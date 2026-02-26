#!/usr/bin/env python3
"""
Siphon Flow Rate Verification
===============================

Verifies siphon flow rate against Torricelli's theorem and computes
drain dynamics for a reservoir.

Physics:
- Torricelli's theorem: v = sqrt(2 * g * h)
  where h is the height difference between inlet and outlet
- Volumetric flow rate: Q = A * v = (pi/4) * d^2 * sqrt(2*g*h)
- This assumes:
  - Inviscid flow (no friction losses)
  - Steady state
  - Tube is fully primed (no air)
  - Tube diameter << reservoir dimensions

Drain dynamics:
- For a cylindrical reservoir of volume V with constant cross-section A_res:
  - h(t) decreases as fluid drains
  - dV/dt = -Q(t) = -A_tube * sqrt(2*g*h(t))
  - If reservoir cross-section is constant: dh/dt = -(A_tube/A_res) * sqrt(2*g*h)
  - Analytical solution: h(t) = h0 * (1 - t/t_drain)^2
  - t_drain = 2 * A_res * sqrt(h0) / (A_tube * sqrt(2*g))
- For simple "how long to drain V mL", we use:
  - t_simple = V / Q (constant flow approximation, valid for large reservoir)

Output: verify_siphon_flow_results.json
"""

import json
import numpy as np
from scipy.integrate import solve_ivp
from pathlib import Path


def torricelli_velocity(g, h):
    """
    Flow velocity from Torricelli's theorem.
    v = sqrt(2*g*h)

    Parameters
    ----------
    g : float
        Gravitational acceleration (mm/s^2).
    h : float
        Height difference between inlet and outlet surfaces (mm).

    Returns
    -------
    v : float
        Flow velocity (mm/s).
    """
    return np.sqrt(2.0 * g * h)


def flow_rate(g, h, d):
    """
    Volumetric flow rate through a circular tube.
    Q = A * v = (pi/4) * d^2 * sqrt(2*g*h)

    Parameters
    ----------
    g : float
        Gravitational acceleration (mm/s^2).
    h : float
        Height difference (mm).
    d : float
        Tube inner diameter (mm).

    Returns
    -------
    Q : float
        Flow rate (mm^3/s).
    """
    A = np.pi / 4.0 * d**2
    v = torricelli_velocity(g, h)
    return A * v


def drain_time_constant_flow(volume_mm3, Q):
    """
    Simple drain time assuming constant flow rate.
    t = V / Q

    Parameters
    ----------
    volume_mm3 : float
        Reservoir volume (mm^3).
    Q : float
        Constant flow rate (mm^3/s).

    Returns
    -------
    t : float
        Drain time (seconds).
    """
    if Q <= 0:
        return float('inf')
    return volume_mm3 / Q


def simulate_drain(g, h0, d_tube, volume_mm3, reservoir_diameter):
    """
    Simulate reservoir draining through a siphon with falling head.

    Models the reservoir as a cylinder with given diameter. As fluid
    drains, the head h decreases, reducing flow rate.

    ODE: dV/dt = -A_tube * sqrt(2*g*h(t))
    where h(t) = V(t) / A_reservoir (assumes siphon outlet stays at bottom)

    Parameters
    ----------
    g : float
        Gravitational acceleration (mm/s^2).
    h0 : float
        Initial height difference (mm).
    d_tube : float
        Siphon tube diameter (mm).
    volume_mm3 : float
        Initial reservoir volume (mm^3).
    reservoir_diameter : float
        Reservoir cylinder diameter (mm).

    Returns
    -------
    t_drain : float
        Time to drain to 1% of initial volume (seconds).
    t_history : list
        Time points.
    v_history : list
        Volume at each time point (mm^3).
    q_history : list
        Flow rate at each time point (mm^3/s).
    """
    A_tube = np.pi / 4.0 * d_tube**2
    A_res = np.pi / 4.0 * reservoir_diameter**2

    def drain_ode(t, state):
        V = state[0]
        if V <= 0:
            return [0.0]
        # Current head: assume head is proportional to remaining volume
        h = h0 * (V / volume_mm3)
        if h <= 0:
            return [0.0]
        Q = A_tube * np.sqrt(2.0 * g * h)
        return [-Q]

    # Estimate max drain time (use constant flow as upper bound * 2)
    Q_initial = A_tube * np.sqrt(2.0 * g * h0)
    t_max = 3.0 * volume_mm3 / Q_initial if Q_initial > 0 else 1000.0

    sol = solve_ivp(
        drain_ode,
        [0, t_max],
        [volume_mm3],
        method='RK45',
        max_step=t_max / 500,
        rtol=1e-8,
        atol=1e-10,
        dense_output=True,
        events=None
    )

    # Find time to drain to 1% of initial volume
    t_drain = t_max
    for i in range(len(sol.t)):
        if sol.y[0][i] <= 0.01 * volume_mm3:
            t_drain = float(sol.t[i])
            break

    # Sample 100 points for output
    t_sample = np.linspace(0, min(t_drain * 1.1, t_max), 100)
    v_sample = sol.sol(t_sample)[0]
    v_sample = np.maximum(v_sample, 0)  # clamp to zero

    # Compute flow rates at sample points
    q_sample = []
    for V in v_sample:
        if V <= 0:
            q_sample.append(0.0)
        else:
            h = h0 * (V / volume_mm3)
            q_sample.append(float(A_tube * np.sqrt(2.0 * g * max(h, 0))))

    return t_drain, t_sample.tolist(), v_sample.tolist(), q_sample


def main():
    g = 9810.0  # mm/s^2
    heights = [20.0, 50.0, 100.0, 200.0]       # mm
    diameters = [5.0, 10.0, 20.0]              # mm tube diameter
    reservoir_volume_mL = 50.0
    reservoir_volume_mm3 = reservoir_volume_mL * 1000.0  # 1 mL = 1000 mm^3 = 1 cm^3
    reservoir_diameter = 40.0  # mm (arbitrary, for drain simulation)

    results = {
        "description": "Siphon flow rate verification against Torricelli's theorem",
        "parameters": {
            "g_mm_per_s2": g,
            "reservoir_volume_mL": reservoir_volume_mL,
            "reservoir_volume_mm3": reservoir_volume_mm3,
            "reservoir_diameter_mm": reservoir_diameter
        },
        "tolerance_notes": {
            "velocity": "JS implementation should match Torricelli velocity within 1%",
            "flow_rate": "Flow rate should match within 2% (allows for timestep effects)",
            "drain_time": "Drain time should match within 5% (accumulation of per-step errors)",
            "note": "Real siphons have friction losses (Darcy-Weisbach), so ideal values are upper bounds"
        },
        "test_cases": []
    }

    for h in heights:
        for d in diameters:
            v = torricelli_velocity(g, h)
            Q = flow_rate(g, h, d)
            A_tube = np.pi / 4.0 * d**2
            t_simple = drain_time_constant_flow(reservoir_volume_mm3, Q)

            # Reynolds number estimate (water at ~20C, kinematic viscosity ~ 1 mm^2/s)
            nu = 1.0  # mm^2/s (approximate for water at 20C)
            Re = v * d / nu

            # Simulate drain with falling head
            t_drain, t_hist, v_hist, q_hist = simulate_drain(
                g, h, d, reservoir_volume_mm3, reservoir_diameter
            )

            case = {
                "h_mm": h,
                "d_tube_mm": d,
                "A_tube_mm2": float(A_tube),
                "velocity_mm_per_s": float(v),
                "velocity_m_per_s": float(v / 1000.0),
                "flow_rate_mm3_per_s": float(Q),
                "flow_rate_mL_per_s": float(Q / 1000.0),
                "reynolds_number": float(Re),
                "flow_regime": "laminar" if Re < 2300 else "turbulent",
                "drain_time_constant_flow_s": float(t_simple),
                "drain_time_falling_head_s": float(t_drain),
                "drain_time_ratio": float(t_drain / t_simple) if t_simple > 0 else float('inf'),
                "drain_history": {
                    "t_s": t_hist,
                    "volume_mm3": v_hist,
                    "flow_rate_mm3_per_s": q_hist
                }
            }
            results["test_cases"].append(case)

            print(f"h={h:.0f}mm, d={d:.0f}mm:")
            print(f"  Velocity: {v:.1f} mm/s ({v/1000:.3f} m/s)")
            print(f"  Flow rate: {Q:.1f} mm^3/s ({Q/1000:.3f} mL/s)")
            print(f"  Re = {Re:.0f} ({'laminar' if Re < 2300 else 'turbulent'})")
            print(f"  Drain time (const flow): {t_simple:.2f} s")
            print(f"  Drain time (falling head): {t_drain:.2f} s")

    # Write results
    out_path = Path(__file__).parent / "verify_siphon_flow_results.json"
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nResults written to {out_path}")


if __name__ == "__main__":
    main()
