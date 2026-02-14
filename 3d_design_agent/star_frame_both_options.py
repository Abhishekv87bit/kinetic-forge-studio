"""
Triple Helix Star Frame - BOTH OPTIONS
Computes and compares the two possible architectures.
"""

import math
import numpy as np

def d2r(d): return d * math.pi / 180.0
def r2d(r): return r * 180.0 / math.pi
def pt(r, deg): return np.array([r * math.cos(d2r(deg)), r * math.sin(d2r(deg))])

HEX_R = 118.0
FRAME_RING_R_IN = 120.0
FRAME_RING_R_OUT = 130.0
STUB_LENGTH_ORIG = 30.0
CORRIDOR_WIDTH = 60.0

print("=" * 70)
print("OPTION A: STANDARD HEXAGRAM (V-CORRIDOR, NOT PARALLEL)")
print("=" * 70)
print()

# Standard hexagram with inner hexagon circumradius = STUB_END_R = 160mm
r_inner_hex = FRAME_RING_R_OUT + STUB_LENGTH_ORIG  # 160mm
R_tip = r_inner_hex * math.sqrt(3)  # 277.1mm

print(f"r_inner (inner hexagon) = {r_inner_hex:.1f} mm")
print(f"R_tip (star tips)       = {R_tip:.1f} mm")
print(f"STUB_LENGTH             = {STUB_LENGTH_ORIG:.1f} mm")
print()

# At each helix position, two arms cross at 60 degrees.
# The gap opens linearly outward from the crossing point.
# gap(d) = 2 * d * tan(30) where d = distance beyond crossing along bisector.
# For gap = 60mm: d = 30 * sqrt(3) = 51.96mm
# HELIX_R = r_inner + d = 160 + 52.0 = 212.0mm

d_for_gap = CORRIDOR_WIDTH / (2 * math.tan(d2r(30)))
HELIX_R_A = r_inner_hex + d_for_gap

print(f"V-angle between arms at helix: 60 deg (half-angle 30 deg)")
print(f"Distance from crossing to 60mm gap: {d_for_gap:.2f} mm")
print(f"HELIX_R = {HELIX_R_A:.2f} mm")
print()

# The helix shaft axis is perpendicular to the corridor bisector.
# The bisector is the helix radial (e.g., 180 deg for helix at 180).
# At the helix position, the two arms are NOT parallel but diverge at 60 deg.
# The perpendicular distance from helix center to each arm = CORRIDOR_WIDTH/2 = 30mm.

# Arm details at helix 180:
# T1 side 150->270: direction 300 deg (= -60 deg)
# T2 side 90->210: direction 240 deg (= -120 deg)
# Bisector of 300 and 240 = 270 deg... no.
# The bisector angle of the V at helix 180:
# The two arms at the crossing point (R=160 on 180 radial) diverge at 60 deg.
# The bisector of the opening V points outward along the 180-deg radial.
# The arms make angles of +30 and -30 deg relative to this bisector.
# So the arm directions at the helix are:
# Arm 1: 180 + 90 + 30 = 300 deg (or equivalently -60 deg)
# Arm 2: 180 + 90 - 30 = 240 deg
# Wait, let me think more carefully.

# At the crossing at (-160, 0):
# T1 arm goes from tip at 150 deg to tip at 270 deg.
# T1 tip 150 = R_tip*(cos150, sin150) = 277.1*(-0.866, 0.5) = (-240, 138.6)
# T1 tip 270 = R_tip*(cos270, sin270) = 277.1*(0, -1) = (0, -277.1)
# Direction = (0-(-240), -277.1-138.6) / |...| = (240, -415.7) -> angle = -60 deg = 300 deg

# T2 arm goes from tip at 90 deg to tip at 210 deg.
# T2 tip 90 = (0, 277.1)
# T2 tip 210 = 277.1*(cos210, sin210) = (-240, -138.6)
# Direction = (-240-0, -138.6-277.1) = (-240, -415.7) -> angle = 240 deg

# Angle between 300 and 240 = 60 deg. Confirmed.
# The bisector of these two directions: (300+240)/2 = 270 deg.
# The arms diverge symmetrically about the 270-deg direction.
# But the helix radial at 180 is the 180-deg direction (pointing left).
# The bisector at 270 deg points DOWNWARD, not leftward!

# Hmm, this means the V doesn't open along the helix radial.
# Let me reconsider.

# The crossing point is at inner hex vertex at 180 deg: (-160, 0).
# The two arms at this crossing have directions 300 and 240 deg.
# The V formed by these arms opens toward the bisector direction 270 deg (downward).
# But we want the gap at a point along the 180-deg radial (further left).

# Moving along 180-deg direction from (-160, 0) toward (-200, 0):
# I need the perpendicular distance from (-R_h, 0) to each arm.

def line_point_dist(P, A, d_angle):
    """Signed perpendicular distance from point P to line through A at angle d_angle"""
    # Normal to line: (-sin(d_angle), cos(d_angle))
    # Distance = (P - A) . normal
    d = d2r(d_angle)
    nx = -math.sin(d)
    ny = math.cos(d)
    return (P[0]-A[0])*nx + (P[1]-A[1])*ny

# Crossing point
C = np.array([-r_inner_hex, 0.0])

# T1 arm at direction 300 deg through C
# T2 arm at direction 240 deg through C

print("Gap analysis along 180-deg radial (hexagram):")
print(f"  {'R_h':>6} | {'d_to_arm1':>10} | {'d_to_arm2':>10} | {'gap':>8}")
print(f"  {'-'*6} | {'-'*10} | {'-'*10} | {'-'*8}")

for R_h_test in range(160, 260, 5):
    P = np.array([-R_h_test, 0.0])
    d1 = line_point_dist(P, C, 300)
    d2 = line_point_dist(P, C, 240)
    gap = abs(d1) + abs(d2) if d1 * d2 < 0 else abs(abs(d1) - abs(d2))
    # Actually: gap between two lines = perpendicular distance between them
    # when measured along the perpendicular to the BISECTOR (or to each arm).
    # But since the arms aren't parallel, the "gap" depends on direction of measurement.
    # The relevant gap is the MINIMUM WIDTH that fits the helix assembly.
    # If the helix is a cylinder, we need the minimum distance between the two arms
    # at the helix position.

    # For a point P between two non-parallel lines, the minimum enclosing width
    # (in any direction) equals the distance to the nearer line, measured
    # perpendicular to that line. But for fitting a rectangle (the helix assembly),
    # we need the gap measured perpendicular to the assembly orientation.

    # The helix shaft is perpendicular to the corridor. In the standard hexagram,
    # if the corridor bisector is the helix radial (180 deg), the shaft would be
    # perpendicular to 180 deg = vertical (90 deg).
    # Gap measured vertically at (-R_h, 0):
    # y-coordinate of arm 1 at x = -R_h
    # Arm 1 (dir 300 = -60 deg) through (-160, 0):
    # parametric: (-160 + t*cos(-60), 0 + t*sin(-60)) = (-160 + t/2, -t*sqrt(3)/2)
    # At x = -R_h: -160 + t/2 = -R_h => t = 2*(160 - R_h)
    # If R_h > 160: t = 2*(160-R_h) < 0. t negative means going backward from (-160,0)
    # in the direction opposite to 300 deg, i.e., 120 deg.
    # y = -t*sqrt(3)/2 = -2*(160-R_h)*sqrt(3)/2 = (R_h-160)*sqrt(3)
    y_arm1 = (R_h_test - 160) * math.sqrt(3)

    # Arm 2 (dir 240 = -120 deg) through (-160, 0):
    # (-160 + t*cos(-120), 0 + t*sin(-120)) = (-160 - t/2, -t*sqrt(3)/2)
    # At x = -R_h: -160 - t/2 = -R_h => t = 2*(R_h - 160)
    # y = -t*sqrt(3)/2 = -(R_h-160)*sqrt(3)
    y_arm2 = -(R_h_test - 160) * math.sqrt(3)

    vertical_gap = abs(y_arm1 - y_arm2)
    print(f"  {R_h_test:6d} | {y_arm1:10.2f} | {y_arm2:10.2f} | {vertical_gap:8.2f}")

# For vertical gap = 60mm:
# 2*(R_h - 160)*sqrt(3) = 60
# R_h = 160 + 30/sqrt(3) = 160 + 17.32 = 177.32

R_h_v60 = 160 + 30 / math.sqrt(3)
print(f"\n  For VERTICAL gap = 60mm: R_h = {R_h_v60:.2f} mm")
print(f"  (This is the gap measured perpendicular to helix shaft if shaft is vertical)")
print()

# For minimum gap = 60mm (measured perpendicular to EACH arm):
# Distance from helix center to nearer arm = 30mm
# The helix center is at (-R_h, 0). The nearer arm is whichever arm is closer.
# By symmetry, both arms are equidistant from the 180-deg radial.
# Perpendicular distance from (-R_h, 0) to arm 1 (through (-160,0) at -60 deg):
# Using the formula: d = (P-A).n where n is unit normal to arm.
# Normal to direction -60 deg: (-sin(-60), cos(-60)) = (sqrt(3)/2, 1/2)
# d1 = ((-R_h+160)*sqrt(3)/2 + 0*1/2) = (160-R_h)*sqrt(3)/2 (negative for R_h>160)
# |d1| = (R_h-160)*sqrt(3)/2
# For |d1| = 30: R_h = 160 + 60/sqrt(3) = 160 + 34.64 = 194.64
R_h_perp = 160 + 60 / math.sqrt(3)
print(f"  For PERPENDICULAR-TO-ARM gap = 60mm: R_h = {R_h_perp:.2f} mm")
print(f"  (30mm perpendicular distance to each arm, measured from midpoint)")
print()

# Summary of Option A
print("OPTION A SUMMARY (Hexagram, V-corridor):")
print(f"  Inner hexagon radius: {r_inner_hex:.0f} mm (= STUB_END_R)")
print(f"  Star tip radius:      {R_tip:.1f} mm")
print(f"  STUB_LENGTH:          {STUB_LENGTH_ORIG:.0f} mm")
print(f"  V-angle at helix:     60 deg")
print(f"  HELIX_R (vertical gap = 60mm): {R_h_v60:.1f} mm")
print(f"  HELIX_R (perp gap = 60mm):     {R_h_perp:.1f} mm")
print(f"  Arms are NOT parallel (60-deg V)")
print(f"  Arm directions at each helix: differ by 60 deg")
print()

# Arm data for option A
print("  Arm directions:")
print("    Helix 180: arm1 at 300 deg, arm2 at 240 deg (V-angle 60 deg)")
print("    Helix 300: arm1 at 60 deg,  arm2 at 0 deg   (V-angle 60 deg)")
print("    Helix  60: arm1 at 180 deg, arm2 at 120 deg (V-angle 60 deg)")
print()

# Triangle data
print("  Triangle 1 (tips at [30, 150, 270] deg):")
for a in [30, 150, 270]:
    v = pt(R_tip, a)
    print(f"    Tip {a:3d} deg: ({v[0]:8.1f}, {v[1]:8.1f})")
print("  Triangle 2 (tips at [90, 210, 330] deg):")
for a in [90, 210, 330]:
    v = pt(R_tip, a)
    print(f"    Tip {a:3d} deg: ({v[0]:8.1f}, {v[1]:8.1f})")

print()
print()

# ================================================================
print("=" * 70)
print("OPTION B: TWO CONCENTRIC EQUILATERAL TRIANGLES (EXACTLY PARALLEL)")
print("=" * 70)
print()

# Two equilateral triangles, same orientation, vertices at [0, 120, 240].
# Inner circumradius R1, outer circumradius R2.
# R2 - R1 = 2 * CORRIDOR_WIDTH = 120mm.
# HELIX_R = (R1 + R2) / 4 = (R1/2 + R2/2) / 2 = average of inradii.
# Actually HELIX_R = (inradius_inner + inradius_outer) / 2 = (R1/2 + R2/2) / 2 = (R1+R2)/4

# But wait - the inradius is the perpendicular distance from center to side.
# For equilateral triangle with circumradius R: inradius = R/2.
# The midline of the corridor is at distance (R1/2 + R2/2)/2 from center.
# HELIX_R = this midline distance on the helix radial.
# Since the helix radial is perpendicular to the side, HELIX_R = midline distance.
# HELIX_R = (R1/2 + R2/2) / 2 = (R1 + R2) / 4

# Hmm that gives HELIX_R = (R1+R2)/4. With R2 = R1 + 120:
# HELIX_R = (R1 + R1 + 120) / 4 = (2*R1 + 120) / 4 = R1/2 + 30

# For HELIX_R = 200: R1/2 + 30 = 200 => R1/2 = 170 => R1 = 340, R2 = 460

# Wait, I should double-check. The inradius of equilateral triangle:
# For circumradius R: inradius = R * cos(30 deg) = R * sqrt(3)/2? NO.
# Let me derive carefully.
# Side length a of equilateral triangle with circumradius R:
# a = R * sqrt(3) (from the formula R = a/sqrt(3))
# Area = sqrt(3)/4 * a^2 = sqrt(3)/4 * 3*R^2 = 3*sqrt(3)/4 * R^2
# Perimeter = 3a = 3R*sqrt(3)
# Inradius = Area / (Perimeter/2) = (3*sqrt(3)/4 * R^2) / (3R*sqrt(3)/2) = R/2

# So inradius = R/2. Confirmed.

# Actually wait. Let me verify with a specific example.
# Equilateral triangle with vertices at distance R from center.
# Vertex at (R, 0). Side from vertex at 120 deg to vertex at 240 deg.
# V1 = R*(cos120, sin120) = (-R/2, R*sqrt(3)/2)
# V2 = R*(cos240, sin240) = (-R/2, -R*sqrt(3)/2)
# This side is a vertical line at x = -R/2.
# Distance from origin to this side = R/2.
# Confirmed: inradius = R/2.

target_helix_r = 200.0
R1 = 2 * (target_helix_r - 30)  # R1/2 = HELIX_R - 30 => R1 = 2*(HELIX_R-30)
R2 = R1 + 120
check_helix_r = (R1 + R2) / 4

print(f"Target HELIX_R = {target_helix_r} mm")
print(f"R1 = {R1:.1f} mm, R2 = {R2:.1f} mm")
print(f"Check HELIX_R = (R1+R2)/4 = {check_helix_r:.1f} mm")
print(f"Corridor width = (R2-R1)/2 = {(R2-R1)/2:.1f} mm")
print()

# Stubs connect from ring (R=130) to BOTH triangle vertices
stub_to_inner = R1 - FRAME_RING_R_OUT
stub_to_outer = R2 - FRAME_RING_R_OUT
print(f"Stub length to inner vertex: {stub_to_inner:.1f} mm")
print(f"Stub length to outer vertex: {stub_to_outer:.1f} mm")
print()

# That's 210 to 330mm stub length. Very long.
# Let's also compute for HELIX_R ~ 160mm (more compact):
print("Parametric sweep:")
print(f"  {'HELIX_R':>8} | {'R1':>8} | {'R2':>8} | {'Stub_in':>8} | {'Stub_out':>8} | {'Side_in':>8} | {'Side_out':>8}")
for hr in [130, 140, 150, 160, 170, 180, 190, 200, 212]:
    r1 = 2*(hr - 30)
    r2 = r1 + 120
    s_in = r1 - FRAME_RING_R_OUT
    s_out = r2 - FRAME_RING_R_OUT
    side_in = r1 * math.sqrt(3)
    side_out = r2 * math.sqrt(3)
    print(f"  {hr:8.0f} | {r1:8.0f} | {r2:8.0f} | {s_in:8.0f} | {s_out:8.0f} | {side_in:8.0f} | {side_out:8.0f}")

print()
print("OPTION B SUMMARY (Concentric triangles, exactly parallel):")
print(f"  Arms are EXACTLY parallel at all points")
print(f"  Corridor width = (R2 - R1) / 2 = {CORRIDOR_WIDTH} mm everywhere")
print(f"  Arm directions:")
print(f"    Helix 180: both arms at 270 deg (straight down)")
print(f"    Helix 300: both arms at  30 deg")
print(f"    Helix  60: both arms at 150 deg")
print(f"  For HELIX_R=200: R1={2*(200-30):.0f}, R2={2*(200-30)+120:.0f}, stubs {2*(200-30)-130:.0f}-{2*(200-30)+120-130:.0f}mm long")
print(f"  For HELIX_R=160: R1={2*(160-30):.0f}, R2={2*(160-30)+120:.0f}, stubs {2*(160-30)-130:.0f}-{2*(160-30)+120-130:.0f}mm long")

print()
print()
print("=" * 70)
print("RECOMMENDATION")
print("=" * 70)
print()
print("Option A (Hexagram) is compact but has 60-deg V corridors.")
print("Option B (Concentric triangles) gives exactly parallel corridors")
print("  but requires much longer stubs.")
print()
print("HYBRID APPROACH: Use the hexagram (Option A) but extend the stubs")
print("to reach HELIX_R = 195mm (perp gap ~60mm). The arms are NOT parallel")
print("but the 30-deg deviation from parallel is accommodated by making the")
print("helix mounting bracket trapezoidal (wider at the outside, narrower inside).")
print()
print("Or: Accept HELIX_R = 177mm (vertical gap = 60mm) with only 30mm stubs,")
print("and use the hexagram as-is. The V-angle of 60 deg means the arm-to-arm")
print("gap grows from 0 at R=160 to 60mm at R=177 (measured vertically).")
print()

# Final answer for the hexagram approach with detailed coordinates:
print("=" * 70)
print("FINAL: HEXAGRAM OPTION A - COMPLETE COORDINATE TABLE")
print("=" * 70)
print()

HELIX_R_FINAL = R_h_v60  # 177.3mm (for 60mm vertical gap)

# Hexagram parameters
print(f"// HEXAGRAM STAR FRAME PARAMETERS")
print(f"HEX_R = {HEX_R};")
print(f"FRAME_RING_R_IN = {FRAME_RING_R_IN};")
print(f"FRAME_RING_R_OUT = {FRAME_RING_R_OUT};")
print(f"STUB_LENGTH = {STUB_LENGTH_ORIG};")
print(f"STUB_END_R = {r_inner_hex};    // = FRAME_RING_R_OUT + STUB_LENGTH")
print(f"")
print(f"// Hexagram derived")
print(f"R_STAR_TIP = {R_tip:.2f};  // = STUB_END_R * sqrt(3)")
print(f"HELIX_R = {HELIX_R_FINAL:.2f};      // where vertical gap = {CORRIDOR_WIDTH}mm")
print(f"CORRIDOR_V_ANGLE = 60;     // degrees, V-opening between arms at helix")
print(f"")
print(f"// Triangle 1 tips (Star of David outer vertices)")
print(f"T1_TIPS = [[{R_tip:.1f}*cos(30), {R_tip:.1f}*sin(30)],")
print(f"           [{R_tip:.1f}*cos(150), {R_tip:.1f}*sin(150)],")
print(f"           [{R_tip:.1f}*cos(270), {R_tip:.1f}*sin(270)]];")
print()
for a in [30, 150, 270]:
    v = pt(R_tip, a)
    print(f"//   Tip {a:3d} deg: ({v[0]:8.1f}, {v[1]:8.1f})")
print()
print(f"// Triangle 2 tips")
print(f"T2_TIPS = [[{R_tip:.1f}*cos(90), {R_tip:.1f}*sin(90)],")
print(f"           [{R_tip:.1f}*cos(210), {R_tip:.1f}*sin(210)],")
print(f"           [{R_tip:.1f}*cos(330), {R_tip:.1f}*sin(330)]];")
print()
for a in [90, 210, 330]:
    v = pt(R_tip, a)
    print(f"//   Tip {a:3d} deg: ({v[0]:8.1f}, {v[1]:8.1f})")

print()
print(f"// 6 ARM LINE SEGMENTS (tip-to-tip through inner hex)")
print(f"// Each arm is a full side of one triangle, passing through 2 inner vertices.")

T1_tips = [30, 150, 270]
T2_tips = [90, 210, 330]

# Triangle 1 sides:
# 30->150 through inner vertices 60 and 120
# 150->270 through inner vertices 180 and 240
# 270->30 through inner vertices 300 and 0
T1_sides = [(30, 150, [60, 120]), (150, 270, [180, 240]), (270, 30, [300, 0])]

# Triangle 2 sides:
# 90->210 through inner vertices 120 and 180
# 210->330 through inner vertices 240 and 300
# 330->90 through inner vertices 0 and 60
T2_sides = [(90, 210, [120, 180]), (210, 330, [240, 300]), (330, 90, [0, 60])]

print()
print("// TRIANGLE 1 SIDES:")
for (a1, a2, inner_verts) in T1_sides:
    v1 = pt(R_tip, a1)
    v2 = pt(R_tip, a2)
    d = v2 - v1
    direction = r2d(math.atan2(d[1], d[0]))
    length = np.linalg.norm(d)
    iv_str = ", ".join([str(iv) for iv in inner_verts])
    print(f"// Side {a1:3d}->{a2:3d}: dir={direction:7.1f} deg, len={length:.1f}mm, "
          f"through inner [{iv_str}]")

print()
print("// TRIANGLE 2 SIDES:")
for (a1, a2, inner_verts) in T2_sides:
    v1 = pt(R_tip, a1)
    v2 = pt(R_tip, a2)
    d = v2 - v1
    direction = r2d(math.atan2(d[1], d[0]))
    length = np.linalg.norm(d)
    iv_str = ", ".join([str(iv) for iv in inner_verts])
    print(f"// Side {a1:3d}->{a2:3d}: dir={direction:7.1f} deg, len={length:.1f}mm, "
          f"through inner [{iv_str}]")

print()
print("// HELIX CORRIDORS (V-shaped):")
print(f"// At each helix position, two arms cross at 60 degrees.")
print(f"// The arms pass from one star tip to another, crossing at the inner hex vertex.")
print(f"// The helix sits at R={HELIX_R_FINAL:.1f}mm where the vertical gap = 60mm.")
print()

helix_corridors = [
    (180, "T1 150->270 (dir -60)", "T2 90->210 (dir -120)", 300, 240),
    (300, "T1 270->30 (dir 60)",   "T2 210->330 (dir 0)",   60, 0),
    (60,  "T1 30->150 (dir 180)",  "T2 330->90 (dir 120)",  180, 120),
]

for (helix_ang, arm1_desc, arm2_desc, dir1, dir2) in helix_corridors:
    hc = pt(HELIX_R_FINAL, helix_ang)
    print(f"// Helix at {helix_ang:3d} deg:  center = ({hc[0]:8.1f}, {hc[1]:8.1f})")
    print(f"//   Arm 1: {arm1_desc}")
    print(f"//   Arm 2: {arm2_desc}")
    print(f"//   V-angle: 60 deg, bisector along {helix_ang} deg")

print()
print("// HELIX POSITIONS:")
for ha in [180, 300, 60]:
    hc = pt(HELIX_R_FINAL, ha)
    print(f"HELIX_{ha}_POS = [{hc[0]:.2f}, {hc[1]:.2f}];  // R={HELIX_R_FINAL:.1f}mm at {ha} deg")

print()
print("// ARM INNER HEX VERTEX COORDINATES (where arms cross):")
for a in [0, 60, 120, 180, 240, 300]:
    v = pt(r_inner_hex, a)
    role = "STUB" if a in [0, 120, 240] else "HELIX_CROSSING"
    print(f"//   {a:3d} deg: ({v[0]:8.1f}, {v[1]:8.1f})  [{role}]")
