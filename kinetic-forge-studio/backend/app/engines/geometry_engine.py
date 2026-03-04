"""
Geometry engine for parametric shape generation and export.

Uses CadQuery for precise B-rep geometry and trimesh for glTF export.
Supports: box, cylinder, sphere, cone, torus, involute spur gear, rack (linear gear).

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


# ---------------------------------------------------------------------------
# Involute gear math
# ---------------------------------------------------------------------------

def _involute_point(base_radius: float, t: float) -> tuple[float, float]:
    """
    Point on an involute curve at parameter t (radians).

    The involute is the curve traced by the end of a taut string
    unwinding from a circle of radius base_radius.
    """
    x = base_radius * (math.cos(t) + t * math.sin(t))
    y = base_radius * (math.sin(t) - t * math.cos(t))
    return (x, y)


def _involute_intersect_radius(base_radius: float, target_radius: float) -> float:
    """
    Find the involute parameter t where the curve reaches target_radius.

    At parameter t, the distance from origin is:
      r(t) = base_radius * sqrt(1 + t^2)
    So t = sqrt((target_radius/base_radius)^2 - 1)
    """
    ratio = target_radius / base_radius
    if ratio <= 1.0:
        return 0.0
    return math.sqrt(ratio * ratio - 1.0)


def _involute_tooth_profile(
    module: float,
    teeth: int,
    pressure_angle_deg: float = 20.0,
    num_involute_points: int = 12,
) -> list[tuple[float, float]]:
    """
    Generate a complete 2D involute spur gear profile (all teeth).

    Returns a closed polygon of (x, y) points. Each tooth follows
    a single continuous path: root_arc -> drive_flank -> tip_arc -> coast_flank.
    No duplicate or near-duplicate points — produces a clean watertight extrusion.
    """
    pressure_angle = math.radians(pressure_angle_deg)

    pitch_radius = module * teeth / 2.0
    base_radius = pitch_radius * math.cos(pressure_angle)
    addendum = module
    dedendum = 1.25 * module
    outer_radius = pitch_radius + addendum
    root_radius = max(base_radius * 0.95, pitch_radius - dedendum)

    angular_pitch = 2.0 * math.pi / teeth
    tooth_thickness_angle = angular_pitch / 2.0

    t_outer = _involute_intersect_radius(base_radius, outer_radius)
    t_pitch = _involute_intersect_radius(base_radius, pitch_radius)
    inv_pitch = t_pitch - math.atan(t_pitch) if t_pitch > 0 else 0.0
    half_tooth_angle = tooth_thickness_angle / 2.0 + inv_pitch

    def _rotate(x: float, y: float, angle: float) -> tuple[float, float]:
        c, s = math.cos(angle), math.sin(angle)
        return (x * c - y * s, x * s + y * c)

    def _drive_flank_point(t: float, center_angle: float) -> tuple[float, float]:
        """Point on the drive (left) involute flank."""
        px, py = _involute_point(base_radius, t)
        inv_a = t - math.atan(t) if t > 0 else 0.0
        return _rotate(px, py, center_angle + half_tooth_angle - inv_a)

    def _coast_flank_point(t: float, center_angle: float) -> tuple[float, float]:
        """Point on the coast (right) involute flank (mirror of drive)."""
        px, py = _involute_point(base_radius, t)
        inv_a = t - math.atan(t) if t > 0 else 0.0
        # Mirror by negating py before rotation
        return _rotate(px, -py, center_angle - half_tooth_angle + inv_a)

    points: list[tuple[float, float]] = []

    for i in range(teeth):
        center = i * angular_pitch

        # 1. Root arc: from previous tooth's coast-root to this tooth's drive-root
        #    Use a single point at the midpoint of the root gap
        gap_center = center - angular_pitch / 2.0
        points.append((root_radius * math.cos(gap_center),
                        root_radius * math.sin(gap_center)))

        # 2. Radial line from root up to base circle (if root < base)
        drive_start_angle = center + half_tooth_angle
        if root_radius < base_radius:
            points.append((root_radius * math.cos(drive_start_angle),
                            root_radius * math.sin(drive_start_angle)))

        # 3. Drive involute flank (root/base -> tip)
        t_start = 0.0  # always start from base circle
        for j in range(num_involute_points + 1):
            t = t_start + (t_outer - t_start) * j / num_involute_points
            points.append(_drive_flank_point(t, center))

        # 4. Tip arc midpoint (smooth transition between flanks)
        drive_tip = points[-1]
        coast_tip = _coast_flank_point(t_outer, center)
        tip_angle_d = math.atan2(drive_tip[1], drive_tip[0])
        tip_angle_c = math.atan2(coast_tip[1], coast_tip[0])
        tip_mid = (tip_angle_d + tip_angle_c) / 2.0
        points.append((outer_radius * math.cos(tip_mid),
                        outer_radius * math.sin(tip_mid)))

        # 5. Coast involute flank (tip -> root/base), reversed direction
        for j in range(num_involute_points, -1, -1):
            t = t_start + (t_outer - t_start) * j / num_involute_points
            points.append(_coast_flank_point(t, center))

        # 6. Radial line from base circle down to root (if root < base)
        coast_root_angle = center - half_tooth_angle
        if root_radius < base_radius:
            points.append((root_radius * math.cos(coast_root_angle),
                            root_radius * math.sin(coast_root_angle)))

    # Close by appending the first point
    if points:
        points.append(points[0])

    return points


def _rack_tooth_profile(
    module: float,
    num_teeth: int,
    pressure_angle_deg: float = 20.0,
    body_height: float = 10.0,
) -> list[tuple[float, float]]:
    """
    Generate a 2D rack (linear gear) profile.

    A rack is a gear with infinite radius — the involute becomes a straight
    line. Teeth are trapezoidal, spaced at circular_pitch = pi * module.

    The rack extends along the X axis, centered at X=0.
    Teeth point upward (+Y). The body extends downward.
    Returns a closed polygon suitable for extrusion.
    """
    pressure_angle = math.radians(pressure_angle_deg)
    circular_pitch = math.pi * module
    addendum = module
    dedendum = 1.25 * module
    total_length = num_teeth * circular_pitch

    # Tooth trapezoidal geometry
    tooth_half_pitch = circular_pitch / 4.0
    tip_half_width = tooth_half_pitch - addendum * math.tan(pressure_angle)
    root_half_width = tooth_half_pitch + dedendum * math.tan(pressure_angle)

    tip_y = addendum
    root_y = -dedendum
    body_bottom_y = -body_height

    points = []

    # Start at bottom-left corner
    start_x = -total_length / 2.0
    points.append((start_x, body_bottom_y))
    points.append((start_x, root_y))

    # Generate each tooth
    for i in range(num_teeth):
        tooth_center_x = start_x + (i + 0.5) * circular_pitch

        # Left root to left tip (rising flank)
        points.append((tooth_center_x - root_half_width, root_y))
        points.append((tooth_center_x - tip_half_width, tip_y))

        # Tip flat
        points.append((tooth_center_x + tip_half_width, tip_y))

        # Right tip to right root (falling flank)
        points.append((tooth_center_x + root_half_width, root_y))

    # Close along bottom
    end_x = start_x + total_length
    points.append((end_x, root_y))
    points.append((end_x, body_bottom_y))
    points.append((start_x, body_bottom_y))

    return points


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
        Generate an involute spur gear with proper tooth profiles.

        Strategy: build a root-diameter cylinder, then union individual
        tooth solids. This guarantees a watertight manifold result
        because each boolean op preserves manifold-ness.
        """
        pressure_angle = math.radians(pressure_angle_deg)
        pitch_radius = module * teeth / 2.0
        base_radius = pitch_radius * math.cos(pressure_angle)
        outer_radius = pitch_radius + module
        root_radius = pitch_radius - 1.25 * module
        angular_pitch = 2.0 * math.pi / teeth

        # Tooth thickness at pitch circle = half the circular pitch
        tooth_thick_angle = angular_pitch / 2.0
        t_pitch = _involute_intersect_radius(base_radius, pitch_radius)
        inv_pitch = t_pitch - math.atan(t_pitch) if t_pitch > 0 else 0.0
        half_tooth = tooth_thick_angle / 2.0 + inv_pitch

        t_outer = _involute_intersect_radius(base_radius, outer_radius)

        # Start with root cylinder
        solid = cq.Workplane("XY").cylinder(height, root_radius, centered=(True, True, False))

        # Build a single tooth profile (2D cross-section)
        n_pts = 8  # involute sample points per flank

        def _tooth_profile(center_angle: float) -> list[tuple[float, float]]:
            """Return closed polygon for one tooth above root circle."""
            pts = []
            # Drive flank: base circle -> tip (left side of tooth)
            for j in range(n_pts + 1):
                t = (t_outer) * j / n_pts
                px, py = _involute_point(base_radius, t)
                inv_a = t - math.atan(t) if t > 0 else 0.0
                rot = center_angle + half_tooth - inv_a
                c, s = math.cos(rot), math.sin(rot)
                pts.append((px * c - py * s, px * s + py * c))

            # Tip arc midpoint
            drive_tip = pts[-1]
            # Coast flank tip point
            t = t_outer
            px, py = _involute_point(base_radius, t)
            inv_a = t - math.atan(t) if t > 0 else 0.0
            rot = center_angle - half_tooth + inv_a
            c, s = math.cos(rot), math.sin(rot)
            coast_tip = (px * c + py * s, px * s - py * c)

            mid_a = (math.atan2(drive_tip[1], drive_tip[0]) +
                      math.atan2(coast_tip[1], coast_tip[0])) / 2.0
            pts.append((outer_radius * math.cos(mid_a),
                         outer_radius * math.sin(mid_a)))

            # Coast flank: tip -> base circle (right side of tooth)
            for j in range(n_pts, -1, -1):
                t = (t_outer) * j / n_pts
                px, py = _involute_point(base_radius, t)
                inv_a = t - math.atan(t) if t > 0 else 0.0
                rot = center_angle - half_tooth + inv_a
                c, s = math.cos(rot), math.sin(rot)
                pts.append((px * c + py * s, px * s - py * c))

            # Close back through the root/base intersection
            # Connect coast base to drive base through root arc
            coast_base = pts[-1]
            drive_base = pts[0]
            cb_angle = math.atan2(coast_base[1], coast_base[0])
            db_angle = math.atan2(drive_base[1], drive_base[0])
            # Add root arc point between coast and drive
            mid_root = (cb_angle + db_angle) / 2.0
            # Use root_radius for the arc, ensuring we go inside the base
            arc_r = min(root_radius, base_radius) - 0.01
            pts.append((arc_r * math.cos(cb_angle), arc_r * math.sin(cb_angle)))
            pts.append((arc_r * math.cos(mid_root), arc_r * math.sin(mid_root)))
            pts.append((arc_r * math.cos(db_angle), arc_r * math.sin(db_angle)))

            pts.append(pts[0])
            return pts

        # Union each tooth onto the root cylinder
        for i in range(teeth):
            center_angle = i * angular_pitch
            profile = _tooth_profile(center_angle)
            tooth_solid = (
                cq.Workplane("XY")
                .polyline(profile)
                .close()
                .extrude(height)
            )
            solid = solid.union(tooth_solid)

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

    def generate_rack(
        self,
        module: float = 1.5,
        num_teeth: int = 10,
        height: float = 8.0,
        body_height: float = 10.0,
        pressure_angle_deg: float = 20.0,
        name: str = "rack",
    ) -> GeometryResult:
        """
        Generate a rack (linear gear) with proper trapezoidal tooth profile.

        The rack meshes with any spur gear of the same module and pressure angle.
        Teeth extend along the X axis; the rack body extends below.

        Args:
            module: Gear module (must match meshing pinion).
            num_teeth: Number of teeth.
            height: Extrusion depth (Z direction).
            body_height: Total height of the rack body.
            pressure_angle_deg: Pressure angle in degrees.
            name: Component name.
        """
        profile = _rack_tooth_profile(
            module=module,
            num_teeth=num_teeth,
            pressure_angle_deg=pressure_angle_deg,
            body_height=body_height,
        )

        solid = (
            cq.Workplane("XY")
            .polyline(profile)
            .close()
            .extrude(height)
        )

        circular_pitch = math.pi * module
        total_length = num_teeth * circular_pitch
        addendum = module

        bb = self._get_bounding_box(solid)
        return GeometryResult(
            name=name,
            shape_type="rack",
            parameters={
                "module": module,
                "num_teeth": num_teeth,
                "height": height,
                "body_height": body_height,
                "pressure_angle_deg": pressure_angle_deg,
                "total_length": total_length,
                "addendum": addendum,
            },
            cq_solid=solid,
            bounding_box=bb,
        )

    def generate_sphere(
        self,
        radius: float = 5.0,
        name: str = "sphere",
    ) -> GeometryResult:
        """Generate a parametric sphere."""
        solid = cq.Workplane("XY").sphere(radius)
        bb = self._get_bounding_box(solid)
        return GeometryResult(
            name=name,
            shape_type="sphere",
            parameters={"radius": radius},
            cq_solid=solid,
            bounding_box=bb,
        )

    def generate_cone(
        self,
        bottom_radius: float = 5.0,
        top_radius: float = 0.0,
        height: float = 10.0,
        name: str = "cone",
    ) -> GeometryResult:
        """
        Generate a parametric cone (or truncated cone / frustum).

        Args:
            bottom_radius: Radius at the base (Z=0).
            top_radius: Radius at the top (Z=height). 0 for a pointed cone.
            height: Height of the cone along Z.
            name: Component name.
        """
        solid = cq.Workplane("XY").add(
            cq.Solid.makeCone(bottom_radius, top_radius, height)
        )
        bb = self._get_bounding_box(solid)
        return GeometryResult(
            name=name,
            shape_type="cone",
            parameters={
                "bottom_radius": bottom_radius,
                "top_radius": top_radius,
                "height": height,
            },
            cq_solid=solid,
            bounding_box=bb,
        )

    def generate_torus(
        self,
        major_radius: float = 10.0,
        minor_radius: float = 2.0,
        name: str = "torus",
    ) -> GeometryResult:
        """
        Generate a parametric torus.

        Args:
            major_radius: Distance from the center of the tube to the center of the torus.
            minor_radius: Radius of the tube.
            name: Component name.
        """
        solid = cq.Workplane("XY").add(
            cq.Solid.makeTorus(major_radius, minor_radius)
        )
        bb = self._get_bounding_box(solid)
        return GeometryResult(
            name=name,
            shape_type="torus",
            parameters={
                "major_radius": major_radius,
                "minor_radius": minor_radius,
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

    def generate_assembly_glb(
        self,
        results: list[GeometryResult],
        positions: list[dict] | None = None,
    ) -> bytes:
        """
        Combine multiple geometry results into a single GLB scene.

        Args:
            results: List of generated geometry shapes.
            positions: Optional list of {"x", "y", "z"} dicts, one per result.
                       Applies a translation transform so parts are spatially separated.
        """
        scene = trimesh.Scene()
        for i, r in enumerate(results):
            mesh = self._to_trimesh(r)
            transform = None
            if positions and i < len(positions):
                pos = positions[i]
                x = float(pos.get("x", 0))
                y = float(pos.get("y", 0))
                z = float(pos.get("z", 0))
                if x != 0 or y != 0 or z != 0:
                    transform = trimesh.transformations.translation_matrix([x, y, z])
            scene.add_geometry(mesh, node_name=r.name, transform=transform)
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
