"""
FDM Ground Truth Consultant — Gate 2 (Prototype).

Identifies critical fits that need test prints before full assembly:
- Critical fit identification: shaft/bearing, gear mesh, press-fit, snap-fit
- Test coupon specifications: what to test-print and measure
- Print orientation: best build direction per part
- Support assessment: where supports are needed
"""

import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)

# Critical fit thresholds for FDM
FDM_THRESHOLDS = {
    "min_clearance_sliding": 0.3,   # mm, minimum for sliding fit
    "min_clearance_free": 0.5,      # mm, minimum for free rotation
    "press_fit_interference": 0.1,  # mm, typical FDM press fit
    "min_wall_thickness": 1.5,      # mm, minimum printable wall
    "max_overhang_angle": 45.0,     # degrees from vertical
    "max_bridge_span": 15.0,        # mm, max unsupported bridge
    "gear_mesh_clearance": 0.2,     # mm, minimum gear tooth clearance
}


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run FDM ground truth consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="fdm_ground_truth", passed=True)

    for check in checks:
        result.checks_run.append(check)

        if check == "critical_fit_id":
            _check_critical_fits(result, state)
        elif check == "test_coupon_spec":
            _check_test_coupons(result, state)
        elif check == "print_orientation":
            _check_print_orientation(result, state)
        elif check == "support_assessment":
            _check_support_needs(result, state)
        else:
            result.checks_passed.append(check)

    return result


def _check_critical_fits(result: "ConsultantResult", state: "ProjectState"):
    """Identify fits that MUST be test-printed before full assembly."""
    components = state.components or state.spec.get("components", [])
    critical_fits = []

    for comp in components:
        if isinstance(comp, dict):
            ctype = comp.get("type", comp.get("component_type", ""))
            name = comp.get("display_name", comp.get("id", "?"))
            params = comp.get("parameters", {})

            # Shaft/bearing interfaces
            if ctype in ("bearing", "bushing"):
                bore = params.get("bore", params.get("inner_diameter", 0))
                if bore > 0:
                    critical_fits.append({
                        "type": "shaft_bearing",
                        "component": name,
                        "nominal": bore,
                        "note": f"Bearing bore {bore}mm — test shaft fit",
                    })

            # Gear mesh
            elif ctype in ("gear", "spur_gear", "pinion"):
                module = params.get("module", 0)
                teeth = params.get("teeth", 0)
                if module and teeth:
                    critical_fits.append({
                        "type": "gear_mesh",
                        "component": name,
                        "nominal": module,
                        "note": f"Gear m={module} z={teeth} — test mesh clearance",
                    })

            # Press-fit joints
            elif params.get("fit_type") == "press_fit" or params.get("fit") == "H7/p6":
                diameter = params.get("diameter", params.get("od", 0))
                critical_fits.append({
                    "type": "press_fit",
                    "component": name,
                    "nominal": diameter,
                    "note": f"Press-fit {diameter}mm — test interference",
                })

            # Snap-fit features
            elif params.get("snap_fit") or ctype == "snap_fit":
                critical_fits.append({
                    "type": "snap_fit",
                    "component": name,
                    "nominal": 0,
                    "note": "Snap-fit — test engagement force and flexibility",
                })

    if critical_fits:
        result.checks_passed.append("critical_fit_id")
        result.findings.append(
            f"Critical fits identified: {len(critical_fits)} fit(s) need test prints"
        )
        for fit in critical_fits:
            result.findings.append(f"  - [{fit['type']}] {fit['note']}")
        result.recommendations.append(
            f"Print {len(critical_fits)} test coupon(s) before full assembly "
            f"to verify critical fits."
        )
    else:
        result.checks_passed.append("critical_fit_id")
        result.findings.append("Critical fits: none identified (simple assembly)")


def _check_test_coupons(result: "ConsultantResult", state: "ProjectState"):
    """Generate test coupon specifications for critical fits."""
    components = state.components or state.spec.get("components", [])
    coupons = []

    for comp in components:
        if isinstance(comp, dict):
            ctype = comp.get("type", comp.get("component_type", ""))
            params = comp.get("parameters", {})

            if ctype in ("gear", "spur_gear", "pinion"):
                module = params.get("module", 0)
                if module > 0:
                    coupons.append(
                        f"Gear tooth mesh coupon: 3-tooth segment, m={module}, "
                        f"test at {FDM_THRESHOLDS['gear_mesh_clearance']}mm clearance"
                    )

            if ctype in ("bearing", "bushing"):
                bore = params.get("bore", 0)
                if bore > 0:
                    coupons.append(
                        f"Shaft fit coupon: {bore}mm bore, test shafts at "
                        f"{bore-0.1:.1f} / {bore} / {bore+0.1:.1f}mm"
                    )

    if coupons:
        result.checks_passed.append("test_coupon_spec")
        result.findings.append(f"Test coupons recommended: {len(coupons)}")
        for coupon in coupons:
            result.findings.append(f"  - {coupon}")
    else:
        result.checks_passed.append("test_coupon_spec")
        result.findings.append("Test coupons: none needed")


def _check_print_orientation(result: "ConsultantResult", state: "ProjectState"):
    """Recommend best build direction for each part type."""
    components = state.components or state.spec.get("components", [])
    orientations = []

    for comp in components:
        if isinstance(comp, dict):
            ctype = comp.get("type", comp.get("component_type", ""))
            name = comp.get("display_name", comp.get("id", "?"))
            params = comp.get("parameters", {})

            if ctype in ("gear", "spur_gear"):
                orientations.append(
                    f"'{name}' (gear): print with tooth face UP "
                    f"(best tooth profile accuracy)"
                )
            elif ctype == "shaft":
                length = params.get("length", params.get("height", 0))
                if length > 50:
                    orientations.append(
                        f"'{name}' (shaft): print VERTICAL for roundness, "
                        f"or horizontal with support if L>{length}mm"
                    )
            elif ctype in ("housing", "frame"):
                orientations.append(
                    f"'{name}' (housing): print with largest flat face DOWN"
                )

    if orientations:
        result.checks_passed.append("print_orientation")
        result.findings.append(
            f"Print orientation recommendations: {len(orientations)}"
        )
        for o in orientations:
            result.findings.append(f"  - {o}")
    else:
        result.checks_passed.append("print_orientation")
        result.findings.append("Print orientation: no specific recommendations")


def _check_support_needs(result: "ConsultantResult", state: "ProjectState"):
    """Assess where supports will be needed."""
    components = state.components or state.spec.get("components", [])
    support_warnings = []

    for comp in components:
        if isinstance(comp, dict):
            ctype = comp.get("type", comp.get("component_type", ""))
            name = comp.get("display_name", comp.get("id", "?"))
            params = comp.get("parameters", {})

            # Parts with internal bores likely need support
            bore = params.get("bore", params.get("inner_diameter", 0))
            if bore > 10:
                support_warnings.append(
                    f"'{name}': bore {bore}mm may need support material "
                    f"(bridge > {FDM_THRESHOLDS['max_bridge_span']}mm)"
                )

            # Overhangs
            if params.get("has_overhang", False):
                support_warnings.append(
                    f"'{name}': has overhang features needing support"
                )

    if support_warnings:
        result.checks_passed.append("support_assessment")
        result.findings.append(f"Support assessment: {len(support_warnings)} part(s) may need support")
        for w in support_warnings:
            result.findings.append(f"  - {w}")
    else:
        result.checks_passed.append("support_assessment")
        result.findings.append("Support assessment: no obvious support needs")
