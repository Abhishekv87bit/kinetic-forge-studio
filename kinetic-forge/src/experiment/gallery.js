// Experiment Mode: Pattern Gallery — saved patterns + curated presets organized by category

import { loadPatterns, getPatterns, savePattern, deletePattern, createProject } from '../state.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { navigate } from '../router.js';
import { setMode } from '../components/mode-toggle.js';
import { showToast } from '../toast.js';
import { renderMultiContextLinks } from '../components/resource-links.js';

const PRESETS = {
  'Wave Patterns': [
    { name: 'Ocean Swell', type: 'wavelab', description: '3-wave superposition mimicking ocean surface',
      params: { waves: [{ A: 2, k: 1, phi: 0 }, { A: 1, k: 2.3, phi: 0.5 }, { A: 0.5, k: 3.7, phi: 1.2 }] },
      tags: ['ocean', 'margolin', 'wave'] },
    { name: 'Interference Pattern', type: 'wavelab', description: 'Two nearly-equal frequencies create beats',
      params: { waves: [{ A: 2, k: 2, phi: 0 }, { A: 2, k: 2.1, phi: 0 }, { A: 0, k: 1, phi: 0 }] },
      tags: ['beats', 'interference'] },
    { name: 'Breath Cycle', type: 'wavelab', description: 'Asymmetric wave — slow inhale, quick exhale (3:1)',
      params: { waves: [{ A: 3, k: 1, phi: 0 }, { A: 1, k: 3, phi: 1.5 }, { A: 0.5, k: 5, phi: 0.8 }] },
      tags: ['breath', 'organic'] },
    { name: 'Gentle Ripple', type: 'wavelab', description: 'Small, fast waves — pond after a stone drops',
      params: { waves: [{ A: 0.8, k: 3, phi: 0 }, { A: 0.5, k: 4.5, phi: 1 }, { A: 0.3, k: 6, phi: 2 }] },
      tags: ['ripple', 'water'] },
  ],
  'Mechanism Recipes': [
    { name: 'Gentle Tree Sway', type: 'mechanisms', description: 'Four-bar 100:15:85:95 at 2-5 RPM — slow, hypnotic side-to-side',
      params: { ratio: '100:15:85:95', rpm: '2-5' }, tags: ['tree', 'nature'], externalUrl: 'https://motiongen.io/' },
    { name: 'Rolling Ocean Wave', type: 'mechanisms', description: 'Four-bar 100:25:90:80 at 3-8 RPM — continuous flowing motion',
      params: { ratio: '100:25:90:80', rpm: '3-8' }, tags: ['wave', 'ocean'], externalUrl: 'https://motiongen.io/' },
    { name: 'Bird Wing Flap', type: 'mechanisms', description: 'Four-bar 80:20:70:85 at 1-3 RPM — majestic, slow beats',
      params: { ratio: '80:20:70:85', rpm: '1-3' }, tags: ['bird', 'wing'], externalUrl: 'https://motiongen.io/' },
    { name: 'Flower Bloom', type: 'mechanisms', description: 'Cam with 120 deg dwell at 1-3 RPM — gentle open-close',
      params: { type: 'cam', dwell: 120, rpm: '1-3' }, tags: ['flower', 'breathing'], externalUrl: 'http://507movements.com/' },
  ],
  'Classic Curves': [
    { name: 'Lissajous 3:2', type: 'patterns', description: 'Two perpendicular oscillations at ratio 3:2',
      params: { preset: 'lissajous', p: 3, q: 2, delta: 1.57 }, tags: ['classic', 'curve'] },
    { name: '5-Petal Rose', type: 'patterns', description: 'Polar curve with 5-fold symmetry — appears in cam profiles',
      params: { preset: 'rose', n: 5, radius: 3 }, tags: ['flower', 'radial'] },
    { name: 'Spirograph', type: 'patterns', description: 'Gear-traced curve — hypotrochoid pattern',
      params: { preset: 'spirograph', R: 4, r: 1, d: 2 }, tags: ['gear', 'spirograph'] },
    { name: 'Butterfly Curve', type: 'patterns', description: 'Complex organic curve with bilateral symmetry',
      params: { preset: 'butterfly' }, tags: ['organic'] },
    { name: 'Fourier Square Wave', type: 'patterns', description: 'How harmonics build a square wave',
      params: { preset: 'fourier', harmonics: 10, waveType: 'square' }, tags: ['fourier'] },
  ],
  '3D Surfaces': [
    { name: 'Ripple Tank', type: 'waves3d', description: '2 point sources creating interference on a 3D surface',
      params: { amplitude: 1.5, freqX: 2, freqY: 2, sources: 2, phaseOffset: 1.5, speed: 1 }, tags: ['3d', 'interference'] },
    { name: 'Margolin Grid', type: 'waves3d', description: '3 wave sources at 120 degrees — Margolin-style wave surface',
      params: { amplitude: 2, freqX: 1.5, freqY: 1.5, sources: 3, phaseOffset: 2.09, speed: 0.8 }, tags: ['3d', 'margolin'] },
  ],
};

export async function mount(container) {
  await loadPatterns();
  render(container);
}

function render(container) {
  const patterns = getPatterns();

  let categorySections = '';
  Object.entries(PRESETS).forEach(([category, presets]) => {
    categorySections += `
      <div>
        <div class="section-title">${category.toUpperCase()}</div>
        <div class="pattern-grid" id="grid-${category.replace(/\s+/g, '-').toLowerCase()}"></div>
      </div>
    `;
  });

  container.innerHTML = `
    <div class="flex-col gap-lg">
      ${categorySections}
      <div>
        <div class="section-title">YOUR SAVED PATTERNS</div>
        <div class="pattern-grid" id="saved-grid"></div>
        ${patterns.length === 0 ? '<p class="text-sm text-dim">No saved patterns yet. Use the Playground to explore and save patterns here.</p>' : ''}
      </div>
    </div>
  `;

  // Render preset categories
  Object.entries(PRESETS).forEach(([category, presets]) => {
    const gridId = `grid-${category.replace(/\s+/g, '-').toLowerCase()}`;
    const grid = document.getElementById(gridId);
    if (grid) {
      presets.forEach(preset => grid.appendChild(createPatternCard(preset, false)));
    }
  });

  // Render saved patterns
  const savedGrid = document.getElementById('saved-grid');
  patterns.forEach(pat => {
    savedGrid.appendChild(createPatternCard(pat, true));
  });

  updateSidebar();
}

function createPatternCard(pattern, isSaved) {
  const card = document.createElement('div');
  card.className = 'pattern-card';

  const typeBadge = `<span class="type-badge">${pattern.type}</span>`;
  const desc = pattern.description || pattern.expression || '';
  const tags = (pattern.tags || []).map(t => `<span class="text-dim text-sm">#${t}</span>`).join(' ');

  // For mechanism recipes, show the ratio prominently
  let detailLine = '';
  if (pattern.type === 'mechanisms' && pattern.params?.ratio) {
    detailLine = `<div class="mono text-sm" style="color:var(--accent);margin-bottom:4px;">${pattern.params.ratio} @ ${pattern.params.rpm} RPM</div>`;
  } else if (pattern.type === 'wavelab' && pattern.params?.waves) {
    const waveCount = pattern.params.waves.filter(w => w.A > 0).length;
    detailLine = `<div class="mono text-sm text-dim" style="margin-bottom:4px;">${waveCount} waves superposed</div>`;
  }

  card.innerHTML = `
    <div class="flex gap" style="align-items:center;margin-bottom:6px;">
      <strong class="text-sm">${pattern.name}</strong>
      ${typeBadge}
    </div>
    <div class="text-sm text-dim" style="margin-bottom:4px;">${desc}</div>
    ${detailLine}
    <div style="margin-bottom:6px;">${tags}</div>
    <div class="flex gap">
      ${pattern.type === 'mechanisms' && pattern.externalUrl
        ? `<a href="${pattern.externalUrl}" target="_blank" rel="noopener" class="text-sm" style="padding:3px 8px;font-size:10px;text-decoration:none;border:1px solid var(--accent);border-radius:4px;color:var(--accent);">Try in Tool</a>`
        : `<button class="load-btn text-sm" style="padding:3px 8px;font-size:10px;">Load</button>`
      }
      ${isSaved ? '<button class="bridge-btn text-sm" style="padding:3px 8px;font-size:10px;">Build</button>' : ''}
      ${isSaved ? '<button class="delete-btn text-sm" style="padding:3px 8px;font-size:10px;border-color:var(--error);color:var(--error);">Delete</button>' : ''}
    </div>
  `;

  const loadBtn = card.querySelector('.load-btn');
  if (loadBtn) {
    loadBtn.onclick = (e) => {
      e.stopPropagation();
      loadInPlayground(pattern);
    };
  }

  if (isSaved) {
    card.querySelector('.bridge-btn').onclick = (e) => {
      e.stopPropagation();
      bridgeToBuild(pattern);
    };
    card.querySelector('.delete-btn').onclick = async (e) => {
      e.stopPropagation();
      await deletePattern(pattern.id);
      render(document.getElementById('workspace'));
      showToast('Pattern deleted', 'info');
    };
  }

  return card;
}

function loadInPlayground(pattern) {
  sessionStorage.setItem('exp-load-pattern', JSON.stringify(pattern));
  navigate('exp-playground');
  showToast(`Loading "${pattern.name}" in Playground`, 'info');
}

async function bridgeToBuild(pattern) {
  const project = await createProject(pattern.name + ' — Build');
  const expr = pattern.expression || pattern.description || JSON.stringify(pattern.params);
  project.stages.discover.savedEquations.push({
    id: 'eq-' + Date.now().toString(36),
    expression: expr,
    tool: pattern.type,
    savedAt: new Date().toISOString()
  });
  setMode('build');
  showToast(`Created project from "${pattern.name}"`, 'success');
}

function updateSidebar() {
  const patterns = getPatterns();
  const sections = [];

  const presetCount = Object.values(PRESETS).reduce((sum, arr) => sum + arr.length, 0);
  sections.push({
    title: 'Gallery Stats',
    html: `
      <p class="text-sm text-dim">
        <strong>${presetCount}</strong> presets across ${Object.keys(PRESETS).length} categories<br>
        <strong>${patterns.length}</strong> saved patterns
      </p>
    `
  });

  sections.push({
    title: 'Quick Tips',
    html: `
      <p class="text-sm text-dim">
        <strong>Load:</strong> Opens pattern in Playground with sliders<br>
        <strong>Try in Tool:</strong> Opens the external mechanism design tool<br>
        <strong>Build:</strong> Creates a new Build project with the config<br>
        <strong>Explore:</strong> Use Playground to discover new patterns, then save here
      </p>
    `
  });

  const extHtml = renderMultiContextLinks(
    ['playground-wavelab', 'playground-patterns', 'playground-3d'],
    { maxItems: 4, compact: true }
  );
  if (extHtml) {
    sections.push({ title: 'Learn More', html: extHtml });
  }

  sections.push({ element: createClaudePanel(null) });
  renderSidebar(sections);
}

export function unmount() {}
