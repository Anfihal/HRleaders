"""Russian messages for request validation errors: the UI shows them next to the field as is."""

from collections.abc import Callable, Mapping
from typing import Any

from pydantic_core import ErrorDetails

Formatter = Callable[[Mapping[str, Any]], str]


def _genitive(count: int, singular: str, plural: str) -> str:
    """Comparatives take the genitive: "не длиннее 21 символа", "не больше 2 элементов"."""
    return singular if count % 10 == 1 and count % 100 != 11 else plural


def _chars(count: int) -> str:
    return f"{count} {_genitive(count, 'символа', 'символов')}"


def _items(count: int) -> str:
    return f"{count} {_genitive(count, 'элемента', 'элементов')}"


MESSAGES: dict[str, Formatter] = {
    "missing": lambda _: "Обязательное поле",
    "string_too_short": lambda ctx: (
        "Обязательное поле" if ctx["min_length"] == 1 else f"Не короче {_chars(ctx['min_length'])}"
    ),
    "string_too_long": lambda ctx: f"Не длиннее {_chars(ctx['max_length'])}",
    "too_short": lambda ctx: f"Не меньше {_items(ctx['min_length'])}",
    "too_long": lambda ctx: f"Не больше {_items(ctx['max_length'])}",
    "greater_than": lambda ctx: f"Должно быть больше {ctx['gt']}",
    "greater_than_equal": lambda ctx: f"Должно быть не меньше {ctx['ge']}",
    "less_than": lambda ctx: f"Должно быть меньше {ctx['lt']}",
    "less_than_equal": lambda ctx: f"Должно быть не больше {ctx['le']}",
    "string_type": lambda _: "Ожидается строка",
    "int_type": lambda _: "Ожидается целое число",
    "int_parsing": lambda _: "Ожидается целое число",
    "int_from_float": lambda _: "Ожидается целое число",
    "bool_type": lambda _: "Ожидается да или нет",
    "bool_parsing": lambda _: "Ожидается да или нет",
    "list_type": lambda _: "Ожидается список",
    "uuid_parsing": lambda _: "Некорректный идентификатор",
    "uuid_type": lambda _: "Некорректный идентификатор",
    "enum": lambda _: "Недопустимое значение",
    "literal_error": lambda _: "Недопустимое значение",
    "json_invalid": lambda _: "Некорректный JSON",
    "model_attributes_type": lambda _: "Ожидается объект",
    "dict_type": lambda _: "Ожидается объект",
}

EMAIL_ERROR_PREFIX = "value is not a valid email address"


def validation_message(error: ErrorDetails) -> str:
    """Translate one pydantic error; unknown types keep pydantic's own message."""
    if error["type"] == "value_error" and error["msg"].startswith(EMAIL_ERROR_PREFIX):
        return "Некорректный email"
    formatter = MESSAGES.get(error["type"])
    if formatter is None:
        return error["msg"]
    return formatter(error.get("ctx") or {})
