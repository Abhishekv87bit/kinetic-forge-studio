# Reuleaux 307 Mechanisms: Decomposition & Recombination Synthesis
## For the Waffle Grid Planetary Kinetic Sculpture

**Date:** 2026-02-24
**Method:** Decompose all 307 mechanisms into primitive kinematic elements, then cross-pollinate across sets to discover novel motion profiles and mechanism combinations.

---

## PART 1: PRIMITIVE KINEMATIC ELEMENTS

Every mechanism in the Reuleaux collection is built from combinations of these atomic elements:

### Joint Types (how parts connect)
| Symbol | Joint | DOF | Reuleaux Sets |
|--------|-------|-----|---------------|
| R | Revolute (pin) | 1 rot | ALL sets |
| P | Prismatic (slider) | 1 trans | D, E, K, S, T |
| H | Screw (helical) | 1 coupled | A3, M1-M8 |
| C | Cylindrical | 2 (rot+trans) | E3, E6 |
| Cam | Cam contact (higher pair) | 1 (profile-defined) | B, L, W |
| Gear | Gear mesh (rolling contact) | 1 (ratio-linked) | C8, G, O, Q, Y |

### Link Types (what connects joints)
| Type | Function | Key Property |
|------|----------|--------------|
| **Crank** | Full rotation, grounded | Continuous input |
| **Rocker** | Partial rotation, grounded | Oscillating input/output |
| **Coupler** | Floating link | Traces complex curves |
| **Slider** | Linear translation | Reciprocating output |
| **Gear body** | Toothed, ratio-linked | Fixed ratio, positive drive |
| **Cam body** | Shaped profile | Programmable motion |
| **Cord/belt** | Flexible, tension only | Force at distance, wraps |
| **Screw** | Helical surface | Rotation-translation coupling |
| **Frame** | Grounded reference | Everything is relative to this |

### Motion Types (what comes out)
| # | Motion | Sets that produce it |
|---|--------|---------------------|
| 1 | **Continuous rotation** | V (belt), G (gears), W (friction) |
| 2 | **Oscillation** (angular) | D (cranks), N (ratchets), Z (couplings) |
| 3 | **Reciprocation** (linear) | E (eccentrics), S (straight-line), T (guides) |
| 4 | **Intermittent advance** | N8 (Geneva), X (escapements) |
| 5 | **Dwell** (pause at extreme) | L (constant-breadth cams) |
| 6 | **Exact sinusoidal** | E (eccentric slider = sin(theta)) |
| 7 | **Modified sinusoidal** (with harmonics) | L (Reuleaux cams), D9 (trammel) |
| 8 | **Exact straight-line** | S16 (hypocycloid), S35 (Peaucellier) |
| 9 | **Approximate straight-line** | S1 (Watt), S2 (Roberts), S5 (Chebyshev) |
| 10 | **Epicycloidal** (looping) | O (planetary+linkage), R (rolling) |
| 11 | **Differential** (sum/difference) | G4 (mismatched planet), M7 (screws) |
| 12 | **Non-constant velocity** | P3 (Hooke's joint), V (crossed belt) |
| 13 | **Positive return** (springless) | L1-L11 (constant-breadth cams) |
| 14 | **Self-locking** (non-backdrivable) | M (screws), C9 (worm) |

---

## PART 2: SET-BY-SET DECOMPOSITION

### Set A: Lower Element Pairs (3 models)
**Atoms:** Revolute, Prismatic, Screw joints
**Extractable element:** The SCREW PAIR (A3) couples rotation and translation in a FIXED RATIO defined by thread pitch. This is the only joint type where one DOF gives you BOTH motions simultaneously.
**Recombination seed:** What if EVERY link in a mechanism were replaced with screws? Instead of pins that rotate and sliders that translate, use screws that do BOTH. A "screw four-bar" would have every joint coupling its rotation to a translation.

### Set B: Higher Element Pairs (5 models)
**Atoms:** Non-circular surface contacts (Curved rotors in chambers)
**Extractable element:** PROFILE-DEFINED MOTION. The shape of the rotor defines the output displacement function. ANY shape that maintains contact gives a valid mechanism.
**Recombination seed:** Custom cam profiles that produce SPECIFIC wave harmonics. A 3-lobed rotor gives 3 pulses/rev (3rd harmonic), a 5-lobed gives 5th harmonic. The lobe count IS the harmonic number.

### Set C: Simple Kinematic Chains (15 models)
**Atoms:** 4-link chains with R/P/Gear joints in various combinations
**Extractable elements:**
- C4: Slider-crank INVERSION (grounded slider vs grounded crank = completely different motion!)
- C8: Planet-ring pair (foundational for all planetary work)
- C9: WORM DRIVE = rotation to perpendicular rotation + self-locking
**Recombination seed:** INVERSION PRINCIPLE applied to the whole sculpture. What if instead of 3 cam shafts driving 49 fixed cells, you have 49 cam shafts and 3 cells? The "grid" rotates and the "cams" are fixed. The entire sculpture is inside-out.

### Set D: Crank Mechanisms (18 models)
**Atoms:** Crank + slider/rocker in various topologies
**Extractable elements:**
- D7/D8: **ANNULAR SLIDER** = slider on a CURVED track (not straight)
- D9: **TRAMMEL (ellipsograph)** = two perpendicular sliders + crank = ELLIPTICAL output
- D11: Oscillating vertical from rotating cross
- D14: Annular slider-crank combining curve + slider
**Recombination seeds:**
1. TRAMMEL AS PIXEL DRIVE: pixel traces an ellipse (2D motion) instead of a line (1D). The ellipse orientation varies with phase.
2. ANNULAR SLIDER replacing linear rack: curved rack wrapping around a gear = more compact.

### Set E: Eccentric Slider Cranks (7 models)
**Atoms:** Eccentric disc + bearing + slider
**Extractable elements:**
- E3: Bearing diameter > crank throw → NESTED eccentric. The bearing shell IS the crank arm.
- E6: TRIPLE NESTING → rotary + oscillatory + sliding in one compact unit
**Recombination seed:** NESTED ECCENTRICS for compound motion. An eccentric inside an eccentric = epicycloidal output. The inner eccentric traces a circle on the outer eccentric's circle. By choosing different radii, you get any prolate or curtate epicycloid. This is a 2-frequency generator in a single compact unit.

### Set F: Crank Chamber Mechanisms (11 models)
**Atoms:** Piston in sealed chamber (engines, pumps)
**Extractable element:** The PISTON concept: a body constrained inside a cylinder, driven by external forces.
**Recombination seed:** OPEN-AIR WEIGHTED PISTON. Remove the sealed chamber. Keep the piston (weighted slug) in an open tube. Gravity pulls it down, cam pushes it up. The weight IS the restoring force (replaces springs). Each cell has a dense metal slug in a glass tube. The slugs rise and fall like thermometer mercury. Visual effect: 49 glass columns with silver slugs pulsating.

### Set G: Simple Gear Trains (8 models)
**Atoms:** Meshing gear pairs in various topologies
**Extractable elements:**
- G3: Standard planetary (S/P/R)
- G4: **MISMATCHED RATIO** double planetary → differential
- G5: **PARALLEL AXIS** compound planetary (side-by-side, not stacked)
- G7: Counter-rotation from paired spur gears
**Recombination seeds:**
1. MISMATCHED RATIOS as a feature: intentionally different gear ratios in the two planetary stages creates a net "wobble" in the output — a deliberate imperfection that adds character.
2. G5 PARALLEL LAYOUT: Sun1 meshes Planet1 which meshes Ring1; Sun2 on a PARALLEL AXIS meshes Planet2. Planets 1 and 2 share a common arm. This trades height for width — important for our 50mm cell pitch but relaxed vertical budget.

### Set I: Chamber Wheel Mechanisms (11 models)
**Atoms:** Shaped rotor in shaped chamber (pumps, blowers)
**Extractable element:** LOBE COUNT = PULSE FREQUENCY. A gear pump with N lobes gives N displacement pulses per revolution.
**Recombination seed:** LOBE PUMP AS MOTION MULTIPLIER. A 3-lobe rotor in a 2-lobe chamber gives 3 output pulses for every 2 input rotations. This is a 1.5:1 frequency multiplier with NO GEARS — just shaped profiles in contact. For our irrational ratios: what lobe combinations approximate sqrt(2)?

### Set K: Complex Slider Cranks (2 models)
**Atoms:** Multiple sliders ganged from one input
**Extractable element:** COMPOUND SLIDER = multiple linear outputs from one rotary input, each with different amplitude/phase.
**Recombination seed:** ONE CRANK drives TWO PERPENDICULAR SLIDERS (one X, one Y) in each cell. The X slider carries the pixel horizontally, the Y slider carries it vertically. Combined: the pixel traces a Lissajous figure determined by the crank geometry. 49 cells, each with slightly different slider ratios = 49 different Lissajous figures.

### Set L: Positive Return Constant Breadth Cams (11 models)
**Atoms:** Shaped cam + parallel guides = springless reciprocation
**Extractable elements:**
- L1: REULEAUX TRIANGLE → modified sinusoid with 3rd-harmonic dwell
- L3: CURVED SQUARE → 4th-harmonic dwell
- L5: CURVED PENTAGON → 5th-harmonic dwell
- L2: **TILTED GUIDES** → phase shift without cam geometry change
- L4-L11: Progression through polygon orders → HARMONIC SERIES
**Recombination seeds:**
1. **HARMONIC PALETTE:** Different cam profiles in different cells to add different harmonics:
   - Edge cells: Triangle cams (3rd harmonic → sharp crests)
   - Middle cells: Pentagon cams (5th harmonic → rippled crests)
   - Center cells: Circular cams (pure sinusoid → smooth crests)
   → The wave surface has different "texture" in different regions
2. **TILTED GUIDE = PHASE CONTROL:** All cams identical on one shaft, but each cell's guide plate tilted differently. Phase is controlled by mechanical setup, not cam geometry. Swappable guide plates = reprogrammable wave.

### Set M: Screw Mechanisms (8 models)
**Atoms:** Helical thread + nut, gear-screw combinations
**Extractable elements:**
- M7: TWO DIFFERENT PITCHES → differential translation
- M8: GEAR PAIRS driving screws → gear-screw differential
- General: Screw = self-locking → output FREEZES when input stops
**Recombination seeds:**
1. **TELESCOPING SCREW PIXEL:** The screw IS the pixel rod. It screws up and down through a nut fixed in the cell housing. Three concentric screws (different pitches) sum three inputs. The pixel is the innermost screw's tip. Visual: threaded columns rising/falling.
2. **SELF-LOCKING WAVE FREEZE:** Stop all motors → wave surface freezes INSTANTLY in its current configuration. No spring-back, no settling. Turn off power → frozen sculpture.

### Set N: Ratchet Mechanisms (26 models)
**Atoms:** Pawl + ratchet wheel = intermittent advance
**Extractable elements:**
- N8: GENEVA WHEEL → advance-dwell-advance with POSITIVE LOCKING
- N1-N7: Various ratchet pawl geometries
- N14: Ratchet driving device with adjustable stroke
**Recombination seeds:**
1. **MIXED TEXTURE GRID:** Some cells use ratchet-driven discrete steps, others use smooth continuous motion. The wave surface has "digital" and "analog" regions. The contrast creates visual tension.
2. **ADJUSTABLE RATCHET STROKE (N14):** Per-cell adjustable advance angle → adjustable amplitude per cell. You can tune the wave envelope by adjusting ratchet strokes.
3. **POLYRHYTHMIC GENEVA ARRAY:** 7 Geneva wheels with 5, 6, 7, 8, 9, 10, 11 slots on the same shaft. Each advances at a different rate. Driven by the same motor, they create a polyrhythmic pattern — a MECHANICAL GAMELAN.

### Set O: Planetary + Linkage (9 models)
**Atoms:** Planetary gear + four-bar/slider = compound mechanisms
**Extractable elements:**
- O1: Planet point traces EPICYCLOID
- O2: Planetary + slider-crank combined
- O3-O9: Various compound planetary/linkage hybrids
**Recombination seeds:**
1. **FOUR-BAR CARRIER PLATE:** Replace the rigid circular carrier with a four-bar linkage. Planets ride on the coupler link. As the "carrier" moves, the planet orbit is NOT a circle but a COUPLER CURVE. The output gain modulates during each carrier revolution — a kind of amplitude modulation built into the mechanism.
2. **EPICYCLOID DRAWING ATTACHMENT:** Attach a stylus to one planet. Below the cell, a slowly-scrolling surface records the pattern. Each cell draws a unique spirograph determined by its gear ratios. The sculpture makes art while performing computation.

### Set P: Jointed Couplings (8 models)
**Atoms:** Universal joints, flexible couplings
**Extractable elements:**
- P3: **HOOKE'S JOINT = 2x VELOCITY RIPPLE.** Input turns at constant speed, output speed varies as `w_out = w_in / (1 - sin^2(alpha) * sin^2(theta))` where alpha is the joint angle. This introduces a 2x-frequency speed variation.
- P6: Clemens coupling → constant-velocity (CV) joint
**Recombination seeds:**
1. **HOOKE'S JOINT AS FREE HARMONIC GENERATOR:** Put a Hooke's joint between motor and cam shaft at angle alpha. The cam shaft now has a 2nd-harmonic speed ripple. By adjusting alpha (0-30 deg), you control the ripple amplitude from 0% to ~15%. Three joints at three different angles → three cam shafts each with different 2nd-harmonic content. The wave surface gets richer harmonics FOR FREE — no extra mechanism.
2. **DOUBLE HOOKE'S JOINT = CV, SINGLE = RIPPLE.** The "bug" (velocity ripple) of a single Hooke's joint is normally fixed by using two in series (double cardan). For our sculpture: deliberately use SINGLE Hooke's joints to INJECT velocity variation. This is USING A BUG AS A FEATURE.

### Set Q: Gear Teeth Profiles (11 models)
**Atoms:** Different tooth geometries
**Extractable elements:**
- Q1-Q2: Cycloidal teeth (older style, sensitive to center distance)
- Q3-Q5: Involute teeth (modern standard, tolerant of CD variation)
- Q6: THUMB-SHAPED HYBRID (strongest for unidirectional loads)
- Q7-Q8: **PIN TEETH** — gear teeth are simple cylindrical pins
- Q9-Q11: Various tooth demonstrations
**Recombination seeds:**
1. **PIN GEARS for VISUAL TRANSPARENCY:** Sun and ring gears made with pin teeth. You can SEE THROUGH the gear mesh — the pins are open, not solid walls. The entire planetary is a transparent cage of spinning pins. Light passes through. Shadows of the pins create moving patterns on the wall behind the sculpture. FUNCTIONAL SHADOW ART.
2. **MIXED TOOTH PROFILES across the grid:** V1 cells use cycloidal teeth (old-world feel), V2 cells use involute (precision feel), V3 cells use pin teeth (open/airy feel). The three Willis variants look different even at a glance — you can SEE the engineering variation.

### Set R: Cycloid Rolling Models (9 models)
**Atoms:** Circle rolling on circle/line → curve generation
**Extractable elements:**
- R1: CYCLOID (circle on line) → brachistochrone (fastest descent curve)
- R5: EPICYCLOID (circle rolling outside circle) → looping curves
- R7: HYPOCYCLOID (circle rolling inside circle) → star-shaped curves
- R3-R4: Prolate/curtate variants (tracing point NOT on rim)
**Recombination seeds:**
1. **CYCLOID GUIDE RAIL:** The pixel slider doesn't move in a straight line — it follows a CYCLOID TRACK. A cycloid is the brachistochrone: the curve of fastest descent under gravity. A pixel following a cycloid path ACCELERATES naturally at the top and DECELERATES at the bottom. This makes the wave crests FAST (like breaking waves) and troughs SLOW (like gathering swells). Physically realistic wave motion from pure geometry.
2. **PROLATE EPICYCLOID PATH:** If the tracing point is OUTSIDE the rolling circle (prolate), the path has sharp CUSPS. Use this for the pixel output: each pixel has a brief sharp reversal at its extreme (cusp) before smoothly returning. This gives the wave surface SNAP at the crests — like a whip crack.

### Set S: Straight-line Mechanisms (48 models!)
**Atoms:** Various linkage topologies producing linear (or near-linear) output
**Extractable elements:**
- S1 (Watt): 3 links, approximate, slight figure-8 deviation
- S2 (Roberts): 3 links, approximate, different deviation pattern
- S5 (Chebyshev): 4 links, very good approximation
- S16 (Hypocycloid): Gear-based, exact, compact
- S17: Inversion where RING GEAR = SLIDER
- S35 (Peaucellier): 8 links, exact, mathematically elegant
- S39-S48: Hart's inversors, Scott-Russell, etc.
**Recombination seeds:**
1. **IMPERFECT GRID:** Different cells use different straight-line mechanisms. Some cells are "exact" (Peaucellier), others are "approximate" (Watt). The slight deviations of the approximate mechanisms add character. Like the difference between a synthesizer and an orchestra — the imperfections create warmth.
2. **S17 RING-AS-SLIDER FUSION:** The ring gear of the planetary IS the output slider. The ring doesn't rotate in a housing — it translates vertically while planets roll inside it. This FUSES the planetary summing and the linear output into one mechanism. Two kinematic chain stages become one. Potentially the most elegant solution.

### Set T: Parallel Guide Mechanisms (20 models)
**Atoms:** Multi-link systems constraining pure translation
**Extractable elements:**
- T1-T5: PARALLELOGRAM LINKAGE = pure translation without rotation
- T13: COMPOUND RACK-AND-PINION for constrained translation
- T8: **PANTOGRAPH** = motion amplifier/reducer
**Recombination seeds:**
1. **PANTOGRAPH AMPLITUDE CONTROL:** Each cell has a small pantograph between the planetary output and the pixel rod. The pantograph ratio determines the amplitude. Different ratios per cell → spatially varying amplitude → the wave has an ENVELOPE.
2. **PARALLELOGRAM OUTPUT LINKAGE:** Instead of a slider in a groove (friction), use a parallelogram linkage to keep the pixel rod vertical while it moves up/down. Zero sliding friction, perfect vertical constraint. The parallelogram adds a subtle pendulum-like feel — the pixel "swings" through a gentle arc.

### Set U: Rotating Arm Guide (3 models)
**Atoms:** Arms on rotating hub with constrained tips
**Extractable element:** ROTATING ARM as output instead of linear slider.
**Recombination seed:** **FLOWER PIXEL:** Each pixel is a small rotating arm (like a flower petal). The arm angle represents the wave height. 49 "flowers" tilting at different angles = a wave surface made of angles, not heights. Visual effect: a field of flowers swaying in the wind. The "wave" is the tilt pattern propagating across the field.

### Set V: Belt Drives (17 models)
**Atoms:** Flexible cord/belt + pulleys for power transfer
**Extractable elements:**
- V1-V4: Standard belt drives (parallel/crossed)
- V5-V7: **CONE PULLEYS** = continuously variable speed
- V10-V12: Shifting belt mechanisms
**Recombination seeds:**
1. **VARIABLE SPEED CONE for IRRATIONAL RATIOS:** Instead of fixed gear ratios (41:29, 55:34) to approximate sqrt(2) and phi, use a CONE PULLEY set. Move the belt to different positions on the cone → continuously variable ratio. You could set the ratio to the EXACT irrational number (limited by belt slip, but sculpture loads are negligible). Turn a knob to sweep through different speed ratios → the wave pattern morphs continuously.
2. **CROSSED BELT = DIRECTION REVERSAL:** A crossed belt reverses rotation. Between Motor C and its cam shaft, use a crossed belt → Cam C runs BACKWARD relative to the motor. This is the simplest possible direction reversal — no gears needed.
3. **CORD SUMMATION (Kelvin's method):** Three cords, each pulled by one cam, thread through a pulley block and attach to the pixel. The pixel position = sum of three cord pulls. RADICALLY SIMPLE — but this is exactly what Margolin does and is explicitly NOT our approach.

### Set W: Friction Wheels (6 models)
**Atoms:** Friction contact between wheels (no teeth)
**Extractable elements:**
- W1-W2: Parallel-axis friction drive
- W3-W4: **BEVEL FRICTION WHEELS** = axis change via friction
- W5-W6: Variable friction demonstrations
**Recombination seeds:**
1. **EXACT IRRATIONAL SPEED VIA FRICTION:** A flat disc (like a record player) touches an idler wheel. The idler's axis is offset from the disc center. The speed ratio = disc_radius_at_contact / idler_radius. By positioning the idler at radius r = R/sqrt(2), you get EXACTLY sqrt(2) ratio. No integer approximation needed. For phi: position at r = R/phi. A precision dial positions the idler → exact irrational ratios.
2. **FRICTION WHEEL AS CLUTCH:** Friction contact can slip under overload. This gives automatic overload protection. If a pixel jams (dust, thread tangle), the friction wheel slips instead of breaking teeth. Self-protecting mechanism.

### Set X: Clock Escapements (20 models)
**Atoms:** Controlled energy release — advance one tooth per oscillation
**Extractable elements:**
- X1: Dead-beat escapement (precise, zero recoil)
- X7: Grasshopper escapement (low friction, long arms)
- X15-X20: Various escapement geometries
**Recombination seeds:**
1. **ESCAPEMENT-METERED WAVE:** Each cell has a tiny escapement. The cam provides energy, the escapement meters its release. Each pixel advances one TICK at a time. 49 pixels ticking at slightly different rates = POLYRHYTHMIC MECHANICAL CLOCK. The wave isn't smooth — it's a field of ticking pixels, each at its own tempo. SOUND BECOMES ART: each tick is audible. 49 ticking sounds, all slightly out of phase, create a complex ambient texture.
2. **ASYMMETRIC WAVE DYNAMICS:** The escapement lets the pixel fall ONE TICK under gravity (fast), then the cam slowly raises it one tick (slow). Fall is gravity-powered, rise is cam-powered. The wave has FAST CRESTS and SLOW TROUGHS — like real ocean waves where crests break sharply but troughs gather slowly.
3. **ENERGY STORAGE:** Between ticks, potential energy is stored in the pixel's height. The escapement controls WHEN this energy is released. This is a MECHANICAL SHIFT REGISTER — each cell stores one bit of wave information (its height) and releases it on the next tick.

### Set Y: Reversing and Shifting Mechanisms (16 models)
**Atoms:** Direction change, ratio change, shifting engagement
**Extractable elements:**
- Y7: Belt + planetary combination
- Y16: **SHIFT LEVER** engages planet between sun and ring → instant reversal
- Y17: Bevel differential with shifting pinion
**Recombination seeds:**
1. **PER-CELL REVERSAL LEVER:** Each cell has a tiny shift lever (Y16 style). Flip it → that cell's pixel moves OPPOSITE to its neighbors. Create "defects" in the wave — one pixel going up while all neighbors go down. Like a splash or vortex. Manual control: visitors can flip individual levers to disrupt the wave. INTERACTIVE.
2. **BEVEL DIFFERENTIAL SUMMING (Y17):** Replace spur planetary with bevel differentials. Three bevel gear pairs on three orthogonal axes, meeting at a central point. Each axis carries one input. The output is the sum. MORE COMPACT than spur planetary for small cells.

### Set Z: Coupling Mechanisms (8 models)
**Atoms:** Shaft-to-shaft coupling elements
**Extractable elements:**
- Z5: **OLDHAM COUPLING** = cross-block transfers rotation between parallel offset shafts
- Z7: Flexible coupling (rubber/spring element)
**Recombination seeds:**
1. **OLDHAM COUPLING AS VISUAL BRIDGE:** Between adjacent cells, add Oldham couplings on the row/column shafts. The cross-blocks oscillate laterally as they transmit rotation. This makes the POWER FLOW VISIBLE — you can see the coupling disc rocking as energy transfers from one cell to the next. A secondary lateral wave propagates along the couplings, perpendicular to the primary vertical wave.
2. **FLEXIBLE COUPLING = PHASE SMEAR:** A flexible coupling (Z7) between cam shaft sections introduces slight phase jitter. The elasticity means phase isn't perfectly transmitted — it "smears" slightly. This is normally a flaw, but for our wave it adds ORGANIC IMPERFECTION. Like the difference between a digital sine wave and a real ocean wave — the real one has micro-turbulence.

---

## PART 3: NOVEL RECOMBINATIONS (Cross-Set Hybrids)

### HYBRID 1: "The Gravity Tide" (Sets F + X + R)
**Elements combined:**
- F-series: Open-air weighted piston (column of dense metal in glass tube)
- X-series: Escapement meters descent rate
- R-series: Cycloid-shaped guide tube (brachistochrone descent)

**How it works:** Each cell is a glass tube with a heavy brass slug inside. The cam slowly raises the slug (stored potential energy). The escapement releases the slug one tick at a time. The tube is curved in a cycloid profile, so the slug ACCELERATES as it descends (brachistochrone physics). The slug's position in the tube IS the pixel displacement.

**Novel motion profile: ASYMMETRIC TIDAL WAVE**
- Rising phase: SLOW (cam-powered, constant speed)
- Falling phase: FAST with acceleration (gravity + cycloid + escapement ticks)
- Like real tidal bores that rush in fast and drain slowly
- Sound: brass slugs ticking against glass walls = metallic rain sound

**Why it's novel:** Gravity-powered descent in a kinetic wave machine. No existing wave sculpture uses gravitational potential as part of the motion profile. The cycloid track means each tick covers a larger distance than the last — accelerating descent.

---

### HYBRID 2: "The Hooke's Harmonic Injector" (Sets P + G + V)
**Elements combined:**
- P3: Hooke's universal joint (single, NOT double) → 2x frequency velocity ripple
- G4: Planetary differential for summing
- V5: Cone pulley for variable speed control

**How it works:** Between each motor and its cam shaft, insert a SINGLE Hooke's joint at adjustable angle alpha. The cam shaft speed now has a 2nd-harmonic ripple:
```
w_cam(t) = w_motor * [1 + k*cos(2*w_motor*t)]
where k = sin^2(alpha) / (1 - sin^2(alpha)*sin^2(w_motor*t))
```
The ripple passes through the entire kinematic chain, adding a 2nd harmonic to every cell's output. The joint angle alpha controls the harmonic amplitude.

Additionally, cone pulleys between the Hooke's joints and the cam shafts allow continuous speed ratio adjustment. You can sweep through different irrational ratios in real time.

**Novel motion profile: TUNABLE POINTED WAVES**
- At alpha=0: pure sinusoid (standard wave)
- At alpha=15deg: slight 2nd harmonic (crests get pointed, troughs get flat)
- At alpha=30deg: strong 2nd harmonic (wave looks like TROCHOIDAL sea waves)
- Adjustable in real-time by tilting the Hooke's joint

**Why it's novel:** Nobody uses Hooke's joint velocity error as a FEATURE. In every engineering textbook, the 2x ripple is a flaw to be corrected with double-cardan joints. Here it becomes a harmonic shaping tool.

---

### HYBRID 3: "The Nested Eccentric" (Set E internals + Set L cam shapes)
**Elements combined:**
- E3/E6: Nested eccentric (bearing > crank throw, triple-nested)
- L1-L11: Constant-breadth cam shapes

**How it works:** An eccentric disc inside a constant-breadth cam profile. The inner eccentric rotates inside the outer Reuleaux triangle (or square, or pentagon). The outer shape determines the harmonic content (3rd, 4th, or 5th harmonic). The inner eccentric sets the fundamental amplitude.

Two parameters per cell:
1. Inner eccentric radius → fundamental amplitude (0-5mm)
2. Outer cam polygon → harmonic number (3, 4, 5, 6, ...)

**Novel motion profile: PROGRAMMABLE HARMONIC CONTENT**
- Each cell has BOTH a fundamental sinusoid AND a specific harmonic
- The harmonic number depends on the cam polygon (field-swappable!)
- Swap out the outer cam shape → change the wave's harmonic texture
- Imagine a grid where edge cells have triangle cams (sharp 3rd harmonic crests) and center cells have pentagon cams (gentle 5th harmonic ripple)

**Why it's novel:** Combining eccentric motion generation with constant-breadth harmonic shaping in a single nested unit. The two functions (amplitude and harmonic content) are independently controlled by concentric elements.

---

### HYBRID 4: "The Deformed-Orbit Planetary" (Set O + Set C four-bar)
**Elements combined:**
- O1: Planetary gear + four-bar linkage
- C1-C4: Four-bar chain inversions

**How it works:** Replace the rigid circular carrier plate with a FOUR-BAR LINKAGE. The sun gear is at one fixed pivot, the ring gear provides the grounded frame. Instead of planets riding on a rigid arm that traces a circle, planets ride on the COUPLER LINK of a four-bar, which traces a COUPLER CURVE.

Different four-bar proportions → different coupler curves:
- Near Grashof type I: nearly circular → standard planetary behavior
- Grashof type II: figure-8 coupler curve → planets REVERSE direction briefly during each orbit
- Non-Grashof: rocking coupler → planets oscillate instead of orbiting

**Novel motion profile: ORBIT-MODULATED SUMMING**
- Standard planetary: output = w_A*sin(A) + w_B*sin(B) + w_C*sin(C)
- Deformed-orbit: output = w_A*f(sin(A)) + w_B*f(sin(B)) + w_C*f(sin(C))
  where f() is a nonlinear function determined by the coupler curve shape
- The nonlinear f() distorts the pure sinusoidal sum, adding harmonics
- Different coupler curves → different distortion → different wave character

**Why it's novel:** Four-bar carrier plates in planetary gearsets have NEVER been built (to my knowledge). The idea of using linkage geometry to nonlinearly distort a summing operation is original.

---

### HYBRID 5: "The Pin-Gear Shadow Theatre" (Set Q + Set O + lighting)
**Elements combined:**
- Q7-Q8: Pin tooth gears (cylindrical pins as teeth)
- O1: Planetary with four-bar (exposed mechanism)
- Lighting: point light source behind the grid

**How it works:** ALL gears in the sculpture — suns, planets, rings — are PIN GEARS. Instead of solid involute tooth walls, each gear is a ring of equally-spaced cylindrical pins. The gears are structurally open — you can see through them.

Mount a single point light source behind the grid. The pin gears cast MOVING SHADOWS on the wall in front of the sculpture. The shadow patterns are:
- Interference patterns from overlapping pin arrays
- Moire patterns from planet pins crossing ring pins at different angles
- Dynamic evolving patterns as the gears rotate

**Novel motion profile: DUAL-OUTPUT SCULPTURE**
- Primary: 49 pixels making a 3D wave surface (physical displacement)
- Secondary: shadow patterns on the wall (2D projected interference)
- The two outputs are mathematically related but visually completely different
- The shadow patterns have their OWN wave behavior, derived from but not identical to the physical wave

**Why it's novel:** Using gear tooth geometry as an optical element. Pin gears are normally chosen for simplicity or low-load applications. Using them specifically because they're TRANSPARENT turns a manufacturing choice into an artistic one.

---

### HYBRID 6: "The Lissajous Surface" (Set D trammel + Set K compound slider)
**Elements combined:**
- D9: Trammel/ellipsograph (crank + 2 perpendicular sliders → elliptical path)
- K1: Compound slider-crank (multiple sliders ganged)
- Two trammels per cell, driven at different frequencies

**How it works:** Each cell has TWO trammel mechanisms, oriented perpendicular to each other. One trammel is driven by cam shaft A at frequency f_A, the other by cam shaft B at frequency f_B. Each trammel produces sinusoidal motion in its own direction. The pixel is connected to BOTH trammels, so it moves in 2D.

The pixel path = Lissajous figure determined by f_A/f_B and the phase difference.

With f_A=1, f_B=sqrt(2): the pixel traces an open Lissajous that NEVER REPEATS.
With different starting phases in different cells: 49 different never-repeating paths.

**Novel motion profile: 2D WAVE SURFACE**
- Pixels don't just go up/down — they move in 2D (up/down AND side-to-side)
- Each pixel traces its own unique Lissajous orbit
- The wave surface is not a height field — it's a TRAJECTORY FIELD
- From above: 49 points orbiting in small patterns, all slightly different
- A moving pointillist painting

**Why it's novel:** All existing wave machines produce 1D displacement (height). A Lissajous-based wave machine produces 2D displacement per point, creating a surface where each point HAS ITS OWN ORBIT rather than just a height.

---

### HYBRID 7: "The Ratchet-Smooth Duality Grid" (Set N + Set E + Set G)
**Elements combined:**
- N8: Geneva wheel (intermittent advance)
- N14: Adjustable ratchet stroke
- E1: Standard eccentric (smooth sinusoidal)
- G4: Planetary summing

**How it works:** The 49-cell grid is divided into two populations:
- **Smooth cells** (25 cells, distributed in center/cross): Standard eccentric drive → smooth sinusoidal output
- **Ratchet cells** (24 cells, distributed on edges/corners): Geneva or ratchet drive → intermittent stepping output

Both populations receive the same 3 cam inputs. The smooth cells produce continuous wave motion. The ratchet cells produce discrete step-by-step motion at the same average rate.

**Novel motion profile: TEXTURE-MAPPED WAVE**
- The wave has TWO TEXTURES visible simultaneously:
  - Center: smooth, continuous, flowing (ocean)
  - Edge: crisp, stepped, mechanical (clockwork)
- The boundary between textures creates visual tension
- Like watching water freeze at the edges while flowing in the center
- Or like a digital-to-analog conversion happening in space instead of time

**Why it's novel:** Deliberately mixing motion qualities (continuous vs. discrete) across a single wave surface. No wave machine does this. It creates a metaphor for the analog/digital boundary.

---

### HYBRID 8: "The Self-Locking Freeze-Frame" (Set M screw + Set X escapement + Set W friction)
**Elements combined:**
- M8: Gear-screw differential (self-locking summing)
- X1: Escapement (metered energy release)
- W1: Friction wheel (overload clutch)

**How it works:** Replace the planetary differential with M8 gear-screw differentials. Three screw-gear pairs per cell, each with slightly different pitch ratios. The screw mechanism is inherently SELF-LOCKING: when the motors stop, the wave surface FREEZES INSTANTLY in its current position. No spring-back, no settling, no drift.

Add an escapement to the output screw. This meters the pixel advance into discrete ticks, giving the wave a staccato quality while running.

Friction wheels between the cam shaft and each cell provide overload protection — if a screw binds, the friction wheel slips instead of stripping teeth.

**Novel motion profile: FREEZE-FRAME WAVE**
- Running: wave surface undulates with escapement-metered ticking
- Motors stop: wave FREEZES instantly in mid-undulation
- Visual: you can literally stop the wave mid-crest, walk up to it, examine the frozen wave topology
- Restart: wave resumes from exactly where it stopped
- Performance art: operator stops/starts the wave at dramatic moments
- Like freeze-frame in film — a powerful visual effect

**Why it's novel:** Self-locking wave sculptures don't exist. Every existing wave machine either free-swings when power is removed (pendulum/gravity type) or gradually settles (spring-return type). A screw-based machine that HOLDS its shape is unique.

---

### HYBRID 9: "The Parametric Resonance Grid" (Set X + pendulum physics + Set G planetary)
**Elements combined:**
- X-series: Escapement/pendulum dynamics
- G-series: Planetary gearing
- Physics: Parametric resonance (oscillator driven near 2x its natural frequency)

**How it works:** Each cell's output isn't a slider — it's a SMALL PENDULUM (or torsional oscillator). The pendulum has a natural frequency determined by its length/stiffness. The planetary output MODULATES the pendulum's parameter (e.g., changes its effective length, or applies a periodic torque at 2x its natural frequency).

When the modulation frequency matches 2x the pendulum's natural frequency → PARAMETRIC RESONANCE → the pendulum swings wildly (exponentially growing until limited by friction).

Different cells have different pendulum lengths → different natural frequencies → different cells resonate with different combinations of the 3 input frequencies.

**Novel motion profile: SELECTIVE RESONANCE WAVE**
- Not all cells move at once. Only cells whose natural frequency resonates with the current input combination
- As motor speeds change, DIFFERENT CELLS become active
- The active pattern SHIFTS across the grid
- Like a heat map where "hot" regions move around
- Some cells oscillate wildly while neighbors are nearly still
- The wave ISN'T a smooth surface — it's a patchy, evolving pattern of resonant and quiet zones

**Why it's novel:** No kinetic wave machine uses resonance as the activation mechanism. Every existing machine drives ALL cells ALL the time. A resonance-based machine creates spatial selectivity — only some cells respond to any given frequency combination. This is closer to how REAL tidal systems work (certain harbors amplify certain tidal constituents through resonance).

---

### HYBRID 10: "The Worm-Organ with Variable Cone" (Sets C9 + V5 + L2)
**Elements combined:**
- C9: Worm drive (90-degree axis change, self-locking, inherent phase shift)
- V5: Cone pulley (continuously variable speed ratio)
- L2: Tilted guide (phase control via angle)

**How it works:** Three worm shafts run along three sides of the grid (like organ pipes). Each worm is driven by its motor through a CONE PULLEY, allowing continuous speed adjustment. Visitors can turn a dial to smoothly change each motor's speed ratio.

Each cell has 3 worm wheels engaging the 3 worms. The worm thread provides automatic phase shift (adjacent cells engage the thread at different points). The tilted guide plates provide fine phase adjustment for tuning.

**Novel motion profile: CONTINUOUSLY TUNABLE WAVE**
- Turn dial A → sweep Motor A speed through different ratios
- The wave pattern MORPHS in real time: from organized standing waves → chaotic interference → organized again at a new ratio
- Find integer ratios → wave LOCKS into a repeating pattern
- Move off-integer → pattern gradually dissolves into non-repetition
- Visitors can FEEL the difference between rational and irrational ratios

**Why it's novel:** Combines the self-locking + inherent phase shift of worm drives with the continuous variability of cone pulleys. The user experience of "tuning" a wave through rational/irrational ratios is unique and deeply educational.

---

### HYBRID 11: "The Reversed-Cell Splash" (Set Y shift lever + any summing method)
**Elements combined:**
- Y16: Shift lever (engages planet between sun and ring, reversing output)
- Any summing mechanism from the rest of the design

**How it works:** Each cell has a small lever that can be flipped between two positions:
- Position 1: Normal summing (output = w_A*A + w_B*B + w_C*C)
- Position 2: Reversed (output = -(w_A*A + w_B*B + w_C*C))

When one cell is reversed while its neighbors are normal, that cell's pixel moves OPPOSITE to the wave. It creates a "defect" — like dropping a stone in the wave and creating a splash.

**Novel motion profile: PROGRAMMABLE WAVE DEFECTS**
- All cells normal: smooth traveling wave
- One cell reversed: persistent "splash" or "vortex" in the wave
- A row reversed: wave reflects off the reversed row
- Checkerboard pattern: complex standing wave
- Visitors can flip levers and SEE the wave physics change
- INTERACTIVE WAVE PHYSICS DEMONSTRATION

**Why it's novel:** No wave machine allows per-cell phase reversal. This makes the sculpture a hands-on wave physics laboratory. You can literally program wave interference patterns by flipping levers.

---

### HYBRID 12: "The Amplitude-Envelope Pantograph" (Set T + Set G + topology)
**Elements combined:**
- T8: Pantograph (motion amplifier/reducer with programmable ratio)
- G-series: Planetary summing
- Spatial distribution: amplitude varies across grid

**How it works:** Between each cell's planetary output and its pixel rod, insert a small PANTOGRAPH linkage. The pantograph ratio determines the pixel's amplitude. Different cells have different ratios:
- Center cells: ratio 1.5 → large amplitude (15mm)
- Middle cells: ratio 1.0 → standard amplitude (10mm)
- Edge cells: ratio 0.5 → small amplitude (5mm)

The result: the wave has a GAUSSIAN AMPLITUDE ENVELOPE. The center of the grid has tall waves, the edges have small waves. The wave "focuses" toward the center.

**Novel motion profile: AMPLITUDE-MODULATED WAVE**
- The wave has shape × envelope: frequency content determined by cam inputs, amplitude envelope determined by pantograph ratios
- Like a WAVE PACKET in quantum mechanics — oscillation modulated by an envelope
- The envelope shape is set by choosing pantograph ratios — Gaussian, conical, saddle, etc.
- Different envelope shapes make the sculpture look COMPLETELY different even with the same inputs

**Why it's novel:** Spatial amplitude modulation in a mechanical wave machine. No existing machine varies amplitude across its surface. This is common in digital wave simulation but has never been done mechanically.

---

## PART 4: TWELVE NOVEL MOTION PROFILES (Summary)

| # | Profile | Key Mechanism | Visual Character | Sound |
|---|---------|--------------|-----------------|-------|
| 1 | **Asymmetric Tidal** | Gravity + escapement | Fast crests, slow troughs | Metallic rain |
| 2 | **Tunable Pointed Waves** | Hooke's joint + variable angle | Adjustable crest sharpness | Quiet |
| 3 | **Programmable Harmonics** | Nested eccentric + polygon cams | Different textures per region | Quiet |
| 4 | **Orbit-Modulated Sum** | Four-bar carrier plate | Nonlinear wave distortion | Gear mesh |
| 5 | **Shadow Theatre** | Pin gears + point light | Dual output: wave + shadow pattern | Pin mesh click |
| 6 | **Lissajous Surface** | Dual trammels per cell | 2D pixel orbits, trajectory field | Quiet |
| 7 | **Texture-Mapped Wave** | Ratchet + smooth mixed | Digital edges, analog center | Mixed tick/smooth |
| 8 | **Freeze-Frame** | Self-locking screw | Instant stop, holds position | Quiet |
| 9 | **Selective Resonance** | Parametric pendulums | Patchy activation, shifting hotspots | Pendulum swoosh |
| 10 | **Continuously Tunable** | Worm + cone pulley | Morphing between rational/irrational | Worm whisper |
| 11 | **Programmable Defects** | Per-cell reversal lever | Splash points, reflection walls | Click (lever) |
| 12 | **Amplitude Envelope** | Pantograph per cell | Wave packet, focused center | Quiet |

---

## PART 5: DEEPEST INSIGHTS — PATTERN-LEVEL DISCOVERIES

### Discovery 1: The INVERSION Principle Scales to the Whole Sculpture

Reuleaux's key insight was that EVERY mechanism has N inversions (fix different links as frame). Applied to our sculpture:

| What's "fixed" (frame) | What moves | Result |
|------------------------|-----------|--------|
| Grid (current design) | Cam shafts rotate, pixels translate | Standard wave surface |
| Cam shafts fixed | Grid translates/rotates | The grid IS the wave — whole surface undulates as one body |
| Pixels fixed (rods grounded) | Cell housings move around fixed rods | Inverted wave — the FRAME undulates, pixels are the reference |

The "grid moves, cams fixed" inversion means: mount the 7x7 grid on a compliant mounting (springs or flexures). Three fixed cams push on the grid from three sides. The entire grid tilts and rocks as a rigid body — a MACROSCOPIC wave motion of the whole object, not individual pixels. Combine this with the standard pixel-level wave for TWO SCALES of wave simultaneously.

### Discovery 2: Every Bug is a Potential Feature

| Engineering "Bug" | Mechanism Source | Sculptural "Feature" |
|-------------------|-----------------|---------------------|
| Hooke's joint velocity ripple | P3 | 2nd harmonic generator |
| Worm drive self-locking | C9, M | Freeze-frame wave |
| Friction wheel slip | W | Organic speed variation |
| Ratchet discontinuity | N | Digital texture contrast |
| Flexible coupling phase jitter | Z7 | Organic imperfection |
| Watt linkage deviation from straight | S1 | Per-cell character variation |
| Gear backlash | Q | Natural reversal cushion |

### Discovery 3: The Harmonic Number = Polygon Side Count

From Set L (constant-breadth cams): the number of sides of the constant-breadth polygon DIRECTLY determines which harmonic it adds to the output:

| Cam shape | Sides | Harmonic added | Wave effect |
|-----------|-------|---------------|-------------|
| Circle (eccentric) | infinity | fundamental only | Pure sinusoid |
| Reuleaux triangle | 3 | 3rd | Sharp crests |
| Curved square | 4 | 4th | Slight asymmetry |
| Curved pentagon | 5 | 5th | Fine ripple |
| Curved hexagon | 6 | 6th | Very fine ripple |

This means you can PROGRAM the harmonic content of each cell by swapping cam profiles. The cam shape IS the Fourier coefficient.

### Discovery 4: Motion Quality is a Material, not just a Parameter

The Reuleaux collection treats motion quality — smooth vs. jerky, exact vs. approximate, locked vs. free — as a DESIGN VARIABLE, not just a consequence. This suggests treating motion quality as a MATERIAL that can be distributed across the grid:

| Motion Quality | Mechanism | "Material" analogy |
|---------------|-----------|-------------------|
| Smooth continuous | Eccentric (E) | Silk |
| Dwell at extremes | Reuleaux cam (L) | Honey (sticky) |
| Discrete steps | Geneva/ratchet (N) | Stone (granular) |
| Self-locking | Worm/screw (M) | Ice (frozen) |
| Exact straight-line | Peaucellier (S35) | Crystal (precise) |
| Approximate line | Watt (S1) | Wood (organic) |
| Velocity-rippled | Hooke's (P3) | Satin (rippled) |
| Friction-variable | Friction wheel (W) | Leather (grippy) |

The sculpture could use MULTIPLE motion materials distributed across the grid, creating a TEXTURE MAP of motion qualities. Edge cells: "stone" (ratcheted). Center: "silk" (smooth). Transition zone: "honey" (dwelling). This has never been done — every wave machine uses one motion quality throughout.

### Discovery 5: Three Untried Summing Topologies

The 18 ideas focused on WHAT does the summing (planetary, screw, cord, linkage). But HOW they're connected also matters:

| Topology | Description | Existing? |
|----------|-------------|-----------|
| **Series sum** | Stage 1 sums A+B, Stage 2 adds C to result | YES (our 2-stage planetary) |
| **Parallel sum** | All 3 inputs simultaneously enter a 3-input mechanism | NO (bevel cube, Hybrid 2A, is closest) |
| **Cascade sum** | Each cell passes its output to the NEXT cell as a 4th input | NO — creates cell-to-cell coupling |
| **Tree sum** | Binary tree: (A+B) and (B+C) computed separately, then combined | NO |
| **Ring sum** | Cells arranged in a ring, each cell sums its inputs + output from previous cell | NO |

The CASCADE topology is especially interesting: if cell [i,j] feeds its output into cell [i+1,j] as a fourth input, then the wave doesn't just superpose 3 inputs — it PROPAGATES through the grid. Each cell's output is influenced by its upstream neighbor. This creates WAVE PROPAGATION DELAY — the wavefront actually takes time to cross the grid, like a real wave. No existing machine does this because Kelvin's design (and all derivatives) use independent parallel summation.

---

## PART 6: THE TOP 5 UNEXPLORED COMBINATIONS

Ranked by the product of (novelty) x (aesthetic impact) x (feasibility):

### #1: "SHADOW ORGAN" (Hybrid 5 variant + Hybrid 10)
Pin-gear planetary + worm drive input + point light
- Worm shafts along 3 sides (simple input, inherent phase)
- All gears are pin gears (transparent)
- Point light behind → shadow patterns on wall
- DUAL OUTPUT: physical 3D wave + 2D shadow interference
- Cone pulleys for live speed tuning
- **Score: novelty=10, aesthetics=10, feasibility=7**

### #2: "TIDAL FREEZE" (Hybrid 8 + Hybrid 1 elements)
Gear-screw differential summing + gravity-assist pixels
- Self-locking screw summing (freeze on power-off)
- Weighted pixels that drop faster than they rise (asymmetric)
- Escapement meters the descent
- **Score: novelty=9, aesthetics=8, feasibility=8**

### #3: "MOTION MATERIAL GRID" (Discovery 4 + Hybrid 7)
Mixed motion qualities distributed across 49 cells
- Center: smooth eccentric (silk)
- Ring 1: Reuleaux cam with dwell (honey)
- Ring 2: ratchet drive (stone)
- Edge: worm with freeze capability (ice)
- 4 different motion textures in one wave surface
- **Score: novelty=10, aesthetics=9, feasibility=6**

### #4: "HARMONIC PALETTE" (L-series + Discovery 3)
Swappable constant-breadth cam profiles per cell
- Each cell has a field-replaceable cam shape
- Triangle = 3rd harmonic, square = 4th, pentagon = 5th
- The cam shape IS the Fourier coefficient
- Visitors can swap cams and watch the wave change character
- **Score: novelty=8, aesthetics=9, feasibility=8**

### #5: "CASCADE WAVE" (Discovery 5 cascade topology)
Cell-to-cell coupling via output → next cell's input
- Each cell sums 3 cam inputs + upstream neighbor's output
- Creates TRUE WAVE PROPAGATION (not instantaneous)
- Wavefront visibly crosses the grid over several seconds
- Physical delay = propagation speed = real wave physics
- **Score: novelty=10, aesthetics=9, feasibility=5**

---

## APPENDIX: Cross-Reference Matrix

Which Reuleaux sets contributed to which hybrids:

| Hybrid | A | B | C | D | E | F | G | I | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z |
|--------|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 Gravity Tide | | | | | | * | | | | | | | | | | * | | | | | | * | | |
| 2 Hooke's Harmonic | | | | | | | * | | | | | | | * | | | | | | * | | | | |
| 3 Nested Eccentric | | | | | * | | | | | * | | | | | | | | | | | | | | |
| 4 Deformed Orbit | | | * | | | | | | | | | | * | | | | | | | | | | | |
| 5 Pin Shadow | | | | | | | | | | | | | * | | * | | | | | | | | | |
| 6 Lissajous Surface | | | | * | | | | | * | | | | | | | | | | | | | | | |
| 7 Texture Map | | | | | * | | * | | | | | * | | | | | | | | | | | | |
| 8 Freeze-Frame | | | | | | | | | | | * | | | | | | | | | | * | * | | |
| 9 Resonance Grid | | | | | | | * | | | | | | | | | | | | | | | * | | |
| 10 Worm Organ | | | * | | | | | | | * | | | | | | | | | | * | | | | |
| 11 Reversal Splash | | | | | | | | | | | | | | | | | | | | | | | * | |
| 12 Amplitude Env | | | | | | | * | | | | | | | | | | | * | | | | | | |
