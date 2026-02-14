# REQUIRED PROJECT FILE STRUCTURE

**Every kinetic sculpture project MUST have this folder structure.**
**Agent MUST create these files IN ORDER - later files cannot exist without earlier ones.**

---

## Directory Structure

```
3d_design_agent/
├── projects/
│   └── [project_name]/
│       ├── 1_checklist.md          ← FIRST - Copy from templates/PROJECT_CHECKLIST.md
│       ├── 2_calculations.md       ← SECOND - Copy from templates/MECHANISM_CALCULATION.md
│       ├── 3_[project]_v1.scad     ← THIRD - Only after calculations approved
│       ├── 4_verification.md       ← FOURTH - After code renders without errors
│       └── assets/                 ← Screenshots, renders, photos
│           ├── mechanism_sketch.png
│           ├── render_t0.png
│           ├── render_t25.png
│           ├── render_t50.png
│           └── render_t75.png
```

---

## File Creation Rules

### Rule 1: Sequential Creation Only

Files MUST be created in numbered order:
1. `1_checklist.md` - Created at project start
2. `2_calculations.md` - Created after Checkpoint 2 (scene decomposition) complete
3. `3_[name]_v1.scad` - Created ONLY after all calculation gates pass
4. `4_verification.md` - Created after successful renders

**VIOLATION:** Creating file 3 before file 2 exists → BLOCKED

### Rule 2: Checklist Drives Everything

The `1_checklist.md` file is the source of truth:
- Agent MUST update checklist status after each action
- Agent MUST check current phase before any work
- Agent CANNOT skip to a later phase

### Rule 3: Calculations Before Code

The `2_calculations.md` file MUST contain:
- All numerical dimensions (no blanks or "TBD")
- Completed Grashof check (if four-bar)
- Coupler constancy verification with actual numbers
- Power budget with actual numbers

**VIOLATION:** Writing .scad code with blank calculations → BLOCKED

### Rule 4: Code Matches Calculations

Every dimension in the .scad file MUST:
- Match a value in `2_calculations.md`
- Be traceable to a calculation

**VIOLATION:** Dimension in code not in calculations → BLOCKED

### Rule 5: Verification Before "Done"

The `4_verification.md` file MUST exist with:
- Screenshots at t=0, 0.25, 0.5, 0.75
- Collision check results
- Final verification statement

**VIOLATION:** Declaring project complete without verification file → BLOCKED

---

## Pre-Flight Check

Before writing ANY .scad code, agent MUST verify:

```
□ Project folder exists: projects/[name]/
□ 1_checklist.md exists and Checkpoints 0-4 are COMPLETE
□ 2_calculations.md exists and all gates PASS
□ All numerical values filled in (no blanks)
□ Coupler length deviation < 0.5mm
□ Power margin ≥ 1.5x
□ All walls ≥ 1.2mm planned
□ All clearances ≥ 0.3mm planned
```

If ANY check fails → DO NOT WRITE CODE

---

## Enforcement Statements

**Add these to the start of every design conversation:**

```
DESIGN AGENT ENFORCEMENT ACTIVE

I will:
1. Create project folder and checklist FIRST
2. Complete calculations with ACTUAL NUMBERS before code
3. Verify coupler constancy at 4 positions
4. STOP if any gate fails
5. Show verification report before declaring complete

I will NOT:
- Write .scad code before calculations exist
- Use arbitrary sin($t) without mechanism trace
- Skip phases even if asked
- Declare "done" without verification file
```

---

## Quick Reference: What Blocks Progress

| Situation | Blocked At | Resolution |
|-----------|------------|------------|
| Coupler length varies > 0.5mm | Checkpoint 3 | Redesign geometry |
| Non-Grashof + needs 360° rotation | Checkpoint 3 | Choose different mechanism |
| Dead point in operating range | Checkpoint 3 | Add flywheel or limit range |
| Power margin < 1.5x | Checkpoint 4 | Simplify or add power |
| Gravity > driving torque | Checkpoint 4 | Add counterweight |
| Orphan sin($t) in code | Checkpoint 5 | Add physical mechanism |
| Collision at any t value | Checkpoint 6 | Fix geometry |
| No verification file | Checkpoint 6 | Complete verification |

---

## Example: Correct Project Creation

```
User: "Create a water-powered fish sculpture"

Agent:
1. mkdir projects/water_fish/
2. cp templates/PROJECT_CHECKLIST.md projects/water_fish/1_checklist.md
3. Fill in Checkpoint 0 (discovery) - ask user questions
4. Update checklist: Checkpoint 0 = COMPLETE
5. Fill in Checkpoint 1 (feasibility) - score risks, pick mechanism
6. Update checklist: Checkpoint 1 = COMPLETE
7. Fill in Checkpoint 2 (decomposition) - list all parts
8. Update checklist: Checkpoint 2 = COMPLETE
9. cp templates/MECHANISM_CALCULATION.md projects/water_fish/2_calculations.md
10. Fill in ALL calculations with numbers
11. Verify: Coupler constancy? Power margin? Walls? Clearances?
12. Update checklist: Checkpoints 3 & 4 = COMPLETE
13. NOW create projects/water_fish/3_water_fish_v1.scad
14. Render at 4 positions, check for collisions
15. Create projects/water_fish/4_verification.md
16. Show verification report to user
17. Update checklist: Checkpoints 5 & 6 = COMPLETE
18. DONE
```
