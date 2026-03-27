/**
 * SC-04 projectStore — Zustand store for KFS project-level state.
 *
 * Holds the active project ID and the ordered list of modules that belong
 * to it.  ModuleListPanel.tsx reads `modules` to render the sidebar;
 * ChatPanel.tsx reads `projectId` when saving a new module.
 *
 * The `modules` array here mirrors the moduleStore's list but is the
 * project-scoped source of truth — it is populated once on project load
 * and updated whenever the user saves or deletes a module.
 */
import { create } from 'zustand';
import type { KFSModule } from './moduleStore';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface KFSProject {
  id: string;
  name: string;
  description?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ProjectStore {
  /** Active project metadata, or null when no project is open. */
  project: KFSProject | null;

  /** Stable project ID shorthand (null when no project is open). */
  projectId: string | null;

  /**
   * Ordered list of modules that belong to the current project.
   * Kept in sync with the backend via fetchProject.
   */
  modules: KFSModule[];

  isLoading: boolean;
  error: string | null;

  // Actions
  setProject: (project: KFSProject) => void;
  setModules: (modules: KFSModule[]) => void;
  upsertModule: (module: KFSModule) => void;
  removeModule: (moduleId: string) => void;

  // Async
  fetchProject: (projectId: string) => Promise<void>;
}

// ---------------------------------------------------------------------------
// Store
// ---------------------------------------------------------------------------

export const useProjectStore = create<ProjectStore>((set, get) => ({
  project: null,
  projectId: null,
  modules: [],
  isLoading: false,
  error: null,

  // ---------------------------------------------------------------------------
  // Synchronous actions
  // ---------------------------------------------------------------------------

  setProject: (project) => set({ project, projectId: project.id }),

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

  removeModule: (moduleId) =>
    set((state) => ({
      modules: state.modules.filter((m) => m.id !== moduleId),
    })),

  // ---------------------------------------------------------------------------
  // Async: load project + modules in one request
  // ---------------------------------------------------------------------------

  fetchProject: async (projectId) => {
    set({ isLoading: true, error: null });
    try {
      const [projectRes, modulesRes] = await Promise.all([
        fetch(`/api/projects/${projectId}`),
        fetch(`/api/projects/${projectId}/modules`),
      ]);

      if (!projectRes.ok) {
        throw new Error(`Project fetch failed: HTTP ${projectRes.status}`);
      }
      if (!modulesRes.ok) {
        throw new Error(`Modules fetch failed: HTTP ${modulesRes.status}`);
      }

      const project: KFSProject = await projectRes.json();
      const modules: KFSModule[] = await modulesRes.json();

      set({ project, projectId: project.id, modules, isLoading: false });
    } catch (err) {
      set({ isLoading: false, error: (err as Error).message });
    }
  },
}));
