"""
Validation API routes.

Provides gate status for a project by running all validators
against the project's current geometry. Supports gate advancement.
"""

from pathlib import Path

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.config import settings
from app.engines.geometry_engine import GeometryEngine
from app.orchestrator.gate import GateEnforcer
from app.routes.projects import get_pm
from app.models.component import ComponentManager

router = APIRouter(prefix="/api/projects/{project_id}", tags=["validation"])

_engine = GeometryEngine()
_enforcer = GateEnforcer()

GATE_ORDER = ["design", "prototype", "production"]


def _generate_geometry_results(components: list[dict]) -> list:
    """Generate GeometryResult objects from component specs."""
    results = []
    for comp in components:
        ctype = comp.get("type", "")
        params = comp.get("parameters", {})
        name = comp.get("id", "part")

        if ctype == "gear":
            results.append(_engine.generate_gear(
                module=float(params.get("module", 1.5)),
                teeth=int(params.get("teeth", 20)),
                height=float(params.get("height", 8)),
                name=name,
            ))
        elif ctype == "box":
            results.append(_engine.generate_box(
                length=float(params.get("length", 10)),
                width=float(params.get("width", 10)),
                height=float(params.get("height", 10)),
                name=name,
            ))
        elif ctype == "cylinder":
            results.append(_engine.generate_cylinder(
                radius=float(params.get("radius", 5)),
                height=float(params.get("height", 10)),
                name=name,
            ))
    return results


def _find_scad_files(project_dir: Path) -> list[Path]:
    """Find all .scad files in a project directory."""
    if not project_dir.exists():
        return []
    return list(project_dir.glob("**/*.scad"))


@router.get("/gate-status")
async def get_gate_status(project_id: str):
    """
    Run all validators on the project's geometry and return gate status.

    Runs mesh-based validators (collision, manufacturability) on components,
    plus file-based validators (geometry compile, consistency) on .scad files.
    """
    pm = await get_pm()

    try:
        project = await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    cm = ComponentManager(pm.db)
    components = await cm.list_all(project_id)
    gate_level = project.gate
    project_dir = settings.projects_dir / project_id

    # Build mesh list from components
    named_meshes = []
    geo_results = _generate_geometry_results(components)
    for gr in geo_results:
        mesh = _engine._to_trimesh(gr)
        named_meshes.append((gr.name, mesh, None))

    # Find .scad files for geometry validation
    scad_files = _find_scad_files(project_dir)

    # Run full async validation (includes geometry, consistency, tolerance)
    gate_result = await _enforcer.run_full_async(
        meshes=named_meshes,
        scad_files=scad_files if scad_files else None,
        project_dir=project_dir if project_dir.exists() else None,
        gate_level=gate_level,
    )

    return gate_result.to_dict()


class AdvanceGateRequest(BaseModel):
    target_gate: str = ""  # empty = next gate in sequence


@router.post("/advance-gate")
async def advance_gate(project_id: str, req: AdvanceGateRequest):
    """
    Attempt to advance the project to the next gate level.

    Runs validation at the target gate level. If all validators pass,
    advances the project. Otherwise returns the gate result with failures.
    """
    pm = await get_pm()

    try:
        project = await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    current_gate = project.gate

    # Determine target gate
    if req.target_gate:
        target = req.target_gate
    else:
        try:
            current_idx = GATE_ORDER.index(current_gate)
            if current_idx >= len(GATE_ORDER) - 1:
                return {
                    "advanced": False,
                    "current_gate": current_gate,
                    "message": f"Already at final gate ({current_gate}).",
                }
            target = GATE_ORDER[current_idx + 1]
        except ValueError:
            target = "prototype"

    # Run validation at target gate level
    cm = ComponentManager(pm.db)
    components = await cm.list_all(project_id)
    project_dir = settings.projects_dir / project_id

    named_meshes = []
    geo_results = _generate_geometry_results(components)
    for gr in geo_results:
        mesh = _engine._to_trimesh(gr)
        named_meshes.append((gr.name, mesh, None))

    scad_files = _find_scad_files(project_dir)

    gate_result = await _enforcer.run_full_async(
        meshes=named_meshes,
        scad_files=scad_files if scad_files else None,
        project_dir=project_dir if project_dir.exists() else None,
        gate_level=target,
    )

    if gate_result.passed:
        # Advance the gate
        await pm.db.execute(
            "UPDATE projects SET gate = ?, updated_at = datetime('now') WHERE id = ?",
            (target, project_id),
        )
        await pm.db.commit()
        return {
            "advanced": True,
            "previous_gate": current_gate,
            "current_gate": target,
            "gate_result": gate_result.to_dict(),
        }
    else:
        return {
            "advanced": False,
            "current_gate": current_gate,
            "target_gate": target,
            "gate_result": gate_result.to_dict(),
            "message": f"Cannot advance to {target}: validation failed.",
        }


# Rule 99 gate consultant metadata
GATE_CONSULTANTS = {
    "design": {
        "automated": ["collision", "manufacturability"],
        "rule99_consultants": [
            "Mechanism Consultant (Grashof, transmission angles, dead points)",
            "Physics Consultant (power budget, torque chain, driver tracing)",
            "Kinematic Chain Consultant (coupler lengths, four-bar checks)",
            "Vertical Budget Auditor (Z-stack proof, radial envelope)",
            "Margolin Eye Consultant (aesthetic review, wave superposition)",
        ],
        "transition": "Say 'design locked' to advance to prototype gate",
    },
    "prototype": {
        "automated": ["collision", "manufacturability", "geometry", "consistency", "tolerance"],
        "rule99_consultants": [
            "ISO 286 Fit Consultant (bearing/shaft tolerances)",
            "Tolerance Stackup Consultant (worst-case + RSS + Monte Carlo)",
            "Collision Check Consultant (mesh-based clearance verification)",
            "FDM Ground Truth Consultant (critical fit test prints)",
        ],
        "transition": "Say 'prototype validated' to advance to production gate",
    },
    "production": {
        "automated": ["collision", "manufacturability", "geometry", "consistency", "tolerance"],
        "rule99_consultants": [
            "DFM Consultant (Design for Manufacture: CNC, waterjet, bent sheet)",
            "Materials Consultant (metal grades, wood species, surface finish)",
            "BOM Consultant (bill of materials, sourcing, cost)",
            "FreeCAD Export Consultant (STEP files, fabrication drawings, FEM)",
        ],
        "transition": "Production gate is final — export package when ready",
    },
}


@router.get("/gate-info")
async def get_gate_info(project_id: str):
    """
    Return Rule 99 gate consultant metadata for the project's current gate.

    Shows which automated validators run and which Rule 99 consultants
    are available for the current gate level.
    """
    pm = await get_pm()
    try:
        project = await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    gate = project.gate
    info = GATE_CONSULTANTS.get(gate, GATE_CONSULTANTS["design"])
    current_idx = GATE_ORDER.index(gate) if gate in GATE_ORDER else 0

    return {
        "project_id": project_id,
        "current_gate": gate,
        "gate_index": current_idx,
        "total_gates": len(GATE_ORDER),
        "consultants": info,
        "can_advance": current_idx < len(GATE_ORDER) - 1,
        "next_gate": GATE_ORDER[current_idx + 1] if current_idx < len(GATE_ORDER) - 1 else None,
    }
