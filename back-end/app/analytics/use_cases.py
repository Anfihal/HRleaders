"""Analytics application services."""

from uuid import UUID

from app.analytics.domain import (
    EmployerOverview,
    FunnelRates,
    TalentPool,
    average_hours,
    level_distribution,
)
from app.analytics.ports import AnalyticsReadModel
from app.talent.ports import TalentReferenceData


class BuildEmployerOverview:
    """H5: one screen answering "is reverse hiring with FSP data working for me?"."""

    def __init__(
        self,
        read_model: AnalyticsReadModel,
        reference: TalentReferenceData,
        recent_declines_limit: int,
    ) -> None:
        self._read_model = read_model
        self._reference = reference
        self._recent_declines_limit = recent_declines_limit

    def execute(self, *, employer_id: UUID) -> EmployerOverview:
        open_total, verified = self._read_model.open_candidates()
        funnel = self._read_model.funnel(employer_id)
        return EmployerOverview(
            talent_pool=TalentPool(
                candidates_open=open_total,
                candidates_verified=verified,
                distribution=level_distribution(
                    self._read_model.open_candidate_scores(), self._reference.scoring_rules()
                ),
            ),
            funnel=funnel,
            rates=FunnelRates.from_counts(funnel),
            average_response_hours=average_hours(self._read_model.response_durations(employer_id)),
            open_vacancies=self._read_model.open_vacancies(employer_id),
            recent_decline_reasons=self._read_model.recent_decline_reasons(
                employer_id, self._recent_declines_limit
            ),
        )
