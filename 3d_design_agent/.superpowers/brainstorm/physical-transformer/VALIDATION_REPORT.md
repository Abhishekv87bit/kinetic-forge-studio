# Physical Transformer -- Validation Report

**Date**: 2026-03-17
**Validator**: Physics & Layout Feasibility Analysis
**Source Spec**: `docs/superpowers/specs/2026-03-17-physical-transformer-design.md`
**Status**: PRE-GEOMETRY (no CadQuery/OpenSCAD models exist yet)

---

## 0. Existing Geometry Files

**RESULT: NONE FOUND**

Searched directories:
- `d:\Claude local\3d_design_agent\` -- no transformer/pantograph/spiral_cam/worm_gear/triptych files
- `C:\Users\abhis\.kinetic-forge-studio\projects\` -- no matching files
- `d:\Claude local\kinetic-forge-studio\` -- no project-related matches (only library transformer.py)

No CadQuery or OpenSCAD geometry exists for this project. This is a clean-sheet validation against the spec only.

---

## 1. Validation Tools Available

| Tool | Path | Status |
|------|------|--------|
| VLAD (CadQuery validator) | `d:\Claude local\tools\vlad.py` | EXISTS -- 8-tier, 35 checks. Requires CadQuery production module with `get_fixed_parts()`, `get_moving_parts()`, `get_mechanism_type()`. Not runnable until geometry is modeled. |
| validate_geometry.py (OpenSCAD) | Various project dirs | EXISTS -- OpenSCAD-specific. Not applicable until SCAD files created. |

**Note**: The HTML dimensions page (`05-dimensions.html`) is STALE -- it references Archimedes levers (superseded by pantograph diamonds), different envelope (600x400x300 vs spec's 600x400x300 body), and a "geared DC motor" instead of the spec's NEMA 17/23. The markdown spec is authoritative.

---

## 2. Physics Validation

### 2.1 Torque Chain: NEMA 23 -> Worm -> Pantograph -> String

**Spec claims**: NEMA 23 (1.26 Nm), staged engagement of 6 weights at a time.

**Analysis**:

Worm gear (module 1.0, 1-start):
- Worm pitch diameter: ~10mm (for module 1.0, 1-start, this depends on worm diameter -- spec says 24mm OD assembly)
- Lead angle for 1-start, module 1.0: alpha = atan(1 * 1.0*pi / (pi * d_worm))
- For d_worm ~10mm: alpha = atan(pi / (pi * 10)) = atan(0.1) = 5.71 degrees
- Worm efficiency (brass on steel, dry): eta ~= 0.3-0.4 (very low for self-locking worms)
- Input torque per worm: T_worm = T_motor / (N_simultaneous * reduction_ratio)

**Spec states staged engagement: 7 groups of 6 weights.**

The barrel cam activates 6 rack-and-pinion updaters at once. Each gradient rack drives through:
- 0.5 module rack -> pinion (Z=16 default) -> 4:1 reduction -> worm shaft Z=12 -> worm

The 4:1 reduction gives torque multiplication of 4x. The pinion-to-rack has ratio dependent on pitch radius.

With NEMA 23 at 1.26 Nm and assuming barrel cam + gearing losses (~30%):
- Available torque at barrel cam output: ~0.88 Nm
- Per worm (6 simultaneous): ~0.147 Nm each
- Through 4:1 reduction backward (cam -> worm): the worm needs to be DRIVEN from the worm side (not the wheel side) during updates
- Worm drive from worm side is the high-efficiency direction: eta ~0.8-0.9

**Torque at worm shaft per weight**: ~0.147 Nm * 0.85 (gear train efficiency) = ~0.125 Nm
**Torque required to turn worm against load**: Depends on string tension + pantograph resistance

Pantograph + string system load estimate:
- Spring tensioner force: ~1-2 N per string (spec says pre-tensioned)
- Worm wheel radius (module 1.0, assuming 20T wheel): r = 10mm
- Load torque per worm: F * r = 2N * 0.01m = 0.02 Nm

**0.125 Nm available vs 0.02 Nm required per weight: ~6x margin**

| Check | Result |
|-------|--------|
| Motor torque sufficient for 6 simultaneous weights | **PASS** -- ~6x margin |
| Motor torque sufficient including barrel cam + pendulum + pin drum | **PASS with caveat** -- additional loads (barrel cam friction ~0.05 Nm, pendulum escapement ~0.02 Nm, pin drum indexing ~0.05 Nm) reduce margin to ~3-4x. Adequate but not generous. |

**IMPORTANT DISCREPANCY**: The spec body text says NEMA 23 (1.26 Nm) but Section 3.5 and 4.6 say NEMA 17 (~0.2-0.3 Nm). The risk register (Section 10) explicitly flags "Zero margin" with NEMA 17 and suggests NEMA 23 as fallback. **The spec is internally inconsistent on motor selection.**

| Check | Result |
|-------|--------|
| NEMA 17 (0.3 Nm) sufficient | **FAIL** -- at 6 simultaneous weights with all auxiliary loads, available torque per weight drops to ~0.03 Nm vs 0.02 Nm required. Essentially zero margin. Any friction increase kills it. |
| NEMA 23 (1.26 Nm) sufficient | **PASS** -- comfortable margin |

**VERDICT: NEMA 23 is mandatory. Update spec Section 3.5 and 4.6 to match the task brief's NEMA 23.**

---

### 2.2 Pendulum Timing

**Spec claims**: 250mm pendulum, T = 2*pi*sqrt(0.25/9.81) = 1.003s

**Verification**:
- T = 2 * pi * sqrt(L/g)
- T = 2 * pi * sqrt(0.250 / 9.81)
- T = 2 * pi * sqrt(0.02549)
- T = 2 * pi * 0.15966
- T = 1.0031 seconds

| Check | Result |
|-------|--------|
| Pendulum period calculation | **PASS** -- 1.003s confirmed exactly |

**Note**: This is the ideal simple pendulum period. Real period will be slightly longer due to:
- Pendulum bob is not a point mass (physical pendulum correction: ~1-3% depending on bob geometry)
- Air resistance (negligible at this scale)
- Escapement impulse timing
- Temperature effects on steel rod (spec acknowledges, says "not critical")

Effective period likely 1.01-1.03s. Acceptable for a kinetic sculpture -- exact timing is not computationally critical.

---

### 2.3 Adjoint Signal Loss Through Needle Bearings

**Task claims**: 12 needle bearing joints x (1-0.003) = 96.4% transmission, 4% loss.

**Analysis**:
The spec mentions PTFE-bushed joints for pantographs (not needle bearings -- HK0306 needle bearings are from the task brief, not the spec). Let me validate both:

**PTFE bushing friction (spec)**: Coefficient ~0.04-0.1 (dry), ~0.02-0.05 (lubricated)
**HK0306 needle bearing friction**: Coefficient ~0.002-0.005

For needle bearings (HK0306):
- Per-joint transmission: (1 - mu) where mu ~= 0.003
- 12 joints: 0.997^12 = 0.9646 = 96.5% transmission
- Loss: ~3.5%

| Check | Result |
|-------|--------|
| Needle bearing signal loss (12 joints, mu=0.003) | **PASS** -- 3.5% loss confirmed (task brief said 4%, close enough) |

**However**: The actual joint count needs verification. Each pantograph diamond has 4 pivot joints. With 3 diamonds per chain and 3 chains (hidden layer) + 3 single-diamond chains (output layer), the joint count is:
- Hidden layer: 3 chains x 3 diamonds x 4 joints = 36 joints
- Output layer: 3 chains x 1 diamond x 4 joints = 12 joints (spec says output pantographs have 3 weights + 1 bias each)
- Total: ~48 pivot joints in the pantograph system alone

With 48 joints at mu=0.003: 0.997^48 = 0.866 = **13.4% total loss**

With PTFE bushings at mu=0.05: 0.95^48 = 0.085 = **91.5% loss -- CATASTROPHIC**

| Check | Result |
|-------|--------|
| Signal loss with actual joint count (48 joints, needle bearings) | **WARNING** -- 13.4% loss, not 4%. Still within SGD noise tolerance (30%) but significantly more than claimed. |
| Signal loss with PTFE bushings (48 joints) | **FAIL** -- 91.5% loss. PTFE bushings are NOT viable for 48-joint chain. Needle bearings or ball bearings mandatory. |

**VERDICT: Use HK0306 needle bearings (not PTFE bushings) at all pantograph joints. Update spec Section 3.3 accordingly. Even with needle bearings, budget for ~13% signal attenuation, not 4%.**

---

### 2.4 Spiral Cam Gradient Accuracy

**Spec claims**: r_min=0.5mm (updated from task brief's 1.5mm), r_max=6mm, 254 degrees active arc.

**SLA resin at 50 micron resolution**:
- Radial resolution: 50 microns = 0.05mm
- At r_min (0.5mm): gradient step = 0.05/0.5 = 10% per step
- At r_max (6mm): gradient step = 0.05/6 = 0.83% per step
- Ratchet quantization: 24 teeth = 15 degrees per step
- 254 degrees / 15 degrees = ~17 discrete positions
- Radial range per step: (6 - 0.5) / 17 = 0.324mm per ratchet position

**Gradient precision**:
- The gradient = forward_displacement x adjoint_displacement
- Forward displacement is stored as angular position (17 discrete levels)
- Adjoint displacement wraps at stored radius
- Torque = T * r, where r is quantized to 17 levels across 0.5-6mm

**Quantization error**: With 17 levels, worst-case quantization is 1/(2*17) = ~3% of full range per factor.

**Combined gradient error budget** (from spec Section 6.3):
- Ratchet quantization: ~6% (15 degrees = coarse)
- Cone bias (r_min offset): ~8%
- Bushing friction: ~5%
- SLA surface roughness: ~2%
- Total: ~15-20% gradient error (RMS combination, not additive)

| Check | Result |
|-------|--------|
| SLA resolution adequate for spiral cam | **PASS** -- 50 micron resolution gives 0.05mm radial precision, adequate for r_max=6mm |
| Gradient accuracy vs spec claim (10-15%) | **WARNING** -- Actual error budget is closer to 15-20% when properly accounting for ratchet quantization at only 17 discrete levels. Spec's 10-15% is optimistic. |
| Gradient noise within SGD tolerance (30%) | **PASS** -- even at 20%, well within proven SGD noise tolerance |
| r_min = 0.5mm printability | **WARNING** -- 0.5mm radius on SLA is achievable but fragile. The spiral profile at r_min has features approaching the 50-micron resolution limit. Consider r_min = 1.0mm (reduces ratio to 6:1 but improves robustness). |

---

### 2.5 Convergence Detection: Spring-Loaded Pins in V-Notches

**Spec claims**: 3 spring-loaded pins drop into V-notches (~2mm wide) when error sliders are within threshold. Mechanical AND gate. Oil dashpot for 3-second delay.

**Tolerance analysis**:
- V-notch width: 2mm
- Slider rail length: 80mm
- Convergence threshold: 2mm / 80mm = 2.5% of full error range
- For a 3-output network with training data as specified, final error magnitude at convergence is typically <5% of max error
- 2.5% threshold is tight but achievable if the network converges cleanly

**Pin reliability**:
- Spring-loaded pin into V-notch is a proven detent mechanism
- V-notch angle matters: 60-degree V gives good centering force, 90-degree gives easier entry
- Pin diameter should be ~1.5-2mm (spec doesn't specify)
- Spring force: needs to overcome pin weight + friction, but not so strong it interferes with slider motion

**Dashpot timing**:
- 3-second delay to prevent false positives: good engineering
- Oil dashpot is simple and reliable
- Temperature sensitivity of oil viscosity could shift timing (3s becomes 2-5s range) -- acceptable for sculpture

| Check | Result |
|-------|--------|
| Convergence threshold appropriate | **PASS** -- 2.5% of range is tight but achievable |
| Mechanical AND gate feasibility | **PASS** -- proven mechanism |
| Dashpot false-positive prevention | **PASS** -- good design choice |
| Convergence threshold adjustability | **PASS** -- replaceable V-notch inserts allow tuning |

**Minor concern**: The 3 error sliders must oscillate in sync for all 3 to be simultaneously in-notch. If one output neuron converges much faster than others (common in small networks), the dashpot may never trigger because the fast-converging slider leaves its notch while the slow one enters. This is actually a feature (training continues until ALL outputs converge) but could extend training time beyond the 26-minute estimate.

---

### 2.6 String Routing: 42 Strings in 600x400x300mm

**Spec claims**: 42 string lines, max 2 pulley redirections per line. 0.5mm braided brass wire.

**String inventory**:
- Input-to-hidden: 27 strings (9 per hidden neuron, but only 3 active at once per neuron due to one-hot)
- Hidden biases: 3 strings
- Hidden-to-output: 9 strings (3 per output neuron)
- Output biases: 3 strings
- **Total: 42 strings**

**Routing constraints**:
- Front face (600x400mm): worm gears are here, strings must route from worm gear shafts to pantograph inputs
- Right face (300x400mm): pantograph diamonds are here
- Strings must turn 90 degrees (front to right) -- requires at least 1 pulley per string
- Adjoint pass requires bidirectional string travel -- pulleys must allow this

**Pulley spacing with 42 strings at 0.5mm diameter**:
- Minimum string-to-string spacing: ~3mm (to prevent tangling with pre-tension movement)
- 42 strings at 3mm spacing: 126mm of linear space needed for a single routing plane
- Available width: 600mm -- adequate for a single layer
- Available depth for routing: 300mm -- adequate for fan-out to pantographs

**Collision analysis**:
- Input-to-hidden strings (27): route from front face worm gears, turn 90 degrees via pulleys, enter pantograph diamonds on right face
- Hidden-to-output strings (9): route from hidden pantograph outputs, through shaped cams, to output pantographs
- These two groups occupy different vertical zones (hidden layer is above output layer)
- Bias strings (6): short, local routing from bias worm gears to nearest pantograph

**Critical crossing point**: Where hidden layer output strings cross the input string field to reach the output pantographs. With careful vertical stratification, this can be managed.

| Check | Result |
|-------|--------|
| 42 strings physically fit in envelope | **PASS** -- 3mm spacing x 42 = 126mm, well within 600mm width |
| Max 2 pulley redirections feasible | **PASS** -- front-to-right turn needs 1 pulley; fan-out to pantograph needs 0-1 more |
| String-to-string collision avoidance | **WARNING** -- requires careful routing plan. Hidden-to-output strings crossing input string field is the critical zone. Vertical stratification needed. |
| Bidirectional string travel through pulleys | **PASS** -- standard grooved pulleys allow bidirectional travel. Friction loss per pulley: ~2-5% |
| 42 strings x 2 pulleys max = ~84 pulleys | **WARNING** -- spec placeholder says "30+" pulleys but actual count is likely 60-84. Each pulley needs a mount, bearing, and alignment. This is significant assembly complexity. |

---

### 2.7 Worm Gear Self-Locking Verification

**Spec claims**: Module 1.0, brass-on-steel, 1-start worm. Self-locking. "Friction angle exceeds lead angle."

**Lead angle calculation**:
- 1-start worm, module 1.0
- Axial pitch = pi * module = 3.14mm
- Worm pitch diameter: For module 1.0 with typical proportions, d_worm = ~10-12mm
- Lead angle: gamma = atan(n * m * pi / (pi * d_worm)) = atan(1 * 1.0 * pi / (pi * d_worm)) = atan(1/d_worm * m)
- For d_worm = 10mm: gamma = atan(1.0 * pi / (pi * 10)) = atan(0.1) = 5.71 degrees
- For d_worm = 12mm: gamma = atan(1.0 * pi / (pi * 12)) = atan(0.083) = 4.76 degrees

**Friction angle (brass on steel, dry)**:
- Coefficient of friction mu = 0.30-0.40 (dry brass on steel)
- Friction angle phi = atan(mu) = atan(0.35) = 19.3 degrees

**Self-locking condition**: phi > gamma
- 19.3 degrees > 5.71 degrees: **YES, self-locking by wide margin (3.4x)**

**Spec Section 6.4 states**: friction angle 11 degrees > lead angle 5.3 degrees. This uses a more conservative friction estimate (mu ~= 0.19) which is reasonable for lightly oiled brass-on-steel.

| Check | Result |
|-------|--------|
| Worm gear self-locking (dry) | **PASS** -- friction angle ~19 degrees >> lead angle ~5.7 degrees |
| Worm gear self-locking (lubricated) | **PASS** -- even at mu=0.10, friction angle 5.7 degrees >= lead angle 5.7 degrees (marginal). At mu=0.15+, solid lock. |
| Self-locking persistence under vibration | **PASS** -- 3.4x margin on friction angle means vibration won't unlock |

**CAUTION**: Do NOT lubricate worm gears with low-friction lubricant (PTFE spray, silicone). Use a medium-viscosity oil that maintains friction angle above lead angle. Dry or lightly oiled is ideal.

---

## 3. Layout Feasibility

### 3.1 Front Face Triptych: 42 Worm Gears + 42 Spiral Cams + 3 Error Sliders in 600x400mm

**Top third -- Worm Gear Matrix (42 units)**:
- Spec: 24mm diameter x 20mm deep per assembly
- Layout: 6 rows. Top 3 rows: 10 gears each (9 weights + 1 bias per hidden neuron). Bottom 3 rows: 4 gears each (3 weights + 1 bias per output neuron).
- Row width: 10 x 24mm = 240mm (hidden rows) or 4 x 24mm = 96mm (output rows)
- 240mm fits in 600mm width with 360mm to spare -- **PASS**
- 6 rows x ~24mm spacing = 144mm height
- Allocated height (top third of 400mm): ~133mm
- **TIGHT** but feasible if spacing is reduced to 22mm between rows (132mm total)

| Check | Result |
|-------|--------|
| Worm gear matrix fits in top third | **PASS (tight)** -- 144mm needed in ~133mm available. Reduce row spacing to 22mm or allocate slightly more than 1/3 of height. |

**Middle third -- Spiral Cam Array (42 units)**:
- Spec: 30x22mm on PLA frame, grid at 32x24mm pitch
- Layout: 10 columns x 5 rows (50 positions, 42 used, 8 empty)
- Width: 10 x 32mm = 320mm -- fits in 600mm: **PASS**
- Height: 5 x 24mm = 120mm -- fits in ~133mm: **PASS**

| Check | Result |
|-------|--------|
| Spiral cam array fits in middle third | **PASS** -- 320x120mm array fits comfortably |

**Bottom third -- Error Sliders (3 units)**:
- Spec: 80mm rail length, 3 units
- Width: 3 x 80mm = 240mm (or more if spaced apart for visibility)
- Height: ~20mm per slider assembly
- Allocated: ~133mm height

| Check | Result |
|-------|--------|
| Error sliders fit in bottom third | **PASS** -- 3 sliders use minimal space, plenty of room for brachistochrone track too |

**Overall front face**: The triptych is feasible but the top third (worm gears) is the tightest fit. The hidden neuron rows (10 gears wide) at 24mm pitch = 240mm, centered in 600mm, leaves 180mm on each side for mounting hardware and plaques. Vertically, the three zones total approximately 144 + 120 + 40 = 304mm, fitting within 400mm with 96mm for spacing and labels.

| Check | Result |
|-------|--------|
| Full front face triptych layout | **PASS** -- all three zones fit with margin for labels and spacing |

### 3.2 Pantograph Layer (Right Face, 300x400mm)

**Hidden layer**: 3 pantograph chains, each with 3 diamonds at 70x40mm expanded
- Per chain footprint: 3 diamonds stacked = ~70mm wide x 120mm tall (3 x 40mm)
- 3 chains side by side: 3 x 70mm = 210mm wide
- Available: 300mm wide x 400mm tall
- 210mm in 300mm width: **PASS** (90mm margin)
- 120mm in 400mm height (upper half): **PASS**

**Output layer**: 3 single-diamond chains at 70x40mm
- Side by side: 210mm wide x 40mm tall
- In lower half of 400mm: **PASS**

| Check | Result |
|-------|--------|
| Pantograph layer fits in right face | **PASS** -- 210x160mm total in 300x400mm available |

### 3.3 Word Prisms (Left Face)

- 3 input prisms: 40mm face width x 60mm long each, stacked vertically with spacing
- Total: 60mm wide x ~200mm tall (3 prisms with spacing)
- 1 answer prism: 60mm wide x 60mm, mounted above
- Mode lever: ~80mm
- Available: 300mm wide x 400mm tall

| Check | Result |
|-------|--------|
| I/O panel fits in left face | **PASS** -- generous space |

### 3.4 String Routing -- 42 Lines Without Tangling

The critical routing challenge:

**Layer 1 (input-to-hidden, 27+3=30 strings)**:
- Origin: front face worm gear shafts (top third)
- Destination: right face pantograph inputs (upper half)
- Turn: 90-degree via pulley at front-right edge
- These strings run in the upper 60% of the volume

**Layer 2 (hidden-to-output, 9+3=12 strings)**:
- Origin: right face hidden pantograph outputs -> shaped cams
- Destination: right face output pantographs (lower half)
- These strings run within the right face, mostly vertical
- Shaped cam followers are inline with the string path

**Collision zone**: Layer 1 strings cross the same vertical plane as Layer 2 strings in the right face. Solution: offset Layer 1 strings by 20-30mm depth from Layer 2.

| Check | Result |
|-------|--------|
| 42 strings can route without collision | **PASS with design constraint** -- requires two distinct depth planes for input and output string fields, separated by ~20-30mm. This must be explicit in the CAD model. |
| Bidirectional adjoint travel feasible | **PASS** -- all string paths are reversible through pulleys |

---

## 4. Discrepancies and Issues Found

### CRITICAL

| # | Issue | Spec Reference | Recommendation |
|---|-------|---------------|----------------|
| C1 | **Motor spec inconsistent**: Body text says NEMA 23 (1.26 Nm), Sections 3.5/4.6 say NEMA 17 | Sections 3.5, 4.6, 10 | Standardize on NEMA 23. NEMA 17 has zero margin. |
| C2 | **Joint friction with PTFE bushings is catastrophic**: Spec says "PTFE-bushed joints" but 48 joints at PTFE friction = 91% signal loss | Section 3.3 | Change to needle bearings (HK0306) or miniature ball bearings at ALL pantograph pivots |
| C3 | **Signal loss understated**: Even with needle bearings, 48 joints = ~13% loss, not the "minimal" implied | Section 3.3 | Budget 13-15% signal attenuation into convergence simulation |

### SIGNIFICANT

| # | Issue | Spec Reference | Recommendation |
|---|-------|---------------|----------------|
| S1 | Pulley count underestimated: spec says "30+" but actual need is 60-84 | Section 7.2 | Update count after string routing diagram is complete |
| S2 | Spiral cam r_min=0.5mm is fragile on SLA | Section 6.3 | Consider r_min=1.0mm for robustness |
| S3 | Gradient error likely 15-20%, not 10-15% as claimed | Section 6.3 | Update error budget; still within SGD tolerance |
| S4 | Ratchet quantization at only 17 levels is coarse for weight storage | Section 6.3 | Consider 36-tooth ratchet (10-degree steps, 25 levels) |
| S5 | HTML dimensions page is stale (references Archimedes levers, DC motor) | 05-dimensions.html | Update HTML to match current spec |

### MINOR

| # | Issue | Spec Reference | Recommendation |
|---|-------|---------------|----------------|
| M1 | Convergence time may exceed 26 min if output neurons converge at different rates | Section 5.3 | Run convergence simulation with per-neuron tracking |
| M2 | String material: spec says "braided brass wire" but task brief says "stainless steel fishing leader" | Section 3.3 | Decide: brass (aesthetic) vs steel (stiffer, less creep). Steel leader wire is the better engineering choice. |
| M3 | Envelope discrepancy: task brief says 900x600x450mm, spec says 600x400x300mm | Sections 7.1, task brief | The 900x600x450 appears to include pedestal. Clarify. |

---

## 5. Summary Scorecard

| Category | Checks | PASS | WARN | FAIL |
|----------|--------|------|------|------|
| Torque chain | 3 | 2 | 0 | 1 (NEMA 17) |
| Pendulum timing | 1 | 1 | 0 | 0 |
| Signal loss (adjoint) | 3 | 1 | 1 | 1 (PTFE) |
| Spiral cam accuracy | 4 | 2 | 2 | 0 |
| Convergence detection | 4 | 4 | 0 | 0 |
| String routing | 5 | 3 | 2 | 0 |
| Worm self-locking | 3 | 3 | 0 | 0 |
| Front face layout | 4 | 4 | 0 | 0 |
| Pantograph layout | 1 | 1 | 0 | 0 |
| I/O panel layout | 1 | 1 | 0 | 0 |
| String collision | 2 | 2 | 0 | 0 |
| **TOTAL** | **31** | **24** | **5** | **2** |

**Overall: 24 PASS, 5 WARNING, 2 FAIL**

---

## 6. Recommendations for Geometry Modeling Phase

### Before writing any CadQuery:

1. **Resolve motor spec** -- lock NEMA 23 in all spec sections
2. **Resolve bearing type** -- lock needle bearings (HK0306) for all pantograph joints, update spec
3. **Create string routing diagram** -- 2D top-down and side views showing all 42 string paths with pulley positions. This is a prerequisite for 3D modeling.
4. **Run convergence simulation** -- Python model with 15-20% gradient noise injection. Validates that the machine can learn before any hardware is built.

### Modeling sequence (aligned with spec Build Phases):

1. **Phase 1 model**: Single worm gear + rack-and-pinion weight updater + spiral cam gradient computer. Validate with VLAD (`mechanism_type='gear'`).
2. **Phase 2 model**: Single pantograph diamond chain (3 diamonds). Validate with VLAD (`mechanism_type='linkage'`). This is where HK0306 bearings must be integrated.
3. **Phase 3 model**: Worm gear grid (3x2 subset). Validate clearance and self-locking.
4. **Phase 4 model**: Single neuron assembly (worm gears + pantograph + shaped cam). First integration test.
5. **Phase 5 model**: Full forward pass assembly. String routing is modeled here.
6. **Phase 6 model**: Add clamp bars, sliding collar differentials, spiral cams, rack-and-pinion updaters.
7. **Phase 7 model**: Pin drum, barrel cam, pendulum, convergence detector.
8. **Phase 8 model**: Full assembly with frame, acrylic panels, plaques.

### VLAD production module interface (when ready):

Each phase model should export:
- `get_fixed_parts()` -- frame, mounts, rails
- `get_moving_parts()` -- gears, pantograph links, sliders, with travel ranges
- `get_mechanism_type()` -- appropriate type per phase
- `get_envelope()` -- `{'x': 600, 'y': 400, 'z': 300}` for full assembly
- `get_clearance_pairs()` -- critical: string-to-string (3mm min), pantograph-to-frame (2mm min)
- `get_motor_spec()` -- `{'torque_nm': 1.26, 'speed_rpm': 100}` (NEMA 23)

---

*Report generated 2026-03-17. No geometry exists yet -- this is a spec-level validation only. All physics calculations use first-principles estimates and should be confirmed with test rig measurements (spec Phase 1).*
