import { useState, useEffect, useCallback } from "react";
import { projectsApi } from "../api/client";

interface ValidatorCheck {
    name: string;
    passed: boolean;
    message: string;
    [key: string]: unknown;
}

interface ValidatorResult {
    validator: string;
    passed: boolean;
    message: string;
    mesh_name?: string;
    checks?: ValidatorCheck[];
    collisions?: unknown[];
    [key: string]: unknown;
}

interface GateStatusData {
    passed: boolean;
    validators: ValidatorResult[];
    summary: string;
}

interface GateStatusProps {
    projectId: string;
    /** Called whenever gate status changes, so parent can enable/disable export */
    onGateChange?: (passed: boolean) => void;
}

const checkIcon = "\u2705";  // green checkmark
const failIcon = "\u274C";   // red X
const pendingIcon = "\u23F3"; // hourglass

const containerStyle: React.CSSProperties = {
    padding: "12px 16px",
    background: "#0d1b3e",
    borderRadius: 6,
    border: "1px solid #1a3a6e",
};

const headerStyle: React.CSSProperties = {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 8,
};

const validatorRowStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: 8,
    padding: "4px 0",
    fontSize: 13,
    lineHeight: 1.4,
};

const subCheckStyle: React.CSSProperties = {
    paddingLeft: 24,
    fontSize: 12,
    opacity: 0.8,
    lineHeight: 1.4,
};

const refreshButtonStyle: React.CSSProperties = {
    background: "none",
    border: "1px solid #444",
    borderRadius: 4,
    color: "#aaa",
    cursor: "pointer",
    padding: "2px 8px",
    fontSize: 11,
};

export default function GateStatus({ projectId, onGateChange }: GateStatusProps) {
    const [status, setStatus] = useState<GateStatusData | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const fetchStatus = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const data = await projectsApi.getGateStatus(projectId);
            setStatus(data);
            onGateChange?.(data.passed);
        } catch (err) {
            setError("Failed to fetch validation status");
            onGateChange?.(false);
        }
        setLoading(false);
    }, [projectId, onGateChange]);

    useEffect(() => {
        fetchStatus();
    }, [fetchStatus]);

    if (loading && !status) {
        return (
            <div style={containerStyle}>
                <div style={{ fontSize: 13, opacity: 0.5 }}>
                    {pendingIcon} Running validators...
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div style={{ ...containerStyle, borderColor: "#6e1a1a" }}>
                <div style={{ fontSize: 13, color: "#ff6b6b" }}>{error}</div>
                <button onClick={fetchStatus} style={{ ...refreshButtonStyle, marginTop: 8 }}>
                    Retry
                </button>
            </div>
        );
    }

    if (!status) return null;

    const overallIcon = status.passed ? checkIcon : failIcon;
    const overallColor = status.passed ? "#4ade80" : "#ff6b6b";

    return (
        <div style={containerStyle}>
            <div style={headerStyle}>
                <span style={{ fontWeight: 600, color: overallColor, fontSize: 14 }}>
                    {overallIcon} Gate: {status.passed ? "PASS" : "BLOCKED"}
                </span>
                <button
                    onClick={fetchStatus}
                    style={refreshButtonStyle}
                    title="Re-run validators"
                    disabled={loading}
                >
                    {loading ? "..." : "Refresh"}
                </button>
            </div>

            {status.validators.length === 0 ? (
                <div style={{ fontSize: 12, opacity: 0.5 }}>
                    No components to validate yet.
                </div>
            ) : (
                <div>
                    {status.validators.map((v, i) => (
                        <div key={`${v.validator}-${v.mesh_name ?? i}`}>
                            <div style={validatorRowStyle}>
                                <span>{v.passed ? checkIcon : failIcon}</span>
                                <span style={{ color: v.passed ? "#ccc" : "#ff6b6b" }}>
                                    {v.validator === "collision"
                                        ? "Collision Check"
                                        : `Manufacturability${v.mesh_name ? `: ${v.mesh_name}` : ""}`}
                                </span>
                            </div>
                            {/* Show sub-checks for manufacturability */}
                            {v.checks && v.checks.map((check) => (
                                <div key={check.name} style={subCheckStyle}>
                                    {check.passed ? checkIcon : failIcon}{" "}
                                    {check.name}: {check.message}
                                </div>
                            ))}
                            {/* Show collision details */}
                            {v.validator === "collision" && !v.passed && v.collisions && (
                                <div style={subCheckStyle}>
                                    {Array.isArray(v.collisions) && (v.collisions as Array<{mesh_a: string; mesh_b: string}>).map((c) => (
                                        <div key={`${c.mesh_a}-${c.mesh_b}`}>
                                            {failIcon} {c.mesh_a} overlaps {c.mesh_b}
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            )}

            <div style={{
                marginTop: 8,
                paddingTop: 8,
                borderTop: "1px solid #1a3a6e",
                fontSize: 12,
                opacity: 0.6,
            }}>
                {status.summary}
            </div>
        </div>
    );
}
