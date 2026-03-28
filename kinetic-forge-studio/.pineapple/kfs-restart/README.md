# KFS Restart via Pineapple Pipeline

This directory contains the **complete tracking infrastructure** for restarting Kinetic Forge Studio v2 through the full Pineapple 10-stage pipeline.

## Structure

```
.pineapple/kfs-restart/
├── MANIFEST.yaml              # Single source of truth (stage progress, gates, success criteria)
├── 00-strategic-brief.md      # Stages 0-1 output (intake + strategic review)
├── 01-architecture-design.md  # Stage 2 output (TBD)
├── 02-implementation-plan.md  # Stage 3 output (TBD)
├── evidence/                  # Stage 6-7 verification artifacts
│   ├── test-results/
│   ├── vlad-validation/
│   └── code-review/
└── sessions/                  # Session handoff notes
    └── 2026-03-26.md         # This session
```

## How to Use

### 1. Update MANIFEST.yaml at Each Stage Gate

After completing a stage, update:
- `status:` from `pending` to `in_progress`/`completed`
- `end:` with completion date
- `gate:` items with ✓/✗/⏳ status

Example:
```yaml
- stage: 2
  name: Architecture
  status: completed    # ← changed from pending
  start: 2026-03-26
  end: 2026-03-27     # ← filled in
  ...
```

### 2. Add Artifacts as You Complete Each Stage

- **Stage 2 (Architecture):** Add `01-architecture-design.md`
- **Stage 3 (Planning):** Add `02-implementation-plan.md`
- **Stage 6 (Verify):** Add evidence to `evidence/`
- **Stage 7 (Review):** Add code review report
- **Stage 8 (Ship):** Commit updated `kfs-bible-v2.yaml`

### 3. Verify Against Success Criteria

Every artifact should demonstrate one or more success criteria:

```bash
# SC-01: Store and version CadQuery modules
pytest backend/tests/test_module_manager.py

# SC-02: Execute modules and write STL/STEP
pytest backend/tests/test_module_executor.py

# ... (see MANIFEST.yaml for all 10)
```

### 4. Gate Between Stages

**Do NOT proceed to the next stage until:**
1. All gate items in current stage are ✓
2. All success criteria for that stage are verified
3. User approval obtained (for stages 2, 3, 7)
4. Tests pass (for stages 4, 5, 6)

## Key Files Reference

| File | Stage | Purpose |
|------|-------|---------|
| MANIFEST.yaml | All | Single source of truth, stage tracking, gates |
| 00-strategic-brief.md | 0-1 | Vision, success criteria, scope, ADRs, risks |
| 01-architecture-design.md | 2 | 10-module design, diagrams, file list |
| 02-implementation-plan.md | 3 | Step-by-step implementation, dependencies, effort |
| evidence/* | 6-7 | Test results, VLAD validation, code review |

## Committing to Git

Every stage produces artifacts that should be committed:

```bash
# Stage 0-1 (Strategic Brief)
git add .pineapple/kfs-restart/
git commit -m "docs: KFS restart via Pineapple — Stages 0-1 complete (strategic brief)"

# Stage 2 (Architecture)
git add .pineapple/kfs-restart/01-architecture-design.md
git commit -m "docs: KFS restart Stage 2 — Architecture design (10 modules, diagrams)"

# Stage 5 (Build)
git add backend/app/workspace/ backend/app/engines/ ...
git commit -m "feat: KFS restart Stage 5 — Implement 10 modules (module manager, executor, VLAD runner, etc.)"

# Stage 6 (Verify)
git add .pineapple/kfs-restart/evidence/
git commit -m "test: KFS restart Stage 6 — Verification complete (contract tests 100%, VLAD validation)"
```

## Success: All Stages Complete

When all 10 stages are done:

- ✓ MANIFEST.yaml shows all stages `completed`
- ✓ KFS can store/version modules (not shape factory output)
- ✓ Modules execute deterministically (STL/STEP written to disk)
- ✓ VLAD validates automatically
- ✓ Three.js renders real geometry
- ✓ .kfs.yaml manifest generated
- ✓ MCP exposes VLAD + CadQuery
- ✓ Observability tracks LLM calls
- ✓ All 10 success criteria verified
- ✓ All 10 ADRs implemented
- ✓ Merged to main, gaps closed, session handoff written

---

**Current Status:** Stage 0-1 ✓ complete. Ready for Stage 2 (Architecture).
