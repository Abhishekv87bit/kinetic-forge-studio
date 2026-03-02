"""Earnings call/press release NLP -- tone surprise detection.

Uses FinBERT for sentiment classification, then compares tone against
earnings direction to detect alignment, sandbagging, or deception.
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

# Lazy-loaded FinBERT pipeline (heavy -- ~500MB model)
_finbert_pipeline = None


def _get_finbert():
    """Lazy-load FinBERT pipeline."""
    global _finbert_pipeline
    if _finbert_pipeline is None:
        try:
            from transformers import pipeline
            _finbert_pipeline = pipeline(
                "sentiment-analysis",
                model="ProsusAI/finbert",
                truncation=True,
                max_length=512,
            )
        except Exception:
            logger.warning("FinBERT not available -- falling back to keyword sentiment")
            _finbert_pipeline = "unavailable"
    return _finbert_pipeline


def _keyword_sentiment(text: str) -> str:
    """Simple keyword-based fallback sentiment."""
    text_lower = text.lower()
    pos = sum(1 for w in ["strong", "growth", "exceeded", "record", "optimistic", "positive", "beat"] if w in text_lower)
    neg = sum(1 for w in ["decline", "loss", "weak", "challenges", "uncertain", "negative", "miss"] if w in text_lower)
    if pos > neg + 1:
        return "positive"
    elif neg > pos + 1:
        return "negative"
    return "neutral"


def compute_earnings_nlp_score(
    text: str,
    earnings_direction: str = "neutral",
    _mock_sentiment: str | None = None,
) -> dict:
    """Compute earnings NLP signal from press release or earnings call text.

    Args:
        text: Earnings press release or call transcript text.
        earnings_direction: "positive", "negative", or "neutral" based on EPS surprise.
        _mock_sentiment: For testing -- skip FinBERT and use this sentiment directly.

    Returns:
        Dict with 'score', 'details'.
    """
    if not text or not text.strip():
        return {"score": 0.0, "details": {"reason": "no earnings text available"}}

    # Get sentiment
    if _mock_sentiment is not None:
        sentiment = _mock_sentiment
        confidence = 0.95
    else:
        pipe = _get_finbert()
        if pipe == "unavailable":
            sentiment = _keyword_sentiment(text)
            confidence = 0.5
        else:
            try:
                result = pipe(text[:512])[0]
                sentiment = result["label"].lower()
                confidence = result["score"]
            except Exception:
                sentiment = _keyword_sentiment(text)
                confidence = 0.5

    # Tone surprise scoring
    score = 0.0
    tone_match = "aligned"

    if sentiment == "positive" and earnings_direction == "positive":
        score = 0.5
        tone_match = "aligned_positive"
    elif sentiment == "negative" and earnings_direction == "negative":
        score = -0.3
        tone_match = "aligned_negative"
    elif sentiment == "positive" and earnings_direction == "negative":
        score = -0.7  # Deception flag: positive tone hiding bad results
        tone_match = "deception_flag"
    elif sentiment == "negative" and earnings_direction == "positive":
        score = 0.3  # Sandbagging: conservative management = actually positive
        tone_match = "sandbagging"
    elif sentiment == "neutral":
        score = 0.0
        tone_match = "neutral"
    elif earnings_direction == "neutral":
        score = 0.1 if sentiment == "positive" else -0.1
        tone_match = "neutral_earnings"

    return {
        "score": round(score, 2),
        "details": {
            "sentiment": sentiment,
            "sentiment_confidence": round(confidence, 3),
            "earnings_direction": earnings_direction,
            "tone_match": tone_match,
        },
    }
