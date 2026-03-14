# Phase 4 Design: Caching Layer + MCP Exposure

**Date:** 2026-03-14
**Gaps:** GAP-PPL-009 (Caching Layer), GAP-PPL-014 (MCP Exposure)
**Scope:** Production Pipeline Phase 4 (Connected)
**GAP-PPL-010 (Cloud Deployment):** Deferred to a future session (D3 difficulty)

## Decisions

- **Caching:** Both Anthropic prompt caching (cost) AND app-level caching (latency)
- **MCP:** Thin wrapper (option A) -- direct imports, not HTTP bridge
- **Deployment:** Deferred

---

## GAP-PPL-009: Caching Layer

### Problem

Every chat message rebuilds the full 60KB system prompt, re-runs FTS5 library
search, and re-executes CadQuery code even when inputs are identical. No
response caching means duplicate work on every request.

### Architecture

Two independent caching layers solving different problems:

#### Layer 1: Anthropic Prompt Caching (cost reduction)

Add `cache_control: {"type": "ephemeral"}` to the system prompt block in
`_call_claude()`. Anthropic caches the system prompt server-side with a 5-minute
TTL, giving 90% cost reduction on cache hits for the system prompt tokens.

- **Where:** `app/orchestrator/chat_agent.py` `_call_claude()` -- modify the
  `system` field from a plain string to a content block with cache_control
- **Scope:** Claude API calls only (not Gemini/Groq/Grok)
- **Zero app-side storage** -- Anthropic manages the cache
- **Verification:** Check the API response `usage` object for
  `cache_creation_input_tokens` and `cache_read_input_tokens` fields

#### Layer 2: App-level TTLCache (latency reduction, all providers)

Custom `TTLCache` class (not `functools.lru_cache`, which does not support
async functions or unhashable arguments like dicts/lists). The TTLCache
stores results keyed by a serialized hash of the arguments.

**Async support:** Decorators for async functions `await` the result before
caching, so the cache stores the resolved value (not the coroutine object).

| Cache Target | Function | Key | TTL | Max Size |
|---|---|---|---|---|
| System prompt | `app/ai/prompt_builder.py` `build_system_prompt()` | SHA256 of JSON-serialized `(gate_level, spec, locked_decisions, component_ids, user_profile_id, library_match_ids)` | Invalidated on project state change (see below) | 32 |
| Library search | `app/db/library.py` `LibraryManager.search()` | `query.strip().lower()` | 1 hour | 128 |
| CadQuery execution | `app/engines/cadquery_engine.py` `CadQueryEngine.generate()` | SHA256 of `(code, str(output_dir), filename_base)` | Permanent (deterministic) | 64 |

**Cache key details:**

- **System prompt:** All parameters that affect the output are included in the
  key. `scad_source` is included via hash (it's file content). The key is a
  SHA256 of the JSON-serialized tuple of all arguments.
- **CadQuery execution:** Key includes `output_dir` and `filename_base` because
  the cached `GenerationResult` contains `Path` objects pointing to specific
  file locations. Same code in different directories = different cache entries.
- **Library search:** Query string is naturally normalized (lowercased, stripped).

**Cache invalidation triggers:**

- System prompt cache: Invalidated when `spec`, `locked_decisions`, or
  `components` change. Triggered by calling `clear_project_cache(project_id)`
  from: `POST /api/projects/{id}/spec`, component registration in chat route,
  and decision locking in decisions route.
- Library search cache: TTL-based (1 hour). Also cleared on library add/delete.
- CadQuery execution cache: Never invalidated (deterministic). Evicted by LRU
  when max size is reached.

**Concurrency:** TTLCache uses `asyncio.Lock` for async cache operations to
prevent thundering herd on cold cache and race conditions during invalidation.

#### What we do NOT cache

- **Conversation history** -- user-specific, always changing
- **LLM responses** -- non-deterministic by design
- **Rule99 consultant reports** -- depend on full project state
- **Component positions** -- can change mid-project

### New Files

1. **`app/middleware/cache.py`** (KFS) -- async-aware TTL cache with observability
   - `TTLCache` class: dict-based with timestamp expiry, asyncio.Lock, LRU eviction
   - `cached_prompt(fn)` -- decorator for system prompt building (sync function)
   - `cached_search(fn)` -- decorator for library FTS5 queries (async function)
   - `cached_execution(fn)` -- decorator for CadQuery subprocess calls (async function)
   - `get_cache_stats() -> dict` -- hit/miss counts, sizes, for `/health`
   - `log_cache_event(name, hit, key_hash)` -- logged to observability
   - `clear_project_cache(project_id)` -- invalidate system prompt cache entries

2. **`production-pipeline/templates/cache.py`** -- universal template
   - Same TTLCache and decorator pattern
   - Placeholder cache targets (users fill in their own)

### Modified Files

- **`app/orchestrator/chat_agent.py`** -- Add `cache_control` to `_call_claude()` system block
- **`app/ai/prompt_builder.py`** -- Wrap `build_system_prompt()` with `cached_prompt`
- **`app/db/library.py`** -- Wrap `search()` with `cached_search`
- **`app/engines/cadquery_engine.py`** -- Wrap `generate()` with `cached_execution`
- **`app/main.py`** -- Wire `get_cache_stats()` into the `health()` endpoint (line ~63)

### Verification

```
App-level cache:
  Send identical request twice.
  Verify: second call to build_system_prompt() returns in <1ms (cache hit).
  Verify: cache hit logged in observability via log_cache_event().
  Verify: get_cache_stats() shows hits > 0 in /api/health response.

Anthropic prompt cache:
  Send two Claude API requests within 5 minutes.
  Verify: second response's usage object contains cache_read_input_tokens > 0.
```

---

## GAP-PPL-014: MCP Exposure

### Problem

KFS tools (VLAD validator, CadQuery executor, library search) are only accessible
through the web app or manual CLI. Other AI agents (e.g., Claude Code) cannot
call them programmatically. MCP (Model Context Protocol) is the standard for
AI tool interop.

### Architecture

Single standalone MCP server using FastMCP, with direct Python imports of
existing KFS engine classes (thin wrapper, option A).

### Tools Exposed

| MCP Tool | Wraps | Input | Output |
|---|---|---|---|
| `vlad_validate` | `tools/vlad.py` subprocess | `module_path: str` (Python module path, e.g. `my_sculpture`) | JSON: tier results, pass/fail, errors |
| `cadquery_execute` | `CadQueryEngine.generate()` | `code: str`, `output_dir: str` (opt) | JSON: success, file paths (as strings), stderr |
| `library_search` | `LibraryManager.search()` | `query: str` | JSON: matching entries with metadata |

**VLAD input constraint:** VLAD expects a Python module path (not inline code).
The module must export `get_fixed_parts()`, `get_moving_parts()`, and
`get_mechanism_type()` functions. The MCP wrapper invokes VLAD via subprocess:
`python tools/vlad.py --json <module_path>`. Inline code is NOT supported --
use `cadquery_execute` for that, then validate the output separately.

**Path serialization:** `GenerationResult.output_files` contains `Path` objects.
The MCP wrapper converts all `Path` values to strings before returning JSON.

**Timeouts:** MCP tools use existing engine timeouts (120s for CadQuery via
subprocess, VLAD's own timeout). No additional MCP-level timeout is added.

### New Files

1. **`kinetic-forge-studio/backend/kfs_mcp_server.py`** -- MCP server
   - Uses FastMCP (`pip install fastmcp`)
   - 3 tool functions with type-annotated parameters
   - Structured JSON responses: `{"success": bool, "data": ..., "error": str|null}`
   - No raw exceptions leak through MCP

2. **`D:/Claude local/.mcp.json`** (or project-level) -- MCP registration
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

3. **`production-pipeline/templates/mcp_server.py`** -- universal template
   - FastMCP boilerplate with placeholder tools
   - Structured error handling pattern
   - Any project fills in its own tools

### Modified Files

- **`pyproject.toml`** -- Add `fastmcp` dependency

### Error Handling

Each tool returns structured JSON. Errors include:
- Tool-level errors (invalid input, missing files)
- Execution errors (subprocess timeout, CadQuery crash)
- Validation errors (VLAD tier failures -- these are NOT errors, they're results)

### Verification

```
Connect Claude Code to KFS MCP server via .mcp.json.
Run: vlad_validate with a known production module path.
Verify: VLAD tier results returned through MCP protocol as structured JSON.
Verify: library_search("planetary") returns matching entries.
Verify: cadquery_execute with simple box code returns success + file paths.
```

---

## Implementation Order

1. **GAP-PPL-009 first** -- cache.py template + KFS wiring + prompt caching headers
2. **GAP-PPL-014 second** -- kfs_mcp_server.py + template + .mcp.json registration
3. Both can be implemented by parallel agents (independent codepaths)

## Testing Strategy

- **Caching:** Unit tests for TTLCache (expiry, eviction, stats, async support,
  concurrency with asyncio.Lock). Integration test sending duplicate requests
  and asserting cache hit in observability log.
- **MCP:** Invoke each tool via FastMCP test client, assert structured JSON output.
  Test error cases (bad module path for VLAD, invalid code for CadQuery, empty
  query for library search).

## Out of Scope

- Redis (upgrade path documented but not implemented)
- HTTP bridge MCP mode (add later for deployed case)
- Cloud deployment (GAP-PPL-010 deferred)
- Additional MCP tools beyond the core 3
- Inline code support for VLAD (use cadquery_execute instead)
