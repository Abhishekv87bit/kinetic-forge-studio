"""
Tests for the observability middleware (SC-10).
Covers session log integration, timestamp format, and LLM call tracking.
"""
import pytest
import pytest_asyncio
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Session log integration — module creation via API should produce a log entry
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_session_log_captures_module_actions(client, tmp_path):
    """
    Creating a module via the API route writes a row to the session_log table.
    Uses the same isolated database as the test client.
    """
    from httpx import AsyncClient, ASGITransport
    from app.routes import modules as modules_route

    async with AsyncClient(
        transport=ASGITransport(app=client), base_url="http://test"
    ) as ac:
        resp = await ac.post(
            "/api/projects/test-proj/modules",
            json={
                "name": "helix_shaft",
                "source_code": "import cadquery as cq\nresult = cq.Workplane('XY')",
                "language": "python",
            },
        )

    assert resp.status_code == 200

    # The session log manager on the route is the same instance injected by the
    # client fixture — read directly to verify persistence.
    sl = modules_route._sl
    await sl._ensure_db()
    log = await sl.get_log("test-proj")

    assert len(log) >= 1
    assert log[0]["action"] == "module_created"
    assert log[0]["project_id"] == "test-proj"


# ---------------------------------------------------------------------------
# Timestamp format
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_log_action_returns_timestamp(session_log_manager):
    """created_at must be a valid ISO-8601 UTC timestamp string."""
    entry = await session_log_manager.log_action(
        project_id="proj-ts",
        action="test_action",
    )

    ts_str = entry["created_at"]
    assert isinstance(ts_str, str), "created_at must be a string"

    # Should parse without raising — fromisoformat handles the +00:00 suffix
    parsed = datetime.fromisoformat(ts_str)
    assert parsed.tzinfo is not None, "created_at must be timezone-aware"


# ---------------------------------------------------------------------------
# LLM call tracking — functions exist and are callable
# ---------------------------------------------------------------------------

def test_log_llm_call_is_callable():
    """log_llm_call must be importable and callable."""
    from app.middleware.observability import log_llm_call

    assert callable(log_llm_call)


def test_observe_llm_call_is_callable():
    """observe_llm_call must be importable and callable (async)."""
    from app.middleware.observability import observe_llm_call

    assert callable(observe_llm_call)


@pytest.mark.asyncio
async def test_log_llm_call_returns_entry():
    """log_llm_call returns a dict with all expected tracking fields."""
    from app.middleware.observability import log_llm_call

    entry = log_llm_call(
        name="test_gen",
        model="gemini-2.5-flash",
        input_tokens=100,
        output_tokens=50,
        latency_ms=123.4,
        success=True,
    )

    assert isinstance(entry, dict)
    for field in ("name", "model", "input_tokens", "output_tokens", "cost_usd",
                  "latency_ms", "success", "timestamp"):
        assert field in entry, f"Missing field in log_llm_call result: {field}"

    assert entry["name"] == "test_gen"
    assert entry["model"] == "gemini-2.5-flash"
    assert entry["input_tokens"] == 100
    assert entry["output_tokens"] == 50
    assert entry["success"] is True
    assert entry["cost_usd"] >= 0


@pytest.mark.asyncio
async def test_observe_llm_call_executes_fn():
    """observe_llm_call awaits the provided callable and returns its result."""
    from app.middleware.observability import observe_llm_call

    async def _fake_llm():
        return "generated_geometry"

    result = await observe_llm_call(
        name="fake_call",
        model="gemini-2.5-flash",
        input_text="build a gear",
        call_fn=_fake_llm,
    )

    assert result == "generated_geometry"
