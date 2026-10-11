"""Employer analytics endpoint."""

from fastapi import APIRouter, Depends

from app.analytics.repository import SqlAlchemyAnalyticsReadModel
from app.analytics.schemas import EmployerOverviewResponse
from app.analytics.use_cases import BuildEmployerOverview
from app.config import Settings
from app.identity.dependencies import require_employer
from app.identity.domain import User
from app.shared.database import DatabaseSession
from app.shared.dependencies import get_app_settings
from app.shared.http import ERROR_RESPONSES
from app.talent.dependencies import get_reference_data
from app.talent.repository import SqlAlchemyTalentReferenceData

router = APIRouter(prefix="/analytics", tags=["analytics"], responses=ERROR_RESPONSES)


@router.get("/overview")
def employer_overview(
    session: DatabaseSession,
    employer: User = Depends(require_employer),
    reference: SqlAlchemyTalentReferenceData = Depends(get_reference_data),
    settings: Settings = Depends(get_app_settings),
) -> EmployerOverviewResponse:
    use_case = BuildEmployerOverview(
        SqlAlchemyAnalyticsReadModel(session), reference, settings.analytics_recent_declines
    )
    return EmployerOverviewResponse.from_domain(use_case.execute(employer_id=employer.id))
