"""
NURBS Hexagram Frame — Triple Helix Upgrade Prototype
======================================================
Replaces the straight-arm hexagram monolith with flowing NURBS surfaces.

Key improvements over V5.5 monolith:
  - Organic, curved arms instead of prismatic box sections
  - Smooth flowing transitions at junction nodes
  - Sculptural tapered tips with twist
  - Still maintains 120-degree symmetry and functional mounting geometry

Dimensions (from Triple Helix V5.5 config):
  - Inner hex ring: ~75mm flat-to-flat (HEX_R = 43mm)
  - Frame ring radius: 45-50mm
  - Arm tip radius: ~175mm (scaled for bed)
  - Overall: fits 349mm print bed
  - Frame height: 48mm (3-tier stack height)
  - Arm cross-section: 10mm x 7mm (tapered at tips)

Usage:
    python prototypes/nurbs/nurbs_hexagram_frame.py

Outputs:
    prototypes/nurbs/output/hexagram_frame.step
    prototypes/nurbs/output/hexagram_frame.stl
"""

import cadquery as cq
from OCP.Geom import Geom_BSplineSurface
from OCP.gp import gp_Pnt
from OCP.TColgp import TColgp_Array2OfPnt
from OCP.TColStd import TColStd_Array1OfReal, TColStd_Array1OfInteger
from OCP.BRepBuilderAPI import BRepBuilderAPI_MakeFace, BRepBuilderAPI_Sewing
from OCP.BRepOffset import BRepOffset_MakeSimpleOffset
import math
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ===========================================================================
# Parameters (from Triple Helix V5.5)
# ===========================================================================
HEX_R = 43.0              # Inner hex radius (center to vertex)
FRAME_RING_R_IN = 45.0    # Inner ring radius
FRAME_RING_R_OUT = 50.0   # Outer ring radius
FRAME_RING_H = 6.0        # Ring thickness (Z)
FRAME_RING_W = 5.0        # Ring wall width (radial)

ARM_W = 10.0              # Arm width at root
ARM_H = 7.0               # Arm height
ARM_TIP_W = 6.0           # Arm width at tip (tapered)
ARM_TIP_H = 5.0           # Arm height at tip
ARM_LENGTH = 110.0        # Arm length from ring edge to tip
ARM_TAPER = 0.6           # Taper ratio

STAR_TIP_R = 160.0        # Distance from center to arm tip
N_ARMS = 6                # 6 arms = 3 corridor pairs
ARM_ANGLES_DEG = [0, 60, 120, 180, 240, 300]  # Hexagram vertices

# Corridor pairs: arms 0&180, 60&240, 120&300
CORRIDOR_PAIRS = [(0, 180), (60, 240), (120, 300)]

SHELL_THICKNESS = 2.0     # Wall thickness for NURBS shells
TOTAL_HEIGHT = 48.0       # Matrix stack height (3 tiers x 16mm)

# Bearing pocket for MR84ZZ (4x8x3mm)
BEARING_OD = 8.0
BEARING_BORE = 4.0
BEARING_WIDTH = 3.0

# ===========================================================================
# NURBS surface builder (from demo)
# ===========================================================================
def make_nurbs_surface(control_points, degree_u=3, degree_v=3):
    """Build BSpline surface from 2D grid of (x,y,z) control points."""
    n_u = len(control_points)
    n_v = len(control_points[0])

    poles = TColgp_Array2OfPnt(1, n_u, 1, n_v)
    for i, row in enumerate(control_points):
        for j, (x, y, z) in enumerate(row):
            poles.SetValue(i + 1, j + 1, gp_Pnt(x, y, z))

    def make_knots(n_pts, degree):
        n_knots = n_pts - degree + 1
        knots = TColStd_Array1OfReal(1, n_knots)
        mults = TColStd_Array1OfInteger(1, n_knots)
        for k in range(n_knots):
            knots.SetValue(k + 1, float(k) / (n_knots - 1))
            if k == 0 or k == n_knots - 1:
                mults.SetValue(k + 1, degree + 1)
            else:
                mults.SetValue(k + 1, 1)
        return knots, mults

    knots_u, mults_u = make_knots(n_u, degree_u)
    knots_v, mults_v = make_knots(n_v, degree_v)

    surface = Geom_BSplineSurface(
        poles, knots_u, knots_v, mults_u, mults_v, degree_u, degree_v,
    )

    face = BRepBuilderAPI_MakeFace(surface, 1e-3).Face()
    return face


def thicken_face(face, thickness):
    """Thicken a NURBS face into a shell by offsetting and sewing."""
    simple = BRepOffset_MakeSimpleOffset(face, thickness)
    simple.Perform()
    if simple.IsDone():
        offset_face = simple.GetResultShape()
        sew = BRepBuilderAPI_Sewing(1e-3)
        sew.Add(face)
        sew.Add(offset_face)
        sew.Perform()
        return cq.Shape(sew.SewedShape())
    return cq.Face(face)


# ===========================================================================
# Build a single flowing arm as a NURBS surface
# ===========================================================================
def build_nurbs_arm(angle_deg, arm_length=ARM_LENGTH, root_w=ARM_W, root_h=ARM_H,
                    tip_w=ARM_TIP_W, tip_h=ARM_TIP_H, start_r=FRAME_RING_R_OUT):
    """
    Create a single flowing NURBS arm surface.

    The arm starts at the ring edge and flows outward with:
    - Smooth taper from root to tip
    - Gentle S-curve lift (organic feel)
    - Twist at the tip for visual interest
    """
    angle_rad = math.radians(angle_deg)
    cos_a = math.cos(angle_rad)
    sin_a = math.sin(angle_rad)

    # Perpendicular direction for width
    perp_cos = math.cos(angle_rad + math.pi / 2)
    perp_sin = math.sin(angle_rad + math.pi / 2)

    n_u = 7  # Along arm length (more points = smoother curve)
    n_v = 5  # Across arm width

    control_points = []
    for i in range(n_u):
        t = i / (n_u - 1)  # 0 to 1 along arm

        # Radial position (smooth acceleration from ring)
        r = start_r + arm_length * t

        # Width interpolation (taper)
        w = root_w * (1.0 - t) + tip_w * t

        # Height with organic S-curve lift
        base_z = 0.0
        # Gentle rise in middle, dip at tip
        lift = 8.0 * math.sin(t * math.pi) * (1.0 - 0.3 * t)

        # Slight twist toward tip (radians)
        twist = 0.15 * t * math.pi  # ~27 degrees at tip

        row = []
        for j in range(n_v):
            s = (j / (n_v - 1) - 0.5)  # -0.5 to 0.5 across width

            # Local coordinates
            local_w = s * w
            # Cross-section shape: slight arch
            local_h = root_h * (1.0 - t * 0.3) * (1.0 - 4.0 * s * s) + lift

            # Apply twist
            tw_w = local_w * math.cos(twist) - local_h * 0.1 * math.sin(twist)
            tw_h = local_w * 0.1 * math.sin(twist) + local_h * math.cos(twist)

            # Transform to global coordinates
            x = r * cos_a + tw_w * perp_cos
            y = r * sin_a + tw_w * perp_sin
            z = tw_h

            row.append((x, y, z))
        control_points.append(row)

    face = make_nurbs_surface(control_points)
    shell = thicken_face(face, SHELL_THICKNESS)
    return shell


# ===========================================================================
# Build the central hex ring as a CadQuery solid
# ===========================================================================
def build_hex_ring(z_offset=0.0, with_ledge=False):
    """
    Build a hexagonal frame ring.
    Upper ring: open bore (no ledge).
    Lower ring: inward ledge to catch matrix.
    """
    # Outer hex
    ring = (
        cq.Workplane("XY")
        .workplane(offset=z_offset)
        .polygon(6, FRAME_RING_R_OUT * 2)
        .extrude(FRAME_RING_H)
    )
    # Inner cutout
    cutout = (
        cq.Workplane("XY")
        .workplane(offset=z_offset - 0.1)
        .polygon(6, FRAME_RING_R_IN * 2)
        .extrude(FRAME_RING_H + 0.2)
    )
    ring = ring.cut(cutout)

    if with_ledge:
        # Inward ledge (catches matrix from above)
        ledge_r_in = 42.0
        ledge_thick = 2.0
        ledge = (
            cq.Workplane("XY")
            .workplane(offset=z_offset + FRAME_RING_H - ledge_thick)
            .polygon(6, FRAME_RING_R_IN * 2)
            .extrude(ledge_thick)
        )
        ledge_cut = (
            cq.Workplane("XY")
            .workplane(offset=z_offset + FRAME_RING_H - ledge_thick - 0.1)
            .polygon(6, ledge_r_in * 2)
            .extrude(ledge_thick + 0.2)
        )
        ledge = ledge.cut(ledge_cut)
        ring = ring.union(ledge)

    return ring


# ===========================================================================
# Build carrier plate at arm tip (bearing mount)
# ===========================================================================
def build_carrier_plate(angle_deg, r=STAR_TIP_R * 0.7):
    """Small carrier plate at arm tip with bearing bore."""
    angle_rad = math.radians(angle_deg)
    cx = r * math.cos(angle_rad)
    cy = r * math.sin(angle_rad)

    plate = (
        cq.Workplane("XY")
        .transformed(offset=(cx, cy, 0))
        .box(20, 14, 10)
    )

    # Bearing bore (MR84ZZ: 8mm OD)
    bore = (
        cq.Workplane("XY")
        .transformed(offset=(cx, cy, 0))
        .circle(BEARING_OD / 2 + 0.15)  # Press-fit clearance
        .extrude(12, both=True)
    )
    plate = plate.cut(bore)

    # Shaft through-hole
    shaft = (
        cq.Workplane("XY")
        .transformed(offset=(cx, cy, 0))
        .circle(BEARING_BORE / 2 + 0.1)
        .extrude(20, both=True)
    )
    plate = plate.cut(shaft)

    return plate


# ===========================================================================
# Build dampener bar connecting corridor pair
# ===========================================================================
def build_dampener_bar(angle_deg, r=STAR_TIP_R * 0.5, span=35.0):
    """Dampener bar between a corridor pair of arms."""
    angle_rad = math.radians(angle_deg)
    cx = r * math.cos(angle_rad)
    cy = r * math.sin(angle_rad)

    perp_cos = math.cos(angle_rad + math.pi / 2)
    perp_sin = math.sin(angle_rad + math.pi / 2)

    # Bar spans perpendicular to arm direction
    bar = (
        cq.Workplane("XY")
        .transformed(offset=(cx, cy, 3.0))
        .transformed(rotate=(0, 0, math.degrees(angle_rad)))
        .box(7, span, 7)
    )

    return bar


# ===========================================================================
# Assemble the complete frame
# ===========================================================================
def build_frame():
    print("Building NURBS hexagram frame...")

    # 1. Upper ring (open bore, at top of matrix stack)
    upper_z = TOTAL_HEIGHT / 2 - FRAME_RING_H
    upper_ring = build_hex_ring(z_offset=upper_z, with_ledge=False)
    print("  Upper ring done")

    # 2. Lower ring (with ledge, at bottom of matrix stack)
    lower_z = -TOTAL_HEIGHT / 2
    lower_ring = build_hex_ring(z_offset=lower_z, with_ledge=True)
    print("  Lower ring done")

    # 3. NURBS arms (6 flowing arms)
    arms = []
    for angle in ARM_ANGLES_DEG:
        arm = build_nurbs_arm(angle)
        arms.append(arm)
        print(f"  Arm at {angle}° done")

    # 4. Carrier plates at helix positions (every other arm pair)
    # Helices at 180°, 300°, 60° (opposite to stubs at 0°, 120°, 240°)
    helix_angles = [180, 300, 60]
    carriers = []
    for angle in helix_angles:
        carrier = build_carrier_plate(angle)
        carriers.append(carrier)
        print(f"  Carrier plate at {angle}° done")

    # 5. Dampener bars between corridor pairs
    dampeners = []
    for a1, a2 in CORRIDOR_PAIRS:
        mid_angle = (a1 + a2) / 2 if a1 < a2 else (a1 + a2 + 360) / 2
        # Use the angle of the first arm in the pair
        damp = build_dampener_bar(a1)
        dampeners.append(damp)
        print(f"  Dampener at {a1}° done")

    # 6. Vertical posts connecting rings (at stub positions: 0°, 120°, 240°)
    post_angles = [0, 120, 240]
    posts = []
    for angle in post_angles:
        angle_rad = math.radians(angle)
        px = (FRAME_RING_R_IN + FRAME_RING_W / 2) * math.cos(angle_rad)
        py = (FRAME_RING_R_IN + FRAME_RING_W / 2) * math.sin(angle_rad)
        post = (
            cq.Workplane("XY")
            .transformed(offset=(px, py, lower_z))
            .circle(3.0)  # 6mm dia posts
            .extrude(TOTAL_HEIGHT + FRAME_RING_H)
        )
        posts.append(post)
        print(f"  Post at {angle}° done")

    return upper_ring, lower_ring, arms, carriers, dampeners, posts


# ===========================================================================
# Export
# ===========================================================================
def export_shape(shape, name):
    step_path = os.path.join(OUTPUT_DIR, f"{name}.step")
    stl_path = os.path.join(OUTPUT_DIR, f"{name}.stl")
    cq.exporters.export(shape, step_path)
    cq.exporters.export(shape, stl_path, exportType="STL", tolerance=0.1)
    print(f"  -> {step_path}")
    print(f"  -> {stl_path}")


if __name__ == "__main__":
    print("=" * 60)
    print("NURBS Hexagram Frame — Triple Helix Upgrade")
    print("=" * 60)

    upper_ring, lower_ring, arms, carriers, dampeners, posts = build_frame()

    # Assemble into one compound for visualization
    assembly = cq.Assembly()
    assembly.add(upper_ring, name="upper_ring", color=cq.Color(0.3, 0.3, 0.8, 1.0))
    assembly.add(lower_ring, name="lower_ring", color=cq.Color(0.3, 0.3, 0.8, 1.0))

    for i, arm in enumerate(arms):
        wp = cq.Workplane("XY").newObject([arm])
        assembly.add(wp, name=f"arm_{ARM_ANGLES_DEG[i]}", color=cq.Color(0.8, 0.5, 0.2, 0.9))

    for i, carrier in enumerate(carriers):
        assembly.add(carrier, name=f"carrier_{i}", color=cq.Color(0.6, 0.6, 0.6, 1.0))

    for i, damp in enumerate(dampeners):
        assembly.add(damp, name=f"dampener_{i}", color=cq.Color(0.5, 0.7, 0.5, 1.0))

    for i, post in enumerate(posts):
        assembly.add(post, name=f"post_{i}", color=cq.Color(0.4, 0.4, 0.4, 1.0))

    # Export assembly
    step_path = os.path.join(OUTPUT_DIR, "hexagram_frame_assembly.step")
    assembly.save(step_path)
    print(f"\nAssembly -> {step_path}")

    # Also export individual rings for inspection
    export_shape(upper_ring, "upper_ring")
    export_shape(lower_ring, "lower_ring")

    print("\n" + "=" * 60)
    print(f"All outputs in: {OUTPUT_DIR}")
    print("=" * 60)
