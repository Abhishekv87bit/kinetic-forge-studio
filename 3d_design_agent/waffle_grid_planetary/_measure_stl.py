"""Read planetary_2.stl and extract key measurements."""
import struct
import math

stl_path = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/planetary_2.stl"

# Read binary STL
with open(stl_path, 'rb') as f:
    header = f.read(80)
    num_triangles = struct.unpack('<I', f.read(4))[0]
    print(f"Triangles: {num_triangles}")

    vertices = []
    for _ in range(num_triangles):
        normal = struct.unpack('<3f', f.read(12))
        v1 = struct.unpack('<3f', f.read(12))
        v2 = struct.unpack('<3f', f.read(12))
        v3 = struct.unpack('<3f', f.read(12))
        attr = struct.unpack('<H', f.read(2))
        vertices.extend([v1, v2, v3])

xs = [v[0] for v in vertices]
ys = [v[1] for v in vertices]
zs = [v[2] for v in vertices]

print(f"\nBounding box:")
print(f"  X: [{min(xs):.2f}, {max(xs):.2f}]  width={max(xs)-min(xs):.2f}")
print(f"  Y: [{min(ys):.2f}, {max(ys):.2f}]  width={max(ys)-min(ys):.2f}")
print(f"  Z: [{min(zs):.2f}, {max(zs):.2f}]  height={max(zs)-min(zs):.2f}")

# Radial analysis
radii = [math.sqrt(v[0]**2 + v[1]**2) for v in vertices]
print(f"\nRadial extent:")
print(f"  Min R: {min(radii):.2f}")
print(f"  Max R: {max(radii):.2f}")

# Z slices — find radius at different Z levels
for z_target in [-1.0, -1.5, -2.0, -3.0, -5.0, -7.0, -9.0, -12.0, -15.0, -18.0, -21.0]:
    nearby = [v for v in vertices if abs(v[2] - z_target) < 0.5]
    if nearby:
        r_vals = [math.sqrt(v[0]**2 + v[1]**2) for v in nearby]
        print(f"  Z={z_target:6.1f}: R_min={min(r_vals):6.2f}  R_max={max(r_vals):6.2f}  (n={len(nearby)})")

# Find distinct Z levels (plate top, plate bottom, tube bottom)
z_unique = sorted(set(round(z, 1) for z in zs))
print(f"\nDistinct Z levels (top 10): {z_unique[-10:]}")
print(f"Distinct Z levels (bot 10): {z_unique[:10]}")

# Angle analysis at plate level (Z ~ -2 to -5) — find where material exists
plate_verts = [v for v in vertices if -5 < v[2] < -1]
if plate_verts:
    angles = [math.degrees(math.atan2(v[1], v[0])) % 360 for v in plate_verts]
    r_at_angle = {}
    for v in plate_verts:
        ang = round(math.degrees(math.atan2(v[1], v[0])) % 360)
        r = math.sqrt(v[0]**2 + v[1]**2)
        if ang not in r_at_angle or r > r_at_angle[ang]:
            r_at_angle[ang] = r
    # Print max radius at each 10-degree increment
    print(f"\nMax radius by angle (plate zone Z=-5 to -1):")
    for a in range(0, 360, 10):
        nearby_ang = [r_at_angle[k] for k in r_at_angle if abs(k-a) < 6]
        if nearby_ang:
            print(f"  {a:3d}°: R_max={max(nearby_ang):.2f}")
