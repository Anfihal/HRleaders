"""durable recruiting jobs outbox and object metadata

Revision ID: 0004
Revises: 0003
Create Date: 2026-10-06 11:28:19.889664
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

from app.shared.database import UtcDateTime

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "recruiting_jobs",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("entity_id", sa.Uuid(), nullable=False),
        sa.Column("type", sa.String(length=64), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("correlation_id", sa.String(length=64), nullable=False),
        sa.Column("request_id", sa.String(length=64), nullable=False),
        sa.Column("attempt", sa.Integer(), nullable=False),
        sa.Column("max_attempts", sa.Integer(), nullable=False),
        sa.Column("lease_token", sa.Uuid(), nullable=True),
        sa.Column("lease_until", UtcDateTime(), nullable=True),
        sa.Column("available_at", UtcDateTime(), nullable=False),
        sa.Column("error_code", sa.String(length=64), nullable=True),
        sa.Column("error_message", sa.String(length=200), nullable=True),
        sa.Column("created_at", UtcDateTime(), nullable=False),
        sa.Column("started_at", UtcDateTime(), nullable=True),
        sa.Column("completed_at", UtcDateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["entity_id"],
            ["recruiting_entities.id"],
            name=op.f("fk_recruiting_jobs_entity_id_recruiting_entities"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["owner_id"],
            ["users.id"],
            name=op.f("fk_recruiting_jobs_owner_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_recruiting_jobs")),
        sa.UniqueConstraint("entity_id", "type", name=op.f("uq_recruiting_jobs_entity_id_type")),
    )
    with op.batch_alter_table("recruiting_jobs", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_recruiting_jobs_entity_id"), ["entity_id"], unique=False
        )
        batch_op.create_index(batch_op.f("ix_recruiting_jobs_owner_id"), ["owner_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_recruiting_jobs_status"), ["status"], unique=False)

    op.create_table(
        "recruiting_media_objects",
        sa.Column("avatar_id", sa.Uuid(), nullable=False),
        sa.Column("storage_key", sa.String(length=200), nullable=False),
        sa.Column("mime_type", sa.String(length=100), nullable=False),
        sa.Column("size", sa.Integer(), nullable=False),
        sa.Column("checksum", sa.String(length=64), nullable=False),
        sa.Column("created_at", UtcDateTime(), nullable=False),
        sa.Column("retention_until", UtcDateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["avatar_id"],
            ["recruiting_entities.id"],
            name=op.f("fk_recruiting_media_objects_avatar_id_recruiting_entities"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("avatar_id", name=op.f("pk_recruiting_media_objects")),
        sa.UniqueConstraint("storage_key", name=op.f("uq_recruiting_media_objects_storage_key")),
    )
    op.create_table(
        "recruiting_outbox",
        sa.Column("sequence", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("event_id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("entity_id", sa.Uuid(), nullable=False),
        sa.Column("job_id", sa.Uuid(), nullable=True),
        sa.Column("subject", sa.String(length=100), nullable=False),
        sa.Column("message_kind", sa.String(length=16), nullable=False),
        sa.Column("envelope", sa.JSON(), nullable=False),
        sa.Column("created_at", UtcDateTime(), nullable=False),
        sa.Column("published_at", UtcDateTime(), nullable=True),
        sa.ForeignKeyConstraint(
            ["entity_id"],
            ["recruiting_entities.id"],
            name=op.f("fk_recruiting_outbox_entity_id_recruiting_entities"),
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["job_id"],
            ["recruiting_jobs.id"],
            name=op.f("fk_recruiting_outbox_job_id_recruiting_jobs"),
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["owner_id"],
            ["users.id"],
            name=op.f("fk_recruiting_outbox_owner_id_users"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("sequence", name=op.f("pk_recruiting_outbox")),
        sa.UniqueConstraint("event_id", name=op.f("uq_recruiting_outbox_event_id")),
    )
    with op.batch_alter_table("recruiting_outbox", schema=None) as batch_op:
        batch_op.create_index(
            batch_op.f("ix_recruiting_outbox_entity_id"), ["entity_id"], unique=False
        )
        batch_op.create_index(
            batch_op.f("ix_recruiting_outbox_owner_id"), ["owner_id"], unique=False
        )
        batch_op.create_index(
            batch_op.f("ix_recruiting_outbox_published_at"), ["published_at"], unique=False
        )


def downgrade() -> None:
    with op.batch_alter_table("recruiting_outbox", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_recruiting_outbox_published_at"))
        batch_op.drop_index(batch_op.f("ix_recruiting_outbox_owner_id"))
        batch_op.drop_index(batch_op.f("ix_recruiting_outbox_entity_id"))

    op.drop_table("recruiting_outbox")
    op.drop_table("recruiting_media_objects")
    with op.batch_alter_table("recruiting_jobs", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_recruiting_jobs_status"))
        batch_op.drop_index(batch_op.f("ix_recruiting_jobs_owner_id"))
        batch_op.drop_index(batch_op.f("ix_recruiting_jobs_entity_id"))

    op.drop_table("recruiting_jobs")
