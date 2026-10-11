"""Anti-corruption layer for the FSP (Федерация спортивного программирования) API.

The rest of the platform never sees raw FSP payloads: it works with the typed
`FspParticipant` DTO returned by an `FspGateway` implementation.
"""

import logging
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import date
from typing import Any, Protocol
from urllib.parse import quote

import httpx

from app.shared.errors import ExternalServiceError, NotFoundError

logger = logging.getLogger(__name__)


class FspParticipantNotFoundError(NotFoundError):
    code = "fsp_participant_not_found"


class FspUnavailableError(ExternalServiceError):
    code = "fsp_unavailable"


@dataclass(frozen=True)
class FspCompetitionRecord:
    name: str
    date: date
    discipline: str
    level: str
    result: str
    role: str | None
    rank: str | None


@dataclass(frozen=True)
class FspParticipant:
    participant_id: str
    full_name: str
    competitions: tuple[FspCompetitionRecord, ...]


class FspGateway(Protocol):
    def fetch_participant(self, participant_id: str) -> FspParticipant: ...


def parse_participant(payload: Mapping[str, Any]) -> FspParticipant:
    return FspParticipant(
        participant_id=str(payload["participant_id"]),
        full_name=str(payload["full_name"]),
        competitions=tuple(
            FspCompetitionRecord(
                name=str(item["name"]),
                date=date.fromisoformat(str(item["date"])),
                discipline=str(item["discipline"]),
                level=str(item["level"]),
                result=str(item["result"]),
                role=item.get("role"),
                rank=item.get("rank"),
            )
            for item in payload.get("competitions", [])
        ),
    )


class HttpFspGateway:
    """Calls `GET {base_url}/participants/{id}` of the FSP API (or the mock service)."""

    def __init__(self, base_url: str, token: str, timeout_seconds: float) -> None:
        self._base_url = base_url.rstrip("/")
        self._token = token
        self._timeout = timeout_seconds

    def fetch_participant(self, participant_id: str) -> FspParticipant:
        url = f"{self._base_url}/participants/{quote(participant_id, safe='')}"
        try:
            response = httpx.get(
                url,
                headers={"Authorization": f"Bearer {self._token}"},
                timeout=self._timeout,
            )
        except httpx.HTTPError as error:
            logger.warning("FSP API request failed: %s", error)
            raise FspUnavailableError("Сервис ФСП временно недоступен") from error
        if response.status_code == httpx.codes.NOT_FOUND:
            raise FspParticipantNotFoundError(f"Участник ФСП {participant_id} не найден")
        if response.is_error:
            logger.warning("FSP API responded with %s: %s", response.status_code, response.text)
            raise FspUnavailableError("Сервис ФСП временно недоступен")
        try:
            return parse_participant(response.json())
        except (KeyError, TypeError, ValueError) as error:
            logger.error("FSP API returned an unexpected payload: %s", error)
            raise FspUnavailableError("Сервис ФСП вернул некорректные данные") from error


class InMemoryFspGateway:
    """Fixture-backed gateway for seeding demo data and tests."""

    def __init__(self, participants: Mapping[str, FspParticipant]) -> None:
        self._participants = dict(participants)

    @classmethod
    def from_payloads(cls, payloads: Sequence[Mapping[str, Any]]) -> "InMemoryFspGateway":
        parsed = [parse_participant(item) for item in payloads]
        return cls({item.participant_id: item for item in parsed})

    def fetch_participant(self, participant_id: str) -> FspParticipant:
        try:
            return self._participants[participant_id]
        except KeyError:
            raise FspParticipantNotFoundError(f"Участник ФСП {participant_id} не найден") from None
