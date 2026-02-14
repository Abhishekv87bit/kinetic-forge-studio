"""
FUSION 360 WAVY RACK GENERATOR
Teeth point UP from sinusoidal wave surface - gear rides on top

FIXED: Tooth geometry now matches Autodesk SpurGear sample for proper meshing
- Addendum = 1.0 × module (tooth above pitch line)
- Dedendum = 1.157 × module (Autodesk standard, NOT 1.25)
- Pitch line is at dedendum height above wave surface

Creates rack where:
- Base follows: Z = amplitude × sin(2π × X / wavelength)
- Teeth point UPWARD (Z+) perpendicular to wave surface
- Gear pitch circle touches rack pitch line (at dedendum height)

INSTALLATION:
1. Copy to: %appdata%\Autodesk\Autodesk Fusion 360\API\Scripts\WavyRack\WavyRack.py
2. Or run install_fusion_scripts.bat

Author: Claude
"""

import adsk.core, adsk.fusion, adsk.cam, traceback
import math

# Default parameters (matching wave mechanism)
DEFAULT_MODULE = 3.0           # mm - must match gear
DEFAULT_RACK_LENGTH = 400.0    # mm - DOUBLED for smooth continuous motion
DEFAULT_RACK_WIDTH = 20.0      # mm (Y direction - depth into page)
DEFAULT_RACK_HEIGHT = 12.0     # mm (base thickness below teeth)
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

        module, length, width, height, pressure_angle, wave_amp, wave_len = params

        # Create the wavy rack
        create_wavy_rack(module, length, width, height, pressure_angle, wave_amp, wave_len)

        # Calculate info
        circular_pitch = math.pi * module
        teeth_count = int(length / circular_pitch)
        pitch_dia = module * 20  # Matching 20-tooth gear

        # Meshing calculation
        dedendum = 1.157 * module
        pitch_radius = pitch_dia / 2

        ui.messageBox(f'Wavy rack created!\n\n'
                     f'Module: {module}mm\n'
                     f'Pressure angle: {pressure_angle}°\n'
                     f'Teeth: {teeth_count}\n'
                     f'Circular pitch: {circular_pitch:.2f}mm\n\n'
                     f'Wave: Z = {wave_amp} × sin(2π × X / {wave_len})\n\n'
                     f'MESHING (for 20T gear):\n'
                     f'  Pitch Ø: {pitch_dia}mm\n'
                     f'  Gear center Z: {pitch_radius + dedendum:.1f}mm above root\n'
                     f'  (dedendum = {dedendum:.2f}mm)')

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

        height_input = ui.inputBox(
            'Enter base height below wave (mm):',
            'Height',
            str(DEFAULT_RACK_HEIGHT)
        )
        if height_input[1]:
            return None
        height = float(height_input[0])

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

        return (module, length, width, height, DEFAULT_PRESSURE_ANGLE, wave_amp, wave_len)

    except:
        return None


def wave_z(x_mm, amplitude, wavelength):
    """Calculate Z height at position X along wave (in mm)"""
    return amplitude * math.sin(2 * math.pi * x_mm / wavelength)


def wave_slope_angle(x_mm, amplitude, wavelength):
    """Calculate slope angle (degrees) at position X"""
    # dz/dx = amplitude * (2π/λ) * cos(2πx/λ)
    slope = amplitude * (2 * math.pi / wavelength) * math.cos(2 * math.pi * x_mm / wavelength)
    return math.degrees(math.atan(slope))


def create_wavy_rack(module, length, width, height, pressure_angle, wave_amp, wave_len):
    """Create rack with teeth pointing UP from wave surface

    TOOTH GEOMETRY (Autodesk SpurGear Sample compatible):
    - Circular pitch = π × module
    - Addendum (ha) = 1.0 × module (above pitch line)
    - Dedendum (hf) = 1.157 × module (below pitch line) - AUTODESK STANDARD
    - Total tooth height = 2.157 × module
    - Tooth thickness at pitch line = π × module / 2

    PITCH LINE POSITION:
    - Pitch line is at dedendum height (1.157 × module) above root
    - Gear pitch circle must touch this line for proper mesh

    MESHING DISTANCE:
    - For Module 3mm, 20-tooth gear: Pitch diameter = 60mm
    - Gear center should be at Z = 30mm (pitch radius) above rack pitch line
    """

    app = adsk.core.Application.get()
    design = app.activeProduct
    rootComp = design.rootComponent

    # Create new component
    occ = rootComp.occurrences.addNewComponent(adsk.core.Matrix3D.create())
    rack_comp = occ.component
    rack_comp.name = f"WavyRack_M{module}_A{int(wave_amp)}"

    # ══════════════════════════════════════════════════════════════════════════
    # TOOTH GEOMETRY CALCULATIONS (Autodesk SpurGear Standard)
    # See: SpurGear/spurGearCreate/logic.py line 548
    # ══════════════════════════════════════════════════════════════════════════

    circular_pitch = math.pi * module        # Distance between teeth
    addendum = 1.0 * module                  # Height above pitch line
    dedendum = 1.157 * module                # AUTODESK STANDARD (not 1.25!)
    tooth_height = addendum + dedendum       # Total tooth height = 2.157m

    num_teeth = int(length / circular_pitch)

    # Pressure angle calculations
    tan_pa = math.tan(math.radians(pressure_angle))

    # Tooth thickness at different heights
    # At pitch line: thickness = circular_pitch / 2
    pitch_half_thick = circular_pitch / 4    # Half thickness at pitch line

    # At tip (addendum above pitch): narrower
    tip_half_thick = pitch_half_thick - addendum * tan_pa

    # At root (dedendum below pitch): wider
    root_half_thick = pitch_half_thick + dedendum * tan_pa

    # Ensure tip isn't too thin (minimum 0.2 × module)
    min_tip = 0.1 * module
    if tip_half_thick < min_tip:
        tip_half_thick = min_tip

    # ══════════════════════════════════════════════════════════════════════════
    # SKETCH ON XY PLANE - then extrude in Z, then rotate result
    #
    # Profile coordinate system:
    # X = horizontal position along rack
    # Y = vertical height (teeth point in +Y direction)
    #
    # After rotation: Y becomes Z (teeth point up)
    # ══════════════════════════════════════════════════════════════════════════

    sketches = rack_comp.sketches
    xyPlane = rack_comp.xYConstructionPlane

    sketch = sketches.add(xyPlane)
    lines = sketch.sketchCurves.sketchLines
    arcs = sketch.sketchCurves.sketchArcs

    # Convert mm to cm for Fusion API
    cp = circular_pitch / 10
    th = tip_half_thick / 10
    rh = root_half_thick / 10
    tooth_h = tooth_height / 10
    base_h = height / 10
    amp = wave_amp / 10

    # Starting X position for teeth (centered on rack)
    start_x = -num_teeth * cp / 2
    end_x = start_x + num_teeth * cp

    # ══════════════════════════════════════════════════════════════════════════
    # Build tooth profile points
    #
    # Each tooth has 6 key points (simplified without fillets for reliability):
    # 1. Root left (at root level)
    # 2. Flank left lower (start of involute at root)
    # 3. Tip left
    # 4. Tip right
    # 5. Flank right lower (start of involute at root)
    # 6. Root right
    #
    # Root level = wave surface (0)
    # Tip level = tooth_height above root
    # ══════════════════════════════════════════════════════════════════════════

    points = []

    # Bottom of base (flat, below the lowest wave point)
    base_bottom_y = -amp - base_h  # Below wave trough

    # Start at bottom-left corner
    points.append((start_x - cp/2, base_bottom_y))

    # Bottom edge to right
    points.append((end_x + cp/2, base_bottom_y))

    # Right edge up to root level at wave surface
    right_x_mm = (end_x + cp/2) * 10
    right_wave_y = wave_z(right_x_mm, wave_amp, wave_len) / 10
    points.append((end_x + cp/2, right_wave_y))

    # ══════════════════════════════════════════════════════════════════════════
    # TEETH: Draw from right to left
    # Each tooth tilted perpendicular to local wave slope
    # ══════════════════════════════════════════════════════════════════════════

    for i in range(num_teeth - 1, -1, -1):
        # Tooth center X position (cm)
        cx_cm = start_x + (i + 0.5) * cp
        cx_mm = cx_cm * 10

        # Wave Y at this tooth center (cm)
        wave_y_cm = wave_z(cx_mm, wave_amp, wave_len) / 10

        # Slope angle for tilting tooth perpendicular to surface
        slope_deg = wave_slope_angle(cx_mm, wave_amp, wave_len)
        cos_s = math.cos(math.radians(slope_deg))
        sin_s = math.sin(math.radians(slope_deg))

        # ════════════════════════════════════════════════════════════════════
        # Local tooth profile (x_local, y_local)
        # Origin at tooth center on wave surface (root level)
        # y_local = 0 is root, y_local = tooth_h is tip
        #
        # Standard involute rack tooth with straight flanks
        # ════════════════════════════════════════════════════════════════════

        local_tooth = [
            # Right side of tooth (coming from previous space)
            (rh, 0),                    # Root right (wide)
            (th, tooth_h),              # Tip right (narrow)
            # Across the tip
            (-th, tooth_h),             # Tip left
            # Left side of tooth (going into next space)
            (-rh, 0),                   # Root left
        ]

        # Transform each point: rotate by slope, translate to wave position
        for lx, ly in local_tooth:
            # Rotate around origin by slope angle
            rx = lx * cos_s - ly * sin_s
            ry = lx * sin_s + ly * cos_s
            # Translate to global position
            gx = cx_cm + rx
            gy = wave_y_cm + ry
            points.append((gx, gy))

    # Left edge down from last tooth root to wave surface then to bottom
    left_x_mm = (start_x - cp/2) * 10
    left_wave_y = wave_z(left_x_mm, wave_amp, wave_len) / 10
    points.append((start_x - cp/2, left_wave_y))

    # Close back to start (bottom left)
    points.append((start_x - cp/2, base_bottom_y))

    # ══════════════════════════════════════════════════════════════════════════
    # Draw the closed profile
    # ══════════════════════════════════════════════════════════════════════════

    for i in range(len(points) - 1):
        p1 = adsk.core.Point3D.create(points[i][0], points[i][1], 0)
        p2 = adsk.core.Point3D.create(points[i + 1][0], points[i + 1][1], 0)
        lines.addByTwoPoints(p1, p2)

    # ══════════════════════════════════════════════════════════════════════════
    # EXTRUDE in Z direction (width)
    # ══════════════════════════════════════════════════════════════════════════

    extrudes = rack_comp.features.extrudeFeatures

    if sketch.profiles.count > 0:
        # Find the largest profile (the full rack cross-section)
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
            extInput.setSymmetricExtent(adsk.core.ValueInput.createByReal(width / 2 / 10), True)
            extrudes.add(extInput)

            # ══════════════════════════════════════════════════════════════════
            # ROTATE 90° around X axis so Y becomes Z (teeth point up)
            # ══════════════════════════════════════════════════════════════════

            if rack_comp.bRepBodies.count > 0:
                body = rack_comp.bRepBodies.item(0)

                # Create move feature to rotate
                moves = rack_comp.features.moveFeatures

                # Create collection with the body
                bodies = adsk.core.ObjectCollection.create()
                bodies.add(body)

                # Create transform: rotate 90° around X axis
                transform = adsk.core.Matrix3D.create()
                origin = adsk.core.Point3D.create(0, 0, 0)
                xAxis = adsk.core.Vector3D.create(1, 0, 0)
                transform.setToRotation(math.pi / 2, xAxis, origin)  # 90 degrees

                moveInput = moves.createInput2(bodies)
                moveInput.defineAsFreeMove(transform)
                moves.add(moveInput)

    # Apply appearance
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
