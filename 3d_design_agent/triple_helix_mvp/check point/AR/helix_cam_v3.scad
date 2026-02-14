// =========================================================
// HELIX CAM V3 — 13-Cam Eccentric Hub + Gravity Rib
// =========================================================
// Self-contained helix camshaft for HEX_R=118 matrix (13 channels).
// One cam per channel strip, stacked with progressive twist along shaft.
//
// Design lineage: helix_cam_v2 → V3 changes:
//   - NUM_CAMS: 5 → 13 (matching NUM_CHANNELS at HEX_R=118)
//   - TWIST_PER_CAM: 72° → 27.69° (360/13)
//   - AXIAL_PITCH: 8mm → 7mm (thinner collar: 3→2mm)
//   - HELIX_LENGTH: 40mm → 91mm (13×7)
//   - Gravity rib: arm 40→20mm, thick 5→4mm, width 6→5mm
//   - End plate: dia 30→22mm, thick 5→4mm
//   - Spacer collar: OD 15→12mm
//   - Self-contained: no config.scad dependency
//
// Coordinate system (helix local):
//   Shaft axis = Z (cams stacked along Z, Z=0 at first cam)
//   Cam orbit plane = XY
//   Gravity rib extends in -X (toward matrix center when positioned)
//
// Hub attachment: press-fit + M3 set screw (no bolt pattern)
// Bearing: 6800ZZ (10/19/5mm) — kept from V2, minimum viable size
// =========================================================

$fn = 40;

// =============================================
// ANIMATION
// =============================================
MANUAL_POSITION = -1;
function anim_t() = (MANUAL_POSITION >= 0) ? MANUAL_POSITION : $t;

// =============================================
// HEX GEOMETRY (for NUM_CHANNELS derivation)
// =============================================
HEX_R        = 118;    // matched to matrix_tier_v3
STACK_OFFSET = 14.0;
HEX_FF       = HEX_R * sqrt(3);
function _half_count() = floor((HEX_FF/2 - STACK_OFFSET/2) / STACK_OFFSET);
NUM_CHANNELS = 2 * _half_count() + 1;  // 13 (at HEX_R=118)

// =============================================
// CAM PARAMETERS
// =============================================
NUM_CAMS      = NUM_CHANNELS;               // 13 (at HEX_R=118, STACK_OFFSET=14)
TWIST_PER_CAM = 360.0 / NUM_CAMS;          // 27.69°
ECCENTRICITY  = 15.0;                       // mm cam throw (±15mm)
CAM_STROKE    = 2 * ECCENTRICITY;           // 24mm peak-to-peak

// =============================================
// BEARING — 6800ZZ (kept from V2)
// =============================================
BEARING_ID    = 10.0;
BEARING_OD    = 19.0;
BEARING_W     = 5.0;

// =============================================
// SHAFT & PIN
// =============================================
SHAFT_DIA     = 10.0;      // matches bearing ID
CENTER_PIN_DIA = 5.0;      // alignment pin through hub centers
SETSCREW_DIA  = 3.0;       // M3 set screw (radial, through web)

// =============================================
// AXIAL STACK
// =============================================
COLLAR_THICK  = 9.0;       // sized so AXIAL_PITCH = STACK_OFFSET (14mm)
AXIAL_PITCH   = BEARING_W + COLLAR_THICK;  // 5+9 = 14mm per cam = STACK_OFFSET
HELIX_LENGTH  = NUM_CAMS * AXIAL_PITCH;    // 13×14 = 182mm

// =============================================
// ECCENTRIC HUB
// =============================================
HUB_PRESS_FIT = 0.1;       // interference fit for bearing seat
HUB_BODY_DIA  = BEARING_ID - HUB_PRESS_FIT;  // 9.9mm
CENTER_BOSS_DIA = CENTER_PIN_DIA + 4;  // 9mm boss around pin
KEEPER_LIP_DIA  = BEARING_ID + 2;  // 12mm keeper lip
KEEPER_LIP_H    = 0.8;     // axial retention

// Soft stop bumps at ±SOFT_STOP_ANGLE (limits rib swing)
SOFT_STOP_ANGLE = 15;      // degrees from neutral

// =============================================
// GRAVITY RIB (Cam Follower Arm) — SCALED DOWN
// =============================================
RIB_ARM_LENGTH  = 20.0;    // was 40 — shorter reach toward matrix
RIB_THICK       = 4.0;     // was 5
RIB_ARM_WIDTH   = 5.0;     // was 6
RIB_TAPER_TIP   = 3.0;     // was 4
RIB_EYELET_DIA  = 1.5;     // was 2 — sized for 0.5mm Dyneema
RIB_RING_OD     = BEARING_OD + 8;  // 27mm (was +10=29mm)
GUIDE_SLOT_W    = 2.0;
GUIDE_SLOT_H    = 15.0;    // was 20 — proportional to smaller rib

// =============================================
// END PLATE — SCALED DOWN
// =============================================
END_PLATE_DIA   = 22.0;    // was 30
END_PLATE_THICK = 4.0;     // was 5
END_PLATE_ARM   = 30.0;    // was 40 — extension to drive shaft
DRIVE_BORE_DIA  = 8.0;     // drive shaft bore at arm end

// =============================================
// SPACER COLLAR — SCALED DOWN
// =============================================
COLLAR_OD       = 12.0;    // was 15

// =============================================
// HELIX POSITIONING (world-space)
// =============================================
HOUSING_HEIGHT  = 30.0;    // tier display height (matching matrix)
TIER_PITCH      = HOUSING_HEIGHT;
TIER_ANGLES     = [0, 120, 240];
HELIX_VERTEX_ANGLES = [180, 300, 60];  // opposite vertices
HELIX_DISTANCE  = 60.0;    // mm from hex edge to shaft center (15° max rope angle)

// =============================================
// COLORS
// =============================================
C_HUB     = [0.3, 0.6, 0.9, 0.9];
C_RIB     = [0.8, 0.5, 0.2, 0.9];
C_COLLAR  = [0.6, 0.6, 0.6, 0.5];
C_STEEL   = [0.7, 0.7, 0.75, 1.0];
C_ENDPLT  = [0.5, 0.5, 0.55, 0.9];

// =============================================
// DISPLAY TOGGLES
// =============================================
/* [Visibility] */
SHOW_HUBS       = true;
SHOW_RIBS       = true;
SHOW_COLLARS    = true;
SHOW_END_PLATES = true;
SHOW_CENTER_PIN = true;

// =============================================
// VERIFICATION
// =============================================
echo(str("=== HELIX CAM V3 ==="));
echo(str("Cams: ", NUM_CAMS, " | Twist/cam: ", round(TWIST_PER_CAM*100)/100, "°"));
echo(str("Eccentricity: ", ECCENTRICITY, "mm | Stroke: ", CAM_STROKE, "mm"));
echo(str("Axial pitch: ", AXIAL_PITCH, "mm | Length: ", HELIX_LENGTH, "mm"));
echo(str("Bearing: 6800ZZ (", BEARING_ID, "/", BEARING_OD, "/", BEARING_W, ")"));
echo(str("Rib: arm=", RIB_ARM_LENGTH, " thick=", RIB_THICK, " ring_OD=", RIB_RING_OD));
echo(str("End plate: dia=", END_PLATE_DIA, " thick=", END_PLATE_THICK));

// Max radial extent: eccentricity + bearing_OD/2 + rib_ring_extra/2
_max_radial = ECCENTRICITY + RIB_RING_OD/2;
echo(str("Max radial envelope: ", _max_radial, "mm (hub center to rib OD)"));
echo(str("Max reach: ", _max_radial + RIB_ARM_LENGTH, "mm (hub center to rib tip)"));

// =============================================
// STANDALONE RENDER
// =============================================
helix_assembly_v3(anim_t());


// =========================================================
// HELIX ASSEMBLY — 11 cams + ribs along shaft (Z-axis)
// =========================================================
module helix_assembly_v3(t = 0) {
    crank_angle = t * 360;

    for (i = [0 : NUM_CAMS - 1]) {
        cam_angle = crank_angle + i * TWIST_PER_CAM;
        z_pos = i * AXIAL_PITCH;

        translate([0, 0, z_pos]) {
            // Eccentric hub (rotates with shaft)
            if (SHOW_HUBS)
                rotate([0, 0, cam_angle])
                    eccentric_hub_v3();

            // Gravity rib (rides on bearing OD, hangs by gravity)
            // Rib center follows eccentric offset
            if (SHOW_RIBS) {
                ecc_x = ECCENTRICITY * cos(cam_angle);
                ecc_y = ECCENTRICITY * sin(cam_angle);
                translate([ecc_x, ecc_y, 0])
                    gravity_rib_v3();
            }

            // Spacer collar between cams (except after last)
            if (SHOW_COLLARS && i < NUM_CAMS - 1)
                translate([0, 0, BEARING_W])
                    spacer_collar_v3();
        }
    }

    // End plates
    if (SHOW_END_PLATES) {
        // Bottom end plate below first cam
        translate([0, 0, -END_PLATE_THICK - 3])
            end_plate_v3();
        // Top end plate above last cam
        translate([0, 0, HELIX_LENGTH])
            end_plate_v3();
    }

    // Center alignment pin — spans full assembly
    if (SHOW_CENTER_PIN)
        color(C_STEEL)
        translate([0, 0, -END_PLATE_THICK - 5])
            cylinder(d = CENTER_PIN_DIA, h = HELIX_LENGTH + 2 * END_PLATE_THICK + 10, $fn = 20);
}


// =========================================================
// POSITIONED HELIX — world-space placement for a tier
// =========================================================
// tier_idx: 0, 1, or 2
// Shaft runs perpendicular to tier's slider direction,
// positioned at hex vertex opposite the slider entry side.

module helix_positioned_v3(tier_idx, t = 0) {
    tier_angle = TIER_ANGLES[tier_idx];
    vertex_angle = HELIX_VERTEX_ANGLES[tier_idx];

    // Radial distance from matrix center to helix shaft
    helix_r = HEX_R + HELIX_DISTANCE;

    // Position at the opposite vertex
    hx = helix_r * cos(vertex_angle);
    hy = helix_r * sin(vertex_angle);

    // Z-height matches tier center
    tier_z = (1 - tier_idx) * TIER_PITCH;

    // Shaft orientation: perpendicular to slider direction
    shaft_angle = tier_angle + 90;

    translate([hx, hy, tier_z]) {
        rotate([0, 0, shaft_angle])
            rotate([0, 90, 0])
                // Center helix on its midpoint
                translate([0, 0, -HELIX_LENGTH/2])
                    helix_assembly_v3(t);
    }
}


// =========================================================
// ECCENTRIC HUB ("Salami Slice" Cam Disc)
// =========================================================
// Cross-section (looking down Z):
//   Center pin (0,0) ←—— web ——→ Hub body (ECCENTRICITY, 0)
//
// The hub body is a press-fit seat for the bearing inner race.
// The structural web bridges the gap from center pin to hub.

module eccentric_hub_v3() {
    color(C_HUB)
    difference() {
        union() {
            // Hub body at eccentric offset (bearing press-fit seat)
            translate([ECCENTRICITY, 0, 0])
                cylinder(d = HUB_BODY_DIA, h = BEARING_W, $fn = 60);

            // Keeper lip (retains bearing axially)
            translate([ECCENTRICITY, 0, 0])
                cylinder(d = KEEPER_LIP_DIA, h = KEEPER_LIP_H, $fn = 60);

            // Structural web — hull from center boss to hub body
            hull() {
                cylinder(d = CENTER_BOSS_DIA, h = BEARING_W, $fn = 30);
                translate([ECCENTRICITY, 0, 0])
                    cylinder(d = HUB_BODY_DIA, h = BEARING_W, $fn = 60);
            }
        }

        // Center pin hole
        translate([0, 0, -1])
            cylinder(d = CENTER_PIN_DIA + 0.2, h = BEARING_W + 2, $fn = 20);

        // Set screw hole (radial, through web into center pin)
        translate([ECCENTRICITY/2, 0, BEARING_W/2])
            rotate([0, 90, 0])
                cylinder(d = SETSCREW_DIA, h = ECCENTRICITY, $fn = 16);

        // Soft stop notches at ±SOFT_STOP_ANGLE
        for (sa = [-SOFT_STOP_ANGLE, SOFT_STOP_ANGLE]) {
            translate([ECCENTRICITY + (HUB_BODY_DIA/2 - 1) * cos(sa),
                       (HUB_BODY_DIA/2 - 1) * sin(sa), -1])
                cylinder(d = 2.5, h = BEARING_W + 2, $fn = 12);
        }
    }
}


// =========================================================
// GRAVITY RIB (Cam Follower Arm) — Scaled Down
// =========================================================
// Rides on bearing outer race, hangs by gravity.
// Arm extends toward matrix center (-X when positioned).
// Cable eyelet at tip connects to slider via Dyneema string.

module gravity_rib_v3() {
    arm_reach = BEARING_OD/2 + RIB_ARM_LENGTH;

    color(C_RIB)
    difference() {
        union() {
            // Bearing ring (sits on bearing outer race)
            difference() {
                cylinder(d = RIB_RING_OD, h = RIB_THICK, center = true, $fn = 40);
                cylinder(d = BEARING_OD + 0.2, h = RIB_THICK + 2, center = true, $fn = 40);
            }

            // Arm extending toward matrix center (-X)
            translate([-arm_reach/2 - BEARING_OD/2, 0, 0])
                cube([arm_reach, RIB_ARM_WIDTH, RIB_THICK], center = true);

            // Taper at tip
            translate([-arm_reach - BEARING_OD/2 + RIB_TAPER_TIP/2, 0, 0])
                cylinder(d = RIB_TAPER_TIP, h = RIB_THICK, center = true, $fn = 16);
        }

        // Cable eyelet at arm tip
        translate([-arm_reach - BEARING_OD/2 + RIB_TAPER_TIP/2, 0, 0])
            cylinder(d = RIB_EYELET_DIA, h = RIB_THICK + 2, center = true, $fn = 16);

        // Anti-rotation guide slot
        translate([-(BEARING_OD/2 + 10), -GUIDE_SLOT_W/2, -GUIDE_SLOT_H/2])
            cube([20, GUIDE_SLOT_W, GUIDE_SLOT_H]);
    }
}


// =========================================================
// SPACER COLLAR — Thinner ring between adjacent cams
// =========================================================
module spacer_collar_v3() {
    color(C_COLLAR)
    difference() {
        cylinder(d = COLLAR_OD, h = COLLAR_THICK, $fn = 30);
        translate([0, 0, -1])
            cylinder(d = CENTER_PIN_DIA + 0.4, h = COLLAR_THICK + 2, $fn = 20);
    }
}


// =========================================================
// END PLATE — Connects helix to drive shaft (scaled down)
// =========================================================
module end_plate_v3() {
    color(C_ENDPLT)
    difference() {
        union() {
            // Circular flange
            cylinder(d = END_PLATE_DIA, h = END_PLATE_THICK, $fn = 40);

            // Extension arm to drive shaft connection
            translate([0, -8, 0])
                cube([END_PLATE_ARM, 16, END_PLATE_THICK]);
        }

        // Center pin hole
        translate([0, 0, -1])
            cylinder(d = CENTER_PIN_DIA + 0.2, h = END_PLATE_THICK + 2, $fn = 20);

        // Set screw hole (radial)
        translate([0, 0, END_PLATE_THICK/2])
            rotate([0, 90, 0])
                cylinder(d = SETSCREW_DIA, h = END_PLATE_DIA, $fn = 16);

        // Drive shaft bore at arm end
        translate([END_PLATE_ARM - 5, 0, -1])
            cylinder(d = DRIVE_BORE_DIA, h = END_PLATE_THICK + 2, $fn = 20);
    }
}
