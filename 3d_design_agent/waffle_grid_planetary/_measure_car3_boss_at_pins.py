"""Measure carrier_3 boss OD at each pin location.
Carrier_3 has bosses that slide through carrier_2 pin holes.
One hole per arm must be big enough for the boss OD, the other for the pin."""
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

car3 = read_stl_vertices(STL_DIR + "planetary_3.stl")
po = read_stl_vertices(STL_DIR + "long_pinion.stl")
pi_stl = read_stl_vertices(STL_DIR + "short_pinion.stl")

# Carrier_3 native position center
c3_cx = (min(v[0] for v in car3) + max(v[0] for v in car3)) / 2
c3_cy = (min(v[1] for v in car3) + max(v[1] for v in car3)) / 2
print(f"Carrier_3 center: ({c3_cx:.2f}, {c3_cy:.2f})")
print(f"Carrier_3 Z: {min(v[2] for v in car3):.2f} to {max(v[2] for v in car3):.2f}")

# Po pinion center (native position)
po_cx = (min(v[0] for v in po) + max(v[0] for v in po)) / 2
po_cy = (min(v[1] for v in po) + max(v[1] for v in po)) / 2
print(f"\nPo center: ({po_cx:.2f}, {po_cy:.2f}), R={math.sqrt(po_cx**2+po_cy**2):.2f}")

# Pi pinion center (native position)
pi_cx = (min(v[0] for v in pi_stl) + max(v[0] for v in pi_stl)) / 2
pi_cy = (min(v[1] for v in pi_stl) + max(v[1] for v in pi_stl)) / 2
print(f"Pi center: ({pi_cx:.2f}, {pi_cy:.2f}), R={math.sqrt(pi_cx**2+pi_cy**2):.2f}")

# === CARRIER_3 BOSS AT PO PIN POSITION ===
print("\n=== CARRIER_3 boss at Po pin position ===")
# Find carrier_3 vertices near the Po pin center, below Z=0
po_nearby = [v for v in car3
             if math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) < 10
             and v[2] < 0]
if po_nearby:
    # Find the cylindrical boss
    for z_check in [-3.5, -5.5]:
        at_z = [v for v in po_nearby if abs(v[2] - z_check) < 0.5]
        if at_z:
            dists = [math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) for v in at_z]
            print(f"  Z~{z_check}: boss R from Po center: {min(dists):.2f} to {max(dists):.2f} "
                  f"(D={max(dists)*2:.2f}), n={len(at_z)}")
else:
    print("  No carrier_3 vertices near Po position below Z=0")

# === CARRIER_3 BOSS AT PI PIN POSITION ===
print("\n=== CARRIER_3 boss at Pi pin position ===")
pi_nearby = [v for v in car3
             if math.sqrt((v[0]-pi_cx)**2 + (v[1]-pi_cy)**2) < 10
             and v[2] < 0]
if pi_nearby:
    for z_check in [-3.5, -5.5]:
        at_z = [v for v in pi_nearby if abs(v[2] - z_check) < 0.5]
        if at_z:
            dists = [math.sqrt((v[0]-pi_cx)**2 + (v[1]-pi_cy)**2) for v in at_z]
            print(f"  Z~{z_check}: boss R from Pi center: {min(dists):.2f} to {max(dists):.2f} "
                  f"(D={max(dists)*2:.2f}), n={len(at_z)}")
else:
    print("  No carrier_3 vertices near Pi position below Z=0")

# === What does the carrier_3 look like near both pin positions? ===
print("\n=== CARRIER_3 structure near pin positions ===")
print("At Po pin (31.4, 0):")
for z in [-5.5, -3.5, 0, 5, 10, 10.5]:
    near = [v for v in car3 if abs(v[2] - z) < 0.5
            and math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) < 12]
    if near:
        dists = sorted([math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) for v in near])
        print(f"  Z~{z:5.1f}: R=[{dists[0]:.2f}..{dists[-1]:.2f}], n={len(near)}")

print("\nAt Pi pin (8.7, 26.0):")
for z in [-5.5, -3.5, 0, 5, 10, 10.5]:
    near = [v for v in car3 if abs(v[2] - z) < 0.5
            and math.sqrt((v[0]-pi_cx)**2 + (v[1]-pi_cy)**2) < 12]
    if near:
        dists = sorted([math.sqrt((v[0]-pi_cx)**2 + (v[1]-pi_cy)**2) for v in near])
        print(f"  Z~{z:5.1f}: R=[{dists[0]:.2f}..{dists[-1]:.2f}], n={len(near)}")

# === ACTUAL CARRIER_2 STL HOLE SIZES ===
print("\n=== CARRIER_2 STL actual hole sizes at pin positions ===")
car2 = read_stl_vertices(STL_DIR + "planetary_2.stl")
plate = [v for v in car2 if abs(v[2] - (-1.5)) < 0.2 or abs(v[2] - (-3.5)) < 0.2]

# PO holes
for i in range(3):
    ang = i * 120
    cx = PO_R * math.cos(math.radians(ang)) if 'PO_R' in dir() else 31.4 * math.cos(math.radians(ang))
    cy = 31.4 * math.sin(math.radians(ang))
    nearby = [v for v in plate if math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) < 6]
    if nearby:
        dists = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v in nearby]
        edge = [d for d in dists if 2 < d < 5.5]
        if edge:
            print(f"PO hole at {ang} deg: D={sum(edge)/len(edge)*2:.2f}mm ({len(edge)} edge verts)")

# PI holes — check at 71.5/191.5/311.5
for i in range(3):
    ang = i * 120 + 71.5
    cx = 27.44 * math.cos(math.radians(ang))
    cy = 27.44 * math.sin(math.radians(ang))
    nearby = [v for v in plate if math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) < 8]
    if nearby:
        dists = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v in nearby]
        # Show all distance clusters
        hist = {}
        for d in dists:
            b = round(d)
            hist[b] = hist.get(b, 0) + 1
        print(f"PI hole at {ang:.1f} deg: dist histogram = {dict(sorted(hist.items()))}")
        edge = [d for d in dists if 2 < d < 5.5]
        if edge:
            print(f"  -> edge D={sum(edge)/len(edge)*2:.2f}mm ({len(edge)} edge verts)")
        large_edge = [d for d in dists if 4 < d < 8]
        if large_edge:
            print(f"  -> large edge D={sum(large_edge)/len(large_edge)*2:.2f}mm ({len(large_edge)} verts)")

# === Now check: does the original carrier_2 have DIFFERENT hole sizes for Po vs Pi? ===
print("\n=== VERIFICATION: Are holes different sizes? ===")
print("Po pin stub OD = 8.25mm (from long_pinion measurement)")
print("Pi pin stub OD = 8.25mm (from short_pinion measurement)")
print("Carrier_3 boss OD at Po = (see above)")
print("Carrier_3 boss OD at Pi = (see above)")
print()
print("If carrier_3 bosses are LARGER than pin stubs,")
print("then the holes that the bosses pass through must be bigger.")
print("The OTHER holes just need to clear the pin stubs (D~8.25+clearance).")
