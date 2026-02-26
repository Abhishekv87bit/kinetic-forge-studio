# Kinetic Discovery Suite — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build 27 standalone HTML experiments for discovering kinetic sculpture motion niches through randomization, mutation, and evolutionary search.

**Architecture:** Each experiment = single self-contained HTML file using p5.js (CDN). Sidebar-based layout (280px left sidebar, flex canvas). Shared aesthetic (cream #f5f3ee, Georgia serif, engineering-drawing style). Atlas mode (4×4 grid) + single mode (click to inspect). Each file is fully independent — no shared JS modules.

**Tech Stack:** p5.js 1.9.0 (CDN), vanilla JS, inline CSS, HTML5 Canvas (2D) or WebGL (3D)

---

## Reference: Existing Patterns

Before building, study these existing files for the established code patterns:

| File | Pattern it demonstrates |
|------|------------------------|
| `exp_coupler_curves_2d.html` | Four-bar solver, atlas grid, top control bar, `computeFullCurve()` |
| `exp_compound_coupler_2d.html` | **Sidebar layout** (280px), slider wiring, HUD, layer list, beauty scoring |
| `exp_chaos_garden_3d.html` | 3D WEBGL, RK4 integration, camera controls |
| `exp_harmonograph_3d.html` | 3D trails, multiple tracers, randomization |
| `exp_lorenz_attractor_3d.html` | Batched line rendering in WEBGL, ghost pre-computation |

**All new experiments use the sidebar layout from `exp_compound_coupler_2d.html`** (not the top-bar layout from `exp_coupler_curves_2d.html`).

---

## Reference: Shared Template Structure

Every new experiment file follows this skeleton:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>[EXPERIMENT TITLE]</title>
<script src="https://cdn.jsdelivr.net/npm/p5@1.9.0/lib/p5.min.js"></script>
<style>
  /* === SHARED CSS (copy from exp_compound_coupler_2d.html) === */
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #f5f3ee; overflow: hidden; font-family: 'Georgia', serif; display: flex; height: 100vh; }
  #sidebar { width: 280px; min-width: 280px; background: #f0ede6; border-right: 1px solid #c8c0b0; overflow-y: auto; padding: 12px 14px; font-size: 12px; color: #444; }
  #sidebar h1 { font-size: 14px; letter-spacing: 1.5px; color: #333; margin-bottom: 2px; font-weight: normal; }
  #sidebar .subtitle { font-size: 10px; color: #888; margin-bottom: 12px; font-style: italic; }
  .section-title { font-size: 9px; text-transform: uppercase; letter-spacing: 2px; color: #8b7355; margin-top: 14px; margin-bottom: 6px; border-bottom: 1px solid #d8d0c0; padding-bottom: 3px; }
  .ctrl-row { display: flex; align-items: center; margin-bottom: 5px; }
  .ctrl-row label { flex: 0 0 85px; font-size: 11px; color: #666; }
  .ctrl-row input[type="range"] { flex: 1; height: 3px; accent-color: #8b4513; }
  .ctrl-row .val { flex: 0 0 50px; text-align: right; font-size: 10px; color: #555; font-family: 'Consolas', monospace; }
  select { width: 100%; padding: 4px 8px; font-size: 11px; font-family: 'Georgia', serif; background: #faf8f3; color: #555; border: 1px solid #c8c0b0; border-radius: 3px; margin-bottom: 4px; }
  .btn-row { display: flex; gap: 5px; margin: 8px 0; flex-wrap: wrap; }
  .btn { padding: 5px 10px; font-size: 10px; font-family: 'Georgia', serif; background: #555; color: #f5f3ee; border: none; cursor: pointer; letter-spacing: 0.5px; border-radius: 2px; }
  .btn:hover { background: #333; }
  .btn.active { background: #8b4513; }
  .btn.accent { background: #2a6848; }
  .btn.accent:hover { background: #1a4830; }
  #canvas-container { flex: 1; position: relative; }
  #canvas-container canvas { display: block; }
  #info-bar { position: fixed; bottom: 0; left: 280px; right: 0; z-index: 100; background: rgba(245,243,238,0.92); border-top: 1px solid #bbb; padding: 4px 16px; font-size: 10px; color: #777; font-style: italic; }
  #hud { position: absolute; top: 8px; right: 12px; background: rgba(245,243,238,0.9); border: 1px solid #c8c0b0; border-radius: 4px; padding: 8px 12px; font-size: 10px; line-height: 1.7; color: #666; min-width: 150px; pointer-events: none; }
  #hud .hv { color: #444; font-family: 'Consolas', monospace; float: right; }
  ::-webkit-scrollbar { width: 4px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: #c8c0b0; border-radius: 2px; }
</style>
</head>
<body>
<div id="sidebar">
  <h1>[EXPERIMENT NAME]</h1>
  <div class="subtitle">[One-line description]</div>
  <!-- Experiment-specific controls -->
</div>
<div id="canvas-container">
  <div id="hud"><!-- Live stats --></div>
</div>
<div id="info-bar">[Description text]</div>

<script>
// ===== CONSTANTS =====
const COLS = 4, ROWS = 4;
const ATLAS_TRAIL = 500, SINGLE_TRAIL = 5000;

// ===== STATE =====
let mode = 'atlas'; // 'atlas' or 'single'
let cells = [];     // array of 16 configs (atlas)
let selectedIdx = -1;
let globalTime = 0;

// ===== CORE SOLVER =====
// [Experiment-specific math goes here]

// ===== CONFIG GENERATOR =====
function randomConfig() { /* return random params */ }
function mutateConfig(cfg) { /* perturb by ±10-15% */ }
function isValid(cfg) { /* return true if mechanism works at all angles */ }

// ===== BEAUTY SCORER =====
function scoreCurve(pts) {
  if (pts.length < 10) return 0;
  let minX=Infinity, maxX=-Infinity, minY=Infinity, maxY=-Infinity;
  for (let p of pts) { minX=Math.min(minX,p.x); maxX=Math.max(maxX,p.x); minY=Math.min(minY,p.y); maxY=Math.max(maxY,p.y); }
  let w = maxX-minX, h = maxY-minY;
  let area = w*h;
  if (area < 1) return 0;
  let perim = 0;
  for (let i=1;i<pts.length;i++) { let dx=pts[i].x-pts[i-1].x, dy=pts[i].y-pts[i-1].y; perim+=Math.sqrt(dx*dx+dy*dy); }
  let complexity = (perim / Math.sqrt(area)) * 3;
  let inflections = 0;
  for (let i=2;i<pts.length;i++) {
    let c1 = (pts[i-1].x-pts[i-2].x)*(pts[i].y-pts[i-1].y) - (pts[i-1].y-pts[i-2].y)*(pts[i].x-pts[i-1].x);
    let c0 = (pts[i-2].x-pts[Math.max(0,i-3)].x)*(pts[i-1].y-pts[i-2].y) - (pts[i-2].y-pts[Math.max(0,i-3)].y)*(pts[i-1].x-pts[i-2].x);
    if (c1*c0 < 0) inflections++;
  }
  let aspect = Math.min(w,h)/Math.max(w,h);
  let score = inflections*2 + complexity + (aspect>0.3?10:0);
  // Self-intersection bonus
  let crossings = 0;
  for (let i=2;i<pts.length;i+=3) for (let j=i+3;j<pts.length;j+=3) {
    if (segmentsIntersect(pts[i-1],pts[i],pts[j-1],pts[j])) crossings++;
  }
  score += Math.min(crossings, 10) * 5;
  // Closure bonus
  let dx=pts[pts.length-1].x-pts[0].x, dy=pts[pts.length-1].y-pts[0].y;
  if (Math.sqrt(dx*dx+dy*dy) < perim*0.05) score += 15;
  return score;
}

function segmentsIntersect(a,b,c,d) {
  let det = (b.x-a.x)*(d.y-c.y) - (b.y-a.y)*(d.x-c.x);
  if (Math.abs(det)<1e-10) return false;
  let t = ((c.x-a.x)*(d.y-c.y) - (c.y-a.y)*(d.x-c.x))/det;
  let u = ((c.x-a.x)*(b.y-a.y) - (c.y-a.y)*(b.x-a.x))/det;
  return t>0.01 && t<0.99 && u>0.01 && u<0.99;
}

// ===== ACTIONS =====
function randomizeAll() { cells = []; for (let i=0;i<COLS*ROWS;i++) { let c; let tries=0; do { c=randomConfig(); tries++; } while(!isValid(c)&&tries<50); cells.push({config:c, trail:[], curve:[]}); } }
function mutateAll() { for (let cell of cells) { let m; let tries=0; do { m=mutateConfig(cell.config); tries++; } while(!isValid(m)&&tries<30); cell.config=m; cell.trail=[]; cell.curve=[]; } }
function findBeautiful() {
  let best = []; for (let i=0;i<200;i++) { let c; let tries=0; do {c=randomConfig();tries++;} while(!isValid(c)&&tries<50); let pts=computeTrace(c); let s=scoreCurve(pts); best.push({config:c, score:s, pts:pts}); }
  best.sort((a,b)=>b.score-a.score);
  cells = best.slice(0,16).map(b=>({config:b.config, trail:[], curve:[]}));
}

// ===== P5.JS SKETCH =====
const sketch = (p) => {
  let cw, ch;
  p.setup = () => {
    let container = document.getElementById('canvas-container');
    cw = container.clientWidth; ch = container.clientHeight;
    p.createCanvas(cw, ch).parent(container);
    randomizeAll();
  };
  p.windowResized = () => { /* resize */ };
  p.draw = () => {
    p.background(245, 243, 238);
    let speed = parseFloat(document.getElementById('sl-speed').value);
    globalTime += speed * 0.02;
    if (mode === 'atlas') drawAtlas(p);
    else drawSingle(p);
    updateHUD();
  };
  p.mousePressed = () => {
    if (mode === 'atlas') {
      let mx = p.mouseX, my = p.mouseY;
      let cellW = cw/COLS, cellH = ch/ROWS;
      let col = Math.floor(mx/cellW), row = Math.floor(my/cellH);
      if (col>=0 && col<COLS && row>=0 && row<ROWS) { selectedIdx = row*COLS+col; mode='single'; /* update UI */ }
    }
  };
};
new p5(sketch, 'canvas-container');

// ===== UI WIRING =====
// Wire up sliders, buttons, mode toggles
</script>
</body>
</html>
```

---

## Reference: Verification Checklist (Every Experiment)

After building each experiment, verify ALL of these:

```
[ ] File opens in Chrome without console errors
[ ] Atlas mode shows 16 cells with animated content
[ ] "Randomize" button generates 16 new configs — verify visual variety
[ ] Click a cell → enters single mode with detail view
[ ] Single mode shows full trail rendering
[ ] "Mutate" perturbs current configs (subtle changes, not full randomize)
[ ] "Find Beautiful" populates atlas with highest-scoring configs
[ ] Speed slider affects animation speed
[ ] Trail length slider affects trail accumulation
[ ] HUD shows FPS ≥ 30 in atlas, ≥ 60 in single
[ ] Info bar shows relevant text
[ ] No visual artifacts (lines clipping, NaN positions, degenerate shapes)
[ ] Coordinate system correct (Y-up in math, Y-down on screen for 2D)
```

---

## WAVE 1: Core Discovery Engines

### Task 1: Linkage Lab — Dyad Composition Engine

**Files:**
- Create: `exp_linkage_lab_2d.html`

**Context:** This is the FOUNDATION experiment. Its dyad composition solver and circle-circle intersection function are reused by Experiments 5, 15, 24, 25. Get this right.

**Step 1: Write the full experiment file**

Create `exp_linkage_lab_2d.html` with:

1. **Core solver — circle-circle intersection:**
```javascript
function circleCircleIntersect(cx1, cy1, r1, cx2, cy2, r2) {
  let dx = cx2-cx1, dy = cy2-cy1;
  let d = Math.sqrt(dx*dx + dy*dy);
  if (d > r1+r2-0.001 || d < Math.abs(r1-r2)+0.001) return null;
  let a = (r1*r1 - r2*r2 + d*d) / (2*d);
  let h = Math.sqrt(Math.max(0, r1*r1 - a*a));
  let mx = cx1 + a*dx/d, my = cy1 + a*dy/d;
  return {
    sol1: { x: mx + h*dy/d, y: my - h*dx/d },
    sol2: { x: mx - h*dy/d, y: my + h*dx/d }
  };
}
```

2. **Dyad composition algorithm:**
   - Ground link: J0=(0,0), J1=(groundLen,0) — both grounded
   - Crank from J0: J2 rotates at motor speed
   - For each dyad d=1..D: pick connectA, connectB from existing joints, random bar lengths L1,L2, solve new joint via circle-circle intersection
   - Branch tracking: at t=0, pick solution with positive Y; thereafter pick closest to previous frame

3. **Config generator:**
   - `numDyads`: 1-9 (slider)
   - `groundLen`: 80-120
   - `crankLen`: 15-60 (must be < groundLen)
   - `dyad[i].connectA/B`: random from solved joints (A ≠ B)
   - `dyad[i].L1, L2`: 20-120
   - `outputJoint`: random non-ground joint

4. **Validation:** test-solve at 72 angles (every 5°). If ANY angle fails → discard. Max 50 retries.

5. **Mutation:** keep topology, perturb bar lengths by gaussian(sigma=8%), re-validate.

6. **Sidebar controls:**
   - Dyad count slider (1-9)
   - Output joint selector
   - Ground length, crank length sliders
   - Randomize, Mutate, Find Beautiful buttons
   - Atlas/Single toggle

7. **Rendering:**
   - Atlas: 4×4 grid, each cell draws ground+bars+joints+coupler trail
   - Single: full-size mechanism with longer trail, all joints labeled
   - Color: ground=gray, crank=red, bars=alternating colors per dyad, trail=gradient

8. **Beauty scoring:** use shared `scoreCurve()` on output joint trajectory

**Step 2: Open in Chrome and verify atlas mode**

Open `exp_linkage_lab_2d.html` in Chrome. Verify:
- 16 cells each showing a mechanism with moving linkages
- Each mechanism has different topology (different bar counts, connections)
- No cells show NaN or frozen mechanisms
- Console has zero errors

**Step 3: Test randomize/mutate/find-beautiful**

- Click "Randomize" 5× — confirm visual variety
- Click "Mutate" — confirm subtle changes (not full randomize)
- Click "Find Beautiful" — confirm atlas fills with complex curves
- Click a cell → single mode with detail view
- Adjust dyad count slider — confirm rebuild with new count

**Step 4: Commit**

```bash
git add exp_linkage_lab_2d.html
git commit -m "feat: add linkage lab experiment — dyad composition engine"
```

---

### Task 2: Cam Profile Synthesizer

**Files:**
- Create: `exp_cam_synth_2d.html`

**Context:** Fourier-based cam profile generation. This cam engine is reused by Experiment 16 (Multi-Cam Sequencer).

**Step 1: Write the full experiment file**

Create `exp_cam_synth_2d.html` with:

1. **Core solver — Fourier cam profile:**
```javascript
function camRadius(theta, baseR, harmonics) {
  let r = baseR;
  for (let k = 0; k < harmonics.length; k++) {
    r += harmonics[k].amp * Math.cos((k+1)*theta + harmonics[k].phase);
  }
  return Math.max(r, baseR * 0.2);
}

function camProfile(baseR, harmonics, steps) {
  let pts = [];
  for (let i = 0; i < steps; i++) {
    let theta = (i/steps) * Math.PI*2;
    let r = camRadius(theta, baseR, harmonics);
    pts.push({ x: r*Math.cos(theta), y: r*Math.sin(theta) });
  }
  return pts;
}
```

2. **Three follower types:**
   - Flat translating: `follower_y = camRadius(theta) - baseR`
   - Roller: offset by roller radius, compute contact point
   - Oscillating arm: pivoted at fixed point, cam pushes arm, traces arc

3. **Config generator:**
   - `numHarmonics`: 2-16
   - `harmonics[k].amp`: 0 to baseR×0.3 (decreasing with k)
   - `harmonics[k].phase`: 0-2π
   - `baseRadius`: 40-80
   - `followerType`: flat/roller/oscillating
   - `rotationSpeed`: 0.5-3.0

4. **Cam validity:** radius > 0 at all angles. Pressure angle < 45°. If invalid, halve amplitudes and retry.

5. **Sidebar controls:** harmonic count, follower type dropdown, base radius, rotation speed, Randomize/Mutate/Find Beautiful

6. **Rendering:**
   - Atlas: each cell shows cam shape (filled, slight transparency) + animated follower + output displacement curve trace
   - Single: large cam with roller animation + displacement graph below

**Step 2: Open in Chrome and verify**

Verify 16 distinct cam shapes, animated followers, displacement curves. No self-intersecting cam profiles.

**Step 3: Test controls and modes**

Test randomize, mutate, follower type switching, single mode click-to-inspect.

**Step 4: Commit**

```bash
git add exp_cam_synth_2d.html
git commit -m "feat: add cam profile synthesizer — Fourier cam generation"
```

---

### Task 3: Non-Circular Gear Pair Explorer

**Files:**
- Create: `exp_noncircular_gears_2d.html`

**Step 1: Write the full experiment file**

1. **Core math — non-circular gear pair:**
   - Input gear pitch curve: `r1(θ) = R_base + Σ aₖ cos(kθ + φₖ)`
   - Output gear: `r2(θ₂) = C - r1(θ₁)` where C = center distance
   - Speed ratio: `ω₂/ω₁ = r1(θ₁) / r2(θ₂)` — varies with angle
   - θ₂ from θ₁: numerically integrate `dθ₂/dθ₁ = r1/r2` using RK4

2. **Gear profile rendering:**
   - Draw pitch curve as closed shape
   - Simplified tooth profiles: small bumps along pitch curve at tooth spacing
   - Both gears rotate correctly (θ₂ tracks θ₁ via integrated ODE)

3. **Chaining 1-3 gear stages:** compound ratio = product of instantaneous ratios

4. **Config:** numGearPairs (1-3), harmonics per gear (1-6), center distance (computed)

5. **Gear validity:** r1(θ)>0 and r2(θ)>0 for all θ. No cusps.

6. **Rendering:**
   - Atlas: each cell shows gear pair animated + small speed ratio graph
   - Single: large gear mesh animation + speed ratio vs time plot

**Step 2: Verify in Chrome**

**Step 3: Test controls**

**Step 4: Commit**

```bash
git add exp_noncircular_gears_2d.html
git commit -m "feat: add non-circular gear pair explorer"
```

---

### Task 4: Spirograph Deep Explorer

**Files:**
- Create: `exp_spirograph_deep_2d.html`

**Step 1: Write the full experiment file**

1. **Core math — nested epicycles (up to 8 circles):**
```javascript
function spirographPoint(circles, t) {
  let x = 0, y = 0;
  for (let i = 0; i < circles.length; i++) {
    x += circles[i].R * Math.cos(circles[i].omega * t + circles[i].phase);
    y += circles[i].R * Math.sin(circles[i].omega * t + circles[i].phase);
  }
  return { x, y };
}
```
   - `omega[i]` = true rolling: `dir[i] * (R[i-1]/R[i]) * omega[i-1]`

2. **Three radius modes:**
   - Integer: R from {10,15,20,25,30...} → closed curves
   - Irrational: R = random float → never-closing curves
   - Near-integer: R = integer ± small epsilon → almost-closing (most beautiful)

3. **Config:** numCircles (2-8), R[i] (5-80, decreasing), dir[i] (±1), penOffset, penAngle

4. **Rendering:**
   - Atlas: each cell traces the compound curve
   - Single: show spinning circles hierarchy + pen tracing

**Step 2-4:** Verify, test, commit.

```bash
git add exp_spirograph_deep_2d.html
git commit -m "feat: add spirograph deep explorer — nested epicycles"
```

---

### Task 5: Walker Gait Lab

**Files:**
- Create: `exp_walker_gait_2d.html`

**Context:** Reuses the EXACT dyad composition solver from Task 1. Copy the solver code.

**Step 1: Write the full experiment file**

1. **Solver:** copy circle-circle intersection + dyad composition from Task 1 verbatim

2. **Walking fitness function:**
   - Track lowest joint's Y trajectory over one crank revolution
   - Stance flatness: variance of Y during lowest 40% of trajectory
   - Step height: max Y - min Y (want sufficient clearance)
   - Forward progress: net X displacement during stance
   - Smoothness: sum of acceleration magnitudes (lower = smoother)
   - Score = flatness×30 + heightScore×20 + forwardProgress×0.5 + smoothness×20

3. **Visual differentiation from Linkage Lab:**
   - Ground line at Y_min
   - Foot trajectory colored: green=stance, red=swing
   - Walking score prominently displayed per cell

4. **Atlas:** 4×4 grid, each cell shows leg mechanism + ground + colored foot path
5. **Single mode:** larger mechanism + walk cycle animation (translate mechanism by foot X progress)

**Step 2-4:** Verify, test, commit.

```bash
git add exp_walker_gait_2d.html
git commit -m "feat: add walker gait lab — dyad mechanisms scored for walking"
```

---

## WAVE 2: Shape & Curve Explorers

### Task 6: Superformula Morpher

**Files:**
- Create: `exp_superformula_2d.html`

**Step 1: Write the full experiment file**

1. **Core math — Gielis superformula:**
```javascript
function superformula(theta, m1, m2, n1, n2, n3, a, b) {
  let t1 = Math.pow(Math.abs(Math.cos(m1*theta/4) / a), n2);
  let t2 = Math.pow(Math.abs(Math.sin(m2*theta/4) / b), n3);
  let r = Math.pow(t1 + t2, -1/n1);
  return isFinite(r) ? r : 0;
}
```

2. **Four animation modes:**
   - Static morph (sliders)
   - Breathing (params oscillate sinusoidally)
   - As cam (shape drives follower)
   - Compound (two shapes nested)

3. **Config:** m1,m2 (0-12), n1 (0.1-5), n2,n3 (0.1-5), a,b (0.5-2.0)

4. **Rendering:** shape as filled polygon + animated mode indicator

**Step 2-4:** Verify, test, commit.

```bash
git add exp_superformula_2d.html
git commit -m "feat: add superformula morpher — Gielis parameter space"
```

---

### Task 7: Rose Curve / Polar Explorer

**Files:**
- Create: `exp_polar_curves_2d.html`

**Step 1: Write the full experiment file**

1. **Core math — multi-term polar equation:**
   - `r(θ) = Σ A[k] * func[k](freq[k]*θ + phase[k])` with N=1-6 terms
   - func: cos, sin, |cos|, |sin|, sawtooth, triangle

2. **Notable presets:** rose, spiral, lemniscate, cardioid, limacon

3. **Unique feature: morph mode** — continuously interpolate between two random configs

4. **Rendering:** pen traveling along curve, radial grid lines for reference

**Step 2-4:** Verify, test, commit.

```bash
git add exp_polar_curves_2d.html
git commit -m "feat: add polar curve explorer — multi-term random polar equations"
```

---

### Task 8: Math Function Drivers

**Files:**
- Create: `exp_math_drivers_2d.html`

**Step 1: Write the full experiment file**

1. **Function library:** Weierstrass, Riemann zeta (critical line approximation), Mandelbrot boundary, logistic bifurcation, Collatz path

2. **Driving modes:** X-Y split, parametric, sequential

3. **Config:** funcX, funcY (enum), params per function, timeScale

4. **Performance note:** Weierstrass and zeta use truncated series (N≤50 terms) to maintain FPS

**Step 2-4:** Verify, test, commit.

```bash
git add exp_math_drivers_2d.html
git commit -m "feat: add math function drivers — strange attractors from pure math"
```

---

### Task 9: Straight-Line Mechanism Sweep

**Files:**
- Create: `exp_straight_line_2d.html`

**Step 1: Write the full experiment file**

1. **Five mechanism types with KNOWN ideal link ratios:**
   - Peaucellier-Lipkin (7 bars, exact)
   - Hart's Inversor (5 bars, exact)
   - Watt's (5 bars, approximate)
   - Chebyshev (4 bars: ground=2, crank=2.5, coupler=5, rocker=2.5)
   - Hoecken (4 bars, different ratios)

2. **Each uses its specific four-bar/multi-bar solver** (Chebyshev/Watt/Hoecken use the standard four-bar solver from Task 1)

3. **Perturbation approach:** sigma parameter (0 to 0.5) distorts ideal link lengths

4. **Atlas layout:** rows=mechanism types, columns=increasing perturbation (0, 0.05, 0.1, 0.2)

5. **Unique display:** straightness score = deviation from perfect line

**Step 2-4:** Verify, test, commit.

```bash
git add exp_straight_line_2d.html
git commit -m "feat: add straight-line mechanism sweep — perturbation from ideal"
```

---

## WAVE 3: Network & Grid Systems

### Task 10: Coupled Oscillator Network

**Files:**
- Create: `exp_coupled_oscillators_2d.html`

**Step 1: Write the full experiment file**

1. **Core — Kuramoto model:**
```javascript
function kuramotoStep(theta, omega, K, dt) {
  for (let i = 0; i < theta.length; i++) {
    let dth = omega[i];
    for (let j = 0; j < theta.length; j++) {
      if (K[i][j] !== 0) dth += K[i][j] * Math.sin(theta[j] - theta[i]);
    }
    theta[i] += dth * dt;
  }
}
```

2. **Five coupling topologies:** ring, star, random graph, small-world, scale-free

3. **Order parameter:** `R = |1/N × Σ exp(i×theta[i])|` (0=desync, 1=sync)

4. **Config:** N (5-50), topology, omega distribution, K_base, p_connect

5. **Rendering:** oscillators as colored dots on a circle (phase=position), coupling lines, R-bar indicator

**Step 2-4:** Verify, test, commit.

```bash
git add exp_coupled_oscillators_2d.html
git commit -m "feat: add coupled oscillator network — Kuramoto synchronization"
```

---

### Task 11: Kinematic Tile Grid

**Files:**
- Create: `exp_kinematic_tiles_2d.html`

**Step 1: Write the full experiment file**

1. **Core concept:** unit cell = four-bar linkage in square tile, MxN tiling with shared boundary joints

2. **Iterative constraint projection solver** (20 iterations per frame):
   - For each bar: project endpoints to satisfy length constraint
   - Average correction between endpoints

3. **Config:** gridSize (2×2 to 6×6), cell bar lengths, topology, motor position

4. **Rendering:** grid of tiles with bars and joints, motion propagation visible as wave

**Step 2-4:** Verify, test, commit.

```bash
git add exp_kinematic_tiles_2d.html
git commit -m "feat: add kinematic tile grid — motion propagation through tiled mechanisms"
```

---

### Task 12: Moire Pattern Animator

**Files:**
- Create: `exp_moire_2d.html`

**Step 1: Write the full experiment file**

1. **Five pattern types:** parallel lines, concentric circles, radial lines, grid, spiral

2. **Two overlapping patterns with relative motion** — purely optical, no physics

3. **Config:** pattern types, spacings, angles, rotation speeds, line weight

4. **Rendering:** draw both patterns; visual interference creates apparent motion

**Step 2-4:** Verify, test, commit.

```bash
git add exp_moire_2d.html
git commit -m "feat: add moire pattern animator — optical motion illusion"
```

---

### Task 13: Bistable Snap-Through Array

**Files:**
- Create: `exp_bistable_array_2d.html`

**Step 1: Write the full experiment file**

1. **Core physics:** double-well potential per element, cascade when neighbor force > barrier

2. **Four topologies:** line, ring, grid, random

3. **Config:** N (10-50), topology, barrier/coupling per element, trigger point

4. **Rendering:** elements as colored dots (flat=gray, snapped=red, reversing=yellow), cascade as time-lapse

**Step 2-4:** Verify, test, commit.

```bash
git add exp_bistable_array_2d.html
git commit -m "feat: add bistable snap-through array — cascade propagation"
```

---

## WAVE 4: Complex Mechanism Randomizers

### Task 14: Gear Train Randomizer

**Files:**
- Create: `exp_gear_train_2d.html`

**Step 1: Write the full experiment file**

1. **Gear types:** spur pair, compound (two on same shaft), idler, planetary stage (20% chance)

2. **Topology:** directed graph of shafts connected by gear meshes. Ensure connectivity via spanning tree.

3. **Config:** numShafts (3-8), teeth per gear (12-72), compound per shaft (50% chance)

4. **Visual:** gears actually rotate with correct tooth meshing visualization (simplified: circles with radial tick marks at tooth positions)

5. **Output:** speed ratio graph (output shaft angular velocity vs time)

**Step 2-4:** Verify, test, commit.

```bash
git add exp_gear_train_2d.html
git commit -m "feat: add gear train randomizer — random gear topologies"
```

---

### Task 15: Automata Figure Compositor

**Files:**
- Create: `exp_automata_figure_2d.html`

**Context:** Uses four-bar solver from Task 1 for each joint. Copy the `solveFourBar` function.

**Step 1: Write the full experiment file**

1. **Stick figure anatomy:** head, neck, torso, 2 arms (shoulder+elbow+hand), 2 legs (hip+knee+foot)

2. **Each joint driven by independent four-bar linkage** with different speed ratios relative to master

3. **Forward kinematics:** accumulate rotations down each limb chain (torso → shoulder → elbow → hand)

4. **Config:** four-bar params per joint, speedRatio per joint (0.25-4.0), amplitude per joint, limb lengths

5. **Rendering:** stick figure "dancing" — atlas shows 16 different random dances

**Step 2-4:** Verify, test, commit.

```bash
git add exp_automata_figure_2d.html
git commit -m "feat: add automata figure compositor — stick figure with random joint mechanisms"
```

---

### Task 16: Multi-Cam Sequencer

**Files:**
- Create: `exp_multicam_sequencer_2d.html`

**Context:** Reuses Fourier cam generation from Task 2.

**Step 1: Write the full experiment file**

1. **Core concept:** N cams (3-8) on single shaft, each with Fourier profile, each drives its own follower

2. **Phase offsets between cams** create timing relationships (Al-Jazari digitized)

3. **Config:** numCams, harmonics per cam, phaseOffset per cam, followerType per cam

4. **Single mode unique feature:** waterfall view — N follower displacement curves stacked vertically (like a music sequencer)

**Step 2-4:** Verify, test, commit.

```bash
git add exp_multicam_sequencer_2d.html
git commit -m "feat: add multi-cam sequencer — N cams on shared shaft"
```

---

### Task 17: Differential Mechanism Explorer

**Files:**
- Create: `exp_differential_2d.html`

**Step 1: Write the full experiment file**

1. **Core math — differential:**
   - Standard: `ω_out = (ω_in1 + ω_in2) / 2`
   - Weighted: `ω_out = (r1×ω_in1 + r2×ω_in2) / (r1+r2)`
   - Compound (2-3 stages)

2. **Two input cranks** at different speeds (sliders or auto)

3. **Config:** numStages (1-3), gear ratios, input speeds

4. **Rendering:** schematic with rotating elements + output speed graph

**Step 2-4:** Verify, test, commit.

```bash
git add exp_differential_2d.html
git commit -m "feat: add differential mechanism explorer"
```

---

### Task 18: Escapement Zoo

**Files:**
- Create: `exp_escapement_zoo_2d.html`

**Step 1: Write the full experiment file**

1. **Four escapement types:** verge, anchor (recoil), deadbeat, grasshopper

2. **Core simulation:** pendulum dynamics with escapement impulse, damping, tooth release/engagement

3. **Config:** type, pendulum length, teeth count, pallet angle, torque, damping

4. **Single mode:** detailed view + tick interval graph (stability analysis)

**Step 2-4:** Verify, test, commit.

```bash
git add exp_escapement_zoo_2d.html
git commit -m "feat: add escapement zoo — clock mechanism randomizer"
```

---

### Task 19: Pantograph Chain

**Files:**
- Create: `exp_pantograph_chain_2d.html`

**Step 1: Write the full experiment file**

1. **Core math:** pantograph ratio k = long_arm/short_arm. P_out = pivot + k×(P_in - pivot). Scales + reflects.

2. **Chaining 2-5 stages:** net scaling = product of k values, each stage can rotate

3. **Config:** numStages (2-5), ratio per stage (-2.0 to 3.0), rotation per stage, input motion type

4. **Rendering:** pantograph linkage structure visible + input curve → output curve

**Step 2-4:** Verify, test, commit.

```bash
git add exp_pantograph_chain_2d.html
git commit -m "feat: add pantograph chain — motion scaling and transformation"
```

---

## WAVE 5: Physics Simulations

### Task 20: 3-Body Gravitational Orrery

**Files:**
- Create: `exp_three_body_2d.html`

**Step 1: Write the full experiment file**

1. **Core algorithm — RK4 N-body:**
   - `a_i = Σ_j G×m_j×(r_j - r_i) / |r_j - r_i|³`
   - Softening: `r_soft = max(r, 5)` to prevent singularity

2. **Presets:** Figure-8 (Chenciner-Montgomery), Lagrange equilateral, Euler collinear

3. **Config:** mass[0..2] (0.5-3.0), pos (±100), vel (±2)

4. **Scoring:** stability (time before ejection) + trajectory complexity

**Step 2-4:** Verify, test, commit.

```bash
git add exp_three_body_2d.html
git commit -m "feat: add 3-body gravitational orrery — chaotic orbit discovery"
```

---

### Task 21: Magnetic Pendulum Basin Explorer

**Files:**
- Create: `exp_magnetic_pendulum_2d.html`

**Step 1: Write the full experiment file**

1. **Core physics:** spring restoring force + N magnetic attractors + damping

2. **Basin mapping mode:** scan grid of starting positions, simulate each until settled, color by final magnet → fractal boundary

3. **Performance:** basin rendering is compute-heavy. Use progressive rendering (compute N rows per frame, not all at once). Resolution slider (64×64 for preview, 256×256 for final).

4. **Config:** numMagnets (3-7), positions, strengths, springK, damping

5. **Single mode:** live pendulum simulation + progressive basin rendering in background

**Step 2-4:** Verify, test, commit.

```bash
git add exp_magnetic_pendulum_2d.html
git commit -m "feat: add magnetic pendulum basin explorer — fractal attractor boundaries"
```

---

### Task 22: Rattleback Cascade Grid

**Files:**
- Create: `exp_rattleback_cascade_2d.html`

**Step 1: Write the full experiment file**

1. **Core physics (simplified 2D):** asymmetric inertia → spin reversal. When reversal energy exceeds neighbor barrier → cascade.

2. **Config:** gridSize (3×3 to 8×8), asymmetry, coupling, initial spins, trigger point

3. **Rendering:** colored dots (CW=blue, CCW=red, reversing=yellow), cascade as time-lapse

**Step 2-4:** Verify, test, commit.

```bash
git add exp_rattleback_cascade_2d.html
git commit -m "feat: add rattleback cascade grid — spin reversal propagation"
```

---

### Task 23: Cable/Pulley Network Explorer

**Files:**
- Create: `exp_cable_pulley_2d.html`

**Step 1: Write the full experiment file**

1. **Core physics:** inextensible cable, fixed vs free pulleys, tangent contact, tension balance

2. **Cable routing:** ordered list of pulleys, total length = straight segments + arc lengths

3. **Config:** numPulleys (3-10), fixed/free, positions, radii, routing order

4. **Single mode interaction:** drag input cable end → see all free pulleys respond

**Step 2-4:** Verify, test, commit.

```bash
git add exp_cable_pulley_2d.html
git commit -m "feat: add cable/pulley network explorer — mechanical advantage discovery"
```

---

## WAVE 6: Advanced Experiments

### Task 24: L-System Linkage Generator

**Files:**
- Create: `exp_lsystem_linkage_2d.html`

**Context:** Interprets L-system grammar as mechanism structure, then solves using dyad solver from Task 1.

**Step 1: Write the full experiment file**

1. **L-system grammar:** F=bar, +=joint(CW), -=joint(CCW), [=branch, ]=end branch

2. **Preset rules:** tree, fern, dragon, Hilbert + random rule generation

3. **After grammar expansion:** structure = bars + joints. Fix root, apply motor to first joint.

4. **DOF check:** Gruebler's equation. If DOF≠1, add/remove bars to fix.

5. **Solver:** iterative constraint projection (same as kinematic tiles, Task 11)

**Step 2-4:** Verify, test, commit.

```bash
git add exp_lsystem_linkage_2d.html
git commit -m "feat: add L-system linkage generator — fractal mechanisms from grammars"
```

---

### Task 25: Creature Evolver

**Files:**
- Create: `exp_creature_evolver_2d.html`

**Context:** Depends on Task 1 (dyad solver) + Task 5 (walking fitness). Combines both.

**Step 1: Write the full experiment file**

1. **Genome:** encodes numDyads, dyad topology+geometry, motor speed, motor pattern, output joint

2. **Genetic operations:**
   - Crossover: random split point in dyad list, fix topology references
   - Mutation: ±15% bar length, swap connections, add/remove dyad, ±20% motor speed
   - Rate: 15% per gene

3. **Evolution loop:** score all → keep top 25% → crossover+mutate to fill → repeat

4. **Fitness functions (user-selectable):**
   - Curve beauty (shared scoreCurve)
   - Walking quality (from Task 5)
   - Maximum reach
   - Periodicity

5. **Controls:** generation counter, auto-evolve toggle (run N generations per second), fitness selector, "pin" button to protect favorites from replacement

6. **Atlas:** top 16 creatures in current generation, visibly improve each generation

**Step 2-4:** Verify, test, commit.

```bash
git add exp_creature_evolver_2d.html
git commit -m "feat: add creature evolver — genetic algorithm for mechanism discovery"
```

---

### Task 26: Compliant Mechanism Explorer

**Files:**
- Create: `exp_compliant_flex_2d.html`

**Step 1: Write the full experiment file**

1. **Core physics — Euler-Bernoulli (simplified):**
   - Discretize each beam into N segments connected by torsional springs
   - Spring moment: `M = k_θ × (θ_i - θ_{i-1} - θ_rest)` where `k_θ = E×I / L_seg`
   - Iterative relaxation (100 iterations per frame)

2. **Config:** numBeams (2-10), lengths, stiffness per beam, connection topology, fixed points, input point+type

3. **Single mode:** interactive drag input point → real-time deformation

**Step 2-4:** Verify, test, commit.

```bash
git add exp_compliant_flex_2d.html
git commit -m "feat: add compliant mechanism explorer — flexible beam networks"
```

---

### Task 27: 3D Cam Surface Explorer

**Files:**
- Create: `exp_3d_cam_surface_3d.html`

**Context:** Only 3D experiment in the new batch. Uses p5.js WEBGL mode.

**Step 1: Write the full experiment file**

1. **Core math — cylindrical cam surface:**
   - `h(θ, z) = Σ A[m][n] × cos(m×θ + φ_m) × cos(n×z×π/L + ψ_n)`
   - 2D Fourier coefficients define the surface

2. **WEBGL rendering:**
   - Draw cam as mesh using `beginShape(TRIANGLE_STRIP)` per theta slice
   - **Coordinate system:** Y+ = down, cam axis along Y, rotation around Y
   - **Camera:** up vector (0,-1,0), orbit controls

3. **Follower:** roller on cam surface, radial displacement = h(θ,z) - baseR

4. **Config:** thetaHarmonics (1-6), zHarmonics (1-4), amplitudes, phases, baseRadius, camLength

5. **Performance budget:** mesh resolution: 60 theta steps × 30 z steps = 1800 quads in atlas (per cell → reduce to 24×12). Full resolution in single mode only.

**Step 2-4:** Verify, test, commit.

```bash
git add exp_3d_cam_surface_3d.html
git commit -m "feat: add 3D cam surface explorer — cylindrical cam with Fourier surface"
```

---

## Post-Build Tasks

### Task 28: Index Page

**Files:**
- Create: `experiments_index.html`

**Step 1: Create an index page linking all 27 experiments**

Simple HTML page with:
- Title: "Kinetic Discovery Suite"
- 6 sections (Wave 1-6)
- Each experiment listed as a clickable link with one-line description
- Same cream/serif aesthetic

**Step 2: Verify all links work**

**Step 3: Commit**

```bash
git add experiments_index.html
git commit -m "feat: add experiments index page"
```

---

### Task 29: Update Master Document

**Files:**
- Modify: `KINETIC_DISCOVERY_MASTER.md`

**Step 1: Add section referencing all 27 new experiments**

Add a new section listing all experiment files, organized by wave, with brief descriptions.

**Step 2: Commit**

```bash
git add KINETIC_DISCOVERY_MASTER.md
git commit -m "docs: update master doc with 27 new experiment references"
```

---

## Execution Notes

### Parallelism opportunities

The following groups can be built in parallel (no shared state or dependencies):

**Fully independent (can all build simultaneously):**
- Wave 2: Tasks 6, 7, 8 (Superformula, Polar, Math Drivers)
- Wave 3: Tasks 10, 11, 12, 13 (Oscillators, Tiles, Moire, Bistable)
- Wave 5: Tasks 20, 21, 22, 23 (3-Body, Magnetic Pendulum, Rattleback, Cable)

**Sequential chains:**
- Task 1 (Linkage Lab) → Task 5 (Walker) → Task 25 (Creature Evolver)
- Task 1 (Linkage Lab) → Task 15 (Automata Figure)
- Task 1 (Linkage Lab) → Task 24 (L-System Linkage)
- Task 2 (Cam Synth) → Task 16 (Multi-Cam Sequencer)

### Time estimates

- Wave 1 (Tasks 1-5): ~3-4 hours — highest complexity, most algorithm work
- Wave 2 (Tasks 6-9): ~1.5-2 hours — primarily math rendering
- Wave 3 (Tasks 10-13): ~2-2.5 hours — network simulations
- Wave 4 (Tasks 14-19): ~3-3.5 hours — diverse mechanism types
- Wave 5 (Tasks 20-23): ~2-2.5 hours — physics simulations
- Wave 6 (Tasks 24-27): ~3-3.5 hours — most complex algorithms
- Post-build (Tasks 28-29): ~0.5 hours

**Total: ~16-18 hours of implementation**

---

*Plan complete. 29 tasks across 6 waves + post-build. Ready for execution.*
*Design doc: `docs/plans/2026-02-26-kinetic-discovery-suite-design.md`*
*Last updated: 2026-02-26*
