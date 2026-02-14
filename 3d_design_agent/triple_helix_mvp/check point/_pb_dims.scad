include <config_v4.scad>

// Manually compute PB dimensions (same as hex_frame)
MW = 4;  // MOUNT_WALL
BW = 5;  // BEARING_W
BOD = 19; // BEARING_OD
MTB = 4.2; // MOUNT_TAB_BOLT
GT = 3;  // GUSSET_THICK

LIP = BW * 0.4;  // 2
HOD = BOD + 2*MW; // 27
HH = BW + LIP;   // 7
BD = BOD + 0.05;  // 19.05
BOLT_D = MTB;     // 4.2
BOLT_IN = BOLT_D + MW; // 8.2
BASE_W = HOD + 2*BOLT_IN; // 43.4
BASE_L = HH + MW; // 11
BASE_T = BW;      // 5

echo(str("PB_HOUSING_OD=", HOD, " PB_HOUSING_H=", HH));
echo(str("PB_BASE_W=", BASE_W, " PB_BASE_L=", BASE_L, " PB_BASE_T=", BASE_T));
echo(str("PB_BORE=", BD, " PB_BOLT_DIA=", BOLT_D, " PB_BOLT_INSET=", BOLT_IN));
echo(str("ARM_W=20 ARM_H=14"));
echo(str("Arm gap at @75: upper_Z=12.8 lower_Z=-12.8 gap=25.6mm"));
echo(str("PB total height (base+housing): ", BASE_T + HOD/2, "mm"));
