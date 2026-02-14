# WALL CHEAT SHEETS — Print These Out

---

# SHEET 1: THE 5 CORE MECHANISMS (90% of Kinetic Sculpture)

```
┌─────────────────────────────────────────────────────────────────┐
│  1. FOUR-BAR LINKAGE                                            │
│     Input: Rotation → Output: Complex curved path               │
│                                                                 │
│     ●━━━━━━━━●        GRASHOF RULE:                             │
│     │        │        S + L ≤ P + Q                             │
│     │        │        (shortest + longest ≤ sum of others)      │
│     ●━━━━━━━━●        If violated → LOCKS UP                    │
│      (ground)                                                   │
│                                                                 │
│     USE FOR: Walking legs, wing flapping, wave motion           │
├─────────────────────────────────────────────────────────────────┤
│  2. CAM & FOLLOWER                                              │
│     Input: Rotation → Output: ANY motion profile you want       │
│                                                                 │
│        ╭───╮                                                    │
│       ╱     ╲  ←cam     RULE: Steep slope = fast motion         │
│      ╱       ╲               = high force required              │
│     ●─────────          Gradual slope = smooth motion           │
│         ↑                                                       │
│      follower           USE FOR: Breath cycles, pauses (dwell), │
│                                  precise timing                 │
├─────────────────────────────────────────────────────────────────┤
│  3. SLIDER-CRANK                                                │
│     Input: Rotation ↔ Output: Linear (back-forth)               │
│                                                                 │
│        ●                RULE: Stroke = 2 × crank radius         │
│       /│                Offset crank = asymmetric timing        │
│      / │                                                        │
│     ●──┼──→             USE FOR: Pistons, waves, pumping        │
│        │                                                        │
├─────────────────────────────────────────────────────────────────┤
│  4. GENEVA MECHANISM                                            │
│     Input: Continuous rotation → Output: Intermittent steps     │
│                                                                 │
│      ╲ │ ╱              RULE: More slots = smoother             │
│       ╲│╱                      but less dwell time              │
│     ───●───             4-slot: 90° motion, 270° dwell          │
│       ╱│╲               6-slot: 60° motion, 300° dwell          │
│      ╱ │ ╲                                                      │
│                         USE FOR: Scene changes, indexing,       │
│                                  dramatic pauses                │
├─────────────────────────────────────────────────────────────────┤
│  5. ECCENTRIC DRIVE                                             │
│     Input: Rotation → Output: Oscillation                       │
│                                                                 │
│       ╭─●─╮             RULE: Offset = amplitude                │
│       │ ↑ │             Bigger offset = bigger swing            │
│       ╰───╯                                                     │
│         │               USE FOR: Swaying, nodding, breathing,   │
│         ↓                        any gentle back-forth          │
└─────────────────────────────────────────────────────────────────┘
```

---

# SHEET 2: THE 7 RECOGNITION TRIGGERS (When to Ask AI)

```
┌─────────────────────────────────────────────────────────────────┐
│  WHEN YOU NOTICE...           ASK AI...                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. "Linkage might lock up"   → "Check Grashof for [a,b,c,d]"   │
│                                                                 │
│  2. "Motion jerky at angle X" → "Transmission angle at X°?"     │
│                                                                 │
│  3. "Parts don't stay same    → "Verify coupler at 0°/90°/      │
│      distance apart"             180°/270°"                     │
│                                                                 │
│  4. "Motor struggling"        → "Power budget for [mass] at     │
│                                  [speed]?"                      │
│                                                                 │
│  5. "Mechanism feels sloppy"  → "Tolerance stack for [N]        │
│                                  joints at [X]mm?"              │
│                                                                 │
│  6. "Need specific speed"     → "Gear ratio: [in RPM] to        │
│                                  [out RPM]?"                    │
│                                                                 │
│  7. "Elements too synced"     → "Phase offset for [N] elements  │
│                                  to look natural?"              │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  YOU RECOGNIZE  →  AI CALCULATES  →  YOU BUILD & VERIFY         │
└─────────────────────────────────────────────────────────────────┘
```

---

# SHEET 3: THE CORE LOOP (What Pros Do)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│    ┌──────────────────────────────────────┐                     │
│    │  1. INTENT                           │                     │
│    │     "I want THIS motion"             │                     │
│    └──────────────┬───────────────────────┘                     │
│                   ↓                                             │
│    ┌──────────────────────────────────────┐                     │
│    │  2. MECHANISM SELECTION              │                     │
│    │     Which of the Big 5?              │                     │
│    └──────────────┬───────────────────────┘                     │
│                   ↓                                             │
│    ┌──────────────────────────────────────┐                     │
│    │  3. SKETCH / CARDBOARD               │ ← Feel it first     │
│    │     Hands-on prototype               │                     │
│    └──────────────┬───────────────────────┘                     │
│                   ↓                                             │
│    ┌──────────────────────────────────────┐                     │
│    │  4. FUSION 360 MODEL                 │ ← Parametric        │
│    │     Joints + Motion Study            │                     │
│    └──────────────┬───────────────────────┘                     │
│                   ↓                                             │
│    ┌──────────────────────────────────────┐                     │
│    │  5. 3D PRINT + TEST                  │                     │
│    │     Does reality match simulation?   │                     │
│    └──────────────┬───────────────────────┘                     │
│                   ↓                                             │
│    ┌──────────────────────────────────────┐                     │
│    │  6. DIAGNOSE DELTA                   │                     │
│    │     Why is it different? Fix it.     │                     │
│    └──────────────┬───────────────────────┘                     │
│                   │                                             │
│                   └──────────→ LOOP BACK TO 4                   │
│                                                                 │
│    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│    Pros take 2-3 WEEKS per loop.                                │
│    You take 2-3 DAYS (Fusion + 3D printer + AI).                │
│    That's your 7x compression.                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

# SHEET 4: FUSION 360 QUICK REFERENCE

```
┌─────────────────────────────────────────────────────────────────┐
│  JOINT SELECTION (Pick the right one first time)                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  REVOLUTE      Simple rotation (hinge)                          │
│  ●─────●       Use when: Axes perfectly aligned                 │
│                                                                 │
│  CYLINDRICAL   Rotation + sliding                               │
│  ●═════●       Use when: Axes might be slightly off             │
│                ** USE THIS WHEN REVOLUTE FAILS **               │
│                                                                 │
│  SLIDER        Linear motion only                               │
│  ●─────→       Use when: Rail, piston, track                    │
│                                                                 │
│  RIGID GROUP   Lock parts together                              │
│  [●●●]         Use when: Multiple parts = one piece             │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  PARAMETRIC SETUP (Do this EVERY time)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Modify → Change Parameters → Add:                           │
│     • crank_length = 50 mm                                      │
│     • coupler_length = 80 mm                                    │
│     • clearance = 0.3 mm  (from YOUR tolerance chart)           │
│                                                                 │
│  2. In sketches: Type parameter NAME, not number                │
│     Change parameter once → whole model updates                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  MOTION STUDY CHECKLIST                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  □ All joints created and LABELED (not Joint1, Joint2...)       │
│  □ One joint = "driver" (motor input)                           │
│  □ Driver set to 0° → 360°                                      │
│  □ Steps: 36 minimum                                            │
│  □ Watch for: collision, binding, unexpected stops              │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  EXPORT FOR PRINT                                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  • Holes: Add clearance to diameter                             │
│  • Pins: Print VERTICAL (layer lines = strength)                │
│  • Links: Print FLAT                                            │
│  • Format: STL or 3MF, High refinement                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# SHEET 4B: FUSION 360 KEYBOARD SHORTCUTS (Memorize These)

```
┌─────────────────────────────────────────────────────────────────┐
│  MOST USED (Learn these first week)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  S            Search commands (type anything)                   │
│  L            Line tool                                         │
│  C            Circle                                            │
│  R            Rectangle                                         │
│  D            Dimension (constrain your sketch!)                │
│  E            Extrude                                           │
│  Q            Press/Pull (quick extrude)                        │
│  M            Move/Copy                                         │
│  J            Joint (assembly)                                  │
│  A            Appearance                                        │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  NAVIGATION (Use constantly)                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Middle Mouse      Orbit (rotate view)                          │
│  Shift + Middle    Pan (move view)                              │
│  Scroll Wheel      Zoom in/out                                  │
│  F                 Fit all to screen                            │
│  Home              Home view                                    │
│  Numpad 1-6        Standard views (Front, Back, Top, etc.)      │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  SKETCH MODE                                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  X            Construction line (reference, won't extrude)      │
│  O            Offset (parallel copy of edge)                    │
│  T            Trim (cut away sketch lines)                      │
│  F            Fillet (round corners)                            │
│  I            Measure                                           │
│  P            Project (bring edge into sketch)                  │
│  Esc          Finish current tool / Exit sketch                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  MODELING                                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  E            Extrude                                           │
│  H            Hole                                              │
│  F            Fillet (round edges)                              │
│  Shift + F    Chamfer (angled edges)                            │
│  Ctrl + C     Copy                                              │
│  Ctrl + V     Paste                                             │
│  Ctrl + Z     Undo (use liberally!)                             │
│  Ctrl + Y     Redo                                              │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ASSEMBLY & JOINTS                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  J            Joint                                             │
│  G            As-Built Joint (position first, then constrain)   │
│  Ctrl + D     Drive Joint (test motion manually)                │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  VISIBILITY                                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  V            Toggle component visibility                       │
│  Ctrl + 1     Show all components                               │
│  Ctrl + 2     Hide all components                               │
│  Alt + drag   Isolate component (hide everything else)          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# SHEET 4C: FUSION 360 TIPS & TRICKS (Time Savers)

```
┌─────────────────────────────────────────────────────────────────┐
│  SKETCH TIPS (Avoid headaches)                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✓ ALWAYS fully constrain sketches (black lines, not blue)      │
│    Blue = underconstrained = will move unexpectedly later       │
│                                                                 │
│  ✓ Use construction lines (X key) for reference geometry        │
│    They guide your sketch but don't create solid features       │
│                                                                 │
│  ✓ Start sketches from ORIGIN when possible                     │
│    Makes parametric changes predictable                         │
│                                                                 │
│  ✓ Name your sketches! Right-click → Rename                     │
│    "Sketch47" means nothing. "crank_profile" means everything   │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  COMPONENT TIPS (Critical for mechanisms)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✓ Create components BEFORE drawing bodies                      │
│    Right-click root → New Component → THEN sketch inside it     │
│    Bodies in root = assembly nightmare later                    │
│                                                                 │
│  ✓ One mechanism part = One component                           │
│    Crank = component. Coupler = component. Ground = component.  │
│                                                                 │
│  ✓ Activate component before sketching (double-click it)        │
│    Green dot = active. Sketch goes into THAT component.         │
│                                                                 │
│  ✓ Use "Ground" to lock the base component                      │
│    Right-click component → Ground                               │
│    Everything moves relative to grounded component              │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  JOINT TIPS (Avoid the #1 beginner mistake)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✓ Position parts FIRST, then joint                             │
│    Use Move tool (M) to put parts where they belong             │
│    Then add joint to lock that relationship                     │
│                                                                 │
│  ✓ Joint failing? Try "As-Built Joint" (G)                      │
│    Captures current position without moving parts               │
│                                                                 │
│  ✓ Revolute failing? Use Cylindrical instead                    │
│    Cylindrical is more forgiving of alignment issues            │
│                                                                 │
│  ✓ Click the EDGE of a hole, not the face                       │
│    For rotational joints, edge selection works better           │
│                                                                 │
│  ✓ Test joints immediately with Drive Joint (Ctrl+D)            │
│    Don't wait until full assembly to discover problems          │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  PARAMETRIC TIPS (Your secret weapon)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✓ Modify → Change Parameters (bookmark this!)                  │
│    Create ALL your dimensions here FIRST                        │
│                                                                 │
│  ✓ Use formulas in parameters:                                  │
│    hole_dia = pin_dia + clearance                               │
│    stroke = crank_radius * 2                                    │
│    gear_ratio = driven_teeth / driver_teeth                     │
│                                                                 │
│  ✓ Link parameters across components                            │
│    Both parts reference same "pin_dia" = always match           │
│                                                                 │
│  ✓ Favorite parameters: Add to Favorites for quick access       │
│    Star icon next to parameter name                             │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  MOTION STUDY TIPS                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✓ Use Contact Sets for collision detection                     │
│    Assemble → Enable Contact Sets → Add parts that might touch  │
│                                                                 │
│  ✓ Motion Links for synchronized mechanisms                     │
│    Assemble → Motion Link → Link two joints mathematically      │
│    Example: Gear A rotates → Gear B rotates at 2:1 ratio        │
│                                                                 │
│  ✓ Record motion study as video                                 │
│    Right-click animation → Export as Video                      │
│    Great for documentation and troubleshooting                  │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  EXPORT TIPS (Get prints right first time)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✓ Right-click component → Save As Mesh → STL                   │
│    Don't export whole assembly if you just need one part        │
│                                                                 │
│  ✓ Use "High" refinement for mechanism parts                    │
│    Low refinement = faceted circles = bad bearing surfaces      │
│                                                                 │
│  ✓ Check units before export (should be mm)                     │
│    File → 3D Print → check "Send to 3D Print Utility"           │
│                                                                 │
│  ✓ Section Analysis before printing                             │
│    Inspect → Section Analysis → see inside your model           │
│    Catch hidden geometry issues before wasting filament         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# SHEET 4D: FUSION 360 WORKFLOW FOR MECHANISMS

```
┌─────────────────────────────────────────────────────────────────┐
│  THE MECHANISM WORKFLOW (Follow this order every time)          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  STEP 1: SETUP                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ □ Create new design                                        │ │
│  │ □ Modify → Change Parameters → Add all dimensions          │ │
│  │ □ Create component: "ground" (the fixed base)              │ │
│  │ □ Ground it (right-click → Ground)                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                         ↓                                       │
│  STEP 2: MODEL EACH PART                                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ □ Create component for each moving part                    │ │
│  │ □ Activate component (double-click)                        │ │
│  │ □ Sketch → reference parameters, not numbers               │ │
│  │ □ Extrude                                                  │ │
│  │ □ Add holes (reference pin_dia + clearance)                │ │
│  │ □ Repeat for all parts                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                         ↓                                       │
│  STEP 3: POSITION                                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ □ Use Move tool (M) to arrange parts                       │ │
│  │ □ Align holes visually                                     │ │
│  │ □ Check for interference (parts overlapping)               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                         ↓                                       │
│  STEP 4: JOINTS                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ □ Add joints (J) one at a time                             │ │
│  │ □ Test each joint immediately (Ctrl+D to drive)            │ │
│  │ □ Label every joint meaningfully                           │ │
│  │ □ If joint fails → try Cylindrical instead of Revolute     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                         ↓                                       │
│  STEP 5: MOTION STUDY                                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ □ Assemble → Motion Study → New                            │ │
│  │ □ Set driver joint: 0° to 360°                             │ │
│  │ □ Steps: 36 minimum                                        │ │
│  │ □ Play animation                                           │ │
│  │ □ Watch for: binding, collision, unexpected behavior       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                         ↓                                       │
│  STEP 6: VERIFY (Before ANY print)                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ □ Check coupler length at 0°, 90°, 180°, 270°              │ │
│  │   (Inspect → Measure → should be IDENTICAL)                │ │
│  │ □ Check for part collision                                 │ │
│  │ □ Check clearances are applied to all holes                │ │
│  └────────────────────────────────────────────────────────────┘ │
│                         ↓                                       │
│  STEP 7: EXPORT                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ □ Right-click each component → Save As Mesh → STL          │ │
│  │ □ High refinement                                          │ │
│  │ □ Check orientation for print (pins vertical!)             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# SHEET 5: YOUR TOLERANCE CHART (Fill in YOUR numbers)

```
┌─────────────────────────────────────────────────────────────────┐
│  MY PRINTER: ___________________    DATE: __________            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PIN JOINTS (5mm pin in hole)                                   │
│  ┌───────────┬──────────┬───────────────────────┐               │
│  │ Clearance │ Result   │ Use For               │               │
│  ├───────────┼──────────┼───────────────────────┤               │
│  │ 0.1 mm    │ ________ │                       │               │
│  │ 0.2 mm    │ ________ │                       │               │
│  │ 0.3 mm    │ ________ │                       │               │
│  │ 0.4 mm    │ ________ │                       │               │
│  │ 0.5 mm    │ ________ │                       │               │
│  └───────────┴──────────┴───────────────────────┘               │
│                                                                 │
│  MY SWEET SPOT: _______ mm                                      │
│                                                                 │
│  SLIDER TRACKS                                                  │
│  ┌───────────┬──────────┬───────────────────────┐               │
│  │ Clearance │ Result   │ Use For               │               │
│  ├───────────┼──────────┼───────────────────────┤               │
│  │ 0.15 mm   │ ________ │                       │               │
│  │ 0.25 mm   │ ________ │                       │               │
│  │ 0.35 mm   │ ________ │                       │               │
│  │ 0.45 mm   │ ________ │                       │               │
│  └───────────┴──────────┴───────────────────────┘               │
│                                                                 │
│  RULE: Never exceed 5 joints in series without preload          │
│        5 joints × 0.3mm = 1.5mm total slop (too much!)          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# SHEET 6: MOTION AESTHETICS (Make It Feel Alive)

```
┌─────────────────────────────────────────────────────────────────┐
│  THE BREATH CYCLE (Nature's rhythm)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  INHALE ─────────────────╲                                      │
│  (slow, building)         ╲                                     │
│                            ╲    EXHALE                          │
│                             ╲   (faster, releasing)             │
│                              ╲                                  │
│  ────────────────────────────╲________ PAUSE                    │
│                                                                 │
│  Ratio: 3:1 (inhale 3 beats : exhale 1 beat)                    │
│  Implement with: Asymmetric cam OR offset slider-crank          │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  GOLDEN PHASE ANGLE: 137.5°                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  When you have multiple similar elements (leaves, waves,        │
│  stars), offset each by 137.5°                                  │
│                                                                 │
│  Element 1:   0.0°                                              │
│  Element 2: 137.5°                                              │
│  Element 3: 275.0° (= 137.5° × 2)                               │
│  Element 4:  52.5° (= 137.5° × 3, wrapped)                      │
│                                                                 │
│  Result: Natural, non-repeating rhythm (sunflower pattern)      │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  DISNEY PRINCIPLES FOR MECHANISMS                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ANTICIPATION    Small opposite motion before main action       │
│  FOLLOW-THROUGH  Overshoot, then settle (use compliant parts)   │
│  SLOW IN/OUT     Ease at start and end (cam profiles)           │
│  SECONDARY       Background elements at different speeds        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# SHEET 7: 18-MONTH ROADMAP (One Page)

```
┌─────────────────────────────────────────────────────────────────┐
│  MONTH   HOURS    FOCUS                      DELIVERABLE        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1       ~50      Foundation                 Escapement +       │
│                   Escapement + Tolerances    Tolerance Chart    │
│                   Four-bar basics                               │
│                                                                 │
│  2-3     ~150     Mechanism Vocabulary       5 mechanisms       │
│                   Big 5 + Integration        built              │
│                                                                 │
│  4-6     ~300     First Sculpture            Wave Panel         │
│                   Design → Build → Polish    (complete)         │
│                                                                 │
│  7-9     ~450     Project-Based              Walking Creature   │
│                   + Reverse Engineering      + 2nd sculpture    │
│                                                                 │
│  10-12   ~600     Advanced Integration       Narrative Scene    │
│                   + Personal Style           + 3rd sculpture    │
│                                                                 │
│  13-18   ~900     Mastery Refinement         6+ sculptures      │
│                   Portfolio Building         Portfolio ready    │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  WEEKLY RHYTHM (11-14 hrs/week)                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  WEEKDAY 1 (2-3 hrs): Cardboard/hands-on OR Fusion modeling     │
│  WEEKDAY 2 (2-3 hrs): Continue OR print test                    │
│  WEEKDAY 3 (2-3 hrs): Iterate OR troubleshoot                   │
│  WEEKEND  (5 hrs):    Power session — major build/integration   │
│                                                                 │
│  Every session: 10 min review → Main work → 10 min document     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# SHEET 8: OFF-THE-SHELF COMPONENTS (Don't Reinvent These)

```
┌─────────────────────────────────────────────────────────────────┐
│  NEED              USE THIS                  WHERE TO GET       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Bearing           608 skateboard bearing    Amazon, $0.50/ea   │
│                    (8mm bore, everywhere)                       │
│                                                                 │
│  Small shaft       1.75mm 3D printer         You have this      │
│                    filament                                     │
│                                                                 │
│  Precision pin     3mm steel dowel           Hardware store     │
│                                                                 │
│  Spring            TPU printed flexure       Design it          │
│                                                                 │
│  Tension member    Guitar string OR          Music store        │
│                    fishing line              Walmart             │
│                                                                 │
│  Low-friction      Brass tubing              Hobby shop         │
│  sleeve            (telescoping sizes)                          │
│                                                                 │
│  Motor             28BYJ-48 stepper          Amazon, $2/ea      │
│  (slow, quiet)     with ULN2003 driver                          │
│                                                                 │
│  Motor             N20 DC gear motor         Amazon, $3/ea      │
│  (adjustable)      (various ratios)                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# QUICK SUMMARY: The Plan In 30 Seconds

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   WHAT YOU DO:      Recognize patterns, ask AI, build, verify   │
│   WHAT AI DOES:     Calculate, generate options, explain why    │
│                                                                 │
│   WORKFLOW:         Cardboard → Fusion → Print → Iterate        │
│                     (same week, not sequential phases)          │
│                                                                 │
│   TIME:             11-14 hrs/week × 18 months = ~900 hours     │
│                                                                 │
│   RESULT:           6+ sculptures, museum-quality,              │
│                     personal style recognizable                 │
│                                                                 │
│   START:            Tonight — Run the Impossible Test           │
│                     Week 1 — Cardboard escapement               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

---

# SHEET 9: CHEAT CODES (Insider Tips)

```
┌─────────────────────────────────────────────────────────────────┐
│  7 CHEAT CODES FOR FASTER MECHANISM DESIGN                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  #1 CYLINDRICAL JOINT HACK                                      │
│     Revolute joints fail ~40% of the time (alignment issues)    │
│     → Use Cylindrical instead — self-corrects alignment         │
│     Time saved: 30+ min per joint debug                        │
│                                                                 │
│  #2 MOTION LINK FOR COUPLED MECHANISMS                          │
│     Multiple joints need synced motion (gear trains, etc.)      │
│     → Fusion: Assemble → Motion Link                           │
│     Links joint motions mathematically (exact ratio)           │
│                                                                 │
│  #3 THE 4-POSITION VERIFICATION RITUAL                          │
│     Measure coupler at 0°, 90°, 180°, 270°                     │
│     If length varies >0.01mm → mechanism is IMPOSSIBLE          │
│     Catches 90% of linkage errors before printing              │
│                                                                 │
│  #4 TOLERANCE STACK SHORTCUT                                    │
│     8 joints × ±0.2mm = ±1.6mm total slop!                    │
│     RULE: Never exceed 5 joints in series without preload      │
│     Preload: Spring tension, gravity bias, flexure return      │
│                                                                 │
│  #5 OFF-THE-SHELF SOURCING                                      │
│     DON'T design: bearings, springs, fasteners, shafts         │
│     608 bearing ($0.50) • 1.75mm filament (free shaft)         │
│     Guitar string (tension) • 3mm dowel (precision pin)        │
│     TPU flexure (spring)                                       │
│                                                                 │
│  #6 PYTHON API MULTIPLIER                                       │
│     Need 20 link-length variants? Python batch script:          │
│     Modify Fusion parameters → batch export STLs               │
│     Generate 50 variants overnight, test best 5 in morning     │
│                                                                 │
│  #7 GIM FOR COUPLER CURVES                                      │
│     Fusion can't visualize coupler curves directly              │
│     → Use GIM (free linkage software) to design curve FIRST    │
│     → Get link lengths → Build in Fusion → Print               │
│     Design the CURVE first, mechanism second                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

---

# SHEET 10: MATERIAL SELECTION FOR KINETIC MECHANISMS

📋 **REFERENCE SHEET** — Look up when choosing materials. Don't memorize.

```
┌─────────────────────────────────────────────────────────────────┐
│  MATERIAL SELECTION GUIDE                                        │
│  "What should I make this part from?"                            │
├──────────────┬──────────────────┬───────────────┬───────────────┤
│  Material    │  Best For        │  Watch Out    │  Expert Tip   │
├──────────────┼──────────────────┼───────────────┼───────────────┤
│  CARDBOARD   │  ALL prototypes  │  Humidity     │  "10 cardboard│
│              │  Mechanism logic  │  warping      │  iterations = │
│              │  First builds    │               │  1 informed   │
│              │                  │               │  CAD design"  │
├──────────────┼──────────────────┼───────────────┼───────────────┤
│  PLA         │  Bodies, frames  │  ANISOTROPIC  │  Use 3        │
│  (3D print)  │  Cam profiles    │  (weak layers)│  perimeters   │
│              │  Brackets        │  High friction│  for shear    │
│              │                  │  NEVER use as │  parts.       │
│              │                  │  bearing!     │  ≈0.3mm       │
│              │                  │               │  clearance    │
├──────────────┼──────────────────┼───────────────┼───────────────┤
│  PETG        │  Parts needing   │  Strings when │  Better UV    │
│  (3D print)  │  flex/impact     │  printing     │  resistance   │
│              │                  │               │  than PLA     │
├──────────────┼──────────────────┼───────────────┼───────────────┤
│  WOOD        │  Structural      │  Warps with   │  D.C. Roy     │
│  (Baltic     │  frames,         │  humidity.    │  uses only    │
│   Birch)     │  aesthetic       │  Weak ⊥ to    │  laminated    │
│              │  elements        │  grain        │  Baltic birch │
├──────────────┼──────────────────┼───────────────┼───────────────┤
│  BRASS       │  Shafts, pins    │  Requires     │  Dug North:   │
│              │  Mechanism parts │  soldering    │  "Looks good  │
│              │  Small gears     │  skill        │  with wood,   │
│              │                  │               │  easy to work"│
├──────────────┼──────────────────┼───────────────┼───────────────┤
│  STEEL       │  Springs,        │  Rusts!       │  Ganson makes │
│  (music wire)│  shafts,         │  Hard to cut  │  wire gears   │
│              │  axles           │               │  from this    │
├──────────────┼──────────────────┼───────────────┼───────────────┤
│  BALL        │  ALL pivot       │  Shielded ≠   │  ALWAYS use   │
│  BEARINGS    │  points!         │  Sealed!      │  SEALED for   │
│              │  Motor shafts    │  Shielded     │  outdoor.     │
│              │  Rotating joints │  rust indoors │  Bronze for   │
│              │                  │  too.         │  wet/marine.  │
├──────────────┴──────────────────┴───────────────┴───────────────┤
│                                                                  │
│  🔴 NEVER: PLA bearings, printed shafts, unlubed metal-on-metal│
│  🟢 ALWAYS: Real bearings at pivots, brass/steel for shafts     │
│  💡 HYBRID: 3D print body + metal shaft + ball bearing = best   │
│                                                                  │
│  Bearing disaster story (Practical Machinist forum):             │
│  "A pivot ball bearing seized after 2 years outdoors from       │
│   condensation rust. Switched to bronze." — Use SEALED.          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

**Print these 10 sheets. Put them on your wall. Reference them constantly.**

Your tolerance chart (Sheet 5) stays BLANK until you fill it in Week 2. That's YOUR data, not generic internet numbers.
