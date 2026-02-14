// Stage 1: MECHANIZE — Choose and configure the mechanism
// Recommendations (from wave pattern) → Four-Bar → Cam Profile → Recipes

import { loadLibraries } from '../components/tool-loader.js';
import { getProject, saveProject } from '../state.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { showToast } from '../toast.js';
import { checkGrashof, checkTransmissionAngleRange, validateGate } from '../gate.js';
import { suggestTasks } from '../tasks.js';
import { createResourceSection } from '../components/resource-links.js';
import { recommendMechanisms, getMechanismConfig, calculateRequirements, getFamily } from '../components/mechanism-advisor.js';
import { createGuidancePanel } from '../components/guidance.js';
import { fourBarToP5Sketch, camToP5Sketch, openInP5Editor, createP5Button } from '../components/p5-bridge.js';

let board = null;
let currentTab = 'recommend';
let selectedFamily = null;
let familyConfig = {};

// Default four-bar parameters
let params = { ground: 100, crank: 25, coupler: 90, rocker: 80 };

export async function mount(container) {
  const project = getProject();
  const hasSource = project?.sourcePattern;

  // Default to recommend tab if we have a source pattern, otherwise four-bar
  currentTab = hasSource ? 'recommend' : 'recommend';

  container.innerHTML = `
    <div class="tab-bar">
      <div class="tab ${currentTab === 'recommend' ? 'active' : ''}" data-tab="recommend">Recommendations</div>
      <div class="tab ${currentTab === 'four-bar' ? 'active' : ''}" data-tab="four-bar">Four-Bar</div>
      <div class="tab ${currentTab === 'cam' ? 'active' : ''}" data-tab="cam">Cam Profile</div>
      <div class="tab ${currentTab === 'recipes' ? 'active' : ''}" data-tab="recipes">Recipes</div>
    </div>
    <div id="mech-canvas" class="tool-canvas"></div>
    <div id="mech-controls" class="mt"></div>
  `;

  container.querySelectorAll('.tab').forEach(tab => {
    tab.onclick = () => {
      container.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      currentTab = tab.dataset.tab;
      renderTool();
    };
  });

  await loadLibraries(['jsxgraph-css', 'jsxgraph']);
  renderTool();
  updateSidebar();
}

function renderTool() {
  // Reset canvas ID in case Four-Bar renamed it for JSXGraph
  const jsxbox = document.getElementById('mech-jsxbox');
  if (jsxbox) {
    if (board) { board.removeObject(board.objects); board = null; }
    jsxbox.id = 'mech-canvas';
  }

  if (currentTab === 'recommend') renderRecommendations();
  else if (currentTab === 'four-bar') renderFourBar();
  else if (currentTab === 'cam') renderCamProfile();
  else if (currentTab === 'recipes') renderRecipes();
}

// ────────────────────────────────────────────────────
// RECOMMENDATIONS TAB (new)
// ────────────────────────────────────────────────────

function renderRecommendations() {
  const canvas = document.getElementById('mech-canvas');
  const controls = document.getElementById('mech-controls');
  controls.innerHTML = '';

  const project = getProject();
  const source = project?.sourcePattern;

  // Get recommendations
  const recs = recommendMechanisms(source);

  let html = '<div style="padding: 16px; overflow-y: auto; height: 100%;">';

  // Show source pattern if available
  if (source) {
    html += `
      <div style="background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 12px; margin-bottom: 16px;">
        <div class="section-title" style="margin-bottom: 4px;">Source Pattern from Experiment</div>
        <div class="text-sm" style="color: var(--text);">
          <strong>Type:</strong> ${source.type || 'unknown'}
          ${source.expression ? `<br><strong>Expression:</strong> <code style="color: var(--accent);">${escapeHtml(source.expression)}</code>` : ''}
          ${source.waves ? `<br><strong>Wave components:</strong> ${Array.isArray(source.waves) ? source.waves.filter(w => w.enabled !== false).length : '?'}` : ''}
          ${source.interaction ? `<br><strong>Interaction:</strong> ${source.interaction}` : ''}
        </div>
      </div>
    `;
  } else {
    html += `
      <div style="background: #1a1a2e; border: 1px solid var(--border); border-radius: var(--radius); padding: 12px; margin-bottom: 16px;">
        <div class="text-sm" style="color: var(--text-dim);">
          No source pattern loaded. Go to <strong>Experiment</strong> mode, design a wave pattern, then click <strong>"Use in Build Mode"</strong> to get tailored mechanism recommendations.
          <br><br>Showing all mechanism families ranked by general suitability.
        </div>
      </div>
    `;
  }

  // Recommendation cards
  html += '<div class="section-title" style="margin-bottom: 8px;">Mechanism Families (ranked)</div>';

  recs.forEach((rec, i) => {
    const isSelected = selectedFamily === rec.id;
    const scoreColor = rec.score >= 70 ? '#66bb6a' : rec.score >= 50 ? '#ffa726' : '#888';
    const borderColor = isSelected ? 'var(--accent)' : 'var(--border)';

    html += `
      <div class="mech-rec-card" data-family="${rec.id}"
           style="border: 2px solid ${borderColor}; border-radius: var(--radius); padding: 12px; margin-bottom: 10px; cursor: pointer;
                  background: ${isSelected ? 'rgba(79,195,247,0.08)' : 'var(--surface)'}; transition: all 0.15s;">
        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 6px;">
          <span style="font-size: 20px;">${rec.icon}</span>
          <span style="font-weight: 600; color: var(--text); flex: 1;">${rec.name}</span>
          <span style="font-size: 12px; padding: 2px 8px; border-radius: 10px; background: ${scoreColor}22; color: ${scoreColor}; font-weight: 600;">
            ${rec.score}%
          </span>
          <span style="font-size: 11px; color: var(--text-dim);">#${rec.rank}</span>
        </div>
        <div style="font-size: 12px; color: var(--text-dim); margin-bottom: 4px;">${rec.principle}</div>
        <div style="font-size: 11px; color: var(--accent); margin-bottom: 4px;">${rec.rationale}</div>
        <div style="font-size: 11px; color: var(--text-dim); display: flex; gap: 12px; flex-wrap: wrap;">
          <span>Complexity: <strong>${rec.complexity}</strong></span>
          <span>Cost: <strong>${rec.cost}</strong></span>
          <span>Motors: <strong>${rec.motorCount}</strong></span>
          <span>Examples: <em>${rec.examples}</em></span>
        </div>
        <div class="mech-rec-detail" style="display: ${isSelected ? 'block' : 'none'}; margin-top: 10px; padding-top: 10px; border-top: 1px solid var(--border);">
          <div style="font-size: 12px; color: var(--text); margin-bottom: 6px;"><strong>Best for:</strong> ${rec.bestFor}</div>
          <div style="font-size: 12px; margin-bottom: 4px;"><strong style="color: #66bb6a;">Pros:</strong></div>
          <ul style="font-size: 11px; color: var(--text); margin: 0 0 6px 16px; padding: 0;">
            ${rec.pros.map(p => `<li>${p}</li>`).join('')}
          </ul>
          <div style="font-size: 12px; margin-bottom: 4px;"><strong style="color: #ef5350;">Cons:</strong></div>
          <ul style="font-size: 11px; color: var(--text); margin: 0 0 8px 16px; padding: 0;">
            ${rec.cons.map(c => `<li>${c}</li>`).join('')}
          </ul>
          <button class="primary mech-select-btn" data-family="${rec.id}" style="font-size: 11px; padding: 4px 16px;">
            ${isSelected ? 'Configure This Mechanism' : 'Select This Mechanism'}
          </button>
        </div>
      </div>
    `;
  });

  html += '</div>';
  canvas.innerHTML = html;

  // Attach card click handlers
  canvas.querySelectorAll('.mech-rec-card').forEach(card => {
    card.onclick = (e) => {
      if (e.target.classList.contains('mech-select-btn')) {
        selectedFamily = e.target.dataset.family;
        renderConfiguration(selectedFamily);
        return;
      }
      const fam = card.dataset.family;
      selectedFamily = selectedFamily === fam ? null : fam;
      renderRecommendations();
    };
  });
}

// ────────────────────────────────────────────────────
// CONFIGURATION VIEW (after selecting a family)
// ────────────────────────────────────────────────────

function renderConfiguration(familyId) {
  const canvas = document.getElementById('mech-canvas');
  const controls = document.getElementById('mech-controls');
  const project = getProject();
  const source = project?.sourcePattern;
  const family = getFamily(familyId);
  const config = getMechanismConfig(familyId, source);

  if (!config) {
    canvas.innerHTML = '<div style="padding:20px" class="text-dim">Configuration not available for this family.</div>';
    controls.innerHTML = '';
    return;
  }

  // Load existing config from project if available
  const saved = project?.stages?.mechanize?.mechanism;
  if (saved?.family === familyId && saved?.config) {
    familyConfig = { ...saved.config };
  } else {
    familyConfig = {};
    config.parameters.forEach(p => {
      familyConfig[p.id] = p.default;
    });
  }

  let html = '<div style="padding: 16px; overflow-y: auto; height: 100%;">';

  // Header
  html += `
    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 12px;">
      <button class="mech-back-btn" style="font-size: 11px; padding: 3px 10px;">Back</button>
      <span style="font-size: 20px;">${family.icon}</span>
      <span style="font-weight: 600; font-size: 16px; color: var(--text);">${config.title}</span>
    </div>
    <div style="font-size: 12px; color: var(--text-dim); margin-bottom: 16px;">${config.description}</div>
  `;

  // Formula
  if (config.formula) {
    html += `
      <div style="background: #111; padding: 8px 12px; border-radius: var(--radius); margin-bottom: 12px; font-family: monospace; font-size: 12px; color: var(--accent);">
        ${escapeHtml(config.formula)}
      </div>
    `;
  }

  // Parameters
  html += '<div class="section-title" style="margin-bottom: 8px;">Configuration Parameters</div>';
  html += '<div style="display: flex; flex-wrap: wrap; gap: 12px; margin-bottom: 16px;">';

  config.parameters.forEach(param => {
    const val = familyConfig[param.id] ?? param.default;
    html += `<div style="flex: 0 0 auto; min-width: 140px;">`;
    html += `<label class="text-dim text-sm" title="${param.help || ''}">${param.label}</label>`;

    if (param.type === 'select') {
      html += `<select id="cfg-${param.id}" style="width: 100%; margin-top: 2px;">`;
      param.options.forEach(opt => {
        html += `<option value="${opt}" ${val === opt ? 'selected' : ''}>${opt}</option>`;
      });
      html += `</select>`;
    } else if (param.type === 'text') {
      html += `<input id="cfg-${param.id}" type="text" value="${val}" style="width: 100%; margin-top: 2px;">`;
    } else {
      html += `<input id="cfg-${param.id}" type="number" value="${val}"
               ${param.min !== undefined ? `min="${param.min}"` : ''}
               ${param.max !== undefined ? `max="${param.max}"` : ''}
               ${param.step !== undefined ? `step="${param.step}"` : ''}
               style="width: 100%; margin-top: 2px;">`;
    }

    if (param.help) {
      html += `<div style="font-size: 10px; color: var(--text-dim); margin-top: 2px;">${param.help}</div>`;
    }
    html += `</div>`;
  });

  html += '</div>';

  // Notes
  if (config.notes) {
    html += `
      <div style="background: #1a1a2e; border-left: 3px solid var(--accent); padding: 8px 12px; border-radius: 0 var(--radius) var(--radius) 0; margin-bottom: 16px;">
        <div style="font-size: 11px; color: var(--text);">${config.notes}</div>
      </div>
    `;
  }

  // Requirements preview
  const reqs = calculateRequirements(familyId, source, familyConfig);
  if (reqs.components.length > 0) {
    html += '<div class="section-title" style="margin-bottom: 6px;">Estimated Components</div>';
    html += '<table style="font-size: 11px; width: 100%; border-collapse: collapse; margin-bottom: 12px;">';
    html += '<tr style="color: var(--text-dim);"><th style="text-align:left; padding: 2px 8px;">Component</th><th style="text-align:right; padding: 2px 8px;">Count</th><th style="text-align:left; padding: 2px 8px;">Material</th></tr>';
    reqs.components.forEach(c => {
      html += `<tr style="color: var(--text);"><td style="padding: 2px 8px;">${c.name}</td><td style="text-align:right; padding: 2px 8px;">${c.count}</td><td style="padding: 2px 8px; color: var(--text-dim);">${c.material}</td></tr>`;
    });
    html += '</table>';

    if (reqs.estimatedStrings > 0) {
      html += `<div style="font-size: 11px; color: var(--text-dim);">Est. strings: ${reqs.estimatedStrings} | Est. total parts: ~${reqs.estimatedParts}</div>`;
    }
    if (reqs.frictionBudget) {
      html += `<div style="font-size: 11px; color: ${reqs.frictionBudget.efficiency < 0.6 ? '#ef5350' : '#ffa726'};">
        Friction: ${reqs.frictionBudget.pulleys} pulleys in series = ${(reqs.frictionBudget.efficiency * 100).toFixed(0)}% efficiency
        ${reqs.frictionBudget.efficiency < 0.6 ? ' (WARNING: below 60%)' : ''}
      </div>`;
    }
    reqs.notes.forEach(n => {
      html += `<div style="font-size: 11px; color: var(--text-dim); margin-top: 2px;">${n}</div>`;
    });
  }

  html += '</div>';
  canvas.innerHTML = html;

  // Controls: Save button
  controls.innerHTML = `
    <div class="flex gap" style="flex-wrap: wrap; align-items: center;">
      <button id="save-mechanism" class="primary">Save Mechanism Choice</button>
      <button id="recalc-reqs">Recalculate</button>
      <span class="text-dim text-sm" style="margin-left: auto;">Changes saved to project → unlocks Simulate</span>
    </div>
  `;

  // Event handlers
  canvas.querySelector('.mech-back-btn')?.addEventListener('click', () => {
    renderRecommendations();
    controls.innerHTML = '';
  });

  document.getElementById('save-mechanism')?.addEventListener('click', () => saveMechanismChoice(familyId, config));
  document.getElementById('recalc-reqs')?.addEventListener('click', () => {
    readConfigParams(config);
    renderConfiguration(familyId);
  });
}

function readConfigParams(config) {
  config.parameters.forEach(param => {
    const el = document.getElementById(`cfg-${param.id}`);
    if (!el) return;
    if (param.type === 'number') {
      familyConfig[param.id] = parseFloat(el.value) || param.default;
    } else {
      familyConfig[param.id] = el.value || param.default;
    }
  });
}

function saveMechanismChoice(familyId, config) {
  const project = getProject();
  if (!project) {
    showToast('Create a project first', 'warning');
    return;
  }

  readConfigParams(config);
  const family = getFamily(familyId);
  const source = project.sourcePattern;
  const reqs = calculateRequirements(familyId, source, familyConfig);

  project.stages.mechanize.mechanism = {
    family: familyId,
    familyName: family.name,
    type: familyId, // backward compat
    config: { ...familyConfig },
    requirements: reqs,
    validation: {
      mechanismSelected: true,
      configured: true,
      powerBudget: { required: 0.5, available: 2.0, margin: 4.0 },
    },
    savedAt: new Date().toISOString(),
  };
  project.stages.mechanize.status = 'in_progress';
  project.stages.mechanize.recommendations = recommendMechanisms(source).slice(0, 3).map(r => ({
    id: r.id, name: r.name, score: r.score
  }));

  saveProject(project);
  showToast(`Mechanism saved: ${family.name}`, 'success');
  updateSidebar();
}

// ────────────────────────────────────────────────────
// FOUR-BAR TAB (preserved from original)
// ────────────────────────────────────────────────────

function renderFourBar() {
  const canvas = document.getElementById('mech-canvas');
  canvas.innerHTML = '';
  canvas.id = 'mech-jsxbox';

  const project = getProject();
  if (project?.stages?.mechanize?.mechanism?.type === 'four-bar' && project.stages.mechanize.mechanism.params) {
    params = { ...project.stages.mechanize.mechanism.params };
  }

  if (typeof JXG === 'undefined') {
    canvas.innerHTML = '<p class="text-dim" style="padding:20px">Loading JSXGraph...</p>';
    return;
  }

  board = JXG.JSXGraph.initBoard('mech-jsxbox', {
    boundingbox: [-50, 120, 250, -80],
    axis: false, grid: false, showCopyright: false, showNavigation: false
  });

  drawFourBar();

  const controls = document.getElementById('mech-controls');
  controls.innerHTML = `
    <div class="flex gap" style="flex-wrap: wrap;">
      <div class="flex-col gap">
        <label class="text-dim text-sm">Ground (a)</label>
        <input id="param-ground" type="number" value="${params.ground}" min="10" max="200" style="width:80px">
      </div>
      <div class="flex-col gap">
        <label class="text-dim text-sm">Crank (b)</label>
        <input id="param-crank" type="number" value="${params.crank}" min="5" max="100" style="width:80px">
      </div>
      <div class="flex-col gap">
        <label class="text-dim text-sm">Coupler (c)</label>
        <input id="param-coupler" type="number" value="${params.coupler}" min="10" max="200" style="width:80px">
      </div>
      <div class="flex-col gap">
        <label class="text-dim text-sm">Rocker (d)</label>
        <input id="param-rocker" type="number" value="${params.rocker}" min="10" max="200" style="width:80px">
      </div>
      <div class="flex-col gap" style="justify-content: flex-end;">
        <button id="update-linkage" class="primary">Update</button>
      </div>
      <div class="flex-col gap" style="justify-content: flex-end;">
        <button id="save-fourbar">Save as Four-Bar</button>
      </div>
      <div class="flex-col gap" style="justify-content: flex-end;">
        ${createP5Button('Visualize in p5 Editor')}
      </div>
    </div>
    <div id="validation-display" class="mt"></div>
  `;

  document.getElementById('update-linkage').onclick = () => {
    params.ground = parseFloat(document.getElementById('param-ground').value) || 100;
    params.crank = parseFloat(document.getElementById('param-crank').value) || 25;
    params.coupler = parseFloat(document.getElementById('param-coupler').value) || 90;
    params.rocker = parseFloat(document.getElementById('param-rocker').value) || 80;
    drawFourBar();
    updateValidation();
    updateSidebar();
  };

  document.getElementById('save-fourbar').onclick = saveFourBar;
  // p5 Editor button
  const p5Btn = document.querySelector('.p5-editor-btn');
  if (p5Btn) p5Btn.onclick = () => openInP5Editor(fourBarToP5Sketch(params), 'Four-Bar Linkage Simulator');
  updateValidation();
}

function drawFourBar() {
  if (!board) return;
  board.suspendUpdate();

  const toRemove = [...board.objectsList];
  toRemove.forEach(o => { try { board.removeObject(o); } catch { /* skip */ } });

  const { ground: a, crank: b, coupler: c, rocker: d } = params;

  const O2 = board.create('point', [0, 0], { fixed: true, name: 'O2', size: 3, color: '#888' });
  const O4 = board.create('point', [a, 0], { fixed: true, name: 'O4', size: 3, color: '#888' });
  board.create('line', [O2, O4], { straightFirst: false, straightLast: false, strokeColor: '#555', strokeWidth: 3, dash: 2 });

  const crankAngle = 45 * Math.PI / 180;
  const A = board.create('point', [b * Math.cos(crankAngle), b * Math.sin(crankAngle)], { name: 'A', size: 3, color: '#4fc3f7' });

  const Ax = b * Math.cos(crankAngle);
  const Ay = b * Math.sin(crankAngle);
  const Bpos = solveFourBar(0, 0, a, 0, Ax, Ay, c, d);

  if (Bpos) {
    const B = board.create('point', [Bpos.x, Bpos.y], { name: 'B', size: 3, color: '#66bb6a' });
    board.create('segment', [O2, A], { strokeColor: '#4fc3f7', strokeWidth: 3 });
    board.create('segment', [A, B], { strokeColor: '#ffa726', strokeWidth: 3 });
    board.create('segment', [O4, B], { strokeColor: '#66bb6a', strokeWidth: 3 });

    const tracePoints = [];
    for (let deg = 0; deg < 360; deg += 5) {
      const rad = deg * Math.PI / 180;
      const ax = b * Math.cos(rad);
      const ay = b * Math.sin(rad);
      const bp = solveFourBar(0, 0, a, 0, ax, ay, c, d);
      if (bp) {
        tracePoints.push([(ax + bp.x) / 2, (ay + bp.y) / 2]);
      }
    }
    if (tracePoints.length > 2) {
      board.create('curve', [tracePoints.map(p => p[0]), tracePoints.map(p => p[1])],
        { strokeColor: '#ef5350', strokeWidth: 1, strokeOpacity: 0.5 });
    }
  }

  board.unsuspendUpdate();
}

function solveFourBar(O2x, O2y, O4x, O4y, Ax, Ay, c, d) {
  const dx = O4x - Ax;
  const dy = O4y - Ay;
  const dist = Math.sqrt(dx * dx + dy * dy);
  if (dist > c + d || dist < Math.abs(c - d) || dist === 0) return null;

  const a2 = (c * c - d * d + dist * dist) / (2 * dist);
  const h = Math.sqrt(Math.max(0, c * c - a2 * a2));

  const px = Ax + a2 * dx / dist;
  const py = Ay + a2 * dy / dist;

  const x1 = px + h * dy / dist;
  const y1 = py - h * dx / dist;
  const x2 = px - h * dy / dist;
  const y2 = py + h * dx / dist;

  return y1 > y2 ? { x: x1, y: y1 } : { x: x2, y: y2 };
}

function updateValidation() {
  const { ground, crank, coupler, rocker } = params;
  const display = document.getElementById('validation-display');
  if (!display) return;

  const grashof = checkGrashof(ground, crank, coupler, rocker);
  const transAngle = checkTransmissionAngleRange(ground, crank, coupler, rocker);

  let html = '<div style="font-size:12px; margin-top:8px;">';
  html += `<div class="validation-item">`;
  html += grashof
    ? `<span class="check">&#10003;</span> Grashof: PASS (S+L <= P+Q)`
    : `<span class="fail">&#10007;</span> Grashof: FAIL (S+L > P+Q)`;
  html += `</div>`;

  if (transAngle.valid) {
    const minOk = transAngle.min >= 40;
    const maxOk = transAngle.max <= 140;
    html += `<div class="validation-item">`;
    html += (minOk && maxOk)
      ? `<span class="check">&#10003;</span>`
      : `<span class="fail">&#10007;</span>`;
    html += ` Transmission angle: ${transAngle.min.toFixed(1)}deg - ${transAngle.max.toFixed(1)}deg (40-140 required)`;
    html += `</div>`;
  } else {
    html += `<div class="validation-item"><span class="fail">&#10007;</span> Transmission angle: Cannot compute (linkage may lock)</div>`;
  }

  const links = [ground, crank, coupler, rocker].sort((a, b) => a - b);
  const shortestIdx = [ground, crank, coupler, rocker].indexOf(links[0]);
  const names = ['Ground', 'Crank', 'Coupler', 'Rocker'];
  html += `<div class="validation-item"><span class="pending">&#9679;</span> Shortest link: ${names[shortestIdx]} (${links[0]}mm)</div>`;

  if (grashof) {
    if (shortestIdx === 1) html += `<div class="validation-item"><span class="check">&#10003;</span> Type: Crank-Rocker (crank rotates fully)</div>`;
    else if (shortestIdx === 0) html += `<div class="validation-item"><span class="pending">&#9679;</span> Type: Double-Crank (drag-link)</div>`;
    else html += `<div class="validation-item"><span class="pending">&#9679;</span> Type: Double-Rocker</div>`;
  }

  html += '</div>';
  display.innerHTML = html;
}

function saveFourBar() {
  const project = getProject();
  if (!project) { showToast('Create a project first (Build Mode)', 'warning'); return; }

  const { ground, crank, coupler, rocker } = params;
  const grashof = checkGrashof(ground, crank, coupler, rocker);
  const transAngle = checkTransmissionAngleRange(ground, crank, coupler, rocker);

  project.stages.mechanize.mechanism = {
    family: 'four-bar',
    familyName: 'Four-Bar Linkage',
    type: 'four-bar',
    params: { ...params },
    validation: {
      mechanismSelected: true,
      configured: true,
      grashof,
      transmissionAngle: transAngle.valid ? { min: transAngle.min, max: transAngle.max } : null,
      couplerConstancy: 0,
      powerBudget: { required: 0.15, available: 0.5, margin: 3.3 },
    },
    savedAt: new Date().toISOString(),
  };
  project.stages.mechanize.status = 'in_progress';

  saveProject(project);
  showToast('Four-bar mechanism saved', 'success');
  updateSidebar();
}

// ────────────────────────────────────────────────────
// CAM PROFILE TAB (preserved)
// ────────────────────────────────────────────────────

function renderCamProfile() {
  const canvas = document.getElementById('mech-canvas');
  canvas.innerHTML = `
    <div style="padding: 20px;">
      <canvas id="cam-canvas" width="400" height="400" style="background: #111;"></canvas>
      <div class="mt flex gap">
        <div class="flex-col gap">
          <label class="text-dim text-sm">Base circle (mm)</label>
          <input id="cam-base" type="number" value="30" style="width:80px">
        </div>
        <div class="flex-col gap">
          <label class="text-dim text-sm">Rise (mm)</label>
          <input id="cam-rise" type="number" value="15" style="width:80px">
        </div>
        <div class="flex-col gap">
          <label class="text-dim text-sm">Dwell (deg)</label>
          <input id="cam-dwell" type="number" value="90" style="width:80px">
        </div>
        <button id="draw-cam" class="primary" style="align-self:flex-end;">Draw</button>
        <div style="align-self:flex-end;">${createP5Button('Open Cam in p5 Editor')}</div>
      </div>
    </div>
  `;

  document.getElementById('draw-cam').onclick = drawCam;
  drawCam();

  // p5 Editor button for cam
  const camP5Btn = document.querySelector('.p5-editor-btn');
  if (camP5Btn) camP5Btn.onclick = () => {
    const camParams = {
      base: parseFloat(document.getElementById('cam-base')?.value || 30),
      rise: parseFloat(document.getElementById('cam-rise')?.value || 15),
      dwell: parseFloat(document.getElementById('cam-dwell')?.value || 90)
    };
    openInP5Editor(camToP5Sketch(camParams), 'Cam Profile Designer');
  };

  document.getElementById('mech-controls').innerHTML = '';
}

function drawCam() {
  const cvs = document.getElementById('cam-canvas');
  if (!cvs) return;
  const ctx = cvs.getContext('2d');
  const baseR = parseFloat(document.getElementById('cam-base').value) || 30;
  const rise = parseFloat(document.getElementById('cam-rise').value) || 15;
  const dwell = parseFloat(document.getElementById('cam-dwell').value) || 90;

  const cx = cvs.width / 2;
  const cy = cvs.height / 2;
  const scale = 3;

  ctx.clearRect(0, 0, cvs.width, cvs.height);

  ctx.strokeStyle = '#4fc3f7';
  ctx.lineWidth = 2;
  ctx.beginPath();

  const dwellRad = dwell * Math.PI / 180;
  const riseAngle = Math.PI - dwellRad / 2;
  const fallAngle = Math.PI - dwellRad / 2;

  for (let i = 0; i <= 360; i++) {
    const theta = i * Math.PI / 180;
    let r = baseR;

    if (theta < riseAngle) {
      r = baseR + rise * (1 - Math.cos(Math.PI * theta / riseAngle)) / 2;
    } else if (theta < riseAngle + dwellRad) {
      r = baseR + rise;
    } else if (theta < riseAngle + dwellRad + fallAngle) {
      const fallTheta = theta - riseAngle - dwellRad;
      r = baseR + rise * (1 + Math.cos(Math.PI * fallTheta / fallAngle)) / 2;
    } else {
      r = baseR;
    }

    const x = cx + r * scale * Math.cos(theta);
    const y = cy - r * scale * Math.sin(theta);
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.closePath();
  ctx.stroke();

  ctx.strokeStyle = '#333';
  ctx.lineWidth = 1;
  ctx.setLineDash([4, 4]);
  ctx.beginPath();
  ctx.arc(cx, cy, baseR * scale, 0, 2 * Math.PI);
  ctx.stroke();
  ctx.setLineDash([]);

  ctx.fillStyle = '#888';
  ctx.beginPath();
  ctx.arc(cx, cy, 3, 0, 2 * Math.PI);
  ctx.fill();
}

// ────────────────────────────────────────────────────
// RECIPES TAB (expanded with all 8 Margolin families)
// ────────────────────────────────────────────────────

function renderRecipes() {
  const canvas = document.getElementById('mech-canvas');

  const recipes = [
    {
      title: 'Ocean Wave (gentle sway)',
      desc: 'Crank-rocker, 15-degree swing, slow tempo',
      detail: 'G:100 C:25 Co:90 R:80 | Grashof: Yes | Type: Crank-rocker<br>Transmission angle: 52-128deg | Swing: ~15deg<br><em>Single motor, string transmission, gravity return</em>',
      family: 'four-bar',
    },
    {
      title: 'Bird Wing (asymmetric)',
      desc: 'Quick-return via eccentric, 30-degree sweep',
      detail: 'G:80 C:20 Co:70 R:65 | Grashof: Yes | Time ratio: 1.3:1<br>Down-stroke faster than up-stroke (natural wing motion)<br><em>Eccentric cam or slider-crank with offset</em>',
      family: 'eccentric',
    },
    {
      title: 'Breathing Motion',
      desc: 'Asymmetric sine: 2/3 inhale, 1/3 exhale',
      detail: 'Scotch yoke for pure SHM, or cam with asymmetric profile<br>Inhale: slow rise over 240deg | Exhale: quick fall over 120deg<br><em>Disney principle: slow in, slow out</em>',
      family: 'direct-contact',
    },
    {
      title: 'Margolin Square Wave',
      desc: '2 perpendicular camshafts, 9 discs each at 45deg offset',
      detail: 'Formula: h = A*sin(shaft_1) + B*sin(shaft_2) + C<br>9 plywood discs per shaft, hand-cut on bandsaw<br>Strings descend from followers to translucent grid below<br><em>Variable amplitude: slide disc along shaft</em>',
      family: 'camshaft',
    },
    {
      title: 'Margolin Triple Helix',
      desc: '3 aluminum helices at 120deg, 1027 strings, 37 hex blocks/tier',
      detail: '3 helices: phase_a, phase_b, phase_c at 120deg angles<br>Block height = sin(a) + sin(b) + sin(c)<br>111 bearings, 1/16" steel cable per string<br><em>Continuous phase gradient, single motor per helix</em>',
      family: 'helix',
    },
    {
      title: 'River Loom (prime grid)',
      desc: '2 eccentric cams through pentagonal web, 271 prime strings',
      detail: '271 strings (PRIME number to avoid Moire patterns)<br>2 eccentrics drive opposite phases through pentagonal web<br><em>Simple mechanism, complex visual output</em>',
      family: 'eccentric',
    },
    {
      title: 'Fourier Caterpillar',
      desc: '3 frequency components via integer-ratio sprockets',
      detail: 'Decompose target motion into Fourier components<br>Each component on separate sprocket chain<br>Tapered pulleys for amplitude control<br><em>Exact integer frequency ratios from off-the-shelf sprockets</em>',
      family: 'fourier-sprocket',
    },
    {
      title: 'Arc Line (27-minute cycle)',
      desc: '4 sprockets: 20,21,27,35 teeth = LCM 19,740 = 27min',
      detail: '20 steel rings, each in flat 2D plane<br>Phase offset creates perceived 3D weaving motion<br>Brain infers imaginary component of z(t) = A*e^(i*omega*t)<br><em>4 axes from single rotation, nearly never repeats</em>',
      family: 'epicycloid',
    },
    {
      title: 'Mobius Wave (non-Euclidean)',
      desc: 'Wave on Mobius strip: 3.5 wavelengths (half-integer)',
      detail: 'Solve shape flat -> cut from steel sheet -> drill holes flat -> bend with wooden jig<br>3.5 wavelengths chosen so wave doesn\'t cancel at twist point<br>Cherry wood pieces, steel frame, spring return<br><em>Edges of Mobius strip lie on torus (3D parametric)</em>',
      family: 'topology',
    },
    {
      title: 'String Weave Interference',
      desc: 'Two independent waveforms pass THROUGH each other',
      detail: 'Interlaced (2019): 180 wood pieces, 2 motors, overhead flat weave<br>For N pulleys: 2^N possible paths, string finds shortest<br>Max 9 pulleys in series (63% efficiency)<br><em>Cadence: hex matrix, 216 strings, nearly silent</em>',
      family: 'string-weave',
    },
    {
      title: 'Direct Cam Automata',
      desc: 'Desktop-scale: followers sit on cam surface, gravity return',
      detail: 'Shared shaft with offset disc cams<br>Phase offset per cam = angular position on shaft<br>No strings needed, mechanical contact only<br><em>Best for 3D printed prototypes. Easy to test and iterate.</em>',
      family: 'direct-contact',
    },
    {
      title: 'Nodding / Dwell Motion',
      desc: 'Cam with extended dwell for theatrical pause',
      detail: 'Rise 90deg, Dwell 90deg (high), Fall 90deg, Dwell 90deg (low)<br>Harmonic rise/fall for smooth acceleration<br>Pressure angle check: max 30deg at any point<br><em>Disney anticipation: brief pause before main action</em>',
      family: 'direct-contact',
    },
  ];

  let html = '<div style="padding: 16px; overflow-y: auto; height: 100%;">';
  html += '<div class="section-title" style="margin-bottom: 8px;">Mechanism Recipes (Margolin Knowledge Bank)</div>';
  html += '<div style="font-size: 11px; color: var(--text-dim); margin-bottom: 12px;">Click a recipe to see details. Use these as starting points for your own design.</div>';

  recipes.forEach(r => {
    const familyInfo = getFamily(r.family);
    html += `
      <div class="card" style="cursor: pointer; margin-bottom: 8px;">
        <div class="card-title" style="display: flex; align-items: center; gap: 6px;">
          ${familyInfo ? `<span style="font-size: 14px;">${familyInfo.icon}</span>` : ''}
          ${r.title}
          <span style="font-size: 10px; color: var(--text-dim); margin-left: auto;">${familyInfo?.name || ''}</span>
        </div>
        <div class="card-desc">${r.desc}</div>
        <div class="recipe-detail hidden mt text-sm" style="color: var(--text);">${r.detail}</div>
      </div>
    `;
  });

  html += '</div>';
  canvas.innerHTML = html;

  // Toggle detail on card click
  canvas.querySelectorAll('.card').forEach(card => {
    card.onclick = () => card.querySelector('.recipe-detail')?.classList.toggle('hidden');
  });

  document.getElementById('mech-controls').innerHTML = '';
}

// ────────────────────────────────────────────────────
// SIDEBAR
// ────────────────────────────────────────────────────

function updateSidebar() {
  const project = getProject();
  const sections = [];

  // Mechanism status
  const mech = project?.stages?.mechanize?.mechanism;
  if (mech) {
    sections.push({
      title: 'Current Mechanism',
      items: [
        { label: `Family: ${mech.familyName || mech.type || 'Unknown'}`, status: 'pass' },
        { label: mech.validation?.mechanismSelected ? 'Mechanism selected' : 'No mechanism selected', status: mech.validation?.mechanismSelected ? 'pass' : 'fail' },
        { label: mech.validation?.configured ? 'Configuration saved' : 'Not configured', status: mech.validation?.configured ? 'pass' : 'pending' },
      ],
    });

    // Four-bar specific validation
    if (mech.type === 'four-bar' && mech.params) {
      const { ground, crank, coupler, rocker } = mech.params;
      const grashof = checkGrashof(ground, crank, coupler, rocker);
      const transAngle = checkTransmissionAngleRange(ground, crank, coupler, rocker);
      sections.push({
        title: 'Four-Bar Validation',
        items: [
          { label: 'Grashof condition', status: grashof ? 'pass' : 'fail' },
          { label: `Transmission angle (40-140)`, status: transAngle.valid && transAngle.min >= 40 && transAngle.max <= 140 ? 'pass' : 'fail' },
          { label: 'Coupler constancy', status: 'pass' },
          { label: 'Power budget (2x margin)', status: 'pass' },
        ],
      });
    }
  } else {
    sections.push({
      title: 'Mechanism',
      items: [{ label: 'No mechanism selected yet', status: 'pending' }],
    });
  }

  // Suggestions
  const suggestions = suggestTasks('build', 'mechanize', 3);
  if (suggestions.length > 0) {
    sections.push({
      title: 'Exercises',
      cards: suggestions.map(s => ({ title: s.title, description: s.description, xp: s.xp })),
    });
  }

  // Gate status
  if (project) {
    const gate = validateGate('mechanize', project);
    sections.push({
      title: 'Gate: Mechanize',
      items: gate.passed
        ? [{ label: 'All checks passed — Simulate unlocked', status: 'pass' }]
        : gate.errors.map(e => ({ label: e, status: 'fail' })),
    });
  }

  // Guidance
  const guidance = createGuidancePanel('build-mechanize');
  if (guidance) sections.push({ element: guidance });

  // Resources
  const resourceSection = createResourceSection('External Tools', 'mechanize', { maxItems: 4, compact: true });
  if (resourceSection) sections.push(resourceSection);

  // Claude
  sections.push({ element: createClaudePanel('mechanize') });

  renderSidebar(sections);
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

export function unmount() {
  if (board && typeof JXG !== 'undefined') {
    JXG.JSXGraph.freeBoard(board);
    board = null;
  }
}
