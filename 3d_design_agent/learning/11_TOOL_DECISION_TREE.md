# Kinetic Sculpture Tool Decision Tree

**Quick reference: "I want to do X" → "Use this tool"**

---

## The Main Question: What Do You Have vs What Do You Need?

```
START HERE
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│  What do you have RIGHT NOW?                                    │
└─────────────────────────────────────────────────────────────────┘
    │
    ├─── "I have an IDEA for a motion (words/sketch)"
    │         │
    │         ▼
    │    Go to: IDEATION TOOLS (Section 1)
    │
    ├─── "I have a PATH/CURVE I want a point to trace"
    │         │
    │         ▼
    │    Go to: SYNTHESIS TOOLS (Section 2)
    │
    ├─── "I have LINK LENGTHS and want to see the motion"
    │         │
    │         ▼
    │    Go to: SIMULATION TOOLS (Section 3)
    │
    ├─── "I have a WORKING LINKAGE and need to build it in CAD"
    │         │
    │         ▼
    │    Go to: CAD TOOLS (Section 4)
    │
    └─── "I have a CAD MODEL and want to make it physical"
              │
              ▼
         Go to: FABRICATION (Section 5)
```

---

## Section 1: IDEATION TOOLS

**Situation:** You have a vague idea like "hummingbird wings" or "gentle wave"

```
What kind of motion?
    │
    ├─── "Oscillating back-and-forth"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ USE: KINETIC_MOTION_RECIPES.md          │
    │    │ Look for: sway, nod, swing recipes      │
    │    │ THEN: Go to Section 3 (Simulation)      │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Continuous rotation → oscillating output"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ USE: Four-bar linkage                   │
    │    │ Recipe: "crank-rocker" type             │
    │    │ THEN: Go to Section 3 (Simulation)      │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Point traces a specific curved path"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ DRAW the path on paper                  │
    │    │ THEN: Go to Section 2 (Synthesis)       │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Complex organic motion (walking, swimming)"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ DECOMPOSE into simpler motions first    │
    │    │ USE: Claude to help break it down       │
    │    │ Each sub-motion → its own mechanism     │
    │    └─────────────────────────────────────────┘
    │
    └─── "I need speed change (fast→slow or slow→fast)"
              │
              ▼
         ┌─────────────────────────────────────────┐
         │ USE: Gear train (BOSL2)                 │
         │ OR: Different crank radius              │
         │ THEN: Go to Section 4 (CAD)             │
         └─────────────────────────────────────────┘
```

---

## Section 2: SYNTHESIS TOOLS (Path → Linkage)

**Situation:** You can draw/describe the curve you want a point to trace

```
How complex is the path?
    │
    ├─── "Simple arc or line segment"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ DON'T NEED synthesis                    │
    │    │ USE: Slider-crank or simple four-bar    │
    │    │ RECIPE: Check KINETIC_MOTION_RECIPES.md │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Figure-8, teardrop, bean shape"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ ★ USE: Pyslvs-UI                        │
    │    │ 1. Draw/import your target curve        │
    │    │ 2. Run dimensional synthesis            │
    │    │ 3. Export link lengths                  │
    │    │ THEN: Verify in Section 3 (Simulation)  │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Custom freeform curve"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ ★ USE: Pyslvs-UI                        │
    │    │ Import curve as points/DXF              │
    │    │ May need multiple iterations            │
    │    │ Accept "close enough" - perfection rare │
    │    └─────────────────────────────────────────┘
    │
    └─── "I need command-line / scriptable synthesis"
              │
              ▼
         ┌─────────────────────────────────────────┐
         │ USE: four-bar-rs                        │
         │ (Same author as Pyslvs, more control)   │
         │ Requires: Rust or use web assembly ver  │
         └─────────────────────────────────────────┘
```

### Pyslvs-UI Quick Reference
```
Install:    pip install pyslvs-ui
            OR download .exe from GitHub releases

Workflow:
1. File → New mechanism
2. Draw your target path (or import DXF)
3. Synthesis → Dimensional Synthesis
4. Pick algorithm (RGA or Firefly usually work)
5. Run → Wait for convergence
6. Export results
```

---

## Section 3: SIMULATION TOOLS (Linkage → Motion)

**Situation:** You have link lengths (from recipe or synthesis), want to see if it works

```
What do you need to see?
    │
    ├─── "Quick visual check - does it move right?"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ ★ USE: linkage_explorer.ipynb          │
    │    │ Already created in your learning folder │
    │    │ Sliders for instant feedback            │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Animation / GIF of the motion"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ ★ USE: mechanism library (Python)      │
    │    │ pip install mechanism                   │
    │    │ Can export GIF animations               │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Detailed analysis (velocity, acceleration)"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ USE: mechanism library (Python)         │
    │    │ Provides SVAJ diagrams                  │
    │    │ Shows transmission angle issues         │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Just need the path coordinates for CAD"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ USE: linkage_quick_test.py              │
    │    │ OR export from mechanism library        │
    │    │ Outputs coordinate arrays               │
    │    └─────────────────────────────────────────┘
    │
    └─── "Browser-based, no install"
              │
              ▼
         ┌─────────────────────────────────────────┐
         │ USE: Web linkage simulators             │
         │ - linkagesimulator.com                  │
         │ - GeoGebra linkage constructions        │
         │ Good for learning, limited export       │
         └─────────────────────────────────────────┘
```

### mechanism Library Quick Reference
```python
# Install
pip install mechanism

# Basic four-bar
from mechanism import FourBarLinkage

linkage = FourBarLinkage(
    ground=100,   # distance between fixed pivots
    crank=30,     # input arm
    coupler=80,   # floating bar
    rocker=70     # output arm
)

# Check if motor can drive it
print(linkage.linkage_type)  # Want "crank-rocker"

# Animate
linkage.animate('output.gif')
```

---

## Section 4: CAD TOOLS (Design → Model)

**Situation:** Linkage is designed, need to build it in OpenSCAD

```
What component are you building?
    │
    ├─── "Gears (spur, bevel, worm)"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ ★ USE: BOSL2 gears module               │
    │    │ include <BOSL2/std.scad>                │
    │    │ include <BOSL2/gears.scad>              │
    │    │ spur_gear(), bevel_gear(), worm_gear()  │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Standard parts (bearings, motors, screws)"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ ★ USE: NopSCADlib                       │
    │    │ Real dimensions for real parts          │
    │    │ ball_bearing(), stepper(), screw()      │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Living hinges / flexures"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ USE: BOSL2 hinges module                │
    │    │ OR: Manual serpentine pattern           │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Custom linkage bars"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ USE: Plain OpenSCAD                     │
    │    │ hull() between two cylinders            │
    │    │ Add bearing holes at calculated points  │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Sculptural elements (bird body, flower)"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ USE: Plain OpenSCAD                     │
    │    │ OR: Import STL from other software      │
    │    │ Focus on attachment points to mechanism │
    │    └─────────────────────────────────────────┘
    │
    └─── "Animate to verify motion in OpenSCAD"
              │
              ▼
         ┌─────────────────────────────────────────┐
         │ USE: $t variable (0 to 1)               │
         │ View → Animate in OpenSCAD              │
         │ Example: rotate([0, 0, $t * 360])       │
         └─────────────────────────────────────────┘
```

### BOSL2 Gear Quick Reference
```openscad
include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// 20-tooth spur gear, module 2
spur_gear(mod=2, teeth=20, thickness=5);

// Meshing distance for two gears
dist = gear_dist(mod=2, teeth1=20, teeth2=40);
```

### NopSCADlib Quick Reference
```openscad
include <NopSCADlib/lib.scad>

// 608 bearing (skateboard bearing)
ball_bearing(BB608);

// NEMA17 stepper motor
NEMA(NEMA17);
```

---

## Section 5: FABRICATION

**Situation:** CAD model is done, need physical prototype

```
What material/method?
    │
    ├─── "3D printing (PLA/PETG)"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ Export STL from OpenSCAD                │
    │    │ Slice with Cura/PrusaSlicer             │
    │    │ Consider: clearances, print orientation │
    │    └─────────────────────────────────────────┘
    │
    ├─── "Laser cutting (wood/acrylic)"
    │         │
    │         ▼
    │    ┌─────────────────────────────────────────┐
    │    │ Export DXF from OpenSCAD                │
    │    │ projection(cut=true) for 2D slices      │
    │    │ Add kerf compensation                   │
    │    └─────────────────────────────────────────┘
    │
    └─── "Metal/wood (manual fabrication)"
              │
              ▼
         ┌─────────────────────────────────────────┐
         │ Export PDF with dimensions              │
         │ Use NopSCADlib BOM generation           │
         │ Create assembly drawings                │
         └─────────────────────────────────────────┘
```

---

## Quick Lookup Table

| I want to... | Use this tool |
|--------------|---------------|
| Find a starting linkage for "gentle sway" | KINETIC_MOTION_RECIPES.md |
| Draw a curve and get linkage parameters | Pyslvs-UI |
| Check if my linkage rotates fully | mechanism library or linkage_explorer.ipynb |
| See an animation of my linkage | mechanism library |
| Design gears in OpenSCAD | BOSL2 |
| Add real bearing dimensions | NopSCADlib |
| Animate my OpenSCAD model | $t variable + View → Animate |
| Debug why motion looks wrong | Claude (describe the problem) |
| Find a GitHub library for X | Claude (ask to search) |

---

## The "I'm Stuck" Flowchart

```
Stuck?
    │
    ├─── "Linkage locks up / won't move"
    │         │
    │         ▼
    │    Check Grashof condition:
    │    shortest + longest < sum of other two?
    │    If NO → redesign link lengths
    │
    ├─── "Motion is jerky / uneven"
    │         │
    │         ▼
    │    Check transmission angle:
    │    Should stay between 40°-140°
    │    Use mechanism library to analyze
    │
    ├─── "Can't get the curve I want"
    │         │
    │         ▼
    │    Try: Coupler point at different position
    │    Try: Extended coupler point (beyond bar)
    │    Try: Different linkage type (six-bar?)
    │
    ├─── "Multiple motions won't coordinate"
    │         │
    │         ▼
    │    Calculate phase offsets
    │    Use gear ratios for speed matching
    │    Ask Claude for help with the math
    │
    └─── "Physical prototype doesn't match simulation"
              │
              ▼
         Check:
         - Bearing friction
         - Manufacturing tolerances
         - Gravity effects (simulation ignores)
         - Joint play/slop
```

---

## Remember

1. **Start with recipes** → Don't calculate from scratch
2. **Draw before math** → Pyslvs turns drawings into numbers
3. **Simulate before building** → Cheaper to fix in software
4. **Use libraries** → BOSL2 and NopSCADlib save hours
5. **Ask Claude** → When stuck, describe the problem
