# Kinetic Forge Studio — Design Document V2

**Date:** 2026-02-23
**Updated:** 2026-02-23
**Status:** Updated — incorporates lessons from V1 implementation
**Supersedes:** `2026-02-23-kinetic-forge-studio-design.md` (V1)

---

## Changes from V1

| # | V1 Said | V2 Says | Why |
|---|---------|---------|-----|
| 1 | "User never leaves the app" | App is an orchestrator that links to native apps | User opens OpenSCAD/FreeCAD for viewing; app coordinates |
| 2 | Three.js/R3F viewport for 3D | Native app launchers + render PNG preview | Helical gear meshes (300K+ faces) broke WebGL; native apps handle this |
| 3 | YAML question tree primary, Claude for ambiguity | Claude API primary for chat, keyword classifier as fast pre-filter | Rigid YAML tree can't handle "3", custom values, or natural feedback |
| 4 | CadQuery only for B-rep | CadQuery OR build123d for B-rep | build123d is newer, more Pythonic, same OCP kernel |
| 5 | No mention of existing pipeline tools | Integrates validate_geometry.py, consistency_audit.py, iso286_lookup.py, tolerance_stackup.py | These exist at D:\Claude local\production_pipeline\ and must be wired in |
| 6 | No Rule 99 integration | Rule 99 consultant pipeline wired into gate transitions | Rule 99 is the user's established design methodology |
| 7 | CadQuery generates placeholder shapes | CAD engines generate REAL production geometry from specs | Placeholder boxes/cylinders serve no purpose |
| 8 | P5.js, R3F, Three.js, Pillow in dependencies | Remove R3F/Three.js; keep P5.js (future), Pillow (future) | Viewport dropped; P5.js motion preview deferred |
| 9 | Video analyzer with ffmpeg | Deferred — not part of core loop | Can add later; not blocking design workflow |

---

## 1. Vision

A standalone web application that orchestrates the kinetic sculpture design process. The app coordinates external tools (Claude API, CadQuery/build123d, OpenSCAD, FreeCAD, trimesh, validation scripts) to produce production-level 3D designs for 3D printing and CNC machining. The user provides intent and feedback through chat; the app generates, validates, and iterates parametric CAD code. Native apps (OpenSCAD, FreeCAD, Fusion 360) are used for viewing and final production — the app links to them, not replaces them.

### Strategic Phases

1. **Replace Friction** — 1-3 design iterations instead of 5-20. Chat -> clarify -> generate -> validate -> open in native app -> feedback -> iterate.
2. **Accelerate Exploration** — Reference library grows with every project. After 50+ designs, the app finds the closest match and adapts rather than generating from scratch.
3. **Enable Production** — Every validated design exports clean STEP -> Fusion 360 -> metal + wood fabrication.

---

## 2. Architecture

```
+------------------------------------------------------------------+
|                     BROWSER (React)                               |
|                                                                   |
|  +----------+  +--------------------+  +----------------------+   |
|  |  Chat /  |  |  Project Files     |  |  Side Panel          |   |
|  |  Intent  |  |  + Native App      |  |  - Spec Sheet        |   |
|  |  Panel   |  |    Launchers       |  |  - Decision Log      |   |
|  |          |  |  + Render Preview  |  |  - Components        |   |
|  |  (left)  |  |  (center)          |  |  - Library Search    |   |
|  |          |  |                    |  |  - Gate Status       |   |
|  +----------+  +--------------------+  +----------------------+   |
|  +--------------------------------------------------------------+ |
|  |  Timeline: checkpoints / version history / rollback           | |
|  +--------------------------------------------------------------+ |
+-----------------------------+------------------------------------+
                              | REST
+-----------------------------+------------------------------------+
|                     FastAPI (Python)                               |
|                                                                   |
|  +------------+  +------------+  +------------+  +------------+   |
|  | Claude API |  |Orchestrator|  |   Gate     |  |  Existing  |   |
|  | Chat Agent |  | (Pipeline) |  |  Enforcer  |  |  Pipeline  |   |
|  |            |  |            |  |  + Rule 99 |  |  Tools     |   |
|  +------------+  +------------+  +------------+  +------------+   |
|                                                                   |
|  +------------+  +------------+  +------------+  +------------+   |
|  |  CadQuery  |  |  OpenSCAD  |  |  FreeCAD   |  |  trimesh   |   |
|  | /build123d |  |  Engine    |  |  Engine    |  |            |   |
|  +------------+  +------------+  +------------+  +------------+   |
|                                                                   |
|  +------------+  +------------+  +------------+  +------------+   |
|  |  Library   |  |  Profile   |  |  Decision  |  | Component  |   |
|  |  (SQLite)  |  |  Store     |  |  Journal   |  | Registry   |   |
|  +------------+  +------------+  +------------+  +------------+   |
+------------------------------------------------------------------+
```

### Core Principle

The app is the brain. Every external tool (Claude API, CadQuery, build123d, OpenSCAD, FreeCAD, trimesh, validate_geometry.py) is a stateless worker. The orchestrator calls them, gets results, decides the next step. Claude is one tool among many. No tool makes decisions. The orchestrator (deterministic Python code) makes ALL decisions.

### Existing Pipeline Tools (already built, must integrate)

Located at `D:\Claude local\production_pipeline\`:
- `validate_geometry.py` — constraint checks on .scad files
- `consistency_audit.py` — drift detection across .scad + config + docs
- `iso286_lookup.py` — ISO 286 shaft/hole tolerance lookup
- `tolerance_stackup.py` — worst-case + RSS + Monte Carlo stackup analysis

Located at `D:\Claude local\3d_design_agent\`:
- Design knowledge, Margolin knowledge bank, Rule 99 specs
- Existing .scad projects with BOSL2 (Ravigneaux V13, Triple Helix, etc.)

---

## 3. Input Modes

All modes feed the same Unified Spec Builder. Can be combined.

### 3.1 Chat (Primary)

- Free-flowing natural language conversation
- **Claude API is the primary chat engine** (user chose Approach B)
- Keyword classifier runs as a fast pre-filter (zero API cost) to extract obvious parameters before sending to Claude
- Claude handles: ambiguity, custom values ("3 motors"), trade-off explanations, iterative feedback, code generation
- Every Claude call auto-includes: current spec, locked decisions, component registry, user profile
- "Just Do It" mode: short imperative messages bypass clarification, go straight to code edit

### 3.2 Photo Upload

- Upload 1-8 photos of a kinetic sculpture or mechanism
- Claude Vision API analyzes: mechanism type, component count, motion path, dimensions
- Output: pre-filled spec sheet feeding normal pipeline

### 3.3 3D File Import

- STEP: B-rep analysis via CadQuery (face types, dimensions, holes, tooth counts)
- STL: Reference-only via trimesh (bounding box, volume, watertight check)
- Two paths: (A) extract dimensions into spec, generate fresh parametric design; (B) attempt parametric reconstruction for simple parts

### 3.4 Video Upload (deferred)

- Not part of initial rebuild. Can add later via ffmpeg + Claude Vision.

---

## 4. CAD Engines

All engines run headless. The orchestrator picks the right one.

| Engine | Role | When Used | Output |
|--------|------|-----------|--------|
| CadQuery / build123d | PRIMARY B-rep generation | Default for all new designs | STEP, STL, glTF |
| OpenSCAD (Nightly + BOSL2) | CSG iteration | Existing .scad files, CSG-specific, quick iteration | STL, CSG |
| FreeCAD (headless via MCP) | Production conversion | STEP -> drawings, DXF/PDF, FEM analysis | DXF, PDF, FEM |

### Engine Selection Logic

1. If user has existing .scad files linked (scad_dir) -> OpenSCAD for iteration
2. If user needs B-rep STEP output directly -> CadQuery/build123d
3. If user needs production drawings/FEM -> FreeCAD via MCP
4. User can override engine selection

### What the Chat Agent Generates

- For CadQuery engine: Python script using CadQuery API -> executed -> produces STEP/STL
- For build123d engine: Python script using build123d API -> executed -> produces STEP/STL
- For OpenSCAD engine: .scad file following user's template (header, $fn, tolerances, named constants, SHOW flags, BOSL2) -> compiled via CLI -> produces STL
- The agent MODIFIES specific constants on iteration, not full rewrites

---

## 5. Visualization

### 5.1 Native App Launchers (Primary — implemented)

- ProjectFilesPanel lists all project files (.scad, .step, .stl) with metadata
- "Open in OpenSCAD" / "Open in FreeCAD" buttons launch native apps
- Per-component SHOW flags listed with color swatches
- Link to source directory

### 5.2 Render Preview (In-app)

- After generation, run headless render (OpenSCAD CLI `--render` or CadQuery -> trimesh -> Pillow)
- Show render PNG in the app for quick visual check without opening native app
- Not interactive — just a snapshot

### 5.3 Visual Diff (future)

- Pillow ImageChops comparison between version renders
- Available in timeline

---

## 6. Validation & Gate Enforcement

All validation runs locally. No API calls. Gates are enforced — buttons grayed out until checks pass.

### Validation Pipeline (runs after every generation)

**For OpenSCAD-based designs:**
1. Compile — `openscad.com -o test.csg` — zero errors, zero warnings
2. `validate_geometry.py` — constraint checks — zero FAILs
3. Render PNG — `openscad.com --render` — visual inspection
4. `consistency_audit.py` — drift detection — zero FAILs

**For CadQuery/build123d designs:**
1. Execute Python script — no exceptions
2. B-rep validation — all solids are valid, no self-intersections
3. Export STEP — verify clean export

**For all designs:**
5. Collision detection — trimesh, no body intersections
6. Wall thickness — FDM manufacturability, minimum per material
7. Watertight check — mesh integrity
8. Overhang angle — FDM printability
9. Envelope check — fits within specified dimensions
10. Vertical budget — Z-stack fits

### Gate System (Rule 99 Integration)

**Gate 1: DESIGN**
- Consultants: mechanism, physics, kinematic chain, vertical budget
- Triggered by: design conversation reaching spec-complete
- Output: locked geometry, approved spec sheet

**Gate 2: PROTOTYPE** (triggered by "design locked")
- Consultants: ISO 286 fits (`iso286_lookup.py`), tolerance stackup (`tolerance_stackup.py`), collision, FDM ground truth
- Output: validated prototype, STL export for printing

**Gate 3: PRODUCTION** (triggered by "prototype validated")
- Consultants: DFM, materials, BOM, FreeCAD STEP/drawings/FEM
- Output: full production export package

### Enforcement

- Zero warnings means zero
- Buttons grayed out until checks pass
- Auto-retry on validation failure (max 3 attempts, app adjusts params)
- Environment pre-check before any operation

---

## 7. Project Memory & Persistence

(No changes from V1 — sections 7.1 through 7.5 carry forward as-is)

- Project structure with spec_sheet.yaml, decision_journal.json, component_registry.json, sessions/, references/, models/, exports/, renders/, validation/
- Decision log with locked/proposed/superseded states and conflict detection
- Component identity registry with permanent IDs
- Session persistence and full context restoration
- User profile persisting across all projects

---

## 8. Reference Library

(No changes from V1 — section 8 carries forward)

- SQLite FTS5 full-text search
- Library-first design: search BEFORE generating from scratch
- Cross-project reuse with traceability

---

## 9. Iteration & Feedback Loops

Three loops:

1. **Chat -> Regeneration:** User gives feedback ("gear too big", "add clearance") -> agent modifies specific constants -> re-validates -> shows render
2. **Native App -> Chat:** User opens in OpenSCAD, sees issue, reports in chat -> agent understands and fixes
3. **Validation -> Auto-retry:** Check fails -> app adjusts parameters (max 3 attempts) -> if still failing, surfaces error with explanation

### "Just Do It" Mode

Short, imperative messages -> constrained edit, no analysis, no alternatives.

---

## 10. Output & Export

```
export_package/
+-- spec_sheet.yaml              # frozen design spec
+-- decision_journal.json        # every choice with reasoning
+-- assembly.step                # production-ready B-rep (via CadQuery)
+-- parts/
|   +-- ring_gear.step
|   +-- sun_gear.step
+-- assembly.stl                 # for 3D printing
+-- validation_report.html       # all checks passed
+-- renders/
|   +-- isometric.png
|   +-- front.png
+-- source/
|   +-- design.py                # CadQuery/build123d script
|   +-- design.scad              # if OpenSCAD was used
+-- scad/                        # original .scad source files if linked
```

- One-click "Export for Fusion 360" bundles STEP files
- One-click "Export for Print" bundles STL + print settings

---

## 11. AI & Cost Management

### Claude-Powered Chat (Approach B)

Every call to Claude auto-includes:
- Current spec sheet
- Relevant locked decisions
- Component registry
- User profile (printer, material, preferences)
- Specific error or question (focused)
- Conversation history for context

### Model Routing

| Task | Model | Why |
|------|-------|-----|
| Chat, clarification, code generation | Claude API | Best at judgment, tradeoffs, code |
| Photo analysis | Claude Vision | Built into Claude API |
| Validation, collision, measurements | No LLM | Deterministic tools, zero cost |
| Bulk generation (optional) | Gemini | Cheaper fallback if Claude fails 2x |

---

## 12. UX Layout

### Home Screen
```
+---------------------------------------------+
|  + New Project     Recent Projects:         |
|                    > ravigneaux_compact_v2   |
|                    > triple_helix_mvp        |
|                                             |
|  Reference Library: 47 designs indexed      |
|  [Search...]                                |
+---------------------------------------------+
```

### Design Workspace
```
+----------+-----------------------+--------------+
|  Chat /  |  Project Files        |  Spec Sheet  |
|  Intent  |  + Native App Launch  |  Decisions   |
|  Panel   |  + Render Preview     |  Components  |
|  (left)  |  (center)             |  Library     |
|          |                       |  Gate Status |
+----------+-----------------------+--------------+
|  Timeline: *v1 --- *v2 --- *v3    [Export v]   |
+------------------------------------------------+
```

---

## 13. Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| Python 3.11+ | Backend runtime | System |
| FastAPI | Async web framework | pip |
| React 18 | Frontend UI framework | npm |
| CadQuery | B-Rep geometry generation | pip/conda |
| build123d | Alternative B-Rep generation | pip |
| OpenSCAD (Nightly) | CSG compilation | System install |
| FreeCAD 1.0+ | Production drawings, FEM | System install |
| trimesh | Mesh analysis, collision | pip |
| Pillow | Render image processing | pip |
| SQLite | Local database | Built into Python |
| Claude API | Chat agent + Vision | API key |
| Gemini API (optional) | Fallback generation | API key |

Removed from V1: React-Three-Fiber, Three.js, P5.js (deferred), python-fcl (trimesh sufficient), ffmpeg (video deferred)

---

## 14. What Exists vs What Needs Building

### Already Built and Working
- FastAPI backend scaffold with all routes
- SQLite database with projects, decisions, components, library tables
- React frontend with HomeScreen, ChatPanel, ProjectFilesPanel, GateStatus, FileUpload
- OpenSCAD engine (CLI export, per-component isolation, caching)
- STEP analyzer (CadQuery B-rep parsing)
- STL analyzer (trimesh)
- Photo analyzer (Claude Vision, with mock fallback)
- Collision + manufacturability validators
- Gate enforcer (runs validators, returns pass/fail)
- Reference library with FTS5 search
- Native app launcher (OpenSCAD, FreeCAD)
- Export package (bundles actual project files)
- Project memory (scad_dir linking, decision CRUD)

### Needs Building (Priority Order)
1. **Claude-powered chat agent** — replace rigid YAML question tree with Claude API
2. **CadQuery/build123d generation engine** — generate real B-rep geometry from specs (not placeholder shapes)
3. **Validation pipeline integration** — wire validate_geometry.py, consistency_audit.py into gate system
4. **Rule 99 gate transitions** — "design locked" and "prototype validated" commands
5. **ISO 286 + tolerance stackup integration** — wire existing Python tools into Gate 2
6. **FreeCAD scripting** — production STEP export, drawings via FreeCAD Python API / MCP
7. **Render preview** — headless render shown in-app after generation
8. **Decision conflict detection** — auto-flag when new decision conflicts with locked one
9. **Library-first flow** — search library before generating from scratch
10. **User profile wiring** — inject printer/material prefs into Claude calls and validation
