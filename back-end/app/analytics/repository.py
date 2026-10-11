"""SQL read model for analytics: aggregates over talent and hiring tables."""

from datetime import timedelta
from uuid import UUID

from sqlalchemy import distinct, func, select
from sqlalchemy.orm import Session

from app.analytics.domain import FunnelCounts
from app.hiring.domain import OfferStatus
from app.hiring.orm import OfferRecord, VacancyRecord
from app.talent.domain import DisciplineScore
from app.talent.orm import CandidateDisciplineScoreRecord, CandidateProfileRecord, ProfileViewRecord


class SqlAlchemyAnalyticsReadModel:
    def __init__(self, session: Session) -> None:
        self._session = session

    def open_candidates(self) -> tuple[int, int]:
        profile = CandidateProfileRecord
        total = self._session.scalar(
            select(func.count()).select_from(profile).where(profile.open_to_offers.is_(True))
        )
        verified = self._session.scalar(
            select(func.count(distinct(profile.id)))
            .join(CandidateDisciplineScoreRecord)
            .where(profile.open_to_offers.is_(True), profile.fsp_synced_at.is_not(None))
        )
        return int(total or 0), int(verified or 0)

    def open_candidate_scores(self) -> list[DisciplineScore]:
        rows = self._session.execute(
            select(
                CandidateDisciplineScoreRecord.discipline_code, CandidateDisciplineScoreRecord.score
            )
            .join(CandidateProfileRecord)
            .where(CandidateProfileRecord.open_to_offers.is_(True))
        )
        return [DisciplineScore(code, score) for code, score in rows]

    def funnel(self, employer_id: UUID) -> FunnelCounts:
        viewed = self._session.scalar(
            select(func.count(distinct(ProfileViewRecord.candidate_id))).where(
                ProfileViewRecord.employer_id == employer_id
            )
        )
        offers = OfferRecord
        contacted = self._session.scalar(
            select(func.count(distinct(offers.candidate_id))).where(
                offers.employer_id == employer_id
            )
        )
        # Result exposes .keys(), so dict(result) would treat it as a mapping.
        by_status = {
            status: int(count)
            for status, count in self._session.execute(
                select(offers.status, func.count())
                .where(offers.employer_id == employer_id)
                .group_by(offers.status)
            )
        }
        opened = self._session.scalar(
            select(func.count())
            .select_from(offers)
            .where(offers.employer_id == employer_id, offers.viewed_at.is_not(None))
        )
        return FunnelCounts(
            candidates_viewed=int(viewed or 0),
            candidates_contacted=int(contacted or 0),
            offers_sent=sum(by_status.values()),
            offers_opened=int(opened or 0),
            offers_accepted=by_status.get(OfferStatus.ACCEPTED.value, 0),
            offers_declined=by_status.get(OfferStatus.DECLINED.value, 0),
            offers_withdrawn=by_status.get(OfferStatus.WITHDRAWN.value, 0),
        )

    def response_durations(self, employer_id: UUID) -> list[timedelta]:
        rows = self._session.execute(
            select(OfferRecord.created_at, OfferRecord.responded_at).where(
                OfferRecord.employer_id == employer_id,
                OfferRecord.status.in_([OfferStatus.ACCEPTED.value, OfferStatus.DECLINED.value]),
            )
        )
        return [responded - created for created, responded in rows if responded is not None]

    def open_vacancies(self, employer_id: UUID) -> int:
        count = self._session.scalar(
            select(func.count())
            .select_from(VacancyRecord)
            .where(VacancyRecord.employer_id == employer_id, VacancyRecord.is_open.is_(True))
        )
        return int(count or 0)

    def recent_decline_reasons(self, employer_id: UUID, limit: int) -> list[str]:
        reasons = self._session.scalars(
            select(OfferRecord.decline_reason)
            .where(
                OfferRecord.employer_id == employer_id,
                OfferRecord.status == OfferStatus.DECLINED.value,
            )
            .order_by(OfferRecord.responded_at.desc())
            .limit(limit)
        )
        return [reason for reason in reasons if reason]
