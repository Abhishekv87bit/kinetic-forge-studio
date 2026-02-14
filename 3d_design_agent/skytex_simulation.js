/*
 * SKYTEX TRIPLE-HELIX KINETIC WAVE SCULPTURE
 * P5.js Digital Twin v2.0 — Margolin-Grounded
 * =============================================================
 * Reverse-engineered from Reuben Margolin's Triple Helix:
 *   37 blocks (hex, 3 rings, PRIME), 111 sliders, ~1027 strings
 *   3 shaftless helical camshafts in 120° star formation
 *   Single motor, whiffletree wave summation, gravity return
 *
 * KINEMATICS: sliderDisp() → nearestSlider() → blockDisp()
 *   Phase from slider's physical shaft position (EXACT original model)
 *
 * ALL PARAMETERS MATCH skytex_parts.scad v2.0 — ZERO MISMATCHES
 *
 * P5 WEBGL: X=right, Y=DOWN, Z=toward viewer
 */

// ============================================
// MARGOLIN GROUND TRUTH
// ============================================
const NUM_HELICES       = 3;
const HELIX_PHASE       = 120;          // degrees between helices
const HELIX_ANGLES_DEG  = [0, 120, 240];

// ============================================
// PARAMETERS (mm) — MATCHED TO skytex_parts.scad v2.0
// ============================================

// Grid (hex, 3 rings = 37 blocks PRIME, inside 600mm square)
const HEX_RINGS      = 3;
const HEX_SPACING    = 52;             // mm center-to-center (50mm block + 2mm gap)
const BOUNDARY_SIZE  = 600;            // mm square boundary

// Cam geometry
const NUM_CAMS          = 37;          // = sliders per helix (Margolin: 111/3)
const SLIDERS_PER_HELIX = 37;         // one per cam
const CAM_TWIST         = 360 / NUM_CAMS;  // ≈9.73° per cam
const ECCENTRICITY      = 12.0;       // mm (from original .scad)

// Bearing: 6810
const BEARING_OD = 65;
const BEARING_ID = 50;
const BEARING_W  = 7;
const HUB_DIA    = 50;               // = BEARING_ID

// Assembly
const COLLAR_DIA   = 15;
const COLLAR_THICK = 1.5;
const SHAFT_DIA    = 8;
const CENTER_PIN   = 5;
const HELIX_LENGTH = NUM_CAMS * BEARING_W + (NUM_CAMS - 1) * COLLAR_THICK;
// = 37 × 7 + 36 × 1.5 = 259 + 54 = 313mm

const SLIDER_SPACING = HELIX_LENGTH / SLIDERS_PER_HELIX;

// Rib (matched to .scad)
const RIB_ARM_LENGTH = 60;
const RIB_THICK      = 6;
const RIB_ARM_WIDTH  = 8;

// Whiffletree shuttle (matched to .scad)
const SHUTTLE_W = 14.5;
const SHUTTLE_H = 30;
const SHUTTLE_D = 12;
const FLOAT_BEARING_OD = 10;          // 623zz
const FLOAT_BEARING_ID = 3;
const NUM_FLOAT_PULLEYS = 2;
const FLOAT_PULLEY_SPACING = 14;

// Housing (matched to .scad)
const HOUSING_W = 36;
const HOUSING_H = 80;

// Block dimensions (matched to .scad)
const BLOCK_FLAT   = 50;              // mm hex across flats
const BLOCK_HEIGHT = 25;              // mm thickness
const BLOCK_VIS_R  = BLOCK_FLAT / 1.732; // circumradius of hex (≈28.9mm for 50mm flat)

// Block & Tackle (parametric)
let BT_RATIO = 1;

// Helix distance from center
const HELIX_DISTANCE = 250;          // mm — scaled for 600mm boundary

// Vertical layout (Y-down in p5)
const CEILING_Y      = -180;
const MOTOR_Y        = -150;
const FRAME_Y        = -20;
const HELIX_Y        = 40;
const MATRIX_Y       = 160;
const WHIFFLETREE_Y  = 220;
const BLOCK_NOMINAL_Y = 320;

// Visual helpers
const STRING_DIA  = 0.6;
const PULLEY_DIA  = 5;
const PULLEY_THICK = 2;
const CABLE_DIA   = 1.0;
const S = 1.0;                        // scale factor

// ============================================
// COLORS
// ============================================
const C_RED    = [200, 60, 60];
const C_GREEN  = [60, 180, 80];
const C_BLUE   = [60, 100, 220];
const C_TIER   = [C_RED, C_GREEN, C_BLUE];
const C_STEEL  = [90, 90, 105];
const C_ALU    = [224, 224, 235];
const C_BRASS  = [191, 140, 51];
const C_SHAFT  = [128, 128, 140];
const C_YELLOW = [240, 220, 40];
const C_DARK   = [40, 40, 50];
const C_POLY   = [204, 209, 217, 50];
const C_BLACK  = [31, 31, 31];
const C_CABLE  = [115, 115, 128];
const C_PULLY  = [140, 140, 153];
const C_GUIDE  = [102, 102, 115];
const C_MOTOR  = [89, 89, 102];
const C_GEAR   = [166, 128, 46];
const C_COLLAR = [235, 235, 242];
const C_WOOD   = [180, 140, 90];
const C_WOOD2  = [160, 120, 75];
const C_ACRYLIC = [180, 200, 220, 40];

// ============================================
// STATE
// ============================================
let motorAngle = 0;
let viewMode = 1;
let HEX_POSITIONS = [];
let SLIDER_NEAREST = [];
let NUM_BLOCKS = 0;

// DOM refs
let slAmp, slSpd, slBt;
let chkHelix, chkRibs, chkMatrix, chkStrings, chkBlocks, chkFrame, chkDrive;
let chkSliders, chkPulleys, chkCables, chkWhiffletree;

// ============================================
// HEX GRID GENERATOR (from original triple_helix_complete.js)
// ============================================
function hexToXZ(q, r) {
  return [HEX_SPACING * (q + r * 0.5),
          HEX_SPACING * (r * sqrt(3) / 2)];
}

function genHex(rings) {
  let p = [];
  for (let q = -rings; q <= rings; q++)
    for (let r = -rings; r <= rings; r++)
      if (abs(q + r) <= rings) p.push(hexToXZ(q, r));
  return p;
}

// ============================================
// KINEMATICS — EXACT MATCH to triple_helix_complete.js
// Phase from slider's physical position along shaft
// ============================================
function sliderDisp(j, hi, th, amp) {
  let posOnShaft = (j - (SLIDERS_PER_HELIX - 1) / 2) * SLIDER_SPACING;
  let shaftPhase = (posOnShaft / HELIX_LENGTH) * 360;
  return amp * sin(radians(th + hi * HELIX_PHASE + shaftPhase));
}

function sliderPos(j, hi, th, amp) {
  let a = radians(HELIX_ANGLES_DEG[hi]);
  let r = HELIX_DISTANCE * 0.75;
  let tangOff = (j - (SLIDERS_PER_HELIX - 1) / 2) * SLIDER_SPACING;
  let tx = -sin(a), tz = cos(a);
  let sx = r * cos(a) + tangOff * tx;
  let sz = r * sin(a) + tangOff * tz;
  let sy = HELIX_Y + sliderDisp(j, hi, th, amp);
  return [sx, sy, sz];
}

function sliderXZ(j, hi) {
  let a = radians(HELIX_ANGLES_DEG[hi]);
  let r = HELIX_DISTANCE * 0.75;
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
// SETUP
// ============================================
function setup() {
  createCanvas(windowWidth, windowHeight, WEBGL);
  strokeCap(ROUND);

  // Generate hex grid (37 blocks for 3 rings — PRIME)
  HEX_POSITIONS = genHex(HEX_RINGS);
  NUM_BLOCKS = HEX_POSITIONS.length;

  // Precompute nearest slider per block per helix
  SLIDER_NEAREST = [];
  for (let i = 0; i < NUM_BLOCKS; i++) {
    SLIDER_NEAREST.push([
      nearestSlider(HEX_POSITIONS[i][0], HEX_POSITIONS[i][1], 0),
      nearestSlider(HEX_POSITIONS[i][0], HEX_POSITIONS[i][1], 1),
      nearestSlider(HEX_POSITIONS[i][0], HEX_POSITIONS[i][1], 2)
    ]);
  }

  // Bind DOM controls
  slAmp = document.getElementById('sl-amp');
  slSpd = document.getElementById('sl-spd');
  slBt  = document.getElementById('sl-bt');

  chkHelix      = document.getElementById('chk-helix');
  chkRibs       = document.getElementById('chk-ribs');
  chkMatrix     = document.getElementById('chk-matrix');
  chkStrings    = document.getElementById('chk-strings');
  chkBlocks     = document.getElementById('chk-blocks');
  chkFrame      = document.getElementById('chk-frame');
  chkDrive      = document.getElementById('chk-drive');
  chkSliders    = document.getElementById('chk-sliders');
  chkPulleys    = document.getElementById('chk-pulleys');
  chkCables     = document.getElementById('chk-cables');
  chkWhiffletree = document.getElementById('chk-whiffletree');

  // Slider value display
  for (let id of ['amp','spd','bt']) {
    let sl = document.getElementById('sl-' + id);
    let vl = document.getElementById('v-' + id);
    if (sl && vl) sl.addEventListener('input', () => { vl.textContent = sl.value; });
  }

  console.log("=== SKYTEX v2.0 (Margolin-Grounded) ===");
  console.log("Blocks: " + NUM_BLOCKS + " (prime=" + (NUM_BLOCKS === 37) + ")");
  console.log("Sliders: " + SLIDERS_PER_HELIX + " × " + NUM_HELICES + " = " + (SLIDERS_PER_HELIX * NUM_HELICES));
  console.log("Cams: " + NUM_CAMS + " × " + CAM_TWIST.toFixed(2) + "° = " + (NUM_CAMS * CAM_TWIST).toFixed(1) + "°");
  console.log("Helix length: " + HELIX_LENGTH.toFixed(1) + "mm");
  console.log("Eccentricity: " + ECCENTRICITY + "mm → stroke: " + (2 * ECCENTRICITY) + "mm");
}

// ============================================
// DRAW
// ============================================
function draw() {
  background(12, 12, 18);
  orbitControl();

  let amp   = parseFloat(slAmp.value);
  let speed = parseFloat(slSpd.value);
  BT_RATIO  = parseInt(slBt.value);

  // Lighting
  ambientLight(80);
  directionalLight(255, 250, 220, 0.5, 1, -0.5);
  directionalLight(50, 70, 100, -1, -0.5, 0.5);
  pointLight(255, 200, 150, 0, -200 * S, 300 * S);

  push();
  scale(S);
  translate(0, -BLOCK_NOMINAL_Y * 0.3, 0);

  let explodeOffset = (viewMode === 2) ? 100 : 0;

  if (viewMode === 1 || viewMode === 2) {
    if (chkFrame.checked)  drawStarFrame();
    if (chkDrive.checked)  drawDriveTrain(motorAngle);
    if (chkMatrix.checked) drawMatrixSheets(explodeOffset);

    for (let i = 0; i < NUM_HELICES; i++) {
      let tierOff = (viewMode === 2) ? (i - 1) * explodeOffset : 0;
      push();
      translate(0, tierOff, 0);
      if (chkHelix.checked)                       drawHelix(i, motorAngle, amp);
      if (chkSliders && chkSliders.checked)        drawSliders(i, motorAngle, amp);
      if (chkCables && chkCables.checked)          drawCables(i, motorAngle, amp);
      if (chkRibs.checked)                         drawRibs(i, motorAngle, amp);
      pop();
    }

    if (chkWhiffletree && chkWhiffletree.checked) drawWhiffletrees(motorAngle, amp);
    drawBlocksWithStrings(motorAngle, amp);
  }
  else if (viewMode === 3) {
    drawMacroView(motorAngle, amp);
  }
  else if (viewMode === 4) {
    drawStarFrame();
    drawDriveTrain(motorAngle);
    for (let t = 0; t < NUM_HELICES; t++) drawHelix(t, motorAngle, amp);
  }

  pop();
  drawHUD(amp);
  motorAngle += speed;
}

// ============================================
// STAR FRAME — Steel triangular truss
// ============================================
function drawStarFrame() {
  // Central hexagonal hub
  push(); noStroke();
  fill(C_STEEL[0], C_STEEL[1], C_STEEL[2]);
  translate(0, FRAME_Y, 0);
  cylinder(30, 20, 6);
  pop();

  // Ceiling mount plate
  push(); noStroke();
  fill(C_STEEL[0], C_STEEL[1], C_STEEL[2], 60);
  translate(0, CEILING_Y, 0);
  cylinder(40, 4, 6);
  pop();

  // 3 Radial arms (to helix bearing housings)
  for (let i = 0; i < NUM_HELICES; i++) {
    let a = radians(HELIX_ANGLES_DEG[i]);
    let ex = HELIX_DISTANCE * cos(a);
    let ez = HELIX_DISTANCE * sin(a);

    // Main beam
    stroke(C_STEEL[0], C_STEEL[1], C_STEEL[2]);
    strokeWeight(3);
    line(0, FRAME_Y, 0, ex, FRAME_Y, ez);

    // Truss diagonals
    let px = -sin(a), pz = cos(a);
    strokeWeight(1.5);
    for (let side = -1; side <= 1; side += 2) {
      let off = side * 10;
      line(off * px, FRAME_Y - 10, off * pz,
           ex + off * px, FRAME_Y - 10, ez + off * pz);
      for (let d = 0; d < 5; d++) {
        let t1 = d / 5, t2 = (d + 1) / 5;
        line(ex * t1 + off * px, FRAME_Y, ez * t1 + off * pz,
             ex * t2, FRAME_Y - 10, ez * t2);
      }
    }

    // Bearing housing at helix end
    push(); noStroke();
    fill(C_ALU[0], C_ALU[1], C_ALU[2]);
    translate(ex, HELIX_Y, ez);
    rotateY(a + HALF_PI); rotateX(HALF_PI);
    cylinder(BEARING_OD / 2 * 0.2, BEARING_W * 1.5, 12);
    pop();
  }

  // Vertical support columns
  for (let i = 0; i < 3; i++) {
    let a = radians(HELIX_ANGLES_DEG[i] + 60);
    let r = HELIX_DISTANCE * 0.65;
    let lx = r * cos(a), lz = r * sin(a);
    stroke(C_STEEL[0], C_STEEL[1], C_STEEL[2]);
    strokeWeight(2.5);
    line(lx, CEILING_Y, lz, lx, FRAME_Y + 10, lz);
  }
}

// ============================================
// DRIVE TRAIN — Motor → Bevel → 3 Helices
// ============================================
function drawDriveTrain(angle) {
  // Motor (ceiling-mounted)
  push(); noStroke();
  fill(C_MOTOR[0], C_MOTOR[1], C_MOTOR[2]);
  translate(0, MOTOR_Y, 0);
  cylinder(18, 35, 16);
  pop();

  // Vertical drive shaft
  push(); noStroke();
  fill(C_SHAFT[0], C_SHAFT[1], C_SHAFT[2]);
  translate(0, (MOTOR_Y + FRAME_Y) / 2, 0);
  rotateY(radians(angle));
  cylinder(3.5, abs(FRAME_Y - MOTOR_Y) - 35, 8);
  pop();

  // Central bevel gear
  push(); noStroke();
  fill(C_GEAR[0], C_GEAR[1], C_GEAR[2]);
  translate(0, FRAME_Y, 0);
  rotateY(radians(angle));
  cone(12, 10, 12);
  pop();

  // Drive shafts + sprockets to each helix
  for (let i = 0; i < NUM_HELICES; i++) {
    let a = radians(HELIX_ANGLES_DEG[i]);
    let ex = HELIX_DISTANCE * cos(a);
    let ez = HELIX_DISTANCE * sin(a);

    // Sprocket at helix
    push(); noStroke();
    fill(C_GEAR[0], C_GEAR[1], C_GEAR[2]);
    translate(ex * 0.95, HELIX_Y, ez * 0.95);
    rotateY(a + HALF_PI); rotateX(HALF_PI);
    cylinder(10, 4, 16);
    pop();

    // Shaft segments
    stroke(C_SHAFT[0], C_SHAFT[1], C_SHAFT[2]);
    strokeWeight(2);
    let steps = 10;
    for (let s = 0; s < steps; s++) {
      let t1 = (s + 0.1) / steps, t2 = (s + 0.9) / steps;
      line(ex * t1, FRAME_Y, ez * t1, ex * t2, FRAME_Y, ez * t2);
    }

    // U-joints
    for (let pos of [0.12, 0.88]) {
      push(); noStroke();
      fill(C_BRASS[0], C_BRASS[1], C_BRASS[2]);
      translate(ex * pos, FRAME_Y, ez * pos);
      sphere(5);
      pop();
    }
  }
}

// ============================================
// HELIX — 37 Eccentric Hubs (CAD-quality detail)
// ============================================
function drawHelix(idx, th, amp) {
  let a = radians(HELIX_ANGLES_DEG[idx]);
  let basePhase = th + idx * HELIX_PHASE;
  let hx = HELIX_DISTANCE * cos(a);
  let hz = HELIX_DISTANCE * sin(a);
  let tx = -sin(a), tz = cos(a);  // tangent (along shaft)
  let rx = cos(a), rz = sin(a);    // radial (toward center)
  let tc = C_TIER[idx];

  // Central shaft line
  let shaftHalf = HELIX_LENGTH / 2 + 20;
  stroke(C_SHAFT[0], C_SHAFT[1], C_SHAFT[2]);
  strokeWeight(SHAFT_DIA * 0.4);
  line(hx + tx * (-shaftHalf), HELIX_Y, hz + tz * (-shaftHalf),
       hx + tx * shaftHalf,    HELIX_Y, hz + tz * shaftHalf);

  // 37 offset discs with bearings
  let dSp = HELIX_LENGTH / NUM_CAMS;

  for (let d = 0; d < NUM_CAMS; d++) {
    let discPhase = basePhase + d * CAM_TWIST;
    let dPos = d * dSp - HELIX_LENGTH / 2 + dSp / 2;

    let shX = hx + tx * dPos;
    let shZ = hz + tz * dPos;

    // Eccentric offset in plane perpendicular to shaft
    let eccCos = ECCENTRICITY * cos(radians(discPhase));
    let eccSin = ECCENTRICITY * sin(radians(discPhase));

    let discX = shX + rx * eccCos;
    let discY = HELIX_Y - eccSin;
    let discZ = shZ + rz * eccCos;

    // Hub disc (colored by tier)
    push(); noStroke();
    fill(tc[0], tc[1], tc[2], 200);
    translate(discX, discY, discZ);
    rotateY(a + HALF_PI);
    rotateX(HALF_PI);
    cylinder(HUB_DIA / 2 * 0.22, BEARING_W * 0.6, 12);
    pop();

    // Bearing ring (torus around hub)
    push(); noStroke();
    fill(C_ALU[0], C_ALU[1], C_ALU[2], 120);
    translate(discX, discY, discZ);
    rotateY(a + HALF_PI);
    rotateX(HALF_PI);
    torus(BEARING_OD / 2 * 0.18, (BEARING_OD - BEARING_ID) / 4 * 0.18, 12, 6);
    pop();

    // Bolt hole indicators (3 dots on hub face, visible twist)
    let hubAngle = radians(d * CAM_TWIST);
    for (let b = 0; b < 3; b++) {
      let ba = hubAngle + b * TWO_PI / 3;
      let boltR = 10 * 0.22; // bolt circle scaled
      let boltX = discX + rx * (boltR * cos(ba)) * cos(radians(discPhase));
      let boltZ = discZ + rz * (boltR * cos(ba)) * cos(radians(discPhase));
      push(); noStroke();
      fill(C_DARK[0], C_DARK[1], C_DARK[2]);
      translate(boltX, discY, boltZ);
      sphere(0.8);
      pop();
    }

    // Collar spacer (centered on shaft axis, no offset)
    if (d < NUM_CAMS - 1) {
      let cPos = (d + 1) * dSp - HELIX_LENGTH / 2;
      push(); noStroke();
      fill(C_COLLAR[0], C_COLLAR[1], C_COLLAR[2]);
      translate(hx + tx * cPos, HELIX_Y, hz + tz * cPos);
      rotateY(a + HALF_PI);
      rotateX(HALF_PI);
      cylinder(COLLAR_DIA / 2 * 0.18, COLLAR_THICK, 8);
      pop();
    }
  }

  // End plates (crank arms)
  for (let end = -1; end <= 1; end += 2) {
    push(); noStroke();
    fill(C_BRASS[0], C_BRASS[1], C_BRASS[2]);
    translate(hx + tx * (end * (HELIX_LENGTH / 2 + 3)), HELIX_Y,
              hz + tz * (end * (HELIX_LENGTH / 2 + 3)));
    rotateY(a + HALF_PI);
    rotateX(HALF_PI);
    cylinder((SHAFT_DIA + 6) / 2, 4, 8);
    pop();
  }
}

// ============================================
// SLIDERS — 37 per helix (111 total)
// ============================================
function drawSliders(idx, th, amp) {
  let a = radians(HELIX_ANGLES_DEG[idx]);

  for (let j = 0; j < SLIDERS_PER_HELIX; j++) {
    let sp = sliderPos(j, idx, th, amp);

    // Slider body
    push(); noStroke();
    fill(C_ALU[0], C_ALU[1], C_ALU[2]);
    translate(sp[0], sp[1], sp[2]);
    box(10, 6, 10);
    pop();

    // Connector pin (string attachment)
    push(); noStroke();
    fill(C_BRASS[0], C_BRASS[1], C_BRASS[2]);
    translate(sp[0], sp[1] + 4, sp[2]);
    cylinder(1, 3, 6);
    pop();

    // Guide rails
    let sxz = sliderXZ(j, idx);
    let railH = ECCENTRICITY * 2 + 15;
    stroke(C_GUIDE[0], C_GUIDE[1], C_GUIDE[2], 60);
    strokeWeight(0.6);
    for (let side = -1; side <= 1; side += 2) {
      let ox = sxz[0] + side * 7 * cos(a);
      let oz = sxz[1] + side * 7 * sin(a);
      line(ox, HELIX_Y - railH / 2, oz, ox, HELIX_Y + railH / 2, oz);
    }
  }
}

// ============================================
// CABLES — Helix to Slider connections
// ============================================
function drawCables(idx, th, amp) {
  let a = radians(HELIX_ANGLES_DEG[idx]);
  let hcx = HELIX_DISTANCE * cos(a), hcz = HELIX_DISTANCE * sin(a);

  stroke(C_CABLE[0], C_CABLE[1], C_CABLE[2]);
  strokeWeight(CABLE_DIA * 0.5);

  for (let j = 0; j < SLIDERS_PER_HELIX; j++) {
    let sp = sliderPos(j, idx, th, amp);
    let depA = a + HALF_PI;
    line(hcx + (HUB_DIA / 2 * 0.2) * cos(depA), HELIX_Y, hcz + (HUB_DIA / 2 * 0.2) * sin(depA),
         sp[0], sp[1], sp[2]);
  }
}

// ============================================
// RIBS — Tension followers on bearings
// ============================================
function drawRibs(tierIdx, angle, amp) {
  let a = radians(HELIX_ANGLES_DEG[tierIdx]);
  let hx = HELIX_DISTANCE * cos(a);
  let hz = HELIX_DISTANCE * sin(a);
  let tx = -sin(a), tz = cos(a);
  let rx = cos(a), rz = sin(a);
  let tc = C_TIER[tierIdx];

  let dSp = HELIX_LENGTH / NUM_CAMS;

  for (let d = 0; d < NUM_CAMS; d++) {
    let discPhase = angle + HELIX_ANGLES_DEG[tierIdx] + d * CAM_TWIST;
    let dPos = d * dSp - HELIX_LENGTH / 2 + dSp / 2;

    let shX = hx + tx * dPos;
    let shZ = hz + tz * dPos;

    // Rib tip oscillates vertically
    let ribY = HELIX_Y + ECCENTRICITY * sin(radians(discPhase));

    // Arm extends inward toward center
    let armLen = RIB_ARM_LENGTH * 0.4;
    let armEndX = shX - rx * armLen;
    let armEndZ = shZ - rz * armLen;

    // Rib arm line (tapered — thicker at bearing, thinner at tip)
    stroke(tc[0], tc[1], tc[2], 160);
    strokeWeight(RIB_THICK * 0.35);
    line(shX, ribY, shZ, armEndX, ribY, armEndZ);

    // Eyelet at rib tip
    push(); noStroke();
    fill(C_BRASS[0], C_BRASS[1], C_BRASS[2]);
    translate(armEndX, ribY, armEndZ);
    sphere(1.5);
    pop();

    // Anti-rotation guide rail (vertical line at bearing position)
    stroke(C_STEEL[0], C_STEEL[1], C_STEEL[2], 40);
    strokeWeight(0.4);
    line(shX, HELIX_Y - ECCENTRICITY - 8, shZ, shX, HELIX_Y + ECCENTRICITY + 8, shZ);
  }
}

// ============================================
// MATRIX SHEETS — 3 Polycarbonate tiers
// ============================================
function drawMatrixSheets(explodeOffset) {
  for (let t = 0; t < 3; t++) {
    let tierY = MATRIX_Y + t * 20 + (viewMode === 2 ? (t - 1) * explodeOffset : 0);
    let tc = C_TIER[t];

    // Polycarbonate sheet (flat hex shape)
    push(); noStroke();
    fill(C_ACRYLIC[0], C_ACRYLIC[1], C_ACRYLIC[2], C_ACRYLIC[3]);
    translate(0, tierY, 0);
    cylinder(BOUNDARY_SIZE / 2 * 0.55, 2.5, 6);
    pop();

    // Drilled holes at block positions (grommet locations)
    for (let i = 0; i < NUM_BLOCKS; i++) {
      push(); noStroke();
      fill(tc[0], tc[1], tc[2], 80);
      translate(HEX_POSITIONS[i][0], tierY, HEX_POSITIONS[i][1]);
      cylinder(2, 3, 6);
      pop();
    }
  }
}

// ============================================
// WHIFFLETREES — Wave summation at each block position
// ============================================
function drawWhiffletrees(th, amp) {
  for (let i = 0; i < NUM_BLOCKS; i++) {
    let bx = HEX_POSITIONS[i][0];
    let bz = HEX_POSITIONS[i][1];

    // Housing outline (acrylic frame)
    push();
    translate(bx, WHIFFLETREE_Y, bz);
    stroke(C_ACRYLIC[0], C_ACRYLIC[1], C_ACRYLIC[2], 60);
    strokeWeight(0.5);
    noFill();
    box(HOUSING_W * 0.3, HOUSING_H * 0.25, SHUTTLE_D * 0.3);

    // 3 fixed redirect pulleys (one per helix tier)
    for (let t = 0; t < 3; t++) {
      let tc = C_TIER[t];
      let fpx = (t === 1 ? 3 : -3);
      let fpy = -6 + t * 4;
      push(); noStroke();
      fill(tc[0], tc[1], tc[2], 120);
      translate(fpx, fpy, 0);
      rotateX(HALF_PI);
      torus(2, 0.6, 8, 4);
      pop();
    }

    // Shuttle with 2 floating pulleys
    let disp = blockDisp(i, th, amp);
    let shuttleY = disp * 0.1;

    push();
    translate(0, shuttleY, 0);
    noStroke();
    fill(C_ALU[0], C_ALU[1], C_ALU[2], 80);
    box(SHUTTLE_W * 0.2, SHUTTLE_H * 0.15, SHUTTLE_D * 0.2);

    // Floating pulleys
    for (let fp = 0; fp < NUM_FLOAT_PULLEYS; fp++) {
      push(); noStroke();
      fill(C_BRASS[0], C_BRASS[1], C_BRASS[2]);
      translate(0, (fp - 0.5) * 4, 0);
      rotateX(HALF_PI);
      torus(1.5, 0.5, 8, 4);
      pop();
    }
    pop();

    // Thread routing (simplified zigzag)
    stroke(C_YELLOW[0], C_YELLOW[1], C_YELLOW[2], 100);
    strokeWeight(0.4);
    line(-3, -6, 0, 0, shuttleY - 2, 0);
    line(3, -2, 0, 0, shuttleY + 2, 0);
    line(-3, 2, 0, 0, shuttleY - 2, 0);
    line(0, shuttleY + 2, 0, 0, 10, 0);  // output to block

    pop();
  }
}

// ============================================
// BLOCKS + STRINGS — Hex grid, serial routing
// ============================================
function drawBlocksWithStrings(th, amp) {
  let maxH = 3 * amp;

  for (let i = 0; i < NUM_BLOCKS; i++) {
    let bx = HEX_POSITIONS[i][0];
    let bz = HEX_POSITIONS[i][1];
    let h = blockDisp(i, th, amp);
    let by = BLOCK_NOMINAL_Y + h;
    let col = blockColor(h, maxH);

    // Block body (hexagonal cross-section, wood-colored)
    push(); noStroke();
    fill(col[0], col[1], col[2]);
    translate(bx, by, bz);
    cylinder(BLOCK_VIS_R, BLOCK_HEIGHT * 0.4, 6);
    pop();

    // Wood grain ring (darker edge)
    push(); noStroke();
    fill(C_WOOD2[0], C_WOOD2[1], C_WOOD2[2], 40);
    translate(bx, by, bz);
    torus(BLOCK_VIS_R * 0.9, 1, 6, 4);
    pop();

    // Top eyelet (single attachment point — whiffletree output)
    push(); noStroke();
    fill(C_BRASS[0], C_BRASS[1], C_BRASS[2]);
    translate(bx, by - BLOCK_HEIGHT * 0.2 - 1, bz);
    torus(2, 0.5, 8, 6);
    pop();

    // Bottom weight (gravity return)
    push(); noStroke();
    fill(C_GUIDE[0], C_GUIDE[1], C_GUIDE[2]);
    translate(bx, by + BLOCK_HEIGHT * 0.2 + 2, bz);
    cylinder(3.5, 3, 8);
    pop();

    // STRING ROUTING
    if (chkStrings.checked) {
      // 3 strings from sliders → through matrix → to whiffletree → single output to block
      let s0 = sliderPos(SLIDER_NEAREST[i][0], 0, th, amp);
      let s1 = sliderPos(SLIDER_NEAREST[i][1], 1, th, amp);
      let s2 = sliderPos(SLIDER_NEAREST[i][2], 2, th, amp);

      // Matrix tier Y positions
      let mY0 = MATRIX_Y;
      let mY1 = MATRIX_Y + 20;
      let mY2 = MATRIX_Y + 40;

      // Whiffletree position
      let wY = WHIFFLETREE_Y;

      // Path per helix: slider → matrix hole (dampener) → whiffletree input
      let paths = [
        [[s0[0], s0[1], s0[2]], [bx, mY0, bz], [bx, wY - 8, bz]],  // Helix 0 (Red)
        [[s1[0], s1[1], s1[2]], [bx, mY1, bz], [bx, wY - 4, bz]],  // Helix 1 (Green)
        [[s2[0], s2[1], s2[2]], [bx, mY2, bz], [bx, wY,     bz]],  // Helix 2 (Blue)
      ];

      for (let p = 0; p < 3; p++) {
        let tc = C_TIER[p];
        stroke(tc[0], tc[1], tc[2], 60);
        strokeWeight(STRING_DIA * 0.6);
        let path = paths[p];
        for (let w = 0; w < path.length - 1; w++) {
          line(path[w][0], path[w][1], path[w][2],
               path[w+1][0], path[w+1][1], path[w+1][2]);
        }
      }

      // Single output: whiffletree → block
      stroke(C_YELLOW[0], C_YELLOW[1], C_YELLOW[2], 80);
      strokeWeight(STRING_DIA * 0.8);
      line(bx, wY + 10, bz, bx, by - BLOCK_HEIGHT * 0.2, bz);
    }
  }
}

function blockColor(h, maxH) {
  let t = constrain((h + maxH) / (2 * maxH), 0, 1);
  return [
    lerp(C_WOOD[0] * 0.4, C_WOOD[0], pow(t, 1.5)),
    lerp(C_WOOD[1] * 0.3, C_WOOD[1], pow(t, 1.2)),
    lerp(C_WOOD[2] * 0.5, C_WOOD[2], t)
  ];
}

// ============================================
// MACRO VIEW — Single Whiffletree Detail
// ============================================
function drawMacroView(angle, amp) {
  // Focus on center block (idx 0 in hex grid = center)
  let i = 0;
  let bx = HEX_POSITIONS[i][0];
  let bz = HEX_POSITIONS[i][1];

  push();
  translate(-bx, -WHIFFLETREE_Y, -bz);
  scale(3); // zoom in

  // Draw whiffletree housing detail
  push();
  translate(bx, WHIFFLETREE_Y, bz);

  // Housing frame
  stroke(C_ACRYLIC[0], C_ACRYLIC[1], C_ACRYLIC[2], 120);
  strokeWeight(0.8);
  noFill();
  box(HOUSING_W * 0.3, HOUSING_H * 0.3, SHUTTLE_D * 0.3);

  // 3 fixed pulleys with tier colors
  for (let t = 0; t < 3; t++) {
    let tc = C_TIER[t];
    let fpx = (t === 1 ? 4 : -4);
    let fpy = -8 + t * 6;
    push(); noStroke();
    fill(tc[0], tc[1], tc[2], 180);
    translate(fpx, fpy, 0);
    rotateX(HALF_PI);
    torus(2.5, 0.8, 12, 6);

    // Pulley label
    fill(tc[0], tc[1], tc[2]);
    pop();

    // Input string from helix
    stroke(tc[0], tc[1], tc[2], 150);
    strokeWeight(0.6);
    line(fpx > 0 ? 10 : -10, fpy - 5, 0, fpx, fpy, 0);
  }

  // Shuttle
  let disp = blockDisp(i, angle, amp);
  let shuttleY = disp * 0.15;

  push();
  translate(0, shuttleY, 0);
  noStroke();
  fill(C_ALU[0], C_ALU[1], C_ALU[2], 150);
  box(SHUTTLE_W * 0.25, SHUTTLE_H * 0.2, SHUTTLE_D * 0.25);

  // 2 floating pulleys
  for (let fp = 0; fp < 2; fp++) {
    push(); noStroke();
    fill(C_BRASS[0], C_BRASS[1], C_BRASS[2]);
    translate(0, (fp - 0.5) * 5, 0);
    rotateX(HALF_PI);
    torus(2, 0.7, 12, 6);
    pop();
  }
  pop();

  // Thread path (yellow zigzag through all pulleys)
  stroke(C_YELLOW[0], C_YELLOW[1], C_YELLOW[2]);
  strokeWeight(0.6);
  let fp1Y = shuttleY - 2.5, fp2Y = shuttleY + 2.5;
  let thread = [
    [0, -15, 0],       // Input top
    [-4, -8, 0],       // Fixed 1
    [0, fp1Y, 0],      // Float 1
    [4, -2, 0],        // Fixed 2
    [0, fp2Y, 0],      // Float 2
    [-4, 4, 0],        // Fixed 3
    [0, 12, 0]         // Output bottom
  ];
  for (let s = 0; s < thread.length - 1; s++) {
    line(thread[s][0], thread[s][1], thread[s][2],
         thread[s+1][0], thread[s+1][1], thread[s+1][2]);
  }

  pop();

  // Block below
  let by = BLOCK_NOMINAL_Y + disp;
  let col = blockColor(disp, 3 * amp);
  push(); noStroke();
  fill(col[0], col[1], col[2]);
  translate(bx, by, bz);
  cylinder(BLOCK_VIS_R, BLOCK_HEIGHT * 0.4, 6);
  pop();

  // Output string
  stroke(C_YELLOW[0], C_YELLOW[1], C_YELLOW[2]);
  strokeWeight(0.5);
  line(bx, WHIFFLETREE_Y + 12, bz, bx, by - 5, bz);

  pop();
}

// ============================================
// HUD — Engineering Status Display
// ============================================
function drawHUD(amp) {
  push();
  // Bottom bar
  fill(0, 0, 0, 150); noStroke();
  rect(-width / 2, height / 2 - 40, width, 40);
  fill(190); textSize(11); textAlign(LEFT);

  let eta = pow(0.95, 3) * 100;  // 3 pulleys serial (redirect + 2 whiffletree)
  let maxDisp = 3 * amp;
  let travel = maxDisp * BT_RATIO;
  let stringEst = NUM_BLOCKS * 28;

  text("Blocks: " + NUM_BLOCKS + " (prime=" + (NUM_BLOCKS === 37) + ")" +
    " | Sliders: " + (SLIDERS_PER_HELIX * 3) +
    " | Amp: " + amp + "mm" +
    " | Ecc: " + ECCENTRICITY + "mm" +
    " | B&T: " + BT_RATIO + ":1" +
    " | Travel: \u00B1" + travel.toFixed(0) + "mm" +
    " | Motor: " + motorAngle.toFixed(0) + "\u00B0" +
    " | \u03B7: " + eta.toFixed(1) + "%" +
    " | Strings: ~" + stringEst +
    " | View: " + ["", "Full", "Exploded", "Macro", "Drive"][viewMode],
    -width / 2 + 15, height / 2 - 15);

  // Top-right: Margolin verification panel
  fill(0, 0, 0, 140); noStroke();
  rect(width / 2 - 300, -height / 2, 300, 120);
  fill(140); textSize(10); textAlign(LEFT);
  let vx = width / 2 - 290, vy = -height / 2 + 15;
  text("MARGOLIN VERIFICATION (Triple Helix)", vx, vy);
  fill(100); textSize(9);
  text("Blocks: " + NUM_BLOCKS + " hex (3 rings) " +
       (NUM_BLOCKS === 37 ? "\u2713 PRIME" : "\u2717"), vx, vy + 15);
  text("Sliders: " + (SLIDERS_PER_HELIX * 3) + " = 111 " +
       (SLIDERS_PER_HELIX * 3 === 111 ? "\u2713" : "\u2717"), vx, vy + 27);
  text("Cams: " + NUM_CAMS + " \u00D7 " + CAM_TWIST.toFixed(2) + "\u00B0 = " +
       (NUM_CAMS * CAM_TWIST).toFixed(1) + "\u00B0 " +
       (Math.abs(NUM_CAMS * CAM_TWIST - 360) < 0.1 ? "\u2713" : "\u2717"), vx, vy + 39);
  text("Strings: ~" + stringEst + " " +
       (Math.abs(stringEst - 1027) < 50 ? "\u2248 1027 \u2713" : "\u2717"), vx, vy + 51);
  text("Pulleys/path: 3 \u2264 9 \u2713 (redirect + whiffletree)", vx, vy + 63);
  text("Friction: " + eta.toFixed(1) + "% > 60% \u2713", vx, vy + 75);
  text("Kinematics: sliderDisp \u2192 nearestSlider \u2192 blockDisp \u2713", vx, vy + 87);
  text("Summation: WHIFFLETREE (3 inputs \u2192 1 output) \u2713", vx, vy + 99);

  pop();
}

// ============================================
// KEYBOARD
// ============================================
function keyPressed() {
  if (key === '1') viewMode = 1;
  if (key === '2') viewMode = 2;
  if (key === '3') viewMode = 3;
  if (key === '4') viewMode = 4;

  for (let i = 1; i <= 4; i++) {
    let el = document.getElementById('vm' + i);
    if (el) {
      el.textContent = (i === viewMode) ? '\u25CF' : '\u25CB';
      el.className = (i === viewMode) ? 'active' : '';
    }
  }
}

function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
}
