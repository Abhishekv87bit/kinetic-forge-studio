"""
STL file analyzer using trimesh.

Loads STL files via trimesh and extracts geometric properties including
bounding box, volume, surface area, watertight check, face/vertex counts.

Note: STL files lack B-rep topology — all analysis is mesh-based approximation.
Face types (planar, cylindrical, etc.) cannot be determined from STL alone.
"""

from pathlib import Path
from typing import Any

import trimesh


class STLAnalyzer:
    """
    Analyze STL files to extract geometric properties.

    Uses trimesh for mesh loading and inspection. Returns honest results
    with a limitations note, since STL format lacks the topological
    information available in B-rep formats like STEP.
    """

    def analyze(self, file_path: str | Path) -> dict[str, Any]:
        """
        Analyze an STL file and return structured geometry data.

        Args:
            file_path: Path to the STL file.

        Returns:
            Dict containing:
                - file_path: Original file path
                - face_count: Number of triangular faces
                - vertex_count: Number of vertices
                - bounding_box: Dict with min/max xyz and dimensions
                - volume: Estimated volume (only meaningful if watertight)
                - surface_area: Total surface area
                - is_watertight: Whether the mesh is closed/manifold
                - euler_number: Euler characteristic (V - E + F)
                - format: "STL"
                - limitations: Honest note about STL analysis limits

        Raises:
            FileNotFoundError: If file does not exist.
            ValueError: If file cannot be loaded as STL.
        """
        file_path = Path(file_path)
        if not file_path.exists():
            raise FileNotFoundError(f"STL file not found: {file_path}")

        try:
            mesh = trimesh.load(str(file_path), file_type="stl")
        except Exception as e:
            raise ValueError(f"Failed to load STL file: {e}")

        # Handle Scene objects (multiple meshes in one STL)
        if isinstance(mesh, trimesh.Scene):
            try:
                mesh = mesh.to_geometry()
            except Exception:
                raise ValueError("STL file contains no valid geometry")

        if not isinstance(mesh, trimesh.Trimesh):
            raise ValueError("Loaded object is not a valid triangle mesh")

        # Validate mesh has actual geometry
        if len(mesh.faces) == 0 or len(mesh.vertices) == 0:
            raise ValueError("STL file contains no geometry (empty mesh)")

        if mesh.bounds is None:
            raise ValueError("STL file contains degenerate geometry (no bounding box)")

        # Bounding box
        bounds = mesh.bounds  # [[xmin, ymin, zmin], [xmax, ymax, zmax]]
        bb_min = bounds[0]
        bb_max = bounds[1]
        extents = mesh.extents  # [x_size, y_size, z_size]

        bounding_box = {
            "x_min": round(float(bb_min[0]), 4),
            "y_min": round(float(bb_min[1]), 4),
            "z_min": round(float(bb_min[2]), 4),
            "x_max": round(float(bb_max[0]), 4),
            "y_max": round(float(bb_max[1]), 4),
            "z_max": round(float(bb_max[2]), 4),
            "x_size": round(float(extents[0]), 4),
            "y_size": round(float(extents[1]), 4),
            "z_size": round(float(extents[2]), 4),
        }

        # Volume (only meaningful for watertight meshes)
        is_watertight = bool(mesh.is_watertight)
        volume = round(float(mesh.volume), 4) if is_watertight else 0.0
        surface_area = round(float(mesh.area), 4)

        # Euler number: V - E + F
        euler_number = int(mesh.euler_number)

        return {
            "file_path": str(file_path),
            "face_count": len(mesh.faces),
            "vertex_count": len(mesh.vertices),
            "bounding_box": bounding_box,
            "volume": volume,
            "surface_area": surface_area,
            "is_watertight": is_watertight,
            "euler_number": euler_number,
            "format": "STL",
            "limitations": (
                "STL lacks topology - approximate analysis only. "
                "Face types (planar, cylindrical, etc.) cannot be determined. "
                "Volume is only valid for watertight meshes. "
                "For full geometry analysis, use STEP format."
            ),
        }
