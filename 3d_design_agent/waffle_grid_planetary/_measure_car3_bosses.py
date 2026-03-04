"""Measure carrier_3 (planetary_3.stl) boss geometry.
The bosses stick out below the carrier_2 plate wings.
Need: boss positions, diameters, how far they protrude below Z=-1.5."""
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

xs = [v[0] for v in car3]
ys = [v[1] for v in car3]
zs = [v[2] for v in car3]

print("=== CARRIER_3 (planetary_3.stl) ===")
print(f"Bbox X: {min(xs):.2f} to {max(xs):.2f}")
print(f"Bbox Y: {min(ys):.2f} to {max(ys):.2f}")
print(f"Bbox Z: {min(zs):.2f} to {max(zs):.2f}")

cx = (min(xs) + max(xs)) / 2
cy = (min(ys) + max(ys)) / 2
print(f"Center: ({cx:.2f}, {cy:.2f})")
print(f"Orbit R: {math.sqrt(cx**2 + cy**2):.2f}")
print(f"Orbit angle: {math.degrees(math.atan2(cy, cx)):.1f} deg")

# Z levels
z_unique = sorted(set(round(v[2], 1) for v in car3))
print(f"\nZ levels ({len(z_unique)}): {z_unique}")

# At each Z level, show R range from center
print("\nR range from center at each Z level:")
for z in z_unique:
    near = [v for v in car3 if abs(v[2] - z) < 0.3]
    if near:
        rs = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v in near]
        print(f"  Z={z:6.1f}: R_min={min(rs):.2f}, R_max={max(rs):.2f}, n={len(near)}")

# The bosses are the parts that extend BELOW the carrier_2 plate
# Carrier_2 plate top = Z=-1.5
# So anything in carrier_3 below Z=-1.5 is a boss sticking through

print("\n=== BOSS ANALYSIS (below Z=-1.5) ===")
below = [v for v in car3 if v[2] < -1.5]
if below:
    print(f"Vertices below Z=-1.5: {len(below)}")
    z_below = sorted(set(round(v[2], 1) for v in below))
    print(f"Z levels below plate: {z_below}")

    for z in z_below:
        near = [v for v in below if abs(v[2] - z) < 0.3]
        rs_from_center = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v in near]
        rs_from_origin = [math.sqrt(v[0]**2 + v[1]**2) for v in near]
        print(f"  Z={z:.1f}: R_from_cage_center={min(rs_from_center):.2f}-{max(rs_from_center):.2f}, "
              f"R_from_origin={min(rs_from_origin):.2f}-{max(rs_from_origin):.2f}, n={len(near)}")
else:
    print("No vertices below Z=-1.5")

# Check what's below Z=0 (bottom of gear zone)
print("\n=== Below Z=0 (bottom of gear zone) ===")
below_0 = [v for v in car3 if v[2] < 0]
if below_0:
    z_below_0 = sorted(set(round(v[2], 1) for v in below_0))
    print(f"Z levels below Z=0: {z_below_0}")
    for z in z_below_0:
        near = [v for v in below_0 if abs(v[2] - z) < 0.3]
        # Find distinct clusters (the bosses)
        # Each boss is a cylinder — find XY positions
        xs_n = [v[0] for v in near]
        ys_n = [v[1] for v in near]
        rs_origin = [math.sqrt(v[0]**2 + v[1]**2) for v in near]
        print(f"  Z={z:.1f}: X=[{min(xs_n):.1f},{max(xs_n):.1f}], "
              f"Y=[{min(ys_n):.1f},{max(ys_n):.1f}], "
              f"R_origin=[{min(rs_origin):.1f},{max(rs_origin):.1f}], n={len(near)}")

# The boss pin diameters and positions
# Find the boss cylindrical features at the bottom
print("\n=== BOSS CYLINDER ANALYSIS ===")
# At the lowest Z level, find cylinder centers
bot_z = min(zs)
bot_verts = [v for v in car3 if abs(v[2] - bot_z) < 0.3]
if bot_verts:
    # Find clusters in XY
    from collections import defaultdict
    # Simple grid clustering
    clusters = defaultdict(list)
    for v in bot_verts:
        key = (round(v[0], 0), round(v[1], 0))
        clusters[key].append(v)

    # Merge nearby clusters
    merged = []
    used = set()
    cluster_list = list(clusters.items())
    for i, (k1, verts1) in enumerate(cluster_list):
        if i in used:
            continue
        group = list(verts1)
        used.add(i)
        for j, (k2, verts2) in enumerate(cluster_list):
            if j in used:
                continue
            if abs(k1[0]-k2[0]) <= 5 and abs(k1[1]-k2[1]) <= 5:
                group.extend(verts2)
                used.add(j)
        if len(group) > 3:
            merged.append(group)

    print(f"Found {len(merged)} boss clusters at Z~{bot_z:.1f}:")
    for i, group in enumerate(merged):
        gx = sum(v[0] for v in group) / len(group)
        gy = sum(v[1] for v in group) / len(group)
        gr = math.sqrt(gx**2 + gy**2)
        gang = math.degrees(math.atan2(gy, gx))
        # Radius of the boss circle
        boss_rs = [math.sqrt((v[0]-gx)**2 + (v[1]-gy)**2) for v in group]
        print(f"  Boss {i}: center ({gx:.2f}, {gy:.2f}), orbit R={gr:.2f}, "
              f"angle={gang:.1f} deg, boss R={max(boss_rs):.2f} (D={max(boss_rs)*2:.2f}), "
              f"n={len(group)}")

# Also measure the carrier_3 at the plate level (where it interfaces with carrier_2)
print("\n=== CARRIER_3 at plate interface level ===")
for z_check in [-1.5, -3.5, -5.5]:
    near = [v for v in car3 if abs(v[2] - z_check) < 0.5]
    if near:
        print(f"Z~{z_check}: {len(near)} verts")
        # Check XY extent
        xs_c = [v[0] for v in near]
        ys_c = [v[1] for v in near]
        print(f"  X: {min(xs_c):.2f} to {max(xs_c):.2f}")
        print(f"  Y: {min(ys_c):.2f} to {max(ys_c):.2f}")
        rs = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v in near]
        print(f"  R from cage center: {min(rs):.2f} to {max(rs):.2f}")

# Also: long_pinion bottom for comparison
print("\n=== LONG PINION boss analysis ===")
po = read_stl_vertices(STL_DIR + "long_pinion.stl")
po_below = [v for v in po if v[2] < 0]
if po_below:
    z_po_below = sorted(set(round(v[2], 1) for v in po_below))
    print(f"Long pinion Z levels below 0: {z_po_below}")
    po_cx = (min(v[0] for v in po) + max(v[0] for v in po)) / 2
    po_cy = (min(v[1] for v in po) + max(v[1] for v in po)) / 2
    for z in z_po_below:
        near = [v for v in po_below if abs(v[2] - z) < 0.3]
        rs = [math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) for v in near]
        print(f"  Z={z:.1f}: R_min={min(rs):.2f}, R_max={max(rs):.2f} (from pinion center)")
else:
    print("Long pinion has NO vertices below Z=0")
    print(f"  Bottom: Z={min(v[2] for v in po):.2f}")
