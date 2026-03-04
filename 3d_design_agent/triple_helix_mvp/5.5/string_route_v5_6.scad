// =========================================================
// STRING ROUTE V5.6 — Cable Path Visualization
// =========================================================
// Shows string paths from follower eyelets through the sculpture.
//
// STRING PATH (per column, per tier):
//   1. FOLLOWER EYELET → (free span, radially inward toward matrix)
//   2. DAMPENER HOLE → (passes through dampener bar, redirects to tier face)
//   3. FIXED PULLEY (far) → (string wraps 180deg around upper fixed pulley)
//   4. SLIDER PULLEY → (wraps under slider pulley, reverses)
//   5. FIXED PULLEY (near) → (wraps 180deg around lower fixed pulley)
//   6. TIE-OFF PIN on slider → (string anchored to slider pin)
//
//   From slider, a SECOND string runs:
//   7. SLIDER PIN (bottom) → downward through matrix
//   8. GUIDE PLATE FUNNEL → (tapered bore constrains to vertical)
//   9. ANCHOR PLATE HOLE → (tied off with retainer knot on top face)
//   ... OR directly to BLOCK below guide plate
//
// The cam's radial oscillation at the eyelet pulls string IN,
// which pulls the slider toward the helix (via redirect pulleys).
// When cam releases, the block weight pulls the string back,
// returning the slider to rest position.
//
// Motion budget:
//   CAM_STROKE = 2 × ECCENTRICITY = 9.6mm (full cam rotation)
//   SLIDER_BIAS = 0.80 → REST_OFFSET = 3.84mm
//   MAX_BLOCK_TRAVEL = 3 × ECCENTRICITY = 14.4mm (summation)
//
// This file renders:
//   - String paths as thin cylinders (hull'd sphere pairs)
//   - Labeled waypoints
//   - Single tier for clarity (set SHOW_TIER to pick which)
// =========================================================

include <config_v5_5.scad>
use <matrix_tier_v5_6.scad>

$fn = 16;

// =============================================
// STRING ROUTING PARAMETERS
// =============================================
_STR_DIA      = STRING_DIA * 4;  // exaggerated for visibility (0.5mm too thin to see)
_STR_COLOR    = C_STRING;
_WAYPOINT_DIA = 2.0;

// Slider strip offset (replicated from tier — cannot use `use` vars)
_SR_MARGIN_HELIX = SP_OD/2 + 2.5 + 0.5;   // END_STOP_W = 2.5
_SR_MARGIN_ARM   = SP_OD/2 + 0.5;
_SR_STRIP_OFFSET = (_SR_MARGIN_HELIX - _SR_MARGIN_ARM) / 2;

// Which tier to show (0=T1 at +TIER_PITCH, 1=T2 at 0, 2=T3 at -TIER_PITCH)
SHOW_TIER_IDX = 1;

// Which channel to highlight (-1 = all)
HIGHLIGHT_CH  = 3;   // center channel

// Toggle components
SHOW_MATRIX   = true;
SHOW_STRINGS  = true;
SHOW_WAYPOINTS = true;
SHOW_BLOCKS   = true;

// =============================================
// TIER GEOMETRY for current view tier
// =============================================
_tier_angle = TIER_ANGLES[SHOW_TIER_IDX];
_tier_z     = (1 - SHOW_TIER_IDX) * TIER_PITCH;
_helix_angle = _tier_angle;  // helix faces the tier

// Dampener bar position (radial from center at DAMPENER_FRAC along arm)
// Approximation: halfway between hex edge and helix
_damp_r = (HEX_R + 5 + ECCENTRICITY + CAM_BRG_OD/2 + FOLLOWER_ARM_LENGTH) / 2;

// Helix center position (from config)
_helix_r = 151.3;  // HELIX_R from frame geometry (auto-computed in monolith)

// Follower tip reach from shaft center
_follower_reach = CAM_ECC + CAM_BRG_OD/2 + FOLLOWER_ARM_LENGTH;

// =============================================
// COLORS
// =============================================
C_WAYPOINT = [1.0, 0.3, 0.3, 0.9];

// =============================================
// STANDALONE RENDER
// =============================================
echo(str("=== STRING ROUTE V5.6 — Tier ", SHOW_TIER_IDX, " ==="));
echo(str("Tier angle=", _tier_angle, "deg | Z=", _tier_z, "mm"));
echo(str("Helix R=", _helix_r, "mm | Follower reach=", _follower_reach, "mm"));
echo(str("Dampener R=", _damp_r, "mm | Dampener hole dia=", DAMPENER_HOLE_DIA, "mm"));
echo(str("String: ", STRING_DIA, "mm Dyneema | Pulleys: FP=", FP_OD, " SP=", SP_OD));
echo(str("Block drop=", _BLOCK_DROP, "mm | Block height=", _BLOCK_HEIGHT_CFG, "mm"));

// Render
string_route_assembly();


// =========================================================
// STRING ROUTE ASSEMBLY
// =========================================================
module string_route_assembly() {
    // Matrix tier (for context)
    if (SHOW_MATRIX) {
        _disps = [for (ch = [0 : NUM_CHANNELS - 1]) 0];
        translate([0, 0, _tier_z])
            rotate([0, 0, _tier_angle])
                rotate([90, 0, 0])
                    matrix_tier(_disps);
    }

    // String routes
    if (SHOW_STRINGS) {
        for (ch = [0 : NUM_CHANNELS - 1]) {
            if (HIGHLIGHT_CH < 0 || ch == HIGHLIGHT_CH) {
                if (CH_LENS[ch] > 0 && COL_COUNTS[ch] > 0) {
                    _raw_n = raw_col_count(CH_LENS[ch]);
                    // Route one string per column in this channel
                    for (j = [0 : max(0, _raw_n - 1)]) {
                        _px = col_x(_raw_n, j, ch);
                        if (col_inside_hex(_px, CH_OFFSETS[ch])) {
                            _route_one_string(ch, _px);
                        }
                    }
                }
            }
        }
    }
}


// =========================================================
// ROUTE ONE STRING — full path from follower to block
// =========================================================
// ch = channel index, col_x = column X position in tier-local coords
module _route_one_string(ch, col_x_local) {
    // All points are in WORLD coordinates.
    // Tier-local X,Z → world XY via rotation by tier_angle
    // Tier-local Y → world Z at tier height

    _d = CH_OFFSETS[ch];       // channel offset (tier-local Z)
    _strip_off = _SR_STRIP_OFFSET;
    _cx = col_x_local + _strip_off;

    // ---- Waypoint 1: FOLLOWER EYELET (on helix, radially inward) ----
    // Helix is at _helix_r from center, at _helix_angle
    // Follower tip extends inward (toward center) by _follower_reach
    _hx = _helix_r * cos(_helix_angle);
    _hy = _helix_r * sin(_helix_angle);
    // Direction from helix toward center
    _hr = sqrt(_hx*_hx + _hy*_hy);
    _hdir_x = -_hx / _hr;
    _hdir_y = -_hy / _hr;

    // Follower eyelet position (radially inward from helix)
    // The eyelet Z depends on which cam disc this channel maps to
    _cam_z_offset = ch * AXIAL_PITCH - HELIX_LENGTH/2 + AXIAL_PITCH/2;
    _eyelet_x = _hx + _hdir_x * _follower_reach;
    _eyelet_y = _hy + _hdir_y * _follower_reach;
    _eyelet_z = _tier_z;  // at tier height (follower is at cam Z which is tier Z)

    wp1 = [_eyelet_x, _eyelet_y, _eyelet_z];

    // ---- Waypoint 2: DAMPENER HOLE (on dampener bar, between arms) ----
    // Dampener bar sits at ~DAMPENER_FRAC along the corridor arms
    // Approximate: radially inward from helix, at damp_r
    _damp_x = _damp_r * cos(_helix_angle);
    _damp_y = _damp_r * sin(_helix_angle);
    wp2 = [_damp_x, _damp_y, _tier_z];

    // ---- Waypoint 3: MATRIX ENTRY (at hex edge, tier face) ----
    // String enters the matrix tier at the hex boundary
    // Convert tier-local coords to world:
    //   tier-local X → world radial direction (parallel to tier face)
    //   tier-local Y → world Z offset (into/out of tier face)
    //   tier-local Z → world lateral (along hex chord)
    _ta_rad = _tier_angle;
    _face_r = HEX_R + 2;  // just outside hex ring

    // Entry point: on the helix-facing edge of the hex
    _entry_x = _face_r * cos(_ta_rad);
    _entry_y = _face_r * sin(_ta_rad);
    wp3 = [_entry_x, _entry_y, _tier_z];

    // ---- Waypoint 4: FIXED PULLEY (far, upper row) ----
    // In tier-local coords: (col_x, +FP_ROW_Y, ch_offset)
    // Transform to world
    wp4 = _tier_to_world(_cx, FP_ROW_Y, _d);

    // ---- Waypoint 5: SLIDER PULLEY ----
    // In tier-local: (col_x + SLIDER_REST_OFFSET, 0, ch_offset)
    wp5 = _tier_to_world(_cx + SLIDER_REST_OFFSET, 0, _d);

    // ---- Waypoint 6: FIXED PULLEY (near, lower row) ----
    wp6 = _tier_to_world(_cx, -FP_ROW_Y, _d);

    // ---- Waypoint 7: TIE-OFF / GUIDE PLATE ----
    // String exits matrix going DOWN through guide plate
    // In tier-local: (col_x, -ch_offset in guide plate frame)
    _guide_z = TIER3_BOT - 6 - 2;  // below lower ring + ledge + guide plate
    wp7 = _tier_to_world(_cx, 0, _d);
    wp7_down = [wp7[0], wp7[1], _guide_z];

    // ---- Waypoint 8: BLOCK ----
    _block_z = _guide_z - _BLOCK_DROP;
    wp8 = [wp7_down[0], wp7_down[1], _block_z];

    // ---- RENDER STRING SEGMENTS ----
    color(_STR_COLOR) {
        // Segment 1: Follower → Dampener
        _string_seg(wp1, wp2);

        // Segment 2: Dampener → Matrix entry
        _string_seg(wp2, wp3);

        // Segment 3: Matrix entry → Far fixed pulley
        _string_seg(wp3, wp4);

        // Segment 4: Far fixed pulley → Slider pulley
        _string_seg(wp4, wp5);

        // Segment 5: Slider pulley → Near fixed pulley
        _string_seg(wp5, wp6);

        // Segment 6: Near fixed pulley → below (toward guide plate)
        _string_seg(wp6, wp7);

        // Segment 7: Through guide plate → Block
        _string_seg(wp7, wp7_down);
        _string_seg(wp7_down, wp8);
    }

    // Waypoint markers
    if (SHOW_WAYPOINTS) {
        color(C_WAYPOINT) {
            _waypoint(wp1, "E");   // Eyelet
            _waypoint(wp2, "D");   // Dampener
            _waypoint(wp3, "M");   // Matrix entry
            _waypoint(wp4, "Ff");  // Fixed far
            _waypoint(wp5, "S");   // Slider
            _waypoint(wp6, "Fn");  // Fixed near
        }
    }

    // Block
    if (SHOW_BLOCKS) {
        color(C_BLOCK)
        translate(wp8)
            cube([COL_PITCH * 0.8, COL_PITCH * 0.8, _BLOCK_HEIGHT_CFG], center = true);
    }
}


// =========================================================
// HELPERS
// =========================================================

// Transform tier-local (x, y, z) to world coordinates
// Tier-local: X=slider, Y=depth, Z=channel stack
// World transform: rotate([90,0,0]) then rotate([0,0,tier_angle])
// Then translate to tier_z
function _tier_to_world(lx, ly, lz) =
    let(
        // rotate([90,0,0]): x'=x, y'=-z, z'=y
        rx = lx,
        ry = -lz,
        rz = ly,
        // rotate([0,0,tier_angle]): x''=rx*cos(a)-ry*sin(a), y''=rx*sin(a)+ry*cos(a), z''=rz
        a = _tier_angle,
        wx = rx * cos(a) - ry * sin(a),
        wy = rx * sin(a) + ry * cos(a),
        wz = rz + _tier_z
    )
    [wx, wy, wz];

// String segment: hull of two small spheres
module _string_seg(p1, p2) {
    hull() {
        translate(p1) sphere(d = _STR_DIA, $fn = 8);
        translate(p2) sphere(d = _STR_DIA, $fn = 8);
    }
}

// Waypoint marker sphere with label
module _waypoint(pos, label) {
    translate(pos) {
        sphere(d = _WAYPOINT_DIA, $fn = 12);
        translate([_WAYPOINT_DIA, 0, _WAYPOINT_DIA])
            linear_extrude(0.5)
                text(label, size = 2, halign = "left", valign = "bottom",
                     font = "Liberation Mono:style=Bold");
    }
}
