# Kinetic Sculpture Workflow Upgrade — Master Execution Prompt

**Date:** 2026-03-02
**Purpose:** Complete prompt for a fresh Claude Code session to execute the full workflow upgrade.
**Context:** This was designed after auditing the entire Kinetic Forge Studio codebase and identifying every gap between what exists, what was planned (Rule 500, Design Doc V2), and what the user needs.

---

## THE PROBLEM

The user (Abhishek) designs kinetic sculptures using Claude Code. The workflow has three systemic failures:

1. **Claude loses context between sessions** — re-derives decisions, re-pitches old ideas, wastes tokens and time
2. **No enforcement** — validation pipeline (Rule 500) exists as markdown but nothing prevents skipping steps
3. **Scattered tools** — terminal, OpenSCAD, FreeCAD, browser, file explorer all disconnected

## THE SOLUTION: THREE LAYERS

```
┌─────────────────────────────────────────────────────┐
│  VS Code (Mission Control)                          │
│  - File tree, git, terminals, markdown preview       │
│  - Tasks: start servers, compile, validate           │
│  - Claude Code extension: inline AI assistance       │
│  - OpenSCAD syntax highlighting                      │
│  - Python debugging for validation scripts           │
├─────────────────────────────────────────────────────┤
│  Kinetic Forge Studio (Pipeline Enforcer)            │
│  - Web app at localhost:5173 (frontend)              │
│  - FastAPI at localhost:8100 (backend)               │
│  - Tracks projects, decisions, components            │
│  - Runs gate validation (collision, manufacturability)│
│  - Blocks export until gates pass                    │
│  - Chat interface drives design pipeline             │
├─────────────────────────────────────────────────────┤
│  Claude Code (Execution Engine)                      │
│  - Generates .scad / CadQuery code                   │
│  - Runs validation scripts                           │
│  - Compiles OpenSCAD                                 │
│  - Connects to FreeCAD MCP                           │
│  - Reads/writes project state files                  │
└─────────────────────────────────────────────────────┘
```

---

## COMPONENT INVENTORY (Current State as of 2026-03-02)

### A. VS Code Workspace

**File:** `D:\Claude local\kinetic-sculpture.code-workspace`
**Status:** JUST CREATED — needs extensions installed and first launch

**What exists:**
- Workspace file with 5 folder groups (Designs, KFS App, Docs & Plans, Tools, Root)
- Tasks defined: KFS Start Backend, KFS Start Frontend, KFS Start Both, OpenSCAD Compile, OpenSCAD Validate, OpenSCAD Compile+Validate
- Launch config for debugging KFS backend
- Recommended extensions list
- Settings: Git Bash terminal, Python 3.12, file associations, format on save

**What's missing:**
- Extensions not yet installed (just recommended)
- No git hooks configured
- No file watcher for auto-validation
- Claude Code extension not in recommendations (user installs separately)

### B. Kinetic Forge Studio — Frontend

**Stack:** React 18 + Three.js/R3F + Zustand + Vite
**Location:** `D:\Claude local\kinetic-forge-studio\frontend\`
**Port:** 5173 (Vite, host 0.0.0.0, strictPort)

| Component | File | Status | What It Does |
|-----------|------|--------|-------------|
| App | App.tsx | WIRED | Home/workspace routing, layout with 3-column design |
| HomeScreen | HomeScreen.tsx | BASIC | Project list + create button. Works but minimal UI |
| ChatPanel | ChatPanel.tsx | WIRED | Send messages to backend pipeline, display responses |
| Viewport3D | Viewport3D.tsx | WIRED | Three.js GLB viewer with click-select, view modes |
| ViewportToolbar | ViewportToolbar.tsx | WIRED | Camera presets, solid/wireframe/xray toggle |
| GateStatus | GateStatus.tsx | WIRED | Fetches validation results, shows pass/fail |
| FileUpload | FileUpload.tsx | WIRED | Drag-drop upload routed to backend analyzers |
| ProjectFilesPanel | ProjectFilesPanel.tsx | STUB | Needs: file listing, "Open in OpenSCAD" buttons |
| projectStore | stores/projectStore.ts | WIRED | Zustand store: projects, activeProject, screen |
| viewportStore | stores/viewportStore.ts | WIRED | Zustand store: selectedMesh, loading, geometryVersion |
| API client | api/client.ts | WIRED | Base URL: localhost:8100/api. All endpoints mapped |

**Design Doc V2 says the viewport should be REMOVED** in favor of native app launchers + render PNG preview. The current Three.js viewport works but chokes on high-poly meshes (helical gears, 300K+ faces). Decision needed: keep viewport for simple previews OR replace with render PNG.

### C. Kinetic Forge Studio — Backend

**Stack:** FastAPI + aiosqlite + trimesh + CadQuery
**Location:** `D:\Claude local\kinetic-forge-studio\backend\`
**Port:** 8100 (uvicorn, reload, host 0.0.0.0)
**DB:** SQLite at `~/.kinetic-forge-studio/studio.db`
**Python:** 3.12 (via `py -3.12`)

#### Routes

| Route File | Endpoints | Status |
|-----------|-----------|--------|
| projects.py | GET/POST /api/projects, GET /api/projects/{id}, POST decisions, POST components | FULLY WIRED |
| chat.py | POST /api/projects/{id}/chat, POST chat/answer, POST chat/reset | WIRED (uses Pipeline, not Claude API) |
| validation.py | GET /api/projects/{id}/gate-status | WIRED (collision + manufacturability) |
| viewport.py | GET /api/projects/{id}/geometry, GET geometry/info | WIRED (serves GLB) |
| upload.py | POST /api/projects/{id}/upload | WIRED (routes to analyzers) |
| library.py | GET /api/library/search, POST /api/library, GET /api/library/{id} | WIRED |
| export.py | GET /api/projects/{id}/export | STUB — endpoint exists, package generation incomplete |
| profile.py | User profile endpoints | STUB — not included in main.py |
| viewer.py | Alternative viewport | STUB — not included in main.py |

#### Engines

| Engine | File | Status | Notes |
|--------|------|--------|-------|
| OpenSCAD | openscad_engine.py | WIRED | Exports per-component STLs → decimates → GLB. Uses SHOW_* flag overrides |
| CadQuery | cadquery_engine.py | WIRED | Executes Python scripts in subprocess, produces STEP + STL |
| FreeCAD | freecad_engine.py | PARTIAL | MCP connection (port 9875) preferred, CLI fallback. FEM is placeholder |
| Geometry | geometry_engine.py | WIRED | CadQuery-based spur gear, box, cylinder → trimesh → GLB |
| Render | render_preview.py | WIRED | OpenSCAD headless render or trimesh screenshot → PNG |

#### Validators

| Validator | File | Status | Notes |
|-----------|------|--------|-------|
| Collision | collision.py | FULLY WIRED | trimesh CollisionManager or AABB fallback |
| Manufacturability | manufacturability.py | FULLY WIRED | Wall thickness, overhang, watertight |
| Geometry | geometry_validator.py | PARTIAL | Expects external validate_geometry.py script |
| Consistency | consistency_validator.py | STUB | |
| Tolerance | tolerance_validator.py | STUB | |

#### Orchestrator

| Module | File | Status | Notes |
|--------|------|--------|-------|
| Pipeline | pipeline.py | WIRED | Classifier → question tree → spec building. No Claude API |
| Gate | gate.py | WIRED | Runs collision + manufacturability, returns pass/fail |
| ChatAgent | chat_agent.py | BUILT BUT NOT INTEGRATED | Full Claude API client with retry logic. Not called from any route |

#### AI

| Module | File | Status | Notes |
|--------|------|--------|-------|
| claude_client.py | ai/claude_client.py | BUILT | Async HTTP to Anthropic Messages API. Unused |
| prompt_builder.py | ai/prompt_builder.py | BUILT | Constructs prompts with spec, decisions, components, profile |

#### Models

| Model | File | Status |
|-------|------|--------|
| ProjectManager | models/project.py | WIRED — SQLite CRUD, project directories |
| DecisionManager | models/decision.py | WIRED — Add, lock, conflict detection |
| ComponentManager | models/component.py | WIRED — Register, list, track parameters |
| UserProfile | models/profile.py | BUILT — Printer/material/style preferences |

#### Importers / Analyzers

| Analyzer | File | Status |
|----------|------|--------|
| STL | importers/stl_analyzer.py | WIRED — trimesh |
| STEP | importers/step_analyzer.py | WIRED — CadQuery |
| Photo | importers/photo_analyzer.py | PARTIAL — placeholder without Claude API key |
| Video | importers/video_analyzer.py | PARTIAL — placeholder without Claude API key |

### D. Memory System

**Location:** `C:\Users\abhis\.claude\projects\D--Claude-local\memory\`

| File | Status | Purpose |
|------|--------|---------|
| MEMORY.md | EXISTS, ~200 lines, bloated | Hardware, preferences, project details all mixed together |
| rule99.md | EXISTS | Rule 99 consultant pipeline spec |
| rule500.md | EXISTS | Full 32-step production pipeline spec |

**What's missing:**
- No project state files (projects/waffle-planetary.yaml etc.)
- No session handoff notes
- No decision log (decisions.md)
- MEMORY.md not organized by topic

### E. Existing Pipeline Tools

**Location:** Various

| Tool | Location | Status |
|------|----------|--------|
| validate_geometry.py | 3d_design_agent/waffle_grid_planetary/ and check point/ | EXISTS — not wired into KFS |
| consistency_audit.py | 3d_design_agent/waffle_grid_planetary/ | EXISTS — not wired into KFS |
| iso286_lookup.py | Unknown / not found | REFERENCED in Rule 500, may not exist yet |
| tolerance_stackup.py | 3d_design_agent/triple_helix_mvp/check point/ | EXISTS — not wired into KFS |
| extract_reference.py | 3d_design_agent/waffle_grid_planetary/ | EXISTS — not wired into KFS |

### F. External Tools

| Tool | Path | Status |
|------|------|--------|
| OpenSCAD Nightly | C:/Program Files/OpenSCAD (Nightly)/openscad.com | INSTALLED, Manifold backend |
| OpenSCAD Stable | C:/Program Files/OpenSCAD/openscad.com | INSTALLED, backup only |
| FreeCAD 1.0.2 | C:/Program Files/FreeCAD 1.0/ | INSTALLED, MCP addon configured |
| BOSL2 | C:/Users/abhis/Documents/OpenSCAD/libraries/BOSL2/ | INSTALLED |
| Python 3.12 | C:/Users/abhis/AppData/Local/Programs/Python/Python312/ | INSTALLED |
| Python 3.10 | D:/Python310/ | INSTALLED (default) |
| VS Code | C:/Users/abhis/AppData/Local/Programs/Microsoft VS Code/ | INSTALLED |
| Git | Available in PATH | INSTALLED |
| ntfy.sh | Topic: bussabtheakhaijanab1851421 | CONFIGURED |

### G. Config Files

| File | Location | Purpose |
|------|----------|---------|
| CLAUDE.md | D:\Claude local\CLAUDE.md | Project-level instructions for Claude Code |
| .mcp.json | D:\Claude local\.mcp.json | MCP server configs (FreeCAD, etc.) |
| launch.json | D:\Claude local\.claude\launch.json | Preview server configs (KFS backend:8100, frontend:5173, gallery:8765) |
| .code-workspace | D:\Claude local\kinetic-sculpture.code-workspace | VS Code workspace (just created) |

---

## EXECUTION PLAN

### Phase 1: VS Code as Mission Control (30 min)

**Goal:** VS Code is the single window where everything happens.

1. **Open workspace:** `code "D:\Claude local\kinetic-sculpture.code-workspace"`
2. **Install extensions** (from recommendations in workspace):
   - `ms-python.python` — Python language support
   - `ms-python.debugpy` — Python debugging
   - `antyos.openscad` — OpenSCAD syntax highlighting
   - `eamodio.gitlens` — Git history/blame
   - `dbaeumer.vscode-eslint` — TypeScript linting
   - `esbenp.prettier-vscode` — Code formatting
3. **Install Claude Code extension** — from VS Code marketplace ("Claude Code" by Anthropic)
4. **Verify tasks work:**
   - `Ctrl+Shift+P` → "Tasks: Run Task" → "KFS: Start Both Servers"
   - Confirm backend on 8100, frontend on 5173
   - Open http://localhost:5173 in browser → see project list
5. **Verify OpenSCAD tasks:**
   - Open any .scad file
   - Run task "OpenSCAD: Compile" → should compile with zero errors
   - Run task "OpenSCAD: Validate Geometry" → should run validator

### Phase 2: Memory Infrastructure (30 min)

**Goal:** Claude Code never loses context between sessions again.

1. **Reorganize memory directory:**
```
C:\Users\abhis\.claude\projects\D--Claude-local\memory\
├── MEMORY.md              ← SLIM: only preferences + pointers (under 100 lines)
├── hardware.md            ← PC specs, OpenSCAD limits (move from MEMORY.md)
├── decisions.md           ← Append-only decision log across ALL projects
├── rule99.md              ← Already exists, keep
├── rule500.md             ← Already exists, keep
├── projects/
│   ├── waffle-planetary.yaml    ← Current state of waffle planetary project
│   ├── triple-helix.yaml       ← Current state of triple helix project
│   └── kinetic-forge-studio.yaml ← Current state of KFS app itself
└── sessions/
    └── (handoff notes go here after each session)
```

2. **Create project state files** from what's known:
   - Each YAML has: project name, status, current_focus, last_session, key decisions (locked), key files, blocked_on, next_steps
   - Populate from existing MEMORY.md content and git history

3. **Create decisions.md** — extract all design decisions scattered in MEMORY.md into structured format:
   ```
   ## 2026-02-14 — Triple Helix V5.1
   - DECIDED: Coaxial corridor architecture for parallel arms
   - REASON: Arms must be parallel for shaft threading
   - REJECTED: Converging arms (55° misalignment)
   ```

4. **Slim MEMORY.md** to under 100 lines — only:
   - User interaction rules
   - Pointers to topic files
   - Active project list
   - Tool preferences

5. **Create session handoff template** that Claude writes at end of every session

### Phase 3: Git Discipline (30 min)

**Goal:** No more "check point" folders. Git branches and tags replace folder copies.

1. **Commit current state** on `kinetic-forge-studio-impl` branch
2. **Tag important checkpoints** from existing folders:
   - `git tag v5.0-triple-helix` (reference only, from check point/5.0/)
   - `git tag v5.5-triple-helix` (reference only, from check point/5.5/)
3. **Set up git hooks:**
   - Pre-commit hook: if any `.scad` file staged, run OpenSCAD compile check
   - Pre-commit hook: if any KFS Python file staged, run `pytest` on backend
4. **Create .gitignore** entries for:
   - `__pycache__/`, `*.pyc`, `node_modules/`, `.env`
   - Large binary files (`.stl`, `.step` over 10MB)
   - Temporary renders (`test.csg`, `test.png`)

### Phase 4: Wire KFS Gaps (2-3 hours)

**Goal:** Close the gaps between what KFS has and what Design Doc V2 + Rule 500 specified.

Priority order (highest impact first):

#### 4.1 Integrate Claude API into Chat (Priority 1)
- `chat_agent.py` is BUILT but not called from `chat.py` route
- Wire it: when `KFS_CLAUDE_API_KEY` is set, use ChatAgent; otherwise fall back to Pipeline (keyword classifier)
- The prompt_builder.py already constructs proper prompts with spec, decisions, components, profile
- Test: send a design message, get Claude-powered response with code generation

#### 4.2 Wire External Validators (Priority 2)
- `geometry_validator.py` — update to call `validate_geometry.py` from existing location
- `consistency_validator.py` — wire to `consistency_audit.py`
- `tolerance_validator.py` — wire to `tolerance_stackup.py`
- Add all three to `gate.py`'s validation pipeline
- Update `validation.py` route to return results from all validators

#### 4.3 Export Package (Priority 3)
- `export.py` route is STUB — implement actual ZIP bundle:
  - spec_sheet.yaml (frozen spec)
  - decision_journal.json (all decisions)
  - parts/*.step and parts/*.stl (per component)
  - assembly.step (combined)
  - validation_report.json (all gate results)
  - renders/*.png (isometric, front, top)
  - source/*.scad or source/*.py (original code)

#### 4.4 Profile Route (Priority 4)
- `profile.py` model exists but route not in main.py
- Add `profile_router` to main.py
- Wire user profile into ChatAgent's prompt builder

#### 4.5 ProjectFilesPanel (Priority 5)
- Currently STUB
- Implement: list all files in project dir
- Add "Open in OpenSCAD" / "Open in FreeCAD" buttons (shell launch)
- Show render preview PNGs

#### 4.6 Rule 99 Gate Integration (Priority 6)
- Gate transitions (design → prototype → production) are defined in Rule 500
- Wire Rule 99 consultant checks into gate transitions
- Add gate advancement endpoints: POST /api/projects/{id}/advance-gate

### Phase 5: CadQuery Production Path (1-2 hours)

**Goal:** Direct STEP output without STL→STEP conversion.

1. **Verify CadQuery is installed** for Python 3.12
2. **Test CadQuery engine** — generate a simple gear, verify STEP export
3. **Wire into ChatAgent** — when Claude generates CadQuery code, execute via cadquery_engine.py
4. **Add build123d as alternative** — same engine, different API syntax
5. **Test end-to-end:** chat message → Claude generates CadQuery → engine executes → STEP + STL → viewport shows GLB

---

## HOW THE THREE LAYERS CONNECT

### Scenario: User designs a new planetary gear set

```
1. USER opens VS Code workspace
   └─ Sees project tree, docs, KFS app code

2. USER runs task "KFS: Start Both Servers"
   └─ Backend on :8100, Frontend on :5173

3. USER opens localhost:5173 in browser
   └─ Sees KFS home screen with existing projects

4. USER clicks "+ New Project" → "planetary_gear_v1"
   └─ KFS creates SQLite entry + project directory

5. USER types in chat: "I want a 3-stage planetary gear with 72T ring"
   └─ Frontend sends POST /api/projects/{id}/chat
   └─ Backend pipeline classifies: mechanism=planetary, ring_teeth=72
   └─ If Claude API key set: ChatAgent generates CadQuery code
   └─ If not: Pipeline asks clarifying questions (sun teeth? module?)

6. USER answers questions until spec is complete
   └─ Backend generates geometry via CadQuery or OpenSCAD engine
   └─ Viewport shows 3D GLB preview
   └─ GateStatus shows collision + manufacturability checks

7. USER sees issue: "planet gear too close to ring"
   └─ Types feedback in chat
   └─ ChatAgent modifies specific parameters
   └─ Re-validates, re-renders

8. USER locks decisions: "ring=72T, sun=18T, module=2.0"
   └─ KFS records in decision journal with reasoning
   └─ Decisions persist across sessions — Claude never re-asks

9. VALIDATION passes all gates
   └─ Export button enabled
   └─ User downloads ZIP: STEP + STL + spec + decisions + validation report

10. Meanwhile in VS Code:
    └─ User can see/edit .scad files directly
    └─ Run OpenSCAD compile task
    └─ Run validation task
    └─ See git diff of changes
    └─ Read design specs in markdown preview
    └─ Use Claude Code extension for inline questions
    └─ Terminal panel shows server logs

11. At end of session:
    └─ Claude writes session handoff note
    └─ Updates project state YAML
    └─ Updates decisions.md if new decisions made
    └─ Next session starts in <15 seconds with full context
```

### Scenario: User returns next day to continue

```
1. USER opens VS Code workspace
2. USER runs "KFS: Start Both Servers"
3. USER opens Claude Code (terminal or extension)
4. USER says: "continue planetary gear"

Claude Code:
  ├─ Reads MEMORY.md (50 lines, fast)
  ├─ Reads memory/projects/planetary-gear-v1.yaml (20 lines)
  │   → knows: 72T ring, 18T sun, module 2.0, blocked on planet clearance
  ├─ Reads memory/sessions/2026-03-02.md (10 lines)
  │   → knows: last session fixed X, next step is Y
  └─ Ready to work in 15 seconds, no re-discovery needed

5. USER opens KFS at localhost:5173
   └─ Project still there with all decisions, components, validation history
   └─ 3D viewport shows last geometry
   └─ Chat history preserved
```

---

## FILES THIS SESSION SHOULD CREATE/MODIFY

1. **Memory files:**
   - `memory/MEMORY.md` — slim to <100 lines
   - `memory/hardware.md` — extracted from MEMORY.md
   - `memory/decisions.md` — new, populated from MEMORY.md
   - `memory/projects/waffle-planetary.yaml` — new
   - `memory/projects/triple-helix.yaml` — new
   - `memory/projects/kinetic-forge-studio.yaml` — new

2. **VS Code:**
   - Install recommended extensions
   - Verify workspace tasks work
   - Install Claude Code extension (user does this manually)

3. **Git:**
   - Set up pre-commit hooks
   - Update .gitignore
   - Initial commit of current state

4. **KFS Backend:**
   - Wire ChatAgent into chat route (with API key check)
   - Wire external validators (geometry, consistency, tolerance)
   - Implement export package
   - Add profile route to main.py
   - Add gate advancement endpoint

5. **KFS Frontend:**
   - Implement ProjectFilesPanel (file list + native app launch)
   - Update HomeScreen (library search, reference count)

---

## PORTS AND SERVICES

| Service | Port | Command |
|---------|------|---------|
| KFS Backend (FastAPI) | 8100 | `py -3.12 -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8100` |
| KFS Frontend (Vite) | 5173 | `npx vite` (from frontend dir, host 0.0.0.0, strictPort) |
| Alpha Pulse Backend | 8000 | (separate project, may be running — don't conflict) |
| FreeCAD MCP | 9875 | (start manually in FreeCAD Python console) |
| Gallery Server | 8765 | (static file server for HTML visualizations) |

---

## CRITICAL RULES FOR EXECUTION

1. **Do NOT re-derive decisions** — read memory files first, always
2. **Do NOT skip VS Code setup** — it's the foundation, not optional
3. **Do NOT rebuild what exists** — KFS has 60+ working Python files and 12+ React components. Wire gaps, don't rewrite
4. **Do NOT propose alternatives to what's already decided** — Rule 500 is the spec. Build it.
5. **Run validation after every code change** — this is the whole point
6. **Write session handoff at end** — the single most important habit
7. **Update project state YAMLs** — keep them current after every meaningful change
8. **Test in browser** — KFS is a web app, verify it works visually
9. **Use VS Code tasks** — don't bypass them with raw terminal commands
10. **Trust the user's eyes** — when they say something looks wrong, fix it. Don't argue with math.
