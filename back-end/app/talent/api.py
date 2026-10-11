"""Candidate profile and talent search endpoints."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.config import Settings
from app.fsp.gateway import FspGateway
from app.identity.dependencies import require_candidate, require_employer
from app.identity.domain import User
from app.shared.dependencies import Clock, get_app_settings, get_clock
from app.shared.http import ERROR_RESPONSES
from app.talent.dependencies import (
    get_fsp_gateway,
    get_profile_repository,
    get_profile_view_log,
    get_reference_data,
)
from app.talent.domain import Grade, TeamRole, WorkFormat
from app.talent.repository import (
    SqlAlchemyCandidateProfileRepository,
    SqlAlchemyProfileViewLog,
    SqlAlchemyTalentReferenceData,
)
from app.talent.schemas import (
    CandidateProfileResponse,
    CandidateSearchResponse,
    CandidateSummaryResponse,
    FspSyncResponse,
    ProfileUpdateRequest,
)
from app.talent.use_cases import (
    CandidateSearchCriteria,
    EnsureCandidateProfile,
    SearchCandidates,
    SyncFspAchievements,
    UpdateCandidateProfile,
    ViewCandidateProfile,
)

router = APIRouter(prefix="/candidates", tags=["talent"], responses=ERROR_RESPONSES)

Profiles = Annotated[SqlAlchemyCandidateProfileRepository, Depends(get_profile_repository)]
Reference = Annotated[SqlAlchemyTalentReferenceData, Depends(get_reference_data)]
AppClock = Annotated[Clock, Depends(get_clock)]
Candidate = Annotated[User, Depends(require_candidate)]
Employer = Annotated[User, Depends(require_employer)]


@router.get("/me")
def get_my_profile(
    user: Candidate, profiles: Profiles, reference: Reference, clock: AppClock
) -> CandidateProfileResponse:
    profile = EnsureCandidateProfile(profiles, clock).execute(
        user_id=user.id, full_name=user.full_name
    )
    return CandidateProfileResponse.from_domain(profile, reference.scoring_rules())


@router.put("/me")
def update_my_profile(
    payload: ProfileUpdateRequest,
    user: Candidate,
    profiles: Profiles,
    reference: Reference,
    clock: AppClock,
    settings: Settings = Depends(get_app_settings),
) -> CandidateProfileResponse:
    use_case = UpdateCandidateProfile(
        profiles, EnsureCandidateProfile(profiles, clock), settings.candidate_skills_max, clock
    )
    profile = use_case.execute(
        user_id=user.id, full_name=user.full_name, details=payload.to_details()
    )
    return CandidateProfileResponse.from_domain(profile, reference.scoring_rules())


@router.post("/me/fsp-sync")
def sync_fsp_achievements(
    user: Candidate,
    profiles: Profiles,
    reference: Reference,
    clock: AppClock,
    gateway: FspGateway = Depends(get_fsp_gateway),
) -> FspSyncResponse:
    report = SyncFspAchievements(profiles, gateway, reference, clock).execute(user_id=user.id)
    return FspSyncResponse.from_report(report, reference.scoring_rules())


@router.get("")
def search_candidates(
    _: Employer,
    profiles: Profiles,
    reference: Reference,
    settings: Settings = Depends(get_app_settings),
    discipline: str | None = None,
    min_level: str | None = None,
    grade: Grade | None = None,
    team_role: TeamRole | None = None,
    work_format: WorkFormat | None = None,
    skill: Annotated[str | None, Query(max_length=80)] = None,
    max_salary: Annotated[int | None, Query(gt=0)] = None,
    verified_only: bool = False,
    limit: Annotated[int | None, Query(gt=0)] = None,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> CandidateSearchResponse:
    page_size = min(limit or settings.search_page_size_default, settings.search_page_size_max)
    page = SearchCandidates(profiles, reference).execute(
        CandidateSearchCriteria(
            limit=page_size,
            offset=offset,
            discipline_code=discipline,
            min_level_code=min_level,
            grade=grade,
            team_role=team_role,
            work_format=work_format,
            skill=skill,
            max_salary=max_salary,
            verified_only=verified_only,
        )
    )
    rules = reference.scoring_rules()
    return CandidateSearchResponse(
        items=[CandidateSummaryResponse.from_match(item, rules) for item in page.items],
        total=page.total,
        limit=page_size,
        offset=offset,
    )


@router.get("/{profile_id}")
def view_candidate(
    profile_id: UUID,
    employer: Employer,
    profiles: Profiles,
    reference: Reference,
    clock: AppClock,
    views: SqlAlchemyProfileViewLog = Depends(get_profile_view_log),
) -> CandidateProfileResponse:
    profile = ViewCandidateProfile(profiles, views, clock).execute(
        employer_id=employer.id, profile_id=profile_id
    )
    return CandidateProfileResponse.from_domain(profile, reference.scoring_rules())
