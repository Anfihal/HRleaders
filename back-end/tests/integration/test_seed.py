from contextlib import contextmanager

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.seed.__main__ import load_demo, seed
from app.shared.database import Database
from tests.conftest import NOW
from tests.helpers import API, PASSWORD

pytestmark = pytest.mark.integration


def run_seed(database: Database, settings: Settings) -> bool:
    with contextmanager(database.session_scope)() as session:
        return seed(session, settings, password=PASSWORD, demo=load_demo(), now=NOW)


def test_seed_is_idempotent_and_feeds_analytics(
    database: Database, settings: Settings, client: TestClient
) -> None:
    assert run_seed(database, settings) is True
    assert run_seed(database, settings) is False

    login = client.post(
        f"{API}/auth/login", json={"email": "hr@radius-soft.example", "password": PASSWORD}
    )
    assert login.status_code == 200, login.text
    overview = client.get(f"{API}/analytics/overview").json()
    assert overview["talent_pool"]["candidates_open"] == 13
    assert overview["talent_pool"]["candidates_verified"] == 12
    funnel = overview["funnel"]
    assert (funnel["candidates_viewed"], funnel["offers_sent"], funnel["offers_accepted"]) == (
        8,
        5,
        1,
    )
    assert overview["rates"]["acceptance"] == pytest.approx(1 / 3, abs=1e-3)
    assert overview["recent_decline_reasons"]

    search = client.get(
        f"{API}/candidates", params={"discipline": "algorithmic", "min_level": "advanced"}
    ).json()
    assert [item["full_name"] for item in search["items"]][:2] == [
        "Иванов Артём Сергеевич",
        "Петров Глеб Максимович",
    ]
