"""SQLAlchemy adapters of the hiring ports."""

from typing import Any
from uuid import UUID

from sqlalchemy import Select, case, exists, func, select
from sqlalchemy.orm import Session

from app.hiring.domain import (
    ACTIVE_STATUSES,
    AWAITING_RESPONSE,
    CandidateSnapshot,
    Offer,
    OfferStatus,
    SalaryRange,
    Vacancy,
)
from app.hiring.orm import OfferRecord, VacancyRecord
from app.hiring.ports import OfferView, VacancyWithStats
from app.identity.orm import UserRecord
from app.talent.domain import Grade, WorkFormat
from app.talent.orm import CandidateProfileRecord

# offer, vacancy, company name, candidate name, candidate headline
_OfferRows = Select[OfferRecord, VacancyRecord, str | None, str, str]


class SqlAlchemyVacancyRepository:
    def __init__(self, session: Session) -> None:
        self._session = session

    def get(self, vacancy_id: UUID) -> Vacancy | None:
        record = self._session.get(VacancyRecord, vacancy_id)
        return vacancy_to_domain(record) if record else None

    def save(self, vacancy: Vacancy) -> None:
        record = self._session.get(VacancyRecord, vacancy.id)
        if record is None:
            record = VacancyRecord(id=vacancy.id, employer_id=vacancy.employer_id)
            self._session.add(record)
        record.title = vacancy.title
        record.discipline_code = vacancy.discipline_code
        record.grade = vacancy.grade.value if vacancy.grade else None
        record.work_format = vacancy.work_format.value if vacancy.work_format else None
        record.salary_from = vacancy.salary.salary_from
        record.salary_to = vacancy.salary.salary_to
        record.skills = list(vacancy.skills)
        record.description = vacancy.description
        record.is_open = vacancy.is_open
        record.created_at = vacancy.created_at
        self._session.flush()

    def list_for_employer(self, employer_id: UUID) -> list[VacancyWithStats]:
        def count_where(*statuses: OfferStatus) -> Any:
            return func.coalesce(
                func.sum(case((OfferRecord.status.in_([s.value for s in statuses]), 1), else_=0)),
                0,
            )

        rows = self._session.execute(
            select(
                VacancyRecord,
                func.count(OfferRecord.id),
                count_where(*AWAITING_RESPONSE),
                count_where(OfferStatus.ACCEPTED),
            )
            .outerjoin(OfferRecord, OfferRecord.vacancy_id == VacancyRecord.id)
            .where(VacancyRecord.employer_id == employer_id)
            .group_by(VacancyRecord.id)
            .order_by(VacancyRecord.is_open.desc(), VacancyRecord.created_at.desc())
        ).all()
        return [
            VacancyWithStats(vacancy_to_domain(row[0]), int(row[1]), int(row[2]), int(row[3]))
            for row in rows
        ]


class SqlAlchemyOfferRepository:
    def __init__(self, session: Session) -> None:
        self._session = session

    def get(self, offer_id: UUID) -> Offer | None:
        record = self._session.get(OfferRecord, offer_id)
        return offer_to_domain(record) if record else None

    def save(self, offer: Offer) -> None:
        record = self._session.get(OfferRecord, offer.id)
        if record is None:
            record = OfferRecord(
                id=offer.id,
                vacancy_id=offer.vacancy_id,
                employer_id=offer.employer_id,
                candidate_id=offer.candidate_id,
            )
            self._session.add(record)
        record.salary = offer.salary
        record.message = offer.message
        record.status = offer.status.value
        record.created_at = offer.created_at
        record.viewed_at = offer.viewed_at
        record.responded_at = offer.responded_at
        record.decline_reason = offer.decline_reason
        self._session.flush()

    def has_active(self, *, vacancy_id: UUID, candidate_id: UUID) -> bool:
        return bool(
            self._session.scalar(
                select(
                    exists().where(
                        OfferRecord.vacancy_id == vacancy_id,
                        OfferRecord.candidate_id == candidate_id,
                        OfferRecord.status.in_([s.value for s in ACTIVE_STATUSES]),
                    )
                )
            )
        )

    def view(self, offer_id: UUID) -> OfferView | None:
        views = self._views(self._view_query().where(OfferRecord.id == offer_id))
        return views[0] if views else None

    def list_for_employer(
        self, employer_id: UUID, status: OfferStatus | None = None
    ) -> list[OfferView]:
        query = self._view_query().where(OfferRecord.employer_id == employer_id)
        if status is not None:
            query = query.where(OfferRecord.status == status.value)
        return self._views(query)

    def list_for_candidate(self, candidate_id: UUID) -> list[OfferView]:
        return self._views(self._view_query().where(OfferRecord.candidate_id == candidate_id))

    @staticmethod
    def _view_query() -> _OfferRows:
        return (
            select(
                OfferRecord,
                VacancyRecord,
                UserRecord.company_name,
                CandidateProfileRecord.full_name,
                CandidateProfileRecord.headline,
            )
            .join(VacancyRecord, VacancyRecord.id == OfferRecord.vacancy_id)
            .join(UserRecord, UserRecord.id == OfferRecord.employer_id)
            .join(CandidateProfileRecord, CandidateProfileRecord.id == OfferRecord.candidate_id)
            .order_by(OfferRecord.created_at.desc(), OfferRecord.id)
        )

    def _views(self, query: _OfferRows) -> list[OfferView]:
        return [
            OfferView(
                offer=offer_to_domain(offer),
                vacancy=vacancy_to_domain(vacancy),
                company_name=company or "",
                candidate_name=name,
                candidate_headline=headline,
            )
            for offer, vacancy, company, name, headline in self._session.execute(query)
        ]


class SqlAlchemyCandidateDirectory:
    """Anti-corruption read of the talent tables for hiring decisions."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def snapshot(self, profile_id: UUID) -> CandidateSnapshot | None:
        open_to_offers = self._session.scalar(
            select(CandidateProfileRecord.open_to_offers).where(
                CandidateProfileRecord.id == profile_id
            )
        )
        return None if open_to_offers is None else CandidateSnapshot(profile_id, open_to_offers)

    def profile_id_for_user(self, user_id: UUID) -> UUID | None:
        return self._session.scalar(
            select(CandidateProfileRecord.id).where(CandidateProfileRecord.user_id == user_id)
        )


def vacancy_to_domain(record: VacancyRecord) -> Vacancy:
    return Vacancy(
        id=record.id,
        employer_id=record.employer_id,
        title=record.title,
        salary=SalaryRange(record.salary_from, record.salary_to),
        created_at=record.created_at,
        discipline_code=record.discipline_code,
        grade=Grade(record.grade) if record.grade else None,
        work_format=WorkFormat(record.work_format) if record.work_format else None,
        skills=list(record.skills),
        description=record.description,
        is_open=record.is_open,
    )


def offer_to_domain(record: OfferRecord) -> Offer:
    return Offer(
        id=record.id,
        vacancy_id=record.vacancy_id,
        employer_id=record.employer_id,
        candidate_id=record.candidate_id,
        salary=record.salary,
        message=record.message,
        status=OfferStatus(record.status),
        created_at=record.created_at,
        viewed_at=record.viewed_at,
        responded_at=record.responded_at,
        decline_reason=record.decline_reason,
    )
