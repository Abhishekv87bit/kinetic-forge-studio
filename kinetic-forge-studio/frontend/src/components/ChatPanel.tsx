import { useState, useRef, useEffect } from "react";
import { chatApi } from "../api/client";
import { useViewportStore } from "../stores/viewportStore";
import FileUpload from "./FileUpload";

interface Message {
    role: "user" | "assistant";
    content: string;
}

interface Props {
    projectId: string;
}

export default function ChatPanel({ projectId }: Props) {
    const [messages, setMessages] = useState<Message[]>([]);
    const [input, setInput] = useState("");
    const [loading, setLoading] = useState(false);
    const bottomRef = useRef<HTMLDivElement>(null);
    const { reloadGeometry } = useViewportStore();

    useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: "smooth" }); }, [messages]);

    const send = async () => {
        if (!input.trim() || loading) return;
        const text = input.trim();
        setInput("");
        setMessages((m) => [...m, { role: "user", content: text }]);
        setLoading(true);
        try {
            const data = await chatApi.send(projectId, text);
            setMessages((m) => [...m, { role: "assistant", content: data.message }]);
            // When spec is complete, backend registers components — reload viewport
            if (data.geometry_ready) {
                reloadGeometry();
            }
        } catch (err) {
            const detail = err instanceof Error ? err.message : "Unknown error";
            setMessages((m) => [...m, { role: "assistant", content: `Error: ${detail}` }]);
        }
        setLoading(false);
    };

    return (
        <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
            <h3 style={{ margin: "0 0 12px" }}>Chat</h3>
            <div style={{ flex: 1, overflowY: "auto", display: "flex", flexDirection: "column", gap: 8 }}>
                {messages.length === 0 && (
                    <p style={{ opacity: 0.4, fontSize: 13 }}>Describe what you want to design...</p>
                )}
                {messages.map((m, i) => (
                    <div key={`${m.role}-${i}`} style={{
                        padding: "8px 12px", borderRadius: 8, fontSize: 13,
                        background: m.role === "user" ? "#1a3a6e" : "#0d1b3e",
                        alignSelf: m.role === "user" ? "flex-end" : "flex-start",
                        maxWidth: "90%",
                    }}>
                        {m.content.split("\n").map((line, j, arr) => (
                            <span key={`line-${j}`}>{line}{j < arr.length - 1 && <br />}</span>
                        ))}
                    </div>
                ))}
                <div ref={bottomRef} />
            </div>
            <div style={{ display: "flex", gap: 8, marginTop: 8 }}>
                <input
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && send()}
                    placeholder="Type here..."
                    disabled={loading}
                    style={{ flex: 1, padding: "8px 12px", borderRadius: 4, border: "1px solid #333", background: "#0d1b3e", color: "#fff" }}
                />
                <button onClick={send} disabled={loading}
                    style={{ padding: "8px 12px", borderRadius: 4, background: "#4a9eff", color: "#fff", border: "none", cursor: "pointer" }}>
                    Send
                </button>
            </div>
            <div style={{ marginTop: 8 }}>
                <FileUpload projectId={projectId} onUpload={(result) => {
                    const a = result.analysis;
                    let analysisText: string;
                    if (typeof a === "string") {
                        analysisText = a;
                    } else if (a?.error) {
                        analysisText = `⚠️ Analysis failed: ${a.error}`;
                    } else if (a?.face_count !== undefined) {
                        // STL analysis
                        const bb = a.bounding_box;
                        analysisText = `📐 STL Analysis:\n• ${a.face_count.toLocaleString()} faces, ${a.vertex_count.toLocaleString()} vertices\n• Size: ${bb?.x_size?.toFixed(1)} × ${bb?.y_size?.toFixed(1)} × ${bb?.z_size?.toFixed(1)} mm\n• Volume: ${a.volume?.toFixed(1)} mm³\n• Watertight: ${a.is_watertight ? "✅ Yes" : "❌ No"}`;
                    } else if (a?.body_count !== undefined) {
                        // STEP analysis
                        analysisText = `📐 STEP Analysis:\n• ${a.body_count} bodies\n• ${a.total_faces} faces (${Object.entries(a.face_types || {}).map(([k,v]) => `${v} ${k}`).join(", ")})\n• Volume: ${a.volume?.toFixed(1)} mm³`;
                    } else if (a?.mechanism_type !== undefined) {
                        // Photo analysis
                        analysisText = `📸 Photo Analysis:\n• Mechanism: ${a.mechanism_type}\n• Motion: ${a.motion_type}\n• Components: ~${a.component_count}\n• Materials: ${a.materials?.join(", ") || "unknown"}`;
                    } else if (a?.cycle_period !== undefined) {
                        // Video analysis
                        analysisText = `🎬 Video Analysis:\n• Cycle: ${a.cycle_period}s\n• Tempo: ${a.tempo}\n• Motions: ${a.motion_types?.join(", ")}`;
                    } else {
                        analysisText = a?.message || JSON.stringify(a, null, 2);
                    }
                    setMessages((m) => [...m,
                        { role: "user", content: `Uploaded: ${result.filename}` },
                        { role: "assistant", content: analysisText },
                    ]);
                }} />
            </div>
        </div>
    );
}
