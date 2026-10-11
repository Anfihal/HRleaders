"""Typed application configuration loaded from environment variables / `.env`."""

import re
from functools import lru_cache
from pathlib import Path
from typing import Annotated
from urllib.parse import urlsplit

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore", hide_input_in_errors=True
    )

    app_name: str = "HRleaders API"
    log_level: str = "INFO"
    api_prefix: str = "/api/v1"
    cors_origins: Annotated[list[str], NoDecode] = Field(default_factory=list)

    database_url: str

    jwt_secret: SecretStr = Field(min_length=32)
    jwt_algorithm: str = "HS256"
    access_token_ttl_minutes: int = Field(default=480, gt=0)
    auth_cookie_name: str = "hrl_session"
    auth_cookie_secure: bool = True

    password_min_length: int = Field(default=8, ge=8)
    password_hash_iterations: int = Field(default=390_000, ge=1_000)

    recruiter_secrets: dict[str, SecretStr] = Field(default_factory=dict)
    avatar_max_bytes: int = Field(default=5_000_000, gt=0)
    avatar_max_pixels: int = Field(default=16_000_000, gt=0)

    media_storage_path: Path = Path(".media")
    worker_poll_seconds: float = Field(default=0.5, gt=0, le=60)
    job_lease_seconds: int = Field(default=180, ge=10, le=3600)
    job_retry_seconds: float = Field(default=2, ge=0, le=300)
    nats_url: str = ""
    nats_token: SecretStr = SecretStr("")
    nats_stream: str = "RECRUITING"
    nats_subject_prefix: str = "recruiting"
    nats_retention_seconds: int = Field(default=86400, ge=60)
    nats_consumer: str = "recruiting-worker"
    recruiting_debug: bool = False

    @field_validator("nats_url")
    @classmethod
    def _nats_address(cls, value: str) -> str:
        if not value:
            return value
        parsed = urlsplit(value)
        if (
            parsed.scheme not in {"nats", "tls"}
            or not parsed.hostname
            or parsed.username
            or parsed.password
            or parsed.query
            or parsed.fragment
            or parsed.path not in {"", "/"}
        ):
            raise ValueError("Use a NATS server URL without credentials; set NATS_TOKEN separately")
        return value

    @field_validator("nats_stream", "nats_consumer", "nats_subject_prefix")
    @classmethod
    def _nats_namespace(cls, value: str) -> str:
        if not re.fullmatch(r"[A-Za-z0-9_-]+", value):
            raise ValueError("Use a nonempty NATS namespace with letters, digits, _ or -")
        return value

    fsp_api_url: str
    fsp_api_token: SecretStr
    fsp_timeout_seconds: float = Field(default=5.0, gt=0)

    search_page_size_default: int = Field(default=20, gt=0)
    search_page_size_max: int = Field(default=100, gt=0)
    candidate_skills_max: int = Field(default=30, gt=0)
    analytics_recent_declines: int = Field(default=5, gt=0)

    @field_validator("cors_origins", mode="before")
    @classmethod
    def _split_csv(cls, value: object) -> object:
        """Allow `CORS_ORIGINS=http://a,http://b` in env files."""
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value


@lru_cache
def get_settings() -> Settings:
    return Settings()
