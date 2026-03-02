import { useState, useEffect } from "react";
import { useProjectStore } from "../stores/projectStore";

export default function HomeScreen() {
    const { projects, loadProjects, createProject, openProject } = useProjectStore();
    const [newName, setNewName] = useState("");

    useEffect(() => { loadProjects(); }, [loadProjects]);

    const handleCreate = () => {
        if (newName.trim()) {
            createProject(newName.trim());
            setNewName("");
        }
    };

    return (
        <div style={{ maxWidth: 600, margin: "80px auto", color: "#fff" }}>
            <h1>Kinetic Forge Studio</h1>
            <div style={{ display: "flex", gap: 8, marginBottom: 32 }}>
                <input
                    value={newName}
                    onChange={(e) => setNewName(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && handleCreate()}
                    placeholder="New project name..."
                    style={{ flex: 1, padding: "8px 12px", borderRadius: 4, border: "1px solid #444", background: "#1a1a2e", color: "#fff" }}
                />
                <button onClick={handleCreate} style={{ padding: "8px 16px", borderRadius: 4, background: "#4a9eff", color: "#fff", border: "none", cursor: "pointer" }}>
                    + New Project
                </button>
            </div>
            {projects.length === 0 ? (
                <p style={{ opacity: 0.5 }}>No projects yet. Create one to get started.</p>
            ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                    {projects.map((p) => (
                        <div key={p.id} onClick={() => openProject(p.id)}
                            style={{ padding: "12px 16px", background: "#16213e", borderRadius: 8, cursor: "pointer", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                            <div>
                                <strong>{p.name}</strong>
                                <span style={{ opacity: 0.5, marginLeft: 12, fontSize: 12 }}>
                                    Gate: {p.gate}
                                </span>
                            </div>
                            <span style={{ fontSize: 12, opacity: 0.4 }}>
                                {new Date(p.created_at).toLocaleDateString()}
                            </span>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
