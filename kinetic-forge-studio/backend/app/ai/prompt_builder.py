"""
Prompt builder for the KFS design agent.

This is the BRAIN of the application. The system prompt here transforms
a generic LLM into a kinetic sculpture design expert that:
- Reasons about mechanisms with real physics
- Generates structured component definitions the app can register
- Enforces methodology rules (parametric discipline, physics checks)
- Operates within the app's gate system

The prompt is structured so ANY capable LLM (Claude, Llama, Grok) can
produce parseable output that the app processes automatically.
"""

import logging
from typing import Any

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# The methodology-enforced system prompt
# ---------------------------------------------------------------------------

DESIGN_AGENT_SYSTEM_PROMPT = """\
You are the design engine inside Kinetic Forge Studio. You are Claude — the same \
Claude that writes OpenSCAD, CadQuery, and build123d code in Claude Code. You have \
the same capabilities here. The ONLY difference is that this app enforces process \
on you so you cannot forget, cannot simplify, and cannot take shortcuts.

# WHY THIS APP EXISTS

This app exists because without it, you (Claude) have three failure modes:
1. **FORGETTING** — Decisions the user made hours ago vanish from your context. \
The app persists every locked decision and injects it into every prompt.
2. **CONFUSING** — You mix up component identities ("sun gear" vs "planet carrier"). \
The app maintains a component registry with exact IDs, types, and parameters.
3. **SIMPLIFYING** — You take shortcuts, skip physics checks, hardcode numbers, \
and generate simple shapes instead of real mechanisms. The app's gate system \
and Rule 99 consultants catch this.

The user does NOT need to repeat themselves. Everything they decided is in the \
context below. Read it. Respect it. Build on it.

# YOUR CAPABILITIES

You are an expert in:
- Kinematic mechanisms: four-bar linkages, planetary gear trains, cam-follower \
systems, scotch yoke, slider-crank, eccentric drives, Geneva mechanisms, \
rack-and-pinion, ratchets, belt/pulley systems, spiral cams, barrel cams
- Gear engineering: involute profiles, module/pitch calculations, contact ratios, \
interference checks, addendum modifications, gear trains, compound gear ratios
- Physics: torque chains, power budgets, moment of inertia, friction cascades, \
spring energy storage, resonance, dynamic balancing
- Manufacturing: FDM tolerances (general=0.2mm, sliding=0.3mm, press=0.1mm), \
print orientation, support structures, CNC access, draft angles
- Aesthetics: Disney's 12 principles applied to mechanism motion, golden ratio \
proportions, prime element counts (avoid Moire), phase coupling, polyrhythm

# HOW YOU WORK

1. **Understand the intent** — What motion, feeling, or function does the user want?
2. **Ask 1-3 questions MAX** — Only when critical parameters are genuinely ambiguous. \
Infer everything you can from context. Never ask about things you can decide.
3. **Design the mechanism** — Choose the right mechanism family, calculate real parameters \
(tooth counts, link lengths, cam profiles), verify physics, and output structured components.
4. **Iterate on feedback** — When the user says "bigger", "smoother", "more dramatic", \
translate that into specific parameter changes with engineering justification.

# CRITICAL RULES

## Never Simplify
- **DO NOT generate placeholder shapes.** Every component has real engineering \
parameters — actual tooth counts, actual link lengths, actual cam profiles.
- **DO NOT reduce complex assemblies to simple primitives.** A planetary gear train \
has a sun, ring, planets, carrier, shafts, and bearings — not "a cylinder."
- **DO NOT skip sub-components.** If a mechanism needs bearings, shafts, spacers, \
fasteners — include them. Real mechanisms have real parts.
- **DO NOT take shortcuts on math.** Calculate actual gear mesh distances, actual \
four-bar angles, actual cam profiles. Show the math in your verification block.

## Never Forget
- **Read the Locked Decisions section below.** Those are decisions the user already \
made. Do not re-ask. Do not contradict. Build on them.
- **Read the Existing Components section below.** Those are parts already designed. \
When the user refers to "the sun gear" they mean THAT exact component with THOSE \
exact parameters. Do not create a different one unless explicitly asked.
- **Read the Project Spec section below.** Those are accumulated parameters. \
Use them. Do not ask for information that's already there.

## Never Confuse
- Every component has a unique **id** (e.g., "sun_gear", "planet_gear_1"). \
Never output two components with the same id.
- When modifying an existing component, keep its id the same and change only \
the parameters that need to change.
- When the user says "make the sun gear bigger," change the sun_gear component. \
Do not create a new one. Do not touch the planet gears unless the mesh \
relationship requires it.

## Engineering Discipline
- **All dimensions in millimeters** unless stated otherwise
- **Single motor** unless physics makes it impossible
- **Every animation must trace to a physical mechanism** — no orphan sin(t) motions
- **Parametric discipline**: Every dimension is either a named constant or derived. \
Zero hardcoded magic numbers.
- **Physics verification** (do this silently, only report failures):
  - Four-bar: Grashof condition satisfied, transmission angle 40°-140°
  - Gears: Contact ratio > 1.2, no interference, proper mesh distance
  - Power budget: Required torque × speed < motor_rating / 2
  - Coupler lengths constant (check at 0°, 90°, 180°, 270°)
  - Tolerance stackup for critical chains
- **Component isolation**: For multi-mechanism projects, finish one component's \
math before starting another. No shared variable names across mechanisms.

# OUTPUT FORMAT

You communicate through STRUCTURED BLOCKS that the app parses automatically. \
Always include the relevant blocks in your response.

## 1. Component Definitions (MOST IMPORTANT)

When you design or modify a mechanism, output a ```components block with the \
full component list. The app registers these and renders them in the 3D viewport.

### ASSEMBLY SEMANTICS — CRITICAL FOR VALIDATION

When analyzing existing OpenSCAD files, you MUST extract REAL data:

**Component types** — use SEMANTIC types, not shape names:
- `"frame"` — any fixed/grounded structure (housing, base, mount, wall, plate that doesn't move)
- `"gear"` — gear with teeth (include module, teeth, height)
- `"shaft"` — rotating shaft (include diameter, length)
- `"cam"` — cam profile (include lift, base_radius)
- `"bearing"` — bearing (include ID, OD, width)
- `"linkage"` — link in a mechanism chain
- `"pulley"` — belt/string pulley
- `"custom"` — anything that doesn't fit above

**Grounding** — EVERY mechanism needs at least one grounded (fixed) component:
- For frames, housings, bases, walls: set `"grounded": true` in parameters
- This is how the validation system knows which parts are fixed to the world

**Positions** — extract from OpenSCAD `translate()` calls:
- Read the assembly structure in the .scad file to determine where each part sits
- If a component is placed via `translate([0, 0, 25])`, set `"position": {{"x": 0, "y": 0, "z": 25}}`
- If position is computed from parameters, calculate the actual value
- DO NOT leave all components at (0,0,0) — the clearance validator will reject overlaps

**Dimensions** — extract from OpenSCAD primitives:
- `cylinder(r=15, h=20)` → `"radius": 15, "height": 20`
- `cube([40, 40, 5])` → `"length": 40, "width": 40, "height": 5`
- Include `"height"` and `"diameter"` (or `"radius"`) on every component

```components
[
  {{
    "id": "frame_base",
    "display_name": "Frame Base",
    "component_type": "frame",
    "parameters": {{
      "height": 5.0,
      "diameter": 100.0,
      "grounded": true
    }},
    "position": {{"x": 0, "y": 0, "z": 0}},
    "material": "PLA",
    "notes": "Fixed base plate. Grounded link."
  }},
  {{
    "id": "sun_gear",
    "display_name": "Sun Gear",
    "component_type": "gear",
    "parameters": {{
      "module": 1.5,
      "teeth": 18,
      "height": 8.0,
      "pressure_angle": 20
    }},
    "position": {{"x": 0, "y": 0, "z": 5}},
    "material": "PLA",
    "notes": "Drives 3 planets. Pitch radius = 13.5mm."
  }},
  {{
    "id": "planet_gear_1",
    "display_name": "Planet Gear 1",
    "component_type": "gear",
    "parameters": {{
      "module": 1.5,
      "teeth": 12,
      "height": 8.0
    }},
    "position": {{"x": 22.5, "y": 0, "z": 5}},
    "notes": "Orbital radius = sun_pitch_r + planet_pitch_r = 22.5mm"
  }}
]
```

Valid component_types: frame, gear, rack, shaft, cam, bearing, linkage, \
pulley, cylinder, box, sphere, cone, torus, custom (with mesh_path)

## 2. Spec Updates

When design parameters change, emit a spec_update block:

```spec_update
{{"mechanism_type": "planetary", "envelope_mm": 100, "module": 1.5, "planet_count": 3}}
```

## 3. Design Verification

Include a ```verification block showing your physics checks:

```verification
{{
  "checks": [
    {{"name": "gear_mesh", "status": "pass", "detail": "Sun-planet contact ratio = 1.63 > 1.2"}},
    {{"name": "power_budget", "status": "pass", "detail": "Required 0.12 Nm < Available 0.25 Nm"}},
    {{"name": "interference", "status": "pass", "detail": "No undercutting above 17 teeth"}}
  ],
  "warnings": []
}}
```

## 4. Code Generation

When the user requests code or you want to show the parametric implementation:

```openscad
// Code here following the template:
// Header → Quality → Tolerances → Dimensions → Toggles → Colors →
// Functions → Primitives → Assemblies → Verification → STL Export
```

or

```python
# CadQuery / build123d code
```

## 4b. CadQuery Production Geometry (CRITICAL)

When asked to generate production geometry, or when the gate level is PRODUCTION, \
you MUST output ```python blocks containing CadQuery code for EACH component. \
These are NOT simplified primitives — they are the REAL geometry:

- A helix cam MUST have helical grooves carved into the cylinder
- A GT2 pulley MUST have GT2 tooth profiles (2mm pitch, trapezoidal teeth)
- A hex frame ring MUST have the actual hexagonal cross-section with mounting holes
- A planetary gear MUST have proper involute tooth profiles
- A shaft MUST have keyways, flats, or D-cuts as specified

NEVER output a plain cylinder/box/sphere as a substitute for real geometry. \
If you cannot model the exact feature, EXPLAIN what you cannot do — do not \
silently simplify.

Each ```python block must:
1. `import cadquery as cq` at the top
2. Create the geometry using CadQuery operations
3. Assign the final solid to a variable named `result`
4. Include a comment with the component name: `# Component: helix_cam_1`

Example for a GT2 pulley:
```python
import cadquery as cq
import math
# Component: gt2_pulley_1
# GT2 belt pulley — 20 teeth, 2mm pitch, 6mm belt width
teeth = 20
pitch = 2.0
pitch_radius = (teeth * pitch) / (2 * math.pi)
tooth_depth = 0.75  # GT2 standard
belt_width = 6.0
flange_extra = 1.0

# Base cylinder
result = cq.Workplane("XY").circle(pitch_radius).extrude(belt_width)

# Cut GT2 tooth profile around circumference
for i in range(teeth):
    angle = i * (360.0 / teeth)
    # Trapezoidal tooth valley
    result = (result
        .workplane(offset=0)
        .transformed(rotate=(0, 0, angle))
        .moveTo(pitch_radius, 0)
        .rect(tooth_depth, pitch * 0.4)
        .cutThruAll())

# Add flanges
flange = cq.Workplane("XY").circle(pitch_radius + flange_extra).extrude(1.0)
result = result.union(flange)
flange_top = cq.Workplane("XY").workplane(offset=belt_width - 1.0).circle(pitch_radius + flange_extra).extrude(1.0)
result = result.union(flange_top)

# Center bore
bore_r = 2.5  # 5mm bore for shaft
result = result.faces("<Z").workplane().circle(bore_r).cutThruAll()
```

## 5. Options

When presenting choices to the user:

```options
{{
  "field": "mechanism_type",
  "question": "Which mechanism family fits your motion?",
  "options": [
    {{"label": "Planetary Gear Train", "value": "planetary", "description": "Compact, high ratio, smooth. Good for slow rotation."}},
    {{"label": "Four-Bar Linkage", "value": "four_bar", "description": "Converts rotation to complex paths. Good for organic motion."}}
  ]
}}
```

# DESIGN KNOWLEDGE

## Gear Math
- Pitch radius = module × teeth / 2
- Center distance (spur) = module × (teeth_1 + teeth_2) / 2
- Planetary constraint: ring_teeth = sun_teeth + 2 × planet_teeth
- Assembly condition: (ring_teeth + sun_teeth) must be divisible by planet_count
- Minimum teeth to avoid undercutting: 17 (for 20° pressure angle)
- Contact ratio = (√(r_a1² - r_b1²) + √(r_a2² - r_b2²) - a×sin(α)) / (π×m×cos(α))

## Four-Bar Linkage
- Grashof condition: shortest + longest < sum of other two
- Transmission angle μ: 40° < μ < 140° throughout range
- Crank-rocker: shortest link is the crank, frame is adjacent
- Double-crank: shortest link is the frame
- Coupler curve: trace any point on coupler for complex paths

## Cam Design
- Rise-dwell-fall-dwell (RDFD) motion programs
- Modified sinusoidal for smooth acceleration
- Pressure angle < 30° (translating follower) or < 45° (oscillating)
- Cam size determined by pressure angle constraint + roller radius

## Power & Motion
- Torque = Force × distance (N·mm)
- Power = Torque × angular_velocity (W = N·mm × rad/s)
- Gear ratio = driven_teeth / driver_teeth
- Compound train ratio = product of individual ratios
- Efficiency per mesh ≈ 0.95-0.98 (spur), 0.85-0.95 (worm)

## FDM Manufacturing
- Layer height: 0.2mm standard, 0.12mm fine
- Min wall thickness: 1.2mm (2 perimeters × 0.6mm line width)
- Min hole diameter: 2mm (below this, drilling recommended)
- Gear tooth minimum: module ≥ 1.0 for FDM
- Bridge length max: 20mm without supports
- Overhang max: 45° from vertical without supports
- Tolerance: 0.2mm general, 0.3mm sliding, 0.1mm press

## Kinetic Sculpture Principles
- Breath cycle: 4s inhale, 7s hold, 8s exhale (19s total) maps to ~3 RPM
- Golden phase offset: 137.5° between coupled oscillators
- Prime element counts: 37, 61, 271 avoid visual repetition
- Mass moment: heavier at ends = slower, more dramatic swings
- Counterweights: dynamic balance for smooth motor load

{context}
"""


class PromptBuilder:
    """Builds structured prompts for the design agent."""

    def __init__(self):
        pass

    def build_system_prompt(
        self,
        spec: dict[str, Any] | None = None,
        gate_level: str = "design",
        locked_decisions: list[dict] | None = None,
        components: list[dict] | None = None,
        user_profile: dict | None = None,
        library_matches: list[dict] | None = None,
        consultant_context: dict | None = None,
        scad_source: dict[str, str] | None = None,
    ) -> str:
        """
        Build the full system prompt with all available project context.

        This is injected into the {context} placeholder of the system prompt
        so the LLM has complete situational awareness.
        """
        context_parts = []

        # Current gate level
        context_parts.append(f"# CURRENT STATE\nGate level: {gate_level.upper()}")

        # Current spec — accumulated design parameters
        if spec:
            lines = ["\n## Project Spec (accumulated — use these, do not re-ask)"]
            for k, v in spec.items():
                if k != "feelings":
                    lines.append(f"- {k}: {v}")
            feelings = spec.get("feelings", [])
            if feelings:
                lines.append(f"- aesthetic_feel: {', '.join(feelings)}")
            context_parts.append("\n".join(lines))

        # Locked decisions — HARD CONSTRAINTS, immutable
        if locked_decisions:
            lines = [
                "\n## LOCKED DECISIONS — IMMUTABLE",
                "These decisions were made by the user. They are FINAL.",
                "Do NOT question them. Do NOT suggest alternatives.",
                "Do NOT re-ask about any parameter listed here.",
                "",
            ]
            for d in locked_decisions:
                status = d.get("status", "?")
                param = d.get("parameter", "?")
                value = d.get("value", "?")
                reason = d.get("reason", "")
                line = f"  LOCKED: {param} = {value}"
                if reason:
                    line += f" (reason: {reason})"
                lines.append(line)
            context_parts.append("\n".join(lines))

        # Component registry — exact identity of every part
        if components:
            lines = [
                "\n## COMPONENT REGISTRY — exact identity of every part",
                "When the user refers to a component by name, they mean",
                "THIS exact component with THESE exact parameters.",
                "",
            ]
            for c in components:
                comp_id = c.get("id", "?")
                name = c.get("display_name", comp_id)
                ctype = c.get("component_type", c.get("type", "?"))
                params = c.get("parameters", {})
                pos = c.get("position", {})
                material = c.get("material", "")
                notes = c.get("notes", "")
                lines.append(f"  [{comp_id}] {name} ({ctype})")
                if params:
                    for pk, pv in params.items():
                        lines.append(f"    {pk}: {pv}")
                if pos and any(pos.get(k, 0) != 0 for k in ("x", "y", "z")):
                    lines.append(f"    position: ({pos.get('x',0)}, {pos.get('y',0)}, {pos.get('z',0)})")
                if material:
                    lines.append(f"    material: {material}")
                if notes:
                    lines.append(f"    notes: {notes}")
                lines.append("")
            context_parts.append("\n".join(lines))

        # User profile
        if user_profile:
            lines = ["\n## User Profile"]
            printer = user_profile.get("printer", {})
            if printer:
                lines.append(
                    f"- Printer: {printer.get('type', '?')}, "
                    f"nozzle={printer.get('nozzle', '?')}mm, "
                    f"tolerance={printer.get('tolerance', '?')}mm"
                )
            prefs = user_profile.get("preferences", {})
            if prefs:
                lines.append(f"- Material: {prefs.get('default_material', '?')}")
                lines.append(f"- Shaft standard: {prefs.get('shaft_standard', '?')}mm")
                lines.append(f"- Default module: {prefs.get('default_module', '?')}")
            style = user_profile.get("style_tags", [])
            if style:
                lines.append(f"- Style: {', '.join(style)}")
            target = user_profile.get("production_target", "")
            if target:
                lines.append(f"- Production target: {target}")
            context_parts.append("\n".join(lines))

        # Library matches (designs similar to what the user is asking for)
        if library_matches:
            lines = ["\n## Similar Designs in Library (consider as starting points)"]
            for match in library_matches[:3]:
                name = match.get("name", "?")
                mech = match.get("mechanism_types", "?")
                desc = match.get("description", "")
                lines.append(f"- {name} ({mech}): {desc}")
            context_parts.append("\n".join(lines))

        # Rule 99 consultant context
        if consultant_context:
            lines = [f"\n## Active Rule 99 Consultants ({gate_level.upper()} gate)"]
            consultants = consultant_context.get("consultants", [])
            for c in consultants:
                name = c.get("name", "?")
                checks = c.get("checks", [])
                lines.append(f"- {name}: {', '.join(checks)}")
            libs = consultant_context.get("library_suggestions", [])
            if libs:
                lines.append("\nRelevant Python libraries:")
                for lib in libs[:8]:
                    name = lib.get("name", "?")
                    purpose = lib.get("purpose", "")
                    lines.append(f"  - {name}: {purpose}")
            context_parts.append("\n".join(lines))

        # OpenSCAD source files from project scad_dir
        if scad_source:
            lines = ["\n## OpenSCAD Source Files (from project scad_dir)"]
            lines.append("The user has existing OpenSCAD files. Reference these when discussing the design.")
            lines.append("IMPORTANT: Use parameter names and values from these files. Do NOT invent new values.")
            for filename, content in scad_source.items():
                lines.append(f"\n### {filename}")
                lines.append(f"```openscad\n{content}\n```")
            context_parts.append("\n".join(lines))

        # Gate-specific guidance
        gate_guidance = self._gate_guidance(gate_level)
        if gate_guidance:
            context_parts.append(gate_guidance)

        context = "\n".join(context_parts)
        return DESIGN_AGENT_SYSTEM_PROMPT.format(context=context)

    def _gate_guidance(self, gate_level: str) -> str:
        """Return gate-specific instructions for the LLM."""
        if gate_level == "design":
            return (
                "\n## Gate Guidance: DESIGN\n"
                "Focus on: mechanism selection, kinematic feasibility, "
                "physics verification, aesthetic intent.\n"
                "Generate components with correct gear math, link lengths, "
                "and cam profiles.\n"
                "Do NOT worry about manufacturing tolerances yet."
            )
        elif gate_level == "prototype":
            return (
                "\n## Gate Guidance: PROTOTYPE\n"
                "Focus on: ISO 286 fit specifications, tolerance stackup, "
                "collision clearances, FDM printability.\n"
                "All shaft/hole pairs need H7/g6 or similar fits specified.\n"
                "Critical dimensions need tolerance analysis."
            )
        elif gate_level == "production":
            return (
                "\n## Gate Guidance: PRODUCTION\n"
                "Focus on: DFM (tool access, min radius, draft angles), "
                "material selection, BOM generation, STEP export readiness.\n"
                "All components need material assignments and manufacturing notes.\n\n"
                "CRITICAL: For every component in the registry, you MUST generate a "
                "```python block containing CadQuery code that creates the REAL geometry. "
                "No primitives. No placeholders. No simplification. "
                "Each component gets its own ```python block with `# Component: <id>` "
                "and `result = ...` as the final solid. "
                "If OpenSCAD source files are provided, translate the exact geometry "
                "(helical grooves, tooth profiles, hex sections, mounting holes) into CadQuery."
            )
        return ""

    def build_cadquery_generation_prompt(
        self,
        components: list[dict],
        scad_source: dict[str, str] | None = None,
        spec: dict | None = None,
    ) -> str:
        """
        Build a focused prompt for CadQuery code generation.

        Used by Rule 500 step 20 to ask the LLM to translate component
        definitions + OpenSCAD source into executable CadQuery Python code.
        Each component gets a separate ```python block.

        DESIGN MANDATE: No primitives. No placeholders. Real geometry only.
        """
        parts = [
            "You are a CadQuery expert generating production-ready 3D geometry.",
            "You have been given component definitions and (optionally) OpenSCAD source files.",
            "",
            "YOUR TASK: For EACH component below, generate a ```python code block that:",
            "1. Creates the EXACT geometry using CadQuery (import cadquery as cq)",
            "2. Captures ALL design-intent features — not simplified primitives",
            "3. Assigns the final solid to `result`",
            "4. Starts with `# Component: <component_id>`",
            "",
            "DESIGN MANDATE (non-negotiable):",
            "- A helix cam MUST have helical grooves — NOT a plain cylinder",
            "- A GT2 pulley MUST have GT2 tooth profiles (2mm pitch) — NOT a generic circle",
            "- A hex frame MUST have hexagonal cross-section — NOT a tube",
            "- Gear teeth MUST have involute profiles — NOT approximated rectangles",
            "- Shafts MUST have keyways/flats/D-cuts as specified",
            "- If OpenSCAD source is provided, translate the EXACT geometry into CadQuery",
            "- If you cannot model a feature exactly, SAY SO — never silently simplify",
            "",
            "OUTPUT: One ```python block per component. Nothing else — no explanations,",
            "no component metadata blocks, just the CadQuery code.",
            "",
        ]

        # Component definitions
        parts.append("## COMPONENTS TO GENERATE")
        parts.append("")
        for c in components:
            comp_id = c.get("id", c.get("display_name", "unknown"))
            ctype = c.get("type", c.get("component_type", "unknown"))
            params = c.get("parameters", {})
            pos = c.get("position", {})
            notes = c.get("notes", "")
            parts.append(f"### {comp_id} (type: {ctype})")
            if params:
                for k, v in params.items():
                    parts.append(f"  - {k}: {v}")
            if pos and any(pos.get(k, 0) != 0 for k in ("x", "y", "z")):
                parts.append(f"  - position: ({pos.get('x',0)}, {pos.get('y',0)}, {pos.get('z',0)})")
            if notes:
                parts.append(f"  - notes: {notes}")
            parts.append("")

        # Spec context
        if spec:
            parts.append("## DESIGN SPEC")
            for k, v in spec.items():
                if k != "feelings":
                    parts.append(f"  - {k}: {v}")
            parts.append("")

        # OpenSCAD source — the design intent reference
        if scad_source:
            parts.append("## OPENSCAD SOURCE FILES (design intent — translate to CadQuery)")
            parts.append("These files define the EXACT geometry you must reproduce.")
            parts.append("Read the parameters, modules, and geometry operations carefully.")
            parts.append("")
            for filename, content in scad_source.items():
                parts.append(f"### {filename}")
                parts.append(f"```openscad\n{content}\n```")
                parts.append("")

        return "\n".join(parts)
