/**
 * SC-04 projectStore — Zustand store for KFS project-level state.
 *
 * Holds the active project ID and metadata.  Module list is owned exclusively
 * by moduleStore; fetchProject writes modules there to avoid dual-store desync
 * (mutations via execute/validate only update moduleStore, so a second copy
 * here would go stale immediately).
 */
import { create } from 'zustand';
import type { KFSModule } from './moduleStore';
import { useModuleStore } from './moduleStore';

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

  isLoading: boolean;
  error: string | null;

  // Actions
  setProject: (project: KFSProject) => void;

  // Async
  fetchProject: (projectId: string) => Promise<void>;
}

// ---------------------------------------------------------------------------
// Store
// ---------------------------------------------------------------------------

export const useProjectStore = create<ProjectStore>((set) => ({
  project: null,
  projectId: null,
  isLoading: false,
  error: null,

  // ---------------------------------------------------------------------------
  // Synchronous actions
  // ---------------------------------------------------------------------------

  setProject: (project) => set({ project, projectId: project.id }),

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

      useModuleStore.getState().setModules(modules);
      set({ project, projectId: project.id, isLoading: false });
    } catch (err) {
      set({ isLoading: false, error: (err as Error).message });
    }
  },
}));
