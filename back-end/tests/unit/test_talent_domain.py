from datetime import date, timedelta
from uuid import uuid4

import pytest

from app.talent.domain import (
    CandidateProfile,
    DisciplineScore,
    FspAchievement,
    FspIdentityMismatchError,
    FspParticipantNotLinkedError,
    InvalidSalaryError,
    ProfileDetails,
    ScoringRules,
    TooManySkillsError,
    UnknownVerificationLevelError,
    clean_skills,
)
from tests.conftest import NOW


def achievement(
    discipline: str = "algorithmic",
    level: str = "national",
    result: str = "winner",
    rank: str | None = None,
    held_on: date = date(2025, 5, 1),
) -> FspAchievement:
    return FspAchievement(
        competition_name="Чемпионат России по спортивному программированию",
        held_on=held_on,
        discipline_code=discipline,
        competition_level_code=level,
        result_code=result,
        sport_rank_code=rank,
    )


class TestScoring:
    def test_points_are_result_times_level_plus_best_rank(self, rules: ScoringRules) -> None:
        scores = rules.score_by_discipline(
            [
                achievement(result="winner", level="national", rank="third"),  # 45 + rank 3
                achievement(result="finalist", level="regional", rank="kms"),  # 10 + rank 20
            ]
        )
        # Rank points are not summed: only the best rank counts once per discipline.
        assert scores == [DisciplineScore("algorithmic", 75.0)]

    def test_scores_are_per_discipline_and_sorted_desc(self, rules: ScoringRules) -> None:
        scores = rules.score_by_discipline(
            [
                achievement("product", "regional", "participant"),
                achievement("security", "international", "winner"),
            ]
        )
        assert [s.discipline_code for s in scores] == ["security", "product"]
        assert scores[0].score == 60.0

    def test_levels_are_sorted_and_assigned_by_threshold(self, rules: ScoringRules) -> None:
        assert [level.code for level in rules.levels] == ["none", "basic", "advanced", "expert"]
        assert rules.level_for(0).code == "none"
        assert rules.level_for(9.9).code == "none"
        assert rules.level_for(10).code == "basic"
        assert rules.level_for(89).code == "advanced"
        assert rules.level_for(500).code == "expert"

    def test_categorize_reports_gap_to_next_level(self, rules: ScoringRules) -> None:
        category = rules.categorize(DisciplineScore("uav", 33.5))
        assert category.level.code == "basic"
        assert category.next_level is not None
        assert category.next_level.code == "advanced"
        assert category.points_to_next_level == 6.5

    def test_top_level_has_no_next_level(self, rules: ScoringRules) -> None:
        category = rules.categorize(DisciplineScore("uav", 120))
        assert category.next_level is None
        assert category.points_to_next_level is None

    def test_unknown_level_code_is_a_typed_error(self, rules: ScoringRules) -> None:
        with pytest.raises(UnknownVerificationLevelError):
            rules.level_by_code("guru")

    def test_rules_require_levels(self) -> None:
        with pytest.raises(ValueError, match="verification level"):
            ScoringRules({}, {}, {}, [])


class TestSkills:
    def test_trims_and_deduplicates_case_insensitively(self) -> None:
        assert clean_skills(["  Go ", "go", "Vue  3", "", "PostgreSQL"], 10) == [
            "Go",
            "Vue 3",
            "PostgreSQL",
        ]

    def test_limit_is_enforced(self) -> None:
        with pytest.raises(TooManySkillsError):
            clean_skills(["a", "b", "c"], 2)


def details(**overrides: object) -> ProfileDetails:
    values: dict[str, object] = {
        "full_name": "Иванов Артём Сергеевич",
        "headline": "Backend-разработчик Go",
        "fsp_participant_id": "FSP-1001",
    }
    values.update(overrides)
    return ProfileDetails(**values)  # type: ignore[arg-type]


class TestCandidateProfile:
    def make_profile(self) -> CandidateProfile:
        profile = CandidateProfile.start(user_id=uuid4(), full_name="  Иванов Артём  ", now=NOW)
        profile.update_details(details(), max_skills=5, now=NOW)
        return profile

    def test_start_trims_name_and_is_not_verified(self) -> None:
        profile = CandidateProfile.start(user_id=uuid4(), full_name="  Иванов  ", now=NOW)
        assert profile.full_name == "Иванов"
        assert not profile.is_fsp_verified
        assert profile.best_score == 0.0

    def test_salary_must_be_positive(self) -> None:
        profile = self.make_profile()
        with pytest.raises(InvalidSalaryError):
            profile.update_details(details(salary_expectation=0), max_skills=5, now=NOW)

    def test_fsp_sync_scores_and_verifies(self, rules: ScoringRules) -> None:
        profile = self.make_profile()
        older, newer = achievement(held_on=date(2024, 1, 1)), achievement(held_on=date(2025, 1, 1))
        later = NOW + timedelta(hours=1)
        profile.apply_fsp_sync(
            participant_full_name="ИВАНОВ  Артём Сергеевич",
            achievements=[older, newer],
            rules=rules,
            now=later,
        )
        assert profile.is_fsp_verified
        assert profile.achievements == [newer, older]
        assert profile.best_score == 90.0
        assert profile.fsp_synced_at == later

    def test_fsp_sync_matches_names_ignoring_yo(self, rules: ScoringRules) -> None:
        profile = self.make_profile()
        profile.update_details(
            details(full_name="Федоров Илья Константинович"), max_skills=5, now=NOW
        )
        profile.apply_fsp_sync(
            participant_full_name="Фёдоров Илья Константинович",
            achievements=[achievement()],
            rules=rules,
            now=NOW,
        )
        assert profile.is_fsp_verified

    def test_fsp_sync_rejects_someone_elses_participant_id(self, rules: ScoringRules) -> None:
        profile = self.make_profile()
        with pytest.raises(FspIdentityMismatchError) as error:
            profile.apply_fsp_sync(
                participant_full_name="Петров Глеб Максимович",
                achievements=[achievement()],
                rules=rules,
                now=NOW,
            )
        assert error.value.details == {"fsp_participant_id": "FSP-1001"}
        assert not profile.is_fsp_verified

    def test_fsp_sync_requires_linked_participant(self, rules: ScoringRules) -> None:
        profile = CandidateProfile.start(user_id=uuid4(), full_name="Иванов", now=NOW)
        with pytest.raises(FspParticipantNotLinkedError):
            profile.apply_fsp_sync(
                participant_full_name="Иванов", achievements=[], rules=rules, now=NOW
            )

    def test_changing_participant_id_drops_confirmed_achievements(
        self, rules: ScoringRules
    ) -> None:
        profile = self.make_profile()
        profile.apply_fsp_sync(
            participant_full_name=profile.full_name,
            achievements=[achievement()],
            rules=rules,
            now=NOW,
        )
        profile.update_details(details(fsp_participant_id="FSP-9999"), max_skills=5, now=NOW)
        assert profile.achievements == []
        assert profile.discipline_scores == []
        assert profile.fsp_synced_at is None

    def test_keeping_participant_id_keeps_achievements(self, rules: ScoringRules) -> None:
        profile = self.make_profile()
        profile.apply_fsp_sync(
            participant_full_name=profile.full_name,
            achievements=[achievement()],
            rules=rules,
            now=NOW,
        )
        profile.update_details(
            details(fsp_participant_id=" FSP-1001 ", city="  "), max_skills=5, now=NOW
        )
        assert profile.is_fsp_verified
        assert profile.city is None
