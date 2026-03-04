"""Extract the outer profile of planetary_2.stl at plate level as polygon points."""
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

# Get outer profile at plate Z=-1.5 (top face)
# For each angle, find max radius
plate_verts = [v for v in vertices if abs(v[2] - (-1.5)) < 0.1]

# Build max-radius profile at 1° increments
profile = {}
for v in plate_verts:
    r = math.sqrt(v[0]**2 + v[1]**2)
    ang = round(math.degrees(math.atan2(v[1], v[0])) % 360, 0)
    if ang not in profile or r > profile[ang]:
        profile[ang] = r

# Output as OpenSCAD polygon points
print("// Outer profile of planetary_2.stl at Z=-1.5")
print("// Generated from STL vertex data")
print("module carrier_profile_2d() {")
print("    polygon([")
pts = []
for ang in sorted(profile.keys()):
    r = profile[ang]
    x = r * math.cos(math.radians(ang))
    y = r * math.sin(math.radians(ang))
    pts.append(f"        [{x:.2f}, {y:.2f}]")
print(",\n".join(pts))
print("    ]);")
print("}")

# Also print just the R vs angle table
print("\n// R vs angle (outer profile):")
for ang in range(0, 360, 5):
    nearby = [(k, profile[k]) for k in profile if abs(k - ang) < 3]
    if nearby:
        best = max(nearby, key=lambda x: x[1])
        print(f"//   {ang:3d}°: R={best[1]:.2f}")
