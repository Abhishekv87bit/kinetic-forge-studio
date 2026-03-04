# Rule 99 — Production Consultant Pipeline (Full Spec)

Loaded on demand when user says "Rule 99". NOT loaded into every conversation.

---

## Scope
Kinetic sculpture `.scad` files and production pipeline scripts ONLY.
Does NOT activate for: web app code, documentation edits, general coding, git operations.

## Principle: Consultant Mode
All pipeline tools communicate as consultants briefing a client:
1. Tool runs its analysis silently
2. Presents findings as **options with tradeoffs** (cost, time, risk, quality)
3. Includes a **clear recommendation** with reasoning
4. Waits for go/no-go before proceeding
5. User never interprets raw engineering data — that's the tool's job

**Bad:** "Yield is 276 MPa. Stress is 180 MPa. You decide."
**Good:** "Your arm handles the load with 35% safety margin. No changes needed."

## Trigger Modes

| Mode | How to Activate | What Happens |
|---|---|---|
| **Rule 99** | Say "Rule 99" | Full scan — every matching consultant fires against current design |
| **Rule 99 [topic]** | Say "Rule 99 cam" | Only topic-related consultants fire |
| **Rule 99 design** | Say "Rule 99 design" + describe idea | Consultants shape the design BEFORE coding — materials, mechanism, motor, structure, acoustics, reliability, fabrication. Outputs a design brief for approval before OpenSCAD begins |
| **Auto-Nudge** | After validation pipeline step 4 passes | Report how many consultants triggered, ask user |

**Topics for targeted Rule 99:** `cam`, `frame`, `drive`, `materials`, `tolerance`, `production`, `print`, `reliability`, `linkage`, `fasteners`, `cables`

### Rule 99 design — Pre-Design Consultant Assembly
When user provides an idea/brief (not an existing .scad file), assemble a virtual consultant team:
1. **Mechanism Advisor** — Recommend mechanism type for desired motion (cam, linkage, cable, etc.)
2. **Structural Engineer** — Frame approach, mounting, scale implications
3. **Materials Consultant** — Material pairs, corrosion, environment suitability, aesthetics
4. **Motor & Drive** — Torque estimate from expected mass, speed, drive method
5. **Acoustic Consultant** — Noise considerations for installation environment
6. **Reliability Planner** — Bearing life, belt life, maintenance intervals for expected duty cycle
7. **Fabrication Advisor** — How it gets made, shipped, and assembled on-site
8. **Balance / Aesthetics** — CG, element count (prime vs grid), visual proportion

Output: A **design brief** with specific numbers and recommendations. User approves/modifies before any OpenSCAD code is written. Every design decision has engineering backing from the start.

## Decision Matrix (Deterministic Triggers)

Consultants fire based on what EXISTS in the current design, not judgment:

### Geometry Triggers

| IF design contains... | THEN fire... |
|---|---|
| Bearing, shaft, or bore dimensions | Clearance Advisor (ISO 286), Tribology contact stress |
| Cam profile | Cam Smoother (SciPy spline), Jerk Analysis, Easing options |
| Linkage (four-bar, slider-crank, etc.) | Dead-Point Finder, Transmission Angle check, Pyslvs/pylinkage verify |
| Frame or structural members | PyNite/anastruct stress+deflection, sectionproperties cross-section |
| Belt, gear, or pulley system | Drive Validator (tension, tooth count), gearpy torque flow |
| Fasteners (bolts, screws) | BAT bolt analysis, grip length check, ezbolt group forces |
| Cable or string routing | pycatenary tension+sag |
| Spring elements | Springcalc verification |
| Multiple materials assigned | Galvanic corrosion check (pymatgen Pourbaix), Thermal expansion delta |
| Structural part oversized for load OR weight reduction desired | TopOpt/topy topology optimization, JAX for flexure design |

### Assembly Triggers

| IF assembly has... | THEN fire... |
|---|---|
| Any moving parts | Collision Detector (python-fcl) at keyframes, Motor Torque (Trimesh inertia) |
| >3 chained parts | Tolerance Stackup (dimstack, Monte Carlo) |
| Complete mechanism defined | CG Balance (Trimesh center_of_mass), Moment of Inertia |
| Animation keyframes | Interference check at 0deg/90deg/180deg/270deg |

### Phase Transition Triggers

| IF moving to... | THEN fire... |
|---|---|
| Prototyping (3D print) | ALL design consultants final pass, Print Orientation, Mesh Repair (pymeshfix), Tolerance Compensation |
| Production (metal/wood) | DFM Advisor, BOM Generator, Nesting (nest2D/DeepNest), Costing, Fatigue (py-fatigue/fatpack), Drawing Generator, Coating Spec |
| Material selection locked | Full material audit: galvanic, thermal expansion, fatigue life, coating |

### Topic Shortcut Mapping

| You Say | What Fires |
|---|---|
| Rule 99 cam | Cam Smoother, Jerk Analysis, Easing, Motor Torque |
| Rule 99 frame | PyNite/anastruct, Section Properties, CG Balance, Bolt Check |
| Rule 99 drive | Belt Validator, gearpy torque flow, Motor Torque |
| Rule 99 materials | Galvanic, Thermal Expansion, Fatigue Life, Coating Spec |
| Rule 99 tolerance | ISO 286, Stackup (dimstack), Monte Carlo, Clearance Advisor |
| Rule 99 production | DFM Advisor, Nesting, Costing, BOM, Drawings, Fatigue |
| Rule 99 print | Mesh Repair, Print Orientation, Tolerance Compensation |
| Rule 99 reliability | Bearing L10, Belt Life, Fatigue, MTBF |
| Rule 99 linkage | Dead-Point Finder, Transmission Angle, Pyslvs/pylinkage |
| Rule 99 fasteners | BAT bolt analysis, grip length, ezbolt group forces |
| Rule 99 cables | pycatenary tension+sag, string length verification |
| Rule 99 vertical | Vertical Budget Auditor — Z-stack enumeration, height proof |

### Vertical Budget Auditor (added Feb 2026, learned from Gemini collaboration)
**Trigger:** "Rule 99 vertical" OR any design with stacked components along a single axis
**What it does:**
1. Enumerate every component in the stack with its actual height (gear face width, carrier plate, stage gap, bearing width, bevel height, spool, flanges, clearances)
2. Sum the total
3. Compare to available envelope (ceiling drop, pedestal height, grid pitch in that axis)
4. Report surplus or deficit with actual numbers
5. If deficit: recommend which component to shrink and by how much

**Output format:**
```
VERTICAL BUDGET — Waffle Grid Node (Z-axis)
─────────────────────────────────────
Stage 1 ring + gear face:    6.0 mm
Carrier 1 plate:             2.0 mm
Stage gap:                   4.0 mm
Carrier 2 plate:             2.0 mm
Stage 2 ring + gear face:    6.0 mm
Bevel transfer zone:        12.0 mm
─────────────────────────────────────
TOTAL STACK:                32.0 mm
AVAILABLE:                  45.0 mm
SURPLUS:                    13.0 mm  ✓
```

**Rule:** This audit MUST pass before ANY mechanism geometry code is written. Architecture before library.

### FDM Ground Truth Consultant (added Feb 2026)
**Trigger:** "Rule 99 print" on first prototype, or when tolerances are assumed but untested
**What it does:**
1. Identify the 2-3 critical fit assumptions in the design (gear mesh clearance, press-fit bore, snap joint)
2. Generate minimal test-print STLs — just the critical joint, not the full assembly
3. Recommend: print these FIRST, measure, then update tolerances before committing to full build
4. For torque applications: flag print-in-place as demo-only, recommend printed-then-assembled with metal dowel pins

**Key recommendation:** Metal pin dowels (2mm/3mm) for planet axles in any gearbox under continuous motor load. Plastic axles are the #1 failure point in 3D-printed gearboxes.

## Global Tolerance System (3 Levels)

**Level 1 — Manufacturing Process Tolerances** (auto-set when target process declared):
- FDM 3D Print: +/-0.20mm general, +/-0.30mm holes, +/-0.10mm press-fit w/ compensation
- Waterjet: +/-0.10mm general, +/-0.05mm fine
- Laser Cut: +/-0.05mm
- CNC Mill: +/-0.025mm general, +/-0.01mm reamed
- CNC Lathe: +/-0.02mm general, +/-0.005mm ground

**Level 2 — Fit Tolerances** (ISO 286 lookup, auto-applied to shaft/bearing pairs):
- Sliding: H7/g6, Transition: H7/k6, Press: H7/p6
- Looked up per nominal diameter, returns actual deviations in microns

**Level 3 — Assembly Stackup** (Monte Carlo on complete chains):
- Each part in chain adds its tolerance from Level 1
- 10,000 virtual assemblies, report % that fit
- When switching prototype->production, tolerances auto-update and stackup re-runs

## Custom Scripts Status

| Script | Purpose | Status | Location |
|---|---|---|---|
| `iso286_lookup.py` | Shaft/hole fit tolerances per nominal diameter | BUILT | `production_pipeline/iso286_lookup.py` |
| `tolerance_stackup.py` | Worst-case + RSS + Monte Carlo stackup | BUILT | `production_pipeline/tolerance_stackup.py` |
| `galvanic_matrix.py` | Corrosion risk for material pairs | Cognitive | Claude analyzes from MIL-STD-889 knowledge |
| `kfactor_calc.py` | Sheet metal bend allowance | Cognitive | Claude calculates BA = pi(R+KT)theta/180 |
| `weld_sizer.py` | Fillet/butt weld sizing per load | Cognitive | Claude sizes per AWS D1.1 |
| `finish_spec.py` | Coating recommendation per material+environment | Cognitive | Claude recommends from decision tree |
| `bom_generator.py` | Extract parts from config -> spreadsheet | BUILT (project-specific) | `check point/5.5/bom_generator.py` |
| `dfm_advisor.py` | Part geometry -> manufacturing method | Cognitive | Claude advises per DFM heuristics |

**"Cognitive"** = Claude performs the analysis from engineering knowledge during Rule 99. No script needed — the analysis is straightforward enough for direct reasoning.

---

## Project Life Gates

Rule 99 consultants are organized into 3 gates. Each gate has entry/exit criteria and a specific consultant set. Consultants only fire for their gate (plus Auto-Nudge awareness).

### Gate 1: DESIGN (idea -> locked geometry)

**Entry:** "Rule 99 discover" / "Rule 99 design" / first .scad file created
**Exit:** Geometry compiles clean, validation passes, user says "design locked"

**Say:** "Rule 99 design", "Rule 99 discover", "Rule 99 vertical"

| Consultant | What It Does | Trigger |
|---|---|---|
| Socratic Physics Consultant | Translates user vision into physics spec | "Rule 99 discover" |
| Function-First Design Consultant | Function -> constraint -> load -> mechanism | Pre-design |
| Mechanism Advisor + Pattern Library | Recommend mechanism, provide kinematic diagram | Mechanism selection |
| Structural Engineer | Envelope check, vertical budget only (no FEM yet) | Frame/structure present |
| Motor & Drive | Torque estimate from mass/speed/friction | Motor/drive specified |
| Acoustic Consultant | Noise considerations | Installation environment discussed |
| Balance / Aesthetics | CG, element count, visual proportion | Design review |
| Vertical Budget Auditor | Z-stack enumeration, height proof | Stacked components |
| Architecture-First enforcement | Zero-dep first pass before library imports | Any new mechanism |
| Kinematic Chain Auditor | Trace input -> output, find broken chains | Moving parts present |
| Gravity & Support Auditor | Every part supported correctly | Vertical elements |
| Rotation Axis Verifier | Rotation axes through bearings, correct orientation | Rotating parts |
| The Margolin Eye | Legibility scoring (0-12, below 8 = rework) | After mechanism verified |

### Gate 2: PROTOTYPE (locked geometry -> physical test piece)

**Entry:** User says "design locked" / "ready to print" / "Rule 99 print"
**Exit:** Test prints validated, tolerances confirmed, assembly interference clear

**Say:** "Rule 99 print", "Rule 99 tolerance", "Rule 99 [topic]"

| Consultant | What It Does | Trigger |
|---|---|---|
| Gate 1 final pass | All Gate 1 consultants run once more | Gate entry |
| Clearance Advisor (ISO 286) | Uses `iso286_lookup.py` for shaft/bore fits | Bearing/shaft/bore dims |
| Tolerance Stackup | Uses `tolerance_stackup.py` (WC + RSS + MC) | >3 chained parts |
| Cam Smoother + Jerk Analysis | SciPy spline, jerk discontinuities | Cam profile present |
| Dead-Point Finder + Transmission Angle | Grashof, transmission angle 40-140deg | Linkage present |
| Drive Validator | Belt tension, tooth count, torque flow | Belt/gear/pulley system |
| Collision Detector | Keyframe interference at 0/90/180/270 deg | Moving parts |
| CG Balance + Moment of Inertia | Mass distribution, dynamic balance | Complete mechanism |
| FDM Ground Truth | Critical test prints (2-3 joints) before full build | First prototype |
| Print Orientation + Mesh Repair | Layer direction, support minimization, pymeshfix | Pre-slice |
| Tolerance Compensation | FDM shrinkage correction | FDM target |
| Fastener Check | BAT bolt analysis, grip length | Fasteners present |
| Spring Verification | Spring rate, fatigue life | Spring elements |

### Gate 3: PRODUCTION (validated prototype -> metal/wood fabrication)

**Entry:** User says "prototype validated" / "ready for production" / "Rule 99 production"
**Exit:** Complete fabrication package (STEP + drawings + BOM + FEM report)

**Say:** "Rule 99 production", "Rule 99 materials"

| Consultant | What It Does | Trigger |
|---|---|---|
| DFM Advisor | Manufacturing method per part (CNC/waterjet/turning/wood) | Cognitive |
| Galvanic Corrosion Check | Material pair compatibility | Multiple materials |
| Fatigue Life | Bearing L10, belt life, fatigue cycles | Cognitive |
| Coating/Finish Spec | Surface treatment per material + environment | Cognitive |
| Weld Sizing | Fillet/butt weld per load | Welded joints |
| Sheet Metal Bend | K-factor, bend allowance | Sheet metal parts |
| BOM Generator | Full BOM with material grades, quantities, cost | `bom_generator.py` |
| Nesting Advisor | Sheet layout for waterjet/laser flat parts | Cognitive |
| **FreeCAD Bridge** | Per-part solid build via MCP `execute_code` | Per-part STEP needed |
| **FreeCAD TechDraw** | Engineering drawings with dims + GD&T | Drawing package needed |
| **FreeCAD FEM** | CalculiX stress analysis on structural parts | Structural verification |
| Production Sign-Off | All above must pass -> go/no-go | Gate exit |

### Auto-Nudge (Gate-Aware)

After validation pipeline step 4 passes, Claude:
1. Identifies which gate the project is currently at
2. Reports only gate-appropriate consultants that triggered
3. Asks user whether to run them

Example: "Validation passed. Project is at Gate 2 (Prototype). 3 consultants triggered: Clearance Advisor, Tolerance Stackup, Collision Detector. Run them?"

---

## FreeCAD MCP Integration (Gate 3)

FreeCAD is the production bridge — Claude executes Python in FreeCAD via MCP `execute_code` to produce machinist-ready outputs.

### Proven Capabilities (working now)
- **Solid geometry**: `Part.makeBox`, `Part.makeCylinder`, `Part.makePolygon` + `extrude()` + boolean `fuse()`/`cut()`
- **Topology cleanup**: `removeSplitter()` for Fusion 360-compatible STEP
- **STEP/BREP export**: `Part.export([obj], "out.step")` — clean solid files
- **Pattern**: `build_frame_v2.py` — generates Python code string, sends via `proxy.execute_code()`
- **Visual check**: `get_view` MCP tool returns PNG screenshot

### Available but Not Yet Scripted
- **TechDraw drawings**: Create pages, add orthographic views, add dimensions, export DXF/SVG
- **FEM analysis**: Full CalculiX pipeline (mesh, constraints, solve, read von Mises/displacement)
- **Assembly interference**: `shape_a.distToShape(shape_b)` or `shape_a.common(shape_b).Volume > 0`
- **Mass properties**: `Shape.Volume`, `Shape.CenterOfMass`, `Shape.MatrixOfInertia`, `Shape.PrincipalProperties`
- **Cross-sections**: `shape.slice(normal_vector, offset)` at arbitrary planes

### FreeCAD Session Setup
RPC server must be started manually each session from FreeCAD Python console:
```python
import sys
sys.path.append(FreeCAD.getUserAppDataDir() + "Mod/FreeCADMCP")
from rpc_server.rpc_server import start_rpc_server
start_rpc_server()
```

### Gate 3 FreeCAD Workflow
1. Parse OpenSCAD config -> Python dict (reuse `validate_geometry.py` parser pattern)
2. Build each part as individual FreeCAD solid via `execute_code`
3. Validate: `shape.isValid()`, `shape.isClosed()`, volume > 0
4. Export per-part: `.step` (CNC), `.stl` (3D print), `.dxf` (waterjet flat profiles)
5. TechDraw: Third-angle projection + dimensions + GD&T per part
6. FEM: Structural parts only (frame arms, carrier nodes, junctions)
7. Assembly: Place all parts, check interference at 4 keyframes
8. Mass report: Per-part mass, total CG, principal axes
