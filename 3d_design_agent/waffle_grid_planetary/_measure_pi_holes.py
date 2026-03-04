"""Precisely measure PI pin hole locations and diameters in carrier_2.
The PI pin holes are on the carrier_2 plate between the arm lobes.
Need to find their exact (X,Y) centers and diameters."""
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

# Get all vertices at plate Z levels (top and bottom face)
plate = [v for v in car2 if abs(v[2] - (-1.5)) < 0.3 or abs(v[2] - (-3.5)) < 0.3]
print(f"Plate vertices: {len(plate)}")

# === FIND ALL CIRCULAR HOLES ===
# Strategy: the hole edges form circles in the XY plane
# We know Po holes are near 0/120/240 deg at R~31.5
# We need to find Pi holes

# First, let's understand the PI positioning from the assembly:
# planetary_3.stl (carrier cage) holds the short pinion
# It's placed at i*120 + ??? offset
# Let's look at planetary_3 to understand the offset

car3 = read_stl_vertices(STL_DIR + "planetary_3.stl")
c3_cx = (min(v[0] for v in car3) + max(v[0] for v in car3)) / 2
c3_cy = (min(v[1] for v in car3) + max(v[1] for v in car3)) / 2
c3_r = math.sqrt(c3_cx**2 + c3_cy**2)
c3_ang = math.degrees(math.atan2(c3_cy, c3_cx))
print(f"\nCarrier_3 center: ({c3_cx:.3f}, {c3_cy:.3f})")
print(f"  Orbit R: {c3_r:.3f}, Angle: {c3_ang:.2f} deg")

# Pi pinion sits inside carrier_3
pi_v = read_stl_vertices(STL_DIR + "short_pinion.stl")
pi_cx = (min(v[0] for v in pi_v) + max(v[0] for v in pi_v)) / 2
pi_cy = (min(v[1] for v in pi_v) + max(v[1] for v in pi_v)) / 2
pi_r = math.sqrt(pi_cx**2 + pi_cy**2)
pi_ang = math.degrees(math.atan2(pi_cy, pi_cx))
print(f"\nShort pinion center: ({pi_cx:.3f}, {pi_cy:.3f})")
print(f"  Orbit R: {pi_r:.3f}, Angle: {pi_ang:.2f} deg")

# Po pinion for reference
po_v = read_stl_vertices(STL_DIR + "long_pinion.stl")
po_cx = (min(v[0] for v in po_v) + max(v[0] for v in po_v)) / 2
po_cy = (min(v[1] for v in po_v) + max(v[1] for v in po_v)) / 2
po_r = math.sqrt(po_cx**2 + po_cy**2)
po_ang = math.degrees(math.atan2(po_cy, po_cx))
print(f"\nLong pinion center: ({po_cx:.3f}, {po_cy:.3f})")
print(f"  Orbit R: {po_r:.3f}, Angle: {po_ang:.2f} deg")

# The offset between Po and Pi in the same carrier segment
print(f"\nAngle difference (Pi - Po): {pi_ang - po_ang:.2f} deg")
print(f"  Per carrier segment: Po at {po_ang:.1f} deg, Pi at {pi_ang:.1f} deg")
print(f"  Delta: {pi_ang - po_ang:.1f} deg")

# So in the assembly, carrier_3 positions each Pi-Po pair
# But carrier_3 is placed at i*120 (3 copies)
# And long_pinion and short_pinion STLs are at their DEFAULT positions
# meaning they represent the i=0 instance

# === KEY: Where are the PI pins in carrier_2? ===
# The pin holes MUST be at the same (R, angle) as the pinion centers
# Since carrier_2 rotates WITH the carrier, the hole positions are fixed
# relative to the carrier plate

# The Po hole at 0 deg matches long_pinion at po_ang=0 deg
# The Pi hole should match short_pinion at pi_ang=71.5 deg

# But wait — the assembly code shows:
#   for (i = [0:2]):
#     rotate([0, 0, ANG_CARRIER + i * 120])
#     import("long_pinion.stl")
# This means the FIRST long_pinion sits at its native position (0 deg)
# and is then rotated by ANG_CARRIER

# Similarly short_pinion at its native position (71.5 deg)
# So in carrier frame: Po at R=31.4, ang=0; Pi at R=27.44, ang=71.5

# But carrier_2 ALSO rotates by ANG_CARRIER, so in carrier_2's frame,
# the pin holes need to be at:
#   Po: R=31.4, angles 0/120/240
#   Pi: R=27.44, angles 71.5 / 191.5 / 311.5

# WAIT — the code currently has:
#   Pi at R=29.5, angles 60/180/300
# But the STL shows Pi center at R=27.44, angle=71.5

# Let me verify by checking actual hole centers in carrier_2 STL

print("\n" + "="*60)
print("ACTUAL HOLE LOCATIONS IN CARRIER_2 STL")
print("="*60)

# Strategy: look for hole edges as clusters of vertices at plate level
# that form small circles

# First find Po holes (we know these are at R~31.5, 0/120/240)
po_hole_centers = []
for test_ang in [0, 120, 240]:
    test_x = 31.5 * math.cos(math.radians(test_ang))
    test_y = 31.5 * math.sin(math.radians(test_ang))
    nearby = [(v, math.sqrt((v[0]-test_x)**2 + (v[1]-test_y)**2))
              for v in plate if math.sqrt((v[0]-test_x)**2 + (v[1]-test_y)**2) < 6]
    # Hole edge vertices are at the hole radius from hole center
    edge = [(v, d) for v, d in nearby if 2 < d < 5.5]
    if edge:
        # Refine center by fitting circle
        # Simple: avg of vertices weighted by angle
        xs = [v[0] for v, _ in edge]
        ys = [v[1] for v, _ in edge]
        cx = sum(xs) / len(xs)
        cy = sum(ys) / len(ys)
        # Recompute radius from refined center
        rs = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v, _ in edge]
        avg_r = sum(rs) / len(rs)
        po_hole_centers.append((cx, cy, avg_r))
        orbit_r = math.sqrt(cx**2 + cy**2)
        orbit_ang = math.degrees(math.atan2(cy, cx))
        print(f"PO hole at ~{test_ang} deg:")
        print(f"  Center: ({cx:.3f}, {cy:.3f})")
        print(f"  Orbit R: {orbit_r:.3f}, Angle: {orbit_ang:.2f} deg")
        print(f"  Hole radius: {avg_r:.3f} -> Hole D: {avg_r*2:.3f}mm")

# Now find Pi holes — try various angles
# Check at 60, 71.5, 75 deg (and their 120-deg copies)
print("\n--- Searching for PI holes ---")
for base_ang in [60, 65, 70, 71.5, 75, 80]:
    for orbit_r_test in [27, 27.5, 28, 29, 29.5, 30]:
        test_x = orbit_r_test * math.cos(math.radians(base_ang))
        test_y = orbit_r_test * math.sin(math.radians(base_ang))
        nearby = [(v, math.sqrt((v[0]-test_x)**2 + (v[1]-test_y)**2))
                  for v in plate if math.sqrt((v[0]-test_x)**2 + (v[1]-test_y)**2) < 5]
        edge = [(v, d) for v, d in nearby if 2 < d < 4.5]
        if len(edge) > 20:  # Significant cluster
            xs = [v[0] for v, _ in edge]
            ys = [v[1] for v, _ in edge]
            cx = sum(xs) / len(xs)
            cy = sum(ys) / len(ys)
            rs = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v, _ in edge]
            avg_r = sum(rs) / len(rs)
            orbit_actual = math.sqrt(cx**2 + cy**2)
            orbit_ang = math.degrees(math.atan2(cy, cx))
            print(f"  Trial ang={base_ang}, R={orbit_r_test}: found hole center at ({cx:.2f}, {cy:.2f})")
            print(f"    Orbit R={orbit_actual:.2f}, Ang={orbit_ang:.1f}, Hole D={avg_r*2:.2f}, {len(edge)} edges")

# Also try the symmetric copies
print("\n--- Searching at 180+offset and 300+offset ---")
for base_ang in [180, 185, 190, 191.5, 195, 300, 305, 310, 311.5, 315]:
    for orbit_r_test in [27, 27.5, 28, 29, 29.5]:
        test_x = orbit_r_test * math.cos(math.radians(base_ang))
        test_y = orbit_r_test * math.sin(math.radians(base_ang))
        nearby = [(v, math.sqrt((v[0]-test_x)**2 + (v[1]-test_y)**2))
                  for v in plate if math.sqrt((v[0]-test_x)**2 + (v[1]-test_y)**2) < 5]
        edge = [(v, d) for v, d in nearby if 2 < d < 4.5]
        if len(edge) > 20:
            xs = [v[0] for v, _ in edge]
            ys = [v[1] for v, _ in edge]
            cx = sum(xs) / len(xs)
            cy = sum(ys) / len(ys)
            rs = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v, _ in edge]
            avg_r = sum(rs) / len(rs)
            orbit_actual = math.sqrt(cx**2 + cy**2)
            orbit_ang = math.degrees(math.atan2(cy, cx))
            print(f"  Trial ang={base_ang}, R={orbit_r_test}: Orbit R={orbit_actual:.2f}, Ang={orbit_ang:.1f}, Hole D={avg_r*2:.2f}, {len(edge)} edges")
