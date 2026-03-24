/**
 * ui.js — HUD elements: FPS counter, status text, energy meters, genre badge, layer dots.
 */

const fpsEl = document.getElementById("fps");
const statusEl = document.getElementById("status");
const energyPanel = document.getElementById("energy-panel");
const energyFill = document.getElementById("energy-fill");
const handsFill = document.getElementById("hands-fill");
const feetFill = document.getElementById("feet-fill");
const genreBadge = document.getElementById("genre-badge");
const layerPanel = document.getElementById("layer-panel");

// Layer dot elements
const layerDots = {
  drums: document.getElementById("layer-drums"),
  bass: document.getElementById("layer-bass"),
  melody: document.getElementById("layer-melody"),
  pad: document.getElementById("layer-pad"),
};

// Genre colors
const GENRE_COLORS = {
  edm: "#00e5ff",       // cyan
  lofi: "#b388ff",      // purple
  hiphop: "#ff9100",    // orange
  latin: "#ff5252",     // red
  rnb: "#e040fb",       // pink
  cinematic: "#7c4dff", // deep purple
  kpop: "#ff4081",      // hot pink
  afrobeat: "#ffd740",  // gold
};

// Rolling FPS calculation
let frameCount = 0;
let lastFpsUpdate = performance.now();

export function tickFps() {
  frameCount++;
  const now = performance.now();
  if (now - lastFpsUpdate >= 1000) {
    fpsEl.textContent = `${frameCount} FPS`;
    frameCount = 0;
    lastFpsUpdate = now;
  }
}

export function setStatus(msg) {
  statusEl.textContent = msg;
}

export function showEnergyPanel() {
  energyPanel.classList.add("visible");
}

/**
 * Update energy meters. Values are 0-1.
 */
export function updateMeters(energy, hands, feet) {
  energyFill.style.width = `${clamp01(energy) * 100}%`;
  handsFill.style.width = `${clamp01(hands) * 100}%`;
  feetFill.style.width = `${clamp01(feet) * 100}%`;
}

/**
 * Update the genre badge display.
 * @param {string|null} genre - "edm" | "lofi" | "hiphop" | null (hide)
 * @param {number} confidence - 0-1
 */
export function updateGenre(genre, confidence = 0) {
  if (!genreBadge) return;
  if (!genre) {
    genreBadge.style.display = "none";
    if (layerPanel) layerPanel.style.display = "none";
    return;
  }

  const labels = {
    edm: "EDM", lofi: "Lo-fi", hiphop: "Hip-Hop",
    latin: "Latin", rnb: "R&B", cinematic: "Cinematic",
    kpop: "K-Pop", afrobeat: "Afrobeat",
  };
  genreBadge.textContent = labels[genre] || genre;
  genreBadge.style.color = GENRE_COLORS[genre] || "#fff";
  genreBadge.style.borderColor = GENRE_COLORS[genre] || "#fff";
  genreBadge.style.display = "block";
  if (layerPanel) layerPanel.style.display = "flex";
}

/**
 * Update layer activation dots.
 * @param {object|null} layers - { drums, bass, melody, pad } with values 0 (off) or >0 (on)
 */
export function updateLayers(layers) {
  if (!layers) return;
  for (const [name, dot] of Object.entries(layerDots)) {
    if (!dot) continue;
    if (layers[name] > 0) {
      dot.classList.add("active");
    } else {
      dot.classList.remove("active");
    }
  }
}

function clamp01(v) {
  return Math.max(0, Math.min(1, v));
}
