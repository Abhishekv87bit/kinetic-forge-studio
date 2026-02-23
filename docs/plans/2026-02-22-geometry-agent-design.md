# Geometry Agent — Design Document

**Date**: 2026-02-22
**Author**: Abhishek Vashisht + Claude Opus 4.6
**Status**: Approved for implementation
**Origin**: Analysis of Zoo/KittyCAD architecture + Gemini brainstorming sessions

---

## 1. Problem Statement

Standard LLMs cannot reason spatially. They treat 3D coordinates as text tokens, leading to hallucinated dimensions, impossible assemblies, and generic geometry. Commercial solutions (Zoo/KittyCAD at $100/month) solve this with proprietary geometry engines, but they:

- Require technical users who speak CAD jargon
- Have no memory of user preferences across sessions
- Can't handle vague, multi-message intent descriptions
- Lock users into proprietary cloud infrastructure

**Goal**: Build a personal, open-source geometry agent that rivals Zoo's spatial intelligence using local tools (OpenSCAD, Build123d, FreeCAD) and Claude as the reasoning engine. The agent must be usable by someone who knows HOW a part should look and function but doesn't know CAD terminology.

---

## 2. Architecture: Three-Layer Intelligence Stack

```
USER (natural language, vague, multi-message)
    |
    v
LAYER 1: INTENT TRANSLATOR ("The Design Consultant")
    Accumulates context, classifies mechanism, guided interview,
    emits structured YAML spec
    |
    v
LAYER 2: ORCHESTRATOR ("The Project Manager")
    Reads spec, decides which tools to run, caches results,
    skips redundant work
    |
    v
LAYER 3: GEOMETRY KERNEL ("The Machinist")
    Engines (OpenSCAD, Build123d, FreeCAD)
    Analyzers (collision, B-Rep, visual diff)
    Validators (constraints, tolerances, consistency)
    Exporters (STL, STEP, reports)
```

### Why Three Layers (Lessons from Zoo)

Zoo's Zookeeper bundles three responsibilities into one: intent parsing, tool routing, and geometry execution. Separating them gives us:

- **Translator** can be improved independently (add mechanisms, better questions) without touching geometry code
- **Orchestrator** can optimize resource usage without understanding CAD
- **Kernel** can swap engines (OpenSCAD → CadQuery) without affecting user experience

---

## 3. Layer 1: Intent Translator

### 3.1 Context Accumulation (The Anti-Rush Rule)

Users don't speak in complete specifications. They give fragments, corrections, and multi-angle descriptions across multiple messages. The translator BUFFERS all input before acting.

**States:**
- `NEEDS_CLARIFICATION` (confidence < 0.4) — ask a clarifying question
- `ACCUMULATING` (confidence 0.4-0.7) — wait for more input
- `READY_TO_INTERVIEW` (confidence > 0.7) — proceed to guided questions

**Key behaviors:**
- Messages are MERGED, not treated independently
- If message N contradicts message N-1, translator reclassifies (doesn't panic)
- Combined context from ALL messages informs classification
- Never assumes — if ambiguous, asks with impact explanation

### 3.2 Three-Stage Pipeline

**Stage 1: CLASSIFY** — Match user intent to mechanism taxonomy
- Knowledge source: `knowledge/taxonomy.yaml`
- Categories: linkage, gear_system, cam, structural
- Each category has subtypes with required parameters

**Stage 2: INTERVIEW** — Extract parameters through guided questions
- Knowledge source: `knowledge/<category>.yaml` (linkages.yaml, gears.yaml, etc.)
- Questions use IMPACT format: simple options with explanations of consequences
- User profile (`~/.geometry-agent/profile.yaml`) stores preferences to skip known answers
- Derived parameters computed from rules (user never asked for computed values)

**Stage 3: RESOLVE** — Validate and emit spec
- Pre-checks: Grashof, transmission angle, envelope fit, material compatibility
- If pre-check fails: explain to user in simple terms, offer alternatives
- Output: `assembly_spec.yaml` (or `part_spec.yaml` for single components)

### 3.3 Assembly Handling

For multi-part requests, the translator decomposes into:
- Parts (each with type and params)
- Constraints (fits, clearances, mesh requirements between parts)
- Relationships (which parts connect, how they move relative to each other)

Assembly constraints use ISO 286 notation (H7/g6) when applicable, with plain-English explanations.

### 3.4 Session Memory

Stored in `~/.geometry-agent/profile.yaml`:
- **Defaults**: material, tolerance, scale, printer constraints
- **Preferences**: detail level, $fn, export format
- **Skip list**: questions the user has permanently answered
- **History**: past designs, common patterns, learned preferences
- **Style notes**: "prefers visible mechanisms," "hexagonal aesthetics," etc.

Profile accumulates over sessions. After ~10 sessions, the translator barely needs to ask anything — it already knows the user's style.

---

## 4. Layer 2: Orchestrator

### 4.1 Planner

Reads the assembly spec and determines:
- Which engine to use (OpenSCAD for iteration, Build123d for production B-Rep)
- Which validators to run (Grashof only for linkages, tolerance stackup only for assemblies)
- Whether rendering is needed (new component: yes; parameter tweak: diff only)
- Whether collision detection is needed (single part: no; assembly: yes)
- Export format (STL for prototype, STEP for production)

### 4.2 Cache

Tracks what's already been validated. On parameter changes:
- Re-validates ONLY constraints affected by the changed parameter
- Re-renders ONLY views where geometry visually changed
- Skips collision check if parts haven't moved relative to each other

### 4.3 Dispatcher

Invokes kernel tools in optimal order:
- Parallel when independent (render + validate can run simultaneously)
- Sequential when dependent (compile must finish before render)

### 4.4 Resource-Saving Logic

| Scenario | Runs | Skips |
|----------|------|-------|
| New component | Full pipeline | Collision (single part) |
| Parameter tweak | Recompile + changed constraints + diff | Full re-render, collision |
| Assembly integration | Collision + assembly render | Re-validate individual parts |
| Export for production | B-Rep + STEP + tolerance stackup | OpenSCAD render |
| Dimension check | Constraint check only | Everything else |

---

## 5. Layer 3: Geometry Kernel

### 5.1 Engines

| Engine | Purpose | When Used |
|--------|---------|-----------|
| OpenSCAD (Nightly + Manifold) | Fast iteration, BOSL2 gears | Default for prototyping |
| Build123d + OCP | B-Rep modeling, STEP export | Production, interference analysis |
| FreeCAD MCP | STEP conversion, FEM analysis | Gate 3 production pipeline |

### 5.2 Analyzers

| Analyzer | Library | Purpose |
|----------|---------|---------|
| Collision detection | trimesh + python-fcl | Mesh intersection (STL pairs) |
| B-Rep interference | OCP BRepAlgoAPI_Common | Exact solid intersection (STEP pairs) |
| Visual diff | Pillow ImageChops | PNG render comparison, changed-geometry highlighting |
| Geometry metrics | trimesh / OCP | Volume, center of mass, surface area, face count |

### 5.3 Validators

| Validator | Source | Purpose |
|-----------|--------|---------|
| Constraint checker | constraints.yaml | Generalized rule engine (replaces hard-coded validate_geometry.py) |
| SCAD parser | Ported from validate_geometry.py | Variable resolver, expression evaluator |
| ISO 286 lookup | iso286_lookup.py (existing) | Shaft/hole tolerance zones |
| Tolerance stackup | tolerance_stackup.py (existing) | Worst-case + RSS + Monte Carlo |
| Consistency audit | Ported from consistency_audit.py | Cross-file drift detection |

### 5.4 Exporters

| Format | Tool | Use Case |
|--------|------|----------|
| STL | OpenSCAD CLI | 3D printing prototype |
| STEP | Build123d / FreeCAD | Production fabrication |
| PNG (6-view) | OpenSCAD MCP | Visual inspection |
| JSON report | Custom | All checks, metrics, pass/fail |
| HTML report | Custom (future) | Visual report with embedded renders |

---

## 6. Constraint System (YAML-Driven)

Replaces hard-coded Python checks with declarative constraint files:

```yaml
# constraints/four_bar_linkage.yaml
name: "Four-bar linkage constraints"
applies_to: linkage.four_bar

rules:
  - name: grashof
    check: "s + l <= p + q"
    vars:
      s: "min(ground, crank, coupler, rocker)"
      l: "max(ground, crank, coupler, rocker)"
      p: "second smallest"
      q: "second largest"
    on_fail: "Linkage cannot make full rotation. Shorten crank or lengthen ground."

  - name: transmission_angle
    check: "min_transmission >= 40 and max_transmission <= 140"
    on_fail: "Linkage will jam at extreme positions. Adjust link ratios."

  - name: envelope_fit
    check: "max_extent <= build_plate"
    on_fail: "Part exceeds printer build volume ({max_extent}mm > {build_plate}mm)."

  - name: min_wall
    check: "all_walls >= printer.min_wall"
    on_fail: "Wall thickness {min_wall}mm below printer minimum {printer.min_wall}mm."
```

---

## 7. Project Structure

```
geometry-agent/
├── pyproject.toml
├── README.md
├── src/
│   └── geometry_agent/
│       ├── __init__.py
│       ├── cli.py                  # Click-based CLI entry point
│       ├── config.py               # Project settings, profile loading
│       │
│       ├── translator/             # LAYER 1
│       │   ├── context.py          # Context buffer + accumulation
│       │   ├── classifier.py       # Taxonomy matching, confidence scoring
│       │   ├── interviewer.py      # Guided question engine
│       │   ├── spec_builder.py     # YAML spec emitter
│       │   └── profile.py          # User preference memory
│       │
│       ├── orchestrator/           # LAYER 2
│       │   ├── planner.py          # Tool selection logic
│       │   ├── cache.py            # Validation result cache
│       │   └── dispatcher.py       # Tool invocation + ordering
│       │
│       ├── engines/                # LAYER 3 - Generators
│       │   ├── openscad.py         # Compile, render via CLI
│       │   ├── build123d_engine.py # B-Rep operations, STEP export
│       │   └── freecad_engine.py   # FreeCAD MCP bridge
│       │
│       ├── analyzers/              # LAYER 3 - Spatial Intelligence
│       │   ├── collision.py        # trimesh + FCL mesh clash
│       │   ├── brep.py             # OCP B-Rep interference + metrics
│       │   └── visual_diff.py      # Pillow render comparison
│       │
│       ├── validators/             # LAYER 3 - Rule Checking
│       │   ├── constraints.py      # YAML-driven constraint engine
│       │   ├── scad_parser.py      # Variable resolver (ported)
│       │   ├── tolerance.py        # ISO 286 + stackup (wrapped)
│       │   └── consistency.py      # Drift audit (ported)
│       │
│       └── exporters/              # LAYER 3 - Output
│           ├── stl.py
│           ├── step.py
│           └── report.py           # JSON/HTML reports
│
├── knowledge/                      # Domain knowledge for translator
│   ├── taxonomy.yaml               # Mechanism type classification
│   ├── linkages.yaml               # Four-bar, six-bar, Jansen, etc.
│   ├── gears.yaml                  # Spur, bevel, planetary, worm, etc.
│   ├── cams.yaml                   # Disc, barrel, conjugate
│   ├── structural.yaml             # Brackets, housings, frames, shafts
│   └── materials.yaml              # PLA, PETG, brass, aluminum, steel
│
├── constraints/                    # User-defined constraint files
│   ├── four_bar_linkage.yaml
│   ├── gear_mesh.yaml
│   └── assembly_fit.yaml
│
├── hooks/                          # Claude Code integration
│   └── on_scad_edit.sh             # Auto-trigger on .scad file change
│
└── tests/
    ├── test_translator.py
    ├── test_collision.py
    ├── test_constraints.py
    └── fixtures/
```

---

## 8. CLI Commands

```bash
# Interactive design (uses translator)
geometry-agent new                              # Start guided interview
geometry-agent new linkage                      # Start with known category
geometry-agent new --from-spec spec.yaml        # Skip translator, use existing spec

# Pipeline commands (uses orchestrator + kernel)
geometry-agent run design.scad                  # Full pipeline: compile+validate+render+report
geometry-agent compile design.scad              # OpenSCAD compile check (zero warnings)
geometry-agent validate design.scad             # Run constraint YAML checks
geometry-agent render design.scad --views all   # 6-view PNG render
geometry-agent diff renders/v1/ renders/v2/     # Visual diff of render directories
geometry-agent collide assembly.stl             # Collision detection on multi-body STL
geometry-agent analyze part.step                # B-Rep analysis (volume, CoM, faces)
geometry-agent export design.scad --format step # STEP export via Build123d
geometry-agent audit                            # Consistency check across project
geometry-agent tolerance H7/g6 25               # ISO 286 lookup

# Composed
geometry-agent run design.scad --collide --export step --report html

# Profile management
geometry-agent profile show                     # Show current preferences
geometry-agent profile set material PLA         # Set default material
geometry-agent profile learn                    # Analyze past sessions, update preferences
```

---

## 9. Dependencies

```toml
[project]
name = "geometry-agent"
version = "0.1.0"
requires-python = ">=3.11"

dependencies = [
    "trimesh[easy]>=4.0",       # Mesh loading, analysis
    "python-fcl>=0.7",          # Collision detection (FCL bindings)
    "build123d>=0.7",           # B-Rep kernel (includes OCP)
    "solidpython2>=2.0",        # Structured SCAD generation
    "Pillow>=10.0",             # Visual diff
    "click>=8.0",               # CLI framework
    "pyyaml>=6.0",              # Constraint/knowledge file parsing
    "rich>=13.0",               # Terminal output formatting
    "numpy>=1.24",              # Numeric operations
]

[project.optional-dependencies]
freecad = ["freecad-mcp>=0.1"]  # FreeCAD bridge (optional, heavy)

[project.scripts]
geometry-agent = "geometry_agent.cli:main"
```

---

## 10. Integration with Claude Code

### 10.1 Hooks

On `.scad` file edit, auto-run validation:

```bash
#!/bin/bash
# hooks/on_scad_edit.sh
FILE="$1"
geometry-agent run "$FILE" --quiet --report json
```

### 10.2 MCP Server (Future)

Expose geometry-agent as an MCP server so Claude Code can call tools directly:
- `geometry_agent.validate(file)` — returns constraint results
- `geometry_agent.render(file, views)` — returns base64 PNGs
- `geometry_agent.collide(stl_files)` — returns collision pairs
- `geometry_agent.translate(messages)` — returns spec YAML

### 10.3 ntfy.sh Notifications

Long-running operations (B-Rep analysis, collision on large assemblies) send notifications:
```bash
curl -d "Collision check complete: 2 interferences found" \
  -H "Tags: warning" ntfy.sh/bussabtheakhaijanab1851421
```

---

## 11. Implementation Phases

### Phase 1: Foundation (Week 1-2)
- Project scaffolding (pyproject.toml, CLI skeleton)
- Port validate_geometry.py → constraint engine
- Port consistency_audit.py → generalized auditor
- Wrap iso286_lookup.py + tolerance_stackup.py
- OpenSCAD compile + render commands
- Basic CLI: `run`, `compile`, `validate`, `render`

### Phase 2: Intelligence (Week 3-4)
- trimesh + FCL collision detection
- Pillow visual diff
- Build123d B-Rep analysis (volume, interference)
- Claude Code hooks for auto-validation
- CLI: `collide`, `diff`, `analyze`

### Phase 3: Translator (Week 5-6)
- Context accumulation engine
- Mechanism taxonomy YAML
- Guided interview system with impact questions
- User profile memory
- CLI: `new`, `profile`

### Phase 4: Orchestrator + Polish (Week 7-8)
- Smart planner (skip redundant work)
- Validation cache
- STEP export pipeline
- JSON/HTML report generation
- ntfy.sh integration
- CLI: `export`, `audit`, full `run` with all flags

---

## 12. Success Criteria

The agent is "done" when:
1. `geometry-agent new` can guide a non-technical user through creating a four-bar linkage from zero knowledge
2. `geometry-agent run` catches constraint violations that would cause print failures
3. `geometry-agent collide` detects part interference in a multi-body STL
4. `geometry-agent diff` shows what changed between two design iterations
5. Claude Code hooks auto-validate on every .scad edit with zero manual commands
6. The user profile remembers preferences and skips redundant questions after 3 sessions

---

## 13. What This Gives You That Zoo Doesn't

| Feature | Zoo ($100/mo) | Your Agent (free, local) |
|---------|---------------|--------------------------|
| Intent translation | Technical prompts only | Impact-based guided interview |
| User memory | None (cold start every session) | Profile.yaml (learns your style) |
| Assembly constraints | Manual | Declarative YAML + auto-check |
| Engine flexibility | KCL only | OpenSCAD + Build123d + FreeCAD |
| Collision detection | Cloud GPU | Local (trimesh + FCL) |
| Offline use | No (cloud required) | Yes (everything local) |
| Claude Code integration | No | Hooks + MCP |
| Cost | $1,200/year | $0 (local compute) |
| Open source | Partially | Fully |

---

## 14. Prior Art & Influences

- **Zoo/KittyCAD Zookeeper**: Three-layer separation (intent → routing → engine)
- **Agentic3D**: LLM → OpenSCAD → render → VLM inspect → iterate loop
- **openscad-agent**: Claude Code + OpenSCAD integration pattern
- **CAD-Coder (MIT)**: CadQuery outperforms raw OpenSCAD for LLM code generation
- **AIDL (MIT)**: Constraint declaration vs coordinate specification for LLMs
- **Gemini brainstorming sessions**: Mechanism taxonomy, multi-model strategy
- **Rule 99 pipeline**: Gate-based validation, consultant-pattern analysis
