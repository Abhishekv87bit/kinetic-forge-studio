// =========================================================
// FRAME — Hexagonal Support Structure
// =========================================================
// Supports the entire triple helix assembly:
//   - Matrix stack (3 tiers)
//   - 3 helix camshafts at hex vertices
//   - Guide plates below matrix
//   - Anchor plate above matrix
//   - Drive system (motor/crank + belts)
//   - Dampeners between helices and matrix
//
// Hexagonal footprint, M6 threaded rod uprights at hex corners.
// =========================================================

include <config.scad>

/* [Visibility] */
SHOW_UPRIGHTS     = true;
SHOW_TOP_RING     = true;
SHOW_MID_RING     = true;
SHOW_BOT_RING     = true;
SHOW_HELIX_MOUNTS = true;
SHOW_DAMPENERS    = true;

// =========================================================
// STANDALONE RENDER
// =========================================================
frame_assembly();


// =========================================================
// FRAME ASSEMBLY
// =========================================================

module frame_assembly() {
    // Ring Z-positions
    top_z = TIER_PITCH + TIER_ENVELOPE_H/2 + 50;   // above Tier 1
    mid_z = 0;                                       // at Tier 2 center
    bot_z = -TIER_PITCH - TIER_ENVELOPE_H/2 - 100;  // below blocks

    // Hex corners for uprights
    for (i = [0 : 5]) {
        a = i * 60 + 30;  // hex corners at 30, 90, 150, 210, 270, 330
        px = FRAME_CORNER_R * cos(a);
        py = FRAME_CORNER_R * sin(a);

        // Vertical uprights
        if (SHOW_UPRIGHTS)
            color(C_FRAME)
            translate([px, py, bot_z])
                cylinder(d = FRAME_ROD_DIA, h = top_z - bot_z, $fn = 20);
    }

    // Horizontal rings (hex-shaped)
    if (SHOW_TOP_RING)
        translate([0, 0, top_z])
            hex_ring(FRAME_HEX_R, FRAME_WALL);

    if (SHOW_MID_RING)
        translate([0, 0, mid_z])
            hex_ring(FRAME_HEX_R, FRAME_WALL);

    if (SHOW_BOT_RING)
        translate([0, 0, bot_z])
            hex_ring(FRAME_HEX_R, FRAME_WALL);

    // Helix shaft mounts (L-brackets at 3 hex vertices)
    if (SHOW_HELIX_MOUNTS) {
        for (tier_idx = [0 : 2]) {
            vertex_angle = HELIX_VERTEX_ANGLES[tier_idx];
            tier_z = (1 - tier_idx) * TIER_PITCH;

            mount_r = FRAME_HEX_R + 5;
            mx = mount_r * cos(vertex_angle);
            my = mount_r * sin(vertex_angle);

            color([0.5, 0.5, 0.6])
            translate([mx, my, tier_z])
                rotate([0, 0, vertex_angle])
                    helix_shaft_mount();
        }
    }

    // Dampeners (between helix and matrix edge)
    if (SHOW_DAMPENERS) {
        for (tier_idx = [0 : 2]) {
            tier_angle = TIER_ANGLES[tier_idx];
            vertex_angle = HELIX_VERTEX_ANGLES[tier_idx];
            tier_z = (1 - tier_idx) * TIER_PITCH;

            // Dampener sits on the frame between helix and matrix
            damp_r = FRAME_HEX_R - 10;
            dx = damp_r * cos(vertex_angle);
            dy = damp_r * sin(vertex_angle);

            color([0.7, 0.7, 0.3, 0.8])
            translate([dx, dy, tier_z - DAMPENER_LENGTH/2])
                cylinder(d = DAMPENER_DIA, h = DAMPENER_LENGTH, $fn = 16);
        }
    }

    echo(str("=== FRAME ==="));
    echo(str("Hex diameter (F-F): ", FRAME_DIAMETER, "mm"));
    echo(str("Corner-to-corner: ", FRAME_CORNER_R * 2, "mm"));
    echo(str("Height: ", top_z - bot_z, "mm"));
}


// =========================================================
// HEX RING (horizontal support ring)
// =========================================================

module hex_ring(hex_r, thick) {
    color(C_FRAME)
    difference() {
        // Outer hex
        linear_extrude(height = thick)
            circle(r = hex_r / cos(30), $fn = 6);

        // Inner hex (hollow)
        translate([0, 0, -1])
            linear_extrude(height = thick + 2)
                circle(r = hex_r / cos(30) - FRAME_WALL * 2, $fn = 6);
    }
}


// =========================================================
// HELIX SHAFT MOUNT (L-bracket)
// =========================================================

module helix_shaft_mount() {
    bracket_w = 30;
    bracket_h = 40;
    bracket_d = 15;
    plate_t = 4;

    // Vertical plate (attaches to frame upright)
    translate([-bracket_d, -bracket_w/2, -bracket_h/2])
        cube([plate_t, bracket_w, bracket_h]);

    // Horizontal plate (shaft bearing sits here)
    translate([-bracket_d, -bracket_w/2, -plate_t/2])
        cube([bracket_d, bracket_w, plate_t]);

    // Shaft bearing hole
    color(C_STEEL)
    translate([0, 0, 0])
        rotate([0, 90, 0])
            difference() {
                cylinder(d = 12, h = plate_t, center = true, $fn = 20);
                cylinder(d = 8, h = plate_t + 2, center = true, $fn = 20);
            }
}
