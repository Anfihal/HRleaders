"""Run one existing application worker: python -m app.recruiting.run_worker."""

import asyncio
import logging
import signal
from contextlib import suppress

from app.config import get_settings
from app.recruiting.providers import MockAvatarProvider, MockLLMProvider
from app.recruiting.storage import FileObjectStorage
from app.recruiting.transport import NatsTransport, OutboxRelay, TransportError
from app.recruiting.worker import JobWorker
from app.shared.database import Database

logger = logging.getLogger(__name__)


async def run() -> None:
    settings = get_settings()
    logging.basicConfig(level=settings.log_level)
    database = Database(settings.database_url)
    worker = JobWorker(
        database,
        settings,
        FileObjectStorage(settings.media_storage_path),
        MockLLMProvider(),
        MockAvatarProvider(),
    )
    stopped = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, stopped.set)
    transport: NatsTransport | None = None
    try:
        while not stopped.is_set():
            try:
                if settings.nats_url and transport is None:
                    transport = await NatsTransport.connect(settings)
                if transport:
                    await OutboxRelay(database, transport).flush()
                    if not await transport.consume_one(database, worker):
                        # SQL is authoritative even if broker retention expired a command.
                        await asyncio.to_thread(worker.run_one)
                else:
                    await asyncio.to_thread(worker.run_one)
            except TransportError:
                logger.error("transport_unavailable; committed outbox remains retryable")
                if transport:
                    with suppress(Exception):
                        await transport.close()
                    transport = None
            except Exception as error:
                logger.error(
                    "worker_iteration_failed type=%s; committed jobs remain retryable",
                    type(error).__name__,
                )
            with suppress(TimeoutError):
                await asyncio.wait_for(stopped.wait(), timeout=settings.worker_poll_seconds)
    finally:
        if transport:
            await transport.close()
        database.engine.dispose()


if __name__ == "__main__":
    asyncio.run(run())
