# NotebookLM Prompt: Pineapple Pipeline v2 Rebuild Plan

## Sources to Upload

Upload ALL of these as NotebookLM sources:

1. `D:\ai-agent-mastery-plan\NOTEBOOKLM_PROMPT.md` — 26-tool directory, 7 Permanent Problems, 8-week curriculum
2. `D:\ai-agent-mastery-plan\NOTEBOOKLM_AI_ENGINEER_MASTERCLASS.md` — AI engineer transition guide
3. `D:\ai-agent-mastery-plan\NOTEBOOKLM_BROKERFLOW_WALKTHROUGH.md` — real project through all 9 stages
4. `D:\GitHub\pineapple-pipeline\DOGFOOD_REPORT.md` — what went wrong with v1
5. `d:\Claude local\docs\superpowers\skills\pineapple\SKILL.md` — 10-stage orchestrator (process to keep)
6. `d:\Claude local\docs\superpowers\skills\pineapple\ceo-review.md` — CEO strategic review skill
7. `d:\Claude local\docs\superpowers\specs\2026-03-15-pineapple-pipeline-design.md` — v1 spec (the one that was wrong)
8. `d:\Claude local\3d_design_agent\sessions\2026-03-20-pineapple-restart-handoff.md` — restart handoff with lessons

---

## Prompt -- Paste This Into NotebookLM

---

Create a comprehensive presentation (25-30 slides) for the Pineapple Pipeline v2 Rebuild Plan. The audience is ME -- I'm using this to understand and approve the rebuild before starting. Use ALL uploaded sources as ground truth.

The story arc: "We built v1 from scratch, dogfooded it, and discovered the spec ignored my own learning plan. Here's what we keep, what we kill, and how v2 uses the 26 tools I already chose."

### SECTION 1: WHAT HAPPENED (4 slides)

Slide 1 -- Title: "Pineapple Pipeline v2: Rebuild on Real Foundations"
- Subtitle: "Kill the custom code. Keep the process. Use the tools you already chose."

Slide 2 -- "The v1 Story"
- Built a 10-stage pipeline with 10 CLI tools, 13 templates, 288 tests
- Dogfooded it: found 17 gaps, fixed them, got to 288 passing tests
- Then discovered: the spec was written WITHOUT reading the learning plan
- The spec reinvented 8+ libraries that were already in the 26-tool directory
- Diagram: show the v1 architecture with red X marks on every custom component

Slide 3 -- "What the Dogfood Actually Found"
- Surface level: 2 dead hookify rules, false-green tests, SKILL.md misalignment
- Real level: the SPEC was the bug, not the code
- We verified implementation vs spec, but never spec vs learning plan
- 10 lessons learned (list all 10 from the handoff)

Slide 4 -- "The 11 Reinvented Wheels"
- Table showing: Custom Code | Lines | Library It Should Have Used
- pipeline_state.py (283 lines) → LangGraph
- Retry counters → Tenacity
- resilience.py circuit breaker (216 lines) → PyBreaker
- Raw HTTP Mem0 stubs → Mem0 SDK
- Raw HTTP Neo4j stubs → Neo4j driver
- Manual cost tracking → LangFuse SDK
- No structured outputs → Instructor
- No LLM eval → DeepEval
- No RAG eval → RAGAS
- No prompt optimization → DSPy
- No vector search → ChromaDB
- "Every custom line was a stolen learning opportunity"

### SECTION 2: WHAT WE KEEP (3 slides)

Slide 5 -- "The Process is Sound"
- 10-stage pipeline diagram (Intake through Evolve)
- 3 path routing (Full/Medium/Lightweight)
- Gate definitions per stage
- This is PROVEN -- dogfood validated the process works
- Show the state machine flow with circuit breaker

Slide 6 -- "Architectural Principles (Battle-Tested)"
- Orchestrator rule: Claude coordinates, never writes code directly
- Separation of concerns: builder != verifier != reviewer (3 independent agents)
- Grep is NEVER verification -- run it, don't read it
- False confidence is worse than no confidence
- The spec is the most dangerous artifact to get wrong

Slide 7 -- "Artifacts Worth Keeping"
- SKILL.md (238 lines) -- the orchestrator
- ceo-review.md (148 lines) -- strategic review skill
- 5 hookify enforcement rules (all working)
- 13 production templates (Docker, CI, middleware)
- 288 tests as behavioral specifications
- DOGFOOD_REPORT.md as the reference for what NOT to do

### SECTION 3: THE 26-TOOL FOUNDATION (5 slides)

Slide 8 -- "The 7 Permanent Problems → 26 Tools"
- From NOTEBOOKLM_PROMPT.md: map each problem to its tools
- Problem 1 (Think): LangGraph, Anthropic API
- Problem 2 (Remember): Mem0, Neo4j, ChromaDB
- Problem 3 (Act): FastAPI, FastMCP, Anthropic SDK
- Problem 4 (Coordinate): LangGraph, Instructor
- Problem 5 (Verify): pytest, DeepEval, RAGAS
- Problem 6 (Protect): Pydantic, PyBreaker, Tenacity, SlowAPI
- Problem 7 (Improve): DSPy, LangFuse, Unsloth
- Show this as a matrix diagram

Slide 9 -- "Tools Mapped to Pipeline Stages"
- Matrix: 10 stages (rows) x 26 tools (columns)
- Stage 0 Intake: Pydantic (validation)
- Stage 1 Strategic Review: Anthropic API, Instructor
- Stage 2 Architecture: LangGraph (state design), Pydantic (contracts)
- Stage 3 Plan: Instructor (structured output)
- Stage 4 Setup: Docker, FastAPI scaffolding
- Stage 5 Build: Anthropic API, Tenacity (retries), LangFuse (tracing)
- Stage 6 Verify: pytest, DeepEval, RAGAS, PyBreaker
- Stage 7 Review: Anthropic API, Instructor
- Stage 8 Ship: Docker, GitHub Actions, FastMCP
- Stage 9 Evolve: Mem0, Neo4j, DSPy, ChromaDB, LangFuse

Slide 10 -- "LangGraph as the Backbone"
- Replace pipeline_state.py with LangGraph state graph
- Each stage is a node in the graph
- Transitions are edges with gate conditions
- Built-in: persistence, retry, checkpoint/resume, parallel execution
- Diagram: LangGraph state graph with 10 nodes, showing the circuit breaker loop as a conditional edge
- "283 lines of custom code replaced by a library designed for exactly this"

Slide 11 -- "The Resilience Stack"
- Tenacity: retry any function with exponential backoff (decorator-based)
- PyBreaker: circuit breaker on external service calls
- Pydantic: validate every data boundary
- LangFuse: trace every LLM call, track costs, monitor latency
- "These are battle-tested by thousands of production systems. Our custom code was tested by us."

Slide 12 -- "The Intelligence Stack"
- Instructor: force Claude outputs into Pydantic models (no more "AI gibberish")
- DeepEval: evaluate LLM output quality (not just "did the code run")
- RAGAS: evaluate retrieval quality (when we add RAG)
- DSPy: automatically optimize prompts using metrics
- Mem0: automatic memory extraction across sessions
- "Each tool solves one problem well. We don't need to reinvent any of them."

### SECTION 4: THE v2 ARCHITECTURE (4 slides)

Slide 13 -- "v2 Architecture Overview"
- Diagram: 3-layer architecture
  - Layer 1: LangGraph (orchestration backbone)
  - Layer 2: Tool integrations (26 tools plugged into graph nodes)
  - Layer 3: Claude Code (the brain -- orchestrates via SKILL.md)
- Show data flow: User request → SKILL.md → LangGraph → Stage nodes → Tools → Output

Slide 14 -- "v2 vs v1: What Changes"
- Side-by-side comparison table:
  | Component | v1 (Custom) | v2 (Library) |
  | State machine | pipeline_state.py | LangGraph |
  | Retries | Custom counters | Tenacity decorators |
  | Circuit breaker | Custom FSM | PyBreaker |
  | Cost tracking | pipeline_tracer.py | LangFuse SDK |
  | LLM outputs | Raw text | Instructor + Pydantic |
  | LLM evaluation | Skipped | DeepEval |
  | Memory | HTTP stubs | Mem0 SDK |
  | Knowledge graph | HTTP stubs | Neo4j driver |
  | Prompt optimization | None | DSPy |
- "Same process. Better tools. Less code. More learning."

Slide 15 -- "What v2 Code Looks Like"
- Show pseudocode for the pipeline using LangGraph:
```python
from langgraph.graph import StateGraph
from tenacity import retry, stop_after_attempt
from instructor import from_anthropic
from langfuse import Langfuse

# Define pipeline as a state graph
pipeline = StateGraph(PipelineState)
pipeline.add_node("intake", intake_node)
pipeline.add_node("strategic_review", strategic_review_node)
pipeline.add_node("architecture", architecture_node)
# ... etc
pipeline.add_conditional_edges("review", circuit_breaker)
pipeline.compile()
```
- "The entire state machine is now a graph definition, not 283 lines of custom code"

Slide 16 -- "The Separation Principle in v2"
- 3 agent types, completely independent:
  1. Builder agents (Stage 5) -- write code, commit. CANNOT run tests.
  2. Verifier agents (Stage 6) -- fresh context, read code cold. CANNOT have built it.
  3. Reviewer agents (Stage 7) -- review full diff. CANNOT have built or verified.
- Diagram: Orchestrator dispatching to 3 separate agent pools with firewalls between them
- "Confirmation bias is a bug. Architecture prevents it."

### SECTION 5: THE REBUILD PLAN (5 slides)

Slide 17 -- "4-Phase Rebuild Aligned with 8-Week Curriculum"
- Phase 1 (Weeks 1-2): Core pipeline with LangGraph + Pydantic + pytest
- Phase 2 (Weeks 3-4): Add Instructor + LangFuse + Tenacity
- Phase 3 (Weeks 5-6): Add DeepEval + PyBreaker + FastAPI
- Phase 4 (Weeks 7-8): Add Mem0 + Neo4j + DSPy + ChromaDB
- "Each phase teaches new tools through the pipeline itself"

Slide 18 -- "Phase 1: The Core (Weeks 1-2)"
- LangGraph state graph with 10 stages
- Pydantic models for all data boundaries (PipelineState, StageGate, VerificationRecord)
- pytest for behavioral tests (port the 288 existing tests)
- Basic CLI: `pineapple doctor`, `pineapple verify`
- Deliverable: Pipeline runs end-to-end on a toy project
- "Learn: LangGraph, Pydantic v2, pytest fixtures"

Slide 19 -- "Phase 2: Intelligence (Weeks 3-4)"
- Instructor for structured LLM outputs at every stage
- LangFuse for tracing every LLM call with cost tracking
- Tenacity for retry logic on all external calls
- Deliverable: Pipeline produces structured artifacts, tracks costs, retries gracefully
- "Learn: Instructor patterns, LangFuse dashboards, decorator-based resilience"

Slide 20 -- "Phase 3: Quality (Weeks 5-6)"
- DeepEval for LLM output evaluation (Stage 6 Layer 4)
- PyBreaker for circuit breaking on external services
- FastAPI to expose pipeline as an API (optional)
- Deliverable: Pipeline evaluates its own AI outputs, handles failures gracefully
- "Learn: LLM-as-judge evaluation, circuit breaker patterns, API design"

Slide 21 -- "Phase 4: Evolution (Weeks 7-8)"
- Mem0 SDK for automatic memory extraction
- Neo4j driver for component relationship graphs
- DSPy for prompt optimization using DeepEval metrics
- ChromaDB for semantic search over past projects
- Deliverable: Pipeline learns from every run, optimizes itself
- "Learn: Vector databases, graph databases, prompt optimization, RAG evaluation"

### SECTION 6: HOW WE PREVENT v1 MISTAKES (3 slides)

Slide 22 -- "10 Non-Negotiable Rules"
1. Read the user's world before designing
2. Verify at every level (code vs spec, spec vs intent)
3. Running code > reading code
4. User pushback is always signal
5. False confidence is worse than no confidence
6. Approval does not equal correctness
7. The spec is the most dangerous artifact
8. Don't reinvent what the user wants to learn
9. Executor is never the verifier
10. Cross-session context is everything

Slide 23 -- "Mandatory Pre-Work Checklist"
- Before ANY spec or plan:
  - [ ] Read `D:\ai-agent-mastery-plan\` for tool decisions
  - [ ] Read MEMORY.md for user preferences
  - [ ] Read relevant project bible for state
  - [ ] Read decisions.md for locked choices
  - [ ] If spec proposes building something a library does, FLAG IT
- "This checklist would have prevented the entire v1 mistake"

Slide 24 -- "The Meta-Pipeline"
- The pipeline is used to rebuild itself
- Full Path: Stage 0 (read learning plan) → Stage 1 (CEO review: "standalone tool or learning project?") → Stage 2 (architecture with LangGraph) → Stage 3 (4-phase plan) → build → verify → ship
- "Dogfood from day zero. Not after 3,442 lines of custom code."

### SECTION 7: VISION (2 slides)

Slide 25 -- "BrokerFlow: The First Real Project"
- From NOTEBOOKLM_BROKERFLOW_WALKTHROUGH.md
- Ontario insurance broker automation
- Runs through all 10 stages using v2 pipeline
- Teaches Python and production patterns naturally
- "The pipeline isn't the product. The pipeline teaches you to build products."

Slide 26 -- "Where This Goes"
- Short term: Rebuild pipeline on 26 tools (8 weeks)
- Medium term: BrokerFlow production launch
- Long term: Every new project scaffolded in 5 minutes with battle-tested tools
- The 7 Permanent Problems are permanent -- the tools evolve, the problems don't
- "You're not learning 26 tools. You're learning 7 patterns that apply to everything."

### Diagram Requirements:

1. **v1 vs v2 Architecture**: Side-by-side showing custom code blocks (red) being replaced by library integrations (green)
2. **26-Tool Matrix**: 7 Permanent Problems (rows) x tools (columns) with which stage uses each
3. **LangGraph State Graph**: 10 nodes with conditional edges, circuit breaker loop, and terminal states
4. **4-Phase Timeline**: Gantt-style showing which tools are added in each 2-week phase
5. **3-Agent Separation**: Orchestrator dispatching to Builder/Verifier/Reviewer pools with firewalls
6. **Data Flow**: User → SKILL.md → LangGraph → Stage nodes → Library tools → Output → Evolve feedback loop

### Tone:
- Honest about the v1 failure ("we built perfectly tested, perfectly wrong code")
- Educational (each phase teaches specific tools)
- Evidence-based (cite dogfood numbers, test counts, line counts)
- Forward-looking (this is the foundation for BrokerFlow and everything after)
- Personal ("your learning plan, your tools, your journey")
