# GEOMETRY CHECKLIST - WAVE OCEAN v5 (2mm Walls + Printable Shafts)

**Updates from v4:**
- Cutout walls: 2mm thick minimum
- Camshaft: 3D printable with integrated cams
- Hinge axle: 3D printable

---

## Part 1: Wall Thickness Calculation

**Requirement:** 2mm walls around ALL cutouts

### Hinge Slot
```
Slot size: 12mm (Y) × 4mm (Z)
Wall thickness: 2mm

Extension below wave body needed:
  Slot Z extent: from -2mm to +2mm (centered at Z=0)
  Add 2mm wall below: Z = -2 - 2 = -4mm
  Add 2mm wall above: Z = +2 + 2 = +4mm

  Total extension height: 8mm (from Z=-4 to Z=+4)
  But wave body starts at Z=0, so extension = 4mm below baseline

Extension width (Y):
  Slot from Y=0 to Y=12mm
  Add 2mm wall at back: Start at Y=-2mm
  Add 2mm wall at front: End at Y=14mm

  Total extension: Y=-2 to Y=14 (16mm wide)
```

### Cam Housing
```
Housing size: 14mm × 14mm (square)
Wall thickness: 2mm

Extension needed:
  Housing Z: from -7mm to +7mm (centered at Z=0)
  Add 2mm wall below: Z = -7 - 2 = -9mm
  Add 2mm wall above: Z = +7 + 2 = +9mm

  But wave body only goes to Z=+10mm
  Housing top wall at Z=+9mm is INSIDE wave body ✓

  Housing bottom needs extension to Z=-9mm

Extension Y:
  Housing center at Y=53mm
  Housing from Y=46 to Y=60
  Add 2mm wall back: Y=44
  Add 2mm wall front: Y=62

  Total extension: Y=44 to Y=62 (18mm wide)
```

---

## Part 2: Revised Wave Geometry

```
SIDE VIEW (Y-Z plane):

                         WAVE BODY
    ┌──────────────────────────────────────────────┐
    │                                              │ Z=10 (top)
    │                                              │
    ├──┬────────────────────────────────────┬──────┤ Z=0 (baseline)
    │  │                                    │      │
    │  │ ┌────────────┐        ┌──────────┐ │      │
    │  │ │            │        │          │ │      │
    │  │ │   HINGE    │        │   CAM    │ │      │
    │  │ │   SLOT     │        │ HOUSING  │ │      │
    │  │ │   12×4     │        │  14×14   │ │      │
    │  │ │            │        │          │ │      │
    │  │ └────────────┘        └──────────┘ │      │
    │  │    2mm walls           2mm walls   │      │
    └──┴────────────────────────────────────┴──────┘ Z=-9 (bottom)

    Y=-2  Y=0        Y=14    Y=44      Y=62  Y=70

    ├─16mm─┤ Hinge    ├─18mm─┤ Cam
           extension          extension
```

**Final dimensions:**
```
Wave body: Y=0 to 70, Z=0 to 10, X=4mm thick

Hinge extension:
  Y: -2 to 14 (16mm)
  Z: 0 to -4 (4mm below baseline)
  Walls: 2mm all around slot

Cam housing extension:
  Y: 44 to 62 (18mm)
  Z: 0 to -9 (9mm below baseline)
  Walls: 2mm all around housing
```

---

## Part 3: Printable Camshaft Design

**All 22 cams integrated onto single shaft**

```
CAMSHAFT WITH CAMS (top view, looking down Z axis):

    ┌─○─┐ ┌─○─┐ ┌─○─┐ ┌─○─┐ ... ┌─○─┐
    │ 1 │ │ 2 │ │ 3 │ │ 4 │     │22 │
    └───┘ └───┘ └───┘ └───┘     └───┘
      │     │     │     │         │
    ══╪═════╪═════╪═════╪═════════╪══  ← Shaft (6mm dia)
      │     │     │     │         │

    Each cam: 4mm thick
    Spacing: 10mm pitch (4mm cam + 4mm wave + 2mm gap)
    Phase: Each cam rotated 16.36° from previous
```

**Shaft parameters:**
```
Shaft diameter: 6mm
Shaft length: 22 × 10mm + margins = 240mm

Cam attachment:
  - Cams are INTEGRAL with shaft (not separate)
  - Printed as one piece
  - Each cam at correct phase angle

Print orientation:
  - Shaft horizontal (along X)
  - May need supports under cams
  - Or print in sections and assemble
```

---

## Part 4: Printable Hinge Axle Design

**Simple round shaft, all waves slide onto it**

```
HINGE AXLE:

    ════════════════════════════════════════
    ↑                                      ↑
    3mm diameter                     240mm length

Features:
  - Smooth cylinder
  - Waves slide on with 0.5mm clearance
  - End caps or retaining clips to hold waves

Print orientation:
  - Horizontal
  - No supports needed
  - Simple cylinder
```

---

## Part 5: Revised Parameters

```openscad
// WAVE BODY
WAVE_LENGTH = 70;
WAVE_BODY_HEIGHT = 10;
WAVE_THICKNESS = 4;

// WALL THICKNESS (for both cutouts)
WALL_THICKNESS = 2;

// HINGE SLOT
HINGE_SLOT_LENGTH = 12;      // Y
HINGE_SLOT_HEIGHT = 4;       // Z
HINGE_SLOT_CENTER_Y = 6;     // Slot center from wave back
HINGE_SLOT_CENTER_Z = 0;

// Hinge extension (slot + walls)
HINGE_EXT_Y_START = -2;      // 2mm wall behind slot
HINGE_EXT_Y_END = 14;        // 2mm wall in front of slot
HINGE_EXT_Z_BOTTOM = -4;     // 2mm wall below slot

// CAM HOUSING
CAM_HOUSING_SIZE = 14;       // Square interior
CAM_HOUSING_CENTER_Y = 53;
CAM_HOUSING_CENTER_Z = 0;

// Cam housing extension (housing + walls)
CAM_EXT_Y_START = 44;        // 53 - 7 - 2 = 44
CAM_EXT_Y_END = 62;          // 53 + 7 + 2 = 62
CAM_EXT_Z_BOTTOM = -9;       // 0 - 7 - 2 = -9

// SHAFTS
HINGE_AXLE_DIA = 3;
CAMSHAFT_DIA = 6;
SHAFT_LENGTH = 240;

// CAMS
NUM_WAVES = 22;
UNIT_PITCH = 10;
CAM_THICKNESS = 4;
```

---

## Part 6: Connection Verification

```
Hinge slot interior: 12 × 4mm
Hinge axle: 3mm diameter
Clearance: (4 - 3) / 2 = 0.5mm each side ✓

Cam housing interior: 14 × 14mm
Max cam size: 12 × 7mm (diagonal ~13.9mm)
Clearance at diagonal: 14 - 13.9 = 0.1mm (TIGHT!)

ADJUSTMENT: Reduce max cam to 11.5 × 7mm
  Diagonal: √(11.5² + 7²)/√2 × √2 ≈ 13.5mm
  Clearance: 14 - 13.5 = 0.5mm ✓

Revised cam formula:
  cam_major(i) = 10 + (i / 21) * 1.5    // 10mm to 11.5mm
  cam_minor(i) = 9 - (i / 21) * 2       // 9mm to 7mm
```

---

## Part 7: Printability

```
Wall thickness: 2mm ✓ (≥1.2mm)
Shaft diameter: 3mm and 6mm ✓
Clearances: 0.5mm ✓ (≥0.3mm)

Camshaft with cams:
  - Long print (240mm)
  - May need to split into 2-3 sections
  - Sections join with 6mm socket/pin

Hinge axle:
  - Simple cylinder
  - Easy to print
```

---

## Part 8: Final Checklist

```
[x] Wall thickness 2mm around all cutouts
[x] Hinge extension calculated
[x] Cam housing extension calculated
[x] Printable camshaft designed
[x] Printable hinge axle designed
[x] Clearances verified
[x] Cam diagonal check passed

GEOMETRY CHECKLIST: 100% PASS
```
