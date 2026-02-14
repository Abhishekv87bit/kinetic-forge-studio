// Claude chat/suggestion panel — lives in sidebar

import { sendMessage } from '../claude.js';
import { checkApiKey } from '../state.js';

export function createClaudePanel(stageContext = null) {
  const panel = document.createElement('div');
  panel.className = 'claude-panel';

  const title = document.createElement('div');
  title.className = 'section-title';
  title.textContent = 'Ask Claude';
  panel.appendChild(title);

  const messages = document.createElement('div');
  messages.className = 'claude-messages';
  panel.appendChild(messages);

  const inputRow = document.createElement('div');
  inputRow.className = 'claude-input';

  const input = document.createElement('input');
  input.type = 'text';
  input.placeholder = 'Ask about mechanisms, math, design...';

  const sendBtn = document.createElement('button');
  sendBtn.textContent = 'Ask';

  inputRow.appendChild(input);
  inputRow.appendChild(sendBtn);
  panel.appendChild(inputRow);

  async function handleSend() {
    const text = input.value.trim();
    if (!text) return;

    const hasKey = await checkApiKey();
    if (!hasKey) {
      addMsg('Configure your Claude API key in settings first.', 'assistant');
      return;
    }

    addMsg(text, 'user');
    input.value = '';
    sendBtn.disabled = true;
    sendBtn.textContent = '...';

    const result = await sendMessage(text, stageContext);
    sendBtn.disabled = false;
    sendBtn.textContent = 'Ask';

    if (result.error) {
      addMsg(`Error: ${result.error}`, 'assistant');
    } else {
      addMsg(result.text, 'assistant');
    }
  }

  function addMsg(text, role) {
    const msg = document.createElement('div');
    msg.className = `claude-msg ${role}`;
    msg.textContent = text;
    messages.appendChild(msg);
    messages.scrollTop = messages.scrollHeight;
  }

  sendBtn.onclick = handleSend;
  input.onkeydown = (e) => { if (e.key === 'Enter') handleSend(); };

  return panel;
}
