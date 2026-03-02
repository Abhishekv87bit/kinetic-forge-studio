"""Synthesizer — evaluates Golden Rules and produces a final signal.

Loads active Golden Rules from DB. For each rule applicable to the
asset class, calls Claude with rule_prompt + agent outputs as context.
Collects per-rule evaluations, computes a weighted score, and
determines the signal type (strong_buy → strong_sell).
"""

from __future__ import annotations

import json
import logging
from typing import Optional

from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.agents.claude_client import call_claude
from app.db.models import GoldenRule

logger = logging.getLogger(__name__)


class RuleEvaluation(BaseModel):
    """Result of evaluating a single Golden Rule."""

    rule_name: str = Field(description="Name of the rule evaluated")
    rule_id: int = Field(description="DB id of the rule")
    direction: str = Field(
        description="One of: bullish, bearish, neutral"
    )
    score: float = Field(
        description="Score from -1.0 (strong sell) to +1.0 (strong buy)"
    )
    reasoning: str = Field(
        description="Plain-language explanation of why this rule scored this way"
    )


class SynthesisOutput(BaseModel):
    """Final synthesized signal from all rule evaluations."""

    rule_evaluations: list[RuleEvaluation] = Field(
        default_factory=list,
        description="Individual rule assessment results",
    )
    weighted_score: float = Field(
        description="Weighted average of rule scores (-1.0 to +1.0)"
    )
    signal_type: str = Field(
        description="One of: strong_buy, buy, hold, sell, strong_sell"
    )
    agreement_ratio: float = Field(
        description="0.0-1.0 — what fraction of rules agree on direction"
    )
    plain_summary: str = Field(
        description=(
            "2-3 paragraph plain-language summary combining all agent outputs. "
            "What's the story with this asset? What should the investor know?"
        )
    )


RULE_EVAL_SYSTEM_PROMPT = """\
You are evaluating an investment rule against data about a specific asset.

You will be given:
1. A rule description and prompt
2. Analysis from multiple agents (analyst, risk, sentiment)

Score this rule from -1.0 (strongly bearish / rule violated) to +1.0 (strongly bullish / rule satisfied).
0.0 means the rule is neutral or not applicable.

Explain your reasoning in plain language — why did this data score this way against this rule?"""


def _blend_signal_scores(rule_score: float, signal_scores: dict) -> float:
    """Blend rule-based score with quantitative signal scores.

    Formula: 0.6 * rule_score + 0.4 * avg(signal_scores)
    If no signal scores, returns rule_score unchanged.
    """
    valid_scores = [
        s["score"] for s in signal_scores.values()
        if isinstance(s.get("score"), (int, float)) and s["score"] != 0.0
    ]
    if not valid_scores:
        return rule_score

    avg_signal = sum(valid_scores) / len(valid_scores)
    blended = 0.6 * rule_score + 0.4 * avg_signal
    return max(-1.0, min(1.0, blended))


def _score_to_signal(score: float) -> str:
    """Convert weighted score to signal type."""
    if score >= 0.6:
        return "strong_buy"
    if score >= 0.2:
        return "buy"
    if score > -0.2:
        return "hold"
    if score > -0.6:
        return "sell"
    return "strong_sell"


async def load_active_rules(
    db: AsyncSession, asset_class: str
) -> list[GoldenRule]:
    """Load active Golden Rules applicable to an asset class."""
    stmt = (
        select(GoldenRule)
        .where(
            GoldenRule.active.is_(True),
            (GoldenRule.asset_class == asset_class) | (GoldenRule.asset_class.is_(None)),
        )
        .order_by(GoldenRule.weight.desc())
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def evaluate_rule(
    rule: GoldenRule,
    agent_context: dict,
) -> RuleEvaluation:
    """Evaluate a single Golden Rule against agent outputs."""
    user_prompt = (
        f"# Rule: {rule.name}\n"
        f"## Rule Description\n{rule.description}\n\n"
        f"## Rule Prompt\n{rule.rule_prompt}\n\n"
        f"## Agent Analysis Data\n"
        f"{json.dumps(agent_context, indent=2, default=str)}"
    )

    result = await call_claude(
        system_prompt=RULE_EVAL_SYSTEM_PROMPT,
        user_prompt=user_prompt,
        response_model=RuleEvaluation,
    )

    # Ensure rule metadata is correct (don't trust Claude to copy it)
    result.rule_name = rule.name
    result.rule_id = rule.id

    return result


async def synthesize(
    db: AsyncSession,
    asset_id: str,
    asset_class: str,
    agent_outputs: dict,
    signal_scores: dict | None = None,
) -> SynthesisOutput:
    """Run all applicable Golden Rules and produce a final signal.

    Args:
        db: Async database session.
        asset_id: The asset being analyzed.
        asset_class: Asset class (equity, crypto, etc).
        agent_outputs: Dict with keys 'analyst', 'risk', 'sentiment'
            containing the Pydantic model outputs (as dicts).
        signal_scores: Optional dict of quantitative signal scores to blend.

    Returns:
        SynthesisOutput with rule evaluations and final signal.
    """
    rules = await load_active_rules(db, asset_class)

    if not rules:
        logger.warning("No active rules found for %s (%s)", asset_id, asset_class)
        return SynthesisOutput(
            rule_evaluations=[],
            weighted_score=0.0,
            signal_type="hold",
            agreement_ratio=0.0,
            plain_summary=(
                f"No investment rules configured for {asset_class} assets. "
                "Add Golden Rules in the dashboard to enable signal generation."
            ),
        )

    # Evaluate each rule — track (rule, evaluation) pairs to keep alignment
    evaluated_pairs: list[tuple[GoldenRule, RuleEvaluation]] = []
    for rule in rules:
        try:
            evaluation = await evaluate_rule(rule, agent_outputs)
            evaluated_pairs.append((rule, evaluation))
        except Exception:
            logger.exception("Failed to evaluate rule '%s'", rule.name)

    evaluations = [ev for _, ev in evaluated_pairs]

    if not evaluations:
        return SynthesisOutput(
            rule_evaluations=[],
            weighted_score=0.0,
            signal_type="hold",
            agreement_ratio=0.0,
            plain_summary="All rule evaluations failed. Cannot generate a signal.",
        )

    # Compute weighted score using aligned pairs (safe even if some rules failed)
    total_weight = sum(
        rule.weight for rule, _ in evaluated_pairs if rule.weight > 0
    )
    if total_weight > 0:
        weighted_score = sum(
            rule.weight * ev.score
            for rule, ev in evaluated_pairs
        ) / total_weight
    else:
        weighted_score = sum(ev.score for ev in evaluations) / len(evaluations)

    # Clamp to [-1, 1]
    weighted_score = max(-1.0, min(1.0, weighted_score))

    # Blend with quantitative signals if available
    if signal_scores:
        weighted_score = _blend_signal_scores(weighted_score, signal_scores)

    # Agreement ratio: what fraction of rules agree on direction?
    directions = [ev.direction for ev in evaluations if ev.direction != "neutral"]
    if directions:
        from collections import Counter
        direction_counts = Counter(directions)
        majority = direction_counts.most_common(1)[0][1]
        agreement_ratio = majority / len(directions)
    else:
        agreement_ratio = 0.0

    signal_type = _score_to_signal(weighted_score)

    # Build plain summary from agent outputs
    analyst_summary = agent_outputs.get("analyst", {}).get("bottom_line", "")
    risk_summary = agent_outputs.get("risk", {}).get("risk_summary", "")
    sentiment_summary = agent_outputs.get("sentiment", {}).get("crowd_mood", "")

    plain_summary = (
        f"**Analysis:** {analyst_summary}\n\n"
        f"**Risk Check:** {risk_summary}\n\n"
        f"**Market Mood:** {sentiment_summary}"
    )

    return SynthesisOutput(
        rule_evaluations=evaluations,
        weighted_score=round(weighted_score, 3),
        signal_type=signal_type,
        agreement_ratio=round(agreement_ratio, 2),
        plain_summary=plain_summary,
    )
