// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT - FINALIZED CANVAS LAYOUT
// ═══════════════════════════════════════════════════════════════════════════
// Total printed: 350 × 250 mm (fits 350mm print bed)
// Canvas art area: 302 × 202 mm
// Mounting tabs: 24mm (sits on wooden frame)
// ═══════════════════════════════════════════════════════════════════════════
$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════
// MASTER DIMENSIONS
// ═══════════════════════════════════════════════════════════════════════════

// Total printed piece
TOTAL_W = 350;
TOTAL_H = 250;

// Mounting tab / wood frame width
TAB_WIDTH = 24;

// Canvas art area (inside mounting tabs)
CANVAS_W = 302;  // 350 - 24 - 24
CANVAS_H = 202;  // 250 - 24 - 24

// Depth range
CANVAS_DEPTH_MIN = 80;
CANVAS_DEPTH_MAX = 100;

// Canvas origin offset (from total piece origin)
CANVAS_ORIGIN_X = TAB_WIDTH;  // 24
CANVAS_ORIGIN_Y = TAB_WIDTH;  // 24

// ═══════════════════════════════════════════════════════════════════════════
// ZONE DEFINITIONS
// All coordinates relative to CANVAS origin (0,0 = bottom-left of art area)
// Format: [X_MIN, X_MAX, Y_MIN, Y_MAX]
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// CLIFF - Left side landmass
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CLIFF = [0, 108, 0, 65];
// Width: 108mm, Height: 65mm

// ─────────────────────────────────────────────────────────────────────────────
// LIGHTHOUSE - On cliff
// ─────────────────────────────────────────────────────────────────────────────
ZONE_LIGHTHOUSE = [73, 82, 53, 105];
// Width: 9mm, Height: 52mm

// ─────────────────────────────────────────────────────────────────────────────
// CYPRESS - Tall tree from bottom into sky
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CYPRESS = [35, 95, 0, 121];
// Width: 60mm, Height: 121mm

// ─────────────────────────────────────────────────────────────────────────────
// CLIFF_WAVES - Breaking zone against cliff
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CLIFF_WAVES = [108, 160, 0, 69];
// Width: 52mm, Height: 69mm

// ─────────────────────────────────────────────────────────────────────────────
// OCEAN_WAVES - Open water (far to approaching)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_OCEAN_WAVES = [151, 302, 0, 65];
// Width: 151mm, Height: 65mm

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM_GEARS - Mechanical elements at base
// ─────────────────────────────────────────────────────────────────────────────
ZONE_BOTTOM_GEARS = [164, 302, 0, 40];
// Width: 138mm, Height: 40mm

// ─────────────────────────────────────────────────────────────────────────────
// WIND_PATH - Swirling sky element
// ─────────────────────────────────────────────────────────────────────────────
ZONE_WIND_PATH = [0, 198, 105, 202];
// Width: 198mm, Height: 97mm

// ─────────────────────────────────────────────────────────────────────────────
// BIG_SWIRL - Large swirl disc
// ─────────────────────────────────────────────────────────────────────────────
ZONE_BIG_SWIRL = [86, 160, 81, 137];
// Width: 74mm, Height: 56mm

// ─────────────────────────────────────────────────────────────────────────────
// SMALL_SWIRL - Small swirl disc
// ─────────────────────────────────────────────────────────────────────────────
ZONE_SMALL_SWIRL = [151, 198, 69, 113];
// Width: 47mm, Height: 44mm

// ─────────────────────────────────────────────────────────────────────────────
// MOON - Top right corner
// ─────────────────────────────────────────────────────────────────────────────
ZONE_MOON = [190, 259, 109, 170];
// Width: 69mm, Height: 61mm

// ─────────────────────────────────────────────────────────────────────────────
// STARS - Upper sky region
// ─────────────────────────────────────────────────────────────────────────────
ZONE_STARS = [0, 198, 101, 202];
// Width: 198mm, Height: 101mm

// ─────────────────────────────────────────────────────────────────────────────
// SKY_GEARS - Decorative foreground gears
// ─────────────────────────────────────────────────────────────────────────────
ZONE_SKY_GEARS = [52, 216, 109, 166];
// Width: 164mm, Height: 57mm

// ─────────────────────────────────────────────────────────────────────────────
// BIRD_WIRE - Horizontal track full width
// ─────────────────────────────────────────────────────────────────────────────
ZONE_BIRD_WIRE = [0, 302, 81, 97];
// Width: 302mm (full), Height: 16mm

// ═══════════════════════════════════════════════════════════════════════════
// Z-LAYER DEFINITIONS (Back to Front, 0-100mm)
// ═══════════════════════════════════════════════════════════════════════════

Z_SKY_BACK = 0;            // Background sky color
Z_MOON_HALO_BACK = 8;      // Moon outer halo
Z_MOON_HALO_FRONT = 12;    // Moon inner halo  
Z_MOON_CORE = 16;          // Moon center disc
Z_STARS = 18;              // Star gears
Z_SWIRL_HALO_BACK = 22;    // Swirl outer halos
Z_SWIRL_HALO_FRONT = 26;   // Swirl inner halos
Z_SWIRL_MAIN = 30;         // Swirl main discs
Z_WIND_PATH = 35;          // Wind path shape
Z_BELTS = 38;              // Belt/chain connections
Z_CLIFF = 40;              // Cliff landmass
Z_LIGHTHOUSE = 45;         // Lighthouse
Z_BOTTOM_GEARS = 48;       // Bottom mechanical gears
Z_OCEAN_WAVES_FAR = 50;    // Far ocean waves
Z_OCEAN_WAVES_MID = 55;    // Mid ocean waves
Z_OCEAN_WAVES_NEAR = 60;   // Near/approaching waves
Z_CLIFF_WAVES = 65;        // Breaking waves
Z_CLIFF_SPRAY = 70;        // Foam spray
Z_CYPRESS = 75;            // Cypress tree
Z_SKY_GEARS = 80;          // Foreground sky gears
Z_BIRD_WIRE = 85;          // Bird wire track
Z_FRAME = 95;              // Mounting tabs (frontmost)

// ═══════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

function zone_x_min(zone) = zone[0];
function zone_x_max(zone) = zone[1];
function zone_y_min(zone) = zone[2];
function zone_y_max(zone) = zone[3];
function zone_width(zone) = zone[1] - zone[0];
function zone_height(zone) = zone[3] - zone[2];
function zone_center_x(zone) = (zone[0] + zone[1]) / 2;
function zone_center_y(zone) = (zone[2] + zone[3]) / 2;

// Position within zone (0.0 to 1.0)
function zone_x(zone, pct) = zone[0] + (zone[1] - zone[0]) * pct;
function zone_y(zone, pct) = zone[2] + (zone[3] - zone[2]) * pct;

// Convert canvas coordinates to total piece coordinates
function to_total_x(canvas_x) = canvas_x + CANVAS_ORIGIN_X;
function to_total_y(canvas_y) = canvas_y + CANVAS_ORIGIN_Y;

// ═══════════════════════════════════════════════════════════════════════════
// VISUALIZATION MODULES
// ═══════════════════════════════════════════════════════════════════════════

module show_zone(zone, name, col, alpha=0.2) {
    x = zone[0];
    y = zone[2];
    w = zone[1] - zone[0];
    h = zone[3] - zone[2];
    
    // Zone fill
    color(col, alpha)
    translate([x, y, 0.1])
    square([w, h]);
    
    // Zone border
    color(col, 0.8)
    translate([x, y, 0.2])
    difference() {
        square([w, h]);
        translate([1, 1]) square([max(1, w-2), max(1, h-2)]);
    }
    
    // Label
    color("black")
    translate([x + 2, y + h/2 - 3, 0.3])
    linear_extrude(0.5)
    text(name, size=5, font="Liberation Sans:style=Bold");
}

module show_all_zones() {
    show_zone(ZONE_CLIFF,        "CLIFF",        "#8B4513", 0.35);
    show_zone(ZONE_LIGHTHOUSE,   "LH",           "#FFD700", 0.50);
    show_zone(ZONE_CYPRESS,      "CYPRESS",      "#228B22", 0.30);
    show_zone(ZONE_CLIFF_WAVES,  "CLIFF_WAVE",   "#00CED1", 0.35);
    show_zone(ZONE_OCEAN_WAVES,  "OCEAN",        "#4169E1", 0.25);
    show_zone(ZONE_BOTTOM_GEARS, "GEARS",        "#FF8C00", 0.40);
    show_zone(ZONE_WIND_PATH,    "WIND",         "#9370DB", 0.20);
    show_zone(ZONE_BIG_SWIRL,    "BIG_SWIRL",    "#FF00FF", 0.35);
    show_zone(ZONE_SMALL_SWIRL,  "SM_SWIRL",     "#FF69B4", 0.35);
    show_zone(ZONE_MOON,         "MOON",         "#FFD700", 0.40);
    show_zone(ZONE_STARS,        "STARS",        "#CCCCCC", 0.12);
    show_zone(ZONE_SKY_GEARS,    "SKY_GEARS",    "#FFA500", 0.15);
    show_zone(ZONE_BIRD_WIRE,    "BIRD",         "#555555", 0.45);
}

module show_canvas_boundary() {
    // Canvas outline
    color("black", 1)
    difference() {
        square([CANVAS_W, CANVAS_H]);
        translate([0.5, 0.5]) square([CANVAS_W - 1, CANVAS_H - 1]);
    }
}

module show_grid(spacing=50) {
    color("#AAAAAA", 0.3) {
        // Vertical lines
        for (x = [0 : spacing : CANVAS_W]) {
            translate([x, 0, 0.05]) square([0.3, CANVAS_H]);
        }
        // Horizontal lines
        for (y = [0 : spacing : CANVAS_H]) {
            translate([0, y, 0.05]) square([CANVAS_W, 0.3]);
        }
    }
    
    // Axis labels
    color("black", 0.6) {
        for (x = [0 : spacing : CANVAS_W]) {
            translate([x - 3, -10, 0])
            linear_extrude(0.5) text(str(x), size=5);
        }
        for (y = [0 : spacing : CANVAS_H]) {
            translate([-18, y - 2, 0])
            linear_extrude(0.5) text(str(y), size=5);
        }
    }
}

module show_mounting_tabs_outline() {
    // Show 24mm border where tabs are
    color("#666666", 0.3)
    translate([-TAB_WIDTH, -TAB_WIDTH, -0.1])
    difference() {
        square([TOTAL_W, TOTAL_H]);
        translate([TAB_WIDTH, TAB_WIDTH]) square([CANVAS_W, CANVAS_H]);
    }
    
    // Label
    color("#666666")
    translate([-TAB_WIDTH + 2, CANVAS_H + TAB_WIDTH/2 - 3, 0])
    linear_extrude(0.5) text("24mm MOUNTING TABS", size=5);
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN VISUALIZATION
// ═══════════════════════════════════════════════════════════════════════════

// Canvas boundary
show_canvas_boundary();

// Grid
show_grid(50);

// All zones
show_all_zones();

// Mounting tabs area
show_mounting_tabs_outline();

// ═══════════════════════════════════════════════════════════════════════════
// CONSOLE OUTPUT - ZONE SUMMARY
// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("              STARRY NIGHT - FINALIZED CANVAS LAYOUT");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("");
echo("CANVAS DIMENSIONS:");
echo("  Total printed piece:  350 × 250 mm");
echo("  Canvas art area:      302 × 202 mm");
echo("  Mounting tabs:        24 mm all sides");
echo("  Depth range:          80-100 mm");
echo("");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("ZONE                  X: MIN → MAX      Y: MIN → MAX      SIZE (W × H)");
echo("───────────────────────────────────────────────────────────────────────────────");
echo(str("CLIFF                 ", ZONE_CLIFF[0], " → ", ZONE_CLIFF[1], "          ", ZONE_CLIFF[2], " → ", ZONE_CLIFF[3], "          ", zone_width(ZONE_CLIFF), " × ", zone_height(ZONE_CLIFF)));
echo(str("LIGHTHOUSE            ", ZONE_LIGHTHOUSE[0], " → ", ZONE_LIGHTHOUSE[1], "          ", ZONE_LIGHTHOUSE[2], " → ", ZONE_LIGHTHOUSE[3], "        ", zone_width(ZONE_LIGHTHOUSE), " × ", zone_height(ZONE_LIGHTHOUSE)));
echo(str("CYPRESS               ", ZONE_CYPRESS[0], " → ", ZONE_CYPRESS[1], "          ", ZONE_CYPRESS[2], " → ", ZONE_CYPRESS[3], "        ", zone_width(ZONE_CYPRESS), " × ", zone_height(ZONE_CYPRESS)));
echo(str("CLIFF_WAVES           ", ZONE_CLIFF_WAVES[0], " → ", ZONE_CLIFF_WAVES[1], "        ", ZONE_CLIFF_WAVES[2], " → ", ZONE_CLIFF_WAVES[3], "         ", zone_width(ZONE_CLIFF_WAVES), " × ", zone_height(ZONE_CLIFF_WAVES)));
echo(str("OCEAN_WAVES           ", ZONE_OCEAN_WAVES[0], " → ", ZONE_OCEAN_WAVES[1], "        ", ZONE_OCEAN_WAVES[2], " → ", ZONE_OCEAN_WAVES[3], "         ", zone_width(ZONE_OCEAN_WAVES), " × ", zone_height(ZONE_OCEAN_WAVES)));
echo(str("BOTTOM_GEARS          ", ZONE_BOTTOM_GEARS[0], " → ", ZONE_BOTTOM_GEARS[1], "        ", ZONE_BOTTOM_GEARS[2], " → ", ZONE_BOTTOM_GEARS[3], "         ", zone_width(ZONE_BOTTOM_GEARS), " × ", zone_height(ZONE_BOTTOM_GEARS)));
echo(str("WIND_PATH             ", ZONE_WIND_PATH[0], " → ", ZONE_WIND_PATH[1], "        ", ZONE_WIND_PATH[2], " → ", ZONE_WIND_PATH[3], "       ", zone_width(ZONE_WIND_PATH), " × ", zone_height(ZONE_WIND_PATH)));
echo(str("BIG_SWIRL             ", ZONE_BIG_SWIRL[0], " → ", ZONE_BIG_SWIRL[1], "        ", ZONE_BIG_SWIRL[2], " → ", ZONE_BIG_SWIRL[3], "        ", zone_width(ZONE_BIG_SWIRL), " × ", zone_height(ZONE_BIG_SWIRL)));
echo(str("SMALL_SWIRL           ", ZONE_SMALL_SWIRL[0], " → ", ZONE_SMALL_SWIRL[1], "        ", ZONE_SMALL_SWIRL[2], " → ", ZONE_SMALL_SWIRL[3], "        ", zone_width(ZONE_SMALL_SWIRL), " × ", zone_height(ZONE_SMALL_SWIRL)));
echo(str("MOON                  ", ZONE_MOON[0], " → ", ZONE_MOON[1], "        ", ZONE_MOON[2], " → ", ZONE_MOON[3], "       ", zone_width(ZONE_MOON), " × ", zone_height(ZONE_MOON)));
echo(str("STARS                 ", ZONE_STARS[0], " → ", ZONE_STARS[1], "          ", ZONE_STARS[2], " → ", ZONE_STARS[3], "       ", zone_width(ZONE_STARS), " × ", zone_height(ZONE_STARS)));
echo(str("SKY_GEARS             ", ZONE_SKY_GEARS[0], " → ", ZONE_SKY_GEARS[1], "         ", ZONE_SKY_GEARS[2], " → ", ZONE_SKY_GEARS[3], "       ", zone_width(ZONE_SKY_GEARS), " × ", zone_height(ZONE_SKY_GEARS)));
echo(str("BIRD_WIRE             ", ZONE_BIRD_WIRE[0], " → ", ZONE_BIRD_WIRE[1], "          ", ZONE_BIRD_WIRE[2], " → ", ZONE_BIRD_WIRE[3], "         ", zone_width(ZONE_BIRD_WIRE), " × ", zone_height(ZONE_BIRD_WIRE)));
echo("");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("Z-LAYERS (Back → Front):");
echo("───────────────────────────────────────────────────────────────────────────────");
echo("  Z=0      SKY_BACK         Background sky");
echo("  Z=8-16   MOON             Halos (8,12) + Core (16)");
echo("  Z=18     STARS            Star gears");
echo("  Z=22-30  SWIRLS           Halos (22,26) + Main (30)");
echo("  Z=35     WIND_PATH        Swirling wind shape");
echo("  Z=38     BELTS            Belt/chain connections");
echo("  Z=40     CLIFF            Landmass");
echo("  Z=45     LIGHTHOUSE       Lighthouse structure");
echo("  Z=48     BOTTOM_GEARS     Mechanical gears");
echo("  Z=50-60  OCEAN_WAVES      Far (50), Mid (55), Near (60)");
echo("  Z=65-70  CLIFF_WAVES      Breaking (65), Spray (70)");
echo("  Z=75     CYPRESS          Cypress tree");
echo("  Z=80     SKY_GEARS        Foreground gears");
echo("  Z=85     BIRD_WIRE        Bird wire track");
echo("  Z=95     FRAME            Mounting tabs");
echo("═══════════════════════════════════════════════════════════════════════════════");
