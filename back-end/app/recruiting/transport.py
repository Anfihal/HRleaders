"""NATS JetStream transport and SQL outbox relay; no domain decisions here."""

from __future__ import annotations

import json
from typing import TYPE_CHECKING
from uuid import UUID

import nats
from nats.aio.client import Client
from nats.errors import TimeoutError as NatsTimeoutError
from nats.js.api import ConsumerConfig, StreamConfig
from nats.js.client import JetStreamContext
from nats.js.errors import NotFoundError as NatsNotFoundError
from sqlalchemy import select

from app.config import Settings
from app.recruiting.orm import ExecutionJobRecord, WorkflowMessageRecord
from app.recruiting.ports import MessageTransport
from app.shared.database import Database, utc_now
from app.shared.errors import ExternalServiceError

if TYPE_CHECKING:
    from typing import Any

    from app.recruiting.worker import JobWorker


class TransportError(ExternalServiceError):
    code = "transport_unavailable"


class OutboxRelay:
    def __init__(self, database: Database, transport: MessageTransport) -> None:
        self.database, self.transport = database, transport

    async def flush(self, limit: int = 100) -> int:
        with self.database.session_factory() as session:
            pending = session.scalars(
                select(WorkflowMessageRecord)
                .where(
                    WorkflowMessageRecord.published_at.is_(None),
                )
                .order_by(WorkflowMessageRecord.sequence)
                .limit(limit)
            ).all()
        count = 0
        for message in pending:
            await self.transport.publish(message.subject, message.envelope)
            # A crash between publish and marking delivered safely republishes the same event_id.
            with self.database.session_factory.begin() as session:
                row = session.get(WorkflowMessageRecord, message.sequence)
                if row is not None:
                    row.published_at = utc_now()
            count += 1
        return count


class NatsTransport:
    def __init__(self, client: Client, settings: Settings) -> None:
        self.client, self.settings = client, settings
        self.js: JetStreamContext = client.jetstream()
        self.subscription: JetStreamContext.PullSubscription | None = None

    @classmethod
    async def connect(cls, settings: Settings) -> NatsTransport:
        async def safe_error(error: Exception) -> None:
            # The client otherwise logs server URLs and exception text on reconnect.
            return None

        try:
            client = await nats.connect(
                servers=[settings.nats_url],
                token=settings.nats_token.get_secret_value() or None,
                error_cb=safe_error,
                connect_timeout=5,
                max_reconnect_attempts=3,
            )
        except Exception as error:
            raise TransportError("NATS недоступен") from error
        transport = cls(client, settings)
        try:
            try:
                await transport.js.stream_info(settings.nats_stream)
            except NatsNotFoundError:
                await transport.js.add_stream(
                    config=StreamConfig(
                        name=settings.nats_stream,
                        subjects=[f"{settings.nats_subject_prefix}.>"],
                        max_age=settings.nats_retention_seconds,
                    )
                )
            transport.subscription = await transport.js.pull_subscribe(
                f"{settings.nats_subject_prefix}.command.>",
                durable=settings.nats_consumer,
                stream=settings.nats_stream,
                config=ConsumerConfig(ack_wait=settings.job_lease_seconds + 10),
            )
        except Exception as error:
            await client.close()
            raise TransportError("Не удалось настроить NATS transport") from error
        return transport

    async def publish(self, subject: str, envelope: dict[str, Any]) -> None:
        try:
            await self.js.publish(
                f"{self.settings.nats_subject_prefix}.{envelope['kind']}.{subject}",
                json.dumps(envelope).encode(),
                headers={"Nats-Msg-Id": envelope["event_id"]},
            )
        except Exception as error:
            raise TransportError("Не удалось опубликовать сообщение") from error

    async def consume_one(self, database: Database, worker: JobWorker) -> bool:
        import asyncio

        assert self.subscription is not None
        try:
            messages = await self.subscription.fetch(batch=1, timeout=0.5)
        except NatsTimeoutError:
            return False
        except Exception as error:
            # Exhausted client reconnects leave a closed subscription. Reset the transport
            # in the worker loop instead of repeatedly fetching from that dead connection.
            raise TransportError("NATS недоступен") from error
        message = messages[0]
        try:
            envelope = json.loads(message.data)
            event_id, job_id = UUID(envelope["event_id"]), UUID(envelope["job_id"])
            with database.session_factory() as session:
                original = session.scalar(
                    select(WorkflowMessageRecord).where(
                        WorkflowMessageRecord.event_id == event_id,
                        WorkflowMessageRecord.message_kind == "command",
                    )
                )
                job = session.get(ExecutionJobRecord, job_id)
                valid = original is not None and original.envelope == envelope
            if not valid:
                await message.term()
                return False
        except (ValueError, KeyError, TypeError):
            await message.term()
            return False
        if job is None:
            await message.ack()
            return False  # Retention may already have removed the entity/job.
        try:
            processed = await asyncio.to_thread(worker.run_one, job_id)
            with database.session_factory() as session:
                current = session.get(ExecutionJobRecord, job_id)
                terminal = current is None or current.status in {"completed", "failed", "cancelled"}
            if terminal:
                await message.ack()
            else:
                await message.nak(delay=self.settings.worker_poll_seconds)
            return processed
        except Exception:
            await message.nak(delay=self.settings.worker_poll_seconds)
            raise TransportError("Не удалось обработать сообщение") from None

    async def close(self) -> None:
        await self.client.drain()
