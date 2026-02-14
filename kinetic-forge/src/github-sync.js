// GitHub sync client — frontend side

import { showToast } from './toast.js';

export async function getGitStatus() {
  try {
    const res = await fetch('/api/github/status');
    return res.json();
  } catch {
    return { error: 'Cannot reach server' };
  }
}

export async function syncToGitHub(message = null) {
  try {
    const res = await fetch('/api/github/sync', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message })
    });
    const data = await res.json();
    if (data.ok) {
      showToast('Synced to GitHub', 'success');
    } else {
      showToast(`Sync failed: ${data.error}`, 'error');
    }
    return data;
  } catch (err) {
    showToast(`Sync error: ${err.message}`, 'error');
    return { error: err.message };
  }
}

export async function pullFromGitHub() {
  try {
    const res = await fetch('/api/github/pull', { method: 'POST' });
    const data = await res.json();
    if (data.ok) {
      showToast('Pulled latest from GitHub', 'success');
    } else {
      showToast(`Pull failed: ${data.error}`, 'error');
    }
    return data;
  } catch (err) {
    showToast(`Pull error: ${err.message}`, 'error');
    return { error: err.message };
  }
}
