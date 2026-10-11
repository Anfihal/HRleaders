"""Reference data: FSP disciplines, categorization weights and verification levels.

Weights live in the database (not in code) so product can tune categorization (H1/H2)
with a new migration and without a release of the application.

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-04 22:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

# (code, label used by FSP, platform label) — the five official FSP disciplines.
DISCIPLINES = [
    ("algorithmic", "Программирование алгоритмическое", "Алгоритмическое программирование"),
    ("product", "Программирование продуктовое", "Продуктовое программирование"),
    (
        "security",
        "Программирование систем информационной безопасности",
        "Информационная безопасность",
    ),
    ("robotics", "Программирование робототехники", "Робототехника"),
    (
        "uav",
        "Программирование беспилотных авиационных систем",
        "Беспилотные авиационные системы",
    ),
]

# (rule_type, code, label used by FSP, platform label, value)
SCORING_RULES = [
    ("result", "winner", "Победитель", "Победитель", 30.0),
    ("result", "prize_winner", "Призёр", "Призёр", 20.0),
    ("result", "finalist", "Финалист", "Финалист", 10.0),
    ("result", "participant", "Участник", "Участник", 3.0),
    ("competition_level", "regional", "Региональный", "Региональные соревнования", 1.0),
    ("competition_level", "national", "Всероссийский", "Всероссийские соревнования", 1.5),
    ("competition_level", "international", "Международный", "Международные соревнования", 2.0),
    ("sport_rank", "ms", "Мастер спорта", "Мастер спорта (МС)", 30.0),
    ("sport_rank", "kms", "Кандидат в мастера спорта", "Кандидат в мастера спорта (КМС)", 20.0),
    ("sport_rank", "first", "I спортивный разряд", "I спортивный разряд", 10.0),
    ("sport_rank", "second", "II спортивный разряд", "II спортивный разряд", 6.0),
    ("sport_rank", "third", "III спортивный разряд", "III спортивный разряд", 3.0),
]

LEVELS = [
    ("none", "Не подтверждён", 0.0),
    ("basic", "Базовый", 10.0),
    ("advanced", "Продвинутый", 40.0),
    ("expert", "Эксперт", 90.0),
]

disciplines_table = sa.table(
    "fsp_disciplines",
    sa.column("code", sa.String),
    sa.column("fsp_label", sa.String),
    sa.column("label", sa.String),
    sa.column("sort_order", sa.Integer),
)
scoring_rules_table = sa.table(
    "scoring_rules",
    sa.column("rule_type", sa.String),
    sa.column("code", sa.String),
    sa.column("fsp_label", sa.String),
    sa.column("label", sa.String),
    sa.column("value", sa.Float),
    sa.column("sort_order", sa.Integer),
)
levels_table = sa.table(
    "verification_levels",
    sa.column("code", sa.String),
    sa.column("label", sa.String),
    sa.column("min_score", sa.Float),
)


def upgrade() -> None:
    op.bulk_insert(
        disciplines_table,
        [
            {"code": code, "fsp_label": fsp_label, "label": label, "sort_order": index}
            for index, (code, fsp_label, label) in enumerate(DISCIPLINES)
        ],
    )
    op.bulk_insert(
        scoring_rules_table,
        [
            {
                "rule_type": rule_type,
                "code": code,
                "fsp_label": fsp_label,
                "label": label,
                "value": value,
                "sort_order": index,
            }
            for index, (rule_type, code, fsp_label, label, value) in enumerate(SCORING_RULES)
        ],
    )
    op.bulk_insert(
        levels_table,
        [{"code": code, "label": label, "min_score": score} for code, label, score in LEVELS],
    )


def downgrade() -> None:
    op.execute(levels_table.delete())
    op.execute(scoring_rules_table.delete())
    op.execute(disciplines_table.delete())
