"""Mock of the FSP participants API — lets the platform run end-to-end without real FSP access.

Contract (the one `HttpFspGateway` consumes):
`GET /participants/{participant_id}` with `Authorization: Bearer <token>`.
"""

import hmac
from functools import lru_cache
from typing import Any

from fastapi import Depends, FastAPI, Header, HTTPException, status
from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

from mock_fsp.fixtures import load_participants


class MockFspSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    fsp_api_token: SecretStr


@lru_cache
def get_mock_settings() -> MockFspSettings:
    return MockFspSettings()


def require_token(
    authorization: str = Header(default=""),
    settings: MockFspSettings = Depends(get_mock_settings),
) -> None:
    expected = f"Bearer {settings.fsp_api_token.get_secret_value()}"
    if not hmac.compare_digest(authorization.encode(), expected.encode()):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid FSP API token")


def create_app(participants: list[dict[str, Any]] | None = None) -> FastAPI:
    by_id = {item["participant_id"]: item for item in participants or load_participants()}
    app = FastAPI(title="FSP API (mock)")

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/participants/{participant_id}", dependencies=[Depends(require_token)])
    def get_participant(participant_id: str) -> dict[str, Any]:
        participant = by_id.get(participant_id)
        if participant is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Participant not found")
        return participant

    return app
