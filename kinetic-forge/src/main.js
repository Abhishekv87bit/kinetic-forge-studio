// KineticForge — Main entry point
// Bootstrap: load state, register routes, init UI

import { registerRoute, navigate, initRouter, setBeforeNavigate, getCurrentRoute } from './router.js';
import { loadProfile, loadTaskHistory, checkApiKey, setApiKey, getProfile, listProjects, loadProject, createProject, getProject } from './state.js';
import { initModeToggle, getMode, setMode } from './components/mode-toggle.js';
import { renderStageNav } from './components/stage-nav.js';
import { renderLearnNav } from './components/learn-nav.js';
import { renderExpNav } from './components/exp-nav.js';
import { updateProgressBar } from './components/progress-bar.js';
import { initKeyboard, registerShortcut } from './keyboard.js';
import { showToast } from './toast.js';
import { canAdvanceTo } from './gate.js';
import { promptInput, showModal } from './components/modal.js';
import { syncToGitHub } from './github-sync.js';
import { showOnboarding, resetOnboarding } from './components/onboarding.js';

// --- Stage modules (lazy imported) ---
const stages = {
  // Build mode (4-stage pipeline: Mechanize → Simulate → Build → Iterate)
  'build-mechanize': () => import('./stages/mechanize.js'),
  'build-simulate': () => import('./stages/simulate.js'),
  'build-build': () => import('./stages/build.js'),
  'build-iterate': () => import('./stages/iterate.js'),
  // Learn mode
  'learn-dashboard': () => import('./learn/dashboard.js'),
  'learn-curriculum': () => import('./learn/curriculum.js'),
  'learn-exercises': () => import('./learn/exercises.js'),
  'learn-skills': () => import('./learn/skills.js'),
  // Experiment mode
  'exp-playground': () => import('./experiment/playground.js'),
  'exp-gallery': () => import('./experiment/gallery.js'),
};

// Cache loaded modules
const moduleCache = {};

async function loadStageModule(routeId) {
  if (!moduleCache[routeId]) {
    const loader = stages[routeId];
    if (loader) {
      moduleCache[routeId] = await loader();
    }
  }
  return moduleCache[routeId];
}

// --- Route Registration ---
function registerAllRoutes() {
  Object.keys(stages).forEach(routeId => {
    registerRoute(routeId, {
      mount: async (container) => {
        const mod = await loadStageModule(routeId);
        if (mod?.mount) await mod.mount(container);
      },
      unmount: async () => {
        const mod = moduleCache[routeId];
        if (mod?.unmount) mod.unmount();
      },
      label: routeId
    });
  });
}

// --- Navigation Guards ---
function setupNavigationGuards() {
  setBeforeNavigate((from, to) => {
    // Auto-switch mode based on route prefix
    if (to?.startsWith('build-') && getMode() !== 'build') {
      setMode('build');
    }
    if (to?.startsWith('learn-') && getMode() !== 'learn') {
      setMode('learn');
    }
    if (to?.startsWith('exp-') && getMode() !== 'experiment') {
      setMode('experiment');
    }

    // Gate check for build mode
    if (to?.startsWith('build-') && getProject()) {
      const stageMap = {
        'build-mechanize': 'mechanize',
        'build-simulate': 'simulate',
        'build-build': 'build',
        'build-iterate': 'iterate'
      };
      const targetStage = stageMap[to];
      if (targetStage && !canAdvanceTo(targetStage, getProject())) {
        showToast('Complete previous stage gate first', 'warning');
        return false;
      }
    }

    return true;
  });
}

// --- Header Actions ---
function renderHeaderActions() {
  const container = document.getElementById('header-actions');
  container.innerHTML = '';

  // Project selector (Build Mode)
  const projectBtn = document.createElement('button');
  projectBtn.textContent = getProject()?.name || 'Project';
  projectBtn.style.fontSize = '11px';
  projectBtn.onclick = showProjectSelector;
  container.appendChild(projectBtn);

  // Sync button
  const syncBtn = document.createElement('button');
  syncBtn.textContent = 'Sync';
  syncBtn.style.fontSize = '11px';
  syncBtn.onclick = () => syncToGitHub();
  container.appendChild(syncBtn);

  // Settings
  const settingsBtn = document.createElement('button');
  settingsBtn.textContent = 'Settings';
  settingsBtn.style.fontSize = '11px';
  settingsBtn.onclick = showSettings;
  container.appendChild(settingsBtn);
}

async function showProjectSelector() {
  const projects = await listProjects();

  const list = document.createElement('div');
  list.className = 'flex-col gap';

  if (projects.length > 0) {
    projects.forEach(p => {
      const item = document.createElement('div');
      item.className = 'card';
      item.innerHTML = `<div class="card-title">${p.name}</div><div class="card-desc">Stage: ${p.currentStage}</div>`;
      item.onclick = async () => {
        await loadProject(p.id);
        overlay.remove();
        updateUI();
        showToast(`Loaded: ${p.name}`, 'info');
      };
      list.appendChild(item);
    });
  } else {
    list.innerHTML = '<p class="text-dim text-sm">No projects yet</p>';
  }

  const createBtn = document.createElement('button');
  createBtn.className = 'primary mt';
  createBtn.textContent = '+ New Project';
  createBtn.onclick = async () => {
    overlay.remove();
    const name = await promptInput('Project Name', 'e.g. Wave Ocean v1');
    if (name) {
      await createProject(name);
      updateUI();
      showToast(`Created: ${name}`, 'success');
      if (getMode() !== 'build') setMode('build');
    }
  };
  list.appendChild(createBtn);

  const overlay = showModal({ title: 'Projects', content: list });
}

async function showSettings() {
  const hasKey = await checkApiKey();

  const content = document.createElement('div');
  content.className = 'flex-col gap';
  content.innerHTML = `
    <div class="text-sm">
      <strong>Claude API Key:</strong> ${hasKey ? '<span class="text-accent">Configured</span>' : '<span style="color:var(--error)">Not set</span>'}
    </div>
    <input id="settings-apikey" type="password" placeholder="sk-ant-..." value="">
    <button id="save-apikey">Save API Key</button>
    <hr style="border-color:var(--border);">
    <div class="text-sm text-dim">
      <strong>Keyboard Shortcuts:</strong><br>
      Ctrl+L: Learn Mode<br>
      Ctrl+B: Build Mode<br>
      Ctrl+E: Experiment Mode<br>
      Ctrl+1-4: Navigate stages (Build)<br>
      Ctrl+S: Sync to GitHub
    </div>
    <button id="replay-onboarding" style="font-size:11px; width:100%;">Replay Onboarding Walkthrough</button>
  `;

  const overlay = showModal({ title: 'Settings', content, actions: [{ label: 'Close' }] });

  content.querySelector('#save-apikey').onclick = async () => {
    const key = content.querySelector('#settings-apikey').value.trim();
    if (key) {
      await setApiKey(key);
      showToast('API key saved', 'success');
      overlay.remove();
    }
  };

  content.querySelector('#replay-onboarding').onclick = async () => {
    overlay.remove();
    await resetOnboarding();
    await showOnboarding();
  };
}

// --- UI Update ---
function updateUI() {
  const mode = getMode();

  if (mode === 'build') {
    renderStageNav();
  } else if (mode === 'experiment') {
    renderExpNav();
  } else {
    renderLearnNav();
  }

  renderHeaderActions();
  updateProgressBar();
}

// --- Keyboard Shortcuts ---
function setupShortcuts() {
  registerShortcut('ctrl+l', () => setMode('learn'), 'Switch to Learn Mode');
  registerShortcut('ctrl+b', () => setMode('build'), 'Switch to Build Mode');
  registerShortcut('ctrl+e', () => setMode('experiment'), 'Switch to Experiment Mode');
  registerShortcut('ctrl+1', () => navigate('build-mechanize'), 'Go to Mechanize');
  registerShortcut('ctrl+2', () => navigate('build-simulate'), 'Go to Simulate');
  registerShortcut('ctrl+3', () => navigate('build-build'), 'Go to Build');
  registerShortcut('ctrl+4', () => navigate('build-iterate'), 'Go to Iterate');
  registerShortcut('ctrl+s', () => syncToGitHub(), 'Sync to GitHub');
}

// --- Listen for mode/route changes ---
function setupListeners() {
  window.addEventListener('mode-changed', () => updateUI());
  window.addEventListener('route-changed', () => updateUI());
  // Re-mount current route when guidance is toggled (to refresh sidebar)
  window.addEventListener('guidance-toggled', async () => {
    const routeId = getCurrentRoute();
    if (routeId && moduleCache[routeId]) {
      const container = document.getElementById('workspace');
      if (container && moduleCache[routeId].mount) {
        await moduleCache[routeId].mount(container);
      }
    }
  });
}

// --- Bootstrap ---
async function init() {
  console.log('KineticForge starting...');
  const t0 = performance.now();

  // Load state
  await loadProfile();
  await loadTaskHistory();

  // Register routes
  registerAllRoutes();

  // Setup navigation
  setupNavigationGuards();
  setupShortcuts();
  setupListeners();
  initKeyboard();

  // Init UI
  initModeToggle();
  updateUI();

  // Start router
  initRouter();

  const elapsed = performance.now() - t0;
  console.log(`KineticForge ready in ${elapsed.toFixed(0)}ms`);

  // Show onboarding on first visit
  await showOnboarding();

  // Check API key
  const hasKey = await checkApiKey();
  if (!hasKey) {
    showToast('Set your Claude API key in Settings to enable AI suggestions', 'info', 5000);
  }
}

init();
