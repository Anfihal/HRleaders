from datetime import timedelta
from uuid import uuid4

import pytest

from app.identity.domain import (
    CompanyNameRequiredError,
    PasswordPolicy,
    Role,
    User,
    WeakPasswordError,
)
from app.shared.database import utc_now
from app.shared.security import InvalidTokenError, JwtTokenService, Pbkdf2PasswordHasher
from tests.conftest import NOW, TEST_JWT_SECRET


@pytest.mark.parametrize("password", ["short1", "onlyletters", "1234567890"])
def test_password_policy_rejects_weak_passwords(password: str) -> None:
    with pytest.raises(WeakPasswordError):
        PasswordPolicy(min_length=8).ensure_satisfied(password)


def test_password_policy_accepts_letters_and_digits() -> None:
    PasswordPolicy(min_length=8).ensure_satisfied("Пароль2026")


def test_employer_requires_company_name() -> None:
    with pytest.raises(CompanyNameRequiredError):
        User.register(
            email="hr@example.org",
            full_name="Ковалёва Анастасия",
            role=Role.EMPLOYER,
            password_hash="x",
            company_name="  ",
            now=NOW,
        )


def test_register_normalizes_email_and_drops_company_for_candidates() -> None:
    user = User.register(
        email="  Artem@Mail.Example ",
        full_name=" Иванов Артём ",
        role=Role.CANDIDATE,
        password_hash="x",
        company_name="Радиус Софт",
        now=NOW,
    )
    assert user.email == "artem@mail.example"
    assert user.full_name == "Иванов Артём"
    assert user.company_name is None


def test_password_hash_roundtrip_and_salting() -> None:
    hasher = Pbkdf2PasswordHasher(iterations=1_000)
    first, second = hasher.hash("Пароль2026"), hasher.hash("Пароль2026")
    assert first != second
    assert hasher.verify("Пароль2026", first)
    assert not hasher.verify("Пароль2027", first)
    assert not hasher.verify("Пароль2026", "garbage")
    assert not hasher.verify("Пароль2026", "md5$1$a$b")


class TestJwt:
    service = JwtTokenService(TEST_JWT_SECRET, "HS256", timedelta(hours=1))

    def test_roundtrip(self) -> None:
        user_id = uuid4()
        claims = self.service.decode(self.service.issue(user_id, "employer", utc_now()))
        assert claims.user_id == user_id
        assert claims.role == "employer"
        assert claims.expires_at.tzinfo is not None

    def test_expired_token_is_rejected(self) -> None:
        token = self.service.issue(uuid4(), "employer", NOW - timedelta(days=1))
        with pytest.raises(InvalidTokenError):
            self.service.decode(token)

    def test_foreign_signature_is_rejected(self) -> None:
        other = JwtTokenService("another-secret-key-with-more-than-32-chars", "HS256", timedelta(1))
        with pytest.raises(InvalidTokenError):
            self.service.decode(other.issue(uuid4(), "employer", utc_now()))
