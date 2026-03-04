# KFS Checklist-Gated Sessions — Design Doc

**Date:** 2026-03-03
**Problem:** Gaps keep getting lost across sessions. Features marked "done" are actually stubs. LLM provider never switched to Claude. scad_dir intake never wired.
**Solution:** Machine-readable gap tracker with verification tests, mandatory session start/end protocol.

## Root Cause

Three failure modes were identified:
1. **Claiming done without testing** — Steps 20-24 of Rule 500 were marked implemented but are static stubs
2. **Not reading state at session start** — Project YAML was stale for 2+ sessions, still listing fixed gaps as open
3. **No acceptance tests** — No way to prove a feature works besides "I wrote the code"

## Design

### Artifact: `kfs-gaps.yaml`

Location: `memory/projects/kfs-gaps.yaml`

Each gap entry has:
- `id` — stable reference (GAP-01 through GAP-XX)
- `severity` — critical > high > medium > low (work order)
- `status` — open → in_progress → closed → verified
- `verify` — concrete command/test that proves the fix works
- `closed_by` / `verified_by` — session date stamps

### Protocol

**Session Start:**
1. Read `kinetic-forge-studio.yaml` → read `kfs-gaps.yaml`
2. Report gap status to user
3. Pick highest-severity open gap

**Session End:**
1. Run verify command for each gap worked on
2. Update YAML with results
3. Write session handoff note

**Rules:**
- "closed" requires verify command to have been run
- "verified" requires user to have seen the output
- New gaps get added immediately when discovered

### Work Order (Priority)

| Order | Gap | Severity | Est. Time |
|-------|-----|----------|-----------|
| 1 | GAP-01: Claude provider priority | critical | 5 min |
| 2 | GAP-02: scad_dir file intake | critical | 30 min |
| 3 | GAP-04: consultant_context wiring | high | 10 min |
| 4 | GAP-03/07: Rule 500 step 20 CadQuery | high | 20 min |
| 5 | GAP-05: Export ZIP completeness | high | 15 min |
| 6 | GAP-06: Rule 500 steps 30-31 | medium | 15 min |
| 7 | GAP-08: architecture_validator.py | medium | 20 min |
| 8 | GAP-09: fdm_validator.py | medium | 15 min |
| 9 | GAP-10: Missing component geometry types | medium | 10 min |
| 10 | GAP-11: ntfy.sh config | low | 2 min |
| 11 | GAP-12: Delete dead claude_client.py | low | 2 min |

Total estimated: ~2.5 hours of implementation across 1-2 sessions.

## Files Created/Modified

- **Created:** `memory/projects/kfs-gaps.yaml` — gap tracker
- **Modified:** `memory/projects/kinetic-forge-studio.yaml` — updated to actual state
- **Modified:** `memory/MEMORY.md` — added KFS Session Protocol section
- **Created:** This design doc

## Success Criteria

- Every KFS session starts with gap status report
- No gap is marked closed without a passing verify test shown to the user
- Project YAML always reflects reality, not aspiration
- New gaps are captured immediately, not forgotten
