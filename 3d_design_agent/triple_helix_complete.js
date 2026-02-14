/*
 * TRIPLE HELIX WAVE SCULPTURE — P5.js Simulation v3.0
 * ====================================================
 * Rebuilt in native P5.js coordinates (Y-down).
 * Cross-validated against triple_helix_prototype_v2.scad.
 *
 * P5 WEBGL COORDINATES:
 *   X = right, Y = DOWN, Z = toward viewer
 *   Mechanism at top (negative Y), blocks hang below (positive Y)
 *   Horizontal plates lie in the XZ plane
 */

// ============================================
// GLOBALS
// ============================================
let theta = 0;
let HEX_POSITIONS = [];
let SLIDER_NEAREST = [];
let NUM_BLOCKS = 0;

let ampSlider, freqSlider, speedSlider;
let chkHelices, chkSliders, chkStrings, chkMatrix, chkCables, chkDrive, chkPulleys, chkFrame;

// ============================================
// PARAMETERS (mm, matched to OpenSCAD v2)
// ============================================
const AMPLITUDE = 10;
const NUM_HELICES = 3;
const HELIX_SPACING = 110;
const HELIX_SHAFT_DIA = 6;
const HELIX_LENGTH = 66;
const HELIX_DISC_DIA = 20;
const HELIX_DISC_THICK = 2;
const HELIX_NUM_DISCS = 20;
const HELIX_COLLAR_DIA = 10;
const HELIX_COLLAR_THICK = 1.5;

const SLIDERS_PER_HELIX = 11;
const SLIDER_SPACING = HELIX_LENGTH / SLIDERS_PER_HELIX;
const SLIDER_WIDTH = 12;
const SLIDER_HEIGHT = 8;
const SLIDER_DEPTH = 12;
const CABLE_DIA = 1.0;

const HEX_RINGS = 3;
const HEX_SPACING_MM = 14;
const BLOCK_DIA = 10;
const BLOCK_H = 8;
const BLOCK_WEIGHT_DIA = 4;

// VERTICAL LAYOUT (Y-down in p5)
const TOP_PLATE_Y = 0;
const HELIX_Y = 90;
const BLOCK_NOMINAL_Y = 260;

const FRAME_RADIUS = HELIX_SPACING + 40;
const FRAME_TRUSS_H = 15;

const STRING_DIA = 0.6;
const PULLEY_DIA = 5;
const PULLEY_THICK = 2;
const MOTOR_DIA = 18;
const MOTOR_H = 25;
const CHAIN_SPROCKET_DIA = 16;
const BEARING_OD = 16;
const BEARING_W = 8;

const S = 2.5;

// ============================================
// COLORS
// ============================================
const C_ALU    = [224, 224, 235];
const C_COLLAR_C = [235, 235, 242];
const C_SHAFT  = [128, 128, 140];
const C_FRAME  = [89, 89, 102];
const C_CABLE  = [115, 115, 128];
const C_BLACK  = [31, 31, 31];
const C_BRASS  = [191, 140, 51];
const C_PULLY  = [140, 140, 153];
const C_MOTOR_C = [89, 89, 102];
const C_GEAR   = [166, 128, 46];
const C_GUIDE  = [102, 102, 115];
const C_POLY   = [204, 209, 217, 50];

// ============================================
// KINEMATICS
// ============================================
function hAngR(i) { return radians(i * 120); }

function sliderDisp(j, hi, th, amp) {
  let posOnShaft = (j - (SLIDERS_PER_HELIX - 1) / 2) * SLIDER_SPACING;
  let shaftPhase = (posOnShaft / HELIX_LENGTH) * 360;
  return amp * sin(radians(th + hi * 120 + shaftPhase));
}

function sliderPos(j, hi, th, amp) {
  let a = hAngR(hi);
  let r = HELIX_SPACING * 0.75;
  let tangOff = (j - (SLIDERS_PER_HELIX - 1) / 2) * SLIDER_SPACING;
  let tx = -sin(a), tz = cos(a);
  let sx = r * cos(a) + tangOff * tx;
  let sz = r * sin(a) + tangOff * tz;
  let sy = HELIX_Y + sliderDisp(j, hi, th, amp);
  return [sx, sy, sz];
}

function sliderXZ(j, hi) {
  let a = hAngR(hi);
  let r = HELIX_SPACING * 0.75;
  let tangOff = (j - (SLIDERS_PER_HELIX - 1) / 2) * SLIDER_SPACING;
  return [r * cos(a) + tangOff * (-sin(a)),
          r * sin(a) + tangOff * cos(a)];
}

function nearestSlider(bx, bz, hi) {
  let best = 0, bestD = Infinity;
  for (let j = 0; j < SLIDERS_PER_HELIX; j++) {
    let s = sliderXZ(j, hi);
    let d = (bx - s[0]) ** 2 + (bz - s[1]) ** 2;
    if (d < bestD) { bestD = d; best = j; }
  }
  return best;
}

function blockDisp(idx, th, amp) {
  return sliderDisp(SLIDER_NEAREST[idx][0], 0, th, amp)
       + sliderDisp(SLIDER_NEAREST[idx][1], 1, th, amp)
       + sliderDisp(SLIDER_NEAREST[idx][2], 2, th, amp);
}

// ============================================
// HEX GRID
// ============================================
function hexToXZ(q, r) {
  return [HEX_SPACING_MM * (q + r * 0.5),
          HEX_SPACING_MM * (r * sqrt(3) / 2)];
}

function genHex(rings) {
  let p = [];
  for (let q = -rings; q <= rings; q++)
    for (let r = -rings; r <= rings; r++)
      if (abs(q + r) <= rings) p.push(hexToXZ(q, r));
  return p;
}

function bColor(h, maxH) {
  let t = constrain((h + maxH) / (2 * maxH), 0, 1);
  return [(0.10 + 0.90 * pow(t, 2.0)) * 255,
          (0.25 + 0.75 * pow(t, 1.3)) * 255,
          (0.55 + 0.45 * t) * 255];
}

// ============================================
// SETUP
// ============================================
function setup() {
  createCanvas(windowWidth, windowHeight, WEBGL);
  strokeCap(ROUND);

  HEX_POSITIONS = genHex(HEX_RINGS);
  NUM_BLOCKS = HEX_POSITIONS.length;

  SLIDER_NEAREST = [];
  for (let i = 0; i < NUM_BLOCKS; i++) {
    SLIDER_NEAREST.push([
      nearestSlider(HEX_POSITIONS[i][0], HEX_POSITIONS[i][1], 0),
      nearestSlider(HEX_POSITIONS[i][0], HEX_POSITIONS[i][1], 1),
      nearestSlider(HEX_POSITIONS[i][0], HEX_POSITIONS[i][1], 2)
    ]);
  }

  let px = 15, py = 10;
  createSpan('TRIPLE HELIX v3').position(px, py)
    .style('color', '#FFF').style('font-weight', 'bold').style('font-size', '14px');

  createSpan('Amplitude').position(px, py+28).style('color','#AAA').style('font-size','11px');
  ampSlider = createSlider(2, 30, AMPLITUDE, 1); ampSlider.position(px, py+44).size(120);

  createSpan('Wave Density').position(px+140, py+28).style('color','#AAA').style('font-size','11px');
  freqSlider = createSlider(0.02, 0.20, 0.08, 0.005); freqSlider.position(px+140, py+44).size(120);

  createSpan('Motor Speed').position(px+280, py+28).style('color','#AAA').style('font-size','11px');
  speedSlider = createSlider(0, 3.0, 0.8, 0.1); speedSlider.position(px+280, py+44).size(120);

  let ty = py + 72;
  chkHelices = createCheckbox('Helices', true).position(px, ty).style('color','#AAA').style('font-size','11px');
  chkSliders = createCheckbox('Sliders', true).position(px+80, ty).style('color','#AAA').style('font-size','11px');
  chkStrings = createCheckbox('Strings', true).position(px+160, ty).style('color','#AAA').style('font-size','11px');
  chkMatrix  = createCheckbox('Matrix', true).position(px+240, ty).style('color','#AAA').style('font-size','11px');
  chkCables  = createCheckbox('Cables', true).position(px+310, ty).style('color','#AAA').style('font-size','11px');
  chkDrive   = createCheckbox('Drive', true).position(px+380, ty).style('color','#AAA').style('font-size','11px');
  chkPulleys = createCheckbox('Pulleys', true).position(px+440, ty).style('color','#AAA').style('font-size','11px');
  chkFrame   = createCheckbox('Frame', true).position(px+520, ty).style('color','#AAA').style('font-size','11px');

  console.log("=== TRIPLE HELIX v3 ===");
  console.log("Blocks: " + NUM_BLOCKS + " (prime=" + (NUM_BLOCKS===37) + ")");
  console.log("Sliders: " + (SLIDERS_PER_HELIX*3));
}

// ============================================
// DRAW
// ============================================
function draw() {
  background(20);
  orbitControl();

  let amp = ampSlider.value();
  let speed = speedSlider.value();

  ambientLight(80);
  directionalLight(255, 250, 220, 0.5, 1, -0.5);
  directionalLight(50, 70, 100, -1, -0.5, 0.5);
  pointLight(255, 200, 150, 0, -200, 300);

  push();
  scale(S);
  translate(0, -BLOCK_NOMINAL_Y * 0.4, 0);

  if (chkFrame.checked()) drawFrame();
  if (chkDrive.checked()) drawDrive();
  if (chkMatrix.checked()) drawMatrix();

  for (let i = 0; i < NUM_HELICES; i++) {
    if (chkHelices.checked()) drawHelix(i, theta, amp);
    if (chkSliders.checked()) drawSliders(i, theta, amp);
    if (chkCables.checked()) drawCables(i, theta, amp);
  }

  drawBlocks(theta, amp);
  pop();

  drawHUD(amp);
  theta += speed;
}

// ============================================
// FRAME
// ============================================
function drawFrame() {
  // Top plate — horizontal in XZ. p5 cylinder axis=Y=vertical, so no rotation needed
  push(); noStroke();
  fill(C_FRAME[0], C_FRAME[1], C_FRAME[2], 50);
  translate(0, TOP_PLATE_Y, 0);
  cylinder(FRAME_RADIUS * 0.8, 3, 6);
  pop();

  for (let i = 0; i < NUM_HELICES; i++) {
    let a = hAngR(i);
    let cx = cos(a), cz = sin(a);

    stroke(C_FRAME[0], C_FRAME[1], C_FRAME[2]);
    strokeWeight(2.5);
    line(12*cx, HELIX_Y, 12*cz,
         HELIX_SPACING*cx, HELIX_Y, HELIX_SPACING*cz);

    let px = -sin(a), pz = cos(a);
    strokeWeight(1.5);
    for (let side = -1; side <= 1; side += 2) {
      let b1x = 12*cx + px*6*side, b1z = 12*cz + pz*6*side;
      let b2x = HELIX_SPACING*cx + px*6*side, b2z = HELIX_SPACING*cz + pz*6*side;
      let by = HELIX_Y + FRAME_TRUSS_H;
      line(b1x, by, b1z, b2x, by, b2z);
      line(12*cx, HELIX_Y, 12*cz, b1x, by, b1z);
      line(HELIX_SPACING*cx, HELIX_Y, HELIX_SPACING*cz, b2x, by, b2z);
    }

    // Bearing housing — cylinder along shaft tangent
    push(); noStroke();
    fill(C_ALU[0], C_ALU[1], C_ALU[2]);
    translate(HELIX_SPACING*cx, HELIX_Y, HELIX_SPACING*cz);
    // Shaft tangent is (-sin(a), 0, cos(a)). To align cylinder with tangent:
    // default cylinder axis = Y. We need it along tangent in XZ plane.
    // rotateX(90) tips Y->Z, then rotateY to align with tangent angle
    rotateY(a + HALF_PI);
    rotateX(HALF_PI);
    cylinder(BEARING_OD/2, BEARING_W, 12);
    pop();
  }

  // Vertical legs
  for (let i = 0; i < 3; i++) {
    let a = hAngR(i) + PI/3;
    let lx = FRAME_RADIUS * 0.85 * cos(a);
    let lz = FRAME_RADIUS * 0.85 * sin(a);
    stroke(C_FRAME[0], C_FRAME[1], C_FRAME[2]);
    strokeWeight(3);
    line(lx, TOP_PLATE_Y, lz, lx, HELIX_Y + 40, lz);
  }

  // Central hub — vertical cylinder at hub
  push(); noStroke();
  fill(C_FRAME[0], C_FRAME[1], C_FRAME[2]);
  translate(0, HELIX_Y, 0);
  cylinder(14, 12, 12);
  pop();
}

// ============================================
// DRIVE
// ============================================
function drawDrive() {
  push(); noStroke(); fill(C_MOTOR_C[0], C_MOTOR_C[1], C_MOTOR_C[2]);
  translate(0, HELIX_Y + 35, 0);
  cylinder(MOTOR_DIA/2, MOTOR_H, 16);
  pop();

  push(); noStroke(); fill(C_SHAFT[0], C_SHAFT[1], C_SHAFT[2]);
  translate(0, HELIX_Y + 10, 0);
  cylinder(2, 20, 8);
  pop();

  push(); noStroke(); fill(C_GEAR[0], C_GEAR[1], C_GEAR[2]);
  translate(0, HELIX_Y, 0);
  cone(8, 6, 12);
  pop();

  for (let i = 0; i < NUM_HELICES; i++) {
    let a = hAngR(i);
    let hx = HELIX_SPACING*cos(a), hz = HELIX_SPACING*sin(a);

    push(); noStroke(); fill(C_GEAR[0], C_GEAR[1], C_GEAR[2]);
    translate(hx, HELIX_Y, hz);
    rotateY(a + HALF_PI); rotateX(HALF_PI);
    cylinder(CHAIN_SPROCKET_DIA/2, 3, 16);
    pop();

    let ni = (i+1)%3;
    let a2 = hAngR(ni);
    let hx2 = HELIX_SPACING*cos(a2), hz2 = HELIX_SPACING*sin(a2);
    stroke(70,70,80); strokeWeight(1.2);
    for (let s = 0; s < 10; s++) {
      let t1 = s/10, t2 = (s+1)/10;
      line(hx*(1-t1)+hx2*t1, HELIX_Y, hz*(1-t1)+hz2*t1,
           hx*(1-t2)+hx2*t2, HELIX_Y, hz*(1-t2)+hz2*t2);
    }
  }
}

// ============================================
// HELIX CAM — Offset-Disc Spiral
// ============================================
// Construction (matching OpenSCAD exactly):
// 1. Shaft runs HORIZONTALLY along TANGENT direction in XZ plane
// 2. Each disc offset from shaft center by ECCENTRICITY
// 3. Offset rotates around shaft axis as we move along shaft -> corkscrew
// 4. Offset plane is perpendicular to shaft:
//    basis1 = RADIAL direction (in XZ plane, toward center)
//    basis2 = VERTICAL direction (Y axis)
// 5. offset = ecc * cos(phase) * RADIAL + ecc * sin(phase) * UP

function drawHelix(idx, th, amp) {
  let a = hAngR(idx);
  let basePhase = th + idx * 120;
  let hx = HELIX_SPACING * cos(a);
  let hz = HELIX_SPACING * sin(a);

  // Tangent direction (along shaft, in XZ plane)
  let tx = -sin(a), tz = cos(a);
  // Radial direction (toward center, in XZ plane)
  let rx = cos(a), rz = sin(a);

  // --- CENTRAL SHAFT LINE ---
  let shaftHalf = HELIX_LENGTH / 2 + 10;
  stroke(C_SHAFT[0], C_SHAFT[1], C_SHAFT[2]);
  strokeWeight(HELIX_SHAFT_DIA * 0.4);
  line(hx + tx*(-shaftHalf), HELIX_Y, hz + tz*(-shaftHalf),
       hx + tx*shaftHalf,    HELIX_Y, hz + tz*shaftHalf);

  // --- OFFSET DISCS ---
  let dSp = HELIX_LENGTH / HELIX_NUM_DISCS;

  for (let d = 0; d < HELIX_NUM_DISCS; d++) {
    let discPhase = basePhase + d * (360 / HELIX_NUM_DISCS);
    let dPos = d * dSp - HELIX_LENGTH / 2 + dSp / 2;

    // Shaft-center point for this disc
    let shX = hx + tx * dPos;
    let shZ = hz + tz * dPos;

    // Eccentric offset rotates in plane perpendicular to shaft
    // cos(phase) -> radial component, sin(phase) -> vertical component
    let eccCos = amp * cos(radians(discPhase));
    let eccSin = amp * sin(radians(discPhase));

    let discX = shX + rx * eccCos;
    let discY = HELIX_Y - eccSin;   // minus because Y-down, offset goes UP
    let discZ = shZ + rz * eccCos;

    // Draw disc perpendicular to shaft
    // p5 cylinder axis = Y (vertical by default)
    // Need axis = tangent direction. Tangent angle in XZ = (a + 90deg)
    push(); noStroke();
    fill(C_ALU[0], C_ALU[1], C_ALU[2], 210);
    translate(discX, discY, discZ);
    // Step 1: rotateY to face tangent direction in XZ plane
    rotateY(a + HALF_PI);
    // Step 2: rotateX to tip cylinder axis from Y into tangent direction
    rotateX(HALF_PI);
    cylinder(HELIX_DISC_DIA / 2, HELIX_DISC_THICK, 12);
    pop();

    // Collar between discs (centered on shaft, no offset)
    if (d < HELIX_NUM_DISCS - 1) {
      let cPos = (d + 1) * dSp - HELIX_LENGTH / 2;
      push(); noStroke();
      fill(C_COLLAR_C[0], C_COLLAR_C[1], C_COLLAR_C[2]);
      translate(hx + tx * cPos, HELIX_Y, hz + tz * cPos);
      rotateY(a + HALF_PI);
      rotateX(HALF_PI);
      cylinder(HELIX_COLLAR_DIA / 2, HELIX_COLLAR_THICK, 8);
      pop();
    }
  }

  // Bearing flanges at each end
  for (let end = -1; end <= 1; end += 2) {
    push(); noStroke(); fill(C_BRASS[0], C_BRASS[1], C_BRASS[2]);
    translate(hx + tx*(end*(HELIX_LENGTH/2+2)), HELIX_Y,
              hz + tz*(end*(HELIX_LENGTH/2+2)));
    rotateY(a + HALF_PI);
    rotateX(HALF_PI);
    cylinder((HELIX_SHAFT_DIA + 4) / 2, 3, 8);
    pop();
  }
}

// ============================================
// SLIDERS
// ============================================
function drawSliders(idx, th, amp) {
  let a = hAngR(idx);

  for (let j = 0; j < SLIDERS_PER_HELIX; j++) {
    let sp = sliderPos(j, idx, th, amp);

    push(); noStroke();
    fill(C_ALU[0], C_ALU[1], C_ALU[2]);
    translate(sp[0], sp[1], sp[2]);
    box(SLIDER_WIDTH, SLIDER_HEIGHT, SLIDER_DEPTH);
    pop();

    push(); noStroke(); fill(C_BRASS[0], C_BRASS[1], C_BRASS[2]);
    translate(sp[0], sp[1] + SLIDER_HEIGHT/2 + 1, sp[2]);
    cylinder(1.25, 4, 6);
    pop();

    let sxz = sliderXZ(j, idx);
    let railH = amp * 2 + 20;
    stroke(C_GUIDE[0], C_GUIDE[1], C_GUIDE[2], 80); strokeWeight(0.8);
    for (let side = -1; side <= 1; side += 2) {
      let ox = sxz[0] + side*(SLIDER_DEPTH/2+2)*cos(a);
      let oz = sxz[1] + side*(SLIDER_DEPTH/2+2)*sin(a);
      line(ox, HELIX_Y - railH/2, oz, ox, HELIX_Y + railH/2, oz);
    }
  }
}

// ============================================
// CABLES
// ============================================
function drawCables(idx, th, amp) {
  let a = hAngR(idx);
  let hcx = HELIX_SPACING*cos(a), hcz = HELIX_SPACING*sin(a);

  stroke(C_CABLE[0], C_CABLE[1], C_CABLE[2]); strokeWeight(CABLE_DIA * 0.7);

  for (let j = 0; j < SLIDERS_PER_HELIX; j++) {
    let sp = sliderPos(j, idx, th, amp);

    for (let step = 0; step < 4; step++) {
      let a1 = a + step * HALF_PI/4;
      let a2 = a + (step+1) * HALF_PI/4;
      line(hcx + (HELIX_DISC_DIA/2)*cos(a1), HELIX_Y, hcz + (HELIX_DISC_DIA/2)*sin(a1),
           hcx + (HELIX_DISC_DIA/2)*cos(a2), HELIX_Y, hcz + (HELIX_DISC_DIA/2)*sin(a2));
    }

    let depA = a + HALF_PI;
    line(hcx + (HELIX_DISC_DIA/2)*cos(depA), HELIX_Y, hcz + (HELIX_DISC_DIA/2)*sin(depA),
         sp[0], sp[1], sp[2]);
  }
}

// ============================================
// MATRIX — 3 Horizontal Polycarbonate Sheets
// ============================================
function drawMatrix() {
  let midY = (TOP_PLATE_Y + HELIX_Y) / 2;
  let sheetR = FRAME_RADIUS * 0.9;

  for (let tier = 0; tier < 3; tier++) {
    let ty = midY + (tier - 1) * 14;

    // Flat horizontal sheet — cylinder axis=Y=vertical, perfect for a thin disc
    push(); noStroke();
    fill(C_POLY[0], C_POLY[1], C_POLY[2], C_POLY[3]);
    translate(0, ty, 0);
    cylinder(sheetR * 0.75, 2.5, 6);
    pop();

    for (let i = 0; i < NUM_BLOCKS; i++) {
      push(); noStroke();
      fill(C_PULLY[0], C_PULLY[1], C_PULLY[2]);
      translate(HEX_POSITIONS[i][0], ty, HEX_POSITIONS[i][1]);
      cylinder(2, 3, 6);
      pop();
    }
  }
}

// ============================================
// BLOCKS + STRINGS + PULLEYS
// ============================================
function drawBlocks(th, amp) {
  let maxH = 3 * amp;

  for (let i = 0; i < NUM_BLOCKS; i++) {
    let bx = HEX_POSITIONS[i][0], bz = HEX_POSITIONS[i][1];
    let h = blockDisp(i, th, amp);
    let by = BLOCK_NOMINAL_Y + h;
    let col = bColor(h, maxH);

    push(); noStroke(); fill(col[0], col[1], col[2]);
    translate(bx, by, bz);
    cylinder(BLOCK_DIA/2, BLOCK_H, 6);
    pop();

    push(); noStroke(); fill(C_BRASS[0], C_BRASS[1], C_BRASS[2]);
    translate(bx, by - BLOCK_H/2 - 0.5, bz);
    torus(1.5, 0.4, 8, 6);
    pop();

    push(); noStroke(); fill(102, 102, 115);
    translate(bx, by + BLOCK_H/2 + 1.5, bz);
    cylinder(BLOCK_WEIGHT_DIA/2 + 1, 2.5, 8);
    pop();

    if (chkStrings.checked()) {
      let s0 = sliderPos(SLIDER_NEAREST[i][0], 0, th, amp);
      let s1 = sliderPos(SLIDER_NEAREST[i][1], 1, th, amp);
      let s2 = sliderPos(SLIDER_NEAREST[i][2], 2, th, amp);
      let m = 6;

      let wp = [
        [bx, TOP_PLATE_Y + 2, bz],
        [s2[0], s2[1] - m, s2[2]],
        s2,
        [s2[0], s2[1] + m, s2[2]],
        [(s2[0]+s1[0])/2, (s2[1]+s1[1])/2, (s2[2]+s1[2])/2],
        [s1[0], s1[1] - m, s1[2]],
        s1,
        [s1[0], s1[1] + m, s1[2]],
        [(s1[0]+s0[0])/2, (s1[1]+s0[1])/2, (s1[2]+s0[2])/2],
        [s0[0], s0[1] - m, s0[2]],
        s0,
        [s0[0], s0[1] + m, s0[2]],
        [bx, by - BLOCK_H/2, bz]
      ];

      stroke(C_BLACK[0], C_BLACK[1], C_BLACK[2], 120);
      strokeWeight(STRING_DIA * 0.5);
      for (let w = 0; w < wp.length - 1; w++)
        line(wp[w][0], wp[w][1], wp[w][2], wp[w+1][0], wp[w+1][1], wp[w+1][2]);

      if (chkPulleys.checked()) {
        let pp = [wp[1], wp[3], wp[5], wp[7], wp[9], wp[11]];
        for (let p = 0; p < 6; p++) {
          push(); noStroke();
          fill(C_PULLY[0], C_PULLY[1], C_PULLY[2]);
          translate(pp[p][0], pp[p][1], pp[p][2]);
          rotateZ(HALF_PI);
          cylinder(PULLEY_DIA/2, PULLEY_THICK, 8);
          pop();
        }
      }
    }
  }
}

// ============================================
// HUD
// ============================================
function drawHUD(amp) {
  push();
  fill(0, 0, 0, 150); noStroke();
  rect(-width/2, height/2 - 35, width, 35);
  fill(190); textSize(11); textAlign(LEFT);
  let wn = freqSlider.value();
  text("Blocks: " + NUM_BLOCKS + " (37=prime)  |  Sliders: " + (SLIDERS_PER_HELIX*3) +
    "  |  Amp: " + amp + "mm  |  WL: ~" + Math.round(2*Math.PI/wn) +
    "mm  |  Motor: " + theta.toFixed(0) + "\u00B0  |  Travel: \u00B1" + (3*amp) + "mm",
    -width/2 + 15, height/2 - 12);
  pop();
}

function windowResized() { resizeCanvas(windowWidth, windowHeight); }
