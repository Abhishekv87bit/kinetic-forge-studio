"""Determine exactly what clearance carrier_3 boss needs through carrier_2.

Key question: The carrier_3 boss at the PO position has OD~18.3mm but
carrier_2 PO holes are only D=8mm. How does this work in the original design?

Answer: The boss sits in the GAP between carrier_2 arms, not through the holes.
But we need to verify this and determine if any modifications are needed.
"""
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

# === CARRIER_3 at PO position ===
# Carrier_3 has a boss around the PO pin. Let's get its exact footprint.
# PO pin center in assembly: (31.4, 0)
# Carrier_3 bottom face is at Z=-5.5, top of boss area at Z=-3.5

print("=== CARRIER_3 BOSS AT PO PIN (31.4, 0) ===")
# Get all car3 verts near the PO pin at the bottom face
po_cx, po_cy = 31.4, 0.0
car3_at_po = [v for v in car3 if math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) < 15]

if car3_at_po:
    # Bottom face (Z=-5.5): this is the boss that extends BELOW carrier_2
    bot = [v for v in car3_at_po if abs(v[2] - (-5.5)) < 0.3]
    top = [v for v in car3_at_po if abs(v[2] - (-3.5)) < 0.3]

    print(f"\nBoss bottom (Z=-5.5): {len(bot)} verts")
    if bot:
        rs_bot = [math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) for v in bot]
        print(f"  R from Po center: min={min(rs_bot):.2f}, max={max(rs_bot):.2f}")
        print(f"  Boss ID={min(rs_bot)*2:.1f}, OD={max(rs_bot)*2:.1f}")
        # Get XY bounding box
        bxs = [v[0] for v in bot]
        bys = [v[1] for v in bot]
        print(f"  X: [{min(bxs):.1f}, {max(bxs):.1f}]")
        print(f"  Y: [{min(bys):.1f}, {max(bys):.1f}]")

    print(f"\nBoss top (Z=-3.5): {len(top)} verts")
    if top:
        rs_top = [math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) for v in top]
        print(f"  R from Po center: min={min(rs_top):.2f}, max={max(rs_top):.2f}")
        print(f"  Boss ID={min(rs_top)*2:.1f}, OD={max(rs_top)*2:.1f}")

# === CARRIER_2 profile at the boss location ===
# The carrier_2 plate is at Z=-1.5 to -3.5
# The boss is at Z=-3.5 to -5.5 (just below the plate)
# The boss at Z=-3.5 overlaps with carrier_2 plate bottom face

print("\n\n=== CARRIER_2 PLATE NEAR PO PIN ===")
car2_plate = [v for v in car2 if abs(v[2] - (-1.5)) < 0.3 or abs(v[2] - (-3.5)) < 0.3]
car2_near_po = [v for v in car2_plate if math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) < 15]

print(f"Carrier_2 plate verts near PO: {len(car2_near_po)}")
if car2_near_po:
    # What's the carrier_2 profile in the boss overlap zone?
    # Convert to polar from PO center
    for z_face in [-1.5, -3.5]:
        face = [v for v in car2_near_po if abs(v[2] - z_face) < 0.3]
        if face:
            rs = [math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) for v in face]
            angs = [math.degrees(math.atan2(v[1]-po_cy, v[0]-po_cx)) for v in face]
            print(f"\n  Z={z_face}: {len(face)} verts")
            print(f"    R from Po: [{min(rs):.1f}, {max(rs):.1f}]")
            print(f"    Angles: [{min(angs):.1f}, {max(angs):.1f}]")

            # The pin hole edge should be at R~4 from Po center
            hole_edge = [v for v in face if math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) < 5]
            if hole_edge:
                hrs = [math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) for v in hole_edge]
                print(f"    Hole edge (R<5): n={len(hole_edge)}, R=[{min(hrs):.2f}, {max(hrs):.2f}]")
                print(f"    -> Hole D = {(min(hrs)+max(hrs)):.1f}mm")

# === COLLISION CHECK ===
# Does the carrier_3 boss at Z=-3.5 to -5.5 collide with carrier_2?
# Carrier_2 plate bottom is at Z=-3.5
# So at Z=-3.5: both carrier_2 and carrier_3 exist
# carrier_3 boss footprint must NOT overlap with carrier_2 solid material

print("\n\n=== COLLISION CHECK AT Z=-3.5 ===")
# Carrier_3 boss footprint (XY positions at Z=-3.5)
car3_z35 = [v for v in car3 if abs(v[2] - (-3.5)) < 0.3]
car2_z35 = [v for v in car2 if abs(v[2] - (-3.5)) < 0.3]

# For each carrier_3 boss vertex, find nearest carrier_2 vertex
# If carrier_3 vertex is INSIDE carrier_2 plate material, that's a collision
print(f"Carrier_3 at Z=-3.5: {len(car3_z35)} verts")
print(f"Carrier_2 at Z=-3.5: {len(car2_z35)} verts")

# Simplify: check if carrier_3 boss angular extent overlaps with carrier_2 arms
# Carrier_2 arms are at ~0 deg (PO), ~71.5 deg (PI), etc.
# Carrier_3 boss is centered on the PO pin at (31.4, 0)

# Boss angular extent from assembly center
if car3_at_po:
    boss_z35 = [v for v in car3_at_po if abs(v[2] - (-3.5)) < 0.3]
    if boss_z35:
        boss_angs = [math.degrees(math.atan2(v[1], v[0])) for v in boss_z35]
        boss_rs = [math.sqrt(v[0]**2 + v[1]**2) for v in boss_z35]
        print(f"\nBoss at Z=-3.5:")
        print(f"  Angular span from origin: [{min(boss_angs):.1f}, {max(boss_angs):.1f}] deg")
        print(f"  R from origin: [{min(boss_rs):.1f}, {max(boss_rs):.1f}]")

        # Carrier_2 arm material in this angular range
        arm_in_range = [v for v in car2_z35
                       if min(boss_angs)-5 < math.degrees(math.atan2(v[1], v[0])) < max(boss_angs)+5
                       and min(boss_rs)-3 < math.sqrt(v[0]**2 + v[1]**2) < max(boss_rs)+3]
        print(f"  Carrier_2 verts in boss zone: {len(arm_in_range)}")

        if arm_in_range:
            arm_rs = [math.sqrt(v[0]**2 + v[1]**2) for v in arm_in_range]
            arm_angs = [math.degrees(math.atan2(v[1], v[0])) for v in arm_in_range]
            print(f"  Carrier_2 arm R: [{min(arm_rs):.1f}, {max(arm_rs):.1f}]")
            print(f"  Carrier_2 arm angles: [{min(arm_angs):.1f}, {max(arm_angs):.1f}]")

# === WHAT THE ORIGINAL DESIGN DOES ===
# In the original Fusion 360 design, carrier_3 boss goes through carrier_2
# The question is: does it go through the PO hole, or through the notch gap?

print("\n\n=== ORIGINAL DESIGN ANALYSIS ===")
print("PO hole in carrier_2: D=8mm at R=31.4, angle=0 deg")
print("Carrier_3 boss at PO:")
if car3_at_po:
    bot_verts = [v for v in car3_at_po if v[2] < -3]
    if bot_verts:
        rs = [math.sqrt((v[0]-po_cx)**2 + (v[1]-po_cy)**2) for v in bot_verts]
        r_min = min(rs)
        r_max = max(rs)
        print(f"  Boss R from PO center: {r_min:.2f} to {r_max:.2f}")
        print(f"  Boss inner D: {r_min*2:.1f}mm (this is the bore/pin hole)")
        print(f"  Boss outer D: {r_max*2:.1f}mm")
        print(f"  Carrier_2 PO hole: D=8mm")
        print(f"  Boss bore D: {r_min*2:.1f}mm")

        if r_max * 2 > 8:
            print(f"\n  ** Boss OD ({r_max*2:.1f}) > PO hole D (8mm) **")
            print(f"  The boss CANNOT fit through the 8mm PO hole!")
            print(f"  It must pass through the notch gap between arms,")
            print(f"  or the PO hole needs to be enlarged to D>={r_max*2:.0f}mm")
            print(f"  Recommended: PO hole D = {math.ceil(r_max*2 + 1)}mm (boss OD + 1mm clearance)")
