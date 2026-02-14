// Task/exercise engine — generates repetitive exercises with varying parameters

import { getTaskHistory, getProfile } from './state.js';

function randomChoice(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

const TASK_TEMPLATES = {
  // --- LEARN: Four-Bar Linkages ---
  'learn-fourbar-grashof': {
    stage: 'learn',
    skillTag: 'fourBar',
    difficulty: 'easy',
    title: (p) => `Find a Grashof-valid linkage (ground=${p.G}mm)`,
    description: 'Adjust link lengths until the crank can fully rotate',
    generateParams: () => ({ G: randomChoice([80, 100, 120]) }),
    xp: 15,
    repeatMax: 12
  },
  'learn-fourbar-coupler': {
    stage: 'learn',
    skillTag: 'fourBar',
    difficulty: 'medium',
    title: (p) => `Trace the coupler curve for ${p.feel} motion`,
    description: 'Explore how coupler point position changes the output path',
    generateParams: () => ({ feel: randomChoice(['gentle sway', 'figure-8', 'teardrop', 'looping']) }),
    xp: 20,
    repeatMax: 10
  },
  'learn-fourbar-swing': {
    stage: 'learn',
    skillTag: 'fourBar',
    difficulty: 'stretch',
    title: (p) => `Match ${p.swing} deg swing angle`,
    description: 'Given a target rocker swing, find the right link lengths',
    generateParams: () => ({ swing: randomChoice([15, 20, 25, 30, 35]) }),
    xp: 25,
    repeatMax: 10
  },

  // --- LEARN: Cams ---
  'learn-cam-dwell': {
    stage: 'learn',
    skillTag: 'cams',
    difficulty: 'easy',
    title: (p) => `Create a ${p.dwell} deg dwell cam`,
    description: 'Adjust dwell angle to create a pause in the follower motion',
    generateParams: () => ({ dwell: randomChoice([60, 90, 120, 150]) }),
    xp: 15,
    repeatMax: 10
  },
  'learn-cam-breathing': {
    stage: 'learn',
    skillTag: 'cams',
    difficulty: 'medium',
    title: (p) => `Design a breathing cam (${p.ratio} rise:fall)`,
    description: 'Create asymmetric rise/fall for organic motion',
    generateParams: () => ({ ratio: randomChoice(['2:1', '3:1', '3:2']) }),
    xp: 20,
    repeatMax: 8
  },

  // --- LEARN: Eccentric & Slider-Crank ---
  'learn-eccentric-stroke': {
    stage: 'learn',
    skillTag: 'eccentric',
    difficulty: 'easy',
    title: (p) => `Set stroke length to ${p.stroke}mm`,
    description: 'Control the stroke by adjusting crank radius',
    generateParams: () => ({ stroke: randomChoice([10, 15, 20, 30]) }),
    xp: 15,
    repeatMax: 10
  },
  'learn-eccentric-sway': {
    stage: 'learn',
    skillTag: 'eccentric',
    difficulty: 'medium',
    title: (p) => `Make a tree sway with ${p.amplitude}mm amplitude`,
    description: 'Use eccentric offset to create gentle swaying motion',
    generateParams: () => ({ amplitude: randomChoice([5, 8, 10, 15]) }),
    xp: 20,
    repeatMax: 8
  },

  // --- LEARN: Gears ---
  'learn-gear-ratio': {
    stage: 'learn',
    skillTag: 'gears',
    difficulty: 'medium',
    title: (p) => `Slow motor from ${p.inputRPM} to ${p.targetRPM} RPM`,
    description: 'Choose gear teeth to achieve the target speed reduction',
    generateParams: () => {
      const inputRPM = randomChoice([60, 100, 120]);
      const ratio = randomChoice([2, 3, 4, 5]);
      return { inputRPM, targetRPM: inputRPM / ratio, ratio };
    },
    xp: 20,
    repeatMax: 10
  },

  // --- LEARN: Physics & Friction ---
  'learn-friction-cascade': {
    stage: 'learn',
    skillTag: 'simulation',
    difficulty: 'medium',
    title: (p) => `Friction cascade: ${p.pulleys} pulleys`,
    description: 'Watch force decay through a Margolin-style pulley chain',
    generateParams: () => ({ pulleys: randomChoice([3, 5, 7, 9]) }),
    xp: 20,
    repeatMax: 8
  },

  // --- LEARN: Design Thinking ---
  'learn-scaling': {
    stage: 'learn',
    skillTag: 'designThinking',
    difficulty: 'easy',
    title: (p) => `Scale mechanism to fit ${p.width}x${p.height}mm box`,
    description: 'Proportionally resize a mechanism to fit a bounding box',
    generateParams: () => ({ width: randomChoice([50, 80, 100, 150]), height: randomChoice([50, 80, 100, 120]) }),
    xp: 15,
    repeatMax: 10
  },

  // --- MECHANIZE (four-bar) --- kept for Build Mode ---
  'mechanize-fourbar-design': {
    stage: 'mechanize',
    skillTag: 'fourBar',
    difficulty: 'stretch',
    title: (p) => `Design crank-rocker with ${p.swing} deg swing`,
    description: `Create a four-bar linkage with the target rocker swing angle`,
    generateParams: () => ({
      swing: randomChoice([10, 15, 18, 20, 25, 30, 35]),
      feel: randomChoice(['gentle sway', 'ocean wave', 'bird wing', 'nodding'])
    }),
    xp: 20,
    repeatMax: 15
  },
  'mechanize-grashof-check': {
    stage: 'mechanize',
    skillTag: 'fourBar',
    difficulty: 'medium',
    title: (p) => `Validate: G=${p.G} C=${p.C} Co=${p.Co} R=${p.R}`,
    description: 'Determine Grashof type and identify the fully-rotating link',
    generateParams: () => {
      const G = randomInt(80, 120);
      const C = randomInt(20, 40);
      const Co = randomInt(60, 100);
      const R = randomInt(50, 90);
      return { G, C, Co, R };
    },
    xp: 15,
    repeatMax: 12
  },

  // --- MECHANIZE (cams) ---
  'mechanize-cam-profile': {
    stage: 'mechanize',
    skillTag: 'cams',
    difficulty: 'stretch',
    title: (p) => `Draw cam: ${p.dwell} deg dwell, ${p.rise}mm rise`,
    description: 'Design a cam profile with specified dwell and rise',
    generateParams: () => ({
      dwell: randomChoice([60, 90, 120, 150]),
      rise: randomChoice([5, 8, 10, 15, 20])
    }),
    xp: 18,
    repeatMax: 10
  },

  // --- SIMULATE ---
  'simulate-friction-test': {
    stage: 'simulate',
    skillTag: 'simulation',
    difficulty: 'medium',
    title: (p) => `Friction test: ${p.pulleys} pulleys in series`,
    description: 'Calculate output force after friction cascade',
    generateParams: () => ({
      pulleys: randomChoice([3, 5, 7, 9, 12]),
      inputForce: randomChoice([1, 2, 5, 10])
    }),
    xp: 15,
    repeatMax: 8
  },

  // --- CREATIVE CODING (p5.js) ---
  'p5-breathing-wave': {
    stage: 'animate',
    skillTag: 'creativeCoding',
    difficulty: 'easy',
    title: () => 'Code a breathing wave in p5.js',
    description: 'Create an asymmetric sine wave that feels like slow breathing — fast inhale, slow exhale',
    generateParams: () => ({}),
    xp: 15,
    repeatMax: 3
  },
  'p5-four-bar-anim': {
    stage: 'animate',
    skillTag: 'creativeCoding',
    difficulty: 'medium',
    title: () => 'Animate a four-bar linkage in p5.js',
    description: 'Code a four-bar linkage with rotating crank, trace the coupler curve, display Grashof check',
    generateParams: () => ({}),
    xp: 25,
    repeatMax: 3
  },
  'p5-3d-wave-field': {
    stage: 'animate',
    skillTag: 'creativeCoding',
    difficulty: 'stretch',
    title: () => 'Create a 3D wave field in p5 WEBGL',
    description: 'Code a Margolin 3D wave surface using p5.js WEBGL mode with multiple wave sources and interactive rotation',
    generateParams: () => ({}),
    xp: 35,
    repeatMax: 3
  }
};

// Suggestion algorithm
export function suggestTasks(mode, stage = null, count = 3) {
  const history = getTaskHistory();
  const profile = getProfile();
  const counts = history?.taskTypeCounts || {};
  const skills = profile?.journey?.skillLevels || {};

  // Filter templates by relevance
  let candidates = Object.entries(TASK_TEMPLATES);

  if (mode === 'build' && stage) {
    // In Build Mode, prioritize current stage tasks
    candidates = candidates.filter(([, t]) => t.stage === stage);
  }

  // Score candidates
  const scored = candidates.map(([type, template]) => {
    const done = counts[type] || 0;
    if (done >= template.repeatMax) return null; // Maxed out

    let score = 0;
    // Skill gap bonus: lower skill = higher score
    const skillLevel = skills[template.skillTag] || 0;
    score += (5 - skillLevel) * 10;

    // Variety bonus: less done = higher score
    score += Math.max(0, 10 - done) * 2;

    // Stage match bonus
    if (stage && template.stage === stage) score += 50;

    // Avoid recent repeats
    const recentTypes = (history?.tasks || []).slice(-3).map(t => t.type);
    if (recentTypes.includes(type)) score -= 30;

    return { type, template, score, params: template.generateParams() };
  }).filter(Boolean);

  // Sort by score descending, take top N
  scored.sort((a, b) => b.score - a.score);
  return scored.slice(0, count).map(s => ({
    type: s.type,
    title: s.template.title(s.params),
    description: s.template.description,
    difficulty: s.template.difficulty,
    params: s.params,
    xp: s.template.xp,
    skillTag: s.template.skillTag,
    stage: s.template.stage
  }));
}

// Generate daily tasks: 1 easy, 1 medium, 1 stretch
export function generateDailyTasks() {
  const all = suggestTasks('learn', null, 20);

  const easy = all.find(t => TASK_TEMPLATES[t.type]?.difficulty === 'easy');
  const medium = all.find(t => TASK_TEMPLATES[t.type]?.difficulty === 'medium');
  const stretch = all.find(t => TASK_TEMPLATES[t.type]?.difficulty === 'stretch');

  const tasks = [easy, medium, stretch].filter(Boolean);

  // If we don't have all 3 difficulties, fill from remaining
  while (tasks.length < 3 && all.length > tasks.length) {
    const next = all.find(t => !tasks.includes(t));
    if (next) tasks.push(next);
    else break;
  }

  return tasks.slice(0, 3);
}

export function getTaskTemplate(type) {
  return TASK_TEMPLATES[type] || null;
}
