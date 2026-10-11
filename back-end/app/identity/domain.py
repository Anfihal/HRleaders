"""Identity domain: platform users and their roles."""

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from uuid import UUID, uuid4

from app.shared.errors import ConflictError, DomainValidationError


class Role(StrEnum):
    CANDIDATE = "candidate"
    EMPLOYER = "employer"


ROLE_LABELS: dict[Role, str] = {
    Role.CANDIDATE: "ИТ-специалист",
    Role.EMPLOYER: "Работодатель",
}


class EmailAlreadyRegisteredError(ConflictError):
    code = "email_already_registered"


class CompanyNameRequiredError(DomainValidationError):
    code = "company_name_required"


class WeakPasswordError(DomainValidationError):
    code = "weak_password"


def normalize_email(email: str) -> str:
    return email.strip().lower()


@dataclass(frozen=True)
class PasswordPolicy:
    min_length: int

    def ensure_satisfied(self, password: str) -> None:
        has_letter = any(char.isalpha() for char in password)
        has_digit = any(char.isdigit() for char in password)
        if len(password) < self.min_length or not (has_letter and has_digit):
            raise WeakPasswordError(
                f"Пароль должен содержать не менее {self.min_length} символов, буквы и цифры",
            )


@dataclass
class User:
    id: UUID
    email: str
    full_name: str
    role: Role
    password_hash: str
    company_name: str | None
    created_at: datetime

    @classmethod
    def register(
        cls,
        *,
        email: str,
        full_name: str,
        role: Role,
        password_hash: str,
        company_name: str | None,
        now: datetime,
    ) -> "User":
        company = (company_name or "").strip() or None
        if role is Role.EMPLOYER and company is None:
            raise CompanyNameRequiredError("Укажите название компании работодателя")
        return cls(
            id=uuid4(),
            email=normalize_email(email),
            full_name=full_name.strip(),
            role=role,
            password_hash=password_hash,
            company_name=company if role is Role.EMPLOYER else None,
            created_at=now,
        )
