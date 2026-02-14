# Lever Amplifier Variations for Fish Arc Motion

**Goal:** Convert wave vertical motion (up/down) to fish arc motion (right/left)
**Wave input:** 5-12mm vertical travel depending on zone

---

## Variation 1: SIMPLE CLASS 1 LEVER (Seesaw)

```
TOP VIEW (viewer looking down at wave):
════════════════════════════════════════

         fish ●━━━━━━━━━━━○━━━━● wave contact
              arc swing   pivot   wave pushes up

SIDE VIEW:
════════════════════════════════════════

    fish ●          pivot ○          ● roller on wave
          \          /              /
           \        /              / wave surface
            \______/          ~~~~●~~~~
                                  ↑↓ vertical motion
```

**Ratio:** 3:1 typical (30mm fish arm : 10mm wave arm)
**Motion:** Fish swings UP when wave goes UP (same direction)
**Arc direction:** Vertical plane (up/down arc, not left/right)

**Problem:** This gives vertical arc, NOT horizontal arc.

---

## Variation 2: TWISTED LEVER (90° Arc Conversion)

```
TOP VIEW:
════════════════════════════════════════

    pivot ○━━━━━━━━━━━━● fish
          │              swings LEFT/RIGHT
          │ twist joint  ↔
          │
          ●━━━━ wave contact
          wave pushes UP/DOWN ↕

The lever has a 90° twist so vertical input → horizontal output
```

**Mechanism:**
- Wave contact arm is VERTICAL
- Fish arm is HORIZONTAL
- Connected at pivot with 90° offset

**Ratio:** Can be any (set by arm lengths)
**Motion:** Wave goes UP → Fish swings LEFT (or right, depending on twist direction)

**Geometry:**
```
3D VIEW:
                      ↑ Z (vertical)
                      │
                      │    fish
                      │     ●━━━━▶ Y (toward viewer)
                      │    /
            pivot ━━━○━━━/━━━━ twist point
                      │\
                      │ \
                      │  ● wave contact (below pivot)
                      │  │
                      │  │ wave surface
              ~~~~~~~~│~~●~~~~~~~~
                      │  ↑↓
                      X (along wave array)
```

**Part count:** 1 (single twisted lever arm)
**Printability:** Excellent (print as one piece)

---

## Variation 3: BELL CRANK (L-shaped Lever)

```
TOP VIEW:
════════════════════════════════════════

                  fish ●
                      │
                      │ horizontal arm
                      │
            pivot ────○────
                      │
                      │ vertical arm
                      │
                      ● wave contact
                      │
              ~~~~~~~~↑↓~~~~~~~~ wave

SIDE VIEW:
════════════════════════════════════════

         fish ●━━━━━━━○ pivot
                      │
                      │
                      ● wave contact
                      │
              ~~~~~~~~│~~~~~~~ wave surface
                      ↑↓
```

**Motion:** Wave UP → fish swings HORIZONTALLY (perpendicular to wave motion)
**Ratio:** Determined by arm length ratio
**Arc direction:** Horizontal plane - exactly what we want!

**Key advantage:** Pure 90° motion conversion, no twist required.

**Geometry:**
```
Arm 1 (vertical): 20mm  - wave contact to pivot
Arm 2 (horizontal): 40mm - pivot to fish

Wave travel: 12mm (Zone C)
Fish arc: 12mm × (40/20) = 24mm horizontal swing
Arc angle: atan(24/40) = ~31° total swing
```

---

## Variation 4: DOUBLE BELL CRANK (Parallel Motion)

```
TOP VIEW:
════════════════════════════════════════

    fish ●━━━━━━━○━━━━━━━●
              pivot 1  connecting rod
                         │
                         │
    wave ●━━━━━━━○━━━━━━━●
    contact   pivot 2

Two bell cranks connected by a rod
Creates parallel motion (fish stays level while swinging)
```

**Motion:** Fish swings horizontally while staying upright
**Advantage:** Fish always faces viewer (doesn't tilt)
**Disadvantage:** More parts (2 cranks + rod)

---

## Variation 5: ROCKER WITH SLIDER (Scotch Yoke Style)

```
SIDE VIEW:
════════════════════════════════════════

              fish ●━━━━━━● rides in slot
                          │
                          │ vertical slot
                   ━━━━━━━╋━━━━━━━ horizontal guide
                          │
                          ● slider block
                          │
                          │ driven by wave via lever

    wave ~~~~~~~~●~~~~~~~~
                 ↑↓
```

**Motion:** Pure sinusoidal horizontal motion
**Fish path:** Perfectly straight line (left-right)
**No arc - just linear oscillation**

---

## Variation 6: COMPOUND LEVER (Two-Stage Amplification)

```
                    fish ●
                         \
                          \ arm 2 (pivot at ○)
                           \
    fixed pivot ━━━━━━━━━━━━○━━━━━━━●━━ intermediate point
                                     \
                                      \ arm 1
                                       \
                                        ● wave contact
```

**Motion:** Two-stage amplification
**Ratio:** Product of both stages (e.g., 2:1 × 3:1 = 6:1)
**Fish travel:** Wave 12mm → Intermediate 24mm → Fish 72mm!

**Risk:** Large amplification = large forces, potential wobble

---

## Variation 7: OFFSET PIVOT LEVER (Asymmetric Arc)

```
                         ● fish
                        /
                       / long arm (60mm)
                      /
    wave ●━━━━━━━━━━━○ pivot (offset toward wave)
         short arm    │
         (10mm)       │
                      frame
```

**Motion:** Highly amplified (6:1 ratio)
**Arc:** Asymmetric - fish travels MORE on one side of swing
**Character:** "Leaping" motion with quick jump, slow return

**Tuning:** Offset position determines asymmetry

---

## COMPARISON TABLE

| Variation | Arc Direction | Parts | Ratio | Character | Printability |
|-----------|---------------|-------|-------|-----------|--------------|
| 1. Simple Seesaw | Vertical | 1 | 3:1 | Up/down | Easy |
| **2. Twisted Lever** | **Horizontal** | **1** | **Any** | **Smooth arc** | **Easy** |
| **3. Bell Crank** | **Horizontal** | **1** | **Any** | **Clean 90° conversion** | **Easy** |
| 4. Double Bell | Horizontal | 3 | Any | Fish stays level | Medium |
| 5. Scotch Yoke | Horizontal (linear) | 3 | 1:1 | Pure sine | Medium |
| 6. Compound | Depends | 2 | High (6:1+) | Dramatic | Medium |
| 7. Offset Pivot | Asymmetric arc | 1 | High | Leap/slow return | Easy |

---

## RECOMMENDATION FOR FISH ARC

**Best Option: Variation 3 - BELL CRANK**

**Why:**
1. **Clean 90° conversion** - wave vertical → fish horizontal
2. **Single part** - one L-shaped lever
3. **Tunable ratio** - adjust arm lengths for desired arc
4. **Fish faces viewer** - horizontal swing keeps fish visible
5. **Easy to print** - flat L-shape, no twist geometry

**Proposed Geometry:**
```
                    ● fish body (detachable)
                    │
         40mm arm ━━┿━━ fish mount point
                    │
         pivot ━━━━━○━━━ frame mount
                    │
                    │ 20mm arm
                    │
                    ● roller follower
                    │
            ~~~~~~~~│~~~~~~~~ wave surface
                    ↑↓ 12mm travel (Zone C)

Fish arc = 12mm × (40/20) = 24mm total swing
Arc angle at fish = atan(12/20) = 31°
```

**Enhanced: OFFSET BELL CRANK for "jump" character**
```
If we offset the pivot toward the wave:

    Arm ratio 50mm:15mm = 3.3:1
    Wave 12mm → Fish arc 40mm
    Plus asymmetric timing (quick up, slow down)

    Creates "jumping" visual rather than "swinging"
```

---

## NEXT STEP

Which lever variation interests you most?

1. **Bell Crank (3)** - Clean horizontal arc, fish swings left-right
2. **Twisted Lever (2)** - Single piece, twist converts motion
3. **Offset Pivot (7)** - Asymmetric "leap and land" motion
4. **Compound (6)** - Maximum amplification, dramatic travel

Or should I sketch a specific configuration in more detail?
