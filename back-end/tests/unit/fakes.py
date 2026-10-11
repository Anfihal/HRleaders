"""In-memory adapters of the hiring ports — fast unit tests of the use cases."""

from copy import deepcopy
from uuid import UUID

from app.hiring.domain import ACTIVE_STATUSES, CandidateSnapshot, Offer, OfferStatus, Vacancy
from app.hiring.ports import OfferView, VacancyWithStats
from app.talent.domain import Discipline


class InMemoryVacancies:
    def __init__(self) -> None:
        self.items: dict[UUID, Vacancy] = {}

    def get(self, vacancy_id: UUID) -> Vacancy | None:
        item = self.items.get(vacancy_id)
        return deepcopy(item) if item else None

    def save(self, vacancy: Vacancy) -> None:
        self.items[vacancy.id] = deepcopy(vacancy)

    def list_for_employer(self, employer_id: UUID) -> list[VacancyWithStats]:
        return [
            VacancyWithStats(v, 0, 0, 0)
            for v in self.items.values()
            if v.employer_id == employer_id
        ]


class InMemoryOffers:
    def __init__(self, vacancies: InMemoryVacancies) -> None:
        self.items: dict[UUID, Offer] = {}
        self._vacancies = vacancies

    def get(self, offer_id: UUID) -> Offer | None:
        item = self.items.get(offer_id)
        return deepcopy(item) if item else None

    def save(self, offer: Offer) -> None:
        self.items[offer.id] = deepcopy(offer)

    def has_active(self, *, vacancy_id: UUID, candidate_id: UUID) -> bool:
        return any(
            o.vacancy_id == vacancy_id
            and o.candidate_id == candidate_id
            and o.status in ACTIVE_STATUSES
            for o in self.items.values()
        )

    def view(self, offer_id: UUID) -> OfferView | None:
        offer = self.get(offer_id)
        if offer is None:
            return None
        vacancy = self._vacancies.items[offer.vacancy_id]
        return OfferView(offer, vacancy, "Радиус Софт", "Иванов Артём", "Backend Go")

    def list_for_employer(
        self, employer_id: UUID, status: OfferStatus | None = None
    ) -> list[OfferView]:
        return [
            view
            for o in self.items.values()
            if o.employer_id == employer_id and (status is None or o.status is status)
            if (view := self.view(o.id)) is not None
        ]

    def list_for_candidate(self, candidate_id: UUID) -> list[OfferView]:
        return [
            view
            for o in self.items.values()
            if o.candidate_id == candidate_id
            if (view := self.view(o.id)) is not None
        ]


class InMemoryCandidates:
    def __init__(self) -> None:
        self.by_profile: dict[UUID, CandidateSnapshot] = {}
        self.profile_by_user: dict[UUID, UUID] = {}

    def add(self, user_id: UUID, profile_id: UUID, *, open_to_offers: bool = True) -> None:
        self.by_profile[profile_id] = CandidateSnapshot(profile_id, open_to_offers)
        self.profile_by_user[user_id] = profile_id

    def snapshot(self, profile_id: UUID) -> CandidateSnapshot | None:
        return self.by_profile.get(profile_id)

    def profile_id_for_user(self, user_id: UUID) -> UUID | None:
        return self.profile_by_user.get(user_id)


class StaticDisciplines:
    def disciplines(self) -> list[Discipline]:
        return [
            Discipline("algorithmic", "Программирование алгоритмическое"),
            Discipline("product", "Программирование продуктовое"),
        ]
