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
- **Activation function**: ReLU (hidden), winner-take-all (output — highest activation wins, no softmax needed)

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

- **Learning rate**: Fixed, encoded as a gear ratio
- **Epochs**: ~30 (perturbation-based learning converges slower than backprop)
- **Examples per epoch**: 8
- **Time per example**: ~12 seconds (17 ticks at 0.7s each)
- **Time per epoch**: ~1.5 minutes
- **Total training time**: ~48 minutes

---

## 3. The Six Faces

The machine is a 600 x 400 x 300mm box. Each face has a distinct purpose.

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

**Shaped cam activation functions**: Each neuron has a brass cam whose profile IS the activation function. ReLU = flat region + linear ramp. Sigmoid approximation = S-curve profile. A follower rides the cam, converting summed displacement into activated output.

**Spring toggle neuron firing**: Bistable toggle mechanism produces an audible SNAP when a neuron's activation crosses threshold. Binary, decisive, satisfying.

### 3.4 LEFT — I/O Panel (Human Interaction)

**What you see**: Three large brass dials with engraved word labels (3 positions each). A prominent red lever for TRAIN/PREDICT mode. A triangular answer prism that rotates to display the prediction.

**Input dials**: Each dial connects via string to the one-hot selector mechanism inside. Turn dial to "Cat" → string pulls the [1,0,0] position. Detent clicks at each of 3 positions.

**One-hot gating mechanism**: Each dial position engages exactly one of three string clamps. Active position: clamp releases string, allowing it to transmit weight displacement to the pantograph. Inactive positions: clamp locks string to a fixed anchor, producing exactly zero displacement regardless of worm gear position. Spring-loaded cam followers on the dial shaft actuate the clamps — rotating the dial physically disconnects 2 strings and connects 1. This ensures inactive inputs contribute precisely zero to the pantograph sum (not "less" — zero).

**Mode switch — Dog clutch**: Large lever with spring-loaded toggle. CLUNK sound on engagement. In TRAIN position: motor runs, pin drum feeds, weights update. In PREDICT position: motor stops, dials connect to forward pass only.

**Answer prism — 3-slot Geneva drive**: Triangular prism with 3 faces (one per output word). Geneva drive produces 120-degree indexing — discrete, positive stops. The winning output neuron drives the prism rotation.

### 3.5 BACK — Motor & Timing

**What you see**: Single NEMA 17 stepper motor driving a barrel cam sequencer. Gravity pendulum providing the heartbeat. All timing derived from one motor.

**Barrel Cam 2b**: Spiral groove on a cylinder. A follower pin rides the groove, converting rotation into a timed sequence of operations. One full revolution = one training example (forward pass + backward pass + weight update).

**Gravity pendulum escapement**: Replaces clock escapement. Weighted arm swings with audible tick-tock, gating the computation into discrete steps. Each swing = one neural operation advancing.

**Shishi-odoshi upgrade**: At end of each training example, a water-hammer style striker produces a resonant TOCK — marking completion. Gravity fills, tips, strikes, resets.

### 3.6 BOTTOM — Loss Computation & Gradient Descent

**What you see**: Cascading balance beams (whippletree) computing error. A brass cycloid track where a steel ball rolls — the brachistochrone curve visualizing gradient descent.

**Whippletree / Calder mobile**: Nested balance beams cascade the difference between predicted and actual output. Like a Calder mobile — the error ripples through the tree, settling at the loss value. Zero-friction pivots on knife edges.

**Brachistochrone ball track**: Cycloid curve (Bernoulli, 1696). After loss is computed, a ball is released and rolls down the fastest-descent curve. The ball's position along the track = current loss. As training progresses, the ball rolls less far — loss is decreasing. Viewers can literally watch the machine get smarter.

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

### 4.4 Single Motor

**Decision**: One NEMA 17 stepper drives everything through mechanical sequencing.
**Rationale**: Project rule. Single motor proves that all complexity emerges from one source of energy — like how neural networks emerge from simple repeated operations.

### 4.5 Materials Palette

| Material | Role | Color |
|----------|------|-------|
| Brass | Compute (moving parts) | Gold |
| Black PLA | Structure (frame, mounts) | Matte black |
| Clear acrylic | Transparency (side panels) | Transparent |
| Steel | Precision (pivots, shafts, ball) | Silver |
| Red accent | Answers + interaction (prism, lever knob, dial pointers) | Deep red |

### 4.6 Sound Palette (Designed Acoustic Events)

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
| Full convergence | sustained rolling silence | Loss → near zero, minimal motion |

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

### 5.2 Backward Pass (7 ticks, TRAIN mode only)

**Training method: Perturbation-based learning.** Rather than computing exact gradients (which requires mechanical differentiation), the machine uses a simpler but proven approach: wiggle each weight slightly, measure whether loss improved, adjust accordingly.

11. **Tick 11**: Whippletree computes loss — predicted output vs. target from pin drum. Each of the 3 output neurons connects a string to one side of its whippletree beam. The target (from pin strip) connects to the other side. Beam tilt = per-neuron error. Cascaded beams sum into total loss.
12. **Tick 12**: Loss displacement drives brachistochrone ball release. Ball rolls down cycloid track to a spring-loaded catch gate. Gate position is set by the scissor amplifier (5x loss magnitude). Ball stops at gate — viewer reads loss as ball position. Return mechanism: after reading, a lever tips the track, ball rolls back to start via gravity return channel on the underside.
13. **Tick 13**: Barrel cam sequences through weight groups (6 at a time). For each group: worm gear advances one micro-step (perturbation). Forward pass re-evaluates (fast — pantographs settle in <0.5 tick). Whippletree re-measures loss.
14. **Tick 14**: If loss decreased: keep the micro-step (worm stays). If loss increased: reverse the micro-step (worm backs up one click). Direction encoded by a ratchet pawl that flips based on whippletree tilt direction.
15. **Tick 15**: Next weight group engages. Repeat ticks 13-14 for all 7 groups (42 weights / 6 per group = 7 groups). In practice, groups overlap with barrel cam sequencing — effective time ~4 ticks for all 42 weights.
16. **Tick 16**: Pin drum indexes to next example (star-wheel ratchet advance)
17. **Tick 17**: Shishi-odoshi striker fires — TOCK — example complete

**Why perturbation over true backprop**: True backpropagation requires computing derivatives mechanically (shaped cam in reverse). This is possible but fragile — cam follower direction reversal introduces backlash. Perturbation is slower (evaluates each weight independently) but robust: it only requires measuring "did loss go up or down?" — a binary decision the whippletree handles naturally. Convergence is slower (~30 epochs vs. ~15 for backprop) but mechanically reliable.

### 5.3 Timing Budget

- 1 tick = ~0.7 seconds (pendulum period at 250mm length)
- 1 training example = 17 ticks = ~12 seconds
- 1 epoch (8 examples) = ~96 seconds (~1.5 minutes)
- 30 epochs to convergence (perturbation is slower) = ~48 minutes
- Total pins/drums: 8 strips x 12 pins each (9 input bits + 3 target bits)

---

## 6. Dimensions & Tolerances

### 6.1 Envelope

- **Width**: 600mm (front face — weight matrix)
- **Height**: 400mm (frame) + 60mm (pin drum above) = 460mm total. Pendulum (250mm) hangs inside the frame from the back top rail — does not extend beyond envelope.
- **Depth**: 300mm
- **Weight estimate**: 4-6 kg
- **Pedestal/base**: Not included in envelope — separate museum-style mount

### 6.2 Key Component Dimensions

| Component | Count | Size (mm) | Material |
|-----------|-------|-----------|----------|
| Worm gear assembly | 42 | 24dia x 20 | Brass + steel |
| Pantograph diamond | 9 (3x3) | 70 x 40 (expanded) | Brass bars |
| Shaped cam | 6 | 36dia x 10 | Brass |
| Input dial | 3 | 44dia x 15 | Brass |
| Answer prism | 1 | 50dia x 40 | Red PLA/resin |
| Pin drum | 1 | 70dia x 360 | Brass |
| Gravity pendulum | 1 | 250 long, 30dia bob | Brass + steel rod |
| Barrel cam | 1 | 40dia x 60 | Dark brass |
| NEMA 17 motor | 1 | 42 x 42 x 48 | Stock |
| Whippletree beams | 5 | 80-200 x 4 x 8 | Brass |
| Spring toggles | 6 | ~20 x 10 | Steel spring |
| String pulleys | 12 | 12dia | Brass |
| Frame edges | 12 | 8 x 8 x varies | Black PLA |
| Acrylic panels | 3 | varies x 3 thick | Clear |

### 6.3 Tolerances

- General: 0.2mm
- Sliding fits (cam followers, pantograph joints): 0.3mm
- Press fits (bearings, shafts): 0.1mm
- Minimum feature size: 1.5mm (3D print constraint)
- String: Braided brass wire, 0.5mm dia

---

## 7. Build Sequence

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

### Phase 6: Backward Pass
Add whippletree, brachistochrone track, error routing, weight update mechanism. Validate one training example converges.

### Phase 7: Automation
Add pin drum, barrel cam sequencer, gravity pendulum timing. Validate full autonomous training loop.

### Phase 8: Polish
Acrylic panels, brass plaques, sound tuning, string tensioning, museum finish.

---

## 8. Mechanism Heritage

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
| Shishi-odoshi | Japanese garden design | Traditional |

**Design philosophy**: Every mechanism in this machine was invented before the transistor. The machine proves that intelligence can emerge from brass, steel, and string — no electricity required in the computation path.

---

## 9. Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Pantograph friction prevents convergence | High | Knife-edge pivots, PTFE bushings, validate Phase 2 early |
| String stretch/creep over 40 min training | Medium | Braided brass wire (low creep), tension springs at endpoints |
| Worm gear backlash accumulates error | Medium | Anti-backlash split gears, validate Phase 3 |
| 42 weights too many for single motor torque | High | Staged engagement (barrel cam activates 6 at a time, not 42) |
| Shaped cam profile precision insufficient | Medium | CNC mill cam blanks (don't 3D print activation functions) |
| Pendulum timing drifts with temperature | Low | Steel pendulum rod (low thermal expansion), not critical for training |
| Sound palette too quiet in gallery setting | Low | Resonance chambers under brass plaques, tuned striker materials |
| Perturbation learning fails to converge with mechanical noise | High | Run Python simulation with +/-5%, 10%, 20% noise on weight updates before building. If >10% noise kills convergence, tighten tolerances or reduce network size |
| Backward pass mechanism unproven | High | Phase 2 must validate perturbation loop on single neuron before scaling |

---

## 10. Success Criteria

1. **Convergence**: Machine reaches >80% accuracy on training set within 30 epochs (~48 minutes)
2. **Generalization**: On held-out examples (new pin strips), accuracy >60%
3. **Visibility**: A non-technical viewer can identify "something is being computed" within 30 seconds
4. **Interaction**: User can switch to PREDICT, turn dials, and receive an answer in <10 seconds
5. **Sound**: All 10 acoustic events are audible and distinct at 1 meter distance
6. **Durability**: Machine completes 100 training runs without mechanical failure
7. **Beauty**: The machine looks like a musical instrument, not a gearbox

---

## 11. Visual Reference

Interactive HTML companion at:
`.superpowers/brainstorm/physical-transformer/`

- `01-architecture.html` — Six faces diagram, operation mapping
- `02-network.html` — Neural network topology, one-hot encoding, weight grid
- `03-mechanisms.html` — All 7 core mechanisms with SVG diagrams
- `04-signal-flow.html` — Complete signal path, timing budget
- `05-dimensions.html` — Component table, tolerance budget, build sequence
- `06-3d-explorer.html` — Interactive Three.js 3D model (orbit, zoom, preset views)

---

## 12. Open Items for Implementation Planning (Priority Order)

1. **Motor torque budget** — sum all mechanism loads, verify NEMA 17 suffices. GO/NO-GO GATE.
2. **Convergence simulation** — Python model of 3x3x3 network with perturbation learning + noise injection at 5/10/20% levels. Validates that the machine CAN learn.
3. **Pantograph linkage lengths** — kinematic analysis for target displacement range. Validate that 3 diamonds sum 4 terms with <2% error.
4. **Exact gear module and tooth count** for worm gears (self-locking verification)
5. **Shaped cam profile equations** — convert ReLU to polar coordinates for CNC
6. **String routing diagram** — exact pulley positions for all 21 lines, max 2 redirections per line
7. **Barrel cam groove profile** — 17-tick timing sequence encoded as a 3D spiral
8. **Pin drum pin spacing** — 9 input bits + 3 target bits x 8 examples = 96 pin positions
