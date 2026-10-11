"""Uniform API error format: `{"error": {"code", "message", "details"}}`."""

import logging
from typing import Any

from fastapi import FastAPI, Request, status
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.shared.errors import AppError, ErrorKind
from app.shared.validation_messages import validation_message

logger = logging.getLogger(__name__)

STATUS_BY_KIND: dict[ErrorKind, int] = {
    ErrorKind.VALIDATION: status.HTTP_422_UNPROCESSABLE_CONTENT,
    ErrorKind.NOT_FOUND: status.HTTP_404_NOT_FOUND,
    ErrorKind.CONFLICT: status.HTTP_409_CONFLICT,
    ErrorKind.UNAUTHENTICATED: status.HTTP_401_UNAUTHORIZED,
    ErrorKind.FORBIDDEN: status.HTTP_403_FORBIDDEN,
    ErrorKind.UNAVAILABLE: status.HTTP_503_SERVICE_UNAVAILABLE,
}


class ErrorBody(BaseModel):
    code: str
    message: str
    details: dict[str, Any] = {}


class ErrorResponse(BaseModel):
    error: ErrorBody


def error_response(status_code: int, code: str, message: str, details: Any = None) -> JSONResponse:
    body = ErrorResponse(error=ErrorBody(code=code, message=message, details=details or {}))
    return JSONResponse(status_code=status_code, content=jsonable_encoder(body))


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def handle_app_error(_: Request, error: AppError) -> JSONResponse:
        status_code = STATUS_BY_KIND[error.kind]
        if error.kind is ErrorKind.UNAVAILABLE:
            logger.warning("External dependency failure: %s", error.code)
        return error_response(status_code, error.code, error.message, error.details)

    @app.exception_handler(RequestValidationError)
    async def handle_request_validation(_: Request, error: RequestValidationError) -> JSONResponse:
        fields = [
            {
                "field": ".".join(str(part) for part in item["loc"][1:]),
                "message": validation_message(item),
            }
            for item in error.errors()
        ]
        return error_response(
            status.HTTP_422_UNPROCESSABLE_CONTENT,
            "validation_error",
            "Проверьте корректность заполнения полей",
            {"fields": fields},
        )

    @app.exception_handler(StarletteHTTPException)
    async def handle_http_error(_: Request, error: StarletteHTTPException) -> JSONResponse:
        code, message = HTTP_ERROR_CODES.get(error.status_code, ("http_error", str(error.detail)))
        return error_response(error.status_code, code, message)

    @app.exception_handler(Exception)
    async def handle_unexpected(_: Request, error: Exception) -> JSONResponse:
        # Upstream exception text and traceback locals may include credentials or PII.
        logger.error("Unhandled error: %s", type(error).__name__)
        return error_response(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "internal_error",
            "Внутренняя ошибка сервера. Попробуйте позже",
        )


HTTP_ERROR_CODES: dict[int, tuple[str, str]] = {
    status.HTTP_404_NOT_FOUND: ("route_not_found", "Ресурс не найден"),
    status.HTTP_405_METHOD_NOT_ALLOWED: ("method_not_allowed", "Метод не поддерживается"),
}


ERROR_RESPONSES: dict[int | str, dict[str, Any]] = {
    code: {"model": ErrorResponse} for code in (401, 403, 404, 409, 422, 503)
}
