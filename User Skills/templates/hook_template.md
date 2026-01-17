# HOOK: your-hook-name

---

> **Template for creating custom hooks (automated triggers)**
> Delete this instruction block after filling in your hook definition.

---

## Overview

| Property | Value |
|----------|-------|
| Hook Name | your-hook-name |
| Trigger Type | [regex / event / condition] |
| Confirmation | [auto / user-confirm] |
| Priority | [1-5, where 1 is highest] |

---

## Trigger Conditions

### Pattern-Based Trigger (if using regex)
```regex
/\b(keyword1|keyword2|phrase with spaces)\b/i
```

### Event-Based Trigger (if using events)
- Event: [file_save / version_create / component_modify / etc.]
- Condition: [Additional conditions that must be true]

### Condition-Based Trigger
```
IF [condition 1]
AND [condition 2]
THEN trigger hook
```

---

## Action Sequence

When triggered, execute these steps in order:

```
STEP 1: [Immediate Action]
├── [What to do first]
└── [What information to gather]

STEP 2: [Analysis/Processing]
├── [What to analyze]
├── [What to calculate]
└── [What to compare]

STEP 3: [User Interaction] (if confirmation required)
├── [What to present to user]
├── [Options to offer]
└── [Wait for response]

STEP 4: [Final Action]
├── [What to do based on response]
└── [How to document/log]
```

---

## Output Format

### If Auto-Execute
```
[HOOK: your-hook-name] Triggered
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Detected: [what triggered it]
Action: [what was done]
Result: [outcome]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### If User Confirmation Required
```
[HOOK: your-hook-name] Triggered
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Detected: [what triggered it]

This hook wants to:
  1. [Action 1]
  2. [Action 2]
  3. [Action 3]

Options:
  [A] Proceed with all actions
  [B] Skip action 2
  [C] Cancel hook

Your choice:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Example Interactions

### Example 1: Trigger and Auto-Execute

**User Input:**
```
[Input that triggers the hook]
```

**Hook Response:**
```
[HOOK: your-hook-name] Triggered
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Detected: [trigger]
Action: [what happened]
Result: [outcome]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Continues with:**
```
[Normal response to user input]
```

### Example 2: Trigger with User Choice

**User Input:**
```
[Input that triggers the hook]
```

**Hook Prompt:**
```
[Presents options to user]
```

**User Chooses:**
```
[Option A/B/C]
```

**Hook Completes:**
```
[Result based on choice]
```

---

## Integration

### Hooks This May Trigger
- [other-hook-name] - [Under what conditions]

### Hooks That May Trigger This
- [other-hook-name] - [Under what conditions]

### Skills This May Call
- /[skill-name] - [Why and when]

---

## Configuration

### Disable This Hook
To temporarily disable this hook, add to your session:
```
HOOK_DISABLED: your-hook-name
```

### Modify Trigger Sensitivity
```
HOOK_your-hook-name_THRESHOLD: [value]
```

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Trigger detected but context unclear | [What to do] |
| Action fails | [What to do] |
| User doesn't respond | [Timeout behavior] |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | YYYY-MM-DD | Initial creation |

---

## Author

- Created by: [Your name]
- Purpose: [Why this hook was created]
- Project: [What project this was created for]

---

*Hook Version: 1.0*
*Last Updated: [Date]*
