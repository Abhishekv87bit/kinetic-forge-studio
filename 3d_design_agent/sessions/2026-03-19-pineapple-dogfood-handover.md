# Pineapple Pipeline Dogfood Review — Session Handover Prompt

**Date:** 2026-03-19
**Purpose:** Copy-paste this entire prompt into a fresh Claude Code session to launch the dogfood audit.

---

## PROMPT START — Copy everything below this line

---

# Mission: Dogfood the Pineapple Pipeline

Run the Pineapple Pipeline through its own process. This is NOT a surface-level review — it's a functional audit that compares every spec requirement against what's actually delivered, runs every tool, tests every gate, and produces a gap report.

**The pipeline lives across two locations:**
- **Spec + SKILL.md:** `d:\Claude local\3d_design_agent\docs\superpowers\` (specs, plans, skills)
- **Implementation:** `D:\GitHub\pineapple-pipeline\` (tools, templates, tests)
- **Hookify gates:** `C:\Users\abhis\.claude\hookify.pineapple-*.local.md` (5 files)
- **Shared config:** `C:\Users\abhis\.pineapple\` (config.yaml, docker-compose.yml)

**Key files to read first:**
1. `d:\Claude local\docs\superpowers\specs\2026-03-15-pineapple-pipeline-design.md` — the FULL design spec (600+ lines, 10 stages, 3 layers, failure handling, cost model, scalability)
2. `d:\Claude local\docs\superpowers\skills\pineapple\SKILL.md` — the master orchestrator skill (161 lines)
3. `d:\Claude local\docs\superpowers\plans\2026-03-15-pineapple-pipeline.md` — the implementation plan (11 tasks, all marked done)

---

## Phase 1: Requirements Extraction (1 agent)

Read the full design spec and extract EVERY testable requirement into a checklist. Organize by layer and stage:

**Layer 1 — Bootstrap:**
- [ ] `~/.pineapple/config.yaml` exists with correct structure (services, templates_dir, cost_ceiling)
- [ ] `~/.pineapple/docker-compose.yml` exists with correct profiles (phase2, phase5, phase6)
- [ ] `pineapple_doctor.py` checks: Docker, services, packages, hookify, templates, superpowers
- [ ] Doctor reports skip/pass/fail correctly when services are unavailable

**Layer 2 — Pipeline (per stage):**
- Stage 0 (Intake): Request classification works (Full/Medium/Lightweight path routing)
- Stage 1 (Strategic Review): CEO skill referenced, strategic brief output format defined
- Stage 2 (Architecture): Maps to `superpowers:brainstorming`, gate = spec exists
- Stage 3 (Plan): Maps to `superpowers:writing-plans`, gate = plan with checkboxes
- Stage 4 (Setup): `apply_pipeline.py` stamps all 17 artifacts, worktree integration
- Stage 5 (Build): Maps to `superpowers:subagent-driven-development`, review tiering (trivial/standard/complex)
- Stage 6 (Verify): `pineapple_verify.py` runs 6 layers, writes `last_verify.json`
- Stage 7 (Review): Maps to `superpowers:requesting-code-review`, severity triage
- Stage 8 (Ship): Maps to `superpowers:finishing-a-development-branch`, 4 options
- Stage 9 (Evolve): `pineapple_evolve.py` handles session handoff, bible update

**Layer 3 — Post-Session:**
- Memory extraction, prompt optimization, graph updates stubs exist

**Cross-cutting:**
- Failure handling table (9 stages x recovery action x max retries x escalation)
- Circuit breaker (Stage 5-6-7 loop, max 3 cycles)
- Rollback strategy (git revert, not reset --hard)
- Pipeline state machine (`.pineapple/runs/<uuid>/state.json`)
- Cost model (per-task estimates, ceiling alert at $200)
- Path routing criteria (quantitative: <50 lines, <200 lines)
- Hookify gates (5 pineapple rules enforce pipeline discipline)

---

## Phase 2: Functional Testing (3 parallel agents)

### Agent A — CLI Tools Audit
For each tool in `D:\GitHub\pineapple-pipeline\tools\`, run it and verify behavior:

```bash
cd D:/GitHub/pineapple-pipeline

# 1. Doctor — bootstrap check
python tools/pineapple_doctor.py

# 2. Apply — dry run scaffold
python tools/apply_pipeline.py --dry-run --name test-dogfood --type fastapi

# 3. Verify — run against the pipeline repo itself
python tools/pineapple_verify.py .

# 4. Evolve — check what it does
python tools/pineapple_evolve.py --help 2>/dev/null || python tools/pineapple_evolve.py

# 5. Config — check config loading
python tools/pineapple_config.py

# 6. State — check pipeline state machine
python tools/pipeline_state.py --help 2>/dev/null || python -c "from tools.pipeline_state import *; print('importable')"

# 7. Tracer — check tracing
python tools/pipeline_tracer.py --help 2>/dev/null || python -c "from tools.pipeline_tracer import *; print('importable')"

# 8. Audit tool
python tools/pineapple_audit.py --help 2>/dev/null || python tools/pineapple_audit.py

# 9. Cleanup tool
python tools/pineapple_cleanup.py --help 2>/dev/null || python tools/pineapple_cleanup.py

# 10. Upgrade tool
python tools/pineapple_upgrade.py --help 2>/dev/null || python tools/pineapple_upgrade.py
```

For each tool, record: (a) does it run without error, (b) does its output match what the spec says it should do, (c) are there stub/placeholder functions vs real implementations.

### Agent B — Test Suite Deep Dive
```bash
cd D:/GitHub/pineapple-pipeline

# Run full test suite with verbose output
python -m pytest tests/ -v --tb=short 2>&1

# Check test coverage — what's tested vs what exists
python -m pytest tests/ -v --co 2>&1  # collect-only to see all test names
```

For each test file, verify:
- Do tests actually assert meaningful things or just check "function exists"?
- Are there tests for failure paths (not just happy path)?
- Do tests cover the spec's requirements or just the implementation's surface?
- Map each test back to a spec requirement — find untested requirements.

### Agent C — Hookify Gate Enforcement
Read all 5 pineapple hookify rules:
```
C:\Users\abhis\.claude\hookify.pineapple-no-code-without-spec.local.md
C:\Users\abhis\.claude\hookify.pineapple-no-impl-without-plan.local.md
C:\Users\abhis\.claude\hookify.pineapple-no-merge-without-verify.local.md
C:\Users\abhis\.claude\hookify.pineapple-no-done-without-evidence.local.md
C:\Users\abhis\.claude\hookify.pineapple-no-gap-close-without-verify.local.md
```

For each rule, verify:
1. Does the condition pattern actually match what it claims to catch?
2. Are there obvious bypasses (e.g., regex too narrow/too broad)?
3. Does the warning message give actionable guidance?
4. Map each rule to the spec's gate requirements — are all gates covered by hookify?
5. Which spec gates have NO hookify enforcement?

---

## Phase 3: SKILL.md vs Spec Alignment (1 agent)

Compare `SKILL.md` (161 lines) against the full spec (600+ lines). For every section in the spec, check:

1. **Stage count mismatch**: Spec has 10 stages (0-9), SKILL.md says "9 stages" — is Stage 0 (Intake) properly handled?
2. **Stage naming**: Spec calls Stage 1 "Strategic Review" with a CEO skill; SKILL.md calls it "Brainstorm" — is the CEO review layer lost?
3. **Skill mappings**: Does each SKILL.md stage invoke the correct superpowers skill per spec?
4. **Gate definitions**: Does SKILL.md enforce every gate the spec defines? List missing gates.
5. **Path routing**: Do the SKILL.md routing criteria match the spec's quantitative criteria (<50 lines, <200 lines, <8 files)?
6. **Failure handling**: Does SKILL.md reference the circuit breaker, max retries, rollback strategy?
7. **Cost awareness**: Does SKILL.md implement the $200 ceiling alert?
8. **State machine**: Does SKILL.md reference `.pineapple/runs/<uuid>/state.json`?
9. **Missing features**: What does the spec define that SKILL.md completely omits?

---

## Phase 4: Template Completeness Audit (1 agent)

Check `D:\GitHub\pineapple-pipeline\templates\` against the spec's template table:

| Spec Requires | File Should Exist | Actually Exists? | Content Real or Stub? |
|---------------|-------------------|------------------|-----------------------|
| Dockerfile.fastapi | templates/Dockerfile.fastapi | ? | ? |
| Dockerfile.vite | templates/Dockerfile.vite | ? | ? |
| docker-compose.template.yml | templates/docker-compose.template.yml | ? | ? |
| ci.github-actions.yml | templates/ci.github-actions.yml | ? | ? |
| env.template | templates/env.template | ? | ? |
| input_guardrails.py | templates/input_guardrails.py | ? | ? |
| observability.py | templates/observability.py | ? | ? |
| rate_limiter.py | templates/rate_limiter.py | ? | ? |
| resilience.py | templates/resilience.py | ? | ? |
| cache.py | templates/cache.py | ? | ? |
| mcp_server.py | templates/mcp_server.py | ? | ? |
| test_adversarial.py | templates/test_adversarial.py | ? | ? |
| test_eval_benchmark.py | templates/test_eval_benchmark.py | ? | ? |

Also check `apply_pipeline.py` — does it actually stamp ALL 17 artifacts the spec claims? Read the code and list every artifact it creates.

---

## Phase 5: Gap Report (synthesize all findings)

Produce a single deliverable: `D:\GitHub\pineapple-pipeline\DOGFOOD_REPORT.md`

Structure:
```markdown
# Pineapple Pipeline Dogfood Report
**Date:** 2026-03-19
**Method:** Spec-vs-implementation audit + functional testing

## Executive Summary
- X requirements tested, Y passing, Z gaps found
- Overall maturity: [Bootstrap/Alpha/Beta/Production]

## Requirement Coverage Matrix
| Req ID | Spec Requirement | Implemented? | Evidence | Gap? |
|--------|-----------------|-------------|----------|------|
| L1-001 | config.yaml structure | YES/NO/PARTIAL | tool output | description |
...

## Tool Functional Results
| Tool | Runs? | Output Correct? | Stubs Found? | Notes |
|------|-------|----------------|-------------|-------|
...

## SKILL.md Alignment Issues
(numbered list of mismatches)

## Hookify Gate Coverage
| Spec Gate | Hookify Rule? | Effective? | Bypasses? |
|-----------|--------------|-----------|-----------|
...

## Template Audit
(table from Phase 4)

## Test Quality Assessment
- Happy path coverage: X%
- Failure path coverage: X%
- Untested requirements: (list)

## Priority Gaps (fix these first)
1. ...
2. ...
3. ...

## Nice-to-Have Gaps (fix later)
1. ...
2. ...
```

---

## Execution Strategy

Use 5 agents total across 3 waves:

**Wave 1** (parallel):
- Agent 1: Phase 1 (requirements extraction from spec)
- Agent 2: Phase 2A (CLI tools audit)
- Agent 3: Phase 2B (test suite deep dive)

**Wave 2** (parallel, after Wave 1 completes):
- Agent 4: Phase 2C (hookify gate enforcement) + Phase 3 (SKILL.md alignment)
- Agent 5: Phase 4 (template completeness)

**Wave 3** (sequential, after all agents return):
- Main thread: Phase 5 (synthesize gap report from all agent results)

This is NOT a review where you skim and say "looks good." Run the tools. Read the code. Count the assertions. Find what's missing. The goal is a gap report that becomes the next implementation plan.
