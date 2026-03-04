"""
Aesthetics Consultant — Gate 1 (Design).

Checks for visual/artistic quality of kinetic sculptures:
- Element count: prime numbers preferred (37, 61, 271 avoid Moire)
- Proportion ratios: golden ratio, pleasing proportions
- Motion quality: smooth vs jerky assessment
- Visual balance: center of mass vs visual center
"""

import math
import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)

# Primes commonly used in kinetic art (avoid Moire patterns)
PREFERRED_PRIMES = {
    7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61,
    67, 71, 73, 79, 83, 89, 97, 101, 127, 131, 137, 139, 149,
    151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211,
    223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271,
}

GOLDEN_RATIO = (1 + math.sqrt(5)) / 2  # ~1.618


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run aesthetics consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="aesthetics", passed=True)
    spec = state.spec

    for check in checks:
        result.checks_run.append(check)

        if check == "element_count":
            _check_element_count(result, spec, state)
        elif check == "proportion_ratios":
            _check_proportions(result, spec, state)
        elif check == "motion_quality":
            _check_motion_quality(result, spec, state)
        elif check == "visual_balance":
            _check_visual_balance(result, spec, state)
        else:
            result.checks_passed.append(check)

    return result


def _is_prime(n: int) -> bool:
    """Check if n is prime."""
    if n < 2:
        return False
    if n < 4:
        return True
    if n % 2 == 0 or n % 3 == 0:
        return False
    i = 5
    while i * i <= n:
        if n % i == 0 or n % (i + 2) == 0:
            return False
        i += 6
    return True


def _check_element_count(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """
    For wave/array mechanisms, prime element counts avoid visual Moire patterns.
    Non-critical: advisory only.
    """
    mechanism = state.mechanism_type or spec.get("mechanism_type", "")
    array_types = ("wave", "wave_sculpture", "array", "grid", "matrix")

    if mechanism not in array_types:
        result.checks_passed.append("element_count")
        result.findings.append("Element count: N/A (not an array mechanism)")
        return

    count = spec.get("element_count", spec.get("num_elements",
            spec.get("grid_count", spec.get("wave_count", 0))))

    if count <= 0:
        result.checks_passed.append("element_count")
        result.findings.append("Element count: not specified")
        return

    if count in PREFERRED_PRIMES:
        result.checks_passed.append("element_count")
        result.findings.append(
            f"Element count PASS: {count} is prime (avoids Moire patterns)"
        )
    elif _is_prime(count):
        result.checks_passed.append("element_count")
        result.findings.append(
            f"Element count PASS: {count} is prime"
        )
    else:
        # Advisory, not a failure
        result.checks_passed.append("element_count")
        # Find nearest primes
        lower = count - 1
        while not _is_prime(lower) and lower > 1:
            lower -= 1
        upper = count + 1
        while not _is_prime(upper):
            upper += 1

        result.findings.append(
            f"Element count advisory: {count} is not prime. "
            f"Consider {lower} or {upper} to avoid Moire patterns."
        )
        result.recommendations.append(
            f"Consider using {lower} or {upper} elements instead of {count} "
            f"for more organic visual patterns (Margolin principle)."
        )


def _check_proportions(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """Check if key dimensions follow pleasing ratios (golden ratio, etc.)."""
    envelope = state.envelope or spec.get("envelope", {})

    width = envelope.get("width", envelope.get("x", 0))
    height = envelope.get("height", envelope.get("z", 0))
    depth = envelope.get("depth", envelope.get("y", 0))

    if not (width and height):
        result.checks_passed.append("proportion_ratios")
        result.findings.append("Proportions: no envelope dimensions to check")
        return

    ratios = []
    if width and height:
        ratio_wh = max(width, height) / min(width, height)
        ratios.append(("width:height", ratio_wh))
    if width and depth:
        ratio_wd = max(width, depth) / min(width, depth)
        ratios.append(("width:depth", ratio_wd))

    # Check closeness to golden ratio or simple ratios
    pleasant_ratios = [
        (GOLDEN_RATIO, "golden ratio (1.618)"),
        (1.0, "1:1 (square)"),
        (1.5, "3:2"),
        (2.0, "2:1"),
        (math.sqrt(2), "√2 (1.414)"),
    ]

    findings = []
    for name, ratio in ratios:
        closest_name = "none"
        closest_dist = float("inf")
        for target, target_name in pleasant_ratios:
            dist = abs(ratio - target)
            if dist < closest_dist:
                closest_dist = dist
                closest_name = target_name

        if closest_dist < 0.1:
            findings.append(f"{name} = {ratio:.3f} (near {closest_name})")
        else:
            findings.append(f"{name} = {ratio:.3f}")

    result.checks_passed.append("proportion_ratios")
    result.findings.append(
        f"Proportions: {'; '.join(findings)}"
    )


def _check_motion_quality(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """Advisory check for smooth vs jerky motion."""
    mechanism = state.mechanism_type or spec.get("mechanism_type", "")

    # Mechanisms with inherently smooth motion
    smooth_mechanisms = {"cam", "wave", "eccentric", "spiral"}
    # Mechanisms that need careful design for smooth motion
    needs_care = {"four_bar", "slider_crank", "ratchet", "geneva"}

    if mechanism in smooth_mechanisms:
        result.checks_passed.append("motion_quality")
        result.findings.append(
            f"Motion quality: '{mechanism}' typically produces smooth motion"
        )
    elif mechanism in needs_care:
        result.checks_passed.append("motion_quality")
        result.findings.append(
            f"Motion quality: '{mechanism}' needs careful link ratios for smooth motion"
        )
        # Check for cam profiles
        has_profile = spec.get("cam_profile") or spec.get("motion_profile")
        if not has_profile:
            result.recommendations.append(
                f"Consider adding a motion profile (ease-in/ease-out) "
                f"for smoother {mechanism} motion."
            )
    else:
        result.checks_passed.append("motion_quality")
        result.findings.append(
            f"Motion quality: mechanism '{mechanism}' — verify smooth operation"
        )


def _check_visual_balance(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """Check if the mechanism is visually balanced (center of mass near center)."""
    components = state.components or spec.get("components", [])

    if not components:
        result.checks_passed.append("visual_balance")
        result.findings.append("Visual balance: no components to check")
        return

    # Compute weighted center
    total_weight = 0.0
    cx, cy, cz = 0.0, 0.0, 0.0

    for comp in components:
        if isinstance(comp, dict):
            pos = comp.get("position", {})
            params = comp.get("parameters", {})

            x = pos.get("x", 0) if isinstance(pos, dict) else 0
            y = pos.get("y", 0) if isinstance(pos, dict) else 0
            z = pos.get("z", 0) if isinstance(pos, dict) else 0

            # Estimate weight from volume (rough)
            weight = params.get("weight", params.get("mass", 1.0))

            cx += x * weight
            cy += y * weight
            cz += z * weight
            total_weight += weight

    if total_weight > 0:
        cx /= total_weight
        cy /= total_weight
        cz /= total_weight

    # Compare to geometric center of envelope
    envelope = state.envelope or spec.get("envelope", {})
    env_cx = envelope.get("width", 0) / 2
    env_cy = envelope.get("depth", 0) / 2

    if env_cx > 0 and env_cy > 0:
        offset = math.sqrt((cx - env_cx)**2 + (cy - env_cy)**2)
        envelope_diag = math.sqrt(env_cx**2 + env_cy**2)
        offset_pct = (offset / envelope_diag * 100) if envelope_diag > 0 else 0

        result.checks_passed.append("visual_balance")
        result.findings.append(
            f"Visual balance: CoM at ({cx:.1f}, {cy:.1f}, {cz:.1f}), "
            f"offset {offset_pct:.0f}% from center"
        )
        if offset_pct > 30:
            result.recommendations.append(
                f"Design is visually off-center ({offset_pct:.0f}%). "
                f"Consider redistributing components for better balance."
            )
    else:
        result.checks_passed.append("visual_balance")
        result.findings.append(
            f"Visual balance: CoM at ({cx:.1f}, {cy:.1f}, {cz:.1f}) "
            f"— no envelope to compare against"
        )
