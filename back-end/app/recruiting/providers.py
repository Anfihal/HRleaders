"""Explicit deterministic demo implementations, never passed off as production AI."""

from typing import Any

from app.recruiting.domain import Interview, weighted_score
from app.shared.errors import ExternalServiceError


class MockLLMProvider:
    def next_question(self, session: Interview, answer: str) -> str:
        index = session.question_index + 1
        return (
            session.questions[index]
            if index < len(session.questions)
            else "Вопросы закончились. Можно завершить интервью."
        )

    def evaluate(
        self, session: Interview, *, context: dict[str, Any] | None = None
    ) -> dict[str, Any]:
        answers = [m["text"] for m in session.transcript if m["role"] == "candidate"]
        # Demo evaluates completion only. It makes no claim about candidate competence.
        coverage = round(len(answers) / len(session.questions) * 100)
        criteria = [
            {**c, "score": coverage, "evidence": "Demo: доля отвеченных вопросов, не оценка навыка"}
            for c in session.snapshot["scenario"]["criteria"]
        ]
        return {
            "demo": True,
            "overall_score": weighted_score(criteria),
            "criteria": criteria,
            "summary": (
                f"Демонстрационное интервью: ответов {len(answers)} из {len(session.questions)}."
            ),
            "strengths": ["Кандидат предоставил ответы"] if answers else [],
            "concerns": ["Demo не оценивает квалификацию. Нужна проверка HR."],
            "red_flags": [],
            "recommendations": ["Проверить примеры и навыки на интервью с человеком"],
            "unanswered_questions": session.questions[session.question_index :],
        }


class MockVoiceProvider:
    def capabilities(self) -> dict[str, Any]:
        return {"demo": True, "tts": "browser", "stt": "manual_transcript", "recording": False}


class MockAvatarProvider:
    def generate(self, source: bytes, options: dict[str, Any]) -> dict[str, Any]:
        return {"demo": True, "rendering": "source_photo", "animation": False, "provider": "demo"}


class MockVideoProvider:
    def prepare(self, options: dict[str, Any]) -> dict[str, Any]:
        return {
            "demo": True,
            "transport": "local_camera",
            "remote_stream": False,
            "recording": False,
        }


def require_demo(configuration: dict[str, Any], kind: str) -> None:
    if configuration[kind]["provider"] != "demo":
        raise ExternalServiceError(
            f"Провайдер {kind} отключён. Подключите адаптер или выберите demo."
        )
