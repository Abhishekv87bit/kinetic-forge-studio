"""
Tests for the module execution service (app/services/module_executor.py).

execute_module() spawns a subprocess running the provided source_code.
Tests use tmp_path to provide an isolated output directory.
"""
import pytest
from pathlib import Path

from app.services.module_executor import execute_module, ExecutionResult


PROJECT_ID = "proj-exec-test"
MODULE_ID = "mod-exec-001"


@pytest.mark.asyncio
async def test_execute_simple_module(tmp_path):
    """A well-formed script that writes an STL file reports success."""
    output_dir = tmp_path / "output"
    stl_path = output_dir / "output.stl"

    # Source writes a minimal placeholder STL so the executor finds a file
    source = f"""
from pathlib import Path
p = Path({str(output_dir)!r}) / 'output.stl'
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text('solid empty\\nendsolid empty\\n')
"""

    result = await execute_module(
        project_id=PROJECT_ID,
        module_id=MODULE_ID,
        source_code=source,
        parameters={},
        output_dir=output_dir,
    )

    assert result.success is True
    assert result.error is None
    # The STL file should be in files_written
    assert any("output.stl" in f for f in result.files_written)
    assert result.duration_ms >= 0


@pytest.mark.asyncio
async def test_execute_module_stdout_captured(tmp_path):
    """Stdout printed by the script is captured in the result."""
    output_dir = tmp_path / "output_stdout"
    source = "print('hello from module')"

    result = await execute_module(
        project_id=PROJECT_ID,
        module_id=MODULE_ID,
        source_code=source,
        parameters={},
        output_dir=output_dir,
    )

    assert result.success is True
    assert "hello from module" in result.stdout


@pytest.mark.asyncio
async def test_execute_module_error(tmp_path):
    """A script with a syntax/runtime error returns success=False with an error."""
    output_dir = tmp_path / "output_err"
    bad_source = "this is not valid python !!!"

    result = await execute_module(
        project_id=PROJECT_ID,
        module_id=MODULE_ID,
        source_code=bad_source,
        parameters={},
        output_dir=output_dir,
    )

    assert result.success is False
    assert result.error is not None
    # The error should reference a non-zero exit code
    assert "code" in result.error.lower() or result.stderr


@pytest.mark.asyncio
async def test_execute_module_runtime_error(tmp_path):
    """A script that raises an exception at runtime returns success=False."""
    output_dir = tmp_path / "output_runtime"
    source = "raise RuntimeError('deliberate failure')"

    result = await execute_module(
        project_id=PROJECT_ID,
        module_id=MODULE_ID,
        source_code=source,
        parameters={},
        output_dir=output_dir,
    )

    assert result.success is False
    assert result.error is not None


@pytest.mark.asyncio
async def test_execute_parameters_available(tmp_path):
    """Parameters dict is injected as _PARAMS and accessible in the script."""
    output_dir = tmp_path / "output_params"
    # Script reads _PARAMS (injected by executor) and writes a marker file
    source = """
from pathlib import Path
marker = Path({!r}) / 'marker.txt'
marker.parent.mkdir(parents=True, exist_ok=True)
marker.write_text(str(_PARAMS.get('teeth', 'missing')))
""".format(str(output_dir))

    result = await execute_module(
        project_id=PROJECT_ID,
        module_id=MODULE_ID,
        source_code=source,
        parameters={"teeth": 24},
        output_dir=output_dir,
    )

    assert result.success is True
    marker_file = output_dir / "marker.txt"
    assert marker_file.exists()
    assert marker_file.read_text() == "24"


@pytest.mark.asyncio
async def test_execute_no_geometry_files(tmp_path):
    """A successful script that produces no STL/STEP files returns empty files_written."""
    output_dir = tmp_path / "output_no_geo"
    # Script runs fine but only writes a .txt file — not picked up by executor
    source = f"open({str(output_dir / 'log.txt')!r}, 'w').write('ok')"

    result = await execute_module(
        project_id=PROJECT_ID,
        module_id=MODULE_ID,
        source_code=source,
        parameters={},
        output_dir=output_dir,
    )

    assert result.success is True
    assert result.files_written == []


@pytest.mark.asyncio
async def test_execute_result_model_fields():
    """ExecutionResult Pydantic model has the expected default field types."""
    r = ExecutionResult(success=True)
    assert r.files_written == []
    assert r.stdout == ""
    assert r.stderr == ""
    assert r.duration_ms == 0.0
    assert r.error is None


@pytest.mark.asyncio
async def test_execute_timeout(tmp_path, monkeypatch):
    """A simulated timeout returns success=False with a timeout error message."""
    import asyncio
    from app.services import module_executor

    original_wait_for = asyncio.wait_for

    async def fake_wait_for(coro, timeout):
        raise asyncio.TimeoutError()

    monkeypatch.setattr(asyncio, "wait_for", fake_wait_for)

    output_dir = tmp_path / "output_timeout"
    result = await module_executor.execute_module(
        project_id=PROJECT_ID,
        module_id=MODULE_ID,
        source_code="import time; time.sleep(999)",
        parameters={},
        output_dir=output_dir,
    )

    assert result.success is False
    assert "timed out" in (result.error or "").lower()
