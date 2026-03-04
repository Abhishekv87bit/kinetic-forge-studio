# Ravigneaux V9 Requirements — Kinetic Sculpture Node

## CLEANUP: Remove from V8

| Item to Remove | Reason |
|---|---|
| `planetary_top` parametric module | Was never needed — it's already inside planetary_1.stl |
| `planetary_mid` parametric module | Was never needed — it's already inside planetary_1.stl |
| `planet_carrier_pins` parametric module | Was just re-importing what planetary_3.stl already has |
| Input gears on sun shafts (Mod 5) | Removed per user request |
| Carrier external gear (Mod 3) | Removed per user request |
| All sub-body toggles/dimensions/colors for above | Dead code, remove |

## KEEP from V8

| Item to Keep | Notes |
|---|---|
| All 13 STL imports | Base geometry stays |
| Ring extension (Mod 1) | Ring covers full gear height Z=[-2, 24] |
| V-groove (Mod 2) | Rope housing on ring OD |
| `aShaft` | Still useful sub-body |
| All visibility toggles for STLs | User control |

## FIX 1: planetary_3 (carrier cage) must exist for ALL 3 planet pairs

**Current problem:** The `planetary_3.stl` import only shows ONE planet carrier cage sub-assembly. In the reference design it's meant to be printed 3x (the Printables page says "Planetary_3 x 3").

**Required:** Import `planetary_3.stl` THREE times at 120-degree spacing, so each of the 3 planet gear pairs (Po + Pi) has its own carrier cage.

### What planetary_3 contains:
- A carrier cage/cradle that holds one pair of planet gears (1x long pinion + 1x short pinion)
- The two planet gears sit on pins within this cage
- The cage connects to the main carrier plates (planetary_1 top, planetary_2 bottom)

### Implementation:
```
for (i = [0:2]) {
    ang = i * 120;
    rotate([0, 0, ang])
    import("planetary_3.stl");
}
```

## FIX 2: 3x long pinion and 3x short pinion at correct positions

**VERIFIED:** Each STL contains a SINGLE gear — NOT 3 copies. All 3 STLs (long_pinion, short_pinion, planetary_3) are single instances that need 3x rotation at 120°.

**Required:** Import each 3x at 120-degree intervals, same pattern as planetary_3.

### Implementation:
```
for (i = [0:2]) {
    ang = i * 120;
    rotate([0, 0, ang]) {
        import("long_pinion.stl");   // Po at orbit ~31.5mm
        import("short_pinion.stl");  // Pi at orbit ~29.5mm
        import("planetary_3.stl");   // carrier cage
    }
}
```

The single STL already has the gear at its correct orbit radius from center. Rotating the entire import at 120° places all 3 pairs correctly.

### Orbit positions (from reference):
- Po (long pinion): orbit ~31.5mm, Z=[0, 22]
- Pi (short pinion): orbit ~29.5mm, Z=[12, 22]

## FIX 3: Carrier_3 sits ON TOP of Carrier_2

**Current problem:** planetary_3 (carrier cage) may not be correctly stacked relative to planetary_2 (bottom carrier plate).

**Required:** planetary_3 sits directly on top of planetary_2. The bottom of planetary_3 (Z=-5.5) should mate with the top of planetary_2 (Z=-1.5). Check alignment and adjust Z offset if needed.

### Stacking order (bottom to top):
1. `planetary_2` — bottom carrier plate, Z=[-21.5, -1.5]
2. `planetary_3` x3 — carrier cages, Z=[-5.5, 10.5] (sits on planetary_2)
3. Planet gears — inside the cages, Z=[0, 22]
4. `planetary_1` — top carrier plate with honeycomb, Z=[-9, 26.5]

## FIX 4: Red retaining tab on carrier_3 — replicate for all 3 pairs

**What it is:** planetary_3 has a small tab/locking feature (highlighted by user in red) that locks the SHORT pinion (Pi) in place on its pin within the carrier cage.

**Current problem:** This tab only exists on one carrier cage instance. Since we're now instancing planetary_3 three times (Fix 1), the tab will automatically be present for all 3 pairs — as long as the tab is part of the planetary_3.stl geometry.

**Verify:** Confirm the tab is visible in the planetary_3.stl mesh. If it's a separate component in the f3d (like a clip), it may need to be separately instanced.

**VERIFIED:** The tab IS part of the planetary_3.stl mesh (visible in render as the arm/lobe at the bottom of the cage). 3x instancing (Fix 1) automatically places the retaining tab at all 3 positions. No separate modeling needed.

## REMAINING KINETIC MODS (kept from V8)

### Mod 1: Ring extends full gear height
- Original ring: Z=[12, 30] — only covers upper zone
- Extended ring: Z=[-2, 24] — covers entire gear zone with 2mm lip
- Added ring shell from Z=-2 to Z=12 (below original)

### Mod 2: V-groove on ring OD
- Width: 4mm, Depth: 2mm
- Center Z: 11mm (center of extended ring)
- Purpose: rope/thread housing for spool mechanism
- Visual rope indicator torus

## ASSEMBLY STRUCTURE (V9)

```
hybrid_assembly()
├── base_stl_assembly()
│   ├── shaft.stl
│   ├── small_sun.stl (Ss, green)
│   ├── big_sun_0_5_backlash.stl (SL, gold)
│   ├── long_pinion.stl x3 at 120° (Po, red)        ← FIX 2
│   ├── short_pinion.stl x3 at 120° (Pi, yellow)     ← FIX 2
│   ├── planetary_1.stl (top carrier, grey)
│   ├── planetary_2.stl (bottom carrier, dark grey)
│   ├── planetary_3.stl x3 at 120° (cages, light grey) ← FIX 1
│   ├── ring_low_profile.stl (ring, dark)
│   ├── big_sun_ring.stl (thrust ring)
│   ├── small_sun_ring.stl (thrust ring)
│   ├── small_washer.stl (washers)
│   └── clip.stl (clips)
├── ring_extension()          ← Mod 1
└── v_groove()                ← Mod 2
```

## KINEMATIC CHAIN (unchanged)

```
Input 1 → SL (large sun, 38T)  ──┐
Input 2 → Ss (small sun, 31T)  ──┤── planets ──→ Ring (88T) = OUTPUT
Input 3 → Carrier rotation     ──┘                    │
                                                   V-groove
                                                   rope/thread
                                                      │
                                                 hanging element
```

## GEAR SPECS (from f3d, unchanged)
- Module: 0.866mm
- Helix angle: 30 deg
- Ss: 31T herringbone (PD 26.85mm)
- SL: 38T right helix (PD 32.91mm)
- Pi: 24T right helix (PD 20.78mm)
- Po: 25T left helix (PD 21.65mm)
- Ring: 88T left helix (PD 76.21mm)
- DynamicClearance: 0.25mm
- Ravigneaux constraint: SL + 2*Po = Ring → 38 + 2*25 = 88 ✓
