"""
Render preview generator for Kinetic Forge Studio.

Generates PNG preview images from CAD outputs:
- OpenSCAD: uses openscad CLI --render -o render.png
- CadQuery/STEP: uses trimesh to render a screenshot
- STL: uses trimesh to render a screenshot

Preview images are stored in projects/{id}/renders/ with version tracking.
"""

import asyncio
import logging
import os
import time
from pathlib import Path

from app.config import settings

logger = logging.getLogger(__name__)


async def render_openscad_preview(
    scad_path: Path,
    output_path: Path,
    width: int = 800,
    height: int = 600,
) -> Path | None:
    """
    Render a PNG preview from an OpenSCAD file.

    Uses the OpenSCAD CLI with --render flag.
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)

    openscad_path = settings.openscad_path
    lib_path = settings.openscad_lib_path

    args = [
        openscad_path,
        "--backend=manifold",
        f"--imgsize={width},{height}",
        "--colorscheme=Tomorrow Night",
        "-o", str(output_path),
        str(scad_path),
    ]

    env = os.environ.copy()
    env["OPENSCADPATH"] = lib_path

    t0 = time.monotonic()
    try:
        proc = await asyncio.create_subprocess_exec(
            *args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
        )
        _, stderr = await asyncio.wait_for(proc.communicate(), timeout=120)
        elapsed = time.monotonic() - t0

        if proc.returncode != 0:
            logger.error("OpenSCAD render failed (%.1fs): %s", elapsed,
                         stderr.decode("utf-8", errors="replace")[:300])
            return None

        if output_path.exists() and output_path.stat().st_size > 0:
            logger.info("Rendered preview in %.1fs: %s", elapsed, output_path)
            return output_path

    except asyncio.TimeoutError:
        logger.error("OpenSCAD render timed out")
    except Exception as e:
        logger.error("Render error: %s", e)

    return None


async def render_stl_preview(
    stl_path: Path,
    output_path: Path,
    width: int = 800,
    height: int = 600,
) -> Path | None:
    """
    Render a PNG preview from an STL file using trimesh + Pillow.

    Falls back to a simple wireframe if pyrender is not available.
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        import trimesh
        from PIL import Image
        import numpy as np

        mesh = trimesh.load(stl_path, force="mesh")

        # Try pyrender first (full render)
        try:
            scene = mesh.scene()
            png_data = scene.save_image(resolution=(width, height))
            if png_data:
                output_path.write_bytes(png_data)
                return output_path
        except Exception:
            pass

        # Fallback: save a simple projected view using trimesh's built-in
        try:
            scene = trimesh.Scene(mesh)
            png_data = scene.save_image(resolution=(width, height))
            if png_data:
                output_path.write_bytes(png_data)
                return output_path
        except Exception as e:
            logger.warning("trimesh render fallback failed: %s", e)

    except ImportError:
        logger.warning("trimesh or Pillow not installed for STL preview")

    return None


async def render_preview(
    file_path: Path,
    renders_dir: Path,
    version: int = 1,
) -> Path | None:
    """
    Auto-detect file type and render a preview.

    Returns the path to the rendered PNG, or None if rendering fails.
    """
    suffix = file_path.suffix.lower()
    output_name = f"{file_path.stem}_v{version}.png"
    output_path = renders_dir / output_name

    if suffix == ".scad":
        return await render_openscad_preview(file_path, output_path)
    elif suffix == ".stl":
        return await render_stl_preview(file_path, output_path)
    elif suffix in (".step", ".stp"):
        # Convert STEP -> STL via CadQuery first, then render
        try:
            from app.engines.cadquery_engine import CadQueryEngine
            engine = CadQueryEngine()
            temp_stl = renders_dir / f"{file_path.stem}_temp.stl"
            exports = await engine.export(file_path, ["stl"], renders_dir)
            if "stl" in exports:
                result = await render_stl_preview(exports["stl"], output_path)
                temp_stl.unlink(missing_ok=True)
                return result
        except Exception as e:
            logger.warning("STEP preview failed: %s", e)
        return None
    else:
        logger.warning("Unsupported file type for preview: %s", suffix)
        return None
