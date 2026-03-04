# Ravigneaux Unit — Component Issues Log
# Every new component MUST be verified against ALL items below before delivery.

## ISSUE-001: Shaft overextension below gear
- **Component:** Ss shaft (Component 1), SL shaft (Component 2)
- **Problem:** Shaft tube extended below the gear face, creating unnecessary material
- **Root cause:** SHAFT_ZBOT set to a value lower than the gear zone bottom
- **Fix:** SHAFT_ZBOT = ZONE_BOT (gear bottom IS shaft bottom)
- **Rule:** No shaft material below the gear face. Ever.

## ISSUE-002: Herringbone halves misaligned
- **Component:** Ss shaft (Component 1)
- **Problem:** Two helical halves didn't meet cleanly at the center — visible gap/step
- **Root cause:** Each half was pre-rotated by +/-twist/2 independently, causing angular offset at the meeting line
- **Fix:** Switched to SatisfyingGears library with Layers=2 (handles alignment internally)
- **Rule:** Always use library's built-in herringbone (Layers=2), never hand-roll two halves.

## ISSUE-003: Transparent pitch circle disc rendered
- **Component:** Ss shaft (Component 1)
- **Problem:** A ghost `%` reference circle appeared as a flat disc at gear center
- **Root cause:** Debug reference geometry left in the code
- **Fix:** Removed the reference geometry
- **Rule:** No debug/reference geometry in delivered components.

## ISSUE-004: Spline teeth too thick
- **Component:** Ss shaft (Component 1)
- **Problem:** Spline ridges were visually chunky, not industry-standard proportions
- **Root cause:** SPLINE_DEPTH=0.8mm on 9mm OD (~9% of OD — too aggressive)
- **Fix:** SPLINE_DEPTH=0.3mm, SPLINE_COUNT=12 (~3% of OD, per SAE/ANSI B92.1)
- **Rule:** Spline depth = 2-5% of shaft OD. Fine pitch (more teeth, shallower).

## ISSUE-005: Spline teeth/grooves unequal width
- **Component:** Ss shaft (Component 1)
- **Problem:** Spline teeth were wider than grooves (55/45 split)
- **Root cause:** groove_ang = tooth_ang * 0.45 (not 0.5)
- **Fix:** groove_ang = tooth_ang * 0.5 (50/50 duty cycle)
- **Rule:** Always 50/50 duty cycle on splines unless explicitly specified otherwise.

## ISSUE-006: Component built as separate bodies
- **Component:** Ss shaft (Component 1)
- **Problem:** Gear, shaft tube, and splines were separate colored blocks with visible seams
- **Root cause:** Each section built independently, not unified
- **Fix:** Single difference(union(tube + gear + splines), bore, grooves, chamfer)
- **Rule:** Every component = ONE unified solid. Single difference(), single bore subtraction.

## ISSUE-007: Stale comments after parameter changes
- **Component:** SL shaft (Component 2)
- **Problem:** Comments referenced old values (e.g. "clears Ss OD 9mm" after OD changed to 8mm)
- **Root cause:** Comments hardcoded numbers instead of referencing parameter names
- **Fix:** Update comments to reference parameter names or remove hardcoded values
- **Rule:** Comments should reference parameter NAMES not hardcoded numbers.

## ISSUE-008: Thrust washer OD interfered with gear mesh
- **Component:** Thrust washer (between Ss and SL)
- **Problem:** Washer OD extended to Ss pitch circle, would collide with planet teeth
- **Root cause:** OD sized to "cover pitch circle + margin" instead of staying inside root circle
- **Fix:** THRUST_OD = (T_SS - 2.5) / DP — inside the gear dedendum (root circle)
- **Rule:** Any washer/spacer near gears must have OD < root circle of the smaller gear.

## ISSUE-009: Missing industry-standard features not proactively suggested
- **Component:** All
- **Problem:** User had to ask for thrust washer — should have been suggested proactively
- **Root cause:** Not maintaining a mental checklist of standard transmission internals
- **Fix:** Proactively suggest these features for every rotating interface:
  - Thrust washers between axially-loaded faces
  - Needle bearings or bushings between concentric shafts
  - Snap ring grooves for axial retention
  - Oil channels/grooves for lubrication paths
  - Edge chamfers/breaks on all sharp corners
  - Keyways or pin holes for torque transfer
- **Rule:** Every new component delivery must include proactive suggestions for missing standard features.

## ISSUE-010: Tooth count sync across files — RESOLVED
- **Component:** Ss shaft (Component 1), SL shaft (Component 2)
- **Problem:** Planets evolved from ZAR8 counts (T_SL=46) to reduced SL (T_SL=30) for carrier clearance. Sun shaft file had stale T_SS=24, T_SL=40.
- **Root cause:** Tooth counts changed in planets file after sun shafts were approved
- **Fix:** Updated ravigneaux_unit.scad to match planets. Then T_SL bumped 30→32 for Po-Ss clearance (ISSUE-012).
- **Final values (both files in sync):** T_SS=26, T_SL=32, T_PO=24, T_PI=19, T_RING=80
- **Ring constraint:** 32 + 2×24 = 80 ✓ (exact, no profile shifts needed)
- **Rule:** When tooth counts change, ALL files sharing those constants must be updated in sync.

## ISSUE-011: Carrier clearance — Ss addendum vs Pi pin corridor
- **Component:** Carrier (Component 5), Ss sun (Component 1)
- **Problem:** Carrier arm must pass through radial gap between Ss outer edge and Pi pin axis
- **Current gap:** ~4mm usable after clearances (Ss addendum R=10.82mm, Pi orbit=17.38mm)
- **Options:** (a) Negative profile shift on Ss to reduce addendum, (b) shorter addendum coefficient, (c) reduce T_SS (changes geometry), (d) narrow carrier arm design
- **Status:** DEFERRED — user will decide when building carrier (Component 5)
- **Rule:** Verify carrier arm width vs Ss-Pi radial corridor before finalizing carrier design.

## ISSUE-012: Po inner edge touching Ss outer edge — RESOLVED
- **Component:** Po planet (Component 3) vs Ss sun (Component 1)
- **Problem:** Po physically extends into Ss zone (Z=0–6) to mesh with Pi. At T_SL=30, T_SS=26, the radial gap formula (T_SL - T_SS - 4) / (2·DP) = 0 — literally zero clearance.
- **Root cause:** Gap = (T_SL - T_SS - 4) / (2·DP). When T_SL - T_SS = 4, gap is exactly zero.
- **Fix:** T_SL 30→32, T_PO 25→24. Gap = (32-26-4)/(2·DP) = 0.77mm. Ring constraint still exact: 32+48=80.
- **Rule:** Always verify Po-Ss clearance: require T_SL - T_SS > 4 (ideally ≥ 6 for 1.5mm+ gap).

---

## PRE-DELIVERY CHECKLIST (run for EVERY new component)
- [ ] ISSUE-001: Shaft bottom = gear face bottom? No overextension?
- [ ] ISSUE-002: Herringbone uses Layers=2 from library? No hand-rolled halves?
- [ ] ISSUE-003: No debug/reference geometry (%, #, ghost shapes)?
- [ ] ISSUE-004: Spline depth = 2-5% of OD? Fine pitch proportions?
- [ ] ISSUE-005: Spline duty cycle = 50/50?
- [ ] ISSUE-006: Single unified solid? One difference(), one bore?
- [ ] ISSUE-007: Comments reference param names, not hardcoded numbers?
- [ ] Zero compile errors, zero warnings?
- [ ] All clearance checks pass?
- [ ] Lead-in chamfer on splines for assembly?
- [ ] ISSUE-008: Washers/spacers OD < root circle of adjacent gears?
- [ ] ISSUE-009: Proactive industry suggestions made? (thrust washers, bearings, snap rings, oil channels, edge breaks)
