"""Validated API/configuration contracts; no provider credentials in these models."""

from typing import Literal
from urllib.parse import urlsplit
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class Criterion(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    weight: int = Field(gt=0, le=100)


class ProviderConfiguration(BaseModel):
    provider: Literal["demo", "disabled"] = "demo"
    endpoint: str = Field(default="", max_length=2048)
    model: str = Field(default="", max_length=200)
    secret_ref: str = Field(default="", max_length=100, pattern=r"^[A-Za-z0-9_-]*$")
    temperature: float = Field(default=0.3, ge=0, le=2)
    timeout_seconds: int = Field(default=30, ge=1, le=120)
    retries: int = Field(default=1, ge=0, le=3)
    max_tokens: int = Field(default=2000, ge=100, le=16000)

    @field_validator("endpoint")
    @classmethod
    def validate_endpoint(cls, value: str) -> str:
        if value:
            parsed = urlsplit(value)
            if (
                parsed.scheme != "https"
                or not parsed.hostname
                or parsed.username
                or parsed.password
                or parsed.query
                or parsed.fragment
            ):
                raise ValueError("HTTPS endpoint без credentials, query и fragment")
        return value


class VoiceConfiguration(ProviderConfiguration):
    voice: str = Field(default="", max_length=200)
    language: str = Field(default="ru-RU", min_length=2, max_length=30)
    speed: float = Field(default=1, ge=0.5, le=2)
    pitch: float = Field(default=1, ge=0, le=2)
    fallback: Literal["text"] = "text"


class VideoConfiguration(ProviderConfiguration):
    quality: Literal["standard", "high"] = "standard"
    width: int = Field(default=1280, ge=320, le=1920)
    height: int = Field(default=720, ge=240, le=1080)
    reconnect_attempts: int = Field(default=3, ge=0, le=10)
    recording: Literal[False] = False
    fallback: Literal["text"] = "text"


class AvatarConfiguration(ProviderConfiguration):
    default_avatar_id: UUID | None = None
    visual_style: str = Field(default="Профессиональный", max_length=120)
    behavior: str = Field(default="Спокойный", max_length=120)


class SecurityConfiguration(BaseModel):
    consent_required: Literal[True] = True
    retention_days: int = Field(default=30, ge=1, le=365)
    privacy_notice: str = Field(
        default=(
            "Ответы сохраняются для оценки интервью. "
            "Камера и микрофон в demo работают локально; запись не ведётся."
        ),
        min_length=1,
        max_length=4000,
    )
    storage: Literal["private_database", "private_object_storage"] = "private_object_storage"


class Configuration(BaseModel):
    ai: ProviderConfiguration = Field(default_factory=ProviderConfiguration)
    voice: VoiceConfiguration = Field(default_factory=VoiceConfiguration)
    video: VideoConfiguration = Field(default_factory=VideoConfiguration)
    avatar: AvatarConfiguration = Field(default_factory=AvatarConfiguration)
    security: SecurityConfiguration = Field(default_factory=SecurityConfiguration)
    default_scenario_id: UUID | None = None


class ScenarioInput(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    name: str = Field(min_length=1, max_length=200)
    description: str = Field(default="", max_length=4000)
    role: str = Field(default="", max_length=200)
    interview_type: str = Field(default="Скрининг", max_length=120)
    goals: str = Field(default="", max_length=4000)
    duration_minutes: int = Field(default=30, ge=1, le=180)
    language: str = Field(default="ru-RU", min_length=2, max_length=30)
    greeting: str = Field(default="Здравствуйте! Расскажите о вашем опыте.", max_length=4000)
    questions: list[str] = Field(min_length=1, max_length=30)
    follow_up: str = Field(default="", max_length=1000)
    closing: str = Field(default="Спасибо! HR ознакомится с результатами.", max_length=4000)
    criteria: list[Criterion] = Field(min_length=1, max_length=20)
    red_flags: list[str] = Field(default_factory=list, max_length=20)
    instructions: str = Field(default="", max_length=8000)
    tone: str = Field(default="Доброжелательный", max_length=120)
    model: str = Field(default="", max_length=200)
    voice: str = Field(default="", max_length=200)
    avatar_id: UUID | None = None
    status: Literal["active", "inactive", "archived"] = "active"

    @field_validator("questions", "red_flags")
    @classmethod
    def validate_lines(cls, values: list[str]) -> list[str]:
        if any(not item.strip() or len(item) > 2000 for item in values):
            raise ValueError("Каждая строка должна содержать 1–2000 символов")
        return [item.strip() for item in values]

    @model_validator(mode="after")
    def validate_weights(self) -> "ScenarioInput":
        if sum(c.weight for c in self.criteria) != 100:
            raise ValueError("Сумма весов критериев должна быть 100")
        return self


class AvatarInput(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    image_base64: str = Field(max_length=8_000_000)
    consent: bool
    voice: str = Field(default="", max_length=200)
    language: str = Field(default="ru-RU", min_length=2, max_length=30)
    visual_style: str = Field(default="Профессиональный", max_length=120)
    behavior: str = Field(default="Спокойный", max_length=120)


class AvatarUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    voice: str = Field(default="", max_length=200)
    language: str = Field(default="ru-RU", min_length=2, max_length=30)
    visual_style: str = Field(default="Профессиональный", max_length=120)
    behavior: str = Field(default="Спокойный", max_length=120)


class InterviewInput(BaseModel):
    vacancy_id: UUID
    candidate_id: UUID
    scenario_id: UUID
    format: Literal["text", "voice", "video"]
    language: str | None = Field(default=None, min_length=2, max_length=30)
    avatar_id: UUID | None = None


class StartInput(BaseModel):
    consent: bool


class AnswerInput(BaseModel):
    text: str = Field(min_length=1, max_length=12000)
    expected_revision: int | None = Field(default=None, ge=0)

    @field_validator("text")
    @classmethod
    def nonblank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("Ответ не должен быть пустым")
        return value.strip()


class EvaluationCriterion(Criterion):
    score: float = Field(ge=0, le=100)
    evidence: str = Field(min_length=1, max_length=12000)


class Evaluation(BaseModel):
    demo: bool
    overall_score: float = Field(ge=0, le=100)
    criteria: list[EvaluationCriterion] = Field(min_length=1, max_length=20)
    summary: str = Field(min_length=1, max_length=12000)
    strengths: list[str] = Field(max_length=30)
    concerns: list[str] = Field(max_length=30)
    red_flags: list[str] = Field(max_length=30)
    recommendations: list[str] = Field(max_length=30)
    unanswered_questions: list[str] = Field(max_length=30)

    @model_validator(mode="after")
    def validate_scores(self) -> "Evaluation":
        if sum(c.weight for c in self.criteria) != 100:
            raise ValueError("Сумма весов evaluation должна быть 100")
        weighted = round(sum(c.score * c.weight for c in self.criteria) / 100, 1)
        if self.overall_score != weighted:
            raise ValueError("Итоговый score не соответствует взвешенным критериям")
        return self


class AvatarGenerationResult(BaseModel):
    model_config = ConfigDict(extra="forbid")
    demo: Literal[True]
    rendering: Literal["source_photo"]
    animation: Literal[False]
    provider: Literal["demo"]
