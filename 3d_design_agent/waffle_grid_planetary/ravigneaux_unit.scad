// ============================================================
// RAVIGNEAUX UNIT — Built component-by-component
// ============================================================
// Uses SatisfyingGears 1.7 library for production-quality involute profiles.
// Units: mm, degrees
// ============================================================

// Import gear library (use = modules only, no demo rendering)
use <../gears/satisfying_gears/files/SatisfyingGears1.7.scad>

$fn = 48;

// ============================================================
// GEAR SPECS
// ============================================================
NORM_MOD   = 0.7;
HELIX_ANG  = 25;
TRANS_MOD  = NORM_MOD / cos(HELIX_ANG);   // ~0.773mm
PRESS_ANG  = 20;

// SatisfyingGears uses DiametralPitch = Teeth / PitchDiameter = 1 / module
DP = 1 / TRANS_MOD;   // ~1.294

// Tooth counts — matched to ravigneaux_planets.scad
// Ring constraint: T_RING = T_SL + 2*T_PO = 32 + 48 = 80 ✓ (exact)
// Po-Ss gap = (T_SL - T_SS - 4) / (2*DP) = 0.77mm (was 0 with T_SL=30)
T_SL   = 32;     // Large sun (+2 over 30 for Po-Ss clearance)
T_PO   = 24;     // Long planet (derived from ring constraint)
T_RING = 80;     // Ring gear (internal)
T_SS   = 26;     // Small sun
T_PI   = 19;     // Short planet

// Pitch radii
PR_SS = T_SS / DP / 2;
PR_SL = T_SL / DP / 2;

// Orbits
ORB_PO = (T_SL + T_PO) * TRANS_MOD / 2;
ORB_PI = (T_SS + T_PI) * TRANS_MOD / 2;

// ============================================================
// SHAFT DIMENSIONS
// ============================================================
ANCHOR_D   = 6;       // M6 rod — innermost datum
SS_TUBE_ID = 6.5;     // 0.25mm/side clearance over M6 rod
SS_TUBE_OD = 8;       // 0.75mm wall (min for metal tube stock)
SL_TUBE_ID = 9;       // 0.5mm/side over Ss tube, 0.35mm/side over Ss splines
SL_TUBE_OD = 10.5;    // 0.75mm wall (matches Ss structural minimum)

// ============================================================
// GEAR ZONE LAYOUT (two-zone, vertically offset suns)
// ============================================================
SS_GEAR_FW     = 6;
SL_GEAR_FW     = 6;
THRUST_PLATE_H = 1.5;

SS_ZONE_BOT = 0;
SS_ZONE_TOP = SS_GEAR_FW;                     // 6
SL_ZONE_BOT = SS_ZONE_TOP + THRUST_PLATE_H;   // 7.5
SL_ZONE_TOP = SL_ZONE_BOT + SL_GEAR_FW;       // 13.5
TOTAL_GEAR_H = SL_ZONE_TOP;                    // 13.5

// Shaft Z extents
// Convention: BOTTOM = gear face (shaft endpoint), TOP = spline tip
SS_SHAFT_ZBOT = SS_ZONE_BOT;     // Gear bottom IS shaft bottom
SS_SHAFT_ZTOP = 56;              // Bearing seats + drive coupling

SL_SHAFT_ZBOT = SL_ZONE_BOT;     // Gear bottom IS shaft bottom (same rule as Ss)
SL_SHAFT_ZTOP = 47;              // Shorter than Ss — separate clutch pack height

// ============================================================
// TOLERANCES
// ============================================================
TOL_GENERAL = 0.20;
BACKLASH    = 0.10;    // Production backlash on pitch circle

// ============================================================
// COLORS
// ============================================================
C_SS    = [0.15, 0.55, 0.30];   // Green
C_SL    = [0.76, 0.60, 0.22];   // Gold
C_THRUST = [0.70, 0.55, 0.35];  // Bronze (thrust washers)

// ============================================================
// THRUST WASHER DIMENSIONS
// ============================================================
// Industry standard: bronze or polymer washers at every rotating interface.
// Handles axial thrust from helical gear helix angle forces.
// Sits between Ss gear top face and SL gear bottom face.
THRUST_ID = SS_TUBE_OD + TOL_GENERAL;   // Clears Ss tube OD with running gap
THRUST_OD = (T_SS - 2.5) / DP;          // Inside Ss gear root circle — no mesh interference

// ============================================================
// SPLINE PARAMETERS
// ============================================================
// Per SAE/ANSI B92.1 involute spline proportions for small shafts:
// More teeth, shallower depth — fine-pitch pattern.
SPLINE_COUNT   = 12;     // Fine pitch: more teeth for 9mm OD
SPLINE_DEPTH   = 0.3;    // Shallow — ~3% of OD (industry: 2-5%)
SPLINE_LENGTH  = 8;
SPLINE_CHAMFER = 1.0;    // Lead-in chamfer at entry

// ============================================================
// COMPONENT 1: SMALL SUN (Ss) — ONE UNIFIED SOLID
// ============================================================
// Assembly: goes in FIRST (innermost tube, around anchor rod)
// Bottom = gear face (herringbone, Z=0 to 6)
// Middle = plain shaft tube (bearing seats)
// Top = external splines with lead-in chamfer (drive coupling)
// ALL built as one continuous solid — no gaps, no seams.

module ss_shaft() {
    spline_od  = SS_TUBE_OD + SPLINE_DEPTH;
    tooth_ang  = 360 / SPLINE_COUNT;
    groove_ang = tooth_ang * 0.5;   // 50/50 duty cycle: teeth = grooves
    spline_zbot = SS_SHAFT_ZTOP - SPLINE_LENGTH;

    color(C_SS)
    difference() {
        // === OUTER SHELL (one union — gear + tube + splines) ===
        union() {
            // 1. Shaft tube — full length, continuous
            translate([0, 0, SS_SHAFT_ZBOT])
            cylinder(d=SS_TUBE_OD, h=SS_SHAFT_ZTOP - SS_SHAFT_ZBOT, $fn=48);

            // 2. Gear teeth — herringbone, production involute
            //    PairGears generates centered on Z=0, so offset to zone center
            translate([0, 0, SS_ZONE_BOT + SS_GEAR_FW / 2])
            PairGears(
                TeethA         = T_SS,
                TeethB         = T_SS,       // dummy, not rendered
                BacklashA      = BACKLASH,
                BacklashB      = 0,
                PressureAngle  = PRESS_ANG,
                DiametralPitch = DP,
                Thickness      = SS_GEAR_FW,
                HelixFaceAngle = HELIX_ANG,
                Layers         = 2,          // herringbone
                ChamferThickness = 0.3,
                InnerChamfers  = false,
                GearAExists    = true,
                GearBExists    = false
            );

            // 3. Spline teeth — raised ridges on shaft OD at top
            translate([0, 0, spline_zbot])
            cylinder(d=spline_od, h=SPLINE_LENGTH, $fn=48);
        }

        // === BORE — single subtraction through the entire solid ===
        translate([0, 0, SS_SHAFT_ZBOT - 0.1])
        cylinder(d=SS_TUBE_ID, h=SS_SHAFT_ZTOP - SS_SHAFT_ZBOT + 0.2, $fn=48);

        // === SPLINE GROOVES — cut into the top section ===
        for (i = [0:SPLINE_COUNT - 1])
            rotate([0, 0, i * tooth_ang])
            translate([0, 0, spline_zbot - 0.1])
            linear_extrude(height=SPLINE_LENGTH + 0.2, convexity=2)
            polygon([
                [SS_TUBE_OD / 2 - SPLINE_DEPTH, 0],
                [(spline_od / 2 + 1) * cos(groove_ang / 2),
                 (spline_od / 2 + 1) * sin(groove_ang / 2)],
                [(spline_od / 2 + 1) * cos(-groove_ang / 2),
                 (spline_od / 2 + 1) * sin(-groove_ang / 2)]
            ]);

        // === SPLINE LEAD-IN CHAMFER — taper at top for easy mating ===
        translate([0, 0, SS_SHAFT_ZTOP - SPLINE_CHAMFER])
        difference() {
            cylinder(d=spline_od + 2, h=SPLINE_CHAMFER + 0.1, $fn=48);
            cylinder(d1=spline_od, d2=SS_TUBE_OD - 0.2,
                     h=SPLINE_CHAMFER, $fn=48);
        }
    }
}

// ============================================================
// COMPONENT 2: LARGE SUN (SL) — ONE UNIFIED SOLID
// ============================================================
// Assembly: slides OVER the Ss tube (sleeve around the green shaft)
// Bottom = gear face (SL_ZONE_BOT) — no shaft below gear
// Gear = herringbone in upper zone (SL_ZONE_BOT to SL_ZONE_TOP)
// Middle = plain sleeve tube (bearing seats)
// Top = external splines with lead-in chamfer (drive coupling)
// Bore clears Ss tube OD (SS_TUBE_OD) with running clearance.

module sl_shaft() {
    // SL spline parameters — scaled for SL_TUBE_OD sleeve
    sl_spline_od   = SL_TUBE_OD + SPLINE_DEPTH;
    tooth_ang      = 360 / SPLINE_COUNT;
    groove_ang     = tooth_ang * 0.5;   // 50/50 duty cycle
    spline_zbot    = SL_SHAFT_ZTOP - SPLINE_LENGTH;

    color(C_SL)
    difference() {
        // === OUTER SHELL (one union — tube + gear + splines) ===
        union() {
            // 1. Sleeve tube — full length, continuous
            translate([0, 0, SL_SHAFT_ZBOT])
            cylinder(d=SL_TUBE_OD, h=SL_SHAFT_ZTOP - SL_SHAFT_ZBOT, $fn=48);

            // 2. Gear teeth — herringbone, production involute
            //    PairGears centered on Z=0, offset to SL zone center
            translate([0, 0, SL_ZONE_BOT + SL_GEAR_FW / 2])
            PairGears(
                TeethA         = T_SL,
                TeethB         = T_SL,       // dummy, not rendered
                BacklashA      = BACKLASH,
                BacklashB      = 0,
                PressureAngle  = PRESS_ANG,
                DiametralPitch = DP,
                Thickness      = SL_GEAR_FW,
                HelixFaceAngle = HELIX_ANG,
                Layers         = 2,          // herringbone
                ChamferThickness = 0.3,
                InnerChamfers  = false,
                GearAExists    = true,
                GearBExists    = false
            );

            // 3. Spline teeth — raised ridges on sleeve OD at top
            translate([0, 0, spline_zbot])
            cylinder(d=sl_spline_od, h=SPLINE_LENGTH, $fn=48);
        }

        // === BORE — clears Ss tube OD with running clearance ===
        translate([0, 0, SL_SHAFT_ZBOT - 0.1])
        cylinder(d=SL_TUBE_ID, h=SL_SHAFT_ZTOP - SL_SHAFT_ZBOT + 0.2, $fn=48);

        // === SPLINE GROOVES — cut into the top section ===
        for (i = [0:SPLINE_COUNT - 1])
            rotate([0, 0, i * tooth_ang])
            translate([0, 0, spline_zbot - 0.1])
            linear_extrude(height=SPLINE_LENGTH + 0.2, convexity=2)
            polygon([
                [SL_TUBE_OD / 2 - SPLINE_DEPTH, 0],
                [(sl_spline_od / 2 + 1) * cos(groove_ang / 2),
                 (sl_spline_od / 2 + 1) * sin(groove_ang / 2)],
                [(sl_spline_od / 2 + 1) * cos(-groove_ang / 2),
                 (sl_spline_od / 2 + 1) * sin(-groove_ang / 2)]
            ]);

        // === SPLINE LEAD-IN CHAMFER — taper at top for easy mating ===
        translate([0, 0, SL_SHAFT_ZTOP - SPLINE_CHAMFER])
        difference() {
            cylinder(d=sl_spline_od + 2, h=SPLINE_CHAMFER + 0.1, $fn=48);
            cylinder(d1=sl_spline_od, d2=SL_TUBE_OD - 0.2,
                     h=SPLINE_CHAMFER, $fn=48);
        }
    }
}

// ============================================================
// THRUST WASHER — between Ss gear face and SL gear face
// ============================================================
// Industry standard: bronze thrust washer absorbs axial loads
// from helical gear helix angle. Sits in the gap between zones.
// Free-floating on the Ss tube — both suns rotate against it.
// Production: sintered bronze (SAE 841) or PTFE-lined steel.

module thrust_washer() {
    color(C_THRUST)
    translate([0, 0, SS_ZONE_TOP])
    difference() {
        cylinder(d=THRUST_OD, h=THRUST_PLATE_H, $fn=48);
        translate([0, 0, -0.1])
        cylinder(d=THRUST_ID, h=THRUST_PLATE_H + 0.2, $fn=48);
    }
}

// ============================================================
// DISPLAY TOGGLES — show/hide each component independently
// ============================================================
/* [Display Toggles] */
SHOW_SS      = true;    // Small sun shaft (green)
SHOW_SL      = true;    // Large sun shaft (gold)
SHOW_THRUST  = true;    // Thrust washer (bronze)
SHOW_XSECTION = false;  // Half-section cut view

// ============================================================
// MAIN
// ============================================================
if (SHOW_XSECTION) {
    difference() {
        union() {
            if (SHOW_SS)     ss_shaft();
            if (SHOW_SL)     sl_shaft();
            if (SHOW_THRUST) thrust_washer();
        }
        // Cut away front half to expose bore nesting
        translate([0, -50, -1])
        cube([50, 100, TOTAL_GEAR_H + 80]);
    }
} else {
    if (SHOW_SS)     ss_shaft();
    if (SHOW_SL)     sl_shaft();
    if (SHOW_THRUST) thrust_washer();
}

echo(str("=== COMPONENT 1: Ss SHAFT (approved) ==="));
echo(str("Ss: ", T_SS, "T herringbone, DP=", DP, " PressAng=", PRESS_ANG));
echo(str("PitchDiameter=", T_SS / DP, "mm  (pitch R=", PR_SS, "mm)"));
echo(str("Gear zone: Z=", SS_ZONE_BOT, " to ", SS_ZONE_TOP, " (", SS_GEAR_FW, "mm)"));
echo(str("Shaft: Z=", SS_SHAFT_ZBOT, " to ", SS_SHAFT_ZTOP,
         " (", SS_SHAFT_ZTOP - SS_SHAFT_ZBOT, "mm total)"));

echo(str("=== COMPONENT 2: SL SHAFT (under review) ==="));
echo(str("SL: ", T_SL, "T herringbone, DP=", DP, " PressAng=", PRESS_ANG));
echo(str("PitchDiameter=", T_SL / DP, "mm  (pitch R=", PR_SL, "mm)"));
echo(str("Gear zone: Z=", SL_ZONE_BOT, " to ", SL_ZONE_TOP, " (", SL_GEAR_FW, "mm)"));
echo(str("Shaft: Z=", SL_SHAFT_ZBOT, " to ", SL_SHAFT_ZTOP,
         " (", SL_SHAFT_ZTOP - SL_SHAFT_ZBOT, "mm total)"));
echo(str("Sleeve: OD=", SL_TUBE_OD, " ID=", SL_TUBE_ID,
         " (clears Ss OD=", SS_TUBE_OD, " +", SL_TUBE_ID - SS_TUBE_OD, "mm gap)"));
echo(str("Splines: ", SPLINE_COUNT, "x at Z=",
         SL_SHAFT_ZTOP - SPLINE_LENGTH, "-", SL_SHAFT_ZTOP,
         ", chamfer=", SPLINE_CHAMFER, "mm"));
echo(str("Backlash: ", BACKLASH, "mm"));

echo(str("=== THRUST WASHER ==="));
echo(str("Bronze washer: OD=", THRUST_OD, " ID=", THRUST_ID,
         " H=", THRUST_PLATE_H, "mm"));
echo(str("Position: Z=", SS_ZONE_TOP, " to ", SS_ZONE_TOP + THRUST_PLATE_H,
         " (between Ss gear top and SL gear bottom)"));

echo(str("=== ASSEMBLY CLEARANCE CHECK ==="));
echo(str("SL bore ID=", SL_TUBE_ID, " vs Ss tube OD=", SS_TUBE_OD,
         " → diametral gap=", SL_TUBE_ID - SS_TUBE_OD,
         "mm (", (SL_TUBE_ID - SS_TUBE_OD)/2, "mm/side)"));
echo(str("SL bore ID=", SL_TUBE_ID, " vs Ss spline OD=", SS_TUBE_OD + SPLINE_DEPTH,
         " → diametral gap=", SL_TUBE_ID - (SS_TUBE_OD + SPLINE_DEPTH),
         "mm — SL slides over splines: ",
         SL_TUBE_ID > SS_TUBE_OD + SPLINE_DEPTH ? "OK" : "FAIL"));
