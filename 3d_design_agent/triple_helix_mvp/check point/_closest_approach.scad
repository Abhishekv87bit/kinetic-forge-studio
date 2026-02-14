include <config_v4.scad>

// Find the closest approach of each arm to the shaft axis.
// Arm beams run from junction to star tip as parametric lines.
// Shaft axis runs through helix center in helix_a direction.
//
// For each arm in the corridor, find the fraction f where the arm
// is closest to the shaft axis (minimum perpendicular distance).

JR = 170; STR = 354;
HR_val = 354 / sqrt(3) + 78 / (2 * tan(30));  // 271.9

// Do all 3 helices, but they're symmetric so H3 is representative
for (hi = [0:2]) {
    helix_a = [180, 300, 60][hi];
    pairs = [[3,4],[5,0],[1,2]];
    arms_defs = [[0,-37],[0,37],[120,83],[120,157],[240,203],[240,277]];
    
    hcx = HR_val * cos(helix_a);
    hcy = HR_val * sin(helix_a);
    sdx = cos(helix_a);
    sdy = sin(helix_a);
    
    for (side = [0:1]) {
        ai = pairs[hi][side];
        s_ang = arms_defs[ai][0];
        t_ang = arms_defs[ai][1];
        
        // Arm line: P(f) = junction + f*(tip - junction), f in [0,1]
        jx = JR*cos(s_ang); jy = JR*sin(s_ang);
        tx = STR*cos(t_ang); ty = STR*sin(t_ang);
        dx = tx - jx; dy = ty - jy;
        
        // Perpendicular distance from P(f) to shaft line:
        // d(f) = |(P(f) - hc) × shaft_dir| / |shaft_dir|
        // Since shaft_dir is unit: d(f) = |(jx+f*dx-hcx)*sdy - (jy+f*dy-hcy)*sdx|
        // = |A + f*B| where A = (jx-hcx)*sdy - (jy-hcy)*sdx, B = dx*sdy - dy*sdx
        A = (jx-hcx)*sdy - (jy-hcy)*sdx;
        B = dx*sdy - dy*sdx;
        
        // Minimum at f = -A/B (if B != 0)
        f_min = (abs(B) > 0.01) ? -A/B : 0.5;
        f_clamped = max(0, min(1, f_min));
        
        // Distance at minimum
        d_min = abs(A + f_clamped * B);
        
        // XY position on arm at f_clamped
        px = jx + f_clamped*dx;
        py = jy + f_clamped*dy;
        
        // Shaft projection at this point
        proj = (px-hcx)*sdx + (py-hcy)*sdy;
        
        // Also check distance at f=0.75 for reference
        d_75 = abs(A + 0.75 * B);
        proj_75 = (jx+0.75*dx - hcx)*sdx + (jy+0.75*dy - hcy)*sdy;
        
        echo(str("H", hi+1, " A", ai, ": closest@f=", round(f_clamped*1000)/1000,
                 " dist=", round(d_min*10)/10, "mm",
                 " XY=[", round(px*10)/10, ",", round(py*10)/10, "]",
                 " shaft_proj=", round(proj*10)/10, "mm"));
        echo(str("  @f=0.75: dist=", round(d_75*10)/10, " proj=", round(proj_75*10)/10));
        echo(str("  @f=1.0 (tip): dist=", round(abs(A+B)*10)/10,
                 " proj=", round(((tx-hcx)*sdx+(ty-hcy)*sdy)*10)/10));
    }
    echo("");
}

echo(str("Cam body: -91 to +91mm | Journals: ±101mm | HELIX_R=", round(HR_val*10)/10));
