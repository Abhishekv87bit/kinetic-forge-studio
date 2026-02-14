# MASTER SPECIFICATION TEMPLATE
## Starry Night Kinetic Art Project

> **PURPOSE**: This document is the single source of truth for all project dimensions,
> components, and decisions. Once a value is locked, it MUST NOT change without explicit
> version control and rationale documentation.

---

## CRITICAL: USER'S MODIFIED VISION (V44-V47)

> **THIS PROJECT IMPLEMENTS THE USER'S MODIFIED VISION, NOT A REPLICA OF THE PAINTING**
>
> The following elements diverge from the Van Gogh reference photo and MUST be preserved:

### Vision Elements (LOCKED)

| Element | Reference Photo Style | USER'S VISION (V44-V47) | Status |
|---------|----------------------|-------------------------|--------|
| **Gear System** | Decorative gears + belts | Clock-style interconnected, NO BELTS | LOCKED |
| **Gear Support** | None | Skeleton plate with bearing holes | LOCKED |
| **Wave Mechanism** | Simple drift/bob | Four-bar linkage, 5 layers, 30° phase | LOCKED |
| **Rice Tube** | Not present | Functional L/R tilt, driven by camshaft | LOCKED |
| **Bird System** | 3-bird decorative flock | Carrier bracket on parallel wires | LOCKED |
| **Wind Path** | Standard swirl | Foreground element with swirl cutouts | LOCKED |
| **Moon Speed** | Standard rotation | VERY SLOW (0.1x base) | LOCKED |
| **Lighthouse Speed** | Standard rotation | SLOW (0.3x base) | LOCKED |
| **Cypress** | Standard placement | 30% bigger, flush BOTTOM | LOCKED |
| **Cliff** | Standard placement | +20% scale, flush LEFT/BOTTOM | LOCKED |
| **Bottom Gears Zone** | Right side | LEFT side [0, 78, 0, 80] | LOCKED |
| **Bird Wire Y** | Generic | Specific range [0, 302, 81, 97] | LOCKED |

### Four-Bar Mechanism Parameters (LOCKED)

```
CRANK_LENGTH = 10mm
GROUND_LENGTH = 25mm
COUPLER_LENGTH = 30mm
ROCKER_LENGTH = 25mm
WAVE_PHASES = [0, 30, 60, 90, 120] degrees (30° offset per layer)
```

### Animation Speed Reference

| Element | Speed Multiplier | Notes |
|---------|-----------------|-------|
| Motor | 6x | Base drive |
| Moon Phase | 0.1x | VERY SLOW per user |
| Lighthouse | 0.3x | SLOW per user |
| Swirl CW | 0.5x | Counter-rotating pair |
| Swirl CCW | 0.7x | Counter-rotating pair |
| Waves | 1x | Full cycle = full rotation |
| Rice Tube | Linked | +/-20° tilt with wave |
| Bird | Intermittent | Visible 10-25% of cycle |

### Base Reference Files

| File | Purpose |
|------|---------|
| `Reference/starry_night_v47_assembly.scad` | Complete user's vision |
| `Reference/starry_night_v44_assembly.scad` | Clock-style gears introduced |
| `Reference/canvas_layout_LOCKED.scad` | Zone definitions |

---

## 1. PROJECT OVERVIEW

```
Project Name: Starry Night Kinetic Automaton
Current Version: V30 (Inherits V44-V47 Vision)
Last Updated: 2026-01-16
Status: In Development

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

**HOW TO USE THIS SECTION:**
- Update version number with each significant change
- Update date whenever document is modified
- Status options: `Planning` | `In Progress` | `Testing` | `Complete` | `On Hold`

---

## 2. DIMENSIONS & BOUNDARIES (IMMUTABLE ONCE SET)

> ⚠️ **WARNING**: These dimensions define all component positions. Changing them
> invalidates the entire component layout. Lock these FIRST before detailed design.

```
Overall Frame (Outer Envelope):
┌─────────────────────────────────────┐
│  Width:  350 mm  (X-axis)           │
│  Height: 275 mm  (Y-axis)           │
│  Depth:  100 mm  (Z-axis)           │
└─────────────────────────────────────┘

Internal Working Volume:
- Width:  344 mm  (350 - 2×3mm walls)
- Height: 269 mm  (275 - 2×3mm walls)
- Depth:   94 mm  (100 - 2×3mm walls)

Zone Boundaries (Y-axis, from bottom):
┌─────────────────────────────────────┐
│ Zone A (Sky):        Y = 120 to 272 mm  │  ← Swirls, stars, moon
│ Zone B (Landscape):  Y =  40 to 120 mm  │  ← Village, hills, cypress
│ Zone C (Base/Water): Y =   0 to  40 mm  │  ← Waves, hidden mechanisms
└─────────────────────────────────────┘

Horizontal Zones (X-axis, from left):
┌─────────────────────────────────────┐
│ Left Zone:    X =   0 to 100 mm     │  ← Cypress tree, cliff
│ Center Zone:  X = 100 to 250 mm     │  ← Village, main sky
│ Right Zone:   X = 250 to 350 mm     │  ← Lighthouse, moon
└─────────────────────────────────────┘
```

**LOCK STATUS:**
| Dimension | Value | Locked | Lock Date | Rationale |
|-----------|-------|--------|-----------|-----------|
| Frame Width | 350mm | ✓ YES | 2026-01-10 | Fits standard shelf, good canvas ratio |
| Frame Height | 275mm | ✓ YES | 2026-01-10 | Matches painting aspect ratio |
| Frame Depth | 100mm | ✓ YES | 2026-01-10 | Adequate for mechanism layers |
| Sky Zone | 120-272mm | ✓ YES | 2026-01-12 | Proportional to original painting |
| Landscape Zone | 40-120mm | ✓ YES | 2026-01-12 | Provides mechanism hiding space |
| Base Zone | 0-40mm | ✓ YES | 2026-01-12 | Wave amplitude + structure |

**HOW TO USE THIS SECTION:**
- Fill in all dimensions during initial planning
- Mark as LOCKED once design work begins on that area
- NEVER change locked dimensions without creating a new major version
- If change is required, document in Version History with full rationale

---

## 3. COMPONENT INVENTORY

> **SURVIVAL CHECK**: After every edit, verify ALL components still exist in code.
> Use this table as the authoritative checklist.

### 3.1 Structural Components

| Component | Status | Z-Layer | Dimensions (mm) | Connected To | Notes |
|-----------|--------|---------|-----------------|--------------|-------|
| Enclosure Back | ✓ Present | -20 | 350×275×3 | Frame | Solid back panel |
| Enclosure Left | ✓ Present | 0 | 100×275×3 | Frame | Side wall |
| Enclosure Right | ✓ Present | 0 | 100×275×3 | Frame | Side wall |
| Enclosure Top | ✓ Present | 0 | 350×3×100 | Frame | Optional, can be open |
| Enclosure Bottom | ✓ Present | 0 | 350×3×100 | Frame | Base platform |
| Front Frame | ✓ Present | +50 | 350×275×3 | Frame | Decorative border only |

### 3.2 Landscape Elements (Static)

| Component | Status | Z-Layer | Position (X,Y) | Dimensions | Notes |
|-----------|--------|---------|----------------|------------|-------|
| Cliff/Hill | ✓ Present | 0 | 0-80, 40-150 | Complex profile | Hides motor cavity |
| Cypress Tree | ✓ Present | +10 | 30-60, 40-200 | Flame-shaped | Iconic element |
| Village Houses | ✓ Present | +5 | 120-240, 50-100 | Multiple pieces | 5 house shapes |
| Church Steeple | ✓ Present | +5 | 180, 60-110 | Pointed spire | Tallest building |
| Rolling Hills | ✓ Present | 0 | 80-350, 40-80 | Curved profile | Background layer |

### 3.3 Motor & Drive System

| Component | Status | Z-Layer | Position | Specs | Notes |
|-----------|--------|---------|----------|-------|-------|
| Motor (N20) | ✓ Present | -10 | Inside cliff | 5V, 60RPM, 6mm shaft | Hidden from view |
| Motor Bracket | ✓ Present | -10 | Inside cliff | 3mm ply | Holds motor secure |
| Pinion Gear | ✓ Present | -5 | On motor shaft | 10T, M1.5, 15mm OD | Press-fit to shaft |
| Master Gear | ✓ Present | -5 | Center of cliff | 60T, M1.5, 90mm OD | 6:1 reduction |
| Idler Shaft | ✓ Present | -5 | Below master | 6mm diameter | Supports master gear |

### 3.4 Wave Mechanism

| Component | Status | Z-Layer | Position | Motion | Notes |
|-----------|--------|---------|----------|--------|-------|
| Wave Crank Disc | ✓ Present | -5 | On master gear | Rotates 360° | Has offset pin |
| Crank Pin | ✓ Present | -5 | R=15 from center | Circular path | Drives connecting rod |
| Connecting Rod | ✓ Present | -3 | Crank to rocker | Reciprocating | 40mm length |
| Rocker Arm | ✓ Present | -3 | Pivot at base | ±25° swing | Converts to linear |
| Wave Bar 1 | ✓ Present | +30 | Y=20-30 | Horizontal slide | Front wave |
| Wave Bar 2 | ✓ Present | +20 | Y=15-25 | Horizontal slide | Middle wave |
| Wave Bar 3 | ✓ Present | +10 | Y=10-20 | Horizontal slide | Back wave |
| Wave Profile 1 | ✓ Present | +30 | On bar 1 | With bar | Sine wave cutout |
| Wave Profile 2 | ✓ Present | +20 | On bar 2 | With bar | Phase offset 120° |
| Wave Profile 3 | ✓ Present | +10 | On bar 3 | With bar | Phase offset 240° |

### 3.5 Sky Mechanism (Swirls)

| Component | Status | Z-Layer | Position (X,Y) | Motion | Notes |
|-----------|--------|---------|----------------|--------|-------|
| Swirl Disc 1 (Large) | ✓ Present | +15 | 180, 200 | CW, 1:1 | Main swirl, 50mm dia |
| Swirl Disc 2 | ✓ Present | +15 | 120, 220 | CCW, 2:1 | 35mm dia |
| Swirl Disc 3 | ✓ Present | +15 | 240, 180 | CW, 1.5:1 | 40mm dia |
| Swirl Disc 4 | ✓ Present | +15 | 280, 220 | CCW, 2:1 | 30mm dia |
| Swirl Disc 5 | ✓ Present | +15 | 150, 170 | CW, 3:1 | 25mm dia, smallest |
| Swirl Drive Gear 1 | ✓ Present | -5 | Behind disc 1 | From master | 20T, M1 |
| Swirl Drive Shaft 1 | ✓ Present | -5 to +15 | Through back | Rotates | 4mm dia |
| Swirl Idler Gears | ✓ Present | -5 | Various | Transfer | Gear train |

### 3.6 Moon Mechanism

| Component | Status | Z-Layer | Position | Motion | Notes |
|-----------|--------|---------|----------|--------|-------|
| Moon Disc | ✓ Present | +25 | 300, 240 | Oscillate ±15° | Crescent shape |
| Moon Pivot | ✓ Present | +20 | 300, 240 | Fixed | Brass bushing |
| Moon Linkage | ✓ Present | -3 | Behind moon | Push-pull | Connected to master |
| Moon Crank | ✓ Present | -5 | On master gear | Rotates | R=8 offset |

### 3.7 Lighthouse Mechanism

| Component | Status | Z-Layer | Position | Motion | Notes |
|-----------|--------|---------|----------|--------|-------|
| Lighthouse Tower | ✓ Present | +10 | 320, 60-100 | Static | Structural |
| Lighthouse Lamp | ✓ Present | +15 | 320, 95 | Static | LED mount point |
| Beam Disc | ✓ Present | +20 | 320, 95 | Rotates 360° | Has beam slot |
| Beam Cam | ✓ Present | -5 | Below tower | From master | 1:4 ratio (slow) |
| Beam Shaft | ✓ Present | -5 to +20 | Through tower | Rotates | 3mm dia |

### 3.8 Decorative Elements

| Component | Status | Z-Layer | Position | Type | Notes |
|-----------|--------|---------|----------|------|-------|
| Stars (×12) | ✓ Present | +35 | Various sky | Static | Different sizes |
| Star Halos (×12) | ✓ Present | +32 | Around stars | Static | Etched rings |
| Border Frame | ✓ Present | +50 | Perimeter | Static | 15mm wide |
| Signature Plate | ✓ Present | +50 | Bottom right | Static | "Van Gogh" style |

**HOW TO USE THIS SECTION:**
- Mark status as: `✓ Present` | `⚠ Modified` | `✗ MISSING` | `○ Planned`
- After EVERY code edit, verify each component exists
- If status becomes `✗ MISSING`, STOP and recover before continuing
- Z-Layer determines render order and physical stacking

---

## 4. MECHANISM CHAIN (Power Flow)

> **TRACE THE POWER**: Every moving component must connect back to the motor.
> If a component has no path, it won't move.

```
                                 MOTOR (N20, 60 RPM)
                                        │
                                        ▼
                              ┌─────────────────┐
                              │  PINION GEAR    │
                              │  10T, M1.5      │
                              │  OD: 15mm       │
                              └────────┬────────┘
                                       │
                     Center Distance: 52.5mm = (10+60)/2 × 1.5
                                       │
                                       ▼
                              ┌─────────────────┐
                              │  MASTER GEAR    │
                              │  60T, M1.5      │
                              │  OD: 90mm       │
                              │  Reduction: 6:1 │
                              │  Output: 10 RPM │
                              └────────┬────────┘
                                       │
           ┌───────────────────────────┼───────────────────────────┐
           │                           │                           │
           ▼                           ▼                           ▼
   ┌───────────────┐          ┌───────────────┐          ┌───────────────┐
   │   BRANCH A    │          │   BRANCH B    │          │   BRANCH C    │
   │  Wave Motion  │          │  Sky Swirls   │          │ Moon + Light  │
   └───────┬───────┘          └───────┬───────┘          └───────┬───────┘
           │                           │                           │
           ▼                           ▼                           ▼
   ┌───────────────┐          ┌───────────────┐          ┌───────────────┐
   │  Crank Disc   │          │  Drive Gear   │          │  Cam Disc     │
   │  R=15mm pin   │          │  20T, M1.0    │          │  Eccentric    │
   └───────┬───────┘          └───────┬───────┘          └───────┬───────┘
           │                           │                           │
           ▼                           │                    ┌──────┴──────┐
   ┌───────────────┐                   │                    ▼             ▼
   │ Connecting    │          ┌────────┴────────┐   ┌───────────┐ ┌───────────┐
   │ Rod (40mm)    │          │                 │   │Moon Crank │ │Beam Shaft │
   └───────┬───────┘          ▼                 ▼   │ Linkage   │ │  1:4      │
           │           ┌───────────┐     ┌───────────┐ └─────┬─────┘ └─────┬─────┘
           ▼           │ Idler 1   │     │ Idler 2   │       │             │
   ┌───────────────┐   │ 15T→30T   │     │ 20T→20T   │       ▼             ▼
   │  Rocker Arm   │   └─────┬─────┘     └─────┬─────┘ ┌───────────┐ ┌───────────┐
   │  Pivot base   │         │                 │       │   MOON    │ │LIGHTHOUSE │
   └───────┬───────┘         ▼                 ▼       │ Oscillate │ │   BEAM    │
           │           ┌───────────┐     ┌───────────┐ │   ±15°    │ │  Rotate   │
           ▼           │ Swirl 1   │     │ Swirl 2   │ └───────────┘ │  2.5 RPM  │
   ┌───────────────┐   │ 50mm, CW  │     │ 35mm, CCW │               └───────────┘
   │  Push Rods    │   │ 10 RPM    │     │ 5 RPM     │
   │  to waves     │   └───────────┘     └───────────┘
   └───────┬───────┘         │                 │
           │                 ▼                 ▼
     ┌─────┴─────┐    ┌───────────┐     ┌───────────┐
     │           │    │ Swirl 3,4 │     │  Swirl 5  │
     ▼           ▼    │ via chain │     │  Fastest  │
┌─────────┐ ┌─────────┐└───────────┘     └───────────┘
│ Wave 1  │ │ Wave 2  │
│ Phase 0°│ │Phase120°│
└─────────┘ └─────────┘
     │
     ▼
┌─────────┐
│ Wave 3  │
│Phase240°│
└─────────┘
```

### Gear Specifications Summary

| Gear | Teeth | Module | OD (mm) | Mesh Partner | Center Dist |
|------|-------|--------|---------|--------------|-------------|
| Pinion | 10 | 1.5 | 15 | Master | 52.5mm |
| Master | 60 | 1.5 | 90 | Pinion | 52.5mm |
| Swirl Drive | 20 | 1.0 | 20 | Swirl Idler 1 | 22.5mm |
| Swirl Idler 1 | 25 | 1.0 | 25 | Swirl Drive | 22.5mm |
| Lighthouse | 40 | 1.0 | 40 | Beacon Driver | 30mm |
| Beacon Driver | 20 | 1.0 | 20 | Lighthouse | 30mm |

### Motion Summary

| Output | Type | Speed | Amplitude | Phase |
|--------|------|-------|-----------|-------|
| Wave 1 | Linear oscillation | 10 cycles/min | ±12mm | 0° |
| Wave 2 | Linear oscillation | 10 cycles/min | ±12mm | 120° |
| Wave 3 | Linear oscillation | 10 cycles/min | ±12mm | 240° |
| Swirl 1 | Continuous rotation | 10 RPM | 360° | - |
| Swirl 2 | Continuous rotation | 5 RPM | 360° | - |
| Swirl 3 | Continuous rotation | 6.67 RPM | 360° | - |
| Swirl 4 | Continuous rotation | 5 RPM | 360° | - |
| Swirl 5 | Continuous rotation | 3.33 RPM | 360° | - |
| Moon | Oscillation | 10 cycles/min | ±15° | - |
| Lighthouse | Continuous rotation | 2.5 RPM | 360° | - |

**HOW TO USE THIS SECTION:**
- Trace from MOTOR to every moving component
- If you can't trace a path, the component won't move
- Update gear ratios when mechanism changes
- Verify center distances match gear calculations: `CD = (T1 + T2) × Module / 2`

---

## 5. Z-LAYER STACK (Front to Back)

> **PHYSICAL REALITY**: Components must not intersect. This stack defines
> the actual depth position of each layer.

```
FRONT (Viewer Side)
        │
        ▼
════════════════════════════════════════════════════════════════
Z = +50mm   │ FRONT FRAME
            │ - Decorative border
            │ - Signature plate
────────────┼────────────────────────────────────────────────────
Z = +40mm   │ (Reserved for future front elements)
            │
────────────┼────────────────────────────────────────────────────
Z = +35mm   │ STARS LAYER
            │ - All 12 star cutouts
            │ - Maximum visual depth from frame
────────────┼────────────────────────────────────────────────────
Z = +32mm   │ STAR HALOS
            │ - Etched rings behind stars
────────────┼────────────────────────────────────────────────────
Z = +30mm   │ WAVE LAYER 1 (Front wave)
            │ - Wave bar 1
            │ - Wave profile 1
────────────┼────────────────────────────────────────────────────
Z = +25mm   │ MOON LAYER
            │ - Moon disc (crescent)
            │ - Moon halo ring
────────────┼────────────────────────────────────────────────────
Z = +20mm   │ WAVE LAYER 2 / LIGHTHOUSE BEAM
            │ - Wave bar 2
            │ - Wave profile 2
            │ - Beam disc with slot
────────────┼────────────────────────────────────────────────────
Z = +15mm   │ SWIRL DISCS LAYER
            │ - All 5 swirl discs
            │ - Swirl decorative spirals
            │ - Lighthouse lamp housing
────────────┼────────────────────────────────────────────────────
Z = +10mm   │ WAVE LAYER 3 / LANDSCAPE FRONT
            │ - Wave bar 3
            │ - Wave profile 3
            │ - Cypress tree (front layer)
            │ - Lighthouse tower
────────────┼────────────────────────────────────────────────────
Z = +5mm    │ VILLAGE LAYER
            │ - All house silhouettes
            │ - Church steeple
────────────┼────────────────────────────────────────────────────
Z = 0mm     │ MAIN MECHANISM PLANE ◄── REFERENCE DATUM
            │ - Cliff/hill profile
            │ - Rolling hills
            │ - Main structural elements
            │ - Side walls attached here
────────────┼────────────────────────────────────────────────────
Z = -3mm    │ LINKAGE LAYER
            │ - Connecting rods
            │ - Rocker arms
            │ - Moon linkage
            │ - Push rods
────────────┼────────────────────────────────────────────────────
Z = -5mm    │ GEAR LAYER
            │ - Master gear
            │ - Pinion gear
            │ - All drive gears
            │ - Crank discs
            │ - Cam discs
────────────┼────────────────────────────────────────────────────
Z = -10mm   │ MOTOR LAYER
            │ - Motor body
            │ - Motor bracket
            │ - Idler shafts
────────────┼────────────────────────────────────────────────────
Z = -15mm   │ (Reserved for motor wiring)
            │
────────────┼────────────────────────────────────────────────────
Z = -20mm   │ BACK WALL
            │ - Enclosure back panel
            │ - Mounting points
════════════════════════════════════════════════════════════════
        │
        ▼
BACK (Wall Side)
```

### Layer Thickness Budget

| Layer Range | Available | Used By | Remaining |
|-------------|-----------|---------|-----------|
| +50 to +35 | 15mm | Frame, Stars | 0mm |
| +35 to +20 | 15mm | Waves 1-2, Moon | 0mm |
| +20 to +5 | 15mm | Swirls, Wave 3, Village | 0mm |
| +5 to -5 | 10mm | Mechanisms, Gears | 2mm |
| -5 to -20 | 15mm | Motor, Back | 5mm |
| **TOTAL** | **70mm** | | **7mm reserve** |

**HOW TO USE THIS SECTION:**
- Before adding component, check Z-layer availability
- Update "Used By" when adding new components
- Maintain 3mm minimum clearance between moving parts
- Z=0 is the REFERENCE - all measurements relative to this

---

## 6. LOCKED DECISIONS (IMMUTABLE)

> **LOCKED = FINAL**: These decisions have been made and validated. Changing
> them would cascade through the entire design. Do NOT modify without
> creating a new major version.

| ID | Decision | Value/Choice | Date Locked | Rationale | Impact if Changed |
|----|----------|--------------|-------------|-----------|-------------------|
| L001 | Frame outer dimensions | 350×275×100mm | 2026-01-10 | Fits target display, good proportions | All component positions invalid |
| L002 | Material thickness | 3mm plywood | 2026-01-10 | Available, laser-cuttable, strong enough | All joint designs invalid |
| L003 | Motor type | N20, 5V, 60RPM | 2026-01-11 | Quiet, available, right speed | Gear ratios, mounting invalid |
| L004 | Motor position | Inside cliff cavity | 2026-01-11 | Hidden from viewer, accessible | Power routing, cliff shape invalid |
| L005 | Primary gear module | 1.5mm | 2026-01-12 | Good strength for 3mm ply | All gear meshes invalid |
| L006 | Master gear ratio | 6:1 (10T:60T) | 2026-01-12 | 10 RPM output, good torque | All motion speeds change |
| L007 | Wave count | 3 layers | 2026-01-13 | Visual depth, manageable complexity | Animation timing invalid |
| L008 | Wave phase offset | 120° between layers | 2026-01-13 | Smooth rolling effect | Animation appearance changes |
| L009 | Swirl count | 5 discs | 2026-01-14 | Matches painting, good coverage | Layout, gear train invalid |
| L010 | Front opening | No front glass/panel | 2026-01-14 | Easy access, no reflections | Dust protection changes |
| L011 | Sky zone boundary | Y = 120mm | 2026-01-12 | Proportional to painting | Component positions invalid |
| L012 | Power input | USB 5V | 2026-01-11 | Universal, safe, convenient | Wiring, motor selection invalid |

**HOW TO USE THIS SECTION:**
- Add new locked decisions as they are finalized
- NEVER delete entries - only add
- If a decision must change, create new version and document cascade effects
- Reference ID (L###) in other documents when depending on this decision

---

## 7. ACTIVE DECISIONS (PENDING)

> **OPEN QUESTIONS**: These need resolution before the affected components
> can be finalized. Track options, recommendations, and status here.

| ID | Question | Options | Pros/Cons | Recommendation | Status | Assigned |
|----|----------|---------|-----------|----------------|--------|----------|
| A001 | Wave profile shape | **A)** Smooth sine curve **B)** Hokusai-style peaks **C)** Abstract geometric | A) Organic feel, easy to cut B) Dramatic, matches art style C) Modern interpretation | B) Hokusai-style | Awaiting user input | User |
| A002 | Star illumination | **A)** No LEDs (static) **B)** Steady LEDs **C)** Twinkling LEDs | A) Simple, no wiring B) Subtle glow C) More alive, complex circuit | A) No LEDs (Phase 1) | Awaiting user input | User |
| A003 | Cypress tree motion | **A)** Static **B)** Gentle sway **C)** Flame-like flicker | A) Simplest B) Natural wind effect C) Matches Van Gogh's style | C) Flame flicker (Phase 2) | Deferred to Phase 2 | - |
| A004 | Surface finish | **A)** Natural wood **B)** Stained dark **C)** Painted colors **D)** Mixed | A) Shows grain B) Dramatic silhouette C) True to painting D) Balanced | D) Mixed approach | Awaiting user input | User |
| A005 | Moon glow method | **A)** Backlight LED **B)** Reflective material **C)** Edge-lit acrylic | A) Bright, needs wiring B) Passive, angle dependent C) Even glow, adds material | C) Edge-lit if LEDs used | Depends on A002 | - |
| A006 | Base feet style | **A)** Flush (no feet) **B)** Small rubber bumpers **C)** Decorative wooden feet | A) Clean, may scratch B) Practical, invisible C) Crafted look | B) Rubber bumpers | Awaiting user input | User |

**Decision Status Legend:**
- `Awaiting user input` - Need user to choose
- `Under investigation` - Researching feasibility
- `Deferred to Phase N` - Will decide later
- `DECIDED → L###` - Resolved, moved to Locked Decisions

**HOW TO USE THIS SECTION:**
- Add new questions as they arise during design
- Document all considered options with pros/cons
- When decided, move to Locked Decisions with new L### ID
- Remove from this table after locking

---

## 8. VERSION HISTORY

> **CHANGELOG**: Every version must document what changed and confirm
> component survival. This is your rollback reference.

| Version | Date | Summary | Detailed Changes | Survival Check | Files Modified |
|---------|------|---------|------------------|----------------|----------------|
| V29 | 2026-01-16 | Added lighthouse beam mechanism | + Added lighthouse tower (Z+10) | ✓ All 47 components present | starry_night_v29.scad |
| | | | + Added beam disc (Z+20) | | starry_night_v29_animate.scad |
| | | | + Added beam drive shaft | | |
| | | | + Added lighthouse gear (40T) | | |
| | | | + Connected to master gear via 1:4 ratio | | |
| | | | + Beam rotates at 2.5 RPM | | |
| V28 | 2026-01-15 | Fixed gear mesh distances | - Corrected pinion-master center distance | ✓ All 43 components present | starry_night_v28.scad |
| | | | - Was 50mm, now 52.5mm (calculated) | | |
| | | | - Gears now mesh without binding | | |
| | | | - Added GEAR_MODULE constant | | |
| V27 | 2026-01-14 | Added all 5 swirl discs | + Swirl discs 1-5 with sizes | ✓ All 43 components present | starry_night_v27.scad |
| | | | + Individual rotation speeds | | |
| | | | + Gear train for distribution | | |
| | | | + Decorative spiral patterns on discs | | |
| V26 | 2026-01-13 | Moon oscillation mechanism | + Moon crescent shape | ✓ All 38 components present | starry_night_v26.scad |
| | | | + Moon pivot point | | |
| | | | + Cam-driven linkage from master | | |
| | | | + ±15° oscillation range | | |
| V25 | 2026-01-12 | Three-layer wave system | + Wave bars 1, 2, 3 | ✓ All 34 components present | starry_night_v25.scad |
| | | | + Wave profiles with sine curves | | |
| | | | + Four-bar linkage from master gear | | |
| | | | + Phase offset implementation | | |
| V24 | 2026-01-11 | Motor and master gear | + N20 motor with bracket | ✓ All 26 components present | starry_night_v24.scad |
| | | | + Pinion gear 10T | | |
| | | | + Master gear 60T | | |
| | | | + Motor cavity in cliff | | |
| V23 | 2026-01-10 | Initial frame and enclosure | + Frame dimensions set | ✓ All 18 components present | starry_night_v23.scad |
| | | | + Three walls (back, left, right) | | |
| | | | + Base and top panels | | |
| | | | + Zone boundaries defined | | |

### Recovery Points

| Version | Recovery Note | How to Restore |
|---------|---------------|----------------|
| V28 | Last known good gear mesh | `git checkout v28 -- starry_night.scad` |
| V25 | Waves working, before moon | `git checkout v25 -- starry_night.scad` |
| V23 | Basic frame only | `git checkout v23 -- starry_night.scad` |

**HOW TO USE THIS SECTION:**
- Create new entry for EVERY saved version
- Run survival check: count components, verify all listed in Section 3
- If survival check fails, DO NOT SAVE - recover missing components first
- Note which files were modified
- Keep recovery points for major milestones

---

## 9. KNOWN ISSUES / TODO

> **ISSUE TRACKER**: Problems discovered, features planned, improvements needed.
> Check off when resolved and note the version that fixed it.

### Critical Issues (Blocking)

- [ ] **ISSUE-001**: Lighthouse beam may collide with star at position (290, 210)
  - *Discovered*: V29, 2026-01-16
  - *Impact*: Beam rotation blocked
  - *Proposed fix*: Move star to (290, 230) or reduce beam length
  - *Assigned*: Next session

- [ ] **ISSUE-002**: Wave bar 2 guide slots not yet designed
  - *Discovered*: V25, 2026-01-12
  - *Impact*: Wave will not slide properly when built
  - *Proposed fix*: Add guide slots to side walls at Y=15-25
  - *Assigned*: Before laser cutting

### Major Issues (Important)

- [ ] **ISSUE-003**: Swirl disc 4 may be too close to frame edge
  - *Discovered*: V27, 2026-01-14
  - *Impact*: May hit frame at X=340 (frame at X=347)
  - *Proposed fix*: Verify clearance, move to X=275 if needed
  - *Assigned*: Review in OpenSCAD

- [x] **ISSUE-004**: ~~Gear mesh too tight~~ FIXED in V28
  - *Discovered*: V24, 2026-01-11
  - *Fixed*: V28, 2026-01-15
  - *Solution*: Corrected center distance calculation

### Minor Issues (Nice to have)

- [ ] **ISSUE-005**: Add engraved version number to back panel
  - *Discovered*: V23, 2026-01-10
  - *Impact*: Tracking which version was cut
  - *Proposed fix*: Add text "V##" to back panel corner
  - *Priority*: Low

- [ ] **ISSUE-006**: Consider adding assembly marks to parts
  - *Discovered*: V25, 2026-01-12
  - *Impact*: Easier assembly
  - *Proposed fix*: Small matching numbers/letters on mating parts
  - *Priority*: Low

### Planned Enhancements (Future)

- [ ] **ENHANCE-001**: Phase 2 - Add cypress tree sway motion
  - *Reference*: Decision A003
  - *Complexity*: Medium
  - *Target*: V35+

- [ ] **ENHANCE-002**: Phase 2 - Add LED backlighting option
  - *Reference*: Decisions A002, A005
  - *Complexity*: Medium
  - *Target*: V35+

- [ ] **ENHANCE-003**: Export DXF for laser cutting
  - *Status*: Need projection module
  - *Complexity*: Low
  - *Target*: Before fabrication

**HOW TO USE THIS SECTION:**
- Add issues immediately when discovered
- Include version discovered and impact assessment
- Mark completed with [x] and note fixing version
- Move resolved issues to "Fixed" subsection periodically
- Reference issue IDs in commit messages

---

## 10. FILES INVENTORY

> **PROJECT FILES**: All files related to this project, their purpose,
> and current status.

### OpenSCAD Design Files

| Filename | Purpose | Lines | Last Modified | Status |
|----------|---------|-------|---------------|--------|
| `starry_night_v29.scad` | Main assembly - current version | 6,959 | 2026-01-16 | Active |
| `starry_night_v29_animate.scad` | Animation test wrapper | 160 | 2026-01-16 | Active |
| `starry_night_v28.scad` | Previous version (backup) | 6,421 | 2026-01-15 | Archived |
| `starry_night_v27.scad` | Swirls version (backup) | 5,892 | 2026-01-14 | Archived |

### Component Library Files

| Filename | Purpose | Lines | Last Modified | Status |
|----------|---------|-------|---------------|--------|
| `lib/gears.scad` | Involute gear generator | 450 | 2026-01-11 | Stable |
| `lib/waves.scad` | Wave profile generators | 180 | 2026-01-12 | Stable |
| `lib/swirls.scad` | Swirl disc patterns | 220 | 2026-01-14 | Stable |
| `lib/linkages.scad` | Four-bar, slider-crank | 340 | 2026-01-13 | Stable |

### Export Files

| Filename | Purpose | Generated From | Date | Status |
|----------|---------|----------------|------|--------|
| `exports/frame_back.dxf` | Laser cut - back panel | v29 | Pending | Not yet generated |
| `exports/gears_sheet.dxf` | Laser cut - all gears | v29 | Pending | Not yet generated |
| `exports/waves_sheet.dxf` | Laser cut - wave pieces | v29 | Pending | Not yet generated |

### Documentation Files

| Filename | Purpose | Last Modified | Status |
|----------|---------|---------------|--------|
| `master_specification_template.md` | This file - master spec | 2026-01-16 | Active |
| `assembly_guide.md` | Build instructions | Pending | Not yet created |
| `parts_list.md` | BOM with sources | Pending | Not yet created |

### Reference Files

| Filename | Purpose | Source | Notes |
|----------|---------|--------|-------|
| `reference/starry_night.jpg` | Original painting reference | Public domain | Color reference |
| `reference/n20_motor_specs.pdf` | Motor datasheet | Manufacturer | Dimensions, specs |
| `reference/plywood_3mm_specs.pdf` | Material properties | Supplier | Kerf, tolerances |

**HOW TO USE THIS SECTION:**
- Update line counts after major edits
- Mark archived files clearly
- Track export file generation status
- Keep reference files documented

---

## 11. TEST INSTRUCTIONS

> **VERIFICATION PROCEDURES**: How to test the design at each stage.

### 11.1 OpenSCAD Preview Test (After Every Edit)

```
1. Open starry_night_v29.scad in OpenSCAD
2. Press F5 (Preview)
3. Verify:
   [ ] No red error messages in console
   [ ] All components visible (use Ctrl+# to isolate if needed)
   [ ] No obvious intersections in default view
4. Rotate view to check:
   [ ] Front view - all silhouettes correct
   [ ] Side view - Z-layers properly stacked
   [ ] Top view - no component overlaps in X-Y plane
5. Check console for warnings about:
   [ ] DEPRECATED functions
   [ ] Undefined variables
   [ ] Zero-thickness geometry
```

### 11.2 Animation Test (After Mechanism Changes)

```
1. Open starry_night_v29_animate.scad in OpenSCAD
2. Go to View → Animate
3. Set parameters:
   - FPS: 30
   - Steps: 360
4. Click play (▶) button
5. Verify each motion:
   [ ] Waves move smoothly side-to-side
   [ ] Wave phases are offset (rolling effect)
   [ ] All swirl discs rotate (correct directions)
   [ ] Moon oscillates back and forth
   [ ] Lighthouse beam rotates steadily
6. Watch for problems:
   [ ] Jerky motion (calculation issue)
   [ ] Components disappearing (conditional bug)
   [ ] Collisions (parts intersecting)
   [ ] Frozen components (not connected to drive)
7. Optional: Export animation
   - View → Export → Export Image Sequence
   - Use external tool to create GIF
```

### 11.3 Component Isolation Test

```
1. In main file, find SHOW_xxx parameters at top
2. Set all to 0 except one category:
   - SHOW_FRAME = 1, others = 0 → Check frame only
   - SHOW_WAVES = 1, others = 0 → Check waves only
   - SHOW_GEARS = 1, others = 0 → Check gears only
3. For each category, verify:
   [ ] All expected components render
   [ ] Dimensions match specification
   [ ] Positions match layout diagram
4. Reset all SHOW_xxx = 1 when done
```

### 11.4 Transparency Debug Mode

```
1. Set TRANSPARENT_CLIFF = 1 at top of file
2. Preview (F5)
3. Verify motor cavity contains:
   [ ] Motor body (correct orientation)
   [ ] Motor bracket (securing motor)
   [ ] Pinion gear (on motor shaft)
   [ ] Master gear (meshing with pinion)
   [ ] Correct center distance (52.5mm)
4. Set TRANSPARENT_CLIFF = 0 when done
```

### 11.5 Collision Detection Test

```
1. Set DEBUG_COLLISION = 1 (if implemented)
2. Render (F6) - full geometry calculation
3. Check for:
   [ ] No "Object may not be a valid 2-manifold" warnings
   [ ] Render completes without errors
4. Manual collision check for moving parts:
   - Set $t = 0.0 and preview
   - Set $t = 0.25 and preview
   - Set $t = 0.5 and preview
   - Set $t = 0.75 and preview
   - No intersections at any phase
```

### 11.6 Measurement Verification

```
1. Use OpenSCAD ruler tool or measure module
2. Verify critical dimensions:
   [ ] Frame outer: 350 × 275 × 100 mm
   [ ] Gear center distance: 52.5mm
   [ ] Wave amplitude: 12mm each side
   [ ] Moon swing: 15° each direction
3. Verify clearances:
   [ ] Gear teeth: minimum 0.5mm backlash
   [ ] Moving parts: minimum 3mm to static parts
   [ ] Z-layers: minimum 3mm between layers
```

### 11.7 Pre-Export Checklist

```
Before generating DXF files:
[ ] All tests above pass
[ ] Version number updated in file header
[ ] Component count matches inventory (Section 3)
[ ] No issues marked as "blocking" (Section 9)
[ ] All locked decisions still valid (Section 6)
[ ] Survival check passed (Section 8)
```

**HOW TO USE THIS SECTION:**
- Run appropriate tests after each work session
- Check off items as you verify
- If any check fails, fix before continuing
- Update test procedures as new features are added

---

## 12. ASCII LAYOUT REFERENCE

> **VISUAL OVERVIEW**: Quick reference for component positions and relationships.

### 12.1 Front View (X-Y Plane, looking at -Z)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         STARRY NIGHT - FRONT VIEW                           │
│                              350mm × 275mm                                  │
├───────────────────────────────────────────────────────┬─────────────────────┤
│  0         50        100       150       200       250│300       350        │
│  ├─────────┼─────────┼─────────┼─────────┼─────────┼──┼───────────┤         │
│                                                       │                     │ 275
│            ★                    ☆         ★          │     ★               │
│      ★           ★        ★         ★                │          ★          │
│              @@@@@                  @@@@              │                     │
│  270       @@@@@@@@      ★       @@@@@@@             │    ☾☾☾              │
│           @@@@@@@@@              @@@@@@@@@            │   ☾☾☾☾☾             │ 250
│    ★     @@Swirl 1@@   ★       @@Swirl 2@@    ★     │    ☾☾☾              │
│          @@@@@@@@@              @@@@@@@@@             │    MOON             │
│           @@@@@@@@      @@@@@    @@@@@@@              │                     │
│            @@@@@       @@@@@@@    @@@@           ★   │          ★          │ 220
│     ★               @@Swirl 3@@              @@@@@   │                     │
│                      @@@@@@@                @@@@@@   │                     │
│  200                  @@@@@                @Swirl 4@ │        ▓▓▓          │
│      @@@@@                                  @@@@@@   │       ▓▓▓▓▓         │
│     @@@@@@@       ★                          @@@@    │      ▓LIGHT▓        │
│    @@Swirl 5@                                   ★    │       ▓▓▓▓▓         │ 175
│     @@@@@@@                                          │        ▓▓▓          │
│      @@@@@                                           │         █           │
│  150                                                 │         █           │
│       ╱╲                                             │         █           │
│      ╱  ╲                                            │      ███████        │ 130
│  120╱    ╲                                           │      LIGHTHOUSE     │
│    ╱      ╲                                          │                     │
│ ──╱────────╲─────────────────────────────────────────┼─────────────────────│ SKY/LAND
│  ╱ CYPRESS  ╲      ___      ▲        ___    ___      │                     │
│ ╱    TREE    ╲   _/   \_   /█\     _/   \_/   \_     │                     │ 100
│╱              ╲_/VILLAGE\_/███\___/  HOUSES    \_    │                     │
│                  █ █ █   CHURCH  █ █   █ █   █       │                     │
│  80                                                  │                     │
│   ████████                                           │                     │
│  ██CLIFF███████████████████████████████████████████████████████████████████│
│  ██ (MOTOR ██   ~~~~~~~~~~~~ROLLING HILLS~~~~~~~~~~~~                      │ 60
│  ██ HIDDEN)██                                                              │
│  ████████████                                        │                     │
│  40                                                  │                     │ 40
│ ════════════════════════════════════════════════════════════════════════════│ LAND/WAVE
│  ≈≈≈≈≈≈≈≈≈≈≈≈≈ WAVE 1 ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈│≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈│
│   ∿∿∿∿∿∿∿∿∿∿∿∿ WAVE 2 ∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿│∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿│ 20
│    ~~~~~~~~~~~  WAVE 3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~│~~~~~~~~~~~~~~~~~~~~│
│                                                      │                    │
│  0                                                   │                    │ 0
└──────────────────────────────────────────────────────┴────────────────────┘
```

### 12.2 Side View (Y-Z Plane, looking at +X)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         STARRY NIGHT - SIDE VIEW                            │
│                              100mm × 275mm                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  FRONT                                                              BACK    │
│  Z=+50        Z=+30      Z=+10      Z=0       Z=-10      Z=-20             │
│    │            │          │         │          │          │               │
│    ▼            ▼          ▼         ▼          ▼          ▼               │
│                                                                     275    │
│  ┌─┐                                                            ┌───────┐  │
│  │F│          ★                                                 │       │  │
│  │R│        Stars                                               │       │  │
│  │A│          │                                                 │       │  │
│  │M│     ┌────┴────┐                                            │       │  │
│  │E│     │ Wave 1  │                                            │  BACK │  │
│  │ │     └─────────┘                                            │       │  │
│  │ │           ┌────────┐                                       │  WALL │  │
│  │ │     ☾     │ Wave 2 │                                       │       │  │
│  │ │    Moon   └────────┘                                       │       │  │
│  │ │     │          │                                           │       │  │
│  │ │     │    ┌─────┴─────┐     ┌──────┐                        │       │  │
│  │ │     │    │   Swirls  │     │Gears │  ┌────┐                │       │  │
│  │ │     │    │  (×5)     │     │      │  │Moto│                │       │  │
│  │ │     │    └───────────┘     │      │  │ r  │                │       │  │
│  │ │     │         │            │      │  └────┘                │       │  │
│  │ │     │    ┌────┴────┐       │      │     │                  │       │  │
│  │ │     │    │ Wave 3  │       └──┬───┘     │                  │       │  │
│  │ │     │    └─────────┘          │         │                  │       │  │
│  │ │     │         │               │         │                  │       │  │ 120
│  │ │─────┼─────────┼───────────────┼─────────┼──────────────────│       │──│ SKY
│  │ │     │         │               │         │                  │       │  │ LAND
│  │ │     │    ┌────┴────┐     ┌────┴────┐    │                  │       │  │
│  │ │     │    │ Village │     │  Cliff  │    │                  │       │  │
│  │ │     │    │ Cypress │     │(contains│    │                  │       │  │ 40
│  │ │─────┼────┴─────────┴─────┤  motor) ├────┼──────────────────│       │──│ LAND
│  │ │     │         │          │ cavity  │    │                  │       │  │ WAVE
│  │ │     │   ═══ Waves ═══    └─────────┘    │                  │       │  │
│  │ │     │    (sliding)                      │                  │       │  │
│  └─┘     └───────────────────────────────────┴──────────────────└───────┘  │ 0
│                                                                             │
│    +50      +30      +20      +10       0       -5      -10      -20       │
└─────────────────────────────────────────────────────────────────────────────┘
                                Z-AXIS (mm)
```

### 12.3 Top View (X-Z Plane, looking at -Y)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          STARRY NIGHT - TOP VIEW                            │
│                              350mm × 100mm                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│        0        50       100       150       200       250       300    350│
│        │         │         │         │         │         │         │       │
│   Z    ▼         ▼         ▼         ▼         ▼         ▼         ▼       │
│        ┌─────────────────────────────────────────────────────────────────┐ │
│  +50   │░░░░░░░░░░░░░░░░░░░░░░ FRONT FRAME ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│  +35   │ ★        ★              ★         ★              ★         ★   │ │
│        │                    STARS LAYER                                  │ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│  +30   │ ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈ WAVE 1 ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈│ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│  +25   │                                                        ☾ MOON  │ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│  +20   │ ∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿ WAVE 2 ∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿  ▓BEAM▓   │ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│  +15   │      @@@@      @@@@       @@@@      @@@@      @@@@      ▓▓▓▓   │ │
│        │     SWIRL1    SWIRL2     SWIRL3    SWIRL4    SWIRL5     LAMP   │ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│  +10   │ ~~~~~~~~~~~~~~~~~~~~~~ WAVE 3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~  █   │ │
│        │  CYPRESS                                               TOWER    │ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│   +5   │         VILLAGE  HOUSES  CHURCH                                │ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│    0   │█ CLIFF ████████████████████████████████████████████████████████│ │
│        │ (MAIN MECHANISM PLANE)                                          │ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│   -3   │  ┌──linkages──┐   ┌──linkages──┐   ┌──linkages──┐              │ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│   -5   │    ⚙PINION⚙MASTER⚙    ⚙⚙⚙ GEAR TRAIN ⚙⚙⚙                      │ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│  -10   │  ╔══════╗                                                       │ │
│        │  ║MOTOR ║  (inside cliff cavity)                                │ │
│        │  ╚══════╝                                                       │ │
│        ├─────────────────────────────────────────────────────────────────┤ │
│  -20   │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ BACK WALL ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ │
│        └─────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│   FRONT ◄────────────────────────────────────────────────────────► BACK    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 12.4 Mechanism Schematic (Simplified)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       MECHANISM SCHEMATIC (ACTIVE CONNECTIONS)              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                              ┌─────────────────┐                            │
│                              │                 │                            │
│        ┌────────────────────►│   SWIRL DISCS   │                            │
│        │   Gear Train        │   (5 rotating)  │                            │
│        │                     │                 │                            │
│        │                     └─────────────────┘                            │
│        │                                                                    │
│        │                     ┌─────────────────┐                            │
│        │                     │                 │                            │
│   ┌────┴────┐               │    MOON DISC    │◄───────┐                   │
│   │         │    ┌──────────►│  (oscillating)  │        │                   │
│   │ MASTER  │    │           │                 │        │                   │
│   │  GEAR   │────┤           └─────────────────┘        │                   │
│   │  60T    │    │                                      │                   │
│   │         │    │           ┌─────────────────┐        │  Cam/Crank        │
│   └────┬────┘    │           │                 │        │  Linkage          │
│        │         └──────────►│   WAVE BARS     │────────┴───────┐           │
│   Mesh │   Four-Bar          │ (3 reciprocating)                │           │
│        │   Linkage           │                 │                │           │
│   ┌────┴────┐                └─────────────────┘                │           │
│   │         │                                                   │           │
│   │ PINION  │                ┌─────────────────┐                │           │
│   │  10T    │                │                 │                │           │
│   │         │                │  LIGHTHOUSE     │◄───────────────┘           │
│   └────┬────┘                │   BEAM DISC     │  Gear 1:4                  │
│        │                     │  (rotating)     │                            │
│   ┌────┴────┐                │                 │                            │
│   │  MOTOR  │                └─────────────────┘                            │
│   │  N20    │                                                               │
│   │  60RPM  │  INPUT POWER                                                  │
│   │   5V    │◄──────────────────────────────────── USB                      │
│   └─────────┘                                                               │
│                                                                             │
│   LEGEND:  ──────►  = Power flow direction                                  │
│            ════════ = Gear mesh                                             │
│            ────────  = Linkage/mechanical connection                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**HOW TO USE THIS SECTION:**
- Reference these diagrams when adding/moving components
- Verify new components don't conflict with existing layout
- Update diagrams when major layout changes occur
- Use ASCII art to communicate layout in text-only environments

---

## APPENDIX A: QUICK REFERENCE CARD

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        STARRY NIGHT QUICK REFERENCE                          ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  FRAME:        350 × 275 × 100 mm                                            ║
║  MATERIAL:     3mm plywood                                                    ║
║  MOTOR:        N20, 5V, 60RPM                                                ║
║  GEAR RATIO:   6:1 (10T pinion → 60T master)                                 ║
║  OUTPUT SPEED: 10 RPM                                                         ║
║                                                                               ║
║  ┌─────────────────────────────────────────────────────────────────────────┐ ║
║  │ ZONE        │ Y-RANGE      │ CONTENTS                                  │ ║
║  ├─────────────┼──────────────┼───────────────────────────────────────────┤ ║
║  │ Sky         │ 120-272mm    │ Swirls, Stars, Moon                       │ ║
║  │ Landscape   │  40-120mm    │ Village, Hills, Cypress, Lighthouse       │ ║
║  │ Base/Waves  │   0-40mm     │ Wave mechanism, hidden gears              │ ║
║  └─────────────────────────────────────────────────────────────────────────┘ ║
║                                                                               ║
║  KEY DISTANCES:                                                               ║
║  • Pinion-Master center: 52.5mm                                              ║
║  • Wave amplitude: ±12mm                                                      ║
║  • Moon oscillation: ±15°                                                     ║
║                                                                               ║
║  CURRENT VERSION: V29        COMPONENTS: 47        STATUS: In Progress       ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

---

## APPENDIX B: TEMPLATE USAGE INSTRUCTIONS

### How to Start a New Project from This Template

1. **Copy this file** to your project directory
2. **Rename** to match your project: `[project_name]_master_spec.md`
3. **Fill in Section 1** with project overview
4. **Define dimensions in Section 2** - these should be locked early
5. **Add components to Section 3** as you design them
6. **Map power flow in Section 4** for all mechanisms
7. **Update version history** after every work session

### After Every Work Session

1. Update "Last Updated" date in Section 1
2. Verify all components exist (Section 3 survival check)
3. Add version entry to Section 8
4. Check off any resolved issues in Section 9
5. Update file inventory in Section 10

### Before Major Changes

1. Create backup of current version
2. Add new row to Version History
3. Document the planned change
4. After change, run survival check
5. If survival check fails, restore backup

### Before Fabrication

1. All Section 9 "Critical Issues" must be resolved
2. All Section 7 "Active Decisions" relevant to fab must be locked
3. Run all tests in Section 11
4. Generate export files and update Section 10
5. Final survival check

---

*Template Version: 1.0*
*Created: 2026-01-16*
*For: Starry Night Kinetic Art Project*
