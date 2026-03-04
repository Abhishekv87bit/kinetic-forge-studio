import { useState, useEffect, useCallback } from "react";
import { projectsApi, gateApi, rule99Api } from "../api/client";
import { useViewportStore } from "../stores/viewportStore";

/* ── Types ─────────────────────────────────────────────── */

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
    // Rule 99 fields
    gate?: string;
    consultants_fired?: number;
    total_checks?: number;
    checks_passed?: number;
    checks_failed?: number;
    recommendations?: string[];
    [key: string]: unknown;
}

interface GateStatusData {
    passed: boolean;
    gate_level?: string;
    validators: ValidatorResult[];
    summary: string;
    consultant_report?: ConsultantReport;
}

interface ConsultantFinding {
    name: string;
    passed: boolean;
    findings: string[];
    recommendations: string[];
    checks_run: string[];
    checks_passed: string[];
    checks_failed: string[];
}

interface ConsultantReport {
    gate: string;
    passed: boolean;
    consultants_fired: ConsultantFinding[];
    recommendations: string[];
    library_suggestions: LibrarySuggestion[];
    total_checks: number;
    checks_passed: number;
    checks_failed: number;
}

interface LibrarySuggestion {
    name: string;
    pip: string | null;
    purpose: string;
    phase: string;
}

interface GateStatusProps {
    projectId: string;
    onGateChange?: (passed: boolean) => void;
}

/* ── Constants ─────────────────────────────────────────── */

const checkIcon = "\u2705";
const failIcon = "\u274C";
const pendingIcon = "\u23F3";

const GATE_LABELS: Record<string, string> = {
    design: "DESIGN",
    prototype: "PROTOTYPE",
    production: "PRODUCTION",
};

const GATE_COLORS: Record<string, string> = {
    design: "#4a9eff",
    prototype: "#f59e0b",
    production: "#10b981",
};

const GATE_TRANSITIONS: Record<string, { target: string; label: string }> = {
    design: { target: "prototype", label: "Lock Design" },
    prototype: { target: "production", label: "Lock Prototype" },
};

/* ── Styles ────────────────────────────────────────────── */

const containerStyle: React.CSSProperties = {
    borderRadius: 6,
    border: "1px solid var(--border-default)",
    overflow: "hidden",
};

const gateBadgeStyle: React.CSSProperties = {
    display: "inline-block",
    padding: "2px 10px",
    borderRadius: 12,
    fontSize: 11,
    fontWeight: 700,
    letterSpacing: 0.5,
};

const sectionHeaderStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    padding: "6px 12px",
    cursor: "pointer",
    fontSize: 12,
    fontWeight: 600,
    background: "var(--bg-base)",
    userSelect: "none",
};

const validatorRowStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: 8,
    padding: "4px 12px",
    fontSize: 13,
    lineHeight: 1.4,
};

const subCheckStyle: React.CSSProperties = {
    paddingLeft: 28,
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

const transitionButtonStyle: React.CSSProperties = {
    padding: "6px 14px",
    borderRadius: 4,
    border: "none",
    fontWeight: 600,
    fontSize: 12,
    cursor: "pointer",
    transition: "all 0.15s",
};

const consultantRowStyle: React.CSSProperties = {
    padding: "4px 12px",
    fontSize: 12,
    lineHeight: 1.5,
    cursor: "pointer",
    display: "flex",
    alignItems: "center",
    gap: 6,
};

const findingTextStyle: React.CSSProperties = {
    paddingLeft: 28,
    paddingRight: 12,
    fontSize: 11,
    opacity: 0.7,
    lineHeight: 1.4,
    paddingBottom: 2,
};

const recommendationStyle: React.CSSProperties = {
    padding: "4px 12px",
    fontSize: 11,
    color: "#f59e0b",
    lineHeight: 1.4,
};

const libraryStyle: React.CSSProperties = {
    padding: "3px 12px",
    fontSize: 11,
    color: "#a78bfa",
    lineHeight: 1.4,
};

/* ── Component ─────────────────────────────────────────── */

export default function GateStatus({ projectId, onGateChange }: GateStatusProps) {
    const [status, setStatus] = useState<GateStatusData | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [consultantReport, setConsultantReport] = useState<ConsultantReport | null>(null);
    const [rule99Loading, setRule99Loading] = useState(false);
    const [transitionLoading, setTransitionLoading] = useState(false);
    const [expandedSections, setExpandedSections] = useState<Set<string>>(
        new Set(["validators"])
    );
    const [expandedConsultants, setExpandedConsultants] = useState<Set<string>>(new Set());
    const geometryVersion = useViewportStore((s) => s.geometryVersion);

    const currentGate = status?.gate_level ?? "design";

    const fetchStatus = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const data = await projectsApi.getGateStatus(projectId);
            setStatus(data);
            onGateChange?.(data.passed);
            // If gate response includes consultant_report, store it
            if (data.consultant_report) {
                setConsultantReport(data.consultant_report);
            }
        } catch {
            setError("Failed to fetch validation status");
            onGateChange?.(false);
        }
        setLoading(false);
    }, [projectId, onGateChange]);

    const runRule99 = useCallback(async () => {
        setRule99Loading(true);
        try {
            const data = await rule99Api.run(projectId);
            setConsultantReport(data as ConsultantReport);
            // Auto-expand consultant section and any failures
            setExpandedSections((prev) => new Set([...prev, "consultants"]));
            const failed = new Set<string>();
            (data as ConsultantReport).consultants_fired.forEach((c: ConsultantFinding) => {
                if (!c.passed) failed.add(c.name);
            });
            setExpandedConsultants(failed);
        } catch {
            // Silently handle — not critical
        }
        setRule99Loading(false);
    }, [projectId]);

    const advanceGate = useCallback(async () => {
        const transition = GATE_TRANSITIONS[currentGate];
        if (!transition) return;
        setTransitionLoading(true);
        try {
            await gateApi.advanceGate(projectId, transition.target);
            await fetchStatus();
        } catch {
            setError("Gate transition failed");
        }
        setTransitionLoading(false);
    }, [projectId, currentGate, fetchStatus]);

    const toggleSection = (section: string) => {
        setExpandedSections((prev) => {
            const next = new Set(prev);
            if (next.has(section)) next.delete(section);
            else next.add(section);
            return next;
        });
    };

    const toggleConsultant = (name: string) => {
        setExpandedConsultants((prev) => {
            const next = new Set(prev);
            if (next.has(name)) next.delete(name);
            else next.add(name);
            return next;
        });
    };

    // Auto-refresh when geometry changes
    useEffect(() => {
        fetchStatus();
    }, [fetchStatus, geometryVersion]);

    /* ── Loading state ───────────────────────────── */
    if (loading && !status) {
        return (
            <div style={{ ...containerStyle, padding: "12px 16px", background: "var(--bg-overlay)" }}>
                <div style={{ fontSize: 13, opacity: 0.5 }}>
                    {pendingIcon} Running validators...
                </div>
            </div>
        );
    }

    if (error && !status) {
        return (
            <div style={{ ...containerStyle, padding: "12px 16px", background: "var(--bg-overlay)", borderColor: "var(--accent-red)" }}>
                <div style={{ fontSize: 13, color: "#ff6b6b" }}>{error}</div>
                <button onClick={fetchStatus} style={{ ...refreshButtonStyle, marginTop: 8 }}>
                    Retry
                </button>
            </div>
        );
    }

    if (!status) return null;

    const gateColor = GATE_COLORS[currentGate] ?? "#4a9eff";
    const gateLabel = GATE_LABELS[currentGate] ?? currentGate.toUpperCase();
    const overallIcon = status.passed ? checkIcon : failIcon;
    const overallColor = status.passed ? "#4ade80" : "#ff6b6b";
    const transition = GATE_TRANSITIONS[currentGate];

    /* ── Render ───────────────────────────────────── */
    return (
        <div style={{ ...containerStyle, background: "var(--bg-overlay)" }}>
            {/* Gate Level Badge + Overall Status */}
            <div style={{
                display: "flex", justifyContent: "space-between", alignItems: "center",
                padding: "10px 12px", borderBottom: "1px solid var(--border-default)",
            }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <span style={{
                        ...gateBadgeStyle,
                        background: `${gateColor}20`,
                        color: gateColor,
                        border: `1px solid ${gateColor}40`,
                    }}>
                        {gateLabel}
                    </span>
                    <span style={{ fontWeight: 600, color: overallColor, fontSize: 13 }}>
                        {overallIcon} {status.passed ? "PASS" : "BLOCKED"}
                    </span>
                </div>
                <button
                    onClick={fetchStatus}
                    style={refreshButtonStyle}
                    title="Re-run validators"
                    disabled={loading}
                >
                    {loading ? "..." : "\u21BB"}
                </button>
            </div>

            {/* Validator Results Section */}
            <div>
                <div
                    style={sectionHeaderStyle}
                    onClick={() => toggleSection("validators")}
                >
                    <span>
                        {expandedSections.has("validators") ? "\u25BC" : "\u25B6"}{" "}
                        Validators ({status.validators.length})
                    </span>
                    <span style={{ fontSize: 11, opacity: 0.5 }}>
                        {status.validators.filter((v) => v.passed).length}/{status.validators.length} pass
                    </span>
                </div>

                {expandedSections.has("validators") && (
                    <div style={{ paddingBottom: 4 }}>
                        {status.validators.length === 0 ? (
                            <div style={{ padding: "8px 12px", fontSize: 12, opacity: 0.5 }}>
                                No components to validate yet.
                            </div>
                        ) : (
                            status.validators.map((v, i) => (
                                <div key={`${v.validator}-${v.mesh_name ?? i}`}>
                                    <div style={validatorRowStyle}>
                                        <span>{v.passed ? checkIcon : failIcon}</span>
                                        <span style={{ color: v.passed ? "#ccc" : "#ff6b6b" }}>
                                            {formatValidatorName(v)}
                                        </span>
                                    </div>
                                    {v.checks?.map((check) => (
                                        <div key={check.name} style={subCheckStyle}>
                                            {check.passed ? checkIcon : failIcon}{" "}
                                            {check.name}: {check.message}
                                        </div>
                                    ))}
                                    {v.validator === "collision" && !v.passed && v.collisions && (
                                        <div style={subCheckStyle}>
                                            {(v.collisions as Array<{ mesh_a: string; mesh_b: string }>).map((c) => (
                                                <div key={`${c.mesh_a}-${c.mesh_b}`}>
                                                    {failIcon} {c.mesh_a} overlaps {c.mesh_b}
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                    {/* Rule 99 summary in validator list */}
                                    {v.validator === "rule99" && (
                                        <div style={subCheckStyle}>
                                            {v.consultants_fired ?? 0} consultants fired,{" "}
                                            {v.checks_passed ?? 0}/{v.total_checks ?? 0} checks passed
                                            {v.recommendations && (v.recommendations as string[]).length > 0 && (
                                                <div style={{ color: "#f59e0b", marginTop: 2 }}>
                                                    {(v.recommendations as string[]).length} recommendation(s)
                                                </div>
                                            )}
                                        </div>
                                    )}
                                </div>
                            ))
                        )}
                    </div>
                )}
            </div>

            {/* Rule 99 Consultant Findings Section */}
            <div>
                <div
                    style={{
                        ...sectionHeaderStyle,
                        borderTop: "1px solid var(--border-default)",
                    }}
                    onClick={() => toggleSection("consultants")}
                >
                    <span>
                        {expandedSections.has("consultants") ? "\u25BC" : "\u25B6"}{" "}
                        Rule 99 Consultants
                        {consultantReport && (
                            <span style={{ fontWeight: 400, opacity: 0.6 }}>
                                {" "}({consultantReport.consultants_fired.length})
                            </span>
                        )}
                    </span>
                    <button
                        onClick={(e) => {
                            e.stopPropagation();
                            runRule99();
                        }}
                        disabled={rule99Loading}
                        style={{
                            ...refreshButtonStyle,
                            color: "#a78bfa",
                            borderColor: "#a78bfa40",
                        }}
                    >
                        {rule99Loading ? "..." : "Run Rule 99"}
                    </button>
                </div>

                {expandedSections.has("consultants") && (
                    <div style={{ paddingBottom: 4 }}>
                        {!consultantReport ? (
                            <div style={{ padding: "8px 12px", fontSize: 12, opacity: 0.5 }}>
                                Click "Run Rule 99" to check methodology compliance.
                            </div>
                        ) : (
                            <>
                                {/* Per-consultant findings */}
                                {consultantReport.consultants_fired.map((c) => (
                                    <div key={c.name}>
                                        <div
                                            style={{
                                                ...consultantRowStyle,
                                                color: c.passed ? "#ccc" : "#ff6b6b",
                                            }}
                                            onClick={() => toggleConsultant(c.name)}
                                        >
                                            <span>{c.passed ? checkIcon : failIcon}</span>
                                            <span style={{ flex: 1, fontWeight: 500 }}>{c.name}</span>
                                            <span style={{ opacity: 0.4, fontSize: 10 }}>
                                                {c.checks_passed.length}/{c.checks_run.length}
                                            </span>
                                            <span style={{ opacity: 0.3, fontSize: 10 }}>
                                                {expandedConsultants.has(c.name) ? "\u25BC" : "\u25B6"}
                                            </span>
                                        </div>
                                        {expandedConsultants.has(c.name) && (
                                            <>
                                                {c.findings.map((f, i) => (
                                                    <div key={i} style={findingTextStyle}>{f}</div>
                                                ))}
                                                {c.recommendations.map((r, i) => (
                                                    <div key={`rec-${i}`} style={recommendationStyle}>
                                                        \u26A0\uFE0F {r}
                                                    </div>
                                                ))}
                                                {c.checks_failed.length > 0 && (
                                                    <div style={{ ...findingTextStyle, color: "#ff6b6b" }}>
                                                        Failed: {c.checks_failed.join(", ")}
                                                    </div>
                                                )}
                                            </>
                                        )}
                                    </div>
                                ))}

                                {/* Library Suggestions */}
                                {consultantReport.library_suggestions.length > 0 && (
                                    <>
                                        <div style={{
                                            ...sectionHeaderStyle,
                                            fontSize: 11,
                                            padding: "4px 12px",
                                            background: "transparent",
                                        }}>
                                            Suggested Libraries
                                        </div>
                                        {consultantReport.library_suggestions.slice(0, 5).map((lib) => (
                                            <div key={lib.name} style={libraryStyle}>
                                                <strong>{lib.name}</strong>
                                                {lib.pip && <span style={{ opacity: 0.5 }}> ({lib.pip})</span>}
                                                {" "}\u2014 {lib.purpose}
                                            </div>
                                        ))}
                                    </>
                                )}

                                {/* Overall consultant summary */}
                                <div style={{
                                    padding: "6px 12px",
                                    fontSize: 11,
                                    opacity: 0.6,
                                    borderTop: "1px solid var(--border-default)",
                                }}>
                                    {consultantReport.checks_passed}/{consultantReport.total_checks} checks passed
                                    {consultantReport.recommendations.length > 0 && (
                                        <span style={{ color: "#f59e0b" }}>
                                            {" "}\u2022 {consultantReport.recommendations.length} recommendation(s)
                                        </span>
                                    )}
                                </div>
                            </>
                        )}
                    </div>
                )}
            </div>

            {/* Gate Transition Button */}
            {transition && (
                <div style={{
                    padding: "8px 12px",
                    borderTop: "1px solid var(--border-default)",
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                }}>
                    <span style={{ fontSize: 11, opacity: 0.5 }}>
                        Advance to {GATE_LABELS[transition.target] ?? transition.target}
                    </span>
                    <button
                        onClick={advanceGate}
                        disabled={!status.passed || transitionLoading}
                        style={{
                            ...transitionButtonStyle,
                            background: status.passed ? gateColor : "#333",
                            color: status.passed ? "#fff" : "#666",
                            cursor: status.passed ? "pointer" : "not-allowed",
                        }}
                        title={
                            status.passed
                                ? `Run gate checks and advance to ${transition.target}`
                                : "Fix all validation errors before advancing"
                        }
                    >
                        {transitionLoading ? "Checking..." : transition.label}
                    </button>
                </div>
            )}

            {/* Summary footer */}
            <div style={{
                padding: "6px 12px",
                borderTop: "1px solid var(--border-default)",
                fontSize: 11,
                opacity: 0.5,
            }}>
                {status.summary}
            </div>
        </div>
    );
}

/* ── Helpers ───────────────────────────────────────────── */

function formatValidatorName(v: ValidatorResult): string {
    switch (v.validator) {
        case "collision": return "Collision Check";
        case "manufacturability": return `Mfg${v.mesh_name ? `: ${v.mesh_name}` : ""}`;
        case "geometry": return `Geometry${v.file ? `: ${v.file}` : ""}`;
        case "consistency": return "Consistency Audit";
        case "tolerance": return "Tolerance Check";
        case "rule99": return "Rule 99 Consultants";
        default: return v.validator;
    }
}
