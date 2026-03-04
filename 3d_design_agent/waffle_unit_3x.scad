// =============================================================
// WAFFLE UNIT 3× — Three Nodes on Shared Shafts
// HERRINGBONE GEARS — self-centering, no axial thrust
// Different internal ratios per node → phase offsets → wave
//
// ARCHITECTURE:
//   3 nodes along X-axis, sharing 3 parallel shafts:
//     A-shaft (red hex): center, drives all Suns
//     B-shaft (green): ABOVE (+Z), drives all Ring1 via ext teeth
//     C-shaft (blue): SIDE (+Y), drives all Ring2 via ext teeth
//
//   Each node has DIFFERENT internal sun/planet tooth counts:
//     Node 0: S1=13, P1=8   → ratio 0.448
//     Node 1: S1=15, P1=7   → ratio 0.517
//     Node 2: S1=17, P1=6   → ratio 0.586
//   All share R1=29 → same ring body, same ext teeth, same shaft mesh
//
// GEAR CONVENTION (Herringbone, H=30°):
//   Internal gears: Sun +H, Planet -H, Ring -H (internal)
//   External drive: Ext ring +H_ext, Pinion -H_ext
//   herringbone=true → double-helical chevron → zero axial thrust
//   Thinner face widths possible since no thrust bearings needed
//
// ENCLOSURE: Ring2 extends as cylindrical shell covering Stage 2.
//   Stage 1 stays exposed (Ring1 has its own ext teeth for B-pinion).
//   Ring2 enclosure outer surface = spool + ext screw teeth for C-pinion.
//
// Units: mm
// =============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

$fn = 48;

// ---- ANIMATION ----
// Use $t for animation (0→1), or MANUAL for static preview
MANUAL_POSITION = -1;   // set ≥0 to override $t
POS = MANUAL_POSITION >= 0 ? MANUAL_POSITION : $t;

// ---- TOLERANCES ----
TOL      = 0.25;
BACKLASH = 0.1;

// ---- GEAR MODULES ----
MOD     = 1.0;    // internal planetary
EXT_MOD = 1.5;    // external drive (ring ext + pinion) — compact!
PA      = 20;     // pressure angle

// ---- HERRINGBONE GEAR PARAMETERS ----
// 30° helix angle — good balance of overlap and radial force
// herringbone=true → BOSL2 creates double-helical chevron pattern
// Self-centering: zero net axial thrust → no thrust bearings needed
// Allows thinner face widths than single-helix screw gears
H       = 30;     // internal planetary helical angle
H_EXT   = 30;     // external drive helical angle
SLICES  = 10;     // slices for smooth herringbone render
HERRING = true;   // master herringbone toggle

// =============================================================
// NODE CONFIGURATIONS — different ratios per node
//
// All nodes share R1_T=29 and R2_T=29 (same ring body, same ext teeth).
// Sun + 2*Planet = Ring for each stage.
// Different S/P gives different carrier output speed → phase offset.
// =============================================================
R1_T = 29;   // ring — same for all nodes
R2_T = 29;

// Node variant table: [Sun1_T, Planet1_T, Sun2_T, Planet2_T]
// Stage 1 varies → different Ring1 input blending
// Stage 2 also varies → compound effect → MORE phase spread
NODE_CONFIGS = [
    [13, 8, 11, 9],   // Node 0: S1=13,P1=8, S2=11,P2=9
    [15, 7, 13, 8],   // Node 1: S1=15,P1=7, S2=13,P2=8
    [17, 6, 15, 7],   // Node 2: S1=17,P1=6, S2=15,P2=7
];

NUM_NODES = len(NODE_CONFIGS);

// Validate all configs
for (i = [0 : NUM_NODES-1]) {
    assert(NODE_CONFIGS[i][0] + 2*NODE_CONFIGS[i][1] == R1_T,
           str("Node ", i, " Stage1: S+2P!=R"));
    assert(NODE_CONFIGS[i][2] + 2*NODE_CONFIGS[i][3] == R2_T,
           str("Node ", i, " Stage2: S+2P!=R"));
}

// =============================================================
// RING BODY — shared geometry (same for all nodes)
// =============================================================
RING_WALL    = 3.5;   // thicker ring backing for structural integrity
R1_RR        = root_radius(mod=MOD, teeth=R1_T, internal=true);
RING_INNER_R = R1_RR + RING_WALL;

// =============================================================
// RING EXTERNAL TEETH (EXT_MOD=1.5, herringbone)
// =============================================================
EXT_T_RAW   = ceil(2 * (RING_INNER_R + 0.5 + 1.25*EXT_MOD) / EXT_MOD);
EXT_T_CLEAN = EXT_T_RAW + (EXT_T_RAW % 2);
PS_EXT      = auto_profile_shift(teeth=EXT_T_CLEAN, pressure_angle=PA);
EXT_PR      = pitch_radius(mod=EXT_MOD, teeth=EXT_T_CLEAN);
EXT_OR      = outer_radius(mod=EXT_MOD, teeth=EXT_T_CLEAN);
EXT_RR      = root_radius(mod=EXT_MOD, teeth=EXT_T_CLEAN);

// Axial pitch (used for overlap checks after face width declaration)
INT_AXIAL_PITCH = PI * MOD / tan(H);
EXT_AXIAL_PITCH = PI * EXT_MOD / tan(H_EXT);

echo("=== EXTERNAL DRIVE ===");
echo("EXT_MOD=", EXT_MOD, "EXT_T=", EXT_T_CLEAN,
     "EXT_OR=", EXT_OR, "EXT_RR=", EXT_RR,
     "root_margin=", EXT_RR - RING_INNER_R);

assert(EXT_RR >= RING_INNER_R + 0.3);

// =============================================================
// DRIVE PINIONS (EXT_MOD=1.5, herringbone — opposite helix for mesh)
// =============================================================
BPIN_T  = 8;   // slightly more teeth for smoother mesh at EXT_MOD=1.5
PS_BPIN = auto_profile_shift(teeth=BPIN_T, pressure_angle=PA);
BPIN_PR = pitch_radius(mod=EXT_MOD, teeth=BPIN_T);
BPIN_OR = outer_radius(mod=EXT_MOD, teeth=BPIN_T);

DRIVE_CD = gear_dist(mod=EXT_MOD, teeth1=EXT_T_CLEAN, teeth2=BPIN_T,
                     helical=H_EXT,
                     profile_shift1=PS_EXT, profile_shift2=PS_BPIN);

echo("BPIN_T=", BPIN_T, "DRIVE_CD=", DRIVE_CD);

// =============================================================
// SHAFT LAYOUT — 90° separation
// B-shaft above (+Z), C-shaft to the side (+Y)
// =============================================================
B_DY = 0;          B_DZ = DRIVE_CD;
C_DY = DRIVE_CD;   C_DZ = 0;

echo("DRIVE_CD=", DRIVE_CD, "B at Z=+", DRIVE_CD, "C at Y=+", DRIVE_CD);

// =============================================================
// PHYSICAL DIMENSIONS — compact herringbone
// Herringbone: each half needs overlap > 1 → half_FW > axial_pitch
// axial_pitch = pi * MOD / tan(30°) ≈ 5.44mm at MOD=1
// Each half = GFW/2 ≥ 5.44mm → GFW ≥ 11mm. We use 10 (close enough).
// EXT: axial_pitch = pi * 1.5 / tan(30°) ≈ 8.16mm → half ≥ 8.16mm
// EXT_GFW = 14 → half=7, overlap=0.86 (acceptable for low-torque spool)
// =============================================================
GFW        = 10;    // internal planetary face width — herringbone compact
EXT_GFW    = 14;    // external drive face width — herringbone
GAP        = 3;     // inter-stage gap
CARRIER_T  = 2.5;   // carrier plate thickness
SHAFT_D    = 4;
BC_SHAFT_D = 4;
CPLG_ID    = SHAFT_D + 0.5;
CPLG_OD    = 7;
PIN_D      = 2;

BRG_OD = 8;  BRG_ID = 4;  BRG_W = 3;

// Herringbone overlap ratio diagnostics (GFW/EXT_GFW now defined)
echo("=== HERRINGBONE OVERLAP ===");
echo("GFW=", GFW, "half_overlap_int=", (GFW/2)/INT_AXIAL_PITCH,
     "(full=", GFW/INT_AXIAL_PITCH, ")");
echo("EXT_GFW=", EXT_GFW, "half_overlap_ext=", (EXT_GFW/2)/EXT_AXIAL_PITCH,
     "(full=", EXT_GFW/EXT_AXIAL_PITCH, ")");

// =============================================================
// NODE STACK LAYOUT (axial = X)
// =============================================================
// Ring bodies are EXT_GFW wide (not GFW) because they carry external teeth.
// Stage spacing must use EXT_GFW to prevent ring-to-ring collision.
S1_LOCAL    = -(GAP/2 + EXT_GFW/2);
S2_LOCAL    =  (GAP/2 + EXT_GFW/2);
STACK_HALF  = EXT_GFW/2 + CARRIER_T;
TOTAL_STACK = (EXT_GFW + CARRIER_T*2)*2 + GAP;

// =============================================================
// STAGE 2 ENCLOSURE-SPOOL
//
// Ring2 extends axially as a cylindrical shell covering Stage 2
// internals (Sun2, Planets2, Carriers2). The enclosure:
//   - Has internal ring gear teeth where planets mesh
//   - Extends as smooth cylinder shell beyond the gear zone
//   - Outer surface carries ext herringbone teeth for C-pinion mesh
//   - Smooth drum section beyond ext teeth = SPOOL for thread
//   - Flanges at spool ends contain the thread
//
// Stage 1 stays EXPOSED — Ring1 has its own ext teeth for B-pinion.
// Ring2 enclosure rotates with C-shaft → spool winds/unwinds thread.
// =============================================================

HOUSING_OR       = RING_INNER_R;     // enclosure cylinder OR = ring body surface
HOUSING_WALL     = RING_WALL;        // structural wall
THREAD_GROOVE_W  = 1.5;             // thread groove visual width
THREAD_PITCH_MM  = 3.0;             // helical thread pitch on spool

// Enclosure extends from Stage 2 ring center toward Stage 1
// covering the gap, coupling, and carrier plates
ENCL_INWARD  = GAP/2 + CARRIER_T + 2;   // how far enclosure extends INWARD (toward Stage 1)
// Enclosure extends outward past ext teeth to form spool drum
SPOOL_EXT    = 10;               // spool drum length beyond ext teeth
SPOOL_GAP    = 1;                // gap between ext teeth and spool drum

// Spool + flange dimensions
SPOOL_OD     = 2 * HOUSING_OR;
FLANGE_R     = EXT_OR + 1;      // flanges at ext tooth tip radius + clearance
FLANGE_T     = 1.5;
SPOOL_DRUM_LEN = SPOOL_EXT;

// Total enclosure axial span (from inward extension to spool end)
ENCL_TOTAL_LEN = ENCL_INWARD + EXT_GFW/2 + SPOOL_GAP + SPOOL_DRUM_LEN;

// Thread + pixel
THREAD_LEN = 60;
PIXEL_W    = 18;
PIXEL_H    = 3;

// Grid spacing along X (between node centers) — compact herringbone
NODE_PITCH = 48;    // tighter pitch with EXT_MOD=1.5 + herringbone

// Total node X extent
NODE_X_MIN = S1_LOCAL - EXT_GFW/2 - FLANGE_T;
NODE_X_MAX = S2_LOCAL + EXT_GFW/2 + SPOOL_GAP + SPOOL_DRUM_LEN + FLANGE_T;

// Shaft dimensions
SHAFT_MARGIN = 25;
SHAFT_X_START = NODE_X_MIN - SHAFT_MARGIN;
SHAFT_X_END   = (NUM_NODES-1)*NODE_PITCH + NODE_X_MAX + SHAFT_MARGIN;
SHAFT_LEN     = SHAFT_X_END - SHAFT_X_START;
SHAFT_X_MID   = (SHAFT_X_START + SHAFT_X_END) / 2;

// =============================================================
// KINEMATICS — per-node, computed as functions
//
// For animation: all 3 shafts spin. Each node computes its own
// carrier output based on its unique S/P/R tooth counts.
// =============================================================
A_SPEED = 1.0;
B_SPEED = 1.13;
C_SPEED = 0.87;

A_IN = POS * 360 * A_SPEED;
B_IN = POS * 360 * B_SPEED;
C_IN = POS * 360 * C_SPEED;

// Per-node kinematic output
function node_sun1_a(i) = A_IN;
function node_ring1_a(i) = B_IN;
function node_car1_a(i) = let(
    s1 = NODE_CONFIGS[i][0],
    r1 = R1_T
) (node_sun1_a(i)*s1 + node_ring1_a(i)*r1) / (s1 + r1);

function node_sun2_a(i) = node_car1_a(i);
function node_ring2_a(i) = C_IN;
function node_car2_a(i) = let(
    s2 = NODE_CONFIGS[i][2],
    r2 = R2_T
) (node_sun2_a(i)*s2 + node_ring2_a(i)*r2) / (s2 + r2);

function node_p1_self(i) = let(
    s1 = NODE_CONFIGS[i][0],
    p1 = NODE_CONFIGS[i][1]
) -(node_car1_a(i) - node_sun1_a(i)) * s1 / p1;

function node_p2_self(i) = let(
    s2 = NODE_CONFIGS[i][2],
    p2 = NODE_CONFIGS[i][3]
) -(node_car2_a(i) - node_sun2_a(i)) * s2 / p2;

BPIN_A_RATIO = -EXT_T_CLEAN / BPIN_T;
CPIN_A_RATIO = -EXT_T_CLEAN / BPIN_T;

// =============================================================
// COLORS
// =============================================================
C_SUN   = [0.85, 0.25, 0.20];
C_SUN2  = [0.70, 0.20, 0.25];
C_RING  = [0.95, 0.40, 0.60];
C_RING2 = [0.68, 0.62, 0.25];
C_EXT   = [0.90, 0.80, 0.30];
C_EXT2  = [0.80, 0.70, 0.28];
C_PLN1  = [0.50, 0.75, 0.50];
C_PLN2  = [0.40, 0.65, 0.40];
C_CAR   = [0.30, 0.50, 0.80];
C_CAR2  = [0.25, 0.42, 0.72];
C_CPLG  = [0.45, 0.65, 0.90];
C_SPL   = [0.58, 0.40, 0.22];
C_FLNG  = [0.65, 0.48, 0.28];
C_THR   = [0.82, 0.82, 0.88];
C_PIX   = [0.74, 0.60, 0.40];
C_SHA   = [0.88, 0.30, 0.22];
C_SHB   = [0.22, 0.75, 0.30];
C_SHC   = [0.22, 0.38, 0.90];
C_PIN   = [0.65, 0.65, 0.68];
C_BPIN  = [0.30, 0.80, 0.30];
C_CPIN  = [0.30, 0.40, 0.90];
C_BRG   = [0.45, 0.45, 0.50];

/* [Nodes] */
SHOW_NODE_0       = true;   // Node 0 (first unit)
SHOW_NODE_1       = false;  // Node 1 (second unit)
SHOW_NODE_2       = false;  // Node 2 (third unit)

/* [Show / Hide] */
SHOW_SHAFTS       = true;   // A, B, C shafts
SHOW_STAGE1       = true;   // Stage 1 gears + carrier + B-pinion
SHOW_STAGE2       = true;   // Stage 2 gears + carrier + C-pinion
SHOW_ENCLOSURE    = true;   // Stage 2 enclosure shell
SHOW_SPOOL        = true;   // Spool drum + flanges + thread groove
SHOW_THREADS      = true;   // Thread line dropping from spool
SHOW_PIXELS       = true;   // Wooden pixel block at bottom

/* [Gear Detail] */
SHOW_SUNS         = true;   // Sun gears
SHOW_RINGS        = true;   // Ring internal teeth
SHOW_EXT_TEETH    = true;   // External herringbone teeth on rings
SHOW_PLANETS      = true;   // Planet gears (3 per stage)

/* [Carrier Detail] */
SHOW_CARRIER_PLATES = true; // Carrier discs
SHOW_PLANET_PINS    = true; // Planet axle pins
SHOW_BEARINGS       = true; // Center bearings
SHOW_COUPLING       = true; // Coupling tube (Stage1 to Stage2)

/* [Enclosure Detail] */
SHOW_ENCL_SHELL   = true;   // Cylindrical enclosure shell (Ring2)
SHOW_SPOOL_DRUM   = true;   // Spool drum (Carrier2 output)
SHOW_FLANGES      = true;   // Flange discs at spool ends
SHOW_GROOVE       = true;   // Thread groove helix visualization

/* [Hidden] */
SHOW_NODE = [SHOW_NODE_0, SHOW_NODE_1, SHOW_NODE_2];

// =============================================================
// MAIN ASSEMBLY
// =============================================================
main();

module main() {
    // 3 shared shafts
    if (SHOW_SHAFTS) shafts();

    // 3 nodes — each can be toggled independently
    for (n = [0 : NUM_NODES-1])
        if (SHOW_NODE[n])
        translate([n * NODE_PITCH, 0, 0])
        node(n);
}

// =============================================================
// SHAFTS — 3 parallel, shared by all nodes
// =============================================================
module shafts() {
    // A-shaft (red hex)
    color(C_SHA)
    translate([SHAFT_X_MID, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, A_IN])
    cylinder(d=SHAFT_D, h=SHAFT_LEN, center=true, $fn=6);

    // B-shaft (green) — ABOVE
    color(C_SHB)
    translate([SHAFT_X_MID, B_DY, B_DZ])
    rotate([0, 90, 0])
    rotate([0, 0, B_IN])
    cylinder(d=BC_SHAFT_D, h=SHAFT_LEN, center=true);

    // C-shaft (blue) — SIDE
    color(C_SHC)
    translate([SHAFT_X_MID, C_DY, C_DZ])
    rotate([0, 90, 0])
    rotate([0, 0, C_IN])
    cylinder(d=BC_SHAFT_D, h=SHAFT_LEN, center=true);
}

// =============================================================
// SINGLE NODE — parameterized by index
// =============================================================
module node(idx) {
    s1_t = NODE_CONFIGS[idx][0];
    p1_t = NODE_CONFIGS[idx][1];
    s2_t = NODE_CONFIGS[idx][2];
    p2_t = NODE_CONFIGS[idx][3];

    // Profile shifts for this node's specific tooth counts
    ps_s1 = auto_profile_shift(teeth=s1_t, pressure_angle=PA);
    ps_p1 = auto_profile_shift(teeth=p1_t, pressure_angle=PA);
    ps_s2 = auto_profile_shift(teeth=s2_t, pressure_angle=PA);
    ps_p2 = auto_profile_shift(teeth=p2_t, pressure_angle=PA);

    orb1 = gear_dist(mod=MOD, teeth1=s1_t, teeth2=p1_t, helical=H,
                     profile_shift1=ps_s1, profile_shift2=ps_p1);
    orb2 = gear_dist(mod=MOD, teeth1=s2_t, teeth2=p2_t, helical=H,
                     profile_shift1=ps_s2, profile_shift2=ps_p2);

    // Kinematic angles for this node
    sun1_a  = node_sun1_a(idx);
    ring1_a = node_ring1_a(idx);
    car1_a  = node_car1_a(idx);
    sun2_a  = node_sun2_a(idx);
    ring2_a = node_ring2_a(idx);
    car2_a  = node_car2_a(idx);
    p1_self = node_p1_self(idx);
    p2_self = node_p2_self(idx);
    bpin_a  = ring1_a * BPIN_A_RATIO;
    cpin_a  = ring2_a * CPIN_A_RATIO;

    // ========== STAGE 1 ==========
    if (SHOW_STAGE1)
    translate([S1_LOCAL, 0, 0])
    rotate([0, 90, 0]) {
        // SUN1 — herringbone +H
        if (SHOW_SUNS)
        color(C_SUN)
        rotate([0, 0, sun1_a])
        spur_gear(mod=MOD, teeth=s1_t, thickness=GFW,
                  shaft_diam=SHAFT_D, pressure_angle=PA,
                  helical=H, herringbone=HERRING, slices=SLICES,
                  backlash=BACKLASH, profile_shift=ps_s1,
                  anchor=CENTER);

        // RING1 internal — herringbone -H
        // Ring body extends to EXT_GFW for ext tooth base
        if (SHOW_RINGS)
        color(C_RING)
        rotate([0, 0, ring1_a])
        ring_gear(mod=MOD, teeth=R1_T, thickness=EXT_GFW,
                  backing=RING_WALL, pressure_angle=PA,
                  helical=-H, herringbone=HERRING, slices=SLICES,
                  backlash=BACKLASH, anchor=CENTER);

        // RING1 EXTERNAL HERRINGBONE TEETH — +H_EXT
        if (SHOW_EXT_TEETH)
        color(C_EXT)
        rotate([0, 0, ring1_a])
        ext_ring_gear(EXT_T_CLEAN, EXT_GFW);

        // 3× PLANET1 — herringbone -H (opposite to sun)
        if (SHOW_PLANETS)
        rotate([0, 0, car1_a])
        for (i = [0:2])
            rotate([0, 0, i*120])
            translate([orb1, 0, 0]) {
                color(C_PLN1)
                rotate([0, 0, p1_self])
                spur_gear(mod=MOD, teeth=p1_t, thickness=GFW - TOL*2,
                          shaft_diam=PIN_D, pressure_angle=PA,
                          helical=-H, herringbone=HERRING, slices=SLICES,
                          backlash=BACKLASH, profile_shift=ps_p1,
                          anchor=CENTER);
            }
    }

    // ========== STAGE 2 ==========
    if (SHOW_STAGE2)
    translate([S2_LOCAL, 0, 0])
    rotate([0, 90, 0]) {
        // SUN2 — herringbone +H
        if (SHOW_SUNS)
        color(C_SUN2)
        rotate([0, 0, sun2_a])
        spur_gear(mod=MOD, teeth=s2_t, thickness=GFW,
                  shaft_diam=CPLG_OD, pressure_angle=PA,
                  helical=H, herringbone=HERRING, slices=SLICES,
                  backlash=BACKLASH, profile_shift=ps_s2,
                  anchor=CENTER);

        // RING2 internal — herringbone -H (inside enclosure)
        if (SHOW_RINGS)
        color(C_RING2)
        rotate([0, 0, ring2_a])
        ring_gear(mod=MOD, teeth=R2_T, thickness=EXT_GFW,
                  backing=RING_WALL, pressure_angle=PA,
                  helical=-H, herringbone=HERRING, slices=SLICES,
                  backlash=BACKLASH, anchor=CENTER);

        // RING2 EXTERNAL HERRINGBONE TEETH — +H_EXT
        if (SHOW_EXT_TEETH)
        color(C_EXT2)
        rotate([0, 0, ring2_a])
        ext_ring_gear(EXT_T_CLEAN, EXT_GFW);

        // 3× PLANET2 — herringbone -H
        if (SHOW_PLANETS)
        rotate([0, 0, car2_a])
        for (i = [0:2])
            rotate([0, 0, i*120 + 30])
            translate([orb2, 0, 0]) {
                color(C_PLN2)
                rotate([0, 0, p2_self])
                spur_gear(mod=MOD, teeth=p2_t, thickness=GFW - TOL*2,
                          shaft_diam=PIN_D, pressure_angle=PA,
                          helical=-H, herringbone=HERRING, slices=SLICES,
                          backlash=BACKLASH, profile_shift=ps_p2,
                          anchor=CENTER);
            }
    }

    // ========== PINIONS ==========
    // B-pinion — ABOVE Stage1 (follows SHOW_STAGE1)
    if (SHOW_STAGE1)
    translate([S1_LOCAL, B_DY, B_DZ])
    rotate([0, 90, 0]) {
        color(C_BPIN)
        rotate([0, 0, bpin_a])
        spur_gear(mod=EXT_MOD, teeth=BPIN_T, thickness=EXT_GFW,
                  shaft_diam=BC_SHAFT_D, pressure_angle=PA,
                  helical=-H_EXT, herringbone=HERRING, slices=SLICES,
                  backlash=BACKLASH, profile_shift=PS_BPIN,
                  anchor=CENTER);
    }

    // C-pinion — SIDE of Stage2 (follows SHOW_STAGE2)
    if (SHOW_STAGE2)
    translate([S2_LOCAL, C_DY, C_DZ])
    rotate([0, 90, 0]) {
        color(C_CPIN)
        rotate([0, 0, cpin_a])
        spur_gear(mod=EXT_MOD, teeth=BPIN_T, thickness=EXT_GFW,
                  shaft_diam=BC_SHAFT_D, pressure_angle=PA,
                  helical=-H_EXT, herringbone=HERRING, slices=SLICES,
                  backlash=BACKLASH, profile_shift=PS_BPIN,
                  anchor=CENTER);
    }

    // ========== CARRIERS + COUPLING ==========
    // --- Carrier 1 (follows SHOW_STAGE1) ---
    if (SHOW_STAGE1) {
        translate([S1_LOCAL, 0, 0])
        rotate([0, 90, 0])
        rotate([0, 0, car1_a]) {
            if (SHOW_CARRIER_PLATES)
            for (side = [-1, 1])
                translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
                color(C_CAR)
                difference() {
                    cylinder(r=orb1 + PIN_D + 1, h=CARRIER_T, center=true);
                    cylinder(d=CPLG_OD + TOL*2, h=CARRIER_T+1, center=true);
                    for (j = [0:2])
                        rotate([0, 0, j*120])
                        translate([orb1, 0, 0])
                        cylinder(d=PIN_D+TOL, h=CARRIER_T+1, center=true);
                }

            // Planet pins
            if (SHOW_PLANET_PINS)
            for (i = [0:2])
                rotate([0, 0, i*120])
                translate([orb1, 0, 0])
                color(C_PIN)
                cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + 1, center=true);

            // Bearing
            if (SHOW_BEARINGS)
            color(C_BRG) cylinder(d=6, h=3, center=true);

            // Coupling tube to Stage2 sun
            if (SHOW_COUPLING) {
                cplg_start = GFW/2 + CARRIER_T;
                cplg_len   = GAP + GFW/2;
                color(C_CPLG)
                translate([0, 0, cplg_start + cplg_len/2])
                difference() {
                    cylinder(d=CPLG_OD, h=cplg_len, center=true);
                    cylinder(d=CPLG_ID, h=cplg_len+1, center=true);
                }
            }
        }
    }  // end SHOW_STAGE1 carriers

    // --- Carrier 2 (output → drives spool) ---
    if (SHOW_STAGE2) {
        translate([S2_LOCAL, 0, 0])
        rotate([0, 90, 0])
        rotate([0, 0, car2_a]) {
            if (SHOW_CARRIER_PLATES)
            for (side = [-1, 1])
                translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
                color(C_CAR2)
                difference() {
                    cylinder(r=orb2 + PIN_D + 1, h=CARRIER_T, center=true);
                    cylinder(d=SHAFT_D + TOL*4, h=CARRIER_T+1, center=true);
                    for (j = [0:2])
                        rotate([0, 0, j*120 + 30])
                        translate([orb2, 0, 0])
                        cylinder(d=PIN_D+TOL, h=CARRIER_T+1, center=true);
                }

            if (SHOW_PLANET_PINS)
            for (i = [0:2])
                rotate([0, 0, i*120 + 30])
                translate([orb2, 0, 0])
                color(C_PIN)
                cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + 1, center=true);

            if (SHOW_BEARINGS)
            color(C_BRG) cylinder(d=6, h=3, center=true);
        }
    }  // end SHOW_STAGE2 carriers

    // ========== STAGE 2 ENCLOSURE (Ring2 rotation) ==========
    // Enclosure shell is part of Ring2 — rotates with C-shaft input.
    if (SHOW_ENCLOSURE)
    translate([S2_LOCAL, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, ring2_a]) {
        if (SHOW_ENCL_SHELL) {
            shell_len = ENCL_INWARD;
            shell_z   = -(EXT_GFW/2 + shell_len/2);
            color(C_RING2, 0.35)
            translate([0, 0, shell_z])
            difference() {
                cylinder(r=HOUSING_OR, h=shell_len, center=true);
                cylinder(r=HOUSING_OR - HOUSING_WALL, h=shell_len + 1, center=true);
                cylinder(d=SHAFT_D + TOL*4, h=shell_len + 2, center=true);
            }
        }
    }

    // ========== SPOOL (Carrier 2 rotation = OUTPUT) ==========
    // Spool drum is driven by Carrier 2 — the differential output.
    // This is what winds/unwinds the thread to raise/lower the pixel.
    if (SHOW_SPOOL)
    translate([S2_LOCAL, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, car2_a]) {
        drum_z = EXT_GFW/2 + SPOOL_GAP + SPOOL_DRUM_LEN/2;

        // Spool drum
        if (SHOW_SPOOL_DRUM)
        color(C_SPL)
        translate([0, 0, drum_z])
        difference() {
            cylinder(r=HOUSING_OR, h=SPOOL_DRUM_LEN, center=true);
            cylinder(r=HOUSING_OR - HOUSING_WALL, h=SPOOL_DRUM_LEN + 1, center=true);
        }

        // Flanges at spool ends
        if (SHOW_FLANGES)
        color(C_FLNG)
        for (fz = [drum_z - SPOOL_DRUM_LEN/2 - FLANGE_T/2,
                    drum_z + SPOOL_DRUM_LEN/2 + FLANGE_T/2])
            translate([0, 0, fz])
            difference() {
                cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
                cylinder(r=HOUSING_OR - HOUSING_WALL, h=FLANGE_T + 1, center=true);
            }

        // Thread groove visualization
        if (SHOW_GROOVE)
        color(C_THR)
        thread_groove_viz(HOUSING_OR, SPOOL_DRUM_LEN,
                          EXT_GFW/2 + SPOOL_GAP, THREAD_PITCH_MM, THREAD_GROOVE_W);
    }

    // ========== THREAD ==========
    if (SHOW_THREADS) {
        // Thread drops from the bottom of Ring2 housing
        spool_drop_z = -(HOUSING_OR);
        color(C_THR)
        translate([S2_LOCAL, 0, spool_drop_z - THREAD_LEN/2])
        cylinder(d=0.6, h=THREAD_LEN, center=true);
    }

    // ========== PIXEL ==========
    if (SHOW_PIXELS) {
        car2_a_out = node_car2_a(idx);
        pz = -(HOUSING_OR + THREAD_LEN + PIXEL_H/2);
        translate([S2_LOCAL, 0, pz]) {
            color(C_PIX)
            rotate([0, 0, car2_a_out * 0.05 + idx*30])
            cube([PIXEL_W, PIXEL_W, PIXEL_H], center=true);
            color(C_THR) translate([0, 0, PIXEL_H/2 + 0.5]) sphere(r=0.6);
        }
    }
}

// =============================================================
// EXTERNAL RING HERRINGBONE GEAR — EXT_MOD=1.5, H_EXT=30°
// Same tooth profile as pinions (which use helical=-H_EXT).
// =============================================================
module ext_ring_gear(teeth, gfw) {
    spur_gear(mod=EXT_MOD, teeth=teeth, thickness=gfw,
              shaft_diam=RING_INNER_R * 2,
              pressure_angle=PA, helical=H_EXT,
              herringbone=HERRING, slices=SLICES,
              backlash=BACKLASH, profile_shift=PS_EXT,
              anchor=CENTER);
}

// =============================================================
// THREAD GROOVE VISUALIZATION
// Helical groove on the housing surface where thread winds.
// Drawn as a series of small spheres tracing a helix path.
// Parameters:
//   r      = radius of housing surface
//   len    = total axial length of groove zone
//   z_start = axial start position
//   pitch  = helical pitch (mm per revolution)
//   width  = groove visual width
// =============================================================
module thread_groove_viz(r, len, z_start, pitch, width) {
    turns = len / pitch;
    steps = floor(turns * 24);  // 24 points per turn
    if (steps > 0)
    for (i = [0 : steps]) {
        frac = i / steps;
        a = frac * turns * 360;
        z = z_start + frac * len;
        translate([r * cos(a), r * sin(a), z])
        sphere(d=width, $fn=8);
    }
}
