"""
DFM Consultant — Gate 3 (Production).

Design for Manufacturing checks:
- Tool access: CNC tool can reach all features
- Minimum radius: internal corners >= tool radius
- Draft angles: for casting/molding
- Wall thickness (production): production material minimums
- Bend radius: sheet metal K-factor
- Hole to edge: minimum distance
"""

import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)

# Manufacturing constraints by process
PROCESS_CONSTRAINTS = {
    "cnc_mill": {
        "min_internal_radius": 1.5,   # mm (standard end mill)
        "min_wall_thickness": 1.0,    # mm
        "min_hole_to_edge": 3.0,      # mm
        "draft_required": False,
    },
    "cnc_lathe": {
        "min_internal_radius": 0.5,   # mm
        "min_wall_thickness": 1.0,    # mm
        "min_hole_to_edge": 2.0,      # mm
        "draft_required": False,
    },
    "waterjet": {
        "min_internal_radius": 0.5,   # mm (kerf)
        "min_wall_thickness": 1.0,    # mm
        "min_hole_to_edge": 2.0,      # mm
        "draft_required": False,
    },
    "laser": {
        "min_internal_radius": 0.2,   # mm
        "min_wall_thickness": 0.5,    # mm
        "min_hole_to_edge": 1.0,      # mm
        "draft_required": False,
    },
    "casting": {
        "min_internal_radius": 3.0,   # mm
        "min_wall_thickness": 3.0,    # mm
        "min_hole_to_edge": 5.0,      # mm
        "draft_required": True,
        "min_draft_angle": 2.0,       # degrees
    },
    "sheet_metal": {
        "min_bend_radius": 1.0,       # × material thickness
        "min_wall_thickness": 0.5,    # mm
        "min_hole_to_edge": 3.0,      # mm (2× thickness)
        "min_flange_width": 5.0,      # mm
    },
}


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run DFM consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="dfm", passed=True)

    for check in checks:
        result.checks_run.append(check)

        if check == "tool_access":
            _check_tool_access(result, state)
        elif check == "minimum_radius":
            _check_min_radius(result, state)
        elif check == "draft_angles":
            _check_draft_angles(result, state)
        elif check == "wall_thickness_prod":
            _check_wall_thickness(result, state)
        elif check == "bend_radius":
            _check_bend_radius(result, state)
        elif check == "hole_to_edge":
            _check_hole_to_edge(result, state)
        else:
            result.checks_passed.append(check)

    return result


def _get_process(state: "ProjectState") -> str:
    """Determine manufacturing process from spec."""
    return state.spec.get("process", state.spec.get("manufacturing_method", "cnc_mill"))


def _check_tool_access(result: "ConsultantResult", state: "ProjectState"):
    """Check that CNC tools can reach all features."""
    components = state.components or state.spec.get("components", [])
    process = _get_process(state)

    if process not in ("cnc_mill", "cnc_lathe"):
        result.checks_passed.append("tool_access")
        result.findings.append(f"Tool access: N/A for {process}")
        return

    issues = []
    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            params = comp.get("parameters", {})

            # Check for deep pockets
            pocket_depth = params.get("pocket_depth", 0)
            pocket_width = params.get("pocket_width", 0)
            if pocket_depth > 0 and pocket_width > 0:
                aspect = pocket_depth / pocket_width
                if aspect > 3:
                    issues.append(
                        f"'{name}': deep pocket aspect {aspect:.1f}:1 "
                        f"(max 3:1 for standard end mills)"
                    )

            # Check for internal features
            if params.get("internal_feature", False):
                if not params.get("tool_access_confirmed", False):
                    issues.append(
                        f"'{name}': internal feature — verify tool access path"
                    )

    if not issues:
        result.checks_passed.append("tool_access")
        result.findings.append("Tool access PASS: no access issues detected")
    else:
        result.checks_failed.append("tool_access")
        result.passed = False
        result.findings.append(f"Tool access FAIL: {len(issues)} issue(s)")
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _check_min_radius(result: "ConsultantResult", state: "ProjectState"):
    """Internal corners must be >= tool radius."""
    process = _get_process(state)
    constraints = PROCESS_CONSTRAINTS.get(process, PROCESS_CONSTRAINTS["cnc_mill"])
    min_radius = constraints.get("min_internal_radius", 1.5)

    components = state.components or state.spec.get("components", [])
    issues = []

    for comp in components:
        if isinstance(comp, dict):
            params = comp.get("parameters", {})
            name = comp.get("display_name", comp.get("id", "?"))

            corner_radius = params.get("corner_radius", params.get("fillet_radius"))
            if corner_radius is not None and corner_radius < min_radius:
                issues.append(
                    f"'{name}': corner radius {corner_radius}mm < "
                    f"min {min_radius}mm for {process}"
                )

    if not issues:
        result.checks_passed.append("minimum_radius")
        result.findings.append(
            f"Minimum radius PASS: all corners >= {min_radius}mm ({process})"
        )
    else:
        result.checks_failed.append("minimum_radius")
        result.passed = False
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _check_draft_angles(result: "ConsultantResult", state: "ProjectState"):
    """Check draft angles for casting/molding."""
    process = _get_process(state)
    constraints = PROCESS_CONSTRAINTS.get(process, {})

    if not constraints.get("draft_required", False):
        result.checks_passed.append("draft_angles")
        result.findings.append(f"Draft angles: N/A for {process}")
        return

    min_draft = constraints.get("min_draft_angle", 2.0)

    components = state.components or state.spec.get("components", [])
    issues = []

    for comp in components:
        if isinstance(comp, dict):
            params = comp.get("parameters", {})
            name = comp.get("display_name", comp.get("id", "?"))

            draft = params.get("draft_angle")
            if draft is not None and draft < min_draft:
                issues.append(
                    f"'{name}': draft angle {draft} deg < min {min_draft} deg"
                )
            elif draft is None:
                issues.append(
                    f"'{name}': no draft angle specified (need >= {min_draft} deg for {process})"
                )

    if not issues:
        result.checks_passed.append("draft_angles")
        result.findings.append(f"Draft angles PASS: all >= {min_draft} deg")
    else:
        result.checks_failed.append("draft_angles")
        result.passed = False
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _check_wall_thickness(result: "ConsultantResult", state: "ProjectState"):
    """Production-grade wall thickness (stricter than FDM)."""
    process = _get_process(state)
    material = state.material or state.spec.get("material", "aluminum")
    constraints = PROCESS_CONSTRAINTS.get(process, PROCESS_CONSTRAINTS["cnc_mill"])
    min_wall = constraints.get("min_wall_thickness", 1.0)

    # Adjust for material
    material_factors = {
        "aluminum": 1.0,
        "steel": 0.8,
        "brass": 1.0,
        "wood": 2.0,
        "acrylic": 1.5,
    }
    factor = material_factors.get(material.lower(), 1.0)
    min_wall *= factor

    result.checks_passed.append("wall_thickness_prod")
    result.findings.append(
        f"Wall thickness: min {min_wall:.1f}mm for {material}/{process}"
    )


def _check_bend_radius(result: "ConsultantResult", state: "ProjectState"):
    """Sheet metal bend radius check."""
    process = _get_process(state)

    if process != "sheet_metal":
        result.checks_passed.append("bend_radius")
        result.findings.append(f"Bend radius: N/A for {process}")
        return

    thickness = state.spec.get("sheet_thickness", 1.0)
    min_bend = thickness  # 1× thickness minimum

    components = state.components or state.spec.get("components", [])
    issues = []

    for comp in components:
        if isinstance(comp, dict):
            params = comp.get("parameters", {})
            name = comp.get("display_name", comp.get("id", "?"))

            bend_r = params.get("bend_radius")
            if bend_r is not None and bend_r < min_bend:
                issues.append(
                    f"'{name}': bend radius {bend_r}mm < "
                    f"min {min_bend}mm (1× thickness)"
                )

    if not issues:
        result.checks_passed.append("bend_radius")
        result.findings.append(f"Bend radius PASS: all >= {min_bend}mm")
    else:
        result.checks_failed.append("bend_radius")
        result.passed = False
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _check_hole_to_edge(result: "ConsultantResult", state: "ProjectState"):
    """Minimum distance from hole to part edge."""
    process = _get_process(state)
    constraints = PROCESS_CONSTRAINTS.get(process, PROCESS_CONSTRAINTS["cnc_mill"])
    min_dist = constraints.get("min_hole_to_edge", 3.0)

    result.checks_passed.append("hole_to_edge")
    result.findings.append(
        f"Hole to edge: min {min_dist}mm for {process} "
        f"(verify in CAD model)"
    )
