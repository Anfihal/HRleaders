"""Read-side port of the analytics context."""

from datetime import timedelta
from typing import Protocol
from uuid import UUID

from app.analytics.domain import FunnelCounts
from app.talent.domain import DisciplineScore


class AnalyticsReadModel(Protocol):
    def open_candidates(self) -> tuple[int, int]:
        """(candidates open to offers, of them verified by FSP)."""
        ...

    def open_candidate_scores(self) -> list[DisciplineScore]: ...

    def funnel(self, employer_id: UUID) -> FunnelCounts: ...

    def response_durations(self, employer_id: UUID) -> list[timedelta]: ...

    def open_vacancies(self, employer_id: UUID) -> int: ...

    def recent_decline_reasons(self, employer_id: UUID, limit: int) -> list[str]: ...
