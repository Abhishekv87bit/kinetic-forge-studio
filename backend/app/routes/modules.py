"""SC-01 / SC-02 / SC-03 / SC-04 / SC-08 Module API Routes.

All 11 module endpoints:
    POST   /modules                              — create module (SC-01)
    GET    /modules                              — list all modules (SC-01)
    GET    /modules/{module_id}                  — get module detail (SC-01)
    PUT    /modules/{module_id}                  — update module code (SC-01)
    POST   /modules/{module_id}/execute          — execute module (SC-02)
    POST   /modules/{module_id}/validate         — run VLAD validation (SC-03)
    POST   /modules/{module_id}/execute-and-validate — execute + VLAD (SC-02+SC-03)
    GET    /modules/{module_id}/geometry         — serve GLB geometry (SC-04)
    GET    /modules/{module_id}/vlad-history     — VLAD run history (SC-03)
    POST   /modules/{module_id}/rollback         — rollback to version (SC-01)
    POST   /modules/{module_id}/manifest         — generate .kfs.yaml (SC-08)
"""
from __future__ import annotations

import asyncio
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import Response
from pydantic import BaseModel

from backend.app.config import settings
from backend.app.models.module import Module, ModuleManager, ModuleVersion
from backend.app.services.module_executor import ExecutionResult, ModuleExecutor
from backend.app.services.vlad_bridge import VladBridge
from backend.app.services.vlad_runner import VladResult, VladRunner

# ManifestGenerator imports kfs_core which may not be installed in all
# environments.  Import it lazily inside the endpoint that needs it so that
# the rest of the router loads cleanly when kfs_core is absent.
def _get_manifest_generator_class():
    from backend.app.services.manifest_generator import ManifestGenerator  # noqa: PLC0415
    return ManifestGenerator

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/modules", tags=["modules"])


# ---------------------------------------------------------------------------
# Shared dependency factories
# ---------------------------------------------------------------------------


def _db_path() -> str:
    """Extract the filesystem path from a sqlite:/// URL."""
    url = settings.database_url
    if url.startswith("sqlite:///"):
        return url[len("sqlite:///"):]
    return url


def get_module_manager() -> ModuleManager:
    return ModuleManager(db_path=_db_path())


def get_executor() -> ModuleExecutor:
    return ModuleExecutor(output_dir=settings.models_dir)


def get_vlad_runner() -> VladRunner:
    return VladRunner(db_path=_db_path())


# ---------------------------------------------------------------------------
# GLB geometry helpers (mirrors SC-04 viewport logic)
# ---------------------------------------------------------------------------


def _stl_path(module_id: str) -> Path:
    return Path(settings.models_dir) / module_id / f"{module_id}.stl"


def _stl_to_glb_bytes(stl_path: Path) -> bytes:
    """Convert *stl_path* to GLB bytes via trimesh (synchronous)."""
    try:
        import trimesh  # type: ignore[import]
    except ImportError as exc:
        raise ImportError(
            "trimesh is required for STL→GLB conversion — "
            "install it with: pip install trimesh"
        ) from exc
    mesh = trimesh.load(str(stl_path), force="mesh")
    return mesh.export(file_type="glb")


# ---------------------------------------------------------------------------
# Request / response schemas
# ---------------------------------------------------------------------------


class CreateModuleRequest(BaseModel):
    name: str
    code: str
    parameters: Optional[Dict[str, Any]] = None


class UpdateModuleRequest(BaseModel):
    code: str


class RollbackRequest(BaseModel):
    target_version: int


class ManifestRequest(BaseModel):
    manifest_path: str
    project_name: str = "KFS Project"
    description: Optional[str] = None


class ModuleResponse(BaseModel):
    id: str
    name: str
    code: str
    version: int
    status: str
    parameters: Optional[Dict[str, Any]] = None
    vlad_verdict: Optional[Dict[str, Any]] = None
    created_at: str
    updated_at: str


class ExecutionResultResponse(BaseModel):
    module_id: str
    status: str
    stl_path: Optional[str] = None
    step_path: Optional[str] = None
    error: Optional[str] = None


class VladCheckResponse(BaseModel):
    check_id: str
    status: str
    detail: str


class VladResultResponse(BaseModel):
    module_id: str
    verdict: str
    passed: bool
    fail_count: int
    warn_count: int
    pass_count: int
    mechanism_type: str
    checks: List[VladCheckResponse]


class ManifestResponse(BaseModel):
    manifest_path: str
    object_count: int
    project_name: str


# ---------------------------------------------------------------------------
# Conversion helpers
# ---------------------------------------------------------------------------


def _module_to_resp(m: Module) -> ModuleResponse:
    return ModuleResponse(
        id=m.id,
        name=m.name,
        code=m.code,
        version=m.version,
        status=m.status,
        parameters=m.parameters,
        vlad_verdict=m.vlad_verdict,
        created_at=m.created_at,
        updated_at=m.updated_at,
    )


def _vlad_to_resp(r: VladResult) -> VladResultResponse:
    return VladResultResponse(
        module_id=r.module_id,
        verdict=r.verdict,
        passed=r.passed,
        fail_count=r.fail_count,
        warn_count=r.warn_count,
        pass_count=r.pass_count,
        mechanism_type=r.mechanism_type,
        checks=[
            VladCheckResponse(
                check_id=c.check_id,
                status=c.status,
                detail=c.detail,
            )
            for c in r.checks
        ],
    )


# ---------------------------------------------------------------------------
# 1. POST /modules — create
# ---------------------------------------------------------------------------


@router.post("", status_code=201, response_model=ModuleResponse)
async def create_module(
    body: CreateModuleRequest,
    mm: ModuleManager = Depends(get_module_manager),
) -> ModuleResponse:
    """Persist a new module record at version 1 with status 'draft'."""
    module = mm.create(name=body.name, code=body.code, parameters=body.parameters)
    return _module_to_resp(module)


# ---------------------------------------------------------------------------
# 2. GET /modules — list all
# ---------------------------------------------------------------------------


@router.get("", response_model=List[ModuleResponse])
async def list_modules(
    mm: ModuleManager = Depends(get_module_manager),
) -> List[ModuleResponse]:
    """Return all modules ordered by creation time (oldest first)."""
    return [_module_to_resp(m) for m in mm.list_all()]


# ---------------------------------------------------------------------------
# 3. GET /modules/{module_id} — get detail
# ---------------------------------------------------------------------------


@router.get("/{module_id}", response_model=ModuleResponse)
async def get_module(
    module_id: str,
    mm: ModuleManager = Depends(get_module_manager),
) -> ModuleResponse:
    """Fetch a single module by ID."""
    module = mm.get(module_id)
    if module is None:
        raise HTTPException(status_code=404, detail=f"Module '{module_id}' not found")
    return _module_to_resp(module)


# ---------------------------------------------------------------------------
# 4. PUT /modules/{module_id} — update code
# ---------------------------------------------------------------------------


@router.put("/{module_id}", response_model=ModuleResponse)
async def update_module(
    module_id: str,
    body: UpdateModuleRequest,
    mm: ModuleManager = Depends(get_module_manager),
) -> ModuleResponse:
    """Replace a module's code and increment its version (snapshots old code)."""
    try:
        module = mm.update_code(module_id, body.code)
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Module '{module_id}' not found")
    return _module_to_resp(module)


# ---------------------------------------------------------------------------
# 5. POST /modules/{module_id}/execute — execute
# ---------------------------------------------------------------------------


@router.post("/{module_id}/execute", response_model=ExecutionResultResponse)
async def execute_module(
    module_id: str,
    mm: ModuleManager = Depends(get_module_manager),
    executor: ModuleExecutor = Depends(get_executor),
) -> ExecutionResultResponse:
    """Execute the stored CadQuery code and write STL + STEP artefacts."""
    module = mm.get(module_id)
    if module is None:
        raise HTTPException(status_code=404, detail=f"Module '{module_id}' not found")

    mm.update_status(module_id, "executing")
    result: ExecutionResult = await executor.execute(module_id, module.code)
    mm.update_status(module_id, result.status)

    return ExecutionResultResponse(
        module_id=result.module_id,
        status=result.status,
        stl_path=result.stl_path,
        step_path=result.step_path,
        error=result.error,
    )


# ---------------------------------------------------------------------------
# 6. POST /modules/{module_id}/validate — VLAD only
# ---------------------------------------------------------------------------


@router.post("/{module_id}/validate", response_model=VladResultResponse)
async def validate_module(
    module_id: str,
    mm: ModuleManager = Depends(get_module_manager),
    vlad: VladRunner = Depends(get_vlad_runner),
) -> VladResultResponse:
    """Run VLAD validation against the current module code."""
    module = mm.get(module_id)
    if module is None:
        raise HTTPException(status_code=404, detail=f"Module '{module_id}' not found")

    bridge = VladBridge(module.code)
    try:
        bridge_path = bridge.write_bridge()
        result = await asyncio.to_thread(vlad.run, module_id, str(bridge_path))
        mm.update_vlad_verdict(
            module_id,
            {"verdict": result.verdict, "passed": result.passed},
        )
    except Exception as exc:
        logger.error("VLAD validation failed for module %r: %s", module_id, exc)
        raise HTTPException(
            status_code=500,
            detail=f"VLAD validation error: {exc}",
        ) from exc
    finally:
        bridge.cleanup()

    return _vlad_to_resp(result)


# ---------------------------------------------------------------------------
# 7. POST /modules/{module_id}/execute-and-validate
# ---------------------------------------------------------------------------


@router.post("/{module_id}/execute-and-validate", response_model=ExecutionResultResponse)
async def execute_and_validate_module(
    module_id: str,
    mm: ModuleManager = Depends(get_module_manager),
    executor: ModuleExecutor = Depends(get_executor),
    vlad: VladRunner = Depends(get_vlad_runner),
) -> ExecutionResultResponse:
    """Execute the module code, then run VLAD validation if execution succeeds."""
    module = mm.get(module_id)
    if module is None:
        raise HTTPException(status_code=404, detail=f"Module '{module_id}' not found")

    mm.update_status(module_id, "executing")
    result: ExecutionResult = await executor.execute(module_id, module.code)
    mm.update_status(module_id, result.status)

    if result.status == "valid":
        bridge = VladBridge(module.code)
        try:
            bridge_path = bridge.write_bridge()
            vlad_result = await asyncio.to_thread(vlad.run, module_id, str(bridge_path))
            mm.update_vlad_verdict(
                module_id,
                {"verdict": vlad_result.verdict, "passed": vlad_result.passed},
            )
        except Exception as exc:
            logger.warning(
                "VLAD failed after successful execution for %r: %s", module_id, exc
            )
        finally:
            bridge.cleanup()

    return ExecutionResultResponse(
        module_id=result.module_id,
        status=result.status,
        stl_path=result.stl_path,
        step_path=result.step_path,
        error=result.error,
    )


# ---------------------------------------------------------------------------
# 8. GET /modules/{module_id}/geometry — serve GLB (SC-04)
# ---------------------------------------------------------------------------


@router.get(
    "/{module_id}/geometry",
    response_class=Response,
    responses={
        200: {
            "content": {"model/gltf-binary": {}},
            "description": "GLB binary of the module geometry.",
        },
        404: {"description": "No geometry artefact found for this module."},
        500: {"description": "STL→GLB conversion failed."},
    },
)
async def get_module_geometry(
    module_id: str,
    v: int = Query(default=0, description="Geometry version (cache-buster, ignored server-side)"),
) -> Response:
    """Return the module's geometry as a GLB binary.

    The STL is expected at ``{settings.models_dir}/{module_id}/{module_id}.stl``,
    which is where ModuleExecutor writes it.  ``?v=`` is a frontend cache-buster.
    """
    stl = _stl_path(module_id)
    if not stl.exists():
        logger.warning("Geometry not found for module %r at %s", module_id, stl)
        raise HTTPException(
            status_code=404,
            detail=f"No geometry artefact for module '{module_id}'. Run execute first.",
        )

    try:
        glb_bytes = await asyncio.to_thread(_stl_to_glb_bytes, stl)
    except ImportError as exc:
        logger.error("trimesh not available: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    except Exception as exc:
        logger.error("STL→GLB conversion failed for %r: %s", module_id, exc)
        raise HTTPException(
            status_code=500,
            detail=f"Geometry conversion failed: {exc}",
        ) from exc

    logger.info("Serving GLB for module %r (%d bytes, v=%d)", module_id, len(glb_bytes), v)
    return Response(
        content=glb_bytes,
        media_type="model/gltf-binary",
        headers={
            "Cache-Control": "no-cache",
            "X-Module-Id": module_id,
        },
    )


# ---------------------------------------------------------------------------
# 9. GET /modules/{module_id}/vlad-history
# ---------------------------------------------------------------------------


@router.get("/{module_id}/vlad-history", response_model=List[VladResultResponse])
async def get_vlad_history(
    module_id: str,
    limit: int = Query(default=10, ge=1, le=100, description="Max results to return"),
    mm: ModuleManager = Depends(get_module_manager),
    vlad: VladRunner = Depends(get_vlad_runner),
) -> List[VladResultResponse]:
    """Return the VLAD validation run history for a module (most recent first)."""
    module = mm.get(module_id)
    if module is None:
        raise HTTPException(status_code=404, detail=f"Module '{module_id}' not found")

    results = await asyncio.to_thread(vlad.get_history, module_id, limit)
    return [_vlad_to_resp(r) for r in results]


# ---------------------------------------------------------------------------
# 10. POST /modules/{module_id}/rollback
# ---------------------------------------------------------------------------


@router.post("/{module_id}/rollback", response_model=ModuleResponse)
async def rollback_module(
    module_id: str,
    body: RollbackRequest,
    mm: ModuleManager = Depends(get_module_manager),
) -> ModuleResponse:
    """Rollback a module to the code from a previous version.

    The version number continues to increment (monotonic history); the
    live code is restored from the requested snapshot.
    """
    try:
        module = mm.rollback(module_id, body.target_version)
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Module '{module_id}' not found")
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return _module_to_resp(module)


# ---------------------------------------------------------------------------
# 11. POST /modules/{module_id}/manifest
# ---------------------------------------------------------------------------


class _ValidModuleAdapter:
    """Thin async wrapper so ManifestGenerator.generate() can call list_valid().

    ManifestGenerator expects ``await manager.list_valid()``.  ModuleManager
    provides a synchronous ``list_all()``.  This adapter filters by status
    without modifying SC-01.
    """

    def __init__(self, mm: ModuleManager) -> None:
        self._mm = mm

    async def list_valid(self) -> list:
        return [m for m in self._mm.list_all() if m.status == "valid"]


@router.post("/{module_id}/manifest", response_model=ManifestResponse)
async def generate_manifest(
    module_id: str,
    body: ManifestRequest,
    mm: ModuleManager = Depends(get_module_manager),
) -> ManifestResponse:
    """Generate a .kfs.yaml manifest for all currently valid modules.

    The triggering *module_id* is verified to exist before generation begins.
    The manifest includes ALL valid modules, not only the triggering one.
    """
    module = mm.get(module_id)
    if module is None:
        raise HTTPException(status_code=404, detail=f"Module '{module_id}' not found")

    ManifestGenerator = _get_manifest_generator_class()
    gen = ManifestGenerator(
        module_manager=_ValidModuleAdapter(mm),
        output_dir=settings.models_dir,
    )
    try:
        manifest = await gen.generate(
            body.manifest_path,
            project_name=body.project_name,
            description=body.description,
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.error("Manifest generation failed: %s", exc)
        raise HTTPException(
            status_code=500,
            detail=f"Manifest generation failed: {exc}",
        ) from exc

    return ManifestResponse(
        manifest_path=body.manifest_path,
        object_count=len(manifest.objects),
        project_name=manifest.name,
    )
