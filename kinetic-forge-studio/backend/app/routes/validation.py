"""
Validation API routes.

Provides gate status for a project by running all validators
against the project's current geometry.
"""

from fastapi import APIRouter, HTTPException

from app.engines.geometry_engine import GeometryEngine
from app.orchestrator.gate import GateEnforcer
from app.routes.projects import get_pm
from app.models.component import ComponentManager

router = APIRouter(prefix="/api/projects/{project_id}", tags=["validation"])

_engine = GeometryEngine()
_enforcer = GateEnforcer()


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


@router.get("/gate-status")
async def get_gate_status(project_id: str):
    """
    Run all validators on the project's geometry and return gate status.

    Returns a structured result with:
    - passed: overall pass/fail
    - validators: per-validator results
    - summary: human-readable summary
    """
    pm = await get_pm()

    try:
        await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    cm = ComponentManager(pm.db)
    components = await cm.list_all(project_id)

    if not components:
        return {
            "passed": True,
            "validators": [],
            "summary": "No components to validate. Add geometry first.",
        }

    # Generate geometry from components
    geo_results = _generate_geometry_results(components)

    if not geo_results:
        return {
            "passed": True,
            "validators": [],
            "summary": "No recognized geometry types to validate.",
        }

    # Convert GeometryResult objects to trimesh for validators
    named_meshes = []
    for gr in geo_results:
        mesh = _engine._to_trimesh(gr)
        named_meshes.append((gr.name, mesh, None))

    # Run gate enforcer
    gate_result = _enforcer.run(named_meshes)

    return gate_result.to_dict()
