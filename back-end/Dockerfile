# One image, two processes: the API (default) and the FSP mock (`uvicorn mock_fsp.main:create_app`).
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app
COPY pyproject.toml ./
COPY app ./app
COPY mock_fsp ./mock_fsp
COPY migrations ./migrations
COPY alembic.ini ./
RUN pip install . && useradd --create-home --uid 10001 hrleaders \
    && mkdir -p /app/.media && chown hrleaders:hrleaders /app/.media
USER hrleaders

EXPOSE 8000
# Migrations are versioned and idempotent, so applying them on start is safe.
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:create_app --factory --host 0.0.0.0 --port 8000 --proxy-headers"]
