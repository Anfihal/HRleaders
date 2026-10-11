"""Authentication endpoints."""

from fastapi import APIRouter, Depends, Response, status

from app.config import Settings
from app.identity.dependencies import (
    get_current_user,
    get_password_hasher,
    get_token_service,
    get_user_repository,
)
from app.identity.domain import PasswordPolicy, User
from app.identity.repository import SqlAlchemyUserRepository
from app.identity.schemas import LoginRequest, RegisterRequest, SessionResponse, UserResponse
from app.identity.use_cases import (
    AuthenticatedSession,
    AuthenticateUser,
    RegisterUser,
    RegistrationRequest,
)
from app.shared.dependencies import Clock, get_app_settings, get_clock
from app.shared.http import ERROR_RESPONSES
from app.shared.security import JwtTokenService, Pbkdf2PasswordHasher

router = APIRouter(prefix="/auth", tags=["auth"], responses=ERROR_RESPONSES)


def _start_session(
    response: Response, session: AuthenticatedSession, settings: Settings
) -> SessionResponse:
    response.set_cookie(
        key=settings.auth_cookie_name,
        value=session.access_token,
        max_age=settings.access_token_ttl_minutes * 60,
        httponly=True,
        secure=settings.auth_cookie_secure,
        samesite="lax",
        path="/",
    )
    return SessionResponse(
        user=UserResponse.from_domain(session.user), access_token=session.access_token
    )


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(
    payload: RegisterRequest,
    response: Response,
    settings: Settings = Depends(get_app_settings),
    users: SqlAlchemyUserRepository = Depends(get_user_repository),
    hasher: Pbkdf2PasswordHasher = Depends(get_password_hasher),
    tokens: JwtTokenService = Depends(get_token_service),
    clock: Clock = Depends(get_clock),
) -> SessionResponse:
    use_case = RegisterUser(
        users, hasher, tokens, PasswordPolicy(settings.password_min_length), clock
    )
    session = use_case.execute(RegistrationRequest(**payload.model_dump()))
    return _start_session(response, session, settings)


@router.post("/login")
def login(
    payload: LoginRequest,
    response: Response,
    settings: Settings = Depends(get_app_settings),
    users: SqlAlchemyUserRepository = Depends(get_user_repository),
    hasher: Pbkdf2PasswordHasher = Depends(get_password_hasher),
    tokens: JwtTokenService = Depends(get_token_service),
    clock: Clock = Depends(get_clock),
) -> SessionResponse:
    session = AuthenticateUser(users, hasher, tokens, clock).execute(
        payload.email, payload.password
    )
    return _start_session(response, session, settings)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(response: Response, settings: Settings = Depends(get_app_settings)) -> None:
    response.delete_cookie(settings.auth_cookie_name, path="/")


@router.get("/me")
def me(user: User = Depends(get_current_user)) -> UserResponse:
    return UserResponse.from_domain(user)
