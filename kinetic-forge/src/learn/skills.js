// Learn Mode: Skills — skill tree / progress view with mastery levels

import { getProfile } from '../state.js';
import { getTaskHistory } from '../state.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { getSkillLevel } from '../xp.js';
import { renderResourceLinksHTML } from '../components/resource-links.js';
import { createGuidancePanel } from '../components/guidance.js';

// Map skill keys to resource contexts
const SKILL_RESOURCE_MAP = {
  fourBar: 'skills-fourBar',
  cams: 'skills-cams',
  gears: 'skills-gears',
  eccentric: 'skills-eccentric',
  simulation: 'skills-simulation',
  designThinking: 'skills-designThinking'
};

const MASTERY_LABELS = ['Not Started', 'Attempted', 'Familiar', 'Proficient', 'Mastered', 'Expert'];

const SKILL_META = {
  fourBar: { label: 'Four-Bar Linkages', color: '#66bb6a', description: 'Grashof condition, transmission angle, coupler curves' },
  cams: { label: 'Cams & Profiles', color: '#ffa726', description: 'Cam design, dwell-rise-fall, pressure angle' },
  gears: { label: 'Gears & Trains', color: '#ef5350', description: 'Spur gears, ratios, backlash, module selection' },
  eccentric: { label: 'Eccentric & Slider-Crank', color: '#4fc3f7', description: 'Eccentric drives, stroke control, slider-crank, tree sway' },
  simulation: { label: 'Physics Simulation', color: '#ab47bc', description: 'Friction cascade, force analysis, lockup detection' },
  designThinking: { label: 'Design Thinking', color: '#78909c', description: 'Scaling, compactness, mechanism selection, bounding boxes' },
  creativeCoding: { label: 'Creative Coding (p5.js)', color: '#e91e63', description: 'Code visualizations, mechanism simulators, and portfolio pieces' }
};

// Map skills to curriculum tracks for progress display
const SKILL_CURRICULUM_MAP = {
  fourBar: ['10_KINETIC_MOTION_RECIPES.md', '15_WALL_CHEATSHEETS.md'],
  cams: ['10_KINETIC_MOTION_RECIPES.md', '05_BOOK_QUICK_REFERENCE.md'],
  gears: ['10_KINETIC_MOTION_RECIPES.md', '11_TOOL_DECISION_TREE.md'],
  eccentric: ['10_KINETIC_MOTION_RECIPES.md', '14_DESIGN_THINKING_FRAMEWORK.md'],
  simulation: ['09_AI_CAD_WORKFLOW.md', '04_FUSION360_LEARNING_GUIDE.md'],
  designThinking: ['14_DESIGN_THINKING_FRAMEWORK.md', '13_SIGNATURE_DISCOVERY_GUIDE.md'],
  creativeCoding: ['06_ONLINE_TOOLS_REFERENCE.md', '00_MASTER_LEARNING_PLAN.md']
};

export async function mount(container) {
  const profile = getProfile();
  const taskHistory = await getTaskHistory();
  const counts = taskHistory?.taskTypeCounts || {};
  const filesViewed = profile?.curriculum?.filesViewed || [];

  container.innerHTML = `
    <div class="section-title">Skill Progress</div>
    <div id="skill-grid" style="display:grid; grid-template-columns: 1fr 1fr; gap: 12px;"></div>
    <div class="section-title mt-lg">Curriculum Coverage</div>
    <div id="curriculum-progress" class="track-progress"></div>
    <div class="section-title mt-lg">Journey Stats</div>
    <div id="stats-panel"></div>
  `;

  const grid = document.getElementById('skill-grid');

  Object.entries(SKILL_META).forEach(([key, meta]) => {
    const level = profile?.journey?.skillLevels?.[key] || 0;
    const taskCount = Object.entries(counts)
      .filter(([type]) => type.includes(key.toLowerCase()) || type.includes(key))
      .reduce((sum, [, c]) => sum + c, 0);
    const computedLevel = getSkillLevel(taskCount);
    const masteryLabel = MASTERY_LABELS[Math.min(computedLevel, MASTERY_LABELS.length - 1)];

    const card = document.createElement('div');
    card.className = 'card';
    card.style.borderLeftColor = meta.color;
    card.style.borderLeftWidth = '3px';
    const resourceCtx = SKILL_RESOURCE_MAP[key];
    const resourceHtml = resourceCtx ? renderResourceLinksHTML(resourceCtx, { maxItems: 3, compact: true }) : '';
    card.innerHTML = `
      <div class="card-title" style="color:${meta.color}">${meta.label}</div>
      <div class="text-sm text-dim">${meta.description}</div>
      <div class="mt flex gap" style="align-items:center;">
        <div style="flex:1; height:6px; background:var(--bg); border-radius:3px; overflow:hidden;">
          <div style="width:${Math.min(100, computedLevel * 20)}%; height:100%; background:${meta.color}; border-radius:3px;"></div>
        </div>
        <span class="text-sm" style="color:${meta.color}">${masteryLabel}</span>
      </div>
      <div class="text-sm text-dim mt">${taskCount} exercises completed</div>
      ${resourceHtml ? `<div class="mt" style="border-top:1px solid var(--border);padding-top:6px;">${resourceHtml}</div>` : ''}
    `;
    grid.appendChild(card);
  });

  // Curriculum coverage per skill
  const currProgress = document.getElementById('curriculum-progress');
  Object.entries(SKILL_CURRICULUM_MAP).forEach(([skill, files]) => {
    const viewed = files.filter(f => filesViewed.includes(f)).length;
    const total = files.length;
    const pct = total > 0 ? Math.round((viewed / total) * 100) : 0;
    const meta = SKILL_META[skill];

    const el = document.createElement('div');
    el.className = 'card';
    el.style.padding = '8px 10px';
    el.innerHTML = `
      <div class="text-sm" style="color:${meta.color}; font-weight:600;">${meta.label}</div>
      <div style="height:4px; background:var(--bg); border-radius:2px; margin-top:4px; overflow:hidden;">
        <div style="width:${pct}%; height:100%; background:${meta.color}; border-radius:2px;"></div>
      </div>
      <div class="text-sm text-dim">${viewed}/${total} docs read</div>
    `;
    currProgress.appendChild(el);
  });

  // Stats
  const stats = document.getElementById('stats-panel');
  stats.innerHTML = `
    <div class="flex gap" style="flex-wrap:wrap;">
      <div class="card" style="flex:1; min-width:120px; text-align:center;">
        <div style="font-size:24px; color:var(--accent);">${profile?.xp?.total || 0}</div>
        <div class="text-sm text-dim">Total XP</div>
      </div>
      <div class="card" style="flex:1; min-width:120px; text-align:center;">
        <div style="font-size:24px; color:var(--success);">${profile?.streak?.currentDays || 0}</div>
        <div class="text-sm text-dim">Day Streak</div>
      </div>
      <div class="card" style="flex:1; min-width:120px; text-align:center;">
        <div style="font-size:24px; color:var(--warning);">${profile?.journey?.totalTasksCompleted || 0}</div>
        <div class="text-sm text-dim">Tasks Done</div>
      </div>
      <div class="card" style="flex:1; min-width:120px; text-align:center;">
        <div style="font-size:24px; color:var(--error);">${profile?.streak?.longestDays || 0}</div>
        <div class="text-sm text-dim">Best Streak</div>
      </div>
    </div>
  `;

  updateSidebar();
}

function updateSidebar() {
  const sections = [];

  sections.push({
    title: 'Mastery Levels',
    html: `<div class="text-sm text-dim" style="line-height:1.6;">
      <strong style="color:var(--text-dim)">Not Started</strong> — 0 exercises<br>
      <strong style="color:var(--text-dim)">Attempted</strong> — 3+ exercises<br>
      <strong style="color:var(--warning)">Familiar</strong> — 8+ exercises<br>
      <strong style="color:var(--warning)">Proficient</strong> — 15+ exercises<br>
      <strong style="color:var(--success)">Mastered</strong> — 25+ exercises<br>
      <strong style="color:var(--success)">Expert</strong> — 40+ exercises
    </div>`
  });

  // Guidance
  const guidance = createGuidancePanel('learn-skills');
  if (guidance) sections.push({ element: guidance });

  sections.push({ element: createClaudePanel(null) });
  renderSidebar(sections);
}

export function unmount() {}
