from collections.abc import Callable

import pytest
from pydantic import ValidationError

from app.config import Settings


def test_cors_origins_accept_csv(make_settings: Callable[..., Settings]) -> None:
    settings = make_settings(cors_origins="http://localhost:5173, https://hr.example ,")
    assert settings.cors_origins == ["http://localhost:5173", "https://hr.example"]


def test_short_jwt_secret_is_rejected(make_settings: Callable[..., Settings]) -> None:
    with pytest.raises(ValidationError):
        make_settings(jwt_secret="short")


@pytest.mark.parametrize(
    "changes",
    [
        {"nats_url": "nats://secret:password@example.org:4222"},
        {"nats_url": "http://example.org"},
        {"nats_subject_prefix": ">"},
        {"nats_stream": ""},
    ],
)
def test_transport_configuration_is_validated_without_echoing_secrets(
    make_settings: Callable[..., Settings], changes: dict[str, str]
) -> None:
    with pytest.raises(ValidationError) as raised:
        make_settings(**changes)
    assert "secret:password" not in str(raised.value)


def test_secrets_are_not_leaked_in_repr(make_settings: Callable[..., Settings]) -> None:
    settings = make_settings()
    assert "fsp-test-token" not in repr(settings)
    assert settings.auth_cookie_name == "hrl_session"
