# Triple Helix MVP -- Machine State Diagram
## V5.1 | 75% Scale | February 14, 2026

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
     |                    13 Eccentric Disc Cams
     |                    (27.69 deg twist/cam on 5mm D-flat shaft)
     |                      |
     |                      v
     |                    13 Follower Rings (on 61808ZZ bearings)
     |                      | cable
     |                      v
     |                    TIER 1 Sliders (13 channels, 0 deg rotation)
     |
     +---- GT2 Belt ----> HELIX 2 (300 deg)
     |                      |
     |                      v
     |                    13 Cams -> 13 Followers -> TIER 2 Sliders (120 deg)
     |
     +---- GT2 Belt ----> HELIX 3 (60 deg)
                            |
                            v
                          13 Cams -> 13 Followers -> TIER 3 Sliders (240 deg)
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
     |   13 discs     |  |   13 discs     |  |   13 discs     |
     |   Phase: 0     |  |   Phase: 120   |  |   Phase: 240   |
     |                |  |                |  |                |
     |  Disc[i] angle |  |  Disc[i] angle |  |  Disc[i] angle |
     |  = t + i*27.7  |  |  = t + i*27.7  |  |  = t + i*27.7  |
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
     |              MATRIX ASSEMBLY (3 TIERS)                  |
     |                                                         |
     |  +---------------------------------------------------+  |
     |  | TIER 1 (Z=+100, rotation=0 deg)                  |  |
     |  |   13 channels x [redirect_in -> slider -> redirect_out] |
     |  |   Slider X = bias + E*sin(t + i*27.7)            |  |
     |  |   FP_ROW_Y = 20mm (U-detour depth)               |  |
     |  +---------------------------------------------------+  |
     |                     <-> 25mm gap                        |
     |  +---------------------------------------------------+  |
     |  | TIER 2 (Z=+25, rotation=120 deg)                 |  |
     |  |   13 channels (same architecture, 120 deg rotated)|  |
     |  +---------------------------------------------------+  |
     |                     <-> 25mm gap                        |
     |  +---------------------------------------------------+  |
     |  | TIER 3 (Z=-50, rotation=240 deg)                 |  |
     |  |   13 channels (same architecture, 240 deg rotated)|  |
     |  +---------------------------------------------------+  |
     +--------------------------+------------------------------+
                                | strings (0.5mm Dyneema)
                                | 9 pulleys + 2 PTFE bushings per string
                                | ~62% friction efficiency
                                v
     +--------------------------------------------------------+
     |              GUIDE PLATES (2x PTFE bushings)            |
     |   GP1: Z = -125mm | GP2: Z = -143mm | Gap = 15mm       |
     |   13 bushing positions in hex grid                      |
     |   Funnel entry (5mm) -> 2mm bore -> dampens oscillation |
     +--------------------------+------------------------------+
                                | strings
                                v
     +--------------------------------------------------------+
     |              BLOCK GRID (hanging below)                 |
     |   13 hex blocks (30mm FF x 15mm H, 80g each)           |
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
| Disc[i] (x13/helix) | cam_angle = theta + i*27.7 deg | continuous | Shaft rotation |
| Bearing (61808ZZ) | orbits with disc | CAM_ECC = 14.5mm | Disc eccentric |
| Follower ring | translates, no rotation | +/-14.5mm orbit | Bearing outer race |
| Soft stop | contact at +/-15 deg | passive | Follower overcorrection |
| Cable | tension / slack | 0 to ~1N | Follower -> slider |
| Slider | X displacement | +/-CAM_ECC | Cable pull |
| Redirect pulleys | spin on axle | free | String passage |
| String | path through 3 tiers | 9 contact pts | Slider motion |
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

    V_ANGLE = 89.25 deg (auto-computed for parallelism)
    Star tip R = 490mm
    Carrier plate R = 363.2mm (all 6 identical)
    Helix R = 339.2mm
    Corridor gap = 65mm

    LEGS: 3 pairs x Eiffel-tower parabolic
          Splay = 20 deg, Height = 300mm
          Tension ring at base connecting 6 feet
```

---

## Assembly Hierarchy

```
hex_frame_v5.scad (TOP LEVEL)
+-- config_v5.scad (all parameters)
+-- helix_cam_v5.scad (USE'd)
|   +-- helix_assembly_v5(t)
|   |   +-- Central shaft (5mm D-flat, 452mm total)
|   |   +-- 13x eccentric_disc_v5(i)
|   |   +-- 13x 61808ZZ bearing
|   |   +-- 13x follower_ring_v5 + soft_stop_pair
|   |   +-- 12x spacer_collar_v5
|   |   +-- 2x E-clip retainers
|   |   +-- GT2 pulley boss
|   +-- (x3 helixes at 180/300/60 deg)
+-- Hex rings (upper + lower with ledges)
+-- 3x Stubs at [0, 120, 240 deg]
+-- 6x Frame arms (parallel corridor pairs)
+-- 6x Carrier plates (625ZZ bearing mounts)
+-- 3x Dampener bar pairs
+-- Block grid (13 blocks, wave animation)
+-- 3x Eiffel-tower leg assemblies + tension ring
```

---

## Build Phase Status

| Phase | Component | Files | Status |
|-------|-----------|-------|--------|
| 1 | Helix Cam | helix_cam_v5.scad | DONE (W2 soft stops applied) |
| 2 | Matrix Tier | matrix_tier_v5.scad | DONE (needs revalidate at 75%) |
| 3 | Matrix Stack | main_stack_v5.scad | DONE (needs revalidate) |
| 3.5 | Guide Plate | guide_plate_v5.scad | DONE (needs revalidate) |
| 4 | Block Grid | (in hex_frame_v5) | DONE (basic, needs refinement) |
| 5 | String Routing | not started | PENDING |
| 6 | Frame + Drive | hex_frame_v5.scad | FRAME DONE, drive pending |
| 7 | Full Assembly | not started | PENDING |

---

## Key Parameters (75% Scale, V5.1)

```
HEX_R           = 98mm
NUM_CHANNELS    = 13            (derived from HEX_R)
NUM_CAMS        = 13            (1 per channel)
ECCENTRICITY    = 12mm          (wave throw target)
CAM_ECC         = 14.5mm        (disc geometry eccentricity)
FP_ROW_Y        = 20mm          (U-detour baseline depth)
INTER_TIER_GAP  = 25mm          (string angle accommodation)
HOUSING_HEIGHT  = 50mm          (derived: 2*FP_ROW_Y + FP_OD + 2)
TIER_PITCH      = 75mm          (housing + gap)
HELIX_LENGTH    = 182mm         (13 x 14mm axial pitch)
_STAR_RATIO     = 2.5           (hexagram extension)
V_ANGLE         = 89.25 deg     (auto-computed for arm parallelism)
SHAFT_DIA       = 5mm           (stainless steel, D-flat)
SLIDER_BIAS     = 0.80          (rest position bias toward helix)
Bearings        = 625ZZ (frame) + 61808ZZ (cam)
Soft stops      = +/-15 deg on each disc (W2 fix)
```

---

## Changes in V5.1 (this session)

| Parameter | Before (V5) | After (V5.1) | Reason |
|-----------|-------------|--------------|--------|
| Scale label | 83% | 75% | Corrected to match design intent |
| V_ANGLE | 70.87 (hardcoded) | 89.25 (auto-computed) | Binary search solver for arm parallelism |
| FP_ROW_Y | 10mm (derived) | 20mm (fixed) | Per rope routing analysis, limits inter-tier lateral shift |
| INTER_TIER_GAP | 0mm (zero-gap) | 25mm | String angle accommodation between tiers |
| ECCENTRICITY | 20mm | 12mm | Per master prompt, gentler wave motion |
| SLIDER_BIAS | 0.866 | 0.80 | Per master prompt |
| HOUSING_HEIGHT | 30mm | 50mm | Cascaded from FP_ROW_Y change |
| TIER_PITCH | 30mm | 75mm | Housing + inter-tier gap |
| Soft stops | none | +/-15 deg | W2 audit fix, prevents follower over-rotation |
