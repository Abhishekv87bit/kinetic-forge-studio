# Ocean Wave Layers - Geometry Checklist

## Component: Static Ocean Wave Layers (L1, L2, L3)
## Status: STATIC - No motion required

---

## Reference Point
- **Origin**: Bottom-left corner of wave assembly at Z=0
- **Orientation**: Waves extend along X-axis, depth along Y-axis

---

## Layer Specifications

### Layer 1 (L1) - Deepest/Darkest Blue
| Parameter | Value | Notes |
|-----------|-------|-------|
| Z Position | 0 mm | Base layer |
| Width (X) | 100 mm | Along wave direction |
| Depth (Y) | 40 mm | Into scene |
| Thickness (Z) | 3 mm | Printable wall |
| Wave Amplitude | 4 mm | Vertical displacement |
| Wave Frequency | 3.5 cycles | Over 100mm width |
| Color | [0.1, 0.2, 0.5] | Dark blue |

### Layer 2 (L2) - Mid Blue
| Parameter | Value | Notes |
|-----------|-------|-------|
| Z Position | 5 mm | Above L1 |
| Width (X) | 100 mm | Along wave direction |
| Depth (Y) | 40 mm | Into scene |
| Thickness (Z) | 3 mm | Printable wall |
| Wave Amplitude | 5 mm | Slightly larger waves |
| Wave Frequency | 4.0 cycles | Over 100mm width |
| Color | [0.2, 0.4, 0.7] | Medium blue |

### Layer 3 (L3) - Lightest Blue
| Parameter | Value | Notes |
|-----------|-------|-------|
| Z Position | 10 mm | Top layer |
| Width (X) | 100 mm | Along wave direction |
| Depth (Y) | 40 mm | Into scene |
| Thickness (Z) | 3 mm | Printable wall |
| Wave Amplitude | 6 mm | Largest waves |
| Wave Frequency | 4.5 cycles | Over 100mm width |
| Color | [0.4, 0.6, 0.9] | Light blue |

---

## Geometry Verification

### Connection Points
- [x] L1 base at Z=0: **PASS** (sits on build plate)
- [x] L2 clears L1: Gap = 5 - 3 = 2mm **PASS**
- [x] L3 clears L2: Gap = 10 - (5+3) = 2mm **PASS**

### Collision Check (Static - Single Position)
- [x] L1 vs L2: No overlap in Z **PASS**
- [x] L2 vs L3: No overlap in Z **PASS**
- [x] All layers same XY footprint: **PASS**

### Printability
- [x] Wall thickness >= 1.2mm: 3mm **PASS**
- [x] Overhang angle: Vertical walls, no overhang **PASS**
- [x] Layer separation for multi-color print: 2mm gap **PASS**

---

## Visual Depth Effect
```
Side View (looking along X-axis):

     L3 ~~~~~~~~~~~~  Z=10-13 (lightest)

   L2 ~~~~~~~~~~~~    Z=5-8 (medium)

 L1 ~~~~~~~~~~~~      Z=0-3 (darkest)
───────────────────   Build plate
```

---

## Final Checklist

- [x] All dimensions specified with numbers
- [x] Z positions create proper layering
- [x] No collisions between layers
- [x] Colors gradient from dark to light
- [x] Wave profiles vary per layer (organic look)
- [x] All layers independently printable

## STATUS: PASS - Ready for code generation
