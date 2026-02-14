// Keyboard shortcut handler

const shortcuts = {};

export function registerShortcut(key, callback, description = '') {
  shortcuts[key.toLowerCase()] = { callback, description };
}

export function getShortcuts() {
  return { ...shortcuts };
}

export function initKeyboard() {
  document.addEventListener('keydown', (e) => {
    // Don't intercept when typing in input/textarea
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;

    const parts = [];
    if (e.ctrlKey) parts.push('ctrl');
    if (e.shiftKey) parts.push('shift');
    if (e.altKey) parts.push('alt');
    parts.push(e.key.toLowerCase());
    const combo = parts.join('+');

    const shortcut = shortcuts[combo];
    if (shortcut) {
      e.preventDefault();
      shortcut.callback();
    }
  });
}
