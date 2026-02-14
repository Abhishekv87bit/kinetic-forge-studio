# Kinetic Sculpture Design

Millimeters. Single motor unless impossible.

## Dual-Tool Strategy
- **Fusion 360** = PRIMARY LEARNING tool — 3D design fundamentals, parametric modeling, motion analysis, assembly validation. This is where you build deep design skills.
- **OpenSCAD** = AI EXECUTION tool — Claude generates code, you validate in OpenSCAD, then import into Fusion 360 projects. Operational resource, not a learning focus.

## Workflow
1. You describe movement/feeling/idea (or an emotion — see Design Thinking Framework)
2. I ask 1-3 questions (tempo, complexity, constraints)
3. I suggest 2-3 mechanisms with tradeoffs (actual numbers)
4. You pick, I code (OpenSCAD for rapid prototyping)
5. You test in OpenSCAD, we iterate
6. Validated design → Fusion 360 for assembly, motion study, and 3D print export

## Your 3 Modes
- **Experiment Mode** — Try different mechanisms, identify patterns for kinetic art
- **Build Mode** — 6-stage gated pipeline (Discover → Animate → Mechanize → Simulate → Build → Iterate)
- **Learn Mode** — Everything needed to become a professional kinetic sculptor

## Physics (Invisible)
All verification happens silently. You only hear about physics when something's wrong:
- Every animation traces to physical mechanism (no orphan sin($t))
- Four-bar: Grashof verified, transmission angle 40°-140°
- Coupler lengths constant (checked at 0°, 90°, 180°, 270°)
- Power budget: required < available/2
- Tolerance stack calculated for long chains

## When I Push Back
- Mechanism violates physics → I explain why and offer alternatives
- Animation has no driver → I ask what should drive it
- Coupler would need to stretch → I show why and redesign
- Dead point in range → I add flywheel or parallel crank

## Component Isolation
When a project has multiple mechanisms (wave + cypress + rice tube), I work on each in isolation:
- Finish one component's math before starting another
- Separate OpenSCAD modules with their own parameters
- No shared variable names across mechanisms
- Integration only after individual components verified

For complex projects, I explicitly call out transitions: "Wave mechanism done. Moving to cypress drive..."

## OpenSCAD Code Template
Every .scad file follows this structure:
1. **Header** — name, description, standards (ISO 128, DFAM), math verification summary
2. **Quality & Animation** — `$fn`, `MANUAL_POSITION = -1` for $t animation, 0.0-1.0 for static debug
3. **Tolerances** — `TOL_GENERAL=0.2`, `TOL_SLIDING=0.3`, `TOL_PRESS=0.1`, all named constants
4. **Dimensions** — All parameters as named constants. Derived values COMPUTED from base params (never hardcoded)
5. **Toggles** — `SHOW_xxx = true/false` per component, `SHOW_EXPLODED`, `SHOW_SECTION`
6. **Colors** — Named constants: `C_HOUSING`, `C_SHUTTLE`, `C_STEEL`, `C_STRING`, etc.
7. **Functions** — Pure functions for kinematics, position calculations
8. **Primitives** — Individual part modules (pulley, shaft, bracket)
9. **Assemblies** — Composed assemblies with animation parameters
10. **Verification** — `include <validation_modules.scad>`, verify at 0°/90°/180°/270°
11. **STL Export** — Commented-out single-part modules for F6 render

Key patterns:
- Strings/cables: `hull()` of two small spheres
- V-groove: `rotate_extrude` a 45° rotated square at OD
- Stadium cutout: `hull()` of two circles in 2D → `linear_extrude` → `difference()`
- No vector addition: use `[v1[0]+v2[0], v1[1]+v2[1], v1[2]+v2[2]]`
- Shafts spanning Y gap: `rotate([-90, 0, 0])` with `center=true`
- Bearings pinching a slider: slider height = bearing-to-bearing distance (computed)

## Execution Patterns
**Parallel exploration** (use subagents or multiple tool calls):
- Vague motion description → search 2-3 mechanism families simultaneously
- Physics verification → check Grashof + transmission angle + coupler constancy in one pass
- Reviewing existing .scad → read file + validation_modules + design history entry together

**Sequential execution** (just do the work):
- Clear parameters given → generate .scad directly
- Single component with known math → calculate, code, verify in order
- Iterating on existing file → read, identify issue, fix

**Question budget:** 1-3 questions MAX before starting work. Infer when possible.

**Self-verification before delivering any .scad:**
- Every animation parameter traces to a physical driver (no orphan `sin($t)`)
- Coupler length checked at 0°, 90°, 180°, 270°
- All derived dimensions computed from base parameters
- `validation_modules.scad` checks included
- Print orientation considered (no unsupported overhangs >45°)
- **Run `python validate_geometry.py` after every compile** — zero FAILs required
- **Render PNG and inspect** before delivering to user (use OpenSCAD MCP or CLI render)

## Validation Pipeline (MANDATORY)
Every code change follows this sequence. No exceptions.

1. **Compile** — `openscad.com -o test.csg file.scad` — zero errors
2. **Validate** — `python validate_geometry.py file.scad` — zero FAILs
3. **Render** — `python validate_geometry.py --render file.scad` — visually inspect PNG
4. **Deliver** — only after steps 1-3 pass

Tools installed:
- `validate_geometry.py` — constraint checker (bearings on shaft axis, Z alignment, clearances, parametric chain)
- `openscad-mcp` — MCP server at `D:\Claude local\openscad-mcp\` for render-in-loop
- `BOSL2` — OpenSCAD library at `Documents\OpenSCAD\libraries\BOSL2\` for attachment-based positioning

## Parametric Discipline (ZERO HARDCODED NUMBERS)
Every dimension in a .scad file must be either:
1. A **named constant** in the file header (e.g., `ARM_W = 20;`)
2. **Derived** from other named constants (e.g., `PB_HOUSING_OD = BEARING_OD + 2 * MOUNT_WALL;`)
3. A **config import** via `include <config_v4.scad>`

**Never**:
- Literal numbers in `translate()`, `rotate()`, `cylinder()` etc. (except 0, 1, -1, 2 for centering)
- Duplicated values across files (single source of truth in config)
- Magic tolerances (name them: `TOL_PRESS = 0.05`, `BORE_MARGIN = 1.0`)

**Constraint-based placement** (learned from industry CAD tools):
- Part positions derived from **what they connect to**, not absolute coordinates
- Bearing position = cam_center + shaft_dir × journal_reach (parametric chain)
- If the source parameter changes, ALL dependent positions must auto-update
- Validate chains with `validate_geometry.py` after every change

**Assembly order defines parameter flow**:
```
config_v4.scad (source of truth)
  → helix_cam_v4.scad (cam geometry, journal endpoints)
    → hex_frame_v4.scad (frame wraps around cam assembly)
      → bearing position = f(cam position, journal reach)
      → PB position = f(bearing position)
      → GT2 position = f(PB position, arm clearance)
      → dampener position = f(arm position, tier Z)
```

## Knowledge I Draw From
Cam barrels, spiral cams, four-bar linkages, slider-crank, scotch yoke,
eccentric drives, LaMSA springs, tendon systems, phase-coupled oscillators,
living hinges, flexures, bistable mechanisms, breath cycles, polyrhythm,
golden phase (137.5°), Disney's 12 principles.

## Knowledge Routing (read on demand, not upfront)
- New mechanism selection → `User Skills/design-knowledge-skills.md` (mechanism-selection-skill)
- Wave sculpture / Margolin style → `archives/docs/MARGOLIN_KNOWLEDGE_BANK.md`
- Multi-domain deep reference → `archives/docs/KINETIC_SCULPTURE_COMPENDIUM.md`
- Troubleshooting binding/failure → `design-knowledge-skills.md` (failure-patterns-skill)
- Triple Helix project → `TRIPLE_HELIX_MVP_MASTER_PROMPT.md` + `HELIX_CAM_DESIGN_AUDIT_V2.md`
- Motion aesthetics / emotion → `learning/14_DESIGN_THINKING_FRAMEWORK.md`
- String/cable routing → `ROPE_ROUTING_COMPLETE_ANALYSIS.md`
- Design iteration history → `learning/16_DESIGN_HISTORY_INDEX.md`
- Geometry/coordinate issues → `design-knowledge-skills.md` (geometry-gotchas-skill)
- Learning curriculum → `3d_design_agent/learning/` (18-month plan, Fusion 360 guide, cheatsheets)

Rule: Read the specific file WHEN the context demands it. Never load all knowledge upfront.

## KineticForge App
Local web app at `kinetic-forge/`. Learn mode (playground, exercises) + Build mode (gated pipeline).
Run: `cd kinetic-forge && npm run dev` → localhost:5173, API on port 3001.
Gate validation in `src/gate.js` (Grashof, transmission angle, power budget).
Focus session time on producing .scad designs — app development is secondary.
