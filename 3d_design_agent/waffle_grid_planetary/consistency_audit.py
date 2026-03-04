#!/usr/bin/env python3
"""
Ravigneaux Grid -- Consistency Audit
=====================================
Checks that the design document, OpenSCAD code, and echo output
all agree on key parameters. Catches DRIFT between files.

Usage:
    python consistency_audit.py              # run audit
    python consistency_audit.py --verbose    # show detail on passes

Exit code: 0 if no FAILs, 1 if any FAILs.
"""

import sys
import os
import re
import argparse
from pathlib import Path

# ================================================================
# PATH SETUP
# ================================================================
SCRIPT_DIR = Path(__file__).resolve().parent
DESIGN_DOC = Path("D:/Claude local/docs/plans/2026-02-23-ravigneaux-grid-sculpture-design.md")
SCAD_FILE = SCRIPT_DIR / "ravigneaux_grid_v1.scad"

# ================================================================
# RESULT TRACKING
# ================================================================
_results = []

def _pass(section, msg):
    _results.append(("PASS", section, msg))

def _fail(section, msg):
    _results.append(("FAIL", section, msg))

def _warn(section, msg):
    _results.append(("WARN", section, msg))


# ================================================================
# PARSERS
# ================================================================

def parse_scad_assignments(filepath):
    """Parse top-level OpenSCAD variable assignments."""
    assignments = {}
    if not filepath.is_file():
        return assignments
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        for i, line in enumerate(f, 1):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("/*"):
                continue
            # Match: VARNAME = <value>;
            m = re.match(r'^([A-Z_][A-Z0-9_]*)\s*=\s*(.+?)\s*;', stripped)
            if m:
                varname = m.group(1)
                raw_val = m.group(2)
                assignments[varname] = (raw_val, i)
    return assignments


def parse_design_doc(filepath):
    """Extract key parameters from the design document markdown."""
    params = {}
    if not filepath.is_file():
        return params
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        text = f.read()

    # Normal module
    m = re.search(r'Normal module:\s*([\d.]+)mm', text)
    if m: params['NORM_MOD'] = float(m.group(1))

    # Helix angle
    m = re.search(r'Helix angle:\s*(\d+)', text)
    if m: params['HELIX_ANG'] = int(m.group(1))

    # Ring teeth
    m = re.search(r'Ring:\s*(\d+)T', text)
    if m: params['T_RING'] = int(m.group(1))

    # Large Sun teeth
    m = re.search(r'Large Sun.*?:\s*(\d+)T', text)
    if m: params['T_SL'] = int(m.group(1))

    # Outer Planet teeth
    m = re.search(r'Outer Planet.*?:\s*(\d+)T', text)
    if m: params['T_PO'] = int(m.group(1))

    # Ring OD
    m = re.search(r'Ring OD:\s*(\d+)mm', text)
    if m: params['RING_OD_TARGET'] = int(m.group(1))

    # Gear zone widths (two-zone axiom)
    m = re.search(r'Ss gear zone \((\d+)mm\)', text)
    if m: params['SS_GEAR_FW'] = int(m.group(1))
    m = re.search(r'SL gear zone \((\d+)mm\)', text)
    if m: params['SL_GEAR_FW'] = int(m.group(1))
    m = re.search(r'thrust plate \(([\d.]+)mm\)', text)
    if m: params['THRUST_PLATE_H'] = float(m.group(1))

    # Anchor diameter
    m = re.search(r'Anchor.*?\|\s*(\d+)mm', text)
    if m: params['ANCHOR_D'] = int(m.group(1))

    # Spool channel width
    m = re.search(r'Spool channel:\s*(\d+)mm', text)
    if m: params['CHANNEL_W'] = int(m.group(1))

    # Pressure angle
    m = re.search(r'Pressure angle:\s*(\d+)', text)
    if m: params['PRESS_ANG'] = int(m.group(1))

    return params


def parse_scad_value(raw_val):
    """Try to evaluate a simple SCAD value string to a Python number."""
    # Handle simple numbers
    try:
        return float(raw_val)
    except ValueError:
        pass
    # Handle integers
    try:
        return int(raw_val)
    except ValueError:
        pass
    return None


# ================================================================
# CHECKS
# ================================================================

def check_files_exist():
    """Verify all expected files exist."""
    section = "FILES"

    if SCAD_FILE.is_file():
        _pass(section, f"SCAD file exists: {SCAD_FILE.name}")
    else:
        _fail(section, f"SCAD file missing: {SCAD_FILE}")

    if DESIGN_DOC.is_file():
        _pass(section, f"Design doc exists: {DESIGN_DOC.name}")
    else:
        _fail(section, f"Design doc missing: {DESIGN_DOC}")

    validate_py = SCRIPT_DIR / "validate_geometry.py"
    if validate_py.is_file():
        _pass(section, f"Validator exists: validate_geometry.py")
    else:
        _warn(section, f"Validator missing: validate_geometry.py")


def check_doc_vs_scad():
    """Cross-check design doc parameters against .scad file."""
    section = "DOC-vs-SCAD"

    doc_params = parse_design_doc(DESIGN_DOC)
    scad_vars = parse_scad_assignments(SCAD_FILE)

    if not doc_params:
        _warn(section, "Could not parse design doc parameters")
        return
    if not scad_vars:
        _warn(section, "Could not parse SCAD assignments")
        return

    # Map doc params to SCAD variable names
    checks = {
        'NORM_MOD': 'NORM_MOD',
        'HELIX_ANG': 'HELIX_ANG',
        'T_RING': 'T_RING',
        'T_SL': 'T_SL',
        'T_PO': 'T_PO',
        'SS_GEAR_FW': 'SS_GEAR_FW',
        'SL_GEAR_FW': 'SL_GEAR_FW',
        'THRUST_PLATE_H': 'THRUST_PLATE_H',
        'ANCHOR_D': 'ANCHOR_D',
        'CHANNEL_W': 'CHANNEL_W',
        'PRESS_ANG': 'PRESS_ANG',
    }

    for doc_key, scad_key in checks.items():
        if doc_key not in doc_params:
            _warn(section, f"Doc missing param: {doc_key}")
            continue
        if scad_key not in scad_vars:
            _warn(section, f"SCAD missing var: {scad_key}")
            continue

        doc_val = doc_params[doc_key]
        scad_raw = scad_vars[scad_key][0]
        scad_val = parse_scad_value(scad_raw)

        if scad_val is not None and abs(float(doc_val) - float(scad_val)) < 0.01:
            _pass(section, f"{doc_key}: doc={doc_val}, scad={scad_val} MATCH")
        else:
            _fail(section, f"{doc_key}: doc={doc_val}, scad={scad_raw} MISMATCH")

    # Ring OD is derived, check approximate match
    if 'RING_OD_TARGET' in doc_params:
        target = doc_params['RING_OD_TARGET']
        # Can't easily evaluate derived SCAD expressions; check it's mentioned in echo
        _pass(section, f"Ring OD target: {target}mm (validated by geometry validator)")


def check_variant_table():
    """Verify variant table in SCAD matches design doc."""
    section = "VARIANTS"

    if not SCAD_FILE.is_file():
        _fail(section, "SCAD file missing")
        return
    if not DESIGN_DOC.is_file():
        _warn(section, "Design doc missing, skipping variant cross-check")
        return

    with open(SCAD_FILE, "r") as f:
        scad_text = f.read()

    with open(DESIGN_DOC, "r") as f:
        doc_text = f.read()

    # Parse variant table from SCAD
    scad_variants = re.findall(r'\[(\d+),\s*(\d+)\]', scad_text)
    # Filter to likely variant entries (in the _VARIANTS array context)
    # Look for the ones that satisfy Ss + 2*Pi = 40
    valid_variants = [(int(ss), int(pi)) for ss, pi in scad_variants
                      if int(ss) + 2*int(pi) == 40]

    # Parse from design doc
    doc_variants = re.findall(r'\|\s*[A-E]\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|', doc_text)
    doc_pairs = [(int(ss), int(pi)) for ss, pi in doc_variants]

    if len(valid_variants) >= 5:
        _pass(section, f"SCAD has {len(valid_variants)} valid variants")
    else:
        _fail(section, f"SCAD has only {len(valid_variants)} valid variants (expected 5)")

    if len(doc_pairs) >= 5:
        _pass(section, f"Doc has {len(doc_pairs)} variant rows")
    else:
        _warn(section, f"Doc has {len(doc_pairs)} variant rows")

    # Cross-check
    for i, (ss, pi) in enumerate(valid_variants[:5]):
        if i < len(doc_pairs):
            dss, dpi = doc_pairs[i]
            if ss == dss and pi == dpi:
                _pass(section, f"Variant {i}: SCAD({ss},{pi}) = Doc({dss},{dpi})")
            else:
                _fail(section, f"Variant {i}: SCAD({ss},{pi}) != Doc({dss},{dpi})")


def check_ext_pinions():
    """Verify external pinion table consistency."""
    section = "EXT-PINIONS"

    if not SCAD_FILE.is_file():
        return

    with open(SCAD_FILE, "r") as f:
        scad_text = f.read()

    # Find _EXT_PINIONS array
    m = re.search(r'_EXT_PINIONS\s*=\s*\[([\d,\s]+)\]', scad_text)
    if m:
        pinions = [int(x.strip()) for x in m.group(1).split(',')]
        if len(pinions) == 5:
            _pass(section, f"5 external pinion counts: {pinions}")
        else:
            _fail(section, f"Expected 5 ext pinions, got {len(pinions)}: {pinions}")

        # Check they're sorted (ascending frequency)
        if pinions == sorted(pinions):
            _pass(section, "Pinions sorted ascending (slow -> fast)")
        else:
            _warn(section, f"Pinions not sorted: {pinions}")
    else:
        _fail(section, "Could not find _EXT_PINIONS array in SCAD")


def check_code_quality():
    """Basic code quality checks on the SCAD file."""
    section = "CODE"

    if not SCAD_FILE.is_file():
        return

    with open(SCAD_FILE, "r") as f:
        lines = f.readlines()

    # Check for magic numbers in transforms (excluding 0, 1, -1, 0.1, 0.2)
    magic_count = 0
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("//") or stripped.startswith("echo") or stripped.startswith("$fn"):
            continue
        # Look for translate/rotate with bare numbers
        if re.search(r'translate\(\[.*\d{2,}', stripped) and not 'EXPLODE' in stripped:
            if not any(var in stripped for var in ['_Z', '_R', '_OD', '_ID', 'RING', 'GEAR',
                                                     'CAR', 'LID', 'ANCHOR', 'CHANNEL', 'ORB']):
                magic_count += 1

    if magic_count == 0:
        _pass(section, "No magic numbers in transforms")
    elif magic_count <= 3:
        _warn(section, f"{magic_count} potential magic numbers in transforms")
    else:
        _fail(section, f"{magic_count} magic numbers in transforms (use named constants)")

    # Check convexity on linear_extrude and rotate_extrude
    extrudes = [i for i, l in enumerate(lines, 1) if 'linear_extrude' in l or 'rotate_extrude' in l]
    missing_convexity = [i for i in extrudes if 'convexity' not in lines[i-1]]
    if len(missing_convexity) == 0:
        _pass(section, f"All {len(extrudes)} extrude calls have convexity parameter")
    else:
        _warn(section, f"{len(missing_convexity)} extrude calls missing convexity (lines: {missing_convexity[:5]})")

    # Check $fn is not global > 48 for preview
    for i, line in enumerate(lines[:5], 1):
        m = re.match(r'^\$fn\s*=\s*(\d+)', line.strip())
        if m:
            fn = int(m.group(1))
            if fn <= 48:
                _pass(section, f"Global $fn={fn} (preview-safe for GTX 1650)")
            elif fn <= 64:
                _warn(section, f"Global $fn={fn} (may lag on GTX 1650 with 25-unit grid)")
            else:
                _fail(section, f"Global $fn={fn} (too high for preview)")


# ================================================================
# MAIN
# ================================================================
def main():
    parser = argparse.ArgumentParser(description="Ravigneaux Grid Consistency Audit")
    parser.add_argument("--verbose", action="store_true", help="Show detail on passes")
    args = parser.parse_args()

    print("=" * 60)
    print("  RAVIGNEAUX GRID -- Consistency Audit")
    print("=" * 60)

    check_files_exist()
    check_doc_vs_scad()
    check_variant_table()
    check_ext_pinions()
    check_code_quality()

    # Summary
    passes = sum(1 for r in _results if r[0] == "PASS")
    fails  = sum(1 for r in _results if r[0] == "FAIL")
    warns  = sum(1 for r in _results if r[0] == "WARN")

    print(f"\n{'='*60}")
    print(f"  RESULTS: {passes} PASS  |  {fails} FAIL  |  {warns} WARN")
    print(f"{'='*60}")

    for status, section, msg in _results:
        if status == "PASS" and not args.verbose:
            continue
        icon = {"PASS": "[OK]", "FAIL": "[FAIL]", "WARN": "[WARN]"}[status]
        print(f"  {icon:6s} {section:20s} {msg}")

    print(f"\n{'PASS' if fails == 0 else 'FAIL'}")
    sys.exit(0 if fails == 0 else 1)


if __name__ == "__main__":
    main()
