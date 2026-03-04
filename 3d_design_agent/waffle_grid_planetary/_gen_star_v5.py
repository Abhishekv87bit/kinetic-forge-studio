"""Symmetric star v5 — proper deep notches between arms.

Key improvement over v4: notches drop to HUB_R (16.5mm) between arms,
creating the classic 3-arm star shape. Uses Gaussian lobes for each arm
with explicit notch suppression between arms.

The profile has 3-fold symmetry with:
- PO lobe at 0 deg (tip R=40)
- PI lobe at 71.5 deg (tip R=40)
- Deep notch at ~90 deg dropping to HUB_R
- Web bridge from PO to PI at moderate R (~32)
"""
import math

# Exact hole positions from STL measurement
PO_R = 31.4       # PO pin orbit radius
PI_R = 27.44      # PI pin orbit radius
PI_ANG = 71.5     # PI pin angle in sector

HUB_R = 16.5      # hub outer radius
TIP_R = 40.0      # max outer radius at arm tip

# Minimum wall around pin holes
PIN_WALL = 4.0    # need 4mm wall outside pin hole edge
PO_PIN_R = 4.0    # pin hole radius (D=8)
PI_PIN_R = 4.0    # pin hole radius (D=8)

def arm_r_at_angle(ang):
    """R for angle 0-120, one sector. Smooth with deep notches.

    Each arm covers ~0 to ~71.5 deg (PO to PI).
    The notch is ~85 to ~115 deg — must drop to HUB_R.
    """

    # === PO lobe: centered at 0 deg, reaches TIP_R ===
    po_sigma = 12  # tight — arm drops fast away from PO
    r_po = HUB_R + (TIP_R - HUB_R) * math.exp(-0.5 * (ang / po_sigma)**2)
    # Also check from next sector boundary (120 deg)
    r_po_next = HUB_R + (TIP_R - HUB_R) * math.exp(-0.5 * ((ang - 120) / po_sigma)**2)

    # === PI lobe: centered at 71.5 deg ===
    # Peak must contain PI pin: R=27.44 + pin_r=4 + wall=4 = 35.44
    pi_peak = PI_R + PIN_WALL + PI_PIN_R  # 35.44
    pi_sigma = 10  # tight — drops fast on both sides
    r_pi = HUB_R + (pi_peak - HUB_R) * math.exp(-0.5 * ((ang - PI_ANG) / pi_sigma)**2)

    # === Web bridge: connects PO lobe to PI lobe ===
    # Only spans the PO-to-PI zone (0 to 71.5 deg), NOT the notch zone
    web_center = PI_ANG / 2  # ~35.75 deg
    web_sigma = 14  # spans the PO-PI gap but dies before notch
    # Must contain both pin orbits with wall along the bridge
    web_peak = max(PO_R, PI_R) + PIN_WALL  # 31.4 + 4 = 35.4
    r_web = HUB_R + (web_peak - HUB_R) * math.exp(-0.5 * ((ang - web_center) / web_sigma)**2)

    r = max(r_po, r_po_next, r_pi, r_web, HUB_R)
    return min(r, TIP_R)


# Check material around pin holes
def verify_pin_material(ang_pin, r_pin, pin_r, name):
    """Verify enough material around a pin hole."""
    r_at_center = arm_r_at_angle(ang_pin)
    margin_outer = r_at_center - r_pin - pin_r  # material outside pin
    margin_inner = r_pin - pin_r - HUB_R        # material inside pin to hub
    print(f"// {name}: R_plate={r_at_center:.1f}, R_pin={r_pin}, pin_r={pin_r}")
    print(f"//   outer margin: {margin_outer:.1f}mm (need >{PIN_WALL})")
    print(f"//   inner margin: {margin_inner:.1f}mm")

    # Check angular extent at pin orbit
    for da in range(1, 25):
        r_check = arm_r_at_angle(ang_pin + da)
        if r_check < r_pin + pin_r:
            print(f"//   arm edge at +{da} deg (R={r_check:.1f})")
            break
    for da in range(1, 25):
        r_check = arm_r_at_angle(ang_pin - da if ang_pin - da >= 0 else ang_pin - da + 120)
        if r_check < r_pin + pin_r:
            print(f"//   arm edge at -{da} deg (R={r_check:.1f})")
            break


# Generate profile
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

print("// Symmetric 3-arm star carrier plate v5")
print(f"// {len(all_pts)} pts, 3-fold symmetric, deep notches")
print("CAR_PROFILE_PTS = [")
lines = [f"    [{x:7.2f}, {y:7.2f}]" for x, y in all_pts]
print(",\n".join(lines))
print("];")

# R vs angle debug
print("\n// R vs angle per sector:")
for i in range(steps + 1):
    a = i * 120.0 / steps
    r = arm_r_at_angle(a)
    bar = '#' * int(r / 2)
    mark = ""
    if abs(a) < 1: mark = " <- PO"
    if abs(a - PI_ANG) < 1: mark = " <- PI"
    if abs(a - 90) < 1: mark = " <- notch zone"
    if abs(a - 120) < 1: mark = " <- next PO"
    print(f"//   {a:5.1f}: R={r:5.1f} {bar}{mark}")

# Material verification
print("\n// Material check:")
verify_pin_material(0, PO_R, PO_PIN_R, "PO")
verify_pin_material(PI_ANG, PI_R, PI_PIN_R, "PI")

# Check minimum R in notch zone
notch_min_r = 999
notch_min_ang = 0
for i in range(450, 600):  # 90-120 deg zone (in 0.2 deg steps)
    a = i * 0.2
    if a > 120: a -= 120  # wrap
    r = arm_r_at_angle(a)
    if r < notch_min_r:
        notch_min_r = r
        notch_min_ang = a
print(f"\n// Notch minimum: R={notch_min_r:.1f} at {notch_min_ang:.1f} deg")
print(f"// Target notch: R={HUB_R} (hub radius)")
