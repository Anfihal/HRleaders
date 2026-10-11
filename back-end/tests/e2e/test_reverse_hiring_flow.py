"""The whole MVP scenario through the public HTTP API, as the front-end drives it."""

import pytest
from fastapi.testclient import TestClient

from tests.helpers import API, PASSWORD, ClientFactory, register

pytestmark = pytest.mark.e2e


def test_reverse_hiring_flow(client_factory: ClientFactory) -> None:
    hr, artem, liza = client_factory(), client_factory(), client_factory()

    # Employer and two candidates register.
    register(
        hr,
        email="hr@radius-soft.example",
        full_name="Ковалёва Анастасия Игоревна",
        role="employer",
        company_name="Радиус Софт",
    )
    register(
        artem,
        email="artem.ivanov@mail.example",
        full_name="Иванов Артём Сергеевич",
        role="candidate",
    )
    register(
        liza, email="liza.kim@mail.example", full_name="Ким Елизавета Олеговна", role="candidate"
    )

    # Candidates fill in profiles and confirm achievements with FSP (H1).
    fill_profile(artem, "FSP-1001", "Backend-разработчик Go", salary=320_000)
    fill_profile(liza, "FSP-1002", "Frontend-разработчик Vue", salary=220_000)
    me = artem.get(f"{API}/candidates/me").json()
    assert me["is_fsp_verified"] is True
    development = me["categories"][0]
    assert development["level"]["code"] == "expert"

    # Employer publishes a vacancy and finds candidates by confirmed category (H2).
    vacancy = hr.post(
        f"{API}/vacancies",
        json={
            "title": "Backend-разработчик (Go), платёжное ядро",
            "salary_from": 300_000,
            "salary_to": 400_000,
            "discipline_code": "algorithmic",
            "grade": "senior",
            "work_format": "hybrid",
            "skills": ["Go"],
        },
    ).json()
    found = hr.get(
        f"{API}/candidates", params={"discipline": "algorithmic", "min_level": "advanced"}
    ).json()
    assert [item["full_name"] for item in found["items"]] == ["Иванов Артём Сергеевич"]
    artem_id = found["items"][0]["id"]
    liza_id = liza.get(f"{API}/candidates/me").json()["id"]

    # Employer opens cards and sends direct offers with a salary (H3).
    assert hr.get(f"{API}/candidates/{artem_id}").status_code == 200
    assert hr.get(f"{API}/candidates/{liza_id}").status_code == 200
    for candidate_id in (artem_id, liza_id):
        sent = hr.post(
            f"{API}/offers",
            json={
                "vacancy_id": vacancy["id"],
                "candidate_id": candidate_id,
                "salary": 350_000,
                "message": "Приглашаем на интервью в команду платёжного ядра",
            },
        )
        assert sent.status_code == 201, sent.text

    # Candidates answer: accept, and decline with a mandatory reason (H4).
    (artem_offer,) = artem.get(f"{API}/offers/incoming").json()
    assert artem_offer["salary"] == 350_000
    artem.post(f"{API}/offers/{artem_offer['id']}/view")
    assert artem.post(f"{API}/offers/{artem_offer['id']}/accept").json()["status"] == "accepted"
    (liza_offer,) = liza.get(f"{API}/offers/incoming").json()
    declined = liza.post(
        f"{API}/offers/{liza_offer['id']}/decline",
        json={"reason": "Интересна только продуктовая разработка"},
    )
    assert declined.json()["status"] == "declined"

    # Employer sees the funnel (H5).
    overview = hr.get(f"{API}/analytics/overview").json()
    funnel = overview["funnel"]
    assert funnel["candidates_viewed"] == 2
    assert funnel["offers_sent"] == 2
    assert funnel["offers_accepted"] == 1
    assert funnel["offers_declined"] == 1
    assert overview["rates"]["acceptance"] == 0.5
    assert overview["recent_decline_reasons"] == ["Интересна только продуктовая разработка"]

    # Session ends.
    assert hr.post(f"{API}/auth/logout").status_code == 204
    assert hr.get(f"{API}/auth/me").status_code == 401
    relogin = hr.post(
        f"{API}/auth/login", json={"email": "hr@radius-soft.example", "password": PASSWORD}
    )
    assert relogin.status_code == 200


def fill_profile(client: TestClient, participant_id: str, headline: str, *, salary: int) -> None:
    me = client.get(f"{API}/auth/me").json()
    response = client.put(
        f"{API}/candidates/me",
        json={
            "full_name": me["full_name"],
            "headline": headline,
            "salary_expectation": salary,
            "fsp_participant_id": participant_id,
            "open_to_offers": True,
        },
    )
    assert response.status_code == 200, response.text
    assert client.post(f"{API}/candidates/me/fsp-sync").status_code == 200
