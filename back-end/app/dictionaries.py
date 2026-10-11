"""Reference dictionaries for the UI: codes with human labels, served from one place.

The front-end never hardcodes labels or business vocabularies — it reads them here.
"""

from collections.abc import Iterable

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.hiring.domain import OFFER_STATUS_LABELS
from app.identity.domain import ROLE_LABELS
from app.shared.http import ERROR_RESPONSES
from app.talent.dependencies import get_reference_data
from app.talent.domain import GRADE_LABELS, TEAM_ROLE_LABELS, WORK_FORMAT_LABELS
from app.talent.repository import ScoringRuleType, SqlAlchemyTalentReferenceData

router = APIRouter(prefix="/dictionaries", tags=["dictionaries"], responses=ERROR_RESPONSES)


class Option(BaseModel):
    code: str
    label: str


class LevelOption(Option):
    min_score: float


class DictionariesResponse(BaseModel):
    roles: list[Option]
    disciplines: list[Option]
    verification_levels: list[LevelOption]
    competition_results: list[Option]
    competition_levels: list[Option]
    sport_ranks: list[Option]
    grades: list[Option]
    team_roles: list[Option]
    work_formats: list[Option]
    offer_statuses: list[Option]


def _options(pairs: Iterable[tuple[str, str]]) -> list[Option]:
    return [Option(code=code, label=label) for code, label in pairs]


@router.get("")
def get_dictionaries(
    reference: SqlAlchemyTalentReferenceData = Depends(get_reference_data),
) -> DictionariesResponse:
    rules = reference.labelled_rules()
    return DictionariesResponse(
        roles=_options(ROLE_LABELS.items()),
        disciplines=[Option(code=d.code, label=d.label) for d in reference.disciplines()],
        verification_levels=[
            LevelOption(code=level.code, label=level.label, min_score=level.min_score)
            for level in reference.scoring_rules().levels
        ],
        competition_results=_options(rules[ScoringRuleType.RESULT]),
        competition_levels=_options(rules[ScoringRuleType.COMPETITION_LEVEL]),
        sport_ranks=_options(rules[ScoringRuleType.SPORT_RANK]),
        grades=_options(GRADE_LABELS.items()),
        team_roles=_options(TEAM_ROLE_LABELS.items()),
        work_formats=_options(WORK_FORMAT_LABELS.items()),
        offer_statuses=_options(OFFER_STATUS_LABELS.items()),
    )
