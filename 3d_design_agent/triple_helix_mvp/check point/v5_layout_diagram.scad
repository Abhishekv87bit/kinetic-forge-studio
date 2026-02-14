// =========================================================
// V5 LAYOUT DIAGRAM — Top View for Arm Geometry Decision
// =========================================================
// Shows: hex matrix, hex ring, stubs, arm paths, helix centers,
//        shaft axes, and bearing positions.
// Render with top view (View → Top) or use camera preset.
// =========================================================

$fn = 48;

// === V5 PARAMETERS ===
HEX_R           = 88.5;
HEX_C2C         = 2 * HEX_R;
HEX_FF          = HEX_R * sqrt(3);
ECCENTRICITY    = 20;
DISC_OD         = 27;
RIB_ARM_LENGTH  = 20;

// Frame
FRAME_RING_R_IN  = HEX_R + 2;       // 90.5
FRAME_RING_R_OUT = FRAME_RING_R_IN + 10;  // 100.5
STUB_LENGTH      = 30;
STUB_INWARD      = 8;
STUB_W           = 20;
ARM_W            = 20;
STUB_R_START     = FRAME_RING_R_OUT - STUB_INWARD;  // 92.5
STUB_R_END       = FRAME_RING_R_OUT + STUB_LENGTH;   // 130.5
JUNCTION_R       = STUB_R_END + STUB_W / 2;          // 140.5

// Star geometry
_STAR_RATIO      = 1.5;
STAR_TIP_R       = _STAR_RATIO * HEX_C2C;  // 265.5 (V4 full extent)
HEXAGRAM_INNER_R = STAR_TIP_R / sqrt(3);    // 153.3

// Helix positioning
CORRIDOR_GAP     = 58.5;  // scaled 75%
_V_PUSH          = CORRIDOR_GAP / (2 * tan(30));  // ~50.5
HELIX_R          = HEXAGRAM_INNER_R + _V_PUSH;     // ~203.8

// Helix angles
HELIX_ANGLES     = [180, 300, 60];
STUB_ANGLES      = [0, 120, 240];

// Arm definitions (V-angle)
V_ANGLE          = 74;
_HALF_V          = V_ANGLE / 2;
ARM_DEFS = [
    [0,   0 - _HALF_V],    // A0
    [0,   0 + _HALF_V],    // A1
    [120, 120 - _HALF_V],  // A2
    [120, 120 + _HALF_V],  // A3
    [240, 240 - _HALF_V],  // A4
    [240, 240 + _HALF_V],  // A5
];

// Shaft direction: perpendicular to radial
function shaft_dir(hi) =
    let(a = HELIX_ANGLES[hi])
    [-sin(a), cos(a)];

// Helix center
function helix_center(hi) =
    let(a = HELIX_ANGLES[hi])
    [HELIX_R * cos(a), HELIX_R * sin(a)];

// Helix cam stack half-length
HELIX_LENGTH = 9 * 14;  // 126mm
HALF_HELIX   = HELIX_LENGTH / 2;  // 63mm

// Bearing positions along shaft
function bearing_near(hi) =
    let(hc = helix_center(hi), sd = shaft_dir(hi))
    [hc[0] + sd[0] * (-HALF_HELIX - 10), hc[1] + sd[1] * (-HALF_HELIX - 10)];

function bearing_far(hi) =
    let(hc = helix_center(hi), sd = shaft_dir(hi))
    [hc[0] + sd[0] * (HALF_HELIX + 10), hc[1] + sd[1] * (HALF_HELIX + 10)];

// =========================================================
// DRAWING
// =========================================================

// --- Hex matrix (ghost) ---
color([0.3, 0.8, 0.3, 0.15])
    linear_extrude(1)
        circle(r = HEX_R, $fn = 6);

// --- Hex matrix edge label ---
color("green")
    translate([HEX_R + 5, 0, 2])
        text("HEX_R=88.5", size = 6);

// --- Frame ring ---
color([0.3, 0.3, 0.3, 0.4])
    linear_extrude(2)
        difference() {
            circle(r = FRAME_RING_R_OUT, $fn = 6);
            circle(r = FRAME_RING_R_IN, $fn = 6);
        }

// --- Reference circles ---
// Hexagram inner R (where arms cross)
color([0.5, 0.5, 0.5, 0.2])
    linear_extrude(0.5)
        difference() {
            circle(r = HEXAGRAM_INNER_R + 0.5);
            circle(r = HEXAGRAM_INNER_R - 0.5);
        }
color("gray")
    translate([HEXAGRAM_INNER_R + 5, 15, 2])
        text("CROSSING=153", size = 5);

// Helix R circle
color([0.2, 0.4, 0.9, 0.3])
    linear_extrude(0.5)
        difference() {
            circle(r = HELIX_R + 0.5);
            circle(r = HELIX_R - 0.5);
        }
color("blue")
    translate([HELIX_R + 5, -10, 2])
        text("HELIX_R=204", size = 5);

// V4 star tip R (for reference — dashed)
color([0.8, 0.8, 0.8, 0.15])
    linear_extrude(0.3)
        difference() {
            circle(r = STAR_TIP_R + 0.3);
            circle(r = STAR_TIP_R - 0.3);
        }
color([0.7, 0.7, 0.7])
    translate([STAR_TIP_R + 5, 0, 2])
        text("V4 STAR_TIP=265 (removed)", size = 4);

// --- Stubs (red) ---
for (sa = STUB_ANGLES) {
    color([0.7, 0.15, 0.15, 0.9])
        rotate([0, 0, sa])
            translate([STUB_R_START, -STUB_W/2, 0])
                cube([STUB_R_END - STUB_R_START, STUB_W, 3]);
}

// --- Arms (6 beams, each a different color) ---
ARM_COLORS = [
    [0.9, 0.2, 0.2],   // A0 red
    [0.2, 0.8, 0.2],   // A1 green
    [0.2, 0.4, 0.9],   // A2 blue
    [0.9, 0.6, 0.1],   // A3 orange
    [0.7, 0.2, 0.8],   // A4 purple
    [0.1, 0.8, 0.8],   // A5 cyan
];

for (ai = [0:5]) {
    stub_angle = ARM_DEFS[ai][0];
    tip_angle  = ARM_DEFS[ai][1];

    // Junction point (arm start)
    jx = JUNCTION_R * cos(stub_angle);
    jy = JUNCTION_R * sin(stub_angle);

    // Star tip point (V4 full extent — draw as thin line for reference)
    tx_full = STAR_TIP_R * cos(tip_angle);
    ty_full = STAR_TIP_R * sin(tip_angle);

    // Arm direction
    dx = tx_full - jx;
    dy = ty_full - jy;
    arm_len_full = sqrt(dx*dx + dy*dy);

    // Cut arm at HELIX_R radial distance (approximate)
    // Find parameter t where the arm line crosses HELIX_R circle
    // Arm point = junction + t * (tip - junction)
    // |arm_point| = HELIX_R
    // This is approximate — just extend to a reasonable length

    // For now, draw full arm as thin ghost, thick arm to ~HELIX_R

    // Ghost line (V4 full extent)
    color([ARM_COLORS[ai][0], ARM_COLORS[ai][1], ARM_COLORS[ai][2], 0.15])
        hull() {
            translate([jx, jy, 0]) cylinder(d = 3, h = 1);
            translate([tx_full, ty_full, 0]) cylinder(d = 3, h = 1);
        }

    // Solid arm (from junction toward helix, stopping approximately at HELIX_R)
    // Compute point along arm at roughly HELIX_R distance from origin
    _cut_frac = 0.55;  // approximate — arms reach ~204mm radius partway along
    cx = jx + _cut_frac * dx;
    cy = jy + _cut_frac * dy;
    _cr = sqrt(cx*cx + cy*cy);

    // Refine: binary search for the fraction where radius = HELIX_R
    // (OpenSCAD doesn't have while loops, so use a few iterations)
    _f1 = (_cr > HELIX_R) ? _cut_frac * 0.9 : _cut_frac * 1.1;
    _cx1 = jx + _f1 * dx;
    _cy1 = jy + _f1 * dy;

    // Just use a reasonable fraction for the diagram
    // Arm at fraction where R ≈ HELIX_R
    _best_frac = (HELIX_R - JUNCTION_R) / (STAR_TIP_R - JUNCTION_R) * 1.1;
    _bx = jx + min(_best_frac, 0.95) * dx;
    _by = jy + min(_best_frac, 0.95) * dy;

    color([ARM_COLORS[ai][0], ARM_COLORS[ai][1], ARM_COLORS[ai][2], 0.8])
        hull() {
            translate([jx, jy, 1]) cylinder(d = ARM_W, h = 4);
            translate([_bx, _by, 1]) cylinder(d = ARM_W, h = 4);
        }

    // Arm label
    _mx = (jx + _bx) / 2;
    _my = (jy + _by) / 2;
    color("black")
        translate([_mx, _my, 6])
            text(str("A", ai), size = 7, halign = "center");
}

// --- Helix centers (large blue dots) ---
for (hi = [0:2]) {
    hc = helix_center(hi);

    // Cam envelope circle (max rib reach)
    _max_reach = ECCENTRICITY + 9.5 + RIB_ARM_LENGTH;  // 49.5mm
    color([0.3, 0.6, 0.9, 0.15])
        translate([hc[0], hc[1], 0])
            linear_extrude(1)
                difference() {
                    circle(r = _max_reach);
                    circle(r = _max_reach - 1);
                }

    // Disc envelope
    color([0.3, 0.6, 0.9, 0.3])
        translate([hc[0], hc[1], 2])
            cylinder(r = ECCENTRICITY + DISC_OD/2, h = 3);  // 33.5mm

    // Center dot
    color([0.1, 0.3, 0.9])
        translate([hc[0], hc[1], 3])
            cylinder(d = 8, h = 5);

    // Label
    color("blue")
        translate([hc[0] + 12, hc[1] + 5, 8])
            text(str("H", hi+1), size = 10);

    // --- Shaft axis line (yellow) ---
    sd = shaft_dir(hi);
    _shaft_half = HALF_HELIX + 30;  // extend a bit past cam stack

    color([0.9, 0.9, 0.1, 0.8])
        hull() {
            translate([hc[0] + sd[0] * (-_shaft_half), hc[1] + sd[1] * (-_shaft_half), 4])
                cylinder(d = 3, h = 3);
            translate([hc[0] + sd[0] * _shaft_half, hc[1] + sd[1] * _shaft_half, 4])
                cylinder(d = 3, h = 3);
        }

    // --- Bearing positions (red dots) ---
    bn = bearing_near(hi);
    bf = bearing_far(hi);

    color([0.9, 0.2, 0.2])
        translate([bn[0], bn[1], 5])
            cylinder(d = 16, h = 4);  // 625ZZ OD

    color([0.9, 0.2, 0.2])
        translate([bf[0], bf[1], 5])
            cylinder(d = 16, h = 4);  // 625ZZ OD

    // Bearing labels
    color("red")
        translate([bn[0] + 10, bn[1], 10])
            text(str("Bn", hi+1), size = 5);
    color("red")
        translate([bf[0] + 10, bf[1], 10])
            text(str("Bf", hi+1), size = 5);
}

// --- Legend ---
translate([-280, -200, 0]) {
    color("black") text("V5 LAYOUT DIAGRAM (Top View)", size = 10);
    translate([0, -15, 0]) color("green") text("Green = hex matrix (88.5mm)", size = 7);
    translate([0, -28, 0]) color("gray") text("Gray circle = arm crossing (153mm)", size = 7);
    translate([0, -41, 0]) color("blue") text("Blue circle = HELIX_R (204mm)", size = 7);
    translate([0, -54, 0]) color([0.7,0.7,0.7]) text("Light gray = V4 star tips (265mm, removed)", size = 7);
    translate([0, -67, 0]) color([0.9,0.9,0.1]) text("Yellow lines = shaft axes", size = 7);
    translate([0, -80, 0]) color("red") text("Red dots = bearing positions (625ZZ)", size = 7);
    translate([0, -93, 0]) color("black") text("Solid arms = V5 extent | Ghost = V4 extent", size = 7);
}
