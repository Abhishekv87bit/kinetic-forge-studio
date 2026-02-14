/*
 * TILTED RING WAVE DRIVER v1.0 (Margolín-Style)
 * ==============================================
 * Educational kinetic sculpture prototype demonstrating
 * Rubén Margolín's tilted-ring wave mechanism.
 *
 * MECHANISM:
 * A circular ring tilted at RING_TILT_DEG from horizontal rotates
 * around a vertical axis driven by a single motor. A rectangular
 * grid of vertical rods passes through a guide plate above. Each
 * rod rests on the ring surface via gravity. As the ring rotates,
 * each rod rises and falls sinusoidally. Rods at different angular
 * positions are phase-shifted, producing a radial traveling wave
 * — like a stone dropped in still water.
 *
 * POWER PATH:
 * Motor → Shaft → Tilted Ring → Strings → Pulleys → Rod bottoms → Tips
 *
 * STRING ROUTING (Margolín style):
 * Each rod has a string attached to its bottom. The string drops
 * vertically to a pulley mounted under the guide plate, redirects
 * downward at an angle to the tilted ring contact point. As the ring
 * rotates, the string length between ring and pulley changes,
 * pulling the rod up or letting it drop back down via gravity.
 *
 * WEAVE SURFACE:
 * A wire grid mesh connects adjacent rod tips, creating a flowing
 * fabric-like surface that undulates with the radial wave.
 *
 * COORDINATE SYSTEM:
 * X, Y: Horizontal plane (grid layout)
 * Z:    Vertical (rod travel direction)
 * Origin: Center of ring rotation at base surface
 *
 * ANIMATION:
 * 1. View → Animate
 * 2. FPS: 30, Steps: 120
 * 3. Set MANUAL_ANGLE = 0 (crest at +Y), 90, 180, 270 for static debug
 */

$fn = 48;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;  // Set 0-360 for static debug, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// PARAMETERS: RING
// ============================================

RING_RADIUS   = 60;     // mm - radius of the tilted driving ring
RING_TILT_DEG = 15;     // degrees - tilt from horizontal plane
RING_TUBE_DIA = 6;      // mm - cross-section diameter of ring tube
RING_Z        = 20;     // mm - height of ring center above base

// ============================================
// PARAMETERS: ROD GRID
// ============================================

GRID_NX      = 9;       // rod count along X
GRID_NY      = 9;       // rod count along Y
GRID_SPACING = 12;      // mm - center-to-center distance between rods

// ============================================
// PARAMETERS: RODS
// ============================================

ROD_DIA      = 3;       // mm - rod shaft diameter
ROD_LENGTH   = 60;      // mm - visible rod length above ring contact
ROD_TIP_DIA  = 6;       // mm - decorative tip sphere diameter

// ============================================
// PARAMETERS: GUIDE PLATE
// ============================================

GUIDE_Z        = 50;                    // mm - plate height above base
GUIDE_THICK    = 3;                     // mm - plate thickness
GUIDE_HOLE_DIA = ROD_DIA + 0.5;        // mm - sliding clearance
GUIDE_MARGIN   = 10;                    // mm - extra border around grid

// ============================================
// PARAMETERS: FRAME
// ============================================

BASE_SIZE    = 150;      // mm - square base side length
BASE_THICK   = 5;        // mm - base plate thickness
PILLAR_DIA   = 8;        // mm - support pillar diameter
SHAFT_DIA    = 5;        // mm - central drive shaft diameter
MOTOR_DIA    = 20;       // mm - motor housing placeholder
MOTOR_HEIGHT = 15;       // mm - motor housing height

// ============================================
// PARAMETERS: PULLEYS
// ============================================

PULLEY_DIA     = 5;      // mm - pulley wheel diameter
PULLEY_THICK   = 2;      // mm - pulley wheel thickness
PULLEY_BRACKET = 2;      // mm - bracket arm width
PULLEY_DROP    = 6;      // mm - how far below guide plate the pulley sits

// ============================================
// PARAMETERS: MESH WEAVE
// ============================================

MESH_WIRE_DIA = 0.8;     // mm - wire thickness connecting rod tips
MESH_SAG      = 1.5;     // mm - slight droop at midpoint between rods

// ============================================
// SHOW / HIDE TOGGLES
// ============================================

SHOW_RING    = true;
SHOW_RODS    = true;
SHOW_GUIDE   = true;
SHOW_FRAME   = true;
SHOW_SHAFT   = true;
SHOW_TIPS    = true;
SHOW_STRINGS = true;     // Strings from ring through pulleys to rods
SHOW_PULLEYS = true;     // Redirect pulleys under guide plate
SHOW_MESH    = true;     // Wire grid mesh connecting rod tips

// ============================================
// COLORS
// ============================================

C_RING   = [0.75, 0.55, 0.20];          // Brass
C_ROD    = [0.50, 0.50, 0.55];          // Steel
C_GUIDE  = [0.85, 0.85, 0.90, 0.35];   // Semi-transparent acrylic
C_FRAME  = [0.30, 0.25, 0.20];          // Dark wood
C_PILLAR = [0.50, 0.50, 0.55];          // Steel
C_SHAFT  = [0.45, 0.45, 0.50];          // Drive shaft
C_STRING = [0.90, 0.85, 0.70];          // Cotton
C_PULLEY = [0.60, 0.60, 0.65];          // Steel pulley wheel
C_MESH   = [0.75, 0.75, 0.80];          // Light steel wire mesh

// Ocean gradient for rod tips: deep blue (low) → white (high)
function clamp(val, lo, hi) = min(hi, max(lo, val));

function tip_color(height, max_h) =
    let(
        t = clamp((height + max_h) / (2 * max_h), 0, 1),
        r = 0.15 + 0.85 * pow(t, 2),
        g = 0.30 + 0.70 * pow(t, 1.5),
        b = 0.60 + 0.40 * t
    )
    [r, g, b];

// ============================================
// KINEMATICS
// ============================================
//
// Physical model: the ring lies in a plane tilted RING_TILT_DEG
// from horizontal. As the ring rotates by theta, a rod at position
// (x, y) sees the ring surface rise and fall sinusoidally.
//
// Phase offset = atan2(y, x) → rods at different angles peak at
// different times → radial traveling wave.

function rod_height(x, y, theta_deg,
                    tilt_deg = RING_TILT_DEG,
                    ring_r   = RING_RADIUS) =
    let(
        r       = sqrt(x * x + y * y),
        phi     = atan2(y, x),
        contact = (r <= ring_r) ? 1 : 0,
        h       = contact * r * tan(tilt_deg) * sin(phi - theta_deg)
    ) h;

function max_rod_displacement(tilt_deg = RING_TILT_DEG,
                              ring_r   = RING_RADIUS) =
    ring_r * tan(tilt_deg);

// Grid position helpers
function rod_x(ix) = (ix - (GRID_NX - 1) / 2) * GRID_SPACING;
function rod_y(iy) = (iy - (GRID_NY - 1) / 2) * GRID_SPACING;

function rod_contacts_ring(x, y) = sqrt(x * x + y * y) <= RING_RADIUS;

// Z position of a rod's tip (top of sphere center)
function rod_tip_z(x, y, theta_deg) =
    RING_Z + rod_height(x, y, theta_deg) + ROD_LENGTH;

// Point on the tilted ring at local angle 'a' (ring frame),
// given current rotation theta
function ring_point(a, theta_deg,
                    tilt_deg = RING_TILT_DEG,
                    ring_r   = RING_RADIUS) =
    let(
        world_a = a + theta_deg,
        x = ring_r * cos(world_a),
        y = ring_r * sin(world_a),
        z = RING_Z + ring_r * tan(tilt_deg) * sin(a)
    )
    [x, y, z];

// ============================================
// MODULES: RING
// ============================================

module tilted_ring(theta_deg) {
    if (SHOW_RING) {
        color(C_RING)
        translate([0, 0, RING_Z])
        rotate([0, 0, theta_deg])
        rotate([RING_TILT_DEG, 0, 0])
        rotate_extrude(convexity = 2, $fn = 72)
        translate([RING_RADIUS, 0, 0])
            circle(d = RING_TUBE_DIA, $fn = 16);
    }
}

// ============================================
// MODULES: DRIVE SHAFT
// ============================================

module drive_shaft(theta_deg) {
    if (SHOW_SHAFT) {
        color(C_SHAFT) {
            // Vertical shaft from base to ring center
            cylinder(d = SHAFT_DIA, h = RING_Z + 5, $fn = 24);

            // Rotation indicator mark
            rotate([0, 0, theta_deg])
            translate([0, -1, RING_Z - 3])
                cube([SHAFT_DIA + 2, 2, 6]);
        }
    }
}

// ============================================
// MODULES: GUIDE PLATE
// ============================================

module guide_plate() {
    if (SHOW_GUIDE) {
        plate_w = (GRID_NX - 1) * GRID_SPACING + 2 * GUIDE_MARGIN;
        plate_h = (GRID_NY - 1) * GRID_SPACING + 2 * GUIDE_MARGIN;

        color(C_GUIDE)
        translate([0, 0, GUIDE_Z])
        difference() {
            translate([-plate_w / 2, -plate_h / 2, 0])
                cube([plate_w, plate_h, GUIDE_THICK]);

            for (ix = [0 : GRID_NX - 1])
                for (iy = [0 : GRID_NY - 1])
                    translate([rod_x(ix), rod_y(iy), -0.1])
                        cylinder(d = GUIDE_HOLE_DIA,
                                 h = GUIDE_THICK + 0.2, $fn = 16);
        }
    }
}

// ============================================
// MODULES: RODS
// ============================================

module single_rod(x, y, theta_deg) {
    h     = rod_height(x, y, theta_deg);
    max_h = max_rod_displacement();
    rod_base_z = RING_Z + h;

    // Rod shaft
    color(C_ROD)
    translate([x, y, rod_base_z])
        cylinder(d = ROD_DIA, h = ROD_LENGTH, $fn = 12);

    // Decorative tip sphere — color encodes height
    if (SHOW_TIPS) {
        color(tip_color(h, max_h))
        translate([x, y, rod_base_z + ROD_LENGTH])
            sphere(d = ROD_TIP_DIA, $fn = 16);
    }
}

module rod_grid(theta_deg) {
    if (SHOW_RODS) {
        for (ix = [0 : GRID_NX - 1])
            for (iy = [0 : GRID_NY - 1])
                single_rod(rod_x(ix), rod_y(iy), theta_deg);
    }
}

// ============================================
// MODULES: FRAME
// ============================================

module frame() {
    if (SHOW_FRAME) {
        // Base plate
        color(C_FRAME)
        translate([-BASE_SIZE / 2, -BASE_SIZE / 2, -BASE_THICK])
            cube([BASE_SIZE, BASE_SIZE, BASE_THICK]);

        // Four corner pillars
        color(C_PILLAR) {
            pillar_inset = 15;
            for (sx = [-1, 1])
                for (sy = [-1, 1])
                    translate([sx * (BASE_SIZE / 2 - pillar_inset),
                               sy * (BASE_SIZE / 2 - pillar_inset), 0])
                        cylinder(d = PILLAR_DIA,
                                 h = GUIDE_Z + GUIDE_THICK, $fn = 16);
        }

        // Motor housing placeholder (below base)
        color(C_SHAFT)
        translate([0, 0, -BASE_THICK - MOTOR_HEIGHT])
            cylinder(d = MOTOR_DIA, h = MOTOR_HEIGHT, $fn = 24);
    }
}

// ============================================
// MODULES: PULLEYS
// ============================================
// Small redirect pulleys mounted under the guide plate, one per rod.
// Each pulley redirects the string from vertical (rod above) to
// angled (down to the tilted ring contact point below).

module single_pulley(x, y) {
    pz = GUIDE_Z - PULLEY_DROP;

    // Pulley wheel (torus approximation: flat cylinder)
    color(C_PULLEY)
    translate([x, y, pz])
    rotate([90, 0, atan2(y, x)])  // Face toward ring center
        cylinder(d = PULLEY_DIA, h = PULLEY_THICK,
                 center = true, $fn = 16);

    // Bracket arm connecting pulley to guide plate underside
    color(C_PILLAR)
    hull() {
        translate([x, y, pz])
            sphere(d = PULLEY_BRACKET, $fn = 8);
        translate([x, y, GUIDE_Z])
            sphere(d = PULLEY_BRACKET, $fn = 8);
    }
}

module pulleys() {
    if (SHOW_PULLEYS) {
        for (ix = [0 : GRID_NX - 1])
            for (iy = [0 : GRID_NY - 1]) {
                x = rod_x(ix);
                y = rod_y(iy);
                if (rod_contacts_ring(x, y))
                    single_pulley(x, y);
            }
    }
}

// ============================================
// MODULES: STRINGS (routed through pulleys)
// ============================================
// String path: rod bottom → pulley → ring contact point
// Two segments per rod, meeting at the pulley.

module single_string(x, y, theta_deg) {
    h   = rod_height(x, y, theta_deg);
    phi = atan2(y, x);

    rod_bottom = [x, y, RING_Z + h];
    pulley_pt  = [x, y, GUIDE_Z - PULLEY_DROP];
    ring_pt    = ring_point(phi - theta_deg, theta_deg);

    color(C_STRING) {
        // Segment 1: rod bottom → pulley (nearly vertical)
        hull() {
            translate(rod_bottom) sphere(d = 0.5, $fn = 6);
            translate(pulley_pt)  sphere(d = 0.5, $fn = 6);
        }
        // Segment 2: pulley → ring contact (angled down)
        hull() {
            translate(pulley_pt) sphere(d = 0.5, $fn = 6);
            translate(ring_pt)   sphere(d = 0.5, $fn = 6);
        }
    }
}

module strings(theta_deg) {
    if (SHOW_STRINGS) {
        for (ix = [0 : GRID_NX - 1])
            for (iy = [0 : GRID_NY - 1]) {
                x = rod_x(ix);
                y = rod_y(iy);
                if (rod_contacts_ring(x, y))
                    single_string(x, y, theta_deg);
            }
    }
}

// ============================================
// MODULES: WIRE MESH WEAVE
// ============================================
// Thin wire links between adjacent rod tips forming a grid.
// Connects each rod tip to its +X and +Y neighbor.
// Creates the fabric-like undulating surface Margolín is known for.

module mesh_link(p1, p2) {
    // Slight sag at midpoint for organic drape feel
    mid = [(p1[0] + p2[0]) / 2,
           (p1[1] + p2[1]) / 2,
           (p1[2] + p2[2]) / 2 - MESH_SAG];

    hull() {
        translate(p1)  sphere(d = MESH_WIRE_DIA, $fn = 6);
        translate(mid) sphere(d = MESH_WIRE_DIA, $fn = 6);
    }
    hull() {
        translate(mid) sphere(d = MESH_WIRE_DIA, $fn = 6);
        translate(p2)  sphere(d = MESH_WIRE_DIA, $fn = 6);
    }
}

module wire_mesh(theta_deg) {
    if (SHOW_MESH) {
        max_h = max_rod_displacement();
        for (ix = [0 : GRID_NX - 1])
            for (iy = [0 : GRID_NY - 1]) {
                x1 = rod_x(ix);
                y1 = rod_y(iy);
                z1 = rod_tip_z(x1, y1, theta_deg);
                h1 = rod_height(x1, y1, theta_deg);

                // Color based on average height of connected tips
                // Link to +X neighbor
                if (ix < GRID_NX - 1) {
                    x2 = rod_x(ix + 1);
                    y2 = y1;
                    z2 = rod_tip_z(x2, y2, theta_deg);
                    h2 = rod_height(x2, y2, theta_deg);
                    avg_h = (h1 + h2) / 2;
                    color(tip_color(avg_h, max_h))
                    mesh_link([x1, y1, z1], [x2, y2, z2]);
                }

                // Link to +Y neighbor
                if (iy < GRID_NY - 1) {
                    x2 = x1;
                    y2 = rod_y(iy + 1);
                    z2 = rod_tip_z(x2, y2, theta_deg);
                    h2 = rod_height(x2, y2, theta_deg);
                    avg_h = (h1 + h2) / 2;
                    color(tip_color(avg_h, max_h))
                    mesh_link([x1, y1, z1], [x2, y2, z2]);
                }
            }
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module margolin_wave_ring() {
    frame();
    drive_shaft(theta);
    tilted_ring(theta);
    guide_plate();
    pulleys();
    rod_grid(theta);
    strings(theta);
    wire_mesh(theta);
}

margolin_wave_ring();

// ============================================
// POWER PATH VERIFICATION
// ============================================

echo("=== POWER PATH ===");
echo("Motor → Shaft → Tilted Ring → Strings → Pulleys → Rods → Tips → Mesh");
echo("Every rod height = f(theta, x, y) — no orphan sin($t).");
echo("=== END POWER PATH ===");

// ============================================
// PHYSICS VERIFICATION
// ============================================

echo("=== PHYSICS CHECK ===");
_max_disp = max_rod_displacement();
echo(str("Ring tilt: ", RING_TILT_DEG, "°"));
echo(str("Ring radius: ", RING_RADIUS, "mm"));
echo(str("Max rod displacement: ±", round(_max_disp * 10) / 10, "mm"));
echo(str("Grid footprint: ",
         (GRID_NX - 1) * GRID_SPACING, " × ",
         (GRID_NY - 1) * GRID_SPACING, "mm"));

// Active rod count
_active = len([for (ix = [0 : GRID_NX - 1], iy = [0 : GRID_NY - 1])
    if (rod_contacts_ring(rod_x(ix), rod_y(iy))) 1]);
echo(str("Active rods (within ring): ", _active, " / ", GRID_NX * GRID_NY));

// Corner rod check
_corner_r = sqrt(pow(rod_x(0), 2) + pow(rod_y(0), 2));
echo(str("Corner rod distance: ", round(_corner_r * 10) / 10,
         "mm (ring R=", RING_RADIUS, " → ",
         _corner_r <= RING_RADIUS ? "ACTIVE" : "STATIC", ")"));

// Current state
echo(str("Current theta: ", round(theta), "°"));

// Cardinal direction rod heights — should show 90° phase shift
_r_test = GRID_SPACING * 2;   // 24mm from center
_h_E = rod_height( _r_test,       0, theta);
_h_N = rod_height(       0, _r_test, theta);
_h_W = rod_height(-_r_test,       0, theta);
_h_S = rod_height(       0,-_r_test, theta);
echo(str("Heights at r=", _r_test, "mm — ",
         "E:", round(_h_E * 10) / 10, " ",
         "N:", round(_h_N * 10) / 10, " ",
         "W:", round(_h_W * 10) / 10, " ",
         "S:", round(_h_S * 10) / 10, "mm"));
echo("(E vs W: opposite sign. N vs S: opposite sign. 90° phase between E↔N)");
echo("=== END PHYSICS ===");

// ============================================
// BUILD VOLUME
// ============================================

echo("=== BUILD VOLUME ===");
echo(str("Base: ", BASE_SIZE, " × ", BASE_SIZE, "mm"));
echo(str("Height: ~", GUIDE_Z + GUIDE_THICK + ROD_LENGTH +
         ROD_TIP_DIA + round(_max_disp), "mm (base to tallest tip)"));
echo("=== END BUILD VOLUME ===");

// ============================================
// INDIVIDUAL PARTS FOR PRINTING
// ============================================
// Uncomment one at a time to export STL:
//
// tilted_ring(0);                // Print flat, mount tilted
// guide_plate();                 // Print flat
// frame();                       // Print as one piece or split
// single_rod(0, 0, 0);          // Print ROD count copies

// ============================================
// ANIMATION INSTRUCTIONS
// ============================================
// 1. Open in OpenSCAD
// 2. View → Animate
// 3. FPS: 30, Steps: 120
// 4. Watch the radial wave pattern:
//    $t=0.00: Wave crest along +Y axis
//    $t=0.25: Wave crest along -X axis
//    $t=0.50: Wave crest along -Y axis
//    $t=0.75: Wave crest along +X axis
//
// DEBUGGING:
//    Set MANUAL_ANGLE = 0  → crest along +Y
//    Set MANUAL_ANGLE = 90 → crest along -X
//    Verify the crest rotates with theta
//
// TUNING:
//    RING_TILT_DEG: Larger = more dramatic wave (15° → ±16mm)
//    GRID_SPACING:  Smaller = denser, smoother visual wave
//    GRID_NX/NY:    More rods = prettier, slower render
//    SHOW_STRINGS:  true for string routing (slow with hull())
//    SHOW_PULLEYS:  true for redirect pulleys under guide plate
//    SHOW_MESH:     true for wire grid weave on tips (slowest)
//    MESH_SAG:      droop amount at wire midpoints (organic feel)
