"""Exact measurements of planetary_2.stl for faithful reproduction."""
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

# === Z levels ===
z_vals = sorted(set(round(v[2], 2) for v in vertices))
print(f"Z levels: {z_vals}")

# === Hub tube measurements ===
# At Z=-10 (pure tube zone), find OD and ID
tube_verts = [v for v in vertices if abs(v[2] - (-10)) < 2]
tube_r = [math.sqrt(v[0]**2 + v[1]**2) for v in tube_verts]
print(f"\nHub tube (Z≈-10): R_min={min(tube_r):.2f}, R_max={max(tube_r):.2f}")
print(f"  → OD={max(tube_r)*2:.2f}, ID={min(tube_r)*2:.2f}")

# At Z=-19.5 (near bottom)
bot_verts = [v for v in vertices if abs(v[2] - (-19.5)) < 0.5]
bot_r = [math.sqrt(v[0]**2 + v[1]**2) for v in bot_verts]
print(f"Hub tube (Z≈-19.5): R_min={min(bot_r):.2f}, R_max={max(bot_r):.2f}")

# Bottom cap
cap_verts = [v for v in vertices if abs(v[2] - (-21.5)) < 0.5]
cap_r = [math.sqrt(v[0]**2 + v[1]**2) for v in cap_verts]
print(f"Bottom cap (Z≈-21.5): R_min={min(cap_r):.2f}, R_max={max(cap_r):.2f}")

# === Plate thickness ===
# Top face at Z=-1.5, bottom of plate features at Z=-3.5
top_verts = [v for v in vertices if abs(v[2] - (-1.5)) < 0.1]
plate_bot_verts = [v for v in vertices if abs(v[2] - (-3.5)) < 0.1]
print(f"\nPlate top Z=-1.5: {len(top_verts)} verts")
print(f"Plate bot Z=-3.5: {len(plate_bot_verts)} verts")
print(f"Plate thickness: {-1.5 - (-3.5):.1f}mm")

# === Pin holes — find circular features ===
# Look for vertices forming circles at known orbits
# PO pins at R≈31.5, PI pins at R≈29.5
# Find pin center and diameter by looking at vertices near those radii

# Group vertices by proximity to pin orbit radii at plate level
for orbit_name, orbit_r, offset_ang in [("PO", 31.5, 0), ("PI", 29.5, 60)]:
    print(f"\n=== {orbit_name} pins (orbit R≈{orbit_r}) ===")
    for pin_idx in range(3):
        pin_ang = pin_idx * 120 + offset_ang
        pin_cx = orbit_r * math.cos(math.radians(pin_ang))
        pin_cy = orbit_r * math.sin(math.radians(pin_ang))

        # Find vertices near this pin center (within 5mm), at plate Z
        nearby = [v for v in vertices
                  if abs(v[2] - (-1.5)) < 0.5 or abs(v[2] - (-3.5)) < 0.5
                  if math.sqrt((v[0]-pin_cx)**2 + (v[1]-pin_cy)**2) < 8]

        if nearby:
            # Compute distances from estimated center
            dists = [math.sqrt((v[0]-pin_cx)**2 + (v[1]-pin_cy)**2) for v in nearby]
            # Pin hole vertices should cluster at the hole radius
            # Find the actual center by looking at inner ring of vertices
            inner = [(v, d) for v, d in zip(nearby, dists) if d < 5]
            if inner:
                inner_r = [d for _, d in inner]
                # The pin hole radius is approximately the min distance cluster
                # Actually, find vertices that form the circle
                hole_verts = [(v, d) for v, d in zip(nearby, dists) if 1.5 < d < 4.5]
                if hole_verts:
                    hole_r_vals = [d for _, d in hole_verts]
                    avg_r = sum(hole_r_vals) / len(hole_r_vals)
                    print(f"  Pin at {pin_ang}°: hole R≈{avg_r:.2f} → D≈{avg_r*2:.2f} ({len(hole_verts)} verts)")

                    # Check Z range of pin hole
                    pin_z = [v[2] for v, _ in hole_verts]
                    print(f"    Z range: [{min(pin_z):.2f}, {max(pin_z):.2f}]")

# === Plate OD ===
plate_verts_top = [v for v in vertices if abs(v[2] - (-1.5)) < 0.1]
max_r = max(math.sqrt(v[0]**2 + v[1]**2) for v in plate_verts_top)
print(f"\nPlate OD (top face): {max_r*2:.2f}mm")

# === Web/arm width measurement ===
# At the narrow point between windows, measure arm width
# Arms are at 0°, 120°, 240° — measure width perpendicular to arm direction
print("\n=== Arm widths (at PO orbit radius) ===")
for arm_ang in [0, 120, 240]:
    # Collect plate vertices near this angle, at PO orbit radius
    arm_verts = [v for v in plate_verts_top
                 if abs(math.sqrt(v[0]**2 + v[1]**2) - 31.5) < 3
                 if abs((math.degrees(math.atan2(v[1], v[0])) % 360) - arm_ang) < 15
                 or abs((math.degrees(math.atan2(v[1], v[0])) % 360) - arm_ang + 360) < 15]
    if arm_verts:
        # Angular spread
        angs = [(math.degrees(math.atan2(v[1], v[0])) % 360) for v in arm_verts]
        spread = max(angs) - min(angs)
        if spread > 180:
            angs = [a - 360 if a > 180 else a for a in angs]
            spread = max(angs) - min(angs)
        arc_width = spread * math.pi / 180 * 31.5  # arc length at orbit
        print(f"  Arm at {arm_ang}°: angular spread={spread:.1f}°, arc width≈{arc_width:.1f}mm")

# === Hub tube wall details at transition zone ===
print("\n=== Transition zone Z=-3.5 to Z=-6.5 ===")
for z in [-3.5, -6.5]:
    verts_z = [v for v in vertices if abs(v[2] - z) < 0.1]
    if verts_z:
        r_vals = [math.sqrt(v[0]**2 + v[1]**2) for v in verts_z]
        print(f"  Z={z}: R_min={min(r_vals):.2f}, R_max={max(r_vals):.2f}, n={len(verts_z)}")
