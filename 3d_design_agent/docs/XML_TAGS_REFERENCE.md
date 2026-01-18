# XML TAGS REFERENCE v2.0
## Custom Prompt Tags for 3D Mechanical Design

---

> **These XML tags provide structured input/output formatting for Claude interactions in the 3D Mechanical Design workspace.**

**Version 2.0 Enhancements:**
- Polymath methodology tags (Seven Masters)
- Compendium reference tags
- Quality assessment tags
- Longevity engineering tags
- Motion design tags
- Sub-agent communication tags

---

## PURPOSE

Custom XML tags enable:
- Clear delineation of component definitions
- Protected/locked sections that must not be modified
- Constraint specifications with validation status
- Vision element preservation (user's creative intent)
- Polymath methodology verification
- Quality and longevity tracking
- Sub-agent handoff communication
- Migration tracking between versions

---

## TABLE OF CONTENTS

### Core Tags (Original)
1. [`<component>`](#1-component---mechanical-component-definition)
2. [`<locked>`](#2-locked---frozen-section-marker)
3. [`<mechanism>`](#3-mechanism---complete-mechanism-definition)
4. [`<constraint>`](#4-constraint---physical-constraint-definition)
5. [`<vision>`](#5-vision---user-vision-element)
6. [`<checkpoint>`](#6-checkpoint---verification-checkpoint)
7. [`<migration>`](#7-migration---version-migration-definition)
8. [`<phase>`](#8-phase---animation-phase-definition)
9. [`<z-layer>`](#9-z-layer---z-layer-definition)
10. [`<diff>`](#10-diff---version-difference-marker)

### Polymath Tags (NEW)
11. [`<polymath-check>`](#11-polymath-check---seven-masters-verification)
12. [`<physics-validation>`](#12-physics-validation---physics-check-result)
13. [`<failure-pattern>`](#13-failure-pattern---known-failure-reference)

### Quality Tags (NEW)
14. [`<quality-assessment>`](#14-quality-assessment---perceived-quality-grade)
15. [`<motion-quality>`](#15-motion-quality---motion-aesthetics-evaluation)
16. [`<longevity>`](#16-longevity---lifespan-and-maintenance-spec)

### Sub-Agent Tags (NEW)
17. [`<agent-handoff>`](#17-agent-handoff---inter-agent-communication)
18. [`<analysis-report>`](#18-analysis-report---sub-agent-output)
19. [`<compendium-ref>`](#19-compendium-ref---compendium-reference)

### Reference
- [Usage Patterns](#usage-patterns)
- [Agent Behavior Rules](#agent-behavior-rules)
- [Tag Priority Matrix](#tag-priority-matrix)

---

# CORE TAGS (Original)

---

## 1. `<component>` - Mechanical Component Definition

### Purpose
Define a mechanical component with all its parameters, position, and relationships.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `name` | Yes | string | Unique component identifier |
| `type` | No | gear, linkage, cam, shaft, bracket, frame, custom | Component category |
| `status` | No | active, deprecated, locked | Component state |

### Child Elements
- `<param name="..." value="...">` - Component parameters
- `<position x="..." y="..." z="..."/>` - 3D position
- `<meshes-with>` - Gear mesh relationships
- `<connects-to>` - Linkage connections
- `<material>` - Material specification (NEW)
- `<wear-point>` - Wear surface identification (NEW)
- `<notes>` - Design notes

### Example
```xml
<component name="master_gear" type="gear" status="locked">
  <param name="teeth">60</param>
  <param name="module">2.0</param>
  <param name="thickness">5.0</param>
  <param name="bore_diameter">8.0</param>
  <position x="70" y="30" z="8"/>
  <meshes-with>motor_pinion</meshes-with>
  <meshes-with>sky_drive_gear</meshes-with>
  <material>PETG</material>
  <wear-point surface="teeth" partner="motor_pinion" lubrication="PTFE spray"/>
  <notes>Main power distribution gear - DO NOT MODIFY</notes>
</component>
```

### Agent Behavior
- When modifying a component, first check its `status`
- If `status="locked"`, refuse modification without explicit user override
- Always update `<meshes-with>` relationships when gear positions change
- Check `<wear-point>` when MaterialsExpert reviews design

---

## 2. `<locked>` - Frozen Section Marker

### Purpose
Mark code or content that should not be modified under any circumstances.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `since` | Yes | date (YYYY-MM-DD) | When locked |
| `reason` | Yes | string | Why it's locked |
| `owner` | No | user, agent | Who locked it |
| `unlock-requires` | No | string | What would justify unlocking |

### Example
```xml
<locked since="2026-01-16" reason="User approved final position" owner="user">
  // Cliff position - DO NOT MODIFY
  cliff_x = 0;      // Flush left
  cliff_y = 0;      // Flush bottom
  cliff_scale = 1.2; // +20% as per user vision
</locked>
```

### In OpenSCAD Comments
```openscad
// <locked since="2026-01-16" reason="Final gear ratio approved">
master_gear_teeth = 60;
motor_pinion_teeth = 10;
// </locked>
```

### Agent Behavior
- **NEVER** modify content inside `<locked>` tags without explicit user override
- Before any operation affecting locked content, warn the user
- When user says "lock this", create a `<locked>` wrapper
- Locked sections survive version changes - preserve them
- Add to lock registry in VersionController

---

## 3. `<mechanism>` - Complete Mechanism Definition

### Purpose
Define a complete mechanism with all its components and kinematic relationships.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `name` | Yes | string | Mechanism identifier |
| `type` | No | four-bar, gear-train, cam-follower, slider-crank, custom | Mechanism type |
| `version` | No | number | Version number |

### Child Elements
- `<component ref="..."/>` - Reference to component
- `<parameter name="..." value="..."/>` - Mechanism parameters
- `<grashof-check>` - Grashof condition result (PASS/FAIL)
- `<motion-type>` - Resulting motion type
- `<polymath-check ref="..."/>` - Reference to Polymath verification (NEW)
- `<physical-connection>` - Connection chain verification (NEW)

### Example
```xml
<mechanism name="wave_drive" type="four-bar" version="3">
  <component ref="camshaft"/>
  <component ref="crank_disc_1"/>
  <component ref="coupler_rod_1"/>
  <component ref="wave_layer_1"/>

  <parameter name="crank_length">25</parameter>
  <parameter name="coupler_length">80</parameter>
  <parameter name="ground_length">60</parameter>
  <parameter name="rocker_length">50</parameter>

  <grashof-check>PASS</grashof-check>
  <motion-type>crank-rocker</motion-type>

  <physical-connection>
    <chain>motor → camshaft → crank_disc_1 → coupler_rod_1 → wave_layer_1</chain>
    <status>VERIFIED</status>
  </physical-connection>

  <notes>
    s + l = 25 + 80 = 105
    p + q = 60 + 50 = 110
    105 < 110: Grashof condition satisfied
  </notes>
</mechanism>
```

### Agent Behavior
- When modifying mechanism components, recalculate `<grashof-check>`
- Update `<motion-type>` if linkage parameters change
- Warn if changes break Grashof condition
- Verify `<physical-connection>` chain before animation code

---

## 4. `<constraint>` - Physical Constraint Definition

### Purpose
Define physical constraints that must be satisfied for the mechanism to work.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `type` | Yes | clearance, mesh, alignment, envelope, motion, thermal, wear | Constraint category |
| `priority` | No | critical, high, medium, low | Importance level |

### Constraint Types

#### Clearance Constraint
```xml
<constraint type="clearance" priority="critical">
  <between>master_gear</between>
  <and>motor_mount</and>
  <minimum>0.3</minimum>
  <unit>mm</unit>
  <current>0.5</current>
  <status>PASS</status>
</constraint>
```

#### Mesh Constraint
```xml
<constraint type="mesh" priority="critical">
  <gear1 ref="motor_pinion" teeth="12"/>
  <gear2 ref="master_gear" teeth="60"/>
  <module>2.0</module>
  <center-distance formula="(12+60)*2.0/2">72.0</center-distance>
  <backlash>0.15</backlash>
  <status>VERIFIED</status>
</constraint>
```

#### Wear Constraint (NEW)
```xml
<constraint type="wear" priority="medium">
  <surface ref="main_shaft_bearing"/>
  <material-pair>PLA/brass</material-pair>
  <friction-coefficient>0.20</friction-coefficient>
  <expected-life years="10" cycles="10000000"/>
  <lubrication>self-lubricating</lubrication>
  <status>ACCEPTABLE</status>
</constraint>
```

### Agent Behavior
- Check all `priority="critical"` constraints before code generation
- MaterialsExpert reviews `type="wear"` constraints
- Update `<status>` when parameters change

---

## 5. `<vision>` - User Vision Element

### Purpose
Capture the user's creative intent - elements that define the artistic goal.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `category` | Yes | aesthetic, motion, emotion, reference | Vision category |
| `priority` | No | essential, important, nice-to-have | How critical |

### Example
```xml
<vision category="motion" priority="essential">
  The waves should move like Van Gogh painted them - swirling,
  organic, with a sense of turbulent energy but still peaceful.
  Multiple frequencies overlapping, not mechanical repetition.
</vision>

<vision category="aesthetic" priority="essential">
  The sun should dominate the composition, drawing the eye first.
  Stars should twinkle subtly, not compete for attention.
</vision>

<vision category="emotion" priority="important">
  The overall feeling should be contemplative - watching the night
  sky, not anxious or busy. Slow enough to meditate on.
</vision>
```

### Agent Behavior
- **NEVER** dismiss or override vision elements
- When motion conflicts with vision, prioritize vision aesthetics
- Reference vision when making design choices
- MotionDesigner uses vision for emotional quality assessment

---

## 6. `<checkpoint>` - Verification Checkpoint

### Purpose
Define verification points during implementation.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `id` | Yes | string | Checkpoint identifier |
| `type` | Yes | render, animate, measure, physics, polymath | Check type |
| `status` | No | pending, passed, failed | Current state |

### Example
```xml
<checkpoint id="CP-001" type="animate" status="passed">
  <description>Verify wave motion at t=0, 0.25, 0.5, 0.75</description>
  <test-procedure>
    1. Open in OpenSCAD
    2. Set $t = 0.0, verify wave position
    3. Set $t = 0.25, verify wave at peak
    4. Set $t = 0.5, verify wave centered
    5. Set $t = 0.75, verify wave at trough
  </test-procedure>
  <expected>Smooth sinusoidal motion, no jerk at direction changes</expected>
  <actual>Motion smooth, slight hesitation at t=0.5 (acceptable)</actual>
  <verified-by>agent</verified-by>
  <verified-date>2026-01-17</verified-date>
</checkpoint>
```

### Agent Behavior
- Create checkpoints for every major verification
- Update status after testing
- Reference checkpoints when reporting to user

---

## 7. `<migration>` - Version Migration Definition

### Purpose
Track changes between versions for safe upgrades.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `from` | Yes | version number | Source version |
| `to` | Yes | version number | Target version |
| `breaking` | No | true/false | Contains breaking changes |

### Example
```xml
<migration from="54" to="55" breaking="false">
  <changes>
    <change type="add" component="moon_phase_cam"/>
    <change type="modify" component="wave_linkage">
      <param name="coupler_length" old="80" new="85"/>
    </change>
    <change type="preserve" component="frame_dimensions" reason="LOCKED"/>
  </changes>
  <tested-checkpoints>
    <checkpoint ref="CP-001" status="passed"/>
    <checkpoint ref="CP-002" status="passed"/>
  </tested-checkpoints>
</migration>
```

### Agent Behavior
- Create migration for every version change
- Mark `breaking="true"` if changes affect locked items or major structure
- VersionController creates and tracks migrations

---

## 8. `<phase>` - Animation Phase Definition

### Purpose
Define animation phase relationships between elements.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `element` | Yes | string | Element name |
| `type` | No | harmonic, linear, stepped, custom | Motion type |
| `frequency` | No | number | Relative to master |

### Example
```xml
<phase element="sun_rotation" type="harmonic" frequency="1">
  <offset>0</offset>
  <amplitude>360</amplitude>
  <unit>degrees</unit>
  <formula>master_phase * 360</formula>
</phase>

<phase element="wave_oscillation" type="harmonic" frequency="3">
  <offset>45</offset>
  <amplitude>25</amplitude>
  <unit>mm</unit>
  <formula>amplitude * sin(master_phase * 360 * 3 + offset)</formula>
</phase>
```

### Agent Behavior
- MotionDesigner creates and reviews phase definitions
- Verify phase relationships create intended polyrhythm
- Check that all phases have physical drivers

---

## 9. `<z-layer>` - Z-Layer Definition

### Purpose
Define vertical stacking layers for assembly.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `id` | Yes | number | Layer number (bottom=0) |
| `z-min` | Yes | number | Minimum Z height |
| `z-max` | Yes | number | Maximum Z height |
| `name` | No | string | Layer name |

### Example
```xml
<z-layer id="0" z-min="0" z-max="3" name="base_plate">
  <components>
    <component ref="frame_base"/>
    <component ref="motor_mount"/>
  </components>
  <clearance-to-next>0.5</clearance-to-next>
</z-layer>

<z-layer id="1" z-min="3.5" z-max="8" name="gear_layer">
  <components>
    <component ref="master_gear"/>
    <component ref="pinion"/>
  </components>
</z-layer>
```

### Agent Behavior
- Use for z-stack skill calculations
- Verify clearance between layers
- Check for collision between layer components

---

## 10. `<diff>` - Version Difference Marker

### Purpose
Mark specific changes in code for diff tracking.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `type` | Yes | add, remove, modify | Change type |
| `version` | Yes | number | Version introducing change |
| `reason` | No | string | Why changed |

### Example
```xml
// <diff type="modify" version="55" reason="User requested calmer motion">
wave_frequency = 2;  // was: 3
// </diff>

// <diff type="add" version="55" reason="New moon phase feature">
module moon_phase_cam() {
  // ... new code ...
}
// </diff>
```

### Agent Behavior
- VersionController adds diff markers
- Use for generating version summaries
- Preserve markers through migrations

---

# POLYMATH TAGS (NEW)

---

## 11. `<polymath-check>` - Seven Masters Verification

### Purpose
Document Polymath methodology verification for a mechanism or design decision.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `mechanism` | Yes | string | Mechanism being verified |
| `date` | Yes | date | Verification date |
| `overall` | Yes | approved, needs-work, rejected | Final verdict |

### Child Elements
One element per master:
- `<van-gogh status="pass|fail|na">` - Motion aesthetics
- `<da-vinci status="pass|fail|na">` - Friction/materials
- `<tesla status="pass|fail|na">` - Mental simulation
- `<edison status="pass|fail|na">` - Test protocol
- `<watt status="pass|fail|na">` - Efficiency/power
- `<galileo status="pass|fail|na">` - Experimental verification
- `<archimedes status="pass|fail|na">` - First principles

### Example
```xml
<polymath-check mechanism="wave_drive" date="2026-01-17" overall="approved">
  <van-gogh status="pass">
    Turbulent wave motion with 3× frequency polyrhythm.
    Matches Van Gogh painting aesthetic.
  </van-gogh>

  <da-vinci status="pass">
    PLA/brass bearing pairs identified.
    Friction coefficient ~0.2 acceptable.
    No bare PLA-on-PLA sliding surfaces.
  </da-vinci>

  <tesla status="pass">
    Full cycle mentally simulated.
    No collisions at t=0, 0.25, 0.5, 0.75.
    Extreme positions verified.
  </tesla>

  <edison status="pass">
    Test: Animate in OpenSCAD, check 4 positions.
    Success criteria: Smooth motion, no gaps.
  </edison>

  <watt status="pass">
    Power path: Motor → Gear (95%) → Linkage (85%) → Output
    Total efficiency: ~80%. Motor capacity adequate.
  </watt>

  <galileo status="pass">
    Verified in OpenSCAD F5 preview.
    Animation checked at 4 time steps.
  </galileo>

  <archimedes status="pass">
    No physics violations.
    Center of gravity balanced.
    Lever ratios calculated correctly.
  </archimedes>
</polymath-check>
```

### Agent Behavior
- MechanismAnalyst creates polymath-check before code generation
- Require all seven checks for mechanism approval
- Reference in pre-code-generation hook

---

## 12. `<physics-validation>` - Physics Check Result

### Purpose
Document physics calculations and validations.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `type` | Yes | grashof, torque, balance, collision, stress | Check type |
| `status` | Yes | pass, fail, warning | Result |

### Examples

#### Grashof Validation
```xml
<physics-validation type="grashof" status="pass">
  <mechanism ref="wave_linkage"/>
  <links>
    <s name="crank">25</s>
    <l name="coupler">80</l>
    <p name="rocker">50</p>
    <q name="ground">60</q>
  </links>
  <calculation>
    s + l = 25 + 80 = 105
    p + q = 50 + 60 = 110
    105 ≤ 110: TRUE
  </calculation>
  <result>Crank-rocker mechanism (valid)</result>
</physics-validation>
```

#### Torque Chain Validation
```xml
<physics-validation type="torque" status="pass">
  <chain>
    <stage name="motor" torque="0.3" unit="Nm"/>
    <stage name="gear_reduction" ratio="5" efficiency="0.95" torque="1.425"/>
    <stage name="linkage" efficiency="0.85" torque="1.21"/>
    <stage name="output" required="0.8" available="1.21"/>
  </chain>
  <margin>51%</margin>
  <result>Adequate torque margin</result>
</physics-validation>
```

#### Balance Validation
```xml
<physics-validation type="balance" status="warning">
  <mechanism ref="main_assembly"/>
  <center-of-gravity x="45" y="32" z="25"/>
  <base-centroid x="50" y="30" z="0"/>
  <offset x="-5" y="2"/>
  <result>Slight left-forward lean. Consider counterweight.</result>
</physics-validation>
```

### Agent Behavior
- MechanismAnalyst creates physics validations
- Require pass on all critical validations
- MaterialsExpert reviews stress validations

---

## 13. `<failure-pattern>` - Known Failure Reference

### Purpose
Document when a design matches a known failure pattern from FAILURE_PATTERNS.md.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `pattern` | Yes | string | Pattern name from reference |
| `severity` | Yes | critical, warning, info | Risk level |
| `acknowledged` | No | true/false | User aware and accepts |

### Example
```xml
<failure-pattern pattern="Tesla Trap" severity="warning" acknowledged="false">
  <trigger>"Should work in theory" statement about thin-wall gear</trigger>
  <reference>FAILURE_PATTERNS.md - Tesla Trap</reference>
  <description>
    Material limits may prevent theoretical mechanism from working.
    Tesla's mental simulations didn't account for material failures.
  </description>
  <prevention>
    1. Increase wall thickness to 2mm minimum
    2. Prototype before committing
    3. Use PETG instead of PLA for stress parts
  </prevention>
  <user-action-required>Acknowledge risk or implement prevention</user-action-required>
</failure-pattern>
```

### Agent Behavior
- Failure-pattern-detector hook creates these
- Block code generation for unacknowledged critical patterns
- Reference FAILURE_PATTERNS.md for full description

---

# QUALITY TAGS (NEW)

---

## 14. `<quality-assessment>` - Perceived Quality Grade

### Purpose
Document quality assessment per Compendium Domain 14.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `project` | Yes | string | Project name |
| `date` | Yes | date | Assessment date |
| `overall-grade` | Yes | A, B+, B, C, D | Final grade |

### Child Elements
- `<motion-quality grade="A-D">` - 40% of score
- `<visual-quality grade="A-D">` - 30% of score
- `<craftsmanship grade="A-D">` - 20% of score
- `<sound-quality grade="A-D">` - 10% of score
- `<recommendations>` - Improvement suggestions

### Example
```xml
<quality-assessment project="starry_night" date="2026-01-17" overall-grade="B+">
  <motion-quality grade="A">
    Smooth sine-wave motion throughout.
    Good polyrhythm between elements.
    No visible backlash or jerk.
  </motion-quality>

  <visual-quality grade="B">
    Clean edge treatments on most parts.
    Some visible layer lines on sun gear.
    Fasteners appropriately hidden.
  </visual-quality>

  <craftsmanship grade="B+">
    Exposed mechanism adds visual interest.
    Brass bushing accents enhance quality feel.
    Consistent finish across assembly.
  </craftsmanship>

  <sound-quality grade="B">
    Slight gear whine at high speed.
    No unpleasant clicks or clunks.
    Consider felt dampening on frame.
  </sound-quality>

  <recommendations>
    <item priority="high">Sand and paint sun gear to hide layers</item>
    <item priority="medium">Add felt dampening to reduce gear noise</item>
    <item priority="low">Consider brass sleeve on main shaft</item>
  </recommendations>
</quality-assessment>
```

### Agent Behavior
- MaterialsExpert creates quality assessments
- Reference when user asks about "quality" or "professional"
- Use to guide final polish recommendations

---

## 15. `<motion-quality>` - Motion Aesthetics Evaluation

### Purpose
Detailed motion quality analysis per Compendium Domain 5.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `mechanism` | Yes | string | Mechanism name |
| `intended-mood` | Yes | string | Target emotional quality |
| `achieved-mood` | Yes | string | Actual emotional quality |

### Child Elements
- `<smoothness rating="1-5">` - Motion smoothness
- `<timing rating="1-5">` - Rhythm quality
- `<relationships rating="1-5">` - Phase relationships
- `<emotion rating="1-5">` - Emotional impact

### Example
```xml
<motion-quality mechanism="wave_drive" intended-mood="contemplative" achieved-mood="contemplative with energy">
  <smoothness rating="4">
    Minor hesitation at wave peaks.
    Consider easing function adjustment.
  </smoothness>

  <timing rating="5">
    3× frequency polyrhythm works well.
    Good breathing room in cycle.
  </timing>

  <relationships rating="4">
    Phase offsets create good visual flow.
    Could add 15° offset to cypress for more organic feel.
  </relationships>

  <emotion rating="4">
    Captures contemplative quality.
    Slightly more energetic than pure Van Gogh calm.
    Consider slowing master cycle by 20%.
  </emotion>

  <motion-vocabulary>
    <element name="sun" type="continuous" frequency="1" phase="0"/>
    <element name="wave" type="harmonic" frequency="3" phase="45"/>
    <element name="stars" type="stepped" frequency="0.5" phase="varies"/>
    <element name="cypress" type="damped" frequency="0.3" phase="90"/>
  </motion-vocabulary>
</motion-quality>
```

### Agent Behavior
- MotionDesigner creates motion quality assessments
- Reference user's `<vision>` when evaluating emotion
- Provide specific parameter adjustments for improvement

---

## 16. `<longevity>` - Lifespan and Maintenance Spec

### Purpose
Document longevity engineering per Compendium Domain 10.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `project` | Yes | string | Project name |
| `environment` | Yes | indoor, outdoor, mixed | Operating environment |
| `target-years` | Yes | number | Design lifespan goal |
| `estimated-years` | Yes | number | Predicted actual lifespan |

### Child Elements
- `<wear-surfaces>` - List of wear points
- `<lubrication-schedule>` - Maintenance intervals
- `<replaceable-parts>` - Parts designed for replacement
- `<environmental-factors>` - UV, temperature, humidity considerations

### Example
```xml
<longevity project="starry_night" environment="indoor" target-years="10" estimated-years="12">
  <wear-surfaces>
    <surface component="main_shaft" material-pair="PLA/brass"
             friction="0.2" life-cycles="10M" status="good"/>
    <surface component="gear_mesh" material-pair="PETG/PETG"
             friction="0.25" life-cycles="5M" status="monitor"/>
    <surface component="cam_follower" material-pair="PLA/steel"
             friction="0.15" life-cycles="15M" status="excellent"/>
  </wear-surfaces>

  <lubrication-schedule>
    <item component="main_shaft" lubricant="PTFE spray" interval-months="6"/>
    <item component="gear_mesh" lubricant="light machine oil" interval-months="12"/>
    <item component="cam" lubricant="none (self-lubricating)" interval-months="0"/>
  </lubrication-schedule>

  <replaceable-parts>
    <part name="cam_follower_tip" reason="high wear surface"/>
    <part name="drive_belt" reason="fatigue after 5 years"/>
  </replaceable-parts>

  <environmental-factors>
    <factor type="UV">Indoor use, minimal UV exposure - OK</factor>
    <factor type="temperature">Room temperature stable - OK</factor>
    <factor type="humidity">Normal indoor humidity - OK for PLA</factor>
    <factor type="dust">Open mechanism - annual cleaning recommended</factor>
  </environmental-factors>

  <maintenance-notes>
    Annual: Visual inspection, clean dust, check gear mesh
    Every 6 months: Lubricate main shaft
    Every 12 months: Lubricate gear teeth
    At 5 years: Replace drive belt, inspect cam follower
  </maintenance-notes>
</longevity>
```

### Agent Behavior
- MaterialsExpert creates longevity specifications
- Reference when user asks about "will this last" or "maintenance"
- Include in final delivery documentation

---

# SUB-AGENT TAGS (NEW)

---

## 17. `<agent-handoff>` - Inter-Agent Communication

### Purpose
Structured communication between sub-agents.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `from` | Yes | string | Sending agent |
| `to` | Yes | string | Receiving agent |
| `priority` | No | high, medium, low | Urgency |

### Child Elements
- `<context>` - What was analyzed/created
- `<request>` - What receiving agent should do
- `<dependencies>` - Information needed

### Example
```xml
<agent-handoff from="MechanismAnalyst" to="OpenSCADArchitect" priority="high">
  <context>
    Analyzed new wave mechanism.
    Physics validated, Polymath check passed.
  </context>

  <request>
    Generate parametric OpenSCAD code for this mechanism.
    Include animation with proper phase relationships.
  </request>

  <dependencies>
    <param name="coupler_length">85</param>
    <param name="crank_radius">25</param>
    <param name="ground_length">60</param>
    <param name="rocker_length">50</param>
    <param name="phase_offset">45</param>
    <constraint type="clearance" min="0.4"/>
    <grashof status="PASS"/>
  </dependencies>
</agent-handoff>
```

### Agent Behavior
- Sub-agents create handoffs when transferring work
- Receiving agent acknowledges handoff
- VersionController tracks handoffs for audit

---

## 18. `<analysis-report>` - Sub-Agent Output

### Purpose
Structured output from sub-agent analysis.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `agent` | Yes | string | Producing agent |
| `type` | Yes | string | Report type |
| `date` | Yes | date | Analysis date |
| `verdict` | Yes | string | Overall conclusion |

### Example
```xml
<analysis-report agent="MechanismAnalyst" type="feasibility" date="2026-01-17" verdict="APPROVED">
  <summary>
    Wave drive mechanism validated for production.
    All Polymath checks passed.
    Ready for code generation.
  </summary>

  <details>
    <section name="geometry">
      All parts have positive volume.
      Clearances verified at 0.4mm.
      Assembly sequence documented.
    </section>

    <section name="kinematics">
      Grashof condition satisfied.
      Transmission angle min 42° (acceptable).
      No dead points in operating range.
    </section>

    <section name="dynamics">
      Torque chain verified.
      Power margin 51%.
      No binding points identified.
    </section>
  </details>

  <recommendations>
    <item>Consider brass bushing for main shaft</item>
    <item>Add fillet to coupler rod pivot</item>
  </recommendations>

  <next-steps>
    1. OpenSCADArchitect: Generate code
    2. MotionDesigner: Verify timing
    3. MaterialsExpert: Review materials
  </next-steps>
</analysis-report>
```

### Agent Behavior
- Each sub-agent produces structured reports
- Reports feed into version documentation
- User can request specific report types

---

## 19. `<compendium-ref>` - Compendium Reference

### Purpose
Reference specific sections of KINETIC_SCULPTURE_COMPENDIUM.md.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `domain` | Yes | 1-14 | Compendium domain number |
| `section` | No | string | Specific section |
| `qrc` | No | 1-5 | Quick Reference Card number |

### Example
```xml
<compendium-ref domain="2" section="Four-Bar Linkages" qrc="2">
  <relevance>User designing four-bar linkage</relevance>
  <key-formula>
    Grashof: S + L ≤ P + Q
    Transmission angle: keep > 40°
  </key-formula>
  <rules-of-thumb>
    - Coupler length affects output motion shape
    - Shorter input crank = smaller output range
    - Ground link position determines mechanism type
  </rules-of-thumb>
  <common-mistakes>
    - Animating without verifying physical connection
    - Ignoring dead points in motion range
    - Undersized pivot pins for torque
  </common-mistakes>
</compendium-ref>
```

### Agent Behavior
- Compendium-reference hook creates these
- Provide relevant expertise during design
- Link to full Compendium for deep dives

---

# USAGE PATTERNS

## Pattern 1: New Mechanism Design

```xml
<!-- User vision -->
<vision category="motion" priority="essential">
  I want the waves to look like Van Gogh painted them.
</vision>

<!-- Polymath verification -->
<polymath-check mechanism="wave_drive" date="2026-01-17" overall="approved">
  ...all seven checks...
</polymath-check>

<!-- Physics validation -->
<physics-validation type="grashof" status="pass">
  ...calculation...
</physics-validation>

<!-- Mechanism definition -->
<mechanism name="wave_drive" type="four-bar" version="1">
  ...components and parameters...
</mechanism>

<!-- Agent handoff -->
<agent-handoff from="MechanismAnalyst" to="OpenSCADArchitect">
  ...generate code...
</agent-handoff>
```

## Pattern 2: Version Delivery

```xml
<!-- Version info -->
<migration from="54" to="55" breaking="false">
  ...changes...
</migration>

<!-- Checkpoints -->
<checkpoint id="CP-001" type="animate" status="passed">
  ...test results...
</checkpoint>

<!-- Quality assessment -->
<quality-assessment project="starry_night" overall-grade="B+">
  ...ratings...
</quality-assessment>

<!-- Longevity spec -->
<longevity environment="indoor" target-years="10">
  ...maintenance schedule...
</longevity>
```

## Pattern 3: Problem Resolution

```xml
<!-- Failure pattern detected -->
<failure-pattern pattern="V53 Disconnect" severity="critical">
  Animation without physical connection detected.
</failure-pattern>

<!-- Physics validation failed -->
<physics-validation type="collision" status="fail">
  Components overlap at t=0.73
</physics-validation>

<!-- Agent report -->
<analysis-report agent="MechanismAnalyst" verdict="NEEDS_WORK">
  ...issues and recommendations...
</analysis-report>
```

---

# AGENT BEHAVIOR RULES

## Priority Order

1. **LOCKED** content - Never modify without explicit override
2. **VISION** elements - Preserve user intent at all costs
3. **POLYMATH** checks - Required for mechanism approval
4. **PHYSICS** validations - Block on critical failures
5. **QUALITY** assessments - Guide recommendations

## Tag Interaction Rules

| Tag | Creates | References | Blocks On |
|-----|---------|------------|-----------|
| `<locked>` | - | All others | Any modification |
| `<vision>` | - | motion-quality | Never (preserve) |
| `<polymath-check>` | mechanism | failure-pattern | Any check fail |
| `<physics-validation>` | mechanism | constraint | Status=fail |
| `<constraint>` | component | physics-validation | Priority=critical, status=fail |
| `<quality-assessment>` | longevity | motion-quality | Never (advisory) |
| `<agent-handoff>` | analysis-report | All | Missing dependencies |

## Required Tags Per Workflow

### New Mechanism
- `<polymath-check>` - Required
- `<physics-validation type="grashof">` - Required for linkages
- `<mechanism>` - Required
- `<phase>` - Required for animated elements

### Version Delivery
- `<migration>` - Required
- `<checkpoint>` - At least one
- `<component>` survival check

### Final Delivery
- `<quality-assessment>` - Required
- `<longevity>` - Required
- All `<locked>` items verified

---

# TAG PRIORITY MATRIX

| Tag Type | Pre-Code | Post-Version | Final Delivery |
|----------|----------|--------------|----------------|
| `<locked>` | CHECK | VERIFY | PRESERVE |
| `<polymath-check>` | REQUIRED | - | REFERENCE |
| `<physics-validation>` | REQUIRED | - | REFERENCE |
| `<mechanism>` | CREATE | UPDATE | LOCK |
| `<constraint>` | CHECK | VERIFY | DOCUMENT |
| `<checkpoint>` | - | CREATE | VERIFY ALL |
| `<quality-assessment>` | - | - | CREATE |
| `<longevity>` | - | - | CREATE |
| `<migration>` | - | CREATE | ARCHIVE |
| `<vision>` | REFERENCE | PRESERVE | PRESERVE |

---

*XML Tags Reference v2.0*
*Structured Communication for Kinetic Sculpture Excellence*
*Integration: POLYMATH_LENS.md, KINETIC_SCULPTURE_COMPENDIUM.md, STATE_MACHINES.md*
