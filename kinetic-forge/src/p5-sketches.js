// ============================================================
// P5.JS SKETCH TEMPLATES FOR KINETIC SCULPTURE
// Each sketch is written in p5.js GLOBAL mode for editor.p5js.org
// Copy → paste into editor → runs immediately
// ============================================================

export const P5_SKETCHES = [

  // ── 1. WAVE SUPERPOSITION ─────────────────────────
  {
    id: 'wave-superposition',
    title: 'Wave Superposition',
    description: 'Combine sine waves with sliders — the core Margolin equation',
    category: 'waves',
    contexts: ['animate', 'playground-wavelab', 'playground-3d', 'exercises-waves'],
    difficulty: 'beginner',
    code: `// Wave Superposition — Margolin h(x,t) = Σ Aᵢ·sin(kᵢx - ωᵢt + φᵢ)
// Adjust sliders to combine waves and see interference patterns

let waves = [];
let sliders = {};
let speed = 1;

function setup() {
  createCanvas(800, 500);

  // 3 default waves
  waves = [
    { A: 2.0, k: 1.0, phi: 0, omega: 1.0, color: [79, 195, 247] },
    { A: 1.0, k: 2.3, phi: 0.5, omega: 0.8, color: [129, 199, 132] },
    { A: 0.5, k: 3.7, phi: 1.2, omega: 1.2, color: [255, 183, 77] }
  ];

  // Create sliders
  let y = 10;
  for (let i = 0; i < waves.length; i++) {
    sliders['A' + i] = createSlider(0, 3, waves[i].A, 0.1);
    sliders['A' + i].position(620, y); sliders['A' + i].style('width', '160px');
    sliders['k' + i] = createSlider(0.1, 5, waves[i].k, 0.1);
    sliders['k' + i].position(620, y + 20); sliders['k' + i].style('width', '160px');
    sliders['phi' + i] = createSlider(0, TWO_PI, waves[i].phi, 0.01);
    sliders['phi' + i].position(620, y + 40); sliders['phi' + i].style('width', '160px');
    y += 80;
  }
}

function draw() {
  background(17, 17, 34);
  let t = frameCount * 0.03 * speed;

  // Update from sliders
  for (let i = 0; i < waves.length; i++) {
    waves[i].A = sliders['A' + i].value();
    waves[i].k = sliders['k' + i].value();
    waves[i].phi = sliders['phi' + i].value();
  }

  // Draw individual waves (dim)
  for (let i = 0; i < waves.length; i++) {
    stroke(waves[i].color[0], waves[i].color[1], waves[i].color[2], 60);
    strokeWeight(1);
    noFill();
    beginShape();
    for (let x = 0; x < 600; x += 2) {
      let xn = x / 600 * TWO_PI * 3;
      let y = height / 2 + waves[i].A * 40 * sin(waves[i].k * xn - waves[i].omega * t + waves[i].phi);
      vertex(x, y);
    }
    endShape();
  }

  // Draw superposition (bright)
  stroke(79, 195, 247);
  strokeWeight(2);
  noFill();
  beginShape();
  for (let x = 0; x < 600; x += 2) {
    let xn = x / 600 * TWO_PI * 3;
    let sum = 0;
    for (let w of waves) {
      sum += w.A * 40 * sin(w.k * xn - w.omega * t + w.phi);
    }
    vertex(x, height / 2 + sum);
  }
  endShape();

  // Labels
  fill(200);
  noStroke();
  textSize(11);
  let ly = 10;
  for (let i = 0; i < waves.length; i++) {
    fill(waves[i].color[0], waves[i].color[1], waves[i].color[2]);
    text('Wave ' + (i + 1) + ': A=' + waves[i].A.toFixed(1) + ' k=' + waves[i].k.toFixed(1) + ' φ=' + waves[i].phi.toFixed(2), 610, ly + 70);
    ly += 80;
  }

  // Formula
  fill(255);
  textSize(13);
  text('h(x,t) = ' + waves.map((w, i) => w.A.toFixed(1) + 'sin(' + w.k.toFixed(1) + 'x - ' + w.omega.toFixed(1) + 't + ' + w.phi.toFixed(2) + ')').join(' + '), 10, height - 15);
}`
  },

  // ── 2. PHASE OFFSET EXPLORER ──────────────────────
  {
    id: 'phase-offset',
    title: 'Phase Offset Explorer',
    description: 'Golden angle (137.5°) vs equal spacing — why Margolin waves feel organic',
    category: 'waves',
    contexts: ['playground-3d', 'exercises-waves'],
    difficulty: 'beginner',
    code: `// Phase Offset Explorer — Golden Angle vs Equal Spacing
// Watch how 137.5° creates organic wave propagation

let nElements = 24;
let phaseSlider, speedSlider, modeSelect;

function setup() {
  createCanvas(800, 500);
  phaseSlider = createSlider(0, 360, 137.5, 0.5);
  phaseSlider.position(10, 10);
  phaseSlider.style('width', '200px');

  speedSlider = createSlider(0.1, 3, 1, 0.1);
  speedSlider.position(10, 40);
  speedSlider.style('width', '200px');

  modeSelect = createSelect();
  modeSelect.position(10, 70);
  modeSelect.option('Custom');
  modeSelect.option('Golden Angle (137.5°)');
  modeSelect.option('Equal Spacing');
  modeSelect.option('Fibonacci');
  modeSelect.changed(() => {
    if (modeSelect.value() === 'Golden Angle (137.5°)') phaseSlider.value(137.5);
    else if (modeSelect.value() === 'Equal Spacing') phaseSlider.value(360 / nElements);
    else if (modeSelect.value() === 'Fibonacci') phaseSlider.value(222.5);
  });
}

function draw() {
  background(17, 17, 34);
  let t = frameCount * 0.02 * speedSlider.value();
  let offset = radians(phaseSlider.value());

  // Draw vertical bars
  let barW = (width - 40) / nElements;
  for (let i = 0; i < nElements; i++) {
    let phase = i * offset;
    let h = 80 + 60 * sin(t - phase);
    let x = 20 + i * barW;
    let y = height / 2;

    // Color based on phase position
    let hue = (i * phaseSlider.value()) % 360;
    colorMode(HSB);
    fill(hue, 80, 90);
    noStroke();
    rect(x, y - h, barW - 2, h * 2, 3);
    colorMode(RGB);
  }

  // Draw connecting wave curve
  stroke(255, 255, 255, 100);
  strokeWeight(2);
  noFill();
  beginShape();
  for (let i = 0; i < nElements; i++) {
    let phase = i * offset;
    let h = 80 + 60 * sin(t - phase);
    vertex(20 + i * barW + barW / 2, height / 2 - h);
  }
  endShape();

  // Labels
  fill(255);
  noStroke();
  textSize(12);
  text('Phase Offset: ' + phaseSlider.value().toFixed(1) + '°', 230, 25);
  text('Speed: ' + speedSlider.value().toFixed(1), 230, 55);
  text(nElements + ' elements', 230, 85);

  // Golden angle indicator
  if (abs(phaseSlider.value() - 137.5) < 1) {
    fill(255, 215, 0);
    text('✦ GOLDEN ANGLE — maximum visual variety', 350, 25);
  }
}`
  },

  // ── 3. FOUR-BAR LINKAGE SIMULATOR ─────────────────
  {
    id: 'four-bar-linkage',
    title: 'Four-Bar Linkage Simulator',
    description: 'Animated linkage with coupler curve tracing and Grashof check',
    category: 'mechanisms',
    contexts: ['animate', 'exercises-fourBar', 'build-mechanize'],
    difficulty: 'medium',
    code: `// Four-Bar Linkage Simulator
// Adjust link lengths with sliders — watch Grashof condition live

let gSlider, cSlider, coSlider, rSlider;
let coupler_path = [];
let angle = 0;

function setup() {
  createCanvas(800, 500);
  gSlider = createSlider(50, 200, 100, 1); gSlider.position(10, 10); gSlider.style('width', '150px');
  cSlider = createSlider(10, 100, 25, 1); cSlider.position(10, 35); cSlider.style('width', '150px');
  coSlider = createSlider(30, 200, 90, 1); coSlider.position(10, 60); coSlider.style('width', '150px');
  rSlider = createSlider(30, 200, 80, 1); rSlider.position(10, 85); rSlider.style('width', '150px');
}

function draw() {
  background(17, 17, 34);
  let g = gSlider.value(), c = cSlider.value(), co = coSlider.value(), r = rSlider.value();

  // Labels
  fill(200); noStroke(); textSize(11);
  text('Ground: ' + g, 170, 22);
  text('Crank: ' + c, 170, 47);
  text('Coupler: ' + co, 170, 72);
  text('Rocker: ' + r, 170, 97);

  // Grashof check
  let links = [g, c, co, r].sort((a, b) => a - b);
  let isGrashof = (links[0] + links[3]) <= (links[1] + links[2]);
  fill(isGrashof ? color(102, 187, 106) : color(239, 83, 80));
  textSize(14);
  text('Grashof: ' + (isGrashof ? 'PASS ✓ (S+L ≤ P+Q)' : 'FAIL ✗ (S+L > P+Q)'), 10, 130);

  // Calculate positions
  translate(250, 300);
  angle += 0.02;

  // A = ground start (fixed)
  let ax = 0, ay = 0;
  // D = ground end (fixed)
  let dx = g, dy = 0;
  // B = crank tip
  let bx = c * cos(angle), by = c * sin(angle);

  // C = solve intersection of circles from B (radius co) and D (radius r)
  let dbx = dx - bx, dby = dy - by;
  let dist_bd = sqrt(dbx * dbx + dby * dby);

  if (dist_bd > co + r || dist_bd < abs(co - r) || dist_bd === 0) {
    // No solution — linkage can't close
    fill(239, 83, 80);
    textSize(12);
    text('Linkage cannot close at this angle', -100, -150);
    coupler_path = [];
    return;
  }

  let a2 = (co * co - r * r + dist_bd * dist_bd) / (2 * dist_bd);
  let h = sqrt(max(0, co * co - a2 * a2));
  let mx = bx + a2 * dbx / dist_bd;
  let my = by + a2 * dby / dist_bd;
  let cx = mx + h * dby / dist_bd;
  let cy = my - h * dbx / dist_bd;

  // Transmission angle
  let v1x = bx - cx, v1y = by - cy;
  let v2x = dx - cx, v2y = dy - cy;
  let dot = v1x * v2x + v1y * v2y;
  let m1 = sqrt(v1x * v1x + v1y * v1y);
  let m2 = sqrt(v2x * v2x + v2y * v2y);
  let transAngle = degrees(acos(constrain(dot / (m1 * m2), -1, 1)));

  // Coupler midpoint for tracing
  let cpx = (bx + cx) / 2, cpy = (by + cy) / 2;
  coupler_path.push({ x: cpx, y: cpy });
  if (coupler_path.length > 600) coupler_path.shift();

  // Draw coupler trace
  noFill();
  stroke(79, 195, 247, 40);
  strokeWeight(1);
  beginShape();
  for (let p of coupler_path) vertex(p.x, p.y);
  endShape();

  // Draw ground
  stroke(100); strokeWeight(3);
  line(ax, ay, dx, dy);

  // Draw crank (green)
  stroke(102, 187, 106); strokeWeight(3);
  line(ax, ay, bx, by);

  // Draw coupler (cyan)
  stroke(79, 195, 247); strokeWeight(3);
  line(bx, by, cx, cy);

  // Draw rocker (orange)
  stroke(255, 183, 77); strokeWeight(3);
  line(dx, dy, cx, cy);

  // Draw joints
  fill(255); noStroke();
  circle(ax, ay, 8); circle(bx, by, 8); circle(cx, cy, 8); circle(dx, dy, 8);

  // Fixed pivots
  fill(100);
  triangle(ax - 8, ay + 4, ax + 8, ay + 4, ax, ay + 14);
  triangle(dx - 8, dy + 4, dx + 8, dy + 4, dx, dy + 14);

  // Transmission angle display
  let taColor = (transAngle >= 40 && transAngle <= 140) ? color(102, 187, 106) : color(239, 83, 80);
  fill(taColor);
  textSize(12);
  text('μ = ' + transAngle.toFixed(1) + '°' + (transAngle < 40 || transAngle > 140 ? ' DANGER' : ' OK'), -240, -180);
}`
  },

  // ── 4. CAM PROFILE DESIGNER ───────────────────────
  {
    id: 'cam-profile',
    title: 'Cam Profile Designer',
    description: 'Interactive cam with rise-dwell-fall and follower displacement graph',
    category: 'mechanisms',
    contexts: ['animate', 'exercises-cams', 'build-mechanize'],
    difficulty: 'medium',
    code: `// Cam Profile Designer — Rise, Dwell, Fall, Return Dwell
// Adjust segments to design follower motion profiles

let baseR = 40;
let riseSlider, dwellSlider, fallSlider, liftSlider;
let camAngle = 0;

function setup() {
  createCanvas(800, 500);
  riseSlider = createSlider(30, 180, 90, 5); riseSlider.position(10, 10); riseSlider.style('width', '150px');
  dwellSlider = createSlider(0, 120, 60, 5); dwellSlider.position(10, 35); dwellSlider.style('width', '150px');
  fallSlider = createSlider(30, 180, 90, 5); fallSlider.position(10, 60); fallSlider.style('width', '150px');
  liftSlider = createSlider(5, 40, 20, 1); liftSlider.position(10, 85); liftSlider.style('width', '150px');
}

function followerHeight(angle, rise, dwell, fall, lift) {
  angle = angle % 360;
  if (angle < 0) angle += 360;
  if (angle < rise) {
    // Rise — simple harmonic
    return lift * (1 - cos(PI * angle / rise)) / 2;
  } else if (angle < rise + dwell) {
    return lift;
  } else if (angle < rise + dwell + fall) {
    let t = (angle - rise - dwell) / fall;
    return lift * (1 + cos(PI * t)) / 2;
  }
  return 0; // Return dwell
}

function draw() {
  background(17, 17, 34);
  let rise = riseSlider.value(), dwell = dwellSlider.value();
  let fall = fallSlider.value(), lift = liftSlider.value();

  fill(200); noStroke(); textSize(11);
  text('Rise: ' + rise + '°', 170, 22);
  text('Dwell: ' + dwell + '°', 170, 47);
  text('Fall: ' + fall + '°', 170, 72);
  text('Lift: ' + lift + 'mm', 170, 97);

  camAngle = (camAngle + 1) % 360;

  // Draw cam profile (left side)
  push();
  translate(200, 280);

  // Cam shape
  noFill(); stroke(79, 195, 247); strokeWeight(2);
  beginShape();
  for (let a = 0; a < 360; a += 2) {
    let r = baseR + followerHeight(a, rise, dwell, fall, lift);
    let x = r * cos(radians(a - camAngle));
    let y = r * sin(radians(a - camAngle));
    vertex(x, y);
  }
  endShape(CLOSE);

  // Base circle
  noFill(); stroke(100); strokeWeight(1);
  circle(0, 0, baseR * 2);

  // Center dot
  fill(255); noStroke();
  circle(0, 0, 6);

  // Current angle indicator
  stroke(255, 183, 77); strokeWeight(2);
  let currentR = baseR + followerHeight(0, rise, dwell, fall, lift);
  line(0, 0, 0, -currentR);

  // Follower
  fill(102, 187, 106);
  let fh = followerHeight(camAngle, rise, dwell, fall, lift);
  rect(-5, -(baseR + fh) - 20, 10, 20);
  pop();

  // Draw displacement graph (right side)
  push();
  translate(420, 120);

  // Axes
  stroke(100); strokeWeight(1);
  line(0, 0, 360, 0);
  line(0, 0, 0, -lift * 4 - 20);

  // Graph
  noFill(); stroke(79, 195, 247); strokeWeight(2);
  beginShape();
  for (let a = 0; a <= 360; a += 2) {
    let h = followerHeight(a, rise, dwell, fall, lift);
    vertex(a, -h * 4);
  }
  endShape();

  // Current position marker
  fill(255, 183, 77); noStroke();
  let ch = followerHeight(camAngle, rise, dwell, fall, lift);
  circle(camAngle, -ch * 4, 8);

  // Zone labels
  fill(150); textSize(10); noStroke();
  text('RISE', rise / 2 - 12, 15);
  text('DWELL', rise + dwell / 2 - 15, 15);
  text('FALL', rise + dwell + fall / 2 - 10, 15);
  text('RETURN', rise + dwell + fall + 10, 15);

  // Zone dividers
  stroke(100, 100, 100, 80); strokeWeight(1);
  line(rise, 10, rise, -lift * 4 - 10);
  line(rise + dwell, 10, rise + dwell, -lift * 4 - 10);
  line(rise + dwell + fall, 10, rise + dwell + fall, -lift * 4 - 10);

  fill(200); textSize(11);
  text('Displacement (mm)', -80, -lift * 4 / 2);
  text('Cam Angle (degrees)', 130, 35);
  pop();
}`
  },

  // ── 5. FRICTION CASCADE ───────────────────────────
  {
    id: 'friction-cascade',
    title: 'Friction Cascade Visualizer',
    description: 'Force propagation through pulleys — why 9 pulleys is the limit',
    category: 'physics',
    contexts: ['exercises-simulation', 'build-simulate'],
    difficulty: 'beginner',
    code: `// Friction Cascade — Watch force decay through pulleys
// Each pulley loses some force to friction

let nSlider, frictionSlider, inputSlider;

function setup() {
  createCanvas(800, 500);
  nSlider = createSlider(1, 15, 7, 1); nSlider.position(10, 10); nSlider.style('width', '200px');
  frictionSlider = createSlider(1, 15, 4, 0.5); frictionSlider.position(10, 40); frictionSlider.style('width', '200px');
  inputSlider = createSlider(1, 20, 5, 0.5); inputSlider.position(10, 70); inputSlider.style('width', '200px');
}

function draw() {
  background(17, 17, 34);
  let n = nSlider.value();
  let friction = frictionSlider.value() / 100;
  let inputForce = inputSlider.value();

  fill(200); noStroke(); textSize(12);
  text('Pulleys: ' + n, 220, 22);
  text('Friction: ' + (friction * 100).toFixed(1) + '% per pulley', 220, 52);
  text('Input Force: ' + inputForce.toFixed(1) + ' N', 220, 82);

  // Calculate forces through chain
  let forces = [inputForce];
  for (let i = 1; i <= n; i++) {
    forces.push(forces[i - 1] * (1 - friction));
  }

  let efficiency = (forces[n] / inputForce * 100);

  // Draw pulleys and bars
  let startX = 60, spacing = (width - 120) / (n + 1);
  let barTop = 150, barH = 250;

  for (let i = 0; i <= n; i++) {
    let x = startX + i * spacing;
    let force = forces[i];
    let h = map(force, 0, inputForce, 0, barH);

    // Bar
    let barColor = lerpColor(color(239, 83, 80), color(102, 187, 106), force / inputForce);
    fill(barColor);
    noStroke();
    rect(x - 15, barTop + barH - h, 30, h, 3, 3, 0, 0);

    // Force label
    fill(255);
    textAlign(CENTER);
    textSize(10);
    text(force.toFixed(2) + 'N', x, barTop + barH + 15);

    // Pulley circle
    if (i > 0) {
      stroke(150); strokeWeight(1); noFill();
      circle(x - spacing / 2, barTop - 20, 20);
      fill(150); noStroke();
      circle(x - spacing / 2, barTop - 20, 4);
    }

    // String between pulleys
    if (i < n) {
      stroke(200, 200, 200, 80); strokeWeight(1);
      line(x + 15, barTop + barH - h, x + spacing - 15, barTop + barH - forces[i + 1] / inputForce * barH);
    }
  }

  textAlign(LEFT);

  // Efficiency display
  fill(efficiency > 70 ? color(102, 187, 106) : efficiency > 40 ? color(255, 183, 77) : color(239, 83, 80));
  textSize(16);
  text('Output: ' + forces[n].toFixed(2) + 'N  (' + efficiency.toFixed(1) + '% efficiency)', 10, height - 40);

  // Warning
  if (efficiency < 50) {
    fill(239, 83, 80);
    textSize(13);
    text('⚠ Below 50% — consider reducing pulley count or friction', 10, height - 15);
  }

  // The "rule of 9"
  fill(200); textSize(11);
  text('At ' + (friction * 100).toFixed(1) + '% friction, 70% efficiency limit = ~' +
    Math.ceil(Math.log(0.7) / Math.log(1 - friction)) + ' pulleys', 10, height - 65);
}`
  },

  // ── 6. TOLERANCE STACK-UP ─────────────────────────
  {
    id: 'tolerance-stack',
    title: 'Tolerance Stack-Up Visualizer',
    description: 'Worst-case vs statistical tolerance accumulation for 3D printed parts',
    category: 'physics',
    contexts: ['exercises-simulation', 'build-build'],
    difficulty: 'medium',
    code: `// Tolerance Stack-Up — Worst Case vs Statistical (RSS)
// See why 5 parts at ±0.3mm can ruin your clearance

let nSlider, tolSlider, gapSlider;

function setup() {
  createCanvas(800, 450);
  nSlider = createSlider(1, 12, 5, 1); nSlider.position(10, 10); nSlider.style('width', '180px');
  tolSlider = createSlider(0.05, 1.0, 0.3, 0.05); tolSlider.position(10, 40); tolSlider.style('width', '180px');
  gapSlider = createSlider(0.5, 5.0, 2.0, 0.1); gapSlider.position(10, 70); gapSlider.style('width', '180px');
}

function draw() {
  background(17, 17, 34);
  let n = nSlider.value(), tol = tolSlider.value(), gap = gapSlider.value();

  fill(200); noStroke(); textSize(12);
  text('Parts: ' + n, 200, 22);
  text('Tolerance: ±' + tol.toFixed(2) + 'mm each', 200, 52);
  text('Clearance gap: ' + gap.toFixed(1) + 'mm', 200, 82);

  let worstCase = n * tol;
  let rss = tol * sqrt(n);

  // Draw parts stacking
  let startX = 50, partW = 50, partH = 120;
  let y = 180;

  for (let i = 0; i < n; i++) {
    let x = startX + i * (partW + 4);

    // Nominal part
    fill(79, 195, 247, 150);
    stroke(79, 195, 247);
    strokeWeight(1);
    rect(x, y, partW, partH, 2);

    // Tolerance zone (worst case)
    noFill();
    stroke(239, 83, 80, 120);
    strokeWeight(1);
    let tolPx = map(tol, 0, 2, 0, 20);
    rect(x - tolPx, y - tolPx, partW + tolPx * 2, partH + tolPx * 2, 2);

    // Label
    fill(200); noStroke(); textSize(9);
    textAlign(CENTER);
    text('±' + tol.toFixed(2), x + partW / 2, y + partH + 15);
  }
  textAlign(LEFT);

  // Results
  let resultY = 350;
  textSize(14);

  // Worst case
  fill(worstCase < gap ? color(102, 187, 106) : color(239, 83, 80));
  text('Worst Case: ±' + worstCase.toFixed(2) + 'mm  ' + (worstCase < gap ? '✓ Fits' : '✗ TOO TIGHT'), 50, resultY);

  // RSS (statistical)
  fill(rss < gap ? color(102, 187, 106) : color(239, 83, 80));
  text('Statistical (RSS): ±' + rss.toFixed(2) + 'mm  ' + (rss < gap ? '✓ Fits' : '✗ TOO TIGHT'), 50, resultY + 25);

  // Gap bar visualization
  let barX = 500, barW = 250, barY = 180;
  fill(50); noStroke();
  rect(barX, barY, barW, 30);

  // Gap
  let gapW = map(gap, 0, 5, 0, barW);
  fill(100, 100, 100); rect(barX, barY, gapW, 30);

  // Worst case overlay
  let wcW = map(worstCase, 0, 5, 0, barW);
  fill(239, 83, 80, 150); rect(barX, barY + 40, wcW, 20);

  // RSS overlay
  let rssW = map(rss, 0, 5, 0, barW);
  fill(102, 187, 106, 150); rect(barX, barY + 70, rssW, 20);

  fill(200); textSize(10);
  text('Available gap: ' + gap.toFixed(1) + 'mm', barX, barY - 5);
  text('Worst case', barX + wcW + 5, barY + 55);
  text('RSS', barX + rssW + 5, barY + 85);

  fill(150); textSize(11);
  text('Formula: Worst = n × tol = ' + n + ' × ' + tol.toFixed(2) + ' = ' + worstCase.toFixed(2), 50, resultY + 60);
  text('Formula: RSS = tol × √n = ' + tol.toFixed(2) + ' × √' + n + ' = ' + rss.toFixed(2), 50, resultY + 80);
}`
  },

  // ── 7. MOTION VOCABULARY ──────────────────────────
  {
    id: 'motion-vocabulary',
    title: 'Motion Vocabulary Sketcher',
    description: 'Code emotions as motion: breathing, surprise, melancholy, joy',
    category: 'design',
    contexts: ['exercises-designThinking', 'animate'],
    difficulty: 'beginner',
    code: `// Motion Vocabulary — Each emotion has a mathematical signature
// Select a feeling, see the math that creates it

let emotions = ['Breathing', 'Surprise', 'Melancholy', 'Joy', 'Hesitation', 'Flowing'];
let selector;
let t = 0;

function setup() {
  createCanvas(800, 400);
  selector = createSelect();
  selector.position(10, 10);
  for (let e of emotions) selector.option(e);
}

function motionValue(emotion, t) {
  switch (emotion) {
    case 'Breathing':
      // Asymmetric sine: slow inhale (2/3), quick exhale (1/3)
      let phase = t % TWO_PI;
      return phase < TWO_PI * 0.67
        ? sin(phase * PI / (TWO_PI * 0.67))
        : -sin((phase - TWO_PI * 0.67) * PI / (TWO_PI * 0.33));
    case 'Surprise':
      // Long pause then sudden jump
      let p = t % (TWO_PI * 2);
      return p < TWO_PI * 1.5 ? 0 : sin((p - TWO_PI * 1.5) * 3);
    case 'Melancholy':
      // Very slow sine with slight asymmetry
      return 0.7 * sin(t * 0.5) + 0.3 * sin(t * 0.3 + 0.5);
    case 'Joy':
      // Bouncy: abs(sin) with higher frequency
      return abs(sin(t * 1.5)) * (0.8 + 0.2 * sin(t * 0.3));
    case 'Hesitation':
      // Start-stop with tremor
      let base = sin(t * 0.7);
      let tremor = 0.1 * sin(t * 8) * (sin(t * 0.5) > 0.3 ? 1 : 0);
      return base + tremor;
    case 'Flowing':
      // Smooth multi-frequency superposition (Margolin-like)
      return 0.5 * sin(t) + 0.3 * sin(t * 1.618) + 0.2 * sin(t * 2.618);
    default: return sin(t);
  }
}

function draw() {
  background(17, 17, 34);
  t += 0.03;
  let emotion = selector.value();

  // Draw motion trail
  stroke(79, 195, 247);
  strokeWeight(2);
  noFill();
  beginShape();
  for (let x = 0; x < width; x += 2) {
    let tt = t - (width - x) * 0.005;
    let y = height / 2 - motionValue(emotion, tt) * 100;
    vertex(x, y);
  }
  endShape();

  // Current point
  let current = motionValue(emotion, t);
  fill(255, 183, 77);
  noStroke();
  circle(width - 20, height / 2 - current * 100, 12);

  // Physical element (vertical bar showing current displacement)
  let barX = width - 60;
  fill(50); noStroke();
  rect(barX, 50, 20, height - 100, 5);
  fill(79, 195, 247);
  let elemY = map(current, -1, 1, height - 70, 70);
  circle(barX + 10, elemY, 16);

  // Emotion name + math formula
  fill(255); textSize(18);
  text(emotion, 200, 30);

  fill(150); textSize(11);
  let formulas = {
    'Breathing': 'Asymmetric sine: 2/3 inhale, 1/3 exhale',
    'Surprise': 'Long dwell + sudden impulse',
    'Melancholy': 'Slow dual-sine: 0.7sin(0.5t) + 0.3sin(0.3t)',
    'Joy': 'Bouncy: |sin(1.5t)| × (0.8 + 0.2sin(0.3t))',
    'Hesitation': 'Base sine + high-freq tremor at peaks',
    'Flowing': 'Golden ratio freqs: sin(t) + sin(φt) + sin(φ²t)'
  };
  text('Math: ' + formulas[emotion], 200, 50);

  // Mechanism suggestion
  let mechanisms = {
    'Breathing': 'Mechanism: Asymmetric cam (slow rise, fast fall)',
    'Surprise': 'Mechanism: Cam with long dwell + steep ramp',
    'Melancholy': 'Mechanism: Eccentric drive, slow motor',
    'Joy': 'Mechanism: Crank with bounce spring',
    'Hesitation': 'Mechanism: Four-bar near dead-point + vibration motor',
    'Flowing': 'Mechanism: Multi-cam Margolin system'
  };
  fill(102, 187, 106); textSize(11);
  text(mechanisms[emotion], 200, 70);
}`
  },

  // ── 8. GEAR TRAIN ANIMATOR ────────────────────────
  {
    id: 'gear-train',
    title: 'Gear Train Animator',
    description: 'Meshing spur gears with adjustable teeth count — see ratio and speed',
    category: 'mechanisms',
    contexts: ['exercises-gears', 'build-mechanize'],
    difficulty: 'medium',
    code: `// Gear Train Animator — Watch teeth mesh, understand ratios
// Adjust tooth counts to change speed and torque

let t1Slider, t2Slider, speedSlider;
let angle1 = 0;

function setup() {
  createCanvas(800, 450);
  t1Slider = createSlider(8, 40, 20, 1); t1Slider.position(10, 10); t1Slider.style('width', '180px');
  t2Slider = createSlider(8, 40, 30, 1); t2Slider.position(10, 40); t2Slider.style('width', '180px');
  speedSlider = createSlider(0.1, 3, 1, 0.1); speedSlider.position(10, 70); speedSlider.style('width', '180px');
}

function drawGear(x, y, teeth, radius, angle, col) {
  push();
  translate(x, y);
  rotate(angle);

  fill(col[0], col[1], col[2], 40);
  stroke(col[0], col[1], col[2]);
  strokeWeight(1.5);

  beginShape();
  for (let i = 0; i < teeth * 2; i++) {
    let a = (i / (teeth * 2)) * TWO_PI;
    let r = (i % 2 === 0) ? radius + 6 : radius - 4;
    vertex(r * cos(a), r * sin(a));
  }
  endShape(CLOSE);

  // Center
  fill(col[0], col[1], col[2]);
  noStroke();
  circle(0, 0, 8);

  // Spoke
  stroke(col[0], col[1], col[2], 100);
  strokeWeight(1);
  line(0, 0, radius - 10, 0);

  pop();
}

function draw() {
  background(17, 17, 34);
  let t1 = t1Slider.value(), t2 = t2Slider.value();
  let speed = speedSlider.value();

  fill(200); noStroke(); textSize(12);
  text('Driver teeth: ' + t1, 200, 22);
  text('Driven teeth: ' + t2, 200, 52);
  text('Speed: ' + speed.toFixed(1), 200, 82);

  let ratio = t2 / t1;
  let r1 = t1 * 3, r2 = t2 * 3;

  // Update angles
  angle1 += 0.02 * speed;
  let angle2 = -angle1 * (t1 / t2);

  // Center positions
  let cx1 = 350, cy = 280;
  let cx2 = cx1 + r1 + r2 + 2; // Mesh distance

  // Draw gears
  drawGear(cx1, cy, t1, r1, angle1, [79, 195, 247]);
  drawGear(cx2, cy, t2, r2, angle2, [255, 183, 77]);

  // Labels
  fill(79, 195, 247); textSize(11);
  textAlign(CENTER);
  text('DRIVER', cx1, cy + r1 + 25);
  text(t1 + ' teeth', cx1, cy + r1 + 40);

  fill(255, 183, 77);
  text('DRIVEN', cx2, cy + r2 + 25);
  text(t2 + ' teeth', cx2, cy + r2 + 40);
  textAlign(LEFT);

  // Ratio info
  fill(255); textSize(14);
  text('Gear Ratio: ' + t1 + ':' + t2 + ' = 1:' + ratio.toFixed(2), 10, 140);
  text('Speed reduction: ' + ratio.toFixed(2) + 'x', 10, 165);
  text('Torque increase: ' + ratio.toFixed(2) + 'x', 10, 190);

  fill(150); textSize(11);
  text('Driver RPM: ' + (60 * speed).toFixed(0) + ' → Driven RPM: ' + (60 * speed / ratio).toFixed(0), 10, 215);

  if (ratio > 5) {
    fill(239, 83, 80); textSize(12);
    text('⚠ High ratio — consider compound gear train', 10, 240);
  }
}`
  },

  // ── 9. MARGOLIN 3D WAVE FIELD ─────────────────────
  {
    id: 'margolin-3d',
    title: 'Margolin 3D Wave Field',
    description: 'WebGL 3D wave surface with multiple sources — the sculpture visualized',
    category: 'waves',
    contexts: ['playground-3d', 'animate'],
    difficulty: 'advanced',
    code: `// Margolin 3D Wave Field (WEBGL)
// h(x,y,t) = Σ Aᵢ·sin(kᵢ·dᵢ(x,y) - ωᵢt + φᵢ)
// Drag to rotate, scroll to zoom

let grid = 30;
let spacing = 10;

function setup() {
  createCanvas(800, 500, WEBGL);
}

function draw() {
  background(17, 17, 34);
  orbitControl();
  rotateX(PI / 4);

  let t = frameCount * 0.03;

  // Lighting
  ambientLight(40);
  directionalLight(79, 195, 247, 0.5, 1, -0.5);
  directionalLight(255, 183, 77, -0.5, -1, 0.5);

  // Wave sources
  let waves = [
    { A: 15, kx: 0.15, ky: 0, omega: 1.0, phi: 0 },
    { A: 10, kx: 0, ky: 0.12, omega: 0.8, phi: 1.0 },
    { A: 5, kx: 0.1, ky: 0.1, omega: 1.2, phi: 2.5 }
  ];

  // Draw wave surface
  noStroke();

  for (let xi = 0; xi < grid - 1; xi++) {
    beginShape(TRIANGLE_STRIP);
    for (let yi = 0; yi < grid; yi++) {
      for (let dx = 0; dx <= 1; dx++) {
        let x = (xi + dx - grid / 2) * spacing;
        let y = (yi - grid / 2) * spacing;

        let h = 0;
        for (let w of waves) {
          h += w.A * sin(w.kx * x + w.ky * y - w.omega * t + w.phi);
        }

        // Color by height
        let r = map(h, -30, 30, 40, 79);
        let g = map(h, -30, 30, 60, 195);
        let b = map(h, -30, 30, 100, 247);
        fill(r, g, b, 200);

        vertex(x, y, h);
      }
    }
    endShape();
  }

  // Ground plane reference
  push();
  translate(0, 0, -35);
  fill(30, 30, 50, 100);
  noStroke();
  plane(grid * spacing, grid * spacing);
  pop();
}`
  },

  // ── 10. LISSAJOUS PATTERN MACHINE ─────────────────
  {
    id: 'lissajous-machine',
    title: 'Lissajous Pattern Machine',
    description: 'Two coupled oscillators with frequency ratio + phase control',
    category: 'patterns',
    contexts: ['playground-patterns', 'exercises-waves'],
    difficulty: 'beginner',
    code: `// Lissajous Pattern Machine
// x = A·sin(a·t + δ), y = B·sin(b·t)
// Adjust frequency ratio to see patterns emerge

let aSlider, bSlider, deltaSlider;
let trail = [];

function setup() {
  createCanvas(800, 500);
  aSlider = createSlider(1, 8, 3, 0.1); aSlider.position(10, 10); aSlider.style('width', '180px');
  bSlider = createSlider(1, 8, 2, 0.1); bSlider.position(10, 40); bSlider.style('width', '180px');
  deltaSlider = createSlider(0, PI, PI / 2, 0.01); deltaSlider.position(10, 70); deltaSlider.style('width', '180px');
}

function draw() {
  background(17, 17, 34);
  let a = aSlider.value(), b = bSlider.value(), delta = deltaSlider.value();

  fill(200); noStroke(); textSize(12);
  text('Freq X (a): ' + a.toFixed(1), 200, 22);
  text('Freq Y (b): ' + b.toFixed(1), 200, 52);
  text('Phase (δ): ' + delta.toFixed(2) + ' rad (' + degrees(delta).toFixed(0) + '°)', 200, 82);

  let ratio = a / b;
  fill(150);
  text('Ratio a:b = ' + a.toFixed(1) + ':' + b.toFixed(1) + ' ≈ ' + ratio.toFixed(3), 450, 22);

  // Common ratios
  let knownRatios = [
    [1, 1, 'Circle/Ellipse'], [1, 2, 'Figure-8'], [2, 3, 'Trefoil'],
    [3, 2, 'Pretzel'], [3, 4, 'Complex loop'], [1, 3, 'Tri-lobe']
  ];
  for (let [na, nb, name] of knownRatios) {
    if (abs(a - na) < 0.15 && abs(b - nb) < 0.15) {
      fill(255, 215, 0); textSize(13);
      text('✦ ' + name + ' pattern!', 450, 52);
    }
  }

  // Calculate current point
  let t = frameCount * 0.02;
  let cx = width / 2, cy = height / 2 + 40;
  let radius = 180;

  let px = cx + radius * sin(a * t + delta);
  let py = cy + radius * sin(b * t);

  trail.push({ x: px, y: py });
  if (trail.length > 2000) trail.shift();

  // Draw trail with fading
  noFill();
  for (let i = 1; i < trail.length; i++) {
    let alpha = map(i, 0, trail.length, 10, 255);
    stroke(79, 195, 247, alpha);
    strokeWeight(1.5);
    line(trail[i - 1].x, trail[i - 1].y, trail[i].x, trail[i].y);
  }

  // Current point
  fill(255, 183, 77);
  noStroke();
  circle(px, py, 8);

  // Equation
  fill(200); textSize(12);
  text('x = sin(' + a.toFixed(1) + 't + ' + delta.toFixed(2) + ')', 10, height - 30);
  text('y = sin(' + b.toFixed(1) + 't)', 10, height - 12);

  // Mechanism connection
  fill(102, 187, 106); textSize(11);
  text('Mechanism: Two perpendicular oscillators (eccentric drives or coupled cranks)', 300, height - 12);

  // Reset on ratio change
  if (frameCount % 300 === 0) trail = [];
}`
  }
];

/**
 * Get sketches filtered by context
 */
export function getSketchesForContext(contextId) {
  return P5_SKETCHES.filter(s => s.contexts.includes(contextId));
}

/**
 * Get sketch by ID
 */
export function getSketchById(id) {
  return P5_SKETCHES.find(s => s.id === id);
}

/**
 * Get all sketch categories
 */
export function getSketchCategories() {
  const cats = new Set(P5_SKETCHES.map(s => s.category));
  return [...cats];
}
