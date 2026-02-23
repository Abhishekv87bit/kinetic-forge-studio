import { useRef } from "react";

interface Props {
    projectId: string;
    onUpload: (result: { filename: string; file_type: string; analysis: string }) => void;
}

export default function FileUpload({ projectId, onUpload }: Props) {
    const inputRef = useRef<HTMLInputElement>(null);

    const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        const form = new FormData();
        form.append("file", file);
        const res = await fetch(`http://localhost:8000/api/projects/${projectId}/upload`, {
            method: "POST",
            body: form,
        });
        const data = await res.json();
        onUpload(data);
        if (inputRef.current) inputRef.current.value = "";
    };

    return (
        <div>
            <input ref={inputRef} type="file" onChange={handleUpload}
                accept=".jpg,.jpeg,.png,.webp,.mp4,.mov,.step,.stp,.stl,.iges,.igs,.3mf"
                style={{ display: "none" }} />
            <button onClick={() => inputRef.current?.click()}
                style={{ width: "100%", padding: "6px", borderRadius: 4, background: "#333", color: "#aaa", border: "1px dashed #555", cursor: "pointer", fontSize: 12 }}>
                Upload photo, video, or 3D file
            </button>
        </div>
    );
}
