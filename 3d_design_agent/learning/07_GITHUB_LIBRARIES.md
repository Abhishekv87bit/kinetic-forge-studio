# GitHub Libraries & Code Resources
## Open Source Tools for Kinetic Sculpture Design

---

## OpenSCAD Libraries (CRITICAL!)

### BOSL2 - Belfry OpenSCAD Library v2
**URL:** [github.com/BelfrySCAD/BOSL2](https://github.com/BelfrySCAD/BOSL2)

**What it provides:**
- **Involute gears** - Proper gear profiles that mesh correctly
- **Attachments system** - Position parts relative to each other
- **Textures** - Knurling, patterns
- **Rounding/chamfering** - Professional edges

**Installation (Windows):**
```bash
cd %USERPROFILE%\Documents\OpenSCAD\libraries
git clone https://github.com/BelfrySCAD/BOSL2.git
```

**Basic usage:**
```openscad
include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// Create a 20-tooth spur gear
spur_gear(pitch=3, teeth=20, thickness=5);
```

**Key functions for kinetic sculpture:**
- `spur_gear()` - Standard gears
- `worm_gear()` - Worm drives
- `bevel_gear()` - Angle change gears
- `rack()` - Linear gear rack
- `planetary_gears()` - Epicyclic systems

**Requires:** OpenSCAD 2021.01 or later

---

### NopSCADlib - Hardware & Vitamins
**URL:** [github.com/nophead/NopSCADlib](https://github.com/nophead/NopSCADlib)

**What it provides:**
- **Ball bearings** - Accurate dimensions
- **Motors** - Steppers, servos, BLDC
- **Hardware** - Screws, nuts, washers
- **Electronics** - PCBs, connectors
- **Auto BOM generation** - Bill of materials

**Installation:**
```bash
cd %USERPROFILE%\Documents\OpenSCAD\libraries
git clone https://github.com/nophead/NopSCADlib.git
```

**Basic usage:**
```openscad
include <NopSCADlib/lib.scad>
include <NopSCADlib/vitamins/bearings.scad>

// 608 bearing (standard skateboard bearing)
ball_bearing(BB608);
```

**Key vitamins for kinetic sculpture:**
- Bearings: `BB608`, `BB625`, `BB6200`
- Stepper motors: `NEMA17`, `NEMA23`
- Servos: Standard hobby servos
- Shafts, couplers, pulleys

---

### OpenSCAD Linkages Library
**URL:** [github.com/machineree/OpenSCAD_Linkages_Library](https://github.com/machineree/OpenSCAD_Linkages_Library)

**What it provides:**
- 2D and 3D linkage primitives
- Angled/twisted linkages
- Pantograph examples

**Installation:**
```bash
cd %USERPROFILE%\Documents\OpenSCAD\libraries
git clone https://github.com/machineree/OpenSCAD_Linkages_Library.git
```

---

### MCAD - OpenSCAD Parametric CAD Library
**URL:** [github.com/openscad/MCAD](https://github.com/openscad/MCAD)

**What it provides:**
- Basic shapes and utilities
- Gears (simpler than BOSL2)
- Threading
- Common mechanical components

**Usually pre-installed with OpenSCAD**

---

## Python Libraries

### Pyslvs-UI - Linkage Synthesis
**URL:** [github.com/KmolYuan/Pyslvs-UI](https://github.com/KmolYuan/Pyslvs-UI)

**What it does:**
- GUI for linkage design
- Path synthesis (draw curve → get linkage)
- Multiple optimization algorithms
- Export to DXF, YAML

**Installation:**
```bash
pip install pyslvs-ui
```

**Note:** Requires C++ compiler on Windows. If fails, use web alternatives.

---

### mechanism - Python Simulation
**URL:** PyPI (already installed)

**What it does:**
- Mechanism simulation
- Animation generation
- SVAJ diagrams

**Usage:**
```python
import mechanism
# See your linkage_explorer.ipynb for examples
```

---

### gabemorris12/mechanism - Python Mechanisms, Cams, Gears
**URL:** [github.com/gabemorris12/mechanism](https://github.com/gabemorris12/mechanism)

**What it does:**
- Comprehensive Python tool for mechanisms, cams, AND gears
- Linkage analysis with plotting
- Cam profile generation (disk, oscillating, translating followers)
- Gear train analysis
- Animation with matplotlib

**Best for:** Analyzing and generating cam profiles, gear calculations, full mechanism simulation in Python

---

### four-bar-rs (Rust)
**URL:** [github.com/KmolYuan/four-bar-rs](https://github.com/KmolYuan/four-bar-rs)

**What it does:**
- Rust-based synthesis tool
- Command-line interface
- Very fast computation

**Best for:** Advanced users needing speed

---

## Simulation & Analysis

### FourBarSimulation (Python)
**URL:** [github.com/RCmags/FourBarSimulation](https://github.com/RCmags/FourBarSimulation)

Simple 2D simulation with adjustable bar lengths and masses.

---

### Simple-Four-Bar (Python)
**URL:** [github.com/Rod-Persky/Simple-Four-Bar](https://github.com/Rod-Persky/Simple-Four-Bar)

Minimal Python four-bar simulation for learning.

---

### strandbeest (MATLAB/Python)
**URL:** [github.com/wrongu/strandbeest](https://github.com/wrongu/strandbeest)

Genetic algorithm optimization for Theo Jansen walking machines. Finds optimal bar lengths!

---

## Generative Design

### Rostok - Linkage Co-Design Framework
**URL:** [github.com/aimclub/rostok](https://github.com/aimclub/rostok)

**What it does:**
- Python framework for generative mechanism design
- Graph-based mechanism description
- Simulation and reward-based optimization
- Search for optimal designs

**Best for:** Phase 3-4, original sculpture design

---

## CAD File Sources (STEP/STL Downloads)

### GrabCAD
**URL:** [grabcad.com](https://grabcad.com/library)

**What it provides:**
- Community library of STEP files for linkages and mechanisms
- Downloadable 3D models importable into Fusion 360
- Search for "four-bar linkage", "cam mechanism", "Geneva drive", etc.

**Best for:** Starting points for Fusion 360 mechanism assemblies — download, modify, learn

---

### Cults3D
**URL:** [cults3d.com](https://cults3d.com)

**What it provides:**
- STL and STEP mechanism files for 3D printing
- Many kinetic/automata designs available
- Mix of free and paid models

**Best for:** Printable mechanism models to study and reverse-engineer

---

### Linkage Mechanism Designer (Desktop Software)
**URL:** [rectorsquid.com](https://blog.rectorsquid.com/linkage-mechanism-designer-and-simulator/)

**What it does:**
- Windows desktop application for linkage design
- More powerful than web-based alternatives
- Save/load designs, export coordinates
- Simulation with animation

**Best for:** Complex multi-bar linkage design before moving to Fusion 360

---

## Curated Collections

### awesome-mecheng
**URL:** [github.com/m2n037/awesome-mecheng](https://github.com/m2n037/awesome-mecheng)

Curated list of mechanical engineering resources on GitHub.

### awesome-openscad
**URL:** [github.com/elasticdotventures/awesome-openscad](https://github.com/elasticdotventures/awesome-openscad)

Collection of OpenSCAD projects and libraries.

---

## Dead Ends (Assessed & Not Useful)

These were investigated and determined to NOT be useful for our workflow:

| Resource | Why It's Not Useful |
|----------|-------------------|
| **PartCAD** | Package manager *framework* only — NOT a ready-to-use parts library. No actual mechanism parts available yet |
| **Mechanical mechanism DB** | Only ~9,000 *images* for AI training — NOT CAD files. Cannot import into Fusion 360 or OpenSCAD |

---

## Installation Priority

### Phase 1 (Install Now)
1. **BOSL2** - You'll need gears soon
2. **NopSCADlib** - Real hardware dimensions

### Phase 2 (When Needed)
1. **OpenSCAD_Linkages_Library** - Linkage primitives
2. **four-bar-rs** - Command-line synthesis

### Phase 3+ (Advanced)
1. **Rostok** - Generative design exploration

---

## Quick Reference: OpenSCAD Library Paths

**Windows:**
```
%USERPROFILE%\Documents\OpenSCAD\libraries\
```

**Mac:**
```
~/Documents/OpenSCAD/libraries/
```

**Linux:**
```
~/.local/share/OpenSCAD/libraries/
```

---

## Verification

After installing, test in OpenSCAD:

```openscad
// Test BOSL2
include <BOSL2/std.scad>
include <BOSL2/gears.scad>
spur_gear(pitch=3, teeth=20, thickness=5);

// Test NopSCADlib
include <NopSCADlib/lib.scad>
include <NopSCADlib/vitamins/bearings.scad>
ball_bearing(BB608);
```

If no errors, you're ready!
