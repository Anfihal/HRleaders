"""Role- and owner-scoped HTTP API, using the existing session cookie/error contract."""

from typing import Any, Literal
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response

from app.identity.dependencies import get_current_user, require_candidate, require_employer
from app.identity.domain import Role, User
from app.recruiting.avatar_use_cases import AvatarService
from app.recruiting.dependencies import (
    get_avatars,
    get_configuration,
    get_directory,
    get_interviews,
    get_repo,
    get_scenarios,
)
from app.recruiting.domain import ConsentRequiredError, InterviewTransitionError
from app.recruiting.interview_use_cases import InterviewService
from app.recruiting.repository import SqlAlchemyRecruitingDirectory, SqlAlchemyRecruitingRepository
from app.recruiting.schemas import (
    AnswerInput,
    AvatarInput,
    AvatarUpdate,
    Configuration,
    Criterion,
    InterviewInput,
    ScenarioInput,
    StartInput,
)
from app.recruiting.use_cases import ConfigurationService, ScenarioService
from app.shared.database import DatabaseSession
from app.shared.errors import NotFoundError

router = APIRouter(prefix="/recruiting", tags=["AI recruiter"])


@router.get("/settings")
def settings(
    user: User = Depends(require_employer),
    service: ConfigurationService = Depends(get_configuration),
) -> dict[str, Any]:
    return service.get(user.id)


@router.put("/settings")
def save_settings(
    spec: Configuration,
    user: User = Depends(require_employer),
    service: ConfigurationService = Depends(get_configuration),
) -> dict[str, Any]:
    return service.save(user.id, spec)


@router.get("/scenario-template")
def scenario_template(
    user: User = Depends(require_employer),
    service: ConfigurationService = Depends(get_configuration),
) -> dict[str, Any]:
    config = service.get(user.id)
    return ScenarioInput(
        name="Новый сценарий",
        questions=["Расскажите о проекте и вашем вкладе"],
        criteria=[Criterion(name="Практический опыт", weight=100)],
        language=config["voice"]["language"],
    ).model_dump(mode="json")


@router.get("/scenarios")
def scenarios(
    user: User = Depends(require_employer), repo: SqlAlchemyRecruitingRepository = Depends(get_repo)
) -> list[dict[str, Any]]:
    return repo.list("scenario", user.id)


@router.get("/scenarios/{entity_id}")
def scenario(
    entity_id: UUID,
    user: User = Depends(require_employer),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
) -> dict[str, Any]:
    return repo.get("scenario", entity_id, user.id)


@router.post("/scenarios", status_code=201)
def create_scenario(
    spec: ScenarioInput,
    user: User = Depends(require_employer),
    service: ScenarioService = Depends(get_scenarios),
) -> dict[str, Any]:
    return service.save(user.id, spec)


@router.put("/scenarios/{entity_id}")
def update_scenario(
    entity_id: UUID,
    spec: ScenarioInput,
    user: User = Depends(require_employer),
    service: ScenarioService = Depends(get_scenarios),
) -> dict[str, Any]:
    return service.save(user.id, spec, entity_id)


@router.post("/scenarios/{entity_id}/duplicate", status_code=201)
def duplicate_scenario(
    entity_id: UUID,
    user: User = Depends(require_employer),
    service: ScenarioService = Depends(get_scenarios),
) -> dict[str, Any]:
    return service.duplicate(user.id, entity_id)


@router.post("/scenarios/{entity_id}/archive")
def archive_scenario(
    entity_id: UUID,
    user: User = Depends(require_employer),
    service: ScenarioService = Depends(get_scenarios),
) -> dict[str, Any]:
    return service.archive(user.id, entity_id)


@router.get("/avatars")
def avatars(
    user: User = Depends(require_employer), repo: SqlAlchemyRecruitingRepository = Depends(get_repo)
) -> list[dict[str, Any]]:
    return repo.list("avatar", user.id)


@router.post("/avatars", status_code=201)
def create_avatar(
    spec: AvatarInput,
    user: User = Depends(require_employer),
    service: AvatarService = Depends(get_avatars),
) -> dict[str, Any]:
    return service.create(user.id, spec)


@router.put("/avatars/{entity_id}")
def update_avatar(
    entity_id: UUID,
    spec: AvatarUpdate,
    user: User = Depends(require_employer),
    service: AvatarService = Depends(get_avatars),
) -> dict[str, Any]:
    return service.update(user.id, entity_id, spec)


@router.post("/avatars/{entity_id}/generate")
def generate_avatar(
    entity_id: UUID,
    user: User = Depends(require_employer),
    service: AvatarService = Depends(get_avatars),
    config: ConfigurationService = Depends(get_configuration),
) -> dict[str, Any]:
    return service.generate(user.id, entity_id, config.get(user.id))


@router.post("/avatars/{entity_id}/refresh")
def refresh_avatar(
    entity_id: UUID,
    user: User = Depends(require_employer),
    service: AvatarService = Depends(get_avatars),
) -> dict[str, Any]:
    return service.refresh(user.id, entity_id)


@router.post("/avatars/{entity_id}/archive")
def archive_avatar(
    entity_id: UUID,
    user: User = Depends(require_employer),
    service: AvatarService = Depends(get_avatars),
) -> dict[str, Any]:
    return service.archive(user.id, entity_id)


@router.get("/avatars/{entity_id}/image")
def image(
    entity_id: UUID,
    interview_id: UUID | None = None,
    user: User = Depends(get_current_user),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
) -> Response:
    owner = user.id
    if user.role == Role.CANDIDATE:
        if interview_id is None:
            raise NotFoundError("Изображение не найдено")
        owner = directory.participant_owner(interview_id, user.id)
        session = repo.get("interview", interview_id, owner)
        if not session["snapshot"]["avatar"] or session["snapshot"]["avatar"]["id"] != str(
            entity_id
        ):
            raise NotFoundError("Изображение не найдено")
    repo.get("avatar", entity_id, owner)
    return Response(
        directory.image(entity_id),
        media_type="image/png",
        headers={"Cache-Control": "no-store", "X-Content-Type-Options": "nosniff"},
    )


@router.get("/interviews")
def interviews(
    user: User = Depends(require_employer), repo: SqlAlchemyRecruitingRepository = Depends(get_repo)
) -> list[dict[str, Any]]:
    return repo.list("interview", user.id)


@router.post("/interviews", status_code=201)
def create_interview(
    spec: InterviewInput,
    user: User = Depends(require_employer),
    service: InterviewService = Depends(get_interviews),
    config: ConfigurationService = Depends(get_configuration),
) -> dict[str, Any]:
    return service.create(user.id, spec, config.get(user.id))


def accessible_interview(
    entity_id: UUID,
    user: User,
    repo: SqlAlchemyRecruitingRepository,
    directory: SqlAlchemyRecruitingDirectory,
) -> dict[str, Any]:
    owner = (
        user.id if user.role == Role.EMPLOYER else directory.participant_owner(entity_id, user.id)
    )
    data = repo.get("interview", entity_id, owner)
    if user.role == Role.CANDIDATE:
        # Candidate needs privacy/media preferences, not employer endpoints or secret references.
        config = data["snapshot"]["configuration"]
        data["snapshot"] = {
            **data["snapshot"],
            "avatar": {
                key: data["snapshot"]["avatar"][key]
                for key in (
                    "id",
                    "name",
                    "voice",
                    "language",
                    "visual_style",
                    "behavior",
                    "status",
                    "demo",
                    "error",
                )
            }
            if data["snapshot"]["avatar"]
            else None,
            "configuration": {
                "voice": {
                    k: config["voice"][k]
                    for k in ("voice", "language", "speed", "pitch", "timeout_seconds")
                },
                "video": {k: config["video"][k] for k in ("width", "height", "reconnect_attempts")},
                "security": config["security"],
            },
        }
    return data


@router.get("/interviews/{entity_id}")
def interview(
    entity_id: UUID,
    user: User = Depends(get_current_user),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
) -> dict[str, Any]:
    return accessible_interview(entity_id, user, repo, directory)


@router.post("/interviews/{entity_id}/start")
def start_interview(
    entity_id: UUID,
    spec: StartInput,
    user: User = Depends(get_current_user),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
    service: InterviewService = Depends(get_interviews),
) -> dict[str, Any]:
    if not spec.consent:
        raise ConsentRequiredError("Необходимо согласие кандидата")
    from app.shared.errors import PermissionDeniedError

    if user.role != Role.CANDIDATE:
        raise PermissionDeniedError("Запуск и согласие доступны только приглашённому кандидату")
    service.start(directory.participant_owner(entity_id, user.id), entity_id, spec.consent)
    return accessible_interview(entity_id, user, repo, directory)


@router.post("/interviews/{entity_id}/answer")
def answer_interview(
    entity_id: UUID,
    spec: AnswerInput,
    user: User = Depends(require_candidate),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
    service: InterviewService = Depends(get_interviews),
) -> dict[str, Any]:
    service.answer(
        directory.participant_owner(entity_id, user.id),
        entity_id,
        spec.text,
        spec.expected_revision,
    )
    return accessible_interview(entity_id, user, repo, directory)


@router.post("/interviews/{entity_id}/complete")
def complete_interview(
    entity_id: UUID,
    user: User = Depends(get_current_user),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
    service: InterviewService = Depends(get_interviews),
) -> dict[str, Any]:
    owner = (
        user.id if user.role == Role.EMPLOYER else directory.participant_owner(entity_id, user.id)
    )
    service.complete(owner, entity_id)
    return accessible_interview(entity_id, user, repo, directory)


@router.get("/interviews/{entity_id}/result")
def result(
    entity_id: UUID,
    user: User = Depends(get_current_user),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
) -> dict[str, Any]:
    data = accessible_interview(entity_id, user, repo, directory)
    if data["status"] != "completed":
        raise InterviewTransitionError("Evaluation доступна после завершения")
    return data


@router.get("/avatars/{entity_id}")
def avatar_status(
    entity_id: UUID,
    user: User = Depends(require_employer),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
) -> dict[str, Any]:
    return repo.get("avatar", entity_id, user.id)


@router.post("/interviews/{entity_id}/cancel")
def cancel_interview(
    entity_id: UUID,
    user: User = Depends(get_current_user),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
    service: InterviewService = Depends(get_interviews),
) -> dict[str, Any]:
    owner = (
        user.id if user.role == Role.EMPLOYER else directory.participant_owner(entity_id, user.id)
    )
    service.cancel(owner, entity_id)
    return accessible_interview(entity_id, user, repo, directory)


@router.post("/interviews/{entity_id}/evaluation/retry")
def retry_evaluation(
    entity_id: UUID,
    user: User = Depends(require_employer),
    service: InterviewService = Depends(get_interviews),
) -> dict[str, Any]:
    return service.retry_evaluation(user.id, entity_id)


@router.get("/interviews/{entity_id}/session")
def runtime_session(
    entity_id: UUID,
    user: User = Depends(get_current_user),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
) -> dict[str, Any] | None:
    data = accessible_interview(entity_id, user, repo, directory)
    return data.get("session")


@router.post("/interviews/{entity_id}/session/{action}")
def connection_command(
    entity_id: UUID,
    action: Literal["reconnect", "connect", "error"],
    user: User = Depends(require_candidate),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
    service: InterviewService = Depends(get_interviews),
) -> dict[str, Any]:
    data = service.reconnect(directory.participant_owner(entity_id, user.id), entity_id, action)
    return data["session"]  # type: ignore[no-any-return]


@router.get("/interviews/{entity_id}/transcript")
def transcript(
    entity_id: UUID,
    user: User = Depends(get_current_user),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
) -> dict[str, Any]:
    data = accessible_interview(entity_id, user, repo, directory)
    return {
        "messages": data["transcript"],
        "finalized": data.get("transcript_finalized", False),
        "revision": data["revision"],
    }


@router.get("/interviews/{entity_id}/events")
def session_events(
    entity_id: UUID,
    session: DatabaseSession,
    after: int = Query(default=0, ge=0),
    limit: int = Query(default=100, ge=1, le=500),
    user: User = Depends(get_current_user),
    directory: SqlAlchemyRecruitingDirectory = Depends(get_directory),
    repo: SqlAlchemyRecruitingRepository = Depends(get_repo),
) -> dict[str, Any]:
    from app.recruiting.realtime import events

    accessible_interview(entity_id, user, repo, directory)
    owner = (
        user.id if user.role == Role.EMPLOYER else directory.participant_owner(entity_id, user.id)
    )
    return events(session, entity_id, owner, after, limit)


@router.get("/jobs/{job_id}")
def job_status(
    job_id: UUID,
    session: DatabaseSession,
    user: User = Depends(require_employer),
) -> dict[str, Any]:
    from sqlalchemy import select

    from app.recruiting.orm import ExecutionJobRecord

    job = session.scalar(
        select(ExecutionJobRecord).where(
            ExecutionJobRecord.id == job_id,
            ExecutionJobRecord.owner_id == user.id,
        )
    )
    if job is None:
        raise NotFoundError("Задание не найдено")
    return {
        "id": str(job.id),
        "entity_id": str(job.entity_id),
        "type": job.type,
        "status": job.status,
        "attempt": job.attempt,
        "max_attempts": job.max_attempts,
        "error_code": job.error_code,
        "error_message": job.error_message,
        "request_id": job.request_id,
        "correlation_id": job.correlation_id,
    }
