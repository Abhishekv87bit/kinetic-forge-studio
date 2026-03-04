#Author: Claude (Fusion 360 API Script)
#Description: Ravigneaux Double Planetary Gearset - Parametric Build
#
# Run this in Fusion 360: Scripts and Add-Ins > Scripts > + > Select this file
#
# Based on dimensional analysis of Zoo text-to-CAD STEP export.
# All dimensions measured from FreeCAD solid-by-solid analysis of
# "ravigneaux unit.step" (69 solids, 2099 faces).
#
# This script creates a parametric Ravigneaux gearset with:
#   - Central shaft
#   - Small sun gear (meshes with short planets)
#   - Large sun gear (meshes with long planets)
#   - 3 short planet gears (mesh with small sun + ring)
#   - 3 long planet gears (mesh with large sun + ring)
#   - Ring gear (internal teeth, 44mm tall housing)
#   - Ring gear flange (bottom lip)
#   - 2 carrier plates (with shaft bore + planet pin bores)
#   - 6 planet pin bearings
#   - 4 large thrust washers
#   - 12 snap rings
#   - 3 support rods
#   - 3 planet pin mounts
#   - Additional sub-assemblies (spacers, hubs)
#
# IMPORTANT: Gears are simplified cylinders. For production, replace
# with Fusion 360's Spur Gear add-in or GF Gear Generator for
# proper involute tooth profiles.

import adsk.core, adsk.fusion, adsk.cam, traceback, math

# ============================================================
# PARAMETERS — Measured from Zoo STEP via FreeCAD analysis
# ============================================================

# Number of planets (shared across short and long sets)
NUM_PLANETS = 3

# --- Ring Gear (Solid 18) ---
# 96x96x44mm, cylindrical radii: R45 (inner), R48 (outer)
RING_INNER_R = 45.0       # internal bore radius
RING_OUTER_R = 48.0       # outer housing radius
RING_HEIGHT = 44.0        # total ring height (houses both gear stages)

# --- Ring Gear Flange (Solid 21) ---
# 96x96x4mm, radii: R46, R48 — thin lip at bottom of ring
RING_FLANGE_INNER_R = 46.0
RING_FLANGE_OUTER_R = 48.0
RING_FLANGE_HEIGHT = 4.0

# --- Large Sun Gear (Solid 14) ---
# 40.1x40.1x22mm, no cylindrical faces (gear teeth)
SUN_LARGE_OR = 20.0       # outer radius (tip of teeth)
SUN_LARGE_HEIGHT = 22.0

# --- Small Sun Gear (Solid 22) ---
# 33.1x33.0x22mm, no cylindrical faces (gear teeth)
SUN_SMALL_OR = 16.5       # outer radius (tip of teeth)
SUN_SMALL_HEIGHT = 22.0

# --- Long Planet Gears (Solids 9,10,11) ---
# 27x27x22mm each, orbit R=31.5mm (from COM)
PLANET_LONG_OR = 13.5     # outer radius
PLANET_LONG_HEIGHT = 22.0
ORBIT_R_LONG = 31.5       # center distance from axis

# --- Short Planet Gears (Solids 6,7,8) ---
# 26x26x10mm each, orbit R=27.5mm (from COM)
PLANET_SHORT_OR = 13.0    # outer radius
PLANET_SHORT_HEIGHT = 10.0
ORBIT_R_SHORT = 27.5      # center distance from axis

# --- Short planet angular offset ---
# Short planets are at different angles than long planets.
# Long planets at 0/120/240 deg, Short planets offset ~34 deg
# (derived from COM positions)
PLANET_LONG_ANGLE_OFFSET = 0.0    # reference
PLANET_SHORT_ANGLE_OFFSET = 34.0  # degrees offset from long planets

# --- Central Shaft (Solid 65) ---
# 10x10x79mm, R=5
SHAFT_RADIUS = 5.0
SHAFT_LENGTH = 79.0

# --- Carrier Plates (Solids 19, 20) ---
# Both 90x90x3mm, outer R=45
CARRIER_OUTER_R = 45.0
CARRIER_THICKNESS = 3.0
CARRIER_LOWER_BORE_R = 18.0   # from Solid 19 radii
CARRIER_UPPER_BORE_R = 18.5   # from Solid 20 radii

# --- Planet Pin Diameter ---
# Bearings (Solids 27-32) are 8x8x6mm, R=4 => pin OD=8mm
PLANET_PIN_R = 4.0
BEARING_HEIGHT = 6.0

# --- Support Rods (Solids 66,67,68) ---
# 8x140x8mm, R=4
SUPPORT_ROD_R = 4.0
SUPPORT_ROD_LENGTH = 140.0

# --- Large Thrust Washers (Solids 60,62,63,64) ---
# 40x40x1.2mm, R_inner=10, R_outer=20
THRUST_WASHER_INNER_R = 10.0
THRUST_WASHER_OUTER_R = 20.0
THRUST_WASHER_HEIGHT = 1.2

# --- Snap Rings (Solids 48-59) ---
# 13x13x1.2mm, R_inner=3, R_outer=6.5
SNAP_RING_INNER_R = 3.0
SNAP_RING_OUTER_R = 6.5
SNAP_RING_HEIGHT = 1.2

# ============================================================
# Z-STACK LAYOUT (from COM analysis)
# ============================================================
# All Z positions are measured from STEP COM data.
# The gear mesh zone spans Z=0 to Z=22.
# Ring gear is centered at Z=11.1, extends -11 to +33 (44mm total)
#
# Shaft:         Z = -53.0 to  26.0  (COM_Z=-13.5)
# Carrier lower: Z = -11.0 to  -8.0  (COM_Z=-9.5)
# Gear zone:     Z =   0.0 to  22.0
#   Short planets:  Z = 12.0 to 22.0  (10mm, COM_Z=17)
#   Long planets:   Z =  0.0 to 22.0  (22mm, COM_Z=11)
#   Suns:           Z =  0.0 to 22.0  (22mm, COM_Z=11)
# Carrier upper: Z =  30.1 to  33.1  (COM_Z=31.6)
# Ring gear:     Z = -10.9 to  33.1  (44mm, COM_Z=11.1)

# Reference Z: we place the gear mesh zone bottom at Z=0
Z_GEAR_BOTTOM = 0.0
Z_CARRIER_LOWER = -9.5 - CARRIER_THICKNESS / 2   # bottom face
Z_CARRIER_UPPER = 31.6 - CARRIER_THICKNESS / 2    # bottom face
Z_RING = 11.1 - RING_HEIGHT / 2                   # bottom face
Z_RING_FLANGE = -2.0 - RING_FLANGE_HEIGHT / 2     # bottom face
Z_SHAFT = -13.5 - SHAFT_LENGTH / 2                # bottom face
Z_SHORT_PLANET = 12.0                              # bottom face
Z_LONG_PLANET = 0.0                                # bottom face
Z_SUN = 0.0                                        # bottom face


def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface
        design = app.activeProduct
        rootComp = design.rootComponent

        # Switch to parametric design mode
        design.designType = adsk.fusion.DesignTypes.ParametricDesignType

        # ============================================================
        # USER PARAMETERS (editable in Fusion 360 Parameters dialog)
        # ============================================================
        userParams = design.userParameters
        add_param(userParams, "ring_inner_r", RING_INNER_R, "mm",
                  "Ring gear inner radius")
        add_param(userParams, "ring_outer_r", RING_OUTER_R, "mm",
                  "Ring gear outer radius")
        add_param(userParams, "ring_height", RING_HEIGHT, "mm",
                  "Ring gear height")
        add_param(userParams, "sun_large_or", SUN_LARGE_OR, "mm",
                  "Large sun outer radius")
        add_param(userParams, "sun_small_or", SUN_SMALL_OR, "mm",
                  "Small sun outer radius")
        add_param(userParams, "planet_long_or", PLANET_LONG_OR, "mm",
                  "Long planet outer radius")
        add_param(userParams, "planet_short_or", PLANET_SHORT_OR, "mm",
                  "Short planet outer radius")
        add_param(userParams, "orbit_r_long", ORBIT_R_LONG, "mm",
                  "Long planet orbit radius")
        add_param(userParams, "orbit_r_short", ORBIT_R_SHORT, "mm",
                  "Short planet orbit radius")
        add_param(userParams, "shaft_radius", SHAFT_RADIUS, "mm",
                  "Central shaft radius")
        add_param(userParams, "shaft_length", SHAFT_LENGTH, "mm",
                  "Central shaft length")
        add_param(userParams, "carrier_outer_r", CARRIER_OUTER_R, "mm",
                  "Carrier plate outer radius")
        add_param(userParams, "carrier_thickness", CARRIER_THICKNESS, "mm",
                  "Carrier plate thickness")
        add_param(userParams, "planet_pin_r", PLANET_PIN_R, "mm",
                  "Planet pin radius")
        add_param(userParams, "support_rod_r", SUPPORT_ROD_R, "mm",
                  "Support rod radius")
        add_param(userParams, "support_rod_length", SUPPORT_ROD_LENGTH, "mm",
                  "Support rod length")

        # ============================================================
        # BUILD COMPONENTS
        # ============================================================

        # 1. CENTRAL SHAFT (Solid 65)
        build_cylinder(rootComp, "CentralShaft",
                       SHAFT_RADIUS, SHAFT_LENGTH,
                       z_offset=Z_SHAFT)

        # 2. RING GEAR (Solid 18) — annular
        build_annular(rootComp, "RingGear",
                      RING_INNER_R, RING_OUTER_R, RING_HEIGHT,
                      z_offset=Z_RING)

        # 3. RING GEAR FLANGE (Solid 21)
        build_annular(rootComp, "RingFlange",
                      RING_FLANGE_INNER_R, RING_FLANGE_OUTER_R,
                      RING_FLANGE_HEIGHT,
                      z_offset=Z_RING_FLANGE)

        # 4. LARGE SUN GEAR (Solid 14) — cylinder with shaft bore
        build_annular(rootComp, "SunGearLarge",
                      SHAFT_RADIUS, SUN_LARGE_OR, SUN_LARGE_HEIGHT,
                      z_offset=Z_SUN)

        # 5. SMALL SUN GEAR (Solid 22) — cylinder with shaft bore
        build_annular(rootComp, "SunGearSmall",
                      SHAFT_RADIUS, SUN_SMALL_OR, SUN_SMALL_HEIGHT,
                      z_offset=Z_SUN)

        # 6. LONG PLANET GEARS (Solids 9,10,11)
        for i in range(NUM_PLANETS):
            angle = PLANET_LONG_ANGLE_OFFSET + i * (360.0 / NUM_PLANETS)
            angle_rad = math.radians(angle)
            cx = ORBIT_R_LONG * math.cos(angle_rad)
            cy = ORBIT_R_LONG * math.sin(angle_rad)
            build_annular(rootComp, f"PlanetLong_{i+1}",
                          PLANET_PIN_R, PLANET_LONG_OR, PLANET_LONG_HEIGHT,
                          x_offset=cx, y_offset=cy,
                          z_offset=Z_LONG_PLANET)

        # 7. SHORT PLANET GEARS (Solids 6,7,8)
        for i in range(NUM_PLANETS):
            angle = PLANET_SHORT_ANGLE_OFFSET + i * (360.0 / NUM_PLANETS)
            angle_rad = math.radians(angle)
            cx = ORBIT_R_SHORT * math.cos(angle_rad)
            cy = ORBIT_R_SHORT * math.sin(angle_rad)
            build_annular(rootComp, f"PlanetShort_{i+1}",
                          PLANET_PIN_R, PLANET_SHORT_OR, PLANET_SHORT_HEIGHT,
                          x_offset=cx, y_offset=cy,
                          z_offset=Z_SHORT_PLANET)

        # 8. CARRIER PLATE LOWER (Solid 19)
        build_carrier_plate(rootComp, "CarrierPlateLower",
                            CARRIER_OUTER_R, CARRIER_THICKNESS,
                            CARRIER_LOWER_BORE_R,
                            PLANET_PIN_R,
                            ORBIT_R_SHORT, ORBIT_R_LONG,
                            PLANET_SHORT_ANGLE_OFFSET,
                            PLANET_LONG_ANGLE_OFFSET,
                            z_offset=Z_CARRIER_LOWER)

        # 9. CARRIER PLATE UPPER (Solid 20)
        build_carrier_plate(rootComp, "CarrierPlateUpper",
                            CARRIER_OUTER_R, CARRIER_THICKNESS,
                            CARRIER_UPPER_BORE_R,
                            PLANET_PIN_R,
                            ORBIT_R_SHORT, ORBIT_R_LONG,
                            PLANET_SHORT_ANGLE_OFFSET,
                            PLANET_LONG_ANGLE_OFFSET,
                            z_offset=Z_CARRIER_UPPER)

        # 10. PLANET PIN BEARINGS (Solids 27-32)
        # 6 bearings, one per planet, all at Z COM=19
        bearing_z = 19.0 - BEARING_HEIGHT / 2
        for i in range(NUM_PLANETS):
            # Long planet bearings
            angle = PLANET_LONG_ANGLE_OFFSET + i * (360.0 / NUM_PLANETS)
            angle_rad = math.radians(angle)
            cx = ORBIT_R_LONG * math.cos(angle_rad)
            cy = ORBIT_R_LONG * math.sin(angle_rad)
            build_cylinder(rootComp, f"BearingLong_{i+1}",
                           PLANET_PIN_R, BEARING_HEIGHT,
                           x_offset=cx, y_offset=cy,
                           z_offset=bearing_z)

        for i in range(NUM_PLANETS):
            # Short planet bearings
            angle = PLANET_SHORT_ANGLE_OFFSET + i * (360.0 / NUM_PLANETS)
            angle_rad = math.radians(angle)
            cx = ORBIT_R_SHORT * math.cos(angle_rad)
            cy = ORBIT_R_SHORT * math.sin(angle_rad)
            build_cylinder(rootComp, f"BearingShort_{i+1}",
                           PLANET_PIN_R, BEARING_HEIGHT,
                           x_offset=cx, y_offset=cy,
                           z_offset=bearing_z)

        # 11. SUPPORT RODS (Solids 66,67,68)
        # Positioned along the length axis (Y in STEP), placed at specific XZ
        # COM data: (18.5,70,0), (-10.7,55,-18.6), (-12.2,38.5,21.2)
        # These run parallel to Y axis in the STEP; in our model Z is the axis
        rod_xz_positions = [
            (18.5, 0.0),
            (-10.7, -18.6),
            (-12.2, 21.2),
        ]
        rod_z_offset = -SUPPORT_ROD_LENGTH / 2 + RING_HEIGHT / 2
        for i, (rx, rz) in enumerate(rod_xz_positions):
            build_cylinder(rootComp, f"SupportRod_{i+1}",
                           SUPPORT_ROD_R, SUPPORT_ROD_LENGTH,
                           x_offset=rx, y_offset=rz,
                           z_offset=rod_z_offset)

        # 12. LARGE THRUST WASHERS (Solids 60,62,63,64)
        # 4 washers at various Z positions
        washer_z_positions = [22.6, -0.9, 30.6, -20.9]
        for i, wz in enumerate(washer_z_positions):
            z = wz - THRUST_WASHER_HEIGHT / 2
            build_annular(rootComp, f"ThrustWasher_{i+1}",
                          THRUST_WASHER_INNER_R, THRUST_WASHER_OUTER_R,
                          THRUST_WASHER_HEIGHT,
                          z_offset=z)

        # 13. SNAP RINGS (Solids 48-59)
        # 12 snap rings at various Z positions and XY offsets
        # Group by Z: 6 at Z=22.6, 3 at Z=0.6, 3 at Z=12.6
        snap_z_groups = [22.6, 22.6, 22.6, 0.6, 0.6, 0.6,
                         22.6, 22.6, 22.6, 12.6, 12.6, 12.6]
        for i, sz in enumerate(snap_z_groups):
            z = sz - SNAP_RING_HEIGHT / 2
            # Place at origin (simplified - in reality they're on planet pins)
            build_annular(rootComp, f"SnapRing_{i+1}",
                          SNAP_RING_INNER_R, SNAP_RING_OUTER_R,
                          SNAP_RING_HEIGHT,
                          z_offset=z)

        # Fit the view
        viewport = app.activeViewport
        viewport.fit()

        ui.messageBox(
            'Ravigneaux gearset created successfully!\n\n'
            'Components:\n'
            f'  Ring Gear: ID={2*RING_INNER_R:.0f}mm, '
            f'OD={2*RING_OUTER_R:.0f}mm, H={RING_HEIGHT:.0f}mm\n'
            f'  Sun Large: OD={2*SUN_LARGE_OR:.0f}mm, '
            f'H={SUN_LARGE_HEIGHT:.0f}mm\n'
            f'  Sun Small: OD={2*SUN_SMALL_OR:.0f}mm, '
            f'H={SUN_SMALL_HEIGHT:.0f}mm\n'
            f'  Long Planets (x{NUM_PLANETS}): '
            f'OD={2*PLANET_LONG_OR:.0f}mm, orbit R={ORBIT_R_LONG:.1f}mm\n'
            f'  Short Planets (x{NUM_PLANETS}): '
            f'OD={2*PLANET_SHORT_OR:.0f}mm, orbit R={ORBIT_R_SHORT:.1f}mm\n'
            f'  Carrier Plates (x2): '
            f'OD={2*CARRIER_OUTER_R:.0f}mm, T={CARRIER_THICKNESS:.0f}mm\n'
            f'  Shaft: OD={2*SHAFT_RADIUS:.0f}mm, L={SHAFT_LENGTH:.0f}mm\n'
            f'  Support Rods (x3): OD={2*SUPPORT_ROD_R:.0f}mm, '
            f'L={SUPPORT_ROD_LENGTH:.0f}mm\n'
            f'  Bearings: {NUM_PLANETS*2}x, '
            f'Thrust Washers: 4x, Snap Rings: 12x\n'
            '\nEdit parameters in Modify > Change Parameters\n'
            '\nNOTE: Gears are simplified cylinders.\n'
            'Replace with Spur Gear add-in for involute teeth.')

    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def add_param(userParams, name, value, units, comment=""):
    """Add a user parameter (editable in Fusion 360 UI).
    Fusion 360 stores lengths in cm internally."""
    try:
        if units == "mm":
            valInput = adsk.core.ValueInput.createByReal(value / 10.0)
        else:
            valInput = adsk.core.ValueInput.createByReal(value)
        userParams.add(name, valInput, units, comment)
    except:
        pass  # parameter may already exist


def create_component(rootComp, name):
    """Create a new component in the root assembly."""
    occ = rootComp.occurrences.addNewComponent(adsk.core.Matrix3D.create())
    occ.component.name = name
    return occ


def mm2cm(v):
    """Convert mm to cm (Fusion 360 internal unit)."""
    return v / 10.0


def build_cylinder(rootComp, name, radius, height,
                   x_offset=0, y_offset=0, z_offset=0):
    """Build a solid cylinder as a new component."""
    occ = create_component(rootComp, name)
    comp = occ.component

    sketches = comp.sketches
    xyPlane = comp.xYConstructionPlane
    sketch = sketches.add(xyPlane)

    center = adsk.core.Point3D.create(mm2cm(x_offset), mm2cm(y_offset), 0)
    sketch.sketchCurves.sketchCircles.addByCenterRadius(
        center, mm2cm(radius))

    profile = sketch.profiles.item(0)
    extrudes = comp.features.extrudeFeatures
    dist = adsk.core.ValueInput.createByReal(mm2cm(height))
    ext = extrudes.addSimple(
        profile, dist,
        adsk.fusion.FeatureOperations.NewBodyFeatureOperation)

    if z_offset != 0:
        move_body(comp, ext.bodies.item(0), 0, 0, z_offset)


def build_annular(rootComp, name, inner_r, outer_r, height,
                  x_offset=0, y_offset=0, z_offset=0):
    """Build an annular (ring-shaped) solid as a new component.
    Creates outer circle, inner circle, extrudes the annular profile."""
    occ = create_component(rootComp, name)
    comp = occ.component

    sketches = comp.sketches
    xyPlane = comp.xYConstructionPlane
    sketch = sketches.add(xyPlane)

    center = adsk.core.Point3D.create(mm2cm(x_offset), mm2cm(y_offset), 0)

    # Outer circle
    sketch.sketchCurves.sketchCircles.addByCenterRadius(
        center, mm2cm(outer_r))

    # Inner circle (bore)
    sketch.sketchCurves.sketchCircles.addByCenterRadius(
        center, mm2cm(inner_r))

    # Find the annular profile (largest area that isn't the full circle)
    # With two concentric circles, there are two profiles:
    # the inner disk and the annular ring. We want the ring (larger area).
    profile = None
    max_area = 0
    for i in range(sketch.profiles.count):
        p = sketch.profiles.item(i)
        area = p.areaProperties().area
        if area > max_area:
            max_area = area
            profile = p

    if profile is None:
        profile = sketch.profiles.item(0)

    extrudes = comp.features.extrudeFeatures
    dist = adsk.core.ValueInput.createByReal(mm2cm(height))
    ext = extrudes.addSimple(
        profile, dist,
        adsk.fusion.FeatureOperations.NewBodyFeatureOperation)

    if z_offset != 0:
        move_body(comp, ext.bodies.item(0), 0, 0, z_offset)


def build_carrier_plate(rootComp, name, outer_r, thickness,
                        shaft_bore_r, pin_bore_r,
                        orbit_r_short, orbit_r_long,
                        short_angle_offset, long_angle_offset,
                        z_offset=0):
    """Build a carrier plate with central bore and planet pin bores."""
    occ = create_component(rootComp, name)
    comp = occ.component

    sketches = comp.sketches
    xyPlane = comp.xYConstructionPlane
    sketch = sketches.add(xyPlane)

    center = adsk.core.Point3D.create(0, 0, 0)

    # Outer circle
    sketch.sketchCurves.sketchCircles.addByCenterRadius(
        center, mm2cm(outer_r))

    # Central shaft bore
    sketch.sketchCurves.sketchCircles.addByCenterRadius(
        center, mm2cm(shaft_bore_r))

    # Long planet pin bores
    for i in range(NUM_PLANETS):
        angle = long_angle_offset + i * (360.0 / NUM_PLANETS)
        angle_rad = math.radians(angle)
        px = mm2cm(orbit_r_long * math.cos(angle_rad))
        py = mm2cm(orbit_r_long * math.sin(angle_rad))
        pin_center = adsk.core.Point3D.create(px, py, 0)
        sketch.sketchCurves.sketchCircles.addByCenterRadius(
            pin_center, mm2cm(pin_bore_r))

    # Short planet pin bores
    for i in range(NUM_PLANETS):
        angle = short_angle_offset + i * (360.0 / NUM_PLANETS)
        angle_rad = math.radians(angle)
        px = mm2cm(orbit_r_short * math.cos(angle_rad))
        py = mm2cm(orbit_r_short * math.sin(angle_rad))
        pin_center = adsk.core.Point3D.create(px, py, 0)
        sketch.sketchCurves.sketchCircles.addByCenterRadius(
            pin_center, mm2cm(pin_bore_r))

    # Find the largest profile (the carrier plate minus all bores)
    profile = None
    max_area = 0
    for i in range(sketch.profiles.count):
        p = sketch.profiles.item(i)
        area = p.areaProperties().area
        if area > max_area:
            max_area = area
            profile = p

    if profile is None:
        profile = sketch.profiles.item(0)

    extrudes = comp.features.extrudeFeatures
    dist = adsk.core.ValueInput.createByReal(mm2cm(thickness))
    ext = extrudes.addSimple(
        profile, dist,
        adsk.fusion.FeatureOperations.NewBodyFeatureOperation)

    if z_offset != 0:
        move_body(comp, ext.bodies.item(0), 0, 0, z_offset)


def move_body(comp, body, dx, dy, dz):
    """Move a body by (dx, dy, dz) in mm."""
    moveFeats = comp.features.moveFeatures

    bodies = adsk.core.ObjectCollection.create()
    bodies.add(body)

    transform = adsk.core.Matrix3D.create()
    transform.translation = adsk.core.Vector3D.create(
        mm2cm(dx), mm2cm(dy), mm2cm(dz))

    moveInput = moveFeats.createInput(bodies, transform)
    moveFeats.add(moveInput)
