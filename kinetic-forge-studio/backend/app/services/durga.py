from pathlib import Path

from pydantic import BaseModel

from app.services.module_executor import ExecutionResult, execute_module
from app.services.durga_rules import get_repair


class DurgaResult(BaseModel):
    success: bool
    files_written: list[str] = []
    stdout: str = ""
    stderr: str = ""
    duration_ms: float = 0.0
    error: str | None = None
    attempts: int = 0
    repairs_applied: list[str] = []


async def execute_with_repair(
    project_id: str,
    module_id: str,
    source_code: str,
    parameters: dict,
    output_dir: Path,
    max_attempts: int = 3,
) -> DurgaResult:
    repairs_applied: list[str] = []
    current_code = source_code
    last_result: ExecutionResult | None = None

    for attempt in range(1, max_attempts + 1):
        result = await execute_module(
            project_id, module_id, current_code, parameters, output_dir
        )
        last_result = result

        if result.success:
            return DurgaResult(
                success=True,
                files_written=result.files_written,
                stdout=result.stdout,
                stderr=result.stderr,
                duration_ms=result.duration_ms,
                attempts=attempt,
                repairs_applied=repairs_applied,
            )

        if attempt >= max_attempts:
            break

        error_text = f"{result.error or ''}\n{result.stderr}"

        # Deterministic repair
        patched = get_repair(error_text, current_code)
        if patched is not None:
            repairs_applied.append(f"attempt {attempt}: deterministic rule applied")
            current_code = patched
            continue

        # LLM-assisted repair (not yet implemented)
        repairs_applied.append(f"attempt {attempt}: no rule matched, LLM repair stubbed")
        break

    return DurgaResult(
        success=False,
        files_written=last_result.files_written if last_result else [],
        stdout=last_result.stdout if last_result else "",
        stderr=last_result.stderr if last_result else "",
        duration_ms=last_result.duration_ms if last_result else 0.0,
        error=last_result.error if last_result else "Unknown error",
        attempts=min(max_attempts, len(repairs_applied) + 1),
        repairs_applied=repairs_applied,
    )
