from typing import Annotated

import pytest
from pydantic import BaseModel, EmailStr, Field, ValidationError

from app.shared.validation_messages import validation_message


class Form(BaseModel):
    email: EmailStr
    message: Annotated[str, Field(min_length=10, max_length=21)]
    reason: Annotated[str, Field(min_length=1)]
    salary: Annotated[int, Field(gt=0)]
    skills: Annotated[list[str], Field(max_length=2)]


VALID = {
    "email": "dev@mail.example",
    "message": "Здравствуйте, Илья",
    "reason": "Далеко ехать",
    "salary": 250_000,
    "skills": ["Go"],
}


def messages(patch: dict[str, object]) -> dict[str, str]:
    with pytest.raises(ValidationError) as caught:
        Form.model_validate(VALID | patch)
    return {str(error["loc"][0]): validation_message(error) for error in caught.value.errors()}


@pytest.mark.parametrize(
    ("patch", "expected"),
    [
        ({"message": "Привет"}, {"message": "Не короче 10 символов"}),
        ({"message": "Здравствуйте, Илья! Ждём вас"}, {"message": "Не длиннее 21 символа"}),
        ({"reason": ""}, {"reason": "Обязательное поле"}),
        ({"salary": 0}, {"salary": "Должно быть больше 0"}),
        ({"salary": "много"}, {"salary": "Ожидается целое число"}),
        ({"skills": ["Go", "Python", "SQL"]}, {"skills": "Не больше 2 элементов"}),
        ({"email": "not-an-email"}, {"email": "Некорректный email"}),
    ],
)
def test_pydantic_errors_are_translated(patch: dict[str, object], expected: dict[str, str]) -> None:
    assert messages(patch) == expected


def test_missing_field() -> None:
    with pytest.raises(ValidationError) as caught:
        Form.model_validate({key: value for key, value in VALID.items() if key != "salary"})
    assert [validation_message(error) for error in caught.value.errors()] == ["Обязательное поле"]


def test_unknown_error_type_keeps_pydantic_message() -> None:
    error = {
        "type": "date_from_datetime_inexact",
        "loc": ("held_on",),
        "msg": "Original",
        "input": 1,
    }
    assert validation_message(error) == "Original"  # type: ignore[arg-type]
