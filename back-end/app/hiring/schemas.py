"""HTTP contracts of the hiring context."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.hiring.domain import OfferStatus, Vacancy
from app.hiring.ports import OfferView, VacancyWithStats
from app.hiring.use_cases import VacancyDraft
from app.talent.domain import Grade, WorkFormat


class VacancyCreateRequest(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    salary_from: int = Field(gt=0)
    salary_to: int = Field(gt=0)
    discipline_code: str | None = Field(default=None, max_length=64)
    grade: Grade | None = None
    work_format: WorkFormat | None = None
    skills: list[str] = Field(default_factory=list, max_length=30)
    description: str = Field(default="", max_length=4000)

    def to_draft(self) -> VacancyDraft:
        return VacancyDraft(**self.model_dump())


class VacancyResponse(BaseModel):
    id: UUID
    title: str
    salary_from: int
    salary_to: int
    discipline_code: str | None
    grade: Grade | None
    work_format: WorkFormat | None
    skills: list[str]
    description: str
    is_open: bool
    created_at: datetime

    @classmethod
    def from_domain(cls, vacancy: Vacancy) -> "VacancyResponse":
        return cls(
            id=vacancy.id,
            title=vacancy.title,
            salary_from=vacancy.salary.salary_from,
            salary_to=vacancy.salary.salary_to,
            discipline_code=vacancy.discipline_code,
            grade=vacancy.grade,
            work_format=vacancy.work_format,
            skills=vacancy.skills,
            description=vacancy.description,
            is_open=vacancy.is_open,
            created_at=vacancy.created_at,
        )


class VacancyWithStatsResponse(VacancyResponse):
    offers_total: int
    offers_awaiting: int
    offers_accepted: int

    @classmethod
    def from_stats(cls, item: VacancyWithStats) -> "VacancyWithStatsResponse":
        return cls(
            **VacancyResponse.from_domain(item.vacancy).model_dump(),
            offers_total=item.offers_total,
            offers_awaiting=item.offers_awaiting,
            offers_accepted=item.offers_accepted,
        )


class OfferCreateRequest(BaseModel):
    vacancy_id: UUID
    candidate_id: UUID
    salary: int = Field(gt=0)
    message: str = Field(min_length=10, max_length=2000)


class OfferDeclineRequest(BaseModel):
    reason: str = Field(min_length=1, max_length=1000)


class OfferResponse(BaseModel):
    id: UUID
    status: OfferStatus
    salary: int
    message: str
    created_at: datetime
    viewed_at: datetime | None
    responded_at: datetime | None
    decline_reason: str | None
    awaits_response: bool
    vacancy: VacancyResponse
    company_name: str
    candidate_id: UUID
    candidate_name: str
    candidate_headline: str

    @classmethod
    def from_view(cls, view: OfferView) -> "OfferResponse":
        offer = view.offer
        return cls(
            id=offer.id,
            status=offer.status,
            salary=offer.salary,
            message=offer.message,
            created_at=offer.created_at,
            viewed_at=offer.viewed_at,
            responded_at=offer.responded_at,
            decline_reason=offer.decline_reason,
            awaits_response=offer.awaits_response,
            vacancy=VacancyResponse.from_domain(view.vacancy),
            company_name=view.company_name,
            candidate_id=offer.candidate_id,
            candidate_name=view.candidate_name,
            candidate_headline=view.candidate_headline,
        )
