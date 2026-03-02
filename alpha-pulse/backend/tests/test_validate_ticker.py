import pytest
from unittest.mock import patch, MagicMock


@pytest.mark.asyncio
async def test_validate_valid_ticker(client):
    mock_info = {"shortName": "Apple Inc.", "quoteType": "EQUITY"}
    with patch("app.routes.assets.yf") as mock_yf:
        mock_ticker = MagicMock()
        mock_ticker.info = mock_info
        mock_yf.Ticker.return_value = mock_ticker
        resp = await client.get("/api/assets/validate/AAPL")
    assert resp.status_code == 200
    data = resp.json()
    assert data["valid"] is True
    assert data["name"] == "Apple Inc."
    assert data["asset_class"] == "equity"


@pytest.mark.asyncio
async def test_validate_invalid_ticker(client):
    with patch("app.routes.assets.yf") as mock_yf:
        mock_ticker = MagicMock()
        mock_ticker.info = {}
        mock_yf.Ticker.return_value = mock_ticker
        resp = await client.get("/api/assets/validate/ZZZZZ123")
    assert resp.status_code == 200
    assert resp.json()["valid"] is False


@pytest.mark.asyncio
async def test_validate_crypto_ticker(client):
    mock_info = {"shortName": "Bitcoin USD", "quoteType": "CRYPTOCURRENCY"}
    with patch("app.routes.assets.yf") as mock_yf:
        mock_ticker = MagicMock()
        mock_ticker.info = mock_info
        mock_yf.Ticker.return_value = mock_ticker
        resp = await client.get("/api/assets/validate/BTC-USD")
    assert resp.status_code == 200
    data = resp.json()
    assert data["valid"] is True
    assert data["asset_class"] == "crypto"
