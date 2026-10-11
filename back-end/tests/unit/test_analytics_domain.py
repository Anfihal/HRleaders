from datetime import timedelta

from app.analytics.domain import (
    FunnelCounts,
    FunnelRates,
    TalentPool,
    average_hours,
    level_distribution,
    rate,
)
from app.talent.domain import DisciplineScore, ScoringRules


def test_rate_handles_empty_denominator() -> None:
    assert rate(0, 0) is None
    assert rate(1, 3) == 0.333


def test_average_hours() -> None:
    assert average_hours([]) is None
    assert average_hours([timedelta(hours=2), timedelta(hours=3)]) == 2.5


def test_funnel_rates_and_awaiting() -> None:
    counts = FunnelCounts(
        candidates_viewed=8,
        candidates_contacted=5,
        offers_sent=6,
        offers_opened=4,
        offers_accepted=1,
        offers_declined=2,
        offers_withdrawn=1,
    )
    assert counts.offers_awaiting == 2
    assert FunnelRates.from_counts(counts) == FunnelRates(
        view_to_offer=0.625, offer_open=0.667, acceptance=0.333
    )


def test_level_distribution_is_ordered_by_discipline_then_level(rules: ScoringRules) -> None:
    scores = [
        DisciplineScore("uav", 95),
        DisciplineScore("algorithmic", 45),
        DisciplineScore("algorithmic", 5),
        DisciplineScore("algorithmic", 50),
    ]
    buckets = [
        (b.discipline_code, b.level_code, b.candidates) for b in level_distribution(scores, rules)
    ]
    assert buckets == [
        ("algorithmic", "none", 1),
        ("algorithmic", "advanced", 2),
        ("uav", "expert", 1),
    ]


def test_verified_share() -> None:
    assert TalentPool(0, 0, []).verified_share is None
    assert TalentPool(4, 3, []).verified_share == 0.75
