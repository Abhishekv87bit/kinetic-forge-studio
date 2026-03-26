"""
Modules route — CRUD, execution, validation, and manifest generation for KFS modules.

Each module is a versioned CadQuery/build123d script attached to a project.
Execution writes STL/STEP geometry; VLAD validates the produced geometry.
"""

import logging
from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.config import settings
from app.middleware.cache import clear_project_cache
from app.models.module import ModuleManager
from app.models.session_context import SessionLogManager

# Service imports — resolved at runtime by the services layer
from app.services.module_executor import execute_module
from app.services.vlad_runner import run_vlad
from app.services.durga import execute_with_repair
from app.services.manifest_generator import generate_manifest

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/projects/{project_id}/modules",
    tags=["modules"],
)

# ---------------------------------------------------------------------------
# Singleton managers (lazy-init, same pattern as projects.py)
# ---------------------------------------------------------------------------

_mm: ModuleManager | None = None
_sl: SessionLogManager | None = None


async def get_mm() -> ModuleManager:
    global _mm
    if _mm is None:
        _mm = ModuleManager(data_dir=settings.data_dir)
    return _mm


async def get_sl() -> SessionLogManager:
    global _sl
    if _sl is None:
        _sl = SessionLogManager(data_dir=settings.data_dir)
    return _sl


# ---------------------------------------------------------------------------
# Request / Response models
# ---------------------------------------------------------------------------

class CreateModuleRequest(BaseModel):
    name: str
    source_code: str
    language: str = "python"
    parameters: dict = {}


class UpdateModuleRequest(BaseModel):
    source_code: str
    change_summary: str = ""


class RollbackRequest(BaseModel):
    target_version: int


class ExecuteRequest(BaseModel):
    output_dir: str = ""


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post("")
async def create_module(project_id: str, req: CreateModuleRequest):
    """Create a new module attached to a project (starts at version 1)."""
    mm = await get_mm()
    sl = await get_sl()
    try:
        module = await mm.create(
            project_id=project_id,
            name=req.name,
            source_code=req.source_code,
            language=req.language,
            parameters=req.parameters,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    await sl.log_action(project_id, "module_created", {"name": req.name}, module["id"])
    clear_project_cache(project_id)
    return module


@router.get("")
async def list_modules(project_id: str):
    """List all modules for a project, newest first."""
    mm = await get_mm()
    return await mm.list_all(project_id)


@router.get("/{module_id}")
async def get_module(project_id: str, module_id: str):
    """Get a single module with its current source code and version."""
    mm = await get_mm()
    try:
        return await mm.get(project_id, module_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Module not found")


@router.put("/{module_id}")
async def update_module(project_id: str, module_id: str, req: UpdateModuleRequest):
    """Update module source code. Auto-increments version and stores old version."""
    mm = await get_mm()
    sl = await get_sl()
    try:
        module = await mm.update_source(
            project_id=project_id,
            module_id=module_id,
            source_code=req.source_code,
            change_summary=req.change_summary,
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    await sl.log_action(
        project_id, "module_updated",
        {"version": module["version"], "change_summary": req.change_summary},
        module_id,
    )
    clear_project_cache(project_id)
    return module


@router.post("/{module_id}/execute")
async def execute_module_endpoint(
    project_id: str, module_id: str, req: ExecuteRequest
):
    """Execute a module's source code and write STL/STEP output files."""
    mm = await get_mm()
    sl = await get_sl()
    try:
        module = await mm.get(project_id, module_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Module not found")

    try:
        result = await execute_module(
            module=module,
            output_dir=req.output_dir or str(settings.data_dir / "geometry" / module_id),
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    await sl.log_action(
        project_id, "module_executed",
        {"success": result.get("success"), "output_files": result.get("output_files")},
        module_id,
    )
    return result


@router.post("/{module_id}/validate")
async def validate_module(project_id: str, module_id: str):
    """Run VLAD geometry validation on the module's latest output files."""
    mm = await get_mm()
    sl = await get_sl()
    try:
        module = await mm.get(project_id, module_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Module not found")

    try:
        result = await run_vlad(module=module)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    await sl.log_action(
        project_id, "module_validated",
        {"passed": result.get("passed"), "tier_results": result.get("tier_results")},
        module_id,
    )
    return result


@router.post("/{module_id}/execute-and-validate")
async def execute_and_validate(
    project_id: str, module_id: str, req: ExecuteRequest
):
    """Execute module then immediately run VLAD — returns combined result."""
    mm = await get_mm()
    sl = await get_sl()
    try:
        module = await mm.get(project_id, module_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Module not found")

    try:
        result = await execute_with_repair(
            module=module,
            output_dir=req.output_dir or str(settings.data_dir / "geometry" / module_id),
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    await sl.log_action(
        project_id, "module_execute_validate",
        {
            "execute_success": result.get("execute", {}).get("success"),
            "vlad_passed": result.get("vlad", {}).get("passed"),
        },
        module_id,
    )
    return result


@router.get("/{module_id}/geometry")
async def get_geometry(project_id: str, module_id: str):
    """Return the latest geometry file path and a browser-accessible URL for the module."""
    mm = await get_mm()
    try:
        module = await mm.get(project_id, module_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Module not found")

    geometry_dir = settings.data_dir / "geometry" / module_id
    stl_path = geometry_dir / "output.stl"
    step_path = geometry_dir / "output.step"

    files: dict[str, Any] = {}
    if stl_path.exists():
        files["stl"] = {
            "path": str(stl_path),
            "url": f"/api/projects/{project_id}/modules/{module_id}/geometry/output.stl",
        }
    if step_path.exists():
        files["step"] = {
            "path": str(step_path),
            "url": f"/api/projects/{project_id}/modules/{module_id}/geometry/output.step",
        }

    if not files:
        raise HTTPException(status_code=404, detail="No geometry found — execute the module first")

    return {"module_id": module_id, "version": module["version"], "files": files}


@router.get("/{module_id}/vlad-history")
async def get_vlad_history(project_id: str, module_id: str):
    """Return the VLAD validation log for a module (newest first)."""
    sl = await get_sl()
    entries = await sl.get_module_log(module_id)
    vlad_entries = [e for e in entries if e.get("action") in ("module_validated", "module_execute_validate")]
    return {"module_id": module_id, "history": vlad_entries}


@router.post("/{module_id}/rollback")
async def rollback_module(
    project_id: str, module_id: str, req: RollbackRequest
):
    """Rollback a module to a specific previous version."""
    mm = await get_mm()
    sl = await get_sl()
    try:
        module = await mm.rollback(project_id, module_id, req.target_version)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    await sl.log_action(
        project_id, "module_rollback",
        {"rolled_back_to": req.target_version, "new_version": module["version"]},
        module_id,
    )
    clear_project_cache(project_id)
    return module


@router.post("/manifest")
async def generate_project_manifest(project_id: str):
    """Generate a .kfs.yaml manifest describing all modules in the project."""
    mm = await get_mm()
    sl = await get_sl()
    modules = await mm.list_all(project_id)

    try:
        manifest = await generate_manifest(project_id=project_id, modules=modules)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    await sl.log_action(project_id, "manifest_generated", {"module_count": len(modules)})
    return manifest
