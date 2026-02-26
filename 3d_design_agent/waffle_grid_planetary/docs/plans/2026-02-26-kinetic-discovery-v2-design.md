# Kinetic Discovery Suite v2 — Redesign Document

**Date:** 2026-02-26
**Branch:** `kinetic-forge-studio-impl`
**Status:** Design — awaiting approval

---

## 1. Problem Statement

The v1 suite (27 experiments) suffers from three critical flaws:

1. **Duplication:** ~60% (14-16) are fundamentally "rigid bars connected at joints" with cosmetic differences
2. **Shallow physics:** Most use kinematic simulation (geometry playback), not dynamic simulation (forces → motion)
3. **Repetitive randomization:** "Find Beautiful" generates similar outputs because the parameter spaces are too narrow

### What v2 fixes

- **Cut 12 linkage duplicates**, replace with genuinely different physical phenomena
- **Real physics simulation** for every experiment that involves forces (Verlet, Matter.js, beam FEA)
- **Defined I/O contracts**: every experiment declares Input, Mechanism, Output, Constraints
- **Broader discovery space**: fluid, gravity-fed, magnetic, tension, elastic, optical categories

---

## 2. Technology Stack

All experiments remain **single-file HTML** for portability. Physics engines loaded from CDN.

| Library | CDN | Purpose |
|---------|-----|---------|
| p5.js 1.9.0 | `cdn.jsdelivr.net/npm/p5@1.9.0/lib/p5.min.js` | Canvas rendering, UI, interaction |
| Matter.js 0.20.0 | `cdn.jsdelivr.net/npm/matter-js@0.20.0/build/matter.min.js` | Rigid body physics (ball runs, ratchets, tipping) |

**Custom physics (inline, no library):**
- Verlet integration for particles, cables, springs, cloth, tensegrity
- RK4 integration for continuous dynamics (orbits, pendulums, oscillators)
- Euler-Bernoulli beam elements for compliant/elastic mechanisms
- SPH-lite discrete particles for fluid/sand flow

### Physics Type Assignment

| Physics Type | Experiments Using It |
|---|---|
| **Verlet particles** | Cable/Pulley, Tensegrity, Creature v2, String Art, Sand Pendulum |
| **Matter.js rigid body** | Ball Run, Tipping Balance, Ratchet & Pawl |
| **Rotary dynamics** (torque, MOI) | Gear Train, Cam Synth, Multi-Cam, Escapement, Geneva, Differential, Magnetic Gears |
| **Force fields** (per-frame) | Magnetic Pendulum, Coupled Oscillators, Three-Body |
| **Elastic FEA** (beam elements) | Compliant Flex, Bistable Array |
| **Particle flow** (discrete gravity) | Water Siphon |
| **Geometric** (no forces) | Moiré, Spirograph, Shadow Sculpture, Origami |

---

## 3. Template Changes from v1

The sidebar/canvas layout stays identical (280px sidebar, cream background, Georgia serif, `#8b4513` accents).

### New template additions:
- **I/O panel** in sidebar: shows current Input value, Output measurement, active Constraints
- **Physics info** in HUD: simulation step count, energy (kinetic + potential), force magnitudes
- **Verlet debug toggle**: shows constraint iterations, particle velocities, force vectors
- **Matter.js debug toggle**: shows collision wireframes, velocity arrows

### Randomization upgrade:
- **"Find Beautiful" v2**: scores by OUTPUT behavior (motion complexity, energy transfer efficiency, surprise factor), not just geometric shape
- **Diversity enforcement**: each new random config must differ from the last N by a minimum Hamming distance in normalized parameter space
- **Seed display**: show and allow entering random seeds for reproducibility

---

## 4. The 27 Experiments — Full Specifications

### CATEGORY A: ROTARY MECHANISMS (6 experiments)

---

#### A1. Cam Profile Synthesizer *(KEEP — minor fix)*
**File:** `exp_cam_synth_2d.html`

**Physics model:** Rotary dynamics. Cam rotates at constant ω, follower responds to profile shape. Add follower mass + return spring so the follower can bounce/separate at high speed.

```
INPUT:    Cam rotation speed (RPM), follower mass, spring stiffness
MECHANISM: Fourier cam profile r(θ) = R₀ + Σ aₖcos(kθ + φₖ)
OUTPUT:   Follower displacement curve, contact force, max acceleration
CONSTRAINT: Pressure angle < 45°, no follower jump (contact force > 0)
```

**Fix needed:** Add follower dynamics (mass + spring). Currently the follower teleports to the cam surface — it should have inertia and potentially lose contact at high speed. Display contact force in real-time. Flag designs where follower jumps off.

**Scoring v2:** Reward smooth displacement + high travel + no jump. Penalize sharp acceleration peaks.

---

#### A2. Non-Circular Gear Pair *(KEEP — OK)*
**File:** `exp_noncircular_gears_2d.html`

```
INPUT:    Input rotation speed (constant)
MECHANISM: Pitch curve r(θ) = R₀ + Σ aₖcos(kθ), conjugate gear computed
OUTPUT:   Output angular velocity ratio ω_out/ω_in as function of angle
CONSTRAINT: Convexity check, min tooth size, center distance constant
```

**No changes needed.** Physics is correct (RK4 theta integration).

---

#### A3. Gear Train Randomizer *(KEEP — OK)*
**File:** `exp_gear_train_2d.html`

```
INPUT:    Motor speed at input shaft
MECHANISM: Random spanning-tree gear topology, compound shafts
OUTPUT:   Output shaft speed and direction, total ratio
CONSTRAINT: No gear overlap, tooth counts 12-60, module consistent
```

**No changes needed.** BFS placement and velocity chain are correct.

---

#### A4. Multi-Cam Sequencer *(KEEP — OK)*
**File:** `exp_multicam_sequencer_2d.html`

```
INPUT:    Shared shaft rotation speed
MECHANISM: N cams (3-8) with independent Fourier profiles and phase offsets
OUTPUT:   N follower displacement waveforms, their phase relationships
CONSTRAINT: Pressure angle per cam < 45°, no follower separation
```

**Minor fix:** Same as A1 — add follower mass/spring to detect separation.

---

#### A5. Differential Mechanism *(KEEP — OK)*
**File:** `exp_differential_2d.html`

```
INPUT:    Two independent input speeds
MECHANISM: Bevel gear differential, ω_out = (r₁·ω₁ + r₂·ω₂)/(r₁+r₂)
OUTPUT:   Blended output speed, ratio contribution graph
CONSTRAINT: Gear ratios 0.5-3.0, max 3 cascaded stages
```

**No changes needed.**

---

#### A6. Geneva & Intermittent Motion *(NEW)*
**File:** `exp_geneva_intermittent_2d.html`

**Physics model:** Rotary dynamics with dwell. Geneva wheel has N slots; driving wheel pin engages one slot per revolution, producing indexed rotation with programmable dwell fraction.

```
INPUT:    Driver speed (RPM), slot count (3-8)
MECHANISM: Geneva cross, Maltese cross, or cam-indexer
           Angular position computed from pin-slot engagement geometry
           Dwell fraction = 1 - (slot_angle / 360°)
OUTPUT:   Output position vs time (staircase curve), dwell duration, peak angular acceleration
CONSTRAINT: Slot count 3-8, pin must clear adjacent slot, output must lock during dwell
```

**Three mechanism types:**
1. **External Geneva** — pin on driver engages radial slots on driven wheel
2. **Internal Geneva** — pin engages slots on inner surface of ring
3. **Cam indexer** — barrel cam with rise/dwell/return profile, globoidal variant

**Randomization:** Slot count, driver/driven ratio, mechanism type. Pin geometry (cylindrical vs roller). Dwell fraction emphasis.

**Scoring:** Reward smooth acceleration during index, long dwell, low peak jerk. Penalize impact forces at engagement.

---

#### A7. Magnetic Gear Pairs *(NEW)*
**File:** `exp_magnetic_gears_2d.html`

**Physics model:** Dipole field simulation. Each magnet is a point dipole with orientation. Torque between magnets computed from dipole-dipole interaction. No contact — torque transmitted through field.

```
INPUT:    Driver torque (Nm), driver magnet count, follower magnet count
MECHANISM: Two concentric rings of permanent magnets
           Torque transmission: τ = Σ (m₁ × B₂) for all magnet pairs
           Gear ratio = N_follower / N_driver (like toothed gears but contactless)
OUTPUT:   Transmitted torque, cogging torque curve, slip threshold
CONSTRAINT: Max torque before slip (magnets decouple), cogging period = LCM(N₁, N₂)
```

**Visualization:** Magnets as colored arrows (N=red, S=blue). Field lines between them. Torque graph shows cogging ripple. Slip animation when overloaded.

**Randomization:** Magnet count per ring (4-20), ring radii, magnet strength, air gap. Halbach array option (oriented to concentrate field on one side).

**Scoring:** High torque density (transmitted torque / volume), low cogging ripple, high slip threshold.

---

### CATEGORY B: TIMING & CLOCK MECHANISMS (2 experiments)

---

#### B1. Escapement Zoo *(KEEP — OK)*
**File:** `exp_escapement_zoo_2d.html`

```
INPUT:    Drive torque, pendulum length, tooth count
MECHANISM: Verge/Anchor/Deadbeat/Grasshopper escapement
OUTPUT:   Tick frequency, tick interval stability (variance), amplitude
CONSTRAINT: Pendulum amplitude 5-45°, escapement must sustain oscillation
```

**No changes needed.** Real pendulum dynamics with drive/damping.

---

#### B2. Ratchet & Pawl Networks *(NEW)*
**File:** `exp_ratchet_pawl_2d.html`

**Physics model:** Matter.js rigid body. Ratchet wheel with asymmetric teeth, pawl on spring-loaded arm. One-directional rotation. Energy stored in spring/weight, released on trigger.

```
INPUT:    Wind-up torque (manual drag or motor), release trigger
MECHANISM: Ratchet teeth engage pawl, prevent reverse rotation
           Spring/weight stores energy during wind-up
           Release: pawl lifts, stored energy drives output shaft
           Chain: ratchet₁ output → ratchet₂ input (cascaded)
OUTPUT:   Stored energy (J), release speed, output motion sequence
CONSTRAINT: Tooth geometry must prevent back-drive, pawl spring must overcome friction
```

**Visualization:** Ratchet wheel with visible teeth, animated pawl clicking. Spring shown as coil getting tighter during wind-up. Energy bar fills up. On release, unwinding animation with speed graph.

**Randomization:** Tooth count (6-24), tooth angle (asymmetric), pawl spring stiffness, number of cascaded ratchets, gear ratios between stages.

**Scoring:** Energy storage capacity, release smoothness, cascade timing precision.

---

### CATEGORY C: WAVE & OSCILLATION (3 experiments)

---

#### C1. Three-Body Orrery *(KEEP — OK)*
**File:** `exp_three_body_2d.html`

```
INPUT:    Mass, position, velocity for 3 bodies
MECHANISM: Newtonian gravity F = G·m₁·m₂/r², RK4 integration
OUTPUT:   Orbital paths, ejection detection, Lyapunov time estimate
CONSTRAINT: Softening parameter prevents singularity, energy conservation check
```

**No changes needed.** RK4 is correct, presets are good.

---

#### C2. Magnetic Pendulum *(KEEP — OK)*
**File:** `exp_magnetic_pendulum_2d.html`

```
INPUT:    Starting position (click on basin map)
MECHANISM: Spring restoring + magnetic attraction + damping
OUTPUT:   Which magnet captures the pendulum, basin boundary fractal
CONSTRAINT: Height > 0 (magnets below plane), damping > 0 (must settle)
```

**No changes needed.** Progressive basin rendering is correct.

---

#### C3. Coupled Oscillators *(KEEP — OK)*
**File:** `exp_coupled_oscillators_2d.html`

```
INPUT:    N oscillators, coupling strength K, topology
MECHANISM: Kuramoto model dθᵢ/dt = ωᵢ + (K/N)·Σ sin(θⱼ - θᵢ)
OUTPUT:   Order parameter R(t), sync/desync transition
CONSTRAINT: N ≤ 50, adjacency list (not matrix)
```

**No changes needed.**

---

### CATEGORY D: CHAOS & DYNAMICS (2 experiments)

---

#### D1. Bistable Snap-Through Array *(KEEP — OK)*
**File:** `exp_bistable_array_2d.html`

```
INPUT:    Click element to trigger, coupling strength
MECHANISM: Double-well potential U(x) = -ax²/2 + bx⁴/4, neighbor coupling
OUTPUT:   Cascade pattern, percentage snapped, propagation wavefront
CONSTRAINT: Stable equilibria at x = ±1, damping prevents unbounded growth
```

**No changes needed.**

---

#### D2. Rattleback Cascade *(KEEP — OK)*
**File:** `exp_rattleback_cascade_2d.html`

```
INPUT:    Initial spin direction (click to trigger)
MECHANISM: Asymmetric coupling converts spin → rock → reverse spin
OUTPUT:   Reversal cascade pattern through network
CONSTRAINT: Asymmetry parameter > 0, damping prevents infinite energy
```

**No changes needed.**

---

### CATEGORY E: STRING, CABLE & TENSION (3 experiments)

---

#### E1. Cable & Pulley Network *(REBUILD)*
**File:** `exp_cable_pulley_2d.html`

**Physics model:** Verlet particle chain. Cable = chain of N particles with distance constraints. Pulleys = fixed circular obstacles that cable wraps around. Free pulleys move under gravity + cable tension.

```
INPUT:    Pull force on cable end (drag handle), pulley layout
MECHANISM: Cable particles connected by distance constraints (Verlet)
           Each timestep: (1) apply gravity to all particles
           (2) enforce distance constraints (10-20 iterations)
           (3) enforce pulley wrap constraints (project particles onto pulley surface)
           Fixed pulleys: cable redirects, free pulleys: cable lifts weight
OUTPUT:   Mechanical advantage (output force / input force), cable path, tension distribution
CONSTRAINT: Cable inextensible (Verlet constraints), cable cannot push (tension only), friction optional
```

**Key implementation details:**
- Cable = 50-100 Verlet particles, spacing ~5px
- Pulley wrap: when particle is inside pulley circle, project onto surface + apply tangent constraint
- Free pulley: its position is the average of cable forces pulling on it minus gravity × mass
- MA computation: count load-bearing cable segments on free pulley
- Cable sag: natural consequence of gravity on Verlet particles (no fake sag needed)

**Randomization:** Pulley count (3-10), fixed vs free distribution, positions, radii. Cable routing order.

**Scoring:** High MA, cable path efficiency (short total length), stable equilibrium (low oscillation amplitude after settling).

---

#### E2. Tensegrity Builder *(NEW)*
**File:** `exp_tensegrity_2d.html`

**Physics model:** Verlet particles (nodes) with two constraint types: struts (rigid distance, resist compression + tension) and cables (enforce max distance, resist tension only — can go slack).

```
INPUT:    Strut count (3-8), cable tension, external load
MECHANISM: Strut endpoints + cable connections form self-stressed structure
           Equilibrium found by iterating Verlet constraints until stable
           Cables: d ≤ d_rest (can go shorter, cannot stretch)
           Struts: d = d_rest (rigid, both directions)
OUTPUT:   Stable structure shape, stress distribution, load capacity
CONSTRAINT: Structure must be self-stable (no external support except gravity floor)
           Cables cannot push, struts cannot bend
```

**Visualization:** Struts as thick gray bars, cables as thin brown lines (thickness ∝ tension). Slack cables shown dashed. Nodes as circles. Force arrows on loaded nodes. Color-coded stress (blue=compression on struts, red=tension on cables).

**Interaction:** Drag any node to deform. Release to watch it spring back (or collapse if unstable). Apply gravity toggle. Apply point load by clicking.

**Randomization:** Node count (6-16), strut/cable ratio, rest lengths, initial layout (random within circle, then relax to equilibrium).

**Scoring:** Stability (returns to shape after perturbation), load capacity (max force before collapse), aesthetic symmetry.

---

#### E3. String Art Machine *(NEW)*
**File:** `exp_string_art_2d.html`

**Physics model:** Geometric (pin placement) + Verlet (string tension/sag).

```
INPUT:    Pin count (10-50), winding rule (every Nth pin), string tension
MECHANISM: Pins arranged on circle/line/shape boundary
           String connects pin_i to pin_(i+K) for K = winding number
           Each string is a Verlet chain (3-5 particles) so it sags under gravity
           Multiple string layers with different K values and colors
OUTPUT:   Envelope curve (Bézier family), string density pattern
CONSTRAINT: Strings cannot cross pins (wrap around if needed), tension > 0
```

**Winding rules:**
1. **Modular arithmetic:** connect pin i to pin (i+K) mod N
2. **Multiplication table:** connect i to (i×K) mod N
3. **Fibonacci:** connect i to pin at Fibonacci index
4. **Cardioid:** connect i to (2i) mod N (creates cardioid envelope)

**Visualization:** Pins as small brown circles on boundary. Strings as thin lines (Verlet particles if sag enabled, straight lines if taut). Envelope curve shown as faint overlay. Color per layer.

**Randomization:** Pin count, boundary shape (circle/ellipse/square/polygon), winding rule, K value, number of layers, string tension.

**Scoring:** Envelope complexity (curvature variation), density uniformity, aesthetic balance.

---

### CATEGORY F: GRAVITY-FED & FLUID (3 experiments)

---

#### F1. Water Siphon Cascade *(NEW)*
**File:** `exp_water_siphon_2d.html`

**Physics model:** Discrete particle flow. Water = collection of small circles that obey gravity + fluid pressure approximation. Siphon tube = fixed boundary. Particles flow through tubes when connected reservoir is higher than outlet.

```
INPUT:    Reservoir heights, tube diameters, valve open/close
MECHANISM: Gravity drives fluid from high to low through siphon tubes
           Siphon principle: once primed (tube full), fluid flows upward over crest
           Flow rate ∝ sqrt(2g·Δh) where Δh = height difference
           Cascade: output of siphon₁ fills reservoir₂, triggers siphon₂
OUTPUT:   Flow rate at each stage, fill levels, cascade timing sequence
CONSTRAINT: Siphon breaks if air enters (reservoir drops below tube inlet)
           Flow stops when Δh = 0
```

**Particle implementation:**
- 200-500 small circles (r=3px) per reservoir
- Gravity: `vy += g * dt`
- Collision: particles bounce off walls + each other (simple overlap resolution)
- Tube flow: particles inside tube follow tube centerline with Poiseuille-like speed profile
- Siphon priming: manual (click to prime) or auto (when reservoir level reaches tube inlet)

**Layout:** 3-6 reservoirs at different heights, connected by curved siphon tubes. Tipping buckets as alternative triggers (bucket tips when full, dumping into next reservoir).

**Randomization:** Reservoir count (3-6), heights, tube diameters, layout (cascading left→right, zigzag, tree), tipping bucket inclusion.

**Scoring:** Longest cascade chain, most interesting timing pattern, self-resetting capability (water returns to start via lowest reservoir pump).

---

#### F2. Ball Run / Marble Machine *(NEW)*
**File:** `exp_ball_run_2d.html`

**Physics model:** Matter.js rigid body engine. Balls = circles with mass, restitution, friction. Track elements = static bodies (ramps, funnels, bumpers, gates).

```
INPUT:    Ball drop position, track element placement
MECHANISM: Gravity + collisions on rigid body track
           Ramp: inclined plane, ball rolls and accelerates
           Funnel: converging walls, ball centers and drops
           Bumper: circular obstacle with restitution > 1 (spring-loaded)
           Gate: timed barrier that opens/closes (via cam or timer)
           Spiral: helical descent around central column
           Jump: ramp launch → parabolic flight → landing zone
OUTPUT:   Ball transit time, path taken, exit speed, split ratios at forks
CONSTRAINT: Ball must reach exit without stopping, track elements cannot overlap
```

**Track elements (randomizable):**
1. **Straight ramp** — angle 10-60°, length 50-200px
2. **Curved ramp** — circular arc, radius 50-150px
3. **Funnel** — V-shape, narrows to one ball width
4. **Bumper field** — grid of circular pegs (Galton board)
5. **Seesaw** — balanced beam, ball tips one side, other side launches waiting ball
6. **Tipping bucket** — fills with ball weight, tips and releases
7. **Loop** — circular loop (ball needs minimum entry speed)
8. **Fork** — path splits, ball takes path based on speed/position

**Randomization:** Element count (5-15), types, positions, angles, connections. Ball count (1-5), drop timing.

**Scoring:** Path complexity (number of elements touched), transit time variance (interesting = inconsistent), visual drama (loops, jumps, close calls).

---

#### F3. Tipping Balance Automata *(NEW)*
**File:** `exp_tipping_balance_2d.html`

**Physics model:** Matter.js rigid body. Balance beams on pivot points. Weights (balls/blocks) roll or slide onto beam arms. When one side outweighs, beam tips, triggering next stage.

```
INPUT:    Weight drop position (or continuous flow like sand/water particles)
MECHANISM: Balance beam: pivot at center, arms of length L₁, L₂
           Torque: τ = Σ(mᵢ × gᵢ × dᵢ) where dᵢ = distance from pivot
           Tips when net torque exceeds friction threshold
           Tipping dumps contents into next balance's input
           Cascade: balance₁ tips → weight falls to balance₂ → tips → ...
OUTPUT:   Tipping sequence timing, cascade pattern, final state
CONSTRAINT: Pivot friction prevents instant tipping, beam has angular limits (±45°)
```

**Layout:** 5-12 balance beams arranged in cascade (high to low). Some parallel (simultaneous tipping), some serial (one triggers next). Weights accumulate from dripping source (particles) or discrete balls.

**Randomization:** Beam count (5-12), arm ratios (L₁/L₂ from 0.5 to 2.0), pivot positions, weight sources, cascade topology.

**Scoring:** Longest cascade chain, most simultaneous tips, self-resetting ability (tipped beams return to neutral after dumping).

---

### CATEGORY G: ELASTIC & COMPLIANT (2 experiments)

---

#### G1. Compliant Mechanism Explorer *(REBUILD)*
**File:** `exp_compliant_flex_2d.html`

**Physics model:** Euler-Bernoulli beam elements. Each beam = chain of N rigid segments connected by torsional springs. Bending stiffness EI determines spring constant at each joint. NOT rigid bar linkages.

```
INPUT:    Applied force (drag input point), beam stiffness EI
MECHANISM: Flexible beam network where motion is transmitted through elastic deformation
           Each joint: τ = -EI × (θ - θ_rest) / L_segment
           Damping: τ_damp = -c × dθ/dt
           Force propagation: input force bends beam₁, which pushes on beam₂, etc.
OUTPUT:   Displacement amplification ratio (output motion / input motion)
          Stress distribution (curvature at each point)
          Fatigue indicator (max stress / yield stress)
CONSTRAINT: Max stress < yield (no permanent deformation), no self-intersection
```

**Key difference from v1:** v1 used rigid bars with pin joints (a linkage, not a compliant mechanism). v2 uses flexible beams that BEND continuously. The deformation IS the mechanism.

**Compliant mechanism types:**
1. **Lever amplifier** — input force at one end, output motion at other end, pivot region bends
2. **Bistable switch** — two stable positions, snap-through when pushed past center
3. **Compliant gripper** — two flexible arms that close when squeezed at base
4. **Displacement inverter** — push in → output moves opposite direction

**Randomization:** Beam topology (series/parallel/branching), stiffness per segment, beam lengths, constraint positions (where beams attach to ground).

**Scoring:** Amplification ratio, energy efficiency (output work / input work), stress safety factor.

---

#### G2. Bistable Array — already kept, see D1 above.

---

### CATEGORY H: OPTICAL & GEOMETRIC (3 experiments)

---

#### H1. Moiré Patterns *(KEEP — OK)*
**File:** `exp_moire_2d.html`

```
INPUT:    Pattern type, spacing, rotation angle, speed
MECHANISM: Two overlapping periodic patterns create interference
OUTPUT:   Apparent motion direction and speed, fringe spacing
CONSTRAINT: Line count limited to ~60 for performance
```

**No changes needed.**

---

#### H2. Spirograph Deep *(KEEP — OK)*
**File:** `exp_spirograph_deep_2d.html`

```
INPUT:    Circle count (2-8), radii, pen offset
MECHANISM: Nested rolling circles (epicycles/hypocycles)
OUTPUT:   Traced curve, closure detection, harmonic analysis
CONSTRAINT: Pen must stay within canvas bounds
```

**No changes needed.**

---

#### H3. Shadow Sculpture *(NEW)*
**File:** `exp_shadow_sculpture_3d.html`

**Physics model:** Geometric ray casting (p5.js WEBGL). 3D object blocks parallel light rays, creating 2D shadow on projection plane.

```
INPUT:    3D shape (random voxel/mesh), light direction (2 angles), rotation speed
MECHANISM: Parallel ray projection from light source through 3D object onto ground plane
           Shadow = 2D silhouette of 3D shape from light's perspective
           As object rotates, shadow morphs continuously
OUTPUT:   Shadow outline, shadow area, silhouette complexity
CONSTRAINT: Light is directional (parallel rays, not point source), object fits within unit sphere
```

**3D shape generation:**
1. **Random voxels** — 5-20 cubes stacked/arranged in 3D grid, random occupancy
2. **Wireframe** — random edges connecting vertices on unit sphere surface
3. **Extruded profile** — 2D random curve extruded along axis with twist
4. **Boolean** — union/difference of 3-5 primitive shapes (sphere, box, cylinder)

**Interaction:** Drag to orbit view. Light direction slider (azimuth + elevation). Object auto-rotates. Shadow shown on ground plane below object. Option to show multiple shadow projections (front + side + top = engineering drawing view).

**Randomization:** Shape type, voxel count, vertex positions, extrusion twist, boolean operations.

**Scoring:** Shadow complexity (perimeter/sqrt(area)), shadow variety (how much it changes during rotation), recognizability (does it look like something?).

---

### CATEGORY I: DEPLOYABLE & STRUCTURAL (2 experiments)

---

#### I1. Origami / Deployable Mechanism *(NEW)*
**File:** `exp_origami_deployable_2d.html`

**Physics model:** Rigid origami — flat panels connected by fold lines (hinges). Each fold has an angle that changes during deployment. Panels are rigid; only folds flex.

```
INPUT:    Fold pattern type, deployment slider (0% = flat, 100% = fully deployed)
MECHANISM: Rigid panels connected at fold lines (hinges)
           Deployment: one driven fold angle controls all others via geometric constraints
           Kinematics: given θ_driver, compute all other fold angles via constraint equations
OUTPUT:   Deployed shape, fold angles, panel stress (deviation from flat)
CONSTRAINT: No panel-panel intersection, all folds must be compatible (1 DOF)
```

**Fold patterns:**
1. **Miura-ori** — chevron pattern, compresses in both X and Y simultaneously
2. **Yoshizawa** — radial folds from center, opens like flower
3. **Waterbomb** — alternating mountain/valley, creates 3D tube
4. **Random** — Voronoi-based fold lines with random mountain/valley assignment (may have multi-DOF)

**Visualization:** 2D flat view (showing fold lines as dashed = mountain, solid = valley) + 2D side view showing cross-section during deployment. Color panels by fold angle.

**Randomization:** Pattern type, grid size (3×3 to 8×8), fold angles, deployment range.

**Scoring:** Compaction ratio (flat area / deployed area), structural stiffness in deployed state, aesthetic symmetry.

---

#### I2. Tensegrity Builder — see E2 above.

---

### CATEGORY J: EVOLUTIONARY & GENERATIVE (2 experiments)

---

#### J1. Creature Evolver v2 *(NEW — replaces broken v1)*
**File:** `exp_creature_evolver_2d.html`

**Physics model:** Verlet particles + distance constraints + ground collision. Creature = graph of mass nodes connected by spring-muscles. Muscles oscillate length sinusoidally. Ground = flat floor with friction.

```
INPUT:    Fitness function selection, mutation rate, population size
MECHANISM: Genome encodes: node positions, connections, muscle frequency/phase/amplitude
           Simulation: Verlet integration with gravity + ground collision + friction
           Muscles: rest_length oscillates as L₀ + A·sin(ωt + φ)
           Ground: if node.y > ground_y, push up + apply friction to vx
OUTPUT:   Distance traveled in T seconds, best/avg/worst fitness over generations
CONSTRAINT: Max 20 nodes, max 40 connections, creature must start above ground
```

**Key difference from v1:** v1 used kinematic linkages (no forces, no ground). v2 has:
- Real gravity pulling nodes down
- Ground collision with friction (creature must push against ground to move)
- Spring-muscles that contract/expand (not just rotating joints)
- Mass at each node (heavy creatures are harder to move)
- Energy cost (total muscle work) as optional fitness penalty

**Fitness functions:**
1. **Distance** — max X displacement of center of mass
2. **Speed** — distance / time
3. **Efficiency** — distance / total muscle energy
4. **Height** — max Y achieved by any node (jumping)

**Genetic operations:**
- Elitism: top 10% survive unchanged
- Crossover: graph merge (take nodes from parent1, connections from parent2)
- Mutation: add/remove node (5%), add/remove connection (10%), perturb muscle params (20%), perturb node mass (10%)
- Speciation: creatures grouped by topology similarity, compete within species

**Atlas mode:** Top 16 creatures animated with motion trails. Color by species.

---

#### J2. Sand Pendulum Harmonograph *(NEW)*
**File:** `exp_sand_pendulum_2d.html`

**Physics model:** Damped compound pendulum (2 pendulums at 90°, one for X, one for Y). Sand grains deposited at pendulum tip position each frame.

```
INPUT:    Pendulum lengths (L₁, L₂), initial amplitudes (A₁, A₂), damping rate
MECHANISM: X = A₁·e^(-γt)·sin(ω₁t + φ₁), Y = A₂·e^(-γt)·sin(ω₂t + φ₂)
           where ω = sqrt(g/L), γ = damping coefficient
           Sand grain deposited at (X,Y) each frame as small circle
OUTPUT:   Lissajous-like sand pattern, frequency ratio ω₁/ω₂, decay envelope
CONSTRAINT: Pattern must fit on canvas, damping must reach < 1% amplitude within time limit
```

**Key feature:** The sand ACCUMULATES. Unlike a regular harmonograph that draws a line, this deposits discrete grains. Where the pendulum moves slowly (near extremes), sand piles up denser. Where it moves fast (center crossings), sand is sparse. This creates natural density gradients.

**Visualization:** Canvas starts as dark brown surface. Sand grains are small tan circles (r=2px) with slight random jitter. Density builds up over time. Option to color grains by deposition time (early = light, late = dark) or by speed (slow = thick, fast = thin).

**Randomization:** L₁, L₂ (frequency ratio), initial amplitudes, phases, damping, rotary vs Cartesian compound configuration.

**Scoring:** Pattern complexity (unique positions / total grains), symmetry score, coverage area, aesthetic density variation.

---

### CATEGORY K: REMAINING UNIQUE (1 experiment)

---

#### K1. Escapement Zoo — see B1 above.

---

### FULL SUITE SUMMARY (27 experiments)

| # | Name | File | Category | Physics | Status |
|---|------|------|----------|---------|--------|
| 01 | Cam Profile Synthesizer | exp_cam_synth_2d.html | Rotary | Rotary + follower dynamics | FIX |
| 02 | Non-Circular Gears | exp_noncircular_gears_2d.html | Rotary | RK4 theta | KEEP |
| 03 | Gear Train Randomizer | exp_gear_train_2d.html | Rotary | BFS velocity chain | KEEP |
| 04 | Multi-Cam Sequencer | exp_multicam_sequencer_2d.html | Rotary | Rotary + follower | FIX |
| 05 | Differential Mechanism | exp_differential_2d.html | Rotary | Bevel gear math | KEEP |
| 06 | Geneva & Intermittent | exp_geneva_intermittent_2d.html | Rotary | Pin-slot engagement | NEW |
| 07 | Magnetic Gear Pairs | exp_magnetic_gears_2d.html | Rotary | Dipole field | NEW |
| 08 | Escapement Zoo | exp_escapement_zoo_2d.html | Timing | Pendulum dynamics | KEEP |
| 09 | Ratchet & Pawl Networks | exp_ratchet_pawl_2d.html | Timing | Matter.js rigid body | NEW |
| 10 | Three-Body Orrery | exp_three_body_2d.html | Oscillation | RK4 N-body | KEEP |
| 11 | Magnetic Pendulum | exp_magnetic_pendulum_2d.html | Oscillation | Force field | KEEP |
| 12 | Coupled Oscillators | exp_coupled_oscillators_2d.html | Oscillation | Kuramoto ODE | KEEP |
| 13 | Bistable Array | exp_bistable_array_2d.html | Chaos | Double-well potential | KEEP |
| 14 | Rattleback Cascade | exp_rattleback_cascade_2d.html | Chaos | Spin-rock coupling | KEEP |
| 15 | Cable & Pulley Network | exp_cable_pulley_2d.html | Tension | Verlet cable | REBUILD |
| 16 | Tensegrity Builder | exp_tensegrity_2d.html | Tension | Verlet strut+cable | NEW |
| 17 | String Art Machine | exp_string_art_2d.html | Tension | Geometric + Verlet sag | NEW |
| 18 | Water Siphon Cascade | exp_water_siphon_2d.html | Fluid/Gravity | Particle flow | NEW |
| 19 | Ball Run / Marble Machine | exp_ball_run_2d.html | Fluid/Gravity | Matter.js rigid body | NEW |
| 20 | Tipping Balance Automata | exp_tipping_balance_2d.html | Fluid/Gravity | Matter.js rigid body | NEW |
| 21 | Compliant Flex Explorer | exp_compliant_flex_2d.html | Elastic | Euler-Bernoulli beam | REBUILD |
| 22 | Moiré Patterns | exp_moire_2d.html | Optical | Geometric interference | KEEP |
| 23 | Spirograph Deep | exp_spirograph_deep_2d.html | Optical | Rolling circles | KEEP |
| 24 | Shadow Sculpture | exp_shadow_sculpture_3d.html | Optical | Ray projection (WEBGL) | NEW |
| 25 | Origami / Deployable | exp_origami_deployable_2d.html | Structural | Rigid fold kinematics | NEW |
| 26 | Creature Evolver v2 | exp_creature_evolver_2d.html | Evolution | Verlet + GA | NEW (replace) |
| 27 | Sand Pendulum | exp_sand_pendulum_2d.html | Generative | Damped oscillation | NEW |

**Totals:** 13 KEEP, 2 FIX, 2 REBUILD, 10 NEW (+ 2 NEW replacing existing files)

---

## 5. Files to Delete

These 12 files will be removed (they are the linkage duplicates and pure math experiments):

```
exp_coupler_curves_2d.html      → replaced by Geneva & Intermittent
exp_compound_coupler_2d.html    → replaced by Ball Run
exp_linkage_lab_2d.html         → replaced by Tensegrity
exp_walker_gait_2d.html         → replaced by String Art
exp_straight_line_2d.html       → replaced by Ratchet & Pawl
exp_pantograph_chain_2d.html    → replaced by Water Siphon
exp_automata_figure_2d.html     → replaced by Tipping Balance
exp_lsystem_linkage_2d.html     → replaced by Origami
exp_polar_curves_2d.html        → replaced by Sand Pendulum
exp_superformula_2d.html        → replaced by Magnetic Gears
exp_math_drivers_2d.html        → replaced by Shadow Sculpture
exp_kinematic_tiles_2d.html     → merged into Bistable (tile propagation concept)
```

Also remove the old extra files from before this project:
```
exp_chaos_garden_3d.html        → duplicate of coupled oscillators concept
exp_harmonograph_3d.html        → replaced by Sand Pendulum (same physics, better output)
exp_lorenz_attractor_3d.html    → pure math, no mechanism
```

---

## 6. Three-Layer Physics Verification Stack

### Layer 1: Python Reference Scripts (build-time)

Small scripts per physics type (~50-100 lines each). Run ONCE during development to generate
ground truth test vectors. Located in `physics_verify/`.

```
physics_verify/
  verify_verlet_cable.py      — expected cable sag shape for given params
  verify_rk4_orbit.py         — expected orbital path for 3-body presets
  verify_beam_deflection.py   — Euler-Bernoulli expected deflection curve
  verify_matter_collision.py  — expected bounce trajectory (ball run)
  verify_dipole_torque.py     — expected magnetic gear torque curve
  verify_pendulum_period.py   — expected period vs analytical T=2pi*sqrt(L/g)
  verify_siphon_flow.py       — expected Torricelli flow rate Q=A*sqrt(2g*h)
  verify_verlet_tensegrity.py — expected equilibrium shape for strut+cable network
```

Each script outputs JSON: `{input_params, expected_state_at_t[], expected_energy_at_t[]}`.
JavaScript implementation tested against these during development.

**Dependencies:** numpy, scipy only. No exotic packages.

### Layer 2: In-Browser Physics HUD (runtime)

Every experiment displays real-time physics health:

```
Energy: 142.3 J (±0.2%)     ← conservation check (green/yellow/red)
Constraints: 0.001 mm        ← max constraint violation
Forces: Sigma = 0.003 N      ← equilibrium check
dt: 0.016s (stable)          ← timestep health
```

Thresholds:
- Energy drift > 5% → HUD turns yellow (warning)
- Energy drift > 20% → HUD turns red (physics broken)
- Constraint violation > 1mm → orange warning
- Constraint violation > 5mm → red, simulation paused
- Force imbalance > 1N at equilibrium → yellow warning

### Layer 3: Analytical Checks (in-code comments)

For systems with known solutions, code includes expected results as comments:

```javascript
// ANALYTICAL CHECK: pendulum L=100mm, g=9810mm/s^2
// T = 2*PI*sqrt(L/g) = 2*PI*sqrt(100/9810) = 0.634s
// Simulated period must be within 2% (0.621 - 0.647s)
```

---

## 7. Quality Gates

Every experiment must pass ALL before delivery:

1. **I/O declaration** — Input, Mechanism, Output, Constraint clearly shown in sidebar
2. **Physics verification (Layer 1)** — Python test vectors match JS output within tolerance
3. **Runtime health (Layer 2)** — HUD shows green for 60 seconds of simulation
4. **Diversity check** — "Randomize" must produce visually distinct results 5/5 times
5. **Find Beautiful v2** — scoring uses OUTPUT behavior metrics, not just shape complexity
6. **Performance** — 30+ FPS on GTX 1650, < 500K polygons if WEBGL
7. **Interaction** — at least one slider meaningfully changes behavior in real-time
8. **Atlas variety** — 16-cell atlas must show at least 4 visually distinct categories
9. **Analytical check (Layer 3)** — known solutions verified in code comments

---

## 7. Build Order

**Wave 1 — Physics foundations (build Verlet + Matter.js helpers first):**
- Cable/Pulley rebuild (validates Verlet)
- Ball Run (validates Matter.js)
- Creature Evolver v2 (validates Verlet + GA)

**Wave 2 — Gravity & fluid:**
- Water Siphon Cascade
- Tipping Balance Automata

**Wave 3 — Tension & structure:**
- Tensegrity Builder
- String Art Machine
- Compliant Flex rebuild

**Wave 4 — Rotary & timing:**
- Geneva & Intermittent
- Magnetic Gear Pairs
- Ratchet & Pawl

**Wave 5 — Visual & generative:**
- Shadow Sculpture (WEBGL)
- Origami / Deployable
- Sand Pendulum

**Wave 6 — Fix existing:**
- Cam Synth (add follower dynamics)
- Multi-Cam Sequencer (add follower dynamics)

**Wave 7 — Cleanup:**
- Delete 12 old files
- Update index page
- Final verification pass
