"""Post-Earnings Announcement Drift (PEAD).
Prices keep drifting in the direction of earnings surprises for weeks.
Sharpe ratios nearly double when exploiting this. (Bernard & Thomas 1989)"""

from app.signals.earnings_drift import compute_drift_score


def test_positive_surprise_drift():
    """Beat estimates by 10%+ -> strong positive drift expected."""
    data = {"actual_eps": 2.20, "estimated_eps": 2.00, "days_since_earnings": 5}
    result = compute_drift_score(data)
    assert result["score"] > 0.3
    assert result["details"]["surprise_pct"] > 0


def test_negative_surprise_drift():
    """Missed estimates -> negative drift."""
    data = {"actual_eps": 1.80, "estimated_eps": 2.00, "days_since_earnings": 3}
    result = compute_drift_score(data)
    assert result["score"] < -0.3


def test_drift_decays_with_time():
    """After 60+ days, drift signal fades."""
    data = {"actual_eps": 2.50, "estimated_eps": 2.00, "days_since_earnings": 70}
    result = compute_drift_score(data)
    assert -0.1 <= result["score"] <= 0.1


def test_inline_earnings_neutral():
    """Met estimates exactly -> no drift."""
    data = {"actual_eps": 2.00, "estimated_eps": 2.00, "days_since_earnings": 5}
    result = compute_drift_score(data)
    assert -0.1 <= result["score"] <= 0.1


def test_missing_data():
    result = compute_drift_score({})
    assert result["score"] == 0.0
