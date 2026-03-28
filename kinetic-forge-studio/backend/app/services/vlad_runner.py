import asyncio
import json
import secrets
from datetime import datetime, timezone
from pathlib import Path

from pydantic import BaseModel

from app.config import settings
from app.db.database import Database


class VladResult(BaseModel):
    tier: str = ""
    passed: bool = False
    checks_run: list[str] = []
    checks_passed: list[str] = []
    checks_failed: list[str] = []
    findings: list[str] = []


_VLAD_SCRIPT = settings.pipeline_dir / "tools" / "vlad.py"


async def run_vlad(
    module_id: str,
    file_path: Path,
    db: Database,
    version: int | None = None,
) -> VladResult:
    try:
        proc = await asyncio.create_subprocess_exec(
            "python",
            str(_VLAD_SCRIPT),
            str(file_path),
            "--json",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout_b, _ = await asyncio.wait_for(proc.communicate(), timeout=300)
    except asyncio.TimeoutError:
        return VladResult(findings=["VLAD timed out after 300s"])
    except Exception as exc:
        return VladResult(findings=[f"VLAD launch error: {exc}"])

    raw = stdout_b.decode(errors="replace")
    from app.services.vlad_bridge import parse_vlad_output
    result = parse_vlad_output(raw)

    result_id = secrets.token_hex(6)
    now = datetime.now(timezone.utc).isoformat()
    await db.conn.execute(
        """INSERT INTO vlad_results
           (id, module_id, version, tier, passed,
            checks_run, checks_passed, checks_failed, findings, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            result_id,
            module_id,
            version,
            result.tier,
            int(result.passed),
            json.dumps(result.checks_run),
            json.dumps(result.checks_passed),
            json.dumps(result.checks_failed),
            json.dumps(result.findings),
            now,
        ),
    )
    await db.conn.commit()

    return result
