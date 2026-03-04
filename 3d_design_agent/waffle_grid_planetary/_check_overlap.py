"""Check if carrier_3 bosses overlap with carrier_2 plate material.
If carrier_3 has material at angles/radii where carrier_2 also has plate material,
we need clearance holes."""
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
car3 = read_stl_vertices(STL_DIR + "planetary_3.stl")

# Carrier_2 plate profile: build an R(angle) map from top face
plate_top = [v for v in car2 if abs(v[2] - (-1.5)) < 0.2]
# Max R at each angle (1-deg bins)
car2_r_at_angle = {}
for v in plate_top:
    ang = round(math.degrees(math.atan2(v[1], v[0])) % 360)
    r = math.sqrt(v[0]**2 + v[1]**2)
    car2_r_at_angle[ang] = max(car2_r_at_angle.get(ang, 0), r)

print("Carrier_2 plate R(angle) at Z=-1.5 (showing arm/notch structure):")
for ang in range(0, 360, 10):
    r = car2_r_at_angle.get(ang, 0)
    bar = '#' * int(r)
    print(f"  {ang:3d} deg: R={r:5.1f} {bar}")

# Now check carrier_3 at ALL 3 instances (i*120)
# Carrier_3 native position is at angle=-22.9 deg
# In assembly: rotate([0,0, ANG_CARRIER + i*120]) import(car3)
# For overlap check, we check all 3 rotated copies

print("\n=== OVERLAP ANALYSIS ===")
print("Checking if carrier_3 (any of 3 copies) has material where carrier_2 plate exists")

# For each carrier_3 vertex below Z=0, check if it's within carrier_2's plate radius
# at that angle
car3_below = [v for v in car3 if v[2] < 0]

overlaps_per_copy = {}
for copy_idx in range(3):
    rot_deg = copy_idx * 120
    cos_r = math.cos(math.radians(rot_deg))
    sin_r = math.sin(math.radians(rot_deg))

    overlap_verts = []
    for v in car3_below:
        # Rotate vertex
        rx = v[0] * cos_r - v[1] * sin_r
        ry = v[0] * sin_r + v[1] * cos_r

        ang = round(math.degrees(math.atan2(ry, rx)) % 360)
        r = math.sqrt(rx**2 + ry**2)

        # Check if carrier_2 has plate material at this angle
        c2_r = car2_r_at_angle.get(ang, 0)

        # If car3 vertex R is within carrier_2 plate region (between hub and plate edge)
        hub_r = 16.5
        if hub_r < r < c2_r:
            overlap_verts.append((rx, ry, v[2], r, ang))

    overlaps_per_copy[copy_idx] = overlap_verts
    print(f"\nCopy {copy_idx} (rotated {rot_deg} deg):")
    print(f"  Overlapping vertices: {len(overlap_verts)}")
    if overlap_verts:
        # Group by angle to find the boss positions
        angle_groups = {}
        for rx, ry, z, r, ang in overlap_verts:
            a_bin = round(ang / 5) * 5
            if a_bin not in angle_groups:
                angle_groups[a_bin] = []
            angle_groups[a_bin].append((rx, ry, z, r))

        for a_bin in sorted(angle_groups.keys()):
            verts_g = angle_groups[a_bin]
            rs = [v[3] for v in verts_g]
            zs = [v[2] for v in verts_g]
            print(f"    Angle~{a_bin} deg: R={min(rs):.1f}-{max(rs):.1f}, "
                  f"Z={min(zs):.1f}-{max(zs):.1f}, n={len(verts_g)}")

        # Find the main boss centers
        print(f"  Boss positions in assembly frame:")
        # Cluster the overlap vertices
        all_x = [v[0] for v in overlap_verts]
        all_y = [v[1] for v in overlap_verts]
        print(f"    X range: {min(all_x):.1f} to {max(all_x):.1f}")
        print(f"    Y range: {min(all_y):.1f} to {max(all_y):.1f}")
        print(f"    R range: {min(v[3] for v in overlap_verts):.1f} to {max(v[3] for v in overlap_verts):.1f}")
