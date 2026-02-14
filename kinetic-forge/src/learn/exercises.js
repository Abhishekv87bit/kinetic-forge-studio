// Learn Mode: Exercises — interactive mechanism explorations with tutorials

import { loadLibraries } from '../components/tool-loader.js';
import { renderSidebar } from '../components/sidebar.js';
import { awardXP, recordTaskCompletion, getSkillLevel } from '../xp.js';
import { addTaskCompletion, getProfile, saveProfile } from '../state.js';
import { showToast } from '../toast.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { renderMultiContextLinks } from '../components/resource-links.js';
import { checkGrashof } from '../gate.js';
import { createGuidancePanel } from '../components/guidance.js';
import { openInP5Editor, fourBarToP5Sketch, camToP5Sketch, frictionToP5Sketch, createP5Button } from '../components/p5-bridge.js';
import { getSketchById } from '../p5-sketches.js';

const MASTERY_LABELS = ['Not Started', 'Attempted', 'Familiar', 'Proficient', 'Mastered', 'Expert'];

// Interactive mechanism exercises — grouped by category
const MECHANISM_EXERCISES = [
  // --- Four-Bar Linkages ---
  {
    id: 'ex-grashof-visual', category: 'Four-Bar Linkages', skillTag: 'fourBar', difficulty: 'easy',
    title: 'Which Link Rotates?',
    description: 'Drag the sliders to change link lengths. Find a combination where the crank can spin a full 360 degrees (Grashof condition).',
    hint: 'The shortest + longest link must be <= sum of the other two. The shortest link must be the crank.',
    type: 'interactive-fourbar', successCondition: 'grashof', xp: 15,
    params: { ground: 100, crank: 50, coupler: 80, rocker: 90 },
    tutorialContexts: ['exercises-fourBar', 'skills-fourBar'],
    learnedFact: 'Grashof condition: S + L <= P + Q. When satisfied, the shortest link can rotate fully. This is the first check for any crank-rocker mechanism.'
  },
  {
    id: 'ex-match-motion', category: 'Four-Bar Linkages', skillTag: 'fourBar', difficulty: 'medium',
    title: 'Match the Motion: 20 deg Swing',
    description: 'Adjust link lengths to create a four-bar linkage where the rocker swings approximately 20 degrees. The rocker swing angle depends on the ratio of crank to ground length.',
    hint: 'A smaller crank relative to the ground gives a smaller swing angle. Try crank=15, ground=100.',
    type: 'interactive-fourbar', successCondition: 'swing-near-20', xp: 20,
    params: { ground: 100, crank: 30, coupler: 85, rocker: 90 },
    tutorialContexts: ['exercises-fourBar'],
    learnedFact: 'The rocker swing angle is primarily determined by the crank-to-ground ratio. Shorter crank = smaller swing. This is how you control the "gesture" of a motion.'
  },

  // --- Cams & Profiles ---
  {
    id: 'ex-cam-dwell', category: 'Cams & Profiles', skillTag: 'cams', difficulty: 'easy',
    title: 'Create a Pause (Dwell)',
    description: 'A cam controls when a puppet nods. Adjust the dwell angle to make the puppet pause at the top for longer before nodding down. Get the dwell above 90 degrees.',
    hint: 'Dwell angle = how many degrees of rotation the follower stays still. 90 deg = 1/4 of a rotation.',
    type: 'interactive-cam', successCondition: 'dwell-above-90', xp: 15,
    params: { baseRadius: 20, riseHeight: 10, dwellAngle: 60 },
    tutorialContexts: ['exercises-cams'],
    learnedFact: 'Dwell lets you create dramatic pauses in motion. 90 deg dwell = pause for 25% of each rotation. Margolin uses variable dwell to create breathing rhythms.'
  },
  {
    id: 'ex-cam-profile', category: 'Cams & Profiles', skillTag: 'cams', difficulty: 'medium',
    title: 'Design a Breathing Cam',
    description: 'Create a cam profile that has a slow rise (inhale) and quick fall (exhale). The rise should take about 3x longer than the fall. Adjust rise angle and fall angle.',
    hint: 'Rise angle 270 deg + fall angle 90 deg = 3:1 ratio. The follower rises slowly and drops quickly.',
    type: 'interactive-cam', successCondition: 'breathing-ratio', xp: 20,
    params: { baseRadius: 20, riseHeight: 12, dwellAngle: 0, riseAngle: 200, fallAngle: 100 },
    tutorialContexts: ['exercises-cams'],
    learnedFact: 'Asymmetric motion profiles create organic, living movement. The 3:1 inhale:exhale ratio mimics natural breathing. Disney animators called this "slow in, slow out."'
  },

  // --- Slider-Crank & Eccentric ---
  {
    id: 'ex-slider-crank', category: 'Slider-Crank & Eccentric', skillTag: 'eccentric', difficulty: 'easy',
    title: 'Control the Stroke Length',
    description: 'A slider-crank drives a wave up and down. The stroke (total travel) = 2x crank radius. Adjust the crank radius to achieve a stroke of exactly 40mm.',
    hint: 'Stroke = 2 x crank radius. For 40mm stroke, set crank radius to 20mm.',
    type: 'interactive-slider-crank', successCondition: 'stroke-40', xp: 15,
    params: { crankRadius: 15, rodLength: 80 },
    tutorialContexts: ['exercises-eccentric'],
    learnedFact: 'Slider-crank: Stroke = 2 x Crank Radius. This is the simplest rotation-to-linear converter. It is used in engines, waves, and pumping motions.'
  },
  {
    id: 'ex-eccentric-sway', category: 'Slider-Crank & Eccentric', skillTag: 'eccentric', difficulty: 'easy',
    title: 'Make a Tree Sway 15mm',
    description: 'An eccentric drive makes a tree element sway. The total sway = 2x eccentric offset. Set the offset to make it sway exactly 15mm total.',
    hint: 'Offset of 7.5mm gives 15mm total sway (7.5mm each side of center).',
    type: 'interactive-eccentric', successCondition: 'sway-15', xp: 15,
    params: { offset: 5, discRadius: 30 },
    tutorialContexts: ['exercises-eccentric'],
    learnedFact: 'Eccentric drives are the simplest sway mechanism. Offset = amplitude. They are ideal for trees, grass, and gentle oscillation where you do not need complex paths.'
  },

  // --- Gears & Trains ---
  {
    id: 'ex-gear-ratio', category: 'Gears & Trains', skillTag: 'gears', difficulty: 'medium',
    title: 'Slow Down the Motor',
    description: 'Your motor spins at 60 RPM but you need 10 RPM for a gentle wave. Set the driver and driven gear teeth to get a 6:1 reduction.',
    hint: 'Ratio = driven teeth / driver teeth. For 6:1, try driver=12, driven=72.',
    type: 'interactive-gears', successCondition: 'ratio-6', xp: 20,
    params: { driverTeeth: 20, drivenTeeth: 40, inputRPM: 60 },
    tutorialContexts: ['exercises', 'skills-gears'],
    learnedFact: 'Gear ratio = driven/driver teeth. A 6:1 ratio means 6x slower but 6x more torque. Most kinetic sculptures need 10-30:1 total reduction from motor to output.'
  },

  // --- Physics & Friction ---
  {
    id: 'ex-friction-cascade', category: 'Physics & Friction', skillTag: 'simulation', difficulty: 'stretch',
    title: 'The Friction Problem',
    description: 'Margolin routes strings through pulleys. Each pulley loses ~4% of force to friction. Add pulleys and watch the output force drop. Find out why he limits chains to 9 pulleys.',
    hint: 'After 9 pulleys at 4% loss each: F_out = F_in x 0.96^9 = ~69% remaining. After 15: only ~54%.',
    type: 'interactive-friction', successCondition: 'friction-understood', xp: 25,
    params: { pulleys: 3, frictionPerPulley: 0.04, inputForce: 10 },
    tutorialContexts: ['exercises', 'skills-simulation'],
    learnedFact: 'Friction cascade: F_out = F_in x (1-f)^n. With 4% loss per pulley, 9 pulleys lose 31% of force. This is why Margolin limits string paths and uses the fewest pulleys possible.'
  },

  // --- Design Thinking ---
  {
    id: 'ex-compact-mechanism', category: 'Design Thinking', skillTag: 'designThinking', difficulty: 'stretch',
    title: 'Make It Fit',
    description: 'This four-bar is 200mm wide but must fit in 80mm. Scale all links by the same factor. The motion character (angles, ratios) stays identical when you scale proportionally.',
    hint: 'Scale factor = 80/200 = 0.4. Multiply every link length by 0.4.',
    type: 'interactive-scaling', successCondition: 'fits-80', xp: 20,
    params: { ground: 200, crank: 50, coupler: 180, rocker: 160, targetWidth: 80 },
    tutorialContexts: ['exercises-design', 'exercises-fourBar'],
    learnedFact: 'Proportional scaling preserves motion character. A 200mm mechanism scaled to 80mm produces the same angles and timing — just smaller. This is how you make compact kinetic art.'
  },

  // ======================================================
  // PIPELINE-REINFORCING EXERCISES (Phase 8)
  // ======================================================

  // --- Mechanize Skills ---
  {
    id: 'ex-wave-to-cams', category: 'Mechanize Skills', skillTag: 'designThinking', difficulty: 'medium',
    title: 'How Many Cams for This Wave?',
    description: 'A 3-source interference pattern needs independent cam shafts — one per wave source. If you have 3 perpendicular wave groups with 6 elements each, how many total cams do you need?',
    hint: '3 wave sources x 6 elements each = 18 cams total. But wait — elements on the same shaft share phase offsets, so you need 3 shafts with 6 cams each.',
    type: 'interactive-cam-count', successCondition: 'cam-count-18', xp: 25,
    params: { waveSources: 3, elementsPerSource: 6, totalCams: 9 },
    tutorialContexts: ['exercises-design'],
    learnedFact: 'Cam count = wave sources x elements per source. Each wave source needs its own shaft. Elements on one shaft share timing but offset phase. This is how Margolin maps math to hardware.'
  },
  {
    id: 'ex-helix-vs-disc', category: 'Mechanize Skills', skillTag: 'designThinking', difficulty: 'stretch',
    title: 'Helical vs Disc Cam: Which and Why?',
    description: 'Choose the right mechanism: a wave with smooth continuous phase gradient (no discrete steps) needs a helix. A wave with distinct phase zones needs disc cams. Adjust the "smoothness" slider to find the crossover.',
    hint: 'Continuous gradient = helix (aluminum spiral). Discrete steps = disc cams (plywood). If step count > 12, a helix becomes more practical.',
    type: 'interactive-mechanism-choice', successCondition: 'mechanism-chosen-correct', xp: 30,
    params: { phaseSteps: 6, smoothness: 0.3, mechanismChoice: 'disc' },
    tutorialContexts: ['exercises-design'],
    learnedFact: 'Helix = continuous phase, disc cams = discrete phase. For < 12 elements, disc cams are cheaper and easier. For > 12 or continuous gradient, helix is more practical. Margolin uses both.'
  },

  // --- Simulate Skills ---
  {
    id: 'ex-friction-budget', category: 'Simulate Skills', skillTag: 'simulation', difficulty: 'medium',
    title: 'Friction Through 7 Pulleys',
    description: 'Calculate: if input force is 5N and each pulley loses 4% friction, what force reaches the 7th pulley? Adjust pulleys to find where efficiency drops below 70%.',
    hint: 'F_out = 5 x 0.96^7 = 3.76N (75.1%). At 9 pulleys: 5 x 0.96^9 = 3.44N (68.9%). The hard limit is 9.',
    type: 'interactive-friction', successCondition: 'friction-below-70', xp: 25,
    params: { pulleys: 5, frictionPerPulley: 0.04, inputForce: 5 },
    tutorialContexts: ['exercises', 'skills-simulation'],
    learnedFact: 'At 4% loss per pulley: 7 pulleys = 75% efficient, 9 pulleys = 69%, 12 pulleys = 61%. Margolin hard-limits at 9 pulleys. If you need more, parallelize the string paths instead.'
  },
  {
    id: 'ex-motor-power', category: 'Simulate Skills', skillTag: 'simulation', difficulty: 'stretch',
    title: 'Can This Motor Drive 3 Cams?',
    description: 'Your motor provides 0.5W. Each cam + follower + string assembly consumes ~0.08W at 10RPM. With the 10x rule (design for 10x expected load), can this motor handle 3 cams?',
    hint: '3 cams x 0.08W = 0.24W needed. With 10x rule: 0.24W x 10 = 2.4W required. Motor is 0.5W. That is NOT enough. You need a 2.5W+ motor.',
    type: 'interactive-power-budget', successCondition: 'power-correct', xp: 30,
    params: { motorPower: 0.5, camCount: 3, powerPerCam: 0.08, safetyFactor: 10, answer: '' },
    tutorialContexts: ['exercises', 'skills-simulation'],
    learnedFact: 'The 10x rule: design for 10x your estimated power. If 3 cams need 0.24W, budget 2.4W. This covers friction surprises, startup torque, and cold weather. Always oversize the motor.'
  },
  {
    id: 'ex-gear-ratio-calc', category: 'Simulate Skills', skillTag: 'gears', difficulty: 'medium',
    title: 'Find the Gear Ratio: 60 to 8 RPM',
    description: 'Your motor runs at 60 RPM but your sculpture needs 8 RPM for a gentle, organic feel. Calculate the gear ratio needed and set the teeth counts to achieve it.',
    hint: 'Ratio = 60/8 = 7.5:1. Driver 12T + driven 90T = 7.5:1 exactly. Or driver 10T + driven 75T.',
    type: 'interactive-gears', successCondition: 'ratio-7.5', xp: 20,
    params: { driverTeeth: 20, drivenTeeth: 40, inputRPM: 60 },
    tutorialContexts: ['exercises', 'skills-gears'],
    learnedFact: 'Gear ratio = output teeth / input teeth = input RPM / output RPM. For 60→8 RPM: 7.5:1 ratio. Use two stages if single ratio is too high (e.g., 3:1 x 2.5:1 = 7.5:1).'
  },

  // --- Build Skills ---
  {
    id: 'ex-material-select', category: 'Build Skills', skillTag: 'designThinking', difficulty: 'medium',
    title: 'This Part Sees 5N Force — PLA or Aluminum?',
    description: 'A cam follower arm experiences 5N of force continuously. Choose the right material: PLA (cheap, prints fast) or Aluminum (stronger, more expensive). Consider fatigue life.',
    hint: 'PLA at 5N continuous: high-stress, fatigues in 6-12 months. Aluminum: minimal fatigue at this load, lasts 10+ years. For a prototype, PLA is fine. For production, upgrade to aluminum.',
    type: 'interactive-material-quiz', successCondition: 'material-correct', xp: 20,
    params: { force: 5, partName: 'Cam follower arm', answers: { prototype: 'PLA', production: 'Aluminum' }, selectedPrototype: '', selectedProduction: '' },
    tutorialContexts: ['exercises-design'],
    learnedFact: 'PLA is fine for prototyping but fatigues under continuous load in 6-12 months. For production parts that see force, upgrade to PETG (2x life), nylon (5x), or aluminum (decades). Always prototype first.'
  },
  {
    id: 'ex-tolerance-stack', category: 'Build Skills', skillTag: 'simulation', difficulty: 'stretch',
    title: 'Tolerance Stack: 5 Parts at 0.3mm Each',
    description: 'You have 5 parts in a stack, each with +/-0.3mm tolerance (3D print). Calculate worst-case and statistical tolerance stack-up. Is the total acceptable for a 2mm clearance gap?',
    hint: 'Worst case: 5 x 0.3mm = 1.5mm. Statistical (RSS): sqrt(5) x 0.3mm = 0.67mm. Worst case uses 75% of your 2mm gap. That is tight but possible.',
    type: 'interactive-tolerance', successCondition: 'tolerance-calculated', xp: 30,
    params: { partCount: 5, toleranceEach: 0.3, clearanceGap: 2.0, worstCase: 0, statistical: 0 },
    tutorialContexts: ['exercises', 'skills-simulation'],
    learnedFact: 'Worst-case stack = n x t. Statistical stack = sqrt(n) x t. For 3D printing (0.3mm tolerance), keep stacks under 5-7 parts. For CNC (0.05mm), you can stack 20+ parts safely.'
  },

  // --- Design Challenges (multi-step) ---
  {
    id: 'ex-design-nodding', category: 'Design Challenges', skillTag: 'cams', difficulty: 'stretch',
    title: 'Design a Nodding Motion',
    description: 'A puppet needs to nod: rise slowly, pause at top (dwell), fall quickly. Design a cam with Rise 120deg, Dwell 90deg, Fall 60deg, Dwell 90deg. Get the dwell above 80deg.',
    hint: 'Rise=120 + Dwell=90 + Fall=60 + Dwell=90 = 360deg total. The 2:1 rise:fall ratio creates anticipation before the quick nod.',
    type: 'interactive-cam', successCondition: 'dwell-above-90', xp: 35,
    params: { baseRadius: 25, riseHeight: 15, dwellAngle: 70 },
    tutorialContexts: ['exercises-cams', 'exercises-design'],
    learnedFact: 'Nodding motion = rise + dwell + fall + dwell. Asymmetric rise/fall creates anticipation (Disney principle). The dwell at top is the "dramatic pause" that gives motion character.'
  },
  {
    id: 'ex-design-sync-waves', category: 'Design Challenges', skillTag: 'simulation', difficulty: 'stretch',
    title: 'Synchronize Two Waves for Constructive Interference',
    description: 'Two waves meet at a point. For maximum amplitude (constructive interference), their phases must differ by 0 or 2π. Set the phase difference to get maximum combined amplitude.',
    hint: 'When phase difference = 0, the waves add perfectly: combined amplitude = A1 + A2. At phase = π, they cancel: amplitude = |A1 - A2|.',
    type: 'interactive-phase-sync', successCondition: 'max-amplitude', xp: 35,
    params: { amplitude1: 2.0, amplitude2: 1.5, phaseDiff: 1.5, frequency: 1.0 },
    tutorialContexts: ['exercises', 'exercises-fourBar'],
    learnedFact: 'Constructive interference: Δφ = 0 or 2nπ, combined A = A1 + A2. Destructive: Δφ = π, A = |A1 - A2|. Margolin uses this to create visual "nodes" where motion cancels and "antinodes" of maximum motion.'
  },
];

let currentExercise = null;
let exerciseState = {};

export async function mount(container) {
  await loadLibraries(['jsxgraph-css', 'jsxgraph']);

  // Group exercises by category
  const categories = {};
  MECHANISM_EXERCISES.forEach(ex => {
    if (!categories[ex.category]) categories[ex.category] = [];
    categories[ex.category].push(ex);
  });

  let categorySections = '';
  Object.entries(categories).forEach(([cat, exercises]) => {
    const cards = exercises.map(ex => {
      const diffClass = ex.difficulty || 'easy';
      return `
        <div class="card daily-task exercise-card" data-id="${ex.id}">
          <div style="flex:1;">
            <div class="flex gap" style="align-items:center;margin-bottom:4px;">
              <span class="difficulty-badge ${diffClass}">${diffClass.toUpperCase()}</span>
              <strong class="text-sm">${ex.title}</strong>
            </div>
            <div class="text-sm text-dim">${ex.description}</div>
            <div class="card-xp">+${ex.xp} XP | Skill: ${ex.skillTag}</div>
          </div>
        </div>
      `;
    }).join('');

    categorySections += `
      <div class="section-title mt-lg">${cat.toUpperCase()}</div>
      <div class="flex-col gap">${cards}</div>
    `;
  });

  container.innerHTML = `
    <div class="section-title">Mechanism Exercises</div>
    <p class="text-sm text-dim" style="margin-bottom:12px;">Interactive explorations — learn by tinkering with real mechanisms. Each exercise has sliders to adjust and a goal to achieve.</p>
    <div id="exercise-list">${categorySections}</div>
    <div id="exercise-workspace" class="mt-lg hidden"></div>
  `;

  container.querySelectorAll('.exercise-card').forEach(card => {
    card.onclick = () => {
      const ex = MECHANISM_EXERCISES.find(e => e.id === card.dataset.id);
      if (ex) startExercise(ex);
    };
  });

  updateSidebar();
}

function startExercise(exercise) {
  currentExercise = exercise;
  exerciseState = { ...exercise.params };

  const workspace = document.getElementById('exercise-workspace');
  workspace.classList.remove('hidden');

  const diffClass = exercise.difficulty || 'easy';
  workspace.innerHTML = `
    <div class="section-title">Current Exercise</div>
    <div class="card" style="border-color: var(--accent);">
      <div style="display:flex; align-items:center; gap:8px; margin-bottom:4px;">
        <span class="difficulty-badge ${diffClass}">${diffClass.toUpperCase()}</span>
        <div class="card-title" style="margin:0;">${exercise.title}</div>
      </div>
      <div class="card-desc">${exercise.description}</div>
    </div>
    <div id="exercise-canvas" style="background:#111;border-radius:8px;margin:8px 0;min-height:250px;"></div>
    <div id="exercise-sliders" class="slider-panel"></div>
    <div id="exercise-status" class="mechanism-info" style="margin:8px 0;"></div>
    <div class="mt flex gap" style="flex-wrap:wrap;">
      <button id="show-hint" style="font-size:12px;">Show Hint</button>
      <button id="complete-exercise" class="primary" disabled>Complete</button>
      <button id="skip-exercise">Skip</button>
      ${createP5Button('Try in p5 Editor')}
    </div>
    <div id="exercise-hint" class="hidden mechanism-info" style="margin-top:8px;border-left-color:var(--warning);">
      <strong>Hint:</strong> ${exercise.hint}
    </div>
    <div id="exercise-tutorials" style="margin-top:12px;"></div>
  `;

  // Render the interactive visualization
  renderExerciseVisualization(exercise);

  // Render tutorial links
  renderTutorialLinks(exercise);

  document.getElementById('show-hint').onclick = () => {
    document.getElementById('exercise-hint').classList.toggle('hidden');
  };
  document.getElementById('complete-exercise').onclick = () => completeExercise();
  document.getElementById('skip-exercise').onclick = () => {
    workspace.classList.add('hidden');
    currentExercise = null;
  };

  // p5 Editor button — generates a sketch relevant to the exercise
  const p5Btn = document.querySelector('.p5-editor-btn');
  if (p5Btn) p5Btn.onclick = () => openExerciseInP5(exercise);

  // Scroll to workspace
  workspace.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function renderExerciseVisualization(exercise) {
  const canvas = document.getElementById('exercise-canvas');
  const sliders = document.getElementById('exercise-sliders');

  if (exercise.type === 'interactive-fourbar') {
    renderFourBarExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-cam') {
    renderCamExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-slider-crank') {
    renderSliderCrankExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-eccentric') {
    renderEccentricExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-gears') {
    renderGearExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-friction') {
    renderFrictionExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-scaling') {
    renderScalingExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-cam-count') {
    renderCamCountExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-mechanism-choice') {
    renderMechanismChoiceExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-power-budget') {
    renderPowerBudgetExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-material-quiz') {
    renderMaterialQuizExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-tolerance') {
    renderToleranceExercise(canvas, sliders, exercise);
  } else if (exercise.type === 'interactive-phase-sync') {
    renderPhaseSyncExercise(canvas, sliders, exercise);
  }
}

function renderFourBarExercise(canvas, sliders, exercise) {
  canvas.style.height = '280px';
  canvas.id = 'fb-canvas';
  if (typeof JXG === 'undefined') { canvas.innerHTML = '<p class="text-dim">Loading JSXGraph...</p>'; return; }

  const board = JXG.JSXGraph.initBoard('fb-canvas', {
    boundingbox: [-20, 130, 230, -40], axis: false, grid: false,
    showCopyright: false, showNavigation: false
  });

  function draw() {
    board.suspendUpdate();
    board.removeObject(board.objectsList.filter(o => o.elType !== 'point' || !o.getAttribute('fixed')));
    // Clear all objects
    while (board.objectsList.length > 0) board.removeObject(board.objectsList[0]);

    const g = exerciseState.ground || 100;
    const c = exerciseState.crank || 30;
    const co = exerciseState.coupler || 80;
    const r = exerciseState.rocker || 70;

    const O2 = board.create('point', [0, 0], { fixed: true, name: 'O2', size: 3, color: '#888' });
    const O4 = board.create('point', [g, 0], { fixed: true, name: 'O4', size: 3, color: '#888' });

    // Position crank tip at 45 degrees
    const ax = c * Math.cos(Math.PI / 4);
    const ay = c * Math.sin(Math.PI / 4);
    const A = board.create('point', [ax, ay], { name: 'A', size: 3, color: '#4fc3f7', fixed: true });

    // Find B via circle intersection
    const bx = g - r * Math.cos(Math.PI / 6);
    const by = r * Math.sin(Math.PI / 6);
    const B = board.create('point', [bx, by], { name: 'B', size: 3, color: '#66bb6a', fixed: true });

    board.create('segment', [O2, A], { strokeColor: '#4fc3f7', strokeWidth: 3 });
    board.create('segment', [A, B], { strokeColor: '#ffa726', strokeWidth: 3 });
    board.create('segment', [O4, B], { strokeColor: '#66bb6a', strokeWidth: 3 });
    board.create('segment', [O2, O4], { strokeColor: '#555', strokeWidth: 2, dash: 2 });
    board.unsuspendUpdate();

    // Check condition
    const isGrashof = checkGrashof(g, c, co, r);
    const links = [g, c, co, r].sort((a, b) => a - b);
    const status = document.getElementById('exercise-status');
    status.innerHTML = `
      <strong>Links:</strong> G=${g} C=${c} Co=${co} R=${r}<br>
      <strong>S+L:</strong> ${links[0]}+${links[3]} = ${links[0] + links[3]} |
      <strong>P+Q:</strong> ${links[1]}+${links[2]} = ${links[1] + links[2]}<br>
      <strong>Grashof:</strong> <span style="color:${isGrashof ? 'var(--success)' : 'var(--error)'};">${isGrashof ? 'VALID — crank can rotate fully' : 'INVALID — no link can rotate fully'}</span>
    `;

    // Check success
    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Ground <span class="slider-value" id="fb-g-val">${exerciseState.ground}</span></label>
      <input type="range" id="fb-g" min="50" max="150" step="5" value="${exerciseState.ground}"></div>
    <div class="slider-group"><label>Crank <span class="slider-value" id="fb-c-val">${exerciseState.crank}</span></label>
      <input type="range" id="fb-c" min="10" max="80" step="5" value="${exerciseState.crank}"></div>
    <div class="slider-group"><label>Coupler <span class="slider-value" id="fb-co-val">${exerciseState.coupler}</span></label>
      <input type="range" id="fb-co" min="40" max="120" step="5" value="${exerciseState.coupler}"></div>
    <div class="slider-group"><label>Rocker <span class="slider-value" id="fb-r-val">${exerciseState.rocker}</span></label>
      <input type="range" id="fb-r" min="40" max="120" step="5" value="${exerciseState.rocker}"></div>
  </div>`;

  ['g', 'c', 'co', 'r'].forEach(key => {
    const map = { g: 'ground', c: 'crank', co: 'coupler', r: 'rocker' };
    const el = document.getElementById(`fb-${key}`);
    if (el) el.oninput = () => {
      exerciseState[map[key]] = parseInt(el.value);
      document.getElementById(`fb-${key}-val`).textContent = el.value;
      draw();
    };
  });

  draw();
}

function renderCamExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="cam-cvs" width="400" height="250" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('cam-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const base = exerciseState.baseRadius || 20;
    const rise = exerciseState.riseHeight || 10;
    const dwell = exerciseState.dwellAngle || 60;
    const cx = W / 2, cy = H / 2;
    const scale = 4;

    // Draw cam profile
    ctx.strokeStyle = '#4fc3f7';
    ctx.lineWidth = 2;
    ctx.beginPath();
    for (let deg = 0; deg <= 360; deg++) {
      const rad = deg * Math.PI / 180;
      let r = base * scale;
      if (deg < dwell) {
        r = (base + rise) * scale; // dwell at top
      } else if (deg < dwell + 90) {
        const t = (deg - dwell) / 90;
        r = (base + rise * (1 - t)) * scale; // fall
      } else if (deg < 360 - 90) {
        r = base * scale; // base circle
      } else {
        const t = (deg - (360 - 90)) / 90;
        r = (base + rise * t) * scale; // rise
      }
      const x = cx + r * Math.cos(rad - Math.PI / 2);
      const y = cy + r * Math.sin(rad - Math.PI / 2);
      if (deg === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    ctx.closePath();
    ctx.stroke();

    // Center
    ctx.beginPath();
    ctx.arc(cx, cy, 3, 0, 2 * Math.PI);
    ctx.fillStyle = '#888';
    ctx.fill();

    // Dwell arc indicator
    ctx.strokeStyle = '#ffa726';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(cx, cy, (base + rise + 3) * scale, -Math.PI / 2, -Math.PI / 2 + dwell * Math.PI / 180);
    ctx.stroke();

    const status = document.getElementById('exercise-status');
    status.innerHTML = `<strong>Dwell:</strong> ${dwell} deg (${(dwell / 360 * 100).toFixed(0)}% of rotation) | <strong>Rise:</strong> ${rise}mm`;

    checkExerciseSuccess(exercise);
  }

  const dwellDefault = exerciseState.dwellAngle || 60;
  const riseDefault = exerciseState.riseHeight || 10;
  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Dwell Angle <span class="slider-value" id="cam-dw-val">${dwellDefault}</span> deg</label>
      <input type="range" id="cam-dw" min="0" max="180" step="5" value="${dwellDefault}"></div>
    <div class="slider-group"><label>Rise Height <span class="slider-value" id="cam-rh-val">${riseDefault}</span> mm</label>
      <input type="range" id="cam-rh" min="3" max="25" step="1" value="${riseDefault}"></div>
  </div>`;

  document.getElementById('cam-dw').oninput = (e) => {
    exerciseState.dwellAngle = parseInt(e.target.value);
    document.getElementById('cam-dw-val').textContent = e.target.value;
    draw();
  };
  document.getElementById('cam-rh').oninput = (e) => {
    exerciseState.riseHeight = parseInt(e.target.value);
    document.getElementById('cam-rh-val').textContent = e.target.value;
    draw();
  };
  draw();
}

function renderSliderCrankExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="sc-cvs" width="500" height="200" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('sc-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const cr = exerciseState.crankRadius || 15;
    const rod = exerciseState.rodLength || 80;
    const cx = 150, cy = H / 2;
    const stroke = cr * 2;

    // Crank circle
    ctx.strokeStyle = '#333';
    ctx.beginPath();
    ctx.arc(cx, cy, cr * 2, 0, 2 * Math.PI);
    ctx.stroke();

    // Show stroke range
    const sliderY = cy;
    ctx.strokeStyle = '#ffa726';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(cx + (rod - cr) * 2, sliderY - 5);
    ctx.lineTo(cx + (rod - cr) * 2, sliderY + 5);
    ctx.moveTo(cx + (rod + cr) * 2, sliderY - 5);
    ctx.lineTo(cx + (rod + cr) * 2, sliderY + 5);
    ctx.moveTo(cx + (rod - cr) * 2, sliderY);
    ctx.lineTo(cx + (rod + cr) * 2, sliderY);
    ctx.stroke();

    // Stroke label
    ctx.fillStyle = '#ffa726';
    ctx.font = '12px monospace';
    ctx.fillText(`Stroke: ${stroke}mm`, cx + rod * 2 - 30, sliderY + 25);

    const status = document.getElementById('exercise-status');
    status.innerHTML = `<strong>Crank Radius:</strong> ${cr}mm | <strong>Stroke:</strong> ${stroke}mm (= 2 x ${cr}) | <strong>Target:</strong> 40mm`;

    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Crank Radius <span class="slider-value" id="sc-cr-val">${exerciseState.crankRadius}</span> mm</label>
      <input type="range" id="sc-cr" min="5" max="40" step="1" value="${exerciseState.crankRadius}"></div>
    <div class="slider-group"><label>Rod Length <span class="slider-value" id="sc-rl-val">${exerciseState.rodLength}</span> mm</label>
      <input type="range" id="sc-rl" min="40" max="120" step="5" value="${exerciseState.rodLength}"></div>
  </div>`;

  document.getElementById('sc-cr').oninput = (e) => {
    exerciseState.crankRadius = parseInt(e.target.value);
    document.getElementById('sc-cr-val').textContent = e.target.value;
    draw();
  };
  document.getElementById('sc-rl').oninput = (e) => {
    exerciseState.rodLength = parseInt(e.target.value);
    document.getElementById('sc-rl-val').textContent = e.target.value;
    draw();
  };
  draw();
}

function renderEccentricExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="ecc-cvs" width="400" height="200" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('ecc-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const offset = exerciseState.offset || 5;
    const discR = exerciseState.discRadius || 30;
    const cx = W / 2, cy = H / 2;
    const scale = 3;

    // Disc
    ctx.strokeStyle = '#4fc3f7';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(cx, cy, discR * scale, 0, 2 * Math.PI);
    ctx.stroke();

    // Center point
    ctx.fillStyle = '#888';
    ctx.beginPath();
    ctx.arc(cx, cy, 3, 0, 2 * Math.PI);
    ctx.fill();

    // Eccentric point
    ctx.fillStyle = '#ffa726';
    ctx.beginPath();
    ctx.arc(cx + offset * scale, cy, 5, 0, 2 * Math.PI);
    ctx.fill();

    // Sway range
    const totalSway = offset * 2;
    ctx.strokeStyle = '#66bb6a';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(cx - offset * scale, cy - 50);
    ctx.lineTo(cx - offset * scale, cy + 50);
    ctx.moveTo(cx + offset * scale, cy - 50);
    ctx.lineTo(cx + offset * scale, cy + 50);
    ctx.stroke();

    ctx.fillStyle = '#66bb6a';
    ctx.font = '12px monospace';
    ctx.fillText(`Total sway: ${totalSway}mm`, cx - 40, cy + 70);

    const status = document.getElementById('exercise-status');
    status.innerHTML = `<strong>Offset:</strong> ${offset}mm | <strong>Total Sway:</strong> ${totalSway}mm (= 2 x ${offset}) | <strong>Target:</strong> 15mm`;

    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Eccentric Offset <span class="slider-value" id="ecc-o-val">${exerciseState.offset}</span> mm</label>
      <input type="range" id="ecc-o" min="1" max="20" step="0.5" value="${exerciseState.offset}"></div>
  </div>`;

  document.getElementById('ecc-o').oninput = (e) => {
    exerciseState.offset = parseFloat(e.target.value);
    document.getElementById('ecc-o-val').textContent = e.target.value;
    draw();
  };
  draw();
}

function renderGearExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="gear-cvs" width="400" height="200" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('gear-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const driver = exerciseState.driverTeeth || 20;
    const driven = exerciseState.drivenTeeth || 40;
    const ratio = driven / driver;
    const outputRPM = exerciseState.inputRPM / ratio;

    const cx1 = W / 3, cx2 = 2 * W / 3, cy = H / 2;
    const r1 = driver * 1.5, r2 = driven * 1.5;

    // Driver gear
    ctx.strokeStyle = '#4fc3f7';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(cx1, cy, Math.min(r1, 60), 0, 2 * Math.PI);
    ctx.stroke();
    ctx.fillStyle = '#4fc3f7';
    ctx.font = '11px monospace';
    ctx.fillText(`${driver}T`, cx1 - 10, cy + 4);

    // Driven gear
    ctx.strokeStyle = '#66bb6a';
    ctx.beginPath();
    ctx.arc(cx2, cy, Math.min(r2, 90), 0, 2 * Math.PI);
    ctx.stroke();
    ctx.fillStyle = '#66bb6a';
    ctx.fillText(`${driven}T`, cx2 - 10, cy + 4);

    ctx.fillStyle = '#fff';
    ctx.font = '12px monospace';
    ctx.fillText(`${exerciseState.inputRPM} RPM -> ${outputRPM.toFixed(1)} RPM`, W / 2 - 60, H - 20);

    const status = document.getElementById('exercise-status');
    status.innerHTML = `<strong>Ratio:</strong> ${driven}/${driver} = ${ratio.toFixed(1)}:1 | <strong>Output:</strong> ${outputRPM.toFixed(1)} RPM | <strong>Target:</strong> 10 RPM (6:1 ratio)`;

    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Driver Teeth <span class="slider-value" id="gear-d1-val">${exerciseState.driverTeeth}</span></label>
      <input type="range" id="gear-d1" min="8" max="40" step="1" value="${exerciseState.driverTeeth}"></div>
    <div class="slider-group"><label>Driven Teeth <span class="slider-value" id="gear-d2-val">${exerciseState.drivenTeeth}</span></label>
      <input type="range" id="gear-d2" min="20" max="120" step="1" value="${exerciseState.drivenTeeth}"></div>
  </div>`;

  document.getElementById('gear-d1').oninput = (e) => {
    exerciseState.driverTeeth = parseInt(e.target.value);
    document.getElementById('gear-d1-val').textContent = e.target.value;
    draw();
  };
  document.getElementById('gear-d2').oninput = (e) => {
    exerciseState.drivenTeeth = parseInt(e.target.value);
    document.getElementById('gear-d2-val').textContent = e.target.value;
    draw();
  };
  draw();
}

function renderFrictionExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="friction-cvs" width="500" height="200" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('friction-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const n = exerciseState.pulleys || 3;
    const f = exerciseState.frictionPerPulley || 0.04;
    const F_in = exerciseState.inputForce || 10;
    const F_out = F_in * Math.pow(1 - f, n);
    const efficiency = (F_out / F_in * 100);

    // Draw pulley chain as bar chart
    const barW = Math.min(30, (W - 60) / Math.max(n, 1));
    for (let i = 0; i <= n; i++) {
      const force = F_in * Math.pow(1 - f, i);
      const barH = (force / F_in) * (H - 40);
      const x = 30 + i * (barW + 4);
      const y = H - 20 - barH;

      const hue = 200 - (i / Math.max(n, 1)) * 150; // blue to red
      ctx.fillStyle = `hsl(${hue}, 70%, 50%)`;
      ctx.fillRect(x, y, barW - 2, barH);

      ctx.fillStyle = '#aaa';
      ctx.font = '9px monospace';
      ctx.fillText(`${force.toFixed(1)}`, x, y - 4);
    }

    ctx.fillStyle = '#fff';
    ctx.font = '11px monospace';
    ctx.fillText(`Input: ${F_in}N | After ${n} pulleys: ${F_out.toFixed(2)}N (${efficiency.toFixed(0)}%)`, 30, 15);

    const status = document.getElementById('exercise-status');
    status.innerHTML = `<strong>Pulleys:</strong> ${n} | <strong>Friction/pulley:</strong> ${(f * 100).toFixed(0)}% | <strong>Efficiency:</strong> ${efficiency.toFixed(1)}% | <strong>Force out:</strong> ${F_out.toFixed(2)}N`;

    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Number of Pulleys <span class="slider-value" id="fr-n-val">${exerciseState.pulleys}</span></label>
      <input type="range" id="fr-n" min="1" max="20" step="1" value="${exerciseState.pulleys}"></div>
    <div class="slider-group"><label>Friction per Pulley <span class="slider-value" id="fr-f-val">${(exerciseState.frictionPerPulley * 100).toFixed(0)}%</span></label>
      <input type="range" id="fr-f" min="0.01" max="0.10" step="0.01" value="${exerciseState.frictionPerPulley}"></div>
  </div>`;

  document.getElementById('fr-n').oninput = (e) => {
    exerciseState.pulleys = parseInt(e.target.value);
    document.getElementById('fr-n-val').textContent = e.target.value;
    draw();
  };
  document.getElementById('fr-f').oninput = (e) => {
    exerciseState.frictionPerPulley = parseFloat(e.target.value);
    document.getElementById('fr-f-val').textContent = (parseFloat(e.target.value) * 100).toFixed(0) + '%';
    draw();
  };
  draw();
}

function renderScalingExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="scale-cvs" width="500" height="250" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('scale-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const g = exerciseState.ground;
    const target = exerciseState.targetWidth;
    const scale = 1.5;

    // Original (dim)
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 1;
    ctx.strokeRect(W / 2 - g * scale / 2, H / 2 - 40, g * scale, 80);
    ctx.fillStyle = '#333';
    ctx.font = '10px monospace';
    ctx.fillText(`Original: ${g}mm`, W / 2 - g * scale / 2, H / 2 + 55);

    // Target box
    ctx.strokeStyle = '#66bb6a';
    ctx.setLineDash([4, 4]);
    ctx.strokeRect(W / 2 - target * scale / 2, H / 2 - 40, target * scale, 80);
    ctx.setLineDash([]);
    ctx.fillStyle = '#66bb6a';
    ctx.fillText(`Target: ${target}mm`, W / 2 - target * scale / 2, H / 2 - 45);

    // Current scaled
    const scaleFactor = g > 0 ? target / exerciseState.ground : 1;
    // Actually use the slider value for ground
    ctx.strokeStyle = '#4fc3f7';
    ctx.lineWidth = 2;
    ctx.strokeRect(W / 2 - g * scale / 2, H / 2 - 30, g * scale, 60);

    const fitsInTarget = g <= target;
    const status = document.getElementById('exercise-status');
    status.innerHTML = `<strong>Current width:</strong> ${g}mm | <strong>Target:</strong> ${target}mm |
      <strong>Fits?</strong> <span style="color:${fitsInTarget ? 'var(--success)' : 'var(--error)'};">${fitsInTarget ? 'YES' : 'NO — too wide'}</span>`;

    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Ground Link <span class="slider-value" id="sc-g-val">${exerciseState.ground}</span> mm</label>
      <input type="range" id="sc-g" min="20" max="200" step="5" value="${exerciseState.ground}"></div>
    <div class="slider-group"><label>Crank <span class="slider-value" id="sc-c-val">${exerciseState.crank}</span> mm</label>
      <input type="range" id="sc-c" min="5" max="80" step="5" value="${exerciseState.crank}"></div>
    <div class="slider-group"><label>Coupler <span class="slider-value" id="sc-co-val">${exerciseState.coupler}</span> mm</label>
      <input type="range" id="sc-co" min="20" max="200" step="5" value="${exerciseState.coupler}"></div>
    <div class="slider-group"><label>Rocker <span class="slider-value" id="sc-r-val">${exerciseState.rocker}</span> mm</label>
      <input type="range" id="sc-r" min="20" max="200" step="5" value="${exerciseState.rocker}"></div>
  </div>`;

  ['g', 'c', 'co', 'r'].forEach(key => {
    const map = { g: 'ground', c: 'crank', co: 'coupler', r: 'rocker' };
    const el = document.getElementById(`sc-${key}`);
    if (el) el.oninput = () => {
      exerciseState[map[key]] = parseInt(el.value);
      document.getElementById(`sc-${key}-val`).textContent = el.value;
      draw();
    };
  });
  draw();
}

// ── New Pipeline-Reinforcing Exercise Renderers ──

function renderCamCountExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="camcount-cvs" width="500" height="250" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('camcount-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const sources = exerciseState.waveSources || 3;
    const elemPer = exerciseState.elementsPerSource || 6;
    const total = exerciseState.totalCams || sources * elemPer;

    // Draw wave source groups as shaft diagrams
    const groupWidth = (W - 40) / sources;
    for (let s = 0; s < sources; s++) {
      const gx = 20 + s * groupWidth + groupWidth / 2;
      const gy = 30;

      // Shaft label
      ctx.fillStyle = '#4fc3f7';
      ctx.font = '11px monospace';
      ctx.fillText(`Shaft ${s + 1}`, gx - 20, gy);

      // Draw cams on shaft
      const camH = Math.min(16, (H - 80) / elemPer);
      for (let e = 0; e < elemPer; e++) {
        const cy = gy + 15 + e * (camH + 2);
        const phase = (e / elemPer) * 360;
        const hue = (s * 120) % 360;
        ctx.fillStyle = `hsl(${hue}, 60%, 45%)`;
        ctx.fillRect(gx - 15, cy, 30, camH);
        ctx.fillStyle = '#aaa';
        ctx.font = '8px monospace';
        ctx.fillText(`${phase.toFixed(0)}deg`, gx + 18, cy + camH - 3);
      }

      // Shaft line
      ctx.strokeStyle = '#666';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(gx, gy + 10);
      ctx.lineTo(gx, gy + 15 + elemPer * (camH + 2));
      ctx.stroke();
    }

    // Total count display
    ctx.fillStyle = '#fff';
    ctx.font = '14px monospace';
    ctx.fillText(`Total cams: ${total} (${sources} shafts x ${elemPer} cams)`, 20, H - 15);

    const status = document.getElementById('exercise-status');
    const correct = total === sources * elemPer && total === 18;
    status.innerHTML = `<strong>Wave sources:</strong> ${sources} | <strong>Elements/source:</strong> ${elemPer} | <strong>Total cams:</strong> ${total} |
      <strong>Target:</strong> 18 <span style="color:${correct ? 'var(--success)' : 'var(--error)'};">${correct ? ' CORRECT' : ''}</span>`;

    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Wave Sources <span class="slider-value" id="cc-ws-val">${exerciseState.waveSources}</span></label>
      <input type="range" id="cc-ws" min="1" max="6" step="1" value="${exerciseState.waveSources}"></div>
    <div class="slider-group"><label>Elements/Source <span class="slider-value" id="cc-ep-val">${exerciseState.elementsPerSource}</span></label>
      <input type="range" id="cc-ep" min="2" max="12" step="1" value="${exerciseState.elementsPerSource}"></div>
    <div class="slider-group"><label>Total Cams <span class="slider-value" id="cc-tc-val">${exerciseState.totalCams}</span></label>
      <input type="range" id="cc-tc" min="2" max="36" step="1" value="${exerciseState.totalCams}"></div>
  </div>`;

  document.getElementById('cc-ws').oninput = (e) => { exerciseState.waveSources = parseInt(e.target.value); document.getElementById('cc-ws-val').textContent = e.target.value; draw(); };
  document.getElementById('cc-ep').oninput = (e) => { exerciseState.elementsPerSource = parseInt(e.target.value); document.getElementById('cc-ep-val').textContent = e.target.value; draw(); };
  document.getElementById('cc-tc').oninput = (e) => { exerciseState.totalCams = parseInt(e.target.value); document.getElementById('cc-tc-val').textContent = e.target.value; draw(); };
  draw();
}

function renderMechanismChoiceExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="mech-cvs" width="500" height="250" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('mech-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const steps = exerciseState.phaseSteps || 6;
    const smooth = exerciseState.smoothness || 0.3;
    const choice = exerciseState.mechanismChoice || 'disc';

    // Draw phase gradient visualization
    const barW = (W - 60) / 20;
    for (let i = 0; i < 20; i++) {
      const t = i / 20;
      // Smooth = continuous gradient, Discrete = stepped
      const phase = smooth > 0.5
        ? t * 360
        : Math.floor(t * steps) * (360 / steps);
      const barH = 40 + (phase / 360) * 120;
      const x = 30 + i * barW;
      const y = H - 30 - barH;

      const hue = phase;
      ctx.fillStyle = `hsl(${hue}, 60%, 45%)`;
      ctx.fillRect(x, y, barW - 2, barH);
    }

    // Labels
    ctx.fillStyle = '#fff';
    ctx.font = '12px monospace';
    ctx.fillText(`Smoothness: ${(smooth * 100).toFixed(0)}% | Steps: ${steps}`, 30, 20);

    // Mechanism recommendation
    const recommended = smooth > 0.6 || steps > 12 ? 'helix' : 'disc';
    ctx.fillStyle = choice === recommended ? '#66bb6a' : '#ef5350';
    ctx.fillText(`Your choice: ${choice.toUpperCase()} | Recommended: ${recommended.toUpperCase()}`, 30, H - 10);

    const status = document.getElementById('exercise-status');
    status.innerHTML = `<strong>Phase steps:</strong> ${steps} | <strong>Smoothness:</strong> ${(smooth * 100).toFixed(0)}% |
      <strong>Choice:</strong> ${choice} | <strong>Correct?</strong> <span style="color:${choice === recommended ? 'var(--success)' : 'var(--error)'};">${choice === recommended ? 'YES' : 'NO — try ' + recommended}</span>`;

    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Phase Steps <span class="slider-value" id="mc-ps-val">${exerciseState.phaseSteps}</span></label>
      <input type="range" id="mc-ps" min="3" max="24" step="1" value="${exerciseState.phaseSteps}"></div>
    <div class="slider-group"><label>Smoothness <span class="slider-value" id="mc-sm-val">${(exerciseState.smoothness * 100).toFixed(0)}%</span></label>
      <input type="range" id="mc-sm" min="0" max="1" step="0.05" value="${exerciseState.smoothness}"></div>
    <div class="slider-group"><label>Mechanism</label>
      <select id="mc-choice" style="flex:1;">
        <option value="disc" ${exerciseState.mechanismChoice === 'disc' ? 'selected' : ''}>Disc Cams</option>
        <option value="helix" ${exerciseState.mechanismChoice === 'helix' ? 'selected' : ''}>Helix</option>
      </select>
    </div>
  </div>`;

  document.getElementById('mc-ps').oninput = (e) => { exerciseState.phaseSteps = parseInt(e.target.value); document.getElementById('mc-ps-val').textContent = e.target.value; draw(); };
  document.getElementById('mc-sm').oninput = (e) => { exerciseState.smoothness = parseFloat(e.target.value); document.getElementById('mc-sm-val').textContent = (parseFloat(e.target.value) * 100).toFixed(0) + '%'; draw(); };
  document.getElementById('mc-choice').onchange = (e) => { exerciseState.mechanismChoice = e.target.value; draw(); };
  draw();
}

function renderPowerBudgetExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="power-cvs" width="500" height="200" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('power-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const motor = exerciseState.motorPower || 0.5;
    const cams = exerciseState.camCount || 3;
    const perCam = exerciseState.powerPerCam || 0.08;
    const safety = exerciseState.safetyFactor || 10;

    const needed = cams * perCam;
    const required = needed * safety;
    const sufficient = motor >= required;

    // Power budget bar chart
    const maxP = Math.max(motor, required) * 1.2;
    const barH = 60;

    // Motor capacity bar
    const motorW = (motor / maxP) * (W - 80);
    ctx.fillStyle = '#4fc3f7';
    ctx.fillRect(40, 40, motorW, barH);
    ctx.fillStyle = '#fff';
    ctx.font = '11px monospace';
    ctx.fillText(`Motor: ${motor}W`, 45, 40 + barH / 2 + 4);

    // Required bar
    const reqW = (required / maxP) * (W - 80);
    ctx.fillStyle = sufficient ? '#66bb6a44' : '#ef535044';
    ctx.fillRect(40, 40, reqW, barH);
    ctx.strokeStyle = sufficient ? '#66bb6a' : '#ef5350';
    ctx.lineWidth = 2;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    ctx.moveTo(40 + reqW, 35);
    ctx.lineTo(40 + reqW, 40 + barH + 5);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.fillStyle = sufficient ? '#66bb6a' : '#ef5350';
    ctx.fillText(`Required: ${required.toFixed(2)}W`, 40 + reqW + 5, 55);

    // Answer prompt
    ctx.fillStyle = '#ffa726';
    ctx.font = '13px monospace';
    const answerText = sufficient ? 'SUFFICIENT' : 'INSUFFICIENT — need bigger motor';
    ctx.fillText(answerText, 40, H - 20);

    const status = document.getElementById('exercise-status');
    status.innerHTML = `<strong>Motor:</strong> ${motor}W | <strong>Cams:</strong> ${cams} x ${perCam}W = ${needed.toFixed(2)}W |
      <strong>x${safety} safety:</strong> ${required.toFixed(2)}W |
      <span style="color:${sufficient ? 'var(--success)' : 'var(--error)'};">${sufficient ? 'OK' : 'FAIL — motor too weak'}</span>`;

    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Motor Power <span class="slider-value" id="pb-mp-val">${exerciseState.motorPower}W</span></label>
      <input type="range" id="pb-mp" min="0.1" max="5" step="0.1" value="${exerciseState.motorPower}"></div>
    <div class="slider-group"><label>Cam Count <span class="slider-value" id="pb-cc-val">${exerciseState.camCount}</span></label>
      <input type="range" id="pb-cc" min="1" max="8" step="1" value="${exerciseState.camCount}"></div>
    <div class="slider-group"><label>Safety Factor <span class="slider-value" id="pb-sf-val">${exerciseState.safetyFactor}x</span></label>
      <input type="range" id="pb-sf" min="2" max="20" step="1" value="${exerciseState.safetyFactor}"></div>
    <div class="slider-group"><label>Answer</label>
      <select id="pb-answer" style="flex:1;">
        <option value="" ${!exerciseState.answer ? 'selected' : ''}>-- Select --</option>
        <option value="sufficient" ${exerciseState.answer === 'sufficient' ? 'selected' : ''}>Motor is sufficient</option>
        <option value="insufficient" ${exerciseState.answer === 'insufficient' ? 'selected' : ''}>Motor is insufficient</option>
      </select>
    </div>
  </div>`;

  document.getElementById('pb-mp').oninput = (e) => { exerciseState.motorPower = parseFloat(e.target.value); document.getElementById('pb-mp-val').textContent = e.target.value + 'W'; draw(); };
  document.getElementById('pb-cc').oninput = (e) => { exerciseState.camCount = parseInt(e.target.value); document.getElementById('pb-cc-val').textContent = e.target.value; draw(); };
  document.getElementById('pb-sf').oninput = (e) => { exerciseState.safetyFactor = parseInt(e.target.value); document.getElementById('pb-sf-val').textContent = e.target.value + 'x'; draw(); };
  document.getElementById('pb-answer').onchange = (e) => { exerciseState.answer = e.target.value; draw(); };
  draw();
}

function renderMaterialQuizExercise(canvas, sliders, exercise) {
  canvas.innerHTML = `
    <div style="padding: 16px; color: var(--text);">
      <div style="font-size: 14px; font-weight: 600; margin-bottom: 12px;">Part: ${exerciseState.partName}</div>
      <div style="font-size: 12px; color: var(--text-dim); margin-bottom: 8px;">Continuous force: <strong style="color: var(--accent);">${exerciseState.force}N</strong></div>

      <div style="margin-bottom: 16px;">
        <div style="font-size: 12px; font-weight: 600; margin-bottom: 6px;">For Prototype (3D Print):</div>
        <div style="display: flex; gap: 8px;">
          <button class="mat-btn" data-ctx="prototype" data-mat="PLA" style="flex:1; padding: 10px; font-size: 12px; border: 2px solid ${exerciseState.selectedPrototype === 'PLA' ? 'var(--accent)' : 'var(--border)'};">PLA<br><span style="font-size:10px;color:var(--text-dim);">Cheap, fast print, 6-12mo life</span></button>
          <button class="mat-btn" data-ctx="prototype" data-mat="PETG" style="flex:1; padding: 10px; font-size: 12px; border: 2px solid ${exerciseState.selectedPrototype === 'PETG' ? 'var(--accent)' : 'var(--border)'};">PETG<br><span style="font-size:10px;color:var(--text-dim);">Stronger, 1-2yr life</span></button>
          <button class="mat-btn" data-ctx="prototype" data-mat="Nylon" style="flex:1; padding: 10px; font-size: 12px; border: 2px solid ${exerciseState.selectedPrototype === 'Nylon' ? 'var(--accent)' : 'var(--border)'};">Nylon<br><span style="font-size:10px;color:var(--text-dim);">Best print strength, hard to print</span></button>
        </div>
      </div>

      <div>
        <div style="font-size: 12px; font-weight: 600; margin-bottom: 6px;">For Production (Final Build):</div>
        <div style="display: flex; gap: 8px;">
          <button class="mat-btn" data-ctx="production" data-mat="PLA" style="flex:1; padding: 10px; font-size: 12px; border: 2px solid ${exerciseState.selectedProduction === 'PLA' ? 'var(--accent)' : 'var(--border)'};">PLA<br><span style="font-size:10px;color:var(--text-dim);">Cheap, fragile</span></button>
          <button class="mat-btn" data-ctx="production" data-mat="Aluminum" style="flex:1; padding: 10px; font-size: 12px; border: 2px solid ${exerciseState.selectedProduction === 'Aluminum' ? 'var(--accent)' : 'var(--border)'};">Aluminum<br><span style="font-size:10px;color:var(--text-dim);">Strong, light, decades</span></button>
          <button class="mat-btn" data-ctx="production" data-mat="Steel" style="flex:1; padding: 10px; font-size: 12px; border: 2px solid ${exerciseState.selectedProduction === 'Steel' ? 'var(--accent)' : 'var(--border)'};">Steel<br><span style="font-size:10px;color:var(--text-dim);">Very strong, heavy</span></button>
        </div>
      </div>
    </div>
  `;

  canvas.querySelectorAll('.mat-btn').forEach(btn => {
    btn.onclick = () => {
      const ctx = btn.dataset.ctx;
      const mat = btn.dataset.mat;
      if (ctx === 'prototype') exerciseState.selectedPrototype = mat;
      else exerciseState.selectedProduction = mat;
      renderMaterialQuizExercise(canvas, sliders, exercise);
    };
  });

  sliders.innerHTML = '';

  const protoCorrect = exerciseState.selectedPrototype === exerciseState.answers.prototype;
  const prodCorrect = exerciseState.selectedProduction === exerciseState.answers.production;
  const status = document.getElementById('exercise-status');
  status.innerHTML = `<strong>Prototype:</strong> ${exerciseState.selectedPrototype || '?'} <span style="color:${protoCorrect ? 'var(--success)' : exerciseState.selectedPrototype ? 'var(--error)' : 'var(--text-dim)'};">${protoCorrect ? 'Correct' : exerciseState.selectedPrototype ? 'Try again' : 'Select one'}</span> |
    <strong>Production:</strong> ${exerciseState.selectedProduction || '?'} <span style="color:${prodCorrect ? 'var(--success)' : exerciseState.selectedProduction ? 'var(--error)' : 'var(--text-dim)'};">${prodCorrect ? 'Correct' : exerciseState.selectedProduction ? 'Try again' : 'Select one'}</span>`;

  checkExerciseSuccess(exercise);
}

function renderToleranceExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="tol-cvs" width="500" height="250" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('tol-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const n = exerciseState.partCount || 5;
    const t = exerciseState.toleranceEach || 0.3;
    const gap = exerciseState.clearanceGap || 2.0;

    const worstCase = n * t;
    const statistical = Math.sqrt(n) * t;

    // Draw parts stack
    const partH = Math.min(30, (H - 80) / n);
    const startY = 30;
    for (let i = 0; i < n; i++) {
      const y = startY + i * (partH + 2);
      const partW = 100 + Math.random() * 20 - 10; // visual variation

      ctx.fillStyle = '#4fc3f788';
      ctx.fillRect(50, y, partW, partH);
      ctx.strokeStyle = '#4fc3f7';
      ctx.lineWidth = 1;
      ctx.strokeRect(50, y, partW, partH);

      // Tolerance range
      ctx.fillStyle = '#ffa72688';
      ctx.fillRect(50 + partW - t * 100, y, t * 200, partH);
    }

    // Gap indicator
    const stackEnd = startY + n * (partH + 2);
    ctx.strokeStyle = '#66bb6a';
    ctx.lineWidth = 2;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    ctx.moveTo(50, stackEnd + 5);
    ctx.lineTo(200, stackEnd + 5);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.fillStyle = '#66bb6a';
    ctx.font = '11px monospace';
    ctx.fillText(`Gap: ${gap}mm`, 55, stackEnd + 20);

    // Results
    ctx.fillStyle = '#fff';
    ctx.font = '12px monospace';
    ctx.fillText(`Worst case: ${n} x ${t}mm = ${worstCase.toFixed(2)}mm`, 220, 50);
    ctx.fillText(`Statistical: sqrt(${n}) x ${t}mm = ${statistical.toFixed(2)}mm`, 220, 70);

    const wcRatio = worstCase / gap * 100;
    const stRatio = statistical / gap * 100;
    ctx.fillStyle = wcRatio > 100 ? '#ef5350' : wcRatio > 75 ? '#ffa726' : '#66bb6a';
    ctx.fillText(`WC uses ${wcRatio.toFixed(0)}% of gap`, 220, 100);
    ctx.fillStyle = stRatio > 100 ? '#ef5350' : stRatio > 75 ? '#ffa726' : '#66bb6a';
    ctx.fillText(`Stat uses ${stRatio.toFixed(0)}% of gap`, 220, 120);

    exerciseState.worstCase = worstCase;
    exerciseState.statistical = statistical;

    const status = document.getElementById('exercise-status');
    status.innerHTML = `<strong>Parts:</strong> ${n} | <strong>Tolerance:</strong> +/-${t}mm | <strong>Worst case:</strong> ${worstCase.toFixed(2)}mm |
      <strong>Statistical:</strong> ${statistical.toFixed(2)}mm | <strong>Gap:</strong> ${gap}mm |
      <span style="color:${worstCase < gap ? 'var(--success)' : 'var(--error)'};">${worstCase < gap ? 'Fits (worst case)' : 'Too tight!'}</span>`;

    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Part Count <span class="slider-value" id="tol-n-val">${exerciseState.partCount}</span></label>
      <input type="range" id="tol-n" min="2" max="12" step="1" value="${exerciseState.partCount}"></div>
    <div class="slider-group"><label>Tolerance +/- <span class="slider-value" id="tol-t-val">${exerciseState.toleranceEach}mm</span></label>
      <input type="range" id="tol-t" min="0.05" max="0.5" step="0.05" value="${exerciseState.toleranceEach}"></div>
    <div class="slider-group"><label>Clearance Gap <span class="slider-value" id="tol-g-val">${exerciseState.clearanceGap}mm</span></label>
      <input type="range" id="tol-g" min="0.5" max="5" step="0.1" value="${exerciseState.clearanceGap}"></div>
  </div>`;

  document.getElementById('tol-n').oninput = (e) => { exerciseState.partCount = parseInt(e.target.value); document.getElementById('tol-n-val').textContent = e.target.value; draw(); };
  document.getElementById('tol-t').oninput = (e) => { exerciseState.toleranceEach = parseFloat(e.target.value); document.getElementById('tol-t-val').textContent = e.target.value + 'mm'; draw(); };
  document.getElementById('tol-g').oninput = (e) => { exerciseState.clearanceGap = parseFloat(e.target.value); document.getElementById('tol-g-val').textContent = e.target.value + 'mm'; draw(); };
  draw();
}

function renderPhaseSyncExercise(canvas, sliders, exercise) {
  canvas.innerHTML = '<canvas id="sync-cvs" width="500" height="250" style="background:#111;width:100%;"></canvas>';

  function draw() {
    const cvs = document.getElementById('sync-cvs');
    if (!cvs) return;
    const ctx = cvs.getContext('2d');
    const W = cvs.width, H = cvs.height;
    ctx.clearRect(0, 0, W, H);

    const A1 = exerciseState.amplitude1 || 2.0;
    const A2 = exerciseState.amplitude2 || 1.5;
    const phi = exerciseState.phaseDiff || 0;
    const freq = exerciseState.frequency || 1.0;

    const maxA = A1 + A2;
    const scaleY = (H - 40) / (2 * maxA);
    const cy = H / 2;

    // Wave 1
    ctx.strokeStyle = '#4fc3f7';
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let x = 0; x < W; x++) {
      const t = (x / W) * 4 * Math.PI;
      const y = cy - A1 * Math.sin(freq * t) * scaleY;
      if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    ctx.stroke();

    // Wave 2
    ctx.strokeStyle = '#66bb6a';
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let x = 0; x < W; x++) {
      const t = (x / W) * 4 * Math.PI;
      const y = cy - A2 * Math.sin(freq * t + phi) * scaleY;
      if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    ctx.stroke();

    // Combined wave
    ctx.strokeStyle = '#ffa726';
    ctx.lineWidth = 2;
    ctx.beginPath();
    let maxCombined = 0;
    for (let x = 0; x < W; x++) {
      const t = (x / W) * 4 * Math.PI;
      const combined = A1 * Math.sin(freq * t) + A2 * Math.sin(freq * t + phi);
      maxCombined = Math.max(maxCombined, Math.abs(combined));
      const y = cy - combined * scaleY;
      if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    ctx.stroke();

    // Labels
    ctx.fillStyle = '#4fc3f7';
    ctx.font = '10px monospace';
    ctx.fillText(`Wave 1: A=${A1}`, 10, 15);
    ctx.fillStyle = '#66bb6a';
    ctx.fillText(`Wave 2: A=${A2}`, 10, 28);
    ctx.fillStyle = '#ffa726';
    ctx.fillText(`Combined: max A=${maxCombined.toFixed(2)}`, 10, 41);

    const theoreticalMax = A1 + A2;
    const efficiency = (maxCombined / theoreticalMax * 100);

    const status = document.getElementById('exercise-status');
    status.innerHTML = `<strong>Phase diff:</strong> ${(phi / Math.PI).toFixed(2)}pi (${(phi * 180 / Math.PI).toFixed(0)} deg) |
      <strong>Combined amp:</strong> ${maxCombined.toFixed(2)} / ${theoreticalMax.toFixed(1)} max |
      <strong>Efficiency:</strong> <span style="color:${efficiency > 95 ? 'var(--success)' : efficiency > 70 ? 'var(--warning)' : 'var(--error)'};">${efficiency.toFixed(0)}%</span>`;

    checkExerciseSuccess(exercise);
  }

  sliders.innerHTML = `<div class="slider-panel-inner">
    <div class="slider-group"><label>Amplitude 1 <span class="slider-value" id="ps-a1-val">${exerciseState.amplitude1}</span></label>
      <input type="range" id="ps-a1" min="0.5" max="3" step="0.1" value="${exerciseState.amplitude1}"></div>
    <div class="slider-group"><label>Amplitude 2 <span class="slider-value" id="ps-a2-val">${exerciseState.amplitude2}</span></label>
      <input type="range" id="ps-a2" min="0.5" max="3" step="0.1" value="${exerciseState.amplitude2}"></div>
    <div class="slider-group"><label>Phase Diff <span class="slider-value" id="ps-ph-val">${(exerciseState.phaseDiff / Math.PI).toFixed(2)}pi</span></label>
      <input type="range" id="ps-ph" min="0" max="6.28" step="0.05" value="${exerciseState.phaseDiff}"></div>
  </div>`;

  document.getElementById('ps-a1').oninput = (e) => { exerciseState.amplitude1 = parseFloat(e.target.value); document.getElementById('ps-a1-val').textContent = e.target.value; draw(); };
  document.getElementById('ps-a2').oninput = (e) => { exerciseState.amplitude2 = parseFloat(e.target.value); document.getElementById('ps-a2-val').textContent = e.target.value; draw(); };
  document.getElementById('ps-ph').oninput = (e) => { exerciseState.phaseDiff = parseFloat(e.target.value); document.getElementById('ps-ph-val').textContent = (parseFloat(e.target.value) / Math.PI).toFixed(2) + 'pi'; draw(); };
  draw();
}

function renderTutorialLinks(exercise) {
  const container = document.getElementById('exercise-tutorials');
  if (!container || !exercise.tutorialContexts) return;

  const html = renderMultiContextLinks(exercise.tutorialContexts, { maxItems: 4, compact: true });
  if (html) {
    container.innerHTML = `
      <div class="section-title" style="font-size:11px;">LEARN MORE</div>
      ${html}
    `;
  }
}

function checkExerciseSuccess(exercise) {
  const btn = document.getElementById('complete-exercise');
  if (!btn) return;

  let success = false;

  switch (exercise.successCondition) {
    case 'grashof':
      success = checkGrashof(exerciseState.ground, exerciseState.crank, exerciseState.coupler, exerciseState.rocker);
      break;
    case 'swing-near-20': {
      // Approximate: swing angle roughly proportional to crank/ground ratio
      const ratio = exerciseState.crank / exerciseState.ground;
      const approxSwing = ratio * 360 / Math.PI; // simplified
      success = checkGrashof(exerciseState.ground, exerciseState.crank, exerciseState.coupler, exerciseState.rocker) && approxSwing > 15 && approxSwing < 25;
      break;
    }
    case 'dwell-above-90':
      success = (exerciseState.dwellAngle || 0) >= 90;
      break;
    case 'breathing-ratio': {
      const rise = exerciseState.riseAngle || 200;
      const fall = exerciseState.fallAngle || 100;
      const ratio = rise / Math.max(fall, 1);
      success = ratio >= 2.5 && ratio <= 3.5;
      break;
    }
    case 'stroke-40':
      success = (exerciseState.crankRadius || 0) === 20;
      break;
    case 'sway-15':
      success = Math.abs((exerciseState.offset || 0) * 2 - 15) < 0.5;
      break;
    case 'ratio-6': {
      const ratio = (exerciseState.drivenTeeth || 1) / (exerciseState.driverTeeth || 1);
      success = Math.abs(ratio - 6) < 0.5;
      break;
    }
    case 'friction-understood':
      success = (exerciseState.pulleys || 0) >= 9;
      break;
    case 'fits-80':
      success = (exerciseState.ground || 200) <= 80;
      break;
    case 'cam-count-18': {
      const total = exerciseState.totalCams || 0;
      const expected = (exerciseState.waveSources || 0) * (exerciseState.elementsPerSource || 0);
      success = total === expected && total === 18;
      break;
    }
    case 'mechanism-chosen-correct': {
      const smooth = exerciseState.smoothness || 0;
      const steps = exerciseState.phaseSteps || 6;
      const recommended = smooth > 0.6 || steps > 12 ? 'helix' : 'disc';
      success = exerciseState.mechanismChoice === recommended;
      break;
    }
    case 'power-correct': {
      const needed = (exerciseState.camCount || 0) * (exerciseState.powerPerCam || 0);
      const required = needed * (exerciseState.safetyFactor || 1);
      const sufficient = (exerciseState.motorPower || 0) >= required;
      const correctAnswer = sufficient ? 'sufficient' : 'insufficient';
      success = exerciseState.answer === correctAnswer;
      break;
    }
    case 'ratio-7.5': {
      const ratio = (exerciseState.drivenTeeth || 1) / (exerciseState.driverTeeth || 1);
      success = Math.abs(ratio - 7.5) < 0.3;
      break;
    }
    case 'friction-below-70': {
      const eff = Math.pow(1 - (exerciseState.frictionPerPulley || 0.04), exerciseState.pulleys || 0) * 100;
      success = eff < 70 && (exerciseState.pulleys || 0) >= 9;
      break;
    }
    case 'material-correct': {
      success = exerciseState.selectedPrototype === exerciseState.answers?.prototype &&
                exerciseState.selectedProduction === exerciseState.answers?.production;
      break;
    }
    case 'tolerance-calculated': {
      const wc = (exerciseState.partCount || 0) * (exerciseState.toleranceEach || 0);
      success = wc > 0 && wc < (exerciseState.clearanceGap || 2) && (exerciseState.partCount || 0) >= 5;
      break;
    }
    case 'max-amplitude': {
      const maxAmp = (exerciseState.amplitude1 || 0) + (exerciseState.amplitude2 || 0);
      // Check if phase diff is near 0 or 2pi for constructive interference
      const phi = exerciseState.phaseDiff || 0;
      const combined = Math.abs(Math.cos(phi / 2)) * maxAmp;
      success = combined > maxAmp * 0.95;
      break;
    }
  }

  btn.disabled = !success;
  if (success) {
    btn.style.opacity = '1';
    btn.textContent = 'Complete!';
  } else {
    btn.style.opacity = '0.5';
    btn.textContent = 'Complete (achieve goal first)';
  }
}

async function completeExercise() {
  if (!currentExercise) return;

  await addTaskCompletion({
    id: 'task-' + Date.now().toString(36),
    type: currentExercise.id,
    stage: 'learn',
    params: exerciseState,
    completedAt: new Date().toISOString(),
    xpEarned: currentExercise.xp
  });

  await awardXP('task-complete', 'learn', currentExercise.skillTag);
  await recordTaskCompletion(currentExercise.skillTag);

  // Check daily task match
  const profile = getProfile();
  if (profile.dailyTasks?.tasks) {
    const dailyMatch = profile.dailyTasks.tasks.find(t =>
      t.type === currentExercise.id && !t.completed
    );
    if (dailyMatch) {
      dailyMatch.completed = true;
      profile.dailyTasks.completedCount = (profile.dailyTasks.completedCount || 0) + 1;
      const allDone = profile.dailyTasks.tasks.every(t => t.completed);
      if (allDone && !profile.dailyTasks.dailyBonusAwarded) {
        profile.dailyTasks.dailyBonusAwarded = true;
        await awardXP('daily-complete');
        showToast('All daily tasks complete! +25 XP bonus!', 'success');
      }
      await saveProfile();
    }
  }

  showToast(`Exercise complete! +${currentExercise.xp} XP`, 'success');

  // Show "What I Learned" card
  const workspace = document.getElementById('exercise-workspace');
  if (workspace && currentExercise.learnedFact) {
    const learnedCard = document.createElement('div');
    learnedCard.className = 'mechanism-info exercise-success';
    learnedCard.style.marginTop = '12px';
    learnedCard.innerHTML = `<strong>What You Learned:</strong><br>${currentExercise.learnedFact}`;
    workspace.appendChild(learnedCard);
  }

  currentExercise = null;
  updateSidebar();
}

function updateSidebar() {
  const profile = getProfile();
  const sections = [];

  sections.push({
    title: 'Your Skills',
    html: Object.entries(profile?.journey?.skillLevels || {}).map(([skill, level]) => {
      const label = MASTERY_LABELS[Math.min(level, MASTERY_LABELS.length - 1)];
      const color = level >= 4 ? 'var(--success)' : level >= 2 ? 'var(--warning)' : 'var(--text-dim)';
      return `<div class="text-sm" style="padding:2px 0;">
        <span style="display:inline-block;width:90px;">${skill}</span>
        <span>${'\u25A0'.repeat(level)}${'\u25A1'.repeat(5 - level)}</span>
        <span style="color:${color};"> ${label}</span>
      </div>`;
    }).join('')
  });

  // Guidance
  const guidance = createGuidancePanel('learn-exercises');
  if (guidance) sections.push({ element: guidance });

  const extHtml = renderMultiContextLinks(
    currentExercise ? (currentExercise.tutorialContexts || ['exercises']) : ['exercises'],
    { maxItems: 3, compact: true }
  );
  if (extHtml) {
    sections.push({ title: 'Related Tools', html: extHtml });
  }

  sections.push({ element: createClaudePanel(null) });
  renderSidebar(sections);
}

// ────────────────────────────────────────────────────
// p5.js Editor integration for exercises
// ────────────────────────────────────────────────────

const EXERCISE_SKETCH_MAP = {
  'ex-grashof-visual': 'four-bar-linkage',
  'ex-match-motion': 'four-bar-linkage',
  'ex-cam-dwell': 'cam-profile',
  'ex-cam-profile': 'cam-profile',
  'ex-gear-ratio': 'gear-train',
  'ex-friction-cascade': 'friction-cascade',
  'ex-tolerance-stack': 'tolerance-stack',
  'ex-design-sync-waves': 'wave-superposition',
  'ex-wave-to-cams': 'cam-profile',
  'ex-gear-ratio-calc': 'gear-train',
  'ex-motor-power': 'friction-cascade',
  'ex-design-nodding': 'cam-profile',
};

const CATEGORY_SKETCH_MAP = {
  'Four-Bar Linkages': 'four-bar-linkage',
  'Cams & Profiles': 'cam-profile',
  'Slider-Crank & Eccentric': 'four-bar-linkage',
  'Gears & Trains': 'gear-train',
  'Physics & Friction': 'friction-cascade',
  'Design Thinking': 'motion-vocabulary',
  'Mechanize Skills': 'cam-profile',
  'Simulate Skills': 'friction-cascade',
  'Build Skills': 'tolerance-stack',
  'Design Challenges': 'wave-superposition',
};

function openExerciseInP5(exercise) {
  // Try exercise-specific sketch first, then category fallback
  const sketchId = EXERCISE_SKETCH_MAP[exercise.id] || CATEGORY_SKETCH_MAP[exercise.category];
  if (sketchId) {
    const sketch = getSketchById(sketchId);
    if (sketch) {
      openInP5Editor(sketch.code, `${exercise.title} — ${sketch.title}`);
      return;
    }
  }

  // Fallback: generate from exercise parameters
  if (exercise.type === 'interactive-fourbar' && exerciseState.params) {
    openInP5Editor(
      fourBarToP5Sketch(exerciseState.params),
      `${exercise.title} — Four-Bar Linkage`
    );
  } else if (exercise.type === 'interactive-cam') {
    openInP5Editor(
      camToP5Sketch({ base: 30, rise: 15, dwell: 90 }),
      `${exercise.title} — Cam Profile`
    );
  } else if (exercise.skillTag === 'simulation') {
    openInP5Editor(
      frictionToP5Sketch(0.95),
      `${exercise.title} — Physics Visualization`
    );
  } else {
    // Generic wave sketch as ultimate fallback
    const waveSk = getSketchById('wave-superposition');
    if (waveSk) openInP5Editor(waveSk.code, `${exercise.title} — Wave Exploration`);
    else showToast('No p5 sketch available for this exercise type', 'info');
  }
}

export function unmount() {
  currentExercise = null;
  exerciseState = {};
}
