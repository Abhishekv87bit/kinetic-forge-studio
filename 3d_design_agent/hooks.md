# 3D Mechanical Design Agent - Hooks Implementation

## Overview

This document defines automated triggers (Hooks) for the 3D Mechanical Design Agent specialized in OpenSCAD, kinetic art, and mechanical assemblies. These hooks ensure safe, predictable code generation and maintain design integrity throughout iterative development.

---

## Table of Contents

1. [Hook 1: pre-code-generation](#hook-1-pre-code-generation)
2. [Hook 2: user-frustration-detector](#hook-2-user-frustration-detector)
3. [Hook 3: post-version-delivery](#hook-3-post-version-delivery)
4. [Hook 4: lock-in-detector](#hook-4-lock-in-detector)
5. [Hook 5: complexity-warning](#hook-5-complexity-warning)
6. [Hook 6: physical-reality-check](#hook-6-physical-reality-check)
7. [Implementation Reference](#implementation-reference)

---

## Hook 1: pre-code-generation

### Purpose
Prevent unintended changes by requiring explicit declaration and confirmation before ANY OpenSCAD code generation.

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
│ ⚠️  AWAITING CONFIRMATION                                    │
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
│ TARGET FILE: kinetic_sculpture.scad                         │
│ LINES AFFECTED: 45-52                                       │
├─────────────────────────────────────────────────────────────┤
│ WILL CHANGE:                                                │
│   • main_gear module: radius 30 → 36                        │
│   • gear_teeth: 24 → 29 (to maintain pitch)                 │
│   • main_gear_position: y-offset +6 for clearance           │
├─────────────────────────────────────────────────────────────┤
│ WILL NOT CHANGE:                                            │
│   • secondary_gear - remains at radius=15, teeth=12         │
│   • motor_mount - position unchanged                        │
│   • frame_dimensions - 200x150x100 (LOCKED)                 │
│   • cam_mechanism - untouched                               │
├─────────────────────────────────────────────────────────────┤
│ MECHANISMS AFFECTED:                                        │
│   [1] Main drive train - gear ratio changes 2:1 → 2.4:1     │
│   [2] Output shaft - RPM decreases by 20%                   │
├─────────────────────────────────────────────────────────────┤
│ BREAKAGE CHECK:                                             │
│   ✓ Gear mesh verified (module 2.0 maintained)              │
│   ⚠️ Secondary gear needs repositioning for mesh            │
│   ✓ No locked item violations                               │
│   ✓ Fits within frame (36 < 50 max)                         │
├─────────────────────────────────────────────────────────────┤
│ ⚠️  AWAITING CONFIRMATION                                    │
│ Note: Secondary gear will need Y+6 offset adjustment        │
│ Type "proceed" to generate code                             │
└─────────────────────────────────────────────────────────────┘
```

**User:** "proceed"

**Agent:** [Now generates the code]

### Claude Code Implementation

```javascript
// Hook Definition for CLAUDE.md or system prompt
const preCodeGenerationHook = {
  name: "pre-code-generation",
  trigger: {
    event: "before_openscad_output",
    fileTypes: [".scad"],
    actions: ["create", "modify", "delete"]
  },

  execute: async function(context) {
    // Step 1: Gather scope information
    const scope = {
      targetFile: context.targetFile,
      lineRange: context.getAffectedLines(),
      modules: context.getAffectedModules()
    };

    // Step 2-3: Declare changes and non-changes
    const changeDeclaration = {
      willChange: context.getProposedChanges(),
      willNotChange: context.getUnaffectedComponents(),
      lockedItems: context.getLockedItems()
    };

    // Step 4: Impact analysis
    const impact = {
      mechanisms: context.traceAffectedMechanisms(),
      dependencies: context.traceDependencies()
    };

    // Step 5: Breakage verification
    const breakageCheck = {
      gearMesh: context.verifyGearMesh(),
      linkageGeometry: context.verifyLinkages(),
      lockedViolations: context.checkLockedViolations(),
      assemblyOrder: context.verifyAssemblyOrder()
    };

    // Step 6: Format and present, await confirmation
    const output = formatPreCodeOutput(scope, changeDeclaration, impact, breakageCheck);
    await context.presentToUser(output);

    const confirmation = await context.awaitUserConfirmation([
      "proceed", "yes", "approved", "go ahead", "do it"
    ]);

    if (!confirmation) {
      return { proceed: false, reason: "User did not confirm" };
    }

    return { proceed: true };
  }
};
```

---

## Hook 2: user-frustration-detector

### Purpose
Detect user frustration signals and respond with appropriate corrective actions to prevent wasted effort and restore progress.

### Trigger Conditions

```yaml
trigger:
  type: "phrase_detection"
  patterns:
    circles:
      phrases: ["going in circles", "we keep coming back", "same issue again", "this again"]
      action: "diagnose_and_rollback"

    lost_component:
      phrases: ["where is my", "where did my", "what happened to", "I lost my", "it's gone"]
      action: "survival_checklist"

    think_hard:
      phrases: ["think hard", "think carefully", "really think", "slow down"]
      action: "extended_analysis"

    verify_works:
      phrases: ["verify this works", "will this actually", "prove it works", "show me it works"]
      action: "feasibility_check"

    broken:
      phrases: ["this is broken", "you broke", "it's broken", "nothing works"]
      action: "emergency_audit"
```

### Phrase-Action Matrix

| User Says | Detection Pattern | Claude Action |
|-----------|-------------------|---------------|
| "going in circles" | `/going in circles\|we keep coming back\|same issue again/i` | STOP → Diagnose pattern → Return to last good version |
| "where is my [X]?" | `/where (is\|did\|are) my\|what happened to\|I lost/i` | Run survival checklist → Identify when X was lost |
| "think hard" | `/think (hard\|carefully)\|really think\|slow down/i` | Slow down → Extended analysis → Question assumptions |
| "verify this works" | `/verify.*works\|will this actually\|prove it\|show me it works/i` | Full physical feasibility check with diagrams |
| "this is broken" | `/broken\|you broke\|nothing works\|completely wrong/i` | Stop all changes → Audit recent modifications |

### Step-by-Step Action Sequences

#### Action: diagnose_and_rollback

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

#### Action: survival_checklist

```
STEP 1: Identify Missing Component
├── Parse [X] from user statement
├── Search current codebase for [X]
└── Search version history for [X]

STEP 2: Run Survival Checklist
├── Check: Is [X] in current file?
├── Check: Is [X] commented out?
├── Check: Was [X] renamed?
├── Check: Was [X] moved to different file?
├── Check: Was [X] accidentally deleted?
└── Find: Last version containing [X]

STEP 3: Identify Loss Point
├── Compare versions to find when [X] disappeared
├── Identify which change removed it
└── Document: "[X] was removed in version [N] when [action]"

STEP 4: Propose Recovery
├── Show the lost code
├── Propose reinsertion point
└── Await user approval
```

#### Action: extended_analysis

```
STEP 1: Acknowledge Request
├── Signal: "Entering extended analysis mode"
└── Slow processing pace

STEP 2: Question Assumptions
├── List all current assumptions
├── Challenge each one
├── Identify any that may be wrong
└── Document uncertain areas

STEP 3: Deep Analysis
├── Re-examine the problem from first principles
├── Consider alternative approaches
├── Check for overlooked constraints
├── Verify physical/mathematical validity
└── Take 3x normal analysis time

STEP 4: Present Findings
├── Show revised understanding
├── Highlight corrected assumptions
├── Present recommendation with confidence level
└── Ask clarifying questions if uncertainty remains
```

#### Action: feasibility_check

```
STEP 1: Physical Fit Verification
├── Verify all parts fit in specified volume
├── Check: max_dimension < enclosure_dimension
├── Generate bounding box diagram
└── Flag any violations

STEP 2: Collision Analysis
├── Trace full range of motion
├── Check for part-to-part interference
├── Generate motion path diagram
└── Identify collision points if any

STEP 3: Power Path Trace
├── Start from motor/input
├── Trace through each transmission element
├── Verify each connection
├── End at output/effect
└── Generate power flow diagram

STEP 4: Geometry Validation
├── Verify gear mesh (center distance, module, teeth)
├── Verify linkage geometry (lengths, pivot points)
├── Check cam profiles
└── Validate all calculations

STEP 5: Present Feasibility Report
├── Show all diagrams
├── List verified items with ✓
├── List concerns with ⚠️
├── List failures with ✗
└── Overall assessment: FEASIBLE / NEEDS WORK / NOT FEASIBLE
```

#### Action: emergency_audit

```
STEP 1: FULL STOP
├── Cease all modifications immediately
├── Acknowledge: "Stopping all changes"
└── Enter audit mode

STEP 2: Audit Recent Modifications
├── List all changes in last 5 versions
├── For each change, note:
│   ├── What was modified
│   ├── Why it was modified
│   └── What it affected
└── Create modification timeline

STEP 3: Identify Breaking Change
├── Compare working version to broken version
├── Isolate the specific change that caused breakage
└── Document: "Breakage caused by [change] in version [N]"

STEP 4: Present Audit Results
├── Show timeline of changes
├── Highlight breaking change
├── Propose rollback to pre-break state
└── Await user direction before ANY further changes
```

### Output Format

#### For "going in circles":
```
┌─────────────────────────────────────────────────────────────┐
│ 🔄 CYCLE DETECTED - DIAGNOSTIC MODE                         │
├─────────────────────────────────────────────────────────────┤
│ PATTERN IDENTIFIED:                                         │
│   We have attempted [X] → [Y] → [X] repeatedly              │
│   Root cause: [description]                                 │
├─────────────────────────────────────────────────────────────┤
│ LAST KNOWN GOOD STATE:                                      │
│   Version: [N] ([timestamp/description])                    │
│   Status: [what was working]                                │
├─────────────────────────────────────────────────────────────┤
│ RECOMMENDED ACTION:                                         │
│   1. Return to version [N]                                  │
│   2. [Alternative approach]                                 │
│   3. [What to do differently]                               │
├─────────────────────────────────────────────────────────────┤
│ Awaiting your direction...                                  │
└─────────────────────────────────────────────────────────────┘
```

#### For "where is my [X]?":
```
┌─────────────────────────────────────────────────────────────┐
│ 🔍 COMPONENT SURVIVAL CHECK: [X]                            │
├─────────────────────────────────────────────────────────────┤
│ SEARCH RESULTS:                                             │
│   Current file:     [✓ Found / ✗ Not found]                 │
│   Commented out:    [✓ Yes / ✗ No]                          │
│   Renamed to:       [new_name / N/A]                        │
│   Moved to:         [file:line / N/A]                       │
├─────────────────────────────────────────────────────────────┤
│ LOSS POINT IDENTIFIED:                                      │
│   Last seen: Version [N]                                    │
│   Removed by: [change description]                          │
│   When: [during what modification]                          │
├─────────────────────────────────────────────────────────────┤
│ RECOVERY:                                                   │
│   [Original code block]                                     │
│   Reinsertion point: Line [N]                               │
├─────────────────────────────────────────────────────────────┤
│ Restore this component? (yes/no)                            │
└─────────────────────────────────────────────────────────────┘
```

#### For "think hard":
```
┌─────────────────────────────────────────────────────────────┐
│ 🧠 EXTENDED ANALYSIS MODE                                   │
├─────────────────────────────────────────────────────────────┤
│ ASSUMPTIONS UNDER REVIEW:                                   │
│   1. [assumption] - [valid/questionable/invalid]            │
│   2. [assumption] - [valid/questionable/invalid]            │
│   3. [assumption] - [valid/questionable/invalid]            │
├─────────────────────────────────────────────────────────────┤
│ DEEP ANALYSIS:                                              │
│   [Detailed reasoning...]                                   │
│   [First principles examination...]                         │
│   [Alternative considerations...]                           │
├─────────────────────────────────────────────────────────────┤
│ REVISED UNDERSTANDING:                                      │
│   [Updated conclusions]                                     │
│   Confidence: [HIGH/MEDIUM/LOW]                             │
├─────────────────────────────────────────────────────────────┤
│ CLARIFYING QUESTIONS:                                       │
│   • [Question if uncertainty exists]                        │
└─────────────────────────────────────────────────────────────┘
```

#### For "verify this works":
```
┌─────────────────────────────────────────────────────────────┐
│ ⚙️  PHYSICAL FEASIBILITY CHECK                               │
├─────────────────────────────────────────────────────────────┤
│ DIMENSIONAL FIT:                                            │
│   Enclosure: [W] x [H] x [D] mm                             │
│   Mechanism: [W] x [H] x [D] mm                             │
│   Status: [✓ FITS / ✗ EXCEEDS by Xmm]                       │
│                                                             │
│   Top View:          Side View:                             │
│   ┌──────────┐       ┌──────────┐                           │
│   │ ┌────┐   │       │   ○──○   │                           │
│   │ │gear│○──│       │   │      │                           │
│   │ └────┘   │       │  ═╧═     │                           │
│   └──────────┘       └──────────┘                           │
├─────────────────────────────────────────────────────────────┤
│ COLLISION CHECK:                                            │
│   Motion range: [description]                               │
│   Interference: [✓ CLEAR / ✗ COLLISION at position X]       │
├─────────────────────────────────────────────────────────────┤
│ POWER PATH:                                                 │
│   Motor → [Gear A] → [Gear B] → [Linkage] → [Output]        │
│     ↓         ↓          ↓          ↓           ↓           │
│   [rpm]    [ratio]    [ratio]    [travel]    [effect]       │
│   Status: [✓ COMPLETE / ✗ BREAK at stage X]                 │
├─────────────────────────────────────────────────────────────┤
│ GEOMETRY VALIDATION:                                        │
│   Gear mesh: [✓ Valid / ✗ Invalid - reason]                 │
│   Linkages:  [✓ Valid / ✗ Invalid - reason]                 │
│   Cams:      [✓ Valid / ✗ Invalid - reason]                 │
├─────────────────────────────────────────────────────────────┤
│ VERDICT: [✓ FEASIBLE / ⚠️ NEEDS WORK / ✗ NOT FEASIBLE]       │
└─────────────────────────────────────────────────────────────┘
```

#### For "this is broken":
```
┌─────────────────────────────────────────────────────────────┐
│ 🛑 EMERGENCY AUDIT - ALL CHANGES STOPPED                    │
├─────────────────────────────────────────────────────────────┤
│ MODIFICATION TIMELINE:                                      │
│   v[N-4]: [change] - [status: OK]                           │
│   v[N-3]: [change] - [status: OK]                           │
│   v[N-2]: [change] - [status: OK]                           │
│   v[N-1]: [change] - [status: ⚠️ SUSPECT]                    │
│   v[N]:   [change] - [status: ✗ BREAKING]                   │
├─────────────────────────────────────────────────────────────┤
│ BREAKING CHANGE IDENTIFIED:                                 │
│   Version: [N]                                              │
│   Change: [description]                                     │
│   Effect: [what it broke]                                   │
├─────────────────────────────────────────────────────────────┤
│ RECOMMENDED ROLLBACK:                                       │
│   Return to: Version [N-1] or [N-2]                         │
│   This restores: [what will be restored]                    │
│   This loses: [what will be lost]                           │
├─────────────────────────────────────────────────────────────┤
│ NO FURTHER CHANGES until you direct me.                     │
│ Options: "rollback to v[N]" / "show me v[N]" / "explain"    │
└─────────────────────────────────────────────────────────────┘
```

### Example Interaction

**User:** "where is my cam mechanism? It was there before!"

**Agent Response:**
```
┌─────────────────────────────────────────────────────────────┐
│ 🔍 COMPONENT SURVIVAL CHECK: cam mechanism                  │
├─────────────────────────────────────────────────────────────┤
│ SEARCH RESULTS:                                             │
│   Current file:     ✗ Not found                             │
│   Commented out:    ✗ No                                    │
│   Renamed to:       N/A                                     │
│   Moved to:         N/A                                     │
├─────────────────────────────────────────────────────────────┤
│ LOSS POINT IDENTIFIED:                                      │
│   Last seen: Version 7 (kinetic_sculpture_v7.scad)          │
│   Removed by: Refactoring gear train in Version 8           │
│   When: I reorganized the drive mechanism and accidentally  │
│         deleted the cam_follower module and cam_profile     │
├─────────────────────────────────────────────────────────────┤
│ RECOVERY - Original code from v7:                           │
│                                                             │
│   module cam_profile(angle) {                               │
│       r = 15 + 5*sin(angle*3);                              │
│       rotate([0,0,angle])                                   │
│           translate([r,0,0])                                │
│               cylinder(h=5, r=2);                           │
│   }                                                         │
│                                                             │
│   module cam_follower() {                                   │
│       translate([0,20,10])                                  │
│           rotate([90,0,0])                                  │
│               cylinder(h=30, r=3);                          │
│   }                                                         │
│                                                             │
│   Reinsertion point: Line 145 (after gear_train module)     │
├─────────────────────────────────────────────────────────────┤
│ Restore this component? (yes/no)                            │
└─────────────────────────────────────────────────────────────┘
```

### Claude Code Implementation

```javascript
const userFrustrationHook = {
  name: "user-frustration-detector",
  trigger: {
    type: "message_pattern",
    patterns: {
      circles: {
        regex: /going in circles|we keep coming back|same issue again|this again|we've tried this/i,
        action: "diagnose_and_rollback"
      },
      lost_component: {
        regex: /where (is|did|are) my|what happened to|I lost my|it's gone|where's the/i,
        action: "survival_checklist"
      },
      think_hard: {
        regex: /think (hard|carefully)|really think|slow down|take your time/i,
        action: "extended_analysis"
      },
      verify_works: {
        regex: /verify.*works|will this actually|prove it|show me it works|is this possible/i,
        action: "feasibility_check"
      },
      broken: {
        regex: /this is broken|you broke|it's broken|nothing works|completely wrong/i,
        action: "emergency_audit"
      }
    }
  },

  execute: async function(context, matchedPattern) {
    switch(matchedPattern.action) {
      case "diagnose_and_rollback":
        await this.diagnoseAndRollback(context);
        break;
      case "survival_checklist":
        const component = this.extractComponentName(context.userMessage);
        await this.runSurvivalChecklist(context, component);
        break;
      case "extended_analysis":
        await this.performExtendedAnalysis(context);
        break;
      case "feasibility_check":
        await this.performFeasibilityCheck(context);
        break;
      case "emergency_audit":
        await this.performEmergencyAudit(context);
        break;
    }
  },

  diagnoseAndRollback: async function(context) {
    // Stop current work
    context.haltCurrentTask();

    // Analyze conversation history for patterns
    const history = context.getConversationHistory(10);
    const pattern = this.detectCyclePattern(history);

    // Find last good state
    const lastGood = context.findLastConfirmedWorkingVersion();

    // Present recovery options
    await context.presentDiagnostic({
      pattern: pattern,
      lastGoodVersion: lastGood,
      recommendedAction: this.generateRecoveryPlan(pattern, lastGood)
    });
  },

  runSurvivalChecklist: async function(context, componentName) {
    const checks = {
      inCurrentFile: context.searchCurrentFile(componentName),
      commentedOut: context.searchCommentedCode(componentName),
      renamed: context.searchRenamedComponents(componentName),
      moved: context.searchAllFiles(componentName),
      versionHistory: context.searchVersionHistory(componentName)
    };

    const lossPoint = this.identifyLossPoint(checks);
    const recovery = this.generateRecoveryCode(lossPoint);

    await context.presentSurvivalReport(checks, lossPoint, recovery);
  }
};
```

---

## Hook 3: post-version-delivery

### Purpose
Ensure quality and user understanding after every version delivery by automatically running verification checks and providing clear testing instructions.

### Trigger Conditions

```yaml
trigger:
  event: "after_version_delivery"
  conditions:
    - file_delivered: true
    - file_extension: [".scad"]
    - version_number_incremented: true
```

**Detection:**
- Agent has just output a new version of an OpenSCAD file
- File has been saved/delivered to user
- Version number has changed (v1 → v2, etc.)

### Step-by-Step Action Sequence

```
STEP 1: Run Component Survival Checklist
├── Parse delivered file
├── List all expected components
├── Verify each component exists
├── Check no components were lost
└── Generate survival report

STEP 2: Generate ASCII Mechanism Layout
├── Identify all mechanisms in file
├── Create top-down ASCII diagram
├── Show spatial relationships
├── Label key components
└── Show motion directions

STEP 3: Generate TEST IT NOW Instructions
├── List specific OpenSCAD commands to run
├── Provide preview angles to check
├── List animation parameters if applicable
├── Specify what to look for
└── Include troubleshooting tips

STEP 4: Present Decision Points
├── List decisions made in this version
├── List pending decisions
├── List options for next iteration
└── Ask user which direction to proceed
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ ✅ VERSION [N] DELIVERED: [filename.scad]                    │
├─────────────────────────────────────────────────────────────┤
│ COMPONENT SURVIVAL CHECK:                                   │
│   ✓ main_gear (teeth=24, r=30)                              │
│   ✓ secondary_gear (teeth=12, r=15)                         │
│   ✓ cam_mechanism                                           │
│   ✓ linkage_arm (length=45)                                 │
│   ✓ motor_mount                                             │
│   ✓ frame (LOCKED: 200x150x100)                             │
│   ─────────────────────────────                             │
│   All [N] components verified present                       │
├─────────────────────────────────────────────────────────────┤
│ MECHANISM LAYOUT (Top View):                                │
│                                                             │
│      ┌─────────────────────────────────┐                    │
│      │            FRAME                │                    │
│      │   ┌───┐                         │                    │
│      │   │ M │←motor    ┌────┐         │                    │
│      │   └─┬─┘          │cam │         │                    │
│      │     │            └──┬─┘         │                    │
│      │   ┌─┴─┐  mesh    ┌──┴──┐        │                    │
│      │   │G1 │○────────○│ G2  │        │                    │
│      │   └───┘          └──┬──┘        │                    │
│      │                     │linkage    │                    │
│      │                   ┌─┴─┐         │                    │
│      │                   │out│←output  │                    │
│      │                   └───┘         │                    │
│      └─────────────────────────────────┘                    │
│                                                             │
│   Legend: M=motor, G1=main gear, G2=secondary, ○=pivot      │
│   Motion: Motor(CW) → G1(CW) → G2(CCW) → Output(oscillate)  │
├─────────────────────────────────────────────────────────────┤
│ 🧪 TEST IT NOW:                                              │
│                                                             │
│   1. Open in OpenSCAD: File → Open → [filename.scad]        │
│                                                             │
│   2. Static Preview:                                        │
│      • Press F5 (Preview)                                   │
│      • Rotate view: drag with middle mouse                  │
│      • Check: All gears visible? Teeth meshing?             │
│                                                             │
│   3. Animation Test:                                        │
│      • View → Animate                                       │
│      • Set FPS: 30, Steps: 360                              │
│      • Watch for: smooth motion, no clipping                │
│                                                             │
│   4. Specific Checks:                                       │
│      • [ ] Main gear rotates without collision              │
│      • [ ] Cam follower follows cam profile                 │
│      • [ ] Output arm reaches full range                    │
│      • [ ] No parts exit frame boundaries                   │
│                                                             │
│   5. If Problems:                                           │
│      • Parts overlapping? → Check clearance values          │
│      • Jerky motion? → Check animation variable $t          │
│      • Missing parts? → Check module calls                  │
├─────────────────────────────────────────────────────────────┤
│ 📋 DECISION POINTS:                                          │
│                                                             │
│   Decisions Made This Version:                              │
│     • Gear ratio set to 2:1                                 │
│     • Cam profile uses 3-lobe design                        │
│                                                             │
│   Pending Decisions:                                        │
│     • Output arm attachment method?                         │
│     • Add decorative elements?                              │
│                                                             │
│   Next Iteration Options:                                   │
│     [A] Refine cam profile for smoother motion              │
│     [B] Add second output mechanism                         │
│     [C] Optimize for 3D printing                            │
│                                                             │
│ What would you like to do next?                             │
└─────────────────────────────────────────────────────────────┘
```

### Example Interaction

**Agent delivers v5 of kinetic_sculpture.scad**

**Automatic Post-Delivery Output:**
```
┌─────────────────────────────────────────────────────────────┐
│ ✅ VERSION 5 DELIVERED: kinetic_sculpture_v5.scad            │
├─────────────────────────────────────────────────────────────┤
│ COMPONENT SURVIVAL CHECK:                                   │
│   ✓ base_plate (100x100x5)                                  │
│   ✓ main_drive_gear (teeth=32, module=2)                    │
│   ✓ follower_gear (teeth=16, module=2)                      │
│   ✓ crank_arm (length=25)                                   │
│   ✓ connecting_rod (length=60)                              │
│   ✓ slider_block                                            │
│   ✓ guide_rails                                             │
│   ✓ motor_shaft_coupler                                     │
│   ─────────────────────────────                             │
│   All 8 components verified present                         │
├─────────────────────────────────────────────────────────────┤
│ MECHANISM LAYOUT (Side View):                               │
│                                                             │
│   Motor ═══╤═══ Main Gear (32T)                             │
│            │         │                                      │
│            │    mesh │                                      │
│            │         ▼                                      │
│            │    Follower (16T)                              │
│            │         │                                      │
│            │    crank│                                      │
│            │         ○←─ pivot                              │
│            │        /                                       │
│            │       / connecting rod                         │
│            │      /                                         │
│            │     ○←─ slider pivot                           │
│            │     │                                          │
│   ─────────┴─────┼──────────── guide rail                   │
│              ◄───┴───► slider motion                        │
│                                                             │
│   Gear ratio: 2:1 (motor:output)                            │
│   Slider stroke: 50mm                                       │
├─────────────────────────────────────────────────────────────┤
│ 🧪 TEST IT NOW:                                              │
│                                                             │
│   1. Preview: F5 in OpenSCAD                                │
│                                                             │
│   2. Animation:                                             │
│      • Enable: View → Animate                               │
│      • FPS: 24, Steps: 360                                  │
│      • Variable: $t controls rotation (0-1 = 0-360°)        │
│                                                             │
│   3. Verification Checklist:                                │
│      • [ ] Gears mesh properly (no overlap, no gap)         │
│      • [ ] Crank rotates full 360° without collision        │
│      • [ ] Connecting rod doesn't pass through parts        │
│      • [ ] Slider stays on guide rails                      │
│      • [ ] Smooth motion throughout cycle                   │
│                                                             │
│   4. View Angles to Check:                                  │
│      • Top (0,0,90): gear mesh alignment                    │
│      • Side (90,0,0): linkage clearance                     │
│      • Iso (60,0,45): overall assembly                      │
├─────────────────────────────────────────────────────────────┤
│ 📋 DECISION POINTS:                                          │
│                                                             │
│   Made This Version:                                        │
│     • Slider-crank mechanism complete                       │
│     • 2:1 gear reduction for torque                         │
│                                                             │
│   Pending:                                                  │
│     • Mounting hole pattern for motor?                      │
│     • Slider end-stops needed?                              │
│                                                             │
│   Next Options:                                             │
│     [A] Add end-stop bumpers to slider                      │
│     [B] Add decorative cover plates                         │
│     [C] Export STLs for printing                            │
│                                                             │
│ Which direction?                                            │
└─────────────────────────────────────────────────────────────┘
```

### Claude Code Implementation

```javascript
const postVersionDeliveryHook = {
  name: "post-version-delivery",
  trigger: {
    event: "after_file_delivery",
    conditions: {
      fileType: ".scad",
      isNewVersion: true
    }
  },

  execute: async function(context) {
    const deliveredFile = context.getDeliveredFile();

    // Step 1: Component Survival Checklist
    const components = this.parseComponents(deliveredFile);
    const expectedComponents = context.getExpectedComponents();
    const survivalCheck = this.verifySurvival(components, expectedComponents);

    // Step 2: Generate ASCII Layout
    const mechanisms = this.identifyMechanisms(deliveredFile);
    const asciiLayout = this.generateASCIILayout(mechanisms);

    // Step 3: Generate Test Instructions
    const testInstructions = this.generateTestInstructions(deliveredFile, mechanisms);

    // Step 4: Compile Decision Points
    const decisions = {
      made: context.getDecisionsMadeThisVersion(),
      pending: context.getPendingDecisions(),
      nextOptions: this.generateNextOptions(deliveredFile)
    };

    // Format and present
    const output = this.formatPostDeliveryReport(
      deliveredFile,
      survivalCheck,
      asciiLayout,
      testInstructions,
      decisions
    );

    await context.presentToUser(output);
  },

  generateASCIILayout: function(mechanisms) {
    // Generate appropriate ASCII diagram based on mechanism type
    const layouts = {
      gear_train: this.drawGearTrainASCII,
      linkage: this.drawLinkageASCII,
      cam_follower: this.drawCamFollowerASCII,
      slider_crank: this.drawSliderCrankASCII
    };

    let ascii = "";
    for (const mech of mechanisms) {
      if (layouts[mech.type]) {
        ascii += layouts[mech.type](mech);
      }
    }
    return ascii;
  },

  generateTestInstructions: function(file, mechanisms) {
    return {
      openCommand: `File → Open → ${file.name}`,
      previewKey: "F5",
      animationSettings: {
        fps: 24,
        steps: 360,
        variable: "$t"
      },
      checkList: this.generateChecklistForMechanisms(mechanisms),
      viewAngles: this.recommendViewAngles(mechanisms),
      troubleshooting: this.generateTroubleshootingTips(mechanisms)
    };
  }
};
```

---

## Hook 4: lock-in-detector

### Purpose
Permanently record user decisions marked as "final" or "immutable" and prevent any future modifications that would violate these locked constraints.

### Trigger Conditions

```yaml
trigger:
  type: "phrase_detection"
  patterns:
    - "let's lock this in"
    - "lock this in"
    - "mark as immutable"
    - "this is final"
    - "don't change this"
    - "never change this"
    - "this is set in stone"
    - "freeze this"
    - "this is fixed"
    - "lock [component]"
    - "finalize [component]"
```

**Regex Pattern:**
```regex
/lock(?: this)? in|mark (?:as )?immutable|(?:this is|that's) final|don't (?:ever )?change|never change|set in stone|freeze (?:this|that)|(?:this is|that's) fixed|finalize|lock (?:the )?(\w+)/i
```

### Step-by-Step Action Sequence

```
STEP 1: Identify Locked Item
├── Parse user statement for component/parameter
├── If ambiguous, ask user to clarify
├── Identify exact values to lock
└── Identify file and line numbers

STEP 2: Create Lock Record
├── Record: component name
├── Record: current value(s)
├── Record: file location
├── Record: timestamp
├── Record: user statement (verbatim)
└── Generate lock ID

STEP 3: Add to Immutable Boundaries List
├── Update master immutable list
├── Categorize lock type:
│   ├── DIMENSION (sizes, positions)
│   ├── PARAMETER (values, ratios)
│   ├── COMPONENT (entire module)
│   └── RELATIONSHIP (how parts connect)
└── Set enforcement level: HARD (error) or SOFT (warning)

STEP 4: Configure Future Warnings
├── Add pre-code-generation check for this item
├── Define violation conditions
└── Set warning/block behavior

STEP 5: Update Master Specification
├── Add lock annotation to specification doc
├── Update any design constraint lists
└── Confirm lock to user

STEP 6: Acknowledge Lock
├── Confirm what was locked
├── Show current locked value
├── Explain how lock will be enforced
└── Provide unlock instructions if needed
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ 🔒 LOCK CONFIRMED                                            │
├─────────────────────────────────────────────────────────────┤
│ LOCKED ITEM: [component/parameter name]                     │
│ LOCKED VALUE: [exact value or specification]                │
│ LOCK TYPE: [DIMENSION/PARAMETER/COMPONENT/RELATIONSHIP]     │
│ LOCATION: [file.scad], lines [X-Y]                          │
├─────────────────────────────────────────────────────────────┤
│ LOCK RECORD:                                                │
│   ID: LOCK-[timestamp]-[hash]                               │
│   User statement: "[exact user quote]"                      │
│   Enforcement: HARD (blocks changes) / SOFT (warns only)    │
├─────────────────────────────────────────────────────────────┤
│ ENFORCEMENT:                                                │
│   Any future change to [item] will:                         │
│   • Trigger pre-code-generation warning                     │
│   • Require explicit unlock command                         │
│   • Show this lock record                                   │
├─────────────────────────────────────────────────────────────┤
│ TO UNLOCK: Say "unlock [item]" or "remove lock LOCK-[id]"   │
└─────────────────────────────────────────────────────────────┘
```

### Immutable Boundaries List Format

```
┌─────────────────────────────────────────────────────────────┐
│ 📋 IMMUTABLE BOUNDARIES - [Project Name]                     │
├─────────────────────────────────────────────────────────────┤
│ ID          │ Item            │ Value       │ Type          │
├─────────────────────────────────────────────────────────────┤
│ LOCK-001    │ frame_size      │ 200x150x100 │ DIMENSION     │
│ LOCK-002    │ gear_module     │ 2.0         │ PARAMETER     │
│ LOCK-003    │ motor_position  │ (10,10,0)   │ DIMENSION     │
│ LOCK-004    │ cam_mechanism   │ [entire]    │ COMPONENT     │
│ LOCK-005    │ gear_ratio      │ 3:1         │ RELATIONSHIP  │
├─────────────────────────────────────────────────────────────┤
│ Total locks: 5                                              │
│ Last updated: [timestamp]                                   │
└─────────────────────────────────────────────────────────────┘
```

### Violation Warning Format

```
┌─────────────────────────────────────────────────────────────┐
│ ⚠️  LOCK VIOLATION DETECTED                                  │
├─────────────────────────────────────────────────────────────┤
│ Your requested change would modify:                         │
│   [parameter/component]                                     │
│                                                             │
│ This item is LOCKED:                                        │
│   Lock ID: LOCK-[id]                                        │
│   Locked value: [value]                                     │
│   Locked by: "[user's original statement]"                  │
├─────────────────────────────────────────────────────────────┤
│ OPTIONS:                                                    │
│   1. Cancel this change (default)                           │
│   2. Unlock and proceed: "unlock LOCK-[id]"                 │
│   3. Modify without touching locked item (if possible)      │
├─────────────────────────────────────────────────────────────┤
│ Awaiting your decision...                                   │
└─────────────────────────────────────────────────────────────┘
```

### Example Interaction

**User:** "The frame dimensions are final - lock this in at 200x150x100"

**Agent Response:**
```
┌─────────────────────────────────────────────────────────────┐
│ 🔒 LOCK CONFIRMED                                            │
├─────────────────────────────────────────────────────────────┤
│ LOCKED ITEM: frame_dimensions                               │
│ LOCKED VALUE: 200mm x 150mm x 100mm (W x H x D)             │
│ LOCK TYPE: DIMENSION                                        │
│ LOCATION: kinetic_sculpture.scad, lines 12-15               │
├─────────────────────────────────────────────────────────────┤
│ LOCK RECORD:                                                │
│   ID: LOCK-20240115-FRM01                                   │
│   User statement: "The frame dimensions are final -         │
│                    lock this in at 200x150x100"             │
│   Enforcement: HARD (blocks changes)                        │
├─────────────────────────────────────────────────────────────┤
│ ENFORCEMENT:                                                │
│   Any future change affecting frame size will:              │
│   • Trigger immediate warning                               │
│   • Require explicit unlock command                         │
│   • Show this lock record                                   │
│                                                             │
│ Protected code:                                             │
│   frame_width = 200;   // LOCKED                            │
│   frame_height = 150;  // LOCKED                            │
│   frame_depth = 100;   // LOCKED                            │
├─────────────────────────────────────────────────────────────┤
│ TO UNLOCK: Say "unlock frame_dimensions" or                 │
│            "remove lock LOCK-20240115-FRM01"                │
└─────────────────────────────────────────────────────────────┘
```

**Later, User:** "Make the frame 250mm wide to fit the larger gear"

**Agent Response:**
```
┌─────────────────────────────────────────────────────────────┐
│ ⚠️  LOCK VIOLATION DETECTED                                  │
├─────────────────────────────────────────────────────────────┤
│ Your requested change would modify:                         │
│   frame_width: 200 → 250                                    │
│                                                             │
│ This item is LOCKED:                                        │
│   Lock ID: LOCK-20240115-FRM01                              │
│   Locked value: 200x150x100                                 │
│   Locked by: "The frame dimensions are final -              │
│               lock this in at 200x150x100"                  │
├─────────────────────────────────────────────────────────────┤
│ OPTIONS:                                                    │
│   1. Cancel this change (keep frame at 200mm)               │
│   2. Unlock and proceed: "unlock frame_dimensions"          │
│   3. Make the gear smaller to fit in 200mm frame            │
├─────────────────────────────────────────────────────────────┤
│ Awaiting your decision...                                   │
└─────────────────────────────────────────────────────────────┘
```

### Claude Code Implementation

```javascript
const lockInDetectorHook = {
  name: "lock-in-detector",
  trigger: {
    type: "phrase_detection",
    patterns: [
      /lock(?: this)? in/i,
      /mark (?:as )?immutable/i,
      /(?:this is|that's) final/i,
      /don't (?:ever )?change/i,
      /never change/i,
      /set in stone/i,
      /freeze (?:this|that)/i,
      /(?:this is|that's) fixed/i,
      /finalize/i
    ]
  },

  // Persistent storage for locks
  locks: new Map(),

  execute: async function(context) {
    // Step 1: Identify what to lock
    const itemToLock = await this.identifyLockTarget(context);

    if (!itemToLock.confirmed) {
      return await context.askClarification(
        "What exactly should I lock? Please specify the component or parameter."
      );
    }

    // Step 2: Create lock record
    const lockRecord = {
      id: this.generateLockId(),
      item: itemToLock.name,
      value: itemToLock.currentValue,
      type: itemToLock.type, // DIMENSION, PARAMETER, COMPONENT, RELATIONSHIP
      location: itemToLock.fileLocation,
      timestamp: new Date().toISOString(),
      userStatement: context.userMessage,
      enforcement: "HARD"
    };

    // Step 3: Add to immutable boundaries
    this.locks.set(lockRecord.id, lockRecord);
    context.addToImmutableBoundaries(lockRecord);

    // Step 4: Configure violation detection
    context.registerPreCodeCheck({
      checkId: lockRecord.id,
      condition: (proposedChanges) => {
        return this.wouldViolateLock(proposedChanges, lockRecord);
      },
      action: "block_and_warn"
    });

    // Step 5: Update master specification
    await context.updateMasterSpec(lockRecord);

    // Step 6: Confirm to user
    await context.presentLockConfirmation(lockRecord);
  },

  checkForViolations: function(proposedChanges) {
    const violations = [];

    for (const [id, lock] of this.locks) {
      if (this.wouldViolateLock(proposedChanges, lock)) {
        violations.push({
          lockId: id,
          lock: lock,
          proposedChange: proposedChanges.getChangeFor(lock.item)
        });
      }
    }

    return violations;
  },

  wouldViolateLock: function(changes, lock) {
    // Check if any proposed change affects the locked item
    return changes.affectedItems.some(item =>
      item.name === lock.item ||
      item.dependencies.includes(lock.item)
    );
  },

  unlock: function(lockId) {
    if (this.locks.has(lockId)) {
      const lock = this.locks.get(lockId);
      this.locks.delete(lockId);
      return { success: true, unlockedItem: lock };
    }
    return { success: false, reason: "Lock not found" };
  }
};
```

---

## Hook 5: complexity-warning

### Purpose
Prevent scope creep and unintended large-scale changes by warning when proposed modifications exceed safe thresholds.

### Trigger Conditions

```yaml
trigger:
  type: "change_analysis"
  thresholds:
    mechanisms_affected: 3      # More than 3 mechanisms
    lines_changed: 100          # More than 100 lines
    files_affected: 2           # More than 2 files
    modules_modified: 5         # More than 5 modules
    dependencies_touched: 4     # More than 4 dependency chains
```

**Detection occurs when:**
- Agent is about to generate code
- Analysis shows thresholds exceeded
- Must trigger BEFORE code generation begins

### Step-by-Step Action Sequence

```
STEP 1: Analyze Proposed Change
├── Count mechanisms affected
├── Count lines to be changed
├── Count files affected
├── Count modules to be modified
├── Map dependency chains
└── Calculate complexity score

STEP 2: STOP if Thresholds Exceeded
├── Halt code generation
├── Flag: COMPLEXITY WARNING
└── Enter advisory mode

STEP 3: Warn User About Scope
├── Show what thresholds are exceeded
├── Explain risks of large changes
├── Show affected components list
└── Emphasize potential for breakage

STEP 4: Suggest Breakdown
├── Propose splitting into phases
├── Each phase = one focused change
├── Order phases by dependency
└── Estimate iterations needed

STEP 5: Present Sequence
├── Show Phase 1: [specific change]
├── Show Phase 2: [specific change]
├── ... continue for all phases
└── Show verification points between phases

STEP 6: Await Explicit Approval
├── Option A: Proceed with full change (risky)
├── Option B: Use phased approach (recommended)
├── Option C: Reduce scope
└── Do NOT proceed without explicit choice
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ ⚠️  COMPLEXITY WARNING - LARGE CHANGE DETECTED               │
├─────────────────────────────────────────────────────────────┤
│ SCOPE ANALYSIS:                                             │
│   Mechanisms affected:  [N] (threshold: 3)     [✓/⚠️]        │
│   Lines changing:       [N] (threshold: 100)   [✓/⚠️]        │
│   Files affected:       [N] (threshold: 2)     [✓/⚠️]        │
│   Modules modified:     [N] (threshold: 5)     [✓/⚠️]        │
│   Dependencies touched: [N] (threshold: 4)     [✓/⚠️]        │
│   ─────────────────────────────────────────────             │
│   COMPLEXITY SCORE: [HIGH/MEDIUM]                           │
├─────────────────────────────────────────────────────────────┤
│ AFFECTED COMPONENTS:                                        │
│   1. [component] - [what changes]                           │
│   2. [component] - [what changes]                           │
│   3. [component] - [what changes]                           │
│   ... [N more]                                              │
├─────────────────────────────────────────────────────────────┤
│ RISK ASSESSMENT:                                            │
│   • Large changes increase chance of unintended breakage    │
│   • Harder to identify what broke if something fails        │
│   • More difficult to roll back if needed                   │
├─────────────────────────────────────────────────────────────┤
│ RECOMMENDED: PHASED APPROACH                                │
│                                                             │
│   Phase 1: [specific focused change]                        │
│            Est. lines: [N], Mechanisms: [N]                 │
│            → Verify before continuing                       │
│                                                             │
│   Phase 2: [specific focused change]                        │
│            Est. lines: [N], Mechanisms: [N]                 │
│            → Verify before continuing                       │
│                                                             │
│   Phase 3: [specific focused change]                        │
│            Est. lines: [N], Mechanisms: [N]                 │
│            → Final verification                             │
│                                                             │
│   Total phases: [N]                                         │
├─────────────────────────────────────────────────────────────┤
│ OPTIONS:                                                    │
│   [A] Proceed with FULL change (⚠️ higher risk)              │
│   [B] Use PHASED approach (✓ recommended)                   │
│   [C] Reduce scope - tell me what to prioritize             │
│                                                             │
│ Enter A, B, or C:                                           │
└─────────────────────────────────────────────────────────────┘
```

### Example Interaction

**User:** "Completely redesign the gear train to use a planetary gear system instead of the current spur gears"

**Agent Response:**
```
┌─────────────────────────────────────────────────────────────┐
│ ⚠️  COMPLEXITY WARNING - LARGE CHANGE DETECTED               │
├─────────────────────────────────────────────────────────────┤
│ SCOPE ANALYSIS:                                             │
│   Mechanisms affected:  5 (threshold: 3)       ⚠️ EXCEEDED   │
│   Lines changing:       187 (threshold: 100)   ⚠️ EXCEEDED   │
│   Files affected:       1 (threshold: 2)       ✓ OK         │
│   Modules modified:     8 (threshold: 5)       ⚠️ EXCEEDED   │
│   Dependencies touched: 6 (threshold: 4)       ⚠️ EXCEEDED   │
│   ─────────────────────────────────────────────             │
│   COMPLEXITY SCORE: HIGH                                    │
├─────────────────────────────────────────────────────────────┤
│ AFFECTED COMPONENTS:                                        │
│   1. main_gear → REMOVE, replace with sun_gear              │
│   2. secondary_gear → REMOVE, replace with planet_gears     │
│   3. gear_mount → REDESIGN for planetary carrier            │
│   4. motor_coupling → MODIFY shaft diameter                 │
│   5. output_shaft → MODIFY connection point                 │
│   6. frame_mounts → ADD ring gear mount points              │
│   7. cam_drive → UPDATE gear connection                     │
│   8. linkage_input → UPDATE attachment point                │
├─────────────────────────────────────────────────────────────┤
│ RISK ASSESSMENT:                                            │
│   • Complete gear train replacement is major change         │
│   • All downstream mechanisms depend on gear output         │
│   • If planetary geometry is wrong, entire assembly fails   │
│   • Difficult to debug if multiple things break             │
├─────────────────────────────────────────────────────────────┤
│ RECOMMENDED: PHASED APPROACH                                │
│                                                             │
│   Phase 1: Create planetary gear module (isolated)          │
│            - sun_gear, planet_gears, ring_gear              │
│            - Test in isolation before integration           │
│            Est. lines: 60, Mechanisms: 1                    │
│            → Verify gear mesh and rotation                  │
│                                                             │
│   Phase 2: Create planetary carrier and housing             │
│            - carrier_plate, bearings, mounts                │
│            Est. lines: 45, Mechanisms: 1                    │
│            → Verify assembly fits in frame                  │
│                                                             │
│   Phase 3: Replace motor coupling                           │
│            - Connect motor to sun gear input                │
│            Est. lines: 25, Mechanisms: 1                    │
│            → Verify motor drives planetary                  │
│                                                             │
│   Phase 4: Reconnect output mechanisms                      │
│            - Cam drive, linkage connections                 │
│            Est. lines: 40, Mechanisms: 2                    │
│            → Verify full system operation                   │
│                                                             │
│   Phase 5: Remove old gear code, cleanup                    │
│            Est. lines: 20 (deletions)                       │
│            → Final verification                             │
│                                                             │
│   Total phases: 5                                           │
├─────────────────────────────────────────────────────────────┤
│ OPTIONS:                                                    │
│   [A] Proceed with FULL change (⚠️ 187 lines, high risk)     │
│   [B] Use PHASED approach (✓ 5 phases, recommended)         │
│   [C] Reduce scope - start with just the gear module        │
│                                                             │
│ Enter A, B, or C:                                           │
└─────────────────────────────────────────────────────────────┘
```

**User:** "B"

**Agent Response:**
```
Starting Phase 1 of 5: Create planetary gear module

I will create the planetary gear module in isolation. This includes:
- sun_gear module
- planet_gear module (with configurable count)
- ring_gear module
- planetary_assembly that combines them

[Proceeds with pre-code-generation hook for Phase 1 only]
```

### Claude Code Implementation

```javascript
const complexityWarningHook = {
  name: "complexity-warning",
  trigger: {
    event: "before_code_generation",
    analysis: "change_scope"
  },

  thresholds: {
    mechanisms: 3,
    lines: 100,
    files: 2,
    modules: 5,
    dependencies: 4
  },

  execute: async function(context) {
    // Step 1: Analyze proposed change
    const analysis = await this.analyzeChangeScope(context.proposedChange);

    // Check if any thresholds exceeded
    const exceeded = {
      mechanisms: analysis.mechanismsAffected > this.thresholds.mechanisms,
      lines: analysis.linesChanged > this.thresholds.lines,
      files: analysis.filesAffected > this.thresholds.files,
      modules: analysis.modulesModified > this.thresholds.modules,
      dependencies: analysis.dependenciesTouched > this.thresholds.dependencies
    };

    const exceedCount = Object.values(exceeded).filter(v => v).length;

    // If thresholds not exceeded, proceed normally
    if (exceedCount === 0) {
      return { proceed: true };
    }

    // Step 2-3: Stop and warn
    const warning = this.formatComplexityWarning(analysis, exceeded);

    // Step 4-5: Generate phased breakdown
    const phases = this.generatePhasedApproach(context.proposedChange, analysis);

    // Step 6: Present and await decision
    await context.presentWarning(warning, phases);

    const choice = await context.awaitUserChoice(['A', 'B', 'C']);

    switch(choice) {
      case 'A':
        // Proceed with full change (user accepts risk)
        return { proceed: true, fullChange: true };

      case 'B':
        // Use phased approach
        context.setPhases(phases);
        return { proceed: true, phasedApproach: true, startPhase: 1 };

      case 'C':
        // User wants to reduce scope
        return { proceed: false, awaitingReducedScope: true };
    }
  },

  analyzeChangeScope: function(proposedChange) {
    return {
      mechanismsAffected: this.countAffectedMechanisms(proposedChange),
      linesChanged: this.estimateLineChanges(proposedChange),
      filesAffected: this.countAffectedFiles(proposedChange),
      modulesModified: this.countModifiedModules(proposedChange),
      dependenciesTouched: this.countDependencyChains(proposedChange),
      affectedComponents: this.listAffectedComponents(proposedChange)
    };
  },

  generatePhasedApproach: function(change, analysis) {
    const phases = [];
    const components = analysis.affectedComponents;

    // Group by dependency order
    const groups = this.groupByDependency(components);

    for (let i = 0; i < groups.length; i++) {
      phases.push({
        number: i + 1,
        description: this.describePhase(groups[i]),
        components: groups[i],
        estimatedLines: this.estimateLinesForGroup(groups[i]),
        mechanisms: this.countMechanismsInGroup(groups[i]),
        verificationSteps: this.generateVerificationSteps(groups[i])
      });
    }

    return phases;
  }
};
```

---

## Hook 6: physical-reality-check

### Purpose
Validate that proposed mechanical designs are physically feasible, with proper fit, motion clearance, power transmission, and geometric validity.

### Trigger Conditions

```yaml
trigger:
  type: "phrase_detection"
  patterns:
    - "will this work"
    - "is this possible"
    - "can this move"
    - "will it fit"
    - "check if this works"
    - "is this feasible"
    - "reality check"
    - "sanity check"
    - "validate this"
    - "can this be built"
    - "will this print"
```

**Regex Pattern:**
```regex
/will (this|it) work|is (this|it) possible|can (this|it) (move|fit|work|be built)|check if|is (this|it) feasible|reality check|sanity check|validate|will (this|it) print/i
```

### Step-by-Step Action Sequence

```
STEP 1: Dimensional Fit Verification
├── Extract all component dimensions
├── Extract enclosure/frame dimensions
├── Check: each component < enclosure
├── Check: total assembly < enclosure
├── Calculate clearances
├── Generate bounding box diagram
└── Flag violations

STEP 2: Collision Analysis
├── Identify all moving parts
├── Map full range of motion for each
├── Generate motion envelope for each part
├── Check envelope intersections
├── Identify collision points and angles
├── Generate collision diagram
└── Flag interference

STEP 3: Power Path Verification
├── Identify power source (motor/input)
├── Trace transmission chain:
│   ├── Motor → Coupling
│   ├── Coupling → Gear 1
│   ├── Gear 1 → Gear 2
│   ├── ... continue chain
│   └── Final stage → Output
├── Verify each connection
├── Calculate ratios/speeds at each stage
├── Generate power flow diagram
└── Flag broken paths

STEP 4: Geometry Validation
├── Gear Mesh Check:
│   ├── Verify module/pitch match
│   ├── Calculate center distance
│   ├── Verify teeth engagement
│   └── Check pressure angle compatibility
├── Linkage Check:
│   ├── Verify Grashof condition
│   ├── Check for dead points
│   ├── Verify range of motion
│   └── Check toggle positions
├── Cam Check:
│   ├── Verify follower reaches profile
│   ├── Check for undercutting
│   └── Verify pressure angle limits
└── Generate geometry diagrams

STEP 5: Compile Feasibility Report
├── Aggregate all check results
├── Calculate overall feasibility score
├── Prioritize issues by severity
├── Generate recommendations
└── Present comprehensive report
```

### Output Format

```
┌─────────────────────────────────────────────────────────────┐
│ ⚙️  PHYSICAL REALITY CHECK                                   │
├─────────────────────────────────────────────────────────────┤
│ DIMENSIONAL FIT ANALYSIS                                    │
│ ─────────────────────────                                   │
│   Enclosure (frame): 200 x 150 x 100 mm                     │
│                                                             │
│   Component          Size (mm)        Status                │
│   ────────────────────────────────────────────              │
│   main_gear          Ø72 x 10         ✓ fits (72 < 200)     │
│   secondary_gear     Ø36 x 10         ✓ fits                │
│   linkage_arm        120 x 15 x 8     ✓ fits                │
│   cam_assembly       Ø50 x 25         ✓ fits                │
│   motor_mount        40 x 40 x 50     ✓ fits                │
│                                                             │
│   Total assembly envelope: 185 x 142 x 95 mm                │
│   Clearance to frame: 15 x 8 x 5 mm   ✓ SUFFICIENT          │
│                                                             │
│   Top View Fit:                                             │
│   ┌────────────────────────────────────┐                    │
│   │ Frame 200x150                      │                    │
│   │  ┌────────────────────────────┐   │                    │
│   │  │    Assembly 185x142        │   │                    │
│   │  │   ┌──┐    ┌──┐            │   │                    │
│   │  │   │G1│────│G2│   ┌───┐    │   │                    │
│   │  │   └──┘    └──┘   │cam│    │   │                    │
│   │  │                   └───┘    │   │                    │
│   │  └────────────────────────────┘   │                    │
│   └────────────────────────────────────┘                    │
│                                                             │
│   Status: ✓ ALL COMPONENTS FIT                              │
├─────────────────────────────────────────────────────────────┤
│ COLLISION ANALYSIS                                          │
│ ──────────────────                                          │
│   Moving Parts Checked:                                     │
│     • main_gear: 360° rotation                              │
│     • secondary_gear: 360° rotation                         │
│     • linkage_arm: -45° to +45° swing                       │
│     • cam_follower: 20mm vertical travel                    │
│                                                             │
│   Motion Envelope Check:                                    │
│     main_gear ↔ secondary_gear:     ✓ No collision          │
│     main_gear ↔ linkage_arm:        ✓ No collision          │
│     main_gear ↔ frame:              ✓ 15mm clearance        │
│     linkage_arm ↔ cam_assembly:     ⚠️ 2mm clearance (tight) │
│     cam_follower ↔ frame:           ✓ No collision          │
│                                                             │
│   Motion Diagram (side view at max swing):                  │
│                                                             │
│        ○ gear axis                                          │
│       /│\                                                   │
│      / │ \ ←linkage sweep                                   │
│     /  │  \                                                 │
│    ────┼────  ← cam (close!)                                │
│        │                                                    │
│                                                             │
│   Status: ⚠️ TIGHT CLEARANCE - Review linkage_arm path       │
├─────────────────────────────────────────────────────────────┤
│ POWER PATH VERIFICATION                                     │
│ ────────────────────────                                    │
│   Tracing from motor to outputs:                            │
│                                                             │
│   [MOTOR]──┬──[MAIN GEAR]──[SECONDARY]──[CAM DRIVE]         │
│    100rpm  │    ↓             ↓            ↓                │
│            │   2:1          1:1         cam                 │
│            │   50rpm        50rpm       profile             │
│            │                                                │
│            └──[LINKAGE INPUT]──[LINKAGE ARM]──[OUTPUT]      │
│                    ↓               ↓            ↓           │
│                  crank          4-bar       oscillate       │
│                  50rpm          ±45°        ±30mm           │
│                                                             │
│   Connection Verification:                                  │
│     Motor → Main gear shaft:    ✓ Connected (D-shaft)       │
│     Main → Secondary mesh:      ✓ Meshed (module 2.0)       │
│     Secondary → Cam:            ✓ Connected (keyed)         │
│     Secondary → Linkage:        ✓ Connected (crank pin)     │
│     Linkage → Output:           ✓ Connected (pivot)         │
│                                                             │
│   Status: ✓ COMPLETE POWER PATH                             │
├─────────────────────────────────────────────────────────────┤
│ GEOMETRY VALIDATION                                         │
│ ───────────────────                                         │
│   GEAR MESH:                                                │
│     Main gear:      teeth=36, module=2.0, Ø=72mm            │
│     Secondary:      teeth=18, module=2.0, Ø=36mm            │
│     Center dist:    54mm (calculated: (72+36)/2 = 54) ✓     │
│     Pressure angle: 20° (standard) ✓                        │
│     Backlash:       0.1mm (acceptable) ✓                    │
│     Status: ✓ VALID MESH                                    │
│                                                             │
│   LINKAGE (4-bar):                                          │
│     Link lengths: L1=20, L2=60, L3=55, L4=50                │
│     Grashof check: 20+60=80 < 55+50=105 ✓ Grashof           │
│     Type: Crank-rocker (shortest=crank) ✓                   │
│     Dead points: None (continuous rotation) ✓               │
│     Status: ✓ VALID LINKAGE                                 │
│                                                             │
│   CAM:                                                      │
│     Profile type: 3-lobe harmonic                           │
│     Base circle: Ø30mm                                      │
│     Max lift: 10mm                                          │
│     Follower type: roller Ø6mm                              │
│     Pressure angle: max 28° (limit 30°) ✓                   │
│     Undercutting: None ✓                                    │
│     Status: ✓ VALID CAM                                     │
├─────────────────────────────────────────────────────────────┤
│ FEASIBILITY VERDICT                                         │
│ ───────────────────                                         │
│                                                             │
│   Dimensional Fit:    ✓ PASS                                │
│   Collision Check:    ⚠️ WARNING (tight clearance)           │
│   Power Path:         ✓ PASS                                │
│   Gear Geometry:      ✓ PASS                                │
│   Linkage Geometry:   ✓ PASS                                │
│   Cam Geometry:       ✓ PASS                                │
│                                                             │
│   ════════════════════════════════════════                  │
│   OVERALL: ⚠️ FEASIBLE WITH CAUTION                          │
│   ════════════════════════════════════════                  │
│                                                             │
│   RECOMMENDATION:                                           │
│   The design will work, but increase clearance between      │
│   linkage_arm and cam_assembly from 2mm to at least 5mm     │
│   to account for manufacturing tolerances.                  │
│                                                             │
│   Options:                                                  │
│   • Shorten linkage_arm by 3mm                              │
│   • Move cam_assembly 3mm in +X direction                   │
│   • Accept 2mm clearance (risky)                            │
└─────────────────────────────────────────────────────────────┘
```

### Example Interaction

**User:** "Will this planetary gear system actually work? Can it move freely?"

**Agent Response:**
```
┌─────────────────────────────────────────────────────────────┐
│ ⚙️  PHYSICAL REALITY CHECK: Planetary Gear System            │
├─────────────────────────────────────────────────────────────┤
│ DIMENSIONAL FIT ANALYSIS                                    │
│ ─────────────────────────                                   │
│   Housing inner diameter: 80mm                              │
│                                                             │
│   Component          Size           Status                  │
│   ─────────────────────────────────────────                 │
│   sun_gear           Ø20 x 8        ✓ fits                  │
│   planet_gears (3x)  Ø24 x 8 each   ✓ fits                  │
│   ring_gear          Ø72 x 10       ✓ fits (72 < 80)        │
│   carrier_plate      Ø70 x 5        ✓ fits                  │
│                                                             │
│   Cross-section View:                                       │
│        ┌─────────────────────┐                              │
│        │   Housing Ø80      │                               │
│        │  ┌───────────────┐ │                               │
│        │  │ Ring Ø72     ││ │                               │
│        │  │  ○   ○   ○   ││←planets                         │
│        │  │    ╳        ││←sun                              │
│        │  │  ○   ○   ○   ││                                 │
│        │  └───────────────┘ │                               │
│        └─────────────────────┘                              │
│                                                             │
│   Clearance: 4mm to housing   ✓ SUFFICIENT                  │
├─────────────────────────────────────────────────────────────┤
│ COLLISION ANALYSIS                                          │
│ ──────────────────                                          │
│   Checking planetary gear rotation:                         │
│                                                             │
│   Sun rotation test:        ✓ Free rotation                 │
│   Planet orbit test:        ✓ Clear path                    │
│   Planet-to-planet check:   ✓ No interference               │
│   Planet-to-ring mesh:      ✓ Proper engagement             │
│   Carrier rotation test:    ✓ Free rotation                 │
│                                                             │
│   Orbit Diagram (top view):                                 │
│           ·  ·  ·                                           │
│        ·    ╱│╲    ·  ← planet orbit path                   │
│       ·   P1 │ P2   ·                                       │
│       ·    ╲│╱     ·                                        │
│        ·   ═╪═    ·  ← sun (center)                         │
│       ·    ╱│╲     ·                                        │
│       ·   P3 │ P4   ·                                       │
│        ·    ╲│╱    ·                                        │
│           ·  ·  ·                                           │
│                                                             │
│   Planet spacing: 90° apart                                 │
│   Minimum gap between planets: 8mm  ✓ NO COLLISION          │
├─────────────────────────────────────────────────────────────┤
│ POWER PATH VERIFICATION                                     │
│ ────────────────────────                                    │
│   Configuration: Sun input → Carrier output (ring fixed)    │
│                                                             │
│   [MOTOR]──[SUN]──┬──[PLANET 1]──┐                          │
│                   ├──[PLANET 2]──┼──[RING]──(FIXED)         │
│                   ├──[PLANET 3]──┤                          │
│                   └──────────────┴──[CARRIER]──[OUTPUT]     │
│                                                             │
│   Gear Ratio Calculation:                                   │
│     Sun teeth: 20                                           │
│     Planet teeth: 24                                        │
│     Ring teeth: 68 (must = sun + 2×planet = 20+48=68) ✓     │
│                                                             │
│     Ratio = 1 + (ring/sun) = 1 + 68/20 = 4.4:1              │
│                                                             │
│   If sun @ 100rpm → carrier @ 22.7rpm (4.4x reduction) ✓    │
│                                                             │
│   Status: ✓ COMPLETE POWER PATH                             │
├─────────────────────────────────────────────────────────────┤
│ GEOMETRY VALIDATION                                         │
│ ───────────────────                                         │
│   PLANETARY GEAR MESH:                                      │
│     Module: 2.0 (all gears) ✓                               │
│     Sun:    20 teeth, Ø40mm (PCD)                           │
│     Planet: 24 teeth, Ø48mm (PCD)                           │
│     Ring:   68 teeth, Ø136mm (PCD, internal)                │
│                                                             │
│   Critical Checks:                                          │
│     Ring = Sun + 2×Planet? 68 = 20 + 48 ✓ VALID             │
│     Sun-planet center: (40+48)/2 = 44mm ✓                   │
│     Planet-ring center: (136-48)/2 = 44mm ✓ MATCHES         │
│     Planet count: 3 (evenly divisible) ✓                    │
│                                                             │
│   Assembly Condition:                                       │
│     (Sun + Ring) / Planets = integer?                       │
│     (20 + 68) / 3 = 29.33 ✗ NOT INTEGER                     │
│                                                             │
│     ⚠️ ASSEMBLY WARNING:                                     │
│     Planets cannot be evenly spaced at 120°!                │
│     Options:                                                │
│     • Use 4 planets: (20+68)/4 = 22 ✓                       │
│     • Change sun to 22T: (22+68)/3 = 30 ✓                   │
│     • Change ring to 70T: (20+70)/3 = 30 ✓                  │
├─────────────────────────────────────────────────────────────┤
│ FEASIBILITY VERDICT                                         │
│ ───────────────────                                         │
│                                                             │
│   Dimensional Fit:    ✓ PASS                                │
│   Collision Check:    ✓ PASS                                │
│   Power Path:         ✓ PASS                                │
│   Planetary Geometry: ✗ FAIL (assembly condition)           │
│                                                             │
│   ════════════════════════════════════════                  │
│   OVERALL: ✗ NOT FEASIBLE AS DESIGNED                       │
│   ════════════════════════════════════════                  │
│                                                             │
│   CRITICAL ISSUE:                                           │
│   The current tooth counts (20/24/68) do not allow          │
│   assembly with 3 equally-spaced planets.                   │
│                                                             │
│   RECOMMENDED FIX (choose one):                             │
│   [A] Change to 4 planets (keeps all current tooth counts)  │
│   [B] Change sun to 22 teeth (keeps 3 planets)              │
│   [C] Change ring to 70 teeth (keeps 3 planets)             │
│                                                             │
│   Which fix would you like me to implement?                 │
└─────────────────────────────────────────────────────────────┘
```

### Claude Code Implementation

```javascript
const physicalRealityCheckHook = {
  name: "physical-reality-check",
  trigger: {
    type: "phrase_detection",
    patterns: [
      /will (this|it) work/i,
      /is (this|it) possible/i,
      /can (this|it) (move|fit|work|be built)/i,
      /is (this|it) feasible/i,
      /reality check/i,
      /sanity check/i,
      /validate/i,
      /will (this|it) print/i
    ]
  },

  execute: async function(context) {
    const design = context.getCurrentDesign();

    // Step 1: Dimensional Fit
    const fitAnalysis = await this.verifyDimensionalFit(design);

    // Step 2: Collision Analysis
    const collisionAnalysis = await this.analyzeCollisions(design);

    // Step 3: Power Path
    const powerPathAnalysis = await this.verifyPowerPath(design);

    // Step 4: Geometry Validation
    const geometryAnalysis = await this.validateGeometry(design);

    // Step 5: Compile Report
    const report = this.compileReport(
      fitAnalysis,
      collisionAnalysis,
      powerPathAnalysis,
      geometryAnalysis
    );

    await context.presentReport(report);

    // If issues found, offer solutions
    if (report.overallStatus !== 'PASS') {
      const solutions = this.generateSolutions(report);
      await context.presentSolutions(solutions);
    }
  },

  verifyDimensionalFit: function(design) {
    const enclosure = design.getEnclosure();
    const components = design.getAllComponents();
    const results = [];

    for (const comp of components) {
      const bbox = comp.getBoundingBox();
      results.push({
        name: comp.name,
        size: bbox,
        fits: bbox.fitsWithin(enclosure),
        clearance: enclosure.clearanceTo(bbox)
      });
    }

    return {
      enclosure: enclosure.dimensions,
      components: results,
      totalEnvelope: design.getTotalEnvelope(),
      overallFits: results.every(r => r.fits),
      diagram: this.generateFitDiagram(design, results)
    };
  },

  analyzeCollisions: function(design) {
    const movingParts = design.getMovingParts();
    const collisions = [];

    for (let i = 0; i < movingParts.length; i++) {
      const partA = movingParts[i];
      const envelopeA = partA.getMotionEnvelope();

      // Check against other parts
      for (let j = i + 1; j < movingParts.length; j++) {
        const partB = movingParts[j];
        const envelopeB = partB.getMotionEnvelope();

        const intersection = envelopeA.intersects(envelopeB);
        if (intersection) {
          collisions.push({
            partA: partA.name,
            partB: partB.name,
            type: 'part-to-part',
            clearance: intersection.minDistance,
            collisionPoint: intersection.location
          });
        }
      }

      // Check against frame
      const frameCollision = envelopeA.intersects(design.getFrame());
      if (frameCollision) {
        collisions.push({
          partA: partA.name,
          partB: 'frame',
          type: 'part-to-frame',
          clearance: frameCollision.minDistance
        });
      }
    }

    return {
      movingParts: movingParts.map(p => ({ name: p.name, motion: p.motionType })),
      collisions: collisions,
      hasCollisions: collisions.some(c => c.clearance <= 0),
      tightClearances: collisions.filter(c => c.clearance > 0 && c.clearance < 5),
      diagram: this.generateCollisionDiagram(design, collisions)
    };
  },

  verifyPowerPath: function(design) {
    const powerSource = design.getPowerSource();
    const outputs = design.getOutputs();
    const paths = [];

    for (const output of outputs) {
      const path = this.tracePowerPath(powerSource, output, design);
      paths.push({
        from: powerSource.name,
        to: output.name,
        stages: path.stages,
        complete: path.complete,
        breakPoint: path.breakPoint,
        ratios: path.ratios,
        speeds: path.speeds
      });
    }

    return {
      powerSource: powerSource,
      outputs: outputs,
      paths: paths,
      allComplete: paths.every(p => p.complete),
      diagram: this.generatePowerPathDiagram(design, paths)
    };
  },

  validateGeometry: function(design) {
    const results = {
      gears: [],
      linkages: [],
      cams: []
    };

    // Validate gear meshes
    for (const gearPair of design.getGearPairs()) {
      results.gears.push(this.validateGearMesh(gearPair));
    }

    // Validate linkages
    for (const linkage of design.getLinkages()) {
      results.linkages.push(this.validateLinkage(linkage));
    }

    // Validate cams
    for (const cam of design.getCams()) {
      results.cams.push(this.validateCam(cam));
    }

    return results;
  },

  validateGearMesh: function(gearPair) {
    const g1 = gearPair.gear1;
    const g2 = gearPair.gear2;

    return {
      gear1: { teeth: g1.teeth, module: g1.module, diameter: g1.pitchDiameter },
      gear2: { teeth: g2.teeth, module: g2.module, diameter: g2.pitchDiameter },
      moduleMatch: g1.module === g2.module,
      centerDistance: {
        actual: gearPair.centerDistance,
        calculated: (g1.pitchDiameter + g2.pitchDiameter) / 2,
        valid: Math.abs(gearPair.centerDistance - (g1.pitchDiameter + g2.pitchDiameter) / 2) < 0.1
      },
      pressureAngle: gearPair.pressureAngle,
      backlash: gearPair.backlash,
      valid: this.isGearMeshValid(gearPair)
    };
  },

  validateLinkage: function(linkage) {
    const lengths = linkage.linkLengths;
    const sorted = [...lengths].sort((a, b) => a - b);
    const shortest = sorted[0];
    const longest = sorted[sorted.length - 1];
    const sumOthers = sorted.slice(1, -1).reduce((a, b) => a + b, 0);

    // Grashof condition: shortest + longest <= sum of others
    const grashof = shortest + longest <= sumOthers + shortest;

    return {
      type: linkage.type,
      linkLengths: lengths,
      grashofCondition: grashof,
      linkageType: this.determineLinkageType(linkage, grashof),
      deadPoints: this.findDeadPoints(linkage),
      rangeOfMotion: this.calculateRangeOfMotion(linkage),
      valid: grashof && this.checkLinkageValidity(linkage)
    };
  }
};
```

---

## Implementation Reference

### Adding Hooks to CLAUDE.md

To enable these hooks in your Claude Code project, add the following to your `CLAUDE.md` file:

```markdown
## Mechanical Design Agent Hooks

This project uses automated hooks for safe, predictable mechanical design iteration.

### Active Hooks

1. **pre-code-generation**: Requires confirmation before ANY OpenSCAD code changes
2. **user-frustration-detector**: Responds to user frustration with appropriate recovery actions
3. **post-version-delivery**: Automatically runs verification after each version delivery
4. **lock-in-detector**: Creates immutable records when user says "lock this in" etc.
5. **complexity-warning**: Warns when changes exceed safe complexity thresholds
6. **physical-reality-check**: Validates physical feasibility when asked

### Hook Trigger Summary

| Hook | Trigger |
|------|---------|
| pre-code-generation | Before any .scad file modification |
| user-frustration-detector | Phrase detection (see matrix) |
| post-version-delivery | After delivering new version file |
| lock-in-detector | "lock this in", "this is final", etc. |
| complexity-warning | >3 mechanisms OR >100 lines changed |
| physical-reality-check | "will this work?", "is this possible?" |

### Immutable Boundaries

[Maintained by lock-in-detector hook]

| ID | Item | Value | Locked Date |
|----|------|-------|-------------|
| (populated dynamically) |

### Version History

| Version | Date | Changes | Status |
|---------|------|---------|--------|
| (populated by post-version-delivery) |
```

### Integration Points

```javascript
// Main agent loop integration
async function processUserMessage(message, context) {
  // Check for frustration triggers first
  const frustrationMatch = userFrustrationHook.checkTrigger(message);
  if (frustrationMatch) {
    return await userFrustrationHook.execute(context, frustrationMatch);
  }

  // Check for lock-in triggers
  const lockMatch = lockInDetectorHook.checkTrigger(message);
  if (lockMatch) {
    return await lockInDetectorHook.execute(context);
  }

  // Check for reality check triggers
  const realityMatch = physicalRealityCheckHook.checkTrigger(message);
  if (realityMatch) {
    return await physicalRealityCheckHook.execute(context);
  }

  // Normal processing...
  if (context.willGenerateCode()) {
    // Check complexity first
    const complexityResult = await complexityWarningHook.execute(context);
    if (!complexityResult.proceed) {
      return complexityResult;
    }

    // Run pre-code-generation hook
    const preCodeResult = await preCodeGenerationHook.execute(context);
    if (!preCodeResult.proceed) {
      return preCodeResult;
    }

    // Generate code...
    const code = await generateOpenSCADCode(context);

    // Run post-version-delivery hook
    await postVersionDeliveryHook.execute(context);

    return code;
  }
}
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│ HOOKS QUICK REFERENCE                                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ PRE-CODE-GENERATION                                         │
│   Triggers: Any .scad modification                          │
│   Output: Change declaration + confirmation request         │
│   User action: Say "proceed" or "yes"                       │
│                                                             │
│ USER-FRUSTRATION-DETECTOR                                   │
│   "going in circles" → Diagnose + rollback                  │
│   "where is my X"    → Survival checklist                   │
│   "think hard"       → Extended analysis                    │
│   "verify works"     → Feasibility check                    │
│   "this is broken"   → Emergency audit                      │
│                                                             │
│ POST-VERSION-DELIVERY                                       │
│   Triggers: After file delivery                             │
│   Output: Survival check + ASCII diagram + test steps       │
│   User action: Follow test instructions or choose next      │
│                                                             │
│ LOCK-IN-DETECTOR                                            │
│   Triggers: "lock in", "final", "don't change"              │
│   Output: Lock confirmation + enforcement notice            │
│   Unlock: "unlock [item]"                                   │
│                                                             │
│ COMPLEXITY-WARNING                                          │
│   Triggers: >3 mechanisms OR >100 lines                     │
│   Output: Scope analysis + phased breakdown                 │
│   User action: Choose A (full), B (phased), C (reduce)      │
│                                                             │
│ PHYSICAL-REALITY-CHECK                                      │
│   Triggers: "will this work", "is this possible"            │
│   Output: Full feasibility report with diagrams             │
│   User action: Review findings, choose fixes if needed      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```
