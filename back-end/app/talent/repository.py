"""SQLAlchemy adapters of the talent ports."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import ColumnElement, exists, func, select
from sqlalchemy.orm import Session

from app.fsp.translator import FspVocabulary
from app.talent.domain import (
    CandidateProfile,
    Discipline,
    DisciplineScore,
    FspAchievement,
    Grade,
    ScoringRules,
    TeamRole,
    VerificationLevel,
    WorkFormat,
    normalize_skill,
)
from app.talent.orm import (
    CandidateDisciplineScoreRecord,
    CandidateProfileRecord,
    CandidateSkillRecord,
    FspAchievementRecord,
    FspDisciplineRecord,
    ProfileViewRecord,
    ScoringRuleRecord,
    VerificationLevelRecord,
)
from app.talent.ports import CandidateMatch, CandidateSearchPage, CandidateSearchQuery


class ScoringRuleType:
    RESULT = "result"
    COMPETITION_LEVEL = "competition_level"
    SPORT_RANK = "sport_rank"


class SqlAlchemyCandidateProfileRepository:
    def __init__(self, session: Session) -> None:
        self._session = session

    def get(self, profile_id: UUID) -> CandidateProfile | None:
        record = self._session.get(CandidateProfileRecord, profile_id)
        return to_domain(record) if record else None

    def get_by_user(self, user_id: UUID) -> CandidateProfile | None:
        record = self._session.scalar(
            select(CandidateProfileRecord).where(CandidateProfileRecord.user_id == user_id)
        )
        return to_domain(record) if record else None

    def save(self, profile: CandidateProfile) -> None:
        record = self._session.get(CandidateProfileRecord, profile.id)
        if record is None:
            record = CandidateProfileRecord(id=profile.id, user_id=profile.user_id)
            self._session.add(record)
        record.full_name = profile.full_name
        record.headline = profile.headline
        record.city = profile.city
        record.grade = profile.grade.value if profile.grade else None
        record.team_role = profile.team_role.value if profile.team_role else None
        record.work_format = profile.work_format.value if profile.work_format else None
        record.salary_expectation = profile.salary_expectation
        record.about = profile.about
        record.open_to_offers = profile.open_to_offers
        record.fsp_participant_id = profile.fsp_participant_id
        record.fsp_synced_at = profile.fsp_synced_at
        record.created_at = profile.created_at
        record.updated_at = profile.updated_at
        # Replace child collections; flush deletes first so unique keys can be reused.
        record.skills.clear()
        record.achievements.clear()
        record.scores.clear()
        self._session.flush()
        record.skills.extend(
            CandidateSkillRecord(name=skill, normalized=normalize_skill(skill), position=index)
            for index, skill in enumerate(profile.skills)
        )
        record.achievements.extend(
            FspAchievementRecord(
                competition_name=item.competition_name,
                held_on=item.held_on,
                discipline_code=item.discipline_code,
                competition_level_code=item.competition_level_code,
                result_code=item.result_code,
                team_role=item.team_role,
                sport_rank_code=item.sport_rank_code,
            )
            for item in profile.achievements
        )
        record.scores.extend(
            CandidateDisciplineScoreRecord(discipline_code=item.discipline_code, score=item.score)
            for item in profile.discipline_scores
        )
        self._session.flush()

    def search(self, query: CandidateSearchQuery) -> CandidateSearchPage:
        profile = CandidateProfileRecord
        score_filter = (
            [CandidateDisciplineScoreRecord.discipline_code == query.discipline_code]
            if query.discipline_code
            else []
        )
        scores = (
            select(
                CandidateDisciplineScoreRecord.candidate_id,
                func.max(CandidateDisciplineScoreRecord.score).label("score"),
            )
            .where(*score_filter)
            .group_by(CandidateDisciplineScoreRecord.candidate_id)
            .subquery()
        )
        relevant_score = func.coalesce(scores.c.score, 0.0)

        conditions: list[ColumnElement[bool]] = [profile.open_to_offers.is_(True)]
        if query.discipline_code or query.verified_only:
            conditions.append(scores.c.score.is_not(None))
        if query.verified_only:
            conditions.append(profile.fsp_synced_at.is_not(None))
        if query.min_score is not None:
            conditions.append(relevant_score >= query.min_score)
        if query.grade:
            conditions.append(profile.grade == query.grade.value)
        if query.team_role:
            conditions.append(profile.team_role == query.team_role.value)
        if query.work_format:
            conditions.append(profile.work_format == query.work_format.value)
        if query.max_salary is not None:
            conditions.append(profile.salary_expectation <= query.max_salary)
        if query.skill:
            conditions.append(
                exists().where(
                    CandidateSkillRecord.candidate_id == profile.id,
                    CandidateSkillRecord.normalized == normalize_skill(query.skill),
                )
            )

        base = select(profile, relevant_score.label("relevant_score")).outerjoin(
            scores, scores.c.candidate_id == profile.id
        )
        filtered = base.where(*conditions)
        total = self._session.scalar(select(func.count()).select_from(filtered.subquery())) or 0
        rows = self._session.execute(
            filtered.order_by(relevant_score.desc(), profile.updated_at.desc(), profile.id)
            .limit(query.limit)
            .offset(query.offset)
        ).all()
        return CandidateSearchPage(
            items=[CandidateMatch(to_domain(row[0]), float(row[1])) for row in rows],
            total=int(total),
        )


class SqlAlchemyTalentReferenceData:
    def __init__(self, session: Session) -> None:
        self._session = session

    def _rules(self, rule_type: str) -> list[ScoringRuleRecord]:
        return list(
            self._session.scalars(
                select(ScoringRuleRecord)
                .where(ScoringRuleRecord.rule_type == rule_type)
                .order_by(ScoringRuleRecord.sort_order)
            )
        )

    def scoring_rules(self) -> ScoringRules:
        levels = self._session.scalars(
            select(VerificationLevelRecord).order_by(VerificationLevelRecord.min_score)
        )
        return ScoringRules(
            result_points={r.code: r.value for r in self._rules(ScoringRuleType.RESULT)},
            competition_level_multipliers={
                r.code: r.value for r in self._rules(ScoringRuleType.COMPETITION_LEVEL)
            },
            sport_rank_points={r.code: r.value for r in self._rules(ScoringRuleType.SPORT_RANK)},
            levels=[VerificationLevel(lv.code, lv.label, lv.min_score) for lv in levels],
        )

    def fsp_vocabulary(self) -> FspVocabulary:
        disciplines = self._session.scalars(select(FspDisciplineRecord))
        return FspVocabulary.build(
            disciplines={d.fsp_label: d.code for d in disciplines},
            competition_levels={
                r.fsp_label: r.code for r in self._rules(ScoringRuleType.COMPETITION_LEVEL)
            },
            results={r.fsp_label: r.code for r in self._rules(ScoringRuleType.RESULT)},
            sport_ranks={r.fsp_label: r.code for r in self._rules(ScoringRuleType.SPORT_RANK)},
        )

    def disciplines(self) -> list[Discipline]:
        records = self._session.scalars(
            select(FspDisciplineRecord).order_by(FspDisciplineRecord.sort_order)
        )
        return [Discipline(record.code, record.label) for record in records]

    def labelled_rules(self) -> dict[str, list[tuple[str, str]]]:
        """(code, label) pairs per rule type — for the dictionaries endpoint."""
        return {
            rule_type: [(r.code, r.label) for r in self._rules(rule_type)]
            for rule_type in (
                ScoringRuleType.RESULT,
                ScoringRuleType.COMPETITION_LEVEL,
                ScoringRuleType.SPORT_RANK,
            )
        }


class SqlAlchemyProfileViewLog:
    def __init__(self, session: Session) -> None:
        self._session = session

    def record(self, *, employer_id: UUID, candidate_id: UUID, viewed_at: datetime) -> None:
        self._session.add(
            ProfileViewRecord(
                employer_id=employer_id, candidate_id=candidate_id, viewed_at=viewed_at
            )
        )
        self._session.flush()


def to_domain(record: CandidateProfileRecord) -> CandidateProfile:
    return CandidateProfile(
        id=record.id,
        user_id=record.user_id,
        full_name=record.full_name,
        headline=record.headline,
        created_at=record.created_at,
        updated_at=record.updated_at,
        city=record.city,
        grade=Grade(record.grade) if record.grade else None,
        team_role=TeamRole(record.team_role) if record.team_role else None,
        work_format=WorkFormat(record.work_format) if record.work_format else None,
        salary_expectation=record.salary_expectation,
        skills=[skill.name for skill in record.skills],
        about=record.about,
        open_to_offers=record.open_to_offers,
        fsp_participant_id=record.fsp_participant_id,
        fsp_synced_at=record.fsp_synced_at,
        achievements=[
            FspAchievement(
                competition_name=item.competition_name,
                held_on=item.held_on,
                discipline_code=item.discipline_code,
                competition_level_code=item.competition_level_code,
                result_code=item.result_code,
                team_role=item.team_role,
                sport_rank_code=item.sport_rank_code,
            )
            for item in record.achievements
        ],
        discipline_scores=[
            DisciplineScore(item.discipline_code, item.score) for item in record.scores
        ],
    )
