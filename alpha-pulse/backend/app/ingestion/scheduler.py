"""Ingestion scheduler — APScheduler integration.

Runs data ingestion jobs on cron schedules. Market-hours aware
for equity data. Global enable/disable via settings.scheduler_enabled.
"""

from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from app.config import settings

logger = logging.getLogger(__name__)

# Proper timezone for US Eastern (handles EST/EDT automatically)
_ET = ZoneInfo("America/New_York")


def is_market_hours(dt: datetime | None = None) -> bool:
    """Check if current time is during US equity market hours.

    Market hours: Mon-Fri, 9:30 AM - 4:00 PM ET.
    Uses zoneinfo for correct EST/EDT handling.
    """
    if dt is None:
        dt = datetime.now(timezone.utc)

    # Convert UTC → America/New_York (DST-aware)
    et_time = dt.astimezone(_ET)

    # Weekend check (Monday=0, Sunday=6)
    if et_time.weekday() >= 5:
        return False

    # Time check: 9:30 - 16:00 ET
    hour, minute = et_time.hour, et_time.minute
    if hour < 9 or (hour == 9 and minute < 30):
        return False
    if hour >= 16:
        return False

    return True


# ── Job functions ─────────────────────────────────────────────────
# These are thin wrappers that the scheduler calls. They acquire
# a DB session, query tracked assets, and call the appropriate
# ingestion function. Defined as module-level async functions.


async def _job_ingest_market():
    """Fetch market data for all tracked equity assets."""
    if not is_market_hours():
        logger.debug("Skipping market ingestion — outside market hours")
        return

    from app.db.database import async_session_factory
    from app.db.models import Asset
    from app.ingestion.market_data import fetch_market_data_async, save_market_snapshot
    from sqlalchemy import select

    async with async_session_factory() as db:
        result = await db.execute(
            select(Asset.id).where(Asset.asset_class == "equity", Asset.tracked.is_(True))
        )
        asset_ids = result.scalars().all()

    for i, asset_id in enumerate(asset_ids):
        try:
            if i > 0:
                await asyncio.sleep(1)  # Rate limit: 1 req/sec
            data = await fetch_market_data_async(asset_id)
            async with async_session_factory() as db:
                await save_market_snapshot(db, asset_id, data)
            logger.info("Market data ingested for %s", asset_id)
        except Exception:
            logger.exception("Market ingestion failed for %s", asset_id)


async def _job_ingest_crypto():
    """Fetch crypto data for all tracked crypto assets."""
    from app.db.database import async_session_factory
    from app.db.models import Asset
    from app.ingestion.crypto_data import fetch_crypto_data, save_crypto_snapshot
    from sqlalchemy import select

    async with async_session_factory() as db:
        result = await db.execute(
            select(Asset.id).where(Asset.asset_class == "crypto", Asset.tracked.is_(True))
        )
        asset_ids = result.scalars().all()

    for i, asset_id in enumerate(asset_ids):
        try:
            if i > 0:
                await asyncio.sleep(2)  # CoinGecko free tier: 30 req/min
            data = await fetch_crypto_data(asset_id)
            async with async_session_factory() as db:
                await save_crypto_snapshot(db, asset_id, data)
            logger.info("Crypto data ingested for %s", asset_id)
        except Exception:
            logger.exception("Crypto ingestion failed for %s", asset_id)


async def _job_ingest_macro():
    """Fetch macro indicators."""
    from app.db.database import async_session_factory
    from app.ingestion.macro_data import fetch_macro_data, save_macro_snapshot

    try:
        data = await fetch_macro_data(api_key=settings.fred_api_key)
        async with async_session_factory() as db:
            await save_macro_snapshot(db, data)
        logger.info("Macro data ingested")
    except Exception:
        logger.exception("Macro ingestion failed")


async def _job_ingest_sentiment():
    """Fetch sentiment for all tracked assets."""
    from app.db.database import async_session_factory
    from app.db.models import Asset
    from app.ingestion.sentiment import (
        fetch_reddit_sentiment,
        fetch_news_sentiment,
        fetch_fear_greed,
        save_sentiment_snapshot,
    )
    from sqlalchemy import select

    # Fear & Greed is global (not per-asset)
    try:
        fg = await fetch_fear_greed()
    except Exception:
        fg = {"score": None, "rating": "unavailable"}

    async with async_session_factory() as db:
        result = await db.execute(
            select(Asset.id).where(Asset.tracked.is_(True))
        )
        asset_ids = result.scalars().all()

    for i, asset_id in enumerate(asset_ids):
        try:
            if i > 0:
                await asyncio.sleep(2)  # Rate limit: Reddit + NewsAPI
            reddit = await fetch_reddit_sentiment(asset_id)
            news = {}
            if settings.newsapi_key:
                news = await fetch_news_sentiment(
                    asset_id, api_key=settings.newsapi_key
                )
            combined = {
                "reddit": reddit,
                "news": news,
                "fear_greed": fg,
            }
            async with async_session_factory() as db:
                await save_sentiment_snapshot(db, asset_id, combined)
            logger.info("Sentiment ingested for %s", asset_id)
        except Exception:
            logger.exception("Sentiment ingestion failed for %s", asset_id)


async def _job_compute_signals():
    """Compute quantitative signals for all tracked equity assets."""
    from app.db.database import async_session_factory
    from app.db.models import Asset
    from app.signals.runner import compute_all_signals
    from sqlalchemy import select

    async with async_session_factory() as db:
        result = await db.execute(
            select(Asset.id).where(Asset.tracked.is_(True))
        )
        asset_ids = result.scalars().all()

    for asset_id in asset_ids:
        try:
            async with async_session_factory() as db:
                await compute_all_signals(db, asset_id)
            logger.info("Signals computed for %s", asset_id)
        except Exception:
            logger.exception("Signal computation failed for %s", asset_id)


async def _job_ingest_sec():
    """Fetch SEC filings for tracked equity assets (weekly)."""
    from app.db.database import async_session_factory
    from app.db.models import Asset
    from app.ingestion.sec_edgar import fetch_sec_filings, save_sec_snapshot
    from sqlalchemy import select

    async with async_session_factory() as db:
        result = await db.execute(
            select(Asset.id).where(Asset.asset_class == "equity", Asset.tracked.is_(True))
        )
        asset_ids = result.scalars().all()

    for i, asset_id in enumerate(asset_ids):
        try:
            if i > 0:
                await asyncio.sleep(10)  # SEC EDGAR: 10 req/sec limit — we pause 10s to be polite
            data = await fetch_sec_filings(asset_id)
            async with async_session_factory() as db:
                await save_sec_snapshot(db, asset_id, data)
            logger.info("SEC filings ingested for %s", asset_id)
        except Exception:
            logger.exception("SEC ingestion failed for %s", asset_id)


async def _job_auto_scan():
    """Run full AI analysis on all tracked assets."""
    from app.db.database import async_session_factory
    from app.db.models import Asset
    from app.agents.orchestrator import run_analysis
    from sqlalchemy import select

    async with async_session_factory() as db:
        result = await db.execute(
            select(Asset.id).where(Asset.tracked.is_(True), Asset.id != "_MACRO")
        )
        asset_ids = result.scalars().all()

    logger.info("Auto-scan starting for %d assets", len(asset_ids))

    for i, asset_id in enumerate(asset_ids):
        try:
            if i > 0:
                await asyncio.sleep(5)  # Groq rate limit: 30 req/min
            async with async_session_factory() as db:
                await run_analysis(db, asset_id)
            logger.info("Auto-scan complete for %s (%d/%d)", asset_id, i + 1, len(asset_ids))
        except Exception:
            logger.exception("Auto-scan failed for %s", asset_id)

    logger.info("Auto-scan finished for %d assets", len(asset_ids))


# ── Scheduler factory ────────────────────────────────────────────


def create_scheduler() -> AsyncIOScheduler:
    """Create and configure the ingestion scheduler.

    Jobs are only added if settings.scheduler_enabled is True.
    The scheduler is NOT started here — call scheduler.start()
    in the FastAPI lifespan.
    """
    scheduler = AsyncIOScheduler()

    if not settings.scheduler_enabled:
        logger.info("Scheduler disabled by config")
        return scheduler

    # Market data: every 30 min, Mon-Fri 9:30-16:00 ET (DST-aware)
    scheduler.add_job(
        _job_ingest_market,
        CronTrigger(
            minute="*/30", hour="9-16", day_of_week="mon-fri",
            timezone=_ET,
        ),
        id="ingest_market_data",
        name="Market Data (equities)",
        replace_existing=True,
    )

    # Crypto: every 15 min, 24/7
    scheduler.add_job(
        _job_ingest_crypto,
        CronTrigger(minute="*/15"),
        id="ingest_crypto_data",
        name="Crypto Data",
        replace_existing=True,
    )

    # Macro: daily at 6:00 AM ET (DST-aware)
    scheduler.add_job(
        _job_ingest_macro,
        CronTrigger(hour=6, minute=0, timezone=_ET),
        id="ingest_macro_data",
        name="Macro Indicators (FRED)",
        replace_existing=True,
    )

    # Sentiment: every 2 hours
    scheduler.add_job(
        _job_ingest_sentiment,
        CronTrigger(hour="*/2", minute=15),
        id="ingest_sentiment",
        name="Sentiment (Reddit + News)",
        replace_existing=True,
    )

    # SEC filings: weekly on Monday at 7:00 AM ET (DST-aware)
    scheduler.add_job(
        _job_ingest_sec,
        CronTrigger(day_of_week="mon", hour=7, minute=0, timezone=_ET),
        id="ingest_sec_filings",
        name="SEC EDGAR Filings",
        replace_existing=True,
    )

    # Signal computation: daily at 7:00 AM ET (after overnight data ingestion)
    scheduler.add_job(
        _job_compute_signals,
        CronTrigger(hour=7, minute=0, timezone=_ET),
        id="compute_signals",
        name="Quantitative Signals",
        replace_existing=True,
    )

    # Auto-scan: daily at 8:00 AM ET (after signal computation at 7 AM)
    scheduler.add_job(
        _job_auto_scan,
        CronTrigger(hour=8, minute=0, timezone=_ET),
        id="auto_scan",
        name="Auto-Scan (AI Analysis)",
        replace_existing=True,
    )

    logger.info("Scheduler configured with %d jobs", len(scheduler.get_jobs()))
    return scheduler


def get_scheduled_jobs(scheduler: AsyncIOScheduler) -> list[dict]:
    """Return a summary of all scheduled jobs."""
    jobs = []
    for job in scheduler.get_jobs():
        next_run = getattr(job, "next_run_time", None)
        jobs.append({
            "id": job.id,
            "name": job.name,
            "next_run": str(next_run) if next_run else None,
            "trigger": str(job.trigger),
        })
    return jobs
