// Central Resource Registry — External links organized by context, category, and tags
// Every link opens in a new browser tab. The app is a launchpad, not a container.

export const RESOURCES = [
  // ===========================
  // ONLINE TOOLS & SIMULATORS
  // ===========================
  { id: '507movements', name: '507 Mechanical Movements', url: 'http://507movements.com/',
    category: 'tool', tags: ['reference', 'mechanisms', 'all'],
    description: 'Animated catalog of 507 historical mechanisms',
    contexts: ['discover', 'dashboard', 'exercises', 'curriculum-mechanisms', 'playground-mechanisms'] },

  { id: 'motiongen', name: 'MotionGen Pro', url: 'https://motiongen.io/',
    category: 'tool', tags: ['linkage', 'synthesis', 'fourBar'],
    description: 'AI-driven path synthesis \u2014 draw curve, get linkage',
    contexts: ['mechanize', 'exercises-fourBar', 'skills-fourBar', 'playground-linkage', 'playground-mechanisms'] },

  { id: 'pmks', name: 'PMKS+', url: 'https://designengrlab.github.io/PMKS/',
    category: 'tool', tags: ['linkage', 'fourBar', 'simulation'],
    description: 'Planar Mechanism Kinematic Simulator',
    contexts: ['mechanize', 'exercises-fourBar', 'skills-fourBar', 'playground-linkage', 'playground-mechanisms'] },

  { id: 'geargenerator', name: 'Gear Generator', url: 'https://geargenerator.com/',
    category: 'tool', tags: ['gears', 'design'],
    description: 'Interactive involute spur gear designer',
    contexts: ['build', 'skills-gears', 'exercises-gears', 'playground-tools'] },

  { id: 'desmos', name: 'Desmos', url: 'https://www.desmos.com/calculator',
    category: 'tool', tags: ['graphing', 'waves', 'math'],
    description: 'Interactive graphing calculator',
    contexts: ['exercises-waves', 'playground-graph', 'discover', 'playground-tools'] },

  { id: 'geogebra', name: 'GeoGebra', url: 'https://www.geogebra.org/geometry',
    category: 'tool', tags: ['geometry', 'graphing', 'fourBar'],
    description: 'Dynamic geometry & algebra tool',
    contexts: ['exercises-fourBar', 'playground-graph', 'playground-tools'] },

  { id: 'polyhedra-viewer', name: 'Polyhedra Viewer', url: 'https://polyhedra.tessera.li/',
    category: 'tool', tags: ['geometry', '3d', 'math'],
    description: 'Interactive 3D polyhedra explorer',
    contexts: ['playground', 'playground-tools'] },

  { id: 'kmoddl', name: 'KMODDL (Cornell)', url: 'https://kmoddl.library.cornell.edu/',
    category: 'tool', tags: ['mechanisms', 'reference', 'historical'],
    description: 'Kinematic Models for Design Digital Library',
    contexts: ['discover', 'curriculum-mechanisms', 'playground-mechanisms'] },

  { id: 'mevirtuoso', name: 'MEvirtuoso', url: 'https://www.mevirtuoso.com/',
    category: 'tool', tags: ['fourBar', 'linkage', 'simulation'],
    description: 'Mechanism design and analysis tool',
    contexts: ['exercises-fourBar', 'mechanize', 'playground-mechanisms'] },

  { id: 'strandbeest-optimizer', name: 'Strandbeest Leg Simulator', url: 'https://www.diywalkers.com/strandbeest-leg-simulator.html',
    category: 'tool', tags: ['walking', 'linkage', 'jansen'],
    description: 'Interactive Jansen leg linkage simulator — adjust ratios, see leg path',
    contexts: ['exercises-walking', 'curriculum-mechanisms', 'playground-mechanisms'] },

  { id: 'diy-walkers', name: 'DIY Walkers', url: 'https://www.diywalkers.com/',
    category: 'tool', tags: ['walking', 'linkage', 'build'],
    description: 'Walking mechanism design resources & plans',
    contexts: ['exercises-walking', 'iterate', 'playground-mechanisms'] },

  { id: 'woodgears', name: 'Woodgears.ca', url: 'https://woodgears.ca/',
    category: 'tool', tags: ['gears', 'woodworking', 'mechanisms'],
    description: 'Gear template generator & woodworking mechanisms',
    contexts: ['skills-gears', 'build'] },

  { id: 'mechanical-toys', name: 'Mechanical Toys', url: 'http://mechanical-toys.com/',
    category: 'tool', tags: ['reference', 'automata', 'mechanisms'],
    description: 'Catalog of mechanical toy mechanisms',
    contexts: ['discover'] },

  // ===========================
  // GITHUB REPOSITORIES
  // ===========================
  { id: 'bosl2', name: 'BOSL2', url: 'https://github.com/BelfrySCAD/BOSL2',
    category: 'repo', tags: ['openscad', 'library', 'parametric'],
    description: 'Belfry OpenSCAD Library v2 \u2014 essential parametric toolbox',
    contexts: ['build', 'skills-openscad', 'curriculum-digital'] },

  { id: 'nopscadlib', name: 'NopSCADlib', url: 'https://github.com/nophead/NopSCADlib',
    category: 'repo', tags: ['openscad', 'library', 'hardware'],
    description: 'OpenSCAD library of common vitamins & hardware',
    contexts: ['build', 'skills-openscad', 'curriculum-digital'] },

  { id: 'pyslvs', name: 'Pyslvs-UI', url: 'https://github.com/KmolYuan/Pyslvs-UI',
    category: 'repo', tags: ['linkage', 'synthesis', 'python'],
    description: 'Open-source planar linkage synthesis tool',
    contexts: ['mechanize', 'skills-fourBar', 'exercises-fourBar'] },

  { id: 'mechanism-py', name: 'mechanism (Python)', url: 'https://github.com/samuelsadok/mechanism',
    category: 'repo', tags: ['simulation', 'python', 'fourBar'],
    description: 'Python library for mechanism simulation',
    contexts: ['simulate', 'exercises-cams', 'skills-simulation', 'exercises-simulation'] },

  { id: 'openscad-repo', name: 'OpenSCAD', url: 'https://github.com/openscad/openscad',
    category: 'repo', tags: ['openscad', 'cad', 'core'],
    description: 'OpenSCAD \u2014 the programmer\'s solid 3D CAD modeller',
    contexts: ['skills-openscad'] },

  { id: 'grabcad', name: 'GrabCAD', url: 'https://grabcad.com/library',
    category: 'repo', tags: ['cad', 'models', '3d'],
    description: 'Free CAD model community library',
    contexts: ['build'] },

  // ===========================
  // TUTORIALS & COURSES
  // ===========================
  { id: 'bezier-primer', name: 'A Primer on B\u00e9zier Curves', url: 'https://pomax.github.io/bezierinfo/',
    category: 'tutorial', tags: ['bezier', 'curves', 'animation'],
    description: 'Free interactive guide to B\u00e9zier math',
    contexts: ['animate', 'playground', 'skills-waves'] },

  { id: 'mit-ocw-dynamics', name: 'MIT OCW: Dynamics', url: 'https://ocw.mit.edu/courses/2-003sc-engineering-dynamics-fall-2011/',
    category: 'tutorial', tags: ['dynamics', 'physics', 'course'],
    description: 'MIT OpenCourseWare \u2014 Engineering Dynamics',
    contexts: ['curriculum-foundations', 'dashboard'] },

  { id: 'cmu-mechanism', name: 'CMU Mechanism Course', url: 'http://www.cs.cmu.edu/~rapidproto/mechanisms/tableofcontents.html',
    category: 'tutorial', tags: ['mechanisms', 'course', 'academic'],
    description: 'Carnegie Mellon mechanism design reference',
    contexts: ['curriculum-foundations', 'curriculum-mechanisms'] },

  { id: 'fusion360-tutorials', name: 'Fusion 360 Tutorials', url: 'https://help.autodesk.com/view/fusion360/ENU/courses/',
    category: 'tutorial', tags: ['fusion360', 'cad', 'official'],
    description: 'Official Autodesk Fusion 360 learning path',
    contexts: ['curriculum-digital', 'skills-simulation'] },

  { id: 'fusion360-motion', name: 'Fusion 360 Motion Study', url: 'https://help.autodesk.com/view/fusion360/ENU/?guid=GUID-3E0B2AB0-5E67-4AC0-AA67-2B7E4AD0E2A4',
    category: 'tutorial', tags: ['fusion360', 'simulation', 'motion'],
    description: 'Fusion 360 motion study tutorial',
    contexts: ['simulate', 'skills-simulation', 'curriculum-digital'] },

  { id: 'fusion360-assembly', name: 'Fusion 360 Assemblies', url: 'https://help.autodesk.com/view/fusion360/ENU/?guid=GUID-80C56E87-3E0D-4E3E-B849-ACD97E6F3E71',
    category: 'tutorial', tags: ['fusion360', 'assembly', 'joints'],
    description: 'Fusion 360 joint & assembly design',
    contexts: ['curriculum-digital', 'build'] },

  { id: 'fusion360-export', name: 'Fusion 360 3D Print Export', url: 'https://help.autodesk.com/view/fusion360/ENU/?guid=GUID-FC12B4E3-6B1C-11E6-B292-BC764E10B201',
    category: 'tutorial', tags: ['fusion360', '3dprint', 'export'],
    description: 'Export designs for 3D printing from Fusion 360',
    contexts: ['build', 'curriculum-digital'] },

  { id: 'nyu-itp-linkage', name: 'NYU ITP Linkage Tutorial', url: 'https://itp.nyu.edu/physcomp/',
    category: 'tutorial', tags: ['linkage', 'physical-computing', 'academic'],
    description: 'NYU ITP physical computing & mechanism resources',
    contexts: ['mechanize', 'curriculum-mechanisms'] },

  { id: 'makewithtech-openscad', name: 'MakeWithTech OpenSCAD', url: 'https://makewithtech.com/category/openscad/',
    category: 'tutorial', tags: ['openscad', 'tutorial', 'beginner'],
    description: 'OpenSCAD tutorials for beginners',
    contexts: ['skills-openscad', 'curriculum-digital'] },

  { id: 'complexity-explorables', name: 'Complexity Explorables', url: 'https://www.complexity-explorables.org/',
    category: 'tutorial', tags: ['math', 'visualization', 'interactive'],
    description: 'Interactive explorations of complex systems',
    contexts: ['playground', 'dashboard', 'playground-tools'] },

  { id: 'observable', name: 'Observable', url: 'https://observablehq.com/',
    category: 'tutorial', tags: ['dataviz', 'javascript', 'interactive'],
    description: 'Interactive notebooks for data & math visualization',
    contexts: ['playground', 'exercises-waves', 'playground-tools'] },

  { id: 'fourier-explainer', name: 'Fourier Transform Visual', url: 'https://www.jezzamon.com/fourier/',
    category: 'tutorial', tags: ['fourier', 'interactive', 'math'],
    description: 'Interactive visual intro to Fourier transforms',
    contexts: ['playground-fourier', 'playground-patterns', 'playground-tools'] },

  { id: 'lissajous-wiki', name: 'Lissajous Curves', url: 'https://en.wikipedia.org/wiki/Lissajous_curve',
    category: 'tutorial', tags: ['parametric', 'lissajous', 'math'],
    description: 'Reference: Lissajous curve mathematics',
    contexts: ['playground-parametric', 'playground-patterns'] },

  { id: 'spirograph-math', name: 'Spirograph Mathematics', url: 'https://en.wikipedia.org/wiki/Spirograph#Mathematical_basis',
    category: 'tutorial', tags: ['parametric', 'spirograph', 'math'],
    description: 'Mathematical basis of spirograph patterns',
    contexts: ['playground-parametric', 'gallery-parametric', 'playground-patterns'] },

  // ===========================
  // COMMUNITY & FORUMS
  // ===========================
  { id: 'reddit-automata', name: 'r/automata', url: 'https://www.reddit.com/r/automata/',
    category: 'community', tags: ['automata', 'community', 'inspiration'],
    description: 'Reddit community for automata & mechanical art',
    contexts: ['iterate', 'dashboard', 'curriculum-resources'] },

  { id: 'reddit-kinetic', name: 'r/KineticArt', url: 'https://www.reddit.com/r/KineticArt/',
    category: 'community', tags: ['kinetic', 'community', 'inspiration'],
    description: 'Reddit community for kinetic sculpture',
    contexts: ['iterate', 'dashboard'] },

  { id: 'hackaday', name: 'Hackaday', url: 'https://hackaday.com/tag/kinetic/',
    category: 'community', tags: ['projects', 'community', 'electronics'],
    description: 'Kinetic projects on Hackaday',
    contexts: ['iterate', 'curriculum-resources'] },

  { id: 'instructables', name: 'Instructables: Automata', url: 'https://www.instructables.com/howto/automata/',
    category: 'community', tags: ['tutorials', 'build', 'diy'],
    description: 'DIY automata build guides',
    contexts: ['iterate', 'curriculum-handson'] },

  { id: 'printables', name: 'Printables', url: 'https://www.printables.com/search/models?q=kinetic',
    category: 'community', tags: ['3dprint', 'models', 'free'],
    description: 'Free 3D printable kinetic models',
    contexts: ['build'] },

  { id: 'cults3d', name: 'Cults3D', url: 'https://cults3d.com/en/search?q=automata',
    category: 'community', tags: ['3dprint', 'models', 'marketplace'],
    description: 'Automata 3D print files',
    contexts: ['build'] },

  // ===========================
  // VIDEO CHANNELS
  // ===========================
  { id: 'thang010146', name: 'Thang010146 (YouTube)', url: 'https://www.youtube.com/@thang010146',
    category: 'video', tags: ['mechanisms', 'animation', 'reference'],
    description: '2000+ mechanism animations \u2014 the essential catalog',
    contexts: ['dashboard', 'curriculum-resources', 'discover', 'playground-mechanisms', 'exercises-fourBar', 'exercises-cams'] },

  { id: 'tim-hunkin', name: 'Tim Hunkin', url: 'https://www.youtube.com/@timhunkin',
    category: 'video', tags: ['engineering', 'machines', 'inspiration'],
    description: 'Engineer & artist \u2014 The Secret Life of Machines',
    contexts: ['dashboard', 'curriculum-foundations'] },

  { id: 'wintergatan', name: 'Wintergatan', url: 'https://www.youtube.com/@Wintergatan',
    category: 'video', tags: ['marble-machine', 'music', 'kinetic'],
    description: 'Marble Machine X build series',
    contexts: ['curriculum-resources', 'iterate'] },

  { id: 'brick-experiment', name: 'Brick Experiment Channel', url: 'https://www.youtube.com/@BrickExperimentChannel',
    category: 'video', tags: ['lego', 'mechanisms', 'experiments'],
    description: 'Lego mechanism experiments & explorations',
    contexts: ['curriculum-resources'] },

  // ===========================
  // ARTIST WEBSITES
  // ===========================
  { id: 'margolin', name: 'Reuben Margolin', url: 'https://www.reubenmargolin.com/',
    category: 'artist', tags: ['waves', 'kinetic', 'sculpture'],
    description: 'Master kinetic sculptor \u2014 wave-based art',
    contexts: ['iterate', 'curriculum-history', 'playground-wavelab', 'playground-3d', 'playground-tools'] },

  { id: 'howe', name: 'David C. Roy', url: 'https://www.woodthatworks.com/',
    category: 'artist', tags: ['wood', 'kinetic', 'wind'],
    description: 'Kinetic wood sculptures \u2014 spring & wind powered',
    contexts: ['iterate', 'curriculum-history', 'playground-tools'] },

  { id: 'jansen', name: 'Theo Jansen', url: 'https://www.strandbeest.com/',
    category: 'artist', tags: ['walking', 'wind', 'linkage'],
    description: 'Strandbeest wind-walking kinetic creatures',
    contexts: ['iterate', 'curriculum-history', 'exercises-walking', 'playground-tools'] },

  { id: 'arthur-ganson', name: 'Arthur Ganson', url: 'https://arthurganson.com/',
    category: 'artist', tags: ['kinetic', 'whimsy', 'sculpture'],
    description: 'Kinetic sculptor \u2014 MIT Museum collection',
    contexts: ['iterate', 'curriculum-history', 'playground-tools'] },

  // ===========================
  // FREE DOWNLOADS & PLANS
  // ===========================
  { id: 'exploratorium-pdf', name: 'Exploratorium: Cardboard Automata', url: 'https://www.exploratorium.edu/sites/default/files/pdfs/CardboardAutomata.pdf',
    category: 'plans', tags: ['cardboard', 'automata', 'free', 'pdf'],
    description: 'Free PDF: build cardboard automata with simple cams',
    contexts: ['dashboard', 'curriculum-handson'] },

  // ===========================
  // BOOKS
  // ===========================
  { id: 'book-making-things-move', name: 'Making Things Move (D. Roberts)', url: 'https://www.amazon.com/Making-Things-Move-Mechanisms-Inventors/dp/0071741674',
    category: 'book', tags: ['mechanisms', 'beginner', 'essential'],
    description: 'Essential book: mechanisms for inventors & hobbyists',
    contexts: ['curriculum-foundations', 'curriculum-mechanisms'] },

  { id: 'book-cabaret-mechanical', name: 'Cabaret Mechanical Movement', url: 'https://www.amazon.com/Cabaret-Mechanical-Movement-Understanding-Movement/dp/0952872919',
    category: 'book', tags: ['automata', 'mechanisms', 'reference'],
    description: 'Mechanisms explained through automata art',
    contexts: ['curriculum-mechanisms'] },

  { id: 'book-making-automata', name: 'Making Automata in Wood', url: 'https://www.amazon.com/Making-Simple-Automata-Robert-Race/dp/1861088388',
    category: 'book', tags: ['automata', 'wood', 'build'],
    description: 'Practical guide to wooden automata construction',
    contexts: ['curriculum-handson'] },

  // ===========================
  // P5.JS & CREATIVE CODING
  // ===========================
  { id: 'p5js-examples', name: 'p5.js Examples', url: 'https://p5js.org/examples/',
    category: 'tutorial', tags: ['p5js', 'animation', 'creative-coding'],
    description: 'p5.js example sketches for creative coding',
    contexts: ['animate', 'playground-tools'] },

  { id: 'p5js-reference', name: 'p5.js Reference', url: 'https://p5js.org/reference/',
    category: 'tutorial', tags: ['p5js', 'reference', 'creative-coding'],
    description: 'p5.js API reference',
    contexts: ['animate', 'playground-tools'] },

  { id: 'p5js-editor', name: 'p5.js Web Editor', url: 'https://editor.p5js.org/',
    category: 'tool', tags: ['p5js', 'creative-coding', 'animation', 'interactive', 'sandbox'],
    description: 'Free online code editor for p5.js — write, run, and share creative coding sketches instantly',
    contexts: ['animate', 'playground-tools', 'playground-wavelab', 'playground-patterns',
               'playground-3d', 'exercises', 'dashboard', 'skills-simulation', 'skills-designThinking'] },

  { id: 'p5js-learn', name: 'p5.js Learn', url: 'https://p5js.org/learn/',
    category: 'tutorial', tags: ['p5js', 'creative-coding', 'tutorial'],
    description: 'Official p5.js tutorials — from basics to advanced creative coding',
    contexts: ['dashboard', 'playground-tools', 'curriculum-digital'] },

  { id: 'coding-train-p5', name: 'Coding Train (p5.js)', url: 'https://www.youtube.com/@TheCodingTrain',
    category: 'video', tags: ['p5js', 'creative-coding', 'tutorial', 'video'],
    description: 'Daniel Shiffman — the best p5.js video tutorials for creative coding and math visualization',
    contexts: ['dashboard', 'curriculum-digital', 'playground-tools'] },

  // ===========================
  // MATH VISUALIZATION
  // ===========================
  { id: 'parametric-curves', name: 'Parametric Curve Guide', url: 'https://en.wikipedia.org/wiki/List_of_curves',
    category: 'tutorial', tags: ['parametric', 'curves', 'reference'],
    description: 'Encyclopedia of mathematical curves',
    contexts: ['gallery-parametric', 'playground-parametric', 'playground-patterns'] },

  { id: 'fourier-series-wiki', name: 'Fourier Series', url: 'https://en.wikipedia.org/wiki/Fourier_series',
    category: 'tutorial', tags: ['fourier', 'math', 'reference'],
    description: 'Fourier series mathematics reference',
    contexts: ['gallery-fourier', 'playground-patterns'] },

  { id: 'math-visualizations', name: 'Math \u2192 Visual', url: 'https://mathvisual.wordpress.com/',
    category: 'tutorial', tags: ['math', 'visualization', 'interactive'],
    description: 'Beautiful mathematical visualizations',
    contexts: ['gallery-graph', 'playground', 'playground-tools'] },

  // ===========================
  // NEW: Wave & 3D Visualization
  // ===========================
  { id: 'grafar', name: 'Grafar', url: 'https://thoughtspile.github.io/grafar/#/',
    category: 'tool', tags: ['3d', 'waves', 'visualization'],
    description: 'Real-time 3D mathematical visualization in the browser',
    contexts: ['playground-3d', 'playground-wavelab', 'playground-tools'] },

  { id: 'cindyjs', name: 'CindyJS', url: 'https://cindyjs.org/',
    category: 'tool', tags: ['geometry', 'interactive', 'creative-coding'],
    description: 'Interactive geometry & creative coding framework',
    contexts: ['playground-tools'] },
];

// ===========================
// QUERY FUNCTIONS
// ===========================

/**
 * Get resources that match a specific context string.
 * Context can be: 'discover', 'animate', 'mechanize', 'simulate', 'build', 'iterate',
 * 'dashboard', 'playground', 'playground-graph', 'playground-fourier', 'playground-parametric',
 * 'playground-linkage', 'playground-wavelab', 'playground-patterns', 'playground-mechanisms',
 * 'playground-3d', 'playground-tools',
 * 'gallery-parametric', 'gallery-fourier', 'gallery-graph',
 * 'exercises', 'exercises-fourBar', 'exercises-waves', 'exercises-cams', 'exercises-walking',
 * 'exercises-gears', 'exercises-simulation', 'exercises-eccentric', 'exercises-design',
 * 'skills-fourBar', 'skills-cams', 'skills-gears', 'skills-eccentric',
 * 'skills-simulation', 'skills-designThinking',
 * 'curriculum-foundations', 'curriculum-handson', 'curriculum-digital', 'curriculum-mechanisms',
 * 'curriculum-resources', 'curriculum-history'
 */
export function getResourcesForContext(context) {
  return RESOURCES.filter(r => r.contexts.includes(context));
}

/**
 * Get resources by category: 'tool', 'repo', 'tutorial', 'community', 'book', 'plans', 'artist', 'video'
 */
export function getResourcesByCategory(category) {
  return RESOURCES.filter(r => r.category === category);
}

/**
 * Get resources by tag (e.g. 'fourBar', 'openscad', 'waves')
 */
export function getResourcesByTag(tag) {
  return RESOURCES.filter(r => r.tags.includes(tag));
}

/**
 * Get all resources (for search/filtering)
 */
export function getAllResources() {
  return [...RESOURCES];
}
