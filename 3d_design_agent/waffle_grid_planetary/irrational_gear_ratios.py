"""
P5: IRRATIONAL GEAR RATIO APPROXIMATION
========================================
Goal: Find integer tooth count pairs that approximate √2 and φ (golden ratio)
for motor→cam gear trains in the Waffle Grid Planetary sculpture.

The 3 cam motors must run at frequency ratios:
  Motor A: 1.0×     (reference)
  Motor B: √2×      (≈ 1.41421356...)
  Motor C: φ×        (≈ 1.61803399...)

Since we use GEAR TRAINS (not electronic speed control), we need integer
tooth count ratios that closely approximate these irrational numbers.

Method: Continued fraction expansion gives best rational approximations.
We also check that:
  - All tooth counts are between MIN_TEETH and MAX_TEETH
  - The gear pair fits physically (combined OD < available space)
  - The ratio error is below a perceptibility threshold
"""

import math
from fractions import Fraction

# === TARGETS ===
SQRT2 = math.sqrt(2)   # 1.41421356...
PHI   = (1 + math.sqrt(5)) / 2  # 1.61803399...

# === CONSTRAINTS ===
MIN_TEETH = 12    # Below this → undercut risk at PA=25°
MAX_TEETH = 80    # Practical maximum for MOD=1.0 (80mm pitch dia)
MOD = 1.0         # Module (mm)
MAX_COMBINED_OD = 120  # mm — max space for two meshing gears

# Perceptibility threshold: how accurately must we approximate?
# The wave repeats when all 3 frequencies return to a common phase.
# With exact irrationals → never repeats.
# With rational approximations p/q → repeats every LCM cycles.
# We want the repeat period > 1 hour at typical sculpture speed.
# At 2 RPM base speed, 1 hour = 120 revolutions of Motor A.
# Repeat period = LCM(qA, qB, qC) revolutions of the base.
# qA = 1 (Motor A is the reference), so repeat = LCM(1, qB, qC)
MIN_REPEAT_REVS = 120  # Want at least this many revs before pattern repeats

def continued_fraction_convergents(x, max_terms=20):
    """Generate best rational approximations via continued fractions."""
    convergents = []
    a0 = int(x)
    remainder = x - a0

    # Build continued fraction [a0; a1, a2, ...]
    h_prev, h_curr = 1, a0
    k_prev, k_curr = 0, 1
    convergents.append((h_curr, k_curr))

    for _ in range(max_terms):
        if abs(remainder) < 1e-12:
            break
        x_inv = 1.0 / remainder
        a_n = int(x_inv)
        remainder = x_inv - a_n

        h_new = a_n * h_curr + h_prev
        k_new = a_n * k_curr + k_prev

        convergents.append((h_new, k_new))
        h_prev, h_curr = h_curr, h_new
        k_prev, k_curr = k_curr, k_new

    return convergents

def find_gear_ratios(target, name, min_t=MIN_TEETH, max_t=MAX_TEETH):
    """Find best integer gear ratios for a target irrational number."""
    print(f"\n{'='*60}")
    print(f"  TARGET: {name} = {target:.10f}")
    print(f"  Tooth range: {min_t}–{max_t}  Module: {MOD}mm")
    print(f"{'='*60}")

    # Method 1: Continued fraction convergents
    print(f"\n  Continued fraction convergents:")
    convergents = continued_fraction_convergents(target)

    viable = []
    for num, den in convergents:
        if den == 0:
            continue
        ratio = num / den
        error = abs(ratio - target) / target * 100

        # Check: can we express this as driven/driver teeth?
        # Ratio = driven_teeth / driver_teeth = num/den
        # For speed-UP: driven < driver (motor gear bigger)
        # For speed-DOWN: driven > driver
        # Our ratios > 1 → cam runs FASTER → driver > driven?
        # Actually: gear ratio = output/input = driven/driver
        # If motor (input) has T_motor teeth and cam (output) has T_cam:
        # ω_cam / ω_motor = T_motor / T_cam = target
        # → T_motor / T_cam = √2  → T_motor = √2 × T_cam
        # So T_motor > T_cam (motor gear is bigger)

        # Single stage: T_motor = num, T_cam = den (if ratio > 1)
        t_motor = num  # driver (motor side)
        t_cam = den    # driven (cam side)

        fits = (min_t <= t_motor <= max_t and min_t <= t_cam <= max_t)
        combined_od = MOD * (t_motor + t_cam + 4)  # +4 for addendum
        space_ok = combined_od <= MAX_COMBINED_OD

        status = "✓ VIABLE" if (fits and space_ok) else "✗"
        if not fits:
            status += " (teeth out of range)"
        if not space_ok:
            status += " (too large)"

        print(f"    {num}/{den} = {ratio:.8f}  error={error:.4f}%  "
              f"T=[{t_motor},{t_cam}]  {status}")

        if fits and space_ok:
            viable.append({
                'num': num, 'den': den, 'ratio': ratio,
                'error_pct': error,
                't_motor': t_motor, 't_cam': t_cam,
                'combined_od': combined_od,
                'method': 'convergent'
            })

    # Method 2: Brute-force search for best ratios in tooth range
    print(f"\n  Brute-force search (top 10 by accuracy):")
    candidates = []
    for t1 in range(min_t, max_t + 1):
        for t2 in range(min_t, max_t + 1):
            ratio = t1 / t2
            error = abs(ratio - target) / target * 100
            if error < 0.5:  # Within 0.5% only
                combined_od = MOD * (t1 + t2 + 4)
                if combined_od <= MAX_COMBINED_OD:
                    candidates.append({
                        'num': t1, 'den': t2, 'ratio': ratio,
                        'error_pct': error,
                        't_motor': t1, 't_cam': t2,
                        'combined_od': combined_od,
                        'method': 'brute_force'
                    })

    candidates.sort(key=lambda x: x['error_pct'])
    for c in candidates[:10]:
        g = math.gcd(c['num'], c['den'])
        simplified = f"{c['num']//g}/{c['den']//g}"
        repeat = math.lcm(1, c['den'])  # LCM with Motor A (1 rev)

        print(f"    {c['num']}/{c['den']} ({simplified}) = {c['ratio']:.8f}  "
              f"error={c['error_pct']:.5f}%  "
              f"OD={c['combined_od']:.0f}mm  "
              f"repeat={repeat}rev")

        viable.append(c)

    # Deduplicate and sort
    seen = set()
    unique = []
    for v in viable:
        key = (v['num'], v['den'])
        if key not in seen:
            seen.add(key)
            unique.append(v)
    unique.sort(key=lambda x: x['error_pct'])

    return unique[:10]

def two_stage_search(target, name, min_t=MIN_TEETH, max_t=60):
    """Find 2-stage compound gear trains for better precision."""
    print(f"\n  Two-stage compound trains (T1/T2 × T3/T4 ≈ {target:.6f}):")

    candidates = []
    for t1 in range(min_t, max_t + 1):
        for t2 in range(min_t, max_t + 1):
            r1 = t1 / t2
            # What ratio does stage 2 need?
            r2_needed = target / r1
            if r2_needed < min_t / max_t or r2_needed > max_t / min_t:
                continue

            for t3 in range(min_t, max_t + 1):
                t4_ideal = t3 / r2_needed
                t4 = round(t4_ideal)
                if t4 < min_t or t4 > max_t:
                    continue

                total_ratio = (t1 / t2) * (t3 / t4)
                error = abs(total_ratio - target) / target * 100

                if error < 0.05:  # Very tight: within 0.05%
                    candidates.append({
                        'stage1': (t1, t2),
                        'stage2': (t3, t4),
                        'ratio': total_ratio,
                        'error_pct': error,
                        'total_teeth': t1 + t2 + t3 + t4
                    })

    candidates.sort(key=lambda x: (x['error_pct'], x['total_teeth']))

    for c in candidates[:8]:
        s1, s2 = c['stage1'], c['stage2']
        repeat_den = s1[1] * s2[1]
        print(f"    {s1[0]}/{s1[1]} × {s2[0]}/{s2[1]} = {c['ratio']:.8f}  "
              f"error={c['error_pct']:.5f}%  "
              f"teeth={c['total_teeth']}  repeat≈{repeat_den}rev")

def main():
    print("╔══════════════════════════════════════════════════════╗")
    print("║  P5: IRRATIONAL GEAR RATIO APPROXIMATION            ║")
    print("║  Motor ratios: 1 : √2 : φ (non-repeating wave)     ║")
    print("╚══════════════════════════════════════════════════════╝")

    # √2 approximation
    sqrt2_options = find_gear_ratios(SQRT2, "√2")
    two_stage_search(SQRT2, "√2")

    # φ approximation
    phi_options = find_gear_ratios(PHI, "φ (golden ratio)")
    two_stage_search(PHI, "φ")

    # === SUMMARY ===
    print("\n" + "="*60)
    print("  RECOMMENDED GEAR PAIRS")
    print("="*60)

    print(f"\n  Motor A (reference): direct drive (1:1) or any equal pair")

    if sqrt2_options:
        best = sqrt2_options[0]
        print(f"\n  Motor B (√2 = {SQRT2:.6f}):")
        print(f"    BEST: {best['t_motor']}T / {best['t_cam']}T = {best['ratio']:.8f}")
        print(f"    Error: {best['error_pct']:.5f}%")
        print(f"    Combined OD: {best['combined_od']:.0f}mm")

        # Show top 3
        for i, opt in enumerate(sqrt2_options[:3]):
            repeat = math.lcm(1, opt['den'])
            print(f"    Option {i+1}: {opt['t_motor']}T/{opt['t_cam']}T "
                  f"= {opt['ratio']:.6f} (err={opt['error_pct']:.4f}%, "
                  f"repeat={repeat}rev)")

    if phi_options:
        best = phi_options[0]
        print(f"\n  Motor C (φ = {PHI:.6f}):")
        print(f"    BEST: {best['t_motor']}T / {best['t_cam']}T = {best['ratio']:.8f}")
        print(f"    Error: {best['error_pct']:.5f}%")
        print(f"    Combined OD: {best['combined_od']:.0f}mm")

        for i, opt in enumerate(phi_options[:3]):
            repeat = math.lcm(1, opt['den'])
            print(f"    Option {i+1}: {opt['t_motor']}T/{opt['t_cam']}T "
                  f"= {opt['ratio']:.6f} (err={opt['error_pct']:.4f}%, "
                  f"repeat={repeat}rev)")

    # Repeat period analysis
    print(f"\n  REPEAT PERIOD ANALYSIS:")
    if sqrt2_options and phi_options:
        for sb in sqrt2_options[:3]:
            for sp in phi_options[:3]:
                qB = sb['den']
                qC = sp['den']
                repeat = math.lcm(qB, qC)
                hours_at_2rpm = repeat / (2 * 60)
                print(f"    B={sb['t_motor']}/{sb['t_cam']} + C={sp['t_motor']}/{sp['t_cam']}: "
                      f"repeat every {repeat} rev = {hours_at_2rpm:.1f} hours @ 2RPM")

if __name__ == '__main__':
    main()
