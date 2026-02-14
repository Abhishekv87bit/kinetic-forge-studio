# STARRY NIGHT V57 INTEGRATION PLAN

## Executive Summary

This document consolidates all findings from the 16-agent parallel rehaul analysis. V57 will fix 7 critical issues while preserving the simplified wave mechanism approach from V56.

---

## CRITICAL FIXES (7 Items)

### Fix C1: Cypress Orphan → Mechanized

**Current (Orphan):**
```openscad
cypress_sway_back = 4 * sin(t * 360 * 0.35);
cypress_sway_front = 5 * sin(t * 360 * 0.45);
```

**V57 Fix (Mechanized):**
```openscad
// Add at line ~75:
cypress_gear_ratio = 18.0 / 45.0;  // Idler mesh
cypress_gear_angle = gear_rot * cypress_gear_ratio;
cypress_eccentric_throw = 2.0 * sin(cypress_gear_angle);
cypress_sway_back = asin(cypress_eccentric_throw / 50.0) * (180/3.14159);
cypress_sway_front = asin(cypress_eccentric_throw / 45.0) * (180/3.14159);
```

**Add module for mechanism visualization:**
```openscad
module cypress_drive_mechanism() {
    // 45T gear at (69, 4) meshing with idler
    translate([TAB_W + 69, TAB_W + 4, Z_GEAR_PLATE]) {
        rotate([0, 0, cypress_gear_angle]) {
            detailed_gear(45, 22.5, 6, 4);
            // Eccentric pin
            translate([20.5, 0, 6]) color(C_METAL) cylinder(d=4, h=8);
        }
    }
}
```

---

### Fix C2: Rice Tube Orphan → Mechanized

**Current (Orphan):**
```openscad
rice_tilt = 20 * sin(master_phase);
```

**V57 Fix (Mechanized):**
```openscad
// Add at line ~92:
rice_eccentric_phase = master_phase;
rice_pin_y = 10 * sin(rice_eccentric_phase);  // 10mm eccentric offset
rice_tilt = asin(rice_pin_y / 30) * (180/3.14159);  // 30mm linkage
```

---

### Fix C3: Birds Orphan + Speed Reduction

**Current (Orphan):**
```openscad
bird_pendulum_angle = BIRD_SWING_ARC * sin(t * 360 * 0.25);
wing_flap = 25 * sin(t * 360 * 8);  // 8x too fast
```

**V57 Fix (Mechanized + Slower):**
```openscad
// Add at line ~83:
bird_crank_angle = master_phase * 0.5;
bird_crank_y = 5 * sin(bird_crank_angle);  // 5mm eccentric
bird_pendulum_angle = asin(bird_crank_y / 30) * 1.2 * (180/3.14159);  // 30mm linkage, scaled to ±30°

// Reduce wing speed:
wing_flap = 25 * sin(t * 360 * 4);  // Changed from 8x to 4x
```

---

### Fix C4: Swirls Animation → Belt-Driven

**Current (Orphan):**
```openscad
swirl_rot_cw = t * 360 * 0.5;
swirl_rot_ccw = -t * 360 * 0.7;
```

**V57 Fix (Belt-Driven):**
```openscad
// Replace at line ~69-70:
swirl_belt_ratio = 20.0 / 24.0;  // Drive 20T → Swirl 24T
swirl_belt_driven = -gear_rot * swirl_belt_ratio;  // From master gear
swirl_rot_cw = swirl_belt_driven;
swirl_rot_ccw = swirl_belt_driven;  // Same speed, moiré from line count diff (24 vs 26)
```

---

### Fix C5: Lighthouse Pulley Ratio

**Current (Orphan):**
```openscad
lighthouse_rot = t * 360 * 0.3;  // 0.3x
// But pulley is 20T:20T = 1:1 = 0.4x
```

**V57 Fix (Correct Ratio):**
```openscad
// Replace at line ~72:
lighthouse_rot = -gear_rot * 0.75;  // 0.4 * 0.75 = 0.3x

// Update pulley at line ~456:
rotate([0, 0, lighthouse_rot]) gt2_pulley(27, 6, 3);  // Changed from 20T to 27T
```

---

### Fix C6: Moon Belt Z-Layer Conflict

**Current (Conflict):**
```openscad
// Line 539-545: Moon belt at Z_MOON_PHASE - 8 = 7 (same as Star belt!)
```

**V57 Fix (Separate Z-Layers):**
```openscad
// Add constant at line ~104:
MOON_BELT_Z = Z_STAR_GEAR + 2;  // = 12 (Star belt at 7, 5mm separation)

// Replace all Z_MOON_PHASE - 8 with MOON_BELT_Z:
// Line 539: translate([drive_x, drive_y, MOON_BELT_Z])
// Line 543-545: belt_segment(..., MOON_BELT_Z)
```

---

### Fix C7: Wave Foam Animation Ratios

**Current (Arbitrary):**
```openscad
curl_rot_zone1 = master_phase * 0.3;
curl_rot_zone2 = master_phase * 0.5;
curl_rot_zone3 = master_phase * 0.8;
```

**V57 Fix (Mechanical Ratios):**
```openscad
// Replace at line ~87-89:
// Use realistic gear ratios from Wave Drive (30T):
curl_rot_zone1 = -gear_rot * 2 * (12.0/30.0);  // 12T driven = 0.8x
curl_rot_zone2 = -gear_rot * 2 * (12.0/30.0);  // 12T driven = 0.8x
curl_rot_zone3 = -gear_rot * 2 * (16.0/30.0);  // 16T driven = 1.07x
```

---

## GEOMETRY CORRECTION

### Gear Train: Wave Drive Position

**Current:** Wave Drive at (115, 15) gives 47.4mm CD (2.4mm over spec)

**V57 Fix:**
```openscad
// Line 394: Change x from 115 to 110
translate([110, 15, Z_GEAR_PLATE]) {
    rotate([0, 0, -gear_rot * 2]) detailed_gear(30, 15, 6, 3);
```

---

## SIMPLIFIED MECHANISMS (Keep As-Is)

The wave zones use rotating foam gears instead of the originally specified mechanisms. This is **intentional and acceptable**:

| Zone | Original Spec | V56 Actual | Verdict |
|------|---------------|------------|---------|
| Zone 1 | Scotch Yoke | Rotating Foam 12T | ACCEPT |
| Zone 2 | Eccentric Cam | Rotating Foam 12T | ACCEPT |
| Zone 3 | Slider-Crank | Rotating Foam 16T | ACCEPT |

**Rationale:** Gear-mounted foam scores Van Gogh 8/10, Watt 9/10 per MECHANISM_ALTERNATIVES.md.

---

## V57 VERIFICATION CHECKLIST

After implementing fixes, verify at θ=0°, 90°, 180°, 270°:

```
ORPHAN ANIMATIONS:
[ ] Cypress sway traces to cypress_gear_angle (not sin($t))
[ ] Rice tilt traces to rice_eccentric_phase (not sin($t))
[ ] Bird pendulum traces to bird_crank_angle (not sin($t))
[ ] Swirls trace to swirl_belt_driven (not sin($t))
[ ] Lighthouse traces to -gear_rot * 0.75 (not sin($t))
[ ] Wave foams trace to gear_rot * 2 * ratio (not sin($t))

GEOMETRY:
[ ] Star belt at Z=7
[ ] Moon belt at Z=12 (no collision)
[ ] Swirl belt at Z=17
[ ] Lighthouse belt at Z=23
[ ] Wave Drive at (110, 15) - 45mm CD

COLLISIONS:
[ ] No belt-belt intersection
[ ] Foam curls clear wave layers
[ ] Cypress layers clear wind path
[ ] Bird wings clear pendulum arm

POWER:
[ ] Motor doesn't stall at any position
[ ] All gears mesh smoothly
```

---

## FILE OUTPUT

**Create:** `3d_design_agent/starry_night_v57_REHAUL.scad`

Copy V56 as base, then apply fixes C1-C7 plus geometry correction.

---

*Plan Status: READY FOR IMPLEMENTATION*
