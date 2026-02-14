# Design Knowledge Skills
## Auto-Loading Distilled Knowledge for Kinetic Sculpture Design

---

## SYSTEM ARCHITECTURE

```
User Input → Pattern Detection → Knowledge Injection → Agent Response
                   ↓
         ┌────────────────────────────────────────┐
         │ KNOWLEDGE SKILLS (distilled, ~50 lines each)
         ├────────────────────────────────────────┤
         │ automata-masters-skill                 │
         │ biomechanics-skill                     │
         │ motion-aesthetics-skill                │
         │ failure-patterns-skill                 │
         │ mechanism-selection-skill              │
         │ compliant-design-skill                 │
         │ design-cognition-skill                 │
         │ wave-mechanics-skill                   │
         │ geometry-gotchas-skill                 │
         └────────────────────────────────────────┘
```

---

# SKILL: AUTOMATA MASTERS (Historical Techniques)

<automata-masters-skill>
## CORE PATTERNS FROM 300 YEARS OF AUTOMATA

### The Cam Barrel (Vaucanson, Jaquet-Droz)
```
ONE rotating drum → MULTIPLE outputs
- Each track on drum controls one motion
- Phased lobes create sequences
- 3D print cam profiles for complex paths
```

### Spiral Cam (Maillardet)
```
Circular cam: 360° = 1 cycle, then repeats
Spiral cam: 360° × N turns = N cycles before repeat
→ 10-turn spiral = 3,600° of programming
```

### The Selector (Jaquet-Droz Writer)
```
Fixed programming + variable selector = reprogrammable
Removable pegs/pins select which cam engages
```

### Weight Sensor (Japanese Karakuri)
```
Mass presence/absence controls mechanism state
Cup on tray → brake engaged → doll stops
Cup removed → brake released → doll moves
NO ELECTRONICS - weight IS the sensor
```

### Ball Counter (Al-Jazari)
```
Falling balls = visual counting + trigger mechanism
Ball falling triggers dragon animation
Ball count shows hours elapsed
```

### Dynamics Cam (Jaquet-Droz Musician)
```
Cam slope = velocity = force modulation
Steep rise → fast motion → forte
Gradual rise → slow motion → piano
```

### KEY INSIGHT
Single motor → cam shaft → N independent motions
Power sources: spring barrel, falling weight, water, sand

### MODERN APPLICATION
- CNC/3D print cam profiles with complex curves
- Stacked cams for multi-axis coordination
- Use cam for ANY programmable motion sequence
</automata-masters-skill>

---

# SKILL: BIOMECHANICS (Natural Motion Translation)

<biomechanics-skill>
## TRANSLATE NATURE → MECHANISM

### Translation Protocol
```
1. Identify biological MOTION (not tissue)
2. Map to kinematic equivalent (linkage/cam/gear)
3. Adapt for rigid body constraints
4. Account for manufacturing
5. Verify principle survives translation
```

### Latch-Mediated Spring Actuation (LaMSA)
```
SLOW loading → FAST release
Mantis shrimp: 10,000g acceleration
Trap-jaw ant: 64 m/s mandible

Motor → Spring → Latch → Output
t_load >> t_release = power amplification

For 10x velocity: wind 1 sec, release 0.1 sec
```

### The Knee as Four-Bar
```
NOT a simple hinge - crossed four-bar linkage
Instant center MOVES during flexion
= combined rolling + sliding
= distributes wear

Use for: organic-looking joint bend
```

### Finger Tendon System
```
ONE actuator → MULTIPLE joints via cable routing
Cable passes through pulleys at each joint
Joint angles couple based on pulley radii
Single pull = coordinated multi-joint curl

Use for: tentacles, grasping, curling motions
```

### Phase-Coupled Oscillators (Fish)
```
Traveling wave = phase-delayed oscillation
Same motor, different cam phases = wave

phase_offset = 360° / n_segments
amplitude = degrees of oscillation

for (i = [0:n-1]) {
  angle = amplitude * sin($t*360 + i*phase_offset);
}
```

### Indirect Flight (Insects)
```
Muscle doesn't attach to wings
Thorax is elastic resonant structure
Wing beat = natural frequency of thorax
Small motor input + resonance = large amplitude

f_natural = (1/2π)√(k/m)
Drive AT resonance for efficiency
```

### QUICK TRANSLATION
| Biological | Mechanical |
|------------|-----------|
| Muscle+tendon | Spring+cable |
| Ligament | Link length constraint |
| Joint capsule | Rotational limit stop |
| Cartilage | Low-friction bearing |
| Bone | Rigid link |
</biomechanics-skill>

---

# SKILL: MOTION AESTHETICS (Making Motion Feel Alive)

<motion-aesthetics-skill>
## WHY MOTION FEELS ALIVE

### Point-Light Walker Principle
```
10-15 moving points = "human detected"
Motion contains information form does not
Pattern of motion > individual parts

MINIMUM VIABLE LIFE:
✓ Multiple elements in coordination
✓ Phase relationships between elements
✓ Non-uniform velocity (acceleration/deceleration)
✓ Response to implied physics (gravity, momentum)
```

### Disney 12 Principles → Mechanism

**Anticipation**
Dip BEFORE rise in cam profile
Before jumping UP, figure crouches DOWN

**Follow-Through**
Appendages: 10-30° phase lag
Lighter elements = more follow-through
Secondary pendulum, spring return

**Slow In, Slow Out (Ease)**
```
S-curve: s(t) = 10t³ - 15t⁴ + 6t⁵
Methods:
- Cam profile curvature
- Four-bar near dead point
- Spring return
- Flywheel smoothing
```

**Arcs**
Natural motion = curved paths
Most linkages create arcs naturally
Avoid pure linear unless "robotic" intent

### The Breath Cycle
```
ALL living things "breathe"
Inhale: slow expansion (2/3 of cycle)
Exhale: faster contraction (1/3 of cycle)

Asymmetric cam: longer rise, shorter fall
1-6 RPM for subtle breathing effect
```

### Polyrhythm & Golden Phase
```
Avoid integer phase relationships (boring)
Use golden angle: 137.5° between elements

phase[i] = i × 137.5° (mod 360°)

Result: never exactly repeats, always interesting
```

### 3:2 Polyrhythm
```
Element A: 3 cycles per revolution
Element B: 2 cycles per revolution
Different gears → natural polyrhythm
```

### AESTHETICS CHECKLIST
```
VELOCITY:
[ ] Non-linear (ease in/out)?
[ ] No sudden stops/starts?
[ ] Speed matches perceived weight?

RHYTHM:
[ ] Non-integer phase relationships?
[ ] Breathing baseline?
[ ] Polyrhythmic interest?

SECONDARY:
[ ] Follow-through on light elements?
[ ] Anticipation before major moves?
```
</motion-aesthetics-skill>

---

# SKILL: FAILURE PATTERNS (What Goes Wrong)

<failure-patterns-skill>
## DETECT & PREVENT COMMON FAILURES

### Tesla Trap - Material Limits Ignored
```
WARNING SIGNS:
- "Should work in theory"
- Extreme speeds/forces/temps
- No prototype planned
- Thin sections under stress

PREVENTION:
[ ] Identified most stressed component?
[ ] σ = F/A calculated?
[ ] Compared to yield strength?
[ ] Safety factor ≥ 2?
```

### Da Vinci Dream - Power Impossibility
```
WARNING SIGNS:
- "If we just optimize..."
- Fighting 10x+ mismatch
- Adding complexity for small gains

PREVENTION:
[ ] Power available: ___ watts
[ ] Power required: ___ watts
[ ] Ratio > 2? (margin for losses)
    NO → Reconsider approach
```

### V53 Disconnect - Animation Without Connection
```
THE #1 KINETIC AUTOMATA FAILURE

WARNING SIGNS:
- sin($t*360) without physical driver
- Coupler rods that don't touch targets
- Phase/amplitude copied, not calculated

PREVENTION - For EVERY animated element:
[ ] What physically drives this?
[ ] Actual geometric contact in model?
[ ] Animation formula matches kinematics?
[ ] Coupler length CONSTANT (not stretching)?
```

### Impossible Rotation
```
Crank: CAN rotate 360° (pinned at one end)
Coupler: CANNOT rotate 360° (pinned BOTH ends)
Coupler = OSCILLATE only!

Joint types:
- Pin: rotation ONLY
- Slider: translation ONLY
- Fixed: NO motion

Animation MUST match joint capability!
```

### Dead Point Denial
```
Four-bar reaches position where crank+coupler collinear
- Transmission angle → 0° or 180°
- Force transmission → zero
- Mechanism locks or requires infinite force

SOLUTIONS:
[ ] Add flywheel (momentum carries through)
[ ] Add parallel crank at 90° offset
[ ] Redesign linkage proportions
```

### Tolerance Stack
```
Each clearance: ±0.2mm
10 joints in chain: ±2mm accumulated slop!

MITIGATION:
- Minimize chain length
- Preloaded joints (spring, press-fit)
- Parallel paths average errors
- Adjustment at output
```

### Galileo Bias
```
"It worked once, so it works"

PREVENTION:
[ ] Tested at t=0, 0.25, 0.5, 0.75, 1.0?
[ ] Looking for binding point?
[ ] Investigating failures (not explaining away)?
```
</failure-patterns-skill>

---

# SKILL: MECHANISM SELECTION (Decision Trees)

<mechanism-selection-skill>
## QUICK MECHANISM SELECTION

### By Output Motion
```
CONTINUOUS ROTATION:
├─ Same speed → Direct coupling
├─ Speed change → Gear train
└─ Direction change → Bevel/worm/idler

OSCILLATION:
├─ <90° → Crank-rocker four-bar
├─ 90-180° → Four-bar or quick-return
└─ Specific profile → Cam follower

LINEAR RECIPROCATING:
├─ Pure sine → Scotch yoke
├─ Approx sine → Slider-crank
├─ Custom profile → Cam
└─ Long stroke → Rack and pinion

INTERMITTENT:
├─ Fixed positions → Geneva drive
├─ One-way only → Ratchet
└─ Programmable → Cam drum

DWELL (pause):
├─ One end → Cam with dwell
├─ Both ends → Rise-dwell-fall-dwell cam
└─ Middle → Geneva or custom cam
```

### Four-Bar Validation
```
1. Measure: Ground, Crank, Coupler, Rocker
2. Find: S(shortest), L(longest), P, Q
3. Grashof: S + L ≤ P + Q?
   YES → Shortest can rotate 360°
   NO → All oscillate only
4. Transmission angle: 40° < μ < 140°?
5. Dead points in operating range?
6. Verify at t=0, 0.25, 0.5, 0.75
```

### Gear Mesh
```
1. Modules MUST match
2. PD = module × teeth
3. CD = (PD₁ + PD₂)/2 + 0.1mm (backlash)
4. Min teeth: 17 (12 with profile shift)
5. Ratio > 6:1? → Use compound train
```

### Printability
```
Wall thickness: ≥ 1.2mm
Clearance: ≥ 0.3mm
Overhang: < 45° without support
Bridge span: < 10mm
Holes: +0.2-0.4mm diameter
```

### SELECTION MATRIX
| Need | First Choice | Avoid When |
|------|--------------|------------|
| Rot→Rot speed change | Gear train | Ratio not critical |
| Rot→Oscillate | Crank-rocker | Large angle needed |
| Rot→Linear | Slider-crank | Non-sine needed |
| Rot→Intermittent | Geneva | Continuous needed |
| Rot→Dwell | Cam | Simple motion OK |
</mechanism-selection-skill>

---

# SKILL: COMPLIANT DESIGN (Flexures & Tensegrity)

<compliant-design-skill>
## BEYOND RIGID BODY MECHANICS

### Why Compliant?
```
Traditional: Multiple parts, joints, friction, backlash
Compliant: Monolithic, no friction, zero backlash
```

### Living Hinge Dimensions
```
| Material | Min Thickness | Max Bend | Fatigue Life |
|----------|---------------|----------|--------------|
| PLA      | 0.4mm         | 90°      | ~100 cycles  |
| PETG     | 0.3mm         | 120°     | ~1,000       |
| TPU      | 0.5mm         | 180°     | ~10,000      |
| Nylon    | 0.3mm         | 150°     | ~50,000      |
| PP       | 0.3mm         | 180°     | ~1,000,000   |

PRINT: Hinge PARALLEL to layers (XY plane)
STRESS: σ = E × t × θ / (2 × L)
```

### Flexure Primitives
```
BLADE: Thin wide strip, rotation about end
NOTCH: Concentrated rotation, stiff elsewhere
LEAF: Zigzag, allows translation
CROSS-BLADE: Pure rotation, no translation
```

### Bistable Mechanism
```
Snaps between two stable states
No power to hold either state
Uses: Click switches, latches, triggers

F_snap ∝ E × w × t³ × h / L³
Energy to switch: U = ½ × F_snap × h
```

### Tensegrity Properties
```
Struts float in tension network
- Lightweight (compression only in struts)
- Resilient (deforms and returns)
- Shape change via cable tension
- Organic appearance
```

### Design Selection
```
Rotational, low cycle → Living hinge (PLA OK)
Rotational, high cycle → Notch flexure (PP/Nylon)
Translational → Parallel blade flexures
Amplified motion → Compliant amplifier
Snap action → Bistable flexure
```

### Compliant Checklist
```
[ ] High cycle? → Use PP or Nylon
[ ] Motion type identified?
[ ] Stiffness calculated: K = τ/θ
[ ] Stress < σ_yield / 2?
[ ] Printable in one piece?
[ ] Flexures in XY plane?
```
</compliant-design-skill>

---

# SKILL: DESIGN COGNITION (How Experts Think)

<design-cognition-skill>
## COGNITIVE TOOLS FOR DESIGN

### Pattern Recognition
```
Novice: "Some linkages"
Expert: "Grashof crank-rocker approaching dead point"

BUILD PATTERNS:
For every mechanism:
1. Name it (four-bar, geneva, etc.)
2. Classify it (motion type, DOF)
3. Note what makes it work/fail
4. Store as retrievable pattern
```

### 7±2 Rule
```
Working memory holds 7±2 chunks
> 9 things = errors guaranteed

SOLUTION: Hierarchical chunking
- 3-7 subsystems max
- Each subsystem: input → output → interface
```

### TRIZ Contradiction Resolution
```
"Part must be BOTH X and NOT-X"

RESOLUTION:
1. Separation in SPACE - X here, not-X there
2. Separation in TIME - X during load, not-X during assembly
3. Separation in SCALE - macro-X, micro-not-X
4. Separation on CONDITION - X when loaded, not-X when not

The resolution IS your innovation
```

### Breaking Functional Fixedness
```
"Gear" → "Rotating disk with periodic profile"
"Cam" → "Rotating shape that controls distance"

Ask: What ELSE has these attributes?
```

### Eureka Protocol
```
1. IMMERSE: Study thoroughly, exhaust obvious
2. INCUBATE: Stop working, do unrelated thing
3. TRIGGER: Return casually, new angle
4. CAPTURE: Record IMMEDIATELY (fades in minutes)

You cannot think to insight - create conditions
```

### When Stuck
```
- Am I solving the RIGHT problem?
- What would completely different look like?
- What would [expert] do differently?
- What if I had half the budget/space/time?
```

### Expert Design Loop
```
1. UNDERSTAND (don't assume)
2. ABSTRACT (function, not mechanism)
3. GENERATE (3+ different approaches)
4. ANALYZE (physics reality check)
5. EMBODY (cardboard before CAD)
6. REFINE (choose with reasoning)
7. VALIDATE (try to break it)
8. REFLECT (extract pattern)
```
</design-cognition-skill>

---

# SKILL: WAVE MECHANICS (Reuben Margolin Patterns)

<wave-mechanics-skill>
## PATTERNS FROM 20+ YEARS OF KINETIC WAVE SCULPTURE

### Wave Superposition via Mechanical Summation
```
Physical output height = algebraic sum of N wave components
Each component: separate mechanical source (cam, helix, eccentric)

h(x,y,t) = Σ Aᵢ·sin(kᵢ·dᵢ(x,y) - ωᵢt + φᵢ)

Parameters:
- N_components: number of wave sources (typically 2-4)
- amplitude_ratios: set by cam eccentricity or helix radius
- frequency_ratios: set by sprocket/gear ratios to motor
- phase_offsets: set by position along shaft or angular offset

Examples:
- Triple Helix: 3 helices at 120°, block height = Σ slider_i
- Square Wave: 2 perpendicular camshafts, h = A·sin(x) + B·sin(y)
- Cadence: 1 motor through hex matrix with 120° maple links
```

### String Path Optimization
```
For N pulleys in routing matrix: 2^N possible paths exist
Correct path = shortest total string length (string self-minimizes)

Design process:
1. Define pulley positions in matrix
2. Enumerate possible routing combinations
3. Shortest path = physically stable routing
4. Friction constraint: μ^(pulleys_in_series) ≤ acceptable loss

Tool: Python + matplotlib for complex matrices (Margolin's Confluence, 2024)
Rule: Max ~9 pulleys in any single serial path (friction limit)
Parallelize: Many short paths better than few long paths
```

### Topological Wave Mapping
```
Map periodic wave function onto non-Euclidean surface
Continuity constraint: waveform must be continuous across topology

MOBIUS STRIP:
- Use half-integer wavelengths (3.5, NOT 3 or 4)
- Integer wavelengths cancel at twist → flat = bad sculpture
- Edges of Mobius strip lie on a TORUS → 3D parametric equations
- Fabrication: solve shape flat → cut/drill → bend into 3D with jig

SPHERE (Geodesic):
- Icosahedral subdivision gives evenly-spaced output points
- 132 points for frequency-2 icosahedron
- Each point = one string/cable output

TREFOIL KNOT:
- Hypotrochoid path on torus surface
- 3 cables trace the knot from 3 phase-offset points
```

### Friction Cascade
```
Serial pulley friction compounds EXPONENTIALLY

F_output ≈ F_input · μ^n
μ ≈ 0.95 per well-lubricated pulley

 Pulleys | Efficiency | Loss
---------|------------|------
    5    |   0.77     | 23%
    9    |   0.63     | 37%
   15    |   0.46     | 54%
   20    |   0.36     | 64%

DESIGN RULES:
- Max ~9 pulleys in any single string path
- Parallelize: many short paths, not few long paths
- Magic Wave: 3000 pulleys TOTAL, but max ~9 in SERIES
- Power budget: required_force < available_force/2
```

### Variable Amplitude via Adjustable Eccentricity
```
Cam amplitude = distance from shaft center to cam center

SLIDING DISC METHOD:
- Disc cam has oversized bore on shaft
- Slide disc to change offset from center
- More offset = larger amplitude wave
- Can be adjusted during installation/tuning

Use: Tuning wave amplitude per station
Example: Square Wave — plywood disc cams slide on shaft
Each of 9 cams independently adjustable
```

### Imaginary Number Visualization
```
2D planar motion perceived as 3D by human visual cortex

Brain assumes MINIMUM CURVATURE path
→ infers depth dimension that doesn't physically exist
→ inferred depth = IMAGINARY component of complex sinusoid

z(t) = A·cos(ωt) + i·A·sin(ωt)
We SEE the real part. We HALLUCINATE the imaginary part.

Design application:
- Chain of elements, each oscillating in a plane
- Phase offset between adjacent elements
- Observer perceives 3D weaving motion
- Example: Arc Line — 20 rings in 2D, appears 3D
- 4 sprocket sizes (20,21,27,35 teeth) → 27-min cycle
```

### Fool's Tackle (Motion Doubling)
```
Pulley cluster: one block fixed, other moves
Output displacement = 2× input displacement (at ½ force)

   Fixed ─┐
          │   ┌─ String in
    ╔═══╗ │   │
    ║ O ║─┘   │  ← Fixed pulley
    ╚═╦═╝     │
      │       │
    ╔═╩═╗     │
    ║ O ║─────┘  ← Moving pulley
    ╚═══╝
      │
      ↓ 2× displacement

Use: Amplify small cam/helix motion to larger visual effect
Example: Cambrian Wave — central ring doubles motion
Trade-off: 2× displacement but ½ force capacity
```

### Prime Number Grid Spacing
```
Prime-number element counts AVOID visual repetition patterns

Non-prime counts → visible "rows" or "columns" in wave
Prime counts → no common factors → no Moiré patterns

GOOD: 127, 131, 137, 139, 149, 151, 157, 271
BAD:  128 (2^7), 144 (12²), 100 (10²), 256 (2^8)

Example: River Loom — 271 strings (prime)
Use: Choosing grid sizes for hex or irregular wave arrays
Also useful: near-primes where factors are large (e.g., 143 = 11×13)
```

### KEY INSIGHT (Margolin)
```
The mechanism IS the computer.
- Sprocket ratios = frequency ratios (Fourier)
- Cam profiles = waveforms (amplitude shaping)
- Position along shaft = phase offset (traveling wave)
- String routing = signal distribution (parallel channels)

ONE motor → complex wave emergence
NO electronics, NO digital control
Math is built INTO the mechanism
```

### WAVE SCULPTURE CHECKLIST
```
MECHANISM:
[ ] Wave equation identified? h(x,y,t) = ?
[ ] Number of wave components? (1-4 typical)
[ ] Drive method per component? (cam/helix/eccentric)
[ ] Phase offset method? (shaft position/angular offset)

TRANSMISSION:
[ ] Max pulleys in series ≤ 9?
[ ] String routing solved? (shortest path)
[ ] Friction budget: F_required < F_available/2?
[ ] Return mechanism? (gravity/spring/counterweight)

AESTHETICS:
[ ] Grid count prime or near-prime?
[ ] Wave components at non-integer ratio? (avoids boring repeat)
[ ] Tempo matches intent? (1-6 RPM for meditative)
[ ] Materials warm? (wood > metal for organic feel)

STRUCTURE:
[ ] Power budget calculated?
[ ] Tolerance stack for chain length?
[ ] Single motor unless physically impossible?
```
</wave-mechanics-skill>

---

# SKILL: GEOMETRY GOTCHAS (Hard-Won Design Patterns)

<geometry-gotchas-skill>
## PATTERNS THAT PREVENT WASTED PRINTS

### Plate-Sandwich Mechanisms
```
When designing mechanisms between two plates:
- Verify bearing/mounting holes are OUTSIDE any cutouts
- Derived dimensions (slider height from bearing spacing) MUST be COMPUTED
- Bearings that "pinch" a slider: slider height = bearing-to-bearing distance
- Never hardcode a dimension that depends on another dimension
```

### OpenSCAD Coordinate Gotchas
```
Shafts spanning Y gap: rotate([-90, 0, 0]) with center=true
Pulleys in Y gap: rotate([90, 0, 0]) with center=true (flips to -Y)
No v1 + v2 vector addition: [v1[0]+v2[0], v1[1]+v2[1], v1[2]+v2[2]]
Coordinate unification is MANDATORY across all component files
```

### Common Shape Patterns
```
String/cable segments: hull() of two small spheres
V-groove pulley: rotate_extrude a 45° rotated square at OD
Stadium cutout: hull() of two circles in 2D → linear_extrude → difference()
```

### Vertical-Plane Eccentric Rule
```
For radial wave machines with offset cranks driving vertical followers:
Eccentric discs MUST spin in VERTICAL planes.
Horizontal-plane eccentrics produce ZERO vertical motion through rigid rod.
Rod variation with vertical: <2% (correct)
Rod variation with horizontal: 2.25x stretching (wrong)
```

### Wave Sign Errors
```
sin(theta - phi) vs sin(phi - theta) → sign determines wave DIRECTION
tan(tilt) vs sin(tilt) → ~3.5% error at 15°, acceptable for prototype
```

### Coordinate Unification (Wave v10 Lesson)
```
All component files MUST share the same origin and axis conventions.
The Y-coordinate mismatch bug in wave v10 was caused by:
- Main assembly using Y=0 at top
- Component file using Y=0 at bottom
Fix: Define coordinate system in config.scad, reference everywhere
```
</geometry-gotchas-skill>

---

# USAGE NOTES

These skills are:
1. **Read on-demand** via CLAUDE.md Knowledge Routing (read the specific skill when context demands it)
2. **Compact** (~50-100 lines each vs 500-1000 line docs)
3. **Actionable** — checklists, formulas, decision trees
4. **Non-overlapping** — each covers distinct domain

Max 2 skills relevant per design task. Read the specific skill, not the whole file.
