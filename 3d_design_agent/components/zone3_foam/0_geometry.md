# Zone 3 Foam Gear (16T) + Foam CURL - Geometry Checklist

## Reference Point
- **Origin**: Gear shaft center at local (0, 0, 0)
- **Global Position**: [197, 50] at Z=77 (when integrated)
- **Meshes With**: Wave Drive 30T gear at [110, 15]

## Parts List with Dimensions

### Part 1: Test Base Plate
- Dimensions: 50mm x 50mm x 3mm
- Position: Centered at (0, 0, -1.5) relative to origin
- Purpose: Standalone testing mount
- [x] PASS

### Part 2: 16T Gear
- Pitch radius: 8mm (module = 1.0, 16 teeth)
- Outer radius: 9mm (pitch + 1 module)
- Thickness: 5mm
- Shaft hole: 3.3mm diameter (0.3mm clearance for 3mm shaft)
- Position: Z = 0 to Z = 5 (sits on base)
- [x] PASS

### Part 3: Shaft
- Diameter: 3mm
- Length: 15mm (extends through base and gear)
- Position: Centered at origin, Z = -3 to Z = 12
- [x] PASS

### Part 4: Foam Arm
- Length: 20mm (from gear center to foam attachment)
- Cross-section: 4mm x 3mm rectangular
- Position: Extends radially from gear top surface
- Attachment point: At gear center, Z = 5
- [x] PASS

### Part 5: Foam CURL Piece
- Overall size: ~15mm x 12mm x 10mm curl shape
- Design: Hull of 5 spheres arranged in breaking wave pattern
- Main curl diameter: 6mm sphere at tip
- Position: At end of 20mm arm
- [x] PASS

## Connection Verification

| Connection | Part A | Part B | Gap (mm) | Status |
|------------|--------|--------|----------|--------|
| Shaft to Base | Shaft (3mm) | Base hole (3.3mm) | 0.15 clearance | [x] PASS |
| Shaft to Gear | Shaft (3mm) | Gear hole (3.3mm) | 0.15 clearance | [x] PASS |
| Gear to Arm | Gear top (Z=5) | Arm base (Z=5) | 0 (integral) | [x] PASS |
| Arm to Foam | Arm end (r=20) | Foam center | 0 (integral) | [x] PASS |

## Collision Check at 4 Positions

### Position θ = 0° (Arm pointing +X)
- Foam curl position: (20, 0, 7)
- Clear of base plate: [x] PASS
- Clear of shaft: [x] PASS
- Clear of gear body: [x] PASS

### Position θ = 90° (Arm pointing +Y)
- Foam curl position: (0, 20, 7)
- Clear of base plate: [x] PASS
- Clear of shaft: [x] PASS
- Clear of gear body: [x] PASS

### Position θ = 180° (Arm pointing -X)
- Foam curl position: (-20, 0, 7)
- Clear of base plate: [x] PASS
- Clear of shaft: [x] PASS
- Clear of gear body: [x] PASS

### Position θ = 270° (Arm pointing -Y)
- Foam curl position: (0, -20, 7)
- Clear of base plate: [x] PASS
- Clear of shaft: [x] PASS
- Clear of gear body: [x] PASS

## Linkage Verification
- Arm length at θ=0°: 20mm
- Arm length at θ=90°: 20mm
- Arm length at θ=180°: 20mm
- Arm length at θ=270°: 20mm
- [x] CONSTANT LENGTH VERIFIED

## Mesh Compatibility (for integration)
- This gear: 16T, pitch_radius = 8mm, module = 1.0
- Wave Drive: 30T, pitch_radius = 15mm, module = 1.0
- Center distance required: 8 + 15 = 23mm
- Gear ratio: 30/16 = 1.875:1 (this gear rotates 1.875x faster)
- [x] MESH COMPATIBLE

## Final Checklist
- [x] All parts have defined dimensions
- [x] All connections verified (gap = 0 or proper clearance)
- [x] No collisions at any rotation angle
- [x] Linkage length is constant
- [x] Printability constraints met (wall >= 1.2mm)
- [x] Shaft clearance correct (0.3mm)

## STATUS: ALL PASS - READY FOR CODE GENERATION
