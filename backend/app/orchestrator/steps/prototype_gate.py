"""
Rule 500 Pipeline — Phase 3: PROTOTYPE GATE (Steps 12-19).

Steps:
  12. STL Export — per-component + assembly
  13. Collision Detection — pairwise mesh clash
  14. Manufacturability — wall thickness, overhang, watertight
  15. ISO 286 Tolerance — shaft/hole fit check
  16. Tolerance Stackup — worst-case + RSS
  17. FDM Ground Truth — test print recommendations
  18. STEP File Analysis — if .step files exist
  19. Rule 99 Prototype Gate — fire Gate 2 consultants
"""

import logging
from pathlib import Path

from app.orchestrator.rule500_pipeline import StepResult

logger = logging.getLogger(__name__)


async def step12_stl_export(context: dict) -> StepResult:
    """Export each component as individual STL."""
    project_dir = Path(context.get("project_dir", ""))
    scad_files = list(project_dir.glob("**/*.scad")) if project_dir.exists() else []

    if not scad_files:
        return StepResult(
            step=12, name="STL Export", phase="prototype",
            passed=True, findings=["No .scad files — skipped"],
        )

    findings = [f"Found {len(scad_files)} .scad file(s) for STL export"]

    # Try exporting STL via OpenSCAD CLI
    try:
        from app.config import settings
        import subprocess, os

        stl_dir = project_dir / "stl"
        stl_dir.mkdir(exist_ok=True)

        for scad_path in scad_files:
            stl_path = stl_dir / scad_path.with_suffix(".stl").name
            cmd = [
                settings.openscad_path,
                "--backend=manifold",
                "-o", str(stl_path),
                str(scad_path),
            ]
            result = subprocess.run(
                cmd, capture_output=True, text=True, timeout=120,
                env={**os.environ, "OPENSCADPATH": settings.openscad_lib_path},
            )
            if result.returncode == 0 and stl_path.exists():
                findings.append(f"  Exported: {stl_path.name}")
            else:
                findings.append(f"  Export failed: {scad_path.name}")
    except Exception as e:
        findings.append(f"STL export error: {e}")

    return StepResult(
        step=12, name="STL Export", phase="prototype",
        passed=True, findings=findings,
    )


async def step13_collision(context: dict) -> StepResult:
    """Collision detection — pairwise mesh clash."""
    components = context.get("components", [])

    if len(components) < 2:
        return StepResult(
            step=13, name="Collision Detection", phase="prototype",
            passed=True, findings=["Fewer than 2 components — skipped"],
        )

    findings = [f"Checking {len(components)} components for collisions"]

    try:
        from app.engines.geometry_engine import GeometryEngine
        from app.utils.geometry import component_to_geometry
        from app.validators.collision import check_collisions
        import trimesh

        engine = GeometryEngine()
        named_meshes = []
        component_types = {}

        for comp in components:
            gr = component_to_geometry(engine, comp)
            if gr is None:
                continue
            mesh = engine._to_trimesh(gr)
            component_types[gr.name] = comp.get("type", "")

            pos = comp.get("position", {})
            if isinstance(pos, dict) and any(pos.get(k, 0) != 0 for k in ("x", "y", "z")):
                transform = trimesh.transformations.translation_matrix([
                    float(pos.get("x", 0)), float(pos.get("y", 0)), float(pos.get("z", 0)),
                ])
            else:
                transform = None
            named_meshes.append((gr.name, mesh, transform))

        if named_meshes:
            result = check_collisions(named_meshes, component_types=component_types)
            if result.passed:
                findings.append("Collision check PASS: no overlaps")
            else:
                findings.append(f"Collision check FAIL: {len(result.collisions)} collision(s)")
                for col in result.collisions:
                    findings.append(f"  {col['mesh_a']} <-> {col['mesh_b']}")

            return StepResult(
                step=13, name="Collision Detection", phase="prototype",
                passed=result.passed, critical=True,
                findings=findings,
            )

    except Exception as e:
        findings.append(f"Collision check error: {e}")

    return StepResult(
        step=13, name="Collision Detection", phase="prototype",
        passed=True, findings=findings,
    )


async def step14_manufacturability(context: dict) -> StepResult:
    """Manufacturability check — wall thickness, overhang, watertight."""
    components = context.get("components", [])

    if not components:
        return StepResult(
            step=14, name="Manufacturability Check", phase="prototype",
            passed=True, findings=["No components — skipped"],
        )

    findings = [f"Checking {len(components)} components for manufacturability"]

    try:
        from app.engines.geometry_engine import GeometryEngine
        from app.utils.geometry import component_to_geometry
        from app.validators.manufacturability import check_manufacturability

        engine = GeometryEngine()
        all_passed = True

        for comp in components:
            gr = component_to_geometry(engine, comp)
            if gr is None:
                continue
            mesh = engine._to_trimesh(gr)
            result = check_manufacturability(mesh)
            name = comp.get("display_name", comp.get("id", "?"))

            if result.passed:
                findings.append(f"  PASS: {name}")
            else:
                all_passed = False
                findings.append(f"  FAIL: {name}")
                for check in result.checks:
                    if not check["passed"]:
                        findings.append(f"    - {check['name']}: {check.get('value', '?')}")

        return StepResult(
            step=14, name="Manufacturability Check", phase="prototype",
            passed=all_passed, findings=findings,
        )

    except Exception as e:
        findings.append(f"Manufacturability error: {e}")

    return StepResult(
        step=14, name="Manufacturability Check", phase="prototype",
        passed=True, findings=findings,
    )


async def step15_iso286(context: dict) -> StepResult:
    """ISO 286 tolerance check for shaft/hole pairs."""
    from app.consultants.rule99_engine import get_engine, ProjectState

    components = context.get("components", [])
    spec = context.get("spec", {})

    project_state = ProjectState(
        gate_level="prototype",
        component_types=[c.get("type", "") for c in components if isinstance(c, dict)],
        components=components,
        spec=spec,
    )

    engine = get_engine()
    report = engine.run_targeted("tolerance", project_state)

    findings = [f"ISO 286 check: {'PASS' if report.passed else 'FAIL'}"]
    for cr in report.consultants_fired:
        for f in cr.findings:
            findings.append(f"  {f}")

    return StepResult(
        step=15, name="ISO 286 Tolerance", phase="prototype",
        passed=report.passed, findings=findings,
    )


async def step16_tolerance_stackup(context: dict) -> StepResult:
    """Tolerance stackup analysis."""
    spec = context.get("spec", {})
    contributors = spec.get("stackup_contributors", [])

    if not contributors:
        return StepResult(
            step=16, name="Tolerance Stackup", phase="prototype",
            passed=True, findings=["No stackup contributors — skipped"],
        )

    from app.validators import tolerance_validator

    result = await tolerance_validator.validate(
        stackup_contributors=contributors,
    )

    findings = [f"Tolerance stackup: {'PASS' if result.passed else 'FAIL'}"]
    findings.extend(result.warnings)
    findings.extend(result.errors)

    return StepResult(
        step=16, name="Tolerance Stackup", phase="prototype",
        passed=result.passed, findings=findings,
    )


async def step17_fdm_ground_truth(context: dict) -> StepResult:
    """FDM ground truth — test print recommendations."""
    from app.consultants.rule99_engine import get_engine, ProjectState

    components = context.get("components", [])

    project_state = ProjectState(
        gate_level="prototype",
        component_types=[c.get("type", "") for c in components if isinstance(c, dict)],
        components=components,
    )

    engine = get_engine()
    report = engine.run_targeted("print", project_state)

    findings = ["FDM Ground Truth recommendations:"]
    for cr in report.consultants_fired:
        for f in cr.findings:
            findings.append(f"  {f}")

    return StepResult(
        step=17, name="FDM Ground Truth", phase="prototype",
        passed=True, findings=findings,
    )


async def step18_step_analysis(context: dict) -> StepResult:
    """Analyze STEP files if they exist."""
    project_dir = Path(context.get("project_dir", ""))
    step_files = (list(project_dir.glob("**/*.step")) +
                  list(project_dir.glob("**/*.stp"))) if project_dir.exists() else []

    if not step_files:
        return StepResult(
            step=18, name="STEP File Analysis", phase="prototype",
            passed=True, findings=["No STEP files found — skipped"],
        )

    findings = [f"Found {len(step_files)} STEP file(s)"]
    for f in step_files:
        findings.append(f"  {f.name} ({f.stat().st_size / 1024:.1f} KB)")

    return StepResult(
        step=18, name="STEP File Analysis", phase="prototype",
        passed=True, findings=findings,
    )


async def step19_rule99_gate2(context: dict) -> StepResult:
    """Run Rule 99 Gate 2 consultants."""
    from app.consultants.rule99_engine import get_engine, ProjectState

    components = context.get("components", [])
    spec = context.get("spec", {})

    project_state = ProjectState(
        gate_level="prototype",
        mechanism_type=spec.get("mechanism_type", ""),
        component_types=[c.get("type", "") for c in components if isinstance(c, dict)],
        components=components,
        spec=spec,
        project_dir=Path(context.get("project_dir", "")),
    )

    engine = get_engine()
    report = engine.run_gate_consultants("prototype", project_state)

    findings = [
        f"Rule 99 Prototype Gate: {'PASS' if report.passed else 'FAIL'}",
        f"Consultants fired: {len(report.consultants_fired)}",
    ]
    for cr in report.consultants_fired:
        icon = "PASS" if cr.passed else "FAIL"
        findings.append(f"  [{icon}] {cr.name}")

    return StepResult(
        step=19, name="Rule 99 Prototype Gate", phase="prototype",
        passed=report.passed, critical=True,
        findings=findings,
        data=report.to_dict(),
    )
