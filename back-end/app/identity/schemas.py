"""HTTP contracts of the identity context."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field

from app.identity.domain import Role, User


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)
    full_name: str = Field(min_length=2, max_length=200)
    role: Role
    company_name: str | None = Field(default=None, max_length=200)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserResponse(BaseModel):
    id: UUID
    email: str
    full_name: str
    role: Role
    company_name: str | None
    created_at: datetime

    @classmethod
    def from_domain(cls, user: User) -> "UserResponse":
        return cls(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            role=user.role,
            company_name=user.company_name,
            created_at=user.created_at,
        )


class SessionResponse(BaseModel):
    user: UserResponse
    access_token: str
    token_type: str = "bearer"
