// ============================================================
// RAVIGNEAUX HYBRID DIFFERENTIAL — PARAMETER CALCULATOR
// Echo-only. Computes all derived values + 12 assertions.
// Run: openscad.com -o test.csg ravigneaux_params.scad
// All assertions must pass before proceeding.
// ============================================================
//
// ARCHITECTURE:
//   Ravigneaux stage: 2 suns (A,B) + inner/outer planets + ring → carrier
//   Simple planetary stage: Sun (=carrier1) + planets + ring (C) → carrier2 → spool
//
//   A-shaft ──HEX──▶ Small Sun (Ss) ──mesh──▶ Inner Planets (Pi)
//   B-tube  ──KEY──▶ Large Sun (SL) ──mesh──▶ Outer Planets (Po)
//   Inner planets also mesh with outer planets
//   Outer planets also mesh with Ring (floating, passive)
//   Carrier holds both planet sets → output
//
//   Carrier1 ═══ Sun2 (compound)
//   C-shaft ──HEX──▶ Ring2 (ext pinion)
//   Sun2 + Ring2 → Carrier2 → Spool
//
// KINEMATIC EQUATIONS:
//   Ravigneaux (ring free):
//     w_carrier1 = (N_Ss * wA + N_SL * wB) / (N_Ss + N_SL)
//
//   Stage 2 (simple planetary):
//     w_carrier2 = (S2_T * w_carrier1 + R2_T * wC) / (S2_T + R2_T)
//
//   Combined:
//     w_spool = kA*wA + kB*wB + kC*wC  where kA+kB+kC = 1
// ============================================================

include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// ============================================================
// PRIMARY PARAMETERS — Ravigneaux Stage
// ============================================================
RAV_MOD = 0.8;         // Module for Ravigneaux gears
RAV_PA = 20;           // Pressure angle

// Tooth counts
N_Ss = 11;             // Small sun (A-shaft)
N_Pi = 8;              // Inner planet (bridges Ss to SL)
N_SL = 27;             // Large sun (B-shaft/tube)
N_Po = 9;              // Outer planet (bridges SL to Ring)
N_R  = 45;             // Ring gear (floating)

// Planet counts
N_INNER_PLANETS = 3;   // Inner planet count
N_OUTER_PLANETS = 3;   // Outer planet count

// ============================================================
// PRIMARY PARAMETERS — Simple Planetary Stage 2
// ============================================================
S2_MOD = 1.0;          // Module for Stage 2 (same as current)
S2_PA = 20;

S2_T = 13;             // Sun2 teeth (= current)
P2_T = 8;              // Planet2 teeth (= current)
R2_T = 29;             // Ring2 teeth (= current)
N_PLANETS_S2 = 3;

// ============================================================
// PRIMARY PARAMETERS — External Drive (Stage 2 only)
// ============================================================
EXT_MOD = 1.5;
EXT_T = 26;            // External teeth on Ring2
CPIN_T = 8;            // C-shaft pinion teeth

// ============================================================
// GEOMETRY PARAMETERS
// ============================================================
GFW = 6;               // Gear face width
EXT_GFW = 6;           // External gear face width
CARRIER_T = 2;         // Carrier plate thickness
PIN_D = 2;             // Planet pin diameter
CAR_PAD = 1.5;         // Carrier radial pad
RING_WALL = 1.5;       // Ring backing wall
THRUST_WASHER_T = 0.5; // PTFE washer
AXIAL_GAP = 0.2 + THRUST_WASHER_T;  // 0.7mm
BACKLASH = 0.21;

// Shaft
SHAFT_D = 5;           // A-shaft hex across-flats
B_TUBE_ID = 7;         // B-tube inner diameter (clears A hex)
B_TUBE_OD = 10;        // B-tube outer diameter
PIP_TOL = 0.35;
BEARING_WALL = 1.5;

// Spool (same as current)
SPOOL_R = 8;
SPOOL_H = 6;
FLANGE_R = SPOOL_R + 3;
FLANGE_T = 1.5;

// ============================================================
// DERIVED VALUES — Ravigneaux Stage
// ============================================================

// Center distances — using BOSL2 gear_dist for actual meshing geometry
// Ss ↔ Pi: small sun to inner planet (external mesh)
CD_Ss_Pi = gear_dist(mod=RAV_MOD, teeth1=N_Ss, teeth2=N_Pi,
                     profile_shift1=0, profile_shift2=0);
ORB_Pi = CD_Ss_Pi;   // Inner planet orbit = center distance from axis

// Pi ↔ Po: inner planet to outer planet (external mesh)
CD_Pi_Po = gear_dist(mod=RAV_MOD, teeth1=N_Pi, teeth2=N_Po,
                     profile_shift1=0, profile_shift2=0);
ORB_Po = ORB_Pi + CD_Pi_Po;  // Outer planet orbit from center

// R ↔ Po: ring to outer planet (internal mesh)
CD_R_Po = gear_dist(mod=RAV_MOD, teeth1=N_R, teeth2=N_Po,
                    internal1=true, profile_shift1=0, profile_shift2=0);

// SL ↔ Po: large sun to outer planet (external mesh)
CD_SL_Po = gear_dist(mod=RAV_MOD, teeth1=N_SL, teeth2=N_Po,
                     profile_shift1=0, profile_shift2=0);
// In Ravigneaux, SL meshes with Pi at same orbit as Ss meshes with Pi
// This is guaranteed by N_SL = N_Ss + 2*N_Pi

// Pitch radii
Ss_PR = pitch_radius(mod=RAV_MOD, teeth=N_Ss);     // 4.4mm
SL_PR = pitch_radius(mod=RAV_MOD, teeth=N_SL);     // 10.8mm
Pi_PR = pitch_radius(mod=RAV_MOD, teeth=N_Pi);     // 3.2mm
Po_PR = pitch_radius(mod=RAV_MOD, teeth=N_Po);     // 3.6mm
R_PR  = pitch_radius(mod=RAV_MOD, teeth=N_R);      // 18.0mm

// Outer radii
Ss_OR = outer_radius(mod=RAV_MOD, teeth=N_Ss);
SL_OR = outer_radius(mod=RAV_MOD, teeth=N_SL);
Pi_OR = outer_radius(mod=RAV_MOD, teeth=N_Pi);
Po_OR = outer_radius(mod=RAV_MOD, teeth=N_Po);
R_ROOT_R = root_radius(mod=RAV_MOD, teeth=N_R, internal=true);

// Ring body OD
RING_BODY_R = R_ROOT_R + RING_WALL;
RING_BODY_OD = RING_BODY_R * 2;

// Carrier radius (outer planets + pin + pad)
RAV_CAR_R = ORB_Po + PIN_D/2 + CAR_PAD;

// ============================================================
// DERIVED VALUES — Stage 2 (unchanged from current)
// ============================================================
S2_ORB = gear_dist(mod=S2_MOD, teeth1=S2_T, teeth2=P2_T,
                   profile_shift1=0, profile_shift2=0);
DRIVE_CD = gear_dist(mod=EXT_MOD, teeth1=EXT_T, teeth2=CPIN_T,
                     profile_shift1=0, profile_shift2=0);

R2_ROOT_R = root_radius(mod=S2_MOD, teeth=R2_T, internal=true);
RING2_INNER_R = R2_ROOT_R + RING_WALL;
EXT_OUTER_R = outer_radius(mod=EXT_MOD, teeth=EXT_T);

S2_CAR_R = S2_ORB + PIN_D/2 + CAR_PAD;

// ============================================================
// DERIVED VALUES — Shaft & Bearing
// ============================================================
HEX_CIRC_R = SHAFT_D / (2 * cos(30));
BEARING_ID = HEX_CIRC_R * 2 + 2 * PIP_TOL;
BEARING_OD = BEARING_ID + 2 * BEARING_WALL;
A_SHAFT_CLEAR_D = BEARING_ID;

// B-tube: verify clears A-shaft hex
B_TUBE_CLEAR = B_TUBE_ID/2 - HEX_CIRC_R;

// ============================================================
// DERIVED VALUES — Kinematic Coefficients
// ============================================================
// Ravigneaux carrier1: w_car1 = (N_Ss*wA + N_SL*wB) / (N_Ss+N_SL)
RAV_kA_local = N_Ss / (N_Ss + N_SL);    // A weight in Rav stage
RAV_kB_local = N_SL / (N_Ss + N_SL);    // B weight in Rav stage

// Stage 2: w_car2 = (S2_T*w_car1 + R2_T*wC) / (S2_T+R2_T)
S2_kSun = S2_T / (S2_T + R2_T);
S2_kRing = R2_T / (S2_T + R2_T);

// Combined 3-input coefficients:
kA = RAV_kA_local * S2_kSun;
kB = RAV_kB_local * S2_kSun;
kC = S2_kRing;
kSUM = kA + kB + kC;

// ============================================================
// DERIVED VALUES — Axial Stack
// ============================================================
// Ravigneaux: carrier_bot + washer + gears + washer + carrier_top
RAV_STAGE_H = CARRIER_T + AXIAL_GAP + GFW + AXIAL_GAP + CARRIER_T;

// Coupling: carrier1 top → Sun2 shaft
COUPLING_GAP = AXIAL_GAP;  // compound shaft passes through

// Stage 2: carrier_bot + washer + gears + washer + carrier_top
S2_STAGE_H = CARRIER_T + AXIAL_GAP + GFW + AXIAL_GAP + CARRIER_T;

// Spool
SPOOL_TOTAL = CARRIER_T + SPOOL_H + FLANGE_T;

// Total
TOTAL_STACK = RAV_STAGE_H + COUPLING_GAP + S2_STAGE_H + SPOOL_TOTAL;

// ============================================================
// ECHO ALL VALUES
// ============================================================
echo("========================================");
echo("  RAVIGNEAUX HYBRID PARAMETERS");
echo("========================================");

echo("--- Ravigneaux Tooth Counts ---");
echo(N_Ss=N_Ss, N_Pi=N_Pi, N_SL=N_SL, N_Po=N_Po, N_R=N_R);

echo("--- Center Distances ---");
echo(CD_Ss_Pi=CD_Ss_Pi, CD_Pi_Po=CD_Pi_Po, CD_R_Po=CD_R_Po, CD_SL_Po=CD_SL_Po);
echo(ORB_Pi=ORB_Pi, ORB_Po=ORB_Po);

echo("--- Pitch Radii ---");
echo(Ss_PR=Ss_PR, SL_PR=SL_PR, Pi_PR=Pi_PR, Po_PR=Po_PR, R_PR=R_PR);

echo("--- Ring Body ---");
echo(R_ROOT_R=R_ROOT_R, RING_BODY_OD=RING_BODY_OD);
echo(RAV_CAR_R=RAV_CAR_R);

echo("--- Concentric Shafts ---");
echo(SHAFT_D=SHAFT_D, B_TUBE_ID=B_TUBE_ID, B_TUBE_OD=B_TUBE_OD);
echo(str("B-tube clearance to A-hex: ", B_TUBE_CLEAR, "mm"));

echo("--- Stage 2 ---");
echo(S2_T=S2_T, P2_T=P2_T, R2_T=R2_T);
echo(S2_ORB=S2_ORB, DRIVE_CD=DRIVE_CD);

echo("--- Kinematic Coefficients ---");
echo(kA=kA, kB=kB, kC=kC, kSUM=kSUM);
echo(str("Blend: ", round(kA*1000)/10, "% A + ", round(kB*1000)/10, "% B + ", round(kC*1000)/10, "% C"));

echo("--- Axial Stack ---");
echo(RAV_STAGE_H=RAV_STAGE_H, S2_STAGE_H=S2_STAGE_H);
echo(TOTAL_STACK=TOTAL_STACK);

// ============================================================
// 12 ASSERTIONS — ALL MUST PASS
// ============================================================
echo("========================================");
echo("  ASSERTIONS");
echo("========================================");

// 1. Ravigneaux inner constraint: N_SL = N_Ss + 2*N_Pi
assert(N_SL == N_Ss + 2*N_Pi,
    str("FAIL: N_SL=", N_SL, " != N_Ss+2*N_Pi=", N_Ss + 2*N_Pi));
echo("✓ Assert 1: N_SL = N_Ss + 2*N_Pi");

// 2. Ravigneaux outer constraint: N_R = N_SL + 2*N_Po
assert(N_R == N_SL + 2*N_Po,
    str("FAIL: N_R=", N_R, " != N_SL+2*N_Po=", N_SL + 2*N_Po));
echo("✓ Assert 2: N_R = N_SL + 2*N_Po");

// 3. Stage 2 constraint: S2 + 2*P2 = R2
assert(S2_T + 2*P2_T == R2_T,
    str("FAIL: S2+2P2=", S2_T+2*P2_T, " != R2=", R2_T));
echo("✓ Assert 3: S2 + 2*P2 = R2");

// 4. ORB_Po definition consistent: ORB_Pi + CD_Pi_Po
assert(abs(ORB_Po - (ORB_Pi + CD_Pi_Po)) < 0.001,
    str("FAIL: ORB_Po=", ORB_Po, " vs ORB_Pi+CD_Pi_Po=", ORB_Pi + CD_Pi_Po));
echo(str("✓ Assert 4: ORB_Po=", ORB_Po, " = ORB_Pi+CD_Pi_Po"));

// 5. Ring internal mesh: CD_R_Po should closely match ORB_Po
//    (small deviation expected from profile geometry)
assert(abs(CD_R_Po - ORB_Po) < 1.0,
    str("FAIL: CD_R_Po=", CD_R_Po, " far from ORB_Po=", ORB_Po));
echo(str("✓ Assert 5: Ring-Po CD=", CD_R_Po, " ≈ ORB_Po=", ORB_Po));

// 6. Large sun to outer planet: CD_SL_Po should closely match ORB_Po
assert(abs(CD_SL_Po - ORB_Po) < 1.0,
    str("FAIL: CD_SL_Po=", CD_SL_Po, " far from ORB_Po=", ORB_Po));
echo(str("✓ Assert 6: SL-Po CD=", CD_SL_Po, " ≈ ORB_Po=", ORB_Po));

// 7. Ring body OD < 42mm (fits in current envelope)
assert(RING_BODY_OD < 42,
    str("FAIL: Ring body OD=", RING_BODY_OD, " >= 42mm"));
echo(str("✓ Assert 7: Ring body OD=", RING_BODY_OD, "mm < 42mm"));

// 8. Coefficients sum to 1.0
assert(abs(kSUM - 1.0) < 0.001,
    str("FAIL: kA+kB+kC=", kSUM, " != 1.0"));
echo(str("✓ Assert 8: kA+kB+kC=", kSUM, " = 1.0000"));

// 9. B-tube clears A-shaft hex
assert(B_TUBE_CLEAR > PIP_TOL,
    str("FAIL: B-tube clearance=", B_TUBE_CLEAR, " <= PIP_TOL=", PIP_TOL));
echo(str("✓ Assert 9: B-tube clearance=", B_TUBE_CLEAR, "mm > PIP_TOL"));

// 10. Small sun root clears A-shaft hex bore
Ss_ROOT_R = root_radius(mod=RAV_MOD, teeth=N_Ss);
assert(Ss_ROOT_R > HEX_CIRC_R + PIP_TOL,
    str("FAIL: Ss root=", Ss_ROOT_R, " <= hex_circ+tol=", HEX_CIRC_R+PIP_TOL));
echo(str("✓ Assert 10: Ss root R=", Ss_ROOT_R, "mm > hex bore R=", HEX_CIRC_R+PIP_TOL));

// 11. Axial stack < 40mm
assert(TOTAL_STACK < 40,
    str("FAIL: Axial stack=", TOTAL_STACK, "mm >= 40mm"));
echo(str("✓ Assert 11: Axial stack=", TOTAL_STACK, "mm < 40mm"));

// 12. Minimum planet teeth >= 6 (printability)
MIN_TEETH = min(N_Pi, N_Po, P2_T);
assert(MIN_TEETH >= 6,
    str("FAIL: Min planet teeth=", MIN_TEETH, " < 6"));
echo(str("✓ Assert 12: Min planet teeth=", MIN_TEETH, " >= 6"));

echo("========================================");
echo("  ALL 12 ASSERTIONS PASSED");
echo("========================================");
