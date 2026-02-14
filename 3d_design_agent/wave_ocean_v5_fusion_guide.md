# Wave Ocean v5 - Fusion 360 Modeling Guide

## Quick Start

### Step 1: Import Parameters
1. Open Fusion 360, create new design
2. Go to **Modify → Change Parameters**
3. Click the **+** button and add parameters from `wave_ocean_v5_fusion_params.csv`
4. Or manually enter key parameters:
   - `MODULE = 3 mm`
   - `PRESSURE_ANGLE = 20 deg`
   - `GEAR_TEETH = 20`

### Step 2: Install Spur Gear Add-In (Recommended)
1. **Tools → Add-Ins → Scripts and Add-Ins**
2. Go to Add-Ins tab → click "+" to get more
3. Search "Spur Gear" by Autodesk
4. Install and run with these settings:
   - Standard: Metric
   - Module: 3
   - Pressure Angle: 20
   - Teeth: 20
   - Backlash: 0.1
   - Face Width: 15
   - Bore: 15

---

## Component-by-Component Instructions

### A. INVOLUTE GEAR (if modeling manually)

#### Sketch 1: Reference Circles
```
1. New Sketch on XY plane
2. Draw circles from origin:
   - Root circle: Ø52.5mm (construction)
   - Base circle: Ø56.38mm (construction)
   - Pitch circle: Ø60mm (construction)
   - Tip circle: Ø66mm (construction)
```

#### Sketch 2: Single Tooth Profile
```
1. New Sketch on XY plane
2. For involute curve, use 3-point spline approximation:

   Right flank control points (X, Y):
   - Start at base circle: (28.19, 0)
   - Mid point: (29.5, 2.8)
   - End at tip: (32.8, 5.2)

3. Mirror across Y-axis for left flank
4. Connect tips with small arc (0.45mm radius)
5. Connect roots with arc tangent to flanks
6. Add root fillet: 0.75mm radius
```

#### Extrude & Pattern
```
1. Extrude tooth profile: 15mm, symmetric
2. Circular Pattern: 20 instances, full 360°
3. Add hub: Ø28mm × 19mm, centered
4. Cut bore: Ø15mm through all
5. Cut keyway: 4mm × 4mm × through
```

---

### B. INVOLUTE RACK

#### Sketch: Single Tooth
```
1. New Sketch on XZ plane
2. Draw trapezoid:
   - Bottom width: 3.5mm (at root)
   - Top width: 5.8mm (at tip)
   - Height: 6.75mm
   - Flank angle: 20° from vertical
3. Add fillets: 0.75mm at root corners
4. Add chamfer: 0.3mm at tip corners
```

#### Create Wavy Base
```
1. Sketch sine wave path on XZ plane:
   - Use Equation: Z = 15 * sin(X * 360 / 100)
   - Or approximate with spline through points:
     X=0: Z=0
     X=25: Z=15
     X=50: Z=0
     X=75: Z=-15
     X=100: Z=0

2. Sketch rack cross-section (20mm × 12mm rectangle)
3. Sweep along sine path
4. Pattern teeth along top surface
```

---

### C. ROD-END BEARING (Heim Joint)

#### Housing (Outer Race)
```
1. Sketch on XZ plane:
   - Cylinder: Ø16mm × 10mm
   - Shank extension: Ø10mm × 8mm

2. Revolve or Extrude
3. Cut spherical socket: Ø12.4mm sphere from center
4. Cut shank bore: Ø8.3mm through
```

#### Ball (Inner Race)
```
1. Sketch hemisphere on XZ plane
2. Revolve 360°: Ø12mm sphere
3. Cut through-bore: Ø8mm
```

#### Assembly
```
1. Create new component for each part
2. Use Joint to place ball inside housing
3. Ball should rotate freely in socket
```

---

### D. CONNECTING ROD

#### Main Body
```
1. Sketch I-beam or rounded rectangle cross-section:
   - Width: 8mm
   - Height: 5mm
   - Corner radius: 1.5mm

2. Extrude: 39mm (rod length minus bearing bodies)
3. Fillet edges: 1mm
```

#### Add Bearings
```
1. Insert rod-end bearing component at each end
2. Joint: Rigid joint to rod body
3. Total length should be 55mm
```

---

### E. ROCKER BAR

#### Main Bar
```
1. Sketch on XY plane:
   - Rectangle: 100mm × 10mm
   - Boss circles at ±50mm: Ø14mm

2. Extrude: 6mm
3. Cut center pivot hole: Ø10.2mm
4. Cut lightening holes: 4× Ø8mm at X = ±15, ±30
5. Fillet all edges: 1mm
```

---

### F. PIVOT STANDOFF

#### Vertical Post
```
1. Sketch square tube: 12mm outer, 8mm inner
2. Extrude: 75mm height
3. Add base plate: 30mm × 20mm × 5mm
4. Add top plate: 25mm × 15mm × 5mm
```

#### Bushing
```
1. Sketch on XY plane:
   - Body: Ø16mm
   - Flange: Ø22mm

2. Extrude body: 12mm
3. Extrude flange: 3mm
4. Cut bore: Ø10mm through
```

---

## Assembly Instructions

### Create Top-Level Assembly
```
1. File → New Design (Assembly)
2. Insert components:
   - Rack (grounded)
   - Gear (joint to rack)
   - Rocker assembly (pivot joint)
   - Connecting rod (revolute joints at both ends)
```

### Joint Setup
```
1. RACK: Ground (fixed)
2. GEAR: Slider joint along rack + rolling constraint
3. PIVOT: Revolute joint to standoff
4. ROCKER: Revolute joint to pivot
5. ROD BOTTOM: Revolute to gear eccentric pin
6. ROD TOP: Revolute to rocker end
```

### Motion Study
```
1. Animate gear position: X = 60 * sin(t * 360)
2. Watch rocker tilt follow automatically
3. Verify rod length stays constant (measure in Inspect)
```

---

## Files Included

| File | Purpose |
|------|---------|
| `wave_ocean_v5_fusion_params.csv` | Import into Change Parameters |
| `wave_ocean_v5_fusion_guide.md` | This guide |
| `wave_ocean_v4.scad` | OpenSCAD reference (verified geometry) |

---

## Tips

1. **Use Parameters** - Link all dimensions to parameters for easy changes
2. **Component Organization** - One component per part, assemble at top level
3. **Joint Origins** - Place joint origins at actual pivot/bearing centers
4. **Capture Position** - Use "Capture Position" after setting up joints
5. **Motion Link** - Use motion link to connect gear translation to rotation

---

## Validation Checklist

- [ ] Gear pitch diameter: 60mm
- [ ] Gear meshes with rack (pitch circles tangent)
- [ ] Rod length constant at all positions: 55mm
- [ ] Rocker pivot at Z = 85mm
- [ ] Eccentric pin offset: 15mm from gear center
- [ ] All joints move freely without binding
