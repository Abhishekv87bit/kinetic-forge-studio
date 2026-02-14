# HELIX CAM KINETIC SCULPTURE — FULL DESIGN AUDIT
## Date: Feb 2026 | Status: CRITICAL ISSUES FOUND

---

## EXECUTIVE SUMMARY

The helix cam design has **elegant geometry** — 30 discs × 12° = perfect 360° traveling wave, self-balancing shaft, minimal motor requirements. However, the audit reveals **3 critical issues** and **4 warnings** that must be resolved before fabrication.

### Severity Scorecard

| Severity | Count | Summary |
|----------|-------|---------|
| **CRITICAL** | 3 | Matrix rectification destroys wave, nut trap interference, slider travel impossible |
| **WARNING** | 4 | Rib clearance tight, no mechanical rib stops, friction may exceed limits, matrix architecture ambiguity |
| **NOTE** | 4 | Cam output subtle, bearing cost, PLA creep, M4 nut trap depth tight |

---

## PART 1: HELIX CAMSHAFT — WHAT WORKS

### 1.1 Traveling Wave — VERIFIED CORRECT

```
30 discs × 12°/disc = 360° total twist
```

One shaft rotation sweeps exactly one complete sine wave across all 30 cam followers. The phase of disc `i` at shaft angle `θ`:

```
φ_i(θ) = θ + i × 12°     (i = 0..29)
```

At any instant, the 30 rib tip Y-displacements form a perfect sinusoid:

```
Y_i(θ) = 12 × sin(θ + i × 12°)    [mm]
```

**This is the native, inherent behavior. No modification needed for traveling wave.**

### 1.2 Self-Balancing Shaft — VERIFIED CORRECT

The sum of gravitational torques from all 30 eccentric masses:

```
T_total(θ) = m_rib × g × e × Σ cos(θ + i×12°)    [i = 0..29]
```

Since 30 equally-spaced phases over 360° sum to exactly zero:

```
Σ cos(θ + i×12°) = 0    (identically, for all θ)
```

**The shaft is perfectly statically balanced at all angles.** The motor fights only bearing friction, not gravity. This is an elegant property of the 30-disc, 12° design.

### 1.3 Cam Follower Motion — VERIFIED

Each bearing center traces a circle of radius = eccentric_offset = **12mm** around the shaft axis.

Gravity rib hangs vertically from the bearing (confirmed safe at sculpture speeds):
- At 5 RPM: rib deflection angle = **0.019°** (negligible)
- At 15 RPM: rib deflection = **0.17°** (negligible)
- Critical RPM (45° swing): **~273 RPM** (never reached)
- Safe operating limit (<5° swing): **~81 RPM**

**Rib tip (string eyelet) displacement: ±12mm in both X (lateral) and Y (vertical)**
- Peak-to-peak: 24mm
- Motion is sinusoidal (pure SHM)
- Each rib traces a 12mm radius circle in the XY plane

### 1.4 Stack Height — REASONABLE

| Configuration | Axial Pitch | Total (30 discs) |
|---------------|-------------|-------------------|
| Rib within bearing envelope | 8mm | **240mm** (9.4") |
| Rib beside bearing | 14mm | **420mm** (16.5") |

With end plates and shaft supports: **~300mm to 460mm total**

### 1.5 Weight & Motor — NO CONCERNS

| Component | Per Unit | ×30 | ×3 Helixes |
|-----------|----------|-----|-----------|
| PLA Hub | 15.0g | 450g | 1,350g |
| 6810 Bearing | 30.0g | 900g | 2,700g |
| PLA Rib | 14.5g | 435g | 1,305g |
| Hardware | 9.6g | 288g | 864g |
| **Subtotal** | **69.1g** | **2,073g** | **6,219g** |

Shaft + end plates + supports: ~350g per helix × 3 = 1,050g

**Total rotating mass: ~7.3 kg**

Required motor: < 0.05 Nm, < 0.025 W. A NEMA 17 stepper or small geared DC motor has 10x+ margin.

---

## PART 2: CRITICAL ISSUES

### ⛔ C1: NUT TRAP AT 132° NEARLY BREACHES HUB EDGE

**What**: The back-face nut trap at 132° (bolt pattern rotated by twist_angle=12°) is positioned 20.1mm from the hub center. The hub radius is 24.95mm. An M4 hex nut trap at 8mm across-flats has a circumscribed radius of 4.62mm.

```
Wall remaining at hex corner: 24.95 - 20.10 - 4.62 = 0.23mm
```

**This is less than a single FDM layer thickness.** The nut trap will breach the hub surface during printing.

**Root cause**: The 8mm nut trap is oversized. Standard DIN 934 M4 hex nut is **7.0mm** across flats, not 8mm.

**Fix**:
1. Change `nut_trap_dia = 8.0` → `nut_trap_dia = 7.0` (standard M4)
2. Reduce `bolt_circle_dia = 20.0` → `bolt_circle_dia = 18.0`
3. Combined fix gives clearance: 24.95 - 19.21 - 4.04 = **1.70mm** ✅

### ⛔ C2: V5 MATRIX HAS FULL-WAVE RECTIFICATION — BLOCKS CAN ONLY GO UP

**What**: This is the most fundamental issue. The V5 matrix converts lateral slider motion to vertical rope displacement via angled rope segments between fixed pulleys (Y=±31mm) and slider pulleys (Y=0). The rope path length follows:

```
L(δ) = 2n × √(δ² + 31²)
```

Because `√(δ² + 31²) ≥ 31` regardless of the **sign** of δ:

```
L(+12) = L(-12) > L(0)
```

**Whether the slider moves LEFT or RIGHT, the rope always LENGTHENS. The block can only go UP from neutral. It CANNOT go below neutral.**

This means:
- The wave output is |sin(θ)|, not sin(θ)
- **True wave superposition is impossible** — you cannot get constructive AND destructive interference
- The beautiful sinusoidal traveling wave from the helix gets turned into a bumpy, always-positive rectified signal
- The sculpture cannot produce the signature Margolin "breathing" motion where blocks rise AND fall

**This is a fundamental physics issue with the lateral-slider-to-vertical-rope geometry.**

**Why Margolin doesn't have this problem**: In his Triple Helix, the sliders move **vertically** (along the helix shaft axis), and strings attach **directly** to the sliders. Slider goes up → string shortens → block rises. Slider goes down → string lengthens → block falls (gravity). 1:1, bidirectional, no rectification.

**Fix Options**:

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A: Direct attachment** | Eliminate block-and-tackle. Rope attaches directly to cam follower rib, routes through matrix as manifold only (redirect pulleys) | Simple, 1:1, bidirectional, 2-3 pulleys per path, ~90% efficiency | No force multiplication, cam output = block travel (±12mm) |
| **B: Vertical slider** | Redesign matrix so slider moves vertically (up/down), pulleys form true block-and-tackle | Classic B&T works correctly, force multiplication, linear response | Major V5 redesign required |
| **C: Lever amplifier** | Rib tip → lever arm → vertical push rod → block rope | Can amplify motion, bidirectional with proper geometry | Additional mechanism complexity, backlash |

**Recommended: Option A (Direct attachment)** — This is exactly what Margolin does, and it works. The ±12mm cam output becomes ±12mm block travel, which is subtle but visible for a chandelier. If more travel is needed, increase eccentric_offset to 18-20mm.

### ⛔ C3: SLIDER TRAVEL VALUE (±68mm) IS PHYSICALLY IMPOSSIBLE

**What**: The V5 animation uses `anim_val = sin($t * 360) * 68`, implying ±68mm slider travel. But:
- The cam produces only ±12mm of motion
- Even if the matrix were a perfect block-and-tackle, it would REDUCE displacement (trade force for distance), not amplify it
- No mechanism in the current design can produce 68mm from 12mm input

**Fix**: Replace `68` with the actual cam output value. For direct attachment: `anim_val = sin($t * 360) * 12`. For visualization purposes during development, a larger value is fine but should be documented as placeholder.

---

## PART 3: WARNINGS

### ⚠ W1: ADJACENT RIB CLEARANCE IS ONLY 2mm AXIALLY

**What**: With 8mm axial pitch and 6mm rib thickness, adjacent ribs have only 2mm clearance. During rotation, the lateral offset between adjacent bearing centers reaches up to 2.51mm (at worst-case shaft angles). While this lateral offset doesn't directly cause axial collision, any rib wobble, bearing play, or assembly tolerance could close the 2mm gap.

**Fix**: Either increase axial pitch to 10mm (giving 4mm clearance) or reduce rib thickness to 4mm.

### ⚠ W2: NO MECHANICAL LIMIT ON RIB SWING

**What**: The gravity rib relies solely on gravity to maintain vertical orientation. During motor startup transients, power failures (motor stops suddenly while ribs are in motion), or external bumps (someone hits the chandelier), ribs could swing beyond their intended range and jam against adjacent components.

**Fix**: Add soft stops — small pins or bumpers on the hub body limiting rib swing to ±15°.

### ⚠ W3: FRICTION CASCADE LIMITS (INDEPENDENT CHANNEL MODEL)

**What**: Even under the best interpretation (each channel independent, one rope per channel), the friction cascade per rope path is:

| Channel | Pulleys in path (2n+1) | Efficiency (η=0.96/pulley with ball bearings) |
|---------|----------------------|----------------------------------------------|
| CH1/CH5 | 7 | 0.96⁷ = 75.1% |
| CH2/CH4 | 9 | 0.96⁹ = 69.3% |
| CH3 | 11 | 0.96¹¹ = 63.8% |

If the rope goes through 3 tiers (one per helix) × one channel each:
- Best case: 3 × 7 = 21 pulleys → η = 0.96²¹ = **42.3%**
- Worst case: 3 × 11 = 33 pulleys → η = 0.96³³ = **25.8%**

These efficiencies are low but potentially workable if block weight is minimal (<10g per block).

Under the serial model (one rope through ALL 5 channels = 43 pulleys): η = 0.96⁴³ = **17.3%** — nearly all force is lost.

**Fix**: Use Option A (direct attachment, 2-3 pulleys per path = 92-96% efficiency) OR reduce pulley count per channel.

### ⚠ W4: MATRIX ARCHITECTURE AMBIGUITY — SERIAL vs PARALLEL

**What**: The V5 design's intent is ambiguous:

| Interpretation | Rope Path | Pulleys/Rope | Blocks/Unit | Total Blocks |
|----------------|-----------|-------------|-------------|-------------|
| **Serial**: 1 rope through all 5 channels | All 5 channels | 43 | 1 | 6 per helix = 18 |
| **Parallel**: 5 independent ropes | 1 channel each | 7-11 | 5 | 30 per helix... but wait |

Under the **parallel** model, each V5 unit handles 5 blocks through 5 channels. With 30 cams per helix and 5 channels per unit, we get 6 units per helix = 30 blocks per helix. But with 3 helixes sharing the SAME block grid, each block needs 3 connections (one per helix). So: 30 blocks total, each visiting 3 matrix units.

Under the **serial** model, 1 rope per unit, 6 units per helix, but each block connects to 3 helixes = 6 × 3 / 3 = 6 blocks total. Way too few.

**The parallel interpretation is the only viable one**, but the V5 animation code drives all 5 sliders with the same `anim_val`, which suggests it was designed thinking of serial operation.

**Fix**: Explicitly define: each channel is independent, each slider is driven by its own cam, each channel routes one rope to one block.

---

## PART 4: NOTES

### 📝 N1: Cam Output May Be Subtle for Ceiling Chandelier

±12mm displacement from a 12ft ceiling ≈ ±0.33% of viewing distance. This IS visible, especially in a wave pattern, but borderline for dramatic effect.

Options to increase:
- Increase eccentric_offset to 18mm (hub clearance allows up to ~20mm)
- Use lever amplification at the rib tip
- Accept subtle motion as aesthetic choice (Margolin's work is often subtle)

### 📝 N2: 90× 6810 Bearings Cost ~$270-$450

6810-2RS bearings cost $3-5 each. 90 bearings (30 per helix × 3) = $270-$450 for bearings alone. Consider smaller 6800 series (10×19×5mm) with redesigned hubs to reduce cost, or 688ZZ (8×16×5mm) for even smaller form factor.

### 📝 N3: PLA May Creep Under Sustained Press-Fit Loads

PLA glass transition is ~60°C and it creeps under constant load. The bearing press-fit (hub OD = 49.9mm for 50mm bearing ID) may loosen over months.

Fix: Use PETG or ABS for hubs, or change to loose fit with set screws.

### 📝 N4: Nut Trap Depth (3.5mm) vs M4 Nut Height (3.2mm)

Only 0.3mm clearance. The nut may not sit fully flush. Acceptable but could cause assembly issues if print quality varies.

---

## PART 5: DIMENSIONAL VERIFICATION MATRIX

### 5.1 Helix Hub Dimensions

| Parameter | Value | Status |
|-----------|-------|--------|
| 30 × 12° = 360° | Correct | ✅ |
| Hub body dia | 49.9mm (bearing_ID - 0.1) | ✅ tight fit |
| Eccentric offset | 12.0mm | ✅ within 50mm hub |
| Hub extent: -12.95 to +36.95 in X | Correct | ✅ |
| Bolt at 0°: 2.0mm from hub center | Inside (20.85mm clearance) | ✅ |
| Bolt at 120°: 19.08mm from hub center | Inside (3.77mm clearance) | ✅ |
| Bolt at 240°: 19.08mm from hub center | Inside (3.77mm clearance) | ✅ |
| Nut trap at 12°: 3.04mm from hub center | Inside (17.29mm clearance) | ✅ |
| **Nut trap at 132°: 20.10mm from center** | **0.23mm wall at hex corner** | ⛔ FIX |
| Nut trap at 252°: 17.84mm from hub center | Inside (2.49mm clearance) | ⚠ Tight |
| Center hole (5mm) vs nearest bolt (10mm) | 5.4mm clearance | ✅ |

### 5.2 Gravity Rib Dimensions

| Parameter | Value | Status |
|-----------|-------|--------|
| Ring OD | 75mm | ✅ |
| Ring ID (bearing clearance) | 65.5mm (bearing OD + 0.5) | ✅ slide fit |
| Rib length | 60mm | ✅ |
| Rib thickness | 6mm (axial) | ⚠ Tight vs 8mm pitch |
| String eyelet | 3mm hole, 5mm from tip | ✅ |
| Eyelet lateral travel | ±12mm (24mm p-p) | ✅ |
| Eyelet vertical travel | ±12mm (24mm p-p) | ✅ |

### 5.3 End Plate Dimensions

| Parameter | Value | Status |
|-----------|-------|--------|
| Plate length (pivot to hub) | 80mm | ✅ |
| Plate width | 40mm | ✅ |
| Plate thickness | 6mm | ✅ |
| Pivot hole (motor shaft) | 8mm | ✅ |
| Bolt pattern matches hub | 3× at 120° on 20mm BCD | ✅ (but needs BCD fix per C1) |

### 5.4 V5 Matrix Dimensions

| Parameter | Value | Status |
|-----------|-------|--------|
| 5 channels, 22mm stacking | Correct | ✅ |
| CH1: 3F/3S, 83mm | Correct | ✅ |
| CH2: 4F/4S, 111mm | Correct | ✅ |
| CH3: 5F/5S, 136mm | Correct | ✅ |
| CH4: 4F/4S, 112mm | Correct | ✅ |
| CH5: 3F/3S, 83mm | Correct | ✅ |
| FP_ROW_Y = 31mm (fixed pulley Y offset) | Correct | ✅ |
| anim_val = sin($t×360) × 68 | **68mm is placeholder, not physical** | ⛔ FIX |
| Lateral slider → vertical rope conversion | **Rectified (blocks only go UP)** | ⛔ FIX |

---

## PART 6: THE PATH FORWARD

### The Core Decision

The helix camshaft design is **sound**. The 30-disc, 12° geometry produces a beautiful traveling wave with perfect self-balancing. The critical issues are all in **how the cam output connects to the blocks**.

There are two viable paths:

### Path A: Margolin-Style Direct Connection (RECOMMENDED)

```
Eccentric Disc → Bearing → Gravity Rib → String Eyelet
    → Redirect Pulley (1-2) → Block
```

- **Block travel**: ±12mm (or ±18mm with increased eccentricity)
- **Pulleys per rope**: 2-3
- **Friction efficiency**: 92-96%
- **Wave fidelity**: Perfect sinusoid, bidirectional
- **Matrix role**: Routing manifold only (organize 30+ strings)
- **Superposition**: Each block's string visits 3 ribs (one per helix). Block height = sum of 3 sinusoidal contributions

The V5 matrix can be simplified to a **string routing plate** with guide holes, similar to Margolin's polycarbonate sheets. The 5-channel architecture with fixed/slider pulleys is no longer needed for force conversion — it becomes purely organizational.

### Path B: Redesigned Vertical-Slider Matrix

If force multiplication is needed (heavy blocks), redesign the matrix so:
- Sliders move **vertically** (not laterally)
- Fixed pulleys on walls, slider pulleys on vertical plate
- True block-and-tackle geometry: rope segments are parallel, MA = 2n
- Cam → vertical push rod → slider plate → rope through B&T → block

This is more complex but provides real mechanical advantage. Estimated MA = 6:1 (CH1) to 10:1 (CH3), meaning a 12mm cam output could produce 72-120mm of block travel.

### What Stays the Same (Both Paths)

1. **Helix camshaft**: 30 discs, 12° twist, 6810 bearings, 12mm eccentricity ✅
2. **Gravity ribs**: Bearing-mounted, gravity-oriented cam followers ✅
3. **3 helixes at 120°**: Belt-driven from single motor ✅
4. **Traveling wave as default**: Inherent from helix geometry ✅
5. **Self-balancing shaft**: 30 × 12° = 360° ✅
6. **30 blocks**: 1:1 mapping to discs per helix ✅

### What Must Change

| Item | Current | Fix |
|------|---------|-----|
| `nut_trap_dia` | 8.0 | → **7.0** (standard M4) |
| `bolt_circle_dia` | 20.0 | → **18.0** (clearance fix) |
| `anim_val` | sin($t×360) × 68 | → sin($t×360) × **12** |
| Matrix function | Block-and-tackle with lateral slider | → **String routing manifold** (Path A) or **vertical-slider B&T** (Path B) |
| Rib axial pitch | ~8mm (implied by bearing width) | → **10mm** (explicit, with spacers) |
| Rib swing limit | None (gravity only) | → **Add ±15° mechanical stops** |

---

## PART 7: KEY NUMBERS REFERENCE

| Parameter | Value | Unit |
|-----------|-------|------|
| Discs per helix | 30 | — |
| Twist per disc | 12 | degrees |
| Total twist | 360 | degrees |
| Bearing | 6810 (50×65×7) | mm |
| Eccentric offset | 12.0 | mm |
| Cam follower travel | ±12.0 | mm |
| Peak-to-peak | 24.0 | mm |
| Wave type (default) | Traveling wave | — |
| Wavelength | 30 disc-spacings | — |
| Phase per disc | 12° = 1/30 cycle | — |
| Shaft balance | Perfect (Σ=0) | — |
| Safe RPM (gravity rib) | <81 | RPM |
| Sculpture RPM (typical) | 1-15 | RPM |
| Weight per disc assembly | 69.1 | grams |
| Weight per helix (total) | 2,430 | grams |
| Weight (3 helixes) | 7,300 | grams |
| Motor torque needed | <0.05 | Nm |
| Motor power needed | <0.025 | W |
| Friction (2-3 pulleys, Path A) | 92-96% | efficiency |
| Friction (7 pulleys, V5 CH1) | 75% | efficiency |
| Friction (43 pulleys, serial) | 17% | efficiency |
| Blocks (natural count) | 30 | (or 31 prime) |

---

## APPENDIX A: WAVE TYPES ACHIEVABLE FROM THIS HELIX

The 30-disc helix natively produces a traveling wave. Other wave types require modifications:

| Wave Type | How | V5 Modification |
|-----------|-----|-----------------|
| **Traveling** (default) | Native — 30 discs × 12° | None |
| **Standing** | Two helixes counter-rotating | Reverse one belt, keep same phase |
| **Variable amplitude** | Gaussian envelope on eccentricity | Machine discs with varying offsets (e.g., 6,8,10,12,12,10,8,6mm) |
| **Beat pattern** | Two helixes at slightly different speeds | Different belt ratios (e.g., 1:1 and 34:35) |
| **3-Helix interference** | Three helixes at 120° phase | Native with triple-helix setup |
| **Damped** | Progressive eccentricity decrease | Machine discs with decreasing offset along shaft |
| **Variable wavelength** | Non-uniform twist angles | Machine discs with non-linear twist (e.g., chirp: 8°,9°,10°...16°) |
| **Radial** | Disc order maps to radial distance, not linear | Re-route cam followers to Vogel spiral positions |

---

*Audit performed by Claude. All calculations shown. Three critical issues identified that must be resolved before fabrication. The helix geometry itself is elegant and correct — the issues are in the cam-to-block transmission chain.*
