import { useState, useCallback } from "react";
import { useProjectStore } from "./stores/projectStore";
import { useViewportStore } from "./stores/viewportStore";
import { exportApi } from "./api/client";
import HomeScreen from "./components/HomeScreen";
import Viewport3D from "./components/Viewport3D";
import ChatPanel from "./components/ChatPanel";
import GateStatus from "./components/GateStatus";

function SelectedMeshInfo() {
    const selectedMesh = useViewportStore((s) => s.selectedMesh);
    if (!selectedMesh) return null;

    const bb = selectedMesh.boundingBox;
    const size = bb
        ? [
            (bb.max[0] - bb.min[0]).toFixed(2),
            (bb.max[1] - bb.min[1]).toFixed(2),
            (bb.max[2] - bb.min[2]).toFixed(2),
        ]
        : null;

    return (
        <div style={{ marginTop: 16, padding: 12, background: "#0d2b5e", borderRadius: 6, border: "1px solid #2a5a9e" }}>
            <h4 style={{ margin: "0 0 8px", color: "#4a9eff" }}>Selected</h4>
            <div style={{ fontSize: 13, lineHeight: 1.6 }}>
                <div><strong>Name:</strong> {selectedMesh.name}</div>
                <div><strong>Vertices:</strong> {selectedMesh.vertexCount.toLocaleString()}</div>
                <div><strong>Faces:</strong> {selectedMesh.faceCount.toLocaleString()}</div>
                {size && (
                    <div><strong>Size:</strong> {size[0]} x {size[1]} x {size[2]}</div>
                )}
            </div>
        </div>
    );
}

const exportButtonEnabled: React.CSSProperties = {
    padding: "8px 20px",
    borderRadius: 4,
    border: "none",
    background: "#4a9eff",
    color: "#fff",
    cursor: "pointer",
    fontWeight: 600,
    fontSize: 13,
};

const exportButtonDisabled: React.CSSProperties = {
    ...exportButtonEnabled,
    background: "#333",
    color: "#666",
    cursor: "not-allowed",
    opacity: 0.5,
};

function Workspace() {
    const { activeProject, goHome } = useProjectStore();
    const [gatePassed, setGatePassed] = useState(false);

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

    return (
        <div style={{ display: "flex", flexDirection: "column", height: "100vh" }}>
            <header style={{ padding: "8px 16px", borderBottom: "1px solid #333", background: "#1a1a2e", color: "#fff", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <button onClick={goHome} style={{ background: "none", border: "none", color: "#4a9eff", cursor: "pointer" }}>&#8592; Home</button>
                    <span>{activeProject.name}</span>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <span style={{ fontSize: 12, opacity: 0.6 }}>Gate: {activeProject.gate}</span>
                    <button
                        onClick={handleExport}
                        disabled={!gatePassed}
                        style={gatePassed ? exportButtonEnabled : exportButtonDisabled}
                        title={gatePassed ? "Export STEP + STL package" : "Fix validation errors before exporting"}
                    >
                        Export
                    </button>
                </div>
            </header>
            <div style={{ display: "flex", flex: 1, overflow: "hidden" }}>
                <div style={{ width: 280, borderRight: "1px solid #333", padding: 16, background: "#16213e", color: "#fff", display: "flex", flexDirection: "column" }}>
                    <ChatPanel projectId={activeProject.id} />
                </div>
                <div style={{ flex: 1, background: "#0a0a0a" }}>
                    <Viewport3D projectId={activeProject.id} />
                </div>
                <div style={{ width: 280, borderLeft: "1px solid #333", padding: 16, background: "#16213e", color: "#fff", overflowY: "auto" }}>
                    <h3>Spec Sheet</h3>
                    <SelectedMeshInfo />

                    {/* Gate Status Panel */}
                    <h4 style={{ marginTop: 16, opacity: 0.7 }}>Validation</h4>
                    <GateStatus
                        projectId={activeProject.id}
                        onGateChange={handleGateChange}
                    />

                    <h4 style={{ marginTop: 16, opacity: 0.7 }}>Decisions ({activeProject.decisions.length})</h4>
                    {activeProject.decisions.map((d) => (
                        <div key={d.id} style={{ padding: 8, marginBottom: 4, background: "#0d1b3e", borderRadius: 4, fontSize: 13 }}>
                            <div>{d.parameter}: <strong>{d.value}</strong></div>
                            <div style={{ opacity: 0.5 }}>{d.status} {d.reason && `\u2014 ${d.reason}`}</div>
                        </div>
                    ))}
                    <h4 style={{ marginTop: 16, opacity: 0.7 }}>Components ({activeProject.components.length})</h4>
                    {activeProject.components.map((c) => (
                        <div key={c.id} style={{ padding: 8, marginBottom: 4, background: "#0d1b3e", borderRadius: 4, fontSize: 13 }}>
                            <strong>{c.display_name}</strong> <span style={{ opacity: 0.5 }}>({c.id})</span>
                        </div>
                    ))}
                </div>
            </div>
            <div style={{ height: 48, borderTop: "1px solid #333", padding: "8px 16px", background: "#1a1a2e", color: "#fff", display: "flex", alignItems: "center" }}>
                <span style={{ opacity: 0.5 }}>Timeline: no checkpoints yet</span>
            </div>
        </div>
    );
}

export default function App() {
    const screen = useProjectStore((s) => s.screen);
    return (
        <div style={{ height: "100vh", background: "#0f0f23" }}>
            {screen === "home" ? <HomeScreen /> : <Workspace />}
        </div>
    );
}
