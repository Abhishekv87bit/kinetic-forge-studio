# USER SKILLS FOLDER
## Custom Workflow Extensions for 3D Mechanical Design

---

> **This folder contains user-created extensions to the 3D Mechanical Design Agent.**

---

## PURPOSE

The User Skills folder allows you to:
- Create custom slash commands tailored to your workflow
- Override default skill behavior with your preferences
- Store personal workflow templates
- Share skills across projects

---

## FOLDER STRUCTURE

```
User Skills/
├── README.md              # This file
├── templates/             # Blank templates for creating new skills
│   ├── skill_template.md  # Template for custom slash commands
│   └── hook_template.md   # Template for custom hooks
├── custom_commands/       # Your custom slash commands
│   └── [your_skills].md
└── overrides/             # Override default agent behaviors
    └── [your_overrides].md
```

---

## CREATING A CUSTOM SKILL

### Step 1: Copy the Template
```bash
cp "User Skills/templates/skill_template.md" "User Skills/custom_commands/my_skill.md"
```

### Step 2: Fill in the Template

Edit your new skill file:
1. Define the trigger pattern (e.g., `/my-skill [param1] [param2]`)
2. Describe the purpose
3. List parameters with types and defaults
4. Define the step-by-step process
5. Specify the output format
6. Provide example usage

### Step 3: Use Your Skill

Your custom skill will be recognized when you use its trigger pattern in the conversation.

---

## EXAMPLE: CUSTOM GEAR CHECK SKILL

**File:** `custom_commands/gear-verify.md`

```markdown
# SKILL: /gear-verify

## Trigger Pattern
/gear-verify [gear_name]

## Purpose
Verify a specific gear's parameters against all meshing partners.

## Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| gear_name | string | yes | Name of gear to verify |

## Steps
1. Find gear definition in current file
2. Identify all meshing partners
3. For each partner:
   - Verify center distance formula
   - Check module match
   - Validate tooth count compatibility
4. Report any issues

## Output Format
GEAR VERIFICATION: [gear_name]
================================
Module: [value]
Teeth: [value]

Meshing Partners:
  - [partner_1]: [status]
  - [partner_2]: [status]

Result: [PASS/FAIL]
```

---

## OVERRIDING DEFAULT SKILLS

To modify how default skills work:

### Step 1: Copy Default Definition
Find the skill definition in `3d_design_agent/skills.md` and copy it.

### Step 2: Create Override File
```bash
touch "User Skills/overrides/gear-calc-override.md"
```

### Step 3: Modify as Needed
```markdown
# OVERRIDE: /gear-calc

## Changes from Default
- Added: Backlash calculation in output
- Added: 3D print tolerance recommendations
- Modified: Output includes metric and imperial units

## New Output Section
PRINT TOLERANCES:
  Gear 1 OD adjustment: +0.3mm (for FDM printing)
  Gear 2 OD adjustment: +0.3mm (for FDM printing)
  Recommended backlash: 0.1mm
  Tooth profile: Involute, pressure angle 20°
```

### Step 4: Override Takes Effect
Your override will be applied whenever the skill is invoked.

---

## CREATING A CUSTOM HOOK

### Step 1: Copy the Hook Template
```bash
cp "User Skills/templates/hook_template.md" "User Skills/custom_commands/my_hook.md"
```

### Step 2: Define Your Hook
- Specify trigger conditions (regex patterns, events)
- Define the action sequence
- Set confirmation requirements (auto or user-confirm)

### Example: Design Review Hook
```markdown
# HOOK: design-review-reminder

## Trigger
Pattern: After any file save containing "FINAL" or "RELEASE"

## Action
1. Pause and display checklist:
   [ ] All constraints verified?
   [ ] Animation tested at 5 t-values?
   [ ] Z-stack collision free?
   [ ] User vision elements preserved?
2. Wait for user confirmation
3. If confirmed, add review timestamp to file

## Auto/Confirm
Confirm required
```

---

## BEST PRACTICES

### 1. Document Everything
Future-you will thank present-you. Include:
- Why you created this skill
- What problem it solves
- Any gotchas or edge cases

### 2. Test Incrementally
- Start with a minimal skill
- Add features one at a time
- Verify each addition works

### 3. Keep Backups
Before overriding a default skill:
- Copy the original to a backup location
- Document what you changed and why

### 4. Use Clear Names
Good: `my_wave_clearance_check.md`
Bad: `skill1.md` or `new.md`

### 5. Follow Conventions
- Use consistent formatting
- Match the style of existing skills
- Include all template sections

---

## SKILL LOADING ORDER

1. **Default skills** from `3d_design_agent/skills.md` load first
2. **User overrides** from `User Skills/overrides/` load second (replace defaults)
3. **Custom commands** from `User Skills/custom_commands/` load last (add new)

---

## SHARING SKILLS

To share a skill with others:
1. Export your skill file
2. Include any dependencies
3. Document required context
4. Test on a clean installation

---

## TROUBLESHOOTING

### Skill Not Recognized
- Check trigger pattern syntax
- Verify file is in correct folder
- Ensure file has `.md` extension

### Override Not Working
- Confirm skill name matches exactly
- Check for syntax errors
- Verify override file is in `overrides/` folder

### Unexpected Behavior
- Review step-by-step process
- Check parameter definitions
- Test with example inputs

---

*User Skills are your workspace customizations.*
*Make the agent work the way YOU work.*
