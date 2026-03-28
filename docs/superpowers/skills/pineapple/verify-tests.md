---
name: verify-tests
description: "Enforcement skill that honestly reports what tests actually test before any test claims are made. Separates v1/v2 test counts, maps coverage gaps, detects fake tests, and blocks inflated test claims."
---

# /verify-tests -- Honest Test Coverage Reporting

Pineapple enforcement skill. Before claiming "X tests pass" or "test coverage is good," prove what the tests actually test.

**Spec:** `docs/ENFORCEMENT_SKILLS_SPEC.md` (Skill 4)
**Trigger:** Any moment you are about to claim test results, report coverage, or state that tests pass.
**Output:** Evidence file at `.pineapple/evidence/verify-tests-<timestamp>.json`

<HARD-GATE>
You CANNOT claim "X tests pass" without stating WHAT they test (v1 or v2).
You CANNOT claim "good coverage" when >50% of public functions are untested.
You CANNOT count v1 tests toward v2 coverage. They are separate codebases.
You MUST flag test files that import from the wrong module (v1 when v2 exists).
</HARD-GATE>

## When to Invoke

- Before claiming test results in any status report, progress update, or conversation
- During Stage 6 (Verify) of the pipeline
- When migrating from v1 to v2 of any system
- Before any commit message or PR description that mentions test counts or coverage
- Anytime the words "tests pass," "test coverage," or "X/Y tests" appear in your output

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `test_dir` | path | Yes | Directory containing test files |
| `source_dir` | path | Yes | Directory containing source code being tested |
| `v2_modules` | list[string] | No | Module paths that are "v2" (current). Everything else is legacy. If omitted, infer from project structure. |

## Process

You MUST follow these steps in strict order. Each step completes before the next begins. No shortcuts. No skipping steps because "it looks fine."

### Step 1: Inventory Test Files

Find every test file in `test_dir`:
- Match patterns: `test_*.py`, `*_test.py`, `conftest.py`
- For EACH test file:
  - Extract all `import` and `from ... import` statements
  - Count test functions (`def test_*`)
  - Count test classes (`class Test*`)
  - Record the file path

**Record:** A list of `{path, imports, test_function_count, test_class_count}`.

Do NOT summarize. List every file.

### Step 2: Classify Each Test File (v1 vs v2)

For each test file from Step 1, classify based on its imports:

| Import pattern | Classification |
|---------------|---------------|
| Imports from `source_dir` (v2 modules) | **v2 test** |
| Imports from legacy/old module paths | **v1 test** |
| Imports from external packages only | **external test** |
| No clear imports (tests internal logic only) | **orphan test** |

**Flag these problems:**
- Test imports from v1 module when a v2 equivalent exists (stale test)
- Test imports from a module that no longer exists on disk (dead test)
- Test file name suggests v2 but imports v1 (misleading test)

**Record:** Each test file now has a `tests_v1_or_v2` field.

### Step 3: Map v2 Coverage

For every source file in `source_dir`:

1. List all public functions (not starting with `_`) and classes
2. For each function/class, search across all v2 test files:
   - Is it imported in any test file?
   - Is it called in any test function?
   - Mark: `has_test: true` or `has_test: false`
3. Produce per-module summary: `{module, functions_total, functions_tested, functions_untested_list}`

**Special attention to:**
- CLI entry points (often untested)
- MCP server endpoints (often untested)
- Agent node functions (often untested)
- Middleware/observability code (often untested)

### Step 4: Detect Fake Tests

Scan every test function for these patterns. A fake test inflates the count without testing anything real.

| Pattern | Classification | Example |
|---------|---------------|---------|
| `assert True` | **Fake** | Placeholder that always passes |
| `assert 1 == 1` | **Fake** | Tautology |
| `pass` as only body | **Fake** | Empty test |
| `pytest.skip(...)` as only body | **Fake** | Skipped unconditionally |
| `pytest.mark.skip` with no conditional | **Fake** | Permanently disabled |
| `@pytest.mark.xfail` with no bug tracker link | **Suspicious** | Expected failure with no plan to fix |
| All external calls mocked, no real assertion on behavior | **Suspicious** | Tests the mock, not the code |
| Test name says "test_X" but never calls X | **Suspicious** | Misleading name |
| Only asserts `is not None` or `isinstance` | **Weak** | Existence check, not behavior check |

**Record:** `{path, line, function_name, reason}` for every fake or suspicious test.

**Count rule:** Fake tests do NOT count toward "tests passing." They are reported separately.

### Step 5: Generate Honest Report

Compile everything from Steps 1-4 into a single honest report. The report MUST use this exact format:

```
=== HONEST TEST REPORT ===

TEST INVENTORY:
- Total test files: N
- Total test functions: N
- v2 tests (testing current code): N
- v1 tests (testing legacy code): N
- External/orphan tests: N
- Fake/placeholder tests: N

V2 COVERAGE:
- v2 modules with tests: N / M
- v2 public functions tested: N / M (X%)
- v2 public functions UNTESTED:
  - module.function1
  - module.function2
  - ...

ZERO-COVERAGE MODULES:
- src/pineapple/agents/evolver.py (0 tests)
- src/pineapple/middleware/observability.py (0 tests)
- ...

FAKE TESTS FOUND:
- tests/test_foo.py:42 test_placeholder -- assert True
- tests/test_bar.py:17 test_nothing -- pass only
- ...

WRONG-MODULE IMPORTS:
- tests/test_old.py imports from production_pipeline.tools (v1) but v2 equivalent exists at src/pineapple/tools
- ...

VERDICT: <one-line honest summary>
```

### Step 6: Write Evidence File

Write the evidence JSON to `.pineapple/evidence/verify-tests-<timestamp>.json` where timestamp is `YYYYMMDD-HHMMSS`.

```json
{
  "skill": "/verify-tests",
  "timestamp": "<ISO 8601>",
  "test_dir": "<path>",
  "source_dir": "<path>",
  "test_files": [
    {
      "path": "tests/test_builder.py",
      "imports_from": ["src.pineapple.agents.builder"],
      "tests_v1_or_v2": "v2",
      "test_function_count": 5,
      "real_assertions_count": 12,
      "fake_tests": 0
    }
  ],
  "v2_coverage": [
    {
      "module": "src/pineapple/agents/builder.py",
      "functions_total": 8,
      "functions_tested": 3,
      "has_test": {
        "build": true,
        "parse_task": true,
        "commit_changes": true,
        "write_files": false,
        "validate_output": false,
        "rollback": false,
        "cleanup": false,
        "report_progress": false
      }
    }
  ],
  "fake_tests": [
    {
      "path": "tests/test_placeholder.py",
      "line": 42,
      "function": "test_placeholder",
      "reason": "assert True -- placeholder that always passes"
    }
  ],
  "wrong_module_imports": [
    {
      "test_file": "tests/test_legacy.py",
      "imports": "production_pipeline.tools.validator",
      "should_import": "pineapple.tools.validator",
      "reason": "v1 import when v2 equivalent exists"
    }
  ],
  "summary": {
    "total_test_files": 57,
    "total_test_functions": 341,
    "v2_tests": 53,
    "v1_tests": 288,
    "external_tests": 0,
    "fake_test_count": 4,
    "v2_modules_total": 15,
    "v2_modules_with_tests": 6,
    "v2_functions_total": 89,
    "v2_functions_tested": 31,
    "v2_functions_untested": 58,
    "coverage_percentage": 34.8,
    "zero_coverage_modules": [
      "src/pineapple/agents/evolver.py",
      "src/pineapple/middleware/observability.py"
    ]
  },
  "honest_report": "53 v2 tests (testing current code), 288 v1 tests (testing dead code). 58 of 89 v2 public functions have zero test coverage (34.8%). 4 fake tests detected. CLI: 0 tests. MCP: 0 tests.",
  "documents_cross_referenced": [],
  "verdict": "<WORKING|WIRED|STUBBED|FAKE> -- <explanation>"
}
```

## Enforcement Rules

These are non-negotiable. Violating any of these is a BLOCK.

### Rule 1: No Unqualified Test Claims

**BLOCKED:** "341 tests pass"
**ALLOWED:** "53 v2 tests pass (testing current code). 288 v1 tests pass (testing legacy code that is not part of v2)."

Every test count MUST state what the tests test.

### Rule 2: No Inflated Coverage Claims

**BLOCKED:** "Good test coverage" when >50% of v2 public functions are untested.
**BLOCKED:** "Tests cover the main functionality" when zero-coverage modules exist.
**ALLOWED:** "31 of 89 v2 functions tested (34.8%). 4 modules have zero coverage: [list]."

### Rule 3: No Counting Fake Tests

**BLOCKED:** Including `assert True` or `pass`-only tests in the passing count.
**ALLOWED:** "53 v2 tests, of which 4 are fake placeholders. 49 real v2 tests pass."

### Rule 4: No Cross-Module Confusion

**BLOCKED:** Claiming v2 coverage based on tests that import from v1 modules.
**BLOCKED:** Ignoring that a test file imports from a module path that no longer exists.
**ALLOWED:** "12 test files import from v1 (production_pipeline.*) -- these do NOT count as v2 coverage."

### Rule 5: Untested Functions Must Be Named

**BLOCKED:** "Most functions are tested" without listing the untested ones.
**ALLOWED:** "Untested v2 functions: write_files, validate_output, rollback, cleanup, report_progress (builder.py); all functions in evolver.py (0/6); all functions in observability.py (0/4)."

## Red Flags -- STOP and Reassess

- You are about to say "tests pass" without having run this skill first
- You are counting v1 tests toward v2 coverage
- You found >10 fake tests (the test suite may be largely decorative)
- You found >70% of v2 functions untested (coverage claim would be dishonest)
- A test file imports from a path that does not exist on disk (dead import)
- You are running pytest on a directory and reporting the total without classifying what each test tests

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Counting all pytest output as "v2 tests" | Classify every test file by its imports |
| Saying "288 tests pass" without context | Say "288 tests pass, but 288 test v1 dead code" |
| Ignoring fake tests in the count | Subtract fake tests from the real count |
| Reporting pytest exit code 0 as "all good" | Exit code 0 means no failures, not good coverage |
| Skipping Step 3 (coverage map) | The coverage map is the whole point -- do not skip it |
| Not listing untested functions by name | Name every untested public function |
| Claiming coverage based on file count | Coverage = functions tested / functions total, not files |

## What This Prevents

| Audit Issue | How |
|-------------|-----|
| C-3: 288 tests test v1 dead code, claimed as v2 coverage | Separates v1/v2 test counts, blocks unqualified claims |
| M-6/M-7/M-8: Zero coverage on agent functions | Lists every untested function by name |
| L-3: v1 stage names in tests | Flags imports from legacy modules |
| Fake tests inflating pass count | Detects and excludes fake/placeholder tests |
| "Good coverage" with 34% actual coverage | Blocks coverage claims when >50% untested |
