import asyncio
import json
import tempfile
import time
from pathlib import Path

from pydantic import BaseModel

from app.config import settings


class ExecutionResult(BaseModel):
    success: bool
    files_written: list[str] = []
    stdout: str = ""
    stderr: str = ""
    duration_ms: float = 0.0
    error: str | None = None


async def execute_module(
    project_id: str,
    module_id: str,
    source_code: str,
    parameters: dict,
    output_dir: Path,
) -> ExecutionResult:
    output_dir.mkdir(parents=True, exist_ok=True)

    params_json = json.dumps(parameters)
    wrapper = (
        f"import os, sys\n"
        f"os.chdir({str(output_dir)!r})\n"
        f"_PARAMS = {params_json}\n"
        f"{source_code}\n"
    )

    tmp_fd = tempfile.NamedTemporaryFile(suffix=".py", delete=False, mode="w", encoding="utf-8")
    tmp = Path(tmp_fd.name)
    tmp_fd.write(wrapper)
    tmp_fd.close()

    start = time.monotonic()
    try:
        proc = await asyncio.create_subprocess_exec(
            "python",
            str(tmp),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=str(output_dir),
        )
        stdout_b, stderr_b = await asyncio.wait_for(proc.communicate(), timeout=120)
    except asyncio.TimeoutError:
        proc.kill()
        return ExecutionResult(
            success=False,
            error="Execution timed out after 120s",
            duration_ms=(time.monotonic() - start) * 1000,
        )
    except Exception as exc:
        return ExecutionResult(
            success=False,
            error=str(exc),
            duration_ms=(time.monotonic() - start) * 1000,
        )
    finally:
        tmp.unlink(missing_ok=True)

    duration_ms = (time.monotonic() - start) * 1000
    stdout = stdout_b.decode(errors="replace")
    stderr = stderr_b.decode(errors="replace")

    if proc.returncode != 0:
        return ExecutionResult(
            success=False,
            stdout=stdout,
            stderr=stderr,
            duration_ms=duration_ms,
            error=f"Process exited with code {proc.returncode}",
        )

    files_written = [
        str(p) for p in output_dir.iterdir()
        if p.suffix.lower() in (".stl", ".step", ".stp")
    ]

    return ExecutionResult(
        success=True,
        files_written=files_written,
        stdout=stdout,
        stderr=stderr,
        duration_ms=duration_ms,
    )
