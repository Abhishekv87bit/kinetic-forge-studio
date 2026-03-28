# NotebookLM Prompt: Pineapple Pipeline Slide Deck

## Sources to Upload

Upload these files as NotebookLM sources before running the prompt:

1. `D:\GitHub\pineapple-pipeline\DOGFOOD_REPORT.md`
2. `d:\Claude local\docs\superpowers\specs\2026-03-15-pineapple-pipeline-design.md`
3. `d:\Claude local\docs\superpowers\skills\pineapple\SKILL.md`
4. `D:\GitHub\pineapple-pipeline\README.md`
5. `D:\GitHub\pineapple-pipeline\THREAT_MODEL.md`

---

## Prompt — Paste This Into NotebookLM

---

Create a comprehensive slide deck (20-25 slides) explaining the Pineapple Pipeline — a universal AI-powered development pipeline. The audience is technical leadership evaluating this as an internal development standard. Use the uploaded sources as your ground truth.

### Slide Structure:

**SECTION 1: THE PROBLEM (3 slides)**

Slide 1 — Title: "Pineapple Pipeline: Universal AI Development Pipeline"
- Subtitle: "Skills as orchestration, agents as execution, tools as enforcement"
- Version 1.0, March 2026

Slide 2 — "The 7 Permanent Problems in AI Development"
- How to Think (reasoning patterns)
- How to Remember (memory systems)
- How to Act (tool use)
- How to Coordinate (orchestration)
- How to Verify (validation)
- How to Protect (security)
- How to Improve (optimization)
- Show how the pipeline maps to each problem

Slide 3 — "Why a Pipeline?"
- Without: ad-hoc development, no gates, no verification, false confidence
- With: structured stages, enforced quality, evidence-based completion
- Key stat: dogfood found 72% of spec requirements were untested before the pipeline fixed itself

**SECTION 2: THE PIPELINE (6 slides)**

Slide 4 — "10-Stage Pipeline Overview"
- Business Process Flow Diagram (BPMN-style):
  ```
  [Intake] → [Strategic Review] → [Architecture] → [Plan] → [Setup] → [Build] → [Verify] → [Review] → [Ship] → [Evolve]
                                                                          ↑                        |
                                                                          └── Circuit Breaker ──────┘
  ```
- Show the 3 paths: Full (all 10), Medium (skip 1-2), Lightweight (skip 1-4)
- Color code: Human stages (blue), Agent stages (green), Mixed (purple)

Slide 5 — "Stage 0-2: From Spark to Spec"
- Intake: classify request, route to path
- Strategic Review: CEO skill asks questions humans wouldn't think to ask
- Architecture: brainstorming skill produces technical design
- Gate flow: Request → Classification → Strategic Brief → Design Spec
- Key principle: "No code without a spec"

Slide 6 — "Stage 3-5: From Plan to Code"
- Plan: checkboxed tasks with file map and verification commands
- Setup: git worktree isolation + template scaffolding (13 production templates)
- Build: single-purpose agents with review tiering (trivial/standard/complex)
- Key principle: "The executor is never the verifier" — separate agents for building vs reviewing
- Show agent dispatch model: Orchestrator → Coder Agent → Spec Reviewer → Code Quality Reviewer

Slide 7 — "Stage 6-7: Verification & Review"
- 6-Layer Verification Model:
  1. Unit Tests (pytest)
  2. Integration Tests
  3. Security Tests (67 adversarial patterns)
  4. LLM Evaluation (DeepEval)
  5. Domain Validation (VLAD)
  6. Visual Inspection (desktop screenshot + analysis)
- SHA-256 signed verification records with integrity hashing
- Code Review with severity triage: Critical → fix + re-verify, Important → fix, Minor → note
- Key principle: "Grep is NEVER verification"

Slide 8 — "Stage 8-9: Ship & Evolve"
- Ship: 4 options (merge/PR/keep/discard), pre-ship integrity check (<2h old verification)
- Evolve: session handoff, bible update, decisions log, memory extraction
- Feedback loop: every cycle feeds the next one
- Show the learning loop diagram

Slide 9 — "Path Routing: Right-Size the Process"
- Quantitative criteria table:
  | Path | Lines | Files | Starts At | Skips |
  |------|-------|-------|-----------|-------|
  | Lightweight | <50 | <3 | Stage 5 (Build) | 1-4 |
  | Medium | <200 | <8 | Stage 3 (Plan) | 1-2 |
  | Full | >200 or new project | any | Stage 1 | none |
- "The pipeline adapts to the task, not the other way around"

**SECTION 3: STATE MACHINE & ENFORCEMENT (4 slides)**

Slide 10 — "State Machine"
- State diagram showing all 9 stages as states
- Transitions: linear forward + REVIEW→BUILD retry loop
- Terminal states: EVOLVE (success), FAILED (error)
- UUID per run, atomic JSON writes, resume from checkpoint
- Truth hierarchy: state.json > git commits > plan checkboxes

Slide 11 — "Circuit Breaker & Failure Handling"
- Build-Verify-Review loop: max 3 cycles
- Per-stage retry table (from SKILL.md)
- Rollback strategy: git revert (NEVER reset --hard)
- Wall-clock timeout: 4 hours
- Escalation paths for each failure mode

Slide 12 — "Two-Layer Enforcement Model"
- Layer 1: Hookify (coding standards) — 5 pineapple rules
  - No code without spec
  - No implementation without plan
  - No merge without verification
  - No completion without evidence
  - No gap closure without verification
- Layer 2: Orchestrator (pipeline flow) — stage gates enforced by SKILL.md
- "Hookify catches the anti-patterns, the orchestrator enforces the process"

Slide 13 — "Cost Model & Controls"
- Per-run estimates: Small $10-30, Medium $50-150, Large $150-500
- 4 cost controls: review tiering, model selection, path routing, early exit
- $200 ceiling with 3 options: continue, pause+resume, simplify
- Agent model selection: haiku (mechanical), sonnet (integration), opus (architecture)

**SECTION 4: TOOLING (3 slides)**

Slide 14 — "10 CLI Tools"
- Architecture diagram showing tools and what stage they serve
- Doctor → Bootstrap | Apply → Setup | State + Tracer → All stages | Verify → Stage 6 | Audit → Compliance | Config → Global | Upgrade → Maintenance | Evolve → Stage 9 | Cleanup → Maintenance
- 261 tests, 4.6/5 quality score

Slide 15 — "13 Production Templates"
- Template architecture: Docker (2), CI/CD (1), Config (1), Middleware (5), MCP (1), Testing (2), Env (1)
- Scaffolded in <5 minutes via apply_pipeline.py
- 3 deployment stacks: fastapi-vite, fastapi-only, vite-only
- Placeholder substitution system with auto-detection

Slide 16 — "Verification Record System"
- JSON record per branch: version, run_id, branch, timestamp, layers, test_count, evidence_hash, integrity_hash
- SHA-256 evidence + integrity hashing prevents forgery
- <2 hour freshness requirement before merge
- Per-branch isolation: Feature A's verification doesn't satisfy Feature B

**SECTION 5: THE DOGFOOD (3 slides)**

Slide 17 — "We Ran the Pipeline on Itself"
- Method: 5 agents, 3 waves, spec-vs-implementation audit
- 216 requirements extracted, 13% tested before, 72% untested
- Found: 2 dead hookify rules, false-green verification, SKILL.md missing an entire stage

Slide 18 — "What We Fixed"
- Batch 1 (P0): all_green bug, 2 dead hookify rules, false-green test templates
- Batch 2 (P1): SKILL.md rewritten — 9 misalignments fixed
- Batch 3 (P2): 133→261 tests, 4 new test files, quality validated at 4.6/5
- All verified end-to-end with functional tests (not file reads)

Slide 19 — "Remaining Gaps"
- CEO skill (Stage 1) — planned
- External services (LangFuse, Mem0, Neo4j) — need Docker setup
- HK-002 hookify engine fix — TodoWrite field resolution
- Visual verification — HandsOn MCP + Windows Sandbox (parked)
- Runtime cost enforcement — currently self-monitored

**SECTION 6: VISION (2 slides)**

Slide 20 — "Architecture Principles"
- Orchestrator rule: Claude is ALWAYS the orchestrator, never writes code directly
- Separation of concerns: the executor is never the verifier
- Evidence over assertions: run it, don't read it
- Honest reporting: "FAILED" is better than false "ALL GREEN"
- Pipeline adapts: 3 paths, not one-size-fits-all

Slide 21 — "8-Phase Roadmap"
- Phase 1-4: DONE (templates, CI, middleware, caching)
- Phase 5: Smart (Mem0, cross-model verify)
- Phase 6: Multi-user (Neo4j, OAuth)
- Phase 7: Evolving (DSPy prompt optimization, LoRA fine-tuning)
- Phase 8: Future (voice interface, A2A protocol)

### Diagram Requirements:

For each diagram, describe it in enough detail that it could be recreated in any diagramming tool:

1. **BPMN Flow**: 10 stages as process blocks with swim lanes (Human, Agent, Mixed), decision gateways for path routing, loop-back arrow for circuit breaker
2. **State Machine**: UML state diagram with 9 states + FAILED, transitions labeled with gate conditions
3. **Agent Architecture**: Shows orchestrator dispatching to coder agents, spec reviewers, code quality reviewers — with clear separation (executor never verifies its own work)
4. **Enforcement Model**: Two layers (hookify + orchestrator) as concentric rings around the pipeline
5. **Verification Layers**: 6 layers as a pyramid/stack, with signed record at the base
6. **Tool-Stage Mapping**: Matrix showing which tools serve which stages

### Tone:
- Technical but accessible
- Evidence-based (cite dogfood numbers)
- Honest about gaps (don't hide what's missing)
- Focus on WHY each design decision was made, not just WHAT
