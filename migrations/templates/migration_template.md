# MIGRATION: v[X] → v[Y]

---

> **Template for documenting version migrations**
> Delete this instruction block after filling in your migration.

---

## Overview

| Property | Value |
|----------|-------|
| From Version | v[X] |
| To Version | v[Y] |
| Migration Type | [breaking / non-breaking / schema / config] |
| Risk Level | [low / medium / high] |
| Estimated Duration | [X minutes] |
| Tested | [yes / no] |
| Reversible | [yes / no] |

---

## Summary

[One paragraph describing what this migration accomplishes and why it's needed.]

---

## Changes

### Breaking Changes
Changes that require modification to existing code/config:

| Change | Impact | Required Action |
|--------|--------|-----------------|
| [Change 1] | [What breaks] | [How to fix] |
| [Change 2] | [What breaks] | [How to fix] |

### New Features
Additions that don't break existing functionality:

| Addition | Description |
|----------|-------------|
| [Feature 1] | [What it does] |
| [Feature 2] | [What it does] |

### Modifications
Changes to existing elements:

| Element | Before | After | Reason |
|---------|--------|-------|--------|
| [Element 1] | [Old value] | [New value] | [Why changed] |

### Deprecations
Elements being phased out:

| Element | Replacement | Removal Version |
|---------|-------------|-----------------|
| [Element 1] | [New element] | v[Z] |

### Removals
Elements completely removed:

| Element | Reason | Migration Path |
|---------|--------|----------------|
| [Element 1] | [Why removed] | [What to use instead] |

---

## Pre-Migration Checklist

Complete ALL items before starting migration:

```
[ ] Current version confirmed as v[X]
[ ] All files committed to git (no uncommitted changes)
[ ] Backup created (git tag or copy)
[ ] Migration document read completely
[ ] Rollback procedure understood
[ ] Sufficient time available (no interruptions expected)
[ ] Dependencies verified:
    [ ] [Dependency 1]
    [ ] [Dependency 2]
```

---

## Migration Steps

### Step 1: [Action Name]

**Purpose:** [What this step accomplishes]

**Commands/Actions:**
```bash
[Command to execute]
```

**Expected Result:**
```
[What output or state to expect]
```

**Verification:**
```
[ ] [How to verify step completed correctly]
```

---

### Step 2: [Action Name]

**Purpose:** [What this step accomplishes]

**Commands/Actions:**
```bash
[Command to execute]
```

**Expected Result:**
```
[What output or state to expect]
```

**Verification:**
```
[ ] [How to verify step completed correctly]
```

---

### Step 3: [Action Name]

**Purpose:** [What this step accomplishes]

**Manual Actions:**
1. [Action 1]
2. [Action 2]
3. [Action 3]

**Expected Result:**
[What state should exist after this step]

**Verification:**
```
[ ] [How to verify step completed correctly]
```

---

## Post-Migration Verification

Complete ALL items after migration:

```
CRITICAL CHECKS:
[ ] [Critical verification 1]
[ ] [Critical verification 2]
[ ] [Critical verification 3]

FUNCTIONAL CHECKS:
[ ] [Functional test 1]
[ ] [Functional test 2]
[ ] [Functional test 3]

INTEGRATION CHECKS:
[ ] [Integration test 1]
[ ] [Integration test 2]

DOCUMENTATION CHECKS:
[ ] All references updated
[ ] Version numbers incremented
[ ] Changelog updated
```

---

## Rollback Procedure

If migration fails, execute these steps to restore previous state:

### When to Rollback
- Any critical check fails
- Unexpected errors during migration
- User requests abort

### Rollback Steps

#### Rollback Step 1: Stop Migration
```
Do not proceed with remaining migration steps.
Document exactly where migration failed.
```

#### Rollback Step 2: Restore from Backup
```bash
git reset --hard pre-migration-v[X]
```

#### Rollback Step 3: Verify Restoration
```
[ ] All files restored to pre-migration state
[ ] No partial changes remain
[ ] System functions correctly
```

#### Rollback Step 4: Document Failure
```
Record:
- Which step failed
- Error message or symptom
- Any partial state that may persist
```

---

## Known Issues

| Issue | Workaround | Planned Fix |
|-------|------------|-------------|
| [Issue 1] | [How to work around] | [When/how will be fixed] |
| [Issue 2] | [How to work around] | [When/how will be fixed] |

---

## Related Migrations

| Migration | Relationship |
|-----------|--------------|
| v[W] → v[X] | Previous migration (must be completed first) |
| v[Y] → v[Z] | Next migration (builds on this one) |

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| YYYY-MM-DD | [Name] | Initial migration document |

---

## Author

- Created by: [Name]
- Reviewed by: [Name]
- Approved by: [Name]
- Date: [YYYY-MM-DD]

---

*Migration Version: 1.0*
*Last Updated: [Date]*
