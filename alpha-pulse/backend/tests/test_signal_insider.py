"""Tests for insider trading signal calculator."""

import pytest
from app.signals.insider import compute_insider_score


def test_strong_net_buying():
    transactions = [
        {"type": "purchase", "shares": 10000, "date": "2026-02-15"},
        {"type": "purchase", "shares": 5000, "date": "2026-02-20"},
        {"type": "sale", "shares": 1000, "date": "2026-02-10"},
    ]
    result = compute_insider_score(transactions)
    assert result["score"] > 0.5
    assert result["direction"] == "net_buying"


def test_net_selling():
    transactions = [
        {"type": "sale", "shares": 50000, "date": "2026-02-15"},
        {"type": "sale", "shares": 30000, "date": "2026-02-20"},
        {"type": "purchase", "shares": 1000, "date": "2026-02-10"},
    ]
    result = compute_insider_score(transactions)
    assert result["score"] < -0.3
    assert result["direction"] == "net_selling"


def test_no_transactions():
    result = compute_insider_score([])
    assert result["score"] == 0.0
    assert result["direction"] == "no_activity"


def test_cluster_buying_bonus():
    """Multiple insiders buying within 14 days gets cluster bonus."""
    transactions = [
        {"type": "purchase", "shares": 5000, "date": "2026-02-15", "insider": "CEO"},
        {"type": "purchase", "shares": 3000, "date": "2026-02-18", "insider": "CFO"},
        {"type": "purchase", "shares": 2000, "date": "2026-02-22", "insider": "COO"},
    ]
    result = compute_insider_score(transactions)
    assert result["score"] >= 0.8  # cluster bonus pushes score higher
    assert result["cluster_detected"] is True
