// ============================================================
// RAVIGNEAUX GRID v1 — Parametric Kinetic Sculpture Unit
// ============================================================
//
// 70mm OD Ravigneaux planetary gearset with spool-channel ring.
// 5 internal variants (Ss/Pi pairs) + 5 external pinion sets.
// Ring-as-housing: ring IS the spool drum.
// Designed for 5x5 hex grid kinetic sculpture.
//
// KINEMATIC CHAIN:
//   Shaft A --> pinion --> Ss tube --> Small Sun --+
//   Shaft B --> pinion --> SL tube --> Large Sun --+-- Ravigneaux --> Ring (OUTPUT)
//   Shaft C --> pinion --> Carrier  --> Carrier  --+         |
//                                                      Spool channel
//                                                          |
//                                                     Rope --> Block
//
// VARIANT SYSTEM:
//   VARIANT = 0..4 selects internal Ss/Pi tooth counts
//   EXT_SET = 0..4 selects external drive pinion tooth counts
//
// REFERENCE:
//   - Ford 4R70W Ravigneaux (ref_assembly.scad) for visual DNA
//   - ravigneaux_v13.scad for parametric structure
//   - HEXAGON ZAR8 for clean trefoil carrier aesthetic
//   - Design doc: docs/plans/2026-02-23-ravigneaux-grid-sculpture-design.md
//
// Units: mm, degrees
// ============================================================

// ============================================================
// QUALITY / ANIMATION
// ============================================================
$fn = 48;  // Assembly preview. Use 64 for final render only.

MANUAL_POSITION = -1;  // >= 0 freezes animation. -1 = use $t
POS = MANUAL_POSITION >= 0 ? MANUAL_POSITION : $t;

// ============================================================
// VARIANT SELECTOR
// ============================================================
VARIANT = 2;   // [0:1:4] Internal gear variant (0=A, 1=B, 2=C, 3=D, 4=E)
EXT_SET = 2;   // [0:1:4] External pinion set (0=slow, 4=fast)

// Internal variant table: [Ss_teeth, Pi_teeth]
// All satisfy: Ss + 2*Pi = 40 (= SL)
_VARIANTS = [
    [16, 12],  // A: B-dominant (kA=0.110, kB=0.200)
    [20, 10],  // B: Balanced-B (kA=0.138, kB=0.172)
    [24,  8],  // C: Center     (kA=0.166, kB=0.145)
    [26,  7],  // D: Balanced-A (kA=0.179, kB=0.131)
    [28,  6],  // E: A-dominant (kA=0.193, kB=0.117)
];

// External pinion tooth counts (for SL drive shaft)
// 13, 21 = Fibonacci; 15, 18, 23 = Fibonacci-adjacent
_EXT_PINIONS = [13, 15, 18, 21, 23];

T_SS = _VARIANTS[VARIANT][0];
T_PI = _VARIANTS[VARIANT][1];
T_EXT_PIN = _EXT_PINIONS[EXT_SET];

// ============================================================
// GEAR SPECIFICATIONS
// ============================================================
NORM_MOD   = 0.7;                         // Normal module (mm)
HELIX_ANG  = 25;                          // Helix angle (deg)
TRANS_MOD  = NORM_MOD / cos(HELIX_ANG);   // Transverse module ~0.773mm
PRESS_ANG  = 20;                          // Pressure angle (deg)
DYN_CLEAR  = 0.20;                        // Dynamic clearance (mm)

// Fixed tooth counts
T_SL   = 40;    // Large sun (fixed across all variants)
T_PO   = 20;    // Outer planet (fixed)
T_RING = 80;    // Ring gear (fixed)

// Ravigneaux constraint verification (echoed at bottom)
// SL + 2*Po = Ring:  40 + 40 = 80  CHECK
// Ss + 2*Pi = SL:    variant-specific, all = 40  CHECK

// Derived pitch radii (transverse)
PR_RING = T_RING * TRANS_MOD / 2;
PR_SL   = T_SL * TRANS_MOD / 2;
PR_SS   = T_SS * TRANS_MOD / 2;
PR_PO   = T_PO * TRANS_MOD / 2;
PR_PI   = T_PI * TRANS_MOD / 2;

// Center distances
CD_SL_PO = (T_SL + T_PO) * TRANS_MOD / 2;  // = ORB_Po (outer planet orbit)
CD_SS_PI = (T_SS + T_PI) * TRANS_MOD / 2;   // = ORB_Pi (inner planet orbit)
CD_PI_PO = (T_PI + T_PO) * TRANS_MOD / 2;

ORB_PO = CD_SL_PO;   // Outer planet orbit radius from center
ORB_PI = CD_SS_PI;    // Inner planet orbit radius from center

// Pi angular offset from Po (degrees)
// In Ravigneaux, Pi and Po share a carrier but orbit at different radii.
// Pi is positioned between adjacent Po planets.
PI_ANG_OFFSET = 60;   // 60 deg offset gives clear separation

// ============================================================
// ANIMATION CONTROLS
// ============================================================
DRIVE_SL_DEG      = 360;   // Input 1: Large sun deg per cycle
DRIVE_SS_DEG      = 0;     // Input 2: Small sun deg per cycle
DRIVE_CARRIER_DEG = 0;     // Input 3: Carrier deg per cycle

MANUAL_SL      = 0;   // [0:1:360]
MANUAL_SS      = 0;   // [0:1:360]
MANUAL_CARRIER = 0;   // [0:1:360]

ANG_SL      = DRIVE_SL_DEG * POS + MANUAL_SL;
ANG_SS      = DRIVE_SS_DEG * POS + MANUAL_SS;
ANG_CARRIER = DRIVE_CARRIER_DEG * POS + MANUAL_CARRIER;

// Ring output (Willis equation, SL drive path)
ANG_RING = -(T_SL / T_RING) * (ANG_SL - ANG_CARRIER) + ANG_CARRIER;

// Planet self-rotation on pin axis
ANG_PO_SELF = -(T_SL / T_PO) * (ANG_SL - ANG_CARRIER);
ANG_PI_SELF = -(T_SS / T_PI) * (ANG_SS - ANG_CARRIER);

// ============================================================
// DIMENSIONS
// ============================================================

// --- Ring / Spool Drum ---
RING_WALL     = 3;                              // Structural wall = spool drum
RING_ROOT_R   = PR_RING + 1.25 * TRANS_MOD;    // Internal gear root (outward)
RING_OD       = 2 * (RING_ROOT_R + RING_WALL);  // ~70mm
RING_ID       = 2 * RING_ROOT_R;

// Spool channel
FLANGE_H      = 2;       // Top/bottom flange height
CHANNEL_W     = 8;       // Open channel width for rope
CHANNEL_DEPTH = 2;       // How deep the channel is recessed

// --- Gear zones (SUN GEARS VERTICALLY OFFSET) ---
// Shafts are concentric (tubes). Gear TEETH are at different Z heights.
// Ss (small sun) at BOTTOM, SL (large sun) at TOP, thrust washer between.
SS_GEAR_FW     = 6;       // Small sun face width
SL_GEAR_FW     = 6;       // Large sun face width
THRUST_PLATE_H = 1.5;     // Thrust washer between zones on shaft

// Z positions (bottom-up: Ss zone, thrust, SL zone)
SS_ZONE_BOT   = 0;
SS_ZONE_TOP   = SS_GEAR_FW;                    // 6
SL_ZONE_BOT   = SS_ZONE_TOP + THRUST_PLATE_H;  // 7.5
SL_ZONE_TOP   = SL_ZONE_BOT + SL_GEAR_FW;      // 13.5
TOTAL_GEAR_H  = SL_ZONE_TOP;                    // 13.5

// Planet Z ranges
PO_ZBOT       = SS_ZONE_BOT;    // Long pinion: spans BOTH zones
PO_ZTOP       = SL_ZONE_TOP;
PI_ZBOT       = SS_ZONE_BOT;    // Short pinion: Ss zone ONLY
PI_ZTOP       = SS_ZONE_TOP;
PI_FW         = SS_GEAR_FW;

// Legacy aliases
GEAR_FW       = TOTAL_GEAR_H;
GEAR_ZONE_BOT = SS_ZONE_BOT;
GEAR_ZONE_TOP = SL_ZONE_TOP;

// --- Axial stack ---
LID_H         = 2;
CARRIER_T     = 2;
AXIAL_GAP     = 0.7;     // Gap + PTFE washer combined
WASHER_H      = 0.5;     // PTFE washer thickness

// Computed Z positions (bottom-up)
LID_BOT_Z     = -(LID_H + AXIAL_GAP + CARRIER_T);  // Bottom lid
CAR2_Z        = -(AXIAL_GAP + CARRIER_T);            // Carrier_2 bottom
CAR2_ZTOP     = -AXIAL_GAP;
// Gear zone: Ss at bottom (Z=0-6), thrust, SL at top (Z=7.5-13.5)
CAR1_ZBOT     = TOTAL_GEAR_H + AXIAL_GAP;
CAR1_ZTOP     = CAR1_ZBOT + CARRIER_T;
LID_TOP_Z     = CAR1_ZTOP + AXIAL_GAP;
LID_TOP_ZTOP  = LID_TOP_Z + LID_H;

// Ring total height (encloses everything + flanges)
RING_ZBOT     = LID_BOT_Z - FLANGE_H;
RING_ZTOP     = LID_TOP_ZTOP + FLANGE_H;
RING_TOTAL_H  = RING_ZTOP - RING_ZBOT;

// Channel Z position (centered on ring)
CHANNEL_Z     = (RING_ZBOT + RING_ZTOP) / 2;

// --- Shafts (concentric) ---
ANCHOR_D      = 6;        // M6 rod
SS_TUBE_ID    = 7;
SS_TUBE_OD    = 9;
SL_TUBE_ID    = 10;
SL_TUBE_OD    = 12;
CARRIER_BORE  = 13;

// Shaft Z extents
ANCHOR_ZBOT   = RING_ZBOT - 20;   // Extends below for frame mount
ANCHOR_ZTOP   = RING_ZTOP + 10;   // Extends above

SS_TUBE_ZBOT  = LID_BOT_Z - 5;
SS_TUBE_ZTOP  = LID_TOP_ZTOP + 5;

SL_TUBE_ZBOT  = LID_BOT_Z - 3;
SL_TUBE_ZTOP  = LID_TOP_ZTOP + 3;

// --- Planet pins ---
PIN_D         = 3;         // Planet pin diameter
PIN_BORE_D    = 3.2;       // Planet bore (clearance fit)

// --- Carrier dimensions ---
CAR_PAD       = 1.5;       // Carrier radial pad beyond outer planet
CAR1_OD       = 2 * (ORB_PO + PIN_D / 2 + CAR_PAD);
CAR1_HUB_OD   = CARRIER_BORE + 4;   // Hub OD for top carrier

// ============================================================
// TOLERANCES
// ============================================================
TOL_GENERAL   = 0.20;     // General clearance
TOL_BEARING   = 0.15;     // Shaft/bore running fit
TOL_PRESS     = 0.05;     // Press fit (pins)

// ============================================================
// VISIBILITY TOGGLES
// ============================================================
SHOW_ANCHOR         = true;
SHOW_SS_SHAFT       = true;
SHOW_SL_SHAFT       = true;
SHOW_CARRIER_2      = true;
SHOW_CARRIER_1      = true;
SHOW_CAGE           = true;
SHOW_PLANETS        = true;
SHOW_RING           = true;
SHOW_LIDS           = true;
SHOW_WASHERS        = true;
SHOW_DRIVE          = false;   // External drive pinions
SHOW_ROPE           = true;

CROSS_SECTION       = false;
EXPLODE             = 0;       // [0:1:30] explode distance

// ============================================================
// COLORS (preserved from v13 / ref_assembly)
// ============================================================
C_ANCHOR    = [0.70, 0.20, 0.20];   // Red anchor shaft
C_SS        = [0.15, 0.55, 0.30];   // Green small sun
C_SL        = [0.76, 0.60, 0.22];   // Gold large sun
C_PO        = [0.85, 0.25, 0.20];   // Red outer planet
C_PI        = [1.0,  0.85, 0.0];    // Yellow inner planet
C_CAR       = [0.55, 0.55, 0.58];   // Grey carrier top
C_CAR2      = [0.45, 0.45, 0.50];   // Darker grey carrier bottom
C_CAGE      = [0.60, 0.60, 0.65];   // Light grey cage
C_RING      = [0.25, 0.25, 0.28];   // Dark ring
C_LID       = [0.30, 0.28, 0.32];   // Lid
C_WASHER    = [0.85, 0.55, 0.20];   // Orange thrust washers
C_ROPE      = [0.82, 0.82, 0.88];   // Light thread
C_DRV       = [0.40, 0.40, 0.45];   // Drive shaft/pinion

// ============================================================
// HELPERS
// ============================================================
module zcyl(d, zbot, h) {
    translate([0, 0, zbot]) cylinder(d=d, h=h, $fn=$fn);
}
module zcyl_hollow(od, id, zbot, h) {
    difference() {
        zcyl(od, zbot, h);
        translate([0, 0, zbot - 0.1]) cylinder(d=id, h=h + 0.2, $fn=$fn);
    }
}

// ============================================================
// LAYER 1: INVOLUTE MATH
// ============================================================
function _inv_polar(rb, alpha_deg) =
    let(a_rad = alpha_deg * PI / 180,
        x = rb * (cos(alpha_deg) + a_rad * sin(alpha_deg)),
        y = rb * (sin(alpha_deg) - a_rad * cos(alpha_deg)),
        r = sqrt(x * x + y * y),
        ang = atan2(y, x))
    [r, ang];

// ============================================================
// LAYER 2: 2D GEAR PROFILES
// ============================================================

// External involute gear 2D profile
module involute_gear_2d(teeth, mod, pressure_angle=20, clearance=0.20) {
    pitch_r  = teeth * mod / 2;
    base_r   = pitch_r * cos(pressure_angle);
    tip_r    = pitch_r + mod;
    root_r   = pitch_r - 1.25 * mod;

    alpha_tip = (base_r < tip_r) ? acos(base_r / tip_r) : 0;
    half_tooth_deg = (PI * mod / 2) / pitch_r * (180 / PI) / 2;

    pitch_polar = _inv_polar(base_r, pressure_angle);
    inv_ang_at_pitch = pitch_polar[1];
    right_offset = half_tooth_deg - inv_ang_at_pitch;

    steps = 20;  // Reduced from 30 for GPU performance

    tip_polar = _inv_polar(base_r, alpha_tip);
    right_tip_ang = tip_polar[1] + right_offset;
    left_tip_ang = -right_tip_ang;

    union() {
        for (i = [0:teeth - 1]) {
            rotate([0, 0, i * 360 / teeth])
            polygon(
                concat(
                    [[root_r * cos(-180 / teeth), root_r * sin(-180 / teeth)],
                     [root_r * cos(right_offset), root_r * sin(right_offset)]],
                    [for (s = [0:steps])
                        let(alpha = alpha_tip * s / steps,
                            p = _inv_polar(base_r, alpha),
                            r = p[0],
                            ang = p[1] + right_offset)
                        [r * cos(ang), r * sin(ang)]
                    ],
                    [for (s = [1:3])
                        let(ang = right_tip_ang + s * (left_tip_ang - right_tip_ang) / 4)
                        [tip_r * cos(ang), tip_r * sin(ang)]
                    ],
                    [for (s = [steps:-1:0])
                        let(alpha = alpha_tip * s / steps,
                            p = _inv_polar(base_r, alpha),
                            r = p[0],
                            ang = -(p[1] + right_offset))
                        [r * cos(ang), r * sin(ang)]
                    ],
                    [[root_r * cos(-right_offset), root_r * sin(-right_offset)],
                     [root_r * cos(180 / teeth), root_r * sin(180 / teeth)]]
                )
            );
        }
        circle(r=root_r, $fn=teeth * 6);
    }
}

// Internal involute gear 2D profile (boolean subtraction)
module internal_gear_2d(teeth, mod, pressure_angle=20, clearance=0.20) {
    pitch_r    = teeth * mod / 2;
    int_root_r = pitch_r + 1.25 * mod;
    difference() {
        circle(r=int_root_r, $fn=teeth * 4);
        involute_gear_2d(teeth, mod, pressure_angle, clearance);
    }
}

// ============================================================
// LAYER 3: 3D GEAR PRIMITIVES
// ============================================================

// Helical external gear
module helical_gear(teeth, mod, helix_angle, height, pressure_angle=20) {
    trans_mod = mod / cos(helix_angle);
    pitch_r = teeth * trans_mod / 2;
    twist = tan(helix_angle) * height / pitch_r * (180 / PI);

    rotate([0, 0, -twist / 2])
    linear_extrude(height=height, twist=twist, slices=40, convexity=10)
    involute_gear_2d(teeth=teeth, mod=trans_mod, pressure_angle=pressure_angle);
}

// Helical internal ring gear
module helical_ring_gear(teeth, mod, helix_angle, height, pressure_angle=20) {
    trans_mod = mod / cos(helix_angle);
    pitch_r = teeth * trans_mod / 2;
    twist = tan(helix_angle) * height / pitch_r * (180 / PI);

    rotate([0, 0, -twist / 2])
    linear_extrude(height=height, twist=twist, slices=40, convexity=10)
    internal_gear_2d(teeth=teeth, mod=trans_mod, pressure_angle=pressure_angle);
}

// Planet gear (helical external + axial bore)
module planet_gear(teeth, mod, helix_angle, height, bore_d, pressure_angle=20) {
    difference() {
        helical_gear(teeth, mod, helix_angle, height, pressure_angle);
        translate([0, 0, -0.1])
        cylinder(d=bore_d, h=height + 0.2, $fn=24);
    }
}

// ============================================================
// LAYER 4: COMPONENT MODULES
// ============================================================

// --- Anchor shaft (M6 rod, fixed to frame) ---
module anchor_shaft() {
    color(C_ANCHOR)
    zcyl(ANCHOR_D, ANCHOR_ZBOT, ANCHOR_ZTOP - ANCHOR_ZBOT);
}

// --- Ss shaft tube (small sun drive — INNER tube, goes in first) ---
module ss_shaft() {
    rotate([0, 0, ANG_SS]) {
        // Tube
        color(C_SS)
        zcyl_hollow(SS_TUBE_OD, SS_TUBE_ID, SS_TUBE_ZBOT,
                    SS_TUBE_ZTOP - SS_TUBE_ZBOT);

        // Sun gear teeth (BOTTOM zone: Z=0 to 6)
        color(C_SS)
        difference() {
            translate([0, 0, SS_ZONE_BOT])
            helical_gear(teeth=T_SS, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=SS_GEAR_FW);
            translate([0, 0, SS_ZONE_BOT - 0.1])
            cylinder(d=SS_TUBE_OD + TOL_GENERAL, h=SS_GEAR_FW + 0.2, $fn=48);
        }
    }
}

// --- SL shaft tube (large sun drive — OUTER sleeve around Ss) ---
module sl_shaft() {
    rotate([0, 0, ANG_SL]) {
        // Tube (sleeve around Ss tube)
        color(C_SL)
        zcyl_hollow(SL_TUBE_OD, SL_TUBE_ID, SL_TUBE_ZBOT,
                    SL_TUBE_ZTOP - SL_TUBE_ZBOT);

        // Sun gear teeth (TOP zone: Z=7.5 to 13.5)
        color(C_SL)
        difference() {
            translate([0, 0, SL_ZONE_BOT])
            helical_gear(teeth=T_SL, mod=NORM_MOD,
                helix_angle=HELIX_ANG, height=SL_GEAR_FW);
            translate([0, 0, SL_ZONE_BOT - 0.1])
            cylinder(d=SL_TUBE_OD + TOL_GENERAL, h=SL_GEAR_FW + 0.2, $fn=48);
        }
    }
}

// --- Ring gear + spool drum (OUTPUT) ---
module ring_spool_assembly() {
    rotate([0, 0, ANG_RING]) {
        difference() {
            union() {
                // Internal helical ring gear teeth (spans full gear zone)
                color(C_RING, 0.6)
                translate([0, 0, GEAR_ZONE_BOT])
                helical_ring_gear(teeth=T_RING, mod=NORM_MOD,
                    helix_angle=HELIX_ANG,
                    height=GEAR_FW);

                // Outer drum wall (full height including flanges)
                color(C_RING, 0.6)
                zcyl_hollow(RING_OD, RING_ID, RING_ZBOT, RING_TOTAL_H);
            }

            // Cut spool channel — recess in the outer surface
            // Channel centered on ring, recessed by CHANNEL_DEPTH
            channel_zbot = CHANNEL_Z - CHANNEL_W / 2;
            channel_od = RING_OD + 0.1;  // cut from outside
            channel_id = RING_OD - 2 * CHANNEL_DEPTH;
            translate([0, 0, channel_zbot])
            difference() {
                cylinder(d=channel_od, h=CHANNEL_W, $fn=96);
                translate([0, 0, -0.1])
                cylinder(d=channel_id, h=CHANNEL_W + 0.2, $fn=96);
            }
        }

        // Bottom lid (bearing seat)
        if (SHOW_LIDS)
        color(C_LID, 0.8)
        zcyl_hollow(RING_ID, SL_TUBE_OD + 2 * TOL_BEARING + 2,
                    LID_BOT_Z, LID_H);

        // Top lid (bearing seat)
        if (SHOW_LIDS)
        color(C_LID, 0.8)
        zcyl_hollow(RING_ID, CAR1_HUB_OD + 2 * TOL_BEARING + 2,
                    LID_TOP_Z, LID_H);
    }
}

// --- Carrier_2 (bottom carrier plate) --- trefoil shape
module carrier_2() {
    rotate([0, 0, ANG_CARRIER]) {
        color(C_CAR2)
        difference() {
            union() {
                // Trefoil plate (3-arm star, clean like ZAR8 reference)
                translate([0, 0, CAR2_Z])
                linear_extrude(height=CARRIER_T, convexity=4)
                trefoil_2d(ORB_PO + PIN_D / 2 + CAR_PAD, CARRIER_BORE / 2 + 1);

                // Hub tube (extends below for shaft coupling)
                zcyl_hollow(CARRIER_BORE + 4, CARRIER_BORE,
                            CAR2_Z - 3, CARRIER_T + 3);
            }

            // Central bore
            translate([0, 0, CAR2_Z - 4])
            cylinder(d=CARRIER_BORE, h=CARRIER_T + 8, $fn=48);

            // Po pin holes (3x at 120 deg)
            for (i = [0:2])
                rotate([0, 0, i * 120])
                translate([ORB_PO, 0, CAR2_Z - 0.1])
                cylinder(d=PIN_D + TOL_PRESS, h=CARRIER_T + 0.2, $fn=16);

            // Pi pin holes (3x at 120 deg + offset)
            for (i = [0:2])
                rotate([0, 0, i * 120 + PI_ANG_OFFSET])
                translate([ORB_PI, 0, CAR2_Z - 0.1])
                cylinder(d=PIN_D + TOL_PRESS, h=CARRIER_T + 0.2, $fn=16);
        }
    }
}

// --- Carrier_1 (top carrier plate) ---
module carrier_1() {
    rotate([0, 0, ANG_CARRIER]) {
        color(C_CAR)
        difference() {
            union() {
                // Trefoil plate
                translate([0, 0, CAR1_ZBOT])
                linear_extrude(height=CARRIER_T, convexity=4)
                trefoil_2d(ORB_PO + PIN_D / 2 + CAR_PAD, CARRIER_BORE / 2 + 1);

                // Hub extending above (for top bearing)
                zcyl(CAR1_HUB_OD, CAR1_ZTOP, 3);
            }

            // Central bore
            translate([0, 0, CAR1_ZBOT - 0.1])
            cylinder(d=CARRIER_BORE, h=CARRIER_T + 4, $fn=48);

            // Po pin holes
            for (i = [0:2])
                rotate([0, 0, i * 120])
                translate([ORB_PO, 0, CAR1_ZBOT - 0.1])
                cylinder(d=PIN_D + TOL_PRESS, h=CARRIER_T + 0.2, $fn=16);

            // Pi pin holes
            for (i = [0:2])
                rotate([0, 0, i * 120 + PI_ANG_OFFSET])
                translate([ORB_PI, 0, CAR1_ZBOT - 0.1])
                cylinder(d=PIN_D + TOL_PRESS, h=CARRIER_T + 0.2, $fn=16);
        }
    }
}

// --- Trefoil 2D profile (clean 3-arm star, ZAR8 aesthetic) ---
module trefoil_2d(arm_r, hub_r) {
    arm_w = PIN_D + 2 * CAR_PAD;  // Width of each arm
    union() {
        // Central hub
        circle(r=hub_r, $fn=48);

        // 3 arms at 120 deg
        for (i = [0:2])
            rotate([0, 0, i * 120])
            hull() {
                circle(r=hub_r, $fn=48);
                translate([arm_r, 0])
                circle(d=arm_w, $fn=24);
            }

        // 3 cross-arms to Pi positions
        for (i = [0:2])
            rotate([0, 0, i * 120 + PI_ANG_OFFSET])
            hull() {
                circle(r=hub_r, $fn=48);
                translate([ORB_PI, 0])
                circle(d=arm_w, $fn=24);
            }
    }
}

// --- Planet cage (pin bosses + bridging webs) ---
CAGE_BOSS_OD = PIN_D + 2;
CAGE_BOSS_ID = PIN_BORE_D;
CAGE_WEB_W   = 2;
CAGE_WEB_H   = 1.5;

module cage_sector(sector_ang) {
    // Cage is ONLY for Pi (short pinion) pins — acts as axial spacer/collar.
    // Po (long pinion) spans full height and is retained by carriers directly.

    // Pi spacer collar — sits on pin in Pi zone (upper portion)
    rotate([0, 0, sector_ang + PI_ANG_OFFSET])
    translate([ORB_PI, 0, PI_ZBOT])
    difference() {
        cylinder(d=CAGE_BOSS_OD, h=PI_FW, $fn=16);
        translate([0, 0, -0.1])
        cylinder(d=CAGE_BOSS_ID, h=PI_FW + 0.2, $fn=16);
    }
}

module planet_cage() {
    color(C_CAGE)
    rotate([0, 0, ANG_CARRIER])
    for (i = [0:2])
        cage_sector(i * 120);
}

// --- Planet gears (3x Po + 3x Pi) — compound planet pairs ---
module planet_assembly() {
    for (i = [0:2]) {
        ang = i * 120;

        // Outer planet (Po) — LONG pinion, spans FULL gear zone
        // Meshes with: SL (external) + Ring (internal)
        if (SHOW_PLANETS)
        color(C_PO)
        rotate([0, 0, ANG_CARRIER + ang])
        translate([ORB_PO, 0, 0])
        rotate([0, 0, ANG_PO_SELF])
        translate([0, 0, PO_ZBOT])
        planet_gear(teeth=T_PO, mod=NORM_MOD,
            helix_angle=HELIX_ANG,
            height=PO_ZTOP - PO_ZBOT,
            bore_d=PIN_BORE_D);

        // Inner planet (Pi) — SHORT pinion, UPPER portion only
        // Meshes with: Ss (external) + Po (external)
        // Creates "cavity" in lower zone where only Po+SL mesh
        if (SHOW_PLANETS)
        color(C_PI)
        rotate([0, 0, ANG_CARRIER + ang + PI_ANG_OFFSET])
        translate([ORB_PI, 0, 0])
        rotate([0, 0, ANG_PI_SELF])
        translate([0, 0, PI_ZBOT])
        planet_gear(teeth=T_PI, mod=NORM_MOD,
            helix_angle=HELIX_ANG,
            height=PI_FW,
            bore_d=PIN_BORE_D);
    }
}

// --- Planet pins (dowel pins through carriers and planets) ---
module planet_pins() {
    pin_zbot = CAR2_Z - 1;
    pin_ztop = CAR1_ZTOP + 1;
    pin_h = pin_ztop - pin_zbot;

    rotate([0, 0, ANG_CARRIER]) {
        // Po pins
        for (i = [0:2])
            rotate([0, 0, i * 120])
            translate([ORB_PO, 0, 0])
            color([0.65, 0.65, 0.68])
            zcyl(PIN_D, pin_zbot, pin_h);

        // Pi pins
        for (i = [0:2])
            rotate([0, 0, i * 120 + PI_ANG_OFFSET])
            translate([ORB_PI, 0, 0])
            color([0.65, 0.65, 0.68])
            zcyl(PIN_D, pin_zbot, pin_h);
    }
}

// --- Thrust washers (two-zone sun layout) ---
module washer_assembly() {
    washer_od = CAR1_OD * 0.6;
    washer_id = CARRIER_BORE + 1;

    // 1. Carrier_2 bottom face (between lid_bot and carrier_2)
    color(C_WASHER)
    zcyl_hollow(washer_od, washer_id, CAR2_Z - WASHER_H, WASHER_H);

    // 2. Carrier_2 top face (between carrier_2 and gear zone)
    color(C_WASHER)
    zcyl_hollow(washer_od, washer_id, CAR2_ZTOP, WASHER_H);

    // 3. Thrust plate between sun zones (Z=6 to 7.5, between Ss and SL)
    // Sits on shaft between the two gear tooth zones
    color(C_WASHER)
    zcyl_hollow(SL_TUBE_OD + 1, SS_TUBE_OD - 1,
                SS_ZONE_TOP, THRUST_PLATE_H);

    // 4. Gear zone top (between gears and carrier_1)
    color(C_WASHER)
    zcyl_hollow(washer_od, washer_id, GEAR_ZONE_TOP, WASHER_H);

    // 5. Carrier_1 top face (between carrier_1 and lid_top)
    color(C_WASHER)
    zcyl_hollow(washer_od, washer_id, CAR1_ZTOP, WASHER_H);

    // 6-9. Planet pin washers (Po and Pi, both ends)
    rotate([0, 0, ANG_CARRIER])
    for (i = [0:2]) {
        // Po pin bottom washer (above carrier_2)
        rotate([0, 0, i * 120])
        translate([ORB_PO, 0, 0])
        color(C_WASHER)
        zcyl_hollow(PIN_D + 2, PIN_BORE_D, CAR2_ZTOP, WASHER_H);

        // Po pin top washer (below carrier_1)
        rotate([0, 0, i * 120])
        translate([ORB_PO, 0, 0])
        color(C_WASHER)
        zcyl_hollow(PIN_D + 2, PIN_BORE_D, GEAR_ZONE_TOP, WASHER_H);

        // Pi pin bottom washer (at Pi zone bottom)
        rotate([0, 0, i * 120 + PI_ANG_OFFSET])
        translate([ORB_PI, 0, 0])
        color(C_WASHER)
        zcyl_hollow(PIN_D + 2, PIN_BORE_D, PI_ZBOT - WASHER_H, WASHER_H);

        // Pi pin top washer (at Pi zone top)
        rotate([0, 0, i * 120 + PI_ANG_OFFSET])
        translate([ORB_PI, 0, 0])
        color(C_WASHER)
        zcyl_hollow(PIN_D + 2, PIN_BORE_D, PI_ZTOP, WASHER_H);
    }
}

// --- Rope from spool channel (360 deg wrap + vertical Z-drop) ---
module rope() {
    rope_drop = 80;  // How far the block hangs below
    rope_d = 0.8;
    wrap_r = RING_OD / 2 - CHANNEL_DEPTH / 2;  // Mid-channel radius
    wrap_steps = 72;  // 360/5 = 5deg per step

    rotate([0, 0, ANG_RING]) {
        color(C_ROPE) {
            // 360 degree wrap around spool channel
            for (s = [0:wrap_steps - 1]) {
                a1 = s * 360 / wrap_steps;
                a2 = (s + 1) * 360 / wrap_steps;
                hull() {
                    translate([wrap_r * cos(a1), wrap_r * sin(a1), CHANNEL_Z])
                    sphere(d=rope_d, $fn=6);
                    translate([wrap_r * cos(a2), wrap_r * sin(a2), CHANNEL_Z])
                    sphere(d=rope_d, $fn=6);
                }
            }

            // Vertical drop from anchor point (0 deg) straight down on Z-axis
            hull() {
                translate([wrap_r, 0, CHANNEL_Z])
                sphere(d=rope_d, $fn=6);
                translate([wrap_r, 0, CHANNEL_Z - rope_drop])
                sphere(d=rope_d, $fn=6);
            }
        }
    }
}

// --- External drive pinions (mesh with sun shafts from row shafts) ---
// 3 external pinions drive: Ss tube, SL tube, Carrier bore
EXT_PIN_OFFSET_R = RING_OD / 2 + 8;  // Pinion center distance from assembly center
EXT_PIN_PR = T_EXT_PIN * TRANS_MOD / 2;

module drive_pinion(ang_deg, drive_shaft_ang) {
    color(C_DRV)
    rotate([0, 0, ang_deg])
    translate([EXT_PIN_OFFSET_R, 0, 0]) {
        // Pinion gear body
        rotate([0, 0, drive_shaft_ang])
        translate([0, 0, GEAR_ZONE_BOT])
        helical_gear(teeth=T_EXT_PIN, mod=NORM_MOD,
            helix_angle=HELIX_ANG, height=GEAR_FW);

        // Drive shaft stub (extending below)
        color(C_DRV)
        zcyl(PIN_D + 1, RING_ZBOT - 5, RING_TOTAL_H + 10);
    }
}

module drive_assembly() {
    // 3 drive pinions at 120 deg, each driving one shaft
    drive_pinion(0, -ANG_SL * T_SL / T_EXT_PIN);
    drive_pinion(120, -ANG_SS * T_SS / T_EXT_PIN);
    drive_pinion(240, -ANG_CARRIER);  // Direct carrier drive (1:1 stub)
}

// ============================================================
// LAYER 5: FULL ASSEMBLY
// ============================================================
module full_assembly() {
    // Anchor shaft (fixed)
    if (SHOW_ANCHOR)       anchor_shaft();

    // Concentric drive shafts
    if (SHOW_SS_SHAFT)     ss_shaft();
    if (SHOW_SL_SHAFT)     sl_shaft();

    // Carrier system
    if (SHOW_CARRIER_2)    carrier_2();
    if (SHOW_CARRIER_1)    carrier_1();
    if (SHOW_CAGE)         planet_cage();
                           planet_pins();

    // Planet gears
    planet_assembly();

    // Ring + spool drum (output)
    if (SHOW_RING)         ring_spool_assembly();

    // Hardware
    if (SHOW_WASHERS)      washer_assembly();

    // External drive pinions
    if (SHOW_DRIVE)        drive_assembly();

    // Rope
    if (SHOW_ROPE)         rope();
}

// ============================================================
// MAIN
// ============================================================
if (CROSS_SECTION) {
    difference() {
        full_assembly();
        translate([-200, 0, -200]) cube([400, 200, 400]);
    }
} else {
    full_assembly();
}

// ============================================================
// ECHO + ASSERTIONS
// ============================================================
echo("==============================================");
echo("  RAVIGNEAUX GRID v1 — PARAMETRIC");
echo("==============================================");
echo(str("VARIANT=", VARIANT, " (Ss=", T_SS, ", Pi=", T_PI, ")"));
echo(str("EXT_SET=", EXT_SET, " (pinion=", T_EXT_PIN, "T)"));
echo("");
echo(str("Ravigneaux check: SL + 2*Po = ", T_SL, " + ", 2 * T_PO,
         " = ", T_SL + 2 * T_PO, " (Ring=", T_RING, ") ",
         (T_SL + 2 * T_PO == T_RING) ? "OK" : "FAIL"));
echo(str("Inner check: Ss + 2*Pi = ", T_SS, " + ", 2 * T_PI,
         " = ", T_SS + 2 * T_PI, " (SL=", T_SL, ") ",
         (T_SS + 2 * T_PI == T_SL) ? "OK" : "FAIL"));
echo("");
echo(str("Pitch radii — Ring:", PR_RING, " SL:", PR_SL, " Ss:", PR_SS,
         " Po:", PR_PO, " Pi:", PR_PI));
echo(str("Orbits — Po:", ORB_PO, "mm  Pi:", ORB_PI, "mm"));
echo(str("Ring OD: ", RING_OD, "mm  Ring total H: ", RING_TOTAL_H, "mm"));
echo("");
echo(str("Ss zone: Z=[", SS_ZONE_BOT, ",", SS_ZONE_TOP, "] h=", SS_GEAR_FW,
         "mm | Thrust: Z=[", SS_ZONE_TOP, ",", SL_ZONE_BOT,
         "] h=", THRUST_PLATE_H, "mm | SL zone: Z=[", SL_ZONE_BOT, ",",
         SL_ZONE_TOP, "] h=", SL_GEAR_FW, "mm"));
echo(str("Po: Z=[", PO_ZBOT, ",", PO_ZTOP, "] h=", PO_ZTOP - PO_ZBOT,
         "mm (full)  Pi: Z=[", PI_ZBOT, ",", PI_ZTOP, "] h=", PI_FW,
         "mm (upper half)  ratio=", (PO_ZTOP - PO_ZBOT) / PI_FW, "x"));
echo("");

// Kinematic coefficients
_kA_local = T_SS / (T_SS + T_SL);
_kB_local = T_SL / (T_SS + T_SL);
echo(str("Blend: kA(Ss)=", _kA_local, "  kB(SL)=", _kB_local,
         "  sum=", _kA_local + _kB_local));

// Shaft clearance checks
echo(str("Ss root R: ", PR_SS - 1.25 * TRANS_MOD,
         "mm  vs Ss tube OD/2: ", SS_TUBE_OD / 2, "mm  gap: ",
         PR_SS - 1.25 * TRANS_MOD - SS_TUBE_OD / 2, "mm"));
echo(str("SL root R: ", PR_SL - 1.25 * TRANS_MOD,
         "mm  vs SL tube OD/2: ", SL_TUBE_OD / 2, "mm  gap: ",
         PR_SL - 1.25 * TRANS_MOD - SL_TUBE_OD / 2, "mm"));

echo(str("Ring output angle: ", ANG_RING, " deg"));
echo("ANIMATION: View->Animate (FPS=10, Steps=100)");
