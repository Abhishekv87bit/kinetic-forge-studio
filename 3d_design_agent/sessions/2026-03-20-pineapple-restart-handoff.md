# Pineapple Pipeline Restart Handoff

**Date:** 2026-03-20
**Purpose:** Give a fresh Claude Code session everything it needs to rebuild the Pineapple Pipeline correctly.
**How to use:** Copy-paste everything below the PROMPT START marker into a new session.

---

PROMPT START

---

## You are restarting the Pineapple Pipeline project from scratch.

The previous implementation was built without reading the user's learning plan. It reinvented 8+ libraries the user had already chosen. The process design is sound. The implementation must be killed and rebuilt on the user's actual tool choices.

**MANDATORY FIRST STEP:** Read CLAUDE.md at `d:\Claude local\CLAUDE.md`. It contains project rules, validation commands, and the pipeline section you must follow.

---

## 1. CONTEXT FILES -- READ ALL BEFORE DOING ANYTHING

Read these files in this exact order. Do not write a single line of code or spec until you have read all of them.

### The user's learning plan (SOURCE OF TRUTH for tool choices):
1. `D:\ai-agent-mastery-plan\NOTEBOOKLM_PROMPT.md` -- 26-tool directory, 7 Permanent Problems, 5 Architecture Patterns, 5 Reasoning Methods. THIS decides what libraries the pipeline uses.
2. `D:\ai-agent-mastery-plan\NOTEBOOKLM_AI_ENGINEER_MASTERCLASS.md` -- 8-week curriculum. The rebuild phases should align with this.
3. `D:\ai-agent-mastery-plan\NOTEBOOKLM_BROKERFLOW_WALKTHROUGH.md` -- Real project walkthrough. BrokerFlow is the planned learning vehicle.

### The process design (KEEP THIS):
4. `d:\Claude local\docs\superpowers\skills\pineapple\SKILL.md` -- 238-line orchestrator. 10 stages, 3 paths, all 9 alignment points fixed. This is the process to keep.
5. `d:\Claude local\docs\superpowers\skills\pineapple\ceo-review.md` -- CEO Strategic Review skill for Stage 1.
6. `d:\Claude local\docs\superpowers\specs\2026-03-15-pineapple-pipeline-design.md` -- 958-line design spec. The process layer is good; the implementation layer needs rewriting.

### What went wrong:
7. `D:\GitHub\pineapple-pipeline\DOGFOOD_REPORT.md` -- Full audit: 216 requirements extracted, 156 untested, 2 dead hookify rules, false-green test templates, SKILL.md misalignments (all now fixed in SKILL.md).
8. `C:\Users\abhis\.claude\projects\d--Claude-local\memory\feedback_pineapple_dogfood_lessons.md` -- 10 hard-earned lessons from dogfooding.

### Project rules:
9. `d:\Claude local\CLAUDE.md` -- Mandatory. Contains validation commands, pipeline reference, tool preferences.

---

## 2. WHAT HAPPENED (so you don't repeat it)

### The fatal mistake
The 958-line spec was written without reading the user's learning plan at `D:\ai-agent-mastery-plan\`. The user had already chosen 26 specific tools through months of research. The pipeline implementation reinvented 8+ of those tools from scratch in custom Python.

### What was built (3,442 lines of tools, 3,635 lines of tests, 13 templates):

**Tools at `D:\GitHub\pineapple-pipeline\tools\`:**
| Tool | Lines | What It Does |
|------|-------|-------------|
| `apply_pipeline.py` | 420 | Scaffold new projects with 13 templates |
| `pineapple_doctor.py` | 447 | Bootstrap health checks (11 checks) |
| `pineapple_verify.py` | 485 | 6-layer verification runner |
| `pineapple_evolve.py` | 678 | Post-session tasks (Mem0, Neo4j, baselines) |
| `pineapple_config.py` | 211 | Pydantic-validated config |
| `pipeline_state.py` | 304 | 9-stage state machine with atomic writes |
| `pipeline_tracer.py` | 244 | JSONL tracer with 7 event types |
| `pineapple_audit.py` | 180 | 4 compliance checks |
| `pineapple_cleanup.py` | 235 | Stale run/worktree cleanup |
| `pineapple_upgrade.py` | 238 | Template version checking with diffs |

**Tests at `D:\GitHub\pineapple-pipeline\tests\`:** 13 files, 3,635 lines total. All pass (288 tests, 0 failures). But coverage is uneven -- 72% of spec requirements untested, 2 test templates give false green.

**Templates at `D:\GitHub\pineapple-pipeline\templates\`:** 13 files. 10 production-ready, 2 test stubs (false green), 1 scaffold.

**Hookify rules at `C:\Users\abhis\.claude\`:**
- `hookify.pineapple-no-code-without-spec.local.md` -- WEAK (narrow file pattern)
- `hookify.pineapple-no-impl-without-plan.local.md` -- WEAK (narrow file pattern)
- `hookify.pineapple-no-merge-without-verify.local.md` -- Was DEAD, may have been fixed
- `hookify.pineapple-no-done-without-evidence.local.md` -- Was DEAD (engine limitation)
- `hookify.pineapple-no-gap-close-without-verify.local.md` -- GOOD

### The core problem: custom code that should be libraries

| Custom Code | Lines | Replace With | Source |
|------------|-------|-------------|--------|
| `pipeline_state.py` (state machine) | 304 | **LangGraph** | User's learning plan |
| Retry counters in state machine | ~30 | **Tenacity** | User's learning plan |
| `resilience.py` template (circuit breaker) | 216 | **PyBreaker** | User's learning plan |
| Raw HTTP stubs for Mem0 | ~50 | **Mem0 SDK** (`mem0ai`) | User's learning plan |
| Raw HTTP stubs for Neo4j | ~50 | **Neo4j Python driver** | User's learning plan |
| Manual cost tracking | ~80 | **LangFuse SDK** | User's learning plan |
| No structured LLM outputs | -- | **Instructor** | User's learning plan |
| No LLM evaluation | skipped | **DeepEval** | User's learning plan |
| No RAG evaluation | -- | **RAGAS** | User's learning plan |
| No prompt optimization | -- | **DSPy** | User's learning plan |
| No vector search | -- | **ChromaDB** | User's learning plan |

---

## 3. WHAT TO SAVE (the process is sound)

These design elements are validated and must survive into the rebuild:

- **10-stage pipeline:** Intake -> Strategic Review -> Architecture -> Plan -> Setup -> Build -> Verify -> Review -> Ship -> Evolve
- **3 path routing** with quantitative criteria (Full: unknown scope; Medium: <200 lines, <8 files, clear scope; Lightweight: <50 lines, <3 files, bug fix)
- **Gate definitions per stage** (see SKILL.md Stages 0-9)
- **Separation of concerns:** Builder (Stage 5) != Verifier (Stage 6) != Reviewer (Stage 7). No shared conversation context.
- **CEO strategic review skill** (`ceo-review.md`) -- The Used-Car-Lot Principle, adaptive questioning, Strategic Brief output
- **Circuit breaker:** 3 cycles max through Stage 5-6-7 loop, then 3 options (merge with issues, redesign, abandon)
- **Rollback strategy:** `git revert` not `git reset --hard`. Never force-push.
- **Cost model:** $200 ceiling with 3 options (continue, pause+resume, simplify)
- **5 hookify enforcement rules** (fix the 2 dead ones, widen the 2 weak ones)
- **State machine concept:** UUID per run, resume from checkpoint, truth hierarchy (state.json > git > checkboxes)
- **13 production templates** (Docker, CI, middleware, tests) -- 10 are production-ready
- **SKILL.md orchestrator** (238 lines, all 9 alignment points fixed in current session)
- **288 existing tests** -- these are behavioral specs for what the tools SHOULD do, even if the implementation changes

---

## 4. THE RESTART PROCESS

You MUST follow the pipeline's own Full Path. This is a new project (rebuild).

### Stage 0: Intake
- You have already read the context files from Section 1 above.
- Classification: **Full Path** (new project, unknown implementation scope).
- Create pipeline run if state machine is available.

### Stage 1: Strategic Review
- Invoke `pineapple:ceo-review` skill.
- Critical strategic question: **"Is the pipeline a standalone tool, or should it BE the user's learning project?"**
  - The user is LEARNING these 26 tools. The pipeline should teach them by using them, not hide them behind abstractions.
  - BrokerFlow (insurance automation) is the planned learning vehicle from the 8-week curriculum. How does the pipeline relate to BrokerFlow?
  - Options: (A) Pipeline is infrastructure that BrokerFlow runs on. (B) Pipeline IS the first project built with these tools. (C) Pipeline and BrokerFlow are built in parallel, teaching different tool subsets.
- Output: Strategic Brief for the rebuild.

### Stage 2: Architecture
- Write a NEW spec that maps each pipeline component to a library from `NOTEBOOKLM_PROMPT.md`.
- The spec must reference the tool directory as the source of truth for ALL library choices.
- Core architecture decision: **LangGraph as the backbone**, replacing `pipeline_state.py`.
- The new spec replaces the implementation sections of `2026-03-15-pineapple-pipeline-design.md`. The process/stage sections stay.
- Proposed mapping:

| Pipeline Component | Library | Role |
|-------------------|---------|------|
| State machine / orchestration | LangGraph | Graph-based state management, checkpointing, resume |
| Data validation | Pydantic | Input/output schemas for every stage |
| Structured LLM output | Instructor | Force LLM responses into Pydantic models |
| Retries | Tenacity | Exponential backoff on transient failures |
| Circuit breaker | PyBreaker | 3-state FSM for Stage 5-6-7 loop |
| Observability / cost tracking | LangFuse | Traces, cost dashboard, latency |
| LLM evaluation | DeepEval | Quality gates in Stage 6 (Verify) |
| Memory extraction | Mem0 SDK | Stage 9 (Evolve) memory persistence |
| Graph memory | Neo4j driver | Stage 9 (Evolve) component relationships |
| Prompt optimization | DSPy | Stage 9 (Evolve) prompt improvement |
| Vector search | ChromaDB | RAG for context retrieval |
| RAG evaluation | RAGAS | Quality of retrieval in Stage 6 |
| Testing | pytest + DeepEval | Unit + LLM eval |

### Stage 3: Plan
- Break into phases that align with the user's 8-week curriculum:
  - **Phase 1 (Week 1-2):** Core pipeline with LangGraph + Pydantic + pytest. Get stages 0-9 flowing as a LangGraph graph. No external services yet.
  - **Phase 2 (Week 3-4):** Add Instructor (structured outputs) + LangFuse (observability) + Tenacity (retries). Pipeline starts producing traces.
  - **Phase 3 (Week 5-6):** Add DeepEval (LLM evals) + PyBreaker (circuit breaker). Stage 6 verification becomes real.
  - **Phase 4 (Week 7-8):** Add Mem0 + Neo4j + DSPy. Stage 9 evolve becomes real. Pipeline is self-improving.
- Each phase must be independently shippable. Phase 1 alone must be a working pipeline.

---

## 5. TEN LESSONS (non-negotiable rules for the rebuild)

1. **Read the user's world before designing.** You have 3 NotebookLM files and 8 weeks of curriculum research. Use them.
2. **Verify at every level.** Code vs spec. Spec vs user intent. User intent vs user's actual plan.
3. **Running code > reading code.** Run every tool you build. `pytest` is not optional.
4. **User pushback is always signal.** If the user questions a choice, the choice is probably wrong.
5. **False confidence is worse than no confidence.** `all_green: true` with 5/6 layers skipped is a lie. Never report success without evidence.
6. **Approval does not equal correctness.** The user approved the original spec. It was still wrong. Cross-check against source documents.
7. **The spec is the most dangerous artifact.** A confident spec that contradicts the user's actual needs will produce confident, wrong code. Always validate the spec against reality before building.
8. **Don't reinvent what the user wants to LEARN.** The user chose LangGraph. Don't write a custom state machine. The user chose Tenacity. Don't write custom retry logic. Using the library IS the learning.
9. **Executor is never the verifier -- including Claude.** The agent that writes code must not test it. The agent that tests must not have build context. Apply this to yourself.
10. **Cross-session context is everything.** This handoff exists because the previous session had to discover things that were already documented. Read first, always.

---

## 6. EXISTING ARTIFACTS (reference, don't destroy)

### Keep and reference:
| Artifact | Path | Status |
|----------|------|--------|
| SKILL.md (orchestrator) | `d:\Claude local\docs\superpowers\skills\pineapple\SKILL.md` | KEEP -- 238 lines, all 9 alignment points fixed |
| CEO Review skill | `d:\Claude local\docs\superpowers\skills\pineapple\ceo-review.md` | KEEP -- complete |
| Design spec (process layer) | `d:\Claude local\docs\superpowers\specs\2026-03-15-pineapple-pipeline-design.md` | KEEP process/stage sections, REWRITE implementation sections |
| Dogfood report | `D:\GitHub\pineapple-pipeline\DOGFOOD_REPORT.md` | KEEP -- reference for what went wrong |
| Dogfood lessons | `C:\Users\abhis\.claude\projects\d--Claude-local\memory\feedback_pineapple_dogfood_lessons.md` | KEEP -- 10 rules |
| NotebookLM slide deck prompt | `d:\Claude local\3d_design_agent\sessions\2026-03-20-notebooklm-pipeline-deck.md` | REFERENCE -- summarizes the story |
| Previous session handoff | `d:\Claude local\3d_design_agent\sessions\2026-03-19-pineapple-dogfood-handover.md` | REFERENCE -- dogfood session notes |

### Existing code (evaluate during Architecture, decide keep/kill/refactor):
| Artifact | Path | Lines | Decision Needed |
|----------|------|-------|----------------|
| 10 pipeline tools | `D:\GitHub\pineapple-pipeline\tools\` | 3,442 | Some may survive if refactored onto libraries (e.g., `pineapple_doctor.py`, `apply_pipeline.py`). `pipeline_state.py` is definitely replaced by LangGraph. |
| 13 test files | `D:\GitHub\pineapple-pipeline\tests\` | 3,635 | Tests define behavior. Keep as specs even if implementation changes. |
| 13 templates | `D:\GitHub\pineapple-pipeline\templates\` | ~1,500 | 10 are production-ready. `resilience.py` (216 lines) replaced by PyBreaker. 2 test stubs need real assertions. |
| 5 hookify rules | `C:\Users\abhis\.claude\hookify.pineapple-*.local.md` | ~100 | Fix the 2 dead rules, widen the 2 weak file patterns. See DOGFOOD_REPORT.md HK-001 through HK-005. |

### User's learning plan (read-only, do not modify):
| File | Path | What It Contains |
|------|------|-----------------|
| Tool directory | `D:\ai-agent-mastery-plan\NOTEBOOKLM_PROMPT.md` | 26 tools, 7 Permanent Problems, architecture patterns |
| Curriculum | `D:\ai-agent-mastery-plan\NOTEBOOKLM_AI_ENGINEER_MASTERCLASS.md` | 8-week plan |
| BrokerFlow walkthrough | `D:\ai-agent-mastery-plan\NOTEBOOKLM_BROKERFLOW_WALKTHROUGH.md` | Real project example |

---

## 7. SUCCESS CRITERIA

The rebuild is successful when:

1. **Every custom state management line is replaced by LangGraph** -- no `pipeline_state.py`, no hand-rolled state machine.
2. **Every retry loop uses Tenacity** -- no manual counters.
3. **Every circuit breaker uses PyBreaker** -- no custom 3-state FSM in templates.
4. **LangFuse replaces manual cost tracking** -- real traces, real dashboards.
5. **Instructor replaces unstructured LLM calls** -- every LLM output has a Pydantic schema.
6. **The 10-stage process is preserved exactly** -- stages, gates, routing, separation of concerns.
7. **The SKILL.md orchestrator is preserved** -- it drives the process, libraries drive the implementation.
8. **Phase 1 alone produces a working pipeline** -- LangGraph + Pydantic + pytest, no external services required.
9. **The new spec explicitly references `NOTEBOOKLM_PROMPT.md`** as the source of truth for tool choices.
10. **All 5 hookify rules work** -- 0 dead, 0 weak. Validate with `py -3.12 tools/validate_hookify.py`.

---

## 8. ANTI-PATTERNS (things the previous session did wrong -- do not repeat)

- Writing a 600-line spec without reading the user's existing research
- Building a custom state machine when LangGraph was in the user's tool list
- Writing custom retry logic when Tenacity was in the user's tool list
- Writing custom circuit breaker logic when PyBreaker was in the user's tool list
- Testing with mocks that hide real behavior (`all_green: true` with 5/6 layers skipped)
- Claiming "133/133 tests pass" when 72% of requirements were untested
- Reporting alignment as "partially aligned" when entire stages were missing
- Not running the tools before declaring them complete
- Not cross-referencing the spec against the user's actual documented plans

---

END OF HANDOFF. Begin with Stage 0: Intake. Read all 9 context files listed in Section 1. Then proceed to Stage 1: Strategic Review using `pineapple:ceo-review`.
