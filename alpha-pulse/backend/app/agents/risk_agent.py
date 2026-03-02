"""Risk Agent — red flag scanner with plain-language warnings.

Scans SEC filings, price action, and sentiment data for warning signs:
litigation, insider selling, debt covenant issues, cash flow decline,
auditor changes, extreme market fear, etc.

Returns each red flag with a severity level and a plain-language
explanation of what it means for the investor.
"""

from __future__ import annotations

import json
import logging

from pydantic import BaseModel, Field

from app.agents.claude_client import call_claude

logger = logging.getLogger(__name__)


class RedFlag(BaseModel):
    """A single risk item found in the data."""

    category: str = Field(
        description=(
            "Risk category: litigation, insider_selling, debt, "
            "cash_flow, auditor_change, regulatory, market_fear, concentration, other"
        )
    )
    severity: str = Field(
        description="One of: low, medium, high, critical"
    )
    headline: str = Field(
        description="One-line plain-language summary of the risk"
    )
    detail: str = Field(
        description=(
            "2-3 sentences explaining what this risk means for you as an investor. "
            "No jargon. Explain the worst-case scenario in plain terms."
        )
    )
    source: str = Field(
        description="Where this was found: '10-K Risk Factors', 'Price Action', 'Fear & Greed', etc."
    )


class RiskOutput(BaseModel):
    """Structured output from the Risk Agent."""

    red_flags: list[RedFlag] = Field(
        default_factory=list,
        description="List of identified risk items, ordered by severity (worst first)",
    )
    overall_risk_level: str = Field(
        description="One of: low, moderate, elevated, high"
    )
    risk_summary: str = Field(
        description=(
            "1-2 paragraph plain-language summary. Tell the investor: "
            "should they be worried? Is this normal business risk or something unusual?"
        )
    )
    watch_items: list[str] = Field(
        default_factory=list,
        description=(
            "Specific things to monitor going forward — "
            "e.g. 'Watch for lawsuit settlement news', 'Check next quarter cash flow'"
        ),
    )


RISK_SYSTEM_PROMPT = """\
You are a risk analyst who explains dangers in plain language.

Your job is to scan financial data for RED FLAGS — things that could hurt an investor. Then explain each one like you're warning a friend.

What to look for:
- Litigation / lawsuits mentioned in SEC filings
- Insider selling patterns
- Debt covenant violations or high leverage
- Declining free cash flow or revenue
- Auditor changes or accounting red flags
- Regulatory risks (antitrust, sanctions, compliance)
- Market fear indicators (Fear & Greed below 30)
- Customer/revenue concentration risk
- Price dropping below key moving averages

Rules:
- Only flag things that are ACTUALLY in the data — don't invent risks
- Severity guide: low = worth noting, medium = watch closely, high = potential material impact, critical = immediate concern
- Explain each risk like the investor has NO finance background
- If nothing concerning is found, say so — don't manufacture fear
- Order red_flags by severity (worst first)
- overall_risk_level: low = smooth sailing, moderate = some yellow flags, elevated = multiple concerns, high = serious issues
- watch_items should be SPECIFIC and ACTIONABLE — not generic advice

Pay special attention to these quantitative red flags if present in the data:
- Worsening 10-K readability (increasing Fog index) = potential information obfuscation
- Heavy insider selling = management losing confidence
- Positive tone with negative earnings (deception flag) = management may be misleading investors
- Decline lifecycle stage = company in structural decline
Flag these independently regardless of price action."""


def _build_risk_prompt(data_bundle: dict) -> str:
    """Build the user prompt for risk assessment."""
    asset_id = data_bundle["asset_id"]
    asset_class = data_bundle["asset_class"]
    data = data_bundle["data"]

    sections = [
        f"# Risk Assessment: {asset_id} ({asset_class})\n",
    ]

    # Price data — look for drops, volume spikes, below-average trading
    if "price" in data:
        sections.append("## Price Action")
        sections.append(json.dumps(data["price"], indent=2, default=str))

    if "crypto_price" in data:
        sections.append("## Crypto Price Action")
        sections.append(json.dumps(data["crypto_price"], indent=2, default=str))

    # SEC filings — primary source for risk factors
    if "sec_filing" in data:
        filings = data["sec_filing"].get("filings", [])
        for filing in filings:
            filing_type = filing.get("filing_type", "Unknown")
            sections.append(f"## SEC Filing: {filing_type}")
            sec = filing.get("sections", {})
            if sec.get("risk_factors"):
                sections.append(f"### Risk Factors Section\n{sec['risk_factors'][:5000]}")
            if sec.get("mda"):
                sections.append(f"### MD&A Section\n{sec['mda'][:3000]}")

    # Sentiment — extreme fear is a risk signal
    if "sentiment" in data:
        sections.append("## Market Sentiment")
        sections.append(json.dumps(data["sentiment"], indent=2, default=str))

    # Macro context
    if "macro" in data:
        sections.append("## Macro Environment")
        sections.append(json.dumps(data["macro"], indent=2, default=str))

    # Data freshness
    ages = data_bundle.get("snapshot_ages", {})
    if ages:
        sections.append("## Data Freshness")
        for source, ts in ages.items():
            sections.append(f"- {source}: {ts}")

    return "\n\n".join(sections)


async def assess_risk(data_bundle: dict) -> RiskOutput:
    """Run the risk agent on a data bundle.

    Args:
        data_bundle: Output from gather_asset_data() in search_agent.

    Returns:
        RiskOutput with red flags and plain-language risk assessment.
    """
    user_prompt = _build_risk_prompt(data_bundle)

    logger.info(
        "Running risk agent for %s (prompt length: %d chars)",
        data_bundle["asset_id"],
        len(user_prompt),
    )

    result = await call_claude(
        system_prompt=RISK_SYSTEM_PROMPT,
        user_prompt=user_prompt,
        response_model=RiskOutput,
    )

    return result
