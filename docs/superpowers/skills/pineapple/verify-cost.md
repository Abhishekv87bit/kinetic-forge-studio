---
name: verify-cost
description: "After wiring any cost/billing/tracking system, or after claiming cost tracking works, verify it actually records real costs. Produces evidence JSON. FAIL if cost is $0 for paid APIs, flush_traces() missing, or cost ceiling is bypassed."
---

# /verify-cost -- Real Cost Tracking Verification

Enforcement skill. Verify that cost tracking actually works by making a real API call and checking every link in the chain from LLM response to recorded cost.

**Spec:** `docs/ENFORCEMENT_SKILLS_SPEC.md` (Skill 5)
**Evidence output:** `.pineapple/evidence/verify-cost-<timestamp>.json`

<HARD-GATE>
Cost = $0 for a paid API is a FAIL. No exceptions. "It should work" is not evidence. A real API call that produces a real recorded cost is the only acceptable proof.
</HARD-GATE>

## When to Invoke

- After integrating LangFuse, LangSmith, or any cost/billing tracking
- After claiming "cost tracking works"
- Before marking cost-related success criteria as complete
- After wiring a new LLM provider into the system
- During Stage 6 (Verify) if the feature touches cost tracking

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `provider` | string | Yes | LLM provider to test (e.g., "gemini", "claude", "openai") |
| `tracking_system` | string | Yes | Tracking system (e.g., "langfuse", "langsmith", "custom") |
| `project_root` | string | Yes | Absolute path to the project being verified |
| `test_prompt` | string | No | Prompt to send (default: "Say hello in exactly 3 words") |

## Process

You MUST follow these steps in strict order. Each step completes before the next begins. Do NOT skip steps. Do NOT assume a step passed without running it.

### Step 1: Make a Real API Call

Send a minimal, cheap prompt through the **production code path** -- not a test harness, not a mock, not a direct SDK call. Use the same entry point that real agents use.

```
1. Identify the production code path for making LLM calls
   - Find the agent or wrapper that calls the provider
   - Use THAT code path, not a shortcut

2. Send the test prompt (default: "Say hello in exactly 3 words")
   - Record: response text, input tokens, output tokens, latency_ms
   - If the call fails, STOP -- the provider integration itself is broken

3. Note the timestamp of the call (needed for trace lookup)
```

**What to run:** Dispatch a subagent to execute the actual API call using the project's production code. The subagent should:
- Import the project's LLM calling code
- Make a single call with the test prompt
- Capture and return: response, token counts, latency, any error

### Step 2: Check Cost Recording

Verify that the call from Step 1 was recorded with a non-zero cost.

```
1. Query the tracking system for traces created after the Step 1 timestamp
   - LangFuse: use the LangFuse SDK or API to query recent traces
   - LangSmith: query the LangSmith API
   - Custom: query whatever storage the project uses

2. Find the trace matching the test call
   - Match by timestamp, prompt content, or trace ID if available

3. Check the cost field:
   - cost_usd MUST be > 0 for paid providers (Claude, GPT-4, Gemini Pro, etc.)
   - cost_usd MAY be 0 for free-tier models ONLY
   - If cost_usd == 0 for a paid provider -> FAIL

4. Also check state.cost_total_usd (or equivalent session cost tracker):
   - Must have incremented from its value before the test call
   - If unchanged -> cost tracking is wired but not accumulating -> FAIL
```

**Gemini-specific check:** Gemini reports usage in a different format than Claude/OpenAI. Verify the wrapper correctly parses `usage_metadata.prompt_token_count` and `usage_metadata.candidates_token_count` (not `usage.prompt_tokens`). This is a known bug source.

### Step 3: Check LangFuse Trace (if LangFuse is wired)

If the project uses LangFuse, verify the trace actually appeared in the system.

```
1. Query LangFuse API for the trace ID from Step 2
   - Use: langfuse.get_trace(trace_id) or the REST API
   - The trace must EXIST (not just be queued locally)

2. Verify trace metadata:
   - model field is populated
   - input/output token counts are populated
   - cost field is populated and > $0

3. If LangFuse is wired but no trace found -> WARN
   (Common cause: flush_traces() not called, so traces are buffered but never sent)
```

If LangFuse is NOT wired, record `langfuse_trace_created: null` (not applicable) and move on.

### Step 4: Verify flush_traces() in All LLM Agents

Scan the codebase for every agent/module that makes LLM calls. Each one MUST call `flush_traces()` (or equivalent) to ensure traces are actually sent to the tracking system.

```
1. Find all files that make LLM calls:
   - Search for: litellm.completion, openai.chat.completions.create,
     google.generativeai, langchain invoke/call patterns, or
     whatever the project's LLM calling convention is

2. For each file found, check if it calls flush_traces() or equivalent:
   - LangFuse: langfuse.flush() or flush_traces()
   - LangSmith: explicit flush or context manager cleanup
   - Custom: whatever the project's flush mechanism is

3. Build two lists:
   - agents_with_flush: files that properly flush
   - agents_without_flush: files that call LLM but never flush

4. Any agent in agents_without_flush -> FAIL
   (Traces will be buffered forever and lost on process exit)
```

### Step 5: Check COST_ESTIMATES Are Realistic

Find the cost estimation constants (often named COST_ESTIMATES, MODEL_COSTS, PRICING, or similar). Verify they contain realistic values.

```
1. Search the codebase for cost estimation dictionaries/constants
   - Look for: COST_ESTIMATES, MODEL_COSTS, PRICING, cost_per_token,
     input_cost, output_cost

2. For each model listed, verify:
   - Paid models (claude-*, gpt-4*, gemini-pro*) have cost > $0
   - Values are in a reasonable range (check against known pricing)
   - No model is hardcoded to $0 unless it is genuinely free-tier

3. Flag any paid model with $0 cost estimate -> FAIL
   (This means the $200 ceiling can never trigger for that model)
```

### Step 6: Verify $200 Cost Ceiling Is Functional

The pipeline has a $200 cost ceiling that should pause execution. Verify it would actually trigger.

```
1. Find the cost ceiling check in the codebase
   - Search for: 200, cost_ceiling, COST_LIMIT, budget, or similar

2. Trace the logic:
   - What variable does it check? (e.g., state.cost_total_usd)
   - Is that variable actually updated when LLM calls are made?
   - Could it stay at $0 forever (making the ceiling useless)?

3. Verify the chain is complete:
   LLM call -> cost recorded -> session total updated -> ceiling checked
   If ANY link is broken -> FAIL

4. If cost estimates are $0 (Step 5 failure), the ceiling is automatically
   non-functional -> FAIL with note "ceiling bypassed by $0 estimates"
```

### Step 7: Record Evidence

Write the evidence file. Every field must be populated from actual observations, not assumptions.

**Evidence path:** `.pineapple/evidence/verify-cost-<YYYYMMDD-HHmmss>.json`

```json
{
  "skill": "/verify-cost",
  "timestamp": "<ISO 8601>",
  "provider": "<provider tested>",
  "tracking_system": "<tracking system tested>",
  "api_call_made": true,
  "test_call": {
    "prompt": "Say hello in exactly 3 words",
    "response": "<actual response>",
    "input_tokens": 12,
    "output_tokens": 5,
    "latency_ms": 340
  },
  "cost_tracked": 0.00012,
  "cost_expected_nonzero": true,
  "langfuse_trace_created": true,
  "trace_id": "<trace ID if available>",
  "agents_with_flush": ["src/agents/builder.py", "src/agents/reviewer.py"],
  "agents_without_flush": [],
  "cost_estimates_realistic": true,
  "cost_estimates_checked": {
    "claude-sonnet-4-20250514": {"input": 0.003, "output": 0.015, "realistic": true},
    "gemini-2.0-flash": {"input": 0.0, "output": 0.0, "realistic": false}
  },
  "ceiling_functional": true,
  "ceiling_detail": "state.cost_total_usd checked against 200.0 in orchestrator.py:L142",
  "documents_cross_referenced": [
    "docs/ENFORCEMENT_SKILLS_SPEC.md",
    "docs/superpowers/skills/pineapple/SKILL.md"
  ],
  "verdict": "PASS -- cost tracked at $0.00012, trace visible in LangFuse, all agents flush, ceiling functional"
}
```

## Verdict Rules

| Condition | Verdict | Reason |
|-----------|---------|--------|
| Cost = $0 for a paid API | **FAIL** | Cost tracking is not working |
| LangFuse wired but no trace created | **WARN** | Traces may be buffered but not flushed |
| flush_traces() missing from any LLM agent | **FAIL** | Traces will be lost on process exit |
| Any paid model has $0 in COST_ESTIMATES | **FAIL** | Cost ceiling will never trigger for that model |
| Cost ceiling check references a variable that is never updated | **FAIL** | $200 ceiling is decorative, not functional |
| All checks pass | **PASS** | Cost tracking is verified end-to-end |

**Verdict string format:** `<PASS|FAIL|WARN> -- <one-sentence summary with actual numbers>`

## Red Flags -- STOP and Reassess

- You are assuming cost tracking works because the code "looks right" (RUN IT)
- You skipped the real API call and only did static analysis (Step 1 is mandatory)
- You found flush_traces() in a test file but not in the production agent (test files do not count)
- You are checking a mock/stub tracking system instead of the real one
- Cost is $0 and you are writing PASS (this is always FAIL for paid providers)
- You are testing with a free-tier model to avoid the $0 check (test the model actually used in production)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Checking code structure instead of running it | Step 1 requires a real API call |
| Testing with a mock LLM provider | Use the real provider, even if it costs a fraction of a cent |
| Accepting $0 cost with "Gemini free tier" excuse | If the production config uses a paid Gemini model, $0 is wrong |
| Checking flush_traces() exists but not verifying trace arrived | Step 3 confirms the trace is in the dashboard, not just queued |
| Marking PASS when one step failed | ANY FAIL in Steps 2-6 means overall FAIL |
| Not checking COST_ESTIMATES dictionary | Silent $0 estimates are the #1 way the ceiling gets bypassed |
