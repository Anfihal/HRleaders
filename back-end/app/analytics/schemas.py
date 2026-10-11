"""HTTP contracts of the analytics context."""

from pydantic import BaseModel

from app.analytics.domain import EmployerOverview


class LevelBucketResponse(BaseModel):
    discipline_code: str
    level_code: str
    candidates: int


class TalentPoolResponse(BaseModel):
    candidates_open: int
    candidates_verified: int
    verified_share: float | None
    distribution: list[LevelBucketResponse]


class FunnelResponse(BaseModel):
    candidates_viewed: int
    candidates_contacted: int
    offers_sent: int
    offers_opened: int
    offers_accepted: int
    offers_declined: int
    offers_withdrawn: int
    offers_awaiting: int


class RatesResponse(BaseModel):
    view_to_offer: float | None
    offer_open: float | None
    acceptance: float | None


class EmployerOverviewResponse(BaseModel):
    talent_pool: TalentPoolResponse
    funnel: FunnelResponse
    rates: RatesResponse
    average_response_hours: float | None
    open_vacancies: int
    recent_decline_reasons: list[str]

    @classmethod
    def from_domain(cls, overview: EmployerOverview) -> "EmployerOverviewResponse":
        pool, funnel, rates = overview.talent_pool, overview.funnel, overview.rates
        return cls(
            talent_pool=TalentPoolResponse(
                candidates_open=pool.candidates_open,
                candidates_verified=pool.candidates_verified,
                verified_share=pool.verified_share,
                distribution=[
                    LevelBucketResponse(
                        discipline_code=bucket.discipline_code,
                        level_code=bucket.level_code,
                        candidates=bucket.candidates,
                    )
                    for bucket in pool.distribution
                ],
            ),
            funnel=FunnelResponse(
                candidates_viewed=funnel.candidates_viewed,
                candidates_contacted=funnel.candidates_contacted,
                offers_sent=funnel.offers_sent,
                offers_opened=funnel.offers_opened,
                offers_accepted=funnel.offers_accepted,
                offers_declined=funnel.offers_declined,
                offers_withdrawn=funnel.offers_withdrawn,
                offers_awaiting=funnel.offers_awaiting,
            ),
            rates=RatesResponse(
                view_to_offer=rates.view_to_offer,
                offer_open=rates.offer_open,
                acceptance=rates.acceptance,
            ),
            average_response_hours=overview.average_response_hours,
            open_vacancies=overview.open_vacancies,
            recent_decline_reasons=list(overview.recent_decline_reasons),
        )
