"""Talent application services (use cases)."""

from dataclasses import dataclass
from uuid import UUID

from app.fsp.gateway import FspGateway
from app.fsp.translator import translate_participant
from app.shared.dependencies import Clock
from app.talent.domain import (
    CandidateProfile,
    CandidateProfileNotFoundError,
    FspParticipantNotLinkedError,
    Grade,
    ProfileDetails,
    TeamRole,
    WorkFormat,
    ensure_known_discipline,
)
from app.talent.ports import (
    CandidateProfileRepository,
    CandidateSearchPage,
    CandidateSearchQuery,
    ProfileViewLog,
    TalentReferenceData,
)


class EnsureCandidateProfile:
    """Every candidate has exactly one profile; it is started on first access."""

    def __init__(self, profiles: CandidateProfileRepository, clock: Clock) -> None:
        self._profiles = profiles
        self._clock = clock

    def execute(self, *, user_id: UUID, full_name: str) -> CandidateProfile:
        profile = self._profiles.get_by_user(user_id)
        if profile is None:
            profile = CandidateProfile.start(
                user_id=user_id, full_name=full_name, now=self._clock()
            )
            self._profiles.save(profile)
        return profile


class UpdateCandidateProfile:
    def __init__(
        self,
        profiles: CandidateProfileRepository,
        ensure_profile: EnsureCandidateProfile,
        max_skills: int,
        clock: Clock,
    ) -> None:
        self._profiles = profiles
        self._ensure_profile = ensure_profile
        self._max_skills = max_skills
        self._clock = clock

    def execute(
        self, *, user_id: UUID, full_name: str, details: ProfileDetails
    ) -> CandidateProfile:
        profile = self._ensure_profile.execute(user_id=user_id, full_name=full_name)
        profile.update_details(details, max_skills=self._max_skills, now=self._clock())
        self._profiles.save(profile)
        return profile


@dataclass(frozen=True)
class FspSyncReport:
    profile: CandidateProfile
    imported: int
    skipped: tuple[str, ...]


class SyncFspAchievements:
    """H1: enrich the profile with confirmed FSP achievements and recompute categories."""

    def __init__(
        self,
        profiles: CandidateProfileRepository,
        gateway: FspGateway,
        reference: TalentReferenceData,
        clock: Clock,
    ) -> None:
        self._profiles = profiles
        self._gateway = gateway
        self._reference = reference
        self._clock = clock

    def execute(self, *, user_id: UUID) -> FspSyncReport:
        profile = self._profiles.get_by_user(user_id)
        if profile is None or profile.fsp_participant_id is None:
            raise FspParticipantNotLinkedError("Укажите ID участника ФСП в профиле")
        participant = self._gateway.fetch_participant(profile.fsp_participant_id)
        translation = translate_participant(participant, self._reference.fsp_vocabulary())
        profile.apply_fsp_sync(
            participant_full_name=participant.full_name,
            achievements=translation.achievements,
            rules=self._reference.scoring_rules(),
            now=self._clock(),
        )
        self._profiles.save(profile)
        return FspSyncReport(profile, len(translation.achievements), translation.skipped)


@dataclass(frozen=True)
class CandidateSearchCriteria:
    """What the employer asks for, in business terms (levels, not scores)."""

    limit: int
    offset: int = 0
    discipline_code: str | None = None
    min_level_code: str | None = None
    grade: Grade | None = None
    team_role: TeamRole | None = None
    work_format: WorkFormat | None = None
    skill: str | None = None
    max_salary: int | None = None
    verified_only: bool = False


class SearchCandidates:
    """H2: search by confirmed category instead of keywords."""

    def __init__(
        self, profiles: CandidateProfileRepository, reference: TalentReferenceData
    ) -> None:
        self._profiles = profiles
        self._reference = reference

    def execute(self, criteria: CandidateSearchCriteria) -> CandidateSearchPage:
        if criteria.discipline_code:
            ensure_known_discipline(criteria.discipline_code, self._reference.disciplines())
        min_score = (
            self._reference.scoring_rules().level_by_code(criteria.min_level_code).min_score
            if criteria.min_level_code
            else None
        )
        return self._profiles.search(
            CandidateSearchQuery(
                limit=criteria.limit,
                offset=criteria.offset,
                discipline_code=criteria.discipline_code,
                min_score=min_score,
                grade=criteria.grade,
                team_role=criteria.team_role,
                work_format=criteria.work_format,
                skill=criteria.skill.strip() if criteria.skill else None,
                max_salary=criteria.max_salary,
                verified_only=criteria.verified_only,
            )
        )


class ViewCandidateProfile:
    """Employer opens a candidate card; the view feeds the hiring funnel (H5)."""

    def __init__(
        self, profiles: CandidateProfileRepository, views: ProfileViewLog, clock: Clock
    ) -> None:
        self._profiles = profiles
        self._views = views
        self._clock = clock

    def execute(self, *, employer_id: UUID, profile_id: UUID) -> CandidateProfile:
        profile = self._profiles.get(profile_id)
        if profile is None or not profile.open_to_offers:
            raise CandidateProfileNotFoundError("Кандидат не найден или скрыл профиль")
        self._views.record(
            employer_id=employer_id, candidate_id=profile.id, viewed_at=self._clock()
        )
        return profile
