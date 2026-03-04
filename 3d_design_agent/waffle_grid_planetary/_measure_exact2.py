"""Exact measurements using actual STL Z levels: -1.5, -3.5, -6.5, -19.5, -21.5"""
import struct
import math

stl_path = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/planetary_2.stl"

with open(stl_path, 'rb') as f:
    header = f.read(80)
    num_triangles = struct.unpack('<I', f.read(4))[0]
    vertices = []
    for _ in range(num_triangles):
        f.read(12)
        v1 = struct.unpack('<3f', f.read(12))
        v2 = struct.unpack('<3f', f.read(12))
        v3 = struct.unpack('<3f', f.read(12))
        f.read(2)
        vertices.extend([v1, v2, v3])

print("Z levels: -1.5 (top), -3.5 (plate bottom), -6.5 (hub top), -19.5 (hub bottom), -21.5 (cap)")

# Each Z level
for z in [-1.5, -3.5, -6.5, -19.5, -21.5]:
    verts = [v for v in vertices if abs(v[2] - z) < 0.05]
    r_vals = [math.sqrt(v[0]**2 + v[1]**2) for v in verts]
    print(f"\nZ={z}: {len(verts)} verts, R=[{min(r_vals):.2f}, {max(r_vals):.2f}]")

# Structure from Z levels:
# Z=-1.5 to -3.5: plate (2mm thick) — star shape, OD=80, ID=27.24
# Z=-3.5 to -6.5: hub only (3mm) — tube OD=33, has inner bore
# Z=-6.5 to -19.5: hub tube (13mm) — tube OD=33
# Z=-19.5 to -21.5: bottom cap (2mm) — closes tube

# === Pin holes ===
# The STL has pin holes as cylindrical features within the plate
# Find clusters of vertices at known orbit radii
print("\n=== Pin hole detection ===")

# At Z=-1.5 (top face), find all vertices, group by angle
top_verts = [v for v in vertices if abs(v[2] - (-1.5)) < 0.05]

# Pin holes are circular depressions — vertices forming small circles
# within the plate. Look for vertex clusters at R~28-32
pin_candidates = [(v, math.sqrt(v[0]**2+v[1]**2), math.degrees(math.atan2(v[1],v[0]))%360)
                  for v in top_verts if 25 < math.sqrt(v[0]**2+v[1]**2) < 35]

# Group by angle (10° bins)
from collections import defaultdict
bins = defaultdict(list)
for v, r, ang in pin_candidates:
    bins[round(ang/10)*10].append((v, r, ang))

# Pin holes should show up as vertices at specific angles with R values
# that form a circle (constant distance from pin center)
# Known pin positions: PO at 0/120/240°, PI at 60/180/300°
for target_ang in [0, 60, 120, 180, 240, 300]:
    orbit_r = 31.5 if target_ang % 120 == 0 else 29.5
    pin_cx = orbit_r * math.cos(math.radians(target_ang))
    pin_cy = orbit_r * math.sin(math.radians(target_ang))

    # Find vertices near pin center across all Z levels
    near_pin = []
    for v in vertices:
        dx = v[0] - pin_cx
        dy = v[1] - pin_cy
        dist = math.sqrt(dx*dx + dy*dy)
        if dist < 6:
            near_pin.append((v, dist))

    if near_pin:
        dists = sorted(set(round(d, 2) for _, d in near_pin))
        # The smallest cluster of distances is the pin hole radius
        # Filter to get the actual hole edge vertices
        hole_edge = [(v, d) for v, d in near_pin if 1.0 < d < 4.0]
        if hole_edge:
            hole_dists = [d for _, d in hole_edge]
            avg_d = sum(hole_dists)/len(hole_dists)
            z_vals_pin = sorted(set(round(v[2], 1) for v, _ in hole_edge))
            pin_type = "PO" if target_ang % 120 == 0 else "PI"
            print(f"  {pin_type} pin @ {target_ang}deg: hole R~{avg_d:.2f} -> D~{avg_d*2:.2f}, Z={z_vals_pin}")
        else:
            print(f"  Pin @ {target_ang}°: no clear hole edge (dists: {dists[:8]})")

# === Hub bore ===
# Inner bore — minimum R at each Z level
print("\n=== Hub bore ===")
for z in [-1.5, -3.5, -6.5, -19.5, -21.5]:
    verts = [v for v in vertices if abs(v[2] - z) < 0.05]
    r_vals = [math.sqrt(v[0]**2 + v[1]**2) for v in verts]
    inner_r = [r for r in r_vals if r < 18]
    if inner_r:
        print(f"  Z={z}: bore R_min={min(inner_r):.2f} -> ID={min(inner_r)*2:.2f}")
