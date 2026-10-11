"""Regressions for providers running in HTTP instead of durable execution jobs."""

from typing import Any
from uuid import UUID

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.recruiting.dependencies import get_avatar_provider, get_llm_provider
from app.recruiting.orm import AvatarImageRecord
from app.recruiting.providers import MockAvatarProvider, MockLLMProvider
from app.shared.database import Database
from tests.helpers import API, ClientFactory, candidate, employer
from tests.integration.test_api_recruiting import ROOT, photo, scenario


def active_interview(client_factory: ClientFactory) -> tuple[TestClient, TestClient, str]:
    hr, person = client_factory(), client_factory()
    employer(hr)
    candidate(person)
    plan = scenario(hr)
    profile = person.get(f"{API}/candidates/me").json()
    vacancy = hr.post(
        f"{API}/vacancies", json={"title": "Async", "salary_from": 100000, "salary_to": 200000}
    ).json()
    response = hr.post(
        f"{ROOT}/interviews",
        json={
            "vacancy_id": vacancy["id"],
            "candidate_id": profile["id"],
            "scenario_id": plan["id"],
            "format": "text",
        },
    )
    assert response.status_code == 201, response.text
    sid = response.json()["id"]
    assert person.post(f"{ROOT}/interviews/{sid}/start", json={"consent": True}).status_code == 200
    return hr, person, sid


def test_completion_queues_evaluation_without_calling_provider(
    client_factory: ClientFactory, app: FastAPI
) -> None:
    calls: list[str] = []

    class ObservedLLM(MockLLMProvider):
        def evaluate(
            self, session: Any, *, context: dict[str, Any] | None = None
        ) -> dict[str, Any]:
            calls.append("evaluate")
            return super().evaluate(session, context=context)

    _, person, sid = active_interview(client_factory)
    app.dependency_overrides[get_llm_provider] = ObservedLLM
    response = person.post(f"{ROOT}/interviews/{sid}/complete")
    assert response.status_code == 200, response.text
    assert calls == [], "Completion must not call an evaluation provider in the HTTP request"
    assert response.json()["status"] == "completed"
    assert response.json()["evaluation"] is None
    assert response.json()["evaluation_status"] == "pending"


def test_avatar_refresh_is_read_only(client_factory: ClientFactory, app: FastAPI) -> None:
    calls: list[str] = []

    class ObservedAvatar(MockAvatarProvider):
        def generate(self, source: bytes, options: dict[str, Any]) -> dict[str, Any]:
            calls.append("generate")
            return super().generate(source, options)

    hr = client_factory()
    employer(hr)
    app.dependency_overrides[get_avatar_provider] = ObservedAvatar
    avatar = hr.post(
        f"{ROOT}/avatars", json={"name": "Async", "image_base64": photo(), "consent": True}
    ).json()
    assert hr.post(f"{ROOT}/avatars/{avatar['id']}/generate").status_code == 200
    response = hr.post(f"{ROOT}/avatars/{avatar['id']}/refresh")
    assert calls == [], "Status refresh must not execute avatar generation"
    assert response.json()["status"] == "processing"


def test_new_avatar_binary_is_not_stored_in_database(
    client_factory: ClientFactory, database: Database
) -> None:
    hr = client_factory()
    employer(hr)
    response = hr.post(
        f"{ROOT}/avatars", json={"name": "Private", "image_base64": photo(), "consent": True}
    )
    assert response.status_code == 201, response.text
    with database.session_factory() as session:
        assert session.get(AvatarImageRecord, UUID(response.json()["id"])) is None
    assert hr.get(f"{ROOT}/avatars/{response.json()['id']}/image").status_code == 200


def test_worker_bootstraps_in_a_separate_process(
    client_factory: ClientFactory, settings: Any
) -> None:
    import os
    import subprocess
    import sys
    from pathlib import Path

    hr = client_factory()
    employer(hr)
    avatar = hr.post(
        f"{ROOT}/avatars", json={"name": "Process", "image_base64": photo(), "consent": True}
    ).json()
    queued = hr.post(f"{ROOT}/avatars/{avatar['id']}/generate").json()
    root = Path(__file__).resolve().parents[3]
    result = subprocess.run(
        [sys.executable, str(root / "experiments/reproduce-worker-bootstrap.py")],
        cwd=root,
        env={
            **os.environ,
            "DATABASE_URL": settings.database_url,
            "JWT_SECRET": settings.jwt_secret.get_secret_value(),
            "FSP_API_URL": settings.fsp_api_url,
            "FSP_API_TOKEN": settings.fsp_api_token.get_secret_value(),
            "MEDIA_STORAGE_PATH": str(settings.media_storage_path),
        },
        capture_output=True,
        text=True,
        check=False,
        timeout=15,
    )
    assert result.returncode == 0, result.stdout
    assert hr.get(f"{ROOT}/jobs/{queued['generation_job_id']}").json()["status"] == "completed"


def test_completion_job_and_outbox_commit_atomically(
    client_factory: ClientFactory, database: Database, monkeypatch: Any
) -> None:
    from sqlalchemy import func, select

    from app.recruiting.journal import SqlWorkflowJournal
    from app.recruiting.orm import ExecutionJobRecord, WorkflowMessageRecord

    _, person, sid = active_interview(client_factory)
    before = person.get(f"{ROOT}/interviews/{sid}").json()

    def fail(*args: Any, **kwargs: Any) -> UUID:
        raise RuntimeError("Scheduler persistence failed")

    monkeypatch.setattr(SqlWorkflowJournal, "enqueue", fail)
    assert person.post(f"{ROOT}/interviews/{sid}/complete").status_code == 500
    after = person.get(f"{ROOT}/interviews/{sid}").json()
    assert after["status"] == "active"
    assert after["transcript"] == before["transcript"]
    with database.session_factory() as session:
        assert session.scalar(select(func.count()).select_from(ExecutionJobRecord)) == 0
        assert (
            session.scalar(
                select(func.count())
                .select_from(WorkflowMessageRecord)
                .where(
                    WorkflowMessageRecord.subject == "interview.completed",
                )
            )
            == 0
        )


def test_duplicate_completion_delivery_and_owner_scoped_events(
    client_factory: ClientFactory, database: Database, settings: Any, drain_jobs: Any
) -> None:
    from sqlalchemy import func, select

    from app.recruiting.orm import ExecutionJobRecord
    from app.recruiting.providers import MockAvatarProvider
    from app.recruiting.storage import FileObjectStorage
    from app.recruiting.worker import JobWorker

    hr, person, sid = active_interview(client_factory)
    person.post(f"{ROOT}/interviews/{sid}/answer", json={"text": "Private answer"})
    completed = person.post(
        f"{ROOT}/interviews/{sid}/complete",
        headers={
            "X-Request-ID": "complete-123",
            "X-Correlation-ID": "workflow-456",
        },
    ).json()
    assert person.post(f"{ROOT}/interviews/{sid}/complete").json() == completed
    assert drain_jobs() == 1
    job_id = UUID(completed["evaluation_job_id"])
    worker = JobWorker(
        database,
        settings,
        FileObjectStorage(settings.media_storage_path),
        MockLLMProvider(),
        MockAvatarProvider(),
    )
    assert worker.run_one(job_id) is False
    with database.session_factory() as session:
        assert session.scalar(select(func.count()).select_from(ExecutionJobRecord)) == 1
    status = hr.get(f"{ROOT}/jobs/{job_id}").json()
    assert status["status"] == "completed"
    assert status["attempt"] == 1
    assert status["request_id"] == "complete-123"
    assert status["correlation_id"] == "workflow-456"
    replay = person.get(f"{ROOT}/interviews/{sid}/events").json()
    assert [event["subject"] for event in replay["events"]].count("evaluation.completed") == 1
    assert "Private answer" not in str(replay)
    assert "endpoint" not in str(replay)
    assert (
        person.get(f"{ROOT}/interviews/{sid}/events?after={replay['cursor']}").json()["events"]
        == []
    )
    assert person.get(f"{ROOT}/jobs/{job_id}").status_code == 403
    other = client_factory()
    employer(other, email="other@company.example")
    assert other.get(f"{ROOT}/jobs/{job_id}").status_code == 404
    assert other.get(f"{ROOT}/interviews/{sid}/events").status_code == 404
    final = person.get(f"{ROOT}/interviews/{sid}/transcript").json()
    assert final["finalized"] is True
    assert final["messages"] == completed["transcript"]


def test_lease_recovery_fences_stale_provider_result(
    client_factory: ClientFactory, database: Database, settings: Any
) -> None:
    from datetime import timedelta

    from app.recruiting.orm import ExecutionJobRecord
    from app.recruiting.providers import MockAvatarProvider
    from app.recruiting.storage import FileObjectStorage
    from app.recruiting.worker import JobWorker
    from app.shared.database import utc_now

    hr, person, sid = active_interview(client_factory)
    job_id = UUID(person.post(f"{ROOT}/interviews/{sid}/complete").json()["evaluation_job_id"])
    worker = JobWorker(
        database,
        settings,
        FileObjectStorage(settings.media_storage_path),
        MockLLMProvider(),
        MockAvatarProvider(),
    )
    first = worker.claim(job_id)
    assert first is not None
    with database.session_factory.begin() as session:
        row = session.get(ExecutionJobRecord, job_id)
        assert row is not None
        row.lease_until = utc_now() - timedelta(seconds=1)
    second = worker.claim(job_id)
    assert second is not None and second.token != first.token and second.attempt == 2
    assert worker.finish(first, {"stale": True}) is False
    worker.execute(second)
    result = hr.get(f"{ROOT}/interviews/{sid}/result").json()
    assert result["evaluation_status"] == "completed"
    assert "stale" not in result["evaluation"]
    assert result["evaluation"]["metadata"]["idempotency_key"] == str(job_id)


def test_concurrent_workers_claim_once(
    client_factory: ClientFactory, database: Database, settings: Any
) -> None:
    from concurrent.futures import ThreadPoolExecutor

    from app.recruiting.providers import MockAvatarProvider
    from app.recruiting.storage import FileObjectStorage
    from app.recruiting.worker import JobWorker

    _, person, sid = active_interview(client_factory)
    job_id = UUID(person.post(f"{ROOT}/interviews/{sid}/complete").json()["evaluation_job_id"])
    worker = JobWorker(
        database,
        settings,
        FileObjectStorage(settings.media_storage_path),
        MockLLMProvider(),
        MockAvatarProvider(),
    )
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda _: worker.claim(job_id), range(2)))
    claims = [result for result in results if result is not None]
    assert len(claims) == 1
    worker.execute(claims[0])
    assert person.get(f"{ROOT}/interviews/{sid}/result").json()["evaluation_status"] == "completed"


def test_provider_runs_without_holding_interview_transaction(
    client_factory: ClientFactory, database: Database, settings: Any
) -> None:
    from concurrent.futures import ThreadPoolExecutor
    from threading import Event

    from app.recruiting.providers import MockAvatarProvider
    from app.recruiting.storage import FileObjectStorage
    from app.recruiting.worker import JobWorker

    started, release = Event(), Event()

    class SlowLLM(MockLLMProvider):
        def evaluate(
            self, session: Any, *, context: dict[str, Any] | None = None
        ) -> dict[str, Any]:
            started.set()
            assert release.wait(5), "Finite provider probe must be released"
            return super().evaluate(session, context=context)

    _, person, sid = active_interview(client_factory)
    job_id = UUID(person.post(f"{ROOT}/interviews/{sid}/complete").json()["evaluation_job_id"])
    worker = JobWorker(
        database,
        settings,
        FileObjectStorage(settings.media_storage_path),
        SlowLLM(),
        MockAvatarProvider(),
    )
    with ThreadPoolExecutor(max_workers=1) as pool:
        future = pool.submit(worker.run_one, job_id)
        try:
            assert started.wait(5)
            response = person.get(f"{ROOT}/interviews/{sid}/result")
            assert response.status_code == 200
            assert response.json()["evaluation_status"] == "processing"
        finally:
            release.set()
        assert future.result() is True


def test_cancel_and_session_connection_commands(client_factory: ClientFactory) -> None:
    hr, person, sid = active_interview(client_factory)
    runtime = person.get(f"{ROOT}/interviews/{sid}/session").json()
    assert runtime["candidate_id"]
    assert runtime["channel"] == "text"
    assert runtime["status"] == "candidate_speaking"
    assert (
        person.post(f"{ROOT}/interviews/{sid}/session/reconnect").json()["status"] == "reconnecting"
    )
    assert (
        person.post(f"{ROOT}/interviews/{sid}/session/connect").json()["connection"] == "connected"
    )
    assert hr.post(f"{ROOT}/interviews/{sid}/session/reconnect").status_code == 403
    assert person.post(f"{ROOT}/interviews/{sid}/session/error").json()["status"] == "error"
    assert (
        person.post(
            f"{ROOT}/interviews/{sid}/answer",
            json={"text": "Text fallback", "expected_revision": 2},
        ).status_code
        == 200
    )
    emitted = person.get(f"{ROOT}/interviews/{sid}/events").json()["events"]
    assert {"connection.error", "ai.thinking", "ai.speaking", "candidate.speaking"} <= {
        event["subject"] for event in emitted
    }
    assert hr.post(f"{ROOT}/interviews/{sid}/cancel").json()["status"] == "cancelled"
    assert person.post(f"{ROOT}/interviews/{sid}/cancel").json()["session"]["status"] == "completed"
    assert (
        person.post(f"{ROOT}/interviews/{sid}/answer", json={"text": "Too late"}).status_code == 409
    )
    assert person.post(f"{ROOT}/interviews/{sid}/complete").status_code == 409
    assert person.post(f"{ROOT}/interviews/{sid}/session/reconnect").status_code == 409


def test_archived_avatar_rejects_late_job_result(
    client_factory: ClientFactory, database: Database, settings: Any
) -> None:
    from app.recruiting.providers import MockAvatarProvider
    from app.recruiting.storage import FileObjectStorage
    from app.recruiting.worker import JobWorker

    hr = client_factory()
    employer(hr)
    avatar = hr.post(
        f"{ROOT}/avatars", json={"name": "Late", "image_base64": photo(), "consent": True}
    ).json()
    queued = hr.post(f"{ROOT}/avatars/{avatar['id']}/generate").json()
    worker = JobWorker(
        database,
        settings,
        FileObjectStorage(settings.media_storage_path),
        MockLLMProvider(),
        MockAvatarProvider(),
    )
    claim = worker.claim(UUID(queued["generation_job_id"]))
    assert claim is not None
    assert hr.post(f"{ROOT}/avatars/{avatar['id']}/archive").status_code == 200
    worker.execute(claim)
    assert hr.get(f"{ROOT}/avatars/{avatar['id']}").json()["status"] == "archived"
    assert hr.get(f"{ROOT}/jobs/{claim.id}").json()["status"] == "cancelled"
    assert hr.get(f"{ROOT}/avatars/{avatar['id']}/image").status_code == 404


def test_legacy_media_export_preserves_content_and_is_idempotent(
    client_factory: ClientFactory, database: Database, settings: Any
) -> None:
    from app.recruiting.export_media import export_legacy
    from app.recruiting.orm import MediaObjectRecord
    from app.recruiting.storage import FileObjectStorage

    hr = client_factory()
    employer(hr)
    avatar = hr.post(
        f"{ROOT}/avatars", json={"name": "Legacy", "image_base64": photo(), "consent": True}
    ).json()
    avatar_id = UUID(avatar["id"])
    content = hr.get(f"{ROOT}/avatars/{avatar_id}/image").content
    storage = FileObjectStorage(settings.media_storage_path)
    with database.session_factory.begin() as session:
        metadata = session.get(MediaObjectRecord, avatar_id)
        assert metadata is not None
        session.delete(metadata)
        session.add(AvatarImageRecord(avatar_id=avatar_id, content=content))
    assert hr.get(f"{ROOT}/avatars/{avatar_id}/image").content == content
    with database.session_factory.begin() as session:
        assert export_legacy(session, storage) == 1
    with database.session_factory.begin() as session:
        assert export_legacy(session, storage) == 0
        assert session.get(AvatarImageRecord, avatar_id) is None
    assert hr.get(f"{ROOT}/avatars/{avatar_id}/image").content == content
