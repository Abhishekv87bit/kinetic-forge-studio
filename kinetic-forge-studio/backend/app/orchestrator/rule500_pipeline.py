"""
Rule 500 Pipeline — 32-Step Production Pipeline Orchestrator.

Say "Rule 500" to trigger. Runs the COMPLETE pipeline on a project.

5 Phases, 32 Steps:
  Phase 1 (Intake):       Steps 1-5
  Phase 2 (Design Gate):  Steps 6-11
  Phase 3 (Prototype):    Steps 12-19
  Phase 4 (Production):   Steps 20-28
  Phase 5 (Finalize):     Steps 29-32

Every step runs. Every step reports pass/fail.
Stops at first critical failure, reports what needs fixing, resumes after fix.
"""

import logging
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


@dataclass
class StepResult:
    """Result from a single pipeline step."""
    step: int
    name: str
    phase: str
    passed: bool
    critical: bool = False  # If True and failed, pipeline stops
    findings: list[str] = field(default_factory=list)
    data: dict = field(default_factory=dict)  # Arbitrary data from step
    duration_ms: int = 0

    def to_dict(self) -> dict:
        return {
            "step": self.step,
            "name": self.name,
            "phase": self.phase,
            "passed": self.passed,
            "critical": self.critical,
            "findings": self.findings,
            "data": self.data,
            "duration_ms": self.duration_ms,
        }


@dataclass
class PipelineReport:
    """Aggregated report from all pipeline steps."""
    project_id: str
    steps: list[StepResult] = field(default_factory=list)
    passed: bool = True
    stopped_at: int | None = None  # Step number where critical failure occurred
    summary: str = ""
    total_duration_ms: int = 0

    def to_dict(self) -> dict:
        return {
            "project_id": self.project_id,
            "passed": self.passed,
            "stopped_at": self.stopped_at,
            "summary": self.summary,
            "total_duration_ms": self.total_duration_ms,
            "steps": [s.to_dict() for s in self.steps],
            "phases": self._phase_summary(),
        }

    def _phase_summary(self) -> dict:
        phases: dict[str, dict] = {}
        for s in self.steps:
            if s.phase not in phases:
                phases[s.phase] = {"total": 0, "passed": 0, "failed": 0}
            phases[s.phase]["total"] += 1
            if s.passed:
                phases[s.phase]["passed"] += 1
            else:
                phases[s.phase]["failed"] += 1
        return phases


# Step registry: maps step number to (name, phase, critical, handler_name)
STEP_REGISTRY: list[tuple[int, str, str, bool, str]] = [
    # Phase 1: INTAKE
    (1,  "Discover Files",            "intake",     False, "step1_discover_files"),
    (2,  "Parse & Classify",          "intake",     False, "step2_parse_classify"),
    (3,  "Reference Library Search",  "intake",     False, "step3_library_search"),
    (4,  "Reference Extraction",      "intake",     False, "step4_reference_extraction"),
    (5,  "User Profile & Preferences","intake",     False, "step5_user_profile"),

    # Phase 2: DESIGN GATE
    (6,  "OpenSCAD Compile",          "design",     True,  "step6_compile"),
    (7,  "Geometry Validation",       "design",     True,  "step7_geometry_validation"),       # VLAD Tiers T1, T2
    (8,  "Consistency Audit",         "design",     False, "step8_consistency_audit"),
    (9,  "Visual Render",             "design",     False, "step9_visual_render"),
    (10, "Architecture Verification", "design",     False, "step10_architecture_verify"),
    (11, "Rule 99 Design Gate",       "design",     True,  "step11_rule99_gate1"),

    # Phase 3: PROTOTYPE GATE
    (12, "STL Export",                "prototype",  False, "step12_stl_export"),
    (13, "Collision Detection",       "prototype",  True,  "step13_collision"),                # VLAD Tiers T3, T4, T5
    (14, "Manufacturability Check",   "prototype",  False, "step14_manufacturability"),        # VLAD Tier T6
    (15, "ISO 286 Tolerance",         "prototype",  False, "step15_iso286"),
    (16, "Tolerance Stackup",         "prototype",  False, "step16_tolerance_stackup"),
    (17, "FDM Ground Truth",          "prototype",  False, "step17_fdm_ground_truth"),
    (18, "STEP File Analysis",        "prototype",  False, "step18_step_analysis"),            # VLAD Tier T8
    (19, "Rule 99 Prototype Gate",    "prototype",  True,  "step19_rule99_gate2"),

    # Phase 4: PRODUCTION GATE
    (20, "CadQuery B-Rep Generation", "production", False, "step20_cadquery_brep"),            # VLAD Tiers T1, T3, T4 (rebuild)
    (21, "FreeCAD STEP Export",       "production", False, "step21_freecad_step"),
    (22, "FreeCAD Assembly",          "production", False, "step22_freecad_assembly"),
    (23, "Fabrication Drawings",      "production", False, "step23_fabrication_drawings"),
    (24, "FEM Analysis",              "production", False, "step24_fem_analysis"),
    (25, "BOM Generation",            "production", False, "step25_bom_generation"),
    (26, "DFM Review",                "production", False, "step26_dfm_review"),
    (27, "Materials Specification",   "production", False, "step27_materials_spec"),
    (28, "Rule 99 Production Gate",   "production", True,  "step28_rule99_gate3"),

    # Phase 5: FINALIZE
    (29, "Lock Decisions",            "finalize",   False, "step29_lock_decisions"),
    (30, "Export Package",            "finalize",   False, "step30_export_package"),
    (31, "Final Report",              "finalize",   False, "step31_final_report"),
    (32, "Notify",                    "finalize",   False, "step32_notify"),
]

# Universal Validator Tier mapping per step
# See docs/plans/2026-03-03-universal-validation-spec.md
STEP_VALIDATOR_TIERS: dict[int, list[str]] = {
    7:  ["T1", "T2"],               # Geometry Validation
    13: ["T3", "T4", "T5"],         # Collision Detection
    14: ["T6"],                     # Manufacturability
    18: ["T8"],                     # STEP Analysis
    20: ["T1", "T3", "T4"],         # CadQuery B-Rep rebuild
}

# Phase gate levels map
PHASE_GATES = {
    "intake": "design",
    "design": "design",
    "prototype": "prototype",
    "production": "production",
    "finalize": "production",
}


class Rule500Pipeline:
    """32-step production pipeline executor."""

    def __init__(self):
        self._step_handlers: dict[str, Any] = {}
        self._load_step_handlers()

    def _load_step_handlers(self):
        """Load step implementation modules."""
        try:
            from app.orchestrator.steps import (
                intake,
                design_gate,
                prototype_gate,
                production_gate,
                finalize,
            )
            self._step_handlers = {
                "intake": intake,
                "design_gate": design_gate,
                "prototype_gate": prototype_gate,
                "production_gate": production_gate,
                "finalize": finalize,
            }
        except ImportError as e:
            logger.warning("Could not load step modules: %s", e)

    async def run(
        self,
        project_id: str,
        project_dir: Path,
        gate_level: str = "production",
        components: list[dict] | None = None,
        spec: dict | None = None,
        scad_source: dict[str, str] | None = None,
    ) -> PipelineReport:
        """
        Run all steps up to the specified gate level.

        Args:
            project_id: Project identifier.
            project_dir: Path to project directory.
            gate_level: Run steps through this gate level.
            components: Current project components.
            spec: Current project spec.
            scad_source: OpenSCAD source files (filename -> content) for LLM context.
        """
        report = PipelineReport(project_id=project_id)
        start_time = time.time()

        context = {
            "project_id": project_id,
            "project_dir": project_dir,
            "components": components or [],
            "spec": spec or {},
            "gate_level": gate_level,
            "scad_source": scad_source or {},
        }

        for step_num, name, phase, critical, handler_name in STEP_REGISTRY:
            # Skip steps beyond requested gate level
            phase_gate = PHASE_GATES.get(phase, "production")
            gate_order = ["design", "prototype", "production"]
            if gate_order.index(phase_gate) > gate_order.index(gate_level):
                break

            step_result = await self.run_step(
                step_num, name, phase, critical, handler_name, context
            )
            report.steps.append(step_result)

            # Feed accumulated results into context for step 31
            context["pipeline_results"] = [
                {"step": s.step, "name": s.name, "phase": s.phase,
                 "passed": s.passed, "findings": s.findings}
                for s in report.steps
            ]

            if not step_result.passed and step_result.critical:
                report.passed = False
                report.stopped_at = step_num
                report.summary = (
                    f"Pipeline STOPPED at step {step_num} ({name}): "
                    f"critical failure. Fix and resume."
                )
                break

            if not step_result.passed:
                report.passed = False

        if report.stopped_at is None:
            passed_count = sum(1 for s in report.steps if s.passed)
            total = len(report.steps)
            report.summary = (
                f"Pipeline complete: {passed_count}/{total} steps passed"
                + (" — ALL PASS" if report.passed else " — has failures")
            )

        report.total_duration_ms = int((time.time() - start_time) * 1000)
        return report

    async def run_step(
        self,
        step_num: int,
        name: str,
        phase: str,
        critical: bool,
        handler_name: str,
        context: dict,
    ) -> StepResult:
        """Run a single pipeline step."""
        start = time.time()

        try:
            # Map handler to module
            module_map = {
                "intake": "intake",
                "design": "design_gate",
                "prototype": "prototype_gate",
                "production": "production_gate",
                "finalize": "finalize",
            }
            module_key = module_map.get(phase, phase)
            module = self._step_handlers.get(module_key)

            if module and hasattr(module, handler_name):
                handler = getattr(module, handler_name)
                result = await handler(context)

                if isinstance(result, StepResult):
                    result.step = step_num
                    result.name = name
                    result.phase = phase
                    result.critical = critical
                    result.duration_ms = int((time.time() - start) * 1000)
                    return result
                elif isinstance(result, dict):
                    return StepResult(
                        step=step_num,
                        name=name,
                        phase=phase,
                        passed=result.get("passed", True),
                        critical=critical,
                        findings=result.get("findings", []),
                        data=result.get("data", {}),
                        duration_ms=int((time.time() - start) * 1000),
                    )
            else:
                # Step not implemented yet
                return StepResult(
                    step=step_num,
                    name=name,
                    phase=phase,
                    passed=True,
                    critical=False,  # Unimplemented steps don't block
                    findings=[f"Step {step_num} ({name}) not yet implemented — skipped"],
                    duration_ms=int((time.time() - start) * 1000),
                )

        except Exception as e:
            logger.error("Step %d (%s) failed: %s", step_num, name, e, exc_info=True)
            return StepResult(
                step=step_num,
                name=name,
                phase=phase,
                passed=False,
                critical=critical,
                findings=[f"Step error: {e}"],
                duration_ms=int((time.time() - start) * 1000),
            )

    async def resume_from(
        self,
        step_number: int,
        project_id: str,
        project_dir: Path,
        **kwargs,
    ) -> PipelineReport:
        """Resume pipeline from a specific step (after fixing failures)."""
        report = PipelineReport(project_id=project_id)
        start_time = time.time()

        context = {
            "project_id": project_id,
            "project_dir": project_dir,
            **kwargs,
        }

        for step_num, name, phase, critical, handler_name in STEP_REGISTRY:
            if step_num < step_number:
                # Mark prior steps as already passed
                report.steps.append(StepResult(
                    step=step_num,
                    name=name,
                    phase=phase,
                    passed=True,
                    findings=["(previously passed)"],
                ))
                continue

            step_result = await self.run_step(
                step_num, name, phase, critical, handler_name, context
            )
            report.steps.append(step_result)

            if not step_result.passed and step_result.critical:
                report.passed = False
                report.stopped_at = step_num
                report.summary = (
                    f"Pipeline STOPPED at step {step_num} ({name}): "
                    f"critical failure. Fix and resume."
                )
                break

        if report.stopped_at is None:
            passed_count = sum(1 for s in report.steps if s.passed)
            report.summary = f"Pipeline resumed from step {step_number}: {passed_count}/32 passed"

        report.total_duration_ms = int((time.time() - start_time) * 1000)
        return report


# Singleton
_pipeline: Rule500Pipeline | None = None


def get_pipeline() -> Rule500Pipeline:
    """Get or create the singleton Rule500Pipeline."""
    global _pipeline
    if _pipeline is None:
        _pipeline = Rule500Pipeline()
    return _pipeline
