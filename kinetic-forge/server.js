import express from 'express';
import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from 'fs';
import { join, resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import simpleGit from 'simple-git';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = resolve(__dirname, '..');
const DATA_DIR = join(__dirname, 'data');
const PROJECTS_DIR = join(DATA_DIR, 'projects');
const KNOWLEDGE_DIRS = [
  join(ROOT, '3d_design_agent', 'archives', 'docs'),
  join(ROOT, '3d_design_agent', 'learning'),
  join(ROOT, 'User Skills')
];

// Ensure data dirs exist
[DATA_DIR, PROJECTS_DIR].forEach(d => {
  if (!existsSync(d)) mkdirSync(d, { recursive: true });
});

const app = express();
app.use(express.json({ limit: '5mb' }));

// --- API Key ---
function getApiKey() {
  // 1. Environment variable
  if (process.env.ANTHROPIC_API_KEY) return process.env.ANTHROPIC_API_KEY;
  // 2. Local file
  const keyFile = join(DATA_DIR, 'api-key.txt');
  if (existsSync(keyFile)) return readFileSync(keyFile, 'utf-8').trim();
  return null;
}

// --- State Endpoints ---

// User profile
app.get('/api/state/profile', (req, res) => {
  const file = join(DATA_DIR, 'user-profile.json');
  if (!existsSync(file)) {
    const defaultProfile = {
      version: 1,
      created: new Date().toISOString(),
      lastActive: new Date().toISOString(),
      mode: 'learn',
      xp: { total: 0, byStage: { discover: 0, animate: 0, mechanize: 0, simulate: 0, build: 0, iterate: 0 } },
      streak: { currentDays: 0, longestDays: 0, lastActiveDate: null },
      journey: {
        stagesCompleted: [],
        totalProjectsStarted: 0,
        totalProjectsCompleted: 0,
        totalTasksCompleted: 0,
        skillLevels: { fourBar: 0, cams: 0, gears: 0, eccentric: 0, simulation: 0, designThinking: 0 }
      },
      preferences: { tooltipsEnabled: true, claudeSuggestionsEnabled: true, autoSyncToGitHub: false }
    };
    writeFileSync(file, JSON.stringify(defaultProfile, null, 2));
    return res.json(defaultProfile);
  }
  res.json(JSON.parse(readFileSync(file, 'utf-8')));
});

app.post('/api/state/profile', (req, res) => {
  const file = join(DATA_DIR, 'user-profile.json');
  writeFileSync(file, JSON.stringify(req.body, null, 2));
  res.json({ ok: true });
});

// Projects
app.get('/api/state/projects', (req, res) => {
  if (!existsSync(PROJECTS_DIR)) return res.json([]);
  const files = readdirSync(PROJECTS_DIR).filter(f => f.endsWith('.json'));
  const projects = files.map(f => {
    const data = JSON.parse(readFileSync(join(PROJECTS_DIR, f), 'utf-8'));
    return { id: data.id, name: data.name, currentStage: data.currentStage, updated: data.updated };
  });
  res.json(projects);
});

app.get('/api/state/project/:id', (req, res) => {
  const file = join(PROJECTS_DIR, `${req.params.id}.json`);
  if (!existsSync(file)) return res.status(404).json({ error: 'Project not found' });
  res.json(JSON.parse(readFileSync(file, 'utf-8')));
});

app.post('/api/state/project/:id', (req, res) => {
  const file = join(PROJECTS_DIR, `${req.params.id}.json`);
  req.body.updated = new Date().toISOString();
  writeFileSync(file, JSON.stringify(req.body, null, 2));
  res.json({ ok: true });
});

// Task history
app.get('/api/state/tasks', (req, res) => {
  const file = join(DATA_DIR, 'task-history.json');
  if (!existsSync(file)) {
    const empty = { version: 1, tasks: [], taskTypeCounts: {} };
    writeFileSync(file, JSON.stringify(empty, null, 2));
    return res.json(empty);
  }
  res.json(JSON.parse(readFileSync(file, 'utf-8')));
});

app.post('/api/state/tasks', (req, res) => {
  const file = join(DATA_DIR, 'task-history.json');
  writeFileSync(file, JSON.stringify(req.body, null, 2));
  res.json({ ok: true });
});

// --- Patterns (Experiment module) ---
app.get('/api/state/patterns', (req, res) => {
  const file = join(DATA_DIR, 'patterns.json');
  if (!existsSync(file)) {
    const empty = { version: 1, patterns: [] };
    writeFileSync(file, JSON.stringify(empty, null, 2));
    return res.json(empty);
  }
  res.json(JSON.parse(readFileSync(file, 'utf-8')));
});

app.post('/api/state/patterns', (req, res) => {
  const file = join(DATA_DIR, 'patterns.json');
  writeFileSync(file, JSON.stringify(req.body, null, 2));
  res.json({ ok: true });
});

// --- API Key management ---
app.get('/api/state/apikey', (req, res) => {
  const key = getApiKey();
  res.json({ configured: !!key });
});

app.post('/api/state/apikey', (req, res) => {
  const { key } = req.body;
  if (!key) return res.status(400).json({ error: 'No key provided' });
  writeFileSync(join(DATA_DIR, 'api-key.txt'), key.trim());
  res.json({ ok: true });
});

// --- Knowledge Bank Endpoints ---

// Index: list available knowledge files
app.get('/api/knowledge/index', (req, res) => {
  const files = [];
  for (const dir of KNOWLEDGE_DIRS) {
    if (!existsSync(dir)) continue;
    for (const f of readdirSync(dir)) {
      if (f.endsWith('.md')) {
        const fullPath = join(dir, f);
        const stat = readFileSync(fullPath).length;
        files.push({ name: f, path: fullPath, sizeKB: Math.round(stat / 1024) });
      }
    }
  }
  res.json(files);
});

// Read specific knowledge file
app.get('/api/knowledge/:file', (req, res) => {
  const filename = req.params.file;
  for (const dir of KNOWLEDGE_DIRS) {
    const fullPath = join(dir, filename);
    if (existsSync(fullPath)) {
      return res.type('text/plain').send(readFileSync(fullPath, 'utf-8'));
    }
  }
  res.status(404).json({ error: 'File not found' });
});

// --- Claude API Proxy ---

app.post('/api/claude/message', async (req, res) => {
  const apiKey = getApiKey();
  if (!apiKey) return res.status(401).json({ error: 'API key not configured' });

  const { messages, systemPrompt } = req.body;

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        system: systemPrompt || 'You are a kinetic sculpture design assistant.',
        messages: messages || []
      })
    });

    if (!response.ok) {
      const err = await response.text();
      return res.status(response.status).json({ error: err });
    }

    const data = await response.json();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/claude/suggest', async (req, res) => {
  const apiKey = getApiKey();
  if (!apiKey) return res.status(401).json({ error: 'API key not configured' });

  const { mode, stage, skillLevels, taskHistory, projectState } = req.body;

  const systemPrompt = `You are a kinetic sculpture learning assistant embedded in KineticForge.
Mode: ${mode || 'learn'}. ${stage ? `Current stage: ${stage}.` : ''}
User skill levels: ${JSON.stringify(skillLevels || {})}.
Recent tasks completed: ${(taskHistory || []).slice(-5).map(t => t.type).join(', ') || 'none'}.
Suggest 2-3 next exercises or actions. Be specific with parameters. Keep each suggestion under 30 words.
Return JSON array: [{"title": "...", "description": "...", "type": "...", "params": {...}}]`;

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 512,
        system: systemPrompt,
        messages: [{ role: 'user', content: 'What should I work on next?' }]
      })
    });

    if (!response.ok) {
      const err = await response.text();
      return res.status(response.status).json({ error: err });
    }

    const data = await response.json();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- GitHub Sync ---

const git = simpleGit(ROOT);

app.get('/api/github/status', async (req, res) => {
  try {
    const status = await git.status();
    res.json({
      clean: status.isClean(),
      modified: status.modified.length,
      staged: status.staged.length,
      untracked: status.not_added.length
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/github/sync', async (req, res) => {
  try {
    const message = req.body.message || `KineticForge: sync ${new Date().toISOString()}`;
    await git.add('kinetic-forge/data/*.json');
    await git.commit(message);
    await git.push();
    res.json({ ok: true, message });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/github/pull', async (req, res) => {
  try {
    const result = await git.pull();
    res.json({ ok: true, summary: result.summary });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- OpenSCAD Syntax Check (optional) ---
app.post('/api/openscad/check', async (req, res) => {
  // Placeholder — will check if openscad CLI is available
  res.json({ available: false, message: 'OpenSCAD CLI check not yet implemented' });
});

// --- Start Server ---
const PORT = 3001;
app.listen(PORT, () => {
  console.log(`KineticForge API server running on http://localhost:${PORT}`);
  console.log(`API key configured: ${!!getApiKey()}`);
  console.log(`Data directory: ${DATA_DIR}`);
  console.log(`Knowledge dirs: ${KNOWLEDGE_DIRS.join(', ')}`);
});
