"""Translate FSP vocabulary (free-form Russian labels) into platform codes."""

import logging
from collections.abc import Mapping
from dataclasses import dataclass

from app.fsp.gateway import FspParticipant
from app.talent.domain import FspAchievement

logger = logging.getLogger(__name__)


def _key(label: str) -> str:
    return " ".join(label.replace("ё", "е").split()).casefold()


@dataclass(frozen=True)
class FspVocabulary:
    """FSP label → platform code, per dictionary. Loaded from reference tables."""

    disciplines: Mapping[str, str]
    competition_levels: Mapping[str, str]
    results: Mapping[str, str]
    sport_ranks: Mapping[str, str]

    @classmethod
    def build(
        cls,
        *,
        disciplines: Mapping[str, str],
        competition_levels: Mapping[str, str],
        results: Mapping[str, str],
        sport_ranks: Mapping[str, str],
    ) -> "FspVocabulary":
        def normalized(mapping: Mapping[str, str]) -> dict[str, str]:
            return {_key(label): code for label, code in mapping.items()}

        return cls(
            normalized(disciplines),
            normalized(competition_levels),
            normalized(results),
            normalized(sport_ranks),
        )


@dataclass(frozen=True)
class TranslationResult:
    achievements: tuple[FspAchievement, ...]
    skipped: tuple[str, ...]


def translate_participant(
    participant: FspParticipant, vocabulary: FspVocabulary
) -> TranslationResult:
    """Records with an unknown discipline/level/result are skipped and reported, not guessed."""
    achievements: list[FspAchievement] = []
    skipped: list[str] = []
    for record in participant.competitions:
        discipline = vocabulary.disciplines.get(_key(record.discipline))
        level = vocabulary.competition_levels.get(_key(record.level))
        result = vocabulary.results.get(_key(record.result))
        if discipline is None or level is None or result is None:
            logger.info("Skipping unrecognized FSP record %r", record)
            skipped.append(record.name)
            continue
        achievements.append(
            FspAchievement(
                competition_name=record.name,
                held_on=record.date,
                discipline_code=discipline,
                competition_level_code=level,
                result_code=result,
                team_role=record.role,
                sport_rank_code=vocabulary.sport_ranks.get(_key(record.rank))
                if record.rank
                else None,
            )
        )
    return TranslationResult(tuple(achievements), tuple(skipped))
