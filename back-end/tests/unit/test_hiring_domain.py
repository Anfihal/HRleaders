from datetime import timedelta
from uuid import uuid4

import pytest

from app.hiring.domain import (
    CandidateNotAvailableError,
    CandidateSnapshot,
    DeclineReasonRequiredError,
    InvalidSalaryRangeError,
    Offer,
    OfferSalaryOutOfRangeError,
    OfferStatus,
    OfferTransitionNotAllowedError,
    SalaryRange,
    Vacancy,
    VacancyClosedError,
)
from tests.conftest import NOW


def vacancy(**overrides: object) -> Vacancy:
    values: dict[str, object] = {
        "employer_id": uuid4(),
        "title": "  Backend-разработчик (Go)  ",
        "salary": SalaryRange(250_000, 350_000),
        "now": NOW,
        "skills": [" Go ", "", "Postgre  SQL"],
    }
    values.update(overrides)
    return Vacancy.publish(**values)  # type: ignore[arg-type]


def candidate(open_to_offers: bool = True) -> CandidateSnapshot:
    return CandidateSnapshot(profile_id=uuid4(), open_to_offers=open_to_offers)


def offer(salary: int = 300_000) -> Offer:
    return Offer.send(
        vacancy=vacancy(), candidate=candidate(), salary=salary, message=" Привет! ", now=NOW
    )


class TestSalaryRange:
    @pytest.mark.parametrize(("low", "high"), [(0, 100), (-1, 100), (200, 100)])
    def test_invalid_ranges(self, low: int, high: int) -> None:
        with pytest.raises(InvalidSalaryRangeError):
            SalaryRange(low, high)

    def test_contains_is_inclusive(self) -> None:
        salary = SalaryRange(100, 200)
        assert salary.contains(100)
        assert salary.contains(200)
        assert not salary.contains(201)


def test_vacancy_publish_normalizes_input() -> None:
    published = vacancy()
    assert published.title == "Backend-разработчик (Go)"
    assert published.skills == ["Go", "Postgre SQL"]
    assert published.is_open
    published.close()
    assert not published.is_open


class TestSendOffer:
    def test_new_offer_is_sent(self) -> None:
        sent = offer()
        assert sent.status is OfferStatus.SENT
        assert sent.message == "Привет!"
        assert sent.awaits_response

    def test_closed_vacancy_rejects_offers(self) -> None:
        closed = vacancy()
        closed.close()
        with pytest.raises(VacancyClosedError):
            Offer.send(vacancy=closed, candidate=candidate(), salary=300_000, message="x", now=NOW)

    def test_hidden_candidate_cannot_receive_offers(self) -> None:
        with pytest.raises(CandidateNotAvailableError):
            Offer.send(
                vacancy=vacancy(), candidate=candidate(False), salary=300_000, message="x", now=NOW
            )

    def test_salary_must_be_within_vacancy_range(self) -> None:
        with pytest.raises(OfferSalaryOutOfRangeError) as error:
            offer(salary=400_000)
        assert error.value.details == {"salary_from": 250_000, "salary_to": 350_000}


class TestOfferLifecycle:
    def test_view_then_accept(self) -> None:
        item = offer()
        item.mark_viewed(NOW + timedelta(hours=1))
        item.mark_viewed(NOW + timedelta(hours=2))  # idempotent: first view wins
        assert item.status is OfferStatus.VIEWED
        assert item.viewed_at == NOW + timedelta(hours=1)
        item.accept(NOW + timedelta(hours=3))
        assert item.status is OfferStatus.ACCEPTED  # type: ignore[comparison-overlap]
        assert item.responded_at == NOW + timedelta(hours=3)
        assert not item.awaits_response

    def test_responding_without_opening_marks_offer_viewed(self) -> None:
        item = offer()
        item.decline("Рассматриваю только удалённый формат", NOW)
        assert item.viewed_at == NOW
        assert item.decline_reason == "Рассматриваю только удалённый формат"

    @pytest.mark.parametrize("reason", ["", "   "])
    def test_decline_requires_reason(self, reason: str) -> None:
        item = offer()
        with pytest.raises(DeclineReasonRequiredError):
            item.decline(reason, NOW)
        assert item.status is OfferStatus.SENT

    def test_answered_offer_cannot_change(self) -> None:
        item = offer()
        item.accept(NOW)
        with pytest.raises(OfferTransitionNotAllowedError, match="Принято"):
            item.decline("Передумал", NOW)
        with pytest.raises(OfferTransitionNotAllowedError):
            item.withdraw(NOW)

    def test_employer_can_withdraw_pending_offer(self) -> None:
        item = offer()
        item.withdraw(NOW)
        assert item.status is OfferStatus.WITHDRAWN
        with pytest.raises(OfferTransitionNotAllowedError):
            item.accept(NOW)
        # Opening a withdrawn offer does not resurrect it.
        item.mark_viewed(NOW)
        assert item.status is OfferStatus.WITHDRAWN
