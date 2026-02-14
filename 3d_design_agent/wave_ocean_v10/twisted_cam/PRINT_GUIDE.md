# Wave Ocean V10 - Twisted Cam System
## Print & Assembly Guide

### Mechanism Overview
A single helical ridge spirals around a cylindrical cam. As the cam rotates, the ridge pushes slats upward in sequence, creating a traveling wave effect. Slats rest on the cam surface with gravity—no complex linkages required.

---

## Parts List

| Part | Quantity | Print Time | Material |
|------|----------|------------|----------|
| Twisted Cam | 1 | ~4 hours | PLA/PETG |
| Slat | 24 | ~30 min each | PLA |
| Guide Rail | 2 | ~1 hour each | PLA |
| Bearing Block | 2 | ~1.5 hours each | PETG |
| Base Plate | 1 | ~2 hours | PLA |

**Total print time:** ~20 hours

---

## Hardware Required

| Item | Qty | Size | Notes |
|------|-----|------|-------|
| 608 Bearing | 2 | 8×22×7mm | Standard skateboard bearing |
| Steel Rod | 1 | 8mm × 260mm | Main shaft |
| M3 Set Screw | 4 | M3×6 | Lock cam to shaft |
| M4 Screw | 8 | M4×12 | Bearing block mounting |
| M3 Screw | 4 | M3×8 | Guide rail mounting |
| M4 Nut | 8 | M4 | Base plate |

---

## Print Settings

### Twisted Cam
- **Orientation:** Horizontal (X axis along bed)
- **Supports:** None needed if ridge smooth enough
- **Layer height:** 0.2mm
- **Infill:** 20% for weight (helps momentum)
- **Walls:** 3

### Slats (24x)
- **Orientation:** Upright (wave crest up)
- **Supports:** None
- **Layer height:** 0.15mm (smoother bottom)
- **Infill:** 15%
- **Tip:** Sand bottom curve smooth!

### Guide Rails (2x)
- **Orientation:** Flat on side
- **Supports:** None
- **Layer height:** 0.2mm
- **Infill:** 30% (thin part needs strength)

### Bearing Blocks (2x)
- **Orientation:** Upright
- **Supports:** Maybe for bearing pocket
- **Layer height:** 0.2mm
- **Infill:** 40% (structural)
- **Material:** PETG recommended

### Base Plate
- **Orientation:** Flat
- **Supports:** None
- **Layer height:** 0.2mm
- **Infill:** 20%

---

## Assembly Sequence

1. **Press bearings** into bearing blocks
   - Bearing pocket is press-fit (slightly tight)
   - Use a flat surface to press evenly

2. **Mount bearing blocks** to base plate
   - Use M4×12 screws from bottom
   - Blocks face inward

3. **Insert shaft** through bearings
   - Should spin freely
   - Center it

4. **Slide twisted cam** onto shaft
   - Secure with M3 set screws
   - Two screws per end, 90° apart

5. **Attach guide rails** to bearing block supports
   - Front rail closer to viewer
   - Back rail behind slats
   - Use M3×8 screws

6. **Insert slats** through guide rail slots
   - Curved bottom faces down (toward cam)
   - Slats should slide freely

7. **Test rotation**
   - Turn shaft by hand
   - All slats should rise and fall smoothly
   - Adjust any binding slats

---

## Tuning Tips

### Slats Stick or Skip
- Sand slat bottoms smoother
- Apply dry lubricant (PTFE spray)
- Check guide rail slot alignment

### Uneven Wave
- Verify cam is centered on shaft
- Check all slats reach cam surface
- Trim any slat bottom irregularities

### Too Much Friction
- Lighter slats (less infill)
- Smoother cam surface (higher $fn when printing)
- Bearings seated properly

### Noise
- Add felt pads to slat bottoms
- Use silicone grease on cam surface
- Slow down rotation speed

---

## Motor Options

For powered operation, add N20 geared motor:
- **Speed:** 30-60 RPM ideal
- **Voltage:** 6-12V
- **Coupling:** 3mm motor shaft to 8mm main shaft
- **Mount:** Create bracket at one end

---

## Dimensions Summary

- **Total length:** 260mm (base plate)
- **Total width:** 70mm
- **Total height:** ~120mm
- **Wave amplitude:** 10mm
- **Wave travel:** Continuous (2 waves visible)
