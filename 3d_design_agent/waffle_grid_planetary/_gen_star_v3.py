"""Generate clean symmetric 3-arm star carrier plate v3.
Smooth arm shape with no pinch between PO and PI holes.
Uses max-of-circles approach: each pin position gets a circle pad,
and a continuous web connects them."""
import math

PO_R = 31.4
PI_R = 27.44
PI_ANG = 71.5
HUB_R = 16.5
TIP_R = 40.0

# Arm pad half-widths (angular, at the tip)
PO_HW = 14    # degrees from PO center to arm edge
PI_HW = 14    # degrees from PI center to arm edge

# Web: maintains a minimum R between the two pads
WEB_R_MIN = 32  # minimum web radius between pads (covers both orbits)

def arm_r_at_angle(ang):
    """R for angle 0-120, one sector."""

    # PO pad: cosine lobe at 0 deg
    po_d = min(abs(ang), abs(ang - 120))  # distance from PO
    if po_d <= PO_HW:
        r_po = HUB_R + (TIP_R - HUB_R) * math.cos(math.radians(90 * po_d / PO_HW))
    else:
        r_po = HUB_R

    # PI pad: cosine lobe at 71.5 deg
    pi_d = abs(ang - PI_ANG)
    if pi_d <= PI_HW:
        r_pi = HUB_R + (TIP_R - HUB_R) * math.cos(math.radians(90 * pi_d / PI_HW))
    else:
        r_pi = HUB_R

    # Web bridge: smooth connection between PO and PI
    # Active from PO_HW to PI_ANG - PI_HW
    web_start = PO_HW        # 14 deg
    web_end = PI_ANG - PI_HW  # 57.5 deg
    if web_start < ang < web_end:
        # Smooth bridge — raised cosine that stays above orbit radius
        frac = (ang - web_start) / (web_end - web_start)
        # Use smoothstep-like profile, minimum at center
        # But don't dip below WEB_R_MIN
        bridge_dip = 0.7  # how much the bridge dips (0=flat at TIP_R, 1=dips to WEB_R_MIN)
        profile = 1 - bridge_dip * math.sin(math.radians(180 * frac))
        r_web = HUB_R + (WEB_R_MIN - HUB_R) + (TIP_R - WEB_R_MIN) * profile
    else:
        r_web = HUB_R

    # Notch: between PI of this sector and PO of next sector
    # PI ends at PI_ANG + PI_HW = 85.5, PO of next starts at 120 - PO_HW = 106
    notch_start = PI_ANG + PI_HW  # 85.5
    notch_end = 120 - PO_HW       # 106
    if notch_start <= ang <= notch_end:
        r_notch = HUB_R  # deep notch
    else:
        r_notch = 0

    r = max(r_po, r_pi, r_web, HUB_R)
    return min(r, TIP_R)


# Generate
steps = 60
all_pts = []
for sector in range(3):
    offset = sector * 120
    for i in range(steps):
        ang = i * 120.0 / steps
        r = arm_r_at_angle(ang)
        g = ang + offset
        x = r * math.cos(math.radians(g))
        y = r * math.sin(math.radians(g))
        all_pts.append((x, y))

print("// Clean symmetric 3-arm star carrier plate v3")
print(f"// {len(all_pts)} pts, 3-fold symmetric, smooth web bridge")
print("CAR_PROFILE_PTS = [")
lines = [f"    [{x:7.2f}, {y:7.2f}]" for x, y in all_pts]
print(",\n".join(lines))
print("];")

print("\n// R vs angle (sector 0):")
for i in range(steps + 1):
    a = i * 120.0 / steps
    r = arm_r_at_angle(a)
    bar = '#' * int(r / 2)
    mark = ""
    if abs(a) < 1: mark = " <-- PO"
    if abs(a - PI_ANG) < 1: mark = " <-- PI"
    print(f"//   {a:5.1f}: R={r:5.1f} {bar}{mark}")
