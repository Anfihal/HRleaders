"""Persisted owner-scoped configuration, scenarios, photos and interview aggregates."""

from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import JSON, ForeignKey, Integer, LargeBinary, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.hiring.orm import VacancyRecord
from app.identity.orm import UserRecord
from app.shared.database import Base, UtcDateTime
from app.talent.orm import CandidateProfileRecord


class RecruitingEntityRecord(Base):
    __tablename__ = "recruiting_entities"
    id: Mapped[UUID] = mapped_column(primary_key=True)
    owner_id: Mapped[UUID] = mapped_column(
        ForeignKey(UserRecord.id, ondelete="CASCADE"), index=True
    )
    kind: Mapped[str] = mapped_column(String(32), index=True)
    data: Mapped[dict[str, Any]] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(UtcDateTime())
    updated_at: Mapped[datetime] = mapped_column(UtcDateTime())


class AvatarImageRecord(Base):
    __tablename__ = "recruiting_avatar_images"
    avatar_id: Mapped[UUID] = mapped_column(
        ForeignKey("recruiting_entities.id", ondelete="CASCADE"), primary_key=True
    )
    content: Mapped[bytes] = mapped_column(LargeBinary)


class InterviewLinkRecord(Base):
    __tablename__ = "recruiting_interview_links"
    interview_id: Mapped[UUID] = mapped_column(
        ForeignKey("recruiting_entities.id", ondelete="CASCADE"), primary_key=True
    )
    vacancy_id: Mapped[UUID] = mapped_column(ForeignKey(VacancyRecord.id))
    candidate_id: Mapped[UUID] = mapped_column(ForeignKey(CandidateProfileRecord.id), index=True)
    scenario_id: Mapped[UUID] = mapped_column(ForeignKey("recruiting_entities.id"))


class MediaObjectRecord(Base):
    __tablename__ = "recruiting_media_objects"
    avatar_id: Mapped[UUID] = mapped_column(
        ForeignKey("recruiting_entities.id", ondelete="CASCADE"), primary_key=True
    )
    storage_key: Mapped[str] = mapped_column(String(200), unique=True)
    mime_type: Mapped[str] = mapped_column(String(100))
    size: Mapped[int]
    checksum: Mapped[str] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(UtcDateTime())
    retention_until: Mapped[datetime | None] = mapped_column(UtcDateTime())


class ExecutionJobRecord(Base):
    __tablename__ = "recruiting_jobs"
    __table_args__ = (UniqueConstraint("entity_id", "type"),)
    id: Mapped[UUID] = mapped_column(primary_key=True)
    owner_id: Mapped[UUID] = mapped_column(
        ForeignKey(UserRecord.id, ondelete="CASCADE"), index=True
    )
    entity_id: Mapped[UUID] = mapped_column(
        ForeignKey("recruiting_entities.id", ondelete="CASCADE"), index=True
    )
    type: Mapped[str] = mapped_column(String(64))
    status: Mapped[str] = mapped_column(String(16), index=True)
    correlation_id: Mapped[str] = mapped_column(String(64))
    request_id: Mapped[str] = mapped_column(String(64))
    attempt: Mapped[int]
    max_attempts: Mapped[int]
    lease_token: Mapped[UUID | None]
    lease_until: Mapped[datetime | None] = mapped_column(UtcDateTime())
    available_at: Mapped[datetime] = mapped_column(UtcDateTime())
    error_code: Mapped[str | None] = mapped_column(String(64))
    error_message: Mapped[str | None] = mapped_column(String(200))
    created_at: Mapped[datetime] = mapped_column(UtcDateTime())
    started_at: Mapped[datetime | None] = mapped_column(UtcDateTime())
    completed_at: Mapped[datetime | None] = mapped_column(UtcDateTime())


class WorkflowMessageRecord(Base):
    __tablename__ = "recruiting_outbox"
    sequence: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    event_id: Mapped[UUID] = mapped_column(unique=True)
    owner_id: Mapped[UUID] = mapped_column(
        ForeignKey(UserRecord.id, ondelete="CASCADE"), index=True
    )
    entity_id: Mapped[UUID] = mapped_column(
        ForeignKey("recruiting_entities.id", ondelete="CASCADE"), index=True
    )
    job_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("recruiting_jobs.id", ondelete="SET NULL")
    )
    subject: Mapped[str] = mapped_column(String(100))
    message_kind: Mapped[str] = mapped_column(String(16))
    envelope: Mapped[dict[str, Any]] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(UtcDateTime())
    published_at: Mapped[datetime | None] = mapped_column(UtcDateTime(), index=True)
