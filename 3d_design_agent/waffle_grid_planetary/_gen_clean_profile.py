"""Generate clean carrier profile polygon.
Clamp minimum R to hub_r (no pin-hole dips).
Use finer steps (1°) for smooth curves."""
import math

hub_r = 16.5  # hub tube outer radius

# R_max vs angle at 5° (one period: 0-120°)
# Clamp min to hub_r
r_raw = {
    0: 40.00, 5: 40.00, 10: 40.00, 15: 39.21, 20: 35.19,
    25: 16.50, 30: 16.50, 35: 16.50, 40: 16.50, 45: 16.50,  # clamped from 13.62
    50: 31.54, 55: 34.57, 60: 36.76, 65: 37.68, 70: 38.19,
    75: 38.12, 80: 37.64, 85: 36.07, 90: 33.56, 95: 31.44,
    100: 35.15, 105: 39.20, 110: 40.00, 115: 40.00, 120: 40.00
}

def interp_r(angle_deg):
    a = angle_deg % 120
    lo = int(a // 5) * 5
    hi = min(lo + 5, 120)
    frac = (a - lo) / 5.0
    r_lo = r_raw.get(lo, hub_r)
    r_hi = r_raw.get(hi, r_raw.get(hi % 120, 40.0))
    r = r_lo + frac * (r_hi - r_lo)
    return max(r, hub_r)

# Generate at 2° steps (180 points)
print("// Clean carrier plate 2D profile")
print("// 180 pts, 2° steps, 3-fold symmetric, min R clamped to hub OD")
print("CAR_PROFILE_PTS = [")
pts = []
for ang in range(0, 360, 2):
    r = interp_r(ang)
    x = r * math.cos(math.radians(ang))
    y = r * math.sin(math.radians(ang))
    pts.append(f"    [{x:7.2f}, {y:7.2f}]")
print(",\n".join(pts))
print("];")
