# GEOMETRY CHECKLIST - MANDATORY BEFORE CODE

**This checklist MUST be completed with actual numbers before ANY OpenSCAD code is written.**

Copy this template to `projects/[name]/0_geometry.md` and fill in ALL blanks.

---

## Part 1: Reference Point

**The SINGLE source of truth for all positions:**

```
Reference name: ____________
Reference position: X=___mm, Y=___mm, Z=___mm
What is it: ____________ (e.g., "motor shaft center")
```

---

## Part 2: Part List with Dimensions

For EACH part, fill in ALL fields:

### Part 1: ____________
```
Dimensions: ___mm × ___mm × ___mm
Position relative to reference:
  X = reference_X + ___mm = ___mm
  Y = reference_Y + ___mm = ___mm
  Z = reference_Z + ___mm = ___mm
Connects to: ____________ at (___mm, ___mm, ___mm)
```

### Part 2: ____________
```
Dimensions: ___mm × ___mm × ___mm
Position relative to reference:
  X = reference_X + ___mm = ___mm
  Y = reference_Y + ___mm = ___mm
  Z = reference_Z + ___mm = ___mm
Connects to: ____________ at (___mm, ___mm, ___mm)
```

### Part 3: ____________
```
Dimensions: ___mm × ___mm × ___mm
Position relative to reference:
  X = reference_X + ___mm = ___mm
  Y = reference_Y + ___mm = ___mm
  Z = reference_Z + ___mm = ___mm
Connects to: ____________ at (___mm, ___mm, ___mm)
```

(Add more parts as needed)

---

## Part 3: Connection Verification

For each connection, verify the parts actually touch:

### Connection 1: _____ connects to _____
```
Part A endpoint: (___mm, ___mm, ___mm)
Part B endpoint: (___mm, ___mm, ___mm)
Gap = sqrt((ΔX)² + (ΔY)² + (ΔZ)²) = ___mm

[ ] PASS (gap = 0) or [ ] FAIL (gap > 0)
```

### Connection 2: _____ connects to _____
```
Part A endpoint: (___mm, ___mm, ___mm)
Part B endpoint: (___mm, ___mm, ___mm)
Gap = sqrt((ΔX)² + (ΔY)² + (ΔZ)²) = ___mm

[ ] PASS (gap = 0) or [ ] FAIL (gap > 0)
```

---

## Part 4: Collision Check

For moving parts, verify NO collisions at 4 positions:

### Moving Part: ____________

```
At θ=0°:
  Part position: (___mm, ___mm, ___mm)
  Nearest obstacle: ____________ at (___mm, ___mm, ___mm)
  Clearance: ___mm [ ] PASS (>0.3mm) / [ ] FAIL

At θ=90°:
  Part position: (___mm, ___mm, ___mm)
  Nearest obstacle: ____________ at (___mm, ___mm, ___mm)
  Clearance: ___mm [ ] PASS (>0.3mm) / [ ] FAIL

At θ=180°:
  Part position: (___mm, ___mm, ___mm)
  Nearest obstacle: ____________ at (___mm, ___mm, ___mm)
  Clearance: ___mm [ ] PASS (>0.3mm) / [ ] FAIL

At θ=270°:
  Part position: (___mm, ___mm, ___mm)
  Nearest obstacle: ____________ at (___mm, ___mm, ___mm)
  Clearance: ___mm [ ] PASS (>0.3mm) / [ ] FAIL
```

---

## Part 5: Linkage Length Verification (if applicable)

```
Declared coupler length: ___mm

At θ=0°:   endpoint A (___,___) to endpoint B (___,___) = ___mm
At θ=90°:  endpoint A (___,___) to endpoint B (___,___) = ___mm
At θ=180°: endpoint A (___,___) to endpoint B (___,___) = ___mm
At θ=270°: endpoint A (___,___) to endpoint B (___,___) = ___mm

Max deviation from declared: ___mm

[ ] PASS (deviation < 0.1mm) or [ ] FAIL
```

---

## Part 6: Final Checklist

```
[ ] All parts have explicit XYZ positions (no guessing)
[ ] All connections verified (gap = 0)
[ ] All collisions checked at 4 positions
[ ] Linkage lengths verified constant
[ ] All numbers are ACTUAL values, not placeholders

Checklist completed by: ____________
Date: ____________
```

---

## BLOCKING RULE

**If ANY checkbox above is unchecked or shows FAIL:**
- DO NOT write OpenSCAD code
- Fix the geometry first
- Re-run this checklist

**Code generation is BLOCKED until this checklist is 100% PASS.**
