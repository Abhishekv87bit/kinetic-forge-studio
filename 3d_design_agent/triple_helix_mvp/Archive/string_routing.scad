// =========================================================
// STRING ROUTING — Complete Path Visualization (V5-based)
// =========================================================
// Traces ONE or ALL 19 strings through their complete path:
//   Anchor → Tier 1 (0°) → Tier 2 (120°) → Tier 3 (240°)
//   → Guide Plate 1 → Guide Plate 2 → Block
//
// Each string touches 15 points total:
//   [A]     Anchor (fixed above tier 1)
//   --- Tier 1 (0° rotation) ---
//   [T1-H1] Tier 1 top hole (entry through top plate)
//   [T1-R1] Tier 1 redirect_in roller (Y=+FP_ROW_Y in tier frame)
//   [T1-S]  Tier 1 slider pulley (Y=0, displaced by slider strip)
//   [T1-R2] Tier 1 redirect_out roller (Y=-FP_ROW_Y)
//   [T1-H2] Tier 1 bottom hole (exit through bottom plate)
//   --- Tier 2 (120° rotation) ---
//   [T2-H1..H2] same U-detour, rotated 120°
//   --- Tier 3 (240° rotation) ---
//   [T3-H1..H2] same U-detour, rotated 240°
//   [GP1]   Guide plate 1 bushing
//   [GP2]   Guide plate 2 bushing
//   [B]     Block attachment
//
// 9 pulleys per string (3 per tier × 3 tiers):
//   redirect_in + slider + redirect_out per tier
// 2 bushings (guide plates)
//
// Material: 0.5mm braided Dyneema/PE
// Friction: 0.97^9 × 0.995^2 = 75.0%
//
// Color coding:
//   Red    = Tier 1 path segments
//   Green  = Tier 2 path segments
//   Blue   = Tier 3 path segments
//   Yellow = Vertical free segments (anchor, inter-tier, block)
//   White  = Guide plate segments
// =========================================================

include <config.scad>

/* [Visibility] */
SHOW_STRING_LINES = true;
SHOW_CONTACT_PTS  = true;     // spheres at each contact point
SHOW_ANNOTATIONS  = false;    // text labels (slow to render)
SHOW_SINGLE       = -1;       // -1 = all 19 strings, 0-18 = single string

/* [Style] */
STRING_VIS_DIA    = 1.0;      // exaggerated for visibility (actual = 0.5mm)
CONTACT_SPHERE    = 2.5;      // contact point marker diameter
SEGMENT_FN        = 8;        // low $fn for string cylinders (speed)

// Colors per tier
C_TIER1  = [0.9, 0.2, 0.2, 0.8];    // Red
C_TIER2  = [0.2, 0.8, 0.2, 0.8];    // Green
C_TIER3  = [0.2, 0.2, 0.9, 0.8];    // Blue
C_VERT   = [0.9, 0.9, 0.2, 0.8];    // Yellow (vertical)
C_GPLATE = [0.95, 0.95, 0.95, 0.8]; // White (guide plate)

// =========================================================
// STANDALONE RENDER
// =========================================================
string_routing_assembly(anim_t());


// =========================================================
// STRING ROUTING ASSEMBLY
// =========================================================

module string_routing_assembly(t = 0) {
    positions = hex_grid(HEX_RINGS, BLOCK_SPACING);

    // === Z REFERENCE POSITIONS ===
    // Tier centers (matching matrix_stack.scad: tier_idx 0 at top, 2 at bottom)
    // tier_z = (1 - tier_idx) * TIER_PITCH
    tier_zs = [for (idx = [0:2]) (1 - idx) * TIER_PITCH];
    // tier_zs[0] = +TIER_PITCH (top tier)
    // tier_zs[1] = 0 (middle tier)
    // tier_zs[2] = -TIER_PITCH (bottom tier)

    // Anchor Z (above top of tier 1)
    anchor_z = tier_zs[0] + TIER_ENVELOPE_H / 2 + 40;

    // Guide plate positions (below tier 3)
    gp1_z = tier_zs[2] - TIER_ENVELOPE_H / 2 - POST_MATRIX_GAP;
    gp2_z = gp1_z - GUIDE_PLATE_THICK - GUIDE_PLATE_GAP;

    // Block Z (below guide plates — nominal hanging position)
    block_base_z = gp2_z - GUIDE_PLATE_THICK - 80;

    for (i = [0 : len(positions) - 1]) {
        if (SHOW_SINGLE == -1 || SHOW_SINGLE == i) {
            pos = positions[i];  // block hex grid position [x, y]

            // Block wave displacement
            dz = block_disp(pos, t);

            // Which channel and position within that channel?
            ch = block_channel(i);
            pos_in_ch = block_pos_in_channel(i);

            // Fixed pulley X position (used for entry/exit holes and redirect pulleys)
            fp_x = block_fp_x(i);

            // Slider pulley X (at rest)
            sp_x_rest = block_sp_x(i);

            // === BUILD CONTACT POINTS FOR EACH TIER ===

            // [A] Anchor — directly above block hex center
            pt_A = [pos[0], pos[1], anchor_z];

            // Tier contact points (5 per tier: H1, R1, S, R2, H2)
            t1_pts = tier_string_points(
                ch, fp_x, sp_x_rest, pos_in_ch,
                tier_zs[0], TIER_ANGLES[0],
                slider_disp(pos, 0, t)
            );
            t2_pts = tier_string_points(
                ch, fp_x, sp_x_rest, pos_in_ch,
                tier_zs[1], TIER_ANGLES[1],
                slider_disp(pos, 1, t)
            );
            t3_pts = tier_string_points(
                ch, fp_x, sp_x_rest, pos_in_ch,
                tier_zs[2], TIER_ANGLES[2],
                slider_disp(pos, 2, t)
            );

            // [GP1] Guide plate 1 — at block hex position
            pt_GP1 = [pos[0], pos[1], gp1_z];

            // [GP2] Guide plate 2
            pt_GP2 = [pos[0], pos[1], gp2_z];

            // [B] Block top
            pt_B = [pos[0], pos[1], block_base_z + dz];

            // === DRAW STRING SEGMENTS ===

            if (SHOW_STRING_LINES) {
                // Anchor → Tier 1 entry (vertical free segment)
                color(C_VERT) string_seg(pt_A, t1_pts[0]);

                // Tier 1 U-detour (5 points → 4 segments)
                color(C_TIER1) {
                    string_seg(t1_pts[0], t1_pts[1]);  // H1 → R1
                    string_seg(t1_pts[1], t1_pts[2]);  // R1 → S (slider)
                    string_seg(t1_pts[2], t1_pts[3]);  // S  → R2
                    string_seg(t1_pts[3], t1_pts[4]);  // R2 → H2
                }

                // Tier 1 exit → Tier 2 entry (inter-tier, angled due to 120° rotation)
                color(C_VERT) string_seg(t1_pts[4], t2_pts[0]);

                // Tier 2 U-detour
                color(C_TIER2) {
                    string_seg(t2_pts[0], t2_pts[1]);
                    string_seg(t2_pts[1], t2_pts[2]);
                    string_seg(t2_pts[2], t2_pts[3]);
                    string_seg(t2_pts[3], t2_pts[4]);
                }

                // Tier 2 exit → Tier 3 entry
                color(C_VERT) string_seg(t2_pts[4], t3_pts[0]);

                // Tier 3 U-detour
                color(C_TIER3) {
                    string_seg(t3_pts[0], t3_pts[1]);
                    string_seg(t3_pts[1], t3_pts[2]);
                    string_seg(t3_pts[2], t3_pts[3]);
                    string_seg(t3_pts[3], t3_pts[4]);
                }

                // Tier 3 exit → Guide plate 1
                color(C_VERT) string_seg(t3_pts[4], pt_GP1);

                // Guide plate 1 → Guide plate 2
                color(C_GPLATE) string_seg(pt_GP1, pt_GP2);

                // Guide plate 2 → Block
                color(C_VERT) string_seg(pt_GP2, pt_B);
            }

            // === CONTACT POINT MARKERS ===
            if (SHOW_CONTACT_PTS) {
                // Anchor
                color([1, 1, 0]) translate(pt_A) sphere(d = CONTACT_SPHERE * 1.5, $fn = 12);

                // Tier 1 points
                for (p = t1_pts) color(C_TIER1) translate(p) sphere(d = CONTACT_SPHERE, $fn = 10);

                // Tier 2 points
                for (p = t2_pts) color(C_TIER2) translate(p) sphere(d = CONTACT_SPHERE, $fn = 10);

                // Tier 3 points
                for (p = t3_pts) color(C_TIER3) translate(p) sphere(d = CONTACT_SPHERE, $fn = 10);

                // Guide plates
                color(C_GPLATE) {
                    translate(pt_GP1) sphere(d = CONTACT_SPHERE, $fn = 10);
                    translate(pt_GP2) sphere(d = CONTACT_SPHERE, $fn = 10);
                }

                // Block
                color(C_BLOCK) translate(pt_B) sphere(d = CONTACT_SPHERE * 1.5, $fn = 12);
            }
        }
    }

    echo(str("=== STRING ROUTING ==="));
    echo(str("Strings: ", NUM_BLOCKS));
    echo(str("Contact points per string: 15 (anchor + 5×3 tiers + 2 guide + block)"));
    echo(str("Pulleys per string: ", PULLEYS_PER_STRING));
    echo(str("Bushings per string: ", BUSHINGS_PER_STRING));
    echo(str("Friction efficiency: ", round(FRICTION_EFF * 1000) / 10, "%"));
    echo(str("Material: 0.5mm braided Dyneema/PE"));
    echo(str("Anchor Z: ", anchor_z, "mm"));
    echo(str("Guide plate 1 Z: ", gp1_z, "mm"));
    echo(str("Guide plate 2 Z: ", gp2_z, "mm"));
    echo(str("Block base Z: ", block_base_z, "mm"));
}


// =========================================================
// TIER STRING POINTS
// =========================================================
// Returns 5 contact points [H1, R1, S, R2, H2] for one string
// through one tier, in world coordinates.
//
// ch          = channel index (0-4)
// fp_x        = fixed pulley X in tier-local frame
// sp_x_rest   = slider pulley X at rest in tier-local frame
// pos_in_ch   = pulley position within channel
// tier_center_z = Z center of this tier in world
// tier_angle  = rotation angle of this tier (0°, 120°, 240°)
// slide_disp  = slider displacement for this tier/block
//
// V5 tier-local coordinate system (before rotate([90,0,0])):
//   X = along channels (slider travel direction)
//   Y = housing depth
//   Z = stacking direction (vertical)
//
// After V5's rotate([90,0,0]) and our tier rotation:
//   tier_angle rotates the entire tier around world Z.
//   Channel Z in V5 code → vertical Z in world.
//   X in V5 code stays as radial from center.
//   Y in V5 code (housing depth) → perpendicular to slider direction.

function tier_string_points(ch, fp_x, sp_x_rest, pos_in_ch,
                            tier_center_z, tier_angle, slide_disp) =
    let(
        // Channel vertical position within tier (from V5: (ch-2)*STACK_OFFSET)
        ch_z_offset = (ch - 2) * STACK_OFFSET,

        // Z positions of the 5 contact points within this tier
        // Top of channel: ch_z_offset + CH_GAPS[ch]/2
        // Bottom of channel: ch_z_offset - CH_GAPS[ch]/2
        // Wall above: + WALL_THICKNESS
        // Redirect_in at upper quarter, slider at center, redirect_out at lower quarter
        half_gap = CH_GAPS[ch] / 2,
        z_H1  = tier_center_z + ch_z_offset + half_gap + WALL_THICKNESS,  // top plate surface
        z_R1  = tier_center_z + ch_z_offset + half_gap * 0.5,  // upper quarter
        z_S   = tier_center_z + ch_z_offset,                    // center (slider)
        z_R2  = tier_center_z + ch_z_offset - half_gap * 0.5,  // lower quarter
        z_H2  = tier_center_z + ch_z_offset - half_gap - WALL_THICKNESS,  // bottom plate

        // Local XY positions (tier frame):
        //   Entry/exit holes: (fp_x, 0) — directly above/below the fixed pulleys
        //   Redirect_in: (fp_x, +FP_ROW_Y) — upper row fixed pulley
        //   Slider: (sp_x_rest + slide_disp, 0) — slider moves along X
        //   Redirect_out: (fp_x, -FP_ROW_Y) — lower row fixed pulley
        h1_local = [fp_x, 0],
        r1_local = [fp_x, FP_ROW_Y],
        s_local  = [sp_x_rest + slide_disp, 0],
        r2_local = [fp_x, -FP_ROW_Y],
        h2_local = [fp_x, 0],

        // Rotate all XY positions by tier_angle around Z
        ca = cos(tier_angle),
        sa = sin(tier_angle),

        h1_rot = [h1_local[0]*ca - h1_local[1]*sa, h1_local[0]*sa + h1_local[1]*ca],
        r1_rot = [r1_local[0]*ca - r1_local[1]*sa, r1_local[0]*sa + r1_local[1]*ca],
        s_rot  = [s_local[0]*ca  - s_local[1]*sa,  s_local[0]*sa  + s_local[1]*ca],
        r2_rot = [r2_local[0]*ca - r2_local[1]*sa, r2_local[0]*sa + r2_local[1]*ca],
        h2_rot = [h2_local[0]*ca - h2_local[1]*sa, h2_local[0]*sa + h2_local[1]*ca]
    )
    [
        [h1_rot[0], h1_rot[1], z_H1],
        [r1_rot[0], r1_rot[1], z_R1],
        [s_rot[0],  s_rot[1],  z_S],
        [r2_rot[0], r2_rot[1], z_R2],
        [h2_rot[0], h2_rot[1], z_H2]
    ];


// =========================================================
// STRING SEGMENT — Hull of Two Spheres
// =========================================================
// Creates a tapered cylinder between two 3D points.
// Uses hull() of two spheres for reliable arbitrary-angle connections.

module string_seg(p1, p2) {
    hull() {
        translate(p1) sphere(d = STRING_VIS_DIA, $fn = SEGMENT_FN);
        translate(p2) sphere(d = STRING_VIS_DIA, $fn = SEGMENT_FN);
    }
}


// =========================================================
// VERIFICATION
// =========================================================

// Test path length for block 0 through all 3 tiers
_test_ch = block_channel(0);
_test_fp_x = block_fp_x(0);
_test_sp_x = block_sp_x(0);

// Tier 1 at rest (t=0, slide_disp=0)
_t1_test = tier_string_points(_test_ch, _test_fp_x, _test_sp_x, 0,
                               TIER_PITCH, 0, 0);
_t1_path = norm(_t1_test[0] - _t1_test[1]) +
           norm(_t1_test[1] - _t1_test[2]) +
           norm(_t1_test[2] - _t1_test[3]) +
           norm(_t1_test[3] - _t1_test[4]);

echo(str("=== STRING PATH LENGTHS (block 0, at rest) ==="));
echo(str("Single tier U-detour path: ~", round(_t1_path * 10) / 10, "mm"));
echo(str("Three tiers (approx): ~", round(_t1_path * 3 * 10) / 10, "mm"));
echo(str("Estimated total per string: ~",
    round((_t1_path * 3 + 40 + 2 * TIER_PITCH + POST_MATRIX_GAP +
           GUIDE_PLATE_GAP + 80) * 10) / 10, "mm"));
echo(str("Block 0 → channel ", _test_ch, ", position ", block_pos_in_channel(0)));
echo(str("Block 0 FP_X=", _test_fp_x, " SP_X=", _test_sp_x));
