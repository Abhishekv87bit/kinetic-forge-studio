"""Default asset seeding -- populates DB with top 30 market assets."""

from __future__ import annotations

import logging

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Asset

logger = logging.getLogger(__name__)

DEFAULT_ASSETS = [
    # Equities (20) -- top by market cap across sectors
    {"id": "AAPL", "asset_class": "equity", "name": "Apple Inc."},
    {"id": "MSFT", "asset_class": "equity", "name": "Microsoft Corp."},
    {"id": "GOOGL", "asset_class": "equity", "name": "Alphabet Inc."},
    {"id": "AMZN", "asset_class": "equity", "name": "Amazon.com Inc."},
    {"id": "NVDA", "asset_class": "equity", "name": "NVIDIA Corp."},
    {"id": "META", "asset_class": "equity", "name": "Meta Platforms Inc."},
    {"id": "TSLA", "asset_class": "equity", "name": "Tesla Inc."},
    {"id": "BRK-B", "asset_class": "equity", "name": "Berkshire Hathaway B"},
    {"id": "JPM", "asset_class": "equity", "name": "JPMorgan Chase & Co."},
    {"id": "V", "asset_class": "equity", "name": "Visa Inc."},
    {"id": "UNH", "asset_class": "equity", "name": "UnitedHealth Group"},
    {"id": "JNJ", "asset_class": "equity", "name": "Johnson & Johnson"},
    {"id": "WMT", "asset_class": "equity", "name": "Walmart Inc."},
    {"id": "PG", "asset_class": "equity", "name": "Procter & Gamble Co."},
    {"id": "MA", "asset_class": "equity", "name": "Mastercard Inc."},
    {"id": "HD", "asset_class": "equity", "name": "The Home Depot Inc."},
    {"id": "XOM", "asset_class": "equity", "name": "Exxon Mobil Corp."},
    {"id": "LLY", "asset_class": "equity", "name": "Eli Lilly and Co."},
    {"id": "AVGO", "asset_class": "equity", "name": "Broadcom Inc."},
    {"id": "COST", "asset_class": "equity", "name": "Costco Wholesale Corp."},
    # Crypto (10) -- top by market cap
    {"id": "BTC-USD", "asset_class": "crypto", "name": "Bitcoin"},
    {"id": "ETH-USD", "asset_class": "crypto", "name": "Ethereum"},
    {"id": "SOL-USD", "asset_class": "crypto", "name": "Solana"},
    {"id": "BNB-USD", "asset_class": "crypto", "name": "Binance Coin"},
    {"id": "XRP-USD", "asset_class": "crypto", "name": "XRP"},
    {"id": "ADA-USD", "asset_class": "crypto", "name": "Cardano"},
    {"id": "DOGE-USD", "asset_class": "crypto", "name": "Dogecoin"},
    {"id": "AVAX-USD", "asset_class": "crypto", "name": "Avalanche"},
    {"id": "DOT-USD", "asset_class": "crypto", "name": "Polkadot"},
    {"id": "LINK-USD", "asset_class": "crypto", "name": "Chainlink"},
]


async def seed_default_assets(db: AsyncSession) -> int:
    """Seed default assets. Returns count of newly created assets."""
    created = 0
    for asset_data in DEFAULT_ASSETS:
        existing = await db.get(Asset, asset_data["id"])
        if existing is None:
            db.add(Asset(**asset_data))
            created += 1
            logger.info("Seeded asset: %s (%s)", asset_data["id"], asset_data["name"])
    if created:
        await db.commit()
    return created
