"""FDM Ground Truth validator — identifies critical fits, recommends test prints."""

from __future__ import annotations


_SHAFT_KEYWORDS = {"shaft", "axle", "spindle", "pin", "dowel"}
_BEARING_KEYWORDS = {"bearing", "bushing", "sleeve", "journal"}
_GEAR_KEYWORDS = {"gear", "pinion", "spur", "helical", "mesh"}


def identify_critical_fits(components: list[dict]) -> list[dict]:
    """Identify component pairs that have critical fit interfaces."""
    critical_fits = []

    for comp in components:
        comp_id = comp.get("id", "")
        comp_type = comp.get("type", comp.get("component_type", "")).lower()
        params = comp.get("parameters", {})
        display = comp.get("display_name", comp_id).lower()

        if any(kw in display or kw in comp_type for kw in _SHAFT_KEYWORDS):
            critical_fits.append({
                "component": comp_id,
                "fit_type": "shaft",
                "diameter": params.get("diameter", params.get("shaft_diameter", "unknown")),
                "recommendation": "Test coupon: cylinder at specified diameter +/- 0.05mm increments",
            })

        if any(kw in display or kw in comp_type for kw in _BEARING_KEYWORDS):
            critical_fits.append({
                "component": comp_id,
                "fit_type": "bearing_seat",
                "bore": params.get("bore", params.get("inner_diameter", "unknown")),
                "od": params.get("od", params.get("outer_diameter", "unknown")),
                "recommendation": "Test coupon: bore at spec +/- 0.05mm, OD pocket at spec +/- 0.05mm",
            })

        if any(kw in display or kw in comp_type for kw in _GEAR_KEYWORDS):
            critical_fits.append({
                "component": comp_id,
                "fit_type": "gear_mesh",
                "module": params.get("module", "unknown"),
                "teeth": params.get("teeth", params.get("num_teeth", "unknown")),
                "recommendation": "Test coupon: 3-tooth gear segment, verify mesh with mating gear",
            })

    return critical_fits


def generate_test_coupons(critical_fits: list[dict]) -> list[dict]:
    """Generate test coupon specifications from critical fit list."""
    coupons = []

    for fit in critical_fits:
        fit_type = fit.get("fit_type", "unknown")

        if fit_type == "shaft":
            diameter = fit.get("diameter", 0)
            if diameter and diameter != "unknown":
                d = float(diameter)
                coupons.append({
                    "name": f"shaft_test_{fit['component']}",
                    "type": "cylinder_array",
                    "description": f"5 cylinders: {d-0.1:.2f}, {d-0.05:.2f}, {d:.2f}, {d+0.05:.2f}, {d+0.1:.2f}mm",
                    "print_time_est": "15 min",
                    "purpose": "Find actual clearance for your printer",
                })

        elif fit_type == "bearing_seat":
            bore = fit.get("bore", 0)
            if bore and bore != "unknown":
                b = float(bore)
                coupons.append({
                    "name": f"bearing_test_{fit['component']}",
                    "type": "bore_array",
                    "description": f"5 bores: {b-0.1:.2f}, {b-0.05:.2f}, {b:.2f}, {b+0.05:.2f}, {b+0.1:.2f}mm",
                    "print_time_est": "20 min",
                    "purpose": "Find press-fit vs slip-fit threshold for your printer",
                })

        elif fit_type == "gear_mesh":
            coupons.append({
                "name": f"gear_test_{fit['component']}",
                "type": "gear_segment",
                "description": f"3-tooth segment, module={fit.get('module', '?')}",
                "print_time_est": "10 min",
                "purpose": "Verify tooth profile prints cleanly and meshes smoothly",
            })

    return coupons
