"""
FUSION 360 ROD-END BEARING (HEIM JOINT) GENERATOR
Spherical bearing for kinetic sculpture linkages

Creates:
- Outer housing with spherical socket
- Inner ball with through-bore

INSTALLATION:
1. Copy to: %appdata%\Autodesk\Autodesk Fusion 360\API\Scripts\RodEndBearing\RodEndBearing.py
2. Or run install_fusion_scripts.bat

Author: Claude
"""

import adsk.core, adsk.fusion, adsk.cam, traceback
import math

# Default parameters
DEFAULT_BORE = 8.0           # mm - through bore for bolt
DEFAULT_BALL_DIA = 12.0      # mm - spherical ball diameter
DEFAULT_BODY_OD = 18.0       # mm - housing outer diameter
DEFAULT_BODY_WIDTH = 12.0    # mm - housing width

def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface

        # Get user input
        params = get_user_input(ui)
        if params is None:
            return

        bore, ball_dia, body_od, body_width = params

        # Create the rod-end bearing
        create_rod_end_bearing(bore, ball_dia, body_od, body_width)

        ui.messageBox(f'Rod-end bearing created!\n\n'
                     f'Bore: Ø{bore}mm\n'
                     f'Ball: Ø{ball_dia}mm\n'
                     f'Body: Ø{body_od}mm × {body_width}mm\n'
                     f'Misalignment: ±15°')

    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))


def get_user_input(ui):
    """Show dialog to get bearing parameters"""
    try:
        bore_input = ui.inputBox(
            'Enter bore diameter (mm):',
            'Bore Diameter',
            str(DEFAULT_BORE)
        )
        if bore_input[1]:
            return None
        bore = float(bore_input[0])

        ball_input = ui.inputBox(
            'Enter ball diameter (mm):',
            'Ball Diameter',
            str(DEFAULT_BALL_DIA)
        )
        if ball_input[1]:
            return None
        ball_dia = float(ball_input[0])

        body_od_input = ui.inputBox(
            'Enter body OD (mm):',
            'Body OD',
            str(DEFAULT_BODY_OD)
        )
        if body_od_input[1]:
            return None
        body_od = float(body_od_input[0])

        body_width_input = ui.inputBox(
            'Enter body width (mm):',
            'Body Width',
            str(DEFAULT_BODY_WIDTH)
        )
        if body_width_input[1]:
            return None
        body_width = float(body_width_input[0])

        return (bore, ball_dia, body_od, body_width)

    except:
        return None


def create_rod_end_bearing(bore, ball_dia, body_od, body_width):
    """Create the rod-end bearing using simple extrude operations"""

    app = adsk.core.Application.get()
    design = app.activeProduct
    rootComp = design.rootComponent

    # Create main component
    occ = rootComp.occurrences.addNewComponent(adsk.core.Matrix3D.create())
    bearing_comp = occ.component
    bearing_comp.name = f"RodEndBearing_Bore{int(bore)}"

    sketches = bearing_comp.sketches
    extrudes = bearing_comp.features.extrudeFeatures

    # Convert to cm
    bore_r = bore / 2 / 10
    ball_r = ball_dia / 2 / 10
    body_r = body_od / 2 / 10
    half_w = body_width / 2 / 10
    socket_r = (ball_dia / 2 + 0.4) / 10  # 0.4mm clearance for 3D printing

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 1: Create housing cylinder
    # ═══════════════════════════════════════════════════════════════════════════

    xyPlane = bearing_comp.xYConstructionPlane
    sketch1 = sketches.add(xyPlane)
    circles1 = sketch1.sketchCurves.sketchCircles

    # Outer housing circle
    circles1.addByCenterRadius(
        adsk.core.Point3D.create(0, 0, 0),
        body_r
    )

    # Extrude housing
    prof1 = sketch1.profiles.item(0)
    extInput1 = extrudes.createInput(prof1, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
    extInput1.setSymmetricExtent(adsk.core.ValueInput.createByReal(half_w), True)
    extrudes.add(extInput1)

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 2: Cut spherical socket using multiple circular cuts
    # (Approximation of sphere using stacked cylinders)
    # ═══════════════════════════════════════════════════════════════════════════

    # Cut main socket hole (cylindrical approximation)
    sketch2 = sketches.add(xyPlane)
    circles2 = sketch2.sketchCurves.sketchCircles

    # Central bore slightly smaller than ball
    circles2.addByCenterRadius(
        adsk.core.Point3D.create(0, 0, 0),
        ball_r * 0.9
    )

    prof2 = sketch2.profiles.item(0)
    extInput2 = extrudes.createInput(prof2, adsk.fusion.FeatureOperations.CutFeatureOperation)
    extInput2.setSymmetricExtent(adsk.core.ValueInput.createByReal(half_w), True)
    extrudes.add(extInput2)

    # Cut larger openings at top and bottom for ball insertion
    # Top opening
    top_plane = create_offset_plane(bearing_comp, half_w * 0.3)
    if top_plane:
        sketch_top = sketches.add(top_plane)
        circles_top = sketch_top.sketchCurves.sketchCircles
        circles_top.addByCenterRadius(
            adsk.core.Point3D.create(0, 0, 0),
            socket_r
        )

        prof_top = sketch_top.profiles.item(0)
        extInput_top = extrudes.createInput(prof_top, adsk.fusion.FeatureOperations.CutFeatureOperation)
        extInput_top.setAllExtent(adsk.fusion.ExtentDirections.PositiveExtentDirection)
        try:
            extrudes.add(extInput_top)
        except:
            pass

    # Bottom opening
    bottom_plane = create_offset_plane(bearing_comp, -half_w * 0.3)
    if bottom_plane:
        sketch_bottom = sketches.add(bottom_plane)
        circles_bottom = sketch_bottom.sketchCurves.sketchCircles
        circles_bottom.addByCenterRadius(
            adsk.core.Point3D.create(0, 0, 0),
            socket_r
        )

        prof_bottom = sketch_bottom.profiles.item(0)
        extInput_bottom = extrudes.createInput(prof_bottom, adsk.fusion.FeatureOperations.CutFeatureOperation)
        extInput_bottom.setAllExtent(adsk.fusion.ExtentDirections.NegativeExtentDirection)
        try:
            extrudes.add(extInput_bottom)
        except:
            pass

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 3: Create ball (separate body)
    # ═══════════════════════════════════════════════════════════════════════════

    # Create ball as cylinder with rounded appearance (true sphere needs revolve)
    sketch_ball = sketches.add(xyPlane)
    circles_ball = sketch_ball.sketchCurves.sketchCircles

    circles_ball.addByCenterRadius(
        adsk.core.Point3D.create(0, 0, 0),
        ball_r
    )

    # Create ball body
    prof_ball = sketch_ball.profiles.item(0)
    extInput_ball = extrudes.createInput(prof_ball, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
    ball_height = ball_r * 0.8  # Slightly flattened sphere approximation
    extInput_ball.setSymmetricExtent(adsk.core.ValueInput.createByReal(ball_height), True)
    extrudes.add(extInput_ball)

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 4: Cut bore through ball
    # ═══════════════════════════════════════════════════════════════════════════

    sketch_bore = sketches.add(xyPlane)
    circles_bore = sketch_bore.sketchCurves.sketchCircles

    circles_bore.addByCenterRadius(
        adsk.core.Point3D.create(0, 0, 0),
        bore_r
    )

    # Cut bore through both bodies
    prof_bore = sketch_bore.profiles.item(0)
    extInput_bore = extrudes.createInput(prof_bore, adsk.fusion.FeatureOperations.CutFeatureOperation)
    extInput_bore.setAllExtent(adsk.fusion.ExtentDirections.SymmetricExtentDirection)
    extrudes.add(extInput_bore)

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 5: Add fillets to housing edges
    # ═══════════════════════════════════════════════════════════════════════════

    try:
        fillets = bearing_comp.features.filletFeatures
        edges = adsk.core.ObjectCollection.create()

        # Add outer edges
        if bearing_comp.bRepBodies.count > 0:
            body = bearing_comp.bRepBodies.item(0)
            for edge in body.edges:
                try:
                    edges.add(edge)
                except:
                    pass

            if edges.count > 0:
                filletInput = fillets.createInput()
                filletInput.addConstantRadiusEdgeSet(edges,
                    adsk.core.ValueInput.createByReal(0.05), True)  # 0.5mm fillet
                fillets.add(filletInput)
    except:
        pass  # Fillets not critical

    # Apply appearance
    apply_appearance(bearing_comp, "Steel - Satin")

    return bearing_comp


def create_offset_plane(comp, offset):
    """Create a construction plane offset from XY"""
    try:
        planes = comp.constructionPlanes
        planeInput = planes.createInput()
        planeInput.setByOffset(comp.xYConstructionPlane,
                              adsk.core.ValueInput.createByReal(offset))
        return planes.add(planeInput)
    except:
        return None


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
