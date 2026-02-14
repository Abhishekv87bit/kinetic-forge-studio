"""
Quick Four-Bar Linkage Tester
=============================
No Jupyter required. Just run this script and change the numbers.

Usage:
    python linkage_quick_test.py

Requirements:
    pip install matplotlib numpy
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import sys

# ============================================================
# CHANGE THESE NUMBERS TO TEST DIFFERENT LINKAGES
# ============================================================

GROUND  = 100   # Distance between fixed pivots (mm)
CRANK   = 30    # Input arm - motor drives this
COUPLER = 80    # The floating bar
ROCKER  = 70    # Output arm - your sculpture element

COUPLER_POINT = 0.5  # Where to trace on coupler (0=B, 1=C, >1=extended)

# Common recipes to try:
# Gentle sway:    100, 15, 85, 95,  point=0.5
# Ocean wave:     100, 25, 90, 80,  point=0.4
# Figure-8:       100, 45, 120, 70, point=0.5
# Wild curves:    100, 35, 95, 80,  point=1.5
# Hammering:      100, 40, 85, 60,  point=0.8

# ============================================================


class FourBarLinkage:
    def __init__(self, ground, crank, coupler, rocker):
        self.ground = ground
        self.crank = crank
        self.coupler = coupler
        self.rocker = rocker
        self.A = np.array([0.0, 0.0])
        self.D = np.array([ground, 0.0])

    def check_grashof(self):
        """Check if linkage can rotate fully."""
        lengths = sorted([self.ground, self.crank, self.coupler, self.rocker])
        shortest, second, third, longest = lengths

        if shortest + longest < second + third:
            if self.crank == shortest:
                return True, "CRANK-ROCKER: Motor can spin continuously. Perfect!"
            elif self.ground == shortest:
                return True, "DOUBLE-CRANK: Both rotate fully. Works but unusual."
            else:
                return True, "ROCKER-CRANK or DOUBLE-ROCKER: May need oscillating input."
        else:
            return False, "NON-GRASHOF: Motor CANNOT spin continuously. Redesign needed!"

    def solve(self, crank_angle_deg):
        """Get all joint positions for given crank angle."""
        theta = np.radians(crank_angle_deg)
        B = self.A + self.crank * np.array([np.cos(theta), np.sin(theta)])

        # Circle-circle intersection to find C
        BD = self.D - B
        d = np.linalg.norm(BD)

        if d > self.coupler + self.rocker or d < abs(self.coupler - self.rocker):
            return None

        a = (self.coupler**2 - self.rocker**2 + d**2) / (2 * d)
        h_sq = self.coupler**2 - a**2
        if h_sq < 0:
            return None

        h = np.sqrt(h_sq)
        P = B + a * BD / d
        perp = np.array([-BD[1], BD[0]]) / d
        C = P + h * perp

        return {'A': self.A, 'B': B, 'C': C, 'D': self.D}

    def get_coupler_curve(self, coupler_point=0.5, steps=360):
        """Trace path of a point on the coupler."""
        curve = []
        for angle in np.linspace(0, 360, steps):
            pos = self.solve(angle)
            if pos:
                P = pos['B'] + coupler_point * (pos['C'] - pos['B'])
                curve.append(P)
        return np.array(curve) if curve else None


def main():
    print("\n" + "="*60)
    print("FOUR-BAR LINKAGE TESTER")
    print("="*60)
    print(f"\nYour linkage:")
    print(f"  Ground:  {GROUND} mm")
    print(f"  Crank:   {CRANK} mm")
    print(f"  Coupler: {COUPLER} mm")
    print(f"  Rocker:  {ROCKER} mm")
    print(f"  Trace point: {COUPLER_POINT}")

    linkage = FourBarLinkage(GROUND, CRANK, COUPLER, ROCKER)

    # Check Grashof
    ok, message = linkage.check_grashof()
    print(f"\nGrashof check: {message}")

    if not ok:
        print("\n⚠️  This linkage won't work with a continuous motor!")
        print("    Try making the crank shorter, or adjusting other lengths.")
        print("    Rule: shortest + longest < sum of other two")

    # Get coupler curve
    curve = linkage.get_coupler_curve(COUPLER_POINT)
    if curve is None or len(curve) < 10:
        print("\n❌ Could not generate motion - linkage locks up!")
        sys.exit(1)

    # Calculate rocker swing
    angles = []
    for a in range(0, 360, 5):
        pos = linkage.solve(a)
        if pos:
            rocker_angle = np.degrees(np.arctan2(
                pos['C'][1] - pos['D'][1],
                pos['C'][0] - pos['D'][0]
            ))
            angles.append(rocker_angle)

    if angles:
        swing = max(angles) - min(angles)
        print(f"\nRocker swing: {swing:.1f}°")

    # Create animation
    print("\nGenerating animation... (close window to exit)")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

    # Left plot: animated linkage
    ax1.set_aspect('equal')
    ax1.set_title(f'Four-Bar Linkage Animation\n{message[:50]}', fontsize=10)
    ax1.grid(True, alpha=0.3)

    # Plot coupler curve (static)
    ax1.plot(curve[:, 0], curve[:, 1], 'm-', linewidth=1, alpha=0.3, label='Coupler curve')

    # Set axis limits
    margin = max(GROUND, CRANK + COUPLER) * 0.4
    all_pts = curve
    ax1.set_xlim(all_pts[:, 0].min() - margin, all_pts[:, 0].max() + margin)
    ax1.set_ylim(all_pts[:, 1].min() - margin, all_pts[:, 1].max() + margin)

    # Fixed pivot markers
    ax1.plot(0, -5, '^k', markersize=15)
    ax1.plot(GROUND, -5, '^k', markersize=15)
    ax1.annotate('Fixed', (0, -15), ha='center', fontsize=8)
    ax1.annotate('Fixed', (GROUND, -15), ha='center', fontsize=8)

    # Initialize animated elements
    crank_line, = ax1.plot([], [], 'b-', linewidth=4, label=f'Crank ({CRANK})')
    coupler_line, = ax1.plot([], [], 'g-', linewidth=4, label=f'Coupler ({COUPLER})')
    rocker_line, = ax1.plot([], [], 'r-', linewidth=4, label=f'Rocker ({ROCKER})')
    ground_line, = ax1.plot([], [], 'k-', linewidth=2, label=f'Ground ({GROUND})')
    trace_dot, = ax1.plot([], [], 'mo', markersize=12)
    joints, = ax1.plot([], [], 'ko', markersize=8)

    ax1.legend(loc='upper left', fontsize=8)

    # Right plot: coupler curves at different points
    ax2.set_aspect('equal')
    ax2.set_title('Coupler Curves at Different Trace Points', fontsize=10)
    ax2.grid(True, alpha=0.3)

    colors = plt.cm.viridis(np.linspace(0, 1, 6))
    for i, cp in enumerate([0.0, 0.25, 0.5, 0.75, 1.0, 1.25]):
        c = linkage.get_coupler_curve(cp)
        if c is not None and len(c) > 10:
            style = '-' if cp == COUPLER_POINT else '--'
            width = 3 if cp == COUPLER_POINT else 1.5
            ax2.plot(c[:, 0], c[:, 1], style, color=colors[i],
                    linewidth=width, alpha=0.8, label=f'{cp:.2f}')

    ax2.legend(title='Trace point', loc='upper right', fontsize=8)

    # Pre-calculate all frames
    frames = []
    for angle in np.linspace(0, 360, 90):
        pos = linkage.solve(angle)
        if pos:
            frames.append(pos)

    def animate(i):
        if i >= len(frames):
            return crank_line, coupler_line, rocker_line, ground_line, trace_dot, joints

        pos = frames[i]
        A, B, C, D = pos['A'], pos['B'], pos['C'], pos['D']
        P = B + COUPLER_POINT * (C - B)

        crank_line.set_data([A[0], B[0]], [A[1], B[1]])
        coupler_line.set_data([B[0], C[0]], [B[1], C[1]])
        rocker_line.set_data([C[0], D[0]], [C[1], D[1]])
        ground_line.set_data([A[0], D[0]], [A[1], D[1]])
        trace_dot.set_data([P[0]], [P[1]])
        joints.set_data([A[0], B[0], C[0], D[0]], [A[1], B[1], C[1], D[1]])

        return crank_line, coupler_line, rocker_line, ground_line, trace_dot, joints

    anim = FuncAnimation(fig, animate, frames=len(frames), interval=40, blit=True)

    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()
