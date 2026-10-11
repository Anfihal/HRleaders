"""HR acceptance flows: scenarios → private photo → video → evidence/result."""

import base64
import json
from collections.abc import Callable
from datetime import timedelta
from io import BytesIO
from typing import Any
from uuid import UUID

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from PIL import Image
from pydantic import SecretStr
from sqlalchemy.orm import Session
from starlette.types import Message, Receive, Scope, Send

from app.recruiting.orm import MediaObjectRecord, RecruitingEntityRecord
from app.shared.database import Database
from tests.helpers import API, ClientFactory, assert_error, candidate, employer

ROOT = f"{API}/recruiting"


def photo() -> str:
    stream = BytesIO()
    Image.new("RGB", (256, 256), "#c7d2fe").save(stream, format="PNG")
    return base64.b64encode(stream.getvalue()).decode()


def scenario(client: TestClient, **changes: Any) -> dict[str, Any]:
    response = client.post(
        f"{ROOT}/scenarios",
        json={
            "name": "Backend: практический опыт",
            "role": "Backend developer",
            "questions": ["Расскажите о проекте", "Как проверяли результат?"],
            "criteria": [
                {"name": "Практика", "weight": 70},
                {"name": "Коммуникация", "weight": 30},
            ],
            **changes,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()  # type: ignore[no-any-return]


def test_avatar_is_committed_before_response_is_sent(
    client_factory: ClientFactory, app: FastAPI, database: Database
) -> None:
    """TestClient waits for teardown, so inspect visibility at the actual ASGI send."""
    hr = client_factory()
    employer(hr)
    visible: list[bool] = []

    async def observe(scope: Scope, receive: Receive, send: Send) -> None:
        async def inspect_response(message: Message) -> None:
            if message["type"] == "http.response.body" and message.get("body"):
                avatar_id = UUID(json.loads(message["body"])["id"])
                with database.session_factory() as independent:
                    visible.append(
                        independent.get(RecruitingEntityRecord, avatar_id) is not None
                        and independent.get(MediaObjectRecord, avatar_id) is not None
                    )
            await send(message)

        await app(scope, receive, inspect_response)

    observer = TestClient(observe)
    observer.cookies.update(hr.cookies)
    response = observer.post(
        f"{ROOT}/avatars", json={"name": "Committed", "image_base64": photo(), "consent": True}
    )
    assert response.status_code == 201, response.text
    assert visible == [True], "A following request must see both avatar and photo immediately"


def test_commit_failure_does_not_send_avatar_success(
    client_factory: ClientFactory, monkeypatch: pytest.MonkeyPatch, settings: Any
) -> None:
    hr = client_factory()
    employer(hr)

    def fail_commit(self: Session) -> None:
        raise RuntimeError("Simulated persistence failure")

    monkeypatch.setattr(Session, "commit", fail_commit)
    response = hr.post(
        f"{ROOT}/avatars", json={"name": "Failed", "image_base64": photo(), "consent": True}
    )
    assert response.status_code == 500, "A failed commit must never return HTTP 201"
    assert list(settings.media_storage_path.rglob("*.png")) == []


def test_hr_photo_to_video_to_evaluation(
    client_factory: ClientFactory, drain_jobs: Callable[[], int]
) -> None:
    hr, person = client_factory(), client_factory()
    employer(hr)
    candidate(person)
    profile = person.get(f"{API}/candidates/me").json()
    vacancy_response = hr.post(
        f"{API}/vacancies",
        json={
            "title": "Backend",
            "salary_from": 100000,
            "salary_to": 200000,
        },
    )
    assert vacancy_response.status_code == 201, vacancy_response.text
    vacancy = vacancy_response.json()
    preferences = hr.get(f"{ROOT}/settings").json()
    preferences["avatar"]["endpoint"] = "https://avatars.example.org/v1"
    assert hr.put(f"{ROOT}/settings", json=preferences).status_code == 200
    uploaded = hr.post(
        f"{ROOT}/avatars", json={"name": "Анна", "image_base64": photo(), "consent": True}
    )
    assert uploaded.status_code == 201, uploaded.text
    avatar = uploaded.json()
    assert avatar["status"] == "draft"
    assert hr.post(f"{ROOT}/avatars/{avatar['id']}/generate").json()["status"] == "processing"
    assert drain_jobs() == 1
    avatar = hr.post(f"{ROOT}/avatars/{avatar['id']}/refresh").json()
    assert avatar["status"] == "ready"
    plan = scenario(hr, avatar_id=avatar["id"])
    created = hr.post(
        f"{ROOT}/interviews",
        json={
            "vacancy_id": vacancy["id"],
            "candidate_id": profile["id"],
            "scenario_id": plan["id"],
            "format": "video",
        },
    )
    assert created.status_code == 201, created.text
    sid = created.json()["id"]
    assert_error(
        hr.post(f"{ROOT}/interviews/{sid}/start", json={"consent": False}), 422, "consent_required"
    )
    assert_error(
        hr.post(f"{ROOT}/interviews/{sid}/start", json={"consent": True}), 403, "forbidden"
    )
    running = person.post(f"{ROOT}/interviews/{sid}/start", json={"consent": True}).json()
    assert running["status"] == "active"
    assert "avatars.example.org" not in str(running)
    assert running["transcript"][0]["role"] == "assistant"
    config = hr.get(f"{ROOT}/settings").json()
    config["voice"]["speed"] = 1.5
    assert hr.put(f"{ROOT}/settings", json=config).status_code == 200
    snapshot = person.get(f"{ROOT}/interviews/{sid}").json()["snapshot"]
    assert snapshot["configuration"]["voice"]["speed"] == 1.0
    assert hr.post(f"{ROOT}/avatars/{avatar['id']}/archive").status_code == 409
    hr.put(f"{ROOT}/scenarios/{plan['id']}", json={**plan, "questions": ["Изменённый вопрос"]})
    assert_error(
        hr.post(f"{ROOT}/interviews/{sid}/answer", json={"text": "HR answer"}), 403, "forbidden"
    )
    assert (
        person.post(
            f"{ROOT}/interviews/{sid}/answer",
            json={"text": "Я создал сервис и проверил его тестами."},
        ).status_code
        == 200
    )
    completed = person.post(f"{ROOT}/interviews/{sid}/complete").json()
    assert completed["status"] == "completed"
    assert completed["evaluation"] is None
    assert person.post(f"{ROOT}/interviews/{sid}/complete").json() == completed
    assert drain_jobs() == 1
    completed = person.get(f"{ROOT}/interviews/{sid}").json()
    result = hr.get(f"{ROOT}/interviews/{sid}/result").json()
    assert result["evaluation"]["demo"] is True
    assert result["evaluation"]["unanswered_questions"] == ["Как проверяли результат?"]
    assert len(result["evaluation"]["criteria"]) == 2
    assert result["duration_seconds"] >= 0
    assert_error(
        person.post(f"{ROOT}/interviews/{sid}/answer", json={"text": "Поздний ответ"}),
        409,
        "interview_transition",
    )
    assert person.post(f"{ROOT}/interviews/{sid}/complete").json() == completed


def test_ownership_settings_and_photo_validation(client_factory: ClientFactory) -> None:
    hr, other, person = client_factory(), client_factory(), client_factory()
    employer(hr)
    employer(other, email="other@company.example")
    candidate(person)
    plan = scenario(hr)
    assert_error(other.get(f"{ROOT}/scenarios/{plan['id']}"), 404, "not_found")
    assert_error(person.get(f"{ROOT}/settings"), 403, "forbidden")
    settings = hr.get(f"{ROOT}/settings").json()
    settings["security"]["retention_days"] = 0
    assert hr.put(f"{ROOT}/settings", json=settings).status_code == 422
    for content, consent in [
        (photo(), False),
        (base64.b64encode(b"<script>evil</script>").decode(), True),
    ]:
        assert (
            hr.post(
                f"{ROOT}/avatars",
                json={"name": "Invalid", "image_base64": content, "consent": consent},
            ).status_code
            == 422
        )
    avatar = hr.post(
        f"{ROOT}/avatars", json={"name": "Private", "image_base64": photo(), "consent": True}
    ).json()
    assert_error(other.get(f"{ROOT}/avatars/{avatar['id']}/image"), 404, "not_found")
    assert hr.get(f"{ROOT}/avatars/{avatar['id']}/image").headers["content-type"] == "image/png"
    duplicate = hr.post(f"{ROOT}/scenarios/{plan['id']}/duplicate").json()
    assert duplicate["id"] != plan["id"]
    assert hr.post(f"{ROOT}/scenarios/{plan['id']}/archive").json()["status"] == "archived"


def test_provider_failure_retry_and_masked_secrets(
    client_factory: ClientFactory, app: Any, drain_jobs: Callable[[], int]
) -> None:
    from app.recruiting.dependencies import get_avatar_provider
    from app.recruiting.providers import MockAvatarProvider
    from app.shared.errors import ExternalServiceError

    class FailingAvatar(MockAvatarProvider):
        def generate(self, source: bytes, options: dict[str, Any]) -> dict[str, Any]:
            raise ExternalServiceError("provider failure with sensitive detail")

    hr = client_factory()
    employer(hr)
    app.state.settings.recruiter_secrets = {"primary": SecretStr("server-only-secret")}
    config = hr.get(f"{ROOT}/settings").json()
    config["ai"]["secret_ref"] = "primary"
    response = hr.put(f"{ROOT}/settings", json=config)
    assert response.status_code == 200
    assert response.json()["ai"]["secret_configured"] is True
    assert "server-only-secret" not in response.text
    config["ai"]["endpoint"] = "https://user:password@example.org/api"
    assert hr.put(f"{ROOT}/settings", json=config).status_code == 422
    avatar = hr.post(
        f"{ROOT}/avatars", json={"name": "Retry", "image_base64": photo(), "consent": True}
    ).json()
    app.dependency_overrides[get_avatar_provider] = FailingAvatar
    assert hr.post(f"{ROOT}/avatars/{avatar['id']}/generate").json()["status"] == "processing"
    assert drain_jobs() == 2
    failed = hr.post(f"{ROOT}/avatars/{avatar['id']}/refresh")
    assert failed.json()["status"] == "failed"
    assert "sensitive detail" not in failed.text
    app.dependency_overrides.pop(get_avatar_provider)
    assert hr.post(f"{ROOT}/avatars/{avatar['id']}/generate").status_code == 200
    assert drain_jobs() == 1
    assert hr.post(f"{ROOT}/avatars/{avatar['id']}/refresh").json()["status"] == "ready"


@pytest.mark.parametrize("format", ["text", "voice"])
def test_formats_answer_retries_and_unrelated_candidate(
    client_factory: ClientFactory, app: Any, format: str, drain_jobs: Callable[[], int]
) -> None:
    from app.recruiting.dependencies import get_llm_provider
    from app.recruiting.providers import MockLLMProvider
    from app.shared.errors import ExternalServiceError

    class FailingLLM(MockLLMProvider):
        def next_question(self, session: Any, answer: str) -> str:
            raise ExternalServiceError("LLM unavailable")

    hr, person, stranger = client_factory(), client_factory(), client_factory()
    employer(hr)
    candidate(person)
    profile = person.get(f"{API}/candidates/me").json()
    candidate(
        stranger,
        email="stranger@mail.example",
        full_name="Другой кандидат",
        fsp_participant_id=None,
        sync=False,
    )
    plan = scenario(hr)
    vacancy = hr.post(
        f"{API}/vacancies", json={"title": "Backend", "salary_from": 100000, "salary_to": 200000}
    ).json()
    session = hr.post(
        f"{ROOT}/interviews",
        json={
            "vacancy_id": vacancy["id"],
            "candidate_id": profile["id"],
            "scenario_id": plan["id"],
            "format": format,
        },
    ).json()
    sid = session["id"]
    assert_error(stranger.get(f"{ROOT}/interviews/{sid}"), 404, "not_found")
    assert_error(hr.get(f"{ROOT}/interviews/{sid}/result"), 409, "interview_transition")
    session = person.post(f"{ROOT}/interviews/{sid}/start", json={"consent": True}).json()
    assert "endpoint" not in session["snapshot"]["configuration"]["voice"]
    app.dependency_overrides[get_llm_provider] = FailingLLM
    payload = {"text": "Опыт", "expected_revision": session["revision"]}
    assert_error(
        person.post(f"{ROOT}/interviews/{sid}/answer", json=payload),
        503,
        "external_service_unavailable",
    )
    assert person.get(f"{ROOT}/interviews/{sid}").json()["transcript"] == session["transcript"]
    app.dependency_overrides.pop(get_llm_provider)
    assert person.post(f"{ROOT}/interviews/{sid}/answer", json=payload).status_code == 200
    assert_error(
        person.post(f"{ROOT}/interviews/{sid}/answer", json=payload), 409, "interview_transition"
    )
    completed = hr.post(f"{ROOT}/interviews/{sid}/complete")
    assert completed.status_code == 200
    assert completed.json()["evaluation"] is None
    assert drain_jobs() == 1
    assert hr.get(f"{ROOT}/interviews/{sid}/result").json()["evaluation"]["overall_score"] == 50


def test_retention_removes_only_expired_completed_interviews(
    client_factory: ClientFactory, database: Any, settings: Any
) -> None:
    from app.recruiting.cleanup import purge_expired
    from app.recruiting.orm import (
        ExecutionJobRecord,
        InterviewLinkRecord,
        RecruitingEntityRecord,
        WorkflowMessageRecord,
    )
    from app.recruiting.storage import FileObjectStorage
    from app.shared.database import utc_now

    hr, person = client_factory(), client_factory()
    employer(hr)
    candidate(person)
    profile = person.get(f"{API}/candidates/me").json()
    vacancy = hr.post(
        f"{API}/vacancies", json={"title": "Retention", "salary_from": 100000, "salary_to": 200000}
    ).json()
    plan = scenario(hr)
    payload = {
        "vacancy_id": vacancy["id"],
        "candidate_id": profile["id"],
        "scenario_id": plan["id"],
        "format": "text",
    }
    old = hr.post(f"{ROOT}/interviews", json=payload).json()
    recent = hr.post(f"{ROOT}/interviews", json=payload).json()
    scheduled = hr.post(f"{ROOT}/interviews", json=payload).json()
    for item in [old, recent]:
        assert (
            person.post(f"{ROOT}/interviews/{item['id']}/start", json={"consent": True}).status_code
            == 200
        )
        assert person.post(f"{ROOT}/interviews/{item['id']}/complete").status_code == 200
    with database.session_factory.begin() as session:
        for item in [old, scheduled]:
            row = session.get(RecruitingEntityRecord, UUID(item["id"]))
            assert row is not None
            row.updated_at = utc_now() - timedelta(days=31)
    with database.session_factory.begin() as session:
        assert purge_expired(session, FileObjectStorage(settings.media_storage_path)) == 1
    with database.session_factory() as session:
        assert session.get(InterviewLinkRecord, UUID(old["id"])) is None
        from sqlalchemy import select

        assert (
            session.scalar(
                select(ExecutionJobRecord).where(ExecutionJobRecord.entity_id == UUID(old["id"]))
            )
            is None
        )
        assert (
            session.scalar(
                select(WorkflowMessageRecord).where(
                    WorkflowMessageRecord.entity_id == UUID(old["id"])
                )
            )
            is None
        )
    assert hr.get(f"{ROOT}/interviews/{old['id']}").status_code == 404
    assert hr.get(f"{ROOT}/interviews/{recent['id']}").status_code == 200
    assert hr.get(f"{ROOT}/interviews/{scheduled['id']}").status_code == 200
    assert hr.get(f"{ROOT}/scenarios/{plan['id']}").status_code == 200


@pytest.mark.parametrize("invalid", [False, True])
def test_evaluation_failure_keeps_finalized_interview_and_allows_retry(
    client_factory: ClientFactory, app: Any, invalid: bool, drain_jobs: Callable[[], int]
) -> None:
    from app.recruiting.dependencies import get_llm_provider
    from app.recruiting.providers import MockLLMProvider
    from app.shared.errors import ExternalServiceError
    from tests.integration.test_recruiting_async import active_interview

    class BadEvaluation(MockLLMProvider):
        def evaluate(
            self, session: Any, *, context: dict[str, Any] | None = None
        ) -> dict[str, Any]:
            if invalid:
                return {"overall_score": 200, "criteria": []}
            raise ExternalServiceError("Provider unavailable: server-only-secret")

    hr, person, sid = active_interview(client_factory)
    app.dependency_overrides[get_llm_provider] = BadEvaluation
    completed = person.post(f"{ROOT}/interviews/{sid}/complete")
    assert completed.status_code == 200
    assert completed.json()["evaluation_status"] == "pending"
    assert drain_jobs() == 2
    after = person.get(f"{ROOT}/interviews/{sid}").json()
    assert after["status"] == "completed"
    assert after["transcript"] == completed.json()["transcript"]
    assert after["transcript_finalized"] is True
    assert after["evaluation"] is None
    assert after["evaluation_status"] == "failed"
    assert "server-only-secret" not in str(after)
    app.dependency_overrides.pop(get_llm_provider)
    assert hr.post(f"{ROOT}/interviews/{sid}/evaluation/retry").status_code == 200
    assert drain_jobs() == 1
    result = person.get(f"{ROOT}/interviews/{sid}/result").json()
    assert result["evaluation_status"] == "completed"
    assert result["transcript"] == completed.json()["transcript"]
