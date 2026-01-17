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

**Before suggesting ANY motion mechanism, ask yourself:**
1. What physical part moves this?
2. What is it connected to?
3. How is it assembled?
4. Can it be 3D printed?

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

### Extended Documentation
- `3d_design_agent/docs/POLYMATH_LENS.md` - Design philosophy framework (Seven Masters: Van Gogh, Da Vinci, Tesla, Edison, Watt, Galileo, Archimedes)
- `3d_design_agent/docs/STATE_MACHINES.md` - Workflow state diagrams (Agent, Design, Mechanism, Hooks)
- `3d_design_agent/docs/XML_TAGS_REFERENCE.md` - Custom prompt tags for structured input/output

### User Extensions
- `User Skills/` - Custom slash commands and workflow overrides
- `User Skills/templates/` - Blank templates for creating new skills and hooks
- `migrations/` - Version upgrade scripts and workspace schema

---

## Hooks Configuration

### 1. pre-code-generation
**Trigger:** Before any `.scad` file modification
**Action:**
- Read the existing file completely before making changes
- Identify all module dependencies
- Document current parameter values
- Check for `// LOCKED` comments indicating frozen sections

### 2. user-frustration-detector
**Trigger:** Regex patterns for frustration detection
```regex
/\b(ugh|argh|damn|dammit|frustrated|annoying|broken|wrong again|still (not |doesn't |won't )?work|this (is|keeps) (breaking|failing)|what the|come on|seriously\??|for the \d+(st|nd|rd|th) time)\b/i
```
**Action:**
- Pause and acknowledge the difficulty
- Summarize what has been tried
- Propose a different approach or ask clarifying questions
- Offer to step back and review the problem holistically

### 3. post-version-delivery
**Trigger:** After creating any new version file (e.g., `mechanism_v3.scad`)
**Action:**
- Run component survival check on all referenced components
- Generate diff summary from previous version
- Update version log in specs folder
- Confirm all modules render without errors

### 4. lock-in-detector
**Trigger:** User phrases indicating finalization
```regex
/\b(lock (this|it)|final(ize)?|freeze|don't (touch|change|modify)|approved|ship it|done with this|keep (this|it) (exactly|as is))\b/i
```
**Action:**
- Add `// LOCKED - [date] - [reason]` comment to relevant sections
- Create a backup copy in versions folder
- Confirm which specific elements are being locked
- Warn before any future modifications to locked sections

### 5. complexity-warning
**Trigger:** When proposed changes affect more than 3 mechanisms or components
**Action:**
- List all affected components before making changes
- Calculate cascading parameter impacts
- Suggest incremental change strategy
- Offer to create a test branch version first

### 6. physical-reality-check
**Trigger:** User asks "will this work?", "is this printable?", "can this move?", or similar
```regex
/\b(will (this|it) (work|print|move|function|fit)|is (this|it) (printable|possible|feasible|realistic)|can (this|it) (move|rotate|work|be (printed|built|made)))\b/i
```
**Action:**
- Check minimum wall thicknesses (recommend ≥1.2mm for FDM)
- Verify clearances between moving parts (recommend ≥0.3mm)
- Confirm gear mesh geometry and tooth engagement
- Validate axis alignments and bearing surfaces
- Check for overhangs requiring supports
- Assess structural weak points

---

## Custom Commands

### /gear-calc
Calculate gear parameters for meshing gears.
**Usage:** `/gear-calc [teeth1] [teeth2] [module]`
**Outputs:**
- Pitch diameters
- Center distance
- Recommended tooth profile
- Contact ratio validation

### /linkage-check
Analyze linkage geometry and motion range.
**Usage:** `/linkage-check [mechanism_file]`
**Outputs:**
- Degrees of freedom
- Motion limits
- Dead points
- Transmission angle analysis

### /svg-extract
Extract 2D profiles from 3D design for laser cutting.
**Usage:** `/svg-extract [scad_file] [layer_height]`
**Outputs:**
- Separated layer SVGs
- Kerf compensation recommendations
- Material thickness annotations

### /component-survival
Verify all components still function after changes.
**Usage:** `/component-survival [scad_file]`
**Checks:**
- All modules compile without errors
- Required parameters have values
- Dependencies exist and are accessible
- No orphaned or unreferenced components

### /version-diff
Compare two versions and summarize changes.
**Usage:** `/version-diff [v_old] [v_new]`
**Outputs:**
- Parameter changes with before/after values
- Added/removed modules
- Geometry modifications
- Breaking changes warnings

### /z-stack
Analyze vertical layer stacking for assembly.
**Usage:** `/z-stack [mechanism_file]`
**Outputs:**
- Layer order visualization
- Clearance verification between layers
- Fastener length calculations
- Assembly sequence recommendation

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
