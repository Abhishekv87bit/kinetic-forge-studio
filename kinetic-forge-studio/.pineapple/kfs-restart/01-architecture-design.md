# KFS v2 Restart — Stage 2: Architecture Design

**Date**: 2026-03-26
**Author**: Architecture Agent (Pineapple Pipeline Stage 2)
**Pipeline**: `.pineapple/kfs-restart/`
**Branch**: `feat/kfs-manifest-system-pipeline`

---

## 1. Module Architecture Overview

The 10 modules form three layers that build on the existing KFS codebase:

```
LAYER 3: Intelligence
  SC-06 Durga Pattern ─── SC-07 MCP Tools ─── SC-10 Observability Wiring
          │                      │
LAYER 2: Pipeline
  SC-02 Module Executor ── SC-03 VLAD Runner ── SC-08 Manifest Generator
          │                      │                      │
LAYER 1: Foundation
  SC-01 Module Manager ── SC-05 Context Persistence ── SC-09 Contract Tests
          │
LAYER 0: Rendering (parallel track)
  SC-04 Three.js Renderer Integration
```

**Key principle**: Layer 1 modules have zero dependencies on higher layers. Layer 2 modules depend only on Layer 1. Layer 3 modules compose Layer 1+2 primitives. SC-04 is a parallel frontend track with no backend layer dependencies beyond the existing viewport route.

**What already exists and MUST NOT be rebuilt**:
- `kfs_core/manifest_models.py` — Pydantic manifest models (KFSManifest, KFSObject, Geometry, etc.)
- `kfs_core/manifest_parser.py` — YAML load/save
- `kfs_core/validator/` — Semantic validation rules
- `kfs_core/schema_generator.py` — JSON Schema generation
- `kfs_cli/` — CLI with generate, validate, bake commands
- `backend/app/consultants/` — 14 consultants (physics, collision, DFM, etc.)
- `backend/app/engines/cadquery_engine.py` — CadQuery script execution
- `backend/app/middleware/observability.py` — LLM cost tracking, LangFuse integration
- `backend/app/models/component.py` — ComponentManager
- `backend/app/models/project.py` — ProjectManager
- `backend/app/db/database.py` — SQLite with aiosqlite

---

## 2. Data Flow Diagram

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                    CHAT AGENT                            │
                    │  (chat_agent.py — existing, modified to call executor)   │
                    └──────────┬──────────────────────────────────────────────┘
                               │ "generate a spur gear"
                               ▼
                    ┌──────────────────────┐
                    │   MODULE MANAGER     │  SC-01
                    │  (CRUD + versioning) │
                    │  modules table in DB │
                    └──────────┬───────────┘
                               │ module record (id, code, version)
                               ▼
                    ┌──────────────────────┐
                    │   MODULE EXECUTOR    │  SC-02
                    │  CadQueryEngine      │
                    │  subprocess sandbox  │
                    └──────┬──────┬────────┘
                           │      │
                   success │      │ failure
                           ▼      ▼
              ┌────────────────┐  ┌─────────────────┐
              │  STL + STEP    │  │  DURGA PATTERN   │ SC-06
              │  on disk       │  │  deterministic   │
              │  {project}/    │  │  repair → VLM →  │
              │   models/      │  │  LLM escalation  │
              └──────┬─────────┘  └─────────────────┘
                     │
                     ▼
              ┌────────────────┐     ┌──────────────────┐
              │  VLAD RUNNER   │ ──► │  vlad_results    │ SC-03
              │  (runs vlad.py │     │  table in DB     │
              │   in subprocess│     └──────────────────┘
              │   --json mode) │
              └──────┬─────────┘
                     │
          ┌──────────┼──────────────────────┐
          ▼          ▼                      ▼
  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐
  │  MANIFEST    │ │  CONTEXT     │ │  VIEWPORT ROUTE  │ (existing)
  │  GENERATOR   │ │  PERSISTENCE │ │  /geometry       │
  │  SC-08       │ │  SC-05       │ │  serves GLB      │
  │  .kfs.yaml   │ │  snapshots + │ │                  │
  └──────────────┘ │  decisions   │ │  SC-04: frontend │
                   └──────────────┘ │  loads real STL   │
                                    └──────────────────┘
                                             │
                                             ▼
                                    ┌──────────────────┐
                                    │  THREE.JS        │ SC-04
                                    │  Viewport3D.tsx  │
                                    │  loads GLB from  │
                                    │  /geometry route │
                                    └──────────────────┘

  CROSS-CUTTING:
  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
  │  MCP TOOLS       │  │  OBSERVABILITY   │  │  CONTRACT TESTS  │
  │  SC-07           │  │  SC-10           │  │  SC-09           │
  │  expose executor │  │  wrap all LLM    │  │  pytest suite    │
  │  + VLAD as tools │  │  calls in        │  │  real assertions │
  └──────────────────┘  │  observe_llm_call│  └──────────────────┘
                        └──────────────────┘
```

---

## 3. Per-Module Design

### SC-01: Module Manager

**Purpose**: Store, version, and retrieve CadQuery module source code in SQLite. A "module" is a Python script that defines a CadQuery component — it has parameters, source code, and a version history.

**Files to create**:
- `backend/app/models/module.py` — `ModuleManager` class

**Files to modify**:
- `backend/app/db/database.py` — Add `modules` and `module_versions` tables to `_init_tables()`
- `backend/app/routes/projects.py` — Add module CRUD endpoints (or create new route file)

**Key interfaces**:
```python
# backend/app/models/module.py

@dataclass
class Module:
    id: str                    # e.g., "spur_gear_20t"
    project_id: str
    name: str                  # human-readable: "Spur Gear 20T"
    geometry_type: str         # ADR-04: "gear", "lattice", "structural", etc.
    source_code: str           # Python/CadQuery script text
    parameters: dict           # {"module": 1.5, "teeth": 20, "height": 8}
    version: int               # auto-incrementing
    status: str                # "draft" | "valid" | "failed"
    stl_path: str | None       # path to last successful STL output
    step_path: str | None      # path to last successful STEP output
    vlad_verdict: str | None   # "PASS" | "FAIL" | None (not yet validated)
    created_at: str
    updated_at: str

class ModuleManager:
    def __init__(self, db: Database): ...
    async def create(self, project_id, name, geometry_type, source_code, parameters) -> Module
    async def get(self, project_id, module_id) -> Module
    async def list_all(self, project_id) -> list[Module]
    async def update_source(self, project_id, module_id, source_code, parameters) -> Module
    async def set_status(self, project_id, module_id, status, stl_path=None, step_path=None) -> None
    async def set_vlad_verdict(self, project_id, module_id, verdict) -> None
    async def get_version_history(self, project_id, module_id) -> list[dict]
    async def rollback(self, project_id, module_id, version) -> Module
```

**Dependencies**: `Database` (existing)
**Success criterion**: SC-01

---

### SC-02: Module Executor

**Purpose**: Execute a module's CadQuery code via the existing `CadQueryEngine`, write STL/STEP to disk, update status.

**Files to create**:
- `backend/app/services/module_executor.py`

**Key interfaces**:
```python
@dataclass
class ExecutionResult:
    success: bool
    module_id: str
    version: int
    stl_path: Path | None
    step_path: Path | None
    stdout: str
    stderr: str
    execution_time_ms: float
    error: str | None

class ModuleExecutor:
    def __init__(self, engine: CadQueryEngine, module_mgr: ModuleManager): ...
    async def execute(self, project_id, module_id, output_dir) -> ExecutionResult
    async def execute_and_validate(self, project_id, module_id, output_dir) -> ExecutionResult
```

ADR-02: if generation fails, status = "failed". No silent fallback.

**Dependencies**: SC-01 (ModuleManager), existing `CadQueryEngine`
**Success criterion**: SC-02

---

### SC-03: VLAD Runner

**Purpose**: Run `vlad.py` in subprocess, parse results, store in DB. Requires a bridge module that wraps KFS module output into VLAD's expected API (`get_fixed_parts`, `get_moving_parts`, `get_mechanism_type`).

**Files to create**:
- `backend/app/services/vlad_runner.py`
- `backend/app/services/vlad_bridge.py` — Generates temp bridge module

**Files to modify**:
- `backend/app/db/database.py` — Add `vlad_results` table
- `backend/app/config.py` — Add `vlad_script_path` setting

**Key interfaces**:
```python
@dataclass
class VladResult:
    module_id: str
    project_id: str
    verdict: str           # "PASS" | "FAIL"
    pass_count: int
    fail_count: int
    warn_count: int
    checks: list[dict]
    mechanism_type: str
    run_at: str
    execution_time_ms: float

class VladRunner:
    def __init__(self, vlad_script: Path, db: Database): ...
    async def validate(self, project_id, module_id, module_source, mechanism_type="gear", output_dir=None) -> VladResult
    async def get_latest(self, project_id, module_id) -> VladResult | None
    async def get_history(self, project_id, module_id) -> list[VladResult]
```

**Dependencies**: SC-01 (ModuleManager), external `vlad.py`
**Success criterion**: SC-03

**Risk**: HIGHEST. VLAD expects specific module API. Bridge must translate. Fallback: run topology checks only (T1-T4) which need only the STEP file.

---

### SC-04: Three.js Renderer Integration

**Purpose**: Serve per-module GLB, auto-reload viewport on new geometry, add VLAD status overlay.

**Files to modify**:
- `backend/app/routes/viewport.py` — Add `GET /modules/{module_id}/geometry`
- `frontend/src/stores/viewportStore.ts` — Add `activeModuleId`
- `frontend/src/components/Viewport3D.tsx` — Per-module geometry URL, auto-reload
- `frontend/src/stores/projectStore.ts` — Add `modules` array

**New frontend files**:
- `frontend/src/stores/moduleStore.ts` — Module state management
- `frontend/src/components/ModuleListPanel.tsx` — Sidebar module list
- `frontend/src/components/ModuleEditorPanel.tsx` — Code editor + execute/validate

**Dependencies**: SC-01 (modules in DB), existing viewport route
**Success criterion**: SC-04

---

### SC-05: Context Persistence

**Purpose**: Track module lifecycle actions for chat context. Session-level action log.

**Files to create**:
- `backend/app/models/session_context.py`

**Files to modify**:
- `backend/app/db/database.py` — Add `session_log` table
- `backend/app/orchestrator/chat_agent.py` — Add module context to prompts
- `backend/app/ai/prompt_builder.py` — Add modules section

**Key interfaces**:
```python
class SessionContextManager:
    def __init__(self, db: Database): ...
    async def log_action(self, project_id, action_type, detail) -> int
    async def get_session_summary(self, project_id, limit=50) -> list[dict]
    async def build_module_context(self, project_id) -> dict
```

**Dependencies**: SC-01, SC-03, existing `Database`
**Success criterion**: SC-05

---

### SC-06: Durga Pattern

**Purpose**: Three-tier repair escalation — deterministic regex fixes first, VLM second (placeholder), LLM third.

**Files to create**:
- `backend/app/services/durga.py` — `DurgaRepairEngine`
- `backend/app/services/durga_rules.py` — Pattern-matched fix rules

**Files to modify**:
- `backend/app/services/module_executor.py` — Call Durga on failure

**Key interfaces**:
```python
@dataclass
class RepairResult:
    repaired: bool
    tier_used: str             # "deterministic" | "vlm" | "llm" | "none"
    original_error: str
    fixed_code: str | None
    explanation: str
    attempts: int

class DurgaRepairEngine:
    def __init__(self, rules, chat_agent=None): ...
    async def attempt_repair(self, source_code, error, vlad_result=None, max_attempts=3) -> RepairResult

DETERMINISTIC_RULES = [
    # "cannot fillet edge" → reduce fillet radius
    # "BRep_API: not done" → simplify boolean operation
    # "no result variable" → add result assignment
    # "zero thickness" → increase extrusion depth
]
```

**Dependencies**: SC-02, SC-03, existing `ChatAgent`
**Success criterion**: SC-06

---

### SC-07: MCP Tools

**Purpose**: Expose module CRUD, execution, and VLAD as MCP tools for external LLM agents.

**Files to create**:
- `backend/app/mcp/kfs_tools.py` — 5 MCP tools
- `backend/app/mcp/__init__.py`

**Tools**: `kfs_create_module`, `kfs_execute_module`, `kfs_validate_module`, `kfs_list_modules`, `kfs_get_module`

**Dependencies**: SC-01, SC-02, SC-03
**Success criterion**: SC-07

---

### SC-08: Manifest Generator

**Purpose**: Generate `.kfs.yaml` from all valid modules using existing `kfs_core` models.

**Files to create**:
- `backend/app/services/manifest_generator.py`

**Key interfaces**:
```python
class ManifestGenerator:
    def __init__(self, module_mgr: ModuleManager): ...
    async def generate_for_project(self, project_id, output_path) -> Path
    def _module_to_kfs_object(self, module: Module) -> KFSObject
```

**Dependencies**: SC-01, existing `kfs_core`
**Success criterion**: SC-08 (basic; ADR-09 advanced deferred to Stage 9)

---

### SC-09: Contract Tests

**Files to create**:
- `tests/test_module_manager.py`
- `tests/test_module_executor.py`
- `tests/test_vlad_runner.py`
- `tests/test_durga.py`
- `tests/test_manifest_generator.py`
- `tests/test_integration_pipeline.py`
- `tests/conftest.py`

CadQuery-dependent tests marked `@pytest.mark.requires_cadquery`. Lightweight DB-only subset always runs.

**Dependencies**: All SC-01 through SC-08
**Success criterion**: SC-09

---

### SC-10: Observability Wiring

**Files to modify**:
- `backend/app/services/durga.py` — Wrap LLM calls in `observe_llm_call()`
- `backend/app/services/module_executor.py` — Log execution time
- `backend/app/services/vlad_runner.py` — Log VLAD time
- `backend/app/middleware/observability.py` — Add `log_execution()` for non-LLM events

**Dependencies**: Existing `observability.py`, SC-02, SC-03, SC-06
**Success criterion**: SC-10

---

## 4. Database Schema Changes

All in `backend/app/db/database.py` `_init_tables()`:

```sql
-- SC-01: Module storage
CREATE TABLE IF NOT EXISTS modules (
    id TEXT NOT NULL,
    project_id TEXT NOT NULL,
    name TEXT NOT NULL,
    geometry_type TEXT NOT NULL,
    source_code TEXT NOT NULL,
    parameters TEXT DEFAULT '{}',
    version INTEGER DEFAULT 1,
    status TEXT DEFAULT 'draft',
    stl_path TEXT,
    step_path TEXT,
    vlad_verdict TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (id, project_id),
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- SC-01: Version history (append-only)
CREATE TABLE IF NOT EXISTS module_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    module_id TEXT NOT NULL,
    project_id TEXT NOT NULL,
    version INTEGER NOT NULL,
    source_code TEXT NOT NULL,
    parameters TEXT DEFAULT '{}',
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (module_id, project_id) REFERENCES modules(id, project_id)
);

-- SC-03: VLAD validation results
CREATE TABLE IF NOT EXISTS vlad_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    module_id TEXT NOT NULL,
    project_id TEXT NOT NULL,
    verdict TEXT NOT NULL,
    pass_count INTEGER DEFAULT 0,
    fail_count INTEGER DEFAULT 0,
    warn_count INTEGER DEFAULT 0,
    checks_json TEXT DEFAULT '[]',
    mechanism_type TEXT,
    execution_time_ms REAL DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (module_id, project_id) REFERENCES modules(id, project_id)
);

-- SC-05: Session action log
CREATE TABLE IF NOT EXISTS session_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id TEXT NOT NULL,
    action_type TEXT NOT NULL,
    detail_json TEXT DEFAULT '{}',
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (project_id) REFERENCES projects(id)
);
```

---

## 5. API Endpoints

### New Route: `backend/app/routes/modules.py`

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/projects/{id}/modules` | Create module |
| GET | `/api/projects/{id}/modules` | List modules |
| GET | `/api/projects/{id}/modules/{mid}` | Get module detail |
| PUT | `/api/projects/{id}/modules/{mid}` | Update (new version) |
| POST | `/api/projects/{id}/modules/{mid}/execute` | Execute module |
| POST | `/api/projects/{id}/modules/{mid}/validate` | Run VLAD |
| POST | `/api/projects/{id}/modules/{mid}/execute-and-validate` | Full pipeline |
| GET | `/api/projects/{id}/modules/{mid}/geometry` | Serve GLB |
| GET | `/api/projects/{id}/modules/{mid}/vlad-history` | VLAD results |
| POST | `/api/projects/{id}/modules/{mid}/rollback` | Version rollback |
| POST | `/api/projects/{id}/manifest` | Generate .kfs.yaml |

---

## 6. Dependency Graph & Build Order

```
Phase 1 (Foundation — no inter-dependencies):
  SC-01  Module Manager
  SC-05  Context Persistence

Phase 2 (Execution — depends on Phase 1):
  SC-02  Module Executor      (depends on SC-01)
  SC-03  VLAD Runner          (depends on SC-01)

Phase 3 (Intelligence — depends on Phase 2):
  SC-06  Durga Pattern        (depends on SC-02, SC-03)
  SC-08  Manifest Generator   (depends on SC-01, uses kfs_core)
  SC-10  Observability Wiring (depends on SC-02, SC-03, SC-06)

Phase 4 (Interface — depends on Phase 2):
  SC-04  Three.js Renderer    (depends on SC-01 for module endpoints)
  SC-07  MCP Tools            (depends on SC-01, SC-02, SC-03)

Phase 5 (Verification — depends on everything):
  SC-09  Contract Tests       (depends on all of the above)
```

**Critical path**: SC-01 → SC-02 → SC-06

---

## 7. File Inventory

### New Files (20)

| File | Module |
|------|--------|
| `backend/app/models/module.py` | SC-01 |
| `backend/app/services/module_executor.py` | SC-02 |
| `backend/app/services/vlad_runner.py` | SC-03 |
| `backend/app/services/vlad_bridge.py` | SC-03 |
| `backend/app/models/session_context.py` | SC-05 |
| `backend/app/services/durga.py` | SC-06 |
| `backend/app/services/durga_rules.py` | SC-06 |
| `backend/app/mcp/kfs_tools.py` | SC-07 |
| `backend/app/mcp/__init__.py` | SC-07 |
| `backend/app/services/manifest_generator.py` | SC-08 |
| `backend/app/routes/modules.py` | SC-01/02/03/08 |
| `frontend/src/stores/moduleStore.ts` | SC-04 |
| `frontend/src/components/ModuleListPanel.tsx` | SC-04 |
| `frontend/src/components/ModuleEditorPanel.tsx` | SC-04 |
| `tests/test_module_manager.py` | SC-09 |
| `tests/test_module_executor.py` | SC-09 |
| `tests/test_vlad_runner.py` | SC-09 |
| `tests/test_durga.py` | SC-09 |
| `tests/test_manifest_generator.py` | SC-09 |
| `tests/test_integration_pipeline.py` | SC-09 |

### Modified Files (11)

| File | Change |
|------|--------|
| `backend/app/db/database.py` | Add 4 new tables |
| `backend/app/config.py` | Add `vlad_script_path` |
| `backend/app/main.py` | Register modules router |
| `backend/app/routes/viewport.py` | Per-module geometry endpoint |
| `backend/app/orchestrator/chat_agent.py` | Module context in prompts |
| `backend/app/ai/prompt_builder.py` | Modules section |
| `backend/app/middleware/observability.py` | Add `log_execution()` |
| `frontend/src/stores/viewportStore.ts` | Add `activeModuleId` |
| `frontend/src/stores/projectStore.ts` | Add modules to project |
| `frontend/src/components/Viewport3D.tsx` | Per-module URL |
| `frontend/src/components/ChatPanel.tsx` | "Save as Module" button |

**Total**: 20 new files, 11 modified. Zero deleted. Zero existing features broken.

---

## 8. Risk Assessment

| Module | Risk | Mitigation |
|--------|------|------------|
| SC-01 Module Manager | Low — CRUD, mirrors ComponentManager | Follow existing pattern |
| SC-02 Module Executor | Medium — subprocess CadQuery failures | Use existing CadQueryEngine as-is |
| SC-03 VLAD Runner | **HIGH** — bridge module translation | Fallback: topology checks only (T1-T4) |
| SC-04 Three.js Renderer | Low — existing GLB serving works | Increment geometryVersion on execute |
| SC-05 Context Persistence | Low — append-only log table | Keep simple |
| SC-06 Durga Pattern | Medium — rule set incomplete at first | Start with 5-10 common fixes, LLM safety net |
| SC-07 MCP Tools | Medium — MCP SDK version dependency | Standalone script, no FastAPI coupling |
| SC-08 Manifest Generator | Low — mechanical mapping | Test relative paths carefully |
| SC-09 Contract Tests | Medium — CadQuery needed in test env | Split: DB tests (always) + geometry tests (marked) |
| SC-10 Observability | Low — wrapping existing functions | Just wire it |
