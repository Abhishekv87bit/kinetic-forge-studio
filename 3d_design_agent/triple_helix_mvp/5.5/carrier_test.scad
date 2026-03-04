// =========================================================
// CARRIER TEST — C-channel arms with solid bridge block
// =========================================================
// One corridor = two C-shaped members facing each other.
// Each C-member: upper arm → solid bridge block → lower arm.
// The bridge is one continuous block from upper arm outer face
// to lower arm outer face. Bearing housing is part of the block.
// No gussets — one clean solid.
// =========================================================

$fn = 32;

// =============================================
// PARAMETERS
// =============================================

// Arm cross-section
ARM_W       = 10;     // width (along shaft axis / Y)
ARM_H       = 7;      // height (vertical / Z)
ARM_CHAMFER = 1.5;

// Tier Z positions
UPPER_Z     = 22.5;
LOWER_Z     = -22.5;
HELIX_Z     = 0;

// Bearing — MR84ZZ
BRG_OD      = 8.0;
BRG_ID      = 4.0;
BRG_W       = 3.0;
BRG_BORE    = 8.15;

// Corridor
CORRIDOR_GAP = 31.4;
ARM_LENGTH   = 100;

// Shaft
SHAFT_DIA    = 4.0;
SHAFT_LEN    = 80;

// Bridge block — one solid piece
// Width (Y) = ARM_W (flush with arms)
// Height (Z) = upper arm outer face to lower arm outer face
// Depth (X) = enough to house bearing with wall all around
HOUSING_WALL  = 4.0;
BRIDGE_D      = BRG_OD + HOUSING_WALL * 2;   // 16mm depth along X
BRIDGE_Z_TOP  = UPPER_Z + ARM_H / 2;         // upper arm outer face
BRIDGE_Z_BOT  = LOWER_Z - ARM_H / 2;         // lower arm outer face
BRIDGE_H      = BRIDGE_Z_TOP - BRIDGE_Z_BOT; // full span

// =============================================
// COLORS
// =============================================
C_ARM     = [0.9, 0.4, 0.9, 0.9];
C_BEARING = [0.5, 0.5, 0.55, 0.8];
C_SHAFT   = [0.7, 0.7, 0.75, 0.9];
C_GHOST   = [0.3, 0.6, 0.9, 0.15];

// =============================================
// DISPLAY TOGGLES
// =============================================
SHOW_SHAFT     = true;
SHOW_BEARING   = true;
SHOW_GHOST_CAM = true;

// =============================================
// ASSEMBLY
// =============================================

// Left C-member
translate([0, -CORRIDOR_GAP/2, 0])
    c_member();

// Right C-member
translate([0, CORRIDOR_GAP/2, 0])
    c_member();

// Bridge center X (housing bore center)
_BRG_CX = ARM_LENGTH - (BRIDGE_D - ARM_H) / 2;

// Shaft
if (SHOW_SHAFT)
    color(C_SHAFT)
    translate([_BRG_CX, 0, HELIX_Z])
        rotate([90, 0, 0])
            cylinder(d=SHAFT_DIA, h=SHAFT_LEN, center=true);

// Bearings
if (SHOW_BEARING)
    for (y_sign = [-1, 1])
        color(C_BEARING)
        translate([_BRG_CX, y_sign * CORRIDOR_GAP/2, HELIX_Z])
            rotate([90, 0, 0])
                difference() {
                    cylinder(d=BRG_OD, h=BRG_W, center=true);
                    cylinder(d=BRG_ID, h=BRG_W+1, center=true);
                }

// Ghost cam
if (SHOW_GHOST_CAM)
    color(C_GHOST)
    translate([_BRG_CX, 0, HELIX_Z])
        rotate([90, 0, 0])
            cylinder(d=27, h=60, center=true);


// =============================================
// C-MEMBER: upper arm → bridge block → lower arm
// =============================================
module c_member() {
    // Bridge block X span
    _bx_inner = ARM_LENGTH - BRIDGE_D + ARM_H/2;  // inboard face
    _bx_outer = ARM_LENGTH + ARM_H/2;              // outboard face (flush with arm tip)

    color(C_ARM)
    difference() {
        union() {
            // === UPPER ARM ===
            _arm_bar([0, 0, UPPER_Z], [ARM_LENGTH, 0, UPPER_Z]);

            // === LOWER ARM ===
            _arm_bar([0, 0, LOWER_Z], [ARM_LENGTH, 0, LOWER_Z]);

            // === BRIDGE BLOCK — one continuous solid ===
            // BRIDGE_D deep (X), ARM_W wide (Y), full tier height (Z).
            // Centered so outer face aligns with arm end.
            _bridge_block();
        }

        // === BEARING BORE — through-hole ===
        translate([_BRG_CX, 0, HELIX_Z])
            rotate([90, 0, 0])
                cylinder(d=BRG_BORE, h=ARM_W + 4, center=true);

        // === SHAFT CLEARANCE ===
        translate([_BRG_CX, 0, HELIX_Z])
            rotate([90, 0, 0])
                cylinder(d=SHAFT_DIA + 1, h=200, center=true);
    }
}


// =============================================
// BRIDGE BLOCK — one solid from top to bottom
// =============================================
module _bridge_block() {
    _cx = ARM_LENGTH - (BRIDGE_D - ARM_H) / 2;
    _c = ARM_CHAMFER;

    // One hull from top to bottom — simple chamfered box
    hull() {
        translate([_cx, 0, BRIDGE_Z_TOP])
            _block_profile();
        translate([_cx, 0, BRIDGE_Z_BOT])
            _block_profile();
    }
}

// Block cross-section: BRIDGE_D along X, ARM_W along Y
module _block_profile() {
    _c = ARM_CHAMFER;
    if (_c > 0.2 && BRIDGE_D > 2*_c && ARM_W > 2*_c) {
        hull()
        for (x = [-BRIDGE_D/2 + _c, BRIDGE_D/2 - _c])
            for (y = [-ARM_W/2 + _c, ARM_W/2 - _c])
                translate([x, y, 0])
                    sphere(r = _c, $fn = 8);
    } else {
        cube([BRIDGE_D, ARM_W, 0.01], center=true);
    }
}


// =============================================
// ARM BAR — horizontal arm run
// =============================================
module _arm_bar(p1, p2) {
    _segs = 8;
    for (i = [0 : _segs - 1]) {
        t0 = i / _segs;
        t1 = (i + 1) / _segs;
        _p0 = [p1[0]+(p2[0]-p1[0])*t0, p1[1], p1[2]];
        _p1 = [p1[0]+(p2[0]-p1[0])*t1, p1[1], p1[2]];
        hull() {
            translate(_p0) _profile_yz();
            translate(_p1) _profile_yz();
        }
    }
}


// =============================================
// PROFILES
// =============================================

// Arm profile in YZ plane (horizontal arms along X)
module _profile_yz() {
    _c = ARM_CHAMFER;
    if (_c > 0.2 && ARM_W > 2*_c && ARM_H > 2*_c) {
        hull()
        for (y = [-ARM_W/2 + _c, ARM_W/2 - _c])
            for (z = [-ARM_H/2 + _c, ARM_H/2 - _c])
                translate([0, y, z])
                    sphere(r = _c, $fn = 8);
    } else {
        cube([0.01, ARM_W, ARM_H], center=true);
    }
}
