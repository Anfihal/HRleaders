"""Database infrastructure shared by all bounded contexts."""

from collections.abc import Iterator
from datetime import UTC, datetime
from typing import Annotated, Any

from fastapi import Depends, Request
from sqlalchemy import DateTime, Dialect, MetaData, create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.types import TypeDecorator

NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_N_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    metadata = MetaData(naming_convention=NAMING_CONVENTION)


class UtcDateTime(TypeDecorator[datetime]):
    """Timezone-aware UTC timestamps on every backend (SQLite drops tzinfo)."""

    impl = DateTime(timezone=True)
    cache_ok = True

    def process_bind_param(self, value: datetime | None, dialect: Dialect) -> datetime | None:
        if value is None:
            return None
        if value.tzinfo is None:
            raise ValueError("Naive datetimes are not allowed; use timezone-aware UTC values")
        return value.astimezone(UTC)

    def process_result_value(self, value: datetime | None, dialect: Dialect) -> datetime | None:
        if value is None:
            return None
        return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


def utc_now() -> datetime:
    return datetime.now(UTC)


class Database:
    """Owns the engine and the session factory for one application instance."""

    def __init__(self, url: str, **engine_options: Any) -> None:
        self.engine: Engine = create_engine(url, pool_pre_ping=True, **engine_options)
        self.session_factory = sessionmaker(bind=self.engine, expire_on_commit=False)

    def session_scope(self) -> Iterator[Session]:
        """Unit of work: commit on success, roll back on any error."""
        session = self.session_factory()
        try:
            yield session
            session.commit()
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()


def get_session(request: Request) -> Iterator[Session]:
    database: Database = request.app.state.database
    yield from database.session_scope()


# Finish the unit of work before sending success or accepting a dependent request.
DatabaseSession = Annotated[Session, Depends(get_session, scope="function")]
