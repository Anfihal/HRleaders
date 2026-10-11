"""Vacancy and direct-offer endpoints (reverse hiring)."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status

from app.hiring.dependencies import (
    get_candidate_directory,
    get_offer_repository,
    get_vacancy_repository,
)
from app.hiring.domain import OfferStatus
from app.hiring.repository import (
    SqlAlchemyCandidateDirectory,
    SqlAlchemyOfferRepository,
    SqlAlchemyVacancyRepository,
)
from app.hiring.schemas import (
    OfferCreateRequest,
    OfferDeclineRequest,
    OfferResponse,
    VacancyCreateRequest,
    VacancyResponse,
    VacancyWithStatsResponse,
)
from app.hiring.use_cases import (
    CandidateOffers,
    CloseVacancy,
    ListEmployerOffers,
    ListEmployerVacancies,
    PublishVacancy,
    SendOffer,
    WithdrawOffer,
)
from app.identity.dependencies import require_candidate, require_employer
from app.identity.domain import User
from app.shared.dependencies import Clock, get_clock
from app.shared.http import ERROR_RESPONSES
from app.talent.dependencies import get_reference_data
from app.talent.repository import SqlAlchemyTalentReferenceData

vacancies_router = APIRouter(prefix="/vacancies", tags=["hiring"], responses=ERROR_RESPONSES)
offers_router = APIRouter(prefix="/offers", tags=["hiring"], responses=ERROR_RESPONSES)

Vacancies = Annotated[SqlAlchemyVacancyRepository, Depends(get_vacancy_repository)]
Offers = Annotated[SqlAlchemyOfferRepository, Depends(get_offer_repository)]
Directory = Annotated[SqlAlchemyCandidateDirectory, Depends(get_candidate_directory)]
Reference = Annotated[SqlAlchemyTalentReferenceData, Depends(get_reference_data)]
AppClock = Annotated[Clock, Depends(get_clock)]
Candidate = Annotated[User, Depends(require_candidate)]
Employer = Annotated[User, Depends(require_employer)]


@vacancies_router.post("", status_code=status.HTTP_201_CREATED)
def publish_vacancy(
    payload: VacancyCreateRequest,
    employer: Employer,
    vacancies: Vacancies,
    reference: Reference,
    clock: AppClock,
) -> VacancyResponse:
    vacancy = PublishVacancy(vacancies, reference, clock).execute(
        employer_id=employer.id, draft=payload.to_draft()
    )
    return VacancyResponse.from_domain(vacancy)


@vacancies_router.get("")
def list_vacancies(employer: Employer, vacancies: Vacancies) -> list[VacancyWithStatsResponse]:
    items = ListEmployerVacancies(vacancies).execute(employer_id=employer.id)
    return [VacancyWithStatsResponse.from_stats(item) for item in items]


@vacancies_router.post("/{vacancy_id}/close")
def close_vacancy(vacancy_id: UUID, employer: Employer, vacancies: Vacancies) -> VacancyResponse:
    vacancy = CloseVacancy(vacancies).execute(employer_id=employer.id, vacancy_id=vacancy_id)
    return VacancyResponse.from_domain(vacancy)


@offers_router.post("", status_code=status.HTTP_201_CREATED)
def send_offer(
    payload: OfferCreateRequest,
    employer: Employer,
    vacancies: Vacancies,
    offers: Offers,
    directory: Directory,
    clock: AppClock,
) -> OfferResponse:
    view = SendOffer(vacancies, offers, directory, clock).execute(
        employer_id=employer.id,
        vacancy_id=payload.vacancy_id,
        candidate_id=payload.candidate_id,
        salary=payload.salary,
        message=payload.message,
    )
    return OfferResponse.from_view(view)


@offers_router.get("")
def list_sent_offers(
    employer: Employer, offers: Offers, status: OfferStatus | None = None
) -> list[OfferResponse]:
    views = ListEmployerOffers(offers).execute(employer_id=employer.id, status=status)
    return [OfferResponse.from_view(view) for view in views]


@offers_router.post("/{offer_id}/withdraw")
def withdraw_offer(
    offer_id: UUID, employer: Employer, offers: Offers, clock: AppClock
) -> OfferResponse:
    view = WithdrawOffer(offers, clock).execute(employer_id=employer.id, offer_id=offer_id)
    return OfferResponse.from_view(view)


@offers_router.get("/incoming")
def list_incoming_offers(
    candidate: Candidate, offers: Offers, directory: Directory, clock: AppClock
) -> list[OfferResponse]:
    views = CandidateOffers(offers, directory, clock).list(user_id=candidate.id)
    return [OfferResponse.from_view(view) for view in views]


@offers_router.post("/{offer_id}/view")
def open_offer(
    offer_id: UUID, candidate: Candidate, offers: Offers, directory: Directory, clock: AppClock
) -> OfferResponse:
    view = CandidateOffers(offers, directory, clock).open(user_id=candidate.id, offer_id=offer_id)
    return OfferResponse.from_view(view)


@offers_router.post("/{offer_id}/accept")
def accept_offer(
    offer_id: UUID, candidate: Candidate, offers: Offers, directory: Directory, clock: AppClock
) -> OfferResponse:
    view = CandidateOffers(offers, directory, clock).accept(user_id=candidate.id, offer_id=offer_id)
    return OfferResponse.from_view(view)


@offers_router.post("/{offer_id}/decline")
def decline_offer(
    offer_id: UUID,
    payload: OfferDeclineRequest,
    candidate: Candidate,
    offers: Offers,
    directory: Directory,
    clock: AppClock,
) -> OfferResponse:
    view = CandidateOffers(offers, directory, clock).decline(
        user_id=candidate.id, offer_id=offer_id, reason=payload.reason
    )
    return OfferResponse.from_view(view)
