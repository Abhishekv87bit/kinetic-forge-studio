# Ravigneaux Wave Drive — Kinematic Analysis

## 1. Architecture Overview

```
Motor Shaft (common to all units)
    │
    ├── External Pinion Pair 1 ──→ SL sun shaft (spline)
    ├── External Pinion Pair 2 ──→ Ss sun shaft (spline)
    └── External Pinion Pair 3 ──→ Carrier plate
                                        │
                              ┌─────────┴─────────┐
                              │  RAVIGNEAUX UNIT   │
                              │  (2-DOF diffrnl)   │
                              └─────────┬─────────┘
                                        │
                                   Ring Gear ──→ Rope Spool
                                                     │
                                                   Pixel
                                              (up/down motion)
```

**Key constraint:** Ravigneaux = **2 DOF**. Four rotating members (Ss, SL, Carrier, Ring),
two gear mesh constraints → need exactly 2 independent inputs to determine the output.
Specifying all 3 inputs REQUIRES a compatibility condition, or the mechanism binds.

---

## 2. Willis Equations (Fundamental Gear Train Relations)

### Path 1: SL → Po → Ring

Gear contacts (carrier held):
- SL (T_SL) → Po (T_PO): **external** mesh
- Po (T_PO) → Ring (T_Ring): **internal** mesh

One external mesh (odd) → **negative** train ratio.

```
(ω_Ring - ω_C) / (ω_SL - ω_C) = -T_SL / T_Ring
```

### Path 2: Ss → Pi → Po → Ring

Gear contacts (carrier held):
- Ss (T_SS) → Pi (T_PI): **external** mesh
- Pi (T_PI) → Po (T_PO): **external** mesh
- Po (T_PO) → Ring (T_Ring): **internal** mesh

Two external meshes (even) → **positive** train ratio.
(Intermediate teeth cancel: T_PI/T_PI = 1, T_PO/T_PO = 1)

```
(ω_Ring - ω_C) / (ω_SS - ω_C) = +T_SS / T_Ring
```

### Expanded forms:

```
Eq1: ω_R = ω_C × (T_Ring + T_SL) / T_Ring  -  ω_SL × T_SL / T_Ring

Eq2: ω_R = ω_C × (T_Ring - T_SS) / T_Ring  +  ω_SS × T_SS / T_Ring
```

---

## 3. Compatibility Condition

Setting Eq1 = Eq2 and solving for ω_C:

```
ω_C × (T_SL + T_SS) = T_SL × ω_SL + T_SS × ω_SS

┌──────────────────────────────────────────────────┐
│  ω_C = (T_SL × ω_SL + T_SS × ω_SS) / (T_SL + T_SS)  │
│                                                          │
│  Carrier speed = tooth-count-weighted average of suns    │
└──────────────────────────────────────────────────┘
```

**Meaning:** You can freely choose ω_SL and ω_SS. The carrier speed is then DETERMINED.
If you also drive the carrier externally, its speed MUST equal this weighted average,
or the gears bind. This constrains the external pinion ratio for the carrier.

---

## 4. Ring Output Formula

Substituting the compatibility condition back into either equation:

```
             T_SL × ω_SL × (T_Ring - T_SS) + T_SS × ω_SS × (T_Ring + T_SL)
ω_Ring = ──────────────────────────────────────────────────────────────────────
                             T_Ring × (T_SL + T_SS)
```

### With our current tooth counts (T_SS=26, T_SL=32, T_Ring=80):

```
ω_Ring = [32 × ω_SL × 54  +  26 × ω_SS × 112] / [80 × 58]
       = [1728 × ω_SL  +  2912 × ω_SS] / 4640
       = 0.3724 × ω_SL  +  0.6276 × ω_SS
```

**Check:** If ω_SL = ω_SS = ω (rigid body rotation):
ω_Ring = (0.3724 + 0.6276) × ω = 1.0 × ω  ✓  (everything spins as one piece)

---

## 5. Drive Mode Table (one motor, external pinions)

All inputs driven from the same motor at speed ω_m, through external gear pairs.

Define: r_SL, r_SS = external pinion ratios
(ω_SL = r_SL × ω_m,  ω_SS = r_SS × ω_m)

```
ω_Ring = ω_m × [0.3724 × r_SL  +  0.6276 × r_SS]

Carrier (compatibility):
r_C = (32 × r_SL + 26 × r_SS) / 58
```

### Example drive modes (single unit):

| Mode | r_SL | r_SS | r_C (forced) | ω_Ring/ω_m | Description |
|------|------|------|-------------|------------|-------------|
| A | 1.0 | 0 | 0.5517 | 0.3724 | SL only, Ss held |
| B | 0 | 1.0 | 0.4483 | 0.6276 | Ss only, SL held |
| C | 1.0 | 1.0 | 1.0000 | 1.0000 | Rigid body spin |
| D | 1.0 | -1.0 | 0.1034 | -0.2552 | Counter-rotating suns |
| E | 1.5 | 0.5 | 1.0517 | 0.8724 | Mixed drive |
| F | 0.5 | 1.5 | 0.9483 | 1.1276 | Reverse mixed |

**Sign convention:** Positive = clockwise viewed from top. Negative = counter-clockwise.
Rope: CW → down, CCW → up.

---

## 6. Multi-Unit Wave Generation

### Strategy: Same motor shaft, different external pinion ratios per unit

Each unit shares the motor shaft but has unique external gear pairs:

```
Unit i:  ω_Ring_i = ω_m × [0.3724 × r_SL_i  +  0.6276 × r_SS_i]
```

**Wave requirement:** Adjacent units must have slightly different ω_Ring.
The DIFFERENCE in ring speed creates the phase shift that propagates the wave.

### Rope displacement per unit:

```
Pixel position:  y_i(t) = R_spool × θ_Ring_i(t)
                         = R_spool × ω_Ring_i × t
                         = R_spool × ω_m × t × [0.3724 × r_SL_i + 0.6276 × r_SS_i]
```

For sinusoidal wave: drive the motor with oscillating speed ω_m = A × sin(2πft)

```
y_i(t) = R_spool × A × K_i × [-cos(2πft) / (2πf)]

where K_i = 0.3724 × r_SL_i + 0.6276 × r_SS_i  (effective ratio for unit i)
```

**Amplitude of pixel i** = R_spool × A × K_i / (2πf)

---

## 7. Two Knobs Per Unit

### Knob 1: External pinion ratios (r_SL_i, r_SS_i)
- Easy to change: swap external gears on the motor shaft
- Does NOT change physical size of unit
- Changes effective ratio K_i continuously

### Knob 2: Internal tooth counts (T_SS_i, T_SL_i)
- Changes the 0.3724 / 0.6276 split (the weighting)
- Changes physical size of unit
- Must satisfy: T_SL + 2×T_PO = T_Ring, and T_SL - T_SS > 4 (ISSUE-012)

### Combined effect:

```
K_i = W_SL(T_SS_i, T_SL_i) × r_SL_i  +  W_SS(T_SS_i, T_SL_i) × r_SS_i

where:
  W_SL = T_SL × (T_Ring - T_SS) / [T_Ring × (T_SL + T_SS)]
  W_SS = T_SS × (T_Ring + T_SL) / [T_Ring × (T_SL + T_SS)]
  W_SL + W_SS = 1  (always sums to 1)
```

---

## 8. Recommended Unit Configurations (7-unit wave)

All units share Ring=80. External pinion ratios chosen for golden-ratio-like
phase drift between adjacent units.

### Option A: Vary external ratios only (identical internal gears)

All units use T_SS=26, T_SL=32, T_PO=24 (our current design).
Wave created purely by varying external pinions.

| Unit | r_SL | r_SS | K_i | K ratio to Unit 1 | Phase character |
|------|------|------|-----|-------------------|-----------------|
| 1 | 1.000 | 1.000 | 1.0000 | 1.000 | Reference |
| 2 | 1.000 | 0.900 | 0.9348 | 0.935 | Slight lag |
| 3 | 1.000 | 0.800 | 0.8697 | 0.870 | Medium lag |
| 4 | 1.000 | 0.618 | 0.7602 | 0.760 | φ-tuned lag |
| 5 | 0.800 | 1.000 | 0.9255 | 0.926 | Cross-tuned |
| 6 | 0.618 | 1.000 | 0.8578 | 0.858 | φ-tuned cross |
| 7 | 0.500 | 0.500 | 0.5000 | 0.500 | Half speed |

**Advantage:** All internal gearsets identical → one design, one BOM, one print.
**Disadvantage:** Wave character limited to linear blending of two ratios.

### Option B: Vary internal tooth counts (same external ratios)

All units use r_SL = r_SS = 1.0 (1:1 external gears, or direct drive).
Wave created by internal geometry differences.

| Unit | T_SS | T_SL | T_PO | Po-Ss gap | W_SL | W_SS | K_i |
|------|------|------|------|-----------|------|------|-----|
| 1 | 26 | 32 | 24 | 0.77mm | 0.372 | 0.628 | 1.000 |
| 2 | 24 | 34 | 23 | 2.32mm | 0.401 | 0.599 | 1.000 |
| 3 | 22 | 36 | 22 | 3.86mm | 0.429 | 0.571 | 1.000 |
| 4 | 20 | 38 | 21 | 5.41mm | 0.458 | 0.542 | 1.000 |
| 5 | 18 | 40 | 20 | 6.95mm | 0.487 | 0.513 | 1.000 |
| 6 | 28 | 30 | 25 | FAIL(-0.77)| 0.346 | 0.654 | 1.000 |
| 7 | 16 | 42 | 19 | 8.50mm | 0.517 | 0.483 | 1.000 |

**PROBLEM:** With r_SL = r_SS = 1.0, ALL K_i = 1.0 regardless of internal counts!
Rigid body — no wave. Internal tooth counts only change the WEIGHTING, not the output
when both suns spin at the same speed.

**Conclusion:** Internal tooth count changes only matter when r_SL ≠ r_SS.

### Option C: Vary BOTH (maximum wave flexibility) — RECOMMENDED

Internal tooth count variation amplifies the effect of external ratio differences.

| Unit | T_SS | T_SL | T_PO | r_SL | r_SS | K_i | Note |
|------|------|------|------|------|------|-----|------|
| 1 | 26 | 32 | 24 | 1.0 | 0.8 | 0.870 | Reference |
| 2 | 24 | 34 | 23 | 1.0 | 0.8 | 0.880 | +1.2% |
| 3 | 22 | 36 | 22 | 1.0 | 0.8 | 0.886 | +1.8% |
| 4 | 20 | 38 | 21 | 0.8 | 1.0 | 0.908 | Cross drive |
| 5 | 18 | 40 | 20 | 0.8 | 1.0 | 0.897 | Cross drive |
| 6 | 24 | 34 | 23 | 0.6 | 1.0 | 0.839 | Strong Ss bias |
| 7 | 26 | 32 | 24 | 0.6 | 1.0 | 0.852 | Strong Ss bias |

**Advantage:** Maximum flexibility — every unit uniquely tuned.
**Disadvantage:** Multiple BOM variants, more complex assembly.

---

## 9. Practical Design Rules

### Rule 1: Ring constraint (absolute)
```
T_SL + 2 × T_PO = T_Ring (= 80 for all units)
T_SL must be even → T_PO is always integer
```

### Rule 2: Po-Ss clearance (ISSUE-012)
```
T_SL - T_SS > 4  →  minimum gap = (T_SL - T_SS - 4) / (2·DP) > 0
Recommended: T_SL - T_SS ≥ 6  →  gap ≥ 0.77mm
```

### Rule 3: Pi mesh constraint (non-degenerate)
```
T_PI > (T_SL - T_SS) / 2
With T_SS=26, T_SL=32: T_PI > 3 → T_PI=19 >> 3 ✓
```

### Rule 4: Carrier compatibility (when all 3 driven)
```
r_C = (T_SL × r_SL + T_SS × r_SS) / (T_SL + T_SS)
Violating this → mechanism binds → broken teeth
```

### Rule 5: Wave K_i diversity
```
For visible wave: max(K_i) / min(K_i) ≥ 1.3 (30% speed range)
For dramatic wave: ratio ≥ 2.0
```

### Rule 6: Rope direction
```
K_i > 0 → Ring CW → rope down → pixel descends
K_i < 0 → Ring CCW → rope up → pixel rises
K_i = 0 → Ring stationary → pixel frozen
Counter-rotating suns (r_SL > 0, r_SS < 0) can flip ring direction
```

---

## 10. Validation Formulas (for code verification)

```python
# Plug these into any unit to verify ring output:

def ring_speed(T_SS, T_SL, T_Ring, r_SL, r_SS, omega_motor):
    """Ring angular velocity for given inputs."""
    W_SL = T_SL * (T_Ring - T_SS) / (T_Ring * (T_SL + T_SS))
    W_SS = T_SS * (T_Ring + T_SL) / (T_Ring * (T_SL + T_SS))
    assert abs(W_SL + W_SS - 1.0) < 1e-10, "Weights must sum to 1"
    K = W_SL * r_SL + W_SS * r_SS
    return K * omega_motor

def carrier_speed(T_SL, T_SS, r_SL, r_SS, omega_motor):
    """Required carrier speed for compatibility."""
    return omega_motor * (T_SL * r_SL + T_SS * r_SS) / (T_SL + T_SS)

def pixel_displacement(R_spool, K_i, amplitude, freq, t):
    """Vertical pixel position (sinusoidal motor drive)."""
    import math
    return R_spool * amplitude * K_i * (-math.cos(2 * math.pi * freq * t)) / (2 * math.pi * freq)
```

---

## Current Unit Reference Values

```
T_SS = 26,  T_SL = 32,  T_PO = 24,  T_PI = 19,  T_Ring = 80
DP = 1.294,  TRANS_MOD = 0.773mm,  NORM_MOD = 0.7mm

W_SL = 32 × 54 / (80 × 58) = 1728/4640 = 0.3724
W_SS = 26 × 112 / (80 × 58) = 2912/4640 = 0.6276

Ring OD (spool surface) ≈ T_Ring / DP + 2/DP = 82/1.294 ≈ 63.4mm
R_spool ≈ 31.7mm

For 1 RPM motor with r_SL=1.0, r_SS=0.8:
  K = 0.3724 × 1.0 + 0.6276 × 0.8 = 0.8745
  ω_Ring = 0.8745 RPM
  Rope speed = 2π × 31.7mm × 0.8745/60 = 2.90 mm/s
```
