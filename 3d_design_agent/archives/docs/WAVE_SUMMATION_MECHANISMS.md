# Wave Summation Mechanisms — Complete Reference

## Purpose
Comprehensive breakdown of mechanical methods to sum two (or more) wave inputs into a single pixel output height. Derived from reverse-engineering Margolin's matrix and brainstorming alternative approaches for an original kinetic sculpture.

---

## Part 1: Margolin's Matrix — Reverse-Engineered Mechanism

### The Problem Being Solved
Generate a 3D wave surface `h(x,y,t) = f(x,t) + g(y,t)` using only mechanical components. Every "pixel" (hanging block) must move up/down by the **sum** of two independent wave inputs.

### Architecture Overview
```
MOTOR → Helical Cam (X) → Follower Arms → Sliders (Rows)  ─┐
                                                              ├→ Floating Pulley → Pixel
MOTOR → Helical Cam (Y) → Follower Arms → Sliders (Cols)  ─┘
```

### Layer 1: Wave Generation (The Helical Cam)
- **Component**: A rotating shaft with helical cam lobes
- **Offset**: Each cam lobe offset ~12° from the next along the shaft
- **Effect**: As shaft rotates, it pushes follower arms sequentially → creates a "traveling wave" of push/pull motion across 10+ outputs
- **Two assemblies**: One for X-axis (rows), one for Y-axis (columns)
- **Drive**: Single motor can drive both via sprocket/belt with appropriate ratio

### Layer 2: Motion Storage (The Slider-Channel System)
- **The Channel (Fixed)**: A rigid frame holding two rows of pulleys — an upper bank and a lower bank (e.g., 10 pulleys each)
- **The Slider (Moving)**: A shuttle that slides horizontally between the upper and lower pulley banks, carrying its own row of pulleys (e.g., 10 pulleys)
- **The Mechanism**: Block-and-tackle arrangement. As the slider moves outward, the pulleys spread apart, consuming more rope length. Slider position (x) converts directly to rope length consumed (L)
- **Each channel = one tier** of the matrix
- **Follower arm pushes/pulls the slider** based on the helical cam's current phase at that position

### Layer 3: Wave Summation (The Floating Pulley)
This is the computational heart — the "analog adder."

- **One continuous rope loop** connects through the X-channel pulleys and the Y-channel pulleys
- **At the intersection**, a **floating pulley** (not fixed to any structure) rides in the bight of the loop
- **The pixel** (weight/block) hangs from this floating pulley

#### The Math
```
When X-slider pulls rope by distance ΔX:
  → Loop shortens on one side
  → Floating pulley rises by ΔX/2

When Y-slider pulls rope by distance ΔY:
  → Loop shortens on other side
  → Floating pulley rises by ΔY/2

When BOTH pull:
  → Total rise = (ΔX + ΔY) / 2
```

**Result**: `Z_pixel = (Input_X + Input_Y) / 2`

This is a **mechanical differential adder** using tension and path-length changes.

### Layer 4: The Pixel (Output)
- Margolin uses **basswood hexagonal blocks** (Triple Helix) or wooden slats
- Gravity provides the return force — when rope releases, pixel drops
- Block weight must overcome friction cascade (see below)

### Critical Engineering Constraints
| Parameter | Value | Why |
|-----------|-------|-----|
| Max pulleys in series | ~9 | Friction cascade: η = 0.95^n, after 9 → 63% efficiency |
| Prime grid counts | 37, 61, 271 | Avoid Moiré visual repetition patterns |
| Block weight | Must overcome friction | Heavier = more reliable return, but more motor load |
| String material | Spectra/Dyneema 0.5mm | High strength, low stretch, minimal weight |

### What Is vs. Isn't Protectable
| Free to Use (Engineering Primitives) | Protected (Artistic Expression) |
|---------------------------------------|----------------------------------|
| Gravity, tension, sine waves | His specific wood/brass aesthetic |
| Pulleys, cams, sliders, strings | His grid resolution and proportions |
| "Hanging from ceiling" format | The "organic jiggle" of flexible wood rods |
| Grid-based wave addition (predates art — naval gunnery computers, WWII) | His specific material palette |
| Floating pulley as adder | The "feel" of his motion (smooth, ocean-like) |
| Helical cams for phase generation | His Python string-path solver (proprietary) |

---

## Part 2: Alternative Summation Mechanisms

### Evaluation Criteria
For each mechanism:
- **The Math**: How does it perform Z = (X + Y) / 2?
- **Fabrication**: How hard is it to build (especially 3D print)?
- **Friction**: How much energy is lost?
- **Aesthetic**: What does it look/feel like?
- **Scalability**: How does it perform at 10×10 (100 nodes)?

---

### MECHANISM 1: Planetary Gear Differential ★★★★★
**Status**: Top candidate. Strong interest.

#### The Math
```
Carrier_Speed = (Sun_Speed + Ring_Speed) / 2
```
The carrier averages the two gear inputs. A spool on the carrier winds string up/down.

#### Architecture
```
X-Axis Hex Shaft → passes THROUGH center → drives Sun Gear
Y-Axis Worm Shaft → passes ABOVE unit → drives Ring Gear (via worm-to-external-teeth)
                                          → Carrier rotates at average
                                          → Spool on carrier winds string
                                          → Pixel rises/falls
```

#### The "Vashisht Node" Design
Three nested parts (Russian doll):
1. **Sun Gear (Red)**: Hex bore, locks onto X-axis hex shaft. Drives planets from center.
2. **Ring Gear (Green)**: Internal teeth mesh with planets. External worm teeth driven by Y-axis shaft above. Rides on carrier's outer hub.
3. **Carrier/Spool (Blue)**: Cup-shaped housing. Planets spin inside. String winds around outside grooves. Flanged rims trap the ring gear concentrically.

#### Shaft Layout ("Two-Story Waffle Grid")
- **Level 1 (Z=0)**: 10 hex shafts running Left→Right (X-axis, through Sun centers)
- **Level 2 (Z=+35mm)**: 10 worm shafts running Front→Back (Y-axis, above Ring tops)
- **Grid pitch**: 60mm center-to-center (40mm unit + 20mm gap for spacers)
- Shafts never intersect because they're on different vertical planes

#### Assembly Method ("Shish Kebab")
1. Build square aluminum extrusion frame
2. Install Y-axis worm shafts in upper bearing row
3. For each X-shaft: slide on Spacer→Node→Spacer→Node... then push through

#### String-to-Height Conversion
```
Z_lift = Spool_Radius × Carrier_Rotation_Angle
```
- Small spool (10mm Ø): 360° = 31mm lift. Fine resolution.
- Large spool (50mm Ø): 360° = 157mm lift. Dramatic amplitude.

#### Worm Drive Advantage
- Self-locking: Pixel weight cannot back-drive the motor when stopped
- High reduction ratio: Small shaft rotation → precise ring movement
- Perpendicular axis: Allows the "two-story" grid layout

#### Pros
- Most compact per-node
- Hides the "math" inside a drum (clean exterior)
- Self-locking worm prevents gravity back-drive
- Proven automotive mechanism (billions manufactured)
- Moderate 3D print tolerance requirements

#### Cons
- 100 gear sets = lots of printing and assembly
- Worm gears are ~50% efficient (friction)
- Needs lubrication (grease) for smooth operation
- Each node must be identical for uniform wave

#### Metal Production Path
- Sun/Planets: Brass or bronze (self-lubricating with steel)
- Ring: Anodized aluminum (lightweight)
- Carrier/Spool: Delrin or machined aluminum
- Shafts: Ground stainless steel
- Bearings: 608ZZ at every shaft support point

---

### MECHANISM 2: Bevel Gear Differential ★★★★☆
**Status**: Strong interest. Classic engineering.

#### The Math
```
Carrier_Speed = (Shaft_A + Shaft_B) / 2
```
Same equation as planetary, different geometry.

#### Architecture
Two bevel "side gears" face each other on a shared axis. Spider bevel gears (usually 2 or 4) mesh with both side gears inside a rotating cage (carrier).

```
X-Input → Left Side Gear  ─┐
                             ├→ Spider Gears in Cage → Cage rotates at average
Y-Input → Right Side Gear ─┘                         → Spool on cage winds string
```

#### Key Difference from Planetary
- **Planetary**: Inputs are concentric (Sun inside Ring). Compact radially.
- **Bevel**: Inputs are coaxial (both on same axis, facing each other). Compact axially.

#### Design Challenge for Grid
Both inputs enter from the SAME axis direction. To drive from two perpendicular shafts, you need a **bevel gear adapter** at each node to redirect one shaft 90°. This adds a part.

#### Pros
- Most robust differential type (handles high torque)
- Extremely well-documented (automotive heritage)
- The cage can be skeletonized for dramatic visual (voronoi patterns)
- Spider gears visible through cage = mesmerizing

#### Cons
- Bevel gear teeth are harder to 3D print than spur teeth
- Needs support material or multi-axis printing
- The 90° redirect adds complexity per node
- Bigger footprint than planetary per node

#### Metal Production Path
- Side gears: Hardened steel (ground teeth)
- Spider gears: Brass
- Cage: Cast or machined aluminum
- Standard automotive diff components available off-shelf for prototyping

---

### MECHANISM 3: Coaxial Differential Screw ★★★★☆
**Status**: Strong interest. Most visually unique. Hardest to build.

#### The Math
```
Pixel_Height = Pitch × (Screw_Rotation - Spline_Rotation)
```
Height depends on the **difference** in rotation between inner screw and outer cage.

#### Architecture
No strings, no gravity return. The pixel is a **nut that physically climbs** a threaded rod.

```
X-Input → Rotates Inner Threaded Rod (the "Screw")
Y-Input → Rotates Outer Splined Cage (the "Sleeve")
          → Nut is keyed to Cage (must rotate with it)
          → Nut threads engage Screw (must climb when they differ)
          → Pixel IS the nut. It climbs up/down.
```

#### The Three Concentric Parts
1. **Inner Screw (X-Input)**: Quad-start threaded rod. Fast travel per revolution. Connected to X-axis via bevel gear at top.
2. **Outer Cage (Y-Input)**: Slotted tube or rail system. Connected to Y-axis via gear at top. Three vertical slots act as splines.
3. **Pixel Nut (Output)**: Hexagonal nut with internal threads (engage screw) and external tabs (engage cage slots). The visible "pixel."

#### Cage Alternatives (Visibility Problem)
The solid cage hides the climbing pixel. Alternatives:
| Style | Description | Visibility | Aesthetic |
|-------|-------------|------------|-----------|
| **Tripod Rail** | 3 thin rods with sliding ear loops | Maximum | Needle-like, minimal |
| **Double Helix Cage** | 2 spiral ribbons around the screw | High + Moiré effect | DNA-like, shimmering |
| **Inverted Spline** | Hex rod INSIDE hollow screw, key through slot | Maximum (no cage) | "Magic" levitation |
| **Floating Ring** | Magnetic coupling, no physical guide | Maximum | Impossible physics |

#### Unique Attribute: Pixel Rotation
Unlike string systems where pixels only go up/down, screw pixels **spin as they climb**. This creates:
- A secondary "shimmer" wave across the grid
- Color-shifting effects if pixels have asymmetric faces or dichroic film
- Moiré interference with the cage/screw threads

#### Pros
- **No strings at all** — rigid, architectural, "digital rain"
- Pixel position is deterministic (not dependent on gravity/tension)
- Rotation adds a visual dimension no string system has
- Looks like nothing else in kinetic art
- Self-holding: Position maintained without power (thread friction)

#### Cons
- **Friction is the dominant challenge** — thread-on-thread contact at 100 nodes
- Requires precision: misalignment = binding = motor stall
- Heavier than string systems (100 threaded rods + nuts)
- More complex top gearbox (two concentric drives per column)
- 3D-printed threads wear over time → metal production essential for longevity

#### Metal Production Path
- Inner screw: Precision lead screw (ground stainless)
- Cage rails: Hardened steel rods or carbon fiber
- Pixel nut: Brass or Delrin (low friction on steel)
- Linear ball splines if budget allows (near-zero friction)

---

### MECHANISM 4: Whiffletree (Balance Beam) ★★★☆☆
**Status**: Worth prototyping. Simplest to build.

#### The Math
```
Center_Height = (Left_End + Right_End) / 2
```
A horizontal bar pivoting at its center. Two inputs lift the ends; the midpoint averages them.

#### Architecture
```
X-Input → Lifts Left end of bar
Y-Input → Lifts Right end of bar
           → Center of bar = average height
           → String attached to center → Pixel hangs below
```

#### Pros
- Simplest mechanism — no gears, no threads, just hinges
- Very 3D-print friendly (print-in-place hinges possible)
- Easy to debug and maintain
- Can cascade: connect whiffletrees to whiffletrees for 3+ input averaging
- The bar itself can be an aesthetic element (voronoi truss, fractal pattern)

#### Cons
- Takes enormous lateral space — bars must be long enough to clear neighbors
- The tilting bar creates visual "noise" that may distract from the wave
- Not self-holding — needs constant tension/gravity
- Harder to scale to 10×10 without bars colliding

#### Variation: Cascading Whiffletree (3+ inputs)
```
Input A ─┐
         ├→ Bar 1 center ─┐
Input B ─┘                 ├→ Bar 3 center → Pixel
Input C ─┐                 │
         ├→ Bar 2 center ─┘
Input D ─┘
```
Each level halves the inputs. For N inputs, need log₂(N) levels.

---

### MECHANISM 5: Rack & Pinion Spider ★★★☆☆
**Status**: Interesting visual. Worth considering.

#### The Math
```
Pinion_Center_Position = (Rack_A + Rack_B) / 2
Pinion_Rotation = (Rack_A - Rack_B) × gear_ratio
```
Two parallel racks sandwich a floating pinion. The pinion's **center** tracks the average.

#### Architecture
```
X-Input → Moves Rack A vertically (or horizontally)
Y-Input → Moves Rack B vertically
           → Floating Pinion center = average position
           → Pixel attached to pinion axle
```

#### Pros
- Very "industrial" and "cyberpunk" aesthetic
- Gear teeth visible and dramatic
- Linear motion in, linear motion out (no rotation-to-linear conversion needed)
- Pinion also spins → secondary rotation attribute (like coaxial screw)

#### Cons
- Racks must be perfectly parallel — any skew = binding
- Long racks for large amplitude = floppy without guides
- Friction increases with rack length

---

### MECHANISM 6: CoreXY Belt Loop ★★★☆☆
**Status**: Natural fit for a 3D printing enthusiast.

#### The Math
```
Position = (Motor_A + Motor_B) / 2    (one axis)
Position = (Motor_A - Motor_B) / 2    (other axis)
```
This is the kinematics of every CoreXY 3D printer.

#### Architecture
A single continuous GT2 belt in a figure-8 path around pulleys. Two motors at fixed positions. The "head" (pixel carrier) rides the belt intersection.

#### Adaptation for Wave Matrix
Instead of one head, use **10 parallel CoreXY loops** stacked vertically, each driving a row of pixels. Or use the belt loop purely for the Z-axis summation at each node.

#### Pros
- Uses off-shelf components (GT2 belts, 20T pulleys, bearings)
- Zero backlash (belt tension eliminates slop)
- High speed capability
- You already understand this kinematics from your printer

#### Cons
- Belt routing for 100 nodes is a nightmare
- Belts stretch over time → drift
- Not self-holding without powered motors

---

### MECHANISM 7: Compliant "Bow" Mechanism ★★★☆☆
**Status**: Exotic. Only possible with 3D printing.

#### The Math
```
Apex_Height ≈ k × (Squeeze_X + Squeeze_Y)
```
A flexible oval ring. Squeezing from two perpendicular directions causes the apex to bulge upward.

#### Architecture
```
X-Input → Squeezes oval Left-Right
Y-Input → Squeezes oval Front-Back
           → Top of oval bulges UP proportionally
           → Pixel sits on top
```

#### Pros
- NO moving parts — just flexing plastic
- Silent operation
- Can be printed in TPU/flexible filament on K2 Plus
- Organic, "breathing" aesthetic — completely unique
- No friction (no sliding surfaces)

#### Cons
- Material fatigue — flexible filaments crack after millions of cycles
- Non-linear response (squeeze-to-bulge isn't perfectly linear)
- Hard to achieve large amplitude (limited by material elasticity)
- Temperature-sensitive (TPU stiffness changes with heat)

---

### MECHANISM 8: Scissor Lift (Pantograph) ★★☆☆☆
**Status**: Visually dramatic but mechanically fragile.

#### The Math
```
Height ≈ √(L² - base²)   where base is compressed by X+Y inputs
```
An X-shaped linkage. Pushing the base legs inward extends the top.

#### Pros
- Dramatic visual expansion/contraction
- Print-in-place hinges possible
- Large amplification ratio (small input → large output)

#### Cons
- Non-linear (height vs input is a square root, not linear)
- Fragile at full extension
- Lots of pin joints = lots of friction
- Difficult to drive from two independent inputs

---

### MECHANISM 9: Differential Hydraulic Syringe ★★☆☆☆
**Status**: Mad scientist aesthetic. Novel but messy.

#### The Math
```
Output_Piston = (Input_A + Input_B) / 2
```
Two input syringes feed into one output cylinder. Pascal's law does the summation.

#### Architecture
```
X-Input → Pushes Syringe A → Fluid flows to Output
Y-Input → Pushes Syringe B → Fluid flows to Output
                              → Output piston rises by average
                              → Pixel attached to output piston
```

#### Pros
- Perfect linear summation (Pascal's law is exact)
- Can be fully sealed (no dust/debris issues)
- Quiet operation
- Dramatic visual if using colored fluid in clear tubing

#### Cons
- Fluid leaks are inevitable at 100 nodes
- Air bubbles cause spongy response
- Temperature changes alter fluid viscosity
- Maintenance nightmare

---

### MECHANISM 10: Cam-on-Cam Stack ★★☆☆☆
**Status**: Simple concept, limited flexibility.

#### The Math
```
Height = Cam_A_lift(θ_A) + Cam_B_lift(θ_B)
```
Two cams in series. Cam A lifts the entire base of Cam B. Cam B lifts the pixel from that elevated base.

#### Architecture
```
X-Input → Rotates Cam A → Lifts platform
Y-Input → Rotates Cam B (sitting on platform) → Lifts pixel from platform
           → Pixel total height = platform + cam B lift
```

#### Pros
- Conceptually simple
- Well-understood cam design
- High force capability

#### Cons
- Two cams per pixel = 200 precision cams for 10×10
- Large vertical footprint (cams stacked)
- Not easily driven from perpendicular shafts

---

### MECHANISM 11: Tensegrity Adder ★★☆☆☆
**Status**: Visually stunning. Structurally unpredictable.

#### Architecture
A floating node held in place only by tension cables. Shortening two cables from perpendicular directions shifts the node upward.

#### Pros
- "Impossible physics" aesthetic — node appears to levitate
- Lightweight
- Dramatic

#### Cons
- Non-linear and hard to control precisely
- Sensitive to cable stretch and temperature
- Each node affects its neighbors (coupled system)
- Near-impossible to tune 100 nodes independently

---

### MECHANISM 12: Magnetic Repulsion Spring ★☆☆☆☆
**Status**: Cool concept. Impractical at scale.

#### Architecture
Permanent magnets moved closer/further from a floating magnet. Repulsion force changes pixel height.

#### Pros
- No physical contact = zero friction
- "Levitation" aesthetic

#### Cons
- Magnets interfere with neighbors at 40-60mm spacing
- Non-linear force curve (inverse square)
- Temperature-sensitive (magnets lose strength when hot)
- Expensive at 100+ nodes

---

## Part 3: Comparison Matrix

### Top Candidates Head-to-Head

| Criterion | Planetary Gear | Bevel Gear | Coaxial Screw | Whiffletree | Rack & Pinion |
|-----------|---------------|------------|---------------|-------------|---------------|
| **Math accuracy** | Exact average | Exact average | Exact difference | Exact average | Exact average |
| **Compactness** | ★★★★★ | ★★★☆☆ | ★★★★☆ | ★★☆☆☆ | ★★★☆☆ |
| **3D printability** | ★★★★☆ | ★★★☆☆ | ★★★☆☆ | ★★★★★ | ★★★★☆ |
| **Friction** | Medium (gear mesh) | Medium (bevel mesh) | HIGH (thread contact) | Low (hinges only) | Medium (rack mesh) |
| **Self-holding** | No (needs brake) | No | YES (thread friction) | No | No |
| **Strings needed?** | Yes (spool output) | Yes (spool output) | NO (rigid nut) | Yes (hangs from center) | Optional |
| **Pixel rotation?** | No | No | YES (secondary attribute) | No | Yes (pinion spins) |
| **Visual distinctness from Margolin** | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★☆☆☆ | ★★★★☆ |
| **Metal production path** | Clear (automotive parts) | Clear (automotive parts) | Clear (lead screws) | Simple (machined bars) | Moderate |
| **Noise level** | Low-medium (gear whine) | Low-medium | Low (scraping) | Silent | Medium (clicking) |
| **Wow factor** | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★☆☆☆ | ★★★☆☆ |

### Motor Options for All Mechanisms

| Drive Method | Motor Count (10×10) | Wave Flexibility | Cost | Complexity |
|--------------|---------------------|------------------|------|------------|
| 2 DC motors + helical cams | 2 | Fixed (one wave shape forever) | ~$50 | Mechanical nightmare (cams, linkages) |
| 20 steppers (10 row + 10 col) | 20 | Infinite (software-controlled) | ~$200 | Wiring-heavy but mechanically simple |
| 100 individual servos | 100 | Maximum (every pixel independent) | ~$1000+ | Wiring nightmare |

**Recommendation**: 20 steppers. Eliminates all cam/linkage complexity. Enables mode switching (sine → raindrop → noise → scanner). Uses TMC2209 silent drivers.

---

## Part 4: Engineering Analysis (Rule 99 Depth)

### 4.1 Torque Budget — Can 20 NEMA 17s Drive 100 Nodes?

**NEMA 17 specs** (typical 42mm stepper):
- Holding torque: 4.0-5.0 kg·cm (0.40-0.50 N·m)
- Running torque at 200 RPM: ~2.5 kg·cm (0.25 N·m)
- Driver: TMC2209 (silent, 2A peak)

**Per-node load estimate** (worst case — all 10 nodes on one shaft moving together):

| Parameter | Planetary Gear | Bevel Gear | Coaxial Screw |
|-----------|---------------|------------|---------------|
| Pixel mass | 50g (PLA) / 200g (metal) | 50g / 200g | 30g (nut only) |
| Spool radius | 15mm | 15mm | N/A (pitch=4mm) |
| Torque per pixel | 0.007 N·m / 0.029 N·m | 0.007 / 0.029 | Thread friction dominant |
| Gear efficiency | 85% (spur) × 50% (worm) = 42% | 85% × 85% = 72% | 40% (screw self-lock) |
| Effective torque/pixel | 0.017 / 0.069 | 0.010 / 0.040 | 0.050 / 0.200 |
| **10 pixels on shaft** | **0.17 / 0.69 N·m** | **0.10 / 0.40 N·m** | **0.50 / 2.0 N·m** |

**Verdict**:
- **Planetary (PLA)**: 0.17 N·m needed vs 0.25 available → **PASS** (1.5× margin)
- **Planetary (Metal)**: 0.69 N·m needed vs 0.25 available → **FAIL** (needs NEMA 23 or gearbox)
- **Bevel (PLA)**: 0.10 N·m needed → **PASS** (2.5× margin)
- **Bevel (Metal)**: 0.40 N·m needed → **MARGINAL** (needs TMC5160 driver at 3A)
- **Coaxial Screw (PLA)**: 0.50 N·m needed → **FAIL** for NEMA 17 (friction too high)
- **Coaxial Screw (Metal)**: 2.0 N·m needed → **FAIL** (needs NEMA 23 + planetary gearbox)

**Key insight**: The worm gear's 50% efficiency is the planetary's Achilles heel. The coaxial screw's thread friction makes it the hungriest for torque. The bevel gear wins on efficiency.

### 4.2 Friction Analysis — The 10× Rule Applied

From the Compendium: "Design for 10× expected load (3× safety × 3× forgotten friction)."

**Friction sources per mechanism** (steady-state, lubricated):

| Source | Planetary | Bevel | Coaxial Screw |
|--------|-----------|-------|---------------|
| Shaft bearings (2 per shaft × 20 shafts) | 0.001 N·m each | 0.001 each | 0.001 each |
| Gear mesh (per node) | 0.005 N·m | 0.003 N·m | N/A |
| Worm gear (per node) | 0.010 N·m | N/A | N/A |
| Thread friction (per node) | N/A | N/A | 0.030 N·m |
| Spool friction (per node) | 0.002 N·m | 0.002 N·m | N/A |
| String drag (per node) | 0.001 N·m | 0.001 N·m | N/A |
| **Total per shaft (10 nodes)** | **0.19 N·m** | **0.07 N·m** | **0.31 N·m** |
| **With 10× Rule** | **1.9 N·m** | **0.7 N·m** | **3.1 N·m** |

**Conclusion**: With 10× safety, only bevel gear stays within NEMA 17 range. Planetary needs NEMA 23 (1.3 N·m). Coaxial screw needs NEMA 23 + 5:1 gearbox.

### 4.3 Tolerance Stack — 10 Nodes on One Shaft

Using `dimstack` Monte Carlo methodology (10,000 virtual assemblies):

**Planetary Gear (per node)**:
- Sun hex bore: 8.00 +0.20/-0.00 mm (FDM tolerance)
- Hex shaft: 8.00 +0.00/-0.05 mm (ground steel)
- Clearance per node: 0.05-0.25mm
- **10 nodes cumulative angular play**: ±2.5° worst case, ±0.8° RSS
- **Verdict**: Acceptable. Wave phase error <1% at 10 nodes.

**Bevel Gear (per node)**:
- Gear mesh backlash: 0.1-0.3mm per mesh (FDM)
- 90° redirect adds one extra mesh
- **10 nodes cumulative backlash**: 1.0-3.0mm at pixel
- **Verdict**: Marginal. Needs anti-backlash springs or split gears for metal production.

**Coaxial Screw (per node)**:
- Thread clearance: 0.10-0.15mm (FDM)
- Spline slot clearance: 0.20mm (FDM)
- **Single node wobble**: ±0.35mm lateral
- **Verdict**: OK for single nodes, but cumulative binding risk on shared shaft.

### 4.4 Material Selection — Prototype vs. Production

**Prototype (3D Print on K2 Plus)**:

| Part | Material | Why |
|------|----------|-----|
| Gears (sun, planet, ring) | PLA+ or PETG | Rigid, dimensionally stable, low creep |
| Carrier/Spool | PETG | Better layer adhesion for thin-walled cup |
| Pixel weights | PLA + steel shot fill | Weight control |
| Shafts | 8mm ground steel (purchased) | Never print shafts |
| Bearings | 608ZZ (purchased) | Never print bearings |
| Worm shaft threads | PLA at 0.12mm layer height | Fine detail needed |

**Production (Metal + Wood)**:

| Part | Material | Tolerance | Surface Finish |
|------|----------|-----------|----------------|
| Sun/Planet gears | Brass (CZ121) | H7 bore | Ra 1.6μm |
| Ring gear | 6061 Aluminum (anodized) | ±0.05mm teeth | Ra 3.2μm |
| Carrier | 6061 Aluminum (machined) | H7/g6 bore | Ra 1.6μm |
| Pixel blocks | Walnut or cherry wood | ±0.5mm | Hand-sanded 220 grit |
| X-axis shafts | 303 Stainless (ground) | h6 | Ra 0.4μm |
| Y-axis worm shafts | 416 Stainless (ground) | h6 | Ra 0.8μm |
| Frame | 2020 Aluminum extrusion | ±0.1mm | Anodized black |

**Galvanic Corrosion Matrix** (critical for mixed metals):
- Brass on Steel: SAFE (similar nobility)
- Aluminum on Steel: RISK (separate with Delrin washers or anodize)
- Brass on Aluminum: MODERATE (anodize the aluminum)

### 4.5 Bearing Selection & Life

**Per shaft**: 2× bearing mounts (one each end of frame)
**Total bearings**: 20 shafts × 2 = 40 bearings minimum

| Bearing | Bore | Load Rating | L10 Life (at 60 RPM) | Cost |
|---------|------|-------------|----------------------|------|
| 608ZZ | 8mm | 3.45 kN dynamic | >100,000 hours | ~$0.50 |
| 688ZZ | 8mm | 1.37 kN | >50,000 hours | ~$1.00 |
| R1810ZZ | 1/2" (12.7mm) | 2.25 kN | >75,000 hours | ~$2.00 |

**Verdict**: 608ZZ is massive overkill for this application. Use them — they're cheap and immortal at these loads.

**Sleeve bearing alternative** (for aesthetic reasons — visible brass bushings):
- Brass tube: 8mm ID, 12mm OD, 10mm long
- Clearance: 0.05-0.10mm on shaft
- Lubrication: Light machine oil, annual
- Life: 10+ years at <60 RPM

### 4.6 Fatigue & Lifetime Estimate

**Target**: 8 hours/day, 365 days/year, 10-year installation life
**Cycles**: At 2 RPM motor speed → ~3.5 million shaft revolutions/year → **35 million total**

| Component | Failure Mode | Est. Life | Mitigation |
|-----------|-------------|-----------|------------|
| 608ZZ bearings | Seal degradation | >10 years | Use double-sealed (2RS) for dusty environments |
| PLA gears | Tooth wear | 1-2 years | Replace with PETG or Nylon; production = brass |
| Brass gears | Tooth wear | 20+ years | Annual grease |
| GT2 belt (if used) | Stretch/tooth shear | 3-5 years | Replace on schedule |
| Stepper motors | Bearing failure | 10,000+ hours | Use quality (StepperOnline, not knockoffs) |
| Worm threads (PLA) | Surface wear | 6-12 months | Production must be metal |
| Strings (Dyneema) | UV degradation | 2-3 years outdoor | Indoor only, or replace annually |

### 4.7 Acoustic Analysis

From Design Thinking Framework — speed psychology:
- Target: 1-3 RPM for "slow, peaceful" meditative quality
- At this speed, gear noise is minimal

| Mechanism | Sound Character | dB Estimate (at 1m) | Mitigation |
|-----------|----------------|---------------------|------------|
| Planetary (PLA) | Light clicking | 25-35 dB | Grease, tight mesh |
| Planetary (Brass) | Soft purring | 20-30 dB | Self-lubricating |
| Bevel (PLA) | Clicking | 30-40 dB | Harder to silence |
| Coaxial Screw | Scraping/grinding | 35-45 dB | Needs Delrin nut on steel |
| Strings/Pulleys (Margolin) | Nearly silent | 15-25 dB | Inherent advantage |

**Key**: Margolin's string systems are nearly silent. Any gear-based system WILL be audible unless you use brass-on-steel with grease. TMC2209 stepper drivers eliminate motor whine.

### 4.8 Power Budget

From Compendium formulas:
```
P = τ × ω
  = Total_shaft_torque × Angular_velocity
  = 0.19 N·m × (2 RPM × 2π/60)
  = 0.19 × 0.21
  = 0.040 W per shaft (planetary, PLA)
```

**Total for 20 shafts**: 0.80 W (PLA) to 3.2 W (metal pixels)

**Power supply**: 12V/5A (60W) supply handles 20 NEMA 17s with massive margin. The motors are mostly holding position, not doing heavy work.

### 4.9 Scaling Math

From Compendium: "2× size = 8× weight = 16× moment of inertia; motor needs ~8× more torque."

| Grid Size | Nodes | Motors | Est. Total Torque | Motor Class |
|-----------|-------|--------|-------------------|-------------|
| 5×5 | 25 | 10 | 0.10 N·m/shaft | NEMA 14 |
| 10×10 | 100 | 20 | 0.19 N·m/shaft | NEMA 17 |
| 15×15 | 225 | 30 | 0.28 N·m/shaft | NEMA 17 (just) |
| 20×20 | 400 | 40 | 0.38 N·m/shaft | NEMA 23 |

---

## Part 5: Recommended Prototype Path

### Phase 1: Single-Node Proof of Concept (1-2 weeks each)

Build ONE node of each top candidate on the K2 Plus. Two NEMA 17 steppers per test.

**Test protocol per node**:
1. **Math verification**: Input A at +30°, Input B at 0° → measure output. Repeat at 0/90/180/270°.
2. **Friction measurement**: Find minimum stepper current to drive the node. Compare to theoretical.
3. **Acoustic measurement**: Phone dB meter at 1m, motor at 2 RPM. Record character (click, whine, scrape).
4. **Backlash measurement**: Reverse direction, measure dead band with dial indicator.
5. **Visual assessment**: Film 30 seconds. Does the mechanism itself look interesting or ugly?
6. **Longevity quick-test**: Run 10,000 cycles (83 minutes at 2 RPM). Inspect for wear.

**Candidates to prototype (ranked by engineering confidence)**:
1. **Planetary Gear Node** — Highest confidence. Most compact. Worm self-locks.
2. **Bevel Gear Node** — Best efficiency. Classical look. Needs 90° adapter.
3. **Coaxial Screw Node** — Most unique visual. Highest risk (friction/binding).

**Rule 99 triggers for Phase 1**:
- `Rule 99 cam` → Jerk analysis on cam-driven input shaft
- `Rule 99 drive` → gearpy torque flow through gear train
- `Rule 99 tolerance` → dimstack Monte Carlo on node assembly
- `Rule 99 materials` → Galvanic check on shaft-to-gear material pairs

### Phase 2: 3×3 Mini-Grid (2-4 weeks)

Winner from Phase 1 → build 9 nodes on a 180×180mm frame. 6 steppers (3 row + 3 col).

**Test protocol**:
- Cumulative friction: Can 3 nodes on one shaft run from one NEMA 17?
- Adjacent interference: Do nodes physically collide or acoustically resonate?
- Wave verification: Drive row motors with sin(t), sin(t+120°), sin(t+240°). Drive col motors same. Film from below — does the wave surface emerge?
- Software test: Arduino + AccelStepper library, 6-channel simultaneous control
- Mode switching: Sine → noise → raindrop transitions

### Phase 3: 10×10 Full Grid (1-2 months)

Scale to 100 nodes, 20 motors, full ESP32 control with real-time wave equation solver.

**Hardware stack**:
- Controller: ESP32-S3 (dual core, 240MHz)
- Motor drivers: 20× TMC2209 on custom PCB (or 5× CNC shield boards)
- Power: 12V/10A mean-well supply
- Communication: USB serial for live parameter tuning, optional WiFi for remote control
- Software: Wave equation evaluated per-motor per-frame, S-curve acceleration profiles (Ruckig library)

**Wave modes programmable in software**:
| Mode | Row Function | Col Function | Visual Effect |
|------|-------------|-------------|---------------|
| Classic sine | sin(i×k + ωt) | cos(j×k + ωt) | Rolling hills |
| Raindrop | sin(|i-5|×k - ωt) | sin(|j-5|×k - ωt) | Concentric rings from center |
| Scanner | gaussian(i - t) | flat | Sweeping bar |
| Noise | perlin(i, t) | perlin(j, t×0.7) | Chaotic sea |
| Breathing | sin(ωt) uniform | sin(ωt) uniform | All rise/fall together |
| Standing wave | sin(i×k)×cos(ωt) | sin(j×k)×cos(ωt) | Nodes stay still, antinodes oscillate |
| Interference | sin(ωt) + sin(3ωt) | cos(ωt) + cos(2ωt) | Complex ripple with harmonics |

### Phase 4: Metal Production (3-6 months)

Design-lock the mechanism → rebuild critical parts in metal. Follow production pipeline from CLAUDE.md.

**Production sequence**:
1. **STEP export**: OpenSCAD → FreeCAD MCP → clean STEP files per part
2. **Gear cutting**: Send gear STEP files to gear specialist (SDP/SI or Boston Gear for prototypes)
3. **Shaft grinding**: Order precision ground shafts from Misumi or McMaster
4. **Frame fabrication**: Waterjet aluminum plates + welded extrusion frame
5. **Assembly**: Press-fit bearings (H7/p6), slide gears onto shafts, install worm drives
6. **Surface finish**: Anodize aluminum (black), polish brass (clear lacquer), oil steel
7. **Pixel fabrication**: CNC-turned walnut or cherry wood hexagons, hand-sanded

**Rule 99 production triggers**:
- `Rule 99 production` → DFM advisor, BOM generator, nesting, costing
- `Rule 99 materials` → Galvanic matrix, thermal expansion delta, coating spec
- `Rule 99 tolerance` → ISO 286 fit classes, GD&T annotation
- `Rule 99 reliability` → Bearing L10, fatigue life (py-fatigue S-N curves), MTBF

---

## Part 6: The "Vashisht Signature" — What Makes It Yours

### Artistic Separation from Margolin

Applying the Design Thinking Framework emotion→mechanism mapping:

| Margolin's Expression | Your Expression |
|----------------------|-----------------|
| Organic, ocean-like, fluid | Architectural, digital, crystalline |
| Wood/brass/string (warm) | Metal/printed lattice/gear (engineered) |
| Silent (string tension) | Soft mechanical purr (gear mesh) |
| Fixed wave loop (analog purity) | Software-controlled modes (digital soul) |
| Gravity-dependent (pixels hang) | Deterministic (pixels climb or are driven) |
| 1 DOF per pixel (up/down) | 2 DOF per pixel (up/down + rotation) |
| Square/polar grid | Hexagonal grid (different interference) |
| Mechanism hidden above | Mechanism IS the art (visible gears) |

### The "Vashisht Matrix" Identity

Regardless of which summation mechanism wins the prototype race, these constants define your voice:

1. **Mechanism-as-ornament**: The gears, screws, or linkages are never hidden. They ARE the sculpture's visual texture. Margolin hides his pulleys overhead; you make them the centerpiece.

2. **Software wave control**: 20 steppers + ESP32 = infinite wave vocabulary. You can perform live "wave concerts" — transitioning from calm sine to chaotic noise to geometric scanner. Margolin's fixed cams play one song forever.

3. **Pixel rotation (if coaxial screw or rack-and-pinion)**: The secondary spin creates a shimmer/sparkle wave that propagates across the grid independently of the height wave. No string system can do this. Use dichroic film or faceted crystal shapes to amplify.

4. **Hexagonal grid topology**: Three-axis wave interference (0°, 120°, 240°) instead of two-axis (X, Y). Produces "tripod" and "star" interference nodes that look crystalline, not oceanic.

5. **Material palette**: Black anodized aluminum frame. Polished brass gears. Walnut wood pixels. Steel shafts. The palette says "precision instrument" not "beach house."

6. **Scale**: Start desktop (300×300mm), grow to room-scale. Margolin works ceiling-mounted and monumental from the start. Your path is modular — add more nodes to grow the grid.

### Emotional Target

From the Emotion→Mechanism Dictionary:
- Primary: **Wave/cascade** — phase-offset eccentrics, each element slightly behind the last
- Secondary: **Breathing** — asymmetric cam profile (slow rise, faster fall) in the software wave equation
- Accent: **Surprise** — occasional mode switch (calm→glitch→calm) like a living organism startling

**Speed**: 1-3 RPM motor speed → pixels move at ~10-30mm/sec → "slow, peaceful" range from Speed Psychology table.

**Rhythm**: Use golden angle (137.5°) phase offset between adjacent motors → never exactly repeats → organic feel despite digital control.

---

## Part 7: Existing Art in This Space

### Direct Comparators

| Artist/Work | Method | How Yours Differs |
|-------------|--------|-------------------|
| **Reuben Margolin** (Triple Helix, Square Wave, etc.) | String + pulley matrix, analog cam drive | You: gear/screw summation, digital control, mechanism visible |
| **ART+COM** (Kinetic Rain, Changi Airport) | 1,216 independent servo winches | You: 20 motors via matrix math (100× fewer motors, same result) |
| **BREAKFAST Studio** (MegaFaces, Brixels) | Independent motor per pixel, flip-disc | You: shared-shaft matrix drive, continuous motion (not binary flip) |
| **Julius Popp** (Bit.Fall) | Water droplet matrix | You: solid pixels, persistent position (not transient) |
| **Daniel Rozin** (Mechanical Mirrors) | Individual servo per tile | You: wave-only motion (not arbitrary image), shared-axis drive |
| **Zimoun** (sound sculptures) | DC motors + simple materials | You: precise wave equation, not random |

### What Hasn't Been Done
The specific combination of:
- **Matrix-driven summation** (2 axes × 10 = 20 motors for 100 pixels)
- **Using gear differentials** (not strings/pulleys) as the summation element
- **Software-switchable wave patterns** (not fixed cams)
- **Mechanism-as-aesthetic** (visible, beautiful gears as the art itself)

This gap exists because it's at the intersection of mechanical engineering knowledge (differentials) and kinetic art tradition (wave sculpture) — two fields that rarely cross.

---

## Part 8: Open Questions for Prototyping

1. **Worm gear efficiency**: Is 50% too pessimistic for 3D-printed PLA worm gears? Test with dynamometer.
2. **Coaxial screw friction**: Can Delrin-on-steel achieve <0.15 coefficient? Need actual test.
3. **Acoustic character**: Does the gear purr enhance or destroy the meditative quality?
4. **String vs. rigid**: Does the pixel need to hang (gravity aesthetic) or can it be rigidly coupled (deterministic position)?
5. **Grid topology**: Square vs. hex — need p5.js comparison of interference patterns at 10×10 scale.
6. **Visual weight**: Does a ceiling of 100 gear nodes look "oppressive" or "magnificent"?
7. **Maintenance access**: Can a failed node be swapped without disassembling the grid?

---

## References

### Primary Sources
- Margolin Knowledge Bank: `archives/docs/MARGOLIN_KNOWLEDGE_BANK.md`
- Triple Helix MVP: `triple_helix_mvp/TRIPLE_HELIX_MVP_MASTER_PROMPT.md`
- Helix Cam Audit: `triple_helix_mvp/HELIX_CAM_DESIGN_AUDIT_V2.md`
- Rope Routing: `triple_helix_mvp/ROPE_ROUTING_COMPLETE_ANALYSIS.md`
- Machine State: `triple_helix_mvp/MACHINE_STATE_DIAGRAM.md`

### Engineering References
- Rule 99 Consultant Spec: `archives/docs/RULE99_CONSULTANT_SPEC.md`
- Rule 99 Library Roster: `archives/docs/RULE99_LIBRARY_ROSTER.md`
- Kinetic Sculpture Compendium: `archives/docs/KINETIC_SCULPTURE_COMPENDIUM.md`
- Design Thinking Framework: `learning/14_DESIGN_THINKING_FRAMEWORK.md`
- Design Knowledge Skills: `User Skills/design-knowledge-skills.md`

### Key Libraries for Analysis
- `gearpy` — Gear train torque flow simulation
- `dimstack` — Tolerance stackup Monte Carlo
- `tribology` — Friction coefficient estimation
- `py-fatigue` — S-N curve lifetime prediction
- `reliability` — Bearing L10 calculation
- `cq_gears` — Gear tooth profile generation (spur, helical, herringbone)
- `Ruckig` — S-curve stepper motion profiles

### Brainstorm Session
- Gemini conversation: Feb 18, 2026
- Mechanisms explored: differential pulley, planetary gear, bevel gear, coaxial screw, whiffletree, rack & pinion, CoreXY belt, compliant bow, scissor lift, hydraulic syringe, cam-on-cam, tensegrity, magnetic repulsion
- p5.js visualizations created for: differential pulley, planetary gear internals, 10×10 wave grid, coaxial screw elevator, morphing wave modes
- OpenSCAD models created for: planetary node assembly, tripod rail elevator
