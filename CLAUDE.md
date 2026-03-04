# Project Rules

Millimeters. Single motor unless impossible.

## Modes
- **Experiment** — Try different mechanisms, identify patterns
- **Build** — 6-stage gated pipeline (Discover → Animate → Mechanize → Simulate → Build → Iterate)
- **Learn** — Everything needed to become a professional kinetic sculptor

## Execution Patterns
- **Parallel**: Vague request → search 2-3 approaches simultaneously
- **Sequential**: Clear parameters → generate directly, calculate → code → verify
- **Question budget**: 1-3 questions MAX before starting work. Infer when possible.

## Validation (tools handle the details)
- **OpenSCAD**: Compile with `openscad.com -o test.csg file.scad`, then run `python validate_geometry.py file.scad` — zero FAILs required
- **CadQuery**: Run `python tools/vlad.py <module_name>` — zero FAILs required (8-tier check: topology, interference, clearance, manufacturability, export)
- **Render & inspect** PNG before delivering to user

## On-Demand Context (read ONLY when the task needs it)
- **Kinetic sculpture design rules** → `3d_design_agent/DESIGN_RULES.md` (OpenSCAD template, physics, parametric discipline, component isolation, knowledge routing)
- **KFS web app** → Read `projects/kinetic-forge-studio.yaml` for state, `projects/kfs-gaps.yaml` for gaps
- **Triple Helix project** → `TRIPLE_HELIX_MVP_MASTER_PROMPT.md`
- **Margolin / wave sculpture** → `archives/docs/MARGOLIN_KNOWLEDGE_BANK.md`

## Tools
- `validate_geometry.py` — OpenSCAD constraint checker
- `tools/vlad.py` (VLAD) — Universal CadQuery validator
- `openscad-mcp` — MCP server for render-in-loop
- `BOSL2` — OpenSCAD library at `Documents\OpenSCAD\libraries\BOSL2\`
- `FreeCAD MCP` — Format bridge (STL→STEP)
