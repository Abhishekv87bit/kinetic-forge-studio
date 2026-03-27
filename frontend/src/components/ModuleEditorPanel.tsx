/**
 * SC-04 ModuleEditorPanel — code editor panel for the active KFS module.
 *
 * Features:
 *   - Monaco-based CadQuery code editor (syntax: Python)
 *   - Execute button  → POST /api/modules/{id}/execute → bumps geometryVersion
 *   - Validate button → POST /api/modules/{id}/validate → shows VLAD results
 *   - Save button     → PATCH /api/modules/{id} (persists code edits)
 *   - VLAD results accordion: list of check rows coloured by PASS/FAIL/WARN
 *
 * The panel reads/writes to moduleStore and also calls bumpGeometryVersion()
 * on viewportStore after a successful execution so Viewport3D refetches GLB.
 */
import React, { useCallback, useEffect, useRef, useState } from 'react';
import Editor, { OnMount } from '@monaco-editor/react';
import type * as Monaco from 'monaco-editor';

import { useModuleStore, type VladCheck } from '../stores/moduleStore';
import { useViewportStore } from '../stores/viewportStore';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ModuleEditorPanelProps {
  style?: React.CSSProperties;
}

// ---------------------------------------------------------------------------
// VLAD results display
// ---------------------------------------------------------------------------

const CHECK_STATUS_COLOURS: Record<string, string> = {
  PASS: '#22c55e',
  FAIL: '#ef4444',
  WARN: '#f59e0b',
  INFO: '#60a5fa',
};

function VladCheckRow({ check }: { check: VladCheck }) {
  return (
    <div
      style={{
        display: 'flex',
        gap: 8,
        padding: '3px 0',
        fontSize: 11,
        fontFamily: 'monospace',
        alignItems: 'flex-start',
      }}
    >
      <span
        style={{
          color: CHECK_STATUS_COLOURS[check.status] ?? '#aaa',
          minWidth: 38,
          fontWeight: 700,
        }}
      >
        {check.status}
      </span>
      <span style={{ color: '#bbb', flex: 1 }}>{check.id}</span>
      {check.detail && <span style={{ color: '#888', flex: 2 }}>{check.detail}</span>}
    </div>
  );
}

function VladPanel({ moduleId }: { moduleId: string }) {
  const module = useModuleStore((s) => s.modules.find((m) => m.id === moduleId));
  const summary = module?.vladSummary;

  if (!summary) return null;

  const verdictColour = summary.verdict === 'PASS' ? '#22c55e' : '#ef4444';

  return (
    <div
      style={{
        borderTop: '1px solid #2a2a2a',
        padding: '8px 12px',
        maxHeight: 180,
        overflowY: 'auto',
        background: '#0f0f0f',
      }}
    >
      {/* Summary header */}
      <div
        style={{
          display: 'flex',
          gap: 12,
          marginBottom: 6,
          fontSize: 11,
          fontFamily: 'monospace',
        }}
      >
        <span style={{ fontWeight: 700, color: verdictColour }}>
          VLAD: {summary.verdict}
        </span>
        <span style={{ color: '#ef4444' }}>✗ {summary.failCount}</span>
        <span style={{ color: '#f59e0b' }}>⚠ {summary.warnCount ?? 0}</span>
        <span style={{ color: '#22c55e' }}>✓ {summary.passCount}</span>
      </div>

      {/* Check rows */}
      <div>
        {summary.checks.map((c, i) => (
          <VladCheckRow key={i} check={c} />
        ))}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Toolbar button
// ---------------------------------------------------------------------------

interface ToolbarButtonProps {
  label: string;
  onClick: () => void;
  disabled?: boolean;
  variant?: 'primary' | 'secondary' | 'danger';
}

function ToolbarButton({
  label,
  onClick,
  disabled,
  variant = 'secondary',
}: ToolbarButtonProps) {
  const colours = {
    primary: { bg: '#2563eb', hover: '#1d4ed8', text: '#fff' },
    secondary: { bg: '#27272a', hover: '#3f3f46', text: '#d4d4d8' },
    danger: { bg: '#7f1d1d', hover: '#991b1b', text: '#fca5a5' },
  }[variant];

  const [hovered, setHovered] = useState(false);

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        padding: '4px 12px',
        border: 'none',
        borderRadius: 4,
        background: disabled ? '#1c1c1c' : hovered ? colours.hover : colours.bg,
        color: disabled ? '#555' : colours.text,
        cursor: disabled ? 'not-allowed' : 'pointer',
        fontSize: 12,
        fontFamily: 'monospace',
        fontWeight: 600,
        transition: 'background 0.1s',
      }}
    >
      {label}
    </button>
  );
}

// ---------------------------------------------------------------------------
// ModuleEditorPanel
// ---------------------------------------------------------------------------

export function ModuleEditorPanel({ style }: ModuleEditorPanelProps) {
  const {
    activeModuleId,
    modules,
    isLoading,
    executeModule,
    validateModule,
    upsertModule,
  } = useModuleStore();

  const { bumpGeometryVersion } = useViewportStore();

  const activeModule = modules.find((m) => m.id === activeModuleId);
  const [localCode, setLocalCode] = useState<string>(activeModule?.code ?? '');
  const [statusMsg, setStatusMsg] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  // Sync local code when active module changes
  useEffect(() => {
    setLocalCode(activeModule?.code ?? '');
    setStatusMsg(null);
  }, [activeModuleId, activeModule?.code]);

  // -------------------------------------------------------------------------
  // Execute
  // -------------------------------------------------------------------------

  const handleExecute = useCallback(async () => {
    if (!activeModuleId) return;
    setStatusMsg('Executing…');
    try {
      await executeModule(activeModuleId);
      const mod = useModuleStore.getState().modules.find((m) => m.id === activeModuleId);
      if (mod?.status === 'valid') {
        bumpGeometryVersion();
        setStatusMsg('Execution succeeded — geometry updated.');
      } else {
        setStatusMsg(`Execution failed: ${mod?.status}`);
      }
    } catch (err) {
      setStatusMsg(`Error: ${(err as Error).message}`);
    }
  }, [activeModuleId, executeModule, bumpGeometryVersion]);

  // -------------------------------------------------------------------------
  // Validate
  // -------------------------------------------------------------------------

  const handleValidate = useCallback(async () => {
    if (!activeModuleId) return;
    setStatusMsg('Running VLAD…');
    try {
      const summary = await validateModule(activeModuleId);
      setStatusMsg(`VLAD ${summary.verdict}: ${summary.failCount} fail(s).`);
    } catch (err) {
      setStatusMsg(`Validate error: ${(err as Error).message}`);
    }
  }, [activeModuleId, validateModule]);

  // -------------------------------------------------------------------------
  // Save (persist edited code)
  // -------------------------------------------------------------------------

  const handleSave = useCallback(async () => {
    if (!activeModuleId || !activeModule) return;
    setIsSaving(true);
    setStatusMsg('Saving…');
    try {
      const res = await fetch(`/api/modules/${activeModuleId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code: localCode }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const updated = await res.json();
      upsertModule(updated);
      setStatusMsg('Saved.');
    } catch (err) {
      setStatusMsg(`Save error: ${(err as Error).message}`);
    } finally {
      setIsSaving(false);
    }
  }, [activeModuleId, activeModule, localCode, upsertModule]);

  // -------------------------------------------------------------------------
  // Monaco keyboard shortcut: Ctrl+S → save
  // -------------------------------------------------------------------------

  const handleEditorMount: OnMount = useCallback(
    (editor: Monaco.editor.IStandaloneCodeEditor) => {
      editor.addAction({
        id: 'kfs-save',
        label: 'Save Module',
        keybindings: [2097 /* Monaco.KeyMod.CtrlCmd | Monaco.KeyCode.KeyS */],
        run: () => handleSave(),
      });
    },
    [handleSave],
  );

  // -------------------------------------------------------------------------
  // Empty state
  // -------------------------------------------------------------------------

  if (!activeModuleId || !activeModule) {
    return (
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100%',
          color: '#555',
          fontSize: 13,
          fontFamily: 'monospace',
          background: '#111',
          ...style,
        }}
      >
        Select a module from the sidebar to edit it.
      </div>
    );
  }

  const busy = isLoading || isSaving;

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        background: '#111',
        ...style,
      }}
    >
      {/* ── Toolbar ── */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          padding: '6px 12px',
          borderBottom: '1px solid #2a2a2a',
          background: '#161616',
          flexShrink: 0,
        }}
      >
        {/* Module name */}
        <span
          style={{
            fontSize: 13,
            fontFamily: 'monospace',
            color: '#93c5fd',
            marginRight: 4,
            fontWeight: 600,
          }}
        >
          {activeModule.name}
        </span>

        {/* Status badge */}
        <span
          style={{
            fontSize: 10,
            fontFamily: 'monospace',
            color:
              activeModule.status === 'valid'
                ? '#22c55e'
                : activeModule.status === 'failed'
                  ? '#ef4444'
                  : '#f59e0b',
            marginRight: 8,
          }}
        >
          {activeModule.status}
        </span>

        <div style={{ flex: 1 }} />

        <ToolbarButton
          label="Save"
          onClick={handleSave}
          disabled={busy}
          variant="secondary"
        />
        <ToolbarButton
          label="Execute"
          onClick={handleExecute}
          disabled={busy}
          variant="primary"
        />
        <ToolbarButton
          label="Validate"
          onClick={handleValidate}
          disabled={busy}
          variant="secondary"
        />
      </div>

      {/* ── Status message ── */}
      {statusMsg && (
        <div
          style={{
            padding: '3px 12px',
            fontSize: 11,
            fontFamily: 'monospace',
            color: '#aaa',
            background: '#0f0f0f',
            borderBottom: '1px solid #1f1f1f',
            flexShrink: 0,
          }}
        >
          {statusMsg}
        </div>
      )}

      {/* ── Monaco Editor ── */}
      <div style={{ flex: 1, minHeight: 0 }}>
        <Editor
          language="python"
          theme="vs-dark"
          value={localCode}
          onChange={(val) => setLocalCode(val ?? '')}
          onMount={handleEditorMount}
          options={{
            fontSize: 13,
            fontFamily: "'JetBrains Mono', 'Fira Code', monospace",
            minimap: { enabled: false },
            scrollBeyondLastLine: false,
            wordWrap: 'on',
            lineNumbers: 'on',
            renderWhitespace: 'boundary',
            tabSize: 4,
            insertSpaces: true,
          }}
        />
      </div>

      {/* ── VLAD results (shown below editor if available) ── */}
      <VladPanel moduleId={activeModuleId} />
    </div>
  );
}

export default ModuleEditorPanel;
