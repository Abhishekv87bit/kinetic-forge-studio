"""
Traceability & Consistency Audit — Triple Helix MVP V5.5
=========================================================
Catches DRIFT: when files, comments, checkpoint snapshots, and documentation
get out of sync with the actual design source of truth (config_v5_5.scad).

Distinct from:
  - v5_5_math_validation.py  (checks formulas / physics)
  - validate_geometry.py     (checks clearances / geometry)

This script checks CONSISTENCY across files.

Usage:
    python consistency_audit.py                 # run audit
    python consistency_audit.py --fix-checkpoint  # copy working files to checkpoint
    python consistency_audit.py --verbose        # show extra detail on passes

Exit code: 0 if no FAILs, 1 if any FAILs.
"""

import sys
import os
import re
import shutil
import argparse
from pathlib import Path

# ================================================================
# PATH SETUP
# ================================================================
# Script lives in 5.5/; base is one level up.
SCRIPT_DIR = Path(__file__).resolve().parent
BASE_DIR = SCRIPT_DIR.parent                              # triple_helix_mvp/
WORKING_DIR = SCRIPT_DIR                                   # 5.5/
CHECKPOINT_SUB = BASE_DIR / "check point" / "5.5"         # check point/5.5/
CHECKPOINT_FLAT = BASE_DIR / "check point"                 # check point/ (flat)
MACHINE_STATE_MD = BASE_DIR / "MACHINE_STATE_DIAGRAM.md"

# ================================================================
# RESULT TRACKING
# ================================================================
_results = []  # list of (status, section, message) where status in {PASS, FAIL, WARN}


def _pass(section, msg):
    _results.append(("PASS", section, msg))


def _fail(section, msg):
    _results.append(("FAIL", section, msg))


def _warn(section, msg):
    _results.append(("WARN", section, msg))


# ================================================================
# HELPERS
# ================================================================

def file_stats(path):
    """Return (size_bytes, line_count) for a text file, or None if missing."""
    if not path.is_file():
        return None
    try:
        size = path.stat().st_size
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            lines = sum(1 for _ in f)
        return (size, lines)
    except Exception:
        return None


def parse_scad_assignments(filepath):
    """
    Parse top-level OpenSCAD variable assignments from a file.
    Returns dict of { VAR_NAME: (raw_value_string, line_number) }.
    Handles:  VARNAME = <value>;
    Skips lines starting with // or inside /* ... */ blocks.
    """
    assignments = {}
    if not filepath.is_file():
        return assignments
    in_block_comment = False
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        for lineno, line in enumerate(f, start=1):
            stripped = line.strip()
            # Block comment tracking
            if in_block_comment:
                if "*/" in stripped:
                    in_block_comment = False
                continue
            if "/*" in stripped:
                if "*/" not in stripped:
                    in_block_comment = True
                continue
            if stripped.startswith("//"):
                continue
            # Match: NAME = value ;
            m = re.match(r'^([A-Z_][A-Z0-9_]*)\s*=\s*([^;]+);', stripped)
            if m:
                var_name = m.group(1)
                var_value = m.group(2).strip()
                assignments[var_name] = (var_value, lineno)
    return assignments


def parse_python_assignments(filepath):
    """
    Parse top-level Python variable assignments.
    Returns dict of { VAR_NAME: (raw_value_string, line_number) }.
    """
    assignments = {}
    if not filepath.is_file():
        return assignments
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        for lineno, line in enumerate(f, start=1):
            stripped = line.strip()
            if stripped.startswith("#") or stripped.startswith("def ") or stripped.startswith("class "):
                continue
            m = re.match(r'^([A-Z_][A-Z0-9_]*)\s*=\s*(.+)', stripped)
            if m:
                var_name = m.group(1)
                var_value = m.group(2).strip()
                # Remove trailing comment
                if "  #" in var_value:
                    var_value = var_value[:var_value.index("  #")].strip()
                assignments[var_name] = (var_value, lineno)
    return assignments


def try_eval_numeric(raw):
    """
    Try to evaluate a raw value string as a numeric.
    Returns float or None.
    """
    # Strip trailing comments from scad values
    raw = raw.strip()
    # Common scad patterns that won't eval in Python
    if any(kw in raw for kw in ["sqrt(", "sin(", "cos(", "tan(", "floor(", "ceil(",
                                  "abs(", "max(", "min(", "let(", "for ",
                                  "[", "function", "PI"]):
        return None
    # Replace known scad -> python
    cleaned = raw.replace("true", "True").replace("false", "False")
    try:
        val = float(eval(cleaned, {"__builtins__": {}}, {}))
        return val
    except Exception:
        pass
    # Try direct float parse
    try:
        return float(raw)
    except ValueError:
        return None


def extract_comment_numbers(line):
    """
    From a line like 'CH_GAP = 6.5;  // 4.0mm gap'
    extract all numbers from the comment portion.
    Returns list of floats found after //.
    """
    if "//" not in line:
        return []
    comment = line[line.index("//"):]
    return [float(m) for m in re.findall(r'(?<!\w)(\d+\.?\d*)', comment)]


# ================================================================
# SECTION 1: CHECKPOINT DRIFT (5.5/ vs check point/5.5/)
# ================================================================

def audit_checkpoint_drift(section_name, working_dir, checkpoint_dir, v55_only=False):
    """
    Compare files that exist in both working_dir and checkpoint_dir.
    If v55_only=True, only check v5_5 files in the reverse direction
    (avoids noise from old-version files in the flat checkpoint).
    """
    if not checkpoint_dir.is_dir():
        _warn(section_name, f"Checkpoint directory does not exist: {checkpoint_dir}")
        return

    # Gather files of interest from working dir
    working_files = sorted(
        p for p in working_dir.iterdir()
        if p.is_file() and p.suffix in (".scad", ".py")
    )
    any_compared = False
    for wf in working_files:
        cf = checkpoint_dir / wf.name
        if not cf.is_file():
            _warn(section_name, f"{wf.name} -- exists in working dir but NOT in checkpoint")
            continue

        ws = file_stats(wf)
        cs = file_stats(cf)
        if ws is None or cs is None:
            _warn(section_name, f"{wf.name} -- could not read one or both copies")
            continue

        any_compared = True
        w_size, w_lines = ws
        c_size, c_lines = cs

        if w_size == c_size and w_lines == c_lines:
            _pass(section_name, f"{wf.name} -- working ({w_lines} lines, {w_size}B) matches checkpoint")
        else:
            _fail(section_name,
                  f"{wf.name} -- STALE: working ({w_lines} lines, {w_size}B) "
                  f"vs checkpoint ({c_lines} lines, {c_size}B)")

    # Also check for files in checkpoint that are NOT in working dir.
    # For flat checkpoint, only check v5_5 files to avoid noise from old versions.
    if checkpoint_dir.is_dir():
        for cf in sorted(checkpoint_dir.iterdir()):
            if cf.is_file() and cf.suffix in (".scad", ".py"):
                if v55_only and "v5_5" not in cf.name and "v5.5" not in cf.name.lower():
                    continue
                wf = working_dir / cf.name
                if not wf.is_file():
                    _warn(section_name, f"{cf.name} -- in checkpoint but NOT in working dir")

    if not any_compared:
        _warn(section_name, "No matching files found between working dir and checkpoint")


# ================================================================
# SECTION 3: PARAMETER CONSISTENCY
# ================================================================

# Key parameters to cross-check. Each entry:
#   (config_var_name, [list of (filename_label, expected_evaluator)])
# We check the *numeric* value if possible, otherwise just check existence.

KEY_PARAMS = [
    "HEX_R", "NUM_CHANNELS", "STACK_OFFSET", "CH_GAP", "WALL_THICKNESS",
    "SHAFT_DIA", "DISC_OD", "ECCENTRICITY",
    "FP_OD", "SP_OD", "FP_ROW_Y",
    "TIER_PITCH", "HOUSING_HEIGHT",
    "FRAME_BRG_ID", "FRAME_BRG_OD", "FRAME_BRG_W",
    "CAM_BRG_ID", "CAM_BRG_OD", "CAM_BRG_W",
    "GUIDE_THICK",
    "ANCHOR_THICK",
    "SLEEVE_CLEARANCE",
    "NUM_TIERS",
    "COLLAR_BUMP_DIA", "COLLAR_BUMP_H", "COLLAR_BUMP_COUNT",
    "AXIAL_PITCH", "COLLAR_THICK",
]


def audit_parameter_consistency():
    """Parse config, then cross-check values in validation.py, monolith, and MACHINE_STATE_DIAGRAM.md."""
    section = "Section 3: Parameter Consistency"

    config_path = WORKING_DIR / "config_v5_5.scad"
    validation_path = WORKING_DIR / "v5_5_math_validation.py"
    monolith_path = WORKING_DIR / "monolith_v5_5.scad"

    config_vars = parse_scad_assignments(config_path)
    validation_vars = parse_python_assignments(validation_path)
    monolith_vars = parse_scad_assignments(monolith_path)

    if not config_vars:
        _fail(section, "Could not parse config_v5_5.scad — no assignments found")
        return

    # Read MACHINE_STATE_DIAGRAM.md for content searches
    md_content = ""
    if MACHINE_STATE_MD.is_file():
        with open(MACHINE_STATE_MD, "r", encoding="utf-8", errors="replace") as f:
            md_content = f.read()
    else:
        _warn(section, f"MACHINE_STATE_DIAGRAM.md not found at {MACHINE_STATE_MD}")

    for param in KEY_PARAMS:
        config_entry = config_vars.get(param)
        if config_entry is None:
            _warn(section, f"{param} -- NOT FOUND in config_v5_5.scad")
            continue

        config_raw, config_line = config_entry
        config_val = try_eval_numeric(config_raw)

        sources_checked = []
        mismatches = []

        # Check in validation.py
        val_entry = validation_vars.get(param)
        if val_entry is not None:
            val_raw, val_line = val_entry
            val_val = try_eval_numeric(val_raw)
            if config_val is not None and val_val is not None:
                if abs(config_val - val_val) < 0.01:
                    sources_checked.append(f"validation.py={val_val}")
                else:
                    mismatches.append(f"validation.py has {val_val} (line {val_line})")
                    sources_checked.append(f"validation.py={val_val} MISMATCH")
            else:
                sources_checked.append(f"validation.py='{val_raw}' (non-numeric)")
        # Not all params need to be in validation.py — only warn for important ones
        elif param in ("HEX_R", "NUM_CHANNELS", "ECCENTRICITY", "SHAFT_DIA", "DISC_OD"):
            mismatches.append(f"NOT FOUND in validation.py")

        # Check in monolith
        mono_entry = monolith_vars.get(param)
        if mono_entry is not None:
            mono_raw, mono_line = mono_entry
            mono_val = try_eval_numeric(mono_raw)
            if config_val is not None and mono_val is not None:
                if abs(config_val - mono_val) < 0.01:
                    sources_checked.append(f"monolith={mono_val}")
                else:
                    mismatches.append(f"monolith has {mono_val} (line {mono_line})")
                    sources_checked.append(f"monolith={mono_val} MISMATCH")
            else:
                # Monolith often derives from config via `include` — HEX_R + 2 etc.
                sources_checked.append(f"monolith='{mono_raw}' (derived/non-numeric)")

        # Check MACHINE_STATE_DIAGRAM.md for documented value
        if md_content and config_val is not None:
            # Look for patterns like "HEX_R = 43" or "HEX_R=43"
            md_pattern = re.compile(
                rf'{re.escape(param)}\s*[=:]\s*(\d+\.?\d*)', re.IGNORECASE
            )
            md_matches = md_pattern.findall(md_content)
            if md_matches:
                # Collect all numeric matches; check if ANY match the config value.
                # Changelog tables (old -> new) legitimately contain old values.
                md_vals = []
                for md_val_str in md_matches:
                    try:
                        md_vals.append(float(md_val_str))
                    except ValueError:
                        pass
                if md_vals:
                    has_correct = any(abs(v - config_val) < 0.01 for v in md_vals)
                    if has_correct:
                        sources_checked.append(f"doc={config_val}")
                    else:
                        # No occurrence matches current config — truly stale
                        mismatches.append(
                            f"MACHINE_STATE_DIAGRAM.md says {param}={md_vals[0]}"
                        )
                        sources_checked.append(f"doc={md_vals[0]} MISMATCH")

        # Report
        config_display = config_val if config_val is not None else config_raw
        if mismatches:
            detail = "; ".join(mismatches)
            _fail(section, f"{param}={config_display} in config — {detail}")
        elif sources_checked:
            _pass(section, f"{param}={config_display} in config — consistent ({', '.join(sources_checked)})")
        else:
            _pass(section, f"{param}={config_display} in config — (no cross-references found)")

    # Special check: GUIDE_THICK vs old GP1_THICK/GP2_THICK/GUIDE_PLATE_GAP
    old_gp_params = ["GP1_THICK", "GP2_THICK", "GUIDE_PLATE_GAP"]
    for old_param in old_gp_params:
        for label, var_dict in [("config", config_vars), ("validation.py", validation_vars),
                                ("monolith", monolith_vars)]:
            if old_param in var_dict:
                _warn(section,
                      f"STALE: {old_param} still defined in {label} "
                      f"(line {var_dict[old_param][1]}) — should be replaced by GUIDE_THICK")

    # Helper: filter MD lines to exclude changelog/comparison table rows
    # These contain old values alongside new values for documenting transitions.
    def _non_changelog_lines(content):
        """Return MD content with changelog/comparison table rows removed."""
        lines = content.split('\n')
        in_changes_section = False
        filtered = []
        for line in lines:
            stripped = line.strip()
            # Detect "Changes" or "Changelog" section headers
            if re.match(r'^#{1,3}\s.*(change|changelog|evolution|comparison)', stripped, re.I):
                in_changes_section = True
            elif re.match(r'^#{1,3}\s', stripped):
                in_changes_section = False
            # Skip table rows that contain '->' (old -> new transitions)
            if stripped.startswith('|') and '->' in stripped:
                continue
            # Skip ALL table rows in a changes/comparison section
            if in_changes_section and stripped.startswith('|'):
                continue
            # Skip table rows containing both old and new bearing/part names
            if stripped.startswith('|') and re.search(
                    r'(625ZZ.*MR84|MR84.*625ZZ|61808.*6704|6704.*61808'
                    r'|GP1.*single|2x.*1x|dual.*single)', stripped, re.I):
                continue
            filtered.append(line)
        return '\n'.join(filtered)

    # Check MD for stale dual-plate references (outside changelog)
    if md_content:
        md_filtered = _non_changelog_lines(md_content)
        stale_md_patterns = [
            (r"GP1.*GP2.*gap\s*=\s*\d+", "dual GP1+GP2+gap reference"),
            (r"2x\s*PTFE\s*bushing", "PTFE bushing reference (V5.5b removed)"),
            (r"Guide Plates.*2x", "dual guide plate reference"),
        ]
        for pat, desc in stale_md_patterns:
            if re.search(pat, md_filtered, re.IGNORECASE):
                _warn(section, f"MACHINE_STATE_DIAGRAM.md contains stale '{desc}'")

    # Check bearing names in MD (outside changelog/comparison tables)
    if md_content:
        md_filtered = _non_changelog_lines(md_content)
        # V5.5 uses MR84ZZ (frame) + 6704ZZ (cam), NOT 625ZZ / 61808ZZ
        if "61808ZZ" in md_filtered:
            _warn(section,
                  "MACHINE_STATE_DIAGRAM.md references 61808ZZ bearings "
                  "(V5.5 uses 6704ZZ for cam, MR84ZZ for frame)")
        if "625ZZ" in md_filtered:
            _warn(section,
                  "MACHINE_STATE_DIAGRAM.md references 625ZZ bearings "
                  "(V5.5 uses MR84ZZ for frame)")

    # Check channel count in MD (outside changelog)
    if md_content:
        md_filtered = _non_changelog_lines(md_content)
        ch_count_matches = re.findall(r'(\d+)\s*channel', md_filtered, re.IGNORECASE)
        for ch_str in ch_count_matches:
            ch_val = int(ch_str)
            if ch_val != 9:
                _warn(section,
                      f"MACHINE_STATE_DIAGRAM.md says '{ch_str} channel' — V5.5 has 9 channels")


# ================================================================
# SECTION 4: FILE EXISTENCE
# ================================================================

EXPECTED_FILES = [
    ("config_v5_5.scad", "required"),
    ("helix_cam_v5_5.scad", "required"),
    ("matrix_stack_v5_5.scad", "required"),
    ("monolith_v5_5.scad", "required"),
    ("anchor_plate_v5_5.scad", "required"),
    ("guide_plate_v5_5.scad", "required"),
    ("v5_5_math_validation.py", "required"),
    ("consistency_audit.py", "required"),       # self!
    ("validate_geometry.py", "optional"),        # should be copied here
]


def audit_file_existence():
    section = "Section 4: File Existence"
    for filename, importance in EXPECTED_FILES:
        fpath = WORKING_DIR / filename
        if fpath.is_file():
            _pass(section, f"{filename}")
        elif importance == "required":
            _fail(section, f"{filename} -- MISSING (required)")
        else:
            _warn(section, f"{filename} -- MISSING from 5.5/ (should be copied here)")


# ================================================================
# SECTION 5: STALE COMMENT DETECTION
# ================================================================

def _is_stale_comment_number(cn_str, cn_val, var_val, comment_part):
    """
    Determine if a number found in a comment likely contradicts the variable value.
    Returns True if it looks like a genuine stale reference.
    Returns False for numbers that are clearly not stale (history, angles, counts, versions).
    """
    # Skip zero
    if cn_val == 0:
        return False

    # Skip if the number matches the variable value
    if abs(cn_val - var_val) < 0.01:
        return False

    # Skip version-like numbers: V5.5, v5_4, etc.
    if re.search(rf'[Vv]\s*{re.escape(cn_str)}', comment_part):
        return False

    # Skip "was X" patterns (documenting history)
    if re.search(rf'was\s+{re.escape(cn_str)}', comment_part, re.IGNORECASE):
        return False

    # Skip "from X" patterns (documenting origin)
    if re.search(rf'from\s+{re.escape(cn_str)}', comment_part, re.IGNORECASE):
        return False

    # Skip numbers followed by "ch" (channel count in history notes like "13ch")
    if re.search(rf'{re.escape(cn_str)}\s*ch\b', comment_part, re.IGNORECASE):
        return False

    # Skip numbers preceded by "deg" context (angles, not dimensions)
    if re.search(rf'{re.escape(cn_str)}\s*deg', comment_part, re.IGNORECASE):
        return False

    # Skip numbers at "...at Xdeg" (angle position references)
    if re.search(rf'at\s+{re.escape(cn_str)}', comment_part, re.IGNORECASE):
        return False

    # Skip parenthesized "was" style: "(was 13)" or "(13ch)"
    if re.search(rf'\(\s*(?:was\s+)?{re.escape(cn_str)}', comment_part, re.IGNORECASE):
        return False

    # Skip if comment has an "=" and the number after = matches var value
    # e.g. "// (FP_OD + SP_OD)/2 + 1.5 = 4.5" on FP_ROW_Y = 4.5 line
    eq_matches = re.findall(r'=\s*(\d+\.?\d*)', comment_part)
    for eq_val_str in eq_matches:
        try:
            if abs(float(eq_val_str) - var_val) < 0.01:
                return False
        except ValueError:
            pass

    # Skip if the number appears to be part of a dimension expression
    # where the RESULT (not this number) is the relevant comparison.
    # E.g., on "HOUSING_HEIGHT = 13; // 2*4.5 + 3 + 1" the 4.5, 3, 1 are
    # formula components, not the declared value.
    # Heuristic: if the comment contains an arithmetic operator near the number,
    # it's likely part of a derivation.
    # Only flag numbers that appear as standalone "Xmm" references.

    # Numbers immediately followed by "mm" are dimension claims — these are stale-worthy
    if re.search(rf'{re.escape(cn_str)}\s*mm', comment_part):
        return True

    # For non-mm numbers, require that they look like a standalone value claim
    # (not part of a formula or channel count or version).
    # If the comment contains arithmetic around this number, skip it.
    if re.search(rf'[\*\+\-/]\s*{re.escape(cn_str)}|{re.escape(cn_str)}\s*[\*\+\-/]',
                 comment_part):
        return False

    # Be conservative: only flag numbers explicitly presented as "Xmm"
    # Other numbers in comments are often formula components, counts, or references.
    return False


def audit_stale_comments():
    """
    Scan .scad files for lines where an assignment value contradicts
    a number mentioned in the trailing comment on the same line.
    Example: CH_GAP = 6.5;  // 4.0mm  -> STALE
    """
    section = "Section 5: Stale Comments"
    scad_files = sorted(WORKING_DIR.glob("*.scad"))
    found_any_stale = False

    for fpath in scad_files:
        with open(fpath, "r", encoding="utf-8", errors="replace") as f:
            for lineno, line in enumerate(f, start=1):
                stripped = line.strip()
                # Must have an assignment AND a comment
                if "//" not in stripped:
                    continue
                m = re.match(r'^([A-Z_][A-Z0-9_]*)\s*=\s*([^;]+);', stripped)
                if not m:
                    continue

                var_name = m.group(1)
                var_raw = m.group(2).strip()
                var_val = try_eval_numeric(var_raw)
                if var_val is None:
                    continue  # can't compare non-numeric

                comment_part = stripped[stripped.index("//"):]
                # Extract all numbers from the comment
                comment_nums = re.findall(r'(?<![.\w])(\d+\.?\d*)', comment_part)
                if not comment_nums:
                    continue

                for cn_str in comment_nums:
                    try:
                        cn_val = float(cn_str)
                    except ValueError:
                        continue

                    if _is_stale_comment_number(cn_str, cn_val, var_val, comment_part):
                        _warn(section,
                              f"{fpath.name}:{lineno} -- {var_name}={var_val} "
                              f"but comment says '{cn_str}mm' in: {comment_part.strip()}")
                        found_any_stale = True

    if not found_any_stale:
        _pass(section, "No stale numeric comments detected")


# ================================================================
# SECTION 6: ORPHAN INCLUDE/USE DETECTION
# ================================================================

def audit_orphan_includes():
    """Check that include<...> and use<...> directives resolve to actual files."""
    section = "Section 6: Orphan Includes"
    scad_files = sorted(WORKING_DIR.glob("*.scad"))
    all_resolved = True

    for fpath in scad_files:
        with open(fpath, "r", encoding="utf-8", errors="replace") as f:
            for lineno, line in enumerate(f, start=1):
                stripped = line.strip()
                m = re.match(r'^(include|use)\s*<([^>]+)>', stripped)
                if not m:
                    continue
                directive = m.group(1)
                ref_file = m.group(2)

                # OpenSCAD resolves relative to file's directory and library paths.
                # Check relative to file's directory first.
                candidate = fpath.parent / ref_file
                if candidate.is_file():
                    _pass(section, f"{fpath.name}:{lineno} -- {directive} <{ref_file}> resolves OK")
                else:
                    _fail(section,
                          f"{fpath.name}:{lineno} -- {directive} <{ref_file}> "
                          f"NOT FOUND at {candidate}")
                    all_resolved = False

    if all_resolved and not any(r[1] == section and r[0] == "PASS" for r in _results):
        _pass(section, "No include/use directives found")


# ================================================================
# SECTION 7: VERSION HEADER CHECK
# ================================================================

def audit_version_headers():
    """
    Each .scad file should reference V5.5 or v5_5 in its header comments.
    Flag files that reference older version numbers without also referencing V5.5.
    """
    section = "Section 7: Version Headers"
    scad_files = sorted(WORKING_DIR.glob("*.scad"))

    old_versions = re.compile(r'V5\.[0-4]|v5_[0-4]', re.IGNORECASE)
    current_version = re.compile(r'V5\.5|v5_5', re.IGNORECASE)

    for fpath in scad_files:
        # Read first 40 lines as "header"
        header_lines = []
        with open(fpath, "r", encoding="utf-8", errors="replace") as f:
            for i, line in enumerate(f):
                if i >= 40:
                    break
                header_lines.append(line)
        header_text = "".join(header_lines)

        has_current = bool(current_version.search(header_text))
        old_matches = old_versions.findall(header_text)

        if has_current:
            if old_matches:
                # Old version mentioned alongside current is OK if it says "from V5.4" etc.
                # But flag if it looks like the file IS the old version
                # Check if the file TITLE line says old version
                first_comment_lines = [l for l in header_lines[:5] if l.strip().startswith("//")]
                title_text = "".join(first_comment_lines)
                old_in_title = old_versions.findall(title_text)
                if old_in_title:
                    # Only flag if the title itself says the old version without current
                    if not current_version.search(title_text):
                        _warn(section,
                              f"{fpath.name} -- title references {old_in_title[0]} "
                              f"(but V5.5 appears elsewhere in header)")
                    else:
                        _pass(section, f"{fpath.name} -- references V5.5")
                else:
                    _pass(section, f"{fpath.name} -- references V5.5")
            else:
                _pass(section, f"{fpath.name} -- references V5.5")
        else:
            if old_matches:
                _fail(section,
                      f"{fpath.name} -- header references {set(old_matches)} "
                      f"but NOT V5.5 — stale version header")
            else:
                _warn(section, f"{fpath.name} -- no version reference found in header")


# ================================================================
# FIX CHECKPOINT
# ================================================================

def fix_checkpoint():
    """Copy all working 5.5/ files to check point/5.5/."""
    print(f"\n  Fixing checkpoint: copying {WORKING_DIR} -> {CHECKPOINT_SUB}")
    CHECKPOINT_SUB.mkdir(parents=True, exist_ok=True)
    copied = 0
    for src in sorted(WORKING_DIR.iterdir()):
        if src.is_file() and src.suffix in (".scad", ".py"):
            dst = CHECKPOINT_SUB / src.name
            shutil.copy2(src, dst)
            print(f"    Copied: {src.name}")
            copied += 1

    # Also update flat checkpoint
    print(f"\n  Updating flat checkpoint: {CHECKPOINT_FLAT}")
    for src in sorted(WORKING_DIR.iterdir()):
        if src.is_file() and src.suffix in (".scad", ".py"):
            dst = CHECKPOINT_FLAT / src.name
            shutil.copy2(src, dst)
            print(f"    Copied: {src.name} (flat)")
            copied += 1

    print(f"\n  {copied} files copied total.")


# ================================================================
# MAIN
# ================================================================

def print_section(name, results_for_section):
    """Print results for one section."""
    print(f"\n{name}")
    for status, _, msg in results_for_section:
        prefix = {"PASS": "  PASS", "FAIL": "  FAIL", "WARN": "  WARN"}[status]
        print(f"{prefix}  {msg}")


def main():
    parser = argparse.ArgumentParser(description="Traceability & Consistency Audit for Triple Helix MVP V5.5")
    parser.add_argument("--fix-checkpoint", action="store_true",
                        help="Copy working 5.5/ files to check point/5.5/ and flat checkpoint")
    parser.add_argument("--verbose", action="store_true",
                        help="Show extra detail")
    args = parser.parse_args()

    if args.fix_checkpoint:
        fix_checkpoint()
        print("\nCheckpoint updated. Run again without --fix-checkpoint to audit.\n")
        return 0

    # ---- Banner ----
    print("=" * 56)
    print("TRACEABILITY & CONSISTENCY AUDIT")
    print("Triple Helix MVP V5.5")
    print("=" * 56)
    print(f"\nWorking dir : {WORKING_DIR}")
    print(f"Checkpoint  : {CHECKPOINT_SUB}")
    print(f"Flat ckpt   : {CHECKPOINT_FLAT}")
    print(f"State doc   : {MACHINE_STATE_MD}")

    # ---- Run all sections ----
    audit_checkpoint_drift("Section 1: Checkpoint Drift (5.5/ vs check point/5.5/)",
                           WORKING_DIR, CHECKPOINT_SUB)

    audit_checkpoint_drift("Section 2: Flat Checkpoint (5.5/ vs check point/)",
                           WORKING_DIR, CHECKPOINT_FLAT, v55_only=True)

    audit_parameter_consistency()

    audit_file_existence()

    audit_stale_comments()

    audit_orphan_includes()

    audit_version_headers()

    # ---- Print results by section ----
    sections_seen = []
    for status, section, msg in _results:
        if section not in sections_seen:
            sections_seen.append(section)

    for section in sections_seen:
        section_results = [(s, sec, m) for s, sec, m in _results if sec == section]
        if not args.verbose:
            # In non-verbose mode, only show FAILs, WARNs, and a PASS summary count
            fails_warns = [(s, sec, m) for s, sec, m in section_results if s != "PASS"]
            pass_count = sum(1 for s, _, _ in section_results if s == "PASS")
            print(f"\n{section}")
            if pass_count > 0:
                print(f"  PASS  {pass_count} check(s) passed")
            for status, _, msg in fails_warns:
                prefix = "  FAIL" if status == "FAIL" else "  WARN"
                print(f"{prefix}  {msg}")
        else:
            print_section(section, section_results)

    # ---- Summary ----
    passes = sum(1 for s, _, _ in _results if s == "PASS")
    fails = sum(1 for s, _, _ in _results if s == "FAIL")
    warns = sum(1 for s, _, _ in _results if s == "WARN")

    print("\n" + "=" * 56)
    print(f"SUMMARY: {passes} PASS / {fails} FAIL / {warns} WARN")
    print("=" * 56)

    if fails > 0:
        print("\nFAILURES:")
        for status, section, msg in _results:
            if status == "FAIL":
                print(f"  [{section}] {msg}")

    if warns > 0 and args.verbose:
        print("\nWARNINGS:")
        for status, section, msg in _results:
            if status == "WARN":
                print(f"  [{section}] {msg}")

    return 1 if fails > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
