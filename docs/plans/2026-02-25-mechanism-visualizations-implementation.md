# Reuleaux Mechanism Visualizations — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build 6 standalone p5.js WEBGL HTML files visualizing Reuleaux mechanisms with Cell/Grid views and rich interactive controls.

**Architecture:** Each file is a self-contained HTML page (~800-1200 lines) using p5.js 1.9.0 from CDN. Shared visual style matches `kelvin_linkage_3d.html`. Each file has Cell View (single mechanism detail) and Grid View (7x7 wave surface). No build system, no shared modules.

**Tech Stack:** p5.js 1.9.0 (WEBGL mode), vanilla JS, HTML5, Web Audio API (escapement only)

**Design Doc:** `docs/plans/2026-02-25-mechanism-visualizations-design.md`
**Style Reference:** `D:\Claude local\3d_design_agent\waffle_grid_planetary\kelvin_linkage_3d.html`
**Mechanism Specs:** `D:\Claude local\3d_design_agent\waffle_grid_planetary\REULEAUX_DECOMPOSITION_SYNTHESIS.md`
**Output Dir:** `D:\Claude local\3d_design_agent\waffle_grid_planetary\`

---

## Task 1: M8 Gear-Screw Differential (`gear_screw_3d.html`)

**Files:**
- Create: `D:\Claude local\3d_design_agent\waffle_grid_planetary\gear_screw_3d.html`

**Why first:** Simplest geometry (cylinders + boxes), clearest interactions (freeze/solo), establishes the Cell/Grid toggle pattern all other files copy.

### Step 1: Write HTML skeleton + CSS + controls panel

Create the file with:
- DOCTYPE, head with p5.js CDN `https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.9.0/p5.min.js`
- CSS matching kelvin exactly: `body { margin:0; background:#080818; overflow:hidden; font-family:monospace; }`
- `#controls` panel (left): Speed slider, Cell/Grid toggle, layer toggles (Screws, Gears, Nut, Connections, Surface), parameter sliders (Pitch A/B/C 0.5-3mm, Gear Ratio 0.5-3x)
- `#hud` panel (right): Motor A/B/C angles, lock indicator, FPS, Revs, current pitch values
- `#explainer` bar (bottom): "M8 GEAR-SCREW DIFFERENTIAL: 3 screws with different pitches sum 3 inputs. SPACE=freeze 1/2/3=solo F=cutaway"
- View preset buttons: Front/Top/Side/Iso/Reset

### Step 2: Write shared constants + state

```javascript
const PHI = (1 + Math.sqrt(5)) / 2;
const SQRT2 = Math.sqrt(2);
const TWO_PI = Math.PI * 2;
const DEG = Math.PI / 180;

// Motor
const MOTOR_FREQS = [1.0, SQRT2, PHI];
const MOTOR_COLORS = [[255,102,136],[102,187,255],[136,255,102]];
const BASE_SPEED = 0.02;

// Grid (matches kelvin)
const GRID_N = 7;
const GRID_SPACING = 35;
const GO = (GRID_N - 1) * GRID_SPACING / 2;

// Mechanism params (adjustable via sliders)
let pitches = [1.0, 1.5, 2.0];  // mm, screw pitches
let gearRatio = 1.0;
let SCREW_DIA = 8;  // mm
let SCREW_LENGTH = 60;  // mm viz
let NUT_HEIGHT = 12;
let NUT_WIDTH = 20;

// State
let motorAngle = 0;
let SPEED_MULT = 1.0;
let frozen = false;
let soloScrew = 0;  // 0=all, 1/2/3=solo
let showCutaway = false;
let viewMode = 'grid';  // 'cell' or 'grid'
let layers = { screws:true, gears:true, nut:true, connections:true, surface:true };
```

### Step 3: Write physics functions

```javascript
// Nut displacement for one cell
function nutDisplacement(col, row) {
  let vi = (row + col) % 3;
  let weights = VARIANT_WEIGHTS[vi];  // same 3 Willis variants as kelvin
  let phaseA = row * 51.43 * DEG;
  let phaseB = col * 51.43 * DEG;
  let phaseC = (GRID_N - 1 - row) * 51.43 * DEG;

  let dA = soloScrew===0||soloScrew===1 ?
    gearRatio * pitches[0] * Math.sin(motorAngle*MOTOR_FREQS[0] + phaseA) : 0;
  let dB = soloScrew===0||soloScrew===2 ?
    gearRatio * pitches[1] * Math.sin(motorAngle*MOTOR_FREQS[1] + phaseB) : 0;
  let dC = soloScrew===0||soloScrew===3 ?
    gearRatio * pitches[2] * Math.sin(motorAngle*MOTOR_FREQS[2] + phaseC) : 0;

  return 40 * (weights[0]*dA + weights[1]*dB + weights[2]*dC) / 2.0;
}

// Self-lock check (display only)
function selfLockAngle(pitch, dia) {
  return Math.atan(pitch / (Math.PI * dia)) * 180 / Math.PI;
}
```

### Step 4: Write Cell View drawing functions

Draw a single M8 mechanism at origin, large scale (SC=4):
- `drawCellScrews()`: 3 vertical cylinders with helical thread (series of small rotated boxes along helix path). Color-coded pink/blue/green. Thread pitch visually matches slider value.
- `drawCellGears()`: 3 gear pairs (small spur gears) at base of each screw connecting to horizontal input shafts.
- `drawCellNut()`: Gold box with 3 cylindrical bores. Position = nutDisplacement(3,3). When cutaway (F): use `clip()` or draw only half the nut.
- `drawCellLabels()`: Text labels using billboard technique (always face camera) — "Screw A (p=1mm)", "Screw B (p=1.5mm)", "Screw C (p=2mm)", "Common Nut".
- When frozen: all screws stop rotating, nut holds position, HUD shows lock icon.

### Step 5: Write Grid View drawing functions

Reuse kelvin's grid architecture:
- `drawGridScrewCells()`: 49 small screw-nut units at grid positions. Simplified: 3 thin cylinders + small gold box per cell.
- `drawGridConnections()`: 3 sets of drive shafts from 3 sides (matching kelvin's cam shaft layout but labeled as "gear drive shafts").
- `drawGridSurface()`: Triangle strip mesh of nut positions, same color mapping as kelvin.
- `drawGridPixelPillars()`: Connecting rods from nut to wave surface.

### Step 6: Write keyboard + UI handlers

```javascript
function keyPressed() {
  if (key === ' ') { frozen = !frozen; return false; }
  if (key === '1') soloScrew = soloScrew===1 ? 0 : 1;
  if (key === '2') soloScrew = soloScrew===2 ? 0 : 2;
  if (key === '3') soloScrew = soloScrew===3 ? 0 : 3;
  if (key === 'f' || key === 'F') showCutaway = !showCutaway;
  if (key === 'v' || key === 'V') viewMode = viewMode==='cell' ? 'grid' : 'cell';
}
```

Wire slider oninput handlers to update `pitches[]`, `gearRatio`, `SPEED_MULT`.
Wire layer toggle buttons. Wire view preset buttons (camera positions).

### Step 7: Write main setup/draw loop

```javascript
function setup() { createCanvas(windowWidth, windowHeight, WEBGL); }

function draw() {
  background(8, 8, 24);
  orbitControl(2, 2, 0.5);
  // Camera setup (same pattern as kelvin)
  // Lighting (same as kelvin)
  if (!frozen) motorAngle += BASE_SPEED * SPEED_MULT;

  if (viewMode === 'cell') {
    drawCellScrews();
    if (layers.gears) drawCellGears();
    if (layers.nut) drawCellNut();
  } else {
    drawGridScrewCells();
    if (layers.connections) drawGridConnections();
    if (layers.surface) drawGridSurface();
  }

  updateHUD();
}
```

### Step 8: Test in browser

Open `gear_screw_3d.html` in Chrome. Verify:
- [ ] Canvas renders dark background with 3D scene
- [ ] Cell view shows 3 colored screws + gold nut
- [ ] Nut moves up/down based on screw rotation
- [ ] SPACE freezes/unfreezes (nut holds position)
- [ ] 1/2/3 solos individual screws
- [ ] F toggles cutaway
- [ ] V toggles cell/grid view
- [ ] Grid view shows 7x7 wave surface
- [ ] Speed slider works
- [ ] Pitch sliders change thread spacing visually
- [ ] FPS stays above 30

---

## Task 2: S17 Ring-as-Slider (`ring_slider_3d.html`)

**Files:**
- Create: `D:\Claude local\3d_design_agent\waffle_grid_planetary\ring_slider_3d.html`

### Step 1: Copy skeleton from gear_screw_3d.html, modify controls

Change title, explainer text, layer toggles to: Sun, Planets, Ring, Carrier, Ghost, Connections, Surface.
Add controls: Sun Teeth slider (20-40), Planet Count toggle (3/4/5), Travel Range slider.
Keyboard: G=ghost, E=explode, L=trace, V=cell/grid.

### Step 2: Write mechanism constants

```javascript
const RING_TEETH = 80;
let sunTeeth = 40;
let planetCount = 3;
const MODULE = 0.773;  // transverse module from Ravigneaux spec
let showGhost = false;
let showExploded = false;
let showTrace = false;
let ringTrail = [];  // for straight-line trace
```

### Step 3: Write Cell View — gear rendering helpers

```javascript
// Simplified spur gear: cylinder + box teeth around perimeter
function drawGear(teeth, module, thickness, color, internal) {
  let pitchR = teeth * module / 2;
  let addendum = module;
  push();
  fill(color[0], color[1], color[2], 180);
  noStroke();
  // Gear body
  cylinder(pitchR - (internal ? addendum : -addendum*0.5), thickness);
  // Teeth
  for (let t = 0; t < teeth; t++) {
    push();
    rotateY(t * TWO_PI / teeth);
    translate(internal ? pitchR - addendum*0.5 : pitchR + addendum*0.5, 0, 0);
    box(addendum, thickness * 0.8, module * 0.4 * Math.PI);
    pop();
  }
  pop();
}
```

### Step 4: Write Cell View — S17 mechanism

- Sun gear at center, gold, rotates at motor speed
- Planet gears (3-5x) orbiting sun on carrier, copper, mesh with ring
- Ring gear: steel-blue, internal teeth, TRANSLATES vertically (not rotates)
- Ring displacement = f(sun_rotation, gear_ratio)
- Carrier plate: dark grey disc
- Guide rails: 2 ghost vertical lines constraining ring
- Ghost overlay (G): translucent red outlines of eliminated parts (rack, pinion, spool, separate slider)
- Exploded view (E): parts spread vertically with spacing
- Straight-line trace (L): red line history showing ring path

### Step 5: Write Grid View

- 49 cells, each a miniature S17 unit
- Ring tops = pixel positions = wave surface
- 3 sun-drive shafts from 3 sides
- Wave surface triangle strip

### Step 6: Wire controls, test

Same pattern as Task 1 Step 8. Verify:
- [ ] Sun rotates, planets orbit and spin, ring translates
- [ ] G shows ghost eliminated parts
- [ ] E explodes view
- [ ] L shows straight-line trace
- [ ] Grid view produces wave surface

---

## Task 3: E3/E6 Nested Eccentric (`nested_eccentric_3d.html`)

**Files:**
- Create: `D:\Claude local\3d_design_agent\waffle_grid_planetary\nested_eccentric_3d.html`

### Step 1: Skeleton + controls

Layer toggles: Inner Ecc, Outer Ecc, Cam Polygon, Follower, Trail, Surface.
Sliders: Polygon Sides (3-8 int), Inner Eccentricity (0-5mm), Outer Eccentricity (0-8mm).
Toggle: Nesting Depth (1/2/3). Keys: T=trail, H=harmonic overlay.

### Step 2: Write nested eccentric math

```javascript
// Position of nth nesting level at time t
function eccentricPos(t, level) {
  // Level 1: inner eccentric orbits shaft center
  let x1 = innerEcc * Math.cos(t);
  let y1 = innerEcc * Math.sin(t);
  if (level === 1 || nestingDepth < 2) return { x: x1, y: y1 };

  // Level 2: outer eccentric orbits inner
  let x2 = x1 + outerEcc * Math.cos(t * 0.618);  // golden sub-harmonic
  let y2 = y1 + outerEcc * Math.sin(t * 0.618);
  if (level === 2 || nestingDepth < 3) return { x: x2, y: y2 };

  // Level 3: cam polygon shapes the contact surface
  let camAngle = t * polygonSides;
  let camR = constantBreadthRadius(camAngle, polygonSides);
  let x3 = x2 + camR * Math.cos(camAngle);
  let y3 = y2 + camR * Math.sin(camAngle);
  return { x: x3, y: y3 };
}

// Constant-breadth cam profile (Reuleaux polygon)
function constantBreadthRadius(angle, sides) {
  // Simplified: radius oscillates with nth harmonic
  let baseR = 15;
  let harmAmp = outerEcc / (sides * sides);
  return baseR + harmAmp * Math.cos(sides * angle);
}
```

### Step 3: Write Cell View

- Concentric animated rings (gold inner, copper outer, steel-blue polygon)
- Each ring visibly orbits around the previous
- Constant-breadth polygon drawn as p5.js shape with `beginShape()/vertex()/endShape()`
- Output follower rides on outermost surface
- Epicycloidal trail: array of last 500 positions, drawn as fading line

### Step 4: Write Grid View

- 49 cells with nested eccentrics
- Distribution: center=circle(n=24), ring1=pentagon(5), ring2=triangle(3), corners=square(4)
- Output positions form wave surface
- Color coding by polygon order

### Step 5: Wire controls, test

- [ ] Polygon sides slider changes cam shape in real-time
- [ ] Nesting depth toggle shows 1/2/3 levels
- [ ] T shows epicycloidal trail
- [ ] H shows harmonic content overlay
- [ ] Grid wave surface varies by region

---

## Task 4: Escapement Pulse Wave (`escapement_pulse_3d.html`)

**Files:**
- Create: `D:\Claude local\3d_design_agent\waffle_grid_planetary\escapement_pulse_3d.html`

### Step 1: Skeleton + controls

Layer toggles: Tubes, Slugs, Escapements, Cams, Tick Marks, Surface.
Sliders: Tick Rate (1-20/s), Asymmetry Ratio (1-5), Cycloid Curvature (0-1), Mass (1-10).
Toggles: Gravity on/off, Sound on/off. Keys: S=step one tick.

### Step 2: Write discrete tick physics

```javascript
// Each cell has its own tick state
let cellTicks = [];  // [row][col] = { height, phase, rising, tickCount }

function initCellTicks() {
  for (let r = 0; r < GRID_N; r++) {
    cellTicks[r] = [];
    for (let c = 0; c < GRID_N; c++) {
      let vi = (r + c) % 3;
      cellTicks[r][c] = {
        height: 0,
        phase: (r * 51.43 + c * 37.2) * DEG,
        rising: true,
        tickCount: 0,
        maxHeight: 40 + VARIANT_WEIGHTS[vi][0] * 20
      };
    }
  }
}

function updateTicks(dt) {
  if (frozen) return;
  for (let r = 0; r < GRID_N; r++) {
    for (let c = 0; c < GRID_N; c++) {
      let cell = cellTicks[r][c];
      let camSpeed = BASE_SPEED * SPEED_MULT;
      // Cam drives: 3 weighted sinusoids determine target height
      let target = nutDisplacement(c, r);  // reuse weighted sum

      if (cell.rising) {
        // Slow rise (cam-powered)
        cell.height += camSpeed * 0.5;
        if (cell.height >= target + cell.maxHeight * 0.5) {
          cell.rising = false;  // trigger fall
        }
      } else {
        // Fast fall (gravity or escapement tick)
        let fallSpeed = camSpeed * asymmetryRatio;
        if (gravity) fallSpeed *= 2.0;
        if (cycloidCurve > 0) {
          // Tautochrone: constant fall time regardless of height
          fallSpeed = camSpeed * asymmetryRatio * (1 + cycloidCurve);
        }
        cell.height -= fallSpeed;
        if (cell.height <= target - cell.maxHeight * 0.5) {
          cell.rising = true;
          cell.tickCount++;
          if (soundEnabled) playTick();
        }
      }
    }
  }
}
```

### Step 3: Write Cell View

- Translucent cylinder (glass tube)
- Gold chunky cylinder inside (brass slug) at cell.height
- Escapement anchor: rocking lever at top, drawn as 2 lines + circle
- Escape wheel: small toothed disc
- Cam pusher: eccentric disc + pushrod below tube
- Tick marks: horizontal lines at discrete intervals
- When cycloidCurve > 0: tube drawn as curved path (series of short cylinders along cycloid)

### Step 4: Write Web Audio tick sound

```javascript
let audioCtx;
function playTick() {
  if (!audioCtx) audioCtx = new AudioContext();
  let osc = audioCtx.createOscillator();
  let gain = audioCtx.createGain();
  osc.type = 'sine';
  osc.frequency.value = 2000 + Math.random() * 500;
  gain.gain.setValueAtTime(0.03, audioCtx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.05);
  osc.connect(gain).connect(audioCtx.destination);
  osc.start(); osc.stop(audioCtx.currentTime + 0.05);
}
```

### Step 5: Grid View + test

- 49 glass tubes with slugs
- Wave surface from slug heights
- Asymmetric wave visible (fast crests, slow troughs)
- S key steps one tick when paused

---

## Task 5: Continuously Tunable Worm (`tunable_worm_3d.html`)

**Files:**
- Create: `D:\Claude local\3d_design_agent\waffle_grid_planetary\tunable_worm_3d.html`

### Step 1: Skeleton + controls

Layer toggles: Worms, Wheels, Cones, Belts, Phase, Surface.
Sliders: Cone A/B/C Position (0-1), Worm Lead (1-4mm).
Keys: R=rational snap, I=irrational snap, P=phase highlight.

### Step 2: Write cone pulley ratio math

```javascript
// Cone pulley: ratio varies with belt position (0=narrow end, 1=wide end)
function coneRatio(position) {
  let rMin = 0.3, rMax = 3.0;
  // Logarithmic mapping for perceptually uniform ratio change
  return rMin * Math.pow(rMax/rMin, position);
}

// Rational proximity detector
function nearestRational(ratio, maxDenom) {
  let bestN = 1, bestD = 1, bestErr = Infinity;
  for (let d = 1; d <= maxDenom; d++) {
    let n = Math.round(ratio * d);
    let err = Math.abs(ratio - n/d);
    if (err < bestErr) { bestErr = err; bestN = n; bestD = d; }
  }
  return { n: bestN, d: bestD, error: bestErr };
}

let conePositions = [0.5, 0.5, 0.5];  // default: all 1:1
```

### Step 3: Write Cell View — worm + cone geometry

- Horizontal worm shaft: cylinder with helical groove (series of small torus segments or rotated boxes)
- Worm wheel: large toothed disc meshing vertically with worm
- Cone pulley pair: two opposing truncated cones (`cylinder(rTop, rBottom, height)`) with belt strip at variable position
- Belt: thin orange strip wrapping both cones at current position
- Phase markers: cyan dots along worm thread showing where adjacent cells engage

### Step 4: Write Grid View

- 3 worm shafts along 3 sides (replacing kelvin's cam shafts)
- Worm shafts visibly threaded
- 49 worm wheels at cell positions
- Cone pulleys at motor end of each shaft
- Wave surface morphs as cone positions change
- HUD: ratio readout + rational proximity indicator

### Step 5: Wire controls, test

- [ ] Cone sliders smoothly change speed ratios
- [ ] R key snaps to nearest rational (pattern locks)
- [ ] I key snaps to irrational (pattern dissolves)
- [ ] Phase gradient visible along worm shaft
- [ ] Wave surface responds to ratio changes

---

## Task 6: Lissajous Surface (`lissajous_surface_3d.html`)

**Files:**
- Create: `D:\Claude local\3d_design_agent\waffle_grid_planetary\lissajous_surface_3d.html`

### Step 1: Skeleton + controls

Layer toggles: Trammel A, Trammel B, Sliders, Pixels, Trail, Arrows, Surface.
Sliders: Freq A (0.5-4.0), Freq B (0.5-4.0), Phase Offset (0-360), Amplitude A/B (1-15mm).
Keys: T=trail, A=arrow field. Presets: "1:1", "1:2", "2:3", "1:sqrt(2)".

### Step 2: Write Lissajous math + trammel kinematics

```javascript
let freqA = 1.0, freqB = SQRT2;
let phaseOffset = 0;
let ampA = 8, ampB = 8;
let showTrail = false, showArrows = false;
let trailBuffers = [];  // per-cell trail history

// Trammel: crank at angle theta drives 2 perpendicular sliders
// Slider X = A*cos(theta), Slider Y = A*sin(theta)
// With 2 trammels at different frequencies:
function cellLissajous(col, row, t) {
  let phRow = row * 51.43 * DEG;
  let phCol = col * 51.43 * DEG;
  let x = ampA * Math.sin(TWO_PI * freqA * t + phRow);
  let y = ampB * Math.sin(TWO_PI * freqB * t + phCol + phaseOffset * DEG);
  return { x, y };
}
```

### Step 3: Write Cell View — dual trammel

- Trammel A (pink): rotating crank arm + 2 perpendicular slider tracks (X-direction)
- Trammel B (blue): rotating crank arm + 2 perpendicular slider tracks (Y-direction)
- Slider tracks drawn as thin grey rails
- Pixel sphere at intersection point, gold
- Lissajous trail: fading line history of last 500 positions
- When curve is closed: trail connects back to start (visually satisfying)
- When open: trail fills rectangle over time

### Step 4: Write Grid View — 2D displacement field

Two rendering modes:
1. **Height mode** (default): pixel Y-displacement mapped to vertical position (like kelvin). The X-displacement shown as slight horizontal offset.
2. **Arrow mode** (A key): top-down view, each cell shows a small arrow indicating its 2D displacement vector. Arrow length = magnitude, arrow direction = angle. Creates a vector field visualization.

Wave surface in height mode: triangle strip using Y-component of Lissajous.
Arrow field: 49 small line segments from grid center to displaced position.

### Step 5: Write preset buttons

```javascript
function setPreset(name) {
  if (name === '1:1') { freqA=1; freqB=1; phaseOffset=90; }  // circle
  if (name === '1:2') { freqA=1; freqB=2; phaseOffset=0; }   // figure-8
  if (name === '2:3') { freqA=2; freqB=3; phaseOffset=0; }   // pretzel
  if (name === 'sqrt2') { freqA=1; freqB=SQRT2; phaseOffset=45; }  // fill
  updateSliders();
}
```

### Step 6: Wire controls, test

- [ ] Frequency sliders change Lissajous shape in real-time
- [ ] T shows trail (closed curves connect, open curves fill)
- [ ] A switches to arrow field view
- [ ] Presets snap to named ratios
- [ ] HUD shows fA:fB ratio and closed/open status
- [ ] Grid view shows coherent wave pattern

---

## Parallelization Strategy

**Batch 1 (parallel):** Tasks 1, 2, 3 — independent files, no shared state
**Batch 2 (parallel):** Tasks 4, 5, 6 — independent files, no shared state

Each agent receives:
- This implementation plan (the relevant task section)
- The design doc
- Full text of `kelvin_linkage_3d.html` as style reference
- Relevant section of `REULEAUX_DECOMPOSITION_SYNTHESIS.md`

---

## Verification Checklist (per file)

After each file is written, open in Chrome and verify:
- [ ] Page loads without console errors
- [ ] Dark background renders, orbit control works
- [ ] Cell view shows mechanism with all parts animated
- [ ] Grid view shows 7x7 wave surface
- [ ] Cell/Grid toggle works (V key or button)
- [ ] All keyboard shortcuts work
- [ ] All sliders update in real-time
- [ ] HUD updates with live values
- [ ] FPS > 30 on GTX 1650
- [ ] Layer toggles show/hide components
- [ ] View presets move camera correctly
