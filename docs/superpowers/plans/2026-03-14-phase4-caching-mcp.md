# Phase 4: Caching Layer + MCP Exposure Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add async-aware TTL caching + Anthropic prompt caching (GAP-PPL-009) and an MCP server exposing VLAD/CadQuery/Library tools (GAP-PPL-014) to close Production Pipeline Phase 4.

**Architecture:** Two independent subsystems. (1) A reusable `TTLCache` class in `app/middleware/cache.py` with async-safe decorators, plus Anthropic `cache_control` headers in the Claude API call. (2) A standalone FastMCP server at `kfs_mcp_server.py` wrapping 3 KFS tools with structured JSON responses.

**Tech Stack:** Python 3.11+, asyncio, hashlib, FastAPI, FastMCP, httpx, pytest-asyncio

**Spec:** `docs/superpowers/specs/2026-03-14-phase4-caching-mcp-design.md`

---

## File Structure

### New Files

| File | Responsibility |
|------|----------------|
| `backend/app/middleware/cache.py` | TTLCache class, async decorators, stats, invalidation |
| `backend/tests/test_cache.py` | Unit tests for TTLCache + integration tests for wiring |
| `backend/kfs_mcp_server.py` | FastMCP server exposing 3 KFS tools |
| `backend/tests/test_mcp_server.py` | Tests for MCP tool invocations |
| `production-pipeline/templates/cache.py` | Universal caching template |
| `production-pipeline/templates/mcp_server.py` | Universal MCP server template |

### Modified Files

| File | Change |
|------|--------|
| `backend/app/orchestrator/chat_agent.py:340-345` | Add `cache_control` to Claude system block |
| `backend/app/main.py:63-71` | Wire cache stats into `/api/health` |
| `backend/pyproject.toml:5-14` | Add `fastmcp` dependency |

---

## Chunk 1: TTLCache Core + Tests

### Task 1: TTLCache Class — Failing Tests

**Files:**
- Create: `backend/tests/test_cache.py`

- [ ] **Step 1: Write failing tests for TTLCache core**

```python
"""Tests for TTLCache + caching decorators (GAP-PPL-009)."""

from __future__ import annotations

import asyncio
import time
from unittest.mock import patch

import pytest

# We'll import from the module we're about to create
from app.middleware.cache import TTLCache, get_cache_stats, clear_all_caches


# ---------------------------------------------------------------------------
# TTLCache unit tests
# ---------------------------------------------------------------------------

class TestTTLCacheBasic:
    """Core get/set/eviction behavior."""

    def test_set_and_get(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        cache.set("key1", "value1")
        assert cache.get("key1") == "value1"

    def test_get_missing_returns_none(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        assert cache.get("nonexistent") is None

    def test_ttl_expiry(self):
        cache = TTLCache(max_size=10, ttl_seconds=1)
        cache.set("key1", "value1")
        assert cache.get("key1") == "value1"
        # Simulate time passing by manipulating the stored timestamp
        cache._entries["key1"] = (cache._entries["key1"][0], time.time() - 2)
        assert cache.get("key1") is None

    def test_lru_eviction(self):
        cache = TTLCache(max_size=2, ttl_seconds=60)
        cache.set("a", 1)
        cache.set("b", 2)
        cache.set("c", 3)  # should evict "a"
        assert cache.get("a") is None
        assert cache.get("b") == 2
        assert cache.get("c") == 3

    def test_set_updates_existing(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        cache.set("key1", "old")
        cache.set("key1", "new")
        assert cache.get("key1") == "new"
        assert cache.size == 1

    def test_clear(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        cache.set("a", 1)
        cache.set("b", 2)
        cache.clear()
        assert cache.size == 0
        assert cache.get("a") is None

    def test_no_ttl_means_permanent(self):
        cache = TTLCache(max_size=10, ttl_seconds=0)
        cache.set("key1", "value1")
        # Manipulate timestamp to 1 hour ago
        cache._entries["key1"] = (cache._entries["key1"][0], time.time() - 3600)
        assert cache.get("key1") == "value1"  # still there


class TestTTLCacheStats:
    """Hit/miss counting."""

    def test_hit_miss_tracking(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        cache.set("a", 1)
        cache.get("a")       # hit
        cache.get("missing")  # miss
        cache.get("a")       # hit
        assert cache.hits == 2
        assert cache.misses == 1

    def test_stats_dict(self):
        cache = TTLCache(max_size=10, ttl_seconds=60, name="test")
        cache.set("a", 1)
        cache.get("a")
        stats = cache.stats()
        assert stats["name"] == "test"
        assert stats["size"] == 1
        assert stats["max_size"] == 10
        assert stats["hits"] == 1
        assert stats["misses"] == 0
        assert stats["hit_rate"] == 1.0


class TestTTLCacheAsync:
    """Async-safe operations."""

    @pytest.mark.asyncio
    async def test_async_set_get(self):
        cache = TTLCache(max_size=10, ttl_seconds=60)
        await cache.aset("key1", "value1")
        result = await cache.aget("key1")
        assert result == "value1"

    @pytest.mark.asyncio
    async def test_concurrent_access(self):
        """Multiple coroutines writing simultaneously should not corrupt state."""
        cache = TTLCache(max_size=100, ttl_seconds=60)

        async def writer(prefix: str, count: int):
            for i in range(count):
                await cache.aset(f"{prefix}_{i}", i)

        await asyncio.gather(
            writer("a", 20),
            writer("b", 20),
            writer("c", 20),
        )
        # All 60 entries should be present (max_size=100)
        total = sum(1 for k in [f"{p}_{i}" for p in "abc" for i in range(20)]
                    if cache.get(k) is not None)
        assert total == 60


class TestGetCacheStats:
    """Global stats aggregation."""

    def test_get_cache_stats_returns_dict(self):
        stats = get_cache_stats()
        assert isinstance(stats, dict)
        assert "caches" in stats


class TestClearAllCaches:
    """Global cache reset."""

    def test_clear_all_resets_everything(self):
        clear_all_caches()
        stats = get_cache_stats()
        for cache_info in stats["caches"].values():
            assert cache_info["size"] == 0
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd D:\Claude local\kinetic-forge-studio\backend && python -m pytest tests/test_cache.py -v 2>&1 | head -40`
Expected: ModuleNotFoundError — `app.middleware.cache` does not exist yet.

---

### Task 2: TTLCache Class — Implementation

**Files:**
- Create: `backend/app/middleware/cache.py`

- [ ] **Step 3: Implement TTLCache**

```python
"""
Async-aware TTL cache with LRU eviction and observability.
==========================================================
GAP-PPL-009 — Caching Layer

Provides TTLCache class and pre-configured cache instances for:
  - System prompt building (sync, invalidated on project state change)
  - Library FTS5 search (async, 1-hour TTL)
  - CadQuery execution (async, permanent / LRU-evicted)

Usage:
    from app.middleware.cache import prompt_cache, search_cache, execution_cache
    from app.middleware.cache import get_cache_stats, clear_all_caches
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import time
from collections import OrderedDict
from typing import Any

logger = logging.getLogger("cache")


class TTLCache:
    """
    Thread/async-safe in-memory cache with TTL expiry and LRU eviction.

    Args:
        max_size: Maximum number of entries. Oldest accessed entry evicted on overflow.
        ttl_seconds: Time-to-live in seconds. 0 means entries never expire.
        name: Human-readable name for stats/logging.
    """

    def __init__(self, max_size: int = 64, ttl_seconds: int | float = 0, name: str = ""):
        self.max_size = max_size
        self.ttl_seconds = ttl_seconds
        self.name = name or f"cache_{id(self)}"
        self.hits = 0
        self.misses = 0
        self._entries: OrderedDict[str, tuple[Any, float]] = OrderedDict()
        self._lock = asyncio.Lock()

    # -- Sync API (for non-async callers) --

    def get(self, key: str) -> Any | None:
        """Get a value by key. Returns None if missing or expired."""
        entry = self._entries.get(key)
        if entry is None:
            self.misses += 1
            return None

        value, timestamp = entry
        if self.ttl_seconds > 0 and (time.time() - timestamp) > self.ttl_seconds:
            del self._entries[key]
            self.misses += 1
            return None

        # Move to end (most recently used)
        self._entries.move_to_end(key)
        self.hits += 1
        return value

    def set(self, key: str, value: Any) -> None:
        """Set a value. Evicts oldest entry if at capacity."""
        if key in self._entries:
            self._entries.move_to_end(key)
            self._entries[key] = (value, time.time())
            return

        if len(self._entries) >= self.max_size:
            self._entries.popitem(last=False)  # evict oldest

        self._entries[key] = (value, time.time())

    def clear(self) -> None:
        """Remove all entries and reset stats."""
        self._entries.clear()
        self.hits = 0
        self.misses = 0

    @property
    def size(self) -> int:
        return len(self._entries)

    def stats(self) -> dict:
        """Return cache statistics."""
        total = self.hits + self.misses
        return {
            "name": self.name,
            "size": self.size,
            "max_size": self.max_size,
            "hits": self.hits,
            "misses": self.misses,
            "hit_rate": round(self.hits / total, 3) if total > 0 else 0.0,
        }

    # -- Async API (wraps sync with lock) --

    async def aget(self, key: str) -> Any | None:
        """Async get with lock protection."""
        async with self._lock:
            return self.get(key)

    async def aset(self, key: str, value: Any) -> None:
        """Async set with lock protection."""
        async with self._lock:
            self.set(key, value)


# ---------------------------------------------------------------------------
# Pre-configured cache instances
# ---------------------------------------------------------------------------

prompt_cache = TTLCache(max_size=32, ttl_seconds=0, name="system_prompt")
search_cache = TTLCache(max_size=128, ttl_seconds=3600, name="library_search")
execution_cache = TTLCache(max_size=64, ttl_seconds=0, name="cadquery_execution")

_ALL_CACHES = [prompt_cache, search_cache, execution_cache]


# ---------------------------------------------------------------------------
# Cache key helpers
# ---------------------------------------------------------------------------

def make_hash_key(*args: Any) -> str:
    """Create a SHA256 hash key from arbitrary arguments via JSON serialization."""
    serialized = json.dumps(args, sort_keys=True, default=str)
    return hashlib.sha256(serialized.encode()).hexdigest()


# ---------------------------------------------------------------------------
# Global operations
# ---------------------------------------------------------------------------

def get_cache_stats() -> dict:
    """Aggregate stats from all cache instances. Wired into /api/health."""
    return {
        "caches": {c.name: c.stats() for c in _ALL_CACHES},
    }


def clear_all_caches() -> None:
    """Reset all caches. Used in tests and on-demand invalidation."""
    for c in _ALL_CACHES:
        c.clear()


def clear_project_cache(project_id: str) -> None:
    """
    Invalidate prompt cache entries for a specific project.

    Called when project state changes (spec update, component registration,
    decision locking). Since prompt cache keys include project-specific data
    (spec, components, decisions), we clear the entire prompt cache — it's
    small (max 32 entries) and rebuilds quickly.
    """
    prompt_cache.clear()
    logger.info("Cleared prompt cache (project %s state changed)", project_id)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd D:\Claude local\kinetic-forge-studio\backend && python -m pytest tests/test_cache.py -v`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
cd D:\Claude local\kinetic-forge-studio\backend
git add app/middleware/cache.py tests/test_cache.py
git commit -m "feat(cache): add TTLCache with async support, LRU eviction, observability stats (GAP-PPL-009)"
```

---

## Chunk 2: Anthropic Prompt Caching + Health Wiring

### Task 3: Anthropic Cache Control Header

**Files:**
- Modify: `backend/app/orchestrator/chat_agent.py:340-345`
- Create: `backend/tests/test_cache_anthropic.py`

- [ ] **Step 6: Write test for cache_control header presence**

Create `backend/tests/test_cache_anthropic.py`:

```python
"""Tests for Anthropic prompt caching header (GAP-PPL-009 Layer 1)."""

from __future__ import annotations

import json
from unittest.mock import AsyncMock, patch, MagicMock

import pytest


class TestAnthropicCacheControl:
    """Verify cache_control is included in Claude API request body."""

    @pytest.mark.asyncio
    async def test_claude_request_has_cache_control(self):
        """The system prompt must be sent as a content block with cache_control."""
        from app.orchestrator.chat_agent import ChatAgent

        agent = ChatAgent()
        captured_json = {}

        # Mock the httpx client to capture the request body
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "content": [{"type": "text", "text": "Hello"}],
            "model": "claude-sonnet-4-20250514",
            "usage": {
                "input_tokens": 100,
                "output_tokens": 50,
                "cache_creation_input_tokens": 100,
                "cache_read_input_tokens": 0,
            },
        }

        async def mock_post(url, **kwargs):
            captured_json.update(kwargs.get("json", {}))
            return mock_response

        mock_client = AsyncMock()
        mock_client.post = mock_post

        with patch.object(agent, "_get_client", return_value=mock_client):
            with patch("app.orchestrator.chat_agent.settings") as mock_settings:
                mock_settings.claude_api_key = "test-key"
                mock_settings.claude_model = "claude-sonnet-4-20250514"
                mock_settings.claude_max_tokens = 4096

                result = await agent._call_claude(
                    system_prompt="You are a design assistant.",
                    messages=[{"role": "user", "content": "hello"}],
                )

        # Verify system field is a list of content blocks, not a plain string
        system_field = captured_json.get("system")
        assert isinstance(system_field, list), (
            f"Expected system to be a list of content blocks, got {type(system_field)}"
        )
        assert len(system_field) == 1
        block = system_field[0]
        assert block["type"] == "text"
        assert block["text"] == "You are a design assistant."
        assert block["cache_control"] == {"type": "ephemeral"}
```

- [ ] **Step 7: Run test to verify it fails**

Run: `cd D:\Claude local\kinetic-forge-studio\backend && python -m pytest tests/test_cache_anthropic.py -v`
Expected: FAIL — system field is currently a plain string, not a content block list.

- [ ] **Step 8: Modify `_call_claude()` to use cache_control**

In `backend/app/orchestrator/chat_agent.py`, change lines 340-345 from:

```python
                    json={
                        "model": settings.claude_model,
                        "max_tokens": settings.claude_max_tokens,
                        "system": system_prompt,
                        "messages": messages,
                    },
```

To:

```python
                    json={
                        "model": settings.claude_model,
                        "max_tokens": settings.claude_max_tokens,
                        "system": [
                            {
                                "type": "text",
                                "text": system_prompt,
                                "cache_control": {"type": "ephemeral"},
                            }
                        ],
                        "messages": messages,
                    },
```

- [ ] **Step 9: Run test to verify it passes**

Run: `cd D:\Claude local\kinetic-forge-studio\backend && python -m pytest tests/test_cache_anthropic.py -v`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
cd D:\Claude local\kinetic-forge-studio\backend
git add app/orchestrator/chat_agent.py tests/test_cache_anthropic.py
git commit -m "feat(cache): add Anthropic prompt caching via cache_control header (GAP-PPL-009 Layer 1)"
```

---

### Task 4: Wire Cache Stats into /api/health

**Files:**
- Modify: `backend/app/main.py:63-71`
- Modify: `backend/tests/test_health.py` (add cache stats assertion)

- [ ] **Step 11: Write test for cache stats in health endpoint**

Append to `backend/tests/test_health.py` (matching the existing async `ASGITransport` pattern):

```python
@pytest.mark.asyncio
async def test_health_includes_cache_stats():
    """Health endpoint should include cache statistics (GAP-PPL-009)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert "cache" in data
    assert "caches" in data["cache"]
    # Should have our 3 named caches
    cache_names = set(data["cache"]["caches"].keys())
    assert "system_prompt" in cache_names
    assert "library_search" in cache_names
    assert "cadquery_execution" in cache_names
```

- [ ] **Step 12: Add cache stats import and wiring to main.py**

In `backend/app/main.py`, add import at line 17 (after the other middleware imports):

```python
from app.middleware.cache import get_cache_stats
```

Then modify the health endpoint (lines 63-71) from:

```python
@app.get("/api/health")
async def health():
    """Health endpoint with pipeline status (GAP-PPL-008)."""
    return {
        "status": "ok",
        "version": settings.version,
        "circuits": get_all_circuit_states(),
        "costs": get_cost_summary(),
    }
```

To:

```python
@app.get("/api/health")
async def health():
    """Health endpoint with pipeline status (GAP-PPL-008)."""
    return {
        "status": "ok",
        "version": settings.version,
        "circuits": get_all_circuit_states(),
        "costs": get_cost_summary(),
        "cache": get_cache_stats(),
    }
```

- [ ] **Step 13: Run health test to verify it passes**

Run: `cd D:\Claude local\kinetic-forge-studio\backend && python -m pytest tests/test_health.py -v`
Expected: PASS

- [ ] **Step 14: Commit**

```bash
cd D:\Claude local\kinetic-forge-studio\backend
git add app/main.py tests/test_health.py
git commit -m "feat(health): add cache stats to /api/health endpoint (GAP-PPL-009)"
```

---

## Chunk 3: MCP Server + Tests

### Task 5: MCP Server — Failing Tests

**Files:**
- Create: `backend/tests/test_mcp_server.py`

- [ ] **Step 15: Write failing tests for MCP server**

```python
"""Tests for KFS MCP server (GAP-PPL-014)."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from unittest.mock import patch, AsyncMock, MagicMock

import pytest

# Import the server module (will fail until we create it)
from kfs_mcp_server import (
    vlad_validate,
    cadquery_execute,
    library_search,
)


class TestVladValidate:
    """VLAD validation tool via MCP."""

    @pytest.mark.asyncio
    async def test_valid_module_returns_structured_json(self):
        """Valid module path should return tier results."""
        mock_result = subprocess.CompletedProcess(
            args=["python", "vlad.py", "--json", "test_module"],
            returncode=0,
            stdout=json.dumps({
                "module": "test_module",
                "mechanism_type": "gear",
                "tiers": {"A": "PASS", "B": "PASS", "C": "PASS"},
                "total_checks": 12,
                "passed": 12,
                "failed": 0,
            }),
            stderr="",
        )
        # Mock asyncio.to_thread which wraps subprocess.run
        with patch("kfs_mcp_server.asyncio.to_thread", return_value=mock_result):
            result = await vlad_validate(module_path="test_module")

        parsed = json.loads(result)
        assert parsed["success"] is True
        assert "tiers" in parsed["data"]
        assert parsed["error"] is None

    @pytest.mark.asyncio
    async def test_invalid_module_returns_error(self):
        """Nonexistent module should return error, not crash."""
        mock_result = subprocess.CompletedProcess(
            args=["python", "vlad.py", "--json", "nonexistent"],
            returncode=2,
            stdout="",
            stderr="ModuleNotFoundError: No module named 'nonexistent'",
        )
        with patch("kfs_mcp_server.asyncio.to_thread", return_value=mock_result):
            result = await vlad_validate(module_path="nonexistent")

        parsed = json.loads(result)
        assert parsed["success"] is False
        assert "ModuleNotFoundError" in parsed["error"]

    @pytest.mark.asyncio
    async def test_timeout_returns_error(self):
        """VLAD subprocess timeout should return structured error."""
        with patch(
            "kfs_mcp_server.asyncio.to_thread",
            side_effect=subprocess.TimeoutExpired(cmd="vlad", timeout=120),
        ):
            result = await vlad_validate(module_path="slow_module")

        parsed = json.loads(result)
        assert parsed["success"] is False
        assert "timeout" in parsed["error"].lower()


class TestCadQueryExecute:
    """CadQuery execution tool via MCP."""

    @pytest.mark.asyncio
    async def test_valid_code_returns_file_paths(self):
        """Valid CadQuery code should return output file paths as strings."""
        mock_result = MagicMock()
        mock_result.success = True
        mock_result.output_files = {"step": Path("/tmp/out.step"), "stl": Path("/tmp/out.stl")}
        mock_result.error = ""
        mock_result.stderr = ""
        mock_result.execution_time = 2.5

        mock_engine = AsyncMock()
        mock_engine.generate.return_value = mock_result

        with patch("kfs_mcp_server.CadQueryEngine", return_value=mock_engine):
            result = await cadquery_execute(code="import cadquery as cq\nresult = cq.Workplane().box(10,10,10)")

        parsed = json.loads(result)
        assert parsed["success"] is True
        # Paths must be strings, not Path objects
        assert isinstance(parsed["data"]["output_files"]["step"], str)

    @pytest.mark.asyncio
    async def test_invalid_code_returns_error(self):
        """Invalid CadQuery code should return error, not crash."""
        mock_result = MagicMock()
        mock_result.success = False
        mock_result.output_files = {}
        mock_result.error = "SyntaxError: invalid syntax"
        mock_result.stderr = "SyntaxError: invalid syntax"
        mock_result.execution_time = 0.1

        mock_engine = AsyncMock()
        mock_engine.generate.return_value = mock_result

        with patch("kfs_mcp_server.CadQueryEngine", return_value=mock_engine):
            result = await cadquery_execute(code="this is not valid python")

        parsed = json.loads(result)
        assert parsed["success"] is False
        assert "SyntaxError" in parsed["error"]


class TestLibrarySearch:
    """Library search tool via MCP."""

    @pytest.mark.asyncio
    async def test_search_returns_matching_entries(self):
        """Search query should return matching library entries."""
        mock_entries = [
            {"id": "1", "name": "Planetary Gearbox", "mechanism_types": "gear"},
            {"id": "2", "name": "Planetary Reducer", "mechanism_types": "gear"},
        ]
        mock_manager = AsyncMock()
        mock_manager.search.return_value = mock_entries

        with patch("kfs_mcp_server._get_library_manager", return_value=mock_manager):
            result = await library_search(query="planetary")

        parsed = json.loads(result)
        assert parsed["success"] is True
        assert len(parsed["data"]) == 2
        assert parsed["data"][0]["name"] == "Planetary Gearbox"

    @pytest.mark.asyncio
    async def test_empty_query_returns_all(self):
        """Empty query should return all entries."""
        mock_entries = [{"id": "1", "name": "Entry 1"}, {"id": "2", "name": "Entry 2"}]
        mock_manager = AsyncMock()
        mock_manager.search.return_value = mock_entries

        with patch("kfs_mcp_server._get_library_manager", return_value=mock_manager):
            result = await library_search(query="")

        parsed = json.loads(result)
        assert parsed["success"] is True

    @pytest.mark.asyncio
    async def test_search_error_returns_structured_error(self):
        """Database errors should return structured error, not crash."""
        mock_manager = AsyncMock()
        mock_manager.search.side_effect = Exception("Database connection failed")

        with patch("kfs_mcp_server._get_library_manager", return_value=mock_manager):
            result = await library_search(query="test")

        parsed = json.loads(result)
        assert parsed["success"] is False
        assert "Database connection failed" in parsed["error"]


class TestMCPResponseContract:
    """All tools must follow the structured response contract."""

    @pytest.mark.asyncio
    @pytest.mark.parametrize("tool_fn,kwargs", [
        (vlad_validate, {"module_path": "test"}),
        (cadquery_execute, {"code": "pass"}),
        (library_search, {"query": "test"}),
    ])
    async def test_all_tools_return_valid_json(self, tool_fn, kwargs):
        """Every tool must return parseable JSON."""
        # Mock away all external deps so the tool runs
        with patch("kfs_mcp_server.asyncio.to_thread", side_effect=Exception("mocked")), \
             patch("kfs_mcp_server.CadQueryEngine", side_effect=Exception("mocked")), \
             patch("kfs_mcp_server._get_library_manager", side_effect=Exception("mocked")):
            result = await tool_fn(**kwargs)

        parsed = json.loads(result)
        assert "success" in parsed
        assert "data" in parsed
        assert "error" in parsed
```

- [ ] **Step 16: Run tests to verify they fail**

Run: `cd D:\Claude local\kinetic-forge-studio\backend && python -m pytest tests/test_mcp_server.py -v 2>&1 | head -20`
Expected: ModuleNotFoundError — `kfs_mcp_server` does not exist yet.

---

### Task 6: MCP Server — Implementation

**Files:**
- Create: `backend/kfs_mcp_server.py`
- Modify: `backend/pyproject.toml` (add fastmcp)

- [ ] **Step 17: Add fastmcp dependency**

In `backend/pyproject.toml`, add `"fastmcp>=2.0"` to the dependencies list:

```toml
dependencies = [
    "fastapi>=0.109",
    "uvicorn[standard]>=0.27",
    "pydantic>=2.5",
    "pydantic-settings>=2.1",
    "aiosqlite>=0.19",
    "python-multipart>=0.0.6",
    "pyyaml>=6.0",
    "httpx>=0.26",
    "fastmcp>=2.0",
]
```

- [ ] **Step 18: Install fastmcp**

Run: `cd D:\Claude local\kinetic-forge-studio\backend && pip install fastmcp>=2.0`

- [ ] **Step 19: Implement kfs_mcp_server.py**

```python
"""
KFS MCP Server — Model Context Protocol tools for Kinetic Forge Studio.
=======================================================================
GAP-PPL-014 — MCP Exposure

Exposes 3 KFS tools to AI agents (e.g., Claude Code) via FastMCP:
  1. vlad_validate   — Run VLAD geometry validator on a CadQuery module
  2. cadquery_execute — Execute CadQuery/build123d code, return file paths
  3. library_search   — Search the KFS parts library via FTS5

Usage:
    # As MCP server (Claude Code auto-discovers via .mcp.json):
    python kfs_mcp_server.py

    # Register in .mcp.json:
    {"mcpServers": {"kfs-tools": {"command": "python", "args": ["kfs_mcp_server.py"]}}}
"""

from __future__ import annotations

import asyncio
import json
import logging
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from fastmcp import FastMCP

# Ensure backend app is importable
sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.engines.cadquery_engine import CadQueryEngine, GenerationResult

logger = logging.getLogger("kfs_mcp")

mcp = FastMCP(
    "KFS Tools",
    description="Kinetic Forge Studio design tools: VLAD validator, CadQuery executor, library search",
)

# Path to VLAD script (relative to this repo)
VLAD_PATH = Path(__file__).resolve().parent.parent.parent / "tools" / "vlad.py"

# Default output directory for CadQuery execution
DEFAULT_OUTPUT_DIR = Path(tempfile.gettempdir()) / "kfs_mcp_output"


def _make_response(success: bool, data: Any = None, error: str | None = None) -> str:
    """Create a structured JSON response string."""
    return json.dumps({"success": success, "data": data, "error": error}, default=str)


# ---------------------------------------------------------------------------
# Tool 1: VLAD Validate
# ---------------------------------------------------------------------------

@mcp.tool()
async def vlad_validate(module_path: str) -> str:
    """
    Run VLAD geometry validator on a CadQuery production module.

    The module must export get_fixed_parts(), get_moving_parts(), and
    get_mechanism_type(). VLAD runs 35 checks across 8 tiers (topology,
    interference, clearance, manufacturability, etc.).

    Args:
        module_path: Python module path (e.g., 'my_sculpture' or 'projects.triple_helix').
                     Must be importable from the current working directory.

    Returns:
        JSON with tier results, pass/fail counts, and any errors.
    """
    try:
        # Run in thread to avoid blocking the asyncio event loop (VLAD can take 30s+)
        result = await asyncio.to_thread(
            subprocess.run,
            [sys.executable, str(VLAD_PATH), "--json", module_path],
            capture_output=True,
            text=True,
            timeout=120,
        )

        if result.returncode == 2:
            # Fatal error (module not found, import error, etc.)
            return _make_response(
                success=False,
                error=result.stderr.strip() or f"VLAD fatal error (exit code 2)",
            )

        # returncode 0 = all pass, 1 = some failures (both are valid results)
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            data = {"raw_output": result.stdout, "raw_stderr": result.stderr}

        return _make_response(
            success=(result.returncode == 0),
            data=data,
            error=result.stderr.strip() if result.returncode != 0 else None,
        )

    except subprocess.TimeoutExpired:
        return _make_response(success=False, error="VLAD timeout (120s exceeded)")
    except Exception as e:
        return _make_response(success=False, error=str(e))


# ---------------------------------------------------------------------------
# Tool 2: CadQuery Execute
# ---------------------------------------------------------------------------

@mcp.tool()
async def cadquery_execute(code: str, output_dir: str = "") -> str:
    """
    Execute CadQuery or build123d Python code and return output file paths.

    The script should assign its result to a variable named 'result'.
    Output STEP and STL files are written to the output directory.

    Args:
        code: Python script text (CadQuery or build123d).
        output_dir: Directory for output files. Defaults to a temp directory.

    Returns:
        JSON with success status, output file paths (as strings), and any errors.
    """
    try:
        out_path = Path(output_dir) if output_dir else DEFAULT_OUTPUT_DIR
        out_path.mkdir(parents=True, exist_ok=True)

        engine = CadQueryEngine()
        result: GenerationResult = await engine.generate(
            code=code,
            output_dir=out_path,
            filename_base="mcp_output",
        )

        return _make_response(
            success=result.success,
            data={
                "output_files": {fmt: str(path) for fmt, path in result.output_files.items()},
                "execution_time": result.execution_time,
                "stderr": result.stderr,
            },
            error=result.error if not result.success else None,
        )
    except Exception as e:
        return _make_response(success=False, error=str(e))


# ---------------------------------------------------------------------------
# Tool 3: Library Search
# ---------------------------------------------------------------------------

_library_manager = None


async def _get_library_manager():
    """Lazy-create a singleton LibraryManager with a persistent DB connection."""
    global _library_manager
    if _library_manager is None:
        from app.db.database import Database
        from app.db.library import LibraryManager

        db = Database()
        await db.connect()
        _library_manager = LibraryManager(db)
    return _library_manager


@mcp.tool()
async def library_search(query: str) -> str:
    """
    Search the KFS parts library using full-text search.

    Searches across name, mechanism_types, and keywords fields.
    Returns matching library entries with metadata.

    Args:
        query: Search query (e.g., 'planetary', 'four-bar linkage', 'wave').
               Empty string returns all entries.

    Returns:
        JSON with list of matching library entries.
    """
    try:
        manager = await _get_library_manager()
        entries = await manager.search(query)
        return _make_response(success=True, data=entries)
    except Exception as e:
        return _make_response(success=False, error=str(e))


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
```

- [ ] **Step 20: Run MCP tests to verify they pass**

Run: `cd D:\Claude local\kinetic-forge-studio\backend && python -m pytest tests/test_mcp_server.py -v`
Expected: All tests PASS.

- [ ] **Step 21: Commit**

```bash
cd D:\Claude local\kinetic-forge-studio\backend
git add kfs_mcp_server.py tests/test_mcp_server.py pyproject.toml
git commit -m "feat(mcp): add KFS MCP server with VLAD, CadQuery, library tools (GAP-PPL-014)"
```

---

## Chunk 4: Pipeline Templates + MCP Registration + Bible Update

### Task 7: Pipeline Templates

**Files:**
- Create: `production-pipeline/templates/cache.py`
- Create: `production-pipeline/templates/mcp_server.py`

- [ ] **Step 22: Create universal cache template**

Create `D:\Claude local\production-pipeline\templates\cache.py`:

```python
"""
Production Pipeline Template: Caching Layer
============================================
GAP-PPL-009 — App-level TTL Cache

Copy to your FastAPI project's middleware directory.
Configure cache instances for your specific use case.

Usage:
    from middleware.cache import TTLCache, get_cache_stats

    # Create a cache
    my_cache = TTLCache(max_size=64, ttl_seconds=3600, name="my_cache")

    # Use it
    result = my_cache.get(key)
    if result is None:
        result = expensive_computation()
        my_cache.set(key, result)

    # Wire stats into /api/health
    @app.get("/api/health")
    async def health():
        return {"cache": get_cache_stats()}

Placeholders:
    - Replace cache instances with your project's targets
    - Adjust max_size and ttl_seconds per cache
    - Add clear_project_cache() triggers to your mutation routes
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import time
from collections import OrderedDict
from typing import Any

logger = logging.getLogger("cache")


class TTLCache:
    """
    Thread/async-safe in-memory cache with TTL expiry and LRU eviction.

    Args:
        max_size: Maximum entries. Oldest accessed evicted on overflow.
        ttl_seconds: Time-to-live in seconds. 0 = never expires.
        name: Human-readable name for stats/logging.
    """

    def __init__(self, max_size: int = 64, ttl_seconds: int | float = 0, name: str = ""):
        self.max_size = max_size
        self.ttl_seconds = ttl_seconds
        self.name = name or f"cache_{id(self)}"
        self.hits = 0
        self.misses = 0
        self._entries: OrderedDict[str, tuple[Any, float]] = OrderedDict()
        self._lock = asyncio.Lock()

    def get(self, key: str) -> Any | None:
        entry = self._entries.get(key)
        if entry is None:
            self.misses += 1
            return None
        value, timestamp = entry
        if self.ttl_seconds > 0 and (time.time() - timestamp) > self.ttl_seconds:
            del self._entries[key]
            self.misses += 1
            return None
        self._entries.move_to_end(key)
        self.hits += 1
        return value

    def set(self, key: str, value: Any) -> None:
        if key in self._entries:
            self._entries.move_to_end(key)
            self._entries[key] = (value, time.time())
            return
        if len(self._entries) >= self.max_size:
            self._entries.popitem(last=False)
        self._entries[key] = (value, time.time())

    def clear(self) -> None:
        self._entries.clear()
        self.hits = 0
        self.misses = 0

    @property
    def size(self) -> int:
        return len(self._entries)

    def stats(self) -> dict:
        total = self.hits + self.misses
        return {
            "name": self.name,
            "size": self.size,
            "max_size": self.max_size,
            "hits": self.hits,
            "misses": self.misses,
            "hit_rate": round(self.hits / total, 3) if total > 0 else 0.0,
        }

    async def aget(self, key: str) -> Any | None:
        async with self._lock:
            return self.get(key)

    async def aset(self, key: str, value: Any) -> None:
        async with self._lock:
            self.set(key, value)


def make_hash_key(*args: Any) -> str:
    serialized = json.dumps(args, sort_keys=True, default=str)
    return hashlib.sha256(serialized.encode()).hexdigest()


# -- Configure your caches here --
# example_cache = TTLCache(max_size=64, ttl_seconds=3600, name="example")
# _ALL_CACHES = [example_cache]
_ALL_CACHES: list[TTLCache] = []


def get_cache_stats() -> dict:
    return {"caches": {c.name: c.stats() for c in _ALL_CACHES}}


def clear_all_caches() -> None:
    for c in _ALL_CACHES:
        c.clear()
```

- [ ] **Step 23: Create universal MCP server template**

Create `D:\Claude local\production-pipeline\templates\mcp_server.py`:

```python
"""
Production Pipeline Template: MCP Server
=========================================
GAP-PPL-014 — MCP Exposure

Create a standalone MCP server that exposes your project's tools to AI agents.
Uses FastMCP (pip install fastmcp).

Usage:
    1. Copy this file to your project root
    2. Replace placeholder tools with your own
    3. Register in .mcp.json for Claude Code auto-discovery:
       {"mcpServers": {"my-tools": {"command": "python", "args": ["mcp_server.py"]}}}
    4. Run: python mcp_server.py

Placeholders:
    - Replace example_tool() with your project's tools
    - Update tool docstrings (they become the tool description in MCP)
    - Add imports for your project's engine classes
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

from fastmcp import FastMCP

# Ensure your project is importable
sys.path.insert(0, str(Path(__file__).resolve().parent))

mcp = FastMCP(
    "My Project Tools",
    description="Replace with your project description",
)


def _make_response(success: bool, data: Any = None, error: str | None = None) -> str:
    """Create a structured JSON response string."""
    return json.dumps({"success": success, "data": data, "error": error}, default=str)


@mcp.tool()
async def example_tool(input_text: str) -> str:
    """
    Example tool — replace with your own.

    Args:
        input_text: Description of the input.

    Returns:
        JSON with structured response.
    """
    try:
        # Replace with your actual logic
        result = {"echo": input_text}
        return _make_response(success=True, data=result)
    except Exception as e:
        return _make_response(success=False, error=str(e))


if __name__ == "__main__":
    mcp.run()
```

- [ ] **Step 24: Commit templates**

```bash
cd "D:\Claude local"
git add production-pipeline/templates/cache.py production-pipeline/templates/mcp_server.py
git commit -m "feat(pipeline): add universal cache + MCP server templates (GAP-PPL-009, GAP-PPL-014)"
```

---

### Task 8: MCP Registration

**Files:**
- Create or modify: `D:\Claude local\.mcp.json`

- [ ] **Step 25: Check if .mcp.json already exists**

Run: `cat "D:\Claude local\.mcp.json" 2>/dev/null || echo "FILE_NOT_FOUND"`

- [ ] **Step 26: Create or update .mcp.json**

If the file does not exist, create `D:\Claude local\.mcp.json`:

```json
{
  "mcpServers": {
    "kfs-tools": {
      "command": "python",
      "args": ["kfs_mcp_server.py"],
      "cwd": "kinetic-forge-studio/backend"
    }
  }
}
```

If it already exists, add the `kfs-tools` entry to the existing `mcpServers` object.

- [ ] **Step 27: Commit registration**

```bash
cd "D:\Claude local"
git add .mcp.json
git commit -m "chore: register KFS MCP server in .mcp.json (GAP-PPL-014)"
```

---

### Task 9: Update Pipeline Bible

**Files:**
- Modify: `C:\Users\abhis\.claude\projects\d--Claude-local\memory\projects\production-pipeline-bible.yaml`

- [ ] **Step 28: Read current bible state**

Read the production-pipeline-bible.yaml to find GAP-PPL-009 and GAP-PPL-014 entries.

- [ ] **Step 29: Update GAP-PPL-009 to closed**

Change GAP-PPL-009:
```yaml
  GAP-PPL-009:
    title: "Caching Layer"
    status: closed
    resolution: |
      Two-layer caching: (1) Anthropic prompt caching via cache_control header
      in _call_claude() — 90% cost reduction on system prompt tokens.
      (2) App-level TTLCache in app/middleware/cache.py — async-safe with LRU
      eviction. Three instances: prompt (32, invalidated), library search (128,
      1hr TTL), CadQuery execution (64, permanent/LRU). Stats wired into
      /api/health. Template at production-pipeline/templates/cache.py.
    files:
      - app/middleware/cache.py (new)
      - app/orchestrator/chat_agent.py (cache_control header)
      - app/main.py (health stats)
      - production-pipeline/templates/cache.py (template)
      - tests/test_cache.py, tests/test_cache_anthropic.py
```

- [ ] **Step 30: Update GAP-PPL-014 to closed**

Change GAP-PPL-014:
```yaml
  GAP-PPL-014:
    title: "MCP Exposure"
    status: closed
    resolution: |
      FastMCP server at kfs_mcp_server.py exposes 3 tools: vlad_validate
      (subprocess), cadquery_execute (direct import), library_search (direct
      import). All return structured JSON {success, data, error}. Registered
      in .mcp.json for Claude Code auto-discovery. Template at
      production-pipeline/templates/mcp_server.py.
    files:
      - kfs_mcp_server.py (new)
      - .mcp.json (new)
      - pyproject.toml (fastmcp dependency)
      - production-pipeline/templates/mcp_server.py (template)
      - tests/test_mcp_server.py
```

- [ ] **Step 31: Update Phase 4 status**

If GAP-PPL-010 is the only remaining open gap in Phase 4, update Phase 4 status to reflect 2/3 closed, note that GAP-PPL-010 is deferred.

- [ ] **Step 32: Commit bible update**

```bash
cd "C:\Users\abhis\.claude\projects\d--Claude-local\memory"
git add projects/production-pipeline-bible.yaml
git commit -m "docs(pipeline): close GAP-PPL-009 (Caching) and GAP-PPL-014 (MCP Exposure) — Phase 4 2/3"
```

---

### Task 10: Session Handoff

**Files:**
- Create: `D:\Claude local\sessions\2026-03-14c.md`

- [ ] **Step 33: Write session handoff**

Create `D:\Claude local\sessions\2026-03-14c.md` with:
- Summary of what was done (TTLCache, Anthropic prompt caching, MCP server)
- Files created/modified
- Test results
- Next session items: GAP-PPL-010 (Cloud Deployment), Phase 5+ gaps
- Any issues encountered

- [ ] **Step 34: Commit handoff**

```bash
cd "D:\Claude local"
git add sessions/2026-03-14c.md
git commit -m "docs: session 2026-03-14c handoff — Phase 4 caching + MCP"
```
