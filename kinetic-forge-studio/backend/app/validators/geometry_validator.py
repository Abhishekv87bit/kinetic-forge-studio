"""
Geometry validator -- wraps production_pipeline/validate_geometry.py.

Runs compile checks and constraint validation on OpenSCAD files.
Called by GateEnforcer for OpenSCAD-based designs.
"""

import asyncio
import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

from app.config import settings

logger = logging.getLogger(__name__)


@dataclass
class GeometryValidationResult:
    """Result of geometry validation."""
    passed: bool
    compile_ok: bool = False
    constraint_checks: list[dict] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    render_path: Path | None = None


async def compile_check(scad_path: Path) -> tuple[bool, str]:
    """
    Run OpenSCAD compile check (zero errors, zero warnings).

    Returns (passed, error_text).
    """
    openscad = settings.openscad_path
    lib_path = settings.openscad_lib_path

    import os
    env = os.environ.copy()
    env["OPENSCADPATH"] = lib_path

    csg_path = scad_path.with_suffix(".csg")
    try:
        proc = await asyncio.create_subprocess_exec(
            openscad, "--backend=manifold",
            "-o", str(csg_path),
            str(scad_path),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
        )
        _, stderr = await asyncio.wait_for(proc.communicate(), timeout=120)
        stderr_text = stderr.decode("utf-8", errors="replace")
    except asyncio.TimeoutError:
        return False, "OpenSCAD compile timed out after 120s"
    except FileNotFoundError:
        return False, f"OpenSCAD not found at: {openscad}"
    except Exception as e:
        return False, f"Compile error: {e}"
    finally:
        csg_path.unlink(missing_ok=True)

    passed = proc.returncode == 0 and "WARNING" not in stderr_text and "ERROR" not in stderr_text
    return passed, stderr_text


async def validate(scad_path: Path, config_path: Path | None = None) -> GeometryValidationResult:
    """
    Run full geometry validation on an OpenSCAD file.

    Steps:
    1. Compile check (openscad -o test.csg)
    2. Constraint validation (validate_geometry.py) if available
    """
    result = GeometryValidationResult(passed=False)

    # Step 1: Compile check
    compile_ok, compile_errors = await compile_check(scad_path)
    result.compile_ok = compile_ok
    if not compile_ok:
        result.errors.append(f"Compile failed: {compile_errors[:500]}")
        return result

    # Step 2: Run validate_geometry.py if available
    script = settings.validate_geometry_script
    if script.exists():
        try:
            args = ["python", str(script), str(scad_path)]
            if config_path and config_path.exists():
                args.extend(["--config", str(config_path)])
            args.append("--json")

            proc = await asyncio.create_subprocess_exec(
                *args,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=60)
            stdout_text = stdout.decode("utf-8", errors="replace")

            try:
                data = json.loads(stdout_text)
                result.constraint_checks = data.get("checks", [])
                result.warnings = data.get("warnings", [])
                failed = [c for c in result.constraint_checks if not c.get("passed", True)]
                result.passed = compile_ok and len(failed) == 0
            except json.JSONDecodeError:
                result.warnings.append("validate_geometry.py output not JSON-parseable")
                result.passed = compile_ok and proc.returncode == 0

        except asyncio.TimeoutError:
            result.errors.append("validate_geometry.py timed out after 60s")
        except Exception as e:
            result.errors.append(f"validate_geometry.py error: {e}")
    else:
        # No validation script — compile check is sufficient
        result.passed = compile_ok
        result.warnings.append(
            f"validate_geometry.py not found at {script}; compile-only check. "
            f"Set KFS_PIPELINE_DIR to configure."
        )

    return result
