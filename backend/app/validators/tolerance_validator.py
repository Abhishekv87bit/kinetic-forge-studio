"""
Tolerance validator -- wraps production_pipeline ISO 286 + stackup tools.

Checks shaft/hole fits and runs tolerance stackup analysis.
Triggered in Gate 2 (PROTOTYPE).
"""

import asyncio
import json
import logging
from dataclasses import dataclass, field

from app.config import settings

logger = logging.getLogger(__name__)


@dataclass
class FitResult:
    """Result of ISO 286 fit check for a single pair."""
    shaft_name: str
    hole_name: str
    nominal: float
    shaft_tolerance: dict | None = None
    hole_tolerance: dict | None = None
    fit_type: str = ""  # clearance, transition, interference
    min_clearance: float = 0.0
    max_clearance: float = 0.0
    passed: bool = True
    notes: str = ""


@dataclass
class StackupResult:
    """Result of tolerance stackup analysis."""
    worst_case: float = 0.0
    rss: float = 0.0
    monte_carlo_mean: float = 0.0
    monte_carlo_std: float = 0.0
    contributors: list[dict] = field(default_factory=list)
    passed: bool = True


@dataclass
class ToleranceValidationResult:
    """Combined tolerance validation result."""
    passed: bool
    fits: list[FitResult] = field(default_factory=list)
    stackup: StackupResult | None = None
    warnings: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)


async def check_fits(pairs: list[dict]) -> list[FitResult]:
    """
    Check ISO 286 fits for shaft/hole pairs.

    Args:
        pairs: List of {"shaft": "8h7", "hole": "8H7", "nominal": 8.0}
    """
    results = []
    script = settings.iso286_script

    if not script.exists():
        logger.warning("iso286_lookup.py not found at %s", script)
        return results

    for pair in pairs:
        shaft = pair.get("shaft", "")
        hole = pair.get("hole", "")
        nominal = pair.get("nominal", 0)

        try:
            proc = await asyncio.create_subprocess_exec(
                "python", str(script),
                "--shaft", shaft,
                "--hole", hole,
                "--nominal", str(nominal),
                "--json",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=10)
            stdout_text = stdout.decode("utf-8", errors="replace")

            try:
                data = json.loads(stdout_text)
                results.append(FitResult(
                    shaft_name=shaft,
                    hole_name=hole,
                    nominal=nominal,
                    shaft_tolerance=data.get("shaft"),
                    hole_tolerance=data.get("hole"),
                    fit_type=data.get("fit_type", "unknown"),
                    min_clearance=data.get("min_clearance", 0),
                    max_clearance=data.get("max_clearance", 0),
                    passed=data.get("passed", True),
                    notes=data.get("notes", ""),
                ))
            except json.JSONDecodeError:
                results.append(FitResult(
                    shaft_name=shaft, hole_name=hole, nominal=nominal,
                    passed=proc.returncode == 0,
                    notes=stdout_text[:200],
                ))

        except asyncio.TimeoutError:
            results.append(FitResult(
                shaft_name=shaft, hole_name=hole, nominal=nominal,
                passed=False, notes="iso286_lookup.py timed out",
            ))
        except Exception as e:
            results.append(FitResult(
                shaft_name=shaft, hole_name=hole, nominal=nominal,
                passed=False, notes=str(e),
            ))

    return results


async def stackup_analysis(contributors: list[dict]) -> StackupResult:
    """
    Run tolerance stackup analysis.

    Args:
        contributors: List of {"name": "...", "nominal": N, "tolerance": T}
    """
    script = settings.tolerance_stackup_script

    if not script.exists():
        logger.warning("tolerance_stackup.py not found at %s", script)
        return StackupResult(passed=True)

    try:
        input_json = json.dumps({"contributors": contributors})
        proc = await asyncio.create_subprocess_exec(
            "python", str(script), "--json", "--input", input_json,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=30)
        stdout_text = stdout.decode("utf-8", errors="replace")

        try:
            data = json.loads(stdout_text)
            return StackupResult(
                worst_case=data.get("worst_case", 0),
                rss=data.get("rss", 0),
                monte_carlo_mean=data.get("monte_carlo_mean", 0),
                monte_carlo_std=data.get("monte_carlo_std", 0),
                contributors=data.get("contributors", []),
                passed=data.get("passed", True),
            )
        except json.JSONDecodeError:
            return StackupResult(passed=proc.returncode == 0)

    except asyncio.TimeoutError:
        return StackupResult(passed=False)
    except Exception:
        return StackupResult(passed=False)


async def validate(
    pairs: list[dict] | None = None,
    stackup_contributors: list[dict] | None = None,
) -> ToleranceValidationResult:
    """Run combined tolerance validation."""
    result = ToleranceValidationResult(passed=True)

    if pairs:
        result.fits = await check_fits(pairs)
        if any(not f.passed for f in result.fits):
            result.passed = False

    if stackup_contributors:
        result.stackup = await stackup_analysis(stackup_contributors)
        if result.stackup and not result.stackup.passed:
            result.passed = False

    return result
