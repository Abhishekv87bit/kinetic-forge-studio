# STARRY NIGHT V57 - COMPREHENSIVE VERIFICATION & SHAPE REDESIGN

## MISSION

You are tasked with two objectives:
1. **VERIFY** all 7 critical fixes and re-check all 12 elements against the defined design methodology
2. **REDESIGN** the cypress, cliff, and wind path shapes in Van Gogh authentic style to fit their defined zones

---

## PART A: FULL RE-VERIFICATION

### Design Methodology Checklist

For EACH of the 12 elements, verify against these rules from CLAUDE.md:

```
HARD RULES:
[ ] Every sin($t), cos($t) traces to a physical mechanism (no orphans)
[ ] Coupler lengths constant at θ=0°, 90°, 180°, 270° (deviation < 0.5mm)
[ ] Walls ≥ 1.2mm for FDM printing
[ ] Clearances ≥ 0.3mm for moving parts
[ ] Power path documented: Motor → [chain] → Element

DESIGN INTENT:
[ ] Van Gogh score documented (0-10 for aesthetic beauty)
[ ] Watt score documented (0-10 for mechanical simplicity)
[ ] Mechanism type justified (or explicitly marked SIMPLIFIED)
```

### Elements to Verify (12)

| # | Element | Zone | Animation | Check |
|---|---------|------|-----------|-------|
| 1 | Stars (5) | Sky | gear_rot_star = master_phase * 0.5 * ratio | Power path |
| 2 | Moon | ZONE_MOON | moon_phase_rot = t * 360 * 0.1 | LOCKED 0.1x |
| 3 | Big Swirl | ZONE_BIG_SWIRL | swirl_rot_ccw | Belt-driven? |
| 4 | Small Swirl | ZONE_SMALL_SWIRL | swirl_rot_cw | Belt-driven? |
| 5 | Lighthouse | ZONE_LIGHTHOUSE | lighthouse_rot | 27T pulley fix? |
| 6 | Cypress | ZONE_CYPRESS | cypress_sway_back/front | Eccentric gear fix? |
| 7 | Cliff | ZONE_CLIFF | (none - static) | Zone fit |
| 8 | Wind Path | ZONE_WIND_PATH | (none - static) | Zone fit + cutouts |
| 9 | Birds | Sky | bird_pendulum_angle, wing_flap | Crank-slider fix? |
| 10 | Rice Tube | Lower right | rice_tilt | Eccentric fix? |
| 11 | Waves (Z1-3) | ZONE_COMBINED_WAVES | curl_rot_zone* | Mechanical ratios? |
| 12 | Foam Curls | Wave zones | curl_rot_zone* | Gear mesh verified? |

### Critical Fix Verification (7)

For each fix, confirm:

**C1: Cypress** - Was `cypress_sway_back = 4 * sin(t * 360 * 0.35)` replaced with mechanized formula using `gear_rot * (18/45)`?

**C2: Rice Tube** - Was `rice_tilt = 20 * sin(master_phase)` replaced with `asin(eccentric_throw / linkage_length)`?

**C3: Birds** - Was pendulum orphan fixed? Was wing_flap reduced from 8x to 4x?

**C4: Swirls** - Do `swirl_rot_cw/ccw` now derive from `swirl_belt_driven = -gear_rot * (20/24)`?

**C5: Lighthouse** - Is pulley now 27T (not 20T)? Does `lighthouse_rot = -gear_rot * 0.75`?

**C6: Moon Belt** - Is belt at Z=12 (not Z=7)? No collision with Star Belt?

**C7: Wave Foams** - Do ratios match `gear_rot * 2 * (teeth/30)` instead of arbitrary 0.3/0.5/0.8?

### Mechanism Verification (8)

| Mechanism | Expected | Verify |
|-----------|----------|--------|
| Gear Train | Motor(10T)→Master(60T)→Sky(20T)→Wave(30T) | CD = 35mm, 40mm, 45mm |
| Belt: Stars | 20T drive → 5 prime pulleys | Z=7 |
| Belt: Moon | 16T→40T = 0.4x, combined 0.1x | Z=12 (fixed) |
| Belt: Swirls | 20T→24T×2 + 2 idlers | Z=17 |
| Belt: Lighthouse | 20T→27T = 0.75x | Z=23 |
| Pendulum: Cypress | 45T eccentric + 50mm/45mm linkages | ±2.3°/±2.5° |
| Pendulum: Birds | 5mm crank + 30mm linkage | ±30° swing |
| Eccentric: Rice | 10mm offset + 30mm arm | ±19.5° tilt |

---

## PART B: SHAPE REDESIGN

### Design Constraints

**Style:** Van Gogh authentic - swirling, expressive, organic curves that capture emotional turbulence

**Zone Fit:** Visual center priority
- Center of mass MUST be within zone
- Edges CAN extend for dramatic effect
- Document any overhang with justification

### Shape 1: CYPRESS

**Zone Definition:**
```openscad
ZONE_CYPRESS = [35, 95, 0, 121];
// X: 35-95 (width = 60mm)
// Y: 0-121 (height = 121mm)
// Center: (65, 60.5)
```

**Current Reference (V56):**
- Dual layer design (back + front for beat pattern)
- Flame-like silhouette with organic curves
- Dark green (#1a3d1a) to lighter green (#2a5a2a)
- Sways ±2-3° at pivot base

**Van Gogh Authentic Redesign Requirements:**
- Tall, narrow, flame-like form reaching skyward
- Swirling internal texture suggesting wind movement
- Organic, asymmetric edges (not geometric)
- Base narrower than middle (flame shape)
- Peak can extend slightly above zone for drama

**Output Required:**
```openscad
// CYPRESS BACK LAYER - Van Gogh Authentic
cypress_back_points = [
    [x0, y0],  // Base left
    [x1, y1],  // ...
    // Provide 15-25 points tracing organic silhouette
];

// CYPRESS FRONT LAYER - Slightly smaller, offset
cypress_front_points = [
    // Similar but 90% scale, 5% X offset
];
```

### Shape 2: CLIFF

**Zone Definition:**
```openscad
ZONE_CLIFF = [0, 108, 0, 65];
// X: 0-108 (width = 108mm)
// Y: 0-65 (height = 65mm)
// Center: (54, 32.5)
```

**Current Reference (V56):**
- Trapezoid base suggesting rocky outcrop
- Brown tones (#6b5344)
- Connects visually to lighthouse zone above
- Provides grounding anchor for dynamic waves

**Van Gogh Authentic Redesign Requirements:**
- Craggy, irregular cliff face (not smooth trapezoid)
- Layered rock strata suggesting geological depth
- Organic edge where waves would crash against cliff
- Left edge can be vertical (frame boundary)
- Right edge slopes dramatically toward waves

**Output Required:**
```openscad
// CLIFF SHAPE - Van Gogh Authentic Craggy Profile
cliff_profile_points = [
    [0, 0],        // Bottom left (frame edge)
    // ... 20-30 points for irregular rocky outline
    [0, height],   // Top left
];

// Optional: CLIFF LAYER 2 (rock strata detail)
cliff_strata_points = [
    // Subset for visual depth
];
```

### Shape 3: WIND PATH

**Zone Definition:**
```openscad
ZONE_WIND_PATH = [0, 198, 100, 202];
// X: 0-198 (width = 198mm)
// Y: 100-202 (height = 102mm)
// Center: (99, 151)
```

**Current Reference (V56):**
- Imported wrapper shape scaled 0.178x
- Cutouts for big swirl (39mm r) and small swirl (25.5mm r)
- Light blue background (#1a4a7e)
- Guides eye through sky zone

**Van Gogh Authentic Redesign Requirements:**
- Flowing, swirling bands suggesting wind currents
- Curves should echo the swirl disc patterns
- NOT a solid rectangle - organic flowing boundary
- Must accommodate swirl cutouts
- Can extend slightly beyond zone edges for flow

**Output Required:**
```openscad
// WIND PATH OUTER BOUNDARY - Flowing organic edge
wind_path_outer = [
    [x0, y0],
    // 30-40 points for swirling boundary
];

// WIND PATH WITH CUTOUTS (difference operation)
// Big swirl cutout center: (123, 140) relative to zone, r=39
// Small swirl cutout center: (174.5, 122) relative to zone, r=25.5
```

---

## PART C: VERIFICATION OUTPUT FORMAT

### Per-Element Report

```
=== ELEMENT: [Name] ===
Zone: [coordinates]
Animation Variables: [list]
Power Path: Motor → ... → Element

ORPHAN CHECK:
[ ] PASS / FAIL - All animations mechanically driven

GEOMETRY CHECK:
[ ] PASS / FAIL - Walls ≥ 1.2mm
[ ] PASS / FAIL - Clearances ≥ 0.3mm
[ ] PASS / FAIL - Zone fit (center in zone)

MECHANISM:
Type: [name]
Van Gogh Score: X/10
Watt Score: X/10
Status: VERIFIED / SIMPLIFIED / NEEDS FIX

COLLISION CHECK (at θ=0°, 90°, 180°, 270°):
[ ] PASS / FAIL - No intersections with adjacent elements
```

### Summary Matrix

```
| Element | Orphan | Geometry | Mechanism | Collision | Overall |
|---------|--------|----------|-----------|-----------|---------|
| Stars   | PASS   | PASS     | VERIFIED  | PASS      | ✅      |
| Moon    | PASS   | PASS     | LOCKED    | PASS      | ✅      |
| ...     |        |          |           |           |         |
```

---

## PART D: SHAPE OUTPUT FORMAT

For each redesigned shape, provide:

1. **OpenSCAD polygon points** (ready to paste)
2. **Bounding box** (min/max X, Y)
3. **Center of mass** (calculated)
4. **Zone fit analysis** (center in zone? overhangs?)
5. **ASCII preview** (rough shape visualization)

Example:
```openscad
// CYPRESS BACK LAYER - Van Gogh Authentic
// Bounding box: X[38, 92], Y[0, 125]
// Center of mass: (65, 58) - WITHIN ZONE ✓
// Overhang: +4mm top (justified: flame peak drama)

cypress_back_points = [
    [50, 0],      // Base center-left
    [60, 0],      // Base center-right
    [65, 15],     // Lower trunk
    [70, 30],     // Trunk widens
    [75, 50],     // Mid-trunk
    [80, 70],     // Upper trunk
    [85, 85],     // Lower canopy
    [88, 95],     // Canopy bulge
    [90, 105],    // Upper canopy
    [85, 115],    // Peak approach
    [75, 122],    // Near peak
    [65, 125],    // PEAK (extends 4mm above zone)
    [55, 120],    // Descending peak
    [48, 110],    // Upper left canopy
    [42, 95],     // Left canopy
    [40, 80],     // Mid-left
    [42, 60],     // Lower left trunk
    [45, 40],     // Trunk narrowing
    [48, 20],     // Lower trunk
    [50, 0]       // Close to base
];
```

---

## EXECUTION INSTRUCTIONS

1. **Read V57 code** (or V56 + fix plan if V57 not yet created)
2. **Verify all 12 elements** against methodology
3. **Verify all 7 critical fixes** implemented correctly
4. **Redesign 3 shapes** with full polygon output
5. **Generate summary matrix** and recommendations

**Output files to create:**
- `VERIFICATION_REPORT_V57.md` - Full verification results
- `CYPRESS_REDESIGN_V57.scad` - New polygon points
- `CLIFF_REDESIGN_V57.scad` - New polygon points
- `WIND_PATH_REDESIGN_V57.scad` - New polygon points
- `SHAPE_PREVIEW_DIAGRAMS.md` - ASCII art previews

---

*Prompt ready for execution*
