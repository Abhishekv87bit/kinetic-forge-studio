# Kinetic Discovery Suite — Complete Design Document

> Date: 2026-02-26
> Purpose: 27 randomized discovery experiments for finding a kinetic sculpture niche
> Approach: Each experiment = standalone HTML (p5.js), atlas + single mode, randomize + evolve
> Build philosophy: Don't rush. Be accurate. Check orientations.

---

## SHARED ARCHITECTURE

Every experiment follows the same template:

### File Structure
```
exp_<name>_2d.html  (or _3d.html for 3D experiments)
├── HTML: sidebar (280px left) + canvas container (flex: 1)
├── CSS: engineering-drawing aesthetic (cream #f5f3ee, serif fonts, 0.5px borders)
├── JS:  p5.js instance mode sketch
│   ├── Core solver (mechanism-specific math)
│   ├── Config generator (randomize / mutate / evolve)
│   ├── Atlas mode renderer (4x4 grid, 16 configs)
│   ├── Single mode renderer (full detail, one config)
│   ├── Beauty scorer (curve complexity metric)
│   └── UI wiring (sliders, buttons, presets)
```

### Shared UI Pattern
- **Left sidebar** (280px): controls, layer list, action buttons
- **Main canvas**: atlas grid or single detail view
- **Bottom info bar**: parameter readout, Roman numeral labels
- **Top-right HUD**: live stats (FPS, score, trail count)

### Shared Controls
Every experiment has:
- **Randomize All** — generate 16 new random configs for atlas
- **Mutate** — perturb current configs ±10-15%
- **Find Beautiful** — generate 200+ random, keep highest scoring
- **Speed** slider — animation speed
- **Trail Length** slider — how many points to accumulate
- **Atlas / Single** toggle — click cell in atlas to inspect

### Coordinate Conventions

**2D experiments (p5.js 2D mode):**
- Mathematical convention internally: X-right, Y-up
- Rendering: flip Y for screen (`y_screen = canvas_center_y - y_math`)
- All mechanism solvers work in math coords, rendering layer flips
- Gravity (when applicable): -Y in math coords (downward on screen)

**3D experiments (p5.js WEBGL mode):**
- p5.js WEBGL: Y+ = screen-down by default
- Camera up vector: (0, -1, 0) so -Y = visual up
- Gravity: +Y direction (screen-down = physical down)
- All positions computed in WEBGL coords directly

### Beauty Scoring (shared algorithm)
```javascript
function scoreCurve(pts) {
  // 1. Bounding box area (reject degenerate: area < 1)
  // 2. Curvature sign changes (inflection points) — weight: 2
  // 3. Self-intersection count (sampled) — weight: 5
  // 4. Perimeter / sqrt(area) ratio (complexity) — weight: 3
  // 5. Aspect ratio bonus (>0.3: +10, penalize thin lines)
  // 6. Closure bonus (if curve nearly closes: +15)
  // Total = sum of weighted components
}
```

### Performance Budget
- Target: 30+ FPS in atlas mode (16 cells), 60 FPS in single mode
- Max trail points per cell in atlas: 500
- Max trail points in single: 5000
- Sphere detail (3D): 8 segments max in atlas, 12 in single
- Line drawing: batched by color segment (no per-vertex stroke in WEBGL)

---

## WAVE 1: Core Discovery Engines (Build First)

### Experiment 1: Linkage Lab
**File:** `exp_linkage_lab_2d.html`
**What:** Random N-bar planar mechanisms via dyad composition

**Core Algorithm — Dyad Composition:**
```
1. Ground link: J0=(0,0), J1=(groundLen, 0) — both fixed
2. Crank: bar from J0, length=crankLen, endpoint J2 rotates at motor speed
   J2.x = crankLen * cos(theta)
   J2.y = crankLen * sin(theta)
3. For each dyad d = 1..D:
   a. Pick connectA, connectB from existing solved joints (connectA != connectB)
   b. Random bar lengths: L1, L2
   c. Solve new joint Jnew by circle-circle intersection:
      |Jnew - connectA| = L1
      |Jnew - connectB| = L2
   d. Two solutions exist. Pick by branch tracking (closest to previous frame).
      At t=0, pick solution with positive Y (arbitrary convention).
```

**Circle-Circle Intersection Solver:**
```javascript
function circleCircleIntersect(cx1, cy1, r1, cx2, cy2, r2) {
  let dx = cx2 - cx1, dy = cy2 - cy1;
  let d = Math.sqrt(dx*dx + dy*dy);
  if (d > r1 + r2 - 0.001 || d < Math.abs(r1 - r2) + 0.001) return null; // no solution
  let a = (r1*r1 - r2*r2 + d*d) / (2*d);
  let h = Math.sqrt(Math.max(0, r1*r1 - a*a));
  let mx = cx1 + a * dx/d;
  let my = cy1 + a * dy/d;
  return {
    sol1: { x: mx + h * dy/d, y: my - h * dx/d },
    sol2: { x: mx - h * dy/d, y: my + h * dx/d }
  };
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numDyads | int | 1-9 | = 4 to 20 links |
| groundLen | float | 80-120 | base ground link |
| crankLen | float | 15-60 | must be < groundLen |
| dyad[i].connectA | jointIdx | any solved joint | topology randomization |
| dyad[i].connectB | jointIdx | any solved joint, != connectA | topology randomization |
| dyad[i].L1 | float | 20-120 | bar 1 length |
| dyad[i].L2 | float | 20-120 | bar 2 length |
| outputJoint | jointIdx | any non-ground joint | which joint to trace |

**Validation:**
- After generating, test-solve at 72 angles (every 5 deg)
- If ANY angle fails (no circle intersection), discard and regenerate
- Max 50 retries per config, then fall back to known-good 4-bar

**Mutation:**
- Keep topology (same connectA, connectB for each dyad)
- Perturb each bar length by gaussian noise, sigma = 8% of current value
- Re-validate after mutation

**Walker Scoring (alternate fitness):**
- Track lowest joint's Y trajectory over one crank revolution
- Score: flatness of "stance" phase (min Y region), step height, smoothness

**Atlas:** 4x4 grid, 16 random mechanisms
**Controls:** dyad count (1-9), randomize, mutate, find beautiful, output joint selector

---

### Experiment 2: Cam Profile Synthesizer
**File:** `exp_cam_synth_2d.html`
**What:** Random cam profiles from Fourier coefficients, follower traces output motion

**Core Algorithm — Fourier Cam Profile:**
```javascript
// Cam radius as function of angle theta:
function camRadius(theta, baseR, harmonics) {
  let r = baseR;
  for (let k = 0; k < harmonics.length; k++) {
    let h = harmonics[k]; // { amplitude, phase }
    r += h.amplitude * Math.cos((k+1) * theta + h.phase);
  }
  return Math.max(r, baseR * 0.2); // clamp to prevent self-intersection
}

// Cam profile as closed curve:
function camProfile(baseR, harmonics, steps) {
  let pts = [];
  for (let i = 0; i < steps; i++) {
    let theta = (i / steps) * Math.PI * 2;
    let r = camRadius(theta, baseR, harmonics);
    pts.push({ x: r * Math.cos(theta), y: r * Math.sin(theta) });
  }
  return pts;
}
```

**Follower Types:**
1. **Flat follower** (translating): rides on cam surface, displacement = cam radius at contact
2. **Roller follower**: circle rolling on cam surface, offset by roller radius
3. **Oscillating arm**: pivoted arm, cam pushes arm, traces arc

**Follower Motion Equation (flat, translating along Y):**
```
follower_y(theta) = camRadius(theta, baseR, harmonics) - baseR
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numHarmonics | int | 2-16 | complexity of cam profile |
| harmonics[k].amplitude | float | 0-baseR*0.3 | decreasing with k |
| harmonics[k].phase | float | 0-2*PI | random |
| baseRadius | float | 40-80 | base circle radius |
| followerType | enum | flat/roller/oscillating | |
| rotationSpeed | float | 0.5-3.0 | cam RPM multiplier |

**Cam Validity Check:**
- Cam profile must not self-intersect: check that radius > 0 at all angles
- Pressure angle (angle between follower direction and cam normal) should stay < 45 deg
- If invalid, reduce harmonic amplitudes by 50% and retry

**Atlas:** 4x4 grid, each cell shows cam shape + animated follower + output curve
**Beauty Score:** applied to the follower displacement curve y(theta)

---

### Experiment 3: Non-Circular Gear Pair Explorer
**File:** `exp_noncircular_gears_2d.html`
**What:** Non-circular gear profiles that convert constant-speed rotation into variable-speed output

**Core Math — Non-Circular Gear Pair:**
```
Input gear: pitch curve r1(theta1)
Output gear: pitch curve r2(theta2)

Constraint: r1(theta1) + r2(theta2) = C (center distance, constant)
Gear ratio: omega2/omega1 = r1(theta1) / r2(theta2)

If r1(theta1) is defined by Fourier series:
  r1(theta) = R_base + sum_{k=1}^{N} a_k * cos(k*theta + phi_k)

Then: r2(theta2) = C - r1(theta1)
And: d(theta2)/d(theta1) = r1(theta1) / r2(theta2)

To get theta2 from theta1: numerically integrate the ODE above.
```

**Output Speed Profile:**
```javascript
function outputSpeed(theta1, r1Func, centerDist) {
  let r1 = r1Func(theta1);
  let r2 = centerDist - r1;
  if (r2 < 1) return null; // invalid
  return r1 / r2; // instantaneous speed ratio
}
```

**Chaining 2-3 Gears:**
- Gear pair 1: input shaft → intermediate shaft (speed ratio varies)
- Gear pair 2: intermediate → output (another varying ratio)
- Compound ratio = product of instantaneous ratios → very complex speed profile

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numGearPairs | int | 1-3 | chained gear stages |
| harmonics[k].amplitude | float | 0-R_base*0.25 | gear eccentricity |
| harmonics[k].phase | float | 0-2*PI | |
| numHarmonics | int | 1-6 | per gear |
| centerDistance | float | computed | R1_max + R2_min + clearance |

**Gear Validity:**
- r1(theta) > 0 for all theta (no self-intersection)
- r2(theta) = C - r1(theta) > 0 for all theta (output gear exists)
- Smooth profile: no sharp cusps (limit harmonic amplitude relative to base radius)

**Atlas:** 4x4 grid, each cell shows gear pair animated + output speed profile graph
**Single mode:** full gear mesh animation + speed ratio vs time plot

---

### Experiment 4: Spirograph Deep Explorer
**File:** `exp_spirograph_deep_2d.html`
**What:** N nested rolling circles (up to 8) with random radii and rolling directions

**Core Math — Nested Epicycles:**
```
For N circles, each defined by:
  R[i] = radius
  dir[i] = +1 (outside/epicycloid) or -1 (inside/hypocycloid)
  speed[i] = angular speed multiplier (derived from radius ratio)

Point position at time t:
  x(t) = sum_{i=0}^{N-1} R[i] * cos(omega[i] * t + phase[i])
  y(t) = sum_{i=0}^{N-1} R[i] * sin(omega[i] * t + phase[i])

where omega[i] = product of gear ratios from outermost to i-th circle

For true rolling (no slip):
  omega[i] = dir[i] * (R[i-1] / R[i]) * omega[i-1]
  with omega[0] = 1.0 (outermost circle speed)
```

**Key difference from harmonograph:** Spirograph uses GEAR RATIOS (rational numbers → closed curves). Harmonograph uses frequency ratios (can be irrational → open curves).

**Integer vs Irrational modes:**
- Integer radii mode: R[i] chosen from {10, 15, 20, 25, 30, ...} → curves close after finite rotations
- Irrational mode: R[i] = random float → curves never close (fill a region)
- Near-integer mode: R[i] = integer ± small epsilon → curves almost close (most beautiful)

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numCircles | int | 2-8 | nesting depth |
| R[i] | float | 5-80 | radius, decreasing with i |
| dir[i] | {-1, +1} | random | inside or outside rolling |
| penOffset | float | 0-R[N-1] | pen distance from last center |
| penAngle | float | 0-2*PI | pen position angle on last circle |

**Atlas:** 4x4 grid, each cell traces the compound spirograph curve
**Controls:** num circles, integer/irrational/near-integer mode, pen position

---

### Experiment 5: Walker Gait Lab
**File:** `exp_walker_gait_2d.html`
**What:** Same dyad-composition engine as Linkage Lab, but scored for WALKING quality

**Uses:** Linkage Lab solver (Experiment 1) — exact same dyad composition + circle-circle intersection

**Walking Fitness Function:**
```javascript
function walkScore(footTrajectory) {
  // footTrajectory = array of {x, y} over one crank revolution

  // 1. Stance flatness: measure variance of Y during lowest 40% of trajectory
  let yVals = footTrajectory.map(p => p.y);
  let yMin = Math.min(...yVals);
  let stanceThreshold = yMin + (Math.max(...yVals) - yMin) * 0.15;
  let stancePts = footTrajectory.filter(p => p.y < stanceThreshold);
  let stanceYVar = variance(stancePts.map(p => p.y));
  let flatness = 1 / (1 + stanceYVar); // higher = flatter stance

  // 2. Step height: max Y - min Y (want sufficient clearance)
  let stepHeight = Math.max(...yVals) - yMin;
  let heightScore = Math.min(stepHeight / 40, 1); // normalize

  // 3. Forward progress: net X displacement during stance phase
  let stanceXs = stancePts.map(p => p.x);
  let forwardProgress = Math.max(...stanceXs) - Math.min(...stanceXs);

  // 4. Smoothness: sum of acceleration magnitudes (lower = smoother)
  let accel = 0;
  for (let i = 2; i < footTrajectory.length; i++) {
    let ax = footTrajectory[i].x - 2*footTrajectory[i-1].x + footTrajectory[i-2].x;
    let ay = footTrajectory[i].y - 2*footTrajectory[i-1].y + footTrajectory[i-2].y;
    accel += Math.sqrt(ax*ax + ay*ay);
  }
  let smoothness = 1 / (1 + accel / footTrajectory.length);

  return flatness * 30 + heightScore * 20 + forwardProgress * 0.5 + smoothness * 20;
}
```

**Atlas:** 4x4 grid, each cell shows leg mechanism + "ground" line + foot trajectory
**Visual:** ground = horizontal line at Y_min, foot path colored by stance (green) vs swing (red)

---

## WAVE 2: Shape & Curve Explorers

### Experiment 6: Superformula Morpher
**File:** `exp_superformula_2d.html`
**What:** Gielis superformula — 6 parameters generate any natural shape

**Core Math:**
```
r(theta) = [ |cos(m1*theta/4)/a|^n2 + |sin(m2*theta/4)/b|^n3 ]^(-1/n1)

Parameters:
  m1, m2: symmetry (integer = symmetric, float = asymmetric)
  n1: overall shape power
  n2, n3: shape detail powers
  a, b: stretch factors (usually a=b=1)
```

**Shape examples by parameter:**
- m=4, n1=n2=n3=2, a=b=1 → circle
- m=4, n1=2, n2=n3=100 → square (rounded)
- m=6, n1=1, n2=n3=1 → hexagon
- m=5, n1=0.3, n2=n3=0.3 → starfish
- m=3, n1=0.5, n2=0.5, n3=0.5 → triangle
- m=0, n1=1, n2=1, n3=1 → circle (degenerate)

**Animation modes:**
1. **Static morph:** sliders control all 6 params, shape updates live
2. **Breathing:** params oscillate sinusoidally with different speeds → shape morphs
3. **As cam:** use current shape as cam profile → show follower motion
4. **Compound:** two superformula shapes nested (inner shape rides outer)

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| m1, m2 | float | 0-12 | symmetry order |
| n1 | float | 0.1-5.0 | shape power |
| n2, n3 | float | 0.1-5.0 | detail powers |
| a, b | float | 0.5-2.0 | stretch (usually 1) |

**Atlas:** 4x4 grid, each cell shows one random superformula shape + animation
**Scoring:** perimeter complexity + symmetry breaking + aspect ratio

---

### Experiment 7: Rose Curve / Polar Explorer
**File:** `exp_polar_curves_2d.html`
**What:** Random polar equations with multiple terms

**Core Math:**
```
r(theta) = sum_{k=1}^{N} A[k] * func[k](freq[k] * theta + phase[k])

where func[k] is one of: cos, sin, |cos|, |sin|, sawtooth, triangle
and N = number of terms (2-8)
```

**Notable curve families:**
- Rose: r = cos(n*theta) — petals
- Spirals: r = a + b*theta — Archimedean
- Lemniscate: r^2 = cos(2*theta) — figure-8
- Cardioid: r = 1 + cos(theta) — heart
- Limacon: r = a + b*cos(theta) — looped heart

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numTerms | int | 1-6 | complexity |
| A[k] | float | 0.1-1.0 | amplitude per term |
| freq[k] | float | 0.5-8.0 | frequency per term |
| phase[k] | float | 0-2*PI | phase per term |
| func[k] | enum | cos/sin/abs_cos/abs_sin | function type |

**Atlas:** 4x4 grid, each cell traces one polar curve, animated pen traveling along it
**Unique feature:** "Morph" mode — continuously interpolate between two random configs

---

### Experiment 8: Math Function Drivers
**File:** `exp_math_drivers_2d.html`
**What:** Strange mathematical functions driving X and Y of a tracer point

**Function Library:**
```javascript
const FUNCTIONS = {
  weierstrass: (t, a, b, N) => {
    // Continuous but nowhere differentiable
    let sum = 0;
    for (let n = 0; n < N; n++) sum += Math.pow(a, n) * Math.cos(Math.pow(b, n) * Math.PI * t);
    return sum;
  },

  zetaCritical: (t, N) => {
    // Riemann zeta on critical line: zeta(0.5 + it)
    // Approximation using Dirichlet series
    let re = 0, im = 0;
    for (let n = 1; n <= N; n++) {
      let logn = Math.log(n);
      re += Math.cos(t * logn) / Math.sqrt(n);
      im -= Math.sin(t * logn) / Math.sqrt(n);
    }
    return { x: re, y: im };
  },

  mandelbrotBoundary: (t, maxIter) => {
    // Trace the boundary of Mandelbrot set
    // Use boundary scanning: c = 2*exp(i*t), iterate until escape
    let angle = t * Math.PI * 2;
    let cr = 0, ci = 0;
    // Binary search for boundary point along ray at angle
    let rMin = 0, rMax = 2;
    for (let i = 0; i < 20; i++) {
      let r = (rMin + rMax) / 2;
      let c_r = r * Math.cos(angle), c_i = r * Math.sin(angle);
      if (escapes(c_r, c_i, maxIter)) rMax = r; else rMin = r;
    }
    let r = (rMin + rMax) / 2;
    return { x: r * Math.cos(angle), y: r * Math.sin(angle) };
  },

  logisticBifurcation: (r, x0, N) => {
    // Iterate x_{n+1} = r * x_n * (1 - x_n)
    let x = x0;
    for (let i = 0; i < N; i++) x = r * x * (1 - x);
    return x;
  },

  collatzPath: (n) => {
    // 3n+1 sequence: generates unpredictable integer paths
    let path = [n];
    while (n > 1 && path.length < 500) {
      n = (n % 2 === 0) ? n / 2 : 3 * n + 1;
      path.push(n);
    }
    return path;
  }
};
```

**Driving modes:**
1. **X-Y split:** one function drives X, another drives Y
2. **Parametric:** function returns {x, y} directly (zeta, mandelbrot)
3. **Sequential:** function generates a sequence, plot as path

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| funcX | enum | weierstrass/zeta/logistic/... | X driver |
| funcY | enum | weierstrass/zeta/logistic/... | Y driver |
| params per function | float[] | varies | function-specific |
| timeScale | float | 0.1-10 | speed through function |

**Atlas:** 4x4 grid, each cell uses different function combo + params

---

### Experiment 9: Straight-Line Mechanism Sweep
**File:** `exp_straight_line_2d.html`
**What:** Known straight-line linkages with perturbed link lengths

**Mechanism Types (each is a specific linkage topology):**
1. **Peaucellier-Lipkin:** 7 bars, exact straight line
   - Links: OA=OB=L1, AC=BC=L2, CP=DP=L3, CD=L4
   - Constraint: L1^2 = L2^2 * L4 (for exact straight line)

2. **Hart's Inversor:** 5 bars, exact straight line
   - Cross-linkage, anti-parallelogram

3. **Watt's linkage:** 5 bars, approximate straight line
   - Nearly straight at midpoint of coupler

4. **Chebyshev linkage:** 4 bars, approximate straight line
   - Specific ratios: ground=2, crank=2.5, coupler=5, rocker=2.5

5. **Hoecken linkage:** 4 bars, approximate straight line
   - Different ratios from Chebyshev

6. **Sarrus linkage:** 3D! 6 bars, exact straight line in 3D (only 3D experiment in this group)

**Perturbation approach:**
```javascript
function perturbLinkage(idealLengths, sigma) {
  return idealLengths.map(L => L * (1 + (Math.random() - 0.5) * 2 * sigma));
}
// sigma = 0: exact straight line
// sigma = 0.05: slight wobble (often beautiful)
// sigma = 0.2: significant deviation (organic curves)
// sigma = 0.5: barely recognizable
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| mechanismType | enum | peaucellier/hart/watt/chebyshev/hoecken | |
| perturbSigma | float | 0-0.5 | how far from ideal |
| whichLinks | bitmask | any subset | which links to perturb |

**Atlas:** rows = mechanism types, columns = increasing perturbation (0, 0.05, 0.1, 0.2)
**Unique feature:** shows "straightness score" — deviation from perfect line

---

## WAVE 3: Network & Grid Systems

### Experiment 10: Coupled Oscillator Network
**File:** `exp_coupled_oscillators_2d.html`
**What:** N oscillators with random coupling topology, discover synchronization

**Core Algorithm — Kuramoto Model (extended):**
```javascript
// Each oscillator i has:
//   theta[i] = phase angle
//   omega[i] = natural frequency
//   K[i][j] = coupling strength to oscillator j

// Phase update (Euler):
for (let i = 0; i < N; i++) {
  let dtheta = omega[i];
  for (let j = 0; j < N; j++) {
    if (K[i][j] !== 0) {
      dtheta += K[i][j] * Math.sin(theta[j] - theta[i]);
    }
  }
  theta[i] += dtheta * dt;
}

// Visualization: each oscillator = dot on a circle
// Phase = angle position on circle
// Synchronized = all dots cluster together
// Desynchronized = dots spread around circle
```

**Coupling Topologies (randomized):**
1. **Ring:** each oscillator coupled to 2 nearest neighbors
2. **Star:** one central hub coupled to all others
3. **Random graph:** each pair coupled with probability p
4. **Small-world:** ring + random long-range shortcuts
5. **Scale-free:** preferential attachment (hubs emerge)

**Order Parameter (Kuramoto):**
```
R = |1/N * sum_i exp(i * theta[i])|
R = 0: completely desynchronized
R = 1: perfectly synchronized
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| N | int | 5-50 | number of oscillators |
| topology | enum | ring/star/random/small-world/scale-free | |
| omega[i] | float | 0.5-2.0 | natural frequency (gaussian distributed) |
| K_base | float | 0-2.0 | base coupling strength |
| p_connect | float | 0.1-0.8 | connection probability (for random graph) |

**Atlas:** 4x4 grid, each cell shows oscillator dots on a circle + order parameter bar
**Discovery:** which topologies sync? which create traveling waves? which form clusters?

---

### Experiment 11: Kinematic Tile Grid
**File:** `exp_kinematic_tiles_2d.html`
**What:** Random unit-cell mechanisms tiled in NxN grid, motion propagates

**Core Concept:**
```
1. Define a unit cell: a 4-bar linkage fitting in a square tile
2. Tile MxN grid: neighboring tiles share boundary joints
3. Motor drives one tile's crank
4. Motion propagates through shared joints to neighbors
5. Edge tiles have their boundary joints fixed to ground
```

**Unit Cell Design:**
```
Each tile is a square of size S.
Ground link along bottom edge: (0,0) to (S,0)
Crank at left-bottom corner.
Two boundary joints on each edge (top, right) that connect to neighbors.
```

**Shared Joint Rule:**
- Tile(row, col)'s right boundary joint = Tile(row, col+1)'s left boundary joint
- Tile(row, col)'s top boundary joint = Tile(row-1, col)'s bottom boundary joint

**Solver:** Iterative constraint relaxation
```javascript
// Can't solve analytically because shared joints create loops
// Use iterative projection:
for (let iter = 0; iter < 20; iter++) {
  for (each bar in mechanism) {
    // Project endpoints to satisfy length constraint
    // Average correction between both endpoints
  }
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| gridSize | int | 2x2 to 6x6 | number of tiles |
| cellBarLengths | float[] | varies | different per tile or uniform |
| cellTopology | enum | standard/diagonal/cross | linkage arrangement within tile |
| motorPosition | {row, col} | any tile | which tile is driven |

**Atlas:** each cell in atlas = a different unit cell design, shown as full grid
**Discovery:** which cell designs create interesting wave propagation?

---

### Experiment 12: Moire Pattern Animator
**File:** `exp_moire_2d.html`
**What:** Two overlapping patterns with relative motion create illusion of movement

**Pattern Types:**
1. **Parallel lines:** spacing S, angle A
2. **Concentric circles:** center (cx, cy), spacing S
3. **Radial lines:** center, N lines
4. **Grid:** square or hexagonal, spacing S
5. **Spiral:** Archimedean, spacing S, arms N

**Moire Formation:**
```javascript
// Draw pattern 1 (static or slow-rotating)
// Draw pattern 2 (offset and/or rotating at different speed)
// The visual interference creates apparent motion

function drawPattern(type, params, time) {
  switch(type) {
    case 'lines':
      let angle = params.angle + params.rotSpeed * time;
      for (let i = -50; i < 50; i++) {
        let offset = i * params.spacing + params.transSpeed * time;
        // Draw line at angle, offset from center
        let x0 = offset * Math.cos(angle + PI/2);
        let y0 = offset * Math.sin(angle + PI/2);
        p.line(x0 - 1000*Math.cos(angle), y0 - 1000*Math.sin(angle),
               x0 + 1000*Math.cos(angle), y0 + 1000*Math.sin(angle));
      }
      break;
    case 'circles':
      for (let r = params.spacing; r < 500; r += params.spacing) {
        p.ellipse(params.cx + params.driftX * time,
                  params.cy + params.driftY * time, r*2, r*2);
      }
      break;
    // ... other types
  }
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| pattern1Type | enum | lines/circles/radial/grid/spiral | |
| pattern2Type | enum | lines/circles/radial/grid/spiral | |
| spacing1, spacing2 | float | 5-30 | line spacing |
| angle1, angle2 | float | 0-PI | initial angle |
| rotSpeed1, rotSpeed2 | float | -0.5 to 0.5 | rotation speed |
| lineWeight | float | 0.5-3.0 | line thickness |

**Atlas:** 4x4 grid, each cell shows different pattern combination
**Unique feature:** completely mechanism-free — pure optical motion illusion

---

### Experiment 13: Bistable Snap-Through Array
**File:** `exp_bistable_array_2d.html`
**What:** N bistable elements connected in network, trigger cascade

**Core Physics — Bistable Element:**
```
Each element has:
  state: 0 (flat) or 1 (snapped)
  energy barrier: E_b (force needed to snap)
  coupling to neighbors: K_c (how much snapping pushes neighbors)

Energy landscape (simplified):
  U(x) = -a*x^2/2 + b*x^4/4  (double-well potential)
  Two stable states at x = ±sqrt(a/b)
  Barrier height = a^2/(4b)

When element i snaps (state 0→1):
  It exerts force F = K_c on each connected neighbor
  If F > E_b for neighbor j: neighbor j also snaps (cascade!)
```

**Simulation:**
```javascript
function step(elements, connections) {
  let toSnap = [];
  for (let i = 0; i < elements.length; i++) {
    if (elements[i].state === 1) continue; // already snapped
    let totalForce = elements[i].externalForce;
    for (let j of connections[i]) {
      if (elements[j].state === 1) {
        totalForce += elements[j].coupling;
      }
    }
    if (totalForce > elements[i].barrier) {
      toSnap.push(i);
    }
  }
  for (let i of toSnap) elements[i].state = 1;
  return toSnap.length; // number that snapped this step
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| N | int | 10-50 | number of elements |
| topology | enum | line/ring/grid/random | how elements connect |
| barrier[i] | float | 0.5-2.0 | snap threshold per element |
| coupling[i] | float | 0.3-1.5 | force transmitted to neighbors |
| triggerPoint | int | index | which element to trigger first |

**Atlas:** 4x4 grid, each cell shows cascade propagation as time-lapse
**Discovery:** which topologies create full cascade vs partial? wave-like vs explosive?

---

## WAVE 4: Complex Mechanism Randomizers

### Experiment 14: Gear Train Randomizer
**File:** `exp_gear_train_2d.html`
**What:** N gears (3-12) with random tooth counts in random arrangement

**Gear Types:**
1. **Spur pair:** two meshing gears, ratio = teeth_A / teeth_B
2. **Compound:** two gears on same shaft (speed locked, different radii)
3. **Idler:** reverses direction without changing ratio
4. **Planetary stage:** sun + planet + ring (compound ratio)

**Train Topology:**
```javascript
// A gear train is a directed graph:
// Nodes = shafts (each with 1+ gears)
// Edges = gear meshes (with ratio)
//
// Generate random train:
function randomGearTrain(numShafts) {
  let shafts = [];
  for (let i = 0; i < numShafts; i++) {
    shafts.push({
      gears: [{ teeth: randInt(12, 60) }],
      x: random position,
      y: random position
    });
  }
  // Connect shafts via gear meshes
  // Ensure connected graph (spanning tree + random extra edges)
  let meshes = [];
  // ... minimum spanning tree to ensure connectivity
  // ... then add 0-3 extra meshes for compound ratios
  return { shafts, meshes };
}
```

**Output:** Track angular velocity of output shaft over time as input rotates at constant speed

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numShafts | int | 3-8 | number of independent shafts |
| teeth[i] | int | 12-72 | tooth count per gear |
| topology | random graph | connected | how shafts mesh |
| compound | bool per shaft | 50% chance | two gears on same shaft? |
| hasPlanetary | bool | 20% chance | include one planetary stage? |

**Atlas:** 4x4 grid, each cell shows gear train schematic + output speed graph
**Unique visual:** gears actually rotate with correct tooth meshing

---

### Experiment 15: Automata Figure Compositor
**File:** `exp_automata_figure_2d.html`
**What:** Stick figure with random mechanism per joint, one motor drives all

**Figure Anatomy:**
```
             HEAD (bob on neck joint)
              |
         NECK (pivot)
        /    |    \
  L_SHOULDER  |  R_SHOULDER
    |     TORSO     |
  L_ELBOW    |   R_ELBOW
    |        |      |
  L_HAND   HIP   R_HAND
          /    \
     L_HIP    R_HIP
       |        |
     L_KNEE   R_KNEE
       |        |
     L_FOOT   R_FOOT
```

**Each joint driven by independent four-bar linkage:**
```javascript
// For joint j:
//   fourBar[j] = { a, b, c, d, cpx, cpy }
//   speedRatio[j] = how fast this joint's crank rotates relative to master
//   amplitude[j] = scaling factor for output angle
//
// Joint angle at time t:
//   theta[j] = solve fourBar at angle (masterAngle * speedRatio[j])
//   Apply as rotation of child limb relative to parent
```

**Forward Kinematics (limb chain):**
```javascript
function computeLimbPositions(joints, fourBars, masterAngle) {
  // Start from torso (fixed at center)
  // For each limb chain (e.g., torso → shoulder → elbow → hand):
  //   accumulate rotations down the chain
  //   each joint adds its four-bar output angle
  let torso = { x: 0, y: 0 };
  let shoulderAngle = solveFourBarOutput(fourBars.shoulder, masterAngle * speeds.shoulder);
  let shoulder = {
    x: torso.x + UPPER_ARM * Math.cos(shoulderAngle),
    y: torso.y + UPPER_ARM * Math.sin(shoulderAngle)
  };
  let elbowAngle = shoulderAngle + solveFourBarOutput(fourBars.elbow, masterAngle * speeds.elbow);
  // ... etc
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| fourBar per joint | {b,c,d,cpx,cpy} | random valid | each joint independent |
| speedRatio per joint | float | 0.25-4.0 | relative to master |
| amplitude per joint | float | 0.1-1.0 | how much this joint moves |
| limbLengths | float[] | proportional | body proportions |

**Atlas:** 4x4 grid, each cell shows a different stick figure "dancing"
**Scoring:** smoothness + range of motion + symmetry breaking
**Discovery:** some random combos look like dancing, walking, swimming, crawling...

---

### Experiment 16: Multi-Cam Sequencer
**File:** `exp_multicam_sequencer_2d.html`
**What:** N cam profiles on a single shaft, each driving a different follower

**Core concept (Al-Jazari digitized):**
```
Single shaft rotates at constant speed.
N cams (3-8) mounted on the shaft at different angular positions.
Each cam has its own Fourier profile (from Experiment 2).
Each cam drives its own follower.
The N followers create a multi-channel "motion sequence."
```

**Layout:**
```
Side view:
  Shaft =====[CAM1][CAM2][CAM3][CAM4]======
              ↕     ↕     ↕     ↕
             F1    F2    F3    F4    ← followers
```

**Followers can be:**
- All translating (parallel, like piano keys)
- All oscillating (pivoted arms, like bird wings)
- Mixed

**Phase offset between cams:**
```javascript
// Each cam can be rotated on the shaft by phaseOffset degrees
// This creates timing relationships between channels
cam[i].phaseOffset = random(0, 2*PI);
// cam[i] drives follower[i] at angle: masterAngle + cam[i].phaseOffset
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numCams | int | 3-8 | number of channels |
| harmonics per cam | Fourier coeffs | 2-8 harmonics | cam shape |
| phaseOffset per cam | float | 0-2*PI | timing between channels |
| followerType | enum per cam | translate/oscillate | |
| amplitudeScale per cam | float | 0.5-1.5 | output magnitude |

**Atlas:** 4x4 grid, each cell shows shaft + cams + followers moving
**Single mode:** waterfall view — all N follower displacement curves stacked vertically
**Discovery:** which random combos produce rhythmic patterns? musical? organic?

---

### Experiment 17: Differential Mechanism Explorer
**File:** `exp_differential_2d.html`
**What:** Random differential gear assemblies — 2 inputs → 1 output

**Core Math — Bevel Gear Differential:**
```
Standard differential:
  omega_out = (omega_in1 + omega_in2) / 2

Weighted differential (different bevel gear sizes):
  omega_out = (r1 * omega_in1 + r2 * omega_in2) / (r1 + r2)
  where r1, r2 are the bevel gear radii

Compound differential (2 stages):
  Stage 1: mid = (r1a * in1 + r1b * in2) / (r1a + r1b)
  Stage 2: out = (r2a * mid + r2b * in3) / (r2a + r2b)
  (3 inputs! This was our original wave grid challenge)
```

**Visualization:**
- Two input cranks rotating at different speeds (user can drag)
- Output shaft shows resulting speed
- Graph: output speed vs time for various input speed combos

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numStages | int | 1-3 | cascaded differentials |
| gearRatio per stage | float | 0.3-3.0 | r1/r2 per stage |
| input1Speed | float | 0.5-3.0 | speed ratio |
| input2Speed | float | 0.5-3.0 | speed ratio |
| input3Speed | float | 0.5-3.0 | (if 2+ stages) |

**Atlas:** 4x4 grid, each cell shows different differential config
**Discovery:** which gear ratios create interesting output rhythms?

---

### Experiment 18: Escapement Zoo
**File:** `exp_escapement_zoo_2d.html`
**What:** Random escapement geometry → different tick rhythms

**Escapement Types:**
1. **Verge and foliot:** oldest, most organic rhythm
2. **Anchor (recoil):** pendulum-driven, slight backwards motion
3. **Deadbeat:** no recoil, precise ticks
4. **Grasshopper:** Harrison's design, complex arm motion
5. **Co-axial:** modern Omega design

**Core Simulation (anchor escapement):**
```javascript
class Escapement {
  constructor(params) {
    this.pendulumLen = params.L;     // pendulum length
    this.pendulumAngle = 0;          // current angle
    this.pendulumOmega = 0;          // angular velocity
    this.escapeTeeth = params.teeth; // number of teeth
    this.palletAngle = params.pallet; // pallet engagement angle
    this.torque = params.torque;     // driving torque from weight/spring
    this.engaged = true;             // is pallet engaging tooth?
  }

  step(dt) {
    // Pendulum dynamics with impulse from escapement
    let gravity = -9.81 / this.pendulumLen * Math.sin(this.pendulumAngle);
    let escapeTorque = 0;

    if (this.engaged && Math.abs(this.pendulumAngle) < this.palletAngle) {
      // Tooth pushing pallet → gives impulse to pendulum
      escapeTorque = this.torque * Math.sign(this.pendulumOmega);
    }

    let alpha = gravity + escapeTorque - 0.01 * this.pendulumOmega; // with damping
    this.pendulumOmega += alpha * dt;
    this.pendulumAngle += this.pendulumOmega * dt;

    // Check tooth release/engagement
    if (Math.abs(this.pendulumAngle) > this.palletAngle) {
      this.engaged = false; // pallet releases tooth
    }
    // ... tooth advancement logic
  }
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| type | enum | verge/anchor/deadbeat/grasshopper | |
| pendulumLength | float | 50-200 | affects tick rate |
| numTeeth | int | 8-30 | escape wheel teeth |
| palletAngle | float | 2-15 deg | engagement arc |
| driveTorque | float | 0.5-5.0 | energy input |
| damping | float | 0.001-0.05 | friction |

**Atlas:** 4x4 grid, each cell shows escapement animated with tick sound indicator
**Single mode:** detailed view + tick interval graph over time (stability analysis)
**Discovery:** which configs are most stable? which produce interesting rhythmic patterns?

---

### Experiment 19: Pantograph Chain
**File:** `exp_pantograph_chain_2d.html`
**What:** N-level pantographs transforming motion through each stage

**Core Math — Single Pantograph:**
```
Pantograph ratio: k = long_arm / short_arm
Input point P_in → Output point P_out
P_out = pivot + k * (P_in - pivot)

This SCALES and REFLECTS the motion.
k > 1: enlarges. k < 1: shrinks. k < 0: inverts.
```

**Chaining:**
```
Stage 1: input motion → scaled by k1 → intermediate motion
Stage 2: intermediate → scaled by k2 → output motion
...
Net scaling = k1 * k2 * ... * kN

But each stage can also ROTATE the motion:
  Stage rotation = angle between input arm and output arm
  Net rotation = sum of all stage rotations
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numStages | int | 2-5 | chain depth |
| ratio[i] | float | -2.0 to 3.0 | per stage (negative = inverts) |
| rotation[i] | float | -PI/2 to PI/2 | orientation per stage |
| inputMotion | enum | circle/ellipse/square/random | what drives the input |

**Atlas:** 4x4 grid, each cell shows pantograph chain + input curve → output curve
**Discovery:** which combinations create unexpected transformations?

---

## WAVE 5: Physics Simulations

### Experiment 20: 3-Body Gravitational Orrery
**File:** `exp_three_body_2d.html`
**What:** 3 masses with random initial conditions, discover stable vs chaotic orbits

**Core Algorithm — Gravitational N-body (RK4):**
```javascript
function derivatives(bodies) {
  // For each body i, compute acceleration from all others:
  // a_i = sum_j (G * m_j * (r_j - r_i)) / |r_j - r_i|^3

  let accels = [];
  for (let i = 0; i < bodies.length; i++) {
    let ax = 0, ay = 0;
    for (let j = 0; j < bodies.length; j++) {
      if (i === j) continue;
      let dx = bodies[j].x - bodies[i].x;
      let dy = bodies[j].y - bodies[i].y;
      let r2 = dx*dx + dy*dy;
      let r = Math.sqrt(r2);
      let softened_r = Math.max(r, 5); // softening to prevent singularity
      let f = bodies[j].mass / (softened_r * softened_r * softened_r);
      ax += f * dx;
      ay += f * dy;
    }
    accels.push({ ax, ay });
  }
  return accels;
}
```

**Known Stable Solutions (presets):**
- Figure-8 (Chenciner-Montgomery 2000): 3 equal masses on figure-8 path
- Lagrange equilateral: 3 masses at triangle vertices, rotating
- Euler collinear: 3 masses on a line, rotating

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| mass[0..2] | float | 0.5-3.0 | mass ratio |
| pos[i] | {x, y} | -100 to 100 | initial position |
| vel[i] | {vx, vy} | -2 to 2 | initial velocity |

**Atlas:** 4x4 grid, each cell shows 3 bodies with trails
**Scoring:** stability (how long before ejection) + aesthetic complexity of trajectories
**Discovery:** finding stable or quasi-stable orbits is genuinely hard and exciting

---

### Experiment 21: Magnetic Pendulum Basin Explorer
**File:** `exp_magnetic_pendulum_2d.html`
**What:** Pendulum over N magnets, map starting positions to final resting magnet

**Core Physics:**
```javascript
function pendulumStep(pend, magnets, dt) {
  // Forces:
  // 1. Gravity restoring: F_g = -k * position (spring-like for small angle)
  // 2. Magnetic attraction: F_m = sum_j (strength_j / |r - magnet_j|^3) * (magnet_j - r)
  // 3. Damping: F_d = -gamma * velocity

  let fx = -pend.springK * pend.x - pend.damping * pend.vx;
  let fy = -pend.springK * pend.y - pend.damping * pend.vy;

  for (let mag of magnets) {
    let dx = mag.x - pend.x;
    let dy = mag.y - pend.y;
    let r2 = dx*dx + dy*dy;
    let r = Math.sqrt(r2 + mag.height*mag.height); // 3D distance (magnet below pendulum plane)
    let f = mag.strength / (r * r * r);
    fx += f * dx;
    fy += f * dy;
  }

  // RK4 or Verlet integration
  pend.vx += fx * dt;
  pend.vy += fy * dt;
  pend.x += pend.vx * dt;
  pend.y += pend.vy * dt;
}
```

**Basin Mapping Mode:**
```javascript
// Scan grid of starting positions
// For each: simulate until settled, record which magnet it ends at
// Color pixel by final magnet → fractal basin boundary appears
for (let px = 0; px < resolution; px++) {
  for (let py = 0; py < resolution; py++) {
    let x0 = mapRange(px, 0, resolution, -range, range);
    let y0 = mapRange(py, 0, resolution, -range, range);
    let finalMagnet = simulate(x0, y0, magnets);
    pixels[px][py] = magnetColors[finalMagnet];
  }
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numMagnets | int | 3-7 | number of magnets |
| magnet[i].x, .y | float | -50 to 50 | position |
| magnet[i].strength | float | 0.5-3.0 | magnetic strength |
| springK | float | 0.01-0.1 | gravity restoring force |
| damping | float | 0.01-0.1 | friction |

**Atlas:** 4x4 grid, each cell shows basin fractal for different magnet arrangement
**Single mode:** live pendulum simulation + progressive basin rendering
**Discovery:** which magnet arrangements create the most complex fractal boundaries?

---

### Experiment 22: Rattleback Cascade Grid
**File:** `exp_rattleback_cascade_2d.html`
**What:** Grid of rattlebacks with random shapes, trigger reversal cascade

**Core Physics — Rattleback (simplified 2D):**
```
A rattleback reverses spin due to asymmetric mass distribution.
Key parameters:
  I1, I2, I3: principal moments of inertia
  alpha: angle between geometric and inertial axes

Equation of motion (simplified):
  d(omega)/dt = -epsilon * (I1 - I2) * sin(2*alpha) * rock_amplitude

If spin is in the "wrong" direction:
  rocking amplitude grows → spin decays → reverses
```

**Cascade Mechanism:**
```javascript
// When rattleback i reverses, it bumps neighbors
// Bump force proportional to reversal energy
// If neighbor is spinning in "wrong" direction → it also reverses faster
function cascadeStep(grid) {
  for (let i = 0; i < grid.length; i++) {
    if (grid[i].justReversed) {
      for (let j of grid[i].neighbors) {
        grid[j].externalTorque += grid[i].reversalEnergy * coupling;
      }
      grid[i].justReversed = false;
    }
  }
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| gridSize | int | 3x3 to 8x8 | number of rattlebacks |
| asymmetry[i] | float | 0.1-0.5 | how asymmetric (affects reversal strength) |
| coupling | float | 0.1-1.0 | how much reversal energy transfers |
| initialSpin[i] | float | -3 to 3 | initial spin speed and direction |
| triggerPoint | {row, col} | any | which one to perturb first |

**Atlas:** 4x4 grid, each cell shows cascade as color-coded time-lapse
**Visual:** each rattleback = colored dot, CW=blue, CCW=red, reversing=yellow

---

### Experiment 23: Cable/Pulley Network Explorer
**File:** `exp_cable_pulley_2d.html`
**What:** N pulleys randomly positioned, cable threaded through → discover mechanical advantage

**Core Physics:**
```
Cable constraints:
- Cable is inextensible (total length constant)
- Cable wraps around pulleys (tangent contact)
- Free pulleys: cable tension balanced by gravity/spring
- Fixed pulleys: redirect cable without moving

For each pulley i:
  if fixed: position is constant, cable redirects
  if free: position adjusts so net cable tension is balanced
    F_gravity = m_i * g (downward)
    F_cable = 2 * T * cos(wrap_angle/2) (upward, for free pulley)
    Equilibrium: T = m_i * g / (2 * cos(wrap_angle/2))
```

**Cable Routing:**
```javascript
// Cable path: ordered list of pulleys the cable wraps around
// Total cable length = sum of straight segments + arc lengths on pulleys
function cableLength(pulleys, routing) {
  let total = 0;
  for (let i = 0; i < routing.length - 1; i++) {
    let p1 = pulleys[routing[i]];
    let p2 = pulleys[routing[i+1]];
    // Tangent-to-tangent distance between circles
    total += tangentDistance(p1, p2);
    // Plus arc length on p1
    total += p1.radius * wrapAngle(p1, p2, prev);
  }
  return total;
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numPulleys | int | 3-10 | total pulleys |
| numFixed | int | 1 to numPulleys-1 | which are fixed |
| positions[i] | {x, y} | random in canvas | pulley positions |
| radii[i] | float | 5-20 | pulley radius |
| routing | int[] | random permutation | cable threading order |
| inputEnd | which cable end | left or right | which end the user pulls |

**Atlas:** 4x4 grid, each cell shows pulley network + cable + motion arrows
**Interaction:** in single mode, drag input end → see all free pulleys respond
**Discovery:** which routings create leverage? which create motion reversal?

---

## WAVE 6: Advanced Experiments

### Experiment 24: L-System Linkage Generator
**File:** `exp_lsystem_linkage_2d.html`
**What:** Grammar rules generate fractal branching structure → interpret as mechanism

**L-System Grammar:**
```
Alphabet: F (draw forward), + (turn right), - (turn left), [ (push state), ] (pop state)

Example rules:
  Tree: F → F[+F]F[-F]F
  Fern: F → FF-[-F+F+F]+[+F-F-F]
  Dragon: F → F+G, G → F-G
  Hilbert: A → -BF+AFA+FB-, B → +AF-BFB-FA+
```

**Interpretation as mechanism:**
```
F = BAR (rigid link, length L)
+ = JOINT (revolute, turn CW by angle delta)
- = JOINT (revolute, turn CCW by angle delta)
[ = BRANCH (new sub-chain from current joint)
] = END BRANCH (return to branch point)

After N iterations of grammar: structure = bars + joints
Fix root joint to ground, apply motor to first joint
Solve kinematics using iterative constraint projection
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| rule | string | random production rules | 1-3 rules |
| iterations | int | 2-5 | grammar expansion depth |
| angle | float | 15-90 deg | turn angle delta |
| lengthDecay | float | 0.5-0.9 | L shrinks per iteration |
| motorJoint | int | first joint or random | which joint is driven |

**Validity:** After generating, check DOF via Gruebler. If DOF != 1, add/remove bars.
**Atlas:** 4x4 grid, each cell shows different grammar → mechanism → motion

---

### Experiment 25: Creature Evolver
**File:** `exp_creature_evolver_2d.html`
**What:** Genetic algorithm evolves both body (linkage) and drive (motor pattern)

**Genome:**
```javascript
// Each creature's genome encodes:
{
  numDyads: 2-6,           // body complexity
  dyads: [                  // topology + geometry
    { connectA, connectB, L1, L2 },
    ...
  ],
  motorSpeed: 0.5-3.0,     // crank rotation speed
  motorPattern: [           // speed modulation (optional)
    { freq, amplitude, phase },  // sinusoidal speed variation
    ...
  ],
  outputJoint: int          // which joint to track
}
```

**Genetic Operations:**
```javascript
function crossover(parent1, parent2) {
  // Pick random split point in dyad list
  // Take first half from parent1, second half from parent2
  // Fix topology references (connectA/B may reference non-existent joints)
}

function mutate(genome, rate) {
  // With probability rate:
  //   - Change one bar length by ±15%
  //   - Swap one dyad's connection points
  //   - Add or remove a dyad
  //   - Change motor speed ±20%
}
```

**Evolution Loop:**
```javascript
function evolve(population, fitnessFunc) {
  // 1. Score all creatures
  let scored = population.map(g => ({ genome: g, score: fitnessFunc(g) }));
  scored.sort((a, b) => b.score - a.score);

  // 2. Selection: keep top 25%
  let survivors = scored.slice(0, Math.floor(population.length * 0.25));

  // 3. Reproduction: fill rest via crossover + mutation
  let newPop = survivors.map(s => s.genome);
  while (newPop.length < population.length) {
    let p1 = survivors[randInt(0, survivors.length)].genome;
    let p2 = survivors[randInt(0, survivors.length)].genome;
    let child = mutate(crossover(p1, p2), 0.15);
    if (isValid(child)) newPop.push(child);
  }

  return newPop;
}
```

**Fitness Functions (user-selectable):**
1. Curve complexity (beauty score from shared algorithm)
2. Walking quality (from Experiment 5)
3. Maximum reach (how far output joint gets from center)
4. Periodicity (how well the motion repeats)

**Atlas:** 4x4 grid showing top 16 creatures in current generation
**Controls:** generation counter, auto-evolve toggle, fitness selector, "pin" button to protect favorites
**Unique:** watch population evolve in real-time — creatures visibly improve each generation

---

### Experiment 26: Compliant Mechanism Explorer
**File:** `exp_compliant_flex_2d.html`
**What:** Flexible bars that bend, one input → distributed deformation

**Core Physics — Euler-Bernoulli Beam (simplified):**
```
For each beam, discretize into N segments.
Each segment is a short rigid link connected by torsional springs.

Torsional spring moment: M = k_theta * (theta_i - theta_{i-1} - theta_rest)
where k_theta = E * I / segment_length (bending stiffness)
      E = Young's modulus
      I = second moment of area = w * h^3 / 12

Solve for equilibrium: for each joint, sum of moments = 0
This gives a tridiagonal system that can be solved directly.
```

**Simplified simulation approach:**
```javascript
// Each beam = array of N segment endpoints
// Apply force at input point
// Iteratively relax: each segment tries to maintain its rest angle
// with spring resistance proportional to stiffness

function relaxBeams(beams, inputForce, iterations) {
  for (let iter = 0; iter < iterations; iter++) {
    for (let beam of beams) {
      for (let i = 1; i < beam.points.length - 1; i++) {
        // Compute bending moment at joint i
        let angle_prev = angleBetween(beam.points[i-1], beam.points[i]);
        let angle_next = angleBetween(beam.points[i], beam.points[i+1]);
        let bend = angle_next - angle_prev - beam.restAngle[i];

        // Apply restoring torque
        let correction = beam.stiffness * bend * 0.1; // damped
        // Rotate downstream segment by correction
        rotateChainFrom(beam, i, correction);
      }
    }
  }
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numBeams | int | 2-10 | number of flexible bars |
| beamLength[i] | float | 30-150 | per beam |
| stiffness[i] | float | 0.1-5.0 | bending resistance |
| connections | topology | random | how beams connect |
| fixedPoints | int[] | 1-3 | which points are anchored |
| inputPoint | int | one free endpoint | where force is applied |
| inputType | enum | force/displacement/oscillating | how input is applied |

**Atlas:** 4x4 grid, each cell shows beam network deforming under input
**Single mode:** interactive — drag input point, see real-time deformation
**Discovery:** which topologies amplify motion? which create interesting distributed patterns?

---

### Experiment 27: 3D Cam Surface Explorer
**File:** `exp_3d_cam_surface_3d.html` (only 3D experiment beyond already-built ones)
**What:** Cylindrical cam with random surface profile → 2-input → 1-output function

**Core Math:**
```
Cylindrical cam: surface height h(theta, z)
  theta = rotation angle (input 1)
  z = axial position (input 2)
  h = radial displacement (output)

Surface generation using spherical harmonics or 2D Fourier:
  h(theta, z) = sum_{m,n} A[m][n] * cos(m*theta + phi_m) * cos(n*z*PI/L + psi_n)
```

**Follower:**
```
Roller follower rides on cam surface.
At position (theta, z), follower displacement = h(theta, z) - base_radius
Follower moves in radial direction only.
```

**Rendering (p5.js WEBGL):**
```javascript
// Draw cylindrical cam as mesh:
for (let i = 0; i < thetaSteps; i++) {
  beginShape(TRIANGLE_STRIP);
  for (let j = 0; j <= zSteps; j++) {
    let th1 = (i / thetaSteps) * TWO_PI;
    let th2 = ((i+1) / thetaSteps) * TWO_PI;
    let z = (j / zSteps) * camLength;
    let r1 = baseR + surfaceHeight(th1, z);
    let r2 = baseR + surfaceHeight(th2, z);
    vertex(r1*cos(th1), z, r1*sin(th1));
    vertex(r2*cos(th2), z, r2*sin(th2));
  }
  endShape();
}
```

**Randomization:**
| Parameter | Type | Range | Notes |
|-----------|------|-------|-------|
| numThetaHarmonics | int | 1-6 | circumferential complexity |
| numZHarmonics | int | 1-4 | axial complexity |
| A[m][n] | float | 0-baseR*0.3 | amplitude per harmonic |
| phi, psi | float | 0-2*PI | phases |
| baseRadius | float | 30-60 | base cylinder radius |
| camLength | float | 60-120 | cylinder length |

**Atlas:** 4x4 grid (rendered in 3D, isometric view), each cell shows one cam surface
**Single mode:** rotate cam, move follower along axis, see output displacement
**Coordinate system:** WEBGL, Y+ = down, cam axis along Y, rotation around Y

---

## BUILD PRIORITY & DEPENDENCIES

```
WAVE 1 (Core — build first, no dependencies):
  1. Linkage Lab          ← foundation for 5, 15, 24, 25
  2. Cam Synthesizer      ← foundation for 16, 27
  3. Non-Circular Gears   ← standalone
  4. Spirograph Deep      ← standalone
  5. Walker Gait Lab      ← depends on 1 (reuses solver)

WAVE 2 (Shapes — standalone):
  6. Superformula         ← standalone
  7. Rose/Polar Curves    ← standalone
  8. Math Drivers         ← standalone
  9. Straight-Line Sweep  ← standalone (known linkage topologies)

WAVE 3 (Networks — standalone):
  10. Coupled Oscillators  ← standalone
  11. Kinematic Tiles      ← standalone (needs iterative solver)
  12. Moire Animator       ← standalone (no physics)
  13. Bistable Array       ← standalone

WAVE 4 (Mechanisms — some depend on Wave 1):
  14. Gear Train           ← standalone
  15. Automata Figure      ← uses four-bar solver from 1
  16. Multi-Cam Sequencer  ← uses Fourier cam from 2
  17. Differential         ← standalone
  18. Escapement Zoo       ← standalone
  19. Pantograph Chain     ← standalone

WAVE 5 (Physics — standalone):
  20. 3-Body Orrery        ← standalone (RK4)
  21. Magnetic Pendulum    ← standalone
  22. Rattleback Cascade   ← standalone
  23. Cable/Pulley         ← standalone

WAVE 6 (Advanced — depend on earlier):
  24. L-System Linkage     ← depends on 1 (dyad solver)
  25. Creature Evolver     ← depends on 1 + 5 (solver + fitness)
  26. Compliant Flex       ← standalone (iterative relaxation)
  27. 3D Cam Surface       ← standalone (only 3D experiment)
```

---

## IMPLEMENTATION NOTES

### Shared code extraction
Experiments 1, 5, 15, 24, 25 all use the dyad composition solver. Rather than duplicating, each file will contain its own copy (standalone HTML requirement), but the algorithm is identical.

Similarly, Experiments 2, 16 share Fourier cam generation.

### Testing each experiment
After building each experiment:
1. Open in Chrome, verify atlas mode renders 16 cells
2. Click "Randomize" 5 times — verify variety
3. Click cell to enter single mode — verify detail view
4. Adjust sliders — verify responsive
5. "Find Beautiful" — verify scoring works
6. Check FPS counter ≥ 30 in atlas, ≥ 60 in single

### File naming convention
```
exp_linkage_lab_2d.html
exp_cam_synth_2d.html
exp_noncircular_gears_2d.html
exp_spirograph_deep_2d.html
exp_walker_gait_2d.html
exp_superformula_2d.html
exp_polar_curves_2d.html
exp_math_drivers_2d.html
exp_straight_line_2d.html
exp_coupled_oscillators_2d.html
exp_kinematic_tiles_2d.html
exp_moire_2d.html
exp_bistable_array_2d.html
exp_gear_train_2d.html
exp_automata_figure_2d.html
exp_multicam_sequencer_2d.html
exp_differential_2d.html
exp_escapement_zoo_2d.html
exp_pantograph_chain_2d.html
exp_three_body_2d.html
exp_magnetic_pendulum_2d.html
exp_rattleback_cascade_2d.html
exp_cable_pulley_2d.html
exp_lsystem_linkage_2d.html
exp_creature_evolver_2d.html
exp_compliant_flex_2d.html
exp_3d_cam_surface_3d.html
```

---

*Design complete. 27 experiments. Ready for implementation planning.*
*Last updated: 2026-02-26*
