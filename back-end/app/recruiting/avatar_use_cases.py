"""Private photo and retryable avatar generation workflow."""

from typing import Any
from uuid import UUID, uuid4

from app.recruiting.domain import TERMINAL_INTERVIEWS, ConsentRequiredError
from app.recruiting.media import validate_photo
from app.recruiting.ports import RecruitingDirectory, RecruitingRepository, WorkflowJournal
from app.recruiting.providers import require_demo
from app.recruiting.schemas import AvatarInput, AvatarUpdate
from app.shared.errors import ConflictError


class AvatarService:
    def __init__(
        self,
        repo: RecruitingRepository,
        directory: RecruitingDirectory,
        journal: WorkflowJournal,
        max_bytes: int,
        max_pixels: int,
    ) -> None:
        self.repo, self.directory, self.journal = repo, directory, journal
        self.max_bytes, self.max_pixels = max_bytes, max_pixels

    def create(self, owner: UUID, spec: AvatarInput) -> dict[str, Any]:
        if not spec.consent:
            raise ConsentRequiredError("Подтвердите право использовать фотографию")
        image = validate_photo(spec.image_base64, self.max_bytes, self.max_pixels)
        entity_id = uuid4()
        data = spec.model_dump(mode="json", exclude={"image_base64"})
        avatar = self.repo.save(
            "avatar",
            entity_id,
            owner,
            {**data, "status": "draft", "demo": True, "error": None, "metadata": {}},
        )
        self.directory.save_image(entity_id, image)
        return avatar

    def generate(self, owner: UUID, entity_id: UUID, config: dict[str, Any]) -> dict[str, Any]:
        data = self.repo.get("avatar", entity_id, owner)
        if data["status"] in {"processing", "ready"}:
            return data
        if data["status"] not in {"draft", "failed"}:
            raise ConflictError("Генерацию нельзя запустить в этом состоянии")
        require_demo(config, "avatar")
        data.update(status="processing", error=None, generation_config=config["avatar"])
        self.repo.save("avatar", entity_id, owner, data)
        job_id = self.journal.enqueue(
            "avatar.generate", entity_id, owner, config["avatar"]["retries"] + 1
        )
        data["generation_job_id"] = str(job_id)
        return self.repo.save("avatar", entity_id, owner, data)

    def refresh(self, owner: UUID, entity_id: UUID) -> dict[str, Any]:
        return self.repo.get("avatar", entity_id, owner)

    def update(self, owner: UUID, entity_id: UUID, spec: AvatarUpdate) -> dict[str, Any]:
        data = self.repo.get("avatar", entity_id, owner)
        return self.repo.save("avatar", entity_id, owner, {**data, **spec.model_dump(mode="json")})

    def archive(self, owner: UUID, entity_id: UUID) -> dict[str, Any]:
        data = self.repo.get("avatar", entity_id, owner)
        for interview in self.repo.list("interview", owner):
            avatar = interview["snapshot"].get("avatar")
            if (
                interview["status"] not in TERMINAL_INTERVIEWS
                and avatar
                and avatar["id"] == str(entity_id)
            ):
                raise ConflictError("Аватар используется в незавершённом интервью")
        data["status"] = "archived"
        self.journal.emit("avatar.archived", entity_id, owner, {"status": "archived"})
        self.directory.delete_image(entity_id)
        return self.repo.save("avatar", entity_id, owner, data)
