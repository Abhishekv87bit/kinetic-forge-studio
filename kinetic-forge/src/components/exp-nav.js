// Experiment Mode navigation — Playground + Gallery

import { navigate, getCurrentRoute } from '../router.js';

const EXP_TABS = [
  { id: 'playground', label: 'Playground', route: 'exp-playground', key: '1' },
  { id: 'gallery', label: 'Gallery', route: 'exp-gallery', key: '2' }
];

export function renderExpNav() {
  const nav = document.getElementById('app-nav');
  nav.innerHTML = '';

  const current = getCurrentRoute();

  EXP_TABS.forEach(tab => {
    const el = document.createElement('div');
    el.className = 'nav-item' + (current === tab.route ? ' active' : '');
    el.innerHTML = `<span>${tab.label}</span><span class="text-dim text-sm">[${tab.key}]</span>`;
    el.onclick = () => navigate(tab.route);
    nav.appendChild(el);
  });
}
