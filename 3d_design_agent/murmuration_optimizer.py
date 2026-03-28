"""
Murmuration Engine — Differentiable Mechanism Optimizer v5

Uses Taichi's differentiable programming to find mechanism parameters
that produce target wave-interference motion across a hex ball field.

v5: FFT-seeded hybrid approach
  1. Generate target wave field
  2. FFT a representative ball to identify dominant frequencies (global)
  3. Seed optimizer with FFT peaks (correct frequency basin)
  4. Gradient descent refines amplitude, spatial params, cam profiles (local)

Key insight from v2-v4 failures: gradient descent cannot reliably find
frequencies — the loss landscape has too many local minima. Use spectral
analysis (FFT) for frequency ID, gradients for everything else.
"""

import taichi as ti
import math
import numpy as np

ti.init(arch=ti.gpu, default_fp=ti.f32)

# ─── CONFIGURATION ───────────────────────────────────────────────────
NUM_RINGS = 7          # hex rings (7 = 169 balls, fast iteration)
PITCH = 22.0           # mm center-to-center
NUM_FREQS = 3          # 3 incommensurate frequency channels
NUM_TIME_STEPS = 800   # 1.6s window
DT = 0.002             # 2ms steps
STROKE = 25.0          # mm half-stroke
CAM_HARMONICS = 4      # Fourier harmonics per cam profile
NUM_ITERS = 2000
BASE_LR = 0.05

# ─── HEX GRID ───────────────────────────────────────────────────────
def generate_hex_grid(num_rings, pitch):
    positions = []
    for q in range(-num_rings, num_rings + 1):
        for r in range(-num_rings, num_rings + 1):
            s = -q - r
            if abs(s) <= num_rings:
                x = pitch * (q + r * 0.5)
                y = pitch * (r * math.sqrt(3) / 2)
                positions.append((x, y))
    return positions

grid = generate_hex_grid(NUM_RINGS, PITCH)
NUM_BALLS = len(grid)

# ─── TAICHI FIELDS ──────────────────────────────────────────────────
ball_xy = ti.Vector.field(2, dtype=ti.f32, shape=NUM_BALLS)
target_z = ti.field(dtype=ti.f32, shape=(NUM_BALLS, NUM_TIME_STEPS), needs_grad=True)
actual_z = ti.field(dtype=ti.f32, shape=(NUM_BALLS, NUM_TIME_STEPS), needs_grad=True)
loss = ti.field(dtype=ti.f32, shape=(), needs_grad=True)

# ─── LEARNABLE PARAMETERS ─────────────────────────────────────────
amp = ti.field(dtype=ti.f32, shape=NUM_FREQS, needs_grad=True)
log_omega = ti.field(dtype=ti.f32, shape=NUM_FREQS, needs_grad=True)
k_wave = ti.field(dtype=ti.f32, shape=NUM_FREQS, needs_grad=True)
theta = ti.field(dtype=ti.f32, shape=NUM_FREQS, needs_grad=True)
cam_a = ti.field(dtype=ti.f32, shape=(NUM_FREQS, CAM_HARMONICS), needs_grad=True)
cam_b = ti.field(dtype=ti.f32, shape=(NUM_FREQS, CAM_HARMONICS), needs_grad=True)

NUM_PARAMS = NUM_FREQS * (4 + 2 * CAM_HARMONICS)


# ─── INITIALIZE ─────────────────────────────────────────────────────

def init_grid():
    for i, (x, y) in enumerate(grid):
        ball_xy[i] = [x, y]

def init_target():
    """Ideal wave field from spec."""
    phi = (1 + math.sqrt(5)) / 2
    sqrt2 = math.sqrt(2)
    base_freq = 5.0  # Hz

    T_omegas = [base_freq * 2*math.pi, base_freq * phi * 2*math.pi, base_freq * sqrt2 * 2*math.pi]
    T_amps = [8.0, 8.0, 8.0]
    T_k = [0.02, 0.02, 0.02]
    T_theta = [0.0, 2*math.pi/3, 4*math.pi/3]

    target_np = np.zeros((NUM_BALLS, NUM_TIME_STEPS), dtype=np.float32)
    for i, (x, y) in enumerate(grid):
        for t in range(NUM_TIME_STEPS):
            time = t * DT
            z = 0.0
            for n in range(3):
                spatial = T_k[n] * (x * math.cos(T_theta[n]) + y * math.sin(T_theta[n]))
                z += T_amps[n] * math.sin(T_omegas[n] * time + spatial)
            # Use tanh (same as model) instead of hard clip — eliminates
            # systematic bias that prevented amplitude convergence in v2-v4
            target_np[i, t] = STROKE * math.tanh(z / STROKE)
    # Write to Taichi field
    for i in range(NUM_BALLS):
        for t in range(NUM_TIME_STEPS):
            target_z[i, t] = target_np[i, t]
    return target_np


def fft_seed(target_np):
    """Use FFT to identify dominant frequencies from the target signal.
    Averages power spectrum across multiple balls for robustness."""
    fs = 1.0 / DT  # sampling frequency
    n_fft = NUM_TIME_STEPS

    # Average power spectrum across ~20 balls spread across the grid
    sample_indices = np.linspace(0, NUM_BALLS - 1, min(20, NUM_BALLS), dtype=int)
    avg_power = np.zeros(n_fft // 2)

    for idx in sample_indices:
        signal = target_np[idx, :]
        spectrum = np.fft.rfft(signal)
        power = np.abs(spectrum[:n_fft // 2]) ** 2
        avg_power += power
    avg_power /= len(sample_indices)

    freqs_fft = np.fft.rfftfreq(n_fft, d=DT)[:n_fft // 2]

    # Find top 3 peaks (skip DC, require minimum separation)
    min_sep_bins = int(0.5 / (freqs_fft[1] - freqs_fft[0]))  # 0.5 Hz min separation
    peaks = []
    power_copy = avg_power.copy()
    power_copy[:2] = 0  # skip DC

    for _ in range(NUM_FREQS):
        peak_idx = np.argmax(power_copy)
        peak_freq = freqs_fft[peak_idx]
        peak_power = power_copy[peak_idx]
        peaks.append((peak_freq, peak_power))
        # Zero out neighborhood to find next peak
        lo = max(0, peak_idx - min_sep_bins)
        hi = min(len(power_copy), peak_idx + min_sep_bins + 1)
        power_copy[lo:hi] = 0

    # Sort by frequency
    peaks.sort(key=lambda x: x[0])
    return peaks, freqs_fft, avg_power


def init_params_from_fft(peaks):
    """Seed learnable parameters using FFT-identified frequencies."""
    print(f"\n--- FFT FREQUENCY IDENTIFICATION ---")
    for i, (freq, power) in enumerate(peaks):
        print(f"  Peak {i+1}: {freq:.2f} Hz (power: {power:.0f})")

    for n, (freq, power) in enumerate(peaks):
        # Frequency: seed from FFT peak
        log_omega[n] = math.log(freq * 2 * math.pi)
        # Amplitude: estimate from power (rough)
        amp[n] = 6.0  # conservative start
        # Spatial params: start generic
        k_wave[n] = 0.02
        # Direction: spread evenly as initial guess
        theta[n] = n * 2 * math.pi / NUM_FREQS
        # Cam profile: pure sine
        cam_b[n, 0] = 1.0
        for h in range(1, CAM_HARMONICS):
            cam_a[n, h] = 0.0
            cam_b[n, h] = 0.0

    print(f"\n  Seeded frequencies: [{', '.join(f'{p[0]:.2f}' for p in peaks)}] Hz")
    print(f"  (Optimizer will refine amp, direction, wavenumber, cam profile)")


# ─── FORWARD SIM (differentiable) ───────────────────────────────────

@ti.kernel
def forward():
    for i, t in ti.ndrange(NUM_BALLS, NUM_TIME_STEPS):
        time = ti.cast(t, ti.f32) * DT
        bx = ball_xy[i][0]
        by = ball_xy[i][1]
        z_sum = 0.0

        for n in ti.static(range(NUM_FREQS)):
            w = ti.exp(log_omega[n])
            spatial_phase = k_wave[n] * (bx * ti.cos(theta[n]) + by * ti.sin(theta[n]))
            cam_angle = w * time + spatial_phase

            cam_val = 0.0
            for h in ti.static(range(CAM_HARMONICS)):
                hf = ti.cast(h + 1, ti.f32)
                cam_val += cam_a[n, h] * ti.cos(hf * cam_angle)
                cam_val += cam_b[n, h] * ti.sin(hf * cam_angle)

            z_sum += amp[n] * cam_val

        actual_z[i, t] = STROKE * ti.tanh(z_sum / STROKE)

@ti.kernel
def compute_loss():
    for i, t in ti.ndrange(NUM_BALLS, NUM_TIME_STEPS):
        diff = actual_z[i, t] - target_z[i, t]
        loss[None] += diff * diff / (NUM_BALLS * NUM_TIME_STEPS)


# ─── ADAM OPTIMIZER ──────────────────────────────────────────────────

def get_all_params_and_grads():
    params, grads = [], []
    for n in range(NUM_FREQS):
        params.extend([amp[n], log_omega[n], k_wave[n], theta[n]])
        grads.extend([amp.grad[n], log_omega.grad[n], k_wave.grad[n], theta.grad[n]])
        for h in range(CAM_HARMONICS):
            params.extend([cam_a[n, h], cam_b[n, h]])
            grads.extend([cam_a.grad[n, h], cam_b.grad[n, h]])
    return params, grads

def set_all_params(values):
    idx = 0
    for n in range(NUM_FREQS):
        amp[n] = values[idx]; idx += 1
        log_omega[n] = values[idx]; idx += 1
        k_wave[n] = values[idx]; idx += 1
        theta[n] = values[idx]; idx += 1
        for h in range(CAM_HARMONICS):
            cam_a[n, h] = values[idx]; idx += 1
            cam_b[n, h] = values[idx]; idx += 1

def adam_step(grads_np, lr, step, beta1=0.9, beta2=0.999, eps=1e-8):
    m = np.zeros(NUM_PARAMS) if step == 1 else adam_step.m
    v = np.zeros(NUM_PARAMS) if step == 1 else adam_step.v

    m = beta1 * m + (1 - beta1) * grads_np
    v = beta2 * v + (1 - beta2) * grads_np**2
    m_hat = m / (1 - beta1**step)
    v_hat = v / (1 - beta2**step)
    update = lr * m_hat / (np.sqrt(v_hat) + eps)

    adam_step.m = m
    adam_step.v = v
    return update


# ─── OPTIMIZATION ────────────────────────────────────────────────────

def optimize(peaks):
    phi = (1 + math.sqrt(5)) / 2
    sqrt2 = math.sqrt(2)

    print(f"\n{'='*70}")
    print(f"MURMURATION ENGINE v5 (FFT-seeded + Adam refinement)")
    print(f"{'='*70}")
    print(f"Balls: {NUM_BALLS} | Params: {NUM_PARAMS} | Time: {NUM_TIME_STEPS*DT:.2f}s")
    print(f"Target: 5.00 Hz, {5*phi:.2f} Hz, {5*sqrt2:.2f} Hz")
    print(f"FFT seeds: [{', '.join(f'{p[0]:.2f}' for p in peaks)}] Hz")
    print(f"Optimizing: amp, direction, wavenumber, cam profile")
    print(f"{'='*70}\n")

    # Reduce frequency LR — FFT already found them, just fine-tune
    freq_lr_scale = 0.1  # 10% of base LR for frequencies

    losses = []
    best_loss = float('inf')
    best_params = None

    for iteration in range(1, NUM_ITERS + 1):
        # Cosine LR with warmup
        warmup = 100
        if iteration <= warmup:
            lr = BASE_LR * iteration / warmup
        else:
            progress = (iteration - warmup) / (NUM_ITERS - warmup)
            lr = BASE_LR * 0.5 * (1 + math.cos(math.pi * progress))

        with ti.ad.Tape(loss=loss):
            forward()
            compute_loss()

        current_loss = loss[None]
        losses.append(current_loss)

        params, grads = get_all_params_and_grads()
        params_np = np.array(params, dtype=np.float32)
        grads_np = np.array(grads, dtype=np.float32)

        # Scale down frequency gradients (FFT already seeded correctly)
        for n in range(NUM_FREQS):
            base = n * (4 + 2 * CAM_HARMONICS)
            grads_np[base + 1] *= freq_lr_scale  # log_omega

        # Clip gradients
        grad_norm = np.linalg.norm(grads_np)
        if grad_norm > 20.0:
            grads_np = grads_np * 20.0 / grad_norm

        update = adam_step(grads_np, lr, iteration)
        new_params = params_np - update
        set_all_params(new_params.tolist())

        if current_loss < best_loss:
            best_loss = current_loss
            best_params = new_params.copy()

        if iteration % 100 == 0 or iteration == 1:
            freqs = [math.exp(log_omega[n]) / (2*math.pi) for n in range(NUM_FREQS)]
            amps = [amp[n] for n in range(NUM_FREQS)]
            dirs = [math.degrees(theta[n]) for n in range(NUM_FREQS)]
            ks = [k_wave[n] for n in range(NUM_FREQS)]
            f_str = ", ".join(f"{f:.2f}" for f in freqs)
            a_str = ", ".join(f"{a:.2f}" for a in amps)
            d_str = ", ".join(f"{d:.1f}" for d in dirs)
            k_str = ", ".join(f"{k:.4f}" for k in ks)
            print(f"[{iteration:4d}] loss={current_loss:8.4f} lr={lr:.4f} | "
                  f"freq=[{f_str}] | amp=[{a_str}] | dir=[{d_str}]")

    # Restore best
    if best_params is not None:
        set_all_params(best_params.tolist())

    print(f"\n{'='*70}")
    print(f"OPTIMIZATION COMPLETE — best loss: {best_loss:.4f}")
    print(f"{'='*70}")

    # Report
    print(f"\n--- DISCOVERED MECHANISM PARAMETERS ---\n")
    freqs = [math.exp(log_omega[n]) / (2*math.pi) for n in range(NUM_FREQS)]
    f0 = freqs[0]
    print(f"{'Channel':<10} {'Freq (Hz)':<12} {'Ratio':<10} {'Amp (mm)':<10} {'Dir (deg)':<10} {'k (rad/mm)':<12}")
    print(f"{'-'*64}")
    for n in range(NUM_FREQS):
        print(f"  {n+1:<8} {freqs[n]:<12.3f} {freqs[n]/f0:<10.4f} {amp[n]:<10.2f} "
              f"{math.degrees(theta[n]):<10.1f} {k_wave[n]:<12.4f}")

    print(f"\nTarget ratios:  1.000 : {phi:.3f} : {sqrt2:.3f}")
    print(f"Found ratios:   1.000 : {freqs[1]/f0:.3f} : {freqs[2]/f0:.3f}")

    err_phi = abs(freqs[1]/f0 - phi) / phi * 100
    err_sqrt2 = abs(freqs[2]/f0 - sqrt2) / sqrt2 * 100
    print(f"Ratio errors:   phi: {err_phi:.1f}%  sqrt2: {err_sqrt2:.1f}%")

    print(f"\nTarget wavenumber: 0.0200 rad/mm")
    print(f"Target directions: 0.0, 120.0, 240.0 deg")

    # Cam profile analysis
    print(f"\nCam profiles (harmonic magnitudes):")
    for n in range(NUM_FREQS):
        mags = []
        for h in range(CAM_HARMONICS):
            mag = math.sqrt(cam_a[n, h]**2 + cam_b[n, h]**2)
            mags.append(mag)
        total = sum(mags) if sum(mags) > 0 else 1
        pct = [f"h{h+1}:{m/total*100:.0f}%" for h, m in enumerate(mags) if m/total > 0.05]
        print(f"  Ch{n+1}: {' '.join(pct)}  (pure sine = h1:100%)")

    np.save("d:/Claude local/3d_design_agent/murmuration_losses.npy", np.array(losses))
    print(f"\nLoss curve saved. Reduction: {(1 - best_loss/losses[0])*100:.1f}%")
    return losses


if __name__ == "__main__":
    init_grid()
    target_np = init_target()
    peaks, freqs_fft, avg_power = fft_seed(target_np)
    init_params_from_fft(peaks)
    optimize(peaks)
