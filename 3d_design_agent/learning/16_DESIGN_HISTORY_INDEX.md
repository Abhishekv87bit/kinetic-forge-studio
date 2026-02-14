# Design History Index
## All Mechanism Prototypes, Design Files & Engineering Insights

**Purpose:** Track every design iteration, its status, key learnings, and where critical engineering insights were discovered. Prevents loss of hard-won design knowledge across sessions.

**Last Updated:** Feb 6, 2026

---

## Standalone Mechanism Prototypes

| # | Design | File | Status | Mechanism Type | Key Learning |
|---|--------|------|--------|---------------|--------------|
| 1 | Margolin Wave Ring v1 | `margolin_wave_ring_v1.scad` | Created, untested | Tilted ring + string array | `rod_height = r*tan(tilt)*sin(phi-theta)`, sign error fix |
| 2 | Radial Crank Wave v1 | `radial_crank_wave_v1.scad` | Created, untested | 16 eccentric discs + ring gear | **CRITICAL: Vertical-plane eccentrics required** |
| 3 | Triple Helix v1 | `triple_helix_prototype_v1.scad` | Complete | 3 helix shafts + cable-slider | 37 hex blocks, nearest-slider routing |
| 4 | Triple Helix v2 | `triple_helix_prototype_v2.scad` | Planned (44KB plan) | Margolin-accurate version | Prime count (37) avoids Moire, LOD system |
| 5 | Water Wheel Kinetic v1 | `water_wheel_kinetic_v1.scad` | Unknown | Water wheel | — |
| 6 | Marble Creature Run v1 | `marble_creature_run_v1.scad` | Unknown | Marble run + creature | — |
| 7 | Ocean Lighthouse v1 | `ocean_lighthouse_v1_PHYSICAL.scad` | Physical design | Lighthouse mechanism | — |
| 8 | Spur Gear Generator | `spur_gear_generator.scad` | Utility | Involute gear generation | Module 3mm, 20 teeth, involute profile |

---

## Wave Mechanism Evolution (v1 → v10)

The wave mechanism went through 10+ iterations. Each taught critical lessons.

### Wave v1-v2 (Early)
**Files:** `components/wave_crank/wave_ocean_v1.scad`, `wave_ocean_v2.scad`
**Status:** Superseded
**Mechanism:** Basic crank-slider wave
**Learnings:** Foundation layout, basic wave motion

### Wave v3 (STL Import Approach)
**Files:** `wave_ocean_v3.scad`, `wave_ocean_v3_fixed.scad`
**Status:** 8 critical failures documented
**Mechanism:** STL import + slider-crank drive
**Failures:**
1. Flex zones broken
2. RED/GREEN wave layer ordering wrong
3. Track connection failed
4. Motor mount issues
5. Layer Y positions incorrect
6. Slats colliding with cams
7. Bearing blocks empty
8. Everything floating (not grounded)
**Key Learning:** STL import approach abandoned; need engineered components

### Wave v4 (Rocker Tilt / Gear-on-Rack)
**Files:** `wave_ocean_v4.scad` + 6 Fusion 360 Python scripts
**Status:** Scripts created, mechanism designed
**Mechanism:** Spur gear rides on wavy rack → connecting rod → rocker bar
**Specs:** Module 3mm, 20 teeth, rocker tilt ±17°, 3 motion types (L-R, U-D, tilt)
**Fusion Scripts:**
- `fusion_spur_gear.py`
- `fusion_wavy_rack.py`
- `fusion_wavy_rack_base.py`
- `fusion_connecting_rod.py`
- `fusion_rocker_bar.py`
- `fusion_rod_end_bearing.py`
- `fusion_wave_assembly.py`
- `fusion_rack.py`

### Wave v5-v6 (Profile Iterations)
**Files:** `wave_ocean_v5_profiles.scad`, `components/wave_crank/wave_ocean_v5.scad`, `wave_ocean_v6.scad`
**Status:** Intermediate iterations
**Mechanism:** Wave profile refinements

### Wave v7 (Geometry Validation)
**Files:** `ocean_waves_v7.scad`, `archives/projects/wave_ocean_v7/wave_ocean_v7.scad`
**Status:** Four-bar FAILED Grashof, redesigned to asymmetric cam
**Mechanism:** Cam-follower system for 5 foam curls
**Critical Findings:**
- Four-bar linkage failed Grashof condition for ALL 5 curl positions
- **Switched to asymmetric cam profile** (quick rise, slow fall)
- Belt drive selected for power transfer
- Follower pad height fixed: 2.5mm → 5mm
- Curl body raised 2mm above wave surface
- All collision checks passed after redesign
**Key Learning:** Don't force four-bar when cam is simpler and more reliable

### Wave v8 (Disc Variants)
**Files:** `archives/projects/wave_ocean_v8/` (5 variants)
**Status:** Testing disc-based approaches
**Mechanism:** Disc cam variants

### Wave v10 (Whack-a-Mole Box / 3-Layer)
**Files:** `wave_ocean_v10_crankA.scad`, `wave_ocean_v10_camB.scad`, `wave_ocean_v10_slatsC.scad`, `wave_ocean_v10_layersD.scad`, `wave_ocean_v10_discsE.scad`, `wave_ocean_v10_helix*.scad`
**Status:** Y-coordinate mismatch bug found
**Mechanism:** 3-layer whack-a-mole design, multiple sub-approaches (crank, cam, slats, discs, helix)
**Critical Bug:** Y coordinate mismatch between `box.scad` and `assembly.scad`
**Fix:** Unify coordinate system using `LAYER_Y_BOX` absolute positions
**Key Learning:** Unified coordinate systems are MANDATORY when integrating multiple components

### Other Wave Files
| File | Description |
|------|-------------|
| `wave_train_channel_v2.scad` | Train channel variant |
| `wave_slider_crank_v1.scad` | Pure slider-crank wave |
| `components/wave_surge/asymmetric_surge_v1.scad` | Asymmetric surge motion |

---

## Starry Night Project (v26 → v49)

The Starry Night is the flagship multi-component kinetic sculpture project.

**Location:** `archives/Reference/starry_night_v*.scad` (26 through 49)

**Components:**
- Ocean waves (3 layers)
- Cliff waves (3 layers)
- Cypress tree (eccentric drive)
- Wind path
- Canvas layout / mounting system
- Rice tube mechanism

**Key files:**
| Version | File | Notable |
|---------|------|---------|
| v26 | `starry_night_v26_animate.scad` | First animation version |
| v27 | `starry_night_v27_steampunk.scad` | Steampunk aesthetic variant |
| v28 | `starry_night_v28_mechanisms.scad` | Mechanism focus |
| v33-v39 | Multiple assembly versions | Iterative refinement |
| v48-v49 | `archives/mechanisms/wave_mechanism_v48/v49.scad` | Latest mechanism versions |

**Component Standalone Files:**
| Component | Location |
|-----------|----------|
| Cypress Drive | `components/cypress_eccentric_drive_v57.scad` |
| Ocean Waves | `components/ocean_waves/ocean_waves_standalone.scad` |
| Cliff Waves | `components/cliff_waves/cliff_waves_standalone.scad` |
| Wave Crank | `components/wave_crank/wave_crank_standalone_v2.scad` |
| Rice Tube | `archives/projects/starry_night_rehaul/2_rice_tube_v57_complete_module.scad` |
| Canvas Layout | Multiple versions in `archives/Reference/canvas_layout_*.scad` |

---

## Critical Engineering Insights (PRESERVE)

### 1. Vertical-Plane Eccentric Requirement
**Source:** Radial Crank Wave v1 development (Session E, ~Feb 5)
```
For a radial wave machine with offset cranks driving vertical followers
through rigid connecting rods, the eccentric discs MUST spin in VERTICAL
planes. Horizontal-plane eccentrics CANNOT produce vertical motion through
a rigid rod regardless of arrangement. The pin must have a vertical
component to its orbital path.
```
**Problems found:**
- Connecting rod stretching 2.25x (24.2mm to 54.6mm) — pin and follower not co-located radially
- Horizontal circular orbit gives zero vertical motion through rigid rod
- **Solution:** Vertical-plane eccentric discs, each on horizontal radial axle. Rod variation < 2%

### 2. Grashof Failures in Wave v7
**Source:** Wave Ocean v7 geometry validation (Jan 25)
- All 5 curl positions failed Grashof condition (S+L > P+Q)
- **Lesson:** Don't assume four-bar will work for all positions — check EVERY configuration
- **Solution:** Switch to cam mechanism when linkage geometry is constrained

### 3. Y-Coordinate Unification (Wave v10)
**Source:** Wave v10 whack-a-mole box (Jan 29)
- Box and assembly used different coordinate origins
- Components appeared correct in isolation but misaligned in assembly
- **Lesson:** Define absolute position constants (e.g., `LAYER_Y_BOX`) shared across ALL files

### 4. Wave v3 — 8 Failure Modes
**Source:** Wave Ocean v3 (Jan 30)
- Documented 8 distinct failure modes from user screenshots
- **Lesson:** Complex multi-layer mechanisms need individual component verification BEFORE integration
- Led to "Component Isolation" principle in CLAUDE.md

### 5. Margolin Wave Ring — Sign Error
**Source:** margolin_wave_ring_v1 (Session E, ~Feb 5)
- `sin(theta - phi)` should be `sin(phi - theta)` — sign determines wave direction
- `tan(tilt)` vs `sin(tilt)` gives ~3.5% error at 15° — acceptable for prototype

---

## Fusion 360 Python Scripts (Wave v4)

| Script | Purpose | Status |
|--------|---------|--------|
| `fusion_spur_gear.py` | Generate involute spur gear | Created |
| `fusion_wavy_rack.py` | Generate wavy rack profile | Created |
| `fusion_wavy_rack_base.py` | Rack base/housing | Created |
| `fusion_connecting_rod.py` | Connecting rod with bearing ends | Created |
| `fusion_rocker_bar.py` | Output rocker bar | Created |
| `fusion_rod_end_bearing.py` | Rod end bearing detail | Created |
| `fusion_wave_assembly.py` | Full assembly script | Created |
| `fusion_rack.py` | Rack component | Created |

**Note:** These scripts are for Fusion 360's Python API. They implement the gear-on-wavy-rack mechanism from Wave v4.

---

## Design Decision: Wave Mechanism Going Forward

**Status (Feb 6, 2026):** Starting fresh. All previous wave iterations (v3-v10) are valuable as learning experiments, but no commitment to any specific approach.

**Wave design fits in Experiment Mode** — the stage where you try different mechanisms and identify patterns for kinetic art. When ready to commit to a wave design for a sculpture, it enters Build Mode (the 6-stage pipeline).

---

## File Location Map

```
D:\Claude local\3d_design_agent\
├── *.scad                          # Active/recent standalone designs
├── fusion_*.py                     # Fusion 360 Python scripts (Wave v4)
├── spur_gear_generator.scad        # Utility
├── components\
│   ├── wave_crank\                 # Wave crank iterations (v1-v6)
│   ├── wave_surge\                 # Asymmetric surge mechanism
│   ├── ocean_waves\                # Starry Night ocean component
│   ├── cliff_waves\                # Starry Night cliff component
│   └── wrappers\                   # Component wrappers
├── archives\
│   ├── Reference\                  # Starry Night v26-v49 + wrappers + canvas
│   ├── mechanisms\                 # Wave mechanism v48-v49
│   ├── projects\                   # Organized project archives
│   │   ├── wave_ocean_v7\
│   │   ├── wave_ocean_v8\
│   │   ├── single_wave\
│   │   ├── water_fish_v2\
│   │   └── starry_night_rehaul\
│   └── docs\                       # Knowledge bases
└── learning\                       # This file's home
```
