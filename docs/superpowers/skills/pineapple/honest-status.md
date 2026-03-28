---
name: honest-status
description: "Evidence-backed progress reporting. Before ANY scorecard, status update, completion claim, or session handoff, compile a report card from /verify-done evidence files. Only WORKING counts as done. BLOCKS false confidence claims."
---

# /honest-status

Evidence-backed progress reporting. The user should NEVER be surprised by a brutal honesty audit. If this skill is used correctly, an audit would find nothing new.

**Spec:** `docs/ENFORCEMENT_SKILLS_SPEC.md` (Skill 6)

## When to Invoke

Invoke this skill BEFORE:
- Any progress report to the user (scorecard, status update, "X done")
- Writing session handoffs (`sessions/YYYY-MM-DD.md`)
- Updating project bibles (closing gaps, noting progress)
- Claiming "done" on any milestone or sprint
- Answering "is it done?" or "how far along are we?"
- Presenting success criteria results

If you are about to tell the user how things are going, run this first.

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `features` | list of strings | Yes | Every feature or criterion being reported on |
| `evidence_dir` | path | No | Defaults to `.pineapple/evidence/` |

## Process

Follow these steps exactly. Do not skip steps. Do not summarize.

### Step 1: List Every Feature Being Reported

Write out the full list of features, criteria, or gaps you are about to report on. Every single one. If you are reporting on 10 success criteria, list all 10. If you are closing 5 gaps, list all 5.

Do NOT cherry-pick the ones that are working. List them all.

### Step 2: Check for Evidence Files

For each feature in the list:
- Look for a `/verify-done` evidence file at `.pineapple/evidence/<feature-slug>.json`
- The evidence file must exist on disk (use `ls` or `test -f`, not memory)
- Read the file and extract the `status` field and `verdict` field

If the file does not exist, the feature is **UNVERIFIED**. You cannot claim any status for it. Not WORKING. Not WIRED. Not even STUBBED. You simply do not know.

### Step 3: Classify Each Feature

For each feature, assign exactly one status based on evidence:

| Status | Source | Meaning |
|--------|--------|---------|
| **WORKING** | Evidence file says WORKING | Runs with real inputs, correct output, tested E2E |
| **WIRED** | Evidence file says WIRED | Library imported and called, behavior not verified |
| **STUBBED** | Evidence file says STUBBED | Function exists but does not do what its name says |
| **FAKE** | Evidence file says FAKE | Returns hardcoded/placeholder data |
| **UNVERIFIED** | No evidence file exists | Unknown status -- no claim can be made |

You MUST use the status from the evidence file. You cannot override it with your own judgment. If the evidence says STUBBED, it is STUBBED -- even if you "think" it works.

### Step 4: Generate the Report Card

Print this exact format:

```
## Status Report: <project> (<YYYY-MM-DD>)

### STUBBED (must fix before shipping)
| # | Feature | Evidence | Detail |
|---|---------|----------|--------|
| 1 | <name>  | <path>   | <what is stubbed and why> |

### FAKE (must fix before shipping)
| # | Feature | Evidence | Detail |
|---|---------|----------|--------|
| 1 | <name>  | <path>   | <what is faked and why> |

### UNVERIFIED (no evidence -- run /verify-done)
| # | Feature | Evidence | Detail |
|---|---------|----------|--------|
| 1 | <name>  | (none)   | No evidence file found |

### WIRED (imported but not behavior-tested)
| # | Feature | Evidence | Last Verified |
|---|---------|----------|---------------|
| 1 | <name>  | <path>   | <date> |

### WORKING (verified with evidence)
| # | Feature | Evidence | Last Verified |
|---|---------|----------|---------------|
| 1 | <name>  | <path>   | <date> |

---

**Summary: X WORKING, Y WIRED, Z STUBBED, W FAKE, V UNVERIFIED**

**Honest score: X/<total> WORKING**

<READY TO SHIP / NOT READY TO SHIP>
```

STUBBED, FAKE, and UNVERIFIED sections appear FIRST, before WIRED and WORKING. The bad news comes first. Always.

If a section has zero items, print the header with "(none)" underneath. Do not omit sections.

### Step 5: Calculate Honest Score

- Only WORKING counts toward the score
- The denominator is the TOTAL number of features (not just the ones with evidence)
- Example: 4 WORKING out of 10 total = "4/10 WORKING" (not "4/6" by excluding unknowns)

If any feature is not WORKING, the report MUST end with: **NOT READY TO SHIP. <N>/<total> features are not working.**

### Step 6: Write Evidence Summary

Write a summary evidence file to `.pineapple/evidence/status-report-<YYYY-MM-DD>.json`:

```json
{
  "skill": "/honest-status",
  "timestamp": "<ISO 8601>",
  "project": "<project name>",
  "features_total": <N>,
  "features_working": <N>,
  "features_wired": <N>,
  "features_stubbed": <N>,
  "features_fake": <N>,
  "features_unverified": <N>,
  "ready_to_ship": false,
  "features": [
    {
      "name": "<feature>",
      "status": "WORKING|WIRED|STUBBED|FAKE|UNVERIFIED",
      "evidence_file": "<path or null>",
      "detail": "<one-line summary>"
    }
  ]
}
```

## Banned Vocabulary

These words and patterns are BANNED from any output produced while this skill is active. If you catch yourself writing any of these, stop and rewrite.

| Banned | Replacement |
|--------|-------------|
| "MET" (as a status) | WORKING, WIRED, STUBBED, FAKE, or UNVERIFIED |
| "all green" | State actual count: "4 WORKING, 3 WIRED, 2 STUBBED, 1 FAKE" |
| "tests pass" (without detail) | State what they test: "53 v2 tests pass, 288 v1 tests are irrelevant" |
| "X/10" (without status breakdown) | "4/10 WORKING, 3/10 WIRED, 3/10 NOT STARTED" |
| "criteria met" | "criteria WORKING" (with evidence) |
| "looks good" | State what was verified and how |
| "should work" | Run /verify-done and get actual evidence |
| "all done" | State the honest score with breakdown |

## Enforcement Rules

1. **Cannot present a scorecard without evidence files for each item.** If you have no evidence files, the entire report is UNVERIFIED. You must say so.

2. **Cannot use banned vocabulary.** Not in the report card, not in the summary, not in conversation with the user. If you write "MET", delete it and rewrite.

3. **STUBBED and FAKE items must be prominent.** They appear in the FIRST sections of the report, not buried at the bottom. The user sees bad news first.

4. **Cannot round up.** 4/10 WORKING is not "almost half done." It is 4/10 WORKING, 6/10 not working.

5. **Cannot exclude unknowns from the denominator.** If 4 features are WORKING and 6 are UNVERIFIED, the score is 4/10 -- not 4/4.

6. **Cannot claim WORKING without a /verify-done evidence file.** Even if you "know" it works. Even if you just ran it. The evidence file is the proof. No file, no claim.

7. **Cannot skip this skill.** If you are about to report progress and you did not run /honest-status, you are violating the enforcement protocol. Stop and run it.

## What This Prevents

| Problem | How /honest-status Prevents It |
|---------|-------------------------------|
| "10/10 MET" false confidence | Cannot say MET, must show evidence for each item |
| Session handoffs that overstate progress | Requires evidence files for every claim in the handoff |
| Bible updates that close gaps without verification | UNVERIFIED status for gaps without evidence |
| User surprise during brutal honesty audit | If /honest-status ran correctly, the audit finds nothing new |
| Cherry-picking working features | Full list required -- every feature must appear |
| Hiding STUBBED/FAKE behind working items | Bad news sections appear first in the report |

## Integration with Pineapple Pipeline

- **Stage 7 (Review):** Reviewer runs /honest-status to see real feature statuses before reviewing
- **Stage 9 (Evolve):** Session handoff uses /honest-status output as the authoritative progress summary
- **Any time user asks "how are we doing?":** Run /honest-status, not a vibes-based summary

## Key Principle

> The user should NEVER be surprised by a brutal honesty audit. If /honest-status is used correctly, the audit would find nothing new. Every STUBBED feature, every FAKE integration, every UNVERIFIED claim -- all of it is already visible in the report card, shown prominently, with no euphemisms.
