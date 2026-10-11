"""Password hashing and access tokens (stdlib PBKDF2 + PyJWT)."""

import base64
import hashlib
import hmac
import secrets
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from uuid import UUID

import jwt

from app.shared.errors import AuthenticationError

_PBKDF2_SCHEME = "pbkdf2_sha256"


class InvalidTokenError(AuthenticationError):
    code = "invalid_token"


class Pbkdf2PasswordHasher:
    def __init__(self, iterations: int) -> None:
        self._iterations = iterations

    def hash(self, password: str) -> str:
        salt = secrets.token_bytes(16)
        digest = self._derive(password, salt, self._iterations)
        return "$".join(
            (_PBKDF2_SCHEME, str(self._iterations), _b64(salt), _b64(digest)),
        )

    def verify(self, password: str, encoded: str) -> bool:
        try:
            scheme, iterations, salt, expected = encoded.split("$")
        except ValueError:
            return False
        if scheme != _PBKDF2_SCHEME:
            return False
        digest = self._derive(password, _unb64(salt), int(iterations))
        return hmac.compare_digest(digest, _unb64(expected))

    @staticmethod
    def _derive(password: str, salt: bytes, iterations: int) -> bytes:
        return hashlib.pbkdf2_hmac("sha256", password.encode(), salt, iterations)


@dataclass(frozen=True)
class TokenClaims:
    user_id: UUID
    role: str
    expires_at: datetime


class JwtTokenService:
    def __init__(self, secret: str, algorithm: str, ttl: timedelta) -> None:
        self._secret = secret
        self._algorithm = algorithm
        self._ttl = ttl

    def issue(self, user_id: UUID, role: str, now: datetime) -> str:
        payload = {"sub": str(user_id), "role": role, "iat": now, "exp": now + self._ttl}
        return jwt.encode(payload, self._secret, algorithm=self._algorithm)

    def decode(self, token: str) -> TokenClaims:
        try:
            payload = jwt.decode(
                token,
                self._secret,
                algorithms=[self._algorithm],
                options={"require": ["sub", "exp", "role"]},
            )
            return TokenClaims(
                user_id=UUID(payload["sub"]),
                role=str(payload["role"]),
                expires_at=datetime.fromtimestamp(payload["exp"], UTC),
            )
        except (jwt.PyJWTError, ValueError) as error:
            raise InvalidTokenError("Сессия недействительна или истекла") from error


def _b64(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _unb64(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))
