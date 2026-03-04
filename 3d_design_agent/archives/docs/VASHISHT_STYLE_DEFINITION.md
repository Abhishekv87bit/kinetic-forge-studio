# The Vashisht Style — Comprehensive Design Reference

## Purpose
Exhaustive catalog of ALL mechanism options, artistic themes, historical parallels, and novel approaches discussed across brainstorming sessions (Gemini + Claude, Feb 2026). This document defines what the "Vashisht style" IS and how it differs from everything else in kinetic sculpture.

---

## TABLE OF CONTENTS
1. [The Core Constraint](#1-the-core-constraint)
2. [Mechanism Families — Complete Catalog](#2-mechanism-families)
3. [Historical Analog Computer Parallels](#3-historical-analog-computers)
4. [Ancient & Non-Western Mechanisms](#4-ancient-mechanisms)
5. [Pixel Representation Options](#5-pixel-representations)
6. [Cage/Guide Architectures](#6-cage-architectures)
7. [Motor & Drive Strategies](#7-motor-drive-strategies)
8. [Artistic Themes & Visual Languages](#8-artistic-themes)
9. [Modern Art Comparators](#9-modern-art-comparators)
10. [The Vashisht Signature — Differentiation Matrix](#10-vashisht-signature)
11. [Novel Hybrid Mechanisms — Rule 99 Synthesis](#11-novel-hybrids)
12. [Engineering Comparison Tables](#12-engineering-tables)
13. [Prototype Path](#13-prototype-path)
14. [Open Questions](#14-open-questions)

### Companion Documents
- **[VASHISHT_COLLISIONS.md](VASHISHT_COLLISIONS.md)** — 18 cross-pollinated mechanism hybrids. Smashes mechanisms from different centuries, cultures, and disciplines together. Tiers are dead. The art is in the collision.
- **[hybrid_mechanisms_3d.html](../../visualizations/hybrid_mechanisms_3d.html)** — Interactive p5.js 3D visualization of all novel hybrid mechanisms

---

## 1. The Core Constraint

Every mechanism must solve this equation physically:

```
Z_pixel(x, y, t) = f(x, t) + g(y, t) + h(optional_3rd_axis, t)
```

A grid of pixels. Each pixel height = SUM of two (or three) independent wave inputs. The mechanism IS the analog computer that evaluates this equation at every grid point, every moment.

**What is NOT constrained:**
- How the sum is computed (gears, strings, screws, linkages, fluid, magnets)
- What the pixel looks like (block, shingle, ball, void, light)
- How the pixel moves (vertical, rotational, lateral, pneumatic)
- Grid topology (square, hex, polar, geodesic)
- Scale (desktop to room-scale)
- Material (PLA prototype, brass/walnut production)

---

## 2. Mechanism Families — Complete Catalog

### TIER 1: Top Candidates (strong engineering basis)

#### 2.1 Planetary Gear Differential
**Rating: 5/5 stars**
```
Carrier_Speed = (Sun_Speed × S_teeth + Ring_Speed × R_teeth) / (S_teeth + R_teeth)
```
- Sun on X-hex-shaft, Ring driven by Y-worm-shaft, Carrier winds spool
- Most compact per node (~40mm diameter)
- Self-locking via worm gear (holds position without power)
- Worm efficiency ~50% (biggest weakness)
- "Russian doll" nested assembly — mechanism IS ornament
- **Prototype exists:** `wave_node_assembly.scad` with BOSL2 involute gears, compound 2-stage planetary

#### 2.2 Bevel Gear Differential
**Rating: 4/5 stars**
```
Cage_Speed = (Side_A + Side_B) / 2
```
- Two bevel side gears face-to-face, spider bevels in a rotating cage
- Best efficiency of all gear types (~72% vs planetary's ~42%)
- Needs 90-degree bevel adapter per node for perpendicular shaft grid
- Cage can be skeletonized (voronoi, lattice) — spider gears visible through openings
- Classic automotive differential — billions manufactured
- Torque per shaft (10 nodes PLA): 0.10 N-m — well within NEMA 17

#### 2.3 Coaxial Differential Screw ("Climbing Pixel")
**Rating: 4/5 stars**
```
Pixel_Height = Pitch × (Screw_Rotation - Cage_Rotation)
```
- NO STRINGS. Pixel is a nut that physically climbs a threaded rod.
- Inner screw (X-input) + outer splined cage (Y-input) + pixel nut (output)
- Pixel ROTATES as it climbs — secondary shimmer wave (unique to this mechanism)
- Self-holding (thread friction maintains position)
- Highest friction of all candidates (0.31 N-m/shaft)
- "Digital rain" aesthetic — pixels rise/fall like Matrix code
- Needs NEMA 23 for metal version

#### 2.4 Floating Pulley Adder (Margolin Method)
**Rating: 4/5 stars**
```
Z_pixel = (Slider_X_displacement + Slider_Y_displacement) / 2
```
- One continuous rope loop through X-channel pulleys and Y-channel pulleys
- Floating pulley at intersection rides the bight — pixel hangs from it
- Nearly silent (15-25 dB)
- Friction cascade limit: max ~9 pulleys in series (efficiency = 0.95^n)
- Gravity-dependent return (pixel must be heavy enough to overcome friction)
- This is Margolin's method — using it directly risks derivative perception

### TIER 2: Worth Prototyping

#### 2.5 Whiffletree (Balance Beam)
**Rating: 3/5 stars**
```
Center = (Left_End + Right_End) / 2
```
- Horizontal bar pivoting at center. Two inputs lift ends; midpoint averages.
- Simplest mechanism — no gears, no threads, just hinges
- Can cascade: whiffletrees feeding whiffletrees for 3+ inputs (log2(N) levels)
- Takes enormous lateral space — bars collide at 10x10 density
- The bar itself can be the aesthetic (voronoi truss, fractal, organic branch)
- **Historical parallel:** Kelvin Tide Predictor used this exact principle

#### 2.6 Rack & Pinion Spider
**Rating: 3/5 stars**
```
Pinion_Center = (Rack_A + Rack_B) / 2
Pinion_Rotation = (Rack_A - Rack_B) × gear_ratio
```
- Two parallel racks sandwich a floating pinion
- Pinion center tracks the average; pinion also SPINS (secondary rotation)
- "Industrial cyberpunk" aesthetic — gear teeth prominent
- Racks must be perfectly parallel — any skew = binding
- Good for rectangular grid; difficult for hex

#### 2.7 CoreXY Belt Loop
**Rating: 3/5 stars**
```
Position_axis1 = (Motor_A + Motor_B) / 2
Position_axis2 = (Motor_A - Motor_B) / 2
```
- GT2 belt in figure-8 path — same kinematics as every CoreXY 3D printer
- Zero backlash (belt tension eliminates slop)
- Uses off-shelf components (GT2 belts, 20T pulleys, 608ZZ bearings)
- Belt routing for 100 nodes is impractical without novel architecture
- Not self-holding without powered motors

### TIER 2.5: Additional Gear/Linkage Mechanisms (from Gemini session)

#### 2.8 Strain Wave (Harmonic Drive) Adder
- Flexible inner ring (Flexspline) deformed by elliptical plug
- High-tech robotics component — extreme reduction ratio in tiny package
- Can print flexible TPU inner ring alongside rigid PLA outer
- Very compact but hard to tune for analog summation

#### 2.9 Spur Gear Differential (Flat Summing Gear)
- Flat alternative to bevel — two sun gears + planets on same plane
- Much THINNER than bevel (slim ceiling profile)
- Less common than bevel but easier to 3D print (no angled teeth)

#### 2.10 Watt's Linkage Adder
- 3-bar linkage adapted for rotary input summation
- "Steampunk / Steam Engine" aesthetic
- Creates approximately straight-line motion from two rotary inputs

#### 2.11 Peaucellier-Lipkin Cell
- Complex diamond-shaped linkage converting circular to PERFECT linear motion
- Extremely intricate, geometric, and rare in kinetic art
- "Mathematical jewel" — the linkage itself is beautiful

#### 2.12 Slider-Crank "V" Engine
- Two connecting rods push single piston (like a V2 combustion engine)
- "Engine block" aesthetic — aggressive, mechanical
- Good for industrial/cyberpunk theme

#### 2.13 Scotch Yoke
- Pin on spinning wheel moves in horizontal slot of a yoke
- Creates PERFECT sine wave (unlike crank which is approximately sine)
- Used in Lord Kelvin's tide predictors
- Simple, compact, well-understood

#### 2.14 Jansen Linkage Pixel
- Theo Jansen's 11 "Holy Number" bars translate crank to D-shaped walking path
- Pixels would "crawl" rather than simply rise/fall
- Creates complex non-sinusoidal trajectories from simple rotation
- "Segmented creature" aesthetic

#### 2.15 Summing Bar (Norden Style)
- Three parallel bars slide horizontally, connected by pins through diagonal slots
- Z-height satisfies geometry of all slot angles simultaneously
- Purely mechanical vector addition — no gears, no strings

#### 2.16 Iris Diaphragm Lift
- Camera lens aperture mechanism — rotating ring constricts blades
- Blades squeeze a cone upward as they close
- "Sci-fi portal" aesthetic
- Could be pixel-as-aperture (see Section 5)

#### 2.17 Block and Tackle Chain Drive
- Bicycle chains + printed sprockets replacing strings/pulleys
- "Heavy metal, cyberpunk, aggressive" aesthetic
- More durable than string but heavier and noisier

#### 2.18 Timing Belt "GT2" Matrix
- Replace strings with GT2 timing belts + 3D-printed pulleys
- "High-tech CNC machine" look vs wooden toy
- Uses off-shelf components; zero backlash

### TIER 3: Experimental / High Risk

#### 2.19 Compliant "Bow" Mechanism
**Rating: 3/5 stars (but uniquely suited to 3D printing)**
```
Apex_Height ≈ k × (Squeeze_X + Squeeze_Y)
```
- Flexible oval ring. Squeezing from perpendicular directions bulges apex upward.
- NO MOVING PARTS — just flexing TPU/compliant material
- Silent operation, zero friction
- "Breathing" organic aesthetic — completely unique in kinetic art
- Material fatigue limits lifetime; non-linear response; temperature-sensitive

#### 2.20 Scissor Lift (Pantograph)
**Rating: 2/5 stars**
```
Height ≈ sqrt(L^2 - base^2)
```
- X-linkage: pushing base inward extends top dramatically
- Non-linear (square root), fragile at full extension, many pin joints
- Dramatic visual expansion/contraction
- Difficult to drive from two independent inputs simultaneously

#### 2.21 Differential Hydraulic Syringe
**Rating: 2/5 stars**
```
Output_Piston = (Input_A + Input_B) / 2   (Pascal's law)
```
- Two input syringes feed one output cylinder
- PERFECT linear summation (Pascal's law is exact)
- Dramatic with colored fluid in clear tubing
- Leaks inevitable at 100 nodes; air bubbles = spongy; maintenance nightmare
- **Historical parallel:** MONIAC hydraulic computer (1949) — water = money

#### 2.22 Cam-on-Cam Stack
**Rating: 2/5 stars**
```
Height = Cam_A_lift(theta_A) + Cam_B_lift(theta_B)
```
- Two cams in series — Cam A lifts the base of Cam B
- Simple concept but 200 precision cams for 10x10
- Large vertical footprint
- **Historical parallel:** Norden Bombsight — 3D cam surfaces as function maps

#### 2.23 Tensegrity Adder
**Rating: 2/5 stars**
- Floating node held by tension cables only — shortening two cables lifts it
- "Impossible physics" levitation aesthetic
- Non-linear, coupled (each node affects neighbors), near-impossible to tune at scale

#### 2.24 Screw-Scissor Hybrid
**Rating: 2/5 stars**
- Screw creates horizontal motion driving a scissor lift for vertical
- Combines two well-understood mechanisms
- Complex per-node but potentially dramatic visual expansion

#### 2.25 Pneumatic Bellows (Hero of Alexandria style)
**Rating: 2/5 stars**
- Airtight bellows pushed by air pressure
- Ceiling pushes blocks DOWN — sculpture "breathes"
- Silent, organic, but needs air routing to 100+ nodes

#### 2.26 Bhaskara Manifold (Fluid-Weight)
**Rating: 2/5 stars**
- Float inside water cylinder — pump controls water level
- Zero solid moving parts on ceiling
- Silent, buoyant movement
- Plumbing complexity at 100 nodes

#### 2.27 Magnetic Repulsion Spring
**Rating: 1/5 stars**
- Permanent magnets control floating magnet height
- Zero friction, levitation look
- Magnets interfere at 40-60mm spacing; inverse-square force curve; expensive

### TIER 4: Matrix Architecture Variants (how the grid itself is organized)

#### 2.28 Zuse Loom (Sliding Plate Matrix)
- 15 X-rails + 15 Y-rails in crosshatch, physically carved sine-wave ramps
- Follower pins rest on BOTH rails simultaneously — Z = ramp_X + ramp_Y
- Zero gears, zero pulleys, 2-inch ceiling profile
- "Skeletal, Architectural, Flat" aesthetic
- Must physically swap rail plates to change wave shape

#### 2.29 Karakuri Cross-Cam Matrix
- Rotating camshafts at every intersection with miniature whiffletree beams
- "Clockwork, Spinning, Rhythmic" aesthetic
- Cam shape = wave profile; shaft speed = wave frequency

#### 2.30 Concentric Epicyclic (Tube-in-Tube)
- Solid rod inside hollow tube per row
- Miniature planetary differential at each node reads both
- "Jet turbine shaft" aesthetic — concentric rotating elements

#### 2.31 Tide Predictor Pulley Train
- Lord Kelvin's method: single continuous thread weaves through multiple pulleys
- Each pulley moved by Scotch Yoke at its frequency
- Can add 10+ wave components in a single thread path
- Extremely compact per wave component

#### 2.32 Meldahl Harmonic Synthesizer
- Weighted chains and variable eccentrics for summing hundreds of sine waves
- Extension of Kelvin's approach to much higher harmonic count

#### 2.33 Programmable Camshaft
- Modular cam lobes that slide onto hex shaft
- Swap printed lobes to physically "reprogram" the wave
- Standard (sine), Sharp (hex/sawtooth), Complex (noise ripple)
- "Physical synthesizer" — the cam library IS the wave vocabulary

---

## 3. Historical Analog Computer Parallels

Each historical machine embodies a principle directly applicable to wave sculpture.

### 3.1 Lord Kelvin's Tide Predictor (1872)
- **What it did:** Summed up to 10 harmonic components to predict tidal heights
- **How:** Continuous wire through pulleys — each component offsets the wire by its amplitude × sin(phase)
- **Direct parallel:** This IS the Margolin mechanism. Kelvin invented floating-pulley summation 150 years before Margolin applied it to art
- **For Vashisht:** The principle is public domain engineering. The specific artistic application is where originality lives

### 3.2 Michelson-Stratton Harmonic Analyzer (1898)
- **What it did:** Summed 80 harmonic components simultaneously
- **How:** 80 sliders pulling a single tension cable through pulleys
- **Direct parallel:** This is Margolin's slider-channel system at industrial scale
- **For Vashisht:** Could build a "visible harmonic analyzer" where each slider IS a display element, not hidden

### 3.3 Antikythera Mechanism (150 BC)
- **What it did:** Predicted positions of Sun, Moon, planets, eclipses
- **How:** Epicyclic (planetary) gearing — nested gear trains sum multiple periodic motions
- **Direct parallel:** The planetary gear differential IS an Antikythera gear train. One of the oldest known analog computers used exactly this principle
- **For Vashisht:** Frame the sculpture as a "modern Antikythera" — wave prediction through visible gearing

### 3.4 Jacquard Loom (1804)
- **What it did:** Automated textile pattern weaving via punched cards
- **How:** X/Y matrix selection — each card row selects which warp threads lift
- **Direct parallel:** The matrix grid architecture (row shafts + column shafts = pixel selection) is Jacquard's principle applied to wave height instead of thread lifting
- **For Vashisht:** The grid IS a loom. Shafts are warp/weft. Pixels are the "fabric" that emerges

### 3.5 Curta Calculator (1940s)
- **What it did:** 4-function arithmetic in a handheld cylinder
- **How:** Step drum (Leibniz wheel) — digits set by sliders, multiplication by repeated addition with carriage shift
- **Direct parallel:** The coaxial differential screw has Curta DNA — concentric rotating elements where relative rotation = computation
- **For Vashisht:** The aesthetic of a precision instrument in a compact cylinder — "engineering jewelry"

### 3.6 Norden Bombsight (WWII)
- **What it did:** Computed bomb release point from aircraft speed, altitude, wind, ballistics
- **How:** 3D cam surfaces as physical function lookup tables, gyroscopes for stabilization
- **Direct parallel:** Cam-on-cam stacks, 3D cam surfaces encoding wave functions
- **For Vashisht:** The cam surface itself can be a sculptural object — the "program" is visible

### 3.7 Naval Fire Control Computers (WWII)
- **What it did:** Aimed naval guns by computing target lead angle from range, bearing, speed, wind, ship roll
- **How:** Bevel gear differentials + disk-ball-cylinder integrators (mechanical calculus)
- **Direct parallel:** Bevel differentials performing real-time summation — exactly what our bevel gear mechanism does
- **For Vashisht:** Frame the sculpture as a "peaceful fire control computer" — the same math that computed destruction now computes beauty

### 3.8 Konrad Zuse Z1 (1938)
- **What it did:** First programmable mechanical computer
- **How:** Sliding metal plates with shaped notches — binary logic gates via ramp addition
- **Direct parallel:** Sliding plates with profiled edges = a form of cam summation
- **For Vashisht:** Binary logic aesthetic — discrete states vs continuous waves. A sculpture that "computes" visibly

### 3.9 MONIAC / Phillips Machine (1949)
- **What it did:** Modeled the economy using water flow (literally hydraulic economics)
- **How:** Water = money flowing through tanks and pipes. Valves = fiscal policy
- **Direct parallel:** Hydraulic syringe summation — fluid levels as analog computation
- **For Vashisht:** A "wave MONIAC" — colored fluid flowing through transparent channels, levels driving pixel positions

### 3.10 Leibniz Step Drum (17th Century)
- **What it did:** First mechanical calculator CPU — multiply by repeated addition
- **How:** Cylinder with 9 teeth of varying lengths. Position along drum selects digit. "Quantized" stepped output
- **Direct parallel:** A step drum at each node could create TERRACED (discrete-level) pixel heights instead of smooth analog
- **For Vashisht:** "Quantized terrain" — pixels snap to levels like a physical bit-depth. Digital aesthetic from 17th-century mechanism

### 3.11 Nomograms / Slide Rule Linkages
- **What they did:** Graphical computation via aligned scales and index lines
- **How:** Physical intersection-based computation — draw a line through two scales, read answer on third
- **For Vashisht:** The FRAME could be a physical nomogram — ruler guides with sliding index pointers that simultaneously solve wave equations

### 3.12 Ford Rangekeeper (WWII Naval)
- **What it did:** Aimed ship's guns by computing target lead
- **How:** Summing bars + integrators computing range, bearing, speed corrections
- **Direct parallel:** Norden-style summing bars at every grid node

### 3.13 Core Rope Memory (1960s Apollo AGC)
- **What it was:** Physical wire matrix woven through magnetic rings — READ-ONLY memory
- **How:** Wire through a ring = 1, wire bypassing ring = 0
- **Direct parallel:** The string routing through the pulley matrix IS a physical program — like core rope where the weave pattern determines the computation
- **For Vashisht:** Frame the string/cable routing as "weaving a program"

### 3.14 Disk-Ball-Cylinder Integrator (Kelvin/Thomson)
- **What it did:** Mechanical integration (continuous summation over time)
- **How:** A steel ball pressed between a rotating disk and a cylinder. Disk speed = input. Ball position = gain. Cylinder rotation = integral
- **Direct parallel:** Could use a disk integrator as a WAVE GENERATOR (integral of constant = ramp, integral of sine = cosine) — self-generating wave without cam or helix
- **For Vashisht:** NOVEL — no kinetic sculpture has used a mechanical integrator as a wave source

---

## 4. Ancient & Non-Western Mechanisms

### 4.1 South-Pointing Chariot (China, ~200 AD)
- First known differential gear in history
- Two wheels driving a differential — figure always points south regardless of turns
- **For Vashisht:** The differential gear IS the Chinese chariot mechanism. Acknowledge this lineage openly

### 4.2 Al-Jazari's Elephant Clock (Islamic world, 12th C)
- Fluid (water) + mechanical summation creating intermittent motion
- Multiple timing mechanisms driving sequential events
- **For Vashisht:** Intermittent/episodic motion as an aesthetic choice — not continuous sine but triggered events. Water-clock precision meets modern mechanism

### 4.3 Zhang Heng's Seismoscope (China, 132 AD)
- Cascading trigger logic — earthquake vibration knocks ball from dragon's mouth into frog's mouth
- Direction-detecting mechanism via internal pendulum
- **For Vashisht:** Cascading trigger chains — one wave event causes another. Domino-like sequential responses across the grid

### 4.4 Hero of Alexandria (1st C AD)
- Pneumatic/steam-powered theater mechanisms
- Automated puppet shows driven by falling sand weights and string routing
- **For Vashisht:** Sand/granular material as a drive medium? Weight-driven (gravity-powered) wave machine with no motor?

### 4.5 Karakuri Ningyo (Japan, Edo Period)
- Wooden cams, springs, whale baleen springs, precision automata
- Clockwork-like mechanisms in wooden housings
- **For Vashisht:** The aesthetic of visible wooden mechanism — walnut cams, cherry gears. Japanese joinery aesthetic applied to gear housings. Wabi-sabi imperfection in a precision machine

### 4.6 Bhaskara's Mercury Wheel (India, 12th C)
- Fluid (mercury) weight-shifting in sealed tubes around a wheel
- Momentum transfer through fluid mass redistribution
- **For Vashisht:** Sealed-tube fluid shifting as a wave transmission mechanism. Mercury (or colored glycerin) in transparent tubes — visible fluid computation

### 4.7 Ghati-Yantra (Indian Water Clock Gear Trains)
- Precision water clocks driving gear trains for celestial computation
- Astronomical calculations through mechanical means
- **For Vashisht:** Time-based computation — the sculpture computes not just waves but TIME. Sidereal gearing ratios creating cosmological rhythms

### 4.8 Meru-Prastara (India, Pingala's Combinatorics)
- Cascading combinatoric addition — generating Pascal's triangle through physical stacking
- Each number = sum of two above it
- **For Vashisht:** NOVEL — A Pascal's triangle physical adder where each node IS the sum of its parents. Not a grid but a triangular cascade

### 4.9 Vayu-Yantra (Indian Pneumatic Bellows)
- Pneumatic actuators in ancient Indian automata
- Bellows creating linear force from compressed air
- **For Vashisht:** Pneumatic actuation — soft robotics meets kinetic art. Silicone bellows nodes driven by pressure differentials

### 4.10 Jantar Mantar (India, 18th C)
- Architectural-scale analog computers — buildings as measurement instruments
- Sundials, quadrants, and celestial observation tools at monumental scale
- **For Vashisht:** Architecture-as-computation — the sculpture IS a building or architectural element. Room-scale installation where the walls/ceiling ARE the computational surface

### 4.11 Samarangana Sutradhara (India)
- Mechanical automata with cam-on-cam logic described in 11th century Sanskrit text
- Sequential automated behaviors
- **For Vashisht:** Cam-on-cam stacking from ancient Indian texts — claim this lineage

---

## 5. Pixel Representation Options

The "pixel" doesn't have to be a hanging block. It can be:

### 5.1 Hanging Block (Margolin Standard)
- Wooden hex/square block on string, gravity return
- Warm, organic, natural-material feel
- Most proven; most associated with Margolin

### 5.2 Climbing Nut (Coaxial Screw)
- Threaded nut physically climbing a rod
- Spins as it moves — secondary rotation wave
- "Digital rain" / "Matrix code" aesthetic
- Deterministic position (no gravity dependence)

### 5.3 Shingle / Scale
- Overlapping plates that tilt/shift rather than translate vertically
- Creates a "fish scale" or "pangolin armor" surface
- Light catches differently at each angle — moiré shimmer
- Could be driven by rotating each plate via gear mesh

### 5.4 Voxel (3D Pixel)
- Extends into the third dimension — pixel has depth/volume, not just height
- Could be an expandable scissor element or inflatable bladder
- Changes volume, not just position

### 5.5 Terraced Strata
- Instead of smooth height, pixel snaps to discrete levels
- Creates "topographic map" / "rice paddy terrace" stepped landscape
- Can be achieved with notched tracks or detent mechanisms
- Digital aesthetic vs analog smooth

### 5.6 Light Pixel
- Physical element doesn't move — instead controls light transmission/reflection
- Fiber optic, LCD shutter, rotating polarizer, angled mirror
- Creates "wave" through light intensity patterns, not physical displacement
- Extremely quiet; low power; no gravity concerns

### 5.7 Rotating Disc / Paddle
- Flat disc that rotates to face toward/away from viewer
- "Flip-disc" style but continuous rotation
- Creates pattern through angle, not position
- Could combine with height change for 2 DOF

### 5.8 Ball / Sphere
- Sphere that rises/falls on a track
- Can also rotate (painted pattern, color shift)
- "Abacus" aesthetic — beads on rods

### 5.9 Void / Negative Space
- Instead of a solid pixel, an APERTURE that opens/closes
- Creates wave pattern through varying hole sizes in a surface
- Light passes through — shadow wave on the floor
- **NOVEL** — no kinetic sculpture uses iris-aperture pixels

### 5.10 Skeletonized Bearing Gimbal
- Faceted cage with miniature flanged bearings (F623ZZ) spinning at nodes
- Hundreds of tiny metallic bearings visible inside intricate printed cages
- "Mechanical jewelry" — every intersection is a kinetic ornament
- Combines with planetary gear for maximum "mechanism-as-ornament"

### 5.11 Turbine Fin / Rifled Pixel
- Pixel with internal rifling or angled fins
- Air resistance or twisted guide string forces spinning during rise/fall
- Creates "propeller shimmer" independent of mechanism
- Works with any vertical-motion mechanism

### 5.12 Topographic Tile
- Top face has texture of specific terrain feature
- When grid aligns = physical 3D map of a mountain range or ocean floor
- Waves make the "geography" shift and reform
- "Living topography" aesthetic

### 5.13 Architectural Obelisk / Gnomon
- Miniature sundial elements at each grid point
- Grid calculates light and shadow (Jantar Mantar inspired)
- Pixel height controls shadow length — wave = moving shadow pattern
- "Solar computer" aesthetic

### 5.14 Lotus Stalk (Indian Yantra)
- Tiered wooden elements that expand in VOLUME (not just height)
- 3-wave interaction creates "Mechanical Forest" of opening/closing flowers
- The pixel IS a blooming lotus — not a block but a form that unfurls

### 5.15 Fluid Level
- Transparent tube with colored liquid
- Level rises/falls based on pressure from wave inputs
- "Thermometer" / "lava lamp" column aesthetic
- Continuous, smooth, bubble-free (if done right)

---

## 6. Cage/Guide Architectures (for Coaxial Screw)

### 6.1 Solid Tube
- Simple, strong, hides the pixel
- Minimum visibility — defeats the purpose of visible mechanism

### 6.2 Tripod Rail
- Three thin rods with sliding ear loops
- Maximum pixel visibility — needle-like, minimal
- "Test tube rack" aesthetic

### 6.3 Double Helix Cage
- Two spiral ribbons around the screw (DNA aesthetic)
- High visibility + Moire shimmer effect as pixel passes through helix
- The cage itself is beautiful — competing visual with the pixel motion

### 6.4 Inverted Spline
- Hex rod INSIDE hollow screw, key through longitudinal slot
- No external cage — pixel appears to float
- "Magic levitation" illusion
- Most mechanically complex to fabricate

### 6.5 Magnetic Coupling (Floating Ring)
- No physical guide — magnetic coupling between inner screw and outer pixel ring
- Maximum "impossible physics" aesthetic
- Impractical at scale (magnet interference between nodes)

---

## 7. Motor & Drive Strategies

### 7.1 Two DC Motors + Helical Cams (Margolin Method)
- 2 motors → fixed wave pattern forever
- Analog purity — mechanism IS the program
- Cheapest (~$50 motors)
- Zero software complexity
- ONE SONG FOREVER — no mode switching

### 7.2 Eight to Ten Motors (Multiplexed Groups)
- Group rows/columns (e.g., every 3rd shaft shares a motor via gearing)
- Some pattern flexibility within groups
- Middle ground on cost/complexity

### 7.3 Twenty Steppers (10 Row + 10 Column)
- **RECOMMENDED for 10x10 square grid**
- Infinite wave vocabulary via software (ESP32 + TMC2209 silent drivers)
- Eliminates ALL cam/linkage complexity
- Cost: ~$200 in motors + drivers
- Live "wave concerts" — transition between modes in real time
- Each shaft independently controlled — any wave equation possible

### 7.4 Thirty Steppers (Hex Grid 3-Axis)
- For 15x15 hex grid: 10 per axis at 0/120/240 degrees
- Three-axis wave interference — crystalline "tripod" patterns
- Most wave vocabulary of any configuration

### 7.5 Hundred+ Individual Servos (Brute Force)
- Every pixel independent — not just wave equations, can do arbitrary images
- ART+COM Kinetic Rain approach (1,216 servos)
- Wiring nightmare, maintenance nightmare
- Loses the "elegant shared-axis math" that makes the matrix beautiful
- Cost: ~$1000+ in servos alone

### 7.6 Single Motor + Mechanical Program (Purist)
- One motor → everything through gear ratios, cam profiles, sprocket chains
- Maximum mechanism complexity, minimum electronics
- Margolin's philosophy — "analog purity"
- Every ratio IS a wave parameter (frequency, phase, amplitude)
- Fixed program but beautiful because the mechanism IS the sculpture

---

## 8. Artistic Themes & Visual Languages

### 8.1 "Precision Instrument" (Recommended Primary)
- Black anodized aluminum frame, polished brass gears, walnut pixels, steel shafts
- Says: "I am a computing machine of extraordinary precision"
- Historical references: Antikythera, Curta, chronometer
- The GEARS are the art. Visible, beautiful, functional

### 8.2 "Digital Rain" / "Matrix Code"
- Climbing pixels on thin rods, dark frame, green or white pixel faces
- The Matrix (1999) aesthetic — cascading vertical motion
- Best with coaxial screw mechanism
- Futuristic, digital, code-made-physical

### 8.3 "Living Organism"
- Organic materials (wood, leather, natural fiber), breathing rhythms
- Asymmetric cam profiles (slow inhale, faster exhale)
- Compliant mechanism (flexing, not rotating)
- Inspired by: jellyfish pulse, lung expansion, heartbeat

### 8.4 "Geological Formation"
- Terraced strata pixels, earth-tone materials, slow movement
- Tectonic plate motion speed (barely perceptible change over minutes)
- Stepped/quantized height levels
- Inspired by: erosion, sedimentation, crystal growth

### 8.5 "Astronomical Instrument"
- Brass, glass, precision circles, celestial references
- Gear ratios encode planetary orbital periods
- Inspired by: orrery, armillary sphere, astrolabe, Jantar Mantar
- The sculpture IS a working astronomical calculator

### 8.6 "Industrial Archaeology"
- Weathered steel, exposed fasteners, visible lubricant
- Imperfect, hand-made feeling (even if CNC'd)
- Inspired by: Victorian engineering, cotton mill machinery, steam-age computation
- Karakuri influence — visible wooden mechanism, wabi-sabi imperfection

### 8.7 "Aquatic / Fluid"
- Transparent/translucent materials, fluid-filled tubes, ripple patterns
- Water or glycerin as the computation medium (hydraulic approach)
- Inspired by: tide pools, coral reef motion, jellyfish
- MONIAC computer aesthetic

### 8.8 "Architectural / Monumental"
- Room-scale, integrated into building structure
- Ceiling/wall/floor as the computational surface
- Inspired by: Jantar Mantar, cathedral rose windows, Islamic geometric tiling
- The building IS the sculpture

### 8.9 "Woven / Textile"
- String/cable as primary visual element, not hidden overhead
- The weave pattern IS the computation — visible string routing
- Loom aesthetic — Jacquard meets kinetic art
- Inspired by: tapestry, macrame, spider webs

### 8.10 "Swiss Watchmaker"
- Intricate, miniature, high-precision
- Compound planetary nodes as tiny mechanical worlds
- Every node is a self-contained "watch movement"
- Inspired by: Curta calculator, chronograph movements, horology

### 8.11 "Ticking Clockwork"
- Stepped/quantized motion — not smooth but discrete "ticks"
- Leibniz Step Drum encoding
- Each pixel snaps to preset heights — "analog pixels"
- Creates stroboscopic illusion when multiple pixels tick at different rates

### 8.12 "Cyberpunk / Chain-Drive"
- Bicycle chains, sprockets, heavy metal aesthetic
- Exposed grease, aggressive geometry
- Inspired by: motorcycle engines, industrial machinery
- Sound IS part of the art — the clicking/clanking is deliberate

### 8.13 "Nautical / Rigging"
- Dense web of cables, pulleys, rope cleats
- Industrial maritime look — the sculpture IS a ship's rigging
- Complex routing patterns visible overhead
- Margolin-adjacent but with heavier, more industrial execution

### 8.14 "Op Art Machine"
- Moire patterns, interference fringes, optical illusions
- Minimal physical motion creates maximum visual complexity
- Inspired by: Bridget Riley, Victor Vasarely
- Overlapping grids with phase-shifted motion

### 8.15 "Light-Play / Shadow"
- Mechanism hidden; output is light patterns on surfaces
- Rotating/tilting elements create moving shadows
- Aperture pixels control light transmission
- Inspired by: camera obscura, stained glass, Islamic mashrabiya screens

---

## 9. Modern Art Comparators

### 9.1 Reuben Margolin
- String + pulley matrix, analog cam drive
- **How Vashisht differs:** Gear/screw summation, digital control, mechanism visible, hex grid

### 9.2 ART+COM (Kinetic Rain, Changi Airport)
- 1,216 independent servo winches
- **How Vashisht differs:** 20 motors via matrix math (100x fewer motors, same result)

### 9.3 BREAKFAST Studio (MegaFaces, Brixels)
- Independent motor per pixel, flip-disc displays
- **How Vashisht differs:** Shared-shaft matrix drive, continuous motion (not binary)

### 9.4 Julius Popp (Bit.Fall)
- Water droplet matrix — transient pixels
- **How Vashisht differs:** Solid persistent pixels, deterministic position

### 9.5 Daniel Rozin (Mechanical Mirrors)
- Individual servo per tile — arbitrary image display
- **How Vashisht differs:** Wave-only motion (constrained to physics), shared-axis elegance

### 9.6 Theo Jansen (Strandbeests)
- Jansen linkage creates walking D-path from simple rotation
- **For Vashisht:** The Jansen linkage converts rotation to complex path — could a "Jansen pixel" trace a non-sinusoidal wave profile?

### 9.7 Naum Gabo (Standing Wave, 1920)
- High-frequency vibration of a single wire creates 3D volume illusion
- **For Vashisht:** Vibrating elements AS pixels — frequency determines apparent volume. NOVEL in kinetic sculpture grid context

### 9.8 Zimoun (Sound Sculptures)
- DC motors + simple materials creating chaotic motion
- **How Vashisht differs:** Precise wave equation, not random noise

---

## 10. The Vashisht Signature — Differentiation Matrix

### What Margolin Does vs. What Vashisht Does

| Dimension | Margolin | Vashisht |
|-----------|----------|----------|
| **Computation** | Hidden overhead (pulleys/cams) | Visible everywhere (mechanism IS art) |
| **Sound** | Nearly silent (strings) | Soft mechanical purr (gear mesh, optional) |
| **Control** | Fixed analog loop (1 motor, 1 wave) | Software-switchable modes (20 steppers, infinite waves) |
| **Pixel DOF** | 1 (up/down only) | 1-2 (up/down + rotation possible) |
| **Gravity** | Required (pixels hang) | Optional (deterministic screw/gear drive) |
| **Grid** | Square/polar | Hexagonal (3-axis interference) |
| **Material** | Warm (wood, string, brass) | Engineered (anodized AL, brass gears, walnut, steel) |
| **Scale path** | Monumental from start | Modular (desktop → room-scale by adding nodes) |
| **Derivation** | Analog purist (no electronics in mechanism) | Digital soul in mechanical body |
| **Historical lineage** | Kelvin Tide Predictor → art | Antikythera/South-Pointing Chariot → art |

### The Six Constants (regardless of mechanism chosen)

1. **Mechanism-as-Ornament:** The gears, screws, or linkages are NEVER hidden. They ARE the sculpture's visual texture. The machine IS the art.

2. **Software Wave Control:** Stepper motors + microcontroller = infinite wave vocabulary. Live "wave concerts" — calm sine → chaotic noise → geometric scanner transitions. Margolin's cams play one song forever.

3. **Pixel Rotation (if applicable):** With coaxial screw or rack-and-pinion, the secondary spin creates shimmer/sparkle propagating independently of height wave. Dichroic film or faceted shapes amplify this.

4. **Hexagonal Grid Topology:** Three-axis interference (0/120/240 degrees) produces crystalline "tripod" and "star" nodes. Looks geological, not oceanic. 30 motors for 15x15 hex grid.

5. **Material Palette:** Black anodized aluminum frame. Polished brass gears. Walnut/cherry wood pixels. Ground steel shafts. Palette says "precision instrument."

6. **Aerospace Grid Frame:** The ceiling matrix itself is a sculpture — voronoi beams, modular generative truss, faceted low-poly structural ribbing. Not Margolin's utilitarian square aluminum tubes.

7. **Detailed Non-Simplified Shapes:** Intricate polyhedrons for pixels (not simple blocks). Skeletonized gear carriers, faceted gyroscopic hubs. Every component is "mechanical jewelry."

8. **Visible Data Paths:** High-vis braided Kevlar or neon paracord strings — an ACTIVE visual element. vs. Margolin's invisible clear fishing line.

9. **High-Density Engine Room:** Lead-screw bank / stepper motor array visible as a "server rack" or "transmission." vs. Margolin's sweeping wooden wheels.

10. **Engineering Heritage Narrative:** Frame the work as continuing the lineage of Antikythera → South-Pointing Chariot → Kelvin Tide Predictor → Naval Fire Control → Curta → YOUR SCULPTURE. The mechanism is a tool of computation applied to beauty instead of war or industry.

### Emotional Target
- **Primary:** Wave/cascade — phase-offset eccentrics, each element slightly behind the last
- **Secondary:** Breathing — asymmetric profile (slow rise, faster fall)
- **Accent:** Surprise — occasional mode switch (calm → glitch → calm) like a startled organism
- **Speed:** 1-3 RPM → pixels at ~10-30mm/sec → "slow, peaceful" meditative quality
- **Rhythm:** Golden angle (137.5 degree) phase offset between adjacent motors → never exactly repeats → organic feel despite digital control

---

## 11. Novel Hybrid Mechanisms — Rule 99 Design Synthesis

These are mechanisms that combine ideas from multiple sources in ways that haven't been done in kinetic art.

> **IMPORTANT: See [VASHISHT_COLLISIONS.md](VASHISHT_COLLISIONS.md) for 18 MORE cross-pollinated hybrids** that go further — smashing mechanisms from different centuries, cultures, and disciplines together without regard for "tiers." The collisions doc is where the REAL creative energy lives. The entries below (11.1-11.14) are the initial "clean" hybrids. The collisions doc is where we got WILD.
>
> **The Vashisht Rule:** Take the mechanism from one century, the material from another, the layout from a third culture, and the purpose from nature. If the combination has never existed before, it's yours.

### 11.1 The Integrator Wave Engine
**Inspiration:** Kelvin's disk-ball-cylinder integrator
**Concept:** Instead of cams or helixes generating the wave, use a MECHANICAL INTEGRATOR. A disk's rotation speed = wave frequency. The ball's position on the disk = amplitude. The cylinder's output = the integral — which IS a sine wave (integral of cosine).
**Why novel:** No kinetic sculpture has used a mechanical integrator as a wave source. The generation mechanism itself is hypnotic to watch.
**Complexity:** High — requires precision disk/ball contact. Production only (not 3D printable).
**Aesthetic:** "Antikythera" — heavy brass disk, polished steel ball, precision instrument feel.

### 11.2 The Cascading Pascal Adder
**Inspiration:** Meru-Prastara (Indian cascading combinatorics) + Whiffletree
**Concept:** Instead of a flat grid where each pixel sums two perpendicular inputs, arrange nodes in a TRIANGULAR CASCADE where each node = (left parent + right parent) / 2. Input wave enters at top row; it cascades down through layers of whiffletree beams.
**Why novel:** Non-rectangular topology. The cascade IS the computation, visible as a waterfall of motion flowing from top to bottom. Pascal's triangle in physical form.
**Complexity:** Low — just pivoting beams + strings. Highly 3D-printable.
**Aesthetic:** "Waterfall" — motion flows downward through a V-shaped cascade.

### 11.3 The Visible Harmonic Analyzer
**Inspiration:** Michelson-Stratton Harmonic Analyzer (1898)
**Concept:** 80 sliders in a row, each driven by a cam at a different harmonic frequency. A continuous wire passes through all sliders — the wire's END POSITION represents the sum of all 80 harmonics. But instead of reading just the end, make EVERY POINT of the wire visible. The wire itself IS the sculpture — it forms a Fourier-synthesized waveform in real space.
**Why novel:** The wire is usually hidden inside a machine. Here, the "computation medium" (the wire/cable) is the visible output.
**Complexity:** Medium — cam fabrication, but simple assembly.
**Aesthetic:** "Living graph" — a single wire forms complex curves in real time.

### 11.4 The Pneumatic Iris Grid
**Inspiration:** Vayu-Yantra (Indian pneumatics) + camera aperture + shadow play
**Concept:** Grid of iris apertures (like camera lens blades). Each iris is opened/closed by pneumatic pressure from two sources (row + column pressure manifolds). Output = shadow pattern on floor/wall below.
**Why novel:** The "pixel" is ABSENCE — a hole of variable size. Light passes through to create the wave pattern in shadow. Mechanism is completely different from any existing kinetic art.
**Complexity:** High — precision iris mechanisms + pneumatic plumbing.
**Aesthetic:** "Mashrabiya" — Islamic geometric screen that breathes and shifts.

### 11.5 The Gyroscopic Summation Node
**Inspiration:** Naval fire control gyroscopes + spinning-top physics
**Concept:** Each node contains a small gyroscope. X-input tilts the gyro mount one way, Y-input tilts it perpendicular. Gyroscopic precession causes the spin axis to precess in a combined direction that IS the vector sum. A pointer on the spin axis traces the wave.
**Why novel:** Uses precession (a deeply counterintuitive physics phenomenon) as the computation method. The spinning elements are mesmerizing.
**Complexity:** Very high — precision bearings, controlled tilt mechanisms.
**Aesthetic:** "Orbital mechanics" — spinning, precessing elements like tiny planets.

### 11.6 The Gravity Chain Computer
**Inspiration:** Hero of Alexandria (sand-weight automata) + catenary curves
**Concept:** No motor. Sculpture is gravity-powered (sand/water weight descending slowly). Weight descends through a series of gear trains that drive wave shafts. Run time = hours before needing reset (like a grandfather clock).
**Why novel:** Pure mechanical computation with ZERO electricity. The "unwinding" IS the performance — when it stops, you rewind it. Ritual/meditation quality.
**Complexity:** Medium — weight + gear train is well-understood (clockwork).
**Aesthetic:** "Clockwork cathedral" — the descent of weight drives waves of beauty.

### 11.7 The Magnetic Fluid Wave (Ferrofluid Display)
**Inspiration:** Bhaskara's mercury wheel + ferrofluid physics
**Concept:** Grid of transparent cells filled with ferrofluid. Electromagnets below (driven by X/Y wave signals) create field peaks that pull ferrofluid into spikes. The spikes ARE the wave surface.
**Why novel:** No mechanical parts AT ALL. Pure field-to-fluid-to-form transformation. The display medium responds directly to the magnetic "computation."
**Complexity:** Low mechanically, high electromagnetically. Ferrofluid is messy, stains everything.
**Aesthetic:** "Alien intelligence" — black spikes rising from nothing, organic and terrifying.

### 11.8 The Resonance Harp
**Inspiration:** Naum Gabo's Standing Wave (1920) + Chladni patterns
**Concept:** Grid of taut strings/wires at different tensions and lengths. Two transducers (X-driver, Y-driver) inject vibration at different frequencies. Where frequencies combine constructively, strings vibrate visibly; where destructive, strings appear still. The WAVE PATTERN emerges from acoustic interference, not mechanical displacement.
**Why novel:** Uses acoustic standing waves as the "pixel." The sculpture SOUNDS its wave pattern — audio and visual are unified.
**Complexity:** Medium — string tensioning + transducer placement.
**Aesthetic:** "Musical instrument" — the sculpture IS a harp that plays visual patterns.

### 11.9 The Sand Erosion Table (Sisyphus Derivative)
**Inspiration:** Sisyphus sand tables + Lissajous patterns
**Concept:** Instead of a ball on a 2D plane (Sisyphus), use a GRID of weighted pendulums (funnels) suspended over a sand bed. Two wave inputs swing the pendulums via strings. Each pendulum traces a local Lissajous pattern in the sand below it. The grid of patterns = the wave surface encoded in sand traces.
**Why novel:** The output is DRAWN, not displayed. The sculpture creates an artifact (the sand pattern) that accumulates over time. Eventually the entire bed fills — then you "reset" (smooth the sand) and it begins again.
**Complexity:** Low — pendulums + string + sand bed.
**Aesthetic:** "Zen garden machine" — automated meditation drawing.

### 11.10 The Moiré Engine
**Inspiration:** Double Helix cage's Moiré effect, scaled to entire grid
**Concept:** Two overlapping grids of parallel lines/slats, one fixed, one moving. The moving grid shifts according to the wave equation. Where the two grids align, they appear transparent. Where misaligned, they appear opaque. The INTERFERENCE PATTERN between the grids IS the wave surface.
**Why novel:** Uses optical illusion, not physical displacement, as the display mechanism. Extremely lightweight and energy-efficient.
**Complexity:** Low — just sliding patterned sheets.
**Aesthetic:** "Op art machine" — Bridget Riley meets computation. The pattern shimmers and flows with minimal motion.

### 11.11 Programmable Physical Synthesizer
**Inspiration:** Modular synthesizer + Jacquard loom punch cards
**Concept:** Cam lobes are SWAPPABLE modules on hex shafts. A library of printed cam shapes (sine, sawtooth, square, noise, custom) can be slid on/off the shaft to physically "reprogram" the wave shape. Each cam = one Fourier component. Stack multiple cams on one shaft = complex waveform.
**Why novel:** The "program" is a physical object you can hold, swap, and combine. Performance art: change the wave by swapping cams mid-show.
**Complexity:** Low — just shaped lobes on a hex shaft.
**Aesthetic:** "Modular synth rack" — wall of interchangeable components.

### 11.12 Cascading Zhang Heng Trigger Grid
**Inspiration:** Zhang Heng's seismoscope + domino chain reactions
**Concept:** Each pixel node has a trigger lever. When a pixel reaches maximum height, it physically trips the lever of its neighbor, which then trips its neighbor. A single wave input at one edge cascades across the grid as a "fracture" — like tectonic plates cracking. The wave propagation speed depends on mechanism speed, not motor speed.
**Why novel:** Self-propagating mechanical wave — the grid "computes" its own propagation. No per-pixel motor drive needed for the cascade.
**Complexity:** Medium — trigger mechanisms + reset springs.
**Aesthetic:** "Earthquake" — landscapes fracturing and reforming.

### 11.13 Compound Waveform Injection
**Inspiration:** Fourier synthesis via software
**Concept:** Even with just 20 steppers, program each motor with `Input = A*sin(wt) + B*sin(3wt) + C*Noise(t)`. The mechanical differential at each node faithfully sums compound X and compound Y. Result = illusion of 5-6 wave sources from just 2 physical axes. The MOTOR becomes the wave synthesizer; the mechanism is just the adder.
**Why novel:** Software complexity enables simple hardware. One compound-programmed stepper replaces multiple cam/helix wave generators.
**Complexity:** Low hardware, medium software (ESP32 + real-time wave math).
**Aesthetic:** Any — this is a control strategy, not a mechanism change.

### 11.14 Ghost Line Aesthetic
**Inspiration:** Matrix drive artifacts
**Concept:** In a row/column matrix, moving Motor Row 10 moves ALL pixels in row 10 simultaneously. This creates visible "ripple artifacts" — horizontal and vertical lines racing across the grid. Instead of fighting this, EMBRACE it as a visual feature. The "ghost lines" become the mechanism's visual fingerprint.
**Why novel:** Turning a bug into a feature. The "digital artifact" IS the Vashisht signature.
**Complexity:** Zero — it's already how the matrix works.
**Aesthetic:** "Scan lines" / "CRT artifact" / "glitch art."

---

## 12. Engineering Comparison Tables

### 12.1 Mechanism vs. Key Metrics

| Mechanism | Math Accuracy | Compactness | 3D Printability | Friction | Self-Holding | Strings? | Pixel Rotation? | Margolin Distance | Wow Factor |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Planetary Gear | Exact | 5/5 | 4/5 | Medium | No* | Yes | No | 4/5 | 4/5 |
| Bevel Gear | Exact | 3/5 | 3/5 | Medium | No | Yes | No | 4/5 | 4/5 |
| Coaxial Screw | Exact | 4/5 | 3/5 | HIGH | Yes | No | YES | 5/5 | 5/5 |
| Floating Pulley | Exact | 3/5 | 5/5 | Cascade | No | Yes | No | 1/5 | 3/5 |
| Whiffletree | Exact | 2/5 | 5/5 | Low | No | Yes | No | 2/5 | 2/5 |
| Rack & Pinion | Exact | 3/5 | 4/5 | Medium | No | Opt | Yes | 4/5 | 3/5 |
| CoreXY Belt | Exact | 3/5 | 4/5 | Low | No | Belt | No | 3/5 | 3/5 |
| Compliant Bow | Approx | 4/5 | 4/5 | Zero | No | No | No | 5/5 | 4/5 |
| Hydraulic | Exact | 2/5 | 3/5 | Low | Yes | No | No | 5/5 | 3/5 |

*Self-locking if worm gear is used

### 12.2 Torque Budget (NEMA 17 = 0.25 N-m available)

| Mechanism | Torque/shaft (10 nodes PLA) | Torque/shaft (10 nodes Metal) | NEMA 17 Pass? |
|-----------|:---:|:---:|:---:|
| Planetary Gear | 0.17 N-m | 0.69 N-m | PLA: YES / Metal: NO |
| Bevel Gear | 0.10 N-m | 0.40 N-m | PLA: YES / Metal: MARGINAL |
| Coaxial Screw | 0.50 N-m | 2.0 N-m | BOTH: NO |

### 12.3 Friction Breakdown (per shaft, 10 nodes, steady-state)

| Source | Planetary | Bevel | Coaxial Screw |
|--------|-----------|-------|---------------|
| Shaft bearings | 0.002 | 0.002 | 0.002 |
| Gear mesh | 0.05 | 0.03 | N/A |
| Worm gear | 0.10 | N/A | N/A |
| Thread friction | N/A | N/A | 0.30 |
| Spool + string | 0.03 | 0.03 | N/A |
| **TOTAL** | **0.19 N-m** | **0.07 N-m** | **0.31 N-m** |

### 12.4 Acoustic Comparison

| Mechanism | Sound Character | dB at 1m | Notes |
|-----------|----------------|----------|-------|
| Planetary (PLA) | Light clicking | 25-35 | Grease reduces significantly |
| Planetary (Brass) | Soft purring | 20-30 | Self-lubricating |
| Bevel (PLA) | Clicking | 30-40 | Harder to silence |
| Coaxial Screw | Scraping | 35-45 | Needs Delrin-on-steel |
| Strings/Pulleys | Nearly silent | 15-25 | Margolin's inherent advantage |

### 12.5 Power Budget (at 2 RPM)

| Configuration | Total Power (PLA) | Total Power (Metal) | PSU Needed |
|---------------|:-:|:-:|:-:|
| 20 shafts, planetary | 0.8 W | 3.2 W | 12V/5A (60W) — massive headroom |
| 20 shafts, bevel | 0.3 W | 1.2 W | Same PSU |
| 20 shafts, screw | 1.3 W | 5.2 W | Same PSU |

---

## 13. Prototype Path

### Phase 1: Single-Node Shootout (1-2 weeks each)
Build ONE node of each top candidate on K2 Plus. Two NEMA 17s per test.

**Test protocol:**
1. Math verification: Input A at +30deg, Input B at 0deg → measure output
2. Friction measurement: Min stepper current to drive
3. Acoustic measurement: Phone dB meter at 1m, 2 RPM
4. Backlash measurement: Reverse direction dead band
5. Visual assessment: Film 30 seconds — is the mechanism beautiful or ugly?
6. Longevity: 10,000 cycles (83 min at 2 RPM), inspect wear

**Candidates (ranked by confidence):**
1. Planetary Gear Node — highest confidence, most compact
2. Bevel Gear Node — best efficiency, classical look
3. Coaxial Screw Node — most unique visual, highest risk

### Phase 2: 3x3 Mini-Grid (2-4 weeks)
Winner from Phase 1 → 9 nodes on 180x180mm frame, 6 steppers.

### Phase 3: 10x10 Full Grid (1-2 months)
100 nodes, 20 motors, ESP32 + TMC2209, full wave equation solver.

### Phase 4: Metal Production (3-6 months)
Design-lock → STEP export → gear cutting → shaft grinding → frame fabrication → anodize/polish/oil → walnut pixels → assembly.

---

## 14. Open Questions

1. **Worm efficiency:** Is 50% too pessimistic for PLA? Test with dynamometer.
2. **Coaxial screw friction:** Can Delrin-on-steel achieve <0.15 coefficient?
3. **Acoustic character:** Does the gear purr enhance or destroy meditative quality?
4. **String vs rigid:** Must the pixel hang (gravity aesthetic) or can it be driven (deterministic)?
5. **Grid topology:** Square vs hex — need interference pattern comparison at 10x10.
6. **Visual weight:** Does a ceiling of 100 gear nodes look oppressive or magnificent?
7. **Maintenance access:** Can a failed node be swapped without disassembling?
8. **Integrator feasibility:** Can a disk-ball-cylinder integrator run at art-sculpture precision (not lab precision)?
9. **Moire engine resolution:** How fine must the grid lines be for convincing wave illusion?
10. **Gravity-powered runtime:** How many hours of wave motion from a 10kg descending weight?
11. **Ferrofluid containment:** Can ferrofluid be sealed permanently in 100 cells without leaking?
12. **Resonance harp tuning:** Can 100 strings be tuned to produce meaningful standing wave patterns from two inputs?

---

## References

### Primary Knowledge Files
- `MARGOLIN_KNOWLEDGE_BANK.md` — 8 mechanism families, 34 sculptures, construction details
- `WAVE_SUMMATION_MECHANISMS.md` — 12 mechanisms rated, engineering analysis, prototype path
- `RULE99_CONSULTANT_SPEC.md` — 95+ consultant tools, tolerance system
- `RULE99_LIBRARY_ROSTER.md` — Python libraries for analysis
- `KINETIC_SCULPTURE_COMPENDIUM.md` — Deep engineering reference

### Brainstorming Sessions
- Gemini AI conversation, Feb 18 2026 — mechanism alternatives, historical computers, ancient mechanisms, artistic themes
- Claude sessions, Feb 2026 — compound planetary design, BOSL2 modeling, engineering analysis

### Historical References
- Lord Kelvin, "The Tide-Predicting Machine" (1872)
- Michelson & Stratton, harmonic analyzer (1898)
- Price, "Gears from the Greeks: The Antikythera Mechanism" (1974)
- Zuse, "Der Computer — Mein Lebenswerk" (autobiography)
- Phillips, MONIAC economic computer (1949)
- Bhaskara II, Siddhanta Shiromani (12th century)
- Al-Jazari, "Book of Knowledge of Ingenious Mechanical Devices" (1206)
