"""Ports of the talent context."""

from dataclasses import dataclass
from datetime import datetime
from typing import Protocol
from uuid import UUID

from app.fsp.translator import FspVocabulary
from app.talent.domain import (
    CandidateProfile,
    Discipline,
    Grade,
    ScoringRules,
    TeamRole,
    WorkFormat,
)


@dataclass(frozen=True)
class CandidateSearchQuery:
    """Repository-level search specification (levels already resolved to scores)."""

    limit: int
    offset: int = 0
    discipline_code: str | None = None
    min_score: float | None = None
    grade: Grade | None = None
    team_role: TeamRole | None = None
    work_format: WorkFormat | None = None
    skill: str | None = None
    max_salary: int | None = None
    verified_only: bool = False


@dataclass(frozen=True)
class CandidateMatch:
    profile: CandidateProfile
    relevant_score: float


@dataclass(frozen=True)
class CandidateSearchPage:
    items: list[CandidateMatch]
    total: int


class CandidateProfileRepository(Protocol):
    def get(self, profile_id: UUID) -> CandidateProfile | None: ...

    def get_by_user(self, user_id: UUID) -> CandidateProfile | None: ...

    def save(self, profile: CandidateProfile) -> None: ...

    def search(self, query: CandidateSearchQuery) -> CandidateSearchPage: ...


class TalentReferenceData(Protocol):
    def scoring_rules(self) -> ScoringRules: ...

    def fsp_vocabulary(self) -> FspVocabulary: ...

    def disciplines(self) -> list[Discipline]: ...


class ProfileViewLog(Protocol):
    def record(self, *, employer_id: UUID, candidate_id: UUID, viewed_at: datetime) -> None: ...
