"""Bulk ingestion -- run all data sources once for all tracked assets."""

from __future__ import annotations

import asyncio
import logging

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Asset
from app.ingestion.market_data import fetch_market_data_async, save_market_snapshot
from app.ingestion.crypto_data import fetch_crypto_data, save_crypto_snapshot

logger = logging.getLogger(__name__)


async def bulk_ingest_all(db: AsyncSession) -> dict:
    """Run market + crypto ingestion for all tracked assets.

    Returns summary dict with counts of attempted/succeeded/failed.
    """
    # Get tracked equities
    result = await db.execute(
        select(Asset.id).where(Asset.asset_class == "equity", Asset.tracked.is_(True))
    )
    equity_ids = list(result.scalars().all())

    # Get tracked crypto
    result = await db.execute(
        select(Asset.id).where(Asset.asset_class == "crypto", Asset.tracked.is_(True))
    )
    crypto_ids = list(result.scalars().all())

    summary = {
        "equities_attempted": len(equity_ids),
        "equities_succeeded": 0,
        "equities_failed": 0,
        "crypto_attempted": len(crypto_ids),
        "crypto_succeeded": 0,
        "crypto_failed": 0,
    }

    # Ingest equities
    for i, asset_id in enumerate(equity_ids):
        try:
            if i > 0:
                await asyncio.sleep(1)  # Rate limit: 1 req/sec
            data = await fetch_market_data_async(asset_id)
            await save_market_snapshot(db, asset_id, data)
            summary["equities_succeeded"] += 1
            logger.info("Bulk ingested market data for %s (%d/%d)", asset_id, i + 1, len(equity_ids))
        except Exception:
            summary["equities_failed"] += 1
            logger.exception("Bulk ingestion failed for %s", asset_id)

    # Ingest crypto
    for i, asset_id in enumerate(crypto_ids):
        try:
            if i > 0:
                await asyncio.sleep(2)  # CoinGecko rate limit
            data = await fetch_crypto_data(asset_id)
            await save_crypto_snapshot(db, asset_id, data)
            summary["crypto_succeeded"] += 1
            logger.info("Bulk ingested crypto data for %s (%d/%d)", asset_id, i + 1, len(crypto_ids))
        except Exception:
            summary["crypto_failed"] += 1
            logger.exception("Bulk crypto ingestion failed for %s", asset_id)

    logger.info("Bulk ingestion complete: %s", summary)
    return summary
