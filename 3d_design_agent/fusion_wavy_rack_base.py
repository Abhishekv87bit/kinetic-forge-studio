"""
FUSION 360 WAVY RACK BASE + TOOTH SKETCH
Creates sinusoidal base profile WITH tooth sketch ready to extrude and pattern

This script generates:
1. Wavy rack base (sinusoidal profile)
2. Tooth sketch on XY plane at X=0 (ready to extrude)

After running:
1. Select the tooth sketch profile
2. Extrude → Join, symmetric to rack width
3. Rectangular Pattern along X-axis

Compatible with Autodesk SpurGear sample (Module 3, 20° pressure angle)

INSTALLATION:
1. Copy to: %appdata%\Autodesk\Autodesk Fusion 360\API\Scripts\WavyRackBase\WavyRackBase.py
2. Or run install_fusion_scripts.bat

Author: Claude
"""

import adsk.core, adsk.fusion, adsk.cam, traceback
import math

# Default parameters
DEFAULT_MODULE = 3.0           # mm - must match gear
DEFAULT_RACK_LENGTH = 400.0    # mm
DEFAULT_RACK_WIDTH = 20.0      # mm (Y direction)
DEFAULT_BASE_HEIGHT = 12.0     # mm (below wave trough)
DEFAULT_PRESSURE_ANGLE = 20.0  # degrees
DEFAULT_WAVE_AMPLITUDE = 15.0  # mm (±15mm up/down)
DEFAULT_WAVE_LENGTH = 100.0    # mm (one full wave cycle)

def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface

        # Get user input
        params = get_user_input(ui)
        if params is None:
            return

        module, length, width, base_height, wave_amp, wave_len = params

        # Create the wavy rack base with tooth sketch
        rack_comp = create_wavy_rack_base(module, length, width, base_height, wave_amp, wave_len)

        # Calculate tooth dimensions for message
        circular_pitch = math.pi * module
        num_teeth = int(length / circular_pitch)

        ui.messageBox(f'Wavy rack BASE + TOOTH SKETCH created!\n\n'
                     f'Module: {module}mm\n'
                     f'Length: {length}mm\n'
                     f'Wave: ±{wave_amp}mm amplitude\n\n'
                     f'═══ NEXT STEPS ═══\n\n'
                     f'1. Find "Tooth Profile" sketch in browser\n'
                     f'2. Select the trapezoid profile\n'
                     f'3. Extrude → Join, {width}mm symmetric\n\n'
                     f'4. Rectangular Pattern:\n'
                     f'   • Direction: X-axis\n'
                     f'   • Quantity: {num_teeth}\n'
                     f'   • Spacing: {circular_pitch:.2f}mm\n\n'
                     f'5. Optional: Fillet roots at {0.25*module:.2f}mm')

    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))


def get_user_input(ui):
    """Show dialog to get rack parameters"""
    try:
        module_input = ui.inputBox(
            'Enter gear module (mm) - must match gear:',
            'Module',
            str(DEFAULT_MODULE)
        )
        if module_input[1]:
            return None
        module = float(module_input[0])

        length_input = ui.inputBox(
            'Enter rack length (mm):',
            'Length',
            str(DEFAULT_RACK_LENGTH)
        )
        if length_input[1]:
            return None
        length = float(length_input[0])

        width_input = ui.inputBox(
            'Enter rack width/depth in Y (mm):',
            'Width',
            str(DEFAULT_RACK_WIDTH)
        )
        if width_input[1]:
            return None
        width = float(width_input[0])

        base_height_input = ui.inputBox(
            'Enter base height below wave trough (mm):',
            'Base Height',
            str(DEFAULT_BASE_HEIGHT)
        )
        if base_height_input[1]:
            return None
        base_height = float(base_height_input[0])

        wave_amp_input = ui.inputBox(
            'Enter wave amplitude (mm):',
            'Wave Amplitude',
            str(DEFAULT_WAVE_AMPLITUDE)
        )
        if wave_amp_input[1]:
            return None
        wave_amp = float(wave_amp_input[0])

        wave_len_input = ui.inputBox(
            'Enter wavelength (mm):',
            'Wavelength',
            str(DEFAULT_WAVE_LENGTH)
        )
        if wave_len_input[1]:
            return None
        wave_len = float(wave_len_input[0])

        return (module, length, width, base_height, wave_amp, wave_len)

    except:
        return None


def wave_z(x_mm, amplitude, wavelength):
    """Calculate Z height at position X along wave (in mm)"""
    return amplitude * math.sin(2 * math.pi * x_mm / wavelength)


def create_wavy_rack_base(module, length, width, base_height, wave_amp, wave_len):
    """Create wavy rack base WITH tooth sketch

    The base has:
    - Bottom: flat surface below wave trough
    - Top: follows sinusoidal wave at ROOT level (where teeth attach)
    - Width: in Y direction

    Also creates:
    - Tooth sketch on XY plane at X=0, ready to extrude and pattern
    """

    app = adsk.core.Application.get()
    design = app.activeProduct
    rootComp = design.rootComponent

    # Create new component
    occ = rootComp.occurrences.addNewComponent(adsk.core.Matrix3D.create())
    rack_comp = occ.component
    rack_comp.name = f"WavyRackBase_M{module}_A{int(wave_amp)}"

    # ══════════════════════════════════════════════════════════════════════════
    # TOOTH GEOMETRY CALCULATIONS (Autodesk Standard)
    # ══════════════════════════════════════════════════════════════════════════

    circular_pitch = math.pi * module
    addendum = 1.0 * module
    dedendum = 1.157 * module
    tooth_height = addendum + dedendum

    tan_pa = math.tan(math.radians(DEFAULT_PRESSURE_ANGLE))
    pitch_half_thick = circular_pitch / 4
    tip_half_thick = pitch_half_thick - addendum * tan_pa
    root_half_thick = pitch_half_thick + dedendum * tan_pa

    num_segments = int(length / 2)  # Resolution: 2mm per segment

    # ══════════════════════════════════════════════════════════════════════════
    # CREATE BASE PROFILE IN XZ PLANE
    # X = along rack length
    # Z = height (wave direction)
    # Then extrude in Y for width
    # ══════════════════════════════════════════════════════════════════════════

    sketches = rack_comp.sketches
    xzPlane = rack_comp.xZConstructionPlane

    sketch = sketches.add(xzPlane)
    sketch.name = "Rack Base Profile"
    lines = sketch.sketchCurves.sketchLines
    splines = sketch.sketchCurves.sketchFittedSplines

    # Convert mm to cm for Fusion API
    half_len = length / 2 / 10  # cm
    base_h = base_height / 10   # cm
    amp = wave_amp / 10         # cm

    # ══════════════════════════════════════════════════════════════════════════
    # Build profile points
    # Bottom is flat, top follows wave
    # ══════════════════════════════════════════════════════════════════════════

    # Bottom left corner (below wave trough)
    bottom_z = -amp - base_h

    bottom_left = adsk.core.Point3D.create(-half_len, 0, bottom_z)
    bottom_right = adsk.core.Point3D.create(half_len, 0, bottom_z)

    # Draw bottom edge
    lines.addByTwoPoints(bottom_left, bottom_right)

    # Draw right edge up to wave
    right_wave_z = wave_z(half_len * 10, wave_amp, wave_len) / 10
    top_right = adsk.core.Point3D.create(half_len, 0, right_wave_z)
    lines.addByTwoPoints(bottom_right, top_right)

    # ══════════════════════════════════════════════════════════════════════════
    # TOP EDGE: Sinusoidal wave using spline
    # ══════════════════════════════════════════════════════════════════════════

    wave_points = adsk.core.ObjectCollection.create()

    for i in range(num_segments + 1):
        x_cm = half_len - (i * length / num_segments / 10)
        x_mm = x_cm * 10
        z_cm = wave_z(x_mm, wave_amp, wave_len) / 10

        point = adsk.core.Point3D.create(x_cm, 0, z_cm)
        wave_points.add(point)

    # Create spline for wave top
    wave_spline = splines.add(wave_points)

    # Draw left edge down to bottom
    left_wave_z = wave_z(-half_len * 10, wave_amp, wave_len) / 10
    top_left = adsk.core.Point3D.create(-half_len, 0, left_wave_z)
    lines.addByTwoPoints(top_left, bottom_left)

    # ══════════════════════════════════════════════════════════════════════════
    # EXTRUDE BASE in Y direction (width)
    # ══════════════════════════════════════════════════════════════════════════

    extrudes = rack_comp.features.extrudeFeatures

    if sketch.profiles.count > 0:
        # Find the largest profile
        prof = sketch.profiles.item(0)
        largest_area = 0
        for i in range(sketch.profiles.count):
            p = sketch.profiles.item(i)
            try:
                area = p.areaProperties().area
                if area > largest_area:
                    largest_area = area
                    prof = p
            except:
                pass

        extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
        extInput.setSymmetricExtent(adsk.core.ValueInput.createByReal(width / 2 / 10), True)
        base_extrude = extrudes.add(extInput)

    # ══════════════════════════════════════════════════════════════════════════
    # CREATE TOOTH SKETCH ON XY PLANE
    # Tooth profile at X=0, ready to extrude and pattern
    # ══════════════════════════════════════════════════════════════════════════

    xyPlane = rack_comp.xYConstructionPlane
    tooth_sketch = sketches.add(xyPlane)
    tooth_sketch.name = "Tooth Profile"
    tooth_lines = tooth_sketch.sketchCurves.sketchLines

    # Convert tooth dimensions to cm
    tip_half_cm = tip_half_thick / 10
    root_half_cm = root_half_thick / 10
    tooth_h_cm = tooth_height / 10

    # Wave height at X=0 (center of rack)
    wave_z_at_0 = wave_z(0, wave_amp, wave_len) / 10  # Should be 0 for sin(0)

    # Tooth base sits on wave surface
    # Draw trapezoid: root at bottom (wider), tip at top (narrower)
    # X = along rack, Y = height of tooth

    root_left = adsk.core.Point3D.create(-root_half_cm, wave_z_at_0, 0)
    tip_left = adsk.core.Point3D.create(-tip_half_cm, wave_z_at_0 + tooth_h_cm, 0)
    tip_right = adsk.core.Point3D.create(tip_half_cm, wave_z_at_0 + tooth_h_cm, 0)
    root_right = adsk.core.Point3D.create(root_half_cm, wave_z_at_0, 0)

    # Draw the tooth profile (closed trapezoid)
    tooth_lines.addByTwoPoints(root_left, tip_left)      # Left flank
    tooth_lines.addByTwoPoints(tip_left, tip_right)       # Tip (top)
    tooth_lines.addByTwoPoints(tip_right, root_right)     # Right flank
    tooth_lines.addByTwoPoints(root_right, root_left)     # Root (bottom)

    # ══════════════════════════════════════════════════════════════════════════
    # Apply appearance
    # ══════════════════════════════════════════════════════════════════════════

    apply_appearance(rack_comp, "Steel - Satin")

    return rack_comp


def apply_appearance(component, appearance_name):
    """Apply a material appearance to component"""
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
