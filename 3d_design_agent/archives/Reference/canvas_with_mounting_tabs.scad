// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT - CANVAS WITH MOUNTING TABS
// Canvas: 350 × 250 mm (full art area)
// Mounts to wooden frame 350 × 250mm via 8 rigid tabs
// Back open for motor/wiring access
// ═══════════════════════════════════════════════════════════════════════════
$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════
// CANVAS DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════
CANVAS_W = 350;
CANVAS_H = 250;
CANVAS_D_MIN = 80;
CANVAS_D_MAX = 100;

// Full canvas is art area (no frame border)
IW = CANVAS_W;  // 350mm
IH = CANVAS_H;  // 250mm

// ═══════════════════════════════════════════════════════════════════════════
// MOUNTING TAB PARAMETERS
// ═══════════════════════════════════════════════════════════════════════════
TAB_EXTENSION = 18;      // How far tab extends beyond canvas edge
TAB_WIDTH = 25;          // Width of tab along canvas edge
TAB_THICKNESS = 6;       // Thickness (Z) of tab base
TAB_GUSSET_HEIGHT = 12;  // Height of reinforcing gusset
TAB_GUSSET_DEPTH = 15;   // Depth of gusset into canvas area

// Wood screw hole
SCREW_HOLE_DIA = 4.0;        // Pilot hole for wood screw
SCREW_HEAD_DIA = 8.0;        // Countersink diameter
SCREW_HEAD_DEPTH = 3.0;      // Countersink depth

// ═══════════════════════════════════════════════════════════════════════════
// TAB POSITIONS (8 total: 4 corners + 4 mid-points)
// Format: [X, Y, rotation_angle]
// X, Y = position on canvas edge
// rotation = which way tab extends (0=right, 90=up, 180=left, 270=down)
// ═══════════════════════════════════════════════════════════════════════════

// Corner tabs (diagonal extension for maximum rigidity)
TAB_CORNER_BL = [0, 0, 225];           // Bottom-left corner
TAB_CORNER_BR = [CANVAS_W, 0, 315];    // Bottom-right corner
TAB_CORNER_TL = [0, CANVAS_H, 135];    // Top-left corner
TAB_CORNER_TR = [CANVAS_W, CANVAS_H, 45]; // Top-right corner

// Mid-point tabs (perpendicular extension)
TAB_MID_BOTTOM = [CANVAS_W/2, 0, 270];        // Bottom center
TAB_MID_TOP = [CANVAS_W/2, CANVAS_H, 90];     // Top center
TAB_MID_LEFT = [0, CANVAS_H/2, 180];          // Left center
TAB_MID_RIGHT = [CANVAS_W, CANVAS_H/2, 0];    // Right center

// All tabs array
ALL_TABS = [
    TAB_CORNER_BL, TAB_CORNER_BR, TAB_CORNER_TL, TAB_CORNER_TR,
    TAB_MID_BOTTOM, TAB_MID_TOP, TAB_MID_LEFT, TAB_MID_RIGHT
];

// ═══════════════════════════════════════════════════════════════════════════
// MOUNTING TAB MODULE (Rigid with gussets)
// ═══════════════════════════════════════════════════════════════════════════
module mounting_tab() {
    // Main tab body
    difference() {
        union() {
            // Tab base plate
            translate([-TAB_WIDTH/2, 0, 0])
            cube([TAB_WIDTH, TAB_EXTENSION, TAB_THICKNESS]);
            
            // Reinforcing gusset (triangular rib for rigidity)
            // Left gusset
            translate([-TAB_WIDTH/2, 0, 0])
            linear_extrude(height = TAB_THICKNESS)
            polygon([
                [0, 0],
                [0, -TAB_GUSSET_DEPTH],
                [TAB_WIDTH * 0.3, 0]
            ]);
            
            // Right gusset
            translate([TAB_WIDTH/2, 0, 0])
            linear_extrude(height = TAB_THICKNESS)
            polygon([
                [0, 0],
                [0, -TAB_GUSSET_DEPTH],
                [-TAB_WIDTH * 0.3, 0]
            ]);
            
            // Vertical reinforcing rib along tab center
            translate([-2, 0, TAB_THICKNESS])
            cube([4, TAB_EXTENSION - 3, TAB_GUSSET_HEIGHT - TAB_THICKNESS]);
            
            // Fillet at base (stronger connection)
            translate([0, 0, 0])
            linear_extrude(height = TAB_THICKNESS)
            polygon([
                [-TAB_WIDTH/2 - 3, -5],
                [-TAB_WIDTH/2, 0],
                [TAB_WIDTH/2, 0],
                [TAB_WIDTH/2 + 3, -5]
            ]);
        }
        
        // Countersunk screw hole
        translate([0, TAB_EXTENSION/2 + 2, -0.1])
        union() {
            // Through hole
            cylinder(d = SCREW_HOLE_DIA, h = TAB_THICKNESS + TAB_GUSSET_HEIGHT + 1);
            // Countersink from top
            translate([0, 0, TAB_THICKNESS + TAB_GUSSET_HEIGHT - SCREW_HEAD_DEPTH])
            cylinder(d1 = SCREW_HOLE_DIA, d2 = SCREW_HEAD_DIA, h = SCREW_HEAD_DEPTH + 0.2);
        }
    }
}

// Corner tab variant (45° angled, extra reinforcement)
module mounting_tab_corner() {
    difference() {
        union() {
            // Tab base plate (slightly larger for corners)
            translate([-TAB_WIDTH/2, 0, 0])
            cube([TAB_WIDTH, TAB_EXTENSION * 1.2, TAB_THICKNESS]);
            
            // Corner gusset (wraps around corner)
            linear_extrude(height = TAB_THICKNESS)
            polygon([
                [-TAB_WIDTH/2, 0],
                [-TAB_WIDTH/2 - 8, -8],
                [TAB_WIDTH/2 + 8, -8],
                [TAB_WIDTH/2, 0]
            ]);
            
            // Vertical rib
            translate([-2.5, 0, TAB_THICKNESS])
            cube([5, TAB_EXTENSION * 1.1, TAB_GUSSET_HEIGHT - TAB_THICKNESS]);
        }
        
        // Countersunk screw hole
        translate([0, TAB_EXTENSION/2 + 4, -0.1])
        union() {
            cylinder(d = SCREW_HOLE_DIA, h = TAB_THICKNESS + TAB_GUSSET_HEIGHT + 1);
            translate([0, 0, TAB_THICKNESS + TAB_GUSSET_HEIGHT - SCREW_HEAD_DEPTH])
            cylinder(d1 = SCREW_HOLE_DIA, d2 = SCREW_HEAD_DIA, h = SCREW_HEAD_DEPTH + 0.2);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// PLACE ALL MOUNTING TABS
// ═══════════════════════════════════════════════════════════════════════════
module all_mounting_tabs() {
    color("#5a5a5a") {
        // Corner tabs (use corner variant)
        translate([TAB_CORNER_BL[0], TAB_CORNER_BL[1], 0])
        rotate([0, 0, TAB_CORNER_BL[2]])
        mounting_tab_corner();
        
        translate([TAB_CORNER_BR[0], TAB_CORNER_BR[1], 0])
        rotate([0, 0, TAB_CORNER_BR[2]])
        mounting_tab_corner();
        
        translate([TAB_CORNER_TL[0], TAB_CORNER_TL[1], 0])
        rotate([0, 0, TAB_CORNER_TL[2]])
        mounting_tab_corner();
        
        translate([TAB_CORNER_TR[0], TAB_CORNER_TR[1], 0])
        rotate([0, 0, TAB_CORNER_TR[2]])
        mounting_tab_corner();
        
        // Mid-point tabs (use standard variant)
        translate([TAB_MID_BOTTOM[0], TAB_MID_BOTTOM[1], 0])
        rotate([0, 0, TAB_MID_BOTTOM[2]])
        mounting_tab();
        
        translate([TAB_MID_TOP[0], TAB_MID_TOP[1], 0])
        rotate([0, 0, TAB_MID_TOP[2]])
        mounting_tab();
        
        translate([TAB_MID_LEFT[0], TAB_MID_LEFT[1], 0])
        rotate([0, 0, TAB_MID_LEFT[2]])
        mounting_tab();
        
        translate([TAB_MID_RIGHT[0], TAB_MID_RIGHT[1], 0])
        rotate([0, 0, TAB_MID_RIGHT[2]])
        mounting_tab();
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CANVAS BASE PLATE (thin backing that tabs attach to)
// ═══════════════════════════════════════════════════════════════════════════
CANVAS_BASE_THICKNESS = 3;  // Thin base plate

module canvas_base() {
    color("#4a7ab0", 0.3)
    cube([CANVAS_W, CANVAS_H, CANVAS_BASE_THICKNESS]);
}

// ═══════════════════════════════════════════════════════════════════════════
// WOODEN FRAME REFERENCE (for visualization only)
// ═══════════════════════════════════════════════════════════════════════════
WOOD_FRAME_DEPTH = 25;      // Depth of wooden frame
WOOD_FRAME_THICKNESS = 20;  // Wood thickness

module wooden_frame_reference() {
    color("#8B4513", 0.3)
    translate([0, 0, -WOOD_FRAME_DEPTH])
    difference() {
        cube([CANVAS_W, CANVAS_H, WOOD_FRAME_DEPTH]);
        translate([WOOD_FRAME_THICKNESS, WOOD_FRAME_THICKNESS, -1])
        cube([CANVAS_W - WOOD_FRAME_THICKNESS*2, 
              CANVAS_H - WOOD_FRAME_THICKNESS*2, 
              WOOD_FRAME_DEPTH + 2]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// ZONE DEFINITIONS (Updated for full canvas area)
// ═══════════════════════════════════════════════════════════════════════════

ZONE_CLIFF = [0, 125, 0, 80];
ZONE_LIGHTHOUSE = [85, 95, 65, 130];
ZONE_CYPRESS = [40, 110, 0, 150];
ZONE_CLIFF_WAVES = [125, 185, 0, 85];
ZONE_OCEAN_WAVES = [175, 350, 0, 80];
ZONE_BOTTOM_GEARS = [190, 350, 0, 50];
ZONE_WIND_PATH = [0, 230, 130, 230];
ZONE_BIG_SWIRL = [100, 185, 100, 170];
ZONE_SMALL_SWIRL = [175, 230, 85, 140];
ZONE_MOON = [220, 300, 135, 210];
ZONE_STARS = [0, 230, 125, 230];
ZONE_SKY_GEARS = [60, 250, 135, 205];
ZONE_BIRD_WIRE = [0, 310, 100, 120];

// Helper functions
function zone_width(zone) = zone[1] - zone[0];
function zone_height(zone) = zone[3] - zone[2];
function zone_center_x(zone) = (zone[0] + zone[1]) / 2;
function zone_center_y(zone) = (zone[2] + zone[3]) / 2;

// ═══════════════════════════════════════════════════════════════════════════
// VISUALIZATION
// ═══════════════════════════════════════════════════════════════════════════
module show_zone(zone, name="", col="red", alpha=0.15) {
    x1 = zone[0]; x2 = zone[1];
    y1 = zone[2]; y2 = zone[3];
    w = x2 - x1;
    h = y2 - y1;
    
    color(col, alpha)
    translate([x1, y1, CANVAS_BASE_THICKNESS + 0.1])
    square([w, h]);
}

module show_all_zones() {
    show_zone(ZONE_CLIFF,        "CLIFF",         "#8B4513", 0.30);
    show_zone(ZONE_LIGHTHOUSE,   "LH",            "#FFD700", 0.40);
    show_zone(ZONE_CYPRESS,      "CYPRESS",       "#228B22", 0.25);
    show_zone(ZONE_CLIFF_WAVES,  "CLIFF WAVES",   "#00CED1", 0.30);
    show_zone(ZONE_OCEAN_WAVES,  "OCEAN",         "#4169E1", 0.20);
    show_zone(ZONE_BOTTOM_GEARS, "GEARS",         "#FF8C00", 0.35);
    show_zone(ZONE_WIND_PATH,    "WIND",          "#9370DB", 0.18);
    show_zone(ZONE_BIG_SWIRL,    "BIG",           "#FF00FF", 0.30);
    show_zone(ZONE_SMALL_SWIRL,  "SMALL",         "#FF69B4", 0.30);
    show_zone(ZONE_MOON,         "MOON",          "#FFD700", 0.35);
    show_zone(ZONE_STARS,        "STARS",         "#AAAAAA", 0.12);
    show_zone(ZONE_SKY_GEARS,    "SKY",           "#FFA500", 0.15);
    show_zone(ZONE_BIRD_WIRE,    "BIRD",          "#696969", 0.40);
}

module show_canvas_outline() {
    color("#333", 0.8)
    translate([0, 0, CANVAS_BASE_THICKNESS + 0.05])
    difference() {
        square([CANVAS_W, CANVAS_H]);
        translate([1, 1]) square([CANVAS_W-2, CANVAS_H-2]);
    }
}

module show_grid(spacing=50) {
    color("gray", 0.2)
    translate([0, 0, CANVAS_BASE_THICKNESS + 0.02])
    for (x = [0 : spacing : CANVAS_W]) {
        translate([x, 0]) square([0.3, CANVAS_H]);
    }
    color("gray", 0.2)
    translate([0, 0, CANVAS_BASE_THICKNESS + 0.02])
    for (y = [0 : spacing : CANVAS_H]) {
        translate([0, y]) square([CANVAS_W, 0.3]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// Canvas base plate
canvas_base();

// Mounting tabs
all_mounting_tabs();

// Wooden frame reference (comment out to hide)
wooden_frame_reference();

// Zone visualization
show_grid(50);
show_all_zones();
show_canvas_outline();

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT - CANVAS WITH MOUNTING TABS");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas: ", CANVAS_W, " × ", CANVAS_H, " mm (full art area)");
echo("Depth: ", CANVAS_D_MIN, "-", CANVAS_D_MAX, " mm");
echo("");
echo("MOUNTING SYSTEM:");
echo("  - 8 rigid tabs (4 corners + 4 mid-points)");
echo("  - Tab extension: ", TAB_EXTENSION, " mm beyond canvas edge");
echo("  - Tab width: ", TAB_WIDTH, " mm");
echo("  - Tab thickness: ", TAB_THICKNESS, " mm with ", TAB_GUSSET_HEIGHT, " mm gussets");
echo("  - Screw hole: ", SCREW_HOLE_DIA, " mm (countersunk ", SCREW_HEAD_DIA, " mm)");
echo("");
echo("WOODEN FRAME: 350 × 250 mm outer");
echo("BACK: Open for motor/wiring access");
echo("═══════════════════════════════════════════════════════════════════════");
