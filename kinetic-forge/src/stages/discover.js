// Stage 1: DISCOVER — Math exploration
// Tools: JSXGraph for 2D plotting, built-in Fourier, equation input

import { loadLibraries } from '../components/tool-loader.js';
import { getProject, saveProject, loadPatterns, getPatterns } from '../state.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { showToast } from '../toast.js';
import { awardXP } from '../xp.js';
import { suggestTasks } from '../tasks.js';
import { navigate } from '../router.js';
import { createResourceSection } from '../components/resource-links.js';

let board = null;
let currentTab = 'jsxgraph';

export async function mount(container) {
  container.innerHTML = `
    <div class="tab-bar">
      <div class="tab active" data-tab="jsxgraph">JSXGraph</div>
      <div class="tab" data-tab="fourier">Fourier</div>
      <div class="tab" data-tab="parametric">Parametric</div>
    </div>
    <div id="discover-canvas" class="tool-canvas"></div>
    <div class="equation-bar">
      <label class="text-dim text-sm">y =</label>
      <input id="equation-input" type="text" placeholder="sin(x) * cos(0.5*x)" value="sin(x)">
      <button id="plot-btn" class="primary">Plot</button>
      <button id="save-eq-btn">Save Equation</button>
    </div>
    <div id="param-controls" class="flex gap mt"></div>
  `;

  // Tab switching
  container.querySelectorAll('.tab').forEach(tab => {
    tab.onclick = () => {
      container.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      currentTab = tab.dataset.tab;
      initTool();
    };
  });

  // Load JSXGraph
  await loadLibraries(['jsxgraph-css', 'jsxgraph']);
  initTool();

  // Plot button
  document.getElementById('plot-btn').onclick = () => plotEquation();

  // Save equation button
  document.getElementById('save-eq-btn').onclick = () => saveEquation();

  // Load patterns for gallery integration
  await loadPatterns().catch(() => {});

  // Render sidebar
  updateSidebar();
}

function initTool() {
  const canvas = document.getElementById('discover-canvas');
  canvas.innerHTML = '';

  if (currentTab === 'jsxgraph') {
    initJSXGraph(canvas);
  } else if (currentTab === 'fourier') {
    initFourier(canvas);
  } else if (currentTab === 'parametric') {
    initParametric(canvas);
  }
}

function initJSXGraph(canvas) {
  canvas.id = 'jsxbox';
  if (typeof JXG === 'undefined') {
    canvas.innerHTML = '<p class="text-dim" style="padding:20px">Loading JSXGraph...</p>';
    return;
  }

  board = JXG.JSXGraph.initBoard('jsxbox', {
    boundingbox: [-10, 6, 10, -6],
    axis: true,
    grid: true,
    showCopyright: false,
    showNavigation: false,
    pan: { enabled: true },
    zoom: { enabled: true }
  });

  // Plot default
  plotEquation();
}

function plotEquation() {
  if (!board || typeof JXG === 'undefined') return;

  // Clear previous plots (keep axes)
  const plotElements = board.objectsList.filter(o =>
    o.elType === 'curve' || o.elType === 'functiongraph'
  );
  plotElements.forEach(o => board.removeObject(o));

  const expr = document.getElementById('equation-input').value.trim();
  if (!expr) return;

  try {
    // Create function from expression
    const fn = new Function('x', `with(Math) { return ${expr}; }`);
    // Test it
    fn(0);

    board.create('functiongraph', [fn, -10, 10], {
      strokeColor: '#4fc3f7',
      strokeWidth: 2,
      highlight: false
    });
  } catch (e) {
    showToast(`Invalid equation: ${e.message}`, 'error');
  }
}

function initFourier(canvas) {
  canvas.innerHTML = `
    <div style="padding: 20px;">
      <canvas id="fourier-canvas" width="700" height="350" style="background: #111;"></canvas>
      <div class="mt flex gap">
        <label class="text-dim text-sm">Harmonics:</label>
        <input id="harmonics-count" type="range" min="1" max="20" value="5">
        <span id="harmonics-label" class="text-sm">5</span>
      </div>
    </div>
  `;

  const cvs = document.getElementById('fourier-canvas');
  const ctx = cvs.getContext('2d');
  const slider = document.getElementById('harmonics-count');
  const label = document.getElementById('harmonics-label');

  function drawFourier() {
    const N = parseInt(slider.value);
    label.textContent = N;
    ctx.clearRect(0, 0, cvs.width, cvs.height);

    // Draw square wave approximation via Fourier series
    ctx.strokeStyle = '#4fc3f7';
    ctx.lineWidth = 2;
    ctx.beginPath();

    for (let px = 0; px < cvs.width; px++) {
      const x = (px / cvs.width) * 4 * Math.PI - 2 * Math.PI;
      let y = 0;
      for (let n = 1; n <= N; n++) {
        const k = 2 * n - 1; // Odd harmonics only
        y += (4 / Math.PI) * Math.sin(k * x) / k;
      }
      const cy = cvs.height / 2 - y * (cvs.height / 4);
      if (px === 0) ctx.moveTo(px, cy);
      else ctx.lineTo(px, cy);
    }
    ctx.stroke();

    // Draw target square wave
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    for (let px = 0; px < cvs.width; px++) {
      const x = (px / cvs.width) * 4 * Math.PI - 2 * Math.PI;
      const y = Math.sign(Math.sin(x));
      const cy = cvs.height / 2 - y * (cvs.height / 4);
      if (px === 0) ctx.moveTo(px, cy);
      else ctx.lineTo(px, cy);
    }
    ctx.stroke();
    ctx.setLineDash([]);

    // Axis
    ctx.strokeStyle = '#444';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, cvs.height / 2);
    ctx.lineTo(cvs.width, cvs.height / 2);
    ctx.stroke();
  }

  slider.oninput = drawFourier;
  drawFourier();
}

function initParametric(canvas) {
  canvas.innerHTML = `
    <div style="padding: 20px;">
      <canvas id="param-canvas" width="400" height="400" style="background: #111;"></canvas>
      <div class="mt flex gap flex-col">
        <div class="flex gap">
          <label class="text-dim text-sm" style="width:60px">x(t) =</label>
          <input id="param-x" type="text" value="sin(3*t)" style="flex:1">
        </div>
        <div class="flex gap">
          <label class="text-dim text-sm" style="width:60px">y(t) =</label>
          <input id="param-y" type="text" value="sin(2*t)" style="flex:1">
        </div>
        <button id="param-plot-btn" class="primary">Plot Parametric</button>
      </div>
    </div>
  `;

  document.getElementById('param-plot-btn').onclick = () => {
    const cvs = document.getElementById('param-canvas');
    const ctx = cvs.getContext('2d');
    const xExpr = document.getElementById('param-x').value;
    const yExpr = document.getElementById('param-y').value;

    try {
      const xFn = new Function('t', `with(Math) { return ${xExpr}; }`);
      const yFn = new Function('t', `with(Math) { return ${yExpr}; }`);

      ctx.clearRect(0, 0, cvs.width, cvs.height);

      // Axes
      ctx.strokeStyle = '#333';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(cvs.width / 2, 0);
      ctx.lineTo(cvs.width / 2, cvs.height);
      ctx.moveTo(0, cvs.height / 2);
      ctx.lineTo(cvs.width, cvs.height / 2);
      ctx.stroke();

      // Curve
      ctx.strokeStyle = '#4fc3f7';
      ctx.lineWidth = 2;
      ctx.beginPath();
      const steps = 1000;
      for (let i = 0; i <= steps; i++) {
        const t = (i / steps) * 2 * Math.PI;
        const x = xFn(t);
        const y = yFn(t);
        const px = cvs.width / 2 + x * (cvs.width / 2.5);
        const py = cvs.height / 2 - y * (cvs.height / 2.5);
        if (i === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.stroke();
    } catch (e) {
      showToast(`Invalid parametric: ${e.message}`, 'error');
    }
  };

  // Auto-plot on load
  document.getElementById('param-plot-btn').click();
}

function saveEquation() {
  const project = getProject();
  const expr = document.getElementById('equation-input').value.trim();
  if (!expr) {
    showToast('Enter an equation first', 'warning');
    return;
  }

  if (project) {
    // Build Mode — save to project
    const eq = {
      id: 'eq-' + Date.now().toString(36),
      expression: expr,
      tool: currentTab,
      savedAt: new Date().toISOString()
    };
    project.stages.discover.savedEquations.push(eq);
    saveProject(project);
    showToast('Equation saved to project', 'success');
  } else {
    showToast('Equation noted (create a project to persist)', 'info');
  }

  updateSidebar();
}

function updateSidebar() {
  const project = getProject();
  const sections = [];

  // Saved equations
  const eqs = project?.stages?.discover?.savedEquations || [];
  if (eqs.length > 0) {
    sections.push({
      title: 'Saved Equations',
      cards: eqs.map(eq => ({
        title: eq.expression,
        description: `${eq.tool} | ${new Date(eq.savedAt).toLocaleDateString()}`
      }))
    });
  }

  // Suggestions
  const suggestions = suggestTasks('build', 'discover', 3);
  if (suggestions.length > 0) {
    sections.push({
      title: 'Suggested Exercises',
      cards: suggestions.map(s => ({
        title: s.title,
        description: s.description,
        xp: s.xp,
        onClick: () => {
          document.getElementById('equation-input').value = s.params?.A
            ? `${s.params.A}*sin(${s.params.k || 1}*x)`
            : 'sin(x)';
          plotEquation();
        }
      }))
    });
  }

  // Load from Gallery
  const patterns = getPatterns() || [];
  if (patterns.length > 0) {
    sections.push({
      title: 'From Gallery',
      cards: patterns.slice(0, 5).map(p => ({
        title: p.name,
        description: p.expression || p.type,
        onClick: () => {
          const input = document.getElementById('equation-input');
          if (input && p.expression) {
            input.value = p.expression;
            plotEquation();
            showToast(`Loaded: ${p.name}`, 'info');
          }
        }
      }))
    });
  }

  // Gate status
  if (project) {
    const gateStatus = eqs.length >= 1 ? 'pass' : 'pending';
    sections.push({
      title: 'Gate: Discover',
      items: [
        { label: `Save equation (${eqs.length}/1)`, status: gateStatus }
      ]
    });
  }

  // External tools
  const resourceSection = createResourceSection('External Tools', 'discover', { maxItems: 4, compact: true });
  if (resourceSection) sections.push(resourceSection);

  // Claude panel
  sections.push({ element: createClaudePanel('discover') });

  renderSidebar(sections);
}

export function unmount() {
  if (board && typeof JXG !== 'undefined') {
    JXG.JSXGraph.freeBoard(board);
    board = null;
  }
}
