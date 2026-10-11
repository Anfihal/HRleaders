"""SQLAlchemy mapping for the hiring context."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import JSON, Boolean, CheckConstraint, ForeignKey, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.shared.database import Base, UtcDateTime


class VacancyRecord(Base):
    __tablename__ = "vacancies"
    __table_args__ = (
        CheckConstraint("salary_from > 0 AND salary_to >= salary_from", name="salary_range"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    employer_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    title: Mapped[str] = mapped_column(String(200))
    discipline_code: Mapped[str | None] = mapped_column(ForeignKey("fsp_disciplines.code"))
    grade: Mapped[str | None] = mapped_column(String(32))
    work_format: Mapped[str | None] = mapped_column(String(32))
    salary_from: Mapped[int] = mapped_column(Integer)
    salary_to: Mapped[int] = mapped_column(Integer)
    skills: Mapped[list[str]] = mapped_column(JSON)
    description: Mapped[str] = mapped_column(Text)
    is_open: Mapped[bool] = mapped_column(Boolean, index=True)
    created_at: Mapped[datetime] = mapped_column(UtcDateTime())


class OfferRecord(Base):
    __tablename__ = "offers"
    __table_args__ = (
        CheckConstraint("salary > 0", name="salary_positive"),
        Index("ix_offers_vacancy_candidate", "vacancy_id", "candidate_id"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    vacancy_id: Mapped[UUID] = mapped_column(ForeignKey("vacancies.id", ondelete="CASCADE"))
    employer_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    candidate_id: Mapped[UUID] = mapped_column(
        ForeignKey("candidate_profiles.id", ondelete="CASCADE"), index=True
    )
    salary: Mapped[int] = mapped_column(Integer)
    message: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), index=True)
    created_at: Mapped[datetime] = mapped_column(UtcDateTime())
    viewed_at: Mapped[datetime | None] = mapped_column(UtcDateTime())
    responded_at: Mapped[datetime | None] = mapped_column(UtcDateTime())
    decline_reason: Mapped[str | None] = mapped_column(Text)
