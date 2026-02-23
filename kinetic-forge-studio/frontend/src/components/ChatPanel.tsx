import { useState, useRef, useEffect } from "react";
import { chatApi } from "../api/client";
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
        } catch {
            setMessages((m) => [...m, { role: "assistant", content: "Error connecting to backend." }]);
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
                    <div key={i} style={{
                        padding: "8px 12px", borderRadius: 8, fontSize: 13,
                        background: m.role === "user" ? "#1a3a6e" : "#0d1b3e",
                        alignSelf: m.role === "user" ? "flex-end" : "flex-start",
                        maxWidth: "90%",
                    }}>
                        {m.content}
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
                    setMessages((m) => [...m,
                        { role: "user", content: `Uploaded: ${result.filename}` },
                        { role: "assistant", content: typeof result.analysis === "string"
                            ? result.analysis
                            : result.analysis?.message || JSON.stringify(result.analysis) },
                    ]);
                }} />
            </div>
        </div>
    );
}
