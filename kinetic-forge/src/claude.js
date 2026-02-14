// Claude API client — frontend side

import { getProfile, getProject } from './state.js';
import { getMode } from './components/mode-toggle.js';

export async function sendMessage(userMessage, stageContext = null) {
  const profile = getProfile();
  const project = getProject();
  const mode = getMode();

  // Build context-aware system prompt
  let systemPrompt = 'You are a kinetic sculpture design assistant embedded in KineticForge.\n';
  systemPrompt += `Mode: ${mode}.\n`;

  if (mode === 'build' && stageContext) {
    systemPrompt += `Current stage: ${stageContext}.\n`;
    if (project) {
      systemPrompt += `Project: ${project.name}.\n`;
      systemPrompt += `Project state: ${JSON.stringify(project.stages[stageContext] || {})}\n`;
    }
  }

  if (profile) {
    systemPrompt += `User skills: ${JSON.stringify(profile.journey.skillLevels)}.\n`;
    systemPrompt += `XP: ${profile.xp.total}.\n`;
  }

  systemPrompt += '\nKeep responses concise. Use bullet points. Include numbers and formulas when relevant.';
  systemPrompt += '\nIf a mechanism violates physics, explain why and suggest an alternative.';
  systemPrompt += '\nIf suggesting a four-bar, provide the ratio (G:C:Co:R).';

  try {
    const res = await fetch('/api/claude/message', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemPrompt,
        messages: [{ role: 'user', content: userMessage }]
      })
    });

    if (!res.ok) {
      const err = await res.json();
      return { error: err.error || 'Claude API error' };
    }

    const data = await res.json();
    const text = data.content?.[0]?.text || 'No response';
    return { text };
  } catch (err) {
    return { error: err.message };
  }
}

export async function getSuggestions(stage = null) {
  const profile = getProfile();

  try {
    const res = await fetch('/api/claude/suggest', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        mode: getMode(),
        stage,
        skillLevels: profile?.journey?.skillLevels,
        taskHistory: [],
        projectState: getProject()
      })
    });

    if (!res.ok) return [];

    const data = await res.json();
    const text = data.content?.[0]?.text || '[]';

    // Try to parse JSON from Claude's response
    try {
      const jsonMatch = text.match(/\[[\s\S]*\]/);
      if (jsonMatch) return JSON.parse(jsonMatch[0]);
    } catch { /* fallback */ }

    return [];
  } catch {
    return [];
  }
}
