"""SQLAlchemy implementation of `UserRepository`."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.identity.domain import Role, User
from app.identity.orm import UserRecord


class SqlAlchemyUserRepository:
    def __init__(self, session: Session) -> None:
        self._session = session

    def get(self, user_id: UUID) -> User | None:
        record = self._session.get(UserRecord, user_id)
        return _to_domain(record) if record else None

    def get_by_email(self, email: str) -> User | None:
        record = self._session.scalar(select(UserRecord).where(UserRecord.email == email))
        return _to_domain(record) if record else None

    def add(self, user: User) -> None:
        self._session.add(
            UserRecord(
                id=user.id,
                email=user.email,
                full_name=user.full_name,
                role=user.role.value,
                password_hash=user.password_hash,
                company_name=user.company_name,
                created_at=user.created_at,
            ),
        )
        self._session.flush()


def _to_domain(record: UserRecord) -> User:
    return User(
        id=record.id,
        email=record.email,
        full_name=record.full_name,
        role=Role(record.role),
        password_hash=record.password_hash,
        company_name=record.company_name,
        created_at=record.created_at,
    )
