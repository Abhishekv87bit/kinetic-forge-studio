#!/usr/bin/env python3
"""
Pendulum Period Verification
=============================

Verifies pendulum period against two references:

1. Small-angle approximation: T = 2*pi*sqrt(L/g)
   Valid for theta << 1 radian.

2. Full nonlinear ODE solved numerically:
   theta''(t) = -(g/L)*sin(theta(t))
   Period found by detecting zero crossings of theta(t).

Physics:
- Simple pendulum: point mass on massless rigid rod
- Small-angle linearization replaces sin(theta) with theta
- For large angles, period increases — the small-angle formula underestimates
- Exact period involves complete elliptic integral:
  T_exact = 4*sqrt(L/g) * K(sin(theta0/2))
  where K is the complete elliptic integral of the first kind

Output: verify_pendulum_period_results.json
"""

import json
import numpy as np
from scipy.integrate import solve_ivp
from scipy.special import ellipk
from pathlib import Path


def pendulum_ode(t, state, g, L):
    """
    ODE for simple pendulum.
    state = [theta, omega]
    theta' = omega
    omega' = -(g/L)*sin(theta)
    """
    theta, omega = state
    return [omega, -(g / L) * np.sin(theta)]


def find_period_from_simulation(t, theta):
    """
    Find the period by detecting zero crossings of theta(t)
    where the pendulum passes through equilibrium going in the
    same direction (positive-going crossings).

    Returns
    -------
    period : float
        Average period from detected crossings.
    n_periods : int
        Number of complete periods detected.
    """
    # Find positive-going zero crossings
    crossings = []
    for i in range(1, len(theta)):
        if theta[i - 1] < 0 and theta[i] >= 0:
            # Linear interpolation for more precise crossing time
            frac = -theta[i - 1] / (theta[i] - theta[i - 1])
            t_cross = t[i - 1] + frac * (t[i] - t[i - 1])
            crossings.append(t_cross)

    if len(crossings) < 2:
        return float('inf'), 0

    periods = np.diff(crossings)
    return float(np.mean(periods)), len(periods)


def exact_period(L, g, theta0):
    """
    Exact period using complete elliptic integral of the first kind.
    T = 4*sqrt(L/g) * K(sin(theta0/2))
    """
    k = np.sin(theta0 / 2)
    K = ellipk(k**2)  # scipy's ellipk takes m = k^2
    return 4.0 * np.sqrt(L / g) * K


def main():
    g = 9.81  # m/s^2
    lengths = [0.1, 0.25, 0.5, 1.0]  # meters
    theta0_values = [0.1, 0.3, 0.5, 1.0]  # radians

    results = {
        "description": "Pendulum period verification: small-angle vs numerical vs exact elliptic integral",
        "parameters": {
            "g_m_per_s2": g
        },
        "tolerance_notes": {
            "period": "JS implementation period should match numerical reference within 1%",
            "small_angle_error": "Shows expected deviation of T=2pi*sqrt(L/g) from true period",
            "trajectory": "Sampled theta(t) at 100 evenly spaced times for waveform comparison"
        },
        "test_cases": []
    }

    for L in lengths:
        for theta0 in theta0_values:
            # Small-angle approximation
            T_small = 2.0 * np.pi * np.sqrt(L / g)

            # Exact period via elliptic integral
            T_exact = exact_period(L, g, theta0)

            # Numerical simulation
            # Simulate for ~10 periods to get good average
            t_max = 15 * T_small
            dt_max = T_small / 200  # at least 200 points per period

            sol = solve_ivp(
                pendulum_ode,
                [0, t_max],
                [theta0, 0.0],  # released from rest
                args=(g, L),
                method='RK45',
                max_step=dt_max,
                rtol=1e-10,
                atol=1e-12,
                dense_output=True
            )

            T_numerical, n_periods = find_period_from_simulation(sol.t, sol.y[0])

            # Sample trajectory at 100 evenly spaced points over 3 periods
            t_sample = np.linspace(0, 3 * T_exact, 100)
            theta_sample = sol.sol(t_sample)[0]

            # Compute errors
            small_angle_error_pct = 100.0 * (T_small - T_exact) / T_exact
            numerical_error_pct = 100.0 * (T_numerical - T_exact) / T_exact

            case = {
                "L_m": L,
                "theta0_rad": theta0,
                "theta0_deg": float(np.degrees(theta0)),
                "T_small_angle_s": float(T_small),
                "T_exact_elliptic_s": float(T_exact),
                "T_numerical_s": float(T_numerical),
                "n_periods_detected": int(n_periods),
                "small_angle_error_pct": float(small_angle_error_pct),
                "numerical_error_pct": float(numerical_error_pct),
                "trajectory_t": t_sample.tolist(),
                "trajectory_theta": theta_sample.tolist()
            }
            results["test_cases"].append(case)

            print(f"L={L:.2f}m, theta0={theta0:.1f}rad ({np.degrees(theta0):.1f} deg):")
            print(f"  T_small={T_small:.6f}s, T_exact={T_exact:.6f}s, T_num={T_numerical:.6f}s")
            print(f"  Small-angle error: {small_angle_error_pct:+.4f}%")
            print(f"  Numerical error:   {numerical_error_pct:+.6f}%")

    # Write results
    out_path = Path(__file__).parent / "verify_pendulum_period_results.json"
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nResults written to {out_path}")


if __name__ == "__main__":
    main()
