# The Physical Transformer — Design Specification v2

**Date**: 2026-03-17
**Version**: 2.0 (complete rewrite incorporating all design reviews, feasibility analysis, and zero-CNC prototype strategy)
**Status**: Design Complete — Awaiting Implementation Planning
**Project**: Kinetic Sculpture Trilogy, Part III
**Trilogy**: Triple Helix (I) → Murmuration Engine (II) → Physical Transformer (III)

---

## 1. Vision

A kinetic sculpture that physically computes a neural network. Not a simulation — an actual analog computer that trains itself on language patterns, converges to learned weights, and produces predictions a human can interact with.

**Three pillars:**
1. **Computer-first** — The machine must actually converge during training
2. **Mesmerizing motion** — Computation itself is the art (Margolin aesthetic)
3. **Educational** — Demystifies AI: "It's not magic, it's mathematical probability"

**Core experience:** A viewer watches the machine train itself (pin drum feeds examples, weights adjust, loss decreases). Then they turn three brass word prisms, pull a lever, and the machine predicts.

---

## 2. Neural Network Architecture

### 2.1 Topology: 3x3x3 → 3 Proof of Concept

- **Input**: 3 words per prism × 3 prisms = 9 one-hot binary inputs
- **Hidden layer**: 3 neurons (each receives 9 weighted inputs + 1 bias)
- **Output layer**: 3 neurons (each receives 3 weighted inputs + 1 bias)
- **Total weights**: 42 (9×3 + 3 bias + 3×3 + 3 bias)
- **Activation function**: ReLU (hidden layer), linear (output layer during training), winner-take-all (output layer during prediction only)

### 2.2 One-Hot Encoding

Each input prism has 3 positions (e.g., "Cat", "Eats", "Fish"). Position 1 = [1,0,0], Position 2 = [0,1,0], Position 3 = [0,0,1]. This eliminates the need for mechanical multiplication in the forward pass — each weight is either used or not.

### 2.3 Training Data

Pin drum encodes 8 training examples:
- "Cat Eats Fish" → Cat
- "Dog Eats Bone" → Dog
- "Cat Chases Mouse" → Cat
- "Dog Chases Cat" → Dog
- "Fish Eats Worm" → Fish
- "Cat Eats Mouse" → Cat
- "Dog Eats Fish" → Dog
- "Fish Eats Fish" → Fish

**Key insight**: Answers before questions. The brass plaque reads: "HERE IS THE TRAINING DATA."

### 2.4 Training Parameters

- **Learning rate**: Fixed, encoded as swappable pinion gear ratio (4 pinion sizes available: aggressive, medium, default, fine-tuning)
- **Training method**: Exact backpropagation via adjoint variable method (Nature Communications 2024)
- **Epochs**: ~15 (adjoint method converges at standard backprop speed)
- **Examples per epoch**: 8
- **Tick period**: ~1.0 second (pendulum period at 250mm length: T = 2π√(0.25/9.81) = 1.003s)
- **Ticks per example**: 13 in TRAIN mode (8 forward + 5 adjoint), 10 in PREDICT mode
- **Time per example**: ~13 seconds (TRAIN mode)
- **Time per epoch**: ~104 seconds (~1.7 minutes)
- **Total training time**: ~26 minutes (15 epochs)

---

## 3. The Six Faces & Viewer Experience

The machine is a 900 × 600 × 450mm box on a museum pedestal (~900mm high). Each face has a distinct purpose, designed around how a human approaches, observes, and interacts.

### 3.0 The Viewer Journey

**Stage 1 — APPROACH (3m)**: A black-and-gold box on a dark pedestal. Stainless steel strings catch light inside. Something is moving. Sound: tick...tock...tick...tock...

**Stage 2 — FRONT FACE (1m, eye level)**: The primary display. Top-to-bottom triptych: 42 worm gears (memory) → 42 spiral cams (learning) → 3 error sliders (convergence). Brass plaques label each zone.

**Stage 3 — LEFT FACE (interaction station)**: Three brass word prisms at hand height. A red mode lever. An answer prism at eye level. Brass instruction plaque. The viewer touches the machine here.

**Stage 4 — RIGHT FACE (walk around)**: Pantograph diamonds breathing, shaped cams tracing functions, spring toggles snapping. The computation engine, visible through acrylic.

**Stage 5 — BACK FACE (backstage)**: Motor, barrel cam, pendulum. The engine room — partially hidden, heard more than seen. Raw mechanism, like seeing backstage at a theater.

**Stage 6 — THE STOP**: After ~26 minutes of training, the ticking stops. Silence. The convergence detector has tripped. The machine decided it has learned enough. A brass plaque reads: "WHEN I KNOW ENOUGH, I STOP."

**Stage 7 — PREDICTION**: The viewer pulls the mode lever (CLUNK). Turns the three word prisms. Watches the forward pass ripple through the strings. The answer prism rotates: chunk-chunk-chunk. A word appears.

**Pedestal height**: Box bottom at 900mm. Input prisms at ~1000-1100mm (hand height). Weight matrix at ~1100-1300mm (eye level). Pin drum at ~1460mm (slightly above — the "teacher" looks down). Answer prism at ~1350mm (easy to read).

**Lighting**: LED strips behind frame edges (the only electronics besides the motor). Side-lit stainless wire glows against the dark frame. Clear acrylic panels become windows into the mechanism.

### 3.1 FRONT — Weight Matrix (42 Worm Gears)

**What you see**: 42 brass/steel worm gear sets arranged in 6 rows behind clear acrylic. Top 3 rows: hidden neurons (10 gears each = 9 weights + 1 bias). Bottom 3 rows: output neurons (4 gears each = 3 weights + 1 bias). Color-coded indicator discs: blue (input→hidden), purple (hidden→output), gold (biases).

**Mechanism**: Self-locking worm gears (module 1.0, off-shelf Harfington/uxcell brass-on-steel sets, $4-6 each). The friction angle (19.3°) exceeds the lead angle (5.7°) by 3.4×, so weights persist without power. Backdriven only during training (worm drives the wheel). A friction-clutch common shaft enables simultaneous reset: clutch engages all worms to a common drive shaft, which spins them to a neutral (zero) position. Disengaging the clutch returns each worm to independent, self-locked state. The cascade of clicks during reset is one of the machine's signature sounds.

**Why worm gears**: Self-locking = persistent memory. No springs, no latches, no power needed. The weight IS the gear position.

**CAUTION**: Do NOT lubricate worm gears with low-friction lubricant (PTFE spray, silicone). Use medium-viscosity oil or keep dry to maintain self-locking friction angle above lead angle.

### 3.2 TOP — Pin Drum (Training Data)

**What you see**: A brass cylinder (~360mm long) mounted on bearings above the machine, studded with removable pin strips. Each strip = one training example. Pins protrude to encode one-hot bit patterns.

**Mechanism**: Barrel Cam 2b indexing. Each training step: (1) pin readers sense current example, (2) drum indexes one strip forward via star-wheel ratchet, (3) spring-loaded push-down/rotate/spring-up sequence.

**Margolin touch**: Pin strips are removable — you can reprogram the machine by swapping strips. Different training sets, different learned behavior.

### 3.3 RIGHT — Computation Engine (Pantograph Diamonds + Shaped Cams)

**What you see**: Cascading rhombus diamonds that expand and contract like breathing lungs. Resin cam profiles that trace mathematical functions. Springs that SNAP when neurons fire.

**Decided mechanism — Pantograph cascade**: Rhombus linkages where OA + OB = OC (pantograph adding mechanism). Three chains of 3 diamonds each (one chain per hidden neuron). Each hidden neuron has 9 weights + 1 bias = 10 connections, but one-hot encoding guarantees only 3 inputs are active at any time (one per prism) + 1 bias = 4 active terms. Three diamonds per chain sum exactly 4 terms: diamond 1 sums terms 1+2, diamond 2 adds term 3, diamond 3 adds bias. Inactive inputs produce zero displacement via the one-hot string clamp mechanism (see Section 3.4).

**Why pantograph over Archimedes lever**: Levers accumulate friction at pivot points. Pantographs distribute force across the rhombus — each diamond adds one term cleanly. The expanding/contracting motion is also far more visually dramatic than a tilting beam.

**Pantograph joints — HK0306 needle bearings**: All pantograph pivot joints use HK0306 needle bearings (3mm bore, 6.5mm OD, 6mm length). This is critical for adjoint signal fidelity. With ~48 pivot joints across all pantograph chains, bearing friction determines adjoint accuracy:
- HK0306 needle bearings (μ ≈ 0.003): 0.997^48 = 86.6% signal transmission (~13% loss)
- PTFE bushings (μ ≈ 0.05): 0.95^48 = 8.5% signal transmission (91.5% loss — CATASTROPHIC)

Needle bearings are mandatory. Budget ~13% signal attenuation into convergence calculations.

**String compliance mitigation**: All strings are pre-tensioned with spring tensioners at their anchor points. Pre-tension eliminates dead zone — the pantograph input moves immediately when a weight string is released. String material: 0.5mm stainless steel fishing leader wire (7-strand, near-zero creep, high stiffness). Maximum 2 pulley redirections per string line to minimize friction losses.

**Shaped cam activation functions (SLA resin)**: Each hidden neuron has a cam (50mm diameter, SLA resin printed at 50μm resolution) whose profile IS the activation function. ReLU = flat region + linear ramp. A spring-loaded follower rides the cam, converting summed displacement into activated output. Output neurons have NO shaped cam (linear activation during training, winner-take-all during prediction only).

**Cams do double duty in adjoint pass**: During the backward pass, the shaped cam automatically computes the ReLU derivative. When the cam is in the active region (positive input, follower on the ramp), adjoint force transmits back through the cam at ratio 1:1 (derivative = 1). When the cam is in the dead region (negative input, follower on the flat), adjoint force pushes into the flat — no torque transmitted (derivative = 0). The cam's geometry IS the chain rule.

**Spring toggle neuron firing**: Bistable toggle mechanism produces an audible SNAP when a neuron's activation crosses threshold. Binary, decisive, satisfying.

**42 Archimedean spiral cam gradient computers**: Mounted on the front face middle triptych zone (visible from front). SLA resin printed at 40mm diameter, 50μm resolution. One per weight. Each spiral cam stores the forward-pass string displacement as an angular position (via ratchet). During the adjoint pass, the backward-traveling string wraps onto the cam at the stored radius. The resulting torque = forward displacement × adjoint displacement = exact gradient.

**Spiral cam specifications**:
- Diameter: 40mm (SLA resin)
- Archimedean spiral profile: r_min=1.0mm, r_max=6mm (ratio 6:1)
- Active arc: 254 degrees
- Ratchet: 36-tooth (10-degree steps, 25 discrete positions)
- Resolution: 0.2mm radial step per ratchet position
- SLA surface finish: 50μm layer height provides 8× margin over ratchet quantization

**Front face triptych (top to bottom)**: The front face is the primary display, read top-to-bottom like a story:
- **Top third**: Worm gear weight matrix (THE MEMORY — 42 gears settle into final positions)
- **Middle third**: Spiral cam gradient array (THE LEARNING — 42 discs oscillate during adjoint pass, shrink as gradients decrease)
- **Bottom third**: 3 sliding collar differentials on MGN7 rails (THE ERROR — sliders converge toward "ZERO ERROR" as training progresses)

Viewers watch: memory stabilizing, learning diminishing, error vanishing. The machine tells its own story.

### 3.4 LEFT — I/O Panel (Human Interaction)

**What you see**: Three brass word prisms (rotating polygon drums) at comfortable hand height. A prominent red lever for TRAIN/PREDICT mode. A matching answer prism above that rotates to show the prediction.

**Input word prisms**: Each input is a triangular prism (3 rectangular faces for 3 words) mounted on a horizontal axis. The user rotates the prism by hand — it clicks into detent positions (spring-loaded ball detent, one per face). The selected word faces the viewer directly in large engraved text. No pointer, no decoding — you just read the face pointing at you. The prism shaft connects via string to the one-hot selector mechanism inside. Each of the 3 detent positions engages exactly one of three string clamps.

**Scalability**: For a larger vocabulary, replace triangular prisms with pentagonal (5 words), hexagonal (6), or heptagonal (7). The one-hot encoding expands accordingly — more faces = more input bits = more weights. The POC uses triangular (3 words).

**One-hot gating mechanism**: Each prism detent position engages exactly one of three string clamps. Active position: clamp releases string, allowing it to transmit weight displacement to the pantograph. Inactive positions: clamp locks string to a fixed anchor, producing exactly zero displacement regardless of worm gear position. Spring-loaded cam followers on the prism shaft actuate the clamps — rotating the prism physically disconnects 2 strings and connects 1. This ensures inactive inputs contribute precisely zero to the pantograph sum (not "less" — zero).

**Mode switch — Dog clutch with dual output routing**: Large lever with spring-loaded toggle. CLUNK sound on engagement. The dog clutch is a sliding collar on a horizontal shaft behind the output rods. It has two sets of engagement teeth:
- **TRAIN position**: Lateral coupling links connect 3 output rods to 3 independent whippletree error beams. Geneva drive disengaged — prism sits still. Motor runs, pin drum feeds, adjoint pass computes gradients, weights update.
- **PREDICT position**: Whippletree links retract (return springs). Tilting comparison beam engages — finds highest output rod, drives Geneva drive. Motor stops, prisms connect to forward pass only.

**Three output rods**: Each output-layer pantograph terminates at a brass rod that always produces continuous displacement — in both modes. The rods are the raw analog outputs. What changes between modes is which downstream mechanism reads them.

**Winner-take-all comparator (PREDICT only)**: A tilting brass comparison beam (120mm) rests on whichever of the 3 output rods is highest. The beam's tilt drives a follower arm into the Geneva drive input disc, indexing the answer prism to the winning face.

**Answer word prism — 3-slot Geneva drive**: A triangular prism matching the input prisms in form factor — same brass material, same size, same horizontal axis mount. 3 rectangular faces, each engraved with one output word. Geneva drive produces 120-degree indexing — discrete, positive stops (chunk-chunk-chunk). Engages only in PREDICT mode. Mounted above the mode lever at eye level, so the viewer looks straight at the answer. The visual symmetry between input prisms (below, hand height) and answer prism (above, eye level) reinforces the input→output narrative: "I chose these words, the machine predicted this one."

### 3.5 BACK — Motor & Timing

**What you see**: Single NEMA 23 stepper motor (1.26 Nm holding torque, 0.5-0.7 Nm at operating speed) driving a barrel cam sequencer. Gravity pendulum providing the heartbeat. All timing derived from one motor.

**Barrel Cam sequencer (FDM PLA, single piece, 270mm length)**: Spiral groove on a cylinder. A follower pin rides the groove, converting rotation into a timed sequence of operations. One full revolution = one training example (forward pass + backward pass + weight update). Printed in a single piece on the K2 Plus (270mm fits within 350mm build volume).

**Gravity pendulum escapement**: Replaces clock escapement. 250mm pendulum with 30mm bob, clock components sourced from Timesavers.com. Weighted arm swings with audible tick-tock (period: 1.003s), gating the computation into discrete steps. Each swing = one neural operation advancing.

**Shishi-odoshi (dry cam-triggered variant)**: At end of each training example, a cam-triggered brass striker produces a resonant TOCK — marking completion. Dry mechanism (no water): cam lifts striker arm against spring, releases at top of cam lobe, striker falls under gravity + spring force onto brass anvil plate.

**Convergence auto-stop (mechanical logic)**: The machine knows when it has learned enough and stops itself. Three mechanical AND gate inputs come from the sliding collar differentials: when all 3 error sliders are within a threshold of center, spring-loaded pins (one per slider) drop into threshold notches. When all 3 pins are engaged simultaneously, a mechanical AND condition is met — a common bar drops under spring force, which disengages the motor clutch. Training stops. The pendulum swings to a halt. Silence.

**Implementation**: Each sliding collar has a V-notch at center position (60° angle for good centering force). A spring-loaded pin (~1.5mm diameter) rides above the slider. When the slider is within the notch width (~2mm = convergence threshold = 2.5% of 80mm rail), the pin drops into the notch. Three pins connect to a common trigger bar via short levers. The trigger bar is held up by any pin that hasn't dropped. When all 3 drop: trigger bar falls → trips a lever → disengages the motor drive clutch (same clutch used by the mode switch).

**Time-delay (soft-close rotary damper)**: To prevent false positives from transient oscillations (all 3 errors crossing zero simultaneously during early training), the trigger bar connects to a soft-close rotary damper (no fluid, no temperature sensitivity). The bar must remain in the "all pins dropped" state for ~3 seconds before the clutch actually disengages. This ensures only sustained convergence triggers the stop, not a lucky transient.

**Auto-switch to PREDICT**: The convergence auto-stop shares the motor clutch with the mode switch dog clutch. When the convergence detector trips, it also shifts the output coupling from whippletree to comparator beam — effectively switching the machine to PREDICT mode automatically. The machine learns, decides it has learned enough, stops, and invites the viewer to interact.

**The theater**: Viewers watch error bars converge over ~26 minutes. Then suddenly — the ticking stops. The machine decided it has learned. The brass plaque next to the convergence detector reads: "WHEN I KNOW ENOUGH, I STOP."

The convergence threshold is adjustable — the V-notch width on each slider can be changed by replacing the notch insert (wider = easier to converge, narrower = more precise).

### 3.6 BOTTOM — Loss Computation & Gradient Descent

**What you see**: Cascading balance beams (whippletree) computing error. A brass cycloid track where a steel ball rolls — the brachistochrone curve visualizing gradient descent.

**Three independent whippletree beams**: One per output neuron (not one aggregate). Each beam compares that neuron's predicted displacement against its target displacement from the pin drum. In TRAIN mode, these beams tilt proportionally to per-neuron error and feed into the sliding collar differentials (see Section 5.2). In aggregate, a cascading fourth beam sums the three errors for the brachistochrone loss visualization. Zero-friction pivots on knife edges.

**Three sliding collar differentials**: Mounted on MGN7 miniature linear rails (polished steel), visible from the front. Each slider displaces left/right as errors occur. As training progresses, sliders visibly converge toward center ("ZERO ERROR" engraved at detent). Blued steel leaf springs convert displacement to adjoint force. The audience watches the machine learn in real time — error shrinking to nothing.

**Brachistochrone ball track**: Cycloid curve (Bernoulli, 1696). After aggregate loss is computed, a ball is released and rolls down the fastest-descent curve. Ball rolls to a spring-loaded catch gate positioned by the scissor amplifier (5× loss magnitude). Ball stops at gate — viewer reads loss as ball position. Return mechanism: lever tips track, ball rolls back via gravity return channel on the underside. As training progresses, the ball rolls less far — loss is decreasing.

**Scissor Mechanism 2 (5× amplifier)**: Mixed-size rhombi amplify small loss changes into visible displacement. Loss might change by 2mm, but the scissor amplifies to 10mm of visible motion.

---

## 4. Locked Design Decisions

### 4.1 Summation: Pantograph Diamond Cascade

**Decision**: Pantograph rhombus linkages with HK0306 needle bearings for all weighted summation.
**Over**: Archimedes lever (friction accumulation), cam-string Kelvin (less visible).
**Rationale**: Most visible, most poetic, best motion quality. Diamonds expand like breathing. Needle bearings maintain 86.6% signal transmission through 48 joints.

### 4.2 Signal Routing: Strings (Margolin Aesthetic)

**Decision**: 0.5mm stainless steel fishing leader wire (7-strand) threaded over small pulleys for all signal transmission.
**Over**: Rigid brass rods (industrial look), hybrid (inconsistent aesthetic), braided brass wire (more creep).
**Rationale**: Margolin aesthetic — strings create a harp-like visual. Pulleys redirect cleanly. 42 string lines (one per weight). Stainless steel leader wire provides near-zero creep and high stiffness. Strings routed on two distinct depth planes (input strings and output strings separated by 20-30mm) to prevent collision.

### 4.3 Overall Aesthetic: "Maker Machine"

**Decision**: Black PLA + 2020 aluminum extrusion + strategic brass accents. Rub 'n Buff gold leaf for accent parts.
**Over**: Full brass (cost prohibitive for prototype), full PLA (insufficient rigidity at 900mm).
**Rationale**: The prototype should look intentional, not cheap. Black anodized aluminum frame provides structural rigidity. Brass word prisms, brass plaques, brass worm gears provide the gold accent. Rub 'n Buff on select PLA parts bridges the gap.

### 4.4 Training: Exact Adjoint Backpropagation

**Decision**: Adjoint variable method — two physical equilibrium states (forward + adjoint) through the same network yield exact gradients.
**Over**: Perturbation-based learning (robust but 3× slower), contrastive Hebbian (approximate gradients), digital twin (hybrid, defeats the purpose).
**Rationale**: Nature 2024 proved it works mechanically. Halves training time. Same 42 strings carry both forward and adjoint signals (Maxwell's reciprocity). Shaped cams compute ReLU derivative for free (flat = 0, ramp = 1). The two-phase breathing cycle (forward wave left-to-right, adjoint wave right-to-left) is more visually dramatic than one-directional flow.

### 4.5 I/O Form Factor: Rotating Word Prisms (Not Dials)

**Decision**: Triangular brass prisms (3 rectangular faces, horizontal axis) for both input selection and answer display.
**Over**: Watch-style dials with pointers, LCD displays, printed labels.
**Rationale**: The selected word IS the face — large, legible, unambiguous. No pointer to decode, no tiny labels to squint at. Input and answer share the same physical vocabulary (both are prisms), reinforcing the input→output narrative. Scales to 5-7 faces for larger vocabulary. Detent clicks provide tactile feedback.

### 4.6 Motor: NEMA 23 Stepper

**Decision**: Single NEMA 23 stepper (1.26 Nm holding torque, 0.5-0.7 Nm at operating speed) drives everything through mechanical sequencing.
**Over**: NEMA 17 (0.25-0.31 Nm — zero torque margin with 6 simultaneous worm gear updates + auxiliary loads).
**Rationale**: With 6 simultaneous weight updates (0.02 Nm each) + barrel cam (0.05 Nm) + pendulum escapement (0.02 Nm) + pin drum indexing (0.05 Nm) = ~0.24 Nm total load. NEMA 23 provides 3-4× margin at operating speed. Single motor rule preserved — all complexity emerges from one source of energy.

### 4.7 Frame: 2020 Aluminum Extrusion

**Decision**: 2020 aluminum extrusion (black anodized) for all structural frame members.
**Over**: PLA frame (insufficient rigidity at 900mm span), 8020 (oversized for this scale).
**Rationale**: At 900mm width, PLA deflects under the weight of 42 worm gears + 42 spiral cams + all mechanisms. 2020 extrusion provides ~10× the rigidity of equivalent PLA sections. Black anodized finish matches the aesthetic. T-slot mounting simplifies assembly and adjustment.

### 4.8 Sliders: MGN7 Miniature Linear Rails

**Decision**: MGN7 linear rails for all sliding collar differentials and any linear motion.
**Over**: Bronze bushings on brass rod (spec v1 approach), drawer slides (too much play).
**Rationale**: Repeatable, near-zero-friction linear motion. Off-shelf, $3-5 each. Critical for convergence detector accuracy — the V-notch + pin mechanism requires consistent, low-friction slider motion.

### 4.9 Gradient Computers: Archimedean Spiral Cams (SLA Resin)

**Decision**: 40mm diameter SLA resin spiral cams with 36-tooth ratchet.
**Over**: Standard taper pins (FAILED — only 1.25:1 radius ratio, need minimum 4:1), brass CNC cams (no CNC available for prototype).
**Rationale**: SLA resin at 50μm resolution provides 8× margin over ratchet quantization. 40mm diameter with r_min=1.0mm, r_max=6mm gives 6:1 ratio (sufficient for gradient computation). 36-tooth ratchet provides 25 discrete angular positions (up from 17 with 24-tooth), significantly improving gradient resolution.

### 4.10 Materials Palette

| Material | Role | Color |
|----------|------|-------|
| Black PLA (FDM) | Structure (mounts, brackets, cam bodies) | Matte black |
| 2020 aluminum extrusion | Frame (black anodized) | Black |
| Brass | Interaction + accents (prisms, plaques, worm gears) | Gold |
| SLA resin | Precision parts (spiral cams, ReLU cams) | Gray/clear |
| Stainless steel | Strings, shafts, springs | Silver |
| Clear acrylic (3mm) | Transparency (side panels) | Transparent |
| Rub 'n Buff gold leaf | Accent treatment on select PLA parts | Gold highlight |
| Red accent | Answers + interaction (lever knob) | Deep red |

### 4.11 Sound Palette (Designed Acoustic Events)

| Event | Sound | Mechanism |
|-------|-------|-----------|
| Heartbeat (each operation) | tick...tock | Gravity pendulum escapement |
| Neuron fires | SNAP | Bistable spring toggle |
| Weight adjusts | click-click-click | Worm gear ratcheting |
| Training example complete | TOCK | Shishi-odoshi dry cam striker |
| Mode switch | CLUNK | Dog clutch engagement |
| Epoch complete | cascade of clicks | Friction-clutch mass reset |
| Ball release (gradient) | silence → rolling | Brachistochrone track |
| Answer revealed | chunk-chunk-chunk | Geneva drive indexing |
| Prism selection | click | Detent mechanism |
| Convergence auto-stop | tick...tock...(silence) | Mechanical AND gate trips motor clutch |
| Full convergence | sustained silence, stillness | All motion ceases — the machine has learned |

---

## 5. Signal Flow

### 5.1 Forward Pass (10 ticks PREDICT / 8 ticks TRAIN)

1. **Tick 1**: Pin drum (or prism) sets 9 input bits via string clamps (one-hot gates)
2. **Tick 2**: Active weight strings engage — 3 active + 1 bias per hidden neuron
3. **Tick 3**: Hidden-layer pantograph diamonds begin expanding (weighted sum accumulates)
4. **Tick 4**: Pantograph cascade settles — sum complete for all 3 hidden neurons
5. **Tick 5**: Shaped cam followers ride cam profiles — ReLU activation applied
6. **Tick 6**: Activated hidden outputs route via strings to output-layer pantographs
7. **Tick 7**: Output-layer pantograph diamonds expand (3 weights + 1 bias each)
8. **Tick 8**: Output pantograph cascade settles — 3 output sums ready
9. **Tick 9 (PREDICT only)**: Winner-take-all: highest displacement output neuron drives Geneva drive
10. **Tick 10 (PREDICT only)**: Answer prism rotates to show prediction — chunk-chunk-chunk

In TRAIN mode, ticks 9-10 are skipped (Geneva drive disengaged, answer prism sits still). Forward pass completes at tick 8, adjoint begins at tick 9.

### 5.2 Backward Pass — Exact Adjoint Backpropagation (5 ticks, TRAIN mode only)

**Training method: Adjoint variable method.** Based on the 2024 Nature Communications proof that exact gradients can be obtained from mechanical networks using only two equilibrium states (forward + adjoint). The same physical network propagates signals in both directions — no separate backward network needed. Maxwell's reciprocity theorem (1864) guarantees that driving a linear mechanism backward computes exactly the transpose of the forward operator.

**Phase switching — 2 clamp bars**: The 42 strings carry signals bidirectionally via a two-phase cycle. Two brass clamp bars (one at the input boundary, one at the output boundary) switch which string endpoints are driven vs. free. The adjoint method requires clamping only at the network's input and output — intermediate layers propagate freely via mechanical reciprocity.
- **Forward phase**: Input clamps ENGAGED (motor drives inputs), output clamps FREE (outputs respond)
- **Dead zone**: All clamps FREE (everything settles to equilibrium)
- **Adjoint phase**: Output clamps ENGAGED (error mechanism drives outputs), input clamps FREE (inputs respond to backward signal)

Each clamp bar is a brass strip with a fixed jaw and a cam-actuated moving jaw. Spring-loaded return (fail-open design). One cam lobe per clamp bar on the main drive shaft.

**Error force generation — 3 sliding collar differentials**: One per output neuron. A brass slider rides an MGN7 linear rail, pulled from opposite sides by the predicted output string and the target string (from pin drum). Slider displacement = (predicted - target) = error. A calibrated leaf spring (0.3mm spring steel) converts displacement to force: F = -k × error. A yoke on the slider routes bidirectional force via opposing string pairs back into the output node.

**Leaf springs**: Fixed at build time (k value calibrated during Phase 6). The leaf spring converts error displacement to force — its k value affects the adjoint force magnitude. The user-adjustable learning rate is the swappable pinion in the rack-and-pinion weight updater (Section 6.4), NOT the leaf spring. Display a rack of 4 pinion sizes on the pedestal for the viewer to see.

9. **Tick 9 (TRAIN: ADJOINT START)**: Clamp bars switch — output clamps engage, input clamps release. 42 spiral cam ratchets lock (storing forward-pass displacements). Three sliding collar differentials compute error forces. Pin drum remains locked at current example.
10. **Tick 10**: Error forces propagate backward through output-layer pantographs (mechanically reversible — push output, inputs move proportionally). Through shaped cams: active neurons (follower on ramp) pass signal at 1:1, dead neurons (follower on flat) block signal — the ReLU derivative, computed by geometry. Budget ~13% signal attenuation through 48 needle-bearing pantograph joints.
11. **Tick 11**: Adjoint signal reaches all 42 weight positions. At each weight, the adjoint string wraps onto the Archimedean spiral cam at the stored forward-displacement radius. Torque = forward × adjoint = exact gradient.
12. **Tick 12**: Gradient torque drives output rack → rack-and-pinion drives worm shaft → weight updates. 42 clicks as all weights adjust simultaneously. Barrel cam sequences through 7 groups of 6 for staged engagement (torque management). Brachistochrone ball released — loss visualization.
13. **Tick 13**: Global reset bar lifts all 42 ratchet pawls (spiral cams return to zero). Clamp bars return to forward configuration. Pin drum indexes to next example (star-wheel ratchet). Shishi-odoshi striker fires — TOCK.

**Rack-and-pinion weight update**: Each gradient output rack meshes with a pinion on an intermediate shaft, through a 4:1 reduction gear pair, to the worm shaft. Self-locking preserved (worm drives from the worm side during updates, self-locks from the wheel side at all other times). Swappable pinion = learning rate: Z=8 (aggressive), Z=12 (medium), Z=16 (default), Z=24 (fine-tuning).

### 5.3 Timing Budget

- 1 tick = ~1.0 second (pendulum full period at 250mm length: T = 2π√(0.25/9.81) = 1.003s)
- 1 training example = 13 ticks (8 forward + 5 adjoint) = ~13 seconds
- 1 prediction = 10 ticks = ~10 seconds
- 1 epoch (8 examples) = ~104 seconds (~1.7 minutes)
- 15 epochs to convergence = ~26 minutes
- Total pins/drums: 8 strips × 12 pins each (9 input bits + 3 target bits)

### 5.4 Why Adjoint Over Perturbation

Perturbation-based learning (the conservative option) wiggles each weight independently and measures loss change — correct but slow (evaluates 42 weights sequentially per example). The adjoint method computes all 42 gradients in a single backward pass, cutting training time from ~48 minutes to ~26 minutes. The 2024 Nature paper proved mechanical adjoint gradients achieve >90% accuracy vs. theoretical exact values. Our 15-20% gradient error from mechanical tolerances (ratchet quantization, string friction, spiral cam bias, bearing losses) is within SGD's proven 30% noise tolerance.

---

## 6. Adjoint Backpropagation — Mechanism Detail

This section specifies the four mechanism systems that enable exact backpropagation. All are additions to the forward-pass mechanisms described in Section 3.

### 6.1 Clamp Bars (Bidirectional String Phase Switching)

2 assemblies — one at the input boundary (clamps all 27 input-to-hidden strings + 3 hidden biases), one at the output boundary (clamps all 9 hidden-to-output strings + 3 output biases). Each clamp bar is a brass strip running perpendicular to the strings:
- **Fixed jaw**: bolted to 2020 extrusion frame
- **Moving jaw**: actuated by cam follower on main drive shaft
- **Jaw gap**: 2mm open (string moves freely), 0mm closed (brass-on-brass pinch locks string)
- **Actuation**: One cam lobe per clamp bar. Forward phase closes input clamps, adjoint phase closes output clamps. 15-degree dead zone between phases.
- **Spring return**: Compression spring opens jaw when cam releases (fail-open — if anything breaks, strings go free)

The two-phase cycle creates a visible breathing rhythm: strings tighten left-to-right (forward), pause, then tighten right-to-left (adjoint). The two clamp bars look like frets on a stringed instrument — one at each end of the string field.

### 6.2 Sliding Collar Differentials (Error Force Generation)

3 units, one per output neuron. Mounted on MGN7 linear rails, visible from the front.
- **Rail**: MGN7 miniature linear rail, 100mm length
- **Slider**: MGN7 carriage with brass cover plate (10×8mm visible face)
- **Predicted string**: from output pantograph rod, pulls slider one direction
- **Target string**: from pin drum target pins, pulls slider opposite direction
- **Slider displacement** = (predicted - target) = error signal
- **Leaf spring**: 0.3mm × 5mm × 60mm spring steel (blued), anchored at rail center. Converts displacement to force F = -k × error
- **Yoke**: brass sheet on slider, routes bidirectional force via opposing string pairs (String+ and String-) to output node
- **Center detent**: engraved "ZERO ERROR" — as training progresses, sliders converge toward center

### 6.3 Archimedean Spiral Cam Gradient Computers

42 units, one per weight. The core multiplication mechanism.
- **Spiral cam**: 40mm diameter SLA resin disc, Archimedean spiral profile (r_min=1.0mm, r_max=6.0mm, 254 degrees active)
- **Forward capture**: Weight string drives a 0.3-module rack → 12T pinion → rotates spiral cam shaft. 36-tooth ratchet wheel locks angular position = stored forward displacement.
- **Adjoint capture**: Backward-traveling string wraps onto spiral cam edge at the stored radius. Torque = tension × radius = forward × adjoint = gradient.
- **Output**: 8T pinion on same shaft drives output rack (5mm travel). Rack displacement = gradient magnitude and direction.
- **Dimensions per unit**: 50mm × 35mm × 15mm on PLA frame plate (larger than v1 due to 40mm cam diameter)
- **Array layout**: 7×6 grid at 55mm × 40mm pitch = 385mm × 240mm total (front face, middle triptych zone). Centered in 900mm width with 257mm margin per side.
- **Error budget**: ratchet quantization (10° = 25 positions, ~4% resolution) + cone bias (r_min offset ~8%) + bearing friction (~5%) + SLA surface roughness (~2%) = total ~15-20% gradient error (within SGD's 30% noise tolerance)

### 6.4 Rack-and-Pinion Weight Updaters

42 units, integrated with spiral cam output. Converts gradient displacement to worm gear rotation.
- **Gradient rack**: 0.5 module, driven by spiral cam output
- **Pinion**: swappable, press-fit brass gear on intermediate shaft. Z=8/12/16/24 = 4 learning rates
- **Reduction**: 48:12 (4:1) gear pair
- **Worm shaft gear**: Z=12, meshes with reduction output
- **Worm**: 1-start, module 1.0, steel. Self-locking (friction angle 19.3° >> lead angle 5.7°)
- **Total ratio**: 1mm rack displacement → 0.119° worm gear rotation (at Z=16 default)
- **Weight resolution**: ~3024 steps over 360°
- **Staged engagement**: Barrel cam sequences through 7 groups of 6 weights. NEMA 23 drives max 6 updates simultaneously (~0.12 Nm total load vs 0.5-0.7 Nm available = 4-6× margin).

---

## 7. Dimensions & Tolerances

### 7.1 Envelope

- **Width**: 900mm (front face — weight matrix + spiral cam array)
- **Height**: 600mm (frame) + 60mm (pin drum above) = 660mm total. Pendulum (250mm) hangs inside the frame from the back top rail — does not extend beyond envelope.
- **Depth**: 450mm
- **Weight estimate**: 8-12 kg (heavier than v1 due to aluminum frame and larger scale)
- **Pedestal/base**: Not included in envelope — separate museum-style mount

### 7.2 Key Component Dimensions

| Component | Count | Size (mm) | Material |
|-----------|-------|-----------|----------|
| Worm gear assembly | 42 | Module 1.0, ~24dia × 20 | Off-shelf brass/steel (Harfington/uxcell) |
| Spiral cam gradient computer | 42 | 40dia × 15, on 50×35 frame | SLA resin cam, steel shaft, PLA frame |
| Rack-and-pinion updater | 42 | 0.5 module, 8mm travel | Brass rack, steel pinion |
| Pantograph diamond | 9 (3×3) | 70 × 40 (expanded) | PLA bars, HK0306 needle bearing joints |
| Shaped cam (ReLU) | 3 | 50dia × 10 | SLA resin (hidden layer only) |
| Clamp bar assembly | 2 | 300 wide × 12 | Brass jaws, steel cam follower |
| Sliding collar differential | 3 | MGN7 rail 100mm + brass slider | MGN7 rail, brass cover plate, blued steel spring |
| Comparison beam (predict) | 1 | 120 × 8 × 4 | Brass |
| Input word prism (triangular) | 3 | 40 face width × 60 long, horizontal axis | Brass, engraved text |
| Answer word prism (triangular) | 1 | 40 face width × 60 long, horizontal axis | Brass, engraved text |
| Convergence detector (AND gate) | 1 | 3 spring pins + trigger bar + rotary damper, 100mm wide | Steel pins, brass bar |
| Pin drum | 1 | 70dia × 360 | Brass tube + removable pin strips |
| Gravity pendulum | 1 | 250 long, 30dia bob | Clock components (Timesavers.com) |
| Barrel cam (sequencer) | 1 | 40dia × 270 | FDM PLA, single piece |
| NEMA 23 stepper motor | 1 | 57 × 57 × 56 | Stock |
| Whippletree beams | 4 | 80-200 × 4 × 8 | Brass (3 per-neuron + 1 aggregate) |
| Dog clutch collar | 1 | 30 × 18dia | Steel |
| Spring toggles | 3 | ~20 × 10 | Steel spring (hidden layer) |
| String pulleys | 60-84 | 12dia | Brass or PLA (exact count from routing diagram) |
| Frame (2020 extrusion) | ~12 lengths | 20 × 20 × varies | Black anodized aluminum |
| Acrylic panels | 3-4 | varies × 3 thick | Clear |
| MGN7 linear rails | 3-6 | 100mm | Stainless steel |
| HK0306 needle bearings | ~48 | 3mm bore, 6.5mm OD | Steel |

### 7.3 Tolerances

- General: 0.2mm (FDM PLA)
- Precision parts (spiral cams, ReLU cams): 0.05mm (SLA resin)
- Sliding fits (cam followers, pantograph joints): 0.3mm
- Press fits (bearings, shafts): 0.1mm
- Minimum feature size: 1.5mm (FDM), 0.3mm (SLA)
- String: 0.5mm stainless steel 7-strand leader wire
- String-to-string minimum spacing: 3mm (collision avoidance)
- String routing: two depth planes separated by 20-30mm (input strings vs output strings)

---

## 8. Bill of Materials

### 8.1 Prototype BOM (~$490)

| Category | Items | Est. Cost |
|----------|-------|-----------|
| **Off-shelf metal** | 42× module 1.0 worm gear sets ($4-6 ea) | $170-250 |
| **Motor** | 1× NEMA 23 stepper + driver | $25-35 |
| **Bearings** | ~48× HK0306 needle bearings ($0.50 ea) + 3-6× MGN7 rail sets ($4 ea) | $40-50 |
| **Frame** | 2020 aluminum extrusion (black anodized, ~6m total) + corner brackets + T-nuts | $40-60 |
| **3D print filament** | PLA (K2 Plus, ~2-3 spools) + SLA resin (~500ml for spiral+ReLU cams) | $50-70 |
| **Strings** | 0.5mm stainless steel leader wire (~50m) + pulleys + tensioners | $20-30 |
| **Springs & hardware** | Compression springs, leaf springs, ball detents, screws, pins | $30-40 |
| **Clock components** | Pendulum parts (Timesavers.com) | $15-25 |
| **Acrylic panels** | 3mm clear, laser-cut or hand-cut | $15-20 |
| **Electronics** | LED strips + power supply (only non-mechanical components) | $15-20 |
| **TOTAL (prototype)** | | **~$420-600** |

### 8.2 Brass Accent Upgrade (~$400-500 additional)

| Item | Cost |
|------|------|
| 4× brass word prisms (custom engraving or Rub 'n Buff + PLA) | $40-80 |
| Brass plaques (laser-etched or CNC engraved) | $60-100 |
| Brass tube for pin drum | $30-50 |
| Rub 'n Buff gold leaf (for PLA accent parts) | $15-25 |
| Brass rod stock (for misc mechanisms) | $30-50 |
| **Subtotal brass upgrade** | **~$175-305** |
| **TOTAL with brass accents** | **~$595-905** |

### 8.3 Fabrication Notes

- **Printer**: Creality K2 Plus with CFS (350×350×350mm build volume, 600mm/s, multi-material)
- **Zero CNC**: All parts are 3D printed (FDM PLA + SLA resin) or off-shelf metal
- **SLA parts** (outsource or desktop SLA printer): 42× spiral cams (40mm dia), 3× ReLU cams (50mm dia)
- **Barrel cam**: FDM PLA, single piece (270mm fits K2 build volume)
- **Print time**: ~25-35 hours total on K2 Plus (was ~80hrs estimate on standard FDM)
- **Assembly time**: ~2-3 weeks
- **Critical off-shelf sources**: Amazon/AliExpress (worm gears, bearings, rails), Timesavers.com (clock components), McMaster-Carr (springs, pins, rod stock)

---

## 9. Mechanism Heritage

Every mechanism in this machine has historical provenance:

| Mechanism | Origin | Year |
|-----------|--------|------|
| Archimedean spiral | Archimedes | ~250 BCE |
| Rack and pinion | Ancient engineering | ~300 BCE |
| Worm gear | Ancient Greece | ~100 BCE |
| Pantograph | Christoph Scheiner | 1603 |
| Brachistochrone | Johann Bernoulli | 1696 |
| Geneva drive | Swiss watchmaking | ~1700s |
| Whippletree | Horse-drawn agriculture | ~1800s |
| Barrel cam | Industrial revolution | ~1850s |
| Dog clutch | Machine tooling | ~1880s |
| Spring toggle | Electrical switching | ~1900s |
| Shaped cam (function generator) | Mechanical computing | ~1930s |
| Shishi-odoshi | Japanese garden design | Traditional |
| Adjoint variable method | Pontryagin / Lions | 1950s-60s |

**Design philosophy**: Every mechanism in this machine was invented before the transistor (the adjoint method predates practical digital neural networks by decades). The machine proves that intelligence can emerge from brass, steel, and string — no electricity required in the computation path.

---

## 10. Risk Register (Post-Mitigation)

| Risk | Severity | Mitigation | Status |
|------|----------|------------|--------|
| Torque: single motor can't drive all mechanisms | LOW | NEMA 23 provides 3-4× margin. Staged engagement (7 groups of 6). Phase 1 torque rig validates. | Mitigated |
| Adjoint signal loss through pantograph joints | LOW | HK0306 needle bearings at all 48 joints = 13% loss (within 30% SGD tolerance). PTFE eliminated. | Mitigated |
| Gradient accuracy from spiral cams | MEDIUM | SLA resin at 40mm/50μm. 36-tooth ratchet (25 positions). 15-20% error within SGD tolerance. Phase 2 validation required. | Partially mitigated |
| String stretch/creep over 26 min training | LOW | Stainless steel 7-strand leader wire (near-zero creep). Pre-tensioned with spring tensioners. | Mitigated |
| Worm gear backlash accumulates error | LOW | Module 1.0 off-shelf sets. Self-locking by 3.4× margin. Validate Phase 3. | Mitigated |
| Convergence false positive (transient zero-crossing) | LOW | Soft-close rotary damper provides 3s delay. No fluid = no temperature sensitivity. | Mitigated |
| Shaped cam profile precision insufficient | LOW | SLA resin at 50mm/50μm. ReLU is simple geometry (flat + ramp). | Mitigated |
| Pendulum timing drifts with temperature | LOW | Steel pendulum rod. Not critical for training correctness. | Accepted |
| Sound palette too quiet in gallery setting | LOW | Resonance chambers under brass plaques. Tuned striker materials. | Deferred to Phase 8 |
| 42 strings tangle during routing | MEDIUM | Two-plane depth separation (20-30mm). Explicit string routing diagram required before modeling. | Partially mitigated |
| Frame deflection at 900mm span | LOW | 2020 aluminum extrusion (10× rigidity vs PLA). Corner brackets + T-slot mounting. | Mitigated |
| SLA spiral cam fragility (r_min area) | LOW | r_min raised from 0.5mm to 1.0mm. 40mm diameter gives robust cross-section. | Mitigated |

---

## 11. Success Criteria

1. **Convergence**: Machine reaches >80% accuracy on training set within 15 epochs (~26 minutes)
2. **Generalization**: On held-out examples (new pin strips), accuracy >60%
3. **Visibility**: A non-technical viewer can identify "something is being computed" within 30 seconds
4. **Interaction**: User can switch to PREDICT, turn prisms, and receive an answer in <10 seconds
5. **Sound**: All 11 acoustic events are audible and distinct at 1 meter distance
6. **Durability**: Machine completes 100 training runs without mechanical failure
7. **Beauty**: The machine looks like a musical instrument, not a gearbox

---

## 12. Visual Reference

Interactive HTML companion at:
`.superpowers/brainstorm/physical-transformer/`

- `01-architecture.html` — Six faces diagram, operation mapping
- `02-network.html` — Neural network topology, one-hot encoding, weight grid
- `03-mechanisms.html` — All 7 core mechanisms with SVG diagrams
- `04-signal-flow.html` — Complete signal path, timing budget
- `05-dimensions.html` — Component table, tolerance budget, build sequence (NOTE: stale — references v1 dimensions)
- `06-3d-explorer.html` — Interactive Three.js 3D model (orbit, zoom, preset views)

---

## 13. Open Items for Implementation Planning (Priority Order)

1. **Convergence simulation** — Python model of 3×3×3 network with exact backprop + noise injection at 15/20/25/30% levels on gradients. Validates that the machine CAN learn with mechanical noise. GO/NO-GO GATE.
2. **String routing diagram** — 2D top-down and side views showing all 42 string paths with pulley positions. Two-plane depth separation. Determines final pulley count (estimated 60-84). Prerequisite for 3D modeling.
3. **Spiral cam geometry validation** — Print test spiral cam at 40mm, validate ratchet engagement and gradient multiplication accuracy across operating range.
4. **Pantograph linkage lengths** — Kinematic analysis for target displacement range. Validate that 3 diamonds sum 4 terms with <2% error at 48 needle-bearing joints. Validate bidirectional force transmission (adjoint mode) with 13% attenuation budget.
5. **Motor torque rig** — NEMA 23 driving 6 worm gears through barrel cam. Measure actual torque at stall and at speed. Phase 1 go/no-go gate.
6. **Clamp bar timing** — Exact cam lobe profiles for the 2 clamp bars on main shaft. Dead zone between phases. Validate no string jamming.
7. **Barrel cam groove profile** — 13-tick timing sequence (8 forward + 5 adjoint) encoded as a 3D spiral with 7 weight-group sections. 270mm length in FDM PLA.
8. **Sliding collar differential calibration** — Leaf spring k values for 4 learning rate options
9. **Pin drum pin spacing** — 9 input bits + 3 target bits × 8 examples = 96 pin positions on 360mm drum

---

## 14. Prior Art

| Project | Team | Approach | Our Differentiation |
|---------|------|----------|-------------------|
| Schaffland MNN | Individual maker | Wooden levers, manual training | We: self-training, exact backprop, museum-quality brass |
| UCLA Metamaterial NN | Research lab | Metamaterial structure, acoustic | We: discrete components, visible computation, interactive |
| Nature 2024 Mechanical Adjoint | Research team | Proved mechanical backprop works | We: first discrete-component implementation at sculpture scale |

**No one has built a discrete-component, self-training, museum-quality kinetic neural network.** This is genuinely novel.

---

## Appendix A: Build Sequence (8 Phases)

### Phase 1: Torque Budget Validation
Build a test rig with NEMA 23 driving 6 worm gears through a barrel cam. Measure actual torque at stall and at speed. GO/NO-GO gate. Simultaneously: run convergence simulation in Python with 15-20% noise injection.

### Phase 2: Pantograph Diamond
Build one pantograph diamond chain (3 diamonds) with HK0306 needle bearings. Validate OA + OB = OC with measured inputs. Measure adjoint signal attenuation (target: <15% loss).

### Phase 3: Worm Gear Grid
Build a 3×2 subset of the weight matrix with off-shelf module 1.0 worm gear sets. Validate self-locking, friction angles, and reset clutch.

### Phase 4: Single Neuron
Integrate: worm selectors → pantograph summation → shaped cam activation → string output. One complete neuron, forward pass only.

### Phase 5: Forward Pass
Wire all 6 neurons. Validate: input prisms → through hidden layer → output prediction.

### Phase 6: Adjoint Backward Pass
Add clamp bars, sliding collar differentials, spiral cam gradient computers, rack-and-pinion updaters. Wire one neuron's complete forward+adjoint cycle. Validate: gradient magnitude and sign match Python reference within 20% error.

### Phase 7: Automation
Add pin drum, barrel cam sequencer, gravity pendulum timing, convergence detector. Validate full autonomous training loop.

### Phase 8: Polish
Acrylic panels, brass plaques, Rub 'n Buff accents, sound tuning, string tensioning, LED lighting, museum finish.
