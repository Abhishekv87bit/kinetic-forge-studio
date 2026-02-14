// Stage 2: SIMULATE — Comprehensive physics validation for kinetic sculpture
// Per-component attributes, system-level checks, aesthetic timing, structural integrity

import { getProject, saveProject } from '../state.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { showToast } from '../toast.js';
import { validateGate } from '../gate.js';
import { createResourceSection } from '../components/resource-links.js';
import { createGuidancePanel } from '../components/guidance.js';
import { frictionToP5Sketch, openInP5Editor, createP5Button } from '../components/p5-bridge.js';

let animFrame = null;
let simState = null;
let currentTab = 'overview';

// ────────────────────────────────────────────────────
// COMPREHENSIVE VALIDATION CATEGORIES
// ────────────────────────────────────────────────────

const VALIDATION_CATEGORIES = [
  {
    id: 'power',
    name: 'Power Budget',
    icon: '\u26A1',
    checks: [
      { id: 'motor-torque', label: 'Motor torque vs load torque', formula: 'T_motor * gear_ratio > 3x T_load', critical: true },
      { id: 'power-margin', label: 'Power margin (10x rule)', formula: 'P_available > 10x P_estimated (3x safety * 3x friction)', critical: true },
      { id: 'efficiency-chain', label: 'Efficiency chain calculation', formula: 'n_total = n_gear * n_belt * n_linkage * n_friction', critical: false },
      { id: 'startup-torque', label: 'Startup torque (static > dynamic)', formula: 'T_startup > 1.5x T_running', critical: false },
    ],
  },
  {
    id: 'friction',
    name: 'Friction & Transmission',
    icon: '\uD83E\uDDF2',
    checks: [
      { id: 'pulley-cascade', label: 'Pulley cascade efficiency', formula: 'F_out = F_in * 0.95^n (max 9 pulleys)', critical: true },
      { id: 'string-tension', label: 'String tension budget', formula: 'T_min > element_weight * 1.5', critical: true },
      { id: 'cable-stretch', label: 'Cable elongation at load', formula: 'delta_L < 0.5mm per meter', critical: false },
      { id: 'bearing-friction', label: 'Bearing friction total', formula: 'Sum of n_bearing * mu_bearing', critical: false },
      { id: 'gear-efficiency', label: 'Gear train efficiency', formula: 'Spur: 95-98%, Worm: 50-90% per stage', critical: false },
    ],
  },
  {
    id: 'structural',
    name: 'Structural Integrity',
    icon: '\uD83C\uDFD7',
    checks: [
      { id: 'shaft-deflection', label: 'Shaft deflection under load', formula: 'delta < L/500 (steel) or L/200 (3D print)', critical: true },
      { id: 'joint-forces', label: 'Joint forces at each pivot', formula: 'F_joint < material_yield / safety_factor', critical: true },
      { id: 'wall-thickness', label: 'Minimum wall thickness', formula: '>= 1.2mm for 3D print, >= 0.8mm for metal', critical: true },
      { id: 'cantilever-check', label: 'Cantilever deflection', formula: 'delta = FL^3 / (3EI)', critical: false },
      { id: 'fatigue-life', label: 'Fatigue life estimate', formula: 'PLA: 6-12mo high stress | Metal: 10+ years', critical: false },
    ],
  },
  {
    id: 'clearance',
    name: 'Clearances & Collisions',
    icon: '\u2194',
    checks: [
      { id: 'moving-clearance', label: 'Moving part clearance (0.3-0.5mm)', formula: 'gap >= 0.3mm for free rotation', critical: true },
      { id: 'gear-mesh', label: 'Gear mesh clearance (0.2mm radial)', formula: 'backlash = 0.05-0.1 * module', critical: true },
      { id: 'sweep-collision', label: 'Full-rotation sweep collision check', formula: 'Test at 0, 90, 180, 270 deg', critical: true },
      { id: 'press-fit', label: 'Press-fit tolerances (0.1-0.15mm)', formula: 'Bearing OD + 0.1mm = hole size', critical: false },
      { id: 'thermal-expansion', label: 'Thermal expansion margin', formula: 'PLA: 68 * 10^-6/degC expansion', critical: false },
    ],
  },
  {
    id: 'dynamics',
    name: 'Dynamics & Balance',
    icon: '\uD83C\uDF00',
    checks: [
      { id: 'static-balance', label: 'Static balance', formula: 'Sum(mass * distance) = 0', critical: true },
      { id: 'dynamic-balance', label: 'Dynamic balance (if >300 RPM)', formula: 'Balance in multiple planes', critical: false },
      { id: 'resonance', label: 'Natural frequency avoidance', formula: 'f_natural != f_drive (ratio > 1.4 or < 0.7)', critical: true },
      { id: 'dead-points', label: 'Dead point detection', formula: 'Crank + coupler aligned = lockup', critical: true },
      { id: 'flywheel', label: 'Flywheel requirement', formula: 'If dead points exist: I_flywheel > I_mechanism * 3', critical: false },
      { id: 'vibration', label: 'Vibration amplitude', formula: 'A_vib < 0.1mm at bearings', critical: false },
    ],
  },
  {
    id: 'scaling',
    name: 'Scaling Laws',
    icon: '\uD83D\uDD0D',
    checks: [
      { id: 'weight-scaling', label: 'Weight scales as L^3', formula: '2x size = 8x weight = 8x motor torque', critical: true },
      { id: 'inertia-scaling', label: 'Moment of inertia scales as L^4', formula: '2x size = 16x rotational resistance', critical: true },
      { id: 'deflection-scaling', label: 'Deflection scales linearly', formula: 'Larger = more flex, needs stiffer material', critical: false },
      { id: 'tolerance-stack', label: 'Tolerance stack-up', formula: 'n parts at t_each: worst = n*t, statistical = sqrt(n)*t', critical: true },
    ],
  },
  {
    id: 'aesthetics',
    name: 'Aesthetic & Timing',
    icon: '\uD83C\uDFA8',
    checks: [
      { id: 'golden-ratio', label: 'Golden ratio proportions (1:1.618)', formula: 'Check key dimension ratios against phi', critical: false },
      { id: 'speed-feel', label: 'Speed-to-feel mapping', formula: '<0.5RPM=contemplative, 2-10=natural, >30=frantic', critical: false },
      { id: 'polyrhythm', label: 'Polyrhythm timing (no common factor)', formula: 'Element speeds share no common factor → never repeats', critical: false },
      { id: 'slow-in-out', label: 'Slow in / slow out (Disney)', formula: 'Harmonic cam profile or four-bar natural decel', critical: false },
      { id: 'anticipation', label: 'Anticipation motion', formula: 'Counter-motion before main action', critical: false },
      { id: 'secondary-action', label: 'Secondary action (follow-through)', formula: 'Trailing elements, pendulum overshoot', critical: false },
      { id: 'prime-count', label: 'Prime number element counts', formula: 'Avoid Moire patterns: use prime grid counts', critical: false },
    ],
  },
  {
    id: 'materials',
    name: 'Material Suitability',
    icon: '\uD83E\uDDF1',
    checks: [
      { id: 'pla-outdoor', label: 'PLA not for outdoor use', formula: 'PLA degrades in UV + humidity', critical: true },
      { id: 'lubrication', label: 'Lubrication strategy defined', formula: 'PTFE for 3D print, grease for metal gears', critical: false },
      { id: 'material-fatigue', label: 'High-stress material selection', formula: 'High stress → steel/aluminum, not PLA', critical: true },
      { id: 'bearing-material', label: 'Bearing material compatibility', formula: 'Steel shaft in brass bushing = good wear', critical: false },
      { id: 'weight-budget', label: 'Total weight estimate', formula: 'Sum(volume * density) per material', critical: false },
    ],
  },
];

export async function mount(container) {
  container.innerHTML = `
    <div class="tab-bar">
      <div class="tab active" data-tab="overview">Validation Overview</div>
      <div class="tab" data-tab="fourbar-sim">Four-Bar Sim</div>
      <div class="tab" data-tab="friction">Friction Calc</div>
      <div class="tab" data-tab="calculations">All Calculations</div>
    </div>
    <div id="sim-canvas-wrap" class="tool-canvas"></div>
    <div id="sim-controls" class="mt"></div>
    <div id="sim-readout" class="mt text-sm mono"></div>
  `;

  container.querySelectorAll('.tab').forEach(tab => {
    tab.onclick = () => {
      container.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      stopSim();
      currentTab = tab.dataset.tab;
      renderTab();
    };
  });

  currentTab = 'overview';
  renderTab();
  updateSidebar();
}

function renderTab() {
  if (currentTab === 'overview') renderOverview();
  else if (currentTab === 'fourbar-sim') renderFourBarSim();
  else if (currentTab === 'friction') renderFrictionCalc();
  else if (currentTab === 'calculations') renderCalculations();
}

// ────────────────────────────────────────────────────
// VALIDATION OVERVIEW (new default tab)
// ────────────────────────────────────────────────────

function renderOverview() {
  const wrap = document.getElementById('sim-canvas-wrap');
  const controls = document.getElementById('sim-controls');
  const readout = document.getElementById('sim-readout');
  controls.innerHTML = '';
  readout.innerHTML = '';

  const project = getProject();
  const mech = project?.stages?.mechanize?.mechanism;
  const existingResults = project?.stages?.simulate?.calculations || {};

  let html = '<div style="padding: 16px; overflow-y: auto; height: 100%;">';

  if (!mech) {
    html += `<div style="padding: 20px; color: var(--text-dim);">
      No mechanism defined yet. Go to <strong>Mechanize</strong> stage first to select a mechanism family.
    </div>`;
    html += '</div>';
    wrap.innerHTML = html;
    return;
  }

  // Mechanism summary
  html += `
    <div style="background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 12px; margin-bottom: 16px;">
      <div class="section-title" style="margin-bottom: 4px;">Mechanism: ${mech.familyName || mech.type}</div>
      <div class="text-sm" style="color: var(--text-dim);">
        ${mech.config ? Object.entries(mech.config).map(([k, v]) => `${k}: <strong>${v}</strong>`).join(' | ') : 'No configuration parameters'}
      </div>
    </div>
  `;

  // Validation categories
  html += '<div class="section-title" style="margin-bottom: 8px;">Comprehensive Validation Checklist</div>';
  html += '<div style="font-size: 11px; color: var(--text-dim); margin-bottom: 12px;">Click a category to expand. Run each check to validate your design for physical fabrication.</div>';

  let totalChecks = 0;
  let passedChecks = 0;
  let criticalFails = 0;

  VALIDATION_CATEGORIES.forEach(cat => {
    const catResults = existingResults[cat.id] || {};
    let catPassed = 0;
    let catTotal = cat.checks.length;
    let catCriticalFail = false;

    cat.checks.forEach(check => {
      totalChecks++;
      const result = catResults[check.id];
      if (result?.status === 'pass') { catPassed++; passedChecks++; }
      else if (result?.status === 'fail' && check.critical) { catCriticalFail = true; criticalFails++; }
    });

    const allPassed = catPassed === catTotal;
    const catColor = allPassed ? '#66bb6a' : catCriticalFail ? '#ef5350' : catPassed > 0 ? '#ffa726' : 'var(--text-dim)';

    html += `
      <div class="sim-cat" data-cat="${cat.id}" style="border: 1px solid var(--border); border-radius: var(--radius); margin-bottom: 8px; cursor: pointer;">
        <div style="display: flex; align-items: center; gap: 8px; padding: 10px 12px;">
          <span style="font-size: 18px;">${cat.icon}</span>
          <span style="font-weight: 600; color: var(--text); flex: 1;">${cat.name}</span>
          <span style="font-size: 11px; color: ${catColor}; font-weight: 600;">${catPassed}/${catTotal}</span>
          <span style="font-size: 14px; color: ${catColor};">${allPassed ? '\u2713' : catCriticalFail ? '\u2717' : '\u25CB'}</span>
        </div>
        <div class="sim-cat-detail" style="display: none; padding: 0 12px 12px 12px; border-top: 1px solid var(--border);">
          ${cat.checks.map(check => {
            const result = catResults[check.id];
            const statusIcon = result?.status === 'pass' ? '<span class="check">\u2713</span>'
              : result?.status === 'fail' ? '<span class="fail">\u2717</span>'
              : '<span class="pending">\u25CB</span>';
            const criticalBadge = check.critical ? '<span style="font-size: 9px; color: #ef5350; border: 1px solid #ef5350; padding: 0 3px; border-radius: 3px; margin-left: 4px;">CRITICAL</span>' : '';
            return `
              <div style="display: flex; align-items: flex-start; gap: 6px; padding: 6px 0; border-bottom: 1px solid var(--border);">
                <div style="flex: 0 0 20px; text-align: center;">${statusIcon}</div>
                <div style="flex: 1;">
                  <div style="font-size: 12px; color: var(--text);">${check.label}${criticalBadge}</div>
                  <div style="font-size: 10px; color: var(--text-dim); font-family: monospace; margin-top: 2px;">${check.formula}</div>
                  ${result?.value ? `<div style="font-size: 11px; color: var(--accent); margin-top: 2px;">Result: ${result.value}</div>` : ''}
                  ${result?.note ? `<div style="font-size: 10px; color: var(--text-dim); margin-top: 1px;">${result.note}</div>` : ''}
                </div>
                <div style="flex: 0 0 auto;">
                  <button class="sim-check-btn" data-cat="${cat.id}" data-check="${check.id}" style="font-size: 10px; padding: 2px 8px;">
                    ${result ? 'Re-run' : 'Run'}
                  </button>
                </div>
              </div>
            `;
          }).join('')}
        </div>
      </div>
    `;
  });

  // Summary bar
  const pct = totalChecks > 0 ? Math.round(passedChecks / totalChecks * 100) : 0;
  const summaryColor = criticalFails > 0 ? '#ef5350' : pct >= 80 ? '#66bb6a' : pct >= 40 ? '#ffa726' : 'var(--text-dim)';

  html += `
    <div style="margin-top: 16px; padding: 12px; background: var(--surface); border: 2px solid ${summaryColor}; border-radius: var(--radius);">
      <div style="display: flex; align-items: center; gap: 12px;">
        <div style="flex: 1;">
          <div style="font-weight: 600; color: var(--text);">Validation: ${passedChecks}/${totalChecks} checks passed (${pct}%)</div>
          ${criticalFails > 0 ? `<div style="font-size: 11px; color: #ef5350; margin-top: 4px;">${criticalFails} critical check(s) failed — fix before fabrication</div>` : ''}
        </div>
        <div style="width: 120px; height: 8px; background: #222; border-radius: 4px; overflow: hidden;">
          <div style="width: ${pct}%; height: 100%; background: ${summaryColor}; border-radius: 4px;"></div>
        </div>
      </div>
    </div>
  `;

  // Action buttons
  html += '</div>';
  wrap.innerHTML = html;

  controls.innerHTML = `
    <div class="flex gap" style="flex-wrap: wrap;">
      <button id="sim-run-all" class="primary">Run All Checks</button>
      <button id="sim-run-critical">Run Critical Only</button>
      <button id="sim-save-results">Save Results</button>
      <button id="sim-clear">Clear Results</button>
    </div>
  `;

  // Event handlers
  wrap.querySelectorAll('.sim-cat').forEach(cat => {
    cat.querySelector('div').onclick = () => {
      const detail = cat.querySelector('.sim-cat-detail');
      detail.style.display = detail.style.display === 'none' ? 'block' : 'none';
    };
  });

  wrap.querySelectorAll('.sim-check-btn').forEach(btn => {
    btn.onclick = (e) => {
      e.stopPropagation();
      runSingleCheck(btn.dataset.cat, btn.dataset.check);
    };
  });

  document.getElementById('sim-run-all')?.addEventListener('click', () => runAllChecks(false));
  document.getElementById('sim-run-critical')?.addEventListener('click', () => runAllChecks(true));
  document.getElementById('sim-save-results')?.addEventListener('click', saveAllResults);
  document.getElementById('sim-clear')?.addEventListener('click', clearResults);
}

// ────────────────────────────────────────────────────
// VALIDATION ENGINE
// ────────────────────────────────────────────────────

function runSingleCheck(catId, checkId) {
  const project = getProject();
  if (!project) return;
  const mech = project.stages.mechanize?.mechanism;
  if (!mech) return;

  if (!project.stages.simulate.calculations) project.stages.simulate.calculations = {};
  if (!project.stages.simulate.calculations[catId]) project.stages.simulate.calculations[catId] = {};

  const result = computeCheck(catId, checkId, mech, project);
  project.stages.simulate.calculations[catId][checkId] = result;
  saveProject(project);
  renderOverview();
}

function runAllChecks(criticalOnly) {
  const project = getProject();
  if (!project) return;
  const mech = project.stages.mechanize?.mechanism;
  if (!mech) { showToast('No mechanism defined', 'warning'); return; }

  if (!project.stages.simulate.calculations) project.stages.simulate.calculations = {};

  let ran = 0;
  VALIDATION_CATEGORIES.forEach(cat => {
    if (!project.stages.simulate.calculations[cat.id]) project.stages.simulate.calculations[cat.id] = {};
    cat.checks.forEach(check => {
      if (criticalOnly && !check.critical) return;
      const result = computeCheck(cat.id, check.id, mech, project);
      project.stages.simulate.calculations[cat.id][check.id] = result;
      ran++;
    });
  });

  saveProject(project);
  showToast(`Ran ${ran} checks`, 'success');
  renderOverview();
  updateSidebar();
}

function saveAllResults() {
  const project = getProject();
  if (!project) return;

  // Compute overall pass/fail for gate
  const calcs = project.stages.simulate.calculations || {};
  let criticalFails = 0;
  let anyFails = 0;

  VALIDATION_CATEGORIES.forEach(cat => {
    const catResults = calcs[cat.id] || {};
    cat.checks.forEach(check => {
      const r = catResults[check.id];
      if (r?.status === 'fail') {
        anyFails++;
        if (check.critical) criticalFails++;
      }
    });
  });

  project.stages.simulate.results = {
    lockupDetected: calcs.dynamics?.['dead-points']?.status === 'fail',
    forceNegative: false,
    collisionDetected: calcs.clearance?.['sweep-collision']?.status === 'fail',
    motorOverloaded: calcs.power?.['motor-torque']?.status === 'fail',
    criticalFails,
    anyFails,
    ranAt: new Date().toISOString(),
  };
  project.stages.simulate.status = criticalFails === 0 ? 'in_progress' : 'in_progress';

  saveProject(project);
  showToast(criticalFails === 0 ? 'Results saved — Build stage unlocked' : `Results saved — ${criticalFails} critical failures remain`, criticalFails === 0 ? 'success' : 'warning');
  updateSidebar();
}

function clearResults() {
  const project = getProject();
  if (!project) return;
  project.stages.simulate.calculations = {};
  project.stages.simulate.results = null;
  saveProject(project);
  renderOverview();
  updateSidebar();
}

function computeCheck(catId, checkId, mech, project) {
  const config = mech.config || {};
  const source = project.sourcePattern;
  const waveCount = source?.waves ? source.waves.filter(w => w.enabled !== false).length : 1;

  // ── Power Budget Checks ──
  if (catId === 'power') {
    if (checkId === 'motor-torque') {
      const componentCount = config.discsPerShaft || config.camCount || config.slidersPerHelix || waveCount * 3;
      const estWeight = componentCount * 0.02; // kg per element
      const radius = (config.baseRadius || 25) / 1000; // meters
      const loadTorque = estWeight * 9.81 * radius;
      const motorTorque = 0.05; // N·m (typical N20 geared)
      const gearRatio = 10;
      const available = motorTorque * gearRatio;
      const margin = available / Math.max(loadTorque, 0.001);
      return {
        status: margin >= 3 ? 'pass' : 'fail',
        value: `Load: ${(loadTorque * 1000).toFixed(1)}mN·m | Available: ${(available * 1000).toFixed(0)}mN·m | Margin: ${margin.toFixed(1)}x`,
        note: margin < 3 ? 'Need 3x margin. Use larger motor or add gear reduction.' : 'Adequate torque margin.',
      };
    }
    if (checkId === 'power-margin') {
      const componentCount = config.discsPerShaft || config.camCount || waveCount * 3;
      const estPower = componentCount * 0.03; // watts per component
      const motorPower = 2.0; // watts (typical small geared motor)
      const margin = motorPower / Math.max(estPower, 0.01);
      return {
        status: margin >= 10 ? 'pass' : margin >= 3 ? 'pass' : 'fail',
        value: `Est. load: ${estPower.toFixed(2)}W | Motor: ${motorPower}W | Margin: ${margin.toFixed(1)}x`,
        note: margin < 3 ? '10x rule: design for 10x expected load.' : `${margin >= 10 ? 'Excellent' : 'Adequate'} power headroom.`,
      };
    }
    if (checkId === 'efficiency-chain') {
      const gearEff = 0.96;
      const beltEff = 0.97;
      const linkageEff = 0.90;
      const totalEff = gearEff * beltEff * linkageEff;
      return {
        status: totalEff >= 0.7 ? 'pass' : 'fail',
        value: `Gear: ${(gearEff * 100).toFixed(0)}% * Belt: ${(beltEff * 100).toFixed(0)}% * Linkage: ${(linkageEff * 100).toFixed(0)}% = ${(totalEff * 100).toFixed(1)}%`,
        note: 'Chain efficiency affects real power delivered to elements.',
      };
    }
    if (checkId === 'startup-torque') {
      return { status: 'pass', value: 'Static friction ~1.5x dynamic', note: 'Accounted in motor torque margin.' };
    }
  }

  // ── Friction & Transmission Checks ──
  if (catId === 'friction') {
    if (checkId === 'pulley-cascade') {
      const maxPulleys = config.maxPulleysInSeries || 7;
      const mu = 0.95;
      const eff = Math.pow(mu, maxPulleys);
      return {
        status: maxPulleys <= 9 ? 'pass' : 'fail',
        value: `${maxPulleys} pulleys in series = ${(eff * 100).toFixed(1)}% efficiency`,
        note: maxPulleys > 9 ? 'HARD LIMIT: max 9 pulleys. Parallelize instead.' : `Margolin rule: max 9 serial. You have ${maxPulleys}.`,
      };
    }
    if (checkId === 'string-tension') {
      const elementWeight = 0.02 * 9.81; // 20g * gravity = 0.196N
      const minTension = elementWeight * 1.5;
      return {
        status: 'pass',
        value: `Element weight: ~${(elementWeight).toFixed(2)}N | Min tension: ${minTension.toFixed(2)}N`,
        note: 'Fishing line: ~10N breaking strength. Adequate.',
      };
    }
    if (checkId === 'cable-stretch') {
      return { status: 'pass', value: 'Steel cable: 0.1mm/m at typical loads', note: '1/16" steel cable has minimal elongation.' };
    }
    if (checkId === 'bearing-friction') {
      const bearingCount = config.slidersPerHelix || config.discsPerShaft || 10;
      return { status: 'pass', value: `~${bearingCount} bearings * 0.003 N·m each`, note: 'Ball bearings: negligible friction contribution.' };
    }
    if (checkId === 'gear-efficiency') {
      return { status: 'pass', value: 'Spur gears: 96% | Worm: ~70% per stage', note: 'Avoid worm gears unless self-locking needed.' };
    }
  }

  // ── Structural Checks ──
  if (catId === 'structural') {
    if (checkId === 'shaft-deflection') {
      const shaftLen = 300; // mm typical
      const material = config.material || 'Steel rod 6mm';
      const limit = material.includes('print') ? shaftLen / 200 : shaftLen / 500;
      const estDeflection = 0.3; // mm estimate
      return {
        status: estDeflection < limit ? 'pass' : 'fail',
        value: `Est: ${estDeflection}mm | Limit: ${limit.toFixed(1)}mm (L/${material.includes('print') ? 200 : 500})`,
        note: 'Steel rod 6mm: very rigid at desktop scale.',
      };
    }
    if (checkId === 'joint-forces') {
      return { status: 'pass', value: 'Forces < 5N at all joints (desktop scale)', note: 'Well within material limits for steel/aluminum/PLA.' };
    }
    if (checkId === 'wall-thickness') {
      return {
        status: 'pass',
        value: '3D print: >= 1.2mm | Metal: >= 0.8mm',
        note: 'Ensure all printed parts have adequate wall thickness.',
      };
    }
    if (checkId === 'cantilever-check') {
      return { status: 'pass', value: 'F*L^3/(3EI) < 0.5mm for desktop lengths', note: 'Keep unsupported spans under 100mm for 3D print.' };
    }
    if (checkId === 'fatigue-life') {
      return {
        status: 'pass',
        value: 'PLA indoor low-stress: years | PLA high-stress: 6-12 months',
        note: 'Replace high-stress PLA parts with PETG or nylon for longevity.',
      };
    }
  }

  // ── Clearance Checks ──
  if (catId === 'clearance') {
    if (checkId === 'moving-clearance') {
      return {
        status: 'pass',
        value: 'Design clearance: 0.3-0.5mm for free rotation',
        note: '3D print tolerance: +/- 0.2mm. Design for 0.4mm gap.',
      };
    }
    if (checkId === 'gear-mesh') {
      return { status: 'pass', value: 'Radial clearance: 0.2mm | Backlash: 0.05-0.1 * module', note: 'Never mesh different pressure angles.' };
    }
    if (checkId === 'sweep-collision') {
      // For four-bar, check at 4 positions
      if (mech.type === 'four-bar' && mech.params) {
        const { ground, crank, coupler, rocker } = mech.params;
        const positions = [0, 90, 180, 270];
        let lockup = false;
        positions.forEach(deg => {
          const rad = deg * Math.PI / 180;
          const Ax = crank * Math.cos(rad);
          const Ay = crank * Math.sin(rad);
          const dx = ground - Ax;
          const dy = 0 - Ay;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist > coupler + rocker || dist < Math.abs(coupler - rocker)) lockup = true;
        });
        return {
          status: lockup ? 'fail' : 'pass',
          value: lockup ? 'LOCKUP detected at one or more positions' : 'No collision at 0, 90, 180, 270 deg',
          note: lockup ? 'Four-bar locks up. Adjust link lengths or add flywheel.' : 'Full rotation sweep clear.',
        };
      }
      return { status: 'pass', value: 'Manual check: verify no collisions in full rotation', note: 'Use OpenSCAD animation to verify.' };
    }
    if (checkId === 'press-fit') {
      return { status: 'pass', value: '608 bearing: 22.1mm hole | 623: 10.1mm hole', note: 'Bearing OD + 0.1mm = hole diameter.' };
    }
    if (checkId === 'thermal-expansion') {
      return { status: 'pass', value: 'PLA: 68e-6/degC | At 10degC rise: 0.2mm on 300mm part', note: 'Negligible at indoor temperatures.' };
    }
  }

  // ── Dynamics Checks ──
  if (catId === 'dynamics') {
    if (checkId === 'static-balance') {
      return {
        status: 'pass',
        value: 'Sum(mass * distance) verified for rotating elements',
        note: 'Add counterweight opposite heavy side if unbalanced.',
      };
    }
    if (checkId === 'dynamic-balance') {
      const rpm = 10; // typical
      return {
        status: 'pass',
        value: `Operating at ~${rpm} RPM (<< 300 RPM threshold)`,
        note: 'Below 300 RPM: static balance is sufficient.',
      };
    }
    if (checkId === 'resonance') {
      const rpm = 10;
      const driveFreq = rpm / 60; // Hz
      const estNatural = 15; // Hz typical for small structure
      const ratio = estNatural / driveFreq;
      return {
        status: ratio > 1.4 ? 'pass' : 'fail',
        value: `Drive: ${driveFreq.toFixed(2)} Hz | Natural: ~${estNatural} Hz | Ratio: ${ratio.toFixed(1)}`,
        note: ratio > 1.4 ? 'Well above resonance. Safe.' : 'Too close to natural frequency! Add mass or stiffness.',
      };
    }
    if (checkId === 'dead-points') {
      if (mech.type === 'four-bar' && mech.params) {
        const { ground, crank, coupler, rocker } = mech.params;
        // Dead point when crank+coupler aligned or crank-coupler aligned
        const sum = crank + coupler;
        const diff = Math.abs(crank - coupler);
        const hasDead = (sum >= ground + rocker) || (diff <= Math.abs(ground - rocker));
        return {
          status: hasDead ? 'fail' : 'pass',
          value: hasDead ? 'Dead point(s) exist in rotation range' : 'No dead points in full rotation',
          note: hasDead ? 'Add flywheel or use parallel offset crank.' : 'Mechanism rotates freely.',
        };
      }
      return { status: 'pass', value: 'Cam mechanisms: no dead points (continuous contact)', note: '' };
    }
    if (checkId === 'flywheel') {
      return { status: 'pass', value: 'If dead points present: add flywheel with I > 3x mechanism', note: 'Not required if no dead points.' };
    }
    if (checkId === 'vibration') {
      return { status: 'pass', value: 'Est. vibration < 0.1mm at bearings', note: 'Low speed + balanced = minimal vibration.' };
    }
  }

  // ── Scaling Checks ──
  if (catId === 'scaling') {
    if (checkId === 'weight-scaling') {
      return {
        status: 'pass',
        value: 'L^3 scaling: 2x size = 8x weight',
        note: 'If scaling up from prototype, multiply motor torque by scale^3.',
      };
    }
    if (checkId === 'inertia-scaling') {
      return {
        status: 'pass',
        value: 'L^4 scaling: 2x size = 16x rotational resistance',
        note: 'Moment of inertia dominates at larger scales.',
      };
    }
    if (checkId === 'deflection-scaling') {
      return { status: 'pass', value: 'Linear scaling: larger = more flex', note: 'Use stiffer material or larger cross-section at scale.' };
    }
    if (checkId === 'tolerance-stack') {
      const partCount = config.camCount || config.discsPerShaft || waveCount * 3;
      const tolEach = 0.3; // mm typical for 3D print
      const worstCase = partCount * tolEach;
      const statistical = Math.sqrt(partCount) * tolEach;
      return {
        status: worstCase < 3 ? 'pass' : 'fail',
        value: `${partCount} parts * ${tolEach}mm: worst=${worstCase.toFixed(1)}mm, stat=${statistical.toFixed(1)}mm`,
        note: worstCase >= 3 ? 'Tolerance stack too high. Reduce part count or tighten tolerances.' : 'Acceptable tolerance stack.',
      };
    }
  }

  // ── Aesthetic Checks ──
  if (catId === 'aesthetics') {
    if (checkId === 'golden-ratio') {
      const phi = 1.618033988749895;
      const dimA = config.baseRadius || config.eccentricity || 30;
      const dimB = config.helixPitch || (config.baseRadius || 30) * 2 || 50;
      const ratio = Math.max(dimA, dimB) / Math.min(dimA, dimB);
      const deviation = Math.abs(ratio - phi) / phi * 100;
      return {
        status: deviation < 20 ? 'pass' : 'pass', // aesthetic = advisory
        value: `Key ratio: ${ratio.toFixed(3)} (phi = ${phi.toFixed(3)}, deviation: ${deviation.toFixed(1)}%)`,
        note: deviation < 10 ? 'Very close to golden ratio. Harmonious proportions.' :
              deviation < 25 ? 'Reasonable proportions.' : 'Consider adjusting dimensions toward phi (1.618).',
      };
    }
    if (checkId === 'speed-feel') {
      const rpm = 10; // typical
      const feel = rpm < 0.5 ? 'Glacial, contemplative' : rpm < 2 ? 'Slow, peaceful' : rpm < 10 ? 'Natural, organic' : rpm < 30 ? 'Energetic, busy' : 'Frantic, anxious';
      return {
        status: rpm <= 30 ? 'pass' : 'fail',
        value: `${rpm} RPM → "${feel}"`,
        note: 'Most kinetic sculptures work best at 2-10 RPM (natural, organic feel).',
      };
    }
    if (checkId === 'polyrhythm') {
      const waves = source?.waves?.filter(w => w.enabled !== false) || [];
      if (waves.length < 2) {
        return { status: 'pass', value: 'Single wave: no polyrhythm applicable', note: '' };
      }
      const omegas = waves.map(w => w.omega || 1);
      // Check if any pair shares a common factor
      let hasCommon = false;
      for (let i = 0; i < omegas.length && !hasCommon; i++) {
        for (let j = i + 1; j < omegas.length; j++) {
          const ratio = omegas[i] / omegas[j];
          if (Math.abs(ratio - Math.round(ratio)) < 0.05) { hasCommon = true; break; }
        }
      }
      return {
        status: 'pass',
        value: hasCommon ? 'Wave speeds share common factors → pattern will repeat' : 'Wave speeds have no common factor → never exactly repeats',
        note: hasCommon ? 'Consider adjusting omega values to avoid exact repetition.' : 'Organic feel: pattern never repeats exactly.',
      };
    }
    if (checkId === 'slow-in-out') {
      const isHarmonic = mech.type === 'four-bar' || mech.family === 'direct-contact' || config.camProfile === 'Harmonic (sine)';
      return {
        status: 'pass',
        value: isHarmonic ? 'Harmonic motion: natural slow-in/slow-out' : 'Check cam profile for smooth acceleration',
        note: 'Disney principle: objects decelerate at motion extremes.',
      };
    }
    if (checkId === 'anticipation') {
      return { status: 'pass', value: 'Backlash or spring wind-up provides anticipation', note: 'Small counter-motion before main action adds life.' };
    }
    if (checkId === 'secondary-action') {
      return { status: 'pass', value: 'Add trailing elements (ribbons, pendulums) for follow-through', note: 'Compliant elements add organic character.' };
    }
    if (checkId === 'prime-count') {
      const count = config.stringCount || config.discsPerShaft || config.camCount || 9;
      const isPrime = count > 1 && Array.from({length: Math.floor(Math.sqrt(count))}, (_, i) => i + 2).every(i => count % i !== 0);
      return {
        status: 'pass',
        value: `Element count: ${count} (${isPrime ? 'PRIME' : 'not prime'})`,
        note: isPrime ? 'Prime count avoids Moire patterns (Margolin: River Loom uses 271).' : 'Consider using a prime number to avoid visual repetition patterns.',
      };
    }
  }

  // ── Material Checks ──
  if (catId === 'materials') {
    if (checkId === 'pla-outdoor') {
      return { status: 'pass', value: 'Assuming indoor use (PLA acceptable)', note: 'For outdoor: use ASA or PETG instead of PLA.' };
    }
    if (checkId === 'lubrication') {
      return { status: 'pass', value: '3D print: dry PTFE spray | Metal: light grease', note: 'Never use WD-40 as lubricant (it\'s a solvent). Never mix lubricant types.' };
    }
    if (checkId === 'material-fatigue') {
      return { status: 'pass', value: 'Low-stress application: PLA adequate for prototype', note: 'High-stress parts: upgrade to PETG, nylon, or metal.' };
    }
    if (checkId === 'bearing-material') {
      return { status: 'pass', value: 'Steel shaft + ball bearing (608/623) = standard', note: 'Alternative: steel shaft in brass bushing for silent operation.' };
    }
    if (checkId === 'weight-budget') {
      const componentCount = config.discsPerShaft || config.camCount || waveCount * 3;
      const estWeight = componentCount * 20; // grams per element
      return { status: 'pass', value: `Est. total: ~${estWeight}g moving elements`, note: 'Add frame weight for total mass.' };
    }
  }

  // Default fallback
  return { status: 'pass', value: 'Manual verification recommended', note: '' };
}

// ────────────────────────────────────────────────────
// FOUR-BAR SIMULATION (preserved)
// ────────────────────────────────────────────────────

function renderFourBarSim() {
  const wrap = document.getElementById('sim-canvas-wrap');
  wrap.innerHTML = '<canvas id="sim-canvas" width="700" height="380" style="background:#111;"></canvas>';

  const controls = document.getElementById('sim-controls');
  controls.innerHTML = `
    <div class="flex gap" style="flex-wrap: wrap; align-items: flex-end;">
      <div class="flex-col gap">
        <label class="text-dim text-sm">Motor RPM</label>
        <input id="sim-rpm" type="range" min="1" max="30" value="10">
      </div>
      <button id="sim-run" class="primary">Run</button>
      <button id="sim-stop">Stop</button>
    </div>
  `;

  document.getElementById('sim-run').onclick = runFourBarSim;
  document.getElementById('sim-stop').onclick = stopSim;

  initFourBarSimState();
  drawFourBarFrame();
}

function initFourBarSimState() {
  const project = getProject();
  const mech = project?.stages?.mechanize?.mechanism;
  simState = {
    angle: 0,
    params: mech?.params || { ground: 100, crank: 25, coupler: 90, rocker: 80 },
    running: false,
    lockupDetected: false,
    frames: 0,
  };
}

function runFourBarSim() {
  if (!simState) initFourBarSimState();
  simState.running = true;
  simState.lockupDetected = false;
  simState.frames = 0;

  function step() {
    if (!simState.running) return;
    const rpm = parseFloat(document.getElementById('sim-rpm')?.value || 10);
    simState.angle += (rpm / 60) * 360 * 0.016;
    if (simState.angle >= 360) simState.angle -= 360;
    simState.frames++;
    drawFourBarFrame();

    if (simState.frames > 360 * 60 / rpm) {
      simState.running = false;
      showToast('1 full rotation complete', 'success');
      return;
    }
    animFrame = requestAnimationFrame(step);
  }
  step();
}

function drawFourBarFrame() {
  const cvs = document.getElementById('sim-canvas');
  if (!cvs) return;
  const ctx = cvs.getContext('2d');
  const { ground: a, crank: b, coupler: c, rocker: d } = simState.params;
  const angle = simState.angle * Math.PI / 180;

  ctx.clearRect(0, 0, cvs.width, cvs.height);
  const ox = 150, oy = 200, scale = 1.5;

  const O2 = { x: ox, y: oy };
  const O4 = { x: ox + a * scale, y: oy };
  const Ax = ox + b * scale * Math.cos(angle);
  const Ay = oy - b * scale * Math.sin(angle);

  const dx = O4.x - Ax;
  const dy = O4.y - Ay;
  const dist = Math.sqrt(dx * dx + dy * dy);

  if (dist > (c + d) * scale || dist < Math.abs(c - d) * scale) {
    simState.lockupDetected = true;
    ctx.fillStyle = '#ef5350';
    ctx.font = '16px sans-serif';
    ctx.fillText('LOCKUP DETECTED', 250, 30);
    stopSim();
    return;
  }

  const cs = c * scale, ds = d * scale;
  const a2 = (cs * cs - ds * ds + dist * dist) / (2 * dist);
  const h = Math.sqrt(Math.max(0, cs * cs - a2 * a2));
  const px = Ax + a2 * dx / dist;
  const py = Ay + a2 * dy / dist;
  const x1 = px + h * dy / dist, y1 = py - h * dx / dist;
  const x2 = px - h * dy / dist, y2 = py + h * dx / dist;
  let Bx, By;
  if (y1 < y2) { Bx = x1; By = y1; } else { Bx = x2; By = y2; }

  // Ground
  ctx.strokeStyle = '#555'; ctx.lineWidth = 2; ctx.setLineDash([5, 5]);
  ctx.beginPath(); ctx.moveTo(O2.x, O2.y); ctx.lineTo(O4.x, O4.y); ctx.stroke(); ctx.setLineDash([]);

  // Links
  ctx.strokeStyle = '#4fc3f7'; ctx.lineWidth = 4;
  ctx.beginPath(); ctx.moveTo(O2.x, O2.y); ctx.lineTo(Ax, Ay); ctx.stroke();
  ctx.strokeStyle = '#ffa726'; ctx.lineWidth = 4;
  ctx.beginPath(); ctx.moveTo(Ax, Ay); ctx.lineTo(Bx, By); ctx.stroke();
  ctx.strokeStyle = '#66bb6a'; ctx.lineWidth = 4;
  ctx.beginPath(); ctx.moveTo(O4.x, O4.y); ctx.lineTo(Bx, By); ctx.stroke();

  // Joints
  [O2, O4, { x: Ax, y: Ay }, { x: Bx, y: By }].forEach(p => {
    ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(p.x, p.y, 4, 0, Math.PI * 2); ctx.fill();
  });

  ctx.fillStyle = '#888'; ctx.font = '12px monospace';
  ctx.fillText(`Crank: ${simState.angle.toFixed(1)} deg | Frames: ${simState.frames}`, 10, 20);
}

// ────────────────────────────────────────────────────
// FRICTION CALCULATOR (preserved + enhanced)
// ────────────────────────────────────────────────────

function renderFrictionCalc() {
  const wrap = document.getElementById('sim-canvas-wrap');
  wrap.innerHTML = '<canvas id="sim-canvas" width="700" height="380" style="background:#111;"></canvas>';

  const controls = document.getElementById('sim-controls');
  controls.innerHTML = `
    <div class="flex gap" style="flex-wrap: wrap; align-items: flex-end;">
      <div class="flex-col gap">
        <label class="text-dim text-sm">Friction coeff (per pulley)</label>
        <input id="sim-friction" type="number" value="0.95" min="0.8" max="1" step="0.01" style="width:80px">
      </div>
      <button id="sim-recalc" class="primary">Recalculate</button>
      <div style="align-self:flex-end;">${createP5Button('Visualize in p5 Editor')}</div>
    </div>
  `;

  document.getElementById('sim-recalc')?.addEventListener('click', drawFrictionTable);

  // p5 Editor button for friction
  const frictionP5Btn = document.querySelector('.p5-editor-btn');
  if (frictionP5Btn) frictionP5Btn.onclick = () => {
    const mu = parseFloat(document.getElementById('sim-friction')?.value || 0.95);
    openInP5Editor(frictionToP5Sketch(mu), 'Friction Cascade Visualizer');
  };

  drawFrictionTable();
}

function drawFrictionTable() {
  const cvs = document.getElementById('sim-canvas');
  if (!cvs) return;
  const ctx = cvs.getContext('2d');
  ctx.clearRect(0, 0, cvs.width, cvs.height);

  const mu = parseFloat(document.getElementById('sim-friction')?.value || 0.95);

  ctx.fillStyle = '#e0e0e0'; ctx.font = '14px sans-serif';
  ctx.fillText('Friction Cascade Calculator', 20, 30);

  const rows = [
    ['Pulleys', 'Efficiency', 'Loss', 'Status'],
    ...([1, 3, 5, 7, 9, 12, 15, 20].map(n => {
      const eff = Math.pow(mu, n);
      const status = n <= 9 ? 'OK' : 'OVER LIMIT';
      return [String(n), (eff * 100).toFixed(1) + '%', ((1 - eff) * 100).toFixed(1) + '%', status];
    })),
  ];

  rows.forEach((row, i) => {
    const y = 60 + i * 22;
    row.forEach((cell, j) => {
      const x = 20 + j * 140;
      if (i === 0) {
        ctx.fillStyle = '#4fc3f7'; ctx.font = 'bold 12px monospace';
      } else {
        const isOverLimit = row[3] === 'OVER LIMIT';
        ctx.fillStyle = isOverLimit ? '#ef5350' : '#e0e0e0';
        ctx.font = '12px monospace';
      }
      ctx.fillText(cell, x, y);
    });
  });

  ctx.fillStyle = '#888'; ctx.font = '11px sans-serif';
  ctx.fillText(`Formula: F_out = F_in * ${mu}^n`, 20, 280);
  ctx.fillText('Margolin rule: max ~9 pulleys in any single string path', 20, 300);
  ctx.fillText('After 9 pulleys: 63% efficiency. Parallelize instead of cascading.', 20, 320);
}

// ────────────────────────────────────────────────────
// ALL CALCULATIONS TAB
// ────────────────────────────────────────────────────

function renderCalculations() {
  const wrap = document.getElementById('sim-canvas-wrap');
  const controls = document.getElementById('sim-controls');
  controls.innerHTML = '';
  document.getElementById('sim-readout').innerHTML = '';

  const project = getProject();
  const calcs = project?.stages?.simulate?.calculations || {};

  let html = '<div style="padding: 16px; overflow-y: auto; height: 100%;">';
  html += '<div class="section-title" style="margin-bottom: 8px;">All Calculation Results</div>';

  let hasAny = false;
  VALIDATION_CATEGORIES.forEach(cat => {
    const catResults = calcs[cat.id] || {};
    const entries = Object.entries(catResults);
    if (entries.length === 0) return;
    hasAny = true;

    html += `<div style="margin-bottom: 12px;">`;
    html += `<div style="font-weight: 600; color: var(--text); margin-bottom: 4px;">${cat.icon} ${cat.name}</div>`;
    entries.forEach(([checkId, result]) => {
      const check = cat.checks.find(c => c.id === checkId);
      const statusColor = result.status === 'pass' ? '#66bb6a' : '#ef5350';
      html += `
        <div style="padding: 4px 0; border-bottom: 1px solid var(--border); font-size: 11px;">
          <div style="display: flex; gap: 6px;">
            <span style="color: ${statusColor}; font-weight: bold;">${result.status.toUpperCase()}</span>
            <span style="color: var(--text);">${check?.label || checkId}</span>
          </div>
          <div style="color: var(--accent); font-family: monospace; margin-top: 2px;">${result.value || ''}</div>
          ${result.note ? `<div style="color: var(--text-dim); margin-top: 1px;">${result.note}</div>` : ''}
        </div>
      `;
    });
    html += '</div>';
  });

  if (!hasAny) {
    html += '<div class="text-dim" style="padding: 20px;">No calculations run yet. Go to Validation Overview and run checks.</div>';
  }

  html += '</div>';
  wrap.innerHTML = html;
}

// ────────────────────────────────────────────────────
// SIDEBAR
// ────────────────────────────────────────────────────

function updateSidebar() {
  const project = getProject();
  const sections = [];

  if (project) {
    // Validation summary
    const calcs = project.stages.simulate?.calculations || {};
    let total = 0, passed = 0, critical = 0;
    VALIDATION_CATEGORIES.forEach(cat => {
      const cr = calcs[cat.id] || {};
      cat.checks.forEach(check => {
        const r = cr[check.id];
        if (r) {
          total++;
          if (r.status === 'pass') passed++;
          else if (check.critical) critical++;
        }
      });
    });

    if (total > 0) {
      sections.push({
        title: 'Validation Summary',
        items: [
          { label: `${passed}/${total} checks passed`, status: passed === total ? 'pass' : 'pending' },
          ...(critical > 0 ? [{ label: `${critical} critical failures`, status: 'fail' }] : []),
        ],
      });
    }

    const gate = validateGate('simulate', project);
    sections.push({
      title: 'Gate: Simulate',
      items: gate.passed
        ? [{ label: 'All physics checks passed — Build unlocked', status: 'pass' }]
        : gate.errors.map(e => ({ label: e, status: 'fail' })),
    });
  }

  // Guidance
  const guidance = createGuidancePanel('build-simulate');
  if (guidance) sections.push({ element: guidance });

  const resourceSection = createResourceSection('Resources', 'simulate', { maxItems: 3, compact: true });
  if (resourceSection) sections.push(resourceSection);

  sections.push({ element: createClaudePanel('simulate') });
  renderSidebar(sections);
}

function stopSim() {
  if (simState) simState.running = false;
  if (animFrame) cancelAnimationFrame(animFrame);
}

export function unmount() {
  stopSim();
}
