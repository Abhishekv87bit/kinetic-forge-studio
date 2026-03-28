# Murmuration Engine -- Physics-Driven Mechanism Specification

## Design Philosophy (LEAP 71 / Noyron approach)
This specification defines WHAT the mechanism must achieve through physics, forces,
and motion profiles. The solver determines HOW -- topology, link geometry, component
count. Think DNA, not blueprint.

---

## 1. OUTPUT BEHAVIOR

A ceiling-hung installation: a dense field of small chrome spheres hangs on thin
steel rods beneath a hidden mechanism housing. When the motor runs, coordinated wave
patterns ripple through the ball field -- mimicking starling murmuration. From 2-3m
below, the observer sees a coherent undulating shape whose internal structure is
individual balls moving up and down. The wave pattern never visibly repeats.

Resting state (motor off): all balls hang at maximum extension under gravity -- a
flat, uniform disc of spheres. Active state: the mechanism retracts and extends rods,
creating traveling interference waves across the field.

---

## 2. SCALE & INSTALLATION

### Prototype (800mm diameter, ceiling-hung, multi-part 3D print)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Overall diameter | 800 mm | Ceiling-hung disc |
| Ball field diameter | 750 mm | After 25mm structural ring on each side |
| Ball field shape | Hexagonal (NOT rectangular) | Organic silhouette, 6-fold symmetry matches murmuration topology |
| Ball field layout | Hex-packed, 17 rings | 3(289) + 51 + 1 = 919 balls at 22mm pitch |
| Ball pitch | 22 mm center-to-center | Sweet spot: 919 balls, 2+ visible wavelengths |
| Mechanism housing depth | 100-150 mm | Above guide plate (hidden from below) |
| Rod hang length | 80-120 mm | Below guide plate (visible) |
| Ball stroke | 40-50 mm | Of the rod hang length |
| Total Z (housing + plate + rods + balls) | ~220-300 mm | No 350mm constraint -- assembled, not single print |
| Orientation | Mechanism on TOP (hidden), balls hang BELOW (visible) | Viewer looks up |

### Print Tiling (Creality K2 Plus: 350 x 350 x 350 mm)

| Component | Tiling strategy | Sections |
|-----------|----------------|----------|
| Guide plate (800mm disc) | Center hex + 6 petal tiles (~300mm each) | 7 |
| Mechanism housing | Mirrors guide plate tiling | 7 |
| Structural ring frame | 6 arc segments (~420mm arc x 40mm wide) | 6 |
| Mechanism internals | Gears, shafts, cam assemblies | ~6-10 |
| **Total printed parts** | | **~26-30** |

Assembly: M3 bolts + alignment pins + interlocking dovetail features between tiles.
Each tile fits within 350 x 350 x 350 mm print volume.

### Production (Machine Shop)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Ball field diameter | 1200-1800 mm | 1.5-2.25x prototype scale |
| Grid | Hex-packed: 27-ring = ~2,269, 40-ring = ~4,921 | More rings = more balls |
| Ball pitch | 22 mm (same as prototype) | Scale = more balls, not bigger balls |
| Materials | Steel rods, machined cams/gears, brass linkages, hardwood frame | |
| Mechanism | Machined steel/aluminum, metal bearings | |

---

## 3. VISUAL PARAMETERS

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Ball diameter | 10 mm | Visible as particles from 2-3m, reads as cloud in peripheral vision |
| Ball material (proto) | Chrome steel ball bearing | 4g weight, reflective, standard size |
| Ball material (prod) | Matte black steel or anodized aluminum | Murmuration = dark mass against light sky |
| Ball weight | ~4 g | 10mm chrome steel bearing ball |
| Guide rod diameter | 1.0 mm spring steel (piano wire) | Near-invisible from 2-3m viewing distance |
| Rod length (below guide plate) | 80-120 mm | Long enough for stroke + visual separation from housing |
| Stroke | +/- 20-25 mm from neutral (40-50 mm total) | Visible wave depth |
| Viewing distance | 2-3 m below (gallery ceiling height) | |
| Aesthetic reference | Starling murmuration: dense, dark, undulating blob | NOT individual-element art like Kinetic Rain |

### Why rods, not ropes

Ropes/cables can only transmit TENSION (pull). They go slack under compression.
For bidirectional wave control, the mechanism must both RETRACT rods (pull up) and
EXTEND rods (push down) with equal authority. Steel rods transmit both tension and
compression. This eliminates the need for gravity return or spring return -- the
mechanism has full force authority in both directions at all times.

Buckling check (1mm steel rod, 120mm unsupported length):
- Euler critical load P_cr = pi^2 * E * I / L^2
- P_cr = pi^2 * 200 GPa * (pi/64 * 1mm^4) / (120mm)^2 = 0.67 N
- Peak mechanism force per rod: 0.35 N
- Safety factor: 1.9x (passes)

---

## 4. MOTION REQUIREMENTS

### Real murmuration physics (reference)
- Wave propagation across flock: 20-40 m/s
- Individual bird reaction: < 100 ms
- Each bird tracks 6-7 nearest neighbors (topological, not metric)
- Flock turn time (400 birds): ~0.5 seconds

### Scaled to 800mm prototype field

| Parameter | Value | Derivation |
|-----------|-------|-----------|
| Wave crossing time (fast) | 200-400 ms | 800mm at 2-4 m/s apparent wave speed |
| Wave crossing time (slow) | 800-3000 ms | Gentle undulation mode |
| Single ball full-stroke time | 50-150 ms | Ball travels 40-50mm in this time |
| Peak ball velocity | 0.3-1.0 m/s | 40mm / 0.1s = 0.4 m/s typical |
| Peak ball acceleration | 1-4 g | Sinusoidal profile at 5-15 Hz |
| Oscillation frequency range | 3-15 Hz | 3 Hz = gentle, 15 Hz = fast murmuration |
| Visible wavelengths across field | ~2 | At k = 20 deg/pitch: wavelength = 18 pitches = 396mm; 750mm / 396mm = ~1.9 |
| Force per rod -- retract (peak) | 0.35 N | F_accel + F_gravity = 0.31 + 0.04 N |
| Force per rod -- extend (peak) | 0.27 N | F_accel - F_gravity = 0.31 - 0.04 N |
| Total force (919 balls, peak) | ~35-65 N | Phase spread means ~20-40% at peak simultaneously |

### CRITICAL CONSTRAINT: Positive drive BOTH directions

Gravity return is EXCLUDED. Rods, not ropes. The mechanism must provide controlled
force authority in both retract (up) and extend (down) directions.

In ceiling-hung orientation, gravity assists extension and opposes retraction. This
makes the force profile asymmetric (retract: 0.35 N, extend: 0.27 N). Without
desmodromic drive, wave peaks (retracted balls) would look visually different from
wave valleys (extended balls) -- destroying the symmetric murmuration illusion.

---

## 5. MATHEMATICAL MODEL

Per ball at hex grid position (q, r) using axial coordinates, vertical displacement:

```
z(q, r, t) = SUM_{n=1}^{3} A_n * sin(omega_n * t + k_n * (x(q,r)*cos(theta_n) + y(q,r)*sin(theta_n)))

where:
  x(q, r) = pitch * (q + r/2)
  y(q, r) = pitch * (r * sqrt(3)/2)
```

| Symbol | Meaning | Value/Range |
|--------|---------|-------------|
| (q, r) | Hex axial coordinates | Integer pairs; q^2 + qr + r^2 <= ring_count^2 |
| A_n | Amplitude per channel | 7-10 mm each (summed peak: +/- 20-25mm) |
| omega_n | Angular frequency | omega_1 = base, omega_2 = omega_1 * phi, omega_3 = omega_1 * sqrt(2) |
| k_n | Spatial wavenumber | 15-25 deg per ball pitch (controls wave "wavelength" across field) |
| theta_n | Wave travel direction | 0, 120, 240 deg (aligned with hex grid's 3 principal axes) |
| phi | Golden ratio | 1.6180339887... (maximally quasi-periodic per KAM theorem) |

### Why 0/120/240 degrees?

A hex grid has 3 natural symmetry axes at 0, 60, 120 degrees. The wave directions
0, 120, 240 align with alternating hex axes, meaning each traveling wave propagates
along rows of balls that share a hex axis. This is geometrically optimal: each helical
shaft or swashplate naturally drives one row of balls along its axis, and the 120-degree
separation maximizes interference complexity.

### Quasi-periodic frequency generation

Approximate irrational ratios with coprime gear teeth:

| Ratio target | Gear teeth | Actual ratio | Error vs ideal | Repeat cycle (revolutions) |
|-------------|-----------|-------------|----------------|--------------------------|
| 1 : phi | 55 : 89 | 1.61818... | 0.007% | 4,895 |
| 1 : sqrt(2) | 99 : 140 | 1.41414... | 0.005% | 13,860 |
| 1 : phi^2 (alt.) | 55 : 144 | 2.61818... | 0.007% | 7,920 |
| **Combined** (phi + sqrt(2)) | 55, 89, 99, 140 | -- | -- | **LCM = 1,233,540** |

Combined repeat cycle: ~1.23 million input revolutions. At 300 RPM motor speed,
the pattern takes **68+ hours** of continuous operation to exactly repeat.
Effectively non-repeating for any gallery exhibition.

---

## 6. MECHANISM FUNCTIONAL BLOCKS

The mechanism must implement these 4 functions. The solver chooses the
mechanical implementation for each.

### BLOCK A -- Frequency Splitter
(1 rotary input -> 3 rotary outputs at incommensurate frequencies)

- Input: single shaft, 100-600 RPM (motor) or 1-15 RPM (hand crank)
- Output: 3 shafts at frequencies omega_1, omega_2, omega_3
- Gear pair 1: 55:89 teeth (phi ratio)
- Gear pair 2: 99:140 teeth (sqrt(2) ratio)
- Shaft 3 = input shaft (ratio 1:1)
- Must use only spur/helical gears (printable, no exotic mechanisms)
- Motor: NEMA 17 stepper (0.4-0.5 N*m) or hand crank

### BLOCK B -- Spatial Phase Distributor
(1 rotary input per frequency -> N phase-shifted oscillations across the grid)

- Each frequency shaft must drive all 919 balls (17-ring hex field)
- Each ball receives the signal at a different phase
- Phase gradient: linear with position along each hex axis (traveling wave)
- Phase must be set by geometry -- position on a shaft, angular offset, link length
- The wave travel direction (theta_n) is set by the orientation of the distributor
- 3 distributors at 0, 120, 240 degrees align with the hex grid's 3 principal axes
- Rows per direction: ~35 (diameter / pitch = 750mm / 22mm)

Candidates:
- Helical shaft: phase = position along axis (proven in Triple Helix)
- Swashplate: phase = angular position of follower around disc
- Long barrel cam: phase = angular position + axial position
- Eccentric stack: phase = angular offset of each disc

### BLOCK C -- Summation
(3 oscillating linear inputs -> 1 combined displacement per ball)

- At each ball position, combine 3 sinusoidal inputs ADDITIVELY
- The combination is superposition: z_total = z_1 + z_2 + z_3
- Must handle bidirectional forces up to 0.35 N per rod (retract at peak + gravity)
- Zero backlash at direction reversal

EXCLUDED:
- Rope/string/cable routing through pulleys (Lord Kelvin / Margolin)
- Planetary/epicyclic gear differentials (2-DOF binding with 3 inputs)
- Barrel cam profile as sole mechanism (1 rev = 1 repeat)
- Individual motors per ball (not a mechanism -- electronic)

Candidates:
- Whippletree linkage: 2 stages of pivoted bars sum 3 linear inputs
  (proven in analog computers, zero friction cascade)
- Lever stack: 3 input levers at different fulcrum points drive one output
- Spring-coupled followers: 3 springs in parallel on one rod, forces add
- Flexure adder: compliant mechanism summing 3 displacements

### BLOCK D -- Output Actuator
(combined signal -> bidirectional rod motion through guide plate)

- 1mm steel rod through guide hole, 40-50 mm stroke
- MUST be desmodromic (positive drive in both directions)
- No gravity return (asymmetric force, loses wave symmetry)
- No spring-only return (resonance, asymmetric force profile)
- No ropes/cables (can only pull, not push)
- Zero backlash at direction reversal
- Smooth passage through neutral (no dead zone)

Candidates:
- Conjugate cam pair: two cams, one opens, one closes (Ducati principle)
- Desmodromic fork: forked follower constrained both ways by cam groove
- Scotch yoke: pin in slotted yoke (inherently bidirectional SHM)
- Double-acting linkage: connecting rod with spherical joints

---

## 7. STRUCTURAL & INSTALLATION

### Ceiling Mount

| Parameter | Value | Notes |
|-----------|-------|-------|
| Suspension points | 3 eyebolts at 120 deg spacing on structural ring | Triangulated, stable against rotation |
| Suspension cable | 2mm steel wire rope or braided Dyneema | Per cable rated >> 25 kg |
| Leveling | Turnbuckle on each cable | Adjustable to < 1 deg tilt |
| Total hung weight (proto) | ~10-12 kg | Well within standard gallery hooks (25 kg rated) |
| Ceiling height required | 3-4 m minimum | 800mm disc at ~2.5m gives 2m viewing below |

### Weight Budget

| Component | Weight | Notes |
|-----------|--------|-------|
| Balls (919 x 4g) | 3.7 kg | Chrome steel 10mm bearings |
| Rods (919 x 0.6g) | 0.6 kg | 1mm piano wire, 120mm each |
| Guide plate (800mm disc, 3mm PLA) | ~1.9 kg | Hex-tiled, 7 sections |
| Structural ring frame | ~1.2 kg | 6 arc segments |
| Mechanism housing | ~1.5 kg | PLA shell |
| Mechanism internals | ~2-3 kg | Gears, shafts, bearings, followers |
| Motor (NEMA 17) | 0.35 kg | Standard |
| **Total** | **~11-13 kg** | |

### Frame Requirements

- Structural ring: outer diameter 800mm, ring width 25mm, depth 30-40mm
- Must resist bending from mechanism torque reaction (motor tries to spin frame)
- Anti-rotation: 3 suspension cables in triangulated arrangement prevent spin
- Guide plate: flat disc with 919 precision-drilled holes at 22mm hex pitch
- Hole diameter: 1.3 mm (1.0mm rod + 0.3mm sliding clearance)
- Plate thickness: 3 mm minimum (rod guidance, not structural)
- Power routing: single cable from motor to ceiling-mounted power supply

---

## 8. HARD CONSTRAINTS (from Triple Helix / Waffle Planetary validated data)

### Force / Power
| Parameter | Value | Source |
|-----------|-------|--------|
| Motor torque | 0.4-0.5 N*m (NEMA 17) | Waffle Planetary validated |
| Force per rod -- retract (peak) | 0.35 N | mass * accel + gravity |
| Force per rod -- extend (peak) | 0.27 N | mass * accel - gravity |
| Total mechanism force | < 65 N | ~919 balls, phase-spread peak |
| Friction efficiency target | > 70% | Better than rope cascade (62%) |
| Hand-crank torque budget | < 0.5 N*m | Must be operable by hand at slow speed |
| Rod buckling limit (1mm, 120mm) | 0.67 N | Euler P_cr, safety factor 1.9x vs 0.35 N |

### Manufacturing
| Parameter | Value | Source |
|-----------|-------|--------|
| Min wall thickness | 1.2 mm | Design rules |
| Sliding clearance | 0.3 mm | FDM tolerance |
| Press-fit tolerance | 0.05 mm | Bearing seats |
| FDM layer height | 0.2 mm | Standard |
| Overhang limit | 45 deg | No supports |
| Primary material (proto) | PLA / PETG | K2 Plus compatible |
| Primary material (prod) | Steel, brass, aluminum, hardwood | Machine shop |
| Guide rod | 1.0 mm spring steel piano wire | Rigid, thin, bidirectional force |
| Bearings | 6810 (50x65x7) or smaller as needed | Validated in Triple Helix |

### Spatial
| Parameter | Value | Source |
|-----------|-------|--------|
| Prototype overall diameter | 800 mm | Ceiling-hung disc |
| Ball field diameter | 750 mm | After structural ring margins |
| Ball count | 919 (17 hex rings at 22mm pitch) | Hex-packed |
| Mechanism housing depth | 100-150 mm | Above guide plate (hidden) |
| Rod hang length | 80-120 mm | Below guide plate (visible) |
| Total Z | ~220-300 mm | Housing + plate + rods + balls |
| Print tile size | < 350 x 350 x 350 mm each | K2 Plus bed |
| Assembled sections | ~26-30 printed parts | Bolted + pinned |
| Production diameter | 1200-1800 mm | 1.5-2.25x prototype |

---

## 9. EXCLUDED MECHANISMS (prior art / proven failures)

| Mechanism | Why excluded | Source |
|-----------|-------------|--------|
| Rope/cable summation | Lord Kelvin (1872) / Margolin. Not original. Can only pull, not push. | Triple Helix project |
| Planetary/epicyclic differential | 2-DOF can't blend 3 inputs (Willis binding) | Waffle Planetary failure |
| Barrel cam as sole summation | 1 revolution = 1 repeat cycle | Murmuration exploration |
| Individual motors per ball | Not a mechanism (Kinetic Rain, BMW already did this) | Prior art |
| Gravity-only return | Asymmetric, loses wave symmetry (ceiling-hung: assists extend only) | Physics |
| Spring-only return | Resonance, asymmetric force, tuning nightmare x919 | Engineering judgment |
| Pneumatic/hydraulic | Leaks, noise, compressor, complexity | Not suitable for gallery |
| Rope/cable for rod drive | Can only transmit tension; goes slack on push | Fundamental physics |

---

## 10. REFERENCE MECHANISMS (building blocks the solver CAN use)

| Mechanism | Function | Origin |
|-----------|----------|--------|
| Swashplate | Rotary -> bidirectional linear sine (axial piston pumps) | Industrial |
| Eccentric disc stack | Rotary -> SHM with phase via angular offset | Engine mechanisms |
| Whippletree linkage | Mechanical addition of 2+ linear inputs | Analog computers |
| Scotch yoke | Rotary -> pure SHM (zero harmonic distortion) | Tide Predictor No. 2 |
| Pin-and-slot (Antikythera) | Speed variation for organic waveform | 100 BCE Greece |
| Fibonacci gear train | Quasi-periodic frequency splitting | KAM theorem |
| Desmodromic cam | Positive drive both directions (125 Hz capable) | Ducati valve trains |
| Conjugate cam pair | No-backlash bidirectional drive | Packaging machines |
| Peaucellier-Lipkin linkage | Exact straight line from rotation (no guide rail) | 1864 |
| Helical shaft | Spatial phase gradient via twist angle | Triple Helix (proven) |

---

## 11. EVALUATION CRITERIA

A valid mechanism MUST:
1. Produce smooth bidirectional motion from 3 summed inputs at 919 nodes (17-ring hex grid)
2. Pattern repeat cycle > 1,000,000 input revolutions (68+ hours at 300 RPM)
3. Support oscillation frequency 3-15 Hz per ball
4. Total friction efficiency > 70%
5. Assemble from tiles that each fit 350 x 350 x 350 mm (K2 Plus)
6. Total assembled diameter: 800 mm (prototype), scalable to 1200-1800 mm (production)
7. Use 1 motor (NEMA 17 class) -- hand-crank operable at 1-15 RPM
8. NOT use any mechanism in the EXCLUDED list
9. Provide positive force in BOTH directions via rigid rods (no ropes, no gravity return)
10. Be 3D printable for prototype (FDM, 0.2mm layer, PLA/PETG)
11. Support ceiling suspension at 3 points (total weight < 13 kg)
12. Resting state (motor off) = flat ball field under gravity

---

## 12. PRECEDENT TO BEAT

**BEA.ST "Breaking Wave"**: 804 spheres, single motor, cam-driven, 36 channels.
BUT: uses a single cam profile (no superposition), pattern repeats every revolution.

This specification asks for 3-frequency superposition with quasi-periodic
non-repetition (1.23 million rev cycle) at comparable ball count (919 vs 804) --
fundamentally richer motion. Plus ceiling-hung orientation for immersive
viewing from below, unlike wall-mounted or table-mounted prior art.

The mechanism that solves this is novel and original.

---

## APPENDIX: Quantitative References

### From Triple Helix (validated build)
- Friction per pulley: eta = 0.95
- Friction cascade (9 pulleys): 0.95^9 = 63% efficiency
- Cam eccentric offset: 12 mm (+/- 12mm throw)
- Gain per tier: 1.41x (rope displacement / slider displacement)
- Block travel (3 tiers superposed): +/- 30-45 mm
- Phase offset per block (helix twist): 18.95 deg
- String: 0.5mm braided Spectra/Dyneema
- Hand crank speed: 1-15 RPM safe range

### From Waffle Planetary (validated physics, mechanism abandoned)
- Ravigneaux constraint: T_SL + 2*T_Po = T_Ring (38 + 2*25 = 88)
- Willis kinematic: omega_Ring = 0.3724*omega_SL + 0.6276*omega_SS
- Block force: 0.061 N per 6.2g element
- Spool radius: 12 mm (75.4 mm rope per revolution)
- NEMA 17 torque: 400+ mN*m (46x headroom for single block)

### From Murmuration Research
- Wave propagation in real flocks: 20-40 m/s
- Individual reaction time: < 100 ms
- Topological interaction: each bird tracks 6-7 nearest neighbors
- Flock turn time (400 birds): ~0.5 seconds
- Visual density for "blob" effect at 2-3m: 10mm balls on 22mm pitch

### Rod vs Rope Physics
- 1mm steel rod: transmits tension AND compression (bidirectional)
- 0.5mm Dyneema rope: transmits tension ONLY (unidirectional, goes slack on push)
- Rod buckling (1mm, 120mm): P_cr = 0.67 N >> 0.35 N peak force (safe)
- Rod weight penalty: 0.6g vs rope 0.1g per element (acceptable for 919 units)
