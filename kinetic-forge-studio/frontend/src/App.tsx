import { useState, useCallback } from "react";
import { useProjectStore } from "./stores/projectStore";
import { useViewportStore } from "./stores/viewportStore";
import { exportApi } from "./api/client";
import HomeScreen from "./components/HomeScreen";
import Viewport3D from "./components/Viewport3D";
import ChatPanel from "./components/ChatPanel";
import GateStatus from "./components/GateStatus";
import PipelinePanel from "./components/PipelinePanel";
import ProjectFilesPanel from "./components/ProjectFilesPanel";

/* ── Selected Mesh Info ───────────────────────────────── */

function SelectedMeshInfo() {
    const selectedMesh = useViewportStore((s) => s.selectedMesh);
    if (!selectedMesh) return null;

    const bb = selectedMesh.boundingBox;
    const size = bb
        ? [
            (bb.max[0] - bb.min[0]).toFixed(1),
            (bb.max[1] - bb.min[1]).toFixed(1),
            (bb.max[2] - bb.min[2]).toFixed(1),
        ]
        : null;

    return (
        <div style={{
            padding: "var(--space-3)",
            background: "var(--bg-overlay)",
            borderRadius: "var(--radius-md)",
            border: "1px solid var(--border-default)",
            marginBottom: "var(--space-3)",
        }}>
            <div style={{
                fontSize: 11,
                fontWeight: 600,
                textTransform: "uppercase" as const,
                letterSpacing: "0.05em",
                color: "var(--accent-blue)",
                marginBottom: 6,
            }}>
                Selected
            </div>
            <div style={{ fontSize: 12, lineHeight: 1.7, color: "var(--text-secondary)" }}>
                <div><span style={{ color: "var(--text-muted)" }}>Name</span> {selectedMesh.name}</div>
                <div><span style={{ color: "var(--text-muted)" }}>Verts</span> {selectedMesh.vertexCount.toLocaleString()}</div>
                <div><span style={{ color: "var(--text-muted)" }}>Faces</span> {selectedMesh.faceCount.toLocaleString()}</div>
                {size && (
                    <div><span style={{ color: "var(--text-muted)" }}>Size</span> {size[0]} {"\u00D7"} {size[1]} {"\u00D7"} {size[2]} mm</div>
                )}
            </div>
        </div>
    );
}

/* ── Right Sidebar Section ────────────────────────────── */

function SidebarSection({ label, count, children, defaultOpen = true }: {
    label: string;
    count?: number;
    children: React.ReactNode;
    defaultOpen?: boolean;
}) {
    const [open, setOpen] = useState(defaultOpen);
    return (
        <div style={{ marginBottom: "var(--space-2)" }}>
            <button
                onClick={() => setOpen(!open)}
                style={{
                    width: "100%",
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    padding: "var(--space-2) 0",
                    color: "var(--text-muted)",
                    fontSize: 11,
                    fontWeight: 600,
                    textTransform: "uppercase" as const,
                    letterSpacing: "0.05em",
                    userSelect: "none" as const,
                }}
            >
                <span>
                    {open ? "\u25BC" : "\u25B6"} {label}
                    {count !== undefined && (
                        <span style={{
                            marginLeft: 6,
                            padding: "1px 6px",
                            borderRadius: 100,
                            background: "var(--bg-overlay)",
                            fontSize: 10,
                            fontWeight: 500,
                            color: "var(--text-secondary)",
                        }}>
                            {count}
                        </span>
                    )}
                </span>
            </button>
            {open && <div className="fade-in">{children}</div>}
        </div>
    );
}

/* ── Workspace ────────────────────────────────────────── */

function Workspace() {
    const { activeProject, goHome } = useProjectStore();
    const [gatePassed, setGatePassed] = useState(false);
    const [rightTab, setRightTab] = useState<"spec" | "pipeline">("spec");

    const handleGateChange = useCallback((passed: boolean) => {
        setGatePassed(passed);
    }, []);

    const handleExport = useCallback(async () => {
        if (!gatePassed || !activeProject) return;
        try {
            const blob = await exportApi.download(activeProject.id);
            const url = URL.createObjectURL(blob);
            const a = document.createElement("a");
            a.href = url;
            a.download = `${activeProject.name.replace(/ /g, "_")}_export.zip`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        } catch (err) {
            alert(`Export failed: ${err instanceof Error ? err.message : "unknown error"}`);
        }
    }, [gatePassed, activeProject]);

    if (!activeProject) return null;

    const gateColor = activeProject.gate === "production" ? "var(--accent-green)"
        : activeProject.gate === "prototype" ? "var(--accent-amber)"
        : "var(--accent-blue)";

    return (
        <div style={{
            display: "flex",
            flexDirection: "column",
            height: "100vh",
            width: "100vw",
            background: "var(--bg-base)",
        }}>
            {/* ── Header ─────────────────────────────── */}
            <header style={{
                height: "var(--header-height)",
                minHeight: "var(--header-height)",
                padding: "0 var(--space-4)",
                borderBottom: "1px solid var(--border-subtle)",
                background: "var(--bg-surface)",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
            }}>
                <div style={{ display: "flex", alignItems: "center", gap: "var(--space-4)" }}>
                    <button
                        onClick={goHome}
                        style={{
                            color: "var(--text-muted)",
                            fontSize: 13,
                            display: "flex",
                            alignItems: "center",
                            gap: 4,
                        }}
                    >
                        <span style={{ fontSize: 16 }}>{"\u2190"}</span>
                    </button>
                    <div style={{
                        width: 1,
                        height: 20,
                        background: "var(--border-subtle)",
                    }} />
                    <span style={{
                        fontWeight: 600,
                        fontSize: 14,
                        color: "var(--text-primary)",
                    }}>
                        {activeProject.name}
                    </span>
                    <span className="gate-pill" style={{
                        background: `color-mix(in srgb, ${gateColor} 15%, transparent)`,
                        color: gateColor,
                        border: `1px solid color-mix(in srgb, ${gateColor} 30%, transparent)`,
                    }}>
                        {activeProject.gate.toUpperCase()}
                    </span>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: "var(--space-3)" }}>
                    <button
                        onClick={handleExport}
                        disabled={!gatePassed}
                        style={{
                            padding: "6px 18px",
                            borderRadius: "var(--radius-sm)",
                            fontWeight: 600,
                            fontSize: 12,
                            background: gatePassed ? "var(--accent-blue)" : "var(--bg-elevated)",
                            color: gatePassed ? "#fff" : "var(--text-disabled)",
                            opacity: gatePassed ? 1 : 0.6,
                            transition: "all 0.15s ease",
                        }}
                        title={gatePassed ? "Export STEP + STL package" : "Fix validation errors before exporting"}
                    >
                        Export
                    </button>
                </div>
            </header>

            {/* ── Main Content ───────────────────────── */}
            <div style={{ display: "flex", flex: 1, overflow: "hidden" }}>

                {/* ── Left Sidebar: Chat + Files ──────── */}
                <div style={{
                    width: "var(--sidebar-left)",
                    minWidth: "var(--sidebar-left)",
                    borderRight: "1px solid var(--border-subtle)",
                    background: "var(--bg-surface)",
                    display: "flex",
                    flexDirection: "column",
                    minHeight: 0,
                }}>
                    <div style={{
                        flex: 1,
                        minHeight: 0,
                        padding: "var(--space-4)",
                        overflowY: "auto",
                    }}>
                        <ChatPanel projectId={activeProject.id} />
                    </div>
                    <div style={{
                        borderTop: "1px solid var(--border-subtle)",
                        maxHeight: "35%",
                        overflowY: "auto",
                        flexShrink: 0,
                    }}>
                        <ProjectFilesPanel projectId={activeProject.id} />
                    </div>
                </div>

                {/* ── Center: 3D Viewport ─────────────── */}
                <div style={{
                    flex: 1,
                    background: "#050508",
                    position: "relative",
                    overflow: "hidden",
                }}>
                    <Viewport3D projectId={activeProject.id} />
                </div>

                {/* ── Right Sidebar: Spec + Pipeline ──── */}
                <div style={{
                    width: "var(--sidebar-right)",
                    minWidth: "var(--sidebar-right)",
                    borderLeft: "1px solid var(--border-subtle)",
                    background: "var(--bg-surface)",
                    display: "flex",
                    flexDirection: "column",
                    minHeight: 0,
                }}>
                    {/* Tab switcher */}
                    <div style={{
                        display: "flex",
                        borderBottom: "1px solid var(--border-subtle)",
                        flexShrink: 0,
                    }}>
                        {(["spec", "pipeline"] as const).map((tab) => (
                            <button
                                key={tab}
                                onClick={() => setRightTab(tab)}
                                style={{
                                    flex: 1,
                                    padding: "var(--space-3) var(--space-4)",
                                    fontSize: 12,
                                    fontWeight: 600,
                                    color: rightTab === tab ? "var(--text-primary)" : "var(--text-muted)",
                                    borderBottom: rightTab === tab
                                        ? "2px solid var(--accent-blue)"
                                        : "2px solid transparent",
                                    transition: "all 0.15s ease",
                                }}
                            >
                                {tab === "spec" ? "Spec Sheet" : "Pipeline"}
                            </button>
                        ))}
                    </div>

                    {/* Tab content */}
                    <div style={{
                        flex: 1,
                        minHeight: 0,
                        overflowY: "auto",
                        padding: "var(--space-4)",
                    }}>
                        {rightTab === "spec" ? (
                            <>
                                <SelectedMeshInfo />

                                <SidebarSection label="Validation" defaultOpen={true}>
                                    <GateStatus
                                        projectId={activeProject.id}
                                        onGateChange={handleGateChange}
                                    />
                                </SidebarSection>

                                <SidebarSection
                                    label="Decisions"
                                    count={activeProject.decisions.length}
                                    defaultOpen={activeProject.decisions.length > 0}
                                >
                                    {activeProject.decisions.length === 0 ? (
                                        <div style={{
                                            fontSize: 12,
                                            color: "var(--text-muted)",
                                            padding: "var(--space-2) 0",
                                        }}>
                                            No decisions locked yet.
                                        </div>
                                    ) : (
                                        <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-1)" }}>
                                            {activeProject.decisions.map((d) => (
                                                <div key={d.id} style={{
                                                    padding: "var(--space-2) var(--space-3)",
                                                    background: "var(--bg-overlay)",
                                                    borderRadius: "var(--radius-sm)",
                                                    fontSize: 12,
                                                    borderLeft: d.status === "locked"
                                                        ? "3px solid var(--accent-green)"
                                                        : "3px solid var(--border-default)",
                                                }}>
                                                    <div style={{ color: "var(--text-primary)" }}>
                                                        {d.parameter}: <strong>{d.value}</strong>
                                                    </div>
                                                    {d.reason && (
                                                        <div style={{
                                                            color: "var(--text-muted)",
                                                            fontSize: 11,
                                                            marginTop: 2,
                                                        }}>
                                                            {d.reason}
                                                        </div>
                                                    )}
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </SidebarSection>

                                <SidebarSection
                                    label="Components"
                                    count={activeProject.components.length}
                                    defaultOpen={activeProject.components.length > 0}
                                >
                                    {activeProject.components.length === 0 ? (
                                        <div style={{
                                            fontSize: 12,
                                            color: "var(--text-muted)",
                                            padding: "var(--space-2) 0",
                                        }}>
                                            No components registered yet.
                                        </div>
                                    ) : (
                                        <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-1)" }}>
                                            {activeProject.components.map((c) => (
                                                <div key={c.id} style={{
                                                    padding: "var(--space-2) var(--space-3)",
                                                    background: "var(--bg-overlay)",
                                                    borderRadius: "var(--radius-sm)",
                                                    fontSize: 12,
                                                    display: "flex",
                                                    justifyContent: "space-between",
                                                    alignItems: "center",
                                                }}>
                                                    <span style={{ fontWeight: 500, color: "var(--text-primary)" }}>
                                                        {c.display_name}
                                                    </span>
                                                    <span style={{
                                                        fontSize: 10,
                                                        color: "var(--text-muted)",
                                                        fontFamily: "var(--font-mono)",
                                                    }}>
                                                        {c.id}
                                                    </span>
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </SidebarSection>
                            </>
                        ) : (
                            <PipelinePanel projectId={activeProject.id} />
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}

/* ── App Root ─────────────────────────────────────────── */

export default function App() {
    const screen = useProjectStore((s) => s.screen);
    return screen === "home" ? <HomeScreen /> : <Workspace />;
}
