// Stage 3: BUILD — Build type selection, per-component materials, code generation
// Prototype (3D Print) vs Production (Metal/Wood) with material recommendations

import { getProject, saveProject } from '../state.js';
import { renderSidebar } from '../components/sidebar.js';
import { createClaudePanel } from '../components/claude-panel.js';
import { showToast } from '../toast.js';
import { validateGate } from '../gate.js';
import { createResourceSection } from '../components/resource-links.js';
import { createGuidancePanel } from '../components/guidance.js';

let currentTab = 'type';

// ────────────────────────────────────────────────────
// MATERIALS DATABASE
// ────────────────────────────────────────────────────

const MATERIALS = {
  'PLA': { category: 'print', strength: 'medium', friction: 'high', outdoor: false, cost: 'low', notes: 'Easy to print. Indoor only. 6-12mo high-stress life.' },
  'PETG': { category: 'print', strength: 'medium', friction: 'medium', outdoor: 'moderate', cost: 'low', notes: 'Stronger than PLA, some outdoor tolerance.' },
  'ASA': { category: 'print', strength: 'medium', friction: 'medium', outdoor: true, cost: 'medium', notes: 'Outdoor-rated. Harder to print.' },
  'Nylon': { category: 'print', strength: 'high', friction: 'low', outdoor: true, cost: 'medium', notes: 'Best for gears/bearings. Hard to print (warping).' },
  'Aluminum': { category: 'metal', strength: 'high', friction: 'low', outdoor: true, cost: 'medium', notes: 'CNC or cast. Lightweight, strong.' },
  'Brass': { category: 'metal', strength: 'medium', friction: 'low', outdoor: true, cost: 'medium', notes: 'Beautiful aesthetic. Great for visible parts.' },
  'Copper': { category: 'metal', strength: 'medium', friction: 'medium', outdoor: true, cost: 'high', notes: 'Patinas over time. Decorative.' },
  'Steel': { category: 'metal', strength: 'very-high', friction: 'low', outdoor: true, cost: 'medium', notes: 'Shafts, frames, high-stress parts.' },
  'Plywood': { category: 'wood', strength: 'medium', friction: 'medium', outdoor: false, cost: 'low', notes: 'Laser-cut. Margolin uses for cams.' },
  'Cherry': { category: 'wood', strength: 'medium', friction: 'medium', outdoor: false, cost: 'medium', notes: 'Warm aesthetic. Margolin\'s preferred element material.' },
  'Basswood': { category: 'wood', strength: 'low', friction: 'medium', outdoor: false, cost: 'low', notes: 'Lightweight. Good for hanging elements.' },
  'Acrylic': { category: 'other', strength: 'medium', friction: 'low', outdoor: false, cost: 'low', notes: 'Laser-cut. Transparent/colored options.' },
  'Polycarbonate': { category: 'other', strength: 'high', friction: 'low', outdoor: true, cost: 'medium', notes: 'Drillable, transparent. Used for matrices.' },
  'Delrin/POM': { category: 'other', strength: 'high', friction: 'very-low', outdoor: true, cost: 'medium', notes: 'Best gear material. Not 3D printable.' },
};

const BUILD_TYPES = [
  {
    id: 'prototype',
    label: 'Prototype (3D Print)',
    icon: '\uD83D\uDDA8',
    description: 'Fast iteration with PLA/PETG. Accept imperfections. Test mechanism before committing to production materials.',
    defaultMaterials: { structural: 'PLA', mechanical: 'PETG', decorative: 'PLA', fasteners: 'Steel' },
    tolerance: '0.3mm',
    process: ['FDM 3D printing', 'Steel rod shafts', '608 bearings'],
  },
  {
    id: 'production',
    label: 'Production (Metal/Wood)',
    icon: '\u2692',
    description: 'Final build quality. Aluminum, brass, steel, wood. CNC or hand-fabricated. Built to last.',
    defaultMaterials: { structural: 'Aluminum', mechanical: 'Steel', decorative: 'Cherry', fasteners: 'Steel' },
    tolerance: '0.1mm',
    process: ['CNC milling', 'Laser cutting', 'Lathe turning', 'Hand finishing'],
  },
  {
    id: 'hybrid',
    label: 'Hybrid (Print + Metal)',
    icon: '\uD83D\uDD27',
    description: 'Print structural, use metal for high-stress and shafts. Best of both worlds.',
    defaultMaterials: { structural: 'PETG', mechanical: 'Steel', decorative: 'Basswood', fasteners: 'Steel' },
    tolerance: '0.2mm',
    process: ['3D print structure', 'Steel shafts + bearings', 'Wood or acrylic elements'],
  },
];

export async function mount(container) {
  const project = getProject();
  const hasType = project?.stages?.build?.buildType;
  currentTab = hasType ? 'materials' : 'type';

  container.innerHTML = `
    <div class="tab-bar">
      <div class="tab ${currentTab === 'type' ? 'active' : ''}" data-tab="type">Build Type</div>
      <div class="tab ${currentTab === 'materials' ? 'active' : ''}" data-tab="materials">Materials</div>
      <div class="tab" data-tab="openscad">OpenSCAD</div>
      <div class="tab" data-tab="bom">Bill of Materials</div>
    </div>
    <div id="build-workspace" class="tool-canvas"></div>
    <div id="build-controls" class="mt"></div>
  `;

  container.querySelectorAll('.tab').forEach(tab => {
    tab.onclick = () => {
      container.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      currentTab = tab.dataset.tab;
      renderTab();
    };
  });

  renderTab();
  updateSidebar();
}

function renderTab() {
  if (currentTab === 'type') renderBuildType();
  else if (currentTab === 'materials') renderMaterials();
  else if (currentTab === 'openscad') renderOpenSCAD();
  else if (currentTab === 'bom') renderBOM();
}

// ────────────────────────────────────────────────────
// BUILD TYPE SELECTION
// ────────────────────────────────────────────────────

function renderBuildType() {
  const workspace = document.getElementById('build-workspace');
  const controls = document.getElementById('build-controls');
  controls.innerHTML = '';

  const project = getProject();
  const currentType = project?.stages?.build?.buildType;

  let html = '<div style="padding: 16px; overflow-y: auto; height: 100%;">';
  html += '<div class="section-title" style="margin-bottom: 8px;">Select Build Type</div>';
  html += '<div style="font-size: 11px; color: var(--text-dim); margin-bottom: 16px;">Choose how you\'ll fabricate this sculpture. This affects material recommendations and code generation.</div>';

  BUILD_TYPES.forEach(bt => {
    const isSelected = currentType === bt.id;
    const borderColor = isSelected ? 'var(--accent)' : 'var(--border)';

    html += `
      <div class="build-type-card" data-type="${bt.id}"
           style="border: 2px solid ${borderColor}; border-radius: var(--radius); padding: 16px; margin-bottom: 12px; cursor: pointer;
                  background: ${isSelected ? 'rgba(79,195,247,0.08)' : 'var(--surface)'};">
        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 8px;">
          <span style="font-size: 24px;">${bt.icon}</span>
          <div>
            <div style="font-weight: 600; font-size: 14px; color: var(--text);">${bt.label}</div>
            <div style="font-size: 11px; color: var(--text-dim);">${bt.description}</div>
          </div>
        </div>
        <div style="font-size: 11px; color: var(--text-dim); display: flex; gap: 16px; flex-wrap: wrap;">
          <span>Tolerance: <strong>${bt.tolerance}</strong></span>
          <span>Process: <strong>${bt.process.join(', ')}</strong></span>
        </div>
        <div style="font-size: 11px; color: var(--text-dim); margin-top: 6px;">
          Defaults: ${Object.entries(bt.defaultMaterials).map(([role, mat]) => `${role}: <strong>${mat}</strong>`).join(' | ')}
        </div>
      </div>
    `;
  });

  html += '</div>';
  workspace.innerHTML = html;

  // Click handlers
  workspace.querySelectorAll('.build-type-card').forEach(card => {
    card.onclick = () => {
      const type = card.dataset.type;
      selectBuildType(type);
    };
  });
}

function selectBuildType(typeId) {
  const project = getProject();
  if (!project) { showToast('No project loaded', 'warning'); return; }

  const bt = BUILD_TYPES.find(t => t.id === typeId);
  if (!bt) return;

  project.stages.build.buildType = typeId;
  project.stages.build.status = 'in_progress';

  // Initialize materials from defaults if not already set
  if (!project.stages.build.materials || Object.keys(project.stages.build.materials).length === 0) {
    project.stages.build.materials = {};
    const mech = project.stages.mechanize?.mechanism;
    const components = mech?.requirements?.components || [];

    components.forEach(comp => {
      const role = guessRole(comp.name);
      project.stages.build.materials[comp.name] = {
        material: bt.defaultMaterials[role] || comp.material?.split(' ')[0] || 'PLA',
        quantity: comp.count,
        role,
      };
    });

    // Add standard components if empty
    if (components.length === 0) {
      project.stages.build.materials = {
        'Motor': { material: 'Steel', quantity: 1, role: 'mechanical' },
        'Main Shaft': { material: bt.defaultMaterials.mechanical, quantity: 1, role: 'mechanical' },
        'Frame': { material: bt.defaultMaterials.structural, quantity: 1, role: 'structural' },
        'Moving Elements': { material: bt.defaultMaterials.decorative, quantity: 6, role: 'decorative' },
        'Bearings': { material: 'Steel', quantity: 4, role: 'fasteners' },
      };
    }
  }

  saveProject(project);
  showToast(`Build type: ${bt.label}`, 'success');
  currentTab = 'materials';
  renderTab();
  updateSidebar();
}

function guessRole(name) {
  const lower = name.toLowerCase();
  if (lower.includes('motor') || lower.includes('shaft') || lower.includes('gear') || lower.includes('cam') || lower.includes('bearing')) return 'mechanical';
  if (lower.includes('frame') || lower.includes('guide') || lower.includes('mount') || lower.includes('support')) return 'structural';
  if (lower.includes('element') || lower.includes('wood') || lower.includes('hanging') || lower.includes('display')) return 'decorative';
  return 'fasteners';
}

// ────────────────────────────────────────────────────
// MATERIALS SELECTION (per-component)
// ────────────────────────────────────────────────────

function renderMaterials() {
  const workspace = document.getElementById('build-workspace');
  const controls = document.getElementById('build-controls');

  const project = getProject();
  const buildType = project?.stages?.build?.buildType;
  const materials = project?.stages?.build?.materials || {};

  if (!buildType) {
    workspace.innerHTML = '<div style="padding: 20px; color: var(--text-dim);">Select a build type first.</div>';
    controls.innerHTML = '';
    return;
  }

  const bt = BUILD_TYPES.find(t => t.id === buildType);
  const materialNames = Object.keys(MATERIALS);

  let html = '<div style="padding: 16px; overflow-y: auto; height: 100%;">';
  html += `
    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 12px;">
      <span style="font-size: 20px;">${bt.icon}</span>
      <span style="font-weight: 600; color: var(--text);">${bt.label}</span>
      <button class="change-type-btn" style="font-size: 10px; padding: 2px 8px; margin-left: auto;">Change Type</button>
    </div>
  `;

  html += '<div class="section-title" style="margin-bottom: 8px;">Per-Component Material Selection</div>';
  html += '<div style="font-size: 11px; color: var(--text-dim); margin-bottom: 12px;">Choose material for each component. System suggests based on stress analysis from Simulate.</div>';

  // Materials table
  html += '<table style="width: 100%; font-size: 11px; border-collapse: collapse;">';
  html += '<tr style="color: var(--text-dim); border-bottom: 1px solid var(--border);">';
  html += '<th style="text-align:left; padding: 6px;">Component</th>';
  html += '<th style="text-align:center; padding: 6px;">Qty</th>';
  html += '<th style="text-align:left; padding: 6px;">Material</th>';
  html += '<th style="text-align:left; padding: 6px;">Properties</th>';
  html += '</tr>';

  Object.entries(materials).forEach(([compName, data]) => {
    const mat = MATERIALS[data.material];
    const roleColor = data.role === 'mechanical' ? '#4fc3f7' : data.role === 'structural' ? '#66bb6a' : data.role === 'decorative' ? '#ffa726' : '#888';

    html += `<tr style="border-bottom: 1px solid var(--border);">`;
    html += `<td style="padding: 6px; color: var(--text);">
      <span style="display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: ${roleColor}; margin-right: 4px;"></span>
      ${compName}
      <div style="font-size: 9px; color: var(--text-dim);">${data.role}</div>
    </td>`;
    html += `<td style="text-align:center; padding: 6px; color: var(--text);">${data.quantity}</td>`;
    html += `<td style="padding: 6px;">
      <select class="mat-select" data-comp="${compName}" style="width: 100%;">
        ${materialNames.map(m => `<option value="${m}" ${data.material === m ? 'selected' : ''}>${m}</option>`).join('')}
      </select>
    </td>`;
    html += `<td style="padding: 6px; font-size: 10px; color: var(--text-dim);">
      ${mat ? `${mat.strength} str | ${mat.friction} friction${mat.outdoor ? ' | outdoor' : ''}` : ''}
    </td>`;
    html += '</tr>';
  });

  html += '</table>';

  // Add component button
  html += `
    <div style="margin-top: 12px; display: flex; gap: 8px;">
      <input id="new-comp-name" type="text" placeholder="Component name" style="flex: 1; font-size: 11px;">
      <input id="new-comp-qty" type="number" value="1" min="1" style="width: 50px; font-size: 11px;">
      <button id="add-comp-btn" style="font-size: 11px; padding: 4px 12px;">+ Add</button>
    </div>
  `;

  // Material legend
  html += `
    <div style="margin-top: 16px; padding: 10px; background: var(--surface); border-radius: var(--radius);">
      <div style="font-size: 11px; font-weight: 600; color: var(--text); margin-bottom: 6px;">Material Legend</div>
      <div style="display: flex; gap: 12px; flex-wrap: wrap; font-size: 10px; color: var(--text-dim);">
        <span><span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:#4fc3f7;"></span> Mechanical (shafts, gears, cams)</span>
        <span><span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:#66bb6a;"></span> Structural (frame, mounts)</span>
        <span><span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:#ffa726;"></span> Decorative (elements, display)</span>
        <span><span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:#888;"></span> Fasteners (pins, bolts)</span>
      </div>
    </div>
  `;

  html += '</div>';
  workspace.innerHTML = html;

  // Controls
  controls.innerHTML = `
    <div class="flex gap" style="flex-wrap: wrap;">
      <button id="save-materials" class="primary">Save Materials</button>
      <button id="suggest-materials">Auto-Suggest</button>
    </div>
  `;

  // Event handlers
  workspace.querySelector('.change-type-btn')?.addEventListener('click', () => {
    currentTab = 'type';
    renderTab();
  });

  workspace.querySelectorAll('.mat-select').forEach(sel => {
    sel.onchange = () => {
      const comp = sel.dataset.comp;
      if (materials[comp]) {
        materials[comp].material = sel.value;
      }
    };
  });

  document.getElementById('add-comp-btn')?.addEventListener('click', () => {
    const name = document.getElementById('new-comp-name')?.value?.trim();
    const qty = parseInt(document.getElementById('new-comp-qty')?.value) || 1;
    if (!name) return;
    if (!project.stages.build.materials) project.stages.build.materials = {};
    project.stages.build.materials[name] = { material: 'PLA', quantity: qty, role: guessRole(name) };
    saveProject(project);
    renderMaterials();
  });

  document.getElementById('save-materials')?.addEventListener('click', () => {
    // Read all selects
    workspace.querySelectorAll('.mat-select').forEach(sel => {
      const comp = sel.dataset.comp;
      if (materials[comp]) materials[comp].material = sel.value;
    });
    project.stages.build.materials = materials;
    saveProject(project);
    showToast('Materials saved', 'success');
    updateSidebar();
  });

  document.getElementById('suggest-materials')?.addEventListener('click', () => {
    suggestMaterials(project);
    renderMaterials();
  });
}

function suggestMaterials(project) {
  const bt = BUILD_TYPES.find(t => t.id === project.stages.build.buildType);
  if (!bt) return;

  const materials = project.stages.build.materials;
  Object.entries(materials).forEach(([name, data]) => {
    data.material = bt.defaultMaterials[data.role] || data.material;
  });

  saveProject(project);
  showToast('Materials auto-suggested based on build type', 'info');
}

// ────────────────────────────────────────────────────
// OPENSCAD CODE TAB
// ────────────────────────────────────────────────────

function renderOpenSCAD() {
  const workspace = document.getElementById('build-workspace');
  const controls = document.getElementById('build-controls');
  const project = getProject();
  const mech = project?.stages?.mechanize?.mechanism;

  workspace.innerHTML = `
    <textarea id="code-editor" rows="20" style="width:100%; height:100%; font-family:var(--mono); font-size:12px; background:#0d1117; color:#c9d1d9; border:none; padding:12px; resize:none;">${generateOpenSCAD(mech, project)}</textarea>
  `;

  controls.innerHTML = `
    <div class="flex gap" style="flex-wrap: wrap;">
      <button id="generate-btn" class="primary">Regenerate</button>
      <button id="copy-btn">Copy to Clipboard</button>
      <button id="save-code-btn">Save Code</button>
    </div>
  `;

  document.getElementById('generate-btn')?.addEventListener('click', () => {
    document.getElementById('code-editor').value = generateOpenSCAD(mech, project);
    showToast('Code regenerated', 'info');
  });

  document.getElementById('copy-btn')?.addEventListener('click', () => {
    navigator.clipboard.writeText(document.getElementById('code-editor')?.value || '');
    showToast('Copied to clipboard', 'success');
  });

  document.getElementById('save-code-btn')?.addEventListener('click', () => {
    const code = document.getElementById('code-editor')?.value || '';
    project.stages.build.generatedCode = code;
    project.stages.build.syntaxErrors = [];
    project.stages.build.status = 'in_progress';
    saveProject(project);
    showToast('Code saved to project', 'success');
    updateSidebar();
  });
}

function generateOpenSCAD(mech, project) {
  if (!mech) {
    return `// No mechanism defined yet
// Go to Mechanize stage to select your mechanism
// Then come back here to generate OpenSCAD code

// Example: crank_angle = $t * 360; for animation
`;
  }

  const buildType = project?.stages?.build?.buildType || 'prototype';
  const materials = project?.stages?.build?.materials || {};
  const config = mech.config || {};
  const family = mech.family || mech.type;

  let code = `// KineticForge — Generated ${mech.familyName || family} Design
// Build type: ${buildType}
// Generated: ${new Date().toISOString()}
//
// Family: ${mech.familyName || family}
`;

  if (family === 'four-bar' && mech.params) {
    const { ground, crank, coupler, rocker } = mech.params;
    code += `
// === FOUR-BAR LINKAGE PARAMETERS ===
ground_length = ${ground};    // mm
crank_length  = ${crank};     // mm
coupler_length = ${coupler};  // mm
rocker_length = ${rocker};    // mm

link_width = 12;
link_thickness = 6;
pin_diameter = 3;
clearance = ${buildType === 'prototype' ? '0.3' : '0.1'};

$fn = ${buildType === 'prototype' ? '32' : '64'};

module link(length) {
    difference() {
        hull() {
            cylinder(d=link_width, h=link_thickness);
            translate([length, 0, 0])
                cylinder(d=link_width, h=link_thickness);
        }
        translate([0, 0, -1])
            cylinder(d=pin_diameter + clearance, h=link_thickness + 2);
        translate([length, 0, -1])
            cylinder(d=pin_diameter + clearance, h=link_thickness + 2);
    }
}

crank_angle = $t * 360;

color("gray") link(ground_length);
rotate([0, 0, crank_angle])
    translate([0, 0, link_thickness + 1])
    color("DodgerBlue") link(crank_length);
`;
  } else if (family === 'camshaft' || family === 'direct-contact') {
    const camCount = config.camCount || config.discsPerShaft || 6;
    const baseR = config.baseRadius || 30;
    const phaseOffset = config.phaseOffset || 360 / camCount;

    code += `
// === CAMSHAFT PARAMETERS ===
cam_count = ${camCount};
base_radius = ${baseR};
phase_offset = ${phaseOffset};  // degrees between adjacent cams
shaft_diameter = 6;
cam_thickness = 5;
eccentricity = ${config.eccentricity || 8};

$fn = ${buildType === 'prototype' ? '64' : '128'};

module disc_cam(eccentricity, phase) {
    rotate([0, 0, phase])
    translate([eccentricity, 0, 0])
    cylinder(r=base_radius, h=cam_thickness);
}

module camshaft() {
    // Central shaft
    color("silver")
    cylinder(d=shaft_diameter, h=cam_count * (cam_thickness + 2) + 10);

    // Individual cams
    for (i = [0:cam_count-1]) {
        translate([0, 0, i * (cam_thickness + 2) + 5])
        rotate([0, 0, $t * 360])
        color("SandyBrown")
        disc_cam(eccentricity, i * phase_offset);
    }
}

camshaft();
`;
  } else if (family === 'eccentric') {
    code += `
// === ECCENTRIC CAM PARAMETERS ===
eccentricity = ${config.eccentricity || 10};
ring_radius = ${config.baseRadius || 25};
ring_thickness = 8;

$fn = ${buildType === 'prototype' ? '64' : '128'};

module eccentric_ring() {
    rotate([0, 0, $t * 360])
    translate([eccentricity, 0, 0])
    difference() {
        cylinder(r=ring_radius, h=ring_thickness);
        translate([0, 0, -1])
        cylinder(r=ring_radius - 5, h=ring_thickness + 2);
    }
}

eccentric_ring();
`;
  } else {
    code += `
// === ${(family || 'MECHANISM').toUpperCase()} PARAMETERS ===
// Configuration: ${JSON.stringify(config, null, 2).replace(/\n/g, '\n// ')}
//
// This mechanism family requires custom OpenSCAD implementation.
// Use the configuration parameters above as your starting point.
// Animate with: $t (0 to 1 = one full cycle)

$fn = 64;

// Placeholder — replace with your design
module placeholder() {
    cylinder(r=20, h=5);
}

rotate([0, 0, $t * 360])
placeholder();
`;
  }

  // Add materials comment block
  if (Object.keys(materials).length > 0) {
    code += `\n// === BILL OF MATERIALS ===\n`;
    Object.entries(materials).forEach(([name, data]) => {
      code += `// ${name}: ${data.quantity}x ${data.material}\n`;
    });
  }

  return code;
}

// ────────────────────────────────────────────────────
// BILL OF MATERIALS TAB
// ────────────────────────────────────────────────────

function renderBOM() {
  const workspace = document.getElementById('build-workspace');
  const controls = document.getElementById('build-controls');
  controls.innerHTML = '';

  const project = getProject();
  const materials = project?.stages?.build?.materials || {};
  const buildType = project?.stages?.build?.buildType;
  const mech = project?.stages?.mechanize?.mechanism;

  let html = '<div style="padding: 16px; overflow-y: auto; height: 100%;">';
  html += '<div class="section-title" style="margin-bottom: 8px;">Bill of Materials</div>';

  if (Object.keys(materials).length === 0) {
    html += '<div class="text-dim">No materials selected. Go to Materials tab first.</div>';
  } else {
    html += '<table style="width:100%; font-size:12px; border-collapse:collapse;">';
    html += '<tr style="color:var(--accent); border-bottom: 2px solid var(--border);">';
    html += '<th style="text-align:left; padding:6px;">Part</th><th style="text-align:center; padding:6px;">Qty</th><th style="text-align:left; padding:6px;">Material</th><th style="text-align:left; padding:6px;">Notes</th>';
    html += '</tr>';

    Object.entries(materials).forEach(([name, data]) => {
      const mat = MATERIALS[data.material];
      html += `<tr style="border-bottom: 1px solid var(--border);">`;
      html += `<td style="padding:6px; color: var(--text);">${name}</td>`;
      html += `<td style="text-align:center; padding:6px; color: var(--text);">${data.quantity}</td>`;
      html += `<td style="padding:6px; color: var(--text);">${data.material}</td>`;
      html += `<td style="padding:6px; font-size:10px; color: var(--text-dim);">${mat?.notes || ''}</td>`;
      html += '</tr>';
    });

    html += '</table>';

    // Assembly notes
    html += `
      <div style="margin-top: 16px; padding: 10px; background: var(--surface); border-radius: var(--radius);">
        <div style="font-weight: 600; font-size: 12px; color: var(--text); margin-bottom: 6px;">Assembly Sequence (Inside-Out Rule)</div>
        <ol style="font-size: 11px; color: var(--text-dim); margin: 0; padding-left: 20px;">
          <li>Main frame / base plate</li>
          <li>Primary bearings / bushings</li>
          <li>Main shaft(s)</li>
          <li>Primary drive (gears / cams)</li>
          <li>Secondary mechanisms</li>
          <li>String routing / cable connections</li>
          <li>Decorative elements</li>
          <li>Final alignment and adjustment</li>
        </ol>
      </div>
    `;

    // First-run protocol
    html += `
      <div style="margin-top: 12px; padding: 10px; background: #1a1a2e; border-left: 3px solid var(--accent); border-radius: 0 var(--radius) var(--radius) 0;">
        <div style="font-weight: 600; font-size: 12px; color: var(--text); margin-bottom: 4px;">First-Run Protocol</div>
        <div style="font-size: 11px; color: var(--text-dim);">
          1. Hand-rotate through full cycle — feel for binding<br>
          2. First power: 2 seconds only — check direction, listen<br>
          3. 1-minute observation — watch for wobble or noise<br>
          4. 10-minute run — check for heating at bearings<br>
          5. Adjust one variable at a time — document changes
        </div>
      </div>
    `;

    // Tolerance reference
    html += `
      <div style="margin-top: 12px; padding: 10px; background: var(--surface); border-radius: var(--radius);">
        <div style="font-weight: 600; font-size: 12px; color: var(--text); margin-bottom: 4px;">Tolerance Quick Reference</div>
        <div style="font-size: 11px; color: var(--text-dim);">
          Press-fit: 0.1-0.15mm | Moving clearance: 0.3-0.5mm | Gear mesh: 0.2mm radial<br>
          3D print tolerance: +/-0.2mm | CNC: +/-0.05mm | Laser: +/-0.1mm
        </div>
      </div>
    `;
  }

  html += '</div>';
  workspace.innerHTML = html;
}

// ────────────────────────────────────────────────────
// SIDEBAR
// ────────────────────────────────────────────────────

function updateSidebar() {
  const project = getProject();
  const sections = [];

  if (project) {
    const build = project.stages.build;
    sections.push({
      title: 'Build Status',
      items: [
        { label: build.buildType ? `Type: ${BUILD_TYPES.find(t => t.id === build.buildType)?.label || build.buildType}` : 'No build type selected', status: build.buildType ? 'pass' : 'pending' },
        { label: build.materials && Object.keys(build.materials).length > 0 ? `${Object.keys(build.materials).length} components defined` : 'No materials defined', status: build.materials && Object.keys(build.materials).length > 0 ? 'pass' : 'pending' },
        { label: build.generatedCode ? 'Code generated' : 'No code generated', status: build.generatedCode ? 'pass' : 'pending' },
      ],
    });

    const gate = validateGate('build', project);
    sections.push({
      title: 'Gate: Build',
      items: gate.passed
        ? [{ label: 'Code generated and valid — Iterate unlocked', status: 'pass' }]
        : gate.errors.map(e => ({ label: e, status: 'fail' })),
    });
  }

  // Guidance
  const guidance = createGuidancePanel('build-build');
  if (guidance) sections.push({ element: guidance });

  const resourceSection = createResourceSection('Resources', 'build', { maxItems: 4, compact: true });
  if (resourceSection) sections.push(resourceSection);

  sections.push({ element: createClaudePanel('build') });
  renderSidebar(sections);
}

export function unmount() {}
