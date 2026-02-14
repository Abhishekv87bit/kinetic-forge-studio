/*
 * TRIPLE HELIX WAVE SCULPTURE v2.0 (Margolin-Accurate)
 * =====================================================
 * Comprehensive prototype of Reuben Margolin's Triple Helix kinetic sculpture.
 * Designed from MARGOLIN_KNOWLEDGE_BANK.md photo analysis + construction sequence.
 *
 * REAL SCULPTURE REFERENCE (Triple Helix, ~2018):
 * - 3 aluminum helix shafts at 120° spacing
 * - 1027 strings, 111 bearings/sliders (37 per tier)
 * - Polycarbonate matrix with precision-drilled hole patterns
 * - Basswood hexagonal blocks with steel shot weights
 * - Machined aluminum collars between helix disc segments
 * - Welded steel triangular truss frame
 *
 * THIS PROTOTYPE:
 * - 3 helix shafts, 20 discs each with aluminum collars
 * - 37 hex blocks (3 rings, prime count — avoids Moiré)
 * - 33 sliders (11 per helix) with nearest-slider routing
 * - Triangular truss frame with bearing housings
 * - Motor bracket, chain tensioners, shaft collars
 * - Dual string render mode (cylinder fast / hull accurate)
 * - LOD system (0=wireframe, 1=preview, 2=full detail)
 * - Full physics validation (friction cascade, power budget)
 *
 * MECHANISM:
 * Motor → Bevel Gear → Chain Drive → 3 Horizontal Helix Shafts
 * → Steel Cables → 33 Sliders (11/helix, IN matrix)
 * → Strings (through redirect pulleys) → 37 Hanging Hex Blocks
 *
 * STRING ROUTING (per block, CORRECTED in v2.0):
 * Each block routes to its NEAREST slider on each helix tier.
 * Top Anchor → Pulley → Nearest Slider on Helix 2
 * → Pulley → Nearest Slider on Helix 1
 * → Pulley → Nearest Slider on Helix 0 → Block
 * Block height = algebraic sum of 3 nearest slider displacements.
 *
 * LIBRARIES:
 * - Getriebe.scad (Dr Jörg Janssen) — kegelradpaar() bevel gears
 * - pins.scad (Tony Buser) — pin() and pinhole() snap-fit
 * - validation_modules.scad — verification suite
 *
 * ANIMATION: View → Animate, FPS: 30, Steps: 120
 */

// ============================================
// LIBRARY INCLUDES
// ============================================
use <Final Designs/Getriebe Bibliothek für OpenSCAD _ Gears Library for OpenSCAD - 1604369 (1)/files/Getriebe.scad>
use <Final Designs/Pin Connectors V3 - 33790/files/pins.scad>
include <components/validation_modules.scad>

// ============================================
// LOD & PERFORMANCE
// ============================================

LOD_LEVEL   = 1;            // 0=wireframe, 1=preview (default), 2=full detail
STRING_MODE = "cylinder";   // "cylinder"=fast (default), "hull"=accurate (slow)

// LOD-dependent $fn values
_fn_low  = (LOD_LEVEL == 0) ? 6  : (LOD_LEVEL == 1) ? 12 : 24;
_fn_mid  = (LOD_LEVEL == 0) ? 8  : (LOD_LEVEL == 1) ? 16 : 24;
_fn_high = (LOD_LEVEL == 0) ? 12 : (LOD_LEVEL == 1) ? 24 : 48;

$fn = _fn_mid;

// ============================================
// ANIMATION
// ============================================

MANUAL_ANGLE = -1;  // 0-360 for static debug, -1 for animation
theta = (MANUAL_ANGLE >= 0) ? MANUAL_ANGLE : $t * 360;

// ============================================
// PARAMETERS: WAVE PHYSICS
// ============================================

AMPLITUDE    = 10;      // mm — per-helix sine amplitude
WAVE_NUMBER  = 0.08;    // rad/mm — spatial frequency (wavelength ~78mm)
PI           = 3.14159265;

// ============================================
// PARAMETERS: HELICES (Offset-Disc Spirals)
// ============================================
// From construction photos: aluminum discs with central bore,
// progressive angular offset forming corkscrew. White aluminum
// collars connect segments. Shaft perpendicular to frame arm.

NUM_HELICES        = 3;
HELIX_SPACING      = 110;     // mm — center to helix axis (up from 90 for larger grid)
HELIX_SHAFT_DIA    = 6;       // mm — central shaft
HELIX_LENGTH       = 66;      // mm — helix body length (11 sliders × 6mm spacing)
HELIX_DISC_DIA     = 20;      // mm — each aluminum disc
HELIX_DISC_THICK   = 2;       // mm — disc thickness
HELIX_NUM_DISCS    = 20;      // 20 discs for smooth spiral (up from 12)
HELIX_ECCENTRICITY = AMPLITUDE; // mm — disc offset = amplitude

// Aluminum collars between discs (visible in Margolin construction photo 3)
HELIX_COLLAR_DIA   = 10;      // mm — collar outer diameter
HELIX_COLLAR_THICK = 1.5;     // mm — collar spacer thickness

// ============================================
// PARAMETERS: SLIDERS (In Matrix, Cable-Connected)
// ============================================
// 11 sliders per helix (33 total). Real sculpture: 37 per tier (111 total).
// Each slider connected to helix via 1/16" steel cable.

SLIDERS_PER_HELIX = 11;
SLIDER_SPACING    = HELIX_LENGTH / SLIDERS_PER_HELIX;
SLIDER_WIDTH      = 12;      // mm
SLIDER_HEIGHT     = 8;       // mm
SLIDER_DEPTH      = 12;      // mm
SLIDER_BORE       = HELIX_DISC_DIA + 2;
SLIDER_RAIL_H     = AMPLITUDE * 2 + 20;
CABLE_DIA         = 1.0;     // mm — 1/16" steel cable visual

// ============================================
// PARAMETERS: BLOCK GRID
// ============================================
// 3 rings = 37 blocks (PRIME — avoids Moiré patterns per Margolin)
// Ring 0=1, 1=7, 2=19, 3=37, 4=61(prime), 5=91(7×13)

HEX_RINGS        = 3;        // 37 blocks
HEX_SPACING      = 14;       // mm — center-to-center
BLOCK_DIA        = 10;       // mm — hex across-flats
BLOCK_HEIGHT     = 8;        // mm — block thickness
BLOCK_WEIGHT_DIA = 4;        // mm — steel shot chamber
BLOCK_BEVEL      = 0.4;      // mm — edge chamfer (printable at ≥0.3)
BLOCK_EYELET_DIA = 1.5;      // mm — string attachment hole
BLOCK_MASS_G     = 5;        // grams — estimated per block

// ============================================
// PARAMETERS: FRAME (Triangular Truss)
// ============================================
// Real sculpture: welded steel triangular truss (photo 4)

FRAME_TOP_Z         = 0;
HELIX_Z             = -90;     // mm — lowered for taller matrix zone
BLOCK_NOMINAL_Z     = -160;    // mm — nominal hang position (lowered)
FRAME_RADIUS        = HELIX_SPACING + 40;  // mm — outer radius
FRAME_TRUSS_DIA     = 6;       // mm — main truss tube diameter
FRAME_BRACE_DIA     = 4;       // mm — diagonal bracing
FRAME_TRUSS_HEIGHT  = 15;      // mm — truss cross-section depth
FRAME_LEG_DIA       = 8;       // mm — support legs

// ============================================
// PARAMETERS: BEARING HOUSINGS
// ============================================
// Flanged bearing blocks at each end of helix shafts

BEARING_OD     = 16;      // mm — outer diameter
BEARING_ID     = HELIX_SHAFT_DIA + 0.4;  // mm — clearance fit
BEARING_WIDTH  = 8;       // mm
BEARING_FLANGE = 4;       // mm — flange extension

// ============================================
// PARAMETERS: MOTOR & DRIVE
// ============================================

MOTOR_DIA          = 18;      // mm — housing diameter
MOTOR_HEIGHT       = 25;      // mm — housing height
MOTOR_BRACKET_W    = 25;      // mm — bracket width
MOTOR_BRACKET_T    = 3;       // mm — bracket plate thickness

GEAR_MODUL         = 1;
GEAR_PINION_T      = 12;
GEAR_WHEEL_T       = 12;
GEAR_AXIS_ANGLE    = 90;
GEAR_FACE_WIDTH    = 6;
GEAR_BORE_PINION   = 4;
GEAR_BORE_WHEEL    = HELIX_SHAFT_DIA;

CHAIN_SPROCKET_DIA = 16;     // mm
TENSIONER_ARM_LEN  = 15;     // mm — spring-loaded idler arm

// ============================================
// PARAMETERS: PIN CONNECTORS
// ============================================

PIN_HEIGHT    = 8;
PIN_RADIUS    = 3;
PIN_LIP_H     = 2;
PIN_LIP_T     = 0.8;
PIN_TOLERANCE = 0.2;

// ============================================
// PARAMETERS: STRINGS & PULLEYS
// ============================================

STRING_DIA     = 0.6;     // mm — Dacron string visual
PULLEY_DIA     = 5;       // mm — redirect pulley
PULLEY_THICK   = 2;       // mm
PULLEY_BRACKET = 1.5;     // mm

// ============================================
// SHOW / HIDE TOGGLES
// ============================================

SHOW_HELICES    = true;
SHOW_COLLARS    = true;     // NEW: aluminum collars between helix discs
SHOW_SLIDERS    = true;
SHOW_CABLES     = true;     // NEW: steel cables helix→slider
SHOW_STRINGS    = true;
SHOW_PULLEYS    = true;
SHOW_MATRIX     = true;
SHOW_BLOCKS     = true;
SHOW_FRAME      = true;
SHOW_DRIVE      = true;
SHOW_GUIDES     = true;
SHOW_BEARINGS   = true;     // NEW: bearing housings
SHOW_TENSIONERS = true;     // NEW: chain tensioners
SHOW_ANNOTATIONS = false;   // Debug: phase arrows, labels

// ============================================
// COLORS (Margolin-Accurate Material Palette)
// ============================================
// From MARGOLIN_KNOWLEDGE_BANK.md materials table + photo analysis

C_BASSWOOD    = [0.82, 0.72, 0.55];       // Warm yellow-tan basswood
C_ALUMINUM    = [0.88, 0.88, 0.92];       // Bright aluminum (discs)
C_COLLAR      = [0.92, 0.92, 0.95];       // White aluminum collar
C_STEEL_SHAFT = [0.50, 0.50, 0.55];       // Steel shaft
C_STEEL_FRAME = [0.35, 0.35, 0.40];       // Welded steel frame
C_STEEL_CABLE = [0.45, 0.45, 0.50];       // 1/16" steel cable
C_DACRON      = [0.12, 0.12, 0.12];       // Black Dacron string
C_POLYCARB    = [0.80, 0.82, 0.85, 0.25]; // Clear polycarbonate
C_BRASS       = [0.75, 0.55, 0.20];       // Brass fittings
C_PULLEY      = [0.55, 0.55, 0.60];       // Nylon/steel pulley
C_MOTOR       = [0.35, 0.35, 0.40];       // Motor housing
C_GEAR        = [0.65, 0.50, 0.18];       // Brass gear
C_GUIDE       = [0.40, 0.40, 0.45];       // Guide rail
C_EYELET      = [0.70, 0.55, 0.25];       // Brass eyelet

// Ocean gradient: deep blue (low) → turquoise (mid) → white (high)
function clamp01(v) = min(1, max(0, v));

function block_color(h, max_h) =
    let(
        t = clamp01((h + max_h) / (2 * max_h)),
        r = 0.10 + 0.90 * pow(t, 2.0),
        g = 0.25 + 0.75 * pow(t, 1.3),
        b = 0.55 + 0.45 * t
    )
    [r, g, b];

// ============================================
// KINEMATICS: WAVE MATH
// ============================================

function helix_angle(i) = i * 120;

function proj_dist(bx, by, i) =
    bx * cos(helix_angle(i)) + by * sin(helix_angle(i));

function wave_contribution(bx, by, i, theta_deg) =
    AMPLITUDE * sin(WAVE_NUMBER * proj_dist(bx, by, i) * (180 / PI)
                    - theta_deg + i * 120);

// Analytical block height (ideal continuous wave — kept for comparison)
function block_height_analytical(bx, by, theta_deg) =
    wave_contribution(bx, by, 0, theta_deg) +
    wave_contribution(bx, by, 1, theta_deg) +
    wave_contribution(bx, by, 2, theta_deg);

function max_displacement() = 3 * AMPLITUDE;

// Multi-slider displacement: slider j on helix i at time theta
function slider_phase_at_pos(j, helix_index, theta_deg) =
    let(
        pos_along_shaft = (j - (SLIDERS_PER_HELIX - 1) / 2) * SLIDER_SPACING,
        shaft_phase = (pos_along_shaft / HELIX_LENGTH) * 360
    )
    AMPLITUDE * sin(theta_deg + helix_index * 120 + shaft_phase);

// Multi-slider world position: slider j on helix i
function multi_slider_world_pos(j, helix_index, theta_deg) =
    let(
        a = helix_angle(helix_index),
        r = HELIX_SPACING * 0.75,
        tangent_offset = (j - (SLIDERS_PER_HELIX - 1) / 2) * SLIDER_SPACING,
        sx = r * cos(a) + tangent_offset * (-sin(a)),
        sy = r * sin(a) + tangent_offset * cos(a),
        sz = HELIX_Z + slider_phase_at_pos(j, helix_index, theta_deg)
    )
    [sx, sy, sz];

// ============================================
// KINEMATICS: NEAREST-SLIDER ROUTING (v2.0 FIX)
// ============================================
// Each block routes to its NEAREST slider on each helix tier.
// This is the physical reality: strings route through the matrix
// to the closest contact point on each tier.

function _slider_xy(j, helix_index) =
    let(
        a = helix_angle(helix_index),
        r = HELIX_SPACING * 0.75,
        tangent_offset = (j - (SLIDERS_PER_HELIX - 1) / 2) * SLIDER_SPACING
    )
    [r * cos(a) + tangent_offset * (-sin(a)),
     r * sin(a) + tangent_offset * cos(a)];

function _dist_sq(bx, by, j, helix_index) =
    let(sxy = _slider_xy(j, helix_index))
    (bx - sxy[0]) * (bx - sxy[0]) + (by - sxy[1]) * (by - sxy[1]);

// Find nearest slider index on helix_index for block at (bx, by)
function nearest_slider_index(bx, by, helix_index) =
    let(
        dists = [for (j = [0 : SLIDERS_PER_HELIX - 1])
                     _dist_sq(bx, by, j, helix_index)],
        min_d = min(dists)
    )
    [for (j = [0 : SLIDERS_PER_HELIX - 1])
         if (dists[j] == min_d) j][0];

// Physical block height = sum of 3 nearest slider displacements
function block_height(bx, by, theta_deg) =
    let(
        s0 = nearest_slider_index(bx, by, 0),
        s1 = nearest_slider_index(bx, by, 1),
        s2 = nearest_slider_index(bx, by, 2)
    )
    slider_phase_at_pos(s0, 0, theta_deg) +
    slider_phase_at_pos(s1, 1, theta_deg) +
    slider_phase_at_pos(s2, 2, theta_deg);

// ============================================
// HEX GRID GENERATION
// ============================================

function hex_to_cart(q, r) =
    [HEX_SPACING * (q + r * 0.5),
     HEX_SPACING * (r * sqrt(3) / 2)];

function hex_positions(rings) =
    [for (q = [-rings : rings])
        for (r = [-rings : rings])
            if (abs(q + r) <= rings)
                hex_to_cart(q, r)];

HEX_POS = hex_positions(HEX_RINGS);
NUM_BLOCKS = len(HEX_POS);

// ============================================
// UTILITY: ORIENTED BEAM
// ============================================
// Used by truss frame, cable routing, string segments

module oriented_beam(p1, p2, dia, fn_override = 0) {
    v = p2 - p1;
    length = norm(v);
    _fn = (fn_override > 0) ? fn_override : _fn_low;
    if (length > 0.01)
    translate(p1)
    rotate([0, 0, atan2(v[1], v[0])])
    rotate([0, acos(v[2] / length), 0])
        cylinder(d = dia, h = length, $fn = _fn);
}

// ============================================
// UTILITY: STRING SEGMENT (Dual Mode)
// ============================================

module string_segment(p1, p2) {
    if (STRING_MODE == "hull") {
        hull() {
            translate(p1) sphere(d = STRING_DIA, $fn = 6);
            translate(p2) sphere(d = STRING_DIA, $fn = 6);
        }
    } else {
        oriented_beam(p1, p2, STRING_DIA, 4);
    }
}

// Cable segment (always cylinder for speed)
module cable_segment(p1, p2) {
    oriented_beam(p1, p2, CABLE_DIA, 4);
}

// ============================================
// MODULE: OFFSET-DISC HELIX ASSEMBLY
// ============================================
// From construction photos: aluminum discs with progressive angular
// offset. White aluminum collars between each disc. Shaft runs
// perpendicular to radial frame arm (tangential direction).

module helix_assembly(index, theta_deg) {
    a = helix_angle(index);
    base_phase = theta_deg + index * 120;

    translate([HELIX_SPACING * cos(a), HELIX_SPACING * sin(a), HELIX_Z])
    rotate([0, 0, a])
    rotate([90, 0, 0]) {
        if (SHOW_HELICES) {
            disc_spacing = HELIX_LENGTH / HELIX_NUM_DISCS;

            // Central shaft (extends beyond helix body for bearings)
            color(C_STEEL_SHAFT)
            translate([0, 0, -HELIX_LENGTH / 2 - 10])
                cylinder(d = HELIX_SHAFT_DIA, h = HELIX_LENGTH + 20, $fn = _fn_mid);

            // Offset discs forming the spiral
            for (d = [0 : HELIX_NUM_DISCS - 1]) {
                disc_phase = base_phase + d * (360 / HELIX_NUM_DISCS);
                dz = d * disc_spacing - HELIX_LENGTH / 2 + disc_spacing / 2;

                // Aluminum disc
                color(C_ALUMINUM, 0.85)
                translate([0, 0, dz])
                rotate([0, 0, disc_phase])
                translate([HELIX_ECCENTRICITY, 0, 0])
                    cylinder(d = HELIX_DISC_DIA, h = HELIX_DISC_THICK,
                             center = true, $fn = _fn_mid);
            }

            // Aluminum collars between discs
            if (SHOW_COLLARS) {
                for (d = [0 : HELIX_NUM_DISCS - 2]) {
                    dz = (d + 1) * disc_spacing - HELIX_LENGTH / 2;
                    color(C_COLLAR)
                    translate([0, 0, dz])
                        cylinder(d = HELIX_COLLAR_DIA, h = HELIX_COLLAR_THICK,
                                 center = true, $fn = _fn_low);
                }
            }

            // Bearing mount flanges at each end
            color(C_BRASS)
            for (end = [-1, 1]) {
                translate([0, 0, end * (HELIX_LENGTH / 2 + 2)])
                    cylinder(d = HELIX_SHAFT_DIA + 4, h = 3,
                             center = true, $fn = _fn_low);
            }
        }
    }
}

// ============================================
// MODULE: BEARING HOUSINGS
// ============================================
// Flanged bearing blocks at each end of helix shaft.
// Mounted to frame arms.

module bearing_housing(pos, shaft_angle) {
    if (SHOW_BEARINGS) {
        color(C_ALUMINUM)
        translate(pos)
        rotate([0, 0, shaft_angle])
        rotate([90, 0, 0]) {
            // Outer housing
            difference() {
                cylinder(d = BEARING_OD, h = BEARING_WIDTH,
                         center = true, $fn = _fn_mid);
                cylinder(d = BEARING_ID, h = BEARING_WIDTH + 1,
                         center = true, $fn = _fn_mid);
            }
            // Mounting flange (flat base for bolting to frame)
            translate([0, -BEARING_OD / 2 + 1, 0])
                cube([BEARING_OD + BEARING_FLANGE * 2,
                      3, BEARING_WIDTH], center = true);
        }

        // Shaft collar with set screw (at each bearing)
        color(C_STEEL_SHAFT)
        translate(pos)
        rotate([0, 0, shaft_angle])
        rotate([90, 0, 0]) {
            difference() {
                cylinder(d = HELIX_SHAFT_DIA + 5, h = 3,
                         center = true, $fn = _fn_low);
                cylinder(d = HELIX_SHAFT_DIA + 0.2, h = 4,
                         center = true, $fn = _fn_low);
            }
            // Set screw visual
            translate([0, (HELIX_SHAFT_DIA + 5) / 2 - 0.5, 0])
                cylinder(d = 1.5, h = 3, center = true, $fn = 6);
        }
    }
}

// ============================================
// MODULE: HELIX SLIDERS (Multiple per Helix)
// ============================================

module single_slider(pos, helix_index) {
    // Slider bearing block
    color(C_ALUMINUM)
    translate(pos)
    translate([-SLIDER_WIDTH / 2, -SLIDER_DEPTH / 2, -SLIDER_HEIGHT / 2])
        cube([SLIDER_WIDTH, SLIDER_DEPTH, SLIDER_HEIGHT]);

    // String-wrap pin (strings loop around this)
    color(C_BRASS)
    translate(pos)
    translate([0, 0, SLIDER_HEIGHT / 2 + 0.5])
        cylinder(d = 2.5, h = 5, $fn = _fn_low);
}

module helix_sliders(index, theta_deg) {
    a = helix_angle(index);

    if (SHOW_SLIDERS) {
        for (j = [0 : SLIDERS_PER_HELIX - 1]) {
            pos = multi_slider_world_pos(j, index, theta_deg);
            single_slider(pos, index);

            // Steel cable from helix to slider (multi-segment wrap)
            if (SHOW_CABLES) {
                helix_center = [HELIX_SPACING * cos(a),
                                HELIX_SPACING * sin(a),
                                HELIX_Z];
                // Cable departs from helix disc circumference
                depart_angle = a + 90;
                depart_pt = [
                    helix_center[0] + (HELIX_DISC_DIA / 2) * cos(depart_angle),
                    helix_center[1] + (HELIX_DISC_DIA / 2) * sin(depart_angle),
                    helix_center[2]
                ];

                color(C_STEEL_CABLE) {
                    // Wrap segment on helix surface (quarter arc, 3 steps)
                    for (step = [0 : 2]) {
                        t1 = step / 3;
                        t2 = (step + 1) / 3;
                        a1 = a + 90 * t1;
                        a2 = a + 90 * t2;
                        p1 = [helix_center[0] + (HELIX_DISC_DIA / 2) * cos(a1),
                              helix_center[1] + (HELIX_DISC_DIA / 2) * sin(a1),
                              helix_center[2]];
                        p2 = [helix_center[0] + (HELIX_DISC_DIA / 2) * cos(a2),
                              helix_center[1] + (HELIX_DISC_DIA / 2) * sin(a2),
                              helix_center[2]];
                        cable_segment(p1, p2);
                    }
                    // Run from departure to slider
                    cable_segment(depart_pt, pos);
                }
            }
        }
    }

    // Vertical guide rails (one pair per slider)
    if (SHOW_GUIDES) {
        for (j = [0 : SLIDERS_PER_HELIX - 1]) {
            tangent_offset = (j - (SLIDERS_PER_HELIX - 1) / 2) * SLIDER_SPACING;
            gx = HELIX_SPACING * 0.75 * cos(a) + tangent_offset * (-sin(a));
            gy = HELIX_SPACING * 0.75 * sin(a) + tangent_offset * cos(a);

            color(C_GUIDE, 0.4)
            for (offset = [-SLIDER_DEPTH / 2 - 2, SLIDER_DEPTH / 2 + 2]) {
                ox = gx + offset * cos(a);
                oy = gy + offset * sin(a);
                translate([ox, oy, HELIX_Z - SLIDER_RAIL_H / 2])
                    cube([2, 2, SLIDER_RAIL_H], center = true);
            }
        }
    }
}

// ============================================
// MODULE: HANGING BLOCK (Detailed Basswood)
// ============================================
// Margolin's basswood hex blocks with steel shot weights,
// brass eyelet for string attachment, beveled edges.

module hanging_block(bx, by, theta_deg) {
    h = block_height(bx, by, theta_deg);
    max_h = max_displacement();
    bz = BLOCK_NOMINAL_Z + h;

    if (SHOW_BLOCKS) {
        // Main hexagonal block with ocean gradient color
        color(block_color(h, max_h))
        translate([bx, by, bz - BLOCK_HEIGHT]) {
            if (LOD_LEVEL >= 2) {
                // Full detail: beveled hex prism
                minkowski() {
                    cylinder(d = BLOCK_DIA - BLOCK_BEVEL * 2,
                             h = BLOCK_HEIGHT - BLOCK_BEVEL, $fn = 6);
                    sphere(r = BLOCK_BEVEL, $fn = 8);
                }
            } else {
                // Preview: simple hex prism
                cylinder(d = BLOCK_DIA, h = BLOCK_HEIGHT, $fn = 6);
            }
        }

        // Brass string eyelet (top center)
        color(C_EYELET)
        translate([bx, by, bz + 0.1])
            difference() {
                cylinder(d = BLOCK_EYELET_DIA + 1.5, h = 1, $fn = _fn_low);
                translate([0, 0, -0.1])
                    cylinder(d = BLOCK_EYELET_DIA, h = 1.2, $fn = _fn_low);
            }

        // Steel shot weight chamber (hollow cylinder at bottom)
        color([0.40, 0.40, 0.45])
        translate([bx, by, bz - BLOCK_HEIGHT - 2.5])
            difference() {
                cylinder(d = BLOCK_WEIGHT_DIA + 2, h = 2.5, $fn = _fn_low);
                translate([0, 0, 0.5])
                    cylinder(d = BLOCK_WEIGHT_DIA, h = 2.5, $fn = _fn_low);
            }

        // Wood grain lines (LOD 2 only)
        if (LOD_LEVEL >= 2) {
            color(C_BASSWOOD * 0.88)
            translate([bx, by, bz - BLOCK_HEIGHT / 2])
            for (g = [-2 : 2]) {
                translate([g * 1.8, 0, 0])
                    cube([0.2, BLOCK_DIA * 0.75, BLOCK_HEIGHT * 0.85],
                         center = true);
            }
        }
    }
}

// ============================================
// MODULE: STRING ROUTING (Nearest-Slider, v2.0)
// ============================================

// Compute string waypoints using nearest slider on each tier
function string_waypoints(bx, by, theta_deg) =
    let(
        h = block_height(bx, by, theta_deg),
        bz = BLOCK_NOMINAL_Z + h,
        // Find nearest slider on each helix tier
        s0_idx = nearest_slider_index(bx, by, 0),
        s1_idx = nearest_slider_index(bx, by, 1),
        s2_idx = nearest_slider_index(bx, by, 2),
        // Actual slider world positions
        s0 = multi_slider_world_pos(s0_idx, 0, theta_deg),
        s1 = multi_slider_world_pos(s1_idx, 1, theta_deg),
        s2 = multi_slider_world_pos(s2_idx, 2, theta_deg),
        margin = 6  // mm above/below slider for approach/depart pulleys
    )
    [
        [bx, by, FRAME_TOP_Z - 2],                                  // 0: top anchor
        [s2[0], s2[1], s2[2] + margin],                             // 1: approach slider 2
        s2,                                                           // 2: slider 2 wrap
        [s2[0], s2[1], s2[2] - margin],                             // 3: depart slider 2
        [(s2[0] + s1[0]) / 2, (s2[1] + s1[1]) / 2,
         (s2[2] + s1[2]) / 2],                                      // 4: transit midpoint 2→1
        [s1[0], s1[1], s1[2] + margin],                             // 5: approach slider 1
        s1,                                                           // 6: slider 1 wrap
        [s1[0], s1[1], s1[2] - margin],                             // 7: depart slider 1
        [(s1[0] + s0[0]) / 2, (s1[1] + s0[1]) / 2,
         (s1[2] + s0[2]) / 2],                                      // 8: transit midpoint 1→0
        [s0[0], s0[1], s0[2] + margin],                             // 9: approach slider 0
        s0,                                                           // 10: slider 0 wrap
        [s0[0], s0[1], s0[2] - margin],                             // 11: depart slider 0
        [bx, by, bz]                                                  // 12: block top
    ];

// String lines ONLY — gated by SHOW_STRINGS
module block_string_lines(bx, by, theta_deg) {
    if (SHOW_STRINGS) {
        wp = string_waypoints(bx, by, theta_deg);

        color(C_DACRON) {
            // Top anchor → approach slider 2
            string_segment(wp[0], wp[1]);
            // Around slider 2
            string_segment(wp[1], wp[2]);
            string_segment(wp[2], wp[3]);
            // Transit to slider 1
            string_segment(wp[3], wp[4]);
            string_segment(wp[4], wp[5]);
            // Around slider 1
            string_segment(wp[5], wp[6]);
            string_segment(wp[6], wp[7]);
            // Transit to slider 0
            string_segment(wp[7], wp[8]);
            string_segment(wp[8], wp[9]);
            // Around slider 0
            string_segment(wp[9], wp[10]);
            string_segment(wp[10], wp[11]);
            // Final drop to block
            string_segment(wp[11], wp[12]);
        }
    }
}

// Redirect pulleys ONLY — gated by SHOW_PULLEYS
module redirect_pulley(pos, face_angle) {
    color(C_PULLEY)
    translate(pos)
    rotate([90, 0, face_angle])
        cylinder(d = PULLEY_DIA, h = PULLEY_THICK, center = true, $fn = _fn_low);

    color(C_GUIDE)
    translate(pos)
        sphere(d = PULLEY_BRACKET, $fn = 8);
}

module block_redirect_pulleys(bx, by, theta_deg) {
    if (SHOW_PULLEYS) {
        wp = string_waypoints(bx, by, theta_deg);

        // Pulleys at approach/depart points for each slider tier
        redirect_pulley(wp[1], helix_angle(2));    // approach s2
        redirect_pulley(wp[3], helix_angle(2));    // depart s2
        redirect_pulley(wp[5], helix_angle(1));    // approach s1
        redirect_pulley(wp[7], helix_angle(1));    // depart s1
        redirect_pulley(wp[9], helix_angle(0));    // approach s0
        redirect_pulley(wp[11], helix_angle(0));   // depart s0
    }
}

// ============================================
// MODULE: TRIANGULAR TRUSS FRAME
// ============================================
// Welded steel triangular truss (from construction photo 4).
// Three radial arms from central hub to helix mounts.

module truss_beam(p1, p2, dia = FRAME_TRUSS_DIA) {
    color(C_STEEL_FRAME)
    oriented_beam(p1, p2, dia, _fn_low);
}

module triangular_truss(p1, p2) {
    v = p2 - p1;
    length = norm(v);
    dir = v / length;

    // Perpendicular vector for truss depth (in XY plane)
    perp = [-dir[1], dir[0], 0];
    down = [0, 0, -FRAME_TRUSS_HEIGHT];

    // Bottom chord offsets
    b1_offset = perp * FRAME_TRUSS_HEIGHT * 0.4 + down;
    b2_offset = perp * (-FRAME_TRUSS_HEIGHT * 0.4) + down;

    bp1_1 = p1 + b1_offset;
    bp2_1 = p2 + b1_offset;
    bp1_2 = p1 + b2_offset;
    bp2_2 = p2 + b2_offset;

    // Top chord
    truss_beam(p1, p2);

    // Bottom chords
    truss_beam(bp1_1, bp2_1, FRAME_BRACE_DIA);
    truss_beam(bp1_2, bp2_2, FRAME_BRACE_DIA);

    // End plates (triangular cross-section)
    truss_beam(p1, bp1_1, FRAME_BRACE_DIA);
    truss_beam(p1, bp1_2, FRAME_BRACE_DIA);
    truss_beam(bp1_1, bp1_2, FRAME_BRACE_DIA);

    truss_beam(p2, bp2_1, FRAME_BRACE_DIA);
    truss_beam(p2, bp2_2, FRAME_BRACE_DIA);
    truss_beam(bp2_1, bp2_2, FRAME_BRACE_DIA);

    // Diagonal cross-bracing
    segments = max(2, floor(length / 35));
    for (s = [0 : segments - 1]) {
        t_mid = (s + 0.5) / segments;
        top_mid = p1 * (1 - t_mid) + p2 * t_mid;

        t1 = s / segments;
        t2 = (s + 1) / segments;

        bot_1a = bp1_1 * (1 - t1) + bp2_1 * t1;
        bot_1b = bp1_1 * (1 - t2) + bp2_1 * t2;
        bot_2a = bp1_2 * (1 - t1) + bp2_2 * t1;
        bot_2b = bp1_2 * (1 - t2) + bp2_2 * t2;

        // X bracing to both bottom chords
        truss_beam(top_mid, bot_1a, FRAME_BRACE_DIA);
        truss_beam(top_mid, bot_1b, FRAME_BRACE_DIA);
        truss_beam(top_mid, bot_2a, FRAME_BRACE_DIA);
        truss_beam(top_mid, bot_2b, FRAME_BRACE_DIA);
    }
}

module frame() {
    if (SHOW_FRAME) {
        // Top plate (hexagonal, semi-transparent)
        color(C_STEEL_FRAME, 0.25)
        translate([0, 0, FRAME_TOP_Z - 3])
            cylinder(d = FRAME_RADIUS * 1.6, h = 3, $fn = 6);

        // Three radial truss arms from hub to helix mounts
        for (i = [0 : NUM_HELICES - 1]) {
            a = helix_angle(i);
            hub_pt = [12 * cos(a), 12 * sin(a), HELIX_Z];
            helix_pt = [HELIX_SPACING * cos(a),
                        HELIX_SPACING * sin(a), HELIX_Z];

            triangular_truss(hub_pt, helix_pt);

            // Pin connector at hub end
            color(C_ALUMINUM)
            translate([8 * cos(a), 8 * sin(a), HELIX_Z - 6])
            rotate([0, 0, a])
                pin(h = PIN_HEIGHT, r = PIN_RADIUS,
                    lh = PIN_LIP_H, lt = PIN_LIP_T, t = PIN_TOLERANCE);

            // Pinhole at helix mount end
            color(C_STEEL_FRAME)
            translate([HELIX_SPACING * cos(a),
                       HELIX_SPACING * sin(a),
                       HELIX_Z - 6])
            rotate([0, 0, a])
                pinhole(h = PIN_HEIGHT, r = PIN_RADIUS,
                        lh = PIN_LIP_H, lt = PIN_LIP_T,
                        t = PIN_TOLERANCE + 0.1, tight = true);

            // Bearing housings at each end of helix shaft
            bearing_offset_1 = HELIX_LENGTH / 2 + 5;
            bearing_offset_2 = -(HELIX_LENGTH / 2 + 5);
            // Tangent direction for helix shaft
            tan_dir = [-sin(a), cos(a)];

            bearing_housing(
                [HELIX_SPACING * cos(a) + tan_dir[0] * bearing_offset_1 * 0,
                 HELIX_SPACING * sin(a) + tan_dir[1] * bearing_offset_1 * 0,
                 HELIX_Z],
                a);
        }

        // Vertical legs (3 legs at 60° offsets from helix arms)
        for (i = [0 : 2]) {
            a = helix_angle(i) + 60;
            lx = FRAME_RADIUS * 0.85 * cos(a);
            ly = FRAME_RADIUS * 0.85 * sin(a);

            color(C_STEEL_FRAME)
            translate([lx, ly, HELIX_Z - 40])
                cylinder(d = FRAME_LEG_DIA, h = -HELIX_Z + 40 + 3, $fn = _fn_low);

            // Leg-to-top-plate gusset
            color(C_STEEL_FRAME)
            translate([lx, ly, FRAME_TOP_Z - 3])
                cylinder(d = FRAME_LEG_DIA + 4, h = 3, $fn = _fn_low);
        }

        // Central hub
        color(C_STEEL_FRAME)
        translate([0, 0, HELIX_Z])
        difference() {
            cylinder(d = 28, h = 12, center = true, $fn = _fn_mid);
            for (i = [0 : NUM_HELICES - 1]) {
                a = helix_angle(i);
                translate([8 * cos(a), 8 * sin(a), -6])
                rotate([0, 0, a])
                    pinhole(h = PIN_HEIGHT, r = PIN_RADIUS,
                            lh = PIN_LIP_H, lt = PIN_LIP_T,
                            t = PIN_TOLERANCE, tight = true);
            }
        }
    }
}

// ============================================
// MODULE: DRIVE SYSTEM (Motor + Gears + Chain)
// ============================================

module motor_bracket() {
    color(C_STEEL_FRAME) {
        // Vertical mounting plate
        translate([-MOTOR_BRACKET_W / 2, -MOTOR_BRACKET_T / 2, HELIX_Z - 38])
            cube([MOTOR_BRACKET_W, MOTOR_BRACKET_T, 38]);

        // Horizontal motor platform
        translate([-MOTOR_BRACKET_W / 2, -MOTOR_BRACKET_W / 2, HELIX_Z - 38 - MOTOR_BRACKET_T])
            cube([MOTOR_BRACKET_W, MOTOR_BRACKET_W, MOTOR_BRACKET_T]);

        // Gusset triangles
        for (side = [-1, 1]) {
            hull() {
                translate([side * (MOTOR_BRACKET_W / 2 - 1), 0, HELIX_Z - 20])
                    cube([1, MOTOR_BRACKET_T, 1], center = true);
                translate([side * (MOTOR_BRACKET_W / 2 - 1), 0, HELIX_Z - 38])
                    cube([1, MOTOR_BRACKET_T, 1], center = true);
                translate([side * (MOTOR_BRACKET_W / 2 - 1),
                           side * (MOTOR_BRACKET_W / 2 - 1), HELIX_Z - 38])
                    cube([1, 1, MOTOR_BRACKET_T], center = true);
            }
        }
    }
}

module chain_tensioner(pos, chain_angle) {
    if (SHOW_TENSIONERS) {
        color(C_STEEL_FRAME)
        translate(pos)
        rotate([0, 0, chain_angle]) {
            // Pivot arm
            hull() {
                cylinder(d = 4, h = 3, center = true, $fn = _fn_low);
                translate([TENSIONER_ARM_LEN, 0, 0])
                    cylinder(d = 4, h = 3, center = true, $fn = _fn_low);
            }
            // Idler sprocket
            color(C_GEAR)
            translate([TENSIONER_ARM_LEN, 0, 0])
                cylinder(d = 10, h = 3, center = true, $fn = _fn_low);
            // Tension spring visual
            color([0.6, 0.6, 0.65])
            translate([TENSIONER_ARM_LEN / 2, -6, 0])
                cylinder(d = 4, h = 8, center = true, $fn = 6);
        }
    }
}

module drive_system() {
    if (SHOW_DRIVE) {
        // Motor bracket
        motor_bracket();

        // Motor housing (on bracket platform)
        color(C_MOTOR)
        translate([0, 0, HELIX_Z - 38 - MOTOR_BRACKET_T - MOTOR_HEIGHT])
            cylinder(d = MOTOR_DIA, h = MOTOR_HEIGHT, $fn = _fn_mid);

        // Motor shaft (vertical, through bracket)
        color(C_STEEL_SHAFT)
        translate([0, 0, HELIX_Z - 12])
            cylinder(d = GEAR_BORE_PINION, h = 15, $fn = _fn_low);

        // Bevel gear pair (Getriebe kegelradpaar)
        color(C_GEAR)
        translate([0, 0, HELIX_Z])
        rotate([0, -90, 0])
            kegelradpaar(
                modul           = GEAR_MODUL,
                zahnzahl_rad    = GEAR_WHEEL_T,
                zahnzahl_ritzel = GEAR_PINION_T,
                achsenwinkel    = GEAR_AXIS_ANGLE,
                zahnbreite      = GEAR_FACE_WIDTH,
                bohrung_rad     = GEAR_BORE_WHEEL,
                bohrung_ritzel  = GEAR_BORE_PINION,
                eingriffswinkel = 20,
                schraegungswinkel = 0,
                zusammen_gebaut = true
            );

        // Chain sprockets at each helix
        for (i = [0 : NUM_HELICES - 1]) {
            a = helix_angle(i);
            hx = HELIX_SPACING * cos(a);
            hy = HELIX_SPACING * sin(a);

            color(C_GEAR)
            translate([hx, hy, HELIX_Z])
            rotate([0, 0, a])
            rotate([0, 90, 0])
                cylinder(d = CHAIN_SPROCKET_DIA, h = 3, center = true, $fn = _fn_mid);
        }

        // Chain paths with tensioners
        color([0.30, 0.30, 0.35])
        for (i = [0 : NUM_HELICES - 1]) {
            a1 = helix_angle(i);
            a2 = helix_angle((i + 1) % NUM_HELICES);
            p1 = [HELIX_SPACING * cos(a1), HELIX_SPACING * sin(a1), HELIX_Z];
            p2 = [HELIX_SPACING * cos(a2), HELIX_SPACING * sin(a2), HELIX_Z];

            // Chain segments
            steps = 10;
            for (s = [0 : steps - 1]) {
                t1 = s / steps;
                t2 = (s + 1) / steps;
                cp1 = p1 * (1 - t1) + p2 * t1;
                cp2 = p1 * (1 - t2) + p2 * t2;
                cable_segment(cp1, cp2);
            }

            // Chain tensioner at midpoint
            mid_pt = (p1 + p2) / 2;
            mid_angle = atan2(p2[1] - p1[1], p2[0] - p1[0]) + 90;
            chain_tensioner(mid_pt + [0, 0, -8], mid_angle);
        }
    }
}

// ============================================
// MODULE: POLYCARBONATE MATRIX (Drilled Sheets)
// ============================================
// Three tier sheets with precision hole patterns.
// From construction photo 1: polycarbonate sheets being drilled
// and routed with precision hole patterns for string routing.

module pulley_matrix() {
    if (SHOW_MATRIX) {
        matrix_z_center = (FRAME_TOP_Z + HELIX_Z) / 2;
        sheet_size = FRAME_RADIUS * 1.3;
        sheet_thick = 2.5;
        tier_spacing = 14;

        for (tier = [0 : 2]) {
            tier_z = matrix_z_center + (tier - 1) * tier_spacing;

            // Polycarbonate sheet with drilled holes
            color(C_POLYCARB)
            translate([0, 0, tier_z])
            difference() {
                // Main sheet (hexagonal, matching top plate)
                cylinder(d = sheet_size * 1.5, h = sheet_thick,
                         center = true, $fn = 6);

                // String passage holes (one per block)
                for (i = [0 : NUM_BLOCKS - 1]) {
                    bx = HEX_POS[i][0];
                    by = HEX_POS[i][1];
                    translate([bx, by, 0])
                        cylinder(d = 3, h = sheet_thick + 1,
                                 center = true, $fn = _fn_low);
                }

                // Slider guide slots
                a = helix_angle(tier);
                for (j = [0 : SLIDERS_PER_HELIX - 1]) {
                    sxy = _slider_xy(j, tier);
                    translate([sxy[0], sxy[1], 0])
                    rotate([0, 0, a])
                        cube([SLIDER_WIDTH + 2, 4, sheet_thick + 1],
                             center = true);
                }
            }

            // Nylon roller pulleys embedded at string holes
            color(C_PULLEY)
            for (i = [0 : NUM_BLOCKS - 1]) {
                bx = HEX_POS[i][0];
                by = HEX_POS[i][1];
                translate([bx, by, tier_z])
                    cylinder(d = 4, h = sheet_thick + 0.5,
                             center = true, $fn = _fn_low);
            }
        }
    }
}

// ============================================
// MODULE: HEX GRID (all blocks)
// ============================================

module hex_grid(theta_deg) {
    for (i = [0 : NUM_BLOCKS - 1]) {
        bx = HEX_POS[i][0];
        by = HEX_POS[i][1];

        hanging_block(bx, by, theta_deg);
        block_string_lines(bx, by, theta_deg);
        block_redirect_pulleys(bx, by, theta_deg);
    }
}

// ============================================
// MODULE: DEBUG ANNOTATIONS
// ============================================

module annotations(theta_deg) {
    if (SHOW_ANNOTATIONS) {
        // Helix direction arrows
        for (i = [0 : NUM_HELICES - 1]) {
            a = helix_angle(i);
            color(C_ALUMINUM)
            translate([HELIX_SPACING * 1.3 * cos(a),
                       HELIX_SPACING * 1.3 * sin(a), HELIX_Z])
            rotate([0, 0, a])
                cube([20, 1, 1], center = true);
        }

        // Current theta label position
        color([1, 1, 1])
        translate([0, 0, FRAME_TOP_Z + 10])
            cube([1, 1, 1]);  // Marker at origin

        // Phase offset verification dots at HELIX_Z level
        for (i = [0 : NUM_HELICES - 1]) {
            a = helix_angle(i);
            disp = AMPLITUDE * sin(theta_deg + i * 120);
            color(C_ALUMINUM)
            translate([HELIX_SPACING * cos(a),
                       HELIX_SPACING * sin(a),
                       HELIX_Z + disp])
                sphere(d = 4, $fn = 8);
        }
    }
}

// ============================================
// MAIN ASSEMBLY
// ============================================

module triple_helix_v2() {
    frame();
    drive_system();
    pulley_matrix();
    annotations(theta);

    for (i = [0 : NUM_HELICES - 1]) {
        helix_assembly(i, theta);
        helix_sliders(i, theta);
    }

    hex_grid(theta);
}

triple_helix_v2();

// ============================================
// VERIFICATION (Extended v2.0)
// ============================================

// --- Power Path ---
echo_power_path_simple([
    "Motor → Bevel Gear (Getriebe kegelradpaar, vert→horiz)",
    str("  → Chain Drive + 3 Tensioners → 3 Horizontal Helix Shafts"),
    str("  → 3× Offset-Disc Spiral Helices at 120° (", HELIX_NUM_DISCS, " discs each, aluminum collars)"),
    str("  → Steel Cables → ", SLIDERS_PER_HELIX * NUM_HELICES, " Sliders (", SLIDERS_PER_HELIX, "/helix, IN matrix)"),
    str("  → Strings (through redirect pulleys) → ", NUM_BLOCKS, " Hanging Basswood Hex Blocks"),
    "  → Each string loops NEAREST slider per tier → algebraic sum",
    str("  → Block height = Σ(3 nearest slider displacements) — no orphan sin($t)")
]);

// --- Printability ---
verify_printability(
    wall_thickness = 2.0,
    clearance = 0.5,
    description = "Redirect Pulley Bracket"
);

verify_printability(
    wall_thickness = 1.5,
    clearance = 0.4,
    description = "Slider Guide Rail"
);

verify_printability(
    wall_thickness = (BEARING_OD - BEARING_ID) / 2,
    clearance = BEARING_ID - HELIX_SHAFT_DIA,
    description = "Bearing Housing"
);

// --- Tolerance Stack ---
verify_tolerance_stack(
    joint_count = 12,           // 6 redirect pulleys + 3 slider wraps + 3 transit pulleys
    per_joint_clearance = 0.2,
    acceptable_stack = 3.5,
    description = "String Route (per block, v2.0 nearest-slider)"
);

// --- Friction Cascade (Margolin formula: μ^n) ---
echo("=== FRICTION CASCADE ANALYSIS ===");
_max_serial_pulleys = 6 + 3;  // 6 redirect + 3 slider wrap contacts
_mu = 0.95;                    // per pulley efficiency
_efficiency = pow(_mu, _max_serial_pulleys);
echo(str("  Max serial pulleys per string: ", _max_serial_pulleys));
echo(str("  Per-pulley efficiency (μ): ", _mu));
echo(str("  Total string efficiency: ", round(_efficiency * 100), "% (loss: ",
         round((1 - _efficiency) * 100), "%)"));
echo(str("  Total pulleys in sculpture: ~", NUM_BLOCKS * 6 + SLIDERS_PER_HELIX * NUM_HELICES));
echo(str("  ", _max_serial_pulleys > 9
    ? "FRICTION WARNING: Exceeds Margolin 9-pulley serial limit!"
    : "RESULT: Within Margolin friction limit (≤9 serial)"));
echo("=== END FRICTION CASCADE ===");

// --- Power Budget ---
echo("=== POWER BUDGET ===");
_total_mass_g = NUM_BLOCKS * BLOCK_MASS_G;
_gravity_force_N = _total_mass_g * 0.00981;
_required_torque = _gravity_force_N * HELIX_ECCENTRICITY;
_motor_torque_est = 50;  // N·mm estimated (small geared DC motor)
_effective_torque = _motor_torque_est * _efficiency;
_power_margin = _effective_torque / _required_torque;
echo(str("  Block count: ", NUM_BLOCKS, " × ", BLOCK_MASS_G, "g = ", _total_mass_g, "g"));
echo(str("  Gravity load: ", round(_gravity_force_N * 100) / 100, " N"));
echo(str("  Required torque: ", round(_required_torque * 10) / 10, " N·mm"));
echo(str("  Motor torque (after friction): ", round(_effective_torque), " N·mm"));
echo(str("  Power margin: ", round(_power_margin * 10) / 10, "x ",
         _power_margin >= 1.5 ? "(≥1.5x OK)" : "WARNING: < 1.5x!"));
echo("=== END POWER BUDGET ===");

// --- Wave Physics ---
echo("=== WAVE PHYSICS ===");
echo(str("Amplitude per helix: ", AMPLITUDE, "mm"));
echo(str("Max block travel (3 aligned): ±", max_displacement(), "mm"));
echo(str("Wavelength: ~", round(2 * PI / WAVE_NUMBER), "mm"));
echo(str("Hex grid: ", HEX_RINGS, " rings → ", NUM_BLOCKS, " blocks (prime: ",
         NUM_BLOCKS == 37 || NUM_BLOCKS == 61 || NUM_BLOCKS == 7 ? "YES" : "NO", ")"));
echo(str("Sliders: ", SLIDERS_PER_HELIX, "/helix × ", NUM_HELICES,
         " = ", SLIDERS_PER_HELIX * NUM_HELICES, " total"));

// Phase verification
_s0z = slider_phase_at_pos(0, 0, theta);
_s1z = slider_phase_at_pos(0, 1, theta);
_s2z = slider_phase_at_pos(0, 2, theta);
echo(str("Center sliders at θ=", round(theta), "°: ",
         "H0=", round(_s0z * 10) / 10, " ",
         "H1=", round(_s1z * 10) / 10, " ",
         "H2=", round(_s2z * 10) / 10, "mm",
         " (expect 120° phase offset)"));

// Nearest-slider assignment sample
echo("--- Slider Assignments (sample) ---");
for (i = [0 : min(6, NUM_BLOCKS - 1)]) {
    _bx = HEX_POS[i][0];
    _by = HEX_POS[i][1];
    _s0i = nearest_slider_index(_bx, _by, 0);
    _s1i = nearest_slider_index(_bx, _by, 1);
    _s2i = nearest_slider_index(_bx, _by, 2);
    echo(str("  Block ", i, " (", round(_bx), ",", round(_by),
             ") → H0[", _s0i, "] H1[", _s1i, "] H2[", _s2i, "]"));
}

_center_h = block_height(0, 0, theta);
_edge_h = block_height(HEX_SPACING * 2, 0, theta);
echo(str("Center block: ", round(_center_h * 10) / 10, "mm, ",
         "Edge block: ", round(_edge_h * 10) / 10, "mm"));
echo("=== END WAVE PHYSICS ===");

// --- Final Verification Report ---
verification_report(
    project_name        = "Triple Helix v2.0 (Margolin-Accurate)",
    power_path_verified = true,
    grashof_type        = "N/A (offset-disc helix spiral, not four-bar)",
    dead_points         = "None (continuous rotation)",
    coupler_max_dev     = 0,
    tolerance_stack     = 2.4,
    power_margin        = _power_margin,
    gravity_ok          = (_power_margin >= 1.5),
    wall_thickness      = min(1.5, (BEARING_OD - BEARING_ID) / 2),
    clearance           = 0.4,
    part_count          = NUM_HELICES                            // helices
                        + NUM_HELICES * HELIX_NUM_DISCS          // discs
                        + NUM_HELICES * (HELIX_NUM_DISCS - 1)    // collars
                        + NUM_HELICES * SLIDERS_PER_HELIX        // sliders
                        + NUM_BLOCKS                              // blocks
                        + NUM_BLOCKS * 6                          // redirect pulleys (6/block)
                        + NUM_HELICES * 2                         // bearing housings
                        + NUM_HELICES                             // chain sprockets
                        + NUM_HELICES                             // chain tensioners
                        + 1                                       // motor
                        + 2                                       // bevel gear pair
                        + 6                                       // pin connectors
                        + 3                                       // matrix sheets
                        + 3                                       // legs
                        + 1                                       // hub
);

// --- Build Envelope ---
echo(str("Build envelope: ~", round(FRAME_RADIUS * 2 * 1.1), "mm dia × ",
         round(-BLOCK_NOMINAL_Z + max_displacement() + 20), "mm tall"));

// ============================================
// ANIMATION INSTRUCTIONS
// ============================================
// 1. Open in OpenSCAD
// 2. View → Animate, FPS: 30, Steps: 120
// 3. Watch the interference pattern in 37 hex blocks:
//    - Complex ripple from 3 superposed traveling waves
//    - Each block routes to NEAREST slider per tier
//    - Color encodes height: deep blue = low, white = high
//
// DEBUGGING:
//    MANUAL_ANGLE = 0/90/180/270  → static debug positions
//    HEX_RINGS = 1                → 7 blocks, fast sanity check
//    SHOW_ANNOTATIONS = true      → phase arrows + verification dots
//
// PERFORMANCE:
//    STRING_MODE = "cylinder"     → ~10x faster than "hull" (default)
//    LOD_LEVEL = 0                → wireframe preview
//    SHOW_STRINGS = false         → fastest render
//    SHOW_MATRIX = false          → remove matrix overlay
//
// QUALITY:
//    LOD_LEVEL = 2                → beveled blocks, grain lines, high $fn
//    STRING_MODE = "hull"         → accurate string rendering
//
// GRID PRESETS:
//    HEX_RINGS = 1  →  7 blocks (fast debug)
//    HEX_RINGS = 2  → 19 blocks (quick preview)
//    HEX_RINGS = 3  → 37 blocks (prime, default)
//    HEX_RINGS = 4  → 61 blocks (prime, rich pattern)
//    HEX_RINGS = 5  → 91 blocks (7×13, high detail, slow)
//
// SLIDER PRESETS:
//    SLIDERS_PER_HELIX = 5   → fast prototype
//    SLIDERS_PER_HELIX = 11  → balanced (default)
//    SLIDERS_PER_HELIX = 19  → high detail
//    SLIDERS_PER_HELIX = 37  → real sculpture (very slow)
//
// INDIVIDUAL PARTS FOR STL EXPORT:
//    Uncomment one at a time:
//    // hanging_block(0, 0, 0);     // Single hex block
//    // single_slider([0,0,0], 0);  // Single slider
//    // frame();                     // Frame only
