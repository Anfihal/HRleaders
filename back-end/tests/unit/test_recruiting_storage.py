"""Private object keys and retention recovery of unreferenced files."""

import os
from datetime import UTC, datetime, timedelta
from pathlib import Path
from uuid import uuid4

import pytest

from app.recruiting.storage import FileObjectStorage, StorageError


def test_storage_rejects_traversal_and_symlink_escape(tmp_path: Path) -> None:
    storage = FileObjectStorage(tmp_path / "objects")
    with pytest.raises(StorageError):
        storage.put("../outside.png", b"private")
    outside = tmp_path / "outside"
    outside.mkdir()
    storage.root.mkdir()
    (storage.root / "avatars").symlink_to(outside, target_is_directory=True)
    with pytest.raises(StorageError):
        storage.put(f"avatars/{uuid4()}/{'a' * 64}.png", b"private")
    assert list(outside.iterdir()) == []


def test_orphan_cleanup_preserves_referenced_and_inflight_uploads(tmp_path: Path) -> None:
    storage = FileObjectStorage(tmp_path)
    retained, inflight, orphan = [f"avatars/{uuid4()}/{'a' * 64}.png" for _ in range(3)]
    old = datetime.now(UTC) - timedelta(days=2)
    for key in (retained, inflight, orphan):
        storage.put(key, b"image")
    for key in (retained, orphan):
        os.utime(storage.path(key), (old.timestamp(), old.timestamp()))
    assert storage.purge_orphans({retained}, datetime.now(UTC) - timedelta(days=1)) == 1
    assert storage.get(retained) == b"image"
    assert storage.get(inflight) == b"image"
    assert not storage.path(orphan).exists()
