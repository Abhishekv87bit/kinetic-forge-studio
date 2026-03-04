# Universal Kinetic Validator — Completion Plan Prompt

## Date: 2026-03-04
## Purpose: Start a plan-mode session to close ALL remaining gaps in `tools/validate_kinetic.py`

---

## Use This Prompt to Start a New Session

Copy everything below the line into a new Claude Code session. It contains all context needed to complete the validator without reading previous conversations.

---

## SESSION PROMPT

I need to complete the Universal Kinetic Sculpture Geometry Validator (`tools/validate_kinetic.py`). This is an 8-tier validation framework for CadQuery kinetic sculpture production scripts.

### Reference Files (read these first)
- **Spec**: `docs/plans/2026-03-03-universal-validation-spec.md` — defines all 35 checks across 8 tiers
- **Implementation**: `tools/validate_kinetic.py` — current code (~710 lines)
- **Rule 99 config**: `kinetic-forge-studio/backend/data/rule99_config.yaml` — consultant-to-tier mapping
- **Test module**: `3d_design_agent/triple_helix_mvp/5.5/cadquery/matrix_tier_production.py` — working production module to test against

### Current State (from 2026-03-04 audit)

**23 of 35 checks fully implemented. 11 stubs. 1 missing. 1 deviation.**

The validator runs, builds geometry, and catches real issues. But 12 checks are either missing, stubbed, or deviated from spec. Here's the complete breakdown:

---

### CATEGORY A: Build These — Generic Implementation Possible

These checks CAN be implemented without project-specific data. They use optional interfaces that modules MAY expose. If the interface isn't present, report INFO with instructions.

#### A1. F5 — Friction Cascade (MISSING — no code at all)
- **Spec**: For `mechanism_type == 'cable'`, compute `efficiency = 0.95^n`. WARN if `n > 9`.
- **Interface needed**: `get_cable_stages() -> int` (number of pulley stages)
- **Action**: Add to `tier7_functional()`. Guard with `mechanism_type == 'cable'`. Check `hasattr(module, 'get_cable_stages')`. If missing, INFO. If present, compute and WARN if n > 9.
- **Blocking**: WARN (cable only)

#### A2. F1/F2/F3 — Grashof, Transmission Angle, Coupler Constancy (STUBS — grouped into single INFO)
- **Spec**: Three separate checks for `mechanism_type == 'linkage'`:
  - F1: `s + l <= p + q` (Grashof condition) — FAIL if cannot complete rotation
  - F2: Check transmission angle at 0/90/180/270 deg — FAIL if <40 or >140 deg
  - F3: Measure coupler length at 4 positions — FAIL if varies >0.1mm
- **Interface needed**: `get_link_lengths() -> dict` with keys `{'s': float, 'l': float, 'p': float, 'q': float}` (shortest, longest, remaining two links)
- **Action**: Split current single-INFO F1 into three separate checks with three result IDs. Guard with `mechanism_type == 'linkage'`. Check `hasattr(module, 'get_link_lengths')`. If missing, three separate INFOs. If present, run actual Grashof/transmission/coupler math.
- **Blocking**: YES (linkage only)

#### A3. F4 — Power Budget (STUB — reports INFO)
- **Spec**: Required torque < available / 2. WARN if underpowered.
- **Interface needed**: `get_motor_spec() -> dict` with keys `{'torque_nm': float, 'speed_rpm': float}`
- **Action**: Check `hasattr(module, 'get_motor_spec')`. If missing, INFO. If present, estimate required torque from moving part masses and travel speeds, compare to motor spec / 2.
- **Blocking**: WARN

#### A4. K3 — Engagement at Extremes (STUB — not in code)
- **Spec**: At min/max travel, check that moving part still overlaps its guide/rail. Overlap volume = 0 means disengaged.
- **Interface needed**: `get_guide_rails() -> dict[str, cq.Workplane]` mapping moving part names to their guide/rail geometry
- **Action**: Add to `tier4_dynamic()`. For each moving part, displace to min and max travel, check `intersection_volume(displaced, guide_rail) > 0`. If overlap = 0, FAIL (disengaged from guide).
- **Blocking**: YES

#### A5. K4 — Dead Point Detection (STUB — not in code)
- **Spec**: For linkages, check transmission angle at 0/90/180/270 deg. FAIL if <40 or >140 deg.
- **Interface needed**: `get_link_lengths()` (same as F2)
- **Action**: Add to `tier4_dynamic()`. Guard with `mechanism_type == 'linkage'`. Compute transmission angle at 4 positions using four-bar kinematics. FAIL if any angle outside 40-140 range.
- **Blocking**: YES (linkage only)
- **Note**: K4 and F2 overlap in purpose. Consider sharing the computation.

#### A6. C2 — Rotating Clearance (STUB — not in code)
- **Spec**: For shafts/bearings, check `bore_dia - shaft_dia`. FAIL if gap < 0.1mm.
- **Interface needed**: `get_shaft_bore_pairs() -> list[tuple[str, str, float, float]]` — (shaft_name, bore_name, shaft_dia, bore_dia)
- **Action**: Add to `tier5_clearance()`. Simple arithmetic check: `bore_dia - shaft_dia >= 0.1`. FAIL if too tight.
- **Blocking**: YES

#### A7. D2 — Volume Stability (STUB — documented)
- **Spec**: Compare current volume to stored reference. WARN if >5% drift.
- **Interface needed**: `get_reference_volumes() -> dict[str, float]` — (part_name → reference_volume_mm3)
- **Action**: Add to `tier2_dimensional()`. For each part with a reference, compare current volume. WARN if drift > 5%.
- **Blocking**: WARN

#### A8. D3 — Symmetry Verification (STUB — documented)
- **Spec**: Mirror and intersect. WARN if asymmetric when shouldn't be.
- **Interface needed**: `get_symmetry_spec() -> dict` with keys `{'axis': str, 'parts': list[str]}` — which parts should be symmetric about which axis
- **Action**: Add to `tier2_dimensional()`. Mirror specified parts about specified axis, compute intersection volume. If `mirror_vol / original_vol < 0.95`, WARN (asymmetric).
- **Blocking**: WARN

#### A9. M1 — Min Wall Thickness (STUB — documented)
- **Spec**: Ray-cast or section analysis. WARN if wall < 1.2mm (FDM).
- **Interface needed**: None (can be computed from geometry alone, but computationally expensive)
- **Action**: Implement using CadQuery section analysis. For each part, take cross-sections at multiple Z heights. Measure minimum wall thickness in each section. WARN if < 1.2mm.
- **Implementation approach**: Use `cq.Workplane.section()` at 5 Z heights per part. Measure minimum wire-to-wire distance. This is an approximation — true wall thickness analysis would need ray-casting.
- **Blocking**: WARN
- **Note**: This is the most computationally expensive check. Consider making it optional via a `--full` CLI flag.

---

### CATEGORY B: Fix These — Code Exists but Deviates from Spec

#### B1. Applicability Matrix Not Enforced
- **Spec** (section "Applicability Matrix"): Different checks fire for different `mechanism_type` values. E.g., F6 only for slider, F1-F3 only for linkage, F5 only for cable.
- **Current code**: ALL checks run for ALL mechanism types. Only F6 and F1 are conditional.
- **Action**: After loading mechanism_type, build a set of applicable check IDs. Skip non-applicable checks with INFO noting "not applicable for {mechanism_type}".
- **Impact**: Reduces noise. Currently a `cam` mechanism would get F6 slider end-stop checks, which is meaningless.

#### B2. Optional Interfaces Not in Docstring
- **Current**: Module docstring (lines 9-16) only documents `get_clearance_pairs()` and `get_assembly()`.
- **Missing from docstring**: `get_envelope()`, `get_link_lengths()`, `get_motor_spec()`, `get_cable_stages()`, `get_guide_rails()`, `get_shaft_bore_pairs()`, `get_reference_volumes()`, `get_symmetry_spec()`
- **Action**: Add all optional interfaces to the module docstring with their return types.

#### B3. E1 Blocking Status
- **Spec**: E1 solid count mismatch is **YES** (blocking/FAIL).
- **Current code**: Reports as **WARN** when count mismatches.
- **Action**: Change WARN to FAIL for E1 solid count mismatch. Or reconsider — a count mismatch between STEP export and CadQuery model might be a WARN-level concern if the STEP was exported from a different version.
- **Decision needed**: Keep as WARN (pragmatic) or change to FAIL (spec-compliant)?

---

### CATEGORY C: Leave As-Is — Intentionally Not Implemented

These are correctly documented as stubs in the file header. They genuinely need project-specific data that can't be inferred from geometry alone. Leave them as INFO-level reports with clear instructions on which interface to implement.

- D2 Volume stability — needs stored baseline (no "first run" yet)
- D3 Symmetry — needs user to specify symmetry expectations
- M1 Wall thickness — computationally prohibitive for large models (make optional)

---

### IMPLEMENTATION ORDER

```
Phase 1: Quick wins (30 min)
  B1. Applicability matrix guard — add mechanism_type gating
  B2. Update docstring with all optional interfaces
  A6. C2 rotating clearance — simple arithmetic, no geometry
  A1. F5 friction cascade — simple 0.95^n formula

Phase 2: Linkage checks (45 min)
  A2. F1/F2/F3 split — three separate checks with four-bar math
  A5. K4 dead point detection — transmission angle at 4 positions

Phase 3: Conditional checks (45 min)
  A3. F4 power budget — torque estimation from geometry
  A4. K3 engagement at extremes — guide rail overlap
  A7. D2 volume stability — reference comparison
  A8. D3 symmetry verification — mirror-and-intersect

Phase 4: Computationally intensive (30 min)
  A9. M1 wall thickness — section analysis (make optional with --full flag)

Phase 5: Final cleanup (15 min)
  B3. E1 blocking decision
  Add --full CLI flag for expensive checks
  Re-run against matrix_tier_production.py
  Verify 0 unexpected FAILs
  Commit
```

### Verification Checklist

After implementation, run:
```bash
python tools/validate_kinetic.py 3d_design_agent/triple_helix_mvp/5.5/cadquery/matrix_tier_production
```

Expected results:
- All T1-T6 checks: PASS (geometry is clean)
- All D checks: PASS or INFO (no envelope/reference defined)
- All S1-S3: PASS (no static collisions)
- All K1-K2: PASS (no dynamic collisions)
- K3: INFO (no get_guide_rails())
- K4: INFO (mechanism_type != linkage)
- K5: PASS (valid drivers)
- C1: PASS (adequate sliding clearance)
- C2: INFO (no get_shaft_bore_pairs())
- C3: not checked (no get_clearance_pairs())
- C4: PASS (no trapped parts excluding housing)
- M1: INFO or WARN (if --full, might find thin walls)
- M2: PASS (parts fit printer)
- M3: INFO (mass estimate)
- F1-F3: INFO (mechanism_type != linkage)
- F4: INFO (no get_motor_spec())
- F5: INFO (mechanism_type != cable)
- F6: FAIL (14 — sliders lack physical end stops — this is a REAL design finding)
- E1: WARN (stale STEP files — count mismatch)
- E2: PASS (STEP topology valid)
- E3: WARN (stale STEP — volume drift)
- E4: INFO (no get_assembly())

The only blocking FAILs should be the 14 F6 end-stop findings (legitimate design issue in matrix_tier_production.py).

### Code Quality Requirements
- Follow existing patterns (result.add with check_id, status, detail)
- Use `hasattr(module, 'get_xxx')` pattern for optional interfaces
- Guard mechanism-specific checks with `if mechanism_type == '...'`
- Keep INFO messages instructive: "implement get_xxx() for full check"
- Add `--full` flag for expensive checks (M1 wall thickness)
- Run `python -c "import ast; ast.parse(open('tools/validate_kinetic.py').read())"` before testing
- All new checks must have test coverage via the matrix_tier_production module
