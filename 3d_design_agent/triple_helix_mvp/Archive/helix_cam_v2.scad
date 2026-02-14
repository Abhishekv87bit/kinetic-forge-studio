// =========================================================
// HELIX CAM V2 — Eccentric Hub + Gravity Rib + End Plate
// =========================================================
// 5 cams per helix (one per channel strip), stacked with progressive twist.
//
// This file defines the helix parts AND the positioned assembly.
// When used in full_assembly.scad, call helix_assembly_positioned()
// which places the helix at the correct position/orientation for its tier.
//
// Coordinate system (helix local):
//   Shaft axis = Z (cams stacked along Z)
//   Cam orbit plane = XY
//   Gravity rib extends in -X (toward matrix center when positioned)
//
// Hub attachment: press-fit + M3 set screw (no bolt pattern)
// Bearing: 6800ZZ (10/19/5mm)
// =========================================================

include <config.scad>

/* [Visibility] */
SHOW_HUBS       = true;
SHOW_RIBS       = true;
SHOW_COLLARS    = true;
SHOW_END_PLATES = true;
SHOW_CENTER_PIN = true;

// =========================================================
// STANDALONE RENDER — single helix, shaft along Z
// =========================================================
helix_assembly(anim_t());


// =========================================================
// HELIX ASSEMBLY — 5 cams + ribs along shaft (Z-axis)
// =========================================================

module helix_assembly(t = 0) {
    crank_angle = t * 360;

    for (i = [0 : NUM_CAMS - 1]) {
        cam_angle = crank_angle + i * TWIST_PER_CAM;
        z_pos = i * AXIAL_PITCH;

        translate([0, 0, z_pos]) {
            // Eccentric hub (rotates with shaft)
            if (SHOW_HUBS)
                rotate([0, 0, cam_angle])
                    eccentric_hub();

            // Gravity rib (rides on bearing OD, hangs by gravity)
            // The rib doesn't rotate with the shaft — it orbits eccentrically
            if (SHOW_RIBS) {
                // Rib center follows the eccentric: offset by eccentricity at cam_angle
                ecc_x = ECCENTRICITY * cos(cam_angle);
                ecc_y = ECCENTRICITY * sin(cam_angle);
                translate([ecc_x, ecc_y, 0])
                    gravity_rib();
            }

            // Spacer collar between cams (except after last)
            if (SHOW_COLLARS && i < NUM_CAMS - 1)
                translate([0, 0, BEARING_W])
                    spacer_collar();
        }
    }

    // End plates
    if (SHOW_END_PLATES) {
        // Bottom end plate at Z = -10
        translate([0, 0, -10])
            end_plate();
        // Top end plate above last cam
        translate([0, 0, HELIX_LENGTH + 3])
            end_plate();
    }

    // Center alignment pin — spans from bottom end plate through top end plate
    if (SHOW_CENTER_PIN)
        color(C_STEEL)
        translate([0, 0, -10])
            cylinder(d = CENTER_PIN_DIA, h = HELIX_LENGTH + 20, $fn = 20);

    echo(str("=== HELIX ASSEMBLY ==="));
    echo(str("Cams: ", NUM_CAMS, " | Twist/cam: ", TWIST_PER_CAM, "°"));
    echo(str("Length: ", HELIX_LENGTH, "mm | Axial pitch: ", AXIAL_PITCH, "mm"));
}


// =========================================================
// POSITIONED HELIX — placed at correct location for a tier
// =========================================================
// tier_idx: 0, 1, or 2 (which tier this helix serves)
// The helix shaft runs perpendicular to the tier's slider direction,
// positioned at the hex vertex opposite the slider entry side.

module helix_assembly_positioned(tier_idx, t = 0) {
    tier_angle = TIER_ANGLES[tier_idx];
    vertex_angle = HELIX_VERTEX_ANGLES[tier_idx];

    // Helix radial distance from matrix center
    helix_r = FRAME_HEX_R + HELIX_DISTANCE;

    // Position at the vertex
    hx = helix_r * cos(vertex_angle);
    hy = helix_r * sin(vertex_angle);

    // Z-height matches tier center
    tier_z = (1 - tier_idx) * TIER_PITCH;

    // Shaft orientation: perpendicular to slider direction
    // Slider direction = tier_angle. Shaft direction = tier_angle + 90
    shaft_angle = tier_angle + 90;

    translate([hx, hy, tier_z]) {
        // Rotate shaft to be horizontal and perpendicular to slider direction
        // Shaft needs to point along shaft_angle in the XY plane
        // First rotate so Z→horizontal along shaft_angle
        rotate([0, 0, shaft_angle])
            rotate([0, 90, 0])
                // Center the helix on its midpoint
                translate([0, 0, -HELIX_LENGTH/2])
                    helix_assembly(t);
    }
}


// =========================================================
// ECCENTRIC HUB ("Salami Slice" Cam)
// =========================================================
// Hub body at eccentric offset with structural web connecting
// back to the center pin bore. Press-fit + set screw attachment.
//
// Cross-section sketch (looking down Z):
//   Center pin (0,0) ←—— web ——→ Hub body (ECCENTRICITY, 0)
//   The web bridges the gap so the hub is structurally connected.

module eccentric_hub() {
    color([0.3, 0.6, 0.9, 0.9])
    difference() {
        union() {
            // Main hub body at eccentric offset (bearing press-fit seat)
            translate([ECCENTRICITY, 0, 0])
                cylinder(d = BEARING_ID - 0.1, h = BEARING_W, $fn = 60);

            // Keeper lip (retains bearing axially)
            translate([ECCENTRICITY, 0, 0])
                cylinder(d = BEARING_ID + 2, h = 0.8, $fn = 60);

            // STRUCTURAL WEB — bridges center pin to hub body
            // Hull from center boss to hub body creates solid connection
            hull() {
                // Center boss around pin
                cylinder(d = CENTER_PIN_DIA + 4, h = BEARING_W, $fn = 30);
                // Hub body
                translate([ECCENTRICITY, 0, 0])
                    cylinder(d = BEARING_ID - 0.1, h = BEARING_W, $fn = 60);
            }
        }

        // Center pin hole (through entire hub)
        translate([0, 0, -1])
            cylinder(d = CENTER_PIN_DIA + 0.2, h = BEARING_W + 2, $fn = 20);

        // Set screw hole (radial, through web into center pin)
        // M3 set screw enters from hub OD side, tightens against center pin
        translate([ECCENTRICITY/2, 0, BEARING_W/2])
            rotate([0, 90, 0])
                cylinder(d = SETSCREW_DIA, h = ECCENTRICITY, $fn = 16);

        // Soft stop tabs — bumps at ±SOFT_STOP_ANGLE
        for (sa = [-SOFT_STOP_ANGLE, SOFT_STOP_ANGLE]) {
            translate([ECCENTRICITY + (BEARING_ID/2 - 1) * cos(sa),
                       (BEARING_ID/2 - 1) * sin(sa), -1])
                cylinder(d = 3, h = BEARING_W + 2, $fn = 12);
        }
    }
}


// =========================================================
// GRAVITY RIB (Cam Follower Arm)
// =========================================================

module gravity_rib() {
    arm_reach = BEARING_OD/2 + RIB_ARM_LENGTH;

    color([0.8, 0.5, 0.2, 0.9])
    difference() {
        union() {
            // Bearing ring (sits on bearing outer race)
            difference() {
                cylinder(d = BEARING_OD + 10, h = RIB_THICK, center = true, $fn = 40);
                cylinder(d = BEARING_OD + 0.2, h = RIB_THICK + 2, center = true, $fn = 40);
            }

            // Arm extending outward (toward matrix)
            // Arm goes in -X direction (toward matrix center when positioned)
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
        translate([-(BEARING_OD/2 + 15), -GUIDE_SLOT_W/2, -GUIDE_SLOT_H/2])
            cube([30, GUIDE_SLOT_W, GUIDE_SLOT_H]);
    }
}


// =========================================================
// SPACER COLLAR (between adjacent cams)
// =========================================================
// Simple ring on center pin between bearing stations.

module spacer_collar() {
    color([0.6, 0.6, 0.6, 0.5])
    difference() {
        cylinder(d = 15, h = COLLAR_THICK, $fn = 30);

        // Center pin clearance
        translate([0, 0, -1])
            cylinder(d = CENTER_PIN_DIA + 0.4, h = COLLAR_THICK + 2, $fn = 20);
    }
}


// =========================================================
// END PLATE (connects helix to drive shaft)
// =========================================================
// No bolt pattern — press-fit on center pin + set screw.

module end_plate() {
    color(C_STEEL)
    difference() {
        union() {
            // Circular flange
            cylinder(d = 30, h = 5, $fn = 40);

            // Extension arm to pivot point (drive shaft connection)
            translate([0, -10, 0])
                cube([40, 20, 5]);
        }

        // Center pin hole
        translate([0, 0, -1])
            cylinder(d = CENTER_PIN_DIA + 0.2, h = 7, $fn = 20);

        // Set screw hole (radial)
        translate([0, 0, 2.5])
            rotate([0, 90, 0])
                cylinder(d = SETSCREW_DIA, h = 20, $fn = 16);

        // Drive shaft bore (at arm end)
        translate([35, 0, -1])
            cylinder(d = 8, h = 7, $fn = 20);
    }
}
