// Mechanism Advisor — analyzes wave/pattern source data and recommends mechanism families
// Based on Margolin Knowledge Bank + Kinetic Sculpture Compendium

// ────────────────────────────────────────────────────
// 8 Mechanism Families (from Margolin taxonomy)
// ────────────────────────────────────────────────────
const MECHANISM_FAMILIES = [
  {
    id: 'camshaft',
    name: 'Camshaft-Driven',
    icon: '\u2699',
    principle: 'Rotating shaft with offset disc cams. Angular position = spatial phase, eccentricity = amplitude.',
    examples: 'Square Wave (2013), Confluence (2024)',
    pros: [
      'Single motor drives complex motion',
      'Tunable amplitude (slide disc along shaft)',
      'Simple to fabricate (bandsaw-cut plywood discs)',
      'Visible overhead mechanism (aesthetic value)',
    ],
    cons: [
      'Discrete phase steps (limited by disc count)',
      'Friction accumulates across followers',
      'Requires string routing from followers to elements',
    ],
    bestFor: 'Two perpendicular waves, tunable amplitude, medium complexity',
    complexity: 'medium',
    cost: 'low',
    precision: 'medium',
    motorCount: '1-2',
    keywords: ['perpendicular', 'tunable', 'disc', 'overhead'],
  },
  {
    id: 'helix',
    name: 'Helix-Driven',
    icon: '\uD83C\uDF00',
    principle: 'Rotating helix shaft acts as continuous cam. Cable wraps around helix, connects to slider blocks.',
    examples: 'Triple Helix (2018), Anemone (2017), Dandelion Wave',
    pros: [
      'Smooth continuous phase variation (infinite resolution)',
      'Single motor per helix',
      'Geometry directly embodies wave equation',
      'Elegant, minimal mechanical complexity per wave',
    ],
    cons: [
      'Precision machining required (lathe for helical cut)',
      'Friction compounds with pulley/slider count',
      'String tension management critical',
      'Harder to prototype with 3D printing',
    ],
    bestFor: 'Smooth phase gradients, 3+ wave components at 120deg, large installations',
    complexity: 'high',
    cost: 'medium',
    precision: 'high',
    motorCount: '1 per helix',
    keywords: ['smooth', 'continuous', 'gradient', 'helix', 'radial'],
  },
  {
    id: 'eccentric',
    name: 'Eccentric Cam / Ring Drive',
    icon: '\u25CB',
    principle: 'Eccentric ring offset from central axis provides simple harmonic motion. String routing distributes motion.',
    examples: 'River Loom (2016), Helio Curve (2016)',
    pros: [
      'Very simple mechanism',
      'Compact footprint',
      'Easy to scale (duplicate in parallel)',
      'Low fabrication complexity',
    ],
    cons: [
      'Pure sine output only (single frequency)',
      'Needs string routing for spatial distribution',
      'Limited harmonic content without superposition',
    ],
    bestFor: 'Simple harmonic motion, scalable parallel arrays, entry-level builds',
    complexity: 'low',
    cost: 'low',
    precision: 'low',
    motorCount: '1',
    keywords: ['simple', 'harmonic', 'parallel', 'eccentric', 'ring'],
  },
  {
    id: 'string-weave',
    name: 'String-Weave / Loom',
    icon: '\uD83E\uDDF5',
    principle: 'Strings routed through matrix of pulleys. Weave pattern determines how input maps to output at each point.',
    examples: 'Confluence (2024), Interlaced (2019), Cadence (2019)',
    pros: [
      'Extremely flexible topology (arbitrary geometry)',
      'Can create complex interference (two waveforms pass through each other)',
      'Nearly silent operation',
      'Single motor for wide distribution',
    ],
    cons: [
      'Design complexity (must compute string paths)',
      'Pulley friction accumulates (max ~9 in series)',
      'Precise pulley placement required',
      'Debugging difficult (many strings)',
    ],
    bestFor: 'Arbitrary topology, interference patterns, large flat sculptures',
    complexity: 'very-high',
    cost: 'medium',
    precision: 'high',
    motorCount: '1-2',
    keywords: ['topology', 'interference', 'flat', 'weave', 'loom', 'string'],
  },
  {
    id: 'fourier-sprocket',
    name: 'Multi-Frequency Fourier (Sprocket Chain)',
    icon: '\u2211',
    principle: 'Integer-ratio sprocket chains maintain exact frequency relationships. Motion = Fourier series sum.',
    examples: 'Arc Line (2024), Fourier Caterpillar',
    pros: [
      'Pure Fourier decomposition mechanized',
      'Exact integer frequency ratios',
      'Single motor input, multiple frequencies out',
      'Mathematically precise',
    ],
    cons: [
      'Limited to integer frequency ratios',
      'Cycle period can be extremely long (LCM of ratios)',
      'Space required for parallel sprocket chains',
      'Off-the-shelf sprocket sizes constrain ratios',
    ],
    bestFor: 'Multiple exact frequency components, Fourier synthesis, mathematical art',
    complexity: 'medium',
    cost: 'medium',
    precision: 'medium',
    motorCount: '1',
    keywords: ['fourier', 'frequency', 'sprocket', 'ratio', 'chain'],
  },
  {
    id: 'topology',
    name: 'Topology + Waves (Non-Euclidean)',
    icon: '\u221E',
    principle: 'Wave equation mapped onto non-Euclidean surfaces (Mobius, torus, sphere, trefoil).',
    examples: 'Mobius Wave (2015), Trefoil (2025), Dandelion Wave',
    pros: [
      'Unique aesthetic (unexpected motion patterns)',
      'Mathematical elegance',
      'Single motor for complex 3D motion',
    ],
    cons: [
      'Extremely complex fabrication',
      'Difficult to mechanically drive (curved surfaces)',
      'Requires deep mathematical analysis',
      'Hard to prototype',
    ],
    bestFor: 'Artistic expression, non-Euclidean surfaces, advanced projects',
    complexity: 'very-high',
    cost: 'very-high',
    precision: 'very-high',
    motorCount: '1',
    keywords: ['mobius', 'torus', 'sphere', 'topology', 'surface'],
  },
  {
    id: 'epicycloid',
    name: 'Epicycloid / Parametric Path',
    icon: '\uD83D\uDD04',
    principle: 'Nested rotating systems trace complex paths. Sprocket combinations explored computationally.',
    examples: 'Arc Line (2024), Trefoil (2025)',
    pros: [
      'Mathematically elegant (complex numbers visible)',
      'Dynamic visual effect (perceived 3D from 2D)',
      'Compact mechanical footprint',
    ],
    cons: [
      'Motion is actually planar (visual illusion)',
      'Careful phase calculations needed',
      'Perceived depth is brain-dependent',
    ],
    bestFor: 'Visual 3D illusions from planar motion, ring/loop sculptures',
    complexity: 'medium',
    cost: 'low',
    precision: 'medium',
    motorCount: '1',
    keywords: ['epicycloid', 'parametric', 'planar', 'loop', 'ring', 'nested'],
  },
  {
    id: 'direct-contact',
    name: 'Direct Cam-Follower Contact',
    icon: '\u2B06',
    principle: 'Followers sit directly on cam surface. No strings — mechanical contact transmits motion.',
    examples: 'Automata, traditional cam mechanisms',
    pros: [
      'No string routing (simpler assembly)',
      'Immediate response (no cable stretch)',
      'Precise motion profile from cam shape',
      'Easy to 3D print and test',
    ],
    cons: [
      'Gravity return only (or spring return)',
      'Cam surface wear over time',
      'Follower must stay in contact (no tension)',
      'Limited spatial distribution (followers near cam)',
    ],
    bestFor: 'Desktop-scale automata, prototype testing, direct vertical motion',
    complexity: 'low',
    cost: 'low',
    precision: 'medium',
    motorCount: '1',
    keywords: ['direct', 'contact', 'follower', 'gravity', 'automata', 'desktop'],
  },
];

// ────────────────────────────────────────────────────
// Recommendation Engine
// ────────────────────────────────────────────────────

/**
 * Analyze a sourcePattern (from Experiment mode) and return ranked mechanism recommendations.
 * @param {object} sourcePattern - { type, waves, interaction, expression, ... }
 * @returns {object[]} Ranked recommendations with scores and rationale
 */
export function recommendMechanisms(sourcePattern) {
  if (!sourcePattern) {
    return MECHANISM_FAMILIES.map(f => ({ ...f, score: 50, rationale: 'No source pattern — showing all options', rank: 0 }));
  }

  const scores = MECHANISM_FAMILIES.map(family => {
    let score = 50; // Base score
    const reasons = [];

    const waveCount = countWaves(sourcePattern);
    const hasMultipleFreqs = hasDistinctFrequencies(sourcePattern);
    const maxAmplitude = getMaxAmplitude(sourcePattern);
    const hasPerpendicularWaves = checkPerpendicular(sourcePattern);
    const hasRadialSymmetry = checkRadialSymmetry(sourcePattern);
    const interactionMode = sourcePattern.interaction || 'superposition';

    // ── Wave Count Scoring ──
    if (waveCount === 1) {
      if (family.id === 'eccentric') { score += 25; reasons.push('Single wave → eccentric is simplest'); }
      if (family.id === 'direct-contact') { score += 20; reasons.push('Single wave → direct cam contact works well'); }
      if (family.id === 'helix') { score -= 15; reasons.push('Helix overkill for single wave'); }
      if (family.id === 'string-weave') { score -= 20; reasons.push('String-weave overkill for single wave'); }
    } else if (waveCount === 2) {
      if (family.id === 'camshaft' && hasPerpendicularWaves) { score += 30; reasons.push('2 perpendicular waves = classic Margolin camshaft setup'); }
      if (family.id === 'eccentric') { score += 10; reasons.push('2 eccentrics in parallel work well'); }
      if (family.id === 'fourier-sprocket' && hasMultipleFreqs) { score += 15; reasons.push('2 frequency components → sprocket chain viable'); }
    } else if (waveCount >= 3) {
      if (family.id === 'helix') { score += 25; reasons.push(`${waveCount} waves → helix provides smooth continuous phase`); }
      if (family.id === 'camshaft') { score += 15; reasons.push(`${waveCount} cams on shared shaft`); }
      if (family.id === 'fourier-sprocket' && hasMultipleFreqs) { score += 20; reasons.push('Multiple frequency components → Fourier sprocket chain'); }
      if (family.id === 'string-weave') { score += 15; reasons.push('Complex patterns → string-weave offers flexible topology'); }
      if (family.id === 'eccentric') { score -= 10; reasons.push('Many waves harder with simple eccentric alone'); }
    }

    // ── Radial Symmetry ──
    if (hasRadialSymmetry) {
      if (family.id === 'helix') { score += 20; reasons.push('Radial symmetry → helices at equal angles (Margolin Triple Helix)'); }
      if (family.id === 'camshaft') { score -= 5; reasons.push('Radial symmetry less natural for linear camshafts'); }
    }

    // ── Perpendicular Waves ──
    if (hasPerpendicularWaves && waveCount === 2) {
      if (family.id === 'camshaft') { score += 20; reasons.push('Perpendicular waves = 2 perpendicular camshafts (Square Wave pattern)'); }
    }

    // ── Interaction Mode ──
    if (interactionMode === 'product') {
      if (family.id === 'string-weave') { score += 15; reasons.push('Product interaction → string-weave can multiply via routing'); }
      if (family.id === 'fourier-sprocket') { score -= 10; reasons.push('Product interaction not natural for Fourier sprockets'); }
    }

    // ── Multiple Distinct Frequencies ──
    if (hasMultipleFreqs) {
      if (family.id === 'fourier-sprocket') { score += 20; reasons.push('Distinct frequencies → integer-ratio sprocket chains'); }
    }

    // ── Pattern Type ──
    if (sourcePattern.type === 'pattern') {
      if (family.id === 'epicycloid') { score += 15; reasons.push('Parametric pattern → epicycloid path tracing'); }
      if (family.id === 'topology') { score += 10; reasons.push('Parametric patterns can map to non-Euclidean surfaces'); }
    }

    // ── Complexity vs Accessibility ──
    // Boost simpler options slightly (user is learning)
    if (family.complexity === 'low') score += 5;
    if (family.complexity === 'very-high') score -= 5;

    return {
      ...family,
      score: Math.max(0, Math.min(100, score)),
      rationale: reasons.length > 0 ? reasons.join('. ') + '.' : 'General-purpose option.',
      waveCount,
    };
  });

  // Sort by score descending
  scores.sort((a, b) => b.score - a.score);

  // Assign ranks
  scores.forEach((s, i) => { s.rank = i + 1; });

  return scores;
}

/**
 * Get details for configuring a selected mechanism family
 * @param {string} familyId
 * @param {object} sourcePattern
 * @returns {object} Configuration details and parameters
 */
export function getMechanismConfig(familyId, sourcePattern) {
  const waveCount = countWaves(sourcePattern);
  const waves = getWaves(sourcePattern);

  const configs = {
    camshaft: {
      title: 'Camshaft Configuration',
      description: 'Disc cams on rotating shaft(s). Each cam\'s angular offset = phase, eccentricity = amplitude.',
      parameters: [
        { id: 'shaftCount', label: 'Number of shafts', type: 'number', default: Math.min(waveCount, 2), min: 1, max: 4, help: '1 shaft per wave direction. 2 perpendicular = Margolin Square Wave.' },
        { id: 'discsPerShaft', label: 'Discs per shaft', type: 'number', default: Math.max(waveCount * 3, 9), min: 3, max: 50, help: 'More discs = finer phase resolution. Margolin used 9 at 45deg offset.' },
        { id: 'phaseOffset', label: 'Phase offset per disc (deg)', type: 'number', default: 360 / Math.max(waveCount * 3, 9), min: 5, max: 90, help: 'Angular offset between adjacent discs.' },
        { id: 'baseRadius', label: 'Base disc radius (mm)', type: 'number', default: 30, min: 10, max: 100, help: 'Radius of the base circle. Eccentricity adds to this.' },
        { id: 'transmission', label: 'Transmission type', type: 'select', options: ['String + gravity return', 'String + spring return', 'Direct follower'], default: 'String + gravity return' },
      ],
      formula: 'h = A_i * sin(shaft_angle + phase_offset_i)',
      notes: 'Variable amplitude: slide disc along shaft to change eccentricity per station.',
    },
    helix: {
      title: 'Helix Drive Configuration',
      description: 'Rotating helix shafts. Cable wraps around helix, connects to slider blocks. Block height = sum of displacements.',
      parameters: [
        { id: 'helixCount', label: 'Number of helices', type: 'number', default: waveCount, min: 1, max: 6, help: 'One helix per wave component. Triple Helix uses 3 at 120deg.' },
        { id: 'helixAngle', label: 'Angle between helices (deg)', type: 'number', default: waveCount >= 3 ? 120 : 90, min: 30, max: 180, help: 'Angular spacing. 120deg for 3 helices, 90deg for 4.' },
        { id: 'slidersPerHelix', label: 'Sliders per helix', type: 'number', default: 37, min: 5, max: 100, help: 'Distributed along helix = continuous phase sampling. Margolin uses 37.' },
        { id: 'helixPitch', label: 'Helix pitch (mm/rev)', type: 'number', default: 50, min: 10, max: 200, help: 'Distance along shaft per revolution. Determines wavelength.' },
        { id: 'cableType', label: 'Cable type', type: 'select', options: ['1/16" steel cable', 'Fishing line', 'Braided Dyneema'], default: '1/16" steel cable' },
      ],
      formula: 'block_height = sin(phase_a) + sin(phase_b) + sin(phase_c)',
      notes: 'Friction limit: ~9 pulleys in series max. Parallelize instead of cascading.',
    },
    eccentric: {
      title: 'Eccentric Cam Configuration',
      description: 'Simple eccentric offset from central axis. String routing distributes the harmonic motion spatially.',
      parameters: [
        { id: 'eccentricCount', label: 'Number of eccentrics', type: 'number', default: Math.min(waveCount, 2), min: 1, max: 4, help: 'River Loom uses 2 eccentrics through pentagonal web.' },
        { id: 'eccentricity', label: 'Eccentricity (mm)', type: 'number', default: getMaxAmplitude(sourcePattern) * 5 || 10, min: 2, max: 50, help: 'Offset from center = amplitude of motion.' },
        { id: 'baseRadius', label: 'Base radius (mm)', type: 'number', default: 25, min: 10, max: 80, help: 'Outer radius of eccentric ring.' },
        { id: 'stringCount', label: 'Number of strings', type: 'number', default: 37, min: 5, max: 300, help: 'Use PRIME numbers to avoid visual repetition (Margolin: 271).' },
        { id: 'returnMethod', label: 'Return method', type: 'select', options: ['Gravity', 'Spring', 'Magnetic'], default: 'Gravity' },
      ],
      formula: 'h(t) = eccentricity * sin(omega * t)',
      notes: 'Prime number string counts avoid Moire patterns. River Loom uses 271 (prime).',
    },
    'string-weave': {
      title: 'String-Weave Configuration',
      description: 'Strings routed through matrix of pulleys. The weave pattern encodes the motion mapping function.',
      parameters: [
        { id: 'gridType', label: 'Grid type', type: 'select', options: ['Rectangular', 'Hexagonal', 'Radial'], default: 'Rectangular', help: 'Hex grids produce smoother wave propagation.' },
        { id: 'gridWidth', label: 'Grid width (elements)', type: 'number', default: 12, min: 3, max: 50, help: 'Number of elements across.' },
        { id: 'gridHeight', label: 'Grid height (elements)', type: 'number', default: 12, min: 3, max: 50, help: 'Number of elements deep.' },
        { id: 'maxPulleysInSeries', label: 'Max pulleys in series', type: 'number', default: 7, min: 3, max: 9, help: 'HARD LIMIT: 9. After 9 pulleys, 63% efficiency. Parallelize instead.' },
        { id: 'inputMotors', label: 'Input motors', type: 'number', default: 1, min: 1, max: 4, help: 'More motors = more independent waveforms.' },
      ],
      formula: 'F_out = F_in * 0.95^n (n = pulleys in series)',
      notes: 'For N pulleys: 2^N possible paths. String naturally finds shortest. Cadence: nearly silent.',
    },
    'fourier-sprocket': {
      title: 'Fourier Sprocket Chain Configuration',
      description: 'Integer-ratio sprocket chains maintain exact frequency relationships between wave components.',
      parameters: [
        { id: 'componentCount', label: 'Frequency components', type: 'number', default: waveCount, min: 2, max: 6, help: 'Each component gets its own sprocket chain.' },
        { id: 'sprocketTeeth', label: 'Sprocket teeth (comma-sep)', type: 'text', default: getSprocketSuggestion(waves), help: 'Integer ratios determine frequency ratios. Arc Line: 20,21,27,35.' },
        { id: 'motorRPM', label: 'Motor RPM', type: 'number', default: 10, min: 1, max: 60, help: 'Input speed. Output speeds = RPM * (driver/driven).' },
        { id: 'outputType', label: 'Output type', type: 'select', options: ['Vertical sliders', 'Ring oscillators', 'Tapered pulleys'], default: 'Vertical sliders' },
      ],
      formula: 'Cycle period = LCM(all teeth counts) / motor_speed',
      notes: 'Arc Line: LCM(20,21,27,35) = 19,740 teeth = 27-minute cycle at 1 RPM.',
    },
    topology: {
      title: 'Topology + Waves Configuration',
      description: 'Wave equation mapped onto non-Euclidean surface. Continuity constraints at topology junctions.',
      parameters: [
        { id: 'surface', label: 'Surface type', type: 'select', options: ['Mobius strip', 'Torus', 'Sphere', 'Trefoil knot', 'Cylinder'], default: 'Cylinder' },
        { id: 'wavelengths', label: 'Wavelengths (should be n+0.5 for Mobius)', type: 'number', default: 3.5, min: 0.5, max: 10, step: 0.5, help: 'Mobius: use half-integer (3.5) to avoid cancellation at twist.' },
        { id: 'elementCount', label: 'Elements along surface', type: 'number', default: 48, min: 12, max: 200, help: 'Dandelion Wave: 132 geodesic points on sphere.' },
        { id: 'material', label: 'Element material', type: 'select', options: ['Cherry wood', 'Basswood', 'Aluminum', '3D Print PLA'], default: 'Cherry wood' },
      ],
      formula: 'Constraint: wave must be continuous at topology junction',
      notes: 'Mobius: solve shape flat → drill holes flat → bend with jig. 3.5 wavelengths avoids cancellation.',
    },
    epicycloid: {
      title: 'Epicycloid / Parametric Path Configuration',
      description: 'Nested rotating systems trace complex paths. Perceived 3D from 2D planar motion.',
      parameters: [
        { id: 'axisCount', label: 'Rotation axes', type: 'number', default: 2, min: 2, max: 4, help: 'Arc Line uses 4 axes from single rotation.' },
        { id: 'ringCount', label: 'Number of rings/elements', type: 'number', default: 12, min: 4, max: 30, help: 'Phase-offset elements. Arc Line: 20 steel rings.' },
        { id: 'phaseStep', label: 'Phase step between elements (deg)', type: 'number', default: 18, min: 5, max: 45 },
        { id: 'swingAmplitude', label: 'Swing amplitude (deg)', type: 'number', default: 30, min: 5, max: 90, help: 'Angular range of each element.' },
      ],
      formula: 'z(t) = A*e^(i*omega*t) — brain infers imaginary component',
      notes: 'Brain interprets 2D planar motion as 3D via minimum-curvature assumption.',
    },
    'direct-contact': {
      title: 'Direct Cam-Follower Configuration',
      description: 'Followers sit directly on cam surface. No strings — mechanical contact transmits motion.',
      parameters: [
        { id: 'camCount', label: 'Number of cams', type: 'number', default: waveCount, min: 1, max: 20, help: 'One cam per follower. All on shared shaft with phase offsets.' },
        { id: 'sharedShaft', label: 'Shared shaft?', type: 'select', options: ['Yes (single shaft)', 'No (individual shafts)'], default: 'Yes (single shaft)' },
        { id: 'camProfile', label: 'Cam profile', type: 'select', options: ['Harmonic (sine)', 'Cycloidal', 'Modified trapezoid', 'Custom polynomial'], default: 'Harmonic (sine)' },
        { id: 'followerType', label: 'Follower type', type: 'select', options: ['Flat', 'Roller', 'Spherical'], default: 'Roller' },
        { id: 'returnType', label: 'Return mechanism', type: 'select', options: ['Gravity', 'Spring', 'Conjugate cam'], default: 'Gravity' },
      ],
      formula: 'h(theta) = base_radius + rise * cam_profile(theta)',
      notes: 'Best for desktop prototyping. 3D printable. Test cam profiles before scaling up.',
    },
  };

  return configs[familyId] || null;
}

/**
 * Calculate mechanism requirements from source pattern + selected family
 * @param {string} familyId
 * @param {object} sourcePattern
 * @param {object} configParams - User-selected configuration parameters
 * @returns {object} Requirements summary
 */
export function calculateRequirements(familyId, sourcePattern, configParams) {
  const waveCount = countWaves(sourcePattern);
  const waves = getWaves(sourcePattern);

  const requirements = {
    components: [],
    estimatedParts: 0,
    estimatedStrings: 0,
    estimatedPulleys: 0,
    motorCount: 1,
    estimatedWeight: 'TBD in Simulate',
    frictionBudget: null,
    notes: [],
  };

  switch (familyId) {
    case 'camshaft': {
      const shafts = configParams?.shaftCount || Math.min(waveCount, 2);
      const discs = configParams?.discsPerShaft || 9;
      requirements.components.push(
        { name: 'Motor', count: 1, material: 'N20 geared DC or NEMA 17' },
        { name: 'Camshaft', count: shafts, material: 'Steel rod + plywood discs' },
        { name: 'Disc cam', count: shafts * discs, material: 'Plywood or 3D print' },
        { name: 'Cam follower', count: shafts * discs, material: 'Roller or flat' },
        { name: 'String/cable', count: shafts * discs, material: 'Fishing line' },
        { name: 'Hanging element', count: discs, material: 'Wood or acrylic' },
      );
      requirements.estimatedParts = 3 + shafts * discs * 3;
      requirements.estimatedStrings = shafts * discs;
      requirements.motorCount = 1;
      requirements.notes.push('Variable amplitude: slide disc along shaft to tune.');
      break;
    }
    case 'helix': {
      const helices = configParams?.helixCount || waveCount;
      const sliders = configParams?.slidersPerHelix || 37;
      requirements.components.push(
        { name: 'Motor', count: 1, material: 'NEMA 17 stepper' },
        { name: 'Helix shaft', count: helices, material: 'Aluminum (lathe-cut)' },
        { name: 'Slider block', count: helices * sliders, material: 'Polycarbonate' },
        { name: 'Steel cable', count: helices * sliders, material: '1/16" steel cable' },
        { name: 'Bearing', count: helices * sliders, material: '623 (3mm bore)' },
      );
      requirements.estimatedParts = helices * sliders * 3;
      requirements.estimatedStrings = helices * sliders;
      requirements.motorCount = 1;
      requirements.frictionBudget = { pulleys: sliders, efficiency: Math.pow(0.95, Math.min(sliders, 9)).toFixed(2) };
      requirements.notes.push('Friction limit: max 9 pulleys in series (63% efficiency).');
      break;
    }
    case 'eccentric': {
      const count = configParams?.eccentricCount || 1;
      const strings = configParams?.stringCount || 37;
      requirements.components.push(
        { name: 'Motor', count: 1, material: 'N20 geared DC' },
        { name: 'Eccentric ring', count: count, material: 'Aluminum or 3D print' },
        { name: 'String', count: strings, material: 'Fishing line' },
        { name: 'Hanging element', count: strings, material: 'Wood or acrylic' },
      );
      requirements.estimatedParts = 2 + count + strings * 2;
      requirements.estimatedStrings = strings;
      requirements.motorCount = 1;
      requirements.notes.push('Use PRIME number string count to avoid Moire.');
      break;
    }
    case 'direct-contact': {
      const cams = configParams?.camCount || waveCount;
      requirements.components.push(
        { name: 'Motor', count: 1, material: 'N20 geared DC' },
        { name: 'Shared shaft', count: 1, material: 'Steel rod 6mm' },
        { name: 'Disc cam', count: cams, material: '3D print PLA/PETG' },
        { name: 'Cam follower', count: cams, material: 'Roller (608 bearing)' },
        { name: 'Follower guide', count: cams, material: '3D print' },
      );
      requirements.estimatedParts = 3 + cams * 3;
      requirements.motorCount = 1;
      requirements.notes.push('Best for desktop prototyping. 3D printable.');
      break;
    }
    default:
      requirements.notes.push('Detailed part count calculated in Simulate stage.');
  }

  return requirements;
}

export function getFamilies() {
  return MECHANISM_FAMILIES;
}

export function getFamily(id) {
  return MECHANISM_FAMILIES.find(f => f.id === id) || null;
}

// ────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────

function countWaves(sp) {
  if (!sp) return 0;
  if (sp.waves && Array.isArray(sp.waves)) {
    return sp.waves.filter(w => w.enabled !== false && (w.A > 0 || w.amplitude > 0)).length;
  }
  return 1;
}

function getWaves(sp) {
  if (!sp) return [];
  if (sp.waves && Array.isArray(sp.waves)) {
    return sp.waves.filter(w => w.enabled !== false);
  }
  return [];
}

function getMaxAmplitude(sp) {
  const waves = getWaves(sp);
  if (waves.length === 0) return 1;
  return Math.max(...waves.map(w => w.A || w.amplitude || 1));
}

function hasDistinctFrequencies(sp) {
  const waves = getWaves(sp);
  if (waves.length < 2) return false;
  const freqs = waves.map(w => {
    const kx = w.kx || w.freqX || w.k || 1;
    const ky = w.ky || w.freqY || 0;
    return Math.sqrt(kx * kx + ky * ky);
  });
  // Check if any two frequencies differ by more than 10%
  for (let i = 0; i < freqs.length; i++) {
    for (let j = i + 1; j < freqs.length; j++) {
      if (Math.abs(freqs[i] - freqs[j]) / Math.max(freqs[i], freqs[j]) > 0.1) return true;
    }
  }
  return false;
}

function checkPerpendicular(sp) {
  const waves = getWaves(sp);
  if (waves.length < 2) return false;
  // Check if any two waves have roughly perpendicular propagation directions
  for (let i = 0; i < waves.length; i++) {
    for (let j = i + 1; j < waves.length; j++) {
      const kx1 = waves[i].kx || waves[i].freqX || waves[i].k || 1;
      const ky1 = waves[i].ky || waves[i].freqY || 0;
      const kx2 = waves[j].kx || waves[j].freqX || waves[j].k || 1;
      const ky2 = waves[j].ky || waves[j].freqY || 0;
      const dot = kx1 * kx2 + ky1 * ky2;
      const mag1 = Math.sqrt(kx1 * kx1 + ky1 * ky1);
      const mag2 = Math.sqrt(kx2 * kx2 + ky2 * ky2);
      if (mag1 > 0 && mag2 > 0) {
        const cosAngle = Math.abs(dot / (mag1 * mag2));
        if (cosAngle < 0.3) return true; // Within ~73deg-107deg of perpendicular
      }
    }
  }
  return false;
}

function checkRadialSymmetry(sp) {
  const waves = getWaves(sp);
  if (waves.length < 3) return false;
  // Check if waves are approximately evenly spaced in angle
  const angles = waves.map(w => {
    const kx = w.kx || w.freqX || w.k || 1;
    const ky = w.ky || w.freqY || 0;
    return Math.atan2(ky, kx);
  }).sort((a, b) => a - b);

  const expectedGap = (2 * Math.PI) / waves.length;
  let radial = true;
  for (let i = 1; i < angles.length; i++) {
    const gap = angles[i] - angles[i - 1];
    if (Math.abs(gap - expectedGap) > 0.5) { radial = false; break; }
  }
  return radial;
}

function getSprocketSuggestion(waves) {
  if (waves.length === 0) return '20,21';
  // Map wave frequencies to approximate integer ratios
  const freqs = waves.map(w => {
    const kx = w.kx || w.freqX || w.k || 1;
    const ky = w.ky || w.freqY || 0;
    return Math.round(Math.sqrt(kx * kx + ky * ky) * 10);
  });
  // Normalize to smallest
  const minF = Math.max(1, Math.min(...freqs));
  const teeth = freqs.map(f => Math.max(12, Math.round((f / minF) * 20)));
  return teeth.join(',');
}
