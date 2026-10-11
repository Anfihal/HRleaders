import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from tests.helpers import API, PASSWORD, ClientFactory, assert_error, employer, register

pytestmark = pytest.mark.integration


def test_register_sets_http_only_cookie_and_me_works(client: TestClient) -> None:
    body = employer(client)
    assert body["user"]["company_name"] == "Радиус Софт"
    assert "password_hash" not in body["user"]
    cookie = client.cookies.get("hrl_session")
    assert cookie
    me = client.get(f"{API}/auth/me")
    assert me.status_code == 200
    assert me.json()["email"] == "hr@radius-soft.example"


def test_cookie_flags(client: TestClient) -> None:
    response = client.post(
        f"{API}/auth/register",
        json={
            "email": "lead@mail.example",
            "password": PASSWORD,
            "full_name": "Петров Глеб",
            "role": "candidate",
        },
    )
    header = response.headers["set-cookie"].lower()
    assert "httponly" in header
    assert "samesite=lax" in header


def test_bearer_token_is_accepted(client_factory: ClientFactory, client: TestClient) -> None:
    token = employer(client)["access_token"]
    other = client_factory()
    response = other.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200


def test_login_logout(client: TestClient, client_factory: ClientFactory) -> None:
    employer(client)
    fresh = client_factory()
    response = fresh.post(
        f"{API}/auth/login", json={"email": "HR@radius-soft.example ", "password": PASSWORD}
    )
    assert response.status_code == 200
    assert fresh.post(f"{API}/auth/logout").status_code == 204
    assert_error(fresh.get(f"{API}/auth/me"), 401, "unauthenticated")


def test_wrong_password_is_401(client: TestClient) -> None:
    employer(client)
    response = client.post(
        f"{API}/auth/login", json={"email": "hr@radius-soft.example", "password": "Wrong2026"}
    )
    assert_error(response, 401, "invalid_credentials")


def test_duplicate_email_is_409(client: TestClient) -> None:
    employer(client)
    response = client.post(
        f"{API}/auth/register",
        json={
            "email": "HR@radius-soft.example",
            "password": PASSWORD,
            "full_name": "Другой HR",
            "role": "employer",
            "company_name": "Другая компания",
        },
    )
    assert_error(response, 409, "email_already_registered")


@pytest.mark.parametrize(
    ("payload", "code"),
    [
        ({"password": "short"}, "weak_password"),
        ({"company_name": None}, "company_name_required"),
        ({"email": "not-an-email"}, "validation_error"),
        ({"role": "admin"}, "validation_error"),
    ],
)
def test_registration_validation(client: TestClient, payload: dict[str, object], code: str) -> None:
    body = {
        "email": "hr@aerosfera.example",
        "password": PASSWORD,
        "full_name": "Смирнов Олег",
        "role": "employer",
        "company_name": "Аэросфера",
    } | payload
    error = assert_error(client.post(f"{API}/auth/register", json=body), 422, code)
    if code == "validation_error":
        assert error["details"]["fields"]


def test_tampered_token_is_401(client: TestClient) -> None:
    client.cookies.set("hrl_session", "eyJhbGciOiJIUzI1NiJ9.e30.bad")
    assert_error(client.get(f"{API}/auth/me"), 401, "invalid_token")


def test_role_guard_is_403(client: TestClient) -> None:
    register(client, email="dev@mail.example", full_name="Иванов Артём", role="candidate")
    assert_error(client.get(f"{API}/analytics/overview"), 403, "forbidden")
    assert_error(client.get(f"{API}/candidates"), 403, "forbidden")


def test_unknown_route_and_method_use_uniform_format(client: TestClient) -> None:
    assert_error(client.get(f"{API}/nope"), 404, "route_not_found")
    assert_error(client.delete(f"{API}/auth/me"), 405, "method_not_allowed")


def test_health_and_openapi(client: TestClient, settings: Settings) -> None:
    assert client.get("/api/health").json() == {"status": "ok"}
    assert client.get(f"{settings.api_prefix}/openapi.json").status_code == 200
