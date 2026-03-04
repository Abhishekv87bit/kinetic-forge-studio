"""Comprehensive measurement of planetary_2.stl AND neighboring components.
Measures how they mesh together to ensure parametric carrier_2 fits correctly."""
import struct
import math
from collections import defaultdict

STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/"

def read_stl_vertices(path):
    with open(path, 'rb') as f:
        header = f.read(80)
        num_tri = struct.unpack('<I', f.read(4))[0]
        verts = []
        for _ in range(num_tri):
            f.read(12)  # normal
            v1 = struct.unpack('<3f', f.read(12))
            v2 = struct.unpack('<3f', f.read(12))
            v3 = struct.unpack('<3f', f.read(12))
            f.read(2)   # attr
            verts.extend([v1, v2, v3])
    return verts

def bbox(verts):
    xs = [v[0] for v in verts]
    ys = [v[1] for v in verts]
    zs = [v[2] for v in verts]
    return {
        'x': (min(xs), max(xs)),
        'y': (min(ys), max(ys)),
        'z': (min(zs), max(zs)),
        'center_xy': ((min(xs)+max(xs))/2, (min(ys)+max(ys))/2),
    }

def z_levels(verts, tol=0.3):
    """Find distinct Z levels by clustering."""
    zs = sorted(set(round(v[2], 2) for v in verts))
    levels = []
    for z in zs:
        if not levels or abs(z - levels[-1]) > tol:
            levels.append(z)
    return levels

def r_range_at_z(verts, z_target, tol=0.5):
    """R min/max at a given Z level."""
    near = [v for v in verts if abs(v[2] - z_target) < tol]
    if not near:
        return None, None
    rs = [math.sqrt(v[0]**2 + v[1]**2) for v in near]
    return min(rs), max(rs)

print("=" * 60)
print("CARRIER_2 (planetary_2.stl) DETAILED MEASUREMENTS")
print("=" * 60)

car2 = read_stl_vertices(STL_DIR + "planetary_2.stl")
bb = bbox(car2)
print(f"Bounding box X: {bb['x'][0]:.2f} to {bb['x'][1]:.2f}")
print(f"Bounding box Y: {bb['y'][0]:.2f} to {bb['y'][1]:.2f}")
print(f"Bounding box Z: {bb['z'][0]:.2f} to {bb['z'][1]:.2f}")
print(f"Center XY: {bb['center_xy']}")

zl = z_levels(car2)
print(f"\nZ levels: {zl}")

for z in zl:
    rmin, rmax = r_range_at_z(car2, z)
    print(f"  Z={z:7.2f}: R_min={rmin:.2f}, R_max={rmax:.2f}, OD={rmax*2:.2f}, ID={rmin*2:.2f}")

# Pin hole analysis at plate level
print("\n--- Pin Hole Analysis ---")
plate_verts = [v for v in car2 if abs(v[2] - (-1.5)) < 0.5 or abs(v[2] - (-3.5)) < 0.5]

for orbit_name, orbit_r, ang_offset in [("PO", 31.5, 0), ("PI", 29.5, 60)]:
    print(f"\n{orbit_name} pins (orbit R={orbit_r}):")
    for pin_idx in range(3):
        pin_ang = pin_idx * 120 + ang_offset
        pin_cx = orbit_r * math.cos(math.radians(pin_ang))
        pin_cy = orbit_r * math.sin(math.radians(pin_ang))
        nearby = [v for v in plate_verts
                  if math.sqrt((v[0]-pin_cx)**2 + (v[1]-pin_cy)**2) < 8]
        if nearby:
            # Find the hole edge vertices
            dists = [math.sqrt((v[0]-pin_cx)**2 + (v[1]-pin_cy)**2) for v in nearby]
            hole_verts = [(v, d) for v, d in zip(nearby, dists) if 1.5 < d < 5]
            if hole_verts:
                hole_r = [d for _, d in hole_verts]
                avg_r = sum(hole_r) / len(hole_r)
                print(f"  {pin_ang}deg: hole D~{avg_r*2:.2f}mm (R~{avg_r:.2f}, {len(hole_verts)} verts)")

# Hub bore details
print("\n--- Hub Bore Through-bore ---")
for z in zl:
    near = [v for v in car2 if abs(v[2] - z) < 0.5]
    rs = [math.sqrt(v[0]**2 + v[1]**2) for v in near]
    # Innermost vertices form the bore
    inner_rs = sorted(rs)[:max(10, len(rs)//10)]
    if inner_rs:
        print(f"  Z={z:.1f}: bore R_min={min(inner_rs):.3f} (D={min(inner_rs)*2:.3f})")

# Hub tube wall
print("\n--- Hub Tube Wall Thickness ---")
for z in [-6.5, -10, -15, -19.5]:
    rmin, rmax = r_range_at_z(car2, z, tol=1.0)
    if rmin and rmax:
        print(f"  Z~{z}: wall = {rmax - rmin:.2f}mm (R={rmin:.2f} to {rmax:.2f})")

# Bottom cap detail
print("\n--- Bottom Cap (Z=-19.5 to -21.5) ---")
for z in [-19.5, -20.0, -20.5, -21.0, -21.5]:
    near = [v for v in car2 if abs(v[2] - z) < 0.3]
    if near:
        rs = [math.sqrt(v[0]**2 + v[1]**2) for v in near]
        print(f"  Z={z:.1f}: R_min={min(rs):.2f}, R_max={max(rs):.2f}, n={len(near)}")


print("\n" + "=" * 60)
print("NEIGHBORING COMPONENT MEASUREMENTS")
print("=" * 60)

# === LONG PINION (Po) ===
print("\n--- LONG PINION (long_pinion.stl) ---")
po = read_stl_vertices(STL_DIR + "long_pinion.stl")
bb_po = bbox(po)
print(f"Bbox Z: {bb_po['z'][0]:.2f} to {bb_po['z'][1]:.2f}")
print(f"Bbox X: {bb_po['x'][0]:.2f} to {bb_po['x'][1]:.2f}")
print(f"Bbox Y: {bb_po['y'][0]:.2f} to {bb_po['y'][1]:.2f}")
print(f"Center XY: ({bb_po['center_xy'][0]:.2f}, {bb_po['center_xy'][1]:.2f})")

# Po pin at center
cx, cy = bb_po['center_xy']
print(f"Pin orbit radius: {math.sqrt(cx**2 + cy**2):.2f}")

# Z levels of Po
po_zl = z_levels(po)
print(f"Z levels (count): {len(po_zl)}, range: {po_zl[0]:.2f} to {po_zl[-1]:.2f}")

# At bottom face, check for pin stub
bot_verts = [v for v in po if abs(v[2] - bb_po['z'][0]) < 0.5]
if bot_verts:
    rs = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v in bot_verts]
    print(f"Bottom face (Z~{bb_po['z'][0]:.1f}): R_min={min(rs):.2f}, R_max={max(rs):.2f}")
    # Pin stub
    inner = [r for r in rs if r < 5]
    if inner:
        print(f"  Pin stub: D~{max(inner)*2:.2f}")

# At top face
top_verts = [v for v in po if abs(v[2] - bb_po['z'][1]) < 0.5]
if top_verts:
    rs = [math.sqrt((v[0]-cx)**2 + (v[1]-cy)**2) for v in top_verts]
    print(f"Top face (Z~{bb_po['z'][1]:.1f}): R_min={min(rs):.2f}, R_max={max(rs):.2f}")

# === SHORT PINION (Pi) ===
print("\n--- SHORT PINION (short_pinion.stl) ---")
pi_v = read_stl_vertices(STL_DIR + "short_pinion.stl")
bb_pi = bbox(pi_v)
print(f"Bbox Z: {bb_pi['z'][0]:.2f} to {bb_pi['z'][1]:.2f}")
print(f"Center XY: ({bb_pi['center_xy'][0]:.2f}, {bb_pi['center_xy'][1]:.2f})")
print(f"Pin orbit radius: {math.sqrt(bb_pi['center_xy'][0]**2 + bb_pi['center_xy'][1]**2):.2f}")

# === CARRIER_1 (planetary_1.stl) ===
print("\n--- CARRIER_1 (planetary_1.stl) ---")
car1 = read_stl_vertices(STL_DIR + "planetary_1.stl")
bb_c1 = bbox(car1)
print(f"Bbox Z: {bb_c1['z'][0]:.2f} to {bb_c1['z'][1]:.2f}")
print(f"Bbox X: {bb_c1['x'][0]:.2f} to {bb_c1['x'][1]:.2f}")
print(f"Center XY: ({bb_c1['center_xy'][0]:.2f}, {bb_c1['center_xy'][1]:.2f})")

c1_zl = z_levels(car1)
print(f"Z levels (count): {len(c1_zl)}")
# Bottom face — where it meets carrier_2 top
for z in [c1_zl[0], c1_zl[1] if len(c1_zl)>1 else c1_zl[0]]:
    rmin, rmax = r_range_at_z(car1, z)
    if rmin:
        print(f"  Z={z:.2f}: R_min={rmin:.2f}, R_max={rmax:.2f}")

# Pin holes in carrier_1 bottom plate
print("  Carrier_1 pin holes (at bottom):")
c1_bot_verts = [v for v in car1 if abs(v[2] - bb_c1['z'][0]) < 2]
for orbit_name, orbit_r, ang_offset in [("PO", 31.5, 0), ("PI", 29.5, 60)]:
    for pin_idx in range(3):
        pin_ang = pin_idx * 120 + ang_offset
        pin_cx = orbit_r * math.cos(math.radians(pin_ang))
        pin_cy = orbit_r * math.sin(math.radians(pin_ang))
        nearby = [v for v in c1_bot_verts
                  if math.sqrt((v[0]-pin_cx)**2 + (v[1]-pin_cy)**2) < 8]
        if nearby:
            dists = [math.sqrt((v[0]-pin_cx)**2 + (v[1]-pin_cy)**2) for v in nearby]
            hole = [d for d in dists if 1.5 < d < 5]
            if hole:
                avg = sum(hole)/len(hole)
                print(f"    {orbit_name} at {pin_ang}deg: hole D~{avg*2:.2f}")

# === CARRIER_3 (planetary_3.stl) ===
print("\n--- CARRIER_3 (planetary_3.stl) ---")
car3 = read_stl_vertices(STL_DIR + "planetary_3.stl")
bb_c3 = bbox(car3)
print(f"Bbox Z: {bb_c3['z'][0]:.2f} to {bb_c3['z'][1]:.2f}")
print(f"Center XY: ({bb_c3['center_xy'][0]:.2f}, {bb_c3['center_xy'][1]:.2f})")
print(f"Pin orbit radius: {math.sqrt(bb_c3['center_xy'][0]**2 + bb_c3['center_xy'][1]**2):.2f}")

# === RING ===
print("\n--- RING (ring_low_profile.stl) ---")
ring = read_stl_vertices(STL_DIR + "ring_low_profile.stl")
bb_ring = bbox(ring)
print(f"Bbox Z: {bb_ring['z'][0]:.2f} to {bb_ring['z'][1]:.2f}")
print(f"Bbox X: {bb_ring['x'][0]:.2f} to {bb_ring['x'][1]:.2f}")

# === BIG SUN ===
print("\n--- BIG SUN (big_sun_0_5_backlash.stl) ---")
sl = read_stl_vertices(STL_DIR + "big_sun_0_5_backlash.stl")
bb_sl = bbox(sl)
print(f"Bbox Z: {bb_sl['z'][0]:.2f} to {bb_sl['z'][1]:.2f}")
print(f"Bbox X: {bb_sl['x'][0]:.2f} to {bb_sl['x'][1]:.2f}")

# Z where big_sun bottom meets carrier_2
for z in [-38, -35, -30, -25]:
    rmin, rmax = r_range_at_z(sl, z, tol=1)
    if rmin:
        print(f"  Z~{z}: R_min={rmin:.2f}, R_max={rmax:.2f}")

# === SMALL SUN ===
print("\n--- SMALL SUN (small_sun.stl) ---")
ss = read_stl_vertices(STL_DIR + "small_sun.stl")
bb_ss = bbox(ss)
print(f"Bbox Z: {bb_ss['z'][0]:.2f} to {bb_ss['z'][1]:.2f}")
print(f"Bbox X: {bb_ss['x'][0]:.2f} to {bb_ss['x'][1]:.2f}")

# === SHAFT ===
print("\n--- SHAFT (shaft.stl) ---")
shaft = read_stl_vertices(STL_DIR + "shaft.stl")
bb_shaft = bbox(shaft)
print(f"Bbox Z: {bb_shaft['z'][0]:.2f} to {bb_shaft['z'][1]:.2f}")
print(f"Shaft D: {bb_shaft['x'][1] - bb_shaft['x'][0]:.2f}")

# === KEY INTERFACE ANALYSIS ===
print("\n" + "=" * 60)
print("KEY INTERFACES — How carrier_2 meshes with neighbors")
print("=" * 60)

print("\n1. CARRIER_2 TOP FACE vs PINION BOTTOM FACES:")
print(f"   Carrier_2 plate top:   Z = {-1.5}")
print(f"   Long pinion (Po) bot:  Z = {bb_po['z'][0]:.2f}")
print(f"   Short pinion (Pi) bot: Z = {bb_pi['z'][0]:.2f}")
print(f"   --> Gap C2_top to Po_bot: {bb_po['z'][0] - (-1.5):.2f}mm")
print(f"   --> Gap C2_top to Pi_bot: {bb_pi['z'][0] - (-1.5):.2f}mm")

print("\n2. CARRIER_2 vs BIG SUN (SL):")
print(f"   Carrier_2 hub bore ID: {27.25:.2f}mm")
print(f"   Big sun OD at Z=-1.5:")
rmin, rmax = r_range_at_z(sl, -1.5, tol=1)
if rmin:
    print(f"     R_min={rmin:.2f}, R_max={rmax:.2f}, OD={rmax*2:.2f}")
print(f"   Big sun tube bottom: Z={bb_sl['z'][0]:.2f}")
print(f"   Carrier_2 hub bottom: Z=-21.5")

print("\n3. CARRIER_2 HUB vs BIG SUN TUBE (concentric clearance):")
for z in [-5, -10, -15, -20]:
    sl_rmin, sl_rmax = r_range_at_z(sl, z, tol=1)
    c2_rmin, c2_rmax = r_range_at_z(car2, z, tol=1)
    if sl_rmax and c2_rmin:
        clearance = c2_rmin - sl_rmax
        print(f"   Z~{z}: SL_OD={sl_rmax*2:.1f}, C2_ID={c2_rmin*2:.1f}, clearance={clearance:.2f}")

print("\n4. GEAR ZONE alignment:")
print(f"   Gear zone: Z={0} to Z={22}")
print(f"   Carrier_2 plate: Z={-1.5} to Z={-3.5}")
print(f"   --> Carrier_2 plate sits {0 - (-1.5):.1f}mm BELOW gear zone bottom")
print(f"   Carrier_1 (top carrier) plate bottom: Z~{bb_c1['z'][0]:.2f}")
print(f"   --> Carriers bracket the gear zone")

print("\n5. PIN POSITIONS (carrier_2 pins must align with pinion centers):")
po_cx, po_cy = bb_po['center_xy']
po_orbit = math.sqrt(po_cx**2 + po_cy**2)
po_ang = math.degrees(math.atan2(po_cy, po_cx))
print(f"   Po STL center: ({po_cx:.2f}, {po_cy:.2f})")
print(f"   Po orbit R: {po_orbit:.2f}, angle: {po_ang:.1f} deg")

pi_cx, pi_cy = bb_pi['center_xy']
pi_orbit = math.sqrt(pi_cx**2 + pi_cy**2)
pi_ang = math.degrees(math.atan2(pi_cy, pi_cx))
print(f"   Pi STL center: ({pi_cx:.2f}, {pi_cy:.2f})")
print(f"   Pi orbit R: {pi_orbit:.2f}, angle: {pi_ang:.1f} deg")

print(f"\n   Code uses PO_ORBIT={31.5}, PI_ORBIT={29.5}")
print(f"   STL shows Po at R={po_orbit:.2f}, Pi at R={pi_orbit:.2f}")
