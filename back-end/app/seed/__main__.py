"""Load realistic demo data through the real use cases: `python -m app.seed`.

Requires `SEED_DEMO_PASSWORD` (the password of every demo account) — it is never stored in code.
Idempotent: does nothing if the demo employers already exist.
"""

import json
import logging
import os
import sys
from collections.abc import Mapping
from contextlib import contextmanager
from datetime import datetime, timedelta
from importlib import resources
from typing import Any
from uuid import UUID

from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.fsp.gateway import InMemoryFspGateway
from app.hiring.domain import OfferStatus
from app.hiring.repository import (
    SqlAlchemyCandidateDirectory,
    SqlAlchemyOfferRepository,
    SqlAlchemyVacancyRepository,
)
from app.hiring.use_cases import CandidateOffers, PublishVacancy, SendOffer, VacancyDraft
from app.identity.domain import PasswordPolicy, Role, User
from app.identity.repository import SqlAlchemyUserRepository
from app.identity.use_cases import RegisterUser, RegistrationRequest
from app.shared.database import Database, utc_now
from app.shared.security import JwtTokenService, Pbkdf2PasswordHasher
from app.talent.domain import Grade, ProfileDetails, TeamRole, WorkFormat
from app.talent.repository import (
    SqlAlchemyCandidateProfileRepository,
    SqlAlchemyProfileViewLog,
    SqlAlchemyTalentReferenceData,
)
from app.talent.use_cases import (
    EnsureCandidateProfile,
    SyncFspAchievements,
    UpdateCandidateProfile,
    ViewCandidateProfile,
)
from mock_fsp.fixtures import load_participants

logger = logging.getLogger("app.seed")

PASSWORD_ENV = "SEED_DEMO_PASSWORD"
DEMO_FILE = "demo.json"
# Demo accounts are registered "a month ago" so the analytics timeline looks lived-in.
REGISTERED_DAYS_AGO = 30


class SeedClock:
    """Movable clock: the seed replays a realistic timeline through the use cases."""

    def __init__(self, now: datetime) -> None:
        self.now = now

    def __call__(self) -> datetime:
        return self.now


def load_demo() -> dict[str, Any]:
    data: dict[str, Any] = json.loads(
        resources.files("app.seed").joinpath(DEMO_FILE).read_text("utf-8")
    )
    return data


def seed(
    session: Session,
    settings: Settings,
    *,
    password: str,
    demo: Mapping[str, Any],
    now: datetime,
) -> bool:
    users = SqlAlchemyUserRepository(session)
    if users.get_by_email(demo["employers"][0]["email"]) is not None:
        logger.info("Demo data is already loaded — skipping")
        return False

    clock = SeedClock(now - timedelta(days=REGISTERED_DAYS_AGO))
    register = RegisterUser(
        users,
        Pbkdf2PasswordHasher(settings.password_hash_iterations),
        JwtTokenService(
            settings.jwt_secret.get_secret_value(),
            settings.jwt_algorithm,
            timedelta(minutes=settings.access_token_ttl_minutes),
        ),
        PasswordPolicy(settings.password_min_length),
        clock,
    )
    accounts: dict[str, User] = {}
    for employer in demo["employers"]:
        accounts[employer["email"]] = register.execute(
            RegistrationRequest(
                email=employer["email"],
                password=password,
                full_name=employer["full_name"],
                role=Role.EMPLOYER,
                company_name=employer["company_name"],
            )
        ).user

    profiles = SqlAlchemyCandidateProfileRepository(session)
    reference = SqlAlchemyTalentReferenceData(session)
    update_profile = UpdateCandidateProfile(
        profiles, EnsureCandidateProfile(profiles, clock), settings.candidate_skills_max, clock
    )
    sync = SyncFspAchievements(
        profiles, InMemoryFspGateway.from_payloads(load_participants()), reference, clock
    )
    profile_ids: dict[str, UUID] = {}
    for candidate in demo["candidates"]:
        user = register.execute(
            RegistrationRequest(
                email=candidate["email"],
                password=password,
                full_name=candidate["full_name"],
                role=Role.CANDIDATE,
            )
        ).user
        accounts[candidate["email"]] = user
        profile = update_profile.execute(
            user_id=user.id,
            full_name=user.full_name,
            details=ProfileDetails(
                full_name=candidate["full_name"],
                headline=candidate["headline"],
                city=candidate["city"],
                grade=Grade(candidate["grade"]),
                team_role=TeamRole(candidate["team_role"]),
                work_format=WorkFormat(candidate["work_format"]),
                salary_expectation=candidate["salary_expectation"],
                skills=candidate["skills"],
                about=candidate["about"],
                open_to_offers=candidate["open_to_offers"],
                fsp_participant_id=candidate["fsp_participant_id"],
            ),
        )
        if profile.fsp_participant_id:
            sync.execute(user_id=user.id)
        profile_ids[candidate["email"]] = profile.id

    vacancies = SqlAlchemyVacancyRepository(session)
    vacancy_ids: dict[str, UUID] = {}
    for vacancy in demo["vacancies"]:
        published = PublishVacancy(vacancies, reference, clock).execute(
            employer_id=accounts[vacancy["employer"]].id,
            draft=VacancyDraft(
                title=vacancy["title"],
                salary_from=vacancy["salary_from"],
                salary_to=vacancy["salary_to"],
                discipline_code=vacancy["discipline_code"],
                grade=Grade(vacancy["grade"]),
                work_format=WorkFormat(vacancy["work_format"]),
                skills=vacancy["skills"],
                description=vacancy["description"],
            ),
        )
        vacancy_ids[vacancy["key"]] = published.id

    views = ViewCandidateProfile(profiles, SqlAlchemyProfileViewLog(session), clock)
    offers = SqlAlchemyOfferRepository(session)
    directory = SqlAlchemyCandidateDirectory(session)
    inbox = CandidateOffers(offers, directory, clock)
    vacancy_owner = {item["key"]: item["employer"] for item in demo["vacancies"]}
    for item in demo["offers"]:
        employer = accounts[vacancy_owner[item["vacancy"]]]
        candidate_user = accounts[item["candidate"]]
        sent_at = now - timedelta(days=item["sent_days_ago"])
        clock.now = sent_at - timedelta(hours=1)
        views.execute(employer_id=employer.id, profile_id=profile_ids[item["candidate"]])
        clock.now = sent_at
        offer = (
            SendOffer(vacancies, offers, directory, clock)
            .execute(
                employer_id=employer.id,
                vacancy_id=vacancy_ids[item["vacancy"]],
                candidate_id=profile_ids[item["candidate"]],
                salary=item["salary"],
                message=item["message"],
            )
            .offer
        )
        status = OfferStatus(item["status"])
        if status is OfferStatus.VIEWED:
            clock.now = sent_at + timedelta(hours=item["view_after_hours"])
            inbox.open(user_id=candidate_user.id, offer_id=offer.id)
        elif status in (OfferStatus.ACCEPTED, OfferStatus.DECLINED):
            clock.now = sent_at + timedelta(hours=item["respond_after_hours"])
            if status is OfferStatus.ACCEPTED:
                inbox.accept(user_id=candidate_user.id, offer_id=offer.id)
            else:
                inbox.decline(
                    user_id=candidate_user.id, offer_id=offer.id, reason=item["decline_reason"]
                )

    for employer_email, candidate_emails in demo["extra_profile_views"].items():
        for days_ago, candidate_email in enumerate(candidate_emails, start=1):
            clock.now = now - timedelta(days=days_ago)
            views.execute(
                employer_id=accounts[employer_email].id, profile_id=profile_ids[candidate_email]
            )
    return True


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")
    password = os.environ.get(PASSWORD_ENV)
    if not password:
        logger.error("Set %s to the password for demo accounts", PASSWORD_ENV)
        return 1
    settings = get_settings()
    database = Database(settings.database_url)
    with contextmanager(database.session_scope)() as session:
        created = seed(session, settings, password=password, demo=load_demo(), now=utc_now())
    if created:
        logger.info("Demo data loaded")
    return 0


if __name__ == "__main__":
    sys.exit(main())
