# WORKSPACE SCHEMA v1
## 3D Mechanical Design Workspace Structure Definition

---

> **This document defines the canonical structure of the workspace at schema version 1.**

---

## Schema Version

| Property | Value |
|----------|-------|
| Schema Version | 1.0 |
| Created | 2026-01-17 |
| Status | Active |

---

## FOLDER STRUCTURE

```
D:\Claude local\                        # Workspace Root
│
├── CLAUDE.md                           # Root configuration file
├── .gitignore                          # Git ignore rules
│
├── 3d_design_agent/                    # Main design agent folder
│   │
│   ├── docs/                           # Extended documentation
│   │   ├── POLYMATH_LENS.md            # Design philosophy
│   │   ├── STATE_MACHINES.md           # State diagrams
│   │   └── XML_TAGS_REFERENCE.md       # XML tag definitions
│   │
│   ├── components/                     # Reusable mechanical components
│   │   └── wrappers/                   # Shape wrapper modules
│   │
│   ├── mechanisms/                     # Complete mechanism assemblies
│   │
│   ├── specs/                          # Design specifications
│   │
│   ├── scripts/                        # Automation scripts
│   │
│   ├── Reference/                      # Historical versions
│   │
│   ├── AR/                             # Archive
│   │
│   ├── CLAUDE.md                       # Agent-specific config (reference)
│   ├── unified_system_prompt.md        # Agent identity
│   ├── skills.md                       # Skill definitions
│   ├── hooks.md                        # Hook definitions
│   ├── sub_agents.md                   # Sub-agent definitions
│   ├── issues_and_mitigations.md       # Known issues
│   ├── MASTER_REFERENCE.md             # Consolidated reference
│   ├── QUICK_REFERENCE.md              # Quick lookup
│   ├── USER_VISION_ELEMENTS.md         # User vision doc
│   ├── master_specification_template.md # Spec template
│   └── IMPLEMENTATION_REPORT.md        # Status report
│
├── User Skills/                        # User customizations
│   ├── README.md                       # User skills documentation
│   ├── templates/                      # Blank templates
│   │   ├── skill_template.md
│   │   └── hook_template.md
│   ├── custom_commands/                # Custom slash commands
│   └── overrides/                      # Override definitions
│
├── migrations/                         # Version migrations
│   ├── README.md                       # Migration documentation
│   ├── templates/
│   │   └── migration_template.md
│   └── schema/
│       └── workspace_schema_v1.md      # This file
│
└── 3d mechanical design/               # Legacy folder (deprecated)
```

---

## FILE TYPES

### Configuration Files

| Pattern | Description | Location |
|---------|-------------|----------|
| `CLAUDE.md` | Root project configuration | Root, 3d_design_agent/ |
| `*.md` (in docs/) | Extended documentation | 3d_design_agent/docs/ |
| `*.md` (in specs/) | Design specifications | 3d_design_agent/specs/ |

### Design Files

| Pattern | Description | Location |
|---------|-------------|----------|
| `*.scad` | OpenSCAD source files | 3d_design_agent/, components/, mechanisms/ |
| `*_v[N].scad` | Versioned design files | 3d_design_agent/, Reference/ |
| `*_MASTER.scad` | Master/stable versions | 3d_design_agent/ |

### Export Files

| Pattern | Description | Location |
|---------|-------------|----------|
| `*.stl` | 3D mesh exports | exports/ (generated) |
| `*.svg` | Vector profiles | exports/ (generated) |
| `*.dxf` | CAD exchange | exports/ (generated) |

### Script Files

| Pattern | Description | Location |
|---------|-------------|----------|
| `*.bat` | Windows batch scripts | scripts/ |
| `*.ps1` | PowerShell scripts | scripts/ |
| `*.py` | Python scripts | scripts/ |

---

## NAMING CONVENTIONS

### Design Files
```
[project]_v[version].scad           # starry_night_v30.scad
[project]_v[version]_MASTER.scad    # starry_night_v50_MASTER.scad
[component]_[type].scad             # gear_spur_24t.scad
[mechanism]_v[version].scad         # wave_mechanism_v48.scad
```

### Documentation Files
```
[TOPIC]_[TYPE].md                   # USER_VISION_ELEMENTS.md
[topic]_spec.md                     # gear_train_spec.md
[TOPIC].md                          # POLYMATH_LENS.md
```

### Skill Files
```
skill_template.md                   # Template
[skill_name].md                     # Custom skill
[skill_name]-override.md            # Override
```

---

## REQUIRED FILES

These files MUST exist for the workspace to function:

### Root Level
- `CLAUDE.md` - Project configuration

### 3d_design_agent/
- `unified_system_prompt.md` - Agent identity
- `skills.md` - Skill definitions
- `hooks.md` - Hook definitions
- `MASTER_REFERENCE.md` - Consolidated reference

### User Skills/
- `README.md` - User documentation

### migrations/
- `README.md` - Migration documentation

---

## CONFIGURATION FORMAT

### CLAUDE.md Structure
```markdown
# CLAUDE.md - [Title]

## Project Context
[Project description]

## Critical Context - NEVER FORGET
[Non-negotiable rules]

## Key Files and Structure
[File organization]

## Hooks Configuration
[Hook definitions]

## Custom Commands
[Skill definitions]

## Working Conventions
[Standards and practices]
```

---

## VERSION CONTROL

### Git Configuration
- Repository root: `D:\Claude local\`
- Remote: GitHub (configured per user)
- Branch strategy: main + feature branches

### Ignore Patterns (.gitignore)
```
*.stl
*.off
*.amf
*.bak
*.tmp
Thumbs.db
.DS_Store
.vscode/
.idea/
```

---

## SCHEMA EVOLUTION

When the schema needs to change:

1. Create new schema file: `workspace_schema_v2.md`
2. Document all differences from v1
3. Create migration: `migrations/v1_to_v2/`
4. Update this file to reference successor

### Schema Change Types

| Type | Description | Migration Required |
|------|-------------|-------------------|
| Folder addition | New folder in structure | Yes (create folder) |
| Folder removal | Remove existing folder | Yes (migrate content) |
| File rename | Change file naming | Yes (rename files) |
| Format change | Modify file content format | Yes (update content) |

---

## VALIDATION

To validate workspace matches schema:

```
FOLDER CHECK:
[ ] 3d_design_agent/ exists
[ ] 3d_design_agent/docs/ exists
[ ] 3d_design_agent/components/ exists
[ ] 3d_design_agent/mechanisms/ exists
[ ] User Skills/ exists
[ ] migrations/ exists

FILE CHECK:
[ ] CLAUDE.md exists at root
[ ] 3d_design_agent/unified_system_prompt.md exists
[ ] 3d_design_agent/skills.md exists
[ ] 3d_design_agent/hooks.md exists
[ ] 3d_design_agent/MASTER_REFERENCE.md exists

CONTENT CHECK:
[ ] CLAUDE.md contains required sections
[ ] skills.md defines 6+ skills
[ ] hooks.md defines 6+ hooks
```

---

*Schema Version: 1.0*
*Status: Active*
*Supersedes: None*
*Superseded by: None (current)*
