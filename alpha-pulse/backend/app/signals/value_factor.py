"""Value factor calculator -- composite of P/E, P/B, dividend yield.

Based on Fama-French value factor (HML). Stocks with low price-to-fundamentals
ratios tend to outperform. MSCI enhanced value delivered 13.3% annually over 50 years.

Scoring: Each component mapped to [-1, +1] range, then averaged.
  P/E:  <12 = +1,  12-18 = +0.3,  18-30 = -0.3,  >30 = -1  (negative excluded)
  P/B:  <1.5 = +1, 1.5-3 = +0.3,  3-8 = -0.3,    >8 = -1
  Div:  >4% = +1,  2-4% = +0.3,   0.5-2% = -0.3,  <0.5% = -1
"""


def _score_pe(pe: float | None) -> tuple[float, bool]:
    if pe is None or pe <= 0:
        return 0.0, True  # excluded
    if pe < 12:
        return 1.0, False
    if pe < 18:
        return 0.3, False
    if pe < 30:
        return -0.3, False
    return -1.0, False


def _score_pb(pb: float | None) -> float:
    if pb is None or pb <= 0:
        return 0.0
    if pb < 1.5:
        return 1.0
    if pb < 3.0:
        return 0.3
    if pb < 8.0:
        return -0.3
    return -1.0


def _score_div(div_yield: float | None) -> float:
    if div_yield is None:
        return 0.0
    if div_yield > 0.04:
        return 1.0
    if div_yield > 0.02:
        return 0.3
    if div_yield > 0.005:
        return -0.3
    return -1.0


def compute_value_score(fundamentals: dict) -> dict:
    pe = fundamentals.get("pe_ratio")
    pb = fundamentals.get("pb_ratio")
    div_yield = fundamentals.get("dividend_yield")

    if pe is None and pb is None and div_yield is None:
        return {"score": 0.0, "details": {"error": "no_fundamental_data"}}

    pe_score, pe_excluded = _score_pe(pe)
    pb_score = _score_pb(pb)
    div_score = _score_div(div_yield)

    components = []
    if not pe_excluded:
        components.append(pe_score)
    components.append(pb_score)
    components.append(div_score)

    avg = sum(components) / len(components) if components else 0.0
    # Scale to [-0.8, 0.8] range (leave room for extreme signals)
    score = round(max(-0.8, min(0.8, avg * 0.8)), 2)

    return {
        "score": score,
        "details": {
            "pe_score": pe_score,
            "pb_score": pb_score,
            "div_score": div_score,
            "pe_excluded": pe_excluded,
            "raw_pe": pe,
            "raw_pb": pb,
            "raw_dividend_yield": div_yield,
        },
    }
