"""
STEP file analyzer using CadQuery.

Imports STEP files via CadQuery's importStep, extracts body information,
face types (planar, cylindrical, conical, etc.), dimensions, bounding box,
and volume data.
"""

from pathlib import Path
from typing import Any

import cadquery as cq
from OCP.BRepAdaptor import BRepAdaptor_Surface
from OCP.GeomAbs import (
    GeomAbs_Plane,
    GeomAbs_Cylinder,
    GeomAbs_Cone,
    GeomAbs_Sphere,
    GeomAbs_Torus,
    GeomAbs_BSplineSurface,
    GeomAbs_BezierSurface,
    GeomAbs_OtherSurface,
)
from OCP.GProp import GProp_GProps
from OCP.BRepGProp import BRepGProp


# Map OCP surface type enums to human-readable names
_SURFACE_TYPE_NAMES = {
    GeomAbs_Plane: "planar",
    GeomAbs_Cylinder: "cylindrical",
    GeomAbs_Cone: "conical",
    GeomAbs_Sphere: "spherical",
    GeomAbs_Torus: "toroidal",
    GeomAbs_BSplineSurface: "bspline",
    GeomAbs_BezierSurface: "bezier",
    GeomAbs_OtherSurface: "other",
}


def _classify_face(face) -> str:
    """Classify a TopoDS_Face by its underlying surface type."""
    adaptor = BRepAdaptor_Surface(face)
    surface_type = adaptor.GetType()
    return _SURFACE_TYPE_NAMES.get(surface_type, "unknown")


def _compute_volume(shape) -> float:
    """Compute volume of an OCP shape using BRepGProp."""
    props = GProp_GProps()
    BRepGProp.VolumeProperties_s(shape, props)
    return props.Mass()


def _compute_surface_area(shape) -> float:
    """Compute surface area of an OCP shape using BRepGProp."""
    props = GProp_GProps()
    BRepGProp.SurfaceProperties_s(shape, props)
    return props.Mass()


class STEPAnalyzer:
    """
    Analyze STEP files to extract geometric properties.

    Uses CadQuery's importStep for loading and OCP (OpenCascade Python)
    for topology inspection including face classification, bounding box,
    volume, and surface area computation.
    """

    def analyze(self, file_path: str | Path) -> dict[str, Any]:
        """
        Analyze a STEP file and return structured geometry data.

        Args:
            file_path: Path to the STEP file.

        Returns:
            Dict containing:
                - file_path: Original file path
                - body_count: Number of solid bodies
                - faces: List of face info dicts (index, type)
                - face_types: Summary count of each face type
                - bounding_box: Dict with min/max xyz and dimensions
                - volume: Total volume in cubic units
                - surface_area: Total surface area in square units
                - format: "STEP"

        Raises:
            FileNotFoundError: If file does not exist.
            ValueError: If file cannot be parsed as STEP.
        """
        file_path = Path(file_path)
        if not file_path.exists():
            raise FileNotFoundError(f"STEP file not found: {file_path}")

        try:
            result = cq.importers.importStep(str(file_path))
        except Exception as e:
            raise ValueError(f"Failed to import STEP file: {e}")

        # Get the compound shape
        compound = result.val()

        # Count solid bodies
        solids = result.solids().vals()
        body_count = len(solids)

        # Analyze faces
        faces_info = []
        face_type_counts: dict[str, int] = {}

        for i, face in enumerate(result.faces().vals()):
            face_type = _classify_face(face.wrapped)
            faces_info.append({"index": i, "type": face_type})
            face_type_counts[face_type] = face_type_counts.get(face_type, 0) + 1

        # Bounding box
        bb = compound.BoundingBox()
        bounding_box = {
            "x_min": round(bb.xmin, 4),
            "y_min": round(bb.ymin, 4),
            "z_min": round(bb.zmin, 4),
            "x_max": round(bb.xmax, 4),
            "y_max": round(bb.ymax, 4),
            "z_max": round(bb.zmax, 4),
            "x_size": round(bb.xmax - bb.xmin, 4),
            "y_size": round(bb.ymax - bb.ymin, 4),
            "z_size": round(bb.zmax - bb.zmin, 4),
        }

        # Volume and surface area
        volume = round(_compute_volume(compound.wrapped), 4)
        surface_area = round(_compute_surface_area(compound.wrapped), 4)

        return {
            "file_path": str(file_path),
            "body_count": body_count,
            "face_count": len(faces_info),
            "faces": faces_info,
            "face_types": face_type_counts,
            "bounding_box": bounding_box,
            "volume": volume,
            "surface_area": surface_area,
            "format": "STEP",
        }
