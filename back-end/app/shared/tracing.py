"""Validated trace identifiers; no payloads, credentials or PII in debug logs."""

import logging
import re
from uuid import uuid4

from starlette.types import ASGIApp, Message, Receive, Scope, Send

logger = logging.getLogger("app.trace")


class TraceMiddleware:
    def __init__(self, app: ASGIApp, debug: bool = False) -> None:
        self.app, self.debug = app, debug

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        headers = dict(scope["headers"])

        def identifier(name: bytes, fallback: str) -> str:
            value = headers.get(name, b"").decode("ascii", errors="ignore")
            return value if re.fullmatch(r"[A-Za-z0-9_-]{1,64}", value) else fallback

        request_id = identifier(b"x-request-id", str(uuid4()))
        correlation_id = identifier(b"x-correlation-id", request_id)
        scope.setdefault("state", {}).update(request_id=request_id, correlation_id=correlation_id)

        async def traced_send(message: Message) -> None:
            if message["type"] == "http.response.start":
                message["headers"] = [
                    *message["headers"],
                    (b"x-request-id", request_id.encode()),
                    (b"x-correlation-id", correlation_id.encode()),
                ]
                if self.debug:
                    logger.info(
                        "request_id=%s correlation_id=%s status=%s",
                        request_id,
                        correlation_id,
                        message["status"],
                    )
            await send(message)

        await self.app(scope, receive, traced_send)
