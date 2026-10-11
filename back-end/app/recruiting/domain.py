"""Interview business invariants, distinct runtime state and evidence scoring."""

from dataclasses import dataclass, field
from datetime import datetime
from enum import StrEnum
from typing import Any

from app.shared.errors import ConflictError, DomainValidationError


class InterviewTransitionError(ConflictError):
    code = "interview_transition"


class ConsentRequiredError(DomainValidationError):
    code = "consent_required"


class InterviewStatus(StrEnum):
    CREATED = "created"
    SCHEDULED = "scheduled"  # Existing 0003 records remain readable.
    PREPARING = "preparing"
    CONNECTING = "connecting"
    ACTIVE = "active"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class SessionStatus(StrEnum):
    PREPARING = "preparing"
    CONNECTING = "connecting"
    AI_THINKING = "ai_thinking"
    AI_SPEAKING = "ai_speaking"
    CANDIDATE_SPEAKING = "candidate_speaking"
    RECONNECTING = "reconnecting"
    ERROR = "error"
    COMPLETED = "completed"


class AvatarStatus(StrEnum):
    DRAFT = "draft"
    UPLOADING = "uploading"
    PROCESSING = "processing"
    READY = "ready"
    FAILED = "failed"
    ARCHIVED = "archived"


class EvaluationStatus(StrEnum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class JobStatus(StrEnum):
    QUEUED = "queued"
    RUNNING = "running"
    RETRYING = "retrying"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


TERMINAL_INTERVIEWS = {InterviewStatus.COMPLETED, InterviewStatus.CANCELLED}


@dataclass
class InterviewSession:
    """Execution state; business transitions belong to Interview."""

    id: str
    interview_id: str
    candidate_id: str
    scenario_id: str
    channel: str
    status: str = SessionStatus.PREPARING
    connection: str = "disconnected"
    started_at: str | None = None
    completed_at: str | None = None
    duration_seconds: int | None = None
    metadata: dict[str, Any] = field(default_factory=dict)

    def transition(self, target: SessionStatus) -> None:
        allowed: dict[str, set[SessionStatus]] = {
            SessionStatus.PREPARING: {SessionStatus.CONNECTING, SessionStatus.ERROR},
            SessionStatus.CONNECTING: {SessionStatus.CANDIDATE_SPEAKING, SessionStatus.ERROR},
            SessionStatus.CANDIDATE_SPEAKING: {
                SessionStatus.AI_THINKING,
                SessionStatus.RECONNECTING,
                SessionStatus.ERROR,
            },
            SessionStatus.AI_THINKING: {SessionStatus.AI_SPEAKING, SessionStatus.ERROR},
            SessionStatus.AI_SPEAKING: {SessionStatus.CANDIDATE_SPEAKING, SessionStatus.ERROR},
            SessionStatus.RECONNECTING: {SessionStatus.CANDIDATE_SPEAKING, SessionStatus.ERROR},
            SessionStatus.ERROR: {SessionStatus.RECONNECTING},
        }
        if self.status == SessionStatus.COMPLETED or (
            target != SessionStatus.COMPLETED and target not in allowed.get(self.status, set())
        ):
            raise InterviewTransitionError("Недопустимый переход runtime session")
        self.status = target


@dataclass
class Interview:
    snapshot: dict[str, Any]
    status: str = InterviewStatus.CREATED
    transcript: list[dict[str, Any]] = field(default_factory=list)
    question_index: int = 0
    revision: int = 0
    started_at: datetime | None = None
    completed_at: datetime | None = None
    evaluation: dict[str, Any] | None = None

    def transition(self, target: InterviewStatus) -> None:
        allowed: dict[str, set[InterviewStatus]] = {
            InterviewStatus.CREATED: {InterviewStatus.PREPARING, InterviewStatus.CANCELLED},
            InterviewStatus.SCHEDULED: {InterviewStatus.PREPARING, InterviewStatus.CANCELLED},
            InterviewStatus.PREPARING: {
                InterviewStatus.CONNECTING,
                InterviewStatus.FAILED,
                InterviewStatus.CANCELLED,
            },
            InterviewStatus.CONNECTING: {
                InterviewStatus.ACTIVE,
                InterviewStatus.FAILED,
                InterviewStatus.CANCELLED,
            },
            InterviewStatus.ACTIVE: {
                InterviewStatus.COMPLETED,
                InterviewStatus.FAILED,
                InterviewStatus.CANCELLED,
            },
            InterviewStatus.FAILED: {InterviewStatus.CANCELLED},
        }
        if target not in allowed.get(self.status, set()):
            raise InterviewTransitionError("Недопустимый переход интервью")
        self.status = target

    def start(self, consent: bool, now: datetime) -> None:
        if not consent:
            raise ConsentRequiredError("Необходимо согласие кандидата")
        self.transition(InterviewStatus.PREPARING)
        self.transition(InterviewStatus.CONNECTING)
        self.transition(InterviewStatus.ACTIVE)
        self.started_at = now
        self.append("assistant", self.snapshot["scenario"]["greeting"], now)
        self.append("assistant", self.questions[0], now)

    @property
    def questions(self) -> list[str]:
        result: list[str] = self.snapshot["scenario"]["questions"]
        return result

    def require_active(self) -> None:
        if self.status != InterviewStatus.ACTIVE:
            raise InterviewTransitionError("Интервью не активно")

    def append(self, role: str, text: str, now: datetime) -> None:
        if text:
            self.transcript.append({"role": role, "text": text, "at": now.isoformat()})
        self.revision += 1

    def answer(self, text: str, next_question: str, now: datetime) -> None:
        self.require_active()
        if self.question_index >= len(self.questions):
            raise InterviewTransitionError("Все вопросы уже отвечены. Завершите интервью.")
        self.append("candidate", text, now)
        self.question_index += 1
        self.append("assistant", next_question, now)

    def complete(self, now: datetime) -> None:
        self.require_active()
        self.transition(InterviewStatus.COMPLETED)
        self.completed_at = now
        self.append("assistant", self.snapshot["scenario"]["closing"], now)

    def cancel(self, now: datetime) -> None:
        self.transition(InterviewStatus.CANCELLED)
        self.completed_at = now
        self.revision += 1


def weighted_score(criteria: list[dict[str, Any]]) -> float:
    total = sum(item["weight"] for item in criteria)
    if total != 100 or any(not 0 <= item["score"] <= 100 for item in criteria):
        raise DomainValidationError("Некорректные критерии evaluation")
    return round(float(sum(item["score"] * item["weight"] for item in criteria)) / float(total), 1)
