// =========================================================
// HELIX CAM V5.5 — Integrated Disc+Collar, Keyed Faces
// =========================================================
// Standards: ISO 128 (technical drawing), DFAM (3D print design)
//
// V5.5 CHANGES FROM V5.4:
//   C3: Face pins REMOVED from cam discs
//       Angular indexing via D-flat shaft + keyed collar bump/dimple + CA glue.
//       Self-indexing: cone bumps on collar front face click into
//       matching conical dimples on the next disc's back face.
//       D-flat prevents gross rotation; bumps provide fine angular lock.
// V5.5c CHANGES (Rule 99):
//   R2: D_FLAT_DEPTH 0.4→0.6mm (better set screw bite)
//   R5: Hemisphere bumps → cone bumps (FDM-friendly, no bridging)
//
// All other dimensions unchanged from V5.4:
//   6704ZZ bearing, 4mm shaft, DISC_OD=19.6, CAM_ECC=4.8
//
// Assembly (per station):
//   1. Slide disc+collar onto D-flat shaft — bumps click into dimples
//      of adjacent disc at correct TWIST_PER_CAM angle
//   2. Apply CA glue between collar face and adjacent disc back
//   3. Press 6704ZZ bearing onto disc outer surface
//   4. Clip follower ring onto bearing outer race
//   5. Thread cable through follower eyelet
//   6. Repeat for all 9 discs
// =========================================================

include <config_v5_5.scad>

$fn = 48;

// =============================================
// DISPLAY TOGGLES
// =============================================
/* [Visibility] */
SHOW_DISCS      = true;
SHOW_SHAFT      = true;
SHOW_BEARINGS   = true;
SHOW_FOLLOWERS  = true;
SHOW_RETAINERS  = true;  // E-clip visualizations

// =============================================
// VERIFICATION
// =============================================
echo(str("=== HELIX CAM V5.5 — KEYED COLLAR FACES (bump+dimple) ==="));
echo(str("Cams: ", NUM_CAMS, " | Twist/cam: ", round(TWIST_PER_CAM*100)/100, "deg"));
echo(str("Total twist: ", round(NUM_CAMS * TWIST_PER_CAM*10)/10, "deg (should be 360)"));
echo(str("CAM_ECC: ", round(CAM_ECC*10)/10, "mm | Stroke: ", round(2*CAM_ECC*10)/10, "mm"));
echo(str("Disc OD: ", DISC_OD, "mm | Boss: ", SHAFT_BOSS_OD, "mm | Collar stub: ", COLLAR_THICK, "mm"));
echo(str("Integrated piece height: ", DISC_THICK + COLLAR_THICK, "mm (disc=", DISC_THICK, " + collar=", COLLAR_THICK, ")"));
echo(str("Bearing: 6704ZZ (", CAM_BRG_ID, "/", CAM_BRG_OD, "/", CAM_BRG_W, ")"));
echo(str("Follower ring: OD=", FOLLOWER_RING_OD, "mm"));
echo(str("Axial pitch: ", AXIAL_PITCH, "mm | Total length: ", HELIX_LENGTH, "mm"));
echo(str("Shaft: ", SHAFT_DIA, "mm D-flat=", D_FLAT_DEPTH, "mm | Total=", round(SHAFT_TOTAL_LENGTH*10)/10, "mm"));
echo(str("V5.5c: Keyed collar — cone bump base=", COLLAR_BUMP_DIA, " tip=", COLLAR_BUMP_TIP_DIA, " h=", COLLAR_BUMP_H, " R=", COLLAR_BUMP_R, " count=", COLLAR_BUMP_COUNT));
echo(str("E-clips: DIN 6799 E-4, groove dia=", ECLIP_GROOVE_DIA, "mm"));

_max_envelope = CAM_ECC + FOLLOWER_RING_OD/2 + FOLLOWER_ARM_LENGTH;
echo(str("Max radial from shaft (follower tip): ", round(_max_envelope*10)/10, "mm"));


// =============================================
// STANDALONE RENDER
// =============================================
helix_assembly_v5(anim_t());


// =========================================================
// HELIX ASSEMBLY — NUM_CAMS integrated disc+collar cams
// =========================================================
module helix_assembly_v5(t = 0) {
    crank_angle = -t * 360;

    _ext_drive = SHAFT_EXT_TO_CARRIER + SHAFT_EXT_BEYOND_DRIVE;
    _ext_free  = SHAFT_EXT_TO_CARRIER + SHAFT_EXT_BEYOND_FREE;
    _total_shaft = HELIX_LENGTH + _ext_drive + _ext_free;

    // Central steel shaft
    if (SHOW_SHAFT) {
        color(C_STEEL)
        translate([0, 0, -_ext_drive])
            difference() {
                cylinder(d = SHAFT_DIA, h = _total_shaft, $fn = 32);

                // D-flat
                translate([SHAFT_DIA/2 - D_FLAT_DEPTH, -SHAFT_DIA, -1])
                    cube([D_FLAT_DEPTH + 1, SHAFT_DIA * 2, _total_shaft + 2]);

                // E-clip groove A (drive end)
                _eclip_a_z = SHAFT_EXT_BEYOND_DRIVE + ECLIP_INBOARD_OFFSET;
                translate([0, 0, _eclip_a_z - ECLIP_GROOVE_W/2])
                    difference() {
                        cylinder(d = SHAFT_DIA + 1, h = ECLIP_GROOVE_W, $fn = 32);
                        cylinder(d = ECLIP_GROOVE_DIA, h = ECLIP_GROOVE_W, $fn = 32);
                    }

                // E-clip groove B (free end)
                _eclip_b_z = _ext_drive + HELIX_LENGTH + SHAFT_EXT_TO_CARRIER
                             - ECLIP_INBOARD_OFFSET;
                translate([0, 0, _eclip_b_z - ECLIP_GROOVE_W/2])
                    difference() {
                        cylinder(d = SHAFT_DIA + 1, h = ECLIP_GROOVE_W, $fn = 32);
                        cylinder(d = ECLIP_GROOVE_DIA, h = ECLIP_GROOVE_W, $fn = 32);
                    }
            }
    }

    // E-clip retainer visualizations
    if (SHOW_RETAINERS) {
        _eclip_a_pos = -SHAFT_EXT_TO_CARRIER + ECLIP_INBOARD_OFFSET;
        color([0.8, 0.8, 0.2, 1.0])
        translate([0, 0, _eclip_a_pos])
            difference() {
                cylinder(d = ECLIP_OD, h = ECLIP_GROOVE_W, center = true, $fn = 24);
                cylinder(d = ECLIP_GROOVE_DIA - 0.5, h = ECLIP_GROOVE_W + 2,
                         center = true, $fn = 24);
            }

        _eclip_b_pos = HELIX_LENGTH + SHAFT_EXT_TO_CARRIER - ECLIP_INBOARD_OFFSET;
        color([0.8, 0.8, 0.2, 1.0])
        translate([0, 0, _eclip_b_pos])
            difference() {
                cylinder(d = ECLIP_OD, h = ECLIP_GROOVE_W, center = true, $fn = 24);
                cylinder(d = ECLIP_GROOVE_DIA - 0.5, h = ECLIP_GROOVE_W + 2,
                         center = true, $fn = 24);
            }
    }

    // Disc stack
    for (i = [0 : NUM_CAMS - 1]) {
        cam_angle = crank_angle + i * TWIST_PER_CAM;
        z_pos = i * AXIAL_PITCH;

        disc_cx = CAM_ECC * cos(cam_angle);
        disc_cy = CAM_ECC * sin(cam_angle);

        translate([0, 0, z_pos]) {
            // Integrated disc+collar (NO face pins)
            if (SHOW_DISCS)
                rotate([0, 0, cam_angle])
                    eccentric_disc_v5_5(
                        disc_index = i,
                        has_collar = (i < NUM_CAMS - 1)
                    );

            // Bearing
            if (SHOW_BEARINGS)
                translate([disc_cx, disc_cy, FLANGE_H])
                    _bearing_6704zz();

            // Follower ring
            if (SHOW_FOLLOWERS)
                translate([disc_cx, disc_cy, FLANGE_H + CAM_BRG_W/2])
                    follower_ring_v5();
        }
    }

    // GT2 pulley on drive end
    _gt2_z = -SHAFT_EXT_TO_CARRIER - CARRIER_PLATE_T_CFG / 2 - GT2_BOSS_H;
    translate([0, 0, _gt2_z])
        gt2_pulley_boss_v5();
}


// =========================================================
// ECCENTRIC DISC V5.5 — Keyed Collar Faces (bump+dimple)
// =========================================================
module eccentric_disc_v5_5(disc_index = 0, has_collar = true) {
    _dbore_angle = -disc_index * TWIST_PER_CAM;

    color(C_DISC)
    union() {
        difference() {
            union() {
                // Main disc body centered at (CAM_ECC, 0)
                translate([CAM_ECC, 0, 0])
                    cylinder(d = DISC_OD, h = DISC_THICK, $fn = 60);

                // Shaft boss at (0, 0)
                cylinder(d = SHAFT_BOSS_OD, h = DISC_THICK, $fn = 32);

                // Bearing seat
                translate([CAM_ECC, 0, FLANGE_H])
                    cylinder(d = DISC_OD, h = BEARING_ZONE_H, $fn = 60);

                // Keeper lip
                translate([CAM_ECC, 0, FLANGE_H + BEARING_ZONE_H - KEEPER_LIP_H])
                    cylinder(d = KEEPER_LIP_DIA, h = KEEPER_LIP_H, $fn = 60);

                // Integrated collar stub
                if (has_collar)
                    translate([0, 0, DISC_THICK])
                        cylinder(d = SHAFT_BOSS_OD, h = COLLAR_THICK, $fn = 32);
            }

            // D-bore through shaft boss (and collar)
            _total_h = has_collar ? DISC_THICK + COLLAR_THICK : DISC_THICK;
            rotate([0, 0, _dbore_angle]) {
                translate([0, 0, -1])
                    cylinder(d = SHAFT_BORE, h = _total_h + 2, $fn = 32);
                translate([SHAFT_DIA/2 - D_FLAT_DEPTH, -SHAFT_BORE, -1])
                    cube([D_FLAT_DEPTH + 1, SHAFT_BORE * 2, _total_h + 2]);
            }

            // Disc index number on top face
            translate([CAM_ECC, 0, DISC_THICK - 0.2])
                linear_extrude(0.4)
                    text(str(disc_index), size = 3, halign = "center", valign = "center",
                         font = "Liberation Mono:style=Bold");

            // V5.5c R5: Conical dimple sockets on disc BACK face (Z=0)
            // Receive cone bumps from previous collar.
            // First disc (index 0) has no dimples on back (nothing behind it)
            if (disc_index > 0) {
                rotate([0, 0, _dbore_angle])
                for (bi = [0 : COLLAR_BUMP_COUNT - 1]) {
                    _bump_a = bi * (360 / COLLAR_BUMP_COUNT);
                    _bx = COLLAR_BUMP_R * cos(_bump_a);
                    _by = COLLAR_BUMP_R * sin(_bump_a);
                    translate([_bx, _by, -0.01])
                        cylinder(d1 = COLLAR_BUMP_DIA + 0.1,
                                 d2 = COLLAR_BUMP_TIP_DIA + 0.1,
                                 h = COLLAR_DIMPLE_DEPTH, $fn = 16);
                }
            }
        }

        // V5.5c R5: Cone bumps on collar FRONT face (top of collar)
        // Prints cleanly on FDM — no bridging artifacts unlike hemispheres.
        // Last disc has no collar → no bumps
        if (has_collar) {
            _collar_top_z = DISC_THICK + COLLAR_THICK;
            // Bumps are at the NEXT disc's D-bore angle
            _next_dbore_angle = -(disc_index + 1) * TWIST_PER_CAM;
            rotate([0, 0, _next_dbore_angle])
            for (bi = [0 : COLLAR_BUMP_COUNT - 1]) {
                _bump_a = bi * (360 / COLLAR_BUMP_COUNT);
                _bx = COLLAR_BUMP_R * cos(_bump_a);
                _by = COLLAR_BUMP_R * sin(_bump_a);
                translate([_bx, _by, _collar_top_z])
                    cylinder(d1 = COLLAR_BUMP_DIA, d2 = COLLAR_BUMP_TIP_DIA,
                             h = COLLAR_BUMP_H, $fn = 16);
            }
        }
    }
}


// =========================================================
// 6704ZZ BEARING
// =========================================================
module _bearing_6704zz() {
    color(C_BEARING)
    difference() {
        cylinder(d = CAM_BRG_OD, h = CAM_BRG_W, $fn = 60);
        translate([0, 0, -1])
            cylinder(d = CAM_BRG_ID, h = CAM_BRG_W + 2, $fn = 60);
    }
}


// =========================================================
// FOLLOWER RING V5
// =========================================================
module follower_ring_v5() {
    _arm_reach = CAM_BRG_OD/2 + FOLLOWER_ARM_LENGTH;

    color(C_RIB)
    difference() {
        union() {
            difference() {
                cylinder(d = FOLLOWER_RING_OD, h = FOLLOWER_RING_H,
                         center = true, $fn = 60);
                cylinder(d = FOLLOWER_RING_ID, h = FOLLOWER_RING_H + 2,
                         center = true, $fn = 60);
            }
            translate([-_arm_reach/2 - CAM_BRG_OD/4, 0, 0])
                cube([_arm_reach, FOLLOWER_ARM_W, FOLLOWER_RING_H], center = true);
            translate([-_arm_reach - CAM_BRG_OD/4 + 2, 0, 0])
                cylinder(d = FOLLOWER_ARM_W + 1.5, h = FOLLOWER_RING_H,
                         center = true, $fn = 16);
        }
        translate([-_arm_reach - CAM_BRG_OD/4 + 2, 0, 0])
            cylinder(d = FOLLOWER_EYELET_DIA, h = FOLLOWER_RING_H + 2,
                     center = true, $fn = 16);
    }
}


// =========================================================
// GT2 PULLEY BOSS
// =========================================================
module gt2_pulley_boss_v5() {
    color(C_ENDPLT) {
        difference() {
            union() {
                cylinder(d = GT2_OD, h = GT2_BOSS_H, $fn = 40);
                cylinder(d = GT2_OD + 2, h = 0.8, $fn = 40);
                translate([0, 0, GT2_BOSS_H - 0.8])
                    cylinder(d = GT2_OD + 2, h = 0.8, $fn = 40);
            }
            translate([0, 0, -1])
                cylinder(d = SHAFT_BORE, h = GT2_BOSS_H + 2, $fn = 32);
            translate([SHAFT_DIA/2 - D_FLAT_DEPTH, -SHAFT_BORE, -1])
                cube([D_FLAT_DEPTH + 1, SHAFT_BORE * 2, GT2_BOSS_H + 2]);
            // Set screw
            translate([0, 0, GT2_BOSS_H/2])
                rotate([90, 0, 0])
                    cylinder(d = SET_SCREW_BORE, h = GT2_OD, $fn = 12);
        }
    }
}
