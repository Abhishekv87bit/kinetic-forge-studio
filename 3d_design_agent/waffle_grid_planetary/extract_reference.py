#!/usr/bin/env python3
"""
Reference Extraction — Rule 500 Step 4.5
=========================================
Analyzes STL reference meshes (e.g. Ford 4R70W Ravigneaux gearset)
to extract per-component dimensional constraints.

Outputs reference_dimensions.json used by validate_geometry.py
as ground-truth for Z-overlap, radial envelope, and proportion checks.

Usage:
    python extract_reference.py                        # analyze default ref dir
    python extract_reference.py --ref-dir <path>       # custom ref dir
    python extract_reference.py --output <path>        # custom output path
    python extract_reference.py --verbose              # show per-vertex stats

Exit code: 0 on success, 1 on failure.
"""

import sys
import os
import json
import argparse
import math
from pathlib import Path
from datetime import datetime

try:
    import trimesh
    import numpy as np
except ImportError:
    print("ERROR: trimesh and numpy required. Install: pip install trimesh numpy")
    sys.exit(1)

# ================================================================
# DEFAULTS
# ================================================================
SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_REF_DIR = Path(
    "D:/Claude local/3d_design_agent/gears/"
    "automatic-transmission-double-planetary-gearset-ravigneaux-model_files"
)
DEFAULT_OUTPUT = SCRIPT_DIR / "reference_dimensions.json"

# ================================================================
# COMPONENT ROLE MAPPING
# ================================================================
# Maps STL filename stems to Ravigneaux component roles.
# This is specific to the Ford 4R70W reference model.
ROLE_MAP = {
    "big_sun_0_5_backlash": {
        "role": "large_sun",
        "abbreviation": "SL",
        "description": "Large sun gear (meshes with long pinion Po)",
        "rotates": True,
        "mesh_partners": ["long_pinion"],
    },
    "small_sun": {
        "role": "small_sun",
        "abbreviation": "Ss",
        "description": "Small sun gear (meshes with short pinion Pi)",
        "rotates": True,
        "mesh_partners": ["short_pinion"],
    },
    "long_pinion": {
        "role": "long_pinion",
        "abbreviation": "Po",
        "description": "Long/outer planet pinion (spans both gear zones)",
        "rotates": True,
        "mesh_partners": ["big_sun_0_5_backlash", "ring_low_profile", "short_pinion"],
    },
    "short_pinion": {
        "role": "short_pinion",
        "abbreviation": "Pi",
        "description": "Short/inner planet pinion (Ss zone only)",
        "rotates": True,
        "mesh_partners": ["small_sun", "long_pinion"],
    },
    "ring_low_profile": {
        "role": "ring_gear",
        "abbreviation": "R",
        "description": "Ring/annulus gear (internal teeth, meshes with Po)",
        "rotates": False,
        "mesh_partners": ["long_pinion"],
    },
    "planetary_1": {
        "role": "carrier_plate_1",
        "abbreviation": "C1",
        "description": "Carrier plate 1 (front/output side)",
        "rotates": True,
        "mesh_partners": [],
    },
    "planetary_2": {
        "role": "carrier_plate_2",
        "abbreviation": "C2",
        "description": "Carrier plate 2 (middle separator)",
        "rotates": True,
        "mesh_partners": [],
    },
    "planetary_3": {
        "role": "carrier_plate_3",
        "abbreviation": "C3",
        "description": "Carrier plate 3 (rear side)",
        "rotates": True,
        "mesh_partners": [],
    },
    "shaft": {
        "role": "central_shaft",
        "abbreviation": "SH",
        "description": "Central input/output shaft",
        "rotates": True,
        "mesh_partners": [],
    },
    "clip": {
        "role": "retaining_clip",
        "abbreviation": "CL",
        "description": "Snap ring / retaining clip",
        "rotates": False,
        "mesh_partners": [],
    },
    "small_washer": {
        "role": "thrust_washer",
        "abbreviation": "TW",
        "description": "Thrust washer (axial load bearing)",
        "rotates": False,
        "mesh_partners": [],
    },
    "big_sun_ring": {
        "role": "sun_retainer_large",
        "abbreviation": "SRL",
        "description": "Large sun gear retaining ring",
        "rotates": False,
        "mesh_partners": [],
    },
    "small_sun_ring": {
        "role": "sun_retainer_small",
        "abbreviation": "SRS",
        "description": "Small sun gear retaining ring",
        "rotates": False,
        "mesh_partners": [],
    },
}


def analyze_stl(filepath, verbose=False):
    """
    Analyze a single STL file and extract dimensional data.

    Returns dict with:
        - bounding_box: {x_min, x_max, y_min, y_max, z_min, z_max}
        - radial_envelope: {r_min, r_max, r_mean} (from XY center)
        - axial_range: {z_bot, z_top, height}
        - mesh_stats: {vertices, faces, volume, is_watertight}
        - center_of_mass: [x, y, z]
    """
    mesh = trimesh.load(filepath)

    if not isinstance(mesh, trimesh.Trimesh):
        return None

    vertices = np.array(mesh.vertices)
    bounds = mesh.bounds  # [[min_x, min_y, min_z], [max_x, max_y, max_z]]

    # Radial analysis (distance from Z-axis in XY plane)
    xy_distances = np.sqrt(vertices[:, 0]**2 + vertices[:, 1]**2)
    r_min = float(np.min(xy_distances))
    r_max = float(np.max(xy_distances))
    r_mean = float(np.mean(xy_distances))

    # Radial profile at multiple Z-slices for detailed analysis
    z_min_val = float(bounds[0][2])
    z_max_val = float(bounds[1][2])
    z_height = z_max_val - z_min_val

    # Sample radial profile at 10 Z-slices
    radial_profile = []
    if z_height > 0.01:
        n_slices = 10
        for i in range(n_slices):
            z_level = z_min_val + (i + 0.5) * z_height / n_slices
            # Vertices near this Z level (+/- 5% of height)
            z_tol = max(z_height * 0.05, 0.1)
            mask = np.abs(vertices[:, 2] - z_level) < z_tol
            if np.sum(mask) > 3:
                slice_r = np.sqrt(vertices[mask, 0]**2 + vertices[mask, 1]**2)
                radial_profile.append({
                    "z": round(z_level, 3),
                    "r_min": round(float(np.min(slice_r)), 3),
                    "r_max": round(float(np.max(slice_r)), 3),
                })

    # Volume and watertight check
    is_watertight = bool(mesh.is_watertight)
    volume = float(mesh.volume) if is_watertight else None

    # Center of mass
    try:
        com = mesh.center_mass.tolist()
    except Exception:
        com = [(bounds[0][i] + bounds[1][i]) / 2 for i in range(3)]

    result = {
        "bounding_box": {
            "x_min": round(float(bounds[0][0]), 3),
            "x_max": round(float(bounds[1][0]), 3),
            "y_min": round(float(bounds[0][1]), 3),
            "y_max": round(float(bounds[1][1]), 3),
            "z_min": round(float(bounds[0][2]), 3),
            "z_max": round(float(bounds[1][2]), 3),
        },
        "radial_envelope": {
            "r_min": round(r_min, 3),
            "r_max": round(r_max, 3),
            "r_mean": round(r_mean, 3),
        },
        "axial_range": {
            "z_bot": round(z_min_val, 3),
            "z_top": round(z_max_val, 3),
            "height": round(z_height, 3),
        },
        "mesh_stats": {
            "vertices": len(mesh.vertices),
            "faces": len(mesh.faces),
            "volume_mm3": round(volume, 2) if volume else None,
            "is_watertight": is_watertight,
        },
        "center_of_mass": [round(c, 3) for c in com],
        "radial_profile": radial_profile,
    }

    if verbose:
        print(f"  Vertices: {len(mesh.vertices)}, Faces: {len(mesh.faces)}")
        print(f"  Radial: r_min={r_min:.2f}, r_max={r_max:.2f}")
        print(f"  Axial:  z_bot={z_min_val:.2f}, z_top={z_max_val:.2f}, h={z_height:.2f}")
        print(f"  Watertight: {is_watertight}")

    return result


def compute_proportions(components):
    """
    Compute relative proportions and ratios between components.
    These become validation constraints for our model.
    """
    proportions = {}

    # Get key components
    sl = components.get("big_sun_0_5_backlash")
    ss = components.get("small_sun")
    po = components.get("long_pinion")
    pi_comp = components.get("short_pinion")
    ring = components.get("ring_low_profile")

    if not all([sl, ss, po, pi_comp, ring]):
        return proportions

    sl_data = sl["dimensions"]
    ss_data = ss["dimensions"]
    po_data = po["dimensions"]
    pi_data = pi_comp["dimensions"]
    ring_data = ring["dimensions"]

    # Sun gear diameter ratio (SL/Ss)
    sl_od = sl_data["radial_envelope"]["r_max"] * 2
    ss_od = ss_data["radial_envelope"]["r_max"] * 2
    if ss_od > 0:
        proportions["sun_diameter_ratio_SL_over_Ss"] = round(sl_od / ss_od, 3)

    # Planet height ratio (Po spans more Z than Pi)
    po_h = po_data["axial_range"]["height"]
    pi_h = pi_data["axial_range"]["height"]
    if pi_h > 0:
        proportions["planet_height_ratio_Po_over_Pi"] = round(po_h / pi_h, 3)

    # Ring ID vs SL OD (must have clearance)
    ring_id = ring_data["radial_envelope"]["r_min"] * 2
    proportions["ring_ID_mm"] = round(ring_id, 2)
    proportions["SL_OD_mm"] = round(sl_od, 2)
    proportions["Ss_OD_mm"] = round(ss_od, 2)
    proportions["ring_OD_mm"] = round(ring_data["radial_envelope"]["r_max"] * 2, 2)
    proportions["Po_OD_mm"] = round(po_data["radial_envelope"]["r_max"] * 2, 2)
    proportions["Pi_OD_mm"] = round(pi_data["radial_envelope"]["r_max"] * 2, 2)

    # Z-stacking order (critical for Ravigneaux validation)
    z_order = []
    for name, comp in components.items():
        d = comp["dimensions"]
        z_order.append({
            "component": name,
            "role": comp.get("role", "unknown"),
            "z_bot": d["axial_range"]["z_bot"],
            "z_top": d["axial_range"]["z_top"],
            "height": d["axial_range"]["height"],
        })
    z_order.sort(key=lambda x: x["z_bot"])
    proportions["z_stacking_order"] = z_order

    # Axial overlap matrix (which components share Z-space)
    overlaps = []
    names = list(components.keys())
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            a = components[names[i]]["dimensions"]["axial_range"]
            b = components[names[j]]["dimensions"]["axial_range"]
            # Overlap exists if one's z_bot < other's z_top AND vice versa
            overlap = min(a["z_top"], b["z_top"]) - max(a["z_bot"], b["z_bot"])
            if overlap > 0.01:  # > 0.01mm overlap
                overlaps.append({
                    "pair": [names[i], names[j]],
                    "overlap_mm": round(overlap, 3),
                    "a_range": [a["z_bot"], a["z_top"]],
                    "b_range": [b["z_bot"], b["z_top"]],
                })
    proportions["axial_overlaps"] = overlaps

    # Radial overlap matrix (which components share radial space)
    radial_overlaps = []
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            a = components[names[i]]["dimensions"]["radial_envelope"]
            b = components[names[j]]["dimensions"]["radial_envelope"]
            r_overlap = min(a["r_max"], b["r_max"]) - max(a["r_min"], b["r_min"])
            if r_overlap > 0.01:
                radial_overlaps.append({
                    "pair": [names[i], names[j]],
                    "radial_overlap_mm": round(r_overlap, 3),
                    "a_range": [a["r_min"], a["r_max"]],
                    "b_range": [b["r_min"], b["r_max"]],
                })
    proportions["radial_overlaps"] = radial_overlaps

    return proportions


def compute_ravigneaux_constraints(components, proportions):
    """
    Derive Ravigneaux-specific structural constraints from reference geometry.
    These become hard rules for the validator.
    """
    constraints = {}

    sl = components.get("big_sun_0_5_backlash")
    ss = components.get("small_sun")
    po = components.get("long_pinion")
    pi_comp = components.get("short_pinion")
    ring = components.get("ring_low_profile")

    if not all([sl, ss, po, pi_comp, ring]):
        return constraints

    sl_z = sl["dimensions"]["axial_range"]
    ss_z = ss["dimensions"]["axial_range"]
    po_z = po["dimensions"]["axial_range"]
    pi_z = pi_comp["dimensions"]["axial_range"]
    ring_z = ring["dimensions"]["axial_range"]

    # RULE: Two-zone axiom — Ss and SL must NOT fully overlap in Z
    ss_sl_overlap = min(sl_z["z_top"], ss_z["z_top"]) - max(sl_z["z_bot"], ss_z["z_bot"])
    constraints["two_zone_axiom"] = {
        "description": "Ss and SL sun gears must be in separate Z-zones (minimal or no overlap)",
        "ss_z_range": [ss_z["z_bot"], ss_z["z_top"]],
        "sl_z_range": [sl_z["z_bot"], sl_z["z_top"]],
        "overlap_mm": round(max(0, ss_sl_overlap), 3),
        "separation_mm": round(max(0, -ss_sl_overlap), 3),
        "rule": "overlap <= 0 (ideally separated by thrust plate thickness)",
    }

    # RULE: Long pinion spans both zones
    po_spans_ss = (po_z["z_bot"] <= ss_z["z_bot"] + 0.5) and (po_z["z_top"] >= ss_z["z_top"] - 0.5)
    po_spans_sl = (po_z["z_bot"] <= sl_z["z_bot"] + 0.5) and (po_z["z_top"] >= sl_z["z_top"] - 0.5)
    constraints["long_pinion_span"] = {
        "description": "Long pinion (Po) must span both Ss and SL gear zones",
        "po_z_range": [po_z["z_bot"], po_z["z_top"]],
        "spans_ss_zone": po_spans_ss,
        "spans_sl_zone": po_spans_sl,
        "rule": "Po z_range must encompass both Ss and SL z_ranges",
    }

    # RULE: Short pinion only in Ss zone
    pi_in_ss = (pi_z["z_bot"] >= ss_z["z_bot"] - 1.0) and (pi_z["z_top"] <= ss_z["z_top"] + 1.0)
    pi_in_sl = (pi_z["z_bot"] >= sl_z["z_bot"] - 1.0) and (pi_z["z_top"] <= sl_z["z_top"] + 1.0)
    constraints["short_pinion_zone"] = {
        "description": "Short pinion (Pi) must be confined to Ss gear zone only",
        "pi_z_range": [pi_z["z_bot"], pi_z["z_top"]],
        "within_ss_zone": pi_in_ss,
        "overlaps_sl_zone": pi_in_sl,
        "rule": "Pi z_range must be within Ss z_range (not SL)",
    }

    # RULE: Ring spans full gear height
    constraints["ring_span"] = {
        "description": "Ring gear must span the full combined gear zone height",
        "ring_z_range": [ring_z["z_bot"], ring_z["z_top"]],
        "combined_gear_z": [
            min(ss_z["z_bot"], sl_z["z_bot"]),
            max(ss_z["z_top"], sl_z["z_top"]),
        ],
        "rule": "Ring z_range >= combined Ss+SL z_range",
    }

    # RULE: Height ratios (for proportional scaling)
    constraints["height_ratios"] = {
        "description": "Reference height ratios for proportional scaling",
        "po_height_mm": po_z["height"],
        "pi_height_mm": pi_z["height"],
        "ss_height_mm": ss_z["height"],
        "sl_height_mm": sl_z["height"],
        "ring_height_mm": ring_z["height"],
        "po_to_pi_ratio": round(po_z["height"] / pi_z["height"], 3) if pi_z["height"] > 0 else None,
        "po_to_ring_ratio": round(po_z["height"] / ring_z["height"], 3) if ring_z["height"] > 0 else None,
    }

    # RULE: Radial nesting (sun inside planet inside ring)
    ss_r = ss["dimensions"]["radial_envelope"]["r_max"]
    sl_r = sl["dimensions"]["radial_envelope"]["r_max"]
    po_r = po["dimensions"]["radial_envelope"]["r_max"]
    pi_r = pi_comp["dimensions"]["radial_envelope"]["r_max"]
    ring_r_inner = ring["dimensions"]["radial_envelope"]["r_min"]
    ring_r_outer = ring["dimensions"]["radial_envelope"]["r_max"]

    constraints["radial_nesting"] = {
        "description": "Radial nesting order: sun < planet < ring",
        "ss_r_max": round(ss_r, 2),
        "sl_r_max": round(sl_r, 2),
        "po_r_max": round(po_r, 2),
        "pi_r_max": round(pi_r, 2),
        "ring_r_inner": round(ring_r_inner, 2),
        "ring_r_outer": round(ring_r_outer, 2),
        "rule": "max(Ss_r, SL_r) < planet_orbit_r < ring_r_inner",
    }

    return constraints


def main():
    parser = argparse.ArgumentParser(
        description="Rule 500 Step 4.5: Reference Extraction"
    )
    parser.add_argument(
        "--ref-dir", type=Path, default=DEFAULT_REF_DIR,
        help="Directory containing reference STL files"
    )
    parser.add_argument(
        "--output", type=Path, default=DEFAULT_OUTPUT,
        help="Output JSON file path"
    )
    parser.add_argument(
        "--verbose", action="store_true",
        help="Show detailed per-component analysis"
    )
    args = parser.parse_args()

    print("=" * 60)
    print("  RULE 500 — Step 4.5: Reference Extraction")
    print("=" * 60)

    if not args.ref_dir.is_dir():
        print(f"ERROR: Reference directory not found: {args.ref_dir}")
        sys.exit(1)

    # Find all STL files
    stl_files = sorted(args.ref_dir.glob("*.stl"))
    if not stl_files:
        print(f"ERROR: No STL files found in {args.ref_dir}")
        sys.exit(1)

    print(f"\nReference directory: {args.ref_dir}")
    print(f"Found {len(stl_files)} STL files\n")

    # Analyze each STL
    components = {}
    for stl_path in stl_files:
        stem = stl_path.stem
        print(f"  Analyzing: {stl_path.name} ...", end=" ")

        role_info = ROLE_MAP.get(stem, {
            "role": stem,
            "abbreviation": "??",
            "description": f"Unknown component: {stem}",
            "rotates": False,
            "mesh_partners": [],
        })

        dims = analyze_stl(stl_path, verbose=args.verbose)
        if dims is None:
            print("SKIP (not a valid mesh)")
            continue

        components[stem] = {
            "file": stl_path.name,
            "role": role_info["role"],
            "abbreviation": role_info["abbreviation"],
            "description": role_info["description"],
            "rotates": role_info["rotates"],
            "mesh_partners": role_info["mesh_partners"],
            "dimensions": dims,
        }
        h = dims["axial_range"]["height"]
        r = dims["radial_envelope"]["r_max"]
        print(f"OK  (h={h:.1f}mm, r_max={r:.1f}mm)")

    print(f"\n  Analyzed {len(components)} components successfully")

    # Compute proportions and constraints
    print("\n  Computing proportions and constraints...")
    proportions = compute_proportions(components)
    constraints = compute_ravigneaux_constraints(components, proportions)

    # Build output
    output = {
        "_metadata": {
            "generated_by": "extract_reference.py (Rule 500 Step 4.5)",
            "generated_at": datetime.now().isoformat(),
            "reference_source": str(args.ref_dir),
            "reference_model": "Ford 4R70W Ravigneaux Double Planetary",
            "stl_count": len(stl_files),
            "components_analyzed": len(components),
        },
        "components": components,
        "proportions": proportions,
        "ravigneaux_constraints": constraints,
    }

    # Write output
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"\n  Output: {args.output}")
    print(f"  File size: {args.output.stat().st_size:,} bytes")

    # Summary
    print(f"\n{'='*60}")
    print("  REFERENCE EXTRACTION SUMMARY")
    print(f"{'='*60}")

    # Z-stacking order
    if "z_stacking_order" in proportions:
        print("\n  Z-Stacking Order (bottom to top):")
        for item in proportions["z_stacking_order"]:
            role = item["role"]
            z_b = item["z_bot"]
            z_t = item["z_top"]
            h = item["height"]
            print(f"    {role:25s} Z=[{z_b:7.2f} .. {z_t:7.2f}]  h={h:6.2f}mm")

    # Axial overlaps
    if "axial_overlaps" in proportions:
        print(f"\n  Axial Overlaps ({len(proportions['axial_overlaps'])} pairs):")
        for ov in proportions["axial_overlaps"][:15]:
            a, b = ov["pair"]
            print(f"    {a:25s} <-> {b:25s}  overlap={ov['overlap_mm']:.2f}mm")

    # Ravigneaux constraints
    if constraints:
        print("\n  Ravigneaux Structural Constraints:")
        tz = constraints.get("two_zone_axiom", {})
        if tz:
            sep = tz.get("separation_mm", 0)
            ovl = tz.get("overlap_mm", 0)
            status = "SEPARATED" if sep > 0 else f"OVERLAP {ovl:.1f}mm"
            print(f"    Two-Zone Axiom: Ss{tz.get('ss_z_range')} vs SL{tz.get('sl_z_range')} -> {status}")

        lp = constraints.get("long_pinion_span", {})
        if lp:
            print(f"    Long Pinion Span: Po{lp.get('po_z_range')} spans_Ss={lp.get('spans_ss_zone')} spans_SL={lp.get('spans_sl_zone')}")

        sp = constraints.get("short_pinion_zone", {})
        if sp:
            print(f"    Short Pinion Zone: Pi{sp.get('pi_z_range')} in_Ss={sp.get('within_ss_zone')} in_SL={sp.get('overlaps_sl_zone')}")

        hr = constraints.get("height_ratios", {})
        if hr:
            print(f"    Height Ratios: Po/Pi={hr.get('po_to_pi_ratio')}, Po/Ring={hr.get('po_to_ring_ratio')}")

    print(f"\n{'='*60}")
    print("  PASS — Reference extraction complete")
    print(f"{'='*60}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
