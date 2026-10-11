import pytest
from fastapi.testclient import TestClient

from tests.helpers import API

pytestmark = pytest.mark.integration


def test_dictionaries_come_from_reference_data(client: TestClient) -> None:
    body = client.get(f"{API}/dictionaries").json()
    assert [d["code"] for d in body["disciplines"]] == [
        "algorithmic",
        "product",
        "security",
        "robotics",
        "uav",
    ]
    assert [(lv["code"], lv["min_score"]) for lv in body["verification_levels"]] == [
        ("none", 0),
        ("basic", 10),
        ("advanced", 40),
        ("expert", 90),
    ]
    for key in (
        "roles",
        "grades",
        "team_roles",
        "work_formats",
        "offer_statuses",
        "competition_results",
        "competition_levels",
        "sport_ranks",
    ):
        assert body[key], key
        assert all(item["code"] and item["label"] for item in body[key])
