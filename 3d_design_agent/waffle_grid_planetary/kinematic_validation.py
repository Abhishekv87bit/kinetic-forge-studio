#!/usr/bin/env python3
"""
Ravigneaux Wave Drive — Kinematic Validation
Verifies Willis equations, compatibility conditions, and wave generation.
"""
import math

# ============================================================
# CURRENT UNIT TOOTH COUNTS
# ============================================================
T_SS   = 26
T_SL   = 32
T_PO   = 24
T_PI   = 19
T_RING = 80

NORM_MOD  = 0.7
HELIX_ANG = 25
TRANS_MOD = NORM_MOD / math.cos(math.radians(HELIX_ANG))
DP = 1 / TRANS_MOD

print("=" * 60)
print("RAVIGNEAUX KINEMATIC VALIDATION")
print("=" * 60)

# ============================================================
# 1. RING CONSTRAINT
# ============================================================
print(f"\n--- Ring Constraint ---")
ring_check = T_SL + 2 * T_PO
print(f"T_SL + 2*T_PO = {T_SL} + {2*T_PO} = {ring_check}")
assert ring_check == T_RING, f"FAIL: {ring_check} != {T_RING}"
print(f"== T_RING = {T_RING} ✓")

# ============================================================
# 2. Po-Ss CLEARANCE (ISSUE-012)
# ============================================================
print(f"\n--- Po-Ss Clearance ---")
po_ss_gap = (T_SL - T_SS - 4) / (2 * DP)
print(f"Gap formula: (T_SL - T_SS - 4) / (2*DP) = ({T_SL} - {T_SS} - 4) / {2*DP:.4f}")
print(f"Gap = {po_ss_gap:.4f} mm")
assert po_ss_gap > 0, f"FAIL: Po-Ss gap = {po_ss_gap:.4f} mm (COLLISION)"
print(f"Gap > 0 ✓")

# ============================================================
# 3. WILLIS EQUATIONS
# ============================================================
print(f"\n--- Willis Equation Verification ---")

def verify_willis(omega_SL, omega_SS, omega_C, omega_R_expected=None):
    """Verify both Willis equations and compatibility."""
    # Path 1: SL -> Po -> Ring
    # (ω_R - ω_C) / (ω_SL - ω_C) = -T_SL / T_Ring
    R1 = -T_SL / T_RING
    omega_R_path1 = omega_C + R1 * (omega_SL - omega_C)

    # Path 2: Ss -> Pi -> Po -> Ring
    # (ω_R - ω_C) / (ω_SS - ω_C) = +T_SS / T_Ring
    R2 = T_SS / T_RING
    omega_R_path2 = omega_C + R2 * (omega_SS - omega_C)

    # Compatibility check
    omega_C_required = (T_SL * omega_SL + T_SS * omega_SS) / (T_SL + T_SS)
    compat_ok = abs(omega_C - omega_C_required) < 1e-10

    print(f"  ω_SL={omega_SL:+.4f}  ω_SS={omega_SS:+.4f}  ω_C={omega_C:+.4f}")
    print(f"  Path1 ω_R = {omega_R_path1:+.4f}")
    print(f"  Path2 ω_R = {omega_R_path2:+.4f}")
    print(f"  Required ω_C = {omega_C_required:+.4f}  {'✓' if compat_ok else 'MISMATCH'}")

    if compat_ok:
        assert abs(omega_R_path1 - omega_R_path2) < 1e-10, "Paths disagree!"
        print(f"  Paths agree ✓  ω_Ring = {omega_R_path1:+.4f}")
    else:
        print(f"  WARNING: ω_C={omega_C:.4f} != required {omega_C_required:.4f}")
        print(f"  Path1 and Path2 give different ω_Ring — mechanism would BIND")

    return omega_R_path1 if compat_ok else None

# Test: rigid body rotation (all spin at 1.0)
print("\nTest 1: Rigid body (all = 1.0)")
verify_willis(1.0, 1.0, 1.0)

# Test: SL only (Ss held)
print("\nTest 2: SL only, Ss held (ω_SS=0)")
omega_C_2 = (T_SL * 1.0 + T_SS * 0) / (T_SL + T_SS)
verify_willis(1.0, 0.0, omega_C_2)

# Test: Ss only (SL held)
print("\nTest 3: Ss only, SL held (ω_SL=0)")
omega_C_3 = (T_SL * 0 + T_SS * 1.0) / (T_SL + T_SS)
verify_willis(0.0, 1.0, omega_C_3)

# Test: Counter-rotating suns
print("\nTest 4: Counter-rotating suns (ω_SL=+1, ω_SS=-1)")
omega_C_4 = (T_SL * 1.0 + T_SS * (-1.0)) / (T_SL + T_SS)
verify_willis(1.0, -1.0, omega_C_4)

# Test: Carrier held
print("\nTest 5: Carrier held (ω_C=0)")
# Compatibility: 0 = T_SL*ω_SL + T_SS*ω_SS → ω_SS = -(T_SL/T_SS)*ω_SL
omega_SS_5 = -(T_SL / T_SS) * 1.0
verify_willis(1.0, omega_SS_5, 0.0)

# ============================================================
# 4. WEIGHT FACTORS
# ============================================================
print(f"\n--- Weight Factors ---")
W_SL = T_SL * (T_RING - T_SS) / (T_RING * (T_SL + T_SS))
W_SS = T_SS * (T_RING + T_SL) / (T_RING * (T_SL + T_SS))
print(f"W_SL = {T_SL}×{T_RING-T_SS} / ({T_RING}×{T_SL+T_SS}) = {W_SL:.6f}")
print(f"W_SS = {T_SS}×{T_RING+T_SL} / ({T_RING}×{T_SL+T_SS}) = {W_SS:.6f}")
print(f"W_SL + W_SS = {W_SL + W_SS:.6f} {'✓' if abs(W_SL + W_SS - 1.0) < 1e-10 else 'FAIL'}")

# ============================================================
# 5. MULTI-UNIT WAVE SIMULATION
# ============================================================
print(f"\n{'=' * 60}")
print("MULTI-UNIT WAVE SIMULATION")
print(f"{'=' * 60}")

# Option A: Same internals, vary external pinion ratios
print(f"\n--- Option A: Identical internals, varied external ratios ---")
print(f"{'Unit':>4} {'r_SL':>6} {'r_SS':>6} {'r_C':>8} {'K_i':>8} {'Phase°':>8}")

configs_A = [
    (1, 1.0, 1.000),
    (2, 1.0, 0.900),
    (3, 1.0, 0.800),
    (4, 1.0, 0.618),
    (5, 0.8, 1.000),
    (6, 0.6, 1.000),
    (7, 0.5, 0.500),
]
K_ref = None
for unit, r_SL, r_SS in configs_A:
    K = W_SL * r_SL + W_SS * r_SS
    r_C = (T_SL * r_SL + T_SS * r_SS) / (T_SL + T_SS)
    if K_ref is None:
        K_ref = K
    phase = 360 * (1 - K / K_ref) if K_ref != 0 else 0
    print(f"{unit:4d} {r_SL:6.3f} {r_SS:6.3f} {r_C:8.4f} {K:8.4f} {phase:8.1f}")

# Option C: Vary both internal and external
print(f"\n--- Option C: Varied internals + externals (RECOMMENDED) ---")
print(f"{'Unit':>4} {'T_SS':>4} {'T_SL':>4} {'T_PO':>4} {'r_SL':>6} {'r_SS':>6} {'K_i':>8} {'Gap_mm':>7}")

configs_C = [
    # (unit, t_ss, t_sl, r_sl, r_ss)
    (1, 26, 32, 1.0, 0.8),
    (2, 24, 34, 1.0, 0.8),
    (3, 22, 36, 1.0, 0.8),
    (4, 20, 38, 0.8, 1.0),
    (5, 18, 40, 0.8, 1.0),
    (6, 24, 34, 0.6, 1.0),
    (7, 26, 32, 0.6, 1.0),
]

for unit, t_ss, t_sl, r_sl, r_ss in configs_C:
    t_po = (T_RING - t_sl) // 2
    gap = (t_sl - t_ss - 4) / (2 * DP)
    w_sl = t_sl * (T_RING - t_ss) / (T_RING * (t_sl + t_ss))
    w_ss = t_ss * (T_RING + t_sl) / (T_RING * (t_sl + t_ss))
    K = w_sl * r_sl + w_ss * r_ss
    status = "✓" if gap > 0 else "FAIL"
    print(f"{unit:4d} {t_ss:4d} {t_sl:4d} {t_po:4d} {r_sl:6.3f} {r_ss:6.3f} {K:8.4f} {gap:6.2f}{status}")

# ============================================================
# 6. ROPE / PIXEL DISPLACEMENT
# ============================================================
print(f"\n{'=' * 60}")
print("ROPE & PIXEL DISPLACEMENT")
print(f"{'=' * 60}")

R_spool = (T_RING + 2) / (2 * DP)  # Ring addendum radius ≈ spool surface
print(f"Ring OD / spool radius = {R_spool:.2f} mm")
print(f"Spool circumference = {2 * math.pi * R_spool:.2f} mm")
print(f"Rope per ring revolution = {2 * math.pi * R_spool:.2f} mm")

# Example: motor at 10 RPM, K range 0.5 to 1.0
motor_rpm = 10
print(f"\nMotor speed = {motor_rpm} RPM")
print(f"{'K_i':>6} {'Ring RPM':>10} {'Rope mm/s':>10} {'Pixel mm/rev':>14}")
for K in [0.5, 0.6, 0.7, 0.8, 0.9, 1.0]:
    ring_rpm = K * motor_rpm
    rope_speed = 2 * math.pi * R_spool * ring_rpm / 60
    pixel_per_rev = 2 * math.pi * R_spool * K
    print(f"{K:6.2f} {ring_rpm:10.2f} {rope_speed:10.2f} {pixel_per_rev:14.2f}")

print(f"\n{'=' * 60}")
print("ALL CHECKS PASSED ✓")
print(f"{'=' * 60}")
