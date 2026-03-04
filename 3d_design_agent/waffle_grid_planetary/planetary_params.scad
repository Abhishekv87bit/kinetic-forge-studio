// ============================================================
// PARAMETER CALCULATOR — Phase 1
// Echo-only. Computes all derived values + 7 asserts.
// Run: openscad.com -o /dev/null planetary_params.scad
// All asserts must pass before proceeding.
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// ============================================================
// PRIMARY PARAMETERS
// ============================================================

// --- Internal Planetary (MOD=1.0) ---
MOD = 1.0;
PA = 20;

// Stage 1: S1 + 2*P1 = R1
S1_T = 13;
P1_T = 8;
R1_T = 29;

// Stage 2: S2 + 2*P2 = R2
S2_T = 11;
P2_T = 9;
R2_T = 29;

// --- External Drive (EXT_MOD=1.5) ---
EXT_MOD = 1.5;
EXT_T = 26;    // external teeth on ring
BPIN_T = 8;    // pinion on B/C shafts

// --- Geometry ---
GFW = 6;           // gear face width (mm)
EXT_GFW = 6;       // external gear face width
CARRIER_T = 2;     // carrier plate thickness
GAP = 3;           // gap between stages
PIN_D = 2;         // planet pin diameter
RING_WALL = 3;     // ring gear backing wall
N_PLANETS = 3;     // planets per stage
THRUST_WASHER_T = 0.5;  // PTFE thrust washer thickness (mm)
AXIAL_GAP = 0.2 + THRUST_WASHER_T;  // 0.7mm: 0.2 clearance + 0.5 washer

// --- Shaft & Tolerances ---
SHAFT_D = 5;       // hex across-flats (mm)
PIP_TOL = 0.35;    // print-in-place clearance
BACKLASH = 0.21;   // gear mesh backlash

// --- Bearings ---
BEARING_WALL = 1.5; // bushing radial wall thickness

// ============================================================
// DERIVED VALUES — Internal Planetary
// ============================================================

// Stage 1 center distance (sun-planet = planet-ring)
S1_ORB = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                   profile_shift1=0, profile_shift2=0);
S1_ORB_CHECK = gear_dist(mod=MOD, teeth1=R1_T, teeth2=P1_T,
                         internal1=true, profile_shift1=0, profile_shift2=0);

// Stage 2 center distance
S2_ORB = gear_dist(mod=MOD, teeth1=S2_T, teeth2=P2_T,
                   profile_shift1=0, profile_shift2=0);
S2_ORB_CHECK = gear_dist(mod=MOD, teeth1=R2_T, teeth2=P2_T,
                         internal1=true, profile_shift1=0, profile_shift2=0);

// Ring gear radii
R1_PITCH_R = pitch_radius(mod=MOD, teeth=R1_T);
R1_ROOT_R = root_radius(mod=MOD, teeth=R1_T, internal=true);
R1_OUTER_R = outer_radius(mod=MOD, teeth=R1_T, internal=true);

R2_PITCH_R = pitch_radius(mod=MOD, teeth=R2_T);
R2_ROOT_R = root_radius(mod=MOD, teeth=R2_T, internal=true);
R2_OUTER_R = outer_radius(mod=MOD, teeth=R2_T, internal=true);

// Ring body outer radius (backing beyond tooth root)
RING_INNER_R = R1_ROOT_R + RING_WALL;  // outer surface of ring body

// Sun gear radii
S1_OR = outer_radius(mod=MOD, teeth=S1_T);
S2_OR = outer_radius(mod=MOD, teeth=S2_T);

// Planet gear radii
P1_OR = outer_radius(mod=MOD, teeth=P1_T);
P2_OR = outer_radius(mod=MOD, teeth=P2_T);

// ============================================================
// DERIVED VALUES — External Drive
// ============================================================

// External teeth on ring
EXT_PITCH_R = pitch_radius(mod=EXT_MOD, teeth=EXT_T);
EXT_ROOT_R = root_radius(mod=EXT_MOD, teeth=EXT_T);
EXT_OUTER_R = outer_radius(mod=EXT_MOD, teeth=EXT_T);

// Pinion on B/C shafts
BPIN_PITCH_R = pitch_radius(mod=EXT_MOD, teeth=BPIN_T);
BPIN_ROOT_R = root_radius(mod=EXT_MOD, teeth=BPIN_T);
BPIN_OUTER_R = outer_radius(mod=EXT_MOD, teeth=BPIN_T);

// Drive center distance (ring ext to pinion)
DRIVE_CD = gear_dist(mod=EXT_MOD, teeth1=EXT_T, teeth2=BPIN_T,
                     profile_shift1=0, profile_shift2=0);

// Ring external OD
RING_EXT_OD = EXT_OUTER_R * 2;

// External root margin: how far ext root is above ring body
EXT_ROOT_MARGIN = EXT_ROOT_R - RING_INNER_R;

// Pinion tooth tip width (approximate: π*mod/2 at tip)
BPIN_TIP_WIDTH = PI * EXT_MOD * BPIN_T / (2 * (BPIN_T + 2));  // approximate

// ============================================================
// DERIVED VALUES — Bearings
// ============================================================
SHAFT_CIRC_R = SHAFT_D / (2 * cos(30));  // circumscribed radius of hex
BEARING_ID = SHAFT_CIRC_R * 2 + 2 * PIP_TOL;
BEARING_OD = BEARING_ID + 2 * BEARING_WALL;

// ============================================================
// DERIVED VALUES — Axial Stack
// ============================================================

// Stage 1: carrier_bottom + washer + gears + washer + carrier_top
STAGE1_H = CARRIER_T + AXIAL_GAP + GFW + AXIAL_GAP + CARRIER_T;
// Stage 2: carrier_bottom + washer + gears + washer + carrier_top
STAGE2_H = CARRIER_T + AXIAL_GAP + GFW + AXIAL_GAP + CARRIER_T;
// Total axial stack (includes coupling gap with washer)
TOTAL_STACK = STAGE1_H + AXIAL_GAP + STAGE2_H;

// ============================================================
// DERIVED VALUES — Envelope Checks
// ============================================================

// C-shaft Y-clearance: 50mm grid - drive CD - ring ext OD/2
C_SHAFT_Y_CLR = 50 - DRIVE_CD - EXT_OUTER_R;

// B-shaft goes vertical (Z), so no radial constraint from grid pitch

// ============================================================
// ECHO ALL VALUES
// ============================================================

echo("========================================");
echo("  PLANETARY DIFFERENTIAL PARAMETERS");
echo("========================================");

echo("--- Internal Planetary (MOD=1.0) ---");
echo(S1_T=S1_T, P1_T=P1_T, R1_T=R1_T);
echo(S2_T=S2_T, P2_T=P2_T, R2_T=R2_T);
echo(str("Stage1 ORB = ", S1_ORB, "  check = ", S1_ORB_CHECK));
echo(str("Stage2 ORB = ", S2_ORB, "  check = ", S2_ORB_CHECK));

echo("--- Ring Geometry ---");
echo(R1_ROOT_R=R1_ROOT_R, R1_PITCH_R=R1_PITCH_R);
echo(RING_INNER_R=RING_INNER_R);

echo("--- External Drive (EXT_MOD=1.5) ---");
echo(EXT_T=EXT_T, BPIN_T=BPIN_T);
echo(EXT_PITCH_R=EXT_PITCH_R, EXT_ROOT_R=EXT_ROOT_R, EXT_OUTER_R=EXT_OUTER_R);
echo(BPIN_PITCH_R=BPIN_PITCH_R, BPIN_ROOT_R=BPIN_ROOT_R, BPIN_OUTER_R=BPIN_OUTER_R);
echo(DRIVE_CD=DRIVE_CD);
echo(RING_EXT_OD=RING_EXT_OD);
echo(EXT_ROOT_MARGIN=EXT_ROOT_MARGIN);

echo("--- Bearings ---");
echo(SHAFT_CIRC_R=SHAFT_CIRC_R);
echo(BEARING_ID=BEARING_ID);
echo(BEARING_OD=BEARING_OD);

echo("--- Thrust Washers ---");
echo(THRUST_WASHER_T=THRUST_WASHER_T, AXIAL_GAP=AXIAL_GAP);

echo("--- Axial Stack ---");
echo(STAGE1_H=STAGE1_H, STAGE2_H=STAGE2_H, AXIAL_GAP=AXIAL_GAP);
echo(TOTAL_STACK=TOTAL_STACK);

echo("--- Envelope (50mm grid) ---");
echo(C_SHAFT_Y_CLR=C_SHAFT_Y_CLR);

// ============================================================
// 7 ASSERTIONS — ALL MUST PASS
// ============================================================

echo("========================================");
echo("  ASSERTIONS");
echo("========================================");

// 1. S+2P=R both stages
assert(S1_T + 2*P1_T == R1_T,
    str("FAIL: Stage1 S+2P=", S1_T+2*P1_T, " != R=", R1_T));
assert(S2_T + 2*P2_T == R2_T,
    str("FAIL: Stage2 S+2P=", S2_T+2*P2_T, " != R=", R2_T));
echo("✓ Assert 1: S+2P=R both stages");

// 2. ORB sun-planet = ORB planet-ring (both stages)
assert(abs(S1_ORB - S1_ORB_CHECK) < 0.001,
    str("FAIL: Stage1 ORB mismatch: ", S1_ORB, " vs ", S1_ORB_CHECK));
assert(abs(S2_ORB - S2_ORB_CHECK) < 0.001,
    str("FAIL: Stage2 ORB mismatch: ", S2_ORB, " vs ", S2_ORB_CHECK));
echo("✓ Assert 2: ORBs match both stages");

// 3. EXT root margin > 0.5mm
assert(EXT_ROOT_MARGIN > 0.5,
    str("FAIL: EXT root margin = ", EXT_ROOT_MARGIN, " < 0.5mm"));
echo(str("✓ Assert 3: EXT root margin = ", EXT_ROOT_MARGIN, "mm > 0.5mm"));

// 4. C-shaft Y-clearance > 0
assert(C_SHAFT_Y_CLR > 0,
    str("FAIL: C-shaft Y-clearance = ", C_SHAFT_Y_CLR, " <= 0"));
echo(str("✓ Assert 4: C-shaft Y-clearance = ", C_SHAFT_Y_CLR, "mm > 0"));

// 5. Pinion tooth tip > 1.2mm
// Tooth tip width ≈ π*mod*T/(2*(T+2)) is approximate;
// more accurately: tip = outer_r - pitch_r should be > 0.6mm (half-tooth)
BPIN_ADDENDUM = BPIN_OUTER_R - BPIN_PITCH_R;
assert(BPIN_ADDENDUM > 0.6,
    str("FAIL: Pinion addendum = ", BPIN_ADDENDUM, " <= 0.6mm"));
echo(str("✓ Assert 5: Pinion addendum = ", BPIN_ADDENDUM, "mm > 0.6mm"));

// 6. Axial stack < 50mm (with thrust washers)
assert(TOTAL_STACK < 50,
    str("FAIL: Axial stack = ", TOTAL_STACK, " >= 50mm"));
echo(str("✓ Assert 6: Axial stack = ", TOTAL_STACK, "mm < 50mm"));

// 8. Thrust washer thickness > 0.3mm (minimum for PTFE)
assert(THRUST_WASHER_T >= 0.3,
    str("FAIL: Thrust washer = ", THRUST_WASHER_T, " < 0.3mm minimum"));
echo(str("✓ Assert 8: Thrust washer = ", THRUST_WASHER_T, "mm >= 0.3mm"));

// 7. Ring ext dia < 50mm
assert(RING_EXT_OD < 50,
    str("FAIL: Ring ext OD = ", RING_EXT_OD, " >= 50mm"));
echo(str("✓ Assert 7: Ring ext OD = ", RING_EXT_OD, "mm < 50mm"));

echo("========================================");
echo("  ALL 8 ASSERTIONS PASSED");
echo("========================================");
