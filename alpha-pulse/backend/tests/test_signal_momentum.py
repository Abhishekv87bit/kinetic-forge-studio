"""Momentum factor: 12-month return minus 1-month return (Jegadeesh & Titman 1993).
Uses trailing price data from yfinance."""

import pytest

from app.signals.momentum import compute_momentum_score


def test_strong_positive_momentum():
    """Stock up 40% over 12mo, only 2% in last month -> strong trend."""
    prices = {"price_12m_ago": 100, "price_1m_ago": 138, "price_now": 140}
    result = compute_momentum_score(prices)
    assert result["score"] > 0.5
    assert result["details"]["momentum_12m"] == pytest.approx(0.4, abs=0.01)
    assert result["details"]["momentum_1m"] == pytest.approx(0.0145, abs=0.01)


def test_negative_momentum():
    """Stock down 20% over 12mo."""
    prices = {"price_12m_ago": 100, "price_1m_ago": 82, "price_now": 80}
    result = compute_momentum_score(prices)
    assert result["score"] <= -0.3


def test_reversal_signal():
    """Stock up 30% in 12mo but down 10% last month -> weakening."""
    prices = {"price_12m_ago": 100, "price_1m_ago": 144, "price_now": 130}
    result = compute_momentum_score(prices)
    # Should be weaker than pure positive momentum
    assert result["score"] < 0.5
    assert result["details"]["reversal_flag"] is True


def test_missing_prices_returns_zero():
    result = compute_momentum_score({})
    assert result["score"] == 0.0


def test_flat_market():
    prices = {"price_12m_ago": 100, "price_1m_ago": 101, "price_now": 100}
    result = compute_momentum_score(prices)
    assert -0.1 <= result["score"] <= 0.1
