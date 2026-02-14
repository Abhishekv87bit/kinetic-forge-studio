// =========================================================
// FULL ASSEMBLY — Triple Helix MVP Complete
// =========================================================
// Everything together, animated by single $t parameter.
//
// Power path:
//   Hand Crank → Belt → 3 Helix Shafts (50mm each)
//   → 5 Eccentric Cams per helix (15 total)
//   → 15 Gravity Ribs → 15 Dyneema Cables
//   → 3-Tier Matrix (5 channels × 19 pulleys × 3 tiers)
//   → 19 Strings through U-detours (9 pulleys each)
//   → Guide Plates (2 bushings each) → 19 Weighted Blocks
//
// Animation: single $t (0→1) drives everything.
//   - Crank rotates 360°
//   - 5 cams per helix produce sinusoidal slider motion (72° phase steps)
//   - Block Z = sum of 3 tier displacements
//
// Material: 0.5mm braided Dyneema/PE (both strings and wires)
// Friction efficiency: 75% (0.97^9 × 0.995^2)
//
// Toggle each subsystem on/off for debugging.
// =========================================================

include <config.scad>
use <helix_cam_v2.scad>
use <matrix_tier_v2.scad>
use <matrix_stack.scad>
use <guide_plate.scad>
use <block_grid.scad>
use <string_routing.scad>
use <frame.scad>
use <drive_system.scad>

/* [Assembly Visibility] */
SHOW_FRAME_ASM      = true;
SHOW_DRIVE_ASM      = true;
SHOW_MATRIX_ASM     = true;
SHOW_GUIDE_ASM      = true;
SHOW_BLOCKS_ASM     = true;
SHOW_STRINGS_ASM    = false;  // heavy to render — toggle ON for path check
SHOW_HELICES_ASM    = true;

/* [Debug] */
SECTION_CUT         = false;  // show XZ cross-section
ASM_EXPLODE         = 0;      // [0:5:100] mm extra gap between subsystems

// =========================================================
// MAIN RENDER
// =========================================================

full_assembly(anim_t());


// =========================================================
// FULL ASSEMBLY MODULE
// =========================================================

module full_assembly(t = 0) {

    // === Z LAYOUT (all relative to matrix center = Z=0) ===
    // Tier 1 center:  +TIER_PITCH mm  (top tier)
    // Tier 2 center:    0mm           (middle tier)
    // Tier 3 center:  -TIER_PITCH mm  (bottom tier)
    //
    // Tier 1 top:     +TIER_PITCH + TIER_ENVELOPE_H/2
    // Tier 3 bottom:  -TIER_PITCH - TIER_ENVELOPE_H/2
    //
    // Guide plates:   below Tier 3 - POST_MATRIX_GAP
    // Blocks:         below guide plates
    // Anchor plate:   above Tier 1

    tier1_top = TIER_PITCH + TIER_ENVELOPE_H / 2;
    tier3_bot = -TIER_PITCH - TIER_ENVELOPE_H / 2;

    // Guide plate Z positions
    gp1_z = tier3_bot - POST_MATRIX_GAP;
    gp2_z = gp1_z - GUIDE_PLATE_THICK - GUIDE_PLATE_GAP;

    // Block Z (hanging below guide plates)
    block_z = gp2_z - GUIDE_PLATE_THICK - 60;

    // Anchor plate Z (above tier 1)
    anchor_z = tier1_top + 30;

    // === FRAME ===
    if (SHOW_FRAME_ASM)
        translate([0, 0, ASM_EXPLODE > 0 ? -ASM_EXPLODE : 0])
            frame_assembly();

    // === DRIVE SYSTEM (belts + crank) ===
    if (SHOW_DRIVE_ASM)
        translate([0, 0, ASM_EXPLODE > 0 ? ASM_EXPLODE * 2 : 0])
            drive_system_assembly(t);

    // === MATRIX STACK (3 tiers at 0°/120°/240°) ===
    if (SHOW_MATRIX_ASM)
        matrix_stack_assembly(t);

    // === GUIDE PLATES (below tier 3) ===
    if (SHOW_GUIDE_ASM) {
        translate([0, 0, gp1_z + (ASM_EXPLODE > 0 ? -ASM_EXPLODE : 0)])
            guide_plate_assembly();
    }

    // === BLOCK GRID (19 hex blocks, animated) ===
    if (SHOW_BLOCKS_ASM) {
        translate([0, 0, block_z + (ASM_EXPLODE > 0 ? -ASM_EXPLODE * 3 : 0)])
            block_grid_assembly(t);
    }

    // === STRING ROUTING (19 strings, all contact points) ===
    if (SHOW_STRINGS_ASM)
        string_routing_assembly(t);

    // === HELIX CAM STACKS (3 helices at 120° vertices) ===
    if (SHOW_HELICES_ASM) {
        for (tier_idx = [0 : 2]) {
            translate([0, 0, ASM_EXPLODE > 0 ? ASM_EXPLODE : 0])
                helix_assembly_positioned(tier_idx, t);
        }
    }

    // === ANCHOR PLATE (simple visualization) ===
    color([0.6, 0.6, 0.7, 0.5])
    translate([0, 0, anchor_z + (ASM_EXPLODE > 0 ? ASM_EXPLODE * 2 : 0)]) {
        // Simple hex plate with 19 string holes
        difference() {
            // Hex plate
            linear_extrude(height = 3)
                circle(r = FRAME_HEX_R / cos(30), $fn = 6);

            // String holes
            positions = hex_grid(HEX_RINGS, BLOCK_SPACING);
            for (pos = positions)
                translate([pos[0], pos[1], -1])
                    cylinder(d = 3, h = 5, $fn = 10);
        }
    }

    // === CROSS-SECTION CUT (debug) ===
    // Toggle SECTION_CUT to see internal structure
    // To use: wrap desired sub-assembly call in difference() with this
    if (SECTION_CUT) {
        echo("SECTION CUT is ON — wrap subsystems in difference() to use");
    }

    // === VERIFICATION REPORT ===
    echo(str(""));
    echo(str("╔════════════════════════════════════════════╗"));
    echo(str("║  TRIPLE HELIX MVP — FULL ASSEMBLY CHECK   ║"));
    echo(str("╠════════════════════════════════════════════╣"));

    // Block count
    _positions = hex_grid(HEX_RINGS, BLOCK_SPACING);
    echo(str("║ Blocks: ", len(_positions), " (expected: ", NUM_BLOCKS, ")"));

    // Cam count
    echo(str("║ Cams per helix: ", NUM_CAMS, " (one per channel strip)"));
    echo(str("║ Total cams: ", NUM_CAMS * NUM_TIERS, " (", NUM_CAMS, " × ", NUM_TIERS, " helices)"));
    echo(str("║ Twist per cam: ", TWIST_PER_CAM, "°"));

    // Helix
    echo(str("║ Helix length: ", HELIX_LENGTH, "mm"));
    echo(str("║ Helix distance from matrix: ", HELIX_DISTANCE, "mm"));

    // Total pulleys
    _total_pulleys = NUM_BLOCKS * PULLEYS_PER_STRING;
    echo(str("║ Total pulleys: ", _total_pulleys, " (", PULLEYS_PER_STRING, " per string × ", NUM_BLOCKS, " strings)"));

    // Total bearings (one per cam)
    echo(str("║ Total cam bearings: ", NUM_CAMS * NUM_TIERS));

    // String/Wire material
    echo(str("║ String: 0.5mm braided Dyneema/PE"));
    echo(str("║ Wire (cam→slider): same material"));

    // Friction
    echo(str("║ Friction per pulley: ", FRICTION_PER_PULLEY));
    echo(str("║ Friction per bushing: ", FRICTION_PER_BUSHING));
    echo(str("║ Overall efficiency: ", round(FRICTION_EFF * 1000) / 10, "%"));

    // Dimensions
    echo(str("║ "));
    echo(str("║ DIMENSIONS:"));
    echo(str("║   Tier envelope: ", TIER_ENVELOPE_H, "mm"));
    echo(str("║   Inter-tier gap: ", INTER_TIER_GAP, "mm"));
    echo(str("║   Matrix stack height: ", MATRIX_TOTAL_H, "mm"));
    echo(str("║   Tier pitch: ", TIER_PITCH, "mm"));
    echo(str("║   Longest channel: ", max(CH_LENS[0], CH_LENS[1], CH_LENS[2], CH_LENS[3], CH_LENS[4]), "mm (CH3)"));
    echo(str("║   Frame diameter: ", FRAME_DIAMETER, "mm (F-F)"));
    echo(str("║   Frame corner-to-corner: ", round(FRAME_CORNER_R * 2 * 10) / 10, "mm"));

    // Z Layout
    echo(str("║ "));
    echo(str("║ Z LAYOUT:"));
    echo(str("║   Anchor plate: Z=", anchor_z, "mm"));
    echo(str("║   Tier 1 center: Z=+", TIER_PITCH, "mm"));
    echo(str("║   Tier 2 center: Z=0mm"));
    echo(str("║   Tier 3 center: Z=-", TIER_PITCH, "mm"));
    echo(str("║   Guide plate 1: Z=", gp1_z, "mm"));
    echo(str("║   Guide plate 2: Z=", gp2_z, "mm"));
    echo(str("║   Block grid: Z=", block_z, "mm"));
    echo(str("║   Total height (anchor→blocks): ", anchor_z - block_z, "mm"));

    // Bed fit check
    echo(str("║ "));
    echo(str("║ BED FIT (Creality K2 Plus 350³):"));
    _longest_ch = max(CH_LENS[0], CH_LENS[1], CH_LENS[2], CH_LENS[3], CH_LENS[4]);
    echo(str("║   Longest channel: ", _longest_ch, " < 350 → ",
             _longest_ch < BED_X ? "✓" : "⚠ TOO WIDE"));
    echo(str("║   Helix length: ", HELIX_LENGTH, " < 350 → ",
             HELIX_LENGTH < BED_Z ? "✓" : "⚠ TOO LONG"));
    _frame_c2c = FRAME_CORNER_R * 2;
    echo(str("║   Frame c-to-c: ", round(_frame_c2c), " < 350 → ",
             _frame_c2c < BED_X ? "✓" : "⚠ TOO WIDE"));

    // Wave output
    _max_travel = GAIN_PER_TIER * ECCENTRICITY * 3;
    _rms_travel = GAIN_PER_TIER * ECCENTRICITY * sqrt(3);
    echo(str("║ "));
    echo(str("║ WAVE OUTPUT:"));
    echo(str("║   Gain per tier: ", GAIN_PER_TIER, ":1"));
    echo(str("║   Eccentricity: ±", ECCENTRICITY, "mm"));
    echo(str("║   Max block travel (constructive): ±", _max_travel, "mm"));
    echo(str("║   Typical block travel (RMS): ±", round(_rms_travel * 10) / 10, "mm"));

    echo(str("║ "));
    echo(str("╚════════════════════════════════════════════╝"));
}
