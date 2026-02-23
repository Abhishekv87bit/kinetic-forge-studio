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
};

export async function fetchHealth() {
    return api("/health");
}
