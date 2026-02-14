# USER'S VISION ELEMENTS - STARRY NIGHT PROJECT
## Definitive Reference for Modified Design (V44-V47)

> **CRITICAL**: This document defines ALL elements that diverge from the Van Gogh reference photo.
> These modifications represent the USER'S CREATIVE VISION and MUST be preserved in all versions.

---

## 1. VISION OVERVIEW

The Starry Night kinetic art project is **NOT** a direct replica of Van Gogh's painting.
The user has specified specific mechanical and aesthetic modifications that create a unique
interpretation. All designs must implement these modifications.

### Quick Comparison

| Aspect | Reference Photo (Van Gogh) | USER'S VISION (V44-V47) |
|--------|---------------------------|-------------------------|
| Overall style | Painterly, organic | Mechanical, clockwork |
| Gear approach | Decorative, belt-driven | Functional, mesh-driven |
| Wave motion | Drifting, random | Precise four-bar linkage |
| Sound | Silent | Rice tube mechanism |
| Bird animation | Static or simple | Carrier system with flapping |

---

## 2. CLOCK-STYLE GEAR SYSTEM (LOCKED)

### Design Philosophy
The gear system must resemble a **clock mechanism** - all gears mesh directly
tooth-to-tooth with calculated center distances. **NO BELTS OR CHAINS**.

### Gear Inventory

| Gear | Teeth | Module | Pitch R | Position | Meshes With |
|------|-------|--------|---------|----------|-------------|
| Motor Pinion | 10T | 1.0 | 5mm | (25, 30) | Master Gear |
| Master Gear | 60T | 1.0 | 30mm | (70, 30) | Pinion, Sky, Wave |
| Sky Drive | 20T | 1.0 | 10mm | (110, 30) | Master |
| Wave Drive | 30T | 1.0 | 15mm | (115, 15) | Master |
| Idler 1 | 18T | 1.0 | 9mm | (70, 75) | Idler chain start |
| Idler 2 | 18T | 1.0 | 9mm | (88, 93) | Chain continuation |
| Idler 3 | 18T | 1.0 | 9mm | (106, 111) | To big swirl |
| Idler 4 | 18T | 1.0 | 9mm | (106, 93) | Branch to small swirl |
| Idler 5 | 18T | 1.0 | 9mm | (124, 93) | Chain to small |
| Idler 6 | 18T | 1.0 | 9mm | (142, 102) | To small swirl gear |
| Big Swirl | 24T | 1.0 | 12mm | zone_cx(BIG) | Idler 3 |
| Small Swirl | 24T | 1.0 | 12mm | zone_cx(SMALL) | Idler 6 |
| Moon | 48T | 1.0 | 24mm | zone_cx(MOON) | Via vertical shaft |
| Lighthouse | 36T | 1.0 | 18mm | zone_cx(LH) | Via vertical shaft |

### Gear Support Plate (Skeleton)
A **skeleton-style support plate** at Z=5 with:
- Bearing holes at all gear axle positions
- Material removed where not needed (skeleton look)
- Minimum 3mm wall thickness around holes

---

## 3. FOUR-BAR WAVE MECHANISM (LOCKED)

### Design Philosophy
Waves are driven by a **camshaft with five cranks**, each offset by 30°.
This creates a realistic rolling wave effect, not random drifting.

### Parameters (IMMUTABLE)

```openscad
// Four-bar linkage dimensions
CRANK_LENGTH = 10;      // Driving crank radius
GROUND_LENGTH = 25;     // Distance between pivots
COUPLER_LENGTH = 30;    // Connecting rod length
ROCKER_LENGTH = 25;     // Output rocker length

// Phase offsets for wave layers
WAVE_PHASES = [0, 30, 60, 90, 120];  // degrees

// Wave motion
WAVE_AMPLITUDE = 12;    // degrees, +/-
WAVE_PIVOT_X = 108;     // At cliff edge
```

### Components

| Component | Quantity | Dimensions | Notes |
|-----------|----------|------------|-------|
| Camshaft | 1 | 100mm length | Drives all waves |
| Crank Discs | 5 | R=CRANK_LENGTH | 30° phase offset each |
| Coupler Rods | 5 | COUPLER_LENGTH | Ball joints at ends |
| Wave Layers | 5 | STL imports | Pivot at cliff edge |
| Drive Gear | 1 | 30T | On camshaft end |

### Wave Layer Files
- `ocean_layer_1.stl`
- `ocean_layer_2.stl`
- `ocean_layer_3.stl`
- `ocean_layer_4.stl`
- `ocean_layer_5.stl`

---

## 4. RICE TUBE MECHANISM (LOCKED)

### Design Philosophy
A **functional rain stick** that tilts left/right, creating sound through
internal baffles and rice/beads.

### Parameters

```openscad
RICE_TUBE_LENGTH = 125;
RICE_TUBE_DIA = 24;
RICE_TUBE_WALL = 2;
RICE_TILT_RANGE = 20;    // degrees, +/-
RICE_BAFFLE_COUNT = 8;
RICE_PIVOT_POS = [233, 20];
```

### Components

| Component | Position | Motion | Notes |
|-----------|----------|--------|-------|
| Tube Body | Z=87 | Tilts +/-20° | Clear acrylic or wood |
| End Caps | Tube ends | With tube | 24mm diameter |
| Internal Baffles | Inside tube | Fixed | 8 spiral baffles |
| Pivot Frame | (233, 20) | Fixed | Bearing blocks |
| Linkage Arm | Below tube | Reciprocating | From camshaft |

### Linkage
The rice tube linkage connects to the **wave drive camshaft**, so the
tube tilts in sync with wave motion.

---

## 5. BIRD WIRE SYSTEM (LOCKED)

### Design Philosophy
Birds travel on a **carrier bracket** along parallel wires, not as a
decorative static flock.

### Parameters

```openscad
BIRD_WIRE_Y_LOWER = 81;
BIRD_WIRE_Y_UPPER = 97;
BIRD_WIRE_LENGTH = 302;   // Full canvas width
BIRD_PULLEY_DIA = 12;
BIRD_CARRIER_SIZE = [18, 8, 4];
```

### Components

| Component | Position | Motion | Notes |
|-----------|----------|--------|-------|
| Lower Wire | Y=81 | Fixed | 1mm steel wire |
| Upper Wire | Y=97 | Fixed | 1mm steel wire |
| Left Pulley | X=5 | Rotating | 12mm diameter |
| Right Pulley | X=297 | Rotating | 12mm diameter |
| Carrier Bracket | On wires | Slides L-R | Holds all birds |
| Birds x3 | On carrier | Wing flap | Offset positions |

### Animation

```openscad
bird_cycle = t;
bird_visible = (bird_cycle > 0.1 && bird_cycle < 0.25);
bird_progress = (bird_cycle - 0.1) / 0.15;  // 0-1 during visible
wing_flap = 25 * sin(t * 360 * 8);
```

---

## 6. ANIMATION SPEEDS (LOCKED)

### Speed Hierarchy

| Element | Multiplier | User's Note |
|---------|------------|-------------|
| Motor | 6x | Base drive speed |
| Master Gear | 1x | Reference speed |
| Moon Phase | **0.1x** | "VERY SLOW" |
| Lighthouse Beam | **0.3x** | "SLOW" |
| Big Swirl CW | 0.5x | Counter-rotating |
| Big Swirl CCW | 0.7x | Counter-rotating |
| Small Swirl | Opposite | Counter-rotating |
| Wave Cycle | 1x | Full rotation = cycle |
| Rice Tube | Linked | +/-20° with wave |
| Bird Visible | 10-25% | Intermittent |

### Animation Code

```openscad
t = $t;

// Gear rotation
gear_rot = t * 360 * 0.4;

// Swirls (counter-rotating pairs)
swirl_rot_cw = t * 360 * 0.5;
swirl_rot_ccw = -t * 360 * 0.7;

// Moon - VERY SLOW per user
moon_phase_rot = t * 360 * 0.1;

// Lighthouse - SLOW per user
lighthouse_rot = t * 360 * 0.3;

// Waves
wave_phase = t * 360;

// Rice tube - linked to wave
rice_tilt = 20 * sin(wave_phase);

// Birds - intermittent
bird_cycle = t;
bird_visible = (bird_cycle > 0.1 && bird_cycle < 0.25);
```

---

## 7. ZONE MODIFICATIONS (LOCKED)

### Changed Zones

| Zone | Reference Position | USER'S VISION |
|------|-------------------|---------------|
| ZONE_BOTTOM_GEARS | Right side | **LEFT** [0, 78, 0, 80] |
| ZONE_BIRD_WIRE | Generic placement | **Specific** [0, 302, 81, 97] |

### Element Modifications

| Element | Reference | USER'S VISION |
|---------|-----------|---------------|
| Cliff | Standard scale, generic | +20% scale, flush LEFT and BOTTOM |
| Cypress | Standard scale, generic | 30% bigger, flush BOTTOM |
| Lighthouse | Generic rotation | SLOW rotation, UPRIGHT |
| Moon | Generic rotation | VERY SLOW phase disc |

---

## 8. Z-LAYER ARCHITECTURE (USER'S VISION)

```
Z-LAYER STACK (Back to Front):
================================================================
Z = 0      | Z_BACK - Back panel with motor mount hole
Z = 2      | Z_LED - Star LED positions
Z = 5      | Z_GEAR_PLATE - Skeleton support plate **USER'S VISION**
Z = 8-28   | Z_GEARS - Main gear train **CLOCK-STYLE**
Z = 15     | Z_MOON_PHASE - Rotating phase disc
Z = 20     | Z_MOON_CRESCENT - Fixed crescent
Z = 25     | Z_SWIRL_INNER - Inner swirl discs
Z = 28     | Z_SWIRL_GEAR - Swirl drive gears
Z = 32     | Z_SWIRL_OUTER - Outer swirl discs
Z = 35     | Z_WIND_PATH - Wind path panel with cutouts
Z = 42     | Z_CLIFF - Cliff landscape (+20% scale)
Z = 48     | Z_LIGHTHOUSE - Lighthouse tower (UPRIGHT)
Z = 55     | Z_FOUR_BAR - Four-bar mechanism **USER'S VISION**
Z = 60-76  | Wave layers (4mm each x 5 layers)
Z = 75     | Z_CYPRESS - Cypress tree (30% bigger)
Z = 82     | Z_BIRD_WIRE - Bird wire system **USER'S VISION**
Z = 87     | Z_RICE_TUBE - Rice tube mechanism **USER'S VISION**
Z = 92     | Z_FRAME - Front frame
================================================================
```

---

## 9. REFERENCE FILES

### Primary References (User's Vision)

| File | Version | Content |
|------|---------|---------|
| `Reference/starry_night_v47_assembly.scad` | V47 | Complete assembly |
| `Reference/starry_night_v46_assembly.scad` | V46 | Master spec impl |
| `Reference/starry_night_v45_assembly.scad` | V45 | Zone verification |
| `Reference/starry_night_v44_assembly.scad` | V44 | Clock-style gears |

### Layout References

| File | Status | Content |
|------|--------|---------|
| `Reference/canvas_layout_LOCKED.scad` | LOCKED | Zone definitions |
| `Reference/canvas_layout_FINAL.scad` | LOCKED | Final layout |

### DO NOT USE (Old Vision)

| File | Reason |
|------|--------|
| `Reference/starry_night_v30_assembly.scad` | Reference photo style, NOT user's vision |
| Any version < V44 | Before user's modifications |

---

## 10. SURVIVAL CHECKLIST

### Before Any Edit

```
[ ] Read USER_VISION_ELEMENTS.md (this file)
[ ] Identify which vision elements might be affected
[ ] Plan changes to preserve all vision elements
```

### After Any Edit - Vision Element Survival

```
GEAR SYSTEM (Clock-style, NO BELTS):
[ ] Motor pinion present
[ ] Master gear present
[ ] 6 idler gears present
[ ] All gears mesh directly (no belts)
[ ] Gear support plate present

FOUR-BAR MECHANISM:
[ ] Camshaft present
[ ] 5 crank discs present
[ ] 5 coupler rods present
[ ] 5 wave layers present
[ ] Correct phase offsets [0,30,60,90,120]

SPECIAL MECHANISMS:
[ ] Rice tube present with linkage
[ ] Bird wire system present
[ ] Bird carrier bracket present
[ ] Wind path with cutouts present

ANIMATION SPEEDS:
[ ] Moon = VERY SLOW (0.1x)
[ ] Lighthouse = SLOW (0.3x)
[ ] Swirls counter-rotating

ZONE POSITIONS:
[ ] Bottom gears on LEFT
[ ] Bird wire Y = 81-97
[ ] Cliff flush LEFT/BOTTOM, +20%
[ ] Cypress flush BOTTOM, +30%
```

---

*Document Version: 1.0*
*Created: 2026-01-16*
*Status: LOCKED - User's Vision Definition*
