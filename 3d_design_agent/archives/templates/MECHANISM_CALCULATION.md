# MECHANISM CALCULATION TEMPLATE

**THIS FILE MUST BE COMPLETED BEFORE ANY .scad CODE IS WRITTEN**

Project: _______________
Date: _______________

---

## PHASE 1: MECHANISM SELECTION

### 1.1 Motion Requirements
| Parameter | Value | Unit |
|-----------|-------|------|
| Input motion type | [ ] rotation / [ ] linear / [ ] oscillation | - |
| Output motion type | [ ] rotation / [ ] linear / [ ] oscillation | - |
| Input speed/frequency | _______ | RPM or Hz |
| Output amplitude | _______ | degrees or mm |
| Continuous or intermittent? | [ ] continuous / [ ] intermittent | - |

### 1.2 Mechanism Choice
Selected mechanism: _______________________

Alternatives considered:
1. _______________________ (rejected because: _______)
2. _______________________ (rejected because: _______)

Why this mechanism fits the motion requirements:
_________________________________________________________________

---

## PHASE 2: DIMENSIONAL LAYOUT

### 2.1 Reference Sketch
```
[DRAW MECHANISM HERE - ASCII or describe positions]

Example for four-bar:

    P1(ground)────────────────P4(ground)
         \                      /
          \  crank            / rocker
           \                  /
            P2──────────────P3
                 coupler
```

### 2.2 Fixed Points (Ground Pivots)
| Point | X (mm) | Y (mm) | Z (mm) | Description |
|-------|--------|--------|--------|-------------|
| P1 | _____ | _____ | _____ | ____________ |
| P2 | _____ | _____ | _____ | ____________ |

### 2.3 Link Lengths
| Link | Length (mm) | Connects | Notes |
|------|-------------|----------|-------|
| Ground | _____ | P1 to P4 | Fixed frame distance |
| Crank | _____ | P1 to P2 | Input link |
| Coupler | _____ | P2 to P3 | Connecting link |
| Rocker | _____ | P3 to P4 | Output link |

---

## PHASE 3: KINEMATIC VALIDATION

### 3.1 Grashof Check (Four-Bar Only)

**MANDATORY IF USING FOUR-BAR LINKAGE**

```
Link lengths:
  Ground (d) = _____ mm
  Crank (a)  = _____ mm
  Coupler (b) = _____ mm
  Rocker (c) = _____ mm

Sorted:
  S (shortest) = _____ mm (which link: _____)
  L (longest)  = _____ mm (which link: _____)
  P = _____ mm
  Q = _____ mm

Grashof Condition:
  S + L = _____ + _____ = _____ mm
  P + Q = _____ + _____ = _____ mm

Result: S + L _____ P + Q  (fill in: < , = , or >)

Classification:
  [ ] S + L < P + Q  → GRASHOF (crank can rotate 360°)
  [ ] S + L = P + Q  → SPECIAL GRASHOF (dead points exist)
  [ ] S + L > P + Q  → NON-GRASHOF (all links rock only)

If Grashof, linkage type (based on which link is grounded):
  [ ] Shortest grounded → Double-crank (both rotate 360°)
  [ ] Longest grounded → Double-rocker (both oscillate)
  [ ] Adjacent to shortest grounded → Crank-rocker
```

**GATE CHECK:**
- [ ] If design requires 360° rotation AND result is NON-GRASHOF → **BLOCKED - REDESIGN**
- [ ] If SPECIAL GRASHOF → dead point mitigation required (see 3.2)

### 3.2 Dead Point Analysis (Four-Bar Only)

```
Dead points occur when crank and coupler are collinear.

For crank angle θ, transmission angle μ calculated as:
μ = arccos((b² + c² - (a² + d² - 2ad·cos(θ))) / (2bc))

Calculate at key positions:

| θ (deg) | μ (deg) | Quality |
|---------|---------|---------|
| 0 | _____ | [ ] OK / [ ] POOR (<40° or >140°) |
| 45 | _____ | [ ] OK / [ ] POOR |
| 90 | _____ | [ ] OK / [ ] POOR |
| 135 | _____ | [ ] OK / [ ] POOR |
| 180 | _____ | [ ] OK / [ ] POOR |
| 225 | _____ | [ ] OK / [ ] POOR |
| 270 | _____ | [ ] OK / [ ] POOR |
| 315 | _____ | [ ] OK / [ ] POOR |

Dead points (μ ≈ 0° or 180°) at θ = _____, _____

Mitigation (if dead points in operating range):
  [ ] Flywheel (momentum carries through)
  [ ] 90° offset parallel crank
  [ ] Limit operating range to θ = _____ to _____
  [ ] N/A - no dead points in range
```

### 3.3 Coupler Length Constancy Check

**CRITICAL: A rigid linkage MUST maintain constant coupler length**

```
Calculate distance between moving pin positions at 4 phases:

At t=0 (θ=0°):
  Pin A position: (_____, _____, _____) mm
  Pin B position: (_____, _____, _____) mm
  Distance A-B: √((Δx)² + (Δy)² + (Δz)²) = _____ mm

At t=0.25 (θ=90°):
  Pin A position: (_____, _____, _____) mm
  Pin B position: (_____, _____, _____) mm
  Distance A-B: _____ mm

At t=0.5 (θ=180°):
  Pin A position: (_____, _____, _____) mm
  Pin B position: (_____, _____, _____) mm
  Distance A-B: _____ mm

At t=0.75 (θ=270°):
  Pin A position: (_____, _____, _____) mm
  Pin B position: (_____, _____, _____) mm
  Distance A-B: _____ mm

Declared coupler length: _____ mm
Maximum deviation: _____ mm

RESULT:
  [ ] PASS - All deviations < 0.5mm
  [ ] FAIL - Deviation > 0.5mm → **BLOCKED - GEOMETRY IMPOSSIBLE**
```

---

## PHASE 4: PHYSICS VALIDATION

### 4.1 Power Budget

```
Power Source:
  Type: [ ] Motor / [ ] Water gravity / [ ] Manual / [ ] Spring

  If motor:
    Voltage: _____ V
    Stall torque: _____ N·mm
    No-load RPM: _____
    Operating torque: _____ N·mm
    Operating power: _____ W

  If water gravity:
    Flow rate: _____ mL/min = _____ m³/s
    Drop height: _____ m
    Power = ρ × Q × g × h = _____ W

Mechanism Efficiency:
  Stage 1 (______): η₁ = _____
  Stage 2 (______): η₂ = _____
  Total efficiency: η = η₁ × η₂ = _____

Power Available: P_source × η = _____ W

Power Required:
  Element 1 (______): τ = _____ N·mm, ω = _____ rad/s → P = _____ W
  Element 2 (______): τ = _____ N·mm, ω = _____ rad/s → P = _____ W
  Total: _____ W

Power Margin: Available / Required = _____x

RESULT:
  [ ] PASS - Margin ≥ 1.5x
  [ ] FAIL - Margin < 1.5x → **BLOCKED - INSUFFICIENT POWER**
```

### 4.2 Gravity Analysis (if any part > 50g)

```
For each element with mass > 50g:

Element: _______________
  Mass: _____ g = _____ kg

  At θ=0°:
    CG position: (_____, _____) mm from pivot
    Horizontal offset: _____ mm
    τ_gravity = m × g × offset = _____ × 9.81 × _____ = _____ N·mm

  At θ=180°:
    CG position: (_____, _____) mm from pivot
    Horizontal offset: _____ mm
    τ_gravity = _____ N·mm

  Maximum gravity torque: _____ N·mm
  Available driving torque: _____ N·mm

RESULT:
  [ ] PASS - Driving torque > gravity torque at all positions
  [ ] FAIL - Add counterweight of _____ g at _____ mm
  [ ] FAIL - Reduce element mass to < _____ g
```

### 4.3 Tolerance Stack

```
Kinematic chain: Input → ____________ → ____________ → Output

Number of joints (N): _____
Per-joint clearance (FDM): ±0.2 mm

Worst-case stack: N × 0.2 = _____ mm
RSS estimate: √(N × 0.04) = _____ mm

Acceptable for this application: _____ mm

RESULT:
  [ ] PASS - Stack < acceptable
  [ ] NEEDS MITIGATION:
      [ ] Preload springs
      [ ] Press-fit connections
      [ ] Adjustment mechanism
```

---

## PHASE 5: PRINTABILITY CHECK

### 5.1 Wall Thickness
| Part | Thinnest Wall | Min Required | Result |
|------|---------------|--------------|--------|
| _____ | _____ mm | 1.2 mm | [ ] PASS / [ ] FAIL |
| _____ | _____ mm | 1.2 mm | [ ] PASS / [ ] FAIL |
| _____ | _____ mm | 1.2 mm | [ ] PASS / [ ] FAIL |

### 5.2 Clearances
| Joint | Clearance | Min Required | Result |
|-------|-----------|--------------|--------|
| _____ | _____ mm | 0.3 mm | [ ] PASS / [ ] FAIL |
| _____ | _____ mm | 0.3 mm | [ ] PASS / [ ] FAIL |

### 5.3 Overhangs
| Feature | Angle | Needs Support? |
|---------|-------|----------------|
| _____ | _____ ° | [ ] No (<45°) / [ ] Yes |
| _____ | _____ ° | [ ] No (<45°) / [ ] Yes |

---

## GATE APPROVAL

**ALL BOXES MUST BE CHECKED BEFORE CODE GENERATION:**

- [ ] Mechanism type selected and justified
- [ ] All link lengths defined with dimensions
- [ ] Grashof check completed (if four-bar)
- [ ] Dead point analysis completed (if four-bar)
- [ ] Coupler length constancy verified (ALL deviations < 0.5mm)
- [ ] Power budget calculated (margin ≥ 1.5x)
- [ ] Gravity analysis completed (if mass > 50g)
- [ ] Tolerance stack acceptable
- [ ] All walls ≥ 1.2mm
- [ ] All clearances ≥ 0.3mm

**APPROVAL:**

Calculations completed by: _______________
Date: _______________

Proceed to code generation: [ ] YES / [ ] NO - Reason: _______________

---

## NOTES / ISSUES DISCOVERED

_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
