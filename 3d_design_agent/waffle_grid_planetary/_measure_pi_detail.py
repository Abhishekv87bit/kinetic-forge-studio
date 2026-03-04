"""Deep-dive: Short pinion (Pi) exact orbit and pin diameter.
The Pi STL is positioned at ONE specific angle (not 0 deg).
Need to find actual pin center and diameter from the STL geometry."""
import struct
import math

STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/"

def read_stl_vertices(path):
    with open(path, 'rb') as f:
        f.read(80)
        num_tri = struct.unpack('<I', f.read(4))[0]
        verts = []
        for _ in range(num_tri):
            f.read(12)
            for _ in range(3):
                verts.append(struct.unpack('<3f', f.read(12)))
            f.read(2)
    return verts

# === SHORT PINION ===
pi_v = read_stl_vertices(STL_DIR + "short_pinion.stl")
xs = [v[0] for v in pi_v]
ys = [v[1] for v in pi_v]
zs = [v[2] for v in pi_v]

# Find center of the pinion (center of bounding box in XY)
cx = (min(xs) + max(xs)) / 2
cy = (min(ys) + max(ys)) / 2
print(f"Pi bounding center: ({cx:.3f}, {cy:.3f})")
print(f"Pi orbit R (from bbox center): {math.sqrt(cx**2 + cy**2):.3f}")
print(f"Pi angle: {math.degrees(math.atan2(cy, cx)):.2f} deg")
print(f"Pi Z range: {min(zs):.2f} to {max(zs):.2f}")

# More accurate: find the pin axis by looking at vertices near center
# The pin is a small cylinder in the middle
for z_target in [12, 15, 18, 22]:
    near = [v for v in pi_v if abs(v[2] - z_target) < 0.5]
    if near:
        # distances from bbox center
        dists = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v in near]
        inner = [d for d in dists if d < 6]
        if inner:
            min_r = min(inner)
            max_inner = max(inner)
            print(f"  Z~{z_target}: inner verts: min_r={min_r:.3f}, max_r={max_inner:.3f}")

# === CHECK: The Pi STL has a pin stub at center ===
# Find the actual pin center more precisely
# Look at bottom face (Z=12) inner circle vertices
bot = [v for v in pi_v if abs(v[2] - 12) < 0.5]
if bot:
    # Cluster inner vertices
    dists_from_cx = [(v, math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2)) for v in bot]
    inner = [(v, d) for v, d in dists_from_cx if d < 6]
    if inner:
        print(f"\nPi bottom face inner vertices ({len(inner)} verts):")
        # Find actual center from inner circle
        ix = [v[0] for v, _ in inner]
        iy = [v[1] for v, _ in inner]
        true_cx = (min(ix) + max(ix)) / 2
        true_cy = (min(iy) + max(iy)) / 2
        print(f"  True pin center: ({true_cx:.3f}, {true_cy:.3f})")
        true_orbit = math.sqrt(true_cx**2 + true_cy**2)
        true_ang = math.degrees(math.atan2(true_cy, true_cx))
        print(f"  True orbit R: {true_orbit:.3f}")
        print(f"  True angle: {true_ang:.2f} deg")

        # Pin diameter from inner verts relative to true center
        pin_dists = [math.sqrt((v[0]-true_cx)**2 + (v[1]-true_cy)**2) for v, _ in inner]
        # Inner ring = pin hole, outer ring = pin stub
        pin_vals = sorted(set(round(d, 1) for d in pin_dists))
        print(f"  Distance clusters: {pin_vals}")

        # The pin stub is the solid cylinder at the very center
        stub_verts = [(v, d) for v, d in zip([vv for vv, _ in inner], pin_dists) if d < 3]
        if stub_verts:
            stub_r = max(d for _, d in stub_verts)
            print(f"  Pin stub radius: {stub_r:.3f} -> D={stub_r*2:.3f}")

# === NOW CHECK CARRIER_2 pin holes more carefully ===
print("\n" + "="*60)
print("RE-MEASURING CARRIER_2 PI PIN HOLES (more precise)")
print("="*60)

car2 = read_stl_vertices(STL_DIR + "planetary_2.stl")

# The Pi pins in carrier_2 should be at the SAME orbit as the Pi pinion
# But we placed them at R=29.5. Let's check what R the actual holes are at.

# Get plate top face vertices
plate_top = [v for v in car2 if abs(v[2] - (-1.5)) < 0.2]
print(f"\nPlate top face (Z~-1.5): {len(plate_top)} vertices")

# For each of the 3 Pi positions (60, 180, 300 deg in carrier_2)
# But Pi might not be at 60/180/300 — let's find the actual hole positions
# by looking for circular gaps in the plate

# Strategy: find vertices at specific radii ranges and angle ranges
# The Pi holes should show as missing material at some angle/radius

# Let's look for vertices that form small circles (the pin hole edges)
# At the plate level, we have vertices at various (R, theta) positions
# Group plate vertices by angle to find holes

import numpy as np
# Don't have numpy, do it manually

# Convert to polar
plate_polar = []
for v in plate_top:
    r = math.sqrt(v[0]**2 + v[1]**2)
    ang = math.degrees(math.atan2(v[1], v[0])) % 360
    plate_polar.append((r, ang, v))

# For the Po holes at known R=31.5, find the hole centers
print("\n--- Locating all pin holes from plate vertices ---")

# Find vertices near the star arms (where pin holes are)
# Arms are at 0, 120, 240 deg for Po; Pi should be between arms

# Better approach: find the actual circle centers by looking at
# vertices that form circular arcs around each hole

# For carrier_2 PI holes specifically, let me check the original profile
# The clean profile was generated from polar R(angle) data
# At angle 60 deg: R drops to hub_r (16.5) — that's the NOTCH, not the pin hole
# The pin holes are INSIDE the plate material, not at the notch

# Let's search for vertices near R=29.5 at various angles
for test_r in [27, 28, 29, 29.5, 30, 31, 31.5, 32]:
    near_r = [p for p in plate_polar if abs(p[0] - test_r) < 1]
    if near_r:
        angs = sorted(set(round(p[1]) for p in near_r))
        print(f"  R~{test_r}: {len(near_r)} verts at angles: {angs[:20]}...")

# Look for vertices specifically forming circles at PI orbit
# The Pi pinion orbit from STL was at R~27.44 (from pinion bbox center)
# But the bbox center might not be the pin center
# Let me check carrier_2 profile at 60/180/300 deg directions

for target_ang in [60, 180, 300]:
    sector = [(r, a, v) for r, a, v in plate_polar
              if abs(a - target_ang) < 10 or abs(a - target_ang + 360) < 10 or abs(a - target_ang - 360) < 10]
    if sector:
        rs = sorted(set(round(r, 1) for r, _, _ in sector))
        print(f"\n  Sector around {target_ang} deg: R values = {rs}")
        # The pin hole would show as an inner and outer edge at pin orbit
        for r, a, v in sorted(sector, key=lambda x: x[0]):
            if 24 < r < 35:
                pass  # Too many to print
        # Just print R range
        sector_rs = [r for r, _, _ in sector if 20 < r < 35]
        if sector_rs:
            print(f"    Inner R={min(sector_rs):.2f}, Outer R={max(sector_rs):.2f}")

# === FINAL: Compare Po pin stub diameter to carrier_2 Po hole diameter ===
print("\n" + "="*60)
print("PO PIN vs CARRIER_2 HOLE COMPARISON")
print("="*60)

# Po pin stub at bottom
po_v = read_stl_vertices(STL_DIR + "long_pinion.stl")
po_cx = (min(v[0] for v in po_v) + max(v[0] for v in po_v)) / 2
po_cy = (min(v[1] for v in po_v) + max(v[1] for v in po_v)) / 2
po_bot = [v for v in po_v if abs(v[2] - 0) < 0.5]
po_inner = [v for v in po_bot if math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) < 6]
if po_inner:
    pin_ds = [math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) for v in po_inner]
    # The pin stub outer edge
    stub_r_max = max(pin_ds)
    # There might be a bore through the pin
    stub_r_min = min(pin_ds)
    print(f"Po pin stub: R_min={stub_r_min:.3f}, R_max={stub_r_max:.3f}")
    print(f"  -> Stub OD = {stub_r_max*2:.3f}mm")
    print(f"  -> Carrier_2 PO hole should be slightly larger: ~{stub_r_max*2 + 0.5:.1f}mm")
    print(f"  -> Current code: CAR_PO_PIN_D = 8mm")
    print(f"  -> STL measured PO hole: D~8.0mm")
    print(f"  -> MATCH: {'YES' if abs(stub_r_max*2 - 8) < 1.5 else 'CHECK'}")
