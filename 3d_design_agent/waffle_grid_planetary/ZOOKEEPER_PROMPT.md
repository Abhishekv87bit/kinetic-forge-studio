# Zookeeper Prompt — Ravigneaux Double Planetary Gearset

## GOAL
Create a fully parametric, production-ready CAD assembly of a Ravigneaux double planetary gearset for a kinetic sculpture. Every component must be an individual parametric body with proper constraints. Export as STEP assembly. All dimensions in millimeters.

---

## GLOBAL GEAR SPECIFICATIONS
- Normal module: **0.866 mm**
- Helix angle: **30°** (right-hand)
- Transverse module: **1.0 mm** (= 0.866 / cos30°)
- Pressure angle: **20°**
- Dynamic clearance: **0.25 mm**
- All gears are **helical involute** unless noted otherwise

---

## COMPONENT LIST (13 parts + extensions)

### PART 1: Ring Gear (ring_gear)
- **Type:** Internal helical gear (teeth face inward)
- **Teeth:** 88T
- **Gear zone:** Z = 0 to Z = 22 mm (teeth active in this zone)
- **OD:** 96 mm
- **Wall thickness:** 3 mm (so ID at tooth roots ≈ 90 mm)
- **Full enclosure height:** extends from Z = -11 (bottom) to Z = 33.1 (top)
  - Bottom extension below gear zone: 11 mm solid wall (no teeth)
  - Top extension above gear zone: ~11 mm solid wall (no teeth)
- **Bottom lid:** annular plate at Z = -11, thickness 3 mm, central bore ≈ 36 mm (clears big sun tube + bearing clearance)
- **Top lid:** annular plate at Z ≈ 30.1, thickness 3 mm, central bore ≈ 37 mm (clears carrier_1 hub + bearing)
- **V-groove:** on the outer cylindrical surface, at Z ≈ 10 mm (midpoint of enclosure), 4 mm wide, 2 mm deep, 45° V-profile. This groove accepts a rope/cable.
- **Rotation:** This is the OUTPUT. It rotates as computed from the gear ratio.

### PART 2: Small Sun Gear Shaft (small_sun / Ss)
- **Type:** External helical gear integral with hollow shaft
- **Teeth:** 31T
- **Gear zone:** Z = 0 to Z = 22 mm (helical teeth on outer surface)
- **Shaft tube below gear:** OD = 18.75 mm, ID = 12 mm (hollow), extends from Z = 0 down to approximately Z = -53 mm
- **Assembly:** This is the INNERMOST rotating shaft. A solid 10 mm rod (Part 13) passes through its bore.
- **Mesh:** Ss meshes with the short pinions (Pi, 24T)
- **Thrust interface:** At the top face (Z = 22), a thrust ring (small_sun_ring, Part 11) sits between Ss top and SL inner bore
- **Input shaft end (below gearbox):**
  - Below the plain tube section, add a splined zone: 6 longitudinal ridges, 0.6 mm depth, 0.45 duty cycle
  - Below the spline, a mounting helical gear: 26T, normal module 0.866, helix 30°, face width 10 mm, with a splined bore matching the shaft spline

### PART 3: Big Sun Gear Shaft (big_sun / SL)
- **Type:** External helical gear integral with hollow shaft
- **Teeth:** 38T
- **Gear zone:** Z = 0 to Z = 22 mm (helical teeth on outer surface)
- **Shaft tube below gear:** OD = 25 mm, ID = 20 mm (hollow — the small sun shaft passes through inside), extends from Z = 0 down to approximately Z = -38 mm
- **Assembly:** This shaft is CONCENTRIC around the small sun shaft. It slides over the small sun tube.
- **Mesh:** SL meshes with the long pinions (Po, 25T)
- **Thrust interface:** At top face (Z = 22), big_sun_ring thrust washer (Part 10) sits between SL top and the carrier/ring lid interface. At bottom, another big_sun_ring sits between SL bottom face and carrier_2 top.
- **Input shaft end (below gearbox):**
  - Below the plain tube section, splined zone: 6 ridges, 0.6 mm depth, 0.45 duty
  - Mounting helical gear: 32T, mod 0.866, helix 30°, FW 10 mm, splined bore matching shaft

### PART 4: Long Pinion (Po) × 3
- **Type:** External helical gear
- **Teeth:** 25T
- **Height:** Z = 0 to Z = 22 mm (full gearbox height)
- **Orbit radius:** 31.5 mm from center (pin center)
- **Pin hole:** 8 mm diameter axial bore through center
- **Spacing:** 3 copies at 0°, 120°, 240° around center
- **Mesh:** Po meshes with SL (38T big sun) and Ring (88T internal)
- **Ravigneaux constraint:** SL + 2×Po = Ring → 38 + 2×25 = 88 ✓

### PART 5: Short Pinion (Pi) × 3
- **Type:** External helical gear
- **Teeth:** 24T
- **Height:** Z = 12 to Z = 22 mm (only top half of gearbox — shorter than Po)
- **Orbit radius:** 27.44 mm from center (actual measured, not theoretical 29.5)
- **Angular offset:** First Pi at 71.5° (not at 0° — offset from Po positions)
- **Pin hole:** 8 mm diameter axial bore through center
- **Spacing:** 3 copies at 71.5°, 191.5°, 311.5°
- **Mesh:** Pi meshes with Ss (31T small sun) and Po (25T long pinion)
- **Note:** Each Pi sits beside a Po — they form a meshing pair on the same carrier arm

### PART 6: Carrier_1 / Upper Carrier (planetary_1)
- **Type:** Structural plate with pin stubs + central hub
- **Plate:** OD = 78 mm, Z = 22 to Z = 26.5 mm (4.5 mm thick plate with honeycomb lightening pattern)
- **Central hub:** OD = 35 mm, extends upward from plate
- **Pin stubs on underside:** 3 × Po pin stubs at R = 31.5 mm (0°/120°/240°), 3 × Pi pin stubs at R = 27.44 mm (71.5°/191.5°/311.5°)
- **Pin stub diameter:** ~8 mm, extending downward into the pinion bores
- **Through bore:** clears SL shaft (≥ 25 mm)
- **This carrier does NOT rotate independently** — it is coupled to carrier_2 via the pinion pins

### PART 7: Carrier_2 / Lower Carrier (planetary_2)
- **Type:** Star-shaped plate + cylindrical hub tube
- **Star plate:** OD = 80 mm, Z = -1.5 to Z = -3.5 mm (2 mm thick), 3-fold symmetric star profile with 6 arms
- **Pin holes in plate:**
  - 3 × Po holes: D = 8 mm at R = 31.4 mm (0°/120°/240°)
  - 3 × Pi holes: D = 13.4 mm at R = 27.44 mm (71.5°/191.5°/311.5°) — oversized to clear carrier_3 boss
- **Hub tube:** OD = 33 mm, ID = 26 mm (clears SL shaft OD 25 + gap), extends from Z = -3.5 down to Z = -19.5
  - Collar zone Z = -3.5 to -6.5: inner R = 15.5 mm (thicker wall)
  - Tube zone Z = -6.5 to -19.5: thin wall tube
- **Bottom cap:** Z = -19.5 to -21.5, annular ring OD = 33, ID = 27.25 mm
- **Input shaft end (below gearbox):**
  - Splined extension below cap: OD = 33, ID = 26, with 6 spline ridges
  - Mounting helical gear: 40T, mod 0.866, helix 30°, FW 10 mm, splined bore

### PART 8: Carrier_3 / Pin Cage (planetary_3)
- **Type:** Structural cage connecting to carrier_2 via pinion axle pins
- **Located inside gearbox** between carrier_1 and carrier_2
- **Has bosses** (small cylindrical collars) around each pin hole — boss bore ≈ 8 mm, boss OD ≈ 9-10 mm
- **These bosses pass through carrier_2's Pi holes** (that's why Pi holes are 13.4 mm — to clear the boss)

### PART 9: Thrust Washers (small_washer) × multiple
- **Dimensions:** OD = 13 mm, ID = 6 mm, H = 1.2 mm
- **Placed at every moving interface** (see washer map below)

### PART 10: Big Sun Thrust Ring (big_sun_ring) × 2
- **Thrust washer between SL shaft and adjacent surfaces**
- **W5 position:** Between SL top face and carrier/ring interface (Z ≈ 22)
- **W8 position:** Between SL bottom face and carrier_2 top (Z ≈ -1.5)

### PART 11: Small Sun Thrust Ring (small_sun_ring) × 1
- **W6 position:** Between Ss top face and SL inner bore (Z ≈ 22)
- **Prevents axial metal-on-metal contact between the two sun shafts**

### PART 12: Retaining Clips (clip) × 6
- **E-clips or C-clips on each pinion axle**
- **Prevent axial migration of pinions on their pins**

### PART 13: Center Shaft (shaft)
- **Solid 10 mm diameter steel rod**
- **Passes through the bore of the small sun shaft**
- **Z range:** approximately Z = -53 to Z = 26 (extends both above and below gearbox)
- **Rotates with the small sun (Ss)**

---

## ASSEMBLY ORDER (bottom to top)

This is the physical assembly sequence — parts slide onto each other concentrically:

1. **Center shaft** (10 mm rod) — inserted first, vertical
2. **Small sun shaft** slides over center shaft (OD 18.75, bore 12 — clears 10 mm rod)
3. **Small sun thrust ring** placed on Ss top face (Z = 22)
4. **Big sun shaft** slides over small sun shaft (OD 25, bore 20 — clears 18.75 mm Ss tube)
5. **Big sun thrust ring** on SL top face (Z = 22)
6. **Carrier_2** (star plate + hub tube, OD 33, bore 26) slides over SL shaft
7. **Big sun thrust ring** between SL bottom and Carrier_2 top (Z ≈ -1.5)
8. **Long pinions (Po) × 3** — drop into carrier_2 Po pin holes, extending Z = 0 to 22
9. **Short pinions (Pi) × 3** — drop into carrier_2 Pi pin holes, extending Z = 12 to 22
10. **Carrier_3** (pin cage) — slides over pinion pins from above, bosses pass through carrier_2 Pi holes
11. **Carrier_1** (upper plate) — pin stubs engage pinion bores from above
12. **Pin washers + clips** — secure pinions axially on their pins
13. **Ring gear enclosure** — slides over entire assembly, internal teeth mesh with Po gears
14. **Ring lids** — close top and bottom of ring housing

---

## WASHER PLACEMENT MAP
| ID | Interface | Position | Type |
|----|-----------|----------|------|
| W1 | Ring top lid ↔ Carrier_1 top | Z ≈ 30 | Central thrust washer (OD 40, ID 20) |
| W2 | Carrier_1 underside ↔ Po top | Z ≈ 22, R = 31.5 | Pin washer × 3 |
| W3 | Carrier_1 underside ↔ Pi top | Z ≈ 22, R = 27.44 | Pin washer × 3 |
| W4 | Pi bottom ↔ Carrier_3 shelf | Z ≈ 12, R = 27.44 | Pin washer × 3 |
| W5 | SL top ↔ interface | Z ≈ 22 | big_sun_ring |
| W6 | Ss top ↔ SL inner bore | Z ≈ 22 | small_sun_ring |
| W7 | Po bottom ↔ Carrier_2 top | Z ≈ 0, R = 31.5 | Pin washer × 3 |
| W8 | SL bottom ↔ Carrier_2 | Z ≈ -1.5 | big_sun_ring |
| W9 | Carrier_2 bottom ↔ Ring bottom lid | Z ≈ -21.5 | Central thrust washer (OD 40, ID 20) |

---

## KINEMATIC RELATIONSHIPS
- **3 independent inputs:** SL (big sun), Ss (small sun), Carrier
- **1 output:** Ring gear
- **Gear equation:** ω_ring = -(T_SL/T_ring) × (ω_SL - ω_carrier) + ω_carrier
- **With only SL driving (Ss=0, Carrier=0):** ratio = -T_SL/T_ring = -38/88 = -0.4318
- **Po self-rotation:** ω_Po = ω_carrier - (T_SL/T_PO) × (ω_SL - ω_carrier)
- **Pi self-rotation:** ω_Pi = ω_carrier - (T_SS/T_PI) × (ω_Ss - ω_carrier)

---

## STAGE 2: INPUT DRIVE SYSTEM (below gearbox)

Each of the 3 concentric shafts extends downward below the gearbox with:
1. A plain tube section (adjustable length)
2. A splined section (6 ridges, 0.6 mm depth)
3. A mounting helical gear that slides onto the spline

Three HORIZONTAL drive shafts (8 mm steel rod) each carry a 20T helical drive pinion that meshes with the corresponding mounting gear:

| Shaft | Mounting Gear | Drive Pinion | Center Distance | Drive Angle |
|-------|--------------|--------------|-----------------|-------------|
| Ss (inner) | 26T | 20T | 18.5 mm | 0° |
| SL (middle) | 32T | 20T | 21.5 mm | 120° |
| Carrier (outer) | 40T | 20T | 24.5 mm | 240° |

The horizontal drive shafts run through multiple gearset units stacked in series (the "Waffle Grid" sculpture concept).

---

## CONSTRAINTS TO ENFORCE
1. All concentric shafts share the same center axis
2. Gear meshes must have correct center distances (tooth count × transverse module / 2)
3. Ravigneaux constraint: T_SL + 2×T_PO = T_RING
4. Pi and Po form meshing pairs — each Pi-Po pair sits on the same carrier arm
5. All thrust interfaces must have washer clearance
6. Boss on carrier_3 must pass through carrier_2 Pi holes (13.4 mm clearance)
7. Ring internal teeth mesh with Po external teeth at correct center distance
8. Carrier_1 and Carrier_2 are coupled — they rotate together via pinion pins

---

## PARAMETRIC REQUIREMENTS
Make these dimensions parametric (adjustable):
- Hub tube lengths for each shaft (Carrier, SL, Ss)
- Shaft extension lengths below gearbox
- Spline engagement length
- Mounting gear face widths
- Ring bottom extension height
- Inner rod extension (both ends equally)
- All clearances and tolerances

---

## OUTPUT FORMAT
- Individual STEP file per component
- Combined STEP assembly with proper mating constraints
- Each component as a separate body/part in the assembly
- Ready for 3D print prototyping (0.2 mm general tolerance, 0.25 mm dynamic clearance on gear meshes)
