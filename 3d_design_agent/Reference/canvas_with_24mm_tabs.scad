// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT - CANVAS WITH 24mm MOUNTING TABS
// ═══════════════════════════════════════════════════════════════════════════
// Total printed: 350 × 250 mm (fits 350mm print bed)
// Canvas art area: 302 × 202 mm
// Mounting tabs: 24mm wide (matches wood frame)
// L-shaped corner tabs for maximum rigidity
// Screws go DOWN into wood frame
// ═══════════════════════════════════════════════════════════════════════════
$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════
// DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════

// Print bed constraint
PRINT_BED_MAX = 350;

// Wooden frame
WOOD_FRAME_OUTER_W = 350;
WOOD_FRAME_OUTER_H = 250;
WOOD_WIDTH = 24;  // Wood frame width on all sides

// Canvas art area (inside wooden frame opening)
CANVAS_W = WOOD_FRAME_OUTER_W - WOOD_WIDTH * 2;  // 302mm
CANVAS_H = WOOD_FRAME_OUTER_H - WOOD_WIDTH * 2;  // 202mm

// Total printed piece (canvas + tabs)
TOTAL_W = CANVAS_W + WOOD_WIDTH * 2;  // 350mm
TOTAL_H = CANVAS_H + WOOD_WIDTH * 2;  // 250mm

// Verify fits print bed
echo("PRINT CHECK: Total width =", TOTAL_W, "mm (max", PRINT_BED_MAX, ")");
echo("PRINT CHECK: Total height =", TOTAL_H, "mm");

// Tab dimensions
TAB_WIDTH = WOOD_WIDTH;       // 24mm - matches wood exactly
TAB_THICKNESS = 5;            // Base thickness
TAB_RIB_HEIGHT = 10;          // Reinforcing rib height
TAB_RIB_WIDTH = 4;            // Rib width

// Screw holes
SCREW_HOLE_DIA = 4.0;
SCREW_HEAD_DIA = 8.0;
SCREW_HEAD_DEPTH = 2.5;

// Canvas base
CANVAS_BASE_THICKNESS = 3;

// Depth
CANVAS_DEPTH_MIN = 80;
CANVAS_DEPTH_MAX = 100;

// ═══════════════════════════════════════════════════════════════════════════
// SCREW HOLE MODULE (countersunk)
// ═══════════════════════════════════════════════════════════════════════════
module screw_hole() {
    translate([0, 0, -1]) {
        // Through hole
        cylinder(d=SCREW_HOLE_DIA, h=TAB_THICKNESS + TAB_RIB_HEIGHT + 2);
        // Countersink
        translate([0, 0, TAB_THICKNESS + TAB_RIB_HEIGHT - SCREW_HEAD_DEPTH + 1])
        cylinder(d1=SCREW_HOLE_DIA, d2=SCREW_HEAD_DIA, h=SCREW_HEAD_DEPTH + 1);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// L-SHAPED CORNER TAB (catches both edges of wood)
// ═══════════════════════════════════════════════════════════════════════════
CORNER_LEG_LENGTH = 50;  // Length of each L-leg along wood

module corner_tab_L() {
    difference() {
        union() {
            // L-shaped base plate
            // Horizontal leg
            cube([CORNER_LEG_LENGTH, TAB_WIDTH, TAB_THICKNESS]);
            // Vertical leg
            cube([TAB_WIDTH, CORNER_LEG_LENGTH, TAB_THICKNESS]);
            
            // Reinforcing ribs on horizontal leg
            translate([5, TAB_WIDTH/2 - TAB_RIB_WIDTH/2, TAB_THICKNESS])
            cube([CORNER_LEG_LENGTH - 10, TAB_RIB_WIDTH, TAB_RIB_HEIGHT - TAB_THICKNESS]);
            
            // Reinforcing ribs on vertical leg
            translate([TAB_WIDTH/2 - TAB_RIB_WIDTH/2, 5, TAB_THICKNESS])
            cube([TAB_RIB_WIDTH, CORNER_LEG_LENGTH - 10, TAB_RIB_HEIGHT - TAB_THICKNESS]);
            
            // Corner reinforcement block
            cube([TAB_WIDTH + 5, TAB_WIDTH + 5, TAB_RIB_HEIGHT]);
            
            // Diagonal brace at corner
            translate([0, 0, TAB_THICKNESS])
            linear_extrude(TAB_RIB_HEIGHT - TAB_THICKNESS)
            polygon([
                [TAB_WIDTH, TAB_WIDTH],
                [TAB_WIDTH + 10, TAB_WIDTH],
                [TAB_WIDTH, TAB_WIDTH + 10]
            ]);
        }
        
        // Screw hole in horizontal leg
        translate([CORNER_LEG_LENGTH - 15, TAB_WIDTH/2, 0])
        screw_hole();
        
        // Screw hole in vertical leg
        translate([TAB_WIDTH/2, CORNER_LEG_LENGTH - 15, 0])
        screw_hole();
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// EDGE TAB (mid-point of each edge)
// ═══════════════════════════════════════════════════════════════════════════
EDGE_TAB_LENGTH = 60;  // Length along canvas edge

module edge_tab() {
    difference() {
        union() {
            // Base plate - full 24mm width on wood
            translate([-EDGE_TAB_LENGTH/2, 0, 0])
            cube([EDGE_TAB_LENGTH, TAB_WIDTH, TAB_THICKNESS]);
            
            // Reinforcing rib along center
            translate([-EDGE_TAB_LENGTH/2 + 8, TAB_WIDTH/2 - TAB_RIB_WIDTH/2, TAB_THICKNESS])
            cube([EDGE_TAB_LENGTH - 16, TAB_RIB_WIDTH, TAB_RIB_HEIGHT - TAB_THICKNESS]);
            
            // End ribs for extra rigidity
            translate([-EDGE_TAB_LENGTH/2 + 3, 3, TAB_THICKNESS])
            cube([TAB_RIB_WIDTH, TAB_WIDTH - 6, TAB_RIB_HEIGHT - TAB_THICKNESS]);
            
            translate([EDGE_TAB_LENGTH/2 - 3 - TAB_RIB_WIDTH, 3, TAB_THICKNESS])
            cube([TAB_RIB_WIDTH, TAB_WIDTH - 6, TAB_RIB_HEIGHT - TAB_THICKNESS]);
        }
        
        // Center screw hole
        translate([0, TAB_WIDTH/2, 0])
        screw_hole();
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// CANVAS BASE PLATE
// ═══════════════════════════════════════════════════════════════════════════
module canvas_base() {
    color("#4a7ab0", 0.4)
    translate([TAB_WIDTH, TAB_WIDTH, 0])
    cube([CANVAS_W, CANVAS_H, CANVAS_BASE_THICKNESS]);
}

// ═══════════════════════════════════════════════════════════════════════════
// ALL MOUNTING TABS ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════
module all_mounting_tabs() {
    color("#555555") {
        // CORNER TABS (L-shaped)
        
        // Bottom-Left corner
        translate([0, 0, 0])
        corner_tab_L();
        
        // Bottom-Right corner (mirror X)
        translate([TOTAL_W, 0, 0])
        mirror([1, 0, 0])
        corner_tab_L();
        
        // Top-Left corner (mirror Y)
        translate([0, TOTAL_H, 0])
        mirror([0, 1, 0])
        corner_tab_L();
        
        // Top-Right corner (mirror X and Y)
        translate([TOTAL_W, TOTAL_H, 0])
        mirror([1, 0, 0])
        mirror([0, 1, 0])
        corner_tab_L();
        
        // EDGE TABS (mid-points)
        
        // Bottom edge center
        translate([TOTAL_W/2, 0, 0])
        rotate([0, 0, 0])
        edge_tab();
        
        // Top edge center
        translate([TOTAL_W/2, TOTAL_H, 0])
        rotate([0, 0, 180])
        edge_tab();
        
        // Left edge center
        translate([0, TOTAL_H/2, 0])
        rotate([0, 0, 90])
        edge_tab();
        
        // Right edge center
        translate([TOTAL_W, TOTAL_H/2, 0])
        rotate([0, 0, -90])
        edge_tab();
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// WOODEN FRAME REFERENCE (for visualization)
// ═══════════════════════════════════════════════════════════════════════════
WOOD_FRAME_DEPTH = 30;

module wooden_frame_reference() {
    color("#8B4513", 0.35)
    translate([0, 0, -WOOD_FRAME_DEPTH])
    difference() {
        cube([WOOD_FRAME_OUTER_W, WOOD_FRAME_OUTER_H, WOOD_FRAME_DEPTH]);
        // Inner opening for canvas
        translate([WOOD_WIDTH, WOOD_WIDTH, -1])
        cube([CANVAS_W, CANVAS_H, WOOD_FRAME_DEPTH + 2]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// ZONE DEFINITIONS (Updated for 302 × 202 canvas)
// All coordinates relative to canvas origin (not total piece)
// ═══════════════════════════════════════════════════════════════════════════

// Scale factor from original 350×250 to new 302×202
SCALE_X = CANVAS_W / 350;  // 0.863
SCALE_Y = CANVAS_H / 250;  // 0.808

// Zones scaled to new canvas size
ZONE_CLIFF = [0 * SCALE_X, 125 * SCALE_X, 0 * SCALE_Y, 80 * SCALE_Y];
ZONE_LIGHTHOUSE = [85 * SCALE_X, 95 * SCALE_X, 65 * SCALE_Y, 130 * SCALE_Y];
ZONE_CYPRESS = [40 * SCALE_X, 110 * SCALE_X, 0 * SCALE_Y, 150 * SCALE_Y];
ZONE_CLIFF_WAVES = [125 * SCALE_X, 185 * SCALE_X, 0 * SCALE_Y, 85 * SCALE_Y];
ZONE_OCEAN_WAVES = [175 * SCALE_X, 302, 0 * SCALE_Y, 80 * SCALE_Y];
ZONE_BOTTOM_GEARS = [190 * SCALE_X, 302, 0 * SCALE_Y, 50 * SCALE_Y];
ZONE_WIND_PATH = [0 * SCALE_X, 230 * SCALE_X, 130 * SCALE_Y, 202];
ZONE_BIG_SWIRL = [100 * SCALE_X, 185 * SCALE_X, 100 * SCALE_Y, 170 * SCALE_Y];
ZONE_SMALL_SWIRL = [175 * SCALE_X, 230 * SCALE_X, 85 * SCALE_Y, 140 * SCALE_Y];
ZONE_MOON = [220 * SCALE_X, 300 * SCALE_X, 135 * SCALE_Y, 202];
ZONE_STARS = [0 * SCALE_X, 230 * SCALE_X, 125 * SCALE_Y, 202];
ZONE_SKY_GEARS = [60 * SCALE_X, 250 * SCALE_X, 135 * SCALE_Y, 202];
ZONE_BIRD_WIRE = [0, 302, 100 * SCALE_Y, 120 * SCALE_Y];

// Helper functions
function zone_width(zone) = zone[1] - zone[0];
function zone_height(zone) = zone[3] - zone[2];
function zone_center_x(zone) = (zone[0] + zone[1]) / 2;
function zone_center_y(zone) = (zone[2] + zone[3]) / 2;

// ═══════════════════════════════════════════════════════════════════════════
// VISUALIZATION MODULES
// ═══════════════════════════════════════════════════════════════════════════
module show_zone(zone, name="", col="red", alpha=0.15) {
    w = zone[1] - zone[0];
    h = zone[3] - zone[2];
    
    // Offset by TAB_WIDTH since zones are relative to canvas, not total
    color(col, alpha)
    translate([TAB_WIDTH + zone[0], TAB_WIDTH + zone[2], CANVAS_BASE_THICKNESS + 0.1])
    square([w, h]);
}

module show_all_zones() {
    show_zone(ZONE_CLIFF,        "CLIFF",         "#8B4513", 0.30);
    show_zone(ZONE_LIGHTHOUSE,   "LH",            "#FFD700", 0.40);
    show_zone(ZONE_CYPRESS,      "CYPRESS",       "#228B22", 0.25);
    show_zone(ZONE_CLIFF_WAVES,  "CLIFF_WAVES",   "#00CED1", 0.30);
    show_zone(ZONE_OCEAN_WAVES,  "OCEAN",         "#4169E1", 0.20);
    show_zone(ZONE_BOTTOM_GEARS, "GEARS",         "#FF8C00", 0.35);
    show_zone(ZONE_WIND_PATH,    "WIND",          "#9370DB", 0.18);
    show_zone(ZONE_BIG_SWIRL,    "BIG",           "#FF00FF", 0.30);
    show_zone(ZONE_SMALL_SWIRL,  "SMALL",         "#FF69B4", 0.30);
    show_zone(ZONE_MOON,         "MOON",          "#FFD700", 0.35);
    show_zone(ZONE_STARS,        "STARS",         "#AAAAAA", 0.10);
    show_zone(ZONE_SKY_GEARS,    "SKY",           "#FFA500", 0.12);
    show_zone(ZONE_BIRD_WIRE,    "BIRD",          "#696969", 0.40);
}

module show_canvas_outline() {
    // Canvas boundary
    color("#333", 0.9)
    translate([TAB_WIDTH, TAB_WIDTH, CANVAS_BASE_THICKNESS + 0.05])
    difference() {
        square([CANVAS_W, CANVAS_H]);
        translate([1, 1]) square([CANVAS_W - 2, CANVAS_H - 2]);
    }
    
    // Total piece boundary
    color("#999", 0.5)
    translate([0, 0, 0.02])
    difference() {
        square([TOTAL_W, TOTAL_H]);
        translate([1, 1]) square([TOTAL_W - 2, TOTAL_H - 2]);
    }
}

module show_grid(spacing=50) {
    color("gray", 0.2)
    translate([TAB_WIDTH, TAB_WIDTH, CANVAS_BASE_THICKNESS + 0.02]) {
        for (x = [0 : spacing : CANVAS_W]) {
            translate([x, 0]) square([0.3, CANVAS_H]);
        }
        for (y = [0 : spacing : CANVAS_H]) {
            translate([0, y]) square([CANVAS_W, 0.3]);
        }
    }
}

module show_dimensions() {
    color("black") {
        // Total width dimension
        translate([0, -15, 0])
        linear_extrude(1) text(str(TOTAL_W, "mm total"), size=6);
        
        // Canvas width
        translate([TAB_WIDTH, -8, 0])
        linear_extrude(1) text(str(CANVAS_W, "mm canvas"), size=5);
        
        // Tab width
        translate([2, TOTAL_H/2, 0])
        rotate([0, 0, 90])
        linear_extrude(1) text(str(TAB_WIDTH, "mm tab"), size=5);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN ASSEMBLY
// ═══════════════════════════════════════════════════════════════════════════

// Canvas base
canvas_base();

// Mounting tabs
all_mounting_tabs();

// Wooden frame reference (comment out to hide)
wooden_frame_reference();

// Visualization
show_grid(50);
show_all_zones();
show_canvas_outline();
show_dimensions();

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT - CANVAS WITH MOUNTING TABS");
echo("═══════════════════════════════════════════════════════════════════════");
echo("");
echo("DIMENSIONS:");
echo("  Total printed piece:", TOTAL_W, "×", TOTAL_H, "mm (fits 350mm print bed)");
echo("  Canvas art area:", CANVAS_W, "×", CANVAS_H, "mm");
echo("  Tab width:", TAB_WIDTH, "mm (matches wood frame)");
echo("");
echo("WOODEN FRAME:");
echo("  Outer:", WOOD_FRAME_OUTER_W, "×", WOOD_FRAME_OUTER_H, "mm");
echo("  Wood width:", WOOD_WIDTH, "mm");
echo("  Inner opening:", CANVAS_W, "×", CANVAS_H, "mm");
echo("");
echo("MOUNTING:");
echo("  4 L-shaped corner tabs (leg length:", CORNER_LEG_LENGTH, "mm)");
echo("  4 edge tabs (length:", EDGE_TAB_LENGTH, "mm)");
echo("  Total: 12 screw holes");
echo("  Screw hole:", SCREW_HOLE_DIA, "mm pilot,", SCREW_HEAD_DIA, "mm countersink");
echo("");
echo("ZONES: Scaled by", SCALE_X, "×", SCALE_Y, "from original");
echo("═══════════════════════════════════════════════════════════════════════");
