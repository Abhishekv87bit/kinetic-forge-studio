"""
Export package API route.

Bundles project data into a downloadable ZIP containing:
- STEP files (assembly + individual parts)
- STL files
- Validation report (JSON)
- Spec sheet (JSON with decisions + components)
- README.txt with project info
"""

import io
import json
import logging
import zipfile
from datetime import datetime, timezone

logger = logging.getLogger(__name__)

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from app.config import settings
from app.engines.geometry_engine import GeometryEngine
from app.models.component import ComponentManager
from app.models.decision import DecisionManager
from app.orchestrator.gate import GateEnforcer
from app.routes.projects import get_pm

router = APIRouter(prefix="/api/projects/{project_id}", tags=["export"])

_engine = GeometryEngine()
_enforcer = GateEnforcer()


def _generate_geometry_from_component(comp: dict):
    """Generate a GeometryResult from a component dict."""
    ctype = comp.get("type", "")
    params = comp.get("parameters", {})
    name = comp.get("id", "part")

    if ctype == "gear":
        return _engine.generate_gear(
            module=float(params.get("module", 1.5)),
            teeth=int(params.get("teeth", 20)),
            height=float(params.get("height", 8)),
            name=name,
        )
    elif ctype == "box":
        return _engine.generate_box(
            length=float(params.get("length", 10)),
            width=float(params.get("width", 10)),
            height=float(params.get("height", 10)),
            name=name,
        )
    elif ctype == "cylinder":
        return _engine.generate_cylinder(
            radius=float(params.get("radius", 5)),
            height=float(params.get("height", 10)),
            name=name,
        )
    return None


@router.get("/export")
async def export_project(project_id: str):
    """
    Export project as a ZIP package.

    Returns a ZIP file containing:
    - Individual STEP files for each component
    - Individual STL files for each component
    - validation_report.json with gate status
    - spec_sheet.json with all decisions and components
    - README.txt with project summary
    """
    pm = await get_pm()

    try:
        project = await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    dm = DecisionManager(pm.db)
    cm = ComponentManager(pm.db)
    decisions = await dm.list_all(project_id)
    components = await cm.list_all(project_id)

    # Generate geometry for all components
    geo_results = []
    for comp in components:
        gr = _generate_geometry_from_component(comp)
        if gr:
            geo_results.append(gr)

    # Run validation
    validation_report = {"passed": True, "validators": [], "summary": "No geometry to validate."}
    if geo_results:
        named_meshes = []
        for gr in geo_results:
            mesh = _engine._to_trimesh(gr)
            named_meshes.append((gr.name, mesh, None))
        gate_result = _enforcer.run(named_meshes)
        validation_report = gate_result.to_dict()

    # Build spec sheet
    spec_sheet = {
        "project_id": project_id,
        "project_name": project.name,
        "gate": project.gate,
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "decisions": decisions,
        "components": components,
        "component_count": len(components),
        "decision_count": len(decisions),
    }

    # Build README
    readme_text = _build_readme(project, components, decisions)

    # Create ZIP in memory
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        # Add README
        zf.writestr("README.txt", readme_text)

        # Add spec sheet
        zf.writestr("spec_sheet.json", json.dumps(spec_sheet, indent=2, default=str))

        # Add validation report
        zf.writestr("validation_report.json", json.dumps(validation_report, indent=2, default=str))

        # Add STEP and STL files for each geometry result
        import tempfile
        from pathlib import Path

        for gr in geo_results:
            # STEP file
            tmp_step = None
            try:
                with tempfile.NamedTemporaryFile(suffix=".step", delete=False) as tmp:
                    tmp_step = Path(tmp.name)
                _engine.export_step(gr, tmp_step)
                zf.write(tmp_step, f"step/{gr.name}.step")
            except Exception as e:
                logger.warning("STEP export failed for %s: %s", gr.name, e)
            finally:
                if tmp_step:
                    tmp_step.unlink(missing_ok=True)

            # STL file
            tmp_stl = None
            try:
                with tempfile.NamedTemporaryFile(suffix=".stl", delete=False) as tmp:
                    tmp_stl = Path(tmp.name)
                _engine.export_stl(gr, tmp_stl)
                zf.write(tmp_stl, f"stl/{gr.name}.stl")
            except Exception as e:
                logger.warning("STL export failed for %s: %s", gr.name, e)
            finally:
                if tmp_stl:
                    tmp_stl.unlink(missing_ok=True)

        # Add source .scad files from project directory
        project_dir = settings.projects_dir / project_id
        if project_dir.exists():
            for scad_file in project_dir.glob("**/*.scad"):
                rel = scad_file.relative_to(project_dir)
                zf.write(scad_file, f"source/{rel}")

        # Add render PNGs from project directory
        renders_dir = project_dir / "renders"
        if renders_dir.exists():
            for png_file in renders_dir.glob("*.png"):
                zf.write(png_file, f"renders/{png_file.name}")

    zip_buffer.seek(0)
    filename = f"{project.name.replace(' ', '_')}_{project_id}_export.zip"

    return StreamingResponse(
        zip_buffer,
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


def _build_readme(project, components: list[dict], decisions: list[dict]) -> str:
    """Build a human-readable README for the export package."""
    lines = [
        f"Kinetic Forge Studio — Export Package",
        f"{'=' * 40}",
        f"",
        f"Project: {project.name}",
        f"ID: {project.id}",
        f"Gate: {project.gate}",
        f"Exported: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}",
        f"",
        f"Components ({len(components)}):",
        f"{'-' * 30}",
    ]

    for comp in components:
        lines.append(f"  - {comp.get('display_name', comp.get('id', 'unknown'))} "
                     f"({comp.get('type', 'unknown')})")
        params = comp.get("parameters", {})
        for k, v in params.items():
            lines.append(f"      {k}: {v}")

    lines.extend([
        f"",
        f"Decisions ({len(decisions)}):",
        f"{'-' * 30}",
    ])

    for dec in decisions:
        status = dec.get("status", "proposed")
        lines.append(f"  - [{status}] {dec.get('parameter', '?')} = {dec.get('value', '?')}")
        if dec.get("reason"):
            lines.append(f"      Reason: {dec['reason']}")

    lines.extend([
        f"",
        f"Package Contents:",
        f"{'-' * 30}",
        f"  step/      — STEP files for each component (B-rep geometry)",
        f"  stl/       — STL mesh files for each component",
        f"  spec_sheet.json    — Full specification with decisions and components",
        f"  validation_report.json  — Validation gate results",
        f"  README.txt         — This file",
        f"",
        f"Generated by Kinetic Forge Studio",
    ])

    return "\n".join(lines)
