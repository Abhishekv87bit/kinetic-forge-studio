"""
Geometry engine for parametric shape generation and export.

Uses CadQuery for precise B-rep geometry and trimesh for glTF export.
Supports: box, cylinder, gear-like shape (simplified spur gear profile).

Pipeline: CadQuery (parametric B-rep) -> STL (intermediate) -> trimesh -> glTF/GLB
Also supports direct STEP export via CadQuery.
"""

import math
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal

import cadquery as cq
import trimesh


@dataclass
class BoundingBox:
    """Axis-aligned bounding box."""
    x_min: float
    y_min: float
    z_min: float
    x_max: float
    y_max: float
    z_max: float

    @property
    def x_size(self) -> float:
        return self.x_max - self.x_min

    @property
    def y_size(self) -> float:
        return self.y_max - self.y_min

    @property
    def z_size(self) -> float:
        return self.z_max - self.z_min


@dataclass
class GeometryResult:
    """Result from shape generation."""
    name: str
    shape_type: str
    parameters: dict
    cq_solid: object  # cadquery.Workplane
    bounding_box: BoundingBox
    mesh: trimesh.Trimesh | None = None


class GeometryEngine:
    """Parametric geometry engine using CadQuery + trimesh."""

    def generate_box(
        self,
        length: float = 10.0,
        width: float = 10.0,
        height: float = 10.0,
        name: str = "box",
    ) -> GeometryResult:
        """Generate a parametric box."""
        solid = cq.Workplane("XY").box(length, width, height)
        bb = self._get_bounding_box(solid)
        return GeometryResult(
            name=name,
            shape_type="box",
            parameters={"length": length, "width": width, "height": height},
            cq_solid=solid,
            bounding_box=bb,
        )

    def generate_cylinder(
        self,
        radius: float = 5.0,
        height: float = 10.0,
        name: str = "cylinder",
    ) -> GeometryResult:
        """Generate a parametric cylinder."""
        solid = cq.Workplane("XY").cylinder(height, radius)
        bb = self._get_bounding_box(solid)
        return GeometryResult(
            name=name,
            shape_type="cylinder",
            parameters={"radius": radius, "height": height},
            cq_solid=solid,
            bounding_box=bb,
        )

    def generate_gear(
        self,
        module: float = 1.5,
        teeth: int = 20,
        height: float = 8.0,
        pressure_angle_deg: float = 20.0,
        name: str = "gear",
    ) -> GeometryResult:
        """
        Generate a simplified spur gear profile.

        Uses involute-approximated tooth profile built from CadQuery 2D sketch
        extruded to height. Not production-grade involute, but geometrically
        representative for visualization and bounding-box validation.
        """
        pitch_radius = module * teeth / 2.0
        addendum = module
        dedendum = 1.25 * module
        outer_radius = pitch_radius + addendum
        root_radius = pitch_radius - dedendum
        tooth_angle = 360.0 / teeth

        # Build gear profile as 2D polygon
        points = []
        for i in range(teeth):
            base_angle = i * tooth_angle
            # Root arc start
            a0 = math.radians(base_angle)
            # Tooth rise
            a1 = math.radians(base_angle + tooth_angle * 0.15)
            # Tooth tip start
            a2 = math.radians(base_angle + tooth_angle * 0.25)
            # Tooth tip end
            a3 = math.radians(base_angle + tooth_angle * 0.45)
            # Tooth fall
            a4 = math.radians(base_angle + tooth_angle * 0.55)
            # Root arc end
            a5 = math.radians(base_angle + tooth_angle * 0.70)
            # Next root start
            a6 = math.radians(base_angle + tooth_angle)

            points.extend([
                (root_radius * math.cos(a0), root_radius * math.sin(a0)),
                (root_radius * math.cos(a1), root_radius * math.sin(a1)),
                (outer_radius * math.cos(a2), outer_radius * math.sin(a2)),
                (outer_radius * math.cos(a3), outer_radius * math.sin(a3)),
                (root_radius * math.cos(a4), root_radius * math.sin(a4)),
                (root_radius * math.cos(a5), root_radius * math.sin(a5)),
            ])

        # Close the polygon
        points.append(points[0])

        # Build CadQuery solid from polygon
        solid = (
            cq.Workplane("XY")
            .polyline(points)
            .close()
            .extrude(height)
        )

        # Add center bore (shaft hole)
        bore_radius = module * 2.0
        if bore_radius < root_radius * 0.8:
            solid = solid.faces(">Z").workplane().hole(bore_radius * 2.0)

        bb = self._get_bounding_box(solid)
        return GeometryResult(
            name=name,
            shape_type="gear",
            parameters={
                "module": module,
                "teeth": teeth,
                "height": height,
                "pressure_angle_deg": pressure_angle_deg,
                "pitch_radius": pitch_radius,
                "outer_radius": outer_radius,
                "root_radius": root_radius,
            },
            cq_solid=solid,
            bounding_box=bb,
        )

    def export_stl(self, result: GeometryResult, path: Path) -> Path:
        """Export geometry to STL file."""
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        cq.exporters.export(result.cq_solid, str(path))
        return path

    def export_step(self, result: GeometryResult, path: Path) -> Path:
        """Export geometry to STEP file."""
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        cq.exporters.export(result.cq_solid, str(path))
        return path

    def export_gltf(self, result: GeometryResult, path: Path) -> Path:
        """Export geometry to glTF binary (.glb) via trimesh."""
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)

        mesh = self._to_trimesh(result)
        result.mesh = mesh
        mesh.export(str(path), file_type="glb")
        return path

    def to_glb_bytes(self, result: GeometryResult) -> bytes:
        """Convert geometry to GLB binary data (for streaming)."""
        mesh = self._to_trimesh(result)
        result.mesh = mesh
        return mesh.export(file_type="glb")

    def generate_assembly_glb(self, results: list[GeometryResult]) -> bytes:
        """Combine multiple geometry results into a single GLB scene."""
        scene = trimesh.Scene()
        for r in results:
            mesh = self._to_trimesh(r)
            scene.add_geometry(mesh, node_name=r.name)
        return scene.export(file_type="glb")

    def _to_trimesh(self, result: GeometryResult) -> trimesh.Trimesh:
        """Convert CadQuery solid to trimesh via intermediate STL."""
        if result.mesh is not None:
            return result.mesh

        with tempfile.NamedTemporaryFile(suffix=".stl", delete=False) as tmp:
            tmp_path = tmp.name

        cq.exporters.export(result.cq_solid, tmp_path)
        mesh = trimesh.load(tmp_path)
        Path(tmp_path).unlink(missing_ok=True)

        if isinstance(mesh, trimesh.Scene):
            # Flatten scene to single mesh
            mesh = mesh.dump(concatenate=True)

        return mesh

    def _get_bounding_box(self, solid: cq.Workplane) -> BoundingBox:
        """Extract bounding box from CadQuery solid."""
        bb = solid.val().BoundingBox()
        return BoundingBox(
            x_min=bb.xmin, y_min=bb.ymin, z_min=bb.zmin,
            x_max=bb.xmax, y_max=bb.ymax, z_max=bb.zmax,
        )
