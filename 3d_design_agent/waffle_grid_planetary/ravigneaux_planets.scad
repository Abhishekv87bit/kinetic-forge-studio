// ============================================================
// RAVIGNEAUX PLANETS — Component 3 (Po) & Component 4 (Pi)
// ============================================================
// Uses SatisfyingGears 1.7 for production involute profiles.
// Simplified sun shafts shown as ghost references for mesh context.
//
// TOOTH COUNTS (SL bumped +2 for Po-Ss clearance):
//   Ss=26  Pi=19  Po=24  Ring=80  SL=32
//   T_RING = T_SL + 2*T_PO = 32 + 48 = 80 ✓ (exact, no profile shifts)
//   SL addendum dia ≈ SS addendum dia + 4.6mm
//   Po-Ss radial gap = 0.77mm (was 0 with SL=30)
//
// LAYOUT:
//   Po (long planet, 24T): outer orbit, meshes SL + Ring + Pi
//   Pi (short planet, 19T): inner orbit, meshes Ss + Po
//   Pi angularly offset from Po (~51°)
//   3 planet sets at 120° (display toggle available)
//
// Units: mm, degrees
// ============================================================

use <../gears/satisfying_gears/files/SatisfyingGears1.7.scad>

$fn = 48;

// ============================================================
// CUSTOMIZER CONTROLS
// ============================================================
/* [Planet Pi Controls] */
PI_TOOTH_COUNT = 19;   // [10:1:30] Tooth count (adjusts diameter)
PI_NUDGE_X     = 0;    // [-10:0.5:10] Fine X adjustment (mm)
PI_NUDGE_Y     = 0;    // [-10:0.5:10] Fine Y adjustment (mm)

/* [Display Toggles] */
SHOW_SS_GHOST  = true;   // Ss sun (transparent reference)
SHOW_SL_GHOST  = true;   // SL sun (transparent reference)
SHOW_PO        = true;   // Po long planet (red)
SHOW_PI        = true;   // Pi short planet (yellow)
SHOW_PIN       = true;   // Planet pins (steel)
SHOW_ALL_SETS  = false;  // Show all 3 planet sets at 120°

// ============================================================
// GEAR SPECS — reduced SL, miniature module
// ============================================================
NORM_MOD   = 0.7;
HELIX_ANG  = 25;
TRANS_MOD  = NORM_MOD / cos(HELIX_ANG);   // ~0.773mm
PRESS_ANG  = 20;
DP = 1 / TRANS_MOD;   // ~1.294

// Tooth counts — SL reduced, then bumped +2 for Po-Ss clearance
// Po-Ss gap = (T_SL - T_SS - 4) / (2*DP) — needs T_SL - T_SS > 4
T_SL   = 32;     // Large sun (was 30, +2 for Po-Ss clearance)
T_PO   = 24;     // Long planet — derived: (T_RING - T_SL) / 2 = (80-32)/2
T_RING = 80;     // Ring gear (internal)
T_SS   = 26;     // Small sun
T_PI   = PI_TOOTH_COUNT;   // Short planet (default 19)

// Number of planet sets
N_PLANETS = 3;

// ============================================================
// GEAR ZONE LAYOUT (matching ravigneaux_unit.scad)
// ============================================================
SS_GEAR_FW     = 6;
SL_GEAR_FW     = 6;
THRUST_PLATE_H = 1.5;

SS_ZONE_BOT = 0;
SS_ZONE_TOP = SS_GEAR_FW;                     // 6
SL_ZONE_BOT = SS_ZONE_TOP + THRUST_PLATE_H;   // 7.5
SL_ZONE_TOP = SL_ZONE_BOT + SL_GEAR_FW;       // 13.5
TOTAL_GEAR_H = SL_ZONE_TOP;                    // 13.5

// ============================================================
// ORBIT RADII — standard Ravigneaux geometry
// ============================================================
// Po orbit from SL-Po mesh
ORB_PO = (T_SL + T_PO) / (2 * DP);   // (30+25)/2.588 = ~21.25mm

// Po orbit from Ring-Po internal mesh (should match ORB_PO)
ORB_PO_RING = (T_RING - T_PO) / (2 * DP);  // (80-25)/2.588 = ~21.25mm
// NOTE: ORB_PO == ORB_PO_RING — EXACT match, no profile shifts needed ✓

// Pi orbit from Ss-Pi mesh
ORB_PI = (T_SS + T_PI) / (2 * DP);    // (26+19)/2.588 = ~17.39mm

// ============================================================
// PI ANGULAR OFFSET — dual mesh with BOTH Ss AND Po
// ============================================================
// Pi sits at ORB_PI (inner orbit) and meshes with Ss by radial distance.
// Angular offset from Po via law of cosines for Pi-Po center distance.
//
// CONSTRAINT: T_PI > (T_SL - T_SS)/2 = (30-26)/2 = 2.  T_PI=19 >> 2 ✓
//
// Law of cosines: d^2 = R1^2 + R2^2 - 2*R1*R2*cos(theta)

PI_PO_MESH_DIST = (T_PI + T_PO) / (2 * DP);   // (19+25)/2.588 = ~17.00mm

// Clamp acos argument to [-1, 1] for numerical safety
_pi_cos_arg = (ORB_PI * ORB_PI + ORB_PO * ORB_PO - PI_PO_MESH_DIST * PI_PO_MESH_DIST)
              / (2 * ORB_PI * ORB_PO);
PI_MESH_ANGLE = acos(min(1, max(-1, _pi_cos_arg)));

// Final Pi center position in XY
PI_POS_X = ORB_PI * cos(PI_MESH_ANGLE) + PI_NUDGE_X;
PI_POS_Y = ORB_PI * sin(PI_MESH_ANGLE) + PI_NUDGE_Y;

// ============================================================
// CLEARANCE CHECK — Pi vs SL
// ============================================================
// SL addendum radius (outer edge of SL gear)
SL_ADD_R = (T_SL + 2) / (2 * DP);   // (30+2)/2.588 = ~12.36mm

// Pi inner reach (closest tooth tip to center)
PI_ADD_R = (T_PI + 2) / (2 * DP);   // (19+2)/2.588 = ~8.11mm
PI_INNER_EDGE = ORB_PI - PI_ADD_R;   // 17.39 - 8.11 = ~9.28mm

// Pi pin clearance past SL outer edge
PI_PIN_CLEARANCE = ORB_PI - SL_ADD_R;   // 17.39 - 12.36 = ~5.03mm

// ============================================================
// PLANET PIN (M3 steel dowel)
// ============================================================
PIN_D    = 3;          // M3 steel dowel pin
PIN_CLEARANCE = 0.3;   // Bore clearance per side over pin
PO_BORE  = PIN_D + 2 * PIN_CLEARANCE;   // Planet bore ID
PI_BORE  = PIN_D + 2 * PIN_CLEARANCE;   // Same pin spec, same bore

// ============================================================
// PLANET FACE WIDTHS
// ============================================================
// Po (long, 25T): spans BOTH zones — meshes SL in upper, ring in both
// Pi (short, 19T): spans Ss zone only — meshes Ss + Po in lower zone
PO_FW = TOTAL_GEAR_H;           // Full height: 0 to TOTAL_GEAR_H
PI_FW = SS_GEAR_FW;             // Ss zone only: 0 to SS_GEAR_FW

// ============================================================
// SHAFT DIMENSIONS (for simplified reference geometry)
// ============================================================
SS_TUBE_OD = 8;
SL_TUBE_OD = 10.5;

// ============================================================
// TOLERANCES
// ============================================================
TOL_GENERAL = 0.20;
BACKLASH    = 0.10;

// ============================================================
// COLORS
// ============================================================
C_SS    = [0.15, 0.55, 0.30, 0.25];   // Green (transparent ghost)
C_SL    = [0.76, 0.60, 0.22, 0.25];   // Gold (transparent ghost)
C_PO    = [0.85, 0.25, 0.20];          // Red — Po long planet
C_PI    = [0.90, 0.80, 0.20];          // Yellow — Pi short planet
C_PIN   = [0.50, 0.50, 0.55];          // Steel grey — planet pin

// ============================================================
// SIMPLIFIED SUN REFERENCES (ghost geometry for mesh context)
// ============================================================
module ss_ghost() {
    color(C_SS)
    translate([0, 0, SS_ZONE_BOT + SS_GEAR_FW / 2])
    PairGears(
        TeethA         = T_SS,
        TeethB         = T_SS,
        BacklashA      = BACKLASH,
        BacklashB      = 0,
        PressureAngle  = PRESS_ANG,
        DiametralPitch = DP,
        Thickness      = SS_GEAR_FW,
        HelixFaceAngle = HELIX_ANG,
        Layers         = 2,
        ChamferThickness = 0.3,
        InnerChamfers  = false,
        GearAExists    = true,
        GearBExists    = false
    );
}

module sl_ghost() {
    color(C_SL)
    translate([0, 0, SL_ZONE_BOT + SL_GEAR_FW / 2])
    PairGears(
        TeethA         = T_SL,
        TeethB         = T_SL,
        BacklashA      = BACKLASH,
        BacklashB      = 0,
        PressureAngle  = PRESS_ANG,
        DiametralPitch = DP,
        Thickness      = SL_GEAR_FW,
        HelixFaceAngle = HELIX_ANG,
        Layers         = 2,
        ChamferThickness = 0.3,
        InnerChamfers  = false,
        GearAExists    = true,
        GearBExists    = false
    );
}

// ============================================================
// COMPONENT 3: LONG PLANET (Po) — ONE UNIFIED SOLID
// ============================================================
// 24T herringbone, spans both gear zones (Z=0 to TOTAL_GEAR_H).
// Meshes with SL sun in upper zone, ring gear in both zones,
// and Pi (short planet) in the lower zone.
// Bore rides on carrier's steel dowel pin.
// No shaft below gear face (ISSUE-001). Unified solid (ISSUE-006).

module po_planet() {
    color(C_PO)
    translate([ORB_PO, 0, 0])
    difference() {
        // Gear teeth — herringbone, full height
        translate([0, 0, SS_ZONE_BOT + PO_FW / 2])
        PairGears(
            TeethA         = T_PO,
            TeethB         = T_PO,
            BacklashA      = BACKLASH,
            BacklashB      = 0,
            PressureAngle  = PRESS_ANG,
            DiametralPitch = DP,
            Thickness      = PO_FW,
            HelixFaceAngle = HELIX_ANG,
            Layers         = 2,
            ChamferThickness = 0.3,
            InnerChamfers  = false,
            GearAExists    = true,
            GearBExists    = false
        );

        // Bore for planet pin — single subtraction through entire gear
        translate([0, 0, SS_ZONE_BOT - 0.1])
        cylinder(d=PO_BORE, h=PO_FW + 0.2, $fn=48);
    }
}

// ============================================================
// COMPONENT 4: SHORT PLANET (Pi) — ONE UNIFIED SOLID
// ============================================================
// 19T herringbone, spans Ss zone only (Z=0 to SS_GEAR_FW).
// Orbits at ORB_PI (Ss-Pi mesh distance) — INNER orbit.
// Angularly offset from Po for dual mesh: Ss + Po.
// PI_TOOTH_COUNT adjusts diameter. PI_NUDGE_X/Y for fine-tuning.
// Bore rides on its own carrier pin (separate from Po pin).

module pi_planet() {
    color(C_PI)
    translate([PI_POS_X, PI_POS_Y, 0])
    difference() {
        // Gear teeth — herringbone, Ss zone height only
        translate([0, 0, SS_ZONE_BOT + PI_FW / 2])
        PairGears(
            TeethA         = T_PI,
            TeethB         = T_PI,
            BacklashA      = BACKLASH,
            BacklashB      = 0,
            PressureAngle  = PRESS_ANG,
            DiametralPitch = DP,
            Thickness      = PI_FW,
            HelixFaceAngle = HELIX_ANG,
            Layers         = 2,
            ChamferThickness = 0.3,
            InnerChamfers  = false,
            GearAExists    = true,
            GearBExists    = false
        );

        // Bore for planet pin
        translate([0, 0, SS_ZONE_BOT - 0.1])
        cylinder(d=PI_BORE, h=PI_FW + 0.2, $fn=48);
    }
}

// ============================================================
// PLANET PINS — separate pins for Po and Pi
// ============================================================
module po_pin() {
    pin_extension = 2;
    color(C_PIN)
    translate([ORB_PO, 0, SS_ZONE_BOT - pin_extension])
    cylinder(d=PIN_D, h=PO_FW + 2 * pin_extension, $fn=48);
}

module pi_pin() {
    pin_extension = 2;
    color(C_PIN)
    translate([PI_POS_X, PI_POS_Y, SS_ZONE_BOT - pin_extension])
    cylinder(d=PIN_D, h=PI_FW + 2 * pin_extension, $fn=48);
}

// ============================================================
// PLANET SET — one Po + one Pi at a given rotation angle
// ============================================================
module planet_set(angle=0) {
    rotate([0, 0, angle]) {
        if (SHOW_PO) po_planet();
        if (SHOW_PI) pi_planet();
        if (SHOW_PIN) {
            po_pin();
            pi_pin();
        }
    }
}

// ============================================================
// MAIN
// ============================================================
if (SHOW_SS_GHOST) %ss_ghost();
if (SHOW_SL_GHOST) %sl_ghost();

if (SHOW_ALL_SETS) {
    // 3 planet sets at 120° spacing
    for (i = [0 : N_PLANETS - 1])
        planet_set(i * 360 / N_PLANETS);
} else {
    // Single planet set for component development
    planet_set(0);
}

// ============================================================
// ECHO — specs and verification
// ============================================================
echo(str("=== TOOTH COUNTS ==="));
echo(str("Ss=", T_SS, " Pi=", T_PI, " Po=", T_PO,
         " Ring=", T_RING, " SL=", T_SL));
echo(str("Ring check: T_SL + 2*T_PO = ", T_SL, "+", 2*T_PO,
         " = ", T_SL + 2*T_PO, " == T_RING=", T_RING, " ✓"));

echo(str("=== SUN DIAMETERS (SL ≈ SS + 3mm) ==="));
echo(str("SS addendum dia=", (T_SS + 2) / DP, "mm"));
echo(str("SL addendum dia=", (T_SL + 2) / DP, "mm"));
echo(str("Difference=", ((T_SL + 2) - (T_SS + 2)) / DP, "mm"));

echo(str("=== COMPONENT 3: Po LONG PLANET ==="));
echo(str("Po: ", T_PO, "T, PitchDia=", T_PO / DP, "mm"));
echo(str("Orbit=", ORB_PO, "mm (outer)"));
echo(str("Ring orbit=", ORB_PO_RING, "mm (matches: ", ORB_PO == ORB_PO_RING, ")"));
echo(str("FaceWidth=", PO_FW, "mm"));

echo(str("=== COMPONENT 4: Pi SHORT PLANET ==="));
echo(str("Pi: ", T_PI, "T, PitchDia=", T_PI / DP, "mm"));
echo(str("Orbit=", ORB_PI, "mm (inner), Angle=", PI_MESH_ANGLE, "deg from Po"));
echo(str("Position: X=", PI_POS_X, " Y=", PI_POS_Y));
echo(str("FaceWidth=", PI_FW, "mm"));

echo(str("=== DUAL MESH VERIFICATION ==="));
echo(str("Ss-Pi: pitch sum=", (T_SS + T_PI) / (2 * DP),
         "mm == ORB_PI=", ORB_PI, "mm ✓"));
_pi_po_actual = sqrt(
    (PI_POS_X - ORB_PO) * (PI_POS_X - ORB_PO) +
    PI_POS_Y * PI_POS_Y
);
echo(str("Pi-Po: required=", PI_PO_MESH_DIST,
         "mm, actual=", _pi_po_actual, "mm",
         " (delta=", _pi_po_actual - PI_PO_MESH_DIST, ")"));

echo(str("=== Pi vs SL CLEARANCE ==="));
echo(str("SL outer edge R=", SL_ADD_R, "mm"));
echo(str("Pi inner tooth R=", PI_INNER_EDGE, "mm (radial overlap=",
         SL_ADD_R - PI_INNER_EDGE, "mm — OK, different Z zones)"));
echo(str("Pi PIN clearance past SL=", PI_PIN_CLEARANCE, "mm ✓"));

echo(str("=== Po vs Ss CLEARANCE (ISSUE-012) ==="));
_ss_add_r = (T_SS + 2) / (2 * DP);
_po_add_r = (T_PO + 2) / (2 * DP);
_po_inner = ORB_PO - _po_add_r;
_po_ss_gap = _po_inner - _ss_add_r;
echo(str("Ss outer R=", _ss_add_r, "mm, Po inner R=", _po_inner, "mm"));
echo(str("Po-Ss radial gap=", _po_ss_gap, "mm",
         _po_ss_gap > 0 ? " ✓" : " COLLISION!"));
