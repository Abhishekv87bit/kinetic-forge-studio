// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT - CANVAS LAYOUT & ZONING SYSTEM
// Canvas: 350 × 250 × (80-100) mm
// ═══════════════════════════════════════════════════════════════════════════
$fn = 32;

// ═══════════════════════════════════════════════════════════════════════════
// MASTER CANVAS DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════
CANVAS_W = 350;      // Total width
CANVAS_H = 250;      // Total height (CORRECTED from 275)
CANVAS_D_MIN = 80;   // Minimum depth
CANVAS_D_MAX = 100;  // Maximum depth
FRAME_W = 20;        // Frame width

// Inner canvas (where all content lives)
IW = CANVAS_W - FRAME_W * 2;  // 310mm inner width
IH = CANVAS_H - FRAME_W * 2;  // 210mm inner height (was 235)

// For reference in Z positioning
Z_MIN = 0;
Z_MAX = CANVAS_D_MAX;  // 100mm max depth

// ═══════════════════════════════════════════════════════════════════════════
//                         ZONE DEFINITIONS
// Each zone defines: [X_MIN, X_MAX, Y_MIN, Y_MAX]
// All values in mm, relative to inner canvas origin (0,0)
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: CLIFF (left side landmass)
// Rectangle (0-100) + Inverted triangle (100-165)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CLIFF = [
    0,          // X_MIN: Left edge
    165,        // X_MAX: Cliff total width
    0,          // Y_MIN: Bottom
    75          // Y_MAX: Cliff height (adjusted for shorter canvas)
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: LIGHTHOUSE (on cliff)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_LIGHTHOUSE = [
    25,         // X_MIN
    50,         // X_MAX
    65,         // Y_MIN: Near cliff top
    130         // Y_MAX: Lighthouse extends above cliff
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: CYPRESS TREE (tall, from bottom to sky)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CYPRESS = [
    55,         // X_MIN
    130,        // X_MAX
    0,          // Y_MIN: Touching bottom
    165         // Y_MAX: Tree top (reaches into sky)
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: CLIFF WAVES (breaking zone - spray against cliff)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CLIFF_WAVES = [
    145,        // X_MIN: Near cliff edge
    195,        // X_MAX: Breaking zone
    0,          // Y_MIN: Water level
    100         // Y_MAX: Spray height
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: OCEAN WAVES (open water - far to approaching)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_OCEAN_WAVES = [
    175,        // X_MIN: After cliff waves (slight overlap)
    IW,         // X_MAX: Right edge (310)
    0,          // Y_MIN: Bottom
    70          // Y_MAX: Wave height limit
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: BOTTOM GEARS (mechanical elements at base)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_BOTTOM_GEARS = [
    155,        // X_MIN: ~50% width
    305,        // X_MAX: Near right edge
    0,          // Y_MIN: Bottom
    25          // Y_MAX: Low band
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: WIND PATH (swirling sky - large area)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_WIND_PATH = [
    0,          // X_MIN: Touches left edge
    230,        // X_MAX: ~74% across
    70,         // Y_MIN: Above waves
    175         // Y_MAX: Upper sky
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: BIG SWIRL DISC (within wind path)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_BIG_SWIRL = [
    30,         // X_MIN
    115,        // X_MAX
    100,        // Y_MIN
    170         // Y_MAX
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: SMALL SWIRL DISC (within wind path)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_SMALL_SWIRL = [
    110,        // X_MIN
    175,        // X_MAX
    85,         // Y_MIN
    140         // Y_MAX
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: MOON (top right corner)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_MOON = [
    230,        // X_MIN
    IW,         // X_MAX: Right edge (310)
    135,        // Y_MIN
    IH          // Y_MAX: Top edge (210)
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: STARS (scattered across upper sky, avoiding moon)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_STARS = [
    15,         // X_MIN
    230,        // X_MAX: Stop before moon
    125,        // Y_MIN
    205         // Y_MAX: Near top
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: SKY GEARS (decorative foreground)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_SKY_GEARS = [
    60,         // X_MIN
    250,        // X_MAX
    135,        // Y_MIN
    205         // Y_MAX
];

// ─────────────────────────────────────────────────────────────────────────────
// ZONE: BIRD WIRE (horizontal track across canvas)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_BIRD_WIRE = [
    0,          // X_MIN: Left edge
    IW,         // X_MAX: Right edge (310) - full width
    100,        // Y_MIN
    120         // Y_MAX: Narrow band
];

// ═══════════════════════════════════════════════════════════════════════════
//                         Z-LAYER DEFINITIONS
// Depth from back (Z=0) to front (Z=100)
// ═══════════════════════════════════════════════════════════════════════════
Z_SKY_BACK = 0;           // Background sky
Z_MOON_HALO_BACK = 8;     // Moon outer halo
Z_MOON_HALO_FRONT = 12;   // Moon inner halo
Z_MOON_CORE = 16;         // Moon center
Z_STARS = 18;             // Star gears
Z_SWIRL_HALO_BACK = 22;   // Swirl outer halo
Z_SWIRL_HALO_FRONT = 26;  // Swirl inner halo
Z_SWIRL_MAIN = 30;        // Swirl main disc
Z_WIND_PATH = 35;         // Wind path shape
Z_BELTS = 38;             // Belt/chain connections
Z_CLIFF = 40;             // Cliff landmass
Z_LIGHTHOUSE = 45;        // Lighthouse
Z_BOTTOM_GEARS = 48;      // Bottom mechanical gears
Z_OCEAN_WAVES_FAR = 50;   // Far ocean waves
Z_OCEAN_WAVES_MID = 55;   // Mid ocean waves
Z_OCEAN_WAVES_NEAR = 60;  // Near/approaching waves
Z_CLIFF_WAVES = 65;       // Breaking waves
Z_CLIFF_SPRAY = 70;       // Foam spray
Z_CYPRESS = 75;           // Cypress tree
Z_SKY_GEARS = 80;         // Foreground sky gears
Z_BIRD_WIRE = 85;         // Bird wire track
Z_FRAME = 95;             // Outer frame (frontmost)

// ═══════════════════════════════════════════════════════════════════════════
//                         HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

// Zone accessors
function zone_x_min(zone) = zone[0];
function zone_x_max(zone) = zone[1];
function zone_y_min(zone) = zone[2];
function zone_y_max(zone) = zone[3];
function zone_width(zone) = zone[1] - zone[0];
function zone_height(zone) = zone[3] - zone[2];
function zone_center_x(zone) = (zone[0] + zone[1]) / 2;
function zone_center_y(zone) = (zone[2] + zone[3]) / 2;

// Position within zone (0-1 normalized)
function zone_x(zone, pct) = zone[0] + (zone[1] - zone[0]) * pct;
function zone_y(zone, pct) = zone[2] + (zone[3] - zone[2]) * pct;

// Check bounds
function in_zone(zone, x, y) = 
    x >= zone[0] && x <= zone[1] && y >= zone[2] && y <= zone[3];

// Clamp position to zone
function clamp_x(zone, x) = max(zone[0], min(zone[1], x));
function clamp_y(zone, y) = max(zone[2], min(zone[3], y));

// ═══════════════════════════════════════════════════════════════════════════
//                         VISUALIZATION MODULES
// ═══════════════════════════════════════════════════════════════════════════

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
        color("black")
        translate([x1 + 3, y1 + 3, 0.2])
        linear_extrude(0.5)
        text(name, size=5, font="Liberation Sans:style=Bold");
    }
}

module show_all_zones() {
    show_zone(ZONE_CLIFF,        "CLIFF",        "#8B4513", 0.25);
    show_zone(ZONE_LIGHTHOUSE,   "LIGHTHOUSE",   "#FFD700", 0.30);
    show_zone(ZONE_CYPRESS,      "CYPRESS",      "#228B22", 0.20);
    show_zone(ZONE_CLIFF_WAVES,  "CLIFF WAVES",  "#00CED1", 0.25);
    show_zone(ZONE_OCEAN_WAVES,  "OCEAN WAVES",  "#4169E1", 0.20);
    show_zone(ZONE_BOTTOM_GEARS, "BOTTOM GEARS", "#FF8C00", 0.30);
    show_zone(ZONE_WIND_PATH,    "WIND PATH",    "#9370DB", 0.15);
    show_zone(ZONE_BIG_SWIRL,    "BIG SWIRL",    "#FF00FF", 0.25);
    show_zone(ZONE_SMALL_SWIRL,  "SMALL SWIRL",  "#FF69B4", 0.25);
    show_zone(ZONE_MOON,         "MOON",         "#FFD700", 0.30);
    show_zone(ZONE_STARS,        "STARS",        "#FFFFFF", 0.12);
    show_zone(ZONE_SKY_GEARS,    "SKY GEARS",    "#FFA500", 0.12);
    show_zone(ZONE_BIRD_WIRE,    "BIRD WIRE",    "#696969", 0.35);
}

module show_canvas_frame() {
    // Outer boundary
    color("#5a4030", 0.8)
    difference() {
        square([IW, IH]);
        translate([1, 1]) square([IW-2, IH-2]);
    }
}

module show_grid(spacing=25) {
    color("gray", 0.3) {
        for (x = [0 : spacing : IW]) {
            translate([x, 0, 0]) square([0.3, IH]);
        }
        for (y = [0 : spacing : IH]) {
            translate([0, y, 0]) square([IW, 0.3]);
        }
    }
    // X labels
    color("black", 0.6) {
        for (x = [0 : spacing : IW]) {
            translate([x - 3, -12, 0])
            linear_extrude(0.5) text(str(x), size=6);
        }
        for (y = [0 : spacing : IH]) {
            translate([-20, y - 2, 0])
            linear_extrude(0.5) text(str(y), size=6);
        }
    }
}

// 3D visualization of Z layers
module show_z_layers_3d() {
    layer_data = [
        [Z_SKY_BACK, "SKY BACK", "#4a7ab0"],
        [Z_MOON_CORE, "MOON", "#FFD700"],
        [Z_STARS, "STARS", "#FFFFFF"],
        [Z_SWIRL_MAIN, "SWIRLS", "#9370DB"],
        [Z_WIND_PATH, "WIND", "#4169E1"],
        [Z_CLIFF, "CLIFF", "#8B4513"],
        [Z_LIGHTHOUSE, "LIGHTHOUSE", "#D4C4A8"],
        [Z_BOTTOM_GEARS, "GEARS", "#B8A060"],
        [Z_OCEAN_WAVES_MID, "WAVES", "#4169E1"],
        [Z_CLIFF_SPRAY, "SPRAY", "#F0F0E8"],
        [Z_CYPRESS, "CYPRESS", "#228B22"],
        [Z_SKY_GEARS, "SKY GEARS", "#FFA500"],
        [Z_BIRD_WIRE, "BIRDS", "#696969"],
        [Z_FRAME, "FRAME", "#5a4030"]
    ];
    
    for (layer = layer_data) {
        translate([0, 0, layer[0]])
        color(layer[2], 0.3)
        linear_extrude(2)
        square([IW, IH]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                         MAIN PREVIEW
// ═══════════════════════════════════════════════════════════════════════════

// 2D Zone Preview (default view)
show_grid(25);
show_all_zones();
show_canvas_frame();

// Uncomment for 3D layer preview:
// show_z_layers_3d();

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("CANVAS LAYOUT - 350 × 250 × (80-100) mm");
echo("Inner Canvas:", IW, "×", IH, "mm");
echo("═══════════════════════════════════════════════════════════════════════");
echo("");
echo("ZONE              X: MIN-MAX      Y: MIN-MAX      SIZE (W×H)");
echo("───────────────────────────────────────────────────────────────────────");
echo(str("CLIFF            ", ZONE_CLIFF[0], "-", ZONE_CLIFF[1], "         ", ZONE_CLIFF[2], "-", ZONE_CLIFF[3], "          ", zone_width(ZONE_CLIFF), "×", zone_height(ZONE_CLIFF)));
echo(str("LIGHTHOUSE       ", ZONE_LIGHTHOUSE[0], "-", ZONE_LIGHTHOUSE[1], "          ", ZONE_LIGHTHOUSE[2], "-", ZONE_LIGHTHOUSE[3], "        ", zone_width(ZONE_LIGHTHOUSE), "×", zone_height(ZONE_LIGHTHOUSE)));
echo(str("CYPRESS          ", ZONE_CYPRESS[0], "-", ZONE_CYPRESS[1], "         ", ZONE_CYPRESS[2], "-", ZONE_CYPRESS[3], "        ", zone_width(ZONE_CYPRESS), "×", zone_height(ZONE_CYPRESS)));
echo(str("CLIFF WAVES      ", ZONE_CLIFF_WAVES[0], "-", ZONE_CLIFF_WAVES[1], "        ", ZONE_CLIFF_WAVES[2], "-", ZONE_CLIFF_WAVES[3], "        ", zone_width(ZONE_CLIFF_WAVES), "×", zone_height(ZONE_CLIFF_WAVES)));
echo(str("OCEAN WAVES      ", ZONE_OCEAN_WAVES[0], "-", ZONE_OCEAN_WAVES[1], "        ", ZONE_OCEAN_WAVES[2], "-", ZONE_OCEAN_WAVES[3], "          ", zone_width(ZONE_OCEAN_WAVES), "×", zone_height(ZONE_OCEAN_WAVES)));
echo(str("BOTTOM GEARS     ", ZONE_BOTTOM_GEARS[0], "-", ZONE_BOTTOM_GEARS[1], "        ", ZONE_BOTTOM_GEARS[2], "-", ZONE_BOTTOM_GEARS[3], "          ", zone_width(ZONE_BOTTOM_GEARS), "×", zone_height(ZONE_BOTTOM_GEARS)));
echo(str("WIND PATH        ", ZONE_WIND_PATH[0], "-", ZONE_WIND_PATH[1], "          ", ZONE_WIND_PATH[2], "-", ZONE_WIND_PATH[3], "        ", zone_width(ZONE_WIND_PATH), "×", zone_height(ZONE_WIND_PATH)));
echo(str("BIG SWIRL        ", ZONE_BIG_SWIRL[0], "-", ZONE_BIG_SWIRL[1], "         ", ZONE_BIG_SWIRL[2], "-", ZONE_BIG_SWIRL[3], "        ", zone_width(ZONE_BIG_SWIRL), "×", zone_height(ZONE_BIG_SWIRL)));
echo(str("SMALL SWIRL      ", ZONE_SMALL_SWIRL[0], "-", ZONE_SMALL_SWIRL[1], "        ", ZONE_SMALL_SWIRL[2], "-", ZONE_SMALL_SWIRL[3], "        ", zone_width(ZONE_SMALL_SWIRL), "×", zone_height(ZONE_SMALL_SWIRL)));
echo(str("MOON             ", ZONE_MOON[0], "-", ZONE_MOON[1], "        ", ZONE_MOON[2], "-", ZONE_MOON[3], "        ", zone_width(ZONE_MOON), "×", zone_height(ZONE_MOON)));
echo(str("STARS            ", ZONE_STARS[0], "-", ZONE_STARS[1], "          ", ZONE_STARS[2], "-", ZONE_STARS[3], "        ", zone_width(ZONE_STARS), "×", zone_height(ZONE_STARS)));
echo(str("SKY GEARS        ", ZONE_SKY_GEARS[0], "-", ZONE_SKY_GEARS[1], "         ", ZONE_SKY_GEARS[2], "-", ZONE_SKY_GEARS[3], "        ", zone_width(ZONE_SKY_GEARS), "×", zone_height(ZONE_SKY_GEARS)));
echo(str("BIRD WIRE        ", ZONE_BIRD_WIRE[0], "-", ZONE_BIRD_WIRE[1], "          ", ZONE_BIRD_WIRE[2], "-", ZONE_BIRD_WIRE[3], "        ", zone_width(ZONE_BIRD_WIRE), "×", zone_height(ZONE_BIRD_WIRE)));
echo("");
echo("Z-LAYERS (back to front):");
echo("  SKY=0, MOON=8-16, STARS=18, SWIRLS=22-30, WIND=35");
echo("  CLIFF=40, LIGHTHOUSE=45, GEARS=48, WAVES=50-70");
echo("  CYPRESS=75, SKY_GEARS=80, BIRDS=85, FRAME=95");
echo("═══════════════════════════════════════════════════════════════════════");
