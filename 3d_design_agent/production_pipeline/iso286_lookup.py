#!/usr/bin/env python3
"""
ISO 286 Shaft/Hole Tolerance Lookup
====================================
Pure Python, no dependencies. Used by Rule 99 Gate 2 (Prototype) and Gate 3 (Production).

Usage:
    from iso286_lookup import iso286_lookup, fit_clearance

    # Single tolerance zone
    result = iso286_lookup(25, "H7")
    # -> {"zone": "H7", "nominal": 25, "upper_dev_um": 21, "lower_dev_um": 0,
    #     "upper_mm": 25.021, "lower_mm": 25.000}

    # Fit pair (hole/shaft)
    fit = fit_clearance(25, "H7", "g6")
    # -> {"nominal": 25, "hole": {...}, "shaft": {...},
    #     "min_clearance_mm": 0.007, "max_clearance_mm": 0.041,
    #     "fit_type": "clearance"}

    # CLI test
    python iso286_lookup.py --test
    python iso286_lookup.py 25 H7/g6
"""

import sys
import math

# --- ISO 286 Diameter Ranges (mm) ---
# Each range: (min_exclusive, max_inclusive)
# First range starts at 0 (>0, <=3)
DIAMETER_RANGES = [
    (0, 3), (3, 6), (6, 10), (10, 18), (18, 30),
    (30, 50), (50, 80), (80, 120), (120, 180),
    (180, 250), (250, 315), (315, 400), (400, 500),
]

def _range_index(nominal_mm):
    """Return the index into DIAMETER_RANGES for a given nominal diameter."""
    for i, (lo, hi) in enumerate(DIAMETER_RANGES):
        if lo < nominal_mm <= hi:
            return i
    raise ValueError(f"Nominal diameter {nominal_mm}mm outside ISO 286 range (>0, <=500)")


# --- Fundamental Deviations (microns) ---
# These are the LOWER deviation for shafts a-h, UPPER deviation for shafts k-zc.
# For holes, the fundamental deviation is the negative of the corresponding shaft letter.
# Exception: holes A-H have their own tables (we use the standard inversion rule).

# Shaft fundamental deviations per diameter range index (microns)
# Source: ISO 286-2 Tables
# Format: deviation_letter -> [value per diameter range index]
# For lowercase letters (shafts): the value is the upper fundamental deviation
# for letters a-h (negative values = shaft smaller than nominal)
# For letters k-zc: value is lower fundamental deviation (positive = shaft larger)

# We store fundamental deviations for the most commonly used zones.
# shaft "es" = upper deviation for a-h; shaft "ei" = lower deviation for k-zc

SHAFT_FUNDAMENTAL_DEV = {
    # letter: [deviation in microns per diameter range, index 0..12]
    # These are "es" (upper deviation) for clearance shafts (negative = below nominal)
    "a":  [-270, -270, -280, -290, -300, -310, -320, -340, -360, -380, -410, -440, -480],
    "b":  [-140, -140, -150, -150, -160, -170, -180, -200, -220, -240, -260, -280, -300],
    "c":  [ -60,  -70,  -80,  -95, -110, -120, -145, -170, -195, -220, -240, -260, -280],
    "d":  [ -20,  -30,  -40,  -50,  -65,  -80, -100, -120, -145, -170, -190, -210, -230],
    "e":  [ -14,  -20,  -25,  -32,  -40,  -50,  -60,  -72,  -85, -100, -110, -125, -135],
    "f":  [  -6,  -10,  -13,  -16,  -20,  -25,  -30,  -36,  -43,  -50,  -56,  -62,  -68],
    "g":  [  -2,   -4,   -5,   -6,   -7,   -9,  -10,  -12,  -14,  -15,  -17,  -18,  -20],
    "h":  [   0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0],
    # These are "ei" (lower deviation) for interference/transition shafts (positive = above nominal)
    "js": None,  # special: symmetric about zero, handled in code
    "k":  [   0,    1,    1,    1,    2,    2,    2,    3,    3,    4,    4,    4,    5],
    "m":  [   2,    4,    6,    7,    8,    9,   11,   13,   15,   17,   20,   21,   23],
    "n":  [   4,    8,   10,   12,   15,   17,   20,   23,   27,   31,   34,   37,   40],
    "p":  [   6,   12,   15,   18,   22,   26,   32,   37,   43,   50,   56,   62,   68],
    "r":  [  10,   15,   19,   23,   28,   34,   41,   48,   55,   63,   70,   77,   84],
    "s":  [  14,   19,   23,   28,   35,   43,   53,   59,   68,   79,   88,   98,  108],
}

# --- IT Grades (tolerance band width in microns) ---
# IT grade values per diameter range index
# Source: ISO 286-1 Table 1
IT_GRADES = {
    # grade: [width in microns per diameter range index 0..12]
    "IT01": [0.3, 0.4, 0.4, 0.5, 0.6, 0.6, 0.8, 1.0, 1.2, 2.0, 2.5, 3.0, 4.0],
    "IT0":  [0.5, 0.6, 0.6, 0.8, 1.0, 1.0, 1.2, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0],
    "IT1":  [0.8, 1.0, 1.0, 1.2, 1.5, 1.5, 2.0, 2.5, 3.5, 4.5, 6.0, 7.0, 8.0],
    "IT2":  [1.2, 1.5, 1.5, 2.0, 2.5, 2.5, 3.0, 4.0, 5.0, 7.0, 8.0, 9.0, 10.0],
    "IT3":  [2.0, 2.5, 2.5, 3.0, 4.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0, 13.0, 15.0],
    "IT4":  [3.0, 4.0, 4.0, 5.0, 6.0, 7.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0],
    "IT5":  [4, 5, 6, 8, 9, 11, 13, 15, 18, 20, 23, 25, 27],
    "IT6":  [6, 8, 9, 11, 13, 16, 19, 22, 25, 29, 32, 36, 40],
    "IT7":  [10, 12, 15, 18, 21, 25, 30, 35, 40, 46, 52, 57, 63],
    "IT8":  [14, 18, 22, 27, 33, 39, 46, 54, 63, 72, 81, 89, 97],
    "IT9":  [25, 30, 36, 43, 52, 62, 74, 87, 100, 115, 130, 140, 155],
    "IT10": [40, 48, 58, 70, 84, 100, 120, 140, 160, 185, 210, 230, 250],
    "IT11": [60, 75, 90, 110, 130, 160, 190, 220, 250, 290, 320, 360, 400],
    "IT12": [100, 120, 150, 180, 210, 250, 300, 350, 400, 460, 520, 570, 630],
    "IT13": [140, 180, 220, 270, 330, 390, 460, 540, 630, 720, 810, 890, 970],
    "IT14": [250, 300, 360, 430, 520, 620, 740, 870, 1000, 1150, 1300, 1400, 1550],
    "IT15": [400, 480, 580, 700, 840, 1000, 1200, 1400, 1600, 1850, 2100, 2300, 2500],
    "IT16": [600, 750, 900, 1100, 1300, 1600, 1900, 2200, 2500, 2900, 3200, 3600, 4000],
}


def _parse_zone(zone_str):
    """Parse a tolerance zone string like 'H7', 'g6', 'js6' into (letter, grade_num)."""
    zone_str = zone_str.strip()
    # Handle 'js' and 'Js' specially (two-character letter)
    if zone_str.lower().startswith("js"):
        return "js", int(zone_str[2:])
    # Single letter + grade number
    letter = zone_str[0]
    grade = int(zone_str[1:])
    return letter, grade


def _is_hole(letter):
    """Uppercase = hole, lowercase = shaft."""
    return letter.isupper() and letter != "j"  # js is lowercase


def _get_tolerance_width(grade, range_idx):
    """Get IT grade tolerance width in microns."""
    key = f"IT{grade}"
    if key not in IT_GRADES:
        raise ValueError(f"IT grade {grade} not supported (available: 01, 0-16)")
    return IT_GRADES[key][range_idx]


def iso286_lookup(nominal_mm, zone_str):
    """
    Look up ISO 286 tolerance zone for a given nominal diameter.

    Args:
        nominal_mm: Nominal diameter in mm (>0, <=500)
        zone_str: Tolerance zone like "H7", "g6", "h6", "js6", "p6", etc.

    Returns:
        dict with keys:
            zone: the zone string
            nominal: nominal diameter in mm
            upper_dev_um: upper deviation in microns
            lower_dev_um: lower deviation in microns
            upper_mm: max limit in mm
            lower_mm: min limit in mm
            tolerance_um: tolerance band width in microns
    """
    letter, grade = _parse_zone(zone_str)
    ridx = _range_index(nominal_mm)
    tol_width = _get_tolerance_width(grade, ridx)

    is_hole = _is_hole(letter)

    if is_hole:
        # Hole: uppercase letter. Fundamental deviation from inverted shaft table.
        shaft_letter = letter.lower()

        if shaft_letter == "js":
            # JS hole: symmetric about zero
            upper_dev = math.ceil(tol_width / 2)
            lower_dev = -math.floor(tol_width / 2)
        elif shaft_letter in ("a", "b", "c", "d", "e", "f", "g", "h"):
            # Holes A-H: EI (lower deviation) = negative of shaft es (upper deviation)
            shaft_es = SHAFT_FUNDAMENTAL_DEV[shaft_letter][ridx]
            lower_dev = -shaft_es  # EI = -es (positive for clearance holes)
            upper_dev = lower_dev + tol_width
        elif shaft_letter in SHAFT_FUNDAMENTAL_DEV:
            # Holes K-ZC: ES (upper deviation) = negative of shaft ei (lower deviation)
            shaft_ei = SHAFT_FUNDAMENTAL_DEV[shaft_letter][ridx]
            upper_dev = -shaft_ei  # ES = -ei (negative for interference holes)
            lower_dev = upper_dev - tol_width
        else:
            raise ValueError(f"Unsupported hole zone letter: {letter}")
    else:
        # Shaft: lowercase letter
        if letter == "js":
            # js: symmetric about zero
            upper_dev = math.ceil(tol_width / 2)
            lower_dev = -math.floor(tol_width / 2)
        elif letter in ("a", "b", "c", "d", "e", "f", "g", "h"):
            # Shafts a-h: es (upper deviation) from table, ei = es - tolerance
            es = SHAFT_FUNDAMENTAL_DEV[letter][ridx]
            upper_dev = es
            lower_dev = es - tol_width
        elif letter in SHAFT_FUNDAMENTAL_DEV:
            # Shafts k-zc: ei (lower deviation) from table, es = ei + tolerance
            ei = SHAFT_FUNDAMENTAL_DEV[letter][ridx]
            lower_dev = ei
            upper_dev = ei + tol_width
        else:
            raise ValueError(f"Unsupported shaft zone letter: {letter}")

    return {
        "zone": zone_str,
        "nominal": nominal_mm,
        "upper_dev_um": upper_dev,
        "lower_dev_um": lower_dev,
        "upper_mm": nominal_mm + upper_dev / 1000,
        "lower_mm": nominal_mm + lower_dev / 1000,
        "tolerance_um": tol_width,
    }


def fit_clearance(nominal_mm, hole_zone, shaft_zone):
    """
    Calculate fit clearance/interference for a hole/shaft pair.

    Args:
        nominal_mm: Nominal diameter in mm
        hole_zone: Hole tolerance zone (e.g., "H7")
        shaft_zone: Shaft tolerance zone (e.g., "g6")

    Returns:
        dict with keys:
            nominal, hole, shaft: zone lookup results
            min_clearance_mm: minimum clearance (negative = interference)
            max_clearance_mm: maximum clearance (negative = interference)
            fit_type: "clearance", "interference", or "transition"
    """
    hole = iso286_lookup(nominal_mm, hole_zone)
    shaft = iso286_lookup(nominal_mm, shaft_zone)

    # Clearance = hole size - shaft size
    # Min clearance = smallest hole - largest shaft
    min_cl = (hole["lower_dev_um"] - shaft["upper_dev_um"]) / 1000
    # Max clearance = largest hole - smallest shaft
    max_cl = (hole["upper_dev_um"] - shaft["lower_dev_um"]) / 1000

    if min_cl > 0:
        fit_type = "clearance"
    elif max_cl < 0:
        fit_type = "interference"
    else:
        fit_type = "transition"

    return {
        "nominal": nominal_mm,
        "hole": hole,
        "shaft": shaft,
        "min_clearance_mm": round(min_cl, 4),
        "max_clearance_mm": round(max_cl, 4),
        "fit_type": fit_type,
    }


def format_fit_report(nominal_mm, hole_zone, shaft_zone):
    """Format a human-readable fit report (consultant-mode output)."""
    fit = fit_clearance(nominal_mm, hole_zone, shaft_zone)
    h = fit["hole"]
    s = fit["shaft"]

    lines = [
        f"ISO 286 Fit Report: {hole_zone}/{shaft_zone} at D{nominal_mm}mm",
        f"{'='*50}",
        f"Hole {hole_zone}:  {h['lower_mm']:.3f} .. {h['upper_mm']:.3f} mm  "
        f"(+{h['lower_dev_um']}/+{h['upper_dev_um']} um)",
        f"Shaft {shaft_zone}: {s['lower_mm']:.3f} .. {s['upper_mm']:.3f} mm  "
        f"({s['lower_dev_um']:+d}/{s['upper_dev_um']:+d} um)",
        f"",
        f"Min clearance: {fit['min_clearance_mm']:+.4f} mm",
        f"Max clearance: {fit['max_clearance_mm']:+.4f} mm",
        f"Fit type: {fit['fit_type'].upper()}",
    ]

    # Consultant recommendation
    if fit["fit_type"] == "clearance":
        if fit["min_clearance_mm"] < 0.005:
            lines.append("\nNOTE: Very tight clearance. Ensure surface finish Ra < 0.8um.")
        else:
            lines.append(f"\nShaft slides freely in bore with {fit['min_clearance_mm']:.3f}mm minimum gap.")
    elif fit["fit_type"] == "interference":
        lines.append(f"\nPress fit. Assembly force required. Min interference: "
                     f"{abs(fit['max_clearance_mm']):.4f}mm.")
    else:
        lines.append("\nTransition fit. May be clearance or interference depending on actual sizes.")

    return "\n".join(lines)


# --- Common Fit Presets ---
COMMON_FITS = {
    "sliding":    ("H7", "g6"),   # Free running, good lubrication
    "location":   ("H7", "h6"),   # Sliding fit, easy assembly
    "transition": ("H7", "k6"),   # Light press, locating
    "press_light":("H7", "n6"),   # Light press fit
    "press":      ("H7", "p6"),   # Standard press fit
    "press_heavy":("H7", "r6"),   # Heavy press fit
    "loose":      ("H9", "d9"),   # Loose running, wide clearance
    "close":      ("H8", "f7"),   # Close running, moderate clearance
    "precision":  ("H6", "g5"),   # Precision running fit
}


def preset_fit(nominal_mm, preset_name):
    """Look up a common fit preset by name."""
    if preset_name not in COMMON_FITS:
        raise ValueError(f"Unknown preset '{preset_name}'. Available: {list(COMMON_FITS.keys())}")
    hole_zone, shaft_zone = COMMON_FITS[preset_name]
    return fit_clearance(nominal_mm, hole_zone, shaft_zone)


# --- Self-Test ---
def _run_tests():
    """Verify against known ISO 286 reference values."""
    passed = 0
    failed = 0

    def check(desc, actual, expected, tol=0.5):
        nonlocal passed, failed
        if abs(actual - expected) <= tol:
            passed += 1
            print(f"  PASS: {desc} = {actual} (expected {expected})")
        else:
            failed += 1
            print(f"  FAIL: {desc} = {actual} (expected {expected})")

    print("ISO 286 Lookup Self-Test")
    print("=" * 50)

    # Test 1: H7 at 25mm -> should be +0/+21 microns
    print("\nTest 1: H7 at 25mm")
    r = iso286_lookup(25, "H7")
    check("lower_dev_um", r["lower_dev_um"], 0)
    check("upper_dev_um", r["upper_dev_um"], 21)

    # Test 2: g6 at 25mm -> should be -7/-20 microns
    print("\nTest 2: g6 at 25mm")
    r = iso286_lookup(25, "g6")
    check("upper_dev_um", r["upper_dev_um"], -7)
    check("lower_dev_um", r["lower_dev_um"], -20)

    # Test 3: H7/g6 fit at 25mm -> clearance
    print("\nTest 3: H7/g6 fit at 25mm")
    f = fit_clearance(25, "H7", "g6")
    check("min_clearance_mm", f["min_clearance_mm"] * 1000, 7, tol=1)  # 0.007mm = 7um
    check("max_clearance_mm", f["max_clearance_mm"] * 1000, 41, tol=1)  # 0.041mm = 41um
    assert f["fit_type"] == "clearance", f"Expected clearance, got {f['fit_type']}"
    passed += 1
    print(f"  PASS: fit_type = {f['fit_type']}")

    # Test 4: h6 at 10mm -> should be 0/-9 microns
    print("\nTest 4: h6 at 10mm")
    r = iso286_lookup(10, "h6")
    check("upper_dev_um", r["upper_dev_um"], 0)
    check("lower_dev_um", r["lower_dev_um"], -9)

    # Test 5: H7/p6 at 50mm -> interference/transition
    print("\nTest 5: H7/p6 at 50mm")
    f = fit_clearance(50, "H7", "p6")
    print(f"  INFO: min_cl={f['min_clearance_mm']:.4f}mm, max_cl={f['max_clearance_mm']:.4f}mm")
    assert f["fit_type"] in ("interference", "transition"), f"Expected interference/transition, got {f['fit_type']}"
    passed += 1
    print(f"  PASS: fit_type = {f['fit_type']}")

    # Test 6: js6 at 25mm -> symmetric
    print("\nTest 6: js6 at 25mm")
    r = iso286_lookup(25, "js6")
    check("upper_dev_um", r["upper_dev_um"], 7, tol=1)  # +/-6.5 rounded
    check("lower_dev_um", r["lower_dev_um"], -6, tol=1)

    # Test 7: Diameter range boundaries
    print("\nTest 7: Range boundaries")
    r3 = iso286_lookup(3, "H7")    # Should use range 0 (>0, <=3)
    r6 = iso286_lookup(6, "H7")    # Should use range 1 (>3, <=6)
    check("H7@3mm upper", r3["upper_dev_um"], 10)
    check("H7@6mm upper", r6["upper_dev_um"], 12)

    # Test 8: Common fit presets
    print("\nTest 8: Fit presets")
    for name in COMMON_FITS:
        f = preset_fit(25, name)
        print(f"  {name:15s}: {f['fit_type']:12s}  cl=[{f['min_clearance_mm']:+.4f}, {f['max_clearance_mm']:+.4f}]mm")
    passed += 1
    print("  PASS: All presets computed without error")

    # Test 9: Full report format
    print("\nTest 9: Report format")
    report = format_fit_report(8, "H7", "g6")
    print(report)
    passed += 1
    print("  PASS: Report generated")

    print(f"\n{'='*50}")
    print(f"Results: {passed} passed, {failed} failed")
    return failed == 0


# --- CLI ---
if __name__ == "__main__":
    if "--test" in sys.argv:
        success = _run_tests()
        sys.exit(0 if success else 1)
    elif len(sys.argv) >= 3:
        nominal = float(sys.argv[1])
        fit_str = sys.argv[2]
        if "/" in fit_str:
            hole_z, shaft_z = fit_str.split("/")
            print(format_fit_report(nominal, hole_z, shaft_z))
        else:
            r = iso286_lookup(nominal, fit_str)
            print(f"Zone {r['zone']} at \u00d8{r['nominal']}mm:")
            print(f"  Limits: {r['lower_mm']:.3f} .. {r['upper_mm']:.3f} mm")
            print(f"  Deviations: {r['lower_dev_um']:+d} / {r['upper_dev_um']:+d} \u00b5m")
            print(f"  Tolerance: {r['tolerance_um']} \u00b5m")
    else:
        print("Usage:")
        print("  python iso286_lookup.py --test")
        print("  python iso286_lookup.py 25 H7/g6")
        print("  python iso286_lookup.py 25 H7")
