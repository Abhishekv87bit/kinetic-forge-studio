"""
MATRIX TIER V5.6 — Production CadQuery Model
==============================================
Translated from matrix_tier_v5_6.scad + config_v5_5.scad

Components modeled:
  1. Housing body — 8 walls (2 boundary + 6 shared) with rails, end stops,
     hex-clipped to HEX_R boundary, post notches cut
  2. Fixed pulley axles — integral steel pins bridging walls
  3. Fixed pulley wheels — captive nylon rollers on axles
  4. Slider assemblies — top/bottom plates with rail grooves, string pins,
     captive pulleys (one per channel, 7 total)

Coordinate system (tier-local, same as OpenSCAD):
  X = slider travel axis
  Y = housing depth (perpendicular to slider face)
  Z = channel stacking axis

All dimensions in millimeters.
"""

import cadquery as cq
import math
import os

# ============================================================
# CONFIG — from config_v5_5.scad (single source of truth)
# ============================================================

# Hex geometry
HEX_R = 43.0
HEX_FF = HEX_R * math.sqrt(3)  # ~74.48 flat-to-flat

# Column spacing
COL_PITCH = 6.0
WALL_MARGIN = 4.0

# Channel stacking
STACK_OFFSET = 10.0
WALL_THICKNESS = 1.5
CH_GAP = STACK_OFFSET - WALL_THICKNESS  # 8.5
HOUSING_HEIGHT = 16.0  # 2*FP_ROW_Y + FP_OD + 1

# Pulleys
FP_OD = 4.0
SP_OD = 4.0
MIN_ROPE_GAP = 1.5
FP_ROW_Y = (FP_OD + SP_OD) / 2 + MIN_ROPE_GAP  # 5.5

# Stagger
STAGGER_HALF_PITCH = COL_PITCH / 2  # 3.0

# Mechanics
ECCENTRICITY = 4.8
SLIDER_BIAS = 0.80
SLIDER_REST_OFFSET = ECCENTRICITY * SLIDER_BIAS  # 3.84

# Frame posts
POST_DIA = 2.5
POST_NOTCH_R = 47.5  # centered in ring wall
FRAME_POST_ANGLES = [0, 120, 240]

# Hex clip
HEX_CLIP_INSET = 0.5

# ============================================================
# MATRIX TIER SPECIFIC — from matrix_tier_v5_6.scad
# ============================================================
PIP_CLEARANCE = 0.3
PIP_Z_GAP = 0.35
PIP_PULLEY_GAP = 0.4
RAIL_HEIGHT = 2.0
RAIL_DEPTH = 0.8
RAIL_TOLERANCE = 0.4
S_GAP = 3.0
END_STOP_W = 2.5
FP_WIDTH = CH_GAP - 0.6           # 7.9 — fixed pulley wheel width
FP_AXLE_DIA = 1.5
SP_PIN_DIA = 1.5
SP_AXLE_DIA = SP_PIN_DIA
SP_WIDTH = S_GAP - 2 * PIP_PULLEY_GAP  # 2.2
SLIDER_PLATE_Y = SP_OD + 1        # 5.0
WALL_MARGIN_AXLE = 2
SLIDER_MARGIN_HELIX = SP_OD / 2 + END_STOP_W + 0.5  # 5.0
SLIDER_MARGIN_ARM = SP_OD / 2 + 0.5                  # 2.5
BUG2_STRIP_OFFSET = (SLIDER_MARGIN_HELIX - SLIDER_MARGIN_ARM) / 2  # 1.25

# Derived Z-stack
_plate_t = (CH_GAP / 2) - (S_GAP / 2) - PIP_Z_GAP   # 2.40
_slot_d = PIP_Z_GAP + RAIL_DEPTH + 0.5                # 1.65

# DESIGN FIX V2: End stop retention via slot-depth engagement.
#
# The slider at rest extends PAST the end stop X positions (slider is longer
# than the wall). So the end stop must fit INSIDE the slot groove without
# colliding with the plate. Retention comes from the end stop nearly filling
# the slot depth — the slot can't easily pass over the bump.
#
# Constraints:
#   Y: END_STOP_Y < slot_h (2.8mm) — must fit inside slot groove
#   Z: protrusion < PIP_Z_GAP + _slot_d (2.0mm) — must stay inside slot depth
#
# Old design: Y=2.0, protrusion=1.15 → only 57% of slot depth. No retention.
# Fix: protrusion = PIP_Z_GAP + _slot_d - 0.2 = 1.8mm → 90% of slot depth.
#      Y = RAIL_HEIGHT = 2.0mm → fits inside 2.8mm slot with 0.4mm clearance/side.
END_STOP_Y = RAIL_HEIGHT    # 2.0mm — fits inside slot groove (2.8mm)
_slot_depth_from_wall = PIP_Z_GAP + _slot_d           # 2.0mm
_end_stop_protrusion = _slot_depth_from_wall - 0.2     # 1.8mm — 90% of slot depth

SP_AXLE_LEN = S_GAP - 2 * PIP_PULLEY_GAP             # 2.2
FP_AXLE_LEN = CH_GAP - 0.4                            # 8.1


# ============================================================
# CHANNEL LAYOUT FUNCTIONS
# ============================================================
def hex_w(d):
    """Width of hex cross-section at depth d from center."""
    max_d = HEX_FF / 2
    if abs(d) > max_d:
        return 0
    return 2 * (HEX_R - abs(d) / math.sqrt(3))


def ch_len(d):
    """Usable channel length at depth d."""
    return max(0, hex_w(d) - 2 * WALL_MARGIN)


def col_x_base(count, idx):
    """Base X position for column idx in a row of count columns."""
    return -((count - 1) / 2) * COL_PITCH + idx * COL_PITCH


def ch_stagger(ch_idx):
    """Stagger offset for channel ch_idx (alternating half-pitch)."""
    return (ch_idx % 2) * STAGGER_HALF_PITCH


def col_x(count, idx, ch_idx=0):
    """X position for column idx in channel ch_idx."""
    return col_x_base(count, idx) + ch_stagger(ch_idx)


def col_inside_hex(px, d):
    """Check if column at X=px fits inside hex at depth d."""
    max_od = max(FP_OD, SP_OD)
    return (abs(px) + max_od / 2 + 1) < (hex_w(d) / 2)


def raw_col_count(length):
    """Raw number of columns that fit in a channel of given length."""
    if length < COL_PITCH:
        return 1 if length > max(FP_OD, SP_OD) else 0
    return int(math.floor(length / COL_PITCH)) + 1


# ============================================================
# COMPUTE CHANNEL DATA
# ============================================================
NUM_CHANNELS = 7
CENTER_CH = (NUM_CHANNELS - 1) / 2  # 3.0
CH_OFFSETS = [(i - CENTER_CH) * STACK_OFFSET for i in range(NUM_CHANNELS)]
# [-30, -20, -10, 0, 10, 20, 30]

CH_LENS = [ch_len(CH_OFFSETS[i]) for i in range(NUM_CHANNELS)]


def culled_columns(ch_idx):
    """Return list of valid column X positions for channel ch_idx."""
    d = CH_OFFSETS[ch_idx]
    length = CH_LENS[ch_idx]
    raw = raw_col_count(length)
    if length <= 0:
        return []
    cols = []
    for j in range(raw):
        px = col_x(raw, j, ch_idx)
        if col_inside_hex(px, d):
            cols.append(px)
    return cols


def culled_span(ch_idx):
    """Span needed to enclose all columns plus axle margin."""
    cols = culled_columns(ch_idx)
    if not cols:
        return 0
    max_abs = max(abs(c) for c in cols)
    return 2 * (max_abs + FP_OD / 2 + WALL_MARGIN_AXLE)


COL_DATA = [culled_columns(i) for i in range(NUM_CHANNELS)]
COL_COUNTS = [len(c) for c in COL_DATA]
CH_WALL_LENS = [max(CH_LENS[i], culled_span(i)) for i in range(NUM_CHANNELS)]


def col_bounds(ch_idx):
    """Min/max X of valid columns."""
    cols = COL_DATA[ch_idx]
    if not cols:
        return (0, 0)
    return (min(cols), max(cols))


CH_S_LEFT = []
CH_S_RIGHT = []
for _i in range(NUM_CHANNELS):
    if COL_COUNTS[_i] > 0:
        _bounds = col_bounds(_i)
        _sl = _bounds[0] + BUG2_STRIP_OFFSET - SP_OD / 2 - SLIDER_MARGIN_ARM
        _sr = _bounds[1] + BUG2_STRIP_OFFSET + SP_OD / 2 + SLIDER_MARGIN_ARM
    else:
        _sl = 0
        _sr = 0
    CH_S_LEFT.append(_sl)
    CH_S_RIGHT.append(_sr)
CH_S_LENS = [CH_S_RIGHT[i] - CH_S_LEFT[i] for i in range(NUM_CHANNELS)]

# Print channel layout summary
print("=== MATRIX TIER V5.6 — CadQuery Production Model ===")
print(f"NUM_CHANNELS={NUM_CHANNELS} | STACK_OFFSET={STACK_OFFSET} | CH_GAP={CH_GAP}")
print(f"HOUSING_HEIGHT={HOUSING_HEIGHT} | WALL_THICKNESS={WALL_THICKNESS}")
for i in range(NUM_CHANNELS):
    print(f"  ch{i}: offset={CH_OFFSETS[i]:+.0f} cols={COL_COUNTS[i]} "
          f"wall_len={CH_WALL_LENS[i]:.1f} slider_len={CH_S_LENS[i]:.1f}")


# ============================================================
# HOUSING BODY — walls + rails + end stops
# ============================================================
def make_box_at(lx, ly, lz, cx, cy, cz):
    """Create a box of size (lx, ly, lz) centered at (cx, cy, cz)."""
    return cq.Workplane("XY").box(lx, ly, lz).translate((cx, cy, cz))


def make_boundary_wall(length, z_base, rail_dir):
    """
    Boundary wall: plate + rail on one side + 2 end stops.
    z_base = Z of wall bottom face.
    rail_dir = +1 (rail above) or -1 (rail below).
    """
    parts = []

    # Main wall plate
    plate_cz = z_base + WALL_THICKNESS / 2
    parts.append(make_box_at(length, HOUSING_HEIGHT, WALL_THICKNESS, 0, 0, plate_cz))

    if rail_dir > 0:
        # Rail on top
        rail_cz = z_base + WALL_THICKNESS + RAIL_DEPTH / 2
        parts.append(make_box_at(length, RAIL_HEIGHT, RAIL_DEPTH, 0, 0, rail_cz))
        # End stops — full plate height for slider retention
        es_cz = z_base + WALL_THICKNESS + _end_stop_protrusion / 2
        parts.append(make_box_at(END_STOP_W, END_STOP_Y, _end_stop_protrusion,
                                 -length / 2 + END_STOP_W / 2, 0, es_cz))
        parts.append(make_box_at(END_STOP_W, END_STOP_Y, _end_stop_protrusion,
                                 length / 2 - END_STOP_W / 2, 0, es_cz))
    else:
        # Rail on bottom
        rail_cz = z_base - RAIL_DEPTH / 2
        parts.append(make_box_at(length, RAIL_HEIGHT, RAIL_DEPTH, 0, 0, rail_cz))
        # End stops — full plate height for slider retention
        es_cz = z_base - _end_stop_protrusion / 2
        parts.append(make_box_at(END_STOP_W, END_STOP_Y, _end_stop_protrusion,
                                 -length / 2 + END_STOP_W / 2, 0, es_cz))
        parts.append(make_box_at(END_STOP_W, END_STOP_Y, _end_stop_protrusion,
                                 length / 2 - END_STOP_W / 2, 0, es_cz))
    return parts


def make_shared_wall(wall_len, z_base):
    """
    Shared (interior) wall: plate + rails on both sides + 4 end stops.
    z_base = Z of wall bottom face.
    """
    parts = []

    # Main plate
    plate_cz = z_base + WALL_THICKNESS / 2
    parts.append(make_box_at(wall_len, HOUSING_HEIGHT, WALL_THICKNESS, 0, 0, plate_cz))

    # Rail below (-Z side)
    rail_below_cz = z_base - RAIL_DEPTH / 2
    parts.append(make_box_at(wall_len, RAIL_HEIGHT, RAIL_DEPTH, 0, 0, rail_below_cz))
    es_below_cz = z_base - _end_stop_protrusion / 2
    parts.append(make_box_at(END_STOP_W, END_STOP_Y, _end_stop_protrusion,
                             -wall_len / 2 + END_STOP_W / 2, 0, es_below_cz))
    parts.append(make_box_at(END_STOP_W, END_STOP_Y, _end_stop_protrusion,
                             wall_len / 2 - END_STOP_W / 2, 0, es_below_cz))

    # Rail above (+Z side)
    rail_above_cz = z_base + WALL_THICKNESS + RAIL_DEPTH / 2
    parts.append(make_box_at(wall_len, RAIL_HEIGHT, RAIL_DEPTH, 0, 0, rail_above_cz))
    es_above_cz = z_base + WALL_THICKNESS + _end_stop_protrusion / 2
    parts.append(make_box_at(END_STOP_W, END_STOP_Y, _end_stop_protrusion,
                             -wall_len / 2 + END_STOP_W / 2, 0, es_above_cz))
    parts.append(make_box_at(END_STOP_W, END_STOP_Y, _end_stop_protrusion,
                             wall_len / 2 - END_STOP_W / 2, 0, es_above_cz))

    return parts


def build_housing():
    """Build the complete housing: all walls, hex-clipped, post-notched."""
    print("Building housing walls...")
    all_parts = []

    # Bottom boundary wall (channel 0)
    z_bottom = CH_OFFSETS[0] - CH_GAP / 2 - WALL_THICKNESS
    all_parts.extend(make_boundary_wall(CH_WALL_LENS[0], z_bottom, rail_dir=+1))

    # Shared walls between channels
    for i in range(NUM_CHANNELS - 1):
        z_shared = CH_OFFSETS[i] + CH_GAP / 2
        wl = max(CH_WALL_LENS[i], CH_WALL_LENS[i + 1])
        all_parts.extend(make_shared_wall(wl, z_shared))

    # Top boundary wall (last channel)
    z_top = CH_OFFSETS[-1] + CH_GAP / 2
    all_parts.extend(make_boundary_wall(CH_WALL_LENS[-1], z_top, rail_dir=-1))

    # Union all wall parts
    print(f"  Unioning {len(all_parts)} wall segments...")
    housing = all_parts[0]
    for p in all_parts[1:]:
        housing = housing.union(p)

    # Fixed pulley axles — integral pins bridging channel gaps
    # PRODUCTION FIX: extend axles 0.5mm into walls for proper body fusion.
    # OpenSCAD used CH_GAP-0.4=8.1mm (PIP gap needed). For STEP production,
    # axles are integral structure — they MUST overlap wall material.
    print("  Adding fixed pulley axles...")
    axle_penetration = 0.5  # mm into each wall
    axle_len_prod = CH_GAP + 2 * axle_penetration  # 9.5mm
    for ch_i in range(NUM_CHANNELS):
        if COL_COUNTS[ch_i] == 0:
            continue
        ch_z = CH_OFFSETS[ch_i]
        for px in COL_DATA[ch_i]:
            for y_sign in [+1, -1]:
                py = y_sign * FP_ROW_Y
                # Axle cylinder along Z, centered at (px, py, ch_z)
                axle = (
                    cq.Workplane("XY")
                    .transformed(offset=(px, py, ch_z - axle_len_prod / 2))
                    .circle(FP_AXLE_DIA / 2)
                    .extrude(axle_len_prod)
                )
                housing = housing.union(axle)

    # Hex clip — intersect with hexagonal prism along Y axis
    print("  Applying hex clip...")
    hex_r = HEX_R - HEX_CLIP_INSET  # 42.5
    total_z = (NUM_CHANNELS + 2) * STACK_OFFSET  # 90
    # Hex prism in XZ plane, extruded along Y
    hex_h = HOUSING_HEIGHT + 10
    hex_prism = (
        cq.Workplane("XZ")
        .polygon(6, 2 * hex_r)
        .extrude(hex_h)
        .translate((0, -hex_h / 2, 0))
    )
    housing = housing.intersect(hex_prism)

    # Post notches — cylindrical cuts at frame post positions
    print("  Cutting post notches...")
    for angle_deg in FRAME_POST_ANGLES:
        a_rad = math.radians(angle_deg)
        px = POST_NOTCH_R * math.cos(a_rad)
        pz = POST_NOTCH_R * math.sin(a_rad)
        notch_r = (POST_DIA + 0.3) / 2
        notch_h = HOUSING_HEIGHT + 4
        notch = (
            cq.Workplane("XZ")
            .transformed(offset=(px, pz, 0))
            .circle(notch_r)
            .extrude(notch_h)
            .translate((0, -notch_h / 2, 0))
        )
        housing = housing.cut(notch)

    print("  Housing complete.")
    return housing


# ============================================================
# FIXED PULLEY WHEEL — captive nylon roller
# ============================================================
def make_fixed_pulley():
    """
    One fixed pulley wheel: annular ring with bore for axle.
    OD = FP_OD (4mm), width = FP_WIDTH (7.9mm), bore = axle + clearance.
    """
    bore_d = FP_AXLE_DIA + PIP_CLEARANCE * 2  # 2.1mm
    wheel = (
        cq.Workplane("XY")
        .circle(FP_OD / 2)
        .circle(bore_d / 2)
        .extrude(FP_WIDTH)
        .translate((0, 0, -FP_WIDTH / 2))
    )
    return wheel


# ============================================================
# SLIDER PULLEY — captive on string pin
# ============================================================
def make_slider_pulley():
    """
    Slider pulley: small wheel + its axle pin.
    Axle: SP_AXLE_DIA (1.5mm), length SP_AXLE_LEN (2.2mm)
    Wheel: SP_OD (4mm), width SP_WIDTH (2.2mm), bore = axle + clearance
    """
    bore_d = SP_AXLE_DIA + PIP_CLEARANCE * 2  # 2.1mm
    # Axle (steel pin)
    axle = (
        cq.Workplane("XY")
        .circle(SP_AXLE_DIA / 2)
        .extrude(SP_AXLE_LEN)
        .translate((0, 0, -SP_AXLE_LEN / 2))
    )
    # Wheel (nylon)
    wheel = (
        cq.Workplane("XY")
        .circle(SP_OD / 2)
        .circle(bore_d / 2)
        .extrude(SP_WIDTH)
        .translate((0, 0, -SP_WIDTH / 2))
    )
    return axle, wheel


# ============================================================
# SLIDER ASSEMBLY — plates + rail grooves + string pins
# ============================================================
def make_slider_assembly(ch_idx, displacement=0):
    """
    Complete slider for one channel: two plates (top/bottom) with rail
    grooves, string pins spanning between plates.

    ch_idx: channel index (0-6)
    displacement: slider X displacement (animation, default 0)
    """
    if COL_COUNTS[ch_idx] == 0:
        return None

    s_len = CH_S_LENS[ch_idx]
    s_left = CH_S_LEFT[ch_idx]

    if s_len <= 0:
        return None

    slot_h = RAIL_HEIGHT + RAIL_TOLERANCE * 2
    half_y = SLIDER_PLATE_Y / 2

    parts = []

    # --- Bottom plate ---
    # Full plate
    bot_z = -(S_GAP / 2 + _plate_t)
    bot_plate = make_box_at(s_len, SLIDER_PLATE_Y, _plate_t,
                            s_left + s_len / 2, 0, bot_z + _plate_t / 2)
    # Rail groove cutout
    bot_groove = make_box_at(s_len + 2, slot_h, _slot_d + 0.1,
                             s_left + s_len / 2, 0, bot_z + (_slot_d + 0.1) / 2 - 0.05)
    bot_plate = bot_plate.cut(bot_groove)
    parts.append(bot_plate)

    # --- Top plate ---
    top_z = S_GAP / 2
    top_plate = make_box_at(s_len, SLIDER_PLATE_Y, _plate_t,
                            s_left + s_len / 2, 0, top_z + _plate_t / 2)
    # Rail groove cutout
    top_groove = make_box_at(s_len + 2, slot_h, _slot_d + 0.1,
                             s_left + s_len / 2, 0,
                             top_z + _plate_t - (_slot_d + 0.1) / 2 + 0.05)
    top_plate = top_plate.cut(top_groove)
    parts.append(top_plate)

    # --- String pins — span between plates through the S_GAP ---
    raw_n = raw_col_count(CH_LENS[ch_idx])
    d = CH_OFFSETS[ch_idx]
    sp_min_x = s_left + SP_OD / 2
    sp_max_x = s_left + s_len - SP_OD / 2

    for j in range(raw_n):
        px = col_x(raw_n, j, ch_idx)
        pin_x = px + BUG2_STRIP_OFFSET
        if col_inside_hex(px, d) and sp_min_x <= pin_x <= sp_max_x:
            pin = (
                cq.Workplane("XY")
                .transformed(offset=(pin_x, 0, -S_GAP / 2))
                .circle(SP_PIN_DIA / 2)
                .extrude(S_GAP)
            )
            parts.append(pin)

    # Union all slider parts
    slider = parts[0]
    for p in parts[1:]:
        slider = slider.union(p)

    # Apply displacement offset
    slider = slider.translate((displacement + SLIDER_REST_OFFSET, 0, 0))

    return slider


# ============================================================
# FULL TIER ASSEMBLY
# ============================================================
def build_tier_assembly():
    """Build the complete matrix tier as a CadQuery Assembly."""
    assy = cq.Assembly()

    # 1. Housing body
    housing = build_housing()
    assy.add(housing, name="housing",
             color=cq.Color(0.6, 0.6, 1.0, 0.9))

    # 2. Fixed pulley wheels (at each column position, ± FP_ROW_Y)
    print("Adding fixed pulley wheels...")
    fp_wheel = make_fixed_pulley()
    fp_count = 0
    for ch_i in range(NUM_CHANNELS):
        if COL_COUNTS[ch_i] == 0:
            continue
        ch_z = CH_OFFSETS[ch_i]
        for col_j, px in enumerate(COL_DATA[ch_i]):
            for y_sign, y_label in [(+1, "pos"), (-1, "neg")]:
                py = y_sign * FP_ROW_Y
                # Wheel oriented along Z, centered at (px, py, ch_z)
                loc = cq.Location(cq.Vector(px, py, ch_z))
                assy.add(fp_wheel, name=f"fp_{ch_i}_{col_j}_{y_label}",
                         loc=loc,
                         color=cq.Color(0.95, 0.95, 0.92, 1.0))
                fp_count += 1
    print(f"  {fp_count} fixed pulley wheels placed.")

    # 3. Slider assemblies (one per channel)
    print("Building slider assemblies...")
    slider_count = 0
    for ch_i in range(NUM_CHANNELS):
        slider = make_slider_assembly(ch_i, displacement=0)
        if slider is not None:
            ch_z = CH_OFFSETS[ch_i]
            loc = cq.Location(cq.Vector(0, 0, ch_z))
            assy.add(slider, name=f"slider_{ch_i}",
                     loc=loc,
                     color=cq.Color(0.9, 0.4, 0.4, 1.0))
            slider_count += 1
    print(f"  {slider_count} slider assemblies built.")

    # 4. Slider pulleys (at each column position on each slider)
    print("Adding slider pulleys...")
    sp_axle, sp_wheel = make_slider_pulley()
    sp_count = 0
    for ch_i in range(NUM_CHANNELS):
        if COL_COUNTS[ch_i] == 0:
            continue
        ch_z = CH_OFFSETS[ch_i]
        raw_n = raw_col_count(CH_LENS[ch_i])
        d = CH_OFFSETS[ch_i]
        s_left = CH_S_LEFT[ch_i]
        s_len = CH_S_LENS[ch_i]
        sp_min_x = s_left + SP_OD / 2
        sp_max_x = s_left + s_len - SP_OD / 2

        for j in range(raw_n):
            px = col_x(raw_n, j, ch_i)
            pin_x = px + BUG2_STRIP_OFFSET
            if col_inside_hex(px, d) and sp_min_x <= pin_x <= sp_max_x:
                # Position: add slider rest offset to X
                sx = pin_x + SLIDER_REST_OFFSET
                loc = cq.Location(cq.Vector(sx, 0, ch_z))
                assy.add(sp_wheel, name=f"sp_{ch_i}_{j}",
                         loc=loc,
                         color=cq.Color(0.95, 0.95, 0.92, 1.0))
                sp_count += 1
    print(f"  {sp_count} slider pulleys placed.")

    return assy


# ============================================================
# EXPORT
# ============================================================
def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))

    # Build individual housing for standalone STEP
    print("\n--- Building housing standalone ---")
    housing = build_housing()
    housing_step = os.path.join(out_dir, "matrix_tier_housing.step")
    housing_stl = os.path.join(out_dir, "matrix_tier_housing.stl")
    cq.exporters.export(housing, housing_step)
    cq.exporters.export(housing, housing_stl)
    print(f"  Exported: {housing_step}")
    print(f"  Exported: {housing_stl}")

    # Build full assembly
    print("\n--- Building full tier assembly ---")
    assy = build_tier_assembly()
    assy_step = os.path.join(out_dir, "matrix_tier_assembly.step")
    assy.save(assy_step)
    print(f"  Exported: {assy_step}")

    # Export ALL sliders individually (positioned at their channel Z)
    print("\n--- Building all slider standalones ---")
    for ch_i in range(NUM_CHANNELS):
        slider = make_slider_assembly(ch_i, displacement=0)
        if slider:
            ch_z = CH_OFFSETS[ch_i]
            positioned = slider.translate((0, 0, ch_z))
            slider_step = os.path.join(out_dir, f"slider_ch{ch_i}.step")
            cq.exporters.export(positioned, slider_step)
            print(f"  Exported: {slider_step}")

    # Export one fixed pulley for inspection
    print("\n--- Building fixed pulley standalone ---")
    fp = make_fixed_pulley()
    fp_step = os.path.join(out_dir, "fixed_pulley.step")
    cq.exporters.export(fp, fp_step)
    print(f"  Exported: {fp_step}")

    print("\n=== ALL EXPORTS COMPLETE ===")


# ============================================================
# UNIVERSAL VALIDATION INTERFACE
# (Required by VLAD — see docs/plans/2026-03-03-universal-validation-spec.md)
# ============================================================
def get_mechanism_type():
    """This is a slider mechanism — sliders translate along X axis."""
    return 'slider'


def get_fixed_parts():
    """Return all fixed geometry: housing + fixed pulley wheels at their positions."""
    parts = {}

    # Housing is one fixed body
    housing = build_housing()
    parts['housing'] = housing

    # Fixed pulley wheels at their actual positions
    fp_wheel = make_fixed_pulley()
    fp_idx = 0
    for ch_i in range(NUM_CHANNELS):
        if COL_COUNTS[ch_i] == 0:
            continue
        ch_z = CH_OFFSETS[ch_i]
        for px in COL_DATA[ch_i]:
            for y_sign in [+1, -1]:
                py = y_sign * FP_ROW_Y
                positioned = fp_wheel.translate((px, py, ch_z))
                parts[f'fp_{fp_idx}'] = positioned
                fp_idx += 1

    return parts


def get_moving_parts():
    """Return all moving geometry: sliders positioned at their channel Z.
    Each slider translates along X axis from -ECCENTRICITY to +ECCENTRICITY
    relative to its rest position (SLIDER_REST_OFFSET already applied in build)."""
    parts = {}

    # Travel range: slider is built at rest (SLIDER_REST_OFFSET applied internally).
    # The cam drives it from -ECCENTRICITY to +ECCENTRICITY relative to rest.
    # So additional displacement from rest = -ECCENTRICITY to +ECCENTRICITY.
    # But rest already includes SLIDER_REST_OFFSET, so total travel from origin:
    #   min = 0 (cam pushes back to zero)
    #   max = SLIDER_REST_OFFSET + ECCENTRICITY - SLIDER_REST_OFFSET = ECCENTRICITY
    # Actually: displacement param in make_slider_assembly adds to SLIDER_REST_OFFSET.
    # At rest: displacement=0 → position = SLIDER_REST_OFFSET
    # At min:  displacement = -(ECCENTRICITY * SLIDER_BIAS) → position = 0
    # At max:  displacement = ECCENTRICITY * (1 - SLIDER_BIAS) → position = ECCENTRICITY
    min_disp = -SLIDER_REST_OFFSET  # brings slider back to X=0
    max_disp = ECCENTRICITY - SLIDER_REST_OFFSET  # brings slider to X=ECCENTRICITY

    for ch_i in range(NUM_CHANNELS):
        slider = make_slider_assembly(ch_i, displacement=0)
        if slider is not None:
            ch_z = CH_OFFSETS[ch_i]
            positioned = slider.translate((0, 0, ch_z))
            parts[f'slider_ch{ch_i}'] = (positioned, 'x', min_disp, max_disp)

    return parts


if __name__ == "__main__":
    main()
