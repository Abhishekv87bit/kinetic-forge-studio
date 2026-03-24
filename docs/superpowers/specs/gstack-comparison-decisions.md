# Pineapple Pipeline vs. gstack — Comparison Decisions

> **Date:** 2026-03-15
> **Context:** After reviewing Garry Tan's [gstack](https://github.com/garrytan/gstack) (14K+ stars), we compared its philosophy and architecture against the Pineapple Pipeline to identify what to keep, borrow, reject, and adapt for a single-developer context.
>
> **Key insight:** gstack is a prompt library encoding professional personas. Pineapple is a stage-gated engineering pipeline. They solve different problems but share a fundamental belief: **different tasks need different cognitive modes.**

---

## 1. What We Kept from Pineapple Pipeline (and Why)

### 1.1 Stage-Gated Pipeline (9 Stages: Intake through Evolve)

**Why keep it:** gstack has no pipeline — it's a bag of skills the user invokes manually. That works for Garry Tan's context (YC CEO, multiple engineers, PR-based workflow). For a single developer building mechanical systems end-to-end, we need the pipeline to enforce discipline that no team is providing. Without gates, we skip verification and ship broken geometry.

**gstack equivalent:** User-driven workflow (plan → implement → review → ship). No enforcement, no gates, no state tracking between stages.

**Why ours is better for us:** The verification stage (Stage 5) with 6 layers — unit tests, integration, adversarial, LLM eval, VLAD domain validation, visual inspection — catches failures that a diff-aware QA scan would miss entirely. Kinetic sculpture validation (gear mesh, friction cascades, tolerance stacking) has no equivalent in web app testing.

### 1.2 Template Library + Scaffolding (apply_pipeline.py)

**Why keep it:** gstack has no scaffolding — every project is configured manually. Our template library (11 templates: Docker, CI, middleware, cache, MCP) stamps a production-ready project in seconds. This is more valuable for a single developer who can't afford to set up infrastructure from scratch each time.

### 1.3 Bible-Based Gap Tracking

**Why keep it:** gstack has no state persistence between sessions beyond `.context/retros/`. Our bible system (production-pipeline-bible.yaml + kfs-bible-v2.yaml) provides a machine-readable source of truth for what's done, what's open, and what's verified. Critical for multi-session projects like KFS (25+ sessions).

**gstack equivalent:** `/retro` skill generates analytics snapshots in `.context/retros/`. Good for reflection, but not for tracking engineering gaps.

### 1.4 Multi-Model Support (Claude + Gemini + Groq)

**Why keep it:** gstack is single-model (Claude only), scaling via parallel sessions. We use Gemini for fast first-pass SCAD generation and Claude for physics verification — fundamentally different capabilities. This isn't about scaling; it's about using the right model for the right task.

### 1.5 Domain-Specific Validation (VLAD, Rule 99)

**Why keep it:** gstack's QA is web-focused (screenshots, console errors, broken links). Our domain validation — VLAD's 35 checks across 8 tiers, Rule 99's 14 consultants — is irreplaceable for mechanical engineering. No generic testing framework catches "planet gear mesh ratio produces non-integer tooth count."

### 1.6 Hookify Enforcement Gates (Coding Standards Only)

**Why keep it:** The existing 11 hookify rules enforce coding standards — verification evidence, gap closure evidence, etc. These apply regardless of whether the pipeline is running. gstack trusts the user; we need runtime enforcement because Claude can skip verification or claim "done" without evidence.

**What changed (ADR-PPL-14):** The originally planned 5 Pineapple-specific hookify gate rules (no-code-without-spec, no-merge-without-verify, etc.) were DROPPED. Pipeline flow enforcement is now solely owned by the orchestrator (ADR-PPL-04). Hookify handles coding standards; the orchestrator handles pipeline gates. One system per concern.

---

## 2. What We Borrowed from gstack (and Why)

### 2.1 Skills as Cognitive Modes (Not Workflow Steps)

**What gstack does:** Each skill (`/plan-ceo-review`, `/review`, `/ship`, `/qa`) represents a different professional persona — a different way of thinking. "Planning is not review. Review is not shipping."

**What we adapted:** Our superpowers skills already work this way (brainstorming, writing-plans, test-driven-development, systematic-debugging), but the Pineapple spec was starting to blur skills and stages. gstack reinforced the principle: **skills are cognitive modes, stages are workflow positions.** A skill can be used in multiple stages. A stage may invoke multiple skills.

**How this maps:** The spec's "Skills as orchestration, agents as execution" philosophy is correct but should be sharpened: skills are the *how-to-think*, stages are the *when-to-do-it*, agents are the *who-does-it*.

### 2.2 Simplicity as a Feature (Explicit Exclusions)

**What gstack does:** ARCHITECTURE.md has a "Notable Exclusions" section — things they deliberately did NOT build (no WebSocket, no MCP, no multi-user, no Windows support). Each exclusion has a rationale.

**What we adapted:** The staff engineer review found the pipeline spec was 80% aspirational. gstack's approach of documenting what you DON'T build is as important as what you do. Added "Scalability Constraints" section and `[IMPLEMENTED]`/`[PLANNED]` markers to the spec. Also adopted the principle: **if infrastructure isn't needed yet, don't build it.**

**Specific cuts inspired by gstack:**
- Dropped Neo4j requirement (component graph) from bootstrapping — deferred to Phase 7
- Dropped Mem0 requirement from bootstrapping — deferred to Phase 7
- Simplified `pineapple_doctor.py` required checks: Docker + hookify + templates + config. LangFuse/Mem0/Neo4j are optional.
- Removed "multi-developer" considerations from the spec entirely

### 2.3 Error Messages for AI, Not Humans

**What gstack does:** Playwright errors are rewritten to give Claude actionable next steps ("Element not found. Run `snapshot -i` to see available elements") instead of stack traces.

**What we adapted:** Pipeline tool error messages should follow this pattern. When `pineapple_verify.py` fails a layer, the output should say *what to do next* ("Layer 3 (security) failed: 2 new attack vectors passed guardrails. Run `pytest tests/test_adversarial.py -v` to see details. Then update `input_guardrails.py` patterns.") — not just "FAIL."

### 2.4 Diff-Aware Testing

**What gstack does:** `/qa` parses `git diff main` to identify affected routes, then tests only those. Practical, fast, focused.

**What we adapted:** Pineapple's Stage 5 (Verify) runs ALL 6 layers every time, which is thorough but slow. Borrowed the diff-aware concept for the Lightweight Path: if the change touches < 3 files and < 50 lines, run only affected test files (detected via `git diff` → map changed files → find corresponding test files). Full 6-layer verification reserved for Medium and Full paths.

### 2.5 Atomic File Operations (temp-file-then-rename)

**What gstack does:** Observability data written via temp file then `os.rename()` for atomicity. No corruption on crash.

**What we adapted:** Same pattern for `.pineapple/runs/<uuid>/state.json` and `.pineapple/verify/<branch>.json`. This was already in the plan (Tier 2) but gstack's implementation confirmed it's the right approach — simple, cross-platform, no locking needed.

### 2.6 Three-Tier Test Strategy (95% Free)

**What gstack does:** Tier 1 (static, free, <2s) catches 95% of issues. Tier 2 (E2E, $3.85, 20min) and Tier 3 (LLM judgment, $0.15, 30s) gate behind `EVALS=1`.

**What we adapted:** Pipeline self-tests should follow this tiering:
- **Tier 1 (free):** Template placeholder validation, Python syntax checks, config schema validation — runs on every commit via CI
- **Tier 2 (cheap):** `pytest` for pipeline tools — runs on every PR
- **Tier 3 (expensive):** E2E pipeline run through all 9 stages — runs manually before releases

---

## 3. What We Rejected from gstack (and Why)

### 3.1 No Central State Machine

**gstack's position:** No pipeline state, no run IDs, no state persistence. Each skill is stateless.

**Why we rejected this:** gstack serves a team workflow where GitHub (PRs, issues, reviews) IS the state machine. For a solo developer, there's no PR to track state. Our state machine (`.pineapple/runs/<uuid>/state.json`) replaces the GitHub-as-state-machine pattern that gstack relies on implicitly.

### 3.2 Browser-Based QA as Primary Testing

**gstack's position:** `/qa` and `/browse` use Playwright to screenshot pages, read console errors, and validate visually.

**Why we rejected this for primary testing:** Our domain is parametric CAD and mechanical engineering — the critical failures are geometric (non-manifold topology, gear interference, bearing misalignment), not visual (broken CSS, 404 links). Screenshot-based QA is useful for KFS's frontend but cannot replace VLAD's 35 structural checks.

**What we kept:** The concept is good for KFS's React/Three.js frontend. May add a `/browse`-style skill later for visual regression testing of the 3D viewport. But it's not a replacement for domain validation.

### 3.3 Conductor-Style Parallel Sessions

**gstack's position:** Scale via 10 parallel Claude Code sessions (Conductor), each with isolated workspace and browser.

**Why we rejected this:** Conductor requires a subscription service. More importantly, our Subagent-Driven Development (SDD) skill already handles parallel execution within a single session — fresh subagent per task, isolated context, two-stage review. SDD is free, requires no external service, and works within Claude Code's existing Agent tool.

**The real difference:** gstack's parallelism is across sessions (10 humans or 10 CI jobs). Ours is within a session (subagents). Different scaling axes.

### 3.4 Greptile Integration

**gstack's position:** External AI code review via Greptile, with learned false-positive history.

**Why we rejected this:** We already have two-stage review (spec compliance + code quality) via SDD reviewer subagents, plus the `superpowers:requesting-code-review` skill. Adding Greptile would be a third review layer for marginal benefit. Also, Greptile is a paid service — our review is built into the pipeline at zero cost.

### 3.5 macOS-Only Cookie/Browser Features

**Why we rejected this:** We're on Windows 11. gstack's cookie decryption is macOS Keychain only. The Playwright browser daemon is compiled for macOS/Linux. Not relevant to our environment.

### 3.6 No Enforcement ("Trust the Developer")

**gstack's position:** User decides when to invoke each skill. No gates, no blocks, no enforcement.

**Why we rejected this:** gstack is designed for experienced engineers at well-funded startups with peer review. We're a solo developer where Claude is both the builder and the reviewer. Without enforcement (hookify BLOCK rules), Claude can and does skip verification, claim completion without evidence, and close gaps without tests. We learned this the hard way across 25+ KFS sessions. Trust but verify — and we need the verify to be mandatory.

---

## 4. Skills vs. Orchestrator Decision

### The "Simplify, Remove Orchestrator" Argument (gstack's position)

gstack makes a compelling case: **an orchestrator is unnecessary overhead when a skilled user can switch cognitive modes manually.** Their 8 skills are independent — no skill depends on another, no state passes between them, no orchestrator coordinates them. The user IS the orchestrator.

**Strengths of this argument:**
- Simpler architecture (just Markdown files)
- No state machine to corrupt or debug
- No orchestrator bugs (the human doesn't have bugs in this sense)
- Each skill is independently testable and replaceable
- 14K+ stars validates the approach for their audience

### The "Multi-Model Across Systems Needs Orchestrator" Counter-Argument (our position)

Pineapple serves a different context:
- **Multi-model:** Claude for reasoning, Gemini for fast SCAD generation — these need coordination
- **Multi-system:** CadQuery engine, VLAD validator, FreeCAD MCP, OpenSCAD CLI — each is a separate system with its own failure modes
- **Multi-session:** Projects span 25+ sessions — state must persist and be resumable
- **No peer review:** Solo developer means the pipeline must enforce what a team would enforce socially

### What We Landed On

**Hybrid approach:** Skills for cognition, lightweight state machine for workflow, no heavy orchestrator.

1. **Skills remain cognitive modes** (brainstorming, TDD, debugging, code review) — borrowed from gstack's philosophy
2. **Stages remain workflow positions** (Intake through Evolve) — but stages are NOT skills, they're checkpoints
3. **The "master skill" from the original spec is DROPPED** — this was the orchestrator. Instead, the user (or a session prompt) decides which stage to work on, and skills handle execution within that stage
4. **State machine is lightweight** — JSON files, atomic writes, per-run UUIDs. Not a database, not a service, not a daemon. Just files.
5. **Gates are enforcement points, not orchestration** — hookify rules check that verification happened before merge, but they don't orchestrate the workflow

**How this maps to single-model vs multi-model:**
- **Single model (Claude only):** gstack's approach works — skills + user judgment. No orchestrator needed.
- **Multi-model (Claude + Gemini + domain tools):** Need a lightweight coordinator that knows which model to invoke for which subtask. This is NOT a heavy orchestrator — it's a routing table in the pipeline state machine.
- **Our case:** Multi-model + multi-system + multi-session = lightweight state machine + skills + hookify enforcement. No master skill, no heavy orchestrator.

---

## 5. Single-Developer Design Constraints

### What Being Solo Changes

| Concern | Team (gstack's context) | Solo (our context) |
|---------|------------------------|-------------------|
| Code review | Peers + Greptile | Self-review via subagents |
| Quality gates | PR approval requirements | Hookify BLOCK rules |
| State tracking | GitHub (PRs, issues) | Bible YAML + state machine |
| Cognitive switching | Different team members | Skills (prompts) |
| Parallel work | Conductor (10 sessions) | SDD subagents |
| Accountability | Team norms, standups | Enforcement gates |
| Knowledge transfer | Docs, onboarding | Session handoffs, MEMORY.md |

### Tradeoffs We Made Specifically for Solo Context

1. **Hookify is BLOCK, not WARN.** A team can rely on social pressure ("did you run the tests?"). Solo, the only pressure is enforcement. Default to BLOCK with `--prototype` override.

2. **Bible over GitHub Issues.** gstack assumes GitHub Issues + PRs for tracking. We use YAML bibles because they're machine-readable, session-resumable, and don't require GitHub round-trips. When we DO push to GitHub, the bible is the source of truth.

3. **Session handoffs are mandatory.** gstack's `/retro` is optional analytics. Our session handoffs are mandatory because there's no teammate to brief — the next session of Claude IS the teammate.

4. **Templates are aggressive.** gstack expects you to set up your own CI, Docker, etc. We stamp 11 templates because setup time is pure overhead for a solo developer. Every hour spent on boilerplate is an hour not spent on kinetic engineering.

5. **Verification is non-negotiable.** gstack's QA is a skill you invoke when you feel like it. Our verification (Stage 5) is a gate you cannot skip. Because nobody else will catch it.

### "People Need to See My Work" Consideration

This shaped several decisions:

- **GitHub as portfolio, not just version control.** Repos need professional READMEs, CI badges, proper descriptions — not just code dumps. This is why the GitHub reorganization happened.
- **Conventional commits + release-please.** Automated changelogs and semantic versioning make repos look professionally maintained even as a solo developer.
- **Public repos with real CI.** Green builds on public repos signal competence to recruiters. CI isn't just for catching bugs — it's proof of engineering discipline.
- **The profile README tells a story.** Not credentials, not certifications — the work itself, linked to real repos with real code.

---

## 6. Architecture Decision Records (ADRs)

> ADR-PPL-01 through ADR-PPL-03 exist in `production-pipeline-bible.yaml`

### ADR-PPL-04: Keep Lightweight Orchestrator (Reject gstack's "No Orchestrator")

**Context:** gstack demonstrated that skills-as-cognitive-modes with no central orchestrator works for experienced teams using GitHub PRs as implicit state. The counter-argument: a single developer coordinating multiple AI models (Claude + Gemini), multiple systems (CadQuery, VLAD, FreeCAD MCP, OpenSCAD), and multi-session projects (25+ sessions for KFS) needs something coordinating between them. The question was whether to build a heavy orchestrator or a lightweight one.

**Decision:** Keep the orchestrator, but make it lightweight — a master skill that reads pipeline state, suggests the next stage, and dispatches the right skills/agents. It does NOT auto-advance stages or make decisions autonomously. It presents options, the user decides. Think of it as a project manager who reads the board and says "here's what's next" — not an autopilot.

**Consequences:**
- (+) Multi-model routing has a single coordination point
- (+) Session resumption is automatic ("where were we?" answered by state machine + orchestrator)
- (+) New developers (or new Claude sessions) can pick up mid-pipeline without reading 5 files
- (-) Must build and maintain the master skill (additional complexity)
- (-) Must be careful it doesn't become a heavy framework that fights the user

### ADR-PPL-05: Skills Are Cognitive Modes, Not Workflow Steps

**Context:** gstack's core insight: "Planning is not review. Review is not shipping." Each skill encodes a different way of thinking. The Pineapple spec was conflating skills (how to think) with stages (when to act).

**Decision:** Separate skills from stages cleanly:
- **Skills** = cognitive modes (brainstorming, TDD, debugging, code review, systematic verification)
- **Stages** = workflow positions (Intake, Plan, Build, Verify, Ship, etc.)
- A skill can be used in multiple stages. A stage may invoke multiple skills.
- Skills are superpowers plugins. Stages are pipeline state transitions.

**Consequences:**
- (+) Skills are reusable across stages and even outside the pipeline
- (+) New skills don't require pipeline changes
- (+) Cleaner mental model
- (-) Must document which skills apply to which stages (done in spec)

### ADR-PPL-06: Lightweight State Machine Over GitHub-as-State

**Context:** gstack uses GitHub (PRs, issues, reviews) as implicit state tracking. This works for teams. For a solo developer, there's no PR workflow — work happens directly on branches or in worktrees.

**Decision:** Use `.pineapple/runs/<uuid>/state.json` as the source of truth for pipeline runs. JSON files, atomic writes, per-run UUIDs. Not a database, not GitHub Issues.

**Consequences:**
- (+) Works offline, no GitHub dependency for state
- (+) Machine-readable, resumable across sessions
- (+) Per-run isolation (two features don't share state)
- (-) Extra files to manage (mitigated by `pineapple_cleanup.py`)
- (-) No web UI for viewing state (acceptable — `jq` is sufficient)

### ADR-PPL-07: BLOCK Enforcement by Default

**Context:** gstack trusts developers to invoke the right skill at the right time. No enforcement. This works when experienced engineers have peer review. For a solo developer using Claude as both builder and reviewer, Claude can and does skip verification.

**Decision:** Hookify gate rules default to BLOCK (`action: stop`), not WARN. Pass `--prototype` to scaffold WARN-level rules for exploratory work.

**Consequences:**
- (+) Cannot ship without verification evidence
- (+) Cannot close gaps without test output
- (+) Catches Claude's tendency to claim "done" without proof
- (-) Slower for prototyping (mitigated by --prototype flag)
- (-) Hookify can break on plugin updates (mitigated by health checks in pineapple_doctor)

### ADR-PPL-08: Multi-Model Routing Over Single-Model Parallelism

**Context:** gstack scales via parallel Claude sessions (Conductor). One model, many instances. Pineapple uses multiple models (Claude, Gemini, Groq) for different tasks.

**Decision:** Keep multi-model routing. Claude for reasoning and verification. Gemini for fast first-pass code generation. Model selection based on task type, not load balancing.

**Consequences:**
- (+) Best model for each task (Gemini is faster for SCAD, Claude is better for physics)
- (+) Cost optimization (Gemini Flash is free for many tasks)
- (+) Resilience (if Claude credits deplete, Gemini continues)
- (-) More complex configuration (model costs, API keys, provider chain)
- (-) No single-vendor simplicity

### ADR-PPL-09: Diff-Aware Verification for Lightweight Path

**Context:** gstack's `/qa` parses `git diff main` to test only affected routes. Pineapple's Stage 5 runs all 6 verification layers regardless of change size.

**Decision:** Adopt diff-aware testing for the Lightweight Path only. Map changed files to corresponding test files. Run only affected tests. Full 6-layer verification reserved for Medium and Full paths.

**Consequences:**
- (+) 30-second verification for small changes (vs 5+ minutes for full suite)
- (+) Encourages frequent small commits (lower barrier to verify)
- (-) Could miss cross-file regressions on Lightweight Path (acceptable risk for <50 lines, <3 files)

### ADR-PPL-10: Document What You Don't Build

**Context:** gstack's ARCHITECTURE.md has "Notable Exclusions" — things deliberately not built, with rationale. The Pineapple spec was 80% aspirational with no markers distinguishing built from planned.

**Decision:** Every section of the spec must have `[IMPLEMENTED]` or `[PLANNED]` markers. Add a "Scalability Constraints" section explicitly stating what the pipeline is NOT designed for. Add "What This Spec Does NOT Cover" section.

**Consequences:**
- (+) Honest about current state — no one is misled
- (+) Readers know where to contribute vs what already works
- (+) Forces clarity about scope
- (-) Requires maintenance as things get implemented

### ADR-PPL-11: Per-Branch Verification Over Global File

**Context:** The original spec used a single `last_verify.json` file. The staff engineer review found this allows Feature A's verification to pass Feature B's merge gate. gstack doesn't have this problem because each PR has its own CI run.

**Decision:** Move verification records to `.pineapple/verify/<branch-name>.json` with integrity hashes (SHA256 of test output). Each branch must have its own verification record.

**Consequences:**
- (+) Parallel features can't share verification status
- (+) Integrity hash prevents spoofing (can't write fake JSON without running tests)
- (+) Hookify gate checks branch-specific file
- (-) More files to manage (mitigated by pineapple_cleanup)

### ADR-PPL-12: Error Messages Target AI Agents

**Context:** gstack rewrites Playwright errors to give Claude actionable next steps instead of stack traces. "Element not found → Run `snapshot -i` to see available elements."

**Decision:** All pipeline tool error messages must include: (1) what failed, (2) why it likely failed, (3) what command to run next. Target the AI agent as the primary reader, not the human.

**Consequences:**
- (+) Claude can self-recover from common failures without human intervention
- (+) Session logs are more useful (actionable errors vs cryptic traces)
- (-) Slightly more verbose error handling code

### ADR-PPL-13: Security — Fail Closed, Not Open

**Context:** gstack's security is lightweight (localhost-only, bearer tokens, no background services). Pineapple's `input_guardrails.py` had a fail-open bug: if the middleware itself errors, the request passes through unfiltered.

**Decision:** Change guardrails to fail-closed. If the security check itself fails, return HTTP 500, don't pass the request through. gstack's "no background services" principle also applies — avoid running services we don't actively need (Neo4j, Mem0 deferred to Phase 7).

**Consequences:**
- (+) ReDoS attack on guardrail regex = request blocked, not passed through
- (+) Simpler bootstrapping (fewer required services)
- (-) False positives from guardrail bugs block legitimate requests (acceptable — fix the guardrail)

### ADR-PPL-14: Drop Pineapple Hookify Gates — Orchestrator Owns Pipeline Enforcement

**Context:** The 5-tier implementation plan called for 5 new Pineapple-specific hookify gate rules (no-code-without-spec, no-impl-without-plan, no-merge-without-verify, no-completion-without-evidence, no-gap-closure-without-verify). These rules overlap almost entirely with what the orchestrator (ADR-PPL-04) already enforces by refusing to advance stages without gate conditions met.

**Decision:** Drop the 5 planned Pineapple hookify gate rules. The orchestrator is the single owner of pipeline flow enforcement. Keep the existing 11 hookify rules (they enforce coding standards like verification evidence, not pipeline flow).

**Rationale:**
- Every gate the 5 rules would enforce is exactly what the orchestrator does by design
- Two enforcement layers (hookify + orchestrator) = double maintenance, conflicting failure modes
- Hookify on Windows is fragile (plugin updates overwrite cache patches, settings.json registration)
- If working outside the pipeline, pipeline-specific hookify gates are irrelevant anyway
- If the orchestrator is bypassed for quick work and bad habits emerge, hookify gates can be added as a corrective measure — not preemptively

**Consequences:**
- (+) Removes an entire tier of planned work (Tier 3 hookify rules)
- (+) Single enforcement system to maintain and debug
- (+) No more "which system blocked me?" confusion
- (-) Working outside the pipeline has no pipeline enforcement (acceptable — pipeline rules don't apply outside the pipeline)
- (-) If orchestrator has a bug in gate checking, no backup catches it (acceptable — fix the orchestrator)

### ADR-PPL-15: CEO Skill — Project-Agnostic Strategic Review

**Context:** The pipeline had a gap between human research (Stage 0: INTAKE) and architecture (Stage 1: BRAINSTORM). The brainstorming skill asks "HOW to build" but nobody asks "SHOULD we build this? What's the REAL product? What should we cut?" gstack's `/plan-ceo-review` skill fills this role for startups but is use-case-specific. We need a project-agnostic version.

**The used-car-lot principle:** A used car lot thinks it sells cars. Actually it sells financing, extended warranties, and peace of mind. The CEO skill's job is to find the REAL product hidden inside the obvious product — the underlying objectives and value drivers that the builder hasn't identified.

**Decision:** Create a CEO skill that operates between INTAKE and ARCHITECTURE. It is:
- **Project-agnostic:** Works for SaaS, portfolio projects, open-source tools, creative projects, learning exercises — anything
- **Breadth-first:** Leverages the LLM's cross-domain training data to ask questions the human wouldn't think to ask (epidemiology for cascade failures, game design for UX patterns, watchmaking for gear trains)
- **Strategic, not tactical:** Finds the core value, identifies what to cut, surfaces hidden assumptions. Does NOT go into architecture — that's the next stage's job
- **Dialogue-driven:** 5-7 probing questions, iterative, dispatches Fact-Finding Agent when data is needed
- **Output:** A Strategic Brief — not a spec, not architecture. Just: what we're building, why, what we're NOT building, what the REAL product is, and what questions remain

**The CEO's core capabilities:**
1. Find the hidden product (not the apparent one)
2. Identify underlying value drivers for ALL parties involved
3. Ask questions the human can't (cross-domain pattern matching from LLM breadth)
4. Drive toward the 10-star version, then scale back to achievable
5. Challenge scope: "What's the version that works in 1/10th the effort?"
6. Surface hidden assumptions: "You're assuming X. What if X isn't true?"

**Consequences:**
- (+) Ideas are strategically filtered before architecture begins — less wasted work
- (+) Cross-domain insights that no human specialist would surface
- (+) Forces explicit scoping and prioritization before any code
- (+) Project-agnostic — works for any project type
- (-) Adds a stage to the pipeline (acceptable — it's the most valuable stage)
- (-) Depends on LLM quality for cross-domain connections (mitigated by Fact-Finding Agent for data)

### ADR-PPL-16: Fact-Finding Agent — Research on Demand

**Context:** During the CEO skill's strategic dialogue, questions arise that need real data, not opinion. "Are there existing solutions?" "What's the state of the art?" "What tools exist?" Currently the human context-switches to NotebookLLM, web browsers, or other research tools to find answers. This breaks flow.

**Decision:** Create a Fact-Finding Agent that the CEO skill dispatches when a question needs research. It searches the web, reads docs, evaluates existing solutions, and returns structured findings back into the CEO dialogue.

**How it relates to human research:**
- Human research (NotebookLLM, videos, web browsing) = what happens BEFORE the pipeline, at their own pace
- Fact-Finding Agent = what happens DURING the CEO dialogue, on demand, without context-switching
- They complement each other — the agent doesn't replace human research, it augments it in real-time

**Capabilities:**
- Search for existing solutions and competitors
- Read documentation, papers, repos
- Summarize the state of the art in a domain
- Identify potential tools, libraries, frameworks
- Find post-mortems and lessons learned from similar projects
- Return structured findings (not raw search results)

**Consequences:**
- (+) CEO dialogue doesn't stall while human researches
- (+) Reduces context-switching between tools
- (+) Structured findings feed directly into strategic decisions
- (-) Web search quality varies (mitigated by human verification of findings)
- (-) Adds latency to CEO dialogue when dispatched (acceptable — research takes time regardless)

### ADR-PPL-17: Pipeline Stages Must Include Human Workflow

**Context:** The pipeline spec is almost entirely agent-centric — it describes what Claude Code does at each stage. But the real workflow is human + agent. The human does research, feeds context, makes decisions at gates, brings domain knowledge the agent doesn't have. This was undocumented.

**Decision:** Every pipeline stage must define BOTH the human role and the agent role. The pipeline is not "what the AI does" — it's "what WE do" where WE = human + agent.

**Human actions across the pipeline:**
- Stage 0 INTAKE: Human has the spark, does initial research (NotebookLLM, videos, web)
- Stage 1 STRATEGIC REVIEW: Human answers CEO skill's questions, provides domain context
- Stage 2 ARCHITECTURE: Human approves design decisions, provides constraints
- Stage 3 PLAN: Human reviews and approves implementation plan
- Stage 4 SETUP: Human approves worktree/branch setup
- Stage 5 BUILD: Human provides clarifications, answers agent questions
- Stage 6 VERIFY: Human reviews verification results
- Stage 7 REVIEW: Human makes final go/no-go decision
- Stage 8 SHIP: Human approves merge
- Stage 9 EVOLVE: Human reviews session handoff, provides corrections

**Consequences:**
- (+) Pipeline is honest about what it actually takes to build something
- (+) Orchestrator knows what to ask the human at each stage
- (+) Onboarding someone to the pipeline includes their role, not just the agent's
- (-) Pipeline is no longer "fully automated" in description (it never was — now it's honest)

### ADR-PPL-18: Restructured Stage Map — Strategic Review Between Intake and Architecture

**Context:** The original 9-stage pipeline (Intake → Brainstorm → Plan → Setup → Build → Verify → Review → Ship → Evolve) had no strategic filtering. An idea went from raw intake directly to architecture. This meant architecture was done on unvetted ideas, leading to scope creep and wasted work.

**Decision:** Insert a STRATEGIC REVIEW stage between INTAKE and the existing stages. Rename BRAINSTORM to ARCHITECTURE for clarity. The new stage map:

| # | Stage | Primary Actor | Purpose |
|---|-------|--------------|---------|
| 0 | INTAKE | Human | Spark + raw research (NotebookLLM, web, videos) |
| 1 | STRATEGIC REVIEW | CEO Skill + Fact-Finding Agent | Find the real product, scope, prioritize, strategic brief |
| 2 | ARCHITECTURE | Brainstorming skill | Design the solution (components, data flow, interfaces) |
| 3 | PLAN | Writing-plans skill | Implementation steps, task breakdown |
| 4 | SETUP | Orchestrator | Worktree, branch, scaffold |
| 5 | BUILD | SDD / executing-plans | Code, test, commit |
| 6 | VERIFY | pineapple_verify.py | 6-layer verification with signed records |
| 7 | REVIEW | Code review skills | Spec compliance + code quality |
| 8 | SHIP | Orchestrator + human | Merge, bible update, release |
| 9 | EVOLVE | pineapple_evolve.py + human | Session handoff, knowledge extraction |

**Key change:** Stage count goes from 9 to 10 (0-9). BRAINSTORM renamed to ARCHITECTURE. New STRATEGIC REVIEW (Stage 1) inserted.

**Consequences:**
- (+) Ideas are strategically vetted before architecture work begins
- (+) Clearer stage names (ARCHITECTURE vs BRAINSTORM)
- (+) Human workflow explicitly represented (INTAKE is human-primary)
- (-) State machine needs update for new stage (pipeline_state.py PipelineStage enum)
- (-) Spec needs restructuring (acceptable — spec is the source of truth, must be accurate)

---

## Summary Matrix

| Area | gstack | Pineapple | Decision |
|------|--------|-----------|----------|
| Philosophy | Skills = personas | Skills = orchestration + agents = execution | **Adapted:** Skills = cognition, stages = workflow, agents = execution |
| Orchestration | None (user decides) | Master skill orchestrator | **Kept ours:** lightweight orchestrator (reads state, suggests next, user decides) |
| State | Stateless (GitHub is state) | JSON state machine | **Kept ours:** solo dev needs explicit state |
| Testing | Diff-aware QA + screenshots | 6-layer verification | **Kept ours + borrowed:** diff-aware for Lightweight Path |
| Security | Lightweight (localhost + tokens) | Heavyweight (guardrails + hookify) | **Kept ours:** fail-closed, BLOCK default |
| Enforcement | Trust the user | Hookify (standards) + Orchestrator (pipeline) | **Split:** hookify for coding standards, orchestrator for pipeline gates (ADR-PPL-14) |
| Parallelism | Conductor (10 sessions) | SDD subagents | **Kept ours:** free, no external service |
| Models | Single (Claude) | Multi (Claude + Gemini + Groq) | **Kept ours:** right model for right task |
| Scaffolding | None | 13 templates + apply_pipeline.py | **Kept ours:** solo dev needs automation |
| Error messages | AI-targeted | Generic | **Borrowed:** all tools now target AI agents |
| Exclusions | Documented | Not documented | **Borrowed:** added markers + constraints section |
| Code review | Greptile + peers | SDD subagents + hookify | **Kept ours:** zero cost, built-in |
| Strategic review | /plan-ceo-review (startup-specific) | None (gap) | **Borrowed + adapted:** CEO skill, project-agnostic (ADR-PPL-15) |
| Research | No built-in | No built-in | **New:** Fact-Finding Agent dispatched by CEO (ADR-PPL-16) |
| Human workflow | Implicit (team handles it) | Undocumented | **New:** Every stage defines human + agent roles (ADR-PPL-17) |
| Stage count | N/A (no stages) | 9 stages (0-8) | **Updated:** 10 stages (0-9), Strategic Review inserted (ADR-PPL-18) |
