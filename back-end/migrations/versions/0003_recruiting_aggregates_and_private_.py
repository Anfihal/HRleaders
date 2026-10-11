"""recruiting aggregates and private avatar media

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-05 16:14:26.408536
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

from app.shared.database import UtcDateTime

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "recruiting_entities",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("kind", sa.String(length=32), nullable=False),
        sa.Column("data", sa.JSON(), nullable=False),
        sa.Column("created_at", UtcDateTime(), nullable=False),
        sa.Column("updated_at", UtcDateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["owner_id"],
            ["users.id"],
            name=op.f("fk_recruiting_entities_owner_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_recruiting_entities")),
    )
    with op.batch_alter_table("recruiting_entities", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_recruiting_entities_kind"), ["kind"], unique=False)
        batch_op.create_index(
            batch_op.f("ix_recruiting_entities_owner_id"), ["owner_id"], unique=False
        )

    op.create_table(
        "recruiting_avatar_images",
        sa.Column("avatar_id", sa.Uuid(), nullable=False),
        sa.Column("content", sa.LargeBinary(), nullable=False),
        sa.ForeignKeyConstraint(
            ["avatar_id"],
            ["recruiting_entities.id"],
            name=op.f("fk_recruiting_avatar_images_avatar_id_recruiting_entities"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("avatar_id", name=op.f("pk_recruiting_avatar_images")),
    )
    op.create_table(
        "recruiting_interview_links",
        sa.Column("interview_id", sa.Uuid(), nullable=False),
        sa.Column("vacancy_id", sa.Uuid(), nullable=False),
        sa.Column("candidate_id", sa.Uuid(), nullable=False),
        sa.Column("scenario_id", sa.Uuid(), nullable=False),
        sa.ForeignKeyConstraint(
            ["candidate_id"],
            ["candidate_profiles.id"],
            name=op.f("fk_recruiting_interview_links_candidate_id_candidate_profiles"),
        ),
        sa.ForeignKeyConstraint(
            ["interview_id"],
            ["recruiting_entities.id"],
            name=op.f("fk_recruiting_interview_links_interview_id_recruiting_entities"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["scenario_id"],
            ["recruiting_entities.id"],
            name=op.f("fk_recruiting_interview_links_scenario_id_recruiting_entities"),
        ),
        sa.ForeignKeyConstraint(
            ["vacancy_id"],
            ["vacancies.id"],
            name=op.f("fk_recruiting_interview_links_vacancy_id_vacancies"),
        ),
        sa.PrimaryKeyConstraint("interview_id", name=op.f("pk_recruiting_interview_links")),
    )
    with op.batch_alter_table("recruiting_interview_links", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_recruiting_interview_links_candidate_id"), ["candidate_id"], unique=False
        )


def downgrade() -> None:
    with op.batch_alter_table("recruiting_interview_links", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_recruiting_interview_links_candidate_id"))

    op.drop_table("recruiting_interview_links")
    op.drop_table("recruiting_avatar_images")
    with op.batch_alter_table("recruiting_entities", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_recruiting_entities_owner_id"))
        batch_op.drop_index(batch_op.f("ix_recruiting_entities_kind"))

    op.drop_table("recruiting_entities")
