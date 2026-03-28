---
name: verify-state-flow
description: "After implementing multi-stage pipelines, verify that every state field READ by a stage is WRITTEN by an upstream stage. Catches orphan reads, name mismatches, and path-dependent gaps before E2E tests."
---

# Verify State Flow

Pineapple Enforcement Skill 3. Catch plumbing issues before they become runtime crashes.

**Spec:** `docs/ENFORCEMENT_SKILLS_SPEC.md` (Skill 3)
**Trigger:** After implementing multi-stage pipelines, before E2E tests.
**Output:** Evidence file at `.pineapple/evidence/verify-state-flow-<timestamp>.json`

<HARD-GATE>
Any missing field (read but never written) is a FAIL. Any name mismatch is a FAIL. Do NOT proceed to E2E testing with unresolved FAIL verdicts.
</HARD-GATE>

## When to Invoke

- After implementing a multi-stage pipeline (like Pineapple itself)
- Before running E2E tests on any stateful system
- When debugging "field X is None" or "KeyError" errors at runtime
- After adding new stages or modifying state schema
- When pipeline paths diverge (e.g., lightweight skips stages)

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `state_file` | path | Yes | Path to the state schema (e.g., `state.py`, `pipeline_state.py`) |
| `stage_files` | list[path] | Yes | Paths to all stage/agent implementation files |
| `state_class` | string | No | Name of the state class (defaults to searching for TypedDict, BaseModel, or dataclass) |

## Process

You MUST follow these steps in strict order. Each step completes before the next begins.

### Step 1: Parse State Schema

Read the `state_file`. Extract every field from the state class.

**What to look for:**
- `TypedDict` fields
- Pydantic `BaseModel` fields
- `dataclass` fields
- `dict` type annotations
- Default values (a field with a default is still a field -- it just has a fallback)

**Build field inventory:**

```
{
  "field_name": {
    "type": "str | dict | list | ...",
    "has_default": true/false,
    "default_value": "..." or null,
    "nested_fields": ["sub.field.a", "sub.field.b"]  // if dict/object type
  }
}
```

For nested state (e.g., `workspace_info.branch`), flatten to dot notation and track both the parent and nested paths.

### Step 2: Analyze Each Stage (WRITE Map)

For each file in `stage_files`, find every state field WRITE.

**Patterns to search for:**

```python
# Direct assignment
state["field_name"] = value
state.field_name = value

# Dict update
state.update({"field_name": value})
state |= {"field_name": value}

# Nested assignment
state["parent"]["child"] = value
state.parent.child = value

# Conditional writes (important -- mark as "conditional")
if condition:
    state["field_name"] = value
```

**Record for each stage:**

```
{
  "stage_file": "strategic_review.py",
  "stage_name": "Stage 1: Strategic Review",
  "writes": [
    {"field": "strategic_brief", "line": 42, "conditional": false},
    {"field": "workspace_info.branch", "line": 67, "conditional": true}
  ]
}
```

### Step 3: Analyze Each Stage (READ Map)

For each file in `stage_files`, find every state field READ.

**Patterns to search for:**

```python
# Direct read
x = state["field_name"]
x = state.field_name

# Dict get (with or without default)
x = state.get("field_name")
x = state.get("field_name", default)  # note: has fallback

# Truthiness check
if state.get("field_name"):
if "field_name" in state:

# Nested read
x = state["parent"]["child"]
x = state.parent.child

# F-string or format interpolation
f"...{state['field_name']}..."
```

**Record for each stage:**

```
{
  "stage_file": "shipper.py",
  "stage_name": "Stage 8: Ship",
  "reads": [
    {"field": "branch", "line": 15, "has_fallback": false},
    {"field": "verify_result", "line": 28, "has_fallback": true, "fallback": "None"}
  ]
}
```

### Step 4: Verify READ/WRITE Consistency

Cross-reference the WRITE map (Step 2) against the READ map (Step 3).

**For each field that is READ anywhere:**

1. Is it WRITTEN by any upstream stage? If no -- mark **MISSING** (this will crash at runtime).
2. Is it WRITTEN by the same stage that reads it? That is OK only if the write happens before the read in execution order.
3. Is it in the initial state schema with a default? If yes, it is covered.

**For each field that is WRITTEN anywhere:**

1. Is it READ by any downstream stage? If no -- mark **ORPHANED** (dead code, wasted computation).

### Step 5: Check Field Name Matches

This is the typo detector. Compare every written field name against every read field name using fuzzy matching.

**Flag as NAME MISMATCH when:**
- Written as `branch`, read as `branch_name`
- Written as `workspace_info.branch`, read as `branch`
- Written as `verify_result`, read as `verification_result`
- Edit distance <= 3 between a written field and a read field that has no writer

For each mismatch, report both the written name and the read name with file and line numbers.

### Step 6: Check Path-Dependent Gaps

The Pineapple Pipeline has three paths (Full, Medium, Lightweight) that skip stages:

- **Full Path:** Stage 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9
- **Medium Path:** Stage 0 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 (skips 1, 2)
- **Lightweight Path:** Stage 0 -> 5 -> 6 -> 8 (skips 1, 2, 3, 4, 7, 9)

**For each path:**

1. List the stages that execute on that path.
2. For each field READ by a stage on this path, check if the field is WRITTEN by a stage that also executes on this path.
3. If a field is written only by a skipped stage, check:
   - Does the reading stage have a fallback (`.get()` with default, `if field in state`, try/except)?
   - Is the field in the initial state with a default value?
4. If no fallback exists -- mark as **PATH GAP**.

**Record:**

```
{
  "path": "lightweight",
  "field": "strategic_brief",
  "written_by_stage": "Stage 1: Strategic Review",
  "skipped_on_path": true,
  "needed_by_stage": "Stage 5: Build",
  "has_fallback": false,
  "verdict": "PATH_GAP"
}
```

### Step 7: Build Report and Write Evidence

Generate the evidence JSON and a human-readable summary.

**Verdict rules:**
- Any MISSING field (read, never written, no default) --> **FAIL**
- Any NAME MISMATCH --> **FAIL**
- Any PATH GAP without fallback handling --> **WARN**
- Any ORPHANED field --> **INFO** (not blocking, but worth noting)
- All clear --> **PASS**

**Write evidence file** to `.pineapple/evidence/verify-state-flow-<timestamp>.json` where `<timestamp>` is ISO 8601 (e.g., `2026-03-23T14-32-00Z`).

## Evidence Format

```json
{
  "skill": "/verify-state-flow",
  "timestamp": "2026-03-23T14:32:00Z",
  "state_class": "PipelineState",
  "state_file": "src/pineapple/state.py",
  "stage_files_analyzed": [
    "src/pineapple/agents/strategic_review.py",
    "src/pineapple/agents/architecture.py",
    "src/pineapple/agents/planner.py",
    "src/pineapple/agents/builder.py",
    "src/pineapple/agents/verifier.py",
    "src/pineapple/agents/reviewer.py",
    "src/pineapple/agents/shipper.py"
  ],
  "field_count": 14,
  "fields": [
    {
      "name": "strategic_brief",
      "type": "str",
      "written_by": [{"stage": "strategic_review.py", "line": 42, "conditional": false}],
      "read_by": [{"stage": "architecture.py", "line": 15}, {"stage": "planner.py", "line": 8}],
      "mismatch": false,
      "orphaned": false,
      "missing": false
    },
    {
      "name": "branch",
      "type": "str",
      "written_by": [],
      "read_by": [{"stage": "shipper.py", "line": 15, "has_fallback": false}],
      "mismatch": false,
      "orphaned": false,
      "missing": true
    }
  ],
  "name_mismatches": [
    {
      "written_as": "verify_result",
      "written_in": "verifier.py",
      "written_line": 88,
      "read_as": "verification_result",
      "read_in": "reviewer.py",
      "read_line": 22,
      "edit_distance": 3
    }
  ],
  "path_gaps": [
    {
      "path": "lightweight",
      "field": "strategic_brief",
      "written_by_stage": "Stage 1: Strategic Review",
      "skipped_on_path": true,
      "needed_by_stage": "Stage 5: Build",
      "has_fallback": false
    }
  ],
  "summary": {
    "total_fields": 14,
    "ok": 10,
    "missing": 1,
    "orphaned": 2,
    "name_mismatches": 1,
    "path_gaps": 1
  },
  "verdict": "FAIL -- 1 orphan read (branch), 1 name mismatch (verify_result vs verification_result)"
}
```

## Enforcement Rules

| Condition | Verdict | Action |
|-----------|---------|--------|
| Any field read but never written (no default) | **FAIL** | BLOCK. Fix the writer or add a default before proceeding. |
| Any name mismatch (edit distance <= 3) | **FAIL** | BLOCK. Rename to match exactly. |
| Path gap without fallback | **WARN** | Do not block, but add fallback handling or document why the field is not needed on that path. |
| Orphaned field (written, never read) | **INFO** | Note in report. Consider removing dead writes. |
| All fields consistent | **PASS** | Proceed to E2E testing. |

## What This Prevents

| Audit Issue | How |
|-------------|-----|
| H-4: Ship reads `branch` but nobody sets it | Detects orphan read -- FAIL |
| H-5: Verifier checks wrong directory | Detects field name mismatch -- FAIL |
| H-6: Wrong field name between stages | Detects typos via fuzzy matching -- FAIL |
| L-7: `tools_available` written but never used | Detects orphan write -- INFO |
| Runtime NoneType crashes | Catches missing fields before any code runs |
| Lightweight path crashes | Catches fields written by skipped stages |

## Human-Readable Output

After writing the evidence file, print a summary table to the console:

```
=== State Flow Verification ===
State class: PipelineState (14 fields)
Stages analyzed: 7

FIELD FLOW MATRIX:
| Field             | Written by         | Read by            | Status      |
|-------------------|--------------------|--------------------|-------------|
| strategic_brief   | Stage 1            | Stage 2, 3         | OK          |
| branch            | (nobody)           | Stage 8            | MISSING     |
| verify_result     | Stage 6            | (nobody)           | ORPHANED    |
| tools_available   | Stage 0            | (nobody)           | ORPHANED    |

NAME MISMATCHES:
  verify_result (verifier.py:88) vs verification_result (reviewer.py:22)

PATH GAPS:
  [lightweight] strategic_brief -- written by Stage 1 (skipped), needed by Stage 5 (no fallback)

VERDICT: FAIL
  1 missing field, 1 name mismatch, 1 path gap (WARN)
  Evidence: .pineapple/evidence/verify-state-flow-2026-03-23T14-32-00Z.json
```

## Red Flags -- STOP and Reassess

- You are running E2E tests without running this skill first
- You found a MISSING field and decided to proceed anyway ("it probably has a default somewhere")
- You matched field names case-insensitively and called it OK (`Branch` != `branch`)
- You skipped path gap analysis ("lightweight path probably does not use that field")
- You did not check nested fields (`state.workspace_info.branch` != `state.branch`)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Only checking top-level field names | Flatten nested fields to dot notation and check both levels |
| Ignoring conditional writes | Mark them as conditional -- they may not execute on all code paths |
| Treating `.get()` with no default as safe | `.get("field")` returns None, which will crash downstream if used as string/dict |
| Skipping path gap analysis | Lightweight path skips 6 stages -- this is where most gaps hide |
| Counting a field written in `__init__` as "always available" | Only if it has a real default, not `None` |
| Fuzzy matching with high threshold | Edit distance <= 3 catches `branch`/`branch_name` but not unrelated fields |
