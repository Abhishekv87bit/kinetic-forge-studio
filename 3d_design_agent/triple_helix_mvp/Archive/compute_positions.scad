// =========================================================
// COMPUTE VALID BLOCK POSITIONS
// =========================================================
// Find eyelet positions that exist in ALL 3 tier rotations.
// A block position (bx, by) is valid if:
//   - In Tier 1 (0°): (bx, by) matches an eyelet
//   - In Tier 2 (120°): rot(-120°) × (bx,by) matches an eyelet
//   - In Tier 3 (240°): rot(-240°) × (bx,by) matches an eyelet
//
// With eyelets on straight channels (V5 style),
// this constrains which positions can be blocks.
// =========================================================

$fn = 36;

// --- Tier parameters ---
N_CHANNELS    = 5;
EYELET_COUNTS = [3, 4, 5, 4, 3];
EYELET_PITCH  = 20.0;
STACK_OFFSET  = 4.5;
CH_GAP        = 3.0;
WALL_T        = 1.5;

CH_YS = [for (i = [0:N_CHANNELS-1])
    (i - (N_CHANNELS-1)/2) * STACK_OFFSET
];

HEX_FTF = 116;
HEX_R   = HEX_FTF / (2 * cos(30));

// --- All eyelet positions in tier-local frame ---
// Eyelet (ch, i) is at X = (i - (count-1)/2) * pitch, Y = CH_YS[ch]

function _eyelet_pos(ch, i) =
    [(i - (EYELET_COUNTS[ch]-1)/2) * EYELET_PITCH, CH_YS[ch]];

ALL_EYELETS = [for (ch = [0:N_CHANNELS-1])
               for (i = [0:EYELET_COUNTS[ch]-1])
                   _eyelet_pos(ch, i)];

// --- Rotation ---
function _rot2d(p, a) = [p[0]*cos(a) - p[1]*sin(a),
                          p[0]*sin(a) + p[1]*cos(a)];

// --- Check if position p matches any eyelet (within tolerance) ---
function _matches_eyelet(p, tol=1.0) =
    len([for (e = ALL_EYELETS)
         if (abs(e[0]-p[0]) < tol && abs(e[1]-p[1]) < tol) 1]) > 0;

// --- Find valid block positions ---
// Start from Tier 1 eyelets, check if they match after rotation
VALID_BLOCKS = [for (e = ALL_EYELETS)
    let(
        // Rotate block position into Tier 2 local frame
        p2 = _rot2d(e, -120),
        // Rotate block position into Tier 3 local frame
        p3 = _rot2d(e, -240),
        // Check if both match an eyelet
        ok2 = _matches_eyelet(p2, 1.5),
        ok3 = _matches_eyelet(p3, 1.5)
    )
    if (ok2 && ok3) e
];

echo(str("Total eyelets per tier: ", len(ALL_EYELETS)));
echo(str("Valid block positions (in all 3 rotations): ", len(VALID_BLOCKS)));

// Show all eyelets
for (e = ALL_EYELETS) {
    color("yellow", 0.3)
    translate([e[0], e[1], 0])
        cylinder(d=3, h=1, center=true);
}

// Show valid blocks
for (b = VALID_BLOCKS) {
    color("lime")
    translate([b[0], b[1], 2])
        cylinder(d=4, h=2, center=true);
    echo(str("  Block at (", round(b[0]*10)/10, ", ", round(b[1]*10)/10, ")"));
}

// Show hex outline
color("white", 0.2)
linear_extrude(0.1)
    rotate([0, 0, 30])
        difference() {
            circle(r=HEX_R, $fn=6);
            circle(r=HEX_R-1, $fn=6);
        }

// Show rotated eyelet grids
for (a = [120, 240]) {
    color(a == 120 ? "green" : "blue", 0.2)
    rotate([0, 0, a])
        for (e = ALL_EYELETS)
            translate([e[0], e[1], -1])
                cylinder(d=2, h=0.5, center=true);
}
