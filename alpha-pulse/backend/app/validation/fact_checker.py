"""Fact Checker — programmatic verification of extracted numbers.

Compares KPIs extracted by the Analyst Agent against raw data
in DataSnapshots. Flags mismatches where Claude may have
hallucinated or misread a number.

This is purely programmatic (no Claude call) — it checks numbers,
not opinions.
"""

from __future__ import annotations

import logging
from typing import Optional

from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)


class FactMismatch(BaseModel):
    """A single fact that doesn't match the raw data."""

    field: str = Field(description="The KPI field that was checked")
    claimed_value: Optional[float] = Field(description="What the analyst agent claimed")
    actual_value: Optional[float] = Field(description="What the raw data shows")
    difference_pct: Optional[float] = Field(
        None, description="Percentage difference if both are numeric"
    )
    severity: str = Field(description="One of: minor (<5%), notable (5-20%), major (>20%)")


class FactCheckResult(BaseModel):
    """Result of fact-checking analyst output against raw data."""

    checks_run: int = Field(description="How many facts were checked")
    mismatches: list[FactMismatch] = Field(default_factory=list)
    passed: bool = Field(description="True if no major mismatches found")
    summary: str = Field(description="Plain-language summary of fact check results")


def _pct_diff(claimed: float, actual: float) -> float:
    """Calculate percentage difference."""
    if actual == 0:
        return 100.0 if claimed != 0 else 0.0
    return abs((claimed - actual) / actual) * 100


def _severity(pct: float) -> str:
    """Classify severity of a mismatch."""
    if pct < 5:
        return "minor"
    if pct < 20:
        return "notable"
    return "major"


def check_facts(
    analyst_output: dict,
    raw_data: dict,
) -> FactCheckResult:
    """Verify analyst-extracted KPIs against raw snapshot data.

    Args:
        analyst_output: Dict from AnalystOutput.model_dump().
        raw_data: The data bundle's "data" dict (raw snapshots).

    Returns:
        FactCheckResult with any mismatches flagged.
    """
    mismatches: list[FactMismatch] = []
    checks_run = 0

    price_data = raw_data.get("price", {})

    # Check key metrics against price data
    key_metrics = analyst_output.get("key_metrics", {})

    # Check if analyst mentioned a price that doesn't match
    if "close" in price_data and "close" in key_metrics:
        checks_run += 1
        try:
            claimed = float(key_metrics["close"])
            actual = float(price_data["close"])
            diff = _pct_diff(claimed, actual)
            if diff > 1:  # More than 1% off on price = flag it
                mismatches.append(FactMismatch(
                    field="close_price",
                    claimed_value=claimed,
                    actual_value=actual,
                    difference_pct=round(diff, 1),
                    severity=_severity(diff),
                ))
        except (ValueError, TypeError):
            pass

    # Check volume
    if "volume" in price_data and "volume" in key_metrics:
        checks_run += 1
        try:
            claimed_str = str(key_metrics["volume"]).upper().replace(",", "")
            # Handle "50M" style
            multiplier = 1
            if claimed_str.endswith("M"):
                multiplier = 1_000_000
                claimed_str = claimed_str[:-1]
            elif claimed_str.endswith("B"):
                multiplier = 1_000_000_000
                claimed_str = claimed_str[:-1]
            elif claimed_str.endswith("K"):
                multiplier = 1_000
                claimed_str = claimed_str[:-1]

            claimed = float(claimed_str) * multiplier
            actual = float(price_data["volume"])
            diff = _pct_diff(claimed, actual)
            if diff > 10:  # Volume can be approximate
                mismatches.append(FactMismatch(
                    field="volume",
                    claimed_value=claimed,
                    actual_value=actual,
                    difference_pct=round(diff, 1),
                    severity=_severity(diff),
                ))
        except (ValueError, TypeError):
            pass

    # Check revenue growth if from SEC filings
    sec_data = raw_data.get("sec_filing", {})
    analyst_rev_growth = analyst_output.get("revenue_growth")
    if analyst_rev_growth is not None and sec_data:
        checks_run += 1
        # We can't fully verify revenue growth without the actual numbers,
        # but we can flag if it's unreasonably high/low
        if abs(analyst_rev_growth) > 200:
            mismatches.append(FactMismatch(
                field="revenue_growth",
                claimed_value=analyst_rev_growth,
                actual_value=None,
                severity="notable",
            ))

    # Check operating margin bounds
    analyst_margin = analyst_output.get("operating_margin")
    if analyst_margin is not None:
        checks_run += 1
        if analyst_margin > 100 or analyst_margin < -100:
            mismatches.append(FactMismatch(
                field="operating_margin",
                claimed_value=analyst_margin,
                actual_value=None,
                severity="major",
            ))

    has_major = any(m.severity == "major" for m in mismatches)

    if not mismatches:
        summary = f"All {checks_run} fact checks passed. Numbers look consistent."
    elif has_major:
        summary = (
            f"Found {len(mismatches)} mismatch(es) in {checks_run} checks. "
            f"MAJOR discrepancy detected — analyst numbers may be unreliable."
        )
    else:
        summary = (
            f"Found {len(mismatches)} minor/notable mismatch(es) in {checks_run} checks. "
            f"Numbers are approximately correct but not exact."
        )

    return FactCheckResult(
        checks_run=checks_run,
        mismatches=mismatches,
        passed=not has_major,
        summary=summary,
    )
