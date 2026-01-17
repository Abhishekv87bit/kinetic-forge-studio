# SKILL: /your-skill-name

---

> **Template for creating custom slash commands**
> Delete this instruction block after filling in your skill definition.

---

## Trigger Pattern

```
/your-skill-name [param1] [param2] [optional_param]
```

---

## Purpose

[Describe what this skill does in 1-2 sentences. Be specific about the problem it solves.]

---

## When to Use

Use this skill when:
- [Situation 1 where this skill is helpful]
- [Situation 2 where this skill is helpful]
- [Situation 3 where this skill is helpful]

Do NOT use this skill when:
- [Situation where a different skill is better]

---

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| param1 | string | yes | - | [What this parameter controls] |
| param2 | number | yes | - | [What this parameter controls] |
| optional_param | boolean | no | false | [What this parameter controls] |

### Parameter Details

**param1:**
- Must be [constraint]
- Example values: [examples]

**param2:**
- Range: [min] to [max]
- Typical values: [examples]

---

## Step-by-Step Process

```
STEP 1: [Action name]
├── [Sub-action 1]
├── [Sub-action 2]
└── [Sub-action 3]

STEP 2: [Action name]
├── [Sub-action 1]
└── [Sub-action 2]

STEP 3: [Action name]
├── [Sub-action 1]
├── [Sub-action 2]
└── [Final action]

STEP 4: [Output/Verification]
└── [What gets returned to user]
```

---

## Output Format

```
============================================================
              [SKILL NAME] RESULTS
============================================================

[SECTION 1 HEADER]:
  [Output line 1]
  [Output line 2]

[SECTION 2 HEADER]:
  [Output line 1]
  [Output line 2]

VERIFICATION:
  [ ] [Check item 1]
  [ ] [Check item 2]
  [ ] [Check item 3]

RECOMMENDATIONS:
  - [Suggestion 1]
  - [Suggestion 2]

============================================================
```

---

## Example Usage

### Example 1: Basic Usage

**Command:**
```
/your-skill-name value1 100
```

**Output:**
```
============================================================
              YOUR-SKILL-NAME RESULTS
============================================================

ANALYSIS:
  Parameter 1: value1
  Parameter 2: 100

RESULT:
  [Calculated output]

VERIFICATION:
  [x] Check 1 passed
  [x] Check 2 passed

============================================================
```

### Example 2: With Optional Parameter

**Command:**
```
/your-skill-name value2 50 true
```

**Output:**
```
[Show different output when optional param is used]
```

---

## Formulas Used

If this skill performs calculations, document them here:

```
[Formula Name]:
  result = (param1 * param2) / constant

Where:
  param1 = [description]
  param2 = [description]
  constant = [value and why]
```

---

## Integration Notes

### Works With
- `/other-skill-1` - [How they complement each other]
- `/other-skill-2` - [How they complement each other]

### Dependencies
- Requires: [Any files, modules, or context needed]
- Expects: [State or conditions that must be true]

### Triggers
- May trigger: [Hooks or other skills this might activate]
- Triggered by: [What might call this skill]

---

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| "Parameter X invalid" | [Why this happens] | [How to fix] |
| "Cannot find [thing]" | [Why this happens] | [How to fix] |
| "Calculation failed" | [Why this happens] | [How to fix] |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | YYYY-MM-DD | Initial creation |

---

## Author

- Created by: [Your name]
- Contact: [Optional contact info]
- Project: [What project this was created for]

---

*Skill Version: 1.0*
*Last Updated: [Date]*
