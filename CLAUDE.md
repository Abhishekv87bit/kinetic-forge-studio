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
- **Orchestrator rule**: Claude is ALWAYS the orchestrator. Never write code directly — launch subagents for all implementation, verification, and review. Main thread coordinates, delegates, and synthesizes.
- **Visual verification**: VS Code can't display images. When visual inspection is needed, launch a subagent that: (1) renders/opens the output on desktop, (2) takes a screenshot via `python -c "from PIL import ImageGrab; ImageGrab.grab().save('screenshot.png')"`, (3) reads the screenshot with the Read tool (multimodal), (4) analyzes what's on screen and reports back to orchestrator.

## Validation (tools handle the details)
- **OpenSCAD**: Compile with `openscad.com -o test.csg file.scad`, then run `python validate_geometry.py file.scad` — zero FAILs required
- **CadQuery**: Run `python tools/vlad.py <module_name>` — zero FAILs required (8-tier check: topology, interference, clearance, manufacturability, export)
- **Render & inspect** PNG before delivering to user

## Mandatory Pre-Work (read BEFORE any spec or plan)
- **User's tool decisions** → `D:\ai-agent-mastery-plan\` (26-tool directory, 8-week curriculum, BrokerFlow walkthrough)
- **Memory** → MEMORY.md (user preferences, locked decisions, active projects)
- **Project bible** → relevant `projects/*.yaml` for current state
- **Decisions log** → `decisions.md` for locked choices
- If a spec proposes building something a library already does, FLAG IT.

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

## Pipeline
- **Pineapple Pipeline** — Universal development pipeline (10 stages: Intake -> Strategic Review -> Architecture -> Plan -> Setup -> Build -> Verify -> Review -> Ship -> Evolve)
- Spec: `docs/superpowers/specs/2026-03-15-pineapple-pipeline-design.md`
- Skill: `docs/superpowers/skills/pineapple/SKILL.md`
- Routes: Full Path (new features), Medium Path (clear scope), Lightweight Path (bug fixes)
- CLI: `python production-pipeline/tools/pineapple_doctor.py` (bootstrap), `python production-pipeline/tools/pineapple_verify.py` (Stage 5)

## Dev Loop (MANDATORY)
Before ANY implementation work, invoke /dev-loop via Skill tool. This is not optional.

Skill invocations:
- `Skill("pineapple:dev-loop")` before any implementation
- `Skill("pineapple:verify-outputs")` after agent claims files written
- `Skill("pineapple:verify-done")` before marking anything complete
- `Skill("pineapple:honest-status")` before any progress report

Skills live at: `d:\Claude local\docs\superpowers\skills\pineapple\`
If Skill tool cannot resolve `pineapple:dev-loop`, read `d:\Claude local\docs\superpowers\skills\pineapple\dev-loop.md` directly.
