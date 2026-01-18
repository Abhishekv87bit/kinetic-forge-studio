# CLAUDE.md - 3D Mechanical Design Workspace Configuration

## Project Context

This is a 3D mechanical design workspace for OpenSCAD kinetic art projects. The workspace focuses on creating precise, mathematically-defined mechanical assemblies including gears, linkages, cams, and interconnected motion systems.

Primary design tool: OpenSCAD (programmatic 3D CAD)
Output formats: .scad source files, .stl for printing, .svg for laser cutting

---

## Critical Context - NEVER FORGET

This is a **PHYSICAL 3D PRINTED KINETIC AUTOMATON**. Every moving part is:
- Mechanically driven (gears, linkages, cams, cranks)
- 3D printed or laser cut
- Assembled in the real world
- Powered by a single motor

**There is NO software animation in the final product.** OpenSCAD $t animation is ONLY for design visualization/preview. The real sculpture has no computer, no code, no motors with controllers - just mechanical motion.

## Mistake Log

| Date | Mistake | Correction | Never Again |
|------|---------|------------|-------------|
| 2025-01-16 | Suggested "software animation" for horizon band | All motion must be mechanical linkage | Physical automaton = mechanical only |
| 2025-01-16 | Lost context that this is real-world build | Re-read project context before suggesting | Always think: "How does this physically work?" |
| 2025-01-17 | V53 four-bar coupler rods not connected to waves | Animation showed motion, but rods were visual-only. Waves animated independently via sin(). | Verify physical connections BEFORE generating animation |
| 2025-01-17 | Coupler rods animated as 360° rotation | Push-pull linkages oscillate, they cannot rotate fully around a shaft | Understand linkage kinematics: pin joints rotate, slider joints translate |
| 2025-01-17 | Generated animation before validating mechanism | Created pretty animation of impossible physics | Run physical-linkage-check BEFORE any animation code |
| 2025-01-17 | SVG wrapper polyhedrons at wrong scale | Wind path, cypress, cliff 100x too big (SVG coordinates not mm) | Use procedural shapes or calculate proper bounding box transforms |

**Before suggesting ANY motion mechanism, ask yourself:**
1. What physical part moves this?
2. What is it connected to?
3. How is it assembled?
4. Can it be 3D printed?
5. **NEW: Are the coupler endpoints connected to their targets?**
6. **NEW: Is the motion type (rotation/translation) compatible with the joint type?**

## Design Philosophy - THINK OUTSIDE THE BOX

**Always explore unconventional mechanisms first.** Don't default to:
- Four-bar linkages for everything
- Hinged segments for articulation
- Sliders for linear motion

**Instead, consider techniques from kinetic art history:**
- Gear-mounted elements (rotation = complex paths)
- Cam followers for programmed motion
- Escapements for intermittent motion
- Counterweights for balance and rhythm
- Geneva drives for indexed positioning
- Parallel linkages for translation without rotation
- Scotch yoke for pure sinusoidal motion
- Cardan/universal joints for angle transmission
- Maltese cross for intermittent rotation
- Gravity-driven mechanisms (Marble machines, etc.)

**Historical kinetic art techniques to remember:**
- Automata (18th century Europe): Cam-driven sequential motion
- Karakuri (Japan): String-driven, gravity-powered, spring mechanisms
- Whirligigs (American folk): Wind-driven, balanced lever arms
- Kinetic sculpture (Calder, Tinguely): Balance, counterweight, chaos
- Clockwork: Escapements, gear trains, maintaining power

| Date | Mistake | Lesson |
|------|---------|--------|
| 2025-01-17 | Suggested complex four-bar for wave curl instead of simple gear-mounted foam | Rotation can simulate fluid motion elegantly |

---

## Key Files and Structure

```
3d_design_agent/
├── components/          # Reusable mechanical components
├── mechanisms/          # Complete mechanism assemblies
├── versions/            # Version history of designs
├── exports/             # Generated STL and SVG files
├── specs/               # Design specifications (.md files)
└── utils/               # Helper modules and libraries
```

### Important Files to Know
- `3d_design_agent/components/*.scad` - Base component library
- `3d_design_agent/mechanisms/*.scad` - Assembled mechanisms
- `3d_design_agent/specs/*.md` - Design specifications and constraints
- `3d_design_agent/versions/` - All versioned iterations

### Extended Documentation (The Polymath System v2.0)

**Core Engineering References:**
- `3d_design_agent/docs/POLYMATH_LENS.md` - **START HERE** - Engineering DNA from seven masters: Van Gogh (turbulence physics), Da Vinci (friction science), Tesla (mental simulation limits), Edison (systematic experimentation), Watt (efficiency measurement), Galileo (experimental verification), Archimedes (first principles). Contains pre-design checklists, physics formulas, mechanism selection guide, and failure patterns.

- `3d_design_agent/docs/KINETIC_SCULPTURE_COMPENDIUM.md` - **MASTER REFERENCE** - Comprehensive knowledge base covering 14 domains: History, Physics, Materials, Design Process, Motion Aesthetics, Sound, Site-Specific, Professional Practice, Tips & Tricks, Longevity Engineering, Assembly Science, Theatrical Kinetics, Scale Wisdom, Perceived Quality. Includes Quick Reference Cards and troubleshooting guide.

- `3d_design_agent/docs/PHYSICS_REFERENCE.md` - Quick calculation reference: torque, gear math, four-bar analysis, center of gravity, friction, scaling laws, 3D printing constraints.

- `3d_design_agent/docs/MECHANISM_DECISION_TREE.md` - Systematic selection flowcharts: motion type → mechanism, four-bar validation, gear mesh verification, printability check, balance analysis, physical connection validation.

- `3d_design_agent/docs/FAILURE_PATTERNS.md` - What went wrong and why: Tesla Trap (material limits), Da Vinci Dream (power-to-weight), Edison Pivot (context change), Galileo Bias (confirmation bias), Watt Wait (manufacturing limits), V53 Disconnect (animation without connection).

**Workflow References:**
- `3d_design_agent/docs/STATE_MACHINES.md` - Workflow state diagrams (11 state machines), hook registry (15 hooks), sub-agent architecture (7 agents), skill definitions (12 skills).
- `3d_design_agent/docs/XML_TAGS_REFERENCE.md` - Custom prompt tags for structured input/output. Includes Polymath tags, Quality tags, and Sub-Agent communication tags.

**Agent Configuration:**
- `3d_design_agent/skills.md` - 12 slash commands in 4 categories: Calculation, Verification, Export, Quality.
- `3d_design_agent/hooks.md` - 15 hooks in 5 priority levels: Critical, Preservation, Verification, UX, Enhancement.
- `3d_design_agent/sub_agents.md` - 7 specialized sub-agents: MechanismAnalyst, OpenSCADArchitect, MotionDesigner, MaterialsExpert, VersionController, VisualizationGuide, DecisionFacilitator.

### User Extensions
- `User Skills/` - Custom slash commands and workflow overrides
- `User Skills/templates/` - Blank templates for creating new skills and hooks
- `migrations/` - Version upgrade scripts and workspace schema

---

## Hooks Configuration v2.0

**15 Hooks in 5 Priority Levels** - See `3d_design_agent/hooks.md` for full documentation.

### PRIORITY LEVEL 1: CRITICAL (Always Execute, Blocks Output)

#### 1. pre-code-generation
**Trigger:** Before any `.scad` file modification
**Action:** Identify scope, declare changes and non-changes, impact analysis, breakage verification, request confirmation.

#### 2. physical-linkage-check
**Trigger:** BEFORE generating ANY animation code for linkages
**Mandatory Verification:**
- Coupler endpoints connected to driver/driven elements
- Motion type matches joint type (pin→rotation, slider→translation)
- Grashof condition verified for four-bar
- No dead points in operating range
**If ANY check fails:** DO NOT generate animation. Report issue first.

#### 3. polymath-pre-design-check
**Trigger:** User requests new mechanism or significant change
**Seven Masters Checklist:**
- VAN GOGH: Motion pattern mathematically defined?
- DA VINCI: Friction coefficients estimated?
- TESLA: Full cycle mentally simulated?
- EDISON: Test procedure defined?
- WATT: Power path traced, efficiency acceptable?
- GALILEO: How to verify in OpenSCAD?
- ARCHIMEDES: Physics laws satisfied?
**If ANY critical check fails:** STOP. Report to user.

### PRIORITY LEVEL 2: PRESERVATION (Protect User Work)

#### 4. lock-in-detector
**Trigger:** User phrases: "lock", "finalize", "freeze", "approved", "ship it"
**Action:** Add LOCKED comment, create backup, warn on future modifications.

#### 5. component-survival-check
**Trigger:** After every version delivery
**Action:** Verify all components from previous version exist in new version.

#### 6. version-backup
**Trigger:** Before significant changes (>3 modules or >50 lines)
**Action:** Auto-create backup with timestamp.

### PRIORITY LEVEL 3: VERIFICATION (Quality Gates)

#### 7. physical-reality-check
**Trigger:** User asks "will this work?", "is this printable?"
**Checks:** Wall thickness ≥1.2mm, clearances ≥0.3mm, gear mesh, overhangs, structural.

#### 8. animation-validation
**Trigger:** Animation code with sin($t) or cos($t)
**Action:** Verify physical driver exists, formula matches kinematics, no orphan animations.

#### 9. longevity-check
**Trigger:** User asks about "final", "production", "will it last"
**Checks:** Wear surfaces, lubrication, fatigue life, maintenance access.

### PRIORITY LEVEL 4: USER EXPERIENCE

#### 10. user-frustration-detector
**Trigger:** "ugh", "going in circles", "where is my", "this is broken"
**Action:** Pause, summarize attempts, propose different approach.

#### 11. complexity-warning
**Trigger:** Changes affect >3 components
**Action:** List all affected components, suggest incremental approach.

#### 12. post-version-delivery
**Trigger:** After creating new version file
**Action:** Survival check, diff summary, ASCII layout, TEST IT NOW instructions.

### PRIORITY LEVEL 5: ENHANCEMENT (Optional Quality)

#### 13. failure-pattern-detector
**Trigger:** Phrases matching known failure modes
**Patterns:**
- "should work in theory" → Tesla Trap
- "just scale it up" → Square-Cube Law
- "it worked once" → Galileo Bias
- sin($t) without connection → V53 Disconnect
**Action:** Reference FAILURE_PATTERNS.md, require acknowledgment.

#### 14. quality-assessment
**Trigger:** User asks about "quality", "professional"
**Action:** Grade mechanism (Motion A-D, Visual A-D, Craftsmanship A-D, Sound A-D).

#### 15. compendium-reference
**Trigger:** Topic keywords (gears, linkages, materials, longevity)
**Action:** Reference relevant KINETIC_SCULPTURE_COMPENDIUM.md sections.

**Full Hook Documentation:** See `3d_design_agent/hooks.md` for complete specifications, output formats, and implementation details.

---

## Custom Commands (12 Skills)

**Full Skill Documentation:** See `3d_design_agent/skills.md` for complete specifications.

### CALCULATION SKILLS

#### /gear-calc
Calculate gear parameters for meshing gears.
**Usage:** `/gear-calc [teeth1] [teeth2] [module]`
**Outputs:** Pitch diameters, center distance, contact ratio, 3D print recommendations.

#### /linkage-check
Analyze linkage geometry and motion range.
**Usage:** `/linkage-check [mechanism_file]`
**Outputs:** Grashof classification, transmission angles, dead points, ROM analysis.

#### /torque-chain (NEW)
Trace power flow from motor to output.
**Usage:** `/torque-chain [mechanism_file]`
**Outputs:** Stage-by-stage torque, efficiency, power budget, motor adequacy.

#### /balance-check (NEW)
Analyze center of gravity and balance.
**Usage:** `/balance-check [mechanism_file]`
**Outputs:** CG location, stability analysis, counterweight recommendations.

### VERIFICATION SKILLS

#### /component-survival
Verify all components still function after changes.
**Usage:** `/component-survival [scad_file]`
**Checks:** Module compilation, parameter values, dependencies, orphaned components.

#### /version-diff
Compare two versions and summarize changes.
**Usage:** `/version-diff [v_old] [v_new]`
**Outputs:** Parameter changes, added/removed modules, breaking changes.

#### /z-stack
Analyze vertical layer stacking for assembly.
**Usage:** `/z-stack [mechanism_file]`
**Outputs:** Layer order, clearance verification, fastener lengths, assembly sequence.

#### /animation-test (NEW)
Validate animation at critical positions.
**Usage:** `/animation-test [scad_file]`
**Checks:** Physical connections at t=0, 0.25, 0.5, 0.75, motion continuity.

### EXPORT SKILLS

#### /svg-extract
Extract 2D profiles for laser cutting.
**Usage:** `/svg-extract [scad_file] [layer_height]`
**Outputs:** Layer SVGs, kerf compensation, material annotations.

#### /bom-generate (NEW)
Generate bill of materials.
**Usage:** `/bom-generate [mechanism_file]`
**Outputs:** Parts list, quantities, materials, hardware, estimated costs.

### QUALITY SKILLS

#### /quality-audit (NEW)
Comprehensive quality assessment.
**Usage:** `/quality-audit [mechanism_file]`
**Outputs:** Motion grade, visual grade, craftsmanship grade, recommendations.

#### /longevity-report (NEW)
Predict lifespan and maintenance needs.
**Usage:** `/longevity-report [mechanism_file]`
**Outputs:** Wear analysis, lubrication schedule, replaceable parts, maintenance plan.

---

## Working Conventions

### Code Modification Protocol
1. **Always read existing code before modifying** - Never assume file contents; always read the current state
2. **Run component survival after every change** - Verify nothing broke
3. **Use mathematical calculations, never visual placement** - All positions derived from formulas
4. **Preserve existing comments and documentation** - Especially `// LOCKED` markers

### Version Control Formula
```
V[N] = V[N-1] + (changes) - (nothing)
```
- Every version must be additive from the previous version
- Never delete functionality without explicit user approval
- Changes are documented, nothing is silently removed
- Version files are immutable once created

### Mathematical Precision
- All dimensions in millimeters
- Angles in degrees
- Use parametric relationships, not magic numbers
- Document formulas in comments: `// center_distance = (d1 + d2) / 2`

### Module Naming Convention
```
component_name_variant()     // e.g., gear_spur_20t()
mechanism_name_version()     // e.g., escapement_anchor_v2()
util_function_name()         // e.g., util_polar_array()
```

---

## File Patterns

### Recognized File Types
| Pattern | Description | Treatment |
|---------|-------------|-----------|
| `*.scad` | OpenSCAD source files | Primary design files - read before modify |
| `*.svg` | Vector graphics | Laser cutting profiles, import sources |
| `*.md` | Specifications | Design requirements and documentation |
| `*.stl` | Mesh exports | Generated output - do not edit directly |
| `*_v[0-9]*.scad` | Versioned files | Immutable history - create new version instead |

### File Naming Patterns
```
[component]_[type]_[variant].scad      # gear_spur_24t.scad
[mechanism]_[name]_v[N].scad           # escapement_deadbeat_v3.scad
[project]_assembly_v[N].scad           # clock_main_assembly_v5.scad
[component]_[type].svg                 # gear_profile.svg
[topic]_spec.md                        # gear_train_spec.md
```

---

## Safety Checks Before Rendering

Before any `F5` (preview) or `F6` (render) equivalent operation:
1. Verify `$fn` is set appropriately (recommend 32-64 for preview, 128+ for export)
2. Check for `intersection()` or `difference()` with non-manifold geometry
3. Confirm all `use` and `include` paths are valid
4. Validate that animation variables (`$t`) have default values

---

## Quick Reference: OpenSCAD Gotchas

- `difference()` - First child is positive, rest are negative
- `$fn` affects all child operations - set locally when needed
- `use <file>` imports modules only; `include <file>` imports everything
- Avoid `hull()` with complex children - breaks CGAL frequently
- Always specify `center=true` or `center=false` explicitly

---

*This configuration is automatically recognized by Claude Code for mechanical design assistance.*
