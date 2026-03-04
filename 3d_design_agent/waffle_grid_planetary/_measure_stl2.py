"""Deeper analysis of planetary_2.stl geometry at each Z level."""
import struct
import math

stl_path = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/planetary_2.stl"

with open(stl_path, 'rb') as f:
    header = f.read(80)
    num_triangles = struct.unpack('<I', f.read(4))[0]
    vertices = []
    for _ in range(num_triangles):
        f.read(12)  # normal
        v1 = struct.unpack('<3f', f.read(12))
        v2 = struct.unpack('<3f', f.read(12))
        v3 = struct.unpack('<3f', f.read(12))
        f.read(2)   # attr
        vertices.extend([v1, v2, v3])

# Analyze each Z level
for z_lvl in [-1.5, -3.5, -6.5, -19.5, -21.5]:
    verts_at_z = [v for v in vertices if abs(v[2] - z_lvl) < 0.01]
    if verts_at_z:
        radii = [math.sqrt(v[0]**2 + v[1]**2) for v in verts_at_z]
        print(f"\n=== Z = {z_lvl} ({len(verts_at_z)} vertices) ===")
        print(f"  R range: [{min(radii):.2f}, {max(radii):.2f}]")

        # Angle histogram: where is material?
        angle_data = {}
        for v in verts_at_z:
            ang = round(math.degrees(math.atan2(v[1], v[0])) % 360, 0)
            r = math.sqrt(v[0]**2 + v[1]**2)
            if ang not in angle_data:
                angle_data[ang] = {'min': r, 'max': r}
            else:
                angle_data[ang]['min'] = min(angle_data[ang]['min'], r)
                angle_data[ang]['max'] = max(angle_data[ang]['max'], r)

        # Group by 30-degree sectors
        for sector_start in range(0, 360, 30):
            sector_verts = [v for v in verts_at_z
                          if sector_start <= (math.degrees(math.atan2(v[1], v[0])) % 360) < sector_start + 30]
            if sector_verts:
                r_vals = [math.sqrt(v[0]**2 + v[1]**2) for v in sector_verts]
                print(f"  {sector_start:3d}-{sector_start+30:3d}°: R=[{min(r_vals):.1f}, {max(r_vals):.1f}]  n={len(sector_verts)}")
            else:
                print(f"  {sector_start:3d}-{sector_start+30:3d}°: NO VERTS")

# Find pin hole positions — look for small circles at Z=-1.5
# Pin holes are depressions, so look for vertices with R near PO_ORBIT or PI_ORBIT
print("\n=== Pin hole analysis (R near 29-32, Z=-1.5 to -3.5) ===")
pin_verts = [v for v in vertices if 28 < math.sqrt(v[0]**2 + v[1]**2) < 33 and -4 < v[2] < -1]
for v in sorted(pin_verts, key=lambda x: math.degrees(math.atan2(x[1], x[0])) % 360)[:30]:
    r = math.sqrt(v[0]**2 + v[1]**2)
    ang = math.degrees(math.atan2(v[1], v[0])) % 360
    print(f"  angle={ang:.1f}°  R={r:.2f}  Z={v[2]:.2f}")
