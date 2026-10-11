"""FastAPI dependencies shared by every bounded context."""

from collections.abc import Callable
from datetime import datetime

from fastapi import Request

from app.config import Settings
from app.shared.database import utc_now

Clock = Callable[[], datetime]


def get_app_settings(request: Request) -> Settings:
    settings: Settings = request.app.state.settings
    return settings


def get_clock() -> Clock:
    return utc_now
