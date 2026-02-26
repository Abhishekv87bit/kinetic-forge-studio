# Kinetic Discovery Suite v2 — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace 12 duplicate linkage experiments with 12 genuinely different physics experiments, rebuild 2 broken ones, fix 2, verified by a three-layer physics stack.

**Architecture:** Each experiment is a standalone single-file HTML (p5.js 1.9.0 + optional Matter.js 0.20.0). Physics correctness enforced by Python reference scripts (build-time), in-browser energy/constraint HUD (runtime), and analytical checks (in-code comments). Verlet integration shared pattern for cable/spring/tensegrity experiments.

**Tech Stack:** p5.js 1.9.0, Matter.js 0.20.0 (CDN), Python 3 + numpy + scipy (build-time only)

**Design doc:** `docs/plans/2026-02-26-kinetic-discovery-v2-design.md`

**Branch:** `kinetic-forge-studio-impl`

**Base directory:** `D:\Claude local\3d_design_agent\waffle_grid_planetary\`

---

## Shared Template CSS

All experiments use identical CSS (lines 1-71 of `exp_cam_synth_2d.html`). Copy verbatim. The ONLY additions for v2 are:

```css
/* Physics HUD additions — append after existing #hud styles */
#physics-hud {
  position: absolute; top: 8px; left: 290px;
  background: rgba(245,243,238,0.9); border: 1px solid #c8c0b0;
  border-radius: 4px; padding: 6px 10px; font-size: 9px; line-height: 1.6;
  color: #666; min-width: 140px; pointer-events: none; font-family: 'Consolas', monospace;
}
#physics-hud.warn { border-color: #cc8800; background: rgba(255,240,200,0.9); }
#physics-hud.error { border-color: #cc2020; background: rgba(255,220,220,0.9); }
```

```html
<!-- Physics HUD HTML — add after #hud div -->
<div id="physics-hud">
  <div>Energy: <span id="ph-energy">—</span></div>
  <div>Drift: <span id="ph-drift">—</span></div>
  <div>Constraints: <span id="ph-constraints">—</span></div>
  <div>dt: <span id="ph-dt">—</span></div>
</div>
```

---

## Shared Verlet Integration Pattern

Used by: Cable/Pulley, Tensegrity, Creature Evolver v2, String Art, Sand Pendulum.
Each experiment includes this inline (no shared file — standalone requirement).

```javascript
// === VERLET PARTICLE SYSTEM ===
// Each particle: {x, y, ox, oy, fx, fy, pinned, mass}
// ox/oy = old position (Verlet stores position history, not velocity)

function verletIntegrate(particles, dt, gravity) {
  for (let p of particles) {
    if (p.pinned) continue;
    let vx = p.x - p.ox;
    let vy = p.y - p.oy;
    p.ox = p.x;
    p.oy = p.y;
    p.x += vx + p.fx / p.mass * dt * dt;
    p.y += vy + (p.fy / p.mass + gravity) * dt * dt;
    p.fx = 0; p.fy = 0;
  }
}

function enforceDistanceConstraint(p1, p2, restLength, stiffness) {
  let dx = p2.x - p1.x;
  let dy = p2.y - p1.y;
  let dist = Math.sqrt(dx * dx + dy * dy);
  if (dist < 0.0001) return;
  let diff = (dist - restLength) / dist;
  let moveX = dx * diff * 0.5 * stiffness;
  let moveY = dy * diff * 0.5 * stiffness;
  if (!p1.pinned) { p1.x += moveX; p1.y += moveY; }
  if (!p2.pinned) { p2.x -= moveX; p2.y -= moveY; }
}

function enforceCableConstraint(p1, p2, maxLength) {
  // Cable: can be shorter (slack), cannot be longer (tension only)
  let dx = p2.x - p1.x;
  let dy = p2.y - p1.y;
  let dist = Math.sqrt(dx * dx + dy * dy);
  if (dist <= maxLength) return; // slack, no force
  let diff = (dist - maxLength) / dist;
  let moveX = dx * diff * 0.5;
  let moveY = dy * diff * 0.5;
  if (!p1.pinned) { p1.x += moveX; p1.y += moveY; }
  if (!p2.pinned) { p2.x -= moveX; p2.y -= moveY; }
}

function computeVerletEnergy(particles, constraints, gravity) {
  let ke = 0, pe = 0;
  for (let p of particles) {
    let vx = p.x - p.ox;
    let vy = p.y - p.oy;
    ke += 0.5 * p.mass * (vx * vx + vy * vy);
    pe += p.mass * gravity * p.y; // gravity potential
  }
  for (let c of constraints) {
    let dx = c.p2.x - c.p1.x;
    let dy = c.p2.y - c.p1.y;
    let dist = Math.sqrt(dx * dx + dy * dy);
    let stretch = dist - c.restLength;
    pe += 0.5 * c.stiffness * stretch * stretch; // elastic potential
  }
  return { ke, pe, total: ke + pe };
}
```

---

## Task 0: Python Verification Scripts

**Files:**
- Create: `physics_verify/verify_verlet_cable.py`
- Create: `physics_verify/verify_pendulum_period.py`
- Create: `physics_verify/verify_beam_deflection.py`
- Create: `physics_verify/verify_dipole_torque.py`
- Create: `physics_verify/verify_siphon_flow.py`
- Create: `physics_verify/requirements.txt`

### Step 1: Create directory and requirements

```bash
mkdir physics_verify
```

`physics_verify/requirements.txt`:
```
numpy>=1.24
scipy>=1.10
```

### Step 2: Write verify_verlet_cable.py

Generates test vectors for a cable with N particles hanging under gravity between two fixed endpoints. Expected shape is a catenary: `y = a * cosh((x - x0) / a) + C`.

```python
"""Verify Verlet cable sag against analytical catenary solution.

Usage: python verify_verlet_cable.py
Output: verify_verlet_cable_results.json
"""
import numpy as np
import json

def catenary(x, a, x0, y0):
    """Analytical catenary: y = a * cosh((x - x0) / a) + y0 - a"""
    return a * np.cosh((x - x0) / a) + y0 - a

def simulate_verlet_cable(n_particles, span, gravity, dt, steps):
    """Simulate a Verlet cable and return final positions."""
    # Initialize particles in straight line
    px = np.linspace(0, span, n_particles)
    py = np.zeros(n_particles)
    ox = px.copy()
    oy = py.copy()
    rest_length = span / (n_particles - 1)

    for _ in range(steps):
        # Verlet integration with gravity
        for i in range(1, n_particles - 1):  # skip pinned endpoints
            vx = px[i] - ox[i]
            vy = py[i] - oy[i]
            ox[i] = px[i]
            oy[i] = py[i]
            px[i] += vx * 0.999  # slight damping
            py[i] += vy * 0.999 + gravity * dt * dt

        # Distance constraints (10 iterations)
        for _ in range(10):
            for i in range(n_particles - 1):
                dx = px[i+1] - px[i]
                dy = py[i+1] - py[i]
                dist = np.sqrt(dx*dx + dy*dy)
                if dist < 1e-6:
                    continue
                diff = (dist - rest_length) / dist * 0.5
                if i > 0:
                    px[i] += dx * diff
                    py[i] += dy * diff
                if i + 1 < n_particles - 1:
                    px[i+1] -= dx * diff
                    py[i+1] -= dy * diff

    return px.tolist(), py.tolist()

if __name__ == "__main__":
    tests = []

    for n in [20, 50, 100]:
        span = 300
        gravity = 0.5
        px, py = simulate_verlet_cable(n, span, gravity, dt=0.5, steps=2000)

        # Fit catenary to result
        from scipy.optimize import curve_fit
        try:
            popt, _ = curve_fit(catenary, px, py, p0=[100, span/2, 0], maxfev=5000)
            a_fit = popt[0]
            residual = np.mean(np.abs(np.array(py) - catenary(np.array(px), *popt)))
        except:
            a_fit = -1
            residual = -1

        tests.append({
            "n_particles": n,
            "span": span,
            "gravity": gravity,
            "final_positions_x": px,
            "final_positions_y": py,
            "catenary_a": float(a_fit),
            "mean_residual_from_catenary": float(residual),
            "max_sag": float(max(py)),
            "tolerance_note": "JS implementation sag should match within 5% of max_sag"
        })

    result = {"test_name": "verlet_cable_sag", "tests": tests}
    with open("physics_verify/verify_verlet_cable_results.json", "w") as f:
        json.dump(result, f, indent=2)
    print(f"Written {len(tests)} test cases")
    for t in tests:
        print(f"  n={t['n_particles']}: sag={t['max_sag']:.1f}px, catenary residual={t['mean_residual_from_catenary']:.2f}px")
```

### Step 3: Write verify_pendulum_period.py

```python
"""Verify pendulum period against analytical solution.

Usage: python verify_pendulum_period.py
Output: verify_pendulum_period_results.json
"""
import numpy as np
from scipy.integrate import solve_ivp
import json

def pendulum_ode(t, y, g, L):
    theta, omega = y
    return [omega, -g/L * np.sin(theta)]

if __name__ == "__main__":
    g = 9.81  # m/s^2 (or mm/s^2 scaled)
    tests = []

    for L in [0.1, 0.25, 0.5, 1.0]:  # meters
        for theta0 in [0.1, 0.3, 0.5, 1.0]:  # radians
            T_approx = 2 * np.pi * np.sqrt(L / g)  # small angle

            # Numerical integration for exact period
            sol = solve_ivp(pendulum_ode, [0, 10*T_approx], [theta0, 0],
                          args=(g, L), max_step=0.001, dense_output=True)

            # Find zero crossings to measure period
            t_fine = np.linspace(0, 10*T_approx, 100000)
            theta_fine = sol.sol(t_fine)[0]
            crossings = []
            for i in range(1, len(theta_fine)):
                if theta_fine[i-1] > 0 and theta_fine[i] <= 0:
                    # Linear interpolation for crossing time
                    frac = theta_fine[i-1] / (theta_fine[i-1] - theta_fine[i])
                    crossings.append(t_fine[i-1] + frac * (t_fine[i] - t_fine[i-1]))

            if len(crossings) >= 2:
                T_numerical = 2 * (crossings[1] - crossings[0])  # half period * 2
            else:
                T_numerical = T_approx

            tests.append({
                "L": L,
                "theta0_rad": theta0,
                "g": g,
                "T_small_angle": float(T_approx),
                "T_numerical": float(T_numerical),
                "error_pct": float(abs(T_numerical - T_approx) / T_approx * 100),
                "tolerance_note": "JS must match T_numerical within 2%"
            })

    result = {"test_name": "pendulum_period", "tests": tests}
    with open("physics_verify/verify_pendulum_period_results.json", "w") as f:
        json.dump(result, f, indent=2)
    print(f"Written {len(tests)} test cases")
    for t in tests:
        print(f"  L={t['L']}m, theta0={t['theta0_rad']}rad: "
              f"T_analytical={t['T_small_angle']:.4f}s, T_numerical={t['T_numerical']:.4f}s "
              f"(diff={t['error_pct']:.2f}%)")
```

### Step 4: Write verify_beam_deflection.py

```python
"""Verify Euler-Bernoulli beam deflection against analytical solution.

Cantilever beam with point load at free end:
  delta_max = P * L^3 / (3 * E * I)

Usage: python verify_beam_deflection.py
Output: verify_beam_deflection_results.json
"""
import numpy as np
import json

if __name__ == "__main__":
    tests = []

    for L in [100, 200, 300]:      # beam length (mm)
        for EI in [1e3, 1e4, 1e5]:  # flexural rigidity (N*mm^2)
            for P in [1, 5, 10]:     # point load (N)
                # Analytical: y(x) = P/(6EI) * (3Lx^2 - x^3)
                x = np.linspace(0, L, 50)
                y_analytical = P / (6 * EI) * (3 * L * x**2 - x**3)
                delta_max = P * L**3 / (3 * EI)

                tests.append({
                    "L": L, "EI": float(EI), "P": P,
                    "delta_max_mm": float(delta_max),
                    "x_positions": x.tolist(),
                    "y_deflection": y_analytical.tolist(),
                    "tolerance_note": "JS tip deflection must match within 3%"
                })

    result = {"test_name": "beam_deflection", "tests": tests}
    with open("physics_verify/verify_beam_deflection_results.json", "w") as f:
        json.dump(result, f, indent=2)
    print(f"Written {len(tests)} test cases")
    for t in tests:
        print(f"  L={t['L']}mm, EI={t['EI']:.0f}, P={t['P']}N: delta_max={t['delta_max_mm']:.2f}mm")
```

### Step 5: Write verify_dipole_torque.py

```python
"""Verify magnetic dipole torque between two magnetic gear rings.

Torque between two dipoles: tau = (mu0/4pi) * (3(m1.r)(m2.r)/r^5 - m1.m2/r^3)
Simplified for 2D: radial dipoles on concentric circles.

Usage: python verify_dipole_torque.py
Output: verify_dipole_torque_results.json
"""
import numpy as np
import json

def dipole_torque_2d(n1, n2, r1, r2, strength, theta_offset):
    """Compute net torque on ring 2 from ring 1 at given angular offset."""
    torque = 0
    for i in range(n1):
        a1 = 2 * np.pi * i / n1
        mx1 = strength * np.cos(a1)  # dipole direction = radial
        my1 = strength * np.sin(a1)
        px1 = r1 * np.cos(a1)
        py1 = r1 * np.sin(a1)

        for j in range(n2):
            a2 = 2 * np.pi * j / n2 + theta_offset
            mx2 = strength * np.cos(a2)
            my2 = strength * np.sin(a2)
            px2 = r2 * np.cos(a2)
            py2 = r2 * np.sin(a2)

            dx = px2 - px1
            dy = py2 - py1
            r = np.sqrt(dx*dx + dy*dy)
            if r < 1e-6:
                continue

            # Simplified 2D dipole interaction torque on dipole 2
            # tau = cross(m2, B1) where B1 is field from dipole 1
            # B1 ~ (3(m1.rhat)rhat - m1) / r^3
            rx, ry = dx/r, dy/r
            m1_dot_r = mx1*rx + my1*ry
            Bx = (3 * m1_dot_r * rx - mx1) / (r**3)
            By = (3 * m1_dot_r * ry - my1) / (r**3)
            # Torque on m2 = m2 x B (cross product z-component)
            tau_z = mx2 * By - my2 * Bx
            # Convert to torque about center (lever arm = r2)
            torque += tau_z * r2

    return torque

if __name__ == "__main__":
    tests = []

    for n1 in [4, 8, 12]:
        for n2 in [4, 8, 12]:
            r1, r2 = 50, 70
            strength = 1.0
            angles = np.linspace(0, 2*np.pi/max(n1,n2), 60)
            torques = [float(dipole_torque_2d(n1, n2, r1, r2, strength, a)) for a in angles]

            tests.append({
                "n1": n1, "n2": n2, "r1": r1, "r2": r2,
                "strength": strength,
                "angles_rad": angles.tolist(),
                "torques": torques,
                "max_torque": float(max(torques)),
                "cogging_period_rad": float(2*np.pi / np.lcm(n1, n2)),
                "gear_ratio": n2/n1,
                "tolerance_note": "JS torque curve shape must match, magnitude within 10%"
            })

    result = {"test_name": "dipole_torque", "tests": tests}
    with open("physics_verify/verify_dipole_torque_results.json", "w") as f:
        json.dump(result, f, indent=2)
    print(f"Written {len(tests)} test cases")
    for t in tests:
        print(f"  {t['n1']}:{t['n2']} magnets, ratio={t['gear_ratio']:.2f}, "
              f"max_torque={t['max_torque']:.4f}, cogging_period={np.degrees(t['cogging_period_rad']):.1f}deg")
```

### Step 6: Write verify_siphon_flow.py

```python
"""Verify siphon flow rate against Torricelli's theorem.

Torricelli: v = sqrt(2*g*h) where h = height difference
Flow rate: Q = A * v where A = cross-sectional area of tube

Usage: python verify_siphon_flow.py
Output: verify_siphon_flow_results.json
"""
import numpy as np
import json

if __name__ == "__main__":
    g = 9810  # mm/s^2
    tests = []

    for h in [20, 50, 100, 200]:     # height difference (mm)
        for d in [5, 10, 20]:         # tube diameter (mm)
            A = np.pi * (d/2)**2
            v = np.sqrt(2 * g * h)
            Q = A * v  # mm^3/s

            # Time to drain reservoir of volume V
            V = 50000  # mm^3 (50 mL)
            t_drain = V / Q

            tests.append({
                "h_mm": h, "d_mm": d,
                "velocity_mm_s": float(v),
                "flow_rate_mm3_s": float(Q),
                "drain_time_s": float(t_drain),
                "reservoir_volume_mm3": V,
                "tolerance_note": "JS particle flow rate should approximate within 20% (discrete particles are inherently noisy)"
            })

    result = {"test_name": "siphon_flow", "tests": tests}
    with open("physics_verify/verify_siphon_flow_results.json", "w") as f:
        json.dump(result, f, indent=2)
    print(f"Written {len(tests)} test cases")
    for t in tests:
        print(f"  h={t['h_mm']}mm, d={t['d_mm']}mm: v={t['velocity_mm_s']:.0f}mm/s, "
              f"Q={t['flow_rate_mm3_s']:.0f}mm3/s, t_drain={t['drain_time_s']:.1f}s")
```

### Step 7: Run all verification scripts

```bash
cd physics_verify
pip install numpy scipy
python verify_verlet_cable.py
python verify_pendulum_period.py
python verify_beam_deflection.py
python verify_dipole_torque.py
python verify_siphon_flow.py
```

Expected: 5 JSON files generated, no errors.

### Step 8: Commit

```bash
git add physics_verify/
git commit -m "feat: add Python physics verification scripts for v2 experiments"
```

---

## Task 1: Rebuild Cable & Pulley (Verlet Physics)

**Files:**
- Rewrite: `exp_cable_pulley_2d.html` (complete rewrite)
- Validate against: `physics_verify/verify_verlet_cable_results.json`

### I/O Contract

```
INPUT:    Pull force on cable end (drag handle), pulley layout
MECHANISM: Verlet particle chain with distance constraints, pulley wrap projection
OUTPUT:   Mechanical advantage (force ratio), cable tension distribution, cable path
CONSTRAINT: Cable inextensible, tension-only (no compression), no self-intersection
```

### Key Implementation Details

**Cable model:** 60 Verlet particles, spacing = total_length / 59. Each frame:
1. Apply gravity to all non-pinned particles
2. Apply input force to handle particle
3. Enforce distance constraints (15 iterations)
4. Project particles outside pulley circles onto pulley surface
5. Compute tension at each segment: `T = stiffness * (dist - restLength) / restLength`

**Pulley wrap:** When a particle enters a pulley's radius, project it onto the pulley circumference. The particle slides along the surface (tangent motion preserved, radial motion absorbed).

**Fixed pulleys:** Position is constant. Cable redirects around them.
**Free pulleys:** Position = sum of cable forces minus gravity × mass. Updated each frame.

**MA computation:** Count cable segments that contact the free pulley. MA = number of supporting segments.

**Physics HUD:** Display total cable tension, max segment tension, MA, energy (kinetic + gravitational potential).

### Atlas Mode
16 configs: random pulley count (3-8), random fixed/free split, random positions/radii. Each cell shows cable path, pulley types (gray=fixed with triangle bracket, brown=free with weight block), MA number.

### Single Mode
Full display. Drag red handle on left to apply input force. Cable responds in real-time. Tension shown as color gradient on cable (blue=low, red=high). Force diagram panel on right.

### Find Beautiful v2
Score by: MA value (higher = more interesting) × cable efficiency (short path) × stability (low oscillation after settling).

### Analytical Check (in-code comment)
```javascript
// ANALYTICAL CHECK: Simple single-pulley system
// MA = 2 for one free pulley with 2 cable segments
// Cable sag should approximate catenary: y = a*cosh(x/a)
// See physics_verify/verify_verlet_cable_results.json for test vectors
```

### Commit
```bash
git add exp_cable_pulley_2d.html
git commit -m "feat: rebuild cable/pulley with Verlet particle physics — real cable sag and tension"
```

---

## Task 2: Build Ball Run / Marble Machine (Matter.js)

**Files:**
- Create: `exp_ball_run_2d.html`

### I/O Contract

```
INPUT:    Ball drop position, track element layout (randomized)
MECHANISM: Matter.js rigid body — gravity, collisions, friction on static track elements
OUTPUT:   Ball transit time, path taken, exit speed, split ratios at forks
CONSTRAINT: Ball must reach exit, track elements cannot overlap
```

### Key Implementation Details

**Matter.js setup:**
```javascript
const engine = Matter.Engine.create({ gravity: { x: 0, y: 1 } });
const world = engine.world;
```

**Track elements (static bodies):**
1. **Ramp:** `Matter.Bodies.rectangle(x, y, length, thickness, { isStatic: true, angle: angle })`
2. **Funnel:** Two angled rectangles converging
3. **Bumper:** `Matter.Bodies.circle(x, y, r, { isStatic: true, restitution: 1.2 })` (spring-loaded)
4. **Loop:** Chain of small static rectangles forming circular track
5. **Seesaw:** Rectangle on pivot via `Matter.Constraint.create({pointA: pivot})`
6. **Gate:** Static body toggled `isStatic: true/false` on timer

**Ball:** `Matter.Bodies.circle(x, y, 8, { restitution: 0.6, friction: 0.1, density: 0.002 })`

**Rendering:** p5.js draws Matter.js bodies each frame. Track elements = brown/gray. Balls = colored circles with motion trail.

**Physics HUD:** Ball speed, height, kinetic energy, total energy (KE + mgh).

### Atlas/Single/Find Beautiful
Same pattern as Cable/Pulley. Atlas = 16 random track layouts. Single = interactive. Find Beautiful scores by path complexity (elements touched), transit time consistency, and visual drama (loops completed, jumps landed).

### Commit
```bash
git add exp_ball_run_2d.html
git commit -m "feat: add ball run / marble machine — Matter.js rigid body track builder"
```

---

## Task 3: Rebuild Creature Evolver v2 (Verlet + GA)

**Files:**
- Rewrite: `exp_creature_evolver_2d.html` (complete rewrite)

### I/O Contract

```
INPUT:    Fitness function, mutation rate, population size (64)
MECHANISM: Genome → Verlet particle creature with spring-muscles on ground with gravity+friction
OUTPUT:   Distance traveled, fitness over generations (best/avg/worst)
CONSTRAINT: Max 20 nodes, max 40 connections, ground collision with friction
```

### Key Implementation Details

**Genome:** `{ nodes: [{x, y, mass}], connections: [{i, j, restLength, amplitude, frequency, phase}] }`

**Simulation per creature (evaluate fitness):**
```javascript
function evaluateCreature(genome, steps, dt) {
  // Create Verlet particles from genome nodes
  let particles = genome.nodes.map(n => ({
    x: n.x, y: n.y, ox: n.x, oy: n.y,
    fx: 0, fy: 0, pinned: false, mass: n.mass
  }));

  let initialCOM = centerOfMass(particles);

  for (let s = 0; s < steps; s++) {
    let t = s * dt;

    // Oscillate muscle rest lengths
    for (let c of genome.connections) {
      c.currentLength = c.restLength + c.amplitude * Math.sin(c.frequency * t + c.phase);
    }

    // Verlet integrate with gravity
    verletIntegrate(particles, dt, GRAVITY);

    // Enforce muscle constraints (distance = currentLength)
    for (let iter = 0; iter < 10; iter++) {
      for (let c of genome.connections) {
        enforceDistanceConstraint(particles[c.i], particles[c.j], c.currentLength, 0.8);
      }
    }

    // Ground collision + friction
    for (let p of particles) {
      if (p.y > GROUND_Y) {
        p.y = GROUND_Y;
        let vy = p.y - p.oy;
        p.oy = p.y + vy * 0.3; // bounce damping
        // Friction: slow horizontal motion when on ground
        let vx = p.x - p.ox;
        p.ox = p.x - vx * FRICTION;
      }
    }
  }

  let finalCOM = centerOfMass(particles);
  return finalCOM.x - initialCOM.x; // distance fitness
}
```

**GA:** Population 64, elitism 10%, crossover (graph merge), mutation (add/remove node/connection, perturb params).

**Physics HUD:** Best creature's KE, PE, muscle energy, ground contact count.

### Commit
```bash
git add exp_creature_evolver_2d.html
git commit -m "feat: rebuild creature evolver v2 — Verlet physics with ground collision and spring-muscles"
```

---

## Task 4: Build Water Siphon Cascade

**Files:**
- Create: `exp_water_siphon_2d.html`
- Validate against: `physics_verify/verify_siphon_flow_results.json`

### I/O Contract

```
INPUT:    Reservoir heights, tube diameters, valve open/close
MECHANISM: Discrete particle gravity flow, siphon principle (primed tube maintains flow uphill)
OUTPUT:   Flow rate per stage, fill levels, cascade timing
CONSTRAINT: Siphon breaks if air enters, flow stops when delta_h = 0
```

### Key Implementation Details

**Particle system (NOT Verlet — simpler):**
- 200-400 particles per reservoir, radius 3px
- Each frame: apply gravity, resolve collisions with walls and other particles
- Inside tube: particles follow tube centerline with speed ∝ sqrt(2g*delta_h)
- Tube entrance: particles enter when reservoir level >= tube inlet height
- Siphon: once tube is full (continuous particle chain from inlet to outlet), flow continues even uphill

**Reservoir:** Rectangle with fill level. Particles bounce off walls. Color = blue with alpha.

**Tubes:** Cubic Bezier curves connecting reservoirs. Particles inside tube follow the Bezier path parameterized by t (0=inlet, 1=outlet).

**Tipping bucket:** Rectangle on pivot. Fills with particles. Tips when COM shifts past pivot. Dumps particles into next reservoir.

**Physics HUD:** Flow rate (particles/second), reservoir levels, siphon status (primed/broken).

### Commit
```bash
git add exp_water_siphon_2d.html
git commit -m "feat: add water siphon cascade — gravity-driven particle flow with siphon physics"
```

---

## Task 5: Build Tipping Balance Automata (Matter.js)

**Files:**
- Create: `exp_tipping_balance_2d.html`

### I/O Contract

```
INPUT:    Weight source position (particle drip or ball drop)
MECHANISM: Matter.js balance beams on pivots, tip when torque exceeds threshold, cascade
OUTPUT:   Tipping sequence timing, cascade pattern
CONSTRAINT: Pivot friction, angular limits ±45°, beam inertia
```

### Key Implementation Details

**Balance beam:** Matter.js rectangle body constrained to pivot point via `Matter.Constraint`. Angular limits enforced by custom position correction.

**Cascade:** When beam tips past threshold, contents slide off arm. Caught by next beam below/adjacent. Accumulation triggers next tip.

**Weight source:** Timed particle emitter (small circles dropping from top).

### Commit
```bash
git add exp_tipping_balance_2d.html
git commit -m "feat: add tipping balance automata — counterweight cascade with Matter.js physics"
```

---

## Task 6: Build Tensegrity Builder (Verlet)

**Files:**
- Create: `exp_tensegrity_2d.html`

### I/O Contract

```
INPUT:    Strut count (3-8), cable tension, external load (click to apply)
MECHANISM: Verlet nodes with strut constraints (rigid) + cable constraints (tension-only)
OUTPUT:   Stable structure shape, stress distribution, load capacity before collapse
CONSTRAINT: Cables cannot push, struts cannot bend, structure must self-stabilize
```

### Key Implementation Details

**Two constraint types:**
```javascript
// Strut: rigid distance (both push and pull)
enforceDistanceConstraint(p1, p2, restLength, 1.0);

// Cable: max distance (pull only, can go slack)
enforceCableConstraint(p1, p2, maxLength);
```

**Equilibrium finding:** Run 500 Verlet steps with high damping to settle structure. If any cable goes slack, mark it dashed.

**Interaction:** Click+drag any node. Release to see if structure springs back (stable) or collapses (unstable).

**Visualization:** Struts = thick gray bars, Cables = thin brown lines (dashed if slack). Color by stress: compression = blue, tension = red.

### Commit
```bash
git add exp_tensegrity_2d.html
git commit -m "feat: add tensegrity builder — Verlet strut/cable self-stressed structures"
```

---

## Task 7: Build String Art Machine

**Files:**
- Create: `exp_string_art_2d.html`

### I/O Contract

```
INPUT:    Pin count (10-50), winding rule (modular/multiplication/fibonacci/cardioid), string tension
MECHANISM: Pins on boundary shape, strings connect pin_i to pin_(i+K mod N)
OUTPUT:   Envelope curve, string density pattern, visual complexity
CONSTRAINT: K < N (winding number), pins on shape boundary only
```

### Commit
```bash
git add exp_string_art_2d.html
git commit -m "feat: add string art machine — winding rules create mathematical envelope curves"
```

---

## Task 8: Rebuild Compliant Flex (Euler-Bernoulli Beam FEA)

**Files:**
- Rewrite: `exp_compliant_flex_2d.html`
- Validate against: `physics_verify/verify_beam_deflection_results.json`

### I/O Contract

```
INPUT:    Applied force (drag), beam stiffness EI, topology
MECHANISM: Euler-Bernoulli beam elements: tau = -EI * (theta - theta_rest) / L_segment
OUTPUT:   Displacement amplification ratio, stress distribution, fatigue indicator
CONSTRAINT: Max stress < yield, no self-intersection of beam
```

### Key Implementation Details

**Beam = chain of N rigid segments connected by torsional springs:**
```javascript
function relaxBeam(joints, segments, EI, damping, dt) {
  for (let i = 1; i < joints.length - 1; i++) {
    let dx1 = joints[i].x - joints[i-1].x;
    let dy1 = joints[i].y - joints[i-1].y;
    let dx2 = joints[i+1].x - joints[i].x;
    let dy2 = joints[i+1].y - joints[i].y;

    let angle1 = Math.atan2(dy1, dx1);
    let angle2 = Math.atan2(dy2, dx2);
    let bend = angle2 - angle1; // bending angle at joint i

    // Restoring torque
    let torque = -EI * (bend - joints[i].restAngle) / segments[i].length;
    torque -= damping * joints[i].angularVel;

    // Apply torque as lateral force on adjacent joints
    let force = torque / segments[i].length;
    // ... distribute force to joints[i-1] and joints[i+1]
  }
}
```

**Four compliant mechanism types:**
1. Lever amplifier — input at one end, output at other, pivot bends
2. Bistable switch — two stable positions, snap-through at center
3. Compliant gripper — two arms close when squeezed at base
4. Displacement inverter — push in, output moves opposite

### Commit
```bash
git add exp_compliant_flex_2d.html
git commit -m "feat: rebuild compliant flex — Euler-Bernoulli beam FEA with real elastic deformation"
```

---

## Task 9: Build Geneva & Intermittent Motion

**Files:**
- Create: `exp_geneva_intermittent_2d.html`

### I/O Contract

```
INPUT:    Driver speed, slot count (3-8), mechanism type
MECHANISM: Pin-slot engagement geometry → indexed rotation with dwell
OUTPUT:   Output staircase curve, dwell duration, peak angular acceleration
CONSTRAINT: Pin must clear adjacent slot, output locks during dwell
```

### Three Mechanism Types
1. **External Geneva** — pin engages radial slots on driven wheel
2. **Internal Geneva** — pin engages slots on inner ring surface
3. **Cam indexer** — barrel cam with globoidal rise/dwell/return

### Commit
```bash
git add exp_geneva_intermittent_2d.html
git commit -m "feat: add Geneva & intermittent motion — indexed rotation with programmable dwell"
```

---

## Task 10: Build Magnetic Gear Pairs

**Files:**
- Create: `exp_magnetic_gears_2d.html`
- Validate against: `physics_verify/verify_dipole_torque_results.json`

### I/O Contract

```
INPUT:    Driver torque, magnet counts (4-20 per ring), air gap
MECHANISM: Dipole-dipole force computation between concentric magnet rings
OUTPUT:   Transmitted torque curve, cogging ripple, slip threshold
CONSTRAINT: Slip when applied torque > max magnetic torque
```

### Commit
```bash
git add exp_magnetic_gears_2d.html
git commit -m "feat: add magnetic gear pairs — contactless torque via dipole field simulation"
```

---

## Task 11: Build Ratchet & Pawl Networks (Matter.js)

**Files:**
- Create: `exp_ratchet_pawl_2d.html`

### I/O Contract

```
INPUT:    Wind-up torque (drag), release trigger
MECHANISM: Matter.js ratchet wheel + spring-loaded pawl, energy storage in spring/weight
OUTPUT:   Stored energy, release speed, cascade sequence timing
CONSTRAINT: Asymmetric teeth prevent back-drive, pawl spring > friction
```

### Commit
```bash
git add exp_ratchet_pawl_2d.html
git commit -m "feat: add ratchet & pawl networks — one-way motion with energy storage and release"
```

---

## Task 12: Build Shadow Sculpture (WEBGL)

**Files:**
- Create: `exp_shadow_sculpture_3d.html`

### I/O Contract

```
INPUT:    3D shape (random voxel/wireframe/boolean), light direction angles
MECHANISM: Parallel ray projection from light through 3D object onto ground plane
OUTPUT:   Shadow silhouette, shadow area, complexity score
CONSTRAINT: Object fits in unit sphere, Y+ = down (p5 WEBGL convention)
```

### Commit
```bash
git add exp_shadow_sculpture_3d.html
git commit -m "feat: add shadow sculpture — 3D form to 2D shadow projection explorer"
```

---

## Task 13: Build Origami / Deployable

**Files:**
- Create: `exp_origami_deployable_2d.html`

### I/O Contract

```
INPUT:    Fold pattern type (Miura-ori/Yoshizawa/Waterbomb/random), deployment slider 0-100%
MECHANISM: Rigid origami — flat panels connected by fold-line hinges, 1 DOF deployment
OUTPUT:   Deployed shape, fold angles, compaction ratio
CONSTRAINT: No panel-panel intersection, fold compatibility (1 DOF)
```

### Commit
```bash
git add exp_origami_deployable_2d.html
git commit -m "feat: add origami deployable — rigid folding mechanisms with 1-DOF deployment"
```

---

## Task 14: Build Sand Pendulum Harmonograph

**Files:**
- Create: `exp_sand_pendulum_2d.html`
- Validate against: `physics_verify/verify_pendulum_period_results.json`

### I/O Contract

```
INPUT:    Pendulum lengths (L1, L2), initial amplitudes, damping rate
MECHANISM: Damped compound pendulum (X=L1, Y=L2), sand deposited at tip each frame
OUTPUT:   Lissajous sand pattern, frequency ratio, density distribution
CONSTRAINT: Pattern fits canvas, damping reaches < 1% amplitude within time limit
```

### Key Feature
Sand ACCUMULATES. Slow motion = dense deposits. Fast crossings = sparse. Natural density gradients emerge.

### Commit
```bash
git add exp_sand_pendulum_2d.html
git commit -m "feat: add sand pendulum harmonograph — damped Lissajous with accumulating sand deposits"
```

---

## Task 15: Fix Cam Synth + Multi-Cam (Follower Dynamics)

**Files:**
- Modify: `exp_cam_synth_2d.html` — add follower mass, spring return, contact force
- Modify: `exp_multicam_sequencer_2d.html` — same follower dynamics addition

### Changes
Add to each follower: mass, spring stiffness, and contact detection.

```javascript
// Follower dynamics (add to simulation loop)
let cam_surface_y = evaluateCamProfile(theta);
let spring_force = -spring_k * (follower_y - rest_y);
let contact_force = 0;

if (follower_y > cam_surface_y) {
  // Follower is below cam surface — contact
  contact_force = follower_mass * follower_accel + spring_force;
} else {
  // Follower has separated from cam — no contact
  // Apply only gravity + spring
  follower_accel = -spring_k / follower_mass * (follower_y - rest_y) + gravity;
}

// Flag separation (jump) in red on HUD
if (contact_force < 0) hudWarn("FOLLOWER JUMP");
```

### Commit
```bash
git add exp_cam_synth_2d.html exp_multicam_sequencer_2d.html
git commit -m "fix: add follower dynamics to cam synth and multi-cam — mass, spring, contact force detection"
```

---

## Task 16: Delete Old Files + Update Index

**Files:**
- Delete 12 linkage duplicates:
  ```
  exp_coupler_curves_2d.html
  exp_compound_coupler_2d.html
  exp_linkage_lab_2d.html
  exp_walker_gait_2d.html
  exp_straight_line_2d.html
  exp_pantograph_chain_2d.html
  exp_automata_figure_2d.html
  exp_lsystem_linkage_2d.html
  exp_polar_curves_2d.html
  exp_superformula_2d.html
  exp_math_drivers_2d.html
  exp_kinematic_tiles_2d.html
  ```
- Delete 3 old extras:
  ```
  exp_chaos_garden_3d.html
  exp_harmonograph_3d.html
  exp_lorenz_attractor_3d.html
  ```
- Rewrite: `exp_index.html` — updated hub page with new 27 experiments

### Commit
```bash
git rm exp_coupler_curves_2d.html exp_compound_coupler_2d.html exp_linkage_lab_2d.html \
       exp_walker_gait_2d.html exp_straight_line_2d.html exp_pantograph_chain_2d.html \
       exp_automata_figure_2d.html exp_lsystem_linkage_2d.html exp_polar_curves_2d.html \
       exp_superformula_2d.html exp_math_drivers_2d.html exp_kinematic_tiles_2d.html \
       exp_chaos_garden_3d.html exp_harmonograph_3d.html exp_lorenz_attractor_3d.html
git add exp_index.html
git commit -m "refactor: remove 15 duplicate/redundant experiments, update index for v2 suite"
```

---

## Task 17: Final Verification Pass

### Step 1: Run all Python verification scripts
```bash
cd physics_verify
python verify_verlet_cable.py
python verify_pendulum_period.py
python verify_beam_deflection.py
python verify_dipole_torque.py
python verify_siphon_flow.py
```

### Step 2: Open each experiment in browser, verify:
- [ ] Physics HUD shows green for 60 seconds
- [ ] "Randomize" produces 5 visually distinct results
- [ ] Atlas shows at least 4 distinct categories
- [ ] At least one slider meaningfully changes behavior
- [ ] No console errors

### Step 3: Final commit
```bash
git add -A
git commit -m "verify: all 27 v2 experiments pass physics verification and quality gates"
```

---

## Execution Summary

| Task | Experiment | Type | Physics Engine | Depends On |
|------|-----------|------|---------------|------------|
| 0 | Python verification scripts | Foundation | numpy/scipy | — |
| 1 | Cable/Pulley | REBUILD | Verlet | Task 0 |
| 2 | Ball Run | NEW | Matter.js | — |
| 3 | Creature Evolver v2 | NEW (replace) | Verlet + GA | Task 0 |
| 4 | Water Siphon | NEW | Particle flow | Task 0 |
| 5 | Tipping Balance | NEW | Matter.js | — |
| 6 | Tensegrity | NEW | Verlet | Task 0 |
| 7 | String Art | NEW | Geometric + Verlet | — |
| 8 | Compliant Flex | REBUILD | Beam FEA | Task 0 |
| 9 | Geneva & Intermittent | NEW | Rotary dynamics | — |
| 10 | Magnetic Gears | NEW | Dipole field | Task 0 |
| 11 | Ratchet & Pawl | NEW | Matter.js | — |
| 12 | Shadow Sculpture | NEW | WEBGL ray projection | — |
| 13 | Origami/Deployable | NEW | Rigid fold kinematics | — |
| 14 | Sand Pendulum | NEW | Damped oscillation | Task 0 |
| 15 | Fix Cam Synth + Multi-Cam | FIX | Rotary + follower | — |
| 16 | Delete old + update index | CLEANUP | — | Tasks 1-15 |
| 17 | Final verification | QA | — | Task 16 |

**Parallelization:** Tasks 1-15 are independent (each is a standalone HTML file). They CAN all run in parallel. Only Tasks 0 (foundation), 16 (cleanup), and 17 (verification) must be sequential.

**Total new/rebuilt files:** 14 experiments + 1 index page + 5 Python scripts = 20 files
**Total deleted files:** 15 old experiments
