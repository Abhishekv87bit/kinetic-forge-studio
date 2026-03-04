#!/usr/bin/env python3
"""
Bill of Materials Generator — Triple Helix MVP V5.5b
=====================================================

Auto-extracts all purchased and printed parts from config_v5_5.scad,
computes derived quantities (shaft lengths, string runs, volumes),
and produces a complete shopping list + print list.

Usage:
    python bom_generator.py                 # Console table output
    python bom_generator.py --csv           # Write bom_v5_5.csv
    python bom_generator.py --json          # Write bom_v5_5.json
    python bom_generator.py --csv --json    # Both files

The script parses the OpenSCAD config file directly (regex extraction),
so it stays in sync as parameters change.
"""

import re
import sys
import json
import csv
import math
import os
from pathlib import Path
from datetime import datetime

# ---------------------------------------------------------------------------
# 1. CONFIG PARSER — extract constants from config_v5_5.scad
# ---------------------------------------------------------------------------

def parse_config(config_path: str) -> dict:
    """Parse named constants from an OpenSCAD config file.

    Handles patterns like:
        NAME = 42;
        NAME = 42.5;
        NAME = expr;   // only captures simple numeric RHS
        NAME = [a, b, c];  // array literals
    """
    params = {}
    with open(config_path, "r", encoding="utf-8") as f:
        text = f.read()

    # Simple numeric assignments:  NAME = 123.45;
    for m in re.finditer(
        r"^[ \t]*([A-Z_][A-Z0-9_]*)\s*=\s*(-?[\d.]+)\s*;",
        text,
        re.MULTILINE,
    ):
        name, val = m.group(1), m.group(2)
        params[name] = float(val) if "." in val else int(val)

    # Array assignments:  NAME = [a, b, c];
    for m in re.finditer(
        r"^[ \t]*([A-Z_][A-Z0-9_]*)\s*=\s*\[([^\]]+)\]\s*;",
        text,
        re.MULTILINE,
    ):
        name = m.group(1)
        elems = m.group(2).split(",")
        try:
            params[name] = [float(e.strip()) for e in elems if e.strip()]
        except ValueError:
            pass  # skip non-numeric arrays (e.g. color vectors with expressions)

    return params


# ---------------------------------------------------------------------------
# 2. DERIVED CALCULATIONS
# ---------------------------------------------------------------------------

def derive(p: dict) -> dict:
    """Compute every derived quantity needed for the BOM.

    p = parsed config parameters (dict of name -> value).
    Returns a new dict with all derived values added.
    """
    d = dict(p)  # shallow copy

    # --- Core geometry ---
    hex_r = d.get("HEX_R", 43)
    hex_ff = hex_r * math.sqrt(3)
    hex_c2c = 2 * hex_r
    d["HEX_FF"] = hex_ff
    d["HEX_C2C"] = hex_c2c

    # --- Channel stacking ---
    stack_offset = d.get("STACK_OFFSET", 8.0)
    half_count = int((hex_ff / 2 - stack_offset / 2) / stack_offset)
    num_channels = 2 * half_count + 1
    d["NUM_CHANNELS"] = num_channels
    d["_half_count"] = half_count

    center_ch = (num_channels - 1) / 2
    ch_offsets = [(i - center_ch) * stack_offset for i in range(num_channels)]
    d["CH_OFFSETS"] = ch_offsets

    # hex_w(d_val)
    def hex_w(d_val):
        max_d = hex_ff / 2
        if abs(d_val) > max_d:
            return 0.0
        return 2 * (hex_r - abs(d_val) / math.sqrt(3))

    wall_margin = d.get("WALL_MARGIN", 4)

    def ch_len(d_val):
        return max(0, hex_w(d_val) - 2 * wall_margin)

    ch_lens = [ch_len(o) for o in ch_offsets]
    d["CH_LENS"] = ch_lens

    # Column counts per channel
    col_pitch = d.get("COL_PITCH", 6)
    fp_od = d.get("FP_OD", 3.0)
    sp_od = d.get("SP_OD", 3.0)

    def raw_col_count(length):
        if length < col_pitch:
            return 1 if length > max(fp_od, sp_od) else 0
        return int(length / col_pitch) + 1

    def col_x_base(count, idx):
        return -((count - 1) / 2) * col_pitch + idx * col_pitch

    stagger_half = col_pitch / 2

    def ch_stagger(ch_idx):
        return (ch_idx % 2) * stagger_half

    def col_x(count, idx, ch_idx=0):
        return col_x_base(count, idx) + ch_stagger(ch_idx)

    def col_inside_hex(px, d_val):
        max_od = max(fp_od, sp_od)
        return (abs(px) + max_od / 2 + 1) < (hex_w(d_val) / 2)

    def culled_col_count(ch_idx):
        d_val = ch_offsets[ch_idx]
        length = ch_lens[ch_idx]
        raw = raw_col_count(length)
        if length <= 0:
            return 0
        valid = sum(
            1
            for j in range(raw)
            if col_inside_hex(col_x(raw, j, ch_idx), d_val)
        )
        return valid

    col_counts = [culled_col_count(i) for i in range(num_channels)]
    d["COL_COUNTS"] = col_counts
    total_columns = sum(col_counts)
    d["TOTAL_COLUMNS"] = total_columns

    # --- Cam / helix ---
    num_cams = num_channels  # 9
    d["NUM_CAMS"] = num_cams
    twist_per_cam = 360.0 / num_cams
    d["TWIST_PER_CAM"] = twist_per_cam

    axial_pitch = d.get("AXIAL_PITCH", 8.0)
    helix_length = num_cams * axial_pitch
    d["HELIX_LENGTH"] = helix_length

    disc_thick = d.get("CAM_BRG_W", 4.0) + 1  # DISC_THICK = CAM_BRG_W + 1
    d["DISC_THICK"] = disc_thick
    collar_thick = axial_pitch - disc_thick
    d["COLLAR_THICK"] = collar_thick

    shaft_dia = d.get("SHAFT_DIA", 4.0)
    shaft_boss_od = shaft_dia + 6  # 10mm
    d["SHAFT_BOSS_OD"] = shaft_boss_od

    cam_brg_id = d.get("CAM_BRG_ID", 20.0)
    disc_od = cam_brg_id - 0.4  # 19.6mm
    d["DISC_OD"] = disc_od

    eccentricity = d.get("ECCENTRICITY", 4.8)
    cam_ecc = disc_od / 2 - shaft_boss_od / 2
    d["CAM_ECC"] = cam_ecc

    # Follower ring dims
    cam_brg_od = d.get("CAM_BRG_OD", 27.0)
    follower_ring_od = cam_brg_od + 4  # 31mm
    follower_ring_id = cam_brg_od + 0.3
    follower_ring_h = d.get("FOLLOWER_RING_H", 3.0)
    d["FOLLOWER_RING_OD"] = follower_ring_od

    # --- Shaft length ---
    # From config: SHAFT_TOTAL_LENGTH is already computed there, but let's
    # re-derive to be safe.

    # We need SHAFT_EXT_TO_CARRIER which depends on frame geometry.
    # For simplicity, read it from the parsed constants if available,
    # otherwise approximate.
    star_ratio = d.get("_STAR_RATIO", 2.5)
    star_tip_r = star_ratio * hex_c2c  # 215mm
    d["STAR_TIP_R"] = star_tip_r

    # Approximate SHAFT_EXT_TO_CARRIER from the config's derivation chain.
    # The config does a complex iterative solve. We replicate key steps:
    ring_r_in = hex_r + 2  # 45mm
    ring_w = d.get("_RING_W_CFG", 5)
    stub_len = d.get("_CFG_STUB_LEN", 15)
    stub_w = d.get("_CFG_STUB_W", 10)
    corridor_gap = d.get("_CORRIDOR_GAP_CFG", 31.4)

    frame_ring_r_out = ring_r_in + ring_w  # 50mm
    stub_r_end = frame_ring_r_out + stub_len  # 65mm
    junction_r = stub_r_end + stub_w / 2  # 70mm
    hexagram_inner = star_tip_r / math.sqrt(3)
    v_push = corridor_gap / (2 * math.tan(math.radians(30)))
    helix_r = hexagram_inner + v_push
    d["HELIX_R"] = helix_r

    # _cfg_find_V — binary search for V_ANGLE
    def par_res(V, T, J):
        return (T * T * math.sin(math.radians(120 - V))
                - 2 * J * T * math.sin(math.radians(120 - V / 2))
                + J * J * math.sin(math.radians(120)))

    def find_V(T, J, lo=10, hi=150):
        for _ in range(100):
            mid = (lo + hi) / 2
            r = par_res(mid, T, J)
            if abs(r) < 0.0001:
                return mid
            if r > 0:
                lo = mid
            else:
                hi = mid
        return (lo + hi) / 2

    v_angle = find_V(star_tip_r, junction_r)
    d["V_ANGLE"] = v_angle

    # Replicate the crossing-distance calculation for helix 0 at angle 180
    stub_a = 120  # degrees  (STUB_ANGLES[1] for helix 0 pair arm 3)
    tip_a = stub_a + v_angle / 2
    jx = junction_r * math.cos(math.radians(stub_a))
    jy = junction_r * math.sin(math.radians(stub_a))
    tx = star_tip_r * math.cos(math.radians(tip_a))
    ty = star_tip_r * math.sin(math.radians(tip_a))
    adx = tx - jx
    ady = ty - jy
    alen = math.sqrt(adx * adx + ady * ady)
    # shaft dir for helix 0 (angle 180): [-sin(180), cos(180)] = [0, -1]
    helix_angle_0 = 180
    sdx = -math.sin(math.radians(helix_angle_0))
    sdy = math.cos(math.radians(helix_angle_0))
    hcx = helix_r * math.cos(math.radians(helix_angle_0))
    hcy = helix_r * math.sin(math.radians(helix_angle_0))
    cross = (adx / alen) * sdy - (ady / alen) * sdx
    djx = hcx - jx
    djy = hcy - jy
    t_mm = (djx * sdy - djy * sdx) / cross if abs(cross) > 0.001 else 0
    cx = jx + (adx / alen) * t_mm
    cy = jy + (ady / alen) * t_mm
    shaft_tangent_dist = abs((cx - hcx) * sdx + (cy - hcy) * sdy)
    shaft_ext_to_carrier = shaft_tangent_dist - helix_length / 2
    d["SHAFT_EXT_TO_CARRIER"] = shaft_ext_to_carrier

    carrier_plate_t = d.get("CARRIER_PLATE_T_CFG", 10)
    gt2_boss_h = d.get("GT2_BOSS_H", 5)
    shaft_ext_beyond_drive = carrier_plate_t / 2 + gt2_boss_h + 1  # 11
    shaft_ext_beyond_free = carrier_plate_t / 2 + 2  # 7
    shaft_total_length = (
        helix_length
        + shaft_ext_to_carrier * 2
        + shaft_ext_beyond_drive
        + shaft_ext_beyond_free
    )
    d["SHAFT_TOTAL_LENGTH"] = shaft_total_length

    # --- GT2 pulleys ---
    gt2_teeth = d.get("GT2_TEETH", 12)
    gt2_pd = gt2_teeth * 2 / math.pi
    gt2_od = gt2_pd + 1.5
    d["GT2_PD"] = gt2_pd
    d["GT2_OD"] = gt2_od

    # --- Belt path length (approximate) ---
    # 3 GT2 pulleys at helix positions + 2 idlers at stub positions + motor
    # Very rough: convex hull perimeter of 6 points on a circle of radius ~helix_r
    # Better approximation: sum of inter-pulley distances
    helix_angles = [180, 300, 60]
    gt2_positions = []
    for hi, ha in enumerate(helix_angles):
        hcx_i = helix_r * math.cos(math.radians(ha))
        hcy_i = helix_r * math.sin(math.radians(ha))
        sd_i = [-math.sin(math.radians(ha)), math.cos(math.radians(ha))]
        gt2_offset = helix_length / 2 + shaft_ext_to_carrier + carrier_plate_t / 2 + gt2_boss_h / 2
        # Drive side GT2 for each helix
        gx = hcx_i + sd_i[0] * gt2_offset
        gy = hcy_i + sd_i[1] * gt2_offset
        gt2_positions.append((gx, gy))

    # Idler positions at stubs 0 and 1
    stub_angles = [0, 120, 240]
    idler_offset_r = stub_w / 2 + gt2_od / 2 + 2
    idler_positions = []
    for si in [0, 1]:
        sa = stub_angles[si]
        ix = (junction_r + idler_offset_r) * math.cos(math.radians(sa))
        iy = (junction_r + idler_offset_r) * math.sin(math.radians(sa))
        idler_positions.append((ix, iy))

    # Approximate belt path: Motor -> H1(drive) -> I1 -> H3(drive) -> I2 -> H2(drive) -> Motor
    # Use distances between points in order: GT2[0], Idler[0], GT2[2], Idler[1], GT2[1], motor_pos
    # Motor near helix 2 drive end
    motor_helix = d.get("MOTOR_HELIX_IDX", 2)
    motor_pos = gt2_positions[motor_helix]  # approximate

    belt_points = [
        gt2_positions[0],
        idler_positions[0],
        gt2_positions[2],
        idler_positions[1],
        gt2_positions[1],
        motor_pos,
    ]
    belt_length = 0
    for i in range(len(belt_points)):
        ax, ay = belt_points[i]
        bx, by = belt_points[(i + 1) % len(belt_points)]
        belt_length += math.sqrt((bx - ax) ** 2 + (by - ay) ** 2)

    # Add wrap around each pulley (~half circumference per pulley)
    belt_length += 3 * math.pi * gt2_pd / 2  # 3 GT2s
    belt_length += 2 * math.pi * gt2_od / 2  # 2 idlers
    d["BELT_LENGTH_MM"] = belt_length

    # --- String / cable path length per string ---
    # Path: anchor plate hole -> down through tiers (U-detour at each fixed/slider pulley)
    #       -> guide plate -> block
    # Rough per-string length:
    #   anchor to tier 1 entry: ~ANCHOR_THICK + HOUSING_HEIGHT/2 = ~10mm
    #   per tier U-detour: 2 * FP_ROW_Y + SP_OD + some slack ~ 20mm
    #   3 tiers: 3 * 20 = 60mm
    #   inter-tier runs: 2 * TIER_PITCH = 26mm
    #   guide plate: GUIDE_THICK = 5mm
    #   block drop: _BLOCK_DROP = 36mm
    # Total per string ~ 137mm, round up for routing slack
    tier_pitch = d.get("HOUSING_HEIGHT", 13) + d.get("INTER_TIER_GAP", 0)
    fp_row_y = (fp_od + sp_od) / 2 + d.get("_MIN_ROPE_GAP", 1.5)
    anchor_thick = d.get("ANCHOR_THICK", 3.0)
    guide_thick = d.get("GUIDE_THICK", 5.0)
    block_drop = d.get("_BLOCK_DROP", 36)

    per_tier_detour = 2 * fp_row_y + sp_od + 5  # U-shape + routing
    inter_tier_run = tier_pitch
    string_per_path = (
        anchor_thick
        + 5  # entry slack
        + 3 * per_tier_detour
        + 2 * inter_tier_run
        + guide_thick
        + block_drop
        + 20  # knot + attachment slack
    )
    d["STRING_LENGTH_PER_PATH"] = string_per_path
    d["STRING_TOTAL_LENGTH"] = num_channels * string_per_path

    # --- Block dimensions ---
    block_gap = d.get("_BLOCK_GAP", 0.8)
    block_ff = col_pitch - block_gap  # 5.2mm
    block_h = d.get("_BLOCK_HEIGHT_CFG", 7)
    d["BLOCK_FF"] = block_ff
    d["BLOCK_H"] = block_h

    # --- Volume estimates for 3D-printed parts ---
    # All in mm^3, convert to cm^3 for print time and grams

    # 1. Frame monolith (very rough)
    #    Two hex rings + stubs + arms + carriers + dampeners + brackets
    ring_volume = (
        2 * (  # two rings
            math.pi * (frame_ring_r_out ** 2 - ring_r_in ** 2)
            * 6  # ring height (upper) ~ 6mm
        )
    )
    # Lower ring extended by guide_stack_h
    ring_volume += math.pi * (frame_ring_r_out ** 2 - ring_r_in ** 2) * guide_thick
    # Ledge
    ledge_r_in = ring_r_in - 3
    ring_volume += math.pi * (ring_r_in ** 2 - ledge_r_in ** 2) * 2  # ledge thick

    # 6 stubs (upper + lower)
    arm_w = 10
    arm_h = 7
    stub_volume = 6 * (stub_len * stub_w * arm_h)  # 6 stubs (3 upper + 3 lower)

    # 6 arms (upper + lower) — approximate as beams
    # Average arm length ~ star_tip_r - junction_r ~ 145mm
    arm_len_avg = star_tip_r - junction_r
    arm_volume = 12 * (arm_len_avg * arm_w * arm_h) * 0.7  # 70% fill factor for taper

    # Junction nodes (6 upper + 6 lower ~ approximate)
    junction_volume = 12 * (stub_w * stub_w * arm_h) * 1.5  # enlarged hulls

    # Carrier nodes (6 total, 2 per helix)
    carrier_node_vol = 6 * (carrier_plate_t * 20 * arm_h)  # rough

    # Dampener bars (3 bars + 6 vertical ties)
    damp_bar_w = d.get("DAMPENER_BAR_W", 5)
    damp_bar_h = d.get("DAMPENER_BAR_H", 7)
    # Bar length ~ corridor gap ~ 31mm
    damp_volume = 3 * (corridor_gap * damp_bar_w * damp_bar_h)
    damp_volume += 6 * (arm_w * arm_h * 45)  # vertical ties

    # Idler brackets + motor bracket
    bracket_volume = 3000  # rough mm^3

    # Frame posts (3 posts spanning full height)
    post_dia = d.get("POST_DIA", 2.5)
    post_height = 50  # approximate span
    post_volume = 3 * math.pi * (post_dia / 2) ** 2 * post_height

    frame_volume_mm3 = (
        ring_volume + stub_volume + arm_volume + junction_volume
        + carrier_node_vol + damp_volume + bracket_volume + post_volume
    )
    d["FRAME_VOLUME_MM3"] = frame_volume_mm3

    # 2. Matrix stack
    #    3 tiers of hex-clipped walls + sliders
    #    Rough: hex area * housing_height * 3 * wall_fraction
    housing_height = d.get("HOUSING_HEIGHT", 13)
    hex_area = (3 * math.sqrt(3) / 2) * hex_r ** 2  # hex area
    # Walls: ~10 walls per tier (9 interior + 2 boundary), each ~ wall_thickness * hex_width * housing_height
    wall_thick = d.get("WALL_THICKNESS", 1.5)
    avg_wall_len = hex_r * 1.5  # average across channels
    walls_per_tier = num_channels + 1  # 10
    wall_vol_per_tier = walls_per_tier * wall_thick * avg_wall_len * housing_height
    # Sliders: 9 per tier
    slider_plate_y = sp_od + 1
    plate_t = (d.get("CH_GAP", 6.5) / 2) - (1.5 / 2) - 0.2  # ~2.3mm
    avg_slider_len = 30  # mm approximate
    slider_vol_per_tier = num_channels * 2 * avg_slider_len * slider_plate_y * plate_t

    matrix_volume_mm3 = 3 * (wall_vol_per_tier + slider_vol_per_tier)
    d["MATRIX_VOLUME_MM3"] = matrix_volume_mm3

    # 3. Anchor plate
    anchor_volume_mm3 = hex_area * anchor_thick * 0.9  # subtract holes
    d["ANCHOR_VOLUME_MM3"] = anchor_volume_mm3

    # 4. Guide plate
    guide_volume_mm3 = hex_area * guide_thick * 0.9
    d["GUIDE_VOLUME_MM3"] = guide_volume_mm3

    # 5. Cam disc (per disc)
    disc_r = disc_od / 2
    boss_r = shaft_boss_od / 2
    disc_body_vol = math.pi * disc_r ** 2 * disc_thick
    boss_vol = math.pi * boss_r ** 2 * disc_thick
    collar_vol = math.pi * boss_r ** 2 * collar_thick
    bore_vol = math.pi * (shaft_dia / 2) ** 2 * (disc_thick + collar_thick)
    per_disc_vol = disc_body_vol + boss_vol + collar_vol - bore_vol
    d["PER_DISC_VOLUME_MM3"] = per_disc_vol

    # 6. Follower ring (per ring)
    fr_or = follower_ring_od / 2
    fr_ir = follower_ring_id / 2
    fr_h = follower_ring_h
    follower_arm_w = d.get("FOLLOWER_ARM_W", 3.0)
    follower_arm_len = d.get("FOLLOWER_ARM_LENGTH", 6.0)
    per_follower_vol = (
        math.pi * (fr_or ** 2 - fr_ir ** 2) * fr_h
        + follower_arm_len * follower_arm_w * fr_h  # arm
    )
    d["PER_FOLLOWER_VOLUME_MM3"] = per_follower_vol

    # 7. GT2 pulley (per pulley) — small
    gt2_r = gt2_od / 2
    gt2_bore_r = (shaft_dia + 0.2) / 2
    per_gt2_vol = math.pi * (gt2_r ** 2 - gt2_bore_r ** 2) * gt2_boss_h
    # Add flanges
    per_gt2_vol += 2 * math.pi * ((gt2_r + 1) ** 2 - gt2_bore_r ** 2) * 0.8
    d["PER_GT2_VOLUME_MM3"] = per_gt2_vol

    # 8. Block (per block)
    per_block_vol = block_ff * block_ff * block_h
    d["PER_BLOCK_VOLUME_MM3"] = per_block_vol

    return d


# ---------------------------------------------------------------------------
# 3. VOLUME / PRINT ESTIMATES
# ---------------------------------------------------------------------------

PLA_DENSITY_G_CM3 = 1.24
PLA_COST_PER_KG = 20.0  # USD
PRINT_RATE_CM3_PER_HOUR = 10.0  # rough at 0.2mm layer height
INFILL_FACTOR = 0.25  # 20-30% infill average


def vol_to_grams(vol_mm3: float) -> float:
    vol_cm3 = vol_mm3 / 1000
    return vol_cm3 * PLA_DENSITY_G_CM3 * INFILL_FACTOR + vol_cm3 * PLA_DENSITY_G_CM3 * 0.3
    # shells (~30% solid) + infill


def vol_to_grams_solid(vol_mm3: float) -> float:
    """For small solid parts like discs and pulleys."""
    return (vol_mm3 / 1000) * PLA_DENSITY_G_CM3


def vol_to_hours(vol_mm3: float) -> float:
    return (vol_mm3 / 1000) / PRINT_RATE_CM3_PER_HOUR


# ---------------------------------------------------------------------------
# 4. BOM STRUCTURE
# ---------------------------------------------------------------------------

def build_bom(d: dict) -> dict:
    """Build complete BOM dict from derived parameters."""

    num_helixes = 3
    num_cams = d["NUM_CAMS"]
    num_channels = d["NUM_CHANNELS"]
    total_cams = num_cams * num_helixes  # 27

    shaft_total = d["SHAFT_TOTAL_LENGTH"]
    shaft_total_rounded = math.ceil(shaft_total)

    belt_len = d["BELT_LENGTH_MM"]
    string_per = d["STRING_LENGTH_PER_PATH"]
    string_total = d["STRING_TOTAL_LENGTH"]

    # ---- PURCHASED PARTS ----
    purchased = []

    # Frame bearings — MR84ZZ
    frame_brg_qty = num_helixes * 2  # 2 per helix (carrier plates)
    purchased.append({
        "qty": frame_brg_qty,
        "part": "Ball bearing",
        "spec": f"MR84ZZ {int(d.get('FRAME_BRG_ID',4))}x{int(d.get('FRAME_BRG_OD',8))}x{int(d.get('FRAME_BRG_W',3))}mm",
        "unit_cost": 0.50,
        "source": "AliExpress / Amazon",
        "notes": "2 per helix, press-fit into carrier plate nodes",
    })

    # Cam bearings — 6704ZZ
    cam_brg_qty = total_cams  # 27
    purchased.append({
        "qty": cam_brg_qty,
        "part": "Ball bearing",
        "spec": f"6704ZZ {int(d.get('CAM_BRG_ID',20))}x{int(d.get('CAM_BRG_OD',27))}x{int(d.get('CAM_BRG_W',4))}mm",
        "unit_cost": 2.50,
        "source": "AliExpress / Amazon",
        "notes": "1 per cam disc, press-fit onto eccentric surface",
    })

    # Steel rod
    shaft_qty = num_helixes
    # Order length: round up to nearest 50mm for stock sizing
    order_len = int(math.ceil(shaft_total / 50) * 50)
    purchased.append({
        "qty": shaft_qty,
        "part": "Steel rod",
        "spec": f"{int(d.get('SHAFT_DIA',4))}mm D-flat SS, {order_len}mm",
        "unit_cost": round(order_len / 300 * 5, 2),
        "source": "McMaster-Carr / AliExpress",
        "notes": f"Computed length {shaft_total_rounded}mm + cut waste. D-flat depth {d.get('D_FLAT_DEPTH',0.4)}mm",
    })

    # E-clips
    eclip_qty = num_helixes * 2  # 2 per shaft
    purchased.append({
        "qty": eclip_qty,
        "part": "E-clip",
        "spec": f"DIN 6799 E-{int(d.get('SHAFT_DIA',4))}",
        "unit_cost": 0.15,
        "source": "McMaster-Carr (pack of 50 ~$5)",
        "notes": "1 each end of shaft, retains shaft in carrier bearings",
    })

    # GT2 belt
    belt_len_m = belt_len / 1000
    purchased.append({
        "qty": 1,
        "part": "GT2 belt (closed loop)",
        "spec": f"2mm pitch, 6mm wide, ~{int(math.ceil(belt_len))}mm loop",
        "unit_cost": round(belt_len_m * 3 + 2, 2),  # ~$3/m + $2 for closed loop
        "source": "Amazon / AliExpress",
        "notes": f"Computed loop ~{int(belt_len)}mm. Buy nearest standard size or open belt + connector.",
    })

    # GT2 pulleys (printed, but listing here as option for metal ones)
    # The design prints these, but metal ones are better. List as optional purchase.
    purchased.append({
        "qty": num_helixes,
        "part": "GT2 pulley (optional metal)",
        "spec": f"{int(d.get('GT2_TEETH',12))}T, {int(d.get('SHAFT_DIA',4))}mm bore",
        "unit_cost": 3.00,
        "source": "Amazon / AliExpress",
        "notes": "Can be 3D-printed (see printed parts). Metal recommended for durability.",
    })

    # Smooth idlers
    purchased.append({
        "qty": 2,
        "part": "Smooth idler pulley",
        "spec": f"~{round(d.get('GT2_OD', 9.1), 1)}mm OD, {int(d.get('IDLER_BORE',3))}mm bore",
        "unit_cost": 2.00,
        "source": "Amazon / AliExpress",
        "notes": "2 idlers at stub positions (stacked double on each post)",
    })

    # Dyneema string
    string_total_m = string_total / 1000
    purchased.append({
        "qty": num_channels,
        "part": "Dyneema braided line",
        "spec": f"0.5mm x {int(math.ceil(string_per))}mm each",
        "unit_cost": round(5 / 10 * string_per / 1000, 2),  # $5 per 10m
        "source": "Amazon (fishing line section)",
        "notes": f"Total: {round(string_total_m * 1.2, 1)}m (incl. 20% waste). Buy 5m spool.",
    })

    # Motor
    purchased.append({
        "qty": 1,
        "part": "Micro gearmotor or stepper",
        "spec": f"Body ~{int(d.get('MOTOR_BODY_DIA',10))}mm dia, {int(d.get('MOTOR_SHAFT_DIA',2))}mm shaft",
        "unit_cost": 8.00,
        "source": "AliExpress / Pololu",
        "notes": "Small DC gearmotor (N20 class) or micro stepper. Low RPM, high torque preferred.",
    })

    # CA glue
    purchased.append({
        "qty": 1,
        "part": "CA glue (cyanoacrylate)",
        "spec": "Medium viscosity, ~20g",
        "unit_cost": 5.00,
        "source": "Amazon / hobby shop",
        "notes": "For collar-disc bonding and anchor plate retention in frame sleeve.",
    })

    # ---- 3D-PRINTED PARTS ----
    printed = []

    # Frame monolith
    frame_g = vol_to_grams(d["FRAME_VOLUME_MM3"])
    frame_h = vol_to_hours(d["FRAME_VOLUME_MM3"])
    printed.append({
        "qty": 1,
        "part": "Frame monolith",
        "file": "monolith_v5_5.scad",
        "material": "PLA",
        "est_grams": round(frame_g, 0),
        "est_hours": round(frame_h, 1),
        "notes": "Large print. Orient flat (rings down). May need supports for arm overhangs.",
    })

    # Matrix stack
    matrix_g = vol_to_grams(d["MATRIX_VOLUME_MM3"])
    matrix_h = vol_to_hours(d["MATRIX_VOLUME_MM3"])
    printed.append({
        "qty": 1,
        "part": "Matrix stack (3 tiers)",
        "file": "matrix_stack_v5_5.scad",
        "material": "PLA",
        "est_grams": round(matrix_g, 0),
        "est_hours": round(matrix_h, 1),
        "notes": "Print-in-place captive sliders. Print vertically. Careful with PIP gaps.",
    })

    # Anchor plate
    anchor_g = vol_to_grams_solid(d["ANCHOR_VOLUME_MM3"])
    anchor_h = vol_to_hours(d["ANCHOR_VOLUME_MM3"])
    printed.append({
        "qty": 1,
        "part": "Anchor plate",
        "file": "anchor_plate_v5_5.scad",
        "material": "PLA",
        "est_grams": round(anchor_g, 1),
        "est_hours": round(anchor_h, 1),
    })

    # Guide plate
    guide_g = vol_to_grams_solid(d["GUIDE_VOLUME_MM3"])
    guide_h = vol_to_hours(d["GUIDE_VOLUME_MM3"])
    printed.append({
        "qty": 1,
        "part": "Guide plate",
        "file": "guide_plate_v5_5.scad",
        "material": "PLA",
        "est_grams": round(guide_g, 1),
        "est_hours": round(guide_h, 1),
        "notes": "Tapered through-holes. Print flat, funnel side up.",
    })

    # Cam discs (integrated disc+collar)
    disc_g = vol_to_grams_solid(d["PER_DISC_VOLUME_MM3"])
    disc_total_g = disc_g * total_cams
    disc_h = vol_to_hours(d["PER_DISC_VOLUME_MM3"] * total_cams)
    printed.append({
        "qty": total_cams,
        "part": "Cam disc+collar",
        "file": "helix_cam_v5_5.scad",
        "material": "PLA",
        "est_grams": round(disc_total_g, 0),
        "est_hours": round(disc_h, 1),
        "notes": (
            f"Each: OD={d['DISC_OD']}mm, thick={d['DISC_THICK']}+{d['COLLAR_THICK']}mm. "
            f"Print flat (disc face down). Last disc per helix has no collar."
        ),
    })

    # Follower rings
    fr_g = vol_to_grams_solid(d["PER_FOLLOWER_VOLUME_MM3"])
    fr_total_g = fr_g * total_cams
    fr_h = vol_to_hours(d["PER_FOLLOWER_VOLUME_MM3"] * total_cams)
    printed.append({
        "qty": total_cams,
        "part": "Follower ring",
        "file": "helix_cam_v5_5.scad",
        "material": "PLA",
        "est_grams": round(fr_total_g, 0),
        "est_hours": round(fr_h, 1),
        "notes": f"Ring OD={d['FOLLOWER_RING_OD']}mm with cable eyelet arm. Print flat.",
    })

    # GT2 pulleys (printed version)
    gt2_g = vol_to_grams_solid(d["PER_GT2_VOLUME_MM3"])
    gt2_total_g = gt2_g * num_helixes
    gt2_h_print = vol_to_hours(d["PER_GT2_VOLUME_MM3"] * num_helixes)
    printed.append({
        "qty": num_helixes,
        "part": "GT2 pulley (printed)",
        "file": "helix_cam_v5_5.scad",
        "material": "PLA",
        "est_grams": round(gt2_total_g, 1),
        "est_hours": round(gt2_h_print, 1),
        "notes": f"{int(d.get('GT2_TEETH',12))}T, D-flat bore. Replace with metal if available.",
    })

    # Blocks
    block_g = vol_to_grams_solid(d["PER_BLOCK_VOLUME_MM3"])
    # Count total blocks = total_columns (one block per string column)
    total_blocks = d["TOTAL_COLUMNS"]
    block_total_g = block_g * total_blocks
    block_h_print = vol_to_hours(d["PER_BLOCK_VOLUME_MM3"] * total_blocks)
    printed.append({
        "qty": total_blocks,
        "part": "Hanging block",
        "file": "(simple geometry)",
        "material": "PLA + steel shot ballast",
        "est_grams": round(block_total_g, 0),
        "est_hours": round(block_h_print, 1),
        "notes": f"Each: {d['BLOCK_FF']:.1f}x{d['BLOCK_FF']:.1f}x{d['BLOCK_H']}mm. Add ballast for weight.",
    })

    # ---- COST SUMMARIES ----
    purchased_total = sum(item["qty"] * item["unit_cost"] for item in purchased)
    total_print_grams = sum(item["est_grams"] for item in printed)
    total_print_hours = sum(item["est_hours"] for item in printed)
    pla_cost = total_print_grams / 1000 * PLA_COST_PER_KG

    return {
        "title": "Triple Helix MVP V5.5b",
        "generated": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "config_source": "config_v5_5.scad",
        "key_params": {
            "HEX_R": d.get("HEX_R"),
            "NUM_CHANNELS": d["NUM_CHANNELS"],
            "NUM_CAMS": d["NUM_CAMS"],
            "NUM_HELIXES": num_helixes,
            "TOTAL_CAMS": total_cams,
            "TOTAL_COLUMNS": d["TOTAL_COLUMNS"],
            "SHAFT_TOTAL_LENGTH_MM": round(shaft_total, 1),
            "BELT_LENGTH_MM": round(belt_len, 0),
            "STRING_PER_PATH_MM": round(string_per, 0),
            "ECCENTRICITY": d.get("ECCENTRICITY"),
            "DISC_OD": d["DISC_OD"],
            "HELIX_R_MM": round(d["HELIX_R"], 1),
            "SCALE": d.get("_SCALE", 0.4831),
        },
        "purchased": purchased,
        "printed": printed,
        "summary": {
            "purchased_total_usd": round(purchased_total, 2),
            "total_bearings": frame_brg_qty + cam_brg_qty,
            "print_grams": round(total_print_grams, 0),
            "print_hours": round(total_print_hours, 1),
            "pla_cost_usd": round(pla_cost, 2),
            "grand_total_usd": round(purchased_total + pla_cost, 2),
        },
    }


# ---------------------------------------------------------------------------
# 5. OUTPUT FORMATTERS
# ---------------------------------------------------------------------------

def format_console(bom: dict) -> str:
    """Produce a human-readable table for the terminal."""
    lines = []
    w = 72

    lines.append("=" * w)
    lines.append(f"BILL OF MATERIALS -- {bom['title']}")
    lines.append(f"Generated: {bom['generated']}")
    lines.append(f"Config: {bom['config_source']}")
    lines.append("=" * w)

    # Key parameters
    lines.append("")
    lines.append("KEY PARAMETERS")
    lines.append("-" * w)
    kp = bom["key_params"]
    lines.append(f"  Scale factor:    {kp['SCALE']}")
    lines.append(f"  HEX_R:           {kp['HEX_R']}mm")
    lines.append(f"  Channels:        {kp['NUM_CHANNELS']}  |  Cams/helix: {kp['NUM_CAMS']}  |  Total cams: {kp['TOTAL_CAMS']}")
    lines.append(f"  Total columns:   {kp['TOTAL_COLUMNS']} (string attachment points)")
    lines.append(f"  DISC_OD:         {kp['DISC_OD']}mm  |  Eccentricity: {kp['ECCENTRICITY']}mm")
    lines.append(f"  HELIX_R:         {kp['HELIX_R_MM']}mm")
    lines.append(f"  Shaft length:    {kp['SHAFT_TOTAL_LENGTH_MM']}mm each (x3)")
    lines.append(f"  Belt loop:       ~{int(kp['BELT_LENGTH_MM'])}mm")
    lines.append(f"  String/path:     ~{int(kp['STRING_PER_PATH_MM'])}mm each (x{kp['NUM_CHANNELS']})")
    lines.append("")

    # Purchased parts
    lines.append("PURCHASED PARTS")
    lines.append("-" * w)
    hdr = f"{'Qty':>5}  {'Part':<30} {'Spec':<28} {'Est.':>7}"
    lines.append(hdr)
    lines.append("-" * w)

    for item in bom["purchased"]:
        cost = item["qty"] * item["unit_cost"]
        lines.append(
            f"{item['qty']:>5}  {item['part']:<30} {item['spec']:<28} ${cost:>6.2f}"
        )

    lines.append("-" * w)
    lines.append(f"{'':>5}  {'':30} {'SUBTOTAL (purchased)':<28} ${bom['summary']['purchased_total_usd']:>6.2f}")
    lines.append(f"{'':>5}  {'':30} {'Total bearings: ' + str(bom['summary']['total_bearings']):<28}")
    lines.append("")

    # Printed parts
    lines.append("3D-PRINTED PARTS")
    lines.append("-" * w)
    hdr2 = f"{'Qty':>5}  {'Part':<30} {'Material':<10} {'Hours':>6} {'Grams':>7}"
    lines.append(hdr2)
    lines.append("-" * w)

    for item in bom["printed"]:
        lines.append(
            f"{item['qty']:>5}  {item['part']:<30} {item['material']:<10} {item['est_hours']:>5.1f}h {item['est_grams']:>6.0f}g"
        )

    lines.append("-" * w)
    lines.append(
        f"{'':>5}  {'TOTALS':<30} {'PLA':<10} "
        f"{bom['summary']['print_hours']:>5.1f}h {bom['summary']['print_grams']:>6.0f}g"
    )
    lines.append(
        f"{'':>5}  {'':30} {'PLA cost (~$' + str(PLA_COST_PER_KG) + '/kg)':<28} ${bom['summary']['pla_cost_usd']:>6.2f}"
    )
    lines.append("")

    # Grand total
    lines.append("=" * w)
    lines.append(
        f"  GRAND TOTAL ESTIMATE:  ${bom['summary']['grand_total_usd']:.2f}"
    )
    lines.append("=" * w)

    # Notes
    lines.append("")
    lines.append("NOTES")
    lines.append("-" * w)
    for item in bom["purchased"]:
        if item.get("notes"):
            lines.append(f"  [{item['part']}] {item['notes']}")
    lines.append("")
    for item in bom["printed"]:
        if item.get("notes"):
            lines.append(f"  [{item['part']}] {item['notes']}")

    lines.append("")
    lines.append("SOURCING TIPS")
    lines.append("-" * w)
    lines.append("  - MR84ZZ & 6704ZZ: buy 10-packs on AliExpress for bulk savings")
    lines.append("  - 4mm D-flat rod: McMaster-Carr #1256T12 or grind flats on round rod")
    lines.append("  - E-clips: DIN 6799 packs of 50 are cheapest (~$5)")
    lines.append("  - GT2 belt: measure actual path in final build, order closest loop size")
    lines.append("  - Dyneema 0.5mm: fishing braided line (PE line) works perfectly")
    lines.append(f"  - Print times assume {PRINT_RATE_CM3_PER_HOUR} cm3/h at 0.2mm layers, ~25% infill")

    return "\n".join(lines)


def write_csv(bom: dict, path: str):
    """Write BOM as CSV file."""
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)

        writer.writerow(["Bill of Materials", bom["title"]])
        writer.writerow(["Generated", bom["generated"]])
        writer.writerow([])

        # Purchased
        writer.writerow(["PURCHASED PARTS"])
        writer.writerow(["Qty", "Part", "Spec", "Unit Cost ($)", "Total Cost ($)", "Source", "Notes"])
        for item in bom["purchased"]:
            writer.writerow([
                item["qty"],
                item["part"],
                item["spec"],
                f"{item['unit_cost']:.2f}",
                f"{item['qty'] * item['unit_cost']:.2f}",
                item.get("source", ""),
                item.get("notes", ""),
            ])
        writer.writerow([
            "", "", "", "Subtotal",
            f"{bom['summary']['purchased_total_usd']:.2f}", "", "",
        ])
        writer.writerow([])

        # Printed
        writer.writerow(["3D-PRINTED PARTS"])
        writer.writerow(["Qty", "Part", "File", "Material", "Est. Hours", "Est. Grams", "Notes"])
        for item in bom["printed"]:
            writer.writerow([
                item["qty"],
                item["part"],
                item.get("file", ""),
                item["material"],
                f"{item['est_hours']:.1f}",
                f"{item['est_grams']:.0f}",
                item.get("notes", ""),
            ])
        writer.writerow([
            "", "Totals", "", "PLA",
            f"{bom['summary']['print_hours']:.1f}",
            f"{bom['summary']['print_grams']:.0f}",
            f"PLA cost: ${bom['summary']['pla_cost_usd']:.2f}",
        ])
        writer.writerow([])
        writer.writerow(["GRAND TOTAL", f"${bom['summary']['grand_total_usd']:.2f}"])


def write_json(bom: dict, path: str):
    """Write BOM as JSON file."""
    with open(path, "w", encoding="utf-8") as f:
        json.dump(bom, f, indent=2)


# ---------------------------------------------------------------------------
# 6. MAIN
# ---------------------------------------------------------------------------

def main():
    # Locate config file — check both the 5.5 directory and check point/5.5
    script_dir = Path(__file__).parent.resolve()
    config_candidates = [
        script_dir / "config_v5_5.scad",
        script_dir.parent / "check point" / "5.5" / "config_v5_5.scad",
    ]

    config_path = None
    for candidate in config_candidates:
        if candidate.exists():
            config_path = candidate
            break

    if config_path is None:
        print(f"ERROR: config_v5_5.scad not found in:")
        for c in config_candidates:
            print(f"  {c}")
        sys.exit(1)

    print(f"Reading config: {config_path}")

    # Parse and derive
    params = parse_config(str(config_path))
    derived = derive(params)

    # Build BOM
    bom = build_bom(derived)

    # Output
    do_csv = "--csv" in sys.argv
    do_json = "--json" in sys.argv

    # Always print console output
    print()
    print(format_console(bom))

    if do_csv:
        csv_path = script_dir / "bom_v5_5.csv"
        write_csv(bom, str(csv_path))
        print(f"\nCSV written to: {csv_path}")

    if do_json:
        json_path = script_dir / "bom_v5_5.json"
        write_json(bom, str(json_path))
        print(f"\nJSON written to: {json_path}")

    if not do_csv and not do_json:
        print(f"\nTip: use --csv and/or --json for file output.")


if __name__ == "__main__":
    main()
