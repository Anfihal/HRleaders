"""Initial schema of identity, talent and hiring contexts.

Revision ID: 0001
Revises:
Create Date: 2026-10-04 21:55:37.058311
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:

    op.create_table(
        "fsp_disciplines",
        sa.Column("code", sa.String(length=64), nullable=False),
        sa.Column("fsp_label", sa.String(length=200), nullable=False),
        sa.Column("label", sa.String(length=200), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint("code", name=op.f("pk_fsp_disciplines")),
        sa.UniqueConstraint("fsp_label", name=op.f("uq_fsp_disciplines_fsp_label")),
    )
    op.create_table(
        "scoring_rules",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("rule_type", sa.String(length=32), nullable=False),
        sa.Column("code", sa.String(length=64), nullable=False),
        sa.Column("fsp_label", sa.String(length=200), nullable=False),
        sa.Column("label", sa.String(length=200), nullable=False),
        sa.Column("value", sa.Float(), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_scoring_rules")),
        sa.UniqueConstraint("rule_type", "code", name=op.f("uq_scoring_rules_rule_type_code")),
    )
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("email", sa.String(length=320), nullable=False),
        sa.Column("full_name", sa.String(length=200), nullable=False),
        sa.Column("role", sa.String(length=32), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("company_name", sa.String(length=200), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_users")),
        sa.UniqueConstraint("email", name=op.f("uq_users_email")),
    )
    with op.batch_alter_table("users", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_users_role"), ["role"], unique=False)

    op.create_table(
        "verification_levels",
        sa.Column("code", sa.String(length=32), nullable=False),
        sa.Column("label", sa.String(length=100), nullable=False),
        sa.Column("min_score", sa.Float(), nullable=False),
        sa.PrimaryKeyConstraint("code", name=op.f("pk_verification_levels")),
        sa.UniqueConstraint("min_score", name=op.f("uq_verification_levels_min_score")),
    )
    op.create_table(
        "candidate_profiles",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("full_name", sa.String(length=200), nullable=False),
        sa.Column("headline", sa.String(length=200), nullable=False),
        sa.Column("city", sa.String(length=120), nullable=True),
        sa.Column("grade", sa.String(length=32), nullable=True),
        sa.Column("team_role", sa.String(length=32), nullable=True),
        sa.Column("work_format", sa.String(length=32), nullable=True),
        sa.Column("salary_expectation", sa.Integer(), nullable=True),
        sa.Column("about", sa.Text(), nullable=True),
        sa.Column("open_to_offers", sa.Boolean(), nullable=False),
        sa.Column("fsp_participant_id", sa.String(length=64), nullable=True),
        sa.Column("fsp_synced_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name=op.f("fk_candidate_profiles_user_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_candidate_profiles")),
        sa.UniqueConstraint("user_id", name=op.f("uq_candidate_profiles_user_id")),
    )
    with op.batch_alter_table("candidate_profiles", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_candidate_profiles_fsp_participant_id"),
            ["fsp_participant_id"],
            unique=False,
        )
        batch_op.create_index(batch_op.f("ix_candidate_profiles_grade"), ["grade"], unique=False)
        batch_op.create_index(
            batch_op.f("ix_candidate_profiles_open_to_offers"), ["open_to_offers"], unique=False
        )
        batch_op.create_index(
            batch_op.f("ix_candidate_profiles_team_role"), ["team_role"], unique=False
        )
        batch_op.create_index(
            batch_op.f("ix_candidate_profiles_work_format"), ["work_format"], unique=False
        )

    op.create_table(
        "vacancies",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("employer_id", sa.Uuid(), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("discipline_code", sa.String(length=64), nullable=True),
        sa.Column("grade", sa.String(length=32), nullable=True),
        sa.Column("work_format", sa.String(length=32), nullable=True),
        sa.Column("salary_from", sa.Integer(), nullable=False),
        sa.Column("salary_to", sa.Integer(), nullable=False),
        sa.Column("skills", sa.JSON(), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("is_open", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "salary_from > 0 AND salary_to >= salary_from", name=op.f("ck_vacancies_salary_range")
        ),
        sa.ForeignKeyConstraint(
            ["discipline_code"],
            ["fsp_disciplines.code"],
            name=op.f("fk_vacancies_discipline_code_fsp_disciplines"),
        ),
        sa.ForeignKeyConstraint(
            ["employer_id"],
            ["users.id"],
            name=op.f("fk_vacancies_employer_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_vacancies")),
    )
    with op.batch_alter_table("vacancies", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_vacancies_employer_id"), ["employer_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_vacancies_is_open"), ["is_open"], unique=False)

    op.create_table(
        "candidate_discipline_scores",
        sa.Column("candidate_id", sa.Uuid(), nullable=False),
        sa.Column("discipline_code", sa.String(length=64), nullable=False),
        sa.Column("score", sa.Float(), nullable=False),
        sa.ForeignKeyConstraint(
            ["candidate_id"],
            ["candidate_profiles.id"],
            name=op.f("fk_candidate_discipline_scores_candidate_id_candidate_profiles"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["discipline_code"],
            ["fsp_disciplines.code"],
            name=op.f("fk_candidate_discipline_scores_discipline_code_fsp_disciplines"),
        ),
        sa.PrimaryKeyConstraint(
            "candidate_id", "discipline_code", name=op.f("pk_candidate_discipline_scores")
        ),
    )
    with op.batch_alter_table("candidate_discipline_scores", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_candidate_discipline_scores_score"), ["score"], unique=False
        )

    op.create_table(
        "candidate_skills",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("candidate_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("normalized", sa.String(length=80), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(
            ["candidate_id"],
            ["candidate_profiles.id"],
            name=op.f("fk_candidate_skills_candidate_id_candidate_profiles"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_candidate_skills")),
        sa.UniqueConstraint(
            "candidate_id", "normalized", name=op.f("uq_candidate_skills_candidate_id_normalized")
        ),
    )
    with op.batch_alter_table("candidate_skills", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_candidate_skills_candidate_id"), ["candidate_id"], unique=False
        )
        batch_op.create_index(
            batch_op.f("ix_candidate_skills_normalized"), ["normalized"], unique=False
        )

    op.create_table(
        "fsp_achievements",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("candidate_id", sa.Uuid(), nullable=False),
        sa.Column("competition_name", sa.String(length=300), nullable=False),
        sa.Column("held_on", sa.Date(), nullable=False),
        sa.Column("discipline_code", sa.String(length=64), nullable=False),
        sa.Column("competition_level_code", sa.String(length=64), nullable=False),
        sa.Column("result_code", sa.String(length=64), nullable=False),
        sa.Column("team_role", sa.String(length=64), nullable=True),
        sa.Column("sport_rank_code", sa.String(length=64), nullable=True),
        sa.ForeignKeyConstraint(
            ["candidate_id"],
            ["candidate_profiles.id"],
            name=op.f("fk_fsp_achievements_candidate_id_candidate_profiles"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["discipline_code"],
            ["fsp_disciplines.code"],
            name=op.f("fk_fsp_achievements_discipline_code_fsp_disciplines"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_fsp_achievements")),
    )
    with op.batch_alter_table("fsp_achievements", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_fsp_achievements_candidate_id"), ["candidate_id"], unique=False
        )

    op.create_table(
        "offers",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("vacancy_id", sa.Uuid(), nullable=False),
        sa.Column("employer_id", sa.Uuid(), nullable=False),
        sa.Column("candidate_id", sa.Uuid(), nullable=False),
        sa.Column("salary", sa.Integer(), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("viewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("decline_reason", sa.Text(), nullable=True),
        sa.CheckConstraint("salary > 0", name=op.f("ck_offers_salary_positive")),
        sa.ForeignKeyConstraint(
            ["candidate_id"],
            ["candidate_profiles.id"],
            name=op.f("fk_offers_candidate_id_candidate_profiles"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["employer_id"],
            ["users.id"],
            name=op.f("fk_offers_employer_id_users"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["vacancy_id"],
            ["vacancies.id"],
            name=op.f("fk_offers_vacancy_id_vacancies"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_offers")),
    )
    with op.batch_alter_table("offers", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_offers_candidate_id"), ["candidate_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_offers_employer_id"), ["employer_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_offers_status"), ["status"], unique=False)
        batch_op.create_index(
            "ix_offers_vacancy_candidate", ["vacancy_id", "candidate_id"], unique=False
        )

    op.create_table(
        "profile_views",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("employer_id", sa.Uuid(), nullable=False),
        sa.Column("candidate_id", sa.Uuid(), nullable=False),
        sa.Column("viewed_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["candidate_id"],
            ["candidate_profiles.id"],
            name=op.f("fk_profile_views_candidate_id_candidate_profiles"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["employer_id"],
            ["users.id"],
            name=op.f("fk_profile_views_employer_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_profile_views")),
    )
    with op.batch_alter_table("profile_views", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_profile_views_candidate_id"), ["candidate_id"], unique=False
        )
        batch_op.create_index(
            batch_op.f("ix_profile_views_employer_id"), ["employer_id"], unique=False
        )


def downgrade() -> None:

    with op.batch_alter_table("profile_views", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_profile_views_employer_id"))
        batch_op.drop_index(batch_op.f("ix_profile_views_candidate_id"))

    op.drop_table("profile_views")
    with op.batch_alter_table("offers", schema=None) as batch_op:
        batch_op.drop_index("ix_offers_vacancy_candidate")
        batch_op.drop_index(batch_op.f("ix_offers_status"))
        batch_op.drop_index(batch_op.f("ix_offers_employer_id"))
        batch_op.drop_index(batch_op.f("ix_offers_candidate_id"))

    op.drop_table("offers")
    with op.batch_alter_table("fsp_achievements", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_fsp_achievements_candidate_id"))

    op.drop_table("fsp_achievements")
    with op.batch_alter_table("candidate_skills", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_candidate_skills_normalized"))
        batch_op.drop_index(batch_op.f("ix_candidate_skills_candidate_id"))

    op.drop_table("candidate_skills")
    with op.batch_alter_table("candidate_discipline_scores", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_candidate_discipline_scores_score"))

    op.drop_table("candidate_discipline_scores")
    with op.batch_alter_table("vacancies", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_vacancies_is_open"))
        batch_op.drop_index(batch_op.f("ix_vacancies_employer_id"))

    op.drop_table("vacancies")
    with op.batch_alter_table("candidate_profiles", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_candidate_profiles_work_format"))
        batch_op.drop_index(batch_op.f("ix_candidate_profiles_team_role"))
        batch_op.drop_index(batch_op.f("ix_candidate_profiles_open_to_offers"))
        batch_op.drop_index(batch_op.f("ix_candidate_profiles_grade"))
        batch_op.drop_index(batch_op.f("ix_candidate_profiles_fsp_participant_id"))

    op.drop_table("candidate_profiles")
    op.drop_table("verification_levels")
    with op.batch_alter_table("users", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_users_role"))

    op.drop_table("users")
    op.drop_table("scoring_rules")
    op.drop_table("fsp_disciplines")
