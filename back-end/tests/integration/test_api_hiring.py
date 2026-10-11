from typing import Any, NamedTuple

import httpx
import pytest
from fastapi.testclient import TestClient

from tests.helpers import API, ClientFactory, assert_error, candidate, employer

pytestmark = pytest.mark.integration

VACANCY = {
    "title": "Backend-разработчик (Go), платёжное ядро",
    "salary_from": 300_000,
    "salary_to": 400_000,
    "discipline_code": "algorithmic",
    "grade": "senior",
    "work_format": "hybrid",
    "skills": ["Go", "PostgreSQL"],
}


class Parties(NamedTuple):
    hr: TestClient
    dev: TestClient
    vacancy: dict[str, Any]
    candidate_id: str


@pytest.fixture
def parties(client_factory: ClientFactory) -> Parties:
    hr, dev = client_factory(), client_factory()
    employer(hr)
    candidate_id = candidate(dev)["profile"]["id"]
    vacancy = hr.post(f"{API}/vacancies", json=VACANCY)
    assert vacancy.status_code == 201, vacancy.text
    return Parties(hr, dev, vacancy.json(), candidate_id)


def offer_payload(vacancy: dict[str, Any], candidate_id: str, **overrides: Any) -> dict[str, Any]:
    payload = {
        "vacancy_id": vacancy["id"],
        "candidate_id": candidate_id,
        "salary": 350_000,
        "message": "Артём, приглашаем в команду платёжного ядра",
    }
    return payload | overrides


@pytest.mark.parametrize(
    ("patch", "status", "code"),
    [
        ({"salary_from": 500_000}, 422, "invalid_salary_range"),
        ({"salary_from": 0}, 422, "validation_error"),
        ({"discipline_code": "cooking"}, 422, "unknown_discipline"),
        ({"title": "Go"}, 422, "validation_error"),
    ],
)
def test_vacancy_validation(
    client: TestClient, patch: dict[str, Any], status: int, code: str
) -> None:
    employer(client)
    assert_error(client.post(f"{API}/vacancies", json=VACANCY | patch), status, code)


def test_vacancies_list_and_close(parties: Parties) -> None:
    hr, _, vacancy, candidate_id = parties
    hr.post(f"{API}/offers", json=offer_payload(vacancy, candidate_id))
    (listed,) = hr.get(f"{API}/vacancies").json()
    assert (listed["offers_total"], listed["offers_awaiting"]) == (1, 1)
    closed = hr.post(f"{API}/vacancies/{vacancy['id']}/close")
    assert closed.json()["is_open"] is False


def test_offer_errors(parties: Parties, client_factory: ClientFactory) -> None:
    hr, _, vacancy, candidate_id = parties

    def send(**overrides: Any) -> httpx.Response:
        response: httpx.Response = hr.post(
            f"{API}/offers", json=offer_payload(vacancy, candidate_id) | overrides
        )
        return response

    error = assert_error(send(salary=450_000), 422, "offer_salary_out_of_range")
    assert error["details"] == {"salary_from": 300_000, "salary_to": 400_000}
    error = assert_error(send(message="Привет"), 422, "validation_error")
    assert error["details"]["fields"] == [{"field": "message", "message": "Не короче 10 символов"}]
    assert send().status_code == 201
    assert_error(send(), 409, "duplicate_offer")
    assert_error(
        send(candidate_id="00000000-0000-0000-0000-000000000000"), 404, "candidate_not_available"
    )

    other = client_factory()
    employer(other, email="talents@aerosfera.example")
    response = other.post(f"{API}/offers", json=offer_payload(vacancy, candidate_id))
    assert_error(response, 404, "vacancy_not_found")
    assert other.get(f"{API}/offers").json() == []


def test_closed_vacancy_rejects_new_offers(parties: Parties) -> None:
    hr, _, vacancy, candidate_id = parties
    hr.post(f"{API}/vacancies/{vacancy['id']}/close")
    response = hr.post(f"{API}/offers", json=offer_payload(vacancy, candidate_id))
    assert_error(response, 409, "vacancy_closed")


def test_candidate_responses(parties: Parties) -> None:
    hr, dev, vacancy, candidate_id = parties
    offer_id = hr.post(f"{API}/offers", json=offer_payload(vacancy, candidate_id)).json()["id"]

    (incoming,) = dev.get(f"{API}/offers/incoming").json()
    assert incoming["company_name"] == "Радиус Софт"
    assert incoming["vacancy"]["title"] == VACANCY["title"]

    assert dev.post(f"{API}/offers/{offer_id}/view").json()["status"] == "viewed"
    assert_error(
        dev.post(f"{API}/offers/{offer_id}/decline", json={"reason": "   "}),
        422,
        "decline_reason_required",
    )
    assert_error(dev.post(f"{API}/offers/{offer_id}/decline", json={}), 422, "validation_error")
    declined = dev.post(
        f"{API}/offers/{offer_id}/decline", json={"reason": "Ищу полностью удалённый формат"}
    )
    assert declined.json()["decline_reason"] == "Ищу полностью удалённый формат"
    assert_error(dev.post(f"{API}/offers/{offer_id}/accept"), 409, "offer_transition_not_allowed")
    assert_error(hr.post(f"{API}/offers/{offer_id}/withdraw"), 409, "offer_transition_not_allowed")
    assert_error(hr.post(f"{API}/offers/{offer_id}/accept"), 403, "forbidden")

    (sent,) = hr.get(f"{API}/offers", params={"status": "declined"}).json()
    assert sent["candidate_name"] == "Иванов Артём Сергеевич"
    assert hr.get(f"{API}/offers", params={"status": "accepted"}).json() == []


def test_withdraw(parties: Parties) -> None:
    hr, dev, vacancy, candidate_id = parties
    offer_id = hr.post(f"{API}/offers", json=offer_payload(vacancy, candidate_id)).json()["id"]
    assert hr.post(f"{API}/offers/{offer_id}/withdraw").json()["status"] == "withdrawn"
    assert_error(dev.post(f"{API}/offers/{offer_id}/accept"), 409, "offer_transition_not_allowed")
    # A withdrawn offer no longer blocks a new one.
    assert hr.post(f"{API}/offers", json=offer_payload(vacancy, candidate_id)).status_code == 201
