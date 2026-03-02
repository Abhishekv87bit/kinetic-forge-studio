"""Analyst Agent — KPI extraction + plain-language insights.

Takes a data bundle from the Search Agent, sends it to Claude,
and returns structured output that combines raw metrics WITH
actionable insights in simple language a non-finance person can act on.
"""

from __future__ import annotations

import json
import logging
from typing import Optional

from pydantic import BaseModel, Field

from app.agents.claude_client import call_claude

logger = logging.getLogger(__name__)


class Insight(BaseModel):
    """A single plain-language insight derived from the data."""

    headline: str = Field(
        description="One-line takeaway, e.g. 'Revenue is growing fast'"
    )
    detail: str = Field(
        description=(
            "2-3 sentences explaining what this means for you as an investor. "
            "No jargon. Use analogies if helpful."
        )
    )
    signal: str = Field(
        description="One of: bullish, bearish, neutral"
    )


class AnalystOutput(BaseModel):
    """Structured output from the Analyst Agent."""

    # --- Raw KPIs (for programmatic use) ---
    revenue_growth: Optional[float] = Field(
        None, description="Revenue growth rate in percent (e.g. 8.0 for 8%)"
    )
    operating_margin: Optional[float] = Field(
        None, description="Operating margin in percent (e.g. 30.1)"
    )
    key_metrics: dict = Field(
        default_factory=dict,
        description="Additional KPIs extracted from the data",
    )

    # --- Plain-language insights (for the human) ---
    insights: list[Insight] = Field(
        description=(
            "3-5 plain-language insights derived from the KPIs. "
            "Each one tells the user what a metric MEANS, not just what it IS."
        )
    )
    bottom_line: str = Field(
        description=(
            "One paragraph summary a friend would give you over coffee. "
            "No finance jargon. Answer: should I pay attention to this stock right now, and why?"
        )
    )

    # --- Strengths / Concerns (simple language) ---
    strengths: list[str] = Field(
        default_factory=list,
        description="What's going well — plain English, 2-5 bullet points",
    )
    concerns: list[str] = Field(
        default_factory=list,
        description="What could go wrong — plain English, 2-5 bullet points",
    )

    # --- Overall direction ---
    outlook: str = Field(
        description="Overall outlook: positive, neutral, or negative"
    )
    confidence_note: str = Field(
        default="",
        description=(
            "How confident is this analysis? Flag if data is stale, "
            "incomplete, or if the situation is too uncertain to call."
        )
    )


ANALYST_SYSTEM_PROMPT = """\
You are an investment research analyst who explains things in plain language.

Your job is TWO things:
1. Extract key numbers (KPIs) from the data — revenue growth, margins, price trends, etc.
2. EXPLAIN what those numbers mean in simple language that helps someone decide whether to buy, hold, or avoid.

Rules:
- Every insight must answer "so what?" — don't just state a number, explain what it means
- Use analogies and comparisons when helpful ("margins are like profit per dollar of sales")
- If something is bad, say it plainly: "This company is burning cash faster than it earns it"
- If something is good, say it plainly: "Revenue is growing and they're keeping more of each dollar"
- The bottom_line should read like advice from a smart friend, not a Wall Street report
- For outlook, use exactly one of: "positive", "neutral", "negative"
- If data is missing or stale, say so in confidence_note — don't guess
- Set KPI fields to null if the data doesn't contain that information

If the data bundle includes a QUANTITATIVE SIGNALS section, incorporate these research-backed scores into your analysis:
- Lifecycle stage (Dickinson method): Maturity/Growth = positive, Decline = negative
- Insider activity: Net buying = bullish conviction, Net selling = red flag
- 10-K readability: Increasing complexity may indicate obfuscation
- Earnings NLP: Tone vs earnings direction mismatch = deception risk
- Employee sentiment: Rising Glassdoor = leading positive indicator
Call out when quantitative signals conflict with each other or with fundamentals."""


def _build_user_prompt(data_bundle: dict) -> str:
    """Build the user prompt from a data bundle."""
    asset_id = data_bundle["asset_id"]
    asset_class = data_bundle["asset_class"]
    data = data_bundle["data"]

    sections = [
        f"# Analysis Request: {asset_id} ({asset_class})\n",
    ]

    # Price data
    if "price" in data:
        sections.append("## Market Data")
        sections.append(json.dumps(data["price"], indent=2, default=str))

    # Crypto data
    if "crypto_price" in data:
        sections.append("## Crypto Market Data")
        sections.append(json.dumps(data["crypto_price"], indent=2, default=str))

    # SEC filings
    if "sec_filing" in data:
        filings = data["sec_filing"].get("filings", [])
        for filing in filings:
            filing_type = filing.get("filing_type", "Unknown")
            sections.append(f"## SEC Filing: {filing_type}")
            sec = filing.get("sections", {})
            if sec.get("risk_factors"):
                sections.append(f"### Risk Factors\n{sec['risk_factors'][:3000]}")
            if sec.get("mda"):
                sections.append(f"### MD&A\n{sec['mda'][:3000]}")

    # Macro context
    if "macro" in data:
        sections.append("## Macro Environment")
        sections.append(json.dumps(data["macro"], indent=2, default=str))

    # Snapshot freshness
    ages = data_bundle.get("snapshot_ages", {})
    if ages:
        sections.append("## Data Freshness")
        for source, ts in ages.items():
            sections.append(f"- {source}: {ts}")

    return "\n\n".join(sections)


async def analyze_asset(data_bundle: dict) -> AnalystOutput:
    """Run the analyst agent on a data bundle.

    Args:
        data_bundle: Output from gather_asset_data() in search_agent.

    Returns:
        AnalystOutput with KPIs + plain-language insights.
    """
    user_prompt = _build_user_prompt(data_bundle)

    logger.info(
        "Running analyst agent for %s (prompt length: %d chars)",
        data_bundle["asset_id"],
        len(user_prompt),
    )

    result = await call_claude(
        system_prompt=ANALYST_SYSTEM_PROMPT,
        user_prompt=user_prompt,
        response_model=AnalystOutput,
    )

    return result
