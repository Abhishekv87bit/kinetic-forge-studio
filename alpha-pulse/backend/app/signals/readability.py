"""10-K readability scoring -- Gunning Fog index + Loughran-McDonald words.

The management obfuscation hypothesis (Li 2008): firms with lower earnings
produce harder-to-read annual reports. Increasing complexity = red flag.
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

# Loughran-McDonald negative/uncertainty word lists (subset -- top 50 each)
_NEGATIVE_WORDS = {
    "loss", "losses", "decline", "declined", "adverse", "adversely", "impairment",
    "impaired", "litigation", "default", "defaults", "restructuring", "downturn",
    "penalty", "penalties", "violation", "violations", "terminated", "termination",
    "unfavorable", "weakness", "deterioration", "deteriorated", "damage", "damages",
    "shutdown", "closing", "closings", "complaint", "complaints", "deficit",
    "deficiency", "deficiencies", "delinquent", "delinquency", "fraud", "fraudulent",
    "lawsuit", "lawsuits", "liability", "liabilities", "negative", "negatively",
    "inability", "unable", "failure", "failed", "breach", "breaches",
}

_UNCERTAINTY_WORDS = {
    "approximately", "assume", "assumes", "assumption", "assumptions", "believe",
    "believes", "could", "depend", "depends", "dependent", "depending", "estimate",
    "estimated", "estimates", "expect", "expects", "expected", "fluctuate",
    "fluctuates", "fluctuation", "intend", "intends", "intention", "likely",
    "may", "might", "possible", "possibly", "predict", "predicts", "prediction",
    "probable", "probably", "project", "projected", "projections", "risk", "risks",
    "risky", "uncertain", "uncertainty", "uncertainties", "unpredictable", "variable",
}


def _count_words(text: str, word_set: set[str]) -> int:
    """Count occurrences of words from a set in text."""
    words = text.lower().split()
    return sum(1 for w in words if w.strip(".,;:!?()\"'") in word_set)


def _gunning_fog(text: str) -> float:
    """Compute Gunning Fog index. Returns 0.0 for empty text."""
    try:
        import textstat
        if not text.strip():
            return 0.0
        return textstat.gunning_fog(text)
    except Exception:
        return 0.0


def compute_readability_score(
    current_text: str,
    prior_fog: float | None = None,
) -> dict:
    """Compute readability signal from 10-K filing text.

    Args:
        current_text: Text from the current 10-K filing.
        prior_fog: Gunning Fog index from the prior year's filing (if available).

    Returns:
        Dict with 'score', 'details'.
    """
    if not current_text or not current_text.strip():
        return {
            "score": 0.0,
            "details": {"reason": "no filing text available"},
        }

    fog = _gunning_fog(current_text)
    neg_count = _count_words(current_text, _NEGATIVE_WORDS)
    unc_count = _count_words(current_text, _UNCERTAINTY_WORDS)
    word_count = len(current_text.split())

    # Normalize counts per 1000 words
    neg_per_1k = (neg_count / max(word_count, 1)) * 1000
    unc_per_1k = (unc_count / max(word_count, 1)) * 1000

    score = 0.0

    if prior_fog is not None:
        fog_delta = fog - prior_fog
        if fog_delta > 2.0:
            score = -0.5  # Significantly more complex = obfuscation signal
        elif fog_delta > 1.0:
            score = -0.2
        elif fog_delta < -2.0:
            score = 0.3   # Getting clearer = positive
        elif fog_delta < -1.0:
            score = 0.1
        # else: stable, score stays 0.0
    # Without prior_fog, we can't compute delta -- return neutral

    return {
        "score": round(score, 2),
        "details": {
            "fog_index": round(fog, 1),
            "prior_fog": prior_fog,
            "fog_delta": round(fog - prior_fog, 1) if prior_fog is not None else None,
            "negative_word_count": neg_count,
            "uncertainty_word_count": unc_count,
            "negative_per_1k": round(neg_per_1k, 1),
            "uncertainty_per_1k": round(unc_per_1k, 1),
            "word_count": word_count,
        },
    }
