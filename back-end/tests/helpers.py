"""Small API helpers shared by integration and e2e tests."""

from collections.abc import Callable
from typing import Any

import httpx
from fastapi.testclient import TestClient

API = "/api/v1"
PASSWORD = "Пароль2026"

# Each call returns a client with its own cookie jar, i.e. a separate browser session.
ClientFactory = Callable[[], TestClient]


def register(
    client: TestClient,
    *,
    email: str,
    full_name: str,
    role: str,
    company_name: str | None = None,
) -> dict[str, Any]:
    response = client.post(
        f"{API}/auth/register",
        json={
            "email": email,
            "password": PASSWORD,
            "full_name": full_name,
            "role": role,
            "company_name": company_name,
        },
    )
    assert response.status_code == 201, response.text
    body: dict[str, Any] = response.json()
    return body


def employer(client: TestClient, email: str = "hr@radius-soft.example") -> dict[str, Any]:
    return register(
        client,
        email=email,
        full_name="Ковалёва Анастасия Игоревна",
        role="employer",
        company_name="Радиус Софт",
    )


def candidate(
    client: TestClient,
    *,
    email: str = "artem.ivanov@mail.example",
    full_name: str = "Иванов Артём Сергеевич",
    fsp_participant_id: str | None = "FSP-1001",
    sync: bool = True,
    **profile: Any,
) -> dict[str, Any]:
    register(client, email=email, full_name=full_name, role="candidate")
    response = client.put(
        f"{API}/candidates/me",
        json={
            "full_name": full_name,
            "headline": "Backend-разработчик Go",
            "fsp_participant_id": fsp_participant_id,
            **profile,
        },
    )
    assert response.status_code == 200, response.text
    if sync:
        response = client.post(f"{API}/candidates/me/fsp-sync")
        assert response.status_code == 200, response.text
    body: dict[str, Any] = response.json()
    return body


def assert_error(response: httpx.Response, status: int, code: str) -> dict[str, Any]:
    assert response.status_code == status, response.text
    body: dict[str, Any] = response.json()
    assert set(body) == {"error"}
    assert body["error"]["code"] == code
    error: dict[str, Any] = body["error"]
    assert error["message"]
    return error
