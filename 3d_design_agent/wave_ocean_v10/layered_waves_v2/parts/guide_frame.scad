/*
 * GUIDE FRAME - Structural Support with Guide Rod Mounts
 * =======================================================
 *
 * Main structural frame that:
 * - Holds 9 vertical guide rods (3 waves x 3 layers)
 * - Provides mounting for bearing blocks
 * - Creates back panel for scene backdrop
 * - Positions all components at correct locations
 *
 * Print: May need to be printed in sections
 * Material: PLA or PETG
 * Layer height: 0.2mm
 * Infill: 25%
 */

include <../common.scad>

// ============================================
// FRAME PARAMETERS
// ============================================

// Overall frame dimensions
FRAME_OUTER_WIDTH = SCENE_WIDTH + 60;       // 310mm
FRAME_OUTER_DEPTH = SCENE_DEPTH + 40;       // 90mm
FRAME_OUTER_HEIGHT = 80;                     // Total frame height

// Wall thicknesses
SIDE_WALL = 8;
BACK_WALL = 5;
BOTTOM_WALL = 8;
TOP_WALL = 5;

// Guide rod socket
GUIDE_SOCKET_DIA = GUIDE_ROD_DIA + TOL_CLEARANCE;  // 4.2mm
GUIDE_SOCKET_DEPTH = 10;                            // Insertion depth

// Reinforcement ribs
RIB_THICKNESS = 4;
RIB_HEIGHT = 15;

// Bearing block mounting
BEARING_MOUNT_HOLE_SPACING = 20;
BEARING_MOUNT_HOLE_DIA = M4_HOLE;

// ============================================
// MAIN MODULE - GUIDE FRAME
// ============================================

module guide_frame() {
    /*
     * Complete guide frame assembly
     * All guide rod positions calculated from common.scad
     */

    color(C_FRAME)
    difference() {
        union() {
            // Main frame shell
            frame_shell();

            // Guide rod socket bosses
            guide_rod_bosses();

            // Reinforcement ribs
            frame_ribs();

            // Bearing block mounting platforms
            bearing_platforms();
        }

        // Guide rod socket holes
        guide_rod_sockets();

        // Bearing block mounting holes
        bearing_mount_holes();

        // Lightening cutouts (optional)
        lightening_cutouts();

        // Cam clearance slot
        cam_clearance();
    }
}

// ============================================
// FRAME SHELL
// ============================================

module frame_shell() {
    /*
     * Main structural shell
     * Open front for wave visibility
     * Back panel, bottom, sides
     */

    // Bottom plate
    translate([-FRAME_OUTER_WIDTH/2, -FRAME_OUTER_DEPTH/2, 0])
        cube([FRAME_OUTER_WIDTH, FRAME_OUTER_DEPTH, BOTTOM_WALL]);

    // Back wall
    translate([-FRAME_OUTER_WIDTH/2, FRAME_OUTER_DEPTH/2 - BACK_WALL, 0])
        cube([FRAME_OUTER_WIDTH, BACK_WALL, FRAME_OUTER_HEIGHT]);

    // Left side wall
    translate([-FRAME_OUTER_WIDTH/2, -FRAME_OUTER_DEPTH/2, 0])
        cube([SIDE_WALL, FRAME_OUTER_DEPTH, FRAME_OUTER_HEIGHT]);

    // Right side wall
    translate([FRAME_OUTER_WIDTH/2 - SIDE_WALL, -FRAME_OUTER_DEPTH/2, 0])
        cube([SIDE_WALL, FRAME_OUTER_DEPTH, FRAME_OUTER_HEIGHT]);

    // Top rail (partial - leaves center open for wave travel)
    translate([-FRAME_OUTER_WIDTH/2, FRAME_OUTER_DEPTH/2 - BACK_WALL - 10, FRAME_OUTER_HEIGHT - TOP_WALL])
        cube([FRAME_OUTER_WIDTH, BACK_WALL + 10, TOP_WALL]);
}

// ============================================
// GUIDE ROD BOSSES
// ============================================

module guide_rod_bosses() {
    /*
     * Reinforced areas around each guide rod socket
     * Provides strength and alignment for guide rods
     */

    boss_dia = GUIDE_SOCKET_DIA + 8;
    boss_height = GUIDE_SOCKET_DEPTH + 5;

    for (w = [0 : NUM_WAVES - 1]) {
        for (l = [0 : NUM_LAYERS - 1]) {
            pos = guide_rod_position(w, l);

            translate([pos[0], pos[1], BOTTOM_WALL - 0.1])
                cylinder(d = boss_dia, h = boss_height);
        }
    }
}

// ============================================
// GUIDE ROD SOCKETS
// ============================================

module guide_rod_sockets() {
    /*
     * Socket holes for guide rod insertion
     * Guide rods press-fit or glue into these
     */

    for (w = [0 : NUM_WAVES - 1]) {
        for (l = [0 : NUM_LAYERS - 1]) {
            pos = guide_rod_position(w, l);

            // Main socket
            translate([pos[0], pos[1], BOTTOM_WALL - 1])
                cylinder(d = GUIDE_SOCKET_DIA, h = GUIDE_SOCKET_DEPTH + 2);

            // Entry chamfer
            translate([pos[0], pos[1], BOTTOM_WALL + GUIDE_SOCKET_DEPTH])
                cylinder(d1 = GUIDE_SOCKET_DIA, d2 = GUIDE_SOCKET_DIA + 2, h = 2);
        }
    }
}

// ============================================
// GUIDE ROD POSITION FUNCTION
// ============================================

function guide_rod_position(w, l) = [
    wave_x(w) + GUIDE_OFFSET_X,
    layer_y(l)
];

// ============================================
// FRAME RIBS
// ============================================

module frame_ribs() {
    /*
     * Internal reinforcement ribs
     * Prevent flexing under load
     */

    // Cross ribs connecting side walls
    rib_positions = [-80, 0, 80];

    for (x = rib_positions) {
        translate([x - RIB_THICKNESS/2, -FRAME_OUTER_DEPTH/2, BOTTOM_WALL])
        hull() {
            cube([RIB_THICKNESS, FRAME_OUTER_DEPTH/2, RIB_HEIGHT]);
            translate([0, FRAME_OUTER_DEPTH/4, RIB_HEIGHT])
                cube([RIB_THICKNESS, FRAME_OUTER_DEPTH/4, 1]);
        }
    }

    // Longitudinal rib (front to back)
    translate([-RIB_THICKNESS/2, -FRAME_OUTER_DEPTH/2, BOTTOM_WALL])
        cube([RIB_THICKNESS, FRAME_OUTER_DEPTH - BACK_WALL, RIB_HEIGHT/2]);
}

// ============================================
// BEARING PLATFORMS
// ============================================

module bearing_platforms() {
    /*
     * Mounting platforms for bearing blocks
     * Located at each end of frame
     */

    platform_width = 40;
    platform_depth = 30;
    platform_height = 5;

    // Left platform
    translate([-FRAME_OUTER_WIDTH/2 + SIDE_WALL, -platform_depth/2, BOTTOM_WALL])
        cube([platform_width, platform_depth, platform_height]);

    // Right platform
    translate([FRAME_OUTER_WIDTH/2 - SIDE_WALL - platform_width, -platform_depth/2, BOTTOM_WALL])
        cube([platform_width, platform_depth, platform_height]);
}

// ============================================
// BEARING MOUNT HOLES
// ============================================

module bearing_mount_holes() {
    /*
     * M4 holes for bearing block attachment
     */

    platform_center_x_left = -FRAME_OUTER_WIDTH/2 + SIDE_WALL + 20;
    platform_center_x_right = FRAME_OUTER_WIDTH/2 - SIDE_WALL - 20;

    // Left bearing block holes
    for (dx = [-BEARING_MOUNT_HOLE_SPACING/2, BEARING_MOUNT_HOLE_SPACING/2]) {
        translate([platform_center_x_left + dx, 0, -1])
            cylinder(d = M4_HOLE, h = BOTTOM_WALL + 10);
    }

    // Right bearing block holes
    for (dx = [-BEARING_MOUNT_HOLE_SPACING/2, BEARING_MOUNT_HOLE_SPACING/2]) {
        translate([platform_center_x_right + dx, 0, -1])
            cylinder(d = M4_HOLE, h = BOTTOM_WALL + 10);
    }
}

// ============================================
// LIGHTENING CUTOUTS
// ============================================

module lightening_cutouts() {
    /*
     * Remove material to reduce weight
     * Keep structural integrity
     */

    // Side wall cutouts
    for (x_sign = [-1, 1]) {
        for (z = [25, 50]) {
            translate([x_sign * (FRAME_OUTER_WIDTH/2 - SIDE_WALL/2),
                       -FRAME_OUTER_DEPTH/4,
                       z])
            rotate([90, 0, 0])
            hull() {
                cylinder(d = 20, h = 1, center = true);
                translate([0, 15, 0])
                    cylinder(d = 15, h = 1, center = true);
            }
        }
    }
}

// ============================================
// CAM CLEARANCE
// ============================================

module cam_clearance() {
    /*
     * Slot for cam rotation below frame
     * Cam rotates in space below the bottom plate
     */

    // Slot through bottom for follower arms
    slot_width = SCENE_WIDTH + 20;
    slot_depth = 30;

    translate([-slot_width/2, -slot_depth/2, -1])
        cube([slot_width, slot_depth, BOTTOM_WALL + 2]);
}

// ============================================
// FRAME SECTIONS (for printing)
// ============================================

module frame_left_section() {
    /*
     * Left third of frame
     * Includes left side wall and guide rod bosses
     */

    intersection() {
        guide_frame();
        translate([-FRAME_OUTER_WIDTH/2 - 1, -FRAME_OUTER_DEPTH/2 - 1, -1])
            cube([FRAME_OUTER_WIDTH/3 + 20, FRAME_OUTER_DEPTH + 2, FRAME_OUTER_HEIGHT + 2]);
    }
}

module frame_center_section() {
    /*
     * Center third of frame
     */

    intersection() {
        guide_frame();
        translate([-FRAME_OUTER_WIDTH/6, -FRAME_OUTER_DEPTH/2 - 1, -1])
            cube([FRAME_OUTER_WIDTH/3, FRAME_OUTER_DEPTH + 2, FRAME_OUTER_HEIGHT + 2]);
    }
}

module frame_right_section() {
    /*
     * Right third of frame
     */

    intersection() {
        guide_frame();
        translate([FRAME_OUTER_WIDTH/6 - 20, -FRAME_OUTER_DEPTH/2 - 1, -1])
            cube([FRAME_OUTER_WIDTH/3 + 21, FRAME_OUTER_DEPTH + 2, FRAME_OUTER_HEIGHT + 2]);
    }
}

// ============================================
// GUIDE ROD VISUALIZATION
// ============================================

module guide_rods_preview() {
    /*
     * Show all guide rods in position
     */

    for (w = [0 : NUM_WAVES - 1]) {
        for (l = [0 : NUM_LAYERS - 1]) {
            pos = guide_rod_position(w, l);

            color(C_GUIDE)
            translate([pos[0], pos[1], BOTTOM_WALL + GUIDE_SOCKET_DEPTH])
                cylinder(d = GUIDE_ROD_DIA, h = GUIDE_ROD_LENGTH);
        }
    }
}

// ============================================
// RENDER
// ============================================

// Complete frame
guide_frame();

// Ghost guide rods
%guide_rods_preview();

// Section preview (for printing)
translate([0, 150, 0]) {
    translate([-110, 0, 0]) frame_left_section();
    translate([0, 0, 0]) frame_center_section();
    translate([110, 0, 0]) frame_right_section();
}

// Info
echo("============================================");
echo("GUIDE FRAME");
echo("============================================");
echo(str("Outer dimensions: ", FRAME_OUTER_WIDTH, " x ", FRAME_OUTER_DEPTH, " x ", FRAME_OUTER_HEIGHT, "mm"));
echo("");
echo("GUIDE ROD POSITIONS:");
for (w = [0 : NUM_WAVES - 1]) {
    for (l = [0 : NUM_LAYERS - 1]) {
        pos = guide_rod_position(w, l);
        echo(str("  Wave ", w, " Layer ", l, ": X=", pos[0], ", Y=", pos[1]));
    }
}
echo("");
echo("Print options:");
echo("  1. Full frame if bed >= 310mm");
echo("  2. Use frame sections for smaller beds");
echo("============================================");
