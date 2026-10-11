"""Scenario and canonical configuration application services."""

from typing import Any
from uuid import UUID, uuid4

from app.recruiting.ports import RecruitingRepository
from app.recruiting.schemas import Configuration, ScenarioInput
from app.shared.errors import DomainValidationError


class ScenarioService:
    def __init__(self, repo: RecruitingRepository) -> None:
        self.repo = repo

    def save(
        self, owner: UUID, spec: ScenarioInput, entity_id: UUID | None = None
    ) -> dict[str, Any]:
        if entity_id:
            self.repo.get("scenario", entity_id, owner)
        if spec.avatar_id:
            avatar = self.repo.get("avatar", spec.avatar_id, owner)
            if avatar["status"] != "ready":
                raise DomainValidationError("Аватар должен быть готов")
        return self.repo.save("scenario", entity_id or uuid4(), owner, spec.model_dump(mode="json"))

    def duplicate(self, owner: UUID, entity_id: UUID) -> dict[str, Any]:
        data = self.repo.get("scenario", entity_id, owner)
        return self.save(
            owner,
            ScenarioInput.model_validate(
                {**data, "name": data["name"][:190] + " (копия)", "status": "inactive"}
            ),
        )

    def archive(self, owner: UUID, entity_id: UUID) -> dict[str, Any]:
        data = self.repo.get("scenario", entity_id, owner)
        data["status"] = "archived"
        return self.repo.save("scenario", entity_id, owner, data)


class ConfigurationService:
    def __init__(self, repo: RecruitingRepository, secret_names: set[str]) -> None:
        self.repo, self.secret_names = repo, secret_names

    def get(self, owner: UUID) -> dict[str, Any]:
        rows = self.repo.list("settings", owner)
        data = Configuration.model_validate(rows[0] if rows else {}).model_dump(mode="json")
        for key in ("ai", "voice", "video", "avatar"):
            ref = data[key]["secret_ref"]
            data[key]["secret_configured"] = ref in self.secret_names
            data[key]["secret_mask"] = "••••••••" if ref in self.secret_names else ""
        data["security"]["storage"] = "private_object_storage"
        return data

    def save(self, owner: UUID, spec: Configuration) -> dict[str, Any]:
        for provider in (spec.ai, spec.voice, spec.video, spec.avatar):
            if provider.secret_ref and provider.secret_ref not in self.secret_names:
                raise DomainValidationError("Ссылка на секрет не настроена на сервере")
        if spec.default_scenario_id:
            scenario = self.repo.get("scenario", spec.default_scenario_id, owner)
            if scenario["status"] != "active":
                raise DomainValidationError("Default-сценарий должен быть активен")
        if spec.avatar.default_avatar_id:
            avatar = self.repo.get("avatar", spec.avatar.default_avatar_id, owner)
            if avatar["status"] != "ready":
                raise DomainValidationError("Default-аватар должен быть готов")
        rows = self.repo.list("settings", owner)
        self.repo.save(
            "settings", UUID(rows[0]["id"]) if rows else owner, owner, spec.model_dump(mode="json")
        )
        return self.get(owner)
