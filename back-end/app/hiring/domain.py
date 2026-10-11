"""Hiring domain: vacancies and direct offers with salary (reverse hiring).

H3: the employer reaches out first with a concrete vacancy and salary.
H4: the candidate answers transparently — declining always requires a reason.
"""

from collections.abc import Sequence
from dataclasses import dataclass, field
from datetime import datetime
from enum import StrEnum
from uuid import UUID, uuid4

from app.shared.errors import ConflictError, DomainValidationError, NotFoundError
from app.talent.domain import Grade, WorkFormat


class OfferStatus(StrEnum):
    SENT = "sent"
    VIEWED = "viewed"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    WITHDRAWN = "withdrawn"


OFFER_STATUS_LABELS = {
    OfferStatus.SENT: "Отправлено",
    OfferStatus.VIEWED: "Просмотрено",
    OfferStatus.ACCEPTED: "Принято",
    OfferStatus.DECLINED: "Отклонено",
    OfferStatus.WITHDRAWN: "Отозвано",
}

AWAITING_RESPONSE = frozenset({OfferStatus.SENT, OfferStatus.VIEWED})
# Statuses that block sending the same vacancy to the same candidate again.
ACTIVE_STATUSES = AWAITING_RESPONSE | {OfferStatus.ACCEPTED}


class VacancyNotFoundError(NotFoundError):
    code = "vacancy_not_found"


class VacancyClosedError(ConflictError):
    code = "vacancy_closed"


class InvalidSalaryRangeError(DomainValidationError):
    code = "invalid_salary_range"


class OfferNotFoundError(NotFoundError):
    code = "offer_not_found"


class OfferSalaryOutOfRangeError(DomainValidationError):
    code = "offer_salary_out_of_range"


class DuplicateOfferError(ConflictError):
    code = "duplicate_offer"


class CandidateNotAvailableError(NotFoundError):
    code = "candidate_not_available"


class OfferTransitionNotAllowedError(ConflictError):
    code = "offer_transition_not_allowed"


class DeclineReasonRequiredError(DomainValidationError):
    code = "decline_reason_required"


@dataclass(frozen=True)
class SalaryRange:
    """Monthly gross salary in roubles."""

    salary_from: int
    salary_to: int

    def __post_init__(self) -> None:
        if self.salary_from <= 0 or self.salary_to < self.salary_from:
            raise InvalidSalaryRangeError(
                "Зарплатная вилка должна быть положительной, «от» не больше «до»"
            )

    def contains(self, salary: int) -> bool:
        return self.salary_from <= salary <= self.salary_to


@dataclass
class Vacancy:
    id: UUID
    employer_id: UUID
    title: str
    salary: SalaryRange
    created_at: datetime
    discipline_code: str | None = None
    grade: Grade | None = None
    work_format: WorkFormat | None = None
    skills: list[str] = field(default_factory=list)
    description: str = ""
    is_open: bool = True

    @classmethod
    def publish(
        cls,
        *,
        employer_id: UUID,
        title: str,
        salary: SalaryRange,
        now: datetime,
        discipline_code: str | None = None,
        grade: Grade | None = None,
        work_format: WorkFormat | None = None,
        skills: Sequence[str] = (),
        description: str = "",
    ) -> "Vacancy":
        return cls(
            id=uuid4(),
            employer_id=employer_id,
            title=title.strip(),
            salary=salary,
            created_at=now,
            discipline_code=discipline_code,
            grade=grade,
            work_format=work_format,
            skills=[" ".join(skill.split()) for skill in skills if skill.strip()],
            description=description.strip(),
        )

    def close(self) -> None:
        self.is_open = False


@dataclass(frozen=True)
class CandidateSnapshot:
    """What hiring needs to know about a candidate from the talent context."""

    profile_id: UUID
    open_to_offers: bool


@dataclass
class Offer:
    """Aggregate root: a direct offer of a vacancy with a concrete salary."""

    id: UUID
    vacancy_id: UUID
    employer_id: UUID
    candidate_id: UUID
    salary: int
    message: str
    status: OfferStatus
    created_at: datetime
    viewed_at: datetime | None = None
    responded_at: datetime | None = None
    decline_reason: str | None = None

    @classmethod
    def send(
        cls,
        *,
        vacancy: Vacancy,
        candidate: CandidateSnapshot,
        salary: int,
        message: str,
        now: datetime,
    ) -> "Offer":
        if not vacancy.is_open:
            raise VacancyClosedError("Вакансия закрыта — предложение отправить нельзя")
        if not candidate.open_to_offers:
            raise CandidateNotAvailableError("Кандидат сейчас не принимает предложения")
        if not vacancy.salary.contains(salary):
            raise OfferSalaryOutOfRangeError(
                "Зарплата в предложении должна входить в вилку вакансии",
                details={
                    "salary_from": vacancy.salary.salary_from,
                    "salary_to": vacancy.salary.salary_to,
                },
            )
        return cls(
            id=uuid4(),
            vacancy_id=vacancy.id,
            employer_id=vacancy.employer_id,
            candidate_id=candidate.profile_id,
            salary=salary,
            message=message.strip(),
            status=OfferStatus.SENT,
            created_at=now,
        )

    @property
    def awaits_response(self) -> bool:
        return self.status in AWAITING_RESPONSE

    def mark_viewed(self, now: datetime) -> None:
        if self.status is OfferStatus.SENT:
            self.status = OfferStatus.VIEWED
            self.viewed_at = now

    def accept(self, now: datetime) -> None:
        self._respond(OfferStatus.ACCEPTED, now)

    def decline(self, reason: str, now: datetime) -> None:
        cleaned = reason.strip()
        if not cleaned:
            raise DeclineReasonRequiredError("Укажите причину отказа — это поможет работодателю")
        self._respond(OfferStatus.DECLINED, now)
        self.decline_reason = cleaned

    def withdraw(self, now: datetime) -> None:
        self._ensure_awaiting(OfferStatus.WITHDRAWN)
        self.status = OfferStatus.WITHDRAWN
        self.responded_at = now

    def _respond(self, status: OfferStatus, now: datetime) -> None:
        self._ensure_awaiting(status)
        if self.viewed_at is None:
            self.viewed_at = now
        self.status = status
        self.responded_at = now

    def _ensure_awaiting(self, target: OfferStatus) -> None:
        if not self.awaits_response:
            raise OfferTransitionNotAllowedError(
                f"Нельзя перевести предложение из статуса «{OFFER_STATUS_LABELS[self.status]}» "
                f"в «{OFFER_STATUS_LABELS[target]}»",
            )
