// Mode toggle: LEARN | BUILD | EXPERIMENT switch

import { getProfile, updateProfile } from '../state.js';
import { navigate } from '../router.js';

let currentMode = 'learn';

const MODES = [
  { id: 'learn', label: 'LEARN', default: 'learn-dashboard' },
  { id: 'build', label: 'BUILD', default: 'build-mechanize' },
  { id: 'experiment', label: 'EXPERIMENT', default: 'exp-playground' }
];

export function getMode() {
  return currentMode;
}

export function setMode(mode) {
  currentMode = mode;
  render();
  updateProfile({ mode });

  const modeConfig = MODES.find(m => m.id === mode);
  if (modeConfig) {
    navigate(modeConfig.default);
  }

  window.dispatchEvent(new CustomEvent('mode-changed', { detail: { mode } }));
}

function render() {
  const container = document.getElementById('mode-toggle-container');
  container.innerHTML = '';

  const toggle = document.createElement('div');
  toggle.className = 'mode-toggle';

  MODES.forEach(m => {
    const btn = document.createElement('button');
    btn.textContent = m.label;
    btn.className = currentMode === m.id ? 'active' : '';
    btn.onclick = () => setMode(m.id);
    toggle.appendChild(btn);
  });

  container.appendChild(toggle);
}

export function initModeToggle() {
  const profile = getProfile();
  currentMode = profile?.mode || 'learn';
  // Ensure valid mode (backward compat)
  if (!MODES.find(m => m.id === currentMode)) currentMode = 'learn';
  render();
}
