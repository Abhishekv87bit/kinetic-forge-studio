"""Verify whether carrier_2 has a through-bore or is solid.
Check if there are internal vertices indicating a hollow tube."""
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

# At each Z level, find ALL R values and check if there's an inner ring
# (indicating a bore)
print("R distribution at each Z level:")
z_slices = {-1.5: 0.1, -3.5: 0.1, -6.5: 0.5, -10: 2, -15: 2, -19.5: 0.3, -21.5: 0.3}

for z_target, tol in z_slices.items():
    near = [v for v in car2 if abs(v[2] - z_target) < tol]
    if near:
        rs = sorted(set(round(math.sqrt(v[0]**2 + v[1]**2), 2) for v in near))
        print(f"\n  Z~{z_target} ({len(near)} verts, {len(rs)} unique R):")
        # Show first 10 and last 10 R values
        if len(rs) <= 20:
            print(f"    All R: {rs}")
        else:
            print(f"    Smallest: {rs[:10]}")
            print(f"    Largest:  {rs[-10:]}")

        # Check for gap indicating bore
        # If solid, R values should go from 0 to OD continuously
        # If hollow, R values start at bore_r
        min_r = min(rs)
        max_r = max(rs)
        print(f"    R range: {min_r} to {max_r}")

        # Look for the smallest R values — are they at bore edge?
        very_inner = [r for r in rs if r < 15]
        if very_inner:
            print(f"    Inner R (< 15): {very_inner}")
        else:
            print(f"    NO vertices with R < 15 -> tube has no bore at this Z")

# === Also check: does the STL have vertices at R=0 or near-center? ===
print("\n\nVertices near center (R < 5):")
center_v = [v for v in car2 if math.sqrt(v[0]**2 + v[1]**2) < 5]
if center_v:
    for v in center_v[:10]:
        print(f"  ({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f}) R={math.sqrt(v[0]**2+v[1]**2):.3f}")
else:
    print("  NONE — carrier_2 STL has no vertices at center")
    print("  This means: the hub tube IS hollow (there's a bore)")
    print("  The bore inner surface vertices are at R_min for each Z")

# === What's the bore at the hub zone? ===
print("\n\nBore radius at hub zone (the inner surface):")
for z_target in [-5, -8, -10, -12, -15, -18, -19.5]:
    near = [v for v in car2 if abs(v[2] - z_target) < 1.5]
    if near:
        rs = [math.sqrt(v[0]**2 + v[1]**2) for v in near]
        inner_r = min(rs)
        outer_r = max(rs)
        print(f"  Z~{z_target}: inner R={inner_r:.3f} (bore D={inner_r*2:.2f}), outer R={outer_r:.3f} (OD={outer_r*2:.2f})")

# === SL shaft dimensions for clearance check ===
print("\n\nBig Sun (SL) tube dimensions:")
sl = read_stl_vertices(STL_DIR + "big_sun_0_5_backlash.stl")
for z_target in [-5, -10, -15, -20, -25, -30, -35, -38]:
    near = [v for v in sl if abs(v[2] - z_target) < 1]
    if near:
        rs = [math.sqrt(v[0]**2 + v[1]**2) for v in near]
        print(f"  SL at Z~{z_target}: R_min={min(rs):.2f}, R_max={max(rs):.2f}, OD={max(rs)*2:.2f}")

# Need to know: does SL shaft pass THROUGH carrier_2 hub?
print(f"\n  SL tube bottom: Z={min(v[2] for v in sl):.2f}")
print(f"  Carrier_2 hub bottom: Z=-21.5")
print(f"  SL extends below carrier_2: {'YES' if min(v[2] for v in sl) < -21.5 else 'NO'}")
print(f"  SL tube top: Z={max(v[2] for v in sl):.2f}")
