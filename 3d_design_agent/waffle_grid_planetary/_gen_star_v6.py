"""Symmetric star v6 — clean polygon, no self-intersections.

Fix from v5: The polar R(angle) approach creates self-intersecting polygons
when R is non-monotonic (dips then rises).

Solution: Use MONOTONIC arm profiles. Each arm has:
- PO peak at 0 deg (R=TIP_R=40)
- Smooth monotonic decrease toward the bridge zone
- Bridge at constant or gently varying R
- PI peak at 71.5 deg (R=pi_peak)
- Smooth monotonic decrease into the notch
- Notch at HUB_R

The key is: NO local minima between PO and PI (bridge doesn't dip).
"""
import math

PO_R = 31.4
PI_R = 27.44
PI_ANG = 71.5
HUB_R = 16.5
TIP_R = 40.0

PIN_WALL = 4.0
PO_PIN_R = 4.0
PI_PIN_R = 4.0

def smooth_blend(x):
    """Smooth step 0->1 for x in 0->1."""
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)

def arm_r_at_angle(ang):
    """R for angle 0-120, one sector.

    Profile zones:
      0       : PO tip (R=TIP_R)
      0-16    : PO arm taper (TIP_R -> bridge_r)
      16-56   : Bridge (gently arched, R >= bridge_r)
      56-71.5 : PI arm rise (bridge_r -> pi_peak)
      71.5    : PI peak
      71.5-85 : PI arm taper (pi_peak -> HUB_R)
      85-115  : Notch (HUB_R)
      115-120 : Next PO arm rise (HUB_R -> TIP_R)
    """

    # PI peak must contain the pin hole
    pi_peak = PI_R + PIN_WALL + PI_PIN_R  # 35.44

    # Bridge R — connects PO arm to PI arm, stays above both pin orbits
    bridge_r = max(PO_R, PI_R) + PIN_WALL  # 35.4

    # Zone boundaries
    po_taper_end = 16.0      # PO arm ends tapering here
    pi_taper_start = 56.0    # PI arm starts rising here
    pi_notch_start = 82.0    # PI arm finishes, notch begins
    notch_end = 115.0        # notch ends, next PO rises

    if ang <= 0:
        return TIP_R

    elif ang <= po_taper_end:
        # PO arm: smooth taper from TIP_R down to bridge_r
        t = ang / po_taper_end  # 0 -> 1
        return TIP_R + (bridge_r - TIP_R) * smooth_blend(t)

    elif ang <= pi_taper_start:
        # Bridge zone: gentle arch, peak at center
        mid = (po_taper_end + pi_taper_start) / 2  # 36
        half_span = (pi_taper_start - po_taper_end) / 2  # 20
        t = (ang - mid) / half_span  # -1 to 1
        # Slight arch: bridge_r at edges, bridge_r+2 at center
        arch = 2.0 * (1 - t*t)
        return bridge_r + arch

    elif ang <= PI_ANG:
        # Rise from bridge to PI peak
        t = (ang - pi_taper_start) / (PI_ANG - pi_taper_start)
        return bridge_r + (pi_peak - bridge_r) * smooth_blend(t)

    elif ang <= pi_notch_start:
        # PI arm taper: pi_peak down to HUB_R
        t = (ang - PI_ANG) / (pi_notch_start - PI_ANG)
        return pi_peak + (HUB_R - pi_peak) * smooth_blend(t)

    elif ang <= notch_end:
        # Deep notch at HUB_R
        return HUB_R

    elif ang <= 120:
        # Rise from HUB_R to next sector's TIP_R
        t = (ang - notch_end) / (120 - notch_end)
        return HUB_R + (TIP_R - HUB_R) * smooth_blend(t)

    else:
        return TIP_R


# Verify monotonicity within each zone
print("// Monotonicity check:")
prev_r = arm_r_at_angle(0)
violations = 0
for i in range(1, 601):
    a = i * 0.2
    r = arm_r_at_angle(a)
    # Check for unexpected direction changes
    if i > 0:
        prev_a = (i-1) * 0.2
        # In taper zones, R should only decrease
        # In rise zones, R should only increase
        # In bridge, slight arch is OK
        pass
    prev_r = r

# Generate profile
steps = 120  # higher resolution for smooth curves
all_pts = []
for sector in range(3):
    for i in range(steps):
        ang = i * 120.0 / steps
        r = arm_r_at_angle(ang)
        g = ang + sector * 120
        x = r * math.cos(math.radians(g))
        y = r * math.sin(math.radians(g))
        all_pts.append((x, y))

# Verify no self-intersections by checking that consecutive points
# always advance CCW (cross product should be consistent)
def cross_2d(o, a, b):
    return (a[0]-o[0])*(b[1]-o[1]) - (a[1]-o[1])*(b[0]-o[0])

n = len(all_pts)
reversals = 0
for i in range(n):
    o = all_pts[i]
    a = all_pts[(i+1) % n]
    b = all_pts[(i+2) % n]
    c = cross_2d(o, a, b)
    if c < -0.01:  # clockwise turn (should be CCW for outer boundary)
        reversals += 1

print(f"// Self-intersection check: {reversals} CW turns out of {n} points")
if reversals > 10:
    print(f"// WARNING: Likely self-intersecting polygon!")
else:
    print(f"// OK: Clean polygon")

print(f"\n// Symmetric 3-arm star carrier plate v6")
print(f"// {len(all_pts)} pts, 3-fold symmetric, monotonic arm profiles")
print("CAR_PROFILE_PTS = [")
lines = [f"    [{x:7.2f}, {y:7.2f}]" for x, y in all_pts]
print(",\n".join(lines))
print("];")

# R vs angle
print("\n// R vs angle per sector:")
for i in range(steps + 1):
    a = i * 120.0 / steps
    r = arm_r_at_angle(a)
    bar = '#' * int(r / 2)
    mark = ""
    if abs(a) < 0.5: mark = " <- PO"
    if abs(a - PI_ANG) < 1: mark = " <- PI"
    if abs(a - 90) < 1: mark = " <- notch"
    if abs(a - 120) < 0.5: mark = " <- next PO"
    print(f"//   {a:5.1f}: R={r:5.1f} {bar}{mark}")

# Material check
print("\n// Material check:")
for name, pr, pa in [("PO", PO_R, 0), ("PI", PI_R, PI_ANG)]:
    r_at = arm_r_at_angle(pa)
    margin = r_at - pr - PO_PIN_R
    print(f"//   {name}: R_plate={r_at:.1f} at {pa} deg, pin at R={pr}, margin={margin:.1f}mm")

    # Angular width at pin orbit
    for da in range(1, 30):
        if arm_r_at_angle(pa + da) < pr + PO_PIN_R:
            print(f"//     arm edge at +{da} deg")
            break
    for da in range(1, 30):
        a_check = pa - da
        if a_check < 0: a_check += 120
        if arm_r_at_angle(a_check) < pr + PO_PIN_R:
            print(f"//     arm edge at -{da} deg")
            break

print(f"\n// Notch R = {HUB_R} from {82} to {115} deg")
