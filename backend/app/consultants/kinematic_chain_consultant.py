"""
Kinematic Chain Consultant — Gate 1 (Design).

Checks assembly feasibility, degree of freedom, and grounding:
- Assembly feasibility: can parts be assembled in order
- Degree of freedom: mechanism DOF = expected DOF
- Grounding check: at least one grounded link
"""

import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run kinematic chain consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="kinematic_chain", passed=True)
    spec = state.spec

    for check in checks:
        result.checks_run.append(check)

        if check == "assembly_feasibility":
            _check_assembly_feasibility(result, spec, state)
        elif check == "degree_of_freedom":
            _check_dof(result, spec, state)
        elif check == "grounding_check":
            _check_grounding(result, spec, state)
        else:
            result.checks_passed.append(check)

    return result


def _check_assembly_feasibility(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """
    Can the mechanism be physically assembled?
    Check for parts that can't be inserted due to interference.
    """
    components = state.components or spec.get("components", [])

    if not components:
        result.checks_passed.append("assembly_feasibility")
        result.findings.append("Assembly feasibility: no components to check")
        return

    # Check for basic assembly issues
    issues = []

    # Look for trapped components (surrounded on all sides)
    for comp in components:
        if isinstance(comp, dict):
            params = comp.get("parameters", {})
            # Press-fit bearings inside closed housings = assembly problem
            if (params.get("fit_type") == "press_fit" and
                    params.get("enclosed", False)):
                name = comp.get("display_name", comp.get("id", "?"))
                issues.append(
                    f"'{name}' is press-fit inside an enclosed housing — "
                    f"may not be insertable"
                )

    if not issues:
        result.checks_passed.append("assembly_feasibility")
        result.findings.append(
            f"Assembly feasibility PASS: {len(components)} components, "
            f"no obvious assembly conflicts"
        )
    else:
        result.checks_failed.append("assembly_feasibility")
        result.passed = False
        result.findings.append(
            f"Assembly feasibility FAIL: {len(issues)} issue(s)"
        )
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _check_dof(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """
    Gruebler's equation: DOF = 3(n-1) - 2*j1 - j2
    where n=links, j1=full joints (pin), j2=half joints (slider).
    Expected DOF should match mechanism type.
    """
    mechanism = state.mechanism_type or spec.get("mechanism_type", "")

    # Expected DOF by mechanism type
    expected_dof_map = {
        "four_bar": 1,
        "four_bar_linkage": 1,
        "slider_crank": 1,
        "scotch_yoke": 1,
        "planetary": 1,  # with carrier fixed
        "cam": 1,
        "rack_and_pinion": 1,
        "worm_gear": 1,
    }

    expected_dof = spec.get("expected_dof", expected_dof_map.get(mechanism))

    if expected_dof is None:
        result.checks_passed.append("degree_of_freedom")
        result.findings.append(
            f"DOF check: unknown expected DOF for mechanism '{mechanism}'"
        )
        return

    # Try to compute actual DOF
    num_links = spec.get("num_links", 0)
    num_full_joints = spec.get("num_full_joints", spec.get("num_pins", 0))
    num_half_joints = spec.get("num_half_joints", spec.get("num_sliders", 0))

    if num_links > 0:
        actual_dof = 3 * (num_links - 1) - 2 * num_full_joints - num_half_joints
    else:
        # Infer from mechanism type
        actual_dof = expected_dof  # Assume correct if not enough data

    if actual_dof == expected_dof:
        result.checks_passed.append("degree_of_freedom")
        result.findings.append(
            f"DOF check PASS: actual={actual_dof}, expected={expected_dof} "
            f"(links={num_links}, j1={num_full_joints}, j2={num_half_joints})"
        )
    else:
        result.checks_failed.append("degree_of_freedom")
        result.passed = False
        result.findings.append(
            f"DOF check FAIL: actual={actual_dof}, expected={expected_dof}"
        )
        if actual_dof > expected_dof:
            result.recommendations.append(
                f"Mechanism is under-constrained (DOF={actual_dof}, need {expected_dof}). "
                f"Add {actual_dof - expected_dof} constraint(s)."
            )
        else:
            result.recommendations.append(
                f"Mechanism is over-constrained (DOF={actual_dof}, need {expected_dof}). "
                f"Remove {expected_dof - actual_dof} constraint(s) or it will bind."
            )


def _check_grounding(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """
    At least one link must be grounded (fixed to the frame).

    Checks three sources for grounding:
    1. component_type is a grounded type (frame, housing, base, etc.)
    2. parameters.grounded or parameters.fixed is True
    3. display_name or id contains grounding keywords (fallback heuristic)
    """
    components = state.components or spec.get("components", [])

    if not components:
        result.checks_passed.append("grounding_check")
        result.findings.append("Grounding: no components to check")
        return

    _GROUND_TYPES = {"frame", "ground", "housing", "base", "mount", "wall", "plate"}
    _GROUND_KEYWORDS = {"frame", "housing", "base", "mount", "wall", "plate", "bracket", "stand", "chassis"}

    grounded = []
    for comp in components:
        if isinstance(comp, dict):
            ctype = (comp.get("type", comp.get("component_type", "")) or "").lower()
            name = comp.get("display_name", comp.get("id", "?"))
            name_lower = name.lower()
            params = comp.get("parameters", {})

            # Check 1: explicit grounded type
            is_grounded = ctype in _GROUND_TYPES

            # Check 2: explicit grounded/fixed parameter
            if not is_grounded:
                is_grounded = (
                    params.get("grounded", False) or
                    params.get("fixed", False)
                )

            # Check 3: name contains grounding keyword (heuristic fallback)
            if not is_grounded:
                for kw in _GROUND_KEYWORDS:
                    if kw in name_lower:
                        is_grounded = True
                        break

            if is_grounded:
                grounded.append(name)

    if grounded:
        result.checks_passed.append("grounding_check")
        result.findings.append(
            f"Grounding PASS: {len(grounded)} grounded component(s): "
            f"{', '.join(grounded)}"
        )
    else:
        result.checks_failed.append("grounding_check")
        result.passed = False
        result.findings.append(
            "Grounding FAIL: no grounded link found. "
            "Hint: set component_type to 'frame' or add 'grounded: true' "
            "in parameters for fixed components."
        )
        result.recommendations.append(
            "Every mechanism needs at least one fixed (grounded) link. "
            "Add a frame, base, or housing component, or set "
            "'grounded: true' in an existing component's parameters."
        )
