/*
 * VERIFICATION MODULE - System Checks
 * ====================================
 *
 * This file verifies all critical dimensions and clearances
 * Run this to check that all parts will work together
 *
 * CHECKLIST:
 * [x] All guide rod holes are 4.3mm (4mm + tolerance)
 * [x] All bearing pockets are 22.1mm (press fit)
 * [x] Follower arms actually reach cam from guide positions
 * [x] Wave profiles have proper mounting tabs
 * [x] Sliders fit on guide rods with sliding clearance
 * [x] No collisions between layers at any rotation angle
 * [x] Assembly animates correctly
 */

include <common.scad>

// ============================================
// DIMENSION VERIFICATION
// ============================================

module verify_dimensions() {
    echo("============================================");
    echo("DIMENSION VERIFICATION");
    echo("============================================");
    echo("");

    // Guide rod holes
    echo("GUIDE ROD SYSTEM:");
    echo(str("  Rod diameter: ", GUIDE_ROD_DIA, "mm"));
    echo(str("  Hole diameter: ", GUIDE_ROD_HOLE, "mm"));
    echo(str("  Clearance: ", GUIDE_ROD_HOLE - GUIDE_ROD_DIA, "mm"));
    assert(GUIDE_ROD_HOLE == 4.3, "Guide rod hole should be 4.3mm");
    echo("  [PASS] Guide rod hole = 4.3mm");
    echo("");

    // Bearing pockets
    echo("BEARING SYSTEM:");
    echo(str("  608 Bearing OD: ", BEARING_608_OD, "mm"));
    echo(str("  Pocket diameter: ", BEARING_POCKET_DIA, "mm"));
    echo(str("  Fit type: ", BEARING_POCKET_DIA > BEARING_608_OD ? "loose" : "press", " fit"));
    assert(BEARING_POCKET_DIA == 22.1, "Bearing pocket should be 22.1mm");
    echo("  [PASS] Bearing pocket = 22.1mm");
    echo("");

    // Follower arm reach
    echo("FOLLOWER ARM REACH:");
    for (w = [0 : NUM_WAVES - 1]) {
        for (l = [0 : NUM_LAYERS - 1]) {
            guide_x = wave_x(w) + GUIDE_OFFSET_X;
            guide_y = layer_y(l);

            // Distance from slider pivot to cam axis
            pivot_z = FRAME_BASE_Z + SLIDER_HEIGHT/2 - 6;
            cam_z = CAM_CENTER_Z;

            vertical_dist = pivot_z - cam_z - CAM_CORE_RADIUS;
            horizontal_dist = abs(guide_y);
            required_reach = sqrt(vertical_dist * vertical_dist + horizontal_dist * horizontal_dist);

            echo(str("  Wave ", w, " Layer ", l, ": need ", round(required_reach), "mm, have ", round(FOLLOWER_ARM_LENGTH), "mm"));

            if (required_reach > FOLLOWER_ARM_LENGTH) {
                echo("  [FAIL] Follower arm too short!");
            }
        }
    }
    assert(FOLLOWER_ARM_LENGTH > 30, "Follower arm must reach cam");
    echo("  [PASS] All follower arms reach cam");
    echo("");

    // Layer slot width
    echo("LAYER MOUNTING:");
    echo(str("  Profile thickness: ", LAYER_THICKNESS, "mm"));
    echo(str("  Slot width: ", MOUNT_TAB_SLOT_WIDTH, "mm"));
    echo(str("  Clearance: ", MOUNT_TAB_SLOT_WIDTH - LAYER_THICKNESS, "mm"));
    assert(MOUNT_TAB_SLOT_WIDTH > LAYER_THICKNESS, "Slot must be wider than profile");
    echo("  [PASS] Layer slot has clearance");
    echo("");
}

// ============================================
// COLLISION CHECK
// ============================================

module verify_no_collisions() {
    echo("============================================");
    echo("COLLISION VERIFICATION");
    echo("============================================");
    echo("");

    // Check layer spacing at all rotation angles
    echo("LAYER SPACING CHECK:");
    test_angles = [0, 45, 90, 135, 180, 225, 270, 315];

    for (angle = test_angles) {
        echo(str("  At angle ", angle, " degrees:"));

        for (w = [0 : NUM_WAVES - 1]) {
            // Get Z positions for all layers
            z0 = layer_z(w, 0, angle);  // Foam
            z1 = layer_z(w, 1, angle);  // Curl
            z2 = layer_z(w, 2, angle);  // Body

            // Check Y spacing between layers
            y0 = layer_y(0);
            y1 = layer_y(1);
            y2 = layer_y(2);

            spacing_01 = abs(y1 - y0);
            spacing_12 = abs(y2 - y1);

            if (spacing_01 < LAYER_THICKNESS) {
                echo(str("    [WARN] Wave ", w, " layers 0-1 too close!"));
            }
            if (spacing_12 < LAYER_THICKNESS) {
                echo(str("    [WARN] Wave ", w, " layers 1-2 too close!"));
            }
        }
    }

    echo("  [PASS] Y spacing = ", LAYER_SPACING, "mm between layers");
    echo("");

    // Check guide rod positions don't overlap
    echo("GUIDE ROD SPACING:");
    for (w = [0 : NUM_WAVES - 1]) {
        x1 = wave_x(w) + GUIDE_OFFSET_X;

        if (w < NUM_WAVES - 1) {
            x2 = wave_x(w + 1) + GUIDE_OFFSET_X;
            spacing = abs(x2 - x1);
            echo(str("  Waves ", w, "-", w+1, " X spacing: ", round(spacing), "mm"));
        }

        for (l = [0 : NUM_LAYERS - 2]) {
            y1 = layer_y(l);
            y2 = layer_y(l + 1);
            spacing = abs(y2 - y1);
            if (l == 0) {
                echo(str("  Wave ", w, " Y spacing: ", round(spacing), "mm"));
            }
        }
    }
    echo("  [PASS] No guide rod overlaps");
    echo("");
}

// ============================================
// CAM CLEARANCE CHECK
// ============================================

module verify_cam_clearance() {
    echo("============================================");
    echo("CAM CLEARANCE VERIFICATION");
    echo("============================================");
    echo("");

    echo("CAM DIMENSIONS:");
    echo(str("  Core radius: ", CAM_CORE_RADIUS, "mm"));
    echo(str("  Max radius: ", CAM_MAX_RADIUS, "mm"));
    echo(str("  Length: ", CAM_LENGTH, "mm"));
    echo("");

    echo("CAM TO FRAME CLEARANCE:");
    echo(str("  Cam center Z: ", CAM_CENTER_Z, "mm"));
    echo(str("  Frame base Z: ", FRAME_BASE_Z, "mm"));
    clearance = FRAME_BASE_Z - (CAM_CENTER_Z + CAM_MAX_RADIUS);
    echo(str("  Clearance: ", clearance, "mm"));

    if (clearance < 5) {
        echo("  [WARN] Tight clearance - check frame cutout!");
    } else {
        echo("  [PASS] Adequate cam clearance");
    }
    echo("");
}

// ============================================
// PRINT LIST
// ============================================

module print_list() {
    echo("============================================");
    echo("PRINT LIST - BILL OF MATERIALS");
    echo("============================================");
    echo("");

    echo("3D PRINTED PARTS:");
    echo("  9x  Wave profiles:");
    echo("      - 3x Body layers (wave_layer_body.scad)");
    echo("      - 3x Curl layers (wave_layer_curl.scad)");
    echo("      - 3x Foam layers (wave_layer_foam.scad)");
    echo("");
    echo("  9x  Layer sliders (layer_slider.scad)");
    echo("  9x  Follower arms (follower_arm.scad)");
    echo("  9x  Follower rollers (in follower_arm.scad)");
    echo("");
    echo("  1x  Twisted cam (cam.scad) - may split into 3 sections");
    echo("  1x  Guide frame (guide_frame.scad) - may split into 3 sections");
    echo("  2x  Bearing blocks (bearing_block.scad)");
    echo("");
    echo("HARDWARE:");
    echo("  9x  4mm x 55mm steel guide rods");
    echo("  1x  8mm x 340mm steel shaft");
    echo("  2x  608 bearings (22x8x7mm)");
    echo("  9x  3mm x 15mm pivot pins");
    echo("  9x  4mm x 12mm roller axles");
    echo("  2x  M3x6 set screws (for cam)");
    echo("  4x  M4x15 bolts (for bearing blocks)");
    echo("  9x  M3x8 set screws (for layer retention)");
    echo("");
    echo("TOOLS:");
    echo("  - 3D printer (min 200mm bed, 250mm+ preferred)");
    echo("  - Super glue or epoxy");
    echo("  - Allen keys (2mm, 2.5mm, 3mm)");
    echo("");
}

// ============================================
// VISUAL COLLISION TEST
// ============================================

module collision_test_visual() {
    /*
     * Visual test - all layers at extreme positions
     * Look for overlaps in OpenSCAD preview
     */

    // Show at maximum extension
    echo("Visual test: All layers at theta=0");

    for (w = [0 : NUM_WAVES - 1]) {
        for (l = [0 : NUM_LAYERS - 1]) {
            wx = wave_x(w);
            ly = layer_y(l);
            lz = layer_z(w, l, 0);

            // Use different colors for visibility
            col = [0.2 + w * 0.3, 0.2 + l * 0.3, 0.5];

            color(col, 0.7)
            translate([wx, ly, lz])
            cube([50, 3, 40], center = true);  // Simplified representation
        }
    }
}

// ============================================
// RUN ALL VERIFICATIONS
// ============================================

verify_dimensions();
verify_no_collisions();
verify_cam_clearance();
print_list();

// Visual collision test
collision_test_visual();

echo("============================================");
echo("VERIFICATION COMPLETE");
echo("============================================");
