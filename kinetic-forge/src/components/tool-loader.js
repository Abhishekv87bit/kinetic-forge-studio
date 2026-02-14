// Dynamic CDN library loader — loads JS from CDN on demand, caches loaded scripts

const loaded = new Set();
const loading = new Map();

const CDN_URLS = {
  'three': 'https://cdn.jsdelivr.net/npm/three@0.137.5/build/three.min.js',
  'jsxgraph': 'https://cdn.jsdelivr.net/npm/jsxgraph@1.9.2/distrib/jsxgraphcore.js',
  'jsxgraph-css': 'https://cdn.jsdelivr.net/npm/jsxgraph@1.9.2/distrib/jsxgraph.css',
  'p5': 'https://cdn.jsdelivr.net/npm/p5@1.9.4/lib/p5.min.js',
  'bezier': 'https://cdn.jsdelivr.net/npm/bezier-js@6.1.4/src/bezier.js',
  'cindyjs': 'https://cindyjs.org/dist/v0.9/Cindy.js',
  'marked': 'https://cdn.jsdelivr.net/npm/marked@12.0.0/marked.min.js',
  // Grafar and MathBox loaded as ES modules when needed
};

function loadScript(url) {
  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = url;
    script.onload = resolve;
    script.onerror = () => reject(new Error(`Failed to load: ${url}`));
    document.head.appendChild(script);
  });
}

function loadCSS(url) {
  return new Promise((resolve) => {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = url;
    link.onload = resolve;
    document.head.appendChild(link);
  });
}

export async function loadLibrary(name) {
  if (loaded.has(name)) return;

  // If already loading, wait for it
  if (loading.has(name)) {
    return loading.get(name);
  }

  const url = CDN_URLS[name];
  if (!url) {
    console.warn(`Unknown library: ${name}`);
    return;
  }

  let promise;
  if (url.endsWith('.css')) {
    promise = loadCSS(url);
  } else {
    promise = loadScript(url);
  }

  loading.set(name, promise);

  try {
    await promise;
    loaded.add(name);
  } finally {
    loading.delete(name);
  }
}

export async function loadLibraries(names) {
  // Load CSS first, then JS in parallel
  const cssNames = names.filter(n => CDN_URLS[n]?.endsWith('.css'));
  const jsNames = names.filter(n => !CDN_URLS[n]?.endsWith('.css'));

  await Promise.all(cssNames.map(n => loadLibrary(n)));
  await Promise.all(jsNames.map(n => loadLibrary(n)));
}

export function isLoaded(name) {
  return loaded.has(name);
}
