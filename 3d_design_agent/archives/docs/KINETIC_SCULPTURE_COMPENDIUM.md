# KINETIC SCULPTURE COMPENDIUM
## World-Class Design Knowledge for Mechanical Artists

*A practical reference distilling the equivalent of graduate-level kinetic sculpture education*
*Emphasis: Desktop scale (100-500mm), 3D printing/laser cutting, single-motor systems*

---

# QUICK REFERENCE CARDS

## QRC-1: Gear Design Essentials

| Parameter | Formula | Rule of Thumb |
|-----------|---------|---------------|
| Center distance | `(T1 + T2) × m / 2` | Add 0.1mm clearance for 3D prints |
| Pitch diameter | `T × m` | This is where teeth mesh |
| Module (m) | `PD / T` | Use m=1-2 for desktop, m=0.5 for small |
| Min teeth | 12-14 for 20° pressure angle | Below 12 = undercut problems |
| Gear ratio | `T_driven / T_driver` | Keep under 6:1 per stage |
| Backlash | 0.05-0.1 × m | Tighter = more friction |
| Face width | 5-10 × m | Wider = stronger but heavier |

**Quick Checks:**
- [ ] Gears spin freely by hand?
- [ ] No clicking or grinding?
- [ ] Teeth fully engage (not just tips)?
- [ ] Backlash consistent around full rotation?

---

## QRC-2: Four-Bar Linkage Validation

**Grashof Condition:** `S + L ≤ P + Q`
- S = shortest link, L = longest link, P, Q = others
- If satisfied: at least one link can rotate fully
- If not: rocker-rocker only (oscillation)

| Link Role | What it does | Common issues |
|-----------|--------------|---------------|
| Ground | Fixed frame | Must be rigid, level |
| Crank | Rotates fully | Needs bearing at both ends |
| Coupler | Connects crank to output | Length must stay constant! |
| Rocker | Oscillates | Watch for dead points |

**Pre-Animation Checklist:**
- [ ] Coupler START connected to crank pin?
- [ ] Coupler END connected to output?
- [ ] All intermediate positions reachable?
- [ ] No lockup at extreme positions?
- [ ] Motion type matches joint type?

---

## QRC-3: 3D Printing for Mechanisms

| Parameter | Value | Why |
|-----------|-------|-----|
| Wall thickness | ≥1.2mm | Strength under stress |
| Clearance (press fit) | 0.1-0.15mm | Tight but insertable |
| Clearance (moving) | 0.3-0.5mm | Free rotation |
| Gear clearance | 0.2mm radial | Mesh without binding |
| Overhang limit | 45° | Beyond needs supports |
| Minimum hole | 2mm | Below = unreliable |
| Layer height | 0.2mm for speed, 0.12mm for gears | Finer = smoother teeth |

**Material Selection:**
- **PLA**: Easy, stiff, but brittle long-term
- **PETG**: Flexible, durable, slight stringing
- **ASA**: Outdoor-capable, needs enclosure to print
- **Delrin/POM**: Best for gears (buy, don't print)

---

## QRC-4: Motor Selection (Desktop Scale)

| Motor Type | Torque | Speed | Best For |
|------------|--------|-------|----------|
| N20 geared DC | 0.3-3 kg·cm | 30-300 RPM | Small automata |
| 28BYJ-48 stepper | 0.3 kg·cm | Variable | Precise positioning |
| NEMA 17 stepper | 3-5 kg·cm | Variable | Room scale |
| 370/380 DC | 1-2 kg·cm | 3000-8000 RPM | Needs gearbox |
| Servo (9g) | 1.5 kg·cm | Fast | Oscillating motion |

**Rule of Thumb:** Motor torque × gear ratio > 3× load torque

**Power Budget:**
```
Required torque = (mass × gravity × radius) + friction losses
Friction estimate = 20-40% of theoretical for 3D prints
```

---

## QRC-5: Troubleshooting Motion

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Won't start | Friction too high | Lubricate, increase clearances |
| Starts then stops | Dead point | Add flywheel, adjust phase |
| Jerky motion | Backlash, uneven friction | Reduce backlash, smooth surfaces |
| Clicking | Gear teeth skipping | Increase engagement, reduce load |
| Grinding | Misalignment | Check shaft parallelism |
| Slowing over time | Lubrication failing | Re-lubricate, use dry lube |
| Works on bench, fails installed | Alignment shift | Redesign mounting, add adjustment |
| Speed varies | Binding at certain angles | Check for interference, run full cycle |

---

# DOMAIN 1: HISTORY & LINEAGE (Practical Lessons)

## What the Masters Teach Us

### Heron of Alexandria (1st Century CE)
**Signature:** Steam-powered, weight-driven, pneumatic mechanisms
**Lesson:** Simple physical principles (gravity, pressure, heat) can create complex apparent behavior

### Al-Jazari (1206 CE)
**Signature:** Camshaft programming, water-powered automata
**Lesson:** Cams are programs in metal. A single rotating drum with shaped lobes can choreograph complex sequences.
**Applicable now:** Use cam profiles to create "character" in motion—asymmetric cams give organic feel

### Jaquet-Droz (1770s)
**Signature:** The Writer, The Musician—programmable automata with interchangeable cams
**Lesson:** Modular cam systems allow behavior changes without mechanism rebuild
**Applicable now:** Design for swappable motion profiles

### Vaucanson (1737)
**Signature:** The Digesting Duck—realistic biological motion
**Lesson:** Study the motion you're imitating obsessively before mechanizing
**Applicable now:** Video reference at 0.25x speed before designing linkages

### Alexander Calder (1930s+)
**Signature:** Mobiles—unpowered, wind/touch driven
**Lesson:** Balance is a mechanism. Counterweights create motion without motors.
**Rules:**
- Moment = weight × distance from pivot
- Nested balance points multiply motion complexity
- Unpredictability from interaction, not randomness

### Jean Tinguely (1950s+)
**Signature:** Meta-Matics—chaotic, found-object mechanisms
**Lesson:** Imperfection is aesthetic. Visible mechanics celebrate the machine.
**Applicable now:** Don't hide everything—exposed gears have beauty

### George Rickey (1960s+)
**Signature:** Stainless steel blades on knife-edge bearings
**Lesson:** Ultra-low friction enables monumental movement from minimal force
**Rules:**
- Knife-edge bearings: friction approaches zero
- Blade inertia provides smooth motion
- Wind threshold design: moves in 3 mph wind

### Theo Jansen (1990s+)
**Signature:** Strandbeests—wind-powered walking mechanisms
**Lesson:** Evolved linkage ratios outperform intuitive design
**The Jansen Linkage:** Specific proportions create smooth walking gait
```
Leg ratios (relative to crank = 1.0):
a = 3.8, b = 4.15, c = 3.93, d = 4.02, e = 5.58,
f = 3.94, g = 3.67, h = 6.57, i = 4.90, j = 5.00, k = 2.58
```

### Anthony Howe (2000s+)
**Signature:** Hypnotic wind sculptures with rotating elements
**Lesson:** Compound rotation (rotating while orbiting) creates visual complexity
**Applicable now:** Mount elements on gear faces, not just shafts

### David C. Roy (Contemporary)
**Signature:** Wooden kinetic sculptures, weight-driven, 4-hour run time
**Lesson:** Stored energy (weights, springs) enables elegant motor-free operation
**Rules:**
- 4 hours runtime from 8-pound weight falling 1 meter
- Escapement controls speed
- Every gram of friction steals from runtime

---

# DOMAIN 2: PHYSICS & ENGINEERING (Rules of Thumb)

## Force Transmission Chain

Every kinetic sculpture is a torque chain:
```
Motor → Gearbox → Transmission → Mechanism → Output

Torque available at each stage = Previous × gear ratio × efficiency
Efficiency per stage:
- Spur gears: 95-98%
- Worm gear: 50-90%
- Belt: 95-98%
- Linkage: 80-95%
- Sliding friction: 70-90%
```

## The 10× Rule
Design for 10× the load you expect:
- Measure or estimate actual load
- Multiply by 3× for safety factor
- Multiply by 3× for friction you forgot
- Result: 10× initial estimate

## Gear Math Essentials

**Module System (metric):**
```
Pitch Diameter (PD) = Module × Teeth
Center Distance = (PD1 + PD2) / 2
Addendum = Module (tooth height above PD)
Dedendum = 1.25 × Module (tooth depth below PD)
```

**Pressure Angle:**
- 20° standard: stronger teeth, more radial force
- 14.5° legacy: weaker teeth, less radial force
- **Never mesh different pressure angles**

**Minimum Teeth (before undercut):**
| Pressure Angle | Min Teeth |
|----------------|-----------|
| 14.5° | 32 |
| 20° | 18 |
| 25° | 12 |

## Linkage Kinematics

**Four-Bar Configurations:**
1. **Crank-Rocker:** Input rotates fully, output oscillates
2. **Double-Crank:** Both links rotate (rare, needs precise lengths)
3. **Double-Rocker:** Both links oscillate (most common mistake)

**Transmission Angle (μ):**
- Ideal: 90° (maximum force transfer)
- Acceptable: 40° - 140°
- Below 40° or above 140°: mechanism will stall

**Dead Points:**
- Occur when crank and coupler align
- Flywheel carries mechanism through
- Or offset crank phase (multiple cranks)

## Balancing

**Static Balance:**
```
Σ(mass × distance from axis) = 0
```
For rotating parts: add counterweight opposite heavy side

**Dynamic Balance:**
For high-speed rotation, balance must be in multiple planes
Rule: Below 300 RPM, static balance usually sufficient for art

## Natural Frequency

```
f = (1/2π) × √(k/m)
```
- k = stiffness (N/m)
- m = mass (kg)

**Design Rule:** Either stay far below natural frequency (stiff) or far above (massive) to avoid resonance

## Power Requirements

```
Power (W) = Torque (N·m) × Angular velocity (rad/s)
Power (W) = Force (N) × Velocity (m/s)
```

**Desktop scale estimates:**
- Light decoration (gears only): 0.1-0.5W
- Small automaton: 0.5-2W
- Complex mechanism: 2-5W
- Heavy wave motion: 5-15W

---

# DOMAIN 3: MATERIALS & FABRICATION

## Material Selection Matrix

| Material | Strength | Friction | Outdoor | Print | Cost | Best Use |
|----------|----------|----------|---------|-------|------|----------|
| PLA | Medium | High | No | Easy | Low | Prototypes, low-stress |
| PETG | Medium | Medium | Moderate | Medium | Low | Structural, some friction |
| ASA | Medium | Medium | Yes | Hard | Medium | Outdoor parts |
| Nylon | High | Low | Yes | Hard | Medium | Gears, bearings |
| Delrin/POM | High | Very Low | Yes | No | Medium | Gears, slides |
| Brass | High | Medium | Yes | No | High | Bushings, wear parts |
| Bronze | Medium | Low | Yes | No | High | Bearings |
| Aluminum | High | Medium | Yes | No | Medium | Structure, shafts |
| Stainless | Very High | Medium | Yes | No | High | Shafts, outdoor |
| Baltic Birch | Medium | Medium | No | No | Low | Laser-cut frames |

## 3D Printing Settings for Mechanisms

**Gears:**
```
Layer height: 0.12-0.16mm
Walls: 4+ perimeters
Infill: 50-100%
Print speed: Slow (30-40mm/s)
Orientation: Lay flat, teeth up
```

**Structural Parts:**
```
Layer height: 0.2mm
Walls: 3 perimeters
Infill: 20-40% gyroid
Print speed: Normal (50-60mm/s)
```

**Bearing Surfaces:**
- Print in XY plane (layers perpendicular to motion)
- Sand with 400, 800, 1200 grit
- Apply dry lubricant (PTFE, graphite)

## Laser Cutting Parameters (Approximate for 3mm)

| Material | Power | Speed | Notes |
|----------|-------|-------|-------|
| Acrylic | 60-80% | 10-15mm/s | Clean cuts, polished edge |
| Baltic Birch | 80-100% | 8-12mm/s | May need multiple passes |
| Cardboard | 20-30% | 30-50mm/s | For prototypes |
| Delrin | 70-80% | 8-10mm/s | Smells bad, needs ventilation |

**Kerf Compensation:**
- Laser removes ~0.15-0.25mm
- Offset paths by half kerf for precise fits
- Test on scrap first

## Bearing Solutions

**Ball Bearings (preferred):**
- 608 (8mm bore): Common, cheap, reliable
- 623 (3mm bore): Small, for light loads
- 686 (6mm bore): Medium, good balance

**Press-fit Dimensions (into 3D print):**
- Bearing OD + 0.1mm = hole size
- Example: 608 bearing (22mm OD) → 22.1mm hole

**Sleeve Bearing Alternative:**
- Brass tube as bushing
- Steel shaft inside brass: excellent wear
- Shaft clearance: 0.05-0.1mm

**DIY Bearing (emergency):**
- PTFE tape wrapped around shaft
- Runs in slightly oversized hole
- Surprisingly effective short-term

## Adhesives & Fasteners

| Task | Best Choice | Cure Time | Notes |
|------|-------------|-----------|-------|
| PLA to PLA | CA glue (medium) | Seconds | Brittle joint |
| PETG to PETG | E6000 | 24h | Flexible, strong |
| Metal to plastic | Epoxy | 5min-24h | Prep surfaces |
| Temporary | Hot glue | Seconds | Easy to remove |
| Threaded insert | Heat-set insert | Minutes | Much stronger than tapping |

**Fastener Sizing:**
- M3 for most desktop mechanisms
- M2 for very small work
- M4+ for structural connections

---

# DOMAIN 4: DESIGN PROCESS (Practical Workflow)

## The 5-Stage Process

### Stage 1: Motion Intent
Before any mechanism design:
1. **Describe the motion in words** (e.g., "gentle rolling waves with occasional white-cap bursts")
2. **Find video reference** of similar motion
3. **Time the motion** (period, rhythm, pauses)
4. **Sketch the motion path** (not the mechanism!)

### Stage 2: Mechanism Selection
Use this decision tree:

```
What motion type?
├── Continuous rotation → Gears, belts
├── Oscillation → Four-bar, cam, crank-rocker
├── Linear → Slider-crank, rack-pinion, lead screw
├── Complex path → Coupler curve, cam, pantograph
└── Intermittent → Geneva, escapement, ratchet

What speed relationship?
├── Constant ratio → Gear train
├── Variable ratio → Cam, non-circular gear
└── Sequential → Cam barrel, programming wheel
```

### Stage 3: Cardboard Prototype
Before any CAD:
1. Cut mechanism from cardboard
2. Pin joints with brads or wire
3. Test motion by hand
4. Iterate in minutes, not hours

**Cardboard Rules:**
- 1mm cardboard ≈ 3mm printed (scale factor 3:1)
- Mark pivot points before cutting
- Use paper fasteners for quick pivots

### Stage 4: CAD & Animation
OpenSCAD workflow:
```openscad
// Always parameterize time
$t = 0; // 0-1 for full cycle

// Calculate mechanism positions
crank_angle = $t * 360;
// ... kinematic calculations ...

// Animate with calculated values
rotate([0, 0, crank_angle]) crank_arm();
```

**Animation Validation:**
- Run at $t = 0, 0.25, 0.5, 0.75, 1.0
- Check for collisions at each position
- Verify linkage lengths stay constant
- Trace output path with hull() of multiple positions

### Stage 5: Physical Assembly
1. Print one part at a time
2. Test fit before printing next
3. Adjust dimensions in CAD based on reality
4. Document every adjustment for version control

## Version Control for Physical Objects

```
project_v01.scad  - Initial concept
project_v02.scad  - First print, discovered clearance issues
project_v03.scad  - Clearance fixed, gear mesh improved
project_v04.scad  - LOCKED - working mechanism
project_v05.scad  - Added decorative elements
```

**Changelog Comments:**
```openscad
// V04 CHANGES:
// - Increased gear clearance from 0.2 to 0.3mm
// - Added chamfer to shaft entry
// - Fixed coupler length from 45 to 47mm
// LOCKED: Mechanism validated, do not change kinematics
```

## Documentation That Actually Helps

**For Each Mechanism:**
1. Sketch of kinematic diagram (links, joints, ground)
2. Key dimensions with tolerances
3. Assembly order (what goes on first?)
4. Known issues and workarounds
5. Photo at each assembly stage

---

# DOMAIN 5: MOTION AESTHETICS (Making It Feel Alive)

## Speed Psychology

| Speed | Feels Like | Use For |
|-------|-----------|---------|
| <0.5 RPM | Glacial, contemplative | Moon, slow rotation |
| 0.5-2 RPM | Slow, peaceful | Clouds, gentle sway |
| 2-10 RPM | Natural, organic | Waves, breathing |
| 10-30 RPM | Energetic, busy | Machinery, activity |
| >30 RPM | Frantic, anxious | Rarely desirable |

## Rhythm Design

**Polyrhythm:** Multiple elements at different speeds
```
Moon: 0.1× base speed
Stars: 0.3× base speed
Waves: 1.0× base speed
Birds: 1.5× base speed
```

When speeds share no common factor, pattern never exactly repeats → organic feel

**Phase Offset:** Start elements at different points in cycle
```
Wave 1: Phase 0°
Wave 2: Phase 30°
Wave 3: Phase 60°
Wave 4: Phase 90°
Wave 5: Phase 120°
```
Creates propagating wave effect

## Animation Principles in Mechanisms

### Slow In, Slow Out
Natural motion accelerates and decelerates.

**Mechanical Solutions:**
- Cam profiles with tangent entry/exit
- Four-bar linkages (natural slow at extremes)
- Spring-loaded returns

### Anticipation
Brief motion opposite the main action.

**Mechanical Solutions:**
- Backlash deliberately used
- Spring wind-up before release
- Counter-rotation before main motion

### Follow-Through
Motion continues past the stopping point, then settles.

**Mechanical Solutions:**
- Pendulum overshoot
- Compliant (flexible) elements
- Damped oscillation

### Secondary Action
Supporting motion that adds life.

**Mechanical Solutions:**
- Loose connections that jiggle
- Trailing elements (ribbons, chains)
- Sympathetic vibration

## Emotional Motion Mapping

| Emotion | Speed | Smoothness | Rhythm | Direction |
|---------|-------|------------|--------|-----------|
| Calm | Slow | Very smooth | Regular | Horizontal |
| Joy | Medium-fast | Bouncy | Upbeat | Upward |
| Anxiety | Variable | Jerky | Irregular | Confined |
| Awe | Very slow | Smooth | Regular | Expansive |
| Whimsy | Variable | Playful | Syncopated | Unexpected |
| Drama | Slow with bursts | Contrasting | Pauses | Vertical |

## Composition in Time

**Foreground Motion:**
- Fastest-moving elements
- Capture immediate attention
- Should be mechanically simpler (reliable)

**Background Motion:**
- Slowest-moving elements
- Noticed after initial impression
- Can be more mechanically complex (less critical)

**Visual Silence:**
- Not everything should move
- Static elements provide reference
- Contrast makes motion visible

---

# DOMAIN 6: SOUND DESIGN

## Intentional Sound

### Mechanical Percussion
| Element | Material | Sound Character |
|---------|----------|----------------|
| Chimes | Brass tube | Clear, resonant |
| Bells | Bronze | Rich, sustained |
| Clicks | Hardwood | Sharp, rhythmic |
| Rustling | Rice/beads in tube | Organic, continuous |
| Tapping | Steel on steel | Metallic, precise |

### Sound Tuning
**Chime Tuning:**
```
Frequency ∝ 1 / length²
Halving length → 4× higher pitch
```

**Resonant Chambers:**
- Enclosed volume amplifies sound
- Opening size affects frequency response
- Larger chamber = lower fundamental

## Sound Minimization

**Gear Noise Sources:**
1. Tooth impact (reduce with helical gears or higher quality)
2. Backlash rattle (tighten mesh or add preload)
3. Resonance (add damping or change speed)

**Silent Mechanism Tips:**
- Use timing belts instead of gears for final stage
- PTFE/Delrin gears mesh quieter than PLA
- Felt pads between frame and mechanism
- Rubber grommets on motor mounts

**Lubrication for Quiet:**
- Grease: Quietest, attracts dust
- Dry PTFE: Quiet, clean, needs reapplication
- Oil: Medium, migrates, attracts dust
- Nothing: Loudest (except Delrin, which runs dry)

---

# DOMAIN 7: SITE-SPECIFIC (Indoor Desktop Focus)

## Environmental Factors

**Humidity:**
- Wood expands/contracts 0.1-0.5% across grain
- Paper-based materials (cardboard) deform significantly
- PLA absorbs moisture, becomes brittle
- Solution: Seal wood, use PETG for humid environments

**Temperature:**
- PLA softens above 50°C (car, sunny window)
- Lubricants thicken when cold
- Electronics may malfunction below 0°C or above 40°C
- Solution: ASA for sun-exposed, silicone grease for cold

**Dust:**
- Accumulates on horizontal surfaces
- Clogs lubricants over time
- Worse near windows, doors
- Solution: Enclosed mechanisms, periodic cleaning

**Vibration:**
- Nearby foot traffic
- Building HVAC systems
- Solution: Rubber feet, isolation mounts, mass at base

## Display Considerations

**Viewing Distance:**
| Scale | Ideal Distance | Details Visible |
|-------|---------------|-----------------|
| 150mm | 30-50cm | All mechanism |
| 300mm | 60-100cm | Major features |
| 500mm | 1-2m | Silhouette, motion |

**Lighting:**
- Side lighting reveals motion better than front
- Backlighting creates silhouette drama
- Avoid direct light on reflective metal (glare)
- Consider shadow as design element

---

# DOMAIN 8: PROFESSIONAL PRACTICE (Essentials)

## Documentation for Longevity

**What to Record:**
1. Bill of materials (every part, source, cost)
2. Assembly sequence (with photos)
3. Adjustment points and current settings
4. Maintenance schedule
5. Failure history and repairs

**Format:**
- Keep with the sculpture physically
- Backup electronically
- Assume future-you has amnesia

## Pricing Framework

**Desktop Kinetic Sculpture (rough estimate):**
```
Materials: Actual cost
Labor: Hours × your rate
Complexity factor: Simple (1×), Medium (1.5×), Complex (2×)
Prototyping: Add 20-40% for development time
Markup: 2-3× for gallery, 1.5× for direct sale
```

**Example:**
- Materials: $50
- Labor: 40 hours × $25 = $1000
- Complexity: Medium (×1.5) = $1575
- Prototyping: +30% = $2047
- Gallery markup: ×2.5 = $5118
- **Gallery price: ~$5000**

## Photographing Kinetic Work

**Video is Essential:**
- Kinetic work needs motion documentation
- Minimum: 30-second loop showing full cycle
- Better: Multiple angles, different speeds
- Best: Making-of documentation

**Still Photography:**
- Long exposure shows motion blur (artistic)
- Multiple exposure composite shows motion range
- Detail shots of mechanism (collectors love this)

---

# DOMAIN 9: TIPS, TRICKS & HARD-WON WISDOM

## Mechanism Secrets

**The "One More Bearing" Rule:**
If something binds, adding a bearing rarely hurts and often helps.

**First Prototype Reality:**
The first prototype never works as expected. Budget time and material for 2-3 iterations minimum.

**Hidden Adjustment:**
Every mechanism needs adjustment points. Design them in:
- Slotted holes for position adjustment
- Eccentric mounts for fine-tuning
- Set screws for shaft positioning
- Shim locations for spacing

**Deliberate Play:**
A little backlash/looseness often makes mechanisms run smoother. Too tight = binding.

## Material Wisdom

**PLA Lifespan:**
- Indoor, low stress: Years
- Indoor, high stress: 6-12 months (creep/fatigue)
- Direct sun: Weeks (warping)
- Humid environment: Months (brittleness)

**Best 3D Print Material by Application:**
| Application | First Choice | Why |
|-------------|--------------|-----|
| Gears | Nylon or Delrin | Low friction, wear resistant |
| Structure | PETG | Tough, doesn't crack |
| Appearance | PLA | Easy, nice finish |
| Outdoor | ASA | UV stable |
| Prototypes | PLA | Cheap, fast |

**Why Wood Moves:**
Wood expands/contracts across the grain, not along it. Design joints to allow movement or everything cracks.

## Debugging Motion

**The Finger Test:**
Rotate mechanism by hand. Feel for:
- Rough spots (misalignment, debris)
- Tight spots (interference, over-constraint)
- Loose spots (excessive clearance, worn parts)
- Click points (dead points, catch points)

**Sound Diagnostics:**
| Sound | Likely Cause |
|-------|--------------|
| Click-click | Gear teeth skipping |
| Grinding | Misalignment or debris |
| Squeak | Friction, needs lubricant |
| Rumble | Bearing failing |
| Silence then clunk | Dead point, needs flywheel |

**Temperature Troubleshooting:**
If it works when cold but fails warm (or vice versa):
- Thermal expansion changing clearances
- Lubricant viscosity changing
- Electronics drifting

## Installation Lessons

**What Goes Wrong:**
1. Mounting surface not level
2. Fasteners loosening from vibration
3. Power cord strain on connector
4. Dust accumulation over time

**What to Bring:**
- Spare fasteners
- Shims (various thicknesses)
- Level
- Screwdrivers + hex keys
- Lubricant
- Cleaning cloth
- The documentation

---

# DOMAIN 10: LONGEVITY ENGINEERING

## Lessons from Surviving Automata

18th-century automata still run today because:
1. **Oversized components** - Built with 10× safety factor
2. **Accessible design** - Can be disassembled for repair
3. **Quality materials** - Brass, steel, not plastic
4. **Regular maintenance** - Professional conservators every 5-10 years

## Wear Prediction

**High-Wear Locations:**
- Gear teeth (replace pair, not single gear)
- Shaft in bearing (shaft wears, bearing wears, or both)
- Sliding contacts (cams, sliders)
- Pivot points (especially with side loading)

**Wear Timeline (desktop scale, continuous operation):**
| Material Pair | Lubricated | Dry |
|--------------|------------|-----|
| PLA on PLA | 1-2 years | Months |
| PETG on PETG | 2-3 years | 1 year |
| Delrin on steel | 5+ years | 2-3 years |
| Brass on steel | 10+ years | 5+ years |

## Design for Maintainability

**Access Points:**
- Back panel that removes without tools
- Or screws, not glue
- Labeling for what's inside

**Modular Replacement:**
- Gear assemblies as sub-units
- Standardized shaft sizes
- Interchangeable bearings

**Documentation:**
- Parts list attached to sculpture
- "Last maintained" log
- Original CAD files accessible

## Lubrication Strategy

**3D Print Mechanisms:**
- Initial: Dry PTFE spray (works great fresh)
- After 6 months: Light machine oil if squeaking
- Annual: Clean and re-apply PTFE

**Metal Mechanisms:**
- Initial: Light grease on gears, oil on bearings
- Annually: Inspect, re-lubricate if dry
- Every 5 years: Full cleaning and re-grease

**DO NOT:**
- Mix lubricant types (some react badly)
- Over-lubricate (attracts dust, makes mess)
- Use WD-40 as lubricant (it's a solvent, dries out)

---

# DOMAIN 11: ASSEMBLY SCIENCE

## Assembly Sequence Planning

**Golden Rule:** Assemble from inside out, core first

**Sequence Template:**
1. Main frame/base (ground reference)
2. Primary bearings/bushings
3. Main shaft(s)
4. Primary gear train
5. Secondary mechanisms
6. Coupling between systems
7. Decorative elements
8. Final adjustment

**Point of No Return:**
Some assemblies can't be disassembled:
- Press-fit bearings
- Glued connections
- Captured components
- **Test everything BEFORE point of no return**

## Adjustment Mechanisms

**Eccentric Mounts:**
Rotating mount shifts position by 2× eccentricity
```
Example: 0.5mm eccentric gives ±0.5mm adjustment
```

**Slotted Holes:**
Slot length = adjustment range + fastener clearance

**Shims:**
Keep a set: 0.1, 0.2, 0.5, 1.0mm
Brass shim stock can be cut to size

**Set Screws:**
- Flat point for grip without damage
- Cup point for permanent positioning
- Cone point for centering

## First-Run Protocol

1. **Before Power:**
   - Turn mechanism by hand through full cycle
   - Feel for binding, listen for interference
   - Verify all fasteners tight

2. **First Power:**
   - Apply power for 2 seconds only
   - Check rotation direction
   - Listen for abnormal sounds

3. **Observation Period:**
   - Run for 1 minute, observe
   - Run for 10 minutes, observe
   - Run for 1 hour, observe
   - Check for heat buildup (feel motor, bearings)

4. **Adjustment:**
   - Mark current settings before adjusting
   - Change one variable at a time
   - Document what works

## The "Almost Works" Problem

**Common Causes:**
| Symptom | Likely Issue | Fix |
|---------|--------------|-----|
| Works sometimes | Marginal clearance | Increase clearance slightly |
| Works then fails | Heat expansion | Increase clearance, add cooling |
| Works briefly | Lubrication failing | Re-lubricate, check for debris |
| Works if helped | Dead point | Add flywheel, adjust phase |
| Works slow not fast | Inertia too high | Reduce mass, increase power |

---

# DOMAIN 12: THEATRICAL KINETICS

## Viewing Experience Design

**Distance and Detail:**
- Close (arm's length): Mechanism visible, can hear sounds
- Medium (2-3m): Overall motion clear, details lost
- Far (across room): Silhouette and major motion only

**Design for Multiple Distances:**
- Large, slow elements visible from far
- Fine, fast elements reward close viewing
- Medium-speed creates mid-range interest

## Lighting Integration

**Side Lighting:**
Reveals depth, emphasizes motion, creates shadows

**Back Lighting:**
Creates silhouettes, dramatic effect, hides mechanism

**Top Lighting:**
Neutral, shows form, can be boring

**Shadow as Medium:**
- Cast shadows on background
- Moving shadows multiply visual interest
- Consider shadow as second artwork

## Pacing for Engagement

**Optimal Cycle Time:**
- Too fast (<10 sec): Can't follow, becomes blur
- Sweet spot (30-90 sec): Can follow, still discovering
- Too slow (>5 min): Loses attention

**Discovery Moments:**
- Something happens every 10-15 seconds
- Major event every 30-60 seconds
- Hidden detail revealed occasionally (2-3 minutes)

**Repeat Viewing:**
- First view: overall motion
- Second view: notice secondary elements
- Third view: discover hidden details
- Long-term: appreciate polyrhythm patterns emerging

## Layered Complexity

**Immediate Layer (0-5 seconds):**
- Dominant motion
- Sets emotional tone
- Must work reliably

**Discovery Layer (5-30 seconds):**
- Secondary motions
- Relationships between elements
- Rewards attention

**Hidden Layer (1+ minute):**
- Subtle details
- Phase relationships
- Easter eggs for patient viewers

---

# DOMAIN 13: SCALE WISDOM

## Desktop Scale (100-500mm)

**Advantages:**
- 3D printable in one piece (many printers)
- Manageable assembly by hand
- Affordable prototyping
- Ships easily

**Challenges:**
- Small tolerances matter more
- Limited motor torque
- Details hard to execute
- Can look "toylike"

**Desktop-Specific Rules:**
- Minimum feature size: 1mm practical
- Gear module: 0.5-1.5 typical
- Shaft diameter: 3-6mm common
- Bearing: 608 often too large, use 623 or 686

**Motor Recommendations:**
- N20 geared DC (30-300 RPM): Most versatile
- 28BYJ-48 stepper: Cheap, precise, weak
- 9g servo: Good for oscillation

## Scaling Up (500mm-2m)

**What Changes:**
- 3D printing becomes sectional assembly
- Laser cutting becomes CNC routing
- Weight becomes significant
- Deflection matters

**Scaling Math:**
| Property | Scales As |
|----------|-----------|
| Length | 1× |
| Area | L² |
| Volume/Weight | L³ |
| Moment of inertia | L⁴ |
| Deflection | L⁴ / L³ = L |

**Example:**
2× size = 8× weight = 16× moment of inertia
Motor needs ~8× more torque

**What Doesn't Scale:**
- Springs (need different spring, not bigger)
- Motors (need bigger motor)
- Bearings (need more/larger bearings)
- Electronics (same size, just more power)

## Scaling Down (<100mm)

**Challenges:**
- Tolerances become impossible
- Friction dominates (low mass, high friction ratio)
- Assembly difficult (tweezers required)
- Visibility of mechanism limited

**Solutions:**
- SLA printing for precision
- Jewel bearings (watch parts)
- Very low friction materials (sapphire, ruby)
- Watchmaker tools and techniques

---

# DOMAIN 14: PERCEIVED QUALITY

## The 3-Second Assessment

What experts notice immediately:
1. **Finish quality** - Are edges clean? Surfaces smooth?
2. **Alignment** - Are things parallel that should be? Square?
3. **Motion quality** - Smooth or jerky? Consistent?
4. **Sound** - Quiet confidence or grinding struggle?
5. **Balance** - Does it look stable? Intentional?

## Finishing Details

**Edge Treatment:**
- All edges chamfered or rounded
- No sharp corners that snag
- Consistent radius throughout

**Surface Quality by Material:**
| Material | Expected Finish |
|----------|-----------------|
| 3D print | Sanded to 400 grit minimum for visible |
| Laser cut | Edges flame-polished (acrylic) or sealed (wood) |
| Metal | Brushed, polished, or intentionally patinated |

**Fastener Discipline:**
- All screws same type and size where possible
- Heads aligned (slot or hex oriented consistently)
- Countersunk where appropriate
- No stripped heads

## Motion Quality Signals

**"Smooth" means:**
- No sudden speed changes
- No hesitation or stutter
- Consistent through full cycle
- Silent or pleasant sound

**"Precise" means:**
- Minimal backlash
- Parts return to exact position
- No wobble or play
- Repeatable motion

**"Effortless" means:**
- Motor not straining (no whine under load)
- Easy to turn by hand
- No visible struggle at any point

## Professional vs Amateur

| Amateur Signs | Professional Alternative |
|---------------|-------------------------|
| Hot glue visible | Hidden fasteners or clean glue lines |
| Wires exposed | Wire routing, strain relief |
| Uneven gaps | Consistent margins |
| Mixed fasteners | Standardized hardware |
| Wobbly motion | Proper bearing support |
| Layer lines visible | Sanded or oriented for aesthetics |
| Squeaking | Properly lubricated |

## The Value of Restraint

**Less can be more:**
- One beautiful motion > ten mediocre ones
- Simple, reliable > complex, fragile
- Confidence in negative space
- Let motion breathe

---

# META-KNOWLEDGE: TACIT WISDOM

## The Diagnostic Glance

What experts see in 3 seconds:
1. **Bearing condition** - Wobble = worn or poorly supported
2. **Gear mesh** - Sound of mesh reveals engagement quality
3. **Frame rigidity** - Any flex = problems coming
4. **Assembly quality** - Consistent gaps, aligned screws
5. **Wear patterns** - Shiny spots show friction points

## The Sound of Right

**Healthy sounds:**
- Gears: Soft hum, not clicking
- Bearings: Silent or soft whir
- Linkages: No clunking at reversal
- Motor: Consistent pitch, no strain

**Warning sounds:**
- Clicking: Teeth skipping or interference
- Grinding: Misalignment or debris
- Squeak: Dry friction
- Whine: Motor overloaded
- Rattle: Loose fastener or excessive backlash

## The Touch Test

**By hand (power off):**
- Smooth = consistent resistance throughout rotation
- Binding = resistance increases at certain positions
- Play = looseness when changing direction
- Gritty = debris or surface damage
- Notchy = damage or interference

**How hard to push:**
- Light touch rotates freely = well designed
- Firm pressure needed = marginal
- Can't turn by hand = won't run well on motor

## The Invisible Adjustments

**What experts do that isn't documented:**
1. Feel a binding spot → slight loosening of one fastener
2. Hear a squeak → drop of oil on specific surface
3. See wobble → shim added under bearing
4. Notice slow spot → slight cam adjustment
5. Feel roughness → polish with 1200 grit by hand

**The sensing:**
- Fingertip sensitivity for surface quality
- Ear for frequency changes indicating load
- Eye for slight misalignment (0.1mm visible)
- Hand for resistance changes through cycle

## The Compromise Hierarchy

**What to sacrifice first:**
1. Cost (spend money to solve problems)
2. Complexity (simplify if possible)
3. Features (cut scope before quality)
4. Speed (slower is usually fine)

**What to protect last:**
1. Reliability (must work every time)
2. Safety (never compromise)
3. Core motion quality (the main experience)
4. Longevity (should last years)

## The Teaching Moment

**Demonstrations that build intuition:**

**For friction:**
Push a heavy book across a table. Now put dowels under it (rolling). Feel the difference. That's why bearings matter.

**For balance:**
Hold a broomstick horizontally by one end. Now hold it by the middle. Feel the difference. That's why balance point matters.

**For gear mesh:**
Mesh two gears with fingers between them. Feel the pressure. Now mesh them too tight. Feel how they bind. That's proper mesh.

**For resonance:**
Push a swing at random times vs. at its natural frequency. That's why timing matters.

**For backlash:**
Rotate a gear forward then backward without the output moving. That's backlash. Now try to write with that much play in your pencil.

---

# DOMAIN 15: REUBEN MARGOLIN — WAVE SCULPTURE MECHANISMS

## Overview
Reuben Margolin (Emeryville, CA) — painter turned kinetic artist. 20+ years building mechanical wave sculptures. 34 wave sculptures, 10 caterpillars catalogued. Core philosophy: analog computation, one motor when possible, math built into the mechanism.

## 8 Mechanism Families

| Family | Principle | Key Example | Motor Count |
|--------|-----------|-------------|-------------|
| **Camshaft** | Offset disc cams on rotating shaft, each cam's position = phase | Square Wave (2 perpendicular shafts, 9 discs each offset 45°) | 1-9 |
| **Helix** | Rotating helix = continuous cam, cable wraps around to drive sliders | Triple Helix (3 shafts at 120°, 1027 strings, 111 sliders) | 1 |
| **Eccentric Cam** | Eccentric ring/cam gives SHM, combined with string distribution | River Loom (2 eccentric cams, 271 prime-number strings) | 1 |
| **String-Weave** | Strings through matrix; weave pattern = motion mapping function | Confluence (2024, Python-computed paths, 2ⁿ possibilities) | varies |
| **Multi-Frequency Fourier** | Integer-ratio sprocket chains = exact frequency relationships | Arc Line (4 sprockets: 20,21,27,35 teeth → 27-min cycle) | 1 |
| **Topology + Waves** | Wave equation on non-Euclidean surface, continuity required | Mobius Wave (3.5 wavelengths, torus parametric equations) | 1 |
| **Epicycloid/Parametric** | Nested rotation traces complex paths, perceived dimension > actual | Arc Line (2D motion → brain infers 3D = imaginary component) | 1 |
| **Interactive** | Human bodies as wave generators | Connected (dancers + 88 pulleys + motor) | 1 + humans |

## Scale Reference

| Sculpture | Strings/Cables | Pulleys | Motors | Weight | Material |
|-----------|---------------|---------|--------|--------|----------|
| Nebula | 445 | thousands | **1** | 11,000 lbs | Aluminum, bicycle reflectors (14,064) |
| Magic Wave | 256 | 3,000 | 9 | — | 5km cable |
| Triple Helix | 1,027 | — | 1 | — | Aluminum helix, basswood blocks |
| Cadence | 216 | — | 1 | — | Maple links at 120° |
| Anemone | 48 | — | 2 | — | Wood helices, steel bars |

## Key Design Principles

**Variable Amplitude**: Disc cams slide on shaft to adjust eccentricity per station (Square Wave method)

**String Path Optimization**: For N pulleys, 2^N paths. Shortest = correct. Use computation for design, analog for execution.

**Friction Cascade**: F_out ≈ F_in × 0.95^n. Max ~9 pulleys in series. Parallelize instead.

**Prime Grid Counts**: 271 (River Loom) avoids visual Moiré. Non-prime → visible repetition.

**Fool's Tackle**: Pulley cluster doubles displacement at half force (Cambrian central ring).

**Topological Continuity**: Mobius → use 3.5 wavelengths (half-integer avoids cancellation at twist). Edges lie on torus.

---

# STARRY NIGHT APPLICATION NOTES

## Applying This Knowledge to V55+

### Current Mechanism Review

**Wave System (Four-Bar):**
- Grashof condition: Verify S+L ≤ P+Q for each crank
- Transmission angle: Check at extremes, should be 40°-140°
- Phase offsets: 30° between waves creates propagation
- Coupler constraint: Length must stay constant (validate in animation)

**Gear Train:**
- Module 1-1.5 appropriate for desktop scale
- Check minimum teeth (≥14 for 20° pressure angle)
- Verify center distances match calculated values
- Backlash: 0.3mm radial clearance for 3D print

**Rice Tube Acoustic:**
- Resonance: Tube length determines fundamental frequency
- Rice quantity: Affects loudness and character
- Motion speed: Faster = louder, slower = subtle

### Improvement Opportunities

1. **Bearing Upgrade:**
   Current: Plain holes in 3D print
   Better: Press-fit bronze bushings or 623 bearings

2. **Gear Material:**
   Current: PLA
   Better: Delrin gears (at least for high-speed mesh)

3. **Lubrication Plan:**
   Add dry PTFE to all gear meshes
   Document in maintenance schedule

4. **Adjustment Points:**
   Add slotted holes for motor position
   Eccentric mount for one gear to adjust mesh

5. **Documentation:**
   Create assembly sequence document
   Photograph each assembly step

### Validation Checklist for V55

- [ ] All four-bar linkages pass Grashof check
- [ ] All transmission angles within 40°-140°
- [ ] All coupler lengths constant through animation
- [ ] Gear center distances match calculation
- [ ] Minimum wall thickness ≥1.2mm everywhere
- [ ] Moving clearances ≥0.3mm
- [ ] Motor torque ≥3× calculated load
- [ ] Each motion has identified physical driver
- [ ] Assembly sequence documented
- [ ] Maintenance access designed in

---

# TROUBLESHOOTING GUIDE

## Quick Diagnosis

| Problem | Check First | Check Second | Check Third |
|---------|-------------|--------------|-------------|
| Won't start | Power connected? | Motor working? | Binding point? |
| Starts then stops | Dead point? | Overheating? | Loose fastener? |
| Runs rough | Lubrication? | Alignment? | Debris? |
| Makes noise | What noise? (See sound table) | Location? | Recent change? |
| Runs too slow | Power supply? | Motor loaded? | Friction increase? |
| Runs too fast | Correct gear ratio? | Governor (if any)? | Load decreased? |
| Wobbles | Bearing worn? | Shaft bent? | Mounting loose? |

## Emergency Repairs

**Quick fixes for common issues:**

| Issue | Quick Fix | Proper Fix |
|-------|-----------|------------|
| Squeaking | Drop of oil | Identify friction source, lubricate properly |
| Loose gear | CA glue on shaft | Print new gear with tighter bore |
| Cracked part | Epoxy | Print replacement |
| Motor dying | Temporarily increase voltage (careful!) | Replace motor |
| Binding | Increase clearance with file | Redesign part |

---

# APPENDIX: FORMULAS

## Gear Formulas
```
Pitch Diameter = Module × Teeth
Center Distance = (PD1 + PD2) / 2
Gear Ratio = T_driven / T_driver
Output Speed = Input Speed / Gear Ratio
Output Torque = Input Torque × Gear Ratio × Efficiency
```

## Linkage Formulas
```
Grashof Condition: S + L ≤ P + Q
Transmission Angle: μ = arccos((a² + b² - c² - d²) / (2ab))
(where geometry defines a, b, c, d at given position)
```

## Power Formulas
```
Power (W) = Torque (N·m) × Angular Velocity (rad/s)
Angular Velocity (rad/s) = RPM × 2π / 60
Torque (N·m) = Force (N) × Lever Arm (m)
```

## Material Formulas
```
Stress = Force / Area
Strain = Change in Length / Original Length
Deflection (cantilever) = FL³ / (3EI)
Natural Frequency = (1/2π) × √(k/m)
```

---

*KINETIC SCULPTURE COMPENDIUM v1.0*
*Compiled for the Starry Night project and future kinetic art*
*Practical focus: Desktop scale, 3D printing, single-motor systems*
