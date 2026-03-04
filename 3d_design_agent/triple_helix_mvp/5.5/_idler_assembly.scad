// =========================================================
// IDLER ASSEMBLY TEST — STL pulley + bolt + c-clamp + parametric fork
// =========================================================
_STL_BASE = "D:/Claude local/3d_design_agent/Pulley/no-3-pulleys-and-right-angle-guides-507-mechanical-movements-model_files";

$fn = 32;

// --- STL part dimensions (measured) ---
_PULLEY_OD   = 20;
_PULLEY_H    = 20;    // along Z in STL native orientation
_BOLT_OD     = 8.5;   // bolt head OD (hex head)
_BOLT_SHAFT_D = 4.5;  // approximate shaft diameter
_BOLT_LEN    = 32.5;
_CLAMP_T     = 2;

// --- Fork design parameters ---
// The fork is a U-shaped clevis bracket:
//   - Two thin parallel plates (arms) with bolt holes
//   - Connected at bottom by a base tab
//   - Pulley sits in the gap between arms, spinning on the bolt
_FORK_WALL     = 3;       // thickness of each arm plate
_FORK_CLEARANCE = 0.5;    // gap between arm inner face and pulley face
_FORK_GAP      = _PULLEY_H + 2 * _FORK_CLEARANCE;  // inner gap between arms
_FORK_ARM_UP   = _PULLEY_OD/2 + 3;   // arm extends this far above bolt center
_FORK_ARM_DOWN = _PULLEY_OD/2 + 2;   // arm extends this far below bolt center
_FORK_ARM_W    = 12;      // arm width (front-to-back, X direction)
_FORK_BOLT_D   = _BOLT_SHAFT_D + 0.4; // clearance bore for bolt shaft
_FORK_BASE_T   = 4;       // base tab thickness (Y direction)

// Total Z span of fork
_FORK_SPAN     = _FORK_GAP + 2 * _FORK_WALL;

echo(str("Fork: gap=", _FORK_GAP, " span=", _FORK_SPAN, " arm_h=", _FORK_ARM_UP + _FORK_ARM_DOWN));
echo(str("Bolt length=", _BOLT_LEN, " vs fork span=", _FORK_SPAN));

// --- Fork module ---
// Origin = bolt axis center (where pulley center is)
// Bolt axis along Z. Fork opens upward (+Y), base at bottom (-Y).
module idler_fork() {
    color([0.6, 0.6, 0.6, 0.9])
    difference() {
        union() {
            // Left arm plate (negative Z side)
            translate([0, (_FORK_ARM_UP - _FORK_ARM_DOWN)/2,
                       -_FORK_GAP/2 - _FORK_WALL/2])
                cube([_FORK_ARM_W, _FORK_ARM_UP + _FORK_ARM_DOWN,
                      _FORK_WALL], center=true);

            // Right arm plate (positive Z side)
            translate([0, (_FORK_ARM_UP - _FORK_ARM_DOWN)/2,
                       _FORK_GAP/2 + _FORK_WALL/2])
                cube([_FORK_ARM_W, _FORK_ARM_UP + _FORK_ARM_DOWN,
                      _FORK_WALL], center=true);

            // Base tab connecting both arms at bottom
            translate([0, -_FORK_ARM_DOWN + _FORK_BASE_T/2, 0])
                cube([_FORK_ARM_W, _FORK_BASE_T, _FORK_SPAN], center=true);
        }

        // Bolt hole through both arms
        cylinder(d=_FORK_BOLT_D, h=_FORK_SPAN + 2, center=true);
    }
}

// --- Full assembly module ---
// Origin = bolt/pulley axis center
// Bolt axis along Z, fork base toward -Y, pulley between arms
module idler_assembly_stl() {
    // 1. Parametric fork body
    idler_fork();

    // 2. Big pulley — STL Z=[0,20], XY centered → shift Z by -H/2
    color([0.9, 0.75, 0.0, 0.9])
    translate([0, 0, -_PULLEY_H/2])
        import(str(_STL_BASE, "/big-pulley_x1.stl"));

    // 3. Bolt — STL Z=[0,32.5], XY centered → shift Z by -L/2
    color([0.3, 0.3, 0.3, 0.9])
    translate([0, 0, -_BOLT_LEN/2])
        import(str(_STL_BASE, "/bolt_x1.stl"));

    // 4. C-clamps — outside each fork arm
    color([0.2, 0.7, 0.3, 0.9]) {
        // Top clamp (positive Z, beyond right arm)
        translate([0, 0, _FORK_GAP/2 + _FORK_WALL + 0.5])
            import(str(_STL_BASE, "/c-clamp_x2.stl"));
        // Bottom clamp (negative Z, beyond left arm)
        translate([0, 0, -_FORK_GAP/2 - _FORK_WALL - 0.5 - _CLAMP_T])
            import(str(_STL_BASE, "/c-clamp_x2.stl"));
    }
}

// Render
idler_assembly_stl();
