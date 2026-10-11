"""Composition of talent adapters for the HTTP layer."""

from fastapi import Depends

from app.config import Settings
from app.fsp.gateway import FspGateway, HttpFspGateway
from app.shared.database import DatabaseSession
from app.shared.dependencies import get_app_settings
from app.talent.repository import (
    SqlAlchemyCandidateProfileRepository,
    SqlAlchemyProfileViewLog,
    SqlAlchemyTalentReferenceData,
)


def get_profile_repository(
    session: DatabaseSession,
) -> SqlAlchemyCandidateProfileRepository:
    return SqlAlchemyCandidateProfileRepository(session)


def get_reference_data(session: DatabaseSession) -> SqlAlchemyTalentReferenceData:
    return SqlAlchemyTalentReferenceData(session)


def get_profile_view_log(session: DatabaseSession) -> SqlAlchemyProfileViewLog:
    return SqlAlchemyProfileViewLog(session)


def get_fsp_gateway(settings: Settings = Depends(get_app_settings)) -> FspGateway:
    return HttpFspGateway(
        base_url=settings.fsp_api_url,
        token=settings.fsp_api_token.get_secret_value(),
        timeout_seconds=settings.fsp_timeout_seconds,
    )
