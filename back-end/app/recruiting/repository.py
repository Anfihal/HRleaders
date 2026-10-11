"""SQLAlchemy adapters; row locks serialize interview mutations on PostgreSQL."""

import logging
from hashlib import sha256
from typing import Any
from uuid import UUID

from sqlalchemy import event, select
from sqlalchemy.orm import Session

from app.recruiting.orm import MediaObjectRecord, RecruitingEntityRecord
from app.recruiting.ports import StorageProvider
from app.shared.database import utc_now
from app.shared.errors import NotFoundError

logger = logging.getLogger(__name__)


def discard_uploaded_objects(session: Session) -> None:
    for storage, key in session.info.pop("recruiting_new_objects", []):
        try:
            storage.delete(key)
        except Exception:
            logger.error("media_rollback_cleanup_failed; run recruiting cleanup")


def commit_media_changes(session: Session) -> None:
    session.info.pop("recruiting_new_objects", None)
    for storage, key in session.info.pop("recruiting_deleted_objects", []):
        try:
            storage.delete(key)
        except Exception:
            logger.error("media_commit_cleanup_failed; run recruiting cleanup")


@event.listens_for(Session, "after_rollback")
def rollback_media_changes(session: Session) -> None:
    discard_uploaded_objects(session)
    session.info.pop("recruiting_deleted_objects", None)


event.listen(Session, "after_commit", commit_media_changes)


class SqlAlchemyRecruitingRepository:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list(self, kind: str, owner_id: UUID) -> list[dict[str, Any]]:
        rows = self.session.scalars(
            select(RecruitingEntityRecord)
            .where(
                RecruitingEntityRecord.owner_id == owner_id,
                RecruitingEntityRecord.kind == kind,
            )
            .order_by(RecruitingEntityRecord.created_at.desc())
        )
        return [self.serialize(row) for row in rows]

    def get(self, kind: str, entity_id: UUID, owner_id: UUID) -> dict[str, Any]:
        row = self.session.scalar(
            select(RecruitingEntityRecord)
            .where(
                RecruitingEntityRecord.id == entity_id,
                RecruitingEntityRecord.owner_id == owner_id,
                RecruitingEntityRecord.kind == kind,
            )
            .with_for_update()
        )
        if row is None:
            raise NotFoundError("Объект не найден")
        return self.serialize(row)

    def save(
        self, kind: str, entity_id: UUID, owner_id: UUID, data: dict[str, Any]
    ) -> dict[str, Any]:
        row = self.session.get(RecruitingEntityRecord, entity_id)
        now = utc_now()
        cleaned = {k: v for k, v in data.items() if k not in {"id", "created_at", "updated_at"}}
        if row is None:
            row = RecruitingEntityRecord(
                id=entity_id,
                owner_id=owner_id,
                kind=kind,
                data=cleaned,
                created_at=now,
                updated_at=now,
            )
            self.session.add(row)
        else:
            if row.owner_id != owner_id or row.kind != kind:
                raise NotFoundError("Объект не найден")
            row.data, row.updated_at = cleaned, now
        self.session.flush()
        return self.serialize(row)

    @staticmethod
    def serialize(row: RecruitingEntityRecord) -> dict[str, Any]:
        return {
            **row.data,
            "id": str(row.id),
            "created_at": row.created_at.isoformat(),
            "updated_at": row.updated_at.isoformat(),
        }


class SqlAlchemyRecruitingDirectory:
    def __init__(self, session: Session, storage: StorageProvider) -> None:
        self.session, self.storage = session, storage

    def context(self, owner_id: UUID, vacancy_id: UUID, candidate_id: UUID) -> dict[str, Any]:
        from app.hiring.orm import VacancyRecord
        from app.shared.errors import DomainValidationError
        from app.talent.orm import CandidateProfileRecord

        vacancy = self.session.get(VacancyRecord, vacancy_id)
        candidate = self.session.get(CandidateProfileRecord, candidate_id)
        if vacancy is None or vacancy.employer_id != owner_id or candidate is None:
            raise NotFoundError("Вакансия или кандидат не найдены")
        if not vacancy.is_open:
            raise DomainValidationError("Вакансия закрыта")
        return {
            "vacancy": {
                "id": str(vacancy_id),
                "title": vacancy.title,
                "description": vacancy.description,
                "skills": vacancy.skills,
            },
            "candidate": {
                "id": str(candidate_id),
                "name": candidate.full_name,
                "headline": candidate.headline,
                "skills": [s.name for s in candidate.skills],
            },
        }

    def participant_owner(self, interview_id: UUID, user_id: UUID) -> UUID:
        from app.recruiting.orm import InterviewLinkRecord
        from app.talent.orm import CandidateProfileRecord

        owner = self.session.scalar(
            select(RecruitingEntityRecord.owner_id)
            .join(
                InterviewLinkRecord,
                InterviewLinkRecord.interview_id == RecruitingEntityRecord.id,
            )
            .join(
                CandidateProfileRecord,
                CandidateProfileRecord.id == InterviewLinkRecord.candidate_id,
            )
            .where(
                RecruitingEntityRecord.id == interview_id,
                CandidateProfileRecord.user_id == user_id,
            )
        )
        if owner is None:
            raise NotFoundError("Интервью не найдено")
        return owner

    def link(
        self, interview_id: UUID, vacancy_id: UUID, candidate_id: UUID, scenario_id: UUID
    ) -> None:
        from app.recruiting.orm import InterviewLinkRecord

        self.session.add(
            InterviewLinkRecord(
                interview_id=interview_id,
                vacancy_id=vacancy_id,
                candidate_id=candidate_id,
                scenario_id=scenario_id,
            )
        )
        self.session.flush()

    def image(self, avatar_id: UUID) -> bytes:
        from app.recruiting.orm import AvatarImageRecord

        media = self.session.get(MediaObjectRecord, avatar_id)
        if media is not None:
            return self.storage.get(media.storage_key)
        record = self.session.get(AvatarImageRecord, avatar_id)
        if record is None:
            raise NotFoundError("Изображение удалено")
        return record.content

    def save_image(self, avatar_id: UUID, content: bytes) -> None:
        checksum = sha256(content).hexdigest()
        key = f"avatars/{avatar_id}/{checksum}.png"
        self.storage.put(key, content)
        self.session.info.setdefault("recruiting_new_objects", []).append((self.storage, key))
        self.session.add(
            MediaObjectRecord(
                avatar_id=avatar_id,
                storage_key=key,
                mime_type="image/png",
                size=len(content),
                checksum=checksum,
                created_at=utc_now(),
                retention_until=None,
            )
        )
        self.session.flush()

    def delete_image(self, avatar_id: UUID) -> None:
        from app.recruiting.orm import AvatarImageRecord

        media = self.session.get(MediaObjectRecord, avatar_id)
        if media is not None:
            self.session.info.setdefault("recruiting_deleted_objects", []).append(
                (self.storage, media.storage_key)
            )
            self.session.delete(media)
        row = self.session.get(AvatarImageRecord, avatar_id)
        if row is not None:
            self.session.delete(row)
