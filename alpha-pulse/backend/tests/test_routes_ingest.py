# tests/test_routes_ingest.py
import pytest
from unittest.mock import patch, AsyncMock


async def test_bulk_ingest_endpoint(client):
    with patch("app.routes.ingest.bulk_ingest_all", new_callable=AsyncMock) as mock:
        mock.return_value = {
            "equities_attempted": 20, "equities_succeeded": 20, "equities_failed": 0,
            "crypto_attempted": 10, "crypto_succeeded": 10, "crypto_failed": 0,
        }
        resp = await client.post("/api/ingest/bulk")
        assert resp.status_code == 200
        data = resp.json()
        assert data["equities_succeeded"] == 20
        assert data["crypto_succeeded"] == 10


async def test_bulk_ingest_returns_partial_failures(client):
    with patch("app.routes.ingest.bulk_ingest_all", new_callable=AsyncMock) as mock:
        mock.return_value = {
            "equities_attempted": 20, "equities_succeeded": 18, "equities_failed": 2,
            "crypto_attempted": 10, "crypto_succeeded": 10, "crypto_failed": 0,
        }
        resp = await client.post("/api/ingest/bulk")
        assert resp.status_code == 200
        data = resp.json()
        assert data["equities_failed"] == 2
