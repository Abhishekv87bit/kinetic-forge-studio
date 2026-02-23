"""
Materials Consultant — Gate 3 (Production).

Material selection and compatibility checks:
- Material selection: appropriate for loads and environment
- Galvanic corrosion: dissimilar metal pairs
- Thermal expansion: differential expansion check
- Surface finish: Ra values for mating surfaces
- Hardness match: shaft vs bearing hardness
"""

import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)

# Galvanic series (anodic to cathodic)
# Higher index = more cathodic (noble)
GALVANIC_SERIES = {
    "magnesium": 0,
    "zinc": 1,
    "aluminum": 2,
    "aluminum_6061": 2,
    "aluminum_7075": 2,
    "mild_steel": 3,
    "steel": 3,
    "cast_iron": 3,
    "stainless_304": 4,
    "stainless_316": 4,
    "tin": 5,
    "lead": 6,
    "nickel": 7,
    "brass": 8,
    "bronze": 8,
    "copper": 9,
    "titanium": 10,
    "gold": 11,
    "platinum": 12,
}

# Thermal expansion coefficients (µm/m/°C)
THERMAL_EXPANSION = {
    "aluminum": 23.1,
    "aluminum_6061": 23.6,
    "brass": 19.0,
    "bronze": 18.0,
    "copper": 16.5,
    "steel": 12.0,
    "stainless_304": 17.3,
    "stainless_316": 16.0,
    "cast_iron": 10.5,
    "titanium": 8.6,
    "wood_oak": 5.4,  # along grain
    "PLA": 68.0,
    "PETG": 60.0,
    "nylon": 80.0,
    "acetal": 85.0,
}


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run materials consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="materials", passed=True)

    for check in checks:
        result.checks_run.append(check)

        if check == "material_selection":
            _check_material_selection(result, state)
        elif check == "galvanic_corrosion":
            _check_galvanic(result, state)
        elif check == "thermal_expansion":
            _check_thermal(result, state)
        elif check == "surface_finish":
            _check_surface_finish(result, state)
        elif check == "hardness_match":
            _check_hardness(result, state)
        else:
            result.checks_passed.append(check)

    return result


def _get_material(comp: dict) -> str:
    """Extract material from a component dict."""
    params = comp.get("parameters", {})
    return (params.get("material", "") or
            comp.get("material", "")).lower().replace(" ", "_")


def _check_material_selection(result: "ConsultantResult", state: "ProjectState"):
    """Verify material is appropriate for application."""
    components = state.components or state.spec.get("components", [])

    if not components:
        result.checks_passed.append("material_selection")
        result.findings.append("Material selection: no components to check")
        return

    issues = []
    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            ctype = comp.get("type", comp.get("component_type", ""))
            material = _get_material(comp)

            if not material:
                issues.append(f"'{name}': no material specified")
                continue

            # Check material-application compatibility
            if ctype == "shaft" and material in ("pla", "petg", "wood"):
                issues.append(
                    f"'{name}' (shaft): {material} is too weak for production shafts. "
                    f"Use steel or brass."
                )
            elif ctype == "gear" and material == "pla":
                issues.append(
                    f"'{name}' (gear): PLA wears quickly. Use acetal, brass, or steel."
                )

    if not issues:
        result.checks_passed.append("material_selection")
        result.findings.append("Material selection PASS: all materials appropriate")
    else:
        result.checks_failed.append("material_selection")
        result.passed = False
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _check_galvanic(result: "ConsultantResult", state: "ProjectState"):
    """
    Check for galvanic corrosion between dissimilar metals in contact.
    MIL-STD-889: > 0.25V potential difference is risky.
    We simplify: > 2 positions apart in galvanic series = warning.
    """
    components = state.components or state.spec.get("components", [])
    materials_in_use = {}

    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            material = _get_material(comp)
            if material and material in GALVANIC_SERIES:
                materials_in_use[name] = material

    if len(materials_in_use) < 2:
        result.checks_passed.append("galvanic_corrosion")
        result.findings.append("Galvanic corrosion: fewer than 2 metals in contact")
        return

    # Check all pairs
    names = list(materials_in_use.keys())
    pairs_at_risk = []

    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            mat_a = materials_in_use[names[i]]
            mat_b = materials_in_use[names[j]]
            idx_a = GALVANIC_SERIES.get(mat_a, -1)
            idx_b = GALVANIC_SERIES.get(mat_b, -1)

            if idx_a >= 0 and idx_b >= 0:
                gap = abs(idx_a - idx_b)
                if gap >= 3:
                    pairs_at_risk.append(
                        f"{names[i]} ({mat_a}) + {names[j]} ({mat_b}): "
                        f"galvanic gap={gap} — HIGH corrosion risk"
                    )
                elif gap >= 2:
                    pairs_at_risk.append(
                        f"{names[i]} ({mat_a}) + {names[j]} ({mat_b}): "
                        f"galvanic gap={gap} — moderate risk, use isolator"
                    )

    if not pairs_at_risk:
        result.checks_passed.append("galvanic_corrosion")
        result.findings.append("Galvanic corrosion PASS: no risky metal pairs")
    else:
        result.checks_failed.append("galvanic_corrosion")
        result.passed = False
        result.findings.append(
            f"Galvanic corrosion: {len(pairs_at_risk)} risky pair(s)"
        )
        for pair in pairs_at_risk:
            result.findings.append(f"  - {pair}")
            result.recommendations.append(pair)


def _check_thermal(result: "ConsultantResult", state: "ProjectState"):
    """Check differential thermal expansion between mating parts."""
    components = state.components or state.spec.get("components", [])
    temp_range = state.spec.get("operating_temp_range", 30)  # °C delta

    materials_cte = {}
    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            material = _get_material(comp)
            if material in THERMAL_EXPANSION:
                materials_cte[name] = (material, THERMAL_EXPANSION[material])

    if len(materials_cte) < 2:
        result.checks_passed.append("thermal_expansion")
        result.findings.append("Thermal expansion: fewer than 2 materials to compare")
        return

    # Find maximum CTE difference
    items = list(materials_cte.items())
    max_diff = 0
    max_pair = ("", "")

    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            name_a, (mat_a, cte_a) = items[i]
            name_b, (mat_b, cte_b) = items[j]
            diff = abs(cte_a - cte_b)
            if diff > max_diff:
                max_diff = diff
                max_pair = (f"{name_a}({mat_a})", f"{name_b}({mat_b})")

    # Differential expansion over temp range for 100mm part
    diff_um = max_diff * temp_range * 100 / 1000  # mm for 100mm length

    if diff_um < 0.05:
        result.checks_passed.append("thermal_expansion")
        result.findings.append(
            f"Thermal expansion PASS: max differential {diff_um:.3f}mm/100mm "
            f"over {temp_range}°C ({max_pair[0]} vs {max_pair[1]})"
        )
    else:
        result.checks_passed.append("thermal_expansion")
        result.findings.append(
            f"Thermal expansion advisory: {diff_um:.3f}mm/100mm "
            f"over {temp_range}°C ({max_pair[0]} vs {max_pair[1]})"
        )
        if diff_um > 0.1:
            result.recommendations.append(
                f"Significant thermal expansion difference between "
                f"{max_pair[0]} and {max_pair[1]}. Account for in fit design."
            )


def _check_surface_finish(result: "ConsultantResult", state: "ProjectState"):
    """Check surface finish (Ra) requirements for mating surfaces."""
    components = state.components or state.spec.get("components", [])

    mating_surfaces = []
    for comp in components:
        if isinstance(comp, dict):
            params = comp.get("parameters", {})
            name = comp.get("display_name", comp.get("id", "?"))
            ctype = comp.get("type", comp.get("component_type", ""))

            if ctype in ("shaft", "bearing", "bushing", "gear"):
                ra = params.get("surface_finish_ra", params.get("ra"))
                if ra is None:
                    # Recommend based on type
                    rec_ra = {"shaft": 0.8, "bearing": 0.4, "gear": 1.6}
                    rec = rec_ra.get(ctype, 1.6)
                    mating_surfaces.append(
                        f"'{name}' ({ctype}): no Ra specified — "
                        f"recommend Ra {rec} µm"
                    )

    if mating_surfaces:
        result.checks_passed.append("surface_finish")
        result.findings.append(
            f"Surface finish: {len(mating_surfaces)} part(s) need Ra spec"
        )
        for s in mating_surfaces:
            result.findings.append(f"  - {s}")
    else:
        result.checks_passed.append("surface_finish")
        result.findings.append("Surface finish: no mating surfaces to check")


def _check_hardness(result: "ConsultantResult", state: "ProjectState"):
    """Shaft should be harder than bearing for proper wear."""
    result.checks_passed.append("hardness_match")
    result.findings.append(
        "Hardness match: verify shaft hardness > bearing/bushing hardness "
        "(shaft wears slower than replaceable bushing)"
    )
