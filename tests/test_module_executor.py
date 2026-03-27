"""Contract tests for SC-02 Module Executor.

Covers:
- Successful execution writes STL/STEP to disk and sets status="valid"
- Failed execution (engine raises) sets status="failed" with error populated
- execute_and_validate stub delegates to execute() and returns ExecutionResult
- No-engine path returns a clear failure
- Real CadQuery tests guarded by @pytest.mark.requires_cadquery
"""
from __future__ import annotations

import os
import pytest
from unittest.mock import MagicMock

from backend.app.services.module_executor import ExecutionResult, ModuleExecutor


# ---------------------------------------------------------------------------
# Custom markers (also declared in pytest.ini if needed globally)
# ---------------------------------------------------------------------------


def pytest_configure(config):  # noqa: D401
    config.addinivalue_line(
        "markers",
        "requires_cadquery: marks tests that need the real CadQuery engine installed",
    )


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def output_dir(tmp_path):
    """Temporary directory for artefact output — isolated per test."""
    return str(tmp_path)


@pytest.fixture
def mock_engine():
    """Minimal CadQueryEngine mock: writes sentinel artefact files on run_code()."""
    engine = MagicMock()

    def _run_code(code, *, stl_path, step_path):
        with open(stl_path, "wb") as f:
            f.write(b"solid mock\nendsolid\n")
        with open(step_path, "wb") as f:
            f.write(b"ISO-10303-21; mock STEP geometry")

    engine.run_code.side_effect = _run_code
    return engine


@pytest.fixture
def executor(output_dir, mock_engine):
    """ModuleExecutor wired to the mock engine."""
    return ModuleExecutor(output_dir=output_dir, engine=mock_engine)


@pytest.fixture
def failing_engine():
    """CadQueryEngine mock that raises RuntimeError on run_code()."""
    engine = MagicMock()
    engine.run_code.side_effect = RuntimeError("syntax error in CadQuery script")
    return engine


@pytest.fixture
def failing_executor(output_dir, failing_engine):
    """ModuleExecutor wired to the failing engine."""
    return ModuleExecutor(output_dir=output_dir, engine=failing_engine)


# ---------------------------------------------------------------------------
# Successful execution — status=valid, files written
# ---------------------------------------------------------------------------


class TestSuccessfulExecution:
    """Engine succeeds: result.status must be 'valid' and both files must exist."""

    @pytest.mark.asyncio
    async def test_status_is_valid(self, executor):
        result = await executor.execute("gear_01", "import cadquery as cq")
        assert result.status == "valid"

    @pytest.mark.asyncio
    async def test_module_id_propagated(self, executor):
        result = await executor.execute("gear_01", "import cadquery as cq")
        assert result.module_id == "gear_01"

    @pytest.mark.asyncio
    async def test_stl_file_written(self, executor):
        result = await executor.execute("gear_01", "import cadquery as cq")
        assert result.stl_path is not None, "stl_path must be set on success"
        assert os.path.isfile(result.stl_path), "STL file must exist on disk"

    @pytest.mark.asyncio
    async def test_step_file_written(self, executor):
        result = await executor.execute("gear_01", "import cadquery as cq")
        assert result.step_path is not None, "step_path must be set on success"
        assert os.path.isfile(result.step_path), "STEP file must exist on disk"

    @pytest.mark.asyncio
    async def test_stl_inside_module_subdirectory(self, executor, output_dir):
        result = await executor.execute("gear_01", "import cadquery as cq")
        assert output_dir in result.stl_path
        assert "gear_01" in result.stl_path

    @pytest.mark.asyncio
    async def test_step_inside_module_subdirectory(self, executor, output_dir):
        result = await executor.execute("gear_01", "import cadquery as cq")
        assert output_dir in result.step_path
        assert "gear_01" in result.step_path

    @pytest.mark.asyncio
    async def test_error_is_none_on_success(self, executor):
        result = await executor.execute("gear_01", "import cadquery as cq")
        assert result.error is None

    @pytest.mark.asyncio
    async def test_module_dir_created(self, executor, output_dir):
        await executor.execute("gear_01", "import cadquery as cq")
        expected_dir = os.path.join(output_dir, "gear_01")
        assert os.path.isdir(expected_dir)

    @pytest.mark.asyncio
    async def test_engine_run_code_called_once(self, executor, mock_engine):
        await executor.execute("gear_01", "import cadquery as cq")
        mock_engine.run_code.assert_called_once()


# ---------------------------------------------------------------------------
# Failed execution — status=failed, error populated
# ---------------------------------------------------------------------------


class TestFailedExecution:
    """Engine raises: result.status must be 'failed' and error must be set."""

    @pytest.mark.asyncio
    async def test_status_is_failed(self, failing_executor):
        result = await failing_executor.execute("bad_module", "invalid code")
        assert result.status == "failed"

    @pytest.mark.asyncio
    async def test_error_is_populated(self, failing_executor):
        result = await failing_executor.execute("bad_module", "invalid code")
        assert result.error is not None
        assert len(result.error) > 0

    @pytest.mark.asyncio
    async def test_error_contains_exception_message(self, failing_executor):
        result = await failing_executor.execute("bad_module", "invalid code")
        assert "syntax error in CadQuery script" in result.error

    @pytest.mark.asyncio
    async def test_module_id_propagated_on_failure(self, failing_executor):
        result = await failing_executor.execute("bad_module", "invalid code")
        assert result.module_id == "bad_module"

    @pytest.mark.asyncio
    async def test_stl_path_is_none_on_failure(self, failing_executor):
        result = await failing_executor.execute("bad_module", "invalid code")
        assert result.stl_path is None

    @pytest.mark.asyncio
    async def test_step_path_is_none_on_failure(self, failing_executor):
        result = await failing_executor.execute("bad_module", "invalid code")
        assert result.step_path is None

    @pytest.mark.asyncio
    async def test_does_not_raise_on_engine_error(self, failing_executor):
        # Engine errors must be caught and returned as ExecutionResult, not re-raised
        try:
            result = await failing_executor.execute("bad_module", "invalid code")
        except Exception as exc:
            pytest.fail(f"execute() must not propagate engine exceptions — got {exc!r}")


# ---------------------------------------------------------------------------
# execute_and_validate stub (SC-03 integration point)
# ---------------------------------------------------------------------------


class TestExecuteAndValidate:
    """execute_and_validate delegates to execute() until SC-03 is wired."""

    @pytest.mark.asyncio
    async def test_returns_execution_result(self, executor):
        result = await executor.execute_and_validate("gear_02", "import cadquery as cq")
        assert isinstance(result, ExecutionResult)

    @pytest.mark.asyncio
    async def test_status_valid_on_success(self, executor):
        result = await executor.execute_and_validate("gear_02", "import cadquery as cq")
        assert result.status == "valid"

    @pytest.mark.asyncio
    async def test_writes_stl_on_success(self, executor):
        result = await executor.execute_and_validate("gear_02", "import cadquery as cq")
        assert result.stl_path is not None
        assert os.path.isfile(result.stl_path)

    @pytest.mark.asyncio
    async def test_writes_step_on_success(self, executor):
        result = await executor.execute_and_validate("gear_02", "import cadquery as cq")
        assert result.step_path is not None
        assert os.path.isfile(result.step_path)

    @pytest.mark.asyncio
    async def test_status_failed_on_engine_error(self, failing_executor):
        result = await failing_executor.execute_and_validate("bad_module", "bad code")
        assert result.status == "failed"

    @pytest.mark.asyncio
    async def test_error_populated_on_engine_error(self, failing_executor):
        result = await failing_executor.execute_and_validate("bad_module", "bad code")
        assert result.error is not None

    @pytest.mark.asyncio
    async def test_module_id_propagated(self, executor):
        result = await executor.execute_and_validate("gear_02", "import cadquery as cq")
        assert result.module_id == "gear_02"


# ---------------------------------------------------------------------------
# No-engine path — explicit failure without RuntimeError propagation
# ---------------------------------------------------------------------------


class TestNoEngine:
    """Executor created without an engine must return a clear failure, not crash."""

    @pytest.mark.asyncio
    async def test_status_is_failed(self, output_dir):
        executor = ModuleExecutor(output_dir=output_dir, engine=None)
        result = await executor.execute("gear_01", "import cadquery as cq")
        assert result.status == "failed"

    @pytest.mark.asyncio
    async def test_error_is_populated(self, output_dir):
        executor = ModuleExecutor(output_dir=output_dir, engine=None)
        result = await executor.execute("gear_01", "import cadquery as cq")
        assert result.error is not None

    @pytest.mark.asyncio
    async def test_does_not_raise(self, output_dir):
        executor = ModuleExecutor(output_dir=output_dir, engine=None)
        try:
            await executor.execute("gear_01", "import cadquery as cq")
        except Exception as exc:
            pytest.fail(f"execute() must not raise when engine=None — got {exc!r}")


# ---------------------------------------------------------------------------
# CadQuery-dependent tests — skipped unless real engine is available
# ---------------------------------------------------------------------------


@pytest.mark.requires_cadquery
class TestWithRealCadQuery:
    """Integration tests that require CadQuery and cadquery_engine installed."""

    @pytest.mark.asyncio
    async def test_simple_box_produces_stl(self, output_dir):
        try:
            from backend.app.engines.cadquery_engine import CadQueryEngine
        except ImportError:
            pytest.skip("cadquery_engine not available")

        engine = CadQueryEngine()
        executor = ModuleExecutor(output_dir=output_dir, engine=engine)
        code = (
            "import cadquery as cq\n"
            "result = cq.Workplane('XY').box(10, 10, 10)\n"
        )
        result = await executor.execute("box_test", code)
        assert result.status == "valid"
        assert result.stl_path is not None
        assert os.path.isfile(result.stl_path)

    @pytest.mark.asyncio
    async def test_invalid_code_sets_failed(self, output_dir):
        try:
            from backend.app.engines.cadquery_engine import CadQueryEngine
        except ImportError:
            pytest.skip("cadquery_engine not available")

        engine = CadQueryEngine()
        executor = ModuleExecutor(output_dir=output_dir, engine=engine)
        result = await executor.execute("bad_test", "this is not valid python !!!@@#")
        assert result.status == "failed"
        assert result.error is not None
