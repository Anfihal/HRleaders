from dataclasses import dataclass, field
from datetime import datetime
from uuid import UUID, uuid4

import pytest

from app.hiring.domain import (
    CandidateNotAvailableError,
    DuplicateOfferError,
    OfferNotFoundError,
    OfferStatus,
    VacancyNotFoundError,
)
from app.hiring.ports import OfferView
from app.hiring.use_cases import (
    CandidateOffers,
    CloseVacancy,
    ListEmployerOffers,
    PublishVacancy,
    SendOffer,
    VacancyDraft,
    WithdrawOffer,
)
from app.talent.domain import UnknownDisciplineError
from tests.conftest import NOW
from tests.unit.fakes import (
    InMemoryCandidates,
    InMemoryOffers,
    InMemoryVacancies,
    StaticDisciplines,
)


def clock() -> datetime:
    return NOW


@dataclass
class World:
    vacancies: InMemoryVacancies = field(default_factory=InMemoryVacancies)
    candidates: InMemoryCandidates = field(default_factory=InMemoryCandidates)
    employer_id: UUID = field(default_factory=uuid4)
    candidate_user_id: UUID = field(default_factory=uuid4)
    candidate_profile_id: UUID = field(default_factory=uuid4)

    def __post_init__(self) -> None:
        self.offers = InMemoryOffers(self.vacancies)
        self.candidates.add(self.candidate_user_id, self.candidate_profile_id)
        self.vacancy = PublishVacancy(self.vacancies, StaticDisciplines(), clock).execute(
            employer_id=self.employer_id,
            draft=VacancyDraft(title="Backend Go", salary_from=250_000, salary_to=350_000),
        )

    def send(self, employer_id: UUID | None = None, candidate_id: UUID | None = None) -> OfferView:
        return SendOffer(self.vacancies, self.offers, self.candidates, clock).execute(
            employer_id=employer_id or self.employer_id,
            vacancy_id=self.vacancy.id,
            candidate_id=candidate_id or self.candidate_profile_id,
            salary=300_000,
            message="Предлагаем роль в платёжном ядре",
        )

    @property
    def inbox(self) -> CandidateOffers:
        return CandidateOffers(self.offers, self.candidates, clock)


@pytest.fixture
def world() -> World:
    return World()


def test_send_offer_returns_enriched_view(world: World) -> None:
    view = world.send()
    assert view.offer.status is OfferStatus.SENT
    assert view.vacancy.id == world.vacancy.id
    assert view.company_name == "Радиус Софт"


def test_duplicate_active_offer_is_rejected(world: World) -> None:
    world.send()
    with pytest.raises(DuplicateOfferError):
        world.send()


def test_offer_can_be_resent_after_decline(world: World) -> None:
    first = world.send()
    world.inbox.decline(
        user_id=world.candidate_user_id, offer_id=first.offer.id, reason="Низкая зарплата"
    )
    assert world.send().offer.id != first.offer.id


def test_foreign_vacancy_looks_like_not_found(world: World) -> None:
    with pytest.raises(VacancyNotFoundError):
        world.send(employer_id=uuid4())
    with pytest.raises(VacancyNotFoundError):
        CloseVacancy(world.vacancies).execute(employer_id=uuid4(), vacancy_id=world.vacancy.id)


def test_vacancy_discipline_must_be_known(world: World) -> None:
    publish = PublishVacancy(world.vacancies, StaticDisciplines(), clock)
    draft = VacancyDraft(title="ML", salary_from=1, salary_to=2, discipline_code="ml")
    with pytest.raises(UnknownDisciplineError):
        publish.execute(employer_id=world.employer_id, draft=draft)


def test_unknown_candidate(world: World) -> None:
    with pytest.raises(CandidateNotAvailableError):
        world.send(candidate_id=uuid4())


def test_candidate_inbox_flow(world: World) -> None:
    sent = world.send()
    assert [v.offer.id for v in world.inbox.list(user_id=world.candidate_user_id)] == [
        sent.offer.id
    ]
    assert world.inbox.list(user_id=uuid4()) == []
    opened = world.inbox.open(user_id=world.candidate_user_id, offer_id=sent.offer.id)
    assert opened.offer.status is OfferStatus.VIEWED
    accepted = world.inbox.accept(user_id=world.candidate_user_id, offer_id=sent.offer.id)
    assert accepted.offer.status is OfferStatus.ACCEPTED
    listed = ListEmployerOffers(world.offers).execute(
        employer_id=world.employer_id, status=OfferStatus.ACCEPTED
    )
    assert len(listed) == 1


def test_other_candidate_cannot_touch_offer(world: World) -> None:
    sent = world.send()
    stranger = uuid4()
    world.candidates.add(stranger, uuid4())
    with pytest.raises(OfferNotFoundError):
        world.inbox.accept(user_id=stranger, offer_id=sent.offer.id)


def test_withdraw_is_limited_to_owner(world: World) -> None:
    sent = world.send()
    withdraw = WithdrawOffer(world.offers, clock)
    with pytest.raises(OfferNotFoundError):
        withdraw.execute(employer_id=uuid4(), offer_id=sent.offer.id)
    result = withdraw.execute(employer_id=world.employer_id, offer_id=sent.offer.id)
    assert result.offer.status is OfferStatus.WITHDRAWN
