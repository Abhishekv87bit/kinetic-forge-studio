"""
Rule 500 Pipeline — Phase 1: INTAKE (Steps 1-5).

Steps:
  1. Discover Files — scan for .scad, .py, .step, .stl, .json
  2. Parse & Classify — extract modules, constants, mechanism type
  3. Reference Library Search — search for similar designs
  4. Reference Extraction — analyze reference STLs with trimesh
  5. User Profile & Preferences — load user profile + gate
"""

import logging
from pathlib import Path

from app.orchestrator.rule500_pipeline import StepResult

logger = logging.getLogger(__name__)


async def step1_discover_files(context: dict) -> StepResult:
    """Scan target path for project files."""
    project_dir = context.get("project_dir")
    if not project_dir:
        return StepResult(
            step=1, name="Discover Files", phase="intake",
            passed=True, findings=["No project directory specified"],
        )

    project_dir = Path(project_dir)
    if not project_dir.exists():
        return StepResult(
            step=1, name="Discover Files", phase="intake",
            passed=True, findings=[f"Project directory does not exist: {project_dir}"],
        )

    # Scan for files
    extensions = {".scad", ".py", ".step", ".stp", ".stl", ".json", ".yaml", ".yml"}
    files: dict[str, list[str]] = {}

    for ext in extensions:
        found = list(project_dir.glob(f"**/*{ext}"))
        if found:
            files[ext] = [str(f.relative_to(project_dir)) for f in found]

    total = sum(len(v) for v in files.values())
    findings = [f"Found {total} file(s) in {project_dir}"]
    for ext, file_list in files.items():
        findings.append(f"  {ext}: {len(file_list)} file(s)")

    return StepResult(
        step=1, name="Discover Files", phase="intake",
        passed=True,
        findings=findings,
        data={"files": files, "total": total},
    )


async def step2_parse_classify(context: dict) -> StepResult:
    """Parse and classify project files."""
    components = context.get("components", [])
    spec = context.get("spec", {})

    mechanism_type = spec.get("mechanism_type", "unknown")
    num_components = len(components)

    findings = [
        f"Mechanism type: {mechanism_type}",
        f"Components: {num_components}",
    ]

    # Extract component types
    types = set()
    for comp in components:
        if isinstance(comp, dict):
            ctype = comp.get("type", comp.get("component_type", ""))
            if ctype:
                types.add(ctype)
    if types:
        findings.append(f"Component types: {', '.join(sorted(types))}")

    return StepResult(
        step=2, name="Parse & Classify", phase="intake",
        passed=True,
        findings=findings,
        data={"mechanism_type": mechanism_type, "component_types": list(types)},
    )


async def step3_library_search(context: dict) -> StepResult:
    """Search reference library for similar designs."""
    from app.consultants.rule99_engine import get_engine, ProjectState

    spec = context.get("spec", {})
    components = context.get("components", [])

    engine = get_engine()
    project_state = ProjectState(
        mechanism_type=spec.get("mechanism_type", ""),
        component_types=[
            c.get("type", "") for c in components if isinstance(c, dict)
        ],
        spec=spec,
    )

    suggestions = engine._suggest_libraries(project_state)

    findings = [f"Library suggestions: {len(suggestions)} relevant libraries"]
    for lib in suggestions[:10]:
        findings.append(f"  - {lib.name}: {lib.purpose}")

    return StepResult(
        step=3, name="Reference Library Search", phase="intake",
        passed=True,
        findings=findings,
        data={"library_count": len(suggestions)},
    )


async def step4_reference_extraction(context: dict) -> StepResult:
    """Analyze reference STL meshes with trimesh."""
    project_dir = Path(context.get("project_dir", ""))
    stl_files = list(project_dir.glob("**/*.stl")) if project_dir.exists() else []

    if not stl_files:
        return StepResult(
            step=4, name="Reference Extraction", phase="intake",
            passed=True,
            findings=["No STL reference files found — skipped"],
        )

    findings = [f"Found {len(stl_files)} STL file(s) for reference extraction"]

    try:
        import trimesh
        for stl_path in stl_files[:5]:  # Analyze up to 5
            mesh = trimesh.load(str(stl_path))
            bounds = mesh.bounds
            extents = mesh.extents
            findings.append(
                f"  {stl_path.name}: extents={extents[0]:.1f}x{extents[1]:.1f}x{extents[2]:.1f}mm"
            )
    except Exception as e:
        findings.append(f"  Analysis error: {e}")

    return StepResult(
        step=4, name="Reference Extraction", phase="intake",
        passed=True,
        findings=findings,
    )


async def step5_user_profile(context: dict) -> StepResult:
    """Load user profile and preferences."""
    spec = context.get("spec", {})
    gate_level = context.get("gate_level", "design")

    findings = [
        f"Current gate: {gate_level}",
        f"Material: {spec.get('material', 'not specified')}",
        f"Envelope: {spec.get('envelope', 'not specified')}",
    ]

    return StepResult(
        step=5, name="User Profile & Preferences", phase="intake",
        passed=True,
        findings=findings,
    )
