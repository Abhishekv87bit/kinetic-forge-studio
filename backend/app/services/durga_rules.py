"""SC-06 Durga Pattern — deterministic repair rules.

Each DeterministicRule pairs an error-message regex pattern with an ``apply``
callable that transforms the broken code into a (hopefully) fixed version.

Rules are tried in order; the first match wins.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Callable, Optional


@dataclass
class DeterministicRule:
    """A single deterministic repair rule.

    Attributes:
        name:          Unique slug used in RepairResult.rule_name.
        error_pattern: Regex matched against the raw error string (re.search).
        description:   Human-readable explanation of what the rule fixes.
        apply:         Callable(code, error, match) -> fixed_code.
    """

    name: str
    error_pattern: str
    description: str
    apply: Callable[[str, str, re.Match], str]


# ---------------------------------------------------------------------------
# Individual fix functions
# ---------------------------------------------------------------------------


def _prepend_cq_import(code: str, error: str, match: re.Match) -> str:
    """Prepend ``import cadquery as cq`` when the name ``cq`` is absent."""
    if "import cadquery as cq" in code:
        return code
    return f"import cadquery as cq\n{code}"


def _remove_show_object(code: str, error: str, match: re.Match) -> str:
    """Strip ``show_object(...)`` calls — only valid inside CQ-editor."""
    lines = [
        line for line in code.splitlines()
        if not line.strip().startswith("show_object")
    ]
    return "\n".join(lines)


def _normalize_workplane(code: str, error: str, match: re.Match) -> str:
    """Capitalise lowercase workplane string literals ("xy" → "XY", etc.)."""
    fixed = code
    for lower, upper in [("'xy'", "'XY'"), ('"xy"', '"XY"'),
                         ("'xz'", "'XZ'"), ('"xz"', '"XZ"'),
                         ("'yz'", "'YZ'"), ('"yz"', '"YZ"')]:
        fixed = fixed.replace(lower, upper)
    return fixed


def _fix_missing_result_val(code: str, error: str, match: re.Match) -> str:
    """Replace bare ``result`` export with ``result.val()`` where needed."""
    # Only touches the final assignment pattern `result = ...; result.val()`
    # by appending .val() to the last line that assigns to `result`
    lines = code.splitlines()
    for i in reversed(range(len(lines))):
        stripped = lines[i].strip()
        if stripped.startswith("result =") and not stripped.endswith(".val()"):
            lines[i] = lines[i].rstrip() + ".val()"
            break
    return "\n".join(lines)


def _add_missing_result_assignment(code: str, error: str, match: re.Match) -> str:
    """Append ``result = r`` when the script never assigns ``result``."""
    if "result" not in code:
        # heuristic: grab last assigned name ending with common CQ variable names
        for varname in ("r", "solid", "shape", "part", "body"):
            if f"{varname} =" in code:
                return code + f"\nresult = {varname}"
    return code


def _halve_fillet_radii(code: str, error: str, match: re.Match) -> str:
    """Halve all numeric fillet radii to recover from BRep topology failures.

    ``BRep_API: command not done`` / ``StdFail_NotDone`` occur when the fillet
    radius exceeds the length of an adjacent edge.  Halving is the minimal safe
    fix that preserves the intent while making the radius geometrically feasible.
    """
    fillet_re = re.compile(r"(\.fillet\(\s*)(\d+(?:\.\d+)?)(\s*\))")

    def _halve(m: re.Match) -> str:
        val = float(m.group(2))
        return f"{m.group(1)}{val / 2:.6g}{m.group(3)}"

    return fillet_re.sub(_halve, code)


def _halve_chamfer_distances(code: str, error: str, match: re.Match) -> str:
    """Halve all numeric chamfer distances to recover from BRep topology failures."""
    chamfer_re = re.compile(r"(\.chamfer\(\s*)(\d+(?:\.\d+)?)(\s*\))")

    def _halve(m: re.Match) -> str:
        val = float(m.group(2))
        return f"{m.group(1)}{val / 2:.6g}{m.group(3)}"

    return chamfer_re.sub(_halve, code)


def _double_shell_thickness(code: str, error: str, match: re.Match) -> str:
    """Double ``.shell()`` thickness to resolve zero-thickness wall errors.

    A ``zero thickness`` / ``StdFail_NotDone`` error on a shell operation
    means the requested wall is too thin relative to the curvature.  Doubling
    preserves the sign (inward vs outward offset) while making it feasible.
    """
    shell_re = re.compile(r"(\.shell\(\s*)([-]?)(\d+(?:\.\d+)?)(\s*\))")

    def _double(m: re.Match) -> str:
        sign = m.group(2)
        val = float(m.group(3))
        return f"{m.group(1)}{sign}{val * 2:.6g}{m.group(4)}"

    return shell_re.sub(_double, code)


# ---------------------------------------------------------------------------
# Rule registry — tried in order, first match wins
# ---------------------------------------------------------------------------

DETERMINISTIC_RULES: list[DeterministicRule] = [
    DeterministicRule(
        name="missing_cq_import",
        error_pattern=r"NameError: name 'cq' is not defined",
        description="Add missing 'import cadquery as cq' at top of script",
        apply=_prepend_cq_import,
    ),
    DeterministicRule(
        name="show_object_undefined",
        error_pattern=r"NameError: name 'show_object' is not defined",
        description="Remove show_object() calls — not valid outside CQ-editor",
        apply=_remove_show_object,
    ),
    DeterministicRule(
        name="invalid_workplane_case",
        error_pattern=r"ValueError:.*[Ww]orkplane",
        description="Capitalise lowercase workplane string literals (xy→XY)",
        apply=_normalize_workplane,
    ),
    DeterministicRule(
        name="missing_result_val",
        error_pattern=r"AttributeError:.*has no attribute 'val'",
        description="Append .val() to the last result assignment",
        apply=_fix_missing_result_val,
    ),
    DeterministicRule(
        name="result_name_not_defined",
        error_pattern=r"NameError: name 'result' is not defined",
        description="Add result assignment from last known shape variable",
        apply=_add_missing_result_assignment,
    ),
    DeterministicRule(
        name="fillet_too_large",
        description="Halve fillet radii when OCCT BRep topology check fails",
        error_pattern=r"BRep_API[:\s].*command not done|StdFail_NotDone",
        apply=_halve_fillet_radii,
    ),
    DeterministicRule(
        name="chamfer_too_large",
        description="Halve chamfer distances when OCCT BRep topology check fails",
        error_pattern=r"BRep_API[:\s].*command not done|StdFail_NotDone",
        apply=_halve_chamfer_distances,
    ),
    DeterministicRule(
        name="zero_thickness_shell",
        description="Double shell() thickness to resolve zero-thickness wall errors",
        error_pattern=r"zero.?thickness|StdFail_NotDone",
        apply=_double_shell_thickness,
    ),
]
