"""
Geometry serving API for the 3D viewport.

Serves glTF binary (GLB) for a project's geometry.

Priority order for each component:
1. Generated STL/STEP file (from CadQuery execution) — real production geometry
2. Parametric CadQuery generation (from component metadata) — only if no file exists
3. NEVER fall back to primitive placeholder shapes

If no components exist, serves a default demo scene.

DESIGN MANDATE: No primitives. No placeholders. Real geometry only.
"""

import logging
from pathlib import Path

import trimesh
from fastapi import APIRouter, HTTPException
from fastapi.responses import Response

from app.config import settings
from app.engines.geometry_engine import GeometryEngine
from app.routes.projects import get_pm
from app.models.component import ComponentManager
from app.utils.geometry import component_to_geometry

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/projects/{project_id}", tags=["viewport"])

_engine = GeometryEngine()


def _generate_default_scene() -> bytes:
    """Generate a default demo scene when project has no components."""
    gear = _engine.generate_gear(module=1.5, teeth=20, height=8, name="demo_gear")
    plate = _engine.generate_box(length=40, width=40, height=3, name="base_plate")
    shaft = _engine.generate_cylinder(radius=2, height=25, name="shaft")
    return _engine.generate_assembly_glb([plate, shaft, gear])


def _load_stl_file(stl_path: Path, name: str) -> trimesh.Trimesh | None:
    """Load an STL file as a trimesh mesh for viewport rendering."""
    try:
        mesh = trimesh.load(str(stl_path), file_type="stl")
        if isinstance(mesh, trimesh.Trimesh) and len(mesh.faces) > 0:
            return mesh
        elif isinstance(mesh, trimesh.Scene):
            # Flatten scene to single mesh
            combined = trimesh.util.concatenate(mesh.dump())
            if isinstance(combined, trimesh.Trimesh) and len(combined.faces) > 0:
                return combined
    except Exception as e:
        logger.warning("Failed to load STL %s: %s", stl_path, e)
    return None


@router.get("/geometry")
async def get_geometry(project_id: str):
    """
    Serve glTF binary for a project's geometry.

    For each component, checks for generated STL files first (real geometry
    from CadQuery execution), then falls back to parametric generation.
    """
    pm = await get_pm()

    try:
        await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    cm = ComponentManager(pm.db)
    components = await cm.list_all(project_id)

    if not components:
        glb_data = _generate_default_scene()
    else:
        scene = trimesh.Scene()
        models_dir = settings.projects_dir / project_id / "models"
        components_rendered = 0

        for comp in components:
            if not isinstance(comp, dict):
                continue

            comp_id = comp.get("id", "unknown")
            pos = comp.get("position", {})
            transform = None
            if isinstance(pos, dict):
                x = float(pos.get("x", 0))
                y = float(pos.get("y", 0))
                z = float(pos.get("z", 0))
                if x != 0 or y != 0 or z != 0:
                    transform = trimesh.transformations.translation_matrix([x, y, z])

            # Priority 1: Check for generated STL file (real geometry)
            stl_loaded = False
            if models_dir.exists():
                # Look for STL files matching this component ID
                for stl_path in models_dir.glob(f"{comp_id}*.stl"):
                    mesh = _load_stl_file(stl_path, comp_id)
                    if mesh is not None:
                        scene.add_geometry(mesh, node_name=comp_id, transform=transform)
                        stl_loaded = True
                        components_rendered += 1
                        logger.debug("Loaded generated STL for %s: %s", comp_id, stl_path)
                        break

            # Priority 2: Parametric generation from component metadata
            if not stl_loaded:
                gr = component_to_geometry(_engine, comp)
                if gr is not None:
                    mesh = _engine._to_trimesh(gr)
                    if mesh is not None:
                        scene.add_geometry(mesh, node_name=comp_id, transform=transform)
                        components_rendered += 1
                else:
                    logger.warning(
                        "Component %s: no generated STL and parametric generation failed. "
                        "This component will NOT appear in viewport.",
                        comp_id,
                    )

        if components_rendered > 0:
            glb_data = scene.export(file_type="glb")
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

    models_dir = settings.projects_dir / project_id / "models"
    comp_info = []
    for c in components:
        comp_id = c.get("id", "unknown")
        ctype = c.get("type", "unknown")
        has_stl = False
        if models_dir.exists():
            has_stl = any(models_dir.glob(f"{comp_id}*.stl"))
        comp_info.append({
            "name": comp_id,
            "type": ctype,
            "geometry_source": "generated_stl" if has_stl else "parametric",
        })

    return {
        "source": "project",
        "component_count": len(components),
        "components": comp_info,
    }
