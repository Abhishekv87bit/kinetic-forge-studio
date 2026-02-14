# Online Tools Reference
## Browser-Based Tools for Kinetic Sculpture Design (No Install Required!)

---

## Quick Decision: Which Tool When?

| You Want To... | Use This Tool |
|----------------|---------------|
| Draw a curve → get a linkage | **MotionGen Pro** |
| Look up "what mechanism does X?" | **507movements.com** |
| Analyze an existing linkage | **PMKS+** |
| Design gears | **geargenerator.com** |
| Optimize Theo Jansen leg | **Strandbeest Optimizer** |
| Understand Grashof visually | **GeoGebra** |
| Quickly animate a mechanism idea in code | **p5.js Web Editor** |

---

## Tier 1: Essential Tools

### MotionGen Pro
**URL:** [motiongen.io](https://motiongen.io)

**What it does:**
- AI-driven path synthesis (draw curve → get linkage)
- N-bar mechanism simulation (not just 4-bar!)
- 2D and 3D visualization
- Export for fabrication (laser cut, 3D print)

**Best for:** "I want THIS curve" problems

**How to use:**
1. Sketch your desired path/curve
2. Click "Path Synthesis"
3. Get 30 candidate mechanisms
4. Adjust constraints, re-run if needed
5. Export for fabrication

**Developed at:** Stony Brook University

---

### 507 Mechanical Movements
**URL:** [507movements.com](http://507movements.com/)

**What it does:**
- Animated catalog of 507 historical mechanisms
- From Henry T. Brown's 1868 book
- Searchable by motion type

**Best for:** "What mechanism creates [this motion]?"

**Pro tip:** David C. Roy recommends this as his primary reference!

**Also see:** [studiored.com/cad/114-of-the-507-mechanical-movement](https://studiored.com/cad/114-of-the-507-mechanical-movement/) for CAD versions

---

### PMKS+ (Planar Mechanism Kinematic Simulator)
**URL:** [pmksplus.com](https://pmksplus.com/)

**What it does:**
- Web-based linkage analysis
- Input link lengths → see motion
- Velocity and acceleration analysis
- Ground, crank, coupler, rocker configuration

**Best for:** Analyzing existing designs, checking Grashof

---

## Tier 2: Specialized Tools

### Gear Generator
**URL:** [geargenerator.com](http://www.geargenerator.com)

**What it does:**
- Design spur gears online
- Set tooth count, module, pressure angle
- Download DXF for laser cutting

**Best for:** Quick gear prototypes

---

### Strandbeest Optimizer
**URL:** [diywalkers.com/strandbeest-optimizer-for-lego.html](https://www.diywalkers.com/strandbeest-optimizer-for-lego.html)

**What it does:**
- Theo Jansen linkage calculator
- Adjust bar lengths, see foot path
- Optimized for LEGO builds
- Python code available for download

**Best for:** Walking mechanisms, Jansen-style legs

---

### GeoGebra - Jansen Linkages
**URL:** [geogebra.org/m/ZrfP4xU3](https://www.geogebra.org/m/ZrfP4xU3)

**What it does:**
- Interactive Strandbeest simulation
- Drag sliders to change parameters
- See "holy numbers" in action

**Best for:** Understanding Jansen linkage visually

---

### Javalab Theo Jansen
**URL:** [javalab.org/en/theo_jansen_en](https://javalab.org/en/theo_jansen_en/)

**What it does:**
- Visualizes Theo Jansen's "holy numbers"
- Shows the exact ratios he discovered
- Interactive simulation

**Holy Numbers (Jansen's optimized ratios):**
```
a = 38.0   (crank)
b = 41.5
c = 39.3
d = 40.1
e = 55.8
f = 39.4
g = 36.7
h = 65.7
```

---

### Linkage Mechanism Designer
**URL:** [rectorsquid.com](https://blog.rectorsquid.com/linkage-mechanism-designer-and-simulator/)

**What it does:**
- Design custom linkages
- Simulate in browser
- Export coordinates

---

## Tier 2B: Interactive Math & Visualization Libraries (KineticForge Pipeline)

These tools were assessed during KineticForge app development. They power the interactive math visualizations for mechanism design and analysis.

### Tier 1 — Directly Powers Pipeline

| Tool | What It Does | CDN / Install | Best For |
|------|-------------|---------------|----------|
| **Grafar** | Reactive 3D math visualization, WebGL/Three.js, auto-detects topology | CDN | 3D parameter space exploration, mechanism surfaces |
| **MathBox** | Presentation-quality WebGL math graphing | CDN (Three.js r137) | Beautiful 3D mechanism path visualizations |
| **MathCell** | Interactive 3D math in plain HTML cells | CDN | Quick inline mechanism calculations |
| **Observable** | Reactive JS notebooks (by D3 creator) | Web-based | Prototyping mechanism simulations |
| **Fourier Interactive** | Draw curve → epicycle decomposition | Web-based | Understanding motion decomposition into sinusoids |
| **Bezier Primer** | 100+ page interactive textbook + Bezier.js library | CDN (Bezier.js) | Cam profiles, smooth path design |

### Tier 2 — Strong Supporting Tools

| Tool | What It Does | CDN / Install | Best For |
|------|-------------|---------------|----------|
| **JSXGraph** | 160KB pure JS, 2D geometry + function plotting | CDN | Lightweight linkage visualization, constraint sketching |
| **CindyJS** | Geometry + CindyLab physics + CindyGL GPU shaders | CDN | Physics-aware mechanism simulation |
| **Complexity Explorables** | Coupled oscillators, synchronization demos | Web-based | Understanding phase-offset patterns |
| **Polyhedra Viewer** | Interactive 3D polyhedra exploration | Web-based | Geodesic/spherical mechanism layouts |
| **Pts.js** | Creative coding TypeScript library | CDN | Artistic motion visualization |

### Library Compatibility Notes
- **Grafar, MathBox, MathCell** share Three.js — **lock to r137** to avoid conflicts
- **JSXGraph, CindyJS** are vanilla JS — no dependency conflicts
- **p5.js** needs **instance mode** when used alongside other libraries
- All CDN-loaded in KineticForge app (no npm install needed for browser use)

---

## Tier 2C: Creative Coding Environment

### p5.js Web Editor
**URL:** [editor.p5js.org](https://editor.p5js.org/)

**What it is:**
Free browser-based coding environment for creative coding with JavaScript. No install, no setup — write code and see results instantly. Sketches are shareable via URL.

**Key uses for kinetic sculpture:**
- **Wave math sandbox** — Experiment with sin/cos combinations, phase offsets, amplitude envelopes in real time
- **Mechanism animation prototyping** — Quickly animate four-bar linkages, cam followers, slider-cranks before committing to Fusion 360
- **Motion vocabulary coding** — Translate your Motion Vocabulary (breathe, pulse, drift, cascade) into running animations
- **Physics visualization** — Visualize friction, inertia, torque curves, and transmission angles interactively
- **Portfolio pieces** — Create shareable web animations that complement your physical sculptures

**Relationship to KineticForge:**
KineticForge has "Open in p5 Editor" buttons that export current parameters (link ratios, phase offsets, wave equations) as runnable p5.js sketches. This bridges the gap between the app's built-in visualizations and standalone creative coding.

**Learning resource:**
**The Coding Train** YouTube channel by Daniel Shiffman ([thecodingtrain.com](https://thecodingtrain.com/)) — excellent video tutorials covering p5.js from basics to advanced creative coding. Particularly relevant series:
- Nature of Code (physics simulations, oscillation, waves)
- Coding Challenges (many mechanism-adjacent projects)
- p5.js Tutorials (complete beginner-friendly walkthrough)

**How it fits your workflow:**
```
IDEA → p5.js sketch (minutes) → CARDBOARD prototype → FUSION 360 → 3D PRINT
```
p5.js adds a rapid digital sketching step before cardboard — useful when you want to test math or timing before cutting anything.

---

## Tier 3: Learning Resources

### Mechanism Design Introduction (CMU)
**URL:** [cs.cmu.edu/.../mechanism-design.html](https://www.cs.cmu.edu/afs/cs/academic/class/15394h-f17/resources/mechanism-design.html)

Comprehensive university-level introduction to mechanisms.

---

### MIT OCW 2.72 Elements of Mechanical Design
**URL:** [ocw.mit.edu](https://ocw.mit.edu/courses/2-72-elements-of-mechanical-design-spring-2009/)

Free MIT course with lecture notes on linkage kinematics.

---

### University of Arkansas Open Textbook
**URL:** [uark.pressbooks.pub](https://uark.pressbooks.pub/mechanicaldesign/chapter/mechanism-synthesis-and-analysis/)

Free textbook on mechanism synthesis with graphical methods.

---

## Workflow Integration

### Phase 1 (Months 1-4): Use These
1. **507movements.com** - Browse for inspiration
2. **PMKS+** - Understand your four-bar recipes
3. **MotionGen Pro** - Synthesize your first custom linkages
4. **p5.js Web Editor** - Learn creative coding basics (shapes, sin/cos animation, frameCount)

### Phase 2 (Months 5-8): Add These
1. **Gear Generator** - Design gear trains
2. **Strandbeest Optimizer** - Walking mechanisms
3. **p5.js Web Editor** - Code four-bar simulator, cam profile designer, friction cascade visualizer

### Phase 3+ (Months 9-18): Explore
1. **CMU/MIT materials** - Deeper theory
2. **Advanced MotionGen** - N-bar synthesis
3. **p5.js Web Editor** - Animated concept sketches, Margolin equation in WebGL, portfolio pieces

---

## Quick Links Summary

| Tool | URL |
|------|-----|
| MotionGen Pro | motiongen.io |
| 507 Movements | 507movements.com |
| PMKS+ | pmksplus.com |
| Gear Generator | geargenerator.com |
| Strandbeest Optimizer | diywalkers.com/strandbeest-optimizer-for-lego.html |
| GeoGebra Jansen | geogebra.org/m/ZrfP4xU3 |
| Javalab Jansen | javalab.org/en/theo_jansen_en |
| Linkage Designer | rectorsquid.com |
| p5.js Web Editor | editor.p5js.org |
| The Coding Train | thecodingtrain.com |
| CMU Course | cs.cmu.edu |
| MIT OCW | ocw.mit.edu |

---

## Pipeline-to-Tool Mapping (KineticForge Stages)

| Pipeline Stage | Primary Tool | Supporting Tools |
|---------------|-------------|------------------|
| **Discover** | 507movements.com, Fourier Interactive | Observable, Complexity Explorables |
| **Animate** | Grafar, MathBox, p5.js | Bezier Primer, Pts.js |
| **Mechanize** | MotionGen Pro, PMKS+, JSXGraph | CindyJS, MathCell |
| **Simulate** | Fusion 360 Motion Study, CindyJS | MathBox, Polyhedra Viewer |
| **Build** | Fusion 360, OpenSCAD + BOSL2 | Gear Generator, NopSCADlib |
| **Iterate** | All of the above | — |

---

## Remember

These tools complement your physical workflow:

```
CARDBOARD PROTOTYPE → ONLINE TOOL VERIFICATION → FUSION 360 CAD → 3D PRINT
```

**Don't skip cardboard!** Use online tools to verify and refine, not replace hands-on learning.
