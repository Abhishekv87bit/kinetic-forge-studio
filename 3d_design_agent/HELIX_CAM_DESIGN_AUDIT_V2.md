# HELIX CAM KINETIC SCULPTURE — DESIGN AUDIT V2
## Date: Feb 2026 | Status: REVISED WITH MARGOLIN DEEP RESEARCH

---

## WHAT CHANGED FROM V1

V1 of this audit had a critical misunderstanding of how Margolin's lateral sliders create bidirectional block motion. After deep research (photos, videos, website text, interviews, annotated prototypes), the mechanism is now clear. The rectification issue (C2 in V1) was based on a wrong mental model. This V2 replaces V1 entirely.

---

## THE SIMPLE TRUTH (Occam's Razor)

### How Margolin's Triple Helix Actually Works

**One sentence**: Each string makes a sideways U-shaped detour around a slider at each tier; when the slider pushes out, the detour widens and the block rises; when it pulls in, the detour narrows and the block drops.

**The full chain:**

```
String anchored at TOP of matrix
  │
  ↓ (vertical)
  │
  ○ Redirect pulley (nylon roller in stationary matrix)
   ╲
    ╲ (angled approach to slider)
     ╲
      ◉ SLIDER PULLEY ←→ moves laterally (driven by helix via cable)
     ╱
    ╱ (angled departure from slider)
   ╱
  ○ Redirect pulley (nylon roller in stationary matrix)
  │
  ↓ (vertical, to next tier)
  │
  [... repeats for Tier 2 and Tier 3 ...]
  │
  ↓
  █ BLOCK (hangs by gravity)
```

At each tier, the string makes a **U-shaped detour** — it leaves the vertical path, goes sideways to the slider, wraps around the slider pulley, comes back, and continues down.

### Why It's Bidirectional

The slider oscillates around a **baseline offset position**. At rest, it's already pulled out some distance from the string's vertical line, creating a baseline detour.

- Slider moves **further out** → U-detour gets **wider** → more string consumed → block **RISES**
- Slider moves **back in** → U-detour gets **narrower** → string released → block **FALLS** (gravity)

The motion is relative to the baseline, not relative to zero. There is no dead zone, no rectification.

### The Numbers

- **Pulleys per tier**: 3 (1 redirect in + 1 slider + 1 redirect out)
- **Tiers per string**: 3 (one per helix)
- **Total pulleys per string path**: 9
- **Friction**: 0.95⁹ ≈ 63% efficiency (Margolin's stated limit)
- **Minimum block weight**: 40g (to overcome friction on return)
- **Actual block weight**: ~70g (40g basswood + 30g steel shot)

### The Three Tier Orientations

**This is critical and was missing from V1.** The three tiers are NOT stacked with sliders all going the same direction:

- **Tier 1**: Sliders move along **0°** direction
- **Tier 2**: Sliders move along **120°** direction
- **Tier 3**: Sliders move along **240°** direction

Each tier's polycarbonate strips are rotated 120° from the previous tier. Strings pass vertically through all three, but the U-detours at each tier go in different horizontal directions. This matches the three helices at 120° spacing.

Visible in annotated photos:
- `Screenshot 2026-02-10 011702.png`: Video still showing tiers labeled 0°, 120°, 240°
- `Screenshot 2026-02-09 042459.png`: Top-down OpenSCAD view with red/blue/yellow lines at 120°
- `Screenshot 2026-02-10 012645.png`: Overhead photo of actual matrix showing polycarbonate grid at angles

### Wave Superposition

Since each string visits all 3 tiers:

```
Block height = C - k × (detour₁ + detour₂ + detour₃)
            = C - k × [A·sin(θ + φ₁) + A·sin(θ + φ₂) + A·sin(θ + φ₃)]
```

This IS the wave superposition equation, computed mechanically by string geometry.

---

## WHAT THIS MEANS FOR OUR V5 DESIGN

### The Architecture Mismatch

| Feature | Margolin Triple Helix | Our V5 Matrix |
|---------|----------------------|---------------|
| Slider direction | 3 directions at 120° | All same direction (X) |
| Pulleys per tier | 3 (redirect-slider-redirect) | 7-11 (zigzag block-and-tackle) |
| Rope topology | Simple U-detour per tier | Multi-wrap zigzag |
| Tiers per string | 3 | 5 channels (unclear if serial or parallel) |
| Total pulleys/string | 9 | 7-43 depending on interpretation |
| String-to-slider relationship | 1:1 — each string visits exactly 1 slider per tier | Multiple wraps around each slider |
| Detour geometry | Asymmetric U (bidirectional) | Symmetric zigzag (potentially rectified) |

### What We Should Build Instead

Our helix cam produces lateral motion. Margolin's sliders move laterally. **The helix cam output is already correct for this mechanism.** The problem is only in how we route the string through the matrix.

**Target architecture for our matrix:**

```
PER TIER (one helix):
  - Stationary polycarbonate/3D-printed plates with redirect rollers
  - 30 sliding strips (one per cam), each carrying one pulley/roller
  - Each sliding strip connected to one cam follower rib via cable
  - String path: redirect → slider pulley (U-turn) → redirect = 3 pulleys

THREE TIERS:
  - Tier 1 at 0°: sliders move along 0° direction
  - Tier 2 at 120°: sliders move along 120° direction
  - Tier 3 at 240°: sliders move along 240° direction
  - Each tier is a separate plate, rotated 120° from the previous
  - String passes vertically through holes in all three plates

PER STRING:
  - 3 tiers × 3 pulleys = 9 pulleys total
  - Within Margolin's friction limit

BLOCKS:
  - 30 blocks (matching 30 cams per helix)
  - Or 31 (prime, avoids Moiré) with one cam shared
  - Each block's string visits its nearest slider on each tier
  - Block height = sum of 3 slider contributions
```

### What Changes from V5

| V5 Component | Keep / Replace | New Design |
|--------------|---------------|------------|
| Helix camshaft (30 discs, 12°) | **KEEP** ✅ | No changes needed |
| Gravity ribs | **KEEP** ✅ | Still the cam followers |
| 5-channel block-and-tackle housing | **REPLACE** ❌ | → Simple 3-tier plate stack |
| Fixed pulleys (Y=±31, 3-5 per side) | **REPLACE** ❌ | → 2 redirect rollers per string per tier |
| Slider plates with multiple pulleys | **REPLACE** ❌ | → Sliding strips, 1 pulley each |
| Wall-mounted axles | **REPLACE** ❌ | → Rollers pressed into polycarbonate/plate |
| 22mm stacking offset | **MODIFY** | → Tier spacing determined by slider height + clearance |
| `anim_val = sin($t*360) * 68` | **FIX** | → `anim_val = sin($t*360) * 12` (actual cam stroke) |

---

## HELIX CAM — VERIFIED CORRECT (unchanged from V1)

### Traveling Wave ✅
```
30 discs × 12°/disc = 360° total twist
Y_i(θ) = 12 × sin(θ + i × 12°)    [mm, per cam follower]
```

### Self-Balancing Shaft ✅
```
Σ cos(θ + i×12°) = 0    for all θ    (i = 0..29)
```

### Gravity Rib Stability ✅
- Safe up to ~81 RPM, sculpture operates at 1-15 RPM
- Deflection at 15 RPM: 0.17° (negligible)

### Weight & Motor ✅
- Total rotating mass: ~7.3 kg (3 helixes)
- Required motor: < 0.05 Nm, < 0.025 W

---

## REMAINING ISSUES TO FIX

### ⛔ C1: Nut Trap Wall Thickness (from V1 — still valid)

Nut trap at 132° has only 0.23mm wall remaining.

**Fix**: `nut_trap_dia` 8→7mm, `bolt_circle_dia` 20→18mm → 1.7mm clearance ✅

### ⚠ W1: Rib Clearance (from V1 — still valid)

Adjacent ribs have 2mm axial clearance at 8mm pitch.

**Fix**: Increase axial pitch to 10mm or reduce rib thickness to 4mm.

### ⚠ W2: No Mechanical Rib Stops (from V1 — still valid)

**Fix**: Add ±15° soft stops on hub body.

### ⚠ W3: Slider Baseline Offset Must Be Designed

For the U-detour to be bidirectional, the slider must oscillate AROUND a baseline position, not from zero. The cam produces ±12mm of lateral motion centered on zero. We need to ensure the slider's rest position places it at the correct baseline offset from the string's vertical line.

Options:
- Spring bias on the sliding strip
- Geometric offset in the slot design
- The cam follower cable naturally creates tension that holds the slider at baseline

### 📝 N1: Block Weight Requirement

Margolin needed 70g blocks to overcome friction. With our 9-pulley path:
- η = 0.95⁹ ≈ 0.63
- Block weight must overcome: W_block > F_friction = W_block × (1 - η) / η
- Minimum: ~40g (but 70g recommended for reliable return)

### 📝 N2: 3D-Printable Matrix Plates

Margolin used CNC-routed polycarbonate with pressed-in steel dowel pins and nylon rollers. For 3D printing:
- PLA/PETG plates with roller channels
- Mini bearings (3×8×4mm) or brass bushings as redirect rollers
- Sliding strips in PTFE-lined channels for low friction

---

## NEW MATRIX DESIGN REQUIREMENTS

### Per-Tier Plate Specifications

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Block count | 30 (or 31 prime) | 1:1 with helix cams |
| Strings per plate | 30 | One per block |
| Slider strips per plate | 30 | One per cam |
| Redirect rollers per string per tier | 2 | In + out |
| Total redirect rollers per plate | 60 | 30 strings × 2 |
| Slider pulleys per plate | 30 | One per slider strip |
| Total pulleys per plate | 90 | 60 redirect + 30 slider |
| Total pulleys (3 plates) | 270 | 90 × 3 |
| Pulleys per string path | 9 | 3 per tier × 3 tiers |

### Tier Stacking

```
        ┌─────────────────┐
        │   TIER 1 (0°)   │  ← Sliders along 0° direction
        │   30 sliders     │     Connected to Helix 1
        └─────────────────┘
               │ strings pass through
        ┌─────────────────┐
        │  TIER 2 (120°)  │  ← Sliders along 120° direction
        │   30 sliders     │     Connected to Helix 2
        └─────────────────┘
               │ strings pass through
        ┌─────────────────┐
        │  TIER 3 (240°)  │  ← Sliders along 240° direction
        │   30 sliders     │     Connected to Helix 3
        └─────────────────┘
               │
          30 blocks hanging
```

### String Path (per block)

```
Top anchor
  ↓
Tier 1: redirect_in → slider_1 (U-turn) → redirect_out
  ↓
Tier 2: redirect_in → slider_2 (U-turn) → redirect_out
  ↓
Tier 3: redirect_in → slider_3 (U-turn) → redirect_out
  ↓
Block (70g, basswood + steel shot)
```

### Block Displacement Calculation

Each tier's U-detour change ≈ 2 × slider_displacement × sin(approach_angle)

For a redirect pulley at distance D from the string vertical, and slider baseline at offset B:
- When slider moves by δ from baseline:
- Detour change ≈ 2δ × B/√(B² + D²) per tier (linearized for small δ)

With B ≈ 30mm, D ≈ 15mm:
- Gain per tier ≈ 2 × B/√(B²+D²) = 2 × 30/√(900+225) = 2 × 30/33.5 = **1.79:1**
- Per tier: ±12mm × 1.79 = ±21.5mm rope change
- But this is distributed across 2 segments (in and out)
- Net per tier: ≈ ±12mm to ±20mm depending on exact geometry
- Across 3 tiers (not all in phase): peak ≈ ±36mm to ±60mm block travel

This is MUCH better than the V5's symmetric zigzag, and it's **bidirectional**.

---

## COMPARISON: V5 vs NEW MARGOLIN-STYLE MATRIX

| Metric | V5 Block-and-Tackle | New Margolin-Style |
|--------|---------------------|-------------------|
| Topology | Symmetric zigzag | Asymmetric U-detour |
| Bidirectional? | ❌ Rectified | ✅ Yes |
| Pulleys per string | 7-43 | 9 |
| Friction efficiency | 17-75% | 63% |
| Dead zone at neutral? | ❌ Yes | ✅ No |
| Linear response? | ❌ Quadratic | ✅ ~Linear |
| Tier directions | All same (X) | 3 at 120° |
| Matches Margolin? | ❌ Different mechanism | ✅ Same principle |
| Complexity | High (many pulley types) | Low (rollers + strips) |

---

## WAVE TYPES (unchanged from V1)

The helix natively produces a traveling wave. Other types via modifications:

| Wave Type | How | Modification |
|-----------|-----|-------------|
| **Traveling** (default) | Native — 30 discs × 12° | None |
| **Standing** | Two helixes counter-rotating | Reverse one belt |
| **Variable amplitude** | Gaussian eccentricity envelope | Machine discs with varying offsets |
| **Beat pattern** | Two helixes at slightly different speeds | Different belt ratios |
| **3-Helix interference** | Three helixes at 120° phase | Native with triple-helix setup |
| **Damped** | Progressive eccentricity decrease | Decreasing offset along shaft |
| **Variable wavelength** | Non-uniform twist angles | Non-linear twist |
| **Radial** | Disc order maps to radial distance | Re-route followers to Vogel spiral |

---

## KEY NUMBERS REFERENCE

| Parameter | Value | Unit |
|-----------|-------|------|
| Discs per helix | 30 | — |
| Twist per disc | 12 | degrees |
| Total twist | 360 | degrees |
| Bearing | 6810 (50×65×7) | mm |
| Eccentric offset | 12.0 | mm |
| Cam follower travel | ±12.0 | mm |
| Peak-to-peak per cam | 24.0 | mm |
| Tiers | 3 at 120° | — |
| Pulleys per string | 9 | — |
| Friction efficiency | 63% | (0.95⁹) |
| Minimum block weight | 40 | grams |
| Recommended block weight | 70 | grams |
| Blocks | 30 (or 31 prime) | — |
| Block peak-peak travel | ~60-80 | mm (estimated) |
| Strings | 30 | — |
| Total pulleys (3 tiers) | 270 | — |
| Safe RPM | <81 | RPM |
| Operating RPM | 1-15 | RPM |

---

## SOURCES

### Margolin Direct
- reubenmargolin.com/waves/triple-helix/story/ — Primary engineering source
- reubenmargolin.com/waves/triple-helix/ — Specifications
- TED Talk 2012: "Sculpting Waves in Wood and Time"
- dantorop.info/project/interview_reuben_margolin/ — Engineering interview

### Local Reference Files
- `Helix cam parts.scad` — Our 30-disc helix design
- `MATRIX SINGLE UNIT v5.scad` — V5 matrix (to be replaced)
- `triple_helix_prototype_v2.scad` — Our full prototype model
- `MARGOLIN_KNOWLEDGE_BANK.md` — Comprehensive knowledge base

### Photos Analyzed
- `tripleHelixStory_1.jpg` — Margolin's matrix prototype
- `tripleHelixStory_2.jpg` — CNC routing polycarbonate strips
- `STACKED MATRXI.jpg` — Annotated 3-tier string path
- `Screenshot 2026-02-09 042459.png` — Top-down view, 3 directions at 120°
- `Screenshot 2026-02-09 102330.png` — Side view, pulley counts 2-4-6-4-2
- `Screenshot 2026-02-09 122443.png` — Front view, 5 tiers with string paths
- `Screenshot 2026-02-09 141254.png` — Close-up actual matrix with strings
- `Screenshot 2026-02-09 170539.png` — 3/4 view V5 with hex frame overlay
- `Screenshot 2026-02-09 170947.png` — OpenSCAD render of stacked matrix
- `Screenshot 2026-02-10 011702.png` — Video still, tiers at 0°/120°/240°
- `Screenshot 2026-02-10 012645.png` — Overhead photo of actual matrix

---

*V2 audit — corrected understanding of Margolin's U-detour mechanism. Helix cam verified correct. V5 block-and-tackle matrix to be replaced with Margolin-style 3-tier redirect matrix.*
