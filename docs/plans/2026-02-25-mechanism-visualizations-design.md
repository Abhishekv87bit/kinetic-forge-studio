# Reuleaux Mechanism Visualizations — Design Document

**Date:** 2026-02-25
**Status:** APPROVED
**Output Directory:** `D:\Claude local\3d_design_agent\waffle_grid_planetary\`
**Style Reference:** `kelvin_linkage_3d.html` (same directory)

---

## Overview

6 standalone p5.js WEBGL HTML files, each visualizing one mechanism from the Reuleaux Decomposition Synthesis (REULEAUX_DECOMPOSITION_SYNTHESIS.md). Each file has two views: **Cell View** (single mechanism in detail) and **Grid View** (7x7 wave surface). Rich interactive controls with parameter sliders, keyboard shortcuts, and real-time physics readout.

## Files

| # | Filename | Mechanism | Source |
|---|----------|-----------|--------|
| 1 | `nested_eccentric_3d.html` | E3/E6 Triple-Nested Eccentric | Hybrid 3 |
| 2 | `ring_slider_3d.html` | S17 Ring-as-Slider Fusion | Set S |
| 3 | `gear_screw_3d.html` | M8 Gear-Screw Differential | Hybrid 8 |
| 4 | `tunable_worm_3d.html` | Continuously Tunable Worm-Organ | Hybrid 10 |
| 5 | `lissajous_surface_3d.html` | Dual Trammel Lissajous Surface | Hybrid 6 |
| 6 | `escapement_pulse_3d.html` | Escapement Pulse Wave | Hybrid 1 + Set X |

## Shared Architecture

All 6 files follow identical layout/structure:

```
LEFT PANEL          CANVAS (p5.js WEBGL)        RIGHT HUD
- Speed slider      - orbitControl()             - Motor angles
- Cell/Grid toggle  - Dark bg #080818            - Parameter values
- Layer toggles     - Ambient+directional light  - FPS, Revs
- Parameter sliders - Ground grid reference       - State indicators
- Keyboard legend   - Axis indicator (RGB=XYZ)

BOTTOM EXPLAINER BAR — mechanism name + one-line description + key shortcuts
```

### Common Controls (all files)
- Speed slider (1-100, default 25)
- SPACE: play/pause animation
- Layer toggle buttons (mechanism-specific)
- View presets: Front / Top / Side / Iso / Reset
- Cell/Grid toggle button
- HUD: motor angles, FPS, revs, current parameter values

### Visual Style (matching kelvin_linkage_3d.html)
- Background: `#080818`
- Panels: `rgba(15,15,35,0.94)`, border-radius 8px, monospace 12px
- Button active: `#4a4a8a` bg, `#88f` border
- Motor colors: A=pink `(255,102,136)`, B=blue `(102,187,255)`, C=green `(136,255,102)`
- Wave surface: triangle strip mesh with height-mapped color (blue-green-gold-red)
- Connections: semi-transparent colored lines

### Common Constants (from Ravigneaux spec)
- Grid: 7x7, spacing 35px (viz scale)
- Cam setup: 7 eccentric discs, 51.43deg twist/disc
- Motor frequencies: 1.0x, sqrt(2)x, phi-x
- 3 Willis variants distributed diagonally

### Cell/Grid Toggle
- Cell View: single mechanism centered at origin, large scale (4x), labeled parts, exploded/cutaway options
- Grid View: full 7x7 wave surface with cam shafts on 3 sides, pixel pillars, connections
- Smooth camera transition between views

---

## File 1: `nested_eccentric_3d.html`

### Mechanism: E3/E6 Triple-Nested Eccentric + Polygon Cam

**Concept:** An eccentric disc inside a constant-breadth cam polygon. The inner eccentric produces the fundamental sinusoid, the outer nesting adds a 2nd frequency, and the polygon cam shape injects a specific harmonic (3rd, 4th, 5th...). Two parameters per cell: eccentricity (amplitude) and polygon order (harmonic number).

### Cell View Components
| Part | Color | Shape | Animation |
|------|-------|-------|-----------|
| Inner eccentric (r1) | Gold `(220,180,40)` | Disc, radius ~10mm | Rotates at motor speed |
| Outer eccentric (r2) | Copper `(200,140,60)` | Bearing shell, radius ~18mm | Orbits around inner |
| Cam polygon | Steel-blue `(100,140,200)` | Constant-breadth n-gon | Orbits around outer |
| Output follower | White `(220,220,220)` | Box riding on cam surface | Translates vertically |
| Epicycloidal trace | Yellow `(255,255,100,80)` | Fading line trail | Shows orbit path |

### Unique Controls
- `Polygon Sides` slider: 3 to 8 (integer steps)
- `Inner Eccentricity` slider: 0 to 5mm
- `Outer Eccentricity` slider: 0 to 8mm
- `Nesting Depth` toggle: 1 / 2 / 3 levels
- `T` key: toggle epicycloidal trace
- `H` key: toggle harmonic overlay (frequency bar graph per cell)

### Grid Distribution
- Center cells: circle cam (pure fundamental, polygon=infinity shown as n=24)
- Ring 1: pentagon cam (5th harmonic)
- Ring 2: triangle cam (3rd harmonic)
- Corners: square cam (4th harmonic)

### Physics
```
output(t) = r1*sin(wt) + r2*sin(wt + phi1) + A_n*sin(n*wt + phi2)
where n = polygon side count
A_n ~ r2/n^2 for small eccentricities
```

---

## File 2: `ring_slider_3d.html`

### Mechanism: S17 Ring-as-Slider — Fused Planetary + Linear Output

**Concept:** The ring gear doesn't rotate in a housing — it translates vertically. Planets roll inside the ring, driven by the sun. As the sun rotates, planets push the ring up/down. This fuses the planetary summing stage and the linear output into ONE mechanism, eliminating: separate slider, rack-pinion, spool, guide rails.

### Cell View Components
| Part | Color | Shape | Animation |
|------|-------|-------|-----------|
| Sun gear | Gold `(220,190,60)` | Spur gear, 40T | Rotates (input) |
| Planet gears (3x) | Copper `(200,150,80)` | Spur gear, 20T each | Orbit + spin |
| Ring gear | Steel-blue `(100,150,220)` | Internal gear, 80T | Translates vertically |
| Carrier plate | Dark grey `(80,80,90)` | Disc with planet axle holes | Rotates with planets |
| Guide rails (2x) | Ghost white `(200,200,200,40)` | Vertical lines | Static, constrain ring |
| Ghost parts | Red translucent `(255,80,80,60)` | Rack, pinion, spool outlines | Toggle with G key |

### Unique Controls
- `Sun Teeth` slider: 20 to 40 (affects ratio)
- `Planet Count` toggle: 3 / 4 / 5
- `G` key: ghost overlay (translucent outlines of eliminated parts)
- `E` key: exploded view (parts separate along Y axis)
- `L` key: straight-line trace (red line showing ring path is linear)
- `Travel Range` slider: max ring displacement

### Physics
```
ring_displacement = (sun_teeth / ring_teeth) * sun_rotation * module * pi
For Sun=40, Ring=80: 0.5mm per degree of sun rotation
Ring travel for 1 full sun revolution: 0.5 * 360 = 180mm (capped by stroke)
Grashof: sun < ring always satisfied
```

---

## File 3: `gear_screw_3d.html`

### Mechanism: M8 Gear-Screw Differential — Self-Locking Freeze-Frame

**Concept:** 3 lead screws per cell, each with a different pitch, each driven by a gear pair from its input shaft. A common nut rides on all 3 screws simultaneously. The nut position = weighted sum of the 3 screw displacements. Self-locking: when motors stop, screws hold position instantly. No drift, no relaxation.

### Cell View Components
| Part | Color | Shape | Animation |
|------|-------|-------|-----------|
| Screw A (pitch 1mm) | Pink `(255,102,136)` | Threaded cylinder | Rotates at fA speed |
| Screw B (pitch 1.5mm) | Blue `(102,187,255)` | Threaded cylinder | Rotates at fB speed |
| Screw C (pitch 2mm) | Green `(136,255,102)` | Threaded cylinder | Rotates at fC speed |
| Gear pairs (3x) | Grey `(120,120,130)` | Spur gear pairs | Input shaft to screw |
| Common nut | Gold `(220,190,60)` | Box with 3 threaded bores | Translates vertically |
| Cutaway plane | Red `(255,50,50,30)` | Half-plane | Slices nut on F key |
| Escapement (optional) | White `(200,200,200)` | Anchor + escape wheel | Ticks on output |

### Unique Controls
- `SPACE` key: freeze/unfreeze (signature interaction — nut HOLDS position)
- `1` / `2` / `3` keys: solo mode (only that screw active, others greyed)
- `F` key: cutaway (nut sliced to show thread engagement)
- `Pitch A` slider: 0.5 to 3mm
- `Pitch B` slider: 0.5 to 3mm
- `Pitch C` slider: 0.5 to 3mm
- `Gear Ratio` slider: speed multiplication factor
- HUD: lock indicator "LOCKED" / "RUNNING"

### Physics
```
nut_position = sum_i( gear_ratio_i * pitch_i * motor_angle_i / (2*pi) )
Self-lock: lead_angle < friction_angle
  lead_angle = atan(pitch / (pi * diameter))
  friction_angle = atan(mu) ~ 8.5deg for steel
  At pitch=2mm, dia=8mm: lead_angle = atan(2/(pi*8)) = 4.5deg < 8.5deg -> LOCKS
```

---

## File 4: `tunable_worm_3d.html`

### Mechanism: Continuously Tunable Worm-Organ with Variable Cone Pulleys

**Concept:** 3 worm shafts run along 3 sides of the grid. Each worm driven by its motor through a cone pulley pair, allowing continuous speed ratio adjustment. Each cell has 3 worm wheels. The worm thread provides automatic phase shift between adjacent cells. Self-locking when input stops.

### Cell View Components
| Part | Color | Shape | Animation |
|------|-------|-------|-----------|
| Worm shaft | Motor-colored | Threaded cylinder (helical) | Rotates |
| Worm wheel | Gold `(220,190,60)` | Toothed disc (40T) | Meshes with worm |
| Cone pulley pair | Grey `(140,140,150)` | Two opposing cones + belt | Belt at variable position |
| Belt | Orange `(255,160,40)` | Thin strip wrapping cones | Moves with rotation |
| Phase markers | Cyan `(100,255,255,60)` | Dots on worm thread | Show phase gradient |
| Output shaft | White `(200,200,200)` | Vertical cylinder | Translates pixel |

### Unique Controls
- `Cone A Position` slider: 0 to 1 (ratio ~0.3x to ~3x)
- `Cone B Position` slider: 0 to 1
- `Cone C Position` slider: 0 to 1
- Current ratio readout: e.g. "A: 1.414x (near sqrt(2))"
- `R` key: snap to nearest rational ratio
- `I` key: snap to irrational (sqrt(2), phi, e/pi)
- `P` key: highlight phase gradient along worm
- Worm lead slider: 1 to 4mm
- Rational-lock indicator in HUD (flashes when near integer ratio)

### Physics
```
speed_ratio = cone_radius_at_belt_A / cone_radius_at_belt_B
worm_ratio = worm_wheel_teeth / worm_starts (typically 40:1)
phase_per_cell = (worm_lead / cell_pitch) * 360deg
Self-lock: worm lead_angle < friction_angle
```

---

## File 5: `lissajous_surface_3d.html`

### Mechanism: Dual Trammel Lissajous Surface — 2D Pixel Orbits

**Concept:** Each cell has two perpendicular trammel mechanisms (X and Y). Each trammel converts rotation to sinusoidal translation. The pixel connects to both trammels, tracing a Lissajous figure. With irrational frequency ratios, the figure never closes. 49 cells with different phases create a 2D trajectory field.

### Cell View Components
| Part | Color | Shape | Animation |
|------|-------|-------|-----------|
| Trammel A (X-dir) | Pink `(255,102,136)` | Crank + 2 perpendicular sliders | Rotates at fA |
| Trammel B (Y-dir) | Blue `(102,187,255)` | Crank + 2 perpendicular sliders | Rotates at fB |
| Slider tracks (4x) | Grey `(80,80,90)` | Rail grooves | Static guides |
| Pixel sphere | Gold `(220,190,60)` | Sphere at intersection | Traces Lissajous |
| Lissajous trail | Yellow `(255,255,100,80)` | Fading line history | Shows orbit shape |
| Arrow field (top view) | Cyan `(100,220,255,60)` | Arrows per cell | 2D displacement vectors |

### Unique Controls
- `Freq A` slider: 0.5 to 4.0
- `Freq B` slider: 0.5 to 4.0
- `Phase Offset` slider: 0 to 360deg
- `Amplitude A` slider: 1 to 15mm
- `Amplitude B` slider: 1 to 15mm
- `T` key: toggle Lissajous trail
- `A` key: toggle arrow field view (top-down 2D displacement)
- Ratio display: "fA:fB = 1.414 (open curve)" with closed/open indicator
- Preset buttons: "1:1 circle", "1:2 figure-8", "2:3 pretzel", "1:sqrt(2) fill"

### Physics
```
x(t) = Ax * sin(2*pi*fA*t + phi_row)
y(t) = Ay * sin(2*pi*fB*t + phi_col + delta)
Closed iff fA/fB is rational; period = LCM(1/fA, 1/fB)
Phase distribution: phi_row = row * 51.43deg (kelvin twist)
```

---

## File 6: `escapement_pulse_3d.html`

### Mechanism: Escapement Pulse Wave — Ticking Pixels with Asymmetric Dynamics

**Concept:** Each cell is a vertical tube with a heavy slug inside. The cam slowly pushes the slug UP (constant speed). An escapement releases the slug to FALL one tick at a time (gravity-powered, fast). The cycloid-curved tube option makes fall time independent of height (tautochrone property). Asymmetric wave: fast crests, slow troughs.

### Cell View Components
| Part | Color | Shape | Animation |
|------|-------|-------|-----------|
| Glass tube | Translucent `(200,220,255,60)` | Cylinder, open top | Static |
| Brass slug | Gold `(220,190,60)` | Chunky cylinder | Rises slowly, falls fast |
| Escapement anchor | White `(200,200,200)` | Rocking lever with teeth | Ticks back and forth |
| Escape wheel | Copper `(200,150,80)` | Toothed disc | Advances one tooth/tick |
| Cam pusher | Motor-colored | Eccentric disc + push rod | Drives slug upward |
| Tick marks | Grey `(100,100,120)` | Horizontal lines on tube | Show discrete positions |
| Cycloid curve | Cyan `(100,255,255,40)` | Tube profile overlay | When curvature > 0 |

### Unique Controls
- `Tick Rate` slider: 1 to 20 ticks/second
- `Gravity` toggle: on/off
- `Asymmetry Ratio` slider: 1:1 to 1:5 (rise:fall time)
- `Cycloid Curvature` slider: 0 (straight) to 1 (full brachistochrone)
- `Sound` toggle: audible tick via Web Audio API
- `S` key: step one tick manually (when paused)
- `Mass` slider: slug mass (visual weight indicator)
- HUD: tick counter, asymmetry ratio, fall velocity

### Physics
```
Rise: cam-driven, constant velocity
  t_rise = tick_height / cam_speed
Fall (straight tube): gravity-accelerated
  t_fall = sqrt(2*h / g)
Fall (cycloid tube): tautochrone property
  t_fall = pi * sqrt(r / g)  -- independent of starting height!
Asymmetry = t_rise / t_fall (displayed in HUD)
```

---

## Implementation Notes

### Execution Order (by dependency/complexity)
1. **M8 Gear-Screw** — simplest geometry (cylinders + boxes), clearest interactions (freeze/solo)
2. **S17 Ring-Slider** — moderate (gear teeth as simplified shapes, ghost overlay)
3. **Nested Eccentric** — moderate (nested rotation math, polygon drawing)
4. **Escapement Pulse** — moderate (asymmetric timing, optional sound)
5. **Tunable Worm** — complex (cone pulley geometry, rational detection)
6. **Lissajous Surface** — complex (dual trammel linkage, 2D displacement field)

### Parallelization Strategy
Files 1-3 can be built in parallel (no shared state). Files 4-6 can follow in a second parallel batch. Each agent gets the full design doc + kelvin reference.

### Performance Budget (per file)
- Target: 60fps on GTX 1650
- Cell view: unlimited detail (single mechanism)
- Grid view: $fn-equivalent ~12 for gear teeth, 8 segments for cylinders
- Total polygon budget: <500K for grid view
- No rotate_extrude equivalent (p5.js doesn't have it — use cylinder/box primitives)

### Gear Tooth Simplification
p5.js WEBGL has no involute profile support. Use simplified gear rendering:
- Small box teeth around a cylinder for spur gears
- Visible tooth count matches spec (40T sun, 80T ring, etc.)
- Internal teeth: inward-pointing boxes on ring inner surface
- Tooth height = 1.25 * module (standard addendum + dedendum)

### Thread Rendering (M8 screws, worm shafts)
- Helical thread: series of small boxes or triangles placed along a helix
- ~20 segments per revolution at grid scale, ~40 in cell view
- Thread pitch visible as spacing between helix turns
