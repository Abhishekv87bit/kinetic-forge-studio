"""Employee sentiment signal -- Glassdoor rating as leading indicator.

Green et al. (2019): Companies with rising Glassdoor ratings outperform
those with declining ratings by ~0.74%/month (~9% annualized).
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


def compute_employee_score(
    current_rating: float | None,
    prior_rating: float | None = None,
) -> dict:
    """Compute employee sentiment signal from Glassdoor-style ratings.

    Args:
        current_rating: Current overall rating (1.0-5.0 scale).
        prior_rating: Prior quarter's rating (for trend detection).

    Returns:
        Dict with 'score', 'trend', 'details'.
    """
    if current_rating is None:
        return {
            "score": 0.0,
            "trend": "unavailable",
            "details": {"reason": "no employee rating data available"},
        }

    # Trend detection (most important signal per research)
    if prior_rating is not None:
        delta = current_rating - prior_rating

        if delta >= 0.2:
            score = 0.6
            trend = "rising"
        elif delta <= -0.2:
            score = -0.6
            trend = "falling"
        elif current_rating >= 4.0:
            score = 0.3
            trend = "stable_high"
        elif current_rating <= 3.0:
            score = -0.3
            trend = "stable_low"
        else:
            score = 0.0
            trend = "stable_mid"
    else:
        # No prior data -- use absolute level only (weaker signal)
        if current_rating >= 4.0:
            score = 0.2
            trend = "high_no_trend"
        elif current_rating <= 3.0:
            score = -0.2
            trend = "low_no_trend"
        else:
            score = 0.0
            trend = "mid_no_trend"

    return {
        "score": round(score, 2),
        "trend": trend,
        "details": {
            "current_rating": current_rating,
            "prior_rating": prior_rating,
            "delta": round(current_rating - prior_rating, 2) if prior_rating else None,
        },
    }
