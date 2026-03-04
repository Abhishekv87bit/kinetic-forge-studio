"""Generate a clean, symmetric 3-arm star carrier plate profile.
Each arm pair (PO + PI holes) forms one wing.
The star has 3-fold rotational symmetry with smooth curves.

Pin positions:
  PO at R=31.4, angles 0/120/240
  PI at R=27.44, angles 71.5/191.5/311.5

Each arm must be wide enough to contain both a PO hole and a PI hole
with adequate material around them (min 3mm wall around each 8mm hole).

Arm structure per 120-deg sector:
  - PO hole at 0 deg, R=31.4
  - PI hole at 71.5 deg, R=27.44
  - The arm spans from ~-15 deg to ~85 deg (covers both holes)
  - Deep notch between arms at ~95-115 deg (drops to hub R)

For symmetry: each sector is identical, just rotated 120 deg.
"""
import math

# Pin positions
PO_R = 31.4
PI_R = 27.44
PI_ANG = 71.5  # relative to PO at 0

# Geometry
HUB_R = 16.5   # hub outer radius (min profile R)
PLATE_R = 40.0  # max plate outer radius
HOLE_D = 8.0    # pin hole diameter
WALL_MIN = 4.0  # minimum wall around holes
BOSS_CLEARANCE_R = 10  # carrier_3 boss radius at PO position

# Each arm spans from PO hole to PI hole
# PO at 0 deg, PI at 71.5 deg
# Arm centerline roughly at (0 + 71.5) / 2 = 35.75 deg

# Need enough material around each hole:
# PO hole: center at R=31.4, need material from R=31.4-8 to R=31.4+8 (min)
# PI hole: center at R=27.44, need material from R=27.44-8 to R=27.44+8

# Arm angular width at each hole (arc width = hole_D + 2*wall at that radius):
# At PO (R=31.4): angular half-width = asin((HOLE_D/2 + WALL_MIN) / PO_R) ~ asin(8/31.4) ~ 14.7 deg
# At PI (R=27.44): angular half-width = asin((HOLE_D/2 + WALL_MIN) / PI_R) ~ asin(8/27.44) ~ 17.0 deg

def arm_profile_sector(steps=180):
    """Generate R(angle) for one 120-degree sector.
    Returns list of (angle, R) pairs from 0 to 120 degrees."""
    pts = []

    # Define arm shape using smooth transitions
    # Arm covers ~-10 to ~82 degrees (PO to PI with margin)
    # Notch from ~82 to ~110 degrees

    for i in range(steps + 1):
        ang = i * 120.0 / steps  # 0 to 120

        # Distance from PO hole center (at 0 deg, R=31.4)
        po_x = PO_R
        po_y = 0
        pt_x = 40 * math.cos(math.radians(ang))  # test point on outer edge
        pt_y = 40 * math.sin(math.radians(ang))

        # Distance from PI hole center (at 71.5 deg, R=27.44)
        pi_x = PI_R * math.cos(math.radians(PI_ANG))
        pi_y = PI_R * math.sin(math.radians(PI_ANG))

        # Arm shape: smooth blend between PO arm and PI arm
        # Use an envelope approach — R is the max of hub_R and the arm contours

        # PO arm: Gaussian-like bulge centered at 0 deg
        po_ang_dist = min(abs(ang), abs(ang - 360))
        po_width = 22  # angular half-width of PO arm (degrees)
        if po_ang_dist < po_width:
            r_po = HUB_R + (PLATE_R - HUB_R) * math.cos(math.radians(90 * po_ang_dist / po_width))
        else:
            r_po = HUB_R

        # PI arm: Gaussian-like bulge centered at 71.5 deg
        pi_ang_dist = abs(ang - PI_ANG)
        pi_width = 22  # angular half-width of PI arm
        if pi_ang_dist < pi_width:
            r_pi = HUB_R + (PLATE_R - HUB_R) * math.cos(math.radians(90 * pi_ang_dist / pi_width))
        else:
            r_pi = HUB_R

        # Bridge between arms (connecting material)
        # From ~20 to ~50 deg, maintain enough R to bridge between PO and PI
        bridge_r = HUB_R
        if 15 < ang < PI_ANG - 15:
            # Linear bridge at a reasonable radius
            frac = (ang - 15) / (PI_ANG - 30)
            bridge_r = HUB_R + 8 * math.sin(math.radians(180 * frac))
            # Also ensure we cover both orbits
            bridge_r = max(bridge_r, min(PO_R, PI_R) + HOLE_D/2 + WALL_MIN - 4)

        r = max(r_po, r_pi, bridge_r, HUB_R)

        # Clamp to plate limits
        r = min(r, PLATE_R)
        r = max(r, HUB_R)

        pts.append((ang, r))

    return pts


def generate_full_profile():
    """Generate full 360-deg profile with 3-fold symmetry."""
    sector = arm_profile_sector(steps=60)  # 60 steps per 120-deg sector

    all_pts = []
    for copy in range(3):
        offset = copy * 120
        for ang, r in sector:
            if copy > 0 and ang == 0:
                continue  # avoid duplicate at sector boundary
            total_ang = ang + offset
            x = r * math.cos(math.radians(total_ang))
            y = r * math.sin(math.radians(total_ang))
            all_pts.append((x, y))

    return all_pts

pts = generate_full_profile()

# Print as OpenSCAD array
print("// Symmetric 3-arm star carrier plate profile")
print(f"// {len(pts)} points, 3-fold symmetric")
print("// PO holes at R=31.4, 0/120/240 deg")
print("// PI holes at R=27.44, 71.5/191.5/311.5 deg")
print("CAR_PROFILE_PTS = [")
lines = []
for x, y in pts:
    lines.append(f"    [{x:7.2f}, {y:7.2f}]")
print(",\n".join(lines))
print("];")

# Also output the R(angle) for debugging
print("\n// R vs angle (for verification):")
sector = arm_profile_sector(steps=60)
for ang, r in sector:
    bar = '#' * int(r / 2)
    print(f"//   {ang:5.1f} deg: R={r:5.1f} {bar}")
