"""SC-04 Viewport Route.

Serves per-module geometry as GLB for consumption by the Three.js frontend.

Endpoint:
    GET /modules/{module_id}/geometry
        Returns the module's geometry as a GLB binary (model/gltf-binary).
        The GLB is produced by converting the STL artefact written by
        ModuleExecutor (SC-02) via trimesh.

        Query params:
            v (int, optional): geometry version — used as a cache-buster by
                               the frontend.  Ignored server-side; its presence
                               forces the browser to refetch on version bump.

        Raises:
            404  — if no STL artefact exists for the requested module_id.
            500  — if the STL→GLB conversion fails (trimesh error).
"""
from __future__ import annotations

import logging
import os
import tempfile
from pathlib import Path

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse, Response

from backend.app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(tags=["viewport"])

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _stl_path(module_id: str) -> Path:
    """Return the expected STL artefact path for *module_id*."""
    return Path(settings.models_dir) / module_id / f"{module_id}.stl"


def _stl_to_glb_bytes(stl_path: Path) -> bytes:
    """Convert *stl_path* to a GLB binary and return the raw bytes.

    Uses ``trimesh`` for the conversion.  This runs synchronously; the
    router wraps it inside a thread via ``asyncio.to_thread`` so the
    FastAPI event loop is not blocked.

    Raises:
        ImportError: if trimesh is not installed.
        Exception:   if trimesh cannot load or export the STL.
    """
    try:
        import trimesh  # type: ignore[import]
    except ImportError as exc:
        raise ImportError(
            "trimesh is required for STL→GLB conversion — "
            "install it with: pip install trimesh"
        ) from exc

    mesh = trimesh.load(str(stl_path), force="mesh")
    glb_bytes: bytes = mesh.export(file_type="glb")
    return glb_bytes


# ---------------------------------------------------------------------------
# Route
# ---------------------------------------------------------------------------


@router.get(
    "/modules/{module_id}/geometry",
    summary="Serve module geometry as GLB",
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

    The frontend appends ``?v={geometryVersion}`` so that incrementing the
    Zustand ``geometryVersion`` counter forces a fresh fetch when new geometry
    is ready, bypassing the browser's HTTP cache.

    The STL artefact is expected at::

        {settings.models_dir}/{module_id}/{module_id}.stl

    which is exactly where :class:`~backend.app.services.module_executor.ModuleExecutor`
    writes it.
    """
    stl = _stl_path(module_id)

    if not stl.exists():
        logger.warning("Geometry not found for module %r at %s", module_id, stl)
        raise HTTPException(
            status_code=404,
            detail=f"No geometry artefact found for module '{module_id}'. "
                   "Run the module executor first.",
        )

    try:
        import asyncio
        glb_bytes = await asyncio.to_thread(_stl_to_glb_bytes, stl)
    except ImportError as exc:
        logger.error("trimesh not available: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    except Exception as exc:
        logger.error(
            "STL→GLB conversion failed for module %r (%s): %s",
            module_id,
            stl,
            exc,
        )
        raise HTTPException(
            status_code=500,
            detail=f"Geometry conversion failed: {exc}",
        ) from exc

    logger.info(
        "Serving GLB for module %r (%d bytes, v=%d)", module_id, len(glb_bytes), v
    )
    return Response(
        content=glb_bytes,
        media_type="model/gltf-binary",
        headers={
            # Instruct the browser not to cache; the frontend's ?v= param
            # handles cache-busting explicitly.
            "Cache-Control": "no-cache",
            "X-Module-Id": module_id,
        },
    )
