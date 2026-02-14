# AI-Assisted CAD Workflow (2026)
## Leveraging Bleeding-Edge Tools for Kinetic Sculpture Design

---

## Your Superpower: Claude + OpenSCAD

You already have the most powerful AI-CAD combination available in 2026:

**Claude** (this conversation) + **OpenSCAD** (parametric CAD)

### Why This Works
- OpenSCAD is code-based → Claude can write/debug it
- Parametric design → Change one number, everything updates
- Text-based → No GUI clicks to replicate
- Version controllable → Git-friendly

### The Workflow
```
YOU: "I want a four-bar linkage with ground=100, crank=30, coupler=80, rocker=70"

CLAUDE: [Generates OpenSCAD code with:]
- Parametric variables at top
- Animated preview with $t
- Proper pivot points
- Export-ready geometry

YOU: [Preview in OpenSCAD, tweak values]

CLAUDE: [Iterates based on your feedback]
```

---

## 2026 AI-CAD Tools Landscape

### Tier 1: Text-to-CAD (Production Ready)

#### Zoo Text-to-CAD
**URL:** [zoo.dev/text-to-cad](https://zoo.dev/text-to-cad)

**What it does:**
- Text prompt → B-rep STEP/GLTF models
- Parametric sliders for adjustment
- ML tuned for manufacturing

**Best for:** Quick mechanical parts, brackets, enclosures

**Strengths:**
- Outputs real CAD formats (STEP)
- Editable dimensions
- Free tier available

**Limitations:**
- Simple geometry only
- Not great for complex mechanisms

**When to use:** "I need a bearing mount" or "motor bracket"

---

#### Adam AI (AdamCAD)
**URL:** [adam.new](https://adam.new)

**What it does:**
- Two modes: Parametric (dimension-driven) + Creative (free-form)
- Exports STL, SCAD
- Browser-based

**Cost:** $9.99/mo (7-day trial)

**Best for:** Exploration, brainstorming shapes

**When to use:** "What if..." creative exploration

---

#### PrintPal
**URL:** [printpal.io/3dgenerator](https://printpal.io/3dgenerator)

**What it does:**
- Text/Image → CAD for 3D printing
- Optimized for printability
- 100k users in 8 months (launched April 2025)

**Best for:** Quick prototypes, 3D printable parts

---

### Tier 2: CAD Copilots (Integrated)

Major CAD programs now have AI assistants:
- **Onshape's AI Advisor**
- **Autodesk Assistant** (Fusion, AutoCAD)
- **Siemens Design Copilot** (Solid Edge, NX)
- **Dassault's Aura** (SolidWorks)

These are trained on documentation - good for "how do I..." questions within the software.

---

### Tier 3: Generative Design

These go beyond text-to-CAD to optimization:

- **Fusion 360 Generative Design** - Topology optimization
- **nTopology** - Lattice structures
- **Rostok** (GitHub) - Linkage mechanism optimization

**Best for:** "Find the optimal shape given these constraints"

---

## When to Use What

| Task | Best Tool |
|------|-----------|
| Generate OpenSCAD mechanism code | **Claude** (you have this!) |
| Quick bracket/mount | **Zoo Text-to-CAD** |
| Creative shape exploration | **Adam AI** |
| "How do I do X in Fusion?" | **Autodesk Assistant** |
| Optimize for weight/strength | **Fusion Generative** |
| Find optimal linkage ratios | **Rostok** or **MotionGen Pro** |

---

## The Claude + OpenSCAD Advantage

### What Claude Excels At

1. **Parametric mechanism code**
   - Four-bar linkages with animation
   - Cam profiles
   - Gear trains

2. **Debugging**
   - "My linkage binds at this angle" → Check Grashof
   - "The gear teeth clash" → Adjust backlash

3. **Iteration**
   - "Make the crank shorter"
   - "Add a second layer with 45° phase offset"

4. **Documentation**
   - Comments in code
   - Explaining why something works

### What Claude Needs From You

1. **Clear intent**
   - "I want gentle tree sway motion"
   - "The output should oscillate ±15°"

2. **Constraints**
   - "Motor at bottom"
   - "Maximum height 200mm"

3. **Feedback**
   - "It binds at 180°"
   - "Motion is too jerky"

---

## Example Workflow

### Starting a New Mechanism

**Step 1: Describe intent**
```
"I want a mechanism that converts motor rotation into
a gentle nodding motion for a bird head, about 20° arc"
```

**Step 2: Claude suggests mechanism**
```
"A simple crank-rocker four-bar will work well.
Ratio suggestion: Ground=100, Crank=15, Coupler=90, Rocker=85
This gives ~22° output swing with smooth motion."
```

**Step 3: Generate OpenSCAD code**
```
"Generate OpenSCAD for this linkage with animation"
```

**Step 4: Preview and iterate**
```
"Make the motion slower and add a slight pause at each end"
```

**Step 5: Integrate**
```
"Now add this to my bird assembly, positioning the
rocker pivot at [x, y] = [50, 80]"
```

---

## AI Limitations (Important!)

### What AI Gets Wrong

1. **Physics violations**
   - Linkages that would bind
   - Impossible Grashof conditions
   - Wrong gear mesh

2. **Manufacturing reality**
   - Impossible overhangs for 3D printing
   - Tolerances too tight
   - Wrong material assumptions

3. **Made-up specifications**
   - Fake material properties
   - Invented formulas
   - Non-existent standards

### Always Verify

- **Cardboard test** - Before trusting any AI-generated mechanism
- **Grashof check** - S + L ≤ P + Q
- **Animation preview** - Watch full rotation in OpenSCAD
- **Physics intuition** - Does it feel right?

---

## Recommended Workflow

```
1. CARDBOARD PROTOTYPE (physical intuition)
        ↓
2. CLAUDE GENERATES OPENSCAD (code)
        ↓
3. PREVIEW ANIMATION (verify motion)
        ↓
4. ZOO/ADAM FOR QUICK PARTS (brackets, mounts)
        ↓
5. ASSEMBLE IN OPENSCAD (integration)
        ↓
6. 3D PRINT TEST
        ↓
7. ITERATE (back to step 2 or 1)
```

---

## Quick Reference

| Tool | URL | Cost | Best For |
|------|-----|------|----------|
| Claude + OpenSCAD | (you have it) | Included | Mechanisms, iteration |
| Zoo | zoo.dev/text-to-cad | Free tier | Quick parts |
| Adam AI | adam.new | $9.99/mo | Creative exploration |
| PrintPal | printpal.io | Free tier | 3D print parts |
| MotionGen Pro | motiongen.io | Free | Path synthesis |

---

## Remember

> "AI works best as a reasoning assistant and first pass generator, not as an authority."

Your cardboard prototypes and physical intuition are still the foundation. AI tools accelerate the digital part of your workflow.

**60% Physical / 40% Digital** - This ratio still applies even with AI tools!
