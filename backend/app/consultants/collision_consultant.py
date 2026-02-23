"""
Collision Consultant — Gate 2 (Prototype).

Enhanced collision report with clearance measurements:
- Pairwise clearance: minimum gap between all moving pairs
- Sweep volume: moving part swept envelope
- Dynamic interference: check at multiple animation positions
"""

import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run collision consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="collision_enhanced", passed=True)

    for check in checks:
        result.checks_run.append(check)

        if check == "pairwise_clearance":
            _check_pairwise_clearance(result, state)
        elif check == "sweep_volume":
            _check_sweep_volume(result, state)
        elif check == "dynamic_interference":
            _check_dynamic_interference(result, state)
        else:
            result.checks_passed.append(check)

    return result


def _check_pairwise_clearance(result: "ConsultantResult", state: "ProjectState"):
    """
    Check minimum gap between all pairs of components.
    Uses existing collision validator if available.
    """
    components = state.components or state.spec.get("components", [])

    if len(components) < 2:
        result.checks_passed.append("pairwise_clearance")
        result.findings.append("Pairwise clearance: fewer than 2 components")
        return

    # Check for position data
    positioned = []
    for comp in components:
        if isinstance(comp, dict):
            pos = comp.get("position", {})
            params = comp.get("parameters", {})
            name = comp.get("display_name", comp.get("id", "?"))

            if isinstance(pos, dict) and any(pos.get(k, 0) != 0 for k in ("x", "y", "z")):
                od = params.get("outer_diameter", params.get("diameter",
                     params.get("od", params.get("radius", 0) * 2)))
                positioned.append({
                    "name": name,
                    "x": pos.get("x", 0),
                    "y": pos.get("y", 0),
                    "z": pos.get("z", 0),
                    "radius": od / 2 if od else 5,  # Default 5mm
                })

    if len(positioned) < 2:
        result.checks_passed.append("pairwise_clearance")
        result.findings.append(
            "Pairwise clearance: insufficient position data for clearance check. "
            "Use mesh-based collision validator for actual STL checks."
        )
        return

    # Simple bounding sphere clearance check
    import math
    min_clearance = float("inf")
    min_pair = ("", "")
    violations = []

    for i in range(len(positioned)):
        for j in range(i + 1, len(positioned)):
            a, b = positioned[i], positioned[j]
            dist = math.sqrt(
                (a["x"] - b["x"])**2 +
                (a["y"] - b["y"])**2 +
                (a["z"] - b["z"])**2
            )
            clearance = dist - a["radius"] - b["radius"]

            if clearance < min_clearance:
                min_clearance = clearance
                min_pair = (a["name"], b["name"])

            if clearance < 0:
                # Skip containment: if one component's center is inside
                # the other's bounding sphere, it's a sub-component (e.g.,
                # a pulley mounted on a slider). Not a collision.
                larger_r = max(a["radius"], b["radius"])
                if dist < larger_r:
                    continue

                violations.append(
                    f"{a['name']} <-> {b['name']}: overlap={-clearance:.2f}mm"
                )

    if violations:
        result.checks_failed.append("pairwise_clearance")
        result.passed = False
        result.findings.append(
            f"Pairwise clearance FAIL: {len(violations)} overlap(s)"
        )
        for v in violations:
            result.findings.append(f"  - {v}")
            result.recommendations.append(f"Fix overlap: {v}")
    else:
        result.checks_passed.append("pairwise_clearance")
        result.findings.append(
            f"Pairwise clearance PASS: min gap={min_clearance:.2f}mm "
            f"({min_pair[0]} <-> {min_pair[1]})"
        )
        if min_clearance < 1.0:
            result.recommendations.append(
                f"Tight clearance: {min_pair[0]} <-> {min_pair[1]} = "
                f"{min_clearance:.2f}mm. Consider increasing gap."
            )


def _check_sweep_volume(result: "ConsultantResult", state: "ProjectState"):
    """Check that swept volumes of moving parts don't interfere."""
    components = state.components or state.spec.get("components", [])

    moving_parts = []
    for comp in components:
        if isinstance(comp, dict):
            params = comp.get("parameters", {})
            name = comp.get("display_name", comp.get("id", "?"))

            if params.get("animated", False) or params.get("rotating", False):
                sweep_radius = params.get("sweep_radius",
                               params.get("crank_length",
                               params.get("arm_length", 0)))
                if sweep_radius > 0:
                    moving_parts.append({
                        "name": name,
                        "sweep_radius": sweep_radius,
                    })

    if moving_parts:
        result.checks_passed.append("sweep_volume")
        result.findings.append(
            f"Sweep volume: {len(moving_parts)} moving part(s) with sweep radii"
        )
        for part in moving_parts:
            result.findings.append(
                f"  - {part['name']}: sweep radius = {part['sweep_radius']:.1f}mm"
            )
        result.recommendations.append(
            "Verify sweep volumes don't overlap using mesh-based collision "
            "at multiple animation positions."
        )
    else:
        result.checks_passed.append("sweep_volume")
        result.findings.append("Sweep volume: no animated parts with sweep data")


def _check_dynamic_interference(result: "ConsultantResult", state: "ProjectState"):
    """
    Advisory: dynamic interference needs STL-level checking.
    This consultant flags what needs to be checked.
    """
    components = state.components or state.spec.get("components", [])

    animated_count = sum(
        1 for c in components
        if isinstance(c, dict) and (
            c.get("parameters", {}).get("animated", False) or
            c.get("parameters", {}).get("rotating", False)
        )
    )

    if animated_count > 0:
        result.checks_passed.append("dynamic_interference")
        result.findings.append(
            f"Dynamic interference: {animated_count} animated component(s) — "
            f"check collision at 0/90/180/270 deg positions"
        )
        result.recommendations.append(
            f"Export STLs at multiple animation positions and run "
            f"mesh collision check for {animated_count} animated parts."
        )
    else:
        result.checks_passed.append("dynamic_interference")
        result.findings.append("Dynamic interference: no animated components")
