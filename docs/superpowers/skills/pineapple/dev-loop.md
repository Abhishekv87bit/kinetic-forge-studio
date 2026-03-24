---
name: dev-loop
description: "MANDATORY development loop for ALL implementation work. Wraps every build cycle in a 6-step gated sequence: PLAN -> IMPLEMENT -> VERIFY-OUTPUTS -> VERIFY-DONE -> REPORT -> COMMIT. Cannot be skipped. Cannot be shortened. Evidence files required at every gate. This is THE process, not a suggestion."
---

# /dev-loop -- The Mandatory Development Loop

This is not a skill you choose to invoke. This is THE ONLY WAY to implement anything in the pipeline. Every line of code, every bug fix, every config change flows through this loop. No exceptions. No shortcuts. No "just this once."

**Spec:** `docs/ENFORCEMENT_SKILLS_SPEC.md`
**Consumes:** `/verify-outputs`, `/verify-done`, `/verify-tests`, `/verify-state-flow`, `/verify-cost`, `/honest-status`
**Output:** Evidence files per cycle (3 mandatory + up to 3 conditional), included in every commit.

<HARD-GATE>
#############################################################################
#                                                                           #
#   YOU CANNOT IMPLEMENT WITHOUT RUNNING THIS LOOP.                         #
#                                                                           #
#   YOU CANNOT COMMIT WITHOUT ALL THREE EVIDENCE FILES.                     #
#                                                                           #
#   YOU CANNOT SKIP A STEP BECAUSE "IT IS A SMALL CHANGE."                  #
#                                                                           #
#   YOU CANNOT SKIP A STEP BECAUSE "WE ALREADY KNOW IT WORKS."             #
#                                                                           #
#   IF YOU ARE ABOUT TO WRITE `git commit` AND YOU HAVE NOT                 #
#   COMPLETED STEPS 3, 4, 5, AND 6 -- STOP. YOU ARE VIOLATING              #
#   THE DEV LOOP.                                                           #
#                                                                           #
#############################################################################

The dev-loop sequence is:

    PLAN -> IMPLEMENT -> VERIFY-OUTPUTS -> VERIFY-DONE -> CONDITIONAL-GATES -> REPORT -> COMMIT
      ^                                       |                |
      +---------- FAIL? FIX AND RETRY --------+----------------+

    CONDITIONAL-GATES (Step 5):
      5a. /verify-tests      (if tests involved)
      5b. /verify-state-flow (if state/pipeline changed)
      5c. /verify-cost       (if cost/observability changed)

Every step produces an artifact. Every artifact is checked at the next step.
No step can be skipped. The loop does not end until COMMIT succeeds with
all three evidence files included.

If you catch yourself about to skip a step, STOP IMMEDIATELY and go back.
</HARD-GATE>

## Why This Exists

Three times, Claude committed without running /verify-done. Three times, Claude ignored hookify warnings. Three times, evidence files were missing from the commit. The pattern is clear: optional verification gets skipped 100% of the time under pressure.

This skill makes verification mandatory by defining it as part of the implementation process itself -- not a separate step that can be deferred. You do not "implement and then verify." You run the dev-loop, which includes verification as a non-removable stage.

The evidence files are not ceremony. They are the proof that work was done correctly. A commit without evidence is an unverified claim. Unverified claims are how we shipped a pipeline where the builder did not write files to disk, the verifier checked the wrong directory, and 288 tests tested dead code.

## The Six Steps

### Step 1: PLAN (before any agent launches)

Before writing a single line of code, write a plan file.

**Create file:** `.pineapple/evidence/plan-<feature-slug>.md`

The plan MUST contain:

```markdown
# Plan: <feature name>

## What will be built/fixed
<Concrete description. Not "fix the bug" -- which bug, in which file, what is the expected behavior after the fix.>

## Expected outputs
<Specific files that will be created or modified. Full paths. Not "some files" -- which files.>

| File | Action | Description |
|------|--------|-------------|
| src/module/feature.py | CREATE | New module implementing X |
| src/module/existing.py | MODIFY | Add Y method to Z class |
| tests/test_feature.py | CREATE | Tests for X behavior |

## Verification commands
<Specific commands that will prove the work is done. Not "run tests" -- which tests, what inputs, what expected output.>

| Command | Expected Result |
|---------|----------------|
| python -c "from module import func; print(func('input'))" | Prints "expected output" |
| pytest tests/test_feature.py -v | All tests pass, 0 failures |
| ls -la src/module/feature.py | File exists, non-empty |

## Acceptance criteria
<What does "done" look like? Be specific enough that a stranger could verify.>
```

**Gate:** Plan file exists on disk before proceeding. If you launch an agent without a plan file, you are violating the dev-loop.

**Why plans matter:** Without a plan, you cannot verify. If you do not know what the expected outputs are, you cannot check whether the outputs are correct. The plan is the contract against which verification runs.

### Step 2: IMPLEMENT (launch agents)

Execute the plan using subagents. The orchestrator does not write code -- agents do.

**Rules:**
- Each agent receives: the plan file, the relevant source files, and nothing else
- Each agent MUST return: files created/modified (full paths), commands run, test results
- The orchestrator records what each agent claims to have done

**What to capture from each agent:**

```
Agent: <name/purpose>
Claimed files created: [list of full paths]
Claimed files modified: [list of full paths]
Commands run: [list]
Agent's self-reported status: <what the agent says>
```

Do NOT trust the agent's self-reported status. Agents lie. Not maliciously -- they are optimistic. They say "done" when they mean "I think I wrote the code." Step 3 checks whether they actually did.

**Gate:** Agent has returned. Orchestrator has the list of claimed outputs. Do NOT proceed to commit. Proceed to Step 3.

### Step 3: VERIFY-OUTPUTS (mandatory -- invoke /verify-outputs)

**Invoke:** `/verify-outputs`

For EVERY file the agent claims to have created or modified:
- Does it exist on disk? (`ls -la`, not grep, not Read)
- Is it non-empty? (size > 0 bytes)
- Is it a real implementation, not a stub? (no `pass` bodies, no `NotImplementedError`, no placeholder comments)
- Does git status show it as modified/added? (cross-reference with agent claims)

**Evidence file:** `.pineapple/evidence/outputs-<feature-slug>.json`

**Verdicts:**
| Verdict | Meaning | Action |
|---------|---------|--------|
| WORKING | All files exist with real implementations | Proceed to Step 4 |
| WIRED | Files exist but some are stubs | STOP. Go back to Step 2. Fix stubs. |
| FAKE | Files do not exist on disk | STOP. Go back to Step 2. Agent lied. |

```
IF verdict != WORKING:
    DO NOT proceed to Step 4.
    DO NOT proceed to commit.
    Return to Step 2 with the list of failures.
    Retry. Max 3 retries before escalating to user.
```

**Gate:** `/verify-outputs` evidence file exists AND verdict is WORKING. No exceptions.

### Step 4: VERIFY-DONE (mandatory -- invoke /verify-done)

**Invoke:** `/verify-done`

This is the behavioral verification. Files existing is necessary but not sufficient. The code must actually DO what it claims to do.

**Process:**
1. Read the plan file from Step 1 (what were the expected behaviors?)
2. Run the verification commands from the plan with REAL inputs
3. Check that REAL outputs match expected behavior
4. Cross-reference against spec, plan, and any related documents
5. Rate: WORKING / WIRED / STUBBED / FAKE

**Evidence file:** `.pineapple/evidence/done-<feature-slug>.json`

**Verdicts and enforcement:**
| Verdict | Action |
|---------|--------|
| WORKING | Proceed to Step 5 |
| WIRED | WARN user. Present what was not verified. Get EXPLICIT "yes" to proceed. Do not assume approval. |
| STUBBED | STOP. Return to Step 2. List what is missing. Cannot proceed. |
| FAKE | STOP. Return to Step 2. Show hardcoded values. Cannot proceed. |

```
IF verdict == STUBBED or verdict == FAKE:
    DO NOT proceed to Step 5.
    DO NOT proceed to commit.
    Return to Step 2 with the failure details.
    Retry. Max 3 retries before escalating to user.

IF verdict == WIRED:
    Present to user: "Feature is WIRED but not fully verified. Proceed?"
    WAIT for explicit user response.
    If user says no -> Return to Step 2.
    If user says yes -> Proceed to Step 5 with WIRED noted.
```

**Gate:** `/verify-done` evidence file exists AND verdict is WORKING (or WIRED with explicit user approval). No exceptions.

**CRITICAL RULE:** The agent that built the feature in Step 2 CANNOT be the agent that runs /verify-done in Step 4. The executor is never the verifier. Launch a FRESH agent with no build context for verification.

### Step 5: CONDITIONAL GATES (mandatory when applicable)

Three additional verification gates fire based on WHAT was changed. These are NOT optional -- they are mandatory when their trigger condition is met.

#### Gate 5a: /verify-tests (fires when tests are involved)
**Trigger:** ANY test file was created, modified, or test results are being reported.
**What it checks:**
- Which modules do the tests actually import? (v1 tools/ or v2 src/pineapple/)
- Are there fake tests? (assert True, pass-only, unconditional skip)
- What is the REAL v2 test coverage? (which functions tested, which not)
**Evidence file:** `.pineapple/evidence/tests-<feature-slug>.json`
**Enforcement:**
- Cannot claim "X tests pass" without stating what they test
- Cannot count v1 tests as v2 coverage
- Cannot count fake tests
**If trigger met but gate skipped:** VIOLATION. Go back.

#### Gate 5b: /verify-state-flow (fires when multi-stage pipeline work)
**Trigger:** ANY state field, inter-stage contract, or graph edge was modified.
**What it checks:**
- Every state field READ has a matching WRITE upstream
- Field names match exactly between writer and reader
- Path-dependent gaps (lightweight skips stages -- do downstream stages handle missing fields?)
**Evidence file:** `.pineapple/evidence/state-flow-<feature-slug>.json`
**Enforcement:**
- Missing field (read but never written) -> FAIL
- Name mismatch (written as X, read as Y) -> FAIL
- Path gap without fallback -> WARN
**If trigger met but gate skipped:** VIOLATION. Go back.

#### Gate 5c: /verify-cost (fires when cost/observability system touched)
**Trigger:** ANY cost tracking, LangFuse, or billing code was modified.
**What it checks:**
- Real API call made, cost tracked (not $0 for paid providers)
- LangFuse trace created (if wired)
- flush_traces() called in all LLM agents
- Cost ceiling functional (not bypassed by $0 estimates)
**Evidence file:** `.pineapple/evidence/cost-<feature-slug>.json`
**Enforcement:**
- Cost = $0 for paid API -> FAIL
- Missing flush_traces() in any LLM agent -> FAIL
**If trigger met but gate skipped:** VIOLATION. Go back.

### Step 6: REPORT (mandatory -- use /honest-status vocabulary)

Before committing, produce a human-readable report. This is not optional status decoration -- it is the final check that forces you to articulate what actually happened.

**The report MUST contain:**

```
=== DEV-LOOP REPORT: <feature> ===

Plan:    .pineapple/evidence/plan-<feature-slug>.md
Outputs: .pineapple/evidence/outputs-<feature-slug>.json
Done:    .pineapple/evidence/done-<feature-slug>.json

Verdict: WORKING | WIRED (user-approved) | STUBBED (BLOCKED) | FAKE (BLOCKED)

Files changed:
  [CREATE] src/module/feature.py (187 lines, real implementation)
  [MODIFY] src/module/existing.py (+23 lines, added Y method)
  [CREATE] tests/test_feature.py (4 tests, testing X behavior)

Verification commands run:
  [PASS] python -c "from module import func; ..." -> correct output
  [PASS] pytest tests/test_feature.py -v -> 4/4 passed
  [PASS] ls -la src/module/feature.py -> exists, 6.2KB

What the tests actually test (not just count):
  - test_func_returns_correct_value: calls func('input'), asserts output == 'expected'
  - test_func_handles_empty_input: calls func(''), asserts raises ValueError
  - test_func_handles_none: calls func(None), asserts raises TypeError
  - test_integration_with_module: calls func through module interface, checks end-to-end

Evidence files ready for commit: YES / NO
```

**Banned vocabulary (from /honest-status):**

| BANNED | USE INSTEAD |
|--------|-------------|
| "MET" | WORKING, WIRED, STUBBED, FAKE |
| "all green" | "4 WORKING, 2 WIRED, 1 STUBBED" |
| "tests pass" | "4 tests pass, testing [specific behaviors]" |
| "looks good" | State what was verified and how |
| "should work" | Run /verify-done and get evidence |
| "all done" | Show the evidence file paths |

**Gate:** Report printed. All three evidence files confirmed to exist. If evidence files are missing, you cannot proceed.

### Step 7: COMMIT (only after Steps 3, 4, 5, and 6 pass)

You have earned the right to commit. But the commit itself has rules.

**Pre-commit checklist:**
- [ ] `.pineapple/evidence/plan-<feature-slug>.md` exists
- [ ] `.pineapple/evidence/outputs-<feature-slug>.json` exists
- [ ] `.pineapple/evidence/done-<feature-slug>.json` exists
- [ ] All three are staged for commit (`git add`)
- [ ] Verdict from Step 4 is WORKING (or WIRED with user approval)
- [ ] Report from Step 5 has been printed

**Commit message format:**
```
<type>: <description>

Evidence:
  plan:    .pineapple/evidence/plan-<feature-slug>.md
  outputs: .pineapple/evidence/outputs-<feature-slug>.json
  done:    .pineapple/evidence/done-<feature-slug>.json

Verdict: <WORKING|WIRED>
```

**Enforcement:**
- Evidence files MUST be included in the commit (staged with `git add`)
- Commit message MUST reference all three evidence paths
- A commit without evidence references is an unverified commit -- it should not exist

**Gate:** Commit succeeds with evidence files included. Dev-loop cycle complete.

## The Retry Loop

When Steps 3 or 4 fail, the loop does not exit. It retries.

```
Attempt 1: PLAN -> IMPLEMENT -> VERIFY-OUTPUTS -> FAIL
           Return to IMPLEMENT with failure details.

Attempt 2: IMPLEMENT (fix) -> VERIFY-OUTPUTS -> PASS -> VERIFY-DONE -> FAIL
           Return to IMPLEMENT with failure details.

Attempt 3: IMPLEMENT (fix) -> VERIFY-OUTPUTS -> PASS -> VERIFY-DONE -> PASS
           Proceed to REPORT -> COMMIT.
```

**Max retries:** 3 full cycles through the loop. After 3 failures, escalate to the user with:
1. What was attempted (3 times)
2. What failed each time (specific evidence)
3. Options: redesign approach, simplify scope, or abandon

Do NOT retry silently. Each retry must state what failed and what is being changed.

## Failure Mode Detection

These are the patterns that indicate the dev-loop is being violated. If you recognize any of these patterns in your own behavior, STOP IMMEDIATELY.

### Pattern 1: "Agent returned, let me commit"
**What happened:** Steps 3, 4, and 5 were skipped entirely.
**Detection:** No evidence files exist. No verification commands were run.
**Fix:** Go back. Run /verify-outputs. Run /verify-done. Print report. Then commit.

### Pattern 2: "Tests pass, all good"
**What happened:** Step 4 was done superficially. "Tests pass" without saying WHICH tests testing WHAT.
**Detection:** No /verify-done evidence file. Or evidence file has no `command_run` field.
**Fix:** Go back. Run specific verification commands from the plan. Record what they test.

### Pattern 3: "X/10 fixed, committing"
**What happened:** Step 5 was skipped. A count without evidence is not a report.
**Detection:** No report printed. No evidence file paths shown.
**Fix:** Go back. Print the full report with evidence paths and test descriptions.

### Pattern 4: "Let me commit and verify later"
**What happened:** The entire dev-loop was inverted. Commit came before verification.
**Detection:** Commit made without evidence files in the staging area.
**Fix:** This commit is invalid. The work is unverified. Run the full dev-loop before the next commit.

### Pattern 5: "It is a small change, no need for the full loop"
**What happened:** The dev-loop was treated as optional based on change size.
**Detection:** ANY implementation work without a plan file.
**Fix:** There is no "small change" exception. A one-line fix still gets a plan, verification, and evidence. The plan can be short. The verification can be quick. But they must exist.

### Pattern 6: "I already know this works"
**What happened:** Confidence replaced evidence. Knowledge is not proof.
**Detection:** Commit without evidence files. Or evidence file written without running commands.
**Fix:** Run the commands. Capture the output. Write the evidence. Confidence is not evidence.

## Integration With Other Skills

| Skill | Role in Dev-Loop |
|-------|-----------------|
| `/verify-outputs` | Invoked at Step 3. Checks files exist on disk. |
| `/verify-done` | Invoked at Step 4. Checks behavior with real inputs. |
| `/verify-tests` | Invoked at Step 5a (conditional). Checks test honesty. |
| `/verify-state-flow` | Invoked at Step 5b (conditional). Checks state contracts. |
| `/verify-cost` | Invoked at Step 5c (conditional). Checks real cost tracking. |
| `/honest-status` | Vocabulary and format used at Step 6. |
| `pineapple` (main skill) | Dev-loop runs inside Stage 5 (Build) and Stage 6 (Verify). |
| Hookify STOP rules | Safety net. Blocks commits missing evidence files. |

**Relationship to pipeline stages:**

```
Stage 5 (Build):
  For each task in the plan:
    Run /dev-loop (PLAN -> IMPLEMENT -> VERIFY-OUTPUTS -> VERIFY-DONE -> REPORT -> COMMIT)

Stage 6 (Verify):
  Fresh agent re-runs /verify-done on ALL features from Stage 5
  This is the SECOND verification pass -- independent of the builder's loop
```

The dev-loop runs INSIDE Stage 5 for each task. Stage 6 is a separate, independent verification by a different agent. Both are required.

## Evidence File Quick Reference

| File | Created at | Format | Required fields |
|------|-----------|--------|----------------|
| `plan-<slug>.md` | Step 1 | Markdown | What, expected outputs, verification commands, acceptance criteria |
| `outputs-<slug>.json` | Step 3 | JSON | claimed_files, exists, is_stub, verdict |
| `done-<slug>.json` | Step 4 | JSON | feature_name, command_run, output_captured, verdict, docs_checked |

All three files live in `.pineapple/evidence/`. All three are committed with the code.

## Red Flags -- STOP and Reassess

You are violating the dev-loop if:

- You are about to run `git commit` and no evidence files exist in `.pineapple/evidence/`
- You are about to run `git commit` and you have not printed a Step 5 report
- You launched an agent without first writing a Step 1 plan file
- You accepted an agent's "done" claim without running /verify-outputs
- You rated something WORKING without running /verify-done
- You used any banned vocabulary in your report
- You skipped a step because the change was "small" or "obvious"
- You are the same agent that built AND verified the feature
- You wrote evidence files without actually running the verification commands
- You are committing code that has a STUBBED or FAKE verdict
- You told the user "all done" without showing evidence file paths

## Common Mistakes

| Mistake | Why It Happens | Fix |
|---------|---------------|-----|
| Skipping Step 1 (plan) | "I know what to do" | Write the plan anyway. It takes 2 minutes and saves 20 minutes of redo. |
| Trusting agent self-reports | Agents are optimistic | Run /verify-outputs on every claim. Trust ls, not agents. |
| Running /verify-done as the builder | Confirmation bias | Launch a fresh agent. The builder cannot verify their own work. |
| Committing without evidence | "I will add it next commit" | No. Evidence is part of THIS commit. Not the next one. |
| Writing evidence without running commands | Filling in the template from memory | The evidence file must contain REAL command output. Not what you think it would say. |
| Skipping the report | "The user can see the evidence files" | The report is the final sanity check. Print it. |
| Retrying without stating what changed | "Trying again" | State what failed, what you changed, and why this attempt should succeed. |
| Rating WIRED as WORKING | "It mostly works" | WIRED means not fully verified. Say WIRED. Let the user decide. |

## The Contract

This skill exists because verification was optional and got skipped. Three times. Despite rules. Despite warnings. Despite hookify.

The dev-loop makes verification non-optional by embedding it in the implementation process itself. You do not implement and then verify. You implement THROUGH verification. The loop is the process. The evidence is the output. The commit is the receipt.

If you are reading this skill and still planning to skip a step: do not. The user will find out. The audit will catch it. The evidence files will be missing. And we will be back here writing an even more aggressive version of this skill.

Run the loop. Every time. All six steps. No exceptions.
