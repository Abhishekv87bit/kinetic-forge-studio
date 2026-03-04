"""Generate clean OpenSCAD polygon from R(angle) polar profile.
Uses 2° steps, 3-fold symmetry from the R_max table."""
import math

# R_max vs angle at 5° from STL (one period 0-119°)
r_max = {
    0: 40.00, 5: 40.00, 10: 40.00, 15: 39.21, 20: 35.19,
    25: 16.50, 30: 16.50, 35: 16.50, 40: 16.50, 45: 13.62,
    50: 31.54, 55: 34.57, 60: 36.76, 65: 37.68, 70: 38.19,
    75: 38.12, 80: 37.64, 85: 36.07, 90: 33.56, 95: 31.44,
    100: 35.15, 105: 39.20, 110: 40.00, 115: 40.00, 120: 40.00
}

def interp_r(angle_deg):
    """Interpolate R for any angle using 3-fold symmetry."""
    a = angle_deg % 120
    lo = int(a // 5) * 5
    hi = min(lo + 5, 120)
    frac = (a - lo) / 5.0
    r_lo = r_max.get(lo, 16.5)
    r_hi = r_max.get(hi, r_max.get(hi % 120, 40.0))
    return r_lo + frac * (r_hi - r_lo)

# Generate points at 2° increments
points = []
for ang in range(0, 360, 2):
    r = interp_r(ang)
    x = r * math.cos(math.radians(ang))
    y = r * math.sin(math.radians(ang))
    points.append((x, y))

# Output as OpenSCAD function
print("// Carrier plate 2D profile — from STL R(angle) polar data")
print("// 180 points at 2° increments, 3-fold symmetry")
print("CAR_PROFILE_PTS = [")
for i, (x, y) in enumerate(points):
    comma = "," if i < len(points) - 1 else ""
    print(f"    [{x:7.2f}, {y:7.2f}]{comma}")
print("];")
print()
print("module carrier_plate_2d() {")
print("    polygon(CAR_PROFILE_PTS);")
print("}")
