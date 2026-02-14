// Gamification: XP, streaks, skill levels

import { getProfile, saveProfile } from './state.js';
import { showToast } from './toast.js';
import { updateProgressBar } from './components/progress-bar.js';

const XP_VALUES = {
  'task-complete': 10,
  'task-first-try': 5,
  'daily-complete': 25,
  'gate-discover': 25,
  'gate-animate': 30,
  'gate-mechanize': 50,
  'gate-simulate': 40,
  'gate-build': 35,
  'gate-iterate': 20,
  'first-project': 100,
  'first-iteration': 50,
  'streak-3': 15,
  'streak-7': 30,
  'streak-14': 60,
  'streak-30': 150
};

const SKILL_THRESHOLDS = [0, 3, 8, 15, 25, 40]; // tasks needed for each level 0-5

export function getSkillLevel(taskCount) {
  for (let i = SKILL_THRESHOLDS.length - 1; i >= 0; i--) {
    if (taskCount >= SKILL_THRESHOLDS[i]) return i;
  }
  return 0;
}

export async function awardXP(action, stageId = null, skillTag = null) {
  const profile = getProfile();
  const amount = XP_VALUES[action] || 0;
  if (amount === 0) return;

  profile.xp.total += amount;
  if (stageId && profile.xp.byStage[stageId] !== undefined) {
    profile.xp.byStage[stageId] += amount;
  }

  showToast(`+${amount} XP`, 'success', 2000);

  // Check streak milestones
  const streak = profile.streak.currentDays;
  const milestones = [3, 7, 14, 30];
  for (const m of milestones) {
    if (streak === m) {
      const bonus = XP_VALUES[`streak-${m}`] || 0;
      if (bonus > 0) {
        profile.xp.total += bonus;
        showToast(`${m}-day streak! +${bonus} XP bonus`, 'success', 3000);
      }
    }
  }

  await saveProfile();
  updateProgressBar();
}

export async function recordTaskCompletion(skillTag) {
  const profile = getProfile();
  profile.journey.totalTasksCompleted++;

  // Update skill level
  if (skillTag && profile.journey.skillLevels[skillTag] !== undefined) {
    // We track by task count in task-history; skill levels derived from that
    // This just increments the direct counter for display purposes
  }

  await saveProfile();
}

export async function recordGatePass(stageId) {
  await awardXP(`gate-${stageId}`, stageId);
  const profile = getProfile();

  if (!profile.journey.stagesCompleted.includes(stageId)) {
    profile.journey.stagesCompleted.push(stageId);
  }

  // First project completion check
  if (stageId === 'iterate' && profile.journey.totalProjectsCompleted === 0) {
    profile.journey.totalProjectsCompleted = 1;
    await awardXP('first-project');
  }

  await saveProfile();
}
