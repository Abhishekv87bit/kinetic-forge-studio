/**
 * SC-04 viewportStore — Zustand store for 3-D viewport state.
 *
 * Tracks which module is currently displayed in the Three.js canvas and
 * provides a geometry version counter that Viewport3D.tsx uses as a React
 * dependency to trigger a GLB refetch without a full page reload.
 *
 * Usage pattern:
 *   const { activeModuleId, geometryVersion, setActiveModuleId } = useViewportStore();
 *   const url = activeModuleId
 *     ? `/api/modules/${activeModuleId}/geometry?v=${geometryVersion}`
 *     : null;
 */
import { create } from 'zustand';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface ViewportStore {
  /** Module currently shown in the 3-D canvas, or null when idle. */
  activeModuleId: string | null;

  /**
   * Monotonically increasing integer.  Viewport3D.tsx appends this as a
   * query-string cache-buster (?v=N) so Three.js refetches the GLB every
   * time new geometry is available without a page reload.
   */
  geometryVersion: number;

  /** Explicit geometry URL override (takes precedence over activeModuleId). */
  geometryUrl: string | null;

  /** Whether the viewport is currently loading a geometry asset. */
  isGeometryLoading: boolean;

  /** Last geometry load error, or null on success. */
  geometryError: string | null;

  // Actions
  setActiveModuleId: (id: string | null) => void;
  setGeometryUrl: (url: string | null) => void;
  bumpGeometryVersion: () => void;
  setGeometryLoading: (loading: boolean) => void;
  setGeometryError: (error: string | null) => void;

  /** Derive the current geometry URL from activeModuleId + geometryVersion. */
  resolvedGeometryUrl: () => string | null;
}

// ---------------------------------------------------------------------------
// Store
// ---------------------------------------------------------------------------

export const useViewportStore = create<ViewportStore>((set, get) => ({
  activeModuleId: null,
  geometryVersion: 0,
  geometryUrl: null,
  isGeometryLoading: false,
  geometryError: null,

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  setActiveModuleId: (id) =>
    set({
      activeModuleId: id,
      geometryError: null,
      // Reset loading state when switching modules
      isGeometryLoading: id !== null,
    }),

  setGeometryUrl: (url) => set({ geometryUrl: url }),

  /**
   * Increment the geometry version counter.  Call this after a successful
   * module execution (SC-02) so Viewport3D detects the change and reloads.
   */
  bumpGeometryVersion: () =>
    set((state) => ({ geometryVersion: state.geometryVersion + 1 })),

  setGeometryLoading: (loading) => set({ isGeometryLoading: loading }),

  setGeometryError: (error) => set({ geometryError: error, isGeometryLoading: false }),

  // ---------------------------------------------------------------------------
  // Derived
  // ---------------------------------------------------------------------------

  resolvedGeometryUrl: () => {
    const { geometryUrl, activeModuleId, geometryVersion } = get();
    if (geometryUrl) return geometryUrl;
    if (!activeModuleId) return null;
    return `/api/modules/${activeModuleId}/geometry?v=${geometryVersion}`;
  },
}));
