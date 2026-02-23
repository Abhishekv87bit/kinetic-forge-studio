import { create } from "zustand";

interface SelectedMesh {
    name: string;
    uuid: string;
    boundingBox: {
        min: [number, number, number];
        max: [number, number, number];
    } | null;
    vertexCount: number;
    faceCount: number;
}

interface ViewportState {
    /** Currently selected mesh info (null if nothing selected) */
    selectedMesh: SelectedMesh | null;
    /** Whether geometry is currently loading */
    loading: boolean;
    /** Error message if geometry loading failed */
    error: string | null;
    /** Geometry revision counter — increment to force reload */
    geometryVersion: number;

    selectMesh: (mesh: SelectedMesh | null) => void;
    setLoading: (loading: boolean) => void;
    setError: (error: string | null) => void;
    reloadGeometry: () => void;
}

export const useViewportStore = create<ViewportState>((set) => ({
    selectedMesh: null,
    loading: false,
    error: null,
    geometryVersion: 0,

    selectMesh: (mesh) => set({ selectedMesh: mesh }),
    setLoading: (loading) => set({ loading }),
    setError: (error) => set({ error }),
    reloadGeometry: () => set((s) => ({ geometryVersion: s.geometryVersion + 1 })),
}));
