"""SQL job scheduler and transactional message journal/outbox."""

from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.recruiting.domain import JobStatus
from app.recruiting.orm import ExecutionJobRecord, WorkflowMessageRecord
from app.shared.database import utc_now
from app.shared.errors import ConflictError, NotFoundError


class SqlWorkflowJournal:
    def __init__(
        self, session: Session, request_id: str, correlation_id: str | None = None
    ) -> None:
        self.session = session
        self.request_id = request_id
        self.correlation_id = correlation_id or request_id

    def enqueue(self, kind: str, entity_id: UUID, owner_id: UUID, max_attempts: int) -> UUID:
        job = self.session.scalar(
            select(ExecutionJobRecord)
            .where(
                ExecutionJobRecord.entity_id == entity_id,
                ExecutionJobRecord.type == kind,
            )
            .with_for_update()
        )
        if job is not None:
            if job.status == JobStatus.FAILED:
                self.retry(job.id, owner_id)
            return job.id
        now = utc_now()
        job = ExecutionJobRecord(
            id=uuid4(),
            owner_id=owner_id,
            entity_id=entity_id,
            type=kind,
            status=JobStatus.QUEUED,
            request_id=self.request_id,
            correlation_id=self.correlation_id,
            attempt=0,
            max_attempts=max_attempts,
            available_at=now,
            created_at=now,
        )
        self.session.add(job)
        self.session.flush()
        self._message(kind, "command", entity_id, owner_id, {}, job.id)
        return job.id

    def retry(self, job_id: UUID, owner_id: UUID) -> None:
        job = self.session.scalar(
            select(ExecutionJobRecord)
            .where(
                ExecutionJobRecord.id == job_id,
                ExecutionJobRecord.owner_id == owner_id,
            )
            .with_for_update()
        )
        if job is None:
            raise NotFoundError("Задание не найдено")
        if job.status != JobStatus.FAILED:
            raise ConflictError("Повторить можно только неудачное задание")
        job.status, job.attempt = JobStatus.QUEUED, 0
        job.available_at = utc_now()
        job.error_code = job.error_message = None
        job.completed_at = job.lease_until = None
        job.lease_token = None
        self._message(job.type, "command", job.entity_id, owner_id, {}, job.id)

    def emit(
        self,
        subject: str,
        entity_id: UUID,
        owner_id: UUID,
        payload: dict[str, Any],
        job_id: UUID | None = None,
    ) -> None:
        self._message(subject, "event", entity_id, owner_id, payload, job_id)

    def _message(
        self,
        subject: str,
        kind: str,
        entity_id: UUID,
        owner_id: UUID,
        payload: dict[str, Any],
        job_id: UUID | None,
    ) -> None:
        event_id, now = uuid4(), utc_now()
        self.session.add(
            WorkflowMessageRecord(
                event_id=event_id,
                owner_id=owner_id,
                entity_id=entity_id,
                job_id=job_id,
                subject=subject,
                message_kind=kind,
                created_at=now,
                envelope={
                    "event_id": str(event_id),
                    "correlation_id": self.correlation_id,
                    "request_id": self.request_id,
                    "job_id": str(job_id) if job_id else None,
                    "entity_id": str(entity_id),
                    "timestamp": now.isoformat(),
                    "payload": payload,
                    "version": 1,
                    "kind": kind,
                    "subject": subject,
                },
            )
        )
        self.session.flush()
