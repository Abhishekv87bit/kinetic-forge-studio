import { useProjectStore } from "./stores/projectStore";
import HomeScreen from "./components/HomeScreen";
import Viewport3D from "./components/Viewport3D";

function Workspace() {
    const { activeProject, goHome } = useProjectStore();
    if (!activeProject) return null;

    return (
        <div style={{ display: "flex", flexDirection: "column", height: "100vh" }}>
            <header style={{ padding: "8px 16px", borderBottom: "1px solid #333", background: "#1a1a2e", color: "#fff", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <button onClick={goHome} style={{ background: "none", border: "none", color: "#4a9eff", cursor: "pointer" }}>&#8592; Home</button>
                    <span>{activeProject.name}</span>
                </div>
                <span style={{ fontSize: 12, opacity: 0.6 }}>Gate: {activeProject.gate}</span>
            </header>
            <div style={{ display: "flex", flex: 1, overflow: "hidden" }}>
                <div style={{ width: 280, borderRight: "1px solid #333", padding: 16, background: "#16213e", color: "#fff", overflowY: "auto" }}>
                    <h3>Chat</h3>
                    <p style={{ opacity: 0.5, fontSize: 14 }}>Type your design intent...</p>
                </div>
                <div style={{ flex: 1, background: "#0a0a0a" }}>
                    <Viewport3D />
                </div>
                <div style={{ width: 280, borderLeft: "1px solid #333", padding: 16, background: "#16213e", color: "#fff", overflowY: "auto" }}>
                    <h3>Spec Sheet</h3>
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
