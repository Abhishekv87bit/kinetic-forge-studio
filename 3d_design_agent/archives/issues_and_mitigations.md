# 3D Mechanical Design Agent: Issues, Challenges & Mitigations

## PROACTIVE ISSUE IDENTIFICATION

This document catalogs known issues, their warning signs, mitigations, and recovery strategies for the 3D Mechanical Design Agent. Use this as a reference during development and when troubleshooting problems.

---

## CATEGORY 1: VERSION CONTROL ISSUES

### Issue 1.1: Component Disappearance (Silent Regression)

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :red_circle: CRITICAL |
| **Description** | Components silently disappearing during iterations when Claude regenerates code |
| **Root Cause** | Recreating from scratch instead of modifying existing code |
| **Warning Signs** | User asks "where is my [X]?", component counts decrease unexpectedly |

**Mitigation Strategies:**
- NEVER recreate code from scratch - always modify existing code
- Run component survival checklist after EVERY change
- Use version diff to verify only targeted changes were made
- Maintain explicit component manifest with expected counts
- Before finalizing any edit, verify all previously existing components still exist

**Recovery Protocol:**
1. Identify last known good version
2. Diff against current version to find when component was lost
3. Restore lost component from good version
4. Analyze what change caused the regression to prevent recurrence

---

### Issue 1.2: Version Drift

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | Gradual deviation from intended design through accumulated small changes |
| **Root Cause** | Each change introduces minor deviations that compound over time |
| **Warning Signs** | Design feels "off" but no single change is wrong, user says "this isn't what I wanted" |

**Mitigation Strategies:**
- Maintain master specification document with locked decisions
- Explicitly mark decisions as LOCKED when finalized
- Reference locked decisions before making any related changes
- Periodic comparison against original specification
- Document the "why" behind each decision, not just the "what"

**Recovery Protocol:**
1. Review master specification
2. Identify which locked decisions have been violated
3. Systematically restore each violated decision
4. Update change log to track restoration

---

### Issue 1.3: Undo Cascade Failure

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | Attempting to undo a change breaks other dependent components |
| **Root Cause** | Changes have hidden dependencies not tracked |
| **Warning Signs** | "Undo" creates new problems, fixing one thing breaks another |

**Mitigation Strategies:**
- Track dependencies explicitly in comments
- Before undoing, identify all dependent components
- Use atomic, isolated changes that minimize cross-dependencies
- Maintain dependency graph for complex mechanisms

**Recovery Protocol:**
1. Stop making changes immediately
2. Return to last known good version
3. Replay changes selectively with dependency awareness

---

## CATEGORY 2: MECHANICAL DESIGN ISSUES

### Issue 2.1: Gear Miscalculation

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :red_circle: CRITICAL |
| **Description** | Placing gears visually instead of mathematically, causing mesh failure |
| **Root Cause** | Estimating center distance instead of calculating from gear parameters |
| **Warning Signs** | Gears appear to touch but animation shows slipping, teeth don't interlock properly |

**Mitigation Strategies:**
- ALWAYS use the formula: `Center Distance = (T1 + T2) * module / 2`
- Where T1 = teeth on gear 1, T2 = teeth on gear 2
- Verify calculated distance against placed distance in code
- For gear trains, calculate each mesh point sequentially
- Never adjust gear positions "by eye"

**Verification Checklist:**
```
[ ] Calculated center distance using formula
[ ] Verified module is consistent across meshing gears
[ ] Checked pitch circles are tangent (not overlapping or gapped)
[ ] Confirmed rotation directions alternate correctly
[ ] Tested animation shows smooth mesh without slipping
```

**Recovery Protocol:**
1. Extract current gear parameters (module, teeth count)
2. Recalculate correct center distances
3. Update positions using calculated values only

---

### Issue 2.2: Z-Layer Collisions

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | Parts occupying same Z-space causing interference or visual artifacts |
| **Root Cause** | No systematic Z-layer tracking, ad-hoc Z positioning |
| **Warning Signs** | Flickering in preview, parts disappearing at certain angles, unexpected Boolean artifacts |

**Mitigation Strategies:**
- Maintain Z-stack diagram showing all components and their Z ranges
- Define Z-layers explicitly (e.g., base=0, mechanism_1=5-15, mechanism_2=20-30)
- Verify Z clearance before adding any new component
- Include Z-range in component comments

**Z-Stack Template:**
```
Z-LAYER MAP:
  Z=0-5:     Base plate
  Z=5-10:    Primary gear train
  Z=10-15:   Secondary mechanisms
  Z=15-20:   Linkage layer
  Z=20-25:   Decorative elements
  Z=25-30:   Top cover
```

**Recovery Protocol:**
1. Document current Z positions of all components
2. Identify overlapping ranges
3. Reassign Z positions to eliminate collisions
4. Update Z-stack diagram

---

### Issue 2.3: Linkage Geometry Failure

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | Four-bar linkage that won't complete full rotation or locks up |
| **Root Cause** | Grashof condition not verified before implementation |
| **Warning Signs** | Animation stops partway, linkage "flips" unexpectedly, jerky motion |

**Mitigation Strategies:**
- Verify Grashof condition before implementation: `s + l < p + q`
  - s = shortest link, l = longest link, p and q = other two links
- For crank-rocker: shortest link must be the crank (input)
- For double-crank: shortest link must be the frame
- Document linkage type and verify configuration matches intent

**Grashof Verification Checklist:**
```
[ ] Measured all four link lengths
[ ] Identified shortest (s) and longest (l) links
[ ] Calculated s + l and p + q
[ ] Verified s + l < p + q (Grashof condition)
[ ] Confirmed linkage type matches intended motion
```

**Recovery Protocol:**
1. Measure current link lengths
2. Calculate Grashof condition
3. Adjust link lengths to satisfy condition while preserving motion intent
4. Retest full rotation cycle

---

### Issue 2.4: Power Path Disconnection

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :red_circle: CRITICAL |
| **Description** | Moving parts not actually connected to motor drive - floating components |
| **Root Cause** | Visual placement without mechanical connection verification |
| **Warning Signs** | Parts don't move during animation, user says "why isn't X moving?" |

**Mitigation Strategies:**
- Trace complete power path from motor to EVERY moving component
- Document power path in comments for each mechanism
- Use explicit connection verification after adding any component
- Create power path diagram for complex assemblies

**Power Path Verification Template:**
```
MOTOR -> Gear A (12T) -> Gear B (36T) -> Shaft 1 -> Gear C (24T) ->
Gear D (24T) -> Crank -> Linkage -> Output Motion

Verify each "->" represents actual mechanical connection
```

**Recovery Protocol:**
1. List all components that should move
2. Trace power path from motor to each
3. Identify disconnected components
4. Add missing mechanical connections

---

### Issue 2.5: Rotation Direction Errors

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | Components rotating in wrong direction, breaking intended motion |
| **Root Cause** | Not tracking rotation direction through gear train |
| **Warning Signs** | Mechanism moves opposite to expected, linkages bind |

**Mitigation Strategies:**
- Track rotation direction at each gear mesh (direction reverses at each mesh)
- Document expected direction for each rotating component
- Verify direction in animation before proceeding

**Rotation Tracking Template:**
```
Motor: CW
  -> Gear A: CCW (1st mesh)
    -> Gear B: CW (2nd mesh)
      -> Gear C: CCW (3rd mesh)
```

---

## CATEGORY 3: COMMUNICATION ISSUES

### Issue 3.1: Context Loss

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | Forgetting locked decisions or user preferences from earlier in conversation |
| **Root Cause** | Long conversations exceed context window, or decisions not explicitly tracked |
| **Warning Signs** | Repeating discussions already had, contradicting earlier agreements |

**Mitigation Strategies:**
- Maintain explicit LOCKED DECISIONS list in project state
- Reference locked decisions before making any related changes
- Summarize key decisions at conversation milestones
- User can say "remember: [X]" to flag important decisions

**Locked Decisions Template:**
```
LOCKED DECISIONS:
1. [LOCKED] Gear module = 2mm (decided iteration 3)
2. [LOCKED] Base plate dimensions: 100x80mm (user specified)
3. [LOCKED] Color scheme: blue mechanisms, gray frame (user preference)
4. [LOCKED] Animation speed: 1 full cycle per $t (decided iteration 5)
```

---

### Issue 3.2: Assumption Mismatch

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :yellow_circle: MEDIUM |
| **Description** | Claude's assumptions about design differ from user's actual intent |
| **Root Cause** | Implicit assumptions not verified, ambiguous requirements |
| **Warning Signs** | User frequently corrects Claude, "that's not what I meant" |

**Mitigation Strategies:**
- Summarize understanding before each major action
- Ask clarifying questions when requirements are ambiguous
- State assumptions explicitly and ask for confirmation
- When in doubt, ask rather than assume

**Pre-Action Verification Template:**
```
"Before I proceed, let me confirm my understanding:
- You want [specific change]
- This will affect [components]
- The expected result is [outcome]
Is this correct?"
```

---

### Issue 3.3: Scope Creep

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | "While we're at it" additions that complicate design and introduce bugs |
| **Root Cause** | Trying to do too much in one iteration |
| **Warning Signs** | Changes affect more than planned, new bugs appear in unrelated areas |

**Mitigation Strategies:**
- One targeted change per iteration
- Complexity warning hook: if change affects >3 mechanisms, pause and get approval
- Resist urge to "improve" unrelated code while making targeted change
- Document scope of each change before starting

**Scope Control Checklist:**
```
Before each change:
[ ] Defined specific scope of change
[ ] Identified affected components (should be minimal)
[ ] Confirmed change doesn't introduce "while we're at it" additions
[ ] Got approval if scope exceeds original plan
```

---

### Issue 3.4: Instruction Ambiguity

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :yellow_circle: MEDIUM |
| **Description** | User instructions can be interpreted multiple ways |
| **Root Cause** | Natural language ambiguity, domain-specific terminology |
| **Warning Signs** | Confident execution of wrong interpretation |

**Mitigation Strategies:**
- Restate instruction in specific technical terms before executing
- Identify potential ambiguities and ask for clarification
- Provide options when multiple interpretations exist

---

## CATEGORY 4: OPENSCAD-SPECIFIC ISSUES

### Issue 4.1: SVG Placeholder Syndrome

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :red_circle: CRITICAL |
| **Description** | Using fake/estimated coordinates instead of real extracted SVG data |
| **Root Cause** | Generating plausible-looking but incorrect path data |
| **Warning Signs** | SVG import looks wrong, coordinates don't match source file |

**Mitigation Strategies:**
- ALWAYS extract actual SVG data via file reading
- Never "approximate" or "estimate" SVG coordinates
- Verify extracted data against source file
- If SVG parsing is complex, simplify the SVG first

**SVG Extraction Protocol:**
```
1. Read the actual SVG file
2. Extract path data exactly as written
3. Parse path commands (M, L, C, Z, etc.)
4. Convert to OpenSCAD polygon or import()
5. Verify result matches source visually
```

**Recovery Protocol:**
1. Read original SVG file
2. Extract actual coordinate data
3. Replace placeholder data with real data
4. Verify visual match

---

### Issue 4.2: Animation Performance

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :yellow_circle: LOW |
| **Description** | Slow animation due to excessive $fn or complex operations |
| **Root Cause** | Over-detailed geometry, unoptimized Boolean operations |
| **Warning Signs** | Preview takes >2 seconds, choppy animation |

**Mitigation Strategies:**
- Profile AFTER stability achieved, not during development
- Use lower $fn during development (e.g., $fn=32)
- Increase $fn only for final render
- Simplify complex shapes where detail isn't visible

**$fn Guidelines:**
```
Development: $fn = 32 (fast preview)
Testing: $fn = 64 (balance)
Final: $fn = 128+ (smooth curves)

For gears: $fn = teeth_count * 4 (minimum for clean teeth)
```

---

### Issue 4.3: Orientation Confusion

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | Viewer POV vs. model coordinate system mismatch |
| **Root Cause** | Confusion between "left/right" in viewer space vs. +X/-X in model space |
| **Warning Signs** | "Move it left" results in wrong direction, orientation corrections needed |

**Mitigation Strategies:**
- ALWAYS verify orientations from front view (viewer perspective)
- Establish coordinate convention at project start
- Use explicit axis names (+X, -X, +Y, -Y, +Z, -Z) when possible
- When user says "left/right", confirm which perspective

**Coordinate Convention:**
```
Standard OpenSCAD (when viewed from default camera):
  +X = Right (viewer's right)
  -X = Left (viewer's left)
  +Y = Back (away from viewer)
  -Y = Front (toward viewer)
  +Z = Up
  -Z = Down
```

---

### Issue 4.4: Boolean Operation Failures

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | difference() or union() produces unexpected results |
| **Root Cause** | Coincident faces, non-manifold geometry, floating point precision |
| **Warning Signs** | Holes don't appear, strange artifacts, preview warnings |

**Mitigation Strategies:**
- Extend cutting shapes slightly beyond target (add 0.01 margin)
- Avoid perfectly coincident faces
- Use manifold=true where supported
- Check for and fix non-manifold warnings

**Boolean Best Practices:**
```openscad
// BAD: Coincident faces
difference() {
  cube([10, 10, 10]);
  translate([5, 0, 0]) cube([5, 10, 10]);  // Face at x=5 is coincident
}

// GOOD: Extended cut
difference() {
  cube([10, 10, 10]);
  translate([5, -0.01, -0.01]) cube([5.02, 10.02, 10.02]);  // Slight extension
}
```

---

### Issue 4.5: Module Parameter Scope

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :yellow_circle: MEDIUM |
| **Description** | Variables not accessible where expected due to OpenSCAD scoping |
| **Root Cause** | OpenSCAD has unusual scoping rules |
| **Warning Signs** | Parameters seem to be ignored, unexpected default values |

**Mitigation Strategies:**
- Pass all needed values as module parameters
- Avoid relying on global variables inside modules
- Use explicit parameter defaults
- Test modules in isolation

---

## CATEGORY 5: WORKFLOW ISSUES

### Issue 5.1: Going in Circles

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | Repeatedly making and reverting similar changes without progress |
| **Pattern** | Fix A breaks B, fix B breaks A, repeat |
| **Warning Signs** | User says "going in circles", similar errors recurring, iteration count high without progress |

**Mitigation Strategies:**
- STOP immediately when pattern detected
- Diagnose the underlying conflict causing the cycle
- Return to last known good version
- Address root cause before attempting fixes
- Consider if design needs restructuring

**Circle-Breaking Protocol:**
1. STOP making changes
2. Identify the two (or more) conflicting requirements
3. Determine if requirements are fundamentally incompatible
4. If compatible: find solution that satisfies both simultaneously
5. If incompatible: present tradeoff to user for decision
6. Implement chosen solution from clean baseline

---

### Issue 5.2: Premature Optimization

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :yellow_circle: MEDIUM |
| **Description** | Optimizing code before core functionality is stable |
| **Root Cause** | Desire to write "good" code before it works |
| **Warning Signs** | Time spent on performance when basic function is broken |

**Mitigation Strategies:**
- Get it working first, then optimize
- Stability before performance
- "Make it work, make it right, make it fast" - in that order
- Optimization is only valuable on stable code

---

### Issue 5.3: Big Bang Integration

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :orange_circle: HIGH |
| **Description** | Trying to add many features at once, then debugging the mess |
| **Root Cause** | Impatience, desire to show quick progress |
| **Warning Signs** | Large code changes, multiple new features per iteration |

**Mitigation Strategies:**
- Incremental integration: one feature at a time
- Verify each feature works before adding the next
- Small, testable changes
- If tempted to do multiple things, split into separate iterations

---

### Issue 5.4: Tunnel Vision

| Attribute | Details |
|-----------|---------|
| **Risk Level** | :yellow_circle: MEDIUM |
| **Description** | Focusing so hard on one problem that other issues are missed |
| **Root Cause** | Deep focus without periodic big-picture check |
| **Warning Signs** | Surprised by "obvious" problems, user points out issues not noticed |

**Mitigation Strategies:**
- Periodic holistic review (every 3-5 iterations)
- After fixing an issue, zoom out to check overall state
- Run full verification checklist periodically, not just targeted checks

---

## CHALLENGES & BLOCKERS TABLE

| Challenge | Likelihood | Impact | Mitigation Strategy |
|-----------|------------|--------|---------------------|
| Multi-mechanism synchronization | High | High | Break into smaller changes, verify each mechanism independently |
| Floating components | Medium | Critical | Power path verification after every component addition |
| User context switching | Medium | Medium | Maintain project state document, explicit decision logging |
| OpenSCAD limitations | Low | Medium | Workarounds documented in knowledge base, know the boundaries |
| Gear train complexity | High | High | Calculate all positions mathematically, never estimate |
| Z-layer conflicts | Medium | High | Maintain and verify Z-stack diagram |
| Animation timing | Medium | Medium | Test animation at multiple $t values, verify full cycle |
| Long conversation drift | High | Medium | Periodic state summaries, explicit locked decisions |
| Scope creep | High | High | Strict one-change-per-iteration discipline |
| Boolean operation artifacts | Medium | Medium | Use proper margins, avoid coincident faces |

---

## EARLY WARNING INDICATORS

| Indicator | What It Suggests | Immediate Action |
|-----------|------------------|------------------|
| User says "where is my X?" | Component regression | Run component survival checklist immediately |
| User says "going in circles" | Workflow stuck in loop | STOP, diagnose pattern, rollback to good version |
| User says "think hard" | Need deeper analysis | Slow down, question all assumptions, verify fundamentals |
| Code change >100 lines | Scope too large | Break into smaller iterations, get approval |
| >3 mechanisms affected | High regression risk | Pause, get explicit user approval before proceeding |
| Same error appears twice | Root cause not addressed | Stop fixing symptoms, find underlying cause |
| Animation suddenly breaks | Likely position/connection error | Check recent changes to moving components |
| "That's not what I meant" | Assumption mismatch | Clarify understanding before proceeding |
| Preview takes >5 seconds | Performance issue | Note for later optimization, continue with function |
| Iteration count >10 same issue | Fundamental problem | Step back, reassess approach entirely |

---

## RECOVERY DECISION TREE

```
Problem Detected
      |
      v
Is the problem in recently changed code?
      |
   Yes |  No
      |    |
      v    v
Can you identify --> Rollback to    Is it a known
the specific        last good       issue type?
breaking change?    version              |
      |                            Yes   |  No
   Yes |  No                        |    |
      |    |                        v    v
      v    v                   Use    Document new
Revert   Rollback to         issue-   issue type,
that     last good           specific analyze and
change   version             recovery develop
only                         protocol mitigation
```

---

## VERIFICATION CHECKLISTS

### Pre-Change Checklist
```
[ ] Identified specific scope of change
[ ] Listed all components that will be affected
[ ] Verified change doesn't violate any locked decisions
[ ] Confirmed change is minimal and targeted
[ ] Documented expected outcome
```

### Post-Change Checklist
```
[ ] All previously existing components still exist
[ ] Changed components function as expected
[ ] Unchanged components still function correctly
[ ] Animation runs smoothly through full cycle
[ ] No new warnings or errors in preview
[ ] Change matches documented expected outcome
```

### Component Survival Checklist
```
[ ] Count of gears matches expected
[ ] Count of linkages matches expected
[ ] Count of decorative elements matches expected
[ ] All named components present
[ ] Power path complete from motor to all outputs
```

### Mechanical Verification Checklist
```
[ ] All gear center distances calculated (not estimated)
[ ] All gear meshes verified (pitch circles tangent)
[ ] Z-layers verified (no collisions)
[ ] Rotation directions traced and correct
[ ] Linkage geometry satisfies Grashof (if applicable)
[ ] Power path complete and verified
```

---

## APPENDIX: COMMON FORMULAS

### Gear Calculations
```
Center Distance = (T1 + T2) * module / 2
Pitch Diameter = teeth * module
Outer Diameter = (teeth + 2) * module
Gear Ratio = T_driven / T_driver
```

### Linkage Calculations
```
Grashof Condition: s + l < p + q
  s = shortest link
  l = longest link
  p, q = other two links

If satisfied: at least one link can make full rotation
If not satisfied: all links limited to oscillation
```

### Animation
```
Full rotation: angle = $t * 360
Oscillation: angle = sin($t * 360) * amplitude
Synchronized: use same $t reference for all linked components
```

---

*Document Version: 1.0*
*Last Updated: 2025*
*Purpose: Proactive issue identification and mitigation for 3D Mechanical Design Agent*
