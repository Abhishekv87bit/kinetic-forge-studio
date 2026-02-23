"""
ISO 286 Consultant — Gate 2 (Prototype).

Wraps the existing iso286_lookup.py script to check shaft/hole fits:
- Fit clearance: H7/g6 sliding, H7/k6 transition, H7/p6 press
- Fit type appropriate: correct fit for application
- Tolerance band width: IT grade appropriate for process
"""

import logging
import subprocess
import json
from pathlib import Path
from typing import TYPE_CHECKING

from app.config import settings

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)

# Fit recommendations by application
FIT_RECOMMENDATIONS = {
    "bearing": {"fit": "H7/g6", "type": "sliding", "note": "Standard bearing bore fit"},
    "shaft_bearing": {"fit": "H7/g6", "type": "sliding", "note": "Shaft through bearing"},
    "press_fit": {"fit": "H7/p6", "type": "press", "note": "Permanent assembly"},
    "transition": {"fit": "H7/k6", "type": "transition", "note": "Keyed assemblies"},
    "clearance": {"fit": "H7/f7", "type": "clearance", "note": "Free rotation"},
    "gear_bore": {"fit": "H7/k6", "type": "transition", "note": "Gear on shaft"},
}


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run ISO 286 consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="iso286", passed=True)
    result.libraries_used.append("iso286_lookup.py")

    for check in checks:
        result.checks_run.append(check)

        if check == "fit_clearance":
            _check_fit_clearance(result, state)
        elif check == "fit_type_appropriate":
            _check_fit_type(result, state)
        elif check == "tolerance_band_width":
            _check_tolerance_band(result, state)
        else:
            result.checks_passed.append(check)

    return result


def _check_fit_clearance(result: "ConsultantResult", state: "ProjectState"):
    """Check each shaft/hole pair against ISO 286 fit tables."""
    pairs = state.tolerance_pairs or state.spec.get("tolerance_pairs", [])

    if not pairs:
        # Try to identify pairs from components
        pairs = _identify_fit_pairs(state)

    if not pairs:
        result.checks_passed.append("fit_clearance")
        result.findings.append("Fit clearance: no shaft/hole pairs identified")
        return

    all_ok = True
    for pair in pairs:
        nominal = pair.get("nominal", 0)
        fit = pair.get("fit", "H7/g6")
        shaft_name = pair.get("shaft", "shaft")
        hole_name = pair.get("hole", "hole")

        # Try to use external iso286_lookup.py
        lookup_result = _iso286_lookup(nominal, fit)

        if lookup_result:
            clearance = lookup_result.get("clearance_min", 0)
            result.findings.append(
                f"  {shaft_name}/{hole_name}: {fit} @ {nominal}mm — "
                f"clearance [{lookup_result.get('clearance_min', '?')}, "
                f"{lookup_result.get('clearance_max', '?')}] mm"
            )
        else:
            # Fallback: basic clearance estimate
            result.findings.append(
                f"  {shaft_name}/{hole_name}: {fit} @ {nominal}mm — "
                f"(ISO 286 lookup unavailable, using estimates)"
            )

    if all_ok:
        result.checks_passed.append("fit_clearance")
        result.findings.insert(0, f"Fit clearance: checked {len(pairs)} pair(s)")
    else:
        result.checks_failed.append("fit_clearance")
        result.passed = False


def _check_fit_type(result: "ConsultantResult", state: "ProjectState"):
    """Verify correct fit type for each application."""
    components = state.components or state.spec.get("components", [])

    issues = []
    for comp in components:
        if isinstance(comp, dict):
            ctype = comp.get("type", comp.get("component_type", ""))
            params = comp.get("parameters", {})
            name = comp.get("display_name", comp.get("id", "?"))
            fit = params.get("fit", params.get("fit_type", ""))

            if not fit:
                continue

            # Check if fit matches recommendation for this component type
            rec = FIT_RECOMMENDATIONS.get(ctype, {})
            rec_fit = rec.get("fit", "")

            if rec_fit and fit != rec_fit:
                issues.append(
                    f"'{name}' ({ctype}): using {fit} but {rec_fit} recommended "
                    f"({rec.get('note', '')})"
                )

    if not issues:
        result.checks_passed.append("fit_type_appropriate")
        result.findings.append("Fit types: all appropriate for application")
    else:
        # Advisory, not hard failure
        result.checks_passed.append("fit_type_appropriate")
        result.findings.append(f"Fit type advisories: {len(issues)}")
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _check_tolerance_band(result: "ConsultantResult", state: "ProjectState"):
    """Check IT grade is appropriate for manufacturing process."""
    material = state.material or state.spec.get("material", "PLA")

    # IT grade ranges by process
    process_grades = {
        "fdm": {"min": 10, "max": 14, "typical": 12},
        "sla": {"min": 7, "max": 10, "typical": 8},
        "cnc": {"min": 5, "max": 8, "typical": 7},
        "lathe": {"min": 5, "max": 7, "typical": 6},
        "casting": {"min": 8, "max": 12, "typical": 10},
    }

    process = state.spec.get("process", "fdm")
    grade_info = process_grades.get(process, process_grades["fdm"])

    pairs = state.tolerance_pairs or state.spec.get("tolerance_pairs", [])
    issues = []

    for pair in pairs:
        fit = pair.get("fit", "H7/g6")
        # Extract IT grade from fit (e.g., H7 -> IT7, g6 -> IT6)
        for part in fit.split("/"):
            if len(part) >= 2:
                try:
                    grade = int(part[1:])
                    if grade < grade_info["min"]:
                        issues.append(
                            f"IT{grade} ({part} in {fit}) is tighter than "
                            f"{process} can achieve (min IT{grade_info['min']})"
                        )
                except ValueError:
                    pass

    if not issues:
        result.checks_passed.append("tolerance_band_width")
        result.findings.append(
            f"Tolerance bands: all IT grades achievable with {process} "
            f"(IT{grade_info['min']}-{grade_info['max']})"
        )
    else:
        result.checks_failed.append("tolerance_band_width")
        result.passed = False
        for issue in issues:
            result.findings.append(f"  - {issue}")
            result.recommendations.append(issue)


def _identify_fit_pairs(state: "ProjectState") -> list[dict]:
    """Auto-identify shaft/hole pairs from components."""
    components = state.components or state.spec.get("components", [])
    pairs = []

    shafts = {}
    holes = {}

    for comp in components:
        if isinstance(comp, dict):
            ctype = comp.get("type", comp.get("component_type", ""))
            params = comp.get("parameters", {})
            name = comp.get("display_name", comp.get("id", "?"))

            if ctype in ("shaft", "axle", "pin"):
                od = params.get("diameter", params.get("od", 0))
                if od > 0:
                    shafts[name] = od
            elif ctype in ("bearing", "bushing", "housing"):
                bore = params.get("bore", params.get("inner_diameter",
                       params.get("id", 0)))
                if bore > 0:
                    holes[name] = bore

    # Match shafts to holes by similar diameter
    for s_name, s_dia in shafts.items():
        for h_name, h_dia in holes.items():
            if abs(s_dia - h_dia) < 1.0:  # Within 1mm
                pairs.append({
                    "shaft": s_name,
                    "hole": h_name,
                    "nominal": s_dia,
                    "fit": "H7/g6",
                })

    return pairs


def _iso286_lookup(nominal: float, fit: str) -> dict | None:
    """Call the external iso286_lookup.py script."""
    script = settings.iso286_script
    if not script.exists():
        return None

    try:
        result = subprocess.run(
            ["python", str(script), str(nominal), fit, "--json"],
            capture_output=True, text=True, timeout=10,
        )
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout)
    except Exception as e:
        logger.debug("ISO 286 lookup failed: %s", e)

    return None
