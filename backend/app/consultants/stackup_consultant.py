"""
Stackup Consultant — Gate 2 (Prototype).

Wraps tolerance_stackup.py for critical dimension chains:
- Worst-case stackup: pessimistic tolerance chain
- RSS stackup: 3-sigma statistical
- Cpk check: process capability index
"""

import logging
import subprocess
import json
from typing import TYPE_CHECKING

from app.config import settings

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run stackup consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="stackup", passed=True)
    result.libraries_used.append("tolerance_stackup.py")

    for check in checks:
        result.checks_run.append(check)

        if check == "worst_case_stackup":
            _check_worst_case(result, state)
        elif check == "rss_stackup":
            _check_rss(result, state)
        elif check == "cpk_check":
            _check_cpk(result, state)
        else:
            result.checks_passed.append(check)

    return result


def _check_worst_case(result: "ConsultantResult", state: "ProjectState"):
    """Worst-case tolerance stackup: all tolerances at maximum deviation."""
    contributors = state.stackup_contributors or state.spec.get("stackup_contributors", [])

    if not contributors:
        result.checks_passed.append("worst_case_stackup")
        result.findings.append("Worst-case stackup: no tolerance contributors specified")
        return

    # Calculate worst-case
    nominal = 0.0
    worst_case_plus = 0.0
    worst_case_minus = 0.0

    for contrib in contributors:
        dim = contrib.get("nominal", 0)
        tol_plus = contrib.get("tolerance_plus", contrib.get("tolerance", 0))
        tol_minus = contrib.get("tolerance_minus", -tol_plus)
        direction = contrib.get("direction", 1)  # +1 or -1

        nominal += dim * direction
        if direction > 0:
            worst_case_plus += tol_plus
            worst_case_minus += tol_minus
        else:
            worst_case_plus += abs(tol_minus)
            worst_case_minus += -abs(tol_plus)

    target_min = state.spec.get("target_clearance_min", 0)
    wc_min = nominal + worst_case_minus
    wc_max = nominal + worst_case_plus

    passed = wc_min >= target_min
    if passed:
        result.checks_passed.append("worst_case_stackup")
        result.findings.append(
            f"Worst-case stackup PASS: [{wc_min:.3f}, {wc_max:.3f}]mm "
            f"(target min: {target_min:.3f}mm, "
            f"{len(contributors)} contributors)"
        )
    else:
        result.checks_failed.append("worst_case_stackup")
        result.passed = False
        result.findings.append(
            f"Worst-case stackup FAIL: min={wc_min:.3f}mm < "
            f"target={target_min:.3f}mm "
            f"(deficit: {target_min - wc_min:.3f}mm)"
        )
        result.recommendations.append(
            f"Worst-case stackup fails by {target_min - wc_min:.3f}mm. "
            f"Tighten tolerances or increase target clearance."
        )


def _check_rss(result: "ConsultantResult", state: "ProjectState"):
    """RSS (Root Sum Square) tolerance stackup — statistical 3-sigma."""
    import math

    contributors = state.stackup_contributors or state.spec.get("stackup_contributors", [])

    if not contributors:
        result.checks_passed.append("rss_stackup")
        result.findings.append("RSS stackup: no tolerance contributors specified")
        return

    nominal = 0.0
    sum_sq = 0.0

    for contrib in contributors:
        dim = contrib.get("nominal", 0)
        tol = contrib.get("tolerance", contrib.get("tolerance_plus", 0))
        direction = contrib.get("direction", 1)

        nominal += dim * direction
        sum_sq += tol ** 2

    rss = math.sqrt(sum_sq)
    rss_min = nominal - rss
    rss_max = nominal + rss

    target_min = state.spec.get("target_clearance_min", 0)

    if rss_min >= target_min:
        result.checks_passed.append("rss_stackup")
        result.findings.append(
            f"RSS stackup PASS: [{rss_min:.3f}, {rss_max:.3f}]mm "
            f"(target min: {target_min:.3f}mm, RSS={rss:.3f}mm)"
        )
    else:
        result.checks_failed.append("rss_stackup")
        result.passed = False
        result.findings.append(
            f"RSS stackup FAIL: min={rss_min:.3f}mm < "
            f"target={target_min:.3f}mm"
        )
        result.recommendations.append(
            f"RSS stackup fails. Tighten largest tolerance contributor "
            f"or increase clearance."
        )


def _check_cpk(result: "ConsultantResult", state: "ProjectState"):
    """
    Process capability index: Cpk >= 1.33 for production quality.
    """
    cpk = state.spec.get("cpk")
    if cpk is not None:
        if cpk >= 1.33:
            result.checks_passed.append("cpk_check")
            result.findings.append(f"Cpk PASS: {cpk:.2f} >= 1.33")
        elif cpk >= 1.0:
            result.checks_passed.append("cpk_check")
            result.findings.append(
                f"Cpk marginal: {cpk:.2f} (target >= 1.33)"
            )
            result.recommendations.append(
                f"Cpk={cpk:.2f} is marginal. Consider tighter process "
                f"control or wider tolerances for Cpk >= 1.33."
            )
        else:
            result.checks_failed.append("cpk_check")
            result.passed = False
            result.findings.append(f"Cpk FAIL: {cpk:.2f} < 1.0")
            result.recommendations.append(
                f"Cpk={cpk:.2f} indicates process cannot reliably hold "
                f"tolerances. Improve process or widen spec."
            )
    else:
        result.checks_passed.append("cpk_check")
        result.findings.append(
            "Cpk: not computed (need measured process data)"
        )
