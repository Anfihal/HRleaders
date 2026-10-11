"""Talent domain: IT specialist profile verified by FSP achievements.

Categorization turns confirmed FSP achievements into a *talent category* per discipline:
`score = Σ result_points × competition_level_multiplier + highest sport_rank_points`,
and the verification level is the highest level whose threshold the score reaches.
All weights and thresholds come from reference data (`ScoringRules`), never from code.
"""

from collections import defaultdict
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass, field
from datetime import date, datetime
from enum import StrEnum
from uuid import UUID, uuid4

from app.shared.errors import ConflictError, DomainValidationError, NotFoundError

SCORE_PRECISION = 1


class Grade(StrEnum):
    JUNIOR = "junior"
    MIDDLE = "middle"
    SENIOR = "senior"
    LEAD = "lead"


class TeamRole(StrEnum):
    BACKEND = "backend"
    FRONTEND = "frontend"
    FULLSTACK = "fullstack"
    MOBILE = "mobile"
    ML = "ml"
    DEVOPS = "devops"
    SECURITY = "security"
    QA = "qa"
    EMBEDDED = "embedded"


class WorkFormat(StrEnum):
    OFFICE = "office"
    HYBRID = "hybrid"
    REMOTE = "remote"


GRADE_LABELS = {
    Grade.JUNIOR: "Junior",
    Grade.MIDDLE: "Middle",
    Grade.SENIOR: "Senior",
    Grade.LEAD: "Lead",
}
TEAM_ROLE_LABELS = {
    TeamRole.BACKEND: "Backend",
    TeamRole.FRONTEND: "Frontend",
    TeamRole.FULLSTACK: "Fullstack",
    TeamRole.MOBILE: "Mobile",
    TeamRole.ML: "ML / Data Science",
    TeamRole.DEVOPS: "DevOps",
    TeamRole.SECURITY: "Security",
    TeamRole.QA: "QA",
    TeamRole.EMBEDDED: "Embedded / Robotics",
}
WORK_FORMAT_LABELS = {
    WorkFormat.OFFICE: "Офис",
    WorkFormat.HYBRID: "Гибрид",
    WorkFormat.REMOTE: "Удалённо",
}


class CandidateProfileNotFoundError(NotFoundError):
    code = "candidate_profile_not_found"


class FspParticipantNotLinkedError(DomainValidationError):
    code = "fsp_participant_not_linked"


class FspIdentityMismatchError(ConflictError):
    code = "fsp_identity_mismatch"


class UnknownVerificationLevelError(DomainValidationError):
    code = "unknown_verification_level"


class UnknownDisciplineError(DomainValidationError):
    code = "unknown_discipline"


def ensure_known_discipline(code: str, disciplines: Iterable["Discipline"]) -> None:
    if code not in {discipline.code for discipline in disciplines}:
        raise UnknownDisciplineError(f"Неизвестное направление ФСП: {code}")


class TooManySkillsError(DomainValidationError):
    code = "too_many_skills"


class InvalidSalaryError(DomainValidationError):
    code = "invalid_salary"


@dataclass(frozen=True)
class Discipline:
    code: str
    label: str


@dataclass(frozen=True)
class VerificationLevel:
    code: str
    label: str
    min_score: float


@dataclass(frozen=True)
class FspAchievement:
    """A competition result confirmed by FSP, already translated to platform codes."""

    competition_name: str
    held_on: date
    discipline_code: str
    competition_level_code: str
    result_code: str
    team_role: str | None = None
    sport_rank_code: str | None = None


@dataclass(frozen=True)
class DisciplineScore:
    discipline_code: str
    score: float


@dataclass(frozen=True)
class TalentCategory:
    """Read view of a discipline score: level and the gap to the next level."""

    discipline_code: str
    score: float
    level: VerificationLevel
    next_level: VerificationLevel | None
    points_to_next_level: float | None


@dataclass(frozen=True)
class ScoringRules:
    result_points: Mapping[str, float]
    competition_level_multipliers: Mapping[str, float]
    sport_rank_points: Mapping[str, float]
    levels: Sequence[VerificationLevel]

    def __post_init__(self) -> None:
        if not self.levels:
            raise ValueError("Scoring rules require at least one verification level")
        ordered = tuple(sorted(self.levels, key=lambda level: level.min_score))
        object.__setattr__(self, "levels", ordered)

    def score_by_discipline(self, achievements: Iterable[FspAchievement]) -> list[DisciplineScore]:
        competition_points: dict[str, float] = defaultdict(float)
        best_rank_points: dict[str, float] = defaultdict(float)
        for achievement in achievements:
            discipline = achievement.discipline_code
            competition_points[discipline] += (
                self.result_points[achievement.result_code]
                * self.competition_level_multipliers[achievement.competition_level_code]
            )
            if achievement.sport_rank_code is not None:
                rank_points = self.sport_rank_points.get(achievement.sport_rank_code, 0.0)
                best_rank_points[discipline] = max(best_rank_points[discipline], rank_points)
        scores = [
            DisciplineScore(
                discipline,
                round(points + best_rank_points[discipline], SCORE_PRECISION),
            )
            for discipline, points in competition_points.items()
        ]
        return sorted(scores, key=lambda item: (-item.score, item.discipline_code))

    def level_for(self, score: float) -> VerificationLevel:
        reached = [level for level in self.levels if score >= level.min_score]
        return reached[-1] if reached else self.levels[0]

    def level_by_code(self, code: str) -> VerificationLevel:
        for level in self.levels:
            if level.code == code:
                return level
        raise UnknownVerificationLevelError(f"Неизвестный уровень подтверждения: {code}")

    def categorize(self, score: DisciplineScore) -> TalentCategory:
        level = self.level_for(score.score)
        higher = [item for item in self.levels if item.min_score > level.min_score]
        next_level = higher[0] if higher else None
        gap = round(next_level.min_score - score.score, SCORE_PRECISION) if next_level else None
        return TalentCategory(score.discipline_code, score.score, level, next_level, gap)


def normalize_skill(skill: str) -> str:
    return " ".join(skill.split()).casefold()


def clean_skills(skills: Iterable[str], max_count: int) -> list[str]:
    """Trim, drop empties and case-insensitive duplicates, keep the user's spelling."""
    seen: set[str] = set()
    cleaned: list[str] = []
    for raw in skills:
        display = " ".join(raw.split())
        key = display.casefold()
        if display and key not in seen:
            seen.add(key)
            cleaned.append(display)
    if len(cleaned) > max_count:
        raise TooManySkillsError(f"Можно указать не более {max_count} навыков")
    return cleaned


def normalize_person_name(name: str) -> str:
    return " ".join(name.replace("ё", "е").replace("Ё", "Е").split()).casefold()


@dataclass(frozen=True)
class ProfileDetails:
    full_name: str
    headline: str
    city: str | None = None
    grade: Grade | None = None
    team_role: TeamRole | None = None
    work_format: WorkFormat | None = None
    salary_expectation: int | None = None
    skills: Sequence[str] = ()
    about: str | None = None
    open_to_offers: bool = True
    fsp_participant_id: str | None = None


@dataclass
class CandidateProfile:
    """Aggregate root of the talent context."""

    id: UUID
    user_id: UUID
    full_name: str
    headline: str
    created_at: datetime
    updated_at: datetime
    city: str | None = None
    grade: Grade | None = None
    team_role: TeamRole | None = None
    work_format: WorkFormat | None = None
    salary_expectation: int | None = None
    skills: list[str] = field(default_factory=list)
    about: str | None = None
    open_to_offers: bool = True
    fsp_participant_id: str | None = None
    fsp_synced_at: datetime | None = None
    achievements: list[FspAchievement] = field(default_factory=list)
    discipline_scores: list[DisciplineScore] = field(default_factory=list)

    @classmethod
    def start(cls, *, user_id: UUID, full_name: str, now: datetime) -> "CandidateProfile":
        return cls(
            id=uuid4(),
            user_id=user_id,
            full_name=full_name.strip(),
            headline="",
            created_at=now,
            updated_at=now,
        )

    @property
    def is_fsp_verified(self) -> bool:
        return self.fsp_synced_at is not None and bool(self.discipline_scores)

    @property
    def best_score(self) -> float:
        return max((item.score for item in self.discipline_scores), default=0.0)

    def update_details(self, details: ProfileDetails, *, max_skills: int, now: datetime) -> None:
        if details.salary_expectation is not None and details.salary_expectation <= 0:
            raise InvalidSalaryError("Ожидаемая зарплата должна быть положительной")
        participant_id = (details.fsp_participant_id or "").strip() or None
        if participant_id != self.fsp_participant_id:
            # Achievements belong to the previously linked participant: drop them.
            self.fsp_participant_id = participant_id
            self.fsp_synced_at = None
            self.achievements = []
            self.discipline_scores = []
        self.full_name = details.full_name.strip()
        self.headline = details.headline.strip()
        self.city = (details.city or "").strip() or None
        self.grade = details.grade
        self.team_role = details.team_role
        self.work_format = details.work_format
        self.salary_expectation = details.salary_expectation
        self.skills = clean_skills(details.skills, max_skills)
        self.about = (details.about or "").strip() or None
        self.open_to_offers = details.open_to_offers
        self.updated_at = now

    def apply_fsp_sync(
        self,
        *,
        participant_full_name: str,
        achievements: Sequence[FspAchievement],
        rules: ScoringRules,
        now: datetime,
    ) -> None:
        if self.fsp_participant_id is None:
            raise FspParticipantNotLinkedError("Укажите ID участника ФСП в профиле")
        if normalize_person_name(participant_full_name) != normalize_person_name(self.full_name):
            raise FspIdentityMismatchError(
                "ФИО участника ФСП не совпадает с ФИО в профиле",
                details={"fsp_participant_id": self.fsp_participant_id},
            )
        self.achievements = sorted(achievements, key=lambda item: item.held_on, reverse=True)
        self.discipline_scores = rules.score_by_discipline(self.achievements)
        self.fsp_synced_at = now
        self.updated_at = now
