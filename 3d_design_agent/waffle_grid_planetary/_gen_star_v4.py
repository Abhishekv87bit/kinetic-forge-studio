"""Symmetric star v4 — no dips, smooth arm profile.
Uses a single smooth curve: R(angle) defined as max of several smooth envelopes.
The key fix: the web envelope overlaps with both pad envelopes so there's never a gap."""
import math

PO_R = 31.4
PI_R = 27.44
PI_ANG = 71.5
HUB_R = 16.5
TIP_R = 40.0

def arm_r_at_angle(ang):
    """R for angle 0-120, one sector. Smooth, no dips."""

    # Envelope 1: PO lobe — wide Gaussian centered at 0
    po_sigma = 18  # width in degrees
    r_po = HUB_R + (TIP_R - HUB_R) * math.exp(-0.5 * (ang / po_sigma)**2)

    # Also check distance from 120 (next PO)
    r_po_next = HUB_R + (TIP_R - HUB_R) * math.exp(-0.5 * ((ang - 120) / po_sigma)**2)

    # Envelope 2: PI lobe — wide Gaussian centered at 71.5
    pi_sigma = 18
    r_pi = HUB_R + (TIP_R - HUB_R) * math.exp(-0.5 * ((ang - PI_ANG) / pi_sigma)**2)

    # Envelope 3: Web connecting PO to PI
    # A smooth raised curve from ~10 to ~60 degrees at moderate R
    web_center = PI_ANG / 2  # ~35.75 deg
    web_sigma = 25
    web_peak = 35  # web peak radius
    r_web = HUB_R + (web_peak - HUB_R) * math.exp(-0.5 * ((ang - web_center) / web_sigma)**2)

    r = max(r_po, r_po_next, r_pi, r_web, HUB_R)
    return min(r, TIP_R)


# Generate
steps = 60
all_pts = []
for sector in range(3):
    for i in range(steps):
        ang = i * 120.0 / steps
        r = arm_r_at_angle(ang)
        g = ang + sector * 120
        x = r * math.cos(math.radians(g))
        y = r * math.sin(math.radians(g))
        all_pts.append((x, y))

print("// Symmetric 3-arm star carrier plate v4")
print(f"// {len(all_pts)} pts, 3-fold symmetric, smooth Gaussian lobes")
print("CAR_PROFILE_PTS = [")
lines = [f"    [{x:7.2f}, {y:7.2f}]" for x, y in all_pts]
print(",\n".join(lines))
print("];")

print("\n// R vs angle:")
for i in range(steps + 1):
    a = i * 120.0 / steps
    r = arm_r_at_angle(a)
    bar = '#' * int(r / 2)
    mark = ""
    if abs(a) < 1: mark = " <- PO"
    if abs(a - PI_ANG) < 1: mark = " <- PI"
    if abs(a - 90) < 1: mark = " <- notch"
    print(f"//   {a:5.1f}: R={r:5.1f} {bar}{mark}")

# Verify pin holes have enough material around them
print("\n// Material check:")
for name, pr, pa in [("PO", PO_R, 0), ("PI", PI_R, PI_ANG)]:
    r_at_hole = arm_r_at_angle(pa)
    margin = r_at_hole - pr - 4  # need 4mm wall outside hole edge
    print(f"//   {name} at R={pr}, ang={pa}: plate R={r_at_hole:.1f}, margin={margin:.1f}mm")
    # Check angular width at pin orbit
    for da in range(1, 20):
        r_check = arm_r_at_angle(pa + da)
        if r_check < pr + 4:
            print(f"//     arm edge at +{da} deg (R={r_check:.1f})")
            break
    for da in range(1, 20):
        r_check = arm_r_at_angle(pa - da)
        if r_check < pr + 4:
            print(f"//     arm edge at -{da} deg (R={r_check:.1f})")
            break
