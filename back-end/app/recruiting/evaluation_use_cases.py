"""Provider evaluation and validation, independent of HTTP/job transport."""

from typing import Any

from pydantic import ValidationError

from app.recruiting.interview_use_cases import InterviewService
from app.recruiting.ports import LLMProvider
from app.recruiting.providers import require_demo
from app.recruiting.schemas import Evaluation
from app.shared.errors import ExternalServiceError


class EvaluationService:
    def __init__(self, llm: LLMProvider) -> None:
        self.llm = llm

    def generate(self, data: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        interview = InterviewService.hydrate(data)
        require_demo(interview.snapshot["configuration"], "ai")
        try:
            evaluation = Evaluation.model_validate(self.llm.evaluate(interview, context=context))
        except ValidationError as error:
            raise ExternalServiceError("Провайдер вернул некорректную evaluation") from error
        expected = interview.snapshot["scenario"]["criteria"]
        actual = [{"name": c.name, "weight": c.weight} for c in evaluation.criteria]
        if actual != expected:
            raise ExternalServiceError("Критерии evaluation не соответствуют сценарию")
        return {
            **evaluation.model_dump(mode="json"),
            "duration": data.get("duration_seconds", 0),
            "metadata": {"provider": "demo", **context},
        }
