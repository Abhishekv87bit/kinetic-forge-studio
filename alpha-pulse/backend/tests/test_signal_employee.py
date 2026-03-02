"""Tests for employee sentiment signal calculator."""

import pytest
from app.signals.employee_sentiment import compute_employee_score


def test_rising_trend_positive():
    result = compute_employee_score(current_rating=4.4, prior_rating=4.0)
    assert result["score"] > 0.3
    assert result["trend"] == "rising"


def test_falling_trend_negative():
    result = compute_employee_score(current_rating=3.2, prior_rating=3.8)
    assert result["score"] < -0.3
    assert result["trend"] == "falling"


def test_stable_high_mildly_positive():
    result = compute_employee_score(current_rating=4.3, prior_rating=4.3)
    assert result["score"] > 0.0
    assert result["trend"] == "stable_high"


def test_stable_low_mildly_negative():
    result = compute_employee_score(current_rating=2.8, prior_rating=2.8)
    assert result["score"] < 0.0
    assert result["trend"] == "stable_low"


def test_no_data_returns_zero():
    result = compute_employee_score(current_rating=None, prior_rating=None)
    assert result["score"] == 0.0
