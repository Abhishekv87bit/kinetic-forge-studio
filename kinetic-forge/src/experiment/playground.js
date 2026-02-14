// Experiment Mode: Playground — visual exploration toolkit for kinetic art
// 5 tabs: Wave Lab, Patterns, Mechanisms (external tools), 3D Waves, External Tools

import { loadLibraries } from '../components/tool-loader.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { loadPatterns, savePattern } from '../state.js';
import { navigate } from '../router.js';
import { createProject } from '../state.js';
import { setMode } from '../components/mode-toggle.js';
import { showToast } from '../toast.js';
import { promptInput } from '../components/modal.js';
import { createResourceSection, renderMultiContextLinks } from '../components/resource-links.js';
import { getResourcesForContext, getResourcesByCategory, getResourcesByTag, getAllResources } from '../resources.js';
import { createGuidancePanel } from '../components/guidance.js';
import { waveParamsToP5Sketch, wave3DParamsToP5Sketch, patternToP5Sketch, openInP5Editor, createP5Button } from '../components/p5-bridge.js';

const TAB_RESOURCE_MAP = {
  wavelab: 'playground-wavelab',
  patterns: 'playground-patterns',
  mechanisms: 'playground-mechanisms',
  waves3d: 'playground-3d',
  tools: 'playground-tools'
};

// --- State ---
let currentTab = 'wavelab';
let animationId = null;
let threeScene = null;

// Wave Lab state
let waveParams = [
  { A: 2.0, k: 1.0, phi: 0 },
  { A: 1.0, k: 2.3, phi: 0.5 },
  { A: 0.5, k: 3.7, phi: 1.2 }
];
let waveSpeed = 1.0;
let waveTime = 0;

// Patterns state
let patternPreset = 'rose';
let patternParams = { n: 5, radius: 3 };

export async function mount(container) {
  // Check if a pattern was loaded from gallery (bug fix)
  const loadedJSON = sessionStorage.getItem('exp-load-pattern');
  if (loadedJSON) {
    sessionStorage.removeItem('exp-load-pattern');
    try {
      const pattern = JSON.parse(loadedJSON);
      // Map old tab types to new ones
      const tabMap = { graph: 'wavelab', fourier: 'patterns', parametric: 'patterns', linkage: 'mechanisms' };
      currentTab = pattern.type && TAB_RESOURCE_MAP[pattern.type] ? pattern.type : (tabMap[pattern.type] || 'wavelab');

      // Apply pattern params
      if (currentTab === 'wavelab' && pattern.params?.waves) {
        waveParams = pattern.params.waves;
      } else if (currentTab === 'patterns' && pattern.params?.preset) {
        patternPreset = pattern.params.preset;
        patternParams = { ...pattern.params };
        delete patternParams.preset;
      } else if (currentTab === 'waves3d' && pattern.params) {
        // Will be applied in initWaves3D
      }
    } catch (e) {
      console.warn('Failed to parse gallery pattern:', e);
      currentTab = 'wavelab';
    }
  }

  container.innerHTML = `
    <div class="tab-bar">
      <div class="tab ${currentTab === 'wavelab' ? 'active' : ''}" data-tab="wavelab">Wave Lab</div>
      <div class="tab ${currentTab === 'patterns' ? 'active' : ''}" data-tab="patterns">Patterns</div>
      <div class="tab ${currentTab === 'mechanisms' ? 'active' : ''}" data-tab="mechanisms">Mechanisms</div>
      <div class="tab ${currentTab === 'waves3d' ? 'active' : ''}" data-tab="waves3d">3D Waves</div>
      <div class="tab ${currentTab === 'tools' ? 'active' : ''}" data-tab="tools">External Tools</div>
    </div>
    <div id="playground-canvas" class="tool-canvas"></div>
    <div id="slider-panel" class="slider-panel"></div>
  `;

  container.querySelectorAll('.tab').forEach(tab => {
    tab.onclick = () => {
      container.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      currentTab = tab.dataset.tab;
      stopAnimation();
      try { initCurrentTab(); } catch (e) { console.warn('Tab init error:', e); }
      updateSidebar();
    };
  });

  // Load libraries needed for current tab
  if (currentTab === 'wavelab' || currentTab === 'patterns') {
    // Canvas-only, no external libs needed
  } else if (currentTab === 'waves3d') {
    await loadLibraries(['three']);
  }

  try { initCurrentTab(); } catch (e) { console.warn('Init error:', e); }
  updateSidebar();

  if (loadedJSON) {
    try {
      const pattern = JSON.parse(loadedJSON);
      if (pattern.name) showToast(`Loaded "${pattern.name}"`, 'success');
    } catch { /* already handled */ }
  }
}

function initCurrentTab() {
  if (currentTab === 'wavelab') initWaveLab();
  else if (currentTab === 'patterns') initPatterns();
  else if (currentTab === 'mechanisms') initMechanisms();
  else if (currentTab === 'waves3d') initWaves3D();
  else if (currentTab === 'tools') initExternalTools();
}

function stopAnimation() {
  if (animationId) {
    cancelAnimationFrame(animationId);
    animationId = null;
  }
  threeScene = null;
}

// ============================================================
// TAB 1: WAVE LAB — Animated multi-wave superposition
// ============================================================
function initWaveLab() {
  const canvas = document.getElementById('playground-canvas');
  if (!canvas) return;
  canvas.innerHTML = '<canvas id="wave-canvas" style="width:100%;height:100%;background:#111;"></canvas>';
  const sliders = document.getElementById('slider-panel');
  sliders.innerHTML = buildWaveSliders();
  attachWaveSliderEvents();

  const cvs = document.getElementById('wave-canvas');
  cvs.width = cvs.offsetWidth || 700;
  cvs.height = cvs.offsetHeight || 360;

  waveTime = 0;
  animateWaves();
}

function buildWaveSliders() {
  let html = '<div class="slider-panel-inner">';
  for (let i = 0; i < 3; i++) {
    const w = waveParams[i];
    html += `
      <div class="slider-wave-group">
        <div class="slider-wave-label">Wave ${i + 1}</div>
        <div class="slider-group">
          <label>Amplitude <span class="slider-value" id="wA${i}-val">${w.A.toFixed(1)}</span></label>
          <input type="range" id="wA${i}" min="0" max="5" step="0.1" value="${w.A}">
        </div>
        <div class="slider-group">
          <label>Frequency <span class="slider-value" id="wk${i}-val">${w.k.toFixed(1)}</span></label>
          <input type="range" id="wk${i}" min="0.1" max="5" step="0.1" value="${w.k}">
        </div>
        <div class="slider-group">
          <label>Phase <span class="slider-value" id="wp${i}-val">${w.phi.toFixed(2)}</span></label>
          <input type="range" id="wp${i}" min="0" max="6.28" step="0.05" value="${w.phi}">
        </div>
      </div>
    `;
  }
  html += `
    <div class="slider-wave-group">
      <div class="slider-wave-label">Global</div>
      <div class="slider-group">
        <label>Speed <span class="slider-value" id="wspeed-val">${waveSpeed.toFixed(1)}</span></label>
        <input type="range" id="wspeed" min="0" max="3" step="0.1" value="${waveSpeed}">
      </div>
    </div>
  `;
  html += `<div class="wave-formula" id="wave-formula"></div>`;
  html += `<div style="margin-top:10px;padding-top:8px;border-top:1px solid var(--border);">
    ${createP5Button('Open in p5 Editor', 'width:100%;justify-content:center;')}
  </div>`;
  html += '</div>';
  return html;
}

function attachWaveSliderEvents() {
  for (let i = 0; i < 3; i++) {
    ['A', 'k', 'p'].forEach((p, pi) => {
      const el = document.getElementById(`w${p}${i}`);
      const val = document.getElementById(`w${p}${i}-val`);
      if (el) el.oninput = () => {
        const v = parseFloat(el.value);
        if (p === 'A') waveParams[i].A = v;
        else if (p === 'k') waveParams[i].k = v;
        else if (p === 'p') waveParams[i].phi = v;
        val.textContent = p === 'p' ? v.toFixed(2) : v.toFixed(1);
        updateWaveFormula();
      };
    });
  }
  const speedEl = document.getElementById('wspeed');
  if (speedEl) speedEl.oninput = () => {
    waveSpeed = parseFloat(speedEl.value);
    document.getElementById('wspeed-val').textContent = waveSpeed.toFixed(1);
  };
  // p5 Editor button
  const p5Btn = document.querySelector('.p5-editor-btn');
  if (p5Btn) p5Btn.onclick = () => openInP5Editor(waveParamsToP5Sketch(waveParams, waveSpeed), 'Wave Superposition');
  updateWaveFormula();
}

function updateWaveFormula() {
  const el = document.getElementById('wave-formula');
  if (!el) return;
  const parts = waveParams.filter(w => w.A > 0).map((w, i) =>
    `${w.A.toFixed(1)}sin(${w.k.toFixed(1)}x + ${w.phi.toFixed(1)})`
  );
  el.textContent = 'y = ' + (parts.join(' + ') || '0');
}

function animateWaves() {
  const cvs = document.getElementById('wave-canvas');
  if (!cvs) return;
  const ctx = cvs.getContext('2d');
  const W = cvs.width;
  const H = cvs.height;

  function frame() {
    ctx.clearRect(0, 0, W, H);

    // Grid lines
    ctx.strokeStyle = '#222';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, H / 2);
    ctx.lineTo(W, H / 2);
    ctx.stroke();

    // Individual waves (dim)
    waveParams.forEach((w, i) => {
      if (w.A <= 0) return;
      const colors = ['#4fc3f733', '#66bb6a33', '#ffa72633'];
      ctx.strokeStyle = colors[i] || '#4fc3f733';
      ctx.lineWidth = 1;
      ctx.beginPath();
      for (let px = 0; px < W; px++) {
        const x = (px / W) * 4 * Math.PI - 2 * Math.PI;
        const y = w.A * Math.sin(w.k * x + w.phi + waveSpeed * waveTime);
        const cy = H / 2 - y * (H / 8);
        if (px === 0) ctx.moveTo(px, cy); else ctx.lineTo(px, cy);
      }
      ctx.stroke();
    });

    // Superposition (bright)
    ctx.strokeStyle = '#4fc3f7';
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    for (let px = 0; px < W; px++) {
      const x = (px / W) * 4 * Math.PI - 2 * Math.PI;
      let y = 0;
      waveParams.forEach(w => {
        y += w.A * Math.sin(w.k * x + w.phi + waveSpeed * waveTime);
      });
      const cy = H / 2 - y * (H / 8);
      if (px === 0) ctx.moveTo(px, cy); else ctx.lineTo(px, cy);
    }
    ctx.stroke();

    waveTime += 0.02;
    animationId = requestAnimationFrame(frame);
  }

  frame();
}

// ============================================================
// TAB 2: PATTERNS — Rose, Lissajous, Spirograph, Fourier, Butterfly
// ============================================================
const PATTERN_PRESETS = {
  rose: { label: 'Rose Curve', defaults: { n: 5, radius: 3 }, sliders: [
    { id: 'pn', label: 'Petals', key: 'n', min: 1, max: 12, step: 1 },
    { id: 'pr', label: 'Radius', key: 'radius', min: 0.5, max: 5, step: 0.5 }
  ]},
  lissajous: { label: 'Lissajous', defaults: { p: 3, q: 2, delta: 1.57 }, sliders: [
    { id: 'pp', label: 'Ratio P', key: 'p', min: 1, max: 7, step: 1 },
    { id: 'pq', label: 'Ratio Q', key: 'q', min: 1, max: 7, step: 1 },
    { id: 'pd', label: 'Phase', key: 'delta', min: 0, max: 6.28, step: 0.1 }
  ]},
  spirograph: { label: 'Spirograph', defaults: { R: 4, r: 1, d: 2 }, sliders: [
    { id: 'pR', label: 'Outer R', key: 'R', min: 1, max: 8, step: 0.5 },
    { id: 'prr', label: 'Inner r', key: 'r', min: 0.5, max: 4, step: 0.25 },
    { id: 'pdd', label: 'Pen d', key: 'd', min: 0.5, max: 5, step: 0.25 }
  ]},
  fourier: { label: 'Fourier', defaults: { harmonics: 5, waveType: 'square' }, sliders: [
    { id: 'pfh', label: 'Harmonics', key: 'harmonics', min: 1, max: 30, step: 1 }
  ]},
  butterfly: { label: 'Butterfly', defaults: {}, sliders: [] }
};

function initPatterns() {
  const canvas = document.getElementById('playground-canvas');
  if (!canvas) return;

  canvas.innerHTML = `
    <div style="padding:12px 12px 0;">
      <div class="preset-selector" id="pattern-chips"></div>
    </div>
    <canvas id="pattern-canvas" style="width:100%;background:#111;"></canvas>
  `;

  const sliderPanel = document.getElementById('slider-panel');
  const chips = document.getElementById('pattern-chips');

  // Render chips
  chips.innerHTML = Object.entries(PATTERN_PRESETS).map(([key, p]) =>
    `<button class="preset-chip ${key === patternPreset ? 'active' : ''}" data-preset="${key}">${p.label}</button>`
  ).join('');

  chips.querySelectorAll('.preset-chip').forEach(chip => {
    chip.onclick = () => {
      patternPreset = chip.dataset.preset;
      patternParams = { ...PATTERN_PRESETS[patternPreset].defaults };
      chips.querySelectorAll('.preset-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      renderPatternSliders(sliderPanel);
      drawPattern();
    };
  });

  // Set defaults if needed
  if (!patternParams || Object.keys(patternParams).length === 0) {
    patternParams = { ...PATTERN_PRESETS[patternPreset].defaults };
  }

  renderPatternSliders(sliderPanel);

  // Size and draw
  const cvs = document.getElementById('pattern-canvas');
  cvs.width = cvs.offsetWidth || 500;
  cvs.height = 400;
  drawPattern();
}

function renderPatternSliders(container) {
  const preset = PATTERN_PRESETS[patternPreset];
  if (!preset) return;

  let html = '<div class="slider-panel-inner">';

  if (patternPreset === 'fourier') {
    html += `
      <div class="slider-group">
        <label>Wave Type</label>
        <select id="pf-type" style="background:var(--bg-elevated);color:var(--text);border:1px solid var(--border);padding:4px 8px;border-radius:4px;">
          <option value="square" ${patternParams.waveType === 'square' ? 'selected' : ''}>Square</option>
          <option value="sawtooth" ${patternParams.waveType === 'sawtooth' ? 'selected' : ''}>Sawtooth</option>
          <option value="triangle" ${patternParams.waveType === 'triangle' ? 'selected' : ''}>Triangle</option>
        </select>
      </div>
    `;
  }

  preset.sliders.forEach(s => {
    const val = patternParams[s.key] ?? s.min;
    html += `
      <div class="slider-group">
        <label>${s.label} <span class="slider-value" id="${s.id}-val">${Number(val).toFixed(s.step < 1 ? 1 : 0)}</span></label>
        <input type="range" id="${s.id}" min="${s.min}" max="${s.max}" step="${s.step}" value="${val}">
      </div>
    `;
  });

  html += `<div style="margin-top:10px;padding-top:8px;border-top:1px solid var(--border);">
    ${createP5Button('Try in p5 Editor', 'width:100%;justify-content:center;')}
  </div>`;
  html += '</div>';
  container.innerHTML = html;

  // Attach events
  preset.sliders.forEach(s => {
    const el = document.getElementById(s.id);
    if (el) el.oninput = () => {
      patternParams[s.key] = parseFloat(el.value);
      const valEl = document.getElementById(`${s.id}-val`);
      if (valEl) valEl.textContent = Number(el.value).toFixed(s.step < 1 ? 1 : 0);
      drawPattern();
    };
  });

  const typeEl = document.getElementById('pf-type');
  if (typeEl) typeEl.onchange = () => {
    patternParams.waveType = typeEl.value;
    drawPattern();
  };

  // p5 Editor button for patterns
  const p5Btn = container.querySelector('.p5-editor-btn');
  if (p5Btn) p5Btn.onclick = () => openInP5Editor(patternToP5Sketch(patternPreset, patternParams), `${PATTERN_PRESETS[patternPreset]?.label || 'Pattern'} Curve`);
}

function drawPattern() {
  const cvs = document.getElementById('pattern-canvas');
  if (!cvs) return;
  const ctx = cvs.getContext('2d');
  const W = cvs.width;
  const H = cvs.height;
  ctx.clearRect(0, 0, W, H);

  ctx.strokeStyle = '#4fc3f7';
  ctx.lineWidth = 2;
  ctx.beginPath();

  if (patternPreset === 'rose') {
    const n = patternParams.n || 5;
    const r = patternParams.radius || 3;
    const scale = Math.min(W, H) / (2 * r + 1);
    for (let i = 0; i <= 2000; i++) {
      const t = (i / 2000) * 2 * Math.PI * (n % 2 === 0 ? 1 : 2);
      const rr = r * Math.cos(n * t);
      const x = W / 2 + rr * Math.cos(t) * scale * 0.35;
      const y = H / 2 - rr * Math.sin(t) * scale * 0.35;
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
  } else if (patternPreset === 'lissajous') {
    const p = patternParams.p || 3;
    const q = patternParams.q || 2;
    const delta = patternParams.delta || Math.PI / 2;
    for (let i = 0; i <= 1000; i++) {
      const t = (i / 1000) * 2 * Math.PI;
      const x = W / 2 + Math.sin(p * t + delta) * (W / 2.5);
      const y = H / 2 - Math.sin(q * t) * (H / 2.5);
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
  } else if (patternPreset === 'spirograph') {
    const R = patternParams.R || 4;
    const r = patternParams.r || 1;
    const d = patternParams.d || 2;
    const maxT = 2 * Math.PI * r / gcd(R, r);
    const scale = Math.min(W, H) / (2 * (R + d) + 2);
    for (let i = 0; i <= 2000; i++) {
      const t = (i / 2000) * maxT * 10;
      const x = W / 2 + ((R - r) * Math.cos(t) + d * Math.cos((R - r) / r * t)) * scale * 0.35;
      const y = H / 2 - ((R - r) * Math.sin(t) - d * Math.sin((R - r) / r * t)) * scale * 0.35;
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
  } else if (patternPreset === 'fourier') {
    const N = patternParams.harmonics || 5;
    const type = patternParams.waveType || 'square';
    // Target (dashed)
    ctx.strokeStyle = '#333';
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    for (let px = 0; px < W; px++) {
      const x = (px / W) * 4 * Math.PI - 2 * Math.PI;
      let y = 0;
      if (type === 'square') y = Math.sign(Math.sin(x));
      else if (type === 'sawtooth') y = ((x % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI) / Math.PI - 1;
      else if (type === 'triangle') y = 2 * Math.abs(2 * (x / (2 * Math.PI) - Math.floor(x / (2 * Math.PI) + 0.5))) - 1;
      const cy = H / 2 - y * (H / 4);
      if (px === 0) ctx.moveTo(px, cy); else ctx.lineTo(px, cy);
    }
    ctx.stroke();
    ctx.setLineDash([]);
    // Approximation
    ctx.strokeStyle = '#4fc3f7';
    ctx.beginPath();
    for (let px = 0; px < W; px++) {
      const x = (px / W) * 4 * Math.PI - 2 * Math.PI;
      let y = 0;
      for (let n = 1; n <= N; n++) {
        if (type === 'square') { const k = 2 * n - 1; y += (4 / Math.PI) * Math.sin(k * x) / k; }
        else if (type === 'sawtooth') { y += 2 * Math.pow(-1, n + 1) * Math.sin(n * x) / (n * Math.PI); }
        else if (type === 'triangle') { const k = 2 * n - 1; y += (8 / (Math.PI * Math.PI)) * Math.pow(-1, n - 1) * Math.sin(k * x) / (k * k); }
      }
      const cy = H / 2 - y * (H / 4);
      if (px === 0) ctx.moveTo(px, cy); else ctx.lineTo(px, cy);
    }
    // Axis
    ctx.stroke();
    ctx.strokeStyle = '#444';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, H / 2);
    ctx.lineTo(W, H / 2);
    ctx.stroke();
    return;
  } else if (patternPreset === 'butterfly') {
    for (let i = 0; i <= 2000; i++) {
      const t = (i / 2000) * 2 * Math.PI;
      const factor = Math.exp(Math.cos(t)) - 2 * Math.cos(4 * t) + Math.pow(Math.sin(t / 12), 5);
      const x = W / 2 + Math.sin(t) * factor * (W / 8);
      const y = H / 2 - Math.cos(t) * factor * (H / 8);
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
  }
  ctx.stroke();
}

function gcd(a, b) {
  a = Math.abs(Math.round(a * 100));
  b = Math.abs(Math.round(b * 100));
  while (b) { [a, b] = [b, a % b]; }
  return a / 100;
}

// ============================================================
// TAB 3: MECHANISMS — External tool launcher
// ============================================================
const MECHANISM_TOOLS = [
  { section: 'Linkage Design', tools: [
    { id: 'motiongen', name: 'MotionGen Pro', url: 'https://motiongen.io/', desc: 'AI-driven path synthesis — draw the curve you want, get a linkage that produces it. Best for four-bar and six-bar linkages.' },
    { id: 'pmks', name: 'PMKS+', url: 'https://designengrlab.github.io/PMKS/', desc: 'Planar Mechanism Kinematic Simulator. Define joints and links, see motion paths, export data. The gold standard for linkage analysis.' },
    { id: 'mevirtuoso', name: 'MEvirtuoso', url: 'https://www.mevirtuoso.com/', desc: 'Mechanism design and analysis tool with interactive visualization and parameter optimization.' },
  ]},
  { section: 'Cam & Gear Design', tools: [
    { id: '507movements', name: '507 Mechanical Movements', url: 'http://507movements.com/', desc: 'Animated catalog of 507 historical mechanisms — cams, gears, linkages, ratchets, escapements. Essential reference.' },
    { id: 'geargenerator', name: 'Gear Generator', url: 'https://geargenerator.com/', desc: 'Interactive involute spur gear designer. Set module, teeth count, pressure angle — export SVG for cutting.' },
    { id: 'kmoddl', name: 'KMODDL (Cornell)', url: 'https://kmoddl.library.cornell.edu/', desc: 'Cornell University Kinematic Models Digital Library. 3D scans of historical teaching models.' },
  ]},
  { section: 'Walking Mechanisms', tools: [
    { id: 'strandbeest', name: 'Strandbeest Leg Simulator', url: 'https://www.diywalkers.com/strandbeest-leg-simulator.html', desc: 'Interactive Jansen leg linkage simulator — adjust the "holy numbers" and see the leg path change in real-time.' },
    { id: 'diywalkers', name: 'DIY Walkers', url: 'https://www.diywalkers.com/', desc: 'Walking mechanism design resources, plans, and build guides. Klann, Jansen, and original linkages.' },
  ]},
  { section: 'Reference & Learning', tools: [
    { id: 'thang', name: 'Thang010146 (YouTube)', url: 'https://www.youtube.com/@thang010146', desc: '2000+ mechanism animations — the most comprehensive visual catalog of mechanisms anywhere. Search by motion type.' },
    { id: 'cmu', name: 'CMU Mechanism Course', url: 'http://www.cs.cmu.edu/~rapidproto/mechanisms/tableofcontents.html', desc: 'Carnegie Mellon mechanism design reference — clear explanations of linkage types, cam design, gear trains.' },
    { id: 'woodgears', name: 'Woodgears.ca', url: 'https://woodgears.ca/', desc: 'Gear template generator plus wooden mechanism projects. Great for understanding gear mesh and tooth profiles.' },
  ]},
];

function initMechanisms() {
  const canvas = document.getElementById('playground-canvas');
  const sliders = document.getElementById('slider-panel');
  if (!canvas) return;
  sliders.innerHTML = '';

  let html = `
    <div style="padding:16px;">
      <p class="text-dim text-sm" style="margin-bottom:16px;">
        Use these professional tools to explore and design mechanisms. Each one lets you interactively build, test, and understand different mechanism types.
      </p>
  `;

  MECHANISM_TOOLS.forEach(section => {
    html += `<div class="section-title" style="margin-top:16px;margin-bottom:8px;">${section.section.toUpperCase()}</div>`;
    html += '<div class="tool-card-grid">';
    section.tools.forEach(tool => {
      html += `
        <div class="tool-card">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;">
            <strong class="text-sm">${tool.name}</strong>
            <a href="${tool.url}" target="_blank" rel="noopener" class="primary" style="padding:3px 10px;font-size:10px;text-decoration:none;border:1px solid var(--accent);border-radius:4px;">Open</a>
          </div>
          <div class="text-sm text-dim">${tool.desc}</div>
        </div>
      `;
    });
    html += '</div>';
  });

  html += '</div>';
  canvas.innerHTML = html;
}

// ============================================================
// TAB 4: 3D WAVES — Margolin-style wave laboratory
// ============================================================
let wave3dWaves = [
  { id: 1, A: 1.5, kx: 2, ky: 0, phi: 0, omega: 1.0, enabled: true },
  { id: 2, A: 1.0, kx: 0, ky: 2, phi: Math.PI / 4, omega: 0.8, enabled: true },
];
let wave3dInteractionMode = 'superposition';
let wave3dTime = 0;
let wave3dNextId = 3;

// Keep legacy reference for save compatibility
let wave3dParams = { amplitude: 1.5, freqX: 2, freqY: 2, sources: 1, phaseOffset: 0, speed: 1.0 };

const WAVE_PRESETS = {
  perpendicular: { label: 'Perpendicular', waves: [
    { A: 1.5, kx: 2, ky: 0, phi: 0, omega: 1.0 },
    { A: 1.5, kx: 0, ky: 2, phi: 0, omega: 1.0 },
  ]},
  radial: { label: 'Margolin Radial', waves: [
    { A: 1.2, kx: 2, ky: 0, phi: 0, omega: 0.8 },
    { A: 1.2, kx: -1, ky: 1.73, phi: 2.09, omega: 0.8 },
    { A: 1.2, kx: -1, ky: -1.73, phi: 4.19, omega: 0.8 },
  ]},
  ocean: { label: 'Ocean Swell', waves: [
    { A: 2.0, kx: 1.5, ky: 0.3, phi: 0, omega: 0.6 },
    { A: 0.8, kx: 2.5, ky: -0.5, phi: 1.2, omega: 1.2 },
  ]},
  standing: { label: 'Standing Wave', waves: [
    { A: 1.5, kx: 2, ky: 0, phi: 0, omega: 1.0 },
    { A: 1.5, kx: -2, ky: 0, phi: 0, omega: 1.0 },
  ]},
  hex: { label: 'Hex Symmetry', waves: [
    { A: 1.0, kx: 2, ky: 0, phi: 0, omega: 0.7 },
    { A: 1.0, kx: 1, ky: 1.73, phi: 1.05, omega: 0.7 },
    { A: 1.0, kx: -1, ky: 1.73, phi: 2.09, omega: 0.7 },
    { A: 1.0, kx: -2, ky: 0, phi: 3.14, omega: 0.7 },
    { A: 1.0, kx: -1, ky: -1.73, phi: 4.19, omega: 0.7 },
    { A: 1.0, kx: 1, ky: -1.73, phi: 5.24, omega: 0.7 },
  ]},
};

async function initWaves3D() {
  const canvas = document.getElementById('playground-canvas');
  const sliderPanel = document.getElementById('slider-panel');
  if (!canvas) return;

  await loadLibraries(['three']);
  if (typeof THREE === 'undefined') {
    canvas.innerHTML = '<p class="text-dim" style="padding:20px">Loading Three.js...</p>';
    return;
  }

  canvas.innerHTML = '<div id="three-container" style="width:100%;height:100%;min-height:360px;"></div>';
  sliderPanel.innerHTML = build3DWavePanel();
  renderWaveControls();
  attach3DGlobalEvents();

  const container = document.getElementById('three-container');
  const W = container.offsetWidth || 700;
  const H = container.offsetHeight || 360;

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x111111);

  const camera = new THREE.PerspectiveCamera(50, W / H, 0.1, 1000);
  camera.position.set(15, 12, 15);
  camera.lookAt(0, 0, 0);

  const renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(W, H);
  container.appendChild(renderer.domElement);

  const grid = new THREE.GridHelper(20, 20, 0x333333, 0x222222);
  scene.add(grid);

  const segments = 60;
  const geometry = new THREE.PlaneGeometry(20, 20, segments, segments);
  geometry.rotateX(-Math.PI / 2);
  const material = new THREE.MeshPhongMaterial({
    color: 0x4fc3f7, wireframe: false, side: THREE.DoubleSide,
    transparent: true, opacity: 0.85, flatShading: true
  });
  const mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);

  const ambient = new THREE.AmbientLight(0x404040);
  scene.add(ambient);
  const directional = new THREE.DirectionalLight(0xffffff, 0.8);
  directional.position.set(10, 20, 10);
  scene.add(directional);

  threeScene = { scene, camera, renderer, mesh, geometry, segments };

  let isDragging = false;
  let prevMouse = { x: 0, y: 0 };
  let rotY = -0.5;
  let rotX = 0.6;

  renderer.domElement.onmousedown = (e) => { isDragging = true; prevMouse = { x: e.clientX, y: e.clientY }; };
  renderer.domElement.onmouseup = () => isDragging = false;
  renderer.domElement.onmouseleave = () => isDragging = false;
  renderer.domElement.onmousemove = (e) => {
    if (!isDragging) return;
    rotY += (e.clientX - prevMouse.x) * 0.005;
    rotX += (e.clientY - prevMouse.y) * 0.005;
    rotX = Math.max(-1.2, Math.min(1.2, rotX));
    prevMouse = { x: e.clientX, y: e.clientY };
    const r = 22;
    camera.position.set(r * Math.sin(rotY) * Math.cos(rotX), r * Math.sin(rotX) + 5, r * Math.cos(rotY) * Math.cos(rotX));
    camera.lookAt(0, 0, 0);
  };

  wave3dTime = 0;
  animate3DWaves();
}

function build3DWavePanel() {
  return `<div class="slider-panel-inner" style="max-height:calc(100vh - 200px);overflow-y:auto;">
    <div class="section-title" style="margin-bottom:6px;">PRESETS</div>
    <div class="preset-chips" id="wave3d-presets">
      ${Object.entries(WAVE_PRESETS).map(([k, v]) =>
        `<span class="preset-chip" data-preset="${k}">${v.label}</span>`
      ).join('')}
    </div>

    <div class="section-title" style="margin-top:12px;margin-bottom:6px;">WAVE COMPONENTS</div>
    <div id="wave3d-list"></div>
    <button id="wave3d-add" style="width:100%;margin-top:8px;">+ Add Wave</button>

    <div class="section-title" style="margin-top:12px;margin-bottom:6px;">INTERACTION</div>
    <div class="slider-group">
      <label style="width:50px;">Mode</label>
      <select id="wave3d-mode" style="flex:1;background:var(--bg);color:var(--text);border:1px solid var(--border);padding:4px;font-size:11px;">
        <option value="superposition" ${wave3dInteractionMode === 'superposition' ? 'selected' : ''}>Superposition (Sum)</option>
        <option value="product" ${wave3dInteractionMode === 'product' ? 'selected' : ''}>Product</option>
        <option value="max" ${wave3dInteractionMode === 'max' ? 'selected' : ''}>Maximum</option>
      </select>
    </div>

    <div class="mechanism-info" style="margin-top:12px;" id="wave3d-formula">
      <div class="mech-title">Margolin Wave Equation</div>
      <div class="mech-desc" id="wave3d-formula-text" style="font-family:var(--mono);font-size:10px;word-break:break-all;"></div>
    </div>

    <div style="margin-top:12px;padding-top:8px;border-top:1px solid var(--border);">
      ${createP5Button('Open in p5 Editor (WebGL)', 'width:100%;justify-content:center;')}
    </div>
  </div>`;
}

function renderWaveControls() {
  const container = document.getElementById('wave3d-list');
  if (!container) return;

  const colors = ['#4fc3f7', '#66bb6a', '#ffa726', '#ef5350', '#ab47bc', '#26c6da', '#ffca28', '#ec407a'];
  container.innerHTML = wave3dWaves.map((w, i) => `
    <div class="wave3d-item" data-id="${w.id}" style="background:var(--bg);padding:8px;border-radius:4px;margin-bottom:6px;border-left:3px solid ${colors[i % colors.length]};">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:4px;">
        <span style="font-size:11px;font-weight:600;color:${colors[i % colors.length]};">Wave ${i + 1}</span>
        <div style="display:flex;gap:4px;align-items:center;">
          <input type="checkbox" class="w3d-toggle" data-id="${w.id}" ${w.enabled ? 'checked' : ''} style="accent-color:var(--accent);">
          ${wave3dWaves.length > 1 ? `<button class="w3d-remove" data-id="${w.id}" style="padding:1px 5px;font-size:10px;line-height:1;">x</button>` : ''}
        </div>
      </div>
      <div class="slider-group"><label>A</label>
        <input type="range" class="w3d-A" data-id="${w.id}" min="0.1" max="3" step="0.1" value="${w.A}">
        <span class="slider-value">${w.A.toFixed(1)}</span>
      </div>
      <div class="slider-group"><label>kx</label>
        <input type="range" class="w3d-kx" data-id="${w.id}" min="-5" max="5" step="0.1" value="${w.kx}">
        <span class="slider-value">${w.kx.toFixed(1)}</span>
      </div>
      <div class="slider-group"><label>ky</label>
        <input type="range" class="w3d-ky" data-id="${w.id}" min="-5" max="5" step="0.1" value="${w.ky}">
        <span class="slider-value">${w.ky.toFixed(1)}</span>
      </div>
      <div class="slider-group"><label>phase</label>
        <input type="range" class="w3d-phi" data-id="${w.id}" min="0" max="6.28" step="0.05" value="${w.phi}">
        <span class="slider-value">${w.phi.toFixed(2)}</span>
      </div>
      <div class="slider-group"><label>speed</label>
        <input type="range" class="w3d-omega" data-id="${w.id}" min="0" max="3" step="0.1" value="${w.omega}">
        <span class="slider-value">${w.omega.toFixed(1)}</span>
      </div>
      <div class="text-sm text-dim" style="margin-top:2px;font-size:10px;">
        Dir: ${Math.abs(w.kx) > Math.abs(w.ky) ? 'X-dominant' : Math.abs(w.ky) > Math.abs(w.kx) ? 'Y-dominant' : 'Diagonal'}
        (${(Math.atan2(w.ky, w.kx) * 180 / Math.PI).toFixed(0)}deg)
      </div>
    </div>
  `).join('');

  attachWaveControlEvents();
  updateWave3DFormula();
}

function attachWaveControlEvents() {
  document.querySelectorAll('.w3d-A, .w3d-kx, .w3d-ky, .w3d-phi, .w3d-omega').forEach(el => {
    el.oninput = () => {
      const id = parseInt(el.dataset.id);
      const wave = wave3dWaves.find(w => w.id === id);
      if (!wave) return;
      const prop = el.className.split(' ')[0].replace('w3d-', '');
      wave[prop] = parseFloat(el.value);
      el.nextElementSibling.textContent = prop === 'phi' ? parseFloat(el.value).toFixed(2) : parseFloat(el.value).toFixed(1);
      updateWave3DFormula();
    };
  });

  document.querySelectorAll('.w3d-toggle').forEach(el => {
    el.onchange = () => {
      const id = parseInt(el.dataset.id);
      const wave = wave3dWaves.find(w => w.id === id);
      if (wave) wave.enabled = el.checked;
      updateWave3DFormula();
    };
  });

  document.querySelectorAll('.w3d-remove').forEach(el => {
    el.onclick = () => {
      const id = parseInt(el.dataset.id);
      wave3dWaves = wave3dWaves.filter(w => w.id !== id);
      renderWaveControls();
    };
  });
}

function attach3DGlobalEvents() {
  document.getElementById('wave3d-add')?.addEventListener('click', () => {
    wave3dWaves.push({
      id: wave3dNextId++,
      A: 1.0,
      kx: +(Math.random() * 4 - 2).toFixed(1),
      ky: +(Math.random() * 4 - 2).toFixed(1),
      phi: +(Math.random() * Math.PI * 2).toFixed(2),
      omega: +(0.5 + Math.random()).toFixed(1),
      enabled: true
    });
    renderWaveControls();
  });

  document.getElementById('wave3d-mode')?.addEventListener('change', (e) => {
    wave3dInteractionMode = e.target.value;
  });

  document.querySelectorAll('#wave3d-presets .preset-chip').forEach(chip => {
    chip.onclick = () => {
      const preset = WAVE_PRESETS[chip.dataset.preset];
      if (!preset) return;
      wave3dWaves = preset.waves.map((w, i) => ({
        id: wave3dNextId++, ...w, enabled: true
      }));
      renderWaveControls();
      document.querySelectorAll('#wave3d-presets .preset-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
    };
  });

  // p5 Editor button for 3D waves
  const p5Btn3d = document.querySelector('.p5-editor-btn');
  if (p5Btn3d) p5Btn3d.onclick = () => openInP5Editor(wave3DParamsToP5Sketch(wave3dWaves, wave3dInteractionMode), 'Margolin 3D Wave Field (WebGL)');
}

function updateWave3DFormula() {
  const el = document.getElementById('wave3d-formula-text');
  if (!el) return;
  const enabled = wave3dWaves.filter(w => w.enabled);
  el.textContent = enabled.length > 0
    ? 'h(x,y,t) = ' + enabled.map(w =>
        `${w.A.toFixed(1)}sin(${w.kx.toFixed(1)}x + ${w.ky.toFixed(1)}y - ${w.omega.toFixed(1)}t + ${w.phi.toFixed(2)})`
      ).join(wave3dInteractionMode === 'product' ? ' * ' : ' + ')
    : 'h(x,y,t) = 0';
}

function animate3DWaves() {
  if (!threeScene) return;
  const { renderer, scene, camera, mesh, geometry } = threeScene;
  const pos = geometry.attributes.position;
  const enabled = wave3dWaves.filter(w => w.enabled);

  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i);
    const z = pos.getZ(i);
    let y = 0;

    if (wave3dInteractionMode === 'superposition') {
      for (const w of enabled) {
        y += w.A * Math.sin(w.kx * x + w.ky * z - w.omega * wave3dTime + w.phi);
      }
    } else if (wave3dInteractionMode === 'product') {
      y = enabled.length > 0 ? 1 : 0;
      for (const w of enabled) {
        y *= w.A * Math.sin(w.kx * x + w.ky * z - w.omega * wave3dTime + w.phi);
      }
    } else if (wave3dInteractionMode === 'max') {
      y = -Infinity;
      for (const w of enabled) {
        const val = w.A * Math.sin(w.kx * x + w.ky * z - w.omega * wave3dTime + w.phi);
        if (val > y) y = val;
      }
      if (!isFinite(y)) y = 0;
    }

    pos.setY(i, y);
  }
  pos.needsUpdate = true;
  geometry.computeVertexNormals();

  renderer.render(scene, camera);
  wave3dTime += 0.03;
  animationId = requestAnimationFrame(animate3DWaves);
}

// ============================================================
// TAB 5: EXTERNAL TOOLS — Everything else
// ============================================================
const EXTERNAL_TOOL_SECTIONS = [
  { section: 'Wave Visualizers', filter: r => r.tags.some(t => ['waves', 'graphing', 'visualization', 'fourier', 'interactive'].includes(t)) && r.category !== 'artist' && !isMechanismTool(r) },
  { section: '3D & CAD', filter: r => r.tags.some(t => ['3d', 'geometry', 'cad'].includes(t)) && !isMechanismTool(r) },
  { section: 'Creative Coding', filter: r => r.tags.some(t => ['p5js', 'creative-coding', 'animation', 'bezier'].includes(t)) },
  { section: 'Community & Forums', filter: r => r.category === 'community' },
  { section: 'Kinetic Artists', filter: r => r.category === 'artist' },
  { section: 'Video Channels', filter: r => r.category === 'video' && !isMechanismTool(r) },
  { section: 'Books & Plans', filter: r => r.category === 'book' || r.category === 'plans' },
];

function isMechanismTool(r) {
  return MECHANISM_TOOLS.some(section => section.tools.some(t => t.id === r.id));
}

function initExternalTools() {
  const canvas = document.getElementById('playground-canvas');
  const sliders = document.getElementById('slider-panel');
  if (!canvas) return;
  sliders.innerHTML = '';

  const allResources = getAllResources();
  const usedIds = new Set(); // Prevent duplicates across sections
  let html = '<div style="padding:16px;">';

  EXTERNAL_TOOL_SECTIONS.forEach(section => {
    const matching = allResources.filter(r => section.filter(r) && !usedIds.has(r.id));
    if (matching.length === 0) return;

    matching.forEach(r => usedIds.add(r.id));

    html += `<div class="section-title" style="margin-top:16px;margin-bottom:8px;">${section.section.toUpperCase()}</div>`;
    html += '<div class="tool-card-grid">';
    matching.forEach(r => {
      html += `
        <div class="tool-card">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;">
            <strong class="text-sm">${r.name}</strong>
            <a href="${r.url}" target="_blank" rel="noopener" class="primary" style="padding:3px 10px;font-size:10px;text-decoration:none;border:1px solid var(--accent);border-radius:4px;">Open</a>
          </div>
          <div class="text-sm text-dim">${r.description}</div>
        </div>
      `;
    });
    html += '</div>';
  });

  html += '</div>';
  canvas.innerHTML = html;
}

// ============================================================
// SAVE & BRIDGE
// ============================================================
async function saveToGallery() {
  const name = await promptInput('Pattern Name', 'e.g. Ocean Swell');
  if (!name) return;

  const pattern = {
    id: 'pat-' + Date.now().toString(36),
    name,
    type: currentTab,
    params: {},
    tags: [],
    savedAt: new Date().toISOString(),
    usedInProject: null
  };

  if (currentTab === 'wavelab') {
    pattern.params = { waves: JSON.parse(JSON.stringify(waveParams)) };
    pattern.tags = ['wave', 'superposition'];
  } else if (currentTab === 'patterns') {
    pattern.params = { preset: patternPreset, ...patternParams };
    pattern.tags = [patternPreset];
  } else if (currentTab === 'waves3d') {
    pattern.params = wave3dWaves
      ? { waves: JSON.parse(JSON.stringify(wave3dWaves)), interaction: wave3dInteractionMode || 'superposition' }
      : { ...wave3dParams };
    pattern.tags = ['3d', 'wave'];
  }

  // Generate a human-readable expression for display
  if (currentTab === 'wavelab') {
    pattern.expression = waveParams.filter(w => w.A > 0).map(w =>
      `${w.A.toFixed(1)}sin(${w.k.toFixed(1)}x)`
    ).join(' + ');
  } else if (currentTab === 'patterns') {
    pattern.expression = `${PATTERN_PRESETS[patternPreset]?.label || patternPreset}: ${JSON.stringify(patternParams)}`;
  }

  await savePattern(pattern);
  showToast(`Saved "${name}" to gallery`, 'success');
  updateSidebar();
}

async function bridgeToBuild() {
  const name = await promptInput('Project Name', 'e.g. Wave Sculpture v1');
  if (!name) return;

  // Capture source pattern data from current experiment
  let sourcePattern = { tab: currentTab, savedAt: new Date().toISOString() };

  if (currentTab === 'wavelab') {
    sourcePattern.type = 'wave2d';
    sourcePattern.waves = JSON.parse(JSON.stringify(waveParams));
    sourcePattern.expression = waveParams.filter(w => w.A > 0).map(w =>
      `${w.A.toFixed(1)}sin(${w.k.toFixed(1)}x)`
    ).join(' + ');
  } else if (currentTab === 'patterns') {
    sourcePattern.type = 'pattern';
    sourcePattern.preset = patternPreset;
    sourcePattern.params = { ...patternParams };
    sourcePattern.expression = `${patternPreset}: ${JSON.stringify(patternParams)}`;
  } else if (currentTab === 'waves3d') {
    sourcePattern.type = 'wave3d';
    sourcePattern.waves = JSON.parse(JSON.stringify(wave3dWaves || [wave3dParams]));
    sourcePattern.interaction = wave3dInteractionMode || 'superposition';
    sourcePattern.expression = (wave3dWaves || []).filter(w => w.enabled !== false).map(w =>
      `${(w.A || w.amplitude || 1).toFixed(1)}sin(${(w.kx || w.freqX || 1).toFixed(1)}x + ${(w.ky || w.freqY || 1).toFixed(1)}y)`
    ).join(' + ') || `wave3d: ${JSON.stringify(wave3dParams)}`;
  }

  const project = await createProject(name, sourcePattern);
  setMode('build');
  showToast(`Created "${name}" — open in Mechanize`, 'success');
}

// ============================================================
// SIDEBAR
// ============================================================
function updateSidebar() {
  const sections = [];

  sections.push({
    title: 'Actions',
    html: `
      <div class="flex-col gap">
        <button id="exp-save-gallery" class="primary" style="width:100%">Save to Gallery</button>
        <button id="exp-bridge-build" style="width:100%">Use in Build Mode</button>
      </div>
    `
  });

  // Tab-specific info
  const infoMap = {
    wavelab: `<p class="text-sm text-dim">
      <strong>Wave Superposition</strong><br>
      Combine multiple sine waves to create complex patterns. This is how Reuben Margolin's sculptures work — each string follows:<br>
      <code style="font-size:10px;">h(x,t) = &Sigma; A&middot;sin(kx + &phi; + &omega;t)</code><br><br>
      Try matching amplitudes for clean interference, or use different frequencies for organic movement.
    </p>`,
    patterns: `<p class="text-sm text-dim">
      <strong>Mathematical Curves</strong><br>
      Each pattern is a different application of parametric equations. Rose curves appear in cam profiles, Lissajous figures in coupled oscillators, spirographs in gear trains.
    </p>`,
    mechanisms: `<p class="text-sm text-dim">
      <strong>Mechanism Exploration</strong><br>
      These external tools let you design real mechanisms interactively. Start with MotionGen to draw a path and get a linkage, or use 507 Movements to browse 500+ animated mechanisms.
    </p>`,
    waves3d: `<p class="text-sm text-dim">
      <strong>3D Wave Surfaces</strong><br>
      Margolin creates these with physical string grids. Multiple wave sources create interference patterns — the same math that governs ocean waves, sound, and light.
    </p>`,
    tools: `<p class="text-sm text-dim">
      <strong>External Resources</strong><br>
      Curated collection of tools, communities, and references for kinetic sculpture design.
    </p>`
  };

  sections.push({
    title: 'About This',
    html: infoMap[currentTab] || ''
  });

  // Contextual guidance
  const guidanceMap = { wavelab: 'exp-wavelab', patterns: 'exp-patterns', waves3d: 'exp-waves3d', mechanisms: 'exp-mechanisms' };
  const guidanceCtx = guidanceMap[currentTab];
  if (guidanceCtx) {
    const guidance = createGuidancePanel(guidanceCtx);
    if (guidance) sections.push({ element: guidance });
  }

  // Per-tab external resources
  const tabCtx = TAB_RESOURCE_MAP[currentTab];
  const contexts = [];
  if (tabCtx) contexts.push(tabCtx);
  contexts.push('playground');
  const extHtml = renderMultiContextLinks(contexts, { maxItems: 4, compact: true });
  if (extHtml) {
    sections.push({ title: 'Related Links', html: extHtml });
  }

  sections.push({ element: createClaudePanel(null) });
  renderSidebar(sections);

  setTimeout(() => {
    document.getElementById('exp-save-gallery')?.addEventListener('click', saveToGallery);
    document.getElementById('exp-bridge-build')?.addEventListener('click', bridgeToBuild);
  }, 0);
}

export function unmount() {
  stopAnimation();
  if (threeScene?.renderer) {
    threeScene.renderer.dispose();
    threeScene = null;
  }
}
