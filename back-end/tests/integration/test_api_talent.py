import httpx
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.fsp.gateway import FspParticipant, FspUnavailableError
from app.talent.dependencies import get_fsp_gateway
from tests.helpers import API, ClientFactory, assert_error, candidate, employer

pytestmark = pytest.mark.integration


def test_fsp_sync_imports_achievements_and_scores(client: TestClient) -> None:
    body = candidate(client)
    assert body["imported"] == 4
    assert body["skipped"] == []
    profile = body["profile"]
    assert profile["is_fsp_verified"] is True
    (category,) = profile["categories"]
    assert category["discipline_code"] == "algorithmic"
    assert category["level"]["code"] == "expert"


def test_fsp_sync_reports_unknown_disciplines(client: TestClient) -> None:
    body = candidate(
        client,
        email="ilya.fedorov@mail.example",
        full_name="Федоров Илья Константинович",  # FSP has «Фёдоров» — ё/е must match
        fsp_participant_id="FSP-1011",
    )
    assert body["skipped"] == ["Экспериментальная лига ФСП по программированию ИИ-агентов"]
    assert body["profile"]["is_fsp_verified"] is True


def test_my_profile_is_created_on_first_access(client: TestClient) -> None:
    candidate(client, sync=False, fsp_participant_id=None)
    profile = client.get(f"{API}/candidates/me").json()
    assert profile["full_name"] == "Иванов Артём Сергеевич"
    assert profile["is_fsp_verified"] is False


def test_fsp_sync_errors(client: TestClient, app: FastAPI) -> None:
    candidate(client, sync=False, fsp_participant_id=None)

    def sync() -> httpx.Response:
        response: httpx.Response = client.post(f"{API}/candidates/me/fsp-sync")
        return response

    assert_error(sync(), 422, "fsp_participant_not_linked")

    profile = {"full_name": "Иванов Артём Сергеевич", "headline": "Go"}
    client.put(f"{API}/candidates/me", json=profile | {"fsp_participant_id": "FSP-0000"})
    assert_error(sync(), 404, "fsp_participant_not_found")

    client.put(f"{API}/candidates/me", json=profile | {"fsp_participant_id": "FSP-1002"})
    error = assert_error(sync(), 409, "fsp_identity_mismatch")
    assert error["details"] == {"fsp_participant_id": "FSP-1002"}

    class DownGateway:
        def fetch_participant(self, participant_id: str) -> FspParticipant:
            raise FspUnavailableError("Сервис ФСП временно недоступен")

    app.dependency_overrides[get_fsp_gateway] = DownGateway
    assert_error(sync(), 503, "fsp_unavailable")


def test_profile_validation(client: TestClient) -> None:
    candidate(client, sync=False)
    response = client.put(
        f"{API}/candidates/me",
        json={"full_name": "Иванов", "headline": "Go", "salary_expectation": -5},
    )
    error = assert_error(response, 422, "validation_error")
    assert error["details"]["fields"][0]["field"] == "salary_expectation"
    response = client.put(
        f"{API}/candidates/me",
        json={"full_name": "Иванов", "headline": "Go", "skills": [f"s{i}" for i in range(31)]},
    )
    assert_error(response, 422, "too_many_skills")


@pytest.fixture
def pool(client_factory: ClientFactory) -> TestClient:
    """Three candidates with different confirmed categories, plus an employer client."""
    candidate(
        client_factory(),
        grade="senior",
        work_format="hybrid",
        skills=["Go", "Kafka"],
        salary_expectation=340_000,
    )
    candidate(
        client_factory(),
        email="liza.kim@mail.example",
        full_name="Ким Елизавета Олеговна",
        fsp_participant_id="FSP-1002",
        grade="middle",
        work_format="remote",
        skills=["Vue 3", "TypeScript"],
        salary_expectation=230_000,
    )
    candidate(
        client_factory(),
        email="hidden@mail.example",
        full_name="Петров Глеб Максимович",
        fsp_participant_id="FSP-1007",
        open_to_offers=False,
    )
    hr = client_factory()
    employer(hr)
    return hr


def names(response: httpx.Response) -> list[str]:
    assert response.status_code == 200, response.text
    return [item["full_name"] for item in response.json()["items"]]


def test_search_by_category_and_filters(pool: TestClient) -> None:
    def search(**params: str | int) -> httpx.Response:
        response: httpx.Response = pool.get(f"{API}/candidates", params=params)
        return response

    everyone = search()
    assert everyone.json()["total"] == 2  # the hidden candidate is never listed
    assert names(search(discipline="algorithmic", min_level="expert")) == ["Иванов Артём Сергеевич"]
    assert names(search(discipline="product")) == ["Ким Елизавета Олеговна"]
    assert names(search(skill="  typescript ")) == ["Ким Елизавета Олеговна"]
    assert names(search(max_salary=300_000)) == ["Ким Елизавета Олеговна"]
    assert names(search(work_format="hybrid", grade="senior")) == ["Иванов Артём Сергеевич"]
    assert search(limit=1).json()["limit"] == 1
    assert len(names(search(limit=1, offset=1))) == 1
    assert_error(search(min_level="guru"), 422, "unknown_verification_level")
    assert_error(search(discipline="cooking"), 422, "unknown_discipline")
    assert_error(search(grade="ninja"), 422, "validation_error")


def test_view_candidate_card(pool: TestClient) -> None:
    item = pool.get(f"{API}/candidates").json()["items"][0]
    card = pool.get(f"{API}/candidates/{item['id']}")
    assert card.status_code == 200
    assert card.json()["achievements"]
    assert_error(
        pool.get(f"{API}/candidates/00000000-0000-0000-0000-000000000000"),
        404,
        "candidate_profile_not_found",
    )
    assert_error(pool.get(f"{API}/candidates/not-a-uuid"), 422, "validation_error")
