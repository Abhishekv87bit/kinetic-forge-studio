/*
 * ASSEMBLY.SCAD - Complete Whack-a-Mole Wave Sculpture
 *
 * ANIMATION: View → Animate in OpenSCAD
 * - FPS: 30
 * - Steps: 120
 *
 * CONCEPT:
 * - Box with slits on top
 * - Slats sit in slits (guidance built-in)
 * - Cams hidden underneath push slats up
 * - Phase offsets EMBEDDED in cam geometry (not just animation!)
 *
 * At any frame, each layer's wave peak is at a DIFFERENT X position.
 */

include <common.scad>
use <parts/box.scad>
use <parts/barrel_cam.scad>
use <parts/slat.scad>
use <parts/shaft_assembly.scad>

// ============================================
// ANIMATION CONTROL
// ============================================

// theta: motor rotation angle (0-360 degrees per rotation)
// $t: OpenSCAD animation variable (0.0 to 1.0)
theta = $t * 360;

// ============================================
// VISIBILITY TOGGLES
// ============================================

SHOW_BOX = true;
SHOW_CAMS = true;
SHOW_SLATS = true;
SHOW_SHAFTS = true;
SHOW_DRIVE = false;   // Belt/pulleys (optional)

// Layer visibility (for debugging)
SHOW_LAYER = [true, true, true];

// Transparency for box (to see mechanism inside)
BOX_ALPHA = 0.3;

// ============================================
// COORDINATE SYSTEM
// ============================================

// Box spans Y from 0 (front) to BOX_WIDTH (back)
// All components use LAYER_Y_BOX and CAM_Y_BOX for absolute positioning
// NO MORE Y_OFFSET - everything uses absolute box coordinates!

// ============================================
// MAIN ASSEMBLY
// ============================================

// --- BOX ENCLOSURE ---
if (SHOW_BOX) {
    color(C_BOX, BOX_ALPHA)
        box_complete();
}

// --- BARREL CAMS (rotating, inside box) ---
if (SHOW_CAMS) {
    for (layer = [0 : NUM_LAYERS - 1]) {
        if (SHOW_LAYER[layer]) {
            // Cam rotates around X-axis
            // Motor rotation applies to ALL cams equally
            // Phase difference is EMBEDDED in cam geometry!

            translate([0, CAM_Y_BOX[layer], CAM_Z[layer]])  // Absolute coordinates!
            rotate([theta, 0, 0])  // Same rotation for all - phase is in geometry
            color(C_CAM)
                barrel_cam(layer);
        }
    }
}

// --- SHAFTS ---
if (SHOW_SHAFTS) {
    for (layer = [0 : NUM_LAYERS - 1]) {
        translate([0, CAM_Y_BOX[layer], CAM_Z[layer]])  // Absolute coordinates!
        rotate([0, 90, 0])
        color(C_SHAFT)
            cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true);
    }
}

// --- SLATS (animated, emerging from floor slits) ---
if (SHOW_SLATS) {
    for (layer = [0 : NUM_LAYERS - 1]) {
        if (SHOW_LAYER[layer]) {
            for (i = [0 : NUM_SLATS - 1]) {
                // Slat X position (with layer interlocking offset)
                x = slat_x(i, layer);

                // Slat Y position - use absolute box coordinates!
                y = LAYER_Y_BOX[layer];

                // Slat Z position (driven by cam)
                // slat_z() calculates position based on cam rotation
                z_base = slat_z(i, layer, theta);

                // Slat height (varies for visual interest)
                h = slat_height(i);

                // Position slat so bottom is at z_base, centered in Y
                translate([x, y, z_base + h/2])
                color(slat_color(layer))
                    slat(h, layer);
            }
        }
    }
}

// --- DRIVE SYSTEM (optional) ---
if (SHOW_DRIVE) {
    // Drive system uses its own CAM_Y positioning internally
    shaft_assembly();
}

// ============================================
// ANIMATION INFO
// ============================================

echo("");
echo("╔════════════════════════════════════════════╗");
echo("║  WHACK-A-MOLE WAVE V3                      ║");
echo("║  EMBEDDED PHASE OFFSETS                   ║");
echo("╠════════════════════════════════════════════╣");
echo(str("║  Animation: theta = ", theta, " deg"));
echo(str("║  $t = ", $t));
echo("╠════════════════════════════════════════════╣");
echo("║  To animate: View → Animate               ║");
echo("║    FPS: 30                                 ║");
echo("║    Steps: 120                              ║");
echo("╚════════════════════════════════════════════╝");
echo("");
echo("KEY FIX: Phase offsets are EMBEDDED in cam geometry!");
echo("All cams rotate together, but their ridges start at different angles:");
echo(str("  Cam 0: +", LAYER_PHASE_OFFSET[0], " deg"));
echo(str("  Cam 1: +", LAYER_PHASE_OFFSET[1], " deg"));
echo(str("  Cam 2: +", LAYER_PHASE_OFFSET[2], " deg"));
echo("");
echo("Watch: Each layer's wave peak should be at DIFFERENT X position!");

// ============================================
// DEBUG: Alignment Verification Markers
// ============================================

// ENABLE THIS TO VERIFY CAM-SLAT ALIGNMENT:
// Red = cam center, Green = slat layer center
// They should be at the same Y position!

SHOW_DEBUG_MARKERS = true;  // Set to false to hide

if (SHOW_DEBUG_MARKERS) {
    for (layer = [0 : NUM_LAYERS - 1]) {
        // Cam center marker (RED sphere at cam Z level)
        translate([0, CAM_Y_BOX[layer], CAM_Z[layer]])
            color("red", 0.8) sphere(d = 8, $fn = 16);

        // Slat layer marker (GREEN sphere at floor level)
        translate([0, LAYER_Y_BOX[layer], FLOOR_Z])
            color("green", 0.8) sphere(d = 8, $fn = 16);

        // Connection line (shows vertical alignment)
        color("yellow", 0.5)
        hull() {
            translate([0, CAM_Y_BOX[layer], CAM_Z[layer]])
                sphere(d = 2, $fn = 8);
            translate([0, LAYER_Y_BOX[layer], FLOOR_Z])
                sphere(d = 2, $fn = 8);
        }

        // Label (layer number)
        translate([-CAM_LENGTH/2 - 15, CAM_Y_BOX[layer], CAM_Z[layer]])
            color("white")
            text(str("L", layer), size = 8, halign = "center", valign = "center");
    }

    // Legend
    echo("");
    echo("╔═══════════════════════════════════════╗");
    echo("║  DEBUG MARKERS ENABLED                ║");
    echo("╠═══════════════════════════════════════╣");
    echo("║  RED = Cam center position            ║");
    echo("║  GREEN = Slat layer position at floor ║");
    echo("║  YELLOW = Alignment verification line ║");
    echo("╠═══════════════════════════════════════╣");
    echo("║  If aligned correctly:                ║");
    echo("║  - Red and Green at same Y coordinate ║");
    echo("║  - Yellow line is vertical            ║");
    echo("╚═══════════════════════════════════════╝");
    echo("");
    echo("POSITIONS:");
    for (layer = [0 : NUM_LAYERS - 1]) {
        echo(str("  Layer ", layer, ": Y=", LAYER_Y_BOX[layer], ", Cam Z=", CAM_Z[layer]));
    }
}

// ============================================
// DEBUG: Show phase verification points
// ============================================

// Uncomment to see where wave peaks are at current frame
/*
for (layer = [0 : NUM_LAYERS - 1]) {
    // Find X position where wave peaks (phase = 0)
    // phase = helix_angle + theta + LAYER_PHASE_OFFSET
    // peak when phase = 0 (or 360)
    target_helix = -theta - LAYER_PHASE_OFFSET[layer];
    // Normalize to 0-360
    target_helix_norm = (target_helix % 360 + 360) % 360;
    // Convert back to X position
    peak_x = (target_helix_norm / (360 * HELIX_TURNS)) * CAM_LENGTH - CAM_LENGTH/2;

    // Show marker at peak
    translate([peak_x, LAYER_Y_BOX[layer], FLOOR_Z + 60])
    color("red")
        cylinder(d = 3, h = 10, $fn = 6);
}
*/
