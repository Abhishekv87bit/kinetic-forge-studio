# Calculations: Drip-Actuated Pendulum

## Dimensions (all in mm)

### Pendulum Arm
- Length: 60mm
- Width: 8mm
- Thickness: 4mm
- Pivot hole: 3.3mm (for 3mm rod, 0.3mm clearance)

### Fish (counterweight side)
- Length: 40mm
- Height: 15mm
- Thickness: 5mm
- Offset from pivot: 30mm (left)
- Estimated mass: 3.75g

### Catch Cup (water side)
- Outer diameter: 15mm
- Inner diameter: 12mm (wall = 1.5mm)
- Depth: 12mm
- Drain hole: 2mm diameter at bottom
- Offset from pivot: 30mm (right)
- Estimated mass: 1.9g

### Counterweight
- Added mass: 1.85g (nut or thicker cup base)
- Location: Cup side, near cup

## Balance Calculation
```
Fish moment: 3.75g × 30mm = 112.5 g·mm
Cup + counterweight: (1.9 + 1.85)g × 30mm = 112.5 g·mm
Balanced: YES
```

## Tipping Threshold
```
Water needed: ~1g (1mL) at 30mm offset
Drips to tip: ~15-20 (at 0.05mL per drip)
```

## Printability
- Cup wall: 1.5mm ≥ 1.2mm ✓
- Arm thickness: 4mm ≥ 1.2mm ✓
- Pivot clearance: 0.3mm ≥ 0.3mm ✓
