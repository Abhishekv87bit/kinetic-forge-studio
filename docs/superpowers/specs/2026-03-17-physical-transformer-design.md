# The Physical Transformer — Design Specification

**Date**: 2026-03-17
**Status**: Draft
**Project**: Kinetic Sculpture Trilogy, Part III
**Trilogy**: Triple Helix (I) → Murmuration Engine (II) → Physical Transformer (III)

---

## 1. Vision

A kinetic sculpture that physically computes a neural network. Not a simulation — an actual analog computer that trains itself on language patterns, converges to learned weights, and produces predictions a human can interact with.

**Three pillars:**
1. **Computer-first** — The machine must actually converge during training
2. **Mesmerizing motion** — Computation itself is the art (Margolin aesthetic)
3. **Educational** — Demystifies AI: "It's not magic, it's mathematical probability"

**Core experience:** A viewer watches the machine train itself (pin drum feeds examples, weights adjust, loss decreases). Then they turn three brass dials, pull a lever, and the machine predicts.

---

## 2. Neural Network Architecture

### 2.1 Topology: 3x3x3 → 3 Proof of Concept

- **Input**: 3 words per dial x 3 dials = 9 one-hot binary inputs
- **Hidden layer**: 3 neurons (each receives 9 weighted inputs + 1 bias)
- **Output layer**: 3 neurons (each receives 3 weighted inputs + 1 bias)
- **Total weights**: 42 (9x3 + 3 bias + 3x3 + 3 bias)
- **Activation function**: ReLU (hidden layer), linear (output layer during training), winner-take-all (output layer during prediction only)

### 2.2 One-Hot Encoding

Each dial has 3 positions (e.g., "Cat", "Eats", "Fish"). Position 1 = [1,0,0], Position 2 = [0,1,0], Position 3 = [0,0,1]. This eliminates the need for mechanical multiplication in the forward pass — each weight is either used or not.

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
- **Time per example**: ~8 seconds (12 ticks at 0.7s each)
- **Time per epoch**: ~64 seconds (~1 minute)
- **Total training time**: ~16 minutes

---

## 3. The Six Faces & Viewer Experience

The machine is a 600 x 400 x 300mm box on a museum pedestal (~900mm high). Each face has a distinct purpose, designed around how a human approaches, observes, and interacts.

### 3.0 The Viewer Journey

**Stage 1 — APPROACH (3m)**: A golden box on a dark pedestal. Strings catch light inside. Something is moving. Sound: tick...tock...tick...tock...

**Stage 2 — FRONT FACE (1m, eye level)**: The primary display. Top-to-bottom triptych: 42 worm gears (memory) → 42 spiral cams (learning) → 3 error sliders (convergence). Brass plaques label each zone.

**Stage 3 — LEFT FACE (interaction station)**: Three brass word prisms at hand height. A red mode lever. An answer prism at eye level. Brass instruction plaque. The viewer touches the machine here.

**Stage 4 — RIGHT FACE (walk around)**: Pantograph diamonds breathing, shaped cams tracing functions, spring toggles snapping. The computation engine, visible through acrylic.

**Stage 5 — BACK FACE (backstage)**: Motor, barrel cam, pendulum. The engine room — partially hidden, heard more than seen. Raw mechanism, like seeing backstage at a theater.

**Stage 6 — THE STOP**: After ~20 minutes of training, the ticking stops. Silence. The convergence detector has tripped. The machine decided it has learned enough. A brass plaque reads: "WHEN I KNOW ENOUGH, I STOP."

**Stage 7 — PREDICTION**: The viewer pulls the mode lever (CLUNK). Turns the three word prisms. Watches the forward pass ripple through the strings. The answer prism rotates: chunk-chunk-chunk. A word appears.

**Pedestal height**: Box bottom at 900mm. Input prisms at ~1000-1100mm (hand height). Weight matrix at ~1100-1300mm (eye level). Pin drum at ~1360mm (slightly above — the "teacher" looks down). Answer prism at ~1250mm (easy to read).

**Lighting**: LED strips behind frame edges (the only electronics besides the motor). Side-lit brass wire glows gold against the dark PLA frame. Clear acrylic panels become windows into the mechanism.

### 3.1 FRONT — Weight Matrix (42 Worm Gears)

**What you see**: 42 brass worm gears arranged in 6 rows behind clear acrylic. Top 3 rows: hidden neurons (10 gears each = 9 weights + 1 bias). Bottom 3 rows: output neurons (4 gears each = 3 weights + 1 bias). Color-coded indicator discs: blue (input→hidden), purple (hidden→output), gold (biases).

**Mechanism**: Self-locking worm gears. The friction angle exceeds the lead angle, so weights persist without power. Backdriven only during training (worm drives the wheel). A friction-clutch common shaft enables simultaneous reset: clutch engages all worms to a common drive shaft, which spins them to a neutral (zero) position. Disengaging the clutch returns each worm to independent, self-locked state. The cascade of clicks during reset is one of the machine's signature sounds.

**Why worm gears**: Self-locking = persistent memory. No springs, no latches, no power needed. The weight IS the gear position.

### 3.2 TOP — Pin Drum (Training Data)

**What you see**: A brass cylinder (~360mm long) mounted on bearings above the machine, studded with removable pin strips. Each strip = one training example. Pins protrude to encode one-hot bit patterns.

**Mechanism**: Barrel Cam 2b indexing. Each training step: (1) pin readers sense current example, (2) drum indexes one strip forward via star-wheel ratchet, (3) spring-loaded push-down/rotate/spring-up sequence.

**Margolin touch**: Pin strips are removable — you can reprogram the machine by swapping strips. Different training sets, different learned behavior.

### 3.3 RIGHT — Computation Engine (Pantograph Diamonds + Shaped Cams)

**What you see**: Cascading rhombus diamonds that expand and contract like breathing lungs. Brass cam profiles that trace mathematical functions. Springs that SNAP when neurons fire.

**Decided mechanism — Pantograph cascade**: Rhombus linkages where OA + OB = OC (pantograph adding mechanism). Three chains of 3 diamonds each (one chain per hidden neuron). Each hidden neuron has 9 weights + 1 bias = 10 connections, but one-hot encoding guarantees only 3 inputs are active at any time (one per dial) + 1 bias = 4 active terms. Three diamonds per chain sum exactly 4 terms: diamond 1 sums terms 1+2, diamond 2 adds term 3, diamond 3 adds bias. Inactive inputs produce zero displacement via the one-hot string clamp mechanism (see Section 3.4).

**Why pantograph over Archimedes lever**: Levers accumulate friction at pivot points. Pantographs distribute force across the rhombus — each diamond adds one term cleanly. The expanding/contracting motion is also far more visually dramatic than a tilting beam.

**String compliance mitigation**: All strings are pre-tensioned with spring tensioners at their anchor points. Pre-tension eliminates dead zone — the pantograph input moves immediately when a weight string is released. String material: 0.5mm braided brass wire (near-zero creep, high stiffness). Maximum 2 pulley redirections per string line to minimize friction losses.

**Shaped cam activation functions**: Each hidden neuron has a brass cam whose profile IS the activation function. ReLU = flat region + linear ramp. A spring-loaded follower rides the cam, converting summed displacement into activated output. Output neurons have NO shaped cam (linear activation during training, winner-take-all during prediction only).

**Cams do double duty in adjoint pass**: During the backward pass, the shaped cam automatically computes the ReLU derivative. When the cam is in the active region (positive input, follower on the ramp), adjoint force transmits back through the cam at ratio 1:1 (derivative = 1). When the cam is in the dead region (negative input, follower on the flat), adjoint force pushes into the flat — no torque transmitted (derivative = 0). The cam's geometry IS the chain rule.

**Spring toggle neuron firing**: Bistable toggle mechanism produces an audible SNAP when a neuron's activation crosses threshold. Binary, decisive, satisfying.

**42 Archimedean spiral cam gradient computers**: Mounted on the front face BELOW the worm gear grid (not behind it — they must be visible). One per weight. Each spiral cam stores the forward-pass string displacement as an angular position (via ratchet). During the adjoint pass, the backward-traveling string wraps onto the cam at the stored radius. The resulting torque = forward displacement x adjoint displacement = exact gradient. 42 brass spirals catching light at different angles.

**Front face triptych (top to bottom)**: The front face is the primary display, read top-to-bottom like a story:
- **Top third**: Worm gear weight matrix (THE MEMORY — 42 gears settle into final positions)
- **Middle third**: Spiral cam gradient array (THE LEARNING — 42 discs oscillate during adjoint pass, shrink as gradients decrease)
- **Bottom third**: 3 sliding collar differentials on a polished brass plate (THE ERROR — sliders converge toward "ZERO ERROR" as training progresses)

Viewers watch: memory stabilizing, learning diminishing, error vanishing. The machine tells its own story.

### 3.4 LEFT — I/O Panel (Human Interaction)

**What you see**: Three brass word prisms (rotating polygon drums) at comfortable hand height. A prominent red lever for TRAIN/PREDICT mode. A matching answer prism above that rotates to show the prediction.

**Input word prisms**: Each input is a triangular prism (3 rectangular faces for 3 words) mounted on a horizontal axis. The user rotates the prism by hand — it clicks into detent positions (spring-loaded ball detent, one per face). The selected word faces the viewer directly in large engraved text. No pointer, no decoding — you just read the face pointing at you. The prism shaft connects via string to the one-hot selector mechanism inside. Each of the 3 detent positions engages exactly one of three string clamps.

**Scalability**: For a larger vocabulary, replace triangular prisms with pentagonal (5 words), hexagonal (6), or heptagonal (7). The one-hot encoding expands accordingly — more faces = more input bits = more weights. The POC uses triangular (3 words).

**One-hot gating mechanism**: Each prism detent position engages exactly one of three string clamps. Active position: clamp releases string, allowing it to transmit weight displacement to the pantograph. Inactive positions: clamp locks string to a fixed anchor, producing exactly zero displacement regardless of worm gear position. Spring-loaded cam followers on the prism shaft actuate the clamps — rotating the prism physically disconnects 2 strings and connects 1. This ensures inactive inputs contribute precisely zero to the pantograph sum (not "less" — zero).

**Mode switch — Dog clutch with dual output routing**: Large lever with spring-loaded toggle. CLUNK sound on engagement. The dog clutch is a sliding collar on a horizontal shaft behind the output rods. It has two sets of engagement teeth:
- **TRAIN position**: Lateral coupling links connect 3 output rods to 3 independent whippletree error beams. Geneva drive disengaged — prism sits still. Motor runs, pin drum feeds, adjoint pass computes gradients, weights update.
- **PREDICT position**: Whippletree links retract (return springs). Tilting comparison beam engages — finds highest output rod, drives Geneva drive. Motor stops, dials connect to forward pass only.

**Three output rods**: Each output-layer pantograph terminates at a brass rod that always produces continuous displacement — in both modes. The rods are the raw analog outputs. What changes between modes is which downstream mechanism reads them.

**Winner-take-all comparator (PREDICT only)**: A tilting brass comparison beam (120mm) rests on whichever of the 3 output rods is highest. The beam's tilt drives a follower arm into the Geneva drive input disc, indexing the answer prism to the winning face.

**Answer word prism — 3-slot Geneva drive**: A triangular prism matching the input prisms in form factor — same brass material, same size, same horizontal axis mount. 3 rectangular faces, each engraved with one output word. Geneva drive produces 120-degree indexing — discrete, positive stops (chunk-chunk-chunk). Engages only in PREDICT mode. Mounted above the mode lever at eye level, so the viewer looks straight at the answer. The visual symmetry between input prisms (below, hand height) and answer prism (above, eye level) reinforces the input→output narrative: "I chose these words, the machine predicted this one."

### 3.5 BACK — Motor & Timing

**What you see**: Single NEMA 17 stepper motor driving a barrel cam sequencer. Gravity pendulum providing the heartbeat. All timing derived from one motor.

**Barrel Cam 2b**: Spiral groove on a cylinder. A follower pin rides the groove, converting rotation into a timed sequence of operations. One full revolution = one training example (forward pass + backward pass + weight update).

**Gravity pendulum escapement**: Replaces clock escapement. Weighted arm swings with audible tick-tock, gating the computation into discrete steps. Each swing = one neural operation advancing.

**Shishi-odoshi upgrade**: At end of each training example, a water-hammer style striker produces a resonant TOCK — marking completion. Gravity fills, tips, strikes, resets.

**Convergence auto-stop (mechanical logic)**: The machine knows when it has learned enough and stops itself. Three mechanical AND gate inputs come from the sliding collar differentials: when all 3 error sliders are within a threshold of center, spring-loaded pins (one per slider) drop into threshold notches. When all 3 pins are engaged simultaneously, a mechanical AND condition is met — a common bar drops under spring force, which disengages the motor clutch. Training stops. The pendulum swings to a halt. Silence.

Implementation: Each sliding collar has a V-notch at center position. A spring-loaded pin rides above the slider. When the slider is within the notch width (~2mm = convergence threshold), the pin drops into the notch. Three pins connect to a common trigger bar via short levers. The trigger bar is held up by any pin that hasn't dropped. When all 3 drop: trigger bar falls → trips a lever → disengages the motor drive clutch (same clutch used by the mode switch). The motor continues spinning but the barrel cam stops — the machine goes silent.

**The theater**: Viewers watch error bars converge over 15-20 minutes. Then suddenly — the ticking stops. The machine decided it has learned. The brass plaque next to the convergence detector reads: "WHEN I KNOW ENOUGH, I STOP."

The convergence threshold is adjustable — the V-notch width on each slider can be changed by replacing the notch insert (wider = easier to converge, narrower = more precise).

### 3.6 BOTTOM — Loss Computation & Gradient Descent

**What you see**: Cascading balance beams (whippletree) computing error. A brass cycloid track where a steel ball rolls — the brachistochrone curve visualizing gradient descent.

**Three independent whippletree beams**: One per output neuron (not one aggregate). Each beam compares that neuron's predicted displacement against its target displacement from the pin drum. In TRAIN mode, these beams tilt proportionally to per-neuron error and feed into the sliding collar differentials (see Section 5.2). In aggregate, a cascading fourth beam sums the three errors for the brachistochrone loss visualization. Zero-friction pivots on knife edges.

**Three sliding collar differentials**: Mounted on a polished brass plate, visible from the front. Each slider displaces left/right as errors occur. As training progresses, sliders visibly converge toward center ("ZERO ERROR" engraved at detent). Blued steel leaf springs convert displacement to adjoint force. The audience watches the machine learn in real time — error shrinking to nothing.

**Brachistochrone ball track**: Cycloid curve (Bernoulli, 1696). After aggregate loss is computed, a ball is released and rolls down the fastest-descent curve. Ball rolls to a spring-loaded catch gate positioned by the scissor amplifier (5x loss magnitude). Ball stops at gate — viewer reads loss as ball position. Return mechanism: lever tips track, ball rolls back via gravity return channel on the underside. As training progresses, the ball rolls less far — loss is decreasing.

**Scissor Mechanism 2 (5x amplifier)**: Mixed-size rhombi amplify small loss changes into visible displacement. Loss might change by 2mm, but the scissor amplifies to 10mm of visible motion.

---

## 4. Locked Design Decisions

### 4.1 Summation: Pantograph Diamond Cascade

**Decision**: Pantograph rhombus linkages for all weighted summation.
**Over**: Archimedes lever (friction accumulation), cam-string Kelvin (less visible).
**Rationale**: Most visible, most poetic, best motion quality. Diamonds expand like breathing.

### 4.2 Signal Routing: Strings (Margolin Aesthetic)

**Decision**: Brass-wire strings threaded over small pulleys for all signal transmission.
**Over**: Rigid brass rods (industrial look), hybrid (inconsistent aesthetic).
**Rationale**: Margolin aesthetic — strings create a harp-like visual. Catenary sag adds organic beauty. Pulleys redirect cleanly. ~21 string lines total.

### 4.3 Overall Aesthetic: Margolin (String + Cam + Pantograph)

**Decision**: Bold path — pantograph diamonds + string routing + shaped cams.
**Over**: Conservative lever+rod, hybrid approaches.
**Rationale**: The machine should look like a musical instrument, not a gearbox. Every signal should be visible as a vibrating, tensioned line. Every computation should breathe.

### 4.4 Training: Exact Adjoint Backpropagation

**Decision**: Adjoint variable method — two physical equilibrium states (forward + adjoint) through the same network yield exact gradients.
**Over**: Perturbation-based learning (robust but 3x slower), contrastive Hebbian (approximate gradients), digital twin (hybrid, defeats the purpose).
**Rationale**: Nature 2024 proved it works mechanically. Halves training time. Same 21 strings carry both forward and adjoint signals (Maxwell's reciprocity). Shaped cams compute ReLU derivative for free (flat = 0, ramp = 1). The two-phase breathing cycle (forward wave left-to-right, adjoint wave right-to-left) is more visually dramatic than one-directional flow.

### 4.5 I/O Form Factor: Rotating Word Prisms (Not Dials)

**Decision**: Triangular brass prisms (3 rectangular faces, horizontal axis) for both input selection and answer display.
**Over**: Watch-style dials with pointers, LCD displays, printed labels.
**Rationale**: The selected word IS the face — large, legible, unambiguous. No pointer to decode, no tiny labels to squint at. Input and answer share the same physical vocabulary (both are prisms), reinforcing the input→output narrative. Scales to 5-7 faces for larger vocabulary. Detent clicks provide tactile feedback.

### 4.6 Single Motor

**Decision**: One NEMA 17 stepper drives everything through mechanical sequencing.
**Rationale**: Project rule. Single motor proves that all complexity emerges from one source of energy — like how neural networks emerge from simple repeated operations.

### 4.7 Materials Palette

| Material | Role | Color |
|----------|------|-------|
| Brass | Compute (moving parts) | Gold |
| Black PLA | Structure (frame, mounts) | Matte black |
| Clear acrylic | Transparency (side panels) | Transparent |
| Steel | Precision (pivots, shafts, ball) | Silver |
| Red accent | Answers + interaction (prism, lever knob, dial pointers) | Deep red |

### 4.8 Sound Palette (Designed Acoustic Events)

| Event | Sound | Mechanism |
|-------|-------|-----------|
| Heartbeat (each operation) | tick...tock | Gravity pendulum escapement |
| Neuron fires | SNAP | Bistable spring toggle |
| Weight adjusts | click-click-click | Worm gear ratcheting |
| Training example complete | TOCK | Shishi-odoshi striker |
| Mode switch | CLUNK | Dog clutch engagement |
| Epoch complete | cascade of clicks | Friction-clutch mass reset |
| Ball release (gradient) | silence → rolling | Brachistochrone track |
| Answer revealed | chunk-chunk-chunk | Geneva drive indexing |
| Dial selection | click | Detent mechanism |
| Convergence auto-stop | tick...tock...(silence) | Mechanical AND gate trips motor clutch |
| Full convergence | sustained silence, stillness | All motion ceases — the machine has learned |

---

## 5. Signal Flow

### 5.1 Forward Pass (10 ticks)

1. **Tick 1**: Pin drum (or dial) sets 9 input bits via string clamps (one-hot gates)
2. **Tick 2**: Active weight strings engage — 3 active + 1 bias per hidden neuron
3. **Tick 3**: Hidden-layer pantograph diamonds begin expanding (weighted sum accumulates)
4. **Tick 4**: Pantograph cascade settles — sum complete for all 3 hidden neurons
5. **Tick 5**: Shaped cam followers ride cam profiles — ReLU activation applied
6. **Tick 6**: Activated hidden outputs route via strings to output-layer pantographs
7. **Tick 7**: Output-layer pantograph diamonds expand (3 weights + 1 bias each)
8. **Tick 8**: Output pantograph cascade settles — 3 output sums ready
9. **Tick 9**: Winner-take-all: highest displacement output neuron drives Geneva drive
10. **Tick 10**: Answer prism rotates to show prediction — chunk-chunk-chunk

### 5.2 Backward Pass — Exact Adjoint Backpropagation (5 ticks, TRAIN mode only)

**Training method: Adjoint variable method.** Based on the 2024 Nature Communications proof that exact gradients can be obtained from mechanical networks using only two equilibrium states (forward + adjoint). The same physical network propagates signals in both directions — no separate backward network needed. Maxwell's reciprocity theorem (1864) guarantees that driving a linear mechanism backward computes exactly the transpose of the forward operator.

**Phase switching — 4 clamp bars**: The 21 strings carry signals bidirectionally via a two-phase cycle. Four brass clamp bars (one at each layer boundary) switch which string endpoints are driven vs. free:
- **Forward phase**: Input clamps ENGAGED (motor drives inputs), output clamps FREE (outputs respond)
- **Dead zone**: All clamps FREE (everything settles to equilibrium)
- **Adjoint phase**: Output clamps ENGAGED (error mechanism drives outputs), input clamps FREE (inputs respond to backward signal)

Each clamp bar is a brass strip with a fixed jaw and a cam-actuated moving jaw. Spring-loaded return (fail-open design). One cam lobe per clamp bar on the main drive shaft.

**Error force generation — 3 sliding collar differentials**: One per output neuron. A brass slider rides a horizontal rail, pulled from opposite sides by the predicted output string and the target string (from pin drum). Slider displacement = (predicted - target) = error. A calibrated leaf spring (0.3mm spring steel) converts displacement to force: F = -k * error. A yoke on the slider routes bidirectional force via opposing string pairs back into the output node.

**Swappable leaf springs = adjustable learning rate.** Display a rack of 5 springs with different k values, color-coded. Viewers can see the "hyperparameter."

11. **Tick 11 (ADJOINT START)**: Clamp bars switch — output clamps engage, input clamps release. 42 spiral cam ratchets lock (storing forward-pass displacements). Three sliding collar differentials compute error forces.
12. **Tick 12**: Error forces propagate backward through output-layer pantographs (mechanically reversible — push output, inputs move proportionally). Through shaped cams: active neurons (follower on ramp) pass signal at 1:1, dead neurons (follower on flat) block signal — the ReLU derivative, computed by geometry.
13. **Tick 13**: Adjoint signal reaches all 42 weight positions. At each weight, the adjoint string wraps onto the Archimedean spiral cam at the stored forward-displacement radius. Torque = forward × adjoint = exact gradient.
14. **Tick 14**: Gradient torque drives output rack → rack-and-pinion drives worm shaft → weight updates. 42 clicks as all weights adjust simultaneously. Barrel cam sequences through 7 groups of 6 for staged engagement (torque management). Brachistochrone ball released — loss visualization.
15. **Tick 15**: Global reset bar lifts all 42 ratchet pawls (spiral cams return to zero). Clamp bars return to forward configuration. Pin drum indexes to next example. Shishi-odoshi striker fires — TOCK.

**Rack-and-pinion weight update**: Each gradient output rack meshes with a pinion on an intermediate shaft, through a 4:1 reduction gear pair, to the worm shaft. Self-locking preserved (worm drives from the worm side during updates, self-locks from the wheel side at all other times). Swappable pinion = learning rate: Z=8 (aggressive), Z=12 (medium), Z=16 (default), Z=24 (fine-tuning).

### 5.3 Timing Budget

- 1 tick = ~0.7 seconds (pendulum period at 250mm length)
- 1 training example = 15 ticks (~10 forward + ~5 adjoint) = ~10.5 seconds
- 1 epoch (8 examples) = ~84 seconds (~1.4 minutes)
- 15 epochs to convergence = ~21 minutes
- Total pins/drums: 8 strips x 12 pins each (9 input bits + 3 target bits)

### 5.4 Why Adjoint Over Perturbation

Perturbation-based learning (the conservative option) wiggles each weight independently and measures loss change — correct but slow (evaluates 42 weights sequentially per example). The adjoint method computes all 42 gradients in a single backward pass, cutting training time from ~48 minutes to ~21 minutes. The 2024 Nature paper proved mechanical adjoint gradients achieve >90% accuracy vs. theoretical exact values. Our 10-15% gradient error from mechanical tolerances (ratchet quantization, string friction, spiral cam bias) is well within SGD's proven 30% noise tolerance.

---

## 6. Adjoint Backpropagation — Mechanism Detail

This section specifies the four new mechanism systems that enable exact backpropagation. All are additions to the forward-pass mechanisms described in Section 3.

### 6.1 Clamp Bars (Bidirectional String Phase Switching)

4 assemblies, one at each layer boundary. Each clamp bar is a brass strip running perpendicular to the strings:
- **Fixed jaw**: bolted to frame
- **Moving jaw**: actuated by cam follower on main drive shaft
- **Jaw gap**: 2mm open (string moves freely), 0mm closed (brass-on-brass pinch locks string)
- **Actuation**: One cam lobe per clamp bar. Forward phase closes input clamps, adjoint phase closes output clamps. 15-degree dead zone between phases.
- **Spring return**: Compression spring opens jaw when cam releases (fail-open — if anything breaks, strings go free)

The two-phase cycle creates a visible breathing rhythm: strings tighten left-to-right (forward), pause, then tighten right-to-left (adjoint). The clamp bars look like frets on a stringed instrument.

### 6.2 Sliding Collar Differentials (Error Force Generation)

3 units, one per output neuron. Mounted on a polished brass plate, visible from the front.
- **Rail**: 3mm brass rod, 80mm long
- **Slider**: 10x8x8mm brass, bored for rail
- **Predicted string**: from output pantograph rod, pulls slider one direction
- **Target string**: from pin drum target pins, pulls slider opposite direction
- **Slider displacement** = (predicted - target) = error signal
- **Leaf spring**: 0.3mm x 5mm x 60mm spring steel (blued), anchored at rail center. Converts displacement to force F = -k * error
- **Yoke**: brass sheet on slider, routes bidirectional force via opposing string pairs (String+ and String-) to output node
- **Center detent**: engraved "ZERO ERROR" — as training progresses, sliders converge toward center

### 6.3 Archimedean Spiral Cam Gradient Computers

42 units, one per weight. The core multiplication mechanism.
- **Spiral cam**: 12mm max diameter brass disc, Archimedean spiral profile (r_min=0.5mm, r_max=6mm, 254 degrees active)
- **Forward capture**: Weight string drives a 0.3-module rack → 12T pinion → rotates spiral cam shaft. 24-tooth ratchet wheel locks angular position = stored forward displacement.
- **Adjoint capture**: Backward-traveling string wraps onto spiral cam edge at the stored radius. Torque = tension x radius = forward x adjoint = gradient.
- **Output**: 8T pinion on same shaft drives output rack (5mm travel). Rack displacement = gradient magnitude and direction.
- **Dimensions per unit**: 30mm x 22mm x 12mm on PLA frame plate
- **Array layout**: 6x7 grid at 35mm pitch = 210mm x 245mm total (mounted behind worm gear grid)
- **Error budget**: ratchet quantization (15 degrees = 0.47mm resolution) + cone bias (r_min offset ~8%) + bushing friction (~5%) = total ~10-15% gradient error

### 6.4 Rack-and-Pinion Weight Updaters

42 units, integrated with spiral cam output. Converts gradient displacement to worm gear rotation.
- **Gradient rack**: 0.5 module, driven by spiral cam output
- **Pinion**: swappable, press-fit brass gear on intermediate shaft. Z=8/12/16/24 = 4 learning rates
- **Reduction**: 48:12 (4:1) gear pair
- **Worm shaft gear**: Z=12, meshes with reduction output
- **Worm**: 1-start, 0.5 module, steel. Self-locking (friction angle 11 degrees > lead angle 5.3 degrees)
- **Total ratio**: 1mm rack displacement → 0.119 degrees worm gear rotation (at Z=16 default)
- **Weight resolution**: ~3024 steps over 360 degrees
- **Staged engagement**: Barrel cam sequences through 7 groups of 6 weights. One NEMA 17 drives max 6 updates simultaneously.

---

## 7. Dimensions & Tolerances

### 7.1 Envelope

- **Width**: 600mm (front face — weight matrix)
- **Height**: 400mm (frame) + 60mm (pin drum above) = 460mm total. Pendulum (250mm) hangs inside the frame from the back top rail — does not extend beyond envelope.
- **Depth**: 300mm
- **Weight estimate**: 4-6 kg
- **Pedestal/base**: Not included in envelope — separate museum-style mount

### 7.2 Key Component Dimensions

| Component | Count | Size (mm) | Material |
|-----------|-------|-----------|----------|
| Worm gear assembly | 42 | 24dia x 20 | Brass + steel |
| Spiral cam gradient computer | 42 | 12dia x 12, on 30x22 frame | Brass cam, steel shaft, PLA frame |
| Rack-and-pinion updater | 42 | 0.5 module, 8mm travel | Brass rack, steel pinion |
| Pantograph diamond | 9 (3x3) | 70 x 40 (expanded) | Brass bars, PTFE-bushed joints |
| Shaped cam (ReLU) | 3 | 36dia x 10 | Brass (hidden layer only) |
| Clamp bar assembly | 4 | 80-200 wide x 12 | Brass jaws, steel cam follower |
| Sliding collar differential | 3 | 80 rail x 10x8 slider | Brass slider, blued steel spring |
| Comparison beam (predict) | 1 | 120 x 8 x 4 | Brass |
| Input word prism (triangular) | 3 | 40 face width x 60 long, on horizontal axis | Brass, engraved text |
| Answer word prism (triangular) | 1 | 40 face width x 60 long, on horizontal axis | Brass, engraved text |
| Convergence detector (AND gate) | 1 | 3 spring pins + trigger bar, 80mm wide | Steel pins, brass bar |
| Pin drum | 1 | 70dia x 360 | Brass |
| Gravity pendulum | 1 | 250 long, 30dia bob | Brass + steel rod |
| Barrel cam (sequencer) | 1 | 40dia x 180 | Dark brass, 7 groove sections |
| NEMA 17 motor | 1 | 42 x 42 x 48 | Stock |
| Whippletree beams | 4 | 80-200 x 4 x 8 | Brass (3 per-neuron + 1 aggregate) |
| Dog clutch collar | 1 | 30 x 18dia | Steel |
| Spring toggles | 3 | ~20 x 10 | Steel spring (hidden layer) |
| String pulleys | 16 | 12dia | Brass |
| Frame edges | 12 | 8 x 8 x varies | Black PLA |
| Acrylic panels | 3 | varies x 3 thick | Clear |

### 7.3 Tolerances

- General: 0.2mm
- Sliding fits (cam followers, pantograph joints): 0.3mm
- Press fits (bearings, shafts): 0.1mm
- Minimum feature size: 1.5mm (3D print constraint)
- String: Braided brass wire, 0.5mm dia

---

## 8. Build Sequence

### Phase 1: Torque Budget Validation
Build a test rig with NEMA 17 driving 6 worm gears through a barrel cam. Measure actual torque at stall and at speed. This is the go/no-go gate — if it fails, the single-motor constraint requires redesign. Simultaneously: run convergence simulation in Python with noise injection (see Section 5.2 note).

### Phase 2: Pantograph Diamond
Build one pantograph diamond chain (3 diamonds). Validate OA + OB = OC with measured inputs.

### Phase 3: Worm Gear Grid
Build a 3x2 subset of the weight matrix. Validate self-locking, friction angles, and reset clutch.

### Phase 4: Single Neuron
Integrate: worm selectors → pantograph summation → shaped cam activation → string output. One complete neuron, forward pass only.

### Phase 5: Forward Pass
Wire all 6 neurons. Validate: input dials → through hidden layer → output prediction.

### Phase 6: Adjoint Backward Pass
Add clamp bars, sliding collar differentials, spiral cam gradient computers, rack-and-pinion updaters. Wire one neuron's complete forward+adjoint cycle. Validate: gradient magnitude and sign match Python reference within 15% error.

### Phase 7: Automation
Add pin drum, barrel cam sequencer, gravity pendulum timing. Validate full autonomous training loop.

### Phase 8: Polish
Acrylic panels, brass plaques, sound tuning, string tensioning, museum finish.

---

## 9. Mechanism Heritage

Every mechanism in this machine has historical provenance:

| Mechanism | Origin | Year |
|-----------|--------|------|
| Archimedes lever | Archimedes | ~250 BCE |
| Worm gear | Ancient Greece | ~100 BCE |
| Pantograph | Christoph Scheiner | 1603 |
| Brachistochrone | Johann Bernoulli | 1696 |
| Geneva drive | Swiss watchmaking | ~1700s |
| Whippletree | Horse-drawn agriculture | ~1800s |
| Barrel cam | Industrial revolution | ~1850s |
| Dog clutch | Machine tooling | ~1880s |
| Spring toggle | Electrical switching | ~1900s |
| Shaped cam (function generator) | Mechanical computing | ~1930s |
| Archimedean spiral | Archimedes | ~250 BCE |
| Rack and pinion | Ancient engineering | ~300 BCE |
| Shishi-odoshi | Japanese garden design | Traditional |
| Adjoint variable method | Pontryagin / Lions | 1950s-60s |

**Design philosophy**: Every mechanism in this machine was invented before the transistor (the adjoint method predates practical digital neural networks by decades). The machine proves that intelligence can emerge from brass, steel, and string — no electricity required in the computation path.

---

## 10. Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Pantograph friction prevents convergence | High | Knife-edge pivots, PTFE bushings, validate Phase 2 early |
| String stretch/creep over 40 min training | Medium | Braided brass wire (low creep), tension springs at endpoints |
| Worm gear backlash accumulates error | Medium | Anti-backlash split gears, validate Phase 3 |
| 42 weights too many for single motor torque | High | Staged engagement (barrel cam activates 6 at a time, not 42) |
| Shaped cam profile precision insufficient | Medium | CNC mill cam blanks (don't 3D print activation functions) |
| Pendulum timing drifts with temperature | Low | Steel pendulum rod (low thermal expansion), not critical for training |
| Sound palette too quiet in gallery setting | Low | Resonance chambers under brass plaques, tuned striker materials |
| Adjoint gradient noise exceeds 30% tolerance | High | Run Python simulation with noise injection at 5/10/20/30% levels. Nature 2024 showed >90% gradient accuracy with physical systems. Our spiral cam + ratchet adds ~10-15% error — within margin |
| Clamp bar timing: strings jam if clamps overlap | Medium | 15-degree dead zone on main cam between phases. Fail-open spring return on all clamp bars |
| Spiral cam ratchet quantization (15 degrees) too coarse | Medium | 24-tooth ratchet = 0.47mm displacement resolution. Equivalent to gradient quantization in digital SGD (proven technique) |
| Adjoint signal attenuation through 3 layers | Medium | PTFE-bushed pantograph joints, ball-bearing pulleys, stiff brass wire for critical paths. Validate Phase 2 with measured attenuation |
| Leaf spring fatigue after 1000+ training cycles | Low | Spring steel 301 rated for >10^6 cycles at this deflection range |

---

## 11. Success Criteria

1. **Convergence**: Machine reaches >80% accuracy on training set within 15 epochs (~21 minutes)
2. **Generalization**: On held-out examples (new pin strips), accuracy >60%
3. **Visibility**: A non-technical viewer can identify "something is being computed" within 30 seconds
4. **Interaction**: User can switch to PREDICT, turn dials, and receive an answer in <10 seconds
5. **Sound**: All 10 acoustic events are audible and distinct at 1 meter distance
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
- `05-dimensions.html` — Component table, tolerance budget, build sequence
- `06-3d-explorer.html` — Interactive Three.js 3D model (orbit, zoom, preset views)

---

## 13. Open Items for Implementation Planning (Priority Order)

1. **Motor torque budget** — sum all mechanism loads (42 worm gears in groups of 6 + barrel cam + pin drum + clamp bars + pendulum), verify NEMA 17 suffices. GO/NO-GO GATE.
2. **Convergence simulation** — Python model of 3x3x3 network with exact backprop + noise injection at 5/10/15/20/30% levels on gradients. Validates that the machine CAN learn with mechanical noise.
3. **Spiral cam geometry** — Archimedean spiral profile: r_min=0.5mm, r_max=6mm, 254 degrees of active travel. Validate multiplication accuracy across operating range.
4. **Pantograph linkage lengths** — kinematic analysis for target displacement range. Validate that 3 diamonds sum 4 terms with <2% error. Validate bidirectional force transmission (adjoint mode).
5. **Clamp bar timing** — exact cam lobe profiles for the 4 clamp bars on main shaft. Dead zone between phases. Validate no string jamming.
6. **Exact gear module and tooth count** for worm gears (self-locking verification) and rack-and-pinion updaters (0.5 module, learning rate ratios)
7. **Shaped cam profile equations** — convert ReLU to polar coordinates for CNC. Validate that flat region blocks adjoint signal (derivative = 0).
8. **String routing diagram** — exact pulley positions for all 21 lines, max 2 redirections per line. Must work bidirectionally.
9. **Barrel cam groove profile** — 15-tick timing sequence (forward 10 + adjoint 5) encoded as a 3D spiral with 7 weight-group sections
10. **Sliding collar differential calibration** — leaf spring k values for 5 learning rate options
11. **Pin drum pin spacing** — 9 input bits + 3 target bits x 8 examples = 96 pin positions
