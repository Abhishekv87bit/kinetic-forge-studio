"""Tests for dashboard summary endpoint."""

import pytest
from app.db.models import Asset, Signal


async def test_dashboard_summary_empty(client, db_session):
    resp = await client.get("/api/dashboard/summary")
    assert resp.status_code == 200
    data = resp.json()
    assert "top_opportunities" in data
    assert "top_risks" in data
    assert data["top_opportunities"] == []


async def test_dashboard_summary_with_signals(client, db_session):
    asset = Asset(id="DASH1", asset_class="equity", name="Dashboard Test")
    db_session.add(asset)
    await db_session.flush()

    signal = Signal(
        asset_id="DASH1",
        signal_type="strong_buy",
        confidence=0.85,
        summary="Test strong buy",
    )
    db_session.add(signal)
    await db_session.commit()

    resp = await client.get("/api/dashboard/summary")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["top_opportunities"]) == 1
    assert data["top_opportunities"][0]["asset_id"] == "DASH1"


async def test_dashboard_summary_separates_buys_and_sells(client, db_session):
    a1 = Asset(id="BUY1", asset_class="equity", name="Buy Asset")
    a2 = Asset(id="SELL1", asset_class="equity", name="Sell Asset")
    db_session.add_all([a1, a2])
    await db_session.flush()

    s1 = Signal(asset_id="BUY1", signal_type="strong_buy", confidence=0.9, summary="Buy")
    s2 = Signal(asset_id="SELL1", signal_type="strong_sell", confidence=0.8, summary="Sell")
    db_session.add_all([s1, s2])
    await db_session.commit()

    resp = await client.get("/api/dashboard/summary")
    data = resp.json()
    assert any(o["asset_id"] == "BUY1" for o in data["top_opportunities"])
    assert any(r["asset_id"] == "SELL1" for r in data["top_risks"])
