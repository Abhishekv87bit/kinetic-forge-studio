// =========================================================
// HELIX CAM V5.3 — Integrated Disc+Collar with Face Pins
// =========================================================
// Standards: ISO 128 (technical drawing), DFAM (3D print design)
//
// DESIGN: Large circular disc with shaft boss at disc edge.
//   The disc IS the eccentric. Shaft passes through an offset
//   boss near the disc edge. A large bearing (61808ZZ, 40×50×6)
//   wraps the entire disc outer surface. A follower ring rides
//   on the bearing outer race — fully decoupled from rotation.
//
//   When the shaft rotates, the disc orbits around the shaft
//   axis. The bearing outer race traces the eccentric path.
//   The follower ring moves with the eccentric but does NOT
//   rotate — cable tension keeps it oriented.
//
// V5.3 CHANGES FROM V5.2:
//   - Shaft upgraded to 8mm with 0.7mm D-flat
//   - Integrated disc+collar: each cam is ONE printed piece
//     (disc body + collar stub). No separate spacer collars.
//   - Face pins replace set screws: 2× 2.5mm printed pins on
//     collar face engage receiving holes on previous disc back.
//     D-bore provides rotational phase indexing.
//   - Soft stops REMOVED: cable tension from block weight
//     keeps follower ring oriented. No slack cable scenario.
//   - E-clip grooves on shaft inboard of each carrier plate
//     (frame-side retention, see hex_frame for carrier shoulder)
//   - Bearing: 688ZZ (8/16/5) at frame carriers (same OD as 625ZZ)
//
// INDEXING: D-flat shaft + pre-angled discs (Option A)
//   Each disc printed with its D-bore at a unique angle from
//   disc center. When slid onto the D-flat shaft, the disc
//   center ends up at the correct phase angle.
//   11 unique STLs, number embossed on each disc face.
//   Face pins lock axial position and prevent rotation creep.
//
// 11 discs × 32.73°/disc = 360° = one full wave.
// AXIAL_PITCH (14mm) decoupled from matrix STACK_OFFSET (12mm).
// Cams are spread out for thick discs; cables bridge the gap.
// Three helixes at [180, 300, 60]° = traveling wave.
//
// Assembly (per station):
//   1. Slide pre-angled disc+collar onto D-flat shaft
//   2. Face pins on collar engage previous disc's receiving holes
//      (first disc: pins engage carrier plate holes)
//   3. Push to position — pins click into receiving holes
//   4. Press 61808ZZ bearing onto disc outer surface
//   5. Clip follower ring onto bearing outer race
//   6. Thread cable through follower eyelet
//   7. Repeat for all 11 discs (no separate collars needed)
// =========================================================

include <config_v5_3.scad>

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
SHOW_PINS       = true;  // face pin highlights

// =============================================
// VERIFICATION
// =============================================
echo(str("=== HELIX CAM V5.3 — INTEGRATED DISC+COLLAR + FACE PINS ==="));
echo(str("Cams: ", NUM_CAMS, " | Twist/cam: ", round(TWIST_PER_CAM*100)/100, "deg"));
echo(str("Total twist: ", round(NUM_CAMS * TWIST_PER_CAM*10)/10, "deg (should be 360)"));
echo(str("CAM_ECC: ", round(CAM_ECC*10)/10, "mm | Stroke: ", round(2*CAM_ECC*10)/10, "mm"));
echo(str("Disc OD: ", DISC_OD, "mm | Boss: ", SHAFT_BOSS_OD, "mm | Collar stub: ", COLLAR_THICK, "mm"));
echo(str("Integrated piece height: ", DISC_THICK + COLLAR_THICK, "mm (disc=", DISC_THICK, " + collar=", COLLAR_THICK, ")"));
echo(str("Bearing: 61808ZZ (", CAM_BRG_ID, "/", CAM_BRG_OD, "/", CAM_BRG_W, ") wraps disc"));
echo(str("Follower ring: OD=", FOLLOWER_RING_OD, "mm (on bearing outer race)"));
echo(str("Axial pitch: ", AXIAL_PITCH, "mm | Total length: ", HELIX_LENGTH, "mm"));
echo(str("Shaft: ", SHAFT_DIA, "mm D-flat=", D_FLAT_DEPTH, "mm | Total=", SHAFT_TOTAL_LENGTH, "mm"));
echo(str("Face pins: ", FACE_PIN_COUNT, "x ", FACE_PIN_DIA, "mm at R=", FACE_PIN_R, "mm, H=", FACE_PIN_H, "mm"));
echo(str("E-clips: DIN 6799 E-8, groove dia=", ECLIP_GROOVE_DIA, "mm"));

_max_envelope = CAM_ECC + FOLLOWER_RING_OD/2 + FOLLOWER_ARM_LENGTH;
echo(str("Max radial from shaft (follower tip): ", round(_max_envelope*10)/10, "mm"));


// =============================================
// STANDALONE RENDER
// =============================================
helix_assembly_v5(anim_t());


// =========================================================
// HELIX ASSEMBLY — 11 integrated disc+collar cams on shaft
// =========================================================
// Shaft extends from carrier plate A (Z < 0) through disc stack
// to carrier plate B (Z > HELIX_LENGTH).
//
// Layout along shaft Z-axis (local frame):
//   Z = -SHAFT_EXT_TO_CARRIER - SHAFT_EXT_BEYOND  : shaft start (drive end)
//   Z = -SHAFT_EXT_TO_CARRIER                      : carrier plate A center
//   Z = 0                                          : first disc face (bearing side)
//   Z = DISC_THICK                                 : first collar start
//   Z = AXIAL_PITCH                                : second disc face
//   Z = NUM_CAMS * AXIAL_PITCH - COLLAR_THICK      : last disc end (no collar on last)
//   Z = HELIX_LENGTH + SHAFT_EXT_TO_CARRIER        : carrier plate B center
//   Z = HELIX_LENGTH + SHAFT_EXT_TO_CARRIER + SHAFT_EXT_BEYOND : shaft end

module helix_assembly_v5(t = 0) {
    crank_angle = t * 360;

    // Shaft extension distances
    _ext_in  = SHAFT_EXT_TO_CARRIER + SHAFT_EXT_BEYOND;
    _ext_out = SHAFT_EXT_TO_CARRIER + SHAFT_EXT_BEYOND;
    _total_shaft = HELIX_LENGTH + _ext_in + _ext_out;

    // Central steel shaft — full length spanning between carrier plates
    if (SHOW_SHAFT) {
        color(C_STEEL)
        translate([0, 0, -_ext_in])
            difference() {
                cylinder(d = SHAFT_DIA, h = _total_shaft, $fn = 32);

                // D-flat along entire length
                translate([SHAFT_DIA/2 - D_FLAT_DEPTH, -SHAFT_DIA, -1])
                    cube([D_FLAT_DEPTH + 1, SHAFT_DIA * 2, _total_shaft + 2]);

                // E-clip groove A (drive end, INSIDE edge of carrier node)
                // Carrier A center at Z = SHAFT_EXT_BEYOND from shaft start
                // E-clip sits right at corridor face, catches bearing inner race
                _eclip_a_z = SHAFT_EXT_BEYOND + ECLIP_INBOARD_OFFSET;
                translate([0, 0, _eclip_a_z - ECLIP_GROOVE_W/2])
                    difference() {
                        cylinder(d = SHAFT_DIA + 1, h = ECLIP_GROOVE_W, $fn = 32);
                        cylinder(d = ECLIP_GROOVE_DIA, h = ECLIP_GROOVE_W, $fn = 32);
                    }

                // E-clip groove B (free end, INSIDE edge of carrier node)
                _eclip_b_z = _ext_in + HELIX_LENGTH + SHAFT_EXT_TO_CARRIER
                             - ECLIP_INBOARD_OFFSET;
                translate([0, 0, _eclip_b_z - ECLIP_GROOVE_W/2])
                    difference() {
                        cylinder(d = SHAFT_DIA + 1, h = ECLIP_GROOVE_W, $fn = 32);
                        cylinder(d = ECLIP_GROOVE_DIA, h = ECLIP_GROOVE_W, $fn = 32);
                    }
            }
    }

    // E-clip retainer visualizations (torus-like rings on shaft)
    if (SHOW_RETAINERS) {
        // E-clip A (drive end, INSIDE edge of carrier node A)
        _eclip_a_pos = -SHAFT_EXT_TO_CARRIER + ECLIP_INBOARD_OFFSET;
        color([0.8, 0.8, 0.2, 1.0])
        translate([0, 0, _eclip_a_pos])
            difference() {
                cylinder(d = ECLIP_OD, h = ECLIP_GROOVE_W, center = true, $fn = 24);
                cylinder(d = ECLIP_GROOVE_DIA - 0.5, h = ECLIP_GROOVE_W + 2,
                         center = true, $fn = 24);
            }

        // E-clip B (free end, INSIDE edge of carrier node B)
        _eclip_b_pos = HELIX_LENGTH + SHAFT_EXT_TO_CARRIER - ECLIP_INBOARD_OFFSET;
        color([0.8, 0.8, 0.2, 1.0])
        translate([0, 0, _eclip_b_pos])
            difference() {
                cylinder(d = ECLIP_OD, h = ECLIP_GROOVE_W, center = true, $fn = 24);
                cylinder(d = ECLIP_GROOVE_DIA - 0.5, h = ECLIP_GROOVE_W + 2,
                         center = true, $fn = 24);
            }
    }

    // Disc stack (11 integrated disc+collar stations)
    for (i = [0 : NUM_CAMS - 1]) {
        cam_angle = crank_angle + i * TWIST_PER_CAM;
        z_pos = i * AXIAL_PITCH;

        disc_cx = CAM_ECC * cos(cam_angle);
        disc_cy = CAM_ECC * sin(cam_angle);

        translate([0, 0, z_pos]) {
            // Integrated disc+collar (one printed piece per station)
            if (SHOW_DISCS)
                rotate([0, 0, cam_angle])
                    eccentric_disc_v5_3(
                        disc_index = i,
                        has_collar = (i < NUM_CAMS - 1),  // last disc has no collar
                        has_pins = (i > 0)                  // first disc has no pins (faces carrier)
                    );

            // Bearing wraps disc body
            if (SHOW_BEARINGS)
                translate([disc_cx, disc_cy, FLANGE_H])
                    _bearing_61808zz();

            // Follower ring rides on bearing outer race
            if (SHOW_FOLLOWERS)
                translate([disc_cx, disc_cy, FLANGE_H + CAM_BRG_W/2])
                    follower_ring_v5();
        }
    }

    // GT2 pulley on drive end (beyond carrier plate A)
    translate([0, 0, -_ext_in])
        gt2_pulley_boss_v5();
}


// =========================================================
// ECCENTRIC DISC V5.3 — Integrated Disc + Collar with Face Pins
// =========================================================
// The disc is a large circle centered at (CAM_ECC, 0) in local frame.
// The shaft boss is at (0, 0) — at the disc edge.
// The shaft passes through (0, 0).
//
// V5.3: The collar is printed as ONE PIECE with the disc body.
//   Collar stub extends from the disc back face (Z = DISC_THICK).
//   The collar OD = SHAFT_BOSS_OD (14mm), much smaller than bearing
//   bore (40mm), so bearing slides over disc from non-collar side.
//
//   Face pins protrude from disc FRONT face (Z < 0) and engage
//   receiving holes on the BACK face of the previous disc's collar.
//   First disc (i=0) has no pins — its front face is toward carrier.
//   Last disc (i=10) has no collar — nothing follows it.
//
// For disc_index = N, the D-bore in the shaft boss is rotated by
//   -N*TWIST_PER_CAM so the disc ends up at the correct phase.
//
// The assembly loop applies rotate([0,0,cam_angle]) which puts
// the disc center at the correct angular position.

module eccentric_disc_v5_3(disc_index = 0, has_collar = true, has_pins = true) {
    // D-bore rotation for indexing (same logic as V3 hubs)
    _dbore_angle = -disc_index * TWIST_PER_CAM;

    color(C_DISC)
    difference() {
        union() {
            // --- Main disc body centered at (CAM_ECC, 0) ---
            translate([CAM_ECC, 0, 0])
                cylinder(d = DISC_OD, h = DISC_THICK, $fn = 60);

            // --- Shaft boss at (0, 0) — disc edge ---
            cylinder(d = SHAFT_BOSS_OD, h = DISC_THICK, $fn = 32);

            // --- Bearing seat: disc body raised above flange ---
            translate([CAM_ECC, 0, FLANGE_H])
                cylinder(d = DISC_OD, h = BEARING_ZONE_H, $fn = 60);

            // --- Keeper lip — retains bearing axially ---
            translate([CAM_ECC, 0, FLANGE_H + BEARING_ZONE_H - KEEPER_LIP_H])
                cylinder(d = KEEPER_LIP_DIA, h = KEEPER_LIP_H, $fn = 60);

            // --- Integrated collar stub (extends from disc back face) ---
            if (has_collar)
                translate([0, 0, DISC_THICK])
                    cylinder(d = SHAFT_BOSS_OD, h = COLLAR_THICK, $fn = 32);
        }

        // --- D-bore through shaft boss (and collar if present) ---
        _total_h = has_collar ? DISC_THICK + COLLAR_THICK : DISC_THICK;
        rotate([0, 0, _dbore_angle]) {
            // Round bore (sliding fit)
            translate([0, 0, -1])
                cylinder(d = SHAFT_BORE, h = _total_h + 2, $fn = 32);

            // D-flat cutout
            translate([SHAFT_DIA/2 - D_FLAT_DEPTH, -SHAFT_BORE, -1])
                cube([D_FLAT_DEPTH + 1, SHAFT_BORE * 2, _total_h + 2]);
        }

        // --- Face pin RECEIVING HOLES on collar back face ---
        // These accept pins from the NEXT disc's front face
        if (has_collar) {
            // Pin holes on collar end face (Z = DISC_THICK + COLLAR_THICK)
            // Rotate to match THIS disc's D-bore angle (pins from next disc
            // are at next disc's angle, but assembly ensures alignment via D-flat)
            for (p = [0 : FACE_PIN_COUNT - 1]) {
                _pin_a = p * (360 / FACE_PIN_COUNT);  // 0°, 180°
                rotate([0, 0, _dbore_angle])
                translate([FACE_PIN_R * cos(_pin_a), FACE_PIN_R * sin(_pin_a),
                           DISC_THICK + COLLAR_THICK - FACE_PIN_HOLE_DEPTH])
                    cylinder(d = FACE_PIN_HOLE_DIA, h = FACE_PIN_HOLE_DEPTH + 1, $fn = 16);
            }
        }

        // --- Disc index number on top face ---
        translate([CAM_ECC, 0, DISC_THICK - 0.3])
            linear_extrude(0.5)
                text(str(disc_index), size = 5, halign = "center", valign = "center",
                     font = "Liberation Mono:style=Bold");
    }

    // --- Face pins protruding from disc FRONT face (Z < 0) ---
    // These engage receiving holes on the previous disc's collar back face
    if (has_pins && SHOW_PINS) {
        color(C_PIN)
        rotate([0, 0, _dbore_angle])
        for (p = [0 : FACE_PIN_COUNT - 1]) {
            _pin_a = p * (360 / FACE_PIN_COUNT);  // 0°, 180°
            translate([FACE_PIN_R * cos(_pin_a), FACE_PIN_R * sin(_pin_a), -FACE_PIN_H])
                cylinder(d = FACE_PIN_DIA, h = FACE_PIN_H, $fn = 16);
        }
    }
}


// =========================================================
// 61808ZZ BEARING — wraps entire disc outer surface
// =========================================================
module _bearing_61808zz() {
    color(C_BEARING)
    difference() {
        cylinder(d = CAM_BRG_OD, h = CAM_BRG_W, $fn = 60);
        translate([0, 0, -1])
            cylinder(d = CAM_BRG_ID, h = CAM_BRG_W + 2, $fn = 60);
    }
}


// =========================================================
// FOLLOWER RING V5 — rides on 61808ZZ outer race
// =========================================================
// Ring clips onto bearing outer race. Short arm extends
// AWAY from shaft (outward, -X in local frame = toward matrix)
// for cable eyelet. No shaft collision possible — everything
// is on the outside of the bearing.
//
// The follower orbits with the disc eccentric but does NOT
// rotate with the cam. Cable tension keeps it oriented.
// No soft stops needed — block weight maintains tension.

module follower_ring_v5() {
    _arm_reach = CAM_BRG_OD/2 + FOLLOWER_ARM_LENGTH;

    color(C_RIB)
    difference() {
        union() {
            // Ring body (clips onto bearing outer race)
            difference() {
                cylinder(d = FOLLOWER_RING_OD, h = FOLLOWER_RING_H,
                         center = true, $fn = 60);
                cylinder(d = FOLLOWER_RING_ID, h = FOLLOWER_RING_H + 2,
                         center = true, $fn = 60);
            }

            // Short arm for cable eyelet — extends OUTWARD from disc
            // (away from shaft, in -X direction = toward matrix)
            translate([-_arm_reach/2 - CAM_BRG_OD/4, 0, 0])
                cube([_arm_reach, FOLLOWER_ARM_W, FOLLOWER_RING_H], center = true);

            // Tip with eyelet boss
            translate([-_arm_reach - CAM_BRG_OD/4 + 3.5, 0, 0])
                cylinder(d = FOLLOWER_ARM_W + 2, h = FOLLOWER_RING_H,
                         center = true, $fn = 16);
        }

        // Cable eyelet hole at tip
        translate([-_arm_reach - CAM_BRG_OD/4 + 3.5, 0, 0])
            cylinder(d = FOLLOWER_EYELET_DIA, h = FOLLOWER_RING_H + 2,
                     center = true, $fn = 16);
    }
}


// =========================================================
// GT2 PULLEY BOSS (on shaft drive end, for belt)
// =========================================================
module gt2_pulley_boss_v5() {
    color(C_ENDPLT) {
        difference() {
            union() {
                cylinder(d = GT2_OD, h = GT2_BOSS_H, $fn = 40);
                // Flanges
                cylinder(d = GT2_OD + 3, h = 1, $fn = 40);
                translate([0, 0, GT2_BOSS_H - 1])
                    cylinder(d = GT2_OD + 3, h = 1, $fn = 40);
            }
            // D-bore for shaft
            translate([0, 0, -1])
                cylinder(d = SHAFT_BORE, h = GT2_BOSS_H + 2, $fn = 32);
            translate([SHAFT_DIA/2 - D_FLAT_DEPTH, -SHAFT_BORE, -1])
                cube([D_FLAT_DEPTH + 1, SHAFT_BORE * 2, GT2_BOSS_H + 2]);
            // Set screw (retained for GT2 pulley — high-torque connection)
            translate([0, 0, GT2_BOSS_H/2])
                rotate([90, 0, 0])
                    cylinder(d = SET_SCREW_BORE, h = GT2_OD, $fn = 12);
        }
    }
}
