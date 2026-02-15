# Triple Helix MVP -- Machine State Diagram
## V5.2 | True 75% Scale + Monolithic Matrix | February 14, 2026

---

## Power Flow (Single Motor Path)

```
HAND CRANK (input)
     |
     v
CENTRAL VERTICAL SHAFT
     |
     +---- GT2 Belt ----> HELIX 1 (180 deg)
     |                      |
     |                      v
     |                    11 Eccentric Disc Cams
     |                    (32.73 deg twist/cam on 5mm D-flat shaft)
     |                      |
     |                      v
     |                    11 Follower Rings (on 61808ZZ bearings)
     |                      | cable
     |                      v
     |                    TIER 1 Sliders (11 channels, 0 deg rotation)
     |
     +---- GT2 Belt ----> HELIX 2 (300 deg)
     |                      |
     |                      v
     |                    11 Cams -> 11 Followers -> TIER 2 Sliders (120 deg)
     |
     +---- GT2 Belt ----> HELIX 3 (60 deg)
                            |
                            v
                          11 Cams -> 11 Followers -> TIER 3 Sliders (240 deg)
```

---

## Mechanical State Machine

```
                    +-----------------------------+
                    |       CRANK ROTATION        |
                    |     t = 0 -> 360 (1 rev)    |
                    +-------------+---------------+
                                  |
                    +-------------v---------------+
                    |     SHAFT ROTATION (x3)     |
                    |  3 shafts at [180,300,60]   |
                    |  All driven at same omega   |
                    +-------------+---------------+
                                  |
              +-------------------+-------------------+
              v                   v                   v
     +----------------+  +----------------+  +----------------+
     |   HELIX 1      |  |   HELIX 2      |  |   HELIX 3      |
     |   11 discs     |  |   11 discs     |  |   11 discs     |
     |   Phase: 0     |  |   Phase: 120   |  |   Phase: 240   |
     |                |  |                |  |                |
     |  Disc[i] angle |  |  Disc[i] angle |  |  Disc[i] angle |
     |  = t + i*32.7  |  |  = t + i*32.7  |  |  = t + i*32.7  |
     +-------+--------+  +-------+--------+  +-------+--------+
             |                   |                   |
             v                   v                   v
     +----------------+  +----------------+  +----------------+
     | FOLLOWER ORBIT |  | FOLLOWER ORBIT |  | FOLLOWER ORBIT |
     |                |  |                |  |                |
     | x = E*cos(phi) |  | x = E*cos(phi) |  | x = E*cos(phi) |
     | y = E*sin(phi) |  | y = E*sin(phi) |  | y = E*sin(phi) |
     | E = 14.5mm     |  | E = 14.5mm     |  | E = 14.5mm     |
     | (CAM_ECC)      |  | (CAM_ECC)      |  | (CAM_ECC)      |
     |                |  |                |  |                |
     | +/-15 deg stop |  | +/-15 deg stop |  | +/-15 deg stop |
     +-------+--------+  +-------+--------+  +-------+--------+
             | cable             | cable             | cable
             v                   v                   v
     +--------------------------------------------------------+
     |         MONOLITHIC MATRIX (1 piece, print-in-place)     |
     |                                                         |
     |  +---------------------------------------------------+  |
     |  | TIER 1 (Z=+30, rotation=0 deg)                   |  |
     |  |   11 channels x [redirect_in -> slider -> redirect_out] |
     |  |   Slider X = bias + E*sin(t + i*32.7)            |  |
     |  |   FP_ROW_Y = 10mm (U-detour depth)               |  |
     |  |   Side-walls only (no floor/ceiling)              |  |
     |  +---------------------------------------------------+  |
     |                     ZERO GAP (touching)                  |
     |  +---------------------------------------------------+  |
     |  | TIER 2 (Z=0, rotation=120 deg)                   |  |
     |  |   11 channels (same architecture, 120 deg rotated)|  |
     |  +---------------------------------------------------+  |
     |                     ZERO GAP (touching)                  |
     |  +---------------------------------------------------+  |
     |  | TIER 3 (Z=-30, rotation=240 deg)                 |  |
     |  |   11 channels (same architecture, 240 deg rotated)|  |
     |  +---------------------------------------------------+  |
     +--------------------------+------------------------------+
                                | strings (0.5mm Dyneema)
                                | Vertical through monolithic piece
                                | ~62% friction efficiency
                                v
     +--------------------------------------------------------+
     |              GUIDE PLATES (2x PTFE bushings)            |
     |   GP1: Z = -45mm | GP2: Z = -63mm | Gap = 15mm        |
     |   11 bushing positions in hex grid                      |
     |   Funnel entry (5mm) -> 2mm bore -> dampens oscillation |
     |   3 alignment pins at 60 deg intervals (3mm dia)        |
     +--------------------------+------------------------------+
                                | strings
                                v
     +--------------------------------------------------------+
     |              BLOCK GRID (hanging below)                 |
     |   11 hex blocks (30mm FF x 15mm H, 80g each)           |
     |   Z_block = baseline - (1/3) x Sum(tier_contributions) |
     |                                                         |
     |   Per block at (bx, by):                                |
     |     tier_k_contrib = E * sin(t + phase_k(bx,by))       |
     |     phase_k = projection onto tier_k channel axis       |
     |                                                         |
     |   3-tier superposition -> complex wave pattern          |
     |   Max travel ~ +/-3 x E = +/-43.5mm (constructive)     |
     |   Typical travel ~ +/-20-30mm (partial superposition)   |
     +--------------------------------------------------------+
```

---

## Component State Summary

| Component | State Variable | Range | Driver |
|-----------|---------------|-------|--------|
| Crank | theta | 0-360 deg | Hand input |
| Shaft (x3) | omega | same as crank | GT2 belt 1:1 |
| Disc[i] (x11/helix) | cam_angle = theta + i*32.7 deg | continuous | Shaft rotation |
| Bearing (61808ZZ) | orbits with disc | CAM_ECC = 14.5mm | Disc eccentric |
| Follower ring | translates, no rotation | +/-14.5mm orbit | Bearing outer race |
| Soft stop | contact at +/-15 deg | passive | Follower overcorrection |
| Cable | tension / slack | 0 to ~1N | Follower -> slider |
| Slider | X displacement | +/-CAM_ECC | Cable pull |
| Redirect pulleys | spin on axle | free | String passage |
| String | path through 3 tiers | vertical routing | Slider motion |
| Guide bushing | friction damping | eta = 0.99 | String passage |
| Block | Z displacement | +/-43.5mm peak | 3-tier superposition |

---

## Frame State (Static)

```
                    HEXAGRAM STAR FRAME

        Star tip [5]          Star tip [1]
              \                 /
               \   HELIX 3    /
                \   (60 deg) /
    Stub [2]-----x===========x-----Stub [0]
    (240 deg)   / \  MATRIX / \     (0 deg)
               /   \       /   \
              /     \     /     \
    Star    /  HELIX \   / HELIX \   Star
    tip[4] /   2      \ /    1    \  tip[0]
          /   (300)    x   (180)   \
         /             / \          \
        /             /   \          \
       /    Stub [1] /     \          \
              (120)      Star tip [3]

    V_ANGLE = 88.15 deg (auto-computed for parallelism)
    Star tip R = 445mm
    Carrier plate R = 336.2mm (all 6 identical)
    Helix R = 313.2mm
    Corridor gap = 65mm

    LEGS: 3 pairs x Eiffel-tower parabolic
          Splay = 20 deg, Height = 300mm
          Tension ring at base connecting 6 feet
```

---

## Assembly Hierarchy

```
hex_frame_v5_2.scad (TOP LEVEL)
+-- config_v5_2.scad (all parameters)
+-- helix_cam_v5_2.scad (USE'd)
|   +-- helix_assembly_v5(t)
|   |   +-- Central shaft (5mm D-flat, 424mm total)
|   |   +-- 11x eccentric_disc_v5(i)
|   |   +-- 11x 61808ZZ bearing
|   |   +-- 11x follower_ring_v5 + soft_stop_pair
|   |   +-- 10x spacer_collar_v5
|   |   +-- 2x E-clip retainers
|   |   +-- GT2 pulley boss
|   +-- (x3 helixes at 180/300/60 deg)
+-- Hex rings (upper + lower with ledges, compress monolithic matrix)
+-- Anchor plate (top, with 3 alignment pins)
+-- 2x Guide plates (bottom, with alignment pin holes)
+-- 3x Stubs at [0, 120, 240 deg]
+-- 6x Frame arms (parallel corridor pairs)
+-- 6x Carrier plates (625ZZ bearing mounts)
+-- 3x Dampener bar pairs
+-- Block grid (11 blocks, wave animation)
+-- 3x Eiffel-tower leg assemblies + tension ring
```

---

## Build Phase Status

| Phase | Component | Files | Status |
|-------|-----------|-------|--------|
| 1 | Helix Cam | helix_cam_v5_2.scad | DONE (W2 soft stops, 11 cams) |
| 2 | Matrix Tier | matrix_tier_v5.scad | NEEDS V5.2 UPDATE (11ch, side-walls-only) |
| 3 | Matrix Stack | main_stack_v5.scad | NEEDS V5.2 UPDATE (monolithic, zero-gap) |
| 3.5 | Guide Plate | guide_plate_v5.scad | NEEDS V5.2 UPDATE (alignment pins) |
| 4 | Block Grid | (in hex_frame_v5_2) | DONE (basic, needs refinement) |
| 5 | String Routing | not started | PENDING |
| 6 | Frame + Drive | hex_frame_v5_2.scad | FRAME DONE, drive pending |
| 7 | Full Assembly | not started | PENDING |

---

## Key Parameters (True 75% Scale, V5.2)

```
HEX_R           = 89mm           (true 75% of 118mm full-scale)
NUM_CHANNELS    = 11             (derived from HEX_R)
NUM_CAMS        = 11             (1 per channel)
ECCENTRICITY    = 12mm           (wave throw target)
CAM_ECC         = 14.5mm         (disc geometry eccentricity)
FP_ROW_Y        = 10mm           (derived: (FP_OD+SP_OD)/2 + rope gap)
INTER_TIER_GAP  = 0mm            (zero-gap: monolithic print-in-place)
HOUSING_HEIGHT  = 30mm           (derived: 2*FP_ROW_Y + FP_OD + 2)
TIER_PITCH      = 30mm           (housing only, no gap)
HELIX_LENGTH    = 154mm          (11 x 14mm axial pitch)
SHAFT_TOTAL     = 424mm          (helix + extensions)
_STAR_RATIO     = 2.5            (hexagram extension)
V_ANGLE         = 88.15 deg      (auto-computed for arm parallelism)
STAR_TIP_R      = 445mm          (2.5 x 178mm)
HELIX_R         = 313.2mm        (helix center distance from origin)
CARRIER_R       = 336.2mm        (all 6 identical)
SHAFT_DIA       = 5mm            (stainless steel, D-flat)
SLIDER_BIAS     = 0.80           (rest position bias toward helix)
Bearings        = 625ZZ (frame) + 61808ZZ (cam)
Soft stops      = +/-15 deg on each disc (W2 fix)
Alignment pins  = 3x 3mm dia at 60 deg intervals
Matrix stack    = 90mm total (3 x 30mm, zero gap)
```

---

## Manufacturing Notes (V5.2)

- **Monolithic matrix**: entire 3-tier stack is ONE 3D-printed piece (print-in-place)
- **Side-walls only**: no top/bottom walls on channels — enables vertical string routing
- **Zero-gap stacking**: tiers touch directly (Tier 1 bottom on Tier 2 top at 120 deg offset)
- **Sandwich clamping**: anchor plate (top) + monolithic matrix + guide plates (bottom)
- **Frame ring compression**: upper hex ring pushes down on anchor plate, lower ring pushes up on guide plates
- **Alignment pins**: 3 pins at 60 deg intervals on hex perimeter register rotation before clamping
- **Stack height reduction**: 140mm (V5.1) → 90mm (V5.2) — 36% thinner

---

## Changes in V5.2 (from V5.1)

| Parameter | V5.1 | V5.2 | Reason |
|-----------|------|------|--------|
| HEX_R | 98mm (83% actual) | 89mm (true 75%) | Correct 75% scaling |
| NUM_CHANNELS | 13 | 11 | Derived from smaller HEX_R |
| NUM_CAMS | 13 | 11 | 1 cam per channel |
| TWIST_PER_CAM | 27.69 deg | 32.73 deg | 360/11 |
| HELIX_LENGTH | 182mm | 154mm | 11 x 14mm |
| INTER_TIER_GAP | 25mm | 0mm | Monolithic print-in-place |
| TIER_PITCH | 55mm | 30mm | Housing only (no gap) |
| Total stack | 140mm | 90mm | 3 x 30mm zero-gap |
| TIER1_TOP | +70mm | +45mm | Compressed stack |
| TIER3_BOT | -70mm | -45mm | Compressed stack |
| V_ANGLE | 89.25 deg | 88.15 deg | Auto-recomputed for new geometry |
| STAR_TIP_R | 490mm | 445mm | 2.5 x 178mm |
| HELIX_R | 339.2mm | 313.2mm | Auto from frame geometry |
| CARRIER_R | 363.2mm | 336.2mm | Auto from frame geometry |
| SHAFT_TOTAL | 452mm | 424mm | Shorter helix |
| Manufacturing | 3 separate tiers | 1 monolithic piece | Print-in-place |
| Alignment | none | 3 pins at 60 deg | Hex registration |
| Matrix walls | floor + ceiling + side | side-walls only | Vertical string routing |

---

## Tooling Updates (V5.2)

| Tool | Change | Status |
|------|--------|--------|
| validate_geometry.py | Auto-reads config from any config_v*.scad (no hardcoded values) | ACTIVE |
| watch_validate.py | File watcher: auto-validates on .scad save, ntfy.sh notifications | NEW |
| mechanism (Python) | Installed: linkage simulation, SVAJ diagrams, GIF export | NEW |
| Pyslvs-UI | Needs Python <=3.11 (Cython build fails on 3.12) | BLOCKED |
