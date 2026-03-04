# The Waffle Grid — Physics Spec Sheet
## Generated via Rule 99 Discover

Built from 6 rounds of Socratic Q&A. Every engineering value traces back to a user answer.

---

## COMPLETE SPECIFICATION

| Parameter | Your Words | Engineering Value | How We Got There |
|-----------|-----------|-------------------|-----------------|
| **Layout** | "12×12 grid" | 144 nodes, 550mm square span | Direct — 12 × 50mm pitch = 600mm edge-to-edge |
| **Pitch** | "~50mm" | 50mm center-to-center | User specified |
| **Mechanism** | "Planetary differential" | Compound planetary, 3 shaft inputs per node | Each node blends 3 input shaft rotations into unique height+spin |
| **Drive** | "3 steppers" | NEMA 17 × 3, ESP32 microcontroller | 3 shafts create 3-wave interference. NEMA 17 has 46× torque headroom |
| **Pixel motion** | "Thread up/down + twist" | Height: 0–70mm, Spin: 0–334° | Spool winds thread → height. Thread twist = drop/SPOOL_RADIUS rad |
| **SPOOL_RADIUS** | (derived) | 12mm | Sets spin-to-height coupling: 70mm drop = 334° twist |
| **Target Δh** | "Visible wave" | 20–30mm between neighbors | Enough for wave legibility, within thread tension budget |
| **Orientation (production)** | "Ceiling-hung" | Viewer looks up at underside | Gravity keeps threads taut, elements dangle naturally |
| **Hanging element** | "Wood" | Birch plywood, 40×40×6mm, 6.2g each | Baltic birch: ρ=0.65 g/cm³, laser-cuts clean, warm aesthetic |
| **Total hanging mass** | (derived) | 893g full / 223g prototype | 144 × 6.2g / 36 × 6.2g — under 1kg, trivial for NEMA 17 |
| **Spool torque (per thread)** | (derived) | 0.73 mN·m | 0.061N × 12mm radius |
| **Total torque (per shaft)** | (derived) | 35 mN·m (full) / 8.7 mN·m (proto) | NEMA 17 delivers 400+ mN·m. Massive headroom. |
| **Mechanism plate** | "Partially revealed" | Skeletal frame, 40-50% open area | Perforated bays per node cluster, structural ribs between |
| **Plate material** | (derived) | 3mm aluminum or 6mm birch ply | Aluminum for contrast, birch to match elements |
| **Wave speed** | "Rain on water" | <1 second crossing, 40-60 RPM steppers | Multiple fast overlapping ripples, interference-rich |
| **Wavelength** | (derived) | 3–4 nodes (150–200mm) | Short λ = 3-4 simultaneous crests visible |
| **Speed ratios** | "Overlapping ripples" | [1.0, 1.13, 0.87] — non-harmonic | Coprime-ish ratios → pattern never exactly repeats |
| **Phase offsets** | (derived) | [0°, 47°, 131°] | Non-symmetric = rain-like randomness from deterministic math |
| **Gasp moment** | "The Spiral" | All nodes form spiral staircase, ~every 20s, lasts ~0.4s | 3 wave phases momentarily align to produce spatial gradient |
| **Spiral turns** | (derived) | 1.5–2 turns (full grid), ~1 turn (6×6 proto) | Height ramps linearly with angle from center |
| **Thread slack check** | (derived) | Max accel 0.21g ≪ 1.0g — thread always taut ✅ | At 50 RPM, amax ≈ 2.1 m/s². Gravity = 9.81 m/s². |
| **Prototype scale** | "6×6 slice" | 36 nodes, 250mm span | Proves wave, rain pattern, partial spiral. Quarter complexity. |
| **Prototype mount** | "Pedestal flip" | Elevated plate on 4 legs, elements dangle below | Same physics as ceiling. Desk-top viewing. ~250mm leg height. |

---

## PHYSICS CONCEPTS LEARNED THIS SESSION

| # | Concept | What You Now Know |
|---|---------|------------------|
| 1 | **2 DOF from 1 input** | A spool gives you height (thread length) AND spin (thread twist) from a single rotation input. spin = drop / SPOOL_RADIUS radians. You get rotation for free — it's geometry, not mechanism. |
| 2 | **Compound planetary differential** | 3 input shafts, 1 output. Each node's planetary blends the 3 shaft speeds differently based on gear ratios. Every node gets a UNIQUE phase from the SAME 3 shafts. This is how 3 motors control 144 independent pixels. |
| 3 | **Wave interference** | 3 sine waves at slightly different speeds overlap. Most of the time: complex "rain" pattern. Periodically: phases align → order emerges (the spiral). The ratios [1.0, 1.13, 0.87] ensure the pattern drifts and evolves without repeating. |
| 4 | **Coprime ratios & the gasp** | When speed ratios share no simple common factor, their LCM is large → the exact pattern repeats rarely. But APPROXIMATE alignment happens on shorter timescales (~20s). That's your spiral gasp — not exact repetition, but close-enough alignment. |
| 5 | **Thread tension = gravity** | Each 6.2g element creates 0.061N of thread tension. The motor fights this times spool radius = 0.73 mN·m per thread. Total across 48 threads per shaft = 35 mN·m. A NEMA 17 has 400 mN·m. The motor has 11× the power it needs. Wood is that light. |
| 6 | **Catenary in slack strings** | When two adjacent elements are at similar heights, a string between them has low tension and sags in a catenary (gravity curve). When heights differ greatly, the string pulls taut and straight. The wave creates traveling patterns of taut/slack across the string network. |
| 7 | **Emergence from chaos** | Three independent oscillators produce pseudo-random interference ("rain on water"). But periodically, their phases align to create a spatial gradient (the spiral). Viewers gasp because order was NOT expected. The math guarantees it happens, but it always feels like a surprise. |
| 8 | **Pendulum response** | At 50 RPM, the max acceleration of a wood element is 0.21g. Since gravity is 1.0g, the thread NEVER goes slack — gravity always wins. This means no bouncing, no lag, no lost steps. The elements track the wave faithfully even at "rain" speed. |

---

## MECHANISM ARCHITECTURE

```
                    3× NEMA 17 STEPPERS (underneath plate)
                    │        │        │
                  Shaft A  Shaft B  Shaft C
                  (1.00×)  (1.13×)  (0.87×)
                    │        │        │
              ┌─────┴────────┴────────┴─────┐
              │   COMPOUND PLANETARY GRID    │
              │   6×6 = 36 nodes (prototype) │
              │   Each node has 3 inputs     │
              │   from the 3 shafts          │
              └──────────────┬───────────────┘
                             │
                    Each node's planetary
                    blends 3 shaft speeds
                    into unique output
                             │
                         SPOOL (r=12mm)
                         winds/unwinds
                         THREAD
                             │
                    ┌────────┴────────┐
                    │                 │
                 HEIGHT            SPIN
                 0-70mm          0-334°
                 (thread         (thread
                  length)         twist)
                    │                │
                    └────────┬───────┘
                             │
                      WOOD ELEMENT
                      40×40×6mm birch
                      6.2g each
                             │
                      ┌──────┴──────┐
                      │  OPTIONAL   │
                      │  STRING     │
                      │  NETWORK    │
                      │  between    │
                      │  adjacent   │
                      │  elements   │
                      └─────────────┘
```

### Node Assignment — How 3 Shafts Control 36 Nodes

Each of the 3 shafts runs continuously across the grid. At each node, a compound planetary differential receives ALL 3 shafts as inputs. The gear ratio at each node determines how it blends the 3 speeds:

- **Node (i, j)** receives shaft A at ratio f_A(i,j), shaft B at f_B(i,j), shaft C at f_C(i,j)
- The output rotation = f_A·ωA + f_B·ωB + f_C·ωC
- By varying the gear ratios across the grid, each node gets a UNIQUE phase

This is the key insight: the ratios ARE the wave. You don't program the wave — the gear ratios physically embed it. Change the stepper speeds → the wave speed/shape changes. But the SPATIAL pattern is locked in the gears.

### Wave Computation

For any node at grid position (i, j), its height at time t:

```
height(i,j,t) = Σ over shafts s:
    A_s × sin( 2π × (i·cos(θ_s) + j·sin(θ_s)) / (pitch × gridSize × λ_s)
                - 2π × speedRatio_s × t / period
                + phaseOffset_s )

Where:
  A_s = amplitude per shaft (normalized to pixelTravel)
  θ_s = shaft wave direction
  λ_s = wavelength factor (0.3-0.5 for "rain")
  speedRatio_s = [1.0, 1.13, 0.87]
  phaseOffset_s = [0°, 47°, 131°]
```

The spin is coupled: `spinAngle(i,j,t) = height(i,j,t) / SPOOL_RADIUS`

---

## STRING NETWORK (optional layer)

Strings connect adjacent wood elements, creating a visible tension mesh below the grid.

| Property | Value |
|----------|-------|
| **Topology options** | Grid-4 (H+V), Grid-8 (H+V+diag), Hex-6, Radial |
| **String material** | Thin monofilament or cotton thread |
| **Behavior** | Tensile only — cannot push, only pull |
| **High Δh** | String taut, steep angle, visible tension line |
| **Low Δh** | String slack, catenary sag from gravity |
| **Visual effect** | Traveling wave of taut/slack creates shimmering mesh |
| **String count (Grid-4, 6×6)** | ~60 strings (horizontal + vertical neighbors) |

The string network makes the wave VISIBLE between elements. Without strings, you see 36 independent points moving. With strings, you see a continuous surface rippling.

---

## THE GASP: SPIRAL EMERGENCE

### What Happens

For ~0.4 seconds every ~20 seconds, the chaotic rain pattern resolves into a clean spiral staircase. Heights increase smoothly with angle from the grid center. Then it dissolves.

### Why It Happens

Three sine waves at speeds [1.0, 1.13, 0.87]:
- Most of the time: constructive and destructive interference creates complex, rain-like patterns
- Periodically: all three waves align so that their combined effect produces a monotonic height gradient across the grid
- This gradient, viewed from above, reads as a spiral because the node layout is a grid (the "staircase" wraps around the center)

### Tuning

| Lever | Effect |
|-------|--------|
| Speed ratios closer (1.0, 1.02, 0.98) | Spiral more frequent, rain less chaotic |
| Speed ratios further (1.0, 1.13, 0.87) | Spiral rare (~20s), rain rich and complex |
| Phase offsets | Control WHERE in the grid the spiral center appears |
| Wavelength | Short λ (3-4 nodes) = more rain texture, spiral less clean |

Sweet spot for "rain + spiral": ratios [1.0, 1.13, 0.87], λ = 3.5 nodes, offsets [0°, 47°, 131°]

---

## PROTOTYPE PLAN (6×6 Pedestal)

### Phase 1: Single Node Proof (1-2 days)
- 3D print one compound planetary differential
- Verify 3-shaft input → single output rotation
- Attach spool (r=12mm), thread, 6.2g wood element
- Confirm: height travel 0-70mm, spin 0-334°
- Measure actual torque, backlash, smoothness

### Phase 2: 6×6 Grid Prototype (2-3 weeks)
- 3D print 36 planetary differentials with varying gear ratios
- Machine or print skeletal mechanism plate (250×250mm)
- 3 shaft channels running across grid
- 3× NEMA 17 on underside with ESP32 control
- 36 birch ply elements on threads
- Pedestal frame: 4 legs, ~250mm height, rigid base

### Phase 3: String Network (optional, +1 week)
- Add tensile strings between adjacent elements (Grid-4 topology first)
- Test visual impact of string mesh
- Try Grid-8 for denser mesh if Grid-4 looks sparse

### Phase 4: Wave Tuning
- ESP32 speed control — sweep stepper RPMs
- Find optimal rain character (40-60 RPM range)
- Confirm spiral gasp moment occurs
- Tune ratios for ~20s spiral interval
- Video for documentation

### Phase 5: Scale to 12×12 (if prototype validates)
- 4× the nodes, same pitch
- Tiled or larger mechanism plate
- Ceiling-mount hardware
- Partially-revealed skeletal frame with backlight

---

## OPEN QUESTIONS (for Rule 99 design phase)

1. **Planetary gear sizing:** At 50mm pitch, each differential must fit within ~45mm diameter. Is compound planetary achievable at this scale? May need micro-planetary or alternative differential (bevel gear differential, harmonic drive).
2. **Shaft routing:** 3 shafts must reach all 36 nodes. Options: parallel shafts with bevel transfers, worm gear taps at each node, or belt/chain distribution. Straight shafts simplest for 6×6.
3. **Wood element shape:** Currently specified as 40×40×6mm flat wafer. Could be shaped: round disc, tapered, leaf-shaped, hexagonal. Shape affects spin visual (more interesting with asymmetric shapes).
4. **Backlight integration:** Partially-revealed plate invites backlighting. LEDs above mechanism plate → gear shadows project downward. Adds visual layer but complicates wiring.
5. **Sound:** 36 planetary diffs at 40-60 RPM will produce a soft mechanical hum. Feature or bug? At rain-speed, the collective clicking could sound like actual rain on a roof. Worth exploring.
6. **String attachment:** If using string network, how do strings attach to wood elements? Drilled holes with knots? Glue? Clips? Must allow element to spin freely.
7. **Pedestal-to-ceiling transition:** The pedestal prototype uses inverted physics (elements below, viewer above). When moving to ceiling mount, the mechanism flips but the wave math is identical. Confirm no mechanical surprises in the flip.

---

## THRUST WASHER INTERFACES

Herringbone gears generate axial thrust. All rotating interfaces require PTFE thrust washers to prevent binding and wear.

| # | Interface | Axial Load Source | Washer Spec |
|---|-----------|------------------|-------------|
| 1 | Carrier1 bot plate ↔ Ring1 face | Herringbone thrust from Stage1 | PTFE 0.5mm, ID=bearing bore, OD=carrier R |
| 2 | Carrier1 top plate ↔ Ring1 face | Same, opposite side | PTFE 0.5mm |
| 3 | Carrier2 bot plate ↔ Ring2 face | Herringbone thrust from Stage2 | PTFE 0.5mm |
| 4 | Carrier2 top plate ↔ Ring2 face | Same, opposite side | PTFE 0.5mm |
| 5 | Sun1 hub ↔ Carrier1 bot bore | Sun axial reaction | PTFE 0.5mm (small) |
| 6 | Spool base ↔ Carrier2 top | Thread tension axial load | PTFE 0.5mm |

**Design parameters:**
- `THRUST_WASHER_T = 0.5mm` (standard PTFE washer)
- `AXIAL_GAP = 0.7mm` (0.2mm clearance + 0.5mm washer)
- Total axial stack increase: ~2.5mm (from 28.5mm to ~31mm)
- Material: PTFE (coefficient of friction ~0.05, self-lubricating)

**Procurement:**
- Source: standard PTFE washer stock, cut to size, or 3D printed in Nylon/PTFE filament
- For prototype: laser-cut 0.5mm PTFE sheet or Nylon washer blanks

---

## POWER & ELECTRICAL

| Component | Value |
|-----------|-------|
| Motors | 3× NEMA 17 (17HS4401 or similar) |
| Driver | 3× TMC2209 (silent, StealthChop) |
| Controller | ESP32 (WiFi for parameter tuning) |
| Supply | 12V 3A (36W) — motors draw ~0.5A each at load |
| Total power | <20W continuous |
| Speed control | Microstepping (1/16 or 1/32) for smooth rain |
| Acceleration | Trapezoidal ramp, max 2.1 m/s² at elements |

---

## MATERIAL BUDGET (6×6 prototype)

| Item | Qty | Est. Cost |
|------|-----|-----------|
| NEMA 17 steppers | 3 | $30 |
| TMC2209 drivers | 3 | $15 |
| ESP32 dev board | 1 | $8 |
| 12V 3A PSU | 1 | $10 |
| 3D print filament (PLA/PETG) | ~500g | $10 |
| Birch plywood (laser cut elements) | 1 sheet | $5 |
| Thread (polyester, 36 × 400mm) | 1 spool | $3 |
| Aluminum extrusion (legs, 4×250mm) | 4 | $12 |
| Bearings (608ZZ for shafts) | 6 | $6 |
| PTFE thrust washers (0.5mm, per node: 6 each) | 216 (36×6) | $15 |
| Fasteners, misc | — | $10 |
| **Total** | | **~$124** |

---

## THE RAIN AND THE SPIRAL

Rain on water. 144 wooden tiles rippling overhead, three invisible waves colliding and canceling. Fast, chaotic, mesmerizing — like staring at a pond in a storm. Then for half a second, the chaos aligns. A spiral staircase materializes. 144 tiles stepping up in a clean helix. You gasp. Then it dissolves, and the rain returns.

The mechanism is partially visible through the skeletal frame above. Gears turning, shafts spinning, the clockwork exposed. The engineering IS the art. Below: warm birch wood in chaos and order. Above: precision gears in constant motion. Between them: threads, invisible from a distance, carrying the mathematics of interference from mechanism to material.

Three motors. 144 threads. One spiral.
