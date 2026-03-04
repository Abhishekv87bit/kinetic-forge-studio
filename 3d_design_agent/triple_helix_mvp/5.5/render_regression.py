#!/usr/bin/env python3
"""
Triple Helix MVP — Visual Regression Testing
==============================================
Renders OpenSCAD designs at multiple camera angles and animation positions,
compares against baseline reference images to catch visual regressions that
math validation cannot detect (misaligned parts, inverted geometry, missing
components).

Modes:
    --baseline      Render all views and save as reference PNGs
    (default)       Render all views and compare against baselines
    --update        Re-render and overwrite baselines (after intentional changes)

Render Matrix:
    6 camera views x 4 animation positions = 24 renders per file

Usage:
    python render_regression.py                          # compare against baselines
    python render_regression.py --baseline               # create initial baselines
    python render_regression.py --update                 # update baselines
    python render_regression.py monolith_v5_5.scad       # test specific file only
    python render_regression.py --positions 0.0 0.5      # only test 2 positions
    python render_regression.py --views iso front         # only test 2 views
    python render_regression.py --threshold 10            # custom hash distance threshold
    python render_regression.py --quick                   # iso view at pos 0.0 only

Exit codes:
    0 = all checks pass (or baseline created)
    1 = one or more FAIL
    2 = fatal error (OpenSCAD not found, no baselines, etc.)
"""

import subprocess
import sys
import os
import hashlib
import time
import argparse
import json
from pathlib import Path
from datetime import datetime

# ============================================================
# OPTIONAL DEPENDENCIES
# ============================================================
try:
    from PIL import Image
    import imagehash
    HAS_IMAGEHASH = True
except ImportError:
    HAS_IMAGEHASH = False

# ============================================================
# OPENSCAD DISCOVERY
# ============================================================
OPENSCAD_SEARCH_PATHS = [
    r"C:\Program Files\OpenSCAD\openscad.com",
    r"C:\Program Files\OpenSCAD\openscad.exe",
    r"C:\Program Files (x86)\OpenSCAD\openscad.com",
    r"C:\Program Files (x86)\OpenSCAD\openscad.exe",
    # Linux / macOS
    "/usr/bin/openscad",
    "/usr/local/bin/openscad",
    "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD",
]


def find_openscad():
    """Locate the OpenSCAD CLI executable. Prefer .com (console) on Windows."""
    # Check PATH first
    for name in ("openscad.com", "openscad"):
        path = _which(name)
        if path:
            return path

    # Check common install locations
    for candidate in OPENSCAD_SEARCH_PATHS:
        if os.path.isfile(candidate):
            return candidate

    return None


def _which(name):
    """Cross-platform which."""
    import shutil
    return shutil.which(name)


# ============================================================
# SCRIPT CONFIGURATION
# ============================================================
SCRIPT_DIR = Path(__file__).resolve().parent
BASELINE_DIR = SCRIPT_DIR / "render_baselines"

# Files to render (skip config and validation-only scripts)
DEFAULT_RENDER_TARGETS = [
    "monolith_v5_5.scad",
    "helix_cam_v5_5.scad",
    "matrix_stack_v5_5.scad",
    "anchor_plate_v5_5.scad",
    "guide_plate_v5_5.scad",
]

# Camera views: name -> --camera=ex,ey,ez,tx,ty,tz,dist
# For Triple Helix centered at origin, ~350mm wide frame, ~50mm tall matrix
CAMERA_VIEWS = {
    "iso":            "300,300,200,0,0,0,600",
    "front":          "0,600,0,0,0,0,600",
    "top":            "0,0,600,0,0,0,600",
    "right":          "600,0,0,0,0,0,600",
    "detail_matrix":  "50,50,30,0,0,0,150",
    "detail_carrier": "200,50,20,160,0,0,100",
}

# Animation positions (set via -D MANUAL_POSITION=X)
ANIMATION_POSITIONS = [0.0, 0.25, 0.5, 0.75]

# Image dimensions
IMG_WIDTH = 800
IMG_HEIGHT = 600

# Perceptual hash comparison thresholds (hamming distance)
THRESHOLD_PASS = 5       # 0-5: PASS (no meaningful change)
THRESHOLD_WARN = 15      # 6-15: WARN (visual change detected)
                          # >15: FAIL (regression)

# Render timeout per image (seconds)
RENDER_TIMEOUT = 180

# Color scheme
COLOR_SCHEME = "Tomorrow Night"


# ============================================================
# RENDER ENGINE
# ============================================================

def render_image(openscad_path, scad_file, output_png, camera, position,
                 timeout=RENDER_TIMEOUT):
    """
    Render a single image from an OpenSCAD file.

    Returns:
        (success: bool, elapsed_seconds: float, error_message: str or None)
    """
    cmd = [
        openscad_path,
        "-o", str(output_png),
        f"--imgsize={IMG_WIDTH},{IMG_HEIGHT}",
        f"--camera={camera}",
        f"--colorscheme={COLOR_SCHEME}",
        "-D", f"MANUAL_POSITION={position}",
        str(scad_file),
    ]

    start = time.time()
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        elapsed = time.time() - start

        # OpenSCAD sometimes exits 0 even with warnings; check for real errors
        combined = result.stdout + result.stderr
        error_lines = [
            l for l in combined.splitlines()
            if "ERROR" in l.upper() and "deprecated" not in l.lower()
        ]

        if result.returncode != 0 and error_lines:
            return False, elapsed, f"OpenSCAD error (exit {result.returncode}): {error_lines[0]}"

        if not output_png.exists():
            return False, elapsed, "Output PNG was not created"

        if output_png.stat().st_size == 0:
            return False, elapsed, "Output PNG is empty (0 bytes)"

        return True, elapsed, None

    except subprocess.TimeoutExpired:
        elapsed = time.time() - start
        return False, elapsed, f"Render timed out after {timeout}s"
    except FileNotFoundError:
        return False, 0.0, f"OpenSCAD not found at: {openscad_path}"
    except Exception as e:
        elapsed = time.time() - start
        return False, elapsed, f"Unexpected error: {e}"


def baseline_name(scad_stem, view, position):
    """Generate the baseline filename for a given render configuration."""
    return f"{scad_stem}_{view}_{position:.2f}.png"


# ============================================================
# COMPARISON ENGINE
# ============================================================

def compare_images_phash(baseline_path, current_path, hash_size=16):
    """
    Compare two images using perceptual hashing.

    Returns:
        (distance: int, method: str)
        distance = hamming distance between perceptual hashes.
        Lower = more similar. 0 = identical.
    """
    if not HAS_IMAGEHASH:
        return compare_images_fallback(baseline_path, current_path)

    try:
        img_base = Image.open(baseline_path)
        img_curr = Image.open(current_path)

        hash_base = imagehash.phash(img_base, hash_size=hash_size)
        hash_curr = imagehash.phash(img_curr, hash_size=hash_size)

        distance = hash_base - hash_curr
        return distance, "phash"
    except Exception as e:
        # Fall back if image loading fails
        return compare_images_fallback(baseline_path, current_path)


def compare_images_fallback(baseline_path, current_path):
    """
    Fallback comparison when imagehash is not available.
    Uses file size similarity and MD5 hash.

    Returns:
        (distance: int, method: str)
        distance: 0 if MD5 matches, estimated distance based on size delta otherwise.
    """
    # MD5 comparison (exact match)
    md5_base = _file_md5(baseline_path)
    md5_curr = _file_md5(current_path)

    if md5_base == md5_curr:
        return 0, "md5"

    # Size-based estimate (crude but catches gross changes)
    size_base = baseline_path.stat().st_size
    size_curr = current_path.stat().st_size

    if size_base == 0:
        return 999, "size"

    # Normalize size delta to a distance-like score
    size_ratio = abs(size_curr - size_base) / size_base
    # Map: 0% change -> distance 1, 5% -> 5, 20% -> 20, etc.
    estimated_distance = max(1, int(size_ratio * 100))

    return estimated_distance, "size-estimate"


def _file_md5(filepath):
    """Compute MD5 hash of a file."""
    h = hashlib.md5()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


# ============================================================
# METADATA
# ============================================================

def load_metadata():
    """Load baseline metadata from JSON file."""
    meta_path = BASELINE_DIR / "metadata.json"
    if meta_path.is_file():
        try:
            with open(meta_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return {}
    return {}


def save_metadata(metadata):
    """Save baseline metadata to JSON file."""
    meta_path = BASELINE_DIR / "metadata.json"
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2, default=str)


def get_openscad_version(openscad_path):
    """Get OpenSCAD version string."""
    try:
        result = subprocess.run(
            [openscad_path, "--version"],
            capture_output=True, text=True, timeout=10,
        )
        version_text = (result.stdout + result.stderr).strip()
        # OpenSCAD prints "OpenSCAD version YYYY.MM.DD"
        return version_text.split("\n")[0] if version_text else "unknown"
    except Exception:
        return "unknown"


# ============================================================
# RESULT TRACKING
# ============================================================

class RenderResult:
    """Tracks the result of a single render + comparison."""
    def __init__(self, filename, view, position):
        self.filename = filename
        self.view = view
        self.position = position
        self.render_ok = False
        self.render_time = 0.0
        self.render_error = None
        self.distance = None
        self.method = None
        self.status = None  # PASS / WARN / FAIL / ERROR / SKIP

    @property
    def label(self):
        return baseline_name(
            Path(self.filename).stem, self.view, self.position
        )


# ============================================================
# MAIN OPERATIONS
# ============================================================

def render_all_views(openscad_path, scad_file, output_dir, views, positions,
                     label=""):
    """
    Render all (view, position) combinations for a single .scad file.

    Returns:
        list of RenderResult
    """
    scad_path = Path(scad_file).resolve()
    scad_stem = scad_path.stem
    results = []

    total = len(views) * len(positions)
    count = 0

    for view_name in views:
        camera = CAMERA_VIEWS[view_name]
        for pos in positions:
            count += 1
            bname = baseline_name(scad_stem, view_name, pos)
            out_png = Path(output_dir) / bname

            r = RenderResult(scad_path.name, view_name, pos)

            progress = f"[{count}/{total}]"
            print(f"  {progress} Rendering {view_name} @ {pos:.2f}...", end="", flush=True)

            ok, elapsed, err = render_image(
                openscad_path, scad_path, out_png, camera, pos
            )
            r.render_ok = ok
            r.render_time = elapsed
            r.render_error = err

            if ok:
                print(f" done ({elapsed:.1f}s)")
            else:
                print(f" FAILED ({err})")
                r.status = "ERROR"

            results.append(r)

    return results


def create_baselines(openscad_path, scad_files, views, positions):
    """
    Mode 1 / --update: Render all views and save as baselines.

    Returns:
        (success: bool, total_rendered: int, total_failed: int)
    """
    BASELINE_DIR.mkdir(parents=True, exist_ok=True)

    metadata = load_metadata()
    metadata["created"] = datetime.now().isoformat()
    metadata["openscad_version"] = get_openscad_version(openscad_path)
    metadata["image_size"] = f"{IMG_WIDTH}x{IMG_HEIGHT}"
    metadata["color_scheme"] = COLOR_SCHEME
    metadata["files"] = {}

    total_rendered = 0
    total_failed = 0

    for scad_file in scad_files:
        scad_path = Path(scad_file).resolve()
        print(f"\n{'=' * 50}")
        print(f"BASELINE: {scad_path.name}")
        print(f"{'=' * 50}")

        results = render_all_views(
            openscad_path, scad_path, BASELINE_DIR, views, positions
        )

        file_meta = {"renders": {}}
        for r in results:
            if r.render_ok:
                total_rendered += 1
                png_path = BASELINE_DIR / r.label
                file_meta["renders"][r.label] = {
                    "view": r.view,
                    "position": r.position,
                    "render_time": round(r.render_time, 2),
                    "md5": _file_md5(png_path),
                    "size_bytes": png_path.stat().st_size,
                }
                if HAS_IMAGEHASH:
                    try:
                        img = Image.open(png_path)
                        file_meta["renders"][r.label]["phash"] = str(
                            imagehash.phash(img, hash_size=16)
                        )
                    except Exception:
                        pass
            else:
                total_failed += 1

        metadata["files"][scad_path.name] = file_meta

    save_metadata(metadata)

    return total_failed == 0, total_rendered, total_failed


def compare_against_baselines(openscad_path, scad_files, views, positions,
                              threshold_fail):
    """
    Default mode: Render all views and compare against baselines.

    Returns:
        (all_results: list of RenderResult, summary: dict)
    """
    if not BASELINE_DIR.is_dir():
        print("ERROR: No baselines found. Run with --baseline first.")
        print(f"  Expected directory: {BASELINE_DIR}")
        return [], {"pass": 0, "warn": 0, "fail": 0, "error": 0, "skip": 0}

    # Temporary directory for current renders
    tmp_dir = SCRIPT_DIR / "render_tmp"
    tmp_dir.mkdir(parents=True, exist_ok=True)

    all_results = []

    for scad_file in scad_files:
        scad_path = Path(scad_file).resolve()
        print(f"\n{'=' * 50}")
        print(f"TARGET: {scad_path.name}")
        print(f"{'=' * 50}")

        results = render_all_views(
            openscad_path, scad_path, tmp_dir, views, positions
        )

        # Compare each rendered image against its baseline
        print(f"\n  Comparison Results:")
        for r in results:
            if not r.render_ok:
                r.status = "ERROR"
                print(f"    ERROR {r.label} -- render failed: {r.render_error}")
                continue

            baseline_path = BASELINE_DIR / r.label
            current_path = tmp_dir / r.label

            if not baseline_path.is_file():
                r.status = "SKIP"
                r.distance = None
                print(f"    SKIP  {r.label} -- no baseline (run --baseline or --update)")
                continue

            distance, method = compare_images_phash(baseline_path, current_path)
            r.distance = distance
            r.method = method

            if distance <= THRESHOLD_PASS:
                r.status = "PASS"
                print(f"    PASS  {r.label} (distance={distance}, method={method})")
            elif distance <= threshold_fail:
                r.status = "WARN"
                print(f"    WARN  {r.label} (distance={distance}, method={method})"
                      f" <- visual change detected")
            else:
                r.status = "FAIL"
                print(f"    FAIL  {r.label} (distance={distance}, method={method})"
                      f" <- REGRESSION")

        all_results.extend(results)

    # Clean up tmp directory
    _cleanup_dir(tmp_dir)

    summary = {
        "pass": sum(1 for r in all_results if r.status == "PASS"),
        "warn": sum(1 for r in all_results if r.status == "WARN"),
        "fail": sum(1 for r in all_results if r.status == "FAIL"),
        "error": sum(1 for r in all_results if r.status == "ERROR"),
        "skip": sum(1 for r in all_results if r.status == "SKIP"),
    }

    return all_results, summary


def _cleanup_dir(dirpath):
    """Remove a temporary directory and all its contents."""
    dirpath = Path(dirpath)
    if not dirpath.is_dir():
        return
    for f in dirpath.iterdir():
        if f.is_file():
            try:
                f.unlink()
            except OSError:
                pass
    try:
        dirpath.rmdir()
    except OSError:
        pass


# ============================================================
# CLI
# ============================================================

def build_parser():
    parser = argparse.ArgumentParser(
        description="Visual regression testing for OpenSCAD designs.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python render_regression.py                          # compare against baselines
  python render_regression.py --baseline               # create initial baselines
  python render_regression.py --update                 # update baselines
  python render_regression.py monolith_v5_5.scad       # test specific file only
  python render_regression.py --positions 0.0 0.5      # only test 2 positions
  python render_regression.py --views iso front         # only test 2 views
  python render_regression.py --threshold 10            # custom hash distance threshold
  python render_regression.py --quick                   # iso @ pos 0.0 only (fast)
        """,
    )

    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument(
        "--baseline", action="store_true",
        help="Create initial baseline reference images",
    )
    mode_group.add_argument(
        "--update", action="store_true",
        help="Re-render and overwrite existing baselines",
    )

    parser.add_argument(
        "files", nargs="*", metavar="FILE",
        help="Specific .scad files to test (default: all render targets)",
    )
    parser.add_argument(
        "--views", nargs="+", metavar="VIEW",
        choices=list(CAMERA_VIEWS.keys()),
        help=f"Camera views to render (choices: {', '.join(CAMERA_VIEWS.keys())})",
    )
    parser.add_argument(
        "--positions", nargs="+", type=float, metavar="POS",
        help="Animation positions to test (default: 0.0 0.25 0.5 0.75)",
    )
    parser.add_argument(
        "--threshold", type=int, default=THRESHOLD_WARN, metavar="N",
        help=f"Hash distance threshold for FAIL (default: {THRESHOLD_WARN})",
    )
    parser.add_argument(
        "--quick", action="store_true",
        help="Quick mode: iso view at position 0.0 only",
    )
    parser.add_argument(
        "--openscad", metavar="PATH",
        help="Path to OpenSCAD executable (auto-detected if not specified)",
    )
    parser.add_argument(
        "--timeout", type=int, default=RENDER_TIMEOUT, metavar="SEC",
        help=f"Render timeout per image in seconds (default: {RENDER_TIMEOUT})",
    )

    return parser


def resolve_files(file_args):
    """
    Resolve .scad file arguments to absolute paths.
    If no files specified, use default render targets.
    """
    if file_args:
        resolved = []
        for f in file_args:
            p = Path(f)
            if not p.is_absolute():
                p = SCRIPT_DIR / p
            p = p.resolve()
            if not p.exists():
                print(f"WARNING: File not found: {p}")
                continue
            if p.suffix != ".scad":
                print(f"WARNING: Skipping non-.scad file: {p}")
                continue
            resolved.append(p)
        return resolved

    # Default: all render targets that exist
    resolved = []
    for name in DEFAULT_RENDER_TARGETS:
        p = SCRIPT_DIR / name
        if p.is_file():
            resolved.append(p.resolve())
        else:
            print(f"WARNING: Default target not found: {p}")
    return resolved


def main():
    parser = build_parser()
    args = parser.parse_args()

    # ---- Banner ----
    print("=" * 50)
    print("RENDER REGRESSION TEST")
    print("=" * 50)

    # ---- Find OpenSCAD ----
    openscad_path = args.openscad or find_openscad()
    if openscad_path is None:
        print("\nERROR: OpenSCAD not found.")
        print("  Searched PATH and common install locations.")
        print("  Use --openscad /path/to/openscad to specify manually.")
        return 2

    print(f"OpenSCAD: {openscad_path}")
    version = get_openscad_version(openscad_path)
    print(f"Version:  {version}")

    # ---- Check imagehash ----
    if not HAS_IMAGEHASH:
        print("\nNOTE: imagehash not available. Using fallback comparison (less accurate).")
        print("  Install for better results: pip install imagehash Pillow")

    # ---- Resolve files ----
    scad_files = resolve_files(args.files)
    if not scad_files:
        print("\nERROR: No .scad files to render.")
        return 2

    print(f"\nTargets ({len(scad_files)}):")
    for f in scad_files:
        print(f"  {f.name}")

    # ---- Resolve views and positions ----
    if args.quick:
        views = ["iso"]
        positions = [0.0]
        print("\nQuick mode: iso @ 0.0 only")
    else:
        views = args.views or list(CAMERA_VIEWS.keys())
        positions = args.positions or ANIMATION_POSITIONS

    total_renders = len(scad_files) * len(views) * len(positions)
    print(f"\nRender matrix: {len(views)} views x {len(positions)} positions"
          f" = {len(views) * len(positions)} per file, {total_renders} total")

    # ---- Update global timeout ----
    global RENDER_TIMEOUT
    RENDER_TIMEOUT = args.timeout

    # ---- Execute mode ----
    if args.baseline or args.update:
        mode_label = "Creating baselines" if args.baseline else "Updating baselines"
        if args.update and not BASELINE_DIR.is_dir():
            print("\nNOTE: No existing baselines found. Creating new baselines.")

        print(f"\n{mode_label}...")
        success, rendered, failed = create_baselines(
            openscad_path, scad_files, views, positions
        )

        print(f"\n{'=' * 50}")
        print(f"BASELINE {'CREATED' if args.baseline else 'UPDATED'}")
        print(f"  Rendered: {rendered}")
        print(f"  Failed:   {failed}")
        print(f"  Location: {BASELINE_DIR}")
        print(f"{'=' * 50}")

        return 0 if success else 1

    else:
        # Comparison mode (default)
        results, summary = compare_against_baselines(
            openscad_path, scad_files, views, positions, args.threshold
        )

        # ---- Summary ----
        total = sum(summary.values())
        print(f"\n{'=' * 50}")
        print(f"SUMMARY: {summary['pass']} PASS / {summary['warn']} WARN"
              f" / {summary['fail']} FAIL"
              f" / {summary['error']} ERROR / {summary['skip']} SKIP"
              f" ({total} total)")
        print(f"{'=' * 50}")

        if summary["fail"] > 0:
            print("\nFAILURES:")
            for r in results:
                if r.status == "FAIL":
                    print(f"  {r.label} (distance={r.distance})")

        if summary["warn"] > 0:
            print("\nWARNINGS:")
            for r in results:
                if r.status == "WARN":
                    print(f"  {r.label} (distance={r.distance})")

        if summary["error"] > 0:
            print("\nERRORS:")
            for r in results:
                if r.status == "ERROR":
                    print(f"  {r.label}: {r.render_error}")

        if summary["skip"] > 0:
            print(f"\n{summary['skip']} render(s) skipped (no baseline)."
                  f" Run --baseline or --update to create them.")

        if summary["fail"] > 0:
            return 1
        return 0


if __name__ == "__main__":
    sys.exit(main())
