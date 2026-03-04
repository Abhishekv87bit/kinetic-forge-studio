"""
BOM Consultant — Gate 3 (Production).

Bill of Materials generation and completeness checking:
- Completeness: all parts accounted for
- Fastener spec: bolt grade, torque spec
- Bearing spec: type, size, preload, lubrication
- Motor spec: type, voltage, torque, speed
- Raw stock: material sizes and sources
"""

import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run BOM consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="bom", passed=True)

    for check in checks:
        result.checks_run.append(check)

        if check == "completeness":
            _check_completeness(result, state)
        elif check == "fastener_spec":
            _check_fastener_spec(result, state)
        elif check == "bearing_spec":
            _check_bearing_spec(result, state)
        elif check == "motor_spec":
            _check_motor_spec(result, state)
        elif check == "raw_stock":
            _check_raw_stock(result, state)
        else:
            result.checks_passed.append(check)

    return result


def _check_completeness(result: "ConsultantResult", state: "ProjectState"):
    """Verify all parts are accounted for in the BOM."""
    components = state.components or state.spec.get("components", [])

    if not components:
        result.checks_failed.append("completeness")
        result.passed = False
        result.findings.append("BOM completeness FAIL: no components registered")
        result.recommendations.append("Register all components before production gate")
        return

    # Check for required fields
    incomplete = []
    bom_items = []

    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            ctype = comp.get("type", comp.get("component_type", ""))
            params = comp.get("parameters", {})
            material = params.get("material", "")

            missing = []
            if not material:
                missing.append("material")
            if not params.get("quantity", 1):
                missing.append("quantity")

            bom_items.append({
                "name": name,
                "type": ctype,
                "material": material or "unspecified",
                "quantity": params.get("quantity", 1),
            })

            if missing:
                incomplete.append(f"'{name}': missing {', '.join(missing)}")

    result.findings.append(
        f"BOM: {len(bom_items)} item(s) registered"
    )
    for item in bom_items:
        result.findings.append(
            f"  - {item['name']} ({item['type']}): "
            f"{item['material']}, qty={item['quantity']}"
        )

    if incomplete:
        result.checks_failed.append("completeness")
        result.passed = False
        result.findings.append(
            f"BOM incomplete: {len(incomplete)} item(s) missing data"
        )
        for inc in incomplete:
            result.recommendations.append(f"BOM: {inc}")
    else:
        result.checks_passed.append("completeness")
        result.findings.append("BOM completeness PASS: all items have material + quantity")


def _check_fastener_spec(result: "ConsultantResult", state: "ProjectState"):
    """Check that fasteners have grade and torque spec."""
    components = state.components or state.spec.get("components", [])

    fasteners = [
        c for c in components
        if isinstance(c, dict)
        and c.get("type", c.get("component_type", "")) in (
            "bolt", "screw", "nut", "fastener", "washer"
        )
    ]

    if not fasteners:
        result.checks_passed.append("fastener_spec")
        result.findings.append("Fastener spec: no fasteners in BOM")
        return

    issues = []
    for f in fasteners:
        name = f.get("display_name", f.get("id", "?"))
        params = f.get("parameters", {})

        if not params.get("grade"):
            issues.append(f"'{name}': no bolt grade (e.g., 8.8, A2-70)")
        if not params.get("torque_nm") and not params.get("torque"):
            issues.append(f"'{name}': no torque spec")
        if not params.get("size"):
            issues.append(f"'{name}': no size (e.g., M5, M8)")

    if not issues:
        result.checks_passed.append("fastener_spec")
        result.findings.append(
            f"Fastener spec PASS: {len(fasteners)} fastener(s) fully specified"
        )
    else:
        result.checks_failed.append("fastener_spec")
        result.passed = False
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _check_bearing_spec(result: "ConsultantResult", state: "ProjectState"):
    """Check that bearings have type, size, and lubrication."""
    components = state.components or state.spec.get("components", [])

    bearings = [
        c for c in components
        if isinstance(c, dict)
        and c.get("type", c.get("component_type", "")) in (
            "bearing", "bushing", "ball_bearing"
        )
    ]

    if not bearings:
        result.checks_passed.append("bearing_spec")
        result.findings.append("Bearing spec: no bearings in BOM")
        return

    issues = []
    for b in bearings:
        name = b.get("display_name", b.get("id", "?"))
        params = b.get("parameters", {})

        if not params.get("bearing_type", params.get("type")):
            issues.append(f"'{name}': no bearing type (ball, sleeve, needle)")
        if not params.get("bore"):
            issues.append(f"'{name}': no bore diameter")
        if not params.get("lubrication"):
            issues.append(f"'{name}': no lubrication spec (grease, oil, dry)")

    if not issues:
        result.checks_passed.append("bearing_spec")
        result.findings.append(
            f"Bearing spec PASS: {len(bearings)} bearing(s) fully specified"
        )
    else:
        result.checks_failed.append("bearing_spec")
        result.passed = False
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _check_motor_spec(result: "ConsultantResult", state: "ProjectState"):
    """Check motor has complete specifications."""
    motor = state.motor_spec or state.spec.get("motor", {})

    if not motor:
        # Check components for motors
        components = state.components or state.spec.get("components", [])
        motors = [
            c for c in components
            if isinstance(c, dict)
            and c.get("type", c.get("component_type", "")) in ("motor", "stepper", "servo")
        ]
        if not motors:
            result.checks_passed.append("motor_spec")
            result.findings.append("Motor spec: no motor in BOM")
            return
        motor = motors[0].get("parameters", {})

    issues = []
    if not motor.get("voltage"):
        issues.append("Motor: no voltage specified")
    if not motor.get("rpm", motor.get("speed_rpm")):
        issues.append("Motor: no speed (RPM) specified")
    if not motor.get("torque_nm", motor.get("torque")):
        issues.append("Motor: no torque specified")
    if not motor.get("type", motor.get("motor_type")):
        issues.append("Motor: no type (DC, stepper, BLDC)")

    if not issues:
        result.checks_passed.append("motor_spec")
        result.findings.append("Motor spec PASS: fully specified")
    else:
        result.checks_failed.append("motor_spec")
        result.passed = False
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _check_raw_stock(result: "ConsultantResult", state: "ProjectState"):
    """Check that raw material stock sizes are specified."""
    components = state.components or state.spec.get("components", [])

    machined_parts = [
        c for c in components
        if isinstance(c, dict)
        and c.get("type", c.get("component_type", "")) in (
            "shaft", "housing", "frame", "bracket", "plate", "block"
        )
    ]

    if not machined_parts:
        result.checks_passed.append("raw_stock")
        result.findings.append("Raw stock: no machined parts to specify")
        return

    issues = []
    for part in machined_parts:
        name = part.get("display_name", part.get("id", "?"))
        params = part.get("parameters", {})

        if not params.get("stock_size") and not params.get("raw_material"):
            issues.append(
                f"'{name}': no raw stock size specified "
                f"(e.g., '25mm round bar', '12mm plate')"
            )

    if not issues:
        result.checks_passed.append("raw_stock")
        result.findings.append(
            f"Raw stock PASS: {len(machined_parts)} part(s) have stock specs"
        )
    else:
        # Advisory, not failure
        result.checks_passed.append("raw_stock")
        result.findings.append(
            f"Raw stock: {len(issues)} part(s) need stock size specs"
        )
        for issue in issues:
            result.recommendations.append(issue)
