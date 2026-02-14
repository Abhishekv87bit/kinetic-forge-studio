# GEOMETRY CHECKLIST - WAVE DRIVE (30T) + HAND CRANK

**Component:** Wave Drive gear with hand crank for manual testing
**Purpose:** Test standalone gear rotation before integrating with master gear

---

## Part 1: Reference Point

**The SINGLE source of truth for all positions:**

```
Reference name: Gear shaft center
Reference position: X=0mm, Y=0mm, Z=0mm
What is it: Center of the 30T gear shaft axis
```

Note: For standalone testing, we use local origin. In final assembly, this maps to [110, 15, 5] in canvas coordinates.

---

## Part 2: Part List with Dimensions

### Part 1: Base Plate (test fixture)
```
Dimensions: 50mm x 50mm x 3mm (thick enough to support shaft)
Position relative to reference:
  X = 0 - 25mm = -25mm (centered)
  Y = 0 - 25mm = -25mm (centered)
  Z = 0 - 8mm = -8mm (below gear)
Connects to: Shaft bushing at (0mm, 0mm, -8mm)
```

### Part 2: Shaft Bushing (in base plate)
```
Dimensions: ID=5mm, OD=8mm, height=5mm
Position relative to reference:
  X = 0mm
  Y = 0mm
  Z = -8mm to -3mm (extends into base plate)
Connects to: Shaft at (0mm, 0mm, -3mm)
Clearance to shaft: 0.3mm (shaft is 4.7mm to fit 5mm hole)
```

### Part 3: Shaft
```
Dimensions: diameter=5mm (nominal), length=20mm
Position relative to reference:
  X = 0mm
  Y = 0mm
  Z = -8mm to +12mm (extends through gear and above)
Connects to: Gear at Z=0, Crank at Z=8mm
```

### Part 4: Wave Drive Gear (30T)
```
Dimensions:
  - Teeth: 30
  - Pitch radius: 15mm
  - Outer diameter: 30mm + 2*addendum = 30mm + 2*1.2mm = 32.4mm
  - Thickness: 6mm
  - Shaft hole: 5mm (with 0.3mm clearance = 5.3mm actual)
Position relative to reference:
  X = 0mm
  Y = 0mm
  Z = 0mm to +6mm
Connects to: Shaft through center bore
```

### Part 5: Crank Arm
```
Dimensions: 30mm length x 5mm width x 3mm thick
Position relative to reference:
  X = 0mm (attached to shaft)
  Y = 0mm
  Z = +8mm (above gear top surface by 2mm clearance)
Connects to: Shaft at (0mm, 0mm, 8mm), Knob at (30mm, 0mm, 8mm)
```

### Part 6: Crank Knob
```
Dimensions: diameter=10mm, height=12mm (comfortable grip)
Position relative to reference:
  X = +30mm
  Y = 0mm
  Z = +8mm to +20mm
Connects to: Crank arm end at (30mm, 0mm, 8mm)
```

---

## Part 3: Connection Verification

### Connection 1: Base Plate connects to Shaft Bushing
```
Part A endpoint (base plate hole center): (0mm, 0mm, -8mm)
Part B endpoint (bushing center): (0mm, 0mm, -8mm)
Gap = sqrt((0)² + (0)² + (0)²) = 0mm

[x] PASS (gap = 0)
```

### Connection 2: Shaft connects to Gear
```
Part A endpoint (shaft center at gear level): (0mm, 0mm, 0mm)
Part B endpoint (gear bore center): (0mm, 0mm, 0mm)
Gap = sqrt((0)² + (0)² + (0)²) = 0mm

[x] PASS (gap = 0)
```

### Connection 3: Shaft connects to Crank
```
Part A endpoint (shaft top): (0mm, 0mm, 8mm)
Part B endpoint (crank attachment): (0mm, 0mm, 8mm)
Gap = sqrt((0)² + (0)² + (0)²) = 0mm

[x] PASS (gap = 0)
```

### Connection 4: Crank connects to Knob
```
Part A endpoint (crank end): (30mm, 0mm, 8mm)
Part B endpoint (knob bottom center): (30mm, 0mm, 8mm)
Gap = sqrt((0)² + (0)² + (0)²) = 0mm

[x] PASS (gap = 0)
```

---

## Part 4: Collision Check

### Moving Part: Crank Arm + Knob

```
At θ=0° (crank pointing +X):
  Knob position: (30mm, 0mm, 8mm)
  Nearest obstacle: Base plate edge at (25mm, 0mm, -5mm)
  Clearance: sqrt((5)² + 0 + (13)²) = 13.9mm [x] PASS (>0.3mm)

At θ=90° (crank pointing +Y):
  Knob position: (0mm, 30mm, 8mm)
  Nearest obstacle: Base plate edge at (0mm, 25mm, -5mm)
  Clearance: sqrt(0 + (5)² + (13)²) = 13.9mm [x] PASS (>0.3mm)

At θ=180° (crank pointing -X):
  Knob position: (-30mm, 0mm, 8mm)
  Nearest obstacle: Base plate edge at (-25mm, 0mm, -5mm)
  Clearance: sqrt((5)² + 0 + (13)²) = 13.9mm [x] PASS (>0.3mm)

At θ=270° (crank pointing -Y):
  Knob position: (0mm, -30mm, 8mm)
  Nearest obstacle: Base plate edge at (0mm, -25mm, -5mm)
  Clearance: sqrt(0 + (5)² + (13)²) = 13.9mm [x] PASS (>0.3mm)
```

### Moving Part: Gear teeth (rotating with shaft)

```
At θ=0°:
  Gear outer edge: 16.2mm from center (with addendum)
  Nearest obstacle: Base plate at Z=-5mm
  Z clearance: 0mm - (-5mm) = 5mm [x] PASS (>0.3mm)

At θ=90°, 180°, 270°:
  Same as above - gear rotates about Z axis, base plate is below
  [x] PASS - no collision possible
```

---

## Part 5: Linkage Length Verification

**Not applicable** - this is a simple rotary component, no linkages.

---

## Part 6: Final Checklist

```
[x] All parts have explicit XYZ positions (no guessing)
[x] All connections verified (gap = 0)
[x] All collisions checked at 4 positions
[x] Linkage lengths verified constant (N/A)
[x] All numbers are ACTUAL values, not placeholders

Checklist completed by: Claude
Date: 2026-01-19
```

---

## SUMMARY - Dimensions for Code

| Part | Key Dimension | Value |
|------|--------------|-------|
| Base plate | Size | 50 x 50 x 3mm |
| Base plate | Z position | -8 to -5mm |
| Shaft | Diameter | 5mm |
| Shaft | Length | 20mm |
| Shaft | Z range | -8 to +12mm |
| Gear | Teeth | 30T |
| Gear | Pitch radius | 15mm |
| Gear | Thickness | 6mm |
| Gear | Z range | 0 to +6mm |
| Gear | Shaft hole | 5.3mm (with clearance) |
| Crank arm | Length | 30mm |
| Crank arm | Z position | 8mm |
| Knob | Diameter | 10mm |
| Knob | Height | 12mm |

**Clearances:**
- Shaft to bushing: 0.3mm (5mm hole, 4.7mm shaft)
- Shaft to gear: 0.3mm (5.3mm hole, 5mm shaft)
- Crank above gear: 2mm (gear top at Z=6, crank at Z=8)

---

## READY FOR CODE: YES
