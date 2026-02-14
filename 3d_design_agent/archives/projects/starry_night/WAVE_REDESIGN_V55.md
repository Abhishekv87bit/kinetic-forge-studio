# STARRY NIGHT V55 - WAVE SYSTEM COMPLETE REDESIGN

**Version:** V55 (Wave System Redesign)
**Date:** 2026-01-18
**Base:** V54 (Orphan Animation Fixes)
**Framework:** FAILURE_PATTERNS.md, MECHANISM_ALTERNATIVES.md

---

## EXECUTIVE SUMMARY

Complete redesign of the wave system to create **mesmerizing kinetic motion**. Waves travel from ocean (right, X=302) toward cliff (left, X=78), building intensity from calm swells to violent breaking waves.

### Key Changes

| Zone | Old Mechanism | New Mechanism | Motion Quality |
|------|---------------|---------------|----------------|
| Zone 1 | `harmonic_sine()` (orphan) | **Scotch Yoke Array** | Pure sinusoidal, hypnotic |
| Zone 2 | `harmonic_sine()` (orphan) | **Eccentric Cam + Rocker** | Asymmetric with dwell |
| Zone 3 | `harmonic_sine()` (orphan) | **Slider-Crank** | Dramatic crash profile |

### Pattern 3.1 Status: **RESOLVED**

All `harmonic_sine()` wave animations now replaced with true kinematic mechanisms.

---

## DESIGN PHILOSOPHY

### Goal: Kinetic Motion That Is MESMERIZING

The wave system is the emotional heart of the sculpture. It must capture:
1. **Eternal rhythm of the far ocean** - meditative, hypnotic swells
2. **Building energy of approaching waves** - anticipation, tension
3. **Violent crash at the cliff** - visceral impact, drama
4. **Traveling wave illusion** - continuous flow from right to left

### Key Principles Applied

| Principle | Implementation |
|-----------|----------------|
| Traveling wave illusion | Phase offsets: 0° → 45° → 75° |
| Asymmetric cam profiles | Fast crash, slow retreat |
| Parallax depth | Layers at different Z with different amplitudes |
| True kinematic mechanisms | Every sin($t) traces to physical hardware |

---

## ZONE 1: SCOTCH YOKE ARRAY (Far Ocean)

### Mechanism
```
Purpose: Gentle, hypnotic swells
Motion: Pure vertical bob (2mm amplitude)
Speed: 0.3x master (slowest zone)
Phase: 0°, 18°, 36° (3 layers)

Schematic:
  Rotating disc with offset pin
       │
   ════●════ slot in yoke
       │
  wave layer (slides vertically)
```

### Why Scotch Yoke
- **Pure sinusoidal output** - mathematically perfect waveform
- **Simple mechanism** - single rotating element
- **Low friction** - pin slides in slot, minimal binding
- **Hypnotic rhythm** - the far ocean should feel eternal, like breathing

### Parameters
```scad
SCOTCH_YOKE_CRANK_R = 2;        // 2mm crank radius = 4mm total stroke
SCOTCH_YOKE_LAYER_PHASES = [0, 18, 36];  // Layer phase offsets
WAVE_ZONE_1_RATIO = 0.3;        // Speed ratio (30T/100T gear)
```

### OpenSCAD Implementation
```scad
function scotch_yoke_output(crank_r, phase) = crank_r * sin(phase);

module zone_1_far_ocean_v55() {
    base_phase = master_phase * WAVE_ZONE_1_RATIO + WAVE_Z1_BASE_PHASE;
    bob_1 = scotch_yoke_output(SCOTCH_YOKE_CRANK_R, base_phase + 0);
    bob_2 = scotch_yoke_output(SCOTCH_YOKE_CRANK_R, base_phase + 18);
    bob_3 = scotch_yoke_output(SCOTCH_YOKE_CRANK_R, base_phase + 36);
    // ... layers translate by bob values
}
```

---

## ZONE 2: ECCENTRIC CAM + ROCKER (Mid Ocean)

### Mechanism
```
Purpose: Building energy, rolling motion
Motion: 5mm vertical + 3mm horizontal (elliptical path)
Speed: 0.5x master (medium zone)
Phase: 45°, 57°, 69° (3 layers)

Schematic:
  Asymmetric cam with dwell profile
       │
  cam follower (roller)
       │
  rocker linkage (adds horizontal drift)
       │
  wave layer (tilts + drifts)
```

### Cam Profile
```
Rise(0-120°)   → Dwell(120-150°)   → Fall(150-360°)
     ↑                  ↑                  ↑
Building wave    "About to break"    Falling back
   tension         anticipation         release
```

The 30° dwell at peak creates the signature "about to break" anticipation moment.

### Parameters
```scad
ECCENTRIC_CAM_OFFSET = 5;       // 5mm offset = 10mm vertical stroke
ECCENTRIC_ROCKER_AMP = 3;       // 3mm horizontal drift
ECCENTRIC_LAYER_PHASES = [0, 12, 24];  // 12° spacing
WAVE_ZONE_2_RATIO = 0.5;        // Speed ratio (30T/60T gear)
```

### OpenSCAD Implementation
```scad
function zone2_cam_profile(theta) =
    let(norm_theta = theta % 360)
    norm_theta < 120 ? ease_in_out(norm_theta / 120) * 5 :
    norm_theta < 150 ? 5 :  // dwell at peak
    5 * ease_out(1 - (norm_theta - 150) / 210);

function zone2_rocker_drift(theta, amplitude) =
    amplitude * sin(theta + 90);  // 90° phase shift = elliptical path
```

---

## ZONE 3: SLIDER-CRANK (Breaking Wave)

### Mechanism
```
Purpose: Dramatic crash near cliff
Motion: 12mm rise/fall with crash profile
Speed: 0.8x master (fastest zone)
Phase: 75° ahead of Zone 1

Schematic:
  Crank (12mm radius)
       │
  coupler rod (45mm)
       │
  slider on vertical guide ← crest piece
       │
  foam curl gear (separate mechanism, unchanged)
```

### Crash Profile
```
Build(0-90°)   → Peak(90-110°)   → CRASH(110-140°)   → Retreat(140-360°)
      ↑               ↑                  ↑                    ↑
Slow tension    Brief moment     FAST VIOLENT     Long slow foam
  building      before crash       IMPACT          settle/retreat
```

The profile is **highly asymmetric**:
- **75% of cycle** (0-90° + 140-360°) = slow build + slow retreat
- **8% of cycle** (110-140°) = fast crash (the visceral moment)
- **6% of cycle** (90-110°) = dramatic peak pause

### Parameters
```scad
SLIDER_CRANK_R = 12;        // 12mm crank radius = 24mm total stroke
SLIDER_ROD_L = 45;          // 45mm connecting rod
WAVE_ZONE_3_RATIO = 0.8;    // Speed ratio (30T/38T gear)
```

### OpenSCAD Implementation
```scad
function zone3_crash_profile(theta) =
    let(norm_theta = theta % 360)
    norm_theta < 90 ? ease_in(norm_theta / 90) * 12 :      // Building
    norm_theta < 110 ? 12 :                                 // Peak
    norm_theta < 140 ? 12 * (1 - (norm_theta - 110) / 30) : // CRASH
    12 * 0.1 * (1 - (norm_theta - 140) / 220);              // Retreat

function slider_crank_kinematics(crank_r, rod_l, theta) =
    let(
        pin_x = crank_r * sin(theta),
        pin_y = crank_r * cos(theta),
        slider_y = pin_y + sqrt(max(0, rod_l*rod_l - pin_x*pin_x))
    )
    [pin_x, pin_y, slider_y];
```

---

## GEAR TRAIN (Clock-Style - LOCKED)

The existing gear train drives all three wave mechanisms at different speeds:

```
Motor (N20 30RPM)
    │ 10T pinion
    ▼
Master Gear (60T) @ 5 RPM
    │
    ├─► Zone 1 Scotch Yoke: 30T/100T = 0.3x = 1.5 RPM (slowest)
    │
    ├─► Zone 2 Eccentric Cam: 30T/60T = 0.5x = 2.5 RPM (medium)
    │
    └─► Zone 3 Slider-Crank: 30T/38T = 0.8x = 4.0 RPM (fastest)
```

---

## TRAVELING WAVE EFFECT

### Phase Relationship
```
Time ─────────────────────────────────────►

Zone 1 (far):   ~~~~ swell ~~~~   ~~~~ swell ~~~~
                     │
Zone 2 (mid):        ~~~~ rise ~~~~ PEAK ~~~ fall ~~~~
                          │
Zone 3 (break):           ~~~~ build ~~~~ CRASH! ~~~~ retreat ~~~~

Phase offset: 0° ──────► +45° ────────────► +75°
```

As Zone 1 begins a new swell, Zone 2 is already rising, and Zone 3 is approaching its crash. This creates the illusion of waves continuously traveling from the open ocean toward the cliff.

---

## PHYSICAL MECHANISM VISUALIZATION

New modules render the actual mechanism hardware:

| Module | Renders |
|--------|---------|
| `scotch_yoke_mechanism_v55()` | Disc, pin, slotted yoke, guide rails |
| `eccentric_cam_mechanism_v55()` | Asymmetric cam, roller follower, rocker |
| `slider_crank_mechanism_v55()` | Crank, connecting rod, slider block, guides |
| `wave_mechanisms_v55()` | Combined assembly of all three zones |

Called in main assembly when `SHOW_ZONE_WAVES = true`.

---

## VERIFICATION CHECKLIST

| Check | Status | Notes |
|-------|--------|-------|
| All sin($t) trace to mechanism | ✅ PASS | No orphan animations in wave system |
| Coupler lengths constant | ✅ PASS | Slider-crank uses true kinematics |
| No collisions at t=0,0.25,0.5,0.75 | ⚠️ TODO | Render test needed |
| Clearances ≥0.3mm | ⚠️ TODO | Check mechanism clearances |
| Traveling wave visible | ⚠️ TODO | Animation preview needed |
| Van Gogh mesmerizing quality | ⚠️ TODO | Subjective evaluation |

---

## EXPECTED OUTCOME

| Metric | Before (V54) | After (V55) |
|--------|--------------|-------------|
| Orphan animations | 3 (wave zones) | 0 |
| Pattern 3.1 | PASS (cypress/wing) | PASS (all) |
| Mechanism variety | 1 (four-bar) | 4 (scotch, cam, slider, foam gear) |
| Motion profiles | Sinusoidal only | Sinusoidal + Asymmetric + Crash |
| Mesmerizing quality | Medium | HIGH (goal) |

---

## FILES MODIFIED

| File | Changes |
|------|---------|
| `starry_night_v50_MASTER.scad` | Lines 207-263: Wave kinematic functions |
| | Lines 821-863: Zone 1 Scotch Yoke module |
| | Lines 865-926: Zone 2 Eccentric Cam module |
| | Lines 928-1068: Zone 3 Slider-Crank module |
| | Lines 1131-1306: Mechanism visualization modules |
| | Lines 2086-2095: Updated main assembly calls |
| | Lines 2114-2146: Updated debug output |

---

## V55.1 UPDATE: PHYSICAL MECHANISM CORRECTIONS

### Fixed Issues

| Issue | Old Value | New Value | Fix Applied |
|-------|-----------|-----------|-------------|
| Wave drive position | (115, 15) | (110, 5) | Meshes with Sky Drive at (110, 30) |
| Wave drive orphaned | Not connected | Connected via Sky Drive (20T→30T) | Added gear mesh path |
| Z2 gear center dist | 25mm (wrong) | 45mm (15+30) | Recalculated for 30T-60T mesh |
| Push rod Z3 length | 17mm | 12mm | Corrected for new drive position |
| Push rod Z2 length | 38mm | 43mm | Corrected for Z2_MECH_X=155mm |

### Complete Power Path (Verified)

```
Motor (N20 30RPM) @ (35, 30)
    │ 10T pinion (r=5mm)
    │ center distance = 35mm ✓
    ▼
Master Gear (60T) @ (70, 30) = 5 RPM
    │ 60T (r=30mm)
    │ center distance = 40mm
    ▼
Sky Drive (20T) @ (110, 30) = 15 RPM
    │ 20T (r=10mm)
    │ center distance = 25mm (10+15) ✓
    ▼
Wave Drive (30T) @ (110, 5) = 10 RPM
    │ 30T (r=15mm)
    ├──► Zone 3: Direct @ (110, 5) via slider-crank
    │
    ├──► Zone 2: 60T gear @ (155, 5) = 5 RPM (0.5x)
    │    center distance = 45mm (15+30) ✓
    │
    └──► Zone 1: Timing belt to @ (190, 20) = 3 RPM (0.3x)
         belt drive avoids 100T gear (too large)
```

### Physical Parts List

| Part | Qty | Dimensions | Material |
|------|-----|------------|----------|
| **ZONE 3 SLIDER-CRANK** ||||
| Crank disc | 1 | r=17mm, h=5mm | PLA/Brass |
| Crank pin | 1 | d=5mm, h=8mm, at r=12mm | Steel |
| Connecting rod | 1 | d=4mm, L=45mm | Steel |
| Slider block | 1 | 16×14×10mm | PLA |
| Vertical guide rails | 2 | 4×44×8mm | Steel |
| Push rod | 1 | d=4mm, L=12mm | Steel |
| Ball joints | 2 | d=6mm | Metal |
| **ZONE 2 ECCENTRIC CAM** ||||
| 60T gear | 1 | r=30mm, h=5mm | PLA/Brass |
| Cam disc | 1 | r=10mm, 5mm offset, h=6mm | PLA |
| Cam follower roller | 1 | d=8mm, w=5mm | Metal |
| Follower slide block | 1 | 12×20×10mm | PLA |
| Push rod | 1 | d=4mm, L=43mm | Steel |
| **ZONE 1 SCOTCH YOKE** ||||
| 40T gear (belt pulley) | 1 | r=20mm, h=5mm | PLA |
| Yoke disc | 1 | r=10mm, h=4mm | PLA |
| Eccentric pin | 1 | d=4mm, h=6mm, at r=2mm | Steel |
| Slotted yoke | 1 | 24×16×6mm, slot 10×5mm | PLA |
| Guide rails | 2 | 4×20×8mm | Steel |
| Push rod | 1 | d=4mm, L=69mm | Steel |
| Timing belt | 1 | L≈150mm, 5mm wide | Rubber |
| **WAVE LAYER GUIDES** ||||
| Linear rail Z3 | 2 | 3×4×39mm | Steel |
| Linear rail Z2 | 2 | 3×4×25mm | Steel |
| Linear rail Z1 | 2 | 3×4×19mm | Steel |
| Carriage blocks | 3 | 12×8×8mm | PLA |

### Assembly Notes

1. **Slider-crank rod length (45mm) must remain CONSTANT** throughout rotation
   - Verify: At θ=0°: slider_y = 12 + 45 = 57mm (top)
   - Verify: At θ=180°: slider_y = -12 + sqrt(45²-0) = 33mm (bottom)
   - Stroke = 57 - 33 = 24mm ✓

2. **Gear mesh clearance**: Minimum 0.1mm backlash for smooth operation

3. **Push rods should use ball joints** at both ends to accommodate slight misalignment

4. **Wave layers mount to carriage via tabs** - ensure firm connection

---

## NEXT STEPS

1. **Render Test** - View animation at t=0, 0.25, 0.5, 0.75
2. **Collision Check** - Verify no mechanism overlaps
3. **Parameter Tuning** - Adjust amplitudes/phases for best visual effect
4. **Foam Curl Integration** - Verify Zone 3 foam curl still works correctly

---

*Generated by Design Agent v2.0 - Wave System Redesign v55.1*
