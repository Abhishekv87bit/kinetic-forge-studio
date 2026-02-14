/*
 * BACKPLATE - Structural Support with 36 Guide Grooves
 *
 * POSITION: Behind the cam (Y = BACKPLATE_Y_FRONT)
 * The cam sweeps Y = ±22mm, backplate starts at Y = 27mm
 * This provides 5mm clearance from cam sweep.
 *
 * PURPOSE:
 * - 36 vertical grooves guide slat tabs
 * - Grooves constrain slats to vertical motion only
 * - Mounting points for bearing blocks
 *
 * Print: 1x (or 2 halves for smaller beds)
 * Orientation: Flat on back
 */

include <../common.scad>

$fn = 32;

// ============================================
// MAIN BACKPLATE MODULE
// ============================================

module backplate() {
    union() {
        difference() {
            union() {
                // Main plate body
                plate_body();

                // Bearing block mounting wings
                bearing_wings();
            }

            // 36 open-top slat grooves
            slat_grooves();

            // Bearing mount holes
            bearing_mount_holes();

            // Weight reduction (optional)
            // weight_pockets();
        }

        // Front retention lips (added after difference to avoid being cut)
        groove_lips();
    }
}

// ============================================
// PLATE BODY
// ============================================

module plate_body() {
    // Plate in Y-Z plane, extends in X
    // Front face at Y = 0 (will be positioned at BACKPLATE_Y_FRONT in assembly)
    translate([-BACKPLATE_WIDTH/2, 0, 0])
        cube([BACKPLATE_WIDTH, BACKPLATE_THICKNESS, BACKPLATE_HEIGHT]);
}

// ============================================
// SLAT GROOVES - All 36
// ============================================

module slat_grooves() {
    // Each groove is a vertical channel for a slat tab
    // OPEN-TOP: Grooves cut through top for easy slat insertion

    groove_z_start = 5;
    groove_z_end = BACKPLATE_HEIGHT + 1;  // Open top - cuts through
    groove_z_length = groove_z_end - groove_z_start;

    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i);

        // Only create groove if within backplate width
        if (abs(x) < BACKPLATE_WIDTH/2 - 3) {
            // Groove cuts into front face of backplate
            translate([x - GROOVE_WIDTH/2, -1, groove_z_start])
                cube([GROOVE_WIDTH, GROOVE_DEPTH + 1, groove_z_length]);

            // Entry chamfer at bottom only (top is open)
            translate([x - (GROOVE_WIDTH + 1)/2, -1, groove_z_start - 0.5])
                cube([GROOVE_WIDTH + 1, 2, 1]);
        }
    }
}

// ============================================
// FRONT RETENTION LIPS - Prevent slats from pulling forward
// ============================================

module groove_lips() {
    // Small ridges on groove walls prevent tab from pulling forward
    // Tab slides past them during top insertion, then they block pull-out
    //
    // Top view (looking down -Z):
    //
    //        GROOVE
    //   ┌──┐      ┌──┐
    //   │▓▓│ tab  │▓▓│  ← ridges project into groove
    //   │  │      │  │
    //   └──┘      └──┘
    //      BACKPLATE
    //
    // Ridges are small triangular profiles for easy tab insertion

    ridge_protrusion = 0.6;  // How far ridge projects into groove (< clearance/2)
    ridge_height = 4;        // Vertical height of ridge
    ridge_depth_y = 8;       // How far back ridge extends into groove

    // Three ridges per side, spaced for tab travel
    ridge_z_positions = [20, 50, 80];

    for (i = [0 : NUM_SLATS - 1]) {
        x = slat_x(i);

        if (abs(x) < BACKPLATE_WIDTH/2 - 3) {
            for (z = ridge_z_positions) {
                // Left ridge (projects right into groove)
                translate([x - GROOVE_WIDTH/2, 2, z])
                    ridge_profile(ridge_protrusion, ridge_depth_y, ridge_height);

                // Right ridge (projects left into groove)
                translate([x + GROOVE_WIDTH/2, 2, z])
                mirror([1, 0, 0])
                    ridge_profile(ridge_protrusion, ridge_depth_y, ridge_height);
            }
        }
    }
}

module ridge_profile(protrusion, depth, height) {
    // Triangular ridge - ramps inward for easy insertion, blocks pullout
    // Profile in X-Y plane, extruded in Z
    linear_extrude(height)
        polygon([
            [0, 0],
            [protrusion, depth * 0.3],
            [protrusion, depth * 0.7],
            [0, depth]
        ]);
}

// ============================================
// BEARING WINGS - Mount bearing blocks
// ============================================

module bearing_wings() {
    // Wings extend forward (-Y) from backplate to meet bearing blocks
    // Bearing blocks are at Y ≈ 0, backplate is at Y = 27

    wing_width = 30;
    wing_depth = BACKPLATE_Y_FRONT + 5;  // Extends from backplate to beyond Y=0
    wing_height = BB_HEIGHT + 10;

    // Left wing
    translate([-BACKPLATE_WIDTH/2, -wing_depth + BACKPLATE_THICKNESS, 0])
        cube([wing_width, wing_depth, wing_height]);

    // Right wing
    translate([BACKPLATE_WIDTH/2 - wing_width, -wing_depth + BACKPLATE_THICKNESS, 0])
        cube([wing_width, wing_depth, wing_height]);
}

// ============================================
// BEARING MOUNT HOLES
// ============================================

module bearing_mount_holes() {
    // M4 holes to attach bearing blocks
    // Positioned on the wings

    hole_z_positions = [10, BB_HEIGHT - 5];

    for (side = [-1, 1]) {
        x = side * (BACKPLATE_WIDTH/2 - 15);

        for (z = hole_z_positions) {
            // Through hole in wing
            translate([x, -BACKPLATE_Y_FRONT - 5, z])
            rotate([-90, 0, 0])
                cylinder(d = M4_HOLE, h = BACKPLATE_Y_FRONT + BACKPLATE_THICKNESS + 10, $fn = 24);
        }
    }
}

// ============================================
// WEIGHT REDUCTION (Optional)
// ============================================

module weight_pockets() {
    // Pockets in back of backplate
    pocket_depth = BACKPLATE_THICKNESS - 5;

    translate([-BACKPLATE_WIDTH/2 + 40, BACKPLATE_THICKNESS - pocket_depth, 40])
        cube([BACKPLATE_WIDTH - 80, pocket_depth + 1, 40]);
}

// ============================================
// RENDER
// ============================================

color(C_BACKPLATE)
backplate();

// Show groove positions (debug)
echo("=== GROOVE POSITIONS ===");
for (i = [0 : 5 : NUM_SLATS - 1]) {
    echo(str("Groove ", i, ": X = ", slat_x(i), "mm"));
}

// ============================================
// VERIFICATION
// ============================================

echo("");
echo("=== BACKPLATE VERIFICATION ===");
echo(str("Size: ", BACKPLATE_WIDTH, " x ", BACKPLATE_THICKNESS, " x ", BACKPLATE_HEIGHT, "mm"));
echo(str("Groove count: ", NUM_SLATS));
echo(str("Groove width: ", GROOVE_WIDTH, "mm (tab=", TAB_THICKNESS, "mm, clearance=", GROOVE_WIDTH - TAB_THICKNESS, "mm)"));
echo(str("Groove depth: ", GROOVE_DEPTH, "mm"));
echo(str("Groove type: OPEN-TOP (for easy slat insertion)"));
echo("");
echo("POSITION (in assembly):");
echo(str("  Front face Y: ", BACKPLATE_Y_FRONT, "mm"));
echo(str("  Cam max Y: ", CAM_MAX_RADIUS, "mm"));
echo(str("  Clearance: ", BACKPLATE_Y_FRONT - CAM_MAX_RADIUS, "mm"));
echo("");
echo("TAB ENGAGEMENT:");
echo(str("  Tab reaches Y: ", SLAT_DEPTH/2 - 5 + TAB_DEPTH + 5, "mm"));
echo(str("  Groove starts Y: ", BACKPLATE_Y_FRONT, "mm"));
echo(str("  Tab penetration: ", (SLAT_DEPTH/2 - 5 + TAB_DEPTH + 5) - BACKPLATE_Y_FRONT, "mm ✓"));
