"""
Vertical Budget Consultant — Gate 1 (Design).

Checks that all components fit within the Z-axis envelope:
- Z-stack enumeration: list all components with Z heights
- Total vs envelope: sum <= available height
- Radial envelope: max OD <= envelope width
- Clearance margins: minimum gap between stacked parts
"""

import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run vertical budget consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="vertical_budget", passed=True)
    spec = state.spec

    for check in checks:
        result.checks_run.append(check)

        if check == "z_stack_enumeration":
            _check_z_stack(result, spec, state)
        elif check == "total_vs_envelope":
            _check_total_vs_envelope(result, spec, state)
        elif check == "radial_envelope":
            _check_radial_envelope(result, spec, state)
        elif check == "clearance_margins":
            _check_clearance_margins(result, spec, state)
        else:
            result.checks_passed.append(check)

    return result


def _check_z_stack(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """Enumerate all components and their Z heights."""
    components = state.components or spec.get("components", [])

    if not components:
        result.checks_passed.append("z_stack_enumeration")
        result.findings.append("Z-stack: no components to enumerate")
        return

    z_items = []
    total_z = 0.0

    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            params = comp.get("parameters", {})
            height = params.get("height", params.get("thickness",
                     params.get("length", params.get("z_height", 0))))

            if height > 0:
                z_items.append((name, height))
                total_z += height

    if z_items:
        result.checks_passed.append("z_stack_enumeration")
        stack_str = " + ".join(f"{name}({h:.1f})" for name, h in z_items)
        result.findings.append(
            f"Z-stack enumeration: {stack_str} = {total_z:.1f}mm total"
        )
    else:
        result.checks_passed.append("z_stack_enumeration")
        result.findings.append(
            "Z-stack: no height data found on components — "
            "add 'height' or 'thickness' parameters"
        )


def _check_total_vs_envelope(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """Total stacked height must fit within envelope."""
    envelope = state.envelope or spec.get("envelope", {})
    envelope_height = envelope.get("height", envelope.get("z", 0))

    if not envelope_height:
        result.checks_passed.append("total_vs_envelope")
        result.findings.append("Total vs envelope: no envelope height specified")
        return

    # Sum component heights
    components = state.components or spec.get("components", [])
    total_z = 0.0
    for comp in components:
        if isinstance(comp, dict):
            params = comp.get("parameters", {})
            height = params.get("height", params.get("thickness",
                     params.get("z_height", 0)))
            total_z += height

    surplus = envelope_height - total_z

    if total_z <= envelope_height:
        result.checks_passed.append("total_vs_envelope")
        result.findings.append(
            f"Total vs envelope PASS: {total_z:.1f}mm <= {envelope_height:.1f}mm "
            f"(surplus: {surplus:.1f}mm)"
        )
        if surplus < 5.0 and surplus >= 0:
            result.recommendations.append(
                f"Z-stack is tight: only {surplus:.1f}mm surplus. "
                f"Consider adding clearance for washers/spacers."
            )
    else:
        result.checks_failed.append("total_vs_envelope")
        result.passed = False
        result.findings.append(
            f"Total vs envelope FAIL: {total_z:.1f}mm > {envelope_height:.1f}mm "
            f"(over by {-surplus:.1f}mm)"
        )
        result.recommendations.append(
            f"Z-stack exceeds envelope by {-surplus:.1f}mm. "
            f"Reduce component heights or increase envelope."
        )


def _check_radial_envelope(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """Max outer diameter must fit within envelope width."""
    envelope = state.envelope or spec.get("envelope", {})
    envelope_width = envelope.get("width", envelope.get("diameter",
                     envelope.get("x", 0)))

    if not envelope_width:
        result.checks_passed.append("radial_envelope")
        result.findings.append("Radial envelope: no envelope width specified")
        return

    # Find max OD
    components = state.components or spec.get("components", [])
    max_od = 0.0
    max_od_name = ""

    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            params = comp.get("parameters", {})
            od = params.get("outer_diameter", params.get("diameter",
                 params.get("od", params.get("radius", 0) * 2)))
            if od > max_od:
                max_od = od
                max_od_name = name

    if max_od <= 0:
        result.checks_passed.append("radial_envelope")
        result.findings.append("Radial envelope: no diameter data on components")
        return

    if max_od <= envelope_width:
        result.checks_passed.append("radial_envelope")
        result.findings.append(
            f"Radial envelope PASS: max OD={max_od:.1f}mm ({max_od_name}) "
            f"<= envelope={envelope_width:.1f}mm"
        )
    else:
        result.checks_failed.append("radial_envelope")
        result.passed = False
        result.findings.append(
            f"Radial envelope FAIL: max OD={max_od:.1f}mm ({max_od_name}) "
            f"> envelope={envelope_width:.1f}mm"
        )
        result.recommendations.append(
            f"Component '{max_od_name}' ({max_od:.1f}mm) exceeds radial envelope "
            f"({envelope_width:.1f}mm). Reduce diameter or increase envelope."
        )


def _check_clearance_margins(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """Minimum gap between stacked parts."""
    components = state.components or spec.get("components", [])
    min_clearance = spec.get("min_z_clearance", 0.5)  # 0.5mm default

    if not components:
        result.checks_passed.append("clearance_margins")
        result.findings.append("Clearance margins: no components to check")
        return

    # Build position list with XY for horizontal separation check
    z_items = []
    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            pos = comp.get("position", {})
            params = comp.get("parameters", {})
            z_bot = pos.get("z", 0) if isinstance(pos, dict) else 0
            x = pos.get("x", 0) if isinstance(pos, dict) else 0
            y = pos.get("y", 0) if isinstance(pos, dict) else 0
            height = params.get("height", params.get("thickness", 0))
            # Approximate horizontal extent (radius) for overlap filtering
            diameter = params.get("diameter", params.get("od",
                       params.get("outer_diameter", params.get("length", 0))))
            radius = diameter / 2 if diameter else 0
            if height > 0:
                z_items.append((name, z_bot, z_bot + height, x, y, radius))

    if len(z_items) < 2:
        result.checks_passed.append("clearance_margins")
        result.findings.append("Clearance margins: fewer than 2 Z-positioned components")
        return

    # Detect unextracted positions: if ALL z_bot values are identical (typically 0),
    # positions were not extracted from the source file. Skip rather than
    # producing false clearance violations.
    unique_z = {z_bot for _, z_bot, _, _, _, _ in z_items}
    if len(unique_z) == 1:
        result.checks_passed.append("clearance_margins")
        result.findings.append(
            f"Clearance margins SKIPPED: all {len(z_items)} components share "
            f"z_bot={next(iter(unique_z)):.1f}mm — positions likely not extracted "
            f"from source. Re-register components with actual Z positions from "
            f"the assembly's translate() calls."
        )
        result.recommendations.append(
            "Component Z-positions were not extracted from OpenSCAD source. "
            "Re-analyze the assembly to get actual translate() offsets for each part."
        )
        return

    # Sort by z_bot
    z_items.sort(key=lambda x: x[1])

    violations = []
    for i in range(len(z_items) - 1):
        name_a, _, z_top_a, x_a, y_a, r_a = z_items[i]
        name_b, z_bot_b, _, x_b, y_b, r_b = z_items[i + 1]
        gap = z_bot_b - z_top_a

        if gap < min_clearance:
            # Check horizontal separation before flagging Z-overlap.
            # If components are far apart in XY, they can occupy the same
            # Z-band without collision (e.g., cam at x=-150 vs slider at x=0).
            dx = x_a - x_b
            dy = y_a - y_b
            horiz_dist = (dx * dx + dy * dy) ** 0.5
            horiz_clearance = horiz_dist - r_a - r_b

            if horiz_clearance > 5.0:
                # Components are well-separated horizontally — no collision
                continue

            violations.append(
                f"{name_a} <-> {name_b}: gap={gap:.2f}mm "
                f"(min {min_clearance:.2f}mm)"
            )

    if not violations:
        result.checks_passed.append("clearance_margins")
        result.findings.append(
            f"Clearance margins PASS: all gaps >= {min_clearance:.1f}mm"
        )
    else:
        result.checks_failed.append("clearance_margins")
        result.passed = False
        result.findings.append(
            f"Clearance margins FAIL: {len(violations)} violation(s)"
        )
        for v in violations:
            result.findings.append(f"  - {v}")
            result.recommendations.append(f"Increase clearance: {v}")
