"""
NURBS Surface Component Prototype
==================================
Demonstrates creating NURBS (Non-Uniform Rational B-Spline) surfaces
using CadQuery's underlying OpenCascade kernel.

This shows how a 4th geometry kernel ("nurbs") could work in KFS
for organic/decorative shell components in kinetic sculptures.

Usage:
    python prototypes/nurbs/nurbs_surface_demo.py

Outputs:
    prototypes/nurbs/output/flowing_shell.step
    prototypes/nurbs/output/flowing_shell.stl
    prototypes/nurbs/output/saddle_surface.step
    prototypes/nurbs/output/wave_panel.step
"""

import cadquery as cq
from OCP.Geom import Geom_BSplineSurface
from OCP.gp import gp_Pnt
from OCP.TColgp import TColgp_Array2OfPnt
from OCP.TColStd import TColStd_Array1OfReal, TColStd_Array1OfInteger
from OCP.BRepBuilderAPI import BRepBuilderAPI_MakeFace
from OCP.ShapeAnalysis import ShapeAnalysis_Surface
from OCP.GeomAbs import GeomAbs_C2
import math
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)


# ---------------------------------------------------------------------------
# Helper: build a BSpline surface from a 2D grid of (x, y, z) control points
# ---------------------------------------------------------------------------
def make_nurbs_surface(control_points, degree_u=3, degree_v=3):
    """
    Build an OCC BSpline surface from a 2D grid of control points.

    Args:
        control_points: list of lists of (x, y, z) tuples
                        Outer list = rows (u direction)
                        Inner list = cols (v direction)
        degree_u: polynomial degree in U direction
        degree_v: polynomial degree in V direction

    Returns:
        OCC TopoDS_Face
    """
    n_u = len(control_points)
    n_v = len(control_points[0])

    # Pack control points into OCC array (1-indexed)
    poles = TColgp_Array2OfPnt(1, n_u, 1, n_v)
    for i, row in enumerate(control_points):
        for j, (x, y, z) in enumerate(row):
            poles.SetValue(i + 1, j + 1, gp_Pnt(x, y, z))

    # Uniform knot vectors (clamped)
    def make_knots(n_pts, degree):
        n_knots = n_pts - degree + 1
        knots = TColStd_Array1OfReal(1, n_knots)
        mults = TColStd_Array1OfInteger(1, n_knots)
        for k in range(n_knots):
            knots.SetValue(k + 1, float(k) / (n_knots - 1))
            if k == 0 or k == n_knots - 1:
                mults.SetValue(k + 1, degree + 1)  # clamped ends
            else:
                mults.SetValue(k + 1, 1)
        return knots, mults

    knots_u, mults_u = make_knots(n_u, degree_u)
    knots_v, mults_v = make_knots(n_v, degree_v)

    # Build the BSpline surface
    surface = Geom_BSplineSurface(
        poles,
        knots_u, knots_v,
        mults_u, mults_v,
        degree_u, degree_v,
    )

    # Convert to a face (B-Rep)
    tolerance = 1e-3
    face = BRepBuilderAPI_MakeFace(surface, tolerance).Face()
    return face


# ---------------------------------------------------------------------------
# Helper: wrap an OCC face into CadQuery for export
# ---------------------------------------------------------------------------
def face_to_cq(face, thickness=None):
    """Wrap OCC face into CadQuery Workplane. Optionally thicken into a solid."""
    wp = cq.Workplane("XY").newObject([cq.Face(face)])
    if thickness:
        # Thicken surface into a solid shell
        from OCP.BRepOffset import BRepOffset_MakeOffset, BRepOffset_Skin
        from OCP.BRepOffsetAPI import BRepOffsetAPI_MakeThickSolid
        from OCP.BRepOffset import BRepOffset_MakeSimpleOffset

        simple = BRepOffset_MakeSimpleOffset(face, thickness)
        simple.Perform()
        if simple.IsDone():
            offset_face = simple.GetResultShape()
            # Sew original + offset into a solid
            from OCP.BRepBuilderAPI import BRepBuilderAPI_Sewing
            sew = BRepBuilderAPI_Sewing(1e-3)
            sew.Add(face)
            sew.Add(offset_face)
            sew.Perform()
            wp = cq.Workplane("XY").newObject([cq.Shape(sew.SewedShape())])
    return wp


def export_shape(shape, name):
    """Export a CadQuery shape to STEP and STL."""
    step_path = os.path.join(OUTPUT_DIR, f"{name}.step")
    stl_path = os.path.join(OUTPUT_DIR, f"{name}.stl")
    cq.exporters.export(shape, step_path)
    cq.exporters.export(shape, stl_path, exportType="STL", tolerance=0.1)
    print(f"  Exported: {step_path}")
    print(f"  Exported: {stl_path}")


# ===========================================================================
# DEMO 1: Flowing Shell — organic enclosure for kinetic sculpture
# ===========================================================================
def demo_flowing_shell():
    """
    A flowing, doubly-curved shell surface — the kind of organic form
    you'd use as a decorative housing around a gear mechanism.

    Control point grid: 6x6, with Z heights creating a smooth dome
    with an asymmetric flowing edge.
    """
    print("\n[Demo 1] Flowing Shell")

    size = 80.0  # mm overall size
    rows, cols = 6, 6

    control_points = []
    for i in range(rows):
        row = []
        u = i / (rows - 1)  # 0..1
        for j in range(cols):
            v = j / (cols - 1)  # 0..1

            x = (u - 0.5) * size
            y = (v - 0.5) * size

            # Base dome shape
            r = math.sqrt((u - 0.5) ** 2 + (v - 0.5) ** 2)
            z = max(0, 25.0 * (1.0 - 2.0 * r))

            # Add flowing asymmetry — one corner lifts higher
            z += 10.0 * u * math.sin(v * math.pi)

            # Edge ripple for organic feel
            z += 3.0 * math.sin(u * math.pi * 2) * math.sin(v * math.pi * 2)

            row.append((x, y, z))
        control_points.append(row)

    face = make_nurbs_surface(control_points)
    shape = face_to_cq(face, thickness=2.0)  # 2mm thick shell
    export_shape(shape, "flowing_shell")
    return shape


# ===========================================================================
# DEMO 2: Saddle Surface — hyperbolic paraboloid (classic math surface)
# ===========================================================================
def demo_saddle():
    """
    Hyperbolic paraboloid (saddle shape). Demonstrates negative curvature
    NURBS — useful for tensioned-fabric-style decorative panels.
    """
    print("\n[Demo 2] Saddle Surface")

    size = 60.0
    rows, cols = 5, 5
    control_points = []

    for i in range(rows):
        row = []
        u = (i / (rows - 1) - 0.5) * 2  # -1..1
        for j in range(cols):
            v = (j / (cols - 1) - 0.5) * 2  # -1..1
            x = u * size / 2
            y = v * size / 2
            z = 15.0 * (u ** 2 - v ** 2)  # classic saddle z = x²-y²
            row.append((x, y, z))
        control_points.append(row)

    face = make_nurbs_surface(control_points)
    shape = face_to_cq(face)
    export_shape(shape, "saddle_surface")
    return shape


# ===========================================================================
# DEMO 3: Wave Panel — kinetic sculpture backdrop
# ===========================================================================
def demo_wave_panel():
    """
    A sinusoidal wave surface — like a Margolin-style wave backdrop.
    Uses more control points for higher fidelity curves.
    """
    print("\n[Demo 3] Wave Panel")

    width, height = 120.0, 80.0
    rows, cols = 8, 8
    control_points = []

    for i in range(rows):
        row = []
        u = i / (rows - 1)
        for j in range(cols):
            v = j / (cols - 1)
            x = (u - 0.5) * width
            y = (v - 0.5) * height
            # Traveling wave with decay from center
            z = 12.0 * math.sin(u * math.pi * 3) * math.cos(v * math.pi * 2)
            # Taper edges down
            edge_factor = 4 * u * (1 - u) * 4 * v * (1 - v)
            z *= edge_factor
            row.append((x, y, z))
        control_points.append(row)

    face = make_nurbs_surface(control_points)
    shape = face_to_cq(face, thickness=1.5)
    export_shape(shape, "wave_panel")
    return shape


# ===========================================================================
# DEMO 4: KFS-Compatible Component — follows get_geometry_type() interface
# ===========================================================================
def get_geometry_type():
    """KFS interface: identifies this as a NURBS surface component."""
    return "nurbs_shell"


def get_component_role():
    """KFS interface: decorative/static component."""
    return "static"


def get_fixed_parts():
    """
    KFS interface: returns the NURBS shell as a fixed (non-moving) part
    with mounting holes for attaching to a kinetic sculpture frame.
    """
    # Build a flowing shell
    size = 80.0
    rows, cols = 6, 6
    control_points = []
    for i in range(rows):
        row = []
        u = i / (rows - 1)
        for j in range(cols):
            v = j / (cols - 1)
            x = (u - 0.5) * size
            y = (v - 0.5) * size
            r = math.sqrt((u - 0.5) ** 2 + (v - 0.5) ** 2)
            z = max(0, 20.0 * (1.0 - 2.0 * r))
            z += 8.0 * u * math.sin(v * math.pi)
            row.append((x, y, z))
        control_points.append(row)

    face = make_nurbs_surface(control_points)
    shell = face_to_cq(face, thickness=2.0)

    # Add mounting holes at corners (KFS production requirement)
    base = cq.Workplane("XY").box(size, size, 3).translate((0, 0, -1.5))
    hole_offset = size / 2 - 8
    for dx in [-hole_offset, hole_offset]:
        for dy in [-hole_offset, hole_offset]:
            base = base.pushPoints([(dx, dy)]).hole(3.2)  # M3 clearance

    return {
        "shell_surface": shell,
        "mounting_base": base,
    }


def get_moving_parts():
    """KFS interface: no moving parts for a decorative shell."""
    return {}


# ===========================================================================
# Main
# ===========================================================================
if __name__ == "__main__":
    print("=" * 60)
    print("NURBS Surface Component Prototype")
    print("=" * 60)

    demo_flowing_shell()
    demo_saddle()
    demo_wave_panel()

    print("\n[Demo 4] KFS-Compatible Component")
    parts = get_fixed_parts()
    for name, part in parts.items():
        export_shape(part, f"kfs_{name}")

    print("\n" + "=" * 60)
    print(f"All outputs in: {OUTPUT_DIR}")
    print("=" * 60)
