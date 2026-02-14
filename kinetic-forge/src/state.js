// State manager — reads/writes JSON via fetch to Express server

let profile = null;
let currentProject = null;
let taskHistory = null;
let patterns = null;

// --- Profile ---
export async function loadProfile() {
  const res = await fetch('/api/state/profile');
  profile = await res.json();

  // Migration: add new fields for 3-module architecture
  if (!profile.curriculum) profile.curriculum = { filesViewed: [], lastViewed: null };
  if (!profile.dailyTasks) profile.dailyTasks = { date: null, tasks: [], completedCount: 0, dailyBonusAwarded: false };
  if (profile.streak && profile.streak.freezesAvailable === undefined) {
    profile.streak.freezesAvailable = 1;
    profile.streak.freezesUsed = 0;
  }

  // Migration: rename old skill keys to new ones (waves→removed, openscad→removed, add eccentric+designThinking)
  if (profile.journey?.skillLevels) {
    const sl = profile.journey.skillLevels;
    if (sl.waves !== undefined && sl.eccentric === undefined) {
      sl.eccentric = 0;
      delete sl.waves;
    }
    if (sl.openscad !== undefined && sl.designThinking === undefined) {
      sl.designThinking = 0;
      delete sl.openscad;
    }
    // Ensure all new keys exist
    if (sl.eccentric === undefined) sl.eccentric = 0;
    if (sl.designThinking === undefined) sl.designThinking = 0;
  }

  // Update streak on load
  const today = new Date().toISOString().split('T')[0];
  if (profile.streak.lastActiveDate) {
    const last = new Date(profile.streak.lastActiveDate);
    const now = new Date(today);
    const diffDays = Math.floor((now - last) / 86400000);
    if (diffDays === 1) {
      profile.streak.currentDays++;
      if (profile.streak.currentDays > profile.streak.longestDays) {
        profile.streak.longestDays = profile.streak.currentDays;
      }
    } else if (diffDays === 2 && profile.streak.freezesAvailable > 0) {
      // Streak freeze: missed 1 day but have a freeze available
      profile.streak.freezesAvailable--;
      profile.streak.freezesUsed++;
      profile.streak.currentDays++;
      if (profile.streak.currentDays > profile.streak.longestDays) {
        profile.streak.longestDays = profile.streak.currentDays;
      }
    } else if (diffDays > 1) {
      profile.streak.currentDays = 1;
    }
  } else {
    profile.streak.currentDays = 1;
  }
  profile.streak.lastActiveDate = today;
  profile.lastActive = new Date().toISOString();
  await saveProfile();
  return profile;
}

export function getProfile() {
  return profile;
}

export async function saveProfile() {
  await fetch('/api/state/profile', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(profile)
  });
}

export async function updateProfile(updates) {
  Object.assign(profile, updates);
  await saveProfile();
}

// --- Projects ---
export async function listProjects() {
  const res = await fetch('/api/state/projects');
  return res.json();
}

export async function loadProject(id) {
  const res = await fetch(`/api/state/project/${id}`);
  if (!res.ok) return null;
  currentProject = await res.json();
  return currentProject;
}

export function getProject() {
  return currentProject;
}

export async function saveProject(project) {
  project = project || currentProject;
  if (!project) return;
  await fetch(`/api/state/project/${project.id}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(project)
  });
}

export function createProjectData(name, sourcePattern = null) {
  const id = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') + '-' + Date.now().toString(36);
  return {
    version: 2,
    id,
    name,
    created: new Date().toISOString(),
    updated: new Date().toISOString(),
    currentStage: 'mechanize',
    sourcePattern: sourcePattern,
    stages: {
      mechanize: { status: 'in_progress', mechanism: null, recommendations: [] },
      simulate: { status: 'locked', results: null, calculations: {} },
      build: { status: 'locked', buildType: null, materials: {}, generatedCode: null, syntaxErrors: [] },
      iterate: { status: 'locked', testLogs: [] }
    },
    iterations: [],
    tags: [],
    notes: ''
  };
}

export async function createProject(name, sourcePattern = null) {
  currentProject = createProjectData(name, sourcePattern);
  await saveProject(currentProject);
  return currentProject;
}

// --- Task History ---
export async function loadTaskHistory() {
  const res = await fetch('/api/state/tasks');
  taskHistory = await res.json();
  return taskHistory;
}

export function getTaskHistory() {
  return taskHistory;
}

export async function addTaskCompletion(task) {
  if (!taskHistory) await loadTaskHistory();
  taskHistory.tasks.push(task);
  taskHistory.taskTypeCounts[task.type] = (taskHistory.taskTypeCounts[task.type] || 0) + 1;
  await fetch('/api/state/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(taskHistory)
  });
}

// --- Patterns (Experiment module) ---
export async function loadPatterns() {
  const res = await fetch('/api/state/patterns');
  const data = await res.json();
  patterns = data.patterns || [];
  return patterns;
}

export function getPatterns() {
  return patterns || [];
}

export async function savePattern(pattern) {
  if (!patterns) await loadPatterns();
  patterns.push(pattern);
  await fetch('/api/state/patterns', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ version: 1, patterns })
  });
}

export async function deletePattern(id) {
  if (!patterns) await loadPatterns();
  patterns = patterns.filter(p => p.id !== id);
  await fetch('/api/state/patterns', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ version: 1, patterns })
  });
}

// --- API Key ---
export async function checkApiKey() {
  const res = await fetch('/api/state/apikey');
  const data = await res.json();
  return data.configured;
}

export async function setApiKey(key) {
  await fetch('/api/state/apikey', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ key })
  });
}
