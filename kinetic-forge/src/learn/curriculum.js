// Learn Mode: Curriculum Browser — browse 18 learning files organized by track

import { loadLibraries } from '../components/tool-loader.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { getProfile, saveProfile } from '../state.js';
import { createResourceSection } from '../components/resource-links.js';

// Map track IDs to resource contexts
const TRACK_RESOURCE_MAP = {
  'foundations': 'curriculum-foundations',
  'hands-on': 'curriculum-handson',
  'digital': 'curriculum-digital',
  'mechanisms': 'curriculum-mechanisms',
  'resources': 'curriculum-resources',
  'history': 'curriculum-history'
};

const TRACKS = [
  { id: 'foundations', label: 'Foundations', icon: '\u{1F9ED}', color: '#4fc3f7',
    files: ['00_MASTER_LEARNING_PLAN.md', '14_DESIGN_THINKING_FRAMEWORK.md', '13_SIGNATURE_DISCOVERY_GUIDE.md'],
    description: 'Core philosophy, design thinking, artistic voice' },
  { id: 'hands-on', label: 'Hands-On Making', icon: '\u2702\uFE0F', color: '#66bb6a',
    files: ['02_CARDBOARD_PROTOTYPING_CURRICULUM.md', '01_DAUGHTER_AUTOMATA_PROJECTS.md'],
    description: 'Cardboard prototyping, family projects' },
  { id: 'digital', label: 'Digital Tools', icon: '\u{1F5A5}\uFE0F', color: '#ffa726',
    files: ['04_FUSION360_LEARNING_GUIDE.md', '09_AI_CAD_WORKFLOW.md', '03_GITHUB_LIBRARY_SETUP_GUIDE.md', '11_TOOL_DECISION_TREE.md'],
    description: 'Fusion 360 levels, AI workflow, tool selection' },
  { id: 'mechanisms', label: 'Mechanisms & Motion', icon: '\u2699\uFE0F', color: '#ef5350',
    files: ['10_KINETIC_MOTION_RECIPES.md', '15_WALL_CHEATSHEETS.md', '05_BOOK_QUICK_REFERENCE.md'],
    description: 'Motion recipes, cheat sheets, book refs' },
  { id: 'resources', label: 'Community & Resources', icon: '\u{1F310}', color: '#ab47bc',
    files: ['06_ONLINE_TOOLS_REFERENCE.md', '07_GITHUB_LIBRARIES.md', '08_FREE_PLANS_INDEX.md', '12_COMMUNITY_RESOURCES.md'],
    description: 'Online tools, GitHub repos, plans, community' },
  { id: 'history', label: 'Design History', icon: '\u{1F4CB}', color: '#78909c',
    files: ['16_DESIGN_HISTORY_INDEX.md', '14_EXPERIMENT_LOG.md', 'SESSION_LOG.md'],
    description: 'Past designs, experiments, session log' }
];

let selectedTrack = null;
let selectedFile = null;
let fileContent = '';

export async function mount(container) {
  await loadLibraries(['marked']);

  // Check if we should auto-open a file (from dashboard recommendation)
  const autoOpen = sessionStorage.getItem('curriculum-open-file');
  if (autoOpen) {
    sessionStorage.removeItem('curriculum-open-file');
    // Find which track contains this file
    for (const track of TRACKS) {
      if (track.files.includes(autoOpen)) {
        selectedTrack = track;
        selectedFile = autoOpen;
        break;
      }
    }
    if (selectedFile) {
      await loadFileContent(selectedFile);
    }
  }

  render(container);
}

async function loadFileContent(filename) {
  try {
    const res = await fetch(`/api/knowledge/${filename}`);
    if (res.ok) {
      fileContent = await res.text();
      // Record view in profile
      const profile = getProfile();
      if (!profile.curriculum) profile.curriculum = { filesViewed: [], lastViewed: null };
      if (!profile.curriculum.filesViewed.includes(filename)) {
        profile.curriculum.filesViewed.push(filename);
      }
      profile.curriculum.lastViewed = filename;
      await saveProfile();
    } else {
      fileContent = `*File not found: ${filename}*`;
    }
  } catch (e) {
    fileContent = `*Error loading file: ${e.message}*`;
  }
}

function render(container) {
  const profile = getProfile();
  const viewed = profile.curriculum?.filesViewed || [];

  container.innerHTML = `
    <div class="flex gap-lg" style="height:100%;">
      <!-- Left: Track list -->
      <div id="track-panel" style="width:220px;flex-shrink:0;overflow-y:auto;">
        ${TRACKS.map(track => {
          const viewedCount = viewed.filter(f => track.files.includes(f)).length;
          const isSelected = selectedTrack?.id === track.id;
          return `
            <div class="track-card ${isSelected ? 'active' : ''}" data-track="${track.id}"
                 style="border-left-color:${track.color};${isSelected ? `background:var(--bg-elevated);` : ''}">
              <div class="flex gap" style="align-items:center;margin-bottom:4px;">
                <span>${track.icon}</span>
                <strong class="text-sm">${track.label}</strong>
              </div>
              <div class="text-sm text-dim" style="margin-bottom:4px;">${track.description}</div>
              <div style="height:4px;background:var(--bg);border-radius:2px;overflow:hidden;">
                <div style="width:${track.files.length > 0 ? Math.round((viewedCount / track.files.length) * 100) : 0}%;height:100%;background:${track.color};border-radius:2px;"></div>
              </div>
              <div class="text-sm text-dim" style="margin-top:2px;">${viewedCount}/${track.files.length} viewed</div>
            </div>
          `;
        }).join('')}
      </div>

      <!-- Center: File list + content -->
      <div style="flex:1;overflow-y:auto;" id="content-panel">
        ${selectedTrack ? renderTrackContent(viewed) : renderWelcome()}
      </div>
    </div>
  `;

  // Attach track click handlers
  container.querySelectorAll('.track-card').forEach(card => {
    card.onclick = () => {
      const trackId = card.dataset.track;
      selectedTrack = TRACKS.find(t => t.id === trackId);
      selectedFile = null;
      fileContent = '';
      render(container);
    };
  });

  // Attach file click handlers
  container.querySelectorAll('.file-item').forEach(item => {
    item.onclick = async () => {
      selectedFile = item.dataset.file;
      await loadFileContent(selectedFile);
      render(container);
    };
  });

  // Back button
  container.querySelector('#back-to-files')?.addEventListener('click', () => {
    selectedFile = null;
    fileContent = '';
    render(container);
  });

  updateSidebar();
}

function renderWelcome() {
  return `
    <div style="padding:24px;text-align:center;">
      <h2 style="color:var(--accent);margin-bottom:12px;">Curriculum Browser</h2>
      <p class="text-dim">Select a track on the left to browse your learning materials.</p>
      <p class="text-dim mt">18 documents organized into 6 learning tracks.</p>
    </div>
  `;
}

function renderTrackContent(viewed) {
  if (selectedFile && fileContent) {
    // Show file content
    const rendered = typeof marked !== 'undefined' && marked.parse
      ? marked.parse(fileContent)
      : `<pre style="white-space:pre-wrap;">${fileContent}</pre>`;

    return `
      <div style="margin-bottom:12px;">
        <button id="back-to-files" class="text-sm" style="padding:4px 10px;">&larr; Back to ${selectedTrack.label}</button>
        <span class="text-sm text-dim" style="margin-left:8px;">${selectedFile}</span>
      </div>
      <div class="markdown-content">${rendered}</div>
    `;
  }

  // Show file list for selected track
  return `
    <div style="padding:8px 0;">
      <div class="section-title" style="color:${selectedTrack.color};">${selectedTrack.icon} ${selectedTrack.label}</div>
      <p class="text-sm text-dim mb">${selectedTrack.description}</p>
      <div class="flex-col gap">
        ${selectedTrack.files.map(file => {
          const isViewed = viewed.includes(file);
          const displayName = file.replace(/^\d+_/, '').replace(/_/g, ' ').replace('.md', '');
          return `
            <div class="file-item card" data-file="${file}" style="cursor:pointer;">
              <div class="flex gap" style="align-items:center;">
                <span style="color:${isViewed ? 'var(--success)' : 'var(--text-dim)'};">${isViewed ? '\u2713' : '\u25CB'}</span>
                <div>
                  <div class="text-sm"><strong>${displayName}</strong></div>
                  <div class="text-sm text-dim">${file}</div>
                </div>
              </div>
            </div>
          `;
        }).join('')}
      </div>
    </div>
  `;
}

function updateSidebar() {
  const profile = getProfile();
  const viewed = profile.curriculum?.filesViewed || [];
  const totalFiles = TRACKS.reduce((sum, t) => sum + t.files.length, 0);

  const sections = [];

  sections.push({
    title: 'Progress',
    html: `
      <p class="text-sm text-dim">
        <strong>${viewed.length}</strong> / ${totalFiles} files viewed<br>
        ${selectedTrack ? `Current track: <span style="color:${selectedTrack.color};">${selectedTrack.label}</span>` : 'Select a track to start'}
      </p>
    `
  });

  if (selectedTrack) {
    const trackViewed = viewed.filter(f => selectedTrack.files.includes(f)).length;
    sections.push({
      title: 'Track Progress',
      html: `
        <div style="margin-bottom:8px;">
          <div style="height:6px;background:var(--bg);border-radius:3px;overflow:hidden;">
            <div style="width:${selectedTrack.files.length > 0 ? Math.round((trackViewed / selectedTrack.files.length) * 100) : 0}%;height:100%;background:${selectedTrack.color};border-radius:3px;"></div>
          </div>
          <div class="text-sm text-dim mt">${trackViewed}/${selectedTrack.files.length} files in this track</div>
        </div>
      `
    });
  }

  // External resources for selected track
  if (selectedTrack) {
    const ctx = TRACK_RESOURCE_MAP[selectedTrack.id];
    if (ctx) {
      const resourceSection = createResourceSection('Related Resources', ctx, { maxItems: 5 });
      if (resourceSection) sections.push(resourceSection);
    }
  }

  sections.push({ element: createClaudePanel(null) });
  renderSidebar(sections);
}

export function unmount() {
  selectedTrack = null;
  selectedFile = null;
  fileContent = '';
}
