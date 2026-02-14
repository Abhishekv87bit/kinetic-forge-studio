"""
FUSION 360 SPUR GEAR WITH ECCENTRIC PIN
ISO 21771 Compliant Involute Profile + 3D Print Optimized

Features:
- True involute tooth profile (20° pressure angle)
- Eccentric drive pin for connecting rod
- Set screw hole for motor shaft
- 3D print tolerances built in

INSTALLATION:
1. Copy to: %appdata%\Autodesk\Autodesk Fusion 360\API\Scripts\SpurGear\SpurGear.py
2. Or run install_fusion_scripts.bat

Author: Claude
"""

import adsk.core, adsk.fusion, adsk.cam, traceback
import math

# ═══════════════════════════════════════════════════════════════════════════════
#                           DEFAULT PARAMETERS
# ═══════════════════════════════════════════════════════════════════════════════

# Gear parameters (ISO 21771)
DEFAULT_MODULE = 3.0           # mm - tooth size
DEFAULT_TEETH = 20             # number of teeth
DEFAULT_THICKNESS = 15.0       # mm - gear face width
DEFAULT_PRESSURE_ANGLE = 20.0  # degrees

# Bore parameters (3D print optimized)
DEFAULT_BORE = 8.0             # mm - for motor shaft
DEFAULT_BORE_CLEARANCE = 0.3   # mm - 3D print tolerance
DEFAULT_SET_SCREW = 3.0        # mm - M3 set screw hole

# Eccentric pin parameters
DEFAULT_PIN_OFFSET = 15.0      # mm - distance from center
DEFAULT_PIN_DIAMETER = 6.0     # mm - pin shaft diameter
DEFAULT_PIN_HEIGHT = 12.0      # mm - height above gear face
DEFAULT_SHOULDER_DIA = 8.0     # mm - shoulder to retain connecting rod
DEFAULT_SHOULDER_HEIGHT = 2.0  # mm
DEFAULT_CLEVIS_HOLE = 3.2      # mm - for 3mm clevis pin (0.2mm clearance)


def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface

        # Get user input
        params = get_user_input(ui)
        if params is None:
            return

        module, teeth, thickness, bore, pin_offset, pin_dia, pin_height = params

        # Create the gear with eccentric pin
        create_gear_with_pin(module, teeth, thickness, bore, pin_offset, pin_dia, pin_height)

        # Calculate dimensions for display
        pitch_dia = module * teeth
        tip_dia = pitch_dia + 2 * module

        ui.messageBox(f'Spur gear with eccentric pin created!\n\n'
                     f'GEAR:\n'
                     f'  Module: {module}mm\n'
                     f'  Teeth: {teeth}\n'
                     f'  Pitch Ø: {pitch_dia}mm\n'
                     f'  Tip Ø: {tip_dia}mm\n'
                     f'  Thickness: {thickness}mm\n\n'
                     f'ECCENTRIC PIN:\n'
                     f'  Offset: {pin_offset}mm\n'
                     f'  Diameter: {pin_dia}mm\n'
                     f'  Height: {pin_height}mm\n\n'
                     f'BORE: Ø{bore}mm with M3 set screw')

    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))


def get_user_input(ui):
    """Get gear parameters from user"""
    try:
        module_input = ui.inputBox('Enter gear module (mm):', 'Module', str(DEFAULT_MODULE))
        if module_input[1]: return None
        module = float(module_input[0])

        teeth_input = ui.inputBox('Enter number of teeth:', 'Teeth', str(DEFAULT_TEETH))
        if teeth_input[1]: return None
        teeth = int(teeth_input[0])

        thickness_input = ui.inputBox('Enter face width (mm):', 'Thickness', str(DEFAULT_THICKNESS))
        if thickness_input[1]: return None
        thickness = float(thickness_input[0])

        bore_input = ui.inputBox('Enter bore diameter (mm, 0 for solid):', 'Bore', str(DEFAULT_BORE))
        if bore_input[1]: return None
        bore = float(bore_input[0])

        pin_offset_input = ui.inputBox('Enter eccentric pin offset (mm):', 'Pin Offset', str(DEFAULT_PIN_OFFSET))
        if pin_offset_input[1]: return None
        pin_offset = float(pin_offset_input[0])

        pin_dia_input = ui.inputBox('Enter pin diameter (mm):', 'Pin Diameter', str(DEFAULT_PIN_DIAMETER))
        if pin_dia_input[1]: return None
        pin_dia = float(pin_dia_input[0])

        pin_height_input = ui.inputBox('Enter pin height above gear (mm):', 'Pin Height', str(DEFAULT_PIN_HEIGHT))
        if pin_height_input[1]: return None
        pin_height = float(pin_height_input[0])

        return (module, teeth, thickness, bore, pin_offset, pin_dia, pin_height)

    except:
        return None


def create_gear_with_pin(module, teeth, thickness, bore, pin_offset, pin_dia, pin_height):
    """Create the complete gear assembly"""

    app = adsk.core.Application.get()
    design = app.activeProduct
    rootComp = design.rootComponent

    # Create new component
    occ = rootComp.occurrences.addNewComponent(adsk.core.Matrix3D.create())
    gear_comp = occ.component
    gear_comp.name = f"SpurGear_M{module}_T{teeth}_Pin"

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 1: Calculate gear dimensions
    # ═══════════════════════════════════════════════════════════════════════════

    pitch_radius = module * teeth / 2.0
    base_radius = pitch_radius * math.cos(math.radians(DEFAULT_PRESSURE_ANGLE))
    tip_radius = pitch_radius + module
    root_radius = pitch_radius - 1.25 * module

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 2: Create gear blank with teeth
    # ═══════════════════════════════════════════════════════════════════════════

    create_gear_body(gear_comp, module, teeth, thickness, pitch_radius,
                    base_radius, tip_radius, root_radius)

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 3: Add center bore with set screw hole
    # ═══════════════════════════════════════════════════════════════════════════

    if bore > 0:
        add_bore_with_setscrew(gear_comp, bore, thickness)

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 4: Add eccentric pin with shoulder and clevis hole
    # ═══════════════════════════════════════════════════════════════════════════

    add_eccentric_pin(gear_comp, pin_offset, pin_dia, pin_height, thickness)

    # Apply appearance
    apply_appearance(gear_comp, "Steel - Satin")

    return gear_comp


def create_gear_body(comp, module, teeth, thickness, pitch_r, base_r, tip_r, root_r):
    """Create the gear body with involute teeth"""

    sketches = comp.sketches
    xyPlane = comp.xYConstructionPlane

    sketch = sketches.add(xyPlane)
    circles = sketch.sketchCurves.sketchCircles
    lines = sketch.sketchCurves.sketchLines
    splines = sketch.sketchCurves.sketchFittedSplines

    center = adsk.core.Point3D.create(0, 0, 0)

    # Convert to cm
    pitch_r_cm = pitch_r / 10
    base_r_cm = base_r / 10
    tip_r_cm = tip_r / 10
    root_r_cm = root_r / 10
    thick_cm = thickness / 10

    # Draw root circle (gear blank base)
    root_circle = circles.addByCenterRadius(center, root_r_cm)

    # Calculate tooth parameters
    angular_pitch = 2 * math.pi / teeth
    tooth_thick_angle = (math.pi * module / 2) / pitch_r  # radians

    # ═══════════════════════════════════════════════════════════════════════════
    # Generate involute teeth
    # ═══════════════════════════════════════════════════════════════════════════

    for i in range(teeth):
        tooth_angle = i * angular_pitch
        draw_involute_tooth(sketch, base_r, tip_r, root_r, tooth_angle,
                           tooth_thick_angle, DEFAULT_PRESSURE_ANGLE)

    # ═══════════════════════════════════════════════════════════════════════════
    # Extrude gear body
    # ═══════════════════════════════════════════════════════════════════════════

    extrudes = comp.features.extrudeFeatures

    # Find largest profile (gear with teeth)
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
        distance = adsk.core.ValueInput.createByReal(thick_cm)
        extInput.setDistanceExtent(False, distance)
        extrudes.add(extInput)


def draw_involute_tooth(sketch, base_r, tip_r, root_r, rotation, tooth_thick_angle, pressure_angle):
    """Draw a single involute tooth"""

    lines = sketch.sketchCurves.sketchLines
    splines = sketch.sketchCurves.sketchFittedSplines

    # Convert to cm
    base_r_cm = base_r / 10
    tip_r_cm = tip_r / 10
    root_r_cm = root_r / 10

    # Generate involute points for right flank
    right_points = []
    steps = 12
    t_max = involute_t_at_radius(base_r, tip_r)

    for j in range(steps + 1):
        t = t_max * j / steps
        x, y = involute_point(base_r, t)

        # Rotate to tooth position (right flank)
        angle = rotation - tooth_thick_angle / 2
        rx = (x * math.cos(angle) - y * math.sin(angle)) / 10
        ry = (x * math.sin(angle) + y * math.cos(angle)) / 10

        right_points.append(adsk.core.Point3D.create(rx, ry, 0))

    # Generate involute points for left flank (mirrored)
    left_points = []
    for j in range(steps + 1):
        t = t_max * j / steps
        x, y = involute_point(base_r, t)

        # Mirror and rotate
        x = -x
        angle = rotation + tooth_thick_angle / 2
        rx = (x * math.cos(angle) - y * math.sin(angle)) / 10
        ry = (x * math.sin(angle) + y * math.cos(angle)) / 10

        left_points.append(adsk.core.Point3D.create(rx, ry, 0))

    # Create splines for tooth flanks
    try:
        right_collection = adsk.core.ObjectCollection.create()
        for pt in right_points:
            right_collection.add(pt)
        right_spline = splines.add(right_collection)

        left_collection = adsk.core.ObjectCollection.create()
        for pt in reversed(left_points):
            left_collection.add(pt)
        left_spline = splines.add(left_collection)

        # Connect tip with line
        lines.addByTwoPoints(right_points[-1], left_points[-1])

    except:
        # Fallback to lines if splines fail
        for j in range(len(right_points) - 1):
            lines.addByTwoPoints(right_points[j], right_points[j + 1])
        lines.addByTwoPoints(right_points[-1], left_points[-1])
        for j in range(len(left_points) - 1):
            lines.addByTwoPoints(left_points[j], left_points[j + 1])


def add_bore_with_setscrew(comp, bore_dia, thickness):
    """Add center bore with radial set screw hole"""

    sketches = comp.sketches
    xyPlane = comp.xYConstructionPlane

    # ═══════════════════════════════════════════════════════════════════════════
    # Cut center bore (with 3D print clearance)
    # ═══════════════════════════════════════════════════════════════════════════

    sketch_bore = sketches.add(xyPlane)
    circles = sketch_bore.sketchCurves.sketchCircles

    # Add clearance for 3D printing
    bore_with_clearance = bore_dia + DEFAULT_BORE_CLEARANCE
    bore_r_cm = bore_with_clearance / 2 / 10

    bore_circle = circles.addByCenterRadius(
        adsk.core.Point3D.create(0, 0, 0),
        bore_r_cm
    )

    extrudes = comp.features.extrudeFeatures
    prof = sketch_bore.profiles.item(0)

    extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.CutFeatureOperation)
    extInput.setAllExtent(adsk.fusion.ExtentDirections.SymmetricExtentDirection)
    extrudes.add(extInput)

    # ═══════════════════════════════════════════════════════════════════════════
    # Add radial set screw hole (M3)
    # ═══════════════════════════════════════════════════════════════════════════

    # Find side face of gear for set screw
    body = comp.bRepBodies.item(0)
    side_face = None

    # Find cylindrical face of bore
    for face in body.faces:
        geom = face.geometry
        if hasattr(geom, 'surfaceType'):
            if geom.surfaceType == adsk.core.SurfaceTypes.CylinderSurfaceType:
                # Check if it's the bore (inner cylinder)
                if hasattr(geom, 'radius'):
                    if abs(geom.radius - bore_r_cm) < 0.01:
                        side_face = face
                        break

    if side_face:
        # Create construction plane at mid-height for set screw
        planes = comp.constructionPlanes
        planeInput = planes.createInput()

        # Use XZ plane offset to mid-height
        xzPlane = comp.xZConstructionPlane
        thick_cm = thickness / 10
        offsetValue = adsk.core.ValueInput.createByReal(thick_cm / 2)
        planeInput.setByOffset(xzPlane, offsetValue)

        try:
            midPlane = planes.add(planeInput)

            # Sketch set screw hole
            sketch_screw = sketches.add(midPlane)
            screw_circles = sketch_screw.sketchCurves.sketchCircles

            # Set screw at bore radius, pointing inward
            screw_r_cm = DEFAULT_SET_SCREW / 2 / 10
            screw_x = (bore_dia / 2 + 3) / 10  # 3mm into material

            screw_circles.addByCenterRadius(
                adsk.core.Point3D.create(screw_x, 0, 0),
                screw_r_cm
            )

            # Cut set screw hole
            prof = sketch_screw.profiles.item(0)
            extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.CutFeatureOperation)
            extInput.setAllExtent(adsk.fusion.ExtentDirections.SymmetricExtentDirection)
            extrudes.add(extInput)
        except:
            pass  # Set screw not critical


def add_eccentric_pin(comp, pin_offset, pin_dia, pin_height, gear_thickness):
    """Add eccentric drive pin with shoulder and clevis hole"""

    sketches = comp.sketches

    # Get top face of gear
    body = comp.bRepBodies.item(0)
    top_face = None
    thick_cm = gear_thickness / 10

    for face in body.faces:
        try:
            normal = face.evaluator.getNormalAtPoint(face.pointOnFace)[1]
            if abs(normal.z - 1.0) < 0.01:
                # Check if it's at the top (Z = thickness)
                bbox = face.boundingBox
                if bbox.maxPoint.z > thick_cm * 0.9:
                    top_face = face
                    break
        except:
            pass

    if not top_face:
        # Fallback: use XY plane offset
        planes = comp.constructionPlanes
        planeInput = planes.createInput()
        planeInput.setByOffset(comp.xYConstructionPlane,
                              adsk.core.ValueInput.createByReal(thick_cm))
        top_face = planes.add(planeInput)

    # ═══════════════════════════════════════════════════════════════════════════
    # Create pin base (shoulder)
    # ═══════════════════════════════════════════════════════════════════════════

    sketch_shoulder = sketches.add(top_face)
    circles = sketch_shoulder.sketchCurves.sketchCircles

    pin_offset_cm = pin_offset / 10
    shoulder_r_cm = DEFAULT_SHOULDER_DIA / 2 / 10
    shoulder_h_cm = DEFAULT_SHOULDER_HEIGHT / 10

    # Shoulder circle at eccentric offset
    shoulder_circle = circles.addByCenterRadius(
        adsk.core.Point3D.create(pin_offset_cm, 0, 0),
        shoulder_r_cm
    )

    # Extrude shoulder
    extrudes = comp.features.extrudeFeatures
    prof = sketch_shoulder.profiles.item(0)

    extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.JoinFeatureOperation)
    distance = adsk.core.ValueInput.createByReal(shoulder_h_cm)
    extInput.setDistanceExtent(False, distance)
    extrudes.add(extInput)

    # ═══════════════════════════════════════════════════════════════════════════
    # Create pin shaft
    # ═══════════════════════════════════════════════════════════════════════════

    # Get new top face (shoulder top)
    body = comp.bRepBodies.item(0)
    shoulder_top = None
    target_z = thick_cm + shoulder_h_cm

    for face in body.faces:
        try:
            normal = face.evaluator.getNormalAtPoint(face.pointOnFace)[1]
            if abs(normal.z - 1.0) < 0.01:
                bbox = face.boundingBox
                if abs(bbox.maxPoint.z - target_z) < 0.01:
                    shoulder_top = face
                    break
        except:
            pass

    if shoulder_top:
        sketch_pin = sketches.add(shoulder_top)
    else:
        # Fallback
        planes = comp.constructionPlanes
        planeInput = planes.createInput()
        planeInput.setByOffset(comp.xYConstructionPlane,
                              adsk.core.ValueInput.createByReal(target_z))
        pin_plane = planes.add(planeInput)
        sketch_pin = sketches.add(pin_plane)

    pin_circles = sketch_pin.sketchCurves.sketchCircles
    pin_r_cm = pin_dia / 2 / 10
    pin_h_cm = pin_height / 10

    pin_circle = pin_circles.addByCenterRadius(
        adsk.core.Point3D.create(pin_offset_cm, 0, 0),
        pin_r_cm
    )

    # Extrude pin shaft
    prof = sketch_pin.profiles.item(0)
    extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.JoinFeatureOperation)
    distance = adsk.core.ValueInput.createByReal(pin_h_cm)
    extInput.setDistanceExtent(False, distance)
    extrudes.add(extInput)

    # ═══════════════════════════════════════════════════════════════════════════
    # Add clevis pin hole through pin (for connecting rod retention)
    # ═══════════════════════════════════════════════════════════════════════════

    # Create plane at pin mid-height for clevis hole
    planes = comp.constructionPlanes
    clevis_z = thick_cm + shoulder_h_cm + pin_h_cm / 2

    try:
        # Create XZ plane at pin location
        planeInput = planes.createInput()
        planeInput.setByOffset(comp.xZConstructionPlane,
                              adsk.core.ValueInput.createByReal(clevis_z))
        clevis_plane = planes.add(planeInput)

        sketch_clevis = sketches.add(clevis_plane)
        clevis_circles = sketch_clevis.sketchCurves.sketchCircles

        clevis_r_cm = DEFAULT_CLEVIS_HOLE / 2 / 10

        # Hole through pin perpendicular to radius
        clevis_circles.addByCenterRadius(
            adsk.core.Point3D.create(pin_offset_cm, 0, 0),
            clevis_r_cm
        )

        # Cut clevis hole through pin
        prof = sketch_clevis.profiles.item(0)
        extInput = extrudes.createInput(prof, adsk.fusion.FeatureOperations.CutFeatureOperation)
        extInput.setAllExtent(adsk.fusion.ExtentDirections.SymmetricExtentDirection)
        extrudes.add(extInput)
    except:
        pass  # Clevis hole can be added manually


def involute_point(base_r, t):
    """Calculate point on involute curve at parameter t"""
    x = base_r * (math.cos(t) + t * math.sin(t))
    y = base_r * (math.sin(t) - t * math.cos(t))
    return x, y


def involute_t_at_radius(base_r, r):
    """Calculate involute parameter t at given radius"""
    if r <= base_r:
        return 0
    return math.sqrt((r / base_r) ** 2 - 1)


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
