# TRIPLE HELIX KINETIC WAVE SCULPTURE — MASTER PROMPT
## Complete Design Brief for OpenSCAD MVP Implementation
### Date: Feb 2026 | Author: Compiled from all project sessions

---

## 1. PROJECT VISION

Design a **mechanically complete, physically working Reuben Margolin-style Triple Helix kinetic wave sculpture** — a mechanical analog calculator that adds 3 sine waves at 120-degree phase offsets to produce asymmetric wave patterns displayed as Z-axis displacement of weighted wooden blocks.

**MVP Scope**: 19 blocks (2 hex rings), hand-crank driven, 3D-printed on Creality K2 Plus (350x350x350mm bed).

**Future Scope**: Chandelier sculpture hanging from 12-foot ceiling with Canadian standard home electrical connection (120V/60Hz, 15A circuit).

---

## 2. HOW IT WORKS — THE SIMPLE TRUTH

### One Sentence
Each string makes a sideways U-shaped detour around a slider at each of 3 tiers; when the slider pushes out, the detour widens and the block rises; when it pulls back, the detour narrows and the block drops by gravity.

### The Equation (Computed Mechanically)
```
Block_height(x, y, t) = C - k * [detour_1 + detour_2 + detour_3]
                       = C - k * [A*sin(theta + phi_1) + A*sin(theta + phi_2) + A*sin(theta + phi_3)]
```

Where:
- `theta` = helix rotation angle (driven by hand crank)
- `phi_1, phi_2, phi_3` = phase offsets from each block's position on the helix (which cam it connects to)
- The 3 tiers are at 0, 120, 240 degrees — matching the 3 helices
- `k` = string-to-displacement gain (geometry-dependent)
- `C` = constant (total string length minus slack)

### Three Functional Layers

```
LAYER 1: INPUT — Three Helix Camshafts
  Rotating eccentric disc stacks → sinusoidal lateral motion
  One cam per block per helix = 19 cams per helix shaft
  3 shafts at 120-degree spacing around the matrix
  Hand crank drives all 3 via belt/gear train

LAYER 2: COMPUTE — Three-Tier Pulley/Roller Matrix
  Each tier = one V5-style matrix unit (sliders + fixed pulleys + guide rails)
  Tier 1 at 0 degrees — sliders driven by Helix 1
  Tier 2 at 120 degrees — sliders driven by Helix 2
  Tier 3 at 240 degrees — sliders driven by Helix 3
  Each string threads through all 3 tiers making U-detours
  Total string path change = SUM of 3 detour changes = wave equation

LAYER 3: OUTPUT — Gravity-Loaded Blocks
  19 hexagonal blocks hanging below the matrix
  Each block attached to one string
  Block weight (70g) overcomes friction to pull string taut
  Block Z-position = visual output of the wave calculation
```

---

## 3. WHAT MARGOLIN BUILT (Ground Truth)

### From Reuben's Own Account (reubenmargolin.com/waves/triple-helix/story/)
- 3 aluminum helical camshafts in 120-degree star formation
- 1,027 strings, 1,027 blocks
- 37 rows per tier (PRIME number — avoids Moire patterns)
- 3 tiers of 37 rows = 111 slider bearings total
- 9,280 pulleys (nylon rollers on steel dowel pins)
- 20,000+ CNC-drilled holes in polycarbonate strips
- 40g minimum block weight to overcome friction; actual = 70g (40g basswood + 30g steel shot)
- After string goes around 9 pulleys, friction force = 10x the block weight
- 2-3/8" ID bearings as slider attachments
- Single overhead motor driving all 3 helixes

### The Critical Architecture
- Polycarbonate strips CNC-routed and drilled, assembled with steel dowel pins
- Nylon rollers (pulleys) spin on the dowel pins
- Sliding strips move laterally in channels between fixed strips
- Each slider strip carries one pulley (the U-turn point)
- Fixed strips carry redirect rollers (in and out)
- String path per tier: redirect_in roller -> slider pulley (U-turn) -> redirect_out roller = 3 pulleys
- String path total: 3 tiers x 3 pulleys = 9 pulleys per string
- Friction efficiency: 0.95^9 = 63% (Margolin's stated limit)

### Tier Orientations (CRITICAL)
The 3 tiers are NOT stacked with sliders all going the same direction:
- Tier 1: Sliders move along 0-degree direction
- Tier 2: Sliders move along 120-degree direction
- Tier 3: Sliders move along 240-degree direction

Each tier's strip assembly is physically rotated 120 degrees from the previous tier. Strings pass vertically through all three, but the U-detours at each tier go in different horizontal directions.

### Why Bidirectional (No Rectification Needed)
The slider oscillates around a BASELINE OFFSET position. At rest, it is already pulled out some distance from the string's vertical line, creating a baseline detour.
- Slider moves further out -> U-detour gets wider -> more string consumed -> block RISES
- Slider moves back in -> U-detour gets narrower -> string released -> block FALLS (gravity)

The motion is relative to the baseline, not relative to zero. There is no dead zone, no rectification.

---

## 4. MVP SPECIFICATIONS

### Block Grid
| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Hex rings | 2 | MVP scale |
| Block count | 19 | 2-ring hex grid (1 + 6 + 12) |
| Block flat-to-flat | 30mm | Scaled down from Margolin's 50mm |
| Block height | 20mm | Visual weight |
| Block weight | 80g | 30g PLA shell + 50g steel shot fill (increased from 70g per rope routing analysis — compensates for guide plate bushing friction) |
| Block spacing | 32mm | 30mm block + 2mm gap |
| Grid diameter | ~128mm | Fits K2 Plus bed |

### Helix Camshafts (3 units)
| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Cams per helix | 19 | One cam per block |
| Twist per cam | 360/19 = 18.95 degrees | Full 360-degree wave |
| Total twist | 360 degrees | One complete wave |
| Bearing | 6810 (50x65x7mm) | Proven from V5 design |
| Eccentric offset | 12.0mm | +-12mm cam follower travel |
| Peak-to-peak stroke | 24.0mm | 2 x eccentricity |
| Hub diameter | 49.9mm (bearing ID press-fit) | 6810 bearing |
| Bolt pattern | 3 bolts at 120 degrees, M4 | Proven from V5 |
| Bolt circle dia | 18mm | CORRECTED from 20mm (nut trap wall fix) |
| Nut trap dia | 7mm | CORRECTED from 8mm (wall thickness fix) |
| Alignment pin | 5mm center rod through stack | Anti-rotation |
| Axial pitch | 10mm per disc | CORRECTED from 8mm (rib clearance fix) |
| Helix length | 19 x 10mm = 190mm | Fits K2 Plus |

### Cam Followers (Gravity Ribs)
| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Type | Gravity rib riding on bearing OD | Margolin-proven |
| Arm length | 60mm | Reach from bearing to cable attach |
| Thickness | 6mm | Structural |
| Anti-rotation | Guide slot on housing jig | Prevents spin |
| Soft stops | +-15 degrees | Prevents over-rotation |
| Eyelet at tip | 3mm hole | String/cable attachment |
| Safe RPM | <81 | Gravity retention limit |
| Operating RPM | 1-15 (hand crank) | Well within safe range |

### Matrix (3-Tier Stack)
| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Tiers | 3 | One per helix (0/120/240 degrees) |
| Architecture per tier | 19 independent narrow channels | Each slider moves independently (one cam per slider) |
| Sliders per tier | 19 | One per block per helix — each independently driven |
| Channels per tier | 19 | One narrow channel per slider (NOT V5's shared 5-channel) |
| Channel width | ~12mm | 10mm slider pulley + 2mm walls |
| Tier total width | ~234mm | 19 channels x 12mm + outer walls |
| Redirect rollers per string per tier | 2 | In (at Y=+20mm) + out (at Y=-20mm) |
| Total pulleys per string | 9 | 3 per tier x 3 tiers (rollers only) |
| Guide plate bushings per string | 2 | Post-matrix vertical correction |
| Combined friction efficiency | ~62% | 0.95^9 x 0.99^2 |
| Tier rotation | 0, 120, 240 degrees | Matches helix spacing |
| Inter-tier gap | 25mm | Accommodates ~39-degree inter-tier string angle |
| Tier boundary holes | 8mm diameter, chamfered | Oversized — NO bushings (string enters at angle) |
| FP_ROW_Y (redirect offset) | 20mm | REDUCED from 31mm — limits inter-tier lateral shift |
| Total matrix height | ~255mm | 3 tiers x (40mm gap + 6mm walls) + 2 x 25mm gaps |

### String Routing (Per Block) — 19 Contact Points
```
[A] Top anchor (fixed to frame above matrix)
  |
  | free vertical drop (45mm)
  |
  ○ 8mm pass-through hole (Tier 1 top plate — NO bushing)
  |
Tier 1 (0 deg):
  [T1-R1] redirect_in roller (13mm, at Y=+20)
    ╲
     ╲ approach segment (~28mm at 45 deg)
      ╲
  [T1-S1] slider_1 U-turn pulley (10mm, at Y=0)  ← COMPUTATION
      ╱
     ╱ departure segment (~28mm at 45 deg)
    ╱
  [T1-R2] redirect_out roller (13mm, at Y=-20)
  |
  ○ 8mm pass-through hole (Tier 1 bottom plate)
  |
  | inter-tier transition (25mm, ~39 deg angle shift for 120 deg rotation)
  |
  ○ 8mm pass-through hole (Tier 2 top plate)
  |
Tier 2 (120 deg): [same pattern, sliders along 120 deg]
  [T2-R1] -> [T2-S1] -> [T2-R2]
  |
  ○ 8mm pass-through (Tier 2 bottom)
  |
  | inter-tier transition
  |
  ○ 8mm pass-through (Tier 3 top)
  |
Tier 3 (240 deg): [same pattern, sliders along 240 deg]
  [T3-R1] -> [T3-S1] -> [T3-R2]
  |
  ○ 8mm pass-through (Tier 3 bottom)
  |
  | post-matrix drop (30mm)
  |
═══ GUIDE PLATE 1 (upper dampener) ═══
  [GP-G1] PTFE bushing (5mm funnel entry → 2mm bore)
  |  captures string from any angle, constrains to vertical
  |  15mm gap
═══ GUIDE PLATE 2 (lower dampener) ═══
  [GP-G2] PTFE bushing (confirms vertical path)
  |
  | free vertical drop (100-250mm, guaranteed vertical)
  |
  █ [B] Block (80g, hanging by gravity)
```

### Guide Plate Assembly (Post-Matrix Dampener)
| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Purpose | Correct lateral string deviation from 3-tier detours | Without it, blocks swing sideways |
| Plates | 2 (upper + lower) | Two-point constraint guarantees vertical |
| Plate spacing | 15mm | Sufficient angular correction |
| Bushing type | PTFE flanged grommet | Low friction (0.99 per bushing) |
| Bushing bore | 2.0mm | String 0.5mm + clearance |
| Funnel entry | 5mm dia chamfer | Accepts string from up to ~40 deg |
| Plate material | PLA, 3mm thick | 19 bushing holes in hex grid |
| Mounting | Fixed to frame (does NOT rotate with tiers) | Aligned with block grid |
| Friction contribution | 0.99^2 = 0.98 | Minimal — only 2% loss |

### Drive System (MVP)
| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Input | Hand crank | MVP simplicity |
| Primary drive | Crank -> central shaft | Direct connection |
| Distribution | Central shaft -> 3 helix shafts | Belt or bevel gears |
| Helix arrangement | 120-degree star around matrix | Margolin layout |
| Speed ratio | 1:1 all helixes | Same speed, phase from position |
| Helix shaft orientation | Horizontal, tangent to radial arm | Each shaft perpendicular to its radial spoke |

### Frame
| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Type | Hexagonal frame | Matches hex grid aesthetic |
| Material | 3D printed PLA/PETG + threaded rod | Structural |
| Size | ~350mm diameter | K2 Plus bed limit |
| Height | ~500mm total | Matrix + block travel + frame |
| Mounting | Tabletop (MVP) | Ceiling mount later |

---

## 5. THE V5 MATRIX UNIT — THE TIER BUILDING BLOCK

### CRITICAL UNDERSTANDING
**The V5 "MATRIX SINGLE UNIT v5.scad" IS one tier of the calculator.** V5's MECHANICAL PRINCIPLES (channel_internals, shared_wall, pulley_row, guide rails) are correct and reusable. The U-detour geometry (FP rows at ±Y, slider at Y=0, slider moves in X) is confirmed correct.

**HOWEVER**: V5's 5-channel layout (with shared slider plates per channel) must be ADAPTED to 19 independent narrow channels. In V5, all pulleys on one slider plate move together — but Margolin's design requires each slider to move independently (driven by its own cam). The MVP tier = 19 copies of a minimal V5-style channel placed side by side, each with its own independently-driven slider.

### V5 Architecture — What We Keep vs Adapt

**KEEP (proven patterns)**:
```
- channel_internals() module — redirect_in + slider + redirect_out per string
- shared_wall() module — walls with guide rails between channels
- pulley_row() module — rollers on axles
- Guide rail geometry (RAIL_HEIGHT, RAIL_DEPTH, RAIL_TOLERANCE)
- Print-in-place clearances (PIP_CLEARANCE=0.3mm, PIP_Z_GAP=0.3mm)
- End stops for slider travel limits
- V-groove pulley design for string retention
```

**ADAPT**:
```
- 5 shared channels → 19 independent narrow channels (1 slider each)
- FP_ROW_Y: 31mm → 20mm (reduces inter-tier lateral shift from 31mm to 20mm)
- Channel gap: 19mm → 40mm (wider for pass-through clearance)
- Animation: sin($t*360)*68 → sin($t*360)*12 (match actual cam stroke)
- Each slider driven by individual cable from its own cam
```

### MVP Tier Dimensions
```
CHANNEL_WIDTH   = 12.0mm   (10mm slider pulley + 2mm divider walls)
NUM_CHANNELS    = 19       (one per string/block/cam)
TIER_WIDTH      = 234.0mm  (19 x 12mm + 2 x 3mm outer walls)
CHANNEL_GAP     = 40.0mm   (vertical clearance for pulleys + slider)
WALL_THICKNESS  = 3.0mm    (outer walls) / 1.5mm (divider walls)
FP_ROW_Y        = 20.0mm   (REDUCED from 31mm — redirect roller Y offset)
RAIL_HEIGHT     = 4.0mm    (guide rail engagement)
RAIL_DEPTH      = 1.5mm    (guide rail protrusion)
RAIL_TOLERANCE  = 0.4mm    (slider-to-rail clearance)
PIP_CLEARANCE   = 0.3mm
PIP_Z_GAP       = 0.3mm
PASS_THROUGH_DIA = 8.0mm   (tier boundary holes — oversized, NO bushings)
```

### V5 Modules (Reusable — Adapt for Narrow Channels)
```
channel_internals(slide_pos, ch_num, ...) — 1 redirect_in + 1 slider + 1 redirect_out per channel
shared_wall(length, offset_a, offset_b)   — Wall between adjacent channels with dual rails
single_face_wall(length, rail_on_top)     — Top/bottom end walls with single rail
pulley_row(count, pitch, od, width, axle_dia, axle_len) — Row of pulleys on axles
```

For the MVP, each narrow channel calls channel_internals with count=1 (single pulley per row).

### V5 Animation (MUST FIX)
```
Current:  anim_val = sin($t * 360) * 68    // WAY TOO LARGE
Correct:  anim_val = sin($t * 360) * 12    // Matches actual cam stroke of +-12mm
```

### How Channels Map to Blocks (MVP: 19 Independent Channels)
```
Channel 1:  1 slider → driven by cam 1  → serves block 1 (string 1)
Channel 2:  1 slider → driven by cam 2  → serves block 2 (string 2)
...
Channel 19: 1 slider → driven by cam 19 → serves block 19 (string 19)

Each channel has exactly:
  - 1 redirect_in roller (13mm OD, at Y=+20mm)
  - 1 slider pulley (10mm OD, at Y=0, moves ±12mm in X)
  - 1 redirect_out roller (13mm OD, at Y=-20mm)
  - 1 cable entry slot (stadium, 3x28mm, for cam-to-slider cable)
  - 2 pass-through holes (8mm, top+bottom plates, for string)
```

Each slider is independently driven by ONE cam from the corresponding helix.

---

## 6. HELIX CAM DESIGN — VERIFIED CORRECT

### From "Helix cam parts.scad"
```
Bearing:          6810 (50mm ID x 65mm OD x 7mm width)
Eccentric offset: 12.0mm (cam throw)
Twist per disc:   360 / NUM_CAMS degrees
Bolt pattern:     3 bolts at 120 degrees, M4, bolt_circle_dia=18mm (CORRECTED)
Nut trap:         M4 hex, dia=7mm (CORRECTED), depth=3.5mm
Center pin:       5mm alignment rod through entire stack
```

### Parts (3 types)
1. **Eccentric Hub** — Circular disc with bearing seat offset 12mm from bolt axis. Front face has through-holes, back face has nut traps ROTATED by twist_angle. Bolting hubs together forces progressive twist.

2. **Gravity Rib** — Arm that rides on bearing OD, extends radially inward toward matrix. Eyelet at tip for cable attachment. Gravity keeps it engaged with cam (no springs needed below 81 RPM).

3. **Rectangular End Plate** — Connects helix stack to motor/crank shaft. Pivot hole for motor shaft, bolt pattern for first hub.

### Physics (Verified)
```
Traveling wave: Y_i(theta) = 12 * sin(theta + i * twist_angle)  [mm, per follower]
Self-balancing: Sum of cos(theta + i*twist) = 0 for all theta (i=0..N-1)
Gravity rib stability: Safe up to ~81 RPM, sculpture operates at 1-15 RPM
Weight per helix: ~2.4 kg (19 discs x bearing + hub + rib)
Total rotating mass: ~7.3 kg (3 helixes)
Required motor: < 0.05 Nm, < 0.025 W (trivial — hand crank is fine)
```

### Remaining Fixes
- C1: Nut trap wall — bolt_circle_dia 20->18mm, nut_trap_dia 8->7mm -> 1.7mm clearance
- W1: Rib clearance — axial pitch 8->10mm OR rib thickness 6->4mm
- W2: Add +-15 degree soft stops on hub body

---

## 7. STRING PATH AND WAVE COMPUTATION

### Per-Block Displacement
Each tier's U-detour change is approximately:
```
delta_detour = 2 * slider_displacement * sin(approach_angle)
```

For redirect pulley at distance D from string vertical, slider baseline at offset B:
```
Gain per tier = 2 * B / sqrt(B^2 + D^2)

REVISED (FP_ROW_Y = 20mm):
  B = 20mm (baseline = FP_ROW_Y), D = 20mm (redirect vertical spacing)
  Gain = 2 * 20 / sqrt(400 + 400) = 40 / 28.3 = 1.41:1
  Per tier: +-12mm cam * 1.41 = +-17mm rope change
  Across 3 tiers (superposed, not all in phase): peak ~+-30 to +-45mm block travel
```

This is bidirectional, linear, and matches Margolin's proven mechanism.
Block travel of 30-45mm is proportionally appropriate for the MVP scale.

### Baseline Offset (W3 — RESOLVED)
In the V5 channel architecture, the baseline offset IS the FP_ROW_Y distance. The redirect rollers at Y=+20mm and Y=-20mm are the fixed points; the slider at Y=0 oscillates in X. The "baseline" is the neutral slider X position, which creates the default U-detour depth.

**MVP approach**: The channel geometry inherently creates the baseline. The slider's guide rail is centered at X=0 in the channel. The string enters vertically through a pass-through hole near X=0. The redirect rollers at Y=±20 force the detour. The slider at Y=0 is already at the correct offset. No spring or external bias needed — the string tension through the redirect rollers naturally holds the geometry.

---

## 8. COMPLETE PARTS LIST (MVP)

### Helix Assemblies (x3)
| Part | Qty per helix | Total (3x) | Material |
|------|--------------|-------------|----------|
| Eccentric hub | 19 | 57 | PLA |
| Gravity rib | 19 | 57 | PLA |
| 6810 bearing | 19 | 57 | Steel (purchased) |
| M4x25 bolt | 57 | 171 | Steel (purchased) |
| M4 hex nut | 57 | 171 | Steel (purchased) |
| Alignment rod 5mm | 1 | 3 | Steel (purchased) |
| End plate | 2 | 6 | PLA |
| Spacer collars | 18 | 54 | PLA |

### Matrix Assembly (3 tiers of 19 independent channels)
| Part | Qty per tier | Total (3x) | Material |
|------|-------------|-------------|----------|
| Top plate (234x80x3mm) | 1 | 3 | PLA/PETG |
| Bottom plate (234x80x3mm) | 1 | 3 | PLA/PETG |
| Divider walls (1.5mm) | 18 | 54 | PLA |
| Redirect-in rollers (13mm OD) | 19 | 57 | Nylon on steel axle |
| Redirect-out rollers (13mm OD) | 19 | 57 | Nylon on steel axle |
| Slider pulleys (10mm OD) | 19 | 57 | Nylon on steel axle |
| Slider strips (60x8x1.5mm) | 19 | 57 | PLA |
| Redirect axles (5mm x 15mm) | 38 | 114 | Steel rod |
| Slider axles (5mm x 10mm) | 19 | 57 | Steel rod |
| Cable entry slot grommets | 19 | 57 | PLA |

### Guide Plate Assembly (post-matrix dampener)
| Part | Qty | Material |
|------|-----|----------|
| Guide plate upper (hex grid, 3mm) | 1 | PLA |
| Guide plate lower (hex grid, 3mm) | 1 | PLA |
| PTFE flanged bushings (2mm bore) | 38 | PTFE (purchased) |
| Spacer posts (15mm) | 4 | PLA |

### Blocks and Strings
| Part | Qty | Material |
|------|-----|----------|
| Hex blocks 30mm FF x 20mm H | 19 | PLA shell + steel shot (80g each) |
| Braided string 0.5mm | 19 x ~800mm | Spectra/Dyneema |
| Top anchor plate | 1 | PLA |

### Frame and Drive
| Part | Qty | Material |
|------|-----|----------|
| Frame uprights | 6 | PLA + M6 threaded rod |
| Frame top plate | 1 | PLA (sectioned for K2 Plus bed) |
| Frame base plate | 1 | PLA (sectioned for K2 Plus bed) |
| Hand crank + shaft | 1 | PLA + steel rod |
| Drive belts/gears | 3 sets | GT2 belt + printed pulleys |

### Estimated Total Part Count: ~800-900 parts

---

## 9. EXISTING FILES — WHAT TO KEEP, MODIFY, OR REPLACE

| File | Status | Action |
|------|--------|--------|
| `Helix cam parts.scad` | KEEP + FIX | Apply C1 (bolt circle 18mm, nut trap 7mm), W1 (pitch 10mm), W2 (soft stops) |
| `MATRIX SINGLE UNIT v5.scad` | KEEP + MODIFY | Fix animation (68->12), adapt for 19 sliders/tier, parameterize for stacking |
| `triple_helix_prototype_v2.scad` | REFERENCE | Full assembly reference — reuse frame/drive patterns |
| `skytex_parts.scad` | REFERENCE | Whiffletree shuttle, dampener grommet, tension rib designs |
| `components/validation_modules.scad` | KEEP | Include in all new files |
| `hex_matrix_3tier_v1.scad` | REPLACE | Was incorrect approach — delete or archive |
| `linear_pulley_unit_v1.scad` | ARCHIVE | Predecessor design, exceeded 9-pulley limit |
| `HELIX_CAM_DESIGN_AUDIT_V2.md` | REFERENCE | Corrected mechanism understanding |
| `MARGOLIN_KNOWLEDGE_BANK.md` | REFERENCE | Comprehensive Margolin research |
| `ROPE_ROUTING_COMPLETE_ANALYSIS.md` | **CRITICAL REFERENCE** | Complete string path, 8 flaws found+fixed, guide plate design, revised params |

---

## 10. OPENSCAD FILE STRUCTURE (Target)

### File Organization
```
3d_design_agent/
  components/
    validation_modules.scad          — EXISTING, keep as-is

  triple_helix_mvp/
    config.scad                      — ALL shared parameters (single source of truth)
    helix_cam_v2.scad               — Eccentric hub + gravity rib + end plate (FIXED)
    matrix_tier_v2.scad             — Single tier: 19 independent narrow channels (ADAPTED from V5)
    matrix_stack.scad               — 3 tiers stacked at 120-degree rotation + inter-tier gaps
    guide_plate.scad                — Post-matrix dampener: 2 plates with PTFE bushings
    block_grid.scad                 — 19 hex blocks on 2-ring grid
    string_routing.scad             — Complete string path visualization (19 contact points per string)
    frame.scad                      — Hex frame with mounting points
    drive_system.scad               — Hand crank + belt distribution
    full_assembly.scad              — Everything together, animated

    stl_export/
      hub_cam_01.stl through hub_cam_19.stl
      rib_01.stl through rib_19.stl
      end_plate.stl
      tier_top_plate.stl             — Print 3 copies (one per tier)
      tier_bottom_plate.stl          — Print 3 copies
      tier_divider_wall.stl          — Print 54 copies (18 per tier x 3)
      slider_strip.stl               — Print 57 copies (19 per tier x 3)
      guide_plate.stl                — Print 2 copies (upper + lower)
      block_hex.stl                  — Print 19 copies (80g each with steel shot)
      frame_section_01.stl through frame_section_06.stl
```

### config.scad (Single Source of Truth)
```openscad
// === MVP CONFIGURATION ===
// All dimensions in mm. Change here, propagates everywhere.

// --- Grid ---
HEX_RINGS       = 2;
NUM_BLOCKS      = 19;       // 1 + 6 + 12
BLOCK_FF        = 30;       // flat-to-flat
BLOCK_HEIGHT    = 20;
BLOCK_SPACING   = 32;       // center-to-center
BLOCK_WEIGHT    = 80;       // grams (30g PLA + 50g steel shot) — increased per rope routing analysis

// --- Helix Cam ---
NUM_CAMS        = 19;       // = NUM_BLOCKS (one cam per block per helix)
NUM_HELICES     = 3;
HELIX_PHASE     = 120;      // degrees between helices
TWIST_PER_CAM   = 360 / NUM_CAMS;  // ~18.95 degrees
ECCENTRICITY    = 12.0;     // mm cam throw
CAM_STROKE      = 2 * ECCENTRICITY; // 24mm peak-to-peak

// --- Bearing: 6810 ---
BEARING_ID      = 50.0;
BEARING_OD      = 65.0;
BEARING_W       = 7.0;

// --- Bolt Pattern (CORRECTED) ---
BOLT_CIRCLE_DIA = 18.0;     // was 20 — nut trap wall fix
BOLT_HOLE_DIA   = 4.2;      // M4 loose fit
NUT_TRAP_DIA    = 7.0;      // was 8 — wall thickness fix
NUT_TRAP_DEPTH  = 3.5;
NUM_BOLTS       = 3;

// --- Helix Stack ---
AXIAL_PITCH     = 10.0;     // was 8 — rib clearance fix
HELIX_LENGTH    = NUM_CAMS * AXIAL_PITCH;  // 190mm
CENTER_PIN_DIA  = 5.0;

// --- Gravity Rib ---
RIB_ARM_LENGTH  = 60.0;
RIB_THICK       = 6.0;      // consider 4mm if clearance tight
SOFT_STOP_ANGLE = 15;       // degrees

// --- Matrix Tier (REVISED from rope routing analysis) ---
NUM_TIERS       = 3;
TIER_ANGLES     = [0, 120, 240];
NUM_CHANNELS_PER_TIER = 19; // independent narrow channels (was 5 shared)
CHANNEL_WIDTH   = 12.0;     // mm per channel (10mm pulley + 2mm dividers)
CHANNEL_GAP     = 40.0;     // mm vertical gap inside channel (was 19mm)
TIER_WIDTH      = 234.0;    // mm total (19 x 12 + 6mm outer walls)
DIVIDER_WALL    = 1.5;      // mm between channels
WALL_THICKNESS  = 3.0;      // mm outer walls
FP_ROW_Y        = 20.0;     // REDUCED from 31mm — limits inter-tier lateral shift
INTER_TIER_GAP  = 25.0;     // mm between tier bottom and next tier top
PASS_THROUGH_DIA = 8.0;     // mm oversized holes at tier boundaries (NO bushings)

// --- Pulleys ---
FP_OD           = 13.0;     // fixed pulley outer diameter
FP_WIDTH        = 18.0;     // fixed pulley width
SP_OD           = 10.0;     // slider pulley outer diameter
SP_WIDTH        = 7.0;      // slider pulley width
AXLE_DIA        = 5.0;      // pulley axle diameter

// --- Guide Rails (from V5) ---
RAIL_HEIGHT     = 4.0;
RAIL_DEPTH      = 1.5;
RAIL_TOLERANCE  = 0.4;
PIP_CLEARANCE   = 0.3;
PIP_Z_GAP       = 0.3;

// --- String ---
STRING_DIA      = 0.5;      // mm braided Spectra/Dyneema
PULLEYS_PER_STRING = 9;     // 3 per tier x 3 tiers (rollers only)
BUSHINGS_PER_STRING = 2;    // guide plate only (tier holes are oversized, no bushings)
FRICTION_ROLLERS = pow(0.95, PULLEYS_PER_STRING);  // 0.6302
FRICTION_BUSHINGS = pow(0.99, BUSHINGS_PER_STRING); // 0.9801
FRICTION_EFF    = FRICTION_ROLLERS * FRICTION_BUSHINGS; // ~0.617

// --- Baseline Offset ---
BASELINE_OFFSET = 20.0;     // mm = FP_ROW_Y — slider Y-offset IS the baseline

// --- Guide Plate (post-matrix dampener) ---
GUIDE_PLATE_COUNT = 2;       // upper + lower
GUIDE_PLATE_GAP   = 15.0;   // mm between plates
GUIDE_BUSHING_BORE = 2.0;   // mm (string 0.5mm + clearance)
GUIDE_FUNNEL_DIA   = 5.0;   // mm entry chamfer (accepts ~40 deg angle)

// --- Frame ---
FRAME_DIAMETER  = 340;      // mm — hex frame outer diameter
FRAME_HEIGHT    = 500;      // mm — total assembly height

// --- Print Bed ---
BED_X           = 350;      // Creality K2 Plus
BED_Y           = 350;
BED_Z           = 350;

// --- Animation ---
MANUAL_POSITION = -1;       // -1 uses $t, 0.0-1.0 for static debug
anim_t = (MANUAL_POSITION >= 0) ? MANUAL_POSITION : $t;

// --- Colors ---
C_ACRYLIC = [0.85, 0.92, 0.95, 0.3];  // transparent blue
C_NYLON   = [0.95, 0.95, 0.92, 1.0];  // white
C_STEEL   = [0.7, 0.7, 0.75, 1.0];    // silver
C_STRING  = [0.1, 0.1, 0.1, 1.0];     // black
C_BLOCK   = [0.82, 0.71, 0.55, 1.0];  // basswood
C_SLIDER  = [0.9, 0.4, 0.4, 1.0];     // red (V5 slider color)

// --- Quality ---
$fn = 60;
```

---

## 11. DESIGN SEQUENCE (Build Order)

### Phase 1: Helix Cam (Apply Fixes to Existing)
1. Copy `Helix cam parts.scad` -> `triple_helix_mvp/helix_cam_v2.scad`
2. Apply C1 fix: bolt_circle_dia=18, nut_trap_dia=7
3. Apply W1 fix: axial_pitch=10 (add spacer collar between hubs)
4. Apply W2 fix: Add +-15 degree soft stops (small tabs on hub body)
5. Update NUM_CAMS=19, twist_angle=360/19
6. Verify: stack 19 hubs, check total length fits K2 Plus bed
7. Include validation_modules.scad, run verify_printability

### Phase 2: Matrix Tier (Redesign from V5 Principles)
1. Create `triple_helix_mvp/matrix_tier_v2.scad` (fresh, using V5 modules as patterns)
2. Design 19 independent narrow channels (12mm wide each), total tier width 234mm
3. Each channel contains: 1 redirect_in (13mm OD, Y=+20), 1 slider (10mm OD, Y=0), 1 redirect_out (13mm OD, Y=-20)
4. FP_ROW_Y = 20mm (reduced from V5's 31mm to limit inter-tier lateral shift)
5. Channel gap = 40mm (wider than V5's 19mm for pulley clearance)
6. Each slider on its own independent strip with guide rails
7. Add cable entry slots (stadium cutout 3x28mm) in side wall for cam-to-slider cables
8. Add 8mm pass-through holes in top and bottom plates for each string (chamfered both sides)
9. Fix animation: each slider driven by sin($t * 360 + phase_i) * 12
10. Test: animate all 19 sliders independently
11. Verify: no collisions, guide rails engage, sliders travel ±12mm freely

### Phase 3: Matrix Stack (3 Tiers)
1. Create `matrix_stack.scad`
2. Instance matrix_tier_v2 three times
3. Tier 1 at Z=0, rotation=0 degrees
4. Tier 2 at Z=(CHANNEL_GAP+6mm)+INTER_TIER_GAP, rotation=120 degrees
5. Tier 3 at Z=2*(above), rotation=240 degrees
6. Verify: 8mm pass-through holes allow ~39-degree string angle between tiers
7. Add inter-tier spacer posts (25mm) with alignment dowels
8. Verify: strings can pass through all 3 tiers at maximum slider deflection

### Phase 3.5: Guide Plate Assembly (NEW)
1. Create `guide_plate.scad`
2. Design 2 identical plates with 19 bushing holes in hex grid pattern
3. PTFE flanged bushings: 5mm funnel entry → 2mm bore
4. 15mm spacer posts between plates
5. Mount below Tier 3 bottom plate with 30mm gap
6. Verify: bushing positions align exactly with block grid centers
7. Test: string at 40-degree entry angle captured by funnel and exits vertical

### Phase 4: Block Grid
1. Create `block_grid.scad`
2. Generate 19 hex block positions (2-ring hex grid, 32mm spacing)
3. Each block: hex shell (30mm FF x 20mm H) with cavity for steel shot (80g total)
4. String attachment point at top center of each block
5. Animate: block Z = f(3 slider positions from 3 tiers) per rope routing geometry
6. Verify: blocks don't collide at maximum displacement (±35mm from neutral)

### Phase 5: String Routing (Visualization — Reference: ROPE_ROUTING_COMPLETE_ANALYSIS.md)
1. Create `string_routing.scad`
2. For each of 19 strings, trace all 19 contact points:
   - [A] Anchor → 8mm hole → [T1-R1] → [T1-S1] → [T1-R2] → 8mm hole
   - → 8mm hole → [T2-R1] → [T2-S1] → [T2-R2] → 8mm hole
   - → 8mm hole → [T3-R1] → [T3-S1] → [T3-R2] → 8mm hole
   - → [GP-G1] guide bushing → [GP-G2] guide bushing → [B] Block
3. Use hull() of two spheres for string segment visualization
4. Color-code: Tier 1 = red, Tier 2 = green, Tier 3 = blue, vertical = yellow
5. Animate: strings change path with slider motion (each slider phase-offset)

### Phase 6: Frame + Drive
1. Create `frame.scad` — hex frame with uprights and mounting plates
2. Create `drive_system.scad` — hand crank, central shaft, 3 belt outputs
3. Position 3 helix assemblies at 120 degrees around matrix
4. Each helix shaft horizontal, tangent to its radial arm
5. Belt/gear connection from central shaft to each helix shaft

### Phase 7: Full Assembly
1. Create `full_assembly.scad` — imports everything
2. Animate with single $t driving all 3 helixes
3. Verify complete power path: crank -> shaft -> belts -> helixes -> ribs -> cables -> sliders -> strings -> blocks
4. Run full verification report
5. Section into printable pieces for K2 Plus bed

---

## 12. VERIFICATION CHECKLIST

### Power Path (Every Moving Part Traces to Motor/Crank)
```
Hand Crank
  -> Central Shaft (rotation)
    -> Belt 1 -> Helix 1 (rotation) -> 19 cams -> 19 ribs -> 19 cables -> 19 sliders (Tier 1)
    -> Belt 2 -> Helix 2 (rotation) -> 19 cams -> 19 ribs -> 19 cables -> 19 sliders (Tier 2)
    -> Belt 3 -> Helix 3 (rotation) -> 19 cams -> 19 ribs -> 19 cables -> 19 sliders (Tier 3)
  -> 19 strings through 3 tiers
    -> 19 blocks (gravity-loaded Z displacement)
```
No orphan sin($t) — every animated element connected to hand crank.

### Kinematics
- [ ] All 57 cams produce +-12mm lateral motion
- [ ] All 57 gravity ribs stay engaged (operating RPM < 81)
- [ ] All 57 sliders move freely in guide rails
- [ ] All 19 strings thread cleanly through 9 pulleys each
- [ ] Friction efficiency >= 63% (0.95^9)
- [ ] Block weight (70g) overcomes friction for reliable return
- [ ] Baseline offset creates bidirectional motion (no dead zone)

### Printability (Creality K2 Plus)
- [ ] Every part fits 350x350x350mm bed
- [ ] Wall thickness >= 1.2mm everywhere
- [ ] Clearance >= 0.3mm for all moving joints
- [ ] No unsupported overhangs > 45 degrees (or add supports)
- [ ] Large assemblies sectioned with alignment features

### Physics
- [ ] Self-balancing shaft: sum of eccentric forces = 0
- [ ] Tolerance stack < 2mm across string path
- [ ] Power budget: required < available/2
- [ ] Gravity analysis: all ribs return reliably

---

## 13. KEY NUMBERS QUICK REFERENCE

| Parameter | Value | Unit | Source |
|-----------|-------|------|--------|
| Blocks | 19 | — | MVP spec |
| Hex rings | 2 | — | MVP spec |
| Cams per helix | 19 | — | 1:1 with blocks |
| Helixes | 3 | — | Margolin design |
| Total cams | 57 | — | 19 x 3 |
| Twist per cam | 18.95 | degrees | 360/19 |
| Eccentric offset | 12.0 | mm | Helix cam parts |
| Cam stroke | 24.0 | mm p-p | 2 x eccentricity |
| Bearing | 6810 (50x65x7) | mm | Proven |
| Tiers | 3 at 0/120/240 | degrees | Margolin |
| Channels per tier | 19 independent | — | Rope routing analysis |
| Channel width | 12 | mm | 10mm pulley + 2mm |
| Tier width | 234 | mm | 19x12 + walls |
| FP_ROW_Y | 20 | mm | REDUCED from 31 |
| Channel gap | 40 | mm | INCREASED from 19 |
| Inter-tier gap | 25 | mm | For 39-deg angle |
| Pass-through holes | 8 | mm dia | Oversized, no bushing |
| Pulleys per string | 9 | — | 3/tier x 3 tiers |
| Bushings per string | 2 | — | Guide plate only |
| Contact points per string | 19 | — | Full routing count |
| Combined friction efficiency | ~62% | — | 0.95^9 x 0.99^2 |
| Block weight | 80 | grams | INCREASED from 70 |
| Safety factor (friction) | 1.63 | — | 80g at 62% eff |
| Block flat-to-flat | 30 | mm | MVP scale |
| Block spacing | 32 | mm | 30mm + 2mm gap |
| Block travel | ±30-45 | mm | At FP_ROW_Y=20mm |
| Grid diameter | ~128 | mm | 2-ring hex |
| Helix length | 190 | mm | 19 x 10mm pitch |
| Matrix height (3 tiers) | ~188 | mm | 3x(40+6) + 2x25 |
| Guide plate assembly | 21 | mm | 3+15+3mm |
| Total matrix + guide | ~255 | mm | Including gaps |
| Frame diameter | ~340 | mm | K2 Plus limit |
| Total height | ~410 | mm | Matrix + frame + drops |
| Strings | 19 | — | 1 per block |
| Total rollers | 171 | — | 19 x 9 |
| Total bushings | 38 | — | 19 x 2 guide plate |
| Print bed | 350x350x350 | mm | K2 Plus |

---

## 14. ANNOTATED REFERENCE IMAGES

### Key Visual References (in project folder)
1. **`STACKED MATRXI.jpg`** — THE TARGET: Annotated photo showing 3 V5-like tiers stacked vertically, yellow string threading through all 3 with U-detours at red X slider positions, hexagonal block hanging at bottom. THIS IS WHAT WE ARE BUILDING.

2. **`Screenshot 2026-02-10 011702.png`** — Video still showing tiers labeled 0 degrees, 120 degrees, 240 degrees — confirms tier rotation.

3. **`Screenshot 2026-02-10 012645.png`** — Overhead photo of actual Margolin matrix showing polycarbonate strips assembled with nylon rollers.

4. **`Screenshot 2026-02-09 042459.png`** — Top-down OpenSCAD view with red/blue/yellow lines at 120 degrees showing helix orientation.

5. **`Screenshot 2026-02-09 102330.png`** — Side view showing pulley count pattern 2-4-6-4-2 (similar to V5's 3-4-5-4-3 pyramid).

6. **`Screenshot 2026-02-09 122443.png`** — Front view showing 5 tiers with string paths visible.

7. **`Screenshot 2026-02-09 141254.png`** — Close-up of actual Margolin matrix with strings installed.

8. **`Screenshot 2026-02-09 170539.png`** — 3/4 view of V5 matrix with hexagonal frame overlay.

9. **`Screenshot 2026-02-09 170947.png`** — OpenSCAD render of stacked matrix assembly.

10. **`tripleHelixStory_1.jpg`** — Margolin's prototype matrix in his workshop.

11. **`tripleHelixStory_2.jpg`** — CNC routing polycarbonate strips.

---

## 15. MISTAKES TO AVOID (Lessons from Previous Sessions)

### Do NOT:
1. **Replace V5 with a new design.** V5's mechanical principles are correct. Adapt the modules, don't redesign from scratch.
2. **Build solid hex plates with holes.** The matrix is channels with rollers, not solid material.
3. **Use serpentine/zigzag string routing.** It's U-detour: in -> around -> out. 3 pulleys per tier. Simple.
4. **Assume all sliders move the same direction.** Each tier's sliders move along that tier's axis (0/120/240 degrees).
5. **Set animation amplitude to 68mm.** The actual cam stroke is +-12mm.
6. **Share animation values across sliders.** Each slider has its own phase based on which cam drives it.
7. **Exceed 9 rollers per string.** Friction cascade kills the mechanism.
8. **Forget the baseline offset.** FP_ROW_Y = 20mm IS the baseline (the Y-distance from redirect rollers to slider).
9. **Use fewer than 80g block weight.** Combined efficiency is 62% (9 rollers + 2 bushings).
10. **Over-analyze when the design is already decided.** Build the components.
11. **Put tight bushings at tier boundaries.** String enters at up to 39-degree angle between tiers — use 8mm oversized holes with chamfers, NOT bushings. Only use PTFE bushings at the guide plate.
12. **Share sliders across multiple strings.** Each slider must move independently. 19 sliders per tier = 19 independent channels, NOT V5's 5 shared-slider channels.
13. **Use FP_ROW_Y = 31mm.** Reduced to 20mm to limit inter-tier lateral shift to 20mm (was 31mm at Y=31). This is critical for the 120-degree rotation between tiers.
14. **Forget the guide plate below Tier 3.** Without it, blocks swing laterally instead of moving purely vertically.
15. **Route strings through multiple V5 channels to reach their target.** Each string enters its own dedicated narrow channel directly — no pass-through routing through intermediate channels.

### Do:
1. **Reuse V5 module patterns** (channel_internals, shared_wall, pulley_row) adapted for narrow 12mm channels.
2. **One cam per block per helix** (19 cams per helix for 19 blocks).
3. **19 independent narrow channels per tier** — each with its own slider driven by its own cam.
4. **Include validation_modules.scad** in every file.
5. **Test each component in isolation** before integration.
6. **Use config.scad** as single source of truth for all parameters.
7. **Animate with individual slider phases** (each slider driven by its specific cam).
8. **Verify power path** from crank to every block.
9. **Reference ROPE_ROUTING_COMPLETE_ANALYSIS.md** for the complete 19-contact-point string path.
10. **Include guide plate assembly** (2 plates, 15mm gap, PTFE bushings) below Tier 3.
11. **Use 8mm pass-through holes** at all tier boundaries — chamfered both sides, no bushings.

---

## 16. FUTURE DEVELOPMENT PATH (Post-MVP)

### Scale Up: 37 Blocks (3 Hex Rings, PRIME)
- 37 cams per helix (twist = 360/37 = 9.73 degrees per cam)
- Same 3-tier architecture, just more sliders per tier
- Larger frame, motorized drive

### Chandelier Installation
- Ceiling mount at 12 feet (3.66m)
- Canadian electrical: 120V/60Hz, 15A circuit
- Single overhead motor (NEMA 17 stepper or small AC gear motor)
- String drops: ~2-3 meters from matrix to blocks
- Block visibility: larger blocks (50mm FF), heavier (150-200g)
- Lighting: LED strips integrated into frame or block illumination from above
- Safety: string retention clips, block catch tray, emergency stop

### Electrical Requirements (Canadian Standard)
- CSA-approved junction box
- 120V AC to 24V DC power supply (for motor driver)
- Stepper driver (TMC2209 or similar)
- Arduino/ESP32 for speed control
- Total power draw: < 50W (motor + electronics)
- Approved flexible cord (SPT-2 or SVT)
- Strain relief at ceiling mount

---

## 17. SOURCES AND REFERENCES

### Primary Sources
- reubenmargolin.com/waves/triple-helix/story/ — Reuben's first-person construction account
- reubenmargolin.com/waves/triple-helix/ — Specifications
- TED Talk 2012: "Sculpting Waves in Wood and Time"
- dantorop.info/project/interview_reuben_margolin/ — Engineering interview

### Project Files
- `MATRIX SINGLE UNIT v5.scad` — V5 tier building block (V107) — reuse modules, adapt to 19 channels
- `Helix cam parts.scad` — Eccentric hub, gravity rib, end plate
- `triple_helix_prototype_v2.scad` — Full assembly reference
- `skytex_parts.scad` — Whiffletree shuttle, dampener grommet (guide plate reference), tension rib
- `components/validation_modules.scad` — Verification modules
- `HELIX_CAM_DESIGN_AUDIT_V2.md` — Corrected mechanism understanding
- **`ROPE_ROUTING_COMPLETE_ANALYSIS.md`** — **CRITICAL**: Complete string path (19 contact points), 8 flaws identified and fixed, guide plate design, revised parameters (FP_ROW_Y=20, block=80g, 19 channels/tier)
- `TRIPLE_HELIX_MVP_MASTER_PROMPT.md` — This document (single source of truth for full design)
- `archives/docs/MARGOLIN_KNOWLEDGE_BANK.md` — Comprehensive knowledge base
- `archives/docs/KINETIC_SCULPTURE_COMPENDIUM.md` — 14 domains of mechanism knowledge

### Visualizations (HTML/JS)
- `triple_helix_complete.html` — Full 3D simulation
- `skytex_simulation.html` — Skytex digital twin
- `margolin_mechanism_explained.html` — U-detour mechanism tutorial
- `margolin_3d_wave.html` — 3D configurable wave display
- `visualization_matrix_comparison.html` — V5 vs alternative comparison
- `wave_types_visualizer.html` — 8 wave type demonstrations
- `v5_wave_engine_3d.html` — V5 matrix 3D with engineering readout

### Key Images
- `STACKED MATRXI.jpg` — THE TARGET (annotated 3-tier stack + string + block)
- 11 screenshots with detailed annotations (see Section 14)
- `tripleHelixStory_1.jpg`, `tripleHelixStory_2.jpg` — Margolin workshop photos

---

*This master prompt captures the complete design intent, all corrections from previous sessions, verified parameters, rope routing analysis (8 flaws found and fixed), and a clear build sequence. Start with Phase 1 (Helix Cam fixes) and proceed sequentially. Every component maps to standard mechanical practice. V5's mechanical principles are the building block — adapt the modules for 19 independent narrow channels per tier. Refer to ROPE_ROUTING_COMPLETE_ANALYSIS.md for the definitive string path specification.*
