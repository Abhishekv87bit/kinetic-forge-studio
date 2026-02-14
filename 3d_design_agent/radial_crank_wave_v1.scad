/*
 * RADIAL OFFSET-CRANK WAVE v1.0
 * ==============================
 * Kinetic sculpture: 16 offset cranks drive overlapping wedge slats
 * in a radial ripple wave pattern. Single motor.
 *
 * MECHANISM:
 * 16 small eccentric discs are arranged in a ring, each spinning
 * on its own horizontal axle oriented radially. All discs are
 * gear-coupled to a central vertical motor shaft via a ring gear.
 * Each disc spins in a vertical radial plane. Its eccentric pin
 * traces a vertical circle (radius = CRANK_RADIUS), directly
 * driving a follower rod up and down through a short connecting
 * rod. Phase offset = each disc's angular position around the ring.
 * Result: 16 followers bobbing with progressive phase → radial wave.
 *
 * Flat wedge-shaped slats sit on top of each follower. Adjacent
 * slats overlap like shingles. When one rides higher than its
 * neighbor, the overlap lip creates a visible wave crest.
 *
 * POWER PATH:
 * Motor → Central shaft → Ring gear → 16 eccentric discs
 * (vertical) → Pins → Connecting rods → Followers → Slats
 *
 * KEY GEOMETRY (why rod length stays constant):
 * Each pin orbits a 6mm vertical circle. The connecting rod is
 * ~30mm long. Horizontal offset swings 0-6mm, vertical component
 * of pin matches follower Z, so rod length = sqrt(30² + (6cos)²)
 * = 30.0 to 30.6mm (< 2% variation). Physically valid.
 *
 * ANIMATION:
 * 1. View → Animate
 * 2. FPS: 30, Steps: 120
 * 3. Set MANUAL_ANGLE = 0..360 for static debug
 */

$fn = 48;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;  // Set 0-360 for static debug, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// PARAMETERS: CRANK DISC
// ============================================

N_SLATS        = 16;                    // Number of cranks / slats
PHASE_STEP     = 360 / N_SLATS;        // 22.5° between adjacent cranks
CRANK_RADIUS   = 6;                     // mm — eccentric throw = wave amplitude
CRANK_DISC_H   = 4;                     // mm — disc plate thickness
CRANK_Z        = 12;                    // mm — Z of disc top surface
PIN_DIA        = 3;                     // mm — crank pin diameter
PIN_HEIGHT     = 6;                     // mm — pin sticks up from disc

// ============================================
// PARAMETERS: FOLLOWER
// ============================================

FOLLOWER_R     = 30;                    // mm — radial distance from center
FOLLOWER_DIA   = 5;                     // mm — rod diameter
FOLLOWER_LEN   = 25;                    // mm — visible rod length below slat

// ============================================
// PARAMETERS: CONNECTING ROD
// ============================================

// Rod connects pin top to follower bottom. Nearly vertical.
// Nominal length: Z distance from pin top to guide plate
ROD_NOMINAL_Z  = 30;                    // mm — approximate vertical span
ROD_WIDTH      = 4;                     // mm — rod bar width

// ============================================
// PARAMETERS: SLAT
// ============================================

SLAT_INNER_R     = 22;                  // mm — inner edge radius
SLAT_OUTER_R     = 75;                  // mm — outer edge radius
SLAT_THICK       = 2.5;                 // mm — Z thickness
SLAT_OVERLAP_DEG = 4;                   // degrees overlap with neighbor
SLAT_ANG_WIDTH   = PHASE_STEP + SLAT_OVERLAP_DEG;  // 26.5°

// ============================================
// PARAMETERS: GUIDE PLATE
// ============================================

GUIDE_Z          = CRANK_Z + PIN_HEIGHT + ROD_NOMINAL_Z;  // ~48mm
GUIDE_THICK      = 3;                   // mm
GUIDE_INNER_R    = 20;                  // mm
GUIDE_OUTER_R    = 40;                  // mm
GUIDE_SLOT_W     = FOLLOWER_DIA + 0.5;  // mm

// ============================================
// PARAMETERS: FRAME
// ============================================

SHAFT_DIA      = 6;                     // mm
BASE_DIA       = 175;                   // mm
BASE_THICK     = 5;                     // mm
PILLAR_DIA     = 6;                     // mm
N_PILLARS      = 4;
MOTOR_DIA      = 18;                    // mm
MOTOR_H        = 12;                    // mm

// ============================================
// SHOW / HIDE TOGGLES
// ============================================

SHOW_DISC      = true;       // Crank disc with pins
SHOW_RODS      = true;       // Connecting rods
SHOW_FOLLOWERS = true;
SHOW_SLATS     = true;
SHOW_GUIDE     = true;
SHOW_FRAME     = true;
SHOW_SHAFT     = true;

// ============================================
// COLORS
// ============================================

C_SHAFT   = [0.55, 0.55, 0.60];
C_DISC    = [0.75, 0.55, 0.20];         // Brass disc
C_PIN     = [0.60, 0.60, 0.65];
C_ROD     = [0.50, 0.50, 0.55];
C_FOLLOW  = [0.45, 0.45, 0.50];
C_GUIDE   = [0.80, 0.80, 0.85, 0.35];
C_BASE    = [0.25, 0.22, 0.20];
C_PILLAR  = [0.40, 0.40, 0.45];

function clamp(v, lo, hi) = min(hi, max(lo, v));

function slat_color(z_offset, max_z) =
    let(
        t = clamp((z_offset + max_z) / (2 * max_z), 0, 1),
        r = 0.10 + 0.30 * t,
        g = 0.25 + 0.40 * pow(t, 1.3),
        b = 0.45 + 0.50 * t
    )
    [r, g, b];

// ============================================
// KINEMATICS
// ============================================
//
// Each follower i has its own small eccentric disc spinning on a
// horizontal axle at (follower_fx, follower_fy, CRANK_Z). All 16
// discs are gear-coupled to the central shaft via a ring gear.
// Each disc spins in a VERTICAL radial plane. The eccentric pin
// traces a vertical circle of radius CRANK_RADIUS, directly
// driving the follower rod up and down.
//
// Phase offset = follower angular position → radial wave.
//
// Rod length verification:
//   pin orbits vertically → horizontal offset = r*cos(phase)
//   vertical offset from neutral = r*sin(phase)
//   rod dz = PIN_Z + r*sin(p) + PIN_HEIGHT - (GUIDE_Z + r*sin(p))
//          = PIN_Z + PIN_HEIGHT - GUIDE_Z = constant (-30mm)
//   rod d_horiz = r*cos(phase) = 0..6mm
//   rod_length = sqrt(30² + (6*cos(p))²) = 30.0..30.6mm (< 2% variation)

// Angular position of follower i in world frame (fixed)
function follower_angle(i) = i * PHASE_STEP;

// Follower XY (fixed in world)
function follower_fx(i) = FOLLOWER_R * cos(follower_angle(i));
function follower_fy(i) = FOLLOWER_R * sin(follower_angle(i));

PIN_Z = CRANK_Z;  // Axle height of eccentric discs

// Eccentric pin position: vertical circle in the radial plane
function ecc_pin_x(i, th) =
    let(phase = th - follower_angle(i),
        radial_offset = CRANK_RADIUS * cos(phase),
        ang = follower_angle(i))
    follower_fx(i) + radial_offset * cos(ang);

function ecc_pin_y(i, th) =
    let(phase = th - follower_angle(i),
        radial_offset = CRANK_RADIUS * cos(phase),
        ang = follower_angle(i))
    follower_fy(i) + radial_offset * sin(ang);

function ecc_pin_z(i, th) =
    PIN_Z + CRANK_RADIUS * sin(th - follower_angle(i));

// Follower Z offset — sinusoidal (matches pin vertical component)
function follower_dz(i, th) = CRANK_RADIUS * sin(th - follower_angle(i));
function follower_z_abs(i, th) = GUIDE_Z + follower_dz(i, th);

// Connecting rod endpoints
function rod_start(i, th) =
    [ecc_pin_x(i, th), ecc_pin_y(i, th), ecc_pin_z(i, th) + PIN_HEIGHT];

function rod_end(i, th) =
    [follower_fx(i), follower_fy(i), follower_z_abs(i, th)];

function rod_length_calc(i, th) =
    let(s = rod_start(i, th), e = rod_end(i, th))
    sqrt(pow(e[0]-s[0], 2) + pow(e[1]-s[1], 2) + pow(e[2]-s[2], 2));

// Slat tilt from neighbor height difference
function slat_tilt(i, th) =
    let(
        z1 = follower_dz(i, th),
        z2 = follower_dz((i + 1) % N_SLATS, th),
        mid_r = (SLAT_INNER_R + SLAT_OUTER_R) / 2,
        chord = 2 * mid_r * sin(PHASE_STEP / 2)
    )
    atan2(z2 - z1, chord);

// ============================================
// MODULES: CRANK DISC + ECCENTRIC DISCS
// ============================================
// Central drive disc (visual) plus 16 small eccentric discs,
// each at a follower position, spinning with phase offsets.

module eccentric_disc_single(i, th) {
    fx = follower_fx(i);
    fy = follower_fy(i);
    fa = follower_angle(i);
    phase = th - fa;

    // Eccentric disc — sits in vertical radial plane, spins around
    // a horizontal axle at the follower position
    color(C_DISC)
    translate([fx, fy, PIN_Z])
    rotate([0, 0, fa])          // Align with radial direction
    rotate([0, -90, 0])         // Tip disc into vertical plane
    rotate([0, 0, phase])       // Spin disc by crank angle
    translate([CRANK_RADIUS / 2, 0, 0])
        cylinder(d = CRANK_RADIUS * 2 + 4, h = CRANK_DISC_H,
                 center = true, $fn = 24);

    // Horizontal axle (at follower position, radial direction)
    color(C_SHAFT)
    translate([fx, fy, PIN_Z])
    rotate([0, 0, fa])
    rotate([0, 90, 0])
        cylinder(d = 3, h = CRANK_RADIUS + 5, center = true, $fn = 12);

    // Eccentric pin (at computed position)
    color(C_PIN)
    translate([ecc_pin_x(i, th), ecc_pin_y(i, th), ecc_pin_z(i, th)])
        cylinder(d = PIN_DIA, h = PIN_HEIGHT, $fn = 12);
}

module crank_disc_assembly(th) {
    if (SHOW_DISC) {
        // Central drive ring (connects all eccentrics via gear train)
        color(C_DISC, 0.4)
        translate([0, 0, CRANK_Z - CRANK_DISC_H])
        difference() {
            cylinder(r = FOLLOWER_R + 8, h = 2, $fn = 64);
            translate([0, 0, -0.1])
                cylinder(r = FOLLOWER_R - 8, h = 2.2, $fn = 64);
        }

        // 16 individual eccentric discs
        for (i = [0 : N_SLATS - 1])
            eccentric_disc_single(i, th);
    }
}

// ============================================
// MODULES: CONNECTING RODS
// ============================================

module single_connecting_rod(i, th) {
    s = rod_start(i, th);
    e = rod_end(i, th);

    color(C_ROD)
    hull() {
        translate(s) sphere(d = ROD_WIDTH, $fn = 10);
        translate(e) sphere(d = ROD_WIDTH, $fn = 10);
    }
}

module connecting_rods(th) {
    if (SHOW_RODS) {
        for (i = [0 : N_SLATS - 1])
            single_connecting_rod(i, th);
    }
}

// ============================================
// MODULES: FOLLOWER RODS
// ============================================

module single_follower(i, th) {
    fz = follower_z_abs(i, th);

    color(C_FOLLOW)
    translate([follower_fx(i), follower_fy(i), fz - FOLLOWER_LEN])
        cylinder(d = FOLLOWER_DIA, h = FOLLOWER_LEN, $fn = 12);
}

module followers(th) {
    if (SHOW_FOLLOWERS) {
        for (i = [0 : N_SLATS - 1])
            single_follower(i, th);
    }
}

// ============================================
// MODULES: SLAT WEDGE
// ============================================

module slat_2d() {
    n_pts = 12;
    half_ang = SLAT_ANG_WIDTH / 2;

    points = concat(
        [for (j = [0 : n_pts])
            let(a = -half_ang + j * SLAT_ANG_WIDTH / n_pts)
            [SLAT_INNER_R * cos(a), SLAT_INNER_R * sin(a)]
        ],
        [for (j = [n_pts : -1 : 0])
            let(a = -half_ang + j * SLAT_ANG_WIDTH / n_pts)
            [SLAT_OUTER_R * cos(a), SLAT_OUTER_R * sin(a)]
        ]
    );
    polygon(points);
}

module slat_wedge(i, th) {
    fz = follower_z_abs(i, th);
    dz = follower_dz(i, th);
    ang = follower_angle(i);
    tilt = slat_tilt(i, th);

    color(slat_color(dz, CRANK_RADIUS))
    translate([0, 0, fz])
    rotate([0, 0, ang])
    rotate([tilt, 0, 0])
    linear_extrude(height = SLAT_THICK)
        slat_2d();
}

module slat_ring(th) {
    if (SHOW_SLATS) {
        for (i = [0 : N_SLATS - 1])
            slat_wedge(i, th);
    }
}

// ============================================
// MODULES: GUIDE PLATE
// ============================================

module guide_plate() {
    if (SHOW_GUIDE) {
        color(C_GUIDE)
        translate([0, 0, GUIDE_Z - GUIDE_THICK])
        difference() {
            difference() {
                cylinder(r = GUIDE_OUTER_R, h = GUIDE_THICK, $fn = 64);
                translate([0, 0, -0.1])
                    cylinder(r = GUIDE_INNER_R, h = GUIDE_THICK + 0.2, $fn = 64);
            }
            for (i = [0 : N_SLATS - 1])
                rotate([0, 0, follower_angle(i)])
                translate([FOLLOWER_R, 0, -0.1])
                    cylinder(d = GUIDE_SLOT_W, h = GUIDE_THICK + 0.2, $fn = 12);
        }
    }
}

// ============================================
// MODULES: BASE FRAME
// ============================================

module base_frame() {
    if (SHOW_FRAME) {
        color(C_BASE)
        translate([0, 0, -BASE_THICK])
            cylinder(d = BASE_DIA, h = BASE_THICK, $fn = 64);

        color(C_PILLAR)
        for (p = [0 : N_PILLARS - 1]) {
            a = p * (360 / N_PILLARS) + 45;
            translate([(GUIDE_OUTER_R + 5) * cos(a),
                       (GUIDE_OUTER_R + 5) * sin(a), 0])
                cylinder(d = PILLAR_DIA, h = GUIDE_Z, $fn = 16);
        }

        color(C_PILLAR)
        translate([0, 0, -BASE_THICK - MOTOR_H])
            cylinder(d = MOTOR_DIA, h = MOTOR_H, $fn = 24);
    }
}

// ============================================
// MODULES: CENTRAL SHAFT
// ============================================

module central_shaft(th) {
    if (SHOW_SHAFT) {
        color(C_SHAFT) {
            cylinder(d = SHAFT_DIA, h = CRANK_Z + 2, $fn = 24);
            rotate([0, 0, th])
            translate([0, -0.8, CRANK_Z - 2])
                cube([SHAFT_DIA + 2, 1.6, 4]);
        }
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module radial_crank_wave() {
    base_frame();
    central_shaft(theta);
    crank_disc_assembly(theta);
    connecting_rods(theta);
    guide_plate();
    followers(theta);
    slat_ring(theta);
}

radial_crank_wave();

// ============================================
// POWER PATH VERIFICATION
// ============================================

echo("=== POWER PATH ===");
echo("Motor → Shaft → Ring gear → 16 eccentric discs → Pins → Rods → Followers → Slats");
echo("Each follower Z = CRANK_RADIUS * sin(theta - phase_i)");
echo("=== END POWER PATH ===");

// ============================================
// PHYSICS VERIFICATION
// ============================================

echo("=== PHYSICS CHECK ===");
echo(str("Cranks: ", N_SLATS, " at ", PHASE_STEP, "° spacing"));
echo(str("Wave amplitude: ±", CRANK_RADIUS, "mm"));
echo(str("Eccentric disc radius: ", CRANK_RADIUS, "mm at r=", FOLLOWER_R, "mm"));
echo(str("Current theta: ", round(theta), "°"));

// Cardinal Z values
echo(str("Follower dZ — ",
    "0:", round(follower_dz(0, theta) * 10) / 10, " ",
    "4:", round(follower_dz(4, theta) * 10) / 10, " ",
    "8:", round(follower_dz(8, theta) * 10) / 10, " ",
    "12:", round(follower_dz(12, theta) * 10) / 10, "mm"));

// Rod length verification — should be nearly constant now
_rod0_0   = rod_length_calc(0, 0);
_rod0_90  = rod_length_calc(0, 90);
_rod0_180 = rod_length_calc(0, 180);
_rod0_270 = rod_length_calc(0, 270);
echo(str("Rod 0 length at θ=0,90,180,270: ",
    round(_rod0_0 * 10) / 10, ", ",
    round(_rod0_90 * 10) / 10, ", ",
    round(_rod0_180 * 10) / 10, ", ",
    round(_rod0_270 * 10) / 10, "mm"));
echo(str("Rod variation: ",
    round((max(_rod0_0, max(_rod0_90, max(_rod0_180, _rod0_270)))
         - min(_rod0_0, min(_rod0_90, min(_rod0_180, _rod0_270)))) * 10) / 10,
    "mm (should be < 1mm)"));

// Overlap check
_max_dz = 2 * CRANK_RADIUS * sin(PHASE_STEP / 2);
_med_r = (SLAT_INNER_R + SLAT_OUTER_R) / 2;
_overlap_arc = _med_r * SLAT_OVERLAP_DEG * 3.14159 / 180;
echo(str("Max adjacent Z diff: ", round(_max_dz * 10) / 10,
    "mm | Overlap arc: ", round(_overlap_arc * 10) / 10, "mm"));
echo("=== END PHYSICS ===");

// ============================================
// BUILD VOLUME
// ============================================

echo("=== BUILD VOLUME ===");
echo(str("Base: ", BASE_DIA, "mm dia"));
echo(str("Slats: R", SLAT_INNER_R, "→R", SLAT_OUTER_R, "mm"));
echo(str("Height: ~", GUIDE_Z + CRANK_RADIUS + SLAT_THICK + FOLLOWER_LEN, "mm"));
echo("=== END BUILD VOLUME ===");

// ============================================
// ANIMATION INSTRUCTIONS
// ============================================
// 1. Open in OpenSCAD → View → Animate
// 2. FPS: 30, Steps: 120
// 3. Watch the wave crest travel around the ring of slats
//
// DEBUGGING:
//    MANUAL_ANGLE = 0   → see phase distribution
//    MANUAL_ANGLE = 90  → verify wave rotates
//
// TUNING:
//    CRANK_RADIUS:      Wave amplitude (6mm = gentle, 10mm = dramatic)
//    N_SLATS:           More = smoother wave, more mechanism
//    SLAT_OVERLAP_DEG:  Overlap amount (4° = subtle, 8° = heavy shingle)
//    SLAT_OUTER_R:      Slat reach (larger = more surface)
//
// SHOW/HIDE:
//    SHOW_DISC = false  → hide mechanism, see only wave surface
//    SHOW_SLATS = false → see only the eccentric drives
