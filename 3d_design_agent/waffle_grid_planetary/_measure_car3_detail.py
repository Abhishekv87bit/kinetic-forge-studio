"""Detailed anatomy of carrier_3 (planetary_3.stl).
Identify every distinct feature: bosses, flanges, bores, etc."""
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

# Overall bounding box
print("=== CARRIER_3 (planetary_3.stl) FULL ANATOMY ===")
print(f"Bounding box:")
print(f"  X: {min(xs):.2f} to {max(xs):.2f} (span {max(xs)-min(xs):.2f})")
print(f"  Y: {min(ys):.2f} to {max(ys):.2f} (span {max(ys)-min(ys):.2f})")
print(f"  Z: {min(zs):.2f} to {max(zs):.2f} (span {max(zs)-min(zs):.2f})")

# Center of mass (approx)
cx = (min(xs) + max(xs)) / 2
cy = (min(ys) + max(ys)) / 2
print(f"  Approx center XY: ({cx:.2f}, {cy:.2f})")
print(f"  Center orbit R: {math.sqrt(cx**2 + cy**2):.2f}")
print(f"  Center angle: {math.degrees(math.atan2(cy, cx)):.1f} deg")

# Z-level slicing — find features at each level
print("\n=== Z-LEVEL ANALYSIS ===")
z_levels = sorted(set(round(v[2], 1) for v in car3))
print(f"Unique Z levels: {len(z_levels)}")
print(f"Z range: {z_levels[0]} to {z_levels[-1]}")

# Sample at key Z levels
for z_target in [-5.5, -5, -4, -3.5, -3, -2, -1.5, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10.5]:
    near = [v for v in car3 if abs(v[2] - z_target) < 0.3]
    if near:
        nxs = [v[0] for v in near]
        nys = [v[1] for v in near]
        # Bounding box at this Z
        x_span = max(nxs) - min(nxs)
        y_span = max(nys) - min(nys)
        # Radii from body center
        rs = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v in near]
        # Also radii from assembly center
        rs_global = [math.sqrt(v[0]**2 + v[1]**2) for v in near]
        print(f"\n  Z~{z_target:5.1f} ({len(near)} verts):")
        print(f"    X: [{min(nxs):.1f}, {max(nxs):.1f}] span={x_span:.1f}")
        print(f"    Y: [{min(nys):.1f}, {max(nys):.1f}] span={y_span:.1f}")
        print(f"    R from body center: [{min(rs):.1f}, {max(rs):.1f}]")
        print(f"    R from assembly origin: [{min(rs_global):.1f}, {max(rs_global):.1f}]")

# === Find the BOSS features ===
# Look for protruding cylindrical features at specific positions
print("\n\n=== BOSS IDENTIFICATION ===")
# The carrier_3 holds pins for both Po and Pi
# Find clusters of vertices at different XY positions

# At the top (Z > 8), what sticks up?
top_verts = [v for v in car3 if v[2] > 8]
if top_verts:
    print(f"\nTop features (Z > 8): {len(top_verts)} verts")
    print(f"  X: [{min(v[0] for v in top_verts):.2f}, {max(v[0] for v in top_verts):.2f}]")
    print(f"  Y: [{min(v[1] for v in top_verts):.2f}, {max(v[1] for v in top_verts):.2f}]")
    # Find sub-clusters by XY position
    from collections import defaultdict
    clusters = defaultdict(list)
    for v in top_verts:
        key = (round(v[0], 0), round(v[1], 0))
        clusters[key].append(v)
    print(f"  XY clusters (rounded to 1mm): {len(clusters)}")
    # Show largest clusters
    for key in sorted(clusters, key=lambda k: -len(clusters[k]))[:5]:
        vl = clusters[key]
        r_global = math.sqrt(key[0]**2 + key[1]**2)
        ang = math.degrees(math.atan2(key[1], key[0]))
        print(f"    ({key[0]:.0f}, {key[1]:.0f}) R={r_global:.1f} ang={ang:.1f}: {len(vl)} verts, Z=[{min(v[2] for v in vl):.1f}, {max(v[2] for v in vl):.1f}]")

# At the bottom (Z < -3), what sticks down?
bot_verts = [v for v in car3 if v[2] < -3]
if bot_verts:
    print(f"\nBottom features (Z < -3): {len(bot_verts)} verts")
    print(f"  X: [{min(v[0] for v in bot_verts):.2f}, {max(v[0] for v in bot_verts):.2f}]")
    print(f"  Y: [{min(v[1] for v in bot_verts):.2f}, {max(v[1] for v in bot_verts):.2f}]")
    clusters = defaultdict(list)
    for v in bot_verts:
        key = (round(v[0], 0), round(v[1], 0))
        clusters[key].append(v)
    print(f"  XY clusters: {len(clusters)}")
    for key in sorted(clusters, key=lambda k: -len(clusters[k]))[:10]:
        vl = clusters[key]
        r_global = math.sqrt(key[0]**2 + key[1]**2)
        ang = math.degrees(math.atan2(key[1], key[0]))
        print(f"    ({key[0]:.0f}, {key[1]:.0f}) R={r_global:.1f} ang={ang:.1f}: {len(vl)} verts, Z=[{min(v[2] for v in vl):.1f}, {max(v[2] for v in vl):.1f}]")

# === Cross-reference with pinion positions ===
print("\n\n=== CROSS-REFERENCE WITH PINIONS ===")
# Long pinion (Po) native center: (31.4, 0) → angle 0 deg
# Short pinion (Pi) native center: (8.7, 26.0) → R=27.44, angle 71.5 deg

# Carrier_3 native center is at ~(-22.93 deg), R~25.75
# What features does it have near the Po and Pi positions?

# Po pin position (in assembly coords): (31.4, 0)
po_near = [v for v in car3 if math.sqrt((v[0]-31.4)**2 + (v[1]-0)**2) < 12]
print(f"\nVerts near Po position (31.4, 0): {len(po_near)}")
if po_near:
    print(f"  Z range: [{min(v[2] for v in po_near):.2f}, {max(v[2] for v in po_near):.2f}]")
    # R from Po center
    po_rs = [math.sqrt((v[0]-31.4)**2 + (v[1]-0)**2) for v in po_near]
    print(f"  R from Po center: [{min(po_rs):.2f}, {max(po_rs):.2f}]")

# Pi pin position (in assembly coords): (8.698, 26.025)
pi_near = [v for v in car3 if math.sqrt((v[0]-8.698)**2 + (v[1]-26.025)**2) < 12]
print(f"\nVerts near Pi position (8.698, 26.025): {len(pi_near)}")
if pi_near:
    print(f"  Z range: [{min(v[2] for v in pi_near):.2f}, {max(v[2] for v in pi_near):.2f}]")
    pi_rs = [math.sqrt((v[0]-8.698)**2 + (v[1]-26.025)**2) for v in pi_near]
    print(f"  R from Pi center: [{min(pi_rs):.2f}, {max(pi_rs):.2f}]")

# === The boss the user is pointing at ===
# From the screenshot, it's a cylindrical boss with a flange/collar
# sticking out sideways from the carrier_3 body
# Let's find all distinct cylindrical features

print("\n\n=== CYLINDRICAL FEATURE DETECTION ===")
# Group all vertices by proximity to potential axis centers
# Look for vertices that form rings at consistent radii

# For each Z slice, find distinct circular clusters
for z_target in [0, 5, 10, -3, -5]:
    near = [v for v in car3 if abs(v[2] - z_target) < 0.5]
    if not near:
        continue
    # K-means-like: find distinct XY centers
    # Simple approach: find isolated XY clusters
    visited = set()
    cluster_list = []
    for i, v in enumerate(near):
        if i in visited:
            continue
        # Find all verts within 3mm of this one in XY
        members = []
        for j, w in enumerate(near):
            if j not in visited and math.sqrt((v[0]-w[0])**2 + (v[1]-w[1])**2) < 3:
                members.append(j)
                visited.add(j)
        if len(members) > 5:
            mx = sum(near[k][0] for k in members) / len(members)
            my = sum(near[k][1] for k in members) / len(members)
            rs = [math.sqrt((near[k][0]-mx)**2 + (near[k][1]-my)**2) for k in members]
            cluster_list.append((mx, my, len(members), max(rs)))

    if cluster_list:
        print(f"\n  Z~{z_target}: {len(cluster_list)} feature clusters")
        for mx, my, n, maxr in sorted(cluster_list, key=lambda x: -x[2])[:6]:
            rg = math.sqrt(mx**2 + my**2)
            ag = math.degrees(math.atan2(my, mx))
            print(f"    center=({mx:.1f}, {my:.1f}) R_global={rg:.1f} ang={ag:.1f} n={n} feature_r={maxr:.1f}")


# === What is the boss visible in the screenshot? ===
# The screenshot shows a cylindrical feature with what looks like:
# - A main cylinder body
# - A flange/collar around it
# - A through-bore
# This is likely the pin boss that holds the planet pin

print("\n\n=== PIN BOSS GEOMETRY ===")
# The carrier_3 cage has bosses where planet pins pass through
# At the PO position: the boss wraps around the Po pin
# Let's check the boss geometry at the Po pin position more carefully

# Get ALL vertices near Po center, slice by Z
if po_near:
    print("\nPo boss Z-profile:")
    for z in range(-6, 12):
        sl = [v for v in po_near if abs(v[2] - z) < 0.5]
        if sl:
            dists = [math.sqrt((v[0]-31.4)**2 + v[1]**2) for v in sl]
            print(f"  Z={z:3d}: n={len(sl):3d}, R_from_Po=[{min(dists):.1f}, {max(dists):.1f}] (D=[{min(dists)*2:.1f}, {max(dists)*2:.1f}])")
