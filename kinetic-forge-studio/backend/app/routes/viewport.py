"""
Geometry serving API for the 3D viewport.

Serves glTF binary (GLB) for a project's geometry. If no components exist yet,
serves a default demo shape (gear + base plate) so the viewport is never empty.
"""

from fastapi import APIRouter, HTTPException
from fastapi.responses import Response

from app.engines.geometry_engine import GeometryEngine
from app.routes.projects import get_pm
from app.models.component import ComponentManager

router = APIRouter(prefix="/api/projects/{project_id}", tags=["viewport"])

_engine = GeometryEngine()


def _generate_default_scene() -> bytes:
    """Generate a default demo scene when project has no components."""
    gear = _engine.generate_gear(module=1.5, teeth=20, height=8, name="demo_gear")
    plate = _engine.generate_box(length=40, width=40, height=3, name="base_plate")
    shaft = _engine.generate_cylinder(radius=2, height=25, name="shaft")
    return _engine.generate_assembly_glb([plate, shaft, gear])


def _generate_component_geometry(component: dict) -> bytes | None:
    """Generate geometry from a component's parameters."""
    ctype = component.get("type", "")
    params = component.get("parameters", {})
    name = component.get("id", "part")

    if ctype == "gear":
        result = _engine.generate_gear(
            module=float(params.get("module", 1.5)),
            teeth=int(params.get("teeth", 20)),
            height=float(params.get("height", 8)),
            name=name,
        )
        return _engine.to_glb_bytes(result)
    elif ctype == "box":
        result = _engine.generate_box(
            length=float(params.get("length", 10)),
            width=float(params.get("width", 10)),
            height=float(params.get("height", 10)),
            name=name,
        )
        return _engine.to_glb_bytes(result)
    elif ctype == "cylinder":
        result = _engine.generate_cylinder(
            radius=float(params.get("radius", 5)),
            height=float(params.get("height", 10)),
            name=name,
        )
        return _engine.to_glb_bytes(result)
    return None


@router.get("/geometry")
async def get_geometry(project_id: str):
    """
    Serve glTF binary for a project's geometry.

    If project has registered components, generates geometry from them.
    Otherwise, serves a default demo scene.
    """
    pm = await get_pm()

    # Verify project exists
    try:
        await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    cm = ComponentManager(pm.db)
    components = await cm.list_all(project_id)

    if not components:
        # No components yet — serve default demo scene
        glb_data = _generate_default_scene()
    else:
        # Generate geometry from registered components
        results = []
        for comp in components:
            if not isinstance(comp, dict):
                continue
            ctype = comp.get("type", "")
            params = comp.get("parameters", {})
            if not isinstance(params, dict):
                params = {}
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

        if results:
            glb_data = _engine.generate_assembly_glb(results)
        else:
            glb_data = _generate_default_scene()

    return Response(
        content=glb_data,
        media_type="model/gltf-binary",
        headers={
            "Content-Disposition": f'inline; filename="{project_id}.glb"',
        },
    )


@router.get("/geometry/info")
async def get_geometry_info(project_id: str):
    """
    Return metadata about the project's geometry without the binary data.
    Useful for the frontend to know what to expect before loading.
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
            "source": "demo",
            "component_count": 3,
            "components": [
                {"name": "base_plate", "type": "box"},
                {"name": "shaft", "type": "cylinder"},
                {"name": "demo_gear", "type": "gear"},
            ],
        }

    return {
        "source": "project",
        "component_count": len(components),
        "components": [
            {"name": c["id"], "type": c.get("type", "unknown")}
            for c in components
        ],
    }
