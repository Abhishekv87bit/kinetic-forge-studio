// ============================================================
// RAVIGNEAUX V13 — SHARED PARAMETERS
// ============================================================
// All constants, dimensions, colors, animation.
// Every other file `include`s this.
// ============================================================

$fn = 64;

// ============================================================
// GEAR SPECS
// ============================================================
NORM_MOD   = 0.866;                          // normal module (mm)
HELIX_ANG  = 30;                             // helix angle (deg, right-hand)
TRANS_MOD  = NORM_MOD / cos(HELIX_ANG);      // transverse module = 1.0mm
PRESS_ANG  = 20;                             // pressure angle (deg)
DYN_CLEAR  = 0.25;                           // dynamic clearance (mm)

// Tooth counts
T_SS   = 31;    // small sun
T_SL   = 38;    // large sun
T_PI   = 24;    // short pinion (meshes Ss + Po)
T_PO   = 25;    // long pinion (meshes SL + Ring)
T_RING = 88;    // ring gear (internal)

// Derived pitch radii (transverse)
PR_RING = T_RING * TRANS_MOD / 2;    // 44.0mm
PR_SL   = T_SL * TRANS_MOD / 2;      // 19.0mm
PR_SS   = T_SS * TRANS_MOD / 2;      // 15.5mm
PR_PO   = T_PO * TRANS_MOD / 2;      // 12.5mm
PR_PI   = T_PI * TRANS_MOD / 2;      // 12.0mm

// Center distances (from tooth counts)
CD_SL_PO = PR_SL + PR_PO;            // 31.5mm = Po orbit radius
CD_SS_PI = PR_SS + PR_PI;            // 27.5mm ~ Pi orbit radius

// ============================================================
// ANIMATION CONTROLS
// ============================================================
DRIVE_SL_DEG      = 360;    // Input 1: Large sun — deg per cycle
DRIVE_SS_DEG      = 0;      // Input 2: Small sun — deg per cycle
DRIVE_CARRIER_DEG = 0;      // Input 3: Carrier — deg per cycle

// Manual position sliders [0:1:360]
MANUAL_SL      = 0;
MANUAL_SS      = 0;
MANUAL_CARRIER = 0;

// Compute current angles = animation + manual
ANG_SL      = DRIVE_SL_DEG * $t + MANUAL_SL;
ANG_SS      = DRIVE_SS_DEG * $t + MANUAL_SS;
ANG_CARRIER = DRIVE_CARRIER_DEG * $t + MANUAL_CARRIER;

// Ring output (Willis equation, SL drive path)
ANG_RING = -(T_SL / T_RING) * (ANG_SL - ANG_CARRIER) + ANG_CARRIER;

// Planet self-rotation on pin axis
ANG_PO_SELF = -(T_SL / T_PO) * (ANG_SL - ANG_CARRIER);
ANG_PI_SELF = -(T_SS / T_PI) * (ANG_SS - ANG_CARRIER);

// ============================================================
// DIMENSIONS
// ============================================================
RING_OD       = 96;
RING_WALL     = 3;
RING_ID       = RING_OD - 2 * RING_WALL;  // 90

GEAR_ZONE_BOT = 0;
GEAR_ZONE_TOP = 22;

// Planet gear Z ranges
PO_ZBOT = 0;        // long pinion bottom
PO_ZTOP = 22;       // long pinion top
PI_ZBOT = 12;       // short pinion bottom
PI_ZTOP = 22;       // short pinion top

// Planet pin orbital radii
PO_ORBIT = 31.5;          // long pinion orbit radius (= CD_SL_PO)
PI_ORBIT_ACTUAL = 27.44;  // short pinion orbit (STL-measured, ~ CD_SS_PI)
PI_ANG_OFFSET   = 71.5;   // Pi angular offset from Po (degrees)

// Planet pin bore
PIN_BORE_D = 8;            // axial bore through planet gears

// Washer dimensions
WASHER_OD   = 13;
WASHER_ID   = 6;
WASHER_H    = 1.2;

// Central thrust washer dims (W1, W9)
THRUST_WASHER_OD = 40;
THRUST_WASHER_ID = 20;
THRUST_WASHER_H  = 1.2;

// Carrier_1 dimensions
CARRIER1_OD      = 78;
CARRIER1_BOSS_OD = 35;
CARRIER1_ZTOP    = 26.5;
CARRIER1_HC_ZBOT = 22;
CARRIER1_HC_H    = CARRIER1_ZTOP - CARRIER1_HC_ZBOT;  // 4.5mm
CARRIER1_HUB_H   = 5;           // hub extends above plate
CARRIER1_BORE    = 26;           // clears SL shaft OD=25 + gap
CARRIER1_PIN_STUB_H = 3;        // pin stubs protrude below plate
CARRIER1_PIN_STUB_D = 8;        // match planet bore

// Sun shaft tube ODs
SUN_TUBE_OD      = 33;

// Bearings
BEARING_TOP_OD  = 26;
BEARING_TOP_ID  = 10;
BEARING_TOP_H   = RING_WALL;
CARRIER_SHAFT_OD = 33;
BEARING_BOT_OD   = 42;
BEARING_BOT_ID   = 35;
BEARING_BOT_H    = RING_WALL;
BEARING_CLR   = 0.25;

// ============================================================
// RING ENCLOSURE
// ============================================================
RING_EXT_SLIDER   = 23;       // [0:1:40]

RING_ORIG_ZBOT = 12;          // where teeth start (Po mesh zone)
RING_ORIG_ZTOP = 30;          // original ring top (from STL ref)
RING_ORIG_H    = RING_ORIG_ZTOP - RING_ORIG_ZBOT;

RING_EXT_H     = RING_EXT_SLIDER;
RING_BOT_Z     = RING_ORIG_ZBOT - RING_EXT_H;
RING_GAP_TOP   = 1.6;
RING_TOP_PLATE = 3;
RING_TOP_Z     = CARRIER1_ZTOP + RING_GAP_TOP + RING_TOP_PLATE;

LID_BOT_Z      = RING_BOT_Z;
LID_BOT_H      = RING_WALL;
LID_BOT_BORE   = SUN_TUBE_OD + 2 * BEARING_CLR + 2;

LID_TOP_Z      = RING_TOP_Z - RING_WALL;
LID_TOP_H      = RING_WALL;
LID_TOP_BORE   = CARRIER1_BOSS_OD + 2 * BEARING_CLR + 2;

RING_ADD_BOT_ZBOT = RING_BOT_Z;
RING_ADD_BOT_ZTOP = RING_ORIG_ZBOT;
RING_ADD_BOT_H    = RING_ADD_BOT_ZTOP - RING_ADD_BOT_ZBOT;

RING_ADD_TOP_ZBOT = RING_ORIG_ZTOP;
RING_ADD_TOP_ZTOP = RING_TOP_Z;
RING_ADD_TOP_H    = RING_ADD_TOP_ZTOP - RING_ADD_TOP_ZBOT;

// V-groove
GROOVE_WIDTH   = 4;
GROOVE_DEPTH   = 2;
GROOVE_Z       = (RING_BOT_Z + RING_TOP_Z) / 2;

// ============================================================
// STAGE 2 — DRIVE SHAFTS
// ============================================================
T_SS_SHAFT  = 17;   T_SL_SHAFT  = 23;   T_CAR_SHAFT = 29;
T_DRV_SS  = 20;     T_DRV_SL  = 20;     T_DRV_CAR = 20;

DRV_SS_OD  = T_DRV_SS  * TRANS_MOD + 2 * NORM_MOD;
DRV_SL_OD  = T_DRV_SL  * TRANS_MOD + 2 * NORM_MOD;
DRV_CAR_OD = T_DRV_CAR * TRANS_MOD + 2 * NORM_MOD;

DRV_SHAFT_D = 8;

DRV_SS_ANG  = 0;      DRV_SL_ANG  = 120;    DRV_CAR_ANG = 240;

CD_SS_DRV  = (T_SS_SHAFT  + T_DRV_SS)  * TRANS_MOD / 2;
CD_SL_DRV  = (T_SL_SHAFT  + T_DRV_SL)  * TRANS_MOD / 2;
CD_CAR_DRV = (T_CAR_SHAFT + T_DRV_CAR) * TRANS_MOD / 2;

DRV_SHAFT_LEN = 120;

ANCHOR_SHAFT_D  = 10;
ANCHOR_SHAFT_ZBOT = -70;
ANCHOR_SHAFT_ZTOP = 40;

// ============================================================
// VISIBILITY TOGGLES
// ============================================================
SHOW_SHAFT          = true;
SHOW_SMALL_SUN      = true;
SHOW_BIG_SUN        = true;
SHOW_LONG_PINION    = true;
SHOW_SHORT_PINION   = true;
SHOW_CARRIER_1      = true;
SHOW_CARRIER_2      = true;
SHOW_CARRIER_3      = true;
SHOW_RING           = true;
SHOW_WASHERS        = true;
SHOW_CLIPS          = true;

SHOW_V_GROOVE       = true;
SHOW_BEARINGS       = true;

SHOW_MOUNT_GEAR     = false;
SHOW_DRIVE          = false;
SHOW_ANCHOR         = false;

CROSS_SECTION       = false;
EXPLODE             = 0;

// ============================================================
// CUSTOMIZER SLIDERS
// ============================================================
CARRIER_SHAFT_EXT = 12.75;    // [5:0.25:20]
CAR_HUB_LEN       = 16;       // [4:0.5:16]
SL_HUB_LEN        = 16;       // [4:0.5:16]
SS_HUB_LEN        = 15;       // [4:0.5:15]
INNER_SHAFT_EXT   = 29;       // [0:0.5:40]
SL_SHAFT_EXT      = 12.75;    // [5:0.25:20]
SS_SHAFT_EXT      = 12.75;    // [5:0.25:20]

// ============================================================
// COLORS
// ============================================================
C_SHAFT     = [0.75, 0.75, 0.78];
C_SS        = [0.15, 0.55, 0.30];
C_SL        = [0.76, 0.60, 0.22];
C_PO        = [0.85, 0.25, 0.20];
C_PI        = [1.0,  0.85, 0.0];
C_CAR       = [0.55, 0.55, 0.58];
C_CAR2      = [0.45, 0.45, 0.50];
C_CAR3      = [0.60, 0.60, 0.65];
C_RING      = [0.25, 0.25, 0.28];
C_THRUST    = [0.85, 0.55, 0.20];
C_WASHER    = [0.95, 0.80, 0.10];
C_CLIP      = [0.3, 0.3, 0.9];
C_GROOVE    = [0.35, 0.20, 0.10];
C_BEARING   = [0.30, 0.60, 0.85];
C_LID       = [0.30, 0.28, 0.32];
C_DRV_SHAFT = [0.40, 0.40, 0.45];
C_DRV_SS    = [0.15, 0.55, 0.30];
C_DRV_SL    = [0.76, 0.60, 0.22];
C_DRV_CAR   = [0.55, 0.55, 0.58];
C_ANCHOR    = [0.70, 0.20, 0.20];

// ============================================================
// HELPERS
// ============================================================
module zcyl(d, zbot, h) {
    translate([0, 0, zbot]) cylinder(d=d, h=h);
}
module zcyl_hollow(od, id, zbot, h) {
    difference() {
        zcyl(od, zbot, h);
        translate([0, 0, zbot - 0.1]) cylinder(d=id, h=h + 0.2);
    }
}

// ============================================================
// SHAFT EXTENSION DIMENSIONS (computed from sliders)
// ============================================================

// Mating gear specs
GEAR_FW       = 10;
LIP_H         = 1.5;
LIP_EXTRA     = 4;
LIP_GAP       = 0.25;
CHAMFER_TIP   = 1;

T_MATE_CAR = 40;
T_MATE_SL  = 32;
T_MATE_SS  = 26;

// Carrier plate dims
CAR_PLATE_ZTOP = -1.5;
CAR_PLATE_ZBOT = -3.5;
CAR_PLATE_OD   = 80;
CAR_PO_PIN_D   = 8;
CAR_PI_PIN_D   = 13.4;     // oversized to clear carrier_3 boss
CAR_PIN_DEPTH  = 2;
CAR_PLATE_H = CAR_PLATE_ZTOP - CAR_PLATE_ZBOT;

// Hub tube
CAR_HUB_ZTOP   = CAR_PLATE_ZBOT;
CAR_HUB_ZBOT   = CAR_PLATE_ZBOT - CAR_HUB_LEN;
CAR_HUB_OD     = 33;
CAR_HUB_ID     = 26;
CAR_HUB_COLLAR_Z = -6.5;

// Bottom cap
CAR_CAP_H     = 2;
CAR_CAP_ZTOP  = CAR_HUB_ZBOT;
CAR_CAP_ZBOT  = CAR_HUB_ZBOT - CAR_CAP_H;
CAR_CAP_OD    = 33;
CAR_CAP_ID    = 27.25;

// Extensions
CAR_EXT_H     = CARRIER_SHAFT_EXT;
CAR_EXT_OD    = 33;
CAR_EXT_ID    = 26;
CAR_EXT_ZTOP  = CAR_CAP_ZBOT;
CAR_EXT_ZBOT  = CAR_CAP_ZBOT - CAR_EXT_H;

SL_EXT_H      = SL_SHAFT_EXT;
SL_EXT_ZTOP   = -(GEAR_ZONE_TOP + SL_HUB_LEN);
SL_EXT_ZBOT   = SL_EXT_ZTOP - SL_EXT_H;
SL_EXT_OD     = 25;
SL_EXT_ID     = 20;

SS_EXT_H      = SS_SHAFT_EXT;
SS_EXT_ZTOP   = SL_EXT_ZTOP - SS_HUB_LEN;
SS_EXT_ZBOT   = SS_EXT_ZTOP - SS_EXT_H;
SS_EXT_OD     = 18.75;
SS_EXT_ID     = 12;

// Drive pinion Z positions (centered on bottom mating gears)
DRV_SS_FW  = GEAR_FW;
DRV_SL_FW  = GEAR_FW;
DRV_CAR_FW = GEAR_FW;
DRV_SS_Z   = SS_EXT_ZBOT  - GEAR_FW / 2;
DRV_SL_Z   = SL_EXT_ZBOT  - GEAR_FW / 2;
DRV_CAR_Z  = CAR_EXT_ZBOT - GEAR_FW / 2;

// Inner shaft
INNER_SHAFT_D    = 10;
INNER_SHAFT_ZTOP = 26 + INNER_SHAFT_EXT / 2;
INNER_SHAFT_ZBOT = SS_EXT_ZTOP - INNER_SHAFT_EXT / 2;

// Bearing Z positions
CARRIER2_ZBOT = -21.5;
BEARING_BOT_Z = RING_BOT_Z;
BEARING_TOP_Z = CARRIER1_ZTOP + RING_GAP_TOP;

// Spline parameters
SPLINE_COUNT   = 6;
SPLINE_DEPTH   = 0.6;
SPLINE_DUTY    = 0.45;
SPLINE_LEADIN  = 1.5;
SPLINE_PILOT   = 0.5;
SPLINE_CHAMFER_TOP = 0.3;
SPLINE_CLEARANCE = 0.2;

// Carrier_3 cage dimensions
CAGE_BOSS_OD = 10;     // outer diameter of pin boss
CAGE_BOSS_ID = 8;      // pin bore = planet bore
CAGE_WEB_W   = 3;      // bridging web width
CAGE_WEB_H   = 2;      // bridging web thickness

// Thrust ring dimensions
BIG_SUN_RING_OD = SL_EXT_OD;      // 25mm
BIG_SUN_RING_ID = SL_EXT_ID;      // 20mm
BIG_SUN_RING_H  = 1.5;

SM_SUN_RING_OD = SS_EXT_OD;       // 18.75mm
SM_SUN_RING_ID = SS_EXT_ID;       // 12mm
SM_SUN_RING_H  = 1.5;
