// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT - CANVAS LAYOUT & ZONING SYSTEM
// Define XY plane boundaries for all elements
// ═══════════════════════════════════════════════════════════════════════════
$fn = 32;

// ═══════════════════════════════════════════════════════════════════════════
// MASTER CANVAS DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════
CANVAS_W = 350;
CANVAS_H = 275;
FRAME_W = 20;

// Inner canvas (where all content lives)
INNER_X_MIN = 0;
INNER_X_MAX = CANVAS_W - FRAME_W * 2;  // 310
INNER_Y_MIN = 0;
INNER_Y_MAX = CANVAS_H - FRAME_W * 2;  // 235

IW = INNER_X_MAX;  // 310mm
IH = INNER_Y_MAX;  // 235mm

// ═══════════════════════════════════════════════════════════════════════════
//                         ZONE DEFINITIONS
// Each zone defines: [X_MIN, X_MAX, Y_MIN, Y_MAX]
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: CLIFF
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CLIFF = [
    0,          // X_MIN: Left edge of inner canvas
    165,        // X_MAX: Cliff extends to 165mm (rect 100 + triangle 65)
    0,          // Y_MIN: Bottom of canvas
    85          // Y_MAX: Cliff height (reduced)
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: LIGHTHOUSE (on top of cliff)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_LIGHTHOUSE = [
    20,         // X_MIN
    55,         // X_MAX
    70,         // Y_MIN: Near top of cliff
    140         // Y_MAX: Lighthouse height above cliff
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: CYPRESS TREE
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CYPRESS = [
    50,         // X_MIN: Left boundary (moved left 100mm from before)
    140,        // X_MAX: Right boundary
    0,          // Y_MIN: Touching bottom frame
    180         // Y_MAX: Tree top (30% bigger)
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: CLIFF WAVES (breaking/spray zone)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CLIFF_WAVES = [
    140,        // X_MIN: Just past cliff edge
    200,        // X_MAX: Breaking zone width
    0,          // Y_MIN: Water level
    120         // Y_MAX: Spray can reach high
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: OCEAN WAVES (open water)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_OCEAN_WAVES = [
    180,        // X_MIN: After cliff wave zone
    IW,         // X_MAX: Right edge
    0,          // Y_MIN: Bottom
    80          // Y_MAX: Wave height limit
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: BOTTOM GEARS
// ─────────────────────────────────────────────────────────────────────────────
ZONE_BOTTOM_GEARS = [
    IW * 0.50,  // X_MIN: Start at 50% width
    IW * 0.98,  // X_MAX: Near right edge
    0,          // Y_MIN: Bottom
    IH * 0.12   // Y_MAX: Low height band
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: WIND PATH (swirling sky element)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_WIND_PATH = [
    0,          // X_MIN: Touches left edge
    IW * 0.75,  // X_MAX: Extends ~75% across
    IH * 0.35,  // Y_MIN: Lower sky
    IH * 0.85   // Y_MAX: Upper sky
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: BIG SWIRL DISC (within wind path)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_BIG_SWIRL = [
    IW * 0.12,  // X_MIN
    IW * 0.38,  // X_MAX
    IH * 0.48,  // Y_MIN
    IH * 0.78   // Y_MAX
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: SMALL SWIRL DISC (within wind path)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_SMALL_SWIRL = [
    IW * 0.36,  // X_MIN
    IW * 0.58,  // X_MAX
    IH * 0.40,  // Y_MIN
    IH * 0.65   // Y_MAX
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: MOON (top right)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_MOON = [
    IW * 0.75,  // X_MIN
    IW * 1.0,   // X_MAX: Right edge
    IH * 0.65,  // Y_MIN
    IH * 1.0    // Y_MAX: Top edge
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: STARS (scattered across sky, avoiding moon)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_STARS = [
    IW * 0.05,  // X_MIN
    IW * 0.75,  // X_MAX: Stop before moon
    IH * 0.60,  // Y_MIN: Upper portion
    IH * 0.98   // Y_MAX: Near top
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: SKY GEARS (decorative foreground gears)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_SKY_GEARS = [
    IW * 0.20,  // X_MIN
    IW * 0.80,  // X_MAX
    IH * 0.65,  // Y_MIN
    IH * 0.98   // Y_MAX
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: BIRD WIRE (horizontal band)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_BIRD_WIRE = [
    0,          // X_MIN: Left edge
    IW,         // X_MAX: Right edge (full width)
    IH * 0.48,  // Y_MIN
    IH * 0.58   // Y_MAX: Narrow band
];

// ═══════════════════════════════════════════════════════════════════════════
//                         HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

// Get zone dimensions
function zone_x_min(zone) = zone[0];
function zone_x_max(zone) = zone[1];
function zone_y_min(zone) = zone[2];
function zone_y_max(zone) = zone[3];
function zone_width(zone) = zone[1] - zone[0];
function zone_height(zone) = zone[3] - zone[2];
function zone_center_x(zone) = (zone[0] + zone[1]) / 2;
function zone_center_y(zone) = (zone[2] + zone[3]) / 2;

// Position within zone (0-1 normalized coordinates)
function zone_x(zone, pct) = zone[0] + (zone[1] - zone[0]) * pct;
function zone_y(zone, pct) = zone[2] + (zone[3] - zone[2]) * pct;

// Check if point is inside zone
function in_zone(zone, x, y) = 
    x >= zone[0] && x <= zone[1] && y >= zone[2] && y <= zone[3];

// ═══════════════════════════════════════════════════════════════════════════
//                         VISUALIZATION MODULES
// ═══════════════════════════════════════════════════════════════════════════

// Draw a zone boundary (for debugging/layout preview)
module show_zone(zone, name="", col="red", alpha=0.15) {
    x1 = zone[0]; x2 = zone[1];
    y1 = zone[2]; y2 = zone[3];
    w = x2 - x1;
    h = y2 - y1;
    
    // Filled area
    color(col, alpha)
    translate([x1, y1, 0])
    square([w, h]);
    
    // Border
    color(col, 0.8)
    translate([x1, y1, 0.1])
    difference() {
        square([w, h]);
        translate([1, 1]) square([w-2, h-2]);
    }
    
    // Label
    if (name != "") {
        color(col)
        translate([x1 + 2, y2 - 10, 0.2])
        linear_extrude(0.5)
        text(name, size=6, font="Liberation Sans:style=Bold");
    }
}

// Show all zones with different colors
module show_all_zones() {
    show_zone(ZONE_CLIFF,        "CLIFF",        "brown",   0.20);
    show_zone(ZONE_LIGHTHOUSE,   "LIGHTHOUSE",   "yellow",  0.25);
    show_zone(ZONE_CYPRESS,      "CYPRESS",      "green",   0.20);
    show_zone(ZONE_CLIFF_WAVES,  "CLIFF WAVES",  "cyan",    0.20);
    show_zone(ZONE_OCEAN_WAVES,  "OCEAN WAVES",  "blue",    0.15);
    show_zone(ZONE_BOTTOM_GEARS, "BOTTOM GEARS", "orange",  0.25);
    show_zone(ZONE_WIND_PATH,    "WIND PATH",    "purple",  0.12);
    show_zone(ZONE_BIG_SWIRL,    "BIG SWIRL",    "magenta", 0.25);
    show_zone(ZONE_SMALL_SWIRL,  "SMALL SWIRL",  "magenta", 0.25);
    show_zone(ZONE_MOON,         "MOON",         "gold",    0.25);
    show_zone(ZONE_STARS,        "STARS",        "white",   0.10);
    show_zone(ZONE_SKY_GEARS,    "SKY GEARS",    "orange",  0.10);
    show_zone(ZONE_BIRD_WIRE,    "BIRD WIRE",    "gray",    0.30);
}

// Canvas frame reference
module show_canvas_frame() {
    color("#5a4030", 0.5)
    difference() {
        square([IW, IH]);
        translate([2, 2]) square([IW-4, IH-4]);
    }
}

// Grid overlay (optional)
module show_grid(spacing=50) {
    color("gray", 0.2) {
        // Vertical lines
        for (x = [0 : spacing : IW]) {
            translate([x, 0, 0])
            square([0.5, IH]);
        }
        // Horizontal lines
        for (y = [0 : spacing : IH]) {
            translate([0, y, 0])
            square([IW, 0.5]);
        }
    }
    // Labels
    color("gray", 0.5) {
        for (x = [0 : spacing : IW]) {
            translate([x, -8, 0])
            linear_extrude(0.5)
            text(str(x), size=5);
        }
        for (y = [0 : spacing : IH]) {
            translate([-15, y, 0])
            linear_extrude(0.5)
            text(str(y), size=5);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                    USAGE EXAMPLE MODULES
// ═══════════════════════════════════════════════════════════════════════════

// Example: Position an element at zone center
module example_centered_in_zone(zone) {
    cx = zone_center_x(zone);
    cy = zone_center_y(zone);
    translate([cx, cy, 1])
    color("red")
    circle(r=5);
}

// Example: Fill a zone with scaled element
module example_fit_to_zone(zone) {
    x = zone_x_min(zone);
    y = zone_y_min(zone);
    w = zone_width(zone);
    h = zone_height(zone);
    
    translate([x, y, 1])
    color("blue", 0.5)
    square([w, h]);
}

// Example: Position at percentage within zone
module example_position_in_zone(zone, pct_x, pct_y) {
    x = zone_x(zone, pct_x);
    y = zone_y(zone, pct_y);
    translate([x, y, 1])
    color("green")
    circle(r=3);
}

// ═══════════════════════════════════════════════════════════════════════════
//                         MAIN PREVIEW
// ═══════════════════════════════════════════════════════════════════════════

// Uncomment the visualization you want:

// Show grid with all zones
show_grid(50);
show_all_zones();
show_canvas_frame();

// Example usage:
// example_centered_in_zone(ZONE_MOON);
// example_position_in_zone(ZONE_STARS, 0.25, 0.75);

// ═══════════════════════════════════════════════════════════════════════════
//                         ZONE SUMMARY
// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("CANVAS LAYOUT - ZONE DEFINITIONS");
echo("═══════════════════════════════════════════════════════════════════════");
echo("Canvas Inner: ", IW, "×", IH, "mm");
echo("");
echo("ZONE              X_MIN    X_MAX    Y_MIN    Y_MAX    W×H");
echo("─────────────────────────────────────────────────────────────────────");
echo("CLIFF:           ", ZONE_CLIFF[0], "-", ZONE_CLIFF[1], "  ", ZONE_CLIFF[2], "-", ZONE_CLIFF[3]);
echo("LIGHTHOUSE:      ", ZONE_LIGHTHOUSE[0], "-", ZONE_LIGHTHOUSE[1], "  ", ZONE_LIGHTHOUSE[2], "-", ZONE_LIGHTHOUSE[3]);
echo("CYPRESS:         ", ZONE_CYPRESS[0], "-", ZONE_CYPRESS[1], "  ", ZONE_CYPRESS[2], "-", ZONE_CYPRESS[3]);
echo("CLIFF WAVES:     ", ZONE_CLIFF_WAVES[0], "-", ZONE_CLIFF_WAVES[1], "  ", ZONE_CLIFF_WAVES[2], "-", ZONE_CLIFF_WAVES[3]);
echo("OCEAN WAVES:     ", ZONE_OCEAN_WAVES[0], "-", ZONE_OCEAN_WAVES[1], "  ", ZONE_OCEAN_WAVES[2], "-", ZONE_OCEAN_WAVES[3]);
echo("BOTTOM GEARS:    ", ZONE_BOTTOM_GEARS[0], "-", ZONE_BOTTOM_GEARS[1], "  ", ZONE_BOTTOM_GEARS[2], "-", ZONE_BOTTOM_GEARS[3]);
echo("WIND PATH:       ", ZONE_WIND_PATH[0], "-", ZONE_WIND_PATH[1], "  ", ZONE_WIND_PATH[2], "-", ZONE_WIND_PATH[3]);
echo("BIG SWIRL:       ", ZONE_BIG_SWIRL[0], "-", ZONE_BIG_SWIRL[1], "  ", ZONE_BIG_SWIRL[2], "-", ZONE_BIG_SWIRL[3]);
echo("SMALL SWIRL:     ", ZONE_SMALL_SWIRL[0], "-", ZONE_SMALL_SWIRL[1], "  ", ZONE_SMALL_SWIRL[2], "-", ZONE_SMALL_SWIRL[3]);
echo("MOON:            ", ZONE_MOON[0], "-", ZONE_MOON[1], "  ", ZONE_MOON[2], "-", ZONE_MOON[3]);
echo("STARS:           ", ZONE_STARS[0], "-", ZONE_STARS[1], "  ", ZONE_STARS[2], "-", ZONE_STARS[3]);
echo("SKY GEARS:       ", ZONE_SKY_GEARS[0], "-", ZONE_SKY_GEARS[1], "  ", ZONE_SKY_GEARS[2], "-", ZONE_SKY_GEARS[3]);
echo("BIRD WIRE:       ", ZONE_BIRD_WIRE[0], "-", ZONE_BIRD_WIRE[1], "  ", ZONE_BIRD_WIRE[2], "-", ZONE_BIRD_WIRE[3]);
echo("═══════════════════════════════════════════════════════════════════════");
