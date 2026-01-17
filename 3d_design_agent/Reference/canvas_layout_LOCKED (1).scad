// ═══════════════════════════════════════════════════════════════════════════
// STARRY NIGHT - LOCKED CANVAS LAYOUT
// ═══════════════════════════════════════════════════════════════════════════
// *** BOUNDARIES ARE LOCKED - ELEMENTS MUST FIT WITHIN THEIR ZONES ***
// *** DO NOT MODIFY ZONE DEFINITIONS ***
// ═══════════════════════════════════════════════════════════════════════════
// Total printed: 350 × 250 mm (fits 350mm print bed)
// Canvas art area: 302 × 202 mm
// Mounting tabs: 24mm (sits on wooden frame)
// ═══════════════════════════════════════════════════════════════════════════
$fn = 48;

// ═══════════════════════════════════════════════════════════════════════════
// MASTER DIMENSIONS (LOCKED)
// ═══════════════════════════════════════════════════════════════════════════
TOTAL_W = 350;
TOTAL_H = 250;
TAB_WIDTH = 24;
CANVAS_W = 302;  // Art area width
CANVAS_H = 202;  // Art area height
CANVAS_DEPTH_MIN = 80;
CANVAS_DEPTH_MAX = 100;

// ═══════════════════════════════════════════════════════════════════════════
// ZONE DEFINITIONS (LOCKED - DO NOT MODIFY)
// Format: [X_MIN, X_MAX, Y_MIN, Y_MAX]
// All coordinates relative to CANVAS origin (0,0 = bottom-left of art area)
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// GROUND LEVEL ZONES (Y starts at 0)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CLIFF        = [0, 108, 0, 65];        // 108 × 65   - Left landmass
ZONE_CLIFF_WAVES  = [108, 160, 0, 69];      // 52 × 69    - Breaking waves
ZONE_OCEAN_WAVES  = [151, 302, 0, 65];      // 151 × 65   - Open water
ZONE_BOTTOM_GEARS = [164, 302, 0, 30];      // 138 × 30   - Mechanical base

// ─────────────────────────────────────────────────────────────────────────────
// VERTICAL ELEMENTS (span from ground up)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_CYPRESS      = [35, 95, 0, 121];       // 60 × 121   - Tall tree
ZONE_LIGHTHOUSE   = [73, 82, 65, 117];      // 9 × 52     - On cliff top

// ─────────────────────────────────────────────────────────────────────────────
// SKY ZONES (upper region)
// ─────────────────────────────────────────────────────────────────────────────
ZONE_WIND_PATH    = [0, 198, 105, 202];     // 198 × 97   - Swirling sky shape
ZONE_BIG_SWIRL    = [86, 160, 110, 170];    // 74 × 60    - Large swirl disc
ZONE_SMALL_SWIRL  = [151, 198, 105, 154];   // 47 × 49    - Small swirl disc
ZONE_MOON         = [231, 300, 141, 202];   // 69 × 61    - Top right
ZONE_STARS        = [0, 198, 101, 202];     // 198 × 101  - Star region
ZONE_SKY_GEARS    = [52, 216, 109, 166];    // 164 × 57   - Foreground gears

// ─────────────────────────────────────────────────────────────────────────────
// HORIZONTAL ELEMENTS
// ─────────────────────────────────────────────────────────────────────────────
ZONE_BIRD_WIRE    = [0, 302, 130, 150];     // 302 × 20   - Full width track (updated)

// ═══════════════════════════════════════════════════════════════════════════
// DERIVED VALUES FOR POSITIONING
// ═══════════════════════════════════════════════════════════════════════════

// Helper functions
function zone_x_min(zone) = zone[0];
function zone_x_max(zone) = zone[1];
function zone_y_min(zone) = zone[2];
function zone_y_max(zone) = zone[3];
function zone_width(zone) = zone[1] - zone[0];
function zone_height(zone) = zone[3] - zone[2];
function zone_center_x(zone) = (zone[0] + zone[1]) / 2;
function zone_center_y(zone) = (zone[2] + zone[3]) / 2;

// Pre-calculated centers and sizes for quick reference
CLIFF_CENTER_X = zone_center_x(ZONE_CLIFF);           // 54
CLIFF_CENTER_Y = zone_center_y(ZONE_CLIFF);           // 32.5

LIGHTHOUSE_CENTER_X = zone_center_x(ZONE_LIGHTHOUSE); // 77.5
LIGHTHOUSE_CENTER_Y = zone_center_y(ZONE_LIGHTHOUSE); // 91

CYPRESS_CENTER_X = zone_center_x(ZONE_CYPRESS);       // 65
CYPRESS_CENTER_Y = zone_center_y(ZONE_CYPRESS);       // 60.5

BIG_SWIRL_CENTER_X = zone_center_x(ZONE_BIG_SWIRL);   // 123
BIG_SWIRL_CENTER_Y = zone_center_y(ZONE_BIG_SWIRL);   // 140
BIG_SWIRL_MAX_R = min(zone_width(ZONE_BIG_SWIRL), zone_height(ZONE_BIG_SWIRL)) / 2; // 30

SMALL_SWIRL_CENTER_X = zone_center_x(ZONE_SMALL_SWIRL); // 174.5
SMALL_SWIRL_CENTER_Y = zone_center_y(ZONE_SMALL_SWIRL); // 129.5
SMALL_SWIRL_MAX_R = min(zone_width(ZONE_SMALL_SWIRL), zone_height(ZONE_SMALL_SWIRL)) / 2; // 23.5

MOON_CENTER_X = zone_center_x(ZONE_MOON);             // 265.5
MOON_CENTER_Y = zone_center_y(ZONE_MOON);             // 171.5
MOON_MAX_R = min(zone_width(ZONE_MOON), zone_height(ZONE_MOON)) / 2; // 30.5

BIRD_WIRE_Y = zone_center_y(ZONE_BIRD_WIRE);          // 138

// ═══════════════════════════════════════════════════════════════════════════
// VISUALIZATION
// ═══════════════════════════════════════════════════════════════════════════

module show_zone(zone, name, col, alpha=0.2) {
    x = zone[0];
    y = zone[2];
    w = zone[1] - zone[0];
    h = zone[3] - zone[2];
    
    color(col, alpha)
    translate([x, y, 0.1])
    square([w, h]);
    
    color(col, 0.8)
    translate([x, y, 0.2])
    difference() {
        square([w, h]);
        translate([1, 1]) square([max(1, w-2), max(1, h-2)]);
    }
    
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
    color("black", 1)
    difference() {
        square([CANVAS_W, CANVAS_H]);
        translate([0.5, 0.5]) square([CANVAS_W - 1, CANVAS_H - 1]);
    }
}

module show_grid(spacing=50) {
    color("#AAAAAA", 0.3) {
        for (x = [0 : spacing : CANVAS_W]) {
            translate([x, 0, 0.05]) square([0.3, CANVAS_H]);
        }
        for (y = [0 : spacing : CANVAS_H]) {
            translate([0, y, 0.05]) square([CANVAS_W, 0.3]);
        }
    }
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
    color("#666666", 0.3)
    translate([-TAB_WIDTH, -TAB_WIDTH, -0.1])
    difference() {
        square([TOTAL_W, TOTAL_H]);
        translate([TAB_WIDTH, TAB_WIDTH]) square([CANVAS_W, CANVAS_H]);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN VISUALIZATION
// ═══════════════════════════════════════════════════════════════════════════
show_canvas_boundary();
show_grid(50);
show_all_zones();
show_mounting_tabs_outline();

// ═══════════════════════════════════════════════════════════════════════════
// CONSOLE OUTPUT
// ═══════════════════════════════════════════════════════════════════════════
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("              STARRY NIGHT - LOCKED CANVAS LAYOUT");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("");
echo("CANVAS: 302 × 202 mm art area | 350 × 250 mm total with tabs");
echo("");
echo("═══════════════════════════════════════════════════════════════════════════════");
echo("ZONE                  X RANGE         Y RANGE         SIZE        CENTER");
echo("───────────────────────────────────────────────────────────────────────────────");
echo(str("CLIFF                 0 → 108         0 → 65          108×65      (54, 32.5)"));
echo(str("LIGHTHOUSE            73 → 82         65 → 117        9×52        (77.5, 91)"));
echo(str("CYPRESS               35 → 95         0 → 121         60×121      (65, 60.5)"));
echo(str("CLIFF_WAVES           108 → 160       0 → 69          52×69       (134, 34.5)"));
echo(str("OCEAN_WAVES           151 → 302       0 → 65          151×65      (226.5, 32.5)"));
echo(str("BOTTOM_GEARS          164 → 302       0 → 30          138×30      (233, 15)"));
echo(str("WIND_PATH             0 → 198         105 → 202       198×97      (99, 153.5)"));
echo(str("BIG_SWIRL             86 → 160        110 → 170       74×60       (123, 140)"));
echo(str("SMALL_SWIRL           151 → 198       105 → 154       47×49       (174.5, 129.5)"));
echo(str("MOON                  231 → 300       141 → 202       69×61       (265.5, 171.5)"));
echo(str("STARS                 0 → 198         101 → 202       198×101     (99, 151.5)"));
echo(str("SKY_GEARS             52 → 216        109 → 166       164×57      (134, 137.5)"));
echo(str("BIRD_WIRE             0 → 302         130 → 150       302×20      (151, 140)"));
echo("═══════════════════════════════════════════════════════════════════════════════");
