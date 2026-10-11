"""Composition of hiring adapters for the HTTP layer."""

from app.hiring.repository import (
    SqlAlchemyCandidateDirectory,
    SqlAlchemyOfferRepository,
    SqlAlchemyVacancyRepository,
)
from app.shared.database import DatabaseSession


def get_vacancy_repository(session: DatabaseSession) -> SqlAlchemyVacancyRepository:
    return SqlAlchemyVacancyRepository(session)


def get_offer_repository(session: DatabaseSession) -> SqlAlchemyOfferRepository:
    return SqlAlchemyOfferRepository(session)


def get_candidate_directory(
    session: DatabaseSession,
) -> SqlAlchemyCandidateDirectory:
    return SqlAlchemyCandidateDirectory(session)
