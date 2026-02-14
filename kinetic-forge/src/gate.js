// Gate validation engine — enforces pipeline progression in Build Mode
// Each gate returns { passed: boolean, errors: string[], warnings: string[] }

const gates = {
  mechanize: (project) => {
    const mech = project.stages.mechanize.mechanism;
    const errors = [];

    if (!mech) {
      return { passed: false, errors: ['No mechanism defined'], warnings: [] };
    }

    // Check that a mechanism family has been selected and configured
    if (!mech.validation?.mechanismSelected) {
      errors.push('Select a mechanism family');
    }
    if (!mech.validation?.configured) {
      errors.push('Configure mechanism parameters');
    }

    // Four-bar specific validation
    if (mech.type === 'four-bar' && mech.validation) {
      const v = mech.validation;
      if (v.grashof === false) errors.push('Grashof condition not satisfied: S + L > P + Q');
      if (v.transmissionAngle && v.transmissionAngle.min < 40)
        errors.push(`Transmission angle too low: ${v.transmissionAngle.min.toFixed(1)} deg (min 40)`);
      if (v.transmissionAngle && v.transmissionAngle.max > 140)
        errors.push(`Transmission angle too high: ${v.transmissionAngle.max.toFixed(1)} deg (max 140)`);
      if (v.couplerConstancy > 0.5)
        errors.push(`Coupler stretches by ${v.couplerConstancy.toFixed(2)}mm (max 0.5)`);
    }

    // Power budget check (all families)
    if (mech.validation?.powerBudget && mech.validation.powerBudget.margin < 1.5) {
      errors.push(`Power margin only ${mech.validation.powerBudget.margin.toFixed(1)}x (need 1.5x minimum)`);
    }

    // Cam-specific validation
    if (mech.type === 'cam' && mech.validation) {
      if (!mech.validation.profileValid) errors.push('Cam profile has discontinuities');
      if (mech.validation.pressureAngleMax > 30)
        errors.push(`Pressure angle too high: ${mech.validation.pressureAngleMax.toFixed(1)} deg (max 30)`);
    }

    return { passed: errors.length === 0, errors, warnings: [] };
  },

  simulate: (project) => {
    const sim = project.stages.simulate;
    const errors = [];

    if (!sim.results) {
      return { passed: false, errors: ['Run simulation first'], warnings: [] };
    }

    if (sim.results.lockupDetected) errors.push('Mechanism locks up during rotation');
    if (sim.results.forceNegative) errors.push('Force goes negative (follower separation)');
    if (sim.results.collisionDetected) errors.push('Collision detected between components');
    if (sim.results.motorOverloaded) errors.push('Required torque exceeds motor capacity');

    return { passed: errors.length === 0, errors, warnings: [] };
  },

  build: (project) => {
    const build = project.stages.build;
    const errors = [];

    if (!build.generatedCode) {
      return { passed: false, errors: ['Generate OpenSCAD code first'], warnings: [] };
    }

    if (build.syntaxErrors && build.syntaxErrors.length > 0) {
      errors.push(...build.syntaxErrors.map(e => `Syntax error: ${e}`));
    }

    return { passed: errors.length === 0, errors, warnings: [] };
  },

  iterate: (project) => {
    const iter = project.stages.iterate;
    const errors = [];

    if (!iter.testLogs || iter.testLogs.length === 0) {
      return { passed: false, errors: ['Document at least one test result'], warnings: [] };
    }

    const lastLog = iter.testLogs[iter.testLogs.length - 1];
    if (!lastLog.whatWorked) errors.push('Fill in "what worked"');
    if (!lastLog.whatDidnt) errors.push('Fill in "what didn\'t work"');
    if (!lastLog.measurements || lastLog.measurements.length === 0)
      errors.push('Add at least one measurement');

    return { passed: errors.length === 0, errors, warnings: [] };
  }
};

export function validateGate(stageId, project) {
  const validator = gates[stageId];
  if (!validator) return { passed: true, errors: [], warnings: [] };
  return validator(project);
}

export function canAdvanceTo(targetStageId, project) {
  if (!project) return false;

  const stageOrder = ['mechanize', 'simulate', 'build', 'iterate'];
  const targetIdx = stageOrder.indexOf(targetStageId);
  if (targetIdx <= 0) return true; // Can always go to mechanize

  // All previous stages must be complete
  for (let i = 0; i < targetIdx; i++) {
    const prev = stageOrder[i];
    const gate = validateGate(prev, project);
    if (!gate.passed) return false;
  }
  return true;
}

// Grashof condition helper (exported for use in Mechanize stage)
export function checkGrashof(ground, crank, coupler, rocker) {
  const links = [ground, crank, coupler, rocker].sort((a, b) => a - b);
  const S = links[0]; // shortest
  const L = links[3]; // longest
  const P = links[1];
  const Q = links[2];
  return (S + L) <= (P + Q);
}

// Transmission angle helper
export function calcTransmissionAngle(ground, crank, coupler, rocker, crankAngleDeg) {
  const a = ground, b = crank, c = coupler, d = rocker;
  const theta = crankAngleDeg * Math.PI / 180;

  // Using cosine rule in the four-bar
  const diag = Math.sqrt(a * a + b * b - 2 * a * b * Math.cos(theta));
  if (diag > c + d || diag < Math.abs(c - d)) return null; // Invalid position

  const cosMu = (c * c + d * d - diag * diag) / (2 * c * d);
  const mu = Math.acos(Math.max(-1, Math.min(1, cosMu))) * 180 / Math.PI;
  return mu;
}

// Check transmission angle at 4 positions
export function checkTransmissionAngleRange(ground, crank, coupler, rocker) {
  const angles = [0, 90, 180, 270];
  let min = 180, max = 0;
  let valid = true;

  for (const a of angles) {
    const mu = calcTransmissionAngle(ground, crank, coupler, rocker, a);
    if (mu === null) { valid = false; continue; }
    min = Math.min(min, mu);
    max = Math.max(max, mu);
  }

  return { valid, min, max };
}
