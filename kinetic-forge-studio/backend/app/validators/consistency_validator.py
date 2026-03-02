"""
Consistency validator -- wraps production_pipeline/consistency_audit.py.

Detects drift between .scad files, config, and docs.
Called after ANY change to .scad files.
"""

import asyncio
import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

from app.config import settings

logger = logging.getLogger(__name__)


@dataclass
class ConsistencyResult:
    """Result of consistency audit."""
    passed: bool
    drift_items: list[dict] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)


async def audit(project_dir: Path) -> ConsistencyResult:
    """
    Run consistency audit on a project directory.

    Checks for drift between .scad, config, and docs.
    """
    result = ConsistencyResult(passed=True)
    script = settings.consistency_audit_script

    if not script.exists():
        result.warnings.append(
            f"consistency_audit.py not found at {script}; skipping. "
            f"Set KFS_PIPELINE_DIR to configure."
        )
        return result

    try:
        proc = await asyncio.create_subprocess_exec(
            "python", str(script), str(project_dir),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=60)
        stdout_text = stdout.decode("utf-8", errors="replace")

        try:
            data = json.loads(stdout_text)
            result.drift_items = data.get("drift", [])
            result.warnings = data.get("warnings", [])
            result.passed = len(result.drift_items) == 0
        except json.JSONDecodeError:
            result.passed = proc.returncode == 0
            if not result.passed:
                result.errors.append(f"Audit failed: {stdout_text[:300]}")

    except asyncio.TimeoutError:
        result.errors.append("consistency_audit.py timed out after 60s")
        result.passed = False
    except Exception as e:
        result.errors.append(f"consistency_audit.py error: {e}")
        result.passed = False

    return result
