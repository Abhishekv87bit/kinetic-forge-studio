// React hooks imported as needed

/** Preset camera view definitions */
export interface PresetView {
    label: string;
    /** Short label for compact display */
    shortLabel: string;
    position: [number, number, number];
}

const PRESET_VIEWS: PresetView[] = [
    { label: "Front", shortLabel: "F", position: [0, 0, 5] },
    { label: "Top", shortLabel: "T", position: [0, 5, 0] },
    { label: "Right", shortLabel: "R", position: [5, 0, 0] },
    { label: "Isometric", shortLabel: "Iso", position: [3, 3, 3] },
];

export type ViewMode = "solid" | "wireframe" | "xray";

interface ViewportToolbarProps {
    /** Callback when a preset view button is clicked */
    onSetView: (position: [number, number, number]) => void;
    /** Current render mode */
    viewMode: ViewMode;
    /** Callback when render mode changes */
    onSetViewMode: (mode: ViewMode) => void;
}

const buttonStyle: React.CSSProperties = {
    padding: "4px 10px",
    borderRadius: 4,
    border: "1px solid #444",
    background: "#1a1a2e",
    color: "#ccc",
    cursor: "pointer",
    fontSize: 12,
    fontWeight: 500,
    minWidth: 32,
    textAlign: "center",
};

const activeButtonStyle: React.CSSProperties = {
    ...buttonStyle,
    background: "#2a4a7e",
    borderColor: "#4a9eff",
    color: "#fff",
};

export default function ViewportToolbar({ onSetView, viewMode, onSetViewMode }: ViewportToolbarProps) {
    return (
        <div style={{
            position: "absolute",
            top: 8,
            left: 8,
            zIndex: 20,
            display: "flex",
            gap: 4,
            flexWrap: "wrap",
            maxWidth: 320,
        }}>
            {/* Preset view buttons */}
            <div style={{ display: "flex", gap: 4 }}>
                {PRESET_VIEWS.map((view) => (
                    <button
                        key={view.label}
                        onClick={() => onSetView(view.position)}
                        style={buttonStyle}
                        title={view.label}
                    >
                        {view.shortLabel}
                    </button>
                ))}
            </div>

            {/* Separator */}
            <div style={{ width: 1, background: "#444", margin: "0 4px" }} />

            {/* Render mode toggles */}
            <div style={{ display: "flex", gap: 4 }}>
                <button
                    onClick={() => onSetViewMode("solid")}
                    style={viewMode === "solid" ? activeButtonStyle : buttonStyle}
                    title="Solid view"
                >
                    Solid
                </button>
                <button
                    onClick={() => onSetViewMode("wireframe")}
                    style={viewMode === "wireframe" ? activeButtonStyle : buttonStyle}
                    title="Wireframe view"
                >
                    Wire
                </button>
                <button
                    onClick={() => onSetViewMode("xray")}
                    style={viewMode === "xray" ? activeButtonStyle : buttonStyle}
                    title="X-ray (transparent) view"
                >
                    X-ray
                </button>
            </div>
        </div>
    );
}
