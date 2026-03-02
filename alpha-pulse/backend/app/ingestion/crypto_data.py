"""Crypto data ingestion via CoinGecko free API.

No API key required for basic endpoints. Rate limit: 30 req/min.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.ingestion.snapshot import save_snapshot

logger = logging.getLogger(__name__)

COINGECKO_BASE = "https://api.coingecko.com/api/v3"

# Map common ticker symbols to CoinGecko IDs
TICKER_TO_COINGECKO = {
    "BTC-USD": "bitcoin",
    "ETH-USD": "ethereum",
    "SOL-USD": "solana",
    "ADA-USD": "cardano",
    "DOT-USD": "polkadot",
    "DOGE-USD": "dogecoin",
    "AVAX-USD": "avalanche-2",
    "MATIC-USD": "matic-network",
    "LINK-USD": "chainlink",
    "XRP-USD": "ripple",
    "BNB-USD": "binancecoin",
}


def _resolve_coin_id(ticker_or_id: str) -> str:
    """Convert a ticker symbol (BTC-USD) to a CoinGecko coin ID (bitcoin)."""
    return TICKER_TO_COINGECKO.get(ticker_or_id.upper(), ticker_or_id.lower())


async def fetch_crypto_data(ticker_or_id: str) -> dict:
    """Fetch crypto data from CoinGecko."""
    coin_id = _resolve_coin_id(ticker_or_id)
    url = f"{COINGECKO_BASE}/coins/{coin_id}"
    params = {
        "localization": "false",
        "tickers": "false",
        "community_data": "true",
        "developer_data": "true",
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.get(url, params=params)
        resp.raise_for_status()
        data = resp.json()

    md = data.get("market_data", {})
    community = data.get("community_data", {})

    return {
        "id": data.get("id"),
        "symbol": data.get("symbol"),
        "name": data.get("name"),
        "price": md.get("current_price", {}).get("usd"),
        "market_cap": md.get("market_cap", {}).get("usd"),
        "volume_24h": md.get("total_volume", {}).get("usd"),
        "price_change_24h": md.get("price_change_percentage_24h"),
        "price_change_7d": md.get("price_change_percentage_7d"),
        "price_change_30d": md.get("price_change_percentage_30d"),
        "ath": md.get("ath", {}).get("usd"),
        "ath_change_pct": md.get("ath_change_percentage", {}).get("usd"),
        "circulating_supply": md.get("circulating_supply"),
        "total_supply": md.get("total_supply"),
        "twitter_followers": community.get("twitter_followers"),
        "reddit_subscribers": community.get("reddit_subscribers"),
        "fetched_at": datetime.now(timezone.utc).isoformat(),
    }


async def save_crypto_snapshot(db: AsyncSession, asset_id: str, data: dict):
    """Persist crypto data as a DataSnapshot."""
    return await save_snapshot(
        db,
        asset_id=asset_id,
        source="crypto_price",
        source_url=f"https://www.coingecko.com/en/coins/{data.get('id', '')}",
        raw_data=data,
    )
