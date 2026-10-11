"""Lifecycle and weighted score checks independent of HTTP/database/providers."""

from datetime import UTC, datetime
from typing import Any

import pytest

from app.recruiting.domain import (
    ConsentRequiredError,
    Interview,
    InterviewSession,
    InterviewStatus,
    InterviewTransitionError,
    SessionStatus,
    weighted_score,
)
from app.recruiting.providers import MockLLMProvider
from app.recruiting.schemas import ScenarioInput
from app.shared.errors import DomainValidationError

NOW = datetime(2026, 10, 5, tzinfo=UTC)


def session() -> Interview:
    return Interview(
        snapshot={
            "scenario": {
                "greeting": "Привет",
                "questions": ["Проект?", "Результат?"],
                "closing": "Спасибо",
                "criteria": [{"name": "Опыт", "weight": 100}],
            }
        }
    )


def test_consent_and_lifecycle() -> None:
    interview = session()
    with pytest.raises(ConsentRequiredError):
        interview.start(False, NOW)
    with pytest.raises(InterviewTransitionError):
        interview.answer("Ответ", "Вопрос", NOW)
    interview.start(True, NOW)
    with pytest.raises(InterviewTransitionError):
        interview.start(True, NOW)
    provider = MockLLMProvider()
    interview.answer("Построил сервис", provider.next_question(interview, "Построил сервис"), NOW)
    result = provider.evaluate(interview)
    assert result["overall_score"] == 50
    assert result["unanswered_questions"] == ["Результат?"]
    interview.complete(NOW)
    assert interview.status == "completed"
    with pytest.raises(InterviewTransitionError):
        interview.answer("Ещё ответ", "", NOW)


def test_weighted_score_and_invalid_scores() -> None:
    assert weighted_score([{"weight": 80, "score": 90}, {"weight": 20, "score": 40}]) == 80
    for criteria in [[{"weight": 10, "score": 1}], [{"weight": 100, "score": 101}]]:
        with pytest.raises(DomainValidationError):
            weighted_score(criteria)


@pytest.mark.parametrize("status", [InterviewStatus.CREATED, InterviewStatus.SCHEDULED])
def test_legacy_and_new_interviews_start_through_the_same_workflow(status: str) -> None:
    interview = session()
    interview.status = status
    interview.start(True, NOW)
    assert interview.status == InterviewStatus.ACTIVE


def test_failed_and_cancelled_interviews_cannot_accept_answers_or_restart() -> None:
    interview = session()
    interview.start(True, NOW)
    interview.transition(InterviewStatus.FAILED)
    with pytest.raises(InterviewTransitionError):
        interview.complete(NOW)
    interview.cancel(NOW)
    assert interview.status == InterviewStatus.CANCELLED
    with pytest.raises(InterviewTransitionError):
        interview.start(True, NOW)
    with pytest.raises(InterviewTransitionError):
        interview.answer("late", "", NOW)


def test_runtime_state_is_independent_and_terminal() -> None:
    runtime = InterviewSession("session", "interview", "candidate", "scenario", "video")
    with pytest.raises(InterviewTransitionError):
        runtime.transition(SessionStatus.AI_SPEAKING)
    runtime.transition(SessionStatus.CONNECTING)
    runtime.transition(SessionStatus.ERROR)
    runtime.transition(SessionStatus.RECONNECTING)
    runtime.transition(SessionStatus.CANDIDATE_SPEAKING)
    runtime.transition(SessionStatus.AI_THINKING)
    runtime.transition(SessionStatus.AI_SPEAKING)
    runtime.transition(SessionStatus.COMPLETED)
    with pytest.raises(InterviewTransitionError):
        runtime.transition(SessionStatus.CANDIDATE_SPEAKING)


@pytest.mark.parametrize(
    "changes", [{"name": " "}, {"questions": [" "]}, {"criteria": [{"name": "Опыт", "weight": 50}]}]
)
def test_scenario_validation(changes: dict[str, Any]) -> None:
    with pytest.raises(ValueError):
        ScenarioInput.model_validate(
            {
                "name": "Screening",
                "questions": ["Опыт?"],
                "criteria": [{"name": "Опыт", "weight": 100}],
                **changes,
            }
        )
