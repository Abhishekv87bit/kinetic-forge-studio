// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT - CANVAS LAYOUT & ZONING SYSTEM
// Canvas: 350 × 250 × (80-100) mm
// User-defined zone boundaries
// ═══════════════════════════════════════════════════════════════════════════
$fn = 32;

// ═══════════════════════════════════════════════════════════════════════════
// MASTER CANVAS DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════
CANVAS_W = 350;
CANVAS_H = 250;
CANVAS_D_MIN = 80;
CANVAS_D_MAX = 100;
FRAME_W = 20;

// Inner canvas dimensions (based on user zone values)
IW = 310;   // Inner width (0-310 for most elements)
IH = 230;   // Inner height (0-230 for sky elements)

// ═══════════════════════════════════════════════════════════════════════════
//                         ZONE DEFINITIONS
// Format: [X_MIN, X_MAX, Y_MIN, Y_MAX]
// ═══════════════════════════════════════════════════════════════════════════

// CLIFF: Landmass on left
ZONE_CLIFF = [0, 125, 0, 80];

// LIGHTHOUSE: On cliff edge
ZONE_LIGHTHOUSE = [85, 95, 65, 130];

// CYPRESS: Tall tree from bottom
ZONE_CYPRESS = [40, 110, 0, 150];

// CLIFF_WAVES: Breaking zone
ZONE_CLIFF_WAVES = [125, 185, 0, 85];

// OCEAN_WAVES: Open water (extends to frame edge)
ZONE_OCEAN_WAVES = [175, 350, 0, 80];

// BOTTOM_GEARS: Mechanical elements
ZONE_BOTTOM_GEARS = [190, 350, 0, 50];

// WIND_PATH: Swirling sky element
ZONE_WIND_PATH = [0, 230, 130, 230];

// BIG_SWIRL: Large swirl disc
ZONE_BIG_SWIRL = [100, 185, 100, 170];

// SMALL_SWIRL: Small swirl disc
ZONE_SMALL_SWIRL = [175, 230, 85, 140];

// MOON: Top right
ZONE_MOON = [220, 300, 135, 210];

// STARS: Upper sky
ZONE_STARS = [0, 230, 125, 230];

// SKY_GEARS: Foreground decorative
ZONE_SKY_GEARS = [60, 250, 135, 205];

// BIRD_WIRE: Full width track
ZONE_BIRD_WIRE = [0, 310, 100, 120];

// ═══════════════════════════════════════════════════════════════════════════
//                         Z-LAYER DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════
Z_SKY_BACK = 0;
Z_MOON_HALO_BACK = 8;
Z_MOON_HALO_FRONT = 12;
Z_MOON_CORE = 16;
Z_STARS = 18;
Z_SWIRL_HALO_BACK = 22;
Z_SWIRL_HALO_FRONT = 26;
Z_SWIRL_MAIN = 30;
Z_WIND_PATH = 35;
Z_BELTS = 38;
Z_CLIFF = 40;
Z_LIGHTHOUSE = 45;
Z_BOTTOM_GEARS = 48;
Z_OCEAN_WAVES_FAR = 50;
Z_OCEAN_WAVES_MID = 55;
Z_OCEAN_WAVES_NEAR = 60;
Z_CLIFF_WAVES = 65;
Z_CLIFF_SPRAY = 70;
Z_CYPRESS = 75;
Z_SKY_GEARS = 80;
Z_BIRD_WIRE = 85;
Z_FRAME = 95;

// ═══════════════════════════════════════════════════════════════════════════
//                         HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════
function zone_x_min(zone) = zone[0];
function zone_x_max(zone) = zone[1];
function zone_y_min(zone) = zone[2];
function zone_y_max(zone) = zone[3];
function zone_width(zone) = zone[1] - zone[0];
function zone_height(zone) = zone[3] - zone[2];
function zone_center_x(zone) = (zone[0] + zone[1]) / 2;
function zone_center_y(zone) = (zone[2] + zone[3]) / 2;
function zone_x(zone, pct) = zone[0] + (zone[1] - zone[0]) * pct;
function zone_y(zone, pct) = zone[2] + (zone[3] - zone[2]) * pct;

// ═══════════════════════════════════════════════════════════════════════════
//                         VISUALIZATION
// ═══════════════════════════════════════════════════════════════════════════
module show_zone(zone, name="", col="red", alpha=0.15) {
    x1 = zone[0]; x2 = zone[1];
    y1 = zone[2]; y2 = zone[3];
    w = x2 - x1;
    h = y2 - y1;
    
    color(col, alpha)
    translate([x1, y1, 0])
    square([w, h]);
    
    color(col, 0.9)
    translate([x1, y1, 0.1])
    difference() {
        square([w, h]);
        translate([1, 1]) square([max(0.1, w-2), max(0.1, h-2)]);
    }
    
    if (name != "") {
        color("black")
        translate([x1 + 2, y1 + h/2 - 3, 0.2])
        linear_extrude(0.5)
        text(name, size=5, font="Liberation Sans:style=Bold");
    }
}

module show_all_zones() {
    show_zone(ZONE_CLIFF,        "CLIFF",         "#8B4513", 0.30);
    show_zone(ZONE_LIGHTHOUSE,   "LH",            "#FFD700", 0.40);
    show_zone(ZONE_CYPRESS,      "CYPRESS",       "#228B22", 0.25);
    show_zone(ZONE_CLIFF_WAVES,  "CLIFF WAVES",   "#00CED1", 0.30);
    show_zone(ZONE_OCEAN_WAVES,  "OCEAN WAVES",   "#4169E1", 0.20);
    show_zone(ZONE_BOTTOM_GEARS, "BOTTOM GEARS",  "#FF8C00", 0.35);
    show_zone(ZONE_WIND_PATH,    "WIND PATH",     "#9370DB", 0.18);
    show_zone(ZONE_BIG_SWIRL,    "BIG SWIRL",     "#FF00FF", 0.30);
    show_zone(ZONE_SMALL_SWIRL,  "SMALL SWIRL",   "#FF69B4", 0.30);
    show_zone(ZONE_MOON,         "MOON",          "#FFD700", 0.35);
    show_zone(ZONE_STARS,        "STARS",         "#AAAAAA", 0.12);
    show_zone(ZONE_SKY_GEARS,    "SKY GEARS",     "#FFA500", 0.15);
    show_zone(ZONE_BIRD_WIRE,    "BIRD WIRE",     "#696969", 0.40);
}

module show_grid(spacing=25) {
    color("gray", 0.25) {
        for (x = [0 : spacing : 350]) {
            translate([x, 0, 0]) square([0.3, 250]);
        }
        for (y = [0 : spacing : 250]) {
            translate([0, y, 0]) square([350, 0.3]);
        }
    }
    color("black", 0.5) {
        for (x = [0 : spacing : 350]) {
            translate([x - 3, -10, 0])
            linear_extrude(0.5) text(str(x), size=5);
        }
        for (y = [0 : spacing : 250]) {
            translate([-18, y - 2, 0])
            linear_extrude(0.5) text(str(y), size=5);
        }
    }
}

module show_canvas_outline() {
    // Full canvas outline
    color("#5a4030", 0.3)
    difference() {
        square([350, 250]);
        translate([1, 1]) square([348, 248]);
    }
    
    // Frame inner edge (20mm frame)
    color("#5a4030", 0.6)
    translate([FRAME_W, FRAME_W, 0.05])
    difference() {
        square([IW, IH - 20]);  // Adjusted for actual inner
        translate([1, 1]) square([IW-2, IH-22]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//                         MAIN PREVIEW
// ═══════════════════════════════════════════════════════════════════════════
show_grid(25);
show_all_zones();
show_canvas_outline();

// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════");
echo("STARRY NIGHT - CANVAS LAYOUT");
echo("Canvas: 350 × 250 mm | Depth: 80-100mm");
echo("═══════════════════════════════════════════════════════════════════════");
echo("");
echo("ZONE              X: MIN → MAX    Y: MIN → MAX    SIZE (W × H)");
echo("───────────────────────────────────────────────────────────────────────");
echo(str("CLIFF             ", ZONE_CLIFF[0], " → ", ZONE_CLIFF[1], "        ", ZONE_CLIFF[2], " → ", ZONE_CLIFF[3], "         ", zone_width(ZONE_CLIFF), " × ", zone_height(ZONE_CLIFF)));
echo(str("LIGHTHOUSE        ", ZONE_LIGHTHOUSE[0], " → ", ZONE_LIGHTHOUSE[1], "        ", ZONE_LIGHTHOUSE[2], " → ", ZONE_LIGHTHOUSE[3], "       ", zone_width(ZONE_LIGHTHOUSE), " × ", zone_height(ZONE_LIGHTHOUSE)));
echo(str("CYPRESS           ", ZONE_CYPRESS[0], " → ", ZONE_CYPRESS[1], "        ", ZONE_CYPRESS[2], " → ", ZONE_CYPRESS[3], "       ", zone_width(ZONE_CYPRESS), " × ", zone_height(ZONE_CYPRESS)));
echo(str("CLIFF_WAVES       ", ZONE_CLIFF_WAVES[0], " → ", ZONE_CLIFF_WAVES[1], "       ", ZONE_CLIFF_WAVES[2], " → ", ZONE_CLIFF_WAVES[3], "        ", zone_width(ZONE_CLIFF_WAVES), " × ", zone_height(ZONE_CLIFF_WAVES)));
echo(str("OCEAN_WAVES       ", ZONE_OCEAN_WAVES[0], " → ", ZONE_OCEAN_WAVES[1], "       ", ZONE_OCEAN_WAVES[2], " → ", ZONE_OCEAN_WAVES[3], "        ", zone_width(ZONE_OCEAN_WAVES), " × ", zone_height(ZONE_OCEAN_WAVES)));
echo(str("BOTTOM_GEARS      ", ZONE_BOTTOM_GEARS[0], " → ", ZONE_BOTTOM_GEARS[1], "       ", ZONE_BOTTOM_GEARS[2], " → ", ZONE_BOTTOM_GEARS[3], "        ", zone_width(ZONE_BOTTOM_GEARS), " × ", zone_height(ZONE_BOTTOM_GEARS)));
echo(str("WIND_PATH         ", ZONE_WIND_PATH[0], " → ", ZONE_WIND_PATH[1], "         ", ZONE_WIND_PATH[2], " → ", ZONE_WIND_PATH[3], "       ", zone_width(ZONE_WIND_PATH), " × ", zone_height(ZONE_WIND_PATH)));
echo(str("BIG_SWIRL         ", ZONE_BIG_SWIRL[0], " → ", ZONE_BIG_SWIRL[1], "       ", ZONE_BIG_SWIRL[2], " → ", ZONE_BIG_SWIRL[3], "       ", zone_width(ZONE_BIG_SWIRL), " × ", zone_height(ZONE_BIG_SWIRL)));
echo(str("SMALL_SWIRL       ", ZONE_SMALL_SWIRL[0], " → ", ZONE_SMALL_SWIRL[1], "       ", ZONE_SMALL_SWIRL[2], " → ", ZONE_SMALL_SWIRL[3], "       ", zone_width(ZONE_SMALL_SWIRL), " × ", zone_height(ZONE_SMALL_SWIRL)));
echo(str("MOON              ", ZONE_MOON[0], " → ", ZONE_MOON[1], "       ", ZONE_MOON[2], " → ", ZONE_MOON[3], "       ", zone_width(ZONE_MOON), " × ", zone_height(ZONE_MOON)));
echo(str("STARS             ", ZONE_STARS[0], " → ", ZONE_STARS[1], "         ", ZONE_STARS[2], " → ", ZONE_STARS[3], "       ", zone_width(ZONE_STARS), " × ", zone_height(ZONE_STARS)));
echo(str("SKY_GEARS         ", ZONE_SKY_GEARS[0], " → ", ZONE_SKY_GEARS[1], "        ", ZONE_SKY_GEARS[2], " → ", ZONE_SKY_GEARS[3], "       ", zone_width(ZONE_SKY_GEARS), " × ", zone_height(ZONE_SKY_GEARS)));
echo(str("BIRD_WIRE         ", ZONE_BIRD_WIRE[0], " → ", ZONE_BIRD_WIRE[1], "         ", ZONE_BIRD_WIRE[2], " → ", ZONE_BIRD_WIRE[3], "       ", zone_width(ZONE_BIRD_WIRE), " × ", zone_height(ZONE_BIRD_WIRE)));
echo("═══════════════════════════════════════════════════════════════════════");
