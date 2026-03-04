"""Symmetric star v7 — symmetrize the ORIGINAL STL profile.

Instead of generating a new profile from scratch, take the original
STL-traced profile, extract one 120-deg sector, and symmetrize it
by averaging the R(angle) with R(71.5-angle) mirrored about the
arm's midline. Then replicate 3x.

This preserves the original arm shape character while making all
3 arms identical.
"""
import math

# Original STL-traced profile points (from ravigneaux_hybrid.scad)
ORIG_PTS = [
    (  40.00,    0.00), (  39.98,    1.40), (  39.90,    2.79),
    (  39.78,    4.18), (  39.61,    5.57), (  39.39,    6.95),
    (  38.82,    8.25), (  38.20,    9.52), (  36.92,   10.59),
    (  35.00,   11.37), (  33.07,   12.04), (  25.70,   10.38),
    (  18.49,    8.23), (  14.83,    7.23), (  14.57,    7.75),
    (  14.29,    8.25), (  13.99,    8.74), (  13.68,    9.23),
    (  13.35,    9.70), (  13.00,   10.16), (  12.64,   10.61),
    (  12.26,   11.04), (  11.87,   11.46), (  13.55,   14.03),
    (  17.08,   18.97), (  20.27,   24.16), (  20.16,   25.81),
    (  19.96,   27.48), (  19.58,   29.02), (  19.02,   30.43),
    (  18.38,   31.84), (  17.43,   32.78), (  16.44,   33.70),
    (  15.37,   34.52), (  14.23,   35.22), (  13.06,   35.89),
    (  11.79,   36.29), (  10.51,   36.66), (   9.20,   36.89),
    (   7.87,   37.01), (   6.54,   37.07), (   5.15,   36.65),
    (   3.80,   36.18), (   2.48,   35.48), (   1.21,   34.54),
    (   0.00,   33.56), (  -1.14,   32.69), (  -2.22,   31.79),
    (  -3.36,   32.01), (  -4.69,   33.34), (  -6.10,   34.62),
    (  -7.64,   35.97), (  -9.29,   37.25), ( -10.85,   37.84),
    ( -12.26,   37.74), ( -13.68,   37.59), ( -14.98,   37.09),
    ( -16.27,   36.54), ( -17.53,   35.95), ( -18.78,   35.32),
    ( -20.00,   34.64), ( -21.20,   33.92), ( -22.37,   33.16),
    ( -23.51,   32.36), ( -24.63,   31.52), ( -25.71,   30.64),
    ( -26.55,   29.49), ( -27.35,   28.32), ( -27.63,   26.68),
    ( -27.35,   24.62), ( -26.96,   22.62), ( -21.84,   17.06),
    ( -16.37,   11.90), ( -13.68,    9.23), ( -13.99,    8.74),
    ( -14.29,    8.25), ( -14.57,    7.75), ( -14.83,    7.23),
    ( -15.07,    6.71), ( -15.30,    6.18), ( -15.50,    5.64),
    ( -15.69,    5.10), ( -15.86,    4.55), ( -18.93,    4.72),
    ( -24.97,    5.31), ( -31.06,    5.48), ( -32.43,    4.56),
    ( -33.78,    3.55), ( -34.92,    2.44), ( -35.86,    1.25),
    ( -36.76,    0.00), ( -37.11,   -1.30), ( -37.40,   -2.62),
    ( -37.58,   -3.95), ( -37.62,   -5.29), ( -37.61,   -6.63),
    ( -37.33,   -7.93), ( -37.00,   -9.23), ( -36.55,  -10.48),
    ( -35.98,  -11.69), ( -35.37,  -12.87), ( -34.32,  -13.86),
    ( -33.24,  -14.80), ( -31.97,  -15.59), ( -30.52,  -16.23),
    ( -29.06,  -16.78), ( -27.74,  -17.33), ( -26.42,  -17.82),
    ( -26.04,  -18.92), ( -26.53,  -20.73), ( -26.93,  -22.59),
    ( -27.33,  -24.60), ( -27.62,  -26.67), ( -27.34,  -28.31),
    ( -26.55,  -29.49), ( -25.71,  -30.64), ( -24.63,  -31.52),
    ( -23.51,  -32.36), ( -22.37,  -33.16), ( -21.20,  -33.92),
    ( -20.00,  -34.64), ( -18.78,  -35.32), ( -17.53,  -35.95),
    ( -16.27,  -36.54), ( -14.98,  -37.09), ( -13.68,  -37.59),
    ( -12.26,  -37.74), ( -10.85,  -37.84), (  -9.29,  -37.27),
    (  -7.65,  -35.99), (  -6.11,  -34.66), (  -3.86,  -27.44),
    (  -2.12,  -20.13), (  -1.15,  -16.46), (  -0.58,  -16.49),
    (  -0.00,  -16.50), (   0.58,  -16.49), (   1.15,  -16.46),
    (   1.72,  -16.41), (   2.30,  -16.34), (   2.87,  -16.25),
    (   3.43,  -16.14), (   3.99,  -16.01), (   5.38,  -18.75),
    (   7.89,  -24.27), (  10.79,  -29.64), (  12.27,  -30.37),
    (  13.81,  -31.03), (  15.35,  -31.46), (  16.85,  -31.68),
    (  18.38,  -31.84), (  19.67,  -31.49), (  20.97,  -31.09),
    (  22.21,  -30.57), (  23.39,  -29.93), (  24.55,  -29.26),
    (  25.54,  -28.36), (  26.49,  -27.43), (  27.35,  -26.41),
    (  28.11,  -25.31), (  28.83,  -24.19), (  29.17,  -22.79),
    (  29.44,  -21.39), (  29.49,  -19.89), (  29.31,  -18.32),
    (  29.06,  -16.78), (  28.88,  -15.36), (  28.64,  -13.97),
    (  29.40,  -13.09), (  31.21,  -12.61), (  33.03,  -12.02),
    (  34.97,  -11.36), (  36.90,  -10.58), (  38.19,   -9.52),
    (  38.81,   -8.25), (  39.39,   -6.95), (  39.61,   -5.57),
    (  39.78,   -4.18), (  39.90,   -2.79), (  39.98,   -1.40),
]

# Convert original to polar R(angle)
orig_polar = []
for x, y in ORIG_PTS:
    r = math.sqrt(x**2 + y**2)
    a = math.degrees(math.atan2(y, x)) % 360
    orig_polar.append((a, r))

# Sort by angle
orig_polar.sort(key=lambda p: p[0])

# Build R(angle) lookup by interpolation
def interp_r(angle, polar_data):
    """Interpolate R at any angle from sorted polar data."""
    angle = angle % 360
    n = len(polar_data)
    for i in range(n):
        a0, r0 = polar_data[i]
        a1, r1 = polar_data[(i+1) % n]
        if a1 < a0:  # wrap around 360
            a1 += 360
        if a0 <= angle <= a1 or (a0 <= angle + 360 <= a1):
            t = (angle - a0) / (a1 - a0) if a1 != a0 else 0
            return r0 + (r1 - r0) * t
        if a0 <= angle + 360 <= a1:
            t = (angle + 360 - a0) / (a1 - a0) if a1 != a0 else 0
            return r0 + (r1 - r0) * t
    # Fallback: closest point
    closest = min(polar_data, key=lambda p: min(abs(p[0] - angle), abs(p[0] - angle - 360), abs(p[0] - angle + 360)))
    return closest[1]

# The original profile has 3 sectors, but they're NOT symmetric.
# Sector 1: 0-120, Sector 2: 120-240, Sector 3: 240-360
# Each sector has a PO tip at the start (0, 120, 240) and PI zone near 71.5+n*120

# Strategy: Extract R(angle) for sector 1 (0-120), then
# create the symmetric version by AVERAGING all 3 sectors.
# Sector 1: angle a → R1(a)
# Sector 2: angle a+120 → R2(a)
# Sector 3: angle a+240 → R3(a)
# Symmetric: R_sym(a) = average(R1(a), R2(a), R3(a))

steps = 60  # per sector
sym_r = []
print("// Symmetrization: averaging 3 original sectors")
for i in range(steps):
    a = i * 120.0 / steps  # 0 to 120

    # Sample from each original sector
    r1 = interp_r(a, orig_polar)          # sector 1
    r2 = interp_r(a + 120, orig_polar)    # sector 2
    r3 = interp_r(a + 240, orig_polar)    # sector 3

    r_avg = (r1 + r2 + r3) / 3.0

    sym_r.append((a, r_avg))
    if i % 10 == 0:
        print(f"//   {a:5.1f}: R1={r1:5.1f} R2={r2:5.1f} R3={r3:5.1f} -> avg={r_avg:5.1f}")

# Generate the symmetric 3-sector polygon
all_pts = []
for sector in range(3):
    for a_local, r in sym_r:
        a_global = a_local + sector * 120
        x = r * math.cos(math.radians(a_global))
        y = r * math.sin(math.radians(a_global))
        all_pts.append((x, y))

print(f"\n// Symmetric 3-arm star carrier plate v7")
print(f"// {len(all_pts)} pts, 3-fold symmetric (averaged from original STL)")
print("CAR_PROFILE_PTS = [")
lines = [f"    [{x:7.2f}, {y:7.2f}]" for x, y in all_pts]
print(",\n".join(lines))
print("];")

# R vs angle
print("\n// R vs angle per sector (symmetrized):")
for a, r in sym_r:
    bar = '#' * int(r / 2)
    mark = ""
    if abs(a) < 1: mark = " <- PO"
    if abs(a - 71.5) < 2: mark = " <- PI zone"
    if abs(a - 90) < 2: mark = " <- notch"
    if abs(a - 120) < 1: mark = " <- next PO"
    print(f"//   {a:5.1f}: R={r:5.1f} {bar}{mark}")
