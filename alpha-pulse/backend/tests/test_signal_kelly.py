"""Kelly Criterion -- optimal bet sizing (Edward Thorp).
f* = (p * b - q) / b
where p = win probability, b = win/loss ratio, q = 1-p.

We use half-Kelly for safety (99% chance of not losing >50% of wealth).
"""

from app.signals.kelly import compute_kelly_fraction


def test_strong_edge():
    """60% win rate, 2:1 payoff -> aggressive sizing."""
    result = compute_kelly_fraction(win_rate=0.60, avg_win=200, avg_loss=100)
    assert 0.15 < result["half_kelly"] < 0.40


def test_coin_flip_no_edge():
    """50% win rate, 1:1 payoff -> zero allocation."""
    result = compute_kelly_fraction(win_rate=0.50, avg_win=100, avg_loss=100)
    assert result["half_kelly"] == 0.0


def test_losing_strategy():
    """40% win rate, 1:1 payoff -> negative Kelly (don't bet)."""
    result = compute_kelly_fraction(win_rate=0.40, avg_win=100, avg_loss=100)
    assert result["half_kelly"] == 0.0
    assert result["details"]["full_kelly"] < 0


def test_caps_at_25_percent():
    """Even with massive edge, cap at 25% of portfolio."""
    result = compute_kelly_fraction(win_rate=0.90, avg_win=500, avg_loss=50)
    assert result["half_kelly"] <= 0.25


def test_insufficient_data():
    result = compute_kelly_fraction(win_rate=None, avg_win=None, avg_loss=None)
    assert result["half_kelly"] == 0.0
