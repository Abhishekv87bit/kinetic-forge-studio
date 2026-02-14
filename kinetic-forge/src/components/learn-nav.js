// Learn Mode: dashboard/curriculum/exercises/skills navigation tabs

import { navigate, getCurrentRoute } from '../router.js';

const LEARN_TABS = [
  { id: 'dashboard', label: 'Dashboard', route: 'learn-dashboard', key: '1' },
  { id: 'curriculum', label: 'Curriculum', route: 'learn-curriculum', key: '2' },
  { id: 'exercises', label: 'Exercises', route: 'learn-exercises', key: '3' },
  { id: 'skills', label: 'Skills', route: 'learn-skills', key: '4' }
];

export function renderLearnNav() {
  const nav = document.getElementById('app-nav');
  nav.innerHTML = '';

  const currentRoute = getCurrentRoute();

  LEARN_TABS.forEach(tab => {
    const item = document.createElement('div');
    item.className = 'nav-item';
    if (currentRoute === tab.route) item.classList.add('active');

    item.textContent = `${tab.key}. ${tab.label}`;
    item.onclick = () => navigate(tab.route);
    nav.appendChild(item);
  });
}
