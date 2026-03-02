"""Tests for readability signal calculator."""

import pytest
from app.signals.readability import compute_readability_score


def test_increasing_complexity_negative():
    result = compute_readability_score(
        current_text="This is a complex obfuscatory methodological implementation.",
        prior_fog=15.0,
    )
    # If current fog is significantly higher than prior, score should be negative
    assert result["score"] <= 0.0


def test_stable_readability_neutral():
    text = "The company reported revenue growth in the quarter."
    # First get the actual fog so we can set prior_fog close to it
    baseline = compute_readability_score(current_text=text, prior_fog=None)
    actual_fog = baseline["details"]["fog_index"]
    # Now test with prior_fog close to actual (small delta = neutral)
    result = compute_readability_score(current_text=text, prior_fog=actual_fog)
    assert -0.2 <= result["score"] <= 0.2


def test_no_prior_fog_returns_neutral():
    result = compute_readability_score(
        current_text="The company reported strong results this quarter.",
        prior_fog=None,
    )
    assert result["score"] == 0.0
    assert "fog_index" in result["details"]


def test_empty_text_returns_zero():
    result = compute_readability_score(current_text="", prior_fog=15.0)
    assert result["score"] == 0.0


def test_negative_sentiment_words_detected():
    text = "Risk uncertainty litigation loss decline deterioration negative adverse"
    result = compute_readability_score(current_text=text, prior_fog=None)
    assert result["details"]["negative_word_count"] > 0
