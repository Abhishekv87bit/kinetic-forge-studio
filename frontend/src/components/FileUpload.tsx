import { useRef } from "react";
import { uploadApi } from "../api/client";

interface AnalysisResult {
    message?: string;
    error?: string;
    [key: string]: unknown;
}

interface Props {
    projectId: string;
    onUpload: (result: { filename: string; file_type: string; analysis: AnalysisResult | string }) => void;
}

export default function FileUpload({ projectId, onUpload }: Props) {
    const inputRef = useRef<HTMLInputElement>(null);

    const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        try {
            const data = await uploadApi.upload(projectId, file);
            onUpload(data);
        } catch (err) {
            onUpload({
                filename: file.name,
                file_type: "unknown",
                analysis: `Upload failed: ${err instanceof Error ? err.message : "unknown error"}`,
            });
        }
        if (inputRef.current) inputRef.current.value = "";
    };

    return (
        <div>
            <input
                ref={inputRef}
                type="file"
                onChange={handleUpload}
                accept=".jpg,.jpeg,.png,.webp,.mp4,.mov,.step,.stp,.stl,.iges,.igs,.3mf"
                style={{ display: "none" }}
            />
            <button
                onClick={() => inputRef.current?.click()}
                style={{
                    width: "100%",
                    padding: "6px",
                    borderRadius: "var(--radius-sm)",
                    background: "transparent",
                    color: "var(--text-muted)",
                    border: "1px dashed var(--border-default)",
                    fontSize: 11,
                    transition: "all 0.15s ease",
                }}
                onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = "var(--accent-blue)";
                    e.currentTarget.style.color = "var(--accent-blue)";
                }}
                onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = "var(--border-default)";
                    e.currentTarget.style.color = "var(--text-muted)";
                }}
            >
                Upload photo, video, or 3D file
            </button>
        </div>
    );
}
