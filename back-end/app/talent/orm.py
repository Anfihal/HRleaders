"""SQLAlchemy mapping for the talent context (profiles + categorization reference data)."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import (
    Boolean,
    Date,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.shared.database import Base, UtcDateTime


class FspDisciplineRecord(Base):
    """FSP discipline dictionary: platform code ↔ label used by the FSP API."""

    __tablename__ = "fsp_disciplines"

    code: Mapped[str] = mapped_column(String(64), primary_key=True)
    fsp_label: Mapped[str] = mapped_column(String(200), unique=True)
    label: Mapped[str] = mapped_column(String(200))
    sort_order: Mapped[int] = mapped_column(Integer)


class ScoringRuleRecord(Base):
    """Categorization weights: points per result, multiplier per level, points per rank."""

    __tablename__ = "scoring_rules"
    __table_args__ = (UniqueConstraint("rule_type", "code"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    rule_type: Mapped[str] = mapped_column(String(32))
    code: Mapped[str] = mapped_column(String(64))
    fsp_label: Mapped[str] = mapped_column(String(200))
    label: Mapped[str] = mapped_column(String(200))
    value: Mapped[float] = mapped_column(Float)
    sort_order: Mapped[int] = mapped_column(Integer)


class VerificationLevelRecord(Base):
    __tablename__ = "verification_levels"

    code: Mapped[str] = mapped_column(String(32), primary_key=True)
    label: Mapped[str] = mapped_column(String(100))
    min_score: Mapped[float] = mapped_column(Float, unique=True)


class CandidateProfileRecord(Base):
    __tablename__ = "candidate_profiles"

    id: Mapped[UUID] = mapped_column(primary_key=True)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    full_name: Mapped[str] = mapped_column(String(200))
    headline: Mapped[str] = mapped_column(String(200))
    city: Mapped[str | None] = mapped_column(String(120))
    grade: Mapped[str | None] = mapped_column(String(32), index=True)
    team_role: Mapped[str | None] = mapped_column(String(32), index=True)
    work_format: Mapped[str | None] = mapped_column(String(32), index=True)
    salary_expectation: Mapped[int | None] = mapped_column(Integer)
    about: Mapped[str | None] = mapped_column(Text)
    open_to_offers: Mapped[bool] = mapped_column(Boolean, index=True)
    fsp_participant_id: Mapped[str | None] = mapped_column(String(64), index=True)
    fsp_synced_at: Mapped[datetime | None] = mapped_column(UtcDateTime())
    created_at: Mapped[datetime] = mapped_column(UtcDateTime())
    updated_at: Mapped[datetime] = mapped_column(UtcDateTime())

    skills: Mapped[list["CandidateSkillRecord"]] = relationship(
        cascade="all, delete-orphan", lazy="selectin", order_by="CandidateSkillRecord.position"
    )
    achievements: Mapped[list["FspAchievementRecord"]] = relationship(
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="FspAchievementRecord.held_on.desc()",
    )
    scores: Mapped[list["CandidateDisciplineScoreRecord"]] = relationship(
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="CandidateDisciplineScoreRecord.score.desc()",
    )


class CandidateSkillRecord(Base):
    __tablename__ = "candidate_skills"
    __table_args__ = (UniqueConstraint("candidate_id", "normalized"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    candidate_id: Mapped[UUID] = mapped_column(
        ForeignKey("candidate_profiles.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(80))
    normalized: Mapped[str] = mapped_column(String(80), index=True)
    position: Mapped[int] = mapped_column(Integer)


class FspAchievementRecord(Base):
    __tablename__ = "fsp_achievements"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    candidate_id: Mapped[UUID] = mapped_column(
        ForeignKey("candidate_profiles.id", ondelete="CASCADE"), index=True
    )
    competition_name: Mapped[str] = mapped_column(String(300))
    held_on: Mapped[date] = mapped_column(Date)
    discipline_code: Mapped[str] = mapped_column(ForeignKey("fsp_disciplines.code"))
    competition_level_code: Mapped[str] = mapped_column(String(64))
    result_code: Mapped[str] = mapped_column(String(64))
    team_role: Mapped[str | None] = mapped_column(String(64))
    sport_rank_code: Mapped[str | None] = mapped_column(String(64))


class CandidateDisciplineScoreRecord(Base):
    """Denormalized categorization result used by talent search."""

    __tablename__ = "candidate_discipline_scores"

    candidate_id: Mapped[UUID] = mapped_column(
        ForeignKey("candidate_profiles.id", ondelete="CASCADE"), primary_key=True
    )
    discipline_code: Mapped[str] = mapped_column(
        ForeignKey("fsp_disciplines.code"), primary_key=True
    )
    score: Mapped[float] = mapped_column(Float, index=True)


class ProfileViewRecord(Base):
    """Employer opened a candidate card — first step of the hiring funnel."""

    __tablename__ = "profile_views"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    employer_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    candidate_id: Mapped[UUID] = mapped_column(
        ForeignKey("candidate_profiles.id", ondelete="CASCADE"), index=True
    )
    viewed_at: Mapped[datetime] = mapped_column(UtcDateTime())
