"""Dashboard summary endpoint -- market intelligence at a glance."""

import logging
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.db.models import Asset, Signal, DataSnapshot, SignalScore

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])

logger = logging.getLogger(__name__)


@router.get("/summary")
async def dashboard_summary(db: AsyncSession = Depends(get_db)):
    """Return market intelligence summary for the dashboard."""

    # Get latest signal per asset (subquery for max id per asset)
    latest_signal_ids = (
        select(
            Signal.asset_id,
            func.max(Signal.id).label("max_id"),
        )
        .group_by(Signal.asset_id)
        .subquery()
    )

    stmt = (
        select(Signal)
        .join(latest_signal_ids, Signal.id == latest_signal_ids.c.max_id)
        .order_by(desc(Signal.confidence))
    )
    result = await db.execute(stmt)
    signals = result.scalars().all()

    opportunities = []
    risks = []

    for sig in signals:
        item = {
            "asset_id": sig.asset_id,
            "signal_type": sig.signal_type,
            "confidence": sig.confidence,
            "summary": sig.summary,
            "signal_id": sig.id,
            "created_at": sig.created_at.isoformat() if sig.created_at else None,
        }
        if sig.signal_type in ("strong_buy", "buy"):
            opportunities.append(item)
        elif sig.signal_type in ("strong_sell", "sell"):
            risks.append(item)

    # Check for stale data (assets with no snapshot in 24h)
    cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
    stale_stmt = (
        select(Asset.id)
        .where(Asset.tracked.is_(True), Asset.id != "_MACRO")
        .outerjoin(
            DataSnapshot,
            (DataSnapshot.asset_id == Asset.id) & (DataSnapshot.fetched_at > cutoff),
        )
        .where(DataSnapshot.id.is_(None))
    )
    stale_result = await db.execute(stale_stmt)
    stale_assets = list(stale_result.scalars().all())

    return {
        "top_opportunities": opportunities[:5],
        "top_risks": risks[:5],
        "total_tracked": len(signals),
        "stale_assets": stale_assets,
    }
