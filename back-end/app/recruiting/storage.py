"""Private filesystem object-store adapter; object keys never come from API input."""

import os
import re
from datetime import datetime
from pathlib import Path
from tempfile import NamedTemporaryFile

from app.shared.errors import ExternalServiceError, NotFoundError


class StorageError(ExternalServiceError):
    code = "storage_unavailable"


class FileObjectStorage:
    def __init__(self, root: Path) -> None:
        self.root = root.resolve()

    def path(self, key: str) -> Path:
        if not re.fullmatch(r"avatars/[0-9a-f-]{36}/[0-9a-f]{64}\.png", key):
            raise StorageError("Некорректный ключ объекта")
        result = self.root / key
        if not result.resolve().is_relative_to(self.root):
            raise StorageError("Некорректный путь объекта")
        return result

    def put(self, key: str, content: bytes) -> None:
        target = self.path(key)
        temporary: str | None = None
        try:
            target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            with NamedTemporaryFile(dir=target.parent, delete=False) as stream:
                temporary = stream.name
                stream.write(content)
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, target)
        except OSError as error:
            raise StorageError("Не удалось сохранить объект") from error
        finally:
            if temporary and os.path.exists(temporary):
                os.unlink(temporary)

    def get(self, key: str) -> bytes:
        try:
            return self.path(key).read_bytes()
        except FileNotFoundError as error:
            raise NotFoundError("Изображение удалено") from error
        except OSError as error:
            raise StorageError("Не удалось прочитать объект") from error

    def delete(self, key: str) -> None:
        try:
            self.path(key).unlink(missing_ok=True)
        except OSError as error:
            raise StorageError("Не удалось удалить объект") from error

    def purge_orphans(self, referenced: set[str], before: datetime, limit: int = 1000) -> int:
        count = 0
        for path in self.root.glob("avatars/*/*.png"):
            key = path.relative_to(self.root).as_posix()
            if key not in referenced and path.stat().st_mtime < before.timestamp():
                self.delete(key)
                count += 1
                if count >= limit:
                    break
        return count
