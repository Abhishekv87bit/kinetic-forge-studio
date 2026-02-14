// Stage 6: ITERATE — Test, measure, refine, document

import { getProject, saveProject } from '../state.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { showToast } from '../toast.js';
import { validateGate } from '../gate.js';
import { recordGatePass } from '../xp.js';
import { createResourceSection } from '../components/resource-links.js';
import { createGuidancePanel } from '../components/guidance.js';

export async function mount(container) {
  const project = getProject();
  const logs = project?.stages?.iterate?.testLogs || [];

  container.innerHTML = `
    <div class="tab-bar">
      <div class="tab active" data-tab="log">Test Log</div>
      <div class="tab" data-tab="history">History (${logs.length})</div>
    </div>
    <div id="iterate-workspace">
      <div class="section-title">New Test Entry</div>
      <div class="flex-col gap">
        <label class="text-dim text-sm">What worked?</label>
        <textarea id="iter-worked" rows="3" placeholder="Describe what went well..."></textarea>

        <label class="text-dim text-sm mt">What didn't work?</label>
        <textarea id="iter-didnt" rows="3" placeholder="Describe issues, failures, surprises..."></textarea>

        <label class="text-dim text-sm mt">Measurements</label>
        <div id="measurements-list"></div>
        <div class="flex gap mt">
          <input id="meas-name" type="text" placeholder="e.g. Rocker swing" style="flex:1">
          <input id="meas-expected" type="text" placeholder="Expected" style="width:80px">
          <input id="meas-actual" type="text" placeholder="Actual" style="width:80px">
          <button id="add-meas">Add</button>
        </div>

        <label class="text-dim text-sm mt">Notes for next iteration</label>
        <textarea id="iter-notes" rows="2" placeholder="What to try next time..."></textarea>

        <div class="flex gap mt">
          <button id="save-log" class="primary">Save Test Log</button>
          <button id="complete-iteration">Complete Iteration Cycle</button>
        </div>
      </div>
    </div>
  `;

  const measurements = [];

  document.getElementById('add-meas').onclick = () => {
    const name = document.getElementById('meas-name').value.trim();
    const expected = document.getElementById('meas-expected').value.trim();
    const actual = document.getElementById('meas-actual').value.trim();
    if (!name) { showToast('Enter measurement name', 'warning'); return; }
    measurements.push({ name, expected, actual, delta: '' });
    renderMeasurements();
    document.getElementById('meas-name').value = '';
    document.getElementById('meas-expected').value = '';
    document.getElementById('meas-actual').value = '';
  };

  function renderMeasurements() {
    const list = document.getElementById('measurements-list');
    list.innerHTML = measurements.map((m, i) => `
      <div class="flex gap text-sm" style="padding: 4px 0;">
        <span style="flex:1">${m.name}</span>
        <span style="width:80px">exp: ${m.expected}</span>
        <span style="width:80px">act: ${m.actual}</span>
      </div>
    `).join('');
  }

  document.getElementById('save-log').onclick = () => {
    if (!project) { showToast('No project loaded', 'warning'); return; }

    const log = {
      id: 'log-' + Date.now().toString(36),
      date: new Date().toISOString(),
      whatWorked: document.getElementById('iter-worked').value.trim(),
      whatDidnt: document.getElementById('iter-didnt').value.trim(),
      measurements: [...measurements],
      notes: document.getElementById('iter-notes').value.trim()
    };

    if (!project.stages.iterate.testLogs) project.stages.iterate.testLogs = [];
    project.stages.iterate.testLogs.push(log);
    project.stages.iterate.status = 'in_progress';
    saveProject(project);
    showToast('Test log saved', 'success');
    updateSidebar();
  };

  document.getElementById('complete-iteration').onclick = async () => {
    if (!project) return;
    const gate = validateGate('iterate', project);
    if (!gate.passed) {
      showToast(gate.errors[0], 'error');
      return;
    }

    project.stages.iterate.status = 'complete';
    project.iterations.push({
      number: project.iterations.length + 1,
      completedAt: new Date().toISOString()
    });

    // Reset stages for next iteration (except discover)
    // This allows the user to cycle through again
    saveProject(project);
    await recordGatePass('iterate');
    showToast('Iteration complete! Ready for next cycle.', 'success');
    updateSidebar();
  };

  container.querySelectorAll('.tab').forEach(tab => {
    tab.onclick = () => {
      container.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      if (tab.dataset.tab === 'history') showHistory(logs);
    };
  });

  updateSidebar();
}

function showHistory(logs) {
  const workspace = document.getElementById('iterate-workspace');
  if (logs.length === 0) {
    workspace.innerHTML = '<p class="text-dim" style="padding:20px;">No test logs yet.</p>';
    return;
  }

  workspace.innerHTML = logs.map(log => `
    <div class="card">
      <div class="card-title">${new Date(log.date).toLocaleDateString()}</div>
      <div class="text-sm mt"><strong>Worked:</strong> ${log.whatWorked || '—'}</div>
      <div class="text-sm"><strong>Issues:</strong> ${log.whatDidnt || '—'}</div>
      ${log.measurements?.length ? `<div class="text-sm"><strong>Measurements:</strong> ${log.measurements.map(m => `${m.name}: ${m.actual} (expected ${m.expected})`).join(', ')}</div>` : ''}
      ${log.notes ? `<div class="text-sm"><strong>Next:</strong> ${log.notes}</div>` : ''}
    </div>
  `).join('');
}

function updateSidebar() {
  const project = getProject();
  const sections = [];

  if (project) {
    const gate = validateGate('iterate', project);
    sections.push({
      title: 'Gate: Iterate',
      items: gate.passed
        ? [{ label: 'Test log complete', status: 'pass' }]
        : gate.errors.map(e => ({ label: e, status: 'fail' }))
    });

    sections.push({
      title: 'Iterations',
      html: `<p class="text-sm">Completed: ${project.iterations?.length || 0} cycles</p>`
    });
  }

  // Guidance
  const guidance = createGuidancePanel('build-iterate');
  if (guidance) sections.push({ element: guidance });

  // External resources — community & artists
  const resourceSection = createResourceSection('Community & Inspiration', 'iterate', { maxItems: 5, compact: true });
  if (resourceSection) sections.push(resourceSection);

  sections.push({ element: createClaudePanel('iterate') });
  renderSidebar(sections);
}

export function unmount() {}
