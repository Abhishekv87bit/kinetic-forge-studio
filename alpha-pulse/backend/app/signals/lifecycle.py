"""Corporate lifecycle classification using Dickinson (2011) cash flow method.

Classifies companies by the sign pattern of operating, investing, and
financing cash flows into: Introduction, Growth, Maturity, Shakeout, Decline.
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

# Dickinson lifecycle classification: (operating_sign, investing_sign, financing_sign) -> stage
_STAGE_MAP = {
    ("-", "-", "+"): "introduction",
    ("+", "-", "+"): "growth",
    ("+", "-", "-"): "maturity",
    ("-", "+", "+"): "decline",
    ("-", "+", "-"): "decline",
}

_SCORE_MAP = {
    "maturity": 0.7,
    "growth": 0.4,
    "shakeout": -0.2,
    "introduction": -0.5,
    "decline": -0.8,
    "unknown": 0.0,
}


def _sign(value: float) -> str:
    return "+" if value >= 0 else "-"


def compute_lifecycle_score(cashflows: list[dict]) -> dict:
    """Compute lifecycle stage from quarterly cash flow data.

    Args:
        cashflows: List of dicts with 'operating', 'investing', 'financing' keys.
                   Last item is the most recent quarter.

    Returns:
        Dict with 'score' (-1 to +1), 'stage', and 'details'.
    """
    if not cashflows:
        return {"score": 0.0, "stage": "unknown", "details": {"reason": "no cash flow data"}}

    # Use the most recent quarter
    latest = cashflows[-1]
    op = latest.get("operating", 0)
    inv = latest.get("investing", 0)
    fin = latest.get("financing", 0)

    pattern = (_sign(op), _sign(inv), _sign(fin))
    stage = _STAGE_MAP.get(pattern, "shakeout")
    score = _SCORE_MAP[stage]

    return {
        "score": score,
        "stage": stage,
        "details": {
            "operating_cf": op,
            "investing_cf": inv,
            "financing_cf": fin,
            "pattern": "".join(pattern),
            "quarters_available": len(cashflows),
        },
    }
