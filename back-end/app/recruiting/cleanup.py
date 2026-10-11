"""Retention maintenance: schedule `python -m app.recruiting.cleanup` daily."""

from datetime import timedelta
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.recruiting.domain import TERMINAL_INTERVIEWS
from app.recruiting.orm import (
    ExecutionJobRecord,
    InterviewLinkRecord,
    MediaObjectRecord,
    RecruitingEntityRecord,
    WorkflowMessageRecord,
)
from app.recruiting.ports import StorageProvider
from app.recruiting.repository import SqlAlchemyRecruitingDirectory, SqlAlchemyRecruitingRepository
from app.recruiting.storage import FileObjectStorage
from app.recruiting.use_cases import ConfigurationService
from app.shared.database import Database, utc_now


def purge_expired(session: Session, storage: StorageProvider) -> int:
    now = utc_now()
    repo = SqlAlchemyRecruitingRepository(session)
    directory = SqlAlchemyRecruitingDirectory(session, storage)
    configuration = ConfigurationService(repo, set())
    count = 0
    owners = session.scalars(select(RecruitingEntityRecord.owner_id).distinct()).all()
    for owner in owners:
        retention = configuration.get(owner)["security"]["retention_days"]
        cutoff = now - timedelta(days=retention)
        rows = session.scalars(
            select(RecruitingEntityRecord).where(
                RecruitingEntityRecord.owner_id == owner,
                RecruitingEntityRecord.kind.in_(["interview", "avatar"]),
            )
        ).all()
        active_avatars = {
            row.data["snapshot"]["avatar"]["id"]
            for row in rows
            if row.kind == "interview"
            and row.data["status"] not in TERMINAL_INTERVIEWS
            and row.data["snapshot"]["avatar"]
        }
        for row in rows:
            if row.updated_at >= cutoff:
                continue
            expired_interview = row.kind == "interview" and row.data["status"] in (
                TERMINAL_INTERVIEWS | {"failed"}
            )
            expired_avatar = (
                row.kind == "avatar"
                and row.data["status"] == "archived"
                and str(row.id) not in active_avatars
            )
            if not (expired_interview or expired_avatar):
                continue
            # Use the same job -> entity lock order as the worker; never race a result commit.
            session.scalars(
                select(ExecutionJobRecord)
                .where(ExecutionJobRecord.entity_id == row.id)
                .with_for_update()
            ).all()
            locked = session.scalar(
                select(RecruitingEntityRecord)
                .where(RecruitingEntityRecord.id == row.id)
                .with_for_update()
                .execution_options(populate_existing=True)
            )
            if locked is None or locked.updated_at >= cutoff:
                continue
            # Explicit dependent deletes also work on SQLite with FK enforcement disabled.
            session.execute(
                delete(WorkflowMessageRecord).where(WorkflowMessageRecord.entity_id == row.id)
            )
            session.execute(
                delete(ExecutionJobRecord).where(ExecutionJobRecord.entity_id == row.id)
            )
            if expired_interview:
                session.execute(
                    delete(InterviewLinkRecord).where(InterviewLinkRecord.interview_id == row.id)
                )
                session.delete(locked)
                count += 1
            else:
                media = session.get(MediaObjectRecord, UUID(str(row.id)))
                directory.delete_image(row.id)
                count += int(media is not None)
    return count


def main() -> None:
    settings = get_settings()
    database = Database(settings.database_url)
    storage = FileObjectStorage(settings.media_storage_path)
    try:
        with database.session_factory.begin() as session:
            count = purge_expired(session, storage)
        # Recover files left by process death between object upload/deletion and SQL commit.
        # The grace period protects uploads still awaiting their short database transaction.
        with database.session_factory() as session:
            referenced = set(session.scalars(select(MediaObjectRecord.storage_key)))
        count += storage.purge_orphans(referenced, utc_now() - timedelta(days=1))
        print(f"Purged {count} expired recruiting items")
    finally:
        database.engine.dispose()


if __name__ == "__main__":
    main()
