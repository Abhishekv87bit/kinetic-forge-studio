/**
 * SC-04 moduleStore — Zustand store for KFS module state.
 *
 * Manages the list of modules for the current project, tracks which module
 * is active in the editor/viewport, and wraps the backend API calls for
 * execute and validate operations.
 *
 * geometryVersion is incremented after a successful execution so that
 * Viewport3D.tsx refetches the geometry URL without a full page reload.
 */
import { create } from 'zustand';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type ModuleStatus = 'valid' | 'failed' | 'pending';

export interface VladCheck {
  id: string;
  status: string;
  detail: string;
}

export interface VladSummary {
  verdict: 'PASS' | 'FAIL';
  failCount: number;
  warnCount: number;
  passCount: number;
  checks: VladCheck[];
}

export interface KFSModule {
  id: string;
  name: string;
  code: string;
  status: ModuleStatus;
  /** Monotonically increasing counter — bumped each time geometry is rebuilt. */
  geometryVersion: number;
  vladSummary?: VladSummary;
  createdAt: string;
  updatedAt: string;
}

export interface ModuleStore {
  modules: KFSModule[];
  activeModuleId: string | null;
  isLoading: boolean;
  error: string | null;

  // Selectors
  activeModule: () => KFSModule | undefined;

  // Actions
  setActiveModuleId: (id: string | null) => void;
  setModules: (modules: KFSModule[]) => void;
  upsertModule: (module: KFSModule) => void;

  // Async API calls
  fetchModules: (projectId: string) => Promise<void>;
  saveAsModule: (opts: { name: string; code: string; projectId: string }) => Promise<KFSModule>;
  executeModule: (moduleId: string) => Promise<void>;
  validateModule: (moduleId: string) => Promise<VladSummary>;
}

// ---------------------------------------------------------------------------
// Store
// ---------------------------------------------------------------------------

export const useModuleStore = create<ModuleStore>((set, get) => ({
  modules: [],
  activeModuleId: null,
  isLoading: false,
  error: null,

  // ---------------------------------------------------------------------------
  // Selectors
  // ---------------------------------------------------------------------------

  activeModule: () => {
    const { modules, activeModuleId } = get();
    return modules.find((m) => m.id === activeModuleId);
  },

  // ---------------------------------------------------------------------------
  // Synchronous actions
  // ---------------------------------------------------------------------------

  setActiveModuleId: (id) => set({ activeModuleId: id }),

  setModules: (modules) => set({ modules }),

  upsertModule: (updated) =>
    set((state) => {
      const idx = state.modules.findIndex((m) => m.id === updated.id);
      if (idx === -1) {
        return { modules: [...state.modules, updated] };
      }
      const next = [...state.modules];
      next[idx] = updated;
      return { modules: next };
    }),

  // ---------------------------------------------------------------------------
  // Async: fetch all modules for a project
  // ---------------------------------------------------------------------------

  fetchModules: async (projectId) => {
    set({ isLoading: true, error: null });
    try {
      const res = await fetch(`/api/projects/${projectId}/modules`);
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
      const data: KFSModule[] = await res.json();
      set({ modules: data, isLoading: false });
    } catch (err) {
      set({ isLoading: false, error: (err as Error).message });
    }
  },

  // ---------------------------------------------------------------------------
  // Async: save chat code as a new module
  // ---------------------------------------------------------------------------

  saveAsModule: async ({ name, code, projectId }) => {
    set({ isLoading: true, error: null });
    try {
      const res = await fetch(`/api/projects/${projectId}/modules`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, code }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
      const created: KFSModule = await res.json();
      get().upsertModule(created);
      set({ isLoading: false });
      return created;
    } catch (err) {
      set({ isLoading: false, error: (err as Error).message });
      throw err;
    }
  },

  // ---------------------------------------------------------------------------
  // Async: execute module — runs CadQuery code, bumps geometryVersion on success
  // ---------------------------------------------------------------------------

  executeModule: async (moduleId) => {
    set({ isLoading: true, error: null });
    try {
      const res = await fetch(`/api/modules/${moduleId}/execute`, { method: 'POST' });
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
      const result: { status: string; error?: string } = await res.json();

      set((state) => ({
        isLoading: false,
        modules: state.modules.map((m) =>
          m.id === moduleId
            ? {
                ...m,
                status: result.status === 'valid' ? 'valid' : 'failed',
                // Bump geometryVersion on success so Viewport3D refetches GLB
                geometryVersion:
                  result.status === 'valid' ? m.geometryVersion + 1 : m.geometryVersion,
              }
            : m,
        ),
      }));
    } catch (err) {
      set({ isLoading: false, error: (err as Error).message });
      throw err;
    }
  },

  // ---------------------------------------------------------------------------
  // Async: validate module via VLAD runner
  // ---------------------------------------------------------------------------

  validateModule: async (moduleId) => {
    set({ isLoading: true, error: null });
    try {
      const res = await fetch(`/api/modules/${moduleId}/validate`, { method: 'POST' });
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
      const summary: VladSummary = await res.json();

      set((state) => ({
        isLoading: false,
        modules: state.modules.map((m) =>
          m.id === moduleId ? { ...m, vladSummary: summary } : m,
        ),
      }));

      return summary;
    } catch (err) {
      set({ isLoading: false, error: (err as Error).message });
      throw err;
    }
  },
}));
