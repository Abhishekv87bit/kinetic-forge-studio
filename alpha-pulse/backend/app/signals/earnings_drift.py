"""Post-Earnings Announcement Drift (PEAD) calculator.

Bernard & Thomas (1989): prices continue to drift 60 days after earnings surprises.
SUE = (actual - estimated) / |estimated|
Signal decays linearly over 60 days.

Score mapping:
  SUE > 10%  -> +0.7 x decay
  SUE > 3%   -> +0.4 x decay
  SUE < -10% -> -0.7 x decay
  SUE < -3%  -> -0.4 x decay
  else       -> 0.0
"""

_DRIFT_WINDOW_DAYS = 60


def compute_drift_score(data: dict) -> dict:
    actual = data.get("actual_eps")
    estimated = data.get("estimated_eps")
    days = data.get("days_since_earnings")

    if actual is None or estimated is None or days is None:
        return {"score": 0.0, "details": {"error": "missing_earnings_data"}}

    if estimated == 0:
        return {"score": 0.0, "details": {"error": "zero_estimate"}}

    surprise_pct = (actual - estimated) / abs(estimated)

    # Time decay: 1.0 at day 0, 0.0 at day 60+
    decay = max(0.0, 1.0 - days / _DRIFT_WINDOW_DAYS)

    # Base score from surprise magnitude
    if surprise_pct > 0.10:
        base = 0.7
    elif surprise_pct > 0.03:
        base = 0.4
    elif surprise_pct < -0.10:
        base = -0.7
    elif surprise_pct < -0.03:
        base = -0.4
    else:
        base = 0.0

    score = round(base * decay, 2)

    return {
        "score": score,
        "details": {
            "surprise_pct": round(surprise_pct, 4),
            "days_since_earnings": days,
            "decay_factor": round(decay, 3),
            "drift_window_days": _DRIFT_WINDOW_DAYS,
        },
    }
