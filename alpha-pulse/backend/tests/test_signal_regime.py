"""Regime detection: classify current macro environment into 4 quadrants.
Based on Ray Dalio's All Weather framework.

Quadrants:
  Rising growth + Rising inflation  -> "reflation" (commodities, gold)
  Rising growth + Falling inflation -> "goldilocks" (stocks)
  Falling growth + Rising inflation -> "stagflation" (gold, TIPS)
  Falling growth + Falling inflation -> "deflation" (bonds)
"""

from app.signals.regime import detect_regime, score_asset_for_regime


def test_goldilocks_regime():
    """GDP up, CPI down -> best for stocks."""
    macro = {"gdp_trend": 0.03, "cpi_trend": -0.005, "yield_curve": 0.5}
    result = detect_regime(macro)
    assert result["regime"] == "goldilocks"


def test_stagflation_regime():
    """GDP down, CPI up -> worst for stocks."""
    macro = {"gdp_trend": -0.02, "cpi_trend": 0.02, "yield_curve": -0.3}
    result = detect_regime(macro)
    assert result["regime"] == "stagflation"


def test_score_equity_in_goldilocks():
    """Equities thrive in goldilocks."""
    score = score_asset_for_regime("equity", "goldilocks")
    assert score > 0.3


def test_score_equity_in_stagflation():
    """Equities suffer in stagflation."""
    score = score_asset_for_regime("equity", "stagflation")
    assert score < -0.3


def test_score_crypto_in_reflation():
    """Crypto behaves like gold/commodities in reflation."""
    score = score_asset_for_regime("crypto", "reflation")
    assert score > 0


def test_missing_macro():
    result = detect_regime({})
    assert result["regime"] == "unknown"
