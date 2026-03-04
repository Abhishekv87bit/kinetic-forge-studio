// =============================================================
// WAFFLE GRID — 5×5 MATRIX ASSEMBLY (V3 — Honest Architecture)
// Complete kinetic sculpture: frame, nodes, suspended blocks
//
// ARCHITECTURE (No Shortcuts — Every Part Physically Connected):
//   5×5 grid of compound planetary differential nodes
//   50mm pitch, all nodes identical gear ratios, MOD=1
//
//   NO HOUSING SHELL. The mechanism is "partially revealed"
//   (per physics spec). Gears are visible and exposed.
//
//   STRUCTURAL CHAIN:
//   Frame → shaft bearings → shafts → keyed/meshed components
//   Everything is held by gear mesh, shaft keys, or bearings.
//   Nothing floats. Every component has a physical connection.
//
// PHYSICAL CONNECTIONS (per node):
//   A-shaft: held by frame bearings at shaft ends
//     → Sun1: hex-keyed to A-shaft (locked rotation + axial)
//     → Carrier1: on needle bearings around A-shaft
//     → Carrier2: on needle bearings around A-shaft
//     → Coupling tube: press-fit into Carrier1, slides inside Sun2 bore
//   B-shaft: held by frame bearings
//     → B-pinion: keyed to B-shaft (rotates with it)
//     → meshes Ring1 ext teeth (holds Ring1 radially)
//   C-shaft: held by frame bearings
//     → C-pinion: keyed to C-shaft
//     → meshes Ring2 ext teeth (holds Ring2 radially)
//   Ring1: held radially by planet mesh + B-pinion mesh
//     → held axially by Carrier1 side plates (sandwiched)
//   Ring2: held radially by planet mesh + C-pinion mesh
//     → held axially by Carrier2 side plates (sandwiched)
//   Carrier2 → spool drum (integral part of Carrier2)
//     → thread wraps on spool drum OD
//     → thread exits tangentially, drops by gravity
//     → pixel block hangs on thread end
//   Between nodes: retaining clips on A-shaft prevent axial drift
//
// KINEMATIC CHAIN:
//   Motor A → A-shaft → Sun1 (hex keyed)
//   Motor B → B-shaft → B-pinion → Ring1 ext teeth → Ring1
//   Motor C → C-shaft → C-pinion → Ring2 ext teeth → Ring2
//   Sun1 ↔ Planet1 ↔ Ring1 → Carrier1 output
//   Carrier1 → coupling tube → Sun2
//   Sun2 ↔ Planet2 ↔ Ring2 → Carrier2 output
//   Carrier2 → spool drum → thread → pixel block
//
// Units: mm
// =============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

$fn = 36;
MANUAL_POSITION = 0.25;
POS = MANUAL_POSITION >= 0 ? MANUAL_POSITION : $t;

// ---- TOLERANCES ----
TOL      = 0.25;
BACKLASH = 0.1;

// ---- GEAR MODULES ----
// Internal planetary gears: MOD=1 (compact, fits inside ring)
MOD = 1.0;
PA  = 20;

// External drive pair: MOD=2 (bigger teeth, visually matches pinion)
// The external ring teeth and shaft pinions use EXT_MOD so they have
// the SAME chunky tooth profile as each other. This is a separate
// gear pair from the internal planetary — different module is valid.
EXT_MOD = 2.0;

// =============================================================
// STAGE 1 GEARS (internal planetary, MOD=1)
// =============================================================
S1_T = 13;  P1_T = 8;  R1_T = 29;
assert(S1_T + 2*P1_T == R1_T, "S1+2P1!=R1");

PS_S1 = auto_profile_shift(teeth=S1_T, pressure_angle=PA);
PS_P1 = auto_profile_shift(teeth=P1_T, pressure_angle=PA);
S1_PR = pitch_radius(mod=MOD, teeth=S1_T);
P1_PR = pitch_radius(mod=MOD, teeth=P1_T);
R1_PR = pitch_radius(mod=MOD, teeth=R1_T);
ORB1 = gear_dist(mod=MOD, teeth1=S1_T, teeth2=P1_T,
                 profile_shift1=PS_S1, profile_shift2=PS_P1);

// =============================================================
// STAGE 2 GEARS (internal planetary, MOD=1)
// =============================================================
S2_T = 11;  P2_T = 9;  R2_T = 29;
assert(S2_T + 2*P2_T == R2_T, "S2+2P2!=R2");

PS_S2 = auto_profile_shift(teeth=S2_T, pressure_angle=PA);
PS_P2 = auto_profile_shift(teeth=P2_T, pressure_angle=PA);
S2_PR = pitch_radius(mod=MOD, teeth=S2_T);
P2_PR = pitch_radius(mod=MOD, teeth=P2_T);
R2_PR = pitch_radius(mod=MOD, teeth=R2_T);
ORB2 = gear_dist(mod=MOD, teeth1=S2_T, teeth2=P2_T,
                 profile_shift1=PS_S2, profile_shift2=PS_P2);

// =============================================================
// RING BODY — shared between internal and external teeth
// =============================================================
RING_WALL = 3.0;
R1_RR = root_radius(mod=MOD, teeth=R1_T, internal=true);
RING_INNER_R = R1_RR + RING_WALL;   // ≈16.5mm outer surface of ring body

// =============================================================
// RING EXTERNAL TEETH (EXT_MOD = 2.0)
//
// Chunky, visible teeth that LOOK like the pinion teeth.
// Same EXT_MOD for both ext ring and pinion → identical tooth profile.
//
// Root must be above RING_INNER_R (ring body OD):
//   root = (T*EXT_MOD/2) - 1.25*EXT_MOD ≥ RING_INNER_R + 0.5
//   T ≥ 2*(RING_INNER_R + 0.5 + 1.25*EXT_MOD)/EXT_MOD
// =============================================================
EXT_T_RAW = ceil(2 * (RING_INNER_R + 0.5 + 1.25*EXT_MOD) / EXT_MOD);
EXT_T_CLEAN = EXT_T_RAW + (EXT_T_RAW % 2);  // round up to even
EXT_PR = pitch_radius(mod=EXT_MOD, teeth=EXT_T_CLEAN);
EXT_OR = outer_radius(mod=EXT_MOD, teeth=EXT_T_CLEAN);
EXT_RR = root_radius(mod=EXT_MOD, teeth=EXT_T_CLEAN);
PS_EXT = auto_profile_shift(teeth=EXT_T_CLEAN, pressure_angle=PA);

echo("EXT_T_CLEAN=", EXT_T_CLEAN, "EXT_PR=", EXT_PR, "EXT_OR=", EXT_OR,
     "EXT_RR=", EXT_RR, "RING_INNER_R=", RING_INNER_R);

assert(EXT_RR >= RING_INNER_R + 0.3,
       str("Ext gear root=", EXT_RR, " too close to ring body=", RING_INNER_R));
assert(EXT_OR * 2 <= 48,
       str("Ext gear OD=", EXT_OR*2, " too large for 50mm pitch"));

// =============================================================
// DRIVE PINIONS (B/C shafts) — SAME EXT_MOD as ring ext teeth
//
// Same module = same tooth height, same tooth width, same profile.
// The pinion and ring ext teeth look IDENTICAL in tooth shape.
// =============================================================
BPIN_T  = 6;
PS_BPIN = auto_profile_shift(teeth=BPIN_T, pressure_angle=PA);
BPIN_PR = pitch_radius(mod=EXT_MOD, teeth=BPIN_T);
BPIN_OR = outer_radius(mod=EXT_MOD, teeth=BPIN_T);
BPIN_RR = root_radius(mod=EXT_MOD, teeth=BPIN_T);

DRIVE_CD = gear_dist(mod=EXT_MOD, teeth1=EXT_T_CLEAN, teeth2=BPIN_T,
                     profile_shift1=PS_EXT, profile_shift2=PS_BPIN);

echo("BPIN_T=", BPIN_T, "BPIN_OR=", BPIN_OR, "DRIVE_CD=", DRIVE_CD);

// =============================================================
// SHAFT LAYOUT — 90° separation around the ring gear
//
// B-shaft: ABOVE the node (Y=0, Z=+DRIVE_CD) → pinion meshes ring at TOP
// C-shaft: SIDE of the node (Y=+DRIVE_CD, Z=0) → pinion meshes ring at SIDE
//
// This eliminates B/C shaft collision that occurred when both
// were side-by-side in the Y direction.
// 90° separation: B approaches vertically, C approaches horizontally.
// =============================================================
B_SHAFT_DY = 0;           // B-shaft: same Y as A-shaft
B_SHAFT_DZ = DRIVE_CD;    // B-shaft: ABOVE A-shaft
C_SHAFT_DY = DRIVE_CD;    // C-shaft: SIDE of A-shaft
C_SHAFT_DZ = 0;           // C-shaft: same Z as A-shaft

// =============================================================
// ENVELOPE & GRID
// =============================================================
GRID_PITCH = 50;
GRID_NX    = 5;
GRID_NY    = 5;

// C-shaft in Y must not collide with adjacent row's ring ext gear
// Nearest approach: GRID_PITCH - DRIVE_CD (C-shaft) - EXT_OR (adj ring)
C_SHAFT_TO_ADJ_RING = GRID_PITCH - DRIVE_CD - EXT_OR;
echo("C_SHAFT_TO_ADJ_RING=", C_SHAFT_TO_ADJ_RING);
assert(C_SHAFT_TO_ADJ_RING > 0,
       str("C-shaft collision with adj ring, gap=", C_SHAFT_TO_ADJ_RING));
// B-shaft is in Z, doesn't affect row spacing

// =============================================================
// PHYSICAL DIMENSIONS
// =============================================================
GFW        = 6;      // gear face width
EXT_GFW    = 5;      // external teeth face width
GAP        = 3;      // gap between stages (coupling zone)
CARRIER_T  = 2;      // carrier plate thickness
SHAFT_D    = 4;      // A-shaft hex diameter
BC_SHAFT_D = 3;      // B/C shaft diameter
CPLG_ID    = SHAFT_D + 0.5;  // coupling tube ID (clears A-shaft hex)
CPLG_OD    = 7;               // coupling tube OD
PIN_D      = 2;      // planet dowel pin diameter

BRG_OD = 8;  BRG_ID = 4;  BRG_W = 3;  // MR84 bearings
NEEDLE_OD = 6; NEEDLE_ID = SHAFT_D + TOL; NEEDLE_W = 3;  // carrier bearings on A-shaft

// =============================================================
// NODE STACK LAYOUT (per node, in local X)
// =============================================================
//
// Axial layout (X direction, local to node center):
//   [----Stage1----|--GAP--|----Stage2----|--SPOOL--]
//   [-STACK_LEFT                          +STACK_RIGHT+SPOOL]
//
S1_LOCAL    = -(GAP/2 + GFW/2);     // stage 1 center X = -4.5
S2_LOCAL    =  (GAP/2 + GFW/2);     // stage 2 center X = +4.5
STACK_HALF  = GFW/2 + CARRIER_T;    // 5mm
TOTAL_STACK = (GFW + CARRIER_T*2)*2 + GAP;  // 23mm
STACK_LEFT  = S1_LOCAL - STACK_HALF;         // -9.5
STACK_RIGHT = S2_LOCAL + STACK_HALF;         // +9.5

// =============================================================
// SPOOL DRUM — integral part of Carrier2
// Extends axially beyond Stage2, thread wraps on its surface
// Diameter = slightly larger than ring gear for thread clearance
// =============================================================
SPOOL_OD     = 22;     // spool drum outer diameter (thread wraps here)
SPOOL_WALL   = 2;      // drum wall thickness
SPOOL_ID     = SPOOL_OD - 2*SPOOL_WALL;
SPOOL_LEN    = 10;     // axial length of spool drum
SPOOL_GAP    = 1;      // gap between Stage2 carrier and spool start
SPOOL_START  = STACK_RIGHT + SPOOL_GAP;
SPOOL_CENTER = SPOOL_START + SPOOL_LEN/2;
FLANGE_R     = SPOOL_OD/2 + 2;  // thread guide flanges
FLANGE_T     = 1.0;

// Thread and pixel
THREAD_LEN = 70;
PIXEL_W    = 18;
PIXEL_H    = 3;

// Total node extent along X
NODE_X_MAX = SPOOL_START + SPOOL_LEN + FLANGE_T;
NODE_X_MIN = STACK_LEFT;
NODE_TOTAL_X = NODE_X_MAX - NODE_X_MIN;

// Check: node fits in grid pitch axially
assert(NODE_TOTAL_X < GRID_PITCH,
       str("Node X extent=", NODE_TOTAL_X, " > pitch=", GRID_PITCH));

// =============================================================
// RETAINING CLIPS on A-shaft (between nodes)
// =============================================================
CLIP_W = 1;
CLIP_OD = SHAFT_D + 2;

// =============================================================
// FRAME DIMENSIONS
// =============================================================
FRAME_BAR    = 8;
FRAME_MARGIN = 35;
LEG_HEIGHT   = 180;   // thread(70) + spool_r(11) + block(3) + FRAME_Z clearance
LEG_SECTION  = 10;

GRID_X_SPAN = (GRID_NX - 1) * GRID_PITCH;
GRID_Y_SPAN = (GRID_NY - 1) * GRID_PITCH;

FRAME_X_MIN = NODE_X_MIN - FRAME_MARGIN;
FRAME_X_MAX = GRID_X_SPAN + NODE_X_MAX + FRAME_MARGIN;
FRAME_Y_MIN = -FRAME_MARGIN;
// C-shaft extends to Y = last_row + DRIVE_CD, plus margin
FRAME_Y_MAX = GRID_Y_SPAN + DRIVE_CD + FRAME_MARGIN;
FRAME_X_LEN = FRAME_X_MAX - FRAME_X_MIN;
FRAME_Y_LEN = FRAME_Y_MAX - FRAME_Y_MIN;
FRAME_MX    = (FRAME_X_MIN + FRAME_X_MAX) / 2;
FRAME_MY    = (FRAME_Y_MIN + FRAME_Y_MAX) / 2;

// Frame Z: above B-shaft (highest point is B-shaft at Z=DRIVE_CD + pinion radius)
FRAME_Z = B_SHAFT_DZ + BPIN_OR + 8;

// Shaft lengths: extend past first/last node with margin
SHAFT_X_START = FRAME_X_MIN + FRAME_BAR + 2;
SHAFT_X_END   = FRAME_X_MAX - FRAME_BAR - 2;
SHAFT_LEN     = SHAFT_X_END - SHAFT_X_START;
SHAFT_X_MID   = (SHAFT_X_START + SHAFT_X_END) / 2;

// =============================================================
// KINEMATICS
// =============================================================
A_IN = POS * 360;
B_IN = POS * 360 * 1.13;
C_IN = POS * 360 * 0.87;

SUN1_A  = A_IN;
RING1_A = B_IN;
CAR1_A  = (SUN1_A*S1_T + RING1_A*R1_T) / (S1_T + R1_T);
SUN2_A  = CAR1_A;
RING2_A = C_IN;
CAR2_A  = (SUN2_A*S2_T + RING2_A*R2_T) / (S2_T + R2_T);
SPOOL_A = CAR2_A;

P1_SELF = -(CAR1_A - SUN1_A) * S1_T / P1_T;
P2_SELF = -(CAR2_A - SUN2_A) * S2_T / P2_T;
BPIN_A  = -RING1_A * EXT_T_CLEAN / BPIN_T;
CPIN_A  = -RING2_A * EXT_T_CLEAN / BPIN_T;

// =============================================================
// COLORS
// =============================================================
C_SUN   = [0.85, 0.25, 0.20];
C_SUN2  = [0.70, 0.20, 0.25];
C_RING  = [0.78, 0.72, 0.25];
C_RING2 = [0.68, 0.62, 0.25];
C_EXT   = [0.90, 0.80, 0.30];
C_EXT2  = [0.80, 0.70, 0.28];
C_PLN1  = [0.35, 0.72, 0.35];
C_PLN2  = [0.28, 0.60, 0.28];
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
C_BPIN  = [0.50, 0.80, 0.50];
C_CPIN  = [0.40, 0.50, 0.90];
C_BRG   = [0.45, 0.45, 0.50];
C_CLIP  = [0.55, 0.55, 0.58];
C_FRAME = [0.25, 0.25, 0.28];
C_LEG   = [0.30, 0.30, 0.32];

// =============================================================
// TOGGLES
// =============================================================
SHOW_FRAME     = true;
SHOW_SHAFTS    = true;
SHOW_GEARS     = true;    // internal gears (suns, planets, rings)
SHOW_CARRIERS  = true;    // carriers, coupling, spool drum
SHOW_PINIONS   = true;    // B/C drive pinions
SHOW_THREADS   = true;
SHOW_PIXELS    = true;
SHOW_CLIPS     = true;    // retaining clips between nodes
SHOW_BEARINGS  = true;    // shaft bearings at frame

SIMPLE_NODES   = false;

// Which row gets full detail (0-4). All other rows get ghost envelope.
// Set to -1 to show ALL rows with full detail.
DETAIL_ROW     = 0;

// =============================================================
// MAIN ASSEMBLY
// =============================================================
main();

module main() {
    if (SHOW_FRAME)    frame();
    if (SHOW_SHAFTS)   all_shafts();
    if (SHOW_CLIPS)    all_retaining_clips();
    if (SHOW_BEARINGS) all_shaft_bearings();

    for (col = [0 : GRID_NX-1])
        for (row = [0 : GRID_NY-1]) {
            nx = col * GRID_PITCH;
            ny = row * GRID_PITCH;
            translate([nx, ny, 0])
            if (DETAIL_ROW < 0 || row == DETAIL_ROW)
                node_assy(row, col);
            else
                ghost_node();
        }
}

// =============================================================
// GHOST NODE — envelope only (for spacing check on non-detail rows)
// Shows grid position without heavy gear geometry
// =============================================================
module ghost_node() {
    // Ring envelope cylinders (semi-transparent)
    for (sx = [S1_LOCAL, S2_LOCAL])
        translate([sx, 0, 0])
        rotate([0, 90, 0])
        color([0.6, 0.6, 0.4, 0.25])
        cylinder(r=EXT_OR, h=GFW + CARRIER_T*2, center=true);

    // Spool envelope
    translate([SPOOL_CENTER, 0, 0])
    rotate([0, 90, 0])
    color([0.5, 0.35, 0.2, 0.25])
    cylinder(d=SPOOL_OD, h=SPOOL_LEN, center=true);

    // Thread + pixel (always show for visual)
    if (SHOW_THREADS) node_thread();
    if (SHOW_PIXELS)  node_pixel();
}

// =============================================================
// SINGLE NODE
// =============================================================
module node_assy(row, col) {
    if (SIMPLE_NODES) {
        simple_node();
    } else {
        if (SHOW_GEARS)    node_stage1();
        if (SHOW_GEARS)    node_stage2();
        if (SHOW_CARRIERS) node_carriers();
        if (SHOW_PINIONS)  node_pinions();
        if (SHOW_THREADS)  node_thread();
        if (SHOW_PIXELS)   node_pixel();
    }
}

// =============================================================
// SIMPLIFIED NODE (for fast preview)
// =============================================================
module simple_node() {
    // Ring bodies (exposed, no housing)
    for (sx = [S1_LOCAL, S2_LOCAL])
        translate([sx, 0, 0])
        rotate([0, 90, 0]) {
            color(C_RING) cylinder(r=RING_INNER_R, h=GFW, center=true);
        }
    // Spool drum
    translate([SPOOL_CENTER, 0, 0])
    rotate([0, 90, 0]) {
        color(C_SPL) cylinder(d=SPOOL_OD, h=SPOOL_LEN, center=true);
        color(C_FLNG)
        for (sz = [-1, 1])
            translate([0, 0, sz*(SPOOL_LEN/2 + FLANGE_T/2)])
            cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
    }
    // Thread
    color(C_THR)
    translate([SPOOL_CENTER, 0, -(SPOOL_OD/2 + THREAD_LEN/2)])
    cylinder(d=0.6, h=THREAD_LEN, center=true);
    // Pixel
    pz = -(SPOOL_OD/2 + THREAD_LEN + PIXEL_H/2);
    translate([SPOOL_CENTER, 0, pz])
    color(C_PIX) cube([PIXEL_W, PIXEL_W, PIXEL_H], center=true);
}

// =============================================================
// NODE STAGE 1 — Sun1 + Ring1 + 3×Planet1 + Ring1 ext teeth
// =============================================================
module node_stage1() {
    translate([S1_LOCAL, 0, 0])
    rotate([0, 90, 0]) {
        // SUN1 — hex-keyed to A-shaft
        color(C_SUN)
        rotate([0, 0, SUN1_A])
        spur_gear(mod=MOD, teeth=S1_T, thickness=GFW,
                  shaft_diam=SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_S1,
                  anchor=CENTER);

        // RING1 — internal teeth, with backing wall
        // Held radially by planet mesh + ext teeth mesh with B-pinion
        // Held axially by Carrier1 side plates (sandwiched)
        color(C_RING)
        rotate([0, 0, RING1_A])
        ring_gear(mod=MOD, teeth=R1_T, thickness=GFW,
                  backing=RING_WALL, pressure_angle=PA,
                  backlash=BACKLASH, anchor=CENTER);

        // RING1 EXTERNAL TEETH — mesh with B-pinion
        color(C_EXT)
        rotate([0, 0, RING1_A])
        ext_ring_gear(EXT_T_CLEAN, EXT_GFW);

        // 3× PLANET1 — on dowel pins in Carrier1
        rotate([0, 0, CAR1_A])
        for (i = [0:2])
            rotate([0, 0, i*120])
            translate([ORB1, 0, 0]) {
                color(C_PLN1)
                rotate([0, 0, P1_SELF])
                spur_gear(mod=MOD, teeth=P1_T, thickness=GFW - TOL*2,
                          shaft_diam=PIN_D, pressure_angle=PA,
                          backlash=BACKLASH, profile_shift=PS_P1,
                          anchor=CENTER);
            }
    }
}

// =============================================================
// NODE STAGE 2 — Sun2 + Ring2 + 3×Planet2 + Ring2 ext teeth
// =============================================================
module node_stage2() {
    translate([S2_LOCAL, 0, 0])
    rotate([0, 90, 0]) {
        // SUN2 — keyed to coupling tube (not directly to A-shaft)
        color(C_SUN2)
        rotate([0, 0, SUN2_A])
        spur_gear(mod=MOD, teeth=S2_T, thickness=GFW,
                  shaft_diam=CPLG_OD, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_S2,
                  anchor=CENTER);

        // RING2 — internal teeth
        color(C_RING2)
        rotate([0, 0, RING2_A])
        ring_gear(mod=MOD, teeth=R2_T, thickness=GFW,
                  backing=RING_WALL, pressure_angle=PA,
                  backlash=BACKLASH, anchor=CENTER);

        // RING2 EXTERNAL TEETH — mesh with C-pinion
        color(C_EXT2)
        rotate([0, 0, RING2_A])
        ext_ring_gear(EXT_T_CLEAN, EXT_GFW);

        // 3× PLANET2
        rotate([0, 0, CAR2_A])
        for (i = [0:2])
            rotate([0, 0, i*120 + 30])
            translate([ORB2, 0, 0]) {
                color(C_PLN2)
                rotate([0, 0, P2_SELF])
                spur_gear(mod=MOD, teeth=P2_T, thickness=GFW - TOL*2,
                          shaft_diam=PIN_D, pressure_angle=PA,
                          backlash=BACKLASH, profile_shift=PS_P2,
                          anchor=CENTER);
            }
    }
}

// =============================================================
// NODE CARRIERS + COUPLING + SPOOL DRUM
//
// Carrier1: two plates sandwiching Stage1 planets+ring
//   → bearings on A-shaft (needle bearings)
//   → coupling tube extends from right plate through GAP to Sun2
//
// Carrier2: two plates sandwiching Stage2 planets+ring
//   → bearings on A-shaft
//   → SPOOL DRUM extends axially from right plate
//   → thread wraps on spool drum OD
// =============================================================
module node_carriers() {
    // ======== CARRIER 1 ========
    translate([S1_LOCAL, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR1_A]) {
        // Two carrier plates (sandwich ring + planets)
        for (side = [-1, 1])
            translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
            color(C_CAR)
            difference() {
                cylinder(r=ORB1 + PIN_D + 1, h=CARRIER_T, center=true);
                // Bore: clears coupling tube OD (A-shaft runs inside coupling)
                cylinder(d=CPLG_OD + TOL*2, h=CARRIER_T+1, center=true);
                // Planet pin holes
                for (j = [0:2])
                    rotate([0, 0, j*120])
                    translate([ORB1, 0, 0])
                    cylinder(d=PIN_D+TOL, h=CARRIER_T+1, center=true);
            }

        // Planet dowel pins (through both plates)
        for (i = [0:2])
            rotate([0, 0, i*120])
            translate([ORB1, 0, 0])
            color(C_PIN)
            cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + 1, center=true);

        // Needle bearing on A-shaft (inside coupling tube bore)
        color(C_BRG)
        cylinder(d=NEEDLE_OD, h=NEEDLE_W, center=true);

        // COUPLING TUBE — hollow tube, press-fit into right carrier plate
        // Extends through GAP, engages Sun2 bore
        cplg_start = GFW/2 + CARRIER_T;
        cplg_len   = GAP + GFW/2;
        color(C_CPLG)
        translate([0, 0, cplg_start + cplg_len/2])
        difference() {
            cylinder(d=CPLG_OD, h=cplg_len, center=true);
            cylinder(d=CPLG_ID, h=cplg_len+1, center=true);
        }
    }

    // ======== CARRIER 2 + SPOOL DRUM ========
    translate([S2_LOCAL, 0, 0])
    rotate([0, 90, 0])
    rotate([0, 0, CAR2_A]) {
        // Two carrier plates
        for (side = [-1, 1])
            translate([0, 0, side*(GFW/2 + CARRIER_T/2)])
            color(C_CAR2)
            difference() {
                cylinder(r=ORB2 + PIN_D + 1, h=CARRIER_T, center=true);
                // Bore: clears A-shaft (no coupling tube here)
                cylinder(d=SHAFT_D + TOL*4, h=CARRIER_T+1, center=true);
                for (j = [0:2])
                    rotate([0, 0, j*120 + 30])
                    translate([ORB2, 0, 0])
                    cylinder(d=PIN_D+TOL, h=CARRIER_T+1, center=true);
            }

        // Planet dowel pins
        for (i = [0:2])
            rotate([0, 0, i*120 + 30])
            translate([ORB2, 0, 0])
            color(C_PIN)
            cylinder(d=PIN_D, h=GFW + CARRIER_T*2 + 1, center=true);

        // Needle bearing on A-shaft
        color(C_BRG)
        cylinder(d=NEEDLE_OD, h=NEEDLE_W, center=true);

        // SPOOL DRUM — cylindrical drum extending from right carrier plate
        // This IS the spool. Thread wraps on its outer surface.
        spool_z = GFW/2 + CARRIER_T + SPOOL_GAP + SPOOL_LEN/2;
        color(C_SPL)
        translate([0, 0, spool_z])
        difference() {
            cylinder(d=SPOOL_OD, h=SPOOL_LEN, center=true);
            // Bore for A-shaft to pass through
            cylinder(d=SHAFT_D + TOL*4, h=SPOOL_LEN + 1, center=true);
        }

        // Spool flanges (thread guides)
        color(C_FLNG)
        for (fz = [spool_z - SPOOL_LEN/2 - FLANGE_T/2,
                   spool_z + SPOOL_LEN/2 + FLANGE_T/2])
            translate([0, 0, fz])
            difference() {
                cylinder(r=FLANGE_R, h=FLANGE_T, center=true);
                cylinder(d=SHAFT_D + TOL*4, h=FLANGE_T + 1, center=true);
            }

        // Connecting web: carrier plate → spool drum
        // (structural arm from carrier plate edge to spool inner wall)
        web_start = GFW/2 + CARRIER_T/2;
        web_end = spool_z - SPOOL_LEN/2;
        web_len = web_end - web_start;
        for (a = [0:2])
            rotate([0, 0, a*120 + 15])
            color(C_CAR2)
            translate([(SHAFT_D/2 + TOL + SPOOL_ID/2)/2, 0, web_start + web_len/2])
            cube([SPOOL_ID/2 - SHAFT_D/2 - TOL, 2, web_len], center=true);
    }
}

// =============================================================
// NODE PINIONS — keyed to B/C shafts, mesh with ring ext teeth
//
// B-pinion at TOP of ring (Z=+DRIVE_CD) — meshes Stage1 ext teeth
// C-pinion at SIDE of ring (Y=+DRIVE_CD) — meshes Stage2 ext teeth
//
// BOTH use EXT_MOD (same as ring ext teeth) → identical tooth profile.
// =============================================================
module node_pinions() {
    // B-pinion at Stage1 — ABOVE ring (Z = +DRIVE_CD)
    translate([S1_LOCAL, B_SHAFT_DY, B_SHAFT_DZ])
    rotate([0, 90, 0]) {
        color(C_BPIN)
        rotate([0, 0, BPIN_A])
        spur_gear(mod=EXT_MOD, teeth=BPIN_T, thickness=EXT_GFW,
                  shaft_diam=BC_SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_BPIN,
                  anchor=CENTER);
    }

    // C-pinion at Stage2 — SIDE of ring (Y = +DRIVE_CD)
    translate([S2_LOCAL, C_SHAFT_DY, C_SHAFT_DZ])
    rotate([0, 90, 0]) {
        color(C_CPIN)
        rotate([0, 0, CPIN_A])
        spur_gear(mod=EXT_MOD, teeth=BPIN_T, thickness=EXT_GFW,
                  shaft_diam=BC_SHAFT_D, pressure_angle=PA,
                  backlash=BACKLASH, profile_shift=PS_BPIN,
                  anchor=CENTER);
    }
}

// =============================================================
// NODE THREAD — from spool drum bottom, drops by gravity
// =============================================================
module node_thread() {
    // Thread exits tangentially from spool drum bottom
    spool_drop_z = -(SPOOL_OD/2);
    color(C_THR)
    translate([SPOOL_CENTER, 0, spool_drop_z - THREAD_LEN/2])
    cylinder(d=0.6, h=THREAD_LEN, center=true);
}

// =============================================================
// NODE PIXEL — suspended wood block at thread end
// =============================================================
module node_pixel() {
    pz = -(SPOOL_OD/2 + THREAD_LEN + PIXEL_H/2);
    translate([SPOOL_CENTER, 0, pz]) {
        color(C_PIX) rotate([0, 0, SPOOL_A * 0.05 + 15])
        cube([PIXEL_W, PIXEL_W, PIXEL_H], center=true);
        // Thread knot on top
        color(C_THR) translate([0, 0, PIXEL_H/2 + 0.5]) sphere(r=0.6);
    }
}

// =============================================================
// EXTERNAL RING GEAR MODULE (BOSL2)
//
// Uses EXT_MOD (= 2.0) — SAME module as the B/C pinions.
// Same EXT_MOD, same PA, same BOSL2 spur_gear() function.
// RESULT: ext teeth are IDENTICAL in size/shape to pinion teeth.
//
// shaft_diam = 2*RING_INNER_R cuts a bore at the ring body OD.
// =============================================================
module ext_ring_gear(teeth, gfw) {
    spur_gear(mod=EXT_MOD, teeth=teeth, thickness=gfw,
              shaft_diam=RING_INNER_R * 2,
              pressure_angle=PA, backlash=BACKLASH,
              profile_shift=PS_EXT, anchor=CENTER);
}

// =============================================================
// ALL SHAFTS — 5 rows × 3 shafts = 15 shafts total
//
// Layout (per row, looking from front along X axis):
//         B-shaft (green)    ← Z = +DRIVE_CD (above)
//            |
//   A-shaft (red) ———— C-shaft (blue)   ← Y = +DRIVE_CD (side)
//            |
//        [thread drops down]
// =============================================================
module all_shafts() {
    for (row = [0 : GRID_NY-1]) {
        ry = row * GRID_PITCH;

        // A-shaft (hex, center of row) — Y=ry, Z=0
        color(C_SHA)
        translate([SHAFT_X_MID, ry, 0])
        rotate([0, 90, 0])
        rotate([0, 0, SUN1_A])
        cylinder(d=SHAFT_D, h=SHAFT_LEN, center=true, $fn=6);

        // B-shaft — ABOVE A-shaft: Y=ry, Z=+DRIVE_CD
        color(C_SHB)
        translate([SHAFT_X_MID, ry + B_SHAFT_DY, B_SHAFT_DZ])
        rotate([0, 90, 0])
        rotate([0, 0, B_IN])
        cylinder(d=BC_SHAFT_D, h=SHAFT_LEN, center=true);

        // C-shaft — SIDE of A-shaft: Y=ry+DRIVE_CD, Z=0
        color(C_SHC)
        translate([SHAFT_X_MID, ry + C_SHAFT_DY, C_SHAFT_DZ])
        rotate([0, 90, 0])
        rotate([0, 0, C_IN])
        cylinder(d=BC_SHAFT_D, h=SHAFT_LEN, center=true);
    }
}

// =============================================================
// RETAINING CLIPS — on A-shaft between and outside nodes
// Prevent axial drift of carrier assemblies along A-shaft
// =============================================================
module all_retaining_clips() {
    for (row = [0 : GRID_NY-1]) {
        ry = row * GRID_PITCH;
        for (col = [0 : GRID_NX-1]) {
            nx = col * GRID_PITCH;
            // Clip before node (left side)
            color(C_CLIP)
            translate([nx + NODE_X_MIN - CLIP_W/2 - 0.5, ry, 0])
            rotate([0, 90, 0])
            difference() {
                cylinder(d=CLIP_OD, h=CLIP_W, center=true);
                cylinder(d=SHAFT_D + TOL, h=CLIP_W+1, center=true);
            }
            // Clip after node (right side, past spool)
            color(C_CLIP)
            translate([nx + NODE_X_MAX + CLIP_W/2 + 0.5, ry, 0])
            rotate([0, 90, 0])
            difference() {
                cylinder(d=CLIP_OD, h=CLIP_W, center=true);
                cylinder(d=SHAFT_D + TOL, h=CLIP_W+1, center=true);
            }
        }
    }
}

// =============================================================
// SHAFT BEARINGS — at frame ends, supporting each shaft
// =============================================================
module all_shaft_bearings() {
    for (row = [0 : GRID_NY-1]) {
        ry = row * GRID_PITCH;
        for (end_x = [SHAFT_X_START + BRG_W/2, SHAFT_X_END - BRG_W/2]) {
            // A-shaft bearing
            translate([end_x, ry, 0])
            rotate([0, 90, 0])
            brg(BRG_OD, BRG_ID, BRG_W);

            // B-shaft bearing — ABOVE
            translate([end_x, ry + B_SHAFT_DY, B_SHAFT_DZ])
            rotate([0, 90, 0])
            brg(BRG_OD, BC_SHAFT_D, BRG_W);

            // C-shaft bearing — SIDE
            translate([end_x, ry + C_SHAFT_DY, C_SHAFT_DZ])
            rotate([0, 90, 0])
            brg(BRG_OD, BC_SHAFT_D, BRG_W);
        }
    }
}

// =============================================================
// FRAME
// =============================================================
module frame() {
    fz = FRAME_Z;

    // ==== PERIMETER RAILS ====
    // Front
    color(C_FRAME)
    translate([FRAME_MX, FRAME_Y_MIN, fz])
    cube([FRAME_X_LEN, FRAME_BAR, FRAME_BAR], center=true);
    // Back
    color(C_FRAME)
    translate([FRAME_MX, FRAME_Y_MAX, fz])
    cube([FRAME_X_LEN, FRAME_BAR, FRAME_BAR], center=true);
    // Left
    color(C_FRAME)
    translate([FRAME_X_MIN, FRAME_MY, fz])
    cube([FRAME_BAR, FRAME_Y_LEN + FRAME_BAR*2, FRAME_BAR], center=true);
    // Right
    color(C_FRAME)
    translate([FRAME_X_MAX, FRAME_MY, fz])
    cube([FRAME_BAR, FRAME_Y_LEN + FRAME_BAR*2, FRAME_BAR], center=true);

    // ==== CROSS-BARS at each row (Y positions) ====
    for (row = [0 : GRID_NY-1]) {
        ry = row * GRID_PITCH;
        color([0.30, 0.30, 0.33])
        translate([FRAME_MX, ry, fz])
        cube([FRAME_X_LEN, FRAME_BAR*0.6, FRAME_BAR], center=true);
    }

    // ==== VERTICAL BEARING DROPS ====
    // Connect frame cross-bars down to shaft level
    for (row = [0 : GRID_NY-1]) {
        ry = row * GRID_PITCH;
        for (end_x = [SHAFT_X_START, SHAFT_X_END]) {
            // A-shaft drop (Z=0)
            color([0.32, 0.32, 0.35])
            translate([end_x, ry, fz/2])
            cube([FRAME_BAR*0.4, FRAME_BAR*0.4, fz], center=true);

            // B-shaft drop (Z=+DRIVE_CD, short drop from frame)
            b_drop_h = fz - B_SHAFT_DZ;
            color([0.32, 0.32, 0.35])
            translate([end_x, ry + B_SHAFT_DY, B_SHAFT_DZ + b_drop_h/2])
            cube([FRAME_BAR*0.3, FRAME_BAR*0.3, b_drop_h], center=true);

            // C-shaft drop (Y=+DRIVE_CD, Z=0)
            color([0.32, 0.32, 0.35])
            translate([end_x, ry + C_SHAFT_DY, fz/2])
            cube([FRAME_BAR*0.3, FRAME_BAR*0.3, fz], center=true);
        }
    }

    // ==== 4 LEGS ====
    leg_pos = [
        [FRAME_X_MIN, FRAME_Y_MIN],
        [FRAME_X_MAX, FRAME_Y_MIN],
        [FRAME_X_MIN, FRAME_Y_MAX],
        [FRAME_X_MAX, FRAME_Y_MAX]
    ];
    for (lp = leg_pos)
        color(C_LEG)
        translate([lp[0], lp[1], fz - LEG_HEIGHT/2 - FRAME_BAR/2])
        cube([LEG_SECTION, LEG_SECTION, LEG_HEIGHT], center=true);
}

// =============================================================
// BEARING (utility)
// =============================================================
module brg(od, id, w) {
    color(C_BRG) difference() {
        cylinder(d=od, h=w, center=true);
        cylinder(d=id, h=w+1, center=true);
    }
}
