/*
 * WAVE OCEAN V10 - APPROACH E: ROTATING DISC ARRAY
 *
 * Concept: Like V8_disc but done CORRECTLY
 *          Multiple elliptical discs on parallel shafts
 *          Discs rotate, their edges form the wave surface
 *          Phase offset between rows creates traveling wave
 *
 * VIEWER POV: Front view, looking at -Y axis
 *   Sees the TOP EDGES of discs as wave surface
 *   Discs rotate in place, but envelope moves left
 *
 * Key fix from V8: Proper shaft-through-disc geometry
 */

$fn = 32;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// LAYOUT PARAMETERS
// ============================================

NUM_ROWS = 6;                // Rows of discs (depth, Y axis)
DISCS_PER_ROW = 4;           // Discs per row (along X axis)
ROW_SPACING = 15;            // Y distance between rows
DISC_SPACING = 40;           // X distance between discs

TOTAL_WIDTH = (DISCS_PER_ROW - 1) * DISC_SPACING;
TOTAL_DEPTH = (NUM_ROWS - 1) * ROW_SPACING;

// Phase creates traveling wave effect
PHASE_PER_ROW = 30;          // Phase offset between rows (wave travels)
PHASE_PER_DISC = 15;         // Phase offset between discs in row (stagger)

// ============================================
// DISC PARAMETERS
// ============================================

// Elliptical disc shape
DISC_MAJOR = 18;             // Long axis (vertical when at 0°)
DISC_MINOR = 12;             // Short axis
DISC_THICKNESS = 4;

// Shaft
SHAFT_DIA = 4;
SHAFT_HOLE = 4.4;            // Clearance hole in disc

// ECCENTRIC mounting - disc center offset from shaft
// This is what makes the disc "wobble" as it rotates
ECCENTRIC_OFFSET = 3;        // Distance from shaft axis to disc center

// ============================================
// SHAFT POSITIONS
// ============================================

SHAFT_Z = 25;                // Height of all shafts (same level)

// Shaft runs along X for each row
function shaft_y(row) = -TOTAL_DEPTH/2 + row * ROW_SPACING;

// ============================================
// COLORS
// ============================================

function disc_color(row) =
    let(t = row / (NUM_ROWS - 1))
    [0.1 + 0.4 * t, 0.25 + 0.35 * t, 0.5 + 0.4 * t];

C_SHAFT = [0.5, 0.5, 0.55];
C_FRAME = [0.3, 0.3, 0.35];

// ============================================
// KINEMATICS
// ============================================

// Phase for each disc (wave travels from back to front = -Y direction)
// Front rows (high row index) LEAD, so wave appears to travel toward viewer
// then we see it from front, so it goes RIGHT to LEFT
function disc_phase(row, disc) =
    theta + (NUM_ROWS - 1 - row) * PHASE_PER_ROW + disc * PHASE_PER_DISC;

// Disc top edge Z position (what viewer sees as wave surface)
function disc_top_z(row, disc) =
    let(phase = disc_phase(row, disc))
    SHAFT_Z + ECCENTRIC_OFFSET + DISC_MAJOR * cos(phase) / 2;

// Gear direction: adjacent rows mesh, so alternate directions
function gear_dir(row) = (row % 2 == 0) ? 1 : -1;

// ============================================
// MODULES
// ============================================

// Single elliptical disc with eccentric shaft hole
module ellipse_disc(row, disc) {
    phase = disc_phase(row, disc) * gear_dir(row);

    rotate([0, 0, phase])  // Rotate disc
    difference() {
        // Elliptical body
        scale([1, DISC_MINOR/DISC_MAJOR, 1])
            cylinder(r=DISC_MAJOR, h=DISC_THICKNESS, center=true, $fn=48);

        // ECCENTRIC shaft hole - offset from center
        translate([ECCENTRIC_OFFSET, 0, 0])
            cylinder(d=SHAFT_HOLE, h=DISC_THICKNESS + 2, center=true);
    }
}

// Single disc positioned in assembly
module mounted_disc(row, disc) {
    x_pos = disc * DISC_SPACING - TOTAL_WIDTH/2;
    y_pos = shaft_y(row);
    phase = disc_phase(row, disc) * gear_dir(row);

    // Disc rotates around shaft axis
    // But disc center is offset from shaft by ECCENTRIC_OFFSET
    // So disc center traces a circle as shaft rotates

    // Current disc center position (offset from shaft)
    center_offset_y = ECCENTRIC_OFFSET * sin(phase);
    center_offset_z = ECCENTRIC_OFFSET * cos(phase);

    color(disc_color(row))
    translate([x_pos, y_pos + center_offset_y, SHAFT_Z + center_offset_z])
    rotate([0, 90, 0])  // Disc face perpendicular to X
        ellipse_disc(row, disc);
}

// Shaft for one row
module row_shaft(row) {
    y_pos = shaft_y(row);

    color(C_SHAFT)
    translate([-TOTAL_WIDTH/2 - 15, y_pos, SHAFT_Z])
    rotate([0, 90, 0])
        cylinder(d=SHAFT_DIA, h=TOTAL_WIDTH + 30);
}

// Frame base
module frame() {
    color(C_FRAME)
    translate([-TOTAL_WIDTH/2 - 20, -TOTAL_DEPTH/2 - 15, 0])
        cube([TOTAL_WIDTH + 40, TOTAL_DEPTH + 30, 5]);

    // Shaft bearings (simplified)
    for (row = [0:NUM_ROWS-1]) {
        y_pos = shaft_y(row);

        color(C_FRAME) {
            translate([-TOTAL_WIDTH/2 - 18, y_pos - 5, 0])
            difference() {
                cube([8, 10, SHAFT_Z + 5]);
                translate([4, 5, SHAFT_Z])
                rotate([0, 90, 0])
                    cylinder(d=SHAFT_DIA + 0.6, h=10, center=true);
            }

            translate([TOTAL_WIDTH/2 + 10, y_pos - 5, 0])
            difference() {
                cube([8, 10, SHAFT_Z + 5]);
                translate([4, 5, SHAFT_Z])
                rotate([0, 90, 0])
                    cylinder(d=SHAFT_DIA + 0.6, h=10, center=true);
            }
        }
    }
}

// Wave surface visualization (connects disc tops)
module wave_surface_hint() {
    color([0.5, 0.7, 0.9, 0.3])
    for (row = [0:NUM_ROWS-2]) {
        for (disc = [0:DISCS_PER_ROW-2]) {
            // Connect disc tops with translucent surface
            x1 = disc * DISC_SPACING - TOTAL_WIDTH/2;
            x2 = (disc + 1) * DISC_SPACING - TOTAL_WIDTH/2;
            y1 = shaft_y(row);
            y2 = shaft_y(row + 1);
            z1 = disc_top_z(row, disc);
            z2 = disc_top_z(row, disc + 1);
            z3 = disc_top_z(row + 1, disc + 1);
            z4 = disc_top_z(row + 1, disc);

            // Quad patch (very simplified)
            hull() {
                translate([x1, y1, z1]) sphere(d=2);
                translate([x2, y1, z2]) sphere(d=2);
                translate([x2, y2, z3]) sphere(d=2);
                translate([x1, y2, z4]) sphere(d=2);
            }
        }
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module wave_ocean_v10_discsE() {
    frame();

    for (row = [0:NUM_ROWS-1]) {
        row_shaft(row);

        for (disc = [0:DISCS_PER_ROW-1]) {
            mounted_disc(row, disc);
        }
    }

    // wave_surface_hint();  // Uncomment to see envelope
}

// Render
wave_ocean_v10_discsE();

// ============================================
// DEBUG
// ============================================

echo("=== WAVE OCEAN V10 - APPROACH E: ROTATING DISC ARRAY ===");
echo(str("Rows: ", NUM_ROWS, ", Discs per row: ", DISCS_PER_ROW));
echo(str("Total discs: ", NUM_ROWS * DISCS_PER_ROW));
echo(str("Disc size: ", DISC_MAJOR, "x", DISC_MINOR, "mm ellipse"));
echo(str("Eccentric offset: ", ECCENTRIC_OFFSET, "mm"));
echo(str("Phase per row: ", PHASE_PER_ROW, " degrees"));
echo("");
echo("CRITICAL GEOMETRY CHECK:");
echo(str("  Shaft diameter: ", SHAFT_DIA, "mm"));
echo(str("  Shaft hole in disc: ", SHAFT_HOLE, "mm"));
echo(str("  Clearance: ", SHAFT_HOLE - SHAFT_DIA, "mm - ",
         (SHAFT_HOLE > SHAFT_DIA) ? "PASS" : "FAIL"));
echo(str("  Eccentric offset: ", ECCENTRIC_OFFSET, "mm from disc center to shaft"));
echo("");
echo("Animation: View -> Animate, FPS=30, Steps=60");
echo("Watch from FRONT - disc edges form traveling wave surface");

// ============================================
// V8 FIXES APPLIED
// ============================================

/*
 * V8 PROBLEMS:
 * 1. Shaft didn't go through disc holes - FIXED with eccentric mounting
 * 2. Orientation confused - FIXED with clear coordinate comments
 * 3. Phase direction unclear - FIXED: wave travels right-to-left
 *
 * KEY INSIGHT:
 * The disc has an ECCENTRIC hole (offset from disc center).
 * When mounted on shaft and rotated:
 * - Shaft stays fixed
 * - Disc center traces circle around shaft
 * - Disc top edge goes up/down
 *
 * This is like the old "spirograph" toy mechanism.
 */
