"""Composition root for repository and provider ports."""

from fastapi import Depends, Request

from app.config import Settings
from app.recruiting.avatar_use_cases import AvatarService
from app.recruiting.interview_use_cases import InterviewService
from app.recruiting.journal import SqlWorkflowJournal
from app.recruiting.providers import (
    MockAvatarProvider,
    MockLLMProvider,
    MockVideoProvider,
    MockVoiceProvider,
)
from app.recruiting.repository import SqlAlchemyRecruitingDirectory, SqlAlchemyRecruitingRepository
from app.recruiting.storage import FileObjectStorage
from app.recruiting.use_cases import ConfigurationService, ScenarioService
from app.shared.database import DatabaseSession
from app.shared.dependencies import Clock, get_app_settings, get_clock


def get_repo(session: DatabaseSession) -> SqlAlchemyRecruitingRepository:
    return SqlAlchemyRecruitingRepository(session)


def get_storage(settings: Settings = Depends(get_app_settings)) -> FileObjectStorage:
    return FileObjectStorage(settings.media_storage_path)


def get_directory(
    session: DatabaseSession,
    storage: FileObjectStorage = Depends(get_storage),
) -> SqlAlchemyRecruitingDirectory:
    return SqlAlchemyRecruitingDirectory(session, storage)


def get_journal(session: DatabaseSession, request: Request) -> SqlWorkflowJournal:
    return SqlWorkflowJournal(session, request.state.request_id, request.state.correlation_id)


def get_configuration(
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
    settings: Settings = Depends(get_app_settings),
) -> ConfigurationService:
    return ConfigurationService(repo, set(settings.recruiter_secrets))


def get_scenarios(repo: SqlAlchemyRecruitingRepository = Depends(get_repo)) -> ScenarioService:
    return ScenarioService(repo)


def get_avatar_provider() -> MockAvatarProvider:
    return MockAvatarProvider()


def get_llm_provider() -> MockLLMProvider:
    return MockLLMProvider()


def get_avatars(
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
    journal: SqlWorkflowJournal = Depends(get_journal),
    settings: Settings = Depends(get_app_settings),
) -> AvatarService:
    return AvatarService(
        repo, directory, journal, settings.avatar_max_bytes, settings.avatar_max_pixels
    )


def get_interviews(
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
    llm: MockLLMProvider = Depends(get_llm_provider),
    clock: Clock = Depends(get_clock),
    journal: SqlWorkflowJournal = Depends(get_journal),
) -> InterviewService:
    return InterviewService(
        repo, directory, llm, MockVoiceProvider(), MockVideoProvider(), clock, journal
    )
