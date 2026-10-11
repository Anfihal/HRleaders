"""HTTP contracts of the talent context."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.talent.domain import (
    CandidateProfile,
    FspAchievement,
    Grade,
    ProfileDetails,
    ScoringRules,
    TalentCategory,
    TeamRole,
    VerificationLevel,
    WorkFormat,
)
from app.talent.ports import CandidateMatch
from app.talent.use_cases import FspSyncReport


class ProfileUpdateRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=200)
    headline: str = Field(min_length=2, max_length=200)
    city: str | None = Field(default=None, max_length=120)
    grade: Grade | None = None
    team_role: TeamRole | None = None
    work_format: WorkFormat | None = None
    salary_expectation: int | None = Field(default=None, gt=0)
    skills: list[str] = Field(default_factory=list)
    about: str | None = Field(default=None, max_length=4000)
    open_to_offers: bool = True
    fsp_participant_id: str | None = Field(default=None, max_length=64)

    def to_details(self) -> ProfileDetails:
        return ProfileDetails(**self.model_dump())


class VerificationLevelResponse(BaseModel):
    code: str
    label: str
    min_score: float

    @classmethod
    def from_domain(cls, level: VerificationLevel) -> "VerificationLevelResponse":
        return cls(code=level.code, label=level.label, min_score=level.min_score)


class TalentCategoryResponse(BaseModel):
    discipline_code: str
    score: float
    level: VerificationLevelResponse
    next_level: VerificationLevelResponse | None
    points_to_next_level: float | None

    @classmethod
    def from_domain(cls, category: TalentCategory) -> "TalentCategoryResponse":
        return cls(
            discipline_code=category.discipline_code,
            score=category.score,
            level=VerificationLevelResponse.from_domain(category.level),
            next_level=VerificationLevelResponse.from_domain(category.next_level)
            if category.next_level
            else None,
            points_to_next_level=category.points_to_next_level,
        )


class FspAchievementResponse(BaseModel):
    competition_name: str
    held_on: date
    discipline_code: str
    competition_level_code: str
    result_code: str
    team_role: str | None
    sport_rank_code: str | None

    @classmethod
    def from_domain(cls, achievement: FspAchievement) -> "FspAchievementResponse":
        return cls.model_validate(achievement, from_attributes=True)


class CandidateSummaryResponse(BaseModel):
    id: UUID
    full_name: str
    headline: str
    city: str | None
    grade: Grade | None
    team_role: TeamRole | None
    work_format: WorkFormat | None
    salary_expectation: int | None
    skills: list[str]
    is_fsp_verified: bool
    relevant_score: float
    categories: list[TalentCategoryResponse]

    @classmethod
    def from_match(cls, match: CandidateMatch, rules: ScoringRules) -> "CandidateSummaryResponse":
        profile = match.profile
        return cls(
            id=profile.id,
            full_name=profile.full_name,
            headline=profile.headline,
            city=profile.city,
            grade=profile.grade,
            team_role=profile.team_role,
            work_format=profile.work_format,
            salary_expectation=profile.salary_expectation,
            skills=profile.skills,
            is_fsp_verified=profile.is_fsp_verified,
            relevant_score=match.relevant_score,
            categories=_categories(profile, rules),
        )


class CandidateSearchResponse(BaseModel):
    items: list[CandidateSummaryResponse]
    total: int
    limit: int
    offset: int


class CandidateProfileResponse(BaseModel):
    id: UUID
    full_name: str
    headline: str
    city: str | None
    grade: Grade | None
    team_role: TeamRole | None
    work_format: WorkFormat | None
    salary_expectation: int | None
    skills: list[str]
    about: str | None
    open_to_offers: bool
    fsp_participant_id: str | None
    fsp_synced_at: datetime | None
    is_fsp_verified: bool
    achievements: list[FspAchievementResponse]
    categories: list[TalentCategoryResponse]
    updated_at: datetime

    @classmethod
    def from_domain(
        cls, profile: CandidateProfile, rules: ScoringRules
    ) -> "CandidateProfileResponse":
        return cls(
            id=profile.id,
            full_name=profile.full_name,
            headline=profile.headline,
            city=profile.city,
            grade=profile.grade,
            team_role=profile.team_role,
            work_format=profile.work_format,
            salary_expectation=profile.salary_expectation,
            skills=profile.skills,
            about=profile.about,
            open_to_offers=profile.open_to_offers,
            fsp_participant_id=profile.fsp_participant_id,
            fsp_synced_at=profile.fsp_synced_at,
            is_fsp_verified=profile.is_fsp_verified,
            achievements=[FspAchievementResponse.from_domain(a) for a in profile.achievements],
            categories=_categories(profile, rules),
            updated_at=profile.updated_at,
        )


class FspSyncResponse(BaseModel):
    profile: CandidateProfileResponse
    imported: int
    skipped: list[str]

    @classmethod
    def from_report(cls, report: FspSyncReport, rules: ScoringRules) -> "FspSyncResponse":
        return cls(
            profile=CandidateProfileResponse.from_domain(report.profile, rules),
            imported=report.imported,
            skipped=list(report.skipped),
        )


def _categories(profile: CandidateProfile, rules: ScoringRules) -> list[TalentCategoryResponse]:
    return [
        TalentCategoryResponse.from_domain(rules.categorize(score))
        for score in profile.discipline_scores
    ]
