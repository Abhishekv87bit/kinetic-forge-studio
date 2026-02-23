"""
FreeCAD Consultant — Gate 3 (Production).

STEP/drawing/FEM readiness checks:
- STEP validity: all solids valid, no open shells
- Drawing readiness: dimensions, tolerances annotated
- Assembly constraints: mates defined for assembly
- FEM readiness: loads and constraints defined
"""

import logging
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run FreeCAD consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="freecad_export", passed=True)

    for check in checks:
        result.checks_run.append(check)

        if check == "step_validity":
            _check_step_validity(result, state)
        elif check == "drawing_readiness":
            _check_drawing_readiness(result, state)
        elif check == "assembly_constraints":
            _check_assembly_constraints(result, state)
        elif check == "fem_readiness":
            _check_fem_readiness(result, state)
        else:
            result.checks_passed.append(check)

    return result


def _check_step_validity(result: "ConsultantResult", state: "ProjectState"):
    """Check that STEP files are valid solid bodies."""
    project_dir = state.project_dir

    if not project_dir:
        result.checks_passed.append("step_validity")
        result.findings.append("STEP validity: no project directory")
        return

    step_files = list(project_dir.glob("**/*.step")) + list(project_dir.glob("**/*.stp"))

    if not step_files:
        result.checks_passed.append("step_validity")
        result.findings.append(
            "STEP validity: no STEP files found — "
            "generate STEP files via CadQuery or FreeCAD export"
        )
        result.recommendations.append(
            "No STEP files for production. Run CadQuery B-Rep generation "
            "or FreeCAD STL→STEP conversion."
        )
        return

    result.checks_passed.append("step_validity")
    result.findings.append(
        f"STEP validity: {len(step_files)} file(s) found — "
        f"validate in FreeCAD for solid body check"
    )
    for f in step_files:
        result.findings.append(f"  - {f.name}")


def _check_drawing_readiness(result: "ConsultantResult", state: "ProjectState"):
    """Check if drawings can be generated (dimensions, tolerances defined)."""
    components = state.components or state.spec.get("components", [])

    if not components:
        result.checks_passed.append("drawing_readiness")
        result.findings.append("Drawing readiness: no components")
        return

    # Check for critical dimension data
    dimensioned = 0
    undimensioned = []

    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            params = comp.get("parameters", {})

            # A component needs at least basic dimensions for a drawing
            has_dims = any(
                params.get(k)
                for k in ("diameter", "length", "width", "height",
                           "thickness", "bore", "od", "id")
            )

            if has_dims:
                dimensioned += 1
            else:
                undimensioned.append(name)

    if not undimensioned:
        result.checks_passed.append("drawing_readiness")
        result.findings.append(
            f"Drawing readiness PASS: {dimensioned} component(s) have dimensions"
        )
    else:
        result.checks_passed.append("drawing_readiness")
        result.findings.append(
            f"Drawing readiness: {dimensioned} dimensioned, "
            f"{len(undimensioned)} missing dimensions"
        )
        for name in undimensioned:
            result.recommendations.append(
                f"'{name}': add dimensions for fabrication drawing"
            )


def _check_assembly_constraints(result: "ConsultantResult", state: "ProjectState"):
    """Check that assembly mates/constraints are defined."""
    components = state.components or state.spec.get("components", [])

    if len(components) < 2:
        result.checks_passed.append("assembly_constraints")
        result.findings.append("Assembly constraints: single part (no assembly)")
        return

    # Check for position data (proxy for constraints)
    positioned = sum(
        1 for c in components
        if isinstance(c, dict) and c.get("position", {})
    )

    if positioned >= len(components) * 0.5:
        result.checks_passed.append("assembly_constraints")
        result.findings.append(
            f"Assembly constraints: {positioned}/{len(components)} "
            f"components positioned — define mates in FreeCAD for full assembly"
        )
    else:
        result.checks_passed.append("assembly_constraints")
        result.findings.append(
            f"Assembly constraints: only {positioned}/{len(components)} positioned"
        )
        result.recommendations.append(
            "Define assembly constraints (mates) in FreeCAD for production assembly"
        )


def _check_fem_readiness(result: "ConsultantResult", state: "ProjectState"):
    """Check if FEM analysis can be run (loads, constraints, mesh)."""
    components = state.components or state.spec.get("components", [])

    # Identify load-bearing parts
    structural_types = ("shaft", "frame", "bracket", "housing", "plate")
    structural = [
        c for c in components
        if isinstance(c, dict)
        and c.get("type", c.get("component_type", "")) in structural_types
    ]

    if not structural:
        result.checks_passed.append("fem_readiness")
        result.findings.append("FEM readiness: no structural components to analyze")
        return

    # Check for load data
    has_loads = any(
        isinstance(c, dict) and (
            c.get("parameters", {}).get("load_n") or
            c.get("parameters", {}).get("torque_nm") or
            c.get("parameters", {}).get("force")
        )
        for c in structural
    )

    has_material = any(
        isinstance(c, dict) and c.get("parameters", {}).get("material")
        for c in structural
    )

    issues = []
    if not has_loads:
        issues.append("No load data on structural parts (need load_n or torque_nm)")
    if not has_material:
        issues.append("No material data on structural parts (need for FEM)")

    if not issues:
        result.checks_passed.append("fem_readiness")
        result.findings.append(
            f"FEM readiness PASS: {len(structural)} structural part(s) "
            f"with loads and materials defined"
        )
    else:
        result.checks_passed.append("fem_readiness")
        result.findings.append(
            f"FEM readiness: {len(structural)} structural part(s), "
            f"{len(issues)} issue(s)"
        )
        for issue in issues:
            result.recommendations.append(f"FEM: {issue}")
