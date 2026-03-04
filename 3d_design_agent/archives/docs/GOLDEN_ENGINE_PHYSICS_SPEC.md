# The Golden Engine — Physics Spec Sheet
## Generated via Rule 99 Discover

Built from 6 rounds of Socratic Q&A. Every engineering value traces back to a user answer.

---

## COMPLETE SPECIFICATION

| Parameter | Your Words | Engineering Value | How We Got There |
|-----------|-----------|-------------------|-----------------|
| **Orientation** | "tabletop, face-on" | Horizontal disk, viewer looks down | Direct |
| **Layout** | "dense sunflower" | 89 pixels, phyllotactic, 137.5° golden angle | Fibonacci number, golden angle |
| **Diameter** | "tabletop" | ~35-40cm total (350-400mm) | Derived from 89 pixels at ~30mm spacing |
| **Pixel shape** | "flat petals" | Thin brass disc/blade, 16×20mm face, 1.2mm thick, on 6mm stalk | Aesthetic choice — rotation makes light dance across field |
| **Pixel travel** | "dramatic" | 30mm vertical rise + coupled rotation | 8mm pitch screw = ~1.3 turns over 30mm |
| **Pixel motion** | "rises AND rotates" | 2-DOF coupled via lead screw | Screw inherently couples translation + rotation |
| **Pixel mass** | (derived) | ~7.5g per pin | Brass density 8.5 g/cm3 × volume |
| **Total pixel mass** | (derived) | 667g (89 × 7.5g) | Sum |
| **Aesthetic** | "visible mechanism" | All gears, shafts, screws exposed | Engineering IS the art |
| **Drive type** | "Central Antikythera hub" | Epicyclic gear train, bronze, 3 output stages | User selected from 3 options |
| **Wave pattern** | "multiple vortices" | 3 spiral waves at different speeds | Coprime Fibonacci ratios |
| **Vortex speed** | "meditative" | Slowest vortex: 10s period | User aesthetic preference |
| **Vortex ratios** | (derived) | 10s / 12.5s / 16.25s (1 : 5/4 : 13/8) | Fibonacci ratios for quasi-periodic pattern |
| **Gasp moment** | "dramatic, ~20min" | All-flat alignment every ~1200s, lasts ~2s | LCM of vortex periods, tuned by gear tooth count |
| **Peak simultaneous load** | (derived) | ~35 pins rising = 263g = 2.6 N | 40% duty cycle (3 overlapping vortices) |
| **Required torque** | (derived) | ~0.005 N·m total at screws | Trivially low — apple weight through fine screw |
| **Motor** | (derived) | NEMA 14 or small gearmotor sufficient | NEMA 17 overkill for this load |
| **Build method** | "hybrid" | 3D print frame + gears, brass rod pins | Prototype with real material where it matters |
| **Base** | "glass/acrylic" | Transparent base — gears visible from below AND above | Aesthetic choice |
| **Frame** | (derived) | Elevated on glass/acrylic, Antikythera hub visible underneath | Mechanism legible from all angles |

---

## PHYSICS CONCEPTS LEARNED THIS SESSION

| # | Concept | What You Now Know |
|---|---------|------------------|
| 1 | **Phyllotaxis** | Golden angle (137.5°) means no two pixels align. Creates Fibonacci spiral arms (5, 8, 13). Wave patterns travel along these arms as vortices. |
| 2 | **Degrees of Freedom** | Each pixel needs 2 motions (rise + rotate). A screw gives BOTH from ONE input — rotation IS translation on a helix. Free 2-DOF from 1-DOF input. |
| 3 | **Coprime ratios** | When gear ratios share no common factors (like 8:13), their combined pattern never exactly repeats. This is why the vortices stay "fresh" forever. |
| 4 | **Torque vs pitch** | Fine pitch screw = low torque but many turns. Coarse pitch = more torque but fewer turns. For 30mm travel: 8mm pitch = 3.75 turns, good balance. |
| 5 | **LCM and the gasp** | The "gasp" (all-flat moment) happens at the Least Common Multiple of all vortex periods. Gear tooth counts tune this interval precisely. Swappable "mood gears" could change it. |
| 6 | **Load budget** | 89 brass pins = 667g total, but only ~35 rise at once = 2.6N peak. Like lifting an apple. This is LOW power — one tiny motor handles the whole sculpture. |

---

## MECHANISM ARCHITECTURE

```
                    MOTOR (NEMA 14, underneath)
                       |
                    WORM GEAR (speed reduction, self-locking)
                       |
              ANTIKYTHERA HUB (visible through glass base)
              /        |        \
         Stage A    Stage B    Stage C
         (1:1)     (5:4)      (13:8)
            |         |          |
         Output    Output     Output
         Shaft A   Shaft B    Shaft C
            |         |          |
      ┌─────┴──┐  ┌──┴───┐  ┌──┴───┐
      Radial    Radial    Radial
      spokes    spokes    spokes
      to ~30    to ~30    to ~29
      pixels    pixels    pixels
         |         |          |
      Bevel/worm  Bevel/worm  Bevel/worm
      at each     at each     at each
      pixel       pixel       pixel
         |         |          |
      Lead screw  Lead screw  Lead screw
      (8mm pitch) (8mm pitch) (8mm pitch)
         |         |          |
      BRASS PIN   BRASS PIN   BRASS PIN
      rises +     rises +     rises +
      rotates     rotates     rotates
```

### Pixel Assignment to Vortex Groups

89 pixels divided among 3 vortex groups by their position in the spiral:
- **Group A** (~30 pixels): Every 3rd pixel starting from #0 → driven by shaft A at 10s period
- **Group B** (~30 pixels): Every 3rd pixel starting from #1 → driven by shaft B at 12.5s period
- **Group C** (~29 pixels): Every 3rd pixel starting from #2 → driven by shaft C at 16.25s period

Because pixels are phyllotactically arranged, each group's members are SCATTERED across the disk — NOT clustered. This means all three vortex patterns are spatially interleaved, creating rich interference everywhere.

---

## OPEN QUESTIONS (for Rule 99 design phase)

1. **Spoke routing:** How do 3 output shafts reach ~30 scattered pixels each? Options: flexible shafts, belt loops, or reorganize groups so each spoke serves a radial sector.
2. **Pin guide:** Each pin needs a bushing/guide to keep it vertical as it rises. 89 precision bores in the top plate. Tolerance: H7/g6 sliding fit on 6mm shaft.
3. **Anti-rotation option:** The screw couples rise+rotation. If we want pins to rise WITHOUT rotating (for light-catching effect where orientation matters), we'd need a keyway or spline. Or embrace the rotation — it makes the light dance.
4. **Glass base thickness:** Must support total sculpture weight (~2-3 kg) without flexing. 6-8mm tempered glass, or 10mm acrylic.
5. **Sound:** Brass pins rising/falling in guide bores will make a soft clicking/ticking. Feature or bug? Probably feature — the clock-like sound reinforces the mechanical aesthetic.
6. **Mood gears:** Swappable gear sets that change the gasp interval. Cool concept but adds complexity. Prototype without, add later if desired.

---

## PROTOTYPE PLAN (Hybrid Build)

### Phase 1: Proof of Concept (3D print, 1 week)
- Print 13-pixel simplified spiral (Fibonacci number, small enough to test)
- Print Antikythera hub with 2 output stages (not 3 yet)
- Use M6 threaded rod as lead screws, brass standoffs as pixel pins
- Acrylic sheet as base (laser cut or buy pre-cut circle)
- Verify: vortex motion reads correctly, pins rise/rotate, gears mesh

### Phase 2: Full 89-pixel Prototype (hybrid, 2-3 weeks)
- Print full frame with 89 guide bores
- Print Antikythera hub with all 3 stages
- Brass rod stock for pins (cut to length, polish ends)
- Glass or acrylic base
- Tune gear tooth counts for ~20-minute gasp interval
- Test long-duration running: friction, wear, noise

### Phase 3: Production (if prototype works)
- CNC brass Antikythera hub
- Waterjet or CNC the frame from aluminum or brass
- Turned brass pins
- Tempered glass base on machined aluminum legs
- Proper bearings at all shaft supports

---

## THE VASHISHT RULE APPLIED

| Century | What We Took |
|---------|-------------|
| **150 BC** (Antikythera) | Epicyclic gear train computing celestial ratios |
| **12th C India** (Fibonacci/Hemachandra) | Golden angle pixel layout, quasi-periodic timing |
| **17th C Japan** (Karakuri) | The "gasp" — surprise reveal from hidden mathematical alignment |
| **21st C** (Strain wave / precision printing) | Miniature gear reduction at desktop scale |
| **Nature** (Sunflower) | Phyllotactic arrangement, spiral arm families |

Five centuries. Three cultures. One sunflower. Yours.
