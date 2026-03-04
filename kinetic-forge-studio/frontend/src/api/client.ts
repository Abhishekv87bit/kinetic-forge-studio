const API_BASE = "http://localhost:8100/api";

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
    setScadDir: (id: string, scadDir: string) =>
        api(`/projects/${id}/scad-dir`, {
            method: "POST",
            body: JSON.stringify({ scad_dir: scadDir }),
        }),
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
    /** Load persisted chat history (survives server restarts). */
    history: (projectId: string) =>
        api(`/projects/${projectId}/chat/history`),
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

export const viewerApi = {
    listFiles: (projectId: string) =>
        api(`/projects/${projectId}/viewer/files`),
    openFile: (projectId: string, filePath?: string) =>
        api(`/projects/${projectId}/viewer/open`, {
            method: "POST",
            body: JSON.stringify({ file_path: filePath ?? null }),
        }),
};

export const profileApi = {
    get: () => api("/profile"),
    update: (data: Record<string, unknown>) =>
        api("/profile", { method: "PUT", body: JSON.stringify(data) }),
};

export const gateApi = {
    advanceGate: (projectId: string, targetGate?: string) =>
        api(`/projects/${projectId}/advance-gate`, {
            method: "POST",
            body: JSON.stringify({ target_gate: targetGate ?? "" }),
        }),
    chatStatus: (projectId: string) =>
        api(`/projects/${projectId}/chat/status`),
    getInfo: (projectId: string) =>
        api(`/projects/${projectId}/gate-info`),
};

export const rule99Api = {
    /** Run Rule 99 consultants for the current gate or a specific topic. */
    run: (projectId: string, topic?: string) =>
        api(`/projects/${projectId}/rule99`, {
            method: "POST",
            body: JSON.stringify({ topic: topic ?? null }),
        }),
};

export const rule500Api = {
    /** Trigger the full Rule 500 pipeline up to a gate level. */
    run: (projectId: string, gateLevel?: string) =>
        api(`/projects/${projectId}/rule500`, {
            method: "POST",
            body: JSON.stringify({ gate_level: gateLevel ?? "design" }),
        }),
    /** Get pipeline progress / last run status. */
    status: (projectId: string) =>
        api(`/projects/${projectId}/rule500/status`),
};

export const snapshotApi = {
    list: (projectId: string) => api(`/projects/${projectId}/snapshots`),
    create: (projectId: string, label: string) =>
        api(`/projects/${projectId}/snapshots`, {
            method: "POST",
            body: JSON.stringify({ label }),
        }),
    rollback: (projectId: string, snapshotId: number) =>
        api(`/projects/${projectId}/snapshots/${snapshotId}/rollback`, {
            method: "POST",
        }),
};

export async function fetchHealth() {
    return api("/health");
}
