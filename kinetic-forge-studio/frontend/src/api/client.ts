const API_BASE = "http://localhost:8000/api";

async function api(path: string, options?: RequestInit) {
    const res = await fetch(`${API_BASE}${path}`, {
        headers: { "Content-Type": "application/json" },
        ...options,
    });
    if (!res.ok) throw new Error(`API error: ${res.status}`);
    return res.json();
}

export const projectsApi = {
    list: () => api("/projects"),
    create: (name: string) => api("/projects", { method: "POST", body: JSON.stringify({ name }) }),
    get: (id: string) => api(`/projects/${id}`),
    addDecision: (id: string, data: { parameter: string; value: string; reason?: string }) =>
        api(`/projects/${id}/decisions`, { method: "POST", body: JSON.stringify(data) }),
    lockDecision: (id: string, decisionId: number) =>
        api(`/projects/${id}/decisions/${decisionId}/lock`, { method: "POST" }),
    listComponents: (id: string) => api(`/projects/${id}/components`),
    getGateStatus: (id: string) => api(`/projects/${id}/gate-status`),
};

export const chatApi = {
    send: (projectId: string, content: string) =>
        api(`/projects/${projectId}/chat`, {
            method: "POST",
            body: JSON.stringify({ content }),
        }),
    answer: (projectId: string, field: string, value: unknown) =>
        api(`/projects/${projectId}/chat/answer`, {
            method: "POST",
            body: JSON.stringify({ field, value }),
        }),
    reset: (projectId: string) =>
        api(`/projects/${projectId}/chat/reset`, { method: "POST" }),
};

export const uploadApi = {
    upload: async (projectId: string, file: File) => {
        const form = new FormData();
        form.append("file", file);
        const res = await fetch(`${API_BASE}/projects/${projectId}/upload`, {
            method: "POST",
            body: form,
        });
        if (!res.ok) throw new Error(`Upload error: ${res.status}`);
        return res.json();
    },
};

export const libraryApi = {
    search: (query: string) => api(`/library/search?q=${encodeURIComponent(query)}`),
    get: (entryId: string) => api(`/library/${entryId}`),
    add: (data: {
        name: string;
        mechanism_types?: string;
        keywords?: string;
        source?: string;
        envelope_x?: number;
        envelope_y?: number;
        envelope_z?: number;
        file_path?: string;
        thumbnail_path?: string;
        project_id?: string;
    }) => api("/library", { method: "POST", body: JSON.stringify(data) }),
};

export const exportApi = {
    download: async (projectId: string): Promise<Blob> => {
        const res = await fetch(`${API_BASE}/projects/${projectId}/export`);
        if (!res.ok) throw new Error(`Export error: ${res.status}`);
        return res.blob();
    },
};

export const viewportApi = {
    geometryUrl: (projectId: string) => `${API_BASE}/projects/${projectId}/geometry`,
    geometryInfo: (projectId: string) => api(`/projects/${projectId}/geometry/info`),
};

export async function fetchHealth() {
    return api("/health");
}
