// ============================================================
// P5.JS WEB EDITOR BRIDGE
// Generates p5.js sketches from KineticForge state and opens
// a modal with Copy-to-Clipboard + link to editor.p5js.org
// ============================================================

import { showModal } from './modal.js';
import { showToast } from '../toast.js';
import { P5_SKETCHES, getSketchById, getSketchesForContext } from '../p5-sketches.js';

const P5_EDITOR_URL = 'https://editor.p5js.org/';

// ────────────────────────────────────────────────────
// CORE: Open in p5 Editor modal
// ────────────────────────────────────────────────────

export function openInP5Editor(code, title = 'p5.js Sketch') {
  const container = document.createElement('div');
  container.innerHTML = `
    <div style="margin-bottom:12px;">
      <p class="text-sm text-dim">Copy this sketch, then paste it into the p5.js Web Editor.</p>
    </div>
    <textarea id="p5-bridge-code" readonly
      style="width:100%;height:280px;font-family:var(--mono);font-size:11px;
             background:var(--bg);color:var(--text);border:1px solid var(--border);
             border-radius:var(--radius);padding:10px;resize:vertical;tab-size:2;"
    >${escapeHtml(code)}</textarea>
    <div style="display:flex;gap:8px;margin-top:12px;align-items:center;">
      <button id="p5-bridge-copy" class="primary" style="flex:0 0 auto;">Copy to Clipboard</button>
      <a href="${P5_EDITOR_URL}" target="_blank" rel="noopener"
         style="flex:0 0 auto;padding:6px 14px;font-size:12px;text-decoration:none;
                border:1px solid var(--accent);border-radius:var(--radius);color:var(--accent);">
        Open p5.js Editor &rarr;
      </a>
      <span id="p5-bridge-status" class="text-sm text-dim" style="flex:1;text-align:right;"></span>
    </div>
  `;

  const overlay = showModal({
    title: `\u{1F3A8} ${title}`,
    content: container,
    actions: [{ label: 'Close' }]
  });

  // Copy handler
  const copyBtn = document.getElementById('p5-bridge-copy');
  const statusEl = document.getElementById('p5-bridge-status');
  if (copyBtn) {
    copyBtn.onclick = async () => {
      try {
        await navigator.clipboard.writeText(code);
        statusEl.textContent = 'Copied!';
        statusEl.style.color = '#66bb6a';
        copyBtn.textContent = 'Copied!';
        setTimeout(() => {
          statusEl.textContent = '';
          copyBtn.textContent = 'Copy to Clipboard';
        }, 2000);
      } catch {
        // Fallback
        const ta = document.getElementById('p5-bridge-code');
        ta.select();
        document.execCommand('copy');
        statusEl.textContent = 'Copied (fallback)';
      }
    };
  }

  return overlay;
}

// ────────────────────────────────────────────────────
// Template picker: choose from sketch library
// ────────────────────────────────────────────────────

export function showSketchPicker(contextId) {
  const sketches = contextId ? getSketchesForContext(contextId) : P5_SKETCHES;
  if (sketches.length === 0) {
    showToast('No sketch templates available for this context', 'warning');
    return;
  }

  const container = document.createElement('div');
  container.innerHTML = `
    <p class="text-sm text-dim" style="margin-bottom:12px;">
      Choose a starter sketch to open in the p5.js Web Editor.
    </p>
    <div style="max-height:400px;overflow-y:auto;">
      ${sketches.map(s => `
        <div class="p5-sketch-card" data-id="${s.id}"
             style="padding:10px 12px;border:1px solid var(--border);border-radius:var(--radius);
                    margin-bottom:6px;cursor:pointer;transition:border-color 0.15s;">
          <div style="display:flex;justify-content:space-between;align-items:center;">
            <strong class="text-sm" style="color:var(--text);">${s.title}</strong>
            <span style="font-size:10px;padding:2px 6px;border:1px solid var(--border);
                         border-radius:10px;color:var(--text-dim);">${s.difficulty}</span>
          </div>
          <div class="text-sm text-dim" style="margin-top:4px;">${s.description}</div>
        </div>
      `).join('')}
    </div>
  `;

  const overlay = showModal({
    title: '\u{1F4DA} p5.js Sketch Templates',
    content: container,
    actions: [{ label: 'Cancel' }]
  });

  // Click handler for cards
  container.querySelectorAll('.p5-sketch-card').forEach(card => {
    card.onmouseenter = () => card.style.borderColor = 'var(--accent)';
    card.onmouseleave = () => card.style.borderColor = 'var(--border)';
    card.onclick = () => {
      overlay.remove();
      const sketch = getSketchById(card.dataset.id);
      if (sketch) openInP5Editor(sketch.code, sketch.title);
    };
  });
}

// ────────────────────────────────────────────────────
// GENERATORS: Convert KineticForge state → p5.js code
// ────────────────────────────────────────────────────

/**
 * Convert Wave Lab parameters to a p5.js sketch
 */
export function waveParamsToP5Sketch(waves, speed = 1.0) {
  const waveData = waves.map((w, i) => {
    const colors = ['[79,195,247]', '[129,199,132]', '[255,183,77]', '[239,83,80]', '[171,71,188]'];
    return `  { A: ${w.A.toFixed(2)}, k: ${w.k.toFixed(2)}, phi: ${w.phi.toFixed(2)}, omega: ${(1.0).toFixed(1)}, color: ${colors[i % colors.length]} }`;
  }).join(',\n');

  return `// Wave Superposition — exported from KineticForge Wave Lab
// Margolin equation: h(x,t) = ${waves.filter(w => w.A > 0).map(w => `${w.A.toFixed(1)}sin(${w.k.toFixed(1)}x + ${w.phi.toFixed(1)})`).join(' + ') || '0'}

let waves = [
${waveData}
];
let speed = ${speed.toFixed(1)};
let sliders = {};

function setup() {
  createCanvas(800, 500);

  let y = 10;
  for (let i = 0; i < waves.length; i++) {
    sliders['A' + i] = createSlider(0, 5, waves[i].A, 0.1);
    sliders['A' + i].position(620, y); sliders['A' + i].style('width', '160px');
    sliders['k' + i] = createSlider(0.1, 5, waves[i].k, 0.1);
    sliders['k' + i].position(620, y + 20); sliders['k' + i].style('width', '160px');
    sliders['phi' + i] = createSlider(0, TWO_PI, waves[i].phi, 0.01);
    sliders['phi' + i].position(620, y + 40); sliders['phi' + i].style('width', '160px');
    y += 70;
  }
  sliders['speed'] = createSlider(0.1, 3, speed, 0.1);
  sliders['speed'].position(620, y); sliders['speed'].style('width', '160px');
}

function draw() {
  background(17, 17, 34);
  speed = sliders['speed'].value();
  let t = frameCount * 0.03 * speed;

  for (let i = 0; i < waves.length; i++) {
    waves[i].A = sliders['A' + i].value();
    waves[i].k = sliders['k' + i].value();
    waves[i].phi = sliders['phi' + i].value();
  }

  // Slider labels
  fill(180); noStroke(); textSize(9); textFont('monospace');
  let ly = 10;
  for (let i = 0; i < waves.length; i++) {
    fill(waves[i].color[0], waves[i].color[1], waves[i].color[2]);
    text('Wave ' + (i+1) + ': A=' + waves[i].A.toFixed(1) + ' k=' + waves[i].k.toFixed(1) + ' phi=' + waves[i].phi.toFixed(1), 620, ly + 63);
    ly += 70;
  }
  fill(180); text('Speed: ' + speed.toFixed(1), 620, ly + 13);

  // Individual waves (dim)
  for (let i = 0; i < waves.length; i++) {
    let w = waves[i];
    stroke(w.color[0], w.color[1], w.color[2], 60); noFill(); strokeWeight(1);
    beginShape();
    for (let x = 0; x < 600; x += 2) {
      let xNorm = map(x, 0, 600, -2 * PI, 2 * PI);
      let y = height/2 + w.A * sin(w.k * xNorm + w.phi + t) * (height/8);
      vertex(x, y);
    }
    endShape();
  }

  // Superposition (bright)
  stroke(79, 195, 247); strokeWeight(2.5); noFill();
  beginShape();
  for (let x = 0; x < 600; x += 2) {
    let xNorm = map(x, 0, 600, -2 * PI, 2 * PI);
    let ySum = 0;
    for (let w of waves) ySum += w.A * sin(w.k * xNorm + w.phi + t);
    vertex(x, height/2 + ySum * (height/8));
  }
  endShape();

  // Formula
  noStroke(); fill(120); textSize(10);
  let formula = 'h(x,t) = ' + waves.map((w, i) =>
    w.A.toFixed(1) + 'sin(' + w.k.toFixed(1) + 'x + ' + w.phi.toFixed(1) + ')'
  ).join(' + ');
  text(formula, 10, height - 10);
}`;
}

/**
 * Convert 3D Wave state to a p5.js WEBGL sketch
 */
export function wave3DParamsToP5Sketch(waves, interaction = 'superposition') {
  const waveInit = waves.filter(w => w.enabled !== false).map(w =>
    `  { A: ${(w.A || 1).toFixed(1)}, kx: ${(w.kx || 1).toFixed(1)}, ky: ${(w.ky || 0).toFixed(1)}, phi: ${(w.phi || 0).toFixed(2)}, omega: ${(w.omega || 1).toFixed(1)} }`
  ).join(',\n');

  return `// 3D Wave Field — exported from KineticForge 3D Waves
// Margolin: h(x,y,t) = Sum of directional waves
// Interaction mode: ${interaction}

let waves = [
${waveInit}
];
let rotX = -0.5, rotY = 0;
let dragging = false, lastMX, lastMY;

function setup() {
  createCanvas(800, 600, WEBGL);
}

function draw() {
  background(17, 17, 34);
  orbitControl();
  rotateX(rotX); rotateY(rotY);

  let t = frameCount * 0.02;
  let gridSize = 40;
  let spacing = 8;

  // Draw wave surface
  stroke(79, 195, 247, 100); noFill();
  for (let gx = -gridSize/2; gx < gridSize/2; gx++) {
    beginShape(TRIANGLE_STRIP);
    for (let gy = -gridSize/2; gy <= gridSize/2; gy++) {
      for (let dx = 0; dx <= 1; dx++) {
        let x = (gx + dx) * spacing;
        let y = gy * spacing;
        let h = 0;
        ${interaction === 'product' ? 'let prod = 1;' : ''}
        ${interaction === 'max' ? 'let maxH = -Infinity;' : ''}
        for (let w of waves) {
          let val = w.A * sin(w.kx * (gx+dx)*0.1 + w.ky * gy*0.1 - w.omega * t + w.phi);
          ${interaction === 'superposition' ? 'h += val;' : interaction === 'product' ? 'prod *= (val + 1.5);' : 'maxH = max(maxH, val);'}
        }
        ${interaction === 'product' ? 'h = prod - 1;' : ''}
        ${interaction === 'max' ? 'h = maxH;' : ''}
        let heightColor = map(h, -3, 3, 0, 255);
        stroke(lerpColor(color(30, 60, 120), color(79, 195, 247), heightColor/255));
        vertex(x, y, h * 15);
      }
    }
    endShape();
  }

  // Info
  push();
  rotateX(-rotX); rotateY(-rotY);
  fill(180); noStroke(); textSize(12); textAlign(LEFT);
  text('Waves: ' + waves.length + ' | Mode: ${interaction}', -width/2 + 10, -height/2 + 20);
  text('Drag to rotate', -width/2 + 10, -height/2 + 36);
  pop();
}`;
}

/**
 * Convert pattern parameters to a p5.js sketch
 */
export function patternToP5Sketch(type, params) {
  const presets = {
    rose: generateRoseSketch(params),
    lissajous: generateLissajousSketch(params),
    spirograph: generateSpirographSketch(params),
    fourier: generateFourierSketch(params),
    butterfly: generateButterflySketch()
  };
  return presets[type] || presets.rose;
}

function generateRoseSketch(params) {
  return `// Rose Curve — exported from KineticForge Patterns
// r(theta) = radius * cos(n * theta)

let nSlider, rSlider;

function setup() {
  createCanvas(600, 600);
  nSlider = createSlider(1, 12, ${params.n || 5}, 1);
  nSlider.position(10, 10); nSlider.style('width', '200px');
  rSlider = createSlider(0.5, 5, ${params.radius || 3}, 0.5);
  rSlider.position(10, 35); rSlider.style('width', '200px');
}

function draw() {
  background(17, 17, 34);
  let n = nSlider.value();
  let r = rSlider.value();

  fill(180); noStroke(); textSize(11); textFont('monospace');
  text('Petals (n): ' + n, 220, 22);
  text('Radius (r): ' + r, 220, 47);

  translate(width/2, height/2);
  stroke(79, 195, 247); noFill(); strokeWeight(2);
  beginShape();
  let maxTheta = (n % 2 === 0) ? TWO_PI : TWO_PI * 2;
  for (let i = 0; i <= 2000; i++) {
    let theta = map(i, 0, 2000, 0, maxTheta);
    let rr = r * cos(n * theta);
    let x = rr * cos(theta) * 80;
    let y = rr * sin(theta) * 80;
    vertex(x, y);
  }
  endShape();

  // Formula
  fill(120); noStroke(); textSize(10);
  text('r(\u03B8) = ' + r.toFixed(1) + ' cos(' + n + '\u03B8)', -width/2 + 10, height/2 - 15);
}`;
}

function generateLissajousSketch(params) {
  return `// Lissajous Curve — exported from KineticForge Patterns
// x = sin(p*t + delta), y = sin(q*t)

let pSlider, qSlider, dSlider;
let trail = [];

function setup() {
  createCanvas(600, 600);
  pSlider = createSlider(1, 7, ${params.p || 3}, 1);
  pSlider.position(10, 10); pSlider.style('width', '160px');
  qSlider = createSlider(1, 7, ${params.q || 2}, 1);
  qSlider.position(10, 35); qSlider.style('width', '160px');
  dSlider = createSlider(0, TWO_PI, ${(params.delta || 1.57).toFixed(2)}, 0.05);
  dSlider.position(10, 60); dSlider.style('width', '160px');
}

function draw() {
  background(17, 17, 34);
  let p = pSlider.value(), q = qSlider.value(), d = dSlider.value();

  fill(180); noStroke(); textSize(11); textFont('monospace');
  text('P: ' + p, 180, 22); text('Q: ' + q, 180, 47); text('Phase: ' + d.toFixed(2), 180, 72);

  // Draw static curve
  translate(width/2, height/2);
  stroke(79, 195, 247); noFill(); strokeWeight(2);
  beginShape();
  for (let i = 0; i <= 1000; i++) {
    let t = map(i, 0, 1000, 0, TWO_PI);
    vertex(sin(p * t + d) * 230, sin(q * t) * 230);
  }
  endShape();

  // Animated point
  let t = frameCount * 0.02;
  let px = sin(p * t + d) * 230;
  let py = sin(q * t) * 230;
  fill(255); noStroke();
  circle(px, py, 8);

  fill(120); noStroke(); textSize(10);
  text('x = sin(' + p + 't + ' + d.toFixed(1) + ')  y = sin(' + q + 't)', -width/2 + 10, height/2 - 15);
}`;
}

function generateSpirographSketch(params) {
  return `// Spirograph (Hypotrochoid) — exported from KineticForge Patterns
// x = (R-r)cos(t) + d*cos((R-r)/r * t)

let RSlider, rSlider, dSlider;

function setup() {
  createCanvas(600, 600);
  RSlider = createSlider(1, 8, ${params.R || 4}, 0.5);
  RSlider.position(10, 10); RSlider.style('width', '160px');
  rSlider = createSlider(0.5, 4, ${params.r || 1}, 0.25);
  rSlider.position(10, 35); rSlider.style('width', '160px');
  dSlider = createSlider(0.5, 5, ${params.d || 2}, 0.25);
  dSlider.position(10, 60); dSlider.style('width', '160px');
}

function draw() {
  background(17, 17, 34);
  let R = RSlider.value(), r = rSlider.value(), d = dSlider.value();

  fill(180); noStroke(); textSize(11); textFont('monospace');
  text('Outer R: ' + R, 180, 22); text('Inner r: ' + r, 180, 47); text('Pen d: ' + d, 180, 72);

  translate(width/2, height/2);
  let scale = min(width, height) / (2 * (R + d) + 2) * 0.35;
  stroke(79, 195, 247); noFill(); strokeWeight(1.5);
  beginShape();
  for (let i = 0; i <= 5000; i++) {
    let t = map(i, 0, 5000, 0, TWO_PI * 20);
    let x = ((R - r) * cos(t) + d * cos((R - r)/r * t)) * scale * 30;
    let y = ((R - r) * sin(t) - d * sin((R - r)/r * t)) * scale * 30;
    vertex(x, y);
  }
  endShape();
}`;
}

function generateFourierSketch(params) {
  return `// Fourier Series Approximation — exported from KineticForge Patterns
// Square wave = sum of odd harmonics: 4/pi * sum(sin((2n-1)x) / (2n-1))

let hSlider;

function setup() {
  createCanvas(800, 400);
  hSlider = createSlider(1, 30, ${params.harmonics || 5}, 1);
  hSlider.position(10, 10); hSlider.style('width', '200px');
}

function draw() {
  background(17, 17, 34);
  let harmonics = hSlider.value();

  fill(180); noStroke(); textSize(11); textFont('monospace');
  text('Harmonics: ' + harmonics, 220, 22);

  // Draw target (square wave)
  stroke(60); strokeWeight(1);
  for (let x = 0; x < width; x++) {
    let xNorm = map(x, 0, width, -PI, 3*PI);
    let target = (sin(xNorm) >= 0) ? 1 : -1;
    point(x, height/2 - target * height/4);
  }

  // Fourier approximation
  stroke(79, 195, 247); strokeWeight(2); noFill();
  beginShape();
  for (let x = 0; x < width; x++) {
    let xNorm = map(x, 0, width, -PI, 3*PI);
    let y = 0;
    for (let n = 1; n <= harmonics; n++) {
      let k = 2 * n - 1;
      y += (4 / PI) * sin(k * xNorm) / k;
    }
    vertex(x, height/2 - y * height/4);
  }
  endShape();

  // Axis
  stroke(60); strokeWeight(1);
  line(0, height/2, width, height/2);

  fill(120); noStroke(); textSize(10);
  text('f(x) = 4/pi * sum(sin((2n-1)x) / (2n-1)), n=1..' + harmonics, 10, height - 15);
}`;
}

function generateButterflySketch() {
  return `// Butterfly Curve (Temple Fay)
// r = e^cos(t) - 2cos(4t) + sin^5(t/12)

function setup() {
  createCanvas(600, 600);
}

function draw() {
  background(17, 17, 34);
  translate(width/2, height/2);

  stroke(79, 195, 247); noFill(); strokeWeight(1.5);
  beginShape();
  for (let i = 0; i <= 2000; i++) {
    let t = map(i, 0, 2000, 0, TWO_PI);
    let r = exp(cos(t)) - 2 * cos(4*t) + pow(sin(t/12), 5);
    let x = sin(t) * r * 60;
    let y = -cos(t) * r * 60;
    vertex(x, y);
  }
  endShape();

  fill(120); noStroke(); textSize(10);
  text('r = e^cos(t) - 2cos(4t) + sin^5(t/12)', -width/2 + 10, height/2 - 15);
}`;
}

/**
 * Convert four-bar linkage parameters to a p5.js sketch
 */
export function fourBarToP5Sketch(params) {
  const { ground, crank, coupler, rocker } = params;
  return `// Four-Bar Linkage Simulator — exported from KineticForge Mechanize
// Ground=${ground}mm  Crank=${crank}mm  Coupler=${coupler}mm  Rocker=${rocker}mm

let a = ${ground}, b = ${crank}, c = ${coupler}, d = ${rocker};
let angle = 0;
let trail = [];
let running = true;

function setup() {
  createCanvas(800, 500);
}

function draw() {
  background(17, 17, 34);
  if (running) angle += 0.02;

  let scale = min(width, height) / (a + b + c + d) * 1.2;
  let ox = width * 0.3, oy = height * 0.55;

  // Solve four-bar
  let O2x = 0, O2y = 0;
  let O4x = a * scale, O4y = 0;
  let Ax = b * scale * cos(angle);
  let Ay = -b * scale * sin(angle);

  let dx = O4x - Ax, dy = O4y - Ay;
  let dist = sqrt(dx*dx + dy*dy);
  let cs = c * scale, ds = d * scale;

  push(); translate(ox, oy);

  // Ground
  stroke(100); strokeWeight(3); strokeDasharray;
  line(O2x, O2y, O4x, O4y);
  fill(100); noStroke();
  circle(O2x, O2y, 10); circle(O4x, O4y, 10);

  if (dist <= cs + ds && dist >= abs(cs - ds) && dist > 0) {
    let a2 = (cs*cs - ds*ds + dist*dist) / (2*dist);
    let h = sqrt(max(0, cs*cs - a2*a2));
    let px = Ax + a2*dx/dist, py = Ay + a2*dy/dist;
    let Bx = px + h*dy/dist, By = py - h*dx/dist;
    let B2x = px - h*dy/dist, B2y = py + h*dx/dist;
    let BX = By < B2y ? Bx : B2x;
    let BY = By < B2y ? By : B2y;

    // Crank
    stroke(79, 195, 247); strokeWeight(3);
    line(O2x, O2y, Ax, Ay);
    // Coupler
    stroke(255, 167, 38); strokeWeight(3);
    line(Ax, Ay, BX, BY);
    // Rocker
    stroke(102, 187, 106); strokeWeight(3);
    line(O4x, O4y, BX, BY);

    // Coupler midpoint trail
    let mx = (Ax + BX) / 2, my = (Ay + BY) / 2;
    trail.push({x: mx, y: my});
    if (trail.length > 500) trail.shift();

    // Draw trail
    stroke(239, 83, 80, 120); strokeWeight(1); noFill();
    beginShape();
    for (let p of trail) vertex(p.x, p.y);
    endShape();

    // Joints
    fill(255); noStroke();
    circle(Ax, Ay, 7); circle(BX, BY, 7);
  }

  pop();

  // Info
  noStroke(); fill(180); textSize(11); textFont('monospace');
  text('Ground (a): ' + a + 'mm', 10, 20);
  text('Crank (b): ' + b + 'mm', 10, 36);
  text('Coupler (c): ' + c + 'mm', 10, 52);
  text('Rocker (d): ' + d + 'mm', 10, 68);

  // Grashof check
  let sorted = [a, b, c, d].sort((x, y) => x - y);
  let grashof = sorted[0] + sorted[3] <= sorted[1] + sorted[2];
  fill(grashof ? color(102, 187, 106) : color(239, 83, 80));
  text('Grashof: ' + (grashof ? 'PASS' : 'FAIL'), 10, 90);

  fill(150); text('Click to pause/resume | Red = coupler midpoint path', 10, height - 15);
}

function mousePressed() {
  running = !running;
}`;
}

/**
 * Convert cam profile parameters to a p5.js sketch
 */
export function camToP5Sketch(params) {
  const base = params?.base || 30;
  const rise = params?.rise || 15;
  const dwell = params?.dwell || 90;
  return `// Cam Profile Designer — exported from KineticForge Mechanize
// Base circle: ${base}mm  Rise: ${rise}mm  Dwell: ${dwell}deg (harmonic motion)

let baseSlider, riseSlider, dwellSlider;
let angle = 0;

function setup() {
  createCanvas(800, 500);
  baseSlider = createSlider(10, 60, ${base}, 1);
  baseSlider.position(10, 10); baseSlider.style('width', '160px');
  riseSlider = createSlider(5, 40, ${rise}, 1);
  riseSlider.position(10, 35); riseSlider.style('width', '160px');
  dwellSlider = createSlider(0, 180, ${dwell}, 5);
  dwellSlider.position(10, 60); dwellSlider.style('width', '160px');
}

function draw() {
  background(17, 17, 34);
  angle += 0.01;

  let base = baseSlider.value();
  let rise = riseSlider.value();
  let dwell = dwellSlider.value();
  let dwellRad = radians(dwell);
  let riseAngle = PI - dwellRad / 2;
  let fallAngle = PI - dwellRad / 2;

  fill(180); noStroke(); textSize(11); textFont('monospace');
  text('Base: ' + base + 'mm', 180, 22);
  text('Rise: ' + rise + 'mm', 180, 47);
  text('Dwell: ' + dwell + 'deg', 180, 72);

  let scale = 4;
  let cx = width * 0.35, cy = height * 0.55;

  push(); translate(cx, cy);

  // Base circle (dashed)
  stroke(60); strokeWeight(1); noFill();
  circle(0, 0, base * scale * 2);

  // Cam profile
  stroke(79, 195, 247); strokeWeight(2); noFill();
  beginShape();
  for (let i = 0; i <= 360; i++) {
    let theta = radians(i);
    let r = base;
    if (theta < riseAngle) {
      r = base + rise * (1 - cos(PI * theta / riseAngle)) / 2;
    } else if (theta < riseAngle + dwellRad) {
      r = base + rise;
    } else if (theta < riseAngle + dwellRad + fallAngle) {
      let fallTheta = theta - riseAngle - dwellRad;
      r = base + rise * (1 + cos(PI * fallTheta / fallAngle)) / 2;
    }
    vertex(r * scale * cos(theta - angle), -r * scale * sin(theta - angle));
  }
  endShape(CLOSE);

  // Follower position
  let theta = angle % TWO_PI;
  let followerR = base;
  if (theta < riseAngle) {
    followerR = base + rise * (1 - cos(PI * theta / riseAngle)) / 2;
  } else if (theta < riseAngle + dwellRad) {
    followerR = base + rise;
  } else if (theta < riseAngle + dwellRad + fallAngle) {
    let ft = theta - riseAngle - dwellRad;
    followerR = base + rise * (1 + cos(PI * ft / fallAngle)) / 2;
  }

  // Follower
  stroke(255, 167, 38); strokeWeight(2);
  line(0, -followerR * scale, 0, -followerR * scale - 40);
  fill(255, 167, 38); noStroke();
  circle(0, -followerR * scale, 10);

  pop();

  // Displacement graph
  let gx = width * 0.62, gy = 80, gw = width * 0.35, gh = height - 160;
  stroke(60); strokeWeight(1); noFill();
  rect(gx, gy, gw, gh);
  fill(100); noStroke(); textSize(10);
  text('Follower Displacement', gx, gy - 5);

  stroke(79, 195, 247); strokeWeight(1.5); noFill();
  beginShape();
  for (let i = 0; i <= gw; i++) {
    let t = map(i, 0, gw, 0, TWO_PI);
    let r = base;
    if (t < riseAngle) r = base + rise * (1 - cos(PI * t / riseAngle)) / 2;
    else if (t < riseAngle + dwellRad) r = base + rise;
    else if (t < riseAngle + dwellRad + fallAngle) {
      let ft = t - riseAngle - dwellRad;
      r = base + rise * (1 + cos(PI * ft / fallAngle)) / 2;
    }
    vertex(gx + i, gy + gh - map(r - base, 0, rise, 0, gh));
  }
  endShape();

  // Current position on graph
  let graphX = map(angle % TWO_PI, 0, TWO_PI, 0, gw);
  stroke(255, 167, 38); strokeWeight(1);
  line(gx + graphX, gy, gx + graphX, gy + gh);
}`;
}

/**
 * Convert friction calc parameters to a p5.js sketch
 */
export function frictionToP5Sketch(mu = 0.95) {
  return `// Friction Cascade Visualizer — exported from KineticForge Simulate
// F_out = F_in * mu^n  (Margolin rule: max ~9 pulleys per string path)

let muSlider, forceSlider;
let pulleys = 9;

function setup() {
  createCanvas(800, 600);
  muSlider = createSlider(0.80, 0.99, ${mu.toFixed(2)}, 0.01);
  muSlider.position(10, 10); muSlider.style('width', '200px');
  forceSlider = createSlider(1, 20, 10, 0.5);
  forceSlider.position(10, 35); forceSlider.style('width', '200px');
}

function draw() {
  background(17, 17, 34);
  let mu = muSlider.value();
  let F_in = forceSlider.value();

  fill(180); noStroke(); textSize(11); textFont('monospace');
  text('Friction coeff (mu): ' + mu.toFixed(2), 220, 22);
  text('Input force (N): ' + F_in.toFixed(1), 220, 47);

  // Draw pulley cascade
  let startX = 80, y = 180, spacing = 70;
  for (let i = 0; i <= 12; i++) {
    let x = startX + i * spacing;
    let eff = pow(mu, i);
    let force = F_in * eff;
    let overLimit = i > 9;

    // Pulley circle
    stroke(overLimit ? color(239, 83, 80) : color(79, 195, 247));
    strokeWeight(2); noFill();
    circle(x, y, 30);

    // String
    if (i > 0) {
      stroke(overLimit ? 80 : 150); strokeWeight(1);
      line(x - spacing + 15, y, x - 15, y);
    }

    // Labels
    noStroke();
    fill(overLimit ? color(239, 83, 80) : 200);
    textSize(9); textAlign(CENTER);
    text(i, x, y + 4);
    textSize(8);
    text(force.toFixed(1) + 'N', x, y + 30);
    text((eff * 100).toFixed(0) + '%', x, y + 42);
  }

  // Limit line
  let limitX = startX + 9 * spacing + spacing/2;
  stroke(239, 83, 80, 100); strokeWeight(1);
  line(limitX, 100, limitX, 280);
  fill(239, 83, 80); noStroke(); textSize(9); textAlign(LEFT);
  text('LIMIT (9)', limitX + 4, 110);

  // Efficiency curve
  textAlign(LEFT);
  let gx = 60, gy = 320, gw = 700, gh = 220;
  stroke(60); strokeWeight(1); noFill();
  rect(gx, gy, gw, gh);
  fill(100); noStroke(); textSize(10);
  text('Efficiency vs Pulleys', gx, gy - 8);

  // Grid
  stroke(40); strokeWeight(0.5);
  for (let p = 0; p <= 20; p += 5) {
    let x = map(p, 0, 20, gx, gx + gw);
    line(x, gy, x, gy + gh);
    fill(80); noStroke(); textSize(8);
    text(p, x - 4, gy + gh + 12);
  }

  // Curve
  stroke(79, 195, 247); strokeWeight(2); noFill();
  beginShape();
  for (let n = 0; n <= 20; n++) {
    let eff = pow(mu, n) * 100;
    vertex(map(n, 0, 20, gx, gx + gw), map(eff, 0, 100, gy + gh, gy));
  }
  endShape();

  // 50% line
  stroke(239, 83, 80, 80); strokeWeight(1);
  let y50 = map(50, 0, 100, gy + gh, gy);
  line(gx, y50, gx + gw, y50);
  fill(239, 83, 80); noStroke(); textSize(8);
  text('50%', gx + gw + 4, y50 + 4);

  // 9-pulley line
  stroke(255, 167, 38, 80); strokeWeight(1);
  let x9 = map(9, 0, 20, gx, gx + gw);
  line(x9, gy, x9, gy + gh);

  fill(180); noStroke(); textSize(10);
  text('Formula: F_out = ' + F_in.toFixed(1) + ' * ' + mu.toFixed(2) + '^n', 10, height - 15);
  text('At 9 pulleys: ' + (pow(mu, 9) * 100).toFixed(1) + '% efficiency, F_out = ' + (F_in * pow(mu, 9)).toFixed(1) + 'N', 350, height - 15);
}`;
}

// ────────────────────────────────────────────────────
// HELPER: Create the "Open in p5 Editor" button HTML
// ────────────────────────────────────────────────────

export function createP5Button(label = 'Open in p5 Editor', style = '') {
  return `<button class="p5-editor-btn" style="display:inline-flex;align-items:center;gap:5px;
    padding:5px 12px;font-size:11px;border:1px solid #e91e63;color:#e91e63;
    background:transparent;border-radius:var(--radius);cursor:pointer;
    transition:all 0.15s;${style}"
    onmouseenter="this.style.background='#e91e631a'"
    onmouseleave="this.style.background='transparent'">
    <span style="font-size:13px;">\u{1F3A8}</span> ${label}
  </button>`;
}

// ────────────────────────────────────────────────────
// UTILITY
// ────────────────────────────────────────────────────

function escapeHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}
