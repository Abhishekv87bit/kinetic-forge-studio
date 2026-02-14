// Learn Mode: Dashboard — daily tasks, streak, smart recommendations, curriculum progress

import { getProfile, saveProfile, getTaskHistory, updateProfile } from '../state.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { generateDailyTasks, getTaskTemplate } from '../tasks.js';
import { awardXP, recordTaskCompletion, getSkillLevel } from '../xp.js';
import { addTaskCompletion } from '../state.js';
import { navigate } from '../router.js';
import { showToast } from '../toast.js';
import { createGuidancePanel } from '../components/guidance.js';
import { createResourceSection } from '../components/resource-links.js';

// Skill → curriculum track mapping for recommendations
const SKILL_TRACK_MAP = {
  fourBar: { file: '14_DESIGN_THINKING_FRAMEWORK.md', label: 'Design Thinking Framework' },
  cams: { file: '10_KINETIC_MOTION_RECIPES.md', label: 'Kinetic Motion Recipes' },
  gears: { file: '15_WALL_CHEATSHEETS.md', label: 'Wall Cheatsheets' },
  eccentric: { file: '10_KINETIC_MOTION_RECIPES.md', label: 'Kinetic Motion Recipes' },
  simulation: { file: '06_ONLINE_TOOLS_REFERENCE.md', label: 'Online Tools Reference' },
  designThinking: { file: '14_DESIGN_THINKING_FRAMEWORK.md', label: 'Design Thinking Framework' }
};

// Track definitions for progress bars
const CURRICULUM_TRACKS = [
  { id: 'foundations', label: 'Foundations', color: '#4fc3f7', files: ['00_MASTER_LEARNING_PLAN.md', '14_DESIGN_THINKING_FRAMEWORK.md', '13_SIGNATURE_DISCOVERY_GUIDE.md'] },
  { id: 'hands-on', label: 'Hands-On', color: '#66bb6a', files: ['02_CARDBOARD_PROTOTYPING_CURRICULUM.md', '01_DAUGHTER_AUTOMATA_PROJECTS.md'] },
  { id: 'digital', label: 'Digital Tools', color: '#ffa726', files: ['04_FUSION360_LEARNING_GUIDE.md', '09_AI_CAD_WORKFLOW.md', '03_GITHUB_LIBRARY_SETUP_GUIDE.md', '11_TOOL_DECISION_TREE.md'] },
  { id: 'mechanisms', label: 'Mechanisms', color: '#ef5350', files: ['10_KINETIC_MOTION_RECIPES.md', '15_WALL_CHEATSHEETS.md', '05_BOOK_QUICK_REFERENCE.md'] },
  { id: 'resources', label: 'Resources', color: '#ab47bc', files: ['06_ONLINE_TOOLS_REFERENCE.md', '07_GITHUB_LIBRARIES.md', '08_FREE_PLANS_INDEX.md', '12_COMMUNITY_RESOURCES.md'] },
  { id: 'history', label: 'History', color: '#78909c', files: ['16_DESIGN_HISTORY_INDEX.md', '14_EXPERIMENT_LOG.md', 'SESSION_LOG.md'] }
];

export async function mount(container) {
  const profile = getProfile();

  // Check if daily tasks need regeneration
  const today = new Date().toISOString().split('T')[0];
  if (!profile.dailyTasks || profile.dailyTasks.date !== today) {
    const tasks = generateDailyTasks();
    profile.dailyTasks = {
      date: today,
      tasks: tasks.map((t, i) => ({ ...t, id: `daily-${i}`, completed: false })),
      completedCount: 0,
      dailyBonusAwarded: false
    };
    await saveProfile();
  }

  render(container);
}

function render(container) {
  const profile = getProfile();
  const daily = profile.dailyTasks || { tasks: [], completedCount: 0 };
  const skills = profile.journey?.skillLevels || {};

  // Find weakest skill for recommendation
  const weakest = Object.entries(skills).reduce((min, [k, v]) => v < min[1] ? [k, v] : min, ['waves', 999]);
  const weakSkill = weakest[0];
  const recTrack = SKILL_TRACK_MAP[weakSkill] || SKILL_TRACK_MAP.waves;

  const allCompleted = daily.tasks.length > 0 && daily.tasks.every(t => t.completed);

  container.innerHTML = `
    <div class="flex-col gap-lg">
      <!-- Stats Banner -->
      <div class="streak-display">
        <div style="text-align:center;">
          <div class="streak-number">${profile.streak?.currentDays || 0}</div>
          <div class="text-dim text-sm">Day Streak</div>
        </div>
        <div style="text-align:center;">
          <div class="streak-number" style="color:var(--success)">${profile.xp?.total || 0}</div>
          <div class="text-dim text-sm">Total XP</div>
        </div>
        <div style="text-align:center;">
          <div class="streak-number" style="color:var(--warning)">${profile.journey?.totalTasksCompleted || 0}</div>
          <div class="text-dim text-sm">Tasks Done</div>
        </div>
        ${profile.streak?.freezesAvailable > 0 ? `
          <div style="text-align:center;">
            <div class="text-sm" style="color:var(--accent);">&#10052;</div>
            <div class="text-dim text-sm">${profile.streak.freezesAvailable} freeze</div>
          </div>
        ` : ''}
      </div>

      <!-- Daily Tasks -->
      <div>
        <div class="section-title">TODAY'S TASKS</div>
        <div class="flex-col gap" id="daily-tasks">
          ${daily.tasks.map((t, i) => `
            <div class="daily-task card ${t.completed ? 'completed' : ''}" data-idx="${i}">
              <div style="flex:1;">
                <div class="flex gap" style="align-items:center;margin-bottom:4px;">
                  <span class="difficulty-badge ${t.difficulty || 'easy'}">${(t.difficulty || 'easy').toUpperCase()}</span>
                  <strong class="text-sm">${t.title}</strong>
                </div>
                <div class="text-sm text-dim">${t.description}</div>
              </div>
              <div style="text-align:right;">
                <div class="text-accent text-sm">+${t.xp} XP</div>
                ${t.completed
                  ? '<span style="color:var(--success);font-size:18px;">&#10003;</span>'
                  : `<button class="complete-daily primary text-sm" data-idx="${i}" style="padding:4px 10px;">Complete</button>`}
              </div>
            </div>
          `).join('')}
        </div>
        ${allCompleted && !daily.dailyBonusAwarded ? `
          <div class="card" style="border-color:var(--success);text-align:center;padding:12px;margin-top:8px;">
            <strong style="color:var(--success);">All tasks complete! +25 XP daily bonus</strong>
          </div>
        ` : ''}
        ${daily.tasks.length > 0 ? `
          <div class="text-sm text-dim mt" style="text-align:center;">
            Daily bonus: +25 XP for completing all 3 tasks
          </div>
        ` : ''}
      </div>

      <!-- Smart Recommendation -->
      <div>
        <div class="section-title">WHAT TO LEARN NEXT</div>
        <div class="card" style="cursor:pointer;" id="rec-card">
          <div class="text-sm text-dim" style="margin-bottom:4px;">Your weakest skill: <strong style="color:var(--warning);">${weakSkill}</strong> (Level ${getSkillLevel(skills[weakSkill] || 0)})</div>
          <div class="text-sm">Open: <span class="text-accent" style="cursor:pointer;">${recTrack.label}</span></div>
        </div>
      </div>

      <!-- Curriculum Progress -->
      <div>
        <div class="section-title">CURRICULUM PROGRESS</div>
        <div class="track-progress">
          ${CURRICULUM_TRACKS.map(track => {
            const viewed = (profile.curriculum?.filesViewed || []).filter(f => track.files.includes(f)).length;
            const total = track.files.length;
            const pct = total > 0 ? Math.round((viewed / total) * 100) : 0;
            return `
              <div class="flex gap" style="align-items:center;">
                <span class="text-sm" style="width:90px;color:${track.color};">${track.label}</span>
                <div style="flex:1;height:6px;background:var(--bg);border-radius:3px;overflow:hidden;">
                  <div style="width:${pct}%;height:100%;background:${track.color};border-radius:3px;transition:width 0.3s;"></div>
                </div>
                <span class="text-sm text-dim" style="width:35px;text-align:right;">${pct}%</span>
              </div>
            `;
          }).join('')}
        </div>
      </div>
    </div>
  `;

  // Attach event listeners
  container.querySelectorAll('.complete-daily').forEach(btn => {
    btn.onclick = async (e) => {
      e.stopPropagation();
      const idx = parseInt(btn.dataset.idx);
      await completeDailyTask(idx);
      render(container);
    };
  });

  document.getElementById('rec-card')?.addEventListener('click', () => {
    // Navigate to curriculum and auto-open the recommended file
    sessionStorage.setItem('curriculum-open-file', recTrack.file);
    navigate('learn-curriculum');
  });

  updateSidebar();
}

async function completeDailyTask(idx) {
  const profile = getProfile();
  const daily = profile.dailyTasks;
  if (!daily || !daily.tasks[idx] || daily.tasks[idx].completed) return;

  daily.tasks[idx].completed = true;
  daily.completedCount++;

  // Award XP
  const task = daily.tasks[idx];
  await awardXP('task-complete', task.stage, task.skillTag);
  await recordTaskCompletion(task.skillTag);
  await addTaskCompletion({
    type: task.type,
    title: task.title,
    params: task.params,
    completedAt: new Date().toISOString()
  });

  // Check if all daily tasks completed
  if (daily.tasks.every(t => t.completed) && !daily.dailyBonusAwarded) {
    daily.dailyBonusAwarded = true;
    await awardXP('daily-complete');
    showToast('All daily tasks complete! +25 XP bonus', 'success', 3000);
  }

  await saveProfile();
}

function updateSidebar() {
  const profile = getProfile();
  const sections = [];

  // Streak milestones
  const streak = profile.streak?.currentDays || 0;
  const milestones = [3, 7, 14, 30, 66];
  sections.push({
    title: 'Streak Milestones',
    html: `
      <div class="flex-col" style="gap:4px;">
        ${milestones.map(m => {
          const reached = streak >= m;
          return `<div class="text-sm" style="color:${reached ? 'var(--success)' : 'var(--text-dim)'};">
            ${reached ? '&#10003;' : '&#9675;'} ${m} days ${m === 66 ? '(habit formed!)' : m === 3 ? '(+15 XP)' : m === 7 ? '(+30 XP)' : m === 14 ? '(+60 XP)' : m === 30 ? '(+150 XP)' : ''}
          </div>`;
        }).join('')}
      </div>
    `
  });

  // Streak freeze status
  const freezes = profile.streak?.freezesAvailable || 0;
  sections.push({
    title: 'Streak Freeze',
    html: `<p class="text-sm text-dim">${freezes > 0 ? `You have ${freezes} freeze available. Miss a day without losing your streak.` : 'No freezes available. Keep your streak going!'}</p>`
  });

  // Guidance
  const guidance = createGuidancePanel('learn-dashboard');
  if (guidance) sections.push({ element: guidance });

  // External resource links
  const resourceSection = createResourceSection('Quick Links', 'dashboard', { maxItems: 5, compact: true });
  if (resourceSection) sections.push(resourceSection);

  sections.push({ element: createClaudePanel(null) });
  renderSidebar(sections);
}

export function unmount() {}
