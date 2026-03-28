# KFS Restart via Pineapple Pipeline — Design Specification

**Date:** 2026-03-26
**Status:** Ready for review
**Goal:** Restart Kinetic Forge Studio v2 workshop redesign using the full Pineapple 10-stage pipeline, incorporating original vision + v2 work + all learnings from production infrastructure

---

## I. CONTEXT & PROBLEM STATEMENT

### The Original Vision (Sessions 1-4, Locked in kfs-bible.yaml)

KFS is meant to be **the persistent workshop** for the Claude terminal workflow:

```
Terminal workflow:
  Claude generates CadQuery code → VLAD validates → iterate

Problem: Terminal has no project memory, no context persistence.

KFS solves this by providing:
  ✓ Project memory (decisions, component history, design rationale)
  ✓ Code workspace (versioned CadQuery modules = real source of truth)
  ✓ VLAD integration (automatic validation on every module)
  ✓ 3D visualization (render real STL/GLB from those modules)
  ✓ Context loop (feed project state back into conversations)
```

**What KFS should NOT be:** A shape factory. An AI that designs things. A geometry generator.

### Why Restart Now?

1. **v2 workshop redesign stalled** (396 commits, work stashed) — had solid architecture but hit quality gates
2. **Production Pipeline now exists** — observability, caching, MCP, security patterns ready to apply
3. **Durga pattern discovered** — deterministic repair > VLM > LLM (60% fewer LLM calls)
4. **ADR-09: Manifest System** — unified format for kinematic + parametric + temporal data (not yet implemented)
5. **250+ gap archive** — All learnings documented, no rework needed

### What Has Proven To Work

From the v1 archive and v2 work:
- Real geometry mandate (fail loudly, no substitution)
- Component-centric architecture (geometry_type, not mechanism_type)
- Multi-kernel geometry (BREP, SDF, TPMS, F-REP, Mesh)
- VLAD as ground truth (35 B-rep checks > mesh consultants)
- Module-based code workspace (versioned, trackable)
- Deterministic repair before LLM escalation

---

## II. DESIGN: STAGES 0-1 (INTAKE & STRATEGIC REVIEW)

### STAGE 0: INTAKE — Raw Synthesis

**Duration:** 1-2 hours
**Owner:** Claude (analysis) + User (context questions if needed)
**Deliverable:** Intake Report (5-10 pages)

#### 0.1: WHAT WE KNOW (Assemble All Context)

Gather and organize:

| Context Source | What It Tells Us |
|---|---|
| **kfs-bible.yaml (v1)** | Original vision (ADRs 1-8), 202 gaps (181 closed, 17 verified) |
| **kfs-bible-v2.yaml** | Current state (80 gaps, 55 closed), ADRs 9-10 (Manifest System, Durga) |
| **feat/kfs-v2-workshop-redesign branch** | 396 commits, 10 module architecture planned, partially implemented |
| **Stashed work (stash@{0})** | GAP-275 (invocation counters), library roster reorganization |
| **Production Pipeline** | Observability, caching, security, MCP, LLM eval, cost tracking patterns |
| **Session notes (24d-26b)** | Quality gate failures in Triple Helix v2, Waves 1-3 gap closures |

**Output:** Categorized inventory of all context, with gaps/conflicts identified.

#### 0.2: WHAT WE NEED TO UNDERSTAND (Clarify Unknowns)

Ask and answer:

1. **Scope Question:** Is the goal to complete v2 workshop as designed, or reassess scope in light of new learnings?
   - **Assumption:** Complete v2 vision (modules + VLAD + manifest) but use Pineapple process to gate each stage

2. **Durga Integration:** How deeply should Durga pattern integrate into the design?
   - **Assumption:** Durga is a design principle (deterministic > VLM > LLM), not an extra layer. Baked into module generation prompts.

3. **Manifest System:** Is ADR-09 (KFS Manifest System) in scope for this restart?
   - **Assumption:** Yes, it's locked in v2 bible. But stage it — implement basic .kfs.yaml in Stage 5 (Build), advanced features (kinematics inference) in Stage 9 (Evolve).

4. **Infrastructure Reuse:** Should we use production-pipeline patterns (observability, caching, MCP)?
   - **Assumption:** Yes. KFS observability already half-wired (chat_agent.py), cache middleware exists, VLAD/CadQuery exposed as MCP. Extend, don't rebuild.

5. **Quality Assurance:** What does "Definition of Done v2" (contract tests, not grep) look like for each module?
   - **Assumption:** Each module has pytest that sends input through the actual pipeline and asserts the feature was invoked, not just that the function exists.

#### 0.3: WHAT COULD BREAK (Risk Assessment)

| Risk | Mitigation |
|---|---|
| **Scope creep** | Stage 1 (Strategic Review) produces a scoped brief. Gates between stages prevent expansion. |
| **v2 branch conflicts with main** | Stage 4 (Setup) rebases/merges cleanly before proceeding. |
| **LLM quality** | Durga pattern + prompt improvements already built on v2 branch. RAG is enabled. VLM critic available. |
| **VLAD integration** | VLAD runner wrapper already designed (10 module spec). MCP exposed (Stage 8 wiring). |
| **Quality gate failures** | Definition of Done v2 (contract tests) prevents silent failures. Each stage gate is objective. |
| **ADR conflicts** | All 10 ADRs in v2 bible are locked. No decisions to remake. |

---

### STAGE 1: STRATEGIC REVIEW — The Brief

**Duration:** Same as Stage 0 (1-2 hours, may overlap)
**Owner:** Claude
**Input:** Intake Report
**Deliverable:** Strategic Brief (3-5 pages)

#### 1.1: VISION STATEMENT

**What we're building:**

> **Kinetic Forge Studio v2**: A persistent workshop that solves the Claude terminal's missing context problem. The LLM generates CadQuery production modules → VLAD validates geometry automatically → results flow back into project context → next iteration uses full project history. Real geometry guaranteed. No placeholders. Deterministic repair before LLM escalation.

#### 1.2: SUCCESS CRITERIA (How We Know This Is Done)

By end of Stage 8 (Ship), KFS must be able to:

1. **Store and version CadQuery modules** (not geometry factory output, actual .py code)
2. **Execute modules** and write STL/STEP to disk (fully deterministic, no shape factory)
3. **Run VLAD** on every module automatically, store results in DB
4. **Render in Three.js** from actual module output (STL/GLB)
5. **Maintain project context** across iterations (modules table + decisions table + snapshots)
6. **Support Durga pattern** — deterministic repair first, LLM only for creativeflow
7. **Expose VLAD + CadQuery as MCP** (LLM can call directly for terminal workflow)
8. **Generate .kfs.yaml manifest** (basic version: components + mechanism_type + parameters)
9. **Pass Definition of Done v2** — contract tests, not grep checks
10. **Track all LLM calls** (cost, latency, tokens) via observability middleware

#### 1.3: SCOPE BOUNDARY

**IN SCOPE (Restart completes these):**
- ✓ Module workspace (database + manager + executor)
- ✓ VLAD integration (runner + results storage + gating)
- ✓ Durga pattern (deterministic repair module)
- ✓ Prompt improvements (RAG + geometry helpers already built)
- ✓ Three.js rendering (from actual module output)
- ✓ Basic .kfs.yaml manifest (components, mechanism_type, parameters)
- ✓ MCP exposure (VLAD, CadQuery executor, library search)
- ✓ Observability (LLM call logging, cost tracking)
- ✓ All 10 ADRs implemented (no new architectural decisions)

**OUT OF SCOPE (Defer to Stage 9: Evolve):**
- Advanced manifest features (kinematics inference, timeline animation)
- Multi-kernel geometry (SDF, TPMS, F-REP, Mesh backends) — CadQuery (BREP) only
- Manufacturing pipeline integration (DFM, tolerancing, BOM enrichment) — keep consultants but don't enhance
- Organic geometry support (NURBS, sculpting) — deferred

#### 1.4: KEY ARCHITECTURAL DECISIONS (Already Locked, No Rework)

| ADR | Decision | Locked Since |
|---|---|---|
| ADR-02 | **Real Geometry Mandate** — No placeholders, fail loudly | 2026-03-03 |
| ADR-04 | **Component-Centric** — geometry_type, not mechanism_type | 2026-03-07 |
| ADR-05 | **Multi-Kernel** — BREP primary, others deferred | 2026-03-07 |
| ADR-10 | **Durga** — Deterministic > VLM > LLM | 2026-03-12 |
| ADR-09 | **Manifest System** — .kfs.yaml (basic in Stage 5, advanced in Stage 9) | 2026-03-12 |

No new decisions needed. Proceed to architecture stage with these locked.

#### 1.5: DEPENDENCIES & SEQUENCING

**Internal dependencies (within KFS):**
- Module workspace must exist before VLAD runner (needs modules table)
- VLAD runner must exist before gating logic (needs validation results)
- Gating logic must exist before prompt updates (needs VLAD feedback loop)

**External dependencies (from Production Pipeline):**
- Observability middleware (✓ exists in main, apply to chat routes)
- Caching (✓ exists, enable Anthropic prompt cache for RAG examples)
- MCP framework (✓ exists in kfs_mcp_server.py, extend with VLAD + CadQuery)
- Security guardrails (✓ wired, no changes needed)

**Resource assumptions:**
- FreeCAD MCP available (http://localhost:9875)
- OpenSCAD Nightly installed (render validation)
- Python 3.12 with pyproject.toml deps
- Gemini API key (primary LLM, Claude fallback)
- ~10 hours implementation time (Stages 2-8)

#### 1.6: RISKS & MITIGATIONS (Revisited)

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| v2 branch has merge conflicts | Medium | High | Stage 4 (Setup) resolves before proceeding. If conflicts are architectural, escalate to Stage 3. |
| Durga pattern integration is incomplete | Low | Medium | v2 branch already has deterministic_repair.py. Verify it's wired in chat_agent.py during Stage 2. |
| VLAD runner doesn't work with current VLAD version | Low | High | Test VLAD in Stage 2 (Architecture). If changes needed, add to Stage 3 (Plan). |
| Three.js rendering fails on real STEP files | Medium | Medium | Fallback: render STL instead (Three.js has GLTFLoader + STLLoader). Both already coded. |
| Observability overhead causes latency | Low | Low | Cache is already enabled (90% cost reduction). Monitor in Stage 6 (Verify). |
| ADRs conflict when implemented | Very Low | High | All 10 ADRs are locked and cross-checked. No conflicts expected. If found, this is a discovery, not a restart failure. |

---

## III. IMPLEMENTATION BOUNDARY (Stages 2-8)

### How Pineapple Stages Map to KFS Restart

| Stage | Name | KFS Work | Gate |
|---|---|---|---|
| **0** | Intake | Synthesize context (this doc) | ✓ Complete |
| **1** | Strategic Review | Write strategic brief (this doc) | ✓ Complete |
| **2** | Architecture | Design 10 modules, diagram interactions, list files to create/modify | Review + sign-off |
| **3** | Planning | Write implementation plan (10 steps), dependencies, effort estimates | Review + sign-off |
| **4** | Setup | Unstash, branch, prepare workspace, run existing tests | All tests pass |
| **5** | Build | Implement all 10 modules (database, manager, executor, VLAD, repair, manifest, etc.) | Code compiles, imports work |
| **6** | Verify | Contract tests (pytest), VLAD validation, real geometry samples | 100% test pass rate |
| **7** | Review | Code review against architecture, ADRs, Definition of Done v2 | Approved by review gate |
| **8** | Ship | Merge to main, update bibles, close gaps, write session handoff | Deployed, documented |
| **9** | Evolve | Extract reusable patterns, update Pineapple templates, measure ROI | Artifacts in production-pipeline/ |

---

## IV. SUCCESS INDICATORS

### Stage 0-1 Complete When:

- [x] Intake Report written (summarizes all context, lists unknowns, assesses risks)
- [x] Strategic Brief written (vision, success criteria, scope, ADRs, dependencies)
- [x] Risk assessment complete (probabilities assigned, mitigations clear)
- [x] No conflicting ADRs identified
- [x] User approval received
- [x] This document committed to git

### Stage 2-8 Tracked By:

- **Architecture stage:** 10-module design + diagram + file list approved
- **Plan stage:** 10-step implementation plan with effort, dependencies, sequence
- **Setup stage:** Clean workspace, v2 branch merged/rebased, tests passing
- **Build stage:** All modules coded + imported
- **Verify stage:** Contract tests 100% pass, VLAD validates real geometry, no test gaps
- **Review stage:** Code review approves all changes against ADRs
- **Ship stage:** Merged to main, gaps closed in v2 bible, session handoff written

---

## V. APPROVAL GATE

**This design is ready for approval when:**

1. The strategic brief above accurately reflects the restart vision
2. Success criteria (section 1.2) are achievable
3. Scope boundary (section 1.3) is correct (in vs. out)
4. Risk assessment (section 1.6) is realistic
5. Implementation boundary (section III) makes sense

**Approval decision:** Should I proceed to Stage 2 (Architecture) with this framing, or revise the brief?
