/*
 * WAVE OCEAN V10 - COMPLETE ASSEMBLY
 * Staggered Barrel Cams + Fish Wire Suspension
 *
 * ANIMATION: Use View → Animate in OpenSCAD
 * - FPS: 30
 * - Steps: 120
 *
 * Features:
 * - 3 barrel cams staggered in Y+Z (no collision)
 * - 60 slats with follower arms (20 per layer)
 * - Fish wire suspension from top rail
 * - Channel guides for lateral constraint
 * - Single motor drives all via belt/pulley
 * - True traveling wave per layer (helical cam profile)
 * - Phase offset between layers (cascading wave)
 */

include <common.scad>
use <parts/barrel_cam.scad>
use <parts/slat_follower.scad>
use <parts/channel_guide.scad>
use <parts/top_rail.scad>
use <parts/bearing_block.scad>
use <parts/frame.scad>

// ============================================
// ANIMATION CONTROL
// ============================================

// theta: 0-360 degrees per rotation
// $t: OpenSCAD animation variable (0.0 to 1.0)
theta = $t * 360;

// ============================================
// VISIBILITY TOGGLES
// ============================================

SHOW_CAMS = true;
SHOW_SLATS = true;
SHOW_FRAME = true;
SHOW_RAILS = true;
SHOW_GUIDES = true;
SHOW_BEARINGS = true;
SHOW_WIRES = true;
SHOW_SHAFTS = true;

// Layer visibility
SHOW_LAYER = [true, true, true];

// ============================================
// MAIN ASSEMBLY
// ============================================

// --- FRAME ---
if (SHOW_FRAME) {
    frame_complete();
}

// --- BEARING BLOCKS ---
if (SHOW_BEARINGS) {
    translate([BB_LEFT_X, 0, 0])
    color(C_BB)
        bearing_block("left");

    translate([BB_RIGHT_X, 0, 0])
    color(C_BB)
        bearing_block("right");
}

// --- SHAFTS ---
if (SHOW_SHAFTS) {
    for (i = [0 : NUM_LAYERS - 1]) {
        translate([0, CAM_Y[i], CAM_Z[i]])
        rotate([0, 90, 0])
        color(C_SHAFT)
            cylinder(d = SHAFT_DIA, h = SHAFT_LENGTH, center = true);
    }
}

// --- BARREL CAMS (rotating) ---
if (SHOW_CAMS) {
    for (L = [0 : NUM_LAYERS - 1]) {
        if (SHOW_LAYER[L]) {
            // Cam rotates around X-axis
            // Phase offset per layer creates cascading wave
            cam_theta = theta + LAYER_PHASE_OFFSET[L];

            translate([0, CAM_Y[L], CAM_Z[L]])
            rotate([cam_theta, 0, 0])
            color(C_CAM)
                barrel_cam(L);
        }
    }
}

// --- CHANNEL GUIDES ---
if (SHOW_GUIDES) {
    for (L = [0 : NUM_LAYERS - 1]) {
        if (SHOW_LAYER[L]) {
            // Guides positioned at mid-height between cam and rail
            guide_z = (CAM_Z[L] + CAM_MAX_RADIUS + TOP_RAIL_Z) / 2;

            translate([0, LAYER_Y_CENTER[L], guide_z])
            color(C_GUIDE)
                channel_guide(L);
        }
    }
}

// --- TOP RAIL ASSEMBLY ---
if (SHOW_RAILS) {
    top_rail_assembly();
}

// --- SLATS WITH FOLLOWERS (animated) ---
if (SHOW_SLATS) {
    for (L = [0 : NUM_LAYERS - 1]) {
        if (SHOW_LAYER[L]) {
            for (i = [0 : NUM_SLATS - 1]) {
                // Slat X position (with layer offset for interlocking)
                x = slat_x(i, L);

                // Slat Y position (layer center)
                y = LAYER_Y_CENTER[L];

                // Slat Z position (driven by cam)
                // The slat rises/falls based on cam rotation
                z = slat_z(i, L, theta);

                // Slat height (varies for visual interest)
                h = slat_height(i);

                translate([x, y, z])
                color(slat_color(L))
                    slat_follower(h, L);
            }
        }
    }
}

// --- FISH WIRES (visualization) ---
if (SHOW_WIRES) {
    for (L = [0 : NUM_LAYERS - 1]) {
        if (SHOW_LAYER[L]) {
            for (i = [0 : NUM_SLATS - 1]) {
                x = slat_x(i, L);
                y = LAYER_Y_CENTER[L];
                z_slat = slat_z(i, L, theta);
                h = slat_height(i);

                // Wire from slat top to rail
                wire_bottom = z_slat + h - 3;  // Top of slat (where wire attaches)
                wire_top = TOP_RAIL_Z - TOP_RAIL_HEIGHT/2;
                wire_length = wire_top - wire_bottom;

                if (wire_length > 0) {
                    translate([x, y, wire_bottom])
                    color(C_WIRE, 0.5)
                        cylinder(d = WIRE_DIA, h = wire_length, $fn = 8);
                }
            }
        }
    }
}

// --- PULLEY SYSTEM ---
pulley_x = BB_LEFT_X - BB_WIDTH/2 - 15;

for (i = [0 : NUM_LAYERS - 1]) {
    // Pulleys rotate with cams
    pulley_theta = theta + LAYER_PHASE_OFFSET[i];

    translate([pulley_x, CAM_Y[i], CAM_Z[i]])
    rotate([pulley_theta, 0, 0])
    rotate([0, 90, 0])
    color([0.3, 0.3, 0.35]) {
        difference() {
            cylinder(d = 15, h = 8, center = true, $fn = 24);
            cylinder(d = SHAFT_DIA + 0.2, h = 10, center = true, $fn = 24);
        }
        // Timing belt teeth indication
        for (a = [0 : 18 : 359]) {
            rotate([0, 0, a])
            translate([7, 0, 0])
                cube([1, 1, 7], center = true);
        }
    }
}

// ============================================
// ANIMATION INFO
// ============================================

echo("");
echo("╔════════════════════════════════════════════╗");
echo("║  WAVE OCEAN V10 - STAGGERED BARREL CAMS    ║");
echo("╠════════════════════════════════════════════╣");
echo(str("║  Animation: theta = ", theta, "°"));
echo(str("║  $t = ", $t));
echo("╠════════════════════════════════════════════╣");
echo("║  To animate: View → Animate               ║");
echo("║    FPS: 30                                 ║");
echo("║    Steps: 120                              ║");
echo("╚════════════════════════════════════════════╝");
echo("");
echo("COMPONENT COUNT:");
echo(str("  Barrel cams: 3 (at Y=", CAM_Y, ", Z=", CAM_Z, ")"));
echo(str("  Slats: ", NUM_SLATS * NUM_LAYERS, " total (", NUM_SLATS, " per layer)"));
echo("  Bearing blocks: 2 (left + right)");
echo("  Channel guides: 3");
echo("  Top rails: 2 (front + back)");
echo("  Columns: 4");
echo("");
echo("PHASE OFFSETS (cascading wave):");
echo(str("  Layer 0 (back):  ", LAYER_PHASE_OFFSET[0], "°"));
echo(str("  Layer 1 (mid):   ", LAYER_PHASE_OFFSET[1], "°"));
echo(str("  Layer 2 (front): ", LAYER_PHASE_OFFSET[2], "°"));
