import { useState, useEffect } from "react";
import { useProjectStore } from "../stores/projectStore";

const GATE_COLORS: Record<string, string> = {
    design: "var(--accent-blue)",
    prototype: "var(--accent-amber)",
    production: "var(--accent-green)",
};

export default function HomeScreen() {
    const { projects, loadProjects, createProject, openProject } = useProjectStore();
    const [newName, setNewName] = useState("");

    // eslint-disable-next-line react-hooks/exhaustive-deps -- Zustand store functions are stable
    useEffect(() => { loadProjects(); }, []);

    const handleCreate = () => {
        if (newName.trim()) {
            createProject(newName.trim());
            setNewName("");
        }
    };

    return (
        <div style={{
            width: "100vw",
            height: "100vh",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "var(--bg-base)",
            overflowY: "auto",
        }}>
            <div style={{
                width: "100%",
                maxWidth: 560,
                padding: "var(--space-8)",
                margin: "auto",
            }}>
                {/* Branding */}
                <div style={{ marginBottom: "var(--space-8)" }}>
                    <h1 style={{
                        fontSize: 28,
                        fontWeight: 700,
                        color: "var(--text-primary)",
                        marginBottom: "var(--space-2)",
                        letterSpacing: "-0.02em",
                    }}>
                        Kinetic Forge Studio
                    </h1>
                    <p style={{
                        fontSize: 14,
                        color: "var(--text-muted)",
                        lineHeight: 1.6,
                    }}>
                        Design kinetic sculptures with methodology-enforced mechanical validation.
                    </p>
                </div>

                {/* New Project */}
                <div style={{
                    display: "flex",
                    gap: "var(--space-2)",
                    marginBottom: "var(--space-6)",
                }}>
                    <input
                        value={newName}
                        onChange={(e) => setNewName(e.target.value)}
                        onKeyDown={(e) => e.key === "Enter" && handleCreate()}
                        placeholder="New project name..."
                        style={{
                            flex: 1,
                            padding: "10px 14px",
                            borderRadius: "var(--radius-md)",
                            border: "1px solid var(--border-default)",
                            background: "var(--bg-input)",
                            color: "var(--text-primary)",
                            fontSize: 14,
                            outline: "none",
                            transition: "border-color 0.15s ease",
                        }}
                        onFocus={(e) => { e.currentTarget.style.borderColor = "var(--accent-blue)"; }}
                        onBlur={(e) => { e.currentTarget.style.borderColor = "var(--border-default)"; }}
                    />
                    <button
                        onClick={handleCreate}
                        style={{
                            padding: "10px 20px",
                            borderRadius: "var(--radius-md)",
                            background: "var(--accent-blue)",
                            color: "#fff",
                            fontWeight: 600,
                            fontSize: 13,
                            transition: "background 0.15s ease",
                        }}
                        onMouseEnter={(e) => { e.currentTarget.style.background = "var(--accent-blue-hover)"; }}
                        onMouseLeave={(e) => { e.currentTarget.style.background = "var(--accent-blue)"; }}
                    >
                        New Project
                    </button>
                </div>

                {/* Project list */}
                {projects.length === 0 ? (
                    <div style={{
                        padding: "var(--space-8)",
                        textAlign: "center",
                        color: "var(--text-muted)",
                        fontSize: 13,
                        border: "1px dashed var(--border-default)",
                        borderRadius: "var(--radius-lg)",
                    }}>
                        No projects yet. Create one to get started.
                    </div>
                ) : (
                    <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-2)" }}>
                        {projects.map((p) => {
                            const gateColor = GATE_COLORS[p.gate] ?? "var(--text-muted)";
                            return (
                                <div
                                    key={p.id}
                                    className="project-card"
                                    onClick={() => openProject(p.id)}
                                    style={{
                                        padding: "var(--space-3) var(--space-4)",
                                        background: "var(--bg-surface)",
                                        borderRadius: "var(--radius-md)",
                                        border: "1px solid var(--border-subtle)",
                                        cursor: "pointer",
                                        display: "flex",
                                        justifyContent: "space-between",
                                        alignItems: "center",
                                    }}
                                >
                                    <div style={{ display: "flex", alignItems: "center", gap: "var(--space-3)" }}>
                                        <span style={{
                                            fontWeight: 600,
                                            fontSize: 14,
                                            color: "var(--text-primary)",
                                        }}>
                                            {p.name}
                                        </span>
                                        <span className="gate-pill" style={{
                                            background: `color-mix(in srgb, ${gateColor} 12%, transparent)`,
                                            color: gateColor,
                                            border: `1px solid color-mix(in srgb, ${gateColor} 25%, transparent)`,
                                        }}>
                                            {p.gate.toUpperCase()}
                                        </span>
                                    </div>
                                    <span style={{
                                        fontSize: 12,
                                        color: "var(--text-muted)",
                                    }}>
                                        {new Date(p.created_at).toLocaleDateString()}
                                    </span>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>
        </div>
    );
}
