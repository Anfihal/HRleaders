"""Demo FSP participants shared by the mock FSP API and the seed."""

import json
from importlib import resources
from typing import Any

FIXTURE_NAME = "participants.json"


def load_participants() -> list[dict[str, Any]]:
    payload = resources.files("mock_fsp").joinpath("data", FIXTURE_NAME).read_text("utf-8")
    participants: list[dict[str, Any]] = json.loads(payload)
    return participants
