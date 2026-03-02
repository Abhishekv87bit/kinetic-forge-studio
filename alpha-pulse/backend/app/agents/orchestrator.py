"""Orchestrator — runs the full AI analysis pipeline.

Pipeline:
1. Search Agent → gather data bundle
2. Analyst + Sentiment agents (in parallel)
3. Risk Agent
4. Synthesizer → evaluate Golden Rules → weighted signal
5. Fact Checker → verify numbers
6. Confidence scorer
7. Save Signal to DB
8. Return complete analysis

This is the single entry point for running a full asset analysis.
"""

from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.agents.analyst_agent import analyze_asset, AnalystOutput
from app.agents.risk_agent import assess_risk, RiskOutput
from app.agents.search_agent import gather_asset_data
from app.agents.sentiment_agent import assess_sentiment, SentimentOutput
from app.agents.synthesizer import synthesize, SynthesisOutput
from app.db.models import Signal
from app.validation.confidence import compute_confidence
from app.validation.fact_checker import check_facts, FactCheckResult

logger = logging.getLogger(__name__)


async def run_analysis(
    db: AsyncSession,
    asset_id: str,
) -> dict:
    """Run the full analysis pipeline for an asset.

    Args:
        db: Async database session.
        asset_id: The asset to analyze (e.g. "AAPL").

    Returns:
        Dict with complete analysis results including:
        - analyst: AnalystOutput
        - risk: RiskOutput
        - sentiment: SentimentOutput
        - synthesis: SynthesisOutput
        - fact_check: FactCheckResult
        - signal: the saved Signal row data
        - confidence: final confidence score
    """
    logger.info("Starting analysis pipeline for %s", asset_id)

    # Step 1: Gather data
    logger.info("[1/7] Gathering data for %s", asset_id)
    data_bundle = await gather_asset_data(db, asset_id)

    # Step 2: Run analyst + sentiment in parallel
    logger.info("[2/7] Running analyst + sentiment agents in parallel")
    analyst_task = asyncio.create_task(analyze_asset(data_bundle))
    sentiment_task = asyncio.create_task(assess_sentiment(data_bundle))

    analyst_output, sentiment_output = await asyncio.gather(
        analyst_task, sentiment_task
    )

    # Step 3: Run risk agent (can use analyst output as context)
    logger.info("[3/7] Running risk agent")
    risk_output = await assess_risk(data_bundle)

    # Step 4: Synthesize — evaluate Golden Rules
    logger.info("[4/7] Running synthesizer")
    agent_outputs = {
        "analyst": analyst_output.model_dump(),
        "risk": risk_output.model_dump(),
        "sentiment": sentiment_output.model_dump(),
    }

    synthesis = await synthesize(
        db,
        asset_id=asset_id,
        asset_class=data_bundle["asset_class"],
        agent_outputs=agent_outputs,
        signal_scores=data_bundle.get("signal_scores", {}),
    )

    # Step 5: Fact check analyst numbers
    logger.info("[5/7] Running fact checker")
    fact_check = check_facts(
        analyst_output=analyst_output.model_dump(),
        raw_data=data_bundle["data"],
    )

    # Step 6: Compute confidence
    logger.info("[6/7] Computing confidence score")
    confidence = compute_confidence(
        agreement_ratio=synthesis.agreement_ratio,
        snapshot_ages=data_bundle.get("snapshot_ages", {}),
        fact_check_passed=fact_check.passed,
    )

    # Step 7: Save signal to DB
    # Wrap in try/except — if the DB save fails, we still return the
    # expensive AI results so the caller doesn't lose them.
    logger.info("[7/7] Saving signal to DB")
    signal_id = None
    try:
        signal = Signal(
            asset_id=asset_id,
            signal_type=synthesis.signal_type,
            confidence=confidence,
            summary=synthesis.plain_summary,
            evidence=[
                {
                    "source": "analyst",
                    "outlook": analyst_output.outlook,
                    "bottom_line": analyst_output.bottom_line,
                },
                {
                    "source": "risk",
                    "level": risk_output.overall_risk_level,
                    "flags": len(risk_output.red_flags),
                },
                {
                    "source": "sentiment",
                    "mood": sentiment_output.overall_sentiment,
                    "confidence": sentiment_output.confidence,
                },
            ],
            risk_flags=[
                {
                    "category": f.category,
                    "severity": f.severity,
                    "headline": f.headline,
                }
                for f in risk_output.red_flags
            ],
            raw_llm={
                "analyst": analyst_output.model_dump(),
                "risk": risk_output.model_dump(),
                "sentiment": sentiment_output.model_dump(),
                "synthesis": synthesis.model_dump(),
                "fact_check": fact_check.model_dump(),
            },
        )
        db.add(signal)
        await db.commit()
        await db.refresh(signal)
        signal_id = signal.id

        # Dispatch alert (ntfy push + dashboard log)
        try:
            from app.alerts.dispatcher import dispatch_signal_alert
            await dispatch_signal_alert(db, signal)
        except Exception:
            logger.exception(
                "Alert dispatch failed for %s — signal saved, alert skipped",
                asset_id,
            )
            # Rollback partial alert state so session stays usable
            await db.rollback()
    except Exception:
        logger.exception(
            "Failed to save signal to DB for %s — AI results preserved in response",
            asset_id,
        )
        # Rollback so the session stays usable
        await db.rollback()

    logger.info(
        "Analysis complete for %s: signal=%s confidence=%.2f saved=%s",
        asset_id,
        synthesis.signal_type,
        confidence,
        signal_id is not None,
    )

    return {
        "asset_id": asset_id,
        "signal_id": signal_id,
        "signal_type": synthesis.signal_type,
        "confidence": confidence,
        "analyst": analyst_output.model_dump(),
        "risk": risk_output.model_dump(),
        "sentiment": sentiment_output.model_dump(),
        "synthesis": synthesis.model_dump(),
        "fact_check": fact_check.model_dump(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
