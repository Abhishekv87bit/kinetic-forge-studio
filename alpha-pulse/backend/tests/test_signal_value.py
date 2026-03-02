"""Value factor: composite of P/E, P/B, dividend yield.
Low P/E + low P/B + high dividend = deep value."""

from app.signals.value_factor import compute_value_score


def test_deep_value_stock():
    """Low P/E, low P/B, decent dividend -> strong value signal."""
    fundamentals = {"pe_ratio": 8.0, "pb_ratio": 1.0, "dividend_yield": 0.04}
    result = compute_value_score(fundamentals)
    assert result["score"] > 0.5


def test_growth_stock_no_value():
    """High P/E, high P/B, no dividend -> negative value signal."""
    fundamentals = {"pe_ratio": 80.0, "pb_ratio": 15.0, "dividend_yield": 0.0}
    result = compute_value_score(fundamentals)
    assert result["score"] < -0.3


def test_moderate_valuation():
    """Average P/E, average P/B -> near zero."""
    fundamentals = {"pe_ratio": 20.0, "pb_ratio": 3.0, "dividend_yield": 0.02}
    result = compute_value_score(fundamentals)
    assert -0.3 <= result["score"] <= 0.3


def test_negative_pe_excluded():
    """Negative P/E (losses) -> skip P/E component, use P/B and dividend."""
    fundamentals = {"pe_ratio": -5.0, "pb_ratio": 2.0, "dividend_yield": 0.03}
    result = compute_value_score(fundamentals)
    assert result["details"]["pe_excluded"] is True


def test_missing_data():
    result = compute_value_score({})
    assert result["score"] == 0.0
