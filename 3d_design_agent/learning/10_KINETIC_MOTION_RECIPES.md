# Kinetic Sculpture Motion Recipe Book

**For artists who think in movement, not equations.**

Each recipe gives you starting link lengths. Plug them into the `linkage_explorer.ipynb` notebook, tweak until it feels right, then export to OpenSCAD.

---

## How to Read These Recipes

```
GROUND  = distance between your two fixed pivot points (your frame)
CRANK   = input arm (motor attaches here)
COUPLER = the floating bar (magic happens here)
ROCKER  = output arm (your sculpture element)

Ratio format: GROUND : CRANK : COUPLER : ROCKER
Example: 100 : 30 : 80 : 70 means ground=100mm, crank=30mm, etc.
```

**Scale freely** — multiply all four numbers by the same factor to make bigger/smaller.

---

## Part 1: Nature Motions

### 🌲 Gentle Tree Sway (Cypress in Breeze)

**The feeling:** Slow, hypnotic side-to-side. Calming. Like watching trees on a calm day.

```
Ratio:  100 : 15 : 85 : 95
Scale:  Ground=100mm gives ~12° rocker swing

Why it works:
- Very short crank (15) = subtle input motion
- Long rocker (95) = small angular output
- Creates slow, gentle oscillation
```

**Coupler point:** 0.5 (middle)
**Motor speed:** 2-5 RPM
**Best for:** Single trees, reeds, tall grasses

---

### 🌊 Rolling Ocean Wave

**The feeling:** Continuous, flowing motion. Each wave crest rises, peaks, falls.

```
Ratio:  100 : 25 : 90 : 80
Scale:  Ground=100mm gives ~18° swing

Why it works:
- Moderate crank creates visible but smooth motion
- Coupler slightly longer than rocker = rounder path
```

**Coupler point:** 0.3-0.4 (closer to crank end)
**Motor speed:** 3-8 RPM
**Best for:** Wave banks, water surfaces

**For multiple waves:** Use same linkage, offset crank angles by 30-45° per wave layer.

---

### 🦅 Bird Wing Flap (Soaring)

**The feeling:** Majestic, slow beats. Not frantic — think eagle, not hummingbird.

```
Ratio:  80 : 20 : 70 : 85
Scale:  Ground=80mm gives ~15° swing

Why it works:
- Short crank = controlled input
- Long rocker = the wing, pivots near body
- Rocker swing becomes wing arc
```

**Coupler point:** N/A (rocker IS the output)
**Motor speed:** 1-3 RPM
**Best for:** Large birds, angels, flying creatures

**For faster flap (small birds):**
```
Ratio:  60 : 30 : 55 : 50
Motor:  8-15 RPM
```

---

### 🌸 Flower Bloom / Breathing

**The feeling:** Gentle open-close. Organic. Like a flower tracking the sun or slow breathing.

```
Ratio:  100 : 20 : 95 : 90
Scale:  Ground=100mm gives ~10° swing

Why it works:
- Very subtle motion (short crank, long everything else)
- Almost imperceptible movement that draws you in
```

**Coupler point:** 0.5
**Motor speed:** 0.5-2 RPM (very slow!)
**Best for:** Flowers, breathing chests, subtle life indicators

---

### 🐟 Fish Swimming (S-Curve Body)

**The feeling:** Sinuous, flowing. The body curves one way, then the other.

```
Primary linkage (body front):
Ratio:  80 : 25 : 75 : 65

Secondary linkage (body rear, 180° offset):
Same ratio, crank mounted opposite

Why it works:
- Two linkages in anti-phase create S-curve
- Each section bends opposite to the other
```

**Motor speed:** 5-10 RPM
**Best for:** Fish, snakes, eels, dragons

---

## Part 2: Mechanical / Industrial Motions

### ⚙️ Nodding Donkey (Oil Pump)

**The feeling:** Industrial, rhythmic. The classic "drinking bird" motion.

```
Ratio:  100 : 35 : 110 : 90
Scale:  Ground=100mm gives ~25° swing

Why it works:
- Longer coupler than ground creates the characteristic "nod"
- Clear mechanical aesthetic
```

**Coupler point:** 1.0 (at the rocker joint)
**Motor speed:** 5-15 RPM
**Best for:** Industrial scenes, steampunk, mechanical creatures

---

### 🎪 Walking Motion (Theo Jansen Style)

**The feeling:** Uncanny, creature-like walking. Legs that lift, swing, plant.

```
Jansen's magic numbers (don't change these ratios!):
a = 38.0   (crank)
b = 41.5   (first link)
c = 39.3   (second link)
d = 40.1   (third link)
e = 55.8   (leg upper)
f = 39.4   (leg lower)
g = 36.7   (ground offset)
h = 65.7   (hip height)

Simplified four-bar approximation:
Ratio:  100 : 38 : 90 : 75
```

**Note:** True Jansen linkage is an 8-bar, not 4-bar. The four-bar gives similar feel but simpler.

**Motor speed:** 10-30 RPM
**Best for:** Walking creatures, strandbeests, mechanical animals

---

### 🔨 Hammering / Pecking

**The feeling:** Quick down-stroke, slower return. Like a blacksmith or woodpecker.

```
Ratio:  100 : 40 : 85 : 60
Scale:  Ground=100mm gives ~35° swing

Why it works:
- Larger crank = more dramatic motion
- Shorter rocker = amplified angular movement
- Asymmetric motion due to linkage geometry
```

**Coupler point:** 0.8 (closer to rocker end)
**Motor speed:** 15-40 RPM
**Best for:** Blacksmiths, woodpeckers, stamping machines

---

## Part 3: Abstract / Artistic Motions

### ∞ Figure-Eight Path

**The feeling:** Mesmerizing infinity loop. A point traces ∞ in space.

```
Ratio:  100 : 45 : 120 : 70
Scale:  Ground=100mm

Why it works:
- Coupler longer than ground
- Specific ratio creates the crossover point
```

**Coupler point:** 0.5 exactly (critical!)
**Motor speed:** 3-8 RPM
**Best for:** Hypnotic displays, meditation pieces, abstract art

---

### 🫘 Bean / Kidney Path

**The feeling:** Organic blob shape. Not circular, not straight — interestingly curved.

```
Ratio:  100 : 30 : 85 : 75
Scale:  Ground=100mm

Why it works:
- Balanced proportions create smooth but non-circular path
```

**Coupler point:** 0.6-0.7
**Motor speed:** 2-6 RPM
**Best for:** Organic shapes, cellular imagery, abstract motion

---

### 💫 Extended Tracer (Wild Curves)

**The feeling:** Dramatic, sweeping arcs that extend beyond the mechanism.

```
Ratio:  100 : 35 : 95 : 80
Scale:  Ground=100mm

The secret: Coupler point = 1.5 or higher!
(This means your traced point is on an EXTENSION of the coupler bar)
```

**Coupler point:** 1.3-2.0 (extended beyond coupler)
**Motor speed:** 2-5 RPM
**Best for:** Dramatic gestures, reaching motions, theatrical pieces

---

## Part 4: Multi-Element Compositions

### 🌊🌊🌊 Wave Train (3 Layers)

**The feeling:** Ocean depth. Foreground waves move differently than background.

```
All three use same base:
Ratio:  100 : 25 : 90 : 80

Layer 1 (front):  Crank at 0°,   amplitude 100%
Layer 2 (mid):    Crank at 40°,  amplitude 80% (scale down)
Layer 3 (back):   Crank at 80°,  amplitude 60% (scale down more)
```

**Single motor:** Use different crank arm lengths from same shaft
**Best for:** Ocean scenes, rolling hills, crowd movements

---

### 🌲🌲 Forest Sway (Multiple Trees)

**The feeling:** Each tree sways slightly differently. Natural variation.

```
Base ratio:  100 : 15 : 85 : 95

Tree 1: Crank at 0°
Tree 2: Crank at 25°, ground scaled to 95
Tree 3: Crank at 50°, ground scaled to 105
Tree 4: Crank at 75°, ground scaled to 98
```

**Key:** Slight variations in ground length create subtle timing differences
**Best for:** Forests, grass fields, coral reefs

---

### 🎭 Call and Response (Two Figures)

**The feeling:** One figure moves, the other responds. Conversation in motion.

```
Figure A:  100 : 30 : 80 : 70  (initiator)
Figure B:  100 : 30 : 80 : 70  (responder)

Crank offset: 180° (exact opposition)
OR
Crank offset: 90° (quarter-phase delay)
```

**Best for:** Dancing couples, arguing figures, mirror reflections

---

## Part 5: Quick Reference Table

| Motion | Ratio (G:C:Co:R) | Swing | Speed | Coupler Pt |
|--------|------------------|-------|-------|------------|
| Gentle sway | 100:15:85:95 | ~12° | 2-5 | 0.5 |
| Ocean wave | 100:25:90:80 | ~18° | 3-8 | 0.3-0.4 |
| Bird wing (soar) | 80:20:70:85 | ~15° | 1-3 | N/A |
| Bird wing (flap) | 60:30:55:50 | ~25° | 8-15 | N/A |
| Breathing | 100:20:95:90 | ~10° | 0.5-2 | 0.5 |
| Nodding | 100:35:110:90 | ~25° | 5-15 | 1.0 |
| Hammering | 100:40:85:60 | ~35° | 15-40 | 0.8 |
| Figure-8 | 100:45:120:70 | N/A | 3-8 | 0.5 |
| Wild curves | 100:35:95:80 | N/A | 2-5 | 1.5+ |

---

## Part 6: Troubleshooting

### "My linkage locks up at certain angles"
- You have a **non-Grashof** linkage
- Fix: Make sure `shortest + longest < sum of other two`
- Usually: Make crank shorter, or ground longer

### "Motion is too jerky"
- Transmission angle is going bad (too acute or obtuse)
- Fix: Adjust coupler length until motion smooths out
- Keep transmission angle between 40°-140°

### "Motion is too subtle / can't see it"
- Crank is too short relative to other links
- Fix: Increase crank length (but watch Grashof condition)

### "Motion is too violent / dramatic"
- Crank is too long, or rocker is too short
- Fix: Shorten crank OR lengthen rocker

### "The path isn't the shape I want"
- Coupler point position changes everything
- Try: Move coupler point from 0 to 1.5 in 0.1 increments
- Try: Extend beyond coupler (1.2, 1.5, 2.0)

---

## Part 7: From Recipe to OpenSCAD

Once you've found your motion in the notebook:

```python
# In the notebook, run:
export_to_openscad(100, 30, 80, 70, 0.5, 'my_motion.scad')
```

This gives you:
1. The coupler curve as polygon points
2. Link length constants
3. Fixed pivot positions

Then in OpenSCAD:
```openscad
include <my_motion.scad>

// Your sculpture element follows the coupler_curve path
// Animate with $t to show motion
```

---

## Next Steps

1. **Open `linkage_explorer.ipynb`** in Jupyter
2. **Pick a recipe** that matches your vision
3. **Plug in the numbers**, adjust to taste
4. **Export** when satisfied
5. **Build in OpenSCAD** with the exported coordinates

The notebook is your playground. These recipes are starting points. Trust your eye — if it looks right, it IS right.

---

## Part 8: Cam Recipes

📖 **Primary Reference:** Robert Addams, "Automata Design", p.8-15 (complete cam chapter with diagrams)
📖 **Secondary Reference:** Making Things Move, p.240-242 (cam types explained)

Cams convert rotation into precisely controlled linear motion. Unlike four-bar linkages, cams let you design *exactly* the motion profile you want.

### 🐌 Snail Cam (Gradual Rise, Sudden Drop)

**The feeling:** Slow build-up, dramatic release. Like a roller coaster climbing then dropping.

```
Profile: Spiral from center outward, then drops back
📖 See: Robert Addams p.9-10 (exact contour diagram)

Use when:
- You want anticipation before action
- "Breathing in" then sudden exhale
- Dramatic reveals
```

**Follower type:** Flat or roller
**Best for:** Jack-in-the-box, surprise reveals, dramatic gestures

---

### 🔘 Lobed Cam (Dwell Periods)

**The feeling:** Move-pause-move-pause. Controlled timing with rest periods.

```
Profile: Circular with flat sections
📖 See: Robert Addams p.10 (dwell angle explained)

Dwell angle determines pause length:
- 30° dwell = short pause
- 90° dwell = quarter-turn pause
- 180° dwell = half-turn pause
```

**Best for:** Mechanical sequences, typewriter actions, indexing

---

### 💧 Drop Cam (Quick Return)

**The feeling:** Slow rise, instant fall. Hammer strikes.

```
Profile: Gradual slope up, vertical drop
📖 See: Robert Addams p.10

Why it works:
- Slope controls rise speed
- Vertical edge = instantaneous return
```

**Best for:** Pecking birds, hammers, stamping motions

---

### ⚙️ Multi-Lobe Cam (Multiple Actions per Rotation)

**The feeling:** Several events per crank turn.

```
Profile: 2-4 bumps around circumference
📖 See: Robert Addams p.9

Lobes:
- 2 lobes = 2 actions per turn
- 3 lobes = 3 actions per turn
- 4 lobes = 4 actions per turn
```

**Best for:** Walking sequences, multiple synchronized actions

---

### 📖 Cam Types Quick Reference

| Cam Type | Book Reference | Best For |
|----------|----------------|----------|
| Edge/Disk Cam | Making Things Move p.240 | Simple up-down |
| Cylindrical Cam | Making Things Move p.241 | Rotary output |
| Barrel Cam | Making Things Move p.242 | Complex programs |
| Snail Cam | Robert Addams p.9-10 | Rise-drop |
| Heart Cam | Robert Addams p.9 | Constant velocity |

---

## Part 9: Lever & Motion Redirects

📖 **Primary Reference:** Robert Addams p.45-47 (lever classes with diagrams)
📖 **Secondary Reference:** Making Things Move p.22-27 (lever mechanics)

### 🔔 Bell Crank (90° Redirect)

**The feeling:** Change direction. Horizontal input becomes vertical output.

```
📖 See: Making Things Move p.249, Fig 8-11

Configuration:
- L-shaped lever
- Pivot at the corner
- Input on one arm, output on the other
```

**Use when:** Your motor is horizontal but you need vertical motion (or vice versa)

---

### ⚖️ Lever Classes

📖 **See:** Robert Addams p.45-47 for diagrams of all three classes

| Class | Pivot Position | Example | Mechanical Advantage |
|-------|---------------|---------|---------------------|
| 1st | Between effort & load | See-saw, balance | Can amplify or reduce |
| 2nd | Load between pivot & effort | Wheelbarrow, nutcracker | Always amplifies |
| 3rd | Effort between pivot & load | Tweezers, fishing rod | Always reduces (but increases speed) |

**Key insight:** 1st class levers can reverse direction; 2nd and 3rd cannot.

---

### 🔄 Scotch Yoke (Pure Sinusoidal)

**The feeling:** Perfect sine wave. No distortion.

```
📖 See: Making Things Move p.247, Fig 8-10

Unlike slider-crank:
- Output is PURE sine wave
- No connecting rod angle distortion
- Smoother at high speeds
```

**Best for:** When you need mathematically pure oscillation

---

### ⚡ Quick Return Mechanism

**The feeling:** Slow forward stroke, fast return stroke.

```
📖 See: Making Things Move p.249, Fig 8-13

Ratio examples:
- 2:1 = return twice as fast as forward
- 3:1 = return three times as fast
```

**Best for:** Machining motions, aggressive pecking, power strokes

---

## Part 10: One-Way & Intermittent Motion

📖 **Primary Reference:** Making Things Move p.246-249
📖 **Secondary Reference:** Robert Addams p.31-34 (ratchets)

### 🔒 Ratchet & Pawl (One-Way Rotation)

**The feeling:** Click-click-click. Forward only.

```
📖 See: Making Things Move p.246, Fig 8-9
📖 See: Robert Addams p.31-34 (detailed examples)

Components:
- Ratchet wheel (toothed)
- Pawl (the finger that catches)
- Spring (keeps pawl engaged)
```

**Use when:** You need to prevent backsliding, accumulate motion, or wind springs

---

### ⏱️ Geneva Stop (Intermittent Indexing)

**The feeling:** Stop-turn-stop-turn. Precise discrete positions.

```
📖 See: Making Things Move p.249, Fig 8-12

Positions per rotation:
- 4-slot Geneva = 4 stops per wheel turn
- 6-slot Geneva = 6 stops per wheel turn
```

**Best for:** Film projectors, rotary indexing, discrete position displays

---

## Part 11: Motion Conversion Cheat Sheet

📖 **CRITICAL REFERENCE:** Making Things Move p.248, Table 8-1

This table shows how to convert between motion types:

| FROM ↓ / TO → | Rotary | Oscillating | Linear | Reciprocating |
|---------------|--------|-------------|--------|---------------|
| **Rotary** | Gears | Crank-rocker | Rack & pinion | Crank-slider |
| **Oscillating** | Ratchet | Linkage | Cam | Linkage |
| **Linear** | Rack & pinion | Cam | Pulley | Cam |
| **Reciprocating** | Ratchet | Linkage | Direct | Cam |

**When stuck:** Find your input type in left column, desired output in top row, intersection shows mechanism!

---

## Part 12: Bio-Inspired Linkages

📖 **Reference:** "Linkage mechanisms in animal joints" paper in `/archives/docs/`

Nature has been optimizing linkages for millions of years. These ratios come from real animals.

### 🦵 Mammalian Knee (Inverted Four-Bar)

```
📖 See: animal joints paper, p.3, Fig 2

Key insight: The knee is NOT a simple hinge!
- It's a crossed four-bar linkage
- Allows rolling + sliding motion
- Prevents dislocation under load
```

**Use when:** You need a joint that's stable under varying loads

---

### 🦅 Bird Wing (Pantograph Style)

```
📖 See: animal joints paper, p.4, Fig 3

Key insight: Wings fold automatically
- Four-bar linkage couples shoulder to elbow
- Folding one joint folds both
- Single actuator controls entire wing
```

**Use when:** You need synchronized folding/unfolding

---

### 🦗 Insect Wing (Short Coupler)

```
📖 See: animal joints paper, p.4, Fig 4

Key insight: Short coupler = AMPLIFIED motion
- Tiny muscle movement → Large wing arc
- Coupler much shorter than other links
- High frequency capable
```

**Ratio hint:** Make coupler 1/3 the length of rocker for 3× motion amplification

---

### 🐟 Fish Jaw (Kinematic Amplification)

```
📖 See: animal joints paper, p.5-8

Key insight: Four-bar jaw creates SUCTION
- Rapid jaw opening creates negative pressure
- Prey gets sucked in, not bitten
- Output displacement >> input displacement
```

**The secret:** Short coupler link + strategic pivot placement = motion amplification

---

## Part 13: Historical Techniques

📖 **Reference:** AUTOMATA_MASTERS.md in `/archives/docs/`

### 📜 Cam Barrel (Multi-Track Programming)

```
📖 See: AUTOMATA_MASTERS.md - Jaquet-Droz section

What it is:
- Cylinder with bumps/grooves
- Multiple tracks control multiple outputs
- Like a music box but for motion
```

**Use when:** You need complex, repeating sequences

---

### 🎭 Weight-Driven Power

```
📖 See: Robert Addams - historical sections
📖 See: AUTOMATA_MASTERS.md - David C. Roy

How it works:
- Falling weight provides energy
- Gear train controls speed
- Can run for hours on single wind
```

**Modern equivalent:** Spring motor or battery + gearbox

---

## Book Quick Reference

| Topic | Robert Addams | Making Things Move | Animal Joints |
|-------|---------------|-------------------|---------------|
| Cams | p.8-15 | p.240-242 | - |
| Cranks | p.16-20 | p.258-259 | - |
| Gears | p.21-30 | p.231-245 | - |
| Ratchets | p.31-34 | p.246 | - |
| Pulleys | p.35-38 | p.246-247 | - |
| Linkages | p.39-41 | p.262-265 | p.1-15 |
| Levers | p.45-47 | p.22-27 | - |
| Young kids | p.64-69 | p.272-273 | - |
| Motion conversion | - | p.248 (TABLE!) | - |

---

## Next Steps

1. **Open `linkage_explorer.ipynb`** in Jupyter
2. **Pick a recipe** that matches your vision
3. **Plug in the numbers**, adjust to taste
4. **Export** when satisfied
5. **Build in OpenSCAD** with the exported coordinates

The notebook is your playground. These recipes are starting points. Trust your eye — if it looks right, it IS right.
