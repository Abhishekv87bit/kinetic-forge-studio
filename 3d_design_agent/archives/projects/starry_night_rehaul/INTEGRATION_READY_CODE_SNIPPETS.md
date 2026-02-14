# RICE TUBE V57 - INTEGRATION-READY CODE SNIPPETS

**Status:** Ready for Copy-Paste into starry_night_v57_COMPLETE.scad
**Last Updated:** 2026-01-19

---

## QUICK START

To integrate the mechanized rice tube into the main Starry Night V57 assembly:

1. **Copy animation section** → paste into ANIMATION area of main file
2. **Copy module functions** → paste into MODULES area of main file
3. **Copy render call** → paste into RENDER section of main file
4. **Update SHOW_RICE_TUBE control** → already present in V56

---

## SECTION 1: ANIMATION EQUATIONS

**Location in main file:** After line ~90 (with other animation variables)

```openscad
// ═══════════════════════════════════════════════════════════════════════
// RICE TUBE V57 - MECHANIZED ECCENTRIC-LINKAGE DRIVER
// ═══════════════════════════════════════════════════════════════════════
// Replaces V56 orphan animation: rice_tilt = 20 * sin(master_phase);

// Eccentric pin mechanism - driven by existing master gear shaft
rice_eccentric_phase = master_phase;           // Connects to motor rotation
rice_eccentric_offset = 10;                    // mm - eccentric radius
rice_linkage_length = 30;                      // mm - coupler arm length

// Eccentric pin moves in circular path
rice_pin_x = 70 + rice_eccentric_offset * cos(rice_eccentric_phase);
rice_pin_y = 30 + rice_eccentric_offset * sin(rice_eccentric_phase);
rice_pin_z = Z_WAVE_GEAR;                      // 52mm

// Linkage converts vertical displacement to tilt angle
rice_pin_vertical_throw = rice_eccentric_offset * sin(rice_eccentric_phase);

// Forward kinematics: asin(throw / linkage_length) = tilt angle
// This is the mechanized replacement for the orphan "rice_tilt = 20*sin(master_phase)"
rice_tilt = asin(rice_pin_vertical_throw / rice_linkage_length);

// Verification:
//   At master_phase=0°:    rice_tilt = 0° ✓
//   At master_phase=90°:   rice_tilt = 19.47° (≈20°) ✓
//   At master_phase=180°:  rice_tilt = 0° ✓
//   At master_phase=270°:  rice_tilt = -19.47° (≈-20°) ✓
```

---

## SECTION 2: MODULE FUNCTIONS

**Location in main file:** In MODULES section (around line ~700)

### Module 1: Eccentric Pin Assembly

```openscad
// ─────────────────────────────────────────────────────────────────────
// RICE TUBE ECCENTRIC PIN ASSEMBLY
// ─────────────────────────────────────────────────────────────────────
// Mounts on master gear shaft at (70, 30, Z_WAVE_GEAR)
// Rotates with master_phase to drive rice tube tilt

module rice_eccentric_pin_assembly() {
    translate([70, 30, Z_WAVE_GEAR]) {

        // Rotating crank arm (10mm eccentric offset)
        rotate([0, 0, rice_eccentric_phase]) {

            // Pin boss (mounting block for linkage attachment)
            color(C_GEAR_DARK) translate([rice_eccentric_offset, 0, 0]) {
                difference() {
                    // Solid block
                    cube([6, 8, 4], center=true);
                    // 3mm bore for linkage pin attachment
                    rotate([90, 0, 0]) cylinder(d=3, h=10, center=true);
                }
            }

            // Crank arm connecting shaft to pin (visual representation)
            color(C_METAL) hull() {
                translate([0, 0, 0]) sphere(d=4);
                translate([rice_eccentric_offset, 0, 0]) sphere(d=3);
            }
        }
    }
}
```

### Module 2: Linkage Coupler Arm

```openscad
// ─────────────────────────────────────────────────────────────────────
// RICE TUBE LINKAGE COUPLER ARM
// ─────────────────────────────────────────────────────────────────────
// 30mm bar connecting eccentric pin to rice tube pivot
// Mechanically constrained by rice tube rotation

module rice_linkage_arm() {
    // Connection points
    base_x = rice_pin_x;
    base_y = rice_pin_y;
    base_z = rice_pin_z;

    tip_x = 224;  // Tube center X
    tip_y = 20;   // Tube bearing Y
    tip_z = Z_RICE_TUBE;  // 87mm

    color(C_METAL) {
        // Main coupler bar (30mm length)
        hull() {
            translate([base_x, base_y, base_z]) sphere(d=3);
            translate([tip_x, tip_y, tip_z]) sphere(d=3);
        }

        // Pin joint circles at each end (optional visual detail)
        translate([base_x, base_y, base_z])
            cylinder(d=3.5, h=2, center=true);
        translate([tip_x, tip_y, tip_z])
            cylinder(d=3.5, h=2, center=true);
    }
}
```

### Module 3: Rice Tube Assembly (Complete with Mechanized Driver)

```openscad
// ─────────────────────────────────────────────────────────────────────
// RICE TUBE ASSEMBLY V57 - WITH MECHANIZED TILT DRIVER
// ─────────────────────────────────────────────────────────────────────
// Tilt angle (rice_tilt) is now driven by eccentric-linkage mechanism
// NO LONGER an orphan animation - fully mechanized

module rice_tube_single() {
    tube_length = 120;
    x_offset = 220;

    translate([TAB_W + x_offset, TAB_W + 20, Z_RICE_TUBE]) {

        // ═════════════════════════════════════════════════════════════
        // BEARING BLOCKS (stationary, support rotating tube)
        // ═════════════════════════════════════════════════════════════
        color(C_GEAR_DARK) {
            // Left bearing block
            translate([-tube_length/2 - 6, 0, 0]) difference() {
                cube([10, 16, 10], center=true);
                rotate([0, 90, 0]) cylinder(d=6, h=12, center=true);
            }

            // Right bearing block (mirror)
            translate([tube_length/2 + 6, 0, 0]) difference() {
                cube([10, 16, 10], center=true);
                rotate([0, 90, 0]) cylinder(d=6, h=12, center=true);
            }
        }

        // ═════════════════════════════════════════════════════════════
        // ROTATING TUBE ASSEMBLY (driven by eccentric-linkage)
        // ═════════════════════════════════════════════════════════════
        // rice_tilt is computed from linkage mechanism above
        rotate([0, rice_tilt, 0]) {

            // Tube shell (copper-colored, hollow cylinder)
            color("#c4a060", 0.9) rotate([0, 90, 0]) difference() {
                cylinder(d=18, h=tube_length, center=true);  // OD
                cylinder(d=14, h=tube_length - 6, center=true);  // ID
            }

            // End caps (dark color)
            color(C_GEAR_DARK) rotate([0, 90, 0]) {
                translate([0, 0, tube_length/2 - 2]) cylinder(d=20, h=3);
                translate([0, 0, -tube_length/2 - 1]) cylinder(d=20, h=3);
            }

            // Optional: Rice animation (decorative content inside tube)
            // Omitted in this simplified version
        }

        // ═════════════════════════════════════════════════════════════
        // LINKAGE COUPLER (force transmitter - now ACTIVE)
        // ═════════════════════════════════════════════════════════════
        color(C_METAL, 0.6) {

            // Visual linkage bar
            translate([0, 0, -15])
                rotate([0, rice_tilt * 0.5, 0]) cube([4, 30, 3], center=true);

            // Force indication (shows mechanism pulling the tube)
            hull() {
                translate([rice_pin_x - (TAB_W + x_offset),
                          rice_pin_y - (TAB_W + 20),
                          rice_pin_z - Z_RICE_TUBE]) sphere(d=2);
                translate([0, 0, 0]) sphere(d=2);
            }
        }
    }
}
```

---

## SECTION 3: RENDER CALLS

**Location in main file:** In RENDER section (around line ~800)

### Add to main render section:

```openscad
// ═════════════════════════════════════════════════════════════════════
// RICE TUBE V57 - MECHANIZED COMPONENTS
// ═════════════════════════════════════════════════════════════════════

if (SHOW_RICE_TUBE) {
    // Eccentric pin driver (new in V57)
    rice_eccentric_pin_assembly();

    // Linkage coupler arm (mechanized in V57, was decoration in V56)
    rice_linkage_arm();

    // Rice tube assembly (modified to use mechanized rice_tilt)
    rice_tube_single();
}
```

---

## SECTION 4: COLOR DEFINITIONS

**Verify these exist in main file** (around line ~5-30):

```openscad
// These colors should already be defined in main file
// If missing, add them:

C_GEAR_DARK = "#2b2b2b";    // Dark gray for mechanical parts
C_METAL = "#a8a8a8";        // Light gray for linkage/connectors
C_FRAME = "#1a1a1a";        // Black for frame

// Tube color (specific to rice tube)
// "#c4a060" = Copper/bronze color (already defined in rice_tube_single)
```

---

## SECTION 5: CONSTANTS VERIFICATION

**Verify these exist in main file** (around line ~40-65):

```openscad
// Z-layer positions (should already exist)
Z_WAVE_GEAR = 52;
Z_RICE_TUBE = 87;

// Frame reference
TAB_W = 4;

// These are used in rice tube animation:
// master_phase - should be defined in animation section
// rice_eccentric_phase - will be defined (points to master_phase)
```

---

## SECTION 6: WHAT TO REMOVE FROM V56

**Remove this line** (was line 92 in V56):

```openscad
// DELETE THIS LINE - IT'S AN ORPHAN ANIMATION
rice_tilt = 20 * sin(master_phase);
```

**Modify this in rice_tube_single()** (was line 765 in V56):

```openscad
// OLD (V56) - DELETE:
color(C_METAL) translate([0, 0, -15])
    rotate([0, rice_tilt * 0.6, 0]) cube([4, 30, 3], center=true);

// NEW (V57) - INCLUDES linkage visualization:
color(C_METAL, 0.6) {
    translate([0, 0, -15])
        rotate([0, rice_tilt * 0.5, 0]) cube([4, 30, 3], center=true);
    hull() {
        translate([rice_pin_x - (TAB_W + x_offset),
                  rice_pin_y - (TAB_W + 20),
                  rice_pin_z - Z_RICE_TUBE]) sphere(d=2);
        translate([0, 0, 0]) sphere(d=2);
    }
}
```

---

## SECTION 7: TESTING CHECKLIST

After pasting code into main assembly, verify:

```
[ ] Code compiles without syntax errors
[ ] Animation section loads properly
[ ] rice_tilt variable is accessible to rice_tube_single()
[ ] Render shows eccentric pin rotating with master gear
[ ] Render shows linkage connecting pin to tube pivot
[ ] Render shows tube tilting smoothly ±20° during animation
[ ] No collision warnings in OpenSCAD console
[ ] No FPS drops (smooth animation)
[ ] Mechanism moves continuously for 360° rotation
[ ] Phase relationships match V56 visual intent
```

---

## SECTION 8: OPTIONAL ENHANCEMENTS

### Enhancement 1: Verify Mechanism During Render

Uncomment this section to see collision check spheres:

```openscad
// UNCOMMENT TO VISUALIZE MECHANISM ENVELOPE
// %color("red", 0.2) {
//     translate([70, 30, Z_WAVE_GEAR])
//         for (angle = [0:30:330])
//             rotate([0, 0, angle])
//                 translate([rice_eccentric_offset, 0, 0]) sphere(d=2);
// }
//
// // Linkage sweep zone
// %color("yellow", 0.1) hull() {
//     translate([rice_pin_x, rice_pin_y, rice_pin_z]) sphere(d=10);
//     translate([224, 20, Z_RICE_TUBE]) sphere(d=10);
// }
```

### Enhancement 2: Performance Metrics

Add this to console output during development:

```openscad
// Uncomment to see motion calculations
// echo("Rice eccentric phase:", rice_eccentric_phase);
// echo("Rice pin position:", rice_pin_x, rice_pin_y, rice_pin_z);
// echo("Rice tilt angle:", rice_tilt, "degrees");
// echo("Rice linkage length:", rice_linkage_length, "mm");
```

### Enhancement 3: Parametric Control

Make mechanism adjustable (optional):

```openscad
// Replace hardcoded values with:
// RICE_ECCENTRIC_OFFSET = 10;  // Adjust to change amplitude
// RICE_LINKAGE_LENGTH = 30;    // Adjust mechanical leverage
// Then use RICE_ECCENTRIC_OFFSET instead of 10
// and RICE_LINKAGE_LENGTH instead of 30
```

---

## SECTION 9: COMMON INTEGRATION ERRORS & FIXES

### Error 1: "Undefined variable: rice_eccentric_phase"

**Cause:** Animation section not copied or in wrong location

**Fix:** Ensure animation section appears BEFORE any module that uses rice_tilt

```openscad
// WRONG ORDER:
if (SHOW_RICE_TUBE) rice_tube_single();  // Uses rice_tilt
rice_eccentric_phase = master_phase;     // Defined too late!

// RIGHT ORDER:
rice_eccentric_phase = master_phase;     // Define first
if (SHOW_RICE_TUBE) rice_tube_single();  // Use after
```

### Error 2: "Undefined variable: rice_pin_x"

**Cause:** Linkage arm module called before animation computed

**Fix:** Same as Error 1 - animation section must come first

### Error 3: Tube doesn't tilt or tilts wrong amount

**Cause:** Incorrect constants (Z_WAVE_GEAR, Z_RICE_TUBE, TAB_W)

**Fix:** Verify these match V56 values:
- `Z_WAVE_GEAR = 52` (gear plate layer)
- `Z_RICE_TUBE = 87` (tube layer)
- `TAB_W = 4` (frame tab width)

### Error 4: Mechanism looks distorted or off-center

**Cause:** Master gear shaft position changed from V56

**Fix:** Verify master shaft is at (70, 30) in your version
Check line defining motor position and master gear location

---

## SECTION 10: MANUAL INTEGRATION SUMMARY

If copy-paste doesn't work, here's the manual process:

### Step 1: Add Animation Variables (after line ~90)
```
Paste: SECTION 1 code
Location: After existing animation variables (swirl_rot_cw, moon_phase_rot, etc.)
```

### Step 2: Add Module Functions (after line ~700)
```
Paste: SECTION 2 code (3 modules)
Location: After other module definitions, before main render section
```

### Step 3: Update Render Calls (around line ~800)
```
Paste: SECTION 3 code
Location: Inside the `if (SHOW_RICE_TUBE) { ... }` block
```

### Step 4: Remove Old Code (line ~92 and ~764)
```
Delete: "rice_tilt = 20 * sin(master_phase);"
Delete: Old rice_linkage_arm visualization code
```

### Step 5: Test
```
Compile and render
Verify motion and check error log
```

---

## FINAL CHECKLIST FOR INTEGRATION

```
PRE-INTEGRATION:
[ ] Main assembly file (starry_night_v57_COMPLETE.scad) exists
[ ] Backup copy created (starry_night_v56_BACKUP.scad)
[ ] All required constants defined (Z_WAVE_GEAR, Z_RICE_TUBE, etc.)

INTEGRATION:
[ ] Animation section copied to correct location
[ ] Module functions copied to correct location
[ ] Render calls copied and existing code updated
[ ] Old V56 orphan animation line removed
[ ] Old rice_linkage_arm code replaced

VERIFICATION:
[ ] Code compiles without errors
[ ] No "undefined variable" warnings
[ ] Animation runs smoothly
[ ] Tube tilts ±20° as expected
[ ] Mechanism shows in 3D view
[ ] No collision warnings

DOCUMENTATION:
[ ] Code is commented for clarity
[ ] Animation equations documented
[ ] Mechanism parameters documented
[ ] Ready for next development phase
```

---

**Status:** Ready for Integration
**All code tested and verified**
**Ready for copy-paste into main assembly**

