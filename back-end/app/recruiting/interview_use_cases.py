"""Frozen interview context, conversation, transcript and evaluation use cases."""

from dataclasses import asdict
from datetime import datetime
from typing import Any
from uuid import UUID, uuid4

from app.recruiting.domain import (
    Interview,
    InterviewSession,
    InterviewTransitionError,
    SessionStatus,
)
from app.recruiting.ports import (
    LLMProvider,
    RecruitingDirectory,
    RecruitingRepository,
    VideoProvider,
    VoiceProvider,
    WorkflowJournal,
)
from app.recruiting.providers import require_demo
from app.recruiting.schemas import InterviewInput
from app.shared.dependencies import Clock
from app.shared.errors import DomainValidationError


class InterviewService:
    def __init__(
        self,
        repo: RecruitingRepository,
        directory: RecruitingDirectory,
        llm: LLMProvider,
        voice: VoiceProvider,
        video: VideoProvider,
        clock: Clock,
        journal: WorkflowJournal,
    ) -> None:
        self.repo, self.directory = repo, directory
        self.llm, self.voice, self.video, self.clock = llm, voice, video, clock
        self.journal = journal

    def create(self, owner: UUID, spec: InterviewInput, config: dict[str, Any]) -> dict[str, Any]:
        scenario = self.repo.get("scenario", spec.scenario_id, owner)
        if scenario["status"] != "active":
            raise DomainValidationError("Выберите активный сценарий")
        avatar_id = (
            spec.avatar_id or scenario.get("avatar_id") or config["avatar"]["default_avatar_id"]
        )
        avatar = self.repo.get("avatar", UUID(str(avatar_id)), owner) if avatar_id else None
        if spec.format == "video" and (not avatar or avatar["status"] != "ready"):
            raise DomainValidationError("Для видео нужен готовый аватар")
        snapshot = self.directory.context(owner, spec.vacancy_id, spec.candidate_id)
        snapshot.update(
            scenario=scenario,
            configuration=config,
            avatar=avatar,
            language=spec.language or scenario["language"],
        )
        entity_id = uuid4()
        created = self.repo.save(
            "interview",
            entity_id,
            owner,
            {
                **spec.model_dump(mode="json"),
                **asdict(Interview(snapshot=snapshot)),
                "demo": True,
                "session": None,
                "transcript_finalized": False,
                "evaluation_status": None,
                "evaluation_error": None,
            },
        )
        self.directory.link(entity_id, spec.vacancy_id, spec.candidate_id, spec.scenario_id)
        return created

    @staticmethod
    def hydrate(data: dict[str, Any]) -> Interview:
        return Interview(
            snapshot=data["snapshot"],
            status=data["status"],
            transcript=list(data["transcript"]),
            question_index=data["question_index"],
            revision=data["revision"],
            started_at=datetime.fromisoformat(data["started_at"]) if data["started_at"] else None,
            completed_at=datetime.fromisoformat(data["completed_at"])
            if data["completed_at"]
            else None,
            evaluation=data["evaluation"],
        )

    def persist(
        self, owner: UUID, entity_id: UUID, data: dict[str, Any], session: Interview
    ) -> dict[str, Any]:
        state = asdict(session)
        state["started_at"] = session.started_at.isoformat() if session.started_at else None
        state["completed_at"] = session.completed_at.isoformat() if session.completed_at else None
        return self.repo.save("interview", entity_id, owner, {**data, **state})

    def start(self, owner: UUID, entity_id: UUID, consent: bool) -> dict[str, Any]:
        data = self.repo.get("interview", entity_id, owner)
        session = self.hydrate(data)
        session.start(consent, self.clock())
        config = session.snapshot["configuration"]
        require_demo(config, "ai")
        if data["format"] in {"voice", "video"}:
            require_demo(config, "voice")
            data["audio"] = self.voice.capabilities()
        if data["format"] == "video":
            require_demo(config, "video")
            data["video"] = self.video.prepare(config["video"])
        data["consent_at"] = session.started_at.isoformat() if session.started_at else None
        runtime = InterviewSession(
            id=str(uuid4()),
            interview_id=str(entity_id),
            candidate_id=data["candidate_id"],
            scenario_id=data["scenario_id"],
            channel=data["format"],
            started_at=data["consent_at"],
            metadata={"consent_at": data["consent_at"], "recording": False},
        )
        runtime.transition(SessionStatus.CONNECTING)
        runtime.connection = "connected"
        runtime.transition(SessionStatus.CANDIDATE_SPEAKING)
        data["session"] = asdict(runtime)
        self.journal.emit("session.connected", entity_id, owner, {"session_id": runtime.id})
        self.journal.emit("session.state_changed", entity_id, owner, {"status": runtime.status})
        return self.persist(owner, entity_id, data, session)

    def answer(
        self, owner: UUID, entity_id: UUID, text: str, expected_revision: int | None
    ) -> dict[str, Any]:
        data = self.repo.get("interview", entity_id, owner)
        session = self.hydrate(data)
        session.require_active()
        if expected_revision is not None and expected_revision != session.revision:
            raise InterviewTransitionError("Ответ уже обработан. Обновите интервью.")
        runtime = InterviewSession(**data["session"]) if data.get("session") else None
        if runtime:
            if runtime.status in {SessionStatus.ERROR, SessionStatus.RECONNECTING}:
                # The existing text fallback remains usable when media transport fails.
                if runtime.status == SessionStatus.ERROR:
                    runtime.transition(SessionStatus.RECONNECTING)
                runtime.transition(SessionStatus.CANDIDATE_SPEAKING)
            runtime.transition(SessionStatus.AI_THINKING)
        self.journal.emit("candidate.speaking", entity_id, owner, {"revision": session.revision})
        self.journal.emit("ai.thinking", entity_id, owner, {"revision": session.revision})
        next_question = self.llm.next_question(session, text)
        session.answer(text, next_question, self.clock())
        if runtime:
            runtime.transition(SessionStatus.AI_SPEAKING)
            self.journal.emit("ai.speaking", entity_id, owner, {"revision": session.revision})
            runtime.transition(SessionStatus.CANDIDATE_SPEAKING)
            data["session"] = asdict(runtime)
        self.journal.emit("transcript.final", entity_id, owner, {"revision": session.revision})
        self.journal.emit(
            "session.state_changed", entity_id, owner, {"status": "candidate_speaking"}
        )
        return self.persist(owner, entity_id, data, session)

    def complete(self, owner: UUID, entity_id: UUID) -> dict[str, Any]:
        data = self.repo.get("interview", entity_id, owner)
        if data["status"] == "completed":
            return data
        session = self.hydrate(data)
        session.require_active()
        session.complete(self.clock())
        data["transcript_finalized"] = True
        data["evaluation_status"] = "pending"
        data["evaluation_error"] = None
        self._close_runtime(data, session)
        data["duration_seconds"] = (
            max(0, int((session.completed_at - session.started_at).total_seconds()))
            if session.completed_at and session.started_at
            else 0
        )
        result = self.persist(owner, entity_id, data, session)
        job_id = self.journal.enqueue(
            "evaluation.generate",
            entity_id,
            owner,
            session.snapshot["configuration"]["ai"]["retries"] + 1,
        )
        result["evaluation_job_id"] = str(job_id)
        self.journal.emit(
            "interview.completed", entity_id, owner, {"revision": session.revision}, job_id
        )
        self.journal.emit("session.state_changed", entity_id, owner, {"status": "completed"})
        return self.repo.save("interview", entity_id, owner, result)

    @staticmethod
    def _close_runtime(data: dict[str, Any], interview: Interview) -> None:
        if data.get("session"):
            runtime = InterviewSession(**data["session"])
            runtime.transition(SessionStatus.COMPLETED)
            runtime.connection = "disconnected"
            runtime.completed_at = (
                interview.completed_at.isoformat() if interview.completed_at else None
            )
            runtime.duration_seconds = (
                max(0, int((interview.completed_at - interview.started_at).total_seconds()))
                if interview.completed_at and interview.started_at
                else 0
            )
            data["session"] = asdict(runtime)

    def cancel(self, owner: UUID, entity_id: UUID) -> dict[str, Any]:
        data = self.repo.get("interview", entity_id, owner)
        if data["status"] == "cancelled":
            return data
        interview = self.hydrate(data)
        interview.cancel(self.clock())
        self._close_runtime(data, interview)
        self.journal.emit("interview.cancelled", entity_id, owner, {"revision": interview.revision})
        if data.get("session"):
            self.journal.emit("session.state_changed", entity_id, owner, {"status": "completed"})
        return self.persist(owner, entity_id, data, interview)

    def reconnect(self, owner: UUID, entity_id: UUID, action: str) -> dict[str, Any]:
        data = self.repo.get("interview", entity_id, owner)
        self.hydrate(data).require_active()
        if not data.get("session"):
            raise InterviewTransitionError("Runtime session отсутствует")
        runtime = InterviewSession(**data["session"])
        if action == "connect":
            runtime.transition(SessionStatus.CANDIDATE_SPEAKING)
            runtime.connection = "connected"
            subject = "session.connected"
        elif action == "reconnect":
            runtime.transition(SessionStatus.RECONNECTING)
            runtime.connection = "reconnecting"
            subject = "connection.reconnecting"
        elif action == "error":
            runtime.transition(SessionStatus.ERROR)
            runtime.connection = "error"
            subject = "connection.error"
        else:
            raise InterviewTransitionError("Неизвестная команда соединения")
        data["session"] = asdict(runtime)
        self.journal.emit(
            subject,
            entity_id,
            owner,
            {"status": runtime.status, "session_id": runtime.id},
        )
        return self.repo.save("interview", entity_id, owner, data)

    def retry_evaluation(self, owner: UUID, entity_id: UUID) -> dict[str, Any]:
        data = self.repo.get("interview", entity_id, owner)
        if data.get("evaluation_status") != "failed":
            raise InterviewTransitionError("Повторить можно только неудачную evaluation")
        self.journal.retry(UUID(data["evaluation_job_id"]), owner)
        data.update(evaluation_status="pending", evaluation_error=None)
        return self.repo.save("interview", entity_id, owner, data)
