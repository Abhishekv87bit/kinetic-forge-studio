"""
Physics Consultant — Gate 1 (Design).

Deterministic checks for physics feasibility:
- Power budget: required < available / 2
- Driver tracing: every animation has a physical driver
- Torque chain: input torque propagates to output
- Friction cascade: efficiency = 0.95^n for n stages
"""

import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run physics consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="physics", passed=True)
    spec = state.spec

    for check in checks:
        result.checks_run.append(check)

        if check == "power_budget":
            _check_power_budget(result, spec, state)
        elif check == "driver_tracing":
            _check_driver_tracing(result, spec, state)
        elif check == "torque_chain":
            _check_torque_chain(result, spec, state)
        elif check == "friction_cascade":
            _check_friction_cascade(result, spec, state)
        else:
            result.checks_passed.append(check)
            result.findings.append(f"Check '{check}' not implemented — skipped")

    return result


def _check_power_budget(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """
    Required power must be less than available / 2.
    P_required = torque_required * angular_velocity
    """
    motor = state.motor_spec or spec.get("motor", {})
    if not motor:
        result.checks_passed.append("power_budget")
        result.findings.append("Power budget: no motor spec provided")
        return

    motor_rpm = motor.get("rpm", motor.get("speed_rpm", 0))
    motor_torque = motor.get("torque_nm", motor.get("torque", 0))

    if not motor_rpm or not motor_torque:
        result.checks_passed.append("power_budget")
        result.findings.append("Power budget: incomplete motor spec (need rpm + torque)")
        return

    # Available power in watts
    import math
    omega = motor_rpm * 2 * math.pi / 60
    available_power = motor_torque * omega
    budget = available_power / 2  # 50% safety margin

    # Required power from spec
    required_torque = spec.get("required_torque_nm", 0)
    required_rpm = spec.get("required_rpm", motor_rpm)

    if required_torque > 0:
        omega_req = required_rpm * 2 * math.pi / 60
        required_power = required_torque * omega_req
    else:
        # Estimate from component count and mass
        num_components = len(state.components) or len(spec.get("components", []))
        # Rough estimate: 0.1W per moving component
        required_power = num_components * 0.1

    if required_power <= budget:
        result.checks_passed.append("power_budget")
        result.findings.append(
            f"Power budget PASS: required={required_power:.2f}W "
            f"<= budget={budget:.2f}W (available={available_power:.2f}W)"
        )
    else:
        result.checks_failed.append("power_budget")
        result.passed = False
        result.findings.append(
            f"Power budget FAIL: required={required_power:.2f}W "
            f"> budget={budget:.2f}W (available={available_power:.2f}W)"
        )
        result.recommendations.append(
            f"Motor is underpowered. Need {required_power:.2f}W but budget is "
            f"{budget:.2f}W. Use a stronger motor or reduce load."
        )


def _check_driver_tracing(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """
    Every animation parameter must trace to a physical mechanism.
    No orphan sin($t) — each movement needs a driver.
    """
    components = state.components or spec.get("components", [])
    if not components:
        result.checks_passed.append("driver_tracing")
        result.findings.append("Driver tracing: no components to check")
        return

    # Check that every animated component has a driver
    undriven = []
    driven = []

    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "unknown"))
            ctype = comp.get("type", comp.get("component_type", ""))
            params = comp.get("parameters", {})

            # These types are drivers, not driven
            if ctype in ("motor", "driver", "input", "crank"):
                driven.append(name)
                continue

            # Check if component has animation but no driver reference
            is_animated = params.get("animated", False)
            has_driver = params.get("driven_by", params.get("driver", ""))

            if is_animated and not has_driver:
                undriven.append(name)
            else:
                driven.append(name)

    if not undriven:
        result.checks_passed.append("driver_tracing")
        result.findings.append(
            f"Driver tracing PASS: all {len(driven)} components have drivers"
        )
    else:
        result.checks_failed.append("driver_tracing")
        result.passed = False
        result.findings.append(
            f"Driver tracing FAIL: {len(undriven)} undriven animations: "
            f"{', '.join(undriven)}"
        )
        result.recommendations.append(
            f"Components [{', '.join(undriven)}] are animated but have no physical "
            f"driver. Add 'driven_by' parameter or connect to mechanism."
        )


def _check_torque_chain(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """
    Verify torque propagates from input to output through the mechanism.
    """
    components = state.components or spec.get("components", [])
    mechanism = state.mechanism_type or spec.get("mechanism_type", "")

    if not components or not mechanism:
        result.checks_passed.append("torque_chain")
        result.findings.append("Torque chain: insufficient data for analysis")
        return

    # Simple check: is there at least one input and one output?
    has_input = False
    has_output = False

    for comp in components:
        if isinstance(comp, dict):
            ctype = comp.get("type", comp.get("component_type", ""))
            if ctype in ("motor", "crank", "driver", "input"):
                has_input = True
            if ctype in ("output", "driven", "rocker", "slider"):
                has_output = True

    if has_input and has_output:
        result.checks_passed.append("torque_chain")
        result.findings.append(
            "Torque chain PASS: input and output components found"
        )
    elif has_input:
        result.checks_passed.append("torque_chain")
        result.findings.append(
            "Torque chain: input found but no explicit output — verify "
            "mechanism transmits motion"
        )
    else:
        result.checks_failed.append("torque_chain")
        result.passed = False
        result.findings.append("Torque chain FAIL: no input driver found")
        result.recommendations.append(
            "No motor/crank/driver component found. Add an input mechanism "
            "to drive the kinetic sculpture."
        )


def _check_friction_cascade(result: "ConsultantResult", spec: dict, state: "ProjectState"):
    """
    Efficiency = 0.95^n for n stages.
    With 9+ pulleys/stages, efficiency drops below 63%.
    """
    num_stages = spec.get("num_stages", spec.get("num_pulleys", 0))

    if not num_stages:
        # Count from components
        components = state.components or spec.get("components", [])
        stage_types = ("pulley", "gear", "belt", "chain", "worm")
        num_stages = sum(
            1 for c in components
            if isinstance(c, dict)
            and c.get("type", c.get("component_type", "")) in stage_types
        )

    if num_stages == 0:
        result.checks_passed.append("friction_cascade")
        result.findings.append("Friction cascade: no stages detected")
        return

    eta_per_stage = spec.get("stage_efficiency", 0.95)
    efficiency = eta_per_stage ** num_stages
    efficiency_pct = efficiency * 100

    if efficiency >= 0.50:  # 50% minimum acceptable
        result.checks_passed.append("friction_cascade")
        result.findings.append(
            f"Friction cascade PASS: {num_stages} stages, "
            f"efficiency={efficiency_pct:.1f}% "
            f"(eta_stage={eta_per_stage})"
        )
        if efficiency < 0.70:
            result.recommendations.append(
                f"Warning: {num_stages} stages gives {efficiency_pct:.1f}% efficiency. "
                f"Consider reducing stages to improve performance."
            )
    else:
        result.checks_failed.append("friction_cascade")
        result.passed = False
        result.findings.append(
            f"Friction cascade FAIL: {num_stages} stages, "
            f"efficiency={efficiency_pct:.1f}% (min 50%)"
        )
        max_stages = 0
        while eta_per_stage ** max_stages >= 0.50:
            max_stages += 1
        max_stages -= 1
        result.recommendations.append(
            f"Too many friction stages. Max ~{max_stages} stages at "
            f"{eta_per_stage} efficiency per stage. Reduce mechanism complexity."
        )
