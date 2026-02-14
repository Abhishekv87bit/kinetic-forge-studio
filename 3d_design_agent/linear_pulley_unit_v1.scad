/*
 * SINGLE-CHANNEL LINEAR PULLEY UNIT v1.0
 * =======================================
 * One channel of Reuben Margolin's Triple Helix cable-slider matrix.
 * Fixed stator with top/bottom pulley banks + moving slider with
 * interleaved pulleys. Serpentine string routing creates mechanical
 * advantage and converts horizontal slider motion to vertical string
 * displacement for hanging blocks.
 *
 * MECHANISM:
 * Helix Push-Rod → Slider Bar (horizontal reciprocation)
 * → Serpentine String through Fixed + Slider Pulleys
 * → Vertical string length change → Block rises/falls
 *
 * STRING ROUTING (serpentine):
 * Anchor → TF[0] → S[0] → BF[0] → S[1] → TF[1] → S[2] → BF[1]
 * → S[3] → TF[2] → S[4] → BF[2] → S[5] → TF[3] → S[6] → BF[3]
 * → Anchor
 * (TF=Top Fixed, BF=Bottom Fixed, S=Slider)
 *
 * POWER PATH:
 * Single motor → helix shaft → push-rod → THIS UNIT → strings → blocks
 * This is ONE of ~33 channels in the full Triple Helix matrix.
 *
 * PRINT: All parts FDM without supports at 0.2mm layer height.
 *   Stator Plate:  flat on bed (XY)  |  Slider Bar: flat on bed (XY)
 *   Pulley:        flat face down     |  Standoff:   upright
 *
 * ANIMATION: View → Animate, FPS: 30, Steps: 120
 * STL EXPORT: Uncomment one module at bottom, F6 render.
 *
 * Units: Millimeters
 * Standard: ISO 128 / DFAM (FDM, PLA/PETG, no supports)
 * Tolerance: ISO 2768-m (Medium)
 */

// ============================================
// QUALITY & ANIMATION
// ============================================

$fn = 48;

MANUAL_POSITION = -1;       // 0.0-1.0 for static debug, -1 for $t animation
stroke_t = (MANUAL_POSITION >= 0) ? MANUAL_POSITION : $t;

// ============================================
// PRINT TOLERANCES (mm)
// ============================================

TOL_GENERAL     = 0.2;     // Non-mating surfaces (ISO 2768-m)
TOL_SLIDING     = 0.3;     // Shaft-in-bore running fit
TOL_SLIDER_RAIL = 0.25;    // Slider bar to guide bearing clearance per side
TOL_PULLEY_BORE = 0.4;     // Pulley bore diametral clearance on shaft
TOL_PLATE_GAP   = 0.3;     // Extra clearance for slider in plate gap

// ============================================
// CORE DIMENSIONS: STATOR (Fixed Assembly)
// ============================================

PLATE_WIDTH     = 300;      // mm — X extent (horizontal)
PLATE_HEIGHT    = 120;      // mm — Z extent (vertical)
PLATE_THICK     = 6;        // mm — acrylic wall thickness
PLATE_GAP       = 15;       // mm — gap between two walls (Y direction)

// Standoffs holding plates apart
STANDOFF_DIA    = 8;        // mm — outer diameter
STANDOFF_BORE   = 4;        // mm — M4 through-bolt
STANDOFF_COUNT  = 6;        // 3 top edge, 3 bottom edge

// Corner mounting holes
CORNER_HOLE_DIA = 3.2;      // mm — M3 clearance for wall/frame mount
CORNER_INSET    = 10;       // mm — from plate edges

// ============================================
// CORE DIMENSIONS: STADIUM CUTOUT
// ============================================

// Stadium cutout — large central opening for weight reduction and slider clearance.
// Must clear the slider pulleys but NOT cut through bearing or pulley bank mounting areas.
// The stadium sits between the fixed pulley banks and between the bearing rows.
// Bearings mount on shaft holes OUTSIDE the stadium (in solid plate above/below).
STADIUM_CENTER_Z = 60;      // mm — vertical center of stadium in plate
STADIUM_HEIGHT  = 60;       // mm — pill-shape Z extent (clears between bearing rows)
STADIUM_RADIUS  = 30;       // mm — end-cap radius (= STADIUM_HEIGHT/2)
STADIUM_LENGTH  = 240;      // mm — pill-shape X extent

// ============================================
// CORE DIMENSIONS: FIXED PULLEY BANKS
// ============================================

NUM_FIXED_TOP      = 8;     // pulleys in top bank
NUM_FIXED_BOTTOM   = 8;     // pulleys in bottom bank
FIXED_PULLEY_DIA   = 12;    // mm — nylon pulley outer diameter
FIXED_PULLEY_THICK = 5;     // mm — pulley width
FIXED_PULLEY_BORE  = 3;     // mm — shaft diameter
GROOVE_DEPTH       = 2;     // mm — V-groove radial depth

PULLEY_SPACING     = 28;    // mm — center-to-center X spacing

// Vertical positions (Z from plate bottom)
TOP_BANK_Z    = PLATE_HEIGHT - 12;   // mm — top pulley bank centerline
BOTTOM_BANK_Z = 12;                   // mm — bottom pulley bank centerline

// Shaft spanning the gap
SHAFT_DIA       = 3;        // mm — polished steel shaft

// ============================================
// CORE DIMENSIONS: GUIDE BEARINGS
// ============================================

BEARING_OD      = 10;       // mm — steel ball bearing outer diameter
BEARING_THICK   = 4;        // mm — bearing width
BEARING_SHAFT   = 3;        // mm — bearing axle

// Bearing Z positions — per user spec: "just below Top Bank, just above Bottom Bank"
// Bearings pinch the slider bar's top and bottom edges.
// Top bearing pair: just below top pulley bank
BEARING_TOP_Z    = TOP_BANK_Z - FIXED_PULLEY_DIA / 2 - BEARING_OD / 2 - 2;
// Bottom bearing pair: just above bottom pulley bank
BEARING_BOTTOM_Z = BOTTOM_BANK_Z + FIXED_PULLEY_DIA / 2 + BEARING_OD / 2 + 2;

// Bearing X positions — two per row, near edges of slider travel
BEARING_X_INSET = 20;       // mm from plate edge

// ============================================
// CORE DIMENSIONS: SLIDER (Moving Assembly)
// ============================================

SLIDER_LENGTH    = 400;     // mm — total X length (extends past stator)
// Slider height is derived: it spans between the bearing rows
// Top bearing center Z=95, Bottom bearing center Z=25
// Slider edges contact the bearings, so slider Z extent = bearing-to-bearing
// Actual value computed in DERIVED GEOMETRY section below
SLIDER_THICK     = 10;      // mm — Y extent (fits in PLATE_GAP with clearance)
SLIDER_EXTENSION = 50;      // mm — overhang past stator left edge

// Push-rod mounting hole
MOUNT_HOLE_DIA   = 5;       // mm — for helix push-rod pin
MOUNT_HOLE_INSET = 25;      // mm — from left end of slider

// ============================================
// CORE DIMENSIONS: SLIDER PULLEYS
// ============================================

NUM_SLIDER_PULLEYS    = 7;
SLIDER_PULLEY_DIA     = 12;    // mm — same as fixed
SLIDER_PULLEY_THICK   = 5;     // mm
SLIDER_PULLEY_BORE    = 3;     // mm

// ============================================
// CORE DIMENSIONS: ANIMATION & STROKE
// ============================================

SLIDER_STROKE   = 60;       // mm — total left/right travel

// Sinusoidal motion (matches helix-driven push-rod)
slider_x_offset = SLIDER_STROKE / 2 * sin(stroke_t * 360);

// ============================================
// CORE DIMENSIONS: STRING
// ============================================

STRING_DIA = 0.8;           // mm — visual thickness (Dacron)

// ============================================
// SCALE FACTOR (for 3D printing on smaller beds)
// ============================================

SCALE_FACTOR = 1.0;         // 1.0=full size, 0.6=fits 220mm bed

// ============================================
// SHOW / HIDE TOGGLES
// ============================================

SHOW_STATOR    = true;      // Plates, standoffs
SHOW_SLIDER    = true;      // Slider bar
SHOW_PULLEYS   = true;      // All pulleys (fixed + slider)
SHOW_BEARINGS  = true;      // Guide bearings
SHOW_STRINGS   = true;      // Serpentine string path
SHOW_SHAFTS    = true;      // Pulley axle shafts
SHOW_SECTION   = false;     // XZ section cut at Y=0
SHOW_EXPLODED  = false;     // Explode stator plates apart
EXPLODE_DIST   = 30;        // mm — explode gap per plate

// ============================================
// COLOR PALETTE (Margolin-Accurate Materials)
// ============================================

C_ACRYLIC     = [0.80, 0.82, 0.85, 0.30];   // Transparent acrylic
C_ACRYLIC_BAR = [0.75, 0.78, 0.82, 0.40];   // Slightly denser acrylic
C_NYLON       = [0.92, 0.92, 0.90, 1.00];   // White nylon pulleys
C_STEEL       = [0.65, 0.65, 0.68, 1.00];   // Polished steel shafts
C_BEARING     = [0.55, 0.55, 0.60, 1.00];   // Steel ball bearings
C_STANDOFF    = [0.70, 0.70, 0.72, 1.00];   // Metal standoffs
C_STRING      = [0.15, 0.15, 0.15, 1.00];   // Near-black string
C_MOUNT       = [0.40, 0.40, 0.45, 1.00];   // Dark steel mounting

// ============================================
// DERIVED GEOMETRY (computed, do not edit)
// ============================================

// Slider vertical center (between bearings) — this is where the slider sits
SLIDER_CENTER_Z = (BEARING_TOP_Z + BEARING_BOTTOM_Z) / 2;

// Slider height: spans from bottom bearing contact to top bearing contact
// The bearings contact the slider's top/bottom edges, so:
SLIDER_HEIGHT = BEARING_TOP_Z - BEARING_BOTTOM_Z;  // ~70mm

// Fixed pulley X positions (centered on stator)
function fixed_pulley_x(i, count) =
    -((count - 1) / 2) * PULLEY_SPACING + i * PULLEY_SPACING;

// Slider pulley X positions — offset by half-spacing for interleaving
function slider_pulley_x(j) =
    fixed_pulley_x(0, NUM_FIXED_TOP) + PULLEY_SPACING / 2
    + j * PULLEY_SPACING;

// Standoff X positions (3 per edge, evenly spaced)
function standoff_x(i) =
    -PLATE_WIDTH / 2 + CORNER_INSET + 15
    + i * ((PLATE_WIDTH - 2 * CORNER_INSET - 30) / 2);

// ============================================
// PRIMITIVE MODULES
// ============================================

// 2D stadium (pill shape) — used for plate cutout
module stadium_2d(length, height) {
    r = height / 2;
    hull() {
        translate([-(length / 2 - r), 0]) circle(r = r);
        translate([ (length / 2 - r), 0]) circle(r = r);
    }
}

// V-groove nylon pulley
module pulley_wheel(od = FIXED_PULLEY_DIA, thick = FIXED_PULLEY_THICK,
                    bore = FIXED_PULLEY_BORE, groove_d = GROOVE_DEPTH) {
    bore_d = bore + TOL_PULLEY_BORE;
    color(C_NYLON)
    difference() {
        // Solid disc
        cylinder(d = od, h = thick, center = true);
        // Central bore
        cylinder(d = bore_d, h = thick + 1, center = true);
        // V-groove: rotate_extrude a diamond at the OD
        rotate_extrude($fn = $fn)
            translate([od / 2, 0])
                rotate([0, 0, 45])
                    square(groove_d * sqrt(2), center = true);
    }
}

// Metal standoff between plates
module standoff_post(length = PLATE_GAP, od = STANDOFF_DIA,
                     bore = STANDOFF_BORE) {
    color(C_STANDOFF)
    difference() {
        cylinder(d = od, h = length);
        translate([0, 0, -0.1])
            cylinder(d = bore, h = length + 0.2);
    }
}

// Steel ball bearing (visual, axis in Y direction)
module guide_bearing(od = BEARING_OD, thick = BEARING_THICK) {
    color(C_BEARING)
    rotate([-90, 0, 0])
        cylinder(d = od, h = thick, center = true);
}

// Shaft spanning the plate gap (Y direction)
module spanning_shaft(length = PLATE_GAP + 2 * PLATE_THICK,
                      dia = SHAFT_DIA) {
    color(C_STEEL)
    rotate([-90, 0, 0])
        cylinder(d = dia, h = length, center = true);
}

// String segment between two 3D points
module string_segment(p1, p2, dia = STRING_DIA) {
    color(C_STRING)
    hull() {
        translate(p1) sphere(d = dia, $fn = 8);
        translate(p2) sphere(d = dia, $fn = 8);
    }
}

// ============================================
// STATOR PLATE MODULE
// ============================================

module stator_plate() {
    color(C_ACRYLIC)
    difference() {
        // Main rectangular plate (XZ plane, extruded in Y)
        translate([-PLATE_WIDTH / 2, 0, 0])
            cube([PLATE_WIDTH, PLATE_THICK, PLATE_HEIGHT]);

        // Stadium cutout (through the plate thickness)
        translate([0, -0.1, STADIUM_CENTER_Z])
            rotate([-90, 0, 0])
                linear_extrude(PLATE_THICK + 0.2)
                    stadium_2d(STADIUM_LENGTH, STADIUM_HEIGHT);

        // Fixed pulley shaft holes — top bank
        for (i = [0 : NUM_FIXED_TOP - 1])
            translate([fixed_pulley_x(i, NUM_FIXED_TOP), -0.1, TOP_BANK_Z])
                rotate([-90, 0, 0])
                    cylinder(d = SHAFT_DIA + TOL_SLIDING,
                             h = PLATE_THICK + 0.2);

        // Fixed pulley shaft holes — bottom bank
        for (i = [0 : NUM_FIXED_BOTTOM - 1])
            translate([fixed_pulley_x(i, NUM_FIXED_BOTTOM), -0.1,
                       BOTTOM_BANK_Z])
                rotate([-90, 0, 0])
                    cylinder(d = SHAFT_DIA + TOL_SLIDING,
                             h = PLATE_THICK + 0.2);

        // Guide bearing shaft holes
        for (xpos = [-PLATE_WIDTH / 2 + BEARING_X_INSET,
                      PLATE_WIDTH / 2 - BEARING_X_INSET])
            for (zpos = [BEARING_TOP_Z, BEARING_BOTTOM_Z])
                translate([xpos, -0.1, zpos])
                    rotate([-90, 0, 0])
                        cylinder(d = BEARING_SHAFT + TOL_SLIDING,
                                 h = PLATE_THICK + 0.2);

        // Standoff bolt holes — top edge
        for (i = [0 : 2])
            translate([standoff_x(i), -0.1,
                       PLATE_HEIGHT - CORNER_INSET])
                rotate([-90, 0, 0])
                    cylinder(d = STANDOFF_BORE + TOL_GENERAL,
                             h = PLATE_THICK + 0.2);

        // Standoff bolt holes — bottom edge
        for (i = [0 : 2])
            translate([standoff_x(i), -0.1, CORNER_INSET])
                rotate([-90, 0, 0])
                    cylinder(d = STANDOFF_BORE + TOL_GENERAL,
                             h = PLATE_THICK + 0.2);

        // Corner mounting holes (M3 for wall/frame)
        for (xm = [-1, 1])
            for (zm = [0, 1])
                translate([xm * (PLATE_WIDTH / 2 - CORNER_INSET),
                           -0.1,
                           CORNER_INSET + zm * (PLATE_HEIGHT - 2 * CORNER_INSET)])
                    rotate([-90, 0, 0])
                        cylinder(d = CORNER_HOLE_DIA,
                                 h = PLATE_THICK + 0.2);
    }
}

// ============================================
// FIXED PULLEY BANK MODULE
// ============================================

module fixed_pulley_bank(bank_z, count) {
    total_shaft_len = PLATE_GAP + 2 * PLATE_THICK;

    for (i = [0 : count - 1]) {
        px = fixed_pulley_x(i, count);

        // Pulley (centered in gap)
        if (SHOW_PULLEYS)
            translate([px, PLATE_THICK + PLATE_GAP / 2, bank_z])
                rotate([90, 0, 0])
                    pulley_wheel();

        // Spanning shaft
        if (SHOW_SHAFTS)
            translate([px, total_shaft_len / 2, bank_z])
                spanning_shaft(length = total_shaft_len);
    }
}

// ============================================
// GUIDE BEARING SET MODULE
// ============================================

module guide_bearing_set() {
    if (SHOW_BEARINGS) {
        for (xpos = [-PLATE_WIDTH / 2 + BEARING_X_INSET,
                      PLATE_WIDTH / 2 - BEARING_X_INSET])
            for (zpos = [BEARING_TOP_Z, BEARING_BOTTOM_Z]) {
                // Bearing centered in gap
                translate([xpos, PLATE_THICK + PLATE_GAP / 2, zpos])
                    guide_bearing();

                // Bearing shaft
                if (SHOW_SHAFTS) {
                    shaft_len = PLATE_GAP + 2 * PLATE_THICK;
                    translate([xpos, shaft_len / 2, zpos])
                        spanning_shaft(length = shaft_len,
                                       dia = BEARING_SHAFT);
                }
            }
    }
}

// ============================================
// STATOR ASSEMBLY MODULE
// ============================================

module stator_assembly() {
    if (SHOW_STATOR) {
        exp = SHOW_EXPLODED ? EXPLODE_DIST : 0;

        // Wall A (near side, Y = 0)
        translate([0, -exp, 0])
            stator_plate();

        // Wall B (far side, Y = PLATE_THICK + PLATE_GAP)
        translate([0, PLATE_THICK + PLATE_GAP + exp, 0])
            stator_plate();

        // Standoffs — top edge
        for (i = [0 : 2])
            translate([standoff_x(i),
                       PLATE_THICK,
                       PLATE_HEIGHT - CORNER_INSET])
                rotate([-90, 0, 0])
                    standoff_post();

        // Standoffs — bottom edge
        for (i = [0 : 2])
            translate([standoff_x(i),
                       PLATE_THICK,
                       CORNER_INSET])
                rotate([-90, 0, 0])
                    standoff_post();
    }

    // Fixed pulley banks (always relative to stator)
    fixed_pulley_bank(TOP_BANK_Z, NUM_FIXED_TOP);
    fixed_pulley_bank(BOTTOM_BANK_Z, NUM_FIXED_BOTTOM);

    // Guide bearings
    guide_bearing_set();
}

// ============================================
// SLIDER BAR MODULE
// ============================================

module slider_bar() {
    color(C_ACRYLIC_BAR)
    difference() {
        // Main rectangular bar (XZ plane, centered in gap)
        translate([-SLIDER_LENGTH / 2 + (PLATE_WIDTH / 2 - SLIDER_EXTENSION),
                   0, -SLIDER_HEIGHT / 2])
            cube([SLIDER_LENGTH, SLIDER_THICK, SLIDER_HEIGHT]);

        // Push-rod mounting hole at left extension
        translate([-SLIDER_LENGTH / 2 + (PLATE_WIDTH / 2 - SLIDER_EXTENSION)
                    + MOUNT_HOLE_INSET,
                   -0.1,
                   0])
            rotate([-90, 0, 0])
                cylinder(d = MOUNT_HOLE_DIA,
                         h = SLIDER_THICK + 0.2);

        // Slider pulley stub shaft holes (through the bar thickness)
        for (j = [0 : NUM_SLIDER_PULLEYS - 1])
            translate([slider_pulley_x(j), -0.1, 0])
                rotate([-90, 0, 0])
                    cylinder(d = SLIDER_PULLEY_BORE + TOL_SLIDING,
                             h = SLIDER_THICK + 0.2);
    }
}

// ============================================
// SLIDER ASSEMBLY MODULE
// ============================================

module slider_assembly(x_offset) {
    if (SHOW_SLIDER) {
        // Y position: centered in gap
        y_center = PLATE_THICK + (PLATE_GAP - SLIDER_THICK) / 2;

        translate([x_offset, y_center, SLIDER_CENTER_Z]) {
            // Slider bar
            slider_bar();

            // Slider pulleys on stub shafts
            if (SHOW_PULLEYS)
                for (j = [0 : NUM_SLIDER_PULLEYS - 1]) {
                    px = slider_pulley_x(j);
                    translate([px, SLIDER_THICK / 2, 0])
                        rotate([90, 0, 0])
                            pulley_wheel(od = SLIDER_PULLEY_DIA,
                                         thick = SLIDER_PULLEY_THICK,
                                         bore = SLIDER_PULLEY_BORE);

                    // Stub shaft (within bar only)
                    if (SHOW_SHAFTS)
                        translate([px, SLIDER_THICK / 2, 0])
                            spanning_shaft(length = SLIDER_THICK + 2,
                                           dia = SLIDER_PULLEY_BORE);
                }
        }
    }
}

// ============================================
// SERPENTINE STRING ROUTING
// ============================================

// The serpentine path alternates through the pulley banks:
// TF[0] → S[0] → BF[0] → S[1] → TF[1] → S[2] → BF[1] → S[3] → ...
//
// With 7 slider pulleys: uses 4 top-fixed + 4 bottom-fixed = 8 of 16 total.
// Pattern: for slider index i:
//   if i is even: previous fixed was TOP, next fixed is BOTTOM
//   if i is odd:  previous fixed was BOTTOM, next fixed is TOP

function serpentine_waypoints(x_off) =
    let(
        // Y midplane of pulleys (centered in gap)
        py = PLATE_THICK + PLATE_GAP / 2,

        // Build the full serpentine path
        // We start at top-fixed[0], then alternate:
        // TF[0] → S[0] → BF[0] → S[1] → TF[1] → S[2] → ...
        n = NUM_SLIDER_PULLEYS,

        // Anchor above first top-fixed pulley
        anchor_start = [fixed_pulley_x(0, NUM_FIXED_TOP),
                        py, TOP_BANK_Z + FIXED_PULLEY_DIA / 2 + 3],

        // Build waypoints procedurally
        waypoints = [
            for (i = [0 : n - 1])
                let(
                    // Which fixed pulley index (alternating top/bottom)
                    fi = floor(i / 2),
                    // Even i: comes FROM top-fixed, goes TO bottom-fixed
                    // Odd i:  comes FROM bottom-fixed, goes TO top-fixed
                    is_from_top = (i % 2 == 0),
                    // Fixed pulley position (the one BEFORE this slider)
                    fx = fixed_pulley_x(fi, NUM_FIXED_TOP),
                    fz = is_from_top ? TOP_BANK_Z : BOTTOM_BANK_Z,
                    // Slider pulley position (shifted by animation)
                    sx = slider_pulley_x(i) + x_off,
                    sz = SLIDER_CENTER_Z
                )
                each [
                    [fx, py, fz],    // Fixed pulley contact point
                    [sx, py, sz]     // Slider pulley contact point
                ],

            // Final fixed pulley at end of serpentine
            let(
                final_fi = floor(NUM_SLIDER_PULLEYS / 2),
                final_is_bottom = (NUM_SLIDER_PULLEYS % 2 == 1)
            )
            [fixed_pulley_x(final_fi, NUM_FIXED_TOP),
             py,
             final_is_bottom ? BOTTOM_BANK_Z : TOP_BANK_Z]
        ],

        // Anchor after last fixed pulley
        last_wp = waypoints[len(waypoints) - 1],
        anchor_end = [last_wp[0], py,
                      last_wp[2] + (last_wp[2] == TOP_BANK_Z ? 1 : -1)
                      * (FIXED_PULLEY_DIA / 2 + 3)]
    )
    concat([anchor_start], waypoints, [anchor_end]);

module string_path(x_offset) {
    if (SHOW_STRINGS) {
        wp = serpentine_waypoints(x_offset);
        for (i = [0 : len(wp) - 2])
            string_segment(wp[i], wp[i + 1]);

        // Anchor spheres at start and end
        color(C_MOUNT) {
            translate(wp[0]) sphere(d = 2.5, $fn = 12);
            translate(wp[len(wp) - 1]) sphere(d = 2.5, $fn = 12);
        }
    }
}

// ============================================
// MAIN ASSEMBLY MODULE
// ============================================

// Top-level module. Can be called standalone or imported:
//   use <linear_pulley_unit_v1.scad>
//   linear_pulley_unit(slider_offset = helix_displacement);

module linear_pulley_unit(slider_offset = undef) {
    // Use external offset if provided, otherwise use animation
    _offset = (slider_offset != undef) ? slider_offset : slider_x_offset;

    scale(SCALE_FACTOR) {
        stator_assembly();
        slider_assembly(_offset);
        string_path(_offset);
    }
}

// Section view: cut at Y midplane to reveal internals
module section_view() {
    _offset = slider_x_offset;
    intersection() {
        scale(SCALE_FACTOR) {
            stator_assembly();
            slider_assembly(_offset);
            string_path(_offset);
        }
        // Keep only near half (Y < midplane)
        translate([-500, -500, -500])
            cube([1000, PLATE_THICK + PLATE_GAP / 2 + 500, 1000]);
    }
}

// ============================================
// VERIFICATION SECTION
// ============================================

// --- Power Path ---
echo("================================================================");
echo("  SINGLE-CHANNEL LINEAR PULLEY UNIT v1.0");
echo("================================================================");
echo("POWER PATH:");
echo("  Helix Push-Rod → Slider Bar (horizontal reciprocation)");
echo(str("  → ", NUM_SLIDER_PULLEYS, " Slider Pulleys (on bar centerline)"));
echo(str("  → Serpentine through ", NUM_FIXED_TOP + NUM_FIXED_BOTTOM,
         " Fixed Pulleys (", NUM_FIXED_TOP, " top + ",
         NUM_FIXED_BOTTOM, " bottom)"));
echo("  → String tension → Block vertical displacement");
echo("");

// --- Dimensions ---
echo("DIMENSIONS:");
echo(str("  Stator plates: ", PLATE_WIDTH, " x ", PLATE_HEIGHT,
         " x ", PLATE_THICK, "mm (x2)"));
echo(str("  Plate gap: ", PLATE_GAP, "mm"));
echo(str("  Stadium cutout: ", STADIUM_LENGTH, " x ", STADIUM_HEIGHT, "mm"));
echo(str("  Slider bar: ", SLIDER_LENGTH, " x ", SLIDER_HEIGHT,
         " x ", SLIDER_THICK, "mm (height derived from bearing spacing)"));
echo(str("  Slider stroke: +/-", SLIDER_STROKE / 2, "mm (",
         SLIDER_STROKE, "mm total)"));
echo(str("  Slider extension: ", SLIDER_EXTENSION,
         "mm past stator (push-rod mount)"));
echo("");

// --- Pulley Layout ---
_fixed_span = (NUM_FIXED_TOP - 1) * PULLEY_SPACING;
_slider_span = (NUM_SLIDER_PULLEYS - 1) * PULLEY_SPACING;
echo("PULLEY LAYOUT:");
echo(str("  Fixed per bank: ", NUM_FIXED_TOP, " @ ", PULLEY_SPACING,
         "mm spacing (span: ", _fixed_span, "mm)"));
echo(str("  Slider: ", NUM_SLIDER_PULLEYS, " @ ", PULLEY_SPACING,
         "mm spacing (span: ", _slider_span, "mm)"));
echo(str("  Interleave offset: ", PULLEY_SPACING / 2, "mm"));
echo(str("  Stadium fits pulleys: ", _fixed_span, "mm < ",
         STADIUM_LENGTH, "mm → ",
         (_fixed_span < STADIUM_LENGTH) ? "OK" : "FAIL"));
echo("");

// --- Friction Cascade ---
// Serpentine uses 4 top + 4 bottom + 7 slider = 15 pulleys total
_serial_pulleys = 4 + 4 + NUM_SLIDER_PULLEYS;
_mu = 0.95;
_efficiency = pow(_mu, _serial_pulleys);
echo("FRICTION CASCADE:");
echo(str("  Serial pulleys in string path: ", _serial_pulleys));
echo(str("  Per-pulley efficiency: ", _mu * 100, "%"));
echo(str("  Total string efficiency: ",
         round(_efficiency * 1000) / 10, "%"));
echo(str("  Margolin 9-pulley limit: ",
         (_serial_pulleys <= 9) ? "WITHIN LIMIT" :
         "EXCEEDS (acceptable for prototype, reduce for production)"));
echo("");

// --- Geometric Checks ---
echo("GEOMETRIC VERIFICATION:");
echo(str("  Slider height: ", SLIDER_HEIGHT, "mm (derived from bearing spacing)"));
echo(str("  Bearing top Z: ", BEARING_TOP_Z, "mm, bottom Z: ", BEARING_BOTTOM_Z, "mm"));
echo(str("  Slider center Z: ", SLIDER_CENTER_Z, "mm"));
echo(str("  Stadium height: ", STADIUM_HEIGHT, "mm, center Z: ", STADIUM_CENTER_Z, "mm"));
echo(str("  Stadium clears slider pulleys: ",
         (STADIUM_HEIGHT >= SLIDER_PULLEY_DIA + 4) ? "OK" : "TIGHT"));
echo(str("  Slider bar in gap: ", SLIDER_THICK, "mm bar in ",
         PLATE_GAP, "mm gap → clearance: ",
         (PLATE_GAP - SLIDER_THICK) / 2, "mm/side"));
echo(str("  Stroke < spacing (no string cross): ",
         SLIDER_STROKE, " < ", PULLEY_SPACING, " → ",
         (SLIDER_STROKE < PULLEY_SPACING) ? "OK" : "WARNING"));
echo(str("  Bearings outside stadium: top ", BEARING_TOP_Z, " > ",
         STADIUM_CENTER_Z + STADIUM_HEIGHT/2, " → ",
         (BEARING_TOP_Z > STADIUM_CENTER_Z + STADIUM_HEIGHT/2) ? "OK" : "FAIL"));
echo(str("  Bearings outside stadium: bottom ", BEARING_BOTTOM_Z, " < ",
         STADIUM_CENTER_Z - STADIUM_HEIGHT/2, " → ",
         (BEARING_BOTTOM_Z < STADIUM_CENTER_Z - STADIUM_HEIGHT/2) ? "OK" : "FAIL"));
echo("");

// --- Printability ---
_min_wall = min(PLATE_THICK,
                (STANDOFF_DIA - STANDOFF_BORE) / 2,
                (FIXED_PULLEY_DIA - (FIXED_PULLEY_BORE + TOL_PULLEY_BORE)) / 2
                - GROOVE_DEPTH);
echo("PRINTABILITY:");
echo(str("  Min wall thickness: ", _min_wall, "mm",
         (_min_wall >= 1.2) ? " (OK, >= 1.2mm)" : " (WARNING: < 1.2mm)"));
echo(str("  Slider clearance per side: ",
         (PLATE_GAP - SLIDER_THICK) / 2, "mm",
         ((PLATE_GAP - SLIDER_THICK) / 2 >= 0.3) ?
         " (OK, >= 0.3mm)" : " (WARNING: tight fit)"));
echo(str("  Scale factor: ", SCALE_FACTOR));
echo(str("  Build envelope: ", SLIDER_LENGTH * SCALE_FACTOR, " x ",
         (PLATE_GAP + 2 * PLATE_THICK) * SCALE_FACTOR, " x ",
         PLATE_HEIGHT * SCALE_FACTOR, "mm"));

_bed_warning = (SLIDER_LENGTH * SCALE_FACTOR > 250) ?
    "  WARNING: Slider exceeds 250mm — set SCALE_FACTOR=0.6 or split-print" :
    "  Slider fits standard print bed";
echo(_bed_warning);
echo("");

// --- Part Count ---
_part_count = 2 + STANDOFF_COUNT + NUM_FIXED_TOP + NUM_FIXED_BOTTOM
              + NUM_SLIDER_PULLEYS + 4 + 1;
echo("PARTS:");
echo(str("  Stator plates: 2"));
echo(str("  Standoffs: ", STANDOFF_COUNT));
echo(str("  Fixed pulleys: ", NUM_FIXED_TOP + NUM_FIXED_BOTTOM,
         " (", NUM_FIXED_TOP, " top + ", NUM_FIXED_BOTTOM, " bottom)"));
echo(str("  Slider pulleys: ", NUM_SLIDER_PULLEYS));
echo(str("  Guide bearings: 4"));
echo(str("  Slider bar: 1"));
echo(str("  Total: ", _part_count, " parts"));
echo("================================================================");

// ============================================
// PRINT ORIENTATION GUIDE
// ============================================

echo("");
echo("PRINT ORIENTATION (all no-support FDM at 0.2mm layers):");
echo("  Stator plate:  flat on bed (XY), stadium cutout facing up");
echo("  Slider bar:    flat on bed (XY), thinnest face down");
echo("  Pulleys (x23): flat face down, groove faces up");
echo("  Standoffs (x6): upright on flat end");
echo("  TIP: Print in clear PETG for transparency effect");
echo("");

// ============================================
// DEFAULT RENDER
// ============================================

if (SHOW_SECTION) {
    section_view();
} else {
    linear_pulley_unit();
}

// ============================================
// STL EXPORT (uncomment ONE, then F6 render)
// ============================================

// --- Individual parts for 3D printing ---
// stator_plate();
// slider_bar();
// pulley_wheel();
// standoff_post();

// --- Split slider for small print beds ---
// (Left half with mounting hole)
// intersection() {
//     slider_bar();
//     translate([-250, -10, -20]) cube([250, 30, 40]);
// }
// (Right half)
// intersection() {
//     slider_bar();
//     translate([0, -10, -20]) cube([250, 30, 40]);
// }

// ============================================
// ANIMATION INSTRUCTIONS
// ============================================
// 1. Open this file in OpenSCAD
// 2. View → Animate
// 3. FPS: 30, Steps: 120
// 4. Watch the slider oscillate and strings track through pulleys
//
// DEBUGGING (static positions):
//   MANUAL_POSITION = 0.00  → slider at left limit
//   MANUAL_POSITION = 0.25  → slider at center (moving right)
//   MANUAL_POSITION = 0.50  → slider at right limit
//   MANUAL_POSITION = 0.75  → slider at center (moving left)
//
// TOGGLE CONTROLS:
//   SHOW_STRINGS  = false   → hide strings to inspect pulleys
//   SHOW_STATOR   = false   → hide plates to see internal mechanism
//   SHOW_SECTION  = true    → XZ section cut revealing internals
//   SHOW_EXPLODED = true    → spread plates apart for inspection
//
// FOR IMPORT INTO TRIPLE HELIX:
//   use <linear_pulley_unit_v1.scad>
//   linear_pulley_unit(slider_offset = helix_displacement);
