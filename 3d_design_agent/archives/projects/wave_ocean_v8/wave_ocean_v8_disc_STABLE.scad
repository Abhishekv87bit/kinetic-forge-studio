/*
 * WAVE OCEAN v8 - VIRTUAL CREST ILLUSION
 * Following the spec exactly from the plan document
 */

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;  // 0-360 for static, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// MODE TOGGLES
// ============================================

PHASE_MODE = "offset";        // "in_phase" or "offset"
PHASE_OFFSET_PER_ROW = 15;    // degrees

STAGGER_MODE = "stagger";     // "sync", "stagger", "random"
STAGGER_PER_DISC = 10;        // degrees

// ============================================
// VISIBILITY TOGGLES
// ============================================

SHOW_DISCS = true;
SHOW_SHAFTS = true;
SHOW_GEARS = true;
SHOW_FOAM = true;

// ============================================
// LAYOUT PARAMETERS
// ============================================

NUM_ROWS = 6;
DISCS_PER_ROW = 8;
DISC_SPACING = 20;
FIRST_DISC_X = 20;
DISC_THICKNESS = 3;
SHAFT_HOLE = 4.2;

SHAFT_DIAMETER = 4;
SHAFT_LENGTH = 200;

ROW_SPACING = 18;  // Y distance between rows

GEAR_MODULE = 1.5;
GEAR_TEETH = 12;
GEAR_THICKNESS = 6;
GEAR_PITCH_DIA = GEAR_MODULE * GEAR_TEETH;  // 18mm

// ============================================
// DISC SHAPE FUNCTIONS (from spec)
// ============================================

function disc_long_axis(row) =
    row == 6 ? 12 :  // small circular
    row == 5 ? 13 :  // medium circular
    row == 4 ? 14 :  // slight oval
    row == 3 ? 15 :  // elliptical
    row == 2 ? 16 :  // tall ellipse
    16;              // row 1: tall (foam added separately)

function disc_short_axis(row) =
    row == 6 ? 12 :  // circular (1:1)
    row == 5 ? 12 :  // circular
    row == 4 ? 11 :  // slight oval (14:11)
    row == 3 ? 10 :  // elliptical (15:10 = 1.5:1)
    row == 2 ? 9 :   // tall (16:9)
    9;               // row 1: tall

function disc_eccentricity(row) =
    row == 6 ? 2 :
    row == 5 ? 3 :
    row == 4 ? 4 :
    row == 3 ? 5 :
    row == 2 ? 6 :
    7;               // row 1

// Colors - gradient from deep blue to light foam
function disc_color(row) =
    row == 6 ? [0.05, 0.15, 0.4] :   // Deep ocean
    row == 5 ? [0.1, 0.25, 0.5] :
    row == 4 ? [0.15, 0.35, 0.6] :
    row == 3 ? [0.2, 0.45, 0.7] :
    row == 2 ? [0.3, 0.55, 0.8] :
    [0.5, 0.75, 0.9];                // Breaking wave

// ============================================
// PHASE FUNCTIONS (from spec)
// ============================================

// Gear direction alternates (meshing gears)
function gear_direction(row) = (row % 2 == 0) ? 1 : -1;

// Row phase offset - front rows LEAD back rows
function row_phase_offset(row) =
    PHASE_MODE == "in_phase" ? 0 :
    (6 - row) * PHASE_OFFSET_PER_ROW;  // Row 1 leads by 75°

// Disc stagger within row
function disc_stagger(disc_index) =
    STAGGER_MODE == "sync" ? 0 :
    STAGGER_MODE == "stagger" ? disc_index * STAGGER_PER_DISC :
    ((disc_index * 37 + 13) % 60) - 30;  // random

// Master phase function (from spec)
function disc_phase(row, disc_index) =
    theta * gear_direction(row)
    + row_phase_offset(row) * gear_direction(row)
    + disc_stagger(disc_index) * gear_direction(row);

// ============================================
// DISC MODULE
// ============================================

module ellipse_disc(row) {
    long = disc_long_axis(row);
    short = disc_short_axis(row);
    ecc = disc_eccentricity(row);

    color(disc_color(row))
    difference() {
        // Ellipse body
        scale([1, short/long, 1])
            cylinder(h=DISC_THICKNESS, d=long, center=true, $fn=48);
        // Eccentric hole
        translate([ecc, 0, 0])
            cylinder(h=DISC_THICKNESS+2, d=SHAFT_HOLE, center=true, $fn=24);
    }
}

// ============================================
// FOAM CURL MODULE (Row 1 only)
// ============================================

module foam_curl() {
    ecc = disc_eccentricity(1);
    color([0.9, 0.95, 1.0])
    // Faces toward Row 2 (ocean side = +Y)
    translate([ecc, 4, 0])
        rotate([0, 0, 0])
            scale([1, 0.6, 1])
                difference() {
                    cylinder(h=DISC_THICKNESS, d=8, center=true, $fn=24);
                    translate([2, 0, 0])
                        cylinder(h=DISC_THICKNESS+2, d=6, center=true, $fn=24);
                }
}

// ============================================
// MOUNTED DISC (on rotating shaft)
// ============================================

module mounted_disc(row, phase_angle) {
    ecc = disc_eccentricity(row);

    // Rotate disc around shaft axis (X-axis)
    rotate([phase_angle, 0, 0])
        // Offset so eccentric hole sits on shaft centerline
        translate([0, 0, -ecc])
            // Orient disc perpendicular to shaft (hole along X)
            rotate([0, 90, 0]) {
                ellipse_disc(row);
                if (row == 1 && SHOW_FOAM)
                    foam_curl();
            }
}

// ============================================
// SHAFT
// ============================================

module shaft_rod() {
    color([0.5, 0.5, 0.5])
    rotate([0, 90, 0])
        cylinder(d=SHAFT_DIAMETER, h=SHAFT_LENGTH, $fn=24);
}

// ============================================
// GEAR (simple visual)
// ============================================

module spur_gear() {
    color([0.6, 0.4, 0.2])
    difference() {
        cylinder(h=GEAR_THICKNESS, d=GEAR_PITCH_DIA, center=true, $fn=GEAR_TEETH*4);
        cylinder(h=GEAR_THICKNESS+2, d=SHAFT_DIAMETER+0.2, center=true, $fn=24);
    }
}

// ============================================
// CAMSHAFT ROW
// ============================================

module camshaft_row(row) {
    // Y position: Row 6 at back (high Y), Row 1 at front (low Y)
    y_pos = (6 - row) * ROW_SPACING;

    translate([0, y_pos, 0]) {
        // Shaft
        if (SHOW_SHAFTS)
            shaft_rod();

        // Discs
        if (SHOW_DISCS)
            for (i = [0:DISCS_PER_ROW-1]) {
                x_pos = FIRST_DISC_X + i * DISC_SPACING;
                phase = disc_phase(row, i);
                translate([x_pos, 0, 0])
                    mounted_disc(row, phase);
            }

        // Gear at right end
        if (SHOW_GEARS)
            translate([SHAFT_LENGTH + 5, 0, 0])
                rotate([0, 90, 0])
                    rotate([0, 0, theta * gear_direction(row)])
                        spur_gear();
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module wave_ocean_v8() {
    for (row = [1:NUM_ROWS]) {
        camshaft_row(row);
    }
}

// Render at Z=40 so discs have room to move
translate([0, 0, 40])
    wave_ocean_v8();

// ============================================
// DEBUG
// ============================================

echo("=== WAVE OCEAN v8 ===");
echo(str("PHASE_MODE: ", PHASE_MODE));
echo(str("STAGGER_MODE: ", STAGGER_MODE));
echo("");
echo("Row positions (Y) and disc specs:");
for (r = [1:6]) {
    y = (6 - r) * ROW_SPACING;
    echo(str("  Row ", r, ": Y=", y, "mm, disc=", disc_long_axis(r), "x", disc_short_axis(r), "mm, ecc=", disc_eccentricity(r), "mm"));
}
