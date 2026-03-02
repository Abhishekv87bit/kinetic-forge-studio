import { useState, useEffect, useCallback } from "react";
import { viewerApi, projectsApi } from "../api/client";

interface ScadFile {
    name: string;
    path: string;
    size_bytes: number;
    is_assembly: boolean;
    is_params: boolean;
}

interface ScadComponent {
    name: string;
    flag: string;
    color: number[];
    priority: number;
}

interface ProjectFiles {
    project_id: string;
    project_name: string;
    scad_dir: string | null;
    scad_files: ScadFile[];
    step_files: { name: string; path: string; size_bytes: number }[];
    stl_files: { name: string; path: string; size_bytes: number }[];
    scad_components?: ScadComponent[];
}

function formatSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function rgbToHex(color: number[]): string {
    const r = Math.round(color[0] * 255);
    const g = Math.round(color[1] * 255);
    const b = Math.round(color[2] * 255);
    return `#${r.toString(16).padStart(2, "0")}${g.toString(16).padStart(2, "0")}${b.toString(16).padStart(2, "0")}`;
}

const priorityLabels: Record<number, string> = {
    1: "Core",
    2: "Structure",
    3: "Hardware",
    4: "Drive",
};

const btnStyle: React.CSSProperties = {
    padding: "6px 14px",
    borderRadius: 4,
    border: "1px solid #4a9eff",
    background: "transparent",
    color: "#4a9eff",
    cursor: "pointer",
    fontSize: 12,
    fontWeight: 600,
};

const btnPrimaryStyle: React.CSSProperties = {
    ...btnStyle,
    background: "#4a9eff",
    color: "#fff",
};

export default function ProjectFilesPanel({ projectId }: { projectId: string }) {
    const [files, setFiles] = useState<ProjectFiles | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [launching, setLaunching] = useState<string | null>(null);
    const [linkingScad, setLinkingScad] = useState(false);
    const [scadDirInput, setScadDirInput] = useState("");

    const loadFiles = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const data = await viewerApi.listFiles(projectId);
            setFiles(data);
        } catch (err) {
            setError(err instanceof Error ? err.message : "Failed to load files");
        } finally {
            setLoading(false);
        }
    }, [projectId]);

    useEffect(() => {
        loadFiles();
    }, [loadFiles]);

    const handleOpen = useCallback(async (filePath?: string) => {
        const label = filePath?.split(/[\\/]/).pop() ?? "assembly";
        setLaunching(label);
        try {
            await viewerApi.openFile(projectId, filePath);
        } catch (err) {
            alert(`Failed to open: ${err instanceof Error ? err.message : "unknown"}`);
        } finally {
            setTimeout(() => setLaunching(null), 1500);
        }
    }, [projectId]);

    const handleLinkScadDir = useCallback(async () => {
        if (!scadDirInput.trim()) return;
        try {
            await projectsApi.setScadDir(projectId, scadDirInput.trim());
            setLinkingScad(false);
            setScadDirInput("");
            loadFiles();
        } catch (err) {
            alert(`Failed: ${err instanceof Error ? err.message : "unknown"}`);
        }
    }, [projectId, scadDirInput, loadFiles]);

    if (loading) {
        return (
            <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%", color: "#666" }}>
                Loading project files...
            </div>
        );
    }

    if (error) {
        return (
            <div style={{ padding: 24, color: "#ff6b6b" }}>
                <p>{error}</p>
                <button onClick={loadFiles} style={btnStyle}>Retry</button>
            </div>
        );
    }

    if (!files) return null;

    return (
        <div style={{ padding: 24, overflowY: "auto", height: "100%", color: "#ccc" }}>
            {/* OpenSCAD Source Section */}
            {files.scad_dir ? (
                <>
                    <div style={{ marginBottom: 20 }}>
                        <h3 style={{ margin: "0 0 8px", color: "#fff" }}>OpenSCAD Source</h3>
                        <div style={{ fontSize: 12, opacity: 0.5, marginBottom: 12, wordBreak: "break-all" }}>
                            {files.scad_dir}
                        </div>
                        <button
                            onClick={() => handleOpen()}
                            style={btnPrimaryStyle}
                            disabled={launching !== null}
                        >
                            {launching === "assembly" ? "Launching..." : "Open Assembly in OpenSCAD"}
                        </button>
                    </div>

                    {/* Component list with colors */}
                    {files.scad_components && files.scad_components.length > 0 && (
                        <div style={{ marginBottom: 20 }}>
                            <h4 style={{ margin: "0 0 8px", opacity: 0.7 }}>
                                Components ({files.scad_components.length})
                            </h4>
                            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 4 }}>
                                {files.scad_components.map((c) => (
                                    <div
                                        key={c.name}
                                        style={{
                                            padding: "6px 10px",
                                            background: "#0d1b3e",
                                            borderRadius: 4,
                                            fontSize: 12,
                                            display: "flex",
                                            alignItems: "center",
                                            gap: 8,
                                            borderLeft: `3px solid ${rgbToHex(c.color)}`,
                                        }}
                                    >
                                        <span style={{ flex: 1 }}>{c.name.replace(/_/g, " ")}</span>
                                        <span style={{ opacity: 0.4, fontSize: 10 }}>
                                            {priorityLabels[c.priority] ?? ""}
                                        </span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* File tree */}
                    {files.scad_files.length > 0 && (
                        <div style={{ marginBottom: 20 }}>
                            <h4 style={{ margin: "0 0 8px", opacity: 0.7 }}>
                                Files ({files.scad_files.length})
                            </h4>
                            {files.scad_files.map((f) => (
                                <div
                                    key={f.path}
                                    style={{
                                        padding: "4px 8px",
                                        fontSize: 12,
                                        display: "flex",
                                        alignItems: "center",
                                        justifyContent: "space-between",
                                        borderBottom: "1px solid #1a2a4e",
                                        opacity: f.is_assembly || f.is_params ? 1 : 0.7,
                                    }}
                                >
                                    <span style={{ fontFamily: "monospace" }}>
                                        {f.is_assembly && <strong style={{ color: "#4a9eff" }}>{f.name}</strong>}
                                        {f.is_params && <strong style={{ color: "#ffa64a" }}>{f.name}</strong>}
                                        {!f.is_assembly && !f.is_params && f.name}
                                    </span>
                                    <span style={{ display: "flex", alignItems: "center", gap: 8 }}>
                                        <span style={{ opacity: 0.4 }}>{formatSize(f.size_bytes)}</span>
                                        <button
                                            onClick={() => handleOpen(f.path)}
                                            style={{
                                                ...btnStyle,
                                                padding: "2px 8px",
                                                fontSize: 11,
                                            }}
                                            disabled={launching !== null}
                                        >
                                            {launching === f.name ? "..." : "Open"}
                                        </button>
                                    </span>
                                </div>
                            ))}
                        </div>
                    )}
                </>
            ) : (
                /* No scad_dir linked — show setup prompt */
                <div style={{ marginBottom: 20 }}>
                    <h3 style={{ margin: "0 0 8px", color: "#fff" }}>Link OpenSCAD Project</h3>
                    <p style={{ fontSize: 13, opacity: 0.6, marginBottom: 12 }}>
                        Point this project to your OpenSCAD source folder (must contain assembly.scad).
                    </p>
                    {linkingScad ? (
                        <div style={{ display: "flex", gap: 8 }}>
                            <input
                                type="text"
                                value={scadDirInput}
                                onChange={(e) => setScadDirInput(e.target.value)}
                                placeholder="D:\path\to\openscad\project"
                                style={{
                                    flex: 1,
                                    padding: "6px 10px",
                                    background: "#0d1b3e",
                                    border: "1px solid #2a5a9e",
                                    borderRadius: 4,
                                    color: "#fff",
                                    fontSize: 12,
                                    fontFamily: "monospace",
                                }}
                            />
                            <button onClick={handleLinkScadDir} style={btnPrimaryStyle}>Link</button>
                            <button onClick={() => setLinkingScad(false)} style={btnStyle}>Cancel</button>
                        </div>
                    ) : (
                        <button onClick={() => setLinkingScad(true)} style={btnPrimaryStyle}>
                            Set OpenSCAD Directory
                        </button>
                    )}
                </div>
            )}

            {/* STEP files */}
            {files.step_files.length > 0 && (
                <div style={{ marginBottom: 20 }}>
                    <h4 style={{ margin: "0 0 8px", opacity: 0.7 }}>
                        STEP Files ({files.step_files.length})
                    </h4>
                    {files.step_files.map((f) => (
                        <div
                            key={f.path}
                            style={{
                                padding: "4px 8px",
                                fontSize: 12,
                                display: "flex",
                                justifyContent: "space-between",
                                borderBottom: "1px solid #1a2a4e",
                            }}
                        >
                            <span>{f.name}</span>
                            <span style={{ display: "flex", gap: 8, alignItems: "center" }}>
                                <span style={{ opacity: 0.4 }}>{formatSize(f.size_bytes)}</span>
                                <button
                                    onClick={() => handleOpen(f.path)}
                                    style={{ ...btnStyle, padding: "2px 8px", fontSize: 11 }}
                                >
                                    Open
                                </button>
                            </span>
                        </div>
                    ))}
                </div>
            )}

            {/* STL files */}
            {files.stl_files.length > 0 && (
                <div style={{ marginBottom: 20 }}>
                    <h4 style={{ margin: "0 0 8px", opacity: 0.7 }}>
                        STL Files ({files.stl_files.length})
                    </h4>
                    {files.stl_files.map((f) => (
                        <div
                            key={f.path}
                            style={{
                                padding: "4px 8px",
                                fontSize: 12,
                                display: "flex",
                                justifyContent: "space-between",
                                borderBottom: "1px solid #1a2a4e",
                            }}
                        >
                            <span>{f.name}</span>
                            <span style={{ display: "flex", gap: 8, alignItems: "center" }}>
                                <span style={{ opacity: 0.4 }}>{formatSize(f.size_bytes)}</span>
                                <button
                                    onClick={() => handleOpen(f.path)}
                                    style={{ ...btnStyle, padding: "2px 8px", fontSize: 11 }}
                                >
                                    Open
                                </button>
                            </span>
                        </div>
                    ))}
                </div>
            )}

            {/* Refresh button */}
            <div style={{ marginTop: 16, paddingTop: 16, borderTop: "1px solid #1a2a4e" }}>
                <button onClick={loadFiles} style={btnStyle}>
                    Refresh File List
                </button>
            </div>
        </div>
    );
}
