import { create } from "zustand";
import { projectsApi } from "../api/client";

interface Decision {
    id: number;
    parameter: string;
    value: string;
    reason: string;
    status: string;
}

interface Component {
    id: string;
    display_name: string;
    type: string;
    parameters: Record<string, unknown>;
}

interface ProjectSummary {
    id: string;
    name: string;
    gate: string;
    created_at: string;
}

interface ProjectState {
    screen: "home" | "workspace";
    projects: ProjectSummary[];
    activeProject: {
        id: string;
        name: string;
        gate: string;
        decisions: Decision[];
        components: Component[];
    } | null;
    loadProjects: () => Promise<void>;
    createProject: (name: string) => Promise<void>;
    openProject: (id: string) => Promise<void>;
    goHome: () => void;
}

export const useProjectStore = create<ProjectState>((set) => ({
    screen: "home",
    projects: [],
    activeProject: null,

    loadProjects: async () => {
        const projects = await projectsApi.list();
        set({ projects });
    },

    createProject: async (name: string) => {
        const project = await projectsApi.create(name);
        const full = await projectsApi.get(project.id);
        set({ screen: "workspace", activeProject: full });
    },

    openProject: async (id: string) => {
        const full = await projectsApi.get(id);
        set({ screen: "workspace", activeProject: full });
    },

    goHome: () => set({ screen: "home", activeProject: null }),
}));
