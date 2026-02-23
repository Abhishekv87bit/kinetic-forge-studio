"""
Rule 500 Pipeline — Phase 5: FINALIZE (Steps 29-32).

Steps:
  29. Lock Decisions — record all design decisions
  30. Export Package — ZIP bundle
  31. Final Report — summary of all 32 steps
  32. Notify — send ntfy.sh notification
"""

import logging
from pathlib import Path

from app.orchestrator.rule500_pipeline import StepResult

logger = logging.getLogger(__name__)


async def step29_lock_decisions(context: dict) -> StepResult:
    """Record all design decisions in project decisions log."""
    spec = context.get("spec", {})

    decisions = []
    for key, value in spec.items():
        if value is not None and value != "":
            decisions.append(f"  {key} = {value}")

    findings = [
        f"Locking {len(decisions)} design decisions",
    ] + decisions[:20]

    if len(decisions) > 20:
        findings.append(f"  ... +{len(decisions) - 20} more")

    return StepResult(
        step=29, name="Lock Decisions", phase="finalize",
        passed=True, findings=findings,
    )


async def step30_export_package(context: dict) -> StepResult:
    """Inventory export package contents."""
    project_dir = Path(context.get("project_dir", ""))
    findings = []
    file_counts = {}

    if project_dir.exists():
        for ext in [".scad", ".stl", ".step", ".png", ".py", ".json"]:
            count = len(list(project_dir.glob(f"**/*{ext}")))
            if count:
                file_counts[ext] = count
                findings.append(f"  {ext}: {count} files")

    components = context.get("components", [])
    if file_counts:
        findings.insert(0, "Project directory contents:")
    else:
        findings.append("No project files found.")

    findings.append(f"Components in registry: {len(components)}")
    findings.append("Export available at GET /api/export/{project_id}")

    return StepResult(
        step=30, name="Export Package", phase="finalize",
        passed=True, findings=findings,
        data={"file_counts": file_counts, "component_count": len(components)},
    )


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
        status = "PASS" if r.get("passed") else "FAIL"
        findings.append(f"  [{status}] Step {step_num}: {name}")

    if not pipeline_results:
        findings.append("  (no pipeline_results in context — wire run() to inject them)")

    return StepResult(
        step=31, name="Final Report", phase="finalize",
        passed=failed == 0,
        findings=findings,
        data={"total": total, "passed": passed, "failed": failed},
    )


async def step32_notify(context: dict) -> StepResult:
    """Send ntfy.sh notification."""
    project_id = context.get("project_id", "unknown")

    try:
        from app.utils.notify import notify
        await notify(
            message=f"Rule 500 complete: {project_id}",
            priority="default",
            tags=["white_check_mark"],
        )
        return StepResult(
            step=32, name="Notify", phase="finalize",
            passed=True,
            findings=["Notification sent via ntfy.sh"],
        )
    except Exception as e:
        return StepResult(
            step=32, name="Notify", phase="finalize",
            passed=True,  # Notification failure is not critical
            findings=[f"Notification skipped: {e}"],
        )
