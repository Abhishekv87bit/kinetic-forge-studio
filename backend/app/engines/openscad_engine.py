"""
OpenSCAD engine for per-component STL export, decimation, and glTF assembly.

Integrates with user's existing OpenSCAD projects by:
1. Parsing params.scad for SHOW_* visibility flags and color constants
2. Exporting each component individually via CLI -D overrides
3. Decimating heavy meshes (helical gears) with trimesh
4. Combining into a single GLB scene with per-component colors

Requires OpenSCAD Nightly with Manifold backend for performance.
"""

import asyncio
import json
import logging
import os
import re
import time
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import trimesh

from app.config import settings

logger = logging.getLogger(__name__)

# Maximum faces per component for browser viewport performance.
# GTX 1650 (4GB VRAM) handles ~500K total polygons smoothly.
MAX_FACES_PER_COMPONENT = 40_000
MAX_TOTAL_FACES = 500_000

# OpenSCAD preview quality — $fn=16 keeps helical gears manageable
VIEWPORT_FN = 16

# Maximum concurrent OpenSCAD export processes
MAX_CONCURRENT_EXPORTS = 3

# All known SHOW_* flags in the Ravigneaux assembly.
# Order matters: these are the flags we'll override via -D
ALL_SHOW_FLAGS = [
    "SHOW_SHAFT",
    "SHOW_SMALL_SUN",
    "SHOW_BIG_SUN",
    "SHOW_LONG_PINION",
    "SHOW_SHORT_PINION",
    "SHOW_CARRIER_1",
    "SHOW_CARRIER_2",
    "SHOW_CARRIER_3",
    "SHOW_RING",
    "SHOW_WASHERS",
    "SHOW_CLIPS",
    "SHOW_V_GROOVE",
    "SHOW_BEARINGS",
    "SHOW_DRIVE",
    "SHOW_ANCHOR",
    "SHOW_MOUNT_GEAR",
]

# Default component definitions: name -> (show_flag, rgb color, priority)
# Priority determines export order (lower = first). Skip low-priority for fast loads.
DEFAULT_COMPONENTS = {
    "ring":         {"flag": "SHOW_RING",         "color": [0.25, 0.25, 0.28], "priority": 1},
    "big_sun":      {"flag": "SHOW_BIG_SUN",      "color": [0.76, 0.60, 0.22], "priority": 1},
    "small_sun":    {"flag": "SHOW_SMALL_SUN",    "color": [0.15, 0.55, 0.30], "priority": 1},
    "carrier_1":    {"flag": "SHOW_CARRIER_1",    "color": [0.55, 0.55, 0.58], "priority": 2},
    "carrier_2":    {"flag": "SHOW_CARRIER_2",    "color": [0.45, 0.45, 0.50], "priority": 2},
    "carrier_3":    {"flag": "SHOW_CARRIER_3",    "color": [0.60, 0.60, 0.65], "priority": 2},
    "long_pinion":  {"flag": "SHOW_LONG_PINION",  "color": [0.85, 0.25, 0.20], "priority": 2},
    "short_pinion": {"flag": "SHOW_SHORT_PINION", "color": [1.00, 0.85, 0.00], "priority": 2},
    "shaft":        {"flag": "SHOW_SHAFT",        "color": [0.75, 0.75, 0.78], "priority": 3},
    "washers":      {"flag": "SHOW_WASHERS",      "color": [0.95, 0.80, 0.10], "priority": 3},
    "clips":        {"flag": "SHOW_CLIPS",        "color": [0.30, 0.30, 0.90], "priority": 3},
    "v_groove":     {"flag": "SHOW_V_GROOVE",      "color": [0.35, 0.20, 0.10], "priority": 3},
    "bearings":     {"flag": "SHOW_BEARINGS",     "color": [0.30, 0.60, 0.85], "priority": 3},
}


@dataclass
class ComponentExport:
    """Result of exporting a single component."""
    name: str
    stl_path: Path
    face_count: int
    vertex_count: int
    color: list[float]
    export_time: float = 0.0
    decimated: bool = False


@dataclass
class AssemblyExport:
    """Result of building the full assembly GLB."""
    glb_bytes: bytes
    components: list[ComponentExport]
    total_faces: int
    total_vertices: int
    build_time: float


class OpenSCADEngine:
    """
    Export per-component STLs from an OpenSCAD project and combine into GLB.

    Usage:
        engine = OpenSCADEngine()
        result = await engine.build_assembly_glb(
            scad_dir=Path("path/to/ravigneaux_v13"),
            cache_dir=Path("path/to/cache"),
        )
        # result.glb_bytes contains the binary GLB data
    """

    def __init__(
        self,
        openscad_path: str | None = None,
        openscad_lib_path: str | None = None,
    ):
        self.openscad_path = openscad_path or settings.openscad_path
        self.openscad_lib_path = openscad_lib_path or settings.openscad_lib_path
        self._semaphore = asyncio.Semaphore(MAX_CONCURRENT_EXPORTS)

    def parse_show_flags(self, scad_dir: Path) -> dict[str, dict]:
        """
        Parse params.scad to discover SHOW_* flags and color constants.

        Returns dict mapping component names to {flag, color, priority}.
        Falls back to DEFAULT_COMPONENTS if parsing fails.
        """
        params_path = scad_dir / "params.scad"
        if not params_path.exists():
            logger.warning("No params.scad found in %s, using defaults", scad_dir)
            return dict(DEFAULT_COMPONENTS)

        try:
            text = params_path.read_text(encoding="utf-8")
        except Exception as e:
            logger.warning("Failed to read params.scad: %s", e)
            return dict(DEFAULT_COMPONENTS)

        # Parse SHOW_* flags to find which are defined
        show_flags = set()
        for match in re.finditer(r'(SHOW_\w+)\s*=\s*(true|false)', text):
            show_flags.add(match.group(1))

        # Parse color constants: C_XXX = [r, g, b] or [r, g, b, a]
        colors = {}
        for match in re.finditer(
            r'(C_\w+)\s*=\s*\[\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)',
            text,
        ):
            colors[match.group(1)] = [
                float(match.group(2)),
                float(match.group(3)),
                float(match.group(4)),
            ]

        # Build component map from discovered flags
        # Map color constants to component names
        color_map = {
            "SHOW_SHAFT":        colors.get("C_SHAFT",   [0.75, 0.75, 0.78]),
            "SHOW_SMALL_SUN":    colors.get("C_SS",      [0.15, 0.55, 0.30]),
            "SHOW_BIG_SUN":      colors.get("C_SL",      [0.76, 0.60, 0.22]),
            "SHOW_LONG_PINION":  colors.get("C_PO",      [0.85, 0.25, 0.20]),
            "SHOW_SHORT_PINION": colors.get("C_PI",      [1.00, 0.85, 0.00]),
            "SHOW_CARRIER_1":    colors.get("C_CAR",     [0.55, 0.55, 0.58]),
            "SHOW_CARRIER_2":    colors.get("C_CAR2",    [0.45, 0.45, 0.50]),
            "SHOW_CARRIER_3":    colors.get("C_CAR3",    [0.60, 0.60, 0.65]),
            "SHOW_RING":         colors.get("C_RING",    [0.25, 0.25, 0.28]),
            "SHOW_WASHERS":      colors.get("C_WASHER",  [0.95, 0.80, 0.10]),
            "SHOW_CLIPS":        colors.get("C_CLIP",    [0.30, 0.30, 0.90]),
            "SHOW_V_GROOVE":     colors.get("C_GROOVE",  [0.35, 0.20, 0.10]),
            "SHOW_BEARINGS":     colors.get("C_BEARING", [0.30, 0.60, 0.85]),
            "SHOW_DRIVE":        colors.get("C_DRV_SHAFT", [0.40, 0.40, 0.45]),
            "SHOW_ANCHOR":       colors.get("C_ANCHOR",  [0.70, 0.20, 0.20]),
            "SHOW_MOUNT_GEAR":   [0.50, 0.50, 0.50],
        }

        # Priority tiers: 1=core gears, 2=structure, 3=hardware
        priority_map = {
            "SHOW_RING": 1, "SHOW_BIG_SUN": 1, "SHOW_SMALL_SUN": 1,
            "SHOW_CARRIER_1": 2, "SHOW_CARRIER_2": 2, "SHOW_CARRIER_3": 2,
            "SHOW_LONG_PINION": 2, "SHOW_SHORT_PINION": 2,
            "SHOW_SHAFT": 3, "SHOW_WASHERS": 3, "SHOW_CLIPS": 3,
            "SHOW_V_GROOVE": 3, "SHOW_BEARINGS": 3,
            "SHOW_DRIVE": 4, "SHOW_ANCHOR": 4, "SHOW_MOUNT_GEAR": 4,
        }

        components = {}
        for flag in show_flags:
            # Convert SHOW_BIG_SUN -> big_sun
            name = flag.replace("SHOW_", "").lower()
            components[name] = {
                "flag": flag,
                "color": color_map.get(flag, [0.5, 0.5, 0.5]),
                "priority": priority_map.get(flag, 3),
            }

        if not components:
            return dict(DEFAULT_COMPONENTS)

        return components

    async def export_component(
        self,
        scad_dir: Path,
        component_name: str,
        show_flag: str,
        cache_dir: Path,
        fn: int = VIEWPORT_FN,
    ) -> Path | None:
        """
        Export a single component from an OpenSCAD assembly.

        Sets all SHOW_* flags to false except the target, exports via CLI.
        Returns the STL path, or None if export fails.
        """
        stl_path = cache_dir / f"{component_name}.stl"
        assembly_path = scad_dir / "assembly.scad"

        if not assembly_path.exists():
            logger.error("assembly.scad not found in %s", scad_dir)
            return None

        # Check cache: if STL exists and is newer than all .scad files, skip
        if stl_path.exists():
            stl_mtime = stl_path.stat().st_mtime
            scad_files = list(scad_dir.rglob("*.scad"))
            newest_scad = max(f.stat().st_mtime for f in scad_files) if scad_files else 0
            if stl_mtime > newest_scad:
                logger.info("Cache hit for %s", component_name)
                return stl_path

        # Build argument list for subprocess_exec (bypasses shell, avoids
        # Windows cmd.exe issues with $fn quoting).
        # -D overrides take precedence over in-file assignments.
        args = [
            self.openscad_path,
            "--backend=manifold",
            "-D", f"$fn={fn}",
            "-D", "CROSS_SECTION=false",
            "-D", "EXPLODE=0",
            "-D", "MANUAL_SL=0",
            "-D", "MANUAL_SS=0",
            "-D", "MANUAL_CARRIER=0",
        ]
        for flag in ALL_SHOW_FLAGS:
            value = "true" if flag == show_flag else "false"
            args.extend(["-D", f"{flag}={value}"])

        args.extend(["-o", str(stl_path), str(assembly_path)])

        # Set OPENSCADPATH env var for BOSL2 library resolution
        env = os.environ.copy()
        env["OPENSCADPATH"] = self.openscad_lib_path

        logger.info("Exporting %s (fn=%d)...", component_name, fn)
        t0 = time.monotonic()

        async with self._semaphore:
            proc = await asyncio.create_subprocess_exec(
                *args,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=env,
            )
            stdout, stderr = await proc.communicate()

        elapsed = time.monotonic() - t0

        if proc.returncode != 0:
            logger.error(
                "OpenSCAD export failed for %s (%.1fs): %s",
                component_name, elapsed,
                stderr.decode("utf-8", errors="replace")[:500],
            )
            return None

        if not stl_path.exists() or stl_path.stat().st_size == 0:
            logger.warning("Empty STL for %s — component may be hidden", component_name)
            return None

        logger.info("Exported %s in %.1fs (%.1f KB)", component_name, elapsed,
                     stl_path.stat().st_size / 1024)
        return stl_path

    def decimate_mesh(
        self,
        mesh: trimesh.Trimesh,
        target_faces: int = MAX_FACES_PER_COMPONENT,
    ) -> tuple[trimesh.Trimesh, bool]:
        """
        Decimate mesh if it exceeds the face budget.

        Returns (mesh, was_decimated).
        """
        if len(mesh.faces) <= target_faces:
            return mesh, False

        logger.info(
            "Decimating %d -> %d faces (%.0f%% reduction)",
            len(mesh.faces), target_faces,
            (1 - target_faces / len(mesh.faces)) * 100,
        )
        try:
            import fast_simplification
            target_reduction = 1.0 - (target_faces / len(mesh.faces))
            # Clamp to valid range
            target_reduction = max(0.01, min(0.99, target_reduction))
            verts_out, faces_out = fast_simplification.simplify(
                mesh.vertices, mesh.faces, target_reduction=target_reduction
            )
            decimated = trimesh.Trimesh(vertices=verts_out, faces=faces_out)
            return decimated, True
        except ImportError:
            logger.warning("fast_simplification not installed, skipping decimation")
            return mesh, False
        except Exception as e:
            logger.warning("Decimation failed, using original: %s", e)
            return mesh, False

    def load_and_prepare_mesh(
        self,
        stl_path: Path,
        color: list[float],
        max_faces: int = MAX_FACES_PER_COMPONENT,
    ) -> tuple[trimesh.Trimesh, bool]:
        """
        Load STL, decimate if needed, apply color.
        Returns (mesh, was_decimated).
        """
        mesh = trimesh.load(stl_path, force="mesh")

        if isinstance(mesh, trimesh.Scene):
            mesh = mesh.dump(concatenate=True)

        # Decimate if over budget
        mesh, decimated = self.decimate_mesh(mesh, max_faces)

        # Apply face colors (RGBA 0-255)
        rgba = [int(c * 255) for c in color] + [255]
        mesh.visual = trimesh.visual.ColorVisuals(
            mesh=mesh,
            face_colors=np.tile(rgba, (len(mesh.faces), 1)),
        )

        return mesh, decimated

    async def build_assembly_glb(
        self,
        scad_dir: Path,
        cache_dir: Path,
        max_priority: int = 3,
        fn: int = VIEWPORT_FN,
    ) -> AssemblyExport:
        """
        Export all components and combine into a single GLB.

        Args:
            scad_dir: Path to the OpenSCAD project directory (contains assembly.scad)
            cache_dir: Path to store cached STL files
            max_priority: Only export components with priority <= this value
            fn: OpenSCAD $fn value (lower = faster but coarser)

        Returns:
            AssemblyExport with GLB bytes and metadata
        """
        t0 = time.monotonic()
        cache_dir.mkdir(parents=True, exist_ok=True)

        # Discover components
        components = self.parse_show_flags(scad_dir)
        logger.info("Found %d components in %s", len(components), scad_dir)

        # Filter by priority
        active = {
            name: info for name, info in components.items()
            if info["priority"] <= max_priority
        }
        logger.info("Exporting %d components (priority <= %d)", len(active), max_priority)

        # Export all components concurrently (bounded by semaphore)
        export_tasks = {}
        for name, info in active.items():
            task = asyncio.create_task(
                self.export_component(scad_dir, name, info["flag"], cache_dir, fn)
            )
            export_tasks[name] = task

        # Wait for all exports
        results = {}
        for name, task in export_tasks.items():
            results[name] = await task

        # Build trimesh scene from exported STLs
        scene = trimesh.Scene()
        component_exports = []
        total_faces = 0

        # Calculate per-component face budget to stay under total limit
        successful = {n: p for n, p in results.items() if p is not None}
        if successful:
            per_component_budget = min(
                MAX_FACES_PER_COMPONENT,
                MAX_TOTAL_FACES // len(successful),
            )
        else:
            per_component_budget = MAX_FACES_PER_COMPONENT

        for name, stl_path in sorted(successful.items()):
            info = active[name]
            try:
                mesh, decimated = self.load_and_prepare_mesh(
                    stl_path, info["color"], per_component_budget
                )
                scene.add_geometry(mesh, node_name=name)
                total_faces += len(mesh.faces)

                component_exports.append(ComponentExport(
                    name=name,
                    stl_path=stl_path,
                    face_count=len(mesh.faces),
                    vertex_count=len(mesh.vertices),
                    color=info["color"],
                    decimated=decimated,
                ))
            except Exception as e:
                logger.error("Failed to load %s: %s", name, e)

        total_vertices = sum(c.vertex_count for c in component_exports)
        elapsed = time.monotonic() - t0

        logger.info(
            "Assembly GLB: %d components, %d faces, %d vertices, %.1fs",
            len(component_exports), total_faces, total_vertices, elapsed,
        )

        # Export scene to GLB bytes
        if component_exports:
            glb_bytes = scene.export(file_type="glb")
        else:
            # Empty scene — return a tiny placeholder
            placeholder = trimesh.creation.box(extents=[10, 10, 10])
            glb_bytes = placeholder.export(file_type="glb")

        return AssemblyExport(
            glb_bytes=glb_bytes,
            components=component_exports,
            total_faces=total_faces,
            total_vertices=total_vertices,
            build_time=elapsed,
        )

    async def get_export_status(self, cache_dir: Path) -> dict:
        """Check what's already cached in the export directory."""
        if not cache_dir.exists():
            return {"cached": 0, "components": []}

        stls = list(cache_dir.glob("*.stl"))
        return {
            "cached": len(stls),
            "components": [
                {
                    "name": p.stem,
                    "size_bytes": p.stat().st_size,
                    "faces": self._quick_face_count(p),
                }
                for p in stls
            ],
        }

    def _quick_face_count(self, stl_path: Path) -> int | None:
        """Quick face count from binary STL header (first 84 bytes)."""
        try:
            with open(stl_path, "rb") as f:
                f.read(80)  # header
                count_bytes = f.read(4)
                if len(count_bytes) == 4:
                    import struct
                    return struct.unpack("<I", count_bytes)[0]
        except Exception:
            pass
        return None
