# KFS Gap Closure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Close all 12 gaps in kfs-gaps.yaml so KFS works end-to-end as a design enforcement engine.

**Architecture:** Each gap is an isolated fix. Work in severity order (critical → high → medium → low). Each fix is verified with its verify command from kfs-gaps.yaml before marking closed. Update kfs-gaps.yaml after each verification.

**Tech Stack:** Python 3.12, FastAPI, aiosqlite, React 18, TypeScript

**Gap Tracker:** `C:\Users\abhis\.claude\projects\D--Claude-local\memory\projects\kfs-gaps.yaml`

**Session Protocol:** Read kfs-gaps.yaml at start. Update it after each verified fix. Never mark closed without running verify.

---

## Task 1: GAP-01 — Switch LLM Provider to Claude-First

**Files:**
- Modify: `backend/app/config.py:8-30`
- Modify: `backend/app/orchestrator/chat_agent.py:83-91`

**Step 1: Add preferred_provider to config.py**

In `backend/app/config.py`, add after line 29 (groq_max_tokens):

```python
preferred_provider: str = "claude"  # claude | groq | grok — env: KFS_PREFERRED_PROVIDER
```

**Step 2: Rewrite _active_provider() in chat_agent.py**

Replace lines 83-91 in `backend/app/orchestrator/chat_agent.py`:

```python
def _active_provider(self) -> Literal["groq", "grok", "claude"] | None:
    """Return the active LLM provider, respecting preferred_provider config."""
    preferred = settings.preferred_provider

    # Check preferred provider first
    key_map = {
        "claude": settings.claude_api_key,
        "groq": settings.groq_api_key,
        "grok": settings.grok_api_key,
    }
    if preferred in key_map and key_map[preferred]:
        return preferred

    # Fallback chain: claude → groq → grok
    if settings.claude_api_key:
        return "claude"
    if settings.groq_api_key:
        return "groq"
    if settings.grok_api_key:
        return "grok"
    return None
```

**Step 3: Verify**

Start backend server, send a chat message, confirm response shows Claude as provider:

```bash
cd "D:\Claude local\kinetic-forge-studio\backend"
py -3.12 -m uvicorn app.main:app --port 8100
```

Then in another terminal:
```bash
curl -X POST http://localhost:8100/api/projects/{id}/chat -H "Content-Type: application/json" -d "{\"message\":\"hello\"}"
```

Check response for `provider` field = `"claude"`.

**Step 4: Update kfs-gaps.yaml**

Set GAP-01 status to `closed`, `closed_by: "2026-03-03"`.

---

## Task 2: GAP-02 — Wire scad_dir File Reading into Chat Pipeline

**Files:**
- Modify: `backend/app/routes/chat.py:207-292` (_send_via_agent)
- Modify: `backend/app/ai/prompt_builder.py:269-278` (add scad_source param)
- Modify: `backend/app/orchestrator/chat_agent.py:108-120` (add scad_source param)

**Step 1: Add scad_source to prompt_builder.py**

In `backend/app/ai/prompt_builder.py`, modify `build_system_prompt()` signature (line 269-278) to add `scad_source`:

```python
def build_system_prompt(
    self,
    spec: dict[str, Any] | None = None,
    gate_level: str = "design",
    locked_decisions: list[dict] | None = None,
    components: list[dict] | None = None,
    user_profile: dict | None = None,
    library_matches: list[dict] | None = None,
    consultant_context: dict | None = None,
    scad_source: dict[str, str] | None = None,  # {filename: content}
) -> str:
```

Then add formatting code AFTER the consultant_context block (after line 398):

```python
if scad_source:
    lines = ["\n## OpenSCAD Source Files (from project scad_dir)"]
    lines.append("The user has existing OpenSCAD files. Reference these when discussing the design.")
    lines.append("IMPORTANT: Use parameter names and values from these files. Do NOT invent new values.")
    for filename, content in scad_source.items():
        lines.append(f"\n### {filename}")
        lines.append(f"```openscad\n{content}\n```")
    context_parts.append("\n".join(lines))
```

**Step 2: Add scad_source to chat_agent.py**

In `backend/app/orchestrator/chat_agent.py`, add `scad_source` to `chat()` signature (after line 119):

```python
async def chat(
    self,
    user_message: str,
    conversation_history: list[dict[str, str]],
    spec: dict[str, Any] | None = None,
    gate_level: str = "design",
    locked_decisions: list[dict] | None = None,
    components: list[dict] | None = None,
    user_profile: dict | None = None,
    classifier_results: dict | None = None,
    library_matches: list[dict] | None = None,
    consultant_context: dict | None = None,
    scad_source: dict[str, str] | None = None,
) -> AgentResponse:
```

And pass it through to prompt builder (around line 140-148):

```python
system_prompt = self.prompt_builder.build_system_prompt(
    spec=spec,
    gate_level=gate_level,
    locked_decisions=locked_decisions,
    components=components,
    user_profile=user_profile,
    library_matches=library_matches,
    consultant_context=consultant_context,
    scad_source=scad_source,
)
```

**Step 3: Read scad files in chat.py _send_via_agent()**

In `backend/app/routes/chat.py`, add a helper function (before `_send_via_agent`):

```python
def _read_scad_source(project) -> dict[str, str] | None:
    """Read .scad files from project's scad_dir for LLM context."""
    if not project.scad_dir:
        return None
    scad_dir = Path(project.scad_dir)
    if not scad_dir.exists():
        return None

    scad_source = {}
    MAX_CHARS_PER_FILE = 4000
    MAX_FILES = 10
    MAX_TOTAL_CHARS = 20000
    total_chars = 0

    scad_files = sorted(scad_dir.glob("**/*.scad"))[:MAX_FILES]
    for scad_file in scad_files:
        try:
            content = scad_file.read_text(encoding="utf-8", errors="replace")
            if len(content) > MAX_CHARS_PER_FILE:
                content = content[:MAX_CHARS_PER_FILE] + "\n// ... (truncated)"
            if total_chars + len(content) > MAX_TOTAL_CHARS:
                break
            scad_source[scad_file.name] = content
            total_chars += len(content)
        except Exception:
            continue

    return scad_source if scad_source else None
```

Then inside `_send_via_agent()`, before the `agent.chat()` call (around line 280), add:

```python
# Read OpenSCAD source files from project's scad_dir
scad_source = _read_scad_source(project)
```

And pass it to the agent.chat() call:

```python
response = await state.agent.chat(
    user_message=msg.message,
    conversation_history=...,
    spec=...,
    gate_level=...,
    locked_decisions=...,
    components=...,
    user_profile=...,
    classifier_results=...,
    library_matches=...,
    scad_source=scad_source,
)
```

**Step 4: Add Path import if missing**

At top of chat.py, ensure `from pathlib import Path` is imported.

**Step 5: Verify**

1. Set scad_dir on a test project:
```bash
curl -X POST http://localhost:8100/api/projects/{id}/scad-dir \
  -H "Content-Type: application/json" \
  -d "{\"scad_dir\": \"D:/Claude local/3d_design_agent/projects/triple-helix\"}"
```

2. Send a chat message about the design:
```bash
curl -X POST http://localhost:8100/api/projects/{id}/chat \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"What are the current dimensions of the eccentric cam?\"}"
```

3. Confirm LLM response references actual parameter names from .scad files (like `CAM_ECCENTRICITY`, `NUM_CHANNELS`, etc.)

**Step 6: Update kfs-gaps.yaml**

Set GAP-02 status to `closed`, `closed_by: "2026-03-03"`.

---

## Task 3: GAP-04 — Wire consultant_context into Chat Pipeline

**Files:**
- Modify: `backend/app/routes/chat.py:282-292` (agent.chat() call)

**Step 1: Fetch consultant context before agent.chat()**

In `_send_via_agent()`, before the agent.chat() call, add:

```python
# Fetch consultant context from Rule 99 for current gate
consultant_context = None
try:
    from app.consultants.rule99_engine import Rule99Engine
    rule99 = Rule99Engine()
    project_state = {
        "gate": project.gate,
        "components": existing_components,
        "spec": spec,
        "decisions": locked_decisions,
    }
    report = rule99.run_gate_consultants(project.gate, project_state)
    consultant_context = {
        "gate": project.gate,
        "consultants": [
            {"name": c.name, "checks": c.findings, "passed": c.passed}
            for c in report.consultants_fired
        ],
        "recommendations": report.recommendations,
        "library_suggestions": [
            {"name": lib.name, "purpose": lib.purpose}
            for lib in report.library_suggestions
        ],
    }
except Exception:
    pass  # Rule 99 is advisory, don't block chat
```

**Step 2: Pass consultant_context to agent.chat()**

Add `consultant_context=consultant_context` to the agent.chat() call at line ~282-292.

Also add it to the retry call (around line 413-422).

**Step 3: Verify**

Send chat message, add temporary debug log in prompt_builder to print whether consultant_context is non-None. Check server logs.

**Step 4: Update kfs-gaps.yaml**

Set GAP-04 status to `closed`.

---

## Task 4: GAP-03/GAP-07 — Wire CadQuery into Rule 500 Step 20

**Files:**
- Modify: `backend/app/orchestrator/steps/production_gate.py:24-30`

**Step 1: Implement step20_cadquery_brep()**

Replace lines 24-30 in production_gate.py:

```python
async def step20_cadquery_brep(context: dict) -> StepResult:
    """Generate B-Rep geometry via CadQuery if Python scripts exist."""
    project_dir = Path(context.get("project_dir", ""))
    components = context.get("components", [])

    # Look for existing CadQuery/Python scripts in project dir
    py_files = list(project_dir.glob("**/*.py")) if project_dir.exists() else []
    cadquery_scripts = [f for f in py_files if _is_cadquery_script(f)]

    if not cadquery_scripts:
        return StepResult(
            step=20, name="CadQuery B-Rep", phase="production",
            passed=True,
            findings=["No CadQuery scripts found in project directory. Skipping."],
        )

    findings = []
    generated_files = []
    try:
        from app.engines.cadquery_engine import CadQueryEngine
        engine = CadQueryEngine()
        output_dir = project_dir / "models"
        output_dir.mkdir(parents=True, exist_ok=True)

        for script in cadquery_scripts:
            code = script.read_text(encoding="utf-8", errors="replace")
            result = await engine.generate(
                code=code,
                output_dir=output_dir,
                filename_base=script.stem,
            )
            if result.success:
                findings.append(f"✓ {script.name}: STEP={result.step_path}, STL={result.stl_path}")
                generated_files.extend([str(result.step_path), str(result.stl_path)])
            else:
                findings.append(f"✗ {script.name}: {result.error}")
    except ImportError:
        findings.append("CadQuery not installed. pip install cadquery to enable.")
    except Exception as e:
        findings.append(f"CadQuery execution error: {e}")

    return StepResult(
        step=20, name="CadQuery B-Rep", phase="production",
        passed=len(generated_files) > 0 or not cadquery_scripts,
        findings=findings,
        data={"generated_files": generated_files},
    )


def _is_cadquery_script(path: Path) -> bool:
    """Check if a Python file contains CadQuery/build123d code."""
    try:
        content = path.read_text(encoding="utf-8", errors="replace")[:2000]
        indicators = ["import cadquery", "import build123d", "cq.Workplane", "from cadquery"]
        return any(ind in content for ind in indicators)
    except Exception:
        return False
```

**Step 2: Add Path import at top of production_gate.py**

```python
from pathlib import Path
```

**Step 3: Wire steps 21-24 with graceful FreeCAD degradation**

Replace steps 21-24 with implementations that try FreecadEngine but gracefully skip if MCP is not running. Pattern for each:

```python
async def step21_freecad_step(context: dict) -> StepResult:
    """Convert STL/STEP files via FreeCAD MCP (skips if unavailable)."""
    project_dir = Path(context.get("project_dir", ""))
    findings = []

    stl_files = list(project_dir.glob("**/*.stl")) if project_dir.exists() else []
    if not stl_files:
        return StepResult(
            step=21, name="FreeCAD STEP", phase="production",
            passed=True, findings=["No STL files to convert."],
        )

    try:
        from app.engines.freecad_engine import FreecadEngine
        engine = FreecadEngine()
        for stl in stl_files[:10]:
            result = await engine.convert_step(stl)
            if result and result.get("success"):
                findings.append(f"✓ {stl.name} → STEP converted")
            else:
                findings.append(f"⚠ {stl.name}: conversion skipped ({result.get('error', 'unknown')})")
    except Exception as e:
        findings.append(f"FreeCAD MCP not available: {e}. Skipping STEP conversion.")

    return StepResult(
        step=21, name="FreeCAD STEP", phase="production",
        passed=True, findings=findings if findings else ["No conversions attempted."],
    )
```

Follow same pattern for steps 22 (assembly), 23 (drawings), 24 (FEM) — each tries the engine, catches errors, reports "skipped" if FreeCAD unavailable.

**Step 4: Verify**

```bash
curl -X POST http://localhost:8100/api/projects/{id}/rule500 \
  -H "Content-Type: application/json"
```

Check that steps 20-24 return actual findings (file paths or "skipped: FreeCAD not available"), NOT static placeholder messages.

**Step 5: Update kfs-gaps.yaml**

Set GAP-03 and GAP-07 status to `closed`.

---

## Task 5: GAP-05 — Complete Export ZIP

**Files:**
- Modify: `backend/app/routes/export.py:95-147`

**Step 1: Add BOM generation to export**

After the existing renders block (around line 147), add:

```python
# BOM (Bill of Materials)
bom = []
for comp in components:
    bom.append({
        "id": comp.get("id", ""),
        "name": comp.get("display_name", comp.get("id", "")),
        "type": comp.get("type", comp.get("component_type", "unknown")),
        "parameters": comp.get("parameters", {}),
        "material": comp.get("parameters", {}).get("material", "unspecified"),
    })
zf.writestr("bom.json", json.dumps(bom, indent=2, default=str))

# Consultant findings (last Rule 99 run if available)
try:
    from app.consultants.rule99_engine import Rule99Engine
    engine = Rule99Engine()
    project_state = {
        "gate": project.gate,
        "components": components,
        "spec": {},
        "decisions": decisions,
    }
    report = engine.run_gate_consultants(project.gate, project_state)
    consultant_data = {
        "gate": project.gate,
        "passed": report.passed,
        "consultants": [
            {"name": c.name, "passed": c.passed, "findings": c.findings}
            for c in report.consultants_fired
        ],
        "recommendations": report.recommendations,
    }
    zf.writestr(
        "reports/consultant_findings.json",
        json.dumps(consultant_data, indent=2, default=str),
    )
except Exception:
    pass  # Skip if Rule 99 not available
```

**Step 2: Ensure `import json` at top of export.py**

**Step 3: Verify**

```bash
curl -o export.zip http://localhost:8100/api/export/{id}
```

Unzip and confirm `bom.json` exists and `reports/consultant_findings.json` exists.

**Step 4: Update kfs-gaps.yaml**

Set GAP-05 status to `closed`.

---

## Task 6: GAP-06 — Fix Rule 500 Steps 30-31

**Files:**
- Modify: `backend/app/orchestrator/steps/finalize.py:41-75`

**Step 1: Implement step30 export package**

Replace step30 (lines 41-66):

```python
async def step30_export_package(context: dict) -> StepResult:
    """List export package contents for the project."""
    project_dir = Path(context.get("project_dir", ""))
    findings = []

    if project_dir.exists():
        scad_count = len(list(project_dir.glob("**/*.scad")))
        stl_count = len(list(project_dir.glob("**/*.stl")))
        step_count = len(list(project_dir.glob("**/*.step")))
        png_count = len(list(project_dir.glob("**/*.png")))
        findings.append(f"Project files: {scad_count} .scad, {stl_count} .stl, {step_count} .step, {png_count} .png")
    else:
        findings.append("No project directory found.")

    components = context.get("components", [])
    findings.append(f"Components in registry: {len(components)}")
    findings.append("Export available at GET /api/export/{project_id}")

    return StepResult(
        step=30, name="Export Package", phase="finalize",
        passed=True, findings=findings,
        data={"scad_count": scad_count if project_dir.exists() else 0,
              "stl_count": stl_count if project_dir.exists() else 0,
              "step_count": step_count if project_dir.exists() else 0},
    )
```

**Step 2: Implement step31 final report**

Replace step31 (lines 69-75):

```python
async def step31_final_report(context: dict) -> StepResult:
    """Generate pipeline summary from all step results."""
    pipeline_results = context.get("pipeline_results", [])

    total = len(pipeline_results)
    passed = sum(1 for r in pipeline_results if r.get("passed", False))
    failed = total - passed

    findings = [
        f"Pipeline complete: {passed}/{total} steps passed, {failed} failed.",
    ]

    for r in pipeline_results:
        step_num = r.get("step", "?")
        name = r.get("name", "?")
        status = "✓" if r.get("passed") else "✗"
        findings.append(f"  {status} Step {step_num}: {name}")

    return StepResult(
        step=31, name="Final Report", phase="finalize",
        passed=failed == 0,
        findings=findings,
        data={"total": total, "passed": passed, "failed": failed,
              "steps": pipeline_results},
    )
```

**Step 3: Pass pipeline_results into step31 context**

In `backend/app/orchestrator/rule500_pipeline.py`, find where step31 is called. Ensure `context["pipeline_results"]` is populated with all previous step results (as list of dicts).

**Step 4: Add `from pathlib import Path` import to finalize.py if missing**

**Step 5: Verify**

```bash
curl -X POST http://localhost:8100/api/projects/{id}/rule500
```

Check step 31 result contains per-step pass/fail summary, not a static sentence.

**Step 6: Update kfs-gaps.yaml**

Set GAP-06 status to `closed`.

---

## Task 7: GAP-08 — Create architecture_validator.py

**Files:**
- Create: `backend/app/validators/architecture_validator.py`
- Modify: `backend/app/orchestrator/gate.py` (add import and call)

**Step 1: Create the validator**

```python
"""Architecture validator — vertical budget, Grashof, transmission angle, power budget."""

from __future__ import annotations
import math


def vertical_budget_check(
    components: list[dict], envelope_height: float | None = None
) -> dict:
    """Check total Z-stack vs envelope height."""
    z_items = []
    total_height = 0.0

    for comp in components:
        params = comp.get("parameters", {})
        h = params.get("height", 0)
        if h:
            z_items.append({"name": comp.get("id", "?"), "height": float(h)})
            total_height += float(h)

    result = {
        "total_height": total_height,
        "items": z_items,
        "passed": True,
        "findings": [],
    }

    if envelope_height and total_height > envelope_height:
        result["passed"] = False
        result["findings"].append(
            f"Z-stack ({total_height:.1f}mm) exceeds envelope ({envelope_height:.1f}mm) "
            f"by {total_height - envelope_height:.1f}mm"
        )
    elif envelope_height:
        surplus = envelope_height - total_height
        result["findings"].append(
            f"Z-stack OK: {total_height:.1f}mm of {envelope_height:.1f}mm "
            f"({surplus:.1f}mm surplus)"
        )
    else:
        result["findings"].append(
            f"Z-stack total: {total_height:.1f}mm (no envelope specified)"
        )

    return result


def grashof_check(
    crank: float, coupler: float, rocker: float, ground: float
) -> dict:
    """Check Grashof condition for a four-bar linkage."""
    links = sorted([crank, coupler, rocker, ground])
    s, p, q, l_ = links[0], links[1], links[2], links[3]

    grashof_sum = s + l_
    other_sum = p + q
    is_grashof = grashof_sum <= other_sum

    result = {
        "passed": is_grashof,
        "s_plus_l": grashof_sum,
        "p_plus_q": other_sum,
        "findings": [],
    }

    if is_grashof:
        result["findings"].append(
            f"Grashof satisfied: S+L={grashof_sum:.1f} ≤ P+Q={other_sum:.1f}"
        )
    else:
        result["findings"].append(
            f"Grashof VIOLATED: S+L={grashof_sum:.1f} > P+Q={other_sum:.1f}. "
            "Mechanism will lock up."
        )

    return result


def transmission_angle_check(
    angles_deg: list[float], min_ok: float = 40.0, max_ok: float = 140.0
) -> dict:
    """Check transmission angles are within acceptable range (40°-140°)."""
    violations = []
    for angle in angles_deg:
        if angle < min_ok or angle > max_ok:
            violations.append(angle)

    result = {
        "passed": len(violations) == 0,
        "angles": angles_deg,
        "violations": violations,
        "findings": [],
    }

    if violations:
        result["findings"].append(
            f"Transmission angle violations: {violations} outside [{min_ok}°, {max_ok}°]"
        )
    else:
        result["findings"].append(
            f"All {len(angles_deg)} transmission angles within [{min_ok}°, {max_ok}°]"
        )

    return result


def power_budget_check(
    required_torque_nm: float,
    required_speed_rpm: float,
    motor_power_w: float,
    safety_factor: float = 2.0,
) -> dict:
    """Check required power < motor power / safety_factor."""
    required_power = required_torque_nm * (required_speed_rpm * 2 * math.pi / 60)
    available_power = motor_power_w / safety_factor

    result = {
        "passed": required_power <= available_power,
        "required_w": round(required_power, 2),
        "available_w": round(available_power, 2),
        "motor_power_w": motor_power_w,
        "safety_factor": safety_factor,
        "findings": [],
    }

    if result["passed"]:
        margin = available_power - required_power
        result["findings"].append(
            f"Power OK: {required_power:.1f}W required, {available_power:.1f}W available "
            f"({margin:.1f}W margin with {safety_factor}x safety)"
        )
    else:
        result["findings"].append(
            f"Power EXCEEDED: {required_power:.1f}W required > {available_power:.1f}W available "
            f"(motor={motor_power_w}W / {safety_factor}x safety)"
        )

    return result
```

**Step 2: Verify import**

```bash
cd "D:\Claude local\kinetic-forge-studio\backend"
py -3.12 -c "from app.validators.architecture_validator import vertical_budget_check, grashof_check; print('OK')"
```

**Step 3: Update kfs-gaps.yaml**

Set GAP-08 status to `closed`.

---

## Task 8: GAP-09 — Create fdm_validator.py

**Files:**
- Create: `backend/app/validators/fdm_validator.py`

**Step 1: Create the validator**

```python
"""FDM Ground Truth validator — identifies critical fits, recommends test prints."""

from __future__ import annotations


# Keywords that suggest critical fit interfaces
_SHAFT_KEYWORDS = {"shaft", "axle", "spindle", "pin", "dowel"}
_BEARING_KEYWORDS = {"bearing", "bushing", "sleeve", "journal"}
_PRESS_KEYWORDS = {"press", "interference", "tight"}
_GEAR_KEYWORDS = {"gear", "pinion", "spur", "helical", "mesh"}


def identify_critical_fits(components: list[dict]) -> list[dict]:
    """Identify component pairs that have critical fit interfaces."""
    critical_fits = []

    for comp in components:
        comp_id = comp.get("id", "")
        comp_type = comp.get("type", comp.get("component_type", "")).lower()
        params = comp.get("parameters", {})
        display = comp.get("display_name", comp_id).lower()

        # Check for shaft/bearing fits
        if any(kw in display or kw in comp_type for kw in _SHAFT_KEYWORDS):
            critical_fits.append({
                "component": comp_id,
                "fit_type": "shaft",
                "diameter": params.get("diameter", params.get("shaft_diameter", "unknown")),
                "recommendation": "Test coupon: cylinder at specified diameter ± 0.05mm increments",
            })

        if any(kw in display or kw in comp_type for kw in _BEARING_KEYWORDS):
            critical_fits.append({
                "component": comp_id,
                "fit_type": "bearing_seat",
                "bore": params.get("bore", params.get("inner_diameter", "unknown")),
                "od": params.get("od", params.get("outer_diameter", "unknown")),
                "recommendation": "Test coupon: bore at spec ± 0.05mm, OD pocket at spec ± 0.05mm",
            })

        if any(kw in display or kw in comp_type for kw in _GEAR_KEYWORDS):
            critical_fits.append({
                "component": comp_id,
                "fit_type": "gear_mesh",
                "module": params.get("module", "unknown"),
                "teeth": params.get("teeth", params.get("num_teeth", "unknown")),
                "recommendation": "Test coupon: 3-tooth gear segment, verify mesh with mating gear",
            })

    return critical_fits


def generate_test_coupons(critical_fits: list[dict]) -> list[dict]:
    """Generate test coupon specifications from critical fit list."""
    coupons = []

    for fit in critical_fits:
        fit_type = fit.get("fit_type", "unknown")

        if fit_type == "shaft":
            diameter = fit.get("diameter", 0)
            if diameter and diameter != "unknown":
                d = float(diameter)
                coupons.append({
                    "name": f"shaft_test_{fit['component']}",
                    "type": "cylinder_array",
                    "description": f"5 cylinders: {d-0.1:.2f}, {d-0.05:.2f}, {d:.2f}, {d+0.05:.2f}, {d+0.1:.2f}mm",
                    "print_time_est": "15 min",
                    "purpose": "Find actual clearance for your printer",
                })

        elif fit_type == "bearing_seat":
            bore = fit.get("bore", 0)
            if bore and bore != "unknown":
                b = float(bore)
                coupons.append({
                    "name": f"bearing_test_{fit['component']}",
                    "type": "bore_array",
                    "description": f"5 bores: {b-0.1:.2f}, {b-0.05:.2f}, {b:.2f}, {b+0.05:.2f}, {b+0.1:.2f}mm",
                    "print_time_est": "20 min",
                    "purpose": "Find press-fit vs slip-fit threshold for your printer",
                })

        elif fit_type == "gear_mesh":
            coupons.append({
                "name": f"gear_test_{fit['component']}",
                "type": "gear_segment",
                "description": f"3-tooth segment, module={fit.get('module', '?')}",
                "print_time_est": "10 min",
                "purpose": "Verify tooth profile prints cleanly and meshes smoothly",
            })

    return coupons
```

**Step 2: Verify import**

```bash
py -3.12 -c "from app.validators.fdm_validator import identify_critical_fits; print('OK')"
```

**Step 3: Update kfs-gaps.yaml**

Set GAP-09 status to `closed`.

---

## Task 9: GAP-10 — Add Missing Component Geometry Types

**Files:**
- Modify: `backend/app/utils/geometry.py:24-58`

**Step 1: Add sphere, cone, torus, custom cases**

After the existing `"rack"` case in `component_to_geometry()`, add:

```python
elif comp_type == "sphere":
    radius = float(params.get("radius", 10))
    return engine.generate_sphere(name=comp_id, radius=radius)

elif comp_type == "cone":
    radius = float(params.get("radius", 10))
    height = float(params.get("height", 20))
    top_radius = float(params.get("top_radius", 0))
    return engine.generate_cone(name=comp_id, radius=radius, height=height, top_radius=top_radius)

elif comp_type == "torus":
    major_radius = float(params.get("major_radius", 20))
    minor_radius = float(params.get("minor_radius", 5))
    return engine.generate_torus(name=comp_id, major_radius=major_radius, minor_radius=minor_radius)

elif comp_type == "custom":
    mesh_path = params.get("mesh_path", "")
    if mesh_path and Path(mesh_path).exists():
        return engine.load_mesh(name=comp_id, path=Path(mesh_path))
    return None
```

**Step 2: Add generate methods to GeometryEngine if missing**

Check `backend/app/engines/geometry_engine.py` for `generate_sphere`, `generate_cone`, `generate_torus`, `load_mesh`. If missing, add them using CadQuery:

```python
def generate_sphere(self, name: str, radius: float) -> GeometryResult:
    """Generate a sphere."""
    import cadquery as cq
    result = cq.Workplane("XY").sphere(radius)
    return self._export_result(result, name)

def generate_cone(self, name: str, radius: float, height: float, top_radius: float = 0) -> GeometryResult:
    """Generate a cone/frustum."""
    import cadquery as cq
    result = cq.Workplane("XY").add(
        cq.Solid.makeCone(radius, top_radius, height)
    )
    return self._export_result(result, name)

def generate_torus(self, name: str, major_radius: float, minor_radius: float) -> GeometryResult:
    """Generate a torus."""
    import cadquery as cq
    result = cq.Workplane("XY").add(
        cq.Solid.makeTorus(major_radius, minor_radius)
    )
    return self._export_result(result, name)
```

**Step 3: Add `from pathlib import Path` to geometry.py if missing**

**Step 4: Verify**

Register a sphere component via API, then GET viewport data, confirm geometry is returned.

**Step 5: Update kfs-gaps.yaml**

Set GAP-10 status to `closed`.

---

## Task 10: GAP-11 — Move ntfy.sh Topic to Config

**Files:**
- Modify: `backend/app/config.py`
- Modify: `backend/app/utils/notify.py:12`

**Step 1: Add ntfy_topic to config.py**

After `cors_origins` (line 30):

```python
ntfy_topic: str = "bussabtheakhaijanab1851421"  # env: KFS_NTFY_TOPIC
```

**Step 2: Update notify.py to use config**

Replace lines 12-13:

```python
from app.config import settings

NTFY_TOPIC = settings.ntfy_topic
NTFY_URL = f"https://ntfy.sh/{NTFY_TOPIC}"
```

**Step 3: Verify**

```bash
cd "D:\Claude local\kinetic-forge-studio\backend"
py -3.12 -c "from app.config import settings; print(settings.ntfy_topic)"
```

Should print the topic string.

**Step 4: Update kfs-gaps.yaml**

Set GAP-11 status to `closed`.

---

## Task 11: GAP-12 — Delete Dead claude_client.py

**Files:**
- Delete: `backend/app/ai/claude_client.py`

**Step 1: Verify no imports reference it**

```bash
cd "D:\Claude local\kinetic-forge-studio\backend"
py -3.12 -c "import ast, pathlib; [print(f) for f in pathlib.Path('app').rglob('*.py') if 'claude_client' in f.read_text()]"
```

Should return empty (no files import it).

**Step 2: Delete the file**

```bash
del "D:\Claude local\kinetic-forge-studio\backend\app\ai\claude_client.py"
```

**Step 3: Verify app still starts**

```bash
py -3.12 -c "from app.main import app; print('OK')"
```

**Step 4: Update kfs-gaps.yaml**

Set GAP-12 status to `closed`.

---

## Task 12: Final — Update All Tracking Files

**Files:**
- Update: `memory/projects/kfs-gaps.yaml` (all statuses)
- Update: `memory/projects/kinetic-forge-studio.yaml` (current_focus, last_session)
- Create: `memory/sessions/2026-03-03.md` (session handoff)
- Update: `memory/decisions.md` (if any new decisions)

**Step 1: Update kfs-gaps.yaml**

Set all closed gaps to verified after running their verify commands.
Update `total`, `closed`, `verified` counts at top.

**Step 2: Update kinetic-forge-studio.yaml**

```yaml
current_focus: "All 12 gaps closed — ready for end-to-end integration test"
last_session: "2026-03-03 — Gap closure sprint"
```

**Step 3: Write session handoff**

Create `memory/sessions/2026-03-03.md` from template with all changes documented.

---

## Execution Notes

- Tasks 1-3 are the highest impact (Claude provider + scad intake + consultant context)
- Tasks 4-6 improve the Rule 500 pipeline
- Tasks 7-9 add missing validators/geometry
- Tasks 10-11 are trivial cleanup
- Task 12 is the mandatory session-end tracking update
- Each task should be committed individually after verification
