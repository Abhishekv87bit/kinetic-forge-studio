import { useState, useCallback } from "react";
import { rule500Api } from "../api/client";

/* ── Types ─────────────────────────────────────────────── */

interface StepResult {
    step: number;
    name: string;
    phase: string;
    passed: boolean;
    critical: boolean;
    findings: string[];
    duration_ms: number;
}

interface PipelineReport {
    steps: StepResult[];
    passed: boolean;
    stopped_at: number | null;
    summary: string;
    gate_level: string;
}

interface Props {
    projectId: string;
}

/* ── Constants ─────────────────────────────────────────── */

const PHASES = [
    { key: "intake", label: "Intake", steps: "1-5", color: "#4a9eff" },
    { key: "design", label: "Design Gate", steps: "6-11", color: "#a78bfa" },
    { key: "prototype", label: "Prototype Gate", steps: "12-19", color: "#f59e0b" },
    { key: "production", label: "Production Gate", steps: "20-28", color: "#ef4444" },
    { key: "finalize", label: "Finalize", steps: "29-32", color: "#10b981" },
] as const;

const ICON_PASS = "\u2705";
const ICON_FAIL = "\u274C";
const ICON_PENDING = "\u2B1C";
const ICON_RUNNING = "\u23F3";
const ICON_SKIP = "\u23ED\uFE0F";

/* ── Styles ────────────────────────────────────────────── */

const panelStyle: React.CSSProperties = {
    background: "var(--bg-overlay)",
    borderRadius: 8,
    border: "1px solid var(--border-default)",
    overflow: "hidden",
};

const headerBarStyle: React.CSSProperties = {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "12px 16px",
    borderBottom: "1px solid var(--border-default)",
};

const runButtonStyle: React.CSSProperties = {
    padding: "6px 16px",
    borderRadius: 4,
    border: "none",
    background: "#4a9eff",
    color: "#fff",
    cursor: "pointer",
    fontWeight: 600,
    fontSize: 12,
};

const runButtonDisabledStyle: React.CSSProperties = {
    ...runButtonStyle,
    background: "#333",
    color: "#666",
    cursor: "not-allowed",
};

const phaseHeaderStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    padding: "8px 16px",
    cursor: "pointer",
    fontSize: 13,
    fontWeight: 600,
    borderTop: "1px solid var(--border-default)",
    userSelect: "none",
};

const stepRowStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "flex-start",
    gap: 8,
    padding: "4px 16px 4px 32px",
    fontSize: 12,
    lineHeight: 1.5,
};

const findingsStyle: React.CSSProperties = {
    paddingLeft: 48,
    paddingRight: 16,
    paddingBottom: 4,
    fontSize: 11,
    opacity: 0.7,
    lineHeight: 1.4,
};

/* ── Component ─────────────────────────────────────────── */

export default function PipelinePanel({ projectId }: Props) {
    const [report, setReport] = useState<PipelineReport | null>(null);
    const [running, setRunning] = useState(false);
    const [expandedPhases, setExpandedPhases] = useState<Set<string>>(new Set());
    const [expandedSteps, setExpandedSteps] = useState<Set<number>>(new Set());
    const [selectedGate, setSelectedGate] = useState("design");
    const [error, setError] = useState<string | null>(null);

    const runPipeline = useCallback(async () => {
        setRunning(true);
        setError(null);
        try {
            const data = await rule500Api.run(projectId, selectedGate);
            setReport(data as PipelineReport);
            // Auto-expand phases that have failures
            const failedPhases = new Set<string>();
            (data as PipelineReport).steps.forEach((s: StepResult) => {
                if (!s.passed) failedPhases.add(s.phase);
            });
            setExpandedPhases(failedPhases);
        } catch (err) {
            setError(err instanceof Error ? err.message : "Pipeline failed");
        }
        setRunning(false);
    }, [projectId, selectedGate]);

    const togglePhase = (phase: string) => {
        setExpandedPhases((prev) => {
            const next = new Set(prev);
            if (next.has(phase)) next.delete(phase);
            else next.add(phase);
            return next;
        });
    };

    const toggleStep = (step: number) => {
        setExpandedSteps((prev) => {
            const next = new Set(prev);
            if (next.has(step)) next.delete(step);
            else next.add(step);
            return next;
        });
    };

    const stepIcon = (step: StepResult) => {
        if (running) return ICON_RUNNING;
        if (step.passed) return ICON_PASS;
        return step.critical ? ICON_FAIL : ICON_SKIP;
    };

    const phaseSteps = (phaseKey: string): StepResult[] =>
        report?.steps.filter((s) => s.phase === phaseKey) ?? [];

    const phaseProgress = (phaseKey: string): { total: number; passed: number } => {
        const steps = phaseSteps(phaseKey);
        return { total: steps.length, passed: steps.filter((s) => s.passed).length };
    };

    return (
        <div style={panelStyle}>
            {/* Header */}
            <div style={headerBarStyle}>
                <span style={{ fontWeight: 700, fontSize: 14 }}>
                    Rule 500 Pipeline
                </span>
                <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                    <select
                        value={selectedGate}
                        onChange={(e) => setSelectedGate(e.target.value)}
                        disabled={running}
                        style={{
                            padding: "4px 8px", borderRadius: 4,
                            border: "1px solid var(--border-subtle)", background: "var(--bg-base)",
                            color: "#ccc", fontSize: 12,
                        }}
                    >
                        <option value="design">Design</option>
                        <option value="prototype">Prototype</option>
                        <option value="production">Production</option>
                    </select>
                    <button
                        onClick={runPipeline}
                        disabled={running}
                        style={running ? runButtonDisabledStyle : runButtonStyle}
                    >
                        {running ? "Running..." : "Run Pipeline"}
                    </button>
                </div>
            </div>

            {/* Error */}
            {error && (
                <div style={{ padding: "8px 16px", color: "#ff6b6b", fontSize: 12 }}>
                    {error}
                </div>
            )}

            {/* No report yet */}
            {!report && !running && !error && (
                <div style={{ padding: "16px", fontSize: 12, opacity: 0.5, textAlign: "center" }}>
                    Select a gate level and click Run Pipeline to start the 32-step validation process.
                </div>
            )}

            {/* Phase sections */}
            {report && PHASES.map(({ key, label, steps: stepRange, color }) => {
                const { total, passed } = phaseProgress(key);
                const isExpanded = expandedPhases.has(key);
                const allPassed = total > 0 && passed === total;
                const phaseFailed = total > 0 && passed < total;
                const stepsInPhase = phaseSteps(key);

                if (stepsInPhase.length === 0) return null;

                return (
                    <div key={key}>
                        <div
                            style={{
                                ...phaseHeaderStyle,
                                background: isExpanded ? "var(--bg-base)" : "transparent",
                            }}
                            onClick={() => togglePhase(key)}
                        >
                            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                                <span style={{ fontSize: 10, opacity: 0.5 }}>
                                    {isExpanded ? "\u25BC" : "\u25B6"}
                                </span>
                                <span style={{ color }}>
                                    {label}
                                </span>
                                <span style={{ fontSize: 11, opacity: 0.5, fontWeight: 400 }}>
                                    Steps {stepRange}
                                </span>
                            </div>
                            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                                {/* Mini progress bar */}
                                <div style={{
                                    width: 60, height: 4, borderRadius: 2,
                                    background: "var(--border-default)",
                                }}>
                                    <div style={{
                                        width: `${total > 0 ? (passed / total) * 100 : 0}%`,
                                        height: "100%", borderRadius: 2,
                                        background: allPassed ? "#10b981" : phaseFailed ? "#f59e0b" : "#4a9eff",
                                        transition: "width 0.3s",
                                    }} />
                                </div>
                                <span style={{ fontSize: 11, opacity: 0.6 }}>
                                    {passed}/{total}
                                </span>
                            </div>
                        </div>

                        {/* Expanded step list */}
                        {isExpanded && stepsInPhase.map((step) => (
                            <div key={step.step}>
                                <div
                                    style={{
                                        ...stepRowStyle,
                                        cursor: step.findings.length > 0 ? "pointer" : "default",
                                        color: step.passed ? "#ccc" : "#ff6b6b",
                                    }}
                                    onClick={() => step.findings.length > 0 && toggleStep(step.step)}
                                >
                                    <span>{stepIcon(step)}</span>
                                    <span style={{ flex: 1 }}>
                                        <strong>{step.step}.</strong> {step.name}
                                        {step.critical && !step.passed && (
                                            <span style={{ color: "#ef4444", marginLeft: 6, fontSize: 10 }}>
                                                CRITICAL
                                            </span>
                                        )}
                                    </span>
                                    {step.duration_ms > 0 && (
                                        <span style={{ opacity: 0.4, fontSize: 10 }}>
                                            {step.duration_ms < 1000
                                                ? `${step.duration_ms}ms`
                                                : `${(step.duration_ms / 1000).toFixed(1)}s`}
                                        </span>
                                    )}
                                    {step.findings.length > 0 && (
                                        <span style={{ opacity: 0.3, fontSize: 10 }}>
                                            {expandedSteps.has(step.step) ? "\u25BC" : "\u25B6"}
                                        </span>
                                    )}
                                </div>
                                {expandedSteps.has(step.step) && step.findings.length > 0 && (
                                    <div style={findingsStyle}>
                                        {step.findings.map((f, i) => (
                                            <div key={i}>{f}</div>
                                        ))}
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>
                );
            })}

            {/* Summary */}
            {report && (
                <div style={{
                    padding: "8px 16px",
                    borderTop: "1px solid var(--border-default)",
                    fontSize: 12,
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                }}>
                    <span style={{
                        color: report.passed ? "#10b981" : "#ff6b6b",
                        fontWeight: 600,
                    }}>
                        {report.passed ? ICON_PASS : ICON_FAIL}{" "}
                        {report.summary}
                    </span>
                    {report.stopped_at !== null && (
                        <span style={{ color: "#f59e0b", fontSize: 11 }}>
                            Stopped at step {report.stopped_at}
                        </span>
                    )}
                </div>
            )}
        </div>
    );
}
