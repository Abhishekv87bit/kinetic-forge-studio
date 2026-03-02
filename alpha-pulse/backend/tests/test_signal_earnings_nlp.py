"""Tests for earnings NLP signal calculator."""

import pytest
from app.signals.earnings_nlp import compute_earnings_nlp_score


def test_positive_alignment():
    """Positive sentiment + positive earnings = aligned positive."""
    result = compute_earnings_nlp_score(
        text="Strong revenue growth exceeded expectations with record margins.",
        earnings_direction="positive",
        _mock_sentiment="positive",
    )
    assert result["score"] > 0.3


def test_deception_flag():
    """Positive sentiment + negative earnings = deception flag."""
    result = compute_earnings_nlp_score(
        text="We are incredibly optimistic about our transformative future.",
        earnings_direction="negative",
        _mock_sentiment="positive",
    )
    assert result["score"] < -0.5


def test_sandbagging_signal():
    """Negative sentiment + positive earnings = sandbagging (conservative mgmt)."""
    result = compute_earnings_nlp_score(
        text="We face significant challenges and uncertain conditions ahead.",
        earnings_direction="positive",
        _mock_sentiment="negative",
    )
    assert result["score"] > 0.0  # sandbagging is slightly positive


def test_empty_text():
    result = compute_earnings_nlp_score(text="", earnings_direction="positive")
    assert result["score"] == 0.0


def test_neutral_earnings():
    result = compute_earnings_nlp_score(
        text="The company reported results in line with expectations.",
        earnings_direction="neutral",
        _mock_sentiment="neutral",
    )
    assert -0.2 <= result["score"] <= 0.2
