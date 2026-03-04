"""Generate a clean OpenSCAD polygon from the R(angle) profile of planetary_2.stl.
Uses the 3-fold symmetry: one period is 120°, pattern repeats 3x."""
import math

# R vs angle from STL (one period: 0-120°, then repeat)
# Clean up to 5° increments using the measured data
r_table = {
    0: 40.00, 5: 40.00, 10: 40.00, 15: 39.21, 20: 35.19,
    25: 16.50, 30: 16.50, 35: 16.50, 40: 16.50, 45: 13.62,
    50: 31.54, 55: 34.57, 60: 36.76, 65: 37.68, 70: 38.19,
    75: 38.12, 80: 37.64, 85: 36.07, 90: 33.56, 95: 31.44,
    100: 35.15, 105: 39.20, 110: 40.00, 115: 40.00
}

# Generate polygon points for full 360° using 3-fold symmetry
# Use 2° steps for smooth curves
print("// Carrier plate 2D profile — traced from planetary_2.stl")
print("// 3-fold symmetry, R(angle) from STL vertex analysis")
print("module carrier_stl_profile_2d() {")
print("    polygon([")

pts = []
for base_ang in range(0, 360, 2):
    # Map to 0-120 range using 3-fold symmetry
    local_ang = base_ang % 120

    # Interpolate R from table (5° increments)
    lo = (local_ang // 5) * 5
    hi = lo + 5
    if hi > 115:
        hi = 0  # wrap (but 120=0)
    frac = (local_ang - lo) / 5.0

    r_lo = r_table.get(lo, 16.5)
    r_hi = r_table.get(hi if hi <= 115 else 0, 40.0)
    r = r_lo + frac * (r_hi - r_lo)

    x = r * math.cos(math.radians(base_ang))
    y = r * math.sin(math.radians(base_ang))
    pts.append(f"        [{x:.2f}, {y:.2f}]")

print(",\n".join(pts))
print("    ]);")
print("}")
