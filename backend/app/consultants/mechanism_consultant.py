"""
Mechanism Consultant — Gate 1 (Design).

Deterministic checks for mechanism feasibility:
- Grashof condition (four-bar linkages)
- Transmission angle range (40-140 deg)
- Dead point detection
- Coupler length constancy at 0/90/180/270 deg
"""

import math
import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.consultants.rule99_engine import ProjectState, ConsultantResult

logger = logging.getLogger(__name__)


def run(state: "ProjectState", checks: list[str]) -> "ConsultantResult":
    """Run mechanism consultant checks."""
    from app.consultants.rule99_engine import ConsultantResult

    result = ConsultantResult(name="mechanism", passed=True)
    spec = state.spec
    mechanism = state.mechanism_type or spec.get("mechanism_type", "")

    for check in checks:
        result.checks_run.append(check)

        if check == "grashof_condition":
            _check_grashof(result, spec, mechanism)
        elif check == "transmission_angle":
            _check_transmission_angle(result, spec, mechanism)
        elif check == "dead_point_detection":
            _check_dead_points(result, spec, mechanism)
        elif check == "coupler_constancy":
            _check_coupler_constancy(result, spec, mechanism)
        else:
            result.checks_passed.append(check)
            result.findings.append(f"Check '{check}' not implemented yet — skipped")

    return result


def _check_grashof(result: "ConsultantResult", spec: dict, mechanism: str):
    """
    Grashof condition: s + l <= p + q for continuous rotation.
    Only applies to four-bar linkages.
    """
    if mechanism not in ("four_bar", "linkage", "four_bar_linkage"):
        result.checks_passed.append("grashof_condition")
        result.findings.append("Grashof: N/A (not a four-bar linkage)")
        return

    links = spec.get("link_lengths", {})
    if not links:
        # Try individual link params
        ground = spec.get("ground_length", spec.get("frame_length", 0))
        crank = spec.get("crank_length", spec.get("input_length", 0))
        coupler = spec.get("coupler_length", 0)
        rocker = spec.get("rocker_length", spec.get("output_length", 0))
        lengths = [ground, crank, coupler, rocker]
    else:
        lengths = [
            links.get("ground", 0),
            links.get("crank", 0),
            links.get("coupler", 0),
            links.get("rocker", 0),
        ]

    lengths = [l for l in lengths if l > 0]

    if len(lengths) < 4:
        result.checks_passed.append("grashof_condition")
        result.findings.append("Grashof: insufficient link data (need 4 lengths)")
        return

    sorted_links = sorted(lengths)
    s, p, q, l = sorted_links[0], sorted_links[1], sorted_links[2], sorted_links[3]

    if s + l <= p + q:
        result.checks_passed.append("grashof_condition")
        result.findings.append(
            f"Grashof PASS: s+l={s+l:.1f} <= p+q={p+q:.1f} "
            f"(links: {sorted_links})"
        )
    else:
        result.checks_failed.append("grashof_condition")
        result.passed = False
        deficit = (s + l) - (p + q)
        result.findings.append(
            f"Grashof FAIL: s+l={s+l:.1f} > p+q={p+q:.1f} "
            f"(deficit: {deficit:.1f}mm)"
        )
        result.recommendations.append(
            f"Linkage cannot make full rotation. Shorten crank by {deficit:.1f}mm "
            f"or lengthen ground link."
        )


def _check_transmission_angle(result: "ConsultantResult", spec: dict, mechanism: str):
    """
    Transmission angle must be 40-140 deg for smooth motion.
    """
    if mechanism not in ("four_bar", "linkage", "four_bar_linkage", "slider_crank"):
        result.checks_passed.append("transmission_angle")
        result.findings.append("Transmission angle: N/A (not a linkage)")
        return

    min_angle = spec.get("min_transmission_angle")
    max_angle = spec.get("max_transmission_angle")

    if min_angle is None and max_angle is None:
        # Try to compute from link lengths
        links = spec.get("link_lengths", {})
        if links:
            angles = _compute_transmission_angles(links)
            if angles:
                min_angle, max_angle = min(angles), max(angles)

    if min_angle is None or max_angle is None:
        result.checks_passed.append("transmission_angle")
        result.findings.append(
            "Transmission angle: no data available — provide link lengths or angles"
        )
        return

    passed = min_angle >= 40 and max_angle <= 140
    if passed:
        result.checks_passed.append("transmission_angle")
        result.findings.append(
            f"Transmission angle PASS: {min_angle:.1f}-{max_angle:.1f} deg "
            f"(target: 40-140)"
        )
    else:
        result.checks_failed.append("transmission_angle")
        result.passed = False
        result.findings.append(
            f"Transmission angle FAIL: {min_angle:.1f}-{max_angle:.1f} deg "
            f"(target: 40-140)"
        )
        if min_angle < 40:
            result.recommendations.append(
                f"Minimum transmission angle {min_angle:.1f} deg is too small. "
                f"Adjust link ratios for smoother motion."
            )
        if max_angle > 140:
            result.recommendations.append(
                f"Maximum transmission angle {max_angle:.1f} deg is too large. "
                f"Adjust link ratios."
            )


def _check_dead_points(result: "ConsultantResult", spec: dict, mechanism: str):
    """
    Dead points: positions where mechanism jams (force perpendicular to motion).
    """
    if mechanism not in ("four_bar", "linkage", "slider_crank"):
        result.checks_passed.append("dead_point_detection")
        result.findings.append("Dead points: N/A (not a linkage)")
        return

    dead_points = spec.get("dead_points", [])
    has_flywheel = spec.get("has_flywheel", False)
    has_parallel_crank = spec.get("parallel_crank", False)

    if not dead_points:
        result.checks_passed.append("dead_point_detection")
        result.findings.append("Dead points: none detected or not computed")
        return

    if has_flywheel or has_parallel_crank:
        result.checks_passed.append("dead_point_detection")
        result.findings.append(
            f"Dead points at angles {dead_points} — mitigated by "
            f"{'flywheel' if has_flywheel else 'parallel crank'}"
        )
    else:
        result.checks_failed.append("dead_point_detection")
        result.passed = False
        result.findings.append(
            f"Dead points at angles {dead_points} — NO mitigation"
        )
        result.recommendations.append(
            "Add flywheel or parallel crank to carry through dead points. "
            "Or redesign to avoid dead points in operating range."
        )


def _check_coupler_constancy(result: "ConsultantResult", spec: dict, mechanism: str):
    """
    Coupler length must be constant at 0/90/180/270 deg.
    Variable coupler = impossible mechanism (stretching links).
    """
    if mechanism not in ("four_bar", "linkage"):
        result.checks_passed.append("coupler_constancy")
        result.findings.append("Coupler constancy: N/A")
        return

    coupler_lengths_at_angles = spec.get("coupler_at_angles", {})
    if not coupler_lengths_at_angles:
        result.checks_passed.append("coupler_constancy")
        result.findings.append("Coupler constancy: not verified (no angle data)")
        return

    nominal = spec.get("coupler_length", 0)
    if nominal == 0 and coupler_lengths_at_angles:
        nominal = list(coupler_lengths_at_angles.values())[0]

    max_deviation = 0.0
    for angle, length in coupler_lengths_at_angles.items():
        deviation = abs(length - nominal)
        max_deviation = max(max_deviation, deviation)

    tolerance = 0.01 * nominal  # 1% tolerance
    if max_deviation <= tolerance:
        result.checks_passed.append("coupler_constancy")
        result.findings.append(
            f"Coupler constancy PASS: max deviation {max_deviation:.3f}mm "
            f"(tolerance: {tolerance:.3f}mm)"
        )
    else:
        result.checks_failed.append("coupler_constancy")
        result.passed = False
        result.findings.append(
            f"Coupler constancy FAIL: max deviation {max_deviation:.3f}mm "
            f"(tolerance: {tolerance:.3f}mm)"
        )
        result.recommendations.append(
            "Coupler link is stretching — impossible mechanism. "
            "Check that all four pivot points are correctly positioned."
        )


def _compute_transmission_angles(links: dict) -> list[float]:
    """Compute transmission angles at 0/90/180/270 deg crank position."""
    a = links.get("ground", 0)
    b = links.get("crank", 0)
    c = links.get("coupler", 0)
    d = links.get("rocker", 0)

    if not all([a, b, c, d]):
        return []

    angles = []
    for theta_deg in [0, 90, 180, 270]:
        theta = math.radians(theta_deg)
        # Coupler-rocker angle via law of cosines
        # Diagonal from crank tip to rocker pivot
        diag_sq = a**2 + b**2 - 2*a*b*math.cos(theta)
        diag = math.sqrt(max(diag_sq, 0.001))

        # Transmission angle = angle at coupler-rocker joint
        cos_mu = (c**2 + d**2 - diag_sq) / (2*c*d) if c*d > 0 else 0
        cos_mu = max(-1, min(1, cos_mu))
        mu = math.degrees(math.acos(cos_mu))
        angles.append(mu)

    return angles
