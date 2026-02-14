# Fusion 360 Complete Learning Guide
## From Zero to Mechanism Designer

**Purpose:** Step-by-step Fusion 360 exercises for kinetic sculpture design. Complete in order — each level builds on the previous.

**Total Time:** ~11 hours of guided exercises + 2-3 hour capstone project

**Prerequisites:** Fusion 360 installed (free for personal use)

---

### LEVEL 1: Interface & Navigation (1 hour)

#### Official Tutorial to Complete First

**Watch:** Autodesk Fusion 360 — "Getting Started" tutorial
- **URL:** https://help.autodesk.com/view/fusion360/ENU/courses/AP-GET-STARTED-OVERVIEW
- **Duration:** ~45 minutes
- **What you'll learn:** Interface layout, navigation, basic workflow

#### Interface Map (Reference While Watching)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ DATA PANEL │ DESIGN ▼ │ SOLID ▼ │ SURFACE ▼ │ SHEET... │ TOOLS ▼ │ ⚙️ │ ? │
│ (9 squares)│          │         │           │          │         │    │   │
├────────────┴──────────┴─────────┴───────────┴──────────┴─────────┴────┴───┤
│                                                                            │
│  BROWSER          ┌─────────────────────────────────────┐    VIEWCUBE     │
│  (left panel)     │                                     │    (top-right)  │
│                   │                                     │    ┌───┐        │
│  ▼ Document       │         3D CANVAS                   │    │TOP│        │
│    ▼ Component1   │                                     │    └───┘        │
│      ▼ Bodies     │     (your model appears here)       │                 │
│      ▼ Sketches   │                                     │    Click faces  │
│      ▼ Origin     │                                     │    to snap view │
│        XY Plane   │                                     │                 │
│        XZ Plane   │                                     │                 │
│        YZ Plane   └─────────────────────────────────────┘                 │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  TIMELINE (bottom) — every operation recorded here, can edit any step     │
│  [Sketch1] → [Extrude1] → [Fillet1] → [Hole1] → ...                       │
└────────────────────────────────────────────────────────────────────────────┘
```

#### Navigation Controls (Practice for 10 Minutes)

| Action | How To Do It | Practice Task |
|--------|--------------|---------------|
| **Orbit (rotate view)** | Hold middle mouse button + drag | Rotate around the origin cube until comfortable |
| **Pan (move view)** | Hold middle mouse + Shift + drag | Move the view left, right, up, down |
| **Zoom** | Scroll wheel | Zoom in close, then zoom out far |
| **Fit All** | Press `F` key or double-click middle button | Returns view to show everything |
| **Snap to Top View** | Click "TOP" face on ViewCube | View from directly above |
| **Snap to Front View** | Click "FRONT" face on ViewCube | View from front |
| **Snap to Isometric** | Click corner of ViewCube (between TOP/FRONT/RIGHT) | Standard 3D view |

#### Exercise 1.1: Navigation Drill (10 minutes)

**Setup:**
1. Open Fusion 360
2. Click **File → New Design** (or Ctrl+N)
3. You now see an empty canvas with origin planes

**Drill:**
1. Press `F` — view should center on origin
2. Click **TOP** on ViewCube — you're now looking straight down at XY plane
3. Click **FRONT** on ViewCube — you're now looking at XZ plane
4. Click the **corner** between TOP/FRONT/RIGHT — isometric view
5. Hold middle mouse button, drag in circle — practice orbiting
6. Hold middle mouse + Shift, drag — practice panning
7. Scroll wheel — practice zooming
8. Press `F` — fit all (resets view)

**Success:** You can navigate without thinking about it.

#### Key Concepts (Understand Before Proceeding)

| Concept | What It Is | Why It Matters |
|---------|------------|----------------|
| **Component** | A container that holds bodies and can move independently | Each moving part in your mechanism = 1 component |
| **Body** | A solid 3D shape | The actual geometry you create |
| **Sketch** | A 2D drawing on a plane | The foundation for 3D shapes (you extrude sketches into bodies) |
| **Timeline** | History of every operation | You can go back and edit ANY step — the model updates |
| **Origin** | The XY, XZ, YZ planes at (0,0,0) | Reference point for all geometry |

---

### LEVEL 2: Sketching Fundamentals (2 hours)

#### Official Tutorial to Complete

**Watch:** "Sketch Fundamentals" learning path
- **URL:** https://help.autodesk.com/view/fusion360/ENU/courses/AP-SKETCH-FUNDAMENTALS
- **Duration:** ~60 minutes
- **Covers:** All sketch tools, constraints, dimensions

#### Exercise 2.1: Your First Sketch — A Simple Rectangle (15 minutes)

**Step-by-step:**

1. **Start a new sketch:**
   - Menu: **Create → Create Sketch**
   - Or: Press `S` to open Sketch toolbar, then click "Create Sketch"
   - Click on the **XY Plane** (the flat horizontal plane in the Browser under Origin)
   - Screen changes: grid appears, "FINISH SKETCH" button appears top-right

2. **Draw a rectangle:**
   - Press `R` (shortcut for Rectangle)
   - Or: Menu **Create → Rectangle → 2-Point Rectangle**
   - Click once at origin (0,0) — this is the first corner
   - Move mouse to the right and up
   - Click again to place second corner
   - A rectangle appears (it will be blue — not yet fully defined)

3. **Add dimensions:**
   - Press `D` (shortcut for Dimension)
   - Or: Menu **Sketch → Sketch Dimension**
   - Click the bottom horizontal line
   - Move mouse down, click to place dimension
   - Type `80` and press Enter — the line is now 80mm
   - Click the left vertical line
   - Move mouse left, click to place dimension
   - Type `15` and press Enter — the height is now 15mm

4. **Observe the color change:**
   - The rectangle should now be **BLACK** (fully constrained)
   - If still blue, you need to add a constraint to fix position:
     - Menu **Sketch → Constraints → Fix/Unfix**
     - Click the bottom-left corner point
     - Now it's black (fully constrained)

5. **Finish the sketch:**
   - Click **FINISH SKETCH** (green checkmark, top-right)
   - Or: Press `Esc` twice

**What you learned:** Create Sketch → Draw → Dimension → Finish Sketch

#### Exercise 2.2: A "Dogbone" Link Shape (20 minutes)

This is the shape you'll use for mechanism links.

**Step-by-step:**

1. **Create new sketch on XY plane**

2. **Draw the center rectangle:**
   - Press `R` for Rectangle
   - Click at origin
   - Draw rectangle roughly 80mm × 15mm (dimensions added next)

3. **Add dimensions:**
   - Press `D`, click bottom line, type `80`
   - Press `D`, click left line, type `15`
   - Fix bottom-left corner to origin (Sketch → Constraints → Fix/Unfix)

4. **Draw circles at each end:**
   - Press `C` for Circle (Center Diameter Circle)
   - For the left circle:
     - Move cursor to the **midpoint** of the left edge (a triangle symbol appears when you hover)
     - Click when you see the midpoint indicator
     - Move mouse outward, click to place circle
     - Press `D`, click the circle, type `15` for diameter (same as link width)

   - For the right circle:
     - Press `C` again
     - Click the **midpoint** of the right edge
     - Draw circle, dimension to `15` diameter

5. **Trim the excess:**
   - Press `T` for Trim
   - Click the parts of the rectangle that are INSIDE the circles (the short edges)
   - Click the parts of the circles that are INSIDE the rectangle (the arcs facing inward)
   - Result: A smooth "dogbone" or "slot" shape

6. **Add holes at each end:**
   - Press `C` for Circle
   - Click the CENTER of the left rounded end (you should see a small circle indicating the center)
   - Draw a small circle, dimension to `5.3` mm diameter (this will be the pivot hole)
   - Repeat for the right end

7. **Verify fully constrained:** All lines should be BLACK

8. **Finish Sketch**

**Result:** A link profile with two pivot holes, ready to extrude.

#### Exercise 2.3: Constraints Practice (15 minutes)

Understanding constraints is critical. They make your sketches "smart."

**Setup:** Create a new sketch on XY plane

**Task 1: Coincident constraint**
- Draw two separate lines (press `L`, click-click for each line)
- Menu: **Sketch → Constraints → Coincident**
- Click the endpoint of line 1, then click the endpoint of line 2
- The points snap together

**Task 2: Horizontal/Vertical constraint**
- Draw a diagonal line
- Menu: **Sketch → Constraints → Horizontal/Vertical**
- Click the line
- It snaps to horizontal (or vertical, depending on angle)

**Task 3: Equal constraint**
- Draw two circles of different sizes
- Menu: **Sketch → Constraints → Equal**
- Click circle 1, then click circle 2
- They become the same size

**Task 4: Concentric constraint**
- Draw two circles in different locations
- Menu: **Sketch → Constraints → Concentric**
- Click circle 1, then circle 2
- The circles share the same center point

**Why this matters:** In mechanisms, you'll use:
- **Concentric** to align holes
- **Equal** to make link widths match
- **Coincident** to connect geometry
- **Horizontal/Vertical** to keep things aligned

---

### LEVEL 3: User Parameters — Parametric Design (1 hour)

#### Why This Is Critical

When you type `80` as a dimension, you've created a "dumb" model. If you need the link to be 100mm later, you have to find and change that dimension manually.

When you type `link_length` as a dimension (where `link_length` is a parameter set to 80mm), you've created a "smart" model. Change the parameter once, and EVERY dimension using it updates automatically.

**For mechanisms:** You WILL iterate. You WILL change dimensions. Parameters save hours of rework.

#### Exercise 3.1: Creating Your First Parameters (15 minutes)

**Step-by-step:**

1. **Open the Parameters dialog:**
   - Menu: **Modify → Change Parameters**
   - Or: Press `Shift+D`
   - A dialog opens showing "User Parameters" and "Model Parameters"

2. **Add your first parameter:**
   - Click the **+** button in the "User Parameters" section
   - A new row appears with fields: Name, Unit, Expression, Comment
   - Fill in:
     - Name: `link_length`
     - Unit: `mm` (should auto-fill)
     - Expression: `60`
     - Comment: `Length of main link`
   - Press Enter or click elsewhere to confirm

3. **Add more parameters:**

   | Name | Unit | Expression | Comment |
   |------|------|------------|---------|
   | `link_length` | mm | `60` | Length of main link |
   | `link_width` | mm | `12` | Width of link (cross-section) |
   | `link_thickness` | mm | `5` | Thickness for extrusion |
   | `pin_diameter` | mm | `5` | Diameter of pivot pins |
   | `clearance` | mm | `0.3` | Printer tolerance (adjust after testing) |
   | `hole_diameter` | mm | `pin_diameter + clearance` | Calculated! |

4. **Notice the calculated parameter:**
   - `hole_diameter` uses an EXPRESSION: `pin_diameter + clearance`
   - It automatically calculates to `5.3`
   - If you change `pin_diameter` to `6`, `hole_diameter` becomes `6.3`

5. **Click OK to close**

#### Exercise 3.2: Using Parameters in a Sketch (20 minutes)

**Step-by-step:**

1. **Create a new sketch on XY plane**

2. **Draw a rectangle:**
   - Press `R`, click at origin, drag to create rectangle
   - DON'T dimension with numbers yet

3. **Dimension using parameters:**
   - Press `D`, click the bottom (horizontal) edge
   - Instead of typing a number, type: `link_length`
   - Press Enter
   - The dimension shows "link_length" (or "60" with an "fx" symbol indicating it's a parameter)

   - Press `D`, click the left (vertical) edge
   - Type: `link_width`
   - Press Enter

4. **Add a circle using a parameter:**
   - Press `C`, click center point, draw circle
   - Press `D`, click the circle
   - Type: `hole_diameter`
   - The hole is now 5.3mm (calculated from `pin_diameter + clearance`)

5. **Test the parametric behavior:**
   - Menu: **Modify → Change Parameters** (or Shift+D)
   - Change `link_length` from `60` to `100`
   - Click OK
   - **Watch your sketch update!** The rectangle is now 100mm long
   - Change it back to `60` for now

**What you learned:** Parameters make dimensions dynamic and linked.

#### Your Standard Parameter Set for All Mechanism Projects

Copy these into every new project:

```
Name                 Unit    Expression              Comment
─────────────────────────────────────────────────────────────────────
link_length          mm      60                      Main link length
crank_length         mm      30                      Crank throw (radius)
coupler_length       mm      80                      Coupler bar length
rocker_length        mm      70                      Output rocker length
base_length          mm      100                     Fixed pivot distance
link_width           mm      12                      Width of links
link_thickness       mm      5                       Material thickness
pin_diameter         mm      5                       Shaft/pin diameter
clearance            mm      0.3                     YOUR printer tolerance
hole_diameter        mm      pin_diameter+clearance  Auto-calculated
```

---

### LEVEL 4: 3D Operations — Extrude, Revolve, Hole (1.5 hours)

#### Official Tutorial to Complete

**Watch:** "Creating 3D Geometry" learning path
- **URL:** https://help.autodesk.com/view/fusion360/ENU/courses/AP-SOLID-CREATE-EXTRUDE
- **Duration:** ~30 minutes
- **Covers:** Extrude, Revolve, and other create tools

#### Exercise 4.1: Extrude Your First Link (15 minutes)

**Prerequisites:** You have a "dogbone" sketch from Exercise 2.2

**Step-by-step:**

1. **Select the sketch profile:**
   - In the Browser (left panel), expand **Sketches**
   - Click on your dogbone sketch to highlight it
   - Or: Click directly on the enclosed area in the canvas

2. **Start Extrude:**
   - Menu: **Create → Extrude**
   - Or: Press `E`
   - The Extrude dialog appears

3. **Configure the extrusion:**
   - **Profile:** Should already show your sketch selected (highlighted blue)
   - **Direction:** One Side (default)
   - **Distance:** Type `link_thickness` (your parameter!) instead of a number
   - **Operation:** New Body (since this is the first body)

4. **Click OK**

5. **Observe the result:**
   - Your 2D sketch is now a 3D solid
   - In the Browser, under Bodies, you see "Body1"
   - In the Timeline at bottom, you see the Extrude operation

**What you learned:** Sketch → Extrude → 3D Body

#### Exercise 4.2: Cut Operation — Making Holes (15 minutes)

**Two ways to make holes:**

**Method A: Extrude Cut (simple but less flexible)**

1. Create a sketch on the TOP face of your link
2. Draw a circle where you want the hole (use `hole_diameter` parameter)
3. Press `E` for Extrude
4. Change **Operation** to **Cut**
5. Change **Extent** to **All** (cuts through entire body)
6. OK

**Method B: Hole Tool (recommended)**

1. Menu: **Create → Hole**
2. Click on the face where you want the hole
3. In the dialog:
   - **Placement:** Click to position (or type coordinates)
   - **Hole Type:** Simple
   - **Drill Point:** Flat (for through holes)
   - **Diameter:** Type `hole_diameter` (your parameter)
   - **Depth:** Select **All** from dropdown
4. OK

**Why Hole Tool is better:**
- Easier to edit later
- Can add counterbore/countersink
- Shows proper hole callout in drawings

#### Exercise 4.3: Revolve — Making a Shaft (20 minutes)

**Goal:** Create a 5mm diameter, 30mm long shaft

**Step-by-step:**

1. **Create sketch on XZ plane** (the vertical plane)

2. **Draw the shaft profile (half the cross-section):**
   - Press `L` for Line
   - Draw a vertical line from origin going UP, 30mm long
   - Draw a horizontal line from the top, going RIGHT, 2.5mm (half of 5mm diameter)
   - Draw a vertical line going DOWN, 30mm
   - Draw a horizontal line going LEFT back to origin
   - You should have a tall, thin rectangle (30mm × 2.5mm)

3. **Draw the axis:**
   - Press `L` for Line
   - Draw a line along the Y-axis (the left edge of your rectangle, from origin going up)
   - Menu: **Sketch → Normal/Construction**
   - Click the line — it becomes dashed (construction geometry, not part of the profile)

4. **Finish Sketch**

5. **Revolve:**
   - Menu: **Create → Revolve**
   - **Profile:** Click the rectangle profile
   - **Axis:** Click the dashed construction line
   - **Angle:** 360° (full revolution)
   - **Operation:** New Body
   - OK

**Result:** A cylindrical shaft, 5mm diameter × 30mm long

---

### LEVEL 5: Modifiers — Fillet, Chamfer, Shell (45 minutes)

#### Exercise 5.1: Filleting Edges (15 minutes)

**Why fillet?**
- Reduces stress concentration (sharp corners crack under load)
- Looks more professional
- Helps with 3D printing (sharp edges can lift)

**Step-by-step (using your extruded link):**

1. **Start Fillet:**
   - Menu: **Modify → Fillet**
   - Or: Press `F`

2. **Select edges:**
   - Click on an edge of your link (it highlights)
   - Hold **Ctrl** and click more edges to add them
   - For a link: select all the long edges (top and bottom perimeter)

3. **Set radius:**
   - In the dialog, type `2` for 2mm radius
   - Preview shows rounded edges

4. **OK**

**Tip:** Fillet AFTER making holes. If you fillet first, then add holes, you might cut through the fillets.

#### Exercise 5.2: Chamfer — Lead-In Edges (10 minutes)

**When to use chamfer instead of fillet:**
- Lead-in for pins/shafts (easier assembly)
- Aesthetic preference (industrial look)
- Reducing first-layer overhang in 3D printing

**Step-by-step:**

1. **Revolve a new shaft** (from Exercise 4.3) or use existing one

2. **Start Chamfer:**
   - Menu: **Modify → Chamfer**

3. **Select the circular edge** at one end of the shaft

4. **Set distance:**
   - Type `1` for 1mm chamfer
   - This creates a 45° bevel

5. **OK**

**Result:** The shaft now has a tapered lead-in, making it easier to insert into holes.

---

### LEVEL 6: Components & Assembly (2 hours)

This is where Fusion becomes powerful for mechanisms. **Each moving part must be its own component.**

#### Official Tutorial to Complete

**Watch:** "Assemblies" learning path
- **URL:** https://help.autodesk.com/view/fusion360/ENU/courses/AP-ASSEMBLE-OVERVIEW
- **Duration:** ~45 minutes
- **Covers:** Components, joints, motion

#### Key Concept: Components vs Bodies

| | Body | Component |
|---|------|-----------|
| **What it is** | A single solid shape | A container that holds bodies |
| **Can it move independently?** | NO | YES |
| **When to use** | Multiple features on ONE part | Multiple PARTS in an assembly |

**Rule:** For mechanisms, every part that moves independently = its own component.

#### Exercise 6.1: Creating Components — A Two-Link Assembly (30 minutes)

**Goal:** Create a crank and a coupler as separate components, then connect them.

**Step-by-step:**

1. **Create the first component (Crank):**
   - In Browser, right-click on the top-level component name (usually "Untitled")
   - Select **New Component**
   - A dialog appears. Name it `Crank`
   - Click OK
   - **Important:** Notice the component appears in Browser with a radio button. The filled radio button means it's ACTIVE.

2. **Activate the Crank component:**
   - Double-click `Crank` in Browser
   - The radio button fills in
   - **Everything you create now goes into this component**

3. **Create the Crank body:**
   - Create Sketch on XY plane
   - Draw a dogbone link: 30mm length × 12mm width × two 5.3mm holes
   - Finish Sketch
   - Extrude to 5mm thickness
   - Fillet edges with 2mm radius

4. **Create the second component (Coupler):**
   - **First, deactivate Crank:** Right-click `Crank` → Deactivate
   - Or: Double-click the top-level component to activate it
   - Right-click top-level → **New Component**
   - Name it `Coupler`
   - Double-click `Coupler` to activate it

5. **Create the Coupler body:**
   - Create Sketch on XY plane
   - Draw a dogbone link: 80mm length × 12mm width × two 5.3mm holes
   - Extrude 5mm, fillet 2mm

6. **View your components:**
   - In Browser, you should see:
     ```
     ▼ Untitled
       ▼ Crank
         ▼ Bodies
           Body1
         ▼ Sketches
       ▼ Coupler
         ▼ Bodies
           Body1
         ▼ Sketches
     ```

#### Exercise 6.2: Positioning Components (15 minutes)

Before adding joints, you need to position the components roughly where they should be.

**Step-by-step:**

1. **Move the Coupler:**
   - Click on the Coupler body to select it
   - Menu: **Modify → Move/Copy**
   - Or: Press `M`

2. **In the Move dialog:**
   - **Move Type:** Select "Point to Point"
   - **Point 1:** Click the center of the LEFT hole on the Coupler
   - **Point 2:** Click the center of the RIGHT hole on the Crank
   - The Coupler snaps so its left hole aligns with the Crank's right hole
   - Click OK

3. **Offset in Z direction:**
   - The components are now overlapping (same Z height)
   - Press `M` to Move again
   - Move Type: "Free Move"
   - Drag the Z arrow (blue) to offset the Coupler by 6mm (so they don't intersect)
   - Or: Type `6` in the Z Distance field

#### Exercise 6.3: Adding Joints (30 minutes)

Joints define HOW components can move relative to each other.

**Joint Types You'll Use:**

| Joint | DOF | What It Allows | Icon Look |
|-------|-----|----------------|-----------|
| **Revolute** | 1 | Rotation around an axis | Pin/hinge |
| **Slider** | 1 | Linear motion along an axis | Piston |
| **Cylindrical** | 2 | Rotation AND sliding along axis | Self-aligning pivot |
| **Rigid** | 0 | No motion (welded) | Lock |

**Step-by-step — Adding a Revolute Joint:**

1. **Ground the Crank first:**
   - Right-click `Crank` in Browser
   - Select **Ground**
   - A pushpin icon appears — Crank cannot move

2. **Start Joint:**
   - Menu: **Assemble → Joint**
   - Or: Press `J`

3. **Select connection points:**
   - **Component 1 (Crank):** Click the center of the RIGHT hole on Crank
     - Fusion highlights the circular edge — this tells it you want to use the hole center
   - **Component 2 (Coupler):** Click the center of the LEFT hole on Coupler
   - A preview shows the joint

4. **Choose joint type:**
   - In the dialog, **Motion Type:** Select **Revolute**
   - This allows rotation only (1 DOF)

5. **Flip if needed:**
   - If the Coupler flips to the wrong side, click **Flip** in the dialog
   - Use the arrow buttons to adjust alignment

6. **Click OK**

7. **Test the joint:**
   - Click and drag the Coupler — it should rotate around the joint
   - It's connected to the Crank but can spin freely

**The Cylindrical Joint Trick:**

If your joint doesn't work smoothly (binding, weird rotation), try **Cylindrical** instead of Revolute:
- Cylindrical adds an extra DOF (sliding along the axis)
- This makes it more forgiving if your geometry isn't perfectly aligned
- For cardboard prototypes translated to CAD, Cylindrical is often better

---

### LEVEL 7: Motion Study — Validating Your Mechanism (1.5 hours)

This is where you CHECK if your mechanism actually works before printing.

#### Official Tutorial

**Watch:** "Motion Study" tutorial
- **URL:** https://help.autodesk.com/view/fusion360/ENU/courses/AP-ASSEMBLE-MOTION-STUDY
- **Duration:** ~20 minutes

#### Exercise 7.1: Basic Motion Study — Spinning the Crank (20 minutes)

**Prerequisites:** You have a Crank and Coupler connected with a Revolute joint

**Step-by-step:**

1. **Open Motion Study:**
   - Menu: **Assemble → Motion Study**
   - Or: In the toolbar, find the Animation/Motion section
   - Click **New Motion Study**

2. **Select the driving joint:**
   - In the dialog, click **Select Joint**
   - Click on the joint connecting Crank to ground (or click the Crank component)
   - This is the INPUT — the joint that will be driven (like a motor)

3. **Configure motion:**
   - **Type:** Constant (continuous rotation)
   - **Speed:** 360 deg (one full rotation)
   - **Steps:** 36 (gives 10° per step — smooth enough to see problems)

4. **Play the animation:**
   - Click the **Play** button
   - Watch the Coupler move as the Crank rotates

5. **What to observe:**
   - Does the mechanism complete a full rotation?
   - Does anything look jerky or stuck?
   - Do parts pass through each other? (indicates interference)

6. **Close Motion Study** when done

#### Exercise 7.2: Building a Complete Four-Bar for Motion Study (45 minutes)

**Goal:** Create a full four-bar linkage and verify it works

**The four components you need:**

| Component | Length | Description |
|-----------|--------|-------------|
| **Base** | 100mm | Fixed link (ground) — just two holes, no movement |
| **Crank** | 30mm | Input link — connected to motor |
| **Coupler** | 90mm | Floating link — connects crank to rocker |
| **Rocker** | 70mm | Output link — rocks back and forth |

**Step-by-step:**

1. **Create Parameters:**
   ```
   base_length = 100 mm
   crank_length = 30 mm
   coupler_length = 90 mm
   rocker_length = 70 mm
   link_width = 12 mm
   link_thickness = 5 mm
   hole_diameter = 5.3 mm
   ```

2. **Create Base component:**
   - New Component → Name: `Base`
   - Sketch on XY: Two circles (holes), 100mm apart center-to-center
   - Extrude just the area around the holes (or make a simple bar)
   - This will be grounded

3. **Create Crank component:**
   - New Component → Name: `Crank`
   - Sketch on XY: Dogbone, `crank_length` long
   - Extrude `link_thickness`

4. **Create Coupler component:**
   - New Component → Name: `Coupler`
   - Sketch on XY: Dogbone, `coupler_length` long
   - Extrude `link_thickness`

5. **Create Rocker component:**
   - New Component → Name: `Rocker`
   - Sketch on XY: Dogbone, `rocker_length` long
   - Extrude `link_thickness`

6. **Ground the Base:**
   - Right-click Base → Ground

7. **Position and Joint the Crank to Base:**
   - Move Crank so its left hole aligns with Base's left hole
   - Assemble → Joint → Revolute
   - Connect Crank's left hole to Base's left hole

8. **Position and Joint the Rocker to Base:**
   - Move Rocker so its left hole aligns with Base's RIGHT hole
   - Joint → Revolute
   - Connect Rocker's left hole to Base's right hole

9. **Position and Joint the Coupler:**
   - Move Coupler to connect Crank and Rocker
   - Joint → Revolute: Coupler's left hole to Crank's right hole
   - Joint → Revolute: Coupler's right hole to Rocker's right hole

10. **Verify joint count:**
    - You should have 4 Revolute joints
    - Mechanism should have 1 DOF (move crank → everything else follows)

11. **Run Motion Study:**
    - New Motion Study
    - Drive the Crank joint
    - 360° rotation
    - Play and observe

**What to check:**
- Does the crank complete a full 360°?
- Does the coupler maintain its shape (not stretch)?
- Does the rocker oscillate smoothly?

#### Exercise 7.3: The 4-Position Verification (Critical!) (20 minutes)

**Why this matters:** A linkage can LOOK correct in CAD but be physically impossible. The coupler would need to stretch or compress, which real materials can't do.

**Step-by-step verification:**

1. **Open your four-bar assembly**

2. **Manually position at 0°:**
   - Right-click the Crank-to-Base joint in Browser
   - Select **Edit Joint**
   - In the dialog, manually set rotation to `0°`
   - OK

3. **Measure the coupler:**
   - Menu: **Inspect → Measure**
   - Click the center of the Coupler's LEFT hole
   - Click the center of the Coupler's RIGHT hole
   - Note the distance: _______ mm

4. **Repeat at 90°, 180°, 270°:**
   - Edit the Crank-to-Base joint to each angle
   - Measure the coupler each time

   | Crank Angle | Measured Coupler Length |
   |-------------|------------------------|
   | 0° | _____ mm |
   | 90° | _____ mm |
   | 180° | _____ mm |
   | 270° | _____ mm |

5. **Evaluate:**
   - **All measurements within 0.01mm:** Valid mechanism
   - **Variation 0.01-0.1mm:** Might work with tolerance
   - **Variation >0.1mm:** Impossible mechanism — your joint positions are wrong

**If it fails:** One of your pivot positions is wrong. Check that:
- Base holes are exactly `base_length` apart
- Link lengths match your parameters
- Joints are at hole CENTERS, not edges

---

### LEVEL 8: Export for 3D Printing (30 minutes)

#### Exercise 8.1: Exporting a Single Component (10 minutes)

**Step-by-step:**

1. **Activate the component you want to export:**
   - Double-click the component in Browser

2. **Right-click the component → Save As Mesh**

3. **Configure export:**
   - **Format:** STL (most universal) or 3MF (better, preserves more data)
   - **Structure:** One File
   - **Refinement:** High (for mechanism parts where precision matters)

4. **Save to your project folder**

5. **Repeat for each component**

#### Print Orientation Guidelines

| Part Type | Orientation | Why |
|-----------|-------------|-----|
| Links | Flat on bed (holes vertical) | Maximum strength across the link |
| Shafts/Pins | Standing vertical | Layer lines along length = stronger |
| Cams | Flat on bed | Smooth profile surface |
| Frames | Minimize overhangs | Less support material needed |

---

### QUICK REFERENCE: Keyboard Shortcuts

| Shortcut | Action | When To Use |
|----------|--------|-------------|
| `S` | Sketch toolbar (search) | Find any sketch tool |
| `L` | Line | Drawing sketch lines |
| `R` | Rectangle | Drawing rectangles |
| `C` | Circle | Drawing circles |
| `D` | Dimension | Adding dimensions |
| `T` | Trim | Cleaning up sketches |
| `E` | Extrude | Creating 3D bodies |
| `F` | Fillet | Rounding edges |
| `M` | Move | Positioning components |
| `J` | Joint | Connecting components |
| `Shift+D` | Parameters | Opening parameter dialog |
| `Ctrl+Z` | Undo | Fixing mistakes |
| `Ctrl+S` | Save | Save often! |
| `F6` | Capture Position | Save component positions |

---

### PRACTICE PROJECT: Complete Four-Bar Linkage (2-3 hours)

**This project combines everything from Levels 1-8.**

**Goal:** Design, assemble, verify, and export a working four-bar linkage.

**Specification:**
```
Base:      100 mm (fixed pivot distance)
Crank:      30 mm (input)
Coupler:    90 mm (floating)
Rocker:     70 mm (output)
All links:  12 mm wide × 5 mm thick
Holes:      5.3 mm diameter (5mm pin + 0.3mm clearance)
```

**Checklist:**

- [ ] Parameters created (all 8 standard parameters)
- [ ] Base component created and grounded
- [ ] Crank component created with dogbone profile
- [ ] Coupler component created
- [ ] Rocker component created
- [ ] All components have fillets (2mm radius)
- [ ] Crank jointed to Base (Revolute)
- [ ] Rocker jointed to Base (Revolute)
- [ ] Coupler jointed to Crank (Revolute)
- [ ] Coupler jointed to Rocker (Revolute)
- [ ] Motion Study: Crank completes full 360°
- [ ] 4-Position Verification: Coupler length constant (±0.01mm)
- [ ] All components exported as STL/3MF

**Estimated time:** 2-3 hours for first attempt, under 1 hour once proficient.

---

## What's Next?

After completing all 8 levels and the practice project, you're ready to:
1. Design your own mechanisms in Fusion 360
2. Use Motion Study to validate before printing
3. Export for 3D printing with correct tolerances

**Companion files:**
- `13_WALL_CHEATSHEETS.md` — Fusion 360 quick reference for your wall
- `14_DESIGN_THINKING_FRAMEWORK.md` — The design process that comes BEFORE Fusion
- `02_CARDBOARD_PROTOTYPING_CURRICULUM.md` — Cardboard first, THEN Fusion
