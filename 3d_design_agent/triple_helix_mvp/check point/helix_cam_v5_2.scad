// =========================================================
// HELIX CAM V5.2 — Disc-Around-Shaft Eccentric Cam
// =========================================================
// Standards: ISO 128 (technical drawing), DFAM (3D print design)
//
// DESIGN: Large circular disc with shaft boss at disc edge.
//   The disc IS the eccentric. Shaft passes through an offset
//   boss near the disc edge. A large bearing (6810ZZ, 50×65×7)
//   wraps the entire disc outer surface. A follower ring rides
//   on the bearing outer race — fully decoupled from rotation.
//
//   When the shaft rotates, the disc orbits around the shaft
//   axis. The bearing outer race traces the eccentric path.
//   The follower ring moves with the eccentric but does NOT
//   rotate — cable tension keeps it oriented.
//
// NO RIB-SHAFT COLLISION: The follower is on the OUTSIDE of
//   the disc. The shaft is at the disc edge. Nothing crosses.
//
// INDEXING: D-flat shaft + pre-angled discs (Option A)
//   Each disc printed with its D-bore at a unique angle from
//   disc center. When slid onto the D-flat shaft, the disc
//   center ends up at the correct phase angle.
//   11 unique STLs, number embossed on each disc face.
//
// 11 discs × 32.73°/disc = 360° = one full wave.
// AXIAL_PITCH (14mm) decoupled from matrix STACK_OFFSET (12mm).
// Cams are spread out for thick discs; cables bridge the gap.
// Three helixes at [180, 300, 60]° = traveling wave.
//
// Assembly (per station):
//   1. Slide pre-angled disc onto shaft (D-flat keyed)
//   2. Push to position, tighten M3 set screw in shaft boss
//   3. Press 61808ZZ bearing onto disc outer surface
//   4. Clip follower ring onto bearing outer race
//   5. Thread cable through follower eyelet
//   6. Slide spacer collar onto shaft
//   7. Repeat for all 11 discs
// =========================================================

include <config_v5_2.scad>

$fn = 48;

// =============================================
// DISPLAY TOGGLES
// =============================================
/* [Visibility] */
SHOW_DISCS      = true;
SHOW_SHAFT      = true;
SHOW_BEARINGS   = true;
SHOW_FOLLOWERS  = true;
SHOW_COLLARS    = true;
SHOW_RETAINERS  = true;
SHOW_SOFT_STOPS = true;

// =============================================
// SOFT STOP PARAMETERS (W2 fix)
// =============================================
// Two small nubs on disc flange at ±15° from neutral (cable direction).
// If follower arm swings past ±15° (slack cable), arm contacts nub.
// Prevents over-rotation and tangling.
SOFT_STOP_ANGLE   = 15;        // degrees from neutral
SOFT_STOP_DIA     = 3.0;       // nub diameter
SOFT_STOP_H       = FOLLOWER_RING_H + 1;  // taller than follower ring
SOFT_STOP_R       = FOLLOWER_RING_OD / 2 + 1;  // just outside follower ring OD

// =============================================
// VERIFICATION
// =============================================
echo(str("=== HELIX CAM V5.2 — DISC-AROUND-SHAFT ==="));
echo(str("Cams: ", NUM_CAMS, " | Twist/cam: ", round(TWIST_PER_CAM*100)/100, "deg"));
echo(str("Total twist: ", round(NUM_CAMS * TWIST_PER_CAM*10)/10, "deg (should be 360)"));
echo(str("CAM_ECC: ", round(CAM_ECC*10)/10, "mm | Stroke: ", round(2*CAM_ECC*10)/10, "mm"));
echo(str("Disc OD: ", DISC_OD, "mm | Shaft boss: ", SHAFT_BOSS_OD, "mm at edge"));
echo(str("Bearing: 6810ZZ (", CAM_BRG_ID, "/", CAM_BRG_OD, "/", CAM_BRG_W, ") wraps disc"));
echo(str("Follower ring: OD=", FOLLOWER_RING_OD, "mm (on bearing outer race)"));
echo(str("Disc thick: ", DISC_THICK, "mm | Collar: ", COLLAR_THICK, "mm | Pitch: ", AXIAL_PITCH, "mm"));
echo(str("Total length: ", HELIX_LENGTH, "mm"));
echo(str("Shaft: ", SHAFT_DIA, "mm D-flat=", D_FLAT_DEPTH, "mm"));

_max_envelope = CAM_ECC + FOLLOWER_RING_OD/2 + FOLLOWER_ARM_LENGTH;
echo(str("Max radial from shaft (follower tip): ", round(_max_envelope*10)/10, "mm"));


// =============================================
// STANDALONE RENDER
// =============================================
helix_assembly_v5(anim_t());


// =========================================================
// HELIX ASSEMBLY — 13 disc-around-shaft cams on central shaft
// =========================================================
// Shaft extends from carrier plate A (Z < 0) through disc stack
// to carrier plate B (Z > HELIX_LENGTH).
//
// Layout along shaft Z-axis (local frame):
//   Z = -SHAFT_EXT_TO_CARRIER - SHAFT_EXT_BEYOND  : shaft start (drive end)
//   Z = -SHAFT_EXT_TO_CARRIER                      : carrier plate A center
//   Z = -SHAFT_EXT_TO_CARRIER + FRAME_BRG_W/2 + 2 : E-clip groove A (inboard)
//   Z = 0                                          : first disc face
//   Z = HELIX_LENGTH                               : last disc end
//   Z = HELIX_LENGTH + SHAFT_EXT_TO_CARRIER - FRAME_BRG_W/2 - 2 : E-clip groove B
//   Z = HELIX_LENGTH + SHAFT_EXT_TO_CARRIER        : carrier plate B center
//   Z = HELIX_LENGTH + SHAFT_EXT_TO_CARRIER + SHAFT_EXT_BEYOND : shaft end

module helix_assembly_v5(t = 0) {
    crank_angle = t * 360;

    // Shaft extension distances
    _ext_in  = SHAFT_EXT_TO_CARRIER + SHAFT_EXT_BEYOND;  // 65mm before first disc
    _ext_out = SHAFT_EXT_TO_CARRIER + SHAFT_EXT_BEYOND;  // 65mm after last disc
    _total_shaft = HELIX_LENGTH + _ext_in + _ext_out;     // 256mm

    // Central steel shaft — full length spanning between carrier plates
    if (SHOW_SHAFT) {
        color(C_STEEL)
        translate([0, 0, -_ext_in])
            difference() {
                cylinder(d = SHAFT_DIA, h = _total_shaft, $fn = 32);
                // D-flat along entire length
                translate([SHAFT_DIA/2 - D_FLAT_DEPTH, -SHAFT_DIA, -1])
                    cube([D_FLAT_DEPTH + 1, SHAFT_DIA * 2, _total_shaft + 2]);

                // E-clip grooves (inboard of each carrier plate)
                // Drive end (Z < 0): groove at carrier + brg_w/2 + 2mm inboard
                _groove_a_z = SHAFT_EXT_TO_CARRIER - FRAME_BRG_W/2 - 2
                              - (-_ext_in) + _ext_in;
                // Wait — let me do this in absolute shaft-local Z:
                // Carrier A center is at Z = -SHAFT_EXT_TO_CARRIER (from disc 0)
                // In shaft-local coords (shaft starts at -_ext_in):
                //   carrier A = _ext_in - SHAFT_EXT_TO_CARRIER = SHAFT_EXT_BEYOND = 15mm from shaft start
                // E-clip inboard of carrier A = 15 + FRAME_BRG_W/2 + 2 = 15 + 2.5 + 2 = 19.5mm
                _eclip_a_z = SHAFT_EXT_BEYOND + FRAME_BRG_W/2 + 2;
                translate([0, 0, _eclip_a_z - ECLIP_GROOVE_W/2])
                    difference() {
                        cylinder(d = SHAFT_DIA + 1, h = ECLIP_GROOVE_W, $fn = 32);
                        cylinder(d = ECLIP_GROOVE_DIA, h = ECLIP_GROOVE_W, $fn = 32);
                    }

                // Free end: carrier B center at Z = HELIX_LENGTH + SHAFT_EXT_TO_CARRIER from disc 0
                // In shaft-local: _ext_in + HELIX_LENGTH + SHAFT_EXT_TO_CARRIER
                // E-clip inboard = that - FRAME_BRG_W/2 - 2
                _eclip_b_z = _ext_in + HELIX_LENGTH + SHAFT_EXT_TO_CARRIER
                             - FRAME_BRG_W/2 - 2;
                translate([0, 0, _eclip_b_z - ECLIP_GROOVE_W/2])
                    difference() {
                        cylinder(d = SHAFT_DIA + 1, h = ECLIP_GROOVE_W, $fn = 32);
                        cylinder(d = ECLIP_GROOVE_DIA, h = ECLIP_GROOVE_W, $fn = 32);
                    }
            }
    }

    // E-clip retainer visualizations (torus-like rings on shaft)
    if (SHOW_RETAINERS) {
        // E-clip A (drive end, inboard of carrier A)
        _eclip_a_pos = -SHAFT_EXT_TO_CARRIER + FRAME_BRG_W/2 + 2;
        color([0.8, 0.8, 0.2, 1.0])
        translate([0, 0, _eclip_a_pos])
            difference() {
                cylinder(d = ECLIP_OD, h = ECLIP_GROOVE_W, center = true, $fn = 24);
                cylinder(d = ECLIP_GROOVE_DIA - 0.5, h = ECLIP_GROOVE_W + 2,
                         center = true, $fn = 24);
            }

        // E-clip B (free end, inboard of carrier B)
        _eclip_b_pos = HELIX_LENGTH + SHAFT_EXT_TO_CARRIER - FRAME_BRG_W/2 - 2;
        color([0.8, 0.8, 0.2, 1.0])
        translate([0, 0, _eclip_b_pos])
            difference() {
                cylinder(d = ECLIP_OD, h = ECLIP_GROOVE_W, center = true, $fn = 24);
                cylinder(d = ECLIP_GROOVE_DIA - 0.5, h = ECLIP_GROOVE_W + 2,
                         center = true, $fn = 24);
            }
    }

    // Disc stack (13 cam stations)
    for (i = [0 : NUM_CAMS - 1]) {
        cam_angle = crank_angle + i * TWIST_PER_CAM;
        z_pos = i * AXIAL_PITCH;

        disc_cx = CAM_ECC * cos(cam_angle);
        disc_cy = CAM_ECC * sin(cam_angle);

        translate([0, 0, z_pos]) {
            if (SHOW_DISCS)
                rotate([0, 0, cam_angle])
                    eccentric_disc_v5(disc_index = i);

            if (SHOW_BEARINGS)
                translate([disc_cx, disc_cy, FLANGE_H])
                    _bearing_6810zz();

            if (SHOW_FOLLOWERS)
                translate([disc_cx, disc_cy, FLANGE_H + CAM_BRG_W/2])
                    follower_ring_v5();

            if (SHOW_COLLARS && i < NUM_CAMS - 1)
                translate([0, 0, DISC_THICK])
                    spacer_collar_v5();

            // Soft stop nubs at ±15° from cable direction (W2 fix)
            if (SHOW_SOFT_STOPS)
                translate([disc_cx, disc_cy, FLANGE_H + CAM_BRG_W/2])
                    _soft_stop_pair();
        }
    }

    // GT2 pulley on drive end (beyond carrier plate A)
    translate([0, 0, -_ext_in])
        gt2_pulley_boss_v5();
}


// =========================================================
// ECCENTRIC DISC V5 — Large disc with shaft boss at edge
// =========================================================
// The disc is a large circle centered at (CAM_ECC, 0) in local frame.
// The shaft boss is at (0, 0) — at the disc edge.
// The shaft passes through (0, 0).
//
// For disc_index = 0, shaft boss is at angle 0° from disc center
//   (i.e., disc center is at +X from shaft).
// For disc_index = N, the D-bore in the shaft boss is rotated by
//   -N*TWIST_PER_CAM so the disc ends up at the correct phase.
//
// The assembly loop applies rotate([0,0,cam_angle]) which puts
// the disc center at the correct angular position.

module eccentric_disc_v5(disc_index = 0) {
    // D-bore rotation for indexing (same logic as V3 hubs)
    _dbore_angle = -disc_index * TWIST_PER_CAM;

    color(C_DISC)
    difference() {
        union() {
            // --- Main disc body centered at (CAM_ECC, 0) ---
            translate([CAM_ECC, 0, 0])
                cylinder(d = DISC_OD, h = DISC_THICK, $fn = 60);

            // --- Shaft boss at (0, 0) — disc edge ---
            // This overlaps with the disc body (tangent/embedded)
            cylinder(d = SHAFT_BOSS_OD, h = DISC_THICK, $fn = 32);

            // --- Bearing seat: disc body raised above flange ---
            translate([CAM_ECC, 0, FLANGE_H])
                cylinder(d = DISC_OD, h = BEARING_ZONE_H, $fn = 60);

            // --- Keeper lip — retains bearing axially ---
            translate([CAM_ECC, 0, FLANGE_H + BEARING_ZONE_H - KEEPER_LIP_H])
                cylinder(d = KEEPER_LIP_DIA, h = KEEPER_LIP_H, $fn = 60);
        }

        // --- D-bore through shaft boss for shaft ---
        rotate([0, 0, _dbore_angle]) {
            // Round bore (sliding fit)
            translate([0, 0, -1])
                cylinder(d = SHAFT_BORE, h = DISC_THICK + 2, $fn = 32);

            // D-flat cutout
            translate([SHAFT_DIA/2 - D_FLAT_DEPTH, -SHAFT_BORE, -1])
                cube([D_FLAT_DEPTH + 1, SHAFT_BORE * 2, DISC_THICK + 2]);
        }

        // --- Set screw hole — radial M3 through shaft boss ---
        // Oriented at 90° from the disc center direction (Y-axis)
        translate([0, SHAFT_BOSS_OD/2, DISC_THICK/2])
            rotate([90, 0, 0])
                cylinder(d = SET_SCREW_BORE, h = SET_SCREW_DEPTH, $fn = 16);

        // --- Disc index number on top face ---
        translate([CAM_ECC, 0, DISC_THICK - 0.3])
            linear_extrude(0.5)
                text(str(disc_index), size = 5, halign = "center", valign = "center",
                     font = "Liberation Mono:style=Bold");
    }
}


// =========================================================
// 6810ZZ BEARING — wraps entire disc outer surface
// =========================================================
module _bearing_6810zz() {
    color(C_BEARING)
    difference() {
        cylinder(d = CAM_BRG_OD, h = CAM_BRG_W, $fn = 60);
        translate([0, 0, -1])
            cylinder(d = CAM_BRG_ID, h = CAM_BRG_W + 2, $fn = 60);
    }
}


// =========================================================
// FOLLOWER RING V5 — rides on 6810ZZ outer race
// =========================================================
// Ring clips onto bearing outer race. Short arm extends
// AWAY from shaft (outward, +X in local frame from disc center)
// for cable eyelet. No shaft collision possible — everything
// is on the outside of the bearing.
//
// The follower orbits with the disc eccentric but does NOT
// rotate with the cam. Cable tension keeps it oriented.

module follower_ring_v5() {
    _arm_reach = CAM_BRG_OD/2 + FOLLOWER_ARM_LENGTH;

    color(C_RIB)
    difference() {
        union() {
            // Ring body (clips onto bearing outer race)
            difference() {
                cylinder(d = FOLLOWER_RING_OD, h = FOLLOWER_RING_H,
                         center = true, $fn = 60);
                cylinder(d = CAM_BRG_OD + 0.4, h = FOLLOWER_RING_H + 2,
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
// SPACER COLLAR V5 — sits on shaft between discs
// =========================================================
module spacer_collar_v5() {
    color(C_NYLON)
    difference() {
        cylinder(d = SHAFT_BOSS_OD, h = COLLAR_THICK, $fn = 32);

        // D-bore matching shaft
        translate([0, 0, -1])
            cylinder(d = SHAFT_BORE, h = COLLAR_THICK + 2, $fn = 32);

        // D-flat cutout
        translate([SHAFT_DIA/2 - D_FLAT_DEPTH, -SHAFT_BORE, -1])
            cube([D_FLAT_DEPTH + 1, SHAFT_BORE * 2, COLLAR_THICK + 2]);
    }
}


// =========================================================
// SOFT STOP PAIR — two nubs at ±15° from neutral
// =========================================================
// Placed on disc flange, just outside follower ring.
// Prevents follower arm from swinging beyond ±15° if cable goes slack.
// Neutral = -X direction (toward matrix center, where cable attaches).
module _soft_stop_pair() {
    for (sign = [-1, 1]) {
        _stop_angle = 180 + sign * SOFT_STOP_ANGLE;  // 180° = -X = cable direction
        _sx = SOFT_STOP_R * cos(_stop_angle);
        _sy = SOFT_STOP_R * sin(_stop_angle);

        color([0.9, 0.3, 0.1, 0.9])
        translate([_sx, _sy, 0])
            cylinder(d = SOFT_STOP_DIA, h = SOFT_STOP_H, center = true, $fn = 12);
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
            // Set screw
            translate([0, 0, GT2_BOSS_H/2])
                rotate([90, 0, 0])
                    cylinder(d = SET_SCREW_BORE, h = GT2_OD, $fn = 12);
        }
    }
}
