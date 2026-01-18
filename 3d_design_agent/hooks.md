# 3D Mechanical Design Agent - Hooks Implementation v2.0

## Overview

This document defines automated triggers (Hooks) for the 3D Mechanical Design Agent specialized in OpenSCAD, kinetic art, and mechanical assemblies. These hooks ensure safe, predictable code generation, maintain design integrity, and enforce quality standards from the Kinetic Sculpture Compendium.

**Version 2.0 Enhancements:**
- 15 hooks organized into 5 priority levels
- Integration with Polymath Design Methodology
- Longevity and quality verification gates
- Sub-agent orchestration triggers
- Compendium-based validation

---

## Table of Contents

### Priority Level 1: CRITICAL (Always Execute)
1. [Hook 1: pre-code-generation](#hook-1-pre-code-generation)
2. [Hook 2: physical-linkage-check](#hook-2-physical-linkage-check)
3. [Hook 3: polymath-pre-design-check](#hook-3-polymath-pre-design-check)

### Priority Level 2: PRESERVATION (Protect User Work)
4. [Hook 4: lock-in-detector](#hook-4-lock-in-detector)
5. [Hook 5: component-survival-check](#hook-5-component-survival-check)
6. [Hook 6: version-backup](#hook-6-version-backup)

### Priority Level 3: VERIFICATION (Quality Gates)
7. [Hook 7: physical-reality-check](#hook-7-physical-reality-check)
8. [Hook 8: animation-validation](#hook-8-animation-validation)
9. [Hook 9: longevity-check](#hook-9-longevity-check)

### Priority Level 4: USER EXPERIENCE
10. [Hook 10: user-frustration-detector](#hook-10-user-frustration-detector)
11. [Hook 11: complexity-warning](#hook-11-complexity-warning)
12. [Hook 12: post-version-delivery](#hook-12-post-version-delivery)

### Priority Level 5: ENHANCEMENT (Optional Quality)
13. [Hook 13: failure-pattern-detector](#hook-13-failure-pattern-detector)
14. [Hook 14: quality-assessment](#hook-14-quality-assessment)
15. [Hook 15: compendium-reference](#hook-15-compendium-reference)

### Reference
- [Priority Execution Order](#priority-execution-order)
- [Hook Interaction Matrix](#hook-interaction-matrix)
- [Implementation Reference](#implementation-reference)

---

# PRIORITY LEVEL 1: CRITICAL

These hooks MUST execute before any code generation. Failure blocks all output.

---

## Hook 1: pre-code-generation

### Purpose
Prevent unintended changes by requiring explicit declaration and confirmation before ANY OpenSCAD code generation.

### Priority Level
**CRITICAL** - Always execute, blocks code output until passed

### Trigger Conditions

```yaml
trigger:
  event: "before_code_generation"
  conditions:
    - agent_is_about_to_write_openscad_code: true
    - target_file_extension: [".scad"]
    - action_type: ["create", "modify", "refactor"]
```

**Pattern Detection:**
- Agent formulating OpenSCAD module/function
- User requests code changes to any `.scad` file
- Agent about to insert, delete, or modify code blocks

### Step-by-Step Action Sequence

```
STEP 1: Identify Scope
├── Parse target file(s)
├── Identify specific line numbers
└── List all modules/functions to be touched

STEP 2: Declare Changes
├── STATE: "I will modify [FILE] at lines [X-Y]"
├── STATE: "This adds/changes/removes [DESCRIPTION]"
└── STATE: "Affected modules: [LIST]"

STEP 3: Declare Non-Changes
├── STATE: "I will NOT touch [MODULES/SECTIONS]"
├── LIST: All mechanisms that remain unchanged
└── CONFIRM: "[COMPONENT] remains at [VALUE]"

STEP 4: Impact Analysis
├── List all mechanisms this change affects
├── Trace dependencies (what calls this? what does this call?)
└── Identify potential cascade effects

STEP 5: Breakage Verification
├── Check: Does this affect gear meshing?
├── Check: Does this affect linkage geometry?
├── Check: Does this affect assembly order?
└── Check: Does this conflict with locked items?

STEP 6: Request Confirmation
├── Present summary to user
├── WAIT for explicit "yes", "proceed", or "approved"
└── Do NOT generate code until confirmed
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ PRE-CODE-GENERATION CHECK                                   │
├─────────────────────────────────────────────────────────────┤
│ TARGET FILE: [filename.scad]                                │
│ LINES AFFECTED: [start_line] - [end_line]                   │
├─────────────────────────────────────────────────────────────┤
│ WILL CHANGE:                                                │
│   • [module_name]: [description of change]                  │
│   • [variable_name]: [old_value] → [new_value]              │
├─────────────────────────────────────────────────────────────┤
│ WILL NOT CHANGE:                                            │
│   • [protected_module_1] - remains intact                   │
│   • [protected_module_2] - remains intact                   │
│   • [locked_parameter] = [value] (LOCKED)                   │
├─────────────────────────────────────────────────────────────┤
│ MECHANISMS AFFECTED:                                        │
│   [1] [mechanism_name] - [how it's affected]                │
│   [2] [mechanism_name] - [how it's affected]                │
├─────────────────────────────────────────────────────────────┤
│ BREAKAGE CHECK:                                             │
│   ✓ No gear mesh conflicts                                  │
│   ✓ No linkage geometry violations                          │
│   ✓ No locked item violations                               │
│   ✓ Assembly order preserved                                │
├─────────────────────────────────────────────────────────────┤
│ AWAITING CONFIRMATION                                       │
│ Type "proceed" or "yes" to generate code                    │
└─────────────────────────────────────────────────────────────┘
```

### Example Interaction

**User:** "Make the main gear 20% larger"

**Agent Response:**
```
┌─────────────────────────────────────────────────────────────┐
│ PRE-CODE-GENERATION CHECK                                   │
├─────────────────────────────────────────────────────────────┤
│ TARGET FILE: starry_night_v54.scad                          │
│ LINES AFFECTED: 145-162                                     │
├─────────────────────────────────────────────────────────────┤
│ WILL CHANGE:                                                │
│   • sun_drive_gear: radius 30 → 36                          │
│   • gear_teeth: 24 → 29 (to maintain module 2.5)            │
│   • gear_position: y-offset +6 for clearance                │
├─────────────────────────────────────────────────────────────┤
│ WILL NOT CHANGE:                                            │
│   • wave_mechanism - untouched                              │
│   • star_gears - positions unchanged                        │
│   • frame_dimensions - 300x200x150 (LOCKED)                 │
├─────────────────────────────────────────────────────────────┤
│ MECHANISMS AFFECTED:                                        │
│   [1] Sun rotation - gear ratio changes 2:1 → 2.4:1         │
│   [2] Planet gears - need repositioning for mesh            │
├─────────────────────────────────────────────────────────────┤
│ BREAKAGE CHECK:                                             │
│   ✓ Gear mesh verified (module 2.5 maintained)              │
│   ! Planet gears need Y+6 offset adjustment                 │
│   ✓ No locked item violations                               │
│   ✓ Fits within frame (36 < 50 max)                         │
├─────────────────────────────────────────────────────────────┤
│ AWAITING CONFIRMATION                                       │
│ Note: Planet gears will need offset adjustment              │
│ Type "proceed" to generate code                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 2: physical-linkage-check

### Purpose
Verify that ALL linkage mechanisms have valid physical connections before generating animation code. Prevents the V53 Disconnect failure pattern.

### Priority Level
**CRITICAL** - Execute before ANY animation code for linkages

### Trigger Conditions

```yaml
trigger:
  event: "before_linkage_animation"
  conditions:
    - code_contains: ["coupler", "four_bar", "linkage", "slider_crank"]
    - animation_variable_used: ["$t", "master_phase", "sin(", "cos("]
```

**Pattern Detection:**
```regex
/\b(coupler|four_bar|linkage|crank|slider|rocker)\b.*\b(sin|cos)\s*\(/i
```

### Mandatory Verification Checklist

```
PHYSICAL CONNECTION VALIDATION:

[ ] DRIVER ENDPOINT
    └── Coupler start coordinates match driver attachment point
    └── Driver rotation axis verified
    └── Attachment method specified (pin/slot/ball)

[ ] DRIVEN ENDPOINT
    └── Coupler end coordinates match driven element attachment point
    └── Driven element pivot verified
    └── Transmission complete from driver to output

[ ] MOTION TYPE COMPATIBILITY
    └── Pin joint → rotation only (no translation)
    └── Slider joint → translation only (no rotation)
    └── Ball joint → multi-axis rotation
    └── Coupler rod → oscillates, NOT 360° rotation

[ ] GRASHOF CONDITION (for four-bar)
    └── S + L ≤ P + Q verified
    └── Crank-rocker, double-crank, or rocker-rocker identified
    └── Dead points identified and handled

[ ] RANGE OF MOTION
    └── All intermediate positions reachable
    └── No mechanical lockup (transmission angle > 30°)
    └── Coupler length constant throughout cycle
```

### Action on Failure

```
IF ANY CHECK FAILS:
├── DO NOT generate animation code
├── Report specific failure to user
├── Show diagram of expected vs actual connection
├── Suggest correction
└── WAIT for user acknowledgment before proceeding

EXAMPLE FAILURE REPORT:
┌─────────────────────────────────────────────────────────────┐
│ LINKAGE CHECK FAILED                                        │
├─────────────────────────────────────────────────────────────┤
│ ISSUE: Coupler endpoint not connected to wave element       │
│                                                             │
│ EXPECTED:                   ACTUAL:                         │
│   Crank ○──────○ Wave         Crank ○──────○ (floating)     │
│         └coupler┘                   └coupler┘  Wave ○       │
│                                                             │
│ The coupler rod endpoint at [x,y,z] does not touch          │
│ the wave pivot at [x',y',z']. Gap = 15mm                    │
│                                                             │
│ SUGGESTION: Extend coupler length or reposition wave pivot  │
├─────────────────────────────────────────────────────────────┤
│ Animation code generation BLOCKED until resolved            │
└─────────────────────────────────────────────────────────────┘
```

### Output Format (Success)

```
┌─────────────────────────────────────────────────────────────┐
│ PHYSICAL LINKAGE CHECK: PASSED                              │
├─────────────────────────────────────────────────────────────┤
│ MECHANISM: wave_drive_linkage                               │
│                                                             │
│ CONNECTION TRACE:                                           │
│   Motor shaft ──○── Crank (r=25)                            │
│                 │                                           │
│   Crank pin ────○── Coupler rod (L=80)                      │
│                     │                                       │
│   Coupler end ──────○── Wave pivot                          │
│                         │                                   │
│   Wave element ─────────┘                                   │
│                                                             │
│ MOTION TYPE: Crank-rocker (validated)                       │
│ GRASHOF: S(25) + L(80) = 105 ≤ P(60) + Q(50) = 110 ✓        │
│ TRANSMISSION ANGLE: min 42° (>30° threshold) ✓              │
│ DEAD POINTS: None in operating range ✓                      │
├─────────────────────────────────────────────────────────────┤
│ Animation code generation APPROVED                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 3: polymath-pre-design-check

### Purpose
Apply the Seven Masters methodology before ANY mechanism design. Ensures physics, fabrication, and kinematics are valid before code generation.

### Priority Level
**CRITICAL** - Execute when user requests new mechanism or significant change

### Trigger Conditions

```yaml
trigger:
  event: "new_mechanism_request"
  patterns:
    - /\b(add|create|design|make|build|implement)\s+(a\s+)?(new\s+)?(mechanism|linkage|gear|cam|motion|movement|animation)\b/i
    - /\b(change|modify|update)\s+(the\s+)?(motion|mechanism|linkage|gear|drive)\b/i
```

### Mandatory Checklist (Seven Masters)

```
POLYMATH PRE-DESIGN VERIFICATION

VAN GOGH CHECK (Turbulence Physics)
[ ] Motion pattern identified (cyclic, chaotic, wave, spiral)
[ ] Mathematical relationship defined (sin, cos, polynomial, Fourier)
[ ] Phase relationships to other elements specified
[ ] "Does the motion feel alive?" - emotional quality considered

DA VINCI CHECK (Friction Science)
[ ] Friction coefficient estimated for material pairs
    └── PLA on PLA: μ ≈ 0.25-0.35
    └── Metal on PLA: μ ≈ 0.15-0.25
    └── Brass on bronze: μ ≈ 0.15
[ ] Bearing surfaces identified
[ ] Lubrication requirements noted (or self-lubricating material)

TESLA CHECK (Mental Simulation)
[ ] Full mechanism cycle mentally traced
[ ] Collision points identified at ALL rotation angles
[ ] Extreme positions verified (0°, 90°, 180°, 270°)
[ ] "Can I see it running in my mind?" - complete visualization

EDISON CHECK (Test Protocol)
[ ] Test procedure defined before building
[ ] Success/failure criteria established
[ ] Measurement method identified
[ ] "What specific test proves this works?"

WATT CHECK (Efficiency)
[ ] Power path traced: Motor → [stages] → Output
[ ] Estimated efficiency at each stage
[ ] Total efficiency acceptable (>50% for kinetic art)
[ ] Torque budget: motor capacity > mechanism load?

GALILEO CHECK (Experimental Verification)
[ ] How will we verify this in OpenSCAD preview?
[ ] What animation positions to check?
[ ] Physical prototype needed before commitment?

ARCHIMEDES CHECK (First Principles)
[ ] Does this violate any physics laws?
[ ] Lever arm and torque calculations correct?
[ ] Center of gravity considered?
[ ] "Would Archimedes approve the geometry?"
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ POLYMATH PRE-DESIGN CHECK                                   │
├─────────────────────────────────────────────────────────────┤
│ PROPOSED MECHANISM: [name]                                  │
├─────────────────────────────────────────────────────────────┤
│ VAN GOGH:  [✓/✗] [Motion pattern: sine wave, f=0.5Hz]       │
│ DA VINCI:  [✓/✗] [Friction: PLA/PLA, μ=0.3, bronze bush]    │
│ TESLA:     [✓/✗] [Full cycle traced, no collisions]         │
│ EDISON:    [✓/✗] [Test: animate $t 0→1, watch for gaps]     │
│ WATT:      [✓/✗] [Efficiency: 85% gear, 70% linkage]        │
│ GALILEO:   [✓/✗] [Verify: F5 at t=0, 0.25, 0.5, 0.75]       │
│ ARCHIMEDES:[✓/✗] [CG balanced, lever ratios correct]        │
├─────────────────────────────────────────────────────────────┤
│ OVERALL: [APPROVED / NEEDS WORK / REJECTED]                 │
│                                                             │
│ [If NEEDS WORK, list specific issues to resolve]            │
└─────────────────────────────────────────────────────────────┘
```

### Failure Pattern References

When a check fails, reference the corresponding failure pattern:

| Check Fails | Reference | Pattern Name |
|-------------|-----------|--------------|
| Van Gogh | FAILURE_PATTERNS.md | Motion Disconnect |
| Da Vinci | FAILURE_PATTERNS.md | Da Vinci Dream (Power-to-Weight) |
| Tesla | FAILURE_PATTERNS.md | Tesla Trap (Material Limits) |
| Edison | FAILURE_PATTERNS.md | Untested Assumption |
| Watt | FAILURE_PATTERNS.md | Efficiency Blindness |
| Galileo | FAILURE_PATTERNS.md | Galileo Bias (Confirmation) |
| Archimedes | FAILURE_PATTERNS.md | Physics Violation |

---

# PRIORITY LEVEL 2: PRESERVATION

These hooks protect user work from accidental loss or modification.

---

## Hook 4: lock-in-detector

### Purpose
Detect when user wants to freeze/finalize parameters and prevent future accidental modifications.

### Priority Level
**PRESERVATION** - Protects finalized user decisions

### Trigger Conditions

```yaml
trigger:
  type: "phrase_detection"
  patterns:
    - /\b(lock (this|it)|final(ize)?|freeze|don't (touch|change|modify))\b/i
    - /\b(approved|ship it|done with this|keep (this|it) (exactly|as is))\b/i
    - /\b(perfect|exactly right|don't mess with)\b/i
```

### Step-by-Step Action Sequence

```
STEP 1: Identify Lock Target
├── Parse what user wants locked
├── Identify specific parameters/modules
└── Confirm scope with user if ambiguous

STEP 2: Apply Lock
├── Add "// LOCKED - [date] - [reason]" comment
├── Record in lock registry
└── Create backup in versions folder

STEP 3: Acknowledge Lock
├── Confirm what was locked
├── Show lock notation added
└── Explain protection behavior

STEP 4: Future Protection
├── Pre-code-generation checks locked items
├── Warn before ANY modification
├── Require explicit unlock command
```

### Lock Comment Format

```openscad
// ═══════════════════════════════════════════════════════════════
// LOCKED - 2025-01-17 - User approved final dimensions
// DO NOT MODIFY without explicit unlock command
// Protected: frame_width, frame_height, frame_depth
// ═══════════════════════════════════════════════════════════════
frame_width = 300;   // LOCKED
frame_height = 200;  // LOCKED
frame_depth = 150;   // LOCKED
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ LOCK APPLIED                                                │
├─────────────────────────────────────────────────────────────┤
│ LOCKED ITEMS:                                               │
│   • frame_width = 300mm                                     │
│   • frame_height = 200mm                                    │
│   • frame_depth = 150mm                                     │
│                                                             │
│ REASON: User approved final dimensions                      │
│ DATE: 2025-01-17                                            │
│                                                             │
│ BACKUP: versions/starry_night_v54_locked_backup.scad        │
├─────────────────────────────────────────────────────────────┤
│ These values will be protected from modification.           │
│ To unlock: say "unlock [parameter]" or "remove lock"        │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 5: component-survival-check

### Purpose
Verify that ALL components from previous version exist in new version. Prevents accidental deletion of user work.

### Priority Level
**PRESERVATION** - Runs after every version delivery

### Trigger Conditions

```yaml
trigger:
  event: "post_version_delivery"
  conditions:
    - new_version_created: true
    - previous_version_exists: true
```

### Step-by-Step Action Sequence

```
STEP 1: Parse Previous Version
├── Extract all module definitions
├── Extract all named parameters
├── Create component inventory

STEP 2: Parse New Version
├── Extract all module definitions
├── Extract all named parameters
├── Create component inventory

STEP 3: Compare Inventories
├── Identify present in both ✓
├── Identify missing from new ✗
├── Identify new additions +
├── Identify renamed ~

STEP 4: Report Results
├── If all present: "Survival check passed"
├── If any missing: ALERT user immediately
├── Offer to restore missing components
```

### Output Format (Failure)

```
┌─────────────────────────────────────────────────────────────┐
│ COMPONENT SURVIVAL CHECK: FAILED                            │
├─────────────────────────────────────────────────────────────┤
│ MISSING FROM NEW VERSION:                                   │
│   ✗ cam_mechanism (was at line 234)                         │
│   ✗ follower_arm (was at line 256)                          │
│                                                             │
│ LAST SEEN: Version 53                                       │
│ LOST DURING: "Refactoring gear train"                       │
├─────────────────────────────────────────────────────────────┤
│ RECOVERY OPTIONS:                                           │
│   [1] Restore from version 53                               │
│   [2] Show me the lost code                                 │
│   [3] I intended to remove these                            │
│                                                             │
│ Which option?                                               │
└─────────────────────────────────────────────────────────────┘
```

### Output Format (Success)

```
┌─────────────────────────────────────────────────────────────┐
│ COMPONENT SURVIVAL CHECK: PASSED                            │
├─────────────────────────────────────────────────────────────┤
│ VERIFIED COMPONENTS: 24/24                                  │
│   ✓ sun_gear_mechanism                                      │
│   ✓ planet_gear_array                                       │
│   ✓ wave_linkage                                            │
│   ✓ star_rotation_drive                                     │
│   ... [18 more components]                                  │
│                                                             │
│ NEW ADDITIONS: 2                                            │
│   + moon_phase_cam                                          │
│   + horizon_gradient                                        │
│                                                             │
│ All previous components preserved.                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 6: version-backup

### Purpose
Automatically create immutable backups before significant changes.

### Priority Level
**PRESERVATION** - Runs before multi-module changes

### Trigger Conditions

```yaml
trigger:
  event: "before_significant_change"
  conditions:
    - modules_affected: ">3"
    - OR: lines_changed: ">50"
    - OR: structure_change: true
```

### Action

```
STEP 1: Create Backup
├── Copy current file to versions/
├── Name: [filename]_v[N]_backup_[timestamp].scad
├── Add header comment with change description

STEP 2: Record Backup
├── Update version log
├── Store diff summary
└── Confirm to user

STEP 3: Proceed with Changes
├── Reference backup location
└── Enable rollback if needed
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ AUTO-BACKUP CREATED                                         │
├─────────────────────────────────────────────────────────────┤
│ This change affects 5 modules and 87 lines.                 │
│ Creating backup before proceeding...                        │
│                                                             │
│ BACKUP: versions/starry_night_v54_backup_20250117_1430.scad │
│                                                             │
│ If anything goes wrong, we can restore from this backup.    │
│ Proceeding with changes...                                  │
└─────────────────────────────────────────────────────────────┘
```

---

# PRIORITY LEVEL 3: VERIFICATION

These hooks verify quality and correctness before delivery.

---

## Hook 7: physical-reality-check

### Purpose
Verify that mechanisms are physically possible, printable, and assemblable.

### Priority Level
**VERIFICATION** - Runs on request or before delivery

### Trigger Conditions

```yaml
trigger:
  type: "phrase_detection"
  patterns:
    - /\b(will (this|it) (work|print|move|function|fit))\b/i
    - /\b(is (this|it) (printable|possible|feasible|realistic))\b/i
    - /\b(can (this|it) (move|rotate|work|be (printed|built|made)))\b/i
```

Also runs automatically before major version delivery.

### Verification Checklist

```
PHYSICAL REALITY CHECK

PRINTABILITY:
[ ] Wall thickness ≥ 1.2mm (FDM minimum)
[ ] Clearance between moving parts ≥ 0.3mm
[ ] Overhangs < 45° or properly supported
[ ] No trapped support material
[ ] Bridge spans < 50mm unsupported

ASSEMBLABILITY:
[ ] Access for fasteners (screwdriver clearance)
[ ] Assembly sequence possible
[ ] Parts can be inserted in correct order
[ ] No impossible interference during assembly

FUNCTIONALITY:
[ ] Gears mesh correctly (center distance verified)
[ ] Linkages reach full range without binding
[ ] Cams follow without jumping
[ ] Bearings have proper clearance

STRUCTURAL:
[ ] Stress points reinforced
[ ] Cantilevers within strength limits
[ ] Load paths verified
[ ] No thin sections under torque
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ PHYSICAL REALITY CHECK                                      │
├─────────────────────────────────────────────────────────────┤
│ PRINTABILITY:                                               │
│   ✓ Wall thickness: min 1.5mm (>1.2mm threshold)            │
│   ✓ Clearances: 0.4mm between gears (>0.3mm threshold)      │
│   ! Overhang on sun_housing: 52° (needs support)            │
│   ✓ No trapped support regions                              │
│                                                             │
│ ASSEMBLABILITY:                                             │
│   ✓ All fastener access verified                            │
│   ✓ Assembly sequence documented                            │
│   ! Planet gears must insert before ring gear               │
│                                                             │
│ FUNCTIONALITY:                                              │
│   ✓ Gear mesh: center distance 45mm = (20+25)×1.8/2 ✓       │
│   ✓ Four-bar linkage: Grashof condition satisfied           │
│   ✓ Cam followers maintain contact                          │
│                                                             │
│ STRUCTURAL:                                                 │
│   ✓ Main shaft: 8mm diameter (rated for 0.5 Nm)             │
│   ! Arm cantilever: consider adding gusset at base          │
├─────────────────────────────────────────────────────────────┤
│ VERDICT: BUILDABLE with 2 notes                             │
│   1. Add support for sun_housing overhang                   │
│   2. Consider gusset on arm cantilever                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 8: animation-validation

### Purpose
Verify that ALL animated elements have valid physical drivers. Prevents fake animations.

### Priority Level
**VERIFICATION** - Runs before any animation code

### Trigger Conditions

```yaml
trigger:
  event: "before_animation_code"
  pattern: /\b(sin|cos)\s*\(\s*(\$t|master_phase|phase)/
```

### Validation Rules

```
FOR EACH ANIMATED ELEMENT:

[ ] Physical driver identified
    └── What mechanism moves this element?
    └── Is the driver connected?
    └── Does driver motion type match animation?

[ ] Animation formula matches kinematics
    └── sin() only for harmonic motion from cranks
    └── Non-harmonic motion needs correct formula
    └── Phase offsets justified by mechanism geometry

[ ] Motion amplitude matches physical constraints
    └── Rotation range from linkage geometry
    └── Translation range from slider limits
    └── No animation beyond physical limits

[ ] No "orphan" animations
    └── Every sin($t) has a corresponding physical mechanism
    └── No visual-only animation allowed
```

### Failure Example

```
┌─────────────────────────────────────────────────────────────┐
│ ANIMATION VALIDATION: FAILED                                │
├─────────────────────────────────────────────────────────────┤
│ ORPHAN ANIMATION DETECTED:                                  │
│                                                             │
│   Line 456: wave_position = 20 * sin($t * 360 * 3);         │
│                                                             │
│   This animation has NO PHYSICAL DRIVER.                    │
│   The wave element is not connected to any mechanism.       │
│                                                             │
│ REQUIRED:                                                   │
│   Wave must be driven by coupler rod from crank             │
│   Animation should derive from linkage kinematics           │
│                                                             │
│ SUGGESTION:                                                 │
│   Calculate wave position from four-bar linkage output:     │
│   wave_angle = atan2(coupler_y, coupler_x);                 │
├─────────────────────────────────────────────────────────────┤
│ Animation code generation BLOCKED                           │
│ Connect the mechanism first, then animate.                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 9: longevity-check

### Purpose
Verify mechanism is designed for long-term operation (10+ years). Based on Compendium Domain 10: Longevity Engineering.

### Priority Level
**VERIFICATION** - Runs on request or before "final" version

### Trigger Conditions

```yaml
trigger:
  type: "phrase_detection"
  patterns:
    - /\b(final|production|long.?term|durable|lasting)\b/i
    - /\b(will (this|it) last|how long|lifespan|durability)\b/i
```

### Longevity Checklist

```
LONGEVITY ENGINEERING CHECK

WEAR SURFACES:
[ ] Bearing surfaces identified
[ ] Material pairing appropriate (dissimilar recommended)
[ ] Replaceable wear parts designed
[ ] Wear indicators visible

LUBRICATION:
[ ] Lubrication points identified
[ ] Self-lubricating materials where possible
[ ] Access for periodic lubrication
[ ] Lubricant type specified

FATIGUE LIFE:
[ ] Stress concentrations minimized
[ ] Fillet radii on all sharp internal corners
[ ] Cycle count estimated
[ ] Safety factor > 2 for oscillating parts

ENVIRONMENTAL:
[ ] UV exposure considered (indoor/outdoor)
[ ] Temperature range specified
[ ] Humidity effects on materials
[ ] Dust/debris ingress prevention

MAINTENANCE ACCESS:
[ ] Components accessible without full disassembly
[ ] Adjustment mechanisms provided
[ ] Spare parts identified
[ ] Documentation for future maintenance
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ LONGEVITY CHECK                                             │
├─────────────────────────────────────────────────────────────┤
│ ESTIMATED LIFESPAN: 10+ years (indoor, light use)           │
│                                                             │
│ WEAR SURFACES:                                              │
│   ✓ Main shaft: brass bushing on PLA (good pairing)         │
│   ✓ Gear teeth: Delrin recommended for high-wear gears      │
│   ! Cam follower: consider adding replaceable tip           │
│                                                             │
│ LUBRICATION:                                                │
│   ✓ Self-lubricating bushings used                          │
│   ✓ PTFE spray recommended for gears annually               │
│   ! Add grease fitting to main bearing                      │
│                                                             │
│ FATIGUE:                                                    │
│   ✓ Fillet radii on crank arm                               │
│   ! Coupler rod needs larger fillet at pivot                │
│   Estimated cycles: 10M @ 1 RPM continuous                  │
│                                                             │
│ MAINTENANCE:                                                │
│   ✓ Side panel removable for access                         │
│   ! Document lubrication schedule                           │
├─────────────────────────────────────────────────────────────┤
│ VERDICT: GOOD with 3 recommendations                        │
│   1. Add replaceable cam follower tip                       │
│   2. Increase coupler rod fillet radius                     │
│   3. Create maintenance schedule document                   │
└─────────────────────────────────────────────────────────────┘
```

---

# PRIORITY LEVEL 4: USER EXPERIENCE

These hooks improve user interaction and prevent frustration.

---

## Hook 10: user-frustration-detector

### Purpose
Detect user frustration signals and respond with appropriate corrective actions to prevent wasted effort and restore progress.

### Priority Level
**USER EXPERIENCE** - Always active during conversation

### Trigger Conditions

```yaml
trigger:
  type: "phrase_detection"
  patterns:
    circles:
      phrases: ["going in circles", "we keep coming back", "same issue again"]
      action: "diagnose_and_rollback"

    lost_component:
      phrases: ["where is my", "where did my", "what happened to", "I lost"]
      action: "survival_checklist"

    think_hard:
      phrases: ["think hard", "think carefully", "really think", "slow down"]
      action: "extended_analysis"

    verify_works:
      phrases: ["verify this works", "will this actually", "prove it works"]
      action: "feasibility_check"

    broken:
      phrases: ["this is broken", "you broke", "it's broken", "nothing works"]
      action: "emergency_audit"

    frustration:
      phrases: ["ugh", "argh", "damn", "frustrated", "annoying"]
      action: "pause_and_acknowledge"
```

### Phrase-Action Matrix

| User Says | Detection Pattern | Claude Action |
|-----------|-------------------|---------------|
| "going in circles" | `/going in circles\|we keep coming back/i` | STOP → Diagnose pattern → Return to last good |
| "where is my [X]?" | `/where (is\|did) my\|what happened to/i` | Run survival checklist → Identify loss point |
| "think hard" | `/think (hard\|carefully)\|really think/i` | Extended analysis → Question assumptions |
| "verify this works" | `/verify.*works\|will this actually/i` | Full physical feasibility check |
| "this is broken" | `/broken\|you broke\|nothing works/i` | Stop all changes → Audit recent mods |
| "ugh"/"frustrated" | `/ugh\|argh\|damn\|frustrated/i` | Pause → Acknowledge → Summarize attempts |

### Action: diagnose_and_rollback

```
STEP 1: STOP
├── Immediately halt current line of work
├── Acknowledge the frustration
└── Signal diagnostic mode

STEP 2: Diagnose Pattern
├── Review last 5 exchanges
├── Identify the loop/cycle
├── Find the root cause of repetition
└── Document: "We keep returning to [X] because [Y]"

STEP 3: Find Last Good State
├── Identify last confirmed-working version
├── List what was different then
└── Propose returning to that state

STEP 4: Present Recovery Plan
├── Show: "Last known good: Version [N]"
├── Show: "What broke: [description]"
├── Show: "Proposed action: [recovery steps]"
└── Await user direction
```

### Output Format (Frustration Detected)

```
┌─────────────────────────────────────────────────────────────┐
│ PAUSE - I hear your frustration                             │
├─────────────────────────────────────────────────────────────┤
│ Let me summarize what we've tried:                          │
│                                                             │
│   Attempt 1: [description] - [outcome]                      │
│   Attempt 2: [description] - [outcome]                      │
│   Attempt 3: [description] - [outcome]                      │
│                                                             │
│ The pattern I'm seeing: [pattern description]               │
│                                                             │
│ DIFFERENT APPROACHES WE HAVEN'T TRIED:                      │
│   [A] [Alternative approach 1]                              │
│   [B] [Alternative approach 2]                              │
│   [C] Step back and reconsider the requirement              │
│                                                             │
│ What would you like to do?                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 11: complexity-warning

### Purpose
Alert user before making changes that affect many components and suggest incremental approach.

### Priority Level
**USER EXPERIENCE** - Runs when change scope is large

### Trigger Conditions

```yaml
trigger:
  event: "before_complex_change"
  conditions:
    - modules_affected: ">3"
    - OR: cascading_parameters: ">5"
    - OR: structural_change: true
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ COMPLEXITY WARNING                                          │
├─────────────────────────────────────────────────────────────┤
│ This change affects 7 components:                           │
│                                                             │
│   1. sun_gear (direct change)                               │
│   2. planet_array (gear mesh dependency)                    │
│   3. ring_gear (gear mesh dependency)                       │
│   4. wave_linkage (position offset)                         │
│   5. frame_cutout (clearance update)                        │
│   6. cover_plate (alignment)                                │
│   7. assembly_guide (documentation)                         │
│                                                             │
│ CASCADING PARAMETERS:                                       │
│   sun_radius → center_distance → planet_positions →         │
│   linkage_anchor → wave_amplitude                           │
│                                                             │
│ RECOMMENDATION:                                             │
│   Break this into 3 smaller changes:                        │
│   [1] Modify sun_gear only, verify mesh                     │
│   [2] Update dependent positions                            │
│   [3] Adjust linkage and verify motion                      │
│                                                             │
│ OPTIONS:                                                    │
│   [A] Proceed with full change (higher risk)                │
│   [B] Use incremental approach (recommended)                │
│   [C] Create test branch first                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 12: post-version-delivery

### Purpose
Ensure quality and user understanding after every version delivery with testing instructions and decision points.

### Priority Level
**USER EXPERIENCE** - Runs after every version delivery

### Trigger Conditions

```yaml
trigger:
  event: "after_version_delivery"
  conditions:
    - file_delivered: true
    - file_extension: [".scad"]
    - version_number_incremented: true
```

### Step-by-Step Action Sequence

```
STEP 1: Run Component Survival Checklist
├── Parse delivered file
├── List all expected components
├── Verify each component exists
└── Generate survival report

STEP 2: Generate ASCII Mechanism Layout
├── Identify all mechanisms in file
├── Create top-down ASCII diagram
├── Show spatial relationships
└── Show motion directions

STEP 3: Generate TEST IT NOW Instructions
├── List specific OpenSCAD commands
├── Provide preview angles to check
├── List animation parameters
└── Include troubleshooting tips

STEP 4: Present Decision Points
├── List decisions made in this version
├── List pending decisions
├── List options for next iteration
└── Ask user direction
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ VERSION 55 DELIVERED: starry_night_v55.scad                 │
├─────────────────────────────────────────────────────────────┤
│ COMPONENT SURVIVAL CHECK: 28/28 verified                    │
│   ✓ All mechanisms present                                  │
│   + NEW: moon_phase_cam                                     │
│   + NEW: horizon_parallax                                   │
├─────────────────────────────────────────────────────────────┤
│ MECHANISM LAYOUT (Top View):                                │
│                                                             │
│      ┌─────────────────────────────────┐                    │
│      │      STARRY NIGHT FRAME         │                    │
│      │   ┌───┐  ⟳                      │                    │
│      │   │sun│────○ planet array       │                    │
│      │   └─┬─┘    │                    │                    │
│      │     │      ○──wave linkage      │                    │
│      │   ┌─┴─┐        │                │                    │
│      │   │ M │←motor  ○──stars         │                    │
│      │   └───┘                         │                    │
│      └─────────────────────────────────┘                    │
├─────────────────────────────────────────────────────────────┤
│ TEST IT NOW:                                                │
│                                                             │
│   1. Open: starry_night_v55.scad in OpenSCAD                │
│   2. Preview: Press F5                                      │
│   3. Animate: View → Animate (FPS: 30, Steps: 360)          │
│                                                             │
│   CHECK THESE POSITIONS:                                    │
│   [ ] t=0.00: Sun at top, waves centered                    │
│   [ ] t=0.25: Sun at right, waves cresting                  │
│   [ ] t=0.50: Sun at bottom, waves centered                 │
│   [ ] t=0.75: Sun at left, waves troughing                  │
├─────────────────────────────────────────────────────────────┤
│ NEXT OPTIONS:                                               │
│   [A] Add cypress tree articulation                         │
│   [B] Refine wave motion curves                             │
│   [C] Prepare for 3D printing (export STLs)                 │
│                                                             │
│ What would you like to do next?                             │
└─────────────────────────────────────────────────────────────┘
```

---

# PRIORITY LEVEL 5: ENHANCEMENT

These hooks improve output quality but are optional.

---

## Hook 13: failure-pattern-detector

### Purpose
Detect patterns that match known failure modes from historical engineering lessons. References FAILURE_PATTERNS.md.

### Priority Level
**ENHANCEMENT** - Warns but does not block

### Trigger Conditions

```yaml
trigger:
  type: "phrase_pattern"
  patterns:
    tesla_trap:
      phrases: ["should work in theory", "theoretically", "in principle"]
      warning: "TESLA TRAP - Theory vs material limits"

    scale_danger:
      phrases: ["just scale it up", "make it bigger", "increase the size"]
      warning: "SQUARE-CUBE LAW - Scaling non-linear"

    da_vinci_dream:
      phrases: ["optimize", "more efficient", "lighter"]
      warning: "DA VINCI DREAM - Check power budget first"

    galileo_bias:
      phrases: ["it worked once", "it worked before", "same as last time"]
      warning: "GALILEO BIAS - Verify conditions match"

    v53_disconnect:
      phrases: ["animate", "sin($t)", "motion"]
      check: "Verify physical connection before animation"
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ FAILURE PATTERN WARNING                                     │
├─────────────────────────────────────────────────────────────┤
│ DETECTED PATTERN: "Scale it up" request                     │
│                                                             │
│ WARNING: SQUARE-CUBE LAW                                    │
│                                                             │
│ When you double size:                                       │
│   • Area (strength) increases 4×                            │
│   • Volume (weight) increases 8×                            │
│   • Result: Relative strength HALVES                        │
│                                                             │
│ HISTORICAL PRECEDENT:                                       │
│   Many mechanisms that work at small scale fail at          │
│   larger scale due to weight/strength ratio changes.        │
│                                                             │
│ BEFORE SCALING:                                             │
│   [ ] Verify motor torque sufficient for new weight         │
│   [ ] Check shaft diameters for increased loads             │
│   [ ] Recalculate bearing sizes                             │
│   [ ] Consider gear ratio changes                           │
│                                                             │
│ Reference: docs/FAILURE_PATTERNS.md - Square-Cube Law       │
├─────────────────────────────────────────────────────────────┤
│ Proceed with scaling? (acknowledge to continue)             │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 14: quality-assessment

### Purpose
Evaluate mechanism against Perceived Quality standards from Compendium Domain 14.

### Priority Level
**ENHANCEMENT** - Runs on request for final versions

### Trigger Conditions

```yaml
trigger:
  type: "phrase_detection"
  patterns:
    - /\b(quality|professional|polish|refine|final)\b/i
    - /\b(looks (cheap|professional|good)|finish)\b/i
```

### Quality Assessment Criteria

```
PERCEIVED QUALITY ASSESSMENT

MOTION QUALITY:
[ ] Smooth motion (no jerk, stutter, or hunting)
[ ] Consistent speed (no acceleration artifacts)
[ ] Clean start/stop (no coast or bounce)
[ ] Backlash: intentional or problematic?

VISUAL QUALITY:
[ ] Edge treatments (chamfers, radii)
[ ] Surface consistency (no visible layers in motion)
[ ] Fastener visibility (hidden or decorative)
[ ] Color/material coordination

CRAFTSMANSHIP SIGNALS:
[ ] Exposed mechanism: reveals quality or hides cheapness?
[ ] Hand-made vs machine: appropriate aesthetic
[ ] Finish level matches intended context

SOUND QUALITY:
[ ] Gear whine: acceptable level?
[ ] Click/clunk: intentional or undesired?
[ ] Overall acoustic character
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ QUALITY ASSESSMENT                                          │
├─────────────────────────────────────────────────────────────┤
│ OVERALL GRADE: B+ (Good, near professional)                 │
│                                                             │
│ MOTION QUALITY: A                                           │
│   ✓ Smooth sine-wave motion                                 │
│   ✓ Consistent gear mesh                                    │
│   ✓ No visible backlash                                     │
│                                                             │
│ VISUAL QUALITY: B                                           │
│   ✓ Clean edge treatments                                   │
│   ! Some layer lines visible on sun gear                    │
│   ✓ Fasteners hidden behind decorative panels               │
│                                                             │
│ CRAFTSMANSHIP: B+                                           │
│   ✓ Exposed mechanism adds interest                         │
│   ! Consider brass bushings for premium look                │
│   ✓ Color palette cohesive                                  │
│                                                             │
│ RECOMMENDATIONS FOR A GRADE:                                │
│   1. Sand/paint sun gear for smooth appearance              │
│   2. Add brass bushing sleeves (visible quality)            │
│   3. Consider clear acrylic cover for dust protection       │
└─────────────────────────────────────────────────────────────┘
```

---

## Hook 15: compendium-reference

### Purpose
Automatically reference relevant sections of KINETIC_SCULPTURE_COMPENDIUM.md when applicable to current task.

### Priority Level
**ENHANCEMENT** - Provides context and expertise

### Trigger Conditions

```yaml
trigger:
  type: "topic_detection"
  topics:
    gears: ["gear", "mesh", "teeth", "module", "pitch"]
    linkages: ["linkage", "four-bar", "coupler", "crank", "rocker"]
    cams: ["cam", "follower", "profile", "dwell"]
    motion: ["motion", "animate", "movement", "timing"]
    materials: ["material", "print", "filament", "brass", "bearing"]
    assembly: ["assemble", "fit", "clearance", "tolerance"]
    longevity: ["wear", "maintenance", "lifespan", "durability"]
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ COMPENDIUM REFERENCE                                        │
├─────────────────────────────────────────────────────────────┤
│ TOPIC: Four-Bar Linkage Design                              │
│                                                             │
│ KEY FORMULAS (QRC-2):                                       │
│   Grashof: S + L ≤ P + Q                                    │
│   Transmission angle: keep > 40° for good power transfer    │
│                                                             │
│ RULES OF THUMB:                                             │
│   • Coupler length affects output motion shape              │
│   • Shorter input crank = smaller output range              │
│   • Ground link position determines mechanism type          │
│                                                             │
│ COMMON MISTAKES:                                            │
│   • Animating without verifying physical connection         │
│   • Ignoring dead points in motion range                    │
│   • Undersized pivot pins for torque                        │
│                                                             │
│ REFERENCE: docs/KINETIC_SCULPTURE_COMPENDIUM.md             │
│   Section: Domain 2 - Physics & Engineering                 │
│   Quick Ref: QRC-2 Linkage Essentials                       │
└─────────────────────────────────────────────────────────────┘
```

---

# REFERENCE

## Priority Execution Order

```
HOOK EXECUTION SEQUENCE:

USER INPUT RECEIVED
        │
        ▼
┌─────────────────────────────────┐
│ PRIORITY 1: CRITICAL            │
│   1. pre-code-generation        │ ─── BLOCKS until passed
│   2. physical-linkage-check     │ ─── BLOCKS until passed
│   3. polymath-pre-design-check  │ ─── BLOCKS until passed
└─────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────┐
│ PRIORITY 2: PRESERVATION        │
│   4. lock-in-detector           │ ─── WARNS, can block
│   5. component-survival-check   │ ─── ALERTS on failure
│   6. version-backup             │ ─── AUTO-CREATES backup
└─────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────┐
│ PRIORITY 3: VERIFICATION        │
│   7. physical-reality-check     │ ─── WARNS of issues
│   8. animation-validation       │ ─── BLOCKS fake animation
│   9. longevity-check            │ ─── RECOMMENDS improvements
└─────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────┐
│ PRIORITY 4: USER EXPERIENCE     │
│   10. user-frustration-detector │ ─── RESPONDS to signals
│   11. complexity-warning        │ ─── SUGGESTS incremental
│   12. post-version-delivery     │ ─── PRESENTS next steps
└─────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────┐
│ PRIORITY 5: ENHANCEMENT         │
│   13. failure-pattern-detector  │ ─── WARNS of known patterns
│   14. quality-assessment        │ ─── GRADES quality
│   15. compendium-reference      │ ─── PROVIDES context
└─────────────────────────────────┘
        │
        ▼
    CODE OUTPUT
```

## Hook Interaction Matrix

| Hook | Triggers | Can Block | Calls Hook |
|------|----------|-----------|------------|
| 1. pre-code-generation | Before code | YES | 2, 3 |
| 2. physical-linkage-check | Linkage code | YES | 8 |
| 3. polymath-pre-design-check | New mechanism | YES | 7 |
| 4. lock-in-detector | Lock phrases | YES | 6 |
| 5. component-survival-check | Post-delivery | NO | - |
| 6. version-backup | Large change | NO | - |
| 7. physical-reality-check | Feasibility | NO | 9 |
| 8. animation-validation | Animation | YES | 2 |
| 9. longevity-check | Final version | NO | - |
| 10. user-frustration-detector | Frustration | NO | 5 |
| 11. complexity-warning | Large scope | NO | 6 |
| 12. post-version-delivery | After delivery | NO | 5 |
| 13. failure-pattern-detector | Patterns | NO | 15 |
| 14. quality-assessment | Quality req | NO | - |
| 15. compendium-reference | Topic match | NO | - |

## Regex Pattern Reference

```javascript
// Hook 1: pre-code-generation
// Triggered by code generation intent (detected by agent)

// Hook 2: physical-linkage-check
/\b(coupler|four_bar|linkage|crank|slider|rocker)\b.*\b(sin|cos)\s*\(/i

// Hook 3: polymath-pre-design-check
/\b(add|create|design|make|build|implement)\s+(a\s+)?(new\s+)?(mechanism|linkage|gear|cam|motion)\b/i

// Hook 4: lock-in-detector
/\b(lock (this|it)|final(ize)?|freeze|don't (touch|change|modify)|approved|ship it)\b/i

// Hook 5: component-survival-check
// Triggered post-delivery (automatic)

// Hook 6: version-backup
// Triggered by scope analysis (automatic)

// Hook 7: physical-reality-check
/\b(will (this|it) (work|print|move|fit)|is (this|it) (printable|possible|feasible))\b/i

// Hook 8: animation-validation
/\b(sin|cos)\s*\(\s*(\$t|master_phase|phase)/

// Hook 9: longevity-check
/\b(final|production|long.?term|durable|will (this|it) last|lifespan)\b/i

// Hook 10: user-frustration-detector
/\b(ugh|argh|damn|frustrated|going in circles|where is my|this is broken)\b/i

// Hook 11: complexity-warning
// Triggered by scope analysis (>3 modules or >50 lines)

// Hook 12: post-version-delivery
// Triggered after version delivery (automatic)

// Hook 13: failure-pattern-detector
/\b(should work in theory|just scale it up|optimize|it worked before)\b/i

// Hook 14: quality-assessment
/\b(quality|professional|polish|refine|final|looks (cheap|professional))\b/i

// Hook 15: compendium-reference
// Triggered by topic keywords (automatic)
```

---

## Implementation Reference

### Claude Code Integration

All hooks are defined in CLAUDE.md in the workspace root. The hooks section specifies:

1. **Trigger Patterns** - Regex or event patterns that activate the hook
2. **Action Sequence** - Steps the agent must execute
3. **Output Format** - ASCII table format for user display
4. **Blocking Behavior** - Whether the hook can prevent code output

### Adding Custom Hooks

To add a new hook:

1. Define trigger conditions (regex patterns or events)
2. Specify action sequence (step-by-step)
3. Create output format template
4. Determine priority level
5. Add to CLAUDE.md hooks section
6. Document in this file

### Hook State Persistence

Hooks maintain state across the conversation:
- Locked items registry
- Component survival inventory
- Version history
- Failure pattern log

---

*Hooks Implementation v2.0 - Comprehensive Quality Assurance for Kinetic Sculpture Design*
*Integration with: POLYMATH_LENS.md, KINETIC_SCULPTURE_COMPENDIUM.md, FAILURE_PATTERNS.md*
