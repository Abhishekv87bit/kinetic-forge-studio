// Hash-based SPA router — zero dependencies

const routes = {};
let currentRoute = null;
let beforeNavigate = null;

export function registerRoute(hash, { mount, unmount, label }) {
  routes[hash] = { mount, unmount, label };
}

export function setBeforeNavigate(fn) {
  beforeNavigate = fn;
}

export function navigate(hash) {
  if (hash === currentRoute) return;

  // Before-navigate hook (for gate checks)
  if (beforeNavigate) {
    const allowed = beforeNavigate(currentRoute, hash);
    if (!allowed) return;
  }

  // Unmount current
  if (currentRoute && routes[currentRoute]?.unmount) {
    routes[currentRoute].unmount();
  }

  // Update hash without triggering hashchange
  currentRoute = hash;
  history.replaceState(null, '', `#${hash}`);

  // Mount new route
  const route = routes[hash];
  if (route?.mount) {
    const workspace = document.getElementById('workspace');
    workspace.innerHTML = '';
    route.mount(workspace);
  }

  // Emit custom event
  window.dispatchEvent(new CustomEvent('route-changed', { detail: { route: hash } }));
}

export function getCurrentRoute() {
  return currentRoute;
}

export function getRoutes() {
  return { ...routes };
}

export function initRouter() {
  // Handle browser back/forward
  window.addEventListener('hashchange', () => {
    const hash = location.hash.slice(1) || 'learn-dashboard';
    if (hash !== currentRoute) {
      navigate(hash);
    }
  });

  // Initial route
  const initial = location.hash.slice(1) || 'learn-dashboard';
  navigate(initial);
}
