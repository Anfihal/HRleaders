"""Ports and read models of the hiring context."""

from dataclasses import dataclass
from typing import Protocol
from uuid import UUID

from app.hiring.domain import CandidateSnapshot, Offer, OfferStatus, Vacancy
from app.talent.domain import Discipline


@dataclass(frozen=True)
class VacancyWithStats:
    vacancy: Vacancy
    offers_total: int
    offers_awaiting: int
    offers_accepted: int


@dataclass(frozen=True)
class OfferView:
    """Offer enriched with what both sides need to see in lists."""

    offer: Offer
    vacancy: Vacancy
    company_name: str
    candidate_name: str
    candidate_headline: str


class VacancyRepository(Protocol):
    def get(self, vacancy_id: UUID) -> Vacancy | None: ...

    def save(self, vacancy: Vacancy) -> None: ...

    def list_for_employer(self, employer_id: UUID) -> list[VacancyWithStats]: ...


class OfferRepository(Protocol):
    def get(self, offer_id: UUID) -> Offer | None: ...

    def save(self, offer: Offer) -> None: ...

    def has_active(self, *, vacancy_id: UUID, candidate_id: UUID) -> bool: ...

    def view(self, offer_id: UUID) -> OfferView | None: ...

    def list_for_employer(
        self, employer_id: UUID, status: OfferStatus | None = None
    ) -> list[OfferView]: ...

    def list_for_candidate(self, candidate_id: UUID) -> list[OfferView]: ...


class DisciplineCatalog(Protocol):
    """FSP disciplines a vacancy may target (reference data of the talent context)."""

    def disciplines(self) -> list[Discipline]: ...


class CandidateDirectory(Protocol):
    """Hiring's view of the talent context."""

    def snapshot(self, profile_id: UUID) -> CandidateSnapshot | None: ...

    def profile_id_for_user(self, user_id: UUID) -> UUID | None: ...
