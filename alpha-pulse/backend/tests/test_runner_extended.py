"""Test that new signal calculators are wired into the runner."""

import pytest
from datetime import datetime, timezone

from app.db.models import Asset, DataSnapshot
from app.signals.runner import compute_all_signals


@pytest.mark.asyncio
async def test_runner_computes_momentum(db_session):
    """Runner should compute momentum for equity assets with price history."""
    asset = Asset(id="TEST", asset_class="equity", name="Test Co", tracked=True)
    db_session.add(asset)
    await db_session.flush()

    # Add price snapshot with historical prices
    snap = DataSnapshot(
        asset_id="TEST",
        source="price",
        raw_data={
            "currentPrice": 140,
            "price_12m_ago": 100,
            "price_1m_ago": 135,
            "pe_ratio": 15,
            "pb_ratio": 2.5,
            "dividend_yield": 0.02,
            "roe": 0.18,
            "debt_to_equity": 0.8,
        },
        fetched_at=datetime.now(timezone.utc),
    )
    db_session.add(snap)
    await db_session.commit()

    results = await compute_all_signals(db_session, "TEST")
    assert "momentum" in results
    assert "value" in results
    assert "quality" in results


@pytest.mark.asyncio
async def test_runner_computes_regime(db_session):
    """Runner should compute regime score using macro data."""
    asset = Asset(id="TEST2", asset_class="equity", name="Test 2", tracked=True)
    # Ensure _MACRO system asset exists
    macro_asset = Asset(id="_MACRO", asset_class="equity", name="Macro", tracked=False)
    db_session.add_all([asset, macro_asset])
    await db_session.flush()

    macro_snap = DataSnapshot(
        asset_id="_MACRO",
        source="macro",
        raw_data={
            "gdp_trend": 0.03,
            "cpi_trend": -0.01,
            "yield_curve": 0.5,
        },
        fetched_at=datetime.now(timezone.utc),
    )
    db_session.add(macro_snap)
    await db_session.commit()

    results = await compute_all_signals(db_session, "TEST2")
    assert "regime" in results
