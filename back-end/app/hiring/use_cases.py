"""Hiring application services."""

from collections.abc import Sequence
from dataclasses import dataclass, field
from uuid import UUID

from app.hiring.domain import (
    CandidateNotAvailableError,
    DuplicateOfferError,
    Offer,
    OfferNotFoundError,
    OfferStatus,
    SalaryRange,
    Vacancy,
    VacancyNotFoundError,
)
from app.hiring.ports import (
    CandidateDirectory,
    DisciplineCatalog,
    OfferRepository,
    OfferView,
    VacancyRepository,
    VacancyWithStats,
)
from app.shared.dependencies import Clock
from app.talent.domain import Grade, WorkFormat, ensure_known_discipline


@dataclass(frozen=True)
class VacancyDraft:
    title: str
    salary_from: int
    salary_to: int
    discipline_code: str | None = None
    grade: Grade | None = None
    work_format: WorkFormat | None = None
    skills: Sequence[str] = field(default_factory=tuple)
    description: str = ""


class PublishVacancy:
    def __init__(
        self, vacancies: VacancyRepository, catalog: DisciplineCatalog, clock: Clock
    ) -> None:
        self._vacancies = vacancies
        self._catalog = catalog
        self._clock = clock

    def execute(self, *, employer_id: UUID, draft: VacancyDraft) -> Vacancy:
        if draft.discipline_code:
            ensure_known_discipline(draft.discipline_code, self._catalog.disciplines())
        vacancy = Vacancy.publish(
            employer_id=employer_id,
            title=draft.title,
            salary=SalaryRange(draft.salary_from, draft.salary_to),
            now=self._clock(),
            discipline_code=draft.discipline_code,
            grade=draft.grade,
            work_format=draft.work_format,
            skills=draft.skills,
            description=draft.description,
        )
        self._vacancies.save(vacancy)
        return vacancy


def _owned_vacancy(vacancies: VacancyRepository, employer_id: UUID, vacancy_id: UUID) -> Vacancy:
    vacancy = vacancies.get(vacancy_id)
    if vacancy is None or vacancy.employer_id != employer_id:
        raise VacancyNotFoundError("Вакансия не найдена")
    return vacancy


class CloseVacancy:
    def __init__(self, vacancies: VacancyRepository) -> None:
        self._vacancies = vacancies

    def execute(self, *, employer_id: UUID, vacancy_id: UUID) -> Vacancy:
        vacancy = _owned_vacancy(self._vacancies, employer_id, vacancy_id)
        vacancy.close()
        self._vacancies.save(vacancy)
        return vacancy


class ListEmployerVacancies:
    def __init__(self, vacancies: VacancyRepository) -> None:
        self._vacancies = vacancies

    def execute(self, *, employer_id: UUID) -> list[VacancyWithStats]:
        return self._vacancies.list_for_employer(employer_id)


class SendOffer:
    """H3: direct offer of a vacancy with a salary to a chosen candidate."""

    def __init__(
        self,
        vacancies: VacancyRepository,
        offers: OfferRepository,
        candidates: CandidateDirectory,
        clock: Clock,
    ) -> None:
        self._vacancies = vacancies
        self._offers = offers
        self._candidates = candidates
        self._clock = clock

    def execute(
        self, *, employer_id: UUID, vacancy_id: UUID, candidate_id: UUID, salary: int, message: str
    ) -> OfferView:
        vacancy = _owned_vacancy(self._vacancies, employer_id, vacancy_id)
        candidate = self._candidates.snapshot(candidate_id)
        if candidate is None:
            raise CandidateNotAvailableError("Кандидат не найден")
        if self._offers.has_active(vacancy_id=vacancy.id, candidate_id=candidate.profile_id):
            raise DuplicateOfferError("Кандидату уже отправлено предложение по этой вакансии")
        offer = Offer.send(
            vacancy=vacancy, candidate=candidate, salary=salary, message=message, now=self._clock()
        )
        self._offers.save(offer)
        return _require_view(self._offers, offer.id)


class ListEmployerOffers:
    def __init__(self, offers: OfferRepository) -> None:
        self._offers = offers

    def execute(self, *, employer_id: UUID, status: OfferStatus | None = None) -> list[OfferView]:
        return self._offers.list_for_employer(employer_id, status)


class WithdrawOffer:
    def __init__(self, offers: OfferRepository, clock: Clock) -> None:
        self._offers = offers
        self._clock = clock

    def execute(self, *, employer_id: UUID, offer_id: UUID) -> OfferView:
        offer = self._offers.get(offer_id)
        if offer is None or offer.employer_id != employer_id:
            raise OfferNotFoundError("Предложение не найдено")
        offer.withdraw(self._clock())
        self._offers.save(offer)
        return _require_view(self._offers, offer.id)


class CandidateOffers:
    """H4: the candidate's inbox — open, accept or decline with a reason."""

    def __init__(
        self, offers: OfferRepository, candidates: CandidateDirectory, clock: Clock
    ) -> None:
        self._offers = offers
        self._candidates = candidates
        self._clock = clock

    def list(self, *, user_id: UUID) -> list[OfferView]:
        profile_id = self._candidates.profile_id_for_user(user_id)
        return self._offers.list_for_candidate(profile_id) if profile_id else []

    def open(self, *, user_id: UUID, offer_id: UUID) -> OfferView:
        offer = self._owned(user_id, offer_id)
        offer.mark_viewed(self._clock())
        return self._persist(offer)

    def accept(self, *, user_id: UUID, offer_id: UUID) -> OfferView:
        offer = self._owned(user_id, offer_id)
        offer.accept(self._clock())
        return self._persist(offer)

    def decline(self, *, user_id: UUID, offer_id: UUID, reason: str) -> OfferView:
        offer = self._owned(user_id, offer_id)
        offer.decline(reason, self._clock())
        return self._persist(offer)

    def _owned(self, user_id: UUID, offer_id: UUID) -> Offer:
        offer = self._offers.get(offer_id)
        profile_id = self._candidates.profile_id_for_user(user_id)
        if offer is None or profile_id is None or offer.candidate_id != profile_id:
            raise OfferNotFoundError("Предложение не найдено")
        return offer

    def _persist(self, offer: Offer) -> OfferView:
        self._offers.save(offer)
        return _require_view(self._offers, offer.id)


def _require_view(offers: OfferRepository, offer_id: UUID) -> OfferView:
    view = offers.view(offer_id)
    if view is None:  # pragma: no cover - the offer was just saved in this unit of work
        raise OfferNotFoundError("Предложение не найдено")
    return view
