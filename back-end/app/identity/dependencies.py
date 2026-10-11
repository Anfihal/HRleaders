"""Composition of identity services and authentication guards for the HTTP layer."""

from collections.abc import Callable
from datetime import timedelta

from fastapi import Depends, Request

from app.config import Settings
from app.identity.domain import Role, User
from app.identity.repository import SqlAlchemyUserRepository
from app.shared.database import DatabaseSession
from app.shared.dependencies import get_app_settings
from app.shared.errors import AuthenticationError, PermissionDeniedError
from app.shared.security import JwtTokenService, Pbkdf2PasswordHasher

_BEARER_PREFIX = "Bearer "


def get_user_repository(session: DatabaseSession) -> SqlAlchemyUserRepository:
    return SqlAlchemyUserRepository(session)


def get_password_hasher(settings: Settings = Depends(get_app_settings)) -> Pbkdf2PasswordHasher:
    return Pbkdf2PasswordHasher(settings.password_hash_iterations)


def get_token_service(settings: Settings = Depends(get_app_settings)) -> JwtTokenService:
    return JwtTokenService(
        secret=settings.jwt_secret.get_secret_value(),
        algorithm=settings.jwt_algorithm,
        ttl=timedelta(minutes=settings.access_token_ttl_minutes),
    )


def _extract_token(request: Request, cookie_name: str) -> str | None:
    """HttpOnly cookie for the browser app, `Authorization: Bearer` for API clients."""
    cookie = request.cookies.get(cookie_name)
    if cookie:
        return cookie
    header = request.headers.get("Authorization", "")
    return header[len(_BEARER_PREFIX) :] if header.startswith(_BEARER_PREFIX) else None


def get_current_user(
    request: Request,
    settings: Settings = Depends(get_app_settings),
    tokens: JwtTokenService = Depends(get_token_service),
    users: SqlAlchemyUserRepository = Depends(get_user_repository),
) -> User:
    token = _extract_token(request, settings.auth_cookie_name)
    if token is None:
        raise AuthenticationError("Требуется вход в систему")
    user = users.get(tokens.decode(token).user_id)
    if user is None:
        raise AuthenticationError("Пользователь не найден")
    return user


def require_role(role: Role) -> Callable[[User], User]:
    def guard(user: User = Depends(get_current_user)) -> User:
        if user.role is not role:
            raise PermissionDeniedError("Действие недоступно для вашей роли")
        return user

    return guard


require_candidate = require_role(Role.CANDIDATE)
require_employer = require_role(Role.EMPLOYER)
