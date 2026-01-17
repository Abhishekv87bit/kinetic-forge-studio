# 3D MECHANICAL DESIGN AGENT - QUICK REFERENCE

---

## USER'S VISION QUICK REFERENCE (V44-V47)

> **ALL DESIGNS MUST IMPLEMENT USER'S VISION, NOT REFERENCE PHOTO**

```
+===============================================================================+
|                    STARRY NIGHT - USER'S MODIFIED VISION                     |
+===============================================================================+
|                                                                               |
| KEY DIFFERENCES FROM REFERENCE PHOTO:                                         |
|   - Clock-style gear mesh (NO BELTS)                                         |
|   - Four-bar linkage waves (NOT simple drift)                                |
|   - Rice tube mechanism (FUNCTIONAL)                                         |
|   - Bird carrier system (NOT decorative flock)                               |
|   - Moon: VERY SLOW (0.1x)                                                   |
|   - Lighthouse: SLOW (0.3x)                                                  |
|                                                                               |
| FOUR-BAR PARAMETERS (LOCKED):                                                 |
|   Crank=10mm, Ground=25mm, Coupler=30mm, Rocker=25mm                         |
|   Wave phases: [0, 30, 60, 90, 120] degrees                                  |
|                                                                               |
| ZONE CHANGES FROM REFERENCE:                                                  |
|   - ZONE_BOTTOM_GEARS moved to LEFT [0, 78, 0, 80]                           |
|   - ZONE_BIRD_WIRE specific Y range [0, 302, 81, 97]                         |
|   - Cliff: +20% scale, flush LEFT/BOTTOM                                     |
|   - Cypress: 30% bigger, flush BOTTOM                                        |
|                                                                               |
| BASE REFERENCE: V47 (starry_night_v47_assembly.scad)                         |
+===============================================================================+
```

### Component Survival Checklist (User's Vision)

```
GEAR TRAIN (11+ gears, NO BELTS):
[ ] Motor pinion (10T)     [ ] Idler 4 (18T)
[ ] Master gear (60T)      [ ] Idler 5 (18T)
[ ] Sky drive (20T)        [ ] Idler 6 (18T)
[ ] Wave drive (30T)       [ ] Big swirl gear (24T)
[ ] Idler 1 (18T)          [ ] Small swirl gear (24T)
[ ] Idler 2 (18T)          [ ] Moon gear (48T)
[ ] Idler 3 (18T)          [ ] Lighthouse gear (36T)

FOUR-BAR MECHANISM:
[ ] Camshaft (100mm)       [ ] Wave layers x5
[ ] Crank discs x5         [ ] Drive gear (30T)
[ ] Coupler rods x5

SPECIAL MECHANISMS:
[ ] Rice tube + linkage    [ ] Bird carrier bracket
[ ] Bird wire system       [ ] Wind path (with holes)
[ ] Gear support plate (skeleton)
```

---

## GOLDEN RULES

```
+===================================================================+
|                         10 GOLDEN RULES                           |
+===================================================================+
|  1. THE STABLE BASE IS SACRED                                     |
|     Working code > "better" code that breaks things               |
|                                                                   |
|  2. TRACE THE POWER PATH                                          |
|     Motor -> Gear -> Linkage -> Output must be unbroken           |
|                                                                   |
|  3. BOUNDARIES ARE IMMUTABLE                                      |
|     Lock zones, coord systems, timing = fixed unless asked        |
|                                                                   |
|  4. VIEWER POV MATTERS                                            |
|     "Left" = user's left, not model's left                        |
|                                                                   |
|  5. V[N] = V[N-1] + (changes) - (nothing)                         |
|     Only add what's requested, remove nothing else                |
|                                                                   |
|  6. WHEN IN DOUBT, ASK                                            |
|     Question = seconds, wrong assumption = hours                  |
|                                                                   |
|  7. DOCUMENT EVERYTHING                                           |
|     Version deltas, change logs, survival checks                  |
|                                                                   |
|  8. TEST AT MULTIPLE $t VALUES                                    |
|     Always: 0.0, 0.25, 0.5, 0.75, 1.0                             |
|                                                                   |
|  9. PHYSICS ALWAYS WINS                                           |
|     Code ignores collisions; reality does not                     |
|                                                                   |
| 10. USER'S VISION DRIVES EVERYTHING                               |
|     Your expertise serves their design                            |
+===================================================================+
```

---

## SKILLS QUICK REFERENCE

| Skill | Syntax | Purpose |
|-------|--------|---------|
| `/gear-calc` | `teeth1=T1 teeth2=T2 module=M` | Calculate gear mesh geometry & center distance |
| `/linkage-check` | `ground=G crank=C coupler=L rocker=R` | Validate 4-bar linkage, Grashof test |
| `/svg-extract` | `file=PATH target_width=W` | Extract REAL coordinates from SVG (never placeholders) |
| `/component-survival` | `file=PATH` | Verify all components exist after edits |
| `/version-diff` | `file_old=V1 file_new=V2 intent="..."` | Ensure only intended changes occurred |
| `/z-stack` | `file=PATH min_clearance=C` | Analyze Z-layers, detect collisions |

---

## HOOK TRIGGERS

| User Says | Action |
|-----------|--------|
| "going in circles" | STOP -> Diagnose pattern -> Rollback to last good |
| "where is my [X]?" | Run survival checklist -> Find when X was lost |
| "think hard" | Extended analysis -> Question assumptions |
| "verify this works" | Full feasibility check with diagrams |
| "this is broken" | STOP all changes -> Audit recent modifications |
| "just make it right" | STOP -> Ask for specific requirements |
| "start over" | STOP -> Confirm: "Delete all [N] components?" |
| "clean up the code" | Ask: "Formatting only or structural?" |

---

## KEY FORMULAS

### Gear Mesh
```
Center Distance = (T1 + T2) x module / 2
Pitch Radius   = teeth x module / 2
Gear Ratio     = T_driven / T_driver
```

### Grashof Condition (4-Bar Linkage)
```
Sort links: s(shortest), l(longest), p, q

s + l < p + q  -->  Grashof (one link can rotate 360)
s + l > p + q  -->  Non-Grashof (all links oscillate)
s + l = p + q  -->  Change-point (special case)
```

### Version Formula
```
V[N] = V[N-1] + (targeted changes) - (nothing else)
```

### Standard Clearances
| Type | Value |
|------|-------|
| Sliding fit | 0.1-0.2mm |
| Gear backlash | 0.04 x module |
| 3D print tolerance | +0.2-0.4mm |
| Motion clearance | 2.0mm min |

---

## COMPONENT SURVIVAL CHECKLIST (Abbreviated)

```
STRUCTURAL          DRIVE TRAIN         MECHANISM
[ ] Back wall       [ ] Motor mount     [ ] Crank arm
[ ] Left wall       [ ] Pinion gear     [ ] Coupler link
[ ] Right wall      [ ] Master gear     [ ] Rocker/output
[ ] Mounting tabs   [ ] Center dist     [ ] Wave layers

CONNECTIONS
[ ] Motor -> Pinion (coaxial)
[ ] Pinion <-> Master (meshed at CD)
[ ] Master -> Crank (attached)
[ ] Crank -> Coupler (pivot)
[ ] Coupler -> Output (pivot)
```

**After EVERY edit:** Count matches? Positions same? Sizes same? $t timing preserved?

---

## EMERGENCY RECOVERY

### Component Missing?
```
1. /component-survival  --> Find what's missing
2. /version-diff        --> Find when it disappeared
3. Restore from last version containing it
4. Re-run /component-survival to confirm
```

### Z-Collision Detected?
```
1. /z-stack             --> Get collision report
2. Apply recommended Z adjustments
3. /gear-calc           --> Recalculate if gears moved
4. /z-stack             --> Verify resolution
```

### Linkage Won't Move?
```
1. /linkage-check       --> Verify Grashof condition
2. If NON-GRASHOF: adjust link lengths
3. Check transmission angle (must be > 40 deg)
4. Re-run /linkage-check
```

### Going in Circles?
```
1. STOP immediately
2. Review last 5 exchanges
3. Identify the loop pattern
4. Return to last confirmed working version
5. Try different approach
```

### User Frustrated?
```
1. Acknowledge and STOP
2. Run emergency audit
3. Present timeline of recent changes
4. Identify breaking change
5. Propose rollback, await direction
```

---

## FILE LOCATIONS

| File | Purpose |
|------|---------|
| `unified_system_prompt.md` | Core agent identity, rules, workflow |
| `skills.md` | 6 skill definitions with full syntax |
| `hooks.md` | Trigger phrases and automated responses |
| `sub_agents.md` | Specialized sub-agent definitions |
| `issues_and_mitigations.md` | Known problems and solutions |
| `master_specification_template.md` | Project spec template |
| `QUICK_REFERENCE.md` | This file |

**All files in:** `D:\Claude local\3d_design_agent\`

---

## BEFORE / AFTER CHECKLISTS

### Before ANY Change
```
[ ] Understand the request?
[ ] Minimal change identified?
[ ] What could break?
[ ] Lock zones marked?
```

### After ANY Change
```
[ ] Survival checklist passed?
[ ] Tested at multiple $t?
[ ] Version delta documented?
[ ] No regressions?
```

---

## QUICK DECISION TREE

```
User wants change?
    |
    v
Is it clear? --NO--> ASK for specifics
    |
   YES
    v
Run /component-survival (before)
    |
    v
Make MINIMAL change
    |
    v
Run /version-diff (verify intent only)
    |
    v
Run /component-survival (after)
    |
    v
Run /z-stack (if positions changed)
    |
    v
DELIVER with documentation
```

---

*Version 1.0 | Quick lookup during active work*
