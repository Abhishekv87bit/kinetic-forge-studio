#!/usr/bin/env python3
"""
Euler-Bernoulli Beam Deflection Verification
=============================================

Verifies cantilever beam deflection under a point load at the free end
using the Euler-Bernoulli beam theory analytical solution.

Physics:
- Cantilever beam: fixed at x=0, free at x=L
- Point load P applied downward at x=L
- Deflection curve: y(x) = P/(6*E*I) * (3*L*x^2 - x^3)
- Maximum deflection at tip: delta_max = P*L^3 / (3*E*I)
- Slope at tip: theta_max = P*L^2 / (2*E*I)

Assumptions:
- Small deflections (linear theory)
- Homogeneous, isotropic material
- Plane sections remain plane
- No shear deformation (thin beam)

The deflection curve is sampled at 50 points along the beam length
for comparison with JS implementations.

Output: verify_beam_deflection_results.json
"""

import json
import numpy as np
from pathlib import Path


def cantilever_deflection(x, P, L, EI):
    """
    Analytical deflection of a cantilever beam with tip load.

    Parameters
    ----------
    x : array_like
        Position along beam (0 = fixed end, L = free end).
    P : float
        Applied force at tip (N).
    L : float
        Beam length (mm).
    EI : float
        Flexural rigidity (N*mm^2).

    Returns
    -------
    y : ndarray
        Deflection at each x position (mm). Positive = downward.
    """
    x = np.asarray(x, dtype=float)
    return P / (6.0 * EI) * (3.0 * L * x**2 - x**3)


def cantilever_slope(x, P, L, EI):
    """
    Analytical slope (dy/dx) of a cantilever beam with tip load.
    """
    x = np.asarray(x, dtype=float)
    return P / (6.0 * EI) * (6.0 * L * x - 3.0 * x**2)


def cantilever_moment(x, P, L):
    """
    Bending moment along the cantilever beam.
    M(x) = P * (L - x)
    """
    x = np.asarray(x, dtype=float)
    return P * (L - x)


def cantilever_shear(x, P):
    """
    Shear force along the cantilever (constant = P for tip load).
    """
    return np.full_like(np.asarray(x, dtype=float), P)


def main():
    lengths = [100.0, 200.0, 300.0]       # mm
    ei_values = [1e3, 1e4, 1e5]           # N*mm^2
    loads = [1.0, 5.0, 10.0]             # N
    n_points = 50                          # sample points along beam

    results = {
        "description": "Euler-Bernoulli cantilever beam deflection verification",
        "parameters": {
            "beam_type": "cantilever",
            "loading": "point_load_at_tip",
            "n_sample_points": n_points
        },
        "tolerance_notes": {
            "deflection": "JS implementation should match analytical deflection within 0.1%",
            "tip_deflection": "Maximum deflection delta_max = P*L^3/(3*E*I) is the key check",
            "curve_shape": "Full deflection curve y(x) should match pointwise within 0.5%",
            "units": "All dimensions in mm, forces in N, EI in N*mm^2"
        },
        "test_cases": []
    }

    for L in lengths:
        for EI in ei_values:
            for P in loads:
                # Maximum deflection at tip
                delta_max = P * L**3 / (3.0 * EI)

                # Maximum slope at tip
                slope_max = P * L**2 / (2.0 * EI)

                # Maximum moment at fixed end
                moment_max = P * L

                # Sample the deflection curve
                x = np.linspace(0, L, n_points)
                y = cantilever_deflection(x, P, L, EI)
                slope = cantilever_slope(x, P, L, EI)
                moment = cantilever_moment(x, P, L)

                # Strain energy: U = P^2 * L^3 / (6 * E * I)
                strain_energy = P**2 * L**3 / (6.0 * EI)

                # Stiffness: k = 3*EI/L^3
                stiffness = 3.0 * EI / L**3

                case = {
                    "L_mm": L,
                    "EI_N_mm2": EI,
                    "P_N": P,
                    "delta_max_mm": float(delta_max),
                    "slope_max_rad": float(slope_max),
                    "slope_max_deg": float(np.degrees(slope_max)),
                    "moment_max_N_mm": float(moment_max),
                    "stiffness_N_per_mm": float(stiffness),
                    "strain_energy_N_mm": float(strain_energy),
                    "deflection_curve": {
                        "x_mm": x.tolist(),
                        "y_mm": y.tolist(),
                        "slope_rad": slope.tolist(),
                        "moment_N_mm": moment.tolist()
                    }
                }
                results["test_cases"].append(case)

                print(f"L={L:.0f}mm, EI={EI:.0e} N*mm^2, P={P:.0f}N:")
                print(f"  delta_max = {delta_max:.4f} mm")
                print(f"  slope_max = {np.degrees(slope_max):.4f} deg")
                print(f"  stiffness = {stiffness:.4f} N/mm")

    # Write results
    out_path = Path(__file__).parent / "verify_beam_deflection_results.json"
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nResults written to {out_path}")


if __name__ == "__main__":
    main()
