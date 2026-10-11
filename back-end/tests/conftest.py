"""Fixtures shared by all test layers."""

from collections.abc import Callable
from datetime import UTC, datetime
from typing import Any

import pytest

from app.config import Settings
from app.talent.domain import ScoringRules, VerificationLevel

# Test-only signing key, never used outside the test process.
TEST_JWT_SECRET = "test-only-secret-key-with-more-than-32-chars"
NOW = datetime(2026, 10, 1, 12, 0, tzinfo=UTC)


@pytest.fixture
def make_settings() -> Callable[..., Settings]:
    def factory(**overrides: Any) -> Settings:
        values: dict[str, Any] = {
            "database_url": "sqlite://",
            "jwt_secret": TEST_JWT_SECRET,
            "auth_cookie_secure": False,
            "password_hash_iterations": 1_000,
            "fsp_api_url": "http://fsp.test",
            "fsp_api_token": "fsp-test-token",
        }
        values.update(overrides)
        return Settings(_env_file=None, **values)

    return factory


@pytest.fixture
def rules() -> ScoringRules:
    """Same weights as the reference data migration (0002)."""
    return ScoringRules(
        result_points={"winner": 30, "prize_winner": 20, "finalist": 10, "participant": 3},
        competition_level_multipliers={"regional": 1.0, "national": 1.5, "international": 2.0},
        sport_rank_points={"ms": 30, "kms": 20, "first": 10, "second": 6, "third": 3},
        levels=[
            VerificationLevel("expert", "Эксперт", 90),
            VerificationLevel("none", "Не подтверждён", 0),
            VerificationLevel("basic", "Базовый", 10),
            VerificationLevel("advanced", "Продвинутый", 40),
        ],
    )
