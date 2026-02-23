# Kinetic Forge Studio — Design Document

**Date:** 2026-02-23
**Status:** Approved
**Supersedes:** `2026-02-22-geometry-agent-design.md` (CLI geometry-agent concept → evolved into standalone web app)

---

## 1. Vision

A standalone web application for designing kinetic sculptures. The app is the orchestrator — it calls CAD engines, validators, and AI services as tools, enforces all gates, and maintains persistent project memory. The user never leaves the app during design. The only external handoff is STEP export to Fusion 360 for final production (CNC, waterjet, metal/wood fabrication).

### Strategic Phases

1. **Replace Friction** — 1-3 design iterations instead of 5-20. Chat → preview → generate → validate → done.
2. **Accelerate Exploration** — Reference library grows with every project. After 50+ designs, the app rarely generates from scratch — it finds the closest match and adapts.
3. **Enable Production** — Every validated design exports clean STEP → Fusion 360 → metal + wood.

---

## 2. Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                     BROWSER (React + R3F)                        │
│                                                                  │
│  ┌──────────┐  ┌────────────────────┐  ┌──────────────────────┐ │
│  │  Chat /   │  │   3D Viewport      │  │  Side Panel          │ │
│  │  Intent   │  │   (R3F / Three.js) │  │  - Spec Sheet        │ │
│  │  Panel    │  │   + P5.js Preview  │  │  - Decision Log      │ │
│  │           │  │                    │  │  - Components        │ │
│  │  (left)   │  │   (center)         │  │  - Library Search    │ │
│  │           │  │                    │  │  - Gate Status       │ │
│  └──────────┘  └────────────────────┘  └──────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────────┐│
│  │  Timeline: checkpoints / version history / rollback          ││
│  └──────────────────────────────────────────────────────────────┘│
└───────────────────────────┬──────────────────────────────────────┘
                            │ REST + WebSocket
┌───────────────────────────┴──────────────────────────────────────┐
│                     FastAPI (Python)                              │
│                                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐│
│  │ Translator │  │Orchestrator│  │   Gate     │  │ Claude API ││
│  │ (NLP→Spec) │  │ (Pipeline) │  │  Enforcer  │  │  Router    ││
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘│
│                                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐│
│  │  CadQuery  │  │  OpenSCAD  │  │  FreeCAD   │  │  trimesh   ││
│  │  Engine    │  │  Engine    │  │  Engine    │  │  + FCL     ││
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘│
│                                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐│
│  │  Library   │  │  Profile   │  │  Decision  │  │ Component  ││
│  │  (SQLite)  │  │  Store     │  │  Journal   │  │ Registry   ││
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘│
└──────────────────────────────────────────────────────────────────┘
```

### Core Principle

The app is the brain. Every external tool (Claude API, CadQuery, OpenSCAD, FreeCAD, trimesh, ffmpeg) is a stateless worker. The orchestrator calls them, gets results, decides the next step. Claude is one tool among many — same level as CadQuery. No tool makes decisions. The orchestrator (deterministic Python code) makes ALL decisions.

---

## 3. Four Input Modes

All four modes feed the same Unified Spec Builder. They can be combined — upload a photo AND type a description AND import a STEP file → all merge into one spec.

### 3.1 Text Input

- Chat interface, freeform natural language
- Three-phase translator:
  - **Phase 1 (Intake):** Local keyword classifier, zero API cost. Identifies mechanism type, envelope, material from keywords.
  - **Phase 2 (Interview):** Two paths — (A) YAML question tree for common unknowns (free, instant, pre-built with impact explanations: "Slow → scotch yoke. Lively → crank.") or (B) Claude API call for genuine ambiguity the YAML can't resolve.
  - **Phase 3 (Confirm):** Show assembled spec sheet, user approves or modifies. No API cost.
- Budget: ~70% of conversations handled entirely by YAML questions (free). Claude called only for complex ambiguity.

### 3.2 Photo Upload

- Upload 1-8 photos of a kinetic sculpture or mechanism
- Claude Vision API analyzes all photos in a single call: identifies mechanism types, estimates component count, describes motion path, estimates dimensions
- Multi-angle extrapolation: front + side → estimate depth, close-up → refine gear teeth count. If angles missing, app asks user to provide specific views.
- Clarifying questions generated from analysis ("I see what looks like a compound planetary. Are there 2 or 3 planet gears?")
- Output: pre-filled spec sheet → normal pipeline continues

### 3.3 Video Upload

- Upload video (MP4, MOV) of mechanism in motion
- ffmpeg extracts key frames (1/sec + extra at state changes, 10-30 frames total)
- Claude Vision receives frame sequence: identifies what moves vs. fixed, motion type per component, tempo estimate, phase relationships, cycle boundaries
- P5.js generates motion recreation shown side-by-side with original video for user verification
- Output: spec sheet WITH motion profile (position vs. time for key points)

### 3.4 3D File Import

Format priority: STEP > IGES > BREP > 3MF > STL > OBJ

**STEP files (.step/.stp):** Full B-Rep analysis via CadQuery — exact dimensions, face types (plane, cylinder, cone, sphere, spline), edge types (line, circle, arc), hole positions, shaft diameters, tooth counts. Feature detection for repeated patterns (gear teeth, array elements). Component segmentation for multi-body assemblies.

**STL files (.stl):** Reference-only mode. trimesh extracts bounding box, volume, surface area. Used as visual overlay (wireframe) alongside new parametric geometry (solid). App is honest: "I can measure dimensions but can't extract features. Do you have a STEP version?"

**Two paths after import:**
- **Path A (Use as Reference):** Extract key dimensions into spec sheet. Generate fresh parametric geometry that matches those dimensions. Show overlay comparison: original wireframe + new solid, differences in red. Recommended for complex assemblies.
- **Path B (Parametric Reconstruction):** Attempt to rebuild as CadQuery primitives. Works for simple mechanical parts (gears, shafts, brackets). App detects when shape is too complex and offers Path A instead.

---

## 4. Preview & Visualization

### 4.1 P5.js Preview (Before Generation)

- Fast wireframe animation showing motion, not geometric detail
- Purpose: "Is this the right movement?" — verify intent before committing to CAD generation
- Instant. Approximate. Runs in browser.

### 4.2 Three.js/R3F Viewport (After Generation)

- Real interactive 3D model — not a screenshot, not a render
- CadQuery generates B-Rep → exports glTF → Three.js loads in browser GPU
- Standard viewport controls matching industry convention:
  - Orbit: left-click drag
  - Pan: right-click drag / middle-click
  - Zoom: scroll wheel
  - Preset views: Front, Top, Right, Isometric buttons
- Advanced modes:
  - Exploded view: parts spread apart to see internals
  - Wireframe: see through solid surfaces
  - X-ray / transparency: see internal components
- Click-to-select: click any component → sidebar shows its parameters
- All verification happens in-app. No need to open external software.

### 4.3 Visual Diff

- Pillow ImageChops comparison between version renders
- Changes highlighted for quick identification
- Available in timeline — click two checkpoints to compare

### 4.4 Overlay Comparison (for imports)

- Original file as wireframe (transparent)
- New parametric model as solid
- Deviations highlighted in red
- Used during STEP/STL import → parametric rebuild workflow

---

## 5. CAD Engines

All engines run headless (no GUI window). The app calls them as libraries or CLI tools and receives geometry back.

| Engine | Role | When Used | Output |
|--------|------|-----------|--------|
| CadQuery | Primary generation | Default for all new designs | B-Rep → STEP, glTF |
| OpenSCAD (Nightly) | CSG compilation | Existing .scad templates, CSG-specific designs | STL, CSG |
| FreeCAD (headless) | Format conversion | STEP → drawings, DXF/PDF, FEM analysis | DXF, PDF, FEM results |

Engine selection: CadQuery by default. OpenSCAD when user has existing .scad files or needs CSG operations. FreeCAD only for format conversion and production drawings. User can override.

---

## 6. Validation & Gate Enforcement

All validation runs locally. No API calls. The app enforces gates — buttons are grayed out until all checks pass.

### Validation Pipeline (runs after every generation)

1. **Compile check** — geometry generates without errors
2. **Collision detection** — trimesh + python-fcl, no body intersections
3. **Wall thickness** — FDM manufacturability, minimum wall per material
4. **Watertight check** — mesh integrity for STL export
5. **Overhang angle** — FDM printability (configurable threshold)
6. **Bridge distance** — FDM printability
7. **Vertical budget** — Z-stack fits within envelope
8. **Envelope check** — radial fit within constraints

### Gate Enforcement

- Zero warnings means zero. Compile must return literally 0 warnings.
- Environment pre-check before any operation: verify tool paths, library paths, tool versions.
- Buttons grayed out until checks pass. No manual override for critical gates.
- Auto-retry on validation failure: app adjusts parameters and re-generates, max 3 attempts. If all fail, surfaces error to user with explanation.

### Validation Report

- HTML report documenting all checks passed/failed
- Saved as artifact per version checkpoint

---

## 7. Project Memory & Persistence

### 7.1 Project Model

Each design is a Project containing:

```
project_ravigneaux_compact_v2/
├── project.json              # metadata, status, gate, timestamps
├── spec_sheet.yaml           # frozen design spec (after approval)
├── decision_journal.json     # every choice with ID, reason, source, timestamp, lock status
├── component_registry.json   # every part: ID, name, position, parameters, links to decisions
├── sessions/
│   ├── session_001.json      # transcript, indexed by topic, linked to decisions
│   └── session_002.json
├── references/
│   ├── ravigneaux_unit.step  # imported STEP file
│   ├── inspiration.jpg       # uploaded photo
│   └── mechanism_video.mp4   # uploaded video
├── models/
│   ├── v1_design.py          # CadQuery source
│   └── v2_design.py
├── exports/
│   ├── assembly.step
│   ├── assembly.stl
│   └── parts/
│       ├── ring_gear.step
│       └── sun_gear.step
├── renders/
│   ├── v1_isometric.png
│   ├── v2_isometric.png
│   └── v1_v2_diff.png
└── validation/
    ├── v1_report.html
    └── v2_report.html
```

### 7.2 Decision Log

Every design choice is a first-class object:

```json
{
  "id": 1,
  "parameter": "ring_gear.OD",
  "value": "82mm",
  "reason": "Fits inside 85mm housing",
  "source": "user",
  "session": "session_001",
  "timestamp": "2026-02-22T10:14:00",
  "status": "locked",
  "superseded_by": null
}
```

- Decisions can be LOCKED (immutable unless explicitly unlocked by user), PROPOSED, or SUPERSEDED.
- When a new decision conflicts with a locked one, the app flags it immediately: "Decision [4] changes module from 1.5 to 1.0, which conflicts with locked decision [2]. Update [2] or keep old value?"
- Conflict detection is automatic — the app tracks which parameters each decision affects.

### 7.3 Component Identity Registry

Every part has a locked identity:

```json
{
  "id": "ring_gear_01",
  "display_name": "Ring Gear",
  "type": "gear",
  "parameters": {"teeth": 48, "module": 1.5, "OD": 82.0},
  "position": {"x": 0, "y": 0, "z": 12.0},
  "decided_by": [1, 2],
  "created_in": "session_001"
}
```

- IDs are permanent once assigned. The app (and Claude) can never confuse "ring_gear_01" with "sun_gear_01."
- The full registry is injected into every Claude API call automatically.

### 7.4 Session Persistence

- Session transcripts are saved, indexed by topic, and linked to decisions.
- Reopening a project restores full context: viewport state, spec sheet, decision log, all files.
- No re-uploading, no re-explaining. Everything persists.

### 7.5 User Profile

Persists across ALL projects:

```yaml
printer:
  type: FDM
  nozzle: 0.4mm
  layer_height: 0.2mm
  tolerance: 0.2mm
  min_wall: 1.5mm
  max_overhang: 45deg

preferences:
  default_material: PLA
  default_module: 1.5
  preferred_mechanisms: [four_bar, planetary, scotch_yoke]
  shaft_standard: 8mm

style_tags: [organic, wave, breathing, museum_quality]
production_target: metal_and_wood
```

---

## 8. Reference Library

### 8.1 Auto-Indexing

Every completed design, every imported file, every reference is indexed in SQLite:

```sql
CREATE TABLE library (
  id TEXT PRIMARY KEY,
  name TEXT,
  source TEXT,           -- 'project', 'import', 'download'
  mechanism_types TEXT,  -- JSON array: ['planetary', 'spur_gear']
  keywords TEXT,         -- full-text searchable
  envelope_x REAL,
  envelope_y REAL,
  envelope_z REAL,
  file_path TEXT,
  thumbnail_path TEXT,
  created_at TIMESTAMP,
  project_id TEXT        -- link to source project if applicable
);
```

### 8.2 Library-First Design

When the user describes a new design, the app searches the library BEFORE generating from scratch:

- **Phase 1 (keywords):** Show rough matches in sidebar based on initial description.
- **Phase 3 (full spec):** Show best match with similarity score. User can click to load as starting point and adapt parameters instead of generating fresh.

### 8.3 Cross-Project Reuse

A gear designed in Project A is available as a reference in Project B. The app creates a link back to the source project, maintaining traceability.

---

## 9. Iteration & Feedback Loops

Three explicit feedback loops, not a linear pipeline:

1. **P5.js → Chat:** Motion preview doesn't match intent → user refines description → new preview.
2. **Three.js → Regeneration:** Geometry is off → user tweaks parameters in sidebar or describes change in chat → app re-generates.
3. **Validation → Auto-retry:** Check fails → app adjusts parameters automatically (max 3 attempts) → if still failing, surfaces error to user with explanation and suggestions.

### "Just Do It" Mode

When the user gives a direct fix instruction (detected by short, imperative messages or repeated requests), the app sends it to Claude as a constrained edit — not open-ended generation. No analysis, no alternatives, just the change applied.

---

## 10. Output & Export

A completed project exports:

```
export_package/
├── spec_sheet.yaml              # frozen design spec
├── decision_journal.json        # every choice with reasoning
├── assembly.step                # production-ready, all parts
├── parts/
│   ├── ring_gear.step
│   ├── sun_gear.step
│   └── ...                      # individual parts for CNC/waterjet
├── assembly.stl                 # for 3D printing prototype
├── validation_report.html       # all checks passed
├── renders/
│   ├── isometric.png
│   ├── front.png
│   └── exploded.png
└── source/
    ├── design.py                # CadQuery script (reproducible)
    └── design.scad              # if OpenSCAD was used
```

- One-click "Export for Fusion 360" bundles STEP files.
- One-click "Export for Print" bundles STL + print settings.

---

## 11. AI & Cost Management

### Smart Claude API Calls

Every call to Claude includes (auto-assembled by the orchestrator):
- Current spec sheet
- Relevant locked decisions
- Component registry
- User profile (printer, material, preferences)
- Specific error or question (focused, not open-ended)

Target: 2-5 Claude API calls per design, at ~$0.10-0.50 each.

### Multi-Model Routing

| Task | Model | Why |
|------|-------|-----|
| Parameter reasoning | Claude | Best at judgment and tradeoffs |
| Mechanism identification from photos/video | Claude Vision | Built into Claude API |
| Bulk code generation (if needed) | Gemini (optional) | Cheaper, faster for straightforward generation |
| Validation, collision, measurements | No LLM | Deterministic tools, zero cost |

### Failure-Aware Routing

If Claude fails 2x on the same geometry type, the app can route to Gemini as an alternative. The orchestrator tracks success/failure per model per task type.

---

## 12. UX Layout

### Home Screen

```
┌─────────────────────────────────────────────┐
│  + New Project     Recent Projects:         │
│                    ► ravigneaux_compact_v2   │
│                    ► triple_helix_mvp        │
│                    ► starry_night_wave_v24   │
│                                             │
│  Reference Library: 47 designs indexed      │
│  [Search...]                                │
└─────────────────────────────────────────────┘
```

### Design Workspace

```
┌──────────┬───────────────────────┬──────────────┐
│  Chat /  │   3D Viewport         │  Spec Sheet  │
│  Intent  │   (R3F interactive)   │  Decisions   │
│  Panel   │   + P5.js preview     │  Components  │
│  (left)  │   (center)            │  Library     │
│          │                       │  Gate Status │
├──────────┴───────────────────────┴──────────────┤
│  Timeline: ◆v1 ─── ◆v2 ─── ◆v3    [Export ▼]  │
└─────────────────────────────────────────────────┘
```

### Status Indicators

- Pipeline progress: ✅ Compiled ✅ Validated ✅ Rendered (or ❌ with details)
- Gate indicator: "Gate 1: DESIGN — 4 decisions locked, 1 conflict pending"
- Buttons grayed out when gate requirements not met

---

## 13. Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| Python 3.11+ | Backend runtime | System |
| FastAPI | Async web framework | pip |
| React 18 | Frontend UI framework | npm |
| React-Three-Fiber | 3D viewport in React | npm |
| Three.js | 3D rendering engine | npm (via R3F) |
| P5.js | Quick motion previews | npm/CDN |
| CadQuery | B-Rep geometry generation | pip/conda |
| OpenSCAD (Nightly) | CSG compilation | System install |
| FreeCAD 1.0+ | Format conversion (headless) | System install |
| trimesh | Mesh analysis, collision | pip |
| python-fcl | Precise collision detection | pip |
| Pillow | Image processing, visual diff | pip |
| ffmpeg | Video frame extraction | System install |
| SQLite | Local database | Built into Python |
| Claude API | AI reasoning (text + vision) | API key |
| Gemini API (optional) | Alternative bulk generation | API key |

All tools are free/open-source except Claude API (~$0.10-0.50/design) and optional Gemini API (~$0.01-0.05/call).

---

## 14. What This Document Supersedes

- `2026-02-22-geometry-agent-design.md` — the CLI geometry-agent concept. The architectural layers (Translator, Orchestrator, Geometry Kernel) carry forward, but the delivery mechanism changed from CLI tool to standalone web app with persistent project memory, interactive 3D viewport, and multi-modal input.
- `2026-02-22-geometry-agent-implementation.md` — the 22-task implementation plan for the CLI tool. A new implementation plan will be created for this app.

---

## 15. Pain Points Addressed

| # | Pain Point (from real design history) | App Feature |
|---|---------------------------------------|-------------|
| 1 | Claude second-guesses user's visual feedback | Visual diff as ground truth; user input = constraint |
| 2 | Claude confuses top/bottom, inner/outer | Component Identity Registry with locked IDs |
| 3 | Fix A breaks B, fix B re-breaks A | Immutable baseline + change isolation |
| 4 | Obvious spatial errors not caught | Automated collision + spatial sanity checks |
| 5 | Claude analyzes instead of executing direct instructions | "Just Do It" mode — constrained edit |
| 6 | Wrong AI model for the job | Multi-model routing (Claude/Gemini/none) |
| 7 | Absolute coordinates break when one part moves | Assembly graph with constraint-based placement |
| 8 | Magic numbers in transforms | Parametric validator rejects literals |
| 9 | Library loading failures cascade | Environment pre-check |
| 10 | "Zero warnings" not enforced | Hard gate — zero means zero |
| 11 | Working faster than committing | Auto-checkpoint after validation |
| 12 | Vertical budget violations discovered late | Mandatory Z-stack table |
| 13 | Context lost across sessions | Decision journal + project memory |
| 14 | Repeating printer/material constraints | User profile persists globally |
| 15 | Not knowing what changed between iterations | Visual diff between versions |
| 16 | Print failures from thin walls/overhangs | FDM manufacturability check |
