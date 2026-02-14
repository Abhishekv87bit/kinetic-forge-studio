// SIMPLE TEST - Just to verify OpenSCAD is rendering

// Test 1: Basic cube
color("red")
translate([0, 0, 0])
    cube([50, 50, 50]);

// Test 2: Basic cylinder
color("blue")
translate([100, 0, 25])
    cylinder(h=50, d=30, $fn=32);

// Test 3: Basic sphere
color("green")
translate([50, 100, 25])
    sphere(d=40, $fn=32);

echo("If you see this message, OpenSCAD is working!");
echo("You should see: red cube, blue cylinder, green sphere");
