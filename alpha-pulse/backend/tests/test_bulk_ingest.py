# tests/test_bulk_ingest.py
import pytest
from unittest.mock import patch, AsyncMock
from app.ingestion.seed import seed_default_assets
from app.ingestion.bulk_ingest import bulk_ingest_all


async def test_bulk_ingest_calls_market_for_equities(db_session):
    await seed_default_assets(db_session)

    with patch("app.ingestion.bulk_ingest.fetch_market_data_async", new_callable=AsyncMock) as mock_fetch, \
         patch("app.ingestion.bulk_ingest.save_market_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.fetch_crypto_data", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.save_crypto_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.asyncio.sleep", new_callable=AsyncMock):
        mock_fetch.return_value = {"ticker": "AAPL", "price": 150.0}
        result = await bulk_ingest_all(db_session)
        assert result["equities_attempted"] == 20
        assert mock_fetch.call_count == 20


async def test_bulk_ingest_calls_crypto_for_crypto_assets(db_session):
    await seed_default_assets(db_session)

    with patch("app.ingestion.bulk_ingest.fetch_market_data_async", new_callable=AsyncMock) as mock_market, \
         patch("app.ingestion.bulk_ingest.save_market_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.fetch_crypto_data", new_callable=AsyncMock) as mock_crypto, \
         patch("app.ingestion.bulk_ingest.save_crypto_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.asyncio.sleep", new_callable=AsyncMock):
        mock_market.return_value = {"ticker": "AAPL", "price": 150.0}
        mock_crypto.return_value = {"ticker": "BTC-USD", "price": 60000.0}
        result = await bulk_ingest_all(db_session)
        assert result["crypto_attempted"] == 10
        assert mock_crypto.call_count == 10


async def test_bulk_ingest_handles_individual_failures(db_session):
    await seed_default_assets(db_session)

    with patch("app.ingestion.bulk_ingest.fetch_market_data_async", new_callable=AsyncMock) as mock_fetch, \
         patch("app.ingestion.bulk_ingest.save_market_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.fetch_crypto_data", new_callable=AsyncMock) as mock_crypto, \
         patch("app.ingestion.bulk_ingest.save_crypto_snapshot", new_callable=AsyncMock), \
         patch("app.ingestion.bulk_ingest.asyncio.sleep", new_callable=AsyncMock):
        mock_fetch.side_effect = Exception("yfinance down")
        mock_crypto.return_value = {"ticker": "BTC-USD", "price": 60000.0}
        result = await bulk_ingest_all(db_session)
        assert result["equities_failed"] == 20
        assert result["crypto_succeeded"] == 10
