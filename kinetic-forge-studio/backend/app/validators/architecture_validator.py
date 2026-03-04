"""Architecture validator — vertical budget, Grashof, transmission angle, power budget."""

from __future__ import annotations
import math


def vertical_budget_check(
    components: list[dict], envelope_height: float | None = None
) -> dict:
    """Check total Z-stack vs envelope height."""
    z_items = []
    total_height = 0.0

    for comp in components:
        params = comp.get("parameters", {})
        h = params.get("height", 0)
        if h:
            z_items.append({"name": comp.get("id", "?"), "height": float(h)})
            total_height += float(h)

    result = {
        "total_height": total_height,
        "items": z_items,
        "passed": True,
        "findings": [],
    }

    if envelope_height and total_height > envelope_height:
        result["passed"] = False
        result["findings"].append(
            f"Z-stack ({total_height:.1f}mm) exceeds envelope ({envelope_height:.1f}mm) "
            f"by {total_height - envelope_height:.1f}mm"
        )
    elif envelope_height:
        surplus = envelope_height - total_height
        result["findings"].append(
            f"Z-stack OK: {total_height:.1f}mm of {envelope_height:.1f}mm "
            f"({surplus:.1f}mm surplus)"
        )
    else:
        result["findings"].append(
            f"Z-stack total: {total_height:.1f}mm (no envelope specified)"
        )

    return result


def grashof_check(
    crank: float, coupler: float, rocker: float, ground: float
) -> dict:
    """Check Grashof condition for a four-bar linkage."""
    links = sorted([crank, coupler, rocker, ground])
    s, p, q, l_ = links[0], links[1], links[2], links[3]

    grashof_sum = s + l_
    other_sum = p + q
    is_grashof = grashof_sum <= other_sum

    result = {
        "passed": is_grashof,
        "s_plus_l": grashof_sum,
        "p_plus_q": other_sum,
        "findings": [],
    }

    if is_grashof:
        result["findings"].append(
            f"Grashof satisfied: S+L={grashof_sum:.1f} <= P+Q={other_sum:.1f}"
        )
    else:
        result["findings"].append(
            f"Grashof VIOLATED: S+L={grashof_sum:.1f} > P+Q={other_sum:.1f}. "
            "Mechanism will lock up."
        )

    return result


def transmission_angle_check(
    angles_deg: list[float], min_ok: float = 40.0, max_ok: float = 140.0
) -> dict:
    """Check transmission angles are within acceptable range (40-140 degrees)."""
    violations = []
    for angle in angles_deg:
        if angle < min_ok or angle > max_ok:
            violations.append(angle)

    result = {
        "passed": len(violations) == 0,
        "angles": angles_deg,
        "violations": violations,
        "findings": [],
    }

    if violations:
        result["findings"].append(
            f"Transmission angle violations: {violations} outside [{min_ok}, {max_ok}]"
        )
    else:
        result["findings"].append(
            f"All {len(angles_deg)} transmission angles within [{min_ok}, {max_ok}]"
        )

    return result


def power_budget_check(
    required_torque_nm: float,
    required_speed_rpm: float,
    motor_power_w: float,
    safety_factor: float = 2.0,
) -> dict:
    """Check required power < motor power / safety_factor."""
    required_power = required_torque_nm * (required_speed_rpm * 2 * math.pi / 60)
    available_power = motor_power_w / safety_factor

    result = {
        "passed": required_power <= available_power,
        "required_w": round(required_power, 2),
        "available_w": round(available_power, 2),
        "motor_power_w": motor_power_w,
        "safety_factor": safety_factor,
        "findings": [],
    }

    if result["passed"]:
        margin = available_power - required_power
        result["findings"].append(
            f"Power OK: {required_power:.1f}W required, {available_power:.1f}W available "
            f"({margin:.1f}W margin with {safety_factor}x safety)"
        )
    else:
        result["findings"].append(
            f"Power EXCEEDED: {required_power:.1f}W required > {available_power:.1f}W available "
            f"(motor={motor_power_w}W / {safety_factor}x safety)"
        )

    return result
