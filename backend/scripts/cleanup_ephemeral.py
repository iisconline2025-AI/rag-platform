"""Hourly cron job — delete ephemeral_chunks past their TTL.

Run via:
    python -m scripts.cleanup_ephemeral

Schedule (Railway): every hour via Railway cron, OR run inline from
within FastAPI with APScheduler.  Cron is preferred (simpler, isolates
failure).
"""
from __future__ import annotations

import asyncio
import logging

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from app.core.config import settings

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("cleanup_ephemeral")


async def main() -> None:
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        result = await conn.execute(text("SELECT cleanup_expired_ephemeral_chunks()"))
        deleted = result.scalar_one()
        log.info("Deleted %d expired ephemeral chunks", deleted)
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
