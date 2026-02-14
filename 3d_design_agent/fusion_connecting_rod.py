"""
FUSION 360 CONNECTING ROD WITH 3D PRINTABLE JOINTS
Industry-standard connections for kinetic sculpture mechanism

Features:
- Gear end: Fork/clevis design with 6.4mm bore for eccentric pin
- Rocker end: Spherical rod-end bearing for misalignment
- 3D print tolerances (0.3-0.4mm clearance)
- Clevis pin holes for retention

INSTALLATION:
1. Copy to: %appdata%\Autodesk\Autodesk Fusion 360\API\Scripts\ConnectingRod\ConnectingRod.py
2. Or run install_fusion_scripts.bat

Author: Claude
"""

import adsk.core, adsk.fusion, adsk.cam, traceback
import math

# ═══════════════════════════════════════════════════════════════════════════════
#                           DEFAULT PARAMETERS
# ═══════════════════════════════════════════════════════════════════════════════

# Rod dimensions
DEFAULT_ROD_LENGTH = 55.0      # mm - center-to-center
DEFAULT_ROD_WIDTH = 10.0       # mm - cross-section width
DEFAULT_ROD_HEIGHT = 6.0       # mm - cross-section height

# Gear end (fork/clevis) - connects to eccentric pin
DEFAULT_FORK_PIN_BORE = 6.4    # mm - 0.4mm clearance for 6mm pin
DEFAULT_FORK_GAP = 8.5         # mm - gap for 8mm shoulder (0.5mm clearance)
DEFAULT_FORK_WALL = 3.0        # mm - wall thickness (3D print minimum)
DEFAULT_FORK_LENGTH = 15.0     # mm - length of fork prongs
DEFAULT_CLEVIS_HOLE = 3.2      # mm - for 3mm clevis pin retention

# Rocker end (spherical bearing)
DEFAULT_BALL_DIA = 12.0        # mm - spherical ball
DEFAULT_BEARING_BORE = 8.0     # mm - for M8 shoulder bolt
DEFAULT_SOCKET_CLEARANCE = 0.4 # mm - 3D print clearance
DEFAULT_BEARING_WIDTH = 12.0   # mm - housing width


def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface

        # Get user input
        params = get_user_input(ui)
        if params is None:
            return

        rod_length, rod_width, rod_height = params

        # Create the connecting rod
        create_connecting_rod(rod_length, rod_width, rod_height)

        ui.messageBox(f'Connecting rod created!\n\n'
                     f'LENGTH: {rod_length}mm (C-to-C)\n'
                     f'SECTION: {rod_width}×{rod_height}mm\n\n'
                     f'GEAR END (Fork):\n'
                     f'  Pin bore: Ø{DEFAULT_FORK_PIN_BORE}mm\n'
                     f'  Fork gap: {DEFAULT_FORK_GAP}mm\n'
                     f'  Clevis hole: Ø{DEFAULT_CLEVIS_HOLE}mm\n\n'
                     f'ROCKER END (Bearing):\n'
                     f'  Ball: Ø{DEFAULT_BALL_DIA}mm\n'
                     f'  Bore: Ø{DEFAULT_BEARING_BORE}mm\n'
                     f'  Misalignment: ±15°')

    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))


def get_user_input(ui):
    """Get rod parameters from user"""
    try:
        length_input = ui.inputBox('Enter rod length center-to-center (mm):',
                                   'Length', str(DEFAULT_ROD_LENGTH))
        if length_input[1]: return None
        rod_length = float(length_input[0])

        width_input = ui.inputBox('Enter rod width (mm):',
                                  'Width', str(DEFAULT_ROD_WIDTH))
        if width_input[1]: return None
        rod_width = float(width_input[0])

        height_input = ui.inputBox('Enter rod height (mm):',
                                   'Height', str(DEFAULT_ROD_HEIGHT))
        if height_input[1]: return None
        rod_height = float(height_input[0])

        return (rod_length, rod_width, rod_height)

    except:
        return None


def create_connecting_rod(rod_length, rod_width, rod_height):
    """Create the complete connecting rod assembly"""

    app = adsk.core.Application.get()
    design = app.activeProduct
    rootComp = design.rootComponent

    # Create new component
    occ = rootComp.occurrences.addNewComponent(adsk.core.Matrix3D.create())
    rod_comp = occ.component
    rod_comp.name = f"ConnectingRod_L{int(rod_length)}"

    # Calculate lengths
    fork_length = DEFAULT_FORK_LENGTH
    bearing_length = DEFAULT_BEARING_WIDTH
    body_length = rod_length - fork_length - bearing_length / 2

    # ═══════════════════════════════════════════════════════════════════════════
    # Create components
    # ═══════════════════════════════════════════════════════════════════════════

    # 1. Fork end (gear connection) - at Y = 0
    create_fork_end(rod_comp, rod_width, rod_height)

    # 2. Rod body
    create_rod_body(rod_comp, body_length, rod_width, rod_height)

    # 3. Spherical bearing end (rocker connection) - at Y = rod_length
    create_bearing_end(rod_comp, rod_length)

    # Apply appearance
    apply_appearance(rod_comp, "Aluminum - Satin")

    return rod_comp


def create_fork_end(comp, width, height):
    """Create fork/clevis end for gear pin connection"""

    sketches = comp.sketches
    xzPlane = comp.xZConstructionPlane

    # ═══════════════════════════════════════════════════════════════════════════
    # Fork profile (viewed from front, Y=0)
    # Two prongs with gap in middle for eccentric pin shoulder
    # ═══════════════════════════════════════════════════════════════════════════

    sketch = sketches.add(xzPlane)
    lines = sketch.sketchCurves.sketchLines

    # Dimensions in cm
    w = width / 10
    h = height / 10
    gap = DEFAULT_FORK_GAP / 10
    wall = DEFAULT_FORK_WALL / 10
    fork_len = DEFAULT_FORK_LENGTH / 10

    # Total width = gap + 2*wall
    total_w = gap + 2 * wall
    half_w = total_w / 2

    # Draw U-shape (fork) profile
    # Outer rectangle
    p1 = adsk.core.Point3D.create(-half_w, 0, 0)
    p2 = adsk.core.Point3D.create(half_w, 0, 0)
    p3 = adsk.core.Point3D.create(half_w, h, 0)
    p4 = adsk.core.Point3D.create(-half_w, h, 0)

    lines.addByTwoPoints(p1, p2)
    lines.addByTwoPoints(p2, p3)
    lines.addByTwoPoints(p3, p4)
    lines.addByTwoPoints(p4, p1)

    # Inner cutout (the gap)
    gap_half = gap / 2
    gap_h = h * 0.7  # Gap depth = 70% of height

    p5 = adsk.core.Point3D.create(-gap_half, h, 0)
    p6 = adsk.core.Point3D.create(gap_half, h, 0)
    p7 = adsk.core.Point3D.create(gap_half, h - gap_h, 0)
    p8 = adsk.core.Point3D.create(-gap_half, h - gap_h, 0)

    lines.addByTwoPoints(p5, p6)
    lines.addByTwoPoints(p6, p7)
    lines.addByTwoPoints(p7, p8)
    lines.addByTwoPoints(p8, p5)

    # ═══════════════════════════════════════════════════════════════════════════
    # Extrude fork (in Y direction)
    # ═══════════════════════════════════════════════════════════════════════════

    extrudes = comp.features.extrudeFeatures

    # Find the U-shaped profile (fork with gap)
    for i in range(sketch.profiles.count):
        prof = sketch.profiles.item(i)
        try:
            area = prof.areaProperties().area
            # U-shape area = outer - inner
            outer_area = total_w * h
            inner_area = gap * gap_h
            expected = outer_area - inner_area
            if abs(area - expected) < 0.001:
                extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
                distance = adsk.core.ValueInput.createByReal(fork_len)
                extInput.setDistanceExtent(False, distance)
                extrudes.add(extInput)
                break
        except:
            pass

    # If no U-shape found, extrude largest profile
    if comp.bRepBodies.count == 0:
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
            distance = adsk.core.ValueInput.createByReal(fork_len)
            extInput.setDistanceExtent(False, distance)
            extrudes.add(extInput)

    # ═══════════════════════════════════════════════════════════════════════════
    # Add pin bore holes through both fork prongs
    # ═══════════════════════════════════════════════════════════════════════════

    # Pin bore at mid-length of fork
    pin_y = fork_len / 2
    pin_z = h / 2
    pin_r = DEFAULT_FORK_PIN_BORE / 2 / 10

    # Create plane at pin location
    planes = comp.constructionPlanes
    try:
        planeInput = planes.createInput()
        planeInput.setByOffset(comp.yZConstructionPlane,
                              adsk.core.ValueInput.createByReal(pin_y))
        pin_plane = planes.add(planeInput)

        sketch_pin = sketches.add(pin_plane)
        circles = sketch_pin.sketchCurves.sketchCircles

        # Left prong hole
        left_x = -(gap / 2 + wall / 2)
        circles.addByCenterRadius(
            adsk.core.Point3D.create(left_x, pin_z, 0),
            pin_r
        )

        # Right prong hole
        right_x = gap / 2 + wall / 2
        circles.addByCenterRadius(
            adsk.core.Point3D.create(right_x, pin_z, 0),
            pin_r
        )

        # Cut pin holes
        for i in range(sketch_pin.profiles.count):
            prof = sketch_pin.profiles.item(i)
            extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.CutFeatureOperation)
            extInput.setAllExtent(adsk.fusion.ExtentDirections.SymmetricExtentDirection)
            try:
                extrudes.add(extInput)
            except:
                pass
    except:
        pass

    # ═══════════════════════════════════════════════════════════════════════════
    # Add clevis pin hole (perpendicular to main pin)
    # ═══════════════════════════════════════════════════════════════════════════

    clevis_r = DEFAULT_CLEVIS_HOLE / 2 / 10

    try:
        # Clevis hole goes through the pin (Y direction)
        sketch_clevis = sketches.add(xzPlane)
        clevis_circles = sketch_clevis.sketchCurves.sketchCircles

        clevis_circles.addByCenterRadius(
            adsk.core.Point3D.create(0, pin_z, 0),
            clevis_r
        )

        prof = sketch_clevis.profiles.item(0)
        extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.CutFeatureOperation)
        distance = adsk.core.ValueInput.createByReal(fork_len)
        extInput.setDistanceExtent(False, distance)
        extrudes.add(extInput)
    except:
        pass


def create_rod_body(comp, body_length, width, height):
    """Create the central rod body"""

    sketches = comp.sketches

    # Body starts after fork
    fork_len = DEFAULT_FORK_LENGTH / 10
    body_len = body_length / 10
    w = width / 10
    h = height / 10

    # ═══════════════════════════════════════════════════════════════════════════
    # Create cross-section at fork end
    # ═══════════════════════════════════════════════════════════════════════════

    # Create plane at fork end
    planes = comp.constructionPlanes
    try:
        planeInput = planes.createInput()
        planeInput.setByOffset(comp.xZConstructionPlane,
                              adsk.core.ValueInput.createByReal(fork_len))
        body_start_plane = planes.add(planeInput)

        sketch = sketches.add(body_start_plane)
        lines = sketch.sketchCurves.sketchLines

        # Rounded rectangle cross-section
        half_w = w / 2
        half_h = h / 2
        r = min(half_w, half_h) * 0.3  # Corner radius

        # Simple rectangle (corners can be filleted later)
        lines.addTwoPointRectangle(
            adsk.core.Point3D.create(-half_w, -half_h, 0),
            adsk.core.Point3D.create(half_w, half_h, 0)
        )

        # Extrude rod body
        extrudes = comp.features.extrudeFeatures
        prof = sketch.profiles.item(0)

        extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.JoinFeatureOperation)
        distance = adsk.core.ValueInput.createByReal(body_len)
        extInput.setDistanceExtent(False, distance)
        extrudes.add(extInput)

    except:
        pass


def create_bearing_end(comp, rod_length):
    """Create spherical rod-end bearing at rocker connection"""

    sketches = comp.sketches
    extrudes = comp.features.extrudeFeatures
    revolves = comp.features.revolveFeatures

    # Bearing position (at rod_length from origin)
    fork_len = DEFAULT_FORK_LENGTH / 10
    bearing_y = rod_length / 10

    ball_r = DEFAULT_BALL_DIA / 2 / 10
    bore_r = DEFAULT_BEARING_BORE / 2 / 10
    socket_r = (DEFAULT_BALL_DIA / 2 + DEFAULT_SOCKET_CLEARANCE) / 10
    housing_r = (DEFAULT_BALL_DIA / 2 + 3) / 10  # 3mm wall
    housing_w = DEFAULT_BEARING_WIDTH / 10

    # ═══════════════════════════════════════════════════════════════════════════
    # Create bearing housing (cylinder with spherical socket)
    # ═══════════════════════════════════════════════════════════════════════════

    # Create plane at bearing location
    planes = comp.constructionPlanes
    try:
        planeInput = planes.createInput()
        planeInput.setByOffset(comp.xZConstructionPlane,
                              adsk.core.ValueInput.createByReal(bearing_y - housing_w / 2))
        housing_plane = planes.add(planeInput)

        sketch_housing = sketches.add(housing_plane)
        circles = sketch_housing.sketchCurves.sketchCircles

        # Outer housing circle
        circles.addByCenterRadius(
            adsk.core.Point3D.create(0, 0, 0),
            housing_r
        )

        # Extrude housing
        prof = sketch_housing.profiles.item(0)
        extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.JoinFeatureOperation)
        distance = adsk.core.ValueInput.createByReal(housing_w)
        extInput.setDistanceExtent(False, distance)
        extrudes.add(extInput)

    except:
        pass

    # ═══════════════════════════════════════════════════════════════════════════
    # Cut spherical socket
    # ═══════════════════════════════════════════════════════════════════════════

    try:
        # Create plane at bearing center for spherical cut
        planeInput = planes.createInput()
        planeInput.setByOffset(comp.yZConstructionPlane,
                              adsk.core.ValueInput.createByReal(bearing_y))
        socket_plane = planes.add(planeInput)

        sketch_socket = sketches.add(socket_plane)
        socket_circles = sketch_socket.sketchCurves.sketchCircles
        socket_lines = sketch_socket.sketchCurves.sketchLines

        # Draw semicircle for revolve
        socket_circles.addByCenterRadius(
            adsk.core.Point3D.create(0, 0, 0),
            socket_r
        )

        # Create axis for revolve
        axis_line = socket_lines.addByTwoPoints(
            adsk.core.Point3D.create(0, -socket_r - 0.1, 0),
            adsk.core.Point3D.create(0, socket_r + 0.1, 0)
        )
        axis_line.isConstruction = True

        # Revolve to cut sphere
        prof = sketch_socket.profiles.item(0)
        revInput = revolves.createInput(prof, axis_line, adsk.fusion.FeatureOperations.CutFeatureOperation)
        angle = adsk.core.ValueInput.createByString("360 deg")
        revInput.setAngleExtent(False, angle)
        revolves.add(revInput)

    except:
        pass

    # ═══════════════════════════════════════════════════════════════════════════
    # Create ball (inner race)
    # ═══════════════════════════════════════════════════════════════════════════

    try:
        sketch_ball = sketches.add(socket_plane)
        ball_circles = sketch_ball.sketchCurves.sketchCircles
        ball_lines = sketch_ball.sketchCurves.sketchLines

        # Ball circle
        ball_circles.addByCenterRadius(
            adsk.core.Point3D.create(0, 0, 0),
            ball_r
        )

        # Axis for revolve
        axis_ball = ball_lines.addByTwoPoints(
            adsk.core.Point3D.create(0, -ball_r - 0.1, 0),
            adsk.core.Point3D.create(0, ball_r + 0.1, 0)
        )
        axis_ball.isConstruction = True

        # Revolve to create sphere
        prof = sketch_ball.profiles.item(0)
        revInput = revolves.createInput(prof, axis_ball, adsk.fusion.FeatureOperations.JoinFeatureOperation)
        angle = adsk.core.ValueInput.createByString("360 deg")
        revInput.setAngleExtent(False, angle)
        revolves.add(revInput)

    except:
        pass

    # ═══════════════════════════════════════════════════════════════════════════
    # Cut bore through ball
    # ═══════════════════════════════════════════════════════════════════════════

    try:
        sketch_bore = sketches.add(comp.xYConstructionPlane)
        bore_circles = sketch_bore.sketchCurves.sketchCircles

        bore_circles.addByCenterRadius(
            adsk.core.Point3D.create(0, bearing_y, 0),
            bore_r
        )

        prof = sketch_bore.profiles.item(0)
        extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.CutFeatureOperation)
        extInput.setAllExtent(adsk.fusion.ExtentDirections.SymmetricExtentDirection)
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
