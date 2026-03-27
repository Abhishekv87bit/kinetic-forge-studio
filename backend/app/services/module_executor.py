"""SC-02 Module Executor.

Execute a module's CadQuery code via the CadQueryEngine, write STL and STEP
artefacts to disk, and return a normalised ExecutionResult.
"""
from __future__ import annotations

import asyncio
import logging
import os
from dataclasses import dataclass
from typing import Optional

from backend.app.services.durga import DurgaRepairEngine

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Value objects
# ---------------------------------------------------------------------------


@dataclass
class ExecutionResult:
    """Outcome of a single module execution attempt.

    Attributes:
        module_id: Opaque identifier passed through from the caller.
        status:    ``"valid"`` on success, ``"failed"`` on any exception.
        stl_path:  Absolute path to the written STL file (success only).
        step_path: Absolute path to the written STEP file (success only).
        error:     Exception message (failure only).
    """

    module_id: str
    status: str  # "valid" | "failed"
    stl_path: Optional[str] = None
    step_path: Optional[str] = None
    error: Optional[str] = None


# ---------------------------------------------------------------------------
# Executor
# ---------------------------------------------------------------------------


class ModuleExecutor:
    """Execute a module's CadQuery code and persist STL/STEP artefacts.

    The CadQueryEngine is injected so tests can supply a lightweight mock
    without requiring CadQuery to be installed in the test environment.

    Args:
        output_dir: Root directory under which per-module sub-directories
                    are created (e.g. ``{project}/models/``).
        engine:     CadQueryEngine instance.  Must expose
                    ``run_code(code, *, stl_path, step_path)`` which writes
                    the two artefact files.  Pass ``None`` only in tests that
                    explicitly verify the "no engine" failure path.
    """

    def __init__(
        self,
        output_dir: str,
        engine=None,
        durga_engine: Optional[DurgaRepairEngine] = None,
    ) -> None:
        self.output_dir = output_dir
        self._engine = engine
        self._durga = durga_engine or DurgaRepairEngine()

    # ------------------------------------------------------------------
    # Public interface
    # ------------------------------------------------------------------

    async def execute(self, module_id: str, code: str) -> ExecutionResult:
        """Run *code* and write STL + STEP artefacts to disk.

        Returns an :class:`ExecutionResult` with ``status="valid"`` on success
        or ``status="failed"`` (with ``error`` populated) if the engine raises.
        """
        module_dir = os.path.join(self.output_dir, module_id)
        os.makedirs(module_dir, exist_ok=True)

        stl_path = os.path.join(module_dir, f"{module_id}.stl")
        step_path = os.path.join(module_dir, f"{module_id}.step")

        try:
            await self._run_engine(code, stl_path, step_path)
            return ExecutionResult(
                module_id=module_id,
                status="valid",
                stl_path=stl_path,
                step_path=step_path,
            )
        except Exception as exc:
            error_str = str(exc)
            logger.error("Execution failed for module %r: %s", module_id, error_str)

            # ── SC-06: Durga repair escalation ────────────────────────
            repair = await self._durga.attempt_repair(code, error_str)
            if repair.success and repair.fixed_code:
                logger.info(
                    "Durga repaired module %r via tier=%r rule=%r — retrying",
                    module_id,
                    repair.tier_used,
                    repair.rule_name,
                )
                try:
                    await self._run_engine(repair.fixed_code, stl_path, step_path)
                    return ExecutionResult(
                        module_id=module_id,
                        status="valid",
                        stl_path=stl_path,
                        step_path=step_path,
                    )
                except Exception as retry_exc:
                    logger.error(
                        "Durga-repaired retry failed for module %r: %s",
                        module_id,
                        retry_exc,
                    )
                    error_str = f"{error_str} | repair({repair.tier_used}) retry: {retry_exc}"

            return ExecutionResult(
                module_id=module_id,
                status="failed",
                error=error_str,
            )

    async def execute_and_validate(self, module_id: str, code: str) -> ExecutionResult:
        """Execute code and run VLAD validation (SC-03 integration stub).

        SC-03 (VladRunner) will enrich this result with validation data.
        Until then, the stub delegates to :meth:`execute` unchanged.
        """
        return await self.execute(module_id, code)

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    async def _run_engine(self, code: str, stl_path: str, step_path: str) -> None:
        """Delegate to the CadQueryEngine in a thread-pool executor.

        CadQueryEngine.run_code is synchronous; running it via
        ``asyncio.to_thread`` prevents blocking the event loop.
        """
        if self._engine is None:
            raise RuntimeError(
                "No CadQueryEngine configured — pass engine= to ModuleExecutor"
            )
        await asyncio.to_thread(
            self._engine.run_code,
            code,
            stl_path=stl_path,
            step_path=step_path,
        )
