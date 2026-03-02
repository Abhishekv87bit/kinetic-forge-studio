"""Signal computation runner -- orchestrates all signal calculators for an asset."""

from __future__ import annotations

import logging

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Asset, DataSnapshot, SignalScore
from app.signals.lifecycle import compute_lifecycle_score
from app.signals.insider import compute_insider_score
from app.signals.readability import compute_readability_score
from app.signals.earnings_nlp import compute_earnings_nlp_score
from app.signals.employee_sentiment import compute_employee_score

logger = logging.getLogger(__name__)


def _extract_cashflows(market_data: dict) -> list[dict]:
    """Extract cash flow data from yfinance market snapshot."""
    financials = market_data.get("quarterly_financials", [])
    cashflows = []
    for period in financials:
        operating = (
            period.get("Operating Cash Flow")
            or period.get("Total Cash From Operating Activities")
            or 0
        )
        investing = (
            period.get("Capital Expenditures")
            or period.get("Total Cashflows From Investing Activities")
            or 0
        )
        financing = (
            period.get("Total Cash From Financing Activities")
            or period.get("Issuance Of Stock")
            or 0
        )
        if operating == 0:
            operating = period.get("Operating Income", 0)
        cashflows.append({
            "operating": operating,
            "investing": investing,
            "financing": financing,
            "period": period.get("period", "unknown"),
        })
    return cashflows


async def _get_latest_snapshot(db: AsyncSession, asset_id: str, source: str) -> dict | None:
    """Get the latest snapshot raw_data for an asset and source."""
    stmt = (
        select(DataSnapshot.raw_data)
        .where(DataSnapshot.asset_id == asset_id, DataSnapshot.source == source)
        .order_by(DataSnapshot.id.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    row = result.scalar_one_or_none()
    return row


async def _save_signal_score(
    db: AsyncSession, asset_id: str, signal_name: str, result: dict
) -> None:
    """Save or update a signal score in the DB."""
    existing = await db.execute(
        select(SignalScore).where(
            SignalScore.asset_id == asset_id,
            SignalScore.signal_name == signal_name,
        )
    )
    for old in existing.scalars().all():
        await db.delete(old)

    score = SignalScore(
        asset_id=asset_id,
        signal_name=signal_name,
        score=result.get("score", 0.0),
        details=result,
    )
    db.add(score)


async def compute_all_signals(db: AsyncSession, asset_id: str) -> dict:
    """Compute all applicable signals for an asset. Returns dict of signal_name -> result."""
    asset = await db.get(Asset, asset_id)
    if not asset:
        logger.warning("Asset %s not found for signal computation", asset_id)
        return {}

    results = {}
    is_equity = asset.asset_class == "equity"

    if is_equity:
        # 1. Lifecycle
        market_data = await _get_latest_snapshot(db, asset_id, "price") or {}
        cashflows = _extract_cashflows(market_data)
        lifecycle_result = compute_lifecycle_score(cashflows)
        results["lifecycle"] = lifecycle_result
        await _save_signal_score(db, asset_id, "lifecycle", lifecycle_result)

        # 2. Insider (requires SEC filing data)
        sec_data = await _get_latest_snapshot(db, asset_id, "sec_filing") or {}
        insider_transactions = sec_data.get("insider_transactions", [])
        insider_result = compute_insider_score(insider_transactions)
        results["insider"] = insider_result
        await _save_signal_score(db, asset_id, "insider", insider_result)

        # 3. Readability (requires 10-K text)
        filing_text = sec_data.get("risk_factors", "") or sec_data.get("mda", "")
        prior_fog = sec_data.get("prior_fog_index")
        readability_result = compute_readability_score(filing_text, prior_fog)
        results["readability"] = readability_result
        await _save_signal_score(db, asset_id, "readability", readability_result)

        # 4. Earnings NLP (requires 8-K or earnings text)
        earnings_text = sec_data.get("earnings_text", "") or sec_data.get("mda", "")
        pe = market_data.get("pe_ratio")
        earnings_dir = "neutral"
        if isinstance(pe, (int, float)):
            earnings_dir = "positive" if pe > 0 else "negative"
        earnings_result = compute_earnings_nlp_score(earnings_text, earnings_dir)
        results["earnings_nlp"] = earnings_result
        await _save_signal_score(db, asset_id, "earnings_nlp", earnings_result)

        # 5. Employee sentiment (Glassdoor data -- placeholder until scraper added)
        employee_result = compute_employee_score(current_rating=None)
        results["employee_sentiment"] = employee_result
        await _save_signal_score(db, asset_id, "employee_sentiment", employee_result)

    await db.commit()

    logger.info(
        "Computed %d signals for %s: %s",
        len(results),
        asset_id,
        {k: v.get("score", 0) for k, v in results.items()},
    )
    return results
