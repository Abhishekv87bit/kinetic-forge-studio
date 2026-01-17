# XML TAGS REFERENCE
## Custom Prompt Tags for 3D Mechanical Design

---

> **These XML tags provide structured input/output formatting for Claude interactions in the 3D Mechanical Design workspace.**

---

## PURPOSE

Custom XML tags enable:
- Clear delineation of component definitions
- Protected/locked sections that must not be modified
- Constraint specifications with validation status
- Vision element preservation (user's creative intent)
- Migration tracking between versions
- Checkpoint verification during implementation

---

## TABLE OF CONTENTS

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
11. [Usage Patterns](#usage-patterns)
12. [Agent Behavior Rules](#agent-behavior-rules)

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
- `<notes>` - Design notes

### Example
```xml
<component name="master_gear" type="gear" status="locked">
  <param name="teeth">60</param>
  <param name="module">1.0</param>
  <param name="thickness">4.0</param>
  <param name="bore_diameter">8.0</param>
  <position x="70" y="30" z="8"/>
  <meshes-with>motor_pinion</meshes-with>
  <meshes-with>sky_drive_gear</meshes-with>
  <notes>Main power distribution gear - DO NOT MODIFY</notes>
</component>
```

### Agent Behavior
- When modifying a component, first check its `status`
- If `status="locked"`, refuse modification without explicit user override
- Always update `<meshes-with>` relationships when gear positions change

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

### Example
```xml
<mechanism name="wave_drive" type="four-bar" version="3">
  <component ref="camshaft"/>
  <component ref="crank_disc_1"/>
  <component ref="coupler_rod_1"/>
  <component ref="wave_layer_1"/>

  <parameter name="crank_length">10</parameter>
  <parameter name="coupler_length">30</parameter>
  <parameter name="ground_length">25</parameter>
  <parameter name="rocker_length">25</parameter>

  <grashof-check>PASS</grashof-check>
  <motion-type>crank-rocker</motion-type>

  <notes>
    s + l = 10 + 30 = 40
    p + q = 25 + 25 = 50
    40 < 50: Grashof condition satisfied
  </notes>
</mechanism>
```

### Agent Behavior
- When modifying mechanism components, recalculate `<grashof-check>`
- Update `<motion-type>` if linkage parameters change
- Warn if changes break Grashof condition

---

## 4. `<constraint>` - Physical Constraint Definition

### Purpose
Define physical constraints that must be satisfied for the mechanism to work.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `type` | Yes | clearance, mesh, alignment, envelope, motion, thermal | Constraint category |
| `priority` | No | critical, high, medium, low | Importance level |

### Constraint Types

#### Clearance Constraint
```xml
<constraint type="clearance" priority="critical">
  <between>master_gear</between>
  <and>motor_mount</and>
  <minimum>2.0</minimum>
  <unit>mm</unit>
  <current>3.5</current>
  <status>PASS</status>
</constraint>
```

#### Mesh Constraint
```xml
<constraint type="mesh" priority="critical">
  <gear1 ref="motor_pinion" teeth="10"/>
  <gear2 ref="master_gear" teeth="60"/>
  <module>1.0</module>
  <center-distance formula="(10+60)*1.0/2">35.0</center-distance>
  <backlash>0.1</backlash>
  <status>VERIFIED</status>
</constraint>
```

#### Envelope Constraint
```xml
<constraint type="envelope" priority="high">
  <component>mechanism_assembly</component>
  <max-x>302</max-x>
  <max-y>250</max-y>
  <max-z>92</max-z>
  <current-x>298</current-x>
  <current-y>245</current-y>
  <current-z>88</current-z>
  <status>WITHIN_BOUNDS</status>
</constraint>
```

#### Motion Constraint
```xml
<constraint type="motion" priority="high">
  <component>wave_layer_1</component>
  <axis>rotation</axis>
  <min-angle>-15</min-angle>
  <max-angle>15</max-angle>
  <current-range>-12 to 12</current-range>
  <status>PASS</status>
</constraint>
```

### Agent Behavior
- Always check constraints before delivering changes
- Update `<status>` when relevant parameters change
- If any `priority="critical"` constraint fails, block delivery

---

## 5. `<vision>` - User Vision Element

### Purpose
Capture user's creative vision that may differ from reference material or defaults.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `element` | Yes | string | Which design element |
| `source` | No | user, reference, hybrid | Origin of vision |
| `priority` | No | must-have, nice-to-have | Importance |

### Example
```xml
<vision element="moon_speed" source="user" priority="must-have">
  <reference>Standard rotation speed (1x)</reference>
  <user-wants>VERY SLOW (0.1x base speed)</user-wants>
  <implementation>
    moon_phase_rot = $t * 360 * 0.1;
  </implementation>
  <rationale>Creates ethereal, dreamlike quality matching Van Gogh's original intent</rationale>
</vision>

<vision element="gear_style" source="user" priority="must-have">
  <reference>Decorative, belt-driven system</reference>
  <user-wants>Clock-style, direct mesh, NO BELTS</user-wants>
  <implementation>All gears mesh tooth-to-tooth</implementation>
  <rationale>Functional clockwork aesthetic, visible mechanics</rationale>
</vision>

<vision element="cliff_scale" source="hybrid" priority="must-have">
  <reference>Standard scale (1.0)</reference>
  <user-wants>+20% larger (1.2 scale)</user-wants>
  <implementation>cliff_scale = 1.2;</implementation>
  <rationale>More prominent foreground presence</rationale>
</vision>
```

### Agent Behavior
- **NEVER** override vision elements without explicit user permission
- Vision elements persist across versions
- When in doubt about user intent, check vision elements first
- Create new vision entries when user expresses preferences

---

## 6. `<checkpoint>` - Verification Checkpoint

### Purpose
Define verification points during implementation that must pass before proceeding.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `id` | Yes | string | Unique checkpoint ID |
| `type` | Yes | component-survival, version-diff, z-stack, grashof, render, custom | Check type |
| `status` | Yes | pending, pass, fail, skip | Current status |

### Example
```xml
<checkpoint id="v47-post-gear-change" type="component-survival" status="pass">
  <triggered-by>Modified master_gear teeth count</triggered-by>
  <verified>
    <item status="pass">Motor pinion present (10T)</item>
    <item status="pass">Master gear present (60T)</item>
    <item status="pass">Center distance = 35mm (correct)</item>
    <item status="pass">All 6 idler gears present</item>
    <item status="pass">Wave mechanism components intact</item>
  </verified>
  <timestamp>2026-01-16T14:30:00</timestamp>
  <notes>All components survived gear parameter change</notes>
</checkpoint>

<checkpoint id="v47-animation-test" type="render" status="pending">
  <triggered-by>Post-modification verification</triggered-by>
  <tests>
    <test t="0.00" status="pending">Initial position</test>
    <test t="0.25" status="pending">Quarter cycle</test>
    <test t="0.50" status="pending">Half cycle</test>
    <test t="0.75" status="pending">Three-quarter cycle</test>
    <test t="1.00" status="pending">Full cycle</test>
  </tests>
</checkpoint>
```

### Agent Behavior
- Run checkpoints after significant changes
- Do not proceed past failed checkpoints
- Document checkpoint results for version history

---

## 7. `<migration>` - Version Migration Definition

### Purpose
Define upgrade/migration procedures between versions.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `from` | Yes | version string | Source version |
| `to` | Yes | version string | Target version |
| `type` | No | breaking, non-breaking, schema | Migration type |

### Example
```xml
<migration from="v46" to="v47" type="breaking">
  <summary>Converted wave drive from oscillation to four-bar linkage</summary>

  <changes>
    <change type="remove">
      <what>wave_oscillate module</what>
      <reason>Replaced with four-bar mechanism</reason>
    </change>
    <change type="add">
      <what>Four-bar linkage components</what>
      <components>camshaft, crank_disc_1, crank_disc_2, coupler_rod_1, coupler_rod_2</components>
    </change>
    <change type="modify">
      <what>wave_layer_1 pivot point</what>
      <before>pivot_x = 100</before>
      <after>pivot_x = 108</after>
      <reason>Moved to cliff edge for four-bar attachment</reason>
    </change>
  </changes>

  <migration-steps>
    <step order="1">Backup v46 assembly</step>
    <step order="2">Remove old wave_oscillate module</step>
    <step order="3">Add camshaft and crank discs</step>
    <step order="4">Add coupler rods</step>
    <step order="5">Update wave layer pivot points</step>
    <step order="6">Run /component-survival</step>
    <step order="7">Test animation at t=0, 0.25, 0.5, 0.75, 1.0</step>
  </migration-steps>

  <rollback-path>Restore from v46 backup in versions/ folder</rollback-path>

  <verification>
    <checkpoint ref="v47-post-gear-change"/>
    <checkpoint ref="v47-animation-test"/>
  </verification>
</migration>
```

### Agent Behavior
- Document all breaking changes in migration tags
- Always include rollback path
- Reference checkpoints for verification

---

## 8. `<phase>` - Animation Phase Definition

### Purpose
Define animation timing phases for coordinated motion.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `name` | Yes | string | Phase identifier |
| `t-start` | Yes | 0.0-1.0 | Starting $t value |
| `t-end` | Yes | 0.0-1.0 | Ending $t value |

### Example
```xml
<phase name="bird_flight" t-start="0.10" t-end="0.25">
  <description>Birds fly across canvas from left to right</description>

  <elements>
    <element ref="bird_carrier">Moves X position</element>
    <element ref="bird_1_wings">Wing flap animation</element>
    <element ref="bird_2_wings">Wing flap animation</element>
    <element ref="bird_3_wings">Wing flap animation</element>
  </elements>

  <motion>
    <formula name="carrier_x">
      lerp(5, 297, ($t - 0.10) / 0.15)
    </formula>
    <formula name="wing_angle">
      25 * sin($t * 360 * 8)
    </formula>
  </motion>

  <notes>
    Phase duration: 0.15 (15% of cycle)
    Birds enter at t=0.10, exit at t=0.25
    8 wing flaps during crossing
  </notes>
</phase>

<phase name="star_twinkle" t-start="0.00" t-end="1.00">
  <description>Stars twinkle continuously throughout animation</description>

  <elements>
    <element ref="star_1">Primary twinkle</element>
    <element ref="star_2">Offset twinkle</element>
    <element ref="star_3">Counter-phase twinkle</element>
  </elements>

  <motion>
    <formula name="twinkle_scale">
      0.8 + 0.2 * sin($t * 360 * 3)
    </formula>
  </motion>
</phase>
```

### Agent Behavior
- Check for phase overlaps that might cause conflicts
- Ensure phase timing is mathematically consistent
- Document element involvement in each phase

---

## 9. `<z-layer>` - Z-Layer Definition

### Purpose
Define Z-axis layer allocations for collision avoidance and assembly order.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `id` | Yes | string | Layer identifier |
| `z-min` | Yes | number | Minimum Z value |
| `z-max` | Yes | number | Maximum Z value |

### Example
```xml
<z-layer id="base_frame" z-min="0" z-max="3">
  <components>
    <component>frame_bottom</component>
    <component>motor_mount</component>
  </components>
  <clearance-above>motor_pinion (Z=3-8)</clearance-above>
</z-layer>

<z-layer id="gear_train" z-min="8" z-max="28">
  <components>
    <component>motor_pinion</component>
    <component>master_gear</component>
    <component>sky_drive_gear</component>
    <component>wave_drive_gear</component>
    <component>idler_1</component>
    <component>idler_2</component>
    <component>idler_3</component>
    <component>idler_4</component>
    <component>idler_5</component>
    <component>idler_6</component>
  </components>
  <clearance-below>motor_mount (Z=0-3)</clearance-below>
  <clearance-above>swirl_inner (Z=25+)</clearance-above>
</z-layer>

<z-layer id="canvas_elements" z-min="25" z-max="45">
  <components>
    <component>sky_layer</component>
    <component>swirl_inner</component>
    <component>swirl_outer</component>
    <component>ocean_layer</component>
  </components>
  <clearance-below>gear_train (Z=8-28)</clearance-below>
</z-layer>
```

### Z-Stack Diagram
```
Z (mm)
  ^
45|  +-----------------+
  |  | Canvas Elements |
  |  +-----------------+
28|  +-----------------+
  |  |   Gear Train    |
  |  +-----------------+
 8|  +-----------------+
  |  |   Base Frame    |
  |  +-----------------+
 0+-----------------------> Components
```

### Agent Behavior
- Before Z modifications, check layer boundaries
- Verify clearances between adjacent layers (min 2mm)
- Run /z-stack skill after Z changes

---

## 10. `<diff>` - Version Difference Marker

### Purpose
Mark changes between versions for documentation and rollback.

### Attributes
| Attribute | Required | Values | Description |
|-----------|----------|--------|-------------|
| `version` | Yes | string | Version where change occurred |
| `type` | Yes | add, remove, modify | Type of change |

### Example
```xml
<diff version="v47" type="add">
  // NEW: Four-bar wave mechanism
  module wave_four_bar() {
    // Crank disc at camshaft
    translate([crank_x, crank_y, crank_z])
      crank_disc();

    // Coupler rod
    translate([coupler_x, coupler_y, coupler_z])
      coupler_rod();
  }
</diff>

<diff version="v47" type="remove">
  // REMOVED: Old oscillation module
  // Was: module wave_oscillate() { ... }
  // Reason: Replaced with four-bar linkage
</diff>

<diff version="v47" type="modify">
  // CHANGED: Wave layer pivot point
  // Before: wave_pivot_x = 100;
  // After:
  wave_pivot_x = 108;  // Moved to cliff edge for four-bar attachment
</diff>
```

### Agent Behavior
- Create diff entries for all changes
- Include before/after values for modifications
- Document reason for removals

---

## USAGE PATTERNS

### Pattern 1: Component Definition Block
```xml
<component name="example_gear" type="gear">
  <param name="teeth">24</param>
  <param name="module">1.0</param>

  <locked since="2026-01-16" reason="Final design approved">
    <param name="thickness">4.0</param>
  </locked>

  <constraint type="mesh" priority="critical">
    <with ref="partner_gear"/>
  </constraint>

  <position x="50" y="30" z="12"/>
</component>
```

### Pattern 2: Vision-Constrained Mechanism
```xml
<mechanism name="moon_phase" type="gear-train">
  <vision element="speed" source="user" priority="must-have">
    <user-wants>VERY SLOW (0.1x)</user-wants>
  </vision>

  <component ref="moon_gear"/>
  <component ref="phase_disc"/>

  <constraint type="motion">
    <speed-ratio>0.1</speed-ratio>
  </constraint>
</mechanism>
```

### Pattern 3: Migration with Checkpoints
```xml
<migration from="v49" to="v50" type="breaking">
  <checkpoint id="pre-migration" type="component-survival" status="pass"/>

  <changes>
    <change type="modify">...</change>
  </changes>

  <checkpoint id="post-migration" type="component-survival" status="pending"/>
</migration>
```

### Pattern 4: Phase Coordination
```xml
<phase name="wave_cycle" t-start="0.0" t-end="1.0">
  <z-layer ref="ocean_layer"/>
  <z-layer ref="wave_foam"/>

  <constraint type="clearance" priority="critical">
    <between>wave_layer_1</between>
    <and>cliff_edge</and>
    <minimum>0.5</minimum>
  </constraint>
</phase>
```

---

## AGENT BEHAVIOR RULES

### Rule 1: Respect Locks
```
IF content is inside <locked> tags:
  THEN refuse modification without explicit user override
  AND warn user before any operation affecting locked content
```

### Rule 2: Preserve Vision
```
IF modification would override <vision> elements:
  THEN ask user for confirmation
  AND document that vision was intentionally changed
```

### Rule 3: Validate Constraints
```
AFTER any modification:
  CHECK all related <constraint> elements
  UPDATE status fields
  IF any critical constraint fails:
    THEN block delivery and report
```

### Rule 4: Verify Checkpoints
```
WHEN <checkpoint> is defined:
  RUN verification at specified point
  UPDATE status (pending -> pass/fail)
  IF fail: STOP and report
```

### Rule 5: Document Changes
```
FOR every modification:
  CREATE appropriate <diff> entry
  INCLUDE before/after values
  DOCUMENT reason for change
```

### Rule 6: Layer Awareness
```
BEFORE any Z-axis modification:
  CHECK <z-layer> definitions
  VERIFY clearances between layers
  RUN /z-stack if boundaries affected
```

---

*Document Version: 1.0*
*Purpose: Structured markup for 3D mechanical design workflows*
*Related Documents: POLYMATH_LENS.md, STATE_MACHINES.md, hooks.md, skills.md*
