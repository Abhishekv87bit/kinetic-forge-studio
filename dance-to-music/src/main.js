/**
 * main.js — Entry point. Wires pose tracking → kinematics → engine → audio.
 *
 * Four modes:
 *   1. "lyria" (default): AI-generated music via Google Lyria RealTime
 *   2. "stems": Pre-composed stems with energy layers + accents
 *   3. "rules": Rule-based synthesis (backward compat)
 *   4. "ml": V2 LSTM model inference (backward compat)
 */
import { PoseTracker } from "./pose.js?v=3";
import { KinematicsEngine } from "./kinematics.js?v=3";
import { MotionMapper } from "./mapper.js?v=3";
import { MLMapper } from "./ml-mapper.js?v=3";
import { AudioEngine } from "./audio.js?v=3";
import { StemPlayer } from "./stem-player.js?v=3";
import { DanceEngine } from "./dance-engine.js?v=3";
import { LyriaPlayer } from "./lyria-player.js?v=3";
import { LyriaMapper } from "./lyria-mapper.js?v=3";
import { tickFps, setStatus, showEnergyPanel, updateMeters, updateGenre, updateLayers } from "./ui.js?v=3";

const video = document.getElementById("video");
const canvas = document.getElementById("overlay");
const startBtn = document.getElementById("start-btn");
const modeToggle = document.getElementById("mode-toggle");
const genrePicker = document.getElementById("genre-picker");
const genreGrid = document.getElementById("genre-grid");
const genreSwitcher = document.getElementById("genre-switcher");

const tracker = new PoseTracker(video, canvas);
const kinematics = new KinematicsEngine(10, 0.3);
const ruleMapper = new MotionMapper();
const mlMapper = new MLMapper();
const audio = new AudioEngine();
const stemPlayer = new StemPlayer();
const danceEngine = new DanceEngine();

// Lyria — API key from KFS
const GEMINI_API_KEY = "AIzaSyDtt5_A7VOm1wTeoAySBLQ7Bydd_x91OX0";
const lyriaPlayer = new LyriaPlayer(GEMINI_API_KEY);
const lyriaMapper = new LyriaMapper();

// Mode: "lyria" | "stems" | "rules" | "ml"
let mode = "lyria";
let selectedGenre = null;
let mlAvailable = false;
let stemsAvailable = false;
let lyriaAvailable = false;

// Normalization constants for energy meters
const KE_MAX = 15;
const SPEED_MAX = 2.0;

// --- Genre picker: user selects genre before starting ---
let genreTiles = genreGrid ? genreGrid.querySelectorAll(".genre-tile") : [];
genreTiles.forEach((tile) => {
  tile.addEventListener("click", () => {
    // Deselect all
    genreTiles.forEach((t) => t.classList.remove("selected"));
    // Select this one
    tile.classList.add("selected");
    selectedGenre = tile.dataset.genre;
    // Enable start button
    startBtn.disabled = false;
    startBtn.textContent = `Start — ${tile.querySelector("span:last-child").textContent}`;
  });
});

// --- Genre switcher: change genre during playback ---
const genreChips = genreSwitcher ? genreSwitcher.querySelectorAll(".genre-chip") : [];
genreChips.forEach((chip) => {
  chip.addEventListener("click", () => {
    const newGenre = chip.dataset.genre;
    if (newGenre === selectedGenre) return;

    // Update selection UI
    genreChips.forEach((c) => c.classList.remove("active"));
    chip.classList.add("active");
    selectedGenre = newGenre;

    // Update genre badge
    updateGenre(selectedGenre, 1.0);

    // Switch genre in active engine
    if (mode === "lyria" && lyriaAvailable) {
      lyriaPlayer.setGenre(newGenre);
    }
    // Always update rules mapper so genre applies if we fall back
    ruleMapper.setGenre(newGenre);

    console.log(`Genre switched to: ${newGenre}`);
  });
});

// --- Frame loop: pose → physics → engine → sound ---
tracker.onFrame = (landmarks, dt) => {
  tickFps();

  // No person detected — OR partial detection (MediaPipe hallucinates
  // all 33 landmarks even when only a head is visible, causing phantom energy)
  const MIN_VISIBLE_LANDMARKS = 15;
  const VIS_GATE = 0.65;
  let visibleCount = landmarks ? landmarks.filter(lm => (lm.visibility ?? 0) >= VIS_GATE).length : 0;

  if (!landmarks || visibleCount < MIN_VISIBLE_LANDMARKS) {
    kinematics.reset();
    lyriaMapper.reset();
    if (stemsAvailable) danceEngine.reset();
    if (mlAvailable) mlMapper.reset();
    updateMeters(0, 0, 0);

    // Fade stems to silence when no one is dancing
    if (mode === "stems" && stemsAvailable) {
      stemPlayer.setLayerVolumes(0, 0, 0, 0);
      updateLayers({ drums: 0, bass: 0, melody: 0, pad: 0 });
    }

    // Fade Lyria to silence when no one is dancing
    if (mode === "lyria" && lyriaAvailable && lyriaPlayer.playing) {
      lyriaPlayer.setVolume(0);
    }
    return;
  }

  const features = kinematics.push(landmarks, dt);
  if (!features) return;

  // Update energy meters
  const { smoothed } = features;
  updateMeters(
    smoothed.totalKE / KE_MAX,
    smoothed.handSpeed / SPEED_MAX,
    smoothed.footSpeed / SPEED_MAX
  );

  // === LYRIA MODE (primary) ===
  if (mode === "lyria" && lyriaAvailable) {
    lyriaPlayer.setVolume(1.0);
    const mapped = lyriaMapper.update(features, dt);
    lyriaPlayer.updateFromDance(mapped);

    // Debug: log band state every ~1s
    if (!tracker._lastMapperLog || performance.now() - tracker._lastMapperLog > 1000) {
      tracker._lastMapperLog = performance.now();
      const m = mapped;
      const b = m.bandMembers;
      const band = `${b.feetActive ? "DRUMS" : "____"} ${b.coreActive ? "BASS" : "____"} ${b.handsActive ? "MELODY" : "______"} ${b.headActive ? "ATMOS" : "_____"}`;
      console.log(
        `[Band] ${band} | d=${m.density.toFixed(2)} b=${m.brightness.toFixed(2)} ` +
        `g=${m.guidance.toFixed(1)} t=${m.temperature.toFixed(2)} ` +
        `arc=${lyriaMapper.arc} key=${lyriaMapper.bandKey}`
      );
    }

    updateGenre(selectedGenre, 1.0);
    return;
  }

  // === STEM MODE ===
  if (mode === "stems" && stemsAvailable) {
    const result = danceEngine.update(features);

    // Genre switching
    stemPlayer.startGenre(result.genre);
    updateGenre(result.genre, result.genreConfidence);

    // Layer activation (energy-based)
    const padVol = result.layers.pad > 0
      ? result.layers.pad * (0.5 + result.accents.padVolumeBoost * 0.5)
      : 0;

    stemPlayer.setLayerVolumes(
      result.layers.drums,
      result.layers.bass,
      result.layers.melody,
      padVol
    );
    updateLayers(result.layers);

    // Filter cutoff modulation
    stemPlayer.setFilterCutoff(result.accents.filterCutoff);

    // Accent instruments on top of stems
    if (result.accents.drumAccent) {
      stemPlayer.accentDrums(result.accents.drumAccent.velocity);
      audio.playKick(result.accents.drumAccent.velocity * 0.5);
    }
    if (result.accents.hatAccent) {
      audio.playHiHat(result.accents.hatAccent.velocity);
    }

    // Playback rate modulation
    stemPlayer.setPlaybackRate(result.accents.playbackRate);

    // Global effects
    audio.setPan(result.accents.pan);
    audio.setReverb(result.accents.reverb);
    return;
  }

  // === RULES / ML MODE (backward compat) ===
  const activeMapper = mode === "ml" ? mlMapper : ruleMapper;
  const result = activeMapper.update(features);

  if (result.melody) audio.playMelody(result.melody.note, result.melody.velocity, result.melody.duration);
  if (result.bass) audio.playBass(result.bass.note, result.bass.velocity, result.bass.duration);
  if (result.kick) audio.playKick(result.kick.velocity);
  if (result.hihat) audio.playHiHat(result.hihat.velocity);
  if (result.pad) audio.updatePad(result.pad.chord, result.pad.volume);
  if (result.pan !== undefined) audio.setPan(result.pan);
  if (result.reverb !== undefined) audio.setReverb(result.reverb);
};

// --- Mode toggle: cycle through Lyria → Stems → Rules → ML ---
if (modeToggle) {
  modeToggle.addEventListener("click", () => {
    if (mode === "lyria") {
      // Pause Lyria, switch to stems or rules
      if (lyriaAvailable) lyriaPlayer.pause();
      if (stemsAvailable) {
        mode = "stems";
        modeToggle.textContent = "Mode: Stems";
        modeToggle.className = "stems-active";
        setStatus("Stems mode");
      } else {
        mode = "rules";
        modeToggle.textContent = "Mode: Rules";
        modeToggle.className = "";
        setStatus("Rules mode");
      }
      updateGenre(null);
      updateLayers(null);
    } else if (mode === "stems") {
      stemPlayer.setLayerVolumes(0, 0, 0, 0);
      mode = "rules";
      modeToggle.textContent = "Mode: Rules";
      modeToggle.className = "";
      setStatus("Rules mode");
      updateGenre(null);
      updateLayers(null);
    } else if (mode === "rules") {
      if (mlAvailable) {
        mode = "ml";
        modeToggle.textContent = `Mode: ML V${mlMapper.version}`;
        modeToggle.className = "ml-active";
        setStatus(`ML V${mlMapper.version} mode`);
      } else if (lyriaAvailable) {
        mode = "lyria";
        lyriaMapper.reset();
        modeToggle.textContent = "Mode: Lyria AI";
        modeToggle.className = "lyria-active";
        lyriaPlayer.play();
        setStatus("Lyria AI mode");
      } else if (stemsAvailable) {
        mode = "stems";
        modeToggle.textContent = "Mode: Stems";
        modeToggle.className = "stems-active";
        setStatus("Stems mode");
      }
    } else {
      // ML → back to Lyria
      if (lyriaAvailable) {
        mode = "lyria";
        lyriaMapper.reset();
        modeToggle.textContent = "Mode: Lyria AI";
        modeToggle.className = "lyria-active";
        lyriaPlayer.play();
        setStatus("Lyria AI mode");
      } else if (stemsAvailable) {
        mode = "stems";
        modeToggle.textContent = "Mode: Stems";
        modeToggle.className = "stems-active";
        setStatus("Stems mode");
      } else {
        mode = "rules";
        modeToggle.textContent = "Mode: Rules";
        modeToggle.className = "";
        setStatus("Rules mode");
      }
    }
  });
}

// --- Timeout helper ---
function withTimeout(promise, ms, label) {
  return Promise.race([
    promise,
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error(`${label} timed out after ${ms / 1000}s`)), ms)
    ),
  ]);
}

// --- Start button: init everything from user gesture ---
startBtn.addEventListener("click", async () => {
  startBtn.disabled = true;

  // Hide genre picker immediately so loading status is visible
  if (genrePicker) genrePicker.classList.add("hidden");
  startBtn.style.display = "none";

  // Show big centered loading status
  const statusEl = document.getElementById("status");
  statusEl.classList.add("loading");

  try {
    setStatus("Loading pose model...");
    await tracker.init((msg) => setStatus(msg));

    setStatus("Starting audio...");
    await audio.init();

    // Apply selected genre to rules engine (used for accent sounds)
    if (selectedGenre) {
      ruleMapper.setGenre(selectedGenre);
    }

    // Connect to Lyria (always — this is the primary music engine)
    if (selectedGenre) {
      try {
        setStatus("Connecting to Lyria AI...");
        await withTimeout(lyriaPlayer.init(selectedGenre), 15000, "Lyria connection");
        lyriaAvailable = true;
        mode = "lyria";
        console.log(`Lyria connected — genre: ${selectedGenre}`);
      } catch (e) {
        console.error("Lyria failed:", e);
        setStatus(`Lyria error: ${e.message}. Using synth mode.`);
        mode = "rules";
      }
    }

    // If Lyria failed, fall through to rules mode (synth engine)
    if (!lyriaAvailable) {
      mode = "rules";
    }

    // Show genre switcher
    if (genreSwitcher) {
      genreSwitcher.style.display = "flex";
      genreChips.forEach((c) => {
        c.classList.toggle("active", c.dataset.genre === selectedGenre);
      });
    }

    // Show mode indicator
    if (modeToggle) {
      modeToggle.style.display = "block";
      if (mode === "lyria") {
        modeToggle.textContent = "Mode: Lyria AI";
        modeToggle.className = "lyria-active";
      } else {
        modeToggle.textContent = "Mode: Synth";
        modeToggle.className = "";
      }
    }

    // Start music
    if (mode === "lyria" && lyriaAvailable) {
      lyriaPlayer.play();
      setStatus("Lyria AI — dance to generate music");
    } else {
      setStatus("Synth mode — dance to play");
    }

    // Ready — switch status back to small HUD
    statusEl.classList.remove("loading");
    showEnergyPanel();
    tracker.start();
  } catch (err) {
    console.error("Start failed:", err);
    alert(`Start failed: ${err.message}`); // DEBUG: show error on mobile
    // Show error in big centered status (z-index 30, above genre picker)
    setStatus(`Error: ${err.message}`);

    // Show genre picker again (contains the retry button)
    if (genrePicker) genrePicker.classList.remove("hidden");
    startBtn.textContent = `Retry — ${selectedGenre}`;
    startBtn.style.display = "";
    startBtn.disabled = false;
  }
});
