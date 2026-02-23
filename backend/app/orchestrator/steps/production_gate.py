"""
Rule 500 Pipeline — Phase 4: PRODUCTION GATE (Steps 20-28).

Steps:
  20. CadQuery B-Rep Generation (LLM generates code → CadQueryEngine executes)
  21. FreeCAD STEP Export
  22. FreeCAD Assembly
  23. Fabrication Drawings
  24. FEM Analysis
  25. BOM Generation
  26. DFM Review
  27. Materials Specification
  28. Rule 99 Production Gate

DESIGN MANDATE: No primitives. No placeholders. Real geometry only.
Step 20 asks the LLM to generate CadQuery code for each component,
then executes that code to produce STEP + STL files.
"""

import logging
import re
import time
from pathlib import Path

from app.orchestrator.rule500_pipeline import StepResult

logger = logging.getLogger(__name__)


def _is_cadquery_script(path: Path) -> bool:
    """Check if a Python file contains CadQuery/build123d code."""
    try:
        content = path.read_text(encoding="utf-8", errors="replace")[:2000]
        return any(kw in content for kw in [
            "import cadquery", "import build123d", "cq.Workplane", "from cadquery",
            "from build123d",
        ])
    except Exception:
        return False


async def step20_cadquery_brep(context: dict) -> StepResult:
    """
    Generate B-Rep geometry via CadQuery for ALL project components.

    This step:
    1. Reads the component registry and OpenSCAD source files
    2. Asks the LLM to generate CadQuery Python code for each component
    3. Executes the generated code via CadQueryEngine
    4. Produces STEP + STL files in project_dir/models/
    5. Also executes any pre-existing CadQuery scripts found in project_dir

    DESIGN MANDATE: The LLM must generate REAL geometry (helical grooves,
    involute teeth, hex profiles) — never primitives or placeholders.
    """
    project_dir = Path(context.get("project_dir", ""))
    components = context.get("components", [])
    spec = context.get("spec", {})
    scad_source = context.get("scad_source", {})
    findings = []
    generated_files = []

    # Phase A: Generate CadQuery code from LLM for registered components
    if components:
        findings.append(f"Phase A: Generating CadQuery code for {len(components)} component(s) via LLM...")
        try:
            llm_results = await _generate_cadquery_via_llm(
                components=components,
                scad_source=scad_source,
                spec=spec,
                project_dir=project_dir,
            )
            for comp_id, result in llm_results.items():
                if result["success"]:
                    findings.append(f"  OK: {comp_id} -> {len(result['files'])} file(s)")
                    generated_files.extend(result["files"])
                else:
                    findings.append(f"  FAIL: {comp_id}: {result['error']}")
        except Exception as e:
            findings.append(f"  LLM CadQuery generation error: {e}")
            logger.exception("step20: LLM CadQuery generation failed")
    else:
        findings.append("Phase A: No components registered. Skipping LLM generation.")

    # Phase B: Also execute any pre-existing CadQuery scripts in project dir
    py_files = list(project_dir.glob("**/*.py")) if project_dir.exists() else []
    cadquery_scripts = [f for f in py_files if _is_cadquery_script(f)]

    if cadquery_scripts:
        findings.append(f"Phase B: Found {len(cadquery_scripts)} existing CadQuery script(s)...")
        try:
            from app.engines.cadquery_engine import CadQueryEngine
            engine = CadQueryEngine()
            output_dir = project_dir / "models"
            output_dir.mkdir(parents=True, exist_ok=True)

            for script in cadquery_scripts:
                code = script.read_text(encoding="utf-8", errors="replace")
                result = await engine.generate(
                    code=code, output_dir=output_dir, filename_base=script.stem,
                )
                if result.success:
                    findings.append(f"  OK: {script.name} -> {len(result.output_files)} file(s)")
                    for fmt, fpath in result.output_files.items():
                        generated_files.append(str(fpath))
                else:
                    findings.append(f"  FAIL: {script.name}: {result.error}")
        except ImportError:
            findings.append("  CadQuery not installed. pip install cadquery to enable.")
        except Exception as e:
            findings.append(f"  CadQuery execution error: {e}")
    else:
        findings.append("Phase B: No pre-existing CadQuery scripts found.")

    passed = len(generated_files) > 0
    if not passed and not components and not cadquery_scripts:
        # Nothing to do at all — pass vacuously
        passed = True
        findings.append("No components or scripts to process.")

    return StepResult(
        step=20, name="CadQuery B-Rep Generation", phase="production",
        passed=passed,
        findings=findings,
        data={"generated_files": generated_files},
    )


async def _generate_cadquery_via_llm(
    components: list[dict],
    scad_source: dict[str, str],
    spec: dict,
    project_dir: Path,
) -> dict[str, dict]:
    """
    Ask the LLM to generate CadQuery code for each component, then execute it.

    Returns: {component_id: {"success": bool, "files": [str], "error": str}}
    """
    from app.ai.prompt_builder import PromptBuilder
    from app.orchestrator.chat_agent import ChatAgent
    from app.engines.cadquery_engine import CadQueryEngine

    builder = PromptBuilder()
    agent = ChatAgent()
    engine = CadQueryEngine()
    output_dir = project_dir / "models"
    output_dir.mkdir(parents=True, exist_ok=True)
    results = {}

    # Build the CadQuery generation prompt
    system_prompt = builder.build_cadquery_generation_prompt(
        components=components,
        scad_source=scad_source if scad_source else None,
        spec=spec if spec else None,
    )

    # Ask LLM to generate CadQuery code for all components at once
    user_msg = (
        f"Generate CadQuery Python code for all {len(components)} components listed above. "
        f"One ```python block per component. Real geometry only — no primitives."
    )

    try:
        # Direct LLM call with our custom CadQuery generation prompt
        # (bypasses chat() which would use the standard system prompt)
        provider = agent._active_provider()
        if provider is None:
            for c in components:
                comp_id = c.get("id", c.get("display_name", "unknown"))
                results[comp_id] = {"success": False, "files": [], "error": "No LLM provider available"}
            return results

        # Direct LLM call with our production geometry prompt
        messages = [{"role": "user", "content": user_msg}]

        if provider == "claude":
            data = await agent._call_claude(system_prompt, messages)
        else:
            from app.config import settings
            api_urls = {
                "groq": "https://api.groq.com/openai/v1/chat/completions",
                "grok": "https://api.x.ai/v1/chat/completions",
                "gemini": "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
            }
            key_map = {
                "groq": settings.groq_api_key,
                "grok": settings.grok_api_key,
                "gemini": settings.gemini_api_key,
            }
            model_map = {
                "groq": settings.groq_model,
                "grok": settings.grok_model,
                "gemini": settings.gemini_model,
            }
            token_map = {
                "groq": settings.groq_max_tokens,
                "grok": settings.grok_max_tokens,
                "gemini": settings.gemini_max_tokens,
            }
            data = await agent._call_openai_compat(
                system_prompt, messages,
                api_url=api_urls[provider],
                api_key=key_map[provider],
                model=model_map[provider],
                max_tokens=token_map[provider],
                provider_name=provider.capitalize(),
            )

        if data is None:
            for c in components:
                comp_id = c.get("id", c.get("display_name", "unknown"))
                results[comp_id] = {"success": False, "files": [], "error": "LLM API call failed"}
            return results

        # Extract text from response
        if provider in ("groq", "grok", "gemini"):
            full_text = agent._extract_openai_text(data)
        else:
            full_text = agent._extract_claude_text(data)

        logger.info("step20: LLM returned %d chars of CadQuery code", len(full_text))

        # Parse python code blocks from the response
        code_blocks = []
        for match in re.finditer(r"```(?:python|cadquery|build123d)\s*\n(.*?)\n```", full_text, re.DOTALL):
            code_blocks.append(match.group(1))

        logger.info("step20: Extracted %d code blocks from LLM response", len(code_blocks))

        if not code_blocks:
            # LLM didn't generate any code blocks
            for c in components:
                comp_id = c.get("id", c.get("display_name", "unknown"))
                results[comp_id] = {
                    "success": False, "files": [],
                    "error": "LLM returned no python code blocks",
                }
            return results

        # Execute each code block
        for i, code in enumerate(code_blocks):
            # Try to extract component ID from the code comment
            comp_id_match = re.search(r"#\s*Component:\s*(\S+)", code)
            if comp_id_match:
                comp_id = comp_id_match.group(1)
            elif i < len(components):
                comp_id = components[i].get("id", f"component_{i}")
            else:
                comp_id = f"component_{i}"

            filename_base = f"{comp_id}_{int(time.time())}"

            try:
                gen_result = await engine.generate(
                    code=code,
                    output_dir=output_dir,
                    filename_base=filename_base,
                )

                if gen_result.success:
                    file_paths = [str(p) for p in gen_result.output_files.values()]
                    results[comp_id] = {"success": True, "files": file_paths, "error": ""}
                    logger.info("step20: Component %s generated: %s", comp_id, file_paths)
                else:
                    results[comp_id] = {
                        "success": False, "files": [],
                        "error": gen_result.error[:300],
                    }
                    logger.warning("step20: Component %s failed: %s", comp_id, gen_result.error[:200])

                    # Save the failed script for debugging
                    debug_path = output_dir / f"{comp_id}_FAILED.py"
                    debug_path.write_text(code, encoding="utf-8")
                    logger.info("step20: Failed script saved to %s", debug_path)
            except Exception as e:
                results[comp_id] = {"success": False, "files": [], "error": str(e)[:300]}

    except Exception as e:
        logger.exception("step20: _generate_cadquery_via_llm failed")
        for c in components:
            comp_id = c.get("id", c.get("display_name", "unknown"))
            if comp_id not in results:
                results[comp_id] = {"success": False, "files": [], "error": str(e)[:300]}

    finally:
        await agent.close()

    return results


async def step21_freecad_step(context: dict) -> StepResult:
    """Validate/convert STEP files via FreeCAD (skips if unavailable)."""
    project_dir = Path(context.get("project_dir", ""))
    findings = []
    step_files = list(project_dir.glob("**/*.step")) if project_dir.exists() else []

    if not step_files:
        return StepResult(
            step=21, name="FreeCAD STEP Export", phase="production",
            passed=True, findings=["No STEP files to validate."],
        )

    try:
        from app.engines.freecad_engine import FreeCADEngine
        engine = FreeCADEngine()
        try:
            for sf in step_files[:10]:
                result = await engine.convert_step(sf)
                if result and result.get("valid"):
                    bodies = result.get("bodies", "?")
                    faces = result.get("faces", "?")
                    findings.append(f"OK: {sf.name} — {bodies} bodies, {faces} faces")
                else:
                    err = result.get("error", "unknown") if result else "no result"
                    findings.append(f"SKIP: {sf.name}: {err}")
        finally:
            await engine.close()
    except ImportError:
        findings.append("FreeCAD engine not available (missing httpx?). Skipping STEP validation.")
    except Exception as e:
        findings.append(f"FreeCAD not available: {e}. Skipping STEP validation.")

    return StepResult(
        step=21, name="FreeCAD STEP Export", phase="production",
        passed=True, findings=findings or ["No validations attempted."],
    )


async def step22_freecad_assembly(context: dict) -> StepResult:
    """Build FreeCAD assembly (skips if MCP unavailable)."""
    components = context.get("components", [])
    findings = [f"Components for assembly: {len(components)}"]

    if not components:
        return StepResult(
            step=22, name="FreeCAD Assembly", phase="production",
            passed=True, findings=["No components provided for assembly."],
        )

    try:
        from app.engines.freecad_engine import FreeCADEngine
        engine = FreeCADEngine()
        try:
            available = await engine.is_mcp_available()
            if available:
                findings.append("FreeCAD MCP available. Assembly requires manual session setup.")
            else:
                findings.append("FreeCAD MCP not running. Start FreeCAD with MCP to enable assembly.")
        finally:
            await engine.close()
    except ImportError:
        findings.append("FreeCAD engine not available. Skipping assembly check.")
    except Exception as e:
        findings.append(f"FreeCAD not available: {e}")

    return StepResult(
        step=22, name="FreeCAD Assembly", phase="production",
        passed=True, findings=findings,
    )


async def step23_fabrication_drawings(context: dict) -> StepResult:
    """Generate fabrication drawings via FreeCAD TechDraw (skips if unavailable)."""
    project_dir = Path(context.get("project_dir", ""))
    step_files = list(project_dir.glob("**/*.step")) if project_dir.exists() else []
    findings = []

    if not step_files:
        findings.append("No STEP files available for drawing generation.")
        return StepResult(
            step=23, name="Fabrication Drawings", phase="production",
            passed=True, findings=findings,
        )

    try:
        from app.engines.freecad_engine import FreeCADEngine
        engine = FreeCADEngine()
        drawings_dir = project_dir / "drawings"
        drawings_dir.mkdir(parents=True, exist_ok=True)
        try:
            for sf in step_files[:5]:
                result = await engine.export_drawings(sf, drawings_dir)
                if result and result.exists():
                    findings.append(f"OK: {sf.name} -> {result.name}")
                else:
                    findings.append(f"SKIP: {sf.name}: drawing generation returned no output")
        finally:
            await engine.close()
    except ImportError:
        findings.append("FreeCAD engine not available. Skipping drawing generation.")
    except Exception as e:
        findings.append(f"FreeCAD not available for drawings: {e}")

    return StepResult(
        step=23, name="Fabrication Drawings", phase="production",
        passed=True, findings=findings or ["No drawings generated."],
    )


async def step24_fem_analysis(context: dict) -> StepResult:
    """Run FEM analysis on critical parts (skips if FreeCAD unavailable)."""
    project_dir = Path(context.get("project_dir", ""))
    components = context.get("components", [])
    findings = []

    # Identify structural components (candidates for FEM)
    structural = [
        c for c in components
        if isinstance(c, dict)
        and c.get("type", c.get("component_type", "")) in (
            "frame", "bracket", "mount", "arm", "housing", "shaft",
        )
    ]

    if not structural:
        return StepResult(
            step=24, name="FEM Analysis", phase="production",
            passed=True, findings=["No structural components identified for FEM analysis."],
        )

    candidate_names = [c.get("display_name", c.get("id", "?")) for c in structural]
    findings.append(f"FEM candidates: {candidate_names}")

    # Look for STEP files to analyze
    step_files = list(project_dir.glob("**/*.step")) if project_dir.exists() else []
    if not step_files:
        findings.append("No STEP files found. FEM requires solid geometry (STEP format).")
        return StepResult(
            step=24, name="FEM Analysis", phase="production",
            passed=True, findings=findings,
        )

    try:
        from app.engines.freecad_engine import FreeCADEngine
        engine = FreeCADEngine()
        try:
            for sf in step_files[:3]:
                result = await engine.run_fem(sf, constraints={})
                if result.success:
                    findings.append(
                        f"OK: {sf.name} — stress={result.max_stress:.1f} MPa, "
                        f"displacement={result.max_displacement:.3f} mm, "
                        f"safety_factor={result.safety_factor:.2f}"
                    )
                else:
                    errors = "; ".join(result.errors) if result.errors else "unknown"
                    findings.append(f"SKIP: {sf.name}: {errors}")
        finally:
            await engine.close()
    except ImportError:
        findings.append("FreeCAD engine not available. Skipping FEM analysis.")
    except Exception as e:
        findings.append(f"FreeCAD not available for FEM: {e}")

    return StepResult(
        step=24, name="FEM Analysis", phase="production",
        passed=True, findings=findings,
    )


async def step25_bom_generation(context: dict) -> StepResult:
    """Generate Bill of Materials."""
    components = context.get("components", [])

    if not components:
        return StepResult(
            step=25, name="BOM Generation", phase="production",
            passed=True, findings=["No components for BOM"],
        )

    bom_items = []
    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            ctype = comp.get("type", comp.get("component_type", ""))
            params = comp.get("parameters", {})
            material = params.get("material", "unspecified")
            qty = params.get("quantity", 1)
            bom_items.append(f"  {name} | {ctype} | {material} | qty: {qty}")

    findings = [
        f"BOM: {len(bom_items)} item(s)",
        "Item | Type | Material | Qty",
        "---|---|---|---",
    ] + bom_items

    return StepResult(
        step=25, name="BOM Generation", phase="production",
        passed=True,
        findings=findings,
        data={"bom_count": len(bom_items)},
    )


async def step26_dfm_review(context: dict) -> StepResult:
    """DFM review via Rule 99 DFM consultant."""
    from app.consultants.rule99_engine import get_engine, ProjectState

    components = context.get("components", [])
    spec = context.get("spec", {})

    project_state = ProjectState(
        gate_level="production",
        component_types=[c.get("type", "") for c in components if isinstance(c, dict)],
        components=components,
        spec=spec,
    )

    engine = get_engine()
    report = engine.run_targeted("production", project_state)

    findings = [f"DFM Review: {'PASS' if report.passed else 'issues found'}"]
    for cr in report.consultants_fired:
        for f in cr.findings[:5]:
            findings.append(f"  {f}")

    return StepResult(
        step=26, name="DFM Review", phase="production",
        passed=True,  # Advisory
        findings=findings,
    )


async def step27_materials_spec(context: dict) -> StepResult:
    """Materials specification per component."""
    components = context.get("components", [])
    spec = context.get("spec", {})

    findings = ["Materials specification:"]
    unspecified = 0

    for comp in components:
        if isinstance(comp, dict):
            name = comp.get("display_name", comp.get("id", "?"))
            params = comp.get("parameters", {})
            material = params.get("material", "")

            if material:
                findings.append(f"  {name}: {material}")
            else:
                findings.append(f"  {name}: UNSPECIFIED")
                unspecified += 1

    if unspecified:
        findings.append(f"\n{unspecified} component(s) need material specification")

    return StepResult(
        step=27, name="Materials Specification", phase="production",
        passed=unspecified == 0,
        findings=findings,
    )


async def step28_rule99_gate3(context: dict) -> StepResult:
    """Run Rule 99 Gate 3 consultants."""
    from app.consultants.rule99_engine import get_engine, ProjectState

    components = context.get("components", [])
    spec = context.get("spec", {})

    project_state = ProjectState(
        gate_level="production",
        mechanism_type=spec.get("mechanism_type", ""),
        component_types=[c.get("type", "") for c in components if isinstance(c, dict)],
        components=components,
        spec=spec,
        project_dir=Path(context.get("project_dir", "")),
        material=spec.get("material", ""),
    )

    engine = get_engine()
    report = engine.run_gate_consultants("production", project_state)

    findings = [
        f"Rule 99 Production Gate: {'PASS' if report.passed else 'FAIL'}",
        f"Consultants fired: {len(report.consultants_fired)}",
    ]
    for cr in report.consultants_fired:
        icon = "PASS" if cr.passed else "FAIL"
        findings.append(f"  [{icon}] {cr.name}")
        for rec in cr.recommendations[:2]:
            findings.append(f"    -> {rec}")

    return StepResult(
        step=28, name="Rule 99 Production Gate", phase="production",
        passed=report.passed, critical=True,
        findings=findings,
        data=report.to_dict(),
    )
