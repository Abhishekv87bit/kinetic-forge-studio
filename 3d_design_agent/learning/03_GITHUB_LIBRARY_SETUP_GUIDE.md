# GitHub Library Setup Guide
## Windows Installation for Kinetic Sculpture Tools

**Time to complete: ~1 hour**

---

## Overview: What You're Installing

| Tool | Purpose | Type |
|------|---------|------|
| OpenSCAD | Parametric CAD | Desktop App |
| BOSL2 | Gears, structural elements | OpenSCAD Library |
| NopSCADlib | Standard parts (bearings, motors) | OpenSCAD Library |
| Pyslvs-UI | Path → Linkage synthesis | Python GUI |
| mechanism | Simulation + animation | Python Library |
| MotionGen Pro | Visual linkage design | Browser (no install) |

---

## Step 1: OpenSCAD (5 min)

### Download
1. Go to [openscad.org/downloads](https://openscad.org/downloads.html)
2. Download **Windows Installer (64-bit)**
3. Run installer, accept defaults

### Verify
1. Open OpenSCAD
2. Type: `cube(10);`
3. Press F5 (Preview)
4. You should see a cube!

### Find Your Library Folder
This is where BOSL2 and NopSCADlib will go.

**Windows default:** `C:\Users\YOUR_USERNAME\Documents\OpenSCAD\libraries`

If it doesn't exist, create it.

---

## Step 2: BOSL2 Library (10 min)

BOSL2 = Belfry OpenSCAD Library v2 (gears, threading, attachments)

### Option A: Download ZIP (Easier)
1. Go to [github.com/BelfrySCAD/BOSL2](https://github.com/BelfrySCAD/BOSL2)
2. Click green **Code** button → **Download ZIP**
3. Extract to: `C:\Users\YOUR_USERNAME\Documents\OpenSCAD\libraries\BOSL2`
4. Make sure the folder structure is:
   ```
   libraries/
   └── BOSL2/
       ├── std.scad
       ├── gears.scad
       └── ... (many files)
   ```

### Option B: Git Clone (Better for Updates)
```cmd
cd C:\Users\YOUR_USERNAME\Documents\OpenSCAD\libraries
git clone https://github.com/BelfrySCAD/BOSL2.git
```

### Verify BOSL2
In OpenSCAD, create new file and type:
```openscad
include <BOSL2/std.scad>
include <BOSL2/gears.scad>

spur_gear(mod=2, teeth=20, thickness=5);
```
Press F5 - you should see a gear!

---

## Step 3: NopSCADlib (10 min)

NopSCADlib = Real parts with real dimensions (bearings, motors, screws)

### Option A: Download ZIP
1. Go to [github.com/nophead/NopSCADlib](https://github.com/nophead/NopSCADlib)
2. Click green **Code** button → **Download ZIP**
3. Extract to: `C:\Users\YOUR_USERNAME\Documents\OpenSCAD\libraries\NopSCADlib`

### Option B: Git Clone
```cmd
cd C:\Users\YOUR_USERNAME\Documents\OpenSCAD\libraries
git clone https://github.com/nophead/NopSCADlib.git
```

### Verify NopSCADlib
In OpenSCAD:
```openscad
include <NopSCADlib/lib.scad>

ball_bearing(BB608);  // 608 skateboard bearing
```
Press F5 - you should see a bearing!

---

## Step 4: Python Environment (15 min)

### Install Python (if needed)
1. Go to [python.org/downloads](https://www.python.org/downloads/)
2. Download Python 3.10+ for Windows
3. **IMPORTANT:** Check "Add Python to PATH" during install!

### Verify Python
Open Command Prompt (cmd):
```cmd
python --version
```
Should show: `Python 3.10.x` or higher

### Install pip packages
```cmd
pip install pyslvs-ui
pip install mechanism
pip install numpy matplotlib
pip install jupyter  # For interactive notebooks
```

---

## Step 5: Pyslvs-UI (5 min)

Pyslvs = Path synthesis (draw curve → get linkage parameters)

### Run It
```cmd
pyslvs
```

A GUI window should open.

### Quick Test
1. File → New
2. Draw a simple curve in the canvas
3. Synthesis → Dimensional Synthesis
4. It should start calculating!

### If It Doesn't Work
Try running from Python:
```cmd
python -m pyslvs_ui
```

---

## Step 6: mechanism Library (5 min)

mechanism = Python library for linkage analysis and animation

### Test It
Create a file `test_mechanism.py`:
```python
from mechanism import FourBarLinkage

# Create a crank-rocker
linkage = FourBarLinkage(
    ground=100,
    crank=30,
    coupler=80,
    rocker=70
)

print(f"Type: {linkage.linkage_type}")
print(f"Grashof: {linkage.is_grashof}")

# Optional: Create animation
# linkage.animate('test_animation.gif')
```

Run it:
```cmd
python test_mechanism.py
```

Should output: `Type: crank-rocker` and `Grashof: True`

---

## Step 7: MotionGen Pro (0 min - Browser)

No install needed!

1. Go to [motiongen.io](https://motiongen.io/)
2. Works in Chrome, Edge, Firefox
3. Bookmark it!

---

## Step 8: Jupyter Notebook (5 min)

For interactive linkage exploration.

### Start Jupyter
```cmd
cd D:\Claude local\3d_design_agent\learning
jupyter notebook
```

A browser window opens with file listing.

### Open the Explorer
Click on `linkage_explorer.ipynb` to open the interactive notebook.

---

## Folder Structure After Setup

```
C:\Users\YOUR_USERNAME\
├── Documents\
│   └── OpenSCAD\
│       └── libraries\
│           ├── BOSL2\
│           │   ├── std.scad
│           │   ├── gears.scad
│           │   └── ...
│           └── NopSCADlib\
│               ├── lib.scad
│               └── ...
│
D:\Claude local\3d_design_agent\
├── learning\
│   ├── linkage_explorer.ipynb
│   ├── linkage_quick_test.py
│   └── ...
```

---

## Verification Checklist

Run through this to confirm everything works:

### OpenSCAD + Libraries
- [ ] OpenSCAD opens and renders a cube
- [ ] BOSL2: `spur_gear()` renders a gear
- [ ] NopSCADlib: `ball_bearing(BB608)` renders a bearing

### Python Tools
- [ ] `python --version` shows 3.10+
- [ ] `pyslvs` opens GUI window
- [ ] mechanism test script runs without errors
- [ ] `jupyter notebook` opens in browser

### Browser Tools
- [ ] motiongen.io loads and is interactive

---

## Common Issues & Fixes

### "Module not found: BOSL2"
- Check folder structure: `libraries/BOSL2/std.scad` should exist
- Restart OpenSCAD after adding libraries

### "pip is not recognized"
- Python wasn't added to PATH
- Reinstall Python, check "Add to PATH"

### "pyslvs won't start"
Try: `python -m pyslvs_ui`
Or reinstall: `pip install --force-reinstall pyslvs-ui`

### "mechanism import error"
Check: `pip show mechanism`
If not found: `pip install mechanism`

### "Jupyter command not found"
```cmd
pip install jupyter
python -m jupyter notebook
```

---

## Quick Reference Card

### OpenSCAD Shortcuts
| Key | Action |
|-----|--------|
| F5 | Preview |
| F6 | Render (slow, accurate) |
| F7 | Export STL |

### BOSL2 Gears
```openscad
include <BOSL2/std.scad>
include <BOSL2/gears.scad>

// 20-tooth spur gear, module 2, 5mm thick
spur_gear(mod=2, teeth=20, thickness=5);

// Meshing distance for two gears
dist = gear_dist(mod=2, teeth1=20, teeth2=40);
```

### NopSCADlib Parts
```openscad
include <NopSCADlib/lib.scad>

ball_bearing(BB608);     // Skateboard bearing
NEMA(NEMA17);            // Stepper motor
screw(M3_cap_screw, 10); // M3 cap screw, 10mm
```

### mechanism Library
```python
from mechanism import FourBarLinkage

linkage = FourBarLinkage(
    ground=100,
    crank=30,
    coupler=80,
    rocker=70
)
print(linkage.linkage_type)
linkage.animate('output.gif')
```

---

## Next Steps After Setup

1. **Run the linkage_explorer notebook** - Play with sliders!
2. **Try KINETIC_MOTION_RECIPES.md** - Build a recipe in OpenSCAD
3. **Open MotionGen Pro** - Design a simple four-bar visually
4. **Build it in cardboard** - Then compare to simulation

---

## Updating Libraries Later

### BOSL2 Update
```cmd
cd C:\Users\YOUR_USERNAME\Documents\OpenSCAD\libraries\BOSL2
git pull
```

### NopSCADlib Update
```cmd
cd C:\Users\YOUR_USERNAME\Documents\OpenSCAD\libraries\NopSCADlib
git pull
```

### Python Packages Update
```cmd
pip install --upgrade pyslvs-ui mechanism
```
