# OpenSCAD Helper Scripts

This directory contains helper scripts for common OpenSCAD operations.

## Scripts

### render_animation.bat

Renders animation frames from an OpenSCAD file.

**Usage:**
```batch
render_animation.bat <file.scad> <output_dir> <frames>
```

**Example:**
```batch
render_animation.bat mymodel.scad output_frames 60
```

This will render 60 frames to `output_frames\frame_0000.png` through `output_frames\frame_0059.png`.

---

### export_svg.bat

Exports a 2D view from an OpenSCAD file to SVG format.

**Usage:**
```batch
export_svg.bat <file.scad> <output.svg>
```

**Example:**
```batch
export_svg.bat mymodel.scad output.svg
```

The script sets `$t=0.5` for animation midpoint and uses a default camera position.

---

### extract_svg_coords.bat

Extracts path coordinates from an SVG file using regex pattern matching.

**Usage:**
```batch
extract_svg_coords.bat <file.svg>
```

**Example:**
```batch
extract_svg_coords.bat output.svg
```

Outputs all SVG path `d` attributes found in the file.

---

### survival_check.ps1

PowerShell script to verify that required components exist in an OpenSCAD file.

**Usage:**
```powershell
.\survival_check.ps1 -file <file.scad>
```

**Example:**
```powershell
.\survival_check.ps1 -file mymodel.scad
```

**Checked Components:**
- enclosure
- motor
- pinion
- master_gear
- four_bar
- wave

Output shows `[OK]` in green for found components and `[MISSING]` in red for missing ones.

---

### version_diff.ps1

PowerShell script to compare two OpenSCAD files and display differences.

**Usage:**
```powershell
.\version_diff.ps1 -old <old_file.scad> -new <new_file.scad>
```

**Example:**
```powershell
.\version_diff.ps1 -old model_v1.scad -new model_v2.scad
```

Displays a formatted table showing lines that differ between the two files.

---

## Requirements

- OpenSCAD must be installed and available in the system PATH
- PowerShell 5.0 or later for `.ps1` scripts
- Windows Command Prompt for `.bat` scripts

## Notes

- Camera position format: `--camera=eyeX,eyeY,eyeZ,centerX,centerY,centerZ,distance`
- Default camera distance is set to 500 units
- Animation frames use zero-padded 4-digit numbering (e.g., frame_0001.png)
