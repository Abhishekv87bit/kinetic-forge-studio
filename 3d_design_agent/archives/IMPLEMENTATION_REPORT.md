# 3D Mechanical Design Agent
## Comprehensive Implementation Report

**Document Version:** 1.0
**Date:** 2026-01-16
**Status:** Implementation Complete

---

## 1. Executive Summary

### What Was Created

A complete agentic framework for a specialized **3D Mechanical Design Agent** focused on OpenSCAD, kinetic art, and mechanical assemblies. This system provides Claude with domain expertise, safety guardrails, and systematic workflows for creating parametric mechanical designs.

### Purpose

The framework addresses critical challenges in AI-assisted mechanical design:

1. **Preventing Design Regressions** - Components silently disappearing during iterations
2. **Ensuring Physical Validity** - Designs that cannot work in reality (gear mesh failures, linkage lockups)
3. **Maintaining Version Stability** - The principle that V[N] = V[N-1] + (targeted changes) - (nothing else)
4. **Preserving User Intent** - Respecting locked decisions and existing work as "sacred"

### Key Capabilities Delivered

- **6 Specialized Skills** (slash commands) for precise mechanical calculations
- **6 Automated Hooks** for safety and quality enforcement
- **5 Domain Sub-Agents** for specialized expertise
- **Comprehensive OpenSCAD Templates** with reusable patterns
- **Master Specification Template** for project state tracking
- **Issue Catalog** with mitigations and recovery protocols

---

## 2. Asset Inventory

### Complete File Listing

| Filename | Line Count | Purpose | Key Contents |
|----------|------------|---------|--------------|
| `unified_system_prompt.md` | 659 lines | Core agent identity and rules | 7 Anti-patterns, 7 Mandatory practices, 12 Golden rules |
| `skills.md` | 1,093 lines | Slash command definitions | 6 skills with formulas, parameters, output formats |
| `hooks.md` | ~900 lines | Automated trigger behaviors | 6 hooks with detection patterns and action sequences |
| `sub_agents.md` | ~900 lines | Specialized domain experts | 5 sub-agents with system prompts and examples |
| `openscad_templates.scad` | 1,000 lines | Reusable OpenSCAD code | 10 sections: gears, linkages, animation, debugging |
| `master_specification_template.md` | 1,050 lines | Project state tracking | 12 sections: dimensions, components, decisions, history |
| `issues_and_mitigations.md` | 683 lines | Known problems and solutions | 5 categories, recovery protocols, checklists |

**Total Implementation:** ~6,285 lines of documentation and templates

---

## 3. Architecture Overview

```
+========================================================================+
|                    3D MECHANICAL DESIGN AGENT                           |
|                      (Main Orchestrator)                                |
+========================================================================+
         |                    |                    |
         v                    v                    v
+------------------+  +------------------+  +------------------+
|  UNIFIED SYSTEM  |  |     SKILLS       |  |      HOOKS       |
|     PROMPT       |  |  (Slash Cmds)    |  |   (Triggers)     |
+------------------+  +------------------+  +------------------+
| - Agent Identity |  | /gear-calc       |  | pre-code-gen     |
| - Anti-patterns  |  | /linkage-check   |  | user-frustration |
| - Mandatory      |  | /svg-extract     |  | post-version     |
|   Practices      |  | /component-      |  | lock-in-detector |
| - Golden Rules   |  |   survival       |  | complexity-warn  |
| - Workflow       |  | /version-diff    |  | physical-reality |
+--------+---------+  | /z-stack         |  +--------+---------+
         |            +--------+---------+           |
         |                     |                     |
         +----------+----------+----------+----------+
                    |
                    v
+========================================================================+
|                         SUB-AGENTS                                      |
+========================================================================+
|                                                                         |
|  +---------------+  +---------------+  +---------------+                |
|  | Mechanism     |  |   OpenSCAD    |  |   Version     |                |
|  | Analyst       |  |   Architect   |  |  Controller   |                |
|  +-------+-------+  +-------+-------+  +-------+-------+                |
|          |                  |                  |                        |
|   Physics &          Code Structure      Change Tracking                |
|   Feasibility        & Templates         & Rollback                     |
|                                                                         |
|  +---------------+  +---------------+                                   |
|  | Visualization |  |   Decision    |                                   |
|  |     Guide     |  |  Facilitator  |                                   |
|  +-------+-------+  +-------+-------+                                   |
|          |                  |                                           |
|   ASCII Diagrams      User Choice                                       |
|   & Layouts           Management                                        |
|                                                                         |
+========================================================================+
         |
         v
+========================================================================+
|                       SUPPORT FILES                                     |
+========================================================================+
|                                                                         |
|  +--------------------+  +--------------------+  +-------------------+  |
|  | openscad_templates |  | master_spec_       |  | issues_and_       |  |
|  | .scad              |  | template.md        |  | mitigations.md    |  |
|  +--------------------+  +--------------------+  +-------------------+  |
|  | - Gear modules     |  | - Dimensions       |  | - Known issues    |  |
|  | - Linkage calcs    |  | - Components       |  | - Recovery        |  |
|  | - Animation        |  | - Lock zones       |  | - Checklists      |  |
|  | - Z-layer mgmt     |  | - Version history  |  | - Formulas        |  |
|  | - Debug helpers    |  | - Test procedures  |  | - Early warnings  |  |
|  +--------------------+  +--------------------+  +-------------------+  |
|                                                                         |
+========================================================================+
```

---

## 4. Skills Implemented (6)

### Skill 1: `/gear-calc` - Gear Train Calculator

| Attribute | Details |
|-----------|---------|
| **Purpose** | Calculate precise gear mesh geometry with ready-to-use OpenSCAD code |
| **Key Formula** | `Center Distance = (T1 + T2) x Module / 2` |
| **Parameters** | teeth1, teeth2, module, pressure_angle, gear1_pos, axis |
| **Output** | Pitch radii, center distance, gear ratio, OpenSCAD placement code |

**Usage Example:**
```
/gear-calc teeth1=10 teeth2=60 module=1.5 gear1_pos=[0,0,5] axis=x
```

---

### Skill 2: `/linkage-check` - Four-Bar Linkage Validator

| Attribute | Details |
|-----------|---------|
| **Purpose** | Validate linkage geometry using Grashof condition |
| **Key Formula** | `s + l < p + q` (shortest + longest < sum of other two) |
| **Parameters** | ground, crank, coupler, rocker, pivot positions |
| **Output** | Grashof result, linkage type, motion range, collision zones |

**Usage Example:**
```
/linkage-check ground=50 crank=15 coupler=45 rocker=40
```

---

### Skill 3: `/svg-extract` - SVG Coordinate Extractor

| Attribute | Details |
|-----------|---------|
| **Purpose** | Extract REAL coordinates from SVG files for OpenSCAD polygons |
| **Key Formula** | Scale factor = target_dimension / original_dimension |
| **Parameters** | file, path_id, scale, target_width, target_height, center |
| **Output** | Point arrays, bounding boxes, OpenSCAD polygon modules |

**Usage Example:**
```
/svg-extract file="wave_pattern.svg" target_width=100 center=true
```

---

### Skill 4: `/component-survival` - Component Checklist Runner

| Attribute | Details |
|-----------|---------|
| **Purpose** | Verify all required components exist after modifications |
| **Key Formula** | Component_count(before) == Component_count(after) |
| **Parameters** | file, checklist preset, custom_items, verbose |
| **Output** | Component status table, missing item alerts, recovery recommendations |

**Usage Example:**
```
/component-survival file="kinetic_wave.scad" verbose=true
```

---

### Skill 5: `/version-diff` - Safe Version Comparison

| Attribute | Details |
|-----------|---------|
| **Purpose** | Ensure only intended changes occurred between versions |
| **Key Formula** | `V[N] = V[N-1] + (targeted changes) - (nothing else)` |
| **Parameters** | file_old, file_new, intent, critical_components |
| **Output** | Change statistics, component comparison, unexpected change alerts |

**Usage Example:**
```
/version-diff file_old="v1.scad" file_new="v2.scad" intent="Update gear module"
```

---

### Skill 6: `/z-stack` - Z-Layer Collision Analyzer

| Attribute | Details |
|-----------|---------|
| **Purpose** | Analyze Z-axis positioning and detect collisions |
| **Key Formula** | Collision when (Z_range_A overlaps Z_range_B) AND (XY_overlap) |
| **Parameters** | file, min_clearance, motion_clearance, show_diagram |
| **Output** | Component inventory, collision matrix, Z-stack ASCII diagram, fix recommendations |

**Usage Example:**
```
/z-stack file="kinetic_wave.scad" min_clearance=0.5 motion_clearance=2.0
```

---

## 5. Hooks Implemented (6)

### Hook 1: `pre-code-generation`

| Attribute | Details |
|-----------|---------|
| **Trigger** | Before ANY OpenSCAD code generation |
| **Action** | Declare scope, list changes, identify non-changes, request confirmation |
| **Example** | User says "Make the main gear 20% larger" - agent produces change summary and awaits "proceed" |

---

### Hook 2: `user-frustration-detector`

| Attribute | Details |
|-----------|---------|
| **Trigger** | Phrases: "going in circles", "where is my X", "think hard", "this is broken" |
| **Action** | Pattern-specific: diagnose_and_rollback, survival_checklist, extended_analysis, emergency_audit |
| **Example** | User says "where is my cam mechanism?" - agent searches version history and offers recovery |

---

### Hook 3: `post-version-delivery`

| Attribute | Details |
|-----------|---------|
| **Trigger** | After every version delivery of .scad file |
| **Action** | Run survival checklist, generate ASCII layout, provide test instructions, list decision points |
| **Example** | After delivering v5, agent shows component verification, mechanism diagram, and "TEST IT NOW" steps |

---

### Hook 4: `lock-in-detector`

| Attribute | Details |
|-----------|---------|
| **Trigger** | User finalizes a decision (e.g., "let's go with option A", "that's final") |
| **Action** | Mark decision as LOCKED, add to locked decisions list, warn before any future modification |
| **Example** | User says "frame dimensions are final" - agent adds to LOCKED list with timestamp |

---

### Hook 5: `complexity-warning`

| Attribute | Details |
|-----------|---------|
| **Trigger** | Proposed change affects >3 mechanisms or >100 lines |
| **Action** | Alert user, suggest breaking into smaller iterations, require explicit approval |
| **Example** | User asks for major refactoring - agent warns of complexity and proposes incremental approach |

---

### Hook 6: `physical-reality-check`

| Attribute | Details |
|-----------|---------|
| **Trigger** | Before finalizing any mechanism design |
| **Action** | Verify: gear mesh valid, linkage Grashof satisfied, no collisions, power path complete |
| **Example** | After gear train design, agent auto-verifies center distances match calculations |

---

## 6. Sub-Agents Implemented (5)

### Sub-Agent 1: MechanismAnalyst

| Attribute | Details |
|-----------|---------|
| **Domain** | Mechanical feasibility and physics validation |
| **Responsibilities** | Collision detection, kinematic validation, power flow analysis, fit verification, stress checks |
| **Key Tools** | analyze_geometry, calculate_gear_train, check_grashof, sweep_volume, clearance_check |
| **Trigger Keywords** | "collision", "torque", "gear ratio", "linkage", "will this work" |

---

### Sub-Agent 2: OpenSCADArchitect

| Attribute | Details |
|-----------|---------|
| **Domain** | Code structure and parametric design |
| **Responsibilities** | Code organization, naming conventions, module design, animation optimization, performance |
| **Key Tools** | parse_scad, validate_syntax, extract_parameters, dependency_graph, refactor_module |
| **Trigger Keywords** | "clean up code", "refactor", "structure", "organize" |

---

### Sub-Agent 3: VersionController

| Attribute | Details |
|-----------|---------|
| **Domain** | Change tracking and rollback management |
| **Responsibilities** | Version tagging, component survival, diff analysis, recovery point management |
| **Key Tools** | create_version, compare_versions, find_last_good, restore_component |
| **Trigger Keywords** | "what changed", "rollback", "restore", "previous version" |

---

### Sub-Agent 4: VisualizationGuide

| Attribute | Details |
|-----------|---------|
| **Domain** | ASCII diagrams and visual communication |
| **Responsibilities** | Mechanism diagrams, power flow charts, Z-stack visualizations, motion paths |
| **Key Tools** | generate_layout_diagram, create_power_flow, render_z_stack, animate_motion_path |
| **Trigger Keywords** | "show me", "visualize", "diagram", "layout" |

---

### Sub-Agent 5: DecisionFacilitator

| Attribute | Details |
|-----------|---------|
| **Domain** | User choice management and consensus building |
| **Responsibilities** | Present options, track pending decisions, record locked decisions, manage tradeoffs |
| **Key Tools** | present_options, record_decision, list_pending, check_lock_conflicts |
| **Trigger Keywords** | "which should I", "options", "decide", "tradeoff" |

---

## 7. Integration Points

### How CLAUDE.md Connects Everything

The `unified_system_prompt.md` serves as the orchestrating document that:

1. **Establishes Identity** - Defines the agent as an "Expert Mechanical Design Engineer"
2. **Enforces Anti-Patterns** - 7 things the agent must NEVER do
3. **Mandates Practices** - 7 things the agent must ALWAYS do
4. **Provides Workflow** - 4-phase design process (Vision, Analysis, Design, Verification)
5. **Contains Reference Knowledge** - Gear formulas, linkage classification, tolerances
6. **Defines Trigger Phrases** - Maps user statements to required actions

### How Scripts Support the Workflow

`openscad_templates.scad` provides:

- **Section 1**: Master file structure template
- **Section 2**: Gear calculation modules with `echo()` debugging
- **Section 3**: Four-bar linkage with Grashof validation
- **Section 4**: Animation patterns (linear, oscillation, easing, stepped)
- **Section 5**: Z-layer constants and management
- **Section 6**: SVG import patterns
- **Section 7**: Debug visualization helpers
- **Section 8**: Component survival markers
- **Section 9**: Utility functions (clamp, lerp, vec_len, etc.)
- **Section 10**: Example assembly

### How Specs Track Project State

`master_specification_template.md` maintains:

- **Dimensions & Boundaries** - Locked frame dimensions with rationale
- **Component Inventory** - Every part with status, Z-layer, position, connections
- **Mechanism Chain** - ASCII power flow from motor to all outputs
- **Z-Layer Stack** - Complete depth mapping with clearances
- **Locked Decisions** - Finalized choices with dates and impact warnings
- **Active Decisions** - Pending questions with options and recommendations
- **Version History** - Every iteration with survival check results
- **Known Issues** - Tracked problems with proposed fixes

---

## 8. Usage Workflow

### Starting a New Session

```
1. LOAD the unified_system_prompt.md into agent context
2. CREATE or OPEN a master_specification.md for the project
3. ESTABLISH locked decisions (frame size, motor specs, etc.)
4. RUN /gear-calc for any gear placements
5. RUN /linkage-check for any four-bar mechanisms
6. RUN /z-stack to plan layer arrangement
7. GENERATE initial code using openscad_templates.scad patterns
8. DELIVER with post-version-delivery hook output
```

### Making Changes Safely

```
1. BEFORE any code generation:
   - pre-code-generation hook activates
   - Agent declares: what WILL change, what WILL NOT change
   - Agent awaits user confirmation

2. DURING changes:
   - complexity-warning hook fires if >3 mechanisms affected
   - physical-reality-check validates mechanics

3. AFTER changes:
   - /version-diff compares old vs new
   - /component-survival verifies nothing lost
   - post-version-delivery provides test instructions
```

### Recovering from Problems

```
IF user says "going in circles":
   1. Hook triggers diagnose_and_rollback
   2. Agent identifies the cycle pattern
   3. Agent finds last known good version
   4. Agent proposes recovery plan

IF user says "where is my X":
   1. Hook triggers survival_checklist
   2. Agent searches current file, history, renamed/moved
   3. Agent identifies loss point (version and change)
   4. Agent offers to restore with specific code

IF user says "this is broken":
   1. Hook triggers emergency_audit
   2. Agent STOPS all changes
   3. Agent audits last 5 versions
   4. Agent identifies breaking change
   5. Agent awaits user direction
```

### Locking Decisions

```
1. User makes final decision ("frame size is final")
2. lock-in-detector hook activates
3. Agent:
   - Confirms: "I'm locking frame_dimensions = 350x275x100mm"
   - Adds to LOCKED DECISIONS in master_spec
   - Records date, rationale, impact if changed
4. Future requests that would change locked items:
   - Agent warns: "This would modify locked item L001"
   - Requires explicit override confirmation
```

---

## 9. Maintenance Notes

### How to Update the System

**Adding New Anti-Patterns:**
```markdown
1. Add to Section 2 of unified_system_prompt.md
2. Use format: ### AP-N: NEVER [action]
3. Include WRONG and RIGHT examples
4. Add to Quick Reference Card at bottom
```

**Updating Formulas:**
```markdown
1. Update in unified_system_prompt.md Section 7
2. Update in skills.md for relevant skill
3. Update in openscad_templates.scad Section 2-3
4. Update in issues_and_mitigations.md Appendix
```

### How to Add New Skills

```markdown
1. Create new skill section in skills.md following existing format:
   - Purpose
   - Why This Matters
   - Formulas
   - Input Parameters table
   - Output Format template
   - Example Usage
   - Integration Notes

2. Add to Quick Reference Card at bottom of skills.md

3. Add trigger keywords to sub_agents.md for auto-invocation

4. Update recommended skill sequences in Workflow Integration section
```

### How to Add New Hooks

```markdown
1. Create new hook section in hooks.md:
   - Purpose
   - Trigger Conditions (YAML format)
   - Step-by-Step Action Sequence
   - Output Format
   - Example Interaction
   - JavaScript implementation reference

2. Add to Table of Contents

3. Update trigger phrase table in unified_system_prompt.md Section 11
```

### Version Control Recommendations

```
RECOMMENDED GIT WORKFLOW:

1. Each major version of the project = separate commit
2. Commit message format: "V[N]: [summary of changes]"
3. Tag stable milestones: git tag -a v25-waves-working
4. Keep master_spec.md updated with each commit
5. Never force-push to main branch
6. Use branches for experimental changes

RECOVERY POINTS TO TAG:
- After initial frame design
- After motor/gear integration
- After each mechanism working
- Before any major refactoring
```

---

## 10. Next Steps - Recommendations for Enhancement

### Priority 1: Immediate Improvements

1. **Create CLAUDE.md integration file**
   - Combine key elements from all files into single agent bootstrap
   - Include quick-reference formulas and checklists

2. **Add STL export workflow**
   - Skill for generating printable exports
   - Layer separation for multi-material prints

3. **Add BOM generator**
   - Skill to extract bill of materials from master_spec
   - Include hardware, motors, fasteners

### Priority 2: Feature Expansion

4. **Add cam profile skill**
   - `/cam-calc` for cam geometry
   - Follower motion profiles
   - Dwell periods

5. **Add tolerance stackup skill**
   - `/tolerance-check` for assembly tolerance analysis
   - GD&T basics for 3D printing

6. **Add Geneva mechanism support**
   - Template module for intermittent motion
   - Timing calculations

### Priority 3: Tooling Integration

7. **OpenSCAD CLI integration**
   - Bash commands for headless rendering
   - Animation frame export automation
   - DXF generation for laser cutting

8. **Git version control hooks**
   - Auto-run survival checklist on commit
   - Block commits that remove components

9. **Visual diff tool**
   - Side-by-side OpenSCAD preview comparison
   - Highlight changed geometry

### Priority 4: Extended Domains

10. **Electrical integration**
    - Motor selection helper
    - Wiring diagram generation
    - Power budget calculation

11. **Assembly instruction generator**
    - Step-by-step build guide from model
    - Exploded view generation

12. **Cost estimation**
    - Material volume calculation
    - Print time estimation
    - Hardware cost lookup

---

## Appendix A: File Location Reference

All implementation files are located at:

```
D:\Claude local\3d_design_agent\
|
+-- unified_system_prompt.md    (Core agent identity and rules)
+-- skills.md                   (6 slash command definitions)
+-- hooks.md                    (6 automated trigger behaviors)
+-- sub_agents.md               (5 specialized domain experts)
+-- openscad_templates.scad     (Reusable OpenSCAD code patterns)
+-- master_specification_template.md  (Project state tracking template)
+-- issues_and_mitigations.md   (Known problems and solutions)
+-- IMPLEMENTATION_REPORT.md    (This document)
```

---

## Appendix B: Quick Start Checklist

```
DEPLOYING THE 3D MECHANICAL DESIGN AGENT:

[ ] 1. Load unified_system_prompt.md as system context
[ ] 2. Make skills.md available for /command reference
[ ] 3. Activate hooks.md trigger patterns
[ ] 4. Enable sub-agent delegation from sub_agents.md
[ ] 5. Copy openscad_templates.scad to project directory
[ ] 6. Create project-specific master_spec from template
[ ] 7. Review issues_and_mitigations.md for known challenges

FIRST INTERACTION CHECKLIST:

[ ] Establish frame dimensions and lock them
[ ] Define motor specifications
[ ] List all intended mechanisms
[ ] Create component inventory
[ ] Run /gear-calc for initial gear train
[ ] Run /linkage-check for any linkages
[ ] Run /z-stack for layer planning
[ ] Generate V01 with survival checklist
```

---

*Implementation Report Generated: 2026-01-16*
*Framework Version: 1.0*
*Total Implementation: 7 files, ~6,300 lines*
