"""Replayable public event boundary; transport owns no interview business rules."""

from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.recruiting.orm import WorkflowMessageRecord


def events(
    session: Session, entity_id: UUID, owner_id: UUID, after: int, limit: int
) -> dict[str, Any]:
    rows = session.scalars(
        select(WorkflowMessageRecord)
        .where(
            WorkflowMessageRecord.entity_id == entity_id,
            WorkflowMessageRecord.owner_id == owner_id,
            WorkflowMessageRecord.message_kind == "event",
            WorkflowMessageRecord.sequence > after,
        )
        .order_by(WorkflowMessageRecord.sequence)
        .limit(limit)
    ).all()
    return {
        "events": [{"sequence": row.sequence, **row.envelope} for row in rows],
        "cursor": rows[-1].sequence if rows else after,
    }
