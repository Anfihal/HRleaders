"""Integration fixtures: a real database migrated with Alembic and the HTTP app.

Uses `TEST_DATABASE_URL` when set (CI runs PostgreSQL), otherwise a temporary SQLite file.
"""

import os
from collections.abc import Callable, Iterator
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import delete

from app.config import Settings
from app.fsp.gateway import FspGateway, InMemoryFspGateway
from app.main import create_app
from app.shared.database import Base, Database
from app.talent.dependencies import get_fsp_gateway
from mock_fsp.fixtures import load_participants

BACKEND_ROOT = Path(__file__).resolve().parents[2]
# Filled by migration 0002 and kept between tests.
REFERENCE_TABLES = {"fsp_disciplines", "scoring_rules", "verification_levels"}

pytestmark = pytest.mark.integration


def alembic_config(url: str) -> Config:
    config = Config(str(BACKEND_ROOT / "alembic.ini"))
    config.set_main_option("sqlalchemy.url", url.replace("%", "%%"))
    config.attributes["configure_logger"] = False
    return config


@pytest.fixture(scope="session")
def database_url(tmp_path_factory: pytest.TempPathFactory) -> str:
    return os.environ.get("TEST_DATABASE_URL") or (
        f"sqlite:///{tmp_path_factory.mktemp('db') / 'test.db'}"
    )


@pytest.fixture(scope="session")
def database(database_url: str) -> Iterator[Database]:
    config = alembic_config(database_url)
    command.downgrade(config, "base")  # start clean even if a previous run crashed
    command.upgrade(config, "head")
    db = Database(database_url)
    yield db
    db.engine.dispose()
    command.downgrade(config, "base")


@pytest.fixture(autouse=True)
def _clean_tables(request: pytest.FixtureRequest) -> Iterator[None]:
    yield
    if "database" not in request.fixturenames:
        return
    db: Database = request.getfixturevalue("database")
    with db.engine.begin() as connection:
        for table in reversed(Base.metadata.sorted_tables):
            if table.name not in REFERENCE_TABLES:
                connection.execute(delete(table))


@pytest.fixture
def fsp_gateway() -> FspGateway:
    return InMemoryFspGateway.from_payloads(load_participants())


@pytest.fixture
def settings(make_settings: Callable[..., Settings], database_url: str, tmp_path: Path) -> Settings:
    return make_settings(
        database_url=database_url, media_storage_path=tmp_path / "media", job_retry_seconds=0
    )


@pytest.fixture
def app(settings: Settings, database: Database, fsp_gateway: FspGateway) -> FastAPI:
    application = create_app(settings, database)
    application.dependency_overrides[get_fsp_gateway] = lambda: fsp_gateway
    return application


@pytest.fixture
def client_factory(app: FastAPI) -> Callable[[], TestClient]:
    """Each client has its own cookie jar, i.e. its own logged-in user."""
    return lambda: TestClient(app, raise_server_exceptions=False)


@pytest.fixture
def client(client_factory: Callable[[], TestClient]) -> TestClient:
    return client_factory()


@pytest.fixture
def drain_jobs(app: FastAPI, database: Database, settings: Settings) -> Callable[[], int]:
    """Run the actual worker against committed jobs; no HTTP background execution."""
    from app.recruiting.dependencies import get_avatar_provider, get_llm_provider
    from app.recruiting.storage import FileObjectStorage
    from app.recruiting.worker import JobWorker

    def drain() -> int:
        avatar = app.dependency_overrides.get(get_avatar_provider, get_avatar_provider)()
        llm = app.dependency_overrides.get(get_llm_provider, get_llm_provider)()
        worker = JobWorker(
            database, settings, FileObjectStorage(settings.media_storage_path), llm, avatar
        )
        for count in range(20):
            if not worker.run_one():
                return count
        raise AssertionError("Worker did not finish within 20 bounded attempts")

    return drain
