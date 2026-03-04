# Kinetic Sculpture Design Rules (On-Demand)

Read this file ONLY when working on kinetic sculpture design, OpenSCAD, or CadQuery tasks.

## Dual-Tool Strategy
- **Fusion 360** = PRIMARY LEARNING tool — 3D design, parametric modeling, motion analysis
- **OpenSCAD** = AI EXECUTION tool — Claude generates code, user validates, then imports to Fusion 360

## Physics (Invisible)
All verification happens silently. User only hears about physics when something's wrong:
- Every animation traces to physical mechanism (no orphan sin($t))
- Four-bar: Grashof verified, transmission angle 40°-140°
- Coupler lengths constant (checked at 0°, 90°, 180°, 270°)
- Power budget: required < available/2
- Tolerance stack calculated for long chains

## When I Push Back
- Mechanism violates physics → explain why, offer alternatives
- Animation has no driver → ask what should drive it
- Coupler would need to stretch → show why and redesign
- Dead point in range → add flywheel or parallel crank

## Component Isolation
When a project has multiple mechanisms, work on each in isolation:
- Finish one component's math before starting another
- Separate OpenSCAD modules with their own parameters
- No shared variable names across mechanisms
- Integration only after individual components verified
- Explicitly call out transitions: "Wave mechanism done. Moving to cypress drive..."

## OpenSCAD Code Template
Every .scad file follows this structure:
1. **Header** — name, description, standards (ISO 128, DFAM), math verification summary
2. **Quality & Animation** — `$fn`, `MANUAL_POSITION = -1` for $t animation, 0.0-1.0 for static debug
3. **Tolerances** — `TOL_GENERAL=0.2`, `TOL_SLIDING=0.3`, `TOL_PRESS=0.1`, all named constants
4. **Dimensions** — All parameters as named constants. Derived values COMPUTED from base params
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

## Parametric Discipline (ZERO HARDCODED NUMBERS)
Every dimension in a .scad file must be either:
1. A **named constant** in the file header (e.g., `ARM_W = 20;`)
2. **Derived** from other named constants (e.g., `PB_HOUSING_OD = BEARING_OD + 2 * MOUNT_WALL;`)
3. A **config import** via `include <config_vN.scad>`

**Never**:
- Literal numbers in `translate()`, `rotate()`, `cylinder()` etc. (except 0, 1, -1, 2 for centering)
- Duplicated values across files (single source of truth in config)
- Magic tolerances (name them: `TOL_PRESS = 0.05`, `BORE_MARGIN = 1.0`)

**Constraint-based placement**:
- Part positions derived from what they connect to, not absolute coordinates
- If the source parameter changes, ALL dependent positions must auto-update

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
