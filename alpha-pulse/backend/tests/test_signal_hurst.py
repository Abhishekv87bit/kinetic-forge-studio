"""Hurst exponent: detect if a price series is trending, mean-reverting, or random.
H > 0.5 -> trending (momentum works)
H = 0.5 -> random walk (no edge)
H < 0.5 -> mean-reverting (contrarian works)

Mandelbrot proved markets are NOT random walks -- H is rarely exactly 0.5.
"""

import numpy as np
from app.signals.hurst import compute_hurst_score


def test_trending_series():
    """Synthetic uptrend -> H > 0.5 -> positive score."""
    np.random.seed(42)
    # Cumulative sum of positive-biased random walk = trending
    prices = np.cumsum(np.random.normal(0.5, 1, 200)) + 100
    result = compute_hurst_score(prices.tolist())
    assert result["score"] > 0
    assert result["details"]["hurst"] > 0.5


def test_mean_reverting_series():
    """Synthetic oscillation -> H < 0.5 -> negative score (contrarian signal)."""
    prices = [100 + 5 * ((-1) ** i) + np.random.normal(0, 0.5) for i in range(200)]
    result = compute_hurst_score(prices)
    assert result["score"] < 0
    assert result["details"]["hurst"] < 0.5


def test_random_walk():
    """Pure random walk -> H ~ 0.5 -> near-zero score."""
    np.random.seed(123)
    prices = np.cumsum(np.random.normal(0, 1, 500)) + 100
    result = compute_hurst_score(prices.tolist())
    assert -0.2 <= result["score"] <= 0.2


def test_too_few_prices():
    result = compute_hurst_score([100, 101, 102])
    assert result["score"] == 0.0
    assert "error" in result["details"]


def test_empty_prices():
    result = compute_hurst_score([])
    assert result["score"] == 0.0
