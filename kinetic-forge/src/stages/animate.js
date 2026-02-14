// Stage 2: ANIMATE — See it move
// Tools: p5.js for creative coding, Canvas 2D for simple animations

import { loadLibraries } from '../components/tool-loader.js';
import { getProject, saveProject } from '../state.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { showToast } from '../toast.js';
import { suggestTasks } from '../tasks.js';
import { createResourceSection } from '../components/resource-links.js';
import { openInP5Editor, showSketchPicker, createP5Button } from '../components/p5-bridge.js';
import { getSketchesForContext, getSketchById } from '../p5-sketches.js';

let p5Instance = null;
let animationFrame = null;

export async function mount(container) {
  container.innerHTML = `
    <div class="tab-bar">
      <div class="tab active" data-tab="wave">Wave Animation</div>
      <div class="tab" data-tab="lissajous">Lissajous</div>
      <div class="tab" data-tab="custom">Custom p5.js</div>
    </div>
    <div id="animate-canvas" class="tool-canvas"></div>
    <div id="animate-controls" class="mt flex gap">
      <div class="flex-col gap">
        <label class="text-dim text-sm">Speed</label>
        <input id="anim-speed" type="range" min="0.1" max="5" step="0.1" value="1">
      </div>
      <div class="flex-col gap">
        <label class="text-dim text-sm">Amplitude</label>
        <input id="anim-amp" type="range" min="10" max="100" step="5" value="50">
      </div>
      <div class="flex-col gap">
        <label class="text-dim text-sm">Frequency</label>
        <input id="anim-freq" type="range" min="0.5" max="5" step="0.1" value="2">
      </div>
      <div class="flex-col gap">
        <label class="text-dim text-sm">Layers</label>
        <input id="anim-layers" type="range" min="1" max="5" step="1" value="3">
      </div>
      <button id="save-anim" style="align-self:flex-end;">Save Animation</button>
    </div>
  `;

  const canvas = document.getElementById('animate-canvas');
  const cvs = document.createElement('canvas');
  cvs.id = 'anim-cvs';
  cvs.width = canvas.clientWidth || 700;
  cvs.height = 380;
  cvs.style.background = '#111';
  canvas.appendChild(cvs);

  startWaveAnimation();

  container.querySelectorAll('.tab').forEach(tab => {
    tab.onclick = () => {
      container.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      cancelAnimationFrame(animationFrame);
      const tabName = tab.dataset.tab;
      if (tabName === 'wave') startWaveAnimation();
      else if (tabName === 'lissajous') startLissajousAnimation();
      else if (tabName === 'custom') showCustomEditor();
    };
  });

  document.getElementById('save-anim').onclick = saveAnimation;
  updateSidebar();
}

function startWaveAnimation() {
  const cvs = document.getElementById('anim-cvs');
  if (!cvs) return;
  const ctx = cvs.getContext('2d');
  let t = 0;

  function frame() {
    const speed = parseFloat(document.getElementById('anim-speed')?.value || 1);
    const amp = parseFloat(document.getElementById('anim-amp')?.value || 50);
    const freq = parseFloat(document.getElementById('anim-freq')?.value || 2);
    const layers = parseInt(document.getElementById('anim-layers')?.value || 3);

    t += 0.016 * speed;
    ctx.clearRect(0, 0, cvs.width, cvs.height);

    const colors = ['#4fc3f7', '#66bb6a', '#ffa726', '#ef5350', '#ab47bc'];

    for (let l = 0; l < layers; l++) {
      const phaseOffset = l * (Math.PI * 2 / layers);
      const layerAmp = amp * (1 - l * 0.15);
      ctx.strokeStyle = colors[l % colors.length];
      ctx.lineWidth = 2;
      ctx.globalAlpha = 1 - l * 0.15;
      ctx.beginPath();

      for (let x = 0; x < cvs.width; x++) {
        const xNorm = (x / cvs.width) * Math.PI * 4;
        const y = cvs.height / 2 + layerAmp * Math.sin(freq * xNorm - t * 2 + phaseOffset);
        if (x === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }
    ctx.globalAlpha = 1;

    animationFrame = requestAnimationFrame(frame);
  }

  frame();
}

function startLissajousAnimation() {
  const cvs = document.getElementById('anim-cvs');
  if (!cvs) return;
  const ctx = cvs.getContext('2d');
  let t = 0;
  const trail = [];

  function frame() {
    const speed = parseFloat(document.getElementById('anim-speed')?.value || 1);
    const amp = parseFloat(document.getElementById('anim-amp')?.value || 50);
    const freq = parseFloat(document.getElementById('anim-freq')?.value || 2);

    t += 0.01 * speed;
    const x = cvs.width / 2 + amp * 2 * Math.sin(3 * t);
    const y = cvs.height / 2 + amp * 2 * Math.sin(freq * t + Math.PI / 4);
    trail.push({ x, y });
    if (trail.length > 500) trail.shift();

    ctx.clearRect(0, 0, cvs.width, cvs.height);

    // Trail
    ctx.strokeStyle = '#4fc3f7';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    trail.forEach((p, i) => {
      ctx.globalAlpha = i / trail.length;
      if (i === 0) ctx.moveTo(p.x, p.y);
      else ctx.lineTo(p.x, p.y);
    });
    ctx.stroke();
    ctx.globalAlpha = 1;

    // Current point
    ctx.fillStyle = '#fff';
    ctx.beginPath();
    ctx.arc(x, y, 4, 0, Math.PI * 2);
    ctx.fill();

    animationFrame = requestAnimationFrame(frame);
  }

  frame();
}

function showCustomEditor() {
  const canvas = document.getElementById('animate-canvas');
  const templates = getSketchesForContext('animate');
  canvas.innerHTML = `
    <div style="padding: 16px;">
      <div style="display:flex;gap:8px;align-items:center;margin-bottom:10px;">
        <select id="sketch-template" style="flex:1;background:var(--bg);color:var(--text);border:1px solid var(--border);padding:6px 8px;border-radius:var(--radius);font-size:12px;">
          <option value="">-- Load a template --</option>
          ${templates.map(s => `<option value="${s.id}">${s.title}</option>`).join('')}
        </select>
        <button id="browse-templates" style="font-size:11px;padding:6px 10px;">Browse All</button>
      </div>
      <textarea id="custom-sketch" rows="12" style="width: 100%; font-family: var(--mono); font-size: 12px;">// p5.js sketch (instance mode)
// Available: p.sin, p.cos, p.map, p.frameCount, etc.

sketch.setup = function() {
  p.createCanvas(680, 350);
};

sketch.draw = function() {
  p.background(17);
  p.stroke(79, 195, 247);
  p.noFill();
  p.beginShape();
  for (let x = 0; x < p.width; x += 2) {
    let y = p.height/2 + 50 * p.sin(x * 0.02 + p.frameCount * 0.03);
    p.vertex(x, y);
  }
  p.endShape();
};</textarea>
      <div style="display:flex;gap:8px;margin-top:10px;">
        <button id="run-sketch" class="primary">Run Sketch</button>
        ${createP5Button('Copy to Web Editor')}
      </div>
      <div id="p5-container" class="mt"></div>
    </div>
  `;

  document.getElementById('run-sketch').onclick = async () => {
    await loadLibraries(['p5']);
    const code = document.getElementById('custom-sketch').value;
    const p5Container = document.getElementById('p5-container');
    p5Container.innerHTML = '';

    if (p5Instance) { p5Instance.remove(); p5Instance = null; }

    try {
      p5Instance = new p5((p) => {
        const sketch = {};
        const fn = new Function('p', 'sketch', code);
        fn(p, sketch);
        p.setup = sketch.setup || (() => p.createCanvas(680, 350));
        p.draw = sketch.draw || (() => {});
      }, p5Container);
    } catch (e) {
      showToast(`Sketch error: ${e.message}`, 'error');
    }
  };

  // Template dropdown
  document.getElementById('sketch-template').onchange = (e) => {
    if (!e.target.value) return;
    const sketch = getSketchById(e.target.value);
    if (sketch) {
      const ta = document.getElementById('custom-sketch');
      if (ta) ta.value = sketch.code;
      showToast(`Loaded: ${sketch.title}`, 'success');
    }
  };

  // Browse all templates
  document.getElementById('browse-templates').onclick = () => showSketchPicker('animate');

  // Copy to Web Editor button
  const p5Btn = document.querySelector('.p5-editor-btn');
  if (p5Btn) p5Btn.onclick = () => {
    const code = document.getElementById('custom-sketch')?.value || '';
    openInP5Editor(code, 'Custom p5.js Sketch');
  };
}

function saveAnimation() {
  const project = getProject();
  if (!project) {
    showToast('Create a project first', 'warning');
    return;
  }

  const anim = {
    id: 'anim-' + Date.now().toString(36),
    type: 'wave',
    params: {
      speed: parseFloat(document.getElementById('anim-speed')?.value || 1),
      amplitude: parseFloat(document.getElementById('anim-amp')?.value || 50),
      frequency: parseFloat(document.getElementById('anim-freq')?.value || 2),
      layers: parseInt(document.getElementById('anim-layers')?.value || 3)
    },
    savedAt: new Date().toISOString()
  };

  project.stages.animate.savedAnimations.push(anim);
  project.stages.animate.status = 'in_progress';
  saveProject(project);
  showToast('Animation saved', 'success');
  updateSidebar();
}

function updateSidebar() {
  const project = getProject();
  const sections = [];

  const anims = project?.stages?.animate?.savedAnimations || [];
  if (anims.length > 0) {
    sections.push({
      title: 'Saved Animations',
      cards: anims.map(a => ({
        title: `${a.type} | A=${a.params.amplitude} f=${a.params.frequency}`,
        description: `${a.params.layers} layers, speed ${a.params.speed}x`
      }))
    });
  }

  const suggestions = suggestTasks('build', 'animate', 3);
  if (suggestions.length > 0) {
    sections.push({
      title: 'Exercises',
      cards: suggestions.map(s => ({ title: s.title, description: s.description, xp: s.xp }))
    });
  }

  // External resources
  const resourceSection = createResourceSection('Resources', 'animate', { maxItems: 3, compact: true });
  if (resourceSection) sections.push(resourceSection);

  sections.push({ element: createClaudePanel('animate') });
  renderSidebar(sections);
}

export function unmount() {
  if (animationFrame) cancelAnimationFrame(animationFrame);
  if (p5Instance) { p5Instance.remove(); p5Instance = null; }
}
