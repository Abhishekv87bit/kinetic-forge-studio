"""Hurst exponent calculator -- R/S (rescaled range) analysis.

Mandelbrot's key insight: market returns follow power laws, not bell curves.
The Hurst exponent reveals hidden structure:

  H > 0.5 -> persistent (trending) -- momentum strategies work
  H = 0.5 -> random walk -- no statistical edge
  H < 0.5 -> anti-persistent (mean-reverting) -- contrarian strategies work

Score mapping:
  H > 0.65 -> +0.5 (strong trend)
  H > 0.55 -> +0.2 (mild trend)
  H < 0.35 -> -0.5 (strong mean reversion)
  H < 0.45 -> -0.2 (mild mean reversion)
  else     -> 0.0 (random)

Requires at least 50 price observations for statistical validity.
"""

import math

_MIN_OBSERVATIONS = 50


def _rescaled_range(series: list[float], n: int) -> float:
    """Compute R/S statistic for a subseries of length n."""
    num_subseries = len(series) // n
    if num_subseries == 0:
        return 0.0

    rs_values = []
    for i in range(num_subseries):
        subseries = series[i * n : (i + 1) * n]
        mean = sum(subseries) / len(subseries)
        deviations = [x - mean for x in subseries]
        cumulative = []
        s = 0
        for d in deviations:
            s += d
            cumulative.append(s)
        r = max(cumulative) - min(cumulative)
        std = (sum(d * d for d in deviations) / len(deviations)) ** 0.5
        if std > 0:
            rs_values.append(r / std)

    return sum(rs_values) / len(rs_values) if rs_values else 0.0


def _estimate_hurst(prices: list[float]) -> float:
    """Estimate Hurst exponent via R/S analysis on log returns."""
    if len(prices) < _MIN_OBSERVATIONS:
        return 0.5  # insufficient data -> assume random

    # Compute log returns
    returns = [
        math.log(prices[i] / prices[i - 1])
        for i in range(1, len(prices))
        if prices[i - 1] > 0 and prices[i] > 0
    ]
    if len(returns) < _MIN_OBSERVATIONS:
        return 0.5

    # R/S analysis at multiple scales
    ns = []
    rs = []
    n = 10
    while n <= len(returns) // 2:
        rs_val = _rescaled_range(returns, n)
        if rs_val > 0:
            ns.append(math.log(n))
            rs.append(math.log(rs_val))
        n = int(n * 1.5)

    if len(ns) < 3:
        return 0.5

    # Linear regression: log(R/S) = H * log(n) + c
    n_mean = sum(ns) / len(ns)
    rs_mean = sum(rs) / len(rs)
    num = sum((ns[i] - n_mean) * (rs[i] - rs_mean) for i in range(len(ns)))
    den = sum((ns[i] - n_mean) ** 2 for i in range(len(ns)))
    h = num / den if den > 0 else 0.5

    return max(0.0, min(1.0, h))


def compute_hurst_score(prices: list[float]) -> dict:
    if len(prices) < _MIN_OBSERVATIONS:
        return {"score": 0.0, "details": {"error": "need_50_observations_minimum"}}

    h = _estimate_hurst(prices)

    if h > 0.65:
        score = 0.5
    elif h > 0.55:
        score = 0.2
    elif h < 0.35:
        score = -0.5
    elif h < 0.45:
        score = -0.2
    else:
        score = 0.0

    regime = "trending" if h > 0.55 else "mean_reverting" if h < 0.45 else "random"

    return {
        "score": score,
        "details": {
            "hurst": round(h, 4),
            "regime": regime,
            "observations": len(prices),
            "interpretation": f"H={h:.3f} -> {regime}",
        },
    }
