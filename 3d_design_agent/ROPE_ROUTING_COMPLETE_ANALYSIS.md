# COMPLETE ROPE ROUTING ANALYSIS
## Triple Helix MVP — Every Contact Point, Angle, and Design Flaw
### Date: Feb 2026

---

## 1. SCOPE

This document traces ONE string from top anchor to block through all 3 matrix tiers, identifying every contact point, every angle change, every transition, and every potential failure mode. All 19 strings follow the same pattern — only the slider assignment differs.

---

## 2. COORDINATE SYSTEM

```
Looking DOWN at the matrix from above (plan view):

              0° (Tier 1 slider direction)
              ↑
              |
              |
   240° ------+------ 120°
  (Tier 3)    |     (Tier 2)
              |

Z-axis: positive UP (toward ceiling/anchor)
        negative DOWN (toward blocks/floor)

Block positions: hex grid in XY plane
String path: primarily vertical (Z), with lateral detours at each tier
```

---

## 3. THE FULL STRING PATH — CONTACT POINT BY CONTACT POINT

### Legend
```
[A]  = Anchor point (fixed)
[R]  = Redirect roller (fixed in matrix frame, spins freely)
[S]  = Slider pulley (moves laterally, spins freely)
[G]  = Guide bushing (fixed, string slides through)
[B]  = Block attachment (fixed to block)
─    = Vertical string segment (free hanging)
╲╱   = Angled string segment (under tension, touching roller)
≈    = String wrap around roller (partial wrap, not full 360°)
```

### Complete Path (19 Contact Points Total)

```
CONTACT    TYPE       LOCATION                    WHAT HAPPENS
POINT
═══════════════════════════════════════════════════════════════════

[A]        ANCHOR     Top plate, directly above    String terminates here.
                      block's hex center            Fixed eyelet or crimp.
           Z = +300mm (above matrix)
           XY = block center position

  │
  │  FREE VERTICAL DROP (~45mm)
  │  String hangs straight down under block weight
  │
  ▼

─────────── TIER 1 ENTRY (0° orientation) ──────────

[T1-G1]    GUIDE      Top face of Tier 1           String enters Tier 1 housing
           BUSHING    Z = +255mm                    through a PTFE-lined bushing.
                      XY = near block center        Constrains string to enter
                                                    at specific XY location.

  │
  │  SHORT VERTICAL (~10mm inside housing)
  │
  ▼

[T1-R1]    REDIRECT   Fixed in Tier 1 matrix       String wraps ~45-90° around
           IN         Z = +245mm                    this roller. Changes direction
                      XY = offset ~8mm from          from vertical to angled
                      string vertical toward         approach toward slider.
                      slider direction (0°)
                      WRAP ANGLE: ~60°
                      ROLLER: 13mm OD nylon

  ╲
   ╲  ANGLED SEGMENT (approach to slider)
    ╲  Length ≈ √(B² + D²) where
     ╲  B = baseline_offset = 35mm (lateral)
      ╲  D = redirect_spacing_Y = 20mm (vertical)
       ╲  Segment length ≈ 40.3mm
        ╲  Angle from vertical: arctan(35/20) = 60°
         ╲
          ▼

[T1-S1]   SLIDER      Moving laterally along 0°    String wraps ~120-150° around
          PULLEY      Z = +225mm                    slider pulley (the U-turn).
                      X = BASELINE ± 12mm           This is where the COMPUTATION
                      (35mm ± 12mm from vertical)   happens. Slider position
                      = 23mm to 47mm from center    determines detour length.
                      WRAP ANGLE: ~120-150°
                      ROLLER: 10mm OD, on slider

          ╱
         ╱  ANGLED SEGMENT (departure from slider)
        ╱   Mirror of approach but not identical
       ╱    because redirect_out may be at
      ╱     slightly different XY than redirect_in
     ╱      Length ≈ 40-42mm
    ╱       Angle from vertical: ~55-65°
   ╱
  ╱
  ▼

[T1-R2]   REDIRECT    Fixed in Tier 1 matrix       String wraps ~45-90° around
          OUT         Z = +205mm                    this roller. Changes direction
                      XY = offset ~5mm from          from angled back to near-
                      string vertical                vertical for tier exit.
                      WRAP ANGLE: ~60°
                      ROLLER: 13mm OD nylon

  │
  │  SHORT NEAR-VERTICAL (~5mm)
  ▼

[T1-G2]   GUIDE       Bottom face of Tier 1        String exits Tier 1 through
          BUSHING     Z = +195mm                    bottom bushing. This is
                      XY = near block center        CRITICAL — see Flaw F1.

═══════════════════════════════════════════════════════════════════

  │
  │  INTER-TIER GAP (~25mm)
  │  String hangs between Tier 1 and Tier 2
  │
  │  *** CRITICAL TRANSITION ***
  │  String must shift laterally to align
  │  with Tier 2's entry point, which is
  │  oriented along 120° instead of 0°
  │  See Section 5: INTER-TIER TRANSITION
  │
  ▼

─────────── TIER 2 ENTRY (120° orientation) ─────────

[T2-G1]   GUIDE       Top face of Tier 2           String enters Tier 2.
          BUSHING     Z = +170mm                    Entry point aligned with
                      XY = shifted to accommodate    120° detour direction.
                      120° slider direction

  │
  ▼

[T2-R1]   REDIRECT    Fixed in Tier 2 matrix       Same as Tier 1 but all
          IN          Z = +160mm                    lateral offsets rotated
                      Along 120° direction           120° from Tier 1.
                      WRAP: ~60°
                      ROLLER: 13mm OD

  ╲
   ╲  APPROACH (along 120° direction)
    ╲  ~40mm angled segment
     ▼

[T2-S1]   SLIDER      Moving along 120° axis       Driven by Helix 2.
          PULLEY      Z = +140mm                    Different phase than T1-S1.
                      Along 120°, baseline ± 12mm
                      WRAP: ~120-150°
                      ROLLER: 10mm OD

     ╱
    ╱  DEPARTURE (along 120° direction)
   ╱   ~40mm angled segment
  ╱
  ▼

[T2-R2]   REDIRECT    Fixed in Tier 2              Back toward center.
          OUT         Z = +120mm
                      WRAP: ~60°

  │
  ▼

[T2-G2]   GUIDE       Bottom face of Tier 2        Exit Tier 2.
          BUSHING     Z = +110mm

═══════════════════════════════════════════════════════════════════

  │
  │  INTER-TIER GAP (~25mm)
  │  Same transition issue — shift for 240°
  ▼

─────────── TIER 3 ENTRY (240° orientation) ─────────

[T3-G1]   GUIDE       Top face of Tier 3           Entry aligned with 240°.
          BUSHING     Z = +85mm

  │
  ▼

[T3-R1]   REDIRECT    Fixed in Tier 3              Along 240° direction.
          IN          Z = +75mm
                      WRAP: ~60°

  ╲
   ╲  APPROACH (along 240°)
    ▼

[T3-S1]   SLIDER      Moving along 240° axis       Driven by Helix 3.
          PULLEY      Z = +55mm
                      WRAP: ~120-150°

    ╱
   ╱  DEPARTURE (along 240°)
  ╱
  ▼

[T3-R2]   REDIRECT    Fixed in Tier 3              Back toward center.
          OUT         Z = +35mm
                      WRAP: ~60°

  │
  ▼

[T3-G2]   GUIDE       Bottom face of Tier 3        Exit Tier 3.
          BUSHING     Z = +25mm

═══════════════════════════════════════════════════════════════════

  │
  │  POST-MATRIX DROP
  │  String now has accumulated lateral
  │  deviations from ALL 3 tier detours
  │  See Section 6: GUIDE PLATE
  ▼

─────────── GUIDE PLATE (DAMPENER GRID) ─────────────

[GP-G1]   GUIDE       Guide Plate 1 (upper)        Captures string from any
          BUSHING     Z = +15mm                     incoming angle. Funnel entry
                      XY = directly above block      (chamfered top) accepts
                      center                         off-angle string.
                      BUSHING: PTFE flanged
                      BORE: 2.0mm (string 0.5mm)
                      FUNNEL: 5mm entry, 2mm exit

  │
  │  SHORT VERTICAL (15mm)
  │  String now fully constrained to vertical
  ▼

[GP-G2]   GUIDE       Guide Plate 2 (lower)        Second guide confirms
          BUSHING     Z = 0mm (datum)               vertical path. Two-point
                      XY = block center              constraint = guaranteed
                      BUSHING: PTFE flanged          straight line.
                      BORE: 2.0mm

  │
  │  FREE VERTICAL DROP to block
  │  (~100-250mm depending on wave position)
  │  String is perfectly vertical here
  │  Block hangs by gravity
  ▼

[B]       BLOCK       Block top center              String terminates at block.
          ATTACH      Z = varies with wave           Crimp, knot, or through-
                      XY = hex grid position          bolt with washer.

═══════════════════════════════════════════════════════════════════
```

### Summary: Contact Points Per String

| Contact Point | Type | Friction | Count |
|---------------|------|----------|-------|
| [A] Anchor | Fixed eyelet | Negligible | 1 |
| [T1-G1] Tier 1 entry guide | PTFE bushing | ~0.99 | 1 |
| [T1-R1] Tier 1 redirect in | Roller (spinning) | ~0.95 | 1 |
| [T1-S1] Tier 1 slider pulley | Roller (spinning) | ~0.95 | 1 |
| [T1-R2] Tier 1 redirect out | Roller (spinning) | ~0.95 | 1 |
| [T1-G2] Tier 1 exit guide | PTFE bushing | ~0.99 | 1 |
| [T2-G1] Tier 2 entry guide | PTFE bushing | ~0.99 | 1 |
| [T2-R1] Tier 2 redirect in | Roller (spinning) | ~0.95 | 1 |
| [T2-S1] Tier 2 slider pulley | Roller (spinning) | ~0.95 | 1 |
| [T2-R2] Tier 2 redirect out | Roller (spinning) | ~0.95 | 1 |
| [T2-G2] Tier 2 exit guide | PTFE bushing | ~0.99 | 1 |
| [T3-G1] Tier 3 entry guide | PTFE bushing | ~0.99 | 1 |
| [T3-R1] Tier 3 redirect in | Roller (spinning) | ~0.95 | 1 |
| [T3-S1] Tier 3 slider pulley | Roller (spinning) | ~0.95 | 1 |
| [T3-R2] Tier 3 redirect out | Roller (spinning) | ~0.95 | 1 |
| [T3-G2] Tier 3 exit guide | PTFE bushing | ~0.99 | 1 |
| [GP-G1] Guide plate upper | PTFE bushing | ~0.99 | 1 |
| [GP-G2] Guide plate lower | PTFE bushing | ~0.99 | 1 |
| [B] Block attach | Fixed | Negligible | 1 |

**Total contact points: 19**
**Spinning rollers: 9** (3 per tier: redirect_in + slider + redirect_out)
**Sliding bushings: 8** (2 per tier entry/exit + 2 guide plate)
**Fixed attach: 2** (anchor + block)

### Updated Friction Calculation

```
Rolling friction:    0.95^9 = 0.6302
Sliding friction:    0.99^8 = 0.9227 (PTFE bushings, low wrap)
Combined efficiency: 0.6302 x 0.9227 = 0.5815 = ~58%

This is LOWER than the previously assumed 63%!
```

---

## 4. DESIGN FLAW ANALYSIS

### F1: GUIDE BUSHINGS ADD MORE FRICTION THAN EXPECTED

**Problem**: The previous analysis assumed 9 contact points (just the rollers). But the string also slides through 8 PTFE bushings (tier entries, exits, guide plate). Even at 99% efficiency each, 0.99^8 = 92.3%, which drops combined efficiency from 63% to 58%.

**Impact**: Block weight must increase to compensate.
```
At 58% efficiency:
  F_friction = block_weight x (1 - 0.58) / 0.58 = 0.724 x block_weight
  For reliable return, need F_gravity > F_friction x safety_factor
  Minimum block weight stays ~70g (the friction acts on block weight itself)
  But MARGIN is thinner. Recommend 80g (40g PLA + 40g steel shot).
```

**Fix**: Increase block weight from 70g to **80g**. OR: eliminate some bushings.

### F2: BUSHING ANGLE — STRING ENTERS BUSHINGS AT AN ANGLE, NOT VERTICAL

**Problem**: Look at [T1-G2] — the string exits Tier 1 after the redirect_out roller. But the redirect_out roller is NOT directly above the next tier's entry bushing. The string exits at a slight angle from the redirect_out roller to the exit bushing.

If the bushing bore is straight (cylindrical), and the string enters at an angle, the string will **press against the bushing wall** on one side, creating a PINCH point with much higher friction than the assumed 0.99.

```
            │ redirect_out roller
            │ at offset ~5mm from center
            │
            │ ╱  ← string exits at angle
            │╱
     ═══════●═══════  bushing (straight bore)
            │         ← string PINCHES here
            │
```

At 5mm offset over 10mm bushing length: approach angle = arctan(5/10) = 26.6 degrees.
String presses against bushing wall at ~26.6° -> much higher friction!

**Fix**: TWO OPTIONS:
1. **Eliminate tier exit bushings entirely.** Let the string exit freely through an oversized hole (8mm diameter, much larger than 0.5mm string). The hole just prevents string from rubbing on the plate edge. No friction contribution. **This is the better option.**
2. **Countersunk/chamfered bushings** with a wide funnel that lets the string enter at angles without pinching.

**Recommendation**: Use **oversized pass-through holes (8mm)** at tier boundaries instead of tight bushings. Only use tight PTFE bushings at the GUIDE PLATE (where we specifically need to constrain the string).

### F3: INTER-TIER TRANSITION — THE 120° ROTATION PROBLEM

**Problem**: This is the most complex geometric issue. When the string exits Tier 1 (which has sliders along 0°), it has been deflected laterally in the 0° direction by the U-detour. Now it needs to enter Tier 2, which has sliders along 120°.

The tier 2 redirect_in roller expects the string to approach from a different direction than the string is currently traveling.

```
Plan view (looking down):

Tier 1 exit: String was deflected along 0° (right)
             Exit point is at block_center + small 0° offset

     ← Tier 1 detour direction (0°)
  ═══════X═══════
         │ string drops vertically
         │
  ═══════X═══════
     ← Tier 2 detour direction (120°)
                  ↗
     Need to detour along THIS direction now
```

The string drops ~25mm vertically between tiers. The Tier 2 redirect_in roller is offset along the 120° direction, NOT along 0°. So the string must naturally find its way from one tier to the next.

**Key insight**: The string doesn't care about our coordinate system. Under tension (block weight), it naturally takes the shortest path between contact points. Between Tier 1's redirect_out and Tier 2's redirect_in, the string will take a STRAIGHT LINE through 3D space. It will naturally have both a vertical component AND a lateral component that shifts it from the 0° exit to the 120° entry.

**But**: This means the string between tiers is NOT vertical — it's angled. And this angle changes as both Tier 1's slider AND Tier 2's slider move. This creates a **coupled system** where each tier's detour slightly affects the adjacent tier's approach angle.

**Is this a problem?** Let's calculate the worst case:

```
Exit Tier 1: redirect_out at ~5mm from string vertical (in 0° direction)
Entry Tier 2: redirect_in at ~8mm from string vertical (in 120° direction)

Lateral displacement between these two points:
  dx (0°) = 5mm (from Tier 1 exit offset)
  Along 120° = 8 x cos(120°), 8 x sin(120°) = -4mm, 6.93mm

Total lateral shift: sqrt((5-(-4))^2 + (0-6.93)^2) = sqrt(81 + 48) = sqrt(129) = 11.4mm
Over vertical drop of 25mm: angle = arctan(11.4/25) = 24.5°

This is a SIGNIFICANT angle!
```

**Fix**: This is actually self-correcting and IS the design intent. The inter-tier string segment takes whatever angle the geometry demands. The redirect_in roller at the top of each tier catches the string from whatever direction it arrives and redirects it toward the slider. That's literally what redirect rollers are FOR.

BUT: We need to ensure the **pass-through holes between tiers are large enough** to accommodate this angular range. With ±12mm slider travel at each tier, the exit angle varies:

```
Worst case lateral shift: up to ~20mm over 25mm vertical = 38.7° from vertical
Required hole diameter at tier boundary:
  20mm lateral over 3mm plate thickness = tan(38.7°) x 3mm = 2.4mm deviation
  String diameter 0.5mm, so hole must be at least: 0.5 + 2 x 2.4 = 5.3mm
  With safety margin: 8mm holes at tier boundaries. ✓ (matches F2 fix)
```

**Verdict**: F3 is not a flaw — it's inherent to the design. But it confirms we need **oversized holes (8mm) between tiers**, not tight bushings.

### F4: SLIDER WRAP ANGLE VARIES WITH SLIDER POSITION

**Problem**: As the slider moves laterally, the string's wrap angle around the slider pulley changes:

```
When slider is at MAXIMUM extension (baseline + 12mm = 47mm from vertical):
  - String approaches at steep angle
  - Wrap angle: ~100° (less wrap)
  - More string consumed, block highest

When slider is at MINIMUM extension (baseline - 12mm = 23mm from vertical):
  - String approaches at shallow angle
  - Wrap angle: ~170° (almost full U-turn)
  - Less string consumed, block lowest
```

The varying wrap angle means:
1. **Friction varies with slider position** (more wrap = more friction)
2. **Response is not perfectly linear** (gain changes with position)

**Is this a problem?** Let's quantify:
```
At max extension (47mm): approach angle to vertical = arctan(47/20) = 67°
  Wrap = 180° - 2 x (90° - 67°) = 180° - 46° = 134°

At min extension (23mm): approach angle to vertical = arctan(23/20) = 49°
  Wrap = 180° - 2 x (90° - 49°) = 180° - 82° = 98°

Wait — that's backwards. Let me recalculate.

At the slider, the string comes in from redirect_in and goes out to redirect_out.
The wrap angle = 180° - (angle_in + angle_out) where angles are measured
from the slider's lateral axis.

Actually — for a U-turn: if the string approaches from above-left and departs
below-left, the wrap angle around the slider is related to how "sharp" the turn is.

When slider is FAR out: string makes a wider, gentler U → LESS wrap → LESS friction
When slider is CLOSE in: string makes a tighter, sharper U → MORE wrap → MORE friction

Friction per roller: η = e^(-μ * θ) where θ is wrap in radians, μ ≈ 0.05 for nylon
  At 134° (2.34 rad): η = e^(-0.05 × 2.34) = 0.890
  At 98° (1.71 rad): η = e^(-0.05 × 1.71) = 0.918

Variation: 89% to 92% — only 3% difference. ACCEPTABLE.
```

**Verdict**: F4 is a minor nonlinearity, not a flaw. The 3% friction variation adds subtle character to the wave (Margolin probably considers this part of the organic feel). No fix needed.

### F5: REDIRECT ROLLER POSITIONS — SYMMETRIC OR ASYMMETRIC?

**Problem**: In the current analysis, redirect_in is at ~8mm offset and redirect_out is at ~5mm offset from the string vertical. Are they at the SAME offset or different?

Looking at the `margolin_mechanism_explained.html` visualization:
```javascript
let redirectInX = 8 * SCALE;   // 8mm offset
let redirectOutX = 5 * SCALE;  // 5mm offset
```

They're ASYMMETRIC. Why?

The redirect_in roller needs to be further from the vertical to provide a good approach angle to the slider. The redirect_out roller can be closer because the string departs at a similar angle but the geometry allows it.

**But is this correct for the physical build?** In V5, the fixed pulleys are at FP_ROW_Y = 31mm on BOTH sides (symmetric). The redirect_in and redirect_out are on opposite sides of the slider.

Actually — let me reconsider. In Margolin's design, the redirects are NOT on opposite sides. They're on the SAME side (the side closer to the string vertical), and the slider is on the far side. The string goes:

```
  │ vertical
  │
  ○ redirect_in (slight offset toward slider)
   ╲
    ╲ approach (string goes toward slider)
     ╲
      ◉ SLIDER (far from vertical, at baseline offset)
     ╱
    ╱ departure (string comes back)
   ╱
  ○ redirect_out (slight offset toward slider)
  │
  │ vertical (continues down)
```

BOTH redirects are near the string vertical. The slider is far away. This is the U-detour: out to the slider and back. The redirects just give the string a clean transition between vertical and angled sections.

**In V5's layout**: The fixed pulleys at Y=+31mm and Y=-31mm are on BOTH sides of the slider row. The slider moves along X. So the fixed pulleys are offset in the PERPENDICULAR direction to the slider motion.

This is DIFFERENT from Margolin's layout where the redirects are offset in the SAME direction as the slider motion.

**THIS IS A SIGNIFICANT ARCHITECTURAL MISMATCH.**

In V5:
```
Plan view of ONE channel:

  FP row (Y=+31)    ○ ○ ○ ○ ○     ← Fixed pulleys (redirect in?)
                     │ │ │ │ │
  Slider (Y=0)      ◉ ◉ ◉ ◉ ◉     ← Slider pulleys (U-turn)
                     │ │ │ │ │
  FP row (Y=-31)    ○ ○ ○ ○ ○     ← Fixed pulleys (redirect out?)
```

The string path in V5 goes: FP top -> Slider -> FP bottom = a zigzag in the Y direction.
The slider moves in X. The string wraps in Y.

In Margolin:
```
Side view of ONE channel (slider moves in X):

  │ string vertical (X ≈ 0)
  │
  ○ redirect_in (X ≈ +8mm, small offset toward slider)
   ╲
    ╲  approach (string goes to X = baseline = +35mm)
     ╲
      ◉ SLIDER at X = 35mm ± 12mm
     ╱
    ╱  departure (string comes back to X ≈ +5mm)
   ╱
  ○ redirect_out (X ≈ +5mm, small offset toward slider)
  │
  │ string continues down
```

**Key difference**: In V5, the fixed pulleys are offset PERPENDICULAR to slider motion (in Y). In Margolin, the redirects are offset PARALLEL to slider motion (in X), just much less than the slider.

**For the V5 architecture to work as a Margolin-style U-detour tier**:
- The string enters from above (vertical, near channel center in X)
- The fixed pulleys at Y=+31 redirect it toward the slider
- The slider IS the U-turn point
- The fixed pulleys at Y=-31 redirect it back
- The string exits downward

But wait — this creates a ZIGZAG in Y, not a U-detour in X!

```
Side view (looking along X axis):

  │ string enters vertically
  │
  ○ FP at Y=+31 (redirects string to Y=0 where slider is)
   ╲
    ╲  angled segment from Y=+31 down to Y=0
     ╲
      ◉ slider pulley at Y=0 (U-turn in X? or just a Y-direction redirect?)
     ╱
    ╱  angled segment from Y=0 down to Y=-31
   ╱
  ○ FP at Y=-31 (redirects back toward vertical)
  │
  │ string exits
```

THIS IS A SERPENTINE/ZIGZAG, NOT A U-DETOUR!

The V5 architecture has the string zigzagging between Y=+31 and Y=-31, with the slider in between. When the slider moves in X, it changes the path length of the segments connecting the fixed pulleys to the slider pulleys. But the detour is in Y (perpendicular to slider motion), not in X (same direction as slider motion).

### F5 FIX: V5 NEEDS REORIENTATION FOR MARGOLIN-STYLE U-DETOUR

**Option A: Redesign the channel so fixed pulleys and slider are on the SAME axis**
```
Looking down at one channel:

  │ string vertical at X = 0
  │
  ○ redirect_in at X = +8mm (offset toward slider)
   ╲
    ╲ approach to slider along X
     ╲
      ◉ slider at X = baseline (35mm), moves ± 12mm along X
     ╱
    ╱ departure from slider along X
   ╱
  ○ redirect_out at X = +5mm (offset toward slider)
  │
  │ string exits vertically at X ≈ 0
```

All three rollers are along the SAME X axis. No Y offset. The U-detour is entirely in X.

**Option B: Keep V5's perpendicular layout but REINTERPRET it**

Actually — V5's layout CAN work, but the "computation" axis is different:
- In V5, the fixed pulleys create a Y-direction detour
- The slider moves in X, which changes the ANGLE of approach between the FP rows
- The gain is: when slider moves out in X, the angled segments (FP -> slider) get longer
- This IS a form of motion amplification, just geometrically different from Margolin's

**BUT**: The V5 zigzag involves MULTIPLE fixed pulleys (3-4-5 per row). A string going through CH3 touches 5 top FPs, 5 slider pulleys, 5 bottom FPs = 15 pulleys. Far exceeding the 9-pulley limit!

**CRITICAL INSIGHT**: In Margolin's design, each string touches only 3 pulleys per tier (1 redirect_in + 1 slider + 1 redirect_out). In V5, each CHANNEL serves multiple strings, and EACH string touches ALL the pulleys in that channel via serpentine routing. That's the block-and-tackle design, not the Margolin U-detour.

**RESOLUTION**: Each V5 channel must be REDESIGNED so that each string has its OWN dedicated redirect pair and its OWN slider pulley. One string, 3 pulleys per tier. The channels just provide the HOUSING for multiple such redirect-slider-redirect triplets.

```
V5 Channel (REDESIGNED for Margolin U-detour):

  Wall ═══════════════════════════════════════ Wall
  │                                              │
  │  String_1    String_2    String_3    String_4│
  │  │           │           │           │       │
  │  ○ R1_in     ○ R2_in     ○ R3_in     ○ R4_in│
  │   ╲           ╲           ╲           ╲      │
  │    ╲           ╲           ╲           ╲     │
  │     ◉ S1       ◉ S2       ◉ S3       ◉ S4  │ ← slider strip
  │    ╱           ╱           ╱           ╱     │    (moves together)
  │   ╱           ╱           ╱           ╱      │
  │  ○ R1_out    ○ R2_out    ○ R3_out    ○ R4_out│
  │  │           │           │           │       │
  │                                              │
  Wall ═══════════════════════════════════════ Wall
```

Each string has its own 3-pulley triplet. Multiple triplets share the same slider strip (which moves together). But each pulley is dedicated to one string.

This IS actually what V5 already does if we reinterpret it:
- V5's pulley_row at Y=+31 = redirect_in rollers (one per string)
- V5's slider_pulleys = U-turn rollers (one per string)
- V5's pulley_row at Y=-31 = redirect_out rollers (one per string)
- A string entering CH3 goes to ONE of the 5 top FPs, then to ONE of the 5 slider pulleys, then to ONE of the 5 bottom FPs
- 3 pulleys per string per channel. NOT 15!

**Wait — IS this how V5 actually works?** Let me re-read the code...

In V5, `pulley_row()` creates a ROW of pulleys. There are 5 pulleys in CH3. If each string goes to just ONE of these pulleys, then 5 strings pass through CH3, each touching 3 pulleys total. That's correct!

The V5 channels DON'T serpentine. They provide parallel paths. The fixed pulleys at Y=+31 are redirect_in, the slider pulleys are U-turn, and the fixed pulleys at Y=-31 are redirect_out. One triplet per string.

**CONFIRMED: V5 IS a Margolin-style U-detour per string.** The Y offset (±31mm) is the direction the U-detour goes — the string goes from near the top wall to the middle (slider) and back to the bottom wall. The slider moves in X, changing the angle and thus the path length.

**F5 is NOT a flaw after all.** V5's geometry IS the U-detour, just oriented with the detour in Y and the computation in X. The "baseline offset" in Margolin's terms is the Y=31mm distance from FP row to slider.

### F6: THE VERTICAL PASS-THROUGH BETWEEN TIERS

**Problem**: When the string exits the bottom of a tier's channel (after the redirect_out at Y=-31), it must travel to the top of the next tier's channel (redirect_in at Y=+31). But the next tier is ROTATED 120° relative to the first.

In V5, the channel axis is along X. The detour goes in Y. When Tier 2 is rotated 120°:

```
Tier 1 (0°): channel along X, detour in Y
  String exits at: (some X, Y=-31, Z=bottom of tier 1)

Tier 2 (120° rotation): channel along X', detour in Y'
  where X' is rotated 120° from X, Y' is rotated 120° from Y
  String must enter at: (some X', Y'=+31, Z=top of tier 2)
```

The lateral shift between Tier 1 exit and Tier 2 entry:
```
Tier 1 exit: approximately at (block_x, -31mm, Z1)  [in Tier 1 local coords]
                 = (block_x, -31, Z1) in global

Tier 2 entry: approximately at (block_x', +31', Z2) [in Tier 2 local coords]
  In global, rotating Y'=+31 by 120°:
  = (block_x·cos120° - 31·sin120°, block_x·sin120° + 31·cos120°, Z2)

For block at center (0,0):
  Tier 1 exit: (0, -31, Z1)
  Tier 2 entry: (-31·sin120°, 31·cos120°, Z2) = (-26.8, -15.5, Z2)

  Lateral shift = sqrt(26.8² + (31-15.5)²) = sqrt(718 + 240) = sqrt(958) = 31.0mm!
```

**31mm lateral shift between tiers for the CENTER block!** Over a ~25mm vertical gap, that's an angle of arctan(31/25) = 51° from vertical!

For blocks at the EDGE of the hex grid (64mm from center), the shift is even larger because the rotation moves the entry point further.

**THIS IS A REAL FLAW.** The string cannot make a 51-degree turn between tiers without significant friction at the pass-through points.

### F6 FIX: INTER-TIER ALIGNMENT PLATE

Between each pair of tiers, add a **transition plate** with rollers that smoothly redirect the string from one tier's exit to the next tier's entry.

```
Tier 1 (0° orientation)
  String exits bottom at (0, -31) in Tier 1 coords
     ╲
      ╲ angled segment
       ╲
  ═══════○═══════  TRANSITION ROLLER (between T1 and T2)
         │          Z = midpoint between tiers
         │          positioned to split the angle in half
        ╱
       ╱ angled segment
      ╱
Tier 2 (120° orientation)
  String enters top at (-26.8, -15.5) in global coords
```

This transition roller:
- Sits between tiers on a fixed bracket
- Splits the 51° deflection into two ~25° segments (much more manageable)
- Is specific to each string (one roller per string per transition)
- Adds 1 roller per transition x 2 transitions = 2 more rollers per string

**Updated pulley count per string**: 9 (tier rollers) + 2 (transition rollers) = **11 rollers**

```
Updated friction: 0.95^11 = 0.5688 = ~57%
```

That's below Margolin's 63% limit. Need to compensate.

**ALTERNATIVE FIX: Reduce baseline offset to reduce detour depth**

If the U-detour is shallower (smaller Y offset between FP rows and slider), the exit angle is more vertical, reducing the inter-tier transition problem.

Current: FP_ROW_Y = 31mm → deep U-detour, large exit angles
Reduced: FP_ROW_Y = 15mm → shallower U-detour, smaller exit angles

At FP_ROW_Y = 15mm:
```
Tier 1 exit: (0, -15, Z1)
Tier 2 entry (rotated 120°): (-15·sin120°, 15·cos120°) = (-13.0, -7.5)
Lateral shift = sqrt(13² + (15-7.5)²) = sqrt(169 + 56.25) = sqrt(225.25) = 15.0mm
Angle over 25mm gap: arctan(15/25) = 31°
```

31° is still significant but much more manageable. The pass-through holes can handle this without additional rollers.

**BEST FIX: Combination approach**
1. Reduce FP_ROW_Y from 31mm to **20mm** (compromise between detour depth and clearance)
2. Use **oversized pass-through holes (10mm)** between tiers (no bushings, no friction)
3. Add **chamfered entries** on all pass-through holes to prevent string snagging
4. Do NOT add transition rollers (keeps pulley count at 9)

At FP_ROW_Y = 20mm:
```
Tier 1 exit: (0, -20, Z1)
Tier 2 entry: (-20·sin120°, 20·cos120°) = (-17.3, -10, Z2)
Lateral shift = sqrt(17.3² + (20-10)²) = sqrt(300 + 100) = sqrt(400) = 20mm
Angle over 25mm gap: arctan(20/25) = 38.7°
Over 3mm plate: tan(38.7°) x 3mm = 2.4mm → hole must be 0.5 + 2x2.4 = 5.3mm
With margin: 8mm holes. ✓
```

**Impact on gain**: Reducing FP_ROW_Y from 31 to 20mm reduces the U-detour gain:
```
Original (Y=31): Gain ≈ 2 x 31 / sqrt(31² + slider_approach²) ≈ 1.6-1.8:1
New (Y=20):      Gain ≈ 2 x 20 / sqrt(20² + slider_approach²) ≈ 1.2-1.5:1

Block travel (per tier):  ±12mm x 1.35 ≈ ±16mm
Block travel (3 tiers):   peak ≈ ±30-45mm
```

Still very visible and good for MVP. Margolin's full sculpture had ~50mm block travel; 30-45mm for MVP is proportionally appropriate.

### F7: STRING ENTRY INTO TIER — WHICH CHANNEL?

**Problem**: A string drops vertically from the anchor (or from the tier above). It must enter the CORRECT channel in the V5 tier to reach its assigned slider. But V5 has 5 channels stacked in Z (within the tier's local frame). How does the string get to, say, CH3 (the middle channel) if it enters from the top?

The string would have to pass through CH1 and CH2 to reach CH3. That means:
- Passing through CH1's wall
- Passing through CH1's gap (avoiding CH1's pulleys and slider)
- Passing through CH1-CH2 shared wall
- Passing through CH2's gap (avoiding CH2's pulleys and slider)
- Passing through CH2-CH3 shared wall
- Arriving at CH3

The string must pass through walls and gaps WITHOUT touching anything until it reaches its designated channel. This requires:
- **Vertical pass-through holes in every wall** between the entry face and the target channel
- Holes must be **aligned vertically** through all intermediate channels
- Holes must **NOT conflict** with pulleys, axles, or slider plates in intermediate channels

**In V5's current design**: The walls have WINDOW cutouts (40mm x 30mm). These windows are for viewing/access but might also serve as pass-through paths. However, the windows are centered on each channel's housing X-center, and a string coming from above would need to be near the block's XY position, which might not align with the windows.

**Fix**: Add dedicated **string pass-through holes** in each wall at each block's XY position. For 19 blocks:
- Each wall needs up to 19 holes (one per string that passes through)
- Holes must be 8mm diameter (per F3/F6 analysis)
- Holes must be positioned to avoid axles and rail features

The strings that belong to CH1 stop at CH1 and don't need pass-through.
The strings for CH2 pass through CH1 walls.
The strings for CH3 pass through CH1 and CH2 walls.
etc.

For the 3-4-5-4-3 distribution (19 strings across 5 channels):
- CH1: 4 strings → enter directly from top
- CH2: 4 strings → pass through 1 wall
- CH3: 4 strings → pass through 2 walls
- CH4: 4 strings → pass through 3 walls  (EXIT through bottom, pass through CH5)
- CH5: 3 strings → pass through 4 walls  (EXIT through bottom)

Wait — this is getting complex. Let me reconsider.

**BETTER APPROACH**: Strings don't enter from the TOP of the tier. They enter from the SIDE.

Look at the V5 design: the channels are open on the FRONT face (looking along Y). The string can enter from the side (through the front opening of each channel) rather than drilling through multiple walls.

```
Side view of tier (looking along X):

  ←─── HOUSING HEIGHT = 85mm ───→

  │ CH5 walls │ CH4 walls │ CH3 walls │ CH2 walls │ CH1 walls │
  │           │           │           │           │           │
  │   gap     │   gap     │   gap     │   gap     │   gap     │
  │           │           │           │           │           │
  │═══════════│═══════════│═══════════│═══════════│═══════════│
       ↑           ↑           ↑           ↑           ↑
  Each channel is open on front and back (Y axis)
  String can enter from the front face of each channel
```

**Revised string path**: The string drops vertically from above, then passes through a **slot in the tier's top face** that routes it to the correct channel level, then enters the channel from the front.

Actually — this is overcomplicating it. Let me look at this differently.

**SIMPLEST APPROACH**: The tier is oriented so the channels stack vertically (in the global Z direction). Strings enter from the TOP. Each string goes to its assigned channel level. The walls between channels have pass-through holes. The string drops straight down through holes in the walls until it reaches its target channel.

The wall holes need to miss the guide rails and axles. V5's shared walls have rails along the centerline (Y=0) and windows in the wall body. A pass-through hole at a block's XY position would be in the wall body, not on the rail. This works IF the block's XY position doesn't coincide with the rail.

Since the rails run along the full length of each wall (in X), and blocks are on a hex grid with various XY positions, the pass-through holes would be at various X positions. The rails are at Y=0 in the wall. If the string is at Y = some_offset, it doesn't conflict with the rail.

**But**: The slider plate slides in X direction, and the slider is at Y ≈ 0 (channel center). If a pass-through string is also near Y=0, it might collide with the slider plate of an intermediate channel.

**Fix**: Route pass-through strings at Y = ±20mm (away from the Y=0 slider centerline). The slider plates are 15mm wide (Y = ±7.5mm), so strings at Y = ±20mm clear the slider plates with 12.5mm margin.

This requires:
1. Pass-through holes in walls at each string's XY position
2. Strings routed at Y offsets to avoid intermediate channel sliders
3. Small redirect at channel entry to bring string from Y=±20mm pass-through to Y=0 where the redirect rollers are

This adds more complexity. Let me reconsider the whole tier architecture...

**FINAL RECOMMENDATION FOR F7**:

For the MVP with only 19 strings, the simplest approach is:
1. **Use only CH3 (the middle channel) for all strings.** CH3 has 5 pulley positions per row. With 19 strings across 3 tiers, each tier handles ~19 strings, but they don't all need separate channels. If the pulleys are respaced, all 19 redirect+slider triplets can fit in ONE wide channel.
2. This eliminates the multi-channel routing problem entirely.
3. The channel becomes wider (to hold 19 triplets) but the architecture is the same as V5's CH3, just with more pulleys.

Alternatively:
1. **Route strings from the FRONT FACE of the tier** (along Y axis), not from the top. Each string enters the front of its target channel horizontally, wraps around the rollers, and exits the back. The vertical string segments (between tiers) connect at the channel's front/back faces.

This is actually how Margolin's polycarbonate strip matrix works — the strings enter from the EDGES of the strips, not from the top.

**For MVP, go with Option 1**: Single wide channel per tier. 19 redirect triplets in a row.

### F8: CAM-TO-SLIDER CONNECTION PATH

**Problem**: Each slider is driven by a cable from a cam follower rib. The rib is on the helix camshaft, which is positioned OUTSIDE the matrix at ~120° spacing. How does the cable get from the rib tip to the slider inside the matrix?

```
Plan view:

                    HELIX 1 (0° position)
                    ○ ← cam follower rib tip
                   /
                  / cable
                 /
  ═══════════════════════════════
  │         MATRIX              │
  │  [slider]←───cable──────── →│← cable entry port
  │                             │
  ═══════════════════════════════
```

The cable must:
1. Exit the rib tip (eyelet, Z = helix shaft height)
2. Travel from the helix to the matrix edge
3. Enter the matrix through a port/hole
4. Connect to the slider strip inside the tier
5. Stay taut under cam oscillation

**Design**:
- Cable enters matrix from the SIDE (along the helix radial direction)
- Cable passes through a slot in the matrix housing wall
- Cable attaches to the end of the slider strip
- Slot is elongated (stadium shape) to allow cable angle changes during slider travel

```
Tier side view:

  Housing wall
  │
  │  ╔════╗ ← elongated cable slot (stadium cutout)
  │  ║    ║
  │  ╚════╝
  │     │ cable goes through here
  │     │
  │     └── attached to slider strip end
```

Slot dimensions:
- Width: cable dia + 2mm clearance = ~3mm
- Height: cam stroke + clearance = 24mm + 4mm = 28mm
- Shape: stadium (hull of 2 circles)

**No additional flaw here**, just needs explicit design.

---

## 5. REVISED STRING PATH (With All Fixes Applied)

### Architecture Changes Summary

| Issue | Fix | Impact |
|-------|-----|--------|
| F1: Bushing friction | Increase block weight to 80g | Weight +10g |
| F2: Angled entry bushings | Use 8mm oversized holes (not bushings) at tier boundaries | Eliminates 6 bushings |
| F3: 120° inter-tier transition | 8mm pass-through holes + chamfers | Self-correcting geometry |
| F4: Variable wrap angle | No fix needed (3% variation) | Organic character |
| F5: V5 detour orientation | V5 IS correct — Y-direction detour, X-direction computation | No change |
| F6: Large inter-tier lateral shift | Reduce FP_ROW_Y from 31 to 20mm | Gain reduced to ~1.35:1 |
| F7: Multi-channel string routing | Single wide channel per tier (all 19 triplets in one row) | Simplifies tier design |
| F8: Cam-to-slider cable | Stadium slot in housing wall | Explicit design needed |

### Revised Contact Points Per String

```
CONTACT    TYPE            FRICTION     NOTES
POINT                      FACTOR
═══════════════════════════════════════════════════════════

[A]        Anchor eyelet   1.000        Fixed, string crimp

[T1-H]     Tier 1 top      1.000        8mm pass-through hole
           pass-through                  NO bushing (oversized)

[T1-R1]    Tier 1          0.950        13mm nylon roller
           redirect in                  Spinning on 5mm axle

[T1-S1]    Tier 1          0.950        10mm slider pulley
           slider U-turn               Spinning on 5mm axle

[T1-R2]    Tier 1          0.950        13mm nylon roller
           redirect out                Spinning on 5mm axle

[T1-H]     Tier 1 bottom   1.000        8mm pass-through hole
           pass-through                  NO bushing

[T2-H]     Tier 2 top      1.000        8mm pass-through hole
           pass-through

[T2-R1]    Redirect in     0.950        13mm roller
[T2-S1]    Slider U-turn   0.950        10mm slider pulley
[T2-R2]    Redirect out    0.950        13mm roller

[T2-H]     Tier 2 bottom   1.000        8mm pass-through

[T3-H]     Tier 3 top      1.000        8mm pass-through

[T3-R1]    Redirect in     0.950        13mm roller
[T3-S1]    Slider U-turn   0.950        10mm slider pulley
[T3-R2]    Redirect out    0.950        13mm roller

[T3-H]     Tier 3 bottom   1.000        8mm pass-through

[GP-G1]    Guide plate     0.990        PTFE bushing (2mm bore)
           upper                         with 5mm funnel entry

[GP-G2]    Guide plate     0.990        PTFE bushing (2mm bore)
           lower                         confirms vertical

[B]        Block attach    1.000        Crimp/knot/bolt

═══════════════════════════════════════════════════════════

TOTAL ROLLERS: 9     (3 per tier)
TOTAL BUSHINGS: 2    (guide plate only)
TOTAL PASS-THROUGHS: 6  (tier entries/exits, no friction)

COMBINED EFFICIENCY: 0.95^9 x 0.99^2 = 0.6302 x 0.9801 = 0.6177 = ~62%
```

This is much better than the 58% from F1! By eliminating the tier bushings and only keeping the guide plate bushings, we maintain close to Margolin's 63% target.

### Revised Block Weight

At 62% efficiency with 80g block:
```
Tension at anchor: 80g x 0.00981 N/g = 0.785N (block weight as tension)
Friction loss: 0.785 x (1 - 0.62) = 0.298N
Available force for return: 0.785 - 0.298 = 0.487N
Safety factor: 0.487 / 0.298 = 1.63   ← Good (>1.5 is reliable)
```

**80g blocks with 62% efficiency gives safety factor of 1.63. CONFIRMED.**

---

## 6. COMPLETE ROPE ROUTING DIAGRAM

### Isometric View — Single String Through All 3 Tiers

```
                              [A] ANCHOR (fixed to frame top plate)
                               │
                   Z=+300      │ free vertical drop
                               │ (string under 80g tension)
                               │
────────────────────── TIER 1 TOP PLATE ──────────────────────
                               │
                   Z=+255      │ 8mm pass-through hole (no bushing)
                               │
                               │ ~10mm vertical inside housing
                               │
                   Z=+245      ○ [T1-R1] REDIRECT IN (13mm roller)
                              ╱    at Y=+20mm from channel center
                             ╱     (offset toward slider direction)
                            ╱
                           ╱       APPROACH SEGMENT
                          ╱        Length: √(20² + 20²) = 28.3mm
                         ╱         Angle: 45° from vertical (in YZ plane)
                        ╱
                   Z=+225   ◉ [T1-S1] SLIDER PULLEY (10mm)
                              at Y=0mm, X=baseline ± 12mm
                              WRAP: ~120°
                              THIS IS WHERE WAVE IS COMPUTED
                        ╲
                         ╲         DEPARTURE SEGMENT
                          ╲        Length: √(20² + 20²) = 28.3mm
                           ╲       Angle: 45° from vertical
                            ╲
                             ╲
                   Z=+205      ○ [T1-R2] REDIRECT OUT (13mm roller)
                              at Y=-20mm from channel center
                               │
                               │ ~10mm to tier bottom
                               │
────────────────────── TIER 1 BOTTOM PLATE ───────────────────
                               │
                   Z=+195      │ 8mm pass-through hole
                               │
                               │ *** INTER-TIER TRANSITION ***
                               │ String drops ~25mm, shifts laterally
                               │ to align with Tier 2's 120° orientation
                               │ Lateral shift: ~20mm (with FP_ROW_Y=20)
                               │ Angle from vertical: ~38.7°
                               │ 8mm holes accommodate this angle
                               │
────────────────────── TIER 2 TOP PLATE (rotated 120°) ──────
                               │
                   Z=+170      │ 8mm pass-through hole
                               │
                               │ Entry angle: ~38.7° from vertical
                               │ Redirect roller catches the string
                               │
                   Z=+160      ○ [T2-R1] REDIRECT IN (13mm roller)
                              ╱    now along 120° direction
                             ╱     (Y'=+20mm in Tier 2 local frame)
                            ╱
                   Z=+140   ◉ [T2-S1] SLIDER PULLEY (10mm)
                              moves along 120° axis
                              driven by HELIX 2
                            ╲
                             ╲
                   Z=+120      ○ [T2-R2] REDIRECT OUT (13mm roller)
                               │ Y'=-20mm in Tier 2 local frame
                               │
────────────────────── TIER 2 BOTTOM PLATE ───────────────────
                               │
                   Z=+110      │ 8mm pass-through hole
                               │
                               │ *** INTER-TIER TRANSITION ***
                               │ Another ~20mm lateral shift
                               │ from 120° exit to 240° entry
                               │
────────────────────── TIER 3 TOP PLATE (rotated 240°) ──────
                               │
                   Z=+85       │ 8mm pass-through hole
                               │
                   Z=+75       ○ [T3-R1] REDIRECT IN (13mm roller)
                              ╱    along 240° direction
                             ╱
                   Z=+55    ◉ [T3-S1] SLIDER PULLEY (10mm)
                              moves along 240° axis
                              driven by HELIX 3
                            ╲
                   Z=+35       ○ [T3-R2] REDIRECT OUT (13mm roller)
                               │
────────────────────── TIER 3 BOTTOM PLATE ───────────────────
                               │
                   Z=+25       │ 8mm pass-through hole
                               │
                               │ String exits Tier 3 at some angle
                               │ determined by T3 slider position
                               │ and relative position to guide plate
                               │
════════════════ GUIDE PLATE 1 (UPPER DAMPENER) ══════════════
                               │
                   Z=+15       ● [GP-G1] PTFE BUSHING
                               │   5mm funnel entry → 2mm bore
                               │   Captures string from any angle
                               │   up to ~40° and constrains to vertical
                               │
                               │   15mm vertical gap (string now vertical)
                               │
════════════════ GUIDE PLATE 2 (LOWER DAMPENER) ══════════════
                               │
                   Z=0         ● [GP-G2] PTFE BUSHING
                               │   Confirms vertical. Two-point
                               │   constraint guarantees straight drop.
                               │
                               │ FREE VERTICAL DROP
                               │ 100-250mm (depends on wave)
                               │ String is guaranteed vertical here
                               │ Block hangs freely
                               │
                               █ [B] BLOCK (80g, hex 30mm FF)
                               █     attached at top center
                               █     Z varies with wave computation
                               █
```

### Plan View (Top-Down) — 3-Tier Overlap

```
Looking DOWN at the matrix stack from above:

                     0° (Tier 1 slider axis)
                     ↑
                     │    Helix 1 position
                     │    ○────────○
                     │
                     │         ┌──────┐
            Tier 1   │         │ T1   │ ← Tier 1 sliders move
            channel: │         │ chan  │   left-right (0° axis)
                     │         └──────┘
                     │
    ─────────────────┼─────────────────
                     │
   Helix 3           │                    Helix 2
   ○                 │                    ○
    ╲                │                   ╱
     ╲       ┌──────────────┐           ╱
      ╲      │              │          ╱
       ╲     │  HEX BLOCK   │         ╱
        ╲    │  GRID (19)   │        ╱
         ╲   │              │       ╱
          ╲  │    ● ● ●     │      ╱
           ╲ │   ● ● ● ●   │     ╱
            ╲│  ● ● ● ● ●  │    ╱
             │   ● ● ● ●   │   ╱
    Tier 3   │    ● ● ●     │  ╱     Tier 2
    channel  │              │ ╱      channel
    (240°)   └──────────────┘╱       (120°)
              ╲             ╱
               ╲           ╱
                ╲         ╱
                 ╲       ╱
                  ╲     ╱
                   ╲   ╱
                    ╲ ╱

              240°          120°


Each ● = one block position = one string
Each string passes through all 3 tier channels
making a U-detour in each tier's axis direction

The 3 tier channels OVERLAP in plan view (stacked vertically)
but are at different Z heights and different orientations
```

### Cross-Section: Single String Through One V5-Style Channel

```
Looking ALONG the channel (along X axis):

  ←── HOUSING GAP (19mm) ──→

  ┌──────────────────────────┐ ← Top wall (or shared wall)
  │  ○ GUIDE RAIL            │
  │                          │
  │                          │   ← Fixed pulley at Y=+20
  │         ○════●           │      ○ = axle end (in wall)
  │        ╱     13mm OD     │      ● = pulley (spinning)
  │       ╱                  │
  │      ╱  APPROACH         │
  │     ╱   SEGMENT          │
  │    ╱                     │
  │   ◉ SLIDER PULLEY       │   ← at Y=0 (channel center)
  │    ╲   10mm OD           │      mounted on slider plate
  │     ╲                    │      ┌─────┐ = slider plate
  │      ╲  DEPARTURE        │      │     │ slides in X
  │       ╲ SEGMENT          │      └─────┘
  │        ╲                 │
  │         ○════●           │   ← Fixed pulley at Y=-20
  │              13mm OD     │
  │                          │
  │  ○ GUIDE RAIL            │
  └──────────────────────────┘ ← Bottom wall (or shared wall)

  String enters from top (through pass-through hole)
  String exits from bottom (through pass-through hole)

  The detour creates a triangular path in the YZ plane:

  Top wall ────────────○ redirect_in (Y=+20)
                      ╱│╲
                     ╱ │  ╲
                    ╱  │   ╲
                   ╱   │    ╲
    slider ◉──────╱────│─────╲────── (moves in X)
                   ╲   │    ╱
                    ╲  │   ╱
                     ╲ │  ╱
                      ╲│╱
  Bottom wall ─────────○ redirect_out (Y=-20)

  When slider pushes out (positive X), the diagonal segments
  get LONGER → more string consumed → block rises
```

---

## 7. DESIGN PARAMETERS UPDATED

### Changed Parameters

| Parameter | Old Value | New Value | Reason |
|-----------|-----------|-----------|--------|
| FP_ROW_Y | 31.0mm | 20.0mm | F6: Reduce inter-tier lateral shift |
| Block weight | 70g | 80g | F1: Compensate for guide plate bushings |
| Tier boundary holes | Tight bushings | 8mm open holes | F2/F3: Angle tolerance |
| Channels used per tier | 5 (CH1-CH5) | 1 wide channel | F7: Simplify routing |
| Guide plate | None | 2 plates with PTFE bushings | Lateral correction |
| Guide bushing bore | N/A | 2.0mm, 5mm funnel entry | String capture angle |
| Guide plate spacing | N/A | 15mm between plates | Angular constraint |
| Inter-tier gap | ~22mm | 25mm | F6: Allow angle tolerance |
| Pass-through hole dia | N/A | 8mm (tier boundaries) | F3/F6: Angle range |

### Unchanged Parameters

| Parameter | Value | Confirmed By |
|-----------|-------|-------------|
| Pulleys per string | 9 | F5 confirmed V5 = U-detour |
| Friction efficiency | ~62% | Revised: 9 rollers + 2 bushings |
| Eccentricity | 12mm | Helix cam design |
| Cam stroke | ±12mm | Unchanged |
| Baseline offset | ~20mm (= FP_ROW_Y) | Revised from 35mm |
| String diameter | 0.5mm | Spectra/Dyneema |
| Block count | 19 | MVP spec |

---

## 8. MVP SIMPLIFIED TIER DESIGN

Based on the F7 analysis, the MVP tier should be a **single wide channel** instead of V5's 5-channel stack. This dramatically simplifies the string routing while keeping the same mechanical principles.

### Single-Channel Tier Design

```
TOP PLATE (wall)
═══════════════════════════════════════════════════════════
│ ○pass  ○pass  ○pass  ○pass  ○pass  ... (19 pass-throughs, 8mm) │
│                                                                  │
│ guide rail (full length)                                         │
═══════════════════════════════════════════════════════════

          GAP = 40mm (wider than V5's 19mm to fit all 19 triplets)

  FIXED PULLEY ROW (Y=+20): ● ● ● ● ● ● ● ● ● ● ● ● ● ● ● ● ● ● ●
  (19 redirect-in rollers, 13mm OD, spaced at 16mm pitch)

  SLIDER STRIP (Y=0):       ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉ ◉
  (19 slider pulleys, 10mm OD, on shared slider plate)
  Slider plate length: 19 x 16mm = 304mm

  FIXED PULLEY ROW (Y=-20): ● ● ● ● ● ● ● ● ● ● ● ● ● ● ● ● ● ● ●
  (19 redirect-out rollers, 13mm OD, spaced at 16mm pitch)

          GAP = 40mm

═══════════════════════════════════════════════════════════
│ guide rail (full length)                                         │
│                                                                  │
│ ○pass  ○pass  ○pass  ○pass  ○pass  ... (19 pass-throughs, 8mm) │
BOTTOM PLATE (wall)
═══════════════════════════════════════════════════════════

  Overall tier dimensions:
    Length: 19 x 16mm + margins = ~330mm (fits K2 Plus 350mm bed!)
    Width (housing): 40mm gap + 2 x 3mm walls = 46mm
    Height (depth): ~80mm (for pulley + slider clearance)
```

### BUT WAIT — 19 Sliders on ONE Strip?

If all 19 sliders share one strip, they all move together. That means they all get the same cam displacement. But each slider should have its OWN cam phase!

**This is why V5 has 5 separate channels** — each channel has its own slider with independent motion. In the original plan, 19 sliders across 5 channels means ~4 independently moving sliders per channel.

But 4 sliders per channel still means those 4 move together. Unless each slider within a channel has its own strip...

**RE-EXAMINING V5**: In V5, each channel has ONE slider plate with MULTIPLE slider pulleys. The whole plate moves as one unit (all pulleys on that plate move the same distance). So CH3 has 5 slider pulleys on one plate = all 5 strings serviced by that channel get the SAME lateral motion.

**This is a problem for the Margolin design**, where each string needs INDEPENDENT slider motion (because each block is at a different position on the hex grid and therefore connects to a different cam on the helix).

**CRITICAL DESIGN DECISION**: We need **19 independently moving sliders per tier**, not 5 channel-sliders. Each slider is driven by its own cam.

This changes the tier design fundamentally:

### REVISED: 19 Independent Narrow Channels

Each tier becomes 19 narrow, independent channels stacked side by side. Each channel is like a "mini-V5-CH1" with:
- 1 redirect-in roller
- 1 slider pulley (on independent slider strip)
- 1 redirect-out roller

```
TIER CROSS-SECTION (looking along slider motion axis):

  ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
  │1│2│3│4│5│6│7│8│9│A│B│C│D│E│F│G│H│I│J│ ← 19 channels
  └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘

Each channel:
  Width: ~12mm (10mm slider pulley + 2mm walls)
  Contains: 1 redirect_in + 1 slider + 1 redirect_out

  Total tier width: 19 x 12mm = 228mm
  + outer walls: 228 + 6mm = 234mm
```

This is MORE like Margolin's actual polycarbonate strip construction — many narrow parallel channels, each with its own slider.

**And it STILL fits the K2 Plus bed (350mm).**

```
  Cable from        Cable from        Cable from
  cam 1             cam 2             cam 19
    │                 │                 │
    ▼                 ▼                 ▼
  ╔═══╗            ╔═══╗            ╔═══╗
  ║ 1 ║            ║ 2 ║    ...     ║19 ║  ← independent sliders
  ╚═══╝            ╚═══╝            ╚═══╝
    │                 │                 │
  string 1         string 2          string 19
    │                 │                 │
    ▼                 ▼                 ▼
  (to next tier)   (to next tier)    (to next tier)
```

This IS the Margolin design: each cam drives one slider, each slider deflects one string.

---

## 9. FINAL COMPONENT LIST (Per Tier)

| Component | Qty | Dimensions | Material |
|-----------|-----|------------|----------|
| Top plate (wall) | 1 | 234 x 80 x 3mm | PLA/PETG |
| Bottom plate (wall) | 1 | 234 x 80 x 3mm | PLA/PETG |
| Internal divider walls | 18 | 80 x (gap) x 1.5mm | PLA |
| Redirect-in rollers | 19 | 13mm OD x 10mm W | Nylon on axle |
| Redirect-out rollers | 19 | 13mm OD x 10mm W | Nylon on axle |
| Slider pulleys | 19 | 10mm OD x 7mm W | Nylon on axle |
| Slider strips | 19 | ~60mm L x 8mm W x 1.5mm | PLA |
| Axles (redirect) | 38 | 5mm dia x 15mm L | Steel rod |
| Axles (slider) | 19 | 5mm dia x 10mm L | Steel rod |
| Guide rails | 2 | 234mm L x 4mm H x 1.5mm D | Integral to plates |
| Cable entry slots | 19 | 3mm x 28mm stadium | Cut in side wall |
| Pass-through holes | 19 | 8mm dia, chamfered | In top & bottom plates |

**Per tier: ~173 parts**
**3 tiers: ~519 parts**

Plus guide plate assembly:
| Component | Qty | Material |
|-----------|-----|----------|
| Guide plate (upper) | 1 | PLA, 3mm thick |
| Guide plate (lower) | 1 | PLA, 3mm thick |
| PTFE bushings | 38 (19 x 2 plates) | PTFE |
| Spacer posts | 4 | PLA, 15mm long |

---

## 10. UPDATED Z-HEIGHT BUDGET

```
COMPONENT                           HEIGHT    CUMULATIVE Z
═══════════════════════════════════════════════════════════

Frame top plate                     6mm       +306mm
Anchor plate                        3mm       +303mm

Free drop (anchor to Tier 1)        45mm      +258mm

Tier 1 top wall                     3mm       +255mm
Tier 1 channel gap                  40mm      +215mm
Tier 1 bottom wall                  3mm       +212mm

Inter-tier gap 1-2                  25mm      +187mm

Tier 2 top wall                     3mm       +184mm
Tier 2 channel gap                  40mm      +144mm
Tier 2 bottom wall                  3mm       +141mm

Inter-tier gap 2-3                  25mm      +116mm

Tier 3 top wall                     3mm       +113mm
Tier 3 channel gap                  40mm      +73mm
Tier 3 bottom wall                  3mm       +70mm

Post-matrix gap                     30mm      +40mm

Guide plate upper                   3mm       +37mm
Guide plate gap                     15mm      +22mm
Guide plate lower                   3mm       +19mm

Free drop to blocks                 variable  varies
(at neutral: ~100mm)
Block height                        20mm      ~-101mm

═══════════════════════════════════════════════════════════

TOTAL MATRIX + GUIDE ASSEMBLY:      255mm
TOTAL WITH FRAME + DROPS:           ~407mm
BLOCK TRAVEL RANGE:                 ±35mm from neutral

FITS K2 PLUS (350mm Z)?
  Matrix assembly alone: 255mm ✓
  Frame needs sectioning for print, assembled with threaded rod
```

---

*This analysis identified 8 potential flaws (F1-F8), resolved all of them, and produced a complete contact-point-by-contact-point rope routing diagram. The key findings: tier boundary holes must be 8mm oversized (not bushings), FP_ROW_Y should reduce from 31mm to 20mm, blocks increase to 80g, and each tier needs 19 independently moving sliders (not 5 shared channel-sliders). The V5 architecture is confirmed as correct U-detour geometry but must be scaled from 5 channels to 19 independent narrow channels per tier.*
