# Rule 99 V2 — Upgrade Specification

## What Changed (V1 → V2)

V1 Rule 99 is a **parts inspector**. It checks individual components: "Is this cam profile smooth? Is this bearing fit ISO 286? Is this bolt strong enough?"

V2 Rule 99 is a **mechanism engineer**. It understands how parts connect, why they connect, and whether the complete kinematic chain actually does what the designer intends.

The difference: V1 can tell you every bolt in a clock is the right grade. V2 can tell you the clock doesn't keep time because gear 3 meshes with the wrong gear.

---

## THE THREE GAPS V1 DOESN'T COVER

### Gap 1: Assembly Intent (the "Shopping Bag" Problem)
V1 verifies parts exist and are individually correct. But it doesn't verify they're ASSEMBLED into a working mechanism. Like checking every grocery item is fresh but never cooking the meal.

**Example (from user feedback):** Gravity Chain Computer visualization has a weight, gears, and wave arms. All correct parts. But they're placed side-by-side like items on a shelf — no kinematic chain connecting weight → chain → gear → shaft → wave arm.

### Gap 2: Kinematic Chain Continuity
A mechanism is a chain: Input → Joint → Link → Joint → Link → ... → Output. Every link in the chain must:
- Physically connect to its neighbors (contact, meshing, cable, belt)
- Have its degrees of freedom constrained correctly (rotation axis, slide axis)
- Transmit force/motion in the right direction

V1 checks individual joints (bearing fit, cam profile). V2 traces the ENTIRE chain from input to output.

### Gap 3: The Margolin Eye (Design Intent Legibility)
An experienced sculptor doesn't just check if a mechanism works — they check if it READS. Can a viewer understand what's happening by watching? Does the motion tell the story?

This is the difference between:
- A cam that technically produces the right displacement curve → engineering correct
- A cam whose motion FEELS like breathing, where you can SEE the follower riding the surface → artistically legible

V1 has no concept of legibility. V2 adds it.

---

## NEW CONSULTANT ROLES (V2 Additions)

### 1. Kinematic Chain Auditor
**Trigger:** ANY mechanism with moving parts
**What it does:**
1. Traces the complete power path: Motor/Input → ... → Output/Pixel
2. At every joint: verifies physical contact between driver and driven
3. At every link: verifies axis of rotation/translation is defined and supported
4. Reports broken chains: "Gear A output shaft ends at X=50. Gear B input starts at X=80. 30mm gap — nothing connects them."

**Implementation approach:**
- Build a directed graph (NetworkX) of the mechanism
- Each node = a part, each edge = a joint/connection
- Check: graph is connected from input to output
- Check: every edge has a defined joint type (revolute, prismatic, gear mesh, belt, cable)
- For gear meshes: verify center distance = (r1 + r2) ± tolerance
- For belt/cable: verify both pulleys are in the same plane
- For cam-follower: verify follower contact point lies on cam profile surface

**OpenSCAD enforcement:**
```
// BAD: Parts placed at absolute coordinates
translate([50, 0, 0]) gear_A();
translate([80, 0, 0]) gear_B();  // 30mm gap, do they mesh?

// GOOD: Parts placed relative to connections
GEAR_A_POS = [50, 0, 0];
GEAR_B_POS = GEAR_A_POS + [GEAR_A_R + GEAR_B_R, 0, 0];  // guaranteed mesh
translate(GEAR_A_POS) gear_A();
translate(GEAR_B_POS) gear_B();
```

**p5.js enforcement:** Same constraint-based placement. Every `translate()` derived from the previous part's output point.

### 2. Gravity & Support Auditor
**Trigger:** ANY design with vertical elements
**What it does:**
1. Identifies every part's Y-position (WEBGL: Y+ = down)
2. For each part: is it supported from above (hanging), below (sitting), or constrained (shaft through bearing)?
3. Reports violations: "Weight is at Y=-50 (above), but the chain it's supposed to fall into is at Y=-80 (even more above). Gravity would pull the weight DOWN (Y+), away from the chain."

**Key rules:**
- Things that hang: blocks, pendulums, weights → must have cable/string to support point ABOVE (more negative Y)
- Things that sit: bases, platforms → must have surface BELOW (more positive Y)
- Things on shafts: constrained by bearing positions, not gravity
- Falling weights drive mechanisms by DESCENDING (Y increasing)

### 3. Rotation Axis Verifier
**Trigger:** ANY rotating part (gear, cam, pulley, shaft)
**What it does:**
1. Every rotating part must have ONE defined rotation axis
2. That axis must pass through a bearing or support point
3. The part must be symmetric (or correctly offset) about that axis
4. Cams rotate about their CENTER SHAFT, not about their edge
5. Gears rotate about their bore, not about a tooth

**Common violations caught:**
- Cam rotating off-center (the Programmable Cam Synthesizer bug)
- Gear spinning about wrong axis
- Shaft rotating in free space (no bearings)
- Pulley floating with no axle

### 4. Mechanism Pattern Library
**Trigger:** When any standard mechanism pattern is detected
**What it does:** Provides the CORRECT kinematic diagram for known mechanism types, so I don't have to reinvent each time.

**Library of verified patterns:**

#### Cam-on-Cam (Stacked Cams)
```
Cam A rotates on shaft → follower A rises/falls
Follower A IS the base plate for Cam B
Cam B rotates on perpendicular shaft mounted ON follower A
Follower B rides on Cam B → final output = sum of both cam profiles

CRITICAL: Cam B's shaft MOVES with follower A. It is NOT fixed in space.
The "on" in cam-on-cam means PHYSICALLY STACKED, not "near each other."
```

#### Scotch Yoke
```
Rotating disk with pin → pin rides in straight slot → slot translates linearly
Pin is at radius R from disk center
Slot constrains motion to ONE axis
Output = R * sin(angle) → PERFECT sine wave

CRITICAL: The slot must be perpendicular to the desired output axis.
The pin must be ON the disk at radius R, not floating nearby.
```

#### Planetary Gear Differential
```
Sun gear (input A) + Ring gear (input B) → Carrier (output = average)
Planet gears mesh with BOTH sun and ring simultaneously
Carrier arm holds planet gear shafts
Output = (sun_speed + ring_speed) / 2

CRITICAL: Planet gears must mesh with both sun AND ring.
Center distances: sun_r + planet_r = ring_r - planet_r
All gears coplanar. Carrier arm connects planet shafts.
```

#### Peaucellier-Lipkin Cell
```
5 bars + 2 fixed points → exact straight line from rotary input
Two long bars from fixed point to junction
Two pairs of equal bars forming diamond
Output point traces perfect straight line

CRITICAL: The TWO fixed ground points are essential.
Without them it's just a floppy diamond, not a straight-line mechanism.
```

#### Whiffletree (Averaging Beam)
```
Two inputs lift/push on ends of a balance beam
Beam pivot at center → pivot height = average of inputs
Can cascade: output of one beam feeds into next level

CRITICAL: Pivot must be at the CENTER of the beam for equal averaging.
Off-center pivot = weighted average (useful but must be intentional).
```

#### Strain Wave (Harmonic) Drive
```
Circular spline (rigid, internal teeth) - FIXED
Flexspline (thin cup, external teeth) - OUTPUT
Wave generator (elliptical cam inside flexspline) - INPUT

Wave generator rotates → flexspline deforms elliptically → teeth mesh at 2 points
Tooth count difference = reduction ratio (e.g., 100:1)

CRITICAL: Flexspline has 2 FEWER teeth than circular spline.
The flex is INSIDE the rigid. The output is the cup, not the cam.
```

#### CoreXY Belt Kinematics
```
Two motors at corners, one continuous belt in figure-8
Carriage position = (motor_A + motor_B) / 2, (motor_A - motor_B) / 2
Both motors same direction → X motion
Motors opposite direction → Y motion

CRITICAL: The belt crosses itself (figure-8). Not two separate belts.
Carriage must be constrained to XY plane by rails.
```

#### Compound Planetary Differential (2-stage, 3 inputs → 1 output)
```
Stage 1: Sun1(shaft A) + Ring1(shaft B) → Carrier1
  - Carrier1 speed = (Sun1_speed × S1_T + Ring1_speed × R1_T) / (S1_T + R1_T)
  - Constraint: S1_T + 2×P1_T = R1_T

Stage 2: Carrier1→Sun2 + Ring2(shaft C) → Carrier2
  - Carrier2 speed = (Sun2_speed × S2_T + Ring2_speed × R2_T) / (S2_T + R2_T)
  - Sun2 is driven BY Carrier1 (coupling shaft between stages)
  - Constraint: S2_T + 2×P2_T = R2_T

Output = Carrier2 → bevel → vertical spool → thread → pixel

CRITICAL: All 3 inputs blend into one unique output rotation.
Different speed ratios at inputs → different phase per node → wave pattern.
Both rings must share the same OD for a common housing.
Bevel transfers bring remote shafts (B, C) into the planetary axis.
Profile shift required for planets with < 17 teeth.
Ring-as-housing: ring gear outer face IS the structural wall (saves diameter).
```

#### Zero-Dependency Gear Strategy (hand-rolled for architecture validation)
```
When proving a new mechanism layout:
1. Use polygon-approximated gear teeth (trapezoid or simple involute)
2. No library imports — file must compile on ANY OpenSCAD install
3. Validate: spatial fit, axis alignment, kinematic chain continuity
4. THEN swap in BOSL2 involute profiles for mesh accuracy

Hand-rolled 2D involute (20-line function):
  function involute_point(base_r, t) = base_r * [cos(t) + t*PI/180*sin(t),
                                                  sin(t) - t*PI/180*cos(t)];
  Generate N points from 0 to tooth_angle, mirror for other flank.

When to use library (BOSL2): production gears that must physically mesh.
When to hand-roll: architecture proofs, spatial debugging, dependency-free sharing.
```

### 5. The Margolin Eye (Design Intent Legibility Consultant)
**Trigger:** After mechanism is verified as physically correct
**What it does:** Evaluates whether the mechanism READS as what it is.

**Legibility checklist:**
1. **Visible cause-and-effect:** Can a viewer trace motor → output? Or is the connection hidden/confusing?
2. **Scale hierarchy:** Important parts larger than incidental parts? Or is everything the same size?
3. **Motion contrast:** Moving parts distinguishable from static? (color, material, size)
4. **Gravity agreement:** Does it LOOK like gravity is real? Things that should hang, hang. Things that should sit, sit.
5. **Speed legibility:** Can you SEE the fast parts are fast and slow parts are slow? Or is everything the same speed?
6. **Material truth:** Does the visual material match the physical behavior? (Heavy things look heavy, flexible things look flexible)

**Scoring:** Each item 0-2 (invisible / partially visible / clearly legible). Total /12. Below 8 = rework.

### 6. Function-First Design Consultant (Topology Optimization Mindset)
**Trigger:** Rule 99 design (pre-design phase)
**What it does:** Instead of "what parts do we need?" starts with "what functions must be performed?"

**Protocol:**
1. Define the FUNCTION: "Transmit rotation from shaft A to shaft B with 3:1 reduction"
2. Define CONSTRAINTS: "Must fit in 50mm cube, single material, 3D printable"
3. Define LOADS: "0.1 N·m torque, 60 RPM input"
4. THEN select mechanism: "Spur gear pair, m=1.5, 20T+60T"
5. THEN derive geometry from mechanism parameters

This is the F1 / topology optimization mindset: define loads and constraints, let function determine form. The "alien bone" shapes from generative design exist because the computer never assumed "this should be a rectangular bracket" — it only knew "hold 500N here, bolted there."

**For kinetic sculpture:** Don't start with "I want a cam." Start with "I want this pixel to follow this motion profile, driven from this shaft, in this space." The mechanism falls out of the requirements.

---

## RESOURCE MANAGEMENT (Library Efficiency)

### Current State: 9 Knowledge Files + ~95 Libraries
The roster is large. Most libraries have never been used. Loading everything wastes context.

### V2 Strategy: Tiered Loading

**Tier 0 — Always Available (in my head):**
- Basic mechanism patterns (cam, linkage, gear, belt, cable)
- Gravity direction, axis conventions
- Constraint-based placement rules
- ISO 286 common fits (H7/g6, H7/k6, H7/p6)

**Tier 1 — Load on Trigger (~10 lines each):**
- Specific mechanism pattern from Pattern Library (Section 4 above)
- Relevant skill from design-knowledge-skills.md
- Tolerance values for declared manufacturing process

**Tier 2 — Load on Demand (full file read):**
- MARGOLIN_KNOWLEDGE_BANK.md → when Margolin/wave/cable discussion
- KINETIC_SCULPTURE_COMPENDIUM.md → when deep mechanism reference needed
- VASHISHT_COLLISIONS.md → when selecting collision to prototype
- VASHISHT_FAVORITES.md → when narrowing design selection

**Tier 3 — Install & Run (Python libraries):**
- Only when actual computation needed
- `pip install` just-in-time, not pre-installed
- Cache results so same computation isn't repeated

### File Index (What Lives Where)

| File | Purpose | When to Read |
|------|---------|-------------|
| `RULE99_CONSULTANT_SPEC.md` | Consultant roles, triggers, tolerance system | When Rule 99 fires |
| `RULE99_LIBRARY_ROSTER.md` | ~95 Python libraries by phase | When specific computation needed |
| `RULE99_V2_UPGRADE.md` | THIS FILE — new consultant roles, patterns | When Rule 99 fires (replaces V1 gaps) |
| `design-knowledge-skills.md` | 9 distilled skills (~50 lines each) | Pattern-matched to user input |
| `MARGOLIN_KNOWLEDGE_BANK.md` | Margolin mechanisms, 34 sculptures | Wave/cable/string discussion |
| `WAVE_SUMMATION_MECHANISMS.md` | 12 mechanisms rated with engineering data | Mechanism selection |
| `KINETIC_SCULPTURE_COMPENDIUM.md` | Deep reference, hundreds of mechanisms | Research phase |
| `VASHISHT_STYLE_DEFINITION.md` | 33+ mechanisms, themes, pixel types | Style/aesthetic decisions |
| `VASHISHT_COLLISIONS.md` | 18 cross-pollinated hybrids | Collision prototype selection |
| `VASHISHT_FAVORITES.md` | 11 selected mechanisms | Active prototype candidates |
| `AUTOMATA_MASTERS.md` | Historical automata techniques | Cam/automata discussion |

---

## WHAT "GREAT" LOOKS LIKE (The Margolin Standard)

You said: "Imagine Ruben Margolin being my consultant."

What a 20-year kinetic sculptor brings:

1. **Instant mechanism diagnosis.** They see a broken four-bar and know it's a Grashof violation before measuring. They see a cam follower chattering and know it's a jerk discontinuity. They don't run Python scripts — they KNOW.

2. **Assembly thinking.** They never think "I need a gear." They think "I need to transmit this motion to that point." The gear is an answer to a question, not a starting point.

3. **Material intuition.** "That arm will flex. I can see it. Make it wider or add a gusset." They don't need FEA — they have thousands of hours of watching things bend, break, and vibrate.

4. **The 3-second test.** A seasoned sculptor can look at a mechanism for 3 seconds and say "that won't work because..." They see the kinematic chain instantly. They see missing supports. They see impossible rotations.

5. **Sound awareness.** They know what every mechanism sounds like. Gears hum, cams tick, cables whisper, bearings whine. They design for the SOUND as much as the motion.

6. **Failure prediction.** "That bearing will fail first." "That cable will stretch." "That bolt will loosen." They've seen every failure mode personally.

### How V2 Approximates This:

| Margolin Has | V2 Approximation |
|-------------|-----------------|
| Instant mechanism diagnosis | Mechanism Pattern Library (verified kinematic diagrams) |
| Assembly thinking | Kinematic Chain Auditor (traces input → output) |
| Material intuition | Structural consultant + deflection limits from experience data |
| The 3-second test | Gravity Auditor + Rotation Axis Verifier + Chain Auditor together |
| Sound awareness | Acoustic Consultant (V1 already has this) |
| Failure prediction | Reliability Planner + Fatigue (V1 already has this) |
| Design legibility | The Margolin Eye (new V2 consultant) |

### The Goal State:
"Apply Rule 99 to a broken design → it instantly identifies:
1. WHAT is broken (kinematic chain gap, axis violation, gravity error)
2. WHY it's broken (this gear doesn't mesh, this cam rotates wrong)
3. WHAT the intent was (this was supposed to be a cam-follower, based on the pattern)
4. HOW to fix it (move part B to X=GEAR_A_POS + GEAR_A_R + GEAR_B_R)

Like any engineer would."

---

## ARCHITECTURE-FIRST PRINCIPLE (added Feb 2026, learned from Gemini collaboration)

**The single biggest process failure to avoid:** Reaching for a library (BOSL2, etc.) before proving the spatial architecture works. The library gives correct profiles but obscures whether the parts actually FIT.

**The correct sequence for any new mechanism in OpenSCAD:**
1. **Vertical Budget** — comment block proving Z-stack fits (Rule 99 vertical)
2. **Envelope Check** — radial fit proof with actual OD numbers
3. **Hand-rolled architecture** — polygon gears, basic cylinders. Zero deps. Compiles anywhere.
4. **Verify** — user opens in OpenSCAD, spins $t, confirms spatial layout
5. **Library upgrade** — swap hand-rolled gears for BOSL2 involute. Now precision matters.
6. **Validate** — full pipeline (compile → validate → render → consistency → Rule 99)

Steps 1-4 should take ONE prompt-response cycle. If it takes more, the architecture isn't clear enough — ask another question, don't generate more code.

**FDM Ground Truth (Stage 0, parallel track):**
Critical fit assumptions (gear mesh clearance, bore press-fit, snap joint) should be test-printed as minimal STLs BEFORE the full assembly is committed. This runs parallel to the spec pipeline. Metal dowel pins (2mm/3mm) for planet axles in any torque application — plastic axles are the #1 failure point.

## IMPLEMENTATION PRIORITY

1. **Mechanism Pattern Library** — highest impact, catches most visualization errors
2. **Kinematic Chain Auditor** — traces connectivity, finds broken chains
3. **Rotation Axis Verifier** — catches the "cams spinning sideways" class of bugs
4. **Gravity & Support Auditor** — catches "upside down" and "floating in space" bugs
5. **The Margolin Eye** — legibility scoring, applied after engineering is correct
6. **Function-First Protocol** — pre-design consultant, topology optimization mindset

Items 1-4 should be applied to EVERY visualization AND every OpenSCAD file.
Item 5 applied after 1-4 pass.
Item 6 applied at design phase only.
Item 7 (Socratic Physics) applied when user is exploring, not yet committed to a design.

---

## NEW MODE: Rule 99 discover — Socratic Physics Consultant

### The Problem It Solves
The user has artistic vision and mechanical intuition — they can SEE when something's wrong, they KNOW what motion they want. But they don't yet have the physics vocabulary to SPECIFY what they want in engineering terms. Without that, the consultant can't derive geometry from function, because function hasn't been defined in physics language.

### Trigger
Say **"Rule 99 discover"** + describe what you want in YOUR language (visual, emotional, sensory).

### How It Works
The consultant becomes a Socratic teacher. It does NOT assume physics knowledge. It:

1. **Asks sensory questions** — translates your vision into physics parameters
2. **Shows the math in your language** — not "0.013 N·m" but "lifting a golf ball 30mm"
3. **Reveals tradeoffs as choices** — not "insufficient torque budget" but "you can have lighter blocks OR fewer pixels OR a bigger motor — which matters most to you?"
4. **Builds physics intuition incrementally** — each question teaches one concept
5. **Accumulates a physics spec** — by the end of the conversation, you have a real engineering specification, built from YOUR answers

### Example Conversation Flow

**You:** "Rule 99 discover — I want a wave sculpture where blocks rise and fall, driven by a single motor. Like breathing. Maybe 10x10 grid."

**Consultant asks — WEIGHT:**
> "Let's figure out how heavy each block is. Picture the block in your hand. Is it:
> - Light like a wooden dice? (~5g)
> - Medium like a golf ball? (~45g)
> - Heavy like a pool ball? (~170g)
> - Something else?"

**You:** "Wooden, light, maybe 3cm cube."

**Consultant translates:**
> "3cm wooden cube = ~15 grams. 100 of them = 1.5 kg total pixel weight.
> To lift ALL 100 blocks at once: you'd need about 15 Newtons of force — imagine holding a 1.5L water bottle upside down. A NEMA 17 motor through a 5:1 gear can do this comfortably.
> But not all blocks lift at the same time in a wave — maybe 30% are rising at once. So the real load is more like half a water bottle. Very manageable."

**Consultant asks — SPEED:**
> "How fast should the wave sweep across? Picture it:
> - Slow like ocean waves from a cliff? (one sweep every 6-8 seconds)
> - Medium like a hand wave? (one sweep every 2-3 seconds)
> - Fast like a ripple in a puddle? (one sweep under 1 second)"

**You:** "Ocean. Slow. Meditative."

**Consultant translates:**
> "6-second period. Motor RPM = depends on mechanism, but roughly 3-10 RPM at the output shaft. This is SLOW for a motor — most run at 100+ RPM. You'll need significant gear reduction (20:1 to 50:1), or use a cam that converts fast rotation into slow output. Good news: slow = quiet, smooth, reliable. Bad news: need more gear reduction = more complexity or a gearmotor."

**Consultant asks — TRAVEL:**
> "How far should each block move? Hold your thumb and index finger apart to show me:
> - A little? (~10mm, fingertip)
> - Medium? (~30mm, thumb width)
> - Dramatic? (~60mm, two fingers)"

**You:** "Medium. 30mm."

**Consultant now HAS a physics spec:**
> "Here's what we've built together:
> - 100 blocks × 15g each = 1.5 kg
> - 30mm travel per block
> - 6-second wave period (3-10 RPM output)
> - Peak simultaneous load: ~30 blocks rising = 0.45 kg = 4.4 N
> - Required torque at pixel: 0.0044 N·m per block
> - Total system torque: ~0.13 N·m (comfortably within NEMA 17 with 5:1 reduction)
> - This is a LOW-POWER sculpture. One small motor handles it. Now we pick the mechanism."

### What Gets Built During Discovery

Each Q&A round fills in one cell of the **Physics Spec Sheet:**

| Parameter | Your Words | Engineering Value | How We Got There |
|-----------|-----------|-------------------|-----------------|
| Block mass | "wooden, light, 3cm" | 15g | wood density × volume |
| Grid size | "10x10" | 100 pixels | direct |
| Wave speed | "ocean, slow" | 6s period, ~5 RPM | user aesthetic preference |
| Travel | "medium, thumb width" | 30mm | user gesture |
| Peak load | (derived) | 4.4 N @ 30% duty | physics: m × g × 30% |
| Torque budget | (derived) | 0.13 N·m | force × lever arm |
| Motor selection | (derived) | NEMA 17 + 5:1 | torque ÷ motor spec |

By the end of discovery, this sheet IS the function definition that the Function-First Design consultant (Section 6) uses to derive geometry.

### The Physics Vocabulary Builder

Each discovery session teaches 2-3 physics concepts through the Q&A. Over multiple sessions:

| Session | Concepts Learned |
|---------|-----------------|
| First sculpture | Mass, force, torque, gear reduction |
| Second sculpture | Friction, efficiency chains (0.95^n), bearing loads |
| Third sculpture | Moment of inertia, acceleration torque, flywheel effect |
| Fourth sculpture | Resonance, natural frequency, vibration isolation |
| Fifth sculpture | Stress, deflection, safety factor |

After 5 sculptures, the user has working physics intuition. They start saying "that arm will flex" instead of "it looks wrong" — same insight, but now they know WHY.

### Integration With Other Modes

```
Rule 99 discover → Physics Spec Sheet
                        ↓
Rule 99 design  → Mechanism selection + design brief (uses spec sheet as input)
                        ↓
Rule 99         → Full scan of coded design (uses spec sheet as acceptance criteria)
                        ↓
Rule 99 [topic] → Targeted deep-dive on specific concern
```

The discover mode is the ENTRY POINT. Everything downstream gets better because the physics are defined upfront in the user's own language.

---

## APPLYING TO VISUALIZATIONS (The Original Problem)

The p5.js visualizations must follow the same rules as OpenSCAD:

```javascript
// BAD: Parts at arbitrary positions
push(); translate(50, 0, 0); drawGear(); pop();
push(); translate(100, 0, 0); drawGear(); pop();  // Do they mesh? Who knows.

// GOOD: Constraint-based placement
const GEAR_A_POS = [50, 0, 0];
const GEAR_A_R = 15;
const GEAR_B_R = 10;
const GEAR_B_POS = [GEAR_A_POS[0] + GEAR_A_R + GEAR_B_R, GEAR_A_POS[1], GEAR_A_POS[2]];
push(); translate(...GEAR_A_POS); drawGear(GEAR_A_R); pop();
push(); translate(...GEAR_B_POS); drawGear(GEAR_B_R); pop();
// Guaranteed mesh. If GEAR_A_R changes, GEAR_B_POS auto-updates.
```

Every visualization draw function should:
1. Define named constants for all dimensions
2. Place each part relative to what it connects to
3. Draw the kinematic chain visibly (shaft lines, belt paths, cable routes)
4. Respect gravity (Y+ = down in WEBGL)
5. Rotate parts about their actual axis (cam about center shaft, not edge)

---

## V2 CONSULTANT GATE ASSIGNMENTS

All V2 consultants are assigned to project life gates (see `RULE99_CONSULTANT_SPEC.md` for full gate definitions):

| V2 Consultant | Gate | When |
|---|---|---|
| Kinematic Chain Auditor | Gate 1: DESIGN | Any mechanism with moving parts |
| Gravity & Support Auditor | Gate 1: DESIGN | Any design with vertical elements |
| Rotation Axis Verifier | Gate 1: DESIGN | Any rotating part |
| Mechanism Pattern Library | Gate 1: DESIGN | Standard mechanism detected |
| The Margolin Eye | Gate 1: DESIGN (late) | After mechanism verified as correct |
| Function-First Design | Gate 1: DESIGN (entry) | Pre-design phase |
| Socratic Physics (discover) | Gate 1: DESIGN (entry) | User exploring, no design yet |

V2 consultants are primarily Gate 1 (Design) because they catch fundamental architecture errors before any metal is cut. They also run as a final pass at Gate 2 entry.

### Built Scripts for Gate 2+3
- `production_pipeline/iso286_lookup.py` -- ISO 286 tolerance lookup (Gate 2)
- `production_pipeline/tolerance_stackup.py` -- Worst-case + RSS + Monte Carlo stackup (Gate 2/3)
