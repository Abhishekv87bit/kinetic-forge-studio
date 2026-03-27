/**
 * SC-04 ModuleListPanel — sidebar showing all modules in the current project.
 *
 * Clicking a module row:
 *   1. Sets activeModuleId in both moduleStore and viewportStore (which causes
 *      Viewport3D to load the new GLB automatically via resolvedGeometryUrl()).
 *   2. Highlights the selected row.
 *
 * Status badge colours mirror VLAD verdict:
 *   valid (PASS) → green
 *   failed       → red
 *   pending      → amber
 */
import React, { useEffect } from 'react';

import { useModuleStore, type KFSModule } from '../stores/moduleStore';
import { useViewportStore } from '../stores/viewportStore';
import { useProjectStore } from '../stores/projectStore';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ModuleListPanelProps {
  /** If provided, panel will auto-fetch modules for this project on mount. */
  projectId?: string;
  /** Optional inline style overrides for the panel container. */
  style?: React.CSSProperties;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const STATUS_COLOURS: Record<string, string> = {
  valid: '#22c55e',
  failed: '#ef4444',
  pending: '#f59e0b',
};

function StatusBadge({ status }: { status: string }) {
  return (
    <span
      style={{
        display: 'inline-block',
        width: 8,
        height: 8,
        borderRadius: '50%',
        background: STATUS_COLOURS[status] ?? '#666',
        marginRight: 6,
        flexShrink: 0,
      }}
      title={status}
    />
  );
}

// ---------------------------------------------------------------------------
// Single module row
// ---------------------------------------------------------------------------

interface ModuleRowProps {
  module: KFSModule;
  isActive: boolean;
  onSelect: (id: string) => void;
}

function ModuleRow({ module, isActive, onSelect }: ModuleRowProps) {
  return (
    <button
      onClick={() => onSelect(module.id)}
      style={{
        display: 'flex',
        alignItems: 'center',
        width: '100%',
        padding: '8px 12px',
        border: 'none',
        borderLeft: isActive ? '3px solid #3b82f6' : '3px solid transparent',
        background: isActive ? 'rgba(59,130,246,0.12)' : 'transparent',
        color: isActive ? '#93c5fd' : '#ccc',
        cursor: 'pointer',
        textAlign: 'left',
        fontFamily: 'monospace',
        fontSize: 13,
        borderRadius: 0,
        transition: 'background 0.1s',
      }}
      onMouseEnter={(e) => {
        if (!isActive) {
          (e.currentTarget as HTMLButtonElement).style.background = 'rgba(255,255,255,0.05)';
        }
      }}
      onMouseLeave={(e) => {
        if (!isActive) {
          (e.currentTarget as HTMLButtonElement).style.background = 'transparent';
        }
      }}
    >
      <StatusBadge status={module.status} />
      <span
        style={{
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap',
          flex: 1,
        }}
      >
        {module.name}
      </span>
      {module.vladSummary && (
        <span
          style={{
            fontSize: 10,
            color: module.vladSummary.verdict === 'PASS' ? '#22c55e' : '#ef4444',
            marginLeft: 6,
            fontWeight: 700,
          }}
        >
          {module.vladSummary.verdict}
        </span>
      )}
    </button>
  );
}

// ---------------------------------------------------------------------------
// Panel
// ---------------------------------------------------------------------------

export function ModuleListPanel({ projectId, style }: ModuleListPanelProps) {
  const { modules, activeModuleId, setActiveModuleId, fetchModules, isLoading, error } =
    useModuleStore();
  const { setActiveModuleId: setViewportModuleId } = useViewportStore();

  // Fetch modules if projectId provided and list is empty
  useEffect(() => {
    if (projectId && modules.length === 0) {
      fetchModules(projectId);
    }
  }, [projectId, modules.length, fetchModules]);

  const handleSelect = (id: string) => {
    setActiveModuleId(id);
    setViewportModuleId(id);
  };

  return (
    <aside
      style={{
        width: 220,
        minWidth: 180,
        height: '100%',
        background: '#161616',
        borderRight: '1px solid #2a2a2a',
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
        ...style,
      }}
    >
      {/* Header */}
      <div
        style={{
          padding: '10px 12px',
          borderBottom: '1px solid #2a2a2a',
          fontSize: 11,
          fontWeight: 700,
          letterSpacing: '0.08em',
          color: '#666',
          fontFamily: 'monospace',
          textTransform: 'uppercase',
        }}
      >
        Modules
        {isLoading && (
          <span style={{ marginLeft: 6, color: '#f59e0b', fontWeight: 400 }}>…</span>
        )}
      </div>

      {/* Error banner */}
      {error && (
        <div
          style={{
            padding: '6px 12px',
            background: '#2a0a0a',
            color: '#ef4444',
            fontSize: 11,
            fontFamily: 'monospace',
            borderBottom: '1px solid #3a1010',
          }}
        >
          {error}
        </div>
      )}

      {/* Module list */}
      <div style={{ flex: 1, overflowY: 'auto' }}>
        {modules.length === 0 && !isLoading ? (
          <div
            style={{
              padding: '20px 12px',
              color: '#555',
              fontSize: 12,
              fontFamily: 'monospace',
              textAlign: 'center',
            }}
          >
            No modules yet.
            <br />
            Use the chat to generate one.
          </div>
        ) : (
          modules.map((m) => (
            <ModuleRow
              key={m.id}
              module={m}
              isActive={m.id === activeModuleId}
              onSelect={handleSelect}
            />
          ))
        )}
      </div>

      {/* Footer — module count */}
      <div
        style={{
          padding: '6px 12px',
          borderTop: '1px solid #2a2a2a',
          fontSize: 11,
          color: '#555',
          fontFamily: 'monospace',
        }}
      >
        {modules.length} module{modules.length !== 1 ? 's' : ''}
      </div>
    </aside>
  );
}

export default ModuleListPanel;
