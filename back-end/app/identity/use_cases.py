"""Identity application services."""

from dataclasses import dataclass

from app.identity.domain import (
    EmailAlreadyRegisteredError,
    PasswordPolicy,
    Role,
    User,
    normalize_email,
)
from app.identity.ports import PasswordHasher, TokenIssuer, UserRepository
from app.shared.dependencies import Clock
from app.shared.errors import AuthenticationError


class InvalidCredentialsError(AuthenticationError):
    code = "invalid_credentials"


@dataclass(frozen=True)
class RegistrationRequest:
    email: str
    password: str
    full_name: str
    role: Role
    company_name: str | None = None


@dataclass(frozen=True)
class AuthenticatedSession:
    user: User
    access_token: str


class RegisterUser:
    def __init__(
        self,
        users: UserRepository,
        hasher: PasswordHasher,
        tokens: TokenIssuer,
        policy: PasswordPolicy,
        clock: Clock,
    ) -> None:
        self._users = users
        self._hasher = hasher
        self._tokens = tokens
        self._policy = policy
        self._clock = clock

    def execute(self, request: RegistrationRequest) -> AuthenticatedSession:
        if self._users.get_by_email(normalize_email(request.email)) is not None:
            raise EmailAlreadyRegisteredError("Пользователь с таким email уже зарегистрирован")
        self._policy.ensure_satisfied(request.password)
        now = self._clock()
        user = User.register(
            email=request.email,
            full_name=request.full_name,
            role=request.role,
            password_hash=self._hasher.hash(request.password),
            company_name=request.company_name,
            now=now,
        )
        self._users.add(user)
        return AuthenticatedSession(user, self._tokens.issue(user.id, user.role, now))


class AuthenticateUser:
    def __init__(
        self,
        users: UserRepository,
        hasher: PasswordHasher,
        tokens: TokenIssuer,
        clock: Clock,
    ) -> None:
        self._users = users
        self._hasher = hasher
        self._tokens = tokens
        self._clock = clock

    def execute(self, email: str, password: str) -> AuthenticatedSession:
        user = self._users.get_by_email(normalize_email(email))
        if user is None or not self._hasher.verify(password, user.password_hash):
            raise InvalidCredentialsError("Неверный email или пароль")
        return AuthenticatedSession(user, self._tokens.issue(user.id, user.role, self._clock()))
