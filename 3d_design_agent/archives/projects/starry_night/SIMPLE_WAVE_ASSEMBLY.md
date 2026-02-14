# Starry Night Wave Mechanism - Simple Version

## Overview

This is a **proven, printable** wave mechanism based on the [MicroWave design by Greg Zumwalt](https://www.instructables.com/MicroWave/). It uses a single camshaft with offset cams to create a traveling wave effect.

**Why this works:**
- ONE mechanism (camshaft) instead of three complex linkages
- 12 cams offset by 30° create traveling wave automatically
- No gears, no linkages, no push rods
- Direct cam-follower contact (simple, reliable)
- Hundreds of makers have successfully printed and assembled this type of mechanism

---

## Bill of Materials

### 3D Printed Parts

| Part | Qty | Print Settings | Notes |
|------|-----|----------------|-------|
| Side frame | 2 | 0.2mm layer, 20% infill | Print flat |
| Cam | 12 | **0.1mm layer, 100% infill** | Print standing, critical part |
| Wave segment | 12 | 0.15mm layer, 50% infill | Print flat |
| Motor mount | 1 | 0.2mm layer, 30% infill | Print flat |
| Shaft coupler | 1 | 0.2mm layer, 100% infill | Print standing |
| Hand crank | 1 | 0.2mm layer, 30% infill | Optional, for manual operation |

### Hardware (Non-Printed)

| Part | Qty | Specification | Where to Buy |
|------|-----|---------------|--------------|
| Steel rod | 1 | 6mm diameter, 200mm long | Hardware store |
| N20 gear motor | 1 | 60 RPM, 6V | Amazon/AliExpress |
| M3×12 bolts | 4 | For motor mount | Hardware store |
| M3 nuts | 4 | For motor mount | Hardware store |
| AAA batteries | 4 | For power | Any store |
| Battery holder | 1 | 4×AAA with switch | Amazon/AliExpress |
| Set screws | 2 | M2.5×5 for shaft coupler | Hardware store |

**Total hardware cost: ~$10-15**

---

## Print Settings

### General
- **Material:** PLA (PETG also works)
- **Nozzle:** 0.4mm
- **Supports:** None needed if oriented correctly

### Critical Parts (Cams)
```
Layer height: 0.1mm
Infill: 100%
Orientation: Standing upright (shaft hole vertical)
Perimeters: 4
```

The cams are the most critical part. Print them at 100% infill so they don't flex under load. The 12-sided polygon bore helps with alignment during assembly.

### Wave Segments
```
Layer height: 0.15mm
Infill: 50%
Orientation: Flat
```

The curved bottom of the follower should rest smoothly on the cams. Sand if needed.

---

## Calibration Test

**PRINT THIS FIRST before printing all parts:**

Create a test piece with:
1. One cam
2. One wave segment
3. A short section of frame with one guide slot

Test that:
- [ ] Cam rotates freely on shaft
- [ ] Wave segment slides smoothly in guide
- [ ] Follower rests properly on cam without binding

If too tight: Increase `CLEARANCE` parameter
If too loose: Decrease `CLEARANCE` parameter

Typical values:
- Ender 3: CLEARANCE = 0.25
- Prusa: CLEARANCE = 0.20
- Resin: CLEARANCE = 0.15

---

## Assembly Instructions

### Step 1: Prepare the Shaft
1. Cut 6mm steel rod to 200mm length
2. File the ends smooth
3. Clean any burrs

### Step 2: Press Cams onto Shaft
This is the most important step!

1. Mark the shaft every ~14mm (segment width)
2. Starting from one end, press first cam onto shaft
3. Rotate **exactly 30°** before pressing next cam
4. Use the 12-sided polygon as reference (each flat = 30°)
5. Continue for all 12 cams

**Tip:** Make a jig with 30° marks to ensure accurate alignment

```
Cam positions (viewed from motor end):
Cam 1:  0°
Cam 2:  30°
Cam 3:  60°
Cam 4:  90°
Cam 5:  120°
Cam 6:  150°
Cam 7:  180°
Cam 8:  210°
Cam 9:  240°
Cam 10: 270°
Cam 11: 300°
Cam 12: 330°
```

### Step 3: Assemble Frame
1. Attach left side frame to base
2. Insert wave segments into guide slots
3. Insert camshaft with cams through bearing holes
4. Attach right side frame

### Step 4: Verify Motion
1. Turn shaft by hand
2. Each wave segment should rise and fall smoothly
3. Wave should appear to travel from left to right (or vice versa)

### Step 5: Add Motor
1. Attach motor mount to right side frame
2. Insert motor into mount
3. Connect shaft coupler between motor shaft and camshaft
4. Tighten set screws

### Step 6: Power Up
1. Connect battery pack
2. Switch on
3. Enjoy mesmerizing wave motion!

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Segments don't move | Cams not touching followers | Adjust segment depth or cam size |
| Wave stuck/jerky | Too much friction | Sand guide slots, add dry lubricant |
| No traveling wave | Cams not properly offset | Re-align cams at 30° intervals |
| Motor stalls | Too much load | Check for binding, reduce friction |
| Segments fall out | Guide slot too loose | Reprint with smaller clearance |

---

## Integration with Starry Night

This simplified mechanism can be integrated into the full Starry Night sculpture by:

1. **Position:** Place behind the wave zone (X = 78-302mm)
2. **Scale:** Adjust FRAME_WIDTH to match wave area (224mm)
3. **Blades:** Replace rectangular blades with Van Gogh wave shapes
4. **Colors:** Print segments in blue gradient (deep blue → white for foam)

The camshaft provides reliable, mesmerizing wave motion without the complexity of the multi-zone mechanism.

---

## References

- [MicroWave by Greg Zumwalt](https://www.instructables.com/MicroWave/) - Original inspiration
- [Kinetic Art Wave Machine](https://www.printables.com/model/734776-kinetic-art-wave-machine) - Alternative design
- [Wave Kinetic Art](https://www.thingiverse.com/thing:2890318) - Hand-crank version

---

*Designed for reliability, not complexity.*
