include <config_v4.scad>

// Values from hex_frame: HELIX_R=271.9, JUNCTION_R=170, STAR_TIP_R=354
HR = 354 / sqrt(3) + 78 / (2 * tan(30));  // HEXAGRAM_INNER_R + _V_PUSH
JR = 170;
STR = 354;

echo(str("Computed HELIX_R = ", round(HR*10)/10));

// arm@75 positions (already verified from markers)
// A3@75=[-265.6,140.5], A4@75=[-265.6,-140.5]
// A5@75=[11.1,-300.3],  A0@75=[254.5,-159.8]
// A1@75=[254.5,159.8],  A2@75=[11.1,300.3]

function sproj(px,py,hcx,hcy,sdx,sdy) = (px-hcx)*sdx + (py-hcy)*sdy;
function sperp(px,py,hcx,hcy,sdx,sdy) = 
    let(p=sproj(px,py,hcx,hcy,sdx,sdy), sx=hcx+p*sdx, sy=hcy+p*sdy)
    sqrt((px-sx)*(px-sx)+(py-sy)*(py-sy));

// H1 (180deg)
hc1x = HR*cos(180); hc1y = HR*sin(180);
echo(str("=== H1 (180°) center=[",round(hc1x*10)/10,",",round(hc1y*10)/10,"] ==="));
echo(str("  A3@75 proj=", round(sproj(-265.6,140.5,hc1x,hc1y,cos(180),sin(180))*10)/10,
         " perp=", round(sperp(-265.6,140.5,hc1x,hc1y,cos(180),sin(180))*10)/10));
echo(str("  A4@75 proj=", round(sproj(-265.6,-140.5,hc1x,hc1y,cos(180),sin(180))*10)/10,
         " perp=", round(sperp(-265.6,-140.5,hc1x,hc1y,cos(180),sin(180))*10)/10));

// H2 (300deg)
hc2x = HR*cos(300); hc2y = HR*sin(300);
echo(str("=== H2 (300°) center=[",round(hc2x*10)/10,",",round(hc2y*10)/10,"] ==="));
echo(str("  A5@75 proj=", round(sproj(11.1,-300.3,hc2x,hc2y,cos(300),sin(300))*10)/10,
         " perp=", round(sperp(11.1,-300.3,hc2x,hc2y,cos(300),sin(300))*10)/10));
echo(str("  A0@75 proj=", round(sproj(254.5,-159.8,hc2x,hc2y,cos(300),sin(300))*10)/10,
         " perp=", round(sperp(254.5,-159.8,hc2x,hc2y,cos(300),sin(300))*10)/10));

// H3 (60deg)
hc3x = HR*cos(60); hc3y = HR*sin(60);
echo(str("=== H3 (60°) center=[",round(hc3x*10)/10,",",round(hc3y*10)/10,"] ==="));
echo(str("  A1@75 proj=", round(sproj(254.5,159.8,hc3x,hc3y,cos(60),sin(60))*10)/10,
         " perp=", round(sperp(254.5,159.8,hc3x,hc3y,cos(60),sin(60))*10)/10));
echo(str("  A2@75 proj=", round(sproj(11.1,300.3,hc3x,hc3y,cos(60),sin(60))*10)/10,
         " perp=", round(sperp(11.1,300.3,hc3x,hc3y,cos(60),sin(60))*10)/10));

echo(str("Cam body: -91 to +91mm | Journals: -101 to +101mm"));
echo(str("Journal ends: near=-101mm far=+101mm"));
