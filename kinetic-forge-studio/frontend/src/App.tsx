import { useState, useEffect } from "react";
import { fetchHealth } from "./api/client";

function App() {
    const [status, setStatus] = useState<string>("connecting...");

    useEffect(() => {
        fetchHealth()
            .then((data) => setStatus(`${data.status} v${data.version}`))
            .catch(() => setStatus("backend offline"));
    }, []);

    return (
        <div style={{ display: "flex", flexDirection: "column", height: "100vh" }}>
            <header style={{ padding: "8px 16px", borderBottom: "1px solid #333", background: "#1a1a2e", color: "#fff", display: "flex", justifyContent: "space-between" }}>
                <span>Kinetic Forge Studio</span>
                <span style={{ fontSize: "12px", opacity: 0.6 }}>{status}</span>
            </header>
            <div style={{ display: "flex", flex: 1, overflow: "hidden" }}>
                <div style={{ width: "280px", borderRight: "1px solid #333", padding: "16px", background: "#16213e", color: "#fff" }}>
                    <h3>Chat</h3>
                    <p style={{ opacity: 0.5 }}>Chat panel placeholder</p>
                </div>
                <div style={{ flex: 1, background: "#0a0a0a" }}>
                    <p style={{ color: "#666", padding: "16px" }}>3D Viewport placeholder</p>
                </div>
                <div style={{ width: "280px", borderLeft: "1px solid #333", padding: "16px", background: "#16213e", color: "#fff" }}>
                    <h3>Spec Sheet</h3>
                    <p style={{ opacity: 0.5 }}>Side panel placeholder</p>
                </div>
            </div>
            <div style={{ height: "48px", borderTop: "1px solid #333", padding: "8px 16px", background: "#1a1a2e", color: "#fff", display: "flex", alignItems: "center" }}>
                <span style={{ opacity: 0.5 }}>Timeline placeholder</span>
            </div>
        </div>
    );
}

export default App;
