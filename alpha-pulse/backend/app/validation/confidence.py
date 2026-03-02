"""Confidence scorer — measures how much we should trust a signal.

Combines two factors:
1. Agreement ratio: what fraction of Golden Rules agree on direction
2. Data freshness: how recent is the underlying data

Result: confidence = agreement_ratio × data_freshness_factor
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

logger = logging.getLogger(__name__)


def _freshness_factor(snapshot_ages: dict[str, str]) -> float:
    """Compute a freshness factor from snapshot timestamps.

    Returns:
        1.0 if all data < 1 day old
        0.9 if < 3 days old
        0.7 if < 7 days old
        0.5 if older
        0.3 if no timestamps available
    """
    if not snapshot_ages:
        return 0.3

    now = datetime.now(timezone.utc)
    max_age_hours = 0.0

    for source, ts_str in snapshot_ages.items():
        try:
            # Handle "Z" suffix (Python 3.10 fromisoformat doesn't support it)
            clean_ts = ts_str.replace("Z", "+00:00") if isinstance(ts_str, str) else str(ts_str)
            ts = datetime.fromisoformat(clean_ts)
            # Ensure timezone-aware for safe subtraction
            if ts.tzinfo is None:
                ts = ts.replace(tzinfo=timezone.utc)
            age_hours = (now - ts).total_seconds() / 3600
            max_age_hours = max(max_age_hours, age_hours)
        except (ValueError, TypeError):
            # Can't parse timestamp — assume stale
            max_age_hours = max(max_age_hours, 200)

    if max_age_hours < 24:
        return 1.0
    if max_age_hours < 72:
        return 0.9
    if max_age_hours < 168:
        return 0.7
    return 0.5


def compute_confidence(
    agreement_ratio: float,
    snapshot_ages: dict[str, str],
    fact_check_passed: bool = True,
) -> float:
    """Compute overall confidence score for a signal.

    Args:
        agreement_ratio: 0.0-1.0, fraction of rules agreeing on direction.
        snapshot_ages: Dict of source → ISO timestamp strings.
        fact_check_passed: False if major fact-check mismatches found.

    Returns:
        Confidence score 0.0-1.0.
    """
    freshness = _freshness_factor(snapshot_ages)
    confidence = agreement_ratio * freshness

    # Penalize if fact check failed
    if not fact_check_passed:
        confidence *= 0.5

    # Clamp
    return round(max(0.0, min(1.0, confidence)), 2)
