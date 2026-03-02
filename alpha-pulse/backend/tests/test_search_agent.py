"""Tests for the Search Agent — data bundle assembler."""

from datetime import datetime, timezone

from app.agents.search_agent import gather_asset_data
from app.db.models import Asset, DataSnapshot, SignalScore


async def test_gather_asset_data_returns_all_sources(db_session):
    """Should collect snapshots grouped by source for a given asset."""
    asset = Asset(id="AAPL", asset_class="equity", name="Apple Inc.")
    db_session.add(asset)
    await db_session.commit()

    # Seed snapshots from different sources
    snapshots = [
        DataSnapshot(
            asset_id="AAPL",
            source="price",
            raw_data={"close": 175.50, "volume": 50_000_000},
            period="2026-03-01",
        ),
        DataSnapshot(
            asset_id="AAPL",
            source="sentiment",
            raw_data={"reddit": {"post_count": 12}, "fear_greed": {"score": 65}},
            period="2026-03-01",
        ),
        DataSnapshot(
            asset_id="AAPL",
            source="sec_filing",
            raw_data={"filings": [{"filing_type": "10-K", "sections": {"risk_factors": "Risk text"}}]},
            period="2026-03-01",
        ),
    ]
    for s in snapshots:
        db_session.add(s)
    await db_session.commit()

    bundle = await gather_asset_data(db_session, "AAPL")

    assert bundle["asset_id"] == "AAPL"
    assert bundle["asset_class"] == "equity"
    assert "price" in bundle["data"]
    assert "sentiment" in bundle["data"]
    assert "sec_filing" in bundle["data"]
    # Each source should have its latest raw_data
    assert bundle["data"]["price"]["close"] == 175.50
    assert bundle["data"]["sentiment"]["reddit"]["post_count"] == 12


async def test_gather_asset_data_latest_only(db_session):
    """Should return the most recent snapshot per source, not all of them."""
    asset = Asset(id="AAPL", asset_class="equity", name="Apple Inc.")
    db_session.add(asset)
    await db_session.commit()

    # Old price snapshot
    db_session.add(DataSnapshot(
        asset_id="AAPL", source="price",
        raw_data={"close": 170.00}, period="2026-02-28",
    ))
    # New price snapshot
    db_session.add(DataSnapshot(
        asset_id="AAPL", source="price",
        raw_data={"close": 175.50}, period="2026-03-01",
    ))
    await db_session.commit()

    bundle = await gather_asset_data(db_session, "AAPL")

    # Should only have the latest price
    assert bundle["data"]["price"]["close"] == 175.50


async def test_gather_asset_data_empty(db_session):
    """Should return empty data dict when asset has no snapshots."""
    asset = Asset(id="TSLA", asset_class="equity", name="Tesla Inc.")
    db_session.add(asset)
    await db_session.commit()

    bundle = await gather_asset_data(db_session, "TSLA")

    assert bundle["asset_id"] == "TSLA"
    assert bundle["data"] == {}


async def test_gather_asset_data_missing_asset(db_session):
    """Should raise ValueError for unknown asset ID."""
    import pytest
    with pytest.raises(ValueError, match="Asset not found"):
        await gather_asset_data(db_session, "DOESNOTEXIST")


async def test_gather_includes_signal_scores(db_session):
    """Signal scores should be included in the data bundle."""
    asset = Asset(id="SIG_TEST", asset_class="equity", name="Signal Test")
    db_session.add(asset)
    score = SignalScore(
        asset_id="SIG_TEST", signal_name="lifecycle", score=0.7,
        details={"stage": "maturity"},
    )
    db_session.add(score)
    await db_session.commit()

    bundle = await gather_asset_data(db_session, "SIG_TEST")
    assert "signal_scores" in bundle
    assert "lifecycle" in bundle["signal_scores"]
    assert bundle["signal_scores"]["lifecycle"]["score"] == 0.7
