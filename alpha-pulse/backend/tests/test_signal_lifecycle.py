"""Tests for lifecycle signal calculator."""

import pytest
from app.signals.lifecycle import compute_lifecycle_score


def test_maturity_stage():
    """Maturity: operating +, investing -, financing -"""
    cashflows = [
        {"operating": 5000, "investing": -2000, "financing": -1000},
    ]
    result = compute_lifecycle_score(cashflows)
    assert result["score"] == 0.7
    assert result["stage"] == "maturity"


def test_growth_stage():
    """Growth: operating +, investing -, financing +"""
    cashflows = [
        {"operating": 3000, "investing": -4000, "financing": 2000},
    ]
    result = compute_lifecycle_score(cashflows)
    assert result["score"] == 0.4
    assert result["stage"] == "growth"


def test_introduction_stage():
    """Introduction: operating -, investing -, financing +"""
    cashflows = [
        {"operating": -1000, "investing": -2000, "financing": 5000},
    ]
    result = compute_lifecycle_score(cashflows)
    assert result["score"] == -0.5
    assert result["stage"] == "introduction"


def test_decline_stage():
    """Decline: operating -, investing +, financing mixed"""
    cashflows = [
        {"operating": -500, "investing": 1000, "financing": -200},
    ]
    result = compute_lifecycle_score(cashflows)
    assert result["score"] == -0.8
    assert result["stage"] == "decline"


def test_empty_cashflows_returns_zero():
    result = compute_lifecycle_score([])
    assert result["score"] == 0.0
    assert result["stage"] == "unknown"


def test_multiple_quarters_uses_latest():
    cashflows = [
        {"operating": -1000, "investing": -2000, "financing": 5000},  # intro (older)
        {"operating": 5000, "investing": -2000, "financing": -1000},  # maturity (latest)
    ]
    result = compute_lifecycle_score(cashflows)
    assert result["stage"] == "maturity"
