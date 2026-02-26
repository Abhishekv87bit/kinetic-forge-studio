#!/usr/bin/env python3
"""
Verlet Cable Sag Verification
==============================

Simulates a cable with N particles hanging under gravity between two fixed
endpoints using Verlet integration with distance constraints. The equilibrium
shape should approximate a catenary curve:

    y = a * cosh((x - x0) / a) + C

For a cable with uniform mass per unit length under gravity, the shape
is a catenary. For a Verlet chain with equal-mass particles, the shape
converges to a catenary as N increases. With finite N and constraint
iterations, it approximates a parabola (which is the catenary's small-sag
limit).

We fit both:
1. Catenary: y = a*cosh((x - x0)/a) + c
2. Parabola: y = A*(x - x0)^2 + c  (the small-sag limit)

Physics:
- Verlet integration: x(t+dt) = 2*x(t) - x(t-dt) + a*dt^2
- Distance constraints enforced iteratively (Jakobsen method)
- Velocity damping ensures convergence to static equilibrium
- Under gravity, constrained particles settle into catenary/parabolic shape

Output: verify_verlet_cable_results.json
"""

import json
import numpy as np
from scipy.optimize import curve_fit
from pathlib import Path


def catenary(x, a, x0, c):
    """Catenary curve: y = a * cosh((x - x0) / a) + c"""
    return a * np.cosh((x - x0) / a) + c


def parabola(x, A, x0, c):
    """Parabola: y = A*(x - x0)^2 + c"""
    return A * (x - x0)**2 + c


def simulate_verlet_cable(n_particles, span, gravity, n_steps, n_constraint_iters,
                          damping=0.98):
    """
    Simulate a cable with Verlet integration and velocity damping.

    Parameters
    ----------
    n_particles : int
        Number of particles (including 2 fixed endpoints).
    span : float
        Horizontal distance between endpoints (pixels).
    gravity : float
        Gravitational acceleration (px/frame^2).
    n_steps : int
        Number of simulation steps.
    n_constraint_iters : int
        Number of constraint satisfaction iterations per step.
    damping : float
        Velocity damping factor per frame (0.98 = 2% energy loss/frame).

    Returns
    -------
    positions : ndarray, shape (n_particles, 2)
        Final (x, y) positions of all particles.
    """
    # Initial positions: evenly spaced along horizontal line at y=0
    positions = np.zeros((n_particles, 2))
    positions[:, 0] = np.linspace(0, span, n_particles)
    positions[:, 1] = 0.0  # start flat

    # Previous positions (for Verlet: prev = current initially => zero velocity)
    prev_positions = positions.copy()

    # Rest length for each segment
    rest_length = span / (n_particles - 1)

    # Gravity vector (positive y = downward in screen coords)
    g_vec = np.array([0.0, gravity])

    for step in range(n_steps):
        # --- Verlet integration with damping ---
        new_positions = positions.copy()

        for i in range(1, n_particles - 1):  # skip fixed endpoints
            velocity = (positions[i] - prev_positions[i]) * damping
            new_positions[i] = positions[i] + velocity + g_vec

        prev_positions = positions.copy()
        positions = new_positions.copy()

        # --- Distance constraints (Jakobsen relaxation) ---
        for _ in range(n_constraint_iters):
            for i in range(n_particles - 1):
                delta = positions[i + 1] - positions[i]
                dist = np.linalg.norm(delta)
                if dist < 1e-10:
                    continue
                diff = (dist - rest_length) / dist
                correction = delta * 0.5 * diff

                # Fixed endpoints don't move
                if i == 0:
                    positions[i + 1] -= correction * 2
                elif i + 1 == n_particles - 1:
                    positions[i] += correction * 2
                else:
                    positions[i] += correction
                    positions[i + 1] -= correction

    return positions


def fit_curves(positions):
    """
    Fit both catenary and parabola to the simulated cable positions.

    Returns
    -------
    cat_params : tuple (a, x0, c) or None
    cat_residual : float
    cat_fitted_y : list
    par_params : tuple (A, x0, c) or None
    par_residual : float
    par_fitted_y : list
    """
    x = positions[:, 0]
    y = positions[:, 1]
    span = x[-1] - x[0]
    sag = np.max(y) - np.min(y)

    if sag < 0.01:
        return None, 0.0, y.tolist(), None, 0.0, y.tolist()

    # --- Parabola fit ---
    x0_guess = span / 2.0
    A_guess = sag / (span / 2.0)**2
    c_guess = np.min(y)

    try:
        par_params, _ = curve_fit(
            parabola, x, y,
            p0=[A_guess, x0_guess, c_guess],
            maxfev=10000
        )
        par_fitted = parabola(x, *par_params)
        par_residual = float(np.sqrt(np.mean((y - par_fitted)**2)))
        par_params = tuple(float(p) for p in par_params)
        par_fitted_y = par_fitted.tolist()
    except (RuntimeError, ValueError):
        par_params = None
        par_residual = float('inf')
        par_fitted_y = []

    # --- Catenary fit ---
    # Use parabola center as initial guess for catenary center
    cat_x0 = par_params[1] if par_params else span / 2.0
    # For catenary, sag = a*(cosh(span/(2a)) - 1) ~ span^2/(8a) for large a
    a_guess = max(span**2 / (8.0 * sag), 1.0)

    try:
        cat_params, _ = curve_fit(
            catenary, x, y,
            p0=[a_guess, cat_x0, np.min(y) - a_guess],
            maxfev=20000,
            bounds=([0.1, -span, -1e8], [1e8, 2 * span, 1e8])
        )
        cat_fitted = catenary(x, *cat_params)
        cat_residual = float(np.sqrt(np.mean((y - cat_fitted)**2)))
        cat_params = tuple(float(p) for p in cat_params)
        cat_fitted_y = cat_fitted.tolist()
    except (RuntimeError, ValueError):
        cat_params = None
        cat_residual = float('inf')
        cat_fitted_y = []

    return cat_params, cat_residual, cat_fitted_y, par_params, par_residual, par_fitted_y


def main():
    span = 300.0
    gravity = 0.5
    n_steps = 3000
    n_constraint_iters = 10
    damping = 0.98
    particle_counts = [20, 50, 100]

    results = {
        "description": "Verlet cable sag verification against catenary and parabolic curves",
        "parameters": {
            "span_px": span,
            "gravity_px_per_frame2": gravity,
            "n_steps": n_steps,
            "n_constraint_iterations": n_constraint_iters,
            "velocity_damping": damping
        },
        "tolerance_notes": {
            "parabola_fit_rms": "JS implementation should match parabola RMS residual within 2x of Python reference",
            "endpoint_positions": "Endpoints must remain fixed at (0, y0) and (span, y0)",
            "sag_depth": "Maximum sag should match within 5% of reference value",
            "catenary_vs_parabola": "For finite N, parabola is often a better fit; catenary converges as N increases",
            "damping_note": "0.98 damping ensures convergence to static equilibrium"
        },
        "test_cases": []
    }

    for n in particle_counts:
        print(f"Simulating cable with N={n} particles...")
        positions = simulate_verlet_cable(n, span, gravity, n_steps,
                                          n_constraint_iters, damping)

        cat_params, cat_res, cat_y, par_params, par_res, par_y = fit_curves(positions)

        sag = float(np.max(positions[:, 1]) - np.min(positions[:, 1]))
        max_y_idx = int(np.argmax(positions[:, 1]))

        case = {
            "n_particles": n,
            "sag_depth_px": sag,
            "max_sag_x": float(positions[max_y_idx, 0]),
            "max_sag_y": float(positions[max_y_idx, 1]),
            "parabola_params": {
                "A": par_params[0],
                "x0": par_params[1],
                "c": par_params[2]
            } if par_params else None,
            "parabola_fit_rms_residual": par_res,
            "catenary_params": {
                "a": cat_params[0],
                "x0": cat_params[1],
                "c": cat_params[2]
            } if cat_params else None,
            "catenary_fit_rms_residual": cat_res,
            "best_fit": "parabola" if par_res <= cat_res else "catenary",
            "positions_x": positions[:, 0].tolist(),
            "positions_y": positions[:, 1].tolist(),
            "parabola_fitted_y": par_y,
            "catenary_fitted_y": cat_y
        }
        results["test_cases"].append(case)

        print(f"  Sag depth: {sag:.2f} px")
        print(f"  Parabola fit RMS: {par_res:.6f} px")
        print(f"  Catenary fit RMS: {cat_res:.6f} px")
        best = "parabola" if par_res <= cat_res else "catenary"
        print(f"  Best fit: {best}")

    # Write results
    out_path = Path(__file__).parent / "verify_verlet_cable_results.json"
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nResults written to {out_path}")


if __name__ == "__main__":
    main()
