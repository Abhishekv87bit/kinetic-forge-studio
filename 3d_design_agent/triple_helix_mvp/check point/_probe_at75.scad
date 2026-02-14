include <config_v4.scad>

// V_ANGLE and ARM_DEFS are in hex_frame, not config. Use literal values.
// _HALF_V = 74/2 = 37
// ARM_DEFS = [[0,-37],[0,37],[120,83],[120,157],[240,203],[240,277]]
// JUNCTION_R = 170, STAR_TIP_R = 354

JR = 170;
STR = 354;

// arm index: [stub_angle, tip_angle]
ARMS = [[0,-37],[0,37],[120,83],[120,157],[240,203],[240,277]];

function at75(ai) = 
    let(s = ARMS[ai][0], t = ARMS[ai][1])
    [JR*cos(s) + (STR*cos(t) - JR*cos(s))*0.75,
     JR*sin(s) + (STR*sin(t) - JR*sin(s))*0.75];

function sproj(px, py, hcx, hcy, sdx, sdy) = (px-hcx)*sdx + (py-hcy)*sdy;
function sperp(px, py, hcx, hcy, sdx, sdy) = 
    let(p = sproj(px,py,hcx,hcy,sdx,sdy),
        sx = hcx+p*sdx, sy = hcy+p*sdy)
    sqrt((px-sx)*(px-sx)+(py-sy)*(py-sy));

HR = HELIX_R;  // 271.9

// H1 (180°): arms 3,4
p3 = at75(3); p4 = at75(4);
hc1x = HR*cos(180); hc1y = HR*sin(180);
echo(str("=== H1 (180°) | center=[", round(hc1x*10)/10, ",", round(hc1y*10)/10, "] ==="));
echo(str("  A3@75=[", round(p3[0]*10)/10, ",", round(p3[1]*10)/10, "] proj=", round(sproj(p3[0],p3[1],hc1x,hc1y,cos(180),sin(180))*10)/10, " perp=", round(sperp(p3[0],p3[1],hc1x,hc1y,cos(180),sin(180))*10)/10));
echo(str("  A4@75=[", round(p4[0]*10)/10, ",", round(p4[1]*10)/10, "] proj=", round(sproj(p4[0],p4[1],hc1x,hc1y,cos(180),sin(180))*10)/10, " perp=", round(sperp(p4[0],p4[1],hc1x,hc1y,cos(180),sin(180))*10)/10));
echo(str("  spread=", round(abs(sproj(p3[0],p3[1],hc1x,hc1y,cos(180),sin(180)) - sproj(p4[0],p4[1],hc1x,hc1y,cos(180),sin(180)))*10)/10));

// H2 (300°): arms 5,0
p5 = at75(5); p0 = at75(0);
hc2x = HR*cos(300); hc2y = HR*sin(300);
echo(str("=== H2 (300°) | center=[", round(hc2x*10)/10, ",", round(hc2y*10)/10, "] ==="));
echo(str("  A5@75=[", round(p5[0]*10)/10, ",", round(p5[1]*10)/10, "] proj=", round(sproj(p5[0],p5[1],hc2x,hc2y,cos(300),sin(300))*10)/10, " perp=", round(sperp(p5[0],p5[1],hc2x,hc2y,cos(300),sin(300))*10)/10));
echo(str("  A0@75=[", round(p0[0]*10)/10, ",", round(p0[1]*10)/10, "] proj=", round(sproj(p0[0],p0[1],hc2x,hc2y,cos(300),sin(300))*10)/10, " perp=", round(sperp(p0[0],p0[1],hc2x,hc2y,cos(300),sin(300))*10)/10));
echo(str("  spread=", round(abs(sproj(p5[0],p5[1],hc2x,hc2y,cos(300),sin(300)) - sproj(p0[0],p0[1],hc2x,hc2y,cos(300),sin(300)))*10)/10));

// H3 (60°): arms 1,2
p1 = at75(1); p2 = at75(2);
hc3x = HR*cos(60); hc3y = HR*sin(60);
echo(str("=== H3 (60°) | center=[", round(hc3x*10)/10, ",", round(hc3y*10)/10, "] ==="));
echo(str("  A1@75=[", round(p1[0]*10)/10, ",", round(p1[1]*10)/10, "] proj=", round(sproj(p1[0],p1[1],hc3x,hc3y,cos(60),sin(60))*10)/10, " perp=", round(sperp(p1[0],p1[1],hc3x,hc3y,cos(60),sin(60))*10)/10));
echo(str("  A2@75=[", round(p2[0]*10)/10, ",", round(p2[1]*10)/10, "] proj=", round(sproj(p2[0],p2[1],hc3x,hc3y,cos(60),sin(60))*10)/10, " perp=", round(sperp(p2[0],p2[1],hc3x,hc3y,cos(60),sin(60))*10)/10));
echo(str("  spread=", round(abs(sproj(p1[0],p1[1],hc3x,hc3y,cos(60),sin(60)) - sproj(p2[0],p2[1],hc3x,hc3y,cos(60),sin(60)))*10)/10));

echo(str("Cam body: -91 to +91mm | Journals: -101 to +101mm"));
