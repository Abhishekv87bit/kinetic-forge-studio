"""
VladRunner — executes ``vlad.py`` in an isolated subprocess (``--json`` mode),
parses the structured JSON result, and persists it to the ``vlad_results`` table.

JSON schema emitted by vlad.py --json:
    {
      "module": "<name>",
      "mechanism_type": "<type>",
      "fixed_parts": <int>,
      "moving_parts": <int>,
      "verdict": "PASS" | "FAIL",
      "counts": {"pass": int, "fail": int, "warn": int, "info": int},
      "checks": [{"id": str, "status": str, "detail": str}, ...]
    }
"""
import json
import logging
import sqlite3
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional

from backend.app.config import settings
from backend.app.middleware.observability import log_execution_sync

_log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------

@dataclass
class VladCheck:
    """Single check entry from VLAD output."""
    check_id: str
    status: str      # PASS | FAIL | WARN | INFO
    detail: str


@dataclass
class VladResult:
    """Parsed result of one VLAD run."""
    module_id: str
    mechanism_type: str
    verdict: str          # PASS | FAIL
    passed: bool
    fail_count: int
    warn_count: int
    pass_count: int
    info_count: int
    fixed_parts: int
    moving_parts: int
    checks: List[VladCheck] = field(default_factory=list)
    raw_json: str = ""
    run_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    db_row_id: Optional[int] = None

    @classmethod
    def from_vlad_json(cls, module_id: str, raw: str) -> "VladResult":
        """Parse VLAD's ``--json`` stdout into a :class:`VladResult`."""
        data = json.loads(raw)
        counts = data.get("counts", {})
        checks = [
            VladCheck(
                check_id=c["id"],
                status=c["status"],
                detail=c.get("detail", ""),
            )
            for c in data.get("checks", [])
        ]
        verdict = data.get("verdict", "FAIL")
        return cls(
            module_id=module_id,
            mechanism_type=data.get("mechanism_type", "unknown"),
            verdict=verdict,
            passed=(verdict == "PASS"),
            fail_count=counts.get("fail", 0),
            warn_count=counts.get("warn", 0),
            pass_count=counts.get("pass", 0),
            info_count=counts.get("info", 0),
            fixed_parts=data.get("fixed_parts", 0),
            moving_parts=data.get("moving_parts", 0),
            checks=checks,
            raw_json=raw,
        )


# ---------------------------------------------------------------------------
# Schema helper
# ---------------------------------------------------------------------------

_CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS vlad_results (
    id             INTEGER  PRIMARY KEY AUTOINCREMENT,
    module_id      TEXT     NOT NULL,
    mechanism_type TEXT     NOT NULL DEFAULT '',
    verdict        TEXT     NOT NULL,
    passed         INTEGER  NOT NULL,
    fail_count     INTEGER  NOT NULL DEFAULT 0,
    warn_count     INTEGER  NOT NULL DEFAULT 0,
    pass_count     INTEGER  NOT NULL DEFAULT 0,
    info_count     INTEGER  NOT NULL DEFAULT 0,
    fixed_parts    INTEGER  NOT NULL DEFAULT 0,
    moving_parts   INTEGER  NOT NULL DEFAULT 0,
    checks_json    TEXT     NOT NULL DEFAULT '[]',
    raw_json       TEXT     NOT NULL DEFAULT '',
    run_at         TEXT     NOT NULL
)
"""

_INSERT_SQL = """
INSERT INTO vlad_results
    (module_id, mechanism_type, verdict, passed,
     fail_count, warn_count, pass_count, info_count,
     fixed_parts, moving_parts, checks_json, raw_json, run_at)
VALUES
    (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
"""


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

class VladRunner:
    """
    Runs ``vlad.py --json <bridge_module>`` in a subprocess, parses the
    result, and persists it to SQLite.

    Parameters
    ----------
    db_path:
        Path to the SQLite database file.  The ``vlad_results`` table is
        created automatically on first use if it does not exist.
    vlad_script_path:
        Path to the ``vlad.py`` script.  Defaults to
        ``settings.vlad_script_path``.
    timeout:
        Maximum seconds to wait for the VLAD subprocess.  Defaults to
        ``settings.cadquery_timeout``.
    """

    def __init__(
        self,
        db_path: str,
        vlad_script_path: Optional[str] = None,
        timeout: Optional[int] = None,
    ) -> None:
        self.db_path = db_path
        self.vlad_script_path = vlad_script_path or settings.vlad_script_path
        self.timeout = timeout or settings.cadquery_timeout
        self._ensure_table()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def run(self, module_id: str, bridge_module_path: str) -> VladResult:
        """
        Execute VLAD against *bridge_module_path* and return the result.

        The result is stored in the ``vlad_results`` table regardless of
        pass/fail status so that failure history is preserved.

        Parameters
        ----------
        module_id:
            Identifier of the KFS module (used as FK reference).
        bridge_module_path:
            Absolute path to the bridge ``.py`` file produced by
            :class:`~backend.app.services.vlad_bridge.VladBridge`.

        Returns
        -------
        VladResult
            Parsed result with ``db_row_id`` set.

        Raises
        ------
        subprocess.TimeoutExpired
            When VLAD does not complete within :attr:`timeout` seconds.
        ValueError
            When VLAD exits with code 2 (fatal / import error) or produces
            non-JSON output.
        """
        start = time.perf_counter()
        run_status = "failure"
        try:
            raw_output = self._invoke_vlad(bridge_module_path)
            result = VladResult.from_vlad_json(module_id, raw_output)
            result.db_row_id = self._store(result)
            run_status = "success" if result.passed else "fail_verdict"
            return result
        finally:
            log_execution_sync(
                "VladRunner",
                "run",
                run_status,
                time.perf_counter() - start,
                {"module_id": module_id, "bridge": bridge_module_path},
            )

    def get_latest(self, module_id: str) -> Optional[VladResult]:
        """
        Return the most recent :class:`VladResult` for *module_id*, or
        *None* if no results exist.
        """
        sql = """
            SELECT id, module_id, mechanism_type, verdict, passed,
                   fail_count, warn_count, pass_count, info_count,
                   fixed_parts, moving_parts, checks_json, raw_json, run_at
            FROM   vlad_results
            WHERE  module_id = ?
            ORDER  BY run_at DESC
            LIMIT  1
        """
        with self._connect() as conn:
            row = conn.execute(sql, (module_id,)).fetchone()
        if row is None:
            return None
        return self._row_to_result(row)

    def get_history(self, module_id: str, limit: int = 10) -> List[VladResult]:
        """Return up to *limit* most-recent results for *module_id*."""
        sql = """
            SELECT id, module_id, mechanism_type, verdict, passed,
                   fail_count, warn_count, pass_count, info_count,
                   fixed_parts, moving_parts, checks_json, raw_json, run_at
            FROM   vlad_results
            WHERE  module_id = ?
            ORDER  BY run_at DESC
            LIMIT  ?
        """
        with self._connect() as conn:
            rows = conn.execute(sql, (module_id, limit)).fetchall()
        return [self._row_to_result(r) for r in rows]

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _invoke_vlad(self, bridge_path: str) -> str:
        """Invoke ``vlad.py --json <bridge>`` and return stdout."""
        cmd = [
            sys.executable,
            self.vlad_script_path,
            "--json",
            bridge_path,
        ]
        try:
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.timeout,
            )
        except subprocess.TimeoutExpired as exc:
            raise subprocess.TimeoutExpired(
                cmd, self.timeout,
                output=f"VLAD timed out after {self.timeout}s for {bridge_path}",
            ) from exc

        # Exit code 2 = fatal (module import failure, missing functions, etc.)
        if proc.returncode == 2:
            raise ValueError(
                f"VLAD fatal error (exit 2) for {bridge_path}:\n{proc.stderr}"
            )

        # Exit 0 = all passing, exit 1 = FAILs found — both produce JSON.
        stdout = proc.stdout.strip()
        if not stdout:
            raise ValueError(
                f"VLAD produced no JSON output for {bridge_path}.\n"
                f"stderr: {proc.stderr}"
            )

        # Validate JSON before returning
        try:
            json.loads(stdout)
        except json.JSONDecodeError as exc:
            raise ValueError(
                f"VLAD output is not valid JSON for {bridge_path}: {exc}\n"
                f"stdout: {stdout[:500]}"
            ) from exc

        return stdout

    def _store(self, result: VladResult) -> int:
        """Insert *result* into ``vlad_results`` and return the new row id."""
        checks_json = json.dumps(
            [{"id": c.check_id, "status": c.status, "detail": c.detail}
             for c in result.checks]
        )
        run_at_str = result.run_at.isoformat()
        with self._connect() as conn:
            cur = conn.execute(
                _INSERT_SQL,
                (
                    result.module_id,
                    result.mechanism_type,
                    result.verdict,
                    int(result.passed),
                    result.fail_count,
                    result.warn_count,
                    result.pass_count,
                    result.info_count,
                    result.fixed_parts,
                    result.moving_parts,
                    checks_json,
                    result.raw_json,
                    run_at_str,
                ),
            )
            conn.commit()
            return cur.lastrowid

    def _row_to_result(self, row: tuple) -> VladResult:
        """Convert a DB row tuple to a :class:`VladResult`."""
        (
            row_id, module_id, mechanism_type, verdict, passed,
            fail_count, warn_count, pass_count, info_count,
            fixed_parts, moving_parts, checks_json, raw_json, run_at,
        ) = row

        checks_data = json.loads(checks_json or "[]")
        checks = [
            VladCheck(c["id"], c["status"], c.get("detail", ""))
            for c in checks_data
        ]

        return VladResult(
            module_id=module_id,
            mechanism_type=mechanism_type,
            verdict=verdict,
            passed=bool(passed),
            fail_count=fail_count,
            warn_count=warn_count,
            pass_count=pass_count,
            info_count=info_count,
            fixed_parts=fixed_parts,
            moving_parts=moving_parts,
            checks=checks,
            raw_json=raw_json,
            run_at=datetime.fromisoformat(run_at),
            db_row_id=row_id,
        )

    def _ensure_table(self) -> None:
        with self._connect() as conn:
            conn.execute(_CREATE_TABLE_SQL)
            conn.commit()

    def _connect(self) -> sqlite3.Connection:
        return sqlite3.connect(self.db_path)
