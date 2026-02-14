// Simple modal component

export function showModal({ title, content, actions = [] }) {
  const overlay = document.createElement('div');
  overlay.className = 'modal-overlay';

  const modal = document.createElement('div');
  modal.className = 'modal-content';

  if (title) {
    const h = document.createElement('div');
    h.className = 'modal-title';
    h.textContent = title;
    modal.appendChild(h);
  }

  if (typeof content === 'string') {
    const body = document.createElement('div');
    body.innerHTML = content;
    modal.appendChild(body);
  } else if (content instanceof HTMLElement) {
    modal.appendChild(content);
  }

  if (actions.length > 0) {
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'modal-actions';
    for (const action of actions) {
      const btn = document.createElement('button');
      btn.textContent = action.label;
      if (action.primary) btn.className = 'primary';
      btn.onclick = () => {
        overlay.remove();
        if (action.onClick) action.onClick();
      };
      actionsDiv.appendChild(btn);
    }
    modal.appendChild(actionsDiv);
  }

  overlay.appendChild(modal);
  overlay.onclick = (e) => {
    if (e.target === overlay) overlay.remove();
  };

  document.body.appendChild(overlay);
  return overlay;
}

export function promptInput(title, placeholder = '') {
  return new Promise((resolve) => {
    const input = document.createElement('input');
    input.type = 'text';
    input.placeholder = placeholder;
    input.style.width = '100%';
    input.style.marginTop = '8px';

    showModal({
      title,
      content: input,
      actions: [
        { label: 'Cancel', onClick: () => resolve(null) },
        { label: 'OK', primary: true, onClick: () => resolve(input.value.trim()) }
      ]
    });

    setTimeout(() => input.focus(), 50);
    input.onkeydown = (e) => {
      if (e.key === 'Enter') {
        document.querySelector('.modal-overlay')?.remove();
        resolve(input.value.trim());
      }
    };
  });
}
