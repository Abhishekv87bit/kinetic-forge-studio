# Ravigneaux Grid Kinetic Sculpture — Design Document

**Date:** 2026-02-23
**Status:** APPROVED
**Rule 500 Target:** `D:\Claude local\3d_design_agent\waffle_grid_planetary\`

---

## Overview

A kinetic sculpture using Ravigneaux planetary gearsets as compact differential units. Each unit takes 3 shared shaft inputs, blends them via internal gear ratios, and outputs ring rotation that winds/unwinds a rope to raise/lower a hanging hex block. 25 units (5x5 hex grid) with varying internal gear ratios + varying external drive pinions create a non-repeating wave interference pattern from 3 stepper motors.

## Architecture

```
3x Stepper Motors (NEMA 14 or 28BYJ-48)
    |
    +-- Shaft A --> pinion --> Ss tube --> Small Sun --+
    +-- Shaft B --> pinion --> SL tube --> Large Sun --+-- Ravigneaux --> Ring (OUTPUT)
    +-- Shaft C --> pinion --> Carrier  --> Carrier  --+         |
                                                          Spool channel
                                                              |
                                                         Rope/Thread
                                                              |
                                                       Guide Plate hole
                                                         (diagonal)
                                                              |
                                                        Hex Block (pixel)
                                                         up/down + XY wobble
```

## Unit Specifications

### Gear Parameters
- Normal module: 0.7mm
- Helix angle: 25 deg
- Transverse module: 0.773mm
- Pressure angle: 20 deg

### Tooth Counts (fixed across all variants)
- Ring: 80T (internal, pitch R = 30.9mm)
- Large Sun (SL): 40T (pitch R = 15.5mm)
- Outer Planet (Po): 20T (pitch R = 7.7mm), 3x at 120 deg

### Tooth Counts (variant-specific)
- Small Sun (Ss): varies per variant
- Inner Planet (Pi): varies per variant (Ss + 2*Pi = 40)

### Ravigneaux Constraints
- SL + 2*Po = Ring: 40 + 40 = 80 CHECK
- Ss + 2*Pi = SL: variant-specific, all = 40 CHECK

### Envelope
- Ring OD: 70mm (including 3mm spool drum wall)
- Unit height: ~26mm (including flanges)
- Two-zone axiom: SL gear zone (6mm) + thrust plate (1.5mm) + Ss gear zone (6mm) = 13.5mm total
- Spool channel: 8mm wide open U-groove between 2mm flanges

### Concentric Shafts
| Layer | Diameter | Function |
|-------|----------|----------|
| Anchor (M6 rod) | 6mm | Fixed to frame |
| Ss tube | ID 7mm / OD 9mm | Drives small sun |
| SL tube | ID 10mm / OD 12mm | Drives large sun |
| Carrier bore | 13mm | Carrier free to rotate |

### Ring-as-Housing / Spool Drum
- Ring internal teeth on inner surface
- Ring body wall: 3mm (structural + spool drum)
- Spool channel: open U-groove, rope wraps in channel
- Two flanges (top/bottom, 2mm each) retain rope
- V-groove replaced by full spool channel

### Axial Stack (inside ring)
| Zone | Height | Z range |
|------|--------|---------|
| Bottom lid | 2mm | |
| Carrier_2 plate | 2mm | |
| Axial gap + PTFE washer | 0.7mm | |
| SL gear zone | 6mm | Z=0 to 6 |
| Thrust plate (PTFE) | 1.5mm | Z=6 to 7.5 |
| Ss gear zone | 6mm | Z=7.5 to 13.5 |
| Axial gap + PTFE washer | 0.7mm | |
| Carrier_1 plate | 2mm | |
| Top lid | 2mm | |
| **Total internal** | **22.9mm** | |

**Two-Zone Axiom:** SL and Ss tooth zones are vertically separated by a thrust plate,
matching the Ford 4R70W reference pattern. Po (outer planet, long pinion) spans both
zones (13.5mm). Pi (inner planet, short pinion) occupies only the Ss zone (6mm).

## Variant Family

### Internal Variants (5 types, assigned to columns)
| Variant | Ss | Pi | kA | kB | kC | Character |
|---------|----|----|------|------|------|-----------|
| A | 16 | 12 | 0.110 | 0.200 | 0.690 | B-dominant |
| B | 20 | 10 | 0.138 | 0.172 | 0.690 | Balanced-B |
| C | 24 | 8 | 0.166 | 0.145 | 0.690 | Center |
| D | 26 | 7 | 0.179 | 0.131 | 0.690 | Balanced-A |
| E | 28 | 6 | 0.193 | 0.117 | 0.690 | A-dominant |

### External Pinion Variants (5 sets, assigned to rows)
| Set | SL pinion | Speed mult | Frequency |
|-----|-----------|-----------|-----------|
| 1 | 13T | x0.406 | Slow |
| 2 | 15T | x0.469 | |
| 3 | 18T | x0.563 | Medium |
| 4 | 21T | x0.656 | |
| 5 | 23T | x0.719 | Fast |

Pinion counts 13, 21 are Fibonacci numbers. 15, 18, 23 are Fibonacci-adjacent.

### Combined: 25 unique units from 5 internal x 5 external variants

## Grid Layout

- 5x5 hex-offset brick pattern (odd rows shifted half-pitch)
- Unit pitch: 80mm (70mm OD + 10mm clearance)
- Grid span: ~320mm x ~350mm
- 3 row shafts per row x 5 rows = 15 shafts total
- Motors: 3x NEMA 14 (or 28BYJ-48 for prototype)
- Controller: ESP32 + 3x TMC2209

## Guide Plate

- 5mm acrylic or aluminum plate
- Suspended ~35mm below unit plane
- Countersunk holes with top/bottom fillets
- Packs blocks from 80mm unit pitch to ~30mm hex block pitch
- Diagonal threads create XY traveling wave via lateral wobble

## Frame

- Minimalist: 3-4mm steel rod or M4 threaded rod
- Perimeter rectangle holds shaft bearings
- 4 legs (~400mm for desktop pedestal)
- Guide plate on thin brackets
- Frame disappears visually — wave and units are the art

## Blocks (Pixels)

- Hex prism, 25mm across-flats x 60-75mm tall
- PLA prototype, birch plywood production
- Thread attaches at top center
- ~6g each, total hanging mass ~150g

## Print Specifications (Prototype)

- Material: PLA
- Layer height: 0.2mm
- Nozzle: 0.4mm
- Ring: print standing up (axis vertical)
- Planets: print flat
- Carrier plates: print flat
- Shaft tubes: print standing up
- $fn: 48 for assembly preview, 64 for final render

## Visual Reference

- ref_assembly.scad: Ford 4R70W STL import (correct component look)
- ravigneaux_v13.scad: fully parametric rebuild (correct code structure)
- HEXAGON ZAR8 reference image: clean trefoil carrier, helical ring teeth
- Color scheme preserved from v13/ref_assembly

## Production Goal

- 3D printing = PROTOTYPING ONLY
- Production: metal (CNC, waterjet) + wood (laser cut blocks)
- Pipeline: OpenSCAD (iterate) -> FreeCAD MCP (STEP) -> Fusion 360 (production)
- Ring: brass or steel. Carrier: aluminum. Shaft: steel. Planets: steel.
- Bearings: standard catalog (H7/h6 fits)

## Wave Physics

Each unit output: ring_speed = kA * wA + kB * wB + kC * wC

With 5 internal variants (different kA/kB) and 5 external pinion sets (different effective input speeds), 25 units produce 25 unique output frequencies. Fibonacci-adjacent pinion counts ensure frequency ratios are approximately irrational -> pattern never repeats.

The guide plate diagonal threads add XY lateral displacement proportional to height change, creating visible traveling waves in both axes simultaneously.
