"""Analytics domain: hiring funnel and talent pool metrics for an employer (H5).

Pure functions over counts — no I/O — so every metric is unit-testable.
"""

from collections import Counter
from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from datetime import timedelta

from app.talent.domain import DisciplineScore, ScoringRules

RATE_PRECISION = 3
HOURS_PRECISION = 1


def rate(part: int, whole: int) -> float | None:
    """Share of `whole`; `None` when there is nothing to compare with yet."""
    return round(part / whole, RATE_PRECISION) if whole else None


def average_hours(durations: Iterable[timedelta]) -> float | None:
    items = list(durations)
    if not items:
        return None
    total = sum((item.total_seconds() for item in items), 0.0)
    return round(total / len(items) / 3600, HOURS_PRECISION)


@dataclass(frozen=True)
class FunnelCounts:
    candidates_viewed: int
    candidates_contacted: int
    offers_sent: int
    offers_opened: int
    offers_accepted: int
    offers_declined: int
    offers_withdrawn: int

    @property
    def offers_awaiting(self) -> int:
        return (
            self.offers_sent - self.offers_accepted - self.offers_declined - self.offers_withdrawn
        )


@dataclass(frozen=True)
class FunnelRates:
    view_to_offer: float | None
    offer_open: float | None
    acceptance: float | None

    @classmethod
    def from_counts(cls, counts: FunnelCounts) -> "FunnelRates":
        return cls(
            view_to_offer=rate(counts.candidates_contacted, counts.candidates_viewed),
            offer_open=rate(counts.offers_opened, counts.offers_sent),
            acceptance=rate(
                counts.offers_accepted, counts.offers_accepted + counts.offers_declined
            ),
        )


@dataclass(frozen=True)
class LevelBucket:
    discipline_code: str
    level_code: str
    candidates: int


def level_distribution(scores: Iterable[DisciplineScore], rules: ScoringRules) -> list[LevelBucket]:
    """How many candidates reach each verification level in each discipline."""
    counter: Counter[tuple[str, str]] = Counter(
        (score.discipline_code, rules.level_for(score.score).code) for score in scores
    )
    level_order = {level.code: index for index, level in enumerate(rules.levels)}
    return [
        LevelBucket(discipline, level, count)
        for (discipline, level), count in sorted(
            counter.items(), key=lambda item: (item[0][0], level_order[item[0][1]])
        )
    ]


@dataclass(frozen=True)
class TalentPool:
    candidates_open: int
    candidates_verified: int
    distribution: Sequence[LevelBucket]

    @property
    def verified_share(self) -> float | None:
        return rate(self.candidates_verified, self.candidates_open)


@dataclass(frozen=True)
class EmployerOverview:
    talent_pool: TalentPool
    funnel: FunnelCounts
    rates: FunnelRates
    average_response_hours: float | None
    open_vacancies: int
    recent_decline_reasons: Sequence[str]
