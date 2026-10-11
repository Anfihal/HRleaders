"""Contract between `HttpFspGateway` and the mock FSP API (the same contract as the real one)."""

from collections.abc import Iterator
from typing import Any

import httpx
import pytest
from fastapi.testclient import TestClient

from app.fsp.gateway import FspParticipantNotFoundError, FspUnavailableError, HttpFspGateway
from mock_fsp.main import create_app, get_mock_settings

pytestmark = pytest.mark.integration

TOKEN = "fsp-test-token"
BASE_URL = "http://fsp.test"


@pytest.fixture
def mock_fsp(monkeypatch: pytest.MonkeyPatch) -> Iterator[TestClient]:
    monkeypatch.setenv("FSP_API_TOKEN", TOKEN)
    get_mock_settings.cache_clear()
    client = TestClient(create_app(), base_url=BASE_URL)
    yield client
    get_mock_settings.cache_clear()


def test_mock_requires_token(mock_fsp: TestClient) -> None:
    assert mock_fsp.get("/participants/FSP-1001").status_code == 401
    wrong = mock_fsp.get("/participants/FSP-1001", headers={"Authorization": "Bearer nope"})
    assert wrong.status_code == 401
    assert mock_fsp.get("/health").json() == {"status": "ok"}


@pytest.fixture
def gateway(mock_fsp: TestClient, monkeypatch: pytest.MonkeyPatch) -> HttpFspGateway:
    """Route the gateway's real HTTP calls into the mock app."""

    def get(url: str, **kwargs: Any) -> httpx.Response:
        kwargs.pop("timeout", None)
        response: httpx.Response = mock_fsp.get(url, **kwargs)
        return response

    monkeypatch.setattr("app.fsp.gateway.httpx.get", get)
    return HttpFspGateway(f"{BASE_URL}/", TOKEN, timeout_seconds=1)


def test_gateway_parses_participant(gateway: HttpFspGateway) -> None:
    participant = gateway.fetch_participant("FSP-1001")
    assert participant.full_name == "Иванов Артём Сергеевич"
    assert participant.competitions
    assert {item.discipline for item in participant.competitions} == {
        "Программирование алгоритмическое"
    }


def test_gateway_maps_not_found(gateway: HttpFspGateway) -> None:
    with pytest.raises(FspParticipantNotFoundError):
        gateway.fetch_participant("FSP-0000")


def test_gateway_maps_auth_failure_to_unavailable(
    mock_fsp: TestClient, gateway: HttpFspGateway
) -> None:
    broken = HttpFspGateway(BASE_URL, "wrong-token", timeout_seconds=1)
    with pytest.raises(FspUnavailableError):
        broken.fetch_participant("FSP-1001")


def test_gateway_maps_network_errors(monkeypatch: pytest.MonkeyPatch) -> None:
    def get(url: str, **kwargs: Any) -> httpx.Response:
        raise httpx.ConnectError("connection refused")

    monkeypatch.setattr("app.fsp.gateway.httpx.get", get)
    with pytest.raises(FspUnavailableError):
        HttpFspGateway(BASE_URL, TOKEN, timeout_seconds=1).fetch_participant("FSP-1001")


def test_gateway_rejects_unexpected_payload(monkeypatch: pytest.MonkeyPatch) -> None:
    def get(url: str, **kwargs: Any) -> httpx.Response:
        return httpx.Response(200, json={"unexpected": True})

    monkeypatch.setattr("app.fsp.gateway.httpx.get", get)
    with pytest.raises(FspUnavailableError):
        HttpFspGateway(BASE_URL, TOKEN, timeout_seconds=1).fetch_participant("FSP-1001")
