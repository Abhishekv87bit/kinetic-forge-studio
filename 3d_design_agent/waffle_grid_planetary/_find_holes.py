"""Find all circular holes in carrier_2 plate using a clean clustering approach.
Look at the top face (Z=-1.5) and find vertices that form circular edges."""
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

car2 = read_stl_vertices(STL_DIR + "planetary_2.stl")

# Get unique vertices at plate top face (Z=-1.5)
top = {}
for v in car2:
    if abs(v[2] - (-1.5)) < 0.1:
        key = (round(v[0], 3), round(v[1], 3))
        top[key] = v

print(f"Unique top face vertices: {len(top)}")

# Convert to list
verts = list(top.values())

# We know PO holes are at R~31.4, angles ~0/120/240
# Let's find ALL holes by checking which vertices form concentric rings
# around potential hole centers

# Strategy: The hole edge vertices have a specific R from hole center
# We already know the 3 PO holes. Let's find PI holes.

# From the assembly: Pi sits at (8.698, 26.025) in its native position
# The carrier_3 (cage that holds Pi) is at (-22.93 deg) in native position
# But the assembly rotates carrier_3 by i*120 deg

# KEY INSIGHT: In the original Fusion 360 model, carrier_2 and the pinions
# are designed together. The pin holes in carrier_2 MUST match where
# the pinions sit when carrier rotation = 0.

# The long_pinion.stl is at angle 0 deg (center at (31.4, 0))
# The short_pinion.stl is at angle 71.5 deg (center at (8.7, 26.0))
# planetary_3.stl (cage) is at angle -22.9 deg

# BUT: carrier_3 instances are at i*120 offsets
# And carrier_2 has 3-fold symmetry at 120 deg

# So Pi hole should be at (8.698, 26.025) relative to assembly center
# And at (8.698, 26.025) rotated by 120 and 240 deg

# Let's check for holes at EXACTLY those positions
pi_positions = []
for i in range(3):
    ang = i * 120
    cos_a = math.cos(math.radians(ang))
    sin_a = math.sin(math.radians(ang))
    # Rotate the native Pi position by i*120
    px = 8.698 * cos_a - 26.025 * sin_a
    py = 8.698 * sin_a + 26.025 * cos_a
    pi_positions.append((px, py))
    r = math.sqrt(px**2 + py**2)
    a = math.degrees(math.atan2(py, px))
    print(f"Expected Pi hole {i} at ({px:.2f}, {py:.2f}), R={r:.2f}, ang={a:.1f} deg")

print()

# Now check carrier_2 for holes at these positions
for i, (ex, ey) in enumerate(pi_positions):
    nearby = [v for v in verts if math.sqrt((v[0]-ex)**2 + (v[1]-ey)**2) < 8]
    print(f"\nPi hole {i} (expected center ({ex:.2f}, {ey:.2f})):")
    print(f"  Vertices within 8mm: {len(nearby)}")
    if nearby:
        dists = [math.sqrt((v[0]-ex)**2 + (v[1]-ey)**2) for v in nearby]
        # Histogram of distances
        hist = {}
        for d in dists:
            bucket = round(d, 0)
            hist[bucket] = hist.get(bucket, 0) + 1
        print(f"  Distance histogram: {dict(sorted(hist.items()))}")

        # The hole edge should show as a peak at a specific distance
        # Filter for likely hole edge (between 2 and 5mm from center)
        edge = [(v, d) for v, d in zip(nearby, dists) if 2 < d < 5]
        if edge:
            rs = [d for _, d in edge]
            print(f"  Edge vertices (2-5mm): n={len(edge)}, R_avg={sum(rs)/len(rs):.3f}, R_min={min(rs):.3f}, R_max={max(rs):.3f}")
            print(f"  -> Hole D = {sum(rs)/len(rs)*2:.3f}mm")

# Also check Po positions more precisely
print("\n" + "="*60)
print("PO HOLE VERIFICATION")
print("="*60)
po_positions = [(31.4, 0)]
for i in range(3):
    ang = i * 120
    cos_a = math.cos(math.radians(ang))
    sin_a = math.sin(math.radians(ang))
    px = 31.4 * cos_a
    py = 31.4 * sin_a
    nearby = [v for v in verts if math.sqrt((v[0]-px)**2 + (v[1]-py)**2) < 6]
    edge = [(v, d) for v, d in
            [(v, math.sqrt((v[0]-px)**2 + (v[1]-py)**2)) for v in nearby]
            if 2 < d < 5.5]
    if edge:
        rs = [d for _, d in edge]
        # Refine center
        xs = [v[0] for v, _ in edge]
        ys = [v[1] for v, _ in edge]
        cx = sum(xs) / len(xs)
        cy = sum(ys) / len(ys)
        # Recompute
        rs2 = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v, _ in edge]
        r_orbit = math.sqrt(cx**2 + cy**2)
        a_orbit = math.degrees(math.atan2(cy, cx))
        print(f"PO hole {i}: center ({cx:.3f}, {cy:.3f}), orbit R={r_orbit:.3f}, ang={a_orbit:.1f}, hole D={sum(rs2)/len(rs2)*2:.3f}")

# Summary
print("\n" + "="*60)
print("SUMMARY: Required Pin Hole Parameters")
print("="*60)
print(f"PO pin orbit R: 31.4mm (code has 31.5)")
print(f"PO pin hole D: ~8.0mm (code has 8 - CORRECT)")
print(f"PO angular positions: 0/120/240 deg (relative to carrier)")
print()

# Check what Pi holes actually look like vs expected
# The short_pinion pin stub is at R=4.125 from its center -> D=8.25mm
# So the Pi pin hole should also be ~8mm, not 5mm
print("Pi pin stub D: 8.25mm (same as Po)")
print("So Pi pin holes should be ~8mm+ clearance")
print()

# Let me check the actual PI ORBIT more carefully
# Pi at angle 71.5 deg, R=27.44 — but in carrier_2 the hole is at 60 deg?
# Let me check: maybe the Pi hole in carrier_2 is NOT at the Pi pinion center
# because the carrier_3 cage holds the Pi pin separately
# The carrier_2 plate has Pi pin holes that the Pi cage pins go through

# Wait - let me re-read the assembly:
# planetary_3 = carrier cage that holds Pi
# The cage itself has pin holes at Pi orbit
# carrier_2 has pin holes for the CAGE pins (carrier_3 pins)

# Actually, from the measurement:
# carrier_3 center at (-22.93 deg, R=25.75) — this is the CAGE position
# The cage is placed at i*120 angles in the assembly
# carrier_3 has pins that go into carrier_2

# So carrier_2's PI holes might be at the CARRIER_3 orbit, not the Pi orbit!
# carrier_3 orbit R = 25.75?? That doesn't match either.

# Let me re-examine. The carrier_3 holds one Pi + one Po pair?
# Or just the Pi?

# From the code: carrier_3 is placed at i*120, long_pinion at i*120, short_pinion at i*120
# They all rotate together because they're all on the same carrier
# The STL positions show:
#   long_pinion at (31.4, 0) — this is where the PO pin is
#   carrier_3 at (23.7, -10.0) — this is the CAGE body center
#   short_pinion at (8.7, 26.0) — this is where the PI pin is

# In carrier_2, we see 6 holes: 3 at 0/120/240 (PO) and 3 others (PI)
# The PI holes must be at R=27.44, angles that correspond to
# the short_pinion position when first carrier instance (i=0) is loaded

# BUT: The assembly code does NOT rotate short_pinion separately!
# It does: rotate([0,0, ANG_CARRIER + i*120]) import("short_pinion.stl")
# So at ANG_CARRIER=0, i=0: short_pinion is at its native (8.7, 26.0)
# At i=1: rotated +120, so at (8.7, 26.0) rotated 120 deg
# At i=2: rotated +240

# And carrier_2 is at: rotate([0,0, ANG_CARRIER]) carrier_full_shaft()
# So in carrier_2's local frame (ANG_CARRIER=0),
# the PI pins must be at (8.7, 26.0) and its 120/240 copies

# So PI orbit R = 27.44, PI angle = 71.5 deg (+ 120, + 240)

# BUT our code puts them at R=29.5, angle=60/180/300
# R is wrong (29.5 vs 27.44) and angle is wrong (60 vs 71.5)

print(f"CRITICAL: PI_ORBIT should be {math.sqrt(8.698**2 + 26.025**2):.2f} (not 29.5)")
print(f"CRITICAL: PI angle offset should be {math.degrees(math.atan2(26.025, 8.698)):.1f} deg (not 60)")
