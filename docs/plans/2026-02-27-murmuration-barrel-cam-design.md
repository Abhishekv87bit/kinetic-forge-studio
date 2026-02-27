# Mechanical Murmuration — Barrel Cam Design

**Date:** 2026-02-27
**Status:** Design Phase
**Decision:** Option A — Two barrel cams, full 2D Boids replay

## Concept

A ceiling-mounted kinetic sculpture that replays starling murmuration behavior.
64 lightweight birds hang from cables, driven by two barrel cams encoding pre-computed
Boids trajectories. One motor turns both cams synchronously.

## Architecture

```
        CEILING MOUNT FRAME
        ════════════════════════════════
        │  │  │  │  │  │  │  │  │  │    ← Spectra braid / fishing line
        ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼      through guide plate holes
     ┌──────────────────────────────────┐
     │      GUIDE PLATE                  │    birds positioned in
     │  (cloud layout, NOT grid)         │    organic cloud formation
     └──────┬───┬───┬───┬───┬───┬──────┘
            │   │   │   │   │   │
     ┌──────▼───▼───▼───▼───▼───▼──────┐
     │         CAM SHAFT ASSEMBLY        │
     │  ┌────────┐      ┌────────┐      │
     │  │ CAM X  │──────│ CAM Y  │      │   2 barrel cams on 1 shaft
     │  │64 grv  │ shaft│64 grv  │      │   motor drives shaft
     │  └────────┘      └────────┘      │
     └──────────────────────────────────┘
                   ▲
              Geared Motor (2 RPM)
```

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Approach | 2-axis barrel cam (Option A) | Full Boids fidelity — no compromise |
| Bird count | 64 (8×8 equivalent) | Printable on K2 Plus, dense enough for cloud |
| Cam encoding | Pre-computed Boids trajectories | Algorithm frozen in plastic = the murmuration |
| Motor speed | 2 RPM (30s loop) | Slow enough for graceful motion |
| Cable type | Spectra braid or fishing line | Invisible, strong, low stretch |
| Bird form | Lightweight 3D printed (~25mm) | Small enough for density, light for cables |

## Barrel Cam Specs (K2 Plus Prototype)

- **Cam diameter:** 60mm (printable, enough groove depth)
- **Cam length:** 100mm (64 grooves at ~1.5mm pitch)
- **Groove depth:** 5mm max (maps to bird travel range)
- **Groove width:** ~1.2mm (0.4mm nozzle compatible)
- **Material:** PLA or PETG
- **Two cams:** Cam X (horizontal motion), Cam Y (vertical motion)
- **Shaft:** 8mm steel rod through both cams
- **Followers:** 64 per cam, spring-loaded roller or pin type

## Boids → Cam Pipeline

```
1. Run Boids sim (64 birds, 30 seconds, 30fps = 900 frames)
   - Separation: 22 units
   - Alignment: 48 units
   - Cohesion: 60 units
   - Topological: 7 nearest neighbors

2. Record trajectories: X(t), Y(t) per bird

3. Normalize to groove depth range:
   - Find global min/max for X and Y across all birds
   - Map to [0, groove_depth] = [0, 5mm]

4. Encode as barrel cam grooves:
   - θ (rotation angle) = time: 360° = 30 seconds
   - Z (axial position) = bird index: 64 positions along 100mm
   - r(θ, Z) = base_radius - groove_depth(bird_Z, time_θ)

5. Generate cam geometry:
   - Option A: Export as STL from visualization tool
   - Option B: Use `camfollower` Python library for proper profiles
   - Option C: Generate OpenSCAD with groove polyhedra

6. 3D print on K2 Plus (350mm³ build volume)
```

## Follower Design

Each of the 64 followers needs:
- **Contact:** Pin or small roller riding in the groove
- **Spring return:** Compression spring pushes follower into groove
- **Cable attachment:** Spectra braid ties to follower arm
- **Guide:** Linear guide constrains follower to radial motion only

Follower spacing: 100mm / 64 = 1.5625mm per groove. This is TIGHT.
Alternative: stagger followers on opposite sides of cam (32 per side).

## Open Questions

1. **Groove pitch vs follower size:** 1.5mm pitch with pin followers may be too tight.
   Solutions: longer cam (200mm), or staggered followers, or fewer birds (49 = 7×7).

2. **Cable routing:** 128 cables (64 per axis) from cam followers to guide plate holes.
   Need a clean routing solution to avoid tangling.

3. **Cam profile smoothness:** Raw Boids data has frame-to-frame jitter.
   Apply Gaussian smoothing to trajectories before encoding.

4. **Spring preload:** Followers need consistent contact. Spring force must overcome
   cable tension + friction but not overload the motor.

5. **Motor torque:** 128 spring-loaded followers × ~0.1N each = ~13N total spring force
   at ~30mm radius = ~0.4 Nm torque. Typical geared motor can handle this.

## GitHub Libraries

- **[camfollower](https://github.com/ochoadavid/camfollower)** — Python cam profile generation
- **[CamFollowerJS](https://github.com/jumpjack/CamFollowerJS)** — Interactive JS cam simulator
- **[tetracamthon](https://github.com/John-Qu/tetracamthon)** — Multi-cam FreeCAD coupling
- **[Kit Wallace cam_profile.scad](https://github.com/KitWallace/openscad)** — OpenSCAD cam profiles

## Experiments Created

| File | Description |
|------|-------------|
| `exp_murmuration_compare.html` | Boids vs Lissajous side-by-side (200 birds) |
| `exp_murmuration_camshaft.html` | 4-shaft cam prototype (8×8 grid, Fourier profiles) |
| `exp_murmuration_3options.html` | 3 mechanical approaches compared |
| `exp_murmuration_boids2cam.html` | Record Boids → visualize barrel cams → export STL |

## Next Steps

1. **Test groove pitch** — Can K2 Plus reliably print 1.5mm pitch grooves? Print test strip.
2. **Evaluate `camfollower` library** — Install, test with sample Boids data
3. **Design follower mechanism** — Pin vs roller, spring type, linear guide
4. **Design cable routing plate** — Cloud-layout guide plate with 64 holes
5. **Build single-axis prototype** — One barrel cam, 8 followers, 8 birds → proof of concept
6. **Full 2-axis assembly** — Both cams, all 64 birds, motor drive
