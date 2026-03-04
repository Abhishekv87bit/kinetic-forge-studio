"""Check if carrier_3 boss fits through carrier_2 notch gap.

The carrier_3 boss at the PO pin is OD=28.4mm. Can it slide through
the notch between carrier_2 arms during assembly?

Actually, rethinking: carrier_3 sits ABOVE carrier_2 (Z > -3.5).
The carrier_3 body is at Z=-5.5 to +10.5. Carrier_2 plate is at Z=-1.5 to -3.5.
In the flipped assembly (rotate 180 around X), carrier_2 plate is at top,
carrier_3 drops down through it.

The boss at Z=-3.5 to -5.5 extends BELOW the carrier_2 plate.
For the boss to exist below the plate, either:
1. Boss fits through the PO hole (NO - boss OD=28.4 >> hole D=8)
2. Boss fits through the notch gap between arms
3. Boss is assembled BEFORE the plate (plate slides over)
4. The original design has relief cuts we're missing

Let's check option 2: does the notch gap at the PO radius allow the boss through?
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

# The carrier_2 plate at Z=-1.5 (top face)
# Check: at R=31.4 (PO orbit), what angular range is solid plate vs gap?
print("=== CARRIER_2 SOLID vs GAP at PO orbit R=31.4 ===")
plate_top = [v for v in car2 if abs(v[2] - (-1.5)) < 0.3]

# Vertices at R close to 31.4 (within 2mm)
at_po_orbit = [(v, math.degrees(math.atan2(v[1], v[0])) % 360)
               for v in plate_top
               if abs(math.sqrt(v[0]**2 + v[1]**2) - 31.4) < 3]

if at_po_orbit:
    angs = sorted(set(round(a, 0) for _, a in at_po_orbit))
    print(f"Plate material at R~31.4: angles (deg) = {angs}")
    print(f"Total angular coverage: {len(angs)} degrees out of 360")

    # Find gaps (consecutive angles with >3 deg gap)
    print("\nGaps in plate at R~31.4:")
    sorted_angs = sorted(angs)
    for i in range(len(sorted_angs)):
        a1 = sorted_angs[i]
        a2 = sorted_angs[(i+1) % len(sorted_angs)]
        if i == len(sorted_angs) - 1:
            gap = (a2 + 360) - a1
        else:
            gap = a2 - a1
        if gap > 3:
            print(f"  Gap from {a1:.0f} to {a2:.0f} deg = {gap:.0f} deg")

# Now check the boss footprint vs the plate footprint
print("\n\n=== BOSS FOOTPRINT vs PLATE FOOTPRINT ===")
# Carrier_3 boss centered at (31.4, 0), OD=28.4
# Boss angular extent from assembly center:
boss_r = 14.22  # max R from PO center

# At assembly center, the boss spans:
# From (31.4-14.22, 0) to (31.4+14.22, 0) in X = (17.18, 45.62)
# Angular span from origin:
boss_ang_min = math.degrees(math.atan2(-boss_r, 31.4))  # ~ -24.4 deg
boss_ang_max = math.degrees(math.atan2(boss_r, 31.4))   # ~ +24.4 deg
print(f"Boss angular span from origin: {boss_ang_min:.1f} to {boss_ang_max:.1f} deg")
print(f"Boss occupies {boss_ang_max - boss_ang_min:.0f} deg of angular space")

# Carrier_2 notch (gap) nearest to PO at 0 deg:
# From original profile: notch is at ~240 deg (sector 3, angles 240±some)
# But for sector 1 arm at 0 deg, the nearest notches are:
#   Before: at ~330-350 deg (between sector 3 PI lobe and sector 1 PO lobe)
#   After: at ~90-110 deg (between sector 1 PI lobe and sector 2 PO lobe)
# The PO arm at 0 deg is SOLID — no notch near it

print("\n\n=== KEY INSIGHT ===")
print("The carrier_3 boss is OD=28.4mm centered on the PO pin.")
print("The carrier_2 arm at 0 deg is solid material spanning ~-20 to +20 deg.")
print("The boss and arm overlap COMPLETELY at the same Z level (Z=-3.5).")
print()
print("This means the original Fusion 360 design has these as MATING parts:")
print("  - The carrier_2 PO hole (D=8) accepts the PO PIN (D~8)")
print("  - The carrier_3 boss is NOT below carrier_2, it's ABOVE it")
print("  - OR: carrier_3 boss passes through from ABOVE, pin goes into hole")
print()

# Let's verify: where is carrier_3 body relative to carrier_2 plate?
print("=== Z OVERLAP VERIFICATION ===")
print(f"Carrier_2 plate: Z=-1.5 (top) to Z=-3.5 (bottom)")
print(f"Carrier_3 full:  Z=-5.5 (bottom) to Z=+10.5 (top)")
print(f"Carrier_3 boss below Z=-3.5: Z=-3.5 to Z=-5.5")
print()

# Actually, the MAIN body of carrier_3 is ABOVE carrier_2 plate (Z>0)
# The boss extends DOWN through the plate
# Let's see what carrier_3 looks like at Z=0 (between plate top and Pi gear bottom)
car3_z0 = [v for v in car3 if abs(v[2]) < 0.5]
print(f"Carrier_3 at Z=0: {len(car3_z0)} verts")
if car3_z0:
    for v in car3_z0[:5]:
        r = math.sqrt(v[0]**2 + v[1]**2)
        a = math.degrees(math.atan2(v[1], v[0]))
        print(f"  ({v[0]:.1f}, {v[1]:.1f}) R={r:.1f} ang={a:.1f}")

# The design is: carrier_3 body spans Z=(-5.5 to 10.5)
# Pi gears are at Z=(12 to 22) — above carrier_3 top
# Po gears are at Z=(0 to 22) — Po gear sits ABOVE carrier_2 plate
# carrier_3 holds the planet pins, its boss goes THROUGH carrier_2
# The pin is integral with carrier_3

# ASSEMBLY ORDER:
# 1. carrier_2 (plate + hub) placed first
# 2. carrier_3 cage drops in from above
# 3. carrier_3 pin passes through carrier_2 PO hole (D=8, pin D~8)
# 4. carrier_3 boss is ABOVE the plate (Z > -1.5), not below!

# Wait - let me re-check. The boss is at Z=-3.5 to -5.5
# But carrier_2 plate bottom is also at Z=-3.5
# So the boss goes BELOW the plate bottom!

# Maybe the boss is actually a different shape at Z=-3.5?
# Let me compare car3 vertices AT Z=-3.5 vs Z=-5.5

print("\n=== CARRIER_3 FOOTPRINT COMPARISON ===")
for zz in [-5.5, -3.5, -1.5, 0, 5, 10]:
    near_z = [v for v in car3 if abs(v[2] - zz) < 0.5]
    if near_z:
        xs = [v[0] for v in near_z]
        ys = [v[1] for v in near_z]
        print(f"  Z={zz:5.1f}: {len(near_z):4d} verts, X=[{min(xs):6.1f},{max(xs):5.1f}] Y=[{min(ys):6.1f},{max(ys):5.1f}]")
    else:
        print(f"  Z={zz:5.1f}: no verts")

# Check if the carrier_2 PO hole in the ORIGINAL STL is actually bigger
# The hole might have been measured wrong
print("\n=== RE-CHECK CARRIER_2 PO HOLE SIZE ===")
# Look at carrier_2 vertices very close to (31.4, 0) at ALL Z levels
for zz in [-1.5, -2.5, -3.5]:
    near_po = [v for v in car2
               if abs(v[2] - zz) < 0.5
               and math.sqrt((v[0]-31.4)**2 + v[1]**2) < 15]
    if near_po:
        ds = sorted([math.sqrt((v[0]-31.4)**2 + v[1]**2) for v in near_po])
        inner = [d for d in ds if d < 6]
        outer = [d for d in ds if d > 6]
        print(f"  Z={zz}: inner R (hole edge) = {inner[:5] if inner else 'none'}")
        if inner:
            print(f"         hole D = {min(inner)*2:.2f} to {max(inner)*2:.2f}")
