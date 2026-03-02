"""Quality factor: ROE, debt-to-equity, earnings stability.
High-quality companies have high ROE, low debt, stable earnings."""

from app.signals.quality_factor import compute_quality_score


def test_high_quality():
    """High ROE, low debt, stable earnings -> strong quality."""
    data = {"roe": 0.25, "debt_to_equity": 0.3, "earnings_growth_std": 0.05}
    result = compute_quality_score(data)
    assert result["score"] > 0.5


def test_low_quality():
    """Low ROE, high debt, volatile earnings."""
    data = {"roe": 0.03, "debt_to_equity": 3.0, "earnings_growth_std": 0.40}
    result = compute_quality_score(data)
    assert result["score"] < -0.3


def test_moderate_quality():
    data = {"roe": 0.12, "debt_to_equity": 1.0, "earnings_growth_std": 0.15}
    result = compute_quality_score(data)
    assert -0.3 <= result["score"] <= 0.3


def test_negative_roe():
    """Losing money -> bad quality signal."""
    data = {"roe": -0.10, "debt_to_equity": 2.0, "earnings_growth_std": 0.30}
    result = compute_quality_score(data)
    assert result["score"] < -0.4


def test_missing_data():
    result = compute_quality_score({})
    assert result["score"] == 0.0
