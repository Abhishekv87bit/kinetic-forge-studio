# Design Thinking Framework for Kinetic Sculpture
## Motion Before Mechanism — The Professional Approach

---

## The Core Reframe: You're Not Learning Mechanisms — You're Learning to SEE Motion

### What You Already Have (Lego Technic Veteran)
- ✅ Mechanical intuition — you KNOW how gears, linkages, cams work
- ✅ Spatial reasoning — you can visualize motion in your head
- ✅ Assembly skills — you've built complex things before
- ✅ Debugging instinct — when something binds, you feel it

### What You Actually Need to Learn
- ❌ NOT: "How does a four-bar work?" (you already know)
- ✅ YES: "Which four-bar creates THIS specific motion?"
- ❌ NOT: Building mechanisms from scratch
- ✅ YES: Finding existing designs, adapting them, combining them
- ❌ NOT: Calculating everything yourself
- ✅ YES: Recognizing when a design "feels wrong" before building

### The Community-Leveraged Approach

```
┌─────────────────────────────────────────────────────────────┐
│ YOUR NEW WORKFLOW                                           │
├─────────────────────────────────────────────────────────────┤
│ 1. VISION: "I want THIS motion" (a feeling, an emotion)     │
│       ↓                                                     │
│ 2. HUNT: Search community resources for similar mechanisms  │
│    - GitHub projects                                        │
│    - 507 Mechanical Movements                               │
│    - Kinetic Sculpture Club examples                        │
│    - PS70 student projects with downloadable files          │
│       ↓                                                     │
│ 3. ADAPT: Download, modify parameters, make it yours        │
│    - Change scale                                           │
│    - Adjust timing/speed                                    │
│    - Combine with other mechanisms                          │
│       ↓                                                     │
│ 4. VALIDATE: Quick prototype (cardboard or fast print)      │
│       ↓                                                     │
│ 5. REFINE: Does it evoke the emotion? Iterate.              │
│       ↓                                                     │
│ 6. INTEGRATE: Combine into your sculpture                   │
└─────────────────────────────────────────────────────────────┘
```

### The Expert Skill: Motion → Emotion Recognition

This is what separates hobbyists from masters:

| Motion Characteristic | Emotion It Creates | Where to Find Examples |
|----------------------|-------------------|----------------------|
| Slow rise, quick drop | Breathing, organic life | Cam profiles in automata book |
| Jerky, stepped motion | Mechanical, industrial | Geneva drives, ratchets |
| Smooth continuous wave | Water, wind, peaceful | Phase-offset eccentrics |
| Sudden pause, then move | Surprise, anticipation | Dwell cams, escapements |
| Multiple elements, slightly out of sync | Natural chaos, forest | Golden angle phase (137.5°) |
| Perfect synchronization | Military, artificial | Gear-linked mechanisms |

**Your learning goal:** See a motion in nature or art → immediately know which mechanism family creates it → find an existing design → adapt it.

---

## The Golden Rule: Cardboard First, Always

Your automata cardboard sessions aren't just playtime — they're your primary design laboratory. Every mechanism gets tested in cardboard before CAD, before printing.

```
┌─────────────────────────────────────────────────────────────┐
│ THE CARDBOARD → FUSION → PRINT PIPELINE                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   1. CARDBOARD (30 min - 2 hrs)                            │
│      • Brass fasteners for joints                          │
│      • Feel the motion with your hands                     │
│      • Discover: Does it bind? Where's the dead spot?      │
│      • Iterate by cutting new pieces                       │
│      • SUCCESS = motion feels right                        │
│           ↓                                                 │
│   2. FUSION 360 (1-2 hrs)                                  │
│      • Translate cardboard dimensions to CAD               │
│      • Add tolerances for 3D printing                      │
│      • Motion study to verify full rotation                │
│      • Parametric so you can tweak later                   │
│      • SUCCESS = simulation matches cardboard              │
│           ↓                                                 │
│   3. PRINT + TEST (2-4 hrs)                                │
│      • Print mechanism only (not decoration)               │
│      • Compare to cardboard behavior                       │
│      • Identify delta: What's different? Why?              │
│      • SUCCESS = motion matches vision                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Why cardboard first?**
- **Speed:** 30 minutes to working prototype vs. 4+ hours to print
- **Feel:** You literally FEEL when something binds or jerks
- **Iteration:** Cut a new link in 2 minutes, not 45 minutes of printing
- **Recognition building:** Your hands learn what your eyes can't see

## The 5 Questions Before ANY Design

Before touching cardboard or Fusion, answer these:

| # | Question | Why It Matters |
|---|----------|----------------|
| 1 | **What EMOTION should this motion create?** | Breathing? Surprise? Mechanical? Organic? This determines everything. |
| 2 | **What's the INPUT motion?** | Continuous rotation? Oscillation? Hand crank? Motor? |
| 3 | **What's the OUTPUT motion?** | Up-down? Side-to-side? Complex path? Multiple elements? |
| 4 | **What's the TIMING?** | Smooth continuous? Pause-move-pause? Fast one way, slow the other? |
| 5 | **How many ELEMENTS move?** | Single? Multiple in sync? Multiple out of phase? |

**Example:**
> "I want a bird that breathes"
> 1. **Emotion:** Peaceful, organic, alive
> 2. **Input:** Continuous motor rotation
> 3. **Output:** Chest rises and falls
> 4. **Timing:** Slow rise (inhale), pause, quick drop (exhale) — asymmetric
> 5. **Elements:** Just the chest (simple), or chest + head nod (complex)
>
> **Mechanism answer:** Pear-shaped cam with dwell. The steep drop = quick exhale. The gradual rise = slow inhale. The flat = pause at top.

## Motion Vocabulary: The Feeling → Mechanism Dictionary

Train yourself to instantly translate feelings into mechanism families:

### Organic / Living Motions
| You Want... | Use This | Why |
|-------------|----------|-----|
| Breathing | Asymmetric cam | Slow in, fast out mimics breath |
| Heartbeat | Snail cam (double-lobe) | Quick pulse, long pause |
| Walking | Four-bar linkage (Jansen/Klann) | Foot lifts, swings, plants |
| Swimming | Cam + lever combination | Wave propagates through body |
| Growing/blooming | Spiral cam or lead screw | Gradual continuous extension |

### Mechanical / Industrial Motions
| You Want... | Use This | Why |
|-------------|----------|-----|
| Stepping/indexing | Geneva drive | Crisp stops, locked positions |
| Pumping | Slider-crank | Piston-like, industrial feel |
| Ticking | Escapement or ratchet | Discrete steps, audible click |
| Spinning with stops | Geneva or intermittent gear | Rotation → pause → rotation |

### Emotional / Abstract Motions
| You Want... | Use This | Why |
|-------------|----------|-----|
| Surprise | Dwell cam with sudden drop | Tension builds, then release |
| Chaos (controlled) | Golden angle phase (137.5°) | Never repeats, feels natural |
| Synchronization | Gear-linked mechanisms | Perfect unison = artificial/military |
| Wave/cascade | Phase-offset eccentrics | Each element slightly behind the last |
| Hesitation | Quick-return or dwell | Fast action, thoughtful pause |

## The "Ugly Cardboard" Rule

**Your first cardboard prototype should be UGLY.**

Why? Because:
- Beautiful prototypes make you reluctant to modify them
- Ugly = permission to cut, tear, rebuild
- Speed matters more than aesthetics at this stage
- You're testing MOTION, not appearance

**The 3-Prototype Minimum:**
1. **Prototype 1:** Wildly wrong. Learn what doesn't work.
2. **Prototype 2:** Getting closer. Refine the ratios.
3. **Prototype 3:** Motion feels right. NOW go to Fusion.


---

## Design Scenarios: How To Approach Real Challenges

Here's how to apply the framework to common kinetic sculpture design situations:

### Scenario 1: "I want something that breathes"

**5 Questions:**
1. Emotion: Peaceful, alive, organic
2. Input: Continuous motor rotation
3. Output: Chest/body rises and falls
4. Timing: Slow rise, pause, quick drop (3:1 ratio feels natural)
5. Elements: Single element (chest) or multiple (chest + head nod)

**Mechanism Selection:** Asymmetric cam (pear-shaped)
- Gradual slope = slow rise (inhale)
- Flat section = pause at top
- Steep drop = quick exhale

**Cardboard Test:** Cut pear-shaped cam from cardboard. Pin follower on top. Turn handle. Does it FEEL like breathing?

---

### Scenario 2: "I want multiple elements moving like a wave"

**5 Questions:**
1. Emotion: Flowing, water-like, peaceful
2. Input: Continuous motor rotation
3. Output: Multiple vertical elements rise/fall in sequence
4. Timing: Continuous, smooth, cascading
5. Elements: 5-12 bars, each slightly behind the last

**Mechanism Selection:** Phase-offset eccentrics
- All eccentrics on same shaft
- Each offset by consistent angle (360°/N for N elements)
- Golden angle (137.5°) for natural, non-repeating feel

**Cardboard Test:** Cut 5 circular cams. Mount on single dowel with angular offset. Attach followers. Turn handle. Does wave propagate smoothly?

---

### Scenario 3: "I want something that pauses dramatically, then moves"

**5 Questions:**
1. Emotion: Tension, surprise, anticipation
2. Input: Continuous motor rotation
3. Output: Element stays still, then suddenly moves
4. Timing: Long pause (70-80%), quick action (20-30%)
5. Elements: Single dramatic element

**Mechanism Selection:** Dwell cam OR Geneva drive
- Dwell cam: Flat section = pause, steep section = action
- Geneva: Locked position for dwell, slotted section for motion

**Cardboard Test:** For Geneva - cut wheel with slot, cut driver with pin. Test dwell ratio. Does the pause build tension?

---

### Scenario 4: "I want a walking creature"

**5 Questions:**
1. Emotion: Alive, mechanical-organic hybrid
2. Input: Continuous motor rotation
3. Output: Legs lift, swing forward, plant
4. Timing: Each leg 180° out of phase (for bipedal), 90° for quadruped
5. Elements: 2, 4, or 6 legs

**Mechanism Selection:** Jansen or Klann linkage (specialized four-bars)
- Published ratios exist — start there
- Coupler point traces foot path

**Cardboard Test:** Build ONE leg first. Does foot lift cleanly? Does it drag? Adjust link lengths until foot path looks right. THEN duplicate for more legs.

---

### Scenario 5: "I want to combine two motions"

**5 Questions:**
1. Emotion: Complex, narrative, layered
2. Input: Single motor (always start here)
3. Output: Element A does X, Element B does Y
4. Timing: In sync? Out of phase? One triggers the other?
5. Elements: 2+ distinct moving parts

**Mechanism Selection:** Gear train or cam stack
- Same-shaft mechanisms = locked timing relationship
- Gear ratios = different speeds from same input
- Multiple cams on one shaft = independent profiles

**Cardboard Test:** Build each mechanism SEPARATELY first. Verify each works. THEN connect to common input. Does integration create interference?

---

## The Design Session Template

For each new mechanism or motion you want to create:

```
┌─────────────────────────────────────────────────────────────┐
│ DESIGN SESSION (2-3 hrs)                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ PHASE 1: VISION (15 min)                                   │
│ • Answer the 5 Questions                                   │
│ • Sketch the motion with arrows (not the mechanism!)       │
│ • Identify: What mechanism FAMILY fits this?               │
│                                                             │
│ PHASE 2: HUNT (15 min)                                     │
│ • Search community for similar motion                      │
│ • Sources: 507 Movements, Kinetic Club, PS70, GitHub       │
│ • Download 1-2 reference designs                           │
│                                                             │
│ PHASE 3: CARDBOARD (30-60 min)                             │
│ • Build ugly prototype                                     │
│ • Test motion with your hands                              │
│ • Iterate until motion FEELS right                         │
│                                                             │
│ PHASE 4: FUSION (30-60 min)                                │
│ • Import/adapt or model from scratch                       │
│ • Use parameters for all dimensions                        │
│ • Motion study to verify                                   │
│                                                             │
│ PHASE 5: DOCUMENT (15 min)                                 │
│ • Photo cardboard + screenshot Fusion                      │
│ • Note: What worked? What surprised you?                   │
│ • Pattern learned: "[Condition] → [Result]"                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## When to Ask AI for Calculations (Mathematical Leverage)

**Your role:** RECOGNIZE the problem. **AI's role:** Calculate. **Your role again:** VERIFY the result.

```
YOU RECOGNIZE          →  YOU ASK AI           →  YOU VERIFY
"This might lock up"   →  "Check Grashof"      →  Build and test
"Motion feels jerky"   →  "Check trans. angle"  →  Watch it move
"Too much slop"        →  "Tolerance stack?"    →  Measure actual play
"Not enough power"     →  "Power budget?"       →  Motor stalls or not
```

### The 7 Mathematical Leverage Points

These are the ONLY math concepts you need to RECOGNIZE. AI calculates. You invoke.

| # | Recognition Trigger | What To Ask AI | What It Prevents |
|---|---------------------|----------------|------------------|
| 1 | **"Will this linkage lock?"** | "Check Grashof condition for links [a,b,c,d]" | Dead mechanisms, wasted prints |
| 2 | **"Motion looks jerky at this angle"** | "What's transmission angle at [X] degrees?" | Jerky motion, high forces |
| 3 | **"Parts don't stay the same distance"** | "Verify coupler length at 0°, 90°, 180°, 270°" | Impossible mechanisms |
| 4 | **"Motor seems to struggle"** | "Power budget: [mass] at [speed] with [friction estimate]" | Stalled motors, burned components |
| 5 | **"Mechanism feels sloppy"** | "Tolerance stack for [N] joints at [clearance] each" | Accumulated slop |
| 6 | **"Need specific timing ratio"** | "Gear ratio for [input RPM] to [output RPM]" | Wrong speeds |
| 7 | **"Elements should move out of phase"** | "Phase offset in degrees for [N] elements" | Boring synchronized motion |

### Building Recognition: The Pattern Library

After each build, document the failure pattern:

```
## Pattern: [Name]
**Recognition:** [How do you spot this problem?]
**Cause:** [Why does it happen?]
**Fix:** [What to do about it]
**Prevention:** [What to check BEFORE building]
```

By Month 3, you'll have ~20 patterns. That's your mechanical intuition — externalized.

---

## Failure Pattern Library (Starter Entries)

📋 **REFERENCE SHEET** — Build this over time. Each failure = one new entry. These are your seeds.

### Pattern 001: Four-Bar Lock-Up
**Recognition:** Mechanism stops dead at a specific angle, won't continue
**Cause:** Grashof condition violated — shortest + longest > sum of other two links
**Fix:** Shorten the crank or lengthen the ground link
**Prevention:** Always ask Claude "Check Grashof for [a,b,c,d]" BEFORE building

### Pattern 002: Jerky Motion Zone
**Recognition:** Smooth everywhere except one angular zone where it stutters
**Cause:** Transmission angle drops below 40 degrees or exceeds 140 degrees
**Fix:** Adjust coupler length until motion smooths across full rotation
**Prevention:** Ask Claude "Transmission angle range for these links?"

### Pattern 003: Outdoor Bearing Seizure
**Recognition:** Pivot stops turning after weeks/months outdoors
**Cause:** Condensation forms inside shielded (not sealed) bearings, causing rust
**Fix:** Replace with double-sealed bearings or bronze bushings
**Prevention:** ALWAYS specify sealed bearings for anything exposed to weather

### Pattern 004: PLA Bearing Failure
**Recognition:** Printed pivot gets hot, deforms, seizes
**Cause:** PLA has too much friction for bearing surfaces; generates heat under continuous motion
**Fix:** Replace printed bearing with real ball bearing (608 skateboard bearings are cheap and universal)
**Prevention:** NEVER use 3D-printed surfaces as bearing contact points

### Pattern 005: Tolerance Stack Slop
**Recognition:** First joint tight, last joint floppy — mechanism wobbles at the end of the chain
**Cause:** Each joint adds clearance; 10 joints at 0.3mm each = 3mm total play
**Fix:** Use tighter clearances on early joints or add preload springs
**Prevention:** Ask Claude "Tolerance stack for N joints at X clearance"

### Pattern 006: Motor Stall Under Load
**Recognition:** Motor hums but doesn't turn, gets hot
**Cause:** Required torque exceeds motor rated torque — usually from friction or gravity
**Fix:** Add gear reduction (higher ratio = more torque), reduce friction, lighten mechanism
**Prevention:** Ask Claude "Power budget for [mass] at [speed] with [friction]"

*[Add your own patterns here as you encounter them...]*

---

## Wisdom from the Masters

📋 **REFERENCE SHEET** — Revisit when stuck or need inspiration. These are quotes and tips from professional kinetic sculptors.

### Tim Hunkin (Cambridge engineer, *Secret Life of Machines/Components*)
- "Don't live on the computer. CAD makes any design look convincing but hides physical reality."
- "I made things badly for the first half of my life." — Permission to start rough.
- Buy a children's kit to learn practical skills — more useful than theory textbooks.
- Tidy your workshop at the end of each day to reflect on what you built.
- His approach: measurements over calculations, reliability over elegance.

### David C. Roy (Physics BS, 40+ years of wooden kinetic sculpture)
- "Getting things simple is much harder than making them complex. You can do a lot of levers and things, but it's inefficient."
- Reduce the mechanism, feature the motion — hide the engineering, show the art.
- Recommended books: *507 Mechanical Movements* + *Making Things Move*.
- "Constraints, when met with patience, can birth unexpected beauty."
- Even a quarter inch off level affects running time for spring-driven pieces.

### Arthur Ganson (BFA, MIT Museum artist-in-residence)
- Start with a feeling or emotion, not a mechanism. The emotion is the goal.
- Never took an engineering course — 30 years of intuitive mistakes as education.
- "When I started, I was making things far more complex than necessary. Now I'm getting more simple."
- "Every part is there for a reason." Simplicity comes with experience.
- Finding the right TOOL can open entirely new creative possibilities (his spot welder changed everything).

### Theo Jansen (Physics background, Strandbeest creator)
- When the solution space is too large, EVOLVE the answer — genetic algorithms, not manual search.
- Accept extinction of failed designs. Keep a boneyard.
- Start crude, iterate over YEARS. His first prototypes could only move their legs while lying on their backs.
- Define clear fitness criteria before optimizing (flatness, ground-time ratio, path shape).

### Dug North (Automata maker, CMT contributor)
- Use dowel-reinforced butt joints for automata boxes — fast, strong enough, easy to disassemble during refinement.
- Cams are "memory" — they allow a mechanism to perform specific movements.
- Shop around for materials — specialty retailers overcharge for common items sold cheaper elsewhere.
- Use grinding stones (not carving bits) for final shaping — smoother finish on Basswood.

### Rob Ives (Paper automata designer, former teacher)
- Accuracy matters for MECHANISMS, not for characters. Mechanism geometry must be precise; decoration can be loose.
- Use reference points as far apart as possible for alignment. Close reference points amplify error.
- Paper teaches real engineering — cams, linkages, gears, ratchets, all work in paper.
- Design your own projects as soon as possible, don't just follow templates.

### CMT Workshop Insight
- "The biggest thing I took is that it's OK to mess up and have a lot of problems starting."
- Start with kits BEFORE courses. Build basic mechanism examples to familiarize yourself.
- Practice between sessions — play and experiment with what you learn each week.

---

## Design Scenario 6: When the Design Space is Too Large (Evolutionary Method)

🧠 **LEARN THIS** (judging fitness criteria) + 🤖 **ASK CLAUDE** (generating variations)

**Inspired by Theo Jansen:** When he needed to optimize 11 link lengths for his Strandbeest, there were 10 trillion possible combinations. Manual search was impossible. So he evolved the solution.

### When to Use This
- You have more than 4 free parameters to optimize simultaneously
- Your wave mechanisms keep needing "one more iteration" (you had 10+ wave versions)
- You can describe what "good" looks like but can't calculate the path to get there
- Cam profile optimization, multi-bar linkage tuning, phase offset selection

### The Method

```
Step 1: Define fitness criteria (🧠 YOU decide what "good" means)
   - "Smooth motion with no jerky zones"
   - "Maximum amplitude with minimum input force"
   - "Gentle acceleration, no sudden stops"

Step 2: Generate many variations (🤖 ASK CLAUDE)
   - "Generate 10 parameter sets for a four-bar that produces gentle sway
     with ground=100, constraint: Grashof must pass"

Step 3: Evaluate each (🧠 YOUR eye judges)
   - Quick cardboard prototypes, or OpenSCAD animation ($t)
   - Score each 1-10 on your fitness criteria

Step 4: Select best 2-3, breed variations (🤖 ASK CLAUDE)
   - "Take these two parameter sets and generate 6 variants
     that interpolate between them, plus 2 mutations"

Step 5: Repeat until satisfied
   - Usually 3-4 generations is enough
   - Accept "good enough" — perfection is the enemy of done
```

**Real example from your work:** Your wave mechanism went through 10+ versions (v3, v4, v7, v10...). Each time you changed one thing and tested. The evolutionary method formalizes this: generate many variants in parallel, evaluate, select, repeat. Faster than serial trial-and-error.
