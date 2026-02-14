/*
 * 4:1 BLOCK-AND-TACKLE LINEAR ACTUATOR v1.0
 * ==========================================
 * Fully parametric 3D-printable distance multiplier.
 * 5 V-groove pulleys (3 fixed, 2 moving) achieve 4:1 ratio.
 * Pull 160mm of cable → shuttle moves 40mm (or vice versa).
 *
 * Standard: ISO 128 / DFAM (FDM, PLA, no supports)
 * Tolerance: ISO 2768-m (Medium)
 * Units: Millimeters
 *
 * MATH VERIFICATION:
 *   4 rope segments support moving block → 4:1 confirmed
 *   Min pulley clearance: 10.33mm at full stroke (req: >2mm)
 *   Cable efficiency: 0.95^5 = 77.4%
 *   Cable routing: Anchor(F2) → M1 → F1 → M2 → F3 → pull end
 *
 * PRINT: All parts FDM without supports at 0.2mm layer height.
 *   Base:    bottom down    |  Lid:    flip (top down)
 *   Shuttle: bottom down    |  Pulley: flat face down
 *
 * ANIMATION: View → Animate, FPS: 30, Steps: 120
 * STL EXPORT: Uncomment one module at bottom, F6 render.
 */

// ============================================
// QUALITY & ANIMATION
// ============================================

$fn = 48;

MANUAL_POSITION = -1;       // 0.0–1.0 for static debug, -1 for $t animation
stroke_t = (MANUAL_POSITION >= 0) ? MANUAL_POSITION : $t;

// ============================================
// PRINT TOLERANCES (mm)
// ============================================

TOL_GENERAL    = 0.2;       // Non-mating surfaces (ISO 2768-m)
TOL_SLIDING    = 0.3;       // Shaft-in-bore running fit
TOL_SLIDER_SIDE = 0.5;      // Rail-to-shuttle gap per side (0.3 EDS, 0.5 recommended FDM)
TOL_PULLEY_BORE = 0.6;      // Pulley bore diametral clearance
TOL_SNAP_HOLE  = 0.5;       // Snap-fit hole clearance

// ============================================
// CORE DIMENSIONS
// ============================================

HOUSING_LENGTH   = 120;     // X extent of base/lid plates
HOUSING_WIDTH    = 70;      // Y extent of base/lid plates
PLATE_THICKNESS  = 3;       // Floor and lid plate thickness

STROKE = 40;                // Shuttle linear travel
RATIO  = 4;                 // Mechanical advantage
CABLE_PULL = STROKE * RATIO; // = 160mm total cable needed

AXLE_DIA       = 4;         // Axle shaft diameter
AXLE_BOSS_H    = 7;         // Boss height above plate
AXLE_BOSS_OD   = 10;        // Boss outer diameter

PULLEY_OD      = 14;        // Pulley outer diameter
PULLEY_ID      = AXLE_DIA + TOL_PULLEY_BORE;  // = 4.6mm
PULLEY_WIDTH   = 5;         // Pulley thickness
GROOVE_ANGLE   = 90;        // V-groove included angle
GROOVE_DEPTH   = 3;         // V-groove radial depth

SHUTTLE_LENGTH  = 140;      // Shuttle X extent
SHUTTLE_WIDTH   = 16;       // Shuttle Y extent
SHUTTLE_THICK   = 3;        // Shuttle plate thickness

EYELET_BOSS_OD  = 12;       // Input eyelet boss diameter
EYELET_HOLE_DIA = 4;        // Eyelet through-hole

CABLE_DIA = 1.0;            // Visualization cable diameter

// ============================================
// AXLE POSITIONS
// ============================================

FIXED_AXLE_Y  = 12;         // Y-offset of fixed axle row from housing center
MOVING_AXLE_Y = -12;        // Y-offset of moving axle row (rail centerline)
Y_OFFSET = FIXED_AXLE_Y - MOVING_AXLE_Y;  // = 24mm

FIXED_AXLE_POS = [[-32, FIXED_AXLE_Y], [0, FIXED_AXLE_Y], [32, FIXED_AXLE_Y]];
MOVING_AXLE_OFFSETS = [-16, 16];  // M1, M2 relative to shuttle center

// ============================================
// SNAP-FIT DIMENSIONS
// ============================================

SNAP_STEM_DIA   = 5;        // Pin stem diameter
SNAP_HEAD_DIA   = 6.6;      // Pin head diameter
SNAP_UNDERCUT   = 45;       // Undercut angle (degrees)
SNAP_PIN_H      = 6;        // Total pin height above plate
SNAP_HOLE_DIA   = SNAP_STEM_DIA + TOL_SNAP_HOLE;  // = 5.5mm

SNAP_POSITIONS = [[54, 29], [54, -29], [-54, 29], [-54, -29]];

// ============================================
// RAIL CHANNEL
// ============================================

RAIL_LENGTH = 145;
RAIL_WIDTH  = SHUTTLE_WIDTH + 2 * TOL_SLIDER_SIDE;  // = 17.0mm default
RAIL_DEPTH  = 1;

// ============================================
// LID FEATURES
// ============================================

LID_AXLE_RECESS_DIA   = AXLE_DIA + 0.5;  // = 4.5mm (H7/g6 running)
LID_AXLE_RECESS_DEPTH = 2;
LID_SLOT_LENGTH = 100;      // Clearance slot X extent
LID_SLOT_WIDTH  = 6;        // Clearance slot Y extent

// ============================================
// MOUNTING
// ============================================

FLANGE_WIDTH     = 10;      // Side flange extension beyond housing
FLANGE_THICKNESS = PLATE_THICKNESS;
MOUNT_HOLE_DIA   = 3.2;     // M3 clearance

// ============================================
// COLORS
// ============================================

C_HOUSING = [0.85, 0.25, 0.25];   // Red
C_SHUTTLE = [0.25, 0.45, 0.85];   // Blue
C_PULLEY  = [0.6, 0.6, 0.65];     // Steel gray
C_CABLE   = [0.15, 0.15, 0.15];   // Near-black
C_SNAP    = [0.5, 0.35, 0.2];     // Bronze

// ============================================
// SHOW / HIDE TOGGLES
// ============================================

SHOW_BASE     = true;
SHOW_LID      = true;
SHOW_SHUTTLE  = true;
SHOW_PULLEYS  = true;
SHOW_CABLE    = true;
SHOW_SNAPS    = true;
SHOW_SECTION  = false;       // Section cut at Y=0
SHOW_EXPLODED = false;       // Exploded assembly view
EXPLODE_DIST  = 30;          // Explode gap (mm)

// ============================================
// HELPER FUNCTIONS
// ============================================

function shuttle_x(t) = -STROKE/2 + t * STROKE;

function cable_efficiency(n) = pow(0.95, n);

// Minimum edge-to-edge gap between any fixed and moving pulley at stroke position t
function min_clearance(t) =
    let(sx = shuttle_x(t),
        m1x = sx + MOVING_AXLE_OFFSETS[0],
        m2x = sx + MOVING_AXLE_OFFSETS[1],
        dists = [
            sqrt(pow(m1x - FIXED_AXLE_POS[0][0], 2) + pow(Y_OFFSET, 2)),
            sqrt(pow(m1x - FIXED_AXLE_POS[1][0], 2) + pow(Y_OFFSET, 2)),
            sqrt(pow(m1x - FIXED_AXLE_POS[2][0], 2) + pow(Y_OFFSET, 2)),
            sqrt(pow(m2x - FIXED_AXLE_POS[0][0], 2) + pow(Y_OFFSET, 2)),
            sqrt(pow(m2x - FIXED_AXLE_POS[1][0], 2) + pow(Y_OFFSET, 2)),
            sqrt(pow(m2x - FIXED_AXLE_POS[2][0], 2) + pow(Y_OFFSET, 2))
        ])
    min(dists) - PULLEY_OD;

// ============================================
// PRIMITIVE MODULES
// ============================================

// V-groove pulley wheel
module pulley_wheel(od=PULLEY_OD, id=PULLEY_ID, w=PULLEY_WIDTH,
                    groove_d=GROOVE_DEPTH) {
    // 90-deg V-groove cut into the circumference
    // Diamond (rotated square) swept around the pulley radius
    // The diamond center sits at the outer radius; its inward point
    // reaches groove_d into the pulley body.
    color(C_PULLEY)
    difference() {
        // Solid cylinder
        cylinder(d=od, h=w, center=true);
        // Central bore
        cylinder(d=id, h=w + 1, center=true);
        // V-groove: rotate_extrude a rotated square at the OD
        // A centered square of side s rotated 45 deg has half-diagonal = s*sqrt(2)/2.
        // We need half-diagonal = groove_d, so s = groove_d * sqrt(2).
        rotate_extrude($fn=$fn)
            translate([od/2, 0])
                rotate([0, 0, 45])
                    square(groove_d * sqrt(2), center=true);
    }
}

// Axle boss (cylinder rising from plate surface)
module axle_boss(dia=AXLE_DIA, h=AXLE_BOSS_H, od=AXLE_BOSS_OD) {
    union() {
        cylinder(d=od, h=h);
        // Fillet ring at base for strength
        cylinder(d1=od + 2, d2=od, h=1.5);
    }
}

// Snap-fit male pin with asymmetric ramp (70% entry, 30% retention)
module snap_fit_male(stem_d=SNAP_STEM_DIA, head_d=SNAP_HEAD_DIA,
                     undercut=SNAP_UNDERCUT, pin_h=SNAP_PIN_H) {
    overhang = (head_d - stem_d) / 2;            // 0.8mm
    ramp_h = overhang / tan(undercut);            // 0.8mm at 45 deg
    entry_h = ramp_h * 0.7;                       // Gradual entry
    retain_h = ramp_h * 0.3;                      // Retention shoulder
    straight_h = pin_h - ramp_h;                  // Stem below ramp

    color(C_SNAP)
    union() {
        // Straight stem
        cylinder(d=stem_d, h=straight_h);
        // Entry ramp (gradual taper out)
        translate([0, 0, straight_h])
            cylinder(d1=stem_d, d2=head_d, h=entry_h);
        // Retention shoulder (steep return)
        translate([0, 0, straight_h + entry_h])
            cylinder(d1=head_d, d2=stem_d, h=retain_h);
    }
}

// Snap-fit female hole (counterbored with entry chamfer)
module snap_fit_female(hole_d=SNAP_HOLE_DIA, depth=10, chamfer=0.5) {
    union() {
        cylinder(d=hole_d, h=depth + 0.1);
        // Entry chamfer
        translate([0, 0, depth - chamfer])
            cylinder(d1=hole_d, d2=hole_d + chamfer * 2, h=chamfer + 0.1);
    }
}

// Cable segment between two 3D points
module cable_segment(p1, p2, dia=CABLE_DIA) {
    color(C_CABLE)
    hull() {
        translate(p1) sphere(d=dia, $fn=12);
        translate(p2) sphere(d=dia, $fn=12);
    }
}

// ============================================
// COMPONENT 1: HOUSING BASE (Red Frame)
// ============================================

module housing_base() {
    // Z-plane for groove (pulley midplane height above base top surface)
    color(C_HOUSING)
    difference() {
        union() {
            // Floor plate
            translate([-HOUSING_LENGTH/2, -HOUSING_WIDTH/2, 0])
                cube([HOUSING_LENGTH, HOUSING_WIDTH, PLATE_THICKNESS]);

            // Side flanges for M3 mounting (extend outward from housing)
            // Positive Y flange
            translate([-HOUSING_LENGTH/2, HOUSING_WIDTH/2, 0])
                cube([HOUSING_LENGTH, FLANGE_WIDTH, FLANGE_THICKNESS]);
            // Negative Y flange
            translate([-HOUSING_LENGTH/2, -HOUSING_WIDTH/2 - FLANGE_WIDTH, 0])
                cube([HOUSING_LENGTH, FLANGE_WIDTH, FLANGE_THICKNESS]);

            // 3 fixed axle bosses
            for (pos = FIXED_AXLE_POS)
                translate([pos[0], pos[1], PLATE_THICKNESS])
                    axle_boss();

            // 4 snap-fit male pins
            if (SHOW_SNAPS)
                for (pos = SNAP_POSITIONS)
                    translate([pos[0], pos[1], PLATE_THICKNESS])
                        snap_fit_male();
        }

        // Rail channel (recessed into top of floor plate)
        translate([-RAIL_LENGTH/2, MOVING_AXLE_Y - RAIL_WIDTH/2,
                   PLATE_THICKNESS - RAIL_DEPTH])
            cube([RAIL_LENGTH, RAIL_WIDTH, RAIL_DEPTH + 0.1]);

        // M3 mounting holes in flanges (2 per side, inset 15mm from ends)
        for (side = [-1, 1])
            for (xoff = [-HOUSING_LENGTH/2 + 15, HOUSING_LENGTH/2 - 15])
                translate([xoff,
                           side * (HOUSING_WIDTH/2 + FLANGE_WIDTH/2),
                           -0.1])
                    cylinder(d=MOUNT_HOLE_DIA, h=FLANGE_THICKNESS + 0.2);
    }
}

// ============================================
// COMPONENT 2: HOUSING LID (Red Frame)
// ============================================

module housing_lid() {
    color(C_HOUSING, 0.7)
    difference() {
        // Lid plate
        translate([-HOUSING_LENGTH/2, -HOUSING_WIDTH/2, 0])
            cube([HOUSING_LENGTH, HOUSING_WIDTH, PLATE_THICKNESS]);

        // 4 snap-fit female holes at corners
        for (pos = SNAP_POSITIONS)
            translate([pos[0], pos[1], -0.1])
                snap_fit_female(depth=PLATE_THICKNESS + 0.2);

        // 3 axle recesses (blind holes for axle tips)
        for (pos = FIXED_AXLE_POS)
            translate([pos[0], pos[1], -0.1])
                cylinder(d=LID_AXLE_RECESS_DIA,
                         h=LID_AXLE_RECESS_DEPTH + 0.1);

        // Clearance slot for moving shuttle axles
        translate([-LID_SLOT_LENGTH/2,
                   MOVING_AXLE_Y - LID_SLOT_WIDTH/2, -0.1])
            cube([LID_SLOT_LENGTH, LID_SLOT_WIDTH,
                  PLATE_THICKNESS + 0.2]);
    }
}

// ============================================
// COMPONENT 3: SHUTTLE (Blue Slider)
// ============================================

module shuttle() {
    color(C_SHUTTLE)
    difference() {
        union() {
            // Main slab
            translate([-SHUTTLE_LENGTH/2, -SHUTTLE_WIDTH/2, 0])
                cube([SHUTTLE_LENGTH, SHUTTLE_WIDTH, SHUTTLE_THICK]);

            // 2 moving axle bosses
            for (xoff = MOVING_AXLE_OFFSETS)
                translate([xoff, 0, SHUTTLE_THICK])
                    axle_boss();

            // Input eyelet boss at left end
            translate([-SHUTTLE_LENGTH/2, 0, 0])
                cylinder(d=EYELET_BOSS_OD, h=SHUTTLE_THICK);
        }

        // Eyelet through-hole for cable attachment
        translate([-SHUTTLE_LENGTH/2, 0, -0.1])
            cylinder(d=EYELET_HOLE_DIA, h=SHUTTLE_THICK + 0.2);

        // Chamfer leading/trailing edges (0.5mm 45-deg bevel)
        for (xend = [-1, 1])
            translate([xend * SHUTTLE_LENGTH/2 + (xend > 0 ? 0 : -1),
                       -SHUTTLE_WIDTH/2 - 0.1, -0.1])
                cube([1, SHUTTLE_WIDTH + 0.2, 0.5]);
    }
}

// ============================================
// COMPONENT 4: PULLEY SET
// ============================================

// Z-heights for pulley midplanes
// Fixed bosses start at PLATE_THICKNESS, rise AXLE_BOSS_H
FIXED_PULLEY_Z  = PLATE_THICKNESS + AXLE_BOSS_H / 2;
// Moving bosses start at shuttle top: (PLATE_THICKNESS - RAIL_DEPTH) + SHUTTLE_THICK
SHUTTLE_TOP_Z   = PLATE_THICKNESS - RAIL_DEPTH + SHUTTLE_THICK;
MOVING_PULLEY_Z = SHUTTLE_TOP_Z + AXLE_BOSS_H / 2;

module fixed_pulleys() {
    for (pos = FIXED_AXLE_POS)
        translate([pos[0], pos[1], FIXED_PULLEY_Z])
            pulley_wheel();
}

module moving_pulleys(t) {
    sx = shuttle_x(t);
    for (xoff = MOVING_AXLE_OFFSETS)
        translate([sx + xoff, MOVING_AXLE_Y, MOVING_PULLEY_Z])
            pulley_wheel();
}

// ============================================
// CABLE PATH MODULE
// ============================================

module cable_path(t) {
    sx = shuttle_x(t);

    // Fixed pulley centers (at their groove midplane)
    f1 = [FIXED_AXLE_POS[0][0], FIXED_AXLE_POS[0][1], FIXED_PULLEY_Z];
    f2 = [FIXED_AXLE_POS[1][0], FIXED_AXLE_POS[1][1], FIXED_PULLEY_Z];
    f3 = [FIXED_AXLE_POS[2][0], FIXED_AXLE_POS[2][1], FIXED_PULLEY_Z];

    // Moving pulley centers (slightly higher due to shuttle riding in channel)
    m1 = [sx + MOVING_AXLE_OFFSETS[0], MOVING_AXLE_Y, MOVING_PULLEY_Z];
    m2 = [sx + MOVING_AXLE_OFFSETS[1], MOVING_AXLE_Y, MOVING_PULLEY_Z];

    // Anchor point: fixed to frame near F2, above the pulley
    anchor = [f2[0], f2[1], FIXED_PULLEY_Z + PULLEY_WIDTH];

    // Pull end: exits right of F3
    pull_end = [f3[0] + 25, f3[1], FIXED_PULLEY_Z];

    // Cable routing: Anchor → M1 → F1 → M2 → F3 → pull end
    // (F2 is anchor mount, F1 and F3 are active redirects = symmetric)
    cable_segment(anchor, m1);         // Segment 1: anchor down to M1
    cable_segment(m1, f1);             // Segment 2: M1 up to F1
    cable_segment(f1, m2);             // Segment 3: F1 down to M2
    cable_segment(m2, f3);             // Segment 4: M2 up to F3
    cable_segment(f3, pull_end);       // Free end: F3 to pull exit

    // Visual: small sphere at anchor point
    color(C_CABLE)
    translate(anchor) sphere(d=2, $fn=12);
}

// ============================================
// ASSEMBLY MODULE
// ============================================

module assembly(t=0.5, exploded=false) {
    exp_base = 0;
    exp_lid  = exploded ? EXPLODE_DIST : 0;
    exp_shut = 0;

    // Lid sits above the tallest bosses (moving axle bosses are higher)
    moving_boss_top = PLATE_THICKNESS - RAIL_DEPTH + SHUTTLE_THICK + AXLE_BOSS_H;
    lid_z = moving_boss_top + 0.5;  // 0.5mm clearance above boss tops

    // Housing base
    if (SHOW_BASE)
        housing_base();

    // Shuttle (rides in rail channel)
    if (SHOW_SHUTTLE)
        translate([shuttle_x(t), MOVING_AXLE_Y,
                   PLATE_THICKNESS - RAIL_DEPTH])
            shuttle();

    // Fixed pulleys
    if (SHOW_PULLEYS)
        fixed_pulleys();

    // Moving pulleys
    if (SHOW_PULLEYS)
        moving_pulleys(t);

    // Cable path
    if (SHOW_CABLE)
        cable_path(t);

    // Housing lid
    if (SHOW_LID)
        translate([0, 0, lid_z + exp_lid])
            housing_lid();
}

// Section view: cut assembly at Y=0 to reveal internals
module section_view(t=0.5) {
    intersection() {
        assembly(t);
        // Keep only Y < 0 half (shows rail channel cross-section)
        translate([-200, -200, -10])
            cube([400, 200, 100]);
    }
}

// ============================================
// CALIBRATION TEST PIECES
// ============================================

// Print this first to verify slider-to-rail fit
module calibration_rail_test() {
    test_len = 30;

    // Rail segment
    color(C_HOUSING)
    difference() {
        translate([-test_len/2, -15, 0])
            cube([test_len, 30, PLATE_THICKNESS]);
        // Channel
        translate([-test_len/2 - 0.1,
                   -RAIL_WIDTH/2,
                   PLATE_THICKNESS - RAIL_DEPTH])
            cube([test_len + 0.2, RAIL_WIDTH, RAIL_DEPTH + 0.1]);
    }

    // Shuttle strip (offset for separate printing)
    color(C_SHUTTLE)
    translate([0, 25, 0])
        translate([-test_len/2, -SHUTTLE_WIDTH/2, 0])
            cube([test_len, SHUTTLE_WIDTH, SHUTTLE_THICK]);

    echo("CALIBRATION: Rail test piece");
    echo(str("  Rail width: ", RAIL_WIDTH, "mm (gap: ",
             TOL_SLIDER_SIDE, "mm/side)"));
    echo(str("  Shuttle width: ", SHUTTLE_WIDTH, "mm"));
    echo("  Shuttle should slide freely with minimal wobble.");
}

// Print this to verify pulley rotation
module calibration_pulley_axle_test() {
    // Single axle boss
    color(C_HOUSING)
    union() {
        translate([0, 0, 0])
            cube([20, 20, PLATE_THICKNESS], center=true);
        translate([0, 0, PLATE_THICKNESS/2])
            axle_boss();
    }

    // Pulley (offset for separate printing)
    color(C_PULLEY)
    translate([30, 0, PULLEY_WIDTH/2])
        pulley_wheel();

    echo("CALIBRATION: Pulley-axle test piece");
    echo(str("  Axle OD: ", AXLE_DIA, "mm  |  Pulley bore: ",
             PULLEY_ID, "mm  |  Gap: ", TOL_PULLEY_BORE, "mm"));
    echo("  Pulley should spin freely on axle boss.");
}

// ============================================
// ECHO VERIFICATION BLOCK
// ============================================

echo("================================================================");
echo("  4:1 BLOCK-AND-TACKLE LINEAR ACTUATOR v1.0");
echo("================================================================");
echo(str("Housing: ", HOUSING_LENGTH, " x ", HOUSING_WIDTH, " x ",
         PLATE_THICKNESS, "mm"));
echo(str("Shuttle: ", SHUTTLE_LENGTH, " x ", SHUTTLE_WIDTH, " x ",
         SHUTTLE_THICK, "mm"));
echo(str("Stroke: ", STROKE, "mm  |  Cable pull: ", CABLE_PULL, "mm"));
echo(str("Ratio: ", RATIO, ":1  |  Efficiency: ",
         round(cable_efficiency(5) * 1000) / 10, "%"));
echo(str("Pulleys: 5 total (3 fixed, 2 moving)  |  OD: ",
         PULLEY_OD, "mm  |  Bore: ", PULLEY_ID, "mm"));
echo(str("Rail channel: ", RAIL_LENGTH, " x ", RAIL_WIDTH,
         "mm (gap: ", TOL_SLIDER_SIDE, "mm/side)"));
echo(str("Min clearance at full stroke: ",
         round(min_clearance(0) * 10) / 10, "mm (req: >2mm)"));
echo(str("Min clearance at center: ",
         round(min_clearance(0.5) * 10) / 10, "mm"));
echo(str("Y-offset (fixed to moving): ", Y_OFFSET, "mm"));
echo(str("Fixed pulley Z: ", FIXED_PULLEY_Z, "mm  |  Moving pulley Z: ",
         MOVING_PULLEY_Z, "mm  (delta: ", MOVING_PULLEY_Z - FIXED_PULLEY_Z, "mm)"));
echo("");
echo("PRINT ORIENTATION (all no-support FDM at 0.2mm layers):");
echo("  Housing Base:  Bottom face down");
echo("  Housing Lid:   Flip (top face down)");
echo("  Shuttle:       Bottom face down");
echo("  Pulley (x5):   Flat face down, axle vertical");
echo("");
echo("TIP: Print calibration_rail_test() first!");
echo("================================================================");

// ============================================
// DEFAULT RENDER
// ============================================

if (SHOW_SECTION) {
    section_view(stroke_t);
} else {
    assembly(stroke_t, SHOW_EXPLODED);
}

// ============================================
// STL EXPORT (uncomment ONE, then F6 render)
// ============================================
// housing_base();
// housing_lid();
// shuttle();
// pulley_wheel();
// calibration_rail_test();
// calibration_pulley_axle_test();
