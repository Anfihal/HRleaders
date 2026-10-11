from datetime import date

from app.fsp.gateway import FspCompetitionRecord, FspParticipant, parse_participant
from app.fsp.translator import FspVocabulary, translate_participant

VOCABULARY = FspVocabulary.build(
    disciplines={"Программирование алгоритмическое": "algorithmic"},
    competition_levels={"Всероссийский": "national", "Региональный": "regional"},
    results={"Победитель": "winner", "Призёр": "prize_winner"},
    sport_ranks={"Кандидат в мастера спорта": "kms"},
)


def record(**overrides: object) -> FspCompetitionRecord:
    values: dict[str, object] = {
        "name": "Кубок России по спортивному программированию",
        "date": date(2025, 10, 5),
        "discipline": "Программирование алгоритмическое",
        "level": "Всероссийский",
        "result": "Победитель",
        "role": "Капитан команды",
        "rank": None,
    }
    values.update(overrides)
    return FspCompetitionRecord(**values)  # type: ignore[arg-type]


def participant(*records: FspCompetitionRecord) -> FspParticipant:
    return FspParticipant("FSP-1", "Иванов Артём Сергеевич", tuple(records))


def test_translates_labels_to_codes() -> None:
    result = translate_participant(
        participant(record(rank="Кандидат в мастера спорта")), VOCABULARY
    )
    assert result.skipped == ()
    (item,) = result.achievements
    assert (item.discipline_code, item.competition_level_code, item.result_code) == (
        "algorithmic",
        "national",
        "winner",
    )
    assert item.sport_rank_code == "kms"
    assert item.team_role == "Капитан команды"


def test_labels_match_ignoring_case_spaces_and_yo() -> None:
    result = translate_participant(
        participant(record(result="ПРИЗЕР", discipline="программирование   алгоритмическое")),
        VOCABULARY,
    )
    assert result.achievements[0].result_code == "prize_winner"


def test_unknown_records_are_skipped_not_guessed() -> None:
    unknown = record(name="Лига ИИ-агентов", discipline="Программирование ИИ-агентов")
    result = translate_participant(participant(record(), unknown), VOCABULARY)
    assert len(result.achievements) == 1
    assert result.skipped == ("Лига ИИ-агентов",)


def test_unknown_rank_is_dropped_but_record_kept() -> None:
    result = translate_participant(participant(record(rank="Гроссмейстер")), VOCABULARY)
    assert result.achievements[0].sport_rank_code is None


def test_parse_participant_payload() -> None:
    parsed = parse_participant(
        {
            "participant_id": 42,
            "full_name": "Иванов",
            "competitions": [
                {
                    "name": "Кубок",
                    "date": "2025-10-05",
                    "discipline": "Программирование алгоритмическое",
                    "level": "Всероссийский",
                    "result": "Победитель",
                }
            ],
        }
    )
    assert parsed.participant_id == "42"
    assert parsed.competitions[0].date == date(2025, 10, 5)
    assert parsed.competitions[0].rank is None
