// Simple test at ocean zone location

// Ocean zone
OCEAN_X_START = 150;
OCEAN_Y_DEPTH = 65;
OCEAN_Z_HEIGHT = 65;

// Just put a colored cube at the ocean zone
color("cyan")
translate([OCEAN_X_START + 50, OCEAN_Y_DEPTH/2, OCEAN_Z_HEIGHT/2])
    cube([100, 65, 65], center=true);

// And a simple cylinder as a "shaft"
color("red")
translate([OCEAN_X_START + 50, 30, 32])
    rotate([0, 90, 0])
        cylinder(d=10, h=80, center=true, $fn=24);

echo("Test at ocean zone location - you should see cyan box and red cylinder");
