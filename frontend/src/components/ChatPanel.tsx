/**
 * SC-04 ChatPanel — conversational interface for generating KFS modules.
 *
 * Features:
 *   - Chat message history (user / assistant turns)
 *   - Text input + Send button
 *   - "Save as Module" button: appears on assistant messages that contain
 *     CadQuery code (detected by a ```python fence), and saves the code
 *     block to the backend as a named module via moduleStore.saveAsModule().
 *
 * The panel reads projectId from projectStore and writes the new module
 * into both moduleStore (for the editor panel) and projectStore (for the
 * sidebar list).
 */
import React, { useCallback, useEffect, useRef, useState } from 'react';

import { useModuleStore } from '../stores/moduleStore';
import { useProjectStore } from '../stores/projectStore';
import { useViewportStore } from '../stores/viewportStore';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type MessageRole = 'user' | 'assistant';

export interface ChatMessage {
  id: string;
  role: MessageRole;
  content: string;
  timestamp: number;
}

interface ChatPanelProps {
  style?: React.CSSProperties;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Extract the first ```python ... ``` code block from markdown text. */
function extractCodeBlock(text: string): string | null {
  const match = text.match(/```python\s*\n([\s\S]*?)```/);
  return match ? match[1].trim() : null;
}

/** Generate a stable string ID without crypto. */
function uid(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
}

// ---------------------------------------------------------------------------
// Save-as-Module modal (inline, minimal)
// ---------------------------------------------------------------------------

interface SaveModalProps {
  code: string;
  onSave: (name: string) => Promise<void>;
  onCancel: () => void;
}

function SaveModal({ code, onSave, onCancel }: SaveModalProps) {
  const [name, setName] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Module name is required.');
      return;
    }
    setSaving(true);
    try {
      await onSave(name.trim());
    } catch (err) {
      setError((err as Error).message);
      setSaving(false);
    }
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.6)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 999,
      }}
      onClick={onCancel}
    >
      <form
        onSubmit={handleSubmit}
        onClick={(e) => e.stopPropagation()}
        style={{
          background: '#1e1e1e',
          border: '1px solid #333',
          borderRadius: 8,
          padding: '20px 24px',
          minWidth: 320,
          display: 'flex',
          flexDirection: 'column',
          gap: 12,
          fontFamily: 'monospace',
        }}
      >
        <div style={{ fontSize: 14, fontWeight: 700, color: '#e2e8f0' }}>
          Save as Module
        </div>

        <input
          ref={inputRef}
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Module name (e.g. spur_gear_m2)"
          style={{
            padding: '6px 10px',
            background: '#111',
            border: '1px solid #444',
            borderRadius: 4,
            color: '#e2e8f0',
            fontSize: 13,
            fontFamily: 'monospace',
            outline: 'none',
          }}
        />

        {error && (
          <div style={{ fontSize: 11, color: '#ef4444' }}>{error}</div>
        )}

        <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
          <button
            type="button"
            onClick={onCancel}
            style={{
              padding: '5px 14px',
              background: '#27272a',
              border: 'none',
              borderRadius: 4,
              color: '#aaa',
              cursor: 'pointer',
              fontSize: 12,
              fontFamily: 'monospace',
            }}
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={saving}
            style={{
              padding: '5px 14px',
              background: saving ? '#1d4ed8' : '#2563eb',
              border: 'none',
              borderRadius: 4,
              color: '#fff',
              cursor: saving ? 'not-allowed' : 'pointer',
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: 700,
            }}
          >
            {saving ? 'Saving…' : 'Save'}
          </button>
        </div>
      </form>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Single message bubble
// ---------------------------------------------------------------------------

interface MessageBubbleProps {
  message: ChatMessage;
  onSaveAsModule: (code: string) => void;
}

function MessageBubble({ message, onSaveAsModule }: MessageBubbleProps) {
  const isUser = message.role === 'user';
  const code = !isUser ? extractCodeBlock(message.content) : null;

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: isUser ? 'flex-end' : 'flex-start',
        marginBottom: 12,
        gap: 4,
      }}
    >
      {/* Role label */}
      <span
        style={{
          fontSize: 10,
          color: '#666',
          fontFamily: 'monospace',
          marginBottom: 2,
        }}
      >
        {isUser ? 'You' : 'KFS Agent'}
      </span>

      {/* Content bubble */}
      <div
        style={{
          maxWidth: '85%',
          padding: '8px 12px',
          borderRadius: isUser ? '12px 12px 2px 12px' : '2px 12px 12px 12px',
          background: isUser ? '#1d4ed8' : '#1e1e1e',
          border: isUser ? 'none' : '1px solid #2a2a2a',
          color: '#e2e8f0',
          fontSize: 13,
          fontFamily: isUser ? 'system-ui, sans-serif' : 'monospace',
          lineHeight: 1.5,
          whiteSpace: 'pre-wrap',
          wordBreak: 'break-word',
        }}
      >
        {message.content}
      </div>

      {/* Save as Module button — shown only for assistant messages with code */}
      {code && (
        <button
          onClick={() => onSaveAsModule(code)}
          style={{
            padding: '3px 10px',
            background: 'transparent',
            border: '1px solid #3b82f6',
            borderRadius: 4,
            color: '#60a5fa',
            cursor: 'pointer',
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: 600,
            transition: 'background 0.1s',
          }}
          onMouseEnter={(e) => {
            (e.currentTarget as HTMLButtonElement).style.background = 'rgba(59,130,246,0.15)';
          }}
          onMouseLeave={(e) => {
            (e.currentTarget as HTMLButtonElement).style.background = 'transparent';
          }}
        >
          ✦ Save as Module
        </button>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// ChatPanel
// ---------------------------------------------------------------------------

export function ChatPanel({ style }: ChatPanelProps) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [pendingCode, setPendingCode] = useState<string | null>(null);

  const messagesEndRef = useRef<HTMLDivElement>(null);

  const { saveAsModule, setActiveModuleId } = useModuleStore();
  const { projectId } = useProjectStore();
  const { setActiveModuleId: setViewportModule } = useViewportStore();

  // Auto-scroll on new messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // -------------------------------------------------------------------------
  // Send message to chat agent
  // -------------------------------------------------------------------------

  const handleSend = useCallback(async () => {
    const text = input.trim();
    if (!text || isSending) return;

    const userMsg: ChatMessage = {
      id: uid(),
      role: 'user',
      content: text,
      timestamp: Date.now(),
    };
    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setIsSending(true);

    try {
      const res = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: text,
          history: messages.slice(-20).map((m) => ({ role: m.role, content: m.content })),
          projectId,
        }),
      });

      if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
      const data: { reply: string } = await res.json();

      const assistantMsg: ChatMessage = {
        id: uid(),
        role: 'assistant',
        content: data.reply,
        timestamp: Date.now(),
      };
      setMessages((prev) => [...prev, assistantMsg]);
    } catch (err) {
      setMessages((prev) => [
        ...prev,
        {
          id: uid(),
          role: 'assistant',
          content: `⚠ Error: ${(err as Error).message}`,
          timestamp: Date.now(),
        },
      ]);
    } finally {
      setIsSending(false);
    }
  }, [input, isSending, messages, projectId]);

  // -------------------------------------------------------------------------
  // Save as Module flow
  // -------------------------------------------------------------------------

  const handleSaveAsModule = useCallback((code: string) => {
    setPendingCode(code);
  }, []);

  const handleConfirmSave = useCallback(
    async (name: string) => {
      if (!pendingCode || !projectId) {
        throw new Error('No project or code to save.');
      }
      const created = await saveAsModule({ name, code: pendingCode, projectId });
      setActiveModuleId(created.id);
      setViewportModule(created.id);
      setPendingCode(null);
    },
    [pendingCode, projectId, saveAsModule, setActiveModuleId, setViewportModule],
  );

  // -------------------------------------------------------------------------
  // Keyboard: Enter to send, Shift+Enter for newline
  // -------------------------------------------------------------------------

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSend();
      }
    },
    [handleSend],
  );

  // -------------------------------------------------------------------------
  // Render
  // -------------------------------------------------------------------------

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        background: '#0f0f0f',
        ...style,
      }}
    >
      {/* Save-as-Module modal */}
      {pendingCode && (
        <SaveModal
          code={pendingCode}
          onSave={handleConfirmSave}
          onCancel={() => setPendingCode(null)}
        />
      )}

      {/* ── Message history ── */}
      <div
        style={{
          flex: 1,
          overflowY: 'auto',
          padding: '16px 12px',
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        {messages.length === 0 ? (
          <div
            style={{
              flex: 1,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#444',
              fontSize: 13,
              fontFamily: 'monospace',
            }}
          >
            Describe a kinetic sculpture component to generate CadQuery code.
          </div>
        ) : (
          messages.map((m) => (
            <MessageBubble
              key={m.id}
              message={m}
              onSaveAsModule={handleSaveAsModule}
            />
          ))
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* ── Input area ── */}
      <div
        style={{
          borderTop: '1px solid #2a2a2a',
          padding: '8px 12px',
          display: 'flex',
          gap: 8,
          alignItems: 'flex-end',
          background: '#161616',
          flexShrink: 0,
        }}
      >
        <textarea
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Generate a spur gear… (Enter to send, Shift+Enter for newline)"
          disabled={isSending}
          rows={2}
          style={{
            flex: 1,
            padding: '7px 10px',
            background: '#111',
            border: '1px solid #333',
            borderRadius: 6,
            color: '#e2e8f0',
            fontSize: 13,
            fontFamily: 'monospace',
            resize: 'none',
            outline: 'none',
            lineHeight: 1.5,
          }}
        />
        <button
          onClick={handleSend}
          disabled={isSending || !input.trim()}
          style={{
            padding: '8px 16px',
            background: isSending || !input.trim() ? '#1c1c1c' : '#2563eb',
            border: 'none',
            borderRadius: 6,
            color: isSending || !input.trim() ? '#555' : '#fff',
            cursor: isSending || !input.trim() ? 'not-allowed' : 'pointer',
            fontSize: 13,
            fontFamily: 'monospace',
            fontWeight: 700,
            alignSelf: 'flex-end',
            height: 36,
          }}
        >
          {isSending ? '…' : 'Send'}
        </button>
      </div>
    </div>
  );
}

export default ChatPanel;
