"""Tests for signal computation runner."""

import pytest
from sqlalchemy import select
from app.db.models import Asset, DataSnapshot, SignalScore
from app.signals.runner import compute_all_signals


async def test_compute_signals_for_equity(db_session):
    """Lifecycle signal computed for equity with cash flow data."""
    asset = Asset(id="TEST", asset_class="equity", name="Test Corp")
    db_session.add(asset)
    snap = DataSnapshot(
        asset_id="TEST",
        source="price",
        raw_data={
            "quarterly_financials": [
                {
                    "period": "2025-12-31",
                    "Total Revenue": 1000000,
                    "Operating Income": 200000,
                }
            ],
            "quarterly_balance_sheet": [{"period": "2025-12-31"}],
        },
    )
    db_session.add(snap)
    await db_session.commit()

    results = await compute_all_signals(db_session, "TEST")
    assert "lifecycle" in results
    assert isinstance(results["lifecycle"]["score"], float)


async def test_compute_signals_skips_crypto_equity_signals(db_session):
    """Crypto assets skip equity-only signals."""
    asset = Asset(id="BTC-USD", asset_class="crypto", name="Bitcoin")
    db_session.add(asset)
    await db_session.commit()

    results = await compute_all_signals(db_session, "BTC-USD")
    assert "lifecycle" not in results
    assert "insider" not in results
    assert "readability" not in results


async def test_compute_signals_saves_to_db(db_session):
    """Signal scores are persisted to SignalScore table."""
    asset = Asset(id="TEST2", asset_class="equity", name="Test2")
    db_session.add(asset)
    await db_session.commit()

    await compute_all_signals(db_session, "TEST2")

    result = await db_session.execute(
        select(SignalScore).where(SignalScore.asset_id == "TEST2")
    )
    scores = result.scalars().all()
    # Should have at least lifecycle (even if zero due to no data)
    assert len(scores) >= 1
