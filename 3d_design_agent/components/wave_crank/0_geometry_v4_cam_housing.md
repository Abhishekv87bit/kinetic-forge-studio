# GEOMETRY CHECKLIST - WAVE OCEAN v4 (Cam-in-Housing Design)

**Mechanism:** Elliptical cam rotating inside rectangular housing
**Key insight:** Cam contacts ALL 4 walls → compound motion (Z + Y)

---

## Part 1: Given Constraints

```
Canvas Z clearance: 80mm
Wave length (Y): 70mm
Wave thickness (X): 4mm

Hinge slot: 12mm (Y) × 4mm (Z) × 4mm (X depth)
Cam housing: 10mm (Y) × 14mm (Z) × 4mm (X depth)

Both cutouts are 4mm deep (same as wave thickness)
```

---

## Part 2: Cam Size Calculation

**Housing interior: 10mm (Y) × 14mm (Z)**

For elliptical cam to contact ALL 4 walls:
```
When θ=0° (major axis horizontal):
  - Cam touches LEFT and RIGHT walls (Y direction)
  - Cam major axis must equal housing Y width
  - Major axis = 10mm

When θ=90° (major axis vertical):
  - Cam touches TOP and BOTTOM walls (Z direction)
  - Cam major axis must equal housing Z height
  - Major axis = 14mm

WAIT - This is a contradiction!
```

**Problem Identified:**
- Housing is 10×14mm (not square)
- An ellipse with major=14 would hit Y walls when vertical
- An ellipse with major=10 would not reach Z walls

**Solution Options:**

### Option A: Use Circular Cam (Equal contact)
```
Cam diameter = 10mm (fits Y width)
Housing Z height = 14mm
Vertical travel = 14 - 10 = 4mm (cam slides up/down)
Y travel = 0mm (cam fills Y width)

RESULT: Only Z motion, no Y motion
NOT what user wants
```

### Option B: Use Smaller Elliptical Cam (Clearance on all sides)
```
If housing is 10×14mm:
  Cam major axis = 12mm (for Z contact)
  Cam minor axis = 8mm (for Y contact)

At θ=0° (horizontal):
  - Cam width in Y = 12mm > 10mm housing width
  - COLLISION! Cam too wide

DOESN'T WORK
```

### Option C: Resize Housing to be Square
```
If housing is 14×14mm:
  Cam major = 14mm, minor = 10mm

At θ=0° (major horizontal):
  - Cam width in Y = 14mm = housing Y → contacts Y walls
  - Cam height in Z = 10mm < 14mm → 4mm vertical play

At θ=90° (major vertical):
  - Cam height in Z = 14mm = housing Z → contacts Z walls
  - Cam width in Y = 10mm < 14mm → 4mm horizontal play

At θ=45° (diagonal):
  - Need to verify no jamming...
```

### Option D: Racetrack/Oval Housing (Matched to Cam)
```
Housing shape matches cam's swept path
More complex geometry but guaranteed smooth motion
```

---

## Part 3: Recommended Solution

**Use SQUARE housing with ELLIPTICAL cam:**

```
Housing: 14mm × 14mm (square)
Cam major axis: 14mm (touches walls at 0° and 90°)
Cam minor axis: 10mm (4mm travel in perpendicular direction)

Travel in Z: ±(14-10)/2 = ±2mm (4mm total)
Travel in Y: ±(14-10)/2 = ±2mm (4mm total)
```

But wait - user specified 10×14mm housing...

**Let me re-analyze user's dimensions:**

If cam housing is **10mm (Y-width) × 14mm (Z-height)**:
- The cam must be smaller than BOTH dimensions
- Maximum cam that fits: 10mm × 10mm (circular)
- Or ellipse with major < 10mm

**For compound motion with user's 10×14 housing:**
```
Cam major axis = 9mm (leaves 0.5mm clearance to Y walls)
Cam minor axis = 6mm

At θ=0° (major horizontal):
  Y span = 9mm, clearance = (10-9)/2 = 0.5mm each side
  Z span = 6mm, clearance = (14-6)/2 = 4mm each side

At θ=90° (major vertical):
  Z span = 9mm, clearance = (14-9)/2 = 2.5mm each side
  Y span = 6mm, clearance = (10-6)/2 = 2mm each side

Z travel = 4mm - 2.5mm = 1.5mm ???

NO - this is wrong thinking...
```

---

## Part 4: Correct Mechanism Analysis

**The cam doesn't "travel" - it ROTATES in place on the camshaft.**
**The WAVE moves because the cam pushes on the housing walls.**

```
Camshaft position: FIXED (runs through center of all cam housings)
Cam rotates on camshaft
Housing (part of wave) is pushed by cam contact

When cam major axis pushes UP on housing ceiling:
  → Wave moves DOWN (housing ceiling is fixed to wave)
  → Wave pivots around hinge slot

When cam major axis pushes toward viewer (Y+):
  → Wave tilts toward viewer
```

**Key Insight:**
The camshaft must pass through the CENTER of each cam housing!

```
CROSS SECTION (looking from +X):

        ┌─────────────────┐
        │   WAVE BODY     │
        │                 │
   ─────┼─────────────────┼───── Wave bottom
        │                 │
   ┌────┴────┐       ┌────┴────┐
   │ HINGE   │       │ CAM     │
   │ ○ SLOT  │       │ HOUSING │
   │ (axle)  │       │    ●────┼──── Camshaft (through center)
   └─────────┘       │  (cam)  │
                     └─────────┘
```

---

## Part 5: Recalculate with Camshaft Through Housing Center

**Given:**
- Cam housing internal: 10mm (Y) × 14mm (Z)
- Camshaft diameter: 6mm
- Camshaft runs through CENTER of housing

**Cam sizing for contact motion:**
```
For cam to push TOP and BOTTOM of housing:
  Cam major axis = housing Z height - clearance
  Cam major axis = 14mm - 1mm = 13mm (0.5mm clearance each side)

For cam to push FRONT and BACK of housing:
  When cam is horizontal, major axis is in Y direction
  Need: 13mm major axis fits in 10mm Y width?
  13mm > 10mm → COLLISION

PROBLEM: If major=13mm for Z contact, it exceeds Y width of 10mm
```

**The housing is NOT square, so:**
- Either cam only contacts Z walls (top/bottom)
- Or cam only contacts Y walls (front/back)
- Or housing must be resized

---

## Part 6: My Recommendation

**Option 1: Square Housing (14×14mm)**
```
Housing: 14mm × 14mm × 4mm
Cam: 13mm major × 9mm minor × 4mm thick

Z motion: ±(14-9)/2 = ±2.5mm (when cam horizontal)
Y motion: ±(14-9)/2 = ±2.5mm (when cam vertical)

Total amplitude: 5mm Z, 5mm Y
```

**Option 2: Keep 10×14mm but Accept Limited Motion**
```
Housing: 10mm (Y) × 14mm (Z) × 4mm
Cam: 9mm major × 7mm minor × 4mm thick

Z motion: ±(14-9)/2 = ±2.5mm (cam contacts top/bottom)
Y motion: ±(10-7)/2 = ±1.5mm (cam contacts front/back)

Total amplitude: 5mm Z, 3mm Y
Asymmetric motion (more up/down than front/back)
```

**Option 3: Progressive Sizing (User's Original Intent)**
```
Keep housing size constant: 10×14mm for all waves

Vary CAM size per wave:
  Wave 1 (rightmost, gentle):   Cam 6×5mm → Z motion ±4mm, Y motion ±2.5mm
  Wave 11 (middle):             Cam 8×6mm → Z motion ±3mm, Y motion ±2mm
  Wave 22 (leftmost, dramatic): Cam 9×7mm → Z motion ±2.5mm, Y motion ±1.5mm

WAIT - this is backwards!
Smaller cam = MORE travel (more clearance in housing)
Larger cam = LESS travel (less clearance)
```

---

## Part 7: Correct Progressive Sizing

**For progressive amplitude (right=gentle, left=dramatic):**

The cam PUSHES the wave. More push = more motion.

**Approach A: Same housing, larger cam = more push amplitude**
```
Housing: 10×14mm (constant for all)

Wave 1 (gentle):    Cam 6×5mm → small cam, pushes gently
Wave 22 (dramatic): Cam 9×7mm → large cam, pushes strongly

BUT: Larger cam means it contacts walls MORE of the time
     Smaller cam has more "dead zone" where no contact

This creates different MOTION PROFILES, not just amplitude
```

**Approach B: Progressive housing size (matches cam)**
```
Wave 1 housing:  8×10mm,  Cam 7×5mm
Wave 22 housing: 12×16mm, Cam 11×8mm

Constant clearance ratio → similar motion profile
Different absolute amplitude
```

**Approach C: Different mechanism entirely**
```
Use follower PIN instead of housing walls
Pin rides on cam surface (outside contact)
Larger cam = larger amplitude directly

This is simpler and more common in wave machines!
```

---

## Part 8: Critical Question for User

**Which approach do you prefer?**

1. **Square housing (14×14mm)** - Equal Z and Y motion
2. **Rectangular housing (10×14mm)** - More Z than Y motion
3. **Progressive housing sizes** - Complex but precise control
4. **Follower pin on cam** - Simpler, proven design

**For progressive amplitude, I recommend:**
- Keep housing size CONSTANT (simpler manufacturing)
- Vary cam ECCENTRICITY (difference between major/minor)
- Larger eccentricity = more dramatic motion

```
Wave 1:  Cam 7mm × 6mm (eccentricity = 1mm) → gentle wobble
Wave 22: Cam 9mm × 5mm (eccentricity = 4mm) → dramatic rock
```

---

## Part 9: Hinge Slot to Cam Housing Distance

**This determines the lever arm and motion amplification.**

```
Wave length: 70mm
Hinge slot position: Near wave bottom, centered on hinge axle
Cam housing position: ??? mm from hinge slot

If hinge is at Y=0 and cam housing center at Y=D:
  Angular motion at wave tip = cam push / D × wave_length

Example:
  D = 50mm (cam housing 50mm from hinge)
  Cam push = 5mm
  Wave tip motion = (5mm / 50mm) × 70mm = 7mm at tip

  D = 30mm (cam housing closer to hinge)
  Same 5mm push → (5mm / 30mm) × 70mm = 11.7mm at tip
```

**Closer cam housing to hinge = MORE amplification at wave tip**

---

## Part 10: Layout Proposal

```
SIDE VIEW (Y-Z plane):

                                70mm
    ├───────────────────────────────────────────┤

    ┌───────────────────────────────────────────┐
    │              WAVE BODY                    │  Z = 20mm (height)
    │                                           │
    └───┬───────────────────────────────┬───────┘
        │                               │
    ┌───┴───┐                     ┌─────┴─────┐
    │       │                     │           │
    │ ○     │ Hinge slot          │   ( )     │ Cam housing
    │       │ 12×4mm              │   cam     │ 10×14mm
    └───────┘                     └───────────┘

    ├── 6 ──┤                     ├─── 7 ────┤

    Y=0     Y=6                   Y=50       Y=57      Y=70
    (hinge center)                (cam center)

    Distance hinge to cam center: 50 - 3 = 47mm
```

**Proposed dimensions:**
- Hinge slot center: Y = 6mm from wave back edge
- Cam housing center: Y = 53mm from wave back edge
- Distance between centers: 47mm
- Wave tip: Y = 70mm

---

## Summary: Recommended Parameters

```
WAVE SLAT:
  Length: 70mm (Y)
  Height: 20mm (Z) - wave body
  Thickness: 4mm (X)

HINGE SLOT (rectangular cutout):
  Position: Y = 0 to 12mm (centered at Y=6mm)
  Size: 12mm (Y) × 4mm (Z height) × 4mm (X through)
  Axle: 3mm diameter (with 0.5mm clearance)

CAM HOUSING (rectangular cutout):
  Position: Y = 48 to 58mm (centered at Y=53mm)
  Size: 10mm (Y) × 14mm (Z height) × 4mm (X through)

CAMS (progressive):
  Wave 1:  7mm × 5mm ellipse (gentle)
  Wave 11: 8mm × 5.5mm ellipse (medium)
  Wave 22: 9mm × 6mm ellipse (dramatic)
  All 4mm thick

SHAFTS:
  Hinge axle: 3mm diameter (static)
  Camshaft: 6mm diameter (rotating)
```

---

## BLOCKING QUESTION

Before I proceed to code, please confirm:

1. Housing 10×14mm is correct? (or should it be square 14×14?)
2. Cam progressive sizing approach acceptable?
3. Distance hinge-to-cam ~47mm acceptable?
4. Wave body height 20mm acceptable?
