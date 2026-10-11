"""Ports (interfaces) the identity use cases depend on."""

from datetime import datetime
from typing import Protocol
from uuid import UUID

from app.identity.domain import User


class UserRepository(Protocol):
    def get(self, user_id: UUID) -> User | None: ...

    def get_by_email(self, email: str) -> User | None: ...

    def add(self, user: User) -> None: ...


class PasswordHasher(Protocol):
    def hash(self, password: str) -> str: ...

    def verify(self, password: str, encoded: str) -> bool: ...


class TokenIssuer(Protocol):
    def issue(self, user_id: UUID, role: str, now: datetime) -> str: ...
