// Contextual guidance system — dismissable "why this matters" + "what to do" panels
// Shows expanded on first visit, collapsed to "?" icon after dismissal
// Integrated into sidebar for every stage/tab

import { getProfile, updateProfile } from '../state.js';

// ────────────────────────────────────────────────────
// GUIDANCE CONTENT DATABASE
// ────────────────────────────────────────────────────

const GUIDANCE = {
  // ── Experiment Mode ──
  'exp-wavelab': {
    title: 'Wave Lab',
    why: 'Waves are the foundation of Margolin-style kinetic sculpture. Every motion — rising, falling, swaying — is a wave. By combining waves you create interference patterns that feel organic and alive.',
    whatToDo: [
      'Add 2-3 wave components with different frequencies',
      'Adjust amplitude (A) to control how dramatic each wave is',
      'Change phase (φ) to offset waves in time',
      'Watch how superposition creates complex motion from simple parts',
      'Open in p5 Editor for code-level control and sharing',
    ],
    connections: [
      { text: 'Wave frequency → cam rotation speed', icon: '⚙' },
      { text: 'Wave amplitude → follower travel distance', icon: '↕' },
      { text: 'Phase offset → cam angular offset on shaft', icon: '🔄' },
      { text: 'p5 Editor → code your own wave math', icon: '<>' },
    ],
    tip: 'Margolin: "The wave is the fundamental unit of kinetic art. Everything else is just a way to make waves."',
  },
  'exp-patterns': {
    title: 'Patterns',
    why: 'Parametric curves like roses, Lissajous, and spirographs aren\'t just pretty — they reveal the motion paths that mechanisms naturally produce. Understanding these patterns helps you design backwards: from desired motion to mechanism.',
    whatToDo: [
      'Try different rose curves (n parameter) to see petal counts',
      'Use Lissajous figures to understand coupled oscillation',
      'Spirograph patterns = what gear trains actually draw',
      'Fourier composition shows how any motion breaks into sine waves',
      'Export to p5 Editor to customize curves and share',
    ],
    connections: [
      { text: 'Rose curves → cam profile shapes', icon: '🌹' },
      { text: 'Lissajous → coupled oscillators (2 motors)', icon: '∞' },
      { text: 'Spirograph → gear train output paths', icon: '⚙' },
      { text: 'Fourier → the core Margolin decomposition principle', icon: '〰' },
      { text: 'p5 Editor → shareable animated patterns', icon: '<>' },
    ],
    tip: 'Every closed curve can be decomposed into Fourier components. This is how Margolin converts art into engineering.',
  },
  'exp-waves3d': {
    title: '3D Waves',
    why: 'This is where your sculpture design begins. The 3D wave surface represents the actual motion field of your kinetic artwork — each point\'s height at each moment in time is what the physical elements will do.',
    whatToDo: [
      'Start with 2 perpendicular waves for a Margolin-style grid',
      'Add more waves with unique directions and speeds',
      'Try "Product" interaction for dramatic interference',
      'Click "Use in Build Mode" when you have a wave you want to build',
      'Try the 3D version in p5.js WebGL for shareable code',
    ],
    connections: [
      { text: 'Wave count → number of cams/helices needed', icon: '📐' },
      { text: 'Wave direction → cam shaft orientation', icon: '→' },
      { text: 'Interaction mode → mechanism complexity', icon: '🔗' },
      { text: 'p5 WEBGL → code 3D wave surfaces', icon: '<>' },
    ],
    tip: 'The Margolin equation: h(x,y,t) = Σ Aᵢ·sin(kᵢ·dᵢ(x,y) - ωᵢt + φᵢ). Each term = one cam shaft or helix.',
  },
  'exp-mechanisms': {
    title: 'Mechanism Viewer',
    why: 'Seeing how linkages, cams, and drives move builds intuition for what mechanisms can produce which motions. This visual library is your reference when choosing mechanisms in Build mode.',
    whatToDo: [
      'Watch how four-bar linkages create non-circular paths',
      'See how cam profiles translate to follower motion',
      'Compare slider-crank vs scotch-yoke output',
      'Note which mechanisms produce smooth vs jerky motion',
    ],
    connections: [
      { text: 'Four-bar → complex paths from simple rotation', icon: '◇' },
      { text: 'Cam → arbitrary motion profiles (dwell, rise, fall)', icon: '⬭' },
      { text: 'Slider-crank → linear reciprocating motion', icon: '↔' },
    ],
    tip: 'Four-bar linkages are the "atoms" of mechanism design. Master them and you can build anything.',
  },

  // ── Build Mode: Mechanize ──
  'build-mechanize': {
    title: 'Mechanize',
    why: 'This is the critical bridge between art and engineering. You\'re choosing HOW to physically produce the wave motion you designed. Different mechanism families have different strengths — the right choice determines whether your sculpture works.',
    whatToDo: [
      'Review the ranked mechanism recommendations',
      'Consider complexity vs precision tradeoffs',
      'Select a family and configure its parameters',
      'Save your choice to unlock Simulate',
      'Animate your mechanism in p5 Editor to verify motion',
    ],
    connections: [
      { text: 'Camshaft → one cam per wave component, vertical stack', icon: '🪵' },
      { text: 'Helix → continuous phase gradient, aluminum spiral', icon: '🌀' },
      { text: 'Eccentric → simplest drive, 2 parts per element', icon: '⭕' },
      { text: 'String-weave → waves pass through each other', icon: '🕸' },
      { text: 'Fourier sprocket → exact frequency ratios', icon: '⛓' },
      { text: 'p5 Editor → mechanism animation sandbox', icon: '<>' },
    ],
    tip: 'Margolin chooses mechanisms based on the wave math, not aesthetics. The math dictates the mechanism. Trust the recommendations.',
  },

  // ── Build Mode: Simulate ──
  'build-simulate': {
    title: 'Simulate',
    why: 'Every physical sculpture must pass physics checks before fabrication. Skipping validation means wasted material, broken parts, and motors that stall. The 40+ checks here catch problems before they become expensive.',
    whatToDo: [
      'Run "All Checks" first to get a baseline',
      'Fix critical failures (red) before anything else',
      'Review aesthetic checks for design refinement',
      'Save results to unlock the Build stage',
      'Visualize physics checks in p5 Editor for deeper understanding',
    ],
    connections: [
      { text: 'Power Budget → motor won\'t stall under load', icon: '⚡' },
      { text: 'Friction Cascade → max 9 pulleys in series', icon: '🧲' },
      { text: 'Golden Ratio → harmonious visual proportions', icon: '🎨' },
      { text: 'Tolerance Stack → parts will actually fit together', icon: '📏' },
      { text: 'Resonance → sculpture won\'t shake itself apart', icon: '🌀' },
      { text: 'p5 Editor → interactive physics sketches', icon: '<>' },
    ],
    tip: 'Margolin\'s rule: design for 10x the expected load. If your math says you need 0.5W, use a 5W motor.',
  },

  // ── Build Mode: Build ──
  'build-build': {
    title: 'Build',
    why: 'Material selection determines whether your sculpture lasts 6 months or 20 years. The right material for each component depends on stress, environment, aesthetics, and budget. This stage turns your validated design into a fabrication plan.',
    whatToDo: [
      'Choose Prototype (3D print) for first iteration',
      'Select materials per component based on role',
      'Generate OpenSCAD code for 3D printable parts',
      'Review the Bill of Materials before ordering',
    ],
    connections: [
      { text: 'PLA → fast prototyping, indoor only, 6-12mo life', icon: '🖨' },
      { text: 'Steel → shafts, high-stress, decades of life', icon: '🔩' },
      { text: 'Plywood → Margolin\'s cam material (bandsaw-cut)', icon: '🪵' },
      { text: 'Cherry wood → warm aesthetic for hanging elements', icon: '🌳' },
      { text: 'Delrin/POM → best gear material (not 3D printable)', icon: '⚙' },
    ],
    tip: 'Start with a 3D printed prototype. Iterate 2-3 times before committing to metal or wood. Margolin prototypes in plywood first.',
  },

  // ── Build Mode: Iterate ──
  'build-iterate': {
    title: 'Iterate',
    why: 'No kinetic sculpture works perfectly on the first build. Iteration is where you discover the gap between theory and reality — binding points, unexpected friction, visual timing that doesn\'t feel right. This is normal and expected.',
    whatToDo: [
      'Follow the First-Run Protocol (hand rotate first)',
      'Document what works and what doesn\'t',
      'Change ONE variable at a time',
      'Log each test run with observations',
    ],
    connections: [
      { text: 'Binding → check clearances, add 0.1mm', icon: '🔧' },
      { text: 'Motor stalls → reduce load or add gear reduction', icon: '⚡' },
      { text: 'Wobble → check balance, add counterweight', icon: '⚖' },
      { text: 'Timing feels wrong → adjust phase offsets', icon: '⏱' },
    ],
    tip: 'Margolin\'s iteration rule: "If it doesn\'t work, the math is wrong or the tolerance is wrong. Never both."',
  },

  // ── Learn Mode ──
  'learn-dashboard': {
    title: 'Dashboard',
    why: 'Tracking your learning progress helps you focus on the skills that matter most for your next project. The skill radar shows where you\'re strong and where to grow.',
    whatToDo: [
      'Check your skill levels and identify gaps',
      'Do exercises in your weakest skill areas',
      'Aim for daily streaks to build consistent practice',
      'Review completed exercises to reinforce knowledge',
    ],
    connections: [],
    tip: 'Focus on one skill area per week. Deep practice beats surface coverage.',
  },
  'learn-exercises': {
    title: 'Exercises',
    why: 'These exercises teach the specific skills needed for each stage of the Build pipeline. Mechanize skills help you choose mechanisms. Simulate skills help you validate designs. Build skills help you select materials.',
    whatToDo: [
      'Start with exercises matching your current Build stage',
      'Read the "Learned Fact" after each exercise',
      'Try different difficulty levels as you improve',
      'Apply what you learn directly to your project',
      'Deepen understanding by coding exercises in p5 Editor',
    ],
    connections: [
      { text: 'Four-Bar exercises → Mechanize stage skills', icon: '◇' },
      { text: 'Cam exercises → motion profile design', icon: '⬭' },
      { text: 'Friction exercises → Simulate stage validation', icon: '🧲' },
      { text: 'Material exercises → Build stage decisions', icon: '🧱' },
      { text: 'p5 Editor → code exercises from scratch', icon: '<>' },
    ],
    tip: 'Each exercise teaches a single concept. Master one before moving to the next.',
  },
  'learn-skills': {
    title: 'Skills',
    why: 'The skill tree maps directly to the Build pipeline. Higher skill levels unlock more advanced mechanism options and give you confidence to attempt complex sculptures.',
    whatToDo: [
      'Review each skill area and your current level',
      'Identify which skills your next project needs',
      'Focus exercises on those specific skills',
    ],
    connections: [],
    tip: 'Skills compound: understanding four-bar linkages makes understanding cams easier, which makes understanding full mechanisms easier.',
  },
};

// ────────────────────────────────────────────────────
// GUIDANCE COMPONENT
// ────────────────────────────────────────────────────

/**
 * Creates a guidance panel element for the given context.
 * @param {string} contextId - Key into GUIDANCE database (e.g. 'build-mechanize')
 * @returns {HTMLElement|null} - Guidance panel element, or null if no guidance exists
 */
export function createGuidancePanel(contextId) {
  const content = GUIDANCE[contextId];
  if (!content) return null;

  const profile = getProfile();
  const dismissed = profile?.guidanceDismissed || {};
  const isCollapsed = dismissed[contextId] === true;

  const wrapper = document.createElement('div');
  wrapper.className = 'guidance-wrapper';

  if (isCollapsed) {
    // Collapsed: just a "?" button to expand
    wrapper.innerHTML = `
      <button class="guidance-expand-btn" title="Show guidance: ${content.title}">
        <span style="font-size: 13px;">?</span>
        <span style="font-size: 10px; margin-left: 4px;">${content.title}</span>
      </button>
    `;
    wrapper.querySelector('.guidance-expand-btn').onclick = () => {
      toggleGuidance(contextId, false);
      // Re-render — the calling code should handle this via event
      window.dispatchEvent(new CustomEvent('guidance-toggled', { detail: { contextId, collapsed: false } }));
    };
    return wrapper;
  }

  // Expanded: full guidance panel
  let html = `
    <div class="guidance-panel">
      <div class="guidance-header">
        <span class="guidance-icon">💡</span>
        <span class="guidance-title">${content.title}</span>
        <button class="guidance-dismiss" title="Dismiss">&times;</button>
      </div>
      <div class="guidance-body">
        <div class="guidance-section">
          <div class="guidance-label">Why this matters</div>
          <div class="guidance-text">${content.why}</div>
        </div>
        <div class="guidance-section">
          <div class="guidance-label">What to do</div>
          <ul class="guidance-list">
            ${content.whatToDo.map(item => `<li>${item}</li>`).join('')}
          </ul>
        </div>
  `;

  if (content.connections.length > 0) {
    html += `
      <div class="guidance-section">
        <div class="guidance-label">Connections</div>
        <div class="guidance-connections">
          ${content.connections.map(c => `
            <div class="guidance-connection">
              <span class="guidance-conn-icon">${c.icon}</span>
              <span>${c.text}</span>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  }

  if (content.tip) {
    html += `
      <div class="guidance-tip">
        <span class="guidance-tip-icon">💬</span>
        <span>${content.tip}</span>
      </div>
    `;
  }

  html += `
      </div>
    </div>
  `;

  wrapper.innerHTML = html;

  // Dismiss handler
  wrapper.querySelector('.guidance-dismiss').onclick = () => {
    toggleGuidance(contextId, true);
    window.dispatchEvent(new CustomEvent('guidance-toggled', { detail: { contextId, collapsed: true } }));
  };

  return wrapper;
}

/**
 * Toggle guidance dismissed state for a context.
 */
function toggleGuidance(contextId, collapsed) {
  const profile = getProfile();
  if (!profile) return;
  if (!profile.guidanceDismissed) profile.guidanceDismissed = {};
  profile.guidanceDismissed[contextId] = collapsed;
  updateProfile({ guidanceDismissed: profile.guidanceDismissed });
}

/**
 * Check if guidance exists for a context.
 */
export function hasGuidance(contextId) {
  return contextId in GUIDANCE;
}

/**
 * Get guidance content for a context (for external use).
 */
export function getGuidanceContent(contextId) {
  return GUIDANCE[contextId] || null;
}
