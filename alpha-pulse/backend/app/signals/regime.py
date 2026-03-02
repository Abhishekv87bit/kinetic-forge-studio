"""Macro regime detection -- Dalio's All Weather 4-quadrant model.

Classifies current environment based on GDP trend and CPI trend:
  gdp_trend > 0, cpi_trend < 0  -> goldilocks  (best for stocks)
  gdp_trend > 0, cpi_trend > 0  -> reflation   (commodities, gold, TIPS)
  gdp_trend < 0, cpi_trend > 0  -> stagflation  (gold, cash -- worst for stocks)
  gdp_trend < 0, cpi_trend < 0  -> deflation    (bonds)

yield_curve < 0 (inverted) adds recession risk penalty.
"""

# Asset-regime affinity matrix: {asset_class: {regime: score}}
_REGIME_SCORES = {
    "equity": {
        "goldilocks": 0.6,
        "reflation": 0.2,
        "deflation": -0.2,
        "stagflation": -0.6,
        "unknown": 0.0,
    },
    "crypto": {
        "goldilocks": 0.3,
        "reflation": 0.4,  # behaves like digital gold
        "deflation": -0.3,
        "stagflation": -0.2,
        "unknown": 0.0,
    },
    "commodity": {
        "goldilocks": 0.1,
        "reflation": 0.7,
        "deflation": -0.5,
        "stagflation": 0.3,
        "unknown": 0.0,
    },
    "forex": {
        "goldilocks": 0.0,
        "reflation": -0.1,
        "deflation": 0.1,
        "stagflation": -0.1,
        "unknown": 0.0,
    },
}


def detect_regime(macro: dict) -> dict:
    """Classify macro environment into one of 4 quadrants."""
    gdp = macro.get("gdp_trend")
    cpi = macro.get("cpi_trend")
    yc = macro.get("yield_curve", 0)

    if gdp is None or cpi is None:
        return {"regime": "unknown", "details": {"error": "missing_macro_data"}}

    growth_rising = gdp > 0
    inflation_rising = cpi > 0

    if growth_rising and not inflation_rising:
        regime = "goldilocks"
    elif growth_rising and inflation_rising:
        regime = "reflation"
    elif not growth_rising and inflation_rising:
        regime = "stagflation"
    else:
        regime = "deflation"

    return {
        "regime": regime,
        "details": {
            "gdp_trend": gdp,
            "cpi_trend": cpi,
            "yield_curve": yc,
            "inverted_curve": yc < 0,
            "recession_risk": yc < -0.2,
        },
    }


def score_asset_for_regime(asset_class: str, regime: str) -> float:
    """Return affinity score for an asset class in the given regime."""
    scores = _REGIME_SCORES.get(asset_class, _REGIME_SCORES["equity"])
    return scores.get(regime, 0.0)
