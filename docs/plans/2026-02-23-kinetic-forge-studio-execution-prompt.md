# Kinetic Forge Studio — Execution Prompt

**Date:** 2026-02-23
**Purpose:** Bring the deployed app from its current state to the V2 design.
**Design Doc:** `D:\Claude local\docs\plans\2026-02-23-kinetic-forge-studio-design-v2.md`

---

## Context

Kinetic Forge Studio is a standalone web app (React 19 + FastAPI) that orchestrates the kinetic sculpture design process. It coordinates external tools (Claude API, CadQuery/build123d, OpenSCAD, FreeCAD, trimesh, validation scripts) to produce production-level 3D designs.

The app was built in 7 phases (28 tasks) and currently has:
- Working frontend: HomeScreen, ChatPanel, ProjectFilesPanel, GateStatus, FileUpload
- Working backend: 7 API routers, SQLite DB, project CRUD, file upload + analysis
- Working OpenSCAD engine (per-component STL export, native app launching)
- Working importers (STEP via CadQuery, STL via trimesh, photo via Claude Vision)
- Working validators (collision, manufacturability)
- Working export pipeline (ZIP bundles actual project files)
- Working reference library (SQLite FTS5 search)

**But the core design loop is broken.** The chat uses a rigid YAML question tree that can't handle natural language, custom values, or iterative feedback. And the "generate" step is a placeholder that says "Spec complete" and does nothing. There is no actual CAD code generation.

---

## What Needs to Change (10 Items, Priority Order)

### ITEM 1: Claude-Powered Chat Agent (HIGHEST PRIORITY)

**Current state:**
- `backend/app/orchestrator/pipeline.py` — Classifier → merge fields → check unknowns → YAML question → placeholder "generation"
- `backend/app/translator/classifier.py` — Keyword extraction via regex + taxonomy YAML
- `backend/app/translator/question_tree.py` — YAML-driven questions with fixed options
- `backend/data/questions/*.yaml` — 6 question files (mechanism_type, motion_type, material, envelope_size, motor_count, teeth)
- `backend/app/routes/chat.py` — Thin route passing messages to Pipeline
- `frontend/src/components/ChatPanel.tsx` — Text-only display, no clickable option buttons

**Problems:**
1. User types "2" for "Dual Motor" → classifier doesn't understand
2. User wants 3 motors → not an option in YAML
3. No clickable buttons in UI for presented options
4. "Spec complete" leads to a dead end (no generation)
5. Can't handle iterative feedback ("gear too big", "add clearance")
6. No conversation context (each message classified independently)

**What to build:**

Replace the rigid pipeline with a Claude API-powered chat agent.

**Backend changes:**

1. Create `backend/app/orchestrator/chat_agent.py`:
   - Class `ChatAgent` that wraps Claude API calls via `httpx`
   - Every call auto-includes in the system prompt:
     - Current spec sheet (from project DB)
     - Locked decisions (from decisions table)
     - Component registry (from components table)
     - User profile (printer, material prefs — from config or profile store)
     - Conversation history (from session)
   - The agent's job: understand intent, ask clarifying questions, update spec, generate CAD code
   - Must support "Just Do It" mode: short imperative messages bypass clarification
   - Falls back gracefully if no API key (returns error message explaining Claude API is required)

2. Keep `backend/app/translator/classifier.py` as a **fast pre-filter** (zero API cost):
   - Run classifier BEFORE sending to Claude
   - Extract obvious parameters (mechanism type, dimensions, materials)
   - Include extracted params in Claude's context so it doesn't re-ask for things already parsed

3. Modify `backend/app/orchestrator/pipeline.py`:
   - Import ChatAgent
   - If Claude API key is configured: route through ChatAgent
   - If no API key: fall back to current classifier + question tree flow
   - ChatAgent receives: user message + classifier results + running spec + conversation history
   - ChatAgent returns: response text + spec updates + optional CAD code + response type

4. Modify `backend/app/routes/chat.py`:
   - Store conversation history per project (not just pipeline state)
   - New endpoint: `POST /api/projects/{id}/chat/context` — returns current spec + decisions for frontend display
   - Conversation history should persist across page reloads (store in DB or filesystem)

5. Modify `backend/app/config.py`:
   - Add `claude_model: str = "claude-sonnet-4-20250514"` (default model)
   - Add `claude_max_tokens: int = 4096`
   - `claude_api_key` already exists

**Frontend changes:**

6. Modify `frontend/src/components/ChatPanel.tsx`:
   - When response includes `question.options`, render clickable buttons
   - Each button calls `chatApi.answer(projectId, field, value)`
   - Support markdown rendering in assistant messages (code blocks, bold, lists)
   - Add a "thinking" indicator while waiting for Claude response
   - Show spec updates as inline badges when parameters are extracted

**Claude System Prompt Template** (for the chat agent):

```
You are the design agent for Kinetic Forge Studio, a kinetic sculpture design orchestrator.

Your job:
1. Understand the user's design intent through conversation
2. Ask 1-3 clarifying questions (not more) when needed
3. Update the design spec as parameters become clear
4. Generate CAD code (CadQuery/build123d Python or OpenSCAD .scad) when ready
5. Iterate on feedback ("too big", "add clearance", "change module")

Current project spec:
{spec_sheet_yaml}

Locked decisions:
{locked_decisions}

Components:
{component_registry}

User profile:
- Printer: {printer_model}
- Material: {material}
- Preferences: {user_prefs}

Classifier extracted these parameters from the latest message:
{classifier_results}

Rules:
- All dimensions in millimeters
- Single motor unless impossible
- Every dimension must be a named constant
- For CadQuery: generate Python script using CadQuery API
- For OpenSCAD: follow the template (Header → Quality → Tolerances → Dimensions → Toggles → Colors → Functions → Primitives → Assemblies)
- When generating code, output it in a ```python or ```openscad code block
- When updating spec, output a JSON block with field:value pairs
- For iterative feedback, modify specific constants — never full rewrites
```

---

### ITEM 2: CadQuery/build123d Generation Engine

**Current state:**
- The old `geometry_engine.py` was deleted (it generated placeholder shapes)
- No engine exists to generate real B-rep geometry from specs

**What to build:**

1. Create `backend/app/engines/cadquery_engine.py`:
   - Class `CadQueryEngine`
   - Method `generate(spec: dict, code: str) -> GenerationResult`:
     - Takes a Python script (CadQuery or build123d) generated by the chat agent
     - Executes it in a subprocess (sandboxed)
     - Captures output files (STEP, STL)
     - Returns: success/failure, output file paths, error messages
   - Method `validate(step_path: Path) -> ValidationResult`:
     - Load STEP with CadQuery
     - Check: all solids valid, no self-intersections
     - Return face count, volume, bounding box
   - Method `export(step_path: Path, formats: list[str]) -> dict[str, Path]`:
     - Export to requested formats (STEP, STL, glTF)

2. Engine selection logic in pipeline:
   - If user has existing .scad files (project.scad_dir set) → OpenSCAD engine
   - If generating new B-rep design → CadQuery/build123d engine
   - If user explicitly requests OpenSCAD → OpenSCAD engine
   - User can override

3. The chat agent generates the Python/OpenSCAD code as text in its response. The pipeline extracts code blocks and sends them to the appropriate engine for execution.

**Dependencies:** `cadquery>=2.4` or `build123d` (already in optional deps). Subprocess execution for safety.

---

### ITEM 3: Validation Pipeline Integration

**Current state:**
- `D:\Claude local\production_pipeline\validate_geometry.py` — constraint checks on .scad files
- `D:\Claude local\production_pipeline\consistency_audit.py` — drift detection
- `D:\Claude local\production_pipeline\iso286_lookup.py` — ISO 286 tolerance lookup
- `D:\Claude local\production_pipeline\tolerance_stackup.py` — stackup analysis
- `backend/app/orchestrator/gate.py` — GateEnforcer runs collision + manufacturability only
- `backend/app/routes/validation.py` — loads STL files, runs GateEnforcer

**What to build:**

1. Create `backend/app/validators/geometry_validator.py`:
   - Wraps `validate_geometry.py` from production_pipeline
   - Method `validate(scad_path: Path) -> ValidationResult`
   - Runs: compile check, constraint checks, returns pass/fail with details
   - Called by GateEnforcer for OpenSCAD-based designs

2. Create `backend/app/validators/consistency_validator.py`:
   - Wraps `consistency_audit.py`
   - Method `audit(project_dir: Path) -> AuditResult`
   - Detects drift between .scad, config, and docs
   - Called after ANY change to .scad files

3. Modify `backend/app/orchestrator/gate.py`:
   - Add geometry_validator and consistency_validator to Gate 1 (Design)
   - Add B-rep validation for CadQuery outputs
   - Wire validators based on engine type (OpenSCAD vs CadQuery)

4. Modify `backend/app/routes/validation.py`:
   - Support both OpenSCAD validation (via production_pipeline tools) and CadQuery validation
   - Return detailed per-check results (not just pass/fail)

**Validation pipeline per engine:**

For OpenSCAD: compile → validate_geometry → render PNG → consistency_audit → collision → manufacturability
For CadQuery: execute script → B-rep valid → STEP export clean → collision → manufacturability

---

### ITEM 4: Rule 99 Gate Transitions

**Current state:**
- Gate field exists in DB (`projects.gate` column)
- GateEnforcer runs validators but doesn't enforce gate-specific checks
- No commands for "design locked", "prototype validated"

**What to build:**

1. Modify `backend/app/orchestrator/gate.py`:
   - Define 3 gates with their required validators:
     - Gate 1 (DESIGN): mechanism, physics, kinematic chain, vertical budget
     - Gate 2 (PROTOTYPE): ISO 286 fits, tolerance stackup, collision, FDM ground truth
     - Gate 3 (PRODUCTION): DFM, materials, BOM, FreeCAD STEP/drawings
   - Gate transition commands:
     - "design locked" → run Gate 1 checks → if pass, transition to Gate 2
     - "prototype validated" → run Gate 2 checks → if pass, transition to Gate 3
   - Auto-fire appropriate consultants per gate

2. Modify `backend/app/routes/chat.py`:
   - Detect gate transition commands in user messages
   - Route to gate enforcer before transition
   - Return consultant recommendations

3. Modify `frontend/src/components/GateStatus.tsx`:
   - Show current gate prominently
   - Show gate-specific checklist
   - Transition buttons (grayed out until checks pass)

---

### ITEM 5: ISO 286 + Tolerance Stackup Integration

**Current state:**
- `D:\Claude local\production_pipeline\iso286_lookup.py` exists and works
- `D:\Claude local\production_pipeline\tolerance_stackup.py` exists and works
- Neither is wired into the app

**What to build:**

1. Create `backend/app/validators/tolerance_validator.py`:
   - Wraps both tools
   - Method `check_fits(spec: dict) -> FitResult`: looks up ISO 286 for each shaft/hole pair
   - Method `stackup_analysis(spec: dict) -> StackupResult`: runs worst-case + RSS + Monte Carlo
   - Triggered in Gate 2

2. Add API endpoint `POST /api/projects/{id}/tolerance`:
   - Accepts component pairs and tolerance specs
   - Returns fit analysis and stackup results
   - Frontend displays in side panel

---

### ITEM 6: FreeCAD Scripting

**Current state:**
- FreeCAD MCP running at localhost:9875
- `backend/app/routes/viewer.py` has `open_file` which launches FreeCAD via subprocess
- No scripted production pipeline through FreeCAD

**What to build:**

1. Create `backend/app/engines/freecad_engine.py`:
   - Connects to FreeCAD via MCP (localhost:9875) or Python API
   - Method `convert_step(step_path: Path) -> dict`: open STEP in FreeCAD, verify solid
   - Method `export_drawings(step_path: Path) -> Path`: generate DXF/PDF production drawings
   - Method `run_fem(step_path: Path, constraints: dict) -> FEMResult`: basic FEM analysis
   - Triggered in Gate 3

2. This is lower priority — needed for production export, not for design iteration.

---

### ITEM 7: Render Preview

**Current state:**
- OpenSCAD engine has `--render` capability
- No in-app render display

**What to build:**

1. After CAD generation, automatically render a preview:
   - OpenSCAD: `openscad.com --render -o render.png` → save to project renders/ dir
   - CadQuery: trimesh → Pillow → save PNG
2. Return render image URL in chat response
3. Display render inline in ChatPanel (as `<img>`)
4. Store in `projects/{id}/renders/` with version tracking

---

### ITEM 8: Decision Conflict Detection

**Current state:**
- Decisions table has `status` field (proposed/locked/superseded)
- No auto-detection of conflicts

**What to build:**

1. Modify `backend/app/models/project.py`:
   - When adding a new decision, check if it conflicts with a locked decision on the same parameter
   - If conflict: return warning, don't auto-supersede locked decisions
   - User must explicitly unlock before overriding

2. Show conflict warnings in chat and side panel.

---

### ITEM 9: Library-First Flow

**Current state:**
- Library table exists with FTS5 search
- Library route has search endpoint
- Never called during design flow

**What to build:**

1. Modify chat agent flow:
   - Before generating from scratch, search library for similar designs
   - If match found (>0.7 similarity): present to user as starting point
   - User can: use as-is, adapt parameters, or generate fresh

2. This is a chat agent behavior change, not a new endpoint.

---

### ITEM 10: User Profile Wiring

**Current state:**
- Config has settings but no per-user profile
- Claude calls don't include user preferences

**What to build:**

1. Create `backend/app/models/profile.py`:
   - Profile stored as JSON file (single-user app)
   - Fields: printer_model, build_volume, material_defaults, tolerance_defaults, preferred_engine
   - Loaded into every Claude API call context

2. Add profile management endpoint: `GET/PUT /api/profile`

3. Frontend: settings page or side panel section for profile editing.

---

## Current File Map

```
D:\Claude local\kinetic-forge-studio\
├── backend/
│   ├── app/
│   │   ├── main.py                    # FastAPI app, 7 routers
│   │   ├── config.py                  # Settings (openscad_path, freecad_path, claude_api_key)
│   │   ├── db/
│   │   │   └── database.py            # SQLite async wrapper
│   │   ├── models/
│   │   │   └── project.py             # ProjectManager (CRUD, decisions, components)
│   │   ├── orchestrator/
│   │   │   ├── pipeline.py            # MODIFY: add ChatAgent routing
│   │   │   └── gate.py                # MODIFY: add gate-specific validators, Rule 99
│   │   ├── translator/
│   │   │   ├── classifier.py          # KEEP: fast pre-filter before Claude
│   │   │   └── question_tree.py       # KEEP: fallback when no API key
│   │   ├── engines/
│   │   │   └── openscad_engine.py     # KEEP: existing OpenSCAD per-component export
│   │   │   # CREATE: cadquery_engine.py
│   │   │   # CREATE: freecad_engine.py
│   │   ├── importers/
│   │   │   ├── photo_analyzer.py      # KEEP
│   │   │   ├── step_analyzer.py       # KEEP
│   │   │   └── stl_analyzer.py        # KEEP
│   │   ├── validators/
│   │   │   ├── collision.py           # KEEP
│   │   │   └── manufacturability.py   # KEEP
│   │   │   # CREATE: geometry_validator.py (wraps validate_geometry.py)
│   │   │   # CREATE: consistency_validator.py (wraps consistency_audit.py)
│   │   │   # CREATE: tolerance_validator.py (wraps iso286 + stackup)
│   │   └── routes/
│   │       ├── chat.py                # MODIFY: conversation history, context endpoint
│   │       ├── projects.py            # KEEP
│   │       ├── upload.py              # KEEP
│   │       ├── validation.py          # MODIFY: per-engine validation
│   │       ├── library.py             # KEEP
│   │       ├── export.py              # KEEP
│   │       └── viewer.py              # KEEP
│   ├── data/
│   │   ├── taxonomy.yaml              # KEEP (used by classifier pre-filter)
│   │   └── questions/                 # KEEP (fallback when no API key)
│   │       ├── mechanism_type.yaml
│   │       ├── motion_type.yaml
│   │       ├── material.yaml
│   │       ├── envelope_size.yaml
│   │       ├── motor_count.yaml
│   │       └── teeth.yaml
│   ├── tests/                         # Update tests for new modules
│   └── pyproject.toml                 # Add httpx dependency (for Claude API)
│
├── frontend/
│   ├── src/
│   │   ├── App.tsx                    # KEEP (layout already correct)
│   │   ├── api/
│   │   │   └── client.ts             # MODIFY: add context endpoint, profile endpoints
│   │   ├── components/
│   │   │   ├── ChatPanel.tsx          # MODIFY: clickable buttons, markdown, thinking indicator
│   │   │   ├── FileUpload.tsx         # KEEP
│   │   │   ├── GateStatus.tsx         # MODIFY: gate-specific checklists, transition buttons
│   │   │   ├── HomeScreen.tsx         # KEEP
│   │   │   └── ProjectFilesPanel.tsx  # KEEP
│   │   └── stores/
│   │       └── projectStore.ts        # KEEP
│   ├── package.json                   # Add markdown rendering dep (react-markdown)
│   └── vite.config.ts                 # KEEP
│
└── .env (create if needed for KFS_CLAUDE_API_KEY)

External tools to integrate:
├── D:\Claude local\production_pipeline\
│   ├── validate_geometry.py           # Wire into geometry_validator.py
│   ├── consistency_audit.py           # Wire into consistency_validator.py
│   ├── iso286_lookup.py               # Wire into tolerance_validator.py
│   └── tolerance_stackup.py           # Wire into tolerance_validator.py
│
└── D:\Claude local\3d_design_agent\   # Design knowledge, Rule 99 specs
```

## Execution Order

**Phase A — Chat Agent (Items 1 + 7)** — Makes the app actually usable
1. Create `chat_agent.py` with Claude API integration
2. Modify `pipeline.py` to route through ChatAgent when API key present
3. Modify `chat.py` route for conversation history
4. Modify `ChatPanel.tsx` for clickable buttons + markdown + render preview
5. Add render preview after generation (inline image in chat)
6. Test end-to-end: user message → Claude → response with options → iterate

**Phase B — CAD Generation (Item 2)** — Makes the app produce real output
7. Create `cadquery_engine.py` with subprocess execution
8. Wire engine selection logic into pipeline
9. Chat agent generates code → engine executes → returns STEP/STL
10. Test: full loop from intent to file output

**Phase C — Validation (Items 3 + 5)** — Makes output reliable
11. Create `geometry_validator.py`, `consistency_validator.py`, `tolerance_validator.py`
12. Modify `gate.py` to use all validators per gate
13. Modify `validation.py` route for detailed per-check results
14. Test: validation catches real issues

**Phase D — Gates (Item 4)** — Makes the process structured
15. Implement gate transition commands
16. Modify GateStatus.tsx for gate-specific UI
17. Test: "design locked" → Gate 2 checks → transition

**Phase E — Polish (Items 6, 8, 9, 10)** — Nice to have
18. FreeCAD engine (production drawings)
19. Decision conflict detection
20. Library-first search flow
21. User profile management

---

## Key Rules

1. **App is the brain, tools are workers.** The orchestrator (deterministic Python) makes ALL decisions. Claude is one tool among many.
2. **Zero warnings means zero.** Validation must pass clean.
3. **All dimensions in millimeters.** Named constants, never literal numbers.
4. **Classifier is a pre-filter, not the brain.** It extracts obvious params to save Claude API costs. Claude handles judgment.
5. **Conversation history must persist.** User should be able to close browser and resume.
6. **Engine selection is automatic but overridable.** .scad files → OpenSCAD. New designs → CadQuery/build123d.
7. **Existing production_pipeline tools are proven code.** Wrap them, don't rewrite them.
8. **The frontend layout is already correct.** Don't change the 3-column layout. Just enhance components.
9. **Keep the YAML fallback.** When no Claude API key, the classifier + question tree still works.
10. **httpx for Claude API calls** (already a FastAPI standard, async-native).

---

## Servers

- Backend: `cd D:\Claude local\kinetic-forge-studio\backend && uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload`
- Frontend: `cd D:\Claude local\kinetic-forge-studio\frontend && npm run dev` (Vite on port 5173)
- FreeCAD MCP: localhost:9875 (manual start via FreeCAD Python console)

## Testing

- Backend: `cd D:\Claude local\kinetic-forge-studio\backend && python -m pytest tests/`
- Frontend: `cd D:\Claude local\kinetic-forge-studio\frontend && npx tsc --noEmit`
- Validate pipeline tools: `cd D:\Claude local\production_pipeline && python validate_geometry.py --help`
