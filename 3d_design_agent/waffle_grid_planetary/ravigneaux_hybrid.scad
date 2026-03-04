// ============================================================
// RAVIGNEAUX HYBRID — V12: Unified Washers + Clips at All Axles
// ============================================================
//
// FEATURES:
//   - All 13 STLs (planets/cages/clips 3x at 120°)
//   - Animation: 3 independent input shafts, computed ring output
//   - Sealed ring enclosure (top lid + bottom lid + bearing seats)
//   - V-groove on ring OD for rope
//
// KINEMATIC CHAIN:
//   Input 1 (SL large sun)   ──┐
//   Input 2 (Ss small sun)   ──┤── planets ──→ Ring = OUTPUT
//   Input 3 (Carrier)         ──┘                  │
//                                              V-groove → rope → hanging element
// ============================================================

$fn = 64;

STL_DIR = "../gears/automatic-transmission-double-planetary-gearset-ravigneaux-model_files/";

// ============================================================
// GEAR SPECS (from f3d)
// ============================================================
//   Module = 0.866mm, Helix = 30 deg
//   Ss = 31T, SL = 38T, Pi = 24T, Po = 25T, Ring = 88T
//   DynamicClearance = 0.25mm
//   Ravigneaux: SL + 2*Po = Ring → 38 + 2*25 = 88 ✓

// Tooth counts for ratio calculations
T_SS   = 31;    // small sun
T_SL   = 38;    // large sun
T_PI   = 24;    // short pinion (meshes Ss)
T_PO   = 25;    // long pinion (meshes SL and Ring)
T_RING = 88;    // ring gear

// ============================================================
// ANIMATION CONTROLS
// ============================================================
// Each input: degrees per animation cycle ($t: 0→1)
// Positive = CCW (standard math), Negative = CW
// Set to 0 = locked/stationary
//
// HOW TO ANIMATE in OpenSCAD:
//   1. View → Animate
//   2. Set FPS=10, Steps=100
//   3. $t will sweep 0→1 automatically
//
// OR use the MANUAL sliders below (works in Customizer without animation)

DRIVE_SL_DEG      = 360;    // Input 1: Large sun (gold) — deg per cycle
DRIVE_SS_DEG      = 0;      // Input 2: Small sun (green) — deg per cycle
DRIVE_CARRIER_DEG = 0;      // Input 3: Carrier — deg per cycle

// Manual position sliders — independent per shaft (Customizer: [0:1:360])
MANUAL_SL      = 0;         // Large sun manual angle
MANUAL_SS      = 0;         // Small sun manual angle
MANUAL_CARRIER = 0;         // Carrier manual angle

// Compute current angles = animation + manual
ANG_SL      = DRIVE_SL_DEG * $t + MANUAL_SL;
ANG_SS      = DRIVE_SS_DEG * $t + MANUAL_SS;
ANG_CARRIER = DRIVE_CARRIER_DEG * $t + MANUAL_CARRIER;

// ============================================================
// RAVIGNEAUX RING OUTPUT CALCULATION
// ============================================================
// The Ravigneaux equation with ALL inputs free:
//
// For a Ravigneaux set (common carrier, shared long planets):
//   T_ring * w_ring = T_SL * w_SL + (T_ring - T_SL) * w_carrier
//     ... but this is simplified. Full Willis equation:
//
// The two mesh paths:
//   Path 1: Ss -> Pi -> Po -> Ring
//   Path 2: SL -> Po -> Ring
//
// Willis equation for compound planetary:
//   (w_ring - w_carrier) / (w_SL - w_carrier) = -T_SL / T_ring   ... (SL-Ring path)
//   (w_ring - w_carrier) / (w_Ss - w_carrier) = T_Ss / T_ring     ... (Ss-Ring path via Pi-Po)
//
// Wait — for Ravigneaux specifically:
//   Path SL→Ring (through Po only):
//     w_ring - w_c = -(T_SL/T_ring) * (w_SL - w_c)
//
//   Path Ss→Ring (through Pi then Po):
//     w_ring - w_c = (T_Ss/T_ring) * (w_Ss - w_c)
//
// With ALL 3 inputs given, the system is over-constrained (2 equations, 1 unknown).
// In practice, for our kinetic sculpture, we pick ONE drive path at a time.
// But for animation, we'll blend: use the SL path if SL is moving,
// Ss path if Ss is moving, carrier path if carrier is moving.
//
// Single-path ratios (other 2 locked at 0):
//   Drive SL only (Ss=0, C=0):  w_ring = -(T_SL/T_ring) * w_SL + (1 + T_SL/T_ring) * 0
//     → w_ring/w_SL = -T_SL/T_ring = -38/88 = -0.4318
//   Drive Ss only (SL=0, C=0):  w_ring = (T_Ss/T_ring) * w_Ss
//     → w_ring/w_Ss = T_Ss/T_ring = 31/88 = 0.3523
//   Drive C only (SL=0, Ss=0):  w_ring = w_c (ring follows carrier 1:1 if suns locked)
//     Actually: from Willis with both suns locked at 0:
//     w_ring - w_c = -(T_SL/T_ring)*(0 - w_c) = (T_SL/T_ring)*w_c
//     w_ring = w_c + (T_SL/T_ring)*w_c = w_c*(1 + T_SL/T_ring)
//     → w_ring/w_c = 1 + 38/88 = 1.4318
//
// For superposition (all moving, linear system):
//   w_ring = -(T_SL/T_ring)*(w_SL - w_c) + w_c
//          = -(T_SL/T_ring)*w_SL + (1 + T_SL/T_ring)*w_c
//
// Using SL path (this is the primary drive path for Ravigneaux):
ANG_RING = -(T_SL / T_RING) * (ANG_SL - ANG_CARRIER) + ANG_CARRIER;

// Also compute planet self-rotation for visual accuracy
// Po rotates on its pin: (w_Po - w_c) = -(T_SL / T_PO) * (w_SL - w_c)
// w_Po = w_c - (T_SL/T_PO)*(w_SL - w_c)
ANG_PO_SELF = -(T_SL / T_PO) * (ANG_SL - ANG_CARRIER);
// Pi meshes with Ss and Po: (w_Pi - w_c) = -(T_SS / T_PI) * (w_Ss - w_c)
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

// Planet pin orbital radii (from center)
PO_ORBIT = 31.5;    // long pinion pin orbit radius
PI_ORBIT = 29.5;    // short pinion pin orbit radius

// Washer dimensions (from small_washer.stl: dia=13, h=1.2)
WASHER_OD   = 13;
WASHER_ID   = 6;     // fits over pin shaft (~5mm dia)
WASHER_H    = 1.2;

// ============================================================
// WASHER PLACEMENT MAP — every moving-against-wall interface
// ============================================================
// W1: Ring top lid ↔ Carrier_1 top       → central thrust washer at Z≈30
// W2: Carrier_1 underside ↔ Po gear top  → pin washer x3 at Z≈22 (Po orbit)
// W3: Carrier_1 underside ↔ Pi gear top  → pin washer x3 at Z≈22 (Pi orbit)
// W4: Pi gear bottom ↔ Carrier_3 shelf   → pin washer x3 at Z≈12 (Pi orbit)
// W5: SL top ↔ interface                 → big_sun_ring.stl (already imported)
// W6: Ss top ↔ SL inner bore             → small_sun_ring.stl (already imported)
// W7: Po gear bottom ↔ Carrier_2 top     → STL washer x3 at Z≈0 (Po orbit)
// W8: SL bottom ↔ Carrier_2              → big_sun_ring.stl (already imported)
// W9: Carrier_2 bottom ↔ Ring bottom lid → central thrust washer at Z≈-21.5
//
// Total parametric washers to add: W1 + W2(x3) + W3(x3) + W4(x3) + W7(x3→use STL) + W9 = 14
// Plus existing STL thrust rings: big_sun_ring (W5/W8), small_sun_ring (W6) = already there

// Central thrust washer dims (W1, W9 — larger, between carrier hub and ring lid)
THRUST_WASHER_OD = 40;     // clears carrier hub (~35mm OD)
THRUST_WASHER_ID = 20;     // clears shaft (~10mm)
THRUST_WASHER_H  = 1.2;    // same thickness as small washer

// Carrier_1 dimensions (from planetary_1.stl: dia=78, Z=[-9, 26.5])
CARRIER1_OD      = 78;       // outer dia of carrier_1 plate
CARRIER1_BOSS_OD = 35;       // central hub OD on planetary_1
CARRIER1_ZTOP    = 26.5;     // top face of carrier_1
CARRIER1_HC_ZBOT = 22;       // bottom of honeycomb zone (approx, above gears)
CARRIER1_HC_H    = CARRIER1_ZTOP - CARRIER1_HC_ZBOT;  // 4.5mm honeycomb zone height
// Sun shaft tube OD at bottom
SUN_TUBE_OD      = 33;       // small_sun OD

// Top bearing — hex fill side, wraps around central shaft (10mm)
BEARING_TOP_OD  = 26;          // outer race OD (press-fit into hex fill bore)
BEARING_TOP_ID  = 10;          // inner race ID (fits on central shaft)
BEARING_TOP_H   = RING_WALL;   // sits flush in hex fill

// Bottom bearing — shaft input side, wraps around carrier shaft (~33mm OD)
// Decouples ring extension from carrier shaft rotation
CARRIER_SHAFT_OD = 33;         // carrier_2 hub tube diameter
BEARING_BOT_OD   = 42;         // outer race OD (press-fit into ring seat bore)
BEARING_BOT_ID   = 35;         // inner race ID (clears carrier shaft + 1mm)
BEARING_BOT_H    = RING_WALL;  // sits flush in ring seat

BEARING_CLR   = 0.25;         // clearance

// ============================================================
// RING ENCLOSURE DIMENSIONS
// ============================================================
RING_EXT_SLIDER   = 23;       // [0:1:40] Ring bottom extension height

// Original ring STL: Z=[12, 30], 18mm tall
RING_ORIG_ZBOT = 12;
RING_ORIG_ZTOP = 30;
RING_ORIG_H    = RING_ORIG_ZTOP - RING_ORIG_ZBOT;  // 18

// Extended ring walls — pinion side only
RING_EXT_H     = RING_EXT_SLIDER;  // driven by customizer slider
RING_BOT_Z     = RING_ORIG_ZBOT - RING_EXT_H;  // bottom of ring wall
// Top: 1.6mm above carrier_1 top + 3mm plate
RING_GAP_TOP   = 1.6;       // gap between carrier_1 top and ring top plate
RING_TOP_PLATE = 3;          // thickness of top inward plate
RING_TOP_Z     = CARRIER1_ZTOP + RING_GAP_TOP + RING_TOP_PLATE;  // top of ring wall

// Bottom lid: flat annular wall at Z=RING_BOT_Z
LID_BOT_Z      = RING_BOT_Z;
LID_BOT_H      = RING_WALL;              // 3mm thick
LID_BOT_BORE   = SUN_TUBE_OD + 2 * BEARING_CLR + 2;  // clears sun tube + bearing

// Top lid: SOLID wall (no honeycomb) at top of ring
LID_TOP_Z      = RING_TOP_Z - RING_WALL; // inner face
LID_TOP_H      = RING_WALL;              // 3mm thick
LID_TOP_BORE   = CARRIER1_BOSS_OD + 2 * BEARING_CLR + 2;  // clears carrier hub + bearing

// Ring wall extension zones (added geometry around original STL ring)
RING_ADD_BOT_ZBOT = RING_BOT_Z;
RING_ADD_BOT_ZTOP = RING_ORIG_ZBOT;      // meets original ring
RING_ADD_BOT_H    = RING_ADD_BOT_ZTOP - RING_ADD_BOT_ZBOT;

RING_ADD_TOP_ZBOT = RING_ORIG_ZTOP;      // starts where original ring ends
RING_ADD_TOP_ZTOP = RING_TOP_Z;
RING_ADD_TOP_H    = RING_ADD_TOP_ZTOP - RING_ADD_TOP_ZBOT;

// V-groove
GROOVE_WIDTH   = 4;
GROOVE_DEPTH   = 2;
GROOVE_Z       = (RING_BOT_Z + RING_TOP_Z) / 2;  // center of full enclosure

// ============================================================
// STAGE 2 — INPUT DRIVE SHAFTS + MATING HELICAL GEARS
// ============================================================
// Three long drive shafts, each carrying a helical gear that meshes
// with the corresponding shaft-end gear on the Ravigneaux unit.
// Multiple units stack in series on these shafts.
//
// Gear specs (same family as Ravigneaux internals):
//   Normal module: 0.866mm, Helix: 30°, Transverse module: 1.0mm
//   Pressure angle: 20°
//
// Shaft-end gears (from STL analysis):
//   Ss shaft:      17T, OD=18.75mm, Z=[-53, -37]
//   SL shaft:      23T, OD=25.0mm,  Z=[-38, -14]
//   Carrier shaft: 29T, OD=31.0mm,  Z=[-21.5, bottom]

// Transverse module (for center distance calculations)
TRANS_MOD = 1.0;   // mn / cos(helix) = 0.866 / cos(30°) = 1.0

// Shaft-end tooth counts (measured from STL)
T_SS_SHAFT  = 17;   // small sun input shaft end
T_SL_SHAFT  = 23;   // large sun input shaft end
T_CAR_SHAFT = 29;   // carrier input shaft end

// Drive pinion tooth counts on horizontal shafts
// Shafts run along X/Y (horizontal), meshing with vertical shaft-end gears
T_DRV_SS  = 20;    // pinion on Ss drive shaft
T_DRV_SL  = 20;    // pinion on SL drive shaft
T_DRV_CAR = 20;    // pinion on Carrier drive shaft

// Drive pinion ODs
DRV_SS_OD  = T_DRV_SS  * TRANS_MOD + 2 * 0.866;
DRV_SL_OD  = T_DRV_SL  * TRANS_MOD + 2 * 0.866;
DRV_CAR_OD = T_DRV_CAR * TRANS_MOD + 2 * 0.866;

// Drive shaft diameter (steel rod running through multiple units)
DRV_SHAFT_D = 8;

// Drive pinion face widths = same as mating gear FW (defined later as GEAR_FW=10)
// DRV_*_FW and DRV_*_Z are defined after shaft extension Z values (forward ref)

// Drive shaft angular positions (direction each shaft approaches from)
DRV_SS_ANG  = 0;      // Ss drive shaft along X
DRV_SL_ANG  = 120;    // SL drive shaft at 120°
DRV_CAR_ANG = 240;    // Carrier drive shaft at 240°

// Center distances — shaft-end pitch radius + drive pinion pitch radius
// Shaft-end pitch radii: Ss=17*1/2=8.5, SL=23*1/2=11.5, Car=29*1/2=14.5
// Drive pinion pitch radii: all 20*1/2=10
CD_SS  = (T_SS_SHAFT  + T_DRV_SS)  * TRANS_MOD / 2;  // 18.5mm
CD_SL  = (T_SL_SHAFT  + T_DRV_SL)  * TRANS_MOD / 2;  // 21.5mm
CD_CAR = (T_CAR_SHAFT + T_DRV_CAR) * TRANS_MOD / 2;  // 24.5mm

// Drive shaft visual half-length (extends outward from unit)
DRV_SHAFT_LEN = 120;  // total visible length of horizontal shaft

// Frame anchor shaft (10mm center shaft — structural, non-rotating, vertical)
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
SHOW_CARRIER_1      = false;
SHOW_CARRIER_2      = true;
SHOW_CARRIER_3      = true;
SHOW_RING           = true;
SHOW_WASHERS        = true;   // ALL washers + thrust rings (unified group)
SHOW_CLIPS          = true;   // Retaining clips at all pinion axle ends

SHOW_V_GROOVE       = true;
SHOW_BEARINGS       = true;   // Visual bearing indicators

// ============================================================
// SHAFT EXTENSION LENGTH (adjust these to control exposed shaft)
// ============================================================
CARRIER_SHAFT_EXT = 12.75;    // [5:0.25:20] Carrier extension length
CAR_HUB_LEN       = 16;       // [4:0.5:16] Carrier hub tube length (plain shaft between plate and cap)
SL_HUB_LEN        = 16;       // [4:0.5:16] SL plain shaft length (below gearbox, above spline ext)
SS_HUB_LEN        = 15;       // [4:0.5:15] SS plain shaft length (below SL, above spline ext)
INNER_SHAFT_EXT   = 29;       // [0:0.5:40] Inner rod extension (grows both ends equally)
SL_SHAFT_EXT      = 12.75;    // [5:0.25:20] Big sun extension length
SS_SHAFT_EXT      = 12.75;    // [5:0.25:20] Small sun extension length
SHOW_MOUNT_GEAR     = false;  // Mounting gears (bottom helical mating gears)
SHOW_DRIVE          = false;  // Stage 2 drive shafts + pinions
SHOW_ANCHOR         = false;  // Frame anchor shaft

CROSS_SECTION       = false;
EXPLODE             = 0;

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
C_DRV_SS    = [0.15, 0.55, 0.30];  // green — matches Ss
C_DRV_SL    = [0.76, 0.60, 0.22];  // gold — matches SL
C_DRV_CAR   = [0.55, 0.55, 0.58];  // gray — matches carrier
C_ANCHOR    = [0.70, 0.20, 0.20];  // red — frame anchor

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
// NEW RING — teeth from STL (extracted), rest parametric
// ============================================================
// TEETH_INNER_D clips away center features from STL, keeping only teeth
TEETH_INNER_D = 70;

module new_ring() {
    rotate([0, 0, ANG_RING]) {
        // --- Internal teeth ONLY (extracted from STL) ---
        color(C_RING, 0.11)
        intersection() {
            import(str(STL_DIR, "ring_low_profile.stl"), convexity=4);
            // Clip to annular band: outer=RING_OD (flush with wall), inner=TEETH_INNER_D
            difference() {
                translate([0, 0, RING_ORIG_ZBOT - 0.1])
                cylinder(d=RING_OD, h=RING_ORIG_H + 0.2, $fn=128);
                translate([0, 0, RING_ORIG_ZBOT - 0.2])
                cylinder(d=TEETH_INNER_D, h=RING_ORIG_H + 0.4, $fn=128);
            }
        }

        // --- Outer wall: full height from RING_BOT_Z to RING_TOP_Z ---
        color(C_RING, 0.11)
        zcyl_hollow(RING_OD, RING_ID, RING_BOT_Z, RING_TOP_Z - RING_BOT_Z);

        // --- Bottom inward plate (bearing seat) ---
        color(C_LID, 0.11)
        zcyl_hollow(RING_ID, BEARING_BOT_OD, RING_BOT_Z, RING_WALL);

        // --- Top inward plate (bearing seat) ---
        color(C_LID, 0.11)
        zcyl_hollow(RING_ID, BEARING_TOP_OD, CARRIER1_ZTOP + RING_GAP_TOP, RING_TOP_PLATE);
    }
}

// ============================================================
// INPUT-END SHAFT EXTENSIONS + HELICAL GEARS
// ============================================================
// Unit is flipped 180° around X: pre-flip -Z faces UP (input end).
// Extend each shaft beyond its existing STL end in -Z direction,
// then add helical gear teeth on the extension.
//
// Pre-flip input-end Z positions (face UP after flip):
//   Ss shaft:      Z=-53 (shaft.stl tip)
//   SL shaft:      Z=-38 (big_sun bottom)
//   Carrier shaft: Z=-21.5 (planetary_2 bottom)
//
// Helical gear specs: Normal module=0.866, Helix=30°, PA=20°

// --- Mating gear dimensions (splined bore + helical teeth outside) ---
// Gears sit tight on extensions, lips act as washers between them
GEAR_FW       = 10;                         // gear face width
LIP_H         = 1.5;                        // lip/washer height
LIP_EXTRA     = 4;                          // lip extends outward as washer flange
LIP_GAP       = 0.25;                       // tiny gap between gear top and lip
CHAMFER_TIP   = 1;                          // minimal chamfer at tip

CAR_GEAR_TEETH = 29;
CAR_GEAR_MOD   = 0.866;
CAR_GEAR_HELIX = 30;

// --- Spline parameters ---
// Design basis: involute-inspired straight splines for slide-on mounting gear
// Key: smooth pilot → tapered lead-in → full engagement zone → chamfer out
SPLINE_COUNT   = 6;                         // 6 ridges — good balance of strength vs wall thickness
SPLINE_DEPTH   = 0.6;                       // ridge height above shaft OD (conservative for 3.5mm wall)
SPLINE_DUTY    = 0.45;                      // ridge slightly narrower than gap — easier assembly
SPLINE_LEADIN  = 1.5;                       // tapered entry ramp — ridge grows from 0 to full depth
SPLINE_PILOT   = 0.5;                       // smooth cylinder (no ridges) at shaft tip — guides bore on
SPLINE_CHAMFER_TOP = 0.3;                   // small chamfer at top end of ridges
SPLINE_CLEARANCE = 0.2;                     // per-side clearance in mating bore

// Splined shaft tube: cylinder with longitudinal ridges on the outside
// Zones from bottom (shaft tip) to top:
//   [0, PILOT]                  — smooth pilot, no ridges
//   [PILOT, PILOT+LEADIN]      — tapered lead-in, ridge grows 0→full depth
//   [PILOT+LEADIN, h-CHAMFER]  — full engagement zone
//   [h-CHAMFER, h]             — chamfer out at top
module splined_tube(od, id, h, n_splines=SPLINE_COUNT, depth=SPLINE_DEPTH, duty=SPLINE_DUTY) {
    ridge_ang = 360 / n_splines * duty;
    pilot = min(SPLINE_PILOT, h * 0.1);
    leadin = min(SPLINE_LEADIN, h * 0.25);
    chamfer_top = min(SPLINE_CHAMFER_TOP, h * 0.1);
    z_ridge_start = pilot;
    z_full_start = pilot + leadin;
    z_full_end = h - chamfer_top;

    difference() {
        union() {
            // Base cylinder — smooth full length
            cylinder(d=od, h=h, $fn=64);

            // Spline ridges with tapered lead-in and chamfer-out
            for (i = [0:n_splines-1])
                rotate([0, 0, i * 360 / n_splines])
                rotate_extrude(angle=ridge_ang, $fn=64)
                translate([od/2, 0])
                polygon([
                    // Lead-in taper: starts at zero depth, ramps to full
                    [0,     z_ridge_start],         // base of lead-in (flush with shaft)
                    [depth, z_full_start],           // full depth reached
                    // Full engagement zone
                    [depth, z_full_end],             // full depth ends
                    // Top chamfer: ramps back to zero
                    [0,     h - 0.01],               // flush at top
                ]);
        }
        // Bore
        translate([0, 0, -0.1])
        cylinder(d=id, h=h + 0.2, $fn=64);
    }
}

// Splined bore: cuts matching slots inside a gear bore
// bore_d = shaft OD, slots accept spline ridges with clearance
module splined_bore(bore_d, h, n_splines=SPLINE_COUNT, depth=SPLINE_DEPTH, duty=SPLINE_DUTY, clearance=SPLINE_CLEARANCE) {
    ridge_ang = 360 / n_splines * duty;
    // Main bore — clears shaft OD with clearance
    translate([0, 0, -0.1])
    cylinder(d=bore_d + clearance * 2, h=h + 0.2, $fn=64);
    // Ridge slots — cut deeper and wider than shaft ridges by clearance
    for (i = [0:n_splines-1])
        rotate([0, 0, i * 360 / n_splines])
        rotate_extrude(angle=ridge_ang + 1, $fn=64)  // +1 deg angular clearance
        translate([bore_d/2 - 0.1, -0.1])
        square([depth + clearance + 0.1, h + 0.2]);
}

// --- Carrier shaft extension (outermost tube) ---
// NOTE: CAR_EXT positions computed after CAR_CAP is defined (see below ~line 670)
CAR_EXT_H     = CARRIER_SHAFT_EXT;
CAR_EXT_OD    = 33;                         // match carrier tube OD
CAR_EXT_ID    = 26;                         // clears SL (OD=25) + 0.5mm gap

// --- SL (big sun) shaft extension ---
SL_EXT_H      = SL_SHAFT_EXT;
SL_EXT_ZTOP   = -(GEAR_ZONE_TOP + SL_HUB_LEN); // gearbox bottom - hub length
SL_EXT_ZBOT   = SL_EXT_ZTOP - SL_EXT_H;        // extends below hub
SL_EXT_OD     = 25;                         // match SL shaft OD
SL_EXT_ID     = 20;                         // clears Ss (OD=18.75) + 0.625mm gap

// --- Ss (small sun / inner shaft) extension ---
SS_EXT_H      = SS_SHAFT_EXT;
SS_EXT_ZTOP   = SL_EXT_ZTOP - SS_HUB_LEN;      // below SL hub bottom
SS_EXT_ZBOT   = SS_EXT_ZTOP - SS_EXT_H;         // extends below hub
SS_EXT_OD     = 18.75;                      // match Ss shaft OD
SS_EXT_ID     = 12;                         // hollow bore, 3.375mm wall

// Hand-rolled involute gear 2D profile (no BOSL2)
//
// Strategy: compute each involute flank point using polar coords (r, angle).
// Right flank: involute from base to tip, rotated to position.
// Left flank: mirror of right flank about tooth centerline (negate angle).
// Tip: circular arc at tip_r between flank tips.
// Root: circular arc at root_r between teeth.

// Involute polar form:
//   At roll angle alpha (from base circle tangent point):
//     radius:      r = rb / cos(alpha)
//     polar angle: phi = alpha - atan2(sin(alpha)-alpha_rad*cos(alpha),
//                                      cos(alpha)+alpha_rad*sin(alpha))
//   Simplified: phi(alpha) = atan2(y,x) of the parametric involute point
//     x = rb*(cos(a) + a_rad*sin(a))
//     y = rb*(sin(a) - a_rad*cos(a))

// Returns [radius, polar_angle] for involute at roll angle alpha_deg
function _inv_polar(rb, alpha_deg) =
    let(a_rad = alpha_deg * PI / 180,
        x = rb * (cos(alpha_deg) + a_rad * sin(alpha_deg)),
        y = rb * (sin(alpha_deg) - a_rad * cos(alpha_deg)),
        r = sqrt(x*x + y*y),
        ang = atan2(y, x))
    [r, ang];

module involute_gear_2d(teeth, mod, pressure_angle=20, clearance=0.25) {
    pitch_r  = teeth * mod / 2;
    base_r   = pitch_r * cos(pressure_angle);
    tip_r    = pitch_r + mod;
    root_r   = pitch_r - 1.25 * mod;

    // Roll angle where involute reaches tip circle
    alpha_tip = (base_r < tip_r) ? acos(base_r / tip_r) : 0;

    // Half-tooth thickness angle at pitch circle (degrees)
    // Tooth thickness = pi*m/2, arc angle = thickness / pitch_r (radians) → degrees
    half_tooth_deg = (PI * mod / 2) / pitch_r * (180 / PI) / 2;
    // Simplifies to: 90 / teeth / 2 = 45/teeth ... but let's keep the explicit form

    // Polar angle of involute at the pitch circle
    pitch_polar = _inv_polar(base_r, pressure_angle);
    inv_ang_at_pitch = pitch_polar[1];

    // Rotate right flank so it sits at +half_tooth_deg at the pitch circle
    right_offset = half_tooth_deg - inv_ang_at_pitch;

    steps = 30;

    // Precompute right flank tip polar angle (for tip arc)
    tip_polar = _inv_polar(base_r, alpha_tip);
    right_tip_ang = tip_polar[1] + right_offset;
    // Left flank tip = mirror about 0° → at angle -right_tip_ang
    left_tip_ang = -right_tip_ang;

    union() {
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * 360 / teeth])
            polygon(
                concat(
                    // Root: from gap center (negative side) to right flank base
                    [[root_r * cos(-180/teeth), root_r * sin(-180/teeth)],
                     [root_r * cos(right_offset), root_r * sin(right_offset)]],

                    // Right flank: involute from base to tip
                    [for (s = [0:steps])
                        let(alpha = alpha_tip * s / steps,
                            p = _inv_polar(base_r, alpha),
                            r = p[0],
                            ang = p[1] + right_offset)
                        [r * cos(ang), r * sin(ang)]
                    ],

                    // Tip arc: from right flank tip to left flank tip
                    [for (s = [1:3])
                        let(ang = right_tip_ang + s * (left_tip_ang - right_tip_ang) / 4)
                        [tip_r * cos(ang), tip_r * sin(ang)]
                    ],

                    // Left flank: mirror of right (tip to base)
                    // Mirror about 0°: angle → -angle
                    [for (s = [steps:-1:0])
                        let(alpha = alpha_tip * s / steps,
                            p = _inv_polar(base_r, alpha),
                            r = p[0],
                            ang = -(p[1] + right_offset))
                        [r * cos(ang), r * sin(ang)]
                    ],

                    // Root: from left flank base to gap center (positive side)
                    [[root_r * cos(-right_offset), root_r * sin(-right_offset)],
                     [root_r * cos(180/teeth), root_r * sin(180/teeth)]]
                )
            );
        }
        circle(r=root_r, $fn=teeth * 8);
    }
}

module helical_gear(teeth, mod, helix_angle, height, pressure_angle=20) {
    trans_mod = mod / cos(helix_angle);
    pitch_r = teeth * trans_mod / 2;
    twist = tan(helix_angle) * height / pitch_r * (180 / PI);

    // Center the twist: pre-rotate by -twist/2 so top and bottom faces are symmetric
    rotate([0, 0, -twist/2])
    linear_extrude(height=height, twist=twist, slices=80, convexity=10)
    involute_gear_2d(teeth=teeth, mod=trans_mod, pressure_angle=pressure_angle);
}

// ============================================================
// FULL PARAMETRIC SHAFTS (replace STLs)
// ============================================================
// Each shaft = top helical gear (meshes inside gearbox) + smooth tube +
//              bottom helical gear (meshes with drive pinion) + lip
// All hollow for concentric nesting.
//
// Original STL geometry reference:
//   shaft.stl:        10mm rod, Z≈26 to Z≈-53 (rotates with Ss)
//   small_sun.stl:    Ss 31T gear (Z=0-22) + tube OD=18.75 (Z=0 to -53)
//   big_sun.stl:      SL 38T gear (Z=0-22) + tube OD=25 (Z=0 to -38)
//   planetary_2.stl:  Carrier plate (Z=0 to -9) + tube OD=33 (Z=-9 to -21.5)
//                     plate has 3 pin holes at PO_ORBIT, 3 at PI_ORBIT

// Bottom mating gear tooth counts — root must clear shaft OD + 2mm wall
T_MATE_CAR = 40;
T_MATE_SL  = 32;
T_MATE_SS  = 26;

// Gear zone heights
TOP_GEAR_FW = 10;   // top gear face width (inside gearbox)

// Carrier plate dimensions (measured from planetary_2.stl)
CAR_PLATE_ZTOP = -1.5;        // top face (STL Z=-1.5)
CAR_PLATE_ZBOT = -3.5;        // bottom face of star plate (STL Z=-3.5)
CAR_PLATE_OD   = 80;          // plate outer diameter (STL R_max=40)
CAR_PO_PIN_D   = 8;           // long pinion (Po) pin hole diameter (STL stub D=8.25)
CAR_PI_PIN_D   = 13.4;        // Pi hole clears carrier_3 boss
CAR_PIN_DEPTH  = 2;           // pin hole depth = plate thickness
CAR_HUB_ZTOP   = CAR_PLATE_ZBOT;                 // hub starts at plate bottom
CAR_HUB_ZBOT   = CAR_PLATE_ZBOT - CAR_HUB_LEN;  // hub bottom = plate bottom - hub length
CAR_HUB_OD     = 33;          // hub outer diameter (STL R_max=16.5)
CAR_HUB_ID     = 26;          // hub inner bore (clears SL tube OD=25 + 0.5mm gap)
// Hub tube structure from STL:
//   Z=-3.5 to -6.5:  collar zone (inner R=15.5, wall=1mm)
//   Z=-6.5 to -19.5: tube (OD=33, thin wall)
//   Z=-19.5 to -21.5: bottom cap (annular, R=13.62 to 15.5)
CAR_HUB_COLLAR_Z = -6.5;      // collar transition Z level
CAR_CAP_H     = 2;                                // cap thickness
CAR_CAP_ZTOP  = CAR_HUB_ZBOT;                    // cap top = hub bottom
CAR_CAP_ZBOT  = CAR_HUB_ZBOT - CAR_CAP_H;        // cap bottom
CAR_CAP_OD    = 33;           // match hub tube OD for smooth shaft surface
CAR_CAP_ID    = 27.25;        // cap inner D (STL R=13.62 -> D=27.25)

// Carrier extension Z (must be after CAR_CAP_ZBOT is defined)
CAR_EXT_ZTOP  = CAR_CAP_ZBOT;               // meets cap bottom
CAR_EXT_ZBOT  = CAR_CAP_ZBOT - CAR_EXT_H;   // extends below cap

// Drive pinion Z + FW — centered on bottom mating gears (splined end of shafts)
DRV_SS_FW  = GEAR_FW;
DRV_SL_FW  = GEAR_FW;
DRV_CAR_FW = GEAR_FW;
DRV_SS_Z   = SS_EXT_ZBOT  - GEAR_FW / 2;   // center of SS mating gear
DRV_SL_Z   = SL_EXT_ZBOT  - GEAR_FW / 2;   // center of SL mating gear
DRV_CAR_Z  = CAR_EXT_ZBOT - GEAR_FW / 2;   // center of Carrier mating gear

// Pi pin orbit (measured from short_pinion.stl native position)
PI_ORBIT_ACTUAL = 27.44;      // actual Pi orbit R from STL center
PI_ANG_OFFSET   = 71.5;       // Pi angle offset from 0 deg (not 60!)

// Inner shaft (was shaft.stl — 10mm rod through center)
INNER_SHAFT_D   = 10;
INNER_SHAFT_ZTOP = 26 + INNER_SHAFT_EXT / 2;       // grows up by half
INNER_SHAFT_ZBOT = SS_EXT_ZTOP - INNER_SHAFT_EXT / 2;  // grows down by half

// --- Ss (small sun) — full parametric ---
// Top: splined tube OD=18.75, ID=12 (Z=0 to Z=22, original design)
// Middle: splined tube continues down to lip
// Bottom: 26T mating gear (splined bore inside, helical teeth outside) + lip
module ss_full_shaft() {
    rotate([0, 0, ANG_SS]) {
        // Splined shaft tube (full length: extension bottom to gearbox top)
        color(C_SS)
        translate([0, 0, SS_EXT_ZBOT])
        splined_tube(od=SS_EXT_OD, id=SS_EXT_ID,
            h=GEAR_ZONE_TOP - SS_EXT_ZBOT);

        // Sun gear teeth inside gearbox (Ss = 31T, Z=0 to 22)
        color(C_SS)
        difference() {
            translate([0, 0, GEAR_ZONE_BOT])
            helical_gear(teeth=T_SS, mod=CAR_GEAR_MOD,
                helix_angle=CAR_GEAR_HELIX, height=GEAR_ZONE_TOP - GEAR_ZONE_BOT);
            // Hollow bore matching shaft ID
            translate([0, 0, GEAR_ZONE_BOT - 0.1])
            cylinder(d=SS_EXT_ID, h=GEAR_ZONE_TOP - GEAR_ZONE_BOT + 0.2, $fn=64);
        }

        // Bottom mating gear (splined bore + helical teeth)
        if (SHOW_MOUNT_GEAR)
        color(C_SS)
        difference() {
            translate([0, 0, SS_EXT_ZBOT - GEAR_FW])
            helical_gear(teeth=T_MATE_SS, mod=CAR_GEAR_MOD,
                helix_angle=CAR_GEAR_HELIX, height=GEAR_FW);
            translate([0, 0, SS_EXT_ZBOT - GEAR_FW])
            splined_bore(bore_d=SS_EXT_OD, h=GEAR_FW);
        }

    }
}

// --- SL (big sun) — full parametric ---
// Top: splined tube OD=25, ID=20 (Z=0 to Z=22, original design)
// Middle: splined tube continues down to lip
// Bottom: 32T mating gear (splined bore inside, helical teeth outside) + lip
module sl_full_shaft() {
    rotate([0, 0, ANG_SL]) {
        // Splined shaft tube (full length: extension bottom to gearbox top)
        color(C_SL)
        translate([0, 0, SL_EXT_ZBOT])
        splined_tube(od=SL_EXT_OD, id=SL_EXT_ID,
            h=GEAR_ZONE_TOP - SL_EXT_ZBOT);

        // Sun gear teeth inside gearbox (SL = 38T, Z=0 to 22)
        color(C_SL)
        difference() {
            translate([0, 0, GEAR_ZONE_BOT])
            helical_gear(teeth=T_SL, mod=CAR_GEAR_MOD,
                helix_angle=CAR_GEAR_HELIX, height=GEAR_ZONE_TOP - GEAR_ZONE_BOT);
            // Hollow bore matching shaft ID
            translate([0, 0, GEAR_ZONE_BOT - 0.1])
            cylinder(d=SL_EXT_ID, h=GEAR_ZONE_TOP - GEAR_ZONE_BOT + 0.2, $fn=64);
        }

        // Bottom mating gear (splined bore + helical teeth)
        if (SHOW_MOUNT_GEAR)
        color(C_SL)
        difference() {
            translate([0, 0, SL_EXT_ZBOT - GEAR_FW])
            helical_gear(teeth=T_MATE_SL, mod=CAR_GEAR_MOD,
                helix_angle=CAR_GEAR_HELIX, height=GEAR_FW);
            translate([0, 0, SL_EXT_ZBOT - GEAR_FW])
            splined_bore(bore_d=SL_EXT_OD, h=GEAR_FW);
        }

    }
}

// --- Carrier (planetary_2) — fully parametric (no STL) ---
// Exact reproduction from STL vertex measurements:
//   Plate: Z=-1.5 to -3.5, star profile OD=80, 2mm thick
//   Hub tube: Z=-3.5 to -19.5, OD=33
//   Collar zone: Z=-3.5 to -6.5 (inner R=15.5)
//   Bottom cap: Z=-19.5 to -21.5, annular (R=13.62 to 15.5)
//   PO pin holes: D=8mm at R=31.4, at 0/120/240 deg
//   PI pin holes: D=8mm at R=27.44, at 71.5/191.5/311.5 deg
//   Through bore: D=26 (clears SL tube OD=25)
CAR_PLATE_H = CAR_PLATE_ZTOP - CAR_PLATE_ZBOT;  // 2mm

// 2D star profile polygon — traced from STL R(angle) at Z=-1.5
// 180 points, 2 deg steps, 3-fold symmetry
CAR_PROFILE_PTS = [
    [  40.00,    0.00], [  39.98,    1.40], [  39.90,    2.79],
    [  39.78,    4.18], [  39.61,    5.57], [  39.39,    6.95],
    [  38.82,    8.25], [  38.20,    9.52], [  36.92,   10.59],
    [  35.00,   11.37], [  33.07,   12.04], [  25.70,   10.38],
    [  18.49,    8.23], [  14.83,    7.23], [  14.57,    7.75],
    [  14.29,    8.25], [  13.99,    8.74], [  13.68,    9.23],
    [  13.35,    9.70], [  13.00,   10.16], [  12.64,   10.61],
    [  12.26,   11.04], [  11.87,   11.46], [  13.55,   14.03],
    [  17.08,   18.97], [  20.27,   24.16], [  20.16,   25.81],
    [  19.96,   27.48], [  19.58,   29.02], [  19.02,   30.43],
    [  18.38,   31.84], [  17.43,   32.78], [  16.44,   33.70],
    [  15.37,   34.52], [  14.23,   35.22], [  13.06,   35.89],
    [  11.79,   36.29], [  10.51,   36.66], [   9.20,   36.89],
    [   7.87,   37.01], [   6.54,   37.07], [   5.15,   36.65],
    [   3.80,   36.18], [   2.48,   35.48], [   1.21,   34.54],
    [   0.00,   33.56], [  -1.14,   32.69], [  -2.22,   31.79],
    [  -3.36,   32.01], [  -4.69,   33.34], [  -6.10,   34.62],
    [  -7.64,   35.97], [  -9.29,   37.25], [ -10.85,   37.84],
    [ -12.26,   37.74], [ -13.68,   37.59], [ -14.98,   37.09],
    [ -16.27,   36.54], [ -17.53,   35.95], [ -18.78,   35.32],
    [ -20.00,   34.64], [ -21.20,   33.92], [ -22.37,   33.16],
    [ -23.51,   32.36], [ -24.63,   31.52], [ -25.71,   30.64],
    [ -26.55,   29.49], [ -27.35,   28.32], [ -27.63,   26.68],
    [ -27.35,   24.62], [ -26.96,   22.62], [ -21.84,   17.06],
    [ -16.37,   11.90], [ -13.68,    9.23], [ -13.99,    8.74],
    [ -14.29,    8.25], [ -14.57,    7.75], [ -14.83,    7.23],
    [ -15.07,    6.71], [ -15.30,    6.18], [ -15.50,    5.64],
    [ -15.69,    5.10], [ -15.86,    4.55], [ -18.93,    4.72],
    [ -24.97,    5.31], [ -31.06,    5.48], [ -32.43,    4.56],
    [ -33.78,    3.55], [ -34.92,    2.44], [ -35.86,    1.25],
    [ -36.76,    0.00], [ -37.11,   -1.30], [ -37.40,   -2.62],
    [ -37.58,   -3.95], [ -37.62,   -5.29], [ -37.61,   -6.63],
    [ -37.33,   -7.93], [ -37.00,   -9.23], [ -36.55,  -10.48],
    [ -35.98,  -11.69], [ -35.37,  -12.87], [ -34.32,  -13.86],
    [ -33.24,  -14.80], [ -31.97,  -15.59], [ -30.52,  -16.23],
    [ -29.06,  -16.78], [ -27.74,  -17.33], [ -26.42,  -17.82],
    [ -26.04,  -18.92], [ -26.53,  -20.73], [ -26.93,  -22.59],
    [ -27.33,  -24.60], [ -27.62,  -26.67], [ -27.34,  -28.31],
    [ -26.55,  -29.49], [ -25.71,  -30.64], [ -24.63,  -31.52],
    [ -23.51,  -32.36], [ -22.37,  -33.16], [ -21.20,  -33.92],
    [ -20.00,  -34.64], [ -18.78,  -35.32], [ -17.53,  -35.95],
    [ -16.27,  -36.54], [ -14.98,  -37.09], [ -13.68,  -37.59],
    [ -12.26,  -37.74], [ -10.85,  -37.84], [  -9.29,  -37.27],
    [  -7.65,  -35.99], [  -6.11,  -34.66], [  -3.86,  -27.44],
    [  -2.12,  -20.13], [  -1.15,  -16.46], [  -0.58,  -16.49],
    [  -0.00,  -16.50], [   0.58,  -16.49], [   1.15,  -16.46],
    [   1.72,  -16.41], [   2.30,  -16.34], [   2.87,  -16.25],
    [   3.43,  -16.14], [   3.99,  -16.01], [   5.38,  -18.75],
    [   7.89,  -24.27], [  10.79,  -29.64], [  12.27,  -30.37],
    [  13.81,  -31.03], [  15.35,  -31.46], [  16.85,  -31.68],
    [  18.38,  -31.84], [  19.67,  -31.49], [  20.97,  -31.09],
    [  22.21,  -30.57], [  23.39,  -29.93], [  24.55,  -29.26],
    [  25.54,  -28.36], [  26.49,  -27.43], [  27.35,  -26.41],
    [  28.11,  -25.31], [  28.83,  -24.19], [  29.17,  -22.79],
    [  29.44,  -21.39], [  29.49,  -19.89], [  29.31,  -18.32],
    [  29.06,  -16.78], [  28.88,  -15.36], [  28.64,  -13.97],
    [  29.40,  -13.09], [  31.21,  -12.61], [  33.03,  -12.02],
    [  34.97,  -11.36], [  36.90,  -10.58], [  38.19,   -9.52],
    [  38.81,   -8.25], [  39.39,   -6.95], [  39.61,   -5.57],
    [  39.78,   -4.18], [  39.90,   -2.79], [  39.98,   -1.40]
];

module carrier_plate_2d() {
    polygon(CAR_PROFILE_PTS);
}

module carrier_full_shaft() {
    rotate([0, 0, ANG_CARRIER]) {
        color(C_CAR2)
        difference() {
            union() {
                // === STAR PLATE — exact STL profile, 2mm thick ===
                translate([0, 0, CAR_PLATE_ZBOT])
                linear_extrude(height=CAR_PLATE_H)
                carrier_plate_2d();

                // === HUB TUBE — OD=33 from plate bottom to cap top ===
                translate([0, 0, CAR_CAP_ZTOP])
                cylinder(d=CAR_HUB_OD, h=CAR_HUB_ZTOP - CAR_CAP_ZTOP, $fn=64);

                // === BOTTOM CAP — annular plate closing the tube ===
                // STL: Z=-19.5 to -21.5, R=13.62 to 15.5
                translate([0, 0, CAR_CAP_ZBOT])
                cylinder(d=CAR_CAP_OD, h=CAR_CAP_ZTOP - CAR_CAP_ZBOT, $fn=64);

                // === SPLINED EXTENSION — below STL zone ===
                translate([0, 0, CAR_EXT_ZBOT])
                splined_tube(od=CAR_EXT_OD, id=CAR_EXT_ID,
                    h=CAR_CAP_ZBOT - CAR_EXT_ZBOT);
            }

            // Central bore through hub + plate (D=26, clears SL tube)
            translate([0, 0, CAR_CAP_ZBOT - 0.1])
            cylinder(d=CAR_HUB_ID, h=CAR_PLATE_ZTOP - CAR_CAP_ZBOT + 0.2, $fn=64);

            // Extension bore (same ID=26, continues through spline)
            translate([0, 0, CAR_EXT_ZBOT - 0.1])
            cylinder(d=CAR_EXT_ID, h=CAR_CAP_ZBOT - CAR_EXT_ZBOT + 0.2, $fn=64);

            // Pin holes — 3x long pinion (Po) at PO_ORBIT, D=8mm
            // PO at 0/120/240 deg (matches long_pinion.stl native at angle 0)
            for (i = [0:2])
                rotate([0, 0, i * 120])
                translate([PO_ORBIT, 0, CAR_PLATE_ZBOT - 0.1])
                cylinder(d=CAR_PO_PIN_D, h=CAR_PIN_DEPTH + 0.2, $fn=24);

            // Pin holes — 3x short pinion (Pi) at PI_ORBIT_ACTUAL, D=8mm
            // PI at 71.5/191.5/311.5 deg (matches short_pinion.stl native at 71.5)
            for (i = [0:2])
                rotate([0, 0, i * 120 + PI_ANG_OFFSET])
                translate([PI_ORBIT_ACTUAL, 0, CAR_PLATE_ZBOT - 0.1])
                cylinder(d=CAR_PI_PIN_D, h=CAR_PIN_DEPTH + 0.2, $fn=24);
        }

        // Bottom mating gear (splined bore + helical teeth)
        if (SHOW_MOUNT_GEAR)
        color(C_CAR2)
        difference() {
            translate([0, 0, CAR_EXT_ZBOT - GEAR_FW])
            helical_gear(teeth=T_MATE_CAR, mod=CAR_GEAR_MOD,
                helix_angle=CAR_GEAR_HELIX, height=GEAR_FW);
            translate([0, 0, CAR_EXT_ZBOT - GEAR_FW])
            splined_bore(bore_d=CAR_EXT_OD, h=GEAR_FW);
        }

    }
}

// --- Inner shaft (was shaft.stl) — solid 10mm rod ---
module inner_shaft() {
    rotate([0, 0, ANG_SS])
    color(C_SHAFT)
    translate([0, 0, INNER_SHAFT_ZBOT])
    cylinder(d=INNER_SHAFT_D, h=INNER_SHAFT_ZTOP - INNER_SHAFT_ZBOT, $fn=32);
}

// ============================================================
// BASE STL ASSEMBLY (with animation rotations)
// ============================================================
module base_stl_assembly() {
    // --- Inner shaft (10mm rod) ---
    if (SHOW_SHAFT)
        inner_shaft();

    // --- SMALL SUN (Ss) — Input 2 ---
    if (SHOW_SMALL_SUN)
        ss_full_shaft();

    // --- BIG SUN (SL) — Input 1 ---
    if (SHOW_BIG_SUN)
        sl_full_shaft();

    // --- PLANET GEAR PAIRS x3 — rotate with carrier + self-spin ---
    for (i = [0:2]) {
        ang = i * 120;

        // Long pinion (Po) — orbits with carrier, self-rotates
        if (SHOW_LONG_PINION)
            color(C_PO)
            rotate([0, 0, ANG_CARRIER + ang])
            // Po self-rotation would require rotating around its own pin axis
            // For visual: just orbit with carrier (self-spin hard with STL import)
            import(str(STL_DIR, "long_pinion.stl"), convexity=4);

        // Short pinion (Pi) — orbits with carrier
        if (SHOW_SHORT_PINION)
            color(C_PI)
            rotate([0, 0, ANG_CARRIER + ang])
            import(str(STL_DIR, "short_pinion.stl"), convexity=4);

        // Carrier cage — orbits with carrier
        if (SHOW_CARRIER_3)
            color(C_CAR3)
            rotate([0, 0, ANG_CARRIER + ang])
            import(str(STL_DIR, "planetary_3.stl"), convexity=4);
    }

    // --- CARRIER TOP (planetary_1) — Input 3 ---
    if (SHOW_CARRIER_1)
        color(C_CAR)
        rotate([0, 0, ANG_CARRIER])
        import(str(STL_DIR, "planetary_1.stl"), convexity=4);

    // --- CARRIER BOTTOM (planetary_2) — rotates with carrier ---
    if (SHOW_CARRIER_2)
        carrier_full_shaft();

    // =========================================================
    // WASHERS — original STL imports only
    // =========================================================
    if (SHOW_WASHERS) {
        // Big sun thrust ring
        color(C_WASHER)
        rotate([0, 0, ANG_SL])
        import(str(STL_DIR, "big_sun_ring.stl"), convexity=4);

        // Small sun thrust ring
        color(C_WASHER)
        rotate([0, 0, ANG_SS])
        import(str(STL_DIR, "small_sun_ring.stl"), convexity=4);

        // Single washer STL (native position — print extras for assembly)
        color(C_WASHER)
        rotate([0, 0, ANG_CARRIER])
        import(str(STL_DIR, "small_washer.stl"), convexity=4);

        // Pinion washers — separate parametric objects x3 at Po pin positions
        for (i = [0:2])
            color(C_WASHER)
            rotate([0, 0, ANG_CARRIER + i * 120])
            translate([PO_ORBIT, 0, PO_ZTOP + 0.3])
            zcyl_hollow(WASHER_OD, WASHER_ID, 0, WASHER_H);
    }

    // =========================================================
    // CLIPS — original STL import only
    // =========================================================
    if (SHOW_CLIPS) {
        color(C_CLIP)
        rotate([0, 0, ANG_CARRIER])
        import(str(STL_DIR, "clip.stl"), convexity=4);
    }

}

// ============================================================
// BEARINGS — visual indicators at lid bores (flush against lids)
// ============================================================
// Bottom lid inner face = LID_BOT_Z + LID_BOT_H
// Top: carrier_1 top face = CARRIER1_ZTOP, bearing sits on top of thrust washer
// Stack order bottom: lid → bearing → W9 washer → carrier_2 bottom face (-21.5)
CARRIER2_ZBOT = -21.5;
BEARING_BOT_Z = RING_BOT_Z;                    // flush at bottom plate
BEARING_TOP_Z = CARRIER1_ZTOP + RING_GAP_TOP;  // flush at top plate

module bearings() {
    // Bottom bearing — decouples ring from carrier shaft
    if (SHOW_BEARINGS)
        color(C_BEARING, 0.9)
        zcyl_hollow(BEARING_BOT_OD, BEARING_BOT_ID, BEARING_BOT_Z, BEARING_BOT_H);

    // Top bearing — in hex fill bore, around central shaft
    if (SHOW_BEARINGS)
        color(C_BEARING, 0.9)
        zcyl_hollow(BEARING_TOP_OD, BEARING_TOP_ID, BEARING_TOP_Z, BEARING_TOP_H);
}

// ============================================================
// STAGE 2 DRIVE ASSEMBLY — 3 horizontal drive shafts
// ============================================================
// Each drive shaft runs horizontally (along X/Y plane), approaching
// the unit from its angular position. A helical gear on the shaft
// meshes with the corresponding vertical shaft-end gear.

module drive_pinion(ang, drv_z, gear_teeth, gear_fw, cd, shaft_color, gear_color) {
    rotate([0, 0, ang])
    translate([cd, 0, drv_z])
    rotate([0, 90, 0]) {
        // Drive shaft (horizontal steel rod, centered on gear)
        color(shaft_color)
        translate([0, 0, -DRV_SHAFT_LEN/2])
        cylinder(d=DRV_SHAFT_D, h=DRV_SHAFT_LEN, $fn=32);

        // Helical drive gear (involute teeth, bored for shaft)
        color(gear_color, 0.85)
        difference() {
            translate([0, 0, -gear_fw/2])
            helical_gear(teeth=gear_teeth, mod=CAR_GEAR_MOD,
                helix_angle=CAR_GEAR_HELIX, height=gear_fw);
            translate([0, 0, -gear_fw/2 - 0.1])
            cylinder(d=DRV_SHAFT_D + 0.4, h=gear_fw + 0.2, $fn=32);
        }
    }
}

module drive_assembly() {
    // Ss drive — green, horizontal, offset by CD_SS
    drive_pinion(DRV_SS_ANG, DRV_SS_Z, T_DRV_SS,
                 DRV_SS_FW, CD_SS, C_DRV_SHAFT, C_DRV_SS);

    // SL drive — gold, horizontal, offset by CD_SL
    drive_pinion(DRV_SL_ANG, DRV_SL_Z, T_DRV_SL,
                 DRV_SL_FW, CD_SL, C_DRV_SHAFT, C_DRV_SL);

    // Carrier drive — gray, horizontal, offset by CD_CAR
    drive_pinion(DRV_CAR_ANG, DRV_CAR_Z, T_DRV_CAR,
                 DRV_CAR_FW, CD_CAR, C_DRV_SHAFT, C_DRV_CAR);
}

// Frame anchor shaft — 10mm steel rod through center (non-rotating, vertical)
module anchor_shaft() {
    color(C_ANCHOR)
    zcyl(ANCHOR_SHAFT_D, ANCHOR_SHAFT_ZBOT, ANCHOR_SHAFT_ZTOP - ANCHOR_SHAFT_ZBOT);
}

// ============================================================
// V-GROOVE on ring OD
// ============================================================
module v_groove() {
    rotate([0, 0, ANG_RING]) {
        color(C_RING, 0.9)
        zcyl_hollow(RING_OD + 0.1, RING_OD - 0.1, GROOVE_Z - GROOVE_WIDTH / 2, GROOVE_WIDTH);

        color(C_GROOVE, 0.8)
        translate([0, 0, GROOVE_Z])
        rotate_extrude(convexity=4)
        translate([RING_OD / 2 - GROOVE_DEPTH * 0.3, 0, 0])
        circle(d=GROOVE_WIDTH * 0.5);
    }
}


// ============================================================
// FULL ASSEMBLY
// ============================================================
module hybrid_assembly() {
    base_stl_assembly();

    if (SHOW_RING)            new_ring();
    if (SHOW_V_GROOVE)        v_groove();
    if (SHOW_BEARINGS)        bearings();
    if (SHOW_DRIVE)           drive_assembly();
    if (SHOW_ANCHOR)          anchor_shaft();
}

// ============================================================
// MAIN
// ============================================================
// Flip entire unit: rotate 180° around X so input shafts face up
if (CROSS_SECTION) {
    difference() {
        rotate([180, 0, 0]) hybrid_assembly();
        translate([-200, 0, -200]) cube([400, 200, 400]);
    }
} else {
    rotate([180, 0, 0]) hybrid_assembly();
}

// ============================================================
// ECHO
// ============================================================
echo("==============================================");
echo("  RAVIGNEAUX V12 — Unified Washers + Clips at All Axles");
echo("==============================================");
echo(str("Manual SL=", MANUAL_SL, "  Ss=", MANUAL_SS, "  Carrier=", MANUAL_CARRIER));
echo(str("Input SL:      ", DRIVE_SL_DEG, " deg/cycle → angle=", ANG_SL));
echo(str("Input Ss:      ", DRIVE_SS_DEG, " deg/cycle → angle=", ANG_SS));
echo(str("Input Carrier: ", DRIVE_CARRIER_DEG, " deg/cycle → angle=", ANG_CARRIER));
echo(str("OUTPUT Ring:   angle=", ANG_RING, " (ratio SL→Ring = ", -T_SL/T_RING, ")"));
echo(str("Ring: original STL only (ring_low_profile.stl)"));
echo(str("V-groove: Z=", GROOVE_Z));
echo("Washers: original STLs only (big_sun_ring + small_sun_ring + 1x small_washer)");
echo("Clips: original STL only (1x clip)");
echo("ANIMATION: Use View→Animate (FPS=10, Steps=100) OR drag MANUAL_SL/SS/CARRIER sliders");
