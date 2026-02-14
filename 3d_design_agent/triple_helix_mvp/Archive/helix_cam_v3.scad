// =========================================================
// HELIX CAM V3 — Pinless Eccentric Disc Camshaft
// =========================================================
// Self-contained helix camshaft for HEX_R=118 matrix (13 channels).
// One cam per channel, stacked with progressive twist along shaft.
//
// PINLESS DESIGN: No central pin or shaft through the cam stack.
//   Each disc is an eccentric body with bearing seat on its OD.
//   Discs bolt face-to-face (M3 × 3), each rotated TWIST_PER_CAM
//   from the previous. The disc stack IS the shaft.
//
// Assembly sequence (per disc):
//   1. Press bearing (6800ZZ) onto bearing seat boss
//   2. Install rib onto bearing outer race
//   3. Align bolt holes with previous disc (rotated by TWIST_PER_CAM)
//   4. Fasten with 3× M3 bolts through clearance holes into tapped holes
//
// End discs have shaft journal stubs (10mm × 10mm) for frame
// bearing mounts. Drive end also has GT2 pulley boss.
//
// Coordinate system (helix local):
//   Shaft axis = Z (discs stacked along Z, Z=0 at first disc)
//   Cam orbit plane = XY
//   Disc geometric center = (0,0) — bolt circle center
//   Bearing seat at (ECCENTRICITY, 0) in disc-local coords
//   Gravity rib extends in -X (toward matrix when positioned)
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
NUM_CAMS      = NUM_CHANNELS;               // 13
TWIST_PER_CAM = 360.0 / NUM_CAMS;          // 27.69°
ECCENTRICITY  = 15.0;                       // mm cam throw (±15mm)
CAM_STROKE    = 2 * ECCENTRICITY;           // 30mm peak-to-peak

// =============================================
// BEARING — 6800ZZ
// =============================================
BEARING_ID    = 10.0;
BEARING_OD    = 19.0;
BEARING_W     = 5.0;

// =============================================
// PINLESS DISC PARAMETERS
// =============================================
// Disc body: hull of center boss + eccentric bearing seat boss
// Bearing seat is at (ECCENTRICITY, 0) in disc-local coordinates.
// Center boss (0,0) houses the bolt circle.

DISC_CENTER_DIA   = 20.0;    // center boss diameter (holds bolt circle)
BEARING_SEAT_DIA  = BEARING_ID - 0.1;  // 9.9mm press-fit for bearing IR
KEEPER_LIP_DIA    = BEARING_ID + 2;    // 12mm axial retention lip
KEEPER_LIP_H      = 0.8;     // lip height

// Disc thickness: bearing zone + flange
BEARING_ZONE_H    = BEARING_W;          // 5mm — bearing sits here
FLANGE_H          = STACK_OFFSET - BEARING_W;  // 9mm — bolt engagement + structure
DISC_THICK        = BEARING_ZONE_H + FLANGE_H; // 14mm = AXIAL_PITCH
AXIAL_PITCH       = DISC_THICK;         // 14mm per disc = STACK_OFFSET
HELIX_LENGTH      = NUM_CAMS * AXIAL_PITCH;    // 182mm

// =============================================
// BOLT PATTERN — 3× M3 on bolt circle
// =============================================
NUM_BOLTS         = 3;
BOLT_DIA          = 3.0;       // M3
BOLT_CLEARANCE    = 3.4;       // clearance hole for M3
BOLT_HEAD_DIA     = 5.5;       // M3 socket head cap
BOLT_HEAD_H       = 3.0;       // M3 head height
BOLT_CIRCLE_R     = 7.0;       // bolt circle radius from disc center
                                // Clears center (min 3.5mm to bolt edge)
                                // Stays inside DISC_CENTER_DIA/2 = 10mm

// Bolt engagement depth (threads into next disc's flange)
BOLT_ENGAGE       = FLANGE_H - 1.0;  // 8mm thread engagement (M3 in PLA: safe)

// =============================================
// GRAVITY RIB (Cam Follower Arm)
// =============================================
RIB_ARM_LENGTH  = 20.0;
RIB_THICK       = 4.0;
RIB_ARM_WIDTH   = 5.0;
RIB_TAPER_TIP   = 3.0;
RIB_EYELET_DIA  = 1.5;        // sized for 0.5mm Dyneema
RIB_RING_OD     = BEARING_OD + 8;  // 27mm
GUIDE_SLOT_W    = 2.0;
GUIDE_SLOT_H    = 15.0;

// =============================================
// END DISC — Shaft Journals + GT2
// =============================================
// End discs have a shaft journal (10mm dia) for frame 6800ZZ bearings.
JOURNAL_DIA       = BEARING_ID;    // 10mm — fits frame bearing bore
JOURNAL_LENGTH    = 10.0;          // stub length beyond disc face

// GT2 pulley on drive end journal
GT2_TEETH       = 20;
GT2_PD          = GT2_TEETH * 2 / PI;     // 12.73mm
GT2_OD          = GT2_PD + 1.5;           // ~14.2mm
GT2_BOSS_H      = 8;

// =============================================
// HELIX POSITIONING (world-space)
// =============================================
HOUSING_HEIGHT  = 30.0;
TIER_PITCH      = HOUSING_HEIGHT;
TIER_ANGLES     = [0, 120, 240];
HELIX_VERTEX_ANGLES = [180, 300, 60];
HELIX_DISTANCE  = 60.0;

// =============================================
// COLORS
// =============================================
C_DISC    = [0.3, 0.6, 0.9, 0.9];
C_RIB     = [0.8, 0.5, 0.2, 0.9];
C_STEEL   = [0.7, 0.7, 0.75, 1.0];
C_BEARING = [0.5, 0.5, 0.55, 0.7];
C_ENDPLT  = [0.5, 0.5, 0.55, 0.9];
C_BOLT    = [0.3, 0.3, 0.3, 1.0];

// =============================================
// DISPLAY TOGGLES
// =============================================
/* [Visibility] */
SHOW_DISCS      = true;
SHOW_BEARINGS   = true;
SHOW_RIBS       = true;
SHOW_BOLTS      = true;
SHOW_END_DISCS  = true;

// =============================================
// VERIFICATION
// =============================================
echo(str("=== HELIX CAM V3 — PINLESS ==="));
echo(str("Cams: ", NUM_CAMS, " | Twist/cam: ", round(TWIST_PER_CAM*100)/100, "°"));
echo(str("Eccentricity: ", ECCENTRICITY, "mm | Stroke: ", CAM_STROKE, "mm"));
echo(str("Disc thick: ", DISC_THICK, "mm (bearing=", BEARING_ZONE_H, " + flange=", FLANGE_H, ")"));
echo(str("Axial pitch: ", AXIAL_PITCH, "mm | Total length: ", HELIX_LENGTH, "mm"));
echo(str("Bearing: 6800ZZ (", BEARING_ID, "/", BEARING_OD, "/", BEARING_W, ")"));
echo(str("Bolt circle: R=", BOLT_CIRCLE_R, "mm, ", NUM_BOLTS, "× M", BOLT_DIA));
echo(str("Rib: arm=", RIB_ARM_LENGTH, " thick=", RIB_THICK, " ring_OD=", RIB_RING_OD));
echo(str("Journal: dia=", JOURNAL_DIA, "mm len=", JOURNAL_LENGTH, "mm"));
echo(str("GT2 boss: ", GT2_TEETH, "T PD=", round(GT2_PD*10)/10, "mm"));

// Radial envelope
_max_radial = ECCENTRICITY + RIB_RING_OD/2;
echo(str("Max radial envelope: ", _max_radial, "mm (disc center to rib OD)"));
echo(str("Max reach: ", _max_radial + RIB_ARM_LENGTH, "mm (disc center to rib tip)"));

// Bolt clearance check: bolt edge to bearing seat edge
_bolt_to_bearing = ECCENTRICITY - BOLT_CIRCLE_R - BOLT_HEAD_DIA/2 - BEARING_SEAT_DIA/2;
echo(str("Bolt-to-bearing clearance: ", round(_bolt_to_bearing*10)/10, "mm",
         (_bolt_to_bearing >= 1.0 ? " ✓" : " ⚠ TIGHT")));

// Bolt engagement check
echo(str("Bolt engagement: ", BOLT_ENGAGE, "mm (need ≥2×dia=", 2*BOLT_DIA, "mm)",
         (BOLT_ENGAGE >= 2*BOLT_DIA ? " ✓" : " ⚠ SHORT")));

// =============================================
// STANDALONE RENDER
// =============================================
helix_assembly_v3(anim_t());


// =========================================================
// HELIX ASSEMBLY — 13 pinless discs + bearings + ribs
// =========================================================
module helix_assembly_v3(t = 0) {
    crank_angle = t * 360;

    for (i = [0 : NUM_CAMS - 1]) {
        cam_angle = crank_angle + i * TWIST_PER_CAM;
        z_pos = i * AXIAL_PITCH;

        translate([0, 0, z_pos]) {
            // Eccentric disc (rotates as unit)
            if (SHOW_DISCS)
                rotate([0, 0, cam_angle])
                    eccentric_disc_v3(
                        is_first = (i == 0),
                        is_last = (i == NUM_CAMS - 1)
                    );

            // Bearing on disc's eccentric boss (in bearing zone)
            if (SHOW_BEARINGS) {
                ecc_x = ECCENTRICITY * cos(cam_angle);
                ecc_y = ECCENTRICITY * sin(cam_angle);
                translate([ecc_x, ecc_y, FLANGE_H])
                    _bearing_6800zz();
            }

            // Gravity rib rides on bearing outer race
            if (SHOW_RIBS) {
                ecc_x = ECCENTRICITY * cos(cam_angle);
                ecc_y = ECCENTRICITY * sin(cam_angle);
                translate([ecc_x, ecc_y, FLANGE_H + BEARING_W/2])
                    gravity_rib_v3();
            }

            // Bolts connecting this disc to the next
            if (SHOW_BOLTS && i < NUM_CAMS - 1)
                rotate([0, 0, cam_angle])
                    _bolt_set();
        }
    }
}


// =========================================================
// ECCENTRIC DISC — Pinless cam body
// =========================================================
// Cross-section: hull of center boss (0,0) + bearing seat (ECC,0)
// Bearing zone on top (Z=0..BEARING_W), flange below (Z=-FLANGE_H..0)
//
// Assembly direction: stack builds in +Z
//   - Flange zone: Z = 0 to FLANGE_H (tapped holes for bolts from disc below)
//   - Bearing zone: Z = FLANGE_H to DISC_THICK (exposed seat for bearing)
//
// is_first: adds shaft journal extending in -Z (non-drive end)
// is_last:  adds shaft journal + GT2 pulley extending in +Z (drive end)

module eccentric_disc_v3(is_first = false, is_last = false) {
    color(C_DISC)
    difference() {
        union() {
            // Main disc body: hull of center boss + bearing seat boss
            hull() {
                // Center boss (bolt circle host)
                cylinder(d = DISC_CENTER_DIA, h = DISC_THICK, $fn = 40);
                // Bearing seat boss (extends to bearing zone)
                translate([ECCENTRICITY, 0, 0])
                    cylinder(d = BEARING_SEAT_DIA + 4, h = DISC_THICK, $fn = 40);
            }

            // Bearing seat boss — precise diameter for press fit
            translate([ECCENTRICITY, 0, FLANGE_H])
                cylinder(d = BEARING_SEAT_DIA, h = BEARING_ZONE_H, $fn = 60);

            // Keeper lip (retains bearing axially — on top face)
            translate([ECCENTRICITY, 0, FLANGE_H + BEARING_ZONE_H - KEEPER_LIP_H])
                cylinder(d = KEEPER_LIP_DIA, h = KEEPER_LIP_H, $fn = 60);

            // Shaft journal on first disc (non-drive end, extends -Z)
            if (is_first)
                translate([0, 0, -JOURNAL_LENGTH])
                    cylinder(d = JOURNAL_DIA, h = JOURNAL_LENGTH, $fn = 40);

            // Shaft journal + GT2 on last disc (drive end, extends +Z)
            if (is_last) {
                translate([0, 0, DISC_THICK])
                    cylinder(d = JOURNAL_DIA, h = JOURNAL_LENGTH, $fn = 40);
                translate([0, 0, DISC_THICK + JOURNAL_LENGTH])
                    gt2_pulley_boss();
            }
        }

        // Bolt clearance holes (through full disc, from bottom face)
        // These accept bolts from the disc BELOW this one
        for (b = [0 : NUM_BOLTS - 1]) {
            ba = b * (360 / NUM_BOLTS);
            bx = BOLT_CIRCLE_R * cos(ba);
            by = BOLT_CIRCLE_R * sin(ba);
            // Clearance through-hole in flange zone
            translate([bx, by, -1])
                cylinder(d = BOLT_CLEARANCE, h = FLANGE_H + 2, $fn = 16);
            // Counterbore for bolt head on bottom face
            translate([bx, by, -1])
                cylinder(d = BOLT_HEAD_DIA + 0.5, h = BOLT_HEAD_H + 1, $fn = 20);
        }

        // Tapped holes for bolts from disc ABOVE (in bearing zone top face)
        // The next disc's bolt pattern is rotated by TWIST_PER_CAM
        // So tapped holes here match the NEXT disc's clearance holes
        for (b = [0 : NUM_BOLTS - 1]) {
            ba = b * (360 / NUM_BOLTS) + TWIST_PER_CAM;
            bx = BOLT_CIRCLE_R * cos(ba);
            by = BOLT_CIRCLE_R * sin(ba);
            translate([bx, by, DISC_THICK - BOLT_ENGAGE])
                cylinder(d = BOLT_DIA * 0.85, h = BOLT_ENGAGE + 1, $fn = 16);
        }
    }
}


// =========================================================
// BEARING 6800ZZ — visual representation
// =========================================================
module _bearing_6800zz() {
    color(C_BEARING)
    difference() {
        cylinder(d = BEARING_OD, h = BEARING_W, $fn = 40);
        translate([0, 0, -1])
            cylinder(d = BEARING_ID, h = BEARING_W + 2, $fn = 40);
    }
}


// =========================================================
// BOLT SET — 3× M3 bolts for visual reference
// =========================================================
// Drawn at disc-local coordinates of the UPPER disc (disc i+1)
// Bolts go through disc i+1's flange clearance holes, down into disc i's tapped holes
// Note: rendered at disc i's Z position, in disc i's local rotation
module _bolt_set() {
    color(C_BOLT)
    for (b = [0 : NUM_BOLTS - 1]) {
        // Bolt angles match the NEXT disc's clearance pattern
        // In current disc's frame, that's offset by TWIST_PER_CAM
        ba = b * (360 / NUM_BOLTS) + TWIST_PER_CAM;
        bx = BOLT_CIRCLE_R * cos(ba);
        by = BOLT_CIRCLE_R * sin(ba);
        // Bolt sits in next disc (i+1) at Z = AXIAL_PITCH
        // Head in next disc's flange counterbore, shaft threads into this disc's top
        translate([bx, by, DISC_THICK - BOLT_ENGAGE]) {
            // Bolt shaft (goes up through next disc's flange + engages into this disc)
            cylinder(d = BOLT_DIA, h = BOLT_ENGAGE + FLANGE_H, $fn = 12);
            // Bolt head (at bottom of next disc's flange counterbore)
            translate([0, 0, BOLT_ENGAGE + FLANGE_H - BOLT_HEAD_H])
                cylinder(d = BOLT_HEAD_DIA, h = BOLT_HEAD_H, $fn = 16);
        }
    }
}


// =========================================================
// GRAVITY RIB (Cam Follower Arm)
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
// GT2 PULLEY BOSS — simplified 20T GT2 timing pulley
// =========================================================
module gt2_pulley_boss() {
    color(C_ENDPLT) {
        cylinder(d = GT2_OD, h = GT2_BOSS_H, $fn = 40);
        cylinder(d = GT2_OD + 3, h = 1, $fn = 40);
        translate([0, 0, GT2_BOSS_H - 1])
            cylinder(d = GT2_OD + 3, h = 1, $fn = 40);
    }
}


// =========================================================
// POSITIONED HELIX — world-space placement for a tier
// =========================================================
module helix_positioned_v3(tier_idx, t = 0) {
    tier_angle = TIER_ANGLES[tier_idx];
    vertex_angle = HELIX_VERTEX_ANGLES[tier_idx];
    helix_r = HEX_R + HELIX_DISTANCE;
    hx = helix_r * cos(vertex_angle);
    hy = helix_r * sin(vertex_angle);
    tier_z = (1 - tier_idx) * TIER_PITCH;
    shaft_angle = tier_angle + 90;

    translate([hx, hy, tier_z]) {
        rotate([0, 0, shaft_angle])
            rotate([0, 90, 0])
                translate([0, 0, -HELIX_LENGTH/2])
                    helix_assembly_v3(t);
    }
}
