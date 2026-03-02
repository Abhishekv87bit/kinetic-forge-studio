"""Momentum factor calculator (Jegadeesh & Titman 1993).

12-month return minus 1-month return = "residual momentum".
Avoids short-term reversal noise while capturing medium-term trend.

Score mapping:
  momentum > 0.20  -> +0.7 (strong trend)
  momentum > 0.05  -> +0.3 (mild trend)
  momentum < -0.20 -> -0.7 (strong decline)
  momentum < -0.05 -> -0.3 (mild decline)
  else              -> 0.0  (flat)

Evidence: MSCI 50-year study -- momentum factor delivered 13.5% annually.
"""


def compute_momentum_score(prices: dict) -> dict:
    p_now = prices.get("price_now")
    p_12m = prices.get("price_12m_ago")
    p_1m = prices.get("price_1m_ago")

    if not all(v and v > 0 for v in [p_now, p_12m, p_1m]):
        return {"score": 0.0, "details": {"error": "insufficient_price_data"}}

    mom_12m = (p_now - p_12m) / p_12m
    mom_1m = (p_now - p_1m) / p_1m
    residual = mom_12m - mom_1m  # strip short-term noise

    # Reversal detection: 12m positive but 1m sharply negative
    reversal_flag = mom_12m > 0.10 and mom_1m < -0.05

    # Score mapping
    if residual > 0.20:
        score = 0.7
    elif residual > 0.05:
        score = 0.3
    elif residual < -0.20:
        score = -0.7
    elif residual < -0.05:
        score = -0.3
    else:
        score = 0.0

    # Penalize reversals
    if reversal_flag:
        score *= 0.5

    return {
        "score": round(score, 2),
        "details": {
            "momentum_12m": round(mom_12m, 4),
            "momentum_1m": round(mom_1m, 4),
            "residual_momentum": round(residual, 4),
            "reversal_flag": reversal_flag,
        },
    }
