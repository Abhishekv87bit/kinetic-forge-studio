// Footer progress display: XP, streak, stage

import { getProfile } from '../state.js';
import { getProject } from '../state.js';
import { getPatterns } from '../state.js';
import { getMode } from './mode-toggle.js';

export function updateProgressBar() {
  const profile = getProfile();
  if (!profile) return;

  document.getElementById('xp-display').textContent = `XP: ${profile.xp.total}`;
  document.getElementById('streak-display').textContent = `Streak: ${profile.streak.currentDays}d`;

  const stageDisplay = document.getElementById('stage-display');
  const mode = getMode();

  if (mode === 'build') {
    const project = getProject();
    if (project) {
      const stageNames = ['discover', 'animate', 'mechanize', 'simulate', 'build', 'iterate'];
      const currentIdx = stageNames.indexOf(project.currentStage) + 1;
      stageDisplay.textContent = `${project.name} | Stage ${currentIdx}/6`;
    } else {
      stageDisplay.textContent = 'No project selected';
    }
  } else if (mode === 'experiment') {
    const patterns = getPatterns();
    stageDisplay.textContent = `Experiment Mode | ${patterns.length} patterns saved`;
  } else {
    const tasks = profile.journey.totalTasksCompleted;
    stageDisplay.textContent = `Learn Mode | ${tasks} tasks completed`;
  }
}
