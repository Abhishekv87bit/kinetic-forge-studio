---
name: verify-done
description: "Before marking ANY feature, task, criterion, or gap as complete/done/MET/PASS, run this skill to produce evidence that the feature actually works. Produces evidence JSON. BLOCKS false completions."
---

# /verify-done -- Feature Completion Evidence

The most important enforcement skill. Prevents "10/10 MET" false confidence.

**Spec:** `docs/ENFORCEMENT_SKILLS_SPEC.md` (Skill 1)
**Trigger:** Before marking ANY feature, task, criterion, or gap as "complete", "done", "MET", or "PASS"
**Output:** Evidence file at `.pineapple/evidence/verify-done-<feature-slug>-<timestamp>.json`

<HARD-GATE>
You MUST run this skill BEFORE:
- Marking a success criterion as met
- Closing a gap in a project bible
- Claiming "feature X is done" to the user
- Advancing past Stage 6 (Verify) in the pipeline
- Writing "PASS" or "MET" or "complete" in any status field

The word "MET" is BANNED as a verdict. Use WORKING / WIRED / STUBBED / FAKE only.
</HARD-GATE>

## Core Principles

These are the dogfood lessons that created this skill. Violating any of them is a skill failure.

1. **"Does it import?" is NOT verification.** An import proves the file exists. It does not prove the code works.
2. **"Do tests pass?" is NOT verification** if the tests do not test behavior. 288 passing tests tested v1 dead code.
3. **Running code > reading code.** Grep is NEVER verification. Read is NEVER verification. Only execution is verification.
4. **False confidence is worse than no confidence.** Saying WORKING when it is STUBBED causes the user to ship broken software. Say STUBBED and let the user decide.
5. **The executor is never the verifier.** If you built the feature, you cannot verify it. A fresh agent with no build context must run this skill.

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `feature` | string | Yes | Human-readable name of the feature being verified |
| `expected_behavior` | string | Yes | What the feature should do when working correctly |
| `test_command` | string | No | Specific command to run (skill infers if omitted) |
| `spec_file` | path | No | Path to spec/plan that defines expected behavior |

## Process

You MUST follow these steps in strict order. Each step completes before the next begins. Do NOT skip steps.

### Step 1: Load Context

Read the relevant documents to understand what the feature SHOULD do:

- Read `spec_file` if provided
- Identify which source files implement the feature (search the codebase)
- Identify which documents define expected behavior (spec, plan, handoff, dogfood report, user's tool directory)
- Record every document path you read -- these go in `docs_checked`

Do NOT start running code yet. Understand the expected behavior first.

### Step 2: Verify File Existence

Check that all implementation files exist on disk:

- Do the source files exist? (not just referenced, actually on disk)
- Are they non-empty?
- Do they contain the expected functions/classes? (not just imports or empty stubs)
- Are function bodies implemented? (not `pass`, not `raise NotImplementedError`, not `return None`)

If files are missing or empty, the verdict is **STUBBED**. Stop here and report.

### Step 3: Run With REAL Inputs

This is the critical step. Execute the feature with real inputs in a real environment.

**If `test_command` was provided:** Run it.
**If not:** Construct a command that exercises the feature. Examples:
- For a Python function: `python -c "from module import func; result = func(real_input); print(result)"`
- For a CLI tool: `python tool.py --real-flag real-argument`
- For an API endpoint: `curl http://localhost:PORT/endpoint -d '{"real": "data"}'`
- For a file processor: Run it on a real file and check the output file

**Capture everything:**
- stdout (full output)
- stderr (full output)
- Exit code
- Wall-clock time

**Infrastructure dependencies:** If the feature requires infrastructure (database, API key, running server) that is not available, record what is missing. The verdict is **WIRED** at best -- you cannot verify end-to-end without the infrastructure.

**What does NOT count as running with real inputs:**
- Importing a module (that is Step 2, not Step 3)
- Running `pytest` if the tests do not test the specific behavior
- Reading the source code and reasoning about what it would do
- Running a linter or type checker

### Step 4: Check REAL Outputs

After running the code, verify that the outputs are correct:

- Do output files exist on disk? Check with `ls`, `stat`, or `test -f`.
- Are outputs non-empty and structurally valid? (not just `{}` or `null`)
- Do outputs match what the spec says the feature should produce?
- If the feature writes to a database, query the database and check records.
- If the feature returns data, check that the data is correct (not hardcoded, not placeholder).

**How to detect FAKE:**
- Output looks reasonable but is the same every time regardless of input
- Output contains placeholder strings ("TODO", "lorem ipsum", "example.com", "test123")
- Output matches a hardcoded return value in the source code
- Numbers are suspiciously round ($0.00, 100%, 0 errors)

### Step 5: Cross-Reference Documents

Read ALL relevant documents and verify alignment:

- Does the code do what the spec says it should?
- Does the spec match the user's original intent?
- Does the plan describe this feature's expected behavior?
- Does the handoff note mention any known issues?
- Does the dogfood report flag this area?

**Check each document and record it:**
```
docs_checked:
  - path: "docs/superpowers/specs/2026-03-15-feature-design.md"
    finding: "Spec says feature should handle 3 input types. Code handles 2."
  - path: "docs/superpowers/plans/2026-03-20-feature-plan.md"
    finding: "Plan step 4 says 'wire to DB'. Code writes to local file instead."
```

If the code diverges from the spec, note the divergence. This does not automatically mean STUBBED -- the code might be correct and the spec outdated. But the divergence MUST be recorded.

### Step 6: Rate and Record

Assign a verdict using ONLY these four statuses:

| Verdict | Criteria | Enforcement |
|---------|----------|-------------|
| **WORKING** | Ran with real inputs. Produced correct output. Output matches spec. Tested end-to-end. | Proceed. |
| **WIRED** | Library imported and called. Code runs without error. But behavior not verified end-to-end (missing infra, partial test). | WARN. Can proceed ONLY with explicit user acknowledgment. Present what was not verified. |
| **STUBBED** | Function exists but does not do what its name says. Empty body, `pass`, `NotImplementedError`, or wrong behavior. | BLOCK. Cannot mark complete. List what is missing. |
| **FAKE** | Returns hardcoded/placeholder data that looks real but is not. Constant return values. $0 costs. Empty responses dressed up as success. | BLOCK. Cannot mark complete. Show the hardcoded values. |

**Rating rules:**
- If ANY critical behavior is FAKE, the entire feature is FAKE.
- If the happy path works but error handling is STUBBED, the feature is WIRED (not WORKING).
- If tests pass but tests do not test the claimed behavior, verdict is based on what YOU observed running the code, not on test results.
- When in doubt, rate DOWN, not up. WIRED is better than a false WORKING.

### Step 7: Write Evidence File

Write the evidence JSON to `.pineapple/evidence/verify-done-<feature-slug>-<timestamp>.json`:

```json
{
  "feature_name": "builder-writes-files-to-disk",
  "expected_behavior": "BuilderAgent.build() creates real source files in the workspace directory",
  "actual_behavior": "BuilderAgent.build() creates metadata dict but does not call file write operations",
  "command_run": "python -c \"from pineapple.agents.builder import BuilderAgent; b = BuilderAgent(); result = b.build('test-task', '/tmp/workspace'); import os; print(os.listdir('/tmp/workspace'))\"",
  "output_captured": "[] (empty directory)",
  "verdict": "STUBBED",
  "docs_checked": [
    "docs/PINEAPPLE_V2_SPEC.md",
    "docs/superpowers/plans/2026-03-20-v2-plan.md",
    "sessions/2026-03-22.md"
  ],
  "evidence": [
    {
      "check": "file_exists",
      "target": "src/pineapple/agents/builder.py",
      "result": true,
      "detail": "File exists, 247 lines"
    },
    {
      "check": "behavior_test",
      "command": "python -c \"...\"",
      "exit_code": 0,
      "stdout_snippet": "[] (empty directory)",
      "result": false,
      "detail": "Builder ran without error but produced no files on disk"
    },
    {
      "check": "output_check",
      "target": "/tmp/workspace/",
      "result": false,
      "detail": "Expected source files in workspace, found empty directory"
    },
    {
      "check": "doc_cross_ref",
      "document": "docs/PINEAPPLE_V2_SPEC.md",
      "result": false,
      "detail": "Spec says builder writes files. Code returns metadata dict only."
    }
  ],
  "timestamp": "2026-03-23T14:32:00Z",
  "blocking": true,
  "blocking_reason": "STUBBED features cannot be marked complete. Builder must write real files to disk."
}
```

### Step 8: Enforce

Based on the verdict:

- **WORKING** -- Report to orchestrator. Feature can be marked complete.
- **WIRED** -- Report to orchestrator with explicit warning. Present what was NOT verified. Ask user: "This feature is WIRED but not fully verified end-to-end. Proceed anyway?" Do NOT mark complete without user's explicit "yes".
- **STUBBED** -- BLOCK. Report to orchestrator. Feature CANNOT be marked complete. List exactly what is missing or broken.
- **FAKE** -- BLOCK. Report to orchestrator. Feature CANNOT be marked complete. Show the hardcoded/placeholder values found.

## Console Report Format

After writing the evidence file, print a human-readable summary:

```
=== /verify-done: <feature_name> ===

Verdict: WORKING | WIRED | STUBBED | FAKE

Expected: <expected_behavior>
Actual:   <actual_behavior>

Evidence:
  [PASS] file_exists: src/module/feature.py (312 lines)
  [PASS] behavior_test: python -c "..." (exit 0, 1.2s)
  [FAIL] output_check: expected 3 output files, found 0
  [FAIL] doc_cross_ref: spec says X, code does Y

Docs checked: 4
  - docs/spec.md
  - docs/plan.md
  - sessions/2026-03-22.md
  - docs/dogfood-report.md

Evidence file: .pineapple/evidence/verify-done-feature-name-20260323T143200.json

BLOCKING: Yes -- STUBBED features cannot be marked complete.
```

## Red Flags -- STOP and Reassess

You are violating this skill if:

- You are about to write "MET" or "PASS" without having run the code
- You ran `grep` or `Read` and called it verification
- You ran `pytest` without checking if the tests actually test the behavior
- You are rating WORKING because "the code looks correct" (reading is not running)
- You are rating WORKING because "tests pass" but you did not check what the tests test
- You skipped Step 3 (Run With REAL Inputs) for any reason
- You skipped Step 5 (Cross-Reference Documents) for any reason
- You are writing the evidence file without having actually run a command
- The `command_run` field in your evidence is empty or contains a grep/read command
- You are the same agent that built the feature (executor is never the verifier)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Grepping for a function and calling it verified | Run the function with real inputs |
| Running pytest and trusting the count | Read the test file -- do tests test THIS behavior? |
| Rating WORKING because import succeeds | Import proves existence, not behavior |
| Rating WORKING because "no errors" | No errors with no output is STUBBED, not WORKING |
| Skipping doc cross-reference | Always check spec, plan, handoff -- divergence is a signal |
| Writing evidence with empty command_run | Every evidence file MUST have a real command that was executed |
| Accepting $0 or 0% or 100% as real values | These are almost always FAKE -- verify with a second input |
| Trusting error handling without triggering errors | Pass bad input on purpose and check the error path |
| Marking complete with WIRED verdict without user ack | WIRED requires explicit user acknowledgment to proceed |

## What This Skill Prevents

| Historical Issue | How This Skill Catches It |
|-----------------|--------------------------|
| C-1: PyBreaker imported but never triggers | Step 3 runs code that should trigger the circuit breaker. If it never opens, verdict is FAKE. |
| H-1: Cost tracking reports $0 for Gemini | Step 3 makes a real call. Step 4 checks cost > $0. If $0, verdict is FAKE. |
| H-3: Builder returns metadata, no files on disk | Step 3 runs builder. Step 4 checks disk for files. Empty directory = STUBBED. |
| 288 tests passing on v1 dead code | Step 3 runs the feature, not the test suite. Tests are not verification. |
| "10/10 criteria MET" with nothing working | Every criterion must go through this skill independently. No batch approvals. |
