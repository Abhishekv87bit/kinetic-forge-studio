"""
General Assembly (GA) Drawing — The Physical Transformer
6-view third-angle projection with BOM table.

All coordinates derived from spec v2 (2026-03-17-physical-transformer-design.md).
Units: millimeters throughout.
"""

import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, Rectangle, Circle, Polygon, FancyArrowPatch
from matplotlib.lines import Line2D
from matplotlib.table import Table
from matplotlib.font_manager import FontProperties
import os

# ── Colour palette ──────────────────────────────────────────────────
COL_BRASS   = '#c9a84c'
COL_STEEL   = '#8899aa'
COL_PLA     = '#555555'
COL_RESIN   = '#7788aa'
COL_FRAME   = '#333333'
COL_DIM     = '#1a3366'   # dark blue dimension lines
COL_BG      = '#ffffff'
COL_RED     = '#aa2222'
COL_ACRYLIC = '#bbddee'

# ── Spec dimensions (mm) ────────────────────────────────────────────
W_FRONT, H_FRONT = 900, 600
DEPTH            = 450
EXTRUSION        = 20          # 2020 extrusion border
INTERIOR_W       = W_FRONT - 2 * EXTRUSION   # 860
INTERIOR_H       = H_FRONT - 2 * EXTRUSION   # 560

# Triptych zones (measured from frame top = y=0 in front-view coords)
# We use y=0 at bottom, y=600 at top for matplotlib
ZONE_TOP_H    = 187   # worm gears
ZONE_MID_H    = 186   # spiral cams
ZONE_BOT_H    = 147   # error sliders  (187+186+147 = 520 < 560, remainder = 40 → margins)
ZONE_MARGIN   = (INTERIOR_H - ZONE_TOP_H - ZONE_MID_H - ZONE_BOT_H) / 2  # 20mm each

# Zone y-limits (bottom-up): bottom zone starts above bottom extrusion
ZONE_BOT_Y0 = EXTRUSION + ZONE_MARGIN
ZONE_BOT_Y1 = ZONE_BOT_Y0 + ZONE_BOT_H
ZONE_MID_Y0 = ZONE_BOT_Y1
ZONE_MID_Y1 = ZONE_MID_Y0 + ZONE_MID_H
ZONE_TOP_Y0 = ZONE_MID_Y1
ZONE_TOP_Y1 = ZONE_TOP_Y0 + ZONE_TOP_H

# ── Callout counter ─────────────────────────────────────────────────
_callout_num = 0

def next_callout():
    global _callout_num
    _callout_num += 1
    return _callout_num

# ── Helper: dimension line ──────────────────────────────────────────
def dim_line(ax, p1, p2, offset, text, horizontal=True, fontsize=5):
    """Draw a dimension line with arrows and text."""
    x1, y1 = p1
    x2, y2 = p2
    if horizontal:
        yo = y1 + offset
        ax.annotate('', xy=(x1, yo), xytext=(x2, yo),
                     arrowprops=dict(arrowstyle='<->', color=COL_DIM, lw=0.6))
        ax.plot([x1, x1], [y1, yo], color=COL_DIM, lw=0.25, ls='--')
        ax.plot([x2, x2], [y2, yo], color=COL_DIM, lw=0.25, ls='--')
        ax.text((x1+x2)/2, yo+2, text, ha='center', va='bottom',
                fontsize=fontsize, color=COL_DIM, fontweight='bold')
    else:  # vertical
        xo = x1 + offset
        ax.annotate('', xy=(xo, y1), xytext=(xo, y2),
                     arrowprops=dict(arrowstyle='<->', color=COL_DIM, lw=0.6))
        ax.plot([x1, xo], [y1, y1], color=COL_DIM, lw=0.25, ls='--')
        ax.plot([x2, xo], [y2, y2], color=COL_DIM, lw=0.25, ls='--')
        ax.text(xo+3, (y1+y2)/2, text, ha='left', va='center',
                fontsize=fontsize, color=COL_DIM, fontweight='bold', rotation=90)

def callout(ax, num, xy, text_xy, label='', fontsize=5):
    """Circled number with leader line."""
    ax.annotate(str(num), xy=xy, xytext=text_xy,
                fontsize=fontsize, fontweight='bold', ha='center', va='center',
                bbox=dict(boxstyle='circle,pad=0.25', fc='white', ec='black', lw=0.5),
                arrowprops=dict(arrowstyle='->', color='black', lw=0.4))

# ── Helper: draw 2020 extrusion frame ──────────────────────────────
def draw_frame(ax, w, h, lw=0.8):
    """Draw a 2020 extrusion frame (double rectangle)."""
    outer = Rectangle((0, 0), w, h, lw=lw, ec='black', fc='none')
    inner = Rectangle((EXTRUSION, EXTRUSION), w - 2*EXTRUSION, h - 2*EXTRUSION,
                       lw=lw*0.6, ec=COL_FRAME, fc='none', ls='--')
    ax.add_patch(outer)
    ax.add_patch(inner)
    # Corner gussets
    for cx, cy in [(0,0),(w,0),(0,h),(w,h)]:
        ax.add_patch(Rectangle((cx - EXTRUSION/2, cy - EXTRUSION/2),
                                 EXTRUSION, EXTRUSION, lw=0.3, ec=COL_FRAME,
                                 fc=COL_FRAME, alpha=0.25, zorder=2))

# ══════════════════════════════════════════════════════════════════════
#  FRONT VIEW
# ══════════════════════════════════════════════════════════════════════
def draw_front_view(ax):
    ax.set_xlim(-60, W_FRONT + 120)
    ax.set_ylim(-60, H_FRONT + 80)
    ax.set_aspect('equal')
    ax.set_title('FRONT VIEW', fontsize=8, fontweight='bold', pad=8)
    ax.axis('off')

    # Frame
    draw_frame(ax, W_FRONT, H_FRONT)

    # Triptych zone shading
    for y0, y1, label, col in [
        (ZONE_TOP_Y0, ZONE_TOP_Y1, 'WORM GEARS (MEMORY)', '#fff8e0'),
        (ZONE_MID_Y0, ZONE_MID_Y1, 'SPIRAL CAMS (LEARNING)', '#eef4ff'),
        (ZONE_BOT_Y0, ZONE_BOT_Y1, 'ERROR SLIDERS', '#ffeeee'),
    ]:
        ax.add_patch(Rectangle((EXTRUSION, y0), INTERIOR_W, y1 - y0,
                                fc=col, ec='none', alpha=0.5, zorder=0))
        ax.text(W_FRONT/2, (y0+y1)/2 + (y1-y0)/2 - 6, label,
                ha='center', va='top', fontsize=4.5, fontstyle='italic', color='#666666')

    # ── Worm gears (top zone) ─────────────────────────────────────
    # Hidden neuron rows: 3 rows x 10 gears (9 weights + 1 bias per row? Spec: 42 total = 30 hidden + 12 output)
    # Spec 7.2: 42 worm gears total.  3 hidden neurons x (9 weights + 1 bias) = 30.  3 output neurons x (3+1) = 12.
    # Layout: top section has hidden rows (3 rows x 10) + output rows (3 rows x 4)
    cx = W_FRONT / 2
    gear_r = 12  # ~24mm dia / 2

    # Hidden neuron gears: 3 rows x 10
    hid_xs = np.linspace(cx - 120, cx + 120, 10)
    hid_ys = [ZONE_TOP_Y1 - 30, ZONE_TOP_Y1 - 52, ZONE_TOP_Y1 - 74]  # top-down within zone
    for row_i, yy in enumerate(hid_ys):
        for xi in hid_xs:
            c = Circle((xi, yy), gear_r, fc=COL_BRASS, ec='black', lw=0.3, zorder=3)
            ax.add_patch(c)
            # Worm groove lines
            ax.plot([xi - gear_r*0.6, xi + gear_r*0.6], [yy, yy],
                    color='#8a7030', lw=0.3, zorder=4)

    # Output neuron gears: 3 rows x 4
    out_xs = np.linspace(cx - 36, cx + 36, 4)
    out_ys = [ZONE_TOP_Y1 - 104, ZONE_TOP_Y1 - 126, ZONE_TOP_Y1 - 148]
    for yy in out_ys:
        for xi in out_xs:
            c = Circle((xi, yy), gear_r, fc=COL_BRASS, ec='black', lw=0.3, zorder=3)
            ax.add_patch(c)
            ax.plot([xi - gear_r*0.6, xi + gear_r*0.6], [yy, yy],
                    color='#8a7030', lw=0.3, zorder=4)

    cn = next_callout()
    callout(ax, cn, (hid_xs[9], hid_ys[0]), (hid_xs[9]+55, hid_ys[0]+25),
            'Worm gear (x42)', fontsize=4.5)

    # ── Spiral cams (middle zone) ─────────────────────────────────
    cam_dia = 40
    cam_r   = cam_dia / 2
    n_cols, n_rows_cam = 7, 6
    pitch_x, pitch_y = 55, 40
    grid_w = (n_cols - 1) * pitch_x  # 330
    grid_h = (n_rows_cam - 1) * pitch_y  # 200
    cam_x0 = (W_FRONT - grid_w) / 2
    cam_y_center = (ZONE_MID_Y0 + ZONE_MID_Y1) / 2
    cam_y0 = cam_y_center - grid_h / 2

    for row in range(n_rows_cam):
        for col in range(n_cols):
            cx_c = cam_x0 + col * pitch_x
            cy_c = cam_y0 + row * pitch_y
            # Cam body
            ax.add_patch(Circle((cx_c, cy_c), cam_r, fc=COL_RESIN, ec='black', lw=0.3, zorder=3))
            # Archimedean spiral inside
            theta = np.linspace(0, 254 * np.pi / 180, 80)
            r_min, r_max = 1.0, 6.0
            r_spiral = r_min + (r_max - r_min) * theta / (254 * np.pi / 180)
            # Scale to visual size (spiral goes from 1mm to 6mm, but we scale to cam_r)
            scale = cam_r * 0.85 / r_max
            sx = cx_c + r_spiral * scale * np.cos(theta)
            sy = cy_c + r_spiral * scale * np.sin(theta)
            ax.plot(sx, sy, color='#445566', lw=0.25, zorder=4)

    cn = next_callout()
    callout(ax, cn, (cam_x0 + 6*pitch_x, cam_y0 + 5*pitch_y),
            (cam_x0 + 6*pitch_x + 60, cam_y0 + 5*pitch_y + 20),
            'Spiral cam (x42)', fontsize=4.5)

    # ── Error sliders (bottom zone) ───────────────────────────────
    rail_len = 100
    rail_h   = 3
    slider_w = 10
    slider_h = 8
    n_sliders = 3
    slider_spacing = 400 / (n_sliders + 1)  # evenly across center 400mm
    slider_x0 = (W_FRONT - 400) / 2

    zone_bot_cy = (ZONE_BOT_Y0 + ZONE_BOT_Y1) / 2

    for i in range(n_sliders):
        rx = slider_x0 + (i + 1) * slider_spacing - rail_len / 2
        ry = zone_bot_cy - rail_h / 2 + (i - 1) * 30  # offset vertically

        # Rail (MGN7)
        ax.add_patch(Rectangle((rx, ry), rail_len, rail_h,
                                fc=COL_STEEL, ec='black', lw=0.3, zorder=3))
        # Slider block
        sx = rx + rail_len / 2 - slider_w / 2 + np.random.uniform(-8, 8)
        sy = ry - (slider_h - rail_h) / 2
        ax.add_patch(Rectangle((sx, sy), slider_w, slider_h,
                                fc=COL_BRASS, ec='black', lw=0.4, zorder=4))
        # "ZERO ERROR" text
        ax.text(rx + rail_len / 2, ry - 6, 'ZERO ERROR', ha='center', va='top',
                fontsize=2.5, color='#666666')

        # Leaf spring zigzag
        spring_x = np.linspace(sx + slider_w + 2, sx + slider_w + 20, 12)
        spring_y = ry + rail_h/2 + 3 * np.array([0, 1, -1, 1, -1, 1, -1, 1, -1, 1, -1, 0])
        ax.plot(spring_x, spring_y, color='#4466aa', lw=0.4, zorder=4)

    cn = next_callout()
    callout(ax, cn, (slider_x0 + slider_spacing - rail_len/2 + rail_len,
                     zone_bot_cy - 30 + rail_h/2),
            (slider_x0 + slider_spacing + rail_len/2 + 50, zone_bot_cy - 45),
            'MGN7 slider (x3)', fontsize=4.5)

    # ── Dimension lines ───────────────────────────────────────────
    dim_line(ax, (0, 0), (W_FRONT, 0), -40, f'{W_FRONT}', horizontal=True)
    dim_line(ax, (0, 0), (0, H_FRONT), -45, f'{H_FRONT}', horizontal=False)

    # Zone heights (right side)
    dim_line(ax, (W_FRONT, ZONE_TOP_Y0), (W_FRONT, ZONE_TOP_Y1), 30,
             f'{ZONE_TOP_H}', horizontal=False, fontsize=4)
    dim_line(ax, (W_FRONT, ZONE_MID_Y0), (W_FRONT, ZONE_MID_Y1), 50,
             f'{ZONE_MID_H}', horizontal=False, fontsize=4)
    dim_line(ax, (W_FRONT, ZONE_BOT_Y0), (W_FRONT, ZONE_BOT_Y1), 70,
             f'{ZONE_BOT_H}', horizontal=False, fontsize=4)

    # Worm gear grid dimension
    dim_line(ax, (hid_xs[0], hid_ys[0] + gear_r), (hid_xs[-1], hid_ys[0] + gear_r),
             20, '240 (10 x 24)', horizontal=True, fontsize=4)

    # Spiral cam array
    dim_line(ax, (cam_x0, cam_y0 - cam_r), (cam_x0 + grid_w, cam_y0 - cam_r),
             -15, f'{int(grid_w)} (7 x 55)', horizontal=True, fontsize=4)

    # ── Callouts for zones ────────────────────────────────────────
    ax.text(EXTRUSION + 5, ZONE_TOP_Y1 - 5, 'TOP THIRD', fontsize=3.5,
            color='#888', va='top')
    ax.text(EXTRUSION + 5, ZONE_MID_Y1 - 5, 'MIDDLE THIRD', fontsize=3.5,
            color='#888', va='top')
    ax.text(EXTRUSION + 5, ZONE_BOT_Y1 - 5, 'BOTTOM THIRD', fontsize=3.5,
            color='#888', va='top')

# ══════════════════════════════════════════════════════════════════════
#  TOP VIEW
# ══════════════════════════════════════════════════════════════════════
def draw_top_view(ax):
    ax.set_xlim(-40, W_FRONT + 60)
    ax.set_ylim(-30, DEPTH + 50)
    ax.set_aspect('equal')
    ax.set_title('TOP VIEW', fontsize=8, fontweight='bold', pad=8)
    ax.axis('off')

    # Frame outline
    ax.add_patch(Rectangle((0, 0), W_FRONT, DEPTH, lw=0.8, ec='black', fc='none'))
    ax.add_patch(Rectangle((EXTRUSION, EXTRUSION), W_FRONT - 2*EXTRUSION,
                            DEPTH - 2*EXTRUSION, lw=0.4, ec=COL_FRAME, fc='none', ls='--'))

    # Pin drum centerline (above, at depth ~30mm from front)
    drum_y = 30
    drum_len = 360
    drum_x0 = (W_FRONT - drum_len) / 2
    ax.add_patch(Rectangle((drum_x0, drum_y - 5), drum_len, 10,
                            fc=COL_BRASS, ec='black', lw=0.4, alpha=0.6, zorder=3))
    ax.plot([drum_x0, drum_x0 + drum_len], [drum_y, drum_y],
            color='black', lw=0.3, ls='-.', zorder=4)
    cn = next_callout()
    callout(ax, cn, (drum_x0 + drum_len, drum_y), (drum_x0 + drum_len + 40, drum_y + 15),
            fontsize=4.5)

    # String routing planes — two lines
    plane1_y = EXTRUSION + 20
    plane2_y = EXTRUSION + 45
    ax.plot([EXTRUSION, W_FRONT - EXTRUSION], [plane1_y, plane1_y],
            color='#cc8844', lw=0.3, ls=':', zorder=2)
    ax.plot([EXTRUSION, W_FRONT - EXTRUSION], [plane2_y, plane2_y],
            color='#4488cc', lw=0.3, ls=':', zorder=2)
    ax.text(W_FRONT - EXTRUSION + 3, plane1_y, 'String plane 1', fontsize=3, va='center')
    ax.text(W_FRONT - EXTRUSION + 3, plane2_y, 'String plane 2', fontsize=3, va='center')

    # Pin drum dashed circle (from above)
    drum_r = 35  # 70mm dia / 2
    drum_cx = W_FRONT / 2
    drum_cy_top = drum_y
    circle_drum = Circle((drum_cx, drum_cy_top), drum_r, lw=0.4, ec='black',
                          fc='none', ls='--', zorder=3)
    ax.add_patch(circle_drum)

    # Motor square (back right)
    motor_size = 57
    motor_x = W_FRONT - EXTRUSION - motor_size - 30
    motor_y = DEPTH - EXTRUSION - motor_size - 10
    ax.add_patch(Rectangle((motor_x, motor_y), motor_size, motor_size,
                            fc=COL_PLA, ec='black', lw=0.5, zorder=3))
    ax.text(motor_x + motor_size/2, motor_y + motor_size/2, 'NEMA\n23',
            ha='center', va='center', fontsize=3.5, color='white', fontweight='bold')
    cn = next_callout()
    callout(ax, cn, (motor_x, motor_y + motor_size/2),
            (motor_x - 35, motor_y + motor_size/2 + 15), fontsize=4.5)

    # Barrel cam centerline (back)
    bc_len = 270
    bc_x0 = (W_FRONT - bc_len) / 2
    bc_y  = DEPTH - EXTRUSION - 40
    ax.plot([bc_x0, bc_x0 + bc_len], [bc_y, bc_y],
            color=COL_PLA, lw=1.5, zorder=3)
    ax.plot([bc_x0, bc_x0 + bc_len], [bc_y, bc_y],
            color='black', lw=0.3, ls='-.', zorder=4)
    cn = next_callout()
    callout(ax, cn, (bc_x0 + bc_len/2, bc_y), (bc_x0 + bc_len/2, bc_y + 25), fontsize=4.5)

    # Dimensions
    dim_line(ax, (0, 0), (W_FRONT, 0), -20, f'{W_FRONT}', horizontal=True)
    dim_line(ax, (0, 0), (0, DEPTH), -30, f'{DEPTH}', horizontal=False)

# ══════════════════════════════════════════════════════════════════════
#  LEFT VIEW
# ══════════════════════════════════════════════════════════════════════
def draw_left_view(ax):
    ax.set_xlim(-40, DEPTH + 60)
    ax.set_ylim(-40, H_FRONT + 60)
    ax.set_aspect('equal')
    ax.set_title('LEFT VIEW (I/O Panel)', fontsize=8, fontweight='bold', pad=8)
    ax.axis('off')

    # Frame
    ax.add_patch(Rectangle((0, 0), DEPTH, H_FRONT, lw=0.8, ec='black', fc='none'))

    # 3 input prisms (triangular, at hand height ~200-350mm)
    prism_face = 40
    prism_h = prism_face * np.sqrt(3) / 2  # equilateral triangle height
    prism_xs = [DEPTH/2 - 20, DEPTH/2, DEPTH/2 + 20]
    prism_ys = [200, 270, 340]

    for i, (px, py) in enumerate(zip(prism_xs, prism_ys)):
        tri = Polygon([
            (px - prism_face/2, py - prism_h/3),
            (px + prism_face/2, py - prism_h/3),
            (px, py + 2*prism_h/3)
        ], closed=True, fc=COL_BRASS, ec='black', lw=0.4, zorder=3)
        ax.add_patch(tri)
        ax.text(px, py, f'W{i+1}', ha='center', va='center', fontsize=3.5,
                fontweight='bold', zorder=4)

    cn = next_callout()
    callout(ax, cn, (prism_xs[2] + prism_face/2, prism_ys[2]),
            (prism_xs[2] + prism_face/2 + 40, prism_ys[2] + 20), fontsize=4.5)

    # Answer prism (above, at eye level ~480mm)
    apx, apy = DEPTH/2, 480
    tri_a = Polygon([
        (apx - prism_face/2, apy - prism_h/3),
        (apx + prism_face/2, apy - prism_h/3),
        (apx, apy + 2*prism_h/3)
    ], closed=True, fc=COL_BRASS, ec='black', lw=0.5, zorder=3)
    ax.add_patch(tri_a)
    ax.text(apx, apy, 'ANS', ha='center', va='center', fontsize=3.5,
            fontweight='bold', zorder=4)
    cn = next_callout()
    callout(ax, cn, (apx + prism_face/2, apy),
            (apx + prism_face/2 + 40, apy + 15), fontsize=4.5)

    # Mode lever
    lever_x = DEPTH/2 - 50
    lever_y_base = 400
    ax.plot([lever_x, lever_x], [lever_y_base, lever_y_base + 60],
            color='black', lw=1.5, zorder=3)
    ax.add_patch(Circle((lever_x, lever_y_base + 60), 6, fc=COL_RED,
                         ec='black', lw=0.4, zorder=4))
    ax.text(lever_x - 12, lever_y_base + 30, 'MODE\nLEVER', ha='center',
            va='center', fontsize=3, rotation=90)
    cn = next_callout()
    callout(ax, cn, (lever_x, lever_y_base + 60),
            (lever_x - 35, lever_y_base + 80), fontsize=4.5)

    # Geneva drive (small, near answer prism)
    gd_x, gd_y = DEPTH/2 + 60, 480
    ax.add_patch(Circle((gd_x, gd_y), 15, fc=COL_STEEL, ec='black', lw=0.4, zorder=3))
    # Geneva slots
    for angle in [0, 120, 240]:
        rad = np.radians(angle)
        ax.plot([gd_x, gd_x + 15*np.cos(rad)], [gd_y, gd_y + 15*np.sin(rad)],
                color='black', lw=0.5, zorder=4)
    cn = next_callout()
    callout(ax, cn, (gd_x + 15, gd_y), (gd_x + 40, gd_y - 15), fontsize=4.5)

    # Dimensions
    dim_line(ax, (0, 0), (DEPTH, 0), -25, f'{DEPTH}', horizontal=True, fontsize=5)

# ══════════════════════════════════════════════════════════════════════
#  RIGHT VIEW
# ══════════════════════════════════════════════════════════════════════
def draw_right_view(ax):
    ax.set_xlim(-40, DEPTH + 60)
    ax.set_ylim(-40, H_FRONT + 60)
    ax.set_aspect('equal')
    ax.set_title('RIGHT VIEW (Computation)', fontsize=8, fontweight='bold', pad=8)
    ax.axis('off')

    # Frame
    ax.add_patch(Rectangle((0, 0), DEPTH, H_FRONT, lw=0.8, ec='black', fc='none'))

    # 3 pantograph chains (rhombus/diamond shapes)
    panto_cx = DEPTH / 2
    chain_ys = [180, 330, 480]  # 3 hidden neurons

    for ci, base_y in enumerate(chain_ys):
        # 3 diamonds per chain
        for di in range(3):
            dy = base_y + di * 45
            # Diamond (rhombus) parametric
            half_w = 35  # expanded width/2
            half_h = 20  # expanded height/2
            diamond = Polygon([
                (panto_cx - half_w, dy),
                (panto_cx, dy + half_h),
                (panto_cx + half_w, dy),
                (panto_cx, dy - half_h),
            ], closed=True, fc=COL_PLA, ec='black', lw=0.4, alpha=0.7, zorder=3)
            ax.add_patch(diamond)
            # Joint circles (needle bearings)
            for jx, jy in [(panto_cx - half_w, dy), (panto_cx + half_w, dy),
                           (panto_cx, dy + half_h), (panto_cx, dy - half_h)]:
                ax.add_patch(Circle((jx, jy), 3, fc=COL_STEEL, ec='black', lw=0.2, zorder=4))

    cn = next_callout()
    callout(ax, cn, (panto_cx + 35, chain_ys[0]), (panto_cx + 80, chain_ys[0] + 15), fontsize=4.5)

    # 3 ReLU cams (50mm circles with profile)
    relu_ys = [base_y + 3*45 + 30 for base_y in chain_ys]
    for ry in relu_ys:
        ax.add_patch(Circle((panto_cx, ry), 25, fc=COL_RESIN, ec='black', lw=0.4, zorder=3))
        # ReLU profile: flat left, ramp right
        rx = np.linspace(-20, 20, 40)
        relu_y = np.where(rx < 0, 0, rx * 0.8)
        ax.plot(panto_cx + rx, ry + relu_y - 5, color='black', lw=0.6, zorder=4)

    cn = next_callout()
    callout(ax, cn, (panto_cx + 25, relu_ys[0]), (panto_cx + 55, relu_ys[0] - 20), fontsize=4.5)

    # Output rods (3 vertical lines from pantographs)
    for i, ry in enumerate(relu_ys):
        rod_x = panto_cx + 60 + i * 15
        ax.plot([rod_x, rod_x], [ry - 30, ry + 30], color=COL_BRASS, lw=1.2, zorder=3)
        ax.add_patch(Circle((rod_x, ry + 30), 3, fc=COL_BRASS, ec='black', lw=0.3, zorder=4))
    cn = next_callout()
    callout(ax, cn, (panto_cx + 60, relu_ys[1] + 30),
            (panto_cx + 100, relu_ys[1] + 50), fontsize=4.5)

# ══════════════════════════════════════════════════════════════════════
#  BACK VIEW
# ══════════════════════════════════════════════════════════════════════
def draw_back_view(ax):
    ax.set_xlim(-40, W_FRONT + 60)
    ax.set_ylim(-40, H_FRONT + 60)
    ax.set_aspect('equal')
    ax.set_title('BACK VIEW (Motor & Timing)', fontsize=8, fontweight='bold', pad=8)
    ax.axis('off')

    # Frame (mirrored)
    ax.add_patch(Rectangle((0, 0), W_FRONT, H_FRONT, lw=0.8, ec='black', fc='none'))

    cx = W_FRONT / 2

    # NEMA 23 motor (57x57)
    motor_w, motor_h = 57, 57
    motor_x = cx - motor_w / 2
    motor_y = H_FRONT / 2 - 50
    ax.add_patch(Rectangle((motor_x, motor_y), motor_w, motor_h,
                            fc=COL_PLA, ec='black', lw=0.6, zorder=3))
    # Motor shaft
    ax.add_patch(Circle((cx, motor_y + motor_h/2), 4, fc=COL_STEEL, ec='black', lw=0.3, zorder=4))
    # Mounting holes
    for dx, dy in [(-23, -23), (23, -23), (-23, 23), (23, 23)]:
        ax.add_patch(Circle((cx + dx, motor_y + motor_h/2 + dy), 2.5,
                            fc='white', ec='black', lw=0.3, zorder=4))
    ax.text(cx, motor_y + motor_h/2, 'NEMA 23\n1.26 Nm', ha='center', va='center',
            fontsize=3.5, color='white', fontweight='bold', zorder=5)
    cn = next_callout()
    callout(ax, cn, (motor_x + motor_w, motor_y + motor_h/2),
            (motor_x + motor_w + 50, motor_y + motor_h/2 + 20), fontsize=4.5)

    # Barrel cam (40 x 270 rectangle)
    bc_w, bc_h = 270, 40
    bc_x = cx - bc_w / 2
    bc_y = motor_y + motor_h + 30
    ax.add_patch(Rectangle((bc_x, bc_y), bc_w, bc_h,
                            fc=COL_PLA, ec='black', lw=0.5, zorder=3))
    # Spiral groove indication
    for i in range(12):
        gx = bc_x + 15 + i * (bc_w - 30) / 11
        ax.plot([gx, gx + 8], [bc_y + 5, bc_y + bc_h - 5],
                color='#777', lw=0.3, zorder=4)
    ax.text(cx, bc_y + bc_h/2, 'BARREL CAM (270mm)', ha='center', va='center',
            fontsize=3.5, fontweight='bold', zorder=5)
    cn = next_callout()
    callout(ax, cn, (bc_x + bc_w, bc_y + bc_h/2),
            (bc_x + bc_w + 50, bc_y + bc_h/2 + 15), fontsize=4.5)

    # Pendulum (line + circle bob)
    pend_top_x = cx + 200
    pend_top_y = H_FRONT - EXTRUSION - 10
    pend_len = 250
    pend_bob_r = 15  # 30mm dia / 2
    ax.plot([pend_top_x, pend_top_x], [pend_top_y, pend_top_y - pend_len],
            color='black', lw=0.8, zorder=3)
    ax.add_patch(Circle((pend_top_x, pend_top_y - pend_len), pend_bob_r,
                         fc=COL_BRASS, ec='black', lw=0.4, zorder=4))
    ax.add_patch(Circle((pend_top_x, pend_top_y), 3, fc='black', ec='black', lw=0.3, zorder=4))
    ax.text(pend_top_x + 20, pend_top_y - pend_len/2, f'PENDULUM\n{pend_len}mm\nT=1.003s',
            fontsize=3, ha='left', va='center')
    cn = next_callout()
    callout(ax, cn, (pend_top_x, pend_top_y - pend_len),
            (pend_top_x + 45, pend_top_y - pend_len - 20), fontsize=4.5)

    # Shishi-odoshi (cam-triggered striker)
    ss_x = cx - 200
    ss_y = H_FRONT - 120
    # Striker arm
    ax.plot([ss_x, ss_x + 50], [ss_y, ss_y + 30], color='black', lw=1.0, zorder=3)
    ax.plot([ss_x + 50, ss_x + 50], [ss_y + 30, ss_y + 10], color='black', lw=0.6, zorder=3)
    # Anvil plate
    ax.add_patch(Rectangle((ss_x + 40, ss_y + 5), 20, 5,
                            fc=COL_BRASS, ec='black', lw=0.3, zorder=3))
    ax.add_patch(Circle((ss_x, ss_y), 3, fc='black', ec='black', lw=0.3, zorder=4))
    cn = next_callout()
    callout(ax, cn, (ss_x + 25, ss_y + 15), (ss_x - 30, ss_y + 40), fontsize=4.5)

    # Dog clutch (near motor)
    dc_x = cx - 80
    dc_y = motor_y + motor_h / 2
    ax.add_patch(Rectangle((dc_x - 15, dc_y - 9), 30, 18,
                            fc=COL_STEEL, ec='black', lw=0.4, zorder=3))
    # Teeth indication
    for t in range(4):
        tx = dc_x - 15 + t * 10
        ax.add_patch(Rectangle((tx, dc_y - 9), 3, 4, fc='#667788', ec='black', lw=0.2, zorder=4))
    cn = next_callout()
    callout(ax, cn, (dc_x, dc_y + 9), (dc_x - 30, dc_y + 30), fontsize=4.5)

    # Clamp bars (2, shown as horizontal lines across width)
    for cb_y, label in [(H_FRONT - 180, 'INPUT CLAMP'), (H_FRONT - 220, 'OUTPUT CLAMP')]:
        ax.plot([100, W_FRONT - 100], [cb_y, cb_y], color=COL_BRASS, lw=1.5, zorder=3)
        ax.plot([100, W_FRONT - 100], [cb_y, cb_y], color='black', lw=0.3, ls='--', zorder=4)
        ax.text(105, cb_y + 5, label, fontsize=2.5, color=COL_BRASS)
    cn = next_callout()
    callout(ax, cn, (W_FRONT - 100, H_FRONT - 180),
            (W_FRONT - 60, H_FRONT - 160), fontsize=4.5)

# ══════════════════════════════════════════════════════════════════════
#  BOTTOM VIEW
# ══════════════════════════════════════════════════════════════════════
def draw_bottom_view(ax):
    ax.set_xlim(-40, W_FRONT + 60)
    ax.set_ylim(-30, DEPTH + 50)
    ax.set_aspect('equal')
    ax.set_title('BOTTOM VIEW (Loss & Gradient)', fontsize=8, fontweight='bold', pad=8)
    ax.axis('off')

    # Frame
    ax.add_patch(Rectangle((0, 0), W_FRONT, DEPTH, lw=0.8, ec='black', fc='none'))

    cx = W_FRONT / 2
    cy = DEPTH / 2

    # Whippletree beams — 3 per-neuron + 1 aggregate
    beam_lengths = [80, 80, 80, 200]
    beam_ys = [cy - 60, cy - 30, cy, cy + 50]
    beam_labels = ['N1', 'N2', 'N3', 'AGG']
    for bl, by, lab in zip(beam_lengths, beam_ys, beam_labels):
        bx = cx - bl / 2
        ax.add_patch(Rectangle((bx, by - 2), bl, 4,
                                fc=COL_BRASS, ec='black', lw=0.4, zorder=3))
        # Pivot
        ax.add_patch(Circle((cx, by), 2.5, fc='black', ec='black', lw=0.3, zorder=4))
        ax.text(bx - 8, by, lab, ha='right', va='center', fontsize=3, fontweight='bold')

    cn = next_callout()
    callout(ax, cn, (cx + 100, beam_ys[3]), (cx + 140, beam_ys[3] + 20), fontsize=4.5)

    # Brachistochrone curve (parametric cycloid)
    # x = r(t - sin(t)), y = r(1 - cos(t))
    r_brach = 40  # radius parameter for visual scale
    t_brach = np.linspace(0, np.pi, 100)
    bx_curve = r_brach * (t_brach - np.sin(t_brach))
    by_curve = r_brach * (1 - np.cos(t_brach))

    # Position on the bottom view
    brach_offset_x = cx - 180
    brach_offset_y = cy + 100

    ax.plot(brach_offset_x + bx_curve, brach_offset_y - by_curve,
            color='black', lw=1.0, zorder=3)
    # Ball at some point along the curve
    ball_t = 0.3
    ball_x = brach_offset_x + r_brach * (ball_t * np.pi - np.sin(ball_t * np.pi))
    ball_y = brach_offset_y - r_brach * (1 - np.cos(ball_t * np.pi))
    ax.add_patch(Circle((ball_x, ball_y), 4, fc=COL_STEEL, ec='black', lw=0.4, zorder=4))

    # Cycloid equation label
    ax.text(brach_offset_x + r_brach * np.pi / 2, brach_offset_y - r_brach * 2 - 8,
            'x = r(t - sin t)\ny = r(1 - cos t)', fontsize=3, ha='center',
            va='top', fontstyle='italic', color='#444')

    cn = next_callout()
    callout(ax, cn, (brach_offset_x + r_brach * np.pi, brach_offset_y),
            (brach_offset_x + r_brach * np.pi + 40, brach_offset_y + 15), fontsize=4.5)

    # Scissor amplifier (5x)
    sci_x = cx + 100
    sci_y = cy + 100
    # Draw as a series of overlapping rhombi
    for si in range(3):
        sx = sci_x + si * 25
        diamond = Polygon([
            (sx, sci_y - 10), (sx + 12.5, sci_y),
            (sx + 25, sci_y - 10), (sx + 12.5, sci_y - 20)
        ], closed=True, fc=COL_PLA, ec='black', lw=0.3, alpha=0.6, zorder=3)
        ax.add_patch(diamond)
    ax.text(sci_x + 37.5, sci_y - 25, 'SCISSOR 5x', fontsize=3, ha='center')

    cn = next_callout()
    callout(ax, cn, (sci_x + 37.5, sci_y - 10), (sci_x + 80, sci_y), fontsize=4.5)

    # Convergence detector
    conv_x = cx + 200
    conv_y = cy - 50
    ax.add_patch(Rectangle((conv_x - 50, conv_y - 5), 100, 10,
                            fc=COL_STEEL, ec='black', lw=0.4, zorder=3))
    # 3 spring pins
    for pi_idx in range(3):
        px = conv_x - 30 + pi_idx * 30
        ax.plot([px, px], [conv_y + 5, conv_y + 15], color='black', lw=0.6, zorder=4)
        ax.add_patch(Circle((px, conv_y + 15), 2, fc=COL_STEEL, ec='black', lw=0.3, zorder=4))
    ax.text(conv_x, conv_y - 10, 'CONVERGENCE\nDETECTOR', fontsize=3, ha='center', va='top')
    cn = next_callout()
    callout(ax, cn, (conv_x + 50, conv_y), (conv_x + 80, conv_y + 20), fontsize=4.5)

    dim_line(ax, (0, 0), (W_FRONT, 0), -20, f'{W_FRONT}', horizontal=True)
    dim_line(ax, (0, 0), (0, DEPTH), -30, f'{DEPTH}', horizontal=False)

# ══════════════════════════════════════════════════════════════════════
#  BOM TABLE
# ══════════════════════════════════════════════════════════════════════
BOM_DATA = [
    ['1',  'Worm gear assembly',          '42', 'M1.0, 24dia x 20',       'Brass/Steel'],
    ['2',  'Spiral cam gradient computer', '42', '40dia x 15',             'SLA resin'],
    ['3',  'Rack-and-pinion updater',      '42', '0.5 mod, 8mm travel',    'Brass/Steel'],
    ['4',  'Pantograph diamond',           '9',  '70 x 40 (expanded)',     'PLA + HK0306'],
    ['5',  'Shaped cam (ReLU)',            '3',  '50dia x 10',             'SLA resin'],
    ['6',  'Clamp bar assembly',           '2',  '300 x 12',              'Brass/Steel'],
    ['7',  'Sliding collar differential',  '3',  'MGN7 rail 100mm',       'Steel/Brass'],
    ['8',  'Comparison beam',              '1',  '120 x 8 x 4',          'Brass'],
    ['9',  'Input word prism',             '3',  '40 face x 60 long',    'Brass'],
    ['10', 'Answer word prism',            '1',  '40 face x 60 long',    'Brass'],
    ['11', 'Convergence detector',         '1',  '3 pins + bar, 100 wide','Steel/Brass'],
    ['12', 'Pin drum',                     '1',  '70dia x 360',          'Brass'],
    ['13', 'Gravity pendulum',             '1',  '250 long, 30dia bob',  'Clock parts'],
    ['14', 'Barrel cam sequencer',         '1',  '40dia x 270',          'FDM PLA'],
    ['15', 'NEMA 23 stepper motor',        '1',  '57 x 57 x 56',        'Stock'],
    ['16', 'Whippletree beams',            '4',  '80-200 x 4 x 8',      'Brass'],
    ['17', 'Dog clutch collar',            '1',  '30 x 18dia',           'Steel'],
    ['18', 'Spring toggles',               '3',  '20 x 10',             'Steel'],
    ['19', 'String pulleys',               '~72','12dia',                'Brass/PLA'],
    ['20', 'Frame (2020 extrusion)',        '~12','20 x 20 x varies',    'Alum. (anod.)'],
    ['21', 'Acrylic panels',               '3-4','varies x 3 thick',    'Clear acrylic'],
    ['22', 'MGN7 linear rails',            '3-6','100mm',               'Stainless'],
    ['23', 'HK0306 needle bearings',       '~48','3mm bore, 6.5 OD',    'Steel'],
    ['24', 'Brachistochrone track',         '1',  'Cycloid, ~125mm arc', 'Brass'],
    ['25', 'Scissor amplifier (5x)',        '1',  'Mixed rhombi',        'PLA'],
]

# ══════════════════════════════════════════════════════════════════════
#  TITLE BLOCK
# ══════════════════════════════════════════════════════════════════════
def draw_title_block(ax):
    """Standard engineering title block."""
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis('off')

    # Border
    ax.add_patch(Rectangle((0.01, 0.05), 0.98, 0.90, lw=1.0, ec='black', fc='none'))

    # Dividers
    ax.plot([0.5, 0.5], [0.05, 0.95], color='black', lw=0.5)
    ax.plot([0.75, 0.75], [0.05, 0.95], color='black', lw=0.5)
    ax.plot([0.01, 0.99], [0.55, 0.55], color='black', lw=0.5)

    # Text
    ax.text(0.25, 0.82, 'THE PHYSICAL TRANSFORMER', ha='center', va='center',
            fontsize=9, fontweight='bold')
    ax.text(0.25, 0.70, 'Kinetic Neural Network Sculpture', ha='center', va='center',
            fontsize=6)
    ax.text(0.25, 0.40, 'GENERAL ASSEMBLY', ha='center', va='center',
            fontsize=7, fontweight='bold')
    ax.text(0.25, 0.25, 'Third-Angle Projection\n6-View Layout', ha='center', va='center',
            fontsize=5)
    ax.text(0.25, 0.12, f'Envelope: {W_FRONT} x {H_FRONT} x {DEPTH} mm\n'
            f'Weight: 8-12 kg   |   Material: PLA + Alum + Brass',
            ha='center', va='center', fontsize=4.5)

    ax.text(0.625, 0.82, 'Date: 2026-03-17', ha='center', va='center', fontsize=5)
    ax.text(0.625, 0.70, 'Spec: v2.0', ha='center', va='center', fontsize=5)
    ax.text(0.625, 0.40, 'Scale: NOT TO SCALE\n(proportional)', ha='center', va='center', fontsize=5)
    ax.text(0.625, 0.20, 'Tolerances:\nFDM: 0.2mm\nSLA: 0.05mm', ha='center', va='center', fontsize=4)

    ax.text(0.875, 0.82, 'Sheet 1 of 1', ha='center', va='center', fontsize=5)
    ax.text(0.875, 0.70, 'Drawing: GA-001', ha='center', va='center', fontsize=5)
    ax.text(0.875, 0.40, 'Units: mm', ha='center', va='center', fontsize=5, fontweight='bold')
    ax.text(0.875, 0.20, 'Trilogy Part III\nTriple Helix (I)\nMurmuration (II)\nTransformer (III)',
            ha='center', va='center', fontsize=3.5)

# ══════════════════════════════════════════════════════════════════════
#  MAIN FIGURE
# ══════════════════════════════════════════════════════════════════════
def main():
    # Layout: 4 rows x 4 cols grid
    # Row 0: [empty][TOP][empty][empty]
    # Row 1: [LEFT][FRONT][RIGHT][BACK]
    # Row 2: [empty][BOTTOM][empty][empty]
    # Row 3: [BOM table spanning all cols] + title block

    fig = plt.figure(figsize=(36, 42), facecolor='white', dpi=100)

    # Use gridspec for precise layout
    import matplotlib.gridspec as gridspec
    gs = gridspec.GridSpec(4, 4, figure=fig,
                           height_ratios=[1.0, 1.4, 1.0, 0.8],
                           width_ratios=[1.0, 2.0, 1.0, 2.0],
                           hspace=0.08, wspace=0.06)

    # TOP VIEW — row 0, col 1
    ax_top = fig.add_subplot(gs[0, 1])
    draw_top_view(ax_top)

    # LEFT VIEW — row 1, col 0
    ax_left = fig.add_subplot(gs[1, 0])
    draw_left_view(ax_left)

    # FRONT VIEW — row 1, col 1 (primary)
    ax_front = fig.add_subplot(gs[1, 1])
    draw_front_view(ax_front)

    # RIGHT VIEW — row 1, col 2
    ax_right = fig.add_subplot(gs[1, 2])
    draw_right_view(ax_right)

    # BACK VIEW — row 1, col 3
    ax_back = fig.add_subplot(gs[1, 3])
    draw_back_view(ax_back)

    # BOTTOM VIEW — row 2, col 1
    ax_bottom = fig.add_subplot(gs[2, 1])
    draw_bottom_view(ax_bottom)

    # BOM TABLE — row 3, cols 0-2
    ax_bom = fig.add_subplot(gs[3, 0:3])
    ax_bom.axis('off')
    ax_bom.set_title('BILL OF MATERIALS (25 Component Types)', fontsize=8,
                     fontweight='bold', pad=6)

    col_labels = ['#', 'Component', 'Qty', 'Size (mm)', 'Material']
    col_widths = [0.04, 0.32, 0.06, 0.30, 0.28]

    table = ax_bom.table(cellText=BOM_DATA, colLabels=col_labels,
                         colWidths=col_widths, loc='center', cellLoc='left')
    table.auto_set_font_size(False)
    table.set_fontsize(5.5)
    table.scale(1.0, 1.2)

    # Style header
    for j in range(len(col_labels)):
        cell = table[0, j]
        cell.set_facecolor('#333333')
        cell.set_text_props(color='white', fontweight='bold')
    # Alternate row shading
    for i in range(1, len(BOM_DATA) + 1):
        for j in range(len(col_labels)):
            cell = table[i, j]
            if i % 2 == 0:
                cell.set_facecolor('#f4f4f4')

    # TITLE BLOCK — row 3, col 3
    ax_title = fig.add_subplot(gs[3, 3])
    draw_title_block(ax_title)

    # ── Supertitle ────────────────────────────────────────────────
    fig.suptitle('THE PHYSICAL TRANSFORMER — GENERAL ASSEMBLY DRAWING GA-001',
                 fontsize=14, fontweight='bold', y=0.98)
    fig.text(0.5, 0.965,
             f'Envelope: {W_FRONT} x {H_FRONT} x {DEPTH} mm  |  '
             f'42 weights  |  3x3x3 topology  |  Single NEMA 23 motor  |  '
             f'Adjoint backpropagation',
             ha='center', fontsize=7, color='#555555')

    # ── Save outputs ──────────────────────────────────────────────
    out_dir = os.path.dirname(os.path.abspath(__file__))

    png_path = os.path.join(out_dir, 'GA_ASSEMBLY.png')
    fig.savefig(png_path, dpi=200, bbox_inches='tight', facecolor='white')
    print(f'[OK] PNG saved: {png_path}')

    svg_path = os.path.join(out_dir, 'GA_ASSEMBLY.svg')
    fig.savefig(svg_path, format='svg', bbox_inches='tight', facecolor='white')
    print(f'[OK] SVG saved: {svg_path}')

    # DXF export (simplified — outlines only)
    try:
        import ezdxf
        doc = ezdxf.new('R2010')
        msp = doc.modelspace()

        # Front view frame
        msp.add_lwpolyline([(0, 0), (W_FRONT, 0), (W_FRONT, H_FRONT),
                             (0, H_FRONT), (0, 0)], close=True,
                            dxfattribs={'layer': 'FRAME'})
        # Inner frame
        msp.add_lwpolyline([
            (EXTRUSION, EXTRUSION),
            (W_FRONT - EXTRUSION, EXTRUSION),
            (W_FRONT - EXTRUSION, H_FRONT - EXTRUSION),
            (EXTRUSION, H_FRONT - EXTRUSION),
            (EXTRUSION, EXTRUSION)
        ], close=True, dxfattribs={'layer': 'FRAME'})

        # Zone dividers
        msp.add_line((EXTRUSION, ZONE_MID_Y0), (W_FRONT - EXTRUSION, ZONE_MID_Y0),
                      dxfattribs={'layer': 'ZONES'})
        msp.add_line((EXTRUSION, ZONE_TOP_Y0), (W_FRONT - EXTRUSION, ZONE_TOP_Y0),
                      dxfattribs={'layer': 'ZONES'})

        # Worm gear circles (hidden layer)
        hid_xs_dxf = np.linspace(W_FRONT/2 - 120, W_FRONT/2 + 120, 10)
        hid_ys_dxf = [ZONE_TOP_Y1 - 30, ZONE_TOP_Y1 - 52, ZONE_TOP_Y1 - 74]
        for yy in hid_ys_dxf:
            for xx in hid_xs_dxf:
                msp.add_circle((xx, yy), 12, dxfattribs={'layer': 'WORM_GEARS'})

        # Output gears
        out_xs_dxf = np.linspace(W_FRONT/2 - 36, W_FRONT/2 + 36, 4)
        out_ys_dxf = [ZONE_TOP_Y1 - 104, ZONE_TOP_Y1 - 126, ZONE_TOP_Y1 - 148]
        for yy in out_ys_dxf:
            for xx in out_xs_dxf:
                msp.add_circle((xx, yy), 12, dxfattribs={'layer': 'WORM_GEARS'})

        # Spiral cam circles
        cam_x0_d = (W_FRONT - (6 * 55)) / 2
        cam_yc = (ZONE_MID_Y0 + ZONE_MID_Y1) / 2
        cam_y0_d = cam_yc - (5 * 40) / 2
        for row in range(6):
            for col in range(7):
                cx_d = cam_x0_d + col * 55
                cy_d = cam_y0_d + row * 40
                msp.add_circle((cx_d, cy_d), 20, dxfattribs={'layer': 'SPIRAL_CAMS'})

        # Error sliders (3 rails)
        slider_sp = 400 / 4
        sx0 = (W_FRONT - 400) / 2
        zbc = (ZONE_BOT_Y0 + ZONE_BOT_Y1) / 2
        for i in range(3):
            rx = sx0 + (i + 1) * slider_sp - 50
            ry = zbc + (i - 1) * 30
            msp.add_lwpolyline([(rx, ry), (rx + 100, ry), (rx + 100, ry + 3),
                                 (rx, ry + 3), (rx, ry)], close=True,
                                dxfattribs={'layer': 'SLIDERS'})

        # Title block text
        msp.add_text('THE PHYSICAL TRANSFORMER - GA-001',
                      dxfattribs={'layer': 'TITLE', 'height': 8}).set_placement((10, -20))
        msp.add_text(f'Envelope: {W_FRONT} x {H_FRONT} x {DEPTH} mm',
                      dxfattribs={'layer': 'TITLE', 'height': 5}).set_placement((10, -35))

        dxf_path = os.path.join(out_dir, 'GA_ASSEMBLY.dxf')
        doc.saveas(dxf_path)
        print(f'[OK] DXF saved: {dxf_path}')
    except Exception as e:
        print(f'[WARN] DXF export failed: {e}')

    plt.close(fig)
    print('\nDone. All outputs in:', out_dir)


if __name__ == '__main__':
    main()
