"""Generate clean symmetric 3-arm star carrier plate.
Uses hull-like approach: each arm is defined by 2 circles (at PO and PI hole positions)
connected smoothly, with rounded tips. The notch between arms drops to hub radius.

Result: smooth, symmetric, production-quality carrier plate profile."""
import math

# Pin positions (per 120-deg sector)
PO_R = 31.4      # PO pin orbit radius
PO_ANG = 0       # PO pin angle in sector (center of one arm tip)
PI_R = 27.44     # PI pin orbit radius
PI_ANG = 71.5    # PI pin angle in sector

# Geometry
HUB_R = 16.5     # hub outer radius
ARM_WIDTH = 12   # arm half-width (angular extent at each hole position)
TIP_R = 40.0     # max outer radius at arm tip

# Each arm: two circular pads (at PO and PI) connected by a web
# PO pad: centered at (PO_R, PO_ANG), radius ~TIP_R at center, tapers
# PI pad: centered at (PI_R, PI_ANG), radius ~TIP_R at center, tapers
# Web: connects the two pads smoothly
# Notch: between PI of one sector and PO of next sector, drops to HUB_R

def smooth_step(x):
    """Smooth step function (0 to 1 for x in 0 to 1)."""
    x = max(0, min(1, x))
    return x * x * (3 - 2 * x)

def arm_r_at_angle(ang):
    """Return R for one 120-degree sector (0 to 120 degrees).
    Uses smooth blending of arm pad contours."""

    # === PO arm pad (centered at PO_ANG=0, extends to TIP_R) ===
    # Width: wider at tip (R=TIP_R), narrows toward hub
    po_dist = abs(ang - PO_ANG)
    if ang > 60:  # wrap for sector boundary
        po_dist = min(po_dist, abs(ang - 120))  # not needed here since PO_ANG=0

    po_half_width = 16  # degrees half-width at outer edge
    if po_dist < po_half_width:
        # Cosine taper from tip
        blend = math.cos(math.radians(90 * po_dist / po_half_width))
        r_po = HUB_R + (TIP_R - HUB_R) * blend
    else:
        r_po = HUB_R

    # === PI arm pad (centered at PI_ANG=71.5) ===
    pi_dist = abs(ang - PI_ANG)
    pi_half_width = 16
    if pi_dist < pi_half_width:
        blend = math.cos(math.radians(90 * pi_dist / pi_half_width))
        r_pi = HUB_R + (TIP_R - HUB_R) * blend
    else:
        r_pi = HUB_R

    # === Web bridge connecting PO and PI ===
    # Between the two pads, maintain enough radius to contain the pin orbits
    web_r = HUB_R
    if PO_ANG + po_half_width < ang < PI_ANG - pi_half_width:
        # Smooth bridge between pads
        frac = (ang - PO_ANG - po_half_width) / (PI_ANG - pi_half_width - PO_ANG - po_half_width)
        # Bridge radius: enough to cover both orbit radii + wall
        min_bridge_r = max(PO_R, PI_R) + 5  # cover both orbits with margin
        web_r = HUB_R + (min_bridge_r - HUB_R) * (1 - 4 * (frac - 0.5)**2)
        web_r = max(web_r, HUB_R)

    # Take maximum of all contributions
    r = max(r_po, r_pi, web_r, HUB_R)
    return min(r, TIP_R)


# Generate profile for one sector, then replicate x3
steps_per_sector = 60  # 2-degree steps
all_pts = []

for sector in range(3):
    offset = sector * 120
    for i in range(steps_per_sector):
        ang_local = i * 120.0 / steps_per_sector
        r = arm_r_at_angle(ang_local)
        ang_global = ang_local + offset
        x = r * math.cos(math.radians(ang_global))
        y = r * math.sin(math.radians(ang_global))
        all_pts.append((x, y))

# Print OpenSCAD array
print("// Clean symmetric 3-arm star carrier plate profile")
print(f"// {len(all_pts)} points, 2-deg steps, 3-fold symmetric")
print("// Each arm has PO hole (R=31.4) and PI hole (R=27.44, +71.5 deg)")
print("CAR_PROFILE_PTS = [")
lines = []
for x, y in all_pts:
    lines.append(f"    [{x:7.2f}, {y:7.2f}]")
print(",\n".join(lines))
print("];")

# Debug: print R vs angle
print("\n// R vs angle per sector:")
for i in range(steps_per_sector + 1):
    ang = i * 120.0 / steps_per_sector
    r = arm_r_at_angle(ang)
    bar = '#' * int(r / 2)
    pin = ""
    if abs(ang - PO_ANG) < 1:
        pin = " <-- PO hole"
    if abs(ang - PI_ANG) < 1:
        pin = " <-- PI hole"
    print(f"//   {ang:5.1f}: R={r:5.1f} {bar}{pin}")
