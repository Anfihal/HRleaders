"""Outbox publish failure/retry and optional real JetStream consumption."""

import asyncio
import json
import os
from typing import Any
from unittest.mock import AsyncMock, Mock
from uuid import UUID, uuid4

import pytest
from nats.aio.client import Client
from nats.errors import ConnectionClosedError
from nats.js.client import JetStreamContext
from sqlalchemy import select

from app.config import Settings
from app.recruiting.orm import WorkflowMessageRecord
from app.recruiting.providers import MockAvatarProvider, MockLLMProvider
from app.recruiting.storage import FileObjectStorage
from app.recruiting.transport import NatsTransport, OutboxRelay, TransportError
from app.recruiting.worker import JobWorker
from app.shared.database import Database
from tests.helpers import ClientFactory
from tests.integration.test_api_recruiting import ROOT
from tests.integration.test_recruiting_async import active_interview


def test_closed_subscription_requests_safe_transport_reconnect(
    database: Database, settings: Settings
) -> None:
    transport = NatsTransport(Client(), settings)
    subscription = Mock(spec=JetStreamContext.PullSubscription)
    subscription.fetch = AsyncMock(side_effect=ConnectionClosedError())
    transport.subscription = subscription
    worker = Mock(spec=JobWorker)

    with pytest.raises(TransportError, match="NATS недоступен"):
        asyncio.run(transport.consume_one(database, worker))
    worker.run_one.assert_not_called()


def test_outbox_failure_keeps_messages_for_retry(
    client_factory: ClientFactory, database: Database
) -> None:
    _, person, sid = active_interview(client_factory)
    person.post(f"{ROOT}/interviews/{sid}/complete")
    published: list[dict[str, Any]] = []

    class Recorder:
        failed = True

        async def publish(self, subject: str, envelope: dict[str, Any]) -> None:
            if self.failed:
                raise RuntimeError("Broker unavailable")
            published.append(envelope)

    transport = Recorder()
    relay = OutboxRelay(database, transport)
    with pytest.raises(RuntimeError, match="Broker unavailable"):
        asyncio.run(relay.flush())
    with database.session_factory() as session:
        assert all(
            row.published_at is None for row in session.scalars(select(WorkflowMessageRecord))
        )
    transport.failed = False
    assert asyncio.run(relay.flush()) > 0
    assert asyncio.run(relay.flush()) == 0
    assert len({message["event_id"] for message in published}) == len(published)
    command = next(message for message in published if message["kind"] == "command")
    assert command["subject"] == "evaluation.generate"
    assert command["version"] == 1
    assert command["payload"] == {}
    assert command["correlation_id"] and command["job_id"] and command["entity_id"]


@pytest.mark.skipif(not os.environ.get("TEST_NATS_URL"), reason="TEST_NATS_URL not configured")
def test_real_nats_command_event_and_duplicate_delivery(
    client_factory: ClientFactory, database: Database, settings: Settings
) -> None:
    hr, person, sid = active_interview(client_factory)
    job_id = UUID(person.post(f"{ROOT}/interviews/{sid}/complete").json()["evaluation_job_id"])
    suffix = uuid4().hex
    configured = settings.model_copy(
        update={
            "nats_url": os.environ["TEST_NATS_URL"],
            "nats_stream": f"TEST_{suffix}",
            "nats_consumer": f"worker_{suffix}",
            "nats_subject_prefix": f"test_{suffix}",
        }
    )
    worker = JobWorker(
        database,
        configured,
        FileObjectStorage(settings.media_storage_path),
        MockLLMProvider(),
        MockAvatarProvider(),
    )

    async def exercise() -> None:
        transport = await NatsTransport.connect(configured)
        try:
            await OutboxRelay(database, transport).flush()
            assert await transport.consume_one(database, worker) is True
            await OutboxRelay(database, transport).flush()
            info = await transport.js.stream_info(configured.nats_stream)
            assert info.state.messages >= 5
            with database.session_factory() as session:
                original = session.scalar(
                    select(WorkflowMessageRecord).where(
                        WorkflowMessageRecord.job_id == job_id,
                        WorkflowMessageRecord.message_kind == "command",
                    )
                )
                assert original is not None
                # Redelivery of the same committed command bypassing broker dedup is harmless.
                await transport.js.publish(
                    f"{configured.nats_subject_prefix}.command.{original.subject}",
                    json.dumps(original.envelope).encode(),
                )
                assert await transport.consume_one(database, worker) is False
                envelope = {**original.envelope, "event_id": str(uuid4())}
                # A broker message cannot invent an uncommitted command.
                await transport.publish(original.subject, envelope)
            assert await transport.consume_one(database, worker) is False
            assert hr.get(f"{ROOT}/jobs/{job_id}").json()["attempt"] == 1
        finally:
            await transport.js.delete_stream(configured.nats_stream)
            await transport.close()

    asyncio.run(exercise())
    assert person.get(f"{ROOT}/interviews/{sid}/result").json()["evaluation_status"] == "completed"
