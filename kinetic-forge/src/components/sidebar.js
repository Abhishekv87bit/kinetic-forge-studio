// Sidebar: context panel for suggestions, saved items, validation, Claude tips

export function renderSidebar(sections = []) {
  const sidebar = document.getElementById('sidebar');
  sidebar.innerHTML = '';

  for (const section of sections) {
    const wrapper = document.createElement('div');
    wrapper.className = 'mb';

    if (section.title) {
      const title = document.createElement('div');
      title.className = 'section-title';
      title.textContent = section.title;
      wrapper.appendChild(title);
    }

    if (section.html) {
      const content = document.createElement('div');
      content.innerHTML = section.html;
      wrapper.appendChild(content);
    }

    if (section.cards) {
      for (const card of section.cards) {
        const el = document.createElement('div');
        el.className = 'card';
        el.innerHTML = `
          <div class="card-title">${card.title}</div>
          <div class="card-desc">${card.description || ''}</div>
          ${card.xp ? `<div class="card-xp">+${card.xp} XP</div>` : ''}
        `;
        if (card.onClick) el.onclick = card.onClick;
        wrapper.appendChild(el);
      }
    }

    if (section.items) {
      for (const item of section.items) {
        const el = document.createElement('div');
        el.className = 'validation-item';
        const icon = item.status === 'pass' ? '&#10003;' : item.status === 'fail' ? '&#10007;' : '&#9679;';
        const cls = item.status === 'pass' ? 'check' : item.status === 'fail' ? 'fail' : 'pending';
        el.innerHTML = `<span class="${cls}">${icon}</span> <span>${item.label}</span>`;
        wrapper.appendChild(el);
      }
    }

    if (section.element) {
      wrapper.appendChild(section.element);
    }

    sidebar.appendChild(wrapper);
  }
}
