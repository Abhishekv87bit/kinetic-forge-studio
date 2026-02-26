#!/usr/bin/env python3
"""
Magnetic Dipole Torque Verification
=====================================

Computes the torque between two concentric rings of magnetic dipoles.
Each magnet is modeled as a point magnetic dipole oriented radially
(pointing outward from center).

Physics:
- Magnetic dipole field: B(r) = (mu0/4pi) * [3(m.r_hat)r_hat - m] / |r|^3
- Torque on dipole m2 in field B: tau = m2 x B
- For radially-oriented dipoles on concentric rings, we sum pairwise
  interactions between all dipoles on ring 1 and all dipoles on ring 2
- Net torque about the shared axis (z-axis) produces cogging behavior
- Cogging period = 360 / lcm(n1, n2) degrees
- Effective gear ratio = n2 / n1

The computation sweeps ring 2 through 60 angular offsets (0 to 360/n2 degrees)
to capture one full cogging period.

Note: We work in 2D (z=0 plane) since radial dipoles in a plane produce
z-axis torque only. Units are arbitrary (normalized dipole strength = 1).

Output: verify_dipole_torque_results.json
"""

import json
import numpy as np
from math import gcd
from pathlib import Path


def dipole_field_2d(m_vec, m_pos, eval_pos):
    """
    Magnetic field of a 2D point dipole at eval_pos.

    Uses the 2D version of the dipole field formula.
    In 2D, the field of a dipole m at origin, evaluated at position r:
    B(r) = (1/(2*pi)) * [2*(m.r_hat)*r_hat - m] / |r|^2

    We use normalized units (mu0 = 4*pi, so prefactor = 1 in 3D;
    for 2D cross-section we use a simplified model).

    For our purpose (relative torque profile), the absolute scale doesn't
    matter -- we only need the shape of torque vs angle.

    Parameters
    ----------
    m_vec : ndarray, shape (2,)
        Dipole moment vector.
    m_pos : ndarray, shape (2,)
        Position of the dipole.
    eval_pos : ndarray, shape (2,)
        Position where field is evaluated.

    Returns
    -------
    B : ndarray, shape (2,)
        Magnetic field vector at eval_pos.
    """
    r = eval_pos - m_pos
    r_mag = np.linalg.norm(r)
    if r_mag < 1e-10:
        return np.zeros(2)

    r_hat = r / r_mag
    m_dot_rhat = np.dot(m_vec, r_hat)

    # 3D dipole field projected to 2D plane: B = (1/r^3) * [3(m.rhat)rhat - m]
    # We keep the 1/r^3 scaling which is correct for 3D dipoles in a plane
    B = (1.0 / r_mag**3) * (3.0 * m_dot_rhat * r_hat - m_vec)
    return B


def compute_ring_torque(n1, n2, r1, r2, offset_deg):
    """
    Compute net z-axis torque on ring 2 from ring 1.

    Parameters
    ----------
    n1, n2 : int
        Number of magnets on ring 1 and ring 2.
    r1, r2 : float
        Radii of ring 1 and ring 2 (mm).
    offset_deg : float
        Angular offset of ring 2 relative to ring 1 (degrees).

    Returns
    -------
    torque_z : float
        Net torque about z-axis (arbitrary units).
    """
    offset_rad = np.radians(offset_deg)

    # Ring 1 magnet positions and dipole moments (radially oriented)
    angles1 = np.linspace(0, 2 * np.pi, n1, endpoint=False)
    pos1 = np.column_stack([r1 * np.cos(angles1), r1 * np.sin(angles1)])
    m1 = np.column_stack([np.cos(angles1), np.sin(angles1)])  # radial outward

    # Ring 2 magnet positions and dipole moments (rotated by offset)
    angles2 = np.linspace(0, 2 * np.pi, n2, endpoint=False) + offset_rad
    pos2 = np.column_stack([r2 * np.cos(angles2), r2 * np.sin(angles2)])
    m2 = np.column_stack([np.cos(angles2), np.sin(angles2)])  # radial outward

    total_torque_z = 0.0

    for j in range(n2):
        # Sum field from all ring 1 dipoles at position of ring 2 magnet j
        B_total = np.zeros(2)
        for i in range(n1):
            B_total += dipole_field_2d(m1[i], pos1[i], pos2[j])

        # Torque on dipole j: tau = m x B (z-component in 2D)
        # tau_z = m2x * By - m2y * Bx
        tau_z = m2[j, 0] * B_total[1] - m2[j, 1] * B_total[0]
        total_torque_z += tau_z

    return total_torque_z


def main():
    n_values = [4, 8, 12]
    r1 = 50.0   # mm
    r2 = 70.0   # mm
    n_offsets = 60

    results = {
        "description": "Magnetic dipole torque between concentric rings of radially-oriented magnets",
        "parameters": {
            "r1_mm": r1,
            "r2_mm": r2,
            "dipole_orientation": "radial_outward",
            "n_angular_offsets": n_offsets,
            "units": "arbitrary (normalized dipole strength = 1)"
        },
        "tolerance_notes": {
            "torque_shape": "JS implementation torque profile should match reference shape within 5% of peak",
            "cogging_period": "Period of torque oscillation should match exactly",
            "zero_crossings": "Equilibrium angles should match within 0.5 degrees",
            "symmetry": "Torque must be antisymmetric about equilibrium points"
        },
        "test_cases": []
    }

    for n1 in n_values:
        for n2 in n_values:
            # Cogging period: full torque cycle repeats every 360/lcm(n1,n2) degrees
            lcm_val = (n1 * n2) // gcd(n1, n2)
            cogging_period_deg = 360.0 / lcm_val

            # Sweep offset over one full cogging period (plus margin for context)
            # We sweep over 360/min(n1,n2) to show multiple cogging periods
            sweep_range = 360.0 / min(n1, n2)
            offsets = np.linspace(0, sweep_range, n_offsets, endpoint=False)

            torques = []
            for offset in offsets:
                tau = compute_ring_torque(n1, n2, r1, r2, offset)
                torques.append(tau)

            torques = np.array(torques)
            max_torque = float(np.max(np.abs(torques)))

            # Find zero crossings (equilibrium points)
            zero_crossings = []
            for i in range(1, len(torques)):
                if torques[i - 1] * torques[i] < 0:
                    # Linear interpolation
                    frac = -torques[i - 1] / (torques[i] - torques[i - 1])
                    angle = offsets[i - 1] + frac * (offsets[i] - offsets[i - 1])
                    zero_crossings.append(float(angle))

            # Detect cogging period from torque signal
            # Use FFT to find dominant frequency
            if max_torque > 1e-15:
                fft_mag = np.abs(np.fft.rfft(torques))
                freqs = np.fft.rfftfreq(len(torques), d=(offsets[1] - offsets[0]))
                # Skip DC component
                if len(fft_mag) > 1:
                    dominant_idx = np.argmax(fft_mag[1:]) + 1
                    dominant_freq = freqs[dominant_idx]
                    detected_period = 1.0 / dominant_freq if dominant_freq > 0 else float('inf')
                else:
                    detected_period = float('inf')
            else:
                detected_period = float('inf')

            case = {
                "n1": n1,
                "n2": n2,
                "theoretical_cogging_period_deg": float(cogging_period_deg),
                "detected_cogging_period_deg": float(detected_period),
                "gear_ratio": float(n2) / float(n1),
                "max_torque_abs": max_torque,
                "equilibrium_angles_deg": zero_crossings,
                "offset_deg": offsets.tolist(),
                "torque": torques.tolist()
            }
            results["test_cases"].append(case)

            print(f"n1={n1}, n2={n2}:")
            print(f"  Gear ratio: {n2/n1:.2f}")
            print(f"  Cogging period (theory): {cogging_period_deg:.2f} deg")
            print(f"  Cogging period (detected): {detected_period:.2f} deg")
            print(f"  Max torque: {max_torque:.6f}")
            print(f"  Equilibria: {len(zero_crossings)} zero crossings")

    # Write results
    out_path = Path(__file__).parent / "verify_dipole_torque_results.json"
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nResults written to {out_path}")


if __name__ == "__main__":
    main()
