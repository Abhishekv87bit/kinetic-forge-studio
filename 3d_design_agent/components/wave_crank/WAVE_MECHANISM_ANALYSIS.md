# WAVE MECHANISM - PROPER ANALYSIS

**Problem:** Cams are intersecting wave bodies - physically impossible
**Date:** 2026-01-20

---

## WHAT WENT WRONG

I placed cams at the SAME Z-height as the waves. The cam discs occupy the same space as the wave slats. This is geometrically impossible.

**Current (WRONG):**
```
Side view (looking along X axis):

    Wave body here         Cam here
         │                    │
         ▼                    ▼
    ┌─────────────────────────────┐
    │    WAVE AND CAM OVERLAP!    │  ← IMPOSSIBLE
    └─────────────────────────────┘
         Z = 25mm (same height)
```

---

## REFERENCE IMAGES ANALYSIS

### Image 1: Stacked MDF Discs
- Thin discs (~4mm) with center holes
- These are CAM BLANKS
- Stack on a shaft with phase offsets

### Image 2 & 3: Classic Wave Machine (Wooden)
- Discs are PERPENDICULAR to wave slats
- Each disc is BETWEEN two wave slats
- Waves REST ON TOP of disc edges
- As disc rotates, its edge profile pushes wave up/down

### Image 4: Slat Wave Machine
- Slats have SLOT at hinge end
- Common axle through all slots
- **KEY INSIGHT:** The cams push on the UNDERSIDE of the slats

### Image 5: Industrial Wave
- Discs are OFFSET from wave panels
- Each disc pushes on the EDGE of a wave panel

---

## CORRECT MECHANISM OPTIONS

### OPTION A: Vertical Offset (Cams Below Waves)

```
Top view:
                CAMSHAFT
    ────────────●────────────
                │
         ╭─────╮│╭─────╮
        (  cam ││  cam )
         ╰─────╯│╰─────╯
                │
    ════════════●════════════  HINGE AXLE
                │
           wave slats
           (ride on top of cams)
```

```
Side view (single wave):

    HINGE AXLE ●═══════════════════════╗  wave slat
               ║                       ║
               ║       wave body       ║
               ║                       ║
               ╚═══════════════════════╝
                              │
                              │ wave RESTS ON cam
                              ▼
                         ╭─────────╮
                        (   CAM     )
                         ╰────●────╯
                              │
                          CAMSHAFT

    Cams at Z = 10mm
    Waves at Z = 20mm (ABOVE cams)
    Waves contact cam at their UNDERSIDE
```

**Pros:**
- Gravity helps keep waves on cams
- No complex follower mechanism
- Matches reference images

**Cons:**
- Waves might bounce/lift off at high speed
- Need to ensure wave underside contacts cam

---

### OPTION B: Horizontal Offset (Cams Push from Side)

```
Top view (looking down Z axis):

    CAMSHAFT at Y = 70
    ═══════════════════════════════════
         ○     ○     ○     ○     ○      (cams, seen from above)

    ─────●─────●─────●─────●─────●─────  wave contact points
         │     │     │     │     │
    ═════╪═════╪═════╪═════╪═════╪═════  waves (horizontal slats)
         │     │     │     │     │
    ═══════════════════════════════════
    HINGE AXLE at Y = 0
```

```
Side view (looking along X axis):

         wave slat
    ═══════════════════════●  ← contact point on wave
                           │
              CAM ─────── ●  ← cam edge touches wave
              rotates  ╲ ╱
                        ●
                        │
                    CAMSHAFT
```

**Pros:**
- Cams and waves never share Z-space
- Clear separation of components

**Cons:**
- Horizontal force on wave (might slide)
- Need guide to keep waves aligned

---

### OPTION C: Follower Pin (Wave has pin that rides in cam groove)

```
Side view:

    HINGE ●═════════════════════════○  FOLLOWER PIN
          ║                         │
          ║      wave body          │ pin enters cam groove
          ║                         │
          ╚═════════════════════════╝
                                    │
                               ╭────┼────╮
                              (  CAM with │ groove )
                               ╰────●────╯
                                    │
                                CAMSHAFT
```

**Pros:**
- Positive engagement (pin can't lift off)
- Precise motion control
- Grooved cam = works in both directions

**Cons:**
- More complex cam manufacturing
- Pin must be strong enough

---

## DECISION: OPTION A (Cams Below Waves)

**Why:**
1. Matches reference images (especially Image 2, 3, 4)
2. Gravity assists contact
3. Simplest geometry
4. Easiest to print and assemble

---

## PROPER GEOMETRY

### Z-Layer Separation

```
Z-AXIS LAYOUT:

Z = 50mm ─── Top of wave slats (visual surface)
Z = 45mm ─── Wave body center
Z = 40mm ─── Bottom of wave slats

Z = 35mm ─── GAP (clearance)

Z = 30mm ─── Top of cams (contact surface)
Z = 25mm ─── Cam center (camshaft axis)
Z = 20mm ─── Bottom of cams

Z = 10mm ─── Hinge axle (waves pivot here)

Z = 0mm  ─── Base plate
```

### Contact Point Calculation

Wave pivots at hinge (Y=0, Z=10).
Wave length = 75mm.
Cam contact at Y=70mm from hinge.

At cam position:
- Cam center at Z=25mm
- Cam major radius = 8mm to 12mm (varies)
- Cam top surface = 25 + 12 = 37mm (max)
- Cam bottom surface = 25 - 12 = 13mm (min)

Wave bottom at contact point:
- Must be AT or BELOW cam top surface when cam is at max
- Wave bottom at contact = 37mm (rides on cam)
- Wave thickness = 4mm
- Wave top at contact = 41mm

This means waves are at Z ≈ 39mm (center) at the cam end.

---

## PARTS BREAKDOWN

### Part 1: Base Frame
- Foundation plate
- Side walls with bearing holes
- Supports both shafts

### Part 2: Hinge Axle (Static)
- 5mm steel rod
- Waves pivot on this
- Fixed to frame

### Part 3: Camshaft (Rotating)
- 6mm steel rod
- Holds all cams
- Driven by hand crank

### Part 4: Elliptical Cams (22 pieces)
- 4mm thick each
- Progressive sizes (8mm to 24mm major axis)
- Mounted on camshaft with phase offsets
- **LOCATED BELOW wave contact points**

### Part 5: Wave Slats (22 pieces)
- 4mm thick each
- Rectangular slot at hinge end (rides on axle)
- **Bottom surface contacts cam top**
- Gravity keeps wave on cam

### Part 6: Hand Crank
- Attached to camshaft
- Outside frame for access

---

## NEXT STEPS

1. Create individual part files
2. Verify Z-layer separation
3. Calculate exact contact geometry
4. Test single wave + single cam first
5. Then scale to full 22-wave system

---

## LESSON LEARNED

**Never place moving parts at the same Z-coordinate unless they're supposed to occupy the same space.**

The cam must be OFFSET from the wave - either:
- Vertically (below/above)
- Horizontally (to the side)
- Or use a follower pin

This is basic mechanism design that I should have caught immediately.
