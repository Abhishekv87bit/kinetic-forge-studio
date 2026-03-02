import pytest


@pytest.mark.asyncio
async def test_create_manual_buy(client):
    # Create asset first
    await client.post("/api/assets", json={"id": "AAPL", "asset_class": "equity", "name": "Apple"})
    resp = await client.post("/api/portfolio/trades/manual", json={
        "asset_id": "AAPL",
        "action": "buy",
        "quantity": 10,
        "price": 150.0,
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["asset_id"] == "AAPL"
    assert data["action"] == "buy"
    assert data["quantity"] == 10
    assert data["price_at"] == 150.0
    assert data["status"] == "open"
    assert data["signal_id"] is None


@pytest.mark.asyncio
async def test_create_manual_sell(client):
    await client.post("/api/assets", json={"id": "TSLA", "asset_class": "equity", "name": "Tesla"})
    resp = await client.post("/api/portfolio/trades/manual", json={
        "asset_id": "TSLA",
        "action": "sell",
        "quantity": 5,
        "price": 200.0,
    })
    assert resp.status_code == 201
    assert resp.json()["action"] == "sell"


@pytest.mark.asyncio
async def test_manual_trade_invalid_action(client):
    await client.post("/api/assets", json={"id": "MSFT", "asset_class": "equity", "name": "Microsoft"})
    resp = await client.post("/api/portfolio/trades/manual", json={
        "asset_id": "MSFT",
        "action": "hold",
        "quantity": 10,
        "price": 100.0,
    })
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_manual_trade_shows_in_summary(client):
    await client.post("/api/assets", json={"id": "GOOG", "asset_class": "equity", "name": "Alphabet"})
    await client.post("/api/portfolio/trades/manual", json={
        "asset_id": "GOOG",
        "action": "buy",
        "quantity": 2,
        "price": 170.0,
    })
    resp = await client.get("/api/portfolio/summary")
    assert resp.status_code == 200
    assert resp.json()["total_trades"] == 1
    assert resp.json()["open_trades"] == 1
