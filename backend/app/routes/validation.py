"""
Validation API routes.

Provides gate status for a project by running all validators
against the project's current geometry. Supports gate advancement.
Integrates Rule 99 consultant pipeline for methodology enforcement.
"""

from pathlib import Path

import numpy as np
import trimesh

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.config import settings
from app.engines.geometry_engine import GeometryEngine
from app.orchestrator.gate import GateEnforcer
from app.orchestrator.rule500_pipeline import get_pipeline
from app.routes.projects import get_pm
from app.models.component import ComponentManager
from app.utils.geometry import component_to_geometry
from app.consultants.rule99_engine import get_engine as get_rule99_engine, ProjectState
from app.middleware.cache import clear_project_cache

router = APIRouter(prefix="/api/projects/{project_id}", tags=["validation"])

_engine = GeometryEngine()
_enforcer = GateEnforcer()

GATE_ORDER = ["design", "prototype", "production"]


def _build_mesh_list(
    components: list[dict],
) -> tuple[list[tuple[str, "trimesh.Trimesh", np.ndarray | None]], dict[str, str]]:
    """
    Build named mesh list with transforms from components.

    Returns:
        Tuple of (meshes_with_transforms, component_types_map).
        component_types_map maps component name -> type string for
        collision exemptions (e.g., gear-gear mesh contact).
    """
    named_meshes = []
    component_types: dict[str, str] = {}

    for comp in components:
        gr = component_to_geometry(_engine, comp)
        if gr is None:
            continue

        mesh = _engine._to_trimesh(gr)
        component_types[gr.name] = comp.get("type", "")

        # Build translation transform from stored position
        pos = comp.get("position", {})
        if isinstance(pos, dict) and any(pos.get(k, 0) != 0 for k in ("x", "y", "z")):
            transform = trimesh.transformations.translation_matrix([
                float(pos.get("x", 0)),
                float(pos.get("y", 0)),
                float(pos.get("z", 0)),
            ])
        else:
            transform = None

        named_meshes.append((gr.name, mesh, transform))

    return named_meshes, component_types


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

    named_meshes, component_types = _build_mesh_list(components)
    scad_files = _find_scad_files(project_dir)

    gate_result = await _enforcer.run_full_async(
        meshes=named_meshes,
        component_types=component_types,
        scad_files=scad_files if scad_files else None,
        project_dir=project_dir if project_dir.exists() else None,
        gate_level=gate_level,
        components=components,
        mechanism_type=project.mechanism_type if hasattr(project, "mechanism_type") else "",
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

    cm = ComponentManager(pm.db)
    components = await cm.list_all(project_id)
    project_dir = settings.projects_dir / project_id

    named_meshes, component_types = _build_mesh_list(components)
    scad_files = _find_scad_files(project_dir)

    gate_result = await _enforcer.run_full_async(
        meshes=named_meshes,
        component_types=component_types,
        scad_files=scad_files if scad_files else None,
        project_dir=project_dir if project_dir.exists() else None,
        gate_level=target,
        components=components,
        mechanism_type=project.mechanism_type if hasattr(project, "mechanism_type") else "",
    )

    if gate_result.passed:
        await pm.update_gate(project_id, target)
        clear_project_cache(project_id)
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


@router.get("/gate-info")
async def get_gate_info(project_id: str):
    """
    Return Rule 99 gate consultant metadata for the project's current gate.
    Uses the actual Rule 99 engine config (not static metadata).
    """
    pm = await get_pm()
    try:
        project = await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    gate = project.gate
    current_idx = GATE_ORDER.index(gate) if gate in GATE_ORDER else 0

    # Get live consultant info from Rule 99 engine
    engine = get_rule99_engine()
    consultants = engine.get_gate_consultant_info(gate)
    topics = engine.get_topics()

    transition_messages = {
        "design": "Say 'design locked' to advance to prototype gate",
        "prototype": "Say 'prototype validated' to advance to production gate",
        "production": "Production gate is final — export package when ready",
    }

    return {
        "project_id": project_id,
        "current_gate": gate,
        "gate_index": current_idx,
        "total_gates": len(GATE_ORDER),
        "consultants": consultants,
        "transition": transition_messages.get(gate, ""),
        "available_topics": list(topics.keys()),
        "can_advance": current_idx < len(GATE_ORDER) - 1,
        "next_gate": GATE_ORDER[current_idx + 1] if current_idx < len(GATE_ORDER) - 1 else None,
    }


class Rule99Request(BaseModel):
    topic: str = ""  # Empty = full gate scan, else targeted topic


@router.post("/rule99")
async def run_rule99(project_id: str, req: Rule99Request):
    """
    Run Rule 99 consultants on the project.

    Modes:
    - No topic: Full scan for current gate level
    - With topic: Targeted scan (e.g., "cam", "drive", "tolerance")
    """
    pm = await get_pm()
    try:
        project = await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    cm = ComponentManager(pm.db)
    components = await cm.list_all(project_id)
    gate_level = project.gate

    # Build project state for Rule 99
    component_types = [c.get("type", "") for c in components if isinstance(c, dict)]
    mechanism_type = project.mechanism_type if hasattr(project, "mechanism_type") else ""

    project_state = ProjectState(
        gate_level=gate_level,
        mechanism_type=mechanism_type,
        component_types=component_types,
        components=components,
        spec={},
        project_dir=settings.projects_dir / project_id,
    )

    engine = get_rule99_engine()

    if req.topic:
        report = engine.run_targeted(req.topic, project_state)
    else:
        report = engine.run_gate_consultants(gate_level, project_state)

    return report.to_dict()


# ── Rule 500 Pipeline Endpoints ────────────────────────────


class Rule500Request(BaseModel):
    gate_level: str = "production"  # Run through this gate level
    step: int | None = None  # Run single step (if specified)
    resume_from: int | None = None  # Resume from this step


@router.post("/rule500")
async def run_rule500(project_id: str, req: Rule500Request):
    """
    Run the Rule 500 32-step production pipeline.

    Modes:
    - Default: Run all steps through production gate
    - gate_level: Run only through specified gate (design, prototype, production)
    - resume_from: Resume pipeline from a specific step after fixing failures
    """
    pm = await get_pm()
    try:
        project = await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    cm = ComponentManager(pm.db)
    components = await cm.list_all(project_id)
    project_dir = settings.projects_dir / project_id

    pipeline = get_pipeline()

    if req.resume_from:
        report = await pipeline.resume_from(
            step_number=req.resume_from,
            project_id=project_id,
            project_dir=project_dir,
            components=components,
            spec={},
        )
    else:
        report = await pipeline.run(
            project_id=project_id,
            project_dir=project_dir,
            gate_level=req.gate_level,
            components=components,
            spec={},
        )

    return report.to_dict()


@router.get("/rule500/status")
async def get_rule500_status(project_id: str):
    """Return info about pipeline steps and current gate."""
    pm = await get_pm()
    try:
        project = await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    from app.orchestrator.rule500_pipeline import STEP_REGISTRY

    steps = []
    for step_num, name, phase, critical, handler in STEP_REGISTRY:
        steps.append({
            "step": step_num,
            "name": name,
            "phase": phase,
            "critical": critical,
        })

    return {
        "project_id": project_id,
        "current_gate": project.gate,
        "total_steps": len(STEP_REGISTRY),
        "steps": steps,
    }
