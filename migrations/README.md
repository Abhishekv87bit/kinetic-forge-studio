# MIGRATIONS FOLDER
## Version Upgrade Management for 3D Mechanical Design Workspace

---

> **This folder manages version migrations, schema changes, and upgrade procedures.**

---

## PURPOSE

The migrations folder enables:
- Safe upgrades between workspace versions
- Documented breaking changes
- Rollback procedures when upgrades fail
- Schema evolution tracking

---

## FOLDER STRUCTURE

```
migrations/
├── README.md                    # This file
├── templates/
│   └── migration_template.md    # Template for new migrations
├── schema/
│   └── workspace_schema_v1.md   # Current schema definition
└── v1_to_v2/                    # Version-specific migrations
    └── [migration_files]
```

---

## MIGRATION TYPES

| Type | Description | Risk Level | Example |
|------|-------------|------------|---------|
| **Schema** | Workspace structure changes | Medium | New folder added |
| **Breaking** | Incompatible changes requiring modification | High | Parameter renamed |
| **Non-breaking** | Additive changes, backward compatible | Low | New optional parameter |
| **Config** | Configuration/settings changes | Low | New hook added |

---

## CREATING A MIGRATION

### Step 1: Create Version Folder
```bash
mkdir "migrations/v1_to_v2"
```

### Step 2: Copy Template
```bash
cp "migrations/templates/migration_template.md" "migrations/v1_to_v2/migration.md"
```

### Step 3: Document Changes
Fill in all sections of the migration template:
- Overview (versions, type, risk)
- Changes summary
- Pre-migration checklist
- Step-by-step migration
- Post-migration verification
- Rollback procedure

### Step 4: Test Migration
- Run migration on a backup copy first
- Verify all steps complete successfully
- Confirm rollback works

---

## RUNNING A MIGRATION

### Pre-Flight Checklist
```
[ ] Read the complete migration document
[ ] Backup current workspace
[ ] Commit all pending changes to git
[ ] Verify no uncommitted work exists
[ ] Confirm you have rollback plan ready
```

### Migration Steps
1. **Backup First**
   ```bash
   git commit -m "Pre-migration backup"
   git tag pre-migration-v1
   ```

2. **Read Migration Document**
   Understand all changes before starting.

3. **Run Pre-Checks**
   Execute any verification scripts in the migration.

4. **Execute Migration Steps**
   Follow steps in order. Do not skip steps.

5. **Run Post-Checks**
   Verify migration completed successfully.

6. **Commit Result**
   ```bash
   git commit -m "Migrated from v1 to v2"
   git tag post-migration-v2
   ```

---

## ROLLBACK PROCEDURE

If migration fails at any step:

### Immediate Rollback
```bash
git reset --hard pre-migration-v1
```

### Investigate Failure
1. Document where migration failed
2. Note any partial changes made
3. Identify root cause

### Retry After Fix
1. Fix the issue
2. Update migration document if needed
3. Restart from beginning

---

## SCHEMA VERSIONING

The current workspace schema is documented in `schema/workspace_schema_v1.md`.

### Schema Includes
- Folder structure definition
- File naming conventions
- Required files list
- Configuration format

### When to Update Schema
- Adding new required folders
- Changing file organization
- Introducing new file types
- Modifying configuration structure

---

## BEST PRACTICES

### 1. Always Document
Every migration must have complete documentation including:
- What changes
- Why it changes
- How to verify success
- How to rollback

### 2. Test First
Run migrations on a copy before applying to real workspace.

### 3. Atomic Changes
Each migration should be a single logical change. Don't combine unrelated changes.

### 4. Include Rollback
Every migration MUST have a working rollback procedure.

### 5. Version Tags
Use git tags to mark pre and post migration states.

---

## EXAMPLE: MIGRATION SUMMARY

```
Migration: v1 → v2
Type: Schema (Non-breaking)
Risk: Low

Changes:
+ Added: docs/ folder for extended documentation
+ Added: User Skills/ folder for custom workflows
+ Added: migrations/ folder (this folder)
+ Modified: CLAUDE.md (added references to new folders)
+ Modified: MASTER_REFERENCE.md (added section 15)

Verification:
[ ] All new folders exist
[ ] CLAUDE.md contains new references
[ ] MASTER_REFERENCE.md has section 15
[ ] Existing files unchanged

Rollback:
  git reset --hard pre-migration-v1
```

---

*Migrations ensure safe evolution of your workspace.*
*Always document. Always backup. Always test.*
