# PROJECT CHECKPOINT SYSTEM

**HARD RULE: Each phase MUST be completed before the next begins.**
**HARD RULE: Agent MUST create/update this file for every new design.**

Project: _______________
Created: _______________

---

## CHECKPOINT 0: DISCOVERY
**Purpose:** Understand what the user actually wants

- [ ] User intent captured in plain language
- [ ] Motion character identified: [ ] flowing / [ ] precise / [ ] snappy / [ ] gentle
- [ ] Emotional goal identified: [ ] calm / [ ] energized / [ ] curious / [ ] amazed
- [ ] Complexity constraint: [ ] simple (1-2 parts) / [ ] moderate (3-5) / [ ] complex
- [ ] Physical constraints listed (size, printability, durability)

**GATE:** Cannot proceed until user confirms understanding is correct.

Discovery notes:
```
[Write user requirements here in plain language]
```

**Status:** [ ] NOT STARTED / [ ] IN PROGRESS / [ ] COMPLETE
**Date completed:** _______________

---

## CHECKPOINT 1: FEASIBILITY
**Purpose:** Verify the design is physically possible before detailing

- [ ] Failure pattern risk scores calculated (all 11 patterns)
- [ ] Any pattern score > 80? [ ] NO / [ ] YES → Which: _______________
- [ ] Mechanism alternatives considered (minimum 3)
- [ ] Mechanism selected with justification
- [ ] Van Gogh vs Watt conflict? [ ] NO / [ ] YES → User chose: _______________

**GATE:** Cannot proceed if any risk score > 80 without mitigation plan.

Feasibility notes:
```
[Write mechanism choice and reasoning here]
```

**Status:** [ ] NOT STARTED / [ ] IN PROGRESS / [ ] COMPLETE
**Date completed:** _______________

---

## CHECKPOINT 2: SCENE DECOMPOSITION
**Purpose:** Classify every element as STATIC or MOVING

| Element | Static/Moving | Motion Type | Physical Part |
|---------|---------------|-------------|---------------|
| | [ ] S / [ ] M | | |
| | [ ] S / [ ] M | | |
| | [ ] S / [ ] M | | |
| | [ ] S / [ ] M | | |

- [ ] All elements classified
- [ ] No shape morphing (shapes are FIXED)
- [ ] All motion is position OR rotation only

**GATE:** Cannot proceed if any element is ambiguous.

**Status:** [ ] NOT STARTED / [ ] IN PROGRESS / [ ] COMPLETE
**Date completed:** _______________

---

## CHECKPOINT 3: MECHANISM DESIGN
**Purpose:** Define exact geometry with numbers

**MANDATORY FILE:** `calculations/[project]_mechanism.md` must exist

- [ ] Calculation file created from template
- [ ] All link lengths filled in with actual numbers
- [ ] Grashof check completed (if four-bar): Result = _______________
- [ ] Dead point analysis completed (if four-bar)
- [ ] Coupler length constancy verified at t=0, 0.25, 0.5, 0.75
  - Max deviation: _____ mm (must be < 0.5mm)
- [ ] Power path traced: Motor/Source → ___ → ___ → ___ → Output

**GATE:** Cannot proceed if:
- Coupler length varies > 0.5mm (geometry impossible)
- Non-Grashof but requires 360° rotation
- Dead point in operating range without mitigation

**Status:** [ ] NOT STARTED / [ ] IN PROGRESS / [ ] COMPLETE
**Date completed:** _______________

---

## CHECKPOINT 4: PHYSICS VALIDATION
**Purpose:** Verify it will actually work in the real world

- [ ] Power budget calculated
  - Available: _____ W
  - Required: _____ W
  - Margin: _____x (must be ≥ 1.5x)
- [ ] Gravity analysis (if mass > 50g)
  - Max gravity torque: _____ N·mm
  - Available torque: _____ N·mm
- [ ] Tolerance stack
  - Joint count: _____
  - Worst-case stack: _____ mm
  - Acceptable: [ ] YES / [ ] NO → Mitigation: _______________

**GATE:** Cannot proceed if:
- Power margin < 1.5x
- Gravity torque > available torque at any position

**Status:** [ ] NOT STARTED / [ ] IN PROGRESS / [ ] COMPLETE
**Date completed:** _______________

---

## CHECKPOINT 5: CODE GENERATION
**Purpose:** Write .scad code that matches the validated design

**MANDATORY:** Every sin($t) or cos($t) must trace to a physical mechanism

- [ ] Code file created: `[project]_v1.scad`
- [ ] All dimensions match calculation file
- [ ] sin($t) audit:
  | Line | Expression | Physical Driver | Connected? |
  |------|------------|-----------------|------------|
  | | | | [ ] Y / [ ] N |
  | | | | [ ] Y / [ ] N |
  | | | | [ ] Y / [ ] N |
- [ ] Power path echo statement included
- [ ] Printability checks included (wall ≥1.2mm, clearance ≥0.3mm)

**GATE:** Cannot proceed if any sin($t) is orphaned (no physical driver).

**Status:** [ ] NOT STARTED / [ ] IN PROGRESS / [ ] COMPLETE
**Date completed:** _______________

---

## CHECKPOINT 6: VERIFICATION
**Purpose:** Confirm the design works before declaring "done"

- [ ] Render test at t=0: [ ] No collision / [ ] No self-intersection
- [ ] Render test at t=0.25: [ ] No collision / [ ] No self-intersection
- [ ] Render test at t=0.5: [ ] No collision / [ ] No self-intersection
- [ ] Render test at t=0.75: [ ] No collision / [ ] No self-intersection
- [ ] Build volume fits printer: _____ × _____ × _____ mm
- [ ] BOM generated with all parts listed
- [ ] Verification report shown to user

**FINAL GATE:** Design is NOT complete until user sees verification report.

**Status:** [ ] NOT STARTED / [ ] IN PROGRESS / [ ] COMPLETE
**Date completed:** _______________

---

## PROJECT STATUS

| Checkpoint | Status | Blocker? |
|------------|--------|----------|
| 0 - Discovery | | |
| 1 - Feasibility | | |
| 2 - Decomposition | | |
| 3 - Mechanism | | |
| 4 - Physics | | |
| 5 - Code | | |
| 6 - Verification | | |

**Current Phase:** _______________
**Next Action:** _______________
**Blocked:** [ ] NO / [ ] YES → Reason: _______________
