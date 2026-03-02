"""Quality factor calculator -- ROE, debt-to-equity, earnings stability.

High-quality stocks have lower volatility and complement momentum (MSCI research).
Quality factor is the weakest standalone but is a crucial risk-reducer in multi-factor.

Scoring:
  ROE:     >20% = +1, 10-20% = +0.3, 5-10% = -0.3, <5% = -1
  D/E:     <0.5 = +1, 0.5-1.5 = +0.3, 1.5-3 = -0.3, >3 = -1
  EarStd:  <0.10 = +1, 0.10-0.20 = +0.3, 0.20-0.35 = -0.3, >0.35 = -1
"""


def _score_roe(roe: float | None) -> float:
    if roe is None:
        return 0.0
    if roe < 0:
        return -1.0
    if roe > 0.20:
        return 1.0
    if roe > 0.10:
        return 0.3
    if roe > 0.05:
        return -0.3
    return -1.0


def _score_debt(de: float | None) -> float:
    if de is None:
        return 0.0
    if de < 0.5:
        return 1.0
    if de < 1.5:
        return 0.3
    if de < 3.0:
        return -0.3
    return -1.0


def _score_stability(std: float | None) -> float:
    if std is None:
        return 0.0
    if std < 0.10:
        return 1.0
    if std < 0.20:
        return 0.3
    if std < 0.35:
        return -0.3
    return -1.0


def compute_quality_score(data: dict) -> dict:
    roe = data.get("roe")
    de = data.get("debt_to_equity")
    eg_std = data.get("earnings_growth_std")

    if roe is None and de is None and eg_std is None:
        return {"score": 0.0, "details": {"error": "no_quality_data"}}

    roe_s = _score_roe(roe)
    de_s = _score_debt(de)
    stab_s = _score_stability(eg_std)

    components = [s for s in [roe_s, de_s, stab_s] if s != 0.0]
    if not components:
        return {"score": 0.0, "details": {"error": "all_components_zero"}}

    avg = sum(components) / len(components)
    score = round(max(-0.8, min(0.8, avg * 0.8)), 2)

    return {
        "score": score,
        "details": {
            "roe_score": roe_s,
            "debt_score": de_s,
            "stability_score": stab_s,
            "raw_roe": roe,
            "raw_debt_to_equity": de,
            "raw_earnings_std": eg_std,
        },
    }
