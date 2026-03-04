#!/usr/bin/env python3
"""
Mechanical Murmuration — Barrel Cam Generator
==============================================
Runs a Boids simulation for 64 birds, records their trajectories,
encodes X(t) and Y(t) as groove profiles on two barrel cams,
and exports binary STL files + OpenSCAD assembly.

Usage:
    python generate_murmuration_cam.py

Outputs:
    murmuration_cam_x.stl   — Barrel cam encoding horizontal motion
    murmuration_cam_y.stl   — Barrel cam encoding vertical motion
    murmuration_assembly.scad — OpenSCAD assembly showing both cams on a shaft
    murmuration_trajectories.json — Raw trajectory data for reference
"""

import math
import struct
import json
import random
import os

# ─── CAM PARAMETERS ─────────────────────────────────────────────────
CAM_DIAMETER = 60.0        # mm
CAM_RADIUS = CAM_DIAMETER / 2.0
CAM_LENGTH = 200.0         # mm (64 grooves at ~3.1mm pitch)
GROOVE_DEPTH = 5.0         # mm max groove depth
GROOVE_WIDTH = 1.2         # mm per groove (follower pin width)
SHAFT_BORE = 8.0           # mm (steel rod)
SHAFT_RADIUS = SHAFT_BORE / 2.0
NUM_BIRDS = 64

# Cam mesh resolution
THETA_STEPS = 360          # circumferential resolution (1° per step)
Z_STEPS = NUM_BIRDS        # axial = one groove per bird
GROOVE_PROFILE_STEPS = 5   # cross-section steps per groove (U-shape)

# ─── BOIDS PARAMETERS ───────────────────────────────────────────────
SIM_DURATION = 30.0        # seconds (one full cam rotation)
SIM_FPS = 30               # frames per second
WARMUP_FRAMES = 150        # 5 seconds warmup before recording
TOTAL_FRAMES = int(SIM_DURATION * SIM_FPS)  # 900 frames

# Boids tuning — topological (7 nearest neighbors)
SEPARATION_DIST = 22.0
ALIGNMENT_DIST = 48.0
COHESION_DIST = 60.0
NUM_NEIGHBORS = 7          # topological distance
MAX_SPEED = 4.0
MAX_FORCE = 0.15
WORLD_SIZE = 200.0         # simulation space

# Smoothing
SMOOTH_SIGMA = 3.0         # Gaussian sigma in frames

# ─── BOIDS SIMULATION ───────────────────────────────────────────────

class Bird:
    def __init__(self):
        self.x = random.uniform(-WORLD_SIZE/2, WORLD_SIZE/2)
        self.y = random.uniform(-WORLD_SIZE/2, WORLD_SIZE/2)
        self.vx = random.uniform(-2, 2)
        self.vy = random.uniform(-2, 2)

def distance(a, b):
    return math.sqrt((a.x - b.x)**2 + (a.y - b.y)**2)

def limit_vec(vx, vy, max_val):
    mag = math.sqrt(vx*vx + vy*vy)
    if mag > max_val and mag > 0:
        vx = vx / mag * max_val
        vy = vy / mag * max_val
    return vx, vy

def step_boids(birds):
    """One step of Boids with topological 7-neighbor distance."""
    n = len(birds)
    forces = [(0.0, 0.0)] * n

    for i in range(n):
        # Find 7 nearest neighbors (topological distance)
        dists = []
        for j in range(n):
            if i == j:
                continue
            d = distance(birds[i], birds[j])
            dists.append((d, j))
        dists.sort(key=lambda x: x[0])
        neighbors = [j for (_, j) in dists[:NUM_NEIGHBORS]]

        sep_x, sep_y = 0.0, 0.0
        ali_x, ali_y = 0.0, 0.0
        coh_x, coh_y = 0.0, 0.0
        sep_count = 0
        ali_count = 0
        coh_count = 0

        for j in neighbors:
            d = distance(birds[i], birds[j])

            # Separation
            if d < SEPARATION_DIST and d > 0:
                dx = birds[i].x - birds[j].x
                dy = birds[i].y - birds[j].y
                sep_x += dx / d
                sep_y += dy / d
                sep_count += 1

            # Alignment
            if d < ALIGNMENT_DIST:
                ali_x += birds[j].vx
                ali_y += birds[j].vy
                ali_count += 1

            # Cohesion
            if d < COHESION_DIST:
                coh_x += birds[j].x
                coh_y += birds[j].y
                coh_count += 1

        fx, fy = 0.0, 0.0

        if sep_count > 0:
            sep_x /= sep_count
            sep_y /= sep_count
            sep_x, sep_y = limit_vec(sep_x, sep_y, MAX_FORCE)
            fx += sep_x * 1.5
            fy += sep_y * 1.5

        if ali_count > 0:
            ali_x /= ali_count
            ali_y /= ali_count
            ali_x, ali_y = limit_vec(ali_x, ali_y, MAX_FORCE)
            fx += ali_x * 1.0
            fy += ali_y * 1.0

        if coh_count > 0:
            coh_x /= coh_count
            coh_y /= coh_count
            coh_x = (coh_x - birds[i].x) * 0.01
            coh_y = (coh_y - birds[i].y) * 0.01
            coh_x, coh_y = limit_vec(coh_x, coh_y, MAX_FORCE)
            fx += coh_x * 1.0
            fy += coh_y * 1.0

        # Soft boundary — steer back toward center
        margin = WORLD_SIZE * 0.4
        if birds[i].x > margin:
            fx -= 0.5
        elif birds[i].x < -margin:
            fx += 0.5
        if birds[i].y > margin:
            fy -= 0.5
        elif birds[i].y < -margin:
            fy += 0.5

        forces[i] = (fx, fy)

    # Apply forces
    for i in range(n):
        birds[i].vx += forces[i][0]
        birds[i].vy += forces[i][1]
        birds[i].vx, birds[i].vy = limit_vec(birds[i].vx, birds[i].vy, MAX_SPEED)
        birds[i].x += birds[i].vx
        birds[i].y += birds[i].vy


def run_boids():
    """Run Boids simulation and return trajectory arrays."""
    print(f"Running Boids simulation: {NUM_BIRDS} birds, {SIM_DURATION}s at {SIM_FPS}fps")
    print(f"  Warmup: {WARMUP_FRAMES} frames, Recording: {TOTAL_FRAMES} frames")

    random.seed(42)  # Reproducible for prototyping
    birds = [Bird() for _ in range(NUM_BIRDS)]

    # Warmup
    for f in range(WARMUP_FRAMES):
        step_boids(birds)
        if f % 50 == 0:
            print(f"  Warmup frame {f}/{WARMUP_FRAMES}")

    # Record
    # traj_x[bird][frame], traj_y[bird][frame]
    traj_x = [[] for _ in range(NUM_BIRDS)]
    traj_y = [[] for _ in range(NUM_BIRDS)]

    for f in range(TOTAL_FRAMES):
        step_boids(birds)
        for i in range(NUM_BIRDS):
            traj_x[i].append(birds[i].x)
            traj_y[i].append(birds[i].y)
        if f % 100 == 0:
            print(f"  Recording frame {f}/{TOTAL_FRAMES}")

    print("  Simulation complete.")
    return traj_x, traj_y


# ─── TRAJECTORY PROCESSING ──────────────────────────────────────────

def gaussian_smooth(data, sigma):
    """Apply Gaussian smoothing to a 1D array (wrapping for loop continuity)."""
    n = len(data)
    if sigma <= 0:
        return data[:]

    # Build kernel
    k_size = int(sigma * 3) * 2 + 1
    kernel = []
    for i in range(k_size):
        x = i - k_size // 2
        kernel.append(math.exp(-0.5 * (x / sigma) ** 2))
    k_sum = sum(kernel)
    kernel = [k / k_sum for k in kernel]

    # Convolve with wrapping (cam is a cylinder — loop is continuous)
    smoothed = []
    half_k = k_size // 2
    for i in range(n):
        val = 0.0
        for j in range(k_size):
            idx = (i + j - half_k) % n
            val += data[idx] * kernel[j]
        smoothed.append(val)
    return smoothed


def normalize_trajectories(traj_x, traj_y):
    """Normalize all trajectories to [0, GROOVE_DEPTH] range."""
    # Find global min/max across ALL birds for each axis
    all_x = [v for bird in traj_x for v in bird]
    all_y = [v for bird in traj_y for v in bird]

    x_min, x_max = min(all_x), max(all_x)
    y_min, y_max = min(all_y), max(all_y)

    print(f"  X range: [{x_min:.1f}, {x_max:.1f}]")
    print(f"  Y range: [{y_min:.1f}, {y_max:.1f}]")

    # Smooth and normalize
    norm_x = []
    norm_y = []
    for i in range(NUM_BIRDS):
        sx = gaussian_smooth(traj_x[i], SMOOTH_SIGMA)
        sy = gaussian_smooth(traj_y[i], SMOOTH_SIGMA)

        # Map to [0, GROOVE_DEPTH]
        nx = [(v - x_min) / (x_max - x_min) * GROOVE_DEPTH if x_max > x_min else GROOVE_DEPTH / 2 for v in sx]
        ny = [(v - y_min) / (y_max - y_min) * GROOVE_DEPTH if y_max > y_min else GROOVE_DEPTH / 2 for v in sy]

        norm_x.append(nx)
        norm_y.append(ny)

    return norm_x, norm_y


# ─── STL GENERATION ─────────────────────────────────────────────────

def write_binary_stl(filename, triangles):
    """Write a binary STL file. triangles = list of ((v1,v2,v3), (nx,ny,nz))."""
    print(f"  Writing {filename}: {len(triangles)} triangles")
    with open(filename, 'wb') as f:
        # 80-byte header
        header = f"Murmuration Barrel Cam - {filename}".encode('ascii')
        header = header[:80].ljust(80, b'\0')
        f.write(header)
        # Triangle count
        f.write(struct.pack('<I', len(triangles)))
        # Triangles
        for (v1, v2, v3), (nx, ny, nz) in triangles:
            f.write(struct.pack('<fff', nx, ny, nz))
            f.write(struct.pack('<fff', *v1))
            f.write(struct.pack('<fff', *v2))
            f.write(struct.pack('<fff', *v3))
            f.write(struct.pack('<H', 0))  # attribute byte count


def compute_normal(v1, v2, v3):
    """Compute face normal from 3 vertices (right-hand rule)."""
    # edge vectors
    ax = v2[0] - v1[0]; ay = v2[1] - v1[1]; az = v2[2] - v1[2]
    bx = v3[0] - v1[0]; by = v3[1] - v1[1]; bz = v3[2] - v1[2]
    # cross product
    nx = ay * bz - az * by
    ny = az * bx - ax * bz
    nz = ax * by - ay * bx
    # normalize
    mag = math.sqrt(nx*nx + ny*ny + nz*nz)
    if mag > 0:
        nx /= mag; ny /= mag; nz /= mag
    return (nx, ny, nz)


def groove_radius(bird_idx, theta_idx, groove_data):
    """
    Get the radius at a given bird groove and angular position.
    groove_data[bird][frame] = depth in [0, GROOVE_DEPTH].
    The groove cuts INTO the cam surface.
    """
    frame = theta_idx % TOTAL_FRAMES
    depth = groove_data[bird_idx][frame]
    return CAM_RADIUS - depth


def build_cam_mesh(groove_data):
    """
    Build a barrel cam mesh as a list of triangles.

    The cam is a cylinder with:
    - Outer surface with 64 grooves cut into it (the trajectory data)
    - Inner bore (shaft hole)
    - Two end caps

    Each groove is a channel along the circumference, with the depth
    varying according to the Boids trajectory for that bird.
    """
    triangles = []

    # Groove layout: each bird gets a band along the Z axis
    groove_pitch = CAM_LENGTH / NUM_BIRDS  # ~3.125mm
    groove_half = GROOVE_WIDTH / 2.0       # half the groove channel width

    # For the outer surface, we build it as a series of axial bands.
    # Between grooves = land (full radius). Inside groove = variable depth.

    # Build a 2D grid of radii: r[z_idx][theta_idx]
    # z_idx corresponds to fine axial positions
    # We'll use: land → groove_bottom → land pattern per bird

    # Fine axial resolution: 5 sub-steps per groove
    sub_steps = GROOVE_PROFILE_STEPS
    z_fine_count = NUM_BIRDS * sub_steps
    r_grid = []  # r_grid[z][theta]
    z_positions = []  # actual Z coordinate for each z_fine index

    for bird in range(NUM_BIRDS):
        z_center = (bird + 0.5) * groove_pitch  # center of this bird's groove band
        for s in range(sub_steps):
            # Position within the groove band: 0..1
            t = s / (sub_steps - 1) if sub_steps > 1 else 0.5
            z_pos = z_center - groove_half + t * GROOVE_WIDTH
            # Groove profile: U-shape (parabolic cross-section)
            # t=0 and t=1 are groove edges (full radius)
            # t=0.5 is groove bottom (variable depth)
            # Profile factor: 0 at edges, 1 at center
            profile = 1.0 - (2.0 * t - 1.0) ** 2  # parabolic

            row = []
            for ti in range(THETA_STEPS):
                frame = int(ti / THETA_STEPS * TOTAL_FRAMES) % TOTAL_FRAMES
                depth = groove_data[bird][frame] * profile
                r = CAM_RADIUS - depth
                row.append(r)

            r_grid.append(row)
            z_positions.append(z_pos)

    # Also add land surfaces between grooves
    # For simplicity, the groove sub-steps already handle the U-profile
    # (edges at full radius). We add cap rings at Z=0 and Z=CAM_LENGTH.

    # ─── OUTER SURFACE TRIANGLES ─────────────────────────────
    for zi in range(len(r_grid) - 1):
        z0 = z_positions[zi]
        z1 = z_positions[zi + 1]
        for ti in range(THETA_STEPS):
            ti_next = (ti + 1) % THETA_STEPS
            theta0 = 2.0 * math.pi * ti / THETA_STEPS
            theta1 = 2.0 * math.pi * ti_next / THETA_STEPS

            r00 = r_grid[zi][ti]
            r01 = r_grid[zi][ti_next]
            r10 = r_grid[zi + 1][ti]
            r11 = r_grid[zi + 1][ti_next]

            # 4 vertices of the quad
            v00 = (r00 * math.cos(theta0), r00 * math.sin(theta0), z0)
            v01 = (r01 * math.cos(theta1), r01 * math.sin(theta1), z0)
            v10 = (r10 * math.cos(theta0), r10 * math.sin(theta0), z1)
            v11 = (r11 * math.cos(theta1), r11 * math.sin(theta1), z1)

            # Two triangles per quad (outward-facing normals)
            n1 = compute_normal(v00, v01, v11)
            triangles.append(((v00, v01, v11), n1))
            n2 = compute_normal(v00, v11, v10)
            triangles.append(((v00, v11, v10), n2))

    # ─── INNER BORE (shaft hole) ─────────────────────────────
    bore_z_steps = 32
    for zi in range(bore_z_steps):
        z0 = zi / bore_z_steps * CAM_LENGTH
        z1 = (zi + 1) / bore_z_steps * CAM_LENGTH
        for ti in range(THETA_STEPS):
            ti_next = (ti + 1) % THETA_STEPS
            theta0 = 2.0 * math.pi * ti / THETA_STEPS
            theta1 = 2.0 * math.pi * ti_next / THETA_STEPS

            # Inner bore vertices (inward-facing normals)
            v00 = (SHAFT_RADIUS * math.cos(theta0), SHAFT_RADIUS * math.sin(theta0), z0)
            v01 = (SHAFT_RADIUS * math.cos(theta1), SHAFT_RADIUS * math.sin(theta1), z0)
            v10 = (SHAFT_RADIUS * math.cos(theta0), SHAFT_RADIUS * math.sin(theta0), z1)
            v11 = (SHAFT_RADIUS * math.cos(theta1), SHAFT_RADIUS * math.sin(theta1), z1)

            # Normals point inward (reversed winding)
            n1 = compute_normal(v00, v11, v01)
            triangles.append(((v00, v11, v01), n1))
            n2 = compute_normal(v00, v10, v11)
            triangles.append(((v00, v10, v11), n2))

    # ─── END CAPS ────────────────────────────────────────────
    for cap_z, flip in [(0.0, True), (CAM_LENGTH, False)]:
        for ti in range(THETA_STEPS):
            ti_next = (ti + 1) % THETA_STEPS
            theta0 = 2.0 * math.pi * ti / THETA_STEPS
            theta1 = 2.0 * math.pi * ti_next / THETA_STEPS

            # Outer edge radius at this cap
            if cap_z == 0.0:
                r0 = r_grid[0][ti]
                r1 = r_grid[0][ti_next]
            else:
                r0 = r_grid[-1][ti]
                r1 = r_grid[-1][ti_next]

            # Annular ring: outer edge to inner bore
            vo0 = (r0 * math.cos(theta0), r0 * math.sin(theta0), cap_z)
            vo1 = (r1 * math.cos(theta1), r1 * math.sin(theta1), cap_z)
            vi0 = (SHAFT_RADIUS * math.cos(theta0), SHAFT_RADIUS * math.sin(theta0), cap_z)
            vi1 = (SHAFT_RADIUS * math.cos(theta1), SHAFT_RADIUS * math.sin(theta1), cap_z)

            if flip:
                n1 = compute_normal(vo0, vi0, vo1)
                triangles.append(((vo0, vi0, vo1), n1))
                n2 = compute_normal(vi0, vi1, vo1)
                triangles.append(((vi0, vi1, vo1), n2))
            else:
                n1 = compute_normal(vo0, vo1, vi0)
                triangles.append(((vo0, vo1, vi0), n1))
                n2 = compute_normal(vi0, vo1, vi1)
                triangles.append(((vi0, vo1, vi1), n2))

    return triangles


# ─── OPENSCAD ASSEMBLY ──────────────────────────────────────────────

def write_openscad_assembly(filename, stl_x, stl_y):
    """Write an OpenSCAD file that imports both cams on a shared shaft."""
    content = f"""// Mechanical Murmuration — Barrel Cam Assembly
// Generated by generate_murmuration_cam.py
// Two barrel cams encoding Boids X and Y trajectories

// ─── PARAMETERS ─────────────────────────────────────
CAM_DIAMETER = {CAM_DIAMETER};
CAM_LENGTH = {CAM_LENGTH};
SHAFT_BORE = {SHAFT_BORE};
GROOVE_DEPTH = {GROOVE_DEPTH};
NUM_BIRDS = {NUM_BIRDS};

// Spacing between cams on the shaft
CAM_GAP = 20;  // mm between cams
SHAFT_EXTENSION = 30;  // mm beyond each end

// Total shaft length
SHAFT_LEN = CAM_LENGTH * 2 + CAM_GAP + SHAFT_EXTENSION * 2;

// ─── TOGGLES ────────────────────────────────────────
SHOW_CAM_X = true;
SHOW_CAM_Y = true;
SHOW_SHAFT = true;
SHOW_FOLLOWERS = true;
SHOW_GUIDE_LINES = false;

// ─── QUALITY ────────────────────────────────────────
$fn = 48;

// ─── COLORS ─────────────────────────────────────────
CAM_X_COLOR = [0.85, 0.25, 0.25, 0.85];  // red
CAM_Y_COLOR = [0.25, 0.45, 0.85, 0.85];  // blue
SHAFT_COLOR = [0.7, 0.7, 0.7, 1.0];       // steel
FOLLOWER_COLOR = [0.3, 0.8, 0.3, 0.6];    // green

// ─── ASSEMBLY ───────────────────────────────────────

// Shaft
if (SHOW_SHAFT) {{
    color(SHAFT_COLOR)
    translate([0, 0, -SHAFT_EXTENSION])
    cylinder(d=SHAFT_BORE - 0.1, h=SHAFT_LEN, $fn=24);
}}

// Cam X (horizontal motion)
if (SHOW_CAM_X) {{
    color(CAM_X_COLOR)
    import("{stl_x}", convexity=10);
}}

// Cam Y (vertical motion) — offset along shaft
if (SHOW_CAM_Y) {{
    color(CAM_Y_COLOR)
    translate([0, 0, CAM_LENGTH + CAM_GAP])
    import("{stl_y}", convexity=10);
}}

// Follower positions (visualization only)
if (SHOW_FOLLOWERS) {{
    groove_pitch = CAM_LENGTH / NUM_BIRDS;
    for (axis = [0, 1]) {{
        z_offset = axis * (CAM_LENGTH + CAM_GAP);
        cam_color = axis == 0 ? CAM_X_COLOR : CAM_Y_COLOR;
        for (i = [0 : NUM_BIRDS - 1]) {{
            z = z_offset + (i + 0.5) * groove_pitch;
            // Follower pin at 12 o'clock position
            color(FOLLOWER_COLOR)
            translate([0, CAM_DIAMETER/2 + 3, z])
            rotate([0, 90, 0])
            cylinder(d=1.0, h=8, center=true, $fn=12);
        }}
    }}
}}

// Guide lines showing groove positions
if (SHOW_GUIDE_LINES) {{
    groove_pitch = CAM_LENGTH / NUM_BIRDS;
    for (i = [0 : NUM_BIRDS - 1]) {{
        z = (i + 0.5) * groove_pitch;
        color([1, 1, 0, 0.3])
        translate([0, 0, z])
        cylinder(d=CAM_DIAMETER + 10, h=0.2, $fn=48);
    }}
}}
"""
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  Written {filename}")


# ─── MAIN ────────────────────────────────────────────────────────────

def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))

    # 1. Run Boids simulation
    traj_x, traj_y = run_boids()

    # 2. Smooth and normalize trajectories
    print("Processing trajectories...")
    norm_x, norm_y = normalize_trajectories(traj_x, traj_y)

    # 3. Save trajectory data for reference
    traj_file = os.path.join(out_dir, "murmuration_trajectories.json")
    with open(traj_file, 'w') as f:
        json.dump({
            "num_birds": NUM_BIRDS,
            "total_frames": TOTAL_FRAMES,
            "sim_duration_s": SIM_DURATION,
            "cam_diameter_mm": CAM_DIAMETER,
            "cam_length_mm": CAM_LENGTH,
            "groove_depth_mm": GROOVE_DEPTH,
            "shaft_bore_mm": SHAFT_BORE,
            "norm_x": norm_x,
            "norm_y": norm_y
        }, f)
    print(f"  Saved trajectory data: {traj_file}")

    # 4. Build Cam X mesh (horizontal motion)
    print("Building Cam X mesh (horizontal motion)...")
    cam_x_tris = build_cam_mesh(norm_x)
    stl_x = os.path.join(out_dir, "murmuration_cam_x.stl")
    write_binary_stl(stl_x, cam_x_tris)

    # 5. Build Cam Y mesh (vertical motion)
    print("Building Cam Y mesh (vertical motion)...")
    cam_y_tris = build_cam_mesh(norm_y)
    stl_y = os.path.join(out_dir, "murmuration_cam_y.stl")
    write_binary_stl(stl_y, cam_y_tris)

    # 6. Write OpenSCAD assembly
    print("Writing OpenSCAD assembly...")
    scad_file = os.path.join(out_dir, "murmuration_assembly.scad")
    write_openscad_assembly(scad_file, "murmuration_cam_x.stl", "murmuration_cam_y.stl")

    # Summary
    print("\n" + "=" * 60)
    print("BARREL CAM GENERATION COMPLETE")
    print("=" * 60)
    print(f"  Cam X STL:    {stl_x}")
    print(f"  Cam Y STL:    {stl_y}")
    print(f"  Assembly:     {scad_file}")
    print(f"  Trajectories: {traj_file}")
    print(f"\n  Cam specs:")
    print(f"    Diameter:    {CAM_DIAMETER}mm")
    print(f"    Length:      {CAM_LENGTH}mm")
    print(f"    Grooves:     {NUM_BIRDS}")
    print(f"    Pitch:       {CAM_LENGTH/NUM_BIRDS:.2f}mm")
    print(f"    Max depth:   {GROOVE_DEPTH}mm")
    print(f"    Shaft bore:  {SHAFT_BORE}mm")
    print(f"\n  Mesh stats:")
    print(f"    Cam X:       {len(cam_x_tris)} triangles")
    print(f"    Cam Y:       {len(cam_y_tris)} triangles")
    print(f"\n  Open in OpenSCAD:")
    print(f"    {scad_file}")


if __name__ == "__main__":
    main()
