"""Idempotent legacy binary export; verify storage before removing database bytes."""

from hashlib import sha256

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.recruiting.orm import AvatarImageRecord, MediaObjectRecord
from app.recruiting.ports import StorageProvider
from app.recruiting.repository import SqlAlchemyRecruitingDirectory
from app.recruiting.storage import FileObjectStorage, StorageError
from app.shared.database import Database


def export_legacy(session: Session, storage: StorageProvider, limit: int = 100) -> int:
    rows = session.scalars(select(AvatarImageRecord).limit(limit).with_for_update()).all()
    directory = SqlAlchemyRecruitingDirectory(session, storage)
    for row in rows:
        media = session.get(MediaObjectRecord, row.avatar_id)
        if media is None:
            directory.save_image(row.avatar_id, row.content)
            media = session.get(MediaObjectRecord, row.avatar_id)
        assert media is not None
        if sha256(storage.get(media.storage_key)).hexdigest() != sha256(row.content).hexdigest():
            raise StorageError("Проверка экспортированного объекта не пройдена")
        session.delete(row)
    return len(rows)


def main() -> None:
    settings = get_settings()
    database = Database(settings.database_url)
    storage = FileObjectStorage(settings.media_storage_path)
    count = 0
    try:
        while True:
            with database.session_factory.begin() as session:
                exported = export_legacy(session, storage)
            count += exported
            if not exported:
                break
        print(f"Exported {count} legacy avatar images")
    finally:
        database.engine.dispose()


if __name__ == "__main__":
    main()
