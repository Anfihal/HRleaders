"""Migrations are versioned, reversible and match the ORM models."""

from pathlib import Path

import pytest
from alembic import command
from alembic.script import ScriptDirectory
from sqlalchemy import create_engine, func, inspect, select, text

from app.shared.database import Base
from app.talent.orm import FspDisciplineRecord, ScoringRuleRecord, VerificationLevelRecord
from tests.integration.conftest import alembic_config

pytestmark = pytest.mark.integration


@pytest.fixture
def fresh_url(tmp_path: Path) -> str:
    return f"sqlite:///{tmp_path / 'migrations.db'}"


def tables(url: str) -> set[str]:
    engine = create_engine(url)
    try:
        return set(inspect(engine).get_table_names())
    finally:
        engine.dispose()


def test_history_is_linear() -> None:
    script = ScriptDirectory.from_config(alembic_config("sqlite://"))
    assert [rev.revision for rev in script.walk_revisions()] == ["0004", "0003", "0002", "0001"]
    assert len(script.get_heads()) == 1


def test_upgrade_downgrade_roundtrip(fresh_url: str) -> None:
    config = alembic_config(fresh_url)
    command.upgrade(config, "head")
    assert {
        "users",
        "candidate_profiles",
        "fsp_achievements",
        "candidate_discipline_scores",
        "vacancies",
        "offers",
        "profile_views",
    } <= tables(fresh_url)

    engine = create_engine(fresh_url)
    with engine.connect() as connection:

        def count(model: type[Base]) -> int | None:
            return connection.scalar(select(func.count()).select_from(model))

        assert count(FspDisciplineRecord) == 5
        assert count(VerificationLevelRecord) == 4
        assert count(ScoringRuleRecord) == 4 + 3 + 5
    engine.dispose()

    command.check(config)  # models and migrations do not drift

    command.downgrade(config, "0001")
    engine = create_engine(fresh_url)
    with engine.connect() as connection:
        assert connection.scalar(text("SELECT count(*) FROM fsp_disciplines")) == 0
    engine.dispose()

    command.downgrade(config, "base")
    assert tables(fresh_url) == {"alembic_version"}

    command.upgrade(config, "head")
    assert "offers" in tables(fresh_url)
