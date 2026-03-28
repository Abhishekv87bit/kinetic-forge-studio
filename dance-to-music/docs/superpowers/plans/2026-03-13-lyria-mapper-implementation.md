# Implementation Plan: LyriaMapper Body-is-the-Band Engine

**Date**: 2026-03-13
**Spec**: `docs/superpowers/specs/2026-03-13-lyria-mapper-design.md`
**Branch**: `feat/kfs-v2-workshop-redesign`

---

## Step 1: Create `src/lyria-mapper.js`

New file implementing the `LyriaMapper` class per the spec. Key implementation details:

- **Constants**: All thresholds from spec, plus `SMOOTH_THRESHOLD = 0.6` (missing from spec constants but used in mood logic -- derived from current code's `jerkNorm < 0.4` which maps to `smoothness > 0.6`)
- **Constructor + reset()**: Initialize time-stamped energy/groove histories, burst decay, arc state, groove lock flag
- **update(features, dt)**: 9-section pipeline:
  1. Body part isolation (4 thresholds -> muteDrums/muteBass)
  2. Energy derivative (time-stamped history, scan for past sample, derivative -> arc state)
  3. Smoothness ratio (1 - clamp(jerkMagnitude / JERK_MAX))
  4. Groove lock (totalKE stddev over time window)
  5. Density (gamma curve + body-part scaling + foot burst + arc modulation)
  6. Brightness (60% quality + 40% hand speed + head bob shimmer)
  7. Temperature (smoothstep cubic + low-energy guard + arc modulation)
  8. Guidance (arm spread + build loosening + groove lock override)
  9. Mood prompt (3D: smoothness x energy x dominant body part suffix)
- **Getters**: `arc`, `grooveLocked` for UI/debugging

**Risk**: None -- pure computation, no external dependencies.

## Step 2: Modify `src/lyria-player.js`

Minimal changes to support `moodSuffix`:

1. Add `moodSuffix = ""` to `updateFromDance()` destructured params
2. Add `this._currentMoodSuffix = ""` to constructor
3. Change prompt update condition: `mood !== this._currentMood` becomes `mood !== this._currentMood || moodSuffix !== this._currentMoodSuffix`
4. Append `moodSuffix` to mood text in prompt: `moodText + (moodSuffix || "")`
5. Track `this._currentMoodSuffix = moodSuffix` on update
6. Update console.log to include suffix

**Risk**: None -- additive change, defaults preserve existing behavior.

## Step 3: Modify `src/main.js`

Replace inline Lyria mapping (lines 132-199) with LyriaMapper:

1. Add import: `import { LyriaMapper } from "./lyria-mapper.js?v=3"`
2. Add instance: `const lyriaMapper = new LyriaMapper()` (after other engines, ~line 34)
3. Add `lyriaMapper.reset()` in no-person handler (~line 103)
4. Replace Lyria frame loop (lines 132-199) with 3-line call: `setVolume(1.0)`, `lyriaMapper.update(features, dt)`, `lyriaPlayer.updateFromDance(mapped)`
5. Add `lyriaMapper.reset()` in mode toggle handlers where `mode = "lyria"` is set (lines ~291, ~305)

**Risk**: `dt` availability -- verify `tracker.onFrame` callback receives `dt`. Confirmed: line 93 `tracker.onFrame = (landmarks, dt) => { ... }`.

---

## Verification

After implementation, manually verify the 10 scenarios from the spec (standing still, feet only, full body, foot stomp, smooth swaying, sharp popping, steady groove, energy build, sudden freeze). No automated tests -- this is a real-time audio POC.
