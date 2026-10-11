"""Bounded, decoded photo validation and metadata-free PNG normalization."""

import base64
import binascii
import warnings
from io import BytesIO

from PIL import Image, UnidentifiedImageError

from app.shared.errors import DomainValidationError


def validate_photo(encoded: str, max_bytes: int, max_pixels: int) -> bytes:
    try:
        source = base64.b64decode(encoded, validate=True)
        if len(source) > max_bytes:
            raise ValueError("Фото слишком большое")
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(BytesIO(source)) as image:
                if image.format not in {"JPEG", "PNG", "WEBP"}:
                    raise ValueError("Разрешены JPEG, PNG и WebP")
                width, height = image.size
                if min(width, height) < 128 or width * height > max_pixels:
                    raise ValueError("Фото: минимум 128×128, превышен лимит пикселей")
                image.load()
                normalized = Image.new("RGB", image.size)
                normalized.paste(image.convert("RGB"))
                output = BytesIO()
                normalized.save(output, format="PNG")
                result = output.getvalue()
                if len(result) > max_bytes:
                    raise ValueError("Нормализованное фото слишком большое")
                return result
    except (
        binascii.Error,
        ValueError,
        UnidentifiedImageError,
        OSError,
        Image.DecompressionBombError,
        Image.DecompressionBombWarning,
    ) as error:
        raise DomainValidationError("Неверное изображение или превышен лимит размера") from error
