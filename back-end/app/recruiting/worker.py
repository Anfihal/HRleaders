"""Lease-based execution. Providers run outside DB transactions; results are fenced."""

import logging
from dataclasses import dataclass
from datetime import timedelta
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import and_, or_, select, update
from sqlalchemy.orm import Session

from app.config import Settings
from app.recruiting.domain import JobStatus
from app.recruiting.evaluation_use_cases import EvaluationService
from app.recruiting.journal import SqlWorkflowJournal
from app.recruiting.orm import ExecutionJobRecord
from app.recruiting.ports import AvatarProvider, LLMProvider, StorageProvider
from app.recruiting.providers import require_demo
from app.recruiting.repository import SqlAlchemyRecruitingDirectory, SqlAlchemyRecruitingRepository
from app.shared.database import Database, utc_now

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class Claim:
    id: UUID
    owner_id: UUID
    entity_id: UUID
    type: str
    token: UUID
    attempt: int
    request_id: str
    correlation_id: str


class JobWorker:
    def __init__(
        self,
        database: Database,
        settings: Settings,
        storage: StorageProvider,
        llm: LLMProvider,
        avatar: AvatarProvider,
    ) -> None:
        self.database, self.settings, self.storage = database, settings, storage
        self.llm, self.avatar = llm, avatar

    @staticmethod
    def journal(session: Session, job: ExecutionJobRecord) -> SqlWorkflowJournal:
        return SqlWorkflowJournal(session, job.request_id, job.correlation_id)

    def claim(self, job_id: UUID | None = None) -> Claim | None:
        now = utc_now()
        eligible = or_(
            and_(
                ExecutionJobRecord.status.in_([JobStatus.QUEUED, JobStatus.RETRYING]),
                ExecutionJobRecord.available_at <= now,
            ),
            and_(
                ExecutionJobRecord.status == JobStatus.RUNNING,
                ExecutionJobRecord.lease_until <= now,
            ),
        )
        with self.database.session_factory.begin() as session:
            query = (
                select(ExecutionJobRecord)
                .where(eligible)
                .order_by(
                    ExecutionJobRecord.available_at,
                    ExecutionJobRecord.created_at,
                )
                .limit(1)
                .with_for_update(skip_locked=True)
            )
            if job_id is not None:
                query = query.where(ExecutionJobRecord.id == job_id)
            job = session.scalar(query)
            if job is None:
                return None
            if job.attempt >= job.max_attempts:
                self._failure(session, job, "job_attempts_exhausted")
                return None
            token = uuid4()
            # Compare-and-swap also fences concurrent SQLite claims (which ignore row locks).
            claimed = session.execute(
                update(ExecutionJobRecord)
                .where(
                    ExecutionJobRecord.id == job.id,
                    eligible,
                    ExecutionJobRecord.attempt == job.attempt,
                )
                .values(
                    status=JobStatus.RUNNING,
                    attempt=job.attempt + 1,
                    lease_token=token,
                    lease_until=now + timedelta(seconds=self.settings.job_lease_seconds),
                    started_at=now,
                )
                .returning(ExecutionJobRecord.id)
            ).scalar_one_or_none()
            if claimed is None:
                return None
            session.refresh(job)
            repo = SqlAlchemyRecruitingRepository(session)
            kind = "avatar" if job.type == "avatar.generate" else "interview"
            data = repo.get(kind, job.entity_id, job.owner_id)
            if not self._target_valid(job, data):
                self._cancel(job)
                return None
            if job.type == "evaluation.generate":
                data.update(evaluation_status="processing", evaluation_error=None)
                repo.save(kind, job.entity_id, job.owner_id, data)
                self.journal(session, job).emit(
                    "evaluation.processing",
                    job.entity_id,
                    job.owner_id,
                    {"status": "processing"},
                    job.id,
                )
            return Claim(
                job.id,
                job.owner_id,
                job.entity_id,
                job.type,
                token,
                job.attempt,
                job.request_id,
                job.correlation_id,
            )

    @staticmethod
    def _target_valid(job: ExecutionJobRecord, data: dict[str, Any]) -> bool:
        if job.type == "avatar.generate":
            return bool(data["status"] == "processing")
        if job.type == "evaluation.generate":
            return bool(
                data["status"] == "completed"
                and data.get("transcript_finalized")
                and data.get("evaluation") is None
            )
        return False

    @staticmethod
    def _cancel(job: ExecutionJobRecord) -> None:
        job.status, job.completed_at = JobStatus.CANCELLED, utc_now()
        job.lease_token = None
        job.lease_until = None

    def execute(self, claim: Claim) -> None:
        try:
            with self.database.session_factory() as session:
                repo = SqlAlchemyRecruitingRepository(session)
                data = repo.get(
                    "avatar" if claim.type == "avatar.generate" else "interview",
                    claim.entity_id,
                    claim.owner_id,
                )
                source = (
                    SqlAlchemyRecruitingDirectory(session, self.storage).image(claim.entity_id)
                    if claim.type == "avatar.generate"
                    else None
                )
            context = {
                "job_id": str(claim.id),
                "entity_id": str(claim.entity_id),
                "request_id": claim.request_id,
                "correlation_id": claim.correlation_id,
                "idempotency_key": str(claim.id),
                "provider_request_id": str(claim.id),
                "attempt": claim.attempt,
            }
            if claim.type == "evaluation.generate":
                context["interview_id"] = str(claim.entity_id)
                context["session_id"] = (data.get("session") or {}).get("id")
            if claim.type == "avatar.generate":
                require_demo({"avatar": data["generation_config"]}, "avatar")
                assert source is not None
                result = self.avatar.generate(
                    source, {**data["generation_config"], "context": context}
                )
                # Public demo media contract is allowlisted; adapters must not echo credentials.
                from app.recruiting.schemas import AvatarGenerationResult

                result = AvatarGenerationResult.model_validate(result).model_dump(mode="json")
                result["metadata"] = context
            elif claim.type == "evaluation.generate":
                result = EvaluationService(self.llm).generate(data, context)
            else:
                raise ValueError("Unsupported execution type")
        except Exception:
            # Vendor exception messages can contain credentials or PII. Never persist/log them.
            self.finish(claim, None, "provider_failure")
        else:
            self.finish(claim, result)

    def finish(
        self,
        claim: Claim,
        result: dict[str, Any] | None,
        error_code: str | None = None,
    ) -> bool:
        with self.database.session_factory.begin() as session:
            job = session.scalar(
                select(ExecutionJobRecord)
                .where(
                    ExecutionJobRecord.id == claim.id,
                    ExecutionJobRecord.status == JobStatus.RUNNING,
                    ExecutionJobRecord.lease_token == claim.token,
                    ExecutionJobRecord.lease_until > utc_now(),
                )
                .with_for_update()
            )
            if job is None:
                return False
            repo = SqlAlchemyRecruitingRepository(session)
            kind = "avatar" if job.type == "avatar.generate" else "interview"
            data = repo.get(kind, job.entity_id, job.owner_id)
            if not self._target_valid(job, data):
                self._cancel(job)
                return False
            if error_code:
                self._failure(session, job, error_code)
            else:
                assert result is not None
                if kind == "avatar":
                    data.update(status="ready", error=None, metadata=result)
                    subject, payload = "avatar.ready", {"status": "ready"}
                else:
                    data.update(
                        evaluation=result, evaluation_status="completed", evaluation_error=None
                    )
                    subject, payload = "evaluation.completed", {"status": "completed"}
                repo.save(kind, job.entity_id, job.owner_id, data)
                job.status, job.completed_at = JobStatus.COMPLETED, utc_now()
                job.error_code = job.error_message = None
                job.lease_token = None
                job.lease_until = None
                self.journal(session, job).emit(
                    subject, job.entity_id, job.owner_id, payload, job.id
                )
            if self.settings.recruiting_debug:
                logger.info(
                    "job_id=%s entity_id=%s correlation_id=%s attempt=%s status=%s",
                    job.id,
                    job.entity_id,
                    job.correlation_id,
                    job.attempt,
                    job.status,
                )
            return True

    def _failure(self, session: Session, job: ExecutionJobRecord, code: str) -> None:
        job.error_code, job.error_message = code, "Не удалось выполнить задание провайдера"
        retry = job.attempt < job.max_attempts
        job.status = JobStatus.RETRYING if retry else JobStatus.FAILED
        job.available_at = utc_now() + timedelta(seconds=self.settings.job_retry_seconds)
        job.lease_token = None
        job.lease_until = None
        if not retry:
            job.completed_at = utc_now()
        repo = SqlAlchemyRecruitingRepository(session)
        kind = "avatar" if job.type == "avatar.generate" else "interview"
        data = repo.get(kind, job.entity_id, job.owner_id)
        if not self._target_valid(job, data):
            self._cancel(job)
            return
        if kind == "avatar":
            data.update(
                status="processing" if retry else "failed",
                error=None if retry else job.error_message,
            )
        else:
            data.update(
                evaluation_status="processing" if retry else "failed",
                evaluation_error=None if retry else job.error_message,
            )
        repo.save(kind, job.entity_id, job.owner_id, data)
        self.journal(session, job).emit(
            "job.retrying"
            if retry
            else ("avatar.failed" if kind == "avatar" else "evaluation.failed"),
            job.entity_id,
            job.owner_id,
            {"status": job.status, "error_code": code},
            job.id,
        )

    def run_one(self, job_id: UUID | None = None) -> bool:
        claim = self.claim(job_id)
        if claim is None:
            return False
        self.execute(claim)
        return True
