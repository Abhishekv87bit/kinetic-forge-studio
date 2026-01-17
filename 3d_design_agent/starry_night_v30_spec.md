# MASTER SPECIFICATION - STARRY NIGHT V48
## User's Modified Vision (V44-V47 + Wave Enhancement + Star Twinkle)

> **PURPOSE**: This document is the single source of truth for the STARRY NIGHT kinetic art project.
> V48 implements the USER'S MODIFIED VISION with enhanced wave physics and star twinkle system.

---

## V48 ENHANCEMENTS (NEW)

| Feature | Description | Status |
|---------|-------------|--------|
| **3-Zone Wave System** | Far/Mid/Breaking zones with physics-based motion | IMPLEMENTED |
| **Articulated Breaking Wave** | Multi-segment hinged mechanism that curls over | IMPLEMENTED |
| **11-Star Twinkle System** | Counter-rotating gear + halo creates sparkle | IMPLEMENTED |
| **Cypress Wind Sway** | +/-3° oscillation coupled to wind path | IMPLEMENTED |
| **Swirl Z-Pulse** | +/-2mm breathing motion on swirl discs | IMPLEMENTED |

### Wave Zone Specifications

| Zone | Position | Motion | Crank Throw | Phase |
|------|----------|--------|-------------|-------|
| Far Ocean | 70-100% | Gentle bob +/-2mm | 5mm | master + 0° |
| Mid Ocean | 40-70% | Drift +/-3mm, Bob +/-5mm | 8mm | master + 30° |
| Breaking | 0-40% | Articulated curl 0-120° | 15mm | master + 60° |

### Articulated Breaking Wave Motion Sequence

```
PHASE 0-120°:   Wave rises, crest lifts, lip begins curl
PHASE 120-180°: Lip folds over dramatically (the "crash")
PHASE 180-360°: Wave retreats, resets for next cycle

Components:
  1. Base Swell    - Fixed pivot at cliff edge, +/-8° tilt
  2. Rising Crest  - Hinged to base, 0-25° lift
  3. Curling Lip   - Hinged to crest, 0-120° fold
  4. Spray Tips    - Detach during crash, 15mm scatter
```

---

## CRITICAL: USER'S VISION vs REFERENCE PHOTO

> **THIS IS NOT A REPLICA OF THE PAINTING**
>
> The user has specified modifications that diverge from Van Gogh's original:
> - Clock-style interconnected gear system (NO belts)
> - Gear support plate (skeleton with bearing holes)
> - Four-bar linkage wave mechanism (NOT simple drift/bob)
> - Rice tube mechanism (functional, driven by wave linkage)
> - Bird wire carrier system (NOT decorative flock)
> - Wind path as foreground element with swirl cutouts
> - Specific animation speeds (Moon: VERY SLOW, Lighthouse: SLOW)

---

## 1. PROJECT OVERVIEW

```
Project Name: Starry Night Kinetic Automaton
Current Version: V48 (Wave Enhancement + Star Twinkle)
Last Updated: 2026-01-16
Status: In Development
Base Reference: V47 (Complete Assembly with User's Vision)
New Features: 3-Zone Waves, Articulated Breaking Wave, 11-Star Twinkle

Description:
A kinetic wooden automaton implementing the USER'S MODIFIED VISION of
Van Gogh's "The Starry Night". Features clock-style interconnected gears,
four-bar linkage wave mechanism, functional rice tube, and carrier-based
bird wire system.

KEY DIFFERENCES FROM REFERENCE PHOTO:
- Gear System: Clock-style mesh (NO belts) vs decorative gears
- Wave Mechanism: Four-bar linkage vs simple animation
- Rice Tube: Functional L/R tilt vs absent
- Bird System: Carrier bracket vs decorative flock

Target Display Size: Desktop/shelf display
Material: 3mm plywood (laser cut)
Power: 5V USB via N20 geared motor
```

---

## 2. DIMENSIONS & BOUNDARIES (LOCKED)

### 2.1 Overall Dimensions

```
Overall Frame (Outer Envelope):
+-------------------------------------+
|  Width:  350 mm  (X-axis)           |
|  Height: 275 mm  (Y-axis)           |  <- Changed from 250mm in some versions
|  Depth:   95 mm  (Z-axis)           |  <- Increased for rice tube clearance
+-------------------------------------+

Canvas Art Area (Inner):
- Width:  302 mm  (INNER_W = IW - 2*TAB_W)
- Height: 227 mm  (INNER_H = IH - 2*TAB_W)
- Frame Width: 20mm
- Tab Width: 4mm
```

### 2.2 Zone Definitions (LOCKED - from canvas_layout_FINAL)

```
Format: [X_MIN, X_MAX, Y_MIN, Y_MAX] - All relative to inner canvas origin

GROUND LEVEL ZONES:
  ZONE_CLIFF        = [0, 108, 0, 65]       // Flush LEFT and BOTTOM
  ZONE_LIGHTHOUSE   = [73, 82, 65, 117]     // ON TOP of cliff
  ZONE_CYPRESS      = [35, 95, 0, 121]      // Flush BOTTOM, 30% bigger
  ZONE_CLIFF_WAVES  = [78, 164, 0, 80]      // Breaking waves at cliff
  ZONE_OCEAN_WAVES  = [164, 302, 0, 52]     // Open water
  ZONE_BOTTOM_GEARS = [0, 78, 0, 80]        // ** MOVED TO LEFT ** (User's vision)

SKY ZONES:
  ZONE_WIND_PATH    = [0, 198, 100, 202]    // Foreground element
  ZONE_BIG_SWIRL    = [86, 160, 110, 170]   // Large swirl disc
  ZONE_SMALL_SWIRL  = [151, 198, 98, 146]   // Small swirl disc
  ZONE_MOON         = [231, 300, 141, 202]  // Top right
  ZONE_SKY_GEARS    = [195, 275, 125, 202]  // Sky mechanism area

HORIZONTAL ELEMENTS:
  ZONE_BIRD_WIRE    = [0, 302, 81, 97]      // ** SPECIFIC Y RANGE ** (User's vision)
```

### 2.3 Lock Status

| Dimension | Value | Locked | Lock Date | Rationale |
|-----------|-------|--------|-----------|-----------|
| Frame Width | 350mm | YES | 2026-01-10 | Fits standard shelf |
| Frame Height | 275mm | YES | 2026-01-10 | Increased for mechanism space |
| Frame Depth | 95mm | YES | 2026-01-16 | Increased for rice tube |
| Zone Definitions | Per V47 | YES | 2026-01-16 | User's modified layout |
| Bottom Gears Zone | LEFT side | YES | 2026-01-16 | User's vision - gears on LEFT |
| Bird Wire Y | 81-97mm | YES | 2026-01-16 | User's specific placement |

---

## 3. COMPONENT INVENTORY

### 3.1 Structural Components

| Component | Status | Z-Layer | Dimensions | Notes |
|-----------|--------|---------|------------|-------|
| Back Panel | Present | Z_BACK=0 | 350x275x3 | Motor mount hole |
| Gear Support Plate | **REQUIRED** | Z_GEAR_PLATE=5 | Skeleton | Bearing holes for ALL axles |
| Frame | Present | Z_FRAME=92 | 350x275x5 | Decorative border |

### 3.2 Clock-Style Gear Train (USER'S VISION - NO BELTS)

| Component | Status | Position | Teeth | Pitch R | Meshes With |
|-----------|--------|----------|-------|---------|-------------|
| Motor Pinion | Required | (25, 30) | 10T | 5mm | Master Gear |
| Master Gear | Required | (70, 30) | 60T | 30mm | Motor Pinion |
| Sky Drive | Required | (110, 30) | 20T | 10mm | Master |
| Wave Drive | Required | (115, 15) | 30T | 15mm | Master |
| Idler 1 | Required | (70, 75) | 18T | 9mm | Chain to swirls |
| Idler 2 | Required | (88, 93) | 18T | 9mm | Chain |
| Idler 3 | Required | (106, 111) | 18T | 9mm | To big swirl |
| Idler 4 | Required | (106, 93) | 18T | 9mm | Branch to small |
| Idler 5 | Required | (124, 93) | 18T | 9mm | Chain |
| Idler 6 | Required | (142, 102) | 18T | 9mm | To small swirl |
| Big Swirl Gear | Required | zone_cx(BIG) | 24T | 12mm | Idler 3 |
| Small Swirl Gear | Required | zone_cx(SMALL) | 24T | 12mm | Idler 6 |
| Moon Gear | Required | zone_cx(MOON) | 48T | 24mm | Via shaft |
| Lighthouse Gear | Required | zone_cx(LH) | 36T | 18mm | Via shaft |

**GEAR MODULE: 1.0** (or 1.5 for visibility)

**CRITICAL**: All gears mesh directly tooth-to-tooth. NO BELTS.

### 3.3 Four-Bar Wave Mechanism (USER'S VISION)

| Component | Status | Position | Dimensions | Notes |
|-----------|--------|----------|------------|-------|
| Camshaft | Required | Z_FOUR_BAR=55 | 100mm length | Drives all 5 wave layers |
| Crank Disc x5 | Required | On camshaft | R=CRANK_LENGTH | 30 deg phase offset each |
| Coupler Rods x5 | Required | Crank to wave | COUPLER_LENGTH=30mm | Ball joints |
| Wave Layers x5 | Required | STL imports | Pivot at cliff edge | +/-12 deg oscillation |
| Drive Gear | Required | Camshaft end | 30T | Connects to master train |

**FOUR-BAR PARAMETERS (LOCKED):**
```
CRANK_LENGTH = 10mm
GROUND_LENGTH = 25mm
COUPLER_LENGTH = 30mm
ROCKER_LENGTH = 25mm
WAVE_PHASES = [0, 30, 60, 90, 120] degrees
```

### 3.4 Rice Tube Mechanism (USER'S VISION)

| Component | Status | Position | Motion | Notes |
|-----------|--------|----------|--------|-------|
| Rice Tube | Required | Z_RICE_TUBE=87 | L/R tilt +/-20 deg | 125mm length |
| Pivot Frame | Required | (233, 20) | Fixed | Bearing blocks |
| Linkage Arm | Required | Below tube | Driven by wave | Connects to camshaft |
| End Caps | Required | Tube ends | With tube | 24mm diameter |
| Internal Baffles | Required | Inside tube | Fixed | 8 baffles |

### 3.5 Bird Wire System (USER'S VISION)

| Component | Status | Position | Motion | Notes |
|-----------|--------|----------|--------|-------|
| Upper Wire | Required | Y=97 | Fixed | Full width 302mm |
| Lower Wire | Required | Y=81 | Fixed | Full width 302mm |
| End Pulleys x2 | Required | X=5, X=297 | Rotating | 12mm diameter |
| Carrier Bracket | Required | On wires | Slides L-R | 18x8x4mm |
| Birds x3 | Required | On carrier | Wing flap | Offset positions |

**BIRD ANIMATION:**
```
bird_cycle = t
bird_visible = (bird_cycle > 0.1 && bird_cycle < 0.25)
bird_progress = linear during visible window
wing_flap = 25 * sin(t * 360 * 8)
```

### 3.6 Landscape Elements

| Component | Status | Z-Layer | Position | Notes |
|-----------|--------|---------|----------|-------|
| Cliff | Present | Z_CLIFF=42 | [0,108,0,65] | +20% scale, flush LEFT/BOTTOM |
| Lighthouse | Present | Z_LIGHTHOUSE=48 | On cliff top | UPRIGHT, SLOW rotation |
| Cypress | Present | Z_CYPRESS=75 | [35,95,0,121] | 30% bigger, flush BOTTOM |
| Wind Path | Present | Z_WIND_PATH=35 | [0,198,100,202] | Holes aligned to swirls |

### 3.7 Sky Elements

| Component | Status | Z-Layer | Position | Motion |
|-----------|--------|---------|----------|--------|
| Big Swirl Inner | Present | Z_SWIRL_INNER=25 | zone_cx(BIG) | CCW 0.7x |
| Big Swirl Outer | Present | Z_SWIRL_OUTER=32 | zone_cx(BIG) | CW 0.5x |
| Small Swirl Inner | Present | Z_SWIRL_INNER=25 | zone_cx(SMALL) | CW 0.5x |
| Small Swirl Outer | Present | Z_SWIRL_OUTER=32 | zone_cx(SMALL) | CCW 0.7x |
| Moon Phase Disc | Present | Z_MOON_PHASE=15 | zone_cx(MOON) | VERY SLOW 0.1x |
| Moon Crescent | Present | Z_MOON_CRESCENT=20 | zone_cx(MOON) | Fixed |
| Star LEDs x11 | Present | Z_LED=2 | Various | Static backlight |

---

## 4. Z-LAYER ARCHITECTURE (from V47)

```
Z-LAYER STACK (Back to Front):
================================================================
Z = 0      | Z_BACK - Back panel
Z = 2      | Z_LED - Star LED positions
Z = 5      | Z_GEAR_PLATE - Skeleton support plate
Z = 8-28   | Z_GEARS - Main gear train
Z = 15     | Z_MOON_PHASE - Rotating phase disc
Z = 20     | Z_MOON_CRESCENT - Fixed crescent
Z = 25     | Z_SWIRL_INNER - Inner swirl discs
Z = 28     | Z_SWIRL_GEAR - Swirl drive gears
Z = 32     | Z_SWIRL_OUTER - Outer swirl discs
Z = 35     | Z_WIND_PATH - Wind path panel
Z = 42     | Z_CLIFF - Cliff landscape
Z = 48     | Z_LIGHTHOUSE - Lighthouse tower
Z = 55     | Z_FOUR_BAR - Four-bar mechanism
Z = 60     | Z_WAVE_START - Wave layers begin
Z = 60-76  | Wave layers (4mm each x 5 layers)
Z = 75     | Z_CYPRESS - Cypress tree (FRONT)
Z = 82     | Z_BIRD_WIRE - Bird wire system
Z = 87     | Z_RICE_TUBE - Rice tube mechanism
Z = 92     | Z_FRAME - Front frame
================================================================
```

---

## 5. ANIMATION PARAMETERS (USER'S CHOICES)

### 5.1 Speed Settings

| Element | Speed | User Note |
|---------|-------|-----------|
| Motor | 6x base | Standard |
| Master Gear | 1x base | Reference |
| Moon Phase | **0.1x** | VERY SLOW per user |
| Lighthouse | **0.3x** | SLOW per user |
| Big Swirl CW | 0.5x | Counter-rotating pair |
| Big Swirl CCW | 0.7x | Counter-rotating pair |
| Small Swirl | Opposite | Counter-rotating |
| Wave Phase | 1x | Full rotation = full cycle |
| Bird | Visible 10-25% | Intermittent appearance |
| Rice Tube | Linked to wave | +/-20 deg tilt |

### 5.2 Animation Code

```openscad
t = $t;

// Base rotations
gear_rot = t * 360 * 0.4;

// Swirls (counter-rotating)
swirl_rot_cw = t * 360 * 0.5;
swirl_rot_ccw = -t * 360 * 0.7;

// Moon (VERY SLOW)
moon_phase_rot = t * 360 * 0.1;

// Lighthouse (SLOW)
lighthouse_rot = t * 360 * 0.3;

// Waves
wave_phase = t * 360;
WAVE_PHASES = [0, 30, 60, 90, 120];

// Rice tube
rice_tilt = 20 * sin(wave_phase);

// Bird
bird_cycle = t;
bird_visible = (bird_cycle > 0.1 && bird_cycle < 0.25);
wing_flap = 25 * sin(t * 360 * 8);
```

---

## 6. LOCKED DECISIONS (USER'S VISION)

| ID | Decision | Value | Date | Impact if Changed |
|----|----------|-------|------|-------------------|
| L001 | Gear System Style | Clock-style mesh, NO BELTS | 2026-01-16 | All gear positions invalid |
| L002 | Gear Support Plate | Skeleton with bearing holes | 2026-01-16 | Axle support lost |
| L003 | Wave Mechanism | Four-bar linkage, 5 layers | 2026-01-16 | Animation style changes |
| L004 | Wave Phases | 30 deg offset per layer | 2026-01-16 | Rolling effect lost |
| L005 | Rice Tube | Functional, L/R tilt | 2026-01-16 | Sound effect lost |
| L006 | Bird System | Carrier bracket, not flock | 2026-01-16 | Animation style changes |
| L007 | Moon Speed | VERY SLOW (0.1x) | 2026-01-16 | User preference |
| L008 | Lighthouse Speed | SLOW (0.3x) | 2026-01-16 | User preference |
| L009 | Bottom Gears | LEFT side zone | 2026-01-16 | Layout changes |
| L010 | Bird Wire Y | 81-97mm range | 2026-01-16 | Position changes |
| L011 | Cypress | 30% bigger, flush bottom | 2026-01-16 | Scale/position changes |
| L012 | Cliff | +20% scale, flush left/bottom | 2026-01-16 | Scale/position changes |

---

## 7. MECHANISM CHAIN (Power Flow - User's Vision)

```
                              MOTOR (N20, 60 RPM)
                                     |
                                     v
                           +------------------+
                           |  MOTOR PINION    |
                           |  10T, Module 1.0 |
                           +--------+---------+
                                    |
                    Center Distance = (10+60)*1.0/2 = 35mm
                                    |
                                    v
                           +------------------+
                           |  MASTER GEAR     |
                           |  60T, 6:1 ratio  |
                           +--------+---------+
                                    |
        +---------------------------+---------------------------+
        |                           |                           |
        v                           v                           v
+---------------+          +---------------+          +---------------+
|  SKY DRIVE    |          |  WAVE DRIVE   |          |  IDLER CHAIN  |
|  20T gear     |          |  30T gear     |          |  To swirls    |
+-------+-------+          +-------+-------+          +-------+-------+
        |                          |                          |
        v                          v                          |
+---------------+          +---------------+          +-------+-------+
| Moon + Light  |          |  CAMSHAFT     |          |               |
| via shafts    |          |  Four-bar     |          v               v
+---------------+          +-------+-------+   +----------+    +----------+
                                   |           |BIG SWIRL |    |SM SWIRL  |
                           +-------+-------+   |CCW + CW  |    |CW + CCW  |
                           |               |   +----------+    +----------+
                           v               v
                    +-----------+   +-----------+
                    | 5 WAVE    |   | RICE TUBE |
                    | LAYERS    |   | L/R tilt  |
                    | (STL)     |   +-----------+
                    +-----------+
```

---

## 8. VERSION HISTORY

| Version | Date | Summary | Key Changes |
|---------|------|---------|-------------|
| V47 | 2026-01-16 | Complete assembly with user's vision | All mechanisms connected |
| V46 | 2026-01-16 | Master spec implementation | Four-bar, rice tube |
| V45 | 2026-01-16 | Verified against canvas_layout_FINAL | Zone corrections |
| V44 | 2026-01-16 | Clock-style gear system | NO BELTS, gear plate |
| V30 | 2026-01-16 | **THIS VERSION** - Corrected to inherit V47 | Full user vision |

### Recovery Points

| Version | Purpose | File |
|---------|---------|------|
| V47 | Last known good with full vision | starry_night_v47_assembly.scad |
| V44 | Clock-style gears introduced | starry_night_v44_assembly.scad |

---

## 9. COMPONENT SURVIVAL CHECKLIST

Run after EVERY edit:

```
STRUCTURAL:
[ ] Back panel
[ ] Gear support plate (skeleton)
[ ] Frame

GEAR TRAIN (11 gears minimum):
[ ] Motor pinion (10T)
[ ] Master gear (60T)
[ ] Sky drive (20T)
[ ] Wave drive (30T)
[ ] Idler 1-6 (18T each)
[ ] Big swirl gear (24T)
[ ] Small swirl gear (24T)
[ ] Moon gear (48T)
[ ] Lighthouse gear (36T)

FOUR-BAR MECHANISM:
[ ] Camshaft (100mm)
[ ] Crank discs x5
[ ] Coupler rods x5
[ ] Wave layers x5

LANDSCAPE:
[ ] Cliff (+20% scale)
[ ] Lighthouse (UPRIGHT)
[ ] Cypress (30% bigger)
[ ] Wind path (with holes)

SKY:
[ ] Big swirl (2 discs)
[ ] Small swirl (2 discs)
[ ] Moon phase disc
[ ] Moon crescent
[ ] Star LEDs

SPECIAL MECHANISMS:
[ ] Rice tube with linkage
[ ] Bird wire system
[ ] Bird carrier bracket
```

---

## 10. FILES REFERENCE

| File | Purpose | Status |
|------|---------|--------|
| `Reference/starry_night_v47_assembly.scad` | Complete user's vision | REFERENCE |
| `Reference/starry_night_v46_assembly.scad` | Master spec implementation | REFERENCE |
| `Reference/starry_night_v45_assembly.scad` | Zone-verified version | REFERENCE |
| `Reference/starry_night_v44_assembly.scad` | Clock-style gears | REFERENCE |
| `Reference/canvas_layout_LOCKED.scad` | Zone definitions | LOCKED |
| `Reference/canvas_layout_FINAL.scad` | Final layout reference | LOCKED |

---

## APPENDIX: QUICK REFERENCE CARD

```
+===============================================================================+
|                    STARRY NIGHT V30 - USER'S VISION                          |
+===============================================================================+
|                                                                               |
| KEY DIFFERENCES FROM REFERENCE PHOTO:                                         |
| - Clock-style gear mesh (NO BELTS)                                           |
| - Four-bar linkage waves (NOT simple drift)                                  |
| - Rice tube mechanism (FUNCTIONAL)                                           |
| - Bird carrier system (NOT decorative flock)                                 |
| - Moon: VERY SLOW (0.1x)                                                     |
| - Lighthouse: SLOW (0.3x)                                                    |
|                                                                               |
| GEAR MODULE: 1.0 (or 1.5 for visibility)                                     |
| WAVE PHASES: [0, 30, 60, 90, 120] degrees                                    |
| FOUR-BAR: Crank=10, Ground=25, Coupler=30, Rocker=25                         |
|                                                                               |
| ZONE CHANGES FROM REFERENCE:                                                  |
| - ZONE_BOTTOM_GEARS moved to LEFT [0, 78, 0, 80]                             |
| - ZONE_BIRD_WIRE specific Y range [0, 302, 81, 97]                           |
|                                                                               |
| BASE VERSION: V47 (starry_night_v47_assembly.scad)                           |
|                                                                               |
+===============================================================================+
```

---

*Specification Version: V30 (Corrected)*
*Created: 2026-01-16*
*Base Reference: V44-V47 (User's Modified Vision)*
*Status: Ready for Development*
