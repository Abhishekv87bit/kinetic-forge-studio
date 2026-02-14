// =========================================================
// HELIX CAM V4 — True Shaftless Eccentric Disc Camshaft
// =========================================================
// Standards: ISO 128 (technical drawing), DFAM (3D print design)
//
// TRUE SHAFTLESS DESIGN: No center boss, no center shaft, no hub.
//   Each disc is a single eccentric cylinder (DISC_OD) centered at
//   (ECCENTRICITY, 0) in local rotation frame. The rotation axis
//   (0,0) passes through empty space. Progressive rotation of
//   identical offset discs creates the helical wave pattern.
//
//   13 discs x 27.69 deg/disc = 360 deg = one full wave.
//   Disc 0 and disc 12 eccentric seats point the same direction.
//   Three helixes at [180, 300, 60] deg offset = traveling wave.
//
// Assembly sequence (per disc):
//   1. Press bearing (6800ZZ) onto bearing seat
//   2. Install gravity rib onto bearing outer race
//   3. Rotate disc by TWIST_PER_CAM from previous
//   4. Bolt face-to-face with 3x M3 through disc body
//
// End discs: thin web bridges from disc body to journal stub at
//   rotation axis (0,0) for frame bearing mounts. Drive end also
//   gets GT2 pulley on the journal.
//
// Coordinate system (helix local):
//   Rotation axis = Z through (0,0)
//   Disc body centered at (ECCENTRICITY, 0) — rotates with crank
//   Shaft axis = Z (discs stacked along Z, Z=0 at first disc)
// =========================================================

include <config_v4.scad>

$fn = 40;

// =============================================
// DISPLAY TOGGLES
// =============================================
/* [Visibility] */
SHOW_DISCS      = true;
SHOW_BEARINGS   = true;
SHOW_RIBS       = true;
SHOW_BOLTS      = true;

// =============================================
// VERIFICATION
// =============================================
echo(str("=== HELIX CAM V4 — TRUE SHAFTLESS ==="));
echo(str("Cams: ", NUM_CAMS, " | Twist/cam: ", round(TWIST_PER_CAM*100)/100, "deg"));
echo(str("Total twist: ", round(NUM_CAMS * TWIST_PER_CAM*10)/10, "deg (should be 360)"));
echo(str("Eccentricity: ", ECCENTRICITY, "mm | Stroke: ", CAM_STROKE, "mm"));
echo(str("Disc: OD=", DISC_OD, "mm centered at ECC=", ECCENTRICITY, "mm from rotation axis"));
echo(str("Disc thick: ", DISC_THICK, "mm (bearing=", BEARING_ZONE_H, " + flange=", FLANGE_H, ")"));
echo(str("Axial pitch: ", AXIAL_PITCH, "mm | Total length: ", HELIX_LENGTH, "mm"));
echo(str("Bearing: 6800ZZ (", BEARING_ID, "/", BEARING_OD, "/", BEARING_W, ")"));
echo(str("Bolt circle: R=", round(BOLT_CIRCLE_R*10)/10, "mm on disc body, ", NUM_BOLTS, "x M", BOLT_DIA));
echo(str("Journal: dia=", JOURNAL_DIA, "mm stub=", JOURNAL_LENGTH, "mm ext=", JOURNAL_EXT, "mm total=", JOURNAL_LENGTH+JOURNAL_EXT, "mm"));

// Envelope check
_max_reach = ECCENTRICITY + DISC_OD/2;
echo(str("Max radial from rotation axis: ", _max_reach, "mm (disc edge)"));
echo(str("Max reach with rib: ", ECCENTRICITY + BEARING_OD/2 + RIB_ARM_LENGTH, "mm"));

// Bolt clearances
_btb = BOLT_CIRCLE_R - BEARING_SEAT_DIA/2 - BOLT_HEAD_DIA/2;
_bte = DISC_OD/2 - BOLT_CIRCLE_R - BOLT_HEAD_DIA/2;
echo(str("Bolt-to-bearing: ", round(_btb*10)/10, "mm", (_btb >= 1.0 ? " ok" : " !! TIGHT")));
echo(str("Bolt-to-edge: ", round(_bte*10)/10, "mm", (_bte >= 1.0 ? " ok" : " !! TIGHT")));


// =============================================
// STANDALONE RENDER
// =============================================
helix_assembly_v4(anim_t());


// =========================================================
// HELIX ASSEMBLY — 13 shaftless eccentric discs
// =========================================================
module helix_assembly_v4(t = 0) {
    crank_angle = t * 360;

    for (i = [0 : NUM_CAMS - 1]) {
        cam_angle = crank_angle + i * TWIST_PER_CAM;
        z_pos = i * AXIAL_PITCH;

        translate([0, 0, z_pos]) {
            // Eccentric disc — rotates around (0,0), body at (ECC,0)
            if (SHOW_DISCS)
                rotate([0, 0, cam_angle])
                    eccentric_disc_v4(
                        is_first = (i == 0),
                        is_last = (i == NUM_CAMS - 1)
                    );

            // Bearing on disc's bearing seat
            if (SHOW_BEARINGS) {
                ecc_x = ECCENTRICITY * cos(cam_angle);
                ecc_y = ECCENTRICITY * sin(cam_angle);
                translate([ecc_x, ecc_y, FLANGE_H])
                    _bearing_6800zz();
            }

            // Gravity rib hangs from bearing outer race
            if (SHOW_RIBS) {
                ecc_x = ECCENTRICITY * cos(cam_angle);
                ecc_y = ECCENTRICITY * sin(cam_angle);
                translate([ecc_x, ecc_y, FLANGE_H + BEARING_W/2])
                    gravity_rib_v4();
            }

            // Bolts connecting this disc to the next
            if (SHOW_BOLTS && i < NUM_CAMS - 1)
                rotate([0, 0, cam_angle])
                    _bolt_set();
        }
    }
}


// =========================================================
// ECCENTRIC DISC — True shaftless cam body
// =========================================================
// Single cylinder at (ECCENTRICITY, 0). No center hub. No hull.
// Bolt holes drilled through the disc body.
//
// End discs add a thin web to journal at rotation axis (0,0).

module eccentric_disc_v4(is_first = false, is_last = false) {
    color(C_DISC)
    difference() {
        union() {
            // Main disc body — single eccentric cylinder
            translate([ECCENTRICITY, 0, 0])
                cylinder(d = DISC_OD, h = DISC_THICK, $fn = 48);

            // Bearing seat boss — precise diameter for press fit
            translate([ECCENTRICITY, 0, FLANGE_H])
                cylinder(d = BEARING_SEAT_DIA, h = BEARING_ZONE_H, $fn = 60);

            // Keeper lip (retains bearing axially)
            translate([ECCENTRICITY, 0, FLANGE_H + BEARING_ZONE_H - KEEPER_LIP_H])
                cylinder(d = KEEPER_LIP_DIA, h = KEEPER_LIP_H, $fn = 60);

            // End disc: web bridge from disc body to journal at rotation axis
            if (is_first || is_last) {
                // Web connecting disc center to rotation axis
                hull() {
                    translate([ECCENTRICITY, 0, 0])
                        cylinder(d = JOURNAL_WEB_W, h = JOURNAL_WEB_H, $fn = 20);
                    cylinder(d = JOURNAL_DIA + 4, h = JOURNAL_WEB_H, $fn = 20);
                }
            }

            // Journal extensions at rotation axis (0,0) — REQ-JE2
            // Total journal = JOURNAL_LENGTH (stub) + JOURNAL_EXT (extension)
            // Includes shoulder step for bearing location
            _total_journal = JOURNAL_LENGTH + JOURNAL_EXT;

            if (is_first) {
                // Near journal — extends in -Z
                translate([0, 0, -_total_journal])
                    cylinder(d = JOURNAL_DIA, h = _total_journal, $fn = 40);
                // Shoulder step — locates bearing inboard
                translate([0, 0, -_total_journal - THRUST_WASHER_T])
                    cylinder(d = SHOULDER_DIA, h = THRUST_WASHER_T + 0.5, $fn = 40);
            }

            if (is_last) {
                // Far journal — extends in +Z
                translate([0, 0, DISC_THICK])
                    cylinder(d = JOURNAL_DIA, h = _total_journal, $fn = 40);
                // Shoulder step — locates bearing inboard
                translate([0, 0, DISC_THICK + _total_journal - 0.5])
                    cylinder(d = SHOULDER_DIA, h = THRUST_WASHER_T + 0.5, $fn = 40);
            }
        }

        // Bolt clearance holes through disc body
        // Bolt circle centered at (ECCENTRICITY, 0) — on the disc
        for (b = [0 : NUM_BOLTS - 1]) {
            ba = b * (360 / NUM_BOLTS);
            bx = ECCENTRICITY + BOLT_CIRCLE_R * cos(ba);
            by = BOLT_CIRCLE_R * sin(ba);
            // Clearance through-hole
            translate([bx, by, -1])
                cylinder(d = BOLT_CLEARANCE_D, h = DISC_THICK + 2, $fn = 16);
            // Counterbore for bolt head on bottom face
            translate([bx, by, -1])
                cylinder(d = BOLT_HEAD_DIA + 0.5, h = BOLT_HEAD_H + 1, $fn = 20);
        }

        // Tapped holes for bolts from disc ABOVE
        // Next disc's bolt pattern is rotated by TWIST_PER_CAM around (0,0)
        // In this disc's local frame, the next disc's bolt circle center
        // is at (ECCENTRICITY rotated by TWIST_PER_CAM)
        _next_ecc_x = ECCENTRICITY * cos(TWIST_PER_CAM);
        _next_ecc_y = ECCENTRICITY * sin(TWIST_PER_CAM);
        for (b = [0 : NUM_BOLTS - 1]) {
            ba = b * (360 / NUM_BOLTS);
            bx = _next_ecc_x + BOLT_CIRCLE_R * cos(ba);
            by = _next_ecc_y + BOLT_CIRCLE_R * sin(ba);
            translate([bx, by, DISC_THICK - BOLT_ENGAGE])
                cylinder(d = BOLT_DIA * 0.85, h = BOLT_ENGAGE + 1, $fn = 16);
        }
    }
}


// =========================================================
// BEARING 6800ZZ
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
// BOLT SET — 3x M3 visual
// =========================================================
// Rendered at disc i position. Bolts connect disc i to disc i+1.
// Bolt circle is on disc body at (ECCENTRICITY, 0).
module _bolt_set() {
    color(C_BOLT)
    for (b = [0 : NUM_BOLTS - 1]) {
        ba = b * (360 / NUM_BOLTS);
        bx = ECCENTRICITY + BOLT_CIRCLE_R * cos(ba);
        by = BOLT_CIRCLE_R * sin(ba);
        translate([bx, by, DISC_THICK - BOLT_ENGAGE]) {
            cylinder(d = BOLT_DIA, h = BOLT_ENGAGE + FLANGE_H, $fn = 12);
            translate([0, 0, BOLT_ENGAGE + FLANGE_H - BOLT_HEAD_H])
                cylinder(d = BOLT_HEAD_DIA, h = BOLT_HEAD_H, $fn = 16);
        }
    }
}


// =========================================================
// GRAVITY RIB (Cam Follower Arm)
// =========================================================
module gravity_rib_v4() {
    arm_reach = BEARING_OD/2 + RIB_ARM_LENGTH;

    color(C_RIB)
    difference() {
        union() {
            // Bearing ring
            difference() {
                cylinder(d = RIB_RING_OD, h = RIB_THICK, center = true, $fn = 40);
                cylinder(d = BEARING_OD + 0.2, h = RIB_THICK + 2, center = true, $fn = 40);
            }
            // Arm extending toward matrix (-X in local)
            translate([-arm_reach/2 - BEARING_OD/2, 0, 0])
                cube([arm_reach, RIB_ARM_WIDTH, RIB_THICK], center = true);
            // Taper tip
            translate([-arm_reach - BEARING_OD/2 + RIB_TAPER_TIP/2, 0, 0])
                cylinder(d = RIB_TAPER_TIP, h = RIB_THICK, center = true, $fn = 16);
        }
        // Cable eyelet
        translate([-arm_reach - BEARING_OD/2 + RIB_TAPER_TIP/2, 0, 0])
            cylinder(d = RIB_EYELET_DIA, h = RIB_THICK + 2, center = true, $fn = 16);
        // Anti-rotation guide slot
        translate([-(BEARING_OD/2 + 10), -GUIDE_SLOT_W/2, -GUIDE_SLOT_H/2])
            cube([20, GUIDE_SLOT_W, GUIDE_SLOT_H]);
    }
}


// =========================================================
// GT2 PULLEY BOSS
// =========================================================
module gt2_pulley_boss() {
    color(C_ENDPLT) {
        cylinder(d = GT2_OD, h = GT2_BOSS_H, $fn = 40);
        // Flanges
        cylinder(d = GT2_OD + 3, h = 1, $fn = 40);
        translate([0, 0, GT2_BOSS_H - 1])
            cylinder(d = GT2_OD + 3, h = 1, $fn = 40);
    }
}
