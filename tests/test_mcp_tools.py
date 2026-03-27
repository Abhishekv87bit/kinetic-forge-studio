"""SC-07 Contract tests for KFS MCP Tools.

Verifies:
- get_tools() returns five schemas each with the required MCP shape keys
- dispatch_tool routes to the correct handler
- kfs_create_module / kfs_list_modules / kfs_get_module return serialised module dicts
- kfs_execute_module propagates all ExecutionResult fields
- kfs_validate_module returns a dict containing a 'verdict' field
"""
from __future__ import annotations

import dataclasses
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from backend.app.mcp.kfs_tools import (
    KFSMCPServer,
    dispatch_tool,
    get_tools,
)
from backend.app.services.module_executor import ExecutionResult
from backend.app.services.vlad_runner import VladCheck, VladResult


# ---------------------------------------------------------------------------
# Helpers — minimal fake objects
# ---------------------------------------------------------------------------


@dataclasses.dataclass
class _FakeModule:
    """Minimal dataclass that satisfies the module fields KFSMCPServer reads."""

    id: str = "mod-abc"
    project_id: str = "proj-1"
    name: str = "Test Gear"
    geometry_type: str = "gear"
    source_code: str = "import cadquery as cq\nresult = cq.Workplane('XY').box(1,1,1)"
    parameters: Dict[str, Any] = dataclasses.field(default_factory=dict)
    version: int = 1
    status: str = "draft"
    stl_path: Optional[str] = None
    step_path: Optional[str] = None
    vlad_verdict: Optional[str] = None
    created_at: str = "2026-01-01T00:00:00Z"
    updated_at: str = "2026-01-01T00:00:00Z"


def _make_vlad_result(verdict: str = "PASS") -> VladResult:
    return VladResult(
        module_id="mod-abc",
        mechanism_type="gear",
        verdict=verdict,
        passed=(verdict == "PASS"),
        fail_count=0,
        warn_count=1,
        pass_count=5,
        info_count=2,
        fixed_parts=1,
        moving_parts=3,
        checks=[
            VladCheck(check_id="topology", status="PASS", detail="ok"),
        ],
        raw_json="{}",
        run_at=datetime(2026, 1, 1, tzinfo=timezone.utc),
    )


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture()
def mock_mgr() -> AsyncMock:
    """Async mock of ModuleManager that returns a _FakeModule by default."""
    mgr = AsyncMock()
    mgr.create.return_value = _FakeModule()
    mgr.get.return_value = _FakeModule()
    mgr.list_all.return_value = [_FakeModule(), _FakeModule(id="mod-xyz")]
    mgr.set_vlad_verdict.return_value = None
    return mgr


@pytest.fixture()
def mock_executor() -> AsyncMock:
    """Async mock of ModuleExecutor."""
    executor = AsyncMock()
    executor.execute.return_value = ExecutionResult(
        module_id="mod-abc",
        status="valid",
        stl_path="/out/mod-abc/mod-abc.stl",
        step_path="/out/mod-abc/mod-abc.step",
        error=None,
    )
    return executor


@pytest.fixture()
def mock_vlad_runner() -> MagicMock:
    """Sync mock of VladRunner (run() is called via asyncio.to_thread)."""
    runner = MagicMock()
    runner.run.return_value = _make_vlad_result("PASS")
    return runner


@pytest.fixture()
def server(mock_mgr, mock_executor, mock_vlad_runner) -> KFSMCPServer:
    return KFSMCPServer(
        module_manager=mock_mgr,
        module_executor=mock_executor,
        vlad_runner=mock_vlad_runner,
    )


# ---------------------------------------------------------------------------
# get_tools() — schema shape contract
# ---------------------------------------------------------------------------

REQUIRED_TOOL_NAMES = {
    "kfs_create_module",
    "kfs_list_modules",
    "kfs_get_module",
    "kfs_execute_module",
    "kfs_validate_module",
}


def test_get_tools_returns_five_schemas():
    tools = get_tools()
    assert len(tools) == 5


def test_get_tools_all_names_present():
    names = {t["name"] for t in get_tools()}
    assert names == REQUIRED_TOOL_NAMES


def test_each_tool_has_name_key():
    for tool in get_tools():
        assert "name" in tool


def test_each_tool_has_description_key():
    for tool in get_tools():
        assert "description" in tool
        assert isinstance(tool["description"], str)
        assert tool["description"].strip()


def test_each_tool_has_input_schema_key():
    for tool in get_tools():
        assert "inputSchema" in tool


def test_input_schema_has_type_object():
    for tool in get_tools():
        assert tool["inputSchema"].get("type") == "object"


def test_input_schema_has_properties():
    for tool in get_tools():
        assert "properties" in tool["inputSchema"]


def test_all_tools_require_project_id():
    for tool in get_tools():
        required = tool["inputSchema"].get("required", [])
        assert "project_id" in required, f"{tool['name']} missing project_id in required"


def test_get_tools_returns_new_list_each_call():
    """Mutating the returned list must not affect subsequent calls."""
    first = get_tools()
    first.clear()
    second = get_tools()
    assert len(second) == 5


# ---------------------------------------------------------------------------
# kfs_create_module
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_module_returns_dict(server, mock_mgr):
    result = await server.kfs_create_module(
        project_id="proj-1",
        name="Test Gear",
        geometry_type="gear",
        source_code="import cadquery as cq",
    )
    assert isinstance(result, dict)


@pytest.mark.asyncio
async def test_create_module_has_id_field(server):
    result = await server.kfs_create_module(
        project_id="proj-1",
        name="Test Gear",
        geometry_type="gear",
        source_code="import cadquery as cq",
    )
    assert "id" in result


@pytest.mark.asyncio
async def test_create_module_delegates_to_manager(server, mock_mgr):
    await server.kfs_create_module(
        project_id="proj-1",
        name="Test Gear",
        geometry_type="gear",
        source_code="import cadquery as cq",
        parameters={"teeth": 20},
    )
    mock_mgr.create.assert_awaited_once()
    call_kwargs = mock_mgr.create.call_args.kwargs
    assert call_kwargs["project_id"] == "proj-1"
    assert call_kwargs["name"] == "Test Gear"


@pytest.mark.asyncio
async def test_create_module_via_dispatch(server):
    result = await dispatch_tool(
        "kfs_create_module",
        {
            "project_id": "proj-1",
            "name": "Test Gear",
            "geometry_type": "gear",
            "source_code": "...",
        },
        server,
    )
    assert "id" in result


# ---------------------------------------------------------------------------
# kfs_list_modules
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_list_modules_returns_list(server):
    result = await server.kfs_list_modules(project_id="proj-1")
    assert isinstance(result, list)


@pytest.mark.asyncio
async def test_list_modules_length_matches_manager(server):
    result = await server.kfs_list_modules(project_id="proj-1")
    assert len(result) == 2


@pytest.mark.asyncio
async def test_list_modules_items_are_dicts(server):
    result = await server.kfs_list_modules(project_id="proj-1")
    for item in result:
        assert isinstance(item, dict)


@pytest.mark.asyncio
async def test_list_modules_via_dispatch(server):
    result = await dispatch_tool("kfs_list_modules", {"project_id": "proj-1"}, server)
    assert isinstance(result, list)


# ---------------------------------------------------------------------------
# kfs_get_module
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_module_returns_dict(server):
    result = await server.kfs_get_module(project_id="proj-1", module_id="mod-abc")
    assert isinstance(result, dict)


@pytest.mark.asyncio
async def test_get_module_has_id(server):
    result = await server.kfs_get_module(project_id="proj-1", module_id="mod-abc")
    assert "id" in result


@pytest.mark.asyncio
async def test_get_module_delegates_correct_ids(server, mock_mgr):
    await server.kfs_get_module(project_id="proj-1", module_id="mod-abc")
    mock_mgr.get.assert_awaited_once_with(project_id="proj-1", module_id="mod-abc")


@pytest.mark.asyncio
async def test_get_module_via_dispatch(server):
    result = await dispatch_tool(
        "kfs_get_module",
        {"project_id": "proj-1", "module_id": "mod-abc"},
        server,
    )
    assert isinstance(result, dict)


# ---------------------------------------------------------------------------
# kfs_execute_module — ExecutionResult field propagation
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_execute_module_returns_dict(server):
    result = await server.kfs_execute_module(project_id="proj-1", module_id="mod-abc")
    assert isinstance(result, dict)


@pytest.mark.asyncio
async def test_execute_module_has_module_id(server):
    result = await server.kfs_execute_module(project_id="proj-1", module_id="mod-abc")
    assert "module_id" in result
    assert result["module_id"] == "mod-abc"


@pytest.mark.asyncio
async def test_execute_module_has_status(server):
    result = await server.kfs_execute_module(project_id="proj-1", module_id="mod-abc")
    assert "status" in result
    assert result["status"] == "valid"


@pytest.mark.asyncio
async def test_execute_module_has_stl_path(server):
    result = await server.kfs_execute_module(project_id="proj-1", module_id="mod-abc")
    assert "stl_path" in result
    assert result["stl_path"] == "/out/mod-abc/mod-abc.stl"


@pytest.mark.asyncio
async def test_execute_module_has_step_path(server):
    result = await server.kfs_execute_module(project_id="proj-1", module_id="mod-abc")
    assert "step_path" in result
    assert result["step_path"] == "/out/mod-abc/mod-abc.step"


@pytest.mark.asyncio
async def test_execute_module_has_error_field(server):
    result = await server.kfs_execute_module(project_id="proj-1", module_id="mod-abc")
    assert "error" in result
    assert result["error"] is None


@pytest.mark.asyncio
async def test_execute_module_propagates_failure_status(mock_mgr, mock_vlad_runner):
    """When executor returns failed status, that status is propagated."""
    executor = AsyncMock()
    executor.execute.return_value = ExecutionResult(
        module_id="mod-abc",
        status="failed",
        error="SyntaxError: invalid syntax",
    )
    server = KFSMCPServer(mock_mgr, executor, mock_vlad_runner)
    result = await server.kfs_execute_module(project_id="proj-1", module_id="mod-abc")
    assert result["status"] == "failed"
    assert "SyntaxError" in result["error"]
    assert result["stl_path"] is None
    assert result["step_path"] is None


@pytest.mark.asyncio
async def test_execute_module_via_dispatch(server):
    result = await dispatch_tool(
        "kfs_execute_module",
        {"project_id": "proj-1", "module_id": "mod-abc"},
        server,
    )
    assert "module_id" in result


# ---------------------------------------------------------------------------
# kfs_validate_module — verdict field contract
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_validate_module_returns_dict(server, mock_vlad_runner):
    fake_bridge = MagicMock()
    fake_bridge.write_bridge.return_value = "/tmp/bridge_abc.py"
    fake_bridge.cleanup.return_value = None

    with patch("backend.app.mcp.kfs_tools.VladBridge", return_value=fake_bridge):
        result = await server.kfs_validate_module(
            project_id="proj-1", module_id="mod-abc"
        )
    assert isinstance(result, dict)


@pytest.mark.asyncio
async def test_validate_module_has_verdict(server, mock_vlad_runner):
    fake_bridge = MagicMock()
    fake_bridge.write_bridge.return_value = "/tmp/bridge_abc.py"
    fake_bridge.cleanup.return_value = None

    with patch("backend.app.mcp.kfs_tools.VladBridge", return_value=fake_bridge):
        result = await server.kfs_validate_module(
            project_id="proj-1", module_id="mod-abc"
        )
    assert "verdict" in result
    assert result["verdict"] == "PASS"


@pytest.mark.asyncio
async def test_validate_module_has_passed(server, mock_vlad_runner):
    fake_bridge = MagicMock()
    fake_bridge.write_bridge.return_value = "/tmp/bridge_abc.py"
    fake_bridge.cleanup.return_value = None

    with patch("backend.app.mcp.kfs_tools.VladBridge", return_value=fake_bridge):
        result = await server.kfs_validate_module(
            project_id="proj-1", module_id="mod-abc"
        )
    assert "passed" in result
    assert result["passed"] is True


@pytest.mark.asyncio
async def test_validate_module_has_counts(server, mock_vlad_runner):
    fake_bridge = MagicMock()
    fake_bridge.write_bridge.return_value = "/tmp/bridge_abc.py"
    fake_bridge.cleanup.return_value = None

    with patch("backend.app.mcp.kfs_tools.VladBridge", return_value=fake_bridge):
        result = await server.kfs_validate_module(
            project_id="proj-1", module_id="mod-abc"
        )
    assert "counts" in result
    counts = result["counts"]
    for key in ("pass", "fail", "warn", "info"):
        assert key in counts


@pytest.mark.asyncio
async def test_validate_module_has_checks(server, mock_vlad_runner):
    fake_bridge = MagicMock()
    fake_bridge.write_bridge.return_value = "/tmp/bridge_abc.py"
    fake_bridge.cleanup.return_value = None

    with patch("backend.app.mcp.kfs_tools.VladBridge", return_value=fake_bridge):
        result = await server.kfs_validate_module(
            project_id="proj-1", module_id="mod-abc"
        )
    assert "checks" in result
    assert isinstance(result["checks"], list)


@pytest.mark.asyncio
async def test_validate_module_stores_verdict(server, mock_mgr, mock_vlad_runner):
    fake_bridge = MagicMock()
    fake_bridge.write_bridge.return_value = "/tmp/bridge_abc.py"
    fake_bridge.cleanup.return_value = None

    with patch("backend.app.mcp.kfs_tools.VladBridge", return_value=fake_bridge):
        await server.kfs_validate_module(project_id="proj-1", module_id="mod-abc")

    mock_mgr.set_vlad_verdict.assert_awaited_once_with(
        project_id="proj-1",
        module_id="mod-abc",
        verdict="PASS",
    )


@pytest.mark.asyncio
async def test_validate_module_fail_verdict(mock_mgr, mock_vlad_runner):
    """FAIL verdict is propagated correctly."""
    mock_vlad_runner.run.return_value = _make_vlad_result("FAIL")
    server = KFSMCPServer(mock_mgr, AsyncMock(), mock_vlad_runner)

    fake_bridge = MagicMock()
    fake_bridge.write_bridge.return_value = "/tmp/bridge_xyz.py"
    fake_bridge.cleanup.return_value = None

    with patch("backend.app.mcp.kfs_tools.VladBridge", return_value=fake_bridge):
        result = await server.kfs_validate_module(
            project_id="proj-1", module_id="mod-abc"
        )
    assert result["verdict"] == "FAIL"
    assert result["passed"] is False


@pytest.mark.asyncio
async def test_validate_module_via_dispatch(server, mock_vlad_runner):
    fake_bridge = MagicMock()
    fake_bridge.write_bridge.return_value = "/tmp/bridge_abc.py"
    fake_bridge.cleanup.return_value = None

    with patch("backend.app.mcp.kfs_tools.VladBridge", return_value=fake_bridge):
        result = await dispatch_tool(
            "kfs_validate_module",
            {"project_id": "proj-1", "module_id": "mod-abc"},
            server,
        )
    assert "verdict" in result


# ---------------------------------------------------------------------------
# dispatch_tool — routing contract
# ---------------------------------------------------------------------------


def test_dispatch_unknown_tool_raises(server):
    with pytest.raises(ValueError, match="Unknown KFS tool"):
        import asyncio
        asyncio.get_event_loop().run_until_complete(
            dispatch_tool("kfs_nonexistent", {}, server)
        )
