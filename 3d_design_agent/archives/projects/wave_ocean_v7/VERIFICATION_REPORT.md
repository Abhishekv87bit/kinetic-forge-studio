# WAVE OCEAN v7 - VERIFICATION REPORT

**Project:** wave_ocean_v7
**File:** projects/wave_ocean_v7/wave_ocean_v7.scad
**Date:** 2026-01-25
**Mechanism:** Asymmetric Cam Profile (Replaces Failed Four-Bar)

---

## MECHANISM SUMMARY

**Type:** Dual Camshaft + Asymmetric Cam Profile + Belt Drive
**Moving Parts:**
- 22 wave slats (elliptical cam driven)
- 5 foam curls (asymmetric cam driven)
- Belt connecting main shaft to foam shaft

**Motion Character:** Asymmetric "quick up, slow down" wave surge
**Quick-Return Ratio:** 1.5:1 (180° fall / 120° rise)

---

## CRITICAL FIXES APPLIED

### 1. Four-Bar Linkage REMOVED (Failed Grashof)
Previous four-bar linkage failed Grashof condition for ALL 5 curls.
Replaced with asymmetric cam profile for reliable motion.

### 2. Gears REMOVED (4mm Too Far Apart)
Center distance: 34.06mm
Required for mesh: 30mm
Gap: 4.06mm - gears could not mesh
Replaced with belt drive which works at any distance.

### 3. Follower Pad EXTENDED (2.5mm → 5mm)
Previous pad barely touched cam at rest.
Now has 2.5mm engagement depth.

### 4. Curl Body RAISED (+2mm)
Previous position dipped below wave surface at minimum tilt.
Now stays above wave surface at all positions.

---

## VALIDATION

| Check | Result | Value |
|-------|--------|-------|
| Cam-follower contact | PASS | Pad engages cam at all positions |
| Curl above wave | PASS | Body Z > 10mm at all tilts |
| Cam clears frame | PASS | 2mm clearance to base |
| Belt drive | PASS | Spans 34mm naturally |
| Walls | PASS | Min 2.5mm (≥1.2mm required) |

### Asymmetric Cam Parameters

| Curl | Base | Lift | Max Radius | Phase |
|------|------|------|------------|-------|
| 0 | 9mm | 7mm | 16mm | 0° |
| 1 | 9mm | 8mm | 17mm | +16.4° |
| 2 | 9mm | 9mm | 18mm | +32.7° |
| 3 | 9mm | 9mm | 18mm | +49.1° |
| 4 | 9mm | 8mm | 17mm | +65.5° |

### Cam Profile Phases

| Phase | Angle Range | Motion |
|-------|-------------|--------|
| Rise | 0° → 120° | Fast lift (modified cosine) |
| Top dwell | 120° → 150° | Hold at max |
| Fall | 150° → 330° | Slow descent (modified cosine) |
| Bottom dwell | 330° → 360° | Hold at min |

---

## RENDER TEST RESULTS

### Position Tests

| Position | Cam Contact | Curl Above Wave | Collisions |
|----------|-------------|-----------------|------------|
| θ=0° | PASS | PASS (Z=11.2mm) | None |
| θ=120° | PASS | PASS (Z=12.8mm) | None |
| θ=180° | PASS | PASS (Z=12mm) | None |
| θ=330° | PASS | PASS (Z=11.2mm) | None |

---

## BILL OF MATERIALS

### Printed Parts

| Part | Qty | Notes |
|------|-----|-------|
| Frame | 1 | 200×80×50mm |
| Wave Slat | 22 | 3mm thick, with follower pad |
| Curl Piece | 5 | With follower arm (no connecting rod) |
| Asymmetric Cam | 5 | 9mm base + 7-9mm lift |
| Pulley | 2 | 12mm radius |
| Hand Crank | 1 | 25mm arm |

**Total Printed Parts:** 36 pieces (was 42 with four-bar)

### Hardware

| Item | Qty | Size |
|------|-----|------|
| Steel Rod (Hinge Axle) | 1 | ⌀3 × 210mm |
| Steel Rod (Main Camshaft) | 1 | ⌀6 × 210mm |
| Steel Rod (Foam Shaft) | 1 | ⌀6 × 210mm |
| Timing Belt | 1 | ~144mm length, 6mm width |
| E-clips | 6 | ⌀3mm / ⌀6mm |

**Note:** No pins or connecting rods needed (cam-follower contact is direct)

---

## FINAL STATUS

```
══════════════════════════════════════════════════════
VERIFICATION COMPLETE
══════════════════════════════════════════════════════

Project: wave_ocean_v7
File: projects/wave_ocean_v7/wave_ocean_v7.scad

MECHANISM:
  Type: Dual Camshaft + Asymmetric Cam + Belt Drive
  Moving parts: 27 (22 waves + 5 curls)

FIXES APPLIED:
  Four-bar → Asymmetric cam (Grashof failure)
  Gears → Belt drive (34mm > 30mm mesh distance)
  Follower pad: 2.5mm → 5mm (engagement)
  Curl Z offset: +2mm (prevents dip)

VALIDATION:
  Cam-follower contact: PASS (all positions)
  Curl above wave: PASS (Z ≥ 11.2mm)
  Cam-frame clearance: PASS (2mm)
  Walls: 2.5mm min (≥1.2mm) PASS

RENDER TEST:
  θ=0°:   PASS
  θ=120°: PASS
  θ=180°: PASS
  θ=330°: PASS

STATUS: READY TO PRINT
══════════════════════════════════════════════════════
```

---

## USAGE

### Preview Animation
1. Open `wave_ocean_v7.scad` in OpenSCAD
2. View → Animate
3. Set FPS=10, Steps=72
4. Watch: Quick rise (0→120°), slow fall (150→330°)

### Manual Position Testing
1. Set `MANUAL_ANGLE = 0;` (line 20)
2. Test positions: 0, 120, 180, 330
3. Set back to -1 for animation

### Toggle Mechanism
- Line 119: `USE_ASYMMETRIC_SURGE = true;` → Asymmetric cam
- Line 119: `USE_ASYMMETRIC_SURGE = false;` → Original elliptical cam

---

## PROJECT COMPLETE

The wave_ocean_v7 asymmetric surge mechanism has been completely redesigned
to fix all mechanical errors. It is now ready for fabrication.
