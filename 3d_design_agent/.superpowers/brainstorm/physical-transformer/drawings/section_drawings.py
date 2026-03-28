"""
Physical Transformer — Section Cut Assembly Drawings
=====================================================
Generates 3 cross-section views revealing internal mechanisms:
  A-A: Horizontal cut at y=300mm (string routing, top-down)
  B-B: Vertical cut at x=450mm (power train, side view)
  C-C: Detail — single neuron end-to-end (2:1 enlarged)

Output: SECTION_CUTS.png (200 DPI) and SECTION_CUTS.svg
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, Circle, Rectangle, Polygon, Arc
from matplotlib.lines import Line2D
from matplotlib.collections import PatchCollection, LineCollection
import matplotlib.patheffects as pe
from pathlib import Path

# ── Global Style ────────────────────────────────────────────────────────────
plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.size': 7,
    'axes.linewidth': 0.8,
    'figure.facecolor': 'white',
    'axes.facecolor': 'white',
})

COLOR_OUTLINE = '#000000'
COLOR_DIM = '#1a3a6e'        # dark blue for dimensions
COLOR_HIDDEN = '#888888'      # hidden lines
COLOR_HATCH_BRASS = '#c5a030' # gold/brass
COLOR_HATCH_STEEL = '#707070' # steel gray
COLOR_HATCH_PLA = '#2a2a2a'   # dark PLA
COLOR_STRING = '#cc3333'      # red-ish for string visibility
COLOR_SECTION_LINE = '#0055aa'
COLOR_FRAME = '#333333'


def draw_title_block(ax, title, scale, cut_label):
    """Draw title block in lower-right of axes."""
    bbox = ax.get_position()
    ax.text(0.98, 0.02, f'SECTION {cut_label}\n{title}\nScale {scale}',
            transform=ax.transAxes, fontsize=7, fontweight='bold',
            ha='right', va='bottom', fontfamily='monospace',
            bbox=dict(boxstyle='square,pad=0.3', facecolor='white',
                      edgecolor='black', linewidth=1.0))


def draw_dimension(ax, p1, p2, offset, text, horizontal=True, fontsize=6):
    """Draw a dimension line with arrows and text."""
    if horizontal:
        y = p1[1] + offset
        ax.annotate('', xy=(p1[0], y), xytext=(p2[0], y),
                     arrowprops=dict(arrowstyle='<->', color=COLOR_DIM, lw=0.7))
        ax.plot([p1[0], p1[0]], [p1[1], y], color=COLOR_DIM, lw=0.4, ls=':')
        ax.plot([p2[0], p2[0]], [p2[1], y], color=COLOR_DIM, lw=0.4, ls=':')
        ax.text((p1[0]+p2[0])/2, y+1, text, ha='center', va='bottom',
                fontsize=fontsize, color=COLOR_DIM, fontweight='bold')
    else:
        x = p1[0] + offset
        ax.annotate('', xy=(x, p1[1]), xytext=(x, p2[1]),
                     arrowprops=dict(arrowstyle='<->', color=COLOR_DIM, lw=0.7))
        ax.plot([p1[0], x], [p1[1], p1[1]], color=COLOR_DIM, lw=0.4, ls=':')
        ax.plot([p2[0], x], [p2[1], p2[1]], color=COLOR_DIM, lw=0.4, ls=':')
        ax.text(x+1, (p1[1]+p2[1])/2, text, ha='left', va='center',
                fontsize=fontsize, color=COLOR_DIM, fontweight='bold', rotation=90)


def draw_2020_section(ax, cx, cy, color=COLOR_FRAME):
    """Draw a 20x20 extrusion cross-section at (cx, cy)."""
    rect = Rectangle((cx-10, cy-10), 20, 20, linewidth=1.0,
                      edgecolor=COLOR_OUTLINE, facecolor='#e8e8e8')
    ax.add_patch(rect)
    # T-slot grooves (simplified)
    for dx in [-5, 5]:
        ax.plot([cx+dx, cx+dx], [cy-10, cy+10], color='#bbb', lw=0.4)
    for dy in [-5, 5]:
        ax.plot([cx-10, cx+10], [cy+dy, cy+dy], color='#bbb', lw=0.4)


def hatched_rect(ax, x, y, w, h, material='steel', label=None):
    """Draw a hatched rectangle for section cut material."""
    hatch_map = {
        'steel': ('///', COLOR_HATCH_STEEL, '#e0e0e0'),
        'brass': ('xxx', COLOR_HATCH_BRASS, '#f5e8b0'),
        'pla':   ('\\\\\\', COLOR_HATCH_PLA, '#d0d0d0'),
        'resin': ('...', '#999999', '#eaeaea'),
    }
    hatch, ec, fc = hatch_map.get(material, hatch_map['steel'])
    rect = Rectangle((x, y), w, h, linewidth=0.8, edgecolor=ec,
                      facecolor=fc, hatch=hatch, zorder=2)
    ax.add_patch(rect)
    if label:
        ax.text(x + w/2, y + h/2, label, ha='center', va='center',
                fontsize=5, fontweight='bold', zorder=3)


# ════════════════════════════════════════════════════════════════════════════
#  SECTION A-A: Horizontal cut at y=300mm, looking DOWN
# ════════════════════════════════════════════════════════════════════════════
def draw_section_AA(ax):
    """Top-down view revealing string routing at mid-height."""
    ax.set_xlim(-30, 950)
    ax.set_ylim(-30, 490)  # z-axis (depth) mapped to y
    ax.set_aspect('equal')
    ax.set_xlabel('X (mm) — Width', fontsize=7)
    ax.set_ylabel('Z (mm) — Depth', fontsize=7)

    # ── Outer frame (2020 extrusion cross-sections at corners) ──
    frame_corners = [(0, 0), (900, 0), (0, 450), (900, 450)]
    for cx, cy in frame_corners:
        draw_2020_section(ax, cx, cy)
    # Mid-frame members
    for cx in [300, 600]:
        draw_2020_section(ax, cx, 0)
        draw_2020_section(ax, cx, 450)

    # Frame outline (dashed for reference)
    frame = Rectangle((0, 0), 900, 450, linewidth=1.2,
                       edgecolor=COLOR_OUTLINE, facecolor='none', ls='--')
    ax.add_patch(frame)

    # ── Cutting plane indicator ──
    ax.text(460, 465, 'SECTION A-A  (y = 300 mm, looking DOWN)',
            ha='center', va='bottom', fontsize=8, fontweight='bold')

    # ── Barrel cam (center, running front-to-back) ──
    barrel_cx, barrel_cy = 450, 225
    barrel = Circle((barrel_cx, barrel_cy), 20, linewidth=1.0,
                     edgecolor=COLOR_OUTLINE, facecolor='#e8e8e8',
                     hatch='///', zorder=3)
    ax.add_patch(barrel)
    ax.text(barrel_cx, barrel_cy, 'BARREL\nCAM\n40dia', ha='center',
            va='center', fontsize=4.5, fontweight='bold', zorder=4)

    # ── Motor cross-section (57x57mm, bottom-back) ──
    motor_x, motor_z = 420, 370
    hatched_rect(ax, motor_x, motor_z, 57, 57, 'steel', 'NEMA 23\nMOTOR')

    # ── String Routing Plane 1: 30 input->hidden strings at z=20mm ──
    plane1_z = 20   # z position (mapped to y in this view)
    ax.axhline(y=plane1_z, color=COLOR_STRING, lw=0.3, ls=':', alpha=0.5)
    ax.text(10, plane1_z + 5, 'STRING PLANE 1 (z=20mm)', fontsize=5,
            color=COLOR_STRING, fontstyle='italic')

    # Worm gear x-positions on front face (z=0 edge)
    hidden_gear_x = np.linspace(330, 570, 10)  # 10 worm gears for hidden layer
    # Each gear connects to 3 hidden neurons => 30 strings
    pulley_x = 860  # near right edge
    pulley_z = plane1_z

    # Pantograph input z-positions on right face (x=900 edge)
    panto_z = np.linspace(80, 350, 9)  # 9 inputs per hidden neuron (3 neurons x 3 inputs each)

    # Draw worm gear positions on front face
    for i, gx in enumerate(hidden_gear_x):
        gear_circle = Circle((gx, 5), 4, linewidth=0.6,
                              edgecolor=COLOR_HATCH_BRASS, facecolor=COLOR_HATCH_BRASS,
                              alpha=0.7, zorder=5)
        ax.add_patch(gear_circle)

    # Draw string routing: gear -> pulley corner -> pantograph
    for i, gx in enumerate(hidden_gear_x):
        for j in range(3):  # 3 hidden neurons
            target_z = panto_z[i % 9]
            # Pulley position (staggered slightly to show routing)
            py = pulley_z + j * 8
            px = pulley_x - j * 5

            # String path: worm gear -> straight to pulley -> 90-deg turn -> pantograph
            string_x = [gx, px, 900]
            string_z = [plane1_z, py, target_z]
            ax.plot(string_x, string_z, color=COLOR_STRING, lw=0.25,
                    alpha=0.4, zorder=2)

            # Pulley at corner
            pulley = Circle((px, py), 3, linewidth=0.4,
                             edgecolor='#666', facecolor='white', zorder=4)
            ax.add_patch(pulley)

    # ── String Routing Plane 2: 12 hidden->output strings at z=45mm ──
    plane2_z = 45
    ax.axhline(y=plane2_z, color='#3366cc', lw=0.3, ls=':', alpha=0.5)
    ax.text(10, plane2_z + 5, 'STRING PLANE 2 (z=45mm)', fontsize=5,
            color='#3366cc', fontstyle='italic')

    # Output worm gears (4 gears centered)
    output_gear_x = np.linspace(414, 486, 4)
    for gx in output_gear_x:
        gear_circle = Circle((gx, 5), 3.5, linewidth=0.6,
                              edgecolor='#997722', facecolor='#997722',
                              alpha=0.7, zorder=5)
        ax.add_patch(gear_circle)

    # 12 output strings within right face zone
    output_panto_z = np.linspace(100, 300, 12)
    for i, gx in enumerate(output_gear_x):
        for j in range(3):
            idx = i * 3 + j
            if idx < 12:
                sz = output_panto_z[idx]
                ax.plot([gx, 870, 900], [plane2_z, plane2_z, sz],
                        color='#3366cc', lw=0.3, alpha=0.5, zorder=2)

    # ── Clamp bars (perpendicular to strings) ──
    # Input clamp bar near front face
    hatched_rect(ax, 280, 10, 340, 12, 'brass', 'INPUT CLAMP BAR')
    # Output clamp bar near right face
    hatched_rect(ax, 840, 60, 12, 280, 'brass')
    ax.text(846, 200, 'OUTPUT\nCLAMP\nBAR', fontsize=4, ha='center',
            va='center', rotation=90, fontweight='bold', zorder=5)

    # ── Depth separation annotation ──
    draw_dimension(ax, (200, plane1_z), (200, plane2_z), -40, '25mm sep.',
                   horizontal=False, fontsize=5)

    # ── Frame dimensions ──
    draw_dimension(ax, (0, 0), (900, 0), -22, '900mm', fontsize=6)
    draw_dimension(ax, (0, 0), (0, 450), -22, '450mm', horizontal=False, fontsize=6)

    # ── Legend ──
    legend_elements = [
        Line2D([0], [0], color=COLOR_STRING, lw=1, label='Input strings (Plane 1, z=20)'),
        Line2D([0], [0], color='#3366cc', lw=1, label='Output strings (Plane 2, z=45)'),
        Line2D([0], [0], marker='o', color='w', markerfacecolor=COLOR_HATCH_BRASS,
               markersize=5, label='Worm gear (brass)', lw=0),
        Line2D([0], [0], marker='o', color='w', markerfacecolor='white',
               markeredgecolor='#666', markersize=5, label='Pulley (12mm dia)', lw=0),
    ]
    ax.legend(handles=legend_elements, loc='upper left', fontsize=5,
              framealpha=0.9, edgecolor='black')

    draw_title_block(ax, 'String Routing Layout', '1:1', 'A-A')


# ════════════════════════════════════════════════════════════════════════════
#  SECTION B-B: Vertical cut at x=450mm, looking LEFT
# ════════════════════════════════════════════════════════════════════════════
def draw_section_BB(ax):
    """Side view revealing power train from motor to worm gears."""
    ax.set_xlim(-30, 490)   # z-axis (depth)
    ax.set_ylim(-30, 680)   # y-axis (height)
    ax.set_aspect('equal')
    ax.set_xlabel('Z (mm) — Depth', fontsize=7)
    ax.set_ylabel('Y (mm) — Height', fontsize=7)

    ax.text(230, 665, 'SECTION B-B  (x = 450 mm, looking LEFT)',
            ha='center', va='bottom', fontsize=8, fontweight='bold')

    # ── Frame outline ──
    frame = Rectangle((0, 0), 450, 600, linewidth=1.2,
                       edgecolor=COLOR_OUTLINE, facecolor='none', ls='--')
    ax.add_patch(frame)

    # 2020 extrusion sections at corners
    for z in [0, 450]:
        for y in [0, 600]:
            draw_2020_section(ax, z, y)

    # ── NEMA 23 Motor (bottom-back) ──
    motor_z, motor_y = 370, 30
    hatched_rect(ax, motor_z, motor_y, 57, 56, 'steel', 'NEMA 23\n57x56')
    # Motor shaft
    ax.plot([motor_z, 50], [motor_y + 28, motor_y + 28], color=COLOR_OUTLINE,
            lw=1.5, zorder=3)
    ax.text(250, motor_y + 28 + 8, 'MAIN SHAFT', fontsize=5, ha='center',
            color=COLOR_DIM, fontstyle='italic')

    # ── Barrel cam (center, on main shaft) ──
    cam_cz, cam_cy = 200, motor_y + 28
    # Show profile view with spiral groove indication
    barrel_rect = Rectangle((cam_cz - 135, cam_cy - 20), 270, 40,
                             linewidth=1.0, edgecolor=COLOR_OUTLINE,
                             facecolor='#e0e0e0', hatch='\\\\\\', zorder=2)
    ax.add_patch(barrel_rect)
    # Spiral groove hint
    theta_b = np.linspace(0, 6*np.pi, 300)
    groove_z = cam_cz - 135 + np.linspace(0, 270, 300)
    groove_y = cam_cy + 12 * np.sin(theta_b)
    ax.plot(groove_z, groove_y, color='#555', lw=0.5, zorder=3)
    ax.text(cam_cz, cam_cy, 'BARREL CAM (40dia x 270)', ha='center',
            va='center', fontsize=5, fontweight='bold', zorder=4)

    # ── Pendulum (hanging from top rail) ──
    pend_z = 350
    pend_top = 580  # below top rail
    pend_len = 250
    pend_bot = pend_top - pend_len
    # Shaft
    ax.plot([pend_z, pend_z], [pend_top, pend_bot], color=COLOR_OUTLINE,
            lw=1.2, zorder=3)
    # Pivot at top
    ax.plot(pend_z, pend_top, 'k^', markersize=6, zorder=4)
    # Bob at bottom
    bob = Circle((pend_z, pend_bot), 15, linewidth=1.0,
                  edgecolor=COLOR_OUTLINE, facecolor=COLOR_HATCH_BRASS,
                  hatch='xxx', zorder=3)
    ax.add_patch(bob)
    ax.text(pend_z + 20, (pend_top + pend_bot)/2, 'PENDULUM\n250mm\n30mm bob',
            fontsize=5, ha='left', va='center', color=COLOR_DIM)
    # Swing arc (dashed)
    swing_angle = 15
    for sign in [-1, 1]:
        angle_rad = np.radians(sign * swing_angle)
        bx = pend_z + pend_len * np.sin(angle_rad)
        by = pend_top - pend_len * np.cos(angle_rad)
        ax.plot([pend_z, bx], [pend_top, by], color=COLOR_HIDDEN,
                lw=0.5, ls='--')

    # ── Clamp bar cam lobes (on main shaft) ──
    for i, (lobe_z, label) in enumerate([(100, 'INPUT\nCLAMP\nCAM'), (140, 'OUTPUT\nCLAMP\nCAM')]):
        # Eccentric circle
        ecc = Circle((lobe_z, motor_y + 28), 14, linewidth=0.8,
                       edgecolor=COLOR_OUTLINE, facecolor='#f0e0b0',
                       hatch='xxx', zorder=3)
        ax.add_patch(ecc)
        # Eccentric offset shown
        ax.plot(lobe_z + 3, motor_y + 28 + 2, 'k+', markersize=4, zorder=4)
        ax.text(lobe_z, motor_y + 28 - 22, label, fontsize=4, ha='center',
                va='top', fontweight='bold')

    # ── Worm gear cross-section (front face center) ──
    worm_cz = 20   # near front face (z~0)
    worm_cy = 300   # mid-height

    # Worm (circle cross-section)
    worm_pitch_dia = 10
    wheel_teeth = 20
    wheel_pitch_dia = wheel_teeth * 1.0
    center_distance = (worm_pitch_dia + wheel_pitch_dia) / 2

    # Worm circle
    theta = np.linspace(0, 2*np.pi, 100)
    worm_x = worm_pitch_dia/2 * np.cos(theta) + worm_cz
    worm_y = worm_pitch_dia/2 * np.sin(theta) + worm_cy
    ax.fill(worm_x, worm_y, color='#e0e0e0', zorder=3)
    ax.plot(worm_x, worm_y, color=COLOR_OUTLINE, lw=1.0, zorder=4)
    # Thread lines on worm
    for offset in np.linspace(-4, 4, 5):
        ax.plot([worm_cz + offset - 1, worm_cz + offset + 1],
                [worm_cy - 5, worm_cy + 5],
                color='#888', lw=0.4, zorder=4)

    # Wheel (larger circle, meshing)
    wheel_cx = worm_cz
    wheel_cy = worm_cy - center_distance
    wheel_x = wheel_pitch_dia/2 * np.cos(theta) + wheel_cx
    wheel_y = wheel_pitch_dia/2 * np.sin(theta) + wheel_cy
    ax.fill(wheel_x, wheel_y, color='#f5e8b0', zorder=2)
    ax.plot(wheel_x, wheel_y, color=COLOR_OUTLINE, lw=1.0, zorder=3)
    # Tooth hint
    for t in np.linspace(0, 2*np.pi, wheel_teeth, endpoint=False):
        tx = wheel_pitch_dia/2 * 1.15 * np.cos(t) + wheel_cx
        ty = wheel_pitch_dia/2 * 1.15 * np.sin(t) + wheel_cy
        ax.plot([wheel_cx + (wheel_pitch_dia/2)*np.cos(t),  tx],
                [wheel_cy + (wheel_pitch_dia/2)*np.sin(t),  ty],
                color=COLOR_OUTLINE, lw=0.3, zorder=3)

    ax.text(worm_cz + 18, worm_cy + 5, 'WORM\nM1.0', fontsize=5,
            ha='left', fontweight='bold', color=COLOR_DIM)
    ax.text(wheel_cx + 18, wheel_cy, f'WHEEL\n{wheel_teeth}T', fontsize=5,
            ha='left', fontweight='bold', color=COLOR_DIM)

    # ── Archimedean spiral cam (below worm gear) ──
    cam_cx = 30
    cam_cy_sc = 200
    r_min = 1.0 * 2  # scaled for visibility
    r_max = 6.0 * 2
    theta_max = 254 * np.pi / 180
    theta_cam = np.linspace(0, theta_max, 200)
    r_cam = r_min + (r_max - r_min) * theta_cam / theta_max
    spiral_x = r_cam * np.cos(theta_cam) + cam_cx
    spiral_y = r_cam * np.sin(theta_cam) + cam_cy_sc

    # Cam body circle
    cam_body = Circle((cam_cx, cam_cy_sc), r_max + 2, linewidth=0.8,
                        edgecolor=COLOR_OUTLINE, facecolor='#eaeaea',
                        hatch='...', zorder=2)
    ax.add_patch(cam_body)
    ax.plot(spiral_x, spiral_y, color='#cc4444', lw=1.2, zorder=3)
    ax.text(cam_cx + 16, cam_cy_sc, 'SPIRAL CAM\n40dia\nArchimedean',
            fontsize=4.5, ha='left', fontweight='bold', color=COLOR_DIM)

    # ── Rack-and-pinion (connecting spiral cam to worm) ──
    rack_z = 25
    ax.plot([rack_z, rack_z], [cam_cy_sc + 15, worm_cy - center_distance - 12],
            color=COLOR_OUTLINE, lw=1.5, zorder=2)
    # Rack teeth
    for ry in np.linspace(cam_cy_sc + 20, worm_cy - center_distance - 15, 12):
        ax.plot([rack_z - 3, rack_z + 3], [ry, ry], color=COLOR_OUTLINE, lw=0.5)
    ax.text(rack_z + 8, (cam_cy_sc + worm_cy)/2, 'RACK\n& PINION',
            fontsize=4.5, ha='left', color=COLOR_DIM, fontweight='bold')

    # ── Pin drum (above frame) ──
    drum_cz = 225
    drum_cy = 630
    drum = Circle((drum_cz, drum_cy), 35, linewidth=1.0,
                    edgecolor=COLOR_OUTLINE, facecolor='#f5e8b0',
                    hatch='xxx', zorder=3)
    ax.add_patch(drum)
    # Pin dots
    for t in np.linspace(0, 2*np.pi, 12, endpoint=False):
        px = drum_cz + 30 * np.cos(t)
        py = drum_cy + 30 * np.sin(t)
        ax.plot(px, py, 'k.', markersize=2, zorder=4)
    ax.text(drum_cz, drum_cy, 'PIN DRUM\n70dia', ha='center', va='center',
            fontsize=5, fontweight='bold', zorder=4)

    # ── Whippletree beams (bottom) ──
    for i, (bz, blen) in enumerate([(100, 80), (200, 120), (300, 200)]):
        by = 80 + i * 30
        # Beam
        ax.plot([bz - blen/2, bz + blen/2], [by, by], color=COLOR_HATCH_BRASS,
                lw=2.5, zorder=3)
        # Pivot (triangle)
        ax.plot(bz, by, 'k^', markersize=5, zorder=4)
        if i == 0:
            ax.text(bz, by - 10, f'WHIPPLETREE\n{blen}mm', fontsize=4,
                    ha='center', va='top', color=COLOR_DIM)

    # ── Shishi-odoshi striker ──
    ax.annotate('SHISHI-ODOSHI\nSTRIKER', xy=(380, 120), fontsize=4.5,
                ha='center', color=COLOR_DIM, fontweight='bold')
    # Arm
    ax.plot([360, 400], [130, 110], color=COLOR_OUTLINE, lw=1.5)
    ax.plot(360, 130, 'ko', markersize=3)  # pivot
    hatched_rect(ax, 395, 100, 15, 10, 'brass')  # anvil

    # ── Dimensions ──
    draw_dimension(ax, (0, 0), (450, 0), -22, '450mm', fontsize=6)
    draw_dimension(ax, (0, 0), (0, 600), -22, '600mm', horizontal=False, fontsize=6)
    draw_dimension(ax, (0, 600), (0, 660), 30, '60mm\npin drum', horizontal=False, fontsize=5)

    draw_title_block(ax, 'Power Train Layout', '1:1', 'B-B')


# ════════════════════════════════════════════════════════════════════════════
#  SECTION C-C: Detail — Single Neuron End-to-End (2:1 enlarged)
# ════════════════════════════════════════════════════════════════════════════
def draw_section_CC(ax):
    """Enlarged detail: one complete signal path through the machine."""
    # Working in "real mm" but displayed at 2:1
    ax.set_xlim(-10, 420)
    ax.set_ylim(-60, 120)
    ax.set_aspect('equal')
    ax.set_xlabel('Signal path (mm, 2:1 scale)', fontsize=7)

    ax.text(210, 110, 'SECTION C-C  Detail: Single Neuron Signal Path  (Scale 2:1)',
            ha='center', va='bottom', fontsize=8, fontweight='bold')

    x_cursor = 0  # running x position for the signal chain

    # ── 1. Worm gear assembly ──
    worm_cx = 25
    worm_cy = 30
    # Worm (helical profile - show as circle with thread lines)
    worm_r = 10
    theta = np.linspace(0, 2*np.pi, 100)
    ax.fill(worm_r * np.cos(theta) + worm_cx,
            worm_r * np.sin(theta) + worm_cy,
            color='#e0e0e0', zorder=3)
    ax.plot(worm_r * np.cos(theta) + worm_cx,
            worm_r * np.sin(theta) + worm_cy,
            color=COLOR_OUTLINE, lw=1.2, zorder=4)
    # Helical thread lines
    for off in np.linspace(-8, 8, 7):
        y_off = worm_cy + off
        half_w = np.sqrt(max(0, worm_r**2 - off**2))
        if half_w > 1:
            ax.plot([worm_cx - half_w*0.6, worm_cx + half_w*0.6],
                    [y_off - 2, y_off + 2], color='#777', lw=0.5, zorder=4)

    # Wheel
    wheel_r = 12
    wheel_cx = worm_cx
    wheel_cy = worm_cy - worm_r - wheel_r + 3  # meshing
    ax.fill(wheel_r * np.cos(theta) + wheel_cx,
            wheel_r * np.sin(theta) + wheel_cy,
            color='#f5e8b0', zorder=2)
    ax.plot(wheel_r * np.cos(theta) + wheel_cx,
            wheel_r * np.sin(theta) + wheel_cy,
            color=COLOR_OUTLINE, lw=1.0, zorder=3)
    # Teeth
    for t in np.linspace(0, 2*np.pi, 20, endpoint=False):
        tx = (wheel_r + 2) * np.cos(t) + wheel_cx
        ty = (wheel_r + 2) * np.sin(t) + wheel_cy
        ax.plot([wheel_cx + wheel_r*np.cos(t), tx],
                [wheel_cy + wheel_r*np.sin(t), ty],
                color=COLOR_OUTLINE, lw=0.4, zorder=3)

    ax.text(worm_cx, worm_cy + 16, 'WORM\nM1.0', fontsize=5, ha='center',
            fontweight='bold', color=COLOR_DIM)
    ax.text(wheel_cx, wheel_cy - 16, 'WHEEL 20T', fontsize=5, ha='center',
            fontweight='bold', color=COLOR_DIM)

    # ── 2. String from worm gear to pulley ──
    string_start_x = worm_cx + worm_r + 2
    string_y = worm_cy
    pulley_cx = 90
    pulley_cy = string_y
    pulley_r = 6  # 12mm dia

    # String line
    ax.plot([string_start_x, pulley_cx - pulley_r],
            [string_y, pulley_cy],
            color=COLOR_STRING, lw=1.0, zorder=5)
    ax.text((string_start_x + pulley_cx)/2, string_y + 5,
            '0.5mm SS wire', fontsize=4.5, ha='center', color=COLOR_STRING,
            fontstyle='italic')

    # Pulley
    pulley = Circle((pulley_cx, pulley_cy), pulley_r, linewidth=1.0,
                      edgecolor=COLOR_OUTLINE, facecolor='white', zorder=4)
    ax.add_patch(pulley)
    # Axle
    ax.plot(pulley_cx, pulley_cy, 'k+', markersize=6, zorder=5)
    ax.text(pulley_cx, pulley_cy - pulley_r - 5, 'PULLEY\n12dia',
            fontsize=4.5, ha='center', va='top', color=COLOR_DIM, fontweight='bold')

    # String continues from pulley to pantograph
    panto_start_x = 130
    ax.plot([pulley_cx + pulley_r, panto_start_x],
            [pulley_cy, 30], color=COLOR_STRING, lw=1.0, zorder=5)

    # ── 3. Pantograph diamond (rhombus) ──
    L = 35  # arm length
    alpha = np.radians(30)
    px0 = panto_start_x
    py0 = 30  # center height

    # Diamond vertices
    verts = np.array([
        [px0, py0],                                          # left (input A)
        [px0 + L*np.cos(alpha), py0 + L*np.sin(alpha)],     # top
        [px0 + 2*L*np.cos(alpha), py0],                     # right (output C)
        [px0 + L*np.cos(alpha), py0 - L*np.sin(alpha)],     # bottom (input B)
    ])

    diamond = Polygon(verts, closed=True, linewidth=1.5,
                       edgecolor=COLOR_OUTLINE, facecolor='#f0f0f0', zorder=3)
    ax.add_patch(diamond)

    # Arms as thick lines
    for i in range(4):
        j = (i + 1) % 4
        ax.plot([verts[i, 0], verts[j, 0]], [verts[i, 1], verts[j, 1]],
                color=COLOR_OUTLINE, lw=2.0, zorder=4)

    # HK0306 bearings at each joint (6.5mm OD)
    bearing_r = 3.25
    for i, (bx, by) in enumerate(verts):
        bearing = Circle((bx, by), bearing_r, linewidth=0.8,
                          edgecolor=COLOR_OUTLINE, facecolor='#ddd',
                          hatch='xx', zorder=5)
        ax.add_patch(bearing)
    ax.text(verts[0, 0], verts[0, 1] - 10, 'HK0306\n6.5 OD', fontsize=4,
            ha='center', va='top', color=COLOR_DIM)

    # Labels
    ax.text(verts[0, 0] - 5, verts[0, 1], 'A', fontsize=7, ha='right',
            fontweight='bold', color='#cc0000')
    ax.text(verts[3, 0], verts[3, 1] - 8, 'B', fontsize=7, ha='center',
            fontweight='bold', color='#cc0000')
    ax.text(verts[2, 0] + 5, verts[2, 1], 'C', fontsize=7, ha='left',
            fontweight='bold', color='#0066cc')
    ax.text(px0 + L*np.cos(alpha), py0 + L*np.sin(alpha) + 8,
            'PANTOGRAPH\nOA+OB=OC', fontsize=5, ha='center', va='bottom',
            fontweight='bold', color=COLOR_DIM)

    # Dimension: arm length
    draw_dimension(ax, (verts[0, 0], verts[0, 1]),
                   (verts[1, 0], verts[1, 1]), -15,
                   f'L={L}mm', horizontal=True, fontsize=5)

    # ── 4. ReLU cam (shaped cam) ──
    relu_cx = verts[2, 0] + 40
    relu_cy = 30
    relu_r_base = 20

    # ReLU cam profile
    theta_relu = np.linspace(0, 2*np.pi, 360)
    r_relu = np.zeros_like(theta_relu)
    for k, t in enumerate(theta_relu):
        if t < np.pi:  # flat region (dead zone = inactive)
            r_relu[k] = relu_r_base
        else:  # linear ramp (active region)
            r_relu[k] = relu_r_base + 5 * (t - np.pi) / np.pi

    cam_x = r_relu * np.cos(theta_relu) + relu_cx
    cam_y = r_relu * np.sin(theta_relu) + relu_cy

    ax.fill(cam_x, cam_y, color='#eaeaea', hatch='...', zorder=2)
    ax.plot(cam_x, cam_y, color=COLOR_OUTLINE, lw=1.2, zorder=3)
    # Center
    ax.plot(relu_cx, relu_cy, 'k+', markersize=5, zorder=4)
    # Follower position
    follower_angle = np.pi * 1.5  # on the ramp
    fr = relu_r_base + 5 * (follower_angle - np.pi) / np.pi
    fx = fr * np.cos(follower_angle) + relu_cx
    fy = fr * np.sin(follower_angle) + relu_cy
    ax.plot(fx, fy, 'ko', markersize=4, zorder=5)
    ax.plot([relu_cx, fx], [relu_cy, fy], color=COLOR_HIDDEN, lw=0.5, ls='--')

    # Labels
    ax.text(relu_cx, relu_cy + relu_r_base + 10, 'ReLU CAM\n50dia (SLA resin)',
            fontsize=5, ha='center', fontweight='bold', color=COLOR_DIM)
    # Annotate regions
    ax.annotate('DEAD\nZONE', xy=(relu_cx - relu_r_base - 3, relu_cy),
                fontsize=4, ha='right', color='#cc0000', fontweight='bold')
    ax.annotate('RAMP\n(active)', xy=(relu_cx + relu_r_base + 5, relu_cy - 5),
                fontsize=4, ha='left', color='#006600', fontweight='bold')

    # String from pantograph output to ReLU cam
    ax.plot([verts[2, 0] + bearing_r, relu_cx - relu_r_base],
            [verts[2, 1], relu_cy], color=COLOR_STRING, lw=1.0, zorder=5)

    # ── 5. Spring toggle (bistable mechanism) ──
    toggle_cx = relu_cx + 45
    toggle_cy = 30
    # Simplified bistable: two angled springs meeting at center
    ax.plot([toggle_cx - 12, toggle_cx, toggle_cx + 12],
            [toggle_cy + 8, toggle_cy - 3, toggle_cy + 8],
            color=COLOR_OUTLINE, lw=1.5, zorder=3)
    # Spring zigzag
    spring_x = np.array([toggle_cx - 12, toggle_cx - 9, toggle_cx - 6,
                          toggle_cx - 3, toggle_cx])
    spring_y = toggle_cy + 8 + np.array([0, 3, -3, 3, -8-3])
    # Fixed points
    ax.plot(toggle_cx - 12, toggle_cy + 8, 'ks', markersize=4, zorder=4)
    ax.plot(toggle_cx + 12, toggle_cy + 8, 'ks', markersize=4, zorder=4)
    ax.plot(toggle_cx, toggle_cy - 3, 'ko', markersize=4, zorder=4)
    ax.text(toggle_cx, toggle_cy + 18, 'SPRING\nTOGGLE\n(SNAP)', fontsize=4.5,
            ha='center', fontweight='bold', color=COLOR_DIM)

    # ── 6. Output string to next stage ──
    out_start_x = toggle_cx + 15
    ax.plot([out_start_x, out_start_x + 50], [30, 30],
            color=COLOR_STRING, lw=1.0, zorder=5)
    ax.annotate('', xy=(out_start_x + 50, 30), xytext=(out_start_x + 40, 30),
                arrowprops=dict(arrowstyle='->', color=COLOR_STRING, lw=1.5))
    ax.text(out_start_x + 25, 35, 'TO NEXT\nPANTOGRAPH', fontsize=4.5,
            ha='center', color=COLOR_STRING, fontweight='bold')

    # ── Signal flow arrow along bottom ──
    ax.annotate('', xy=(400, -35), xytext=(10, -35),
                arrowprops=dict(arrowstyle='->', color='#444', lw=1.5))
    labels_flow = ['WEIGHT\n(worm gear)', 'ROUTE\n(string+pulley)',
                   'SUM\n(pantograph)', 'ACTIVATE\n(ReLU cam)',
                   'FIRE\n(toggle)', 'OUTPUT\n(string)']
    positions = [25, 80, 170, 270, 330, 380]
    for lbl, px in zip(labels_flow, positions):
        ax.text(px, -45, lbl, fontsize=4.5, ha='center', va='top',
                fontweight='bold', color='#444')

    draw_title_block(ax, 'Single Neuron E2E', '2:1', 'C-C')


# ════════════════════════════════════════════════════════════════════════════
#  MAIN — Compose all three sections
# ════════════════════════════════════════════════════════════════════════════
def main():
    fig = plt.figure(figsize=(22, 30), dpi=100)

    # Layout: A-A on top (wide), B-B bottom-left, C-C bottom-right
    gs = fig.add_gridspec(3, 2, height_ratios=[1.0, 1.2, 0.6],
                          hspace=0.25, wspace=0.2,
                          left=0.05, right=0.95, top=0.96, bottom=0.03)

    # Section A-A (top, spans both columns)
    ax_aa = fig.add_subplot(gs[0, :])
    draw_section_AA(ax_aa)
    ax_aa.grid(True, alpha=0.15, lw=0.3)

    # Section B-B (middle-left)
    ax_bb = fig.add_subplot(gs[1, 0])
    draw_section_BB(ax_bb)
    ax_bb.grid(True, alpha=0.15, lw=0.3)

    # Section C-C (middle-right + bottom-right combined)
    ax_cc = fig.add_subplot(gs[1:, 1])
    draw_section_CC(ax_cc)
    ax_cc.grid(True, alpha=0.15, lw=0.3)

    # Overall title
    fig.suptitle('THE PHYSICAL TRANSFORMER\nSection Cut Assembly Drawings',
                 fontsize=16, fontweight='bold', y=0.99)
    fig.text(0.5, 0.965,
             '900 x 600 x 450 mm  |  42 weights  |  Single NEMA 23  |  All dimensions in mm',
             ha='center', fontsize=9, fontstyle='italic', color='#555')

    # Save
    out_dir = Path(r'd:\Claude local\3d_design_agent\.superpowers\brainstorm\physical-transformer\drawings')
    out_dir.mkdir(parents=True, exist_ok=True)

    png_path = out_dir / 'SECTION_CUTS.png'
    svg_path = out_dir / 'SECTION_CUTS.svg'

    fig.savefig(str(png_path), dpi=200, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    print(f'Saved PNG: {png_path}')

    fig.savefig(str(svg_path), format='svg', bbox_inches='tight',
                facecolor='white', edgecolor='none')
    print(f'Saved SVG: {svg_path}')

    plt.close(fig)
    print('Done.')


if __name__ == '__main__':
    main()
