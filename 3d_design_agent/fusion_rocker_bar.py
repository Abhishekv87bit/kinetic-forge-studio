"""
FUSION 360 ROCKER BAR WITH 3D PRINTABLE JOINTS
Industry-standard connections for kinetic sculpture mechanism

Features:
- Center pivot with bushing recess
- End attachment hole for connecting rod bearing
- Lightening holes for weight reduction
- 3D print tolerances built in

INSTALLATION:
1. Copy to: %appdata%\Autodesk\Autodesk Fusion 360\API\Scripts\RockerBar\RockerBar.py
2. Or run install_fusion_scripts.bat

Author: Claude
"""

import adsk.core, adsk.fusion, adsk.cam, traceback
import math

# ═══════════════════════════════════════════════════════════════════════════════
#                           DEFAULT PARAMETERS
# ═══════════════════════════════════════════════════════════════════════════════

# Bar dimensions
DEFAULT_LENGTH = 100.0         # mm - total length
DEFAULT_WIDTH = 12.0           # mm - bar width
DEFAULT_THICKNESS = 8.0        # mm - bar thickness

# Pivot center (for fixed mounting)
DEFAULT_PIVOT_BORE = 10.3      # mm - 0.3mm clearance for 10mm shoulder bolt
DEFAULT_BUSHING_DIA = 12.0     # mm - bushing recess diameter
DEFAULT_BUSHING_DEPTH = 2.0    # mm - bushing recess depth

# End attachment (for connecting rod)
DEFAULT_END_BORE = 8.4         # mm - 0.4mm clearance for 8mm shoulder bolt
DEFAULT_END_BOSS_DIA = 16.0    # mm - boss diameter at end

# Lightening holes
DEFAULT_LIGHT_HOLE_DIA = 6.0   # mm - weight reduction holes
DEFAULT_LIGHT_HOLE_COUNT = 4   # number of lightening holes


def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface

        # Get user input
        params = get_user_input(ui)
        if params is None:
            return

        length, width, thickness, pivot_bore, end_bore = params

        # Create the rocker bar
        create_rocker_bar(length, width, thickness, pivot_bore, end_bore)

        ui.messageBox(f'Rocker bar created!\n\n'
                     f'LENGTH: {length}mm\n'
                     f'SECTION: {width}×{thickness}mm\n\n'
                     f'PIVOT CENTER:\n'
                     f'  Bore: Ø{pivot_bore}mm\n'
                     f'  Bushing: Ø{DEFAULT_BUSHING_DIA}×{DEFAULT_BUSHING_DEPTH}mm\n\n'
                     f'ROD END:\n'
                     f'  Bore: Ø{end_bore}mm\n'
                     f'  Boss: Ø{DEFAULT_END_BOSS_DIA}mm\n\n'
                     f'Arm length: ±{length/2}mm')

    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))


def get_user_input(ui):
    """Get rocker parameters from user"""
    try:
        length_input = ui.inputBox('Enter total length (mm):', 'Length', str(DEFAULT_LENGTH))
        if length_input[1]: return None
        length = float(length_input[0])

        width_input = ui.inputBox('Enter bar width (mm):', 'Width', str(DEFAULT_WIDTH))
        if width_input[1]: return None
        width = float(width_input[0])

        thickness_input = ui.inputBox('Enter thickness (mm):', 'Thickness', str(DEFAULT_THICKNESS))
        if thickness_input[1]: return None
        thickness = float(thickness_input[0])

        pivot_input = ui.inputBox('Enter pivot bore diameter (mm):', 'Pivot Bore', str(DEFAULT_PIVOT_BORE))
        if pivot_input[1]: return None
        pivot_bore = float(pivot_input[0])

        end_input = ui.inputBox('Enter end bore diameter (mm):', 'End Bore', str(DEFAULT_END_BORE))
        if end_input[1]: return None
        end_bore = float(end_input[0])

        return (length, width, thickness, pivot_bore, end_bore)

    except:
        return None


def create_rocker_bar(length, width, thickness, pivot_bore, end_bore):
    """Create the complete rocker bar"""

    app = adsk.core.Application.get()
    design = app.activeProduct
    rootComp = design.rootComponent

    # Create new component
    occ = rootComp.occurrences.addNewComponent(adsk.core.Matrix3D.create())
    rocker_comp = occ.component
    rocker_comp.name = f"RockerBar_L{int(length)}"

    # ═══════════════════════════════════════════════════════════════════════════
    # Create bar body with rounded ends
    # ═══════════════════════════════════════════════════════════════════════════

    create_bar_body(rocker_comp, length, width, thickness)

    # ═══════════════════════════════════════════════════════════════════════════
    # Add pivot hole with bushing recess
    # ═══════════════════════════════════════════════════════════════════════════

    add_pivot_hole(rocker_comp, pivot_bore, thickness)

    # ═══════════════════════════════════════════════════════════════════════════
    # Add end attachment hole (for connecting rod)
    # One end only - at +X position
    # ═══════════════════════════════════════════════════════════════════════════

    add_end_hole(rocker_comp, length, end_bore, thickness)

    # ═══════════════════════════════════════════════════════════════════════════
    # Add lightening holes
    # ═══════════════════════════════════════════════════════════════════════════

    add_lightening_holes(rocker_comp, length, thickness)

    # Apply appearance
    apply_appearance(rocker_comp, "Aluminum - Satin")

    return rocker_comp


def create_bar_body(comp, length, width, thickness):
    """Create the rocker bar body with rounded ends"""

    sketches = comp.sketches
    xyPlane = comp.xYConstructionPlane

    sketch = sketches.add(xyPlane)
    lines = sketch.sketchCurves.sketchLines
    arcs = sketch.sketchCurves.sketchArcs
    circles = sketch.sketchCurves.sketchCircles

    # Dimensions in cm
    half_len = length / 2 / 10
    half_w = width / 2 / 10
    thick = thickness / 10
    end_boss_r = DEFAULT_END_BOSS_DIA / 2 / 10

    # ═══════════════════════════════════════════════════════════════════════════
    # Draw bar profile with rounded ends
    # Main bar body + circular bosses at ends
    # ═══════════════════════════════════════════════════════════════════════════

    # Main bar rectangle (slightly shorter to account for rounded ends)
    bar_half_len = half_len - half_w

    # Draw bar with semicircular ends
    p1 = adsk.core.Point3D.create(-bar_half_len, -half_w, 0)
    p2 = adsk.core.Point3D.create(bar_half_len, -half_w, 0)
    p3 = adsk.core.Point3D.create(bar_half_len, half_w, 0)
    p4 = adsk.core.Point3D.create(-bar_half_len, half_w, 0)

    # Straight edges
    lines.addByTwoPoints(p1, p2)
    lines.addByTwoPoints(p3, p4)

    # Semicircular ends
    left_center = adsk.core.Point3D.create(-bar_half_len, 0, 0)
    right_center = adsk.core.Point3D.create(bar_half_len, 0, 0)

    arcs.addByCenterStartSweep(left_center, p1, math.radians(180))
    arcs.addByCenterStartSweep(right_center, p2, math.radians(-180))

    # Add larger bosses at ends for holes
    # These extend beyond the basic bar width
    circles.addByCenterRadius(
        adsk.core.Point3D.create(-half_len + end_boss_r, 0, 0),
        end_boss_r
    )
    circles.addByCenterRadius(
        adsk.core.Point3D.create(half_len - end_boss_r, 0, 0),
        end_boss_r
    )

    # ═══════════════════════════════════════════════════════════════════════════
    # Extrude the combined profile
    # ═══════════════════════════════════════════════════════════════════════════

    extrudes = comp.features.extrudeFeatures

    # Find largest profile (combined shape)
    largest_prof = None
    largest_area = 0
    for i in range(sketch.profiles.count):
        prof = sketch.profiles.item(i)
        try:
            area = prof.areaProperties().area
            if area > largest_area:
                largest_area = area
                largest_prof = prof
        except:
            pass

    if largest_prof:
        extInput = extrudes.createInput(largest_prof, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
        extInput.setSymmetricExtent(adsk.core.ValueInput.createByReal(thick / 2), True)
        extrudes.add(extInput)


def add_pivot_hole(comp, pivot_bore, thickness):
    """Add center pivot hole with bushing recess"""

    sketches = comp.sketches
    extrudes = comp.features.extrudeFeatures

    thick = thickness / 10
    pivot_r = pivot_bore / 2 / 10
    bushing_r = DEFAULT_BUSHING_DIA / 2 / 10
    bushing_d = DEFAULT_BUSHING_DEPTH / 10

    # ═══════════════════════════════════════════════════════════════════════════
    # Main pivot bore (through hole)
    # ═══════════════════════════════════════════════════════════════════════════

    sketch_pivot = sketches.add(comp.xYConstructionPlane)
    circles = sketch_pivot.sketchCurves.sketchCircles

    circles.addByCenterRadius(
        adsk.core.Point3D.create(0, 0, 0),
        pivot_r
    )

    prof = sketch_pivot.profiles.item(0)
    extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.CutFeatureOperation)
    extInput.setAllExtent(adsk.fusion.ExtentDirections.SymmetricExtentDirection)
    extrudes.add(extInput)

    # ═══════════════════════════════════════════════════════════════════════════
    # Bushing recess (counterbore on both sides)
    # ═══════════════════════════════════════════════════════════════════════════

    # Top side recess
    try:
        # Find top face
        body = comp.bRepBodies.item(0)
        top_face = None
        for face in body.faces:
            try:
                normal = face.evaluator.getNormalAtPoint(face.pointOnFace)[1]
                if abs(normal.z - 1.0) < 0.01:
                    top_face = face
                    break
            except:
                pass

        if top_face:
            sketch_bushing = sketches.add(top_face)
            bushing_circles = sketch_bushing.sketchCurves.sketchCircles

            bushing_circles.addByCenterRadius(
                adsk.core.Point3D.create(0, 0, 0),
                bushing_r
            )

            prof = sketch_bushing.profiles.item(0)
            extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.CutFeatureOperation)
            distance = adsk.core.ValueInput.createByReal(bushing_d)
            extInput.setDistanceExtent(False, distance)
            extrudes.add(extInput)

    except:
        pass


def add_end_hole(comp, length, end_bore, thickness):
    """Add attachment hole at one end for connecting rod"""

    sketches = comp.sketches
    extrudes = comp.features.extrudeFeatures

    half_len = length / 2 / 10
    end_boss_r = DEFAULT_END_BOSS_DIA / 2 / 10
    end_r = end_bore / 2 / 10

    # Hole position: at end boss center
    # FIXED: Correct position calculation (was dividing by 10 twice before)
    hole_x = half_len - end_boss_r

    # ═══════════════════════════════════════════════════════════════════════════
    # End attachment bore (through hole)
    # Only at +X end (for connecting rod)
    # ═══════════════════════════════════════════════════════════════════════════

    sketch_end = sketches.add(comp.xYConstructionPlane)
    circles = sketch_end.sketchCurves.sketchCircles

    circles.addByCenterRadius(
        adsk.core.Point3D.create(hole_x, 0, 0),
        end_r
    )

    prof = sketch_end.profiles.item(0)
    extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.CutFeatureOperation)
    extInput.setAllExtent(adsk.fusion.ExtentDirections.SymmetricExtentDirection)
    extrudes.add(extInput)


def add_lightening_holes(comp, length, thickness):
    """Add lightening holes between pivot and ends"""

    sketches = comp.sketches
    extrudes = comp.features.extrudeFeatures

    half_len = length / 2 / 10
    light_r = DEFAULT_LIGHT_HOLE_DIA / 2 / 10

    # ═══════════════════════════════════════════════════════════════════════════
    # Lightening holes at fixed positions
    # FIXED: Correct position calculation (positions are fractions of half-length)
    # ═══════════════════════════════════════════════════════════════════════════

    # Positions as fractions of half-length (from center)
    hole_positions = [0.25, 0.55]  # 25% and 55% of half-length from center

    sketch_light = sketches.add(comp.xYConstructionPlane)
    circles = sketch_light.sketchCurves.sketchCircles

    for pos in hole_positions:
        # Positive X side
        x_pos = half_len * pos
        circles.addByCenterRadius(
            adsk.core.Point3D.create(x_pos, 0, 0),
            light_r
        )

        # Negative X side (symmetrical)
        circles.addByCenterRadius(
            adsk.core.Point3D.create(-x_pos, 0, 0),
            light_r
        )

    # Cut all lightening holes
    for i in range(sketch_light.profiles.count):
        prof = sketch_light.profiles.item(i)
        extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.CutFeatureOperation)
        extInput.setAllExtent(adsk.fusion.ExtentDirections.SymmetricExtentDirection)
        try:
            extrudes.add(extInput)
        except:
            pass


def apply_appearance(component, appearance_name):
    """Apply material appearance"""
    try:
        app = adsk.core.Application.get()
        lib = app.materialLibraries.itemByName("Fusion 360 Appearance Library")
        if lib:
            appearance = lib.appearances.itemByName(appearance_name)
            if appearance:
                for body in component.bRepBodies:
                    body.appearance = appearance
    except:
        pass


if __name__ == '__main__':
    run(None)
