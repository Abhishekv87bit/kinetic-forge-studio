# Vashisht Favorites — Mechanical Efficiency & Engineering Comparison

## Standard Efficiency Reference Values

| Transmission Type | Efficiency | Notes |
|---|---|---|
| Spur gear mesh | 0.95–0.98 | Per mesh, well-lubricated |
| Bevel gear mesh | 0.93–0.97 | Higher sliding friction than spur |
| Worm gear | 0.40–0.85 | Depends on lead angle; self-locking below ~0.50 |
| Epicyclic / planetary | 0.95–0.97 | Per stage |
| GT2 timing belt | 0.95–0.98 | Per span |
| Scotch yoke | 0.88–0.92 | Sliding contact, side loads |
| Linkage (4-bar) | 0.90–0.95 | Pin joints, depends on quality |
| Lead screw (Acme) | 0.35–0.55 | Self-locking types |
| Lead screw (ball) | 0.85–0.92 | Rolling contact, non-locking |
| Cable over pulley | 0.95–0.97 | Per pulley |
| Cam + follower | 0.88–0.93 | Sliding contact, spring return |
| Geneva mechanism | 0.80–0.88 | Intermittent, shock loads |
| Ratchet / click | 0.85–0.92 | Energy lost to detent |
| Strain wave | 0.65–0.85 | Flexspline deformation |
| Differential screw | 0.25–0.45 | Two thread interfaces |
| Compliant mechanism | 0.70–0.85 | Elastic strain energy |

---

## Master Comparison Table

| # | Mechanism | Efficiency Chain | Total Eff. | Unique Parts | Total Parts | Motor | 1 Motor? | Complexity | Build |
|---|---|---|---|---|---|---|---|---|---|
| 1 | War-to-Peace | worm(.65)×bevel(.95)×bevel(.95)×bevel(.95)×cable(.95)×cable(.95)×tensegrity(.80)×LED(.90) | **36%** | 22 | 400–600 | NEMA 23 | Marginal | EXTREME | Full CNC |
| 2 | Breathing Fabric | yoke(.90)×slider(.95) | **86%** | 8 | 25–35 | NEMA 14 | **YES** | **LOW** | 3D Print |
| 3 | Golden Engine | worm(.70)×epicyclic(.96)×shaft(.98)×bevel(.95)×worm(.65)×leadscrew(.40) | **16%** | 18 | 1,200–1,500 | NEMA 34 | Marginal | EXTREME | Full CNC |
| 4 | Woven Calculator | cam(.90)×Peaucellier(.88)×crossbar(.90)×output(.92) | **66%** | 15 | 200–350 | NEMA 17 | YES | HIGH | Hybrid |
| 5 | Quantized Calculator | stepdrum(.85)×Geneva(.83)×ratchet(.88)×diffscrew(.35) | **22%** | 16 | 150–250 | NEMA 17 | YES | HIGH | Full CNC |
| 6 | Ramp Interference | yoke(.90)×yoke(.90)×balls(.98) | **79%** | 10 | 30–50 | NEMA 14 | **YES** | **LOW** | 3D Print+Laser |
| 7 | Shadow Computer | epicyclic(.96)×epicyclic(.96)×cam(.90)×iris(.88) | **73%** | 14 | 200–400 | NEMA 17 | YES | HIGH | Hybrid |
| 8 | Ghost Lines | belt(.97)×cam(.90)×pushrod(.95) | **83%** | 9 | 80–120 | NEMA 17 | YES | **MEDIUM** | 3D Print |
| 9 | Resonance Harp | eccentric(.90)×coupling(.70) + Q gain 10–50x | **63%** mech | 10 | 40–80 | NEMA 14 | YES | MEDIUM | Hybrid (wood) |
| 10 | 15x15 Waffle Grid | belt(.97)×bevel(.95)×spur(.97)×planetary(.93)×spline(.98) | **82%** | 12 | 3,500–4,500 | NEMA 34 | With reduction | EXTREME | Full CNC |
| 11 | Coaxial Screw | belt(.97)×bevel(.70)×Acme(.40) or belt(.97)×bevel(.95)×ball(.88) | **27%** / **81%** | 10 | 200–400 | NEMA 17 | YES | MEDIUM | Hybrid |

---

## Per-Mechanism Efficiency Chains (Detailed)

### 1. War-to-Peace Converter (36%)
Motor → worm reduction → central bevel differential → branching bevel tree → cable network → tensegrity nodes

| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Worm gear (self-locking, high ratio) | 0.65 | 0.650 |
| 2 | Bevel differential input | 0.95 | 0.618 |
| 3 | Bevel branch level 1 | 0.95 | 0.587 |
| 4 | Bevel branch level 2 | 0.95 | 0.557 |
| 5 | Cable to node | 0.95 | 0.529 |
| 6 | Cable redirect pulley | 0.95 | 0.503 |
| 7 | Tensegrity compliance | 0.80 | 0.402 |
| 8 | LED trigger (mech→elec) | 0.90 | 0.362 |

### 2. Breathing Fabric (86%)
Motor → scotch yoke → linear slider → fabric push/pull

| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Scotch yoke | 0.90 | 0.900 |
| 2 | Linear guide/slider | 0.95 | 0.855 |

### 3. The Golden Engine (16%)
Motor → worm → epicyclic hub → spokes → bevel at pixel → worm at pixel → lead screw

| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Worm gear input | 0.70 | 0.700 |
| 2 | Epicyclic planetary set | 0.96 | 0.672 |
| 3 | Radial spoke coupling | 0.98 | 0.659 |
| 4 | Bevel at pixel | 0.95 | 0.626 |
| 5 | Worm at pixel (reduction) | 0.65 | 0.407 |
| 6 | Lead screw (Acme) | 0.40 | 0.163 |

**Note:** This is the most punishing chain. Two worm stages + Acme screw. Consider: replace pixel-level worm with belt loop (0.97), replace Acme with ball screw (0.88) → new efficiency: 0.70×0.96×0.98×0.95×0.97×0.88 = **50%** — triple the original.

### 4. Woven Calculator (66%)
Motor → cam shaft → card reader → Peaucellier linkages → crossbar

| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Cam + follower | 0.90 | 0.900 |
| 2 | Peaucellier-Lipkin (7 bars, 6 joints) | 0.88 | 0.792 |
| 3 | Crossbar selector | 0.90 | 0.713 |
| 4 | Output linkage | 0.92 | 0.656 |

### 5. Quantized Calculator (22%)
Motor → step drum → Geneva → ratchet → differential screw

| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Leibniz step drum | 0.85 | 0.850 |
| 2 | Geneva mechanism | 0.83 | 0.706 |
| 3 | Ratchet/detent | 0.88 | 0.621 |
| 4 | Differential screw | 0.35 | 0.217 |

**Note:** Low efficiency is the FEATURE. Friction = holding force. Self-locking at every stage.

### 6. Ramp Interference Engine (79%)
Motor → scotch yoke pair (90deg phase) → sliding plates + balls

| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Scotch yoke axis 1 | 0.90 | 0.900 |
| 2 | Scotch yoke axis 2 | 0.90 | 0.810 |
| 3 | Ball bearing transfer | 0.98 | 0.794 |

### 7. The Shadow Computer (73%)
Motor → dual epicyclic → cam/linkage → iris aperture array

| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Epicyclic stage 1 | 0.96 | 0.960 |
| 2 | Epicyclic stage 2 | 0.96 | 0.922 |
| 3 | Cam to iris ring | 0.90 | 0.829 |
| 4 | Iris blade linkage | 0.88 | 0.730 |

### 8. Ghost Lines (83%)
Motor → belt → cam shaft → push rods

| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Timing belt | 0.97 | 0.970 |
| 2 | Cam + follower | 0.90 | 0.873 |
| 3 | Push rod / linear guide | 0.95 | 0.829 |

### 9. Resonance Harp (63% mech, 630–3150% effective)
Motor → eccentric → string excitation at resonance

| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Eccentric cam | 0.90 | 0.900 |
| 2 | Bridge coupling | 0.70 | 0.630 |
| **Resonance Q** | 10–50x amplitude gain | ×10–50 | **6.3–31.5** effective |

**Note:** Only mechanism that AMPLIFIES. Tiny input at resonant frequency → large sustained vibration. Effective output-per-watt exceeds all others by 10x+.

### 10. 15x15 Waffle Grid (82%)
Motor → belt → bevel → layer shafts → 225 planetary differentials

| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Timing belt | 0.97 | 0.970 |
| 2 | Bevel gear | 0.95 | 0.922 |
| 3 | Spur gear | 0.97 | 0.894 |
| 4 | Compound planetary | 0.93 | 0.831 |
| 5 | Output spline | 0.98 | 0.815 |

**Note:** Per-path efficient, but 225 parallel loads × block weight = big motor.

### 11. Coaxial Screw (27% Acme / 81% Ball)
Motor → belt → bevel → threaded rod → nut

**Acme (self-locking):**
| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Timing belt | 0.97 | 0.970 |
| 2 | Bevel/worm per screw | 0.70 | 0.679 |
| 3 | Acme lead screw | 0.40 | 0.272 |

**Ball screw (needs brake):**
| Stage | Type | Eff. | Cumulative |
|---|---|---|---|
| 1 | Timing belt | 0.97 | 0.970 |
| 2 | Bevel gear | 0.95 | 0.922 |
| 3 | Ball screw | 0.88 | 0.811 |

---

## Rankings

### Simplest to Build
| Rank | Mechanism | Parts | Complexity |
|---|---|---|---|
| 1 | Breathing Fabric | 25–35 | LOW |
| 2 | Ramp Interference | 30–50 | LOW |
| 3 | Resonance Harp | 40–80 | MEDIUM |
| 4 | Ghost Lines | 80–120 | MEDIUM |
| 5 | Coaxial Screw | 200–400 | MEDIUM |
| 6 | Woven Calculator | 200–350 | HIGH |
| 7 | Shadow Computer | 200–400 | HIGH |
| 8 | Quantized Calculator | 150–250 | HIGH |
| 9 | War-to-Peace | 400–600 | EXTREME |
| 10 | Golden Engine | 1,200–1,500 | EXTREME |
| 11 | Waffle Grid | 3,500–4,500 | EXTREME |

### Most Efficient
| Rank | Mechanism | Efficiency |
|---|---|---|
| 1 | Breathing Fabric | 86% |
| 2 | Ghost Lines | 83% |
| 3 | Waffle Grid | 82% |
| 4 | Coaxial Screw (ball) | 81% |
| 5 | Ramp Interference | 79% |
| 6 | Shadow Computer | 73% |
| 7 | Woven Calculator | 66% |
| 8 | Resonance Harp | 63% (mech) / 630%+ (effective) |
| 9 | War-to-Peace | 36% |
| 10 | Coaxial Screw (Acme) | 27% |
| 11 | Quantized Calculator | 22% |
| 12 | Golden Engine | 16% |

### Best Visual-to-Complexity Ratio (WOW per engineering pain)
| Rank | Mechanism | Visual Impact | Complexity | Why |
|---|---|---|---|---|
| 1 | **Ramp Interference** | HIGH | LOW | Minimum parts, maximum optical Moire. Ball bearings are a delightful detail. |
| 2 | **Breathing Fabric** | HIGH | LOW | Viscerally biological. Nearly tied with #1, slightly less rich (1-axis vs 2-axis). |
| 3 | **Resonance Harp** | HIGH | MEDIUM | Only multi-sensory option (sight + sound). Tuning is hidden complexity. |
| 4 | **Ghost Lines** | MED-HIGH | MEDIUM | Scan-line animation, surprisingly complex patterns from simple cams. |
| 5 | **Shadow Computer** | VERY HIGH | HIGH | Projected light is spectacular. Iris + epicyclic is serious engineering. |
| 6 | **Coaxial Screw** | MEDIUM | MEDIUM | Clean, legible, satisfying. Reliable workhorse aesthetic. |
| 7 | **Woven Calculator** | HIGH | HIGH | Synchronized linkage forest is spectacular when working, but finicky. |
| 8 | **War-to-Peace** | VERY HIGH | EXTREME | Tensegrity constellation is stunning, but cable tensioning is a research project. |
| 9 | **Quantized Calculator** | MEDIUM | HIGH | Deeply satisfying clicks (ASMR-level), but best appreciated up close. |
| 10 | **Golden Engine** | VERY HIGH | EXTREME | Fibonacci spiral is gorgeous, but 89 worm assemblies is multi-month CNC. |
| 11 | **Waffle Grid** | HIGH | EXTREME | 225 pixels gives resolution, but 3,500+ parts is industrial. Lowest wow-per-part. |

---

## The Efficiency Killers (What to Avoid or Redesign)

| Component | Typical Eff. | Appears In | Fix |
|---|---|---|---|
| Worm gear | 0.40–0.70 | Golden Engine (×2), War-to-Peace, Coaxial Screw | Replace with belt+bevel. Accept no self-lock, add brake. |
| Acme lead screw | 0.35–0.55 | Golden Engine, Coaxial Screw, Quantized Calc | Ball screw (0.88) if self-lock not needed. |
| Differential screw | 0.25–0.45 | Quantized Calculator | Intentional — the friction IS the feature (self-locking). |
| Geneva mechanism | 0.80–0.88 | Quantized Calculator | Acceptable if quantization is the goal. |
| Tensegrity compliance | 0.70–0.85 | War-to-Peace | Pre-tension carefully; minimize cable redirect angles. |

## The Efficiency Champions

| Component | Typical Eff. | Best For |
|---|---|---|
| Timing belt | 0.95–0.98 | Power distribution over distance |
| Ball screw | 0.85–0.92 | Linear pixel motion (no self-lock) |
| Spur gear | 0.95–0.98 | Speed/torque change at same axis offset |
| Epicyclic set | 0.95–0.97 | Compact high-ratio reduction |
| Ball bearing transfer | 0.98+ | Plate-to-plate force transmission |
| Resonance | 10–50× gain | Amplitude amplification (free energy from sustain) |

---

## Golden Engine Redesign Note

Current architecture: **16% efficient** (worst of all 11).

Proposed fix — remove the two efficiency killers:
- Replace pixel-level worm gear (0.65) with belt loop from spoke (0.97)
- Replace Acme lead screw (0.40) with ball screw (0.88)

New chain: worm(0.70) × epicyclic(0.96) × spoke(0.98) × belt(0.97) × ball_screw(0.88)
**New efficiency: 56%** — 3.5× improvement.

Trade-off: lose self-locking (pixels won't hold position when motor stops). Solutions:
1. Motor brake (electromagnetic, $5 part)
2. Continuous slow drive (meditative sculpture runs continuously anyway)
3. Counterweight on each pixel (gravity-neutral, no holding force needed)
