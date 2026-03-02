"""Insider trading signal -- analyzes Form 4 purchase/sale patterns."""

from __future__ import annotations

import logging
from datetime import datetime

logger = logging.getLogger(__name__)


def compute_insider_score(transactions: list[dict]) -> dict:
    """Compute insider trading signal from Form 4 data.

    Args:
        transactions: List of dicts with 'type' (purchase/sale),
                      'shares', 'date', optional 'insider' name.

    Returns:
        Dict with 'score', 'direction', 'cluster_detected', 'details'.
    """
    if not transactions:
        return {
            "score": 0.0,
            "direction": "no_activity",
            "cluster_detected": False,
            "details": {"reason": "no insider transactions found"},
        }

    total_bought = sum(t.get("shares", 0) for t in transactions if t.get("type") == "purchase")
    total_sold = sum(t.get("shares", 0) for t in transactions if t.get("type") == "sale")
    total = total_bought + total_sold

    if total == 0:
        return {
            "score": 0.0,
            "direction": "no_activity",
            "cluster_detected": False,
            "details": {"reason": "zero share volume"},
        }

    net_ratio = (total_bought - total_sold) / total  # -1 to +1

    # Detect cluster buying: 3+ unique insiders purchasing within 14 days
    purchases = [t for t in transactions if t.get("type") == "purchase"]
    cluster_detected = False
    if len(purchases) >= 3:
        purchase_dates = []
        for t in purchases:
            try:
                purchase_dates.append(datetime.strptime(t["date"], "%Y-%m-%d"))
            except (ValueError, KeyError):
                continue
        if purchase_dates:
            purchase_dates.sort()
            span = (purchase_dates[-1] - purchase_dates[0]).days
            unique_insiders = len(set(t.get("insider", f"unknown_{i}") for i, t in enumerate(purchases)))
            if span <= 14 and unique_insiders >= 3:
                cluster_detected = True

    # Score calculation
    if net_ratio > 0.3:
        base_score = min(0.8, net_ratio)
        direction = "net_buying"
    elif net_ratio < -0.3:
        base_score = max(-0.6, net_ratio * 0.75)
        direction = "net_selling"
    else:
        base_score = 0.0
        direction = "mixed"

    # Cluster bonus
    if cluster_detected and direction == "net_buying":
        base_score = min(1.0, base_score + 0.2)

    return {
        "score": round(base_score, 2),
        "direction": direction,
        "cluster_detected": cluster_detected,
        "details": {
            "total_bought": total_bought,
            "total_sold": total_sold,
            "net_ratio": round(net_ratio, 3),
            "transaction_count": len(transactions),
        },
    }
