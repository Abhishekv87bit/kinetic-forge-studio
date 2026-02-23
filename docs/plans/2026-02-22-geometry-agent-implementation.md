# Geometry Agent Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a three-layer geometry agent (Intent Translator + Orchestrator + Geometry Kernel) that validates, renders, and analyzes 3D CAD models locally using OpenSCAD, Build123d, and trimesh.

**Architecture:** CLI tool (`geometry-agent`) with Click framework. Ports existing validation scripts into a unified package. Adds collision detection (trimesh+FCL), visual diff (Pillow), and B-Rep analysis (Build123d/OCP). Claude Code hooks auto-trigger on .scad edits.

**Tech Stack:** Python 3.11+, Click, trimesh, python-fcl, Build123d, Pillow, PyYAML, Rich, SolidPython2

**Design Doc:** `docs/plans/2026-02-22-geometry-agent-design.md`

---

## Phase 1: Foundation (Tasks 1-7)

### Task 1: Project Scaffolding

**Files:**
- Create: `geometry-agent/pyproject.toml`
- Create: `geometry-agent/src/geometry_agent/__init__.py`
- Create: `geometry-agent/src/geometry_agent/cli.py`
- Create: `geometry-agent/src/geometry_agent/config.py`
- Create: `geometry-agent/tests/__init__.py`
- Create: `geometry-agent/tests/test_cli.py`

**Step 1: Create directory structure**

```bash
mkdir -p "D:/Claude local/geometry-agent/src/geometry_agent"
mkdir -p "D:/Claude local/geometry-agent/tests/fixtures"
mkdir -p "D:/Claude local/geometry-agent/knowledge"
mkdir -p "D:/Claude local/geometry-agent/constraints"
mkdir -p "D:/Claude local/geometry-agent/hooks"
```

**Step 2: Write pyproject.toml**

```toml
[project]
name = "geometry-agent"
version = "0.1.0"
description = "Open-source geometry agent for CAD validation, collision detection, and design guidance"
requires-python = ">=3.11"

dependencies = [
    "click>=8.0",
    "pyyaml>=6.0",
    "rich>=13.0",
    "Pillow>=10.0",
    "numpy>=1.24",
]

[project.optional-dependencies]
collision = ["trimesh[easy]>=4.0", "python-fcl>=0.7"]
brep = ["build123d>=0.7"]
full = ["geometry-agent[collision,brep]"]
dev = ["pytest>=8.0", "pytest-cov>=4.0"]

[project.scripts]
geometry-agent = "geometry_agent.cli:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.pytest.ini_options]
testpaths = ["tests"]
```

**Step 3: Write minimal CLI skeleton**

```python
# src/geometry_agent/__init__.py
__version__ = "0.1.0"
```

```python
# src/geometry_agent/cli.py
import click
from rich.console import Console

console = Console()

@click.group()
@click.version_option()
def main():
    """Geometry Agent - Open-source CAD validation and analysis."""
    pass

@main.command()
@click.argument("scad_file", type=click.Path(exists=True))
def compile(scad_file):
    """Compile an OpenSCAD file (zero warnings required)."""
    console.print(f"[bold]Compiling[/bold] {scad_file}...")

@main.command()
@click.argument("scad_file", type=click.Path(exists=True))
def validate(scad_file):
    """Run constraint checks on a .scad file."""
    console.print(f"[bold]Validating[/bold] {scad_file}...")

@main.command()
@click.argument("scad_file", type=click.Path(exists=True))
@click.option("--views", default="isometric", help="Comma-separated view names")
def render(scad_file, views):
    """Render multi-view PNGs of a .scad file."""
    console.print(f"[bold]Rendering[/bold] {scad_file} [{views}]...")

if __name__ == "__main__":
    main()
```

```python
# src/geometry_agent/config.py
import os
from pathlib import Path

OPENSCAD_NIGHTLY = Path(r"C:/Program Files/OpenSCAD (Nightly)/openscad.com")
OPENSCAD_STABLE = Path(r"C:/Program Files/OpenSCAD/openscad.com")
OPENSCADPATH = os.environ.get("OPENSCADPATH", r"C:\Users\abhis\Documents\OpenSCAD\libraries")

def get_openscad_binary() -> Path:
    """Return the best available OpenSCAD binary (prefer Nightly)."""
    if OPENSCAD_NIGHTLY.exists():
        return OPENSCAD_NIGHTLY
    if OPENSCAD_STABLE.exists():
        return OPENSCAD_STABLE
    raise FileNotFoundError("OpenSCAD not found. Install from openscad.org")
```

**Step 4: Write test to verify CLI loads**

```python
# tests/test_cli.py
from click.testing import CliRunner
from geometry_agent.cli import main

def test_cli_version():
    runner = CliRunner()
    result = runner.invoke(main, ["--version"])
    assert result.exit_code == 0
    assert "0.1.0" in result.output

def test_cli_help():
    runner = CliRunner()
    result = runner.invoke(main, ["--help"])
    assert result.exit_code == 0
    assert "compile" in result.output
    assert "validate" in result.output
    assert "render" in result.output
```

**Step 5: Install in dev mode and run tests**

```bash
cd "D:/Claude local/geometry-agent"
pip install -e ".[dev]"
pytest tests/test_cli.py -v
```

Expected: 2 tests PASS

**Step 6: Commit**

```bash
git add geometry-agent/
git commit -m "feat: geometry-agent project scaffolding with CLI skeleton"
```

---

### Task 2: OpenSCAD Engine (Compile + Render)

**Files:**
- Create: `geometry-agent/src/geometry_agent/engines/__init__.py`
- Create: `geometry-agent/src/geometry_agent/engines/openscad.py`
- Create: `geometry-agent/tests/test_openscad_engine.py`
- Create: `geometry-agent/tests/fixtures/simple_cube.scad`

**Step 1: Create test fixture**

```openscad
// tests/fixtures/simple_cube.scad
// Minimal test file for compile/render verification
SIZE = 20;
HOLE_R = 5;

difference() {
    cube([SIZE, SIZE, SIZE], center=true);
    cylinder(r=HOLE_R, h=SIZE+2, center=true, $fn=24);
}
```

**Step 2: Write failing tests**

```python
# tests/test_openscad_engine.py
import pytest
from pathlib import Path
from geometry_agent.engines.openscad import OpenSCADEngine

FIXTURE = Path(__file__).parent / "fixtures" / "simple_cube.scad"

@pytest.fixture
def engine():
    return OpenSCADEngine()

def test_engine_finds_openscad(engine):
    assert engine.binary.exists()

def test_compile_success(engine):
    result = engine.compile(FIXTURE)
    assert result.success is True
    assert result.warnings == []

def test_compile_catches_warnings(engine, tmp_path):
    bad_file = tmp_path / "bad.scad"
    bad_file.write_text('use <nonexistent.scad>; cube(10);')
    result = engine.compile(bad_file)
    assert result.success is False or len(result.warnings) > 0

def test_render_produces_png(engine, tmp_path):
    result = engine.render(FIXTURE, output_dir=tmp_path, views=["isometric"])
    assert result.success is True
    assert (tmp_path / "simple_cube_isometric.png").exists()

def test_render_multiple_views(engine, tmp_path):
    result = engine.render(FIXTURE, output_dir=tmp_path, views=["front", "top", "isometric"])
    assert result.success is True
    assert len(list(tmp_path.glob("*.png"))) == 3
```

**Step 3: Run tests to verify they fail**

```bash
pytest tests/test_openscad_engine.py -v
```

Expected: FAIL with ImportError (module doesn't exist yet)

**Step 4: Implement OpenSCAD engine**

```python
# src/geometry_agent/engines/__init__.py
from dataclasses import dataclass, field

@dataclass
class CompileResult:
    success: bool
    warnings: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    duration_ms: float = 0.0

@dataclass
class RenderResult:
    success: bool
    images: dict[str, str] = field(default_factory=dict)  # view_name -> file_path
    errors: list[str] = field(default_factory=list)
    duration_ms: float = 0.0
```

```python
# src/geometry_agent/engines/openscad.py
import os
import re
import subprocess
import time
from pathlib import Path
from geometry_agent.config import get_openscad_binary, OPENSCADPATH
from geometry_agent.engines import CompileResult, RenderResult

VIEW_PRESETS = {
    "front":     "0,0,0,0,0,0",
    "back":      "0,0,0,180,0,0",
    "left":      "0,0,0,0,0,270",
    "right":     "0,0,0,0,0,90",
    "top":       "0,0,0,90,0,0",
    "bottom":    "0,0,0,270,0,0",
    "isometric": "0,0,0,55,0,25",
    "dimetric":  "0,0,0,55,0,15",
}

class OpenSCADEngine:
    def __init__(self):
        self.binary = get_openscad_binary()
        self.env = {**os.environ, "OPENSCADPATH": OPENSCADPATH}

    def compile(self, scad_path: Path) -> CompileResult:
        """Compile .scad to .csg, check for warnings/errors."""
        scad_path = Path(scad_path)
        start = time.time()
        try:
            result = subprocess.run(
                [str(self.binary), "--backend=manifold", "-o", "NUL", str(scad_path)],
                capture_output=True, text=True, timeout=60, env=self.env,
            )
        except subprocess.TimeoutExpired:
            return CompileResult(success=False, errors=["Compile timed out (60s)"])

        duration = (time.time() - start) * 1000
        warnings = [l for l in result.stderr.splitlines() if "WARNING" in l]
        errors = [l for l in result.stderr.splitlines() if "ERROR" in l]
        success = result.returncode == 0 and len(warnings) == 0 and len(errors) == 0
        return CompileResult(success=success, warnings=warnings, errors=errors, duration_ms=duration)

    def render(self, scad_path: Path, output_dir: Path, views: list[str] = None,
               size: tuple[int,int] = (800, 600)) -> RenderResult:
        """Render .scad to PNG for each requested view."""
        scad_path = Path(scad_path)
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        views = views or ["isometric"]
        stem = scad_path.stem
        images = {}
        errors = []
        start = time.time()

        for view in views:
            rotation = VIEW_PRESETS.get(view, VIEW_PRESETS["isometric"])
            out_file = output_dir / f"{stem}_{view}.png"
            cmd = [
                str(self.binary),
                "--backend=manifold",
                "-o", str(out_file),
                f"--imgsize={size[0]},{size[1]}",
                "--colorscheme=Tomorrow Night",
                "--viewall", "--autocenter",
                f"--view=axes",
                str(scad_path),
            ]
            try:
                result = subprocess.run(cmd, capture_output=True, text=True,
                                       timeout=120, env=self.env)
                if out_file.exists():
                    images[view] = str(out_file)
                else:
                    errors.append(f"Render failed for {view}: {result.stderr[:200]}")
            except subprocess.TimeoutExpired:
                errors.append(f"Render timed out for {view}")

        duration = (time.time() - start) * 1000
        return RenderResult(success=len(errors) == 0, images=images,
                          errors=errors, duration_ms=duration)
```

**Step 5: Run tests**

```bash
pytest tests/test_openscad_engine.py -v
```

Expected: All PASS (requires OpenSCAD Nightly installed)

**Step 6: Wire CLI commands**

Update `cli.py` to use the engine:

```python
# Add to cli.py - replace the stub compile/render commands
from geometry_agent.engines.openscad import OpenSCADEngine

@main.command()
@click.argument("scad_file", type=click.Path(exists=True))
def compile(scad_file):
    """Compile an OpenSCAD file (zero warnings required)."""
    engine = OpenSCADEngine()
    result = engine.compile(Path(scad_file))
    if result.success:
        console.print(f"[green]PASS[/green] Compiled in {result.duration_ms:.0f}ms")
    else:
        console.print(f"[red]FAIL[/red] {len(result.warnings)} warnings, {len(result.errors)} errors")
        for w in result.warnings:
            console.print(f"  [yellow]WARN[/yellow] {w}")
        for e in result.errors:
            console.print(f"  [red]ERR[/red] {e}")
    raise SystemExit(0 if result.success else 1)
```

**Step 7: Commit**

```bash
git add geometry-agent/
git commit -m "feat: OpenSCAD engine with compile and render commands"
```

---

### Task 3: SCAD Parser (Port from validate_geometry.py)

**Files:**
- Create: `geometry-agent/src/geometry_agent/validators/__init__.py`
- Create: `geometry-agent/src/geometry_agent/validators/scad_parser.py`
- Create: `geometry-agent/tests/test_scad_parser.py`
- Create: `geometry-agent/tests/fixtures/test_config.scad`
- Reference: `3d_design_agent/triple_helix_mvp/5.5/validate_geometry.py` (lines 1-200, the parser section)

**Step 1: Create test config fixture**

```openscad
// tests/fixtures/test_config.scad
// Test config for parser verification
PI_VAL = 3.14159;
RADIUS = 25;
DIAMETER = RADIUS * 2;
HEIGHT = 100;
AREA = PI * RADIUS * RADIUS;
WALL = 2.5;
INNER_R = RADIUS - WALL;
TOOTH_COUNT = 20;
MODULE = 2;
PITCH_R = TOOTH_COUNT * MODULE / 2;
CLEARANCE = 0.2;
SHOW_HOUSING = true;
COLORS = [0.5, 0.5, 0.5];
```

**Step 2: Write failing tests**

```python
# tests/test_scad_parser.py
import pytest
from pathlib import Path
from geometry_agent.validators.scad_parser import parse_scad_config

FIXTURE = Path(__file__).parent / "fixtures" / "test_config.scad"

def test_parse_simple_values():
    cfg = parse_scad_config(FIXTURE)
    assert cfg is not None
    assert cfg["RADIUS"] == 25
    assert cfg["HEIGHT"] == 100
    assert cfg["WALL"] == 2.5
    assert cfg["TOOTH_COUNT"] == 20

def test_parse_derived_values():
    cfg = parse_scad_config(FIXTURE)
    assert cfg["DIAMETER"] == 50        # RADIUS * 2
    assert cfg["INNER_R"] == 22.5       # RADIUS - WALL
    assert cfg["PITCH_R"] == 20         # TOOTH_COUNT * MODULE / 2

def test_parse_pi():
    cfg = parse_scad_config(FIXTURE)
    assert abs(cfg["AREA"] - 3.14159 * 25 * 25) < 0.01

def test_parse_boolean():
    cfg = parse_scad_config(FIXTURE)
    assert cfg["SHOW_HOUSING"] is True

def test_parse_array():
    cfg = parse_scad_config(FIXTURE)
    assert cfg["COLORS"] == [0.5, 0.5, 0.5]

def test_parse_nonexistent_file():
    result = parse_scad_config(Path("nonexistent.scad"))
    assert result is None
```

**Step 3: Run tests to verify they fail**

```bash
pytest tests/test_scad_parser.py -v
```

Expected: FAIL with ImportError

**Step 4: Port the parser**

Copy the parsing functions from `validate_geometry.py` (lines 1-200) into `scad_parser.py`. Key functions to port:
- `parse_scad_config(path) -> dict | None`
- `_eval_expr(expr, known) -> float | list | bool | None`
- `_eval_arithmetic(expr, known) -> float | None`
- `_tokenize(expr, known)`, `_parse_add_sub`, `_parse_mul_div`, `_parse_unary`, `_parse_atom`

Adapt: remove hardcoded paths, make it a clean module.

**Step 5: Run tests**

```bash
pytest tests/test_scad_parser.py -v
```

Expected: All PASS

**Step 6: Commit**

```bash
git add geometry-agent/
git commit -m "feat: SCAD parser ported from validate_geometry.py"
```

---

### Task 4: Constraint Engine (YAML-Driven)

**Files:**
- Create: `geometry-agent/src/geometry_agent/validators/constraints.py`
- Create: `geometry-agent/constraints/example.yaml`
- Create: `geometry-agent/tests/test_constraints.py`

**Step 1: Create example constraint file**

```yaml
# constraints/example.yaml
name: "Basic geometry constraints"

rules:
  - name: wall_thickness
    check: "WALL >= 0.8"
    on_fail: "Wall thickness {WALL}mm is below FDM minimum 0.8mm."

  - name: hole_clearance
    check: "INNER_R > 0"
    on_fail: "Inner radius must be positive (got {INNER_R}mm)."

  - name: gear_module
    check: "MODULE >= 1 and MODULE <= 4"
    on_fail: "Gear module {MODULE} outside printable range 1-4mm."

  - name: build_plate
    check: "DIAMETER <= 350"
    on_fail: "Part diameter {DIAMETER}mm exceeds K2 Plus build plate (350mm)."
```

**Step 2: Write failing tests**

```python
# tests/test_constraints.py
import pytest
from pathlib import Path
from geometry_agent.validators.constraints import check_constraints

CONSTRAINT_FILE = Path(__file__).parent.parent / "constraints" / "example.yaml"

def test_all_pass():
    cfg = {"WALL": 2.5, "INNER_R": 22.5, "MODULE": 2, "DIAMETER": 50}
    results = check_constraints(cfg, CONSTRAINT_FILE)
    assert all(r["status"] == "PASS" for r in results)

def test_wall_too_thin():
    cfg = {"WALL": 0.3, "INNER_R": 22.5, "MODULE": 2, "DIAMETER": 50}
    results = check_constraints(cfg, CONSTRAINT_FILE)
    wall_result = next(r for r in results if r["name"] == "wall_thickness")
    assert wall_result["status"] == "FAIL"

def test_diameter_too_large():
    cfg = {"WALL": 2.5, "INNER_R": 22.5, "MODULE": 2, "DIAMETER": 400}
    results = check_constraints(cfg, CONSTRAINT_FILE)
    plate_result = next(r for r in results if r["name"] == "build_plate")
    assert plate_result["status"] == "FAIL"
    assert "350mm" in plate_result["message"]

def test_missing_variable():
    cfg = {"WALL": 2.5}  # Missing INNER_R, MODULE, DIAMETER
    results = check_constraints(cfg, CONSTRAINT_FILE)
    # Missing vars should produce WARN, not crash
    assert any(r["status"] == "WARN" for r in results)
```

**Step 3: Run tests to verify failure**

```bash
pytest tests/test_constraints.py -v
```

**Step 4: Implement constraint engine**

```python
# src/geometry_agent/validators/constraints.py
import re
import yaml
from pathlib import Path

def check_constraints(config: dict, constraint_file: Path) -> list[dict]:
    """Evaluate YAML constraint rules against parsed config values."""
    constraint_file = Path(constraint_file)
    with open(constraint_file) as f:
        spec = yaml.safe_load(f)

    results = []
    for rule in spec.get("rules", []):
        name = rule["name"]
        expr = rule["check"]
        on_fail = rule.get("on_fail", f"Check '{name}' failed.")

        # Find all variable references in the expression
        var_names = re.findall(r'[A-Z][A-Z0-9_]*', expr)
        missing = [v for v in var_names if v not in config]

        if missing:
            results.append({
                "name": name,
                "status": "WARN",
                "message": f"Missing variables: {', '.join(missing)}"
            })
            continue

        # Build evaluation namespace
        ns = {k: v for k, v in config.items() if isinstance(v, (int, float, bool))}

        try:
            passed = bool(eval(expr, {"__builtins__": {}}, ns))
        except Exception as e:
            results.append({
                "name": name,
                "status": "WARN",
                "message": f"Could not evaluate: {e}"
            })
            continue

        if passed:
            results.append({"name": name, "status": "PASS", "message": ""})
        else:
            msg = on_fail
            for var in var_names:
                if var in config:
                    msg = msg.replace(f"{{{var}}}", str(config[var]))
            results.append({"name": name, "status": "FAIL", "message": msg})

    return results
```

**Step 5: Run tests**

```bash
pytest tests/test_constraints.py -v
```

Expected: All PASS

**Step 6: Wire into CLI validate command**

**Step 7: Commit**

```bash
git add geometry-agent/
git commit -m "feat: YAML-driven constraint engine"
```

---

### Task 5: Tolerance Tools (Wrap Existing)

**Files:**
- Create: `geometry-agent/src/geometry_agent/validators/tolerance.py`
- Create: `geometry-agent/tests/test_tolerance.py`
- Reference: `3d_design_agent/production_pipeline/iso286_lookup.py`
- Reference: `3d_design_agent/production_pipeline/tolerance_stackup.py`

**Step 1: Write failing tests**

```python
# tests/test_tolerance.py
from geometry_agent.validators.tolerance import iso286_lookup, fit_analysis

def test_h7_25mm():
    result = iso286_lookup(25, "H7")
    assert result["zone"] == "H7"
    assert result["nominal"] == 25
    assert result["upper_dev_um"] == 21
    assert result["lower_dev_um"] == 0

def test_clearance_fit():
    result = fit_analysis(25, "H7", "g6")
    assert result["fit_type"] == "clearance"
    assert result["min_clearance_mm"] > 0
```

**Step 2: Implement wrapper**

Copy `iso286_lookup.py` and `tolerance_stackup.py` into the validators directory. Create a thin wrapper in `tolerance.py` that re-exports the public API.

```python
# src/geometry_agent/validators/tolerance.py
"""Tolerance analysis tools - wraps ISO 286 lookup and stackup analysis."""
import sys
from pathlib import Path

# Add production_pipeline to path for import
_prod_path = Path(__file__).parent.parent.parent.parent.parent / "3d_design_agent" / "production_pipeline"
if _prod_path.exists():
    sys.path.insert(0, str(_prod_path))

from iso286_lookup import iso286_lookup, fit_clearance as fit_analysis, format_fit_report
from tolerance_stackup import StackupChain, run_stackup, Dimension, StackupResult

__all__ = ["iso286_lookup", "fit_analysis", "format_fit_report",
           "StackupChain", "run_stackup", "Dimension", "StackupResult"]
```

**Step 3: Run tests + Commit**

```bash
pytest tests/test_tolerance.py -v
git add geometry-agent/ && git commit -m "feat: tolerance tools wrapped (ISO 286 + stackup)"
```

---

### Task 6: Visual Diff Analyzer

**Files:**
- Create: `geometry-agent/src/geometry_agent/analyzers/__init__.py`
- Create: `geometry-agent/src/geometry_agent/analyzers/visual_diff.py`
- Create: `geometry-agent/tests/test_visual_diff.py`

**Step 1: Write failing tests**

```python
# tests/test_visual_diff.py
import pytest
from pathlib import Path
from PIL import Image
from geometry_agent.analyzers.visual_diff import compare_renders

@pytest.fixture
def identical_images(tmp_path):
    img = Image.new("RGB", (100, 100), "red")
    a = tmp_path / "a.png"
    b = tmp_path / "b.png"
    img.save(a)
    img.save(b)
    return a, b

@pytest.fixture
def different_images(tmp_path):
    a_path = tmp_path / "a.png"
    b_path = tmp_path / "b.png"
    Image.new("RGB", (100, 100), "red").save(a_path)
    Image.new("RGB", (100, 100), "blue").save(b_path)
    return a_path, b_path

def test_identical_images(identical_images):
    a, b = identical_images
    result = compare_renders(a, b)
    assert result["changed"] is False
    assert result["pct_changed"] == 0.0

def test_different_images(different_images):
    a, b = different_images
    result = compare_renders(a, b)
    assert result["changed"] is True
    assert result["pct_changed"] > 90.0  # almost all pixels differ

def test_diff_image_saved(different_images, tmp_path):
    a, b = different_images
    diff_path = tmp_path / "diff.png"
    result = compare_renders(a, b, diff_output=diff_path)
    assert diff_path.exists()
```

**Step 2: Implement**

```python
# src/geometry_agent/analyzers/__init__.py
```

```python
# src/geometry_agent/analyzers/visual_diff.py
from pathlib import Path
import numpy as np
from PIL import Image, ImageChops

def compare_renders(path_a: Path, path_b: Path, threshold: int = 10,
                    diff_output: Path = None) -> dict:
    """Compare two rendered PNGs and report differences."""
    img_a = Image.open(path_a).convert("RGB")
    img_b = Image.open(path_b).convert("RGB")

    if img_a.size != img_b.size:
        return {"changed": True, "pct_changed": 100.0,
                "error": f"Size mismatch: {img_a.size} vs {img_b.size}"}

    diff = ImageChops.difference(img_a, img_b)
    bbox = diff.getbbox()

    arr = np.array(diff)
    changed_pixels = int(np.sum(arr.max(axis=2) > threshold))
    total_pixels = arr.shape[0] * arr.shape[1]
    pct = (changed_pixels / total_pixels * 100) if total_pixels > 0 else 0.0

    if diff_output:
        amplified = diff.point(lambda x: min(255, x * 10))
        amplified.save(diff_output)

    return {
        "changed": bbox is not None,
        "bbox": bbox,
        "pct_changed": round(pct, 2),
        "changed_pixels": changed_pixels,
        "total_pixels": total_pixels,
    }
```

**Step 3: Run tests + Commit**

```bash
pytest tests/test_visual_diff.py -v
git add geometry-agent/ && git commit -m "feat: visual diff analyzer (Pillow)"
```

---

### Task 7: Collision Detection Analyzer

**Files:**
- Create: `geometry-agent/src/geometry_agent/analyzers/collision.py`
- Create: `geometry-agent/tests/test_collision.py`
- Create: `geometry-agent/tests/fixtures/cube_a.stl` (generated in test)

**Step 1: Write failing tests**

```python
# tests/test_collision.py
import pytest
import numpy as np

pytest.importorskip("trimesh")
pytest.importorskip("fcl")

from geometry_agent.analyzers.collision import check_collisions

@pytest.fixture
def overlapping_meshes(tmp_path):
    import trimesh
    a = trimesh.creation.box(extents=[10, 10, 10])
    b = trimesh.creation.box(extents=[10, 10, 10])
    b.apply_translation([5, 0, 0])  # 5mm overlap
    a_path = tmp_path / "a.stl"
    b_path = tmp_path / "b.stl"
    a.export(str(a_path))
    b.export(str(b_path))
    return [str(a_path), str(b_path)]

@pytest.fixture
def separated_meshes(tmp_path):
    import trimesh
    a = trimesh.creation.box(extents=[10, 10, 10])
    b = trimesh.creation.box(extents=[10, 10, 10])
    b.apply_translation([20, 0, 0])  # 10mm gap
    a_path = tmp_path / "a.stl"
    b_path = tmp_path / "b.stl"
    a.export(str(a_path))
    b.export(str(b_path))
    return [str(a_path), str(b_path)]

def test_overlapping_detected(overlapping_meshes):
    result = check_collisions(overlapping_meshes)
    assert result["has_collisions"] is True
    assert len(result["pairs"]) == 1

def test_separated_clear(separated_meshes):
    result = check_collisions(separated_meshes)
    assert result["has_collisions"] is False

def test_single_file_no_crash(tmp_path):
    import trimesh
    a = trimesh.creation.box(extents=[10, 10, 10])
    a_path = tmp_path / "a.stl"
    a.export(str(a_path))
    result = check_collisions([str(a_path)])
    assert result["has_collisions"] is False
```

**Step 2: Implement**

```python
# src/geometry_agent/analyzers/collision.py
from pathlib import Path

def check_collisions(stl_paths: list[str]) -> dict:
    """Check for mesh collisions between STL files using trimesh + FCL."""
    try:
        import trimesh
        import trimesh.collision
    except ImportError:
        return {"has_collisions": False, "error": "trimesh or python-fcl not installed",
                "pairs": []}

    manager = trimesh.collision.CollisionManager()
    names = []

    for path in stl_paths:
        p = Path(path)
        mesh = trimesh.load_mesh(str(p))
        name = p.stem
        manager.add_object(name, mesh)
        names.append(name)

    if len(names) < 2:
        return {"has_collisions": False, "pairs": [], "part_count": len(names)}

    is_collision, collision_names = manager.in_collision_internal(return_names=True)

    # Get minimum distances for all pairs
    min_dist = manager.min_distance_internal(return_names=True)

    pairs = []
    if is_collision:
        for name_pair in collision_names:
            a, b = sorted(name_pair)
            pairs.append({"part_a": a, "part_b": b, "status": "COLLISION"})

    return {
        "has_collisions": is_collision,
        "pairs": pairs,
        "part_count": len(names),
        "min_distance": min_dist if not is_collision else 0.0,
    }
```

**Step 3: Run tests + Commit**

```bash
pip install "trimesh[easy]" python-fcl
pytest tests/test_collision.py -v
git add geometry-agent/ && git commit -m "feat: collision detection analyzer (trimesh + FCL)"
```

---

## Phase 2: Intelligence (Tasks 8-10)

### Task 8: Pipeline Orchestrator (run command)

**Files:**
- Create: `geometry-agent/src/geometry_agent/orchestrator/__init__.py`
- Create: `geometry-agent/src/geometry_agent/orchestrator/planner.py`
- Create: `geometry-agent/src/geometry_agent/orchestrator/dispatcher.py`
- Create: `geometry-agent/tests/test_pipeline.py`

The `run` command chains: compile → parse → validate → render → diff → report.

**Step 1: Write failing tests**

```python
# tests/test_pipeline.py
import pytest
from pathlib import Path
from geometry_agent.orchestrator.dispatcher import run_pipeline

FIXTURE = Path(__file__).parent / "fixtures" / "simple_cube.scad"
CONSTRAINTS = Path(__file__).parent.parent / "constraints" / "example.yaml"

def test_full_pipeline(tmp_path):
    result = run_pipeline(
        scad_file=FIXTURE,
        constraint_file=CONSTRAINTS,
        output_dir=tmp_path,
        render_views=["isometric"],
    )
    assert result["compile"]["success"] is True
    assert "constraints" in result
    assert "renders" in result

def test_pipeline_compile_failure(tmp_path):
    bad = tmp_path / "bad.scad"
    bad.write_text("use <nonexistent.scad>; cube(10);")
    result = run_pipeline(scad_file=bad, output_dir=tmp_path)
    assert result["compile"]["success"] is False
    # Pipeline should stop early on compile failure
    assert "renders" not in result or result["renders"] is None

def test_pipeline_skip_render(tmp_path):
    result = run_pipeline(
        scad_file=FIXTURE,
        constraint_file=CONSTRAINTS,
        output_dir=tmp_path,
        skip_render=True,
    )
    assert result["compile"]["success"] is True
    assert result.get("renders") is None
```

**Step 2: Run tests to verify they fail**

```bash
pytest tests/test_pipeline.py -v
```

Expected: FAIL with ImportError

**Step 3: Implement planner**

```python
# src/geometry_agent/orchestrator/__init__.py
from dataclasses import dataclass, field

@dataclass
class PipelineConfig:
    """What the orchestrator should run."""
    compile: bool = True
    parse: bool = True
    validate: bool = True
    render: bool = True
    render_views: list[str] = field(default_factory=lambda: ["isometric"])
    collide: bool = False
    diff_against: str | None = None
    export_format: str | None = None  # "stl", "step", or None
    constraint_file: str | None = None
    report_format: str = "terminal"  # "terminal", "json", "html"
```

```python
# src/geometry_agent/orchestrator/planner.py
from pathlib import Path
from geometry_agent.orchestrator import PipelineConfig

def plan_pipeline(
    scad_file: Path,
    constraint_file: Path | None = None,
    render_views: list[str] | None = None,
    skip_render: bool = False,
    collide: bool = False,
    diff_against: str | None = None,
    export_format: str | None = None,
    report_format: str = "terminal",
) -> PipelineConfig:
    """Decide what tools to run based on inputs and flags."""
    return PipelineConfig(
        compile=True,
        parse=constraint_file is not None,
        validate=constraint_file is not None,
        render=not skip_render,
        render_views=render_views or ["isometric"],
        collide=collide,
        diff_against=diff_against,
        export_format=export_format,
        constraint_file=str(constraint_file) if constraint_file else None,
        report_format=report_format,
    )
```

**Step 4: Implement dispatcher**

```python
# src/geometry_agent/orchestrator/dispatcher.py
from pathlib import Path
from geometry_agent.orchestrator.planner import plan_pipeline
from geometry_agent.engines.openscad import OpenSCADEngine
from geometry_agent.validators.scad_parser import parse_scad_config
from geometry_agent.validators.constraints import check_constraints

def run_pipeline(
    scad_file: Path,
    constraint_file: Path | None = None,
    output_dir: Path | None = None,
    render_views: list[str] | None = None,
    skip_render: bool = False,
    collide: bool = False,
    diff_against: str | None = None,
    export_format: str | None = None,
    report_format: str = "terminal",
) -> dict:
    """Execute the full validation pipeline."""
    scad_file = Path(scad_file)
    output_dir = Path(output_dir) if output_dir else scad_file.parent / "output"
    output_dir.mkdir(parents=True, exist_ok=True)

    config = plan_pipeline(
        scad_file, constraint_file, render_views, skip_render,
        collide, diff_against, export_format, report_format,
    )

    result = {"file": str(scad_file), "steps_run": []}
    engine = OpenSCADEngine()

    # Step 1: Compile
    if config.compile:
        compile_res = engine.compile(scad_file)
        result["compile"] = {
            "success": compile_res.success,
            "warnings": compile_res.warnings,
            "errors": compile_res.errors,
            "duration_ms": compile_res.duration_ms,
        }
        result["steps_run"].append("compile")
        if not compile_res.success:
            return result  # Stop early

    # Step 2: Parse + Validate
    if config.parse and config.constraint_file:
        parsed = parse_scad_config(scad_file)
        if parsed:
            constraint_results = check_constraints(parsed, Path(config.constraint_file))
            result["constraints"] = constraint_results
            result["steps_run"].append("validate")

    # Step 3: Render
    if config.render:
        render_res = engine.render(scad_file, output_dir, config.render_views)
        result["renders"] = {
            "success": render_res.success,
            "images": render_res.images,
            "errors": render_res.errors,
            "duration_ms": render_res.duration_ms,
        }
        result["steps_run"].append("render")
    else:
        result["renders"] = None

    # Step 4: Visual diff (if baseline provided)
    if config.diff_against:
        from geometry_agent.analyzers.visual_diff import compare_renders
        diff_results = {}
        baseline_dir = Path(config.diff_against)
        if result.get("renders") and result["renders"].get("images"):
            for view, img_path in result["renders"]["images"].items():
                baseline = baseline_dir / Path(img_path).name
                if baseline.exists():
                    diff_results[view] = compare_renders(
                        baseline, Path(img_path),
                        diff_output=output_dir / f"diff_{view}.png",
                    )
        result["diff"] = diff_results
        result["steps_run"].append("diff")

    # Step 5: Collision (if requested)
    if config.collide:
        from geometry_agent.analyzers.collision import check_collisions
        stl_files = list(output_dir.glob("*.stl"))
        if stl_files:
            result["collision"] = check_collisions([str(f) for f in stl_files])
            result["steps_run"].append("collide")

    return result
```

**Step 5: Wire CLI run command**

```python
# Add to cli.py
from geometry_agent.orchestrator.dispatcher import run_pipeline as _run_pipeline

@main.command()
@click.argument("scad_file", type=click.Path(exists=True))
@click.option("--constraints", "-c", type=click.Path(exists=True), help="Constraint YAML file")
@click.option("--views", default="isometric", help="Comma-separated view names or 'all'")
@click.option("--no-render", is_flag=True, help="Skip rendering")
@click.option("--collide", is_flag=True, help="Run collision detection on STLs in output")
@click.option("--diff", "diff_against", type=click.Path(exists=True), help="Baseline render dir for diff")
@click.option("--report", "report_format", default="terminal", type=click.Choice(["terminal", "json"]))
@click.option("--output", "-o", type=click.Path(), help="Output directory")
def run(scad_file, constraints, views, no_render, collide, diff_against, report_format, output):
    """Full pipeline: compile + validate + render + report."""
    view_list = ["front", "back", "left", "right", "top", "bottom", "isometric", "dimetric"] if views == "all" else views.split(",")
    result = _run_pipeline(
        scad_file=Path(scad_file),
        constraint_file=Path(constraints) if constraints else None,
        output_dir=Path(output) if output else None,
        render_views=view_list,
        skip_render=no_render,
        collide=collide,
        diff_against=diff_against,
        report_format=report_format,
    )
    # Display results
    if result.get("compile", {}).get("success"):
        console.print(f"[green]COMPILE[/green] OK ({result['compile']['duration_ms']:.0f}ms)")
    else:
        console.print(f"[red]COMPILE[/red] FAILED")
        for e in result.get("compile", {}).get("errors", []):
            console.print(f"  [red]{e}[/red]")
        raise SystemExit(1)

    if "constraints" in result:
        fails = [r for r in result["constraints"] if r["status"] == "FAIL"]
        warns = [r for r in result["constraints"] if r["status"] == "WARN"]
        passes = [r for r in result["constraints"] if r["status"] == "PASS"]
        console.print(f"[bold]VALIDATE[/bold] {len(passes)} pass, {len(fails)} fail, {len(warns)} warn")
        for f in fails:
            console.print(f"  [red]FAIL[/red] {f['name']}: {f['message']}")

    if result.get("renders", {}) and result["renders"].get("success"):
        console.print(f"[green]RENDER[/green] {len(result['renders']['images'])} views ({result['renders']['duration_ms']:.0f}ms)")

    has_fails = any(r["status"] == "FAIL" for r in result.get("constraints", []))
    raise SystemExit(1 if has_fails else 0)
```

**Step 6: Run tests**

```bash
pytest tests/test_pipeline.py -v
```

Expected: All PASS

**Step 7: Commit**

```bash
git add geometry-agent/
git commit -m "feat: pipeline orchestrator with planner and dispatcher"
```

---

### Task 9: Report Generator

**Files:**
- Create: `geometry-agent/src/geometry_agent/exporters/__init__.py`
- Create: `geometry-agent/src/geometry_agent/exporters/report.py`
- Create: `geometry-agent/tests/test_report.py`

**Step 1: Write failing tests**

```python
# tests/test_report.py
import json
import pytest
from geometry_agent.exporters.report import generate_json_report, generate_html_report

@pytest.fixture
def sample_pipeline_result():
    return {
        "file": "test.scad",
        "steps_run": ["compile", "validate", "render"],
        "compile": {"success": True, "warnings": [], "errors": [], "duration_ms": 150},
        "constraints": [
            {"name": "wall_thickness", "status": "PASS", "message": ""},
            {"name": "build_plate", "status": "FAIL", "message": "Diameter 400mm > 350mm"},
        ],
        "renders": {
            "success": True,
            "images": {"isometric": "/tmp/test_isometric.png"},
            "duration_ms": 2000,
        },
    }

def test_json_report(sample_pipeline_result, tmp_path):
    out = tmp_path / "report.json"
    generate_json_report(sample_pipeline_result, out)
    assert out.exists()
    data = json.loads(out.read_text())
    assert data["file"] == "test.scad"
    assert data["summary"]["total_checks"] == 2
    assert data["summary"]["fails"] == 1

def test_json_report_summary(sample_pipeline_result, tmp_path):
    out = tmp_path / "report.json"
    generate_json_report(sample_pipeline_result, out)
    data = json.loads(out.read_text())
    assert "pass_rate" in data["summary"]
    assert data["summary"]["pass_rate"] == 50.0

def test_html_report(sample_pipeline_result, tmp_path):
    out = tmp_path / "report.html"
    generate_html_report(sample_pipeline_result, out)
    assert out.exists()
    html = out.read_text()
    assert "test.scad" in html
    assert "FAIL" in html
    assert "wall_thickness" in html
```

**Step 2: Run tests to verify they fail**

```bash
pytest tests/test_report.py -v
```

**Step 3: Implement report generator**

```python
# src/geometry_agent/exporters/__init__.py
```

```python
# src/geometry_agent/exporters/report.py
import json
from datetime import datetime
from pathlib import Path

def _compute_summary(result: dict) -> dict:
    """Compute summary stats from pipeline result."""
    constraints = result.get("constraints", [])
    passes = sum(1 for c in constraints if c["status"] == "PASS")
    fails = sum(1 for c in constraints if c["status"] == "FAIL")
    warns = sum(1 for c in constraints if c["status"] == "WARN")
    total = len(constraints)
    return {
        "total_checks": total,
        "passes": passes,
        "fails": fails,
        "warns": warns,
        "pass_rate": round(passes / total * 100, 1) if total > 0 else 100.0,
        "compile_ok": result.get("compile", {}).get("success", False),
        "render_ok": result.get("renders", {}).get("success", False) if result.get("renders") else None,
        "steps_run": result.get("steps_run", []),
    }

def generate_json_report(result: dict, output_path: Path) -> None:
    """Write pipeline results as structured JSON report."""
    report = {
        "file": result.get("file", ""),
        "timestamp": datetime.now().isoformat(),
        "summary": _compute_summary(result),
        "compile": result.get("compile"),
        "constraints": result.get("constraints"),
        "renders": result.get("renders"),
        "diff": result.get("diff"),
        "collision": result.get("collision"),
    }
    output_path = Path(output_path)
    output_path.write_text(json.dumps(report, indent=2, default=str))

def generate_html_report(result: dict, output_path: Path) -> None:
    """Write pipeline results as self-contained HTML report."""
    summary = _compute_summary(result)
    constraints = result.get("constraints", [])

    rows = ""
    for c in constraints:
        color = {"PASS": "#4caf50", "FAIL": "#f44336", "WARN": "#ff9800"}[c["status"]]
        rows += f'<tr><td style="color:{color};font-weight:bold">{c["status"]}</td>'
        rows += f'<td>{c["name"]}</td><td>{c.get("message", "")}</td></tr>\n'

    render_imgs = ""
    if result.get("renders") and result["renders"].get("images"):
        for view, path in result["renders"]["images"].items():
            render_imgs += f'<div><h4>{view}</h4><img src="{path}" style="max-width:400px"></div>\n'

    html = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Geometry Agent Report</title>
<style>
  body {{ font-family: system-ui; max-width: 900px; margin: 2em auto; padding: 0 1em; }}
  table {{ border-collapse: collapse; width: 100%; }}
  th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
  th {{ background: #f5f5f5; }}
  .summary {{ display: flex; gap: 2em; margin: 1em 0; }}
  .stat {{ padding: 1em; background: #f9f9f9; border-radius: 8px; text-align: center; }}
  .stat .value {{ font-size: 2em; font-weight: bold; }}
  .renders {{ display: flex; flex-wrap: wrap; gap: 1em; }}
</style></head>
<body>
<h1>Geometry Agent Report</h1>
<p><strong>File:</strong> {result.get('file', '')}</p>
<p><strong>Time:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M')}</p>

<div class="summary">
  <div class="stat"><div class="value">{summary['pass_rate']}%</div><div>Pass Rate</div></div>
  <div class="stat"><div class="value">{summary['passes']}</div><div>Pass</div></div>
  <div class="stat"><div class="value" style="color:#f44336">{summary['fails']}</div><div>Fail</div></div>
  <div class="stat"><div class="value" style="color:#ff9800">{summary['warns']}</div><div>Warn</div></div>
</div>

<h2>Constraint Results</h2>
<table><tr><th>Status</th><th>Check</th><th>Message</th></tr>
{rows}</table>

<h2>Renders</h2>
<div class="renders">{render_imgs}</div>
</body></html>"""

    Path(output_path).write_text(html)
```

**Step 4: Run tests**

```bash
pytest tests/test_report.py -v
```

Expected: All PASS

**Step 5: Commit**

```bash
git add geometry-agent/
git commit -m "feat: JSON and HTML report generator"
```

---

### Task 10: Claude Code Hooks

**Files:**
- Create: `geometry-agent/hooks/on_scad_edit.sh`
- Create: `geometry-agent/hooks/on_scad_edit.ps1`
- Reference: `.claude/settings.local.json`

**Step 1: Create bash hook script**

```bash
#!/bin/bash
# hooks/on_scad_edit.sh
# Auto-validate .scad files when Claude Code edits them
# Triggered as a post-tool hook on Edit/Write tools

FILE="$1"
if [[ "$FILE" == *.scad ]]; then
    # Quick compile check — zero warnings required
    geometry-agent compile "$FILE" --quiet 2>&1
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "HOOK BLOCKED: OpenSCAD compile failed for $FILE"
        exit 1
    fi
fi
```

**Step 2: Create PowerShell hook (Windows fallback)**

```powershell
# hooks/on_scad_edit.ps1
# Windows equivalent of on_scad_edit.sh
param([string]$File)

if ($File -match '\.scad$') {
    $result = & geometry-agent compile $File --quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "HOOK BLOCKED: OpenSCAD compile failed for $File"
        exit 1
    }
}
```

**Step 3: Document hook configuration**

Add to project README: users configure hooks in `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash geometry-agent/hooks/on_scad_edit.sh $CLAUDE_FILE_PATH"
          }
        ]
      }
    ]
  }
}
```

**Step 4: Test manually**

```bash
# Edit any .scad file in Claude Code — hook should fire and report compile status
geometry-agent compile tests/fixtures/simple_cube.scad --quiet
echo "Exit code: $?"
```

Expected: Exit code 0 for valid files

**Step 5: Commit**

```bash
git add geometry-agent/hooks/
git commit -m "feat: Claude Code hooks for auto-validation on .scad edit"
```

---

## Phase 3: Translator (Tasks 11-14)

### Task 11: Mechanism Knowledge Base (YAML)

**Files:**
- Create: `geometry-agent/knowledge/taxonomy.yaml`
- Create: `geometry-agent/knowledge/linkages.yaml`
- Create: `geometry-agent/knowledge/gears.yaml`
- Create: `geometry-agent/knowledge/cams.yaml`
- Create: `geometry-agent/knowledge/structural.yaml`
- Create: `geometry-agent/knowledge/materials.yaml`
- Create: `geometry-agent/tests/test_knowledge.py`

**Step 1: Write failing tests**

```python
# tests/test_knowledge.py
import pytest
import yaml
from pathlib import Path

KNOWLEDGE_DIR = Path(__file__).parent.parent / "knowledge"

REQUIRED_FILES = ["taxonomy.yaml", "linkages.yaml", "gears.yaml",
                  "cams.yaml", "structural.yaml", "materials.yaml"]

@pytest.mark.parametrize("filename", REQUIRED_FILES)
def test_knowledge_file_exists(filename):
    assert (KNOWLEDGE_DIR / filename).exists(), f"Missing {filename}"

@pytest.mark.parametrize("filename", REQUIRED_FILES)
def test_knowledge_file_valid_yaml(filename):
    with open(KNOWLEDGE_DIR / filename) as f:
        data = yaml.safe_load(f)
    assert isinstance(data, dict), f"{filename} root must be a dict"

def test_taxonomy_has_categories():
    with open(KNOWLEDGE_DIR / "taxonomy.yaml") as f:
        data = yaml.safe_load(f)
    assert "categories" in data
    for cat in data["categories"]:
        assert "name" in cat
        assert "keywords" in cat
        assert "subtypes" in cat

def test_linkages_has_questions():
    with open(KNOWLEDGE_DIR / "linkages.yaml") as f:
        data = yaml.safe_load(f)
    assert "subtypes" in data
    four_bar = next((s for s in data["subtypes"] if s["name"] == "four_bar"), None)
    assert four_bar is not None
    assert "params" in four_bar
    assert "questions" in four_bar

def test_question_has_impact_format():
    with open(KNOWLEDGE_DIR / "linkages.yaml") as f:
        data = yaml.safe_load(f)
    four_bar = next(s for s in data["subtypes"] if s["name"] == "four_bar")
    for q in four_bar["questions"]:
        assert "prompt" in q, "Each question needs a prompt"
        assert "options" in q, "Each question needs options"
        for opt in q["options"]:
            assert "label" in opt
            assert "impact" in opt, "Each option needs an impact explanation"

def test_materials_has_properties():
    with open(KNOWLEDGE_DIR / "materials.yaml") as f:
        data = yaml.safe_load(f)
    assert "materials" in data
    pla = next((m for m in data["materials"] if m["name"] == "PLA"), None)
    assert pla is not None
    assert "density" in pla
    assert "tensile_strength" in pla
```

**Step 2: Run tests to verify they fail**

```bash
pytest tests/test_knowledge.py -v
```

**Step 3: Create taxonomy.yaml**

```yaml
# knowledge/taxonomy.yaml
name: "Mechanism Taxonomy"
description: "Top-level classification of mechanical design requests"

categories:
  - name: linkage
    keywords: ["linkage", "crank", "rocker", "four-bar", "six-bar", "jansen", "pantograph",
               "lever", "pivot", "hinge", "articulated", "motion path", "coupler curve"]
    subtypes: ["four_bar", "six_bar", "slider_crank", "jansen", "pantograph", "scotch_yoke"]
    knowledge_file: "linkages.yaml"

  - name: gear_system
    keywords: ["gear", "planetary", "spur", "bevel", "worm", "rack", "pinion", "helical",
               "epicyclic", "differential", "transmission", "mesh", "tooth", "module"]
    subtypes: ["spur_pair", "planetary", "bevel", "worm", "rack_and_pinion", "compound"]
    knowledge_file: "gears.yaml"

  - name: cam
    keywords: ["cam", "follower", "eccentric", "lobe", "profile", "barrel", "disc",
               "conjugate", "desmodromic", "dwell"]
    subtypes: ["disc_cam", "barrel_cam", "conjugate_cam", "eccentric"]
    knowledge_file: "cams.yaml"

  - name: structural
    keywords: ["bracket", "housing", "frame", "shaft", "enclosure", "mount", "plate",
               "standoff", "spacer", "bearing block", "pillow block"]
    subtypes: ["bracket", "housing", "shaft", "plate", "bearing_block"]
    knowledge_file: "structural.yaml"
```

**Step 4: Create linkages.yaml (with impact-based questions)**

```yaml
# knowledge/linkages.yaml
name: "Linkage Mechanisms"

subtypes:
  - name: four_bar
    description: "Classic four-bar linkage — converts rotation to oscillation or vice versa"
    params:
      required: [ground, crank, coupler, rocker]
      optional: [coupler_point_x, coupler_point_y, material, wall_thickness]
      derived:
        - name: grashof_sum
          formula: "min(ground, crank, coupler, rocker) + max(ground, crank, coupler, rocker)"
        - name: pq_sum
          formula: "sorted([ground, crank, coupler, rocker])[1] + sorted([ground, crank, coupler, rocker])[2]"

    questions:
      - param: motion_type
        prompt: "What kind of movement do you want?"
        options:
          - label: "Back-and-forth swing"
            impact: "The output arm rocks like a pendulum. Good for fans, wipers, wave generators."
            sets: {type: "crank_rocker"}
          - label: "Full rotation on both ends"
            impact: "Both the input and output spin completely around. Rare — needs specific link ratios."
            sets: {type: "double_crank"}
          - label: "I want a specific path shape"
            impact: "A point on the connecting bar traces a curved path. Used for walking robots, art."
            sets: {type: "coupler_curve"}

      - param: size
        prompt: "How big should this be?"
        options:
          - label: "Palm-sized (under 50mm)"
            impact: "Good for desk toys, small mechanisms. Needs tight tolerances."
            sets: {ground: 30, crank: 10, coupler: 25, rocker: 20}
          - label: "Hand-sized (50-150mm)"
            impact: "Standard prototyping size. Easy to 3D print and test."
            sets: {ground: 80, crank: 25, coupler: 60, rocker: 50}
          - label: "Large (150mm+)"
            impact: "Needs stronger material, bigger pivots. May not fit on print bed in one piece."
            sets: {ground: 200, crank: 60, coupler: 150, rocker: 120}

      - param: speed
        prompt: "How fast should it move?"
        options:
          - label: "Slow and smooth (under 30 RPM)"
            impact: "Gentle, contemplative motion. No vibration concerns."
            sets: {max_rpm: 30}
          - label: "Moderate (30-120 RPM)"
            impact: "Visible, satisfying motion. May need small flywheel for smoothness."
            sets: {max_rpm: 120}
          - label: "Fast (120+ RPM)"
            impact: "Dynamic, energetic. Needs balanced design to avoid vibration and noise."
            sets: {max_rpm: 300}

    prechecks:
      - name: grashof
        check: "grashof_sum <= pq_sum"
        on_fail: "This linkage can't make full rotations. I'll adjust the shortest link to fix it."
      - name: transmission_angle
        check: "min_transmission >= 40 and max_transmission <= 140"
        on_fail: "The linkage will feel 'stuck' at some positions. Let me adjust the proportions."

  - name: slider_crank
    description: "Converts rotation to linear back-and-forth motion (like a piston)"
    params:
      required: [crank_length, connecting_rod, stroke]
      optional: [offset, material]
      derived:
        - name: stroke
          formula: "2 * crank_length"

    questions:
      - param: stroke_length
        prompt: "How far should the slider travel back and forth?"
        options:
          - label: "Short travel (under 20mm)"
            impact: "Small displacement. Good for switches, micro-pumps."
            sets: {crank_length: 8, connecting_rod: 30}
          - label: "Medium travel (20-60mm)"
            impact: "Versatile range. Works for most kinetic art and small mechanisms."
            sets: {crank_length: 20, connecting_rod: 60}
          - label: "Long travel (60mm+)"
            impact: "Big motion. Needs sturdy slider guides to prevent binding."
            sets: {crank_length: 40, connecting_rod: 120}

    prechecks:
      - name: rod_ratio
        check: "connecting_rod >= 3 * crank_length"
        on_fail: "The connecting rod is too short relative to the crank. This causes harsh side loads."
```

**Step 5: Create gears.yaml, cams.yaml, structural.yaml, materials.yaml**

(Similar structure to linkages.yaml — each has subtypes, params, impact-based questions, prechecks. Full content generated at implementation time based on MARGOLIN_KNOWLEDGE_BANK and WAVE_SUMMATION_MECHANISMS reference material.)

Key content for each:
- `gears.yaml`: spur_pair (module, tooth count, pressure angle), planetary (sun/planet/ring teeth, stages), bevel, worm
- `cams.yaml`: disc_cam (base_radius, max_lift, dwell_angles), barrel_cam (helix_angle, lead), eccentric
- `structural.yaml`: bracket (mounting holes, load direction), housing (inner dims, wall), shaft (diameter, length, keyway)
- `materials.yaml`: PLA, PETG, ABS, Nylon, Brass, Aluminum 6061, Steel 1018, Walnut — each with density, tensile_strength, youngs_modulus, max_temp, printable, machineable, cost_per_kg

**Step 6: Run tests**

```bash
pytest tests/test_knowledge.py -v
```

Expected: All PASS

**Step 7: Commit**

```bash
git add geometry-agent/knowledge/ geometry-agent/tests/test_knowledge.py
git commit -m "feat: mechanism knowledge base (taxonomy, linkages, gears, cams, structural, materials)"
```

---

### Task 12: Context Accumulator

**Files:**
- Create: `geometry-agent/src/geometry_agent/translator/__init__.py`
- Create: `geometry-agent/src/geometry_agent/translator/context.py`
- Create: `geometry-agent/src/geometry_agent/translator/classifier.py`
- Create: `geometry-agent/tests/test_context.py`

**Step 1: Write failing tests**

```python
# tests/test_context.py
import pytest
from geometry_agent.translator.context import TranslatorContext
from geometry_agent.translator.classifier import classify

def test_empty_context():
    ctx = TranslatorContext()
    assert ctx.confidence == 0.0
    assert ctx.state == "NEEDS_CLARIFICATION"
    assert ctx.category is None

def test_single_message_low_confidence():
    ctx = TranslatorContext()
    ctx.add_message("I want to make something that moves")
    assert ctx.confidence < 0.7  # Too vague to proceed
    assert ctx.state in ("NEEDS_CLARIFICATION", "ACCUMULATING")

def test_clear_message_high_confidence():
    ctx = TranslatorContext()
    ctx.add_message("I want to build a four-bar linkage")
    assert ctx.confidence >= 0.7
    assert ctx.category == "linkage"
    assert ctx.subtype == "four_bar"
    assert ctx.state == "READY_TO_INTERVIEW"

def test_multi_message_accumulation():
    ctx = TranslatorContext()
    ctx.add_message("I need something that converts rotation to oscillation")
    assert ctx.confidence < 0.7
    ctx.add_message("like a crank driving a rocking arm")
    assert ctx.confidence >= 0.7
    assert ctx.category == "linkage"

def test_contradiction_reclassifies():
    ctx = TranslatorContext()
    ctx.add_message("I want gears that mesh together")
    assert ctx.category == "gear_system"
    ctx.add_message("actually no, I want a cam with a follower")
    assert ctx.category == "cam"

def test_multi_angle_same_thing():
    ctx = TranslatorContext()
    ctx.add_message("I want a thing that rocks back and forth")
    ctx.add_message("it should be driven by a motor spinning continuously")
    ctx.add_message("the output should swing maybe 60 degrees")
    # All three describe a crank-rocker linkage from different angles
    assert ctx.category == "linkage"
    assert ctx.message_count == 3

def test_context_merged_text():
    ctx = TranslatorContext()
    ctx.add_message("I want gears")
    ctx.add_message("planetary type")
    assert "gears" in ctx.combined_text
    assert "planetary" in ctx.combined_text

def test_classify_keywords():
    result = classify("I need a four-bar linkage with a crank")
    assert result["category"] == "linkage"
    assert result["confidence"] > 0.5

def test_classify_gear():
    result = classify("planetary gear set with three planets")
    assert result["category"] == "gear_system"
    assert result["confidence"] > 0.5

def test_classify_vague():
    result = classify("I want to make something cool")
    assert result["confidence"] < 0.4
```

**Step 2: Run tests to verify they fail**

```bash
pytest tests/test_context.py -v
```

**Step 3: Implement classifier**

```python
# src/geometry_agent/translator/__init__.py
```

```python
# src/geometry_agent/translator/classifier.py
import yaml
from pathlib import Path

_TAXONOMY = None

def _load_taxonomy() -> dict:
    global _TAXONOMY
    if _TAXONOMY is None:
        taxonomy_path = Path(__file__).parent.parent.parent.parent / "knowledge" / "taxonomy.yaml"
        with open(taxonomy_path) as f:
            _TAXONOMY = yaml.safe_load(f)
    return _TAXONOMY

def classify(text: str) -> dict:
    """Classify user text against mechanism taxonomy. Returns category, subtype, confidence."""
    taxonomy = _load_taxonomy()
    text_lower = text.lower()
    words = set(text_lower.split())

    best_category = None
    best_score = 0
    best_subtype = None

    for cat in taxonomy["categories"]:
        score = 0
        for keyword in cat["keywords"]:
            kw_lower = keyword.lower()
            if kw_lower in text_lower:
                # Exact phrase match scores higher
                score += 2 if " " in kw_lower else 1
            elif any(kw_lower.startswith(w) or w.startswith(kw_lower) for w in words):
                score += 0.5

        if score > best_score:
            best_score = score
            best_category = cat["name"]

    # Try to identify subtype
    if best_category:
        cat_data = next(c for c in taxonomy["categories"] if c["name"] == best_category)
        for subtype in cat_data.get("subtypes", []):
            sub_clean = subtype.replace("_", " ").replace("-", " ")
            if sub_clean in text_lower or subtype in text_lower:
                best_subtype = subtype
                best_score += 2
                break

    # Normalize confidence to 0-1 range
    confidence = min(1.0, best_score / 5.0)

    return {
        "category": best_category,
        "subtype": best_subtype,
        "confidence": round(confidence, 2),
        "score": best_score,
    }
```

**Step 4: Implement context accumulator**

```python
# src/geometry_agent/translator/context.py
from geometry_agent.translator.classifier import classify

class TranslatorContext:
    """Buffers multiple user messages, reclassifies on each addition.

    States:
        NEEDS_CLARIFICATION (confidence < 0.4) — ask a clarifying question
        ACCUMULATING (0.4 <= confidence < 0.7) — wait for more input
        READY_TO_INTERVIEW (confidence >= 0.7) — proceed to guided questions
    """

    def __init__(self):
        self._messages: list[str] = []
        self._classification: dict = {"category": None, "subtype": None, "confidence": 0.0}

    @property
    def confidence(self) -> float:
        return self._classification["confidence"]

    @property
    def category(self) -> str | None:
        return self._classification["category"]

    @property
    def subtype(self) -> str | None:
        return self._classification["subtype"]

    @property
    def state(self) -> str:
        c = self.confidence
        if c < 0.4:
            return "NEEDS_CLARIFICATION"
        elif c < 0.7:
            return "ACCUMULATING"
        else:
            return "READY_TO_INTERVIEW"

    @property
    def message_count(self) -> int:
        return len(self._messages)

    @property
    def combined_text(self) -> str:
        return " ".join(self._messages)

    def add_message(self, text: str) -> dict:
        """Add a message and reclassify using ALL accumulated context."""
        self._messages.append(text)
        # Always classify against the FULL combined context
        self._classification = classify(self.combined_text)
        return {
            "state": self.state,
            "category": self.category,
            "subtype": self.subtype,
            "confidence": self.confidence,
        }

    def get_clarification_prompt(self) -> str | None:
        """Return a prompt to ask the user if we need clarification."""
        if self.state != "NEEDS_CLARIFICATION":
            return None
        if not self._messages:
            return "What would you like to design? Describe what it should do or how it should move."
        return ("I'm not sure what type of mechanism you're describing. "
                "Could you tell me more about the motion or function you want?")

    def reset(self):
        """Clear all accumulated context."""
        self._messages.clear()
        self._classification = {"category": None, "subtype": None, "confidence": 0.0}
```

**Step 5: Run tests**

```bash
pytest tests/test_context.py -v
```

Expected: All PASS

**Step 6: Commit**

```bash
git add geometry-agent/src/geometry_agent/translator/ geometry-agent/tests/test_context.py
git commit -m "feat: context accumulator with keyword classifier for multi-message intent"
```

---

### Task 13: Guided Interviewer

**Files:**
- Create: `geometry-agent/src/geometry_agent/translator/interviewer.py`
- Create: `geometry-agent/src/geometry_agent/translator/spec_builder.py`
- Create: `geometry-agent/tests/test_interviewer.py`

**Step 1: Write failing tests**

```python
# tests/test_interviewer.py
import pytest
from pathlib import Path
from geometry_agent.translator.interviewer import Interviewer
from geometry_agent.translator.spec_builder import build_spec

KNOWLEDGE_DIR = Path(__file__).parent.parent / "knowledge"

@pytest.fixture
def interviewer():
    return Interviewer(KNOWLEDGE_DIR)

def test_load_questions(interviewer):
    questions = interviewer.get_questions("linkage", "four_bar")
    assert len(questions) > 0
    assert all("prompt" in q for q in questions)

def test_question_has_options_with_impact(interviewer):
    questions = interviewer.get_questions("linkage", "four_bar")
    for q in questions:
        assert "options" in q
        for opt in q["options"]:
            assert "label" in opt
            assert "impact" in opt

def test_answer_question(interviewer):
    questions = interviewer.get_questions("linkage", "four_bar")
    # Simulate answering the first question with option 0
    interviewer.answer(questions[0]["param"], 0)
    assert interviewer.has_answer(questions[0]["param"])

def test_all_answered_produces_params(interviewer):
    questions = interviewer.get_questions("linkage", "four_bar")
    for q in questions:
        interviewer.answer(q["param"], 0)  # Pick first option for all
    params = interviewer.get_collected_params()
    assert len(params) > 0

def test_skip_known_from_profile(interviewer):
    # Simulate profile with known preferences
    profile_prefs = {"material": "PLA", "max_rpm": 60}
    questions = interviewer.get_questions("linkage", "four_bar", skip=profile_prefs)
    param_names = [q["param"] for q in questions]
    # Questions for already-known params should be skipped
    for known in profile_prefs:
        assert known not in param_names

def test_build_spec():
    params = {
        "ground": 80, "crank": 25, "coupler": 60, "rocker": 50,
        "material": "PLA", "wall_thickness": 2.5,
    }
    spec = build_spec("linkage", "four_bar", params)
    assert spec["type"] == "linkage"
    assert spec["subtype"] == "four_bar"
    assert spec["params"]["ground"] == 80
    assert "derived" in spec

def test_build_assembly_spec():
    parts = [
        {"type": "gear_system", "subtype": "spur_pair", "params": {"module": 2, "teeth_a": 20, "teeth_b": 40}},
        {"type": "structural", "subtype": "shaft", "params": {"diameter": 8, "length": 50}},
    ]
    constraints = [
        {"type": "press_fit", "parts": [0, 1], "fit": "H7/p6"},
    ]
    spec = build_spec("assembly", "custom", {}, parts=parts, constraints=constraints)
    assert spec["type"] == "assembly"
    assert len(spec["parts"]) == 2
    assert len(spec["constraints"]) == 1
```

**Step 2: Run tests to verify they fail**

```bash
pytest tests/test_interviewer.py -v
```

**Step 3: Implement interviewer**

```python
# src/geometry_agent/translator/interviewer.py
import yaml
from pathlib import Path

class Interviewer:
    """Guided question engine — reads knowledge YAML, presents impact-based options."""

    def __init__(self, knowledge_dir: Path):
        self.knowledge_dir = Path(knowledge_dir)
        self._answers: dict[str, int] = {}  # param -> selected option index
        self._collected: dict[str, any] = {}  # param -> resolved value

    def get_questions(self, category: str, subtype: str,
                      skip: dict | None = None) -> list[dict]:
        """Load questions for a category/subtype, skipping already-known params."""
        skip = skip or {}
        knowledge_file = self._find_knowledge_file(category)
        if not knowledge_file:
            return []

        with open(knowledge_file) as f:
            data = yaml.safe_load(f)

        subtype_data = next(
            (s for s in data.get("subtypes", []) if s["name"] == subtype), None
        )
        if not subtype_data:
            return []

        questions = subtype_data.get("questions", [])

        # Pre-populate from skip dict (profile preferences)
        for param, value in skip.items():
            self._collected[param] = value

        # Filter out questions for already-known params
        return [q for q in questions if q["param"] not in skip]

    def answer(self, param: str, option_index: int):
        """Record the user's answer for a parameter."""
        self._answers[param] = option_index

    def has_answer(self, param: str) -> bool:
        return param in self._answers

    def get_collected_params(self) -> dict:
        """Return all collected parameters (from answers + skip dict)."""
        return dict(self._collected)

    def resolve_answers(self, category: str, subtype: str) -> dict:
        """Resolve answer indices to actual parameter values using knowledge YAML."""
        knowledge_file = self._find_knowledge_file(category)
        if not knowledge_file:
            return self._collected

        with open(knowledge_file) as f:
            data = yaml.safe_load(f)

        subtype_data = next(
            (s for s in data.get("subtypes", []) if s["name"] == subtype), None
        )
        if not subtype_data:
            return self._collected

        for q in subtype_data.get("questions", []):
            param = q["param"]
            if param in self._answers:
                idx = self._answers[param]
                option = q["options"][idx]
                # Merge the option's "sets" dict into collected params
                if "sets" in option:
                    self._collected.update(option["sets"])

        return self._collected

    def _find_knowledge_file(self, category: str) -> Path | None:
        """Find the YAML knowledge file for a category."""
        # Load taxonomy to find the mapping
        taxonomy_path = self.knowledge_dir / "taxonomy.yaml"
        if not taxonomy_path.exists():
            return None
        with open(taxonomy_path) as f:
            taxonomy = yaml.safe_load(f)
        cat_data = next(
            (c for c in taxonomy["categories"] if c["name"] == category), None
        )
        if cat_data and "knowledge_file" in cat_data:
            kf = self.knowledge_dir / cat_data["knowledge_file"]
            return kf if kf.exists() else None
        return None
```

**Step 4: Implement spec builder**

```python
# src/geometry_agent/translator/spec_builder.py
import yaml
from datetime import datetime

def build_spec(
    category: str,
    subtype: str,
    params: dict,
    parts: list[dict] | None = None,
    constraints: list[dict] | None = None,
) -> dict:
    """Build a structured spec dict from collected interview parameters.

    For single parts: returns part_spec with type, subtype, params, derived.
    For assemblies: returns assembly_spec with parts list + constraints.
    """
    spec = {
        "version": "1.0",
        "created": datetime.now().isoformat(),
        "type": category,
        "subtype": subtype,
        "params": dict(params),
        "derived": {},
    }

    # Compute derived values where possible
    if category == "linkage" and subtype == "four_bar":
        links = [params.get("ground", 0), params.get("crank", 0),
                 params.get("coupler", 0), params.get("rocker", 0)]
        if all(l > 0 for l in links):
            sorted_links = sorted(links)
            spec["derived"]["grashof_sum"] = sorted_links[0] + sorted_links[3]
            spec["derived"]["pq_sum"] = sorted_links[1] + sorted_links[2]
            spec["derived"]["is_grashof"] = spec["derived"]["grashof_sum"] <= spec["derived"]["pq_sum"]

    elif category == "gear_system" and subtype == "spur_pair":
        m = params.get("module", 0)
        ta = params.get("teeth_a", 0)
        tb = params.get("teeth_b", 0)
        if m > 0 and ta > 0 and tb > 0:
            spec["derived"]["pitch_r_a"] = m * ta / 2
            spec["derived"]["pitch_r_b"] = m * tb / 2
            spec["derived"]["center_distance"] = m * (ta + tb) / 2
            spec["derived"]["gear_ratio"] = tb / ta

    elif category == "linkage" and subtype == "slider_crank":
        crank = params.get("crank_length", 0)
        if crank > 0:
            spec["derived"]["stroke"] = 2 * crank

    # Assembly handling
    if category == "assembly" or parts:
        spec["type"] = "assembly"
        spec["parts"] = parts or []
        spec["constraints"] = constraints or []

    return spec

def spec_to_yaml(spec: dict, output_path: str) -> None:
    """Write spec dict to YAML file."""
    with open(output_path, "w") as f:
        yaml.dump(spec, f, default_flow_style=False, sort_keys=False)
```

**Step 5: Run tests**

```bash
pytest tests/test_interviewer.py -v
```

Expected: All PASS

**Step 6: Commit**

```bash
git add geometry-agent/src/geometry_agent/translator/ geometry-agent/tests/test_interviewer.py
git commit -m "feat: guided interviewer with impact-based questions and spec builder"
```

---

### Task 14: User Profile Memory

**Files:**
- Create: `geometry-agent/src/geometry_agent/translator/profile.py`
- Create: `geometry-agent/tests/test_profile.py`

**Step 1: Write failing tests**

```python
# tests/test_profile.py
import pytest
from pathlib import Path
from geometry_agent.translator.profile import UserProfile

@pytest.fixture
def profile(tmp_path):
    return UserProfile(config_dir=tmp_path)

def test_new_profile_empty(profile):
    assert profile.defaults == {}
    assert profile.preferences == {}
    assert profile.skip_list == {}

def test_set_default(profile):
    profile.set_default("material", "PLA")
    assert profile.defaults["material"] == "PLA"

def test_set_preference(profile):
    profile.set_preference("fn", 48)
    assert profile.preferences["fn"] == 48

def test_add_to_skip_list(profile):
    profile.skip_answer("material", "PLA")
    assert profile.skip_list["material"] == "PLA"

def test_save_and_reload(profile, tmp_path):
    profile.set_default("material", "PETG")
    profile.set_preference("fn", 64)
    profile.skip_answer("max_rpm", 60)
    profile.add_style_note("prefers hexagonal aesthetics")
    profile.save()

    # Reload from disk
    reloaded = UserProfile(config_dir=tmp_path)
    assert reloaded.defaults["material"] == "PETG"
    assert reloaded.preferences["fn"] == 64
    assert reloaded.skip_list["max_rpm"] == 60
    assert "hexagonal" in reloaded.style_notes[0]

def test_record_design(profile):
    profile.record_design("linkage", "four_bar", {"ground": 80, "crank": 25})
    assert len(profile.history) == 1
    assert profile.history[0]["category"] == "linkage"

def test_get_skip_dict(profile):
    profile.skip_answer("material", "PLA")
    profile.skip_answer("max_rpm", 60)
    skip = profile.get_skip_dict()
    assert skip == {"material": "PLA", "max_rpm": 60}
```

**Step 2: Run tests to verify they fail**

```bash
pytest tests/test_profile.py -v
```

**Step 3: Implement profile**

```python
# src/geometry_agent/translator/profile.py
import yaml
from datetime import datetime
from pathlib import Path

class UserProfile:
    """Persistent user preferences stored in ~/.geometry-agent/profile.yaml.

    Accumulates over sessions. After ~10 sessions, the translator
    barely needs to ask anything — it already knows the user's style.
    """

    def __init__(self, config_dir: Path | None = None):
        self.config_dir = Path(config_dir) if config_dir else Path.home() / ".geometry-agent"
        self.config_dir.mkdir(parents=True, exist_ok=True)
        self._path = self.config_dir / "profile.yaml"

        self.defaults: dict = {}       # material, tolerance, scale, printer constraints
        self.preferences: dict = {}    # detail level, $fn, export format
        self.skip_list: dict = {}      # questions permanently answered (param -> value)
        self.history: list[dict] = []  # past designs
        self.style_notes: list[str] = []  # "prefers visible mechanisms", etc.

        self._load()

    def _load(self):
        if self._path.exists():
            with open(self._path) as f:
                data = yaml.safe_load(f) or {}
            self.defaults = data.get("defaults", {})
            self.preferences = data.get("preferences", {})
            self.skip_list = data.get("skip_list", {})
            self.history = data.get("history", [])
            self.style_notes = data.get("style_notes", [])

    def save(self):
        data = {
            "defaults": self.defaults,
            "preferences": self.preferences,
            "skip_list": self.skip_list,
            "history": self.history,
            "style_notes": self.style_notes,
        }
        with open(self._path, "w") as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False)

    def set_default(self, key: str, value):
        self.defaults[key] = value
        self.save()

    def set_preference(self, key: str, value):
        self.preferences[key] = value
        self.save()

    def skip_answer(self, param: str, value):
        """Permanently answer a question — won't be asked again."""
        self.skip_list[param] = value
        self.save()

    def get_skip_dict(self) -> dict:
        """Return all permanently answered params for the interviewer."""
        return dict(self.skip_list)

    def add_style_note(self, note: str):
        if note not in self.style_notes:
            self.style_notes.append(note)
            self.save()

    def record_design(self, category: str, subtype: str, params: dict):
        """Record a completed design for learning."""
        self.history.append({
            "timestamp": datetime.now().isoformat(),
            "category": category,
            "subtype": subtype,
            "params": params,
        })
        self.save()
```

**Step 4: Wire profile into CLI**

```python
# Add to cli.py

@main.group()
def profile():
    """Manage user profile and preferences."""
    pass

@profile.command("show")
def profile_show():
    """Show current profile preferences."""
    from geometry_agent.translator.profile import UserProfile
    p = UserProfile()
    console.print("[bold]Defaults:[/bold]")
    for k, v in p.defaults.items():
        console.print(f"  {k}: {v}")
    console.print(f"\n[bold]Preferences:[/bold]")
    for k, v in p.preferences.items():
        console.print(f"  {k}: {v}")
    console.print(f"\n[bold]Skip List:[/bold] {len(p.skip_list)} answers saved")
    console.print(f"[bold]History:[/bold] {len(p.history)} past designs")
    console.print(f"[bold]Style Notes:[/bold] {p.style_notes}")

@profile.command("set")
@click.argument("key")
@click.argument("value")
def profile_set(key, value):
    """Set a default preference."""
    from geometry_agent.translator.profile import UserProfile
    p = UserProfile()
    # Try to parse as number
    try:
        value = float(value)
        if value == int(value):
            value = int(value)
    except ValueError:
        pass
    p.set_default(key, value)
    console.print(f"Set {key} = {value}")
```

**Step 5: Run tests**

```bash
pytest tests/test_profile.py -v
```

Expected: All PASS

**Step 6: Commit**

```bash
git add geometry-agent/
git commit -m "feat: user profile with persistent preferences and design history"
```

---

## Phase 4: Production Pipeline (Tasks 15-17)

### Task 15: B-Rep Analysis (Build123d)

**Files:**
- Create: `geometry-agent/src/geometry_agent/analyzers/brep.py`
- Create: `geometry-agent/src/geometry_agent/engines/build123d_engine.py`
- Create: `geometry-agent/tests/test_brep.py`

**Step 1: Write failing tests**

```python
# tests/test_brep.py
import pytest

build123d = pytest.importorskip("build123d")

from geometry_agent.analyzers.brep import analyze_step, check_brep_interference
from geometry_agent.engines.build123d_engine import Build123dEngine

@pytest.fixture
def sample_step(tmp_path):
    """Create a simple STEP file using Build123d."""
    from build123d import Box, export_step
    box = Box(20, 20, 20)
    path = tmp_path / "box.step"
    export_step(box, str(path))
    return path

@pytest.fixture
def two_overlapping_steps(tmp_path):
    from build123d import Box, Pos, export_step
    a = Box(20, 20, 20)
    b = Pos(10, 0, 0) * Box(20, 20, 20)
    a_path = tmp_path / "a.step"
    b_path = tmp_path / "b.step"
    export_step(a, str(a_path))
    export_step(b, str(b_path))
    return a_path, b_path

def test_analyze_volume(sample_step):
    result = analyze_step(sample_step)
    assert abs(result["volume_mm3"] - 8000.0) < 1.0  # 20^3

def test_analyze_surface_area(sample_step):
    result = analyze_step(sample_step)
    assert abs(result["surface_area_mm2"] - 2400.0) < 1.0  # 6 * 20^2

def test_analyze_center_of_mass(sample_step):
    result = analyze_step(sample_step)
    com = result["center_of_mass"]
    assert abs(com[0]) < 0.1 and abs(com[1]) < 0.1 and abs(com[2]) < 0.1

def test_analyze_face_count(sample_step):
    result = analyze_step(sample_step)
    assert result["face_count"] == 6

def test_brep_interference(two_overlapping_steps):
    a, b = two_overlapping_steps
    result = check_brep_interference(a, b)
    assert result["has_interference"] is True
    assert result["interference_volume_mm3"] > 0
```

**Step 2: Run tests to verify they fail**

```bash
pip install build123d
pytest tests/test_brep.py -v
```

**Step 3: Implement B-Rep analyzer**

```python
# src/geometry_agent/analyzers/brep.py
from pathlib import Path

def analyze_step(step_path: Path) -> dict:
    """Analyze a STEP file for volume, surface area, CoM, face count."""
    try:
        from OCP.BRepGProp import brepgprop
        from OCP.GProp import GProp_GProps
        from OCP.STEPControl import STEPControl_Reader
        from OCP.TopExp import TopExp_Explorer
        from OCP.TopAbs import TopAbs_FACE
    except ImportError:
        return {"error": "build123d/OCP not installed"}

    reader = STEPControl_Reader()
    reader.ReadFile(str(step_path))
    reader.TransferRoots()
    shape = reader.OneShape()

    # Volume and CoM
    vol_props = GProp_GProps()
    brepgprop.VolumeProperties(shape, vol_props)
    volume = vol_props.Mass()
    com = vol_props.CentreOfMass()

    # Surface area
    surf_props = GProp_GProps()
    brepgprop.SurfaceProperties(shape, surf_props)
    surface_area = surf_props.Mass()

    # Face count
    face_count = 0
    explorer = TopExp_Explorer(shape, TopAbs_FACE)
    while explorer.More():
        face_count += 1
        explorer.Next()

    return {
        "volume_mm3": round(volume, 3),
        "surface_area_mm2": round(surface_area, 3),
        "center_of_mass": [round(com.X(), 3), round(com.Y(), 3), round(com.Z(), 3)],
        "face_count": face_count,
    }

def check_brep_interference(step_a: Path, step_b: Path) -> dict:
    """Check for B-Rep interference between two STEP files using OCP."""
    try:
        from OCP.BRepAlgoAPI import BRepAlgoAPI_Common
        from OCP.BRepGProp import brepgprop
        from OCP.GProp import GProp_GProps
        from OCP.STEPControl import STEPControl_Reader
    except ImportError:
        return {"error": "build123d/OCP not installed"}

    def load_shape(path):
        reader = STEPControl_Reader()
        reader.ReadFile(str(path))
        reader.TransferRoots()
        return reader.OneShape()

    shape_a = load_shape(step_a)
    shape_b = load_shape(step_b)

    common = BRepAlgoAPI_Common(shape_a, shape_b)
    common.Build()
    common_shape = common.Shape()

    props = GProp_GProps()
    brepgprop.VolumeProperties(common_shape, props)
    interference_vol = props.Mass()

    return {
        "has_interference": interference_vol > 0.001,
        "interference_volume_mm3": round(interference_vol, 3),
    }
```

**Step 4: Implement Build123d engine**

```python
# src/geometry_agent/engines/build123d_engine.py
from pathlib import Path

class Build123dEngine:
    """B-Rep operations and STEP export via Build123d/OCP."""

    def __init__(self):
        try:
            import build123d
            self.available = True
        except ImportError:
            self.available = False

    def stl_to_step(self, stl_path: Path, step_path: Path) -> dict:
        """Convert STL mesh to STEP solid via Build123d import."""
        if not self.available:
            return {"success": False, "error": "build123d not installed"}
        try:
            from build123d import import_stl, export_step
            shape = import_stl(str(stl_path))
            export_step(shape, str(step_path))
            return {"success": True, "output": str(step_path)}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def analyze(self, step_path: Path) -> dict:
        """Analyze STEP file geometry."""
        from geometry_agent.analyzers.brep import analyze_step
        return analyze_step(step_path)
```

**Step 5: Run tests**

```bash
pytest tests/test_brep.py -v
```

Expected: All PASS (requires build123d installed)

**Step 6: Commit**

```bash
git add geometry-agent/
git commit -m "feat: B-Rep analysis engine (Build123d + OCP)"
```

---

### Task 16: STEP Export + STL Export Pipeline

**Files:**
- Create: `geometry-agent/src/geometry_agent/exporters/step.py`
- Create: `geometry-agent/src/geometry_agent/exporters/stl.py`
- Create: `geometry-agent/src/geometry_agent/engines/freecad_engine.py`
- Create: `geometry-agent/tests/test_export.py`

**Step 1: Write failing tests**

```python
# tests/test_export.py
import pytest
from pathlib import Path
from geometry_agent.exporters.stl import export_stl
from geometry_agent.engines.openscad import OpenSCADEngine

FIXTURE = Path(__file__).parent / "fixtures" / "simple_cube.scad"

def test_stl_export(tmp_path):
    result = export_stl(FIXTURE, tmp_path / "output.stl")
    assert result["success"] is True
    assert (tmp_path / "output.stl").exists()
    assert (tmp_path / "output.stl").stat().st_size > 0

def test_stl_export_bad_file(tmp_path):
    bad = tmp_path / "bad.scad"
    bad.write_text("invalid openscad code here !!!")
    result = export_stl(bad, tmp_path / "output.stl")
    assert result["success"] is False

@pytest.mark.skipif(not pytest.importorskip("build123d", reason="build123d not installed"),
                    reason="build123d not installed")
def test_step_export(tmp_path):
    from geometry_agent.exporters.step import export_step
    # First export STL, then convert to STEP
    stl_path = tmp_path / "cube.stl"
    export_stl(FIXTURE, stl_path)
    result = export_step(stl_path, tmp_path / "cube.step")
    assert result["success"] is True
```

**Step 2: Implement STL exporter**

```python
# src/geometry_agent/exporters/stl.py
from pathlib import Path
from geometry_agent.engines.openscad import OpenSCADEngine

def export_stl(scad_path: Path, output_path: Path) -> dict:
    """Export .scad to .stl via OpenSCAD CLI."""
    engine = OpenSCADEngine()
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    import subprocess, os
    try:
        result = subprocess.run(
            [str(engine.binary), "--backend=manifold", "-o", str(output_path), str(scad_path)],
            capture_output=True, text=True, timeout=300, env=engine.env,
        )
        if output_path.exists() and output_path.stat().st_size > 0:
            return {"success": True, "output": str(output_path),
                    "size_bytes": output_path.stat().st_size}
        else:
            return {"success": False, "error": result.stderr[:500]}
    except subprocess.TimeoutExpired:
        return {"success": False, "error": "STL export timed out (300s)"}
```

**Step 3: Implement STEP exporter**

```python
# src/geometry_agent/exporters/step.py
from pathlib import Path

def export_step(input_path: Path, output_path: Path, method: str = "build123d") -> dict:
    """Export to STEP format. Input can be .stl or .scad.

    Methods: 'build123d' (default), 'freecad'
    """
    input_path = Path(input_path)
    output_path = Path(output_path)

    # If input is .scad, first convert to STL
    if input_path.suffix == ".scad":
        from geometry_agent.exporters.stl import export_stl
        stl_path = output_path.with_suffix(".stl")
        stl_result = export_stl(input_path, stl_path)
        if not stl_result["success"]:
            return {"success": False, "error": f"STL export failed: {stl_result['error']}"}
        input_path = stl_path

    if method == "build123d":
        return _export_via_build123d(input_path, output_path)
    elif method == "freecad":
        return _export_via_freecad(input_path, output_path)
    else:
        return {"success": False, "error": f"Unknown method: {method}"}

def _export_via_build123d(stl_path: Path, step_path: Path) -> dict:
    try:
        from geometry_agent.engines.build123d_engine import Build123dEngine
        engine = Build123dEngine()
        return engine.stl_to_step(stl_path, step_path)
    except ImportError:
        return {"success": False, "error": "build123d not installed. pip install build123d"}

def _export_via_freecad(stl_path: Path, step_path: Path) -> dict:
    try:
        from geometry_agent.engines.freecad_engine import FreeCADEngine
        engine = FreeCADEngine()
        return engine.stl_to_step(stl_path, step_path)
    except Exception as e:
        return {"success": False, "error": f"FreeCAD export failed: {e}"}
```

**Step 4: Implement FreeCAD engine (MCP bridge)**

```python
# src/geometry_agent/engines/freecad_engine.py
from pathlib import Path

class FreeCADEngine:
    """Bridge to FreeCAD via MCP RPC (localhost:9875)."""

    def __init__(self, host: str = "localhost", port: int = 9875):
        self.host = host
        self.port = port
        self.available = self._check_available()

    def _check_available(self) -> bool:
        try:
            import xmlrpc.client
            proxy = xmlrpc.client.ServerProxy(f"http://{self.host}:{self.port}")
            proxy.ping()
            return True
        except Exception:
            return False

    def stl_to_step(self, stl_path: Path, step_path: Path) -> dict:
        """Convert STL to STEP via FreeCAD RPC."""
        if not self.available:
            return {"success": False, "error": "FreeCAD RPC not available on localhost:9875"}
        try:
            import xmlrpc.client
            proxy = xmlrpc.client.ServerProxy(f"http://{self.host}:{self.port}")
            # FreeCAD MCP code execution
            code = f"""
import Part
shape = Part.Shape()
shape.read("{str(stl_path).replace(chr(92), '/')}")
solid = Part.makeSolid(shape)
solid.exportStep("{str(step_path).replace(chr(92), '/')}")
"""
            proxy.execute_code(code)
            if Path(step_path).exists():
                return {"success": True, "output": str(step_path)}
            return {"success": False, "error": "STEP file not created"}
        except Exception as e:
            return {"success": False, "error": str(e)}
```

**Step 5: Run tests + Commit**

```bash
pytest tests/test_export.py -v
git add geometry-agent/
git commit -m "feat: STL and STEP export pipeline (OpenSCAD + Build123d + FreeCAD)"
```

---

### Task 17: Consistency Audit (Port from consistency_audit.py)

**Files:**
- Create: `geometry-agent/src/geometry_agent/validators/consistency.py`
- Create: `geometry-agent/tests/test_consistency.py`
- Reference: `3d_design_agent/triple_helix_mvp/check point/consistency_audit.py`

**Step 1: Write failing tests**

```python
# tests/test_consistency.py
import pytest
from pathlib import Path
from geometry_agent.validators.consistency import audit_project

@pytest.fixture
def consistent_project(tmp_path):
    """Create a mini project with consistent config values."""
    config = tmp_path / "config.scad"
    config.write_text("HEX_R = 89;\nWALL = 3;\n")
    main = tmp_path / "main.scad"
    main.write_text('use <config.scad>;\nHEX_R_LOCAL = 89;\n')
    return tmp_path

@pytest.fixture
def drifted_project(tmp_path):
    """Create a project with config drift."""
    config = tmp_path / "config.scad"
    config.write_text("HEX_R = 89;\nWALL = 3;\n")
    main = tmp_path / "main.scad"
    main.write_text("HEX_R = 100;\n")  # Different value!
    return tmp_path

def test_consistent_project(consistent_project):
    result = audit_project(consistent_project)
    assert result["status"] == "PASS"
    assert len(result["drifts"]) == 0

def test_drift_detected(drifted_project):
    result = audit_project(drifted_project)
    assert result["status"] == "FAIL"
    assert len(result["drifts"]) > 0
    assert any("HEX_R" in d["variable"] for d in result["drifts"])
```

**Step 2: Implement consistency auditor**

```python
# src/geometry_agent/validators/consistency.py
from pathlib import Path
from geometry_agent.validators.scad_parser import parse_scad_config

def audit_project(project_dir: Path) -> dict:
    """Check for config value drift across all .scad files in a project."""
    project_dir = Path(project_dir)
    scad_files = list(project_dir.glob("**/*.scad"))

    # Parse all files
    all_configs = {}
    for f in scad_files:
        parsed = parse_scad_config(f)
        if parsed:
            all_configs[str(f)] = parsed

    # Find variables defined in multiple files with different values
    var_sources: dict[str, list[tuple[str, any]]] = {}
    for filepath, config in all_configs.items():
        for var, val in config.items():
            if var not in var_sources:
                var_sources[var] = []
            var_sources[var].append((filepath, val))

    drifts = []
    for var, sources in var_sources.items():
        if len(sources) < 2:
            continue
        values = set()
        for _, val in sources:
            if isinstance(val, (list, dict)):
                values.add(str(val))
            else:
                values.add(val)
        if len(values) > 1:
            drifts.append({
                "variable": var,
                "sources": [{"file": f, "value": v} for f, v in sources],
            })

    return {
        "status": "FAIL" if drifts else "PASS",
        "files_scanned": len(scad_files),
        "variables_checked": len(var_sources),
        "drifts": drifts,
    }
```

**Step 3: Run tests + Commit**

```bash
pytest tests/test_consistency.py -v
git add geometry-agent/
git commit -m "feat: consistency audit for cross-file config drift detection"
```

---

## Phase 5: Nice-to-Haves (Tasks 18-22)

### Task 18: Geometry Metrics Analyzer (trimesh)

**Files:**
- Create: `geometry-agent/src/geometry_agent/analyzers/metrics.py`
- Create: `geometry-agent/tests/test_metrics.py`

Lightweight mesh analysis without Build123d — uses trimesh for STL files.

**Step 1: Write failing tests**

```python
# tests/test_metrics.py
import pytest

trimesh = pytest.importorskip("trimesh")

from geometry_agent.analyzers.metrics import analyze_mesh

@pytest.fixture
def cube_stl(tmp_path):
    import trimesh
    mesh = trimesh.creation.box(extents=[20, 20, 20])
    path = tmp_path / "cube.stl"
    mesh.export(str(path))
    return path

def test_volume(cube_stl):
    result = analyze_mesh(cube_stl)
    assert abs(result["volume_mm3"] - 8000.0) < 1.0

def test_surface_area(cube_stl):
    result = analyze_mesh(cube_stl)
    assert abs(result["surface_area_mm2"] - 2400.0) < 1.0

def test_bounding_box(cube_stl):
    result = analyze_mesh(cube_stl)
    bb = result["bounding_box"]
    assert abs(bb["x"] - 20) < 0.1
    assert abs(bb["y"] - 20) < 0.1
    assert abs(bb["z"] - 20) < 0.1

def test_watertight(cube_stl):
    result = analyze_mesh(cube_stl)
    assert result["is_watertight"] is True

def test_face_count(cube_stl):
    result = analyze_mesh(cube_stl)
    assert result["face_count"] == 12  # 6 faces * 2 triangles each
```

**Step 2: Implement**

```python
# src/geometry_agent/analyzers/metrics.py
from pathlib import Path

def analyze_mesh(stl_path: Path) -> dict:
    """Analyze STL mesh geometry using trimesh."""
    try:
        import trimesh
    except ImportError:
        return {"error": "trimesh not installed"}

    mesh = trimesh.load_mesh(str(stl_path))
    bounds = mesh.bounding_box.extents

    return {
        "volume_mm3": round(float(mesh.volume), 3),
        "surface_area_mm2": round(float(mesh.area), 3),
        "center_of_mass": [round(float(c), 3) for c in mesh.center_mass],
        "bounding_box": {
            "x": round(float(bounds[0]), 3),
            "y": round(float(bounds[1]), 3),
            "z": round(float(bounds[2]), 3),
        },
        "is_watertight": bool(mesh.is_watertight),
        "face_count": len(mesh.faces),
        "vertex_count": len(mesh.vertices),
    }
```

**Step 3: Run tests + Commit**

```bash
pytest tests/test_metrics.py -v
git add geometry-agent/
git commit -m "feat: geometry metrics analyzer (trimesh — volume, CoM, bbox, watertight)"
```

---

### Task 19: Advanced Constraint Files

**Files:**
- Create: `geometry-agent/constraints/four_bar_linkage.yaml`
- Create: `geometry-agent/constraints/gear_mesh.yaml`
- Create: `geometry-agent/constraints/assembly_fit.yaml`
- Create: `geometry-agent/tests/test_advanced_constraints.py`

**Step 1: Create constraint files**

```yaml
# constraints/four_bar_linkage.yaml
name: "Four-bar linkage constraints"
applies_to: linkage.four_bar

rules:
  - name: grashof
    check: "GRASHOF_SUM <= PQ_SUM"
    on_fail: "Linkage cannot make full rotation. Shorten crank or lengthen ground."

  - name: transmission_angle_min
    check: "MIN_TRANSMISSION >= 40"
    on_fail: "Minimum transmission angle {MIN_TRANSMISSION} deg too low. Linkage will jam."

  - name: transmission_angle_max
    check: "MAX_TRANSMISSION <= 140"
    on_fail: "Maximum transmission angle {MAX_TRANSMISSION} deg too high."

  - name: min_link_length
    check: "CRANK >= 5"
    on_fail: "Crank length {CRANK}mm too short for FDM pivot pins."

  - name: link_ratio
    check: "COUPLER / CRANK <= 6"
    on_fail: "Coupler/crank ratio {COUPLER}/{CRANK} = too high. Causes sluggish motion."
```

```yaml
# constraints/gear_mesh.yaml
name: "Gear mesh constraints"
applies_to: gear_system

rules:
  - name: min_teeth
    check: "TOOTH_COUNT >= 12"
    on_fail: "Tooth count {TOOTH_COUNT} causes undercutting. Minimum 12 for standard pressure angle."

  - name: module_range
    check: "MODULE >= 0.5 and MODULE <= 5"
    on_fail: "Module {MODULE}mm outside practical range (0.5-5mm)."

  - name: pressure_angle
    check: "PRESSURE_ANGLE >= 14.5 and PRESSURE_ANGLE <= 25"
    on_fail: "Pressure angle {PRESSURE_ANGLE} deg outside standard range."

  - name: backlash
    check: "BACKLASH >= 0.1 and BACKLASH <= 0.5"
    on_fail: "Backlash {BACKLASH}mm — should be 0.1-0.5mm for FDM gears."

  - name: contact_ratio
    check: "CONTACT_RATIO >= 1.2"
    on_fail: "Contact ratio {CONTACT_RATIO} below 1.2 — gears won't mesh smoothly."
```

```yaml
# constraints/assembly_fit.yaml
name: "Assembly fit constraints"
applies_to: assembly

rules:
  - name: clearance_positive
    check: "MIN_CLEARANCE > 0"
    on_fail: "Interference fit detected: {MIN_CLEARANCE}mm clearance. Parts won't assemble."

  - name: shaft_bearing_fit
    check: "SHAFT_DIA <= BEARING_BORE"
    on_fail: "Shaft {SHAFT_DIA}mm won't fit bearing bore {BEARING_BORE}mm."

  - name: wall_around_bearing
    check: "HOUSING_WALL >= 2.0"
    on_fail: "Housing wall {HOUSING_WALL}mm around bearing too thin. Minimum 2mm for PLA."
```

**Step 2: Write tests + Commit**

```bash
pytest tests/test_advanced_constraints.py -v
git add geometry-agent/constraints/ geometry-agent/tests/
git commit -m "feat: advanced constraint files (four-bar, gear mesh, assembly fit)"
```

---

### Task 20: Validation Cache

**Files:**
- Create: `geometry-agent/src/geometry_agent/orchestrator/cache.py`
- Create: `geometry-agent/tests/test_cache.py`

Cache validation results keyed by file hash. On parameter tweaks, only re-validate changed constraints.

**Step 1: Write failing tests**

```python
# tests/test_cache.py
import pytest
from pathlib import Path
from geometry_agent.orchestrator.cache import ValidationCache

@pytest.fixture
def cache(tmp_path):
    return ValidationCache(cache_dir=tmp_path / ".cache")

def test_cache_miss(cache, tmp_path):
    f = tmp_path / "test.scad"
    f.write_text("cube(10);")
    assert cache.get(f, "compile") is None

def test_cache_hit(cache, tmp_path):
    f = tmp_path / "test.scad"
    f.write_text("cube(10);")
    cache.put(f, "compile", {"success": True})
    result = cache.get(f, "compile")
    assert result is not None
    assert result["success"] is True

def test_cache_invalidated_on_change(cache, tmp_path):
    f = tmp_path / "test.scad"
    f.write_text("cube(10);")
    cache.put(f, "compile", {"success": True})
    # Modify the file
    f.write_text("cube(20);")
    assert cache.get(f, "compile") is None  # Cache invalidated

def test_cache_clear(cache, tmp_path):
    f = tmp_path / "test.scad"
    f.write_text("cube(10);")
    cache.put(f, "compile", {"success": True})
    cache.clear()
    assert cache.get(f, "compile") is None
```

**Step 2: Implement**

```python
# src/geometry_agent/orchestrator/cache.py
import json
import hashlib
from pathlib import Path

class ValidationCache:
    """File-hash-based cache for validation results."""

    def __init__(self, cache_dir: Path | None = None):
        self.cache_dir = Path(cache_dir) if cache_dir else Path.home() / ".geometry-agent" / "cache"
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def _file_hash(self, path: Path) -> str:
        content = Path(path).read_bytes()
        return hashlib.sha256(content).hexdigest()[:16]

    def _cache_key(self, path: Path, step: str) -> Path:
        h = self._file_hash(path)
        return self.cache_dir / f"{Path(path).stem}_{h}_{step}.json"

    def get(self, path: Path, step: str) -> dict | None:
        key = self._cache_key(path, step)
        if key.exists():
            return json.loads(key.read_text())
        return None

    def put(self, path: Path, step: str, result: dict):
        key = self._cache_key(path, step)
        key.write_text(json.dumps(result, default=str))

    def clear(self):
        for f in self.cache_dir.glob("*.json"):
            f.unlink()
```

**Step 3: Run tests + Commit**

```bash
pytest tests/test_cache.py -v
git add geometry-agent/
git commit -m "feat: validation cache (file-hash based, auto-invalidation)"
```

---

### Task 21: MCP Server (Expose geometry-agent as MCP)

**Files:**
- Create: `geometry-agent/src/geometry_agent/mcp_server.py`
- Create: `geometry-agent/tests/test_mcp_server.py`

Expose geometry-agent tools as an MCP server so Claude Code can call them directly.

**Step 1: Write failing tests**

```python
# tests/test_mcp_server.py
import pytest
from geometry_agent.mcp_server import GeometryAgentMCP

def test_server_instantiation():
    server = GeometryAgentMCP()
    assert server is not None

def test_list_tools():
    server = GeometryAgentMCP()
    tools = server.list_tools()
    tool_names = [t["name"] for t in tools]
    assert "validate" in tool_names
    assert "compile" in tool_names
    assert "render" in tool_names
    assert "collide" in tool_names
```

**Step 2: Implement MCP server**

```python
# src/geometry_agent/mcp_server.py
"""MCP Server — exposes geometry-agent tools to Claude Code."""
import json
from pathlib import Path

class GeometryAgentMCP:
    """Minimal MCP-compatible server for geometry-agent tools."""

    def list_tools(self) -> list[dict]:
        return [
            {"name": "compile", "description": "Compile OpenSCAD file (zero warnings)",
             "inputSchema": {"type": "object", "properties": {"file": {"type": "string"}}, "required": ["file"]}},
            {"name": "validate", "description": "Run YAML constraint checks on .scad file",
             "inputSchema": {"type": "object", "properties": {"file": {"type": "string"}, "constraints": {"type": "string"}}, "required": ["file"]}},
            {"name": "render", "description": "Render multi-view PNGs",
             "inputSchema": {"type": "object", "properties": {"file": {"type": "string"}, "views": {"type": "string", "default": "isometric"}}, "required": ["file"]}},
            {"name": "collide", "description": "Check mesh collisions between STL files",
             "inputSchema": {"type": "object", "properties": {"files": {"type": "array", "items": {"type": "string"}}}, "required": ["files"]}},
            {"name": "analyze", "description": "Analyze STL/STEP geometry (volume, CoM, bbox)",
             "inputSchema": {"type": "object", "properties": {"file": {"type": "string"}}, "required": ["file"]}},
            {"name": "diff", "description": "Visual diff between two PNG renders",
             "inputSchema": {"type": "object", "properties": {"a": {"type": "string"}, "b": {"type": "string"}}, "required": ["a", "b"]}},
            {"name": "tolerance", "description": "ISO 286 tolerance lookup",
             "inputSchema": {"type": "object", "properties": {"nominal": {"type": "number"}, "hole": {"type": "string"}, "shaft": {"type": "string"}}, "required": ["nominal", "hole"]}},
        ]

    def call_tool(self, name: str, arguments: dict) -> dict:
        if name == "compile":
            from geometry_agent.engines.openscad import OpenSCADEngine
            engine = OpenSCADEngine()
            result = engine.compile(Path(arguments["file"]))
            return {"success": result.success, "warnings": result.warnings, "errors": result.errors}

        elif name == "validate":
            from geometry_agent.validators.scad_parser import parse_scad_config
            from geometry_agent.validators.constraints import check_constraints
            cfg = parse_scad_config(Path(arguments["file"]))
            if cfg and "constraints" in arguments:
                return {"results": check_constraints(cfg, Path(arguments["constraints"]))}
            return {"results": [], "note": "No config parsed or no constraints file"}

        elif name == "render":
            from geometry_agent.engines.openscad import OpenSCADEngine
            engine = OpenSCADEngine()
            views = arguments.get("views", "isometric").split(",")
            output_dir = Path(arguments["file"]).parent / "renders"
            result = engine.render(Path(arguments["file"]), output_dir, views)
            return {"success": result.success, "images": result.images}

        elif name == "collide":
            from geometry_agent.analyzers.collision import check_collisions
            return check_collisions(arguments["files"])

        elif name == "analyze":
            f = Path(arguments["file"])
            if f.suffix == ".step":
                from geometry_agent.analyzers.brep import analyze_step
                return analyze_step(f)
            else:
                from geometry_agent.analyzers.metrics import analyze_mesh
                return analyze_mesh(f)

        elif name == "diff":
            from geometry_agent.analyzers.visual_diff import compare_renders
            return compare_renders(Path(arguments["a"]), Path(arguments["b"]))

        elif name == "tolerance":
            from geometry_agent.validators.tolerance import iso286_lookup, fit_analysis
            result = iso286_lookup(arguments["nominal"], arguments["hole"])
            if "shaft" in arguments:
                fit = fit_analysis(arguments["nominal"], arguments["hole"], arguments["shaft"])
                result["fit"] = fit
            return result

        return {"error": f"Unknown tool: {name}"}
```

**Step 3: Run tests + Commit**

```bash
pytest tests/test_mcp_server.py -v
git add geometry-agent/
git commit -m "feat: MCP server exposing geometry-agent tools to Claude Code"
```

---

### Task 22: Full CLI Integration + README

**Files:**
- Modify: `geometry-agent/src/geometry_agent/cli.py` (wire ALL remaining commands)
- Create: `geometry-agent/README.md`

Wire all remaining CLI commands: `new`, `collide`, `diff`, `analyze`, `export`, `audit`, `tolerance`.

**Step 1: Wire remaining commands into cli.py**

```python
# Add these commands to cli.py

@main.command()
@click.argument("stl_files", nargs=-1, type=click.Path(exists=True))
def collide(stl_files):
    """Check for mesh collisions between STL files."""
    from geometry_agent.analyzers.collision import check_collisions
    result = check_collisions(list(stl_files))
    if result.get("has_collisions"):
        console.print(f"[red]COLLISION[/red] {len(result['pairs'])} interference(s) found")
        for p in result["pairs"]:
            console.print(f"  {p['part_a']} x {p['part_b']}")
        raise SystemExit(1)
    else:
        console.print(f"[green]CLEAR[/green] No collisions among {result['part_count']} parts")

@main.command("diff")
@click.argument("dir_a", type=click.Path(exists=True))
@click.argument("dir_b", type=click.Path(exists=True))
@click.option("--output", "-o", type=click.Path(), help="Output directory for diff images")
def diff_cmd(dir_a, dir_b, output):
    """Visual diff between two render directories."""
    from geometry_agent.analyzers.visual_diff import compare_renders
    dir_a, dir_b = Path(dir_a), Path(dir_b)
    out_dir = Path(output) if output else dir_b / "diffs"
    out_dir.mkdir(parents=True, exist_ok=True)
    pngs_a = sorted(dir_a.glob("*.png"))
    for img_a in pngs_a:
        img_b = dir_b / img_a.name
        if img_b.exists():
            result = compare_renders(img_a, img_b, diff_output=out_dir / f"diff_{img_a.name}")
            status = "[red]CHANGED[/red]" if result["changed"] else "[green]SAME[/green]"
            console.print(f"  {status} {img_a.name} ({result['pct_changed']:.1f}% changed)")

@main.command()
@click.argument("file", type=click.Path(exists=True))
def analyze(file):
    """Analyze STL or STEP file geometry (volume, CoM, bbox)."""
    f = Path(file)
    if f.suffix == ".step":
        from geometry_agent.analyzers.brep import analyze_step
        result = analyze_step(f)
    else:
        from geometry_agent.analyzers.metrics import analyze_mesh
        result = analyze_mesh(f)
    for k, v in result.items():
        console.print(f"  [bold]{k}:[/bold] {v}")

@main.command()
@click.argument("scad_file", type=click.Path(exists=True))
@click.option("--format", "fmt", default="stl", type=click.Choice(["stl", "step"]))
@click.option("--output", "-o", type=click.Path(), help="Output file path")
@click.option("--method", default="build123d", type=click.Choice(["build123d", "freecad"]))
def export(scad_file, fmt, output, method):
    """Export .scad to STL or STEP."""
    out = Path(output) if output else Path(scad_file).with_suffix(f".{fmt}")
    if fmt == "stl":
        from geometry_agent.exporters.stl import export_stl
        result = export_stl(Path(scad_file), out)
    else:
        from geometry_agent.exporters.step import export_step
        result = export_step(Path(scad_file), out, method=method)
    if result["success"]:
        console.print(f"[green]EXPORTED[/green] {out}")
    else:
        console.print(f"[red]FAILED[/red] {result['error']}")
        raise SystemExit(1)

@main.command()
@click.argument("project_dir", default=".", type=click.Path(exists=True))
def audit(project_dir):
    """Consistency check across project .scad files."""
    from geometry_agent.validators.consistency import audit_project
    result = audit_project(Path(project_dir))
    if result["status"] == "PASS":
        console.print(f"[green]PASS[/green] {result['files_scanned']} files, {result['variables_checked']} vars — no drift")
    else:
        console.print(f"[red]FAIL[/red] {len(result['drifts'])} variable(s) have inconsistent values:")
        for d in result["drifts"]:
            console.print(f"  [yellow]{d['variable']}[/yellow]:")
            for src in d["sources"]:
                console.print(f"    {src['file']}: {src['value']}")

@main.command()
@click.argument("fit_spec")
@click.argument("nominal", type=float)
def tolerance(fit_spec, nominal):
    """ISO 286 tolerance lookup. Usage: geometry-agent tolerance H7/g6 25"""
    from geometry_agent.validators.tolerance import iso286_lookup, fit_analysis, format_fit_report
    parts = fit_spec.split("/")
    if len(parts) == 2:
        result = fit_analysis(nominal, parts[0], parts[1])
        console.print(format_fit_report(result))
    else:
        result = iso286_lookup(nominal, parts[0])
        for k, v in result.items():
            console.print(f"  {k}: {v}")

@main.command("new")
@click.argument("category", required=False)
@click.option("--from-spec", type=click.Path(exists=True), help="Skip translator, use existing spec")
def new_design(category, from_spec):
    """Start guided interview for a new design."""
    if from_spec:
        import yaml
        with open(from_spec) as f:
            spec = yaml.safe_load(f)
        console.print(f"[bold]Loaded spec:[/bold] {spec.get('type')}/{spec.get('subtype')}")
        return

    from geometry_agent.translator.context import TranslatorContext
    from geometry_agent.translator.interviewer import Interviewer
    from geometry_agent.translator.profile import UserProfile

    ctx = TranslatorContext()
    profile = UserProfile()
    knowledge_dir = Path(__file__).parent.parent.parent / "knowledge"
    interviewer = Interviewer(knowledge_dir)

    if category:
        ctx.add_message(f"I want to build a {category}")

    # Interactive loop
    while ctx.state != "READY_TO_INTERVIEW":
        if ctx.state == "NEEDS_CLARIFICATION":
            prompt = ctx.get_clarification_prompt()
            console.print(f"\n[bold]{prompt}[/bold]")
        else:
            console.print("\n[dim]Tell me more about what you want to build...[/dim]")
        user_input = click.prompt("You", prompt_suffix="> ")
        status = ctx.add_message(user_input)
        console.print(f"  [dim]Confidence: {status['confidence']:.0%} — {status['state']}[/dim]")

    console.print(f"\n[green]Identified:[/green] {ctx.category} / {ctx.subtype}")

    # Run interview
    questions = interviewer.get_questions(ctx.category, ctx.subtype, skip=profile.get_skip_dict())
    for q in questions:
        console.print(f"\n[bold]{q['prompt']}[/bold]")
        for i, opt in enumerate(q["options"]):
            console.print(f"  [{i+1}] {opt['label']}")
            console.print(f"      [dim]{opt['impact']}[/dim]")
        choice = click.prompt("Choice", type=int) - 1
        interviewer.answer(q["param"], choice)

    params = interviewer.resolve_answers(ctx.category, ctx.subtype)
    from geometry_agent.translator.spec_builder import build_spec, spec_to_yaml
    spec = build_spec(ctx.category, ctx.subtype, params)

    out_path = f"{ctx.category}_{ctx.subtype}_spec.yaml"
    spec_to_yaml(spec, out_path)
    console.print(f"\n[green]Spec saved:[/green] {out_path}")
    profile.record_design(ctx.category, ctx.subtype, params)
```

**Step 2: Run full test suite**

```bash
pytest tests/ -v
```

Expected: All PASS

**Step 3: Commit**

```bash
git add geometry-agent/
git commit -m "feat: complete CLI with all commands wired"
```

---

## Verification Checklist

After all tasks complete, verify:

**Phase 1: Foundation**
- [ ] `geometry-agent --version` returns 0.1.0
- [ ] `geometry-agent compile tests/fixtures/simple_cube.scad` — PASS, zero warnings
- [ ] `geometry-agent validate tests/fixtures/test_config.scad` — runs constraint checks
- [ ] `geometry-agent render tests/fixtures/simple_cube.scad --views all` — produces 8 PNGs
- [ ] `geometry-agent tolerance H7/g6 25` — shows clearance fit data

**Phase 2: Intelligence**
- [ ] `geometry-agent run design.scad -c constraints/example.yaml` — full pipeline
- [ ] `geometry-agent run` generates JSON report with `--report json`
- [ ] `geometry-agent run` generates HTML report with `--report html`
- [ ] Claude Code hook fires on `.scad` edit

**Phase 3: Translator**
- [ ] Knowledge YAML files parse correctly (`pytest tests/test_knowledge.py`)
- [ ] `geometry-agent new linkage` — starts guided interview
- [ ] Multi-message context accumulation works (vague → confident)
- [ ] Impact-based questions show consequences of each choice
- [ ] `geometry-agent profile show` — displays saved preferences
- [ ] Profile skip list works (known answers not re-asked)

**Phase 4: Production Pipeline**
- [ ] `geometry-agent analyze part.stl` — shows volume, CoM, bbox
- [ ] `geometry-agent analyze part.step` — shows B-Rep metrics
- [ ] `geometry-agent export design.scad --format stl` — produces STL
- [ ] `geometry-agent export design.scad --format step` — produces STEP
- [ ] `geometry-agent audit` — detects config drift across .scad files

**Phase 5: Nice-to-Haves**
- [ ] `geometry-agent collide a.stl b.stl` — detects overlap
- [ ] `geometry-agent diff renders/v1/ renders/v2/` — shows changed pixels
- [ ] Validation cache skips re-checks for unchanged files
- [ ] MCP server tools list matches CLI commands
- [ ] Advanced constraint files (four-bar, gear mesh, assembly) parse and evaluate

**Full Suite**
- [ ] `pytest tests/ -v` — ALL tests pass
- [ ] `pip install -e ".[full,dev]"` — installs without errors
