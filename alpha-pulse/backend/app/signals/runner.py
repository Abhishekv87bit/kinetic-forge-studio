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
from app.signals.momentum import compute_momentum_score
from app.signals.value_factor import compute_value_score
from app.signals.quality_factor import compute_quality_score
from app.signals.earnings_drift import compute_drift_score
from app.signals.regime import detect_regime, score_asset_for_regime
from app.signals.hurst import compute_hurst_score

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

        # 6. Momentum -- from price snapshot
        price_data = market_data or {}
        momentum_prices = {
            "price_now": price_data.get("currentPrice"),
            "price_12m_ago": price_data.get("price_12m_ago"),
            "price_1m_ago": price_data.get("price_1m_ago"),
        }
        if momentum_prices["price_now"]:
            result = compute_momentum_score(momentum_prices)
            await _save_signal_score(db, asset_id, "momentum", result)
            results["momentum"] = result

        # 7. Value -- from fundamentals
        value_data = {
            "pe_ratio": price_data.get("pe_ratio"),
            "pb_ratio": price_data.get("pb_ratio"),
            "dividend_yield": price_data.get("dividend_yield"),
        }
        if any(v is not None for v in value_data.values()):
            result = compute_value_score(value_data)
            await _save_signal_score(db, asset_id, "value", result)
            results["value"] = result

        # 8. Quality -- from fundamentals
        quality_data = {
            "roe": price_data.get("roe"),
            "debt_to_equity": price_data.get("debt_to_equity"),
            "earnings_growth_std": price_data.get("earnings_growth_std"),
        }
        if any(v is not None for v in quality_data.values()):
            result = compute_quality_score(quality_data)
            await _save_signal_score(db, asset_id, "quality", result)
            results["quality"] = result

        # 9. Post-Earnings Drift
        drift_data = {
            "actual_eps": price_data.get("actual_eps"),
            "estimated_eps": price_data.get("estimated_eps"),
            "days_since_earnings": price_data.get("days_since_earnings"),
        }
        if drift_data["actual_eps"] is not None:
            result = compute_drift_score(drift_data)
            await _save_signal_score(db, asset_id, "earnings_drift", result)
            results["earnings_drift"] = result

    # 10. Regime -- from macro snapshot (applies to all asset classes)
    macro_snap = await _get_latest_snapshot(db, "_MACRO", "macro")
    if macro_snap:
        regime_result = detect_regime(macro_snap)
        regime_score = score_asset_for_regime(asset.asset_class, regime_result["regime"])
        combined = {"score": regime_score, "details": {**regime_result["details"], "regime": regime_result["regime"]}}
        await _save_signal_score(db, asset_id, "regime", combined)
        results["regime"] = combined

    if is_equity:
        # 11. Hurst exponent -- from price history (if available)
        price_data = (await _get_latest_snapshot(db, asset_id, "price")) or {}
        price_history = price_data.get("price_history", [])
        if len(price_history) >= 50:
            result = compute_hurst_score(price_history)
            await _save_signal_score(db, asset_id, "hurst", result)
            results["hurst"] = result

    await db.commit()

    logger.info(
        "Computed %d signals for %s: %s",
        len(results),
        asset_id,
        {k: v.get("score", 0) for k, v in results.items()},
    )
    return results
