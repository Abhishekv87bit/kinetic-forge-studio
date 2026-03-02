"""Search Agent — assembles data bundles from local DB.

Queries all DataSnapshot rows for a given asset, groups by source,
and returns only the latest snapshot per source. No Claude call —
pure data retrieval to feed downstream agents.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Asset, DataSnapshot, SignalScore

logger = logging.getLogger(__name__)


async def gather_asset_data(db: AsyncSession, asset_id: str) -> dict:
    """Assemble a context bundle with latest data per source.

    Args:
        db: Async database session.
        asset_id: The asset ticker / ID to gather data for.

    Returns:
        dict with keys:
            - asset_id: str
            - asset_class: str
            - data: dict[source_name, raw_data]  (latest snapshot per source)
            - snapshot_ages: dict[source_name, iso_timestamp]

    Raises:
        ValueError: If asset_id doesn't exist in the DB.
    """
    # Verify asset exists and get its class
    asset = await db.get(Asset, asset_id)
    if asset is None:
        raise ValueError(f"Asset not found: {asset_id}")

    # Subquery: max id per source (latest snapshot)
    latest_ids_subq = (
        select(
            DataSnapshot.source,
            func.max(DataSnapshot.id).label("max_id"),
        )
        .where(DataSnapshot.asset_id == asset_id)
        .group_by(DataSnapshot.source)
        .subquery()
    )

    # Main query: join snapshots to get full rows for latest per source
    stmt = (
        select(DataSnapshot)
        .join(
            latest_ids_subq,
            (DataSnapshot.id == latest_ids_subq.c.max_id),
        )
        .order_by(DataSnapshot.source)
    )

    result = await db.execute(stmt)
    snapshots = result.scalars().all()

    data: dict[str, dict] = {}
    snapshot_ages: dict[str, str] = {}

    for snap in snapshots:
        data[snap.source] = snap.raw_data
        fetched = snap.fetched_at
        if fetched:
            snapshot_ages[snap.source] = (
                fetched.isoformat() if hasattr(fetched, "isoformat") else str(fetched)
            )

    logger.info(
        "Gathered %d data sources for %s: %s",
        len(data),
        asset_id,
        list(data.keys()),
    )

    # Gather latest signal scores
    score_stmt = select(SignalScore).where(SignalScore.asset_id == asset_id)
    score_result = await db.execute(score_stmt)
    signal_scores = {}
    for ss in score_result.scalars().all():
        signal_scores[ss.signal_name] = {
            "score": ss.score,
            "details": ss.details,
            "computed_at": ss.computed_at.isoformat() if ss.computed_at else None,
        }

    return {
        "asset_id": asset_id,
        "asset_class": asset.asset_class,
        "data": data,
        "snapshot_ages": snapshot_ages,
        "signal_scores": signal_scores,
    }
