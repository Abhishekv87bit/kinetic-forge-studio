"""
Native app launcher API.

Opens project files in their native applications (OpenSCAD, FreeCAD, etc.)
instead of trying to render complex geometry in a browser WebGL viewport.
"""

import logging
import asyncio
import os
from pathlib import Path

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.config import settings
from app.routes.projects import get_pm

router = APIRouter(prefix="/api/projects/{project_id}/viewer", tags=["viewer"])

logger = logging.getLogger(__name__)


class OpenFileRequest(BaseModel):
    file_path: str | None = None  # specific file, or None for assembly.scad


@router.get("/files")
async def list_project_files(project_id: str):
    """
    List all viewable files for a project.

    Returns file paths organized by type, with metadata for the UI.
    """
    pm = await get_pm()
    try:
        project = await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    result = {
        "project_id": project_id,
        "project_name": project.name,
        "scad_dir": project.scad_dir,
        "scad_files": [],
        "step_files": [],
        "stl_files": [],
        "other_files": [],
    }

    # Scan scad_dir for OpenSCAD files
    if project.scad_dir:
        scad_path = Path(project.scad_dir)
        if scad_path.exists():
            for f in sorted(scad_path.rglob("*.scad")):
                rel = f.relative_to(scad_path)
                result["scad_files"].append({
                    "name": str(rel),
                    "path": str(f),
                    "size_bytes": f.stat().st_size,
                    "is_assembly": f.name == "assembly.scad",
                    "is_params": f.name == "params.scad",
                })

    # Scan project data dir for exported files
    data_dir = project.data_dir
    if data_dir.exists():
        for f in sorted(data_dir.rglob("*.step")) + sorted(data_dir.rglob("*.stp")):
            result["step_files"].append({
                "name": f.name,
                "path": str(f),
                "size_bytes": f.stat().st_size,
            })
        for f in sorted(data_dir.rglob("*.stl")):
            result["stl_files"].append({
                "name": f.name,
                "path": str(f),
                "size_bytes": f.stat().st_size,
            })

    # Parse SHOW flags if scad_dir exists
    if project.scad_dir:
        params_path = Path(project.scad_dir) / "params.scad"
        if params_path.exists():
            try:
                from app.engines.openscad_engine import OpenSCADEngine
                engine = OpenSCADEngine()
                components = engine.parse_show_flags(Path(project.scad_dir))
                result["scad_components"] = [
                    {"name": name, "flag": info["flag"],
                     "color": info["color"], "priority": info["priority"]}
                    for name, info in sorted(
                        components.items(), key=lambda x: x[1]["priority"]
                    )
                ]
            except Exception as e:
                logger.warning("Failed to parse SHOW flags: %s", e)

    return result


@router.post("/open")
async def open_in_native_app(project_id: str, req: OpenFileRequest):
    """
    Launch a file in its native application.

    - .scad files -> OpenSCAD (Nightly)
    - .step/.stp files -> FreeCAD
    - .stl files -> system default STL viewer

    Returns immediately after launching (non-blocking).
    """
    pm = await get_pm()
    try:
        project = await pm.open(project_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Project not found")

    # Determine which file to open
    if req.file_path:
        file_path = Path(req.file_path)
    elif project.scad_dir:
        file_path = Path(project.scad_dir) / "assembly.scad"
    else:
        raise HTTPException(status_code=400, detail="No file specified and no scad_dir set")

    if not file_path.exists():
        raise HTTPException(status_code=404, detail=f"File not found: {file_path}")

    ext = file_path.suffix.lower()

    # Choose the right application
    if ext == ".scad":
        app_path = settings.openscad_path
        app_name = "OpenSCAD"
        # Use the GUI version (openscad.exe, not openscad.com)
        gui_path = app_path.replace("openscad.com", "openscad.exe")
        if Path(gui_path).exists():
            app_path = gui_path
        cmd = [app_path, str(file_path)]
    elif ext in (".step", ".stp"):
        app_path = settings.freecad_path
        app_name = "FreeCAD"
        # Use FreeCAD GUI, not FreeCADCmd
        gui_path = app_path.replace("FreeCADCmd.exe", "FreeCAD.exe")
        if Path(gui_path).exists():
            app_path = gui_path
        cmd = [app_path, str(file_path)]
    elif ext == ".stl":
        # Use system default (os.startfile on Windows)
        app_name = "system default"
        cmd = None  # Will use os.startfile
    else:
        raise HTTPException(
            status_code=400,
            detail=f"No viewer configured for {ext} files",
        )

    # Launch the application (fire-and-forget)
    try:
        if cmd:
            # Detached subprocess — doesn't block the server
            await asyncio.to_thread(
                _launch_detached, cmd
            )
        else:
            # Windows os.startfile for system default
            await asyncio.to_thread(os.startfile, str(file_path))

        logger.info("Opened %s in %s", file_path.name, app_name)
        return {
            "status": "launched",
            "app": app_name,
            "file": str(file_path),
        }
    except Exception as e:
        logger.error("Failed to launch %s: %s", app_name, e)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to launch {app_name}: {e}",
        )


def _launch_detached(cmd: list[str]):
    """Launch a subprocess detached from the server process."""
    import subprocess
    # CREATE_NEW_PROCESS_GROUP + DETACHED_PROCESS on Windows
    creation_flags = 0
    if os.name == "nt":
        creation_flags = (
            subprocess.CREATE_NEW_PROCESS_GROUP
            | subprocess.DETACHED_PROCESS
        )
    subprocess.Popen(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        creationflags=creation_flags,
    )
