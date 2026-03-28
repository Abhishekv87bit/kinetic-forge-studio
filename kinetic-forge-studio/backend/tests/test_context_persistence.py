"""
Tests for SessionLogManager (SC-05 — Context Persistence).
"""
import pytest
import pytest_asyncio


pytestmark = pytest.mark.asyncio


async def test_log_action(session_log_manager):
    """log_action returns a dict with all expected fields."""
    result = await session_log_manager.log_action(
        project_id="proj-001",
        action="module_created",
    )

    assert isinstance(result, dict)
    for field in ("id", "project_id", "action", "details", "module_id", "created_at"):
        assert field in result, f"Missing field: {field}"

    assert result["project_id"] == "proj-001"
    assert result["action"] == "module_created"


async def test_log_action_with_details(session_log_manager):
    """details dict is JSON-serialised on write and deserialised on read."""
    details = {"name": "gear_shaft", "language": "python"}
    result = await session_log_manager.log_action(
        project_id="proj-001",
        action="module_created",
        details=details,
    )

    assert isinstance(result["details"], dict)
    assert result["details"] == details


async def test_log_action_with_module_id(session_log_manager):
    """module_id is stored and returned when supplied."""
    result = await session_log_manager.log_action(
        project_id="proj-001",
        action="module_updated",
        module_id="mod-abc",
    )

    assert result["module_id"] == "mod-abc"


async def test_get_log(session_log_manager):
    """get_log returns all entries for a project, most recent first."""
    pid = "proj-log-order"
    await session_log_manager.log_action(pid, "action_first")
    await session_log_manager.log_action(pid, "action_second")
    await session_log_manager.log_action(pid, "action_third")

    log = await session_log_manager.get_log(pid)

    assert len(log) == 3
    # Most recent entry created last — its created_at should be >= earlier ones
    assert log[0]["created_at"] >= log[1]["created_at"]
    assert log[1]["created_at"] >= log[2]["created_at"]


async def test_get_log_limit(session_log_manager):
    """get_log(limit=N) returns at most N entries."""
    pid = "proj-limit"
    for i in range(5):
        await session_log_manager.log_action(pid, f"action_{i}")

    log = await session_log_manager.get_log(pid, limit=2)

    assert len(log) == 2


async def test_get_module_log(session_log_manager):
    """get_module_log filters by module_id, excluding entries from other modules."""
    pid = "proj-module-filter"
    await session_log_manager.log_action(pid, "created", module_id="mod-A")
    await session_log_manager.log_action(pid, "created", module_id="mod-B")
    await session_log_manager.log_action(pid, "updated", module_id="mod-A")

    log_a = await session_log_manager.get_module_log("mod-A")
    log_b = await session_log_manager.get_module_log("mod-B")

    assert len(log_a) == 2
    assert all(entry["module_id"] == "mod-A" for entry in log_a)

    assert len(log_b) == 1
    assert log_b[0]["module_id"] == "mod-B"


async def test_get_log_empty_project(session_log_manager):
    """get_log for a project with no entries returns an empty list."""
    log = await session_log_manager.get_log("non-existent-project")

    assert log == []
