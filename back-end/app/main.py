"""Application composition root."""

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.analytics.api import router as analytics_router
from app.config import Settings, get_settings
from app.dictionaries import router as dictionaries_router
from app.hiring.api import offers_router, vacancies_router
from app.identity.api import router as identity_router
from app.recruiting.api import router as recruiting_router
from app.shared.database import Database
from app.shared.http import register_error_handlers
from app.shared.tracing import TraceMiddleware
from app.talent.api import router as talent_router

HEALTH_PATH = "/api/health"


def create_app(settings: Settings | None = None, database: Database | None = None) -> FastAPI:
    settings = settings or get_settings()
    logging.basicConfig(level=settings.log_level)

    app = FastAPI(
        title=settings.app_name,
        openapi_url=f"{settings.api_prefix}/openapi.json",
        docs_url=f"{settings.api_prefix}/docs",
        redoc_url=None,
    )
    app.state.settings = settings
    app.state.database = database or Database(settings.database_url)

    app.add_middleware(TraceMiddleware, debug=settings.recruiting_debug)
    register_error_handlers(app)
    if settings.cors_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.cors_origins,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
    for router in (
        identity_router,
        talent_router,
        vacancies_router,
        offers_router,
        analytics_router,
        dictionaries_router,
        recruiting_router,
    ):
        app.include_router(router, prefix=settings.api_prefix)

    @app.get(HEALTH_PATH, tags=["health"])
    def health() -> dict[str, str]:
        return {"status": "ok"}

    return app
