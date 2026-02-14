// Build Mode: stage navigation bar with gate status dots
// 4-stage pipeline: Mechanize → Simulate → Build → Iterate

import { navigate, getCurrentRoute } from '../router.js';
import { getProject, createProject } from '../state.js';
import { validateGate } from '../gate.js';
import { promptInput } from './modal.js';
import { showToast } from '../toast.js';

const STAGES = [
  { id: 'mechanize', label: 'Mechanize', route: 'build-mechanize', key: '1' },
  { id: 'simulate', label: 'Simulate', route: 'build-simulate', key: '2' },
  { id: 'build', label: 'Build', route: 'build-build', key: '3' },
  { id: 'iterate', label: 'Iterate', route: 'build-iterate', key: '4' }
];

export function getStages() {
  return STAGES;
}

export function getStageIndex(stageId) {
  return STAGES.findIndex(s => s.id === stageId);
}

export function renderStageNav() {
  const nav = document.getElementById('app-nav');
  nav.innerHTML = '';

  const project = getProject();
  const currentRoute = getCurrentRoute();

  // New Project button when no project loaded
  if (!project) {
    const newBtn = document.createElement('button');
    newBtn.className = 'primary';
    newBtn.style.cssText = 'font-size:11px;padding:4px 12px;margin-right:12px;';
    newBtn.textContent = '+ New Project';
    newBtn.onclick = async () => {
      const name = await promptInput('Project Name', 'e.g. Wave Sculpture v1');
      if (name) {
        await createProject(name);
        showToast(`Created: ${name}`, 'success');
        renderStageNav();
        navigate('build-mechanize');
      }
    };
    nav.appendChild(newBtn);
  }

  STAGES.forEach((stage, i) => {
    const item = document.createElement('div');
    item.className = 'nav-item';

    // Determine gate status
    let gateClass = 'locked';
    if (project) {
      const stageData = project.stages[stage.id];
      if (!stageData) {
        gateClass = 'locked';
      } else if (stageData.status === 'complete') {
        gateClass = 'passed';
      } else if (stageData.status === 'in_progress') {
        const gate = validateGate(stage.id, project);
        gateClass = gate.passed ? 'passed' : 'pending';
      } else if (stageData.status === 'locked') {
        if (i === 0 || project.stages[STAGES[i - 1].id]?.status === 'complete' ||
            project.stages[STAGES[i - 1].id]?.status === 'in_progress') {
          gateClass = 'pending';
        }
      }
    } else {
      gateClass = i === 0 ? 'pending' : 'locked';
    }

    if (currentRoute === stage.route) {
      item.classList.add('active');
    }

    if (gateClass === 'locked' && !project) {
      item.classList.add('locked');
    }

    // Gate dot
    const dot = document.createElement('span');
    dot.className = `gate-dot ${gateClass}`;

    // Label
    const label = document.createElement('span');
    label.textContent = `${stage.key}. ${stage.label}`;

    item.appendChild(dot);
    item.appendChild(label);

    item.onclick = () => {
      if (gateClass !== 'locked') {
        navigate(stage.route);
      }
    };

    nav.appendChild(item);
  });

  // Project name display
  if (project) {
    const nameEl = document.createElement('span');
    nameEl.className = 'text-dim text-sm';
    nameEl.style.marginLeft = 'auto';
    nameEl.textContent = project.name;
    nav.appendChild(nameEl);
  }
}
