"""Typed application errors.

Domain and application layers raise subclasses of `AppError`; the HTTP layer maps the
error *kind* to a status code in one place (`app.shared.http`). Layers below the API never
know about HTTP.
"""

from enum import StrEnum
from typing import Any


class ErrorKind(StrEnum):
    VALIDATION = "validation"
    NOT_FOUND = "not_found"
    CONFLICT = "conflict"
    UNAUTHENTICATED = "unauthenticated"
    FORBIDDEN = "forbidden"
    UNAVAILABLE = "unavailable"


class AppError(Exception):
    kind: ErrorKind = ErrorKind.VALIDATION
    code: str = "app_error"

    def __init__(self, message: str, *, details: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.details = details or {}


class DomainValidationError(AppError):
    kind = ErrorKind.VALIDATION
    code = "domain_validation_error"


class NotFoundError(AppError):
    kind = ErrorKind.NOT_FOUND
    code = "not_found"


class ConflictError(AppError):
    kind = ErrorKind.CONFLICT
    code = "conflict"


class AuthenticationError(AppError):
    kind = ErrorKind.UNAUTHENTICATED
    code = "unauthenticated"


class PermissionDeniedError(AppError):
    kind = ErrorKind.FORBIDDEN
    code = "forbidden"


class ExternalServiceError(AppError):
    kind = ErrorKind.UNAVAILABLE
    code = "external_service_unavailable"
