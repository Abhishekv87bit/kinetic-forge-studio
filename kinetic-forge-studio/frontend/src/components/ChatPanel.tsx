import { useState, useRef, useEffect } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { chatApi, snapshotApi } from "../api/client";
import { useViewportStore } from "../stores/viewportStore";
import { useProjectStore } from "../stores/projectStore";
import FileUpload from "./FileUpload";

/* -- Types --------------------------------------------------------- */

interface GateResult {
    passed: boolean;
    gate_level: string;
    summary: string;
    suggestions?: string[];
}

interface QuestionOption {
    label: string;
    value: string;
    impact?: string;
    description?: string;
}

interface QuestionData {
    field: string;
    question?: string;
    options?: QuestionOption[];
    default?: string;
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
    library_suggestions: { name: string; pip: string | null; purpose: string }[];
    total_checks: number;
    checks_passed: number;
    checks_failed: number;
}

interface PipelineStepResult {
    step: number;
    name: string;
    phase: string;
    passed: boolean;
    critical: boolean;
    findings: string[];
    duration_ms: number;
}

interface PipelineReport {
    steps: PipelineStepResult[];
    passed: boolean;
    stopped_at: number | null;
    summary: string;
    gate_level: string;
}

interface CodeExecutionResult {
    language: string;
    skipped: boolean;
    success: boolean;
    error?: string;
    stdout?: string;
    execution_time?: number;
    output_files?: Record<string, string>;
}

interface Snapshot {
    id: number;
    label: string;
    gate: string;
    trigger: string;
    created_at: string;
}

interface Message {
    role: "user" | "assistant";
    content: string;
    gateResult?: GateResult;
    question?: QuestionData;
    options?: { field: string; options: QuestionOption[] };
    consultantReport?: ConsultantReport;
    pipelineReport?: PipelineReport;
    codeExecution?: CodeExecutionResult[];
    retryCount?: number;
}

interface Props {
    projectId: string;
}

/* -- Markdown custom renderers ------------------------------------- */

const mdComponents = {
    /* Code blocks with dark background and mono font */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    code({ className, children, ...rest }: any) {
        const isInline = !className;
        if (isInline) {
            return (
                <code
                    {...rest}
                    style={{
                        background: "rgba(255,255,255,0.08)",
                        padding: "1px 5px",
                        borderRadius: 4,
                        fontSize: "0.9em",
                        fontFamily: "'Fira Code', 'Cascadia Code', monospace",
                    }}
                >
                    {children}
                </code>
            );
        }
        return (
            <code
                {...rest}
                className={className}
                style={{
                    display: "block",
                    background: "rgba(0,0,0,0.3)",
                    padding: "8px 10px",
                    borderRadius: 6,
                    fontSize: 11,
                    lineHeight: 1.5,
                    overflowX: "auto",
                    fontFamily: "'Fira Code', 'Cascadia Code', monospace",
                    whiteSpace: "pre",
                }}
            >
                {children}
            </code>
        );
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    pre({ children }: any) {
        return <pre style={{ margin: "6px 0" }}>{children}</pre>;
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    p({ children }: any) {
        return <p style={{ margin: "4px 0" }}>{children}</p>;
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ul({ children }: any) {
        return <ul style={{ margin: "4px 0", paddingLeft: 18 }}>{children}</ul>;
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ol({ children }: any) {
        return <ol style={{ margin: "4px 0", paddingLeft: 18 }}>{children}</ol>;
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    h1({ children }: any) {
        return <h1 style={{ fontSize: 16, fontWeight: 700, margin: "8px 0 4px" }}>{children}</h1>;
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    h2({ children }: any) {
        return <h2 style={{ fontSize: 14, fontWeight: 700, margin: "6px 0 3px" }}>{children}</h2>;
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    h3({ children }: any) {
        return <h3 style={{ fontSize: 13, fontWeight: 600, margin: "4px 0 2px" }}>{children}</h3>;
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    table({ children }: any) {
        return (
            <table style={{
                borderCollapse: "collapse",
                fontSize: 11,
                margin: "6px 0",
                width: "100%",
            }}>
                {children}
            </table>
        );
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    th({ children }: any) {
        return (
            <th style={{
                borderBottom: "1px solid var(--border-default)",
                padding: "3px 6px",
                textAlign: "left",
                fontWeight: 600,
            }}>
                {children}
            </th>
        );
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    td({ children }: any) {
        return (
            <td style={{
                borderBottom: "1px solid var(--border-subtle)",
                padding: "3px 6px",
            }}>
                {children}
            </td>
        );
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    strong({ children }: any) {
        return <strong style={{ color: "var(--text-primary)", fontWeight: 600 }}>{children}</strong>;
    },
};

/* -- Styles -------------------------------------------------------- */

const consultantBlockStyle: React.CSSProperties = {
    marginTop: 8,
    padding: "8px 10px",
    borderRadius: "var(--radius-md)",
    background: "var(--bg-base)",
    border: "1px solid var(--border-default)",
    fontSize: 11,
};

const consultantRowStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: 6,
    padding: "2px 0",
    cursor: "pointer",
};

const findingLineStyle: React.CSSProperties = {
    paddingLeft: 20,
    fontSize: 10,
    opacity: 0.7,
    lineHeight: 1.4,
};

const recommendLineStyle: React.CSSProperties = {
    paddingLeft: 20,
    fontSize: 10,
    color: "#f59e0b",
    lineHeight: 1.4,
};

const libSuggestionStyle: React.CSSProperties = {
    display: "inline-block",
    padding: "2px 8px",
    borderRadius: 100,
    background: "rgba(167, 139, 250, 0.1)",
    border: "1px solid rgba(167, 139, 250, 0.2)",
    color: "var(--accent-purple)",
    fontSize: 10,
    marginRight: 4,
    marginTop: 4,
};

const pipelineBlockStyle: React.CSSProperties = {
    marginTop: 8,
    padding: "8px 10px",
    borderRadius: "var(--radius-md)",
    background: "var(--bg-base)",
    border: "1px solid var(--border-default)",
    fontSize: 11,
};

const pipelineStepStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: 6,
    padding: "1px 0",
    fontSize: 10,
};

const codeExecBlockStyle: React.CSSProperties = {
    marginTop: 8,
    padding: "6px 10px",
    borderRadius: "var(--radius-md)",
    background: "rgba(0, 0, 0, 0.25)",
    border: "1px solid var(--border-subtle)",
    fontSize: 11,
};

const timelineBarStyle: React.CSSProperties = {
    flexShrink: 0,
    marginBottom: 4,
    padding: "4px 0",
    borderBottom: "1px solid var(--border-subtle)",
};

const snapshotDotStyle: React.CSSProperties = {
    width: 8,
    height: 8,
    borderRadius: "50%",
    background: "var(--accent-blue)",
    flexShrink: 0,
};

const optionButtonStyle: React.CSSProperties = {
    padding: "6px 12px",
    borderRadius: 16,
    border: "1px solid var(--accent-blue)",
    background: "transparent",
    color: "var(--accent-blue)",
    cursor: "pointer",
    fontSize: 12,
    fontWeight: 500,
    transition: "all 0.15s",
};

/* -- Component ----------------------------------------------------- */

export default function ChatPanel({ projectId }: Props) {
    const [messages, setMessages] = useState<Message[]>([]);
    const [input, setInput] = useState("");
    const [loading, setLoading] = useState(false);
    const [historyLoaded, setHistoryLoaded] = useState(false);
    const [expandedConsultants, setExpandedConsultants] = useState<Set<string>>(new Set());
    const [snapshots, setSnapshots] = useState<Snapshot[]>([]);
    const [showTimeline, setShowTimeline] = useState(false);
    const bottomRef = useRef<HTMLDivElement>(null);
    const { reloadGeometry } = useViewportStore();
    const { refreshProject } = useProjectStore();

    /* Load persisted chat history on mount / project change */
    useEffect(() => {
        let cancelled = false;
        setHistoryLoaded(false);
        setMessages([]);
        chatApi.history(projectId).then((data) => {
            if (cancelled) return;
            if (data?.messages?.length) {
                const restored: Message[] = data.messages.map(
                    (m: { role: string; content: string }) => ({
                        role: m.role as "user" | "assistant",
                        content: m.content,
                    })
                );
                setMessages(restored);
            }
            setHistoryLoaded(true);
        }).catch(() => {
            if (!cancelled) setHistoryLoaded(true);
        });
        return () => { cancelled = true; };
    }, [projectId]);

    /* Load snapshots for timeline */
    const refreshSnapshots = () => {
        snapshotApi.list(projectId).then((data) => {
            if (Array.isArray(data)) setSnapshots(data);
        }).catch(() => {});
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
    useEffect(() => { refreshSnapshots(); }, [projectId]);

    useEffect(() => {
        bottomRef.current?.scrollIntoView({ behavior: "smooth" });
    }, [messages]);

    const toggleConsultant = (name: string) => {
        setExpandedConsultants((prev) => {
            const next = new Set(prev);
            if (next.has(name)) next.delete(name);
            else next.add(name);
            return next;
        });
    };

    const handleResponse = (data: Record<string, unknown>) => {
        const assistantMsg: Message = {
            role: "assistant",
            content: data.message as string,
        };
        if (data.gate_result) {
            assistantMsg.gateResult = data.gate_result as GateResult;
        }
        if (data.question) {
            assistantMsg.question = data.question as QuestionData;
        }
        if (data.options) {
            assistantMsg.options = data.options as { field: string; options: QuestionOption[] };
        }
        if (data.consultant_report) {
            assistantMsg.consultantReport = data.consultant_report as ConsultantReport;
        }
        if (data.pipeline_report) {
            assistantMsg.pipelineReport = data.pipeline_report as PipelineReport;
        }
        if (data.code_execution) {
            assistantMsg.codeExecution = data.code_execution as CodeExecutionResult[];
        }
        if (data.retry_count !== undefined) {
            assistantMsg.retryCount = data.retry_count as number;
        }
        setMessages((m) => [...m, assistantMsg]);

        if (data.geometry_ready) {
            reloadGeometry();
            refreshProject();
        }
        // Refresh timeline after any response that might create snapshots
        if (data.geometry_ready || data.gate_advanced || data.code_execution) {
            refreshSnapshots();
        }
    };

    const send = async () => {
        if (!input.trim() || loading) return;
        const text = input.trim();
        setInput("");
        setMessages((m) => [...m, { role: "user", content: text }]);
        setLoading(true);
        try {
            const data = await chatApi.send(projectId, text);
            handleResponse(data);
        } catch (err) {
            const detail = err instanceof Error ? err.message : "Unknown error";
            setMessages((m) => [
                ...m,
                { role: "assistant", content: `Error: ${detail}` },
            ]);
        }
        setLoading(false);
    };

    const selectOption = async (field: string, value: string, label: string) => {
        if (loading) return;
        setMessages((m) => [...m, { role: "user", content: label }]);
        setLoading(true);
        try {
            const data = await chatApi.answer(projectId, field, value);
            handleResponse(data);
        } catch (err) {
            const detail = err instanceof Error ? err.message : "Unknown error";
            setMessages((m) => [
                ...m,
                { role: "assistant", content: `Error: ${detail}` },
            ]);
        }
        setLoading(false);
    };

    return (
        <div style={{ display: "flex", flexDirection: "column", height: "100%", minHeight: 0 }}>
            <div style={{
                fontSize: 11,
                fontWeight: 600,
                textTransform: "uppercase" as const,
                letterSpacing: "0.05em",
                color: "var(--text-muted)",
                marginBottom: "var(--space-3)",
                flexShrink: 0,
            }}>
                Chat
            </div>

            {/* Timeline / Snapshot bar */}
            {snapshots.length > 0 && (
                <div style={timelineBarStyle}>
                    <div
                        style={{
                            fontSize: 10,
                            color: "var(--text-muted)",
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            gap: 4,
                            userSelect: "none",
                        }}
                        onClick={() => setShowTimeline(!showTimeline)}
                    >
                        <span style={{ fontSize: 8 }}>
                            {showTimeline ? "\u25BC" : "\u25B6"}
                        </span>
                        <span>Timeline ({snapshots.length})</span>
                    </div>
                    {showTimeline && (
                        <div style={{
                            maxHeight: 120,
                            overflowY: "auto",
                            marginTop: 4,
                        }}>
                            {snapshots.map((s) => (
                                <div key={s.id} style={{
                                    display: "flex",
                                    alignItems: "center",
                                    gap: 6,
                                    padding: "2px 0",
                                    fontSize: 10,
                                    color: "var(--text-secondary)",
                                }}>
                                    <span style={snapshotDotStyle} />
                                    <span style={{ flex: 1 }}>{s.label}</span>
                                    <span style={{ opacity: 0.4 }}>
                                        {s.gate}
                                    </span>
                                    <button
                                        style={{
                                            fontSize: 9,
                                            padding: "1px 6px",
                                            borderRadius: 4,
                                            border: "1px solid var(--border-default)",
                                            background: "transparent",
                                            color: "var(--accent-amber)",
                                            cursor: "pointer",
                                        }}
                                        onClick={async () => {
                                            if (!window.confirm(
                                                `Rollback to "${s.label}"?\n\nThis will replace current components and decisions.`
                                            )) return;
                                            try {
                                                await snapshotApi.rollback(
                                                    projectId, s.id
                                                );
                                                reloadGeometry();
                                                refreshProject();
                                                refreshSnapshots();
                                            } catch (err) {
                                                console.error("Rollback failed", err);
                                            }
                                        }}
                                    >
                                        Rollback
                                    </button>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            )}
            <div
                style={{
                    flex: 1,
                    minHeight: 0,
                    overflowY: "auto",
                    display: "flex",
                    flexDirection: "column",
                    gap: "var(--space-2)",
                }}
            >
                {/* Empty state or loading history */}
                {!historyLoaded && (
                    <div style={{
                        padding: "var(--space-4)",
                        textAlign: "center",
                        color: "var(--text-disabled)",
                        fontSize: 12,
                    }}>
                        Loading conversation...
                    </div>
                )}
                {historyLoaded && messages.length === 0 && (
                    <div style={{
                        padding: "var(--space-8) var(--space-4)",
                        textAlign: "center",
                        color: "var(--text-muted)",
                        fontSize: 13,
                        lineHeight: 1.6,
                    }}>
                        Describe the kinetic sculpture you want to design.
                        <div style={{ fontSize: 11, marginTop: "var(--space-2)", color: "var(--text-disabled)" }}>
                            Try "Rule 99" or "design locked" for methodology commands.
                        </div>
                    </div>
                )}
                {messages.map((m, i) => (
                    <div
                        key={`${m.role}-${i}`}
                        style={{
                            padding: "var(--space-2) var(--space-3)",
                            borderRadius: "var(--radius-lg)",
                            fontSize: 13,
                            lineHeight: 1.5,
                            background: m.role === "user"
                                ? "rgba(59, 130, 246, 0.15)"
                                : "var(--bg-overlay)",
                            border: m.role === "user"
                                ? "1px solid rgba(59, 130, 246, 0.2)"
                                : "1px solid var(--border-subtle)",
                            alignSelf:
                                m.role === "user" ? "flex-end" : "flex-start",
                            maxWidth: "92%",
                        }}
                    >
                        {/* Message text — rendered as Markdown for assistant, plain for user */}
                        {m.role === "assistant" ? (
                            <div className="chat-markdown">
                                <ReactMarkdown
                                    remarkPlugins={[remarkGfm]}
                                    components={mdComponents}
                                >
                                    {m.content}
                                </ReactMarkdown>
                            </div>
                        ) : (
                            <span>{m.content}</span>
                        )}

                        {/* Gate Result */}
                        {m.gateResult && (
                            <div
                                style={{
                                    marginTop: 8,
                                    padding: "6px 10px",
                                    borderRadius: 6,
                                    background: m.gateResult.passed
                                        ? "#0d3320"
                                        : "#3d1515",
                                    border: `1px solid ${m.gateResult.passed ? "#1a6b3a" : "#6b1a1a"}`,
                                    fontSize: 12,
                                }}
                            >
                                <span style={{ fontWeight: 600 }}>
                                    {m.gateResult.passed
                                        ? "GATE PASSED"
                                        : "GATE BLOCKED"}
                                </span>
                                <span
                                    style={{ opacity: 0.7, marginLeft: 8 }}
                                >
                                    ({m.gateResult.gate_level})
                                </span>
                            </div>
                        )}

                        {/* Consultant Report (inline in chat) */}
                        {m.consultantReport && (
                            <div style={consultantBlockStyle}>
                                <div
                                    style={{
                                        fontWeight: 600,
                                        marginBottom: 4,
                                        color: m.consultantReport.passed
                                            ? "#4ade80"
                                            : "#ff6b6b",
                                    }}
                                >
                                    {m.consultantReport.passed ? "\u2705" : "\u274C"}{" "}
                                    Rule 99 — {m.consultantReport.gate.toUpperCase()}
                                    <span
                                        style={{
                                            fontWeight: 400,
                                            opacity: 0.6,
                                            marginLeft: 8,
                                        }}
                                    >
                                        {m.consultantReport.checks_passed}/
                                        {m.consultantReport.total_checks} checks
                                    </span>
                                </div>
                                {m.consultantReport.consultants_fired.map(
                                    (c) => (
                                        <div key={c.name}>
                                            <div
                                                style={consultantRowStyle}
                                                onClick={() =>
                                                    toggleConsultant(c.name)
                                                }
                                            >
                                                <span>
                                                    {c.passed
                                                        ? "\u2705"
                                                        : "\u274C"}
                                                </span>
                                                <span
                                                    style={{
                                                        flex: 1,
                                                        color: c.passed
                                                            ? "#ccc"
                                                            : "#ff6b6b",
                                                    }}
                                                >
                                                    {c.name}
                                                </span>
                                                <span
                                                    style={{
                                                        opacity: 0.3,
                                                        fontSize: 9,
                                                    }}
                                                >
                                                    {expandedConsultants.has(
                                                        c.name
                                                    )
                                                        ? "\u25BC"
                                                        : "\u25B6"}
                                                </span>
                                            </div>
                                            {expandedConsultants.has(
                                                c.name
                                            ) && (
                                                <>
                                                    {c.findings.map(
                                                        (f, fi) => (
                                                            <div
                                                                key={fi}
                                                                style={
                                                                    findingLineStyle
                                                                }
                                                            >
                                                                {f}
                                                            </div>
                                                        )
                                                    )}
                                                    {c.recommendations.map(
                                                        (r, ri) => (
                                                            <div
                                                                key={`r-${ri}`}
                                                                style={
                                                                    recommendLineStyle
                                                                }
                                                            >
                                                                {"\u26A0\uFE0F"}{" "}
                                                                {r}
                                                            </div>
                                                        )
                                                    )}
                                                </>
                                            )}
                                        </div>
                                    )
                                )}
                                {/* Library Suggestions */}
                                {m.consultantReport.library_suggestions
                                    .length > 0 && (
                                    <div style={{ marginTop: 6 }}>
                                        {m.consultantReport.library_suggestions
                                            .slice(0, 5)
                                            .map((lib) => (
                                                <span
                                                    key={lib.name}
                                                    style={libSuggestionStyle}
                                                    title={lib.purpose}
                                                >
                                                    {lib.name}
                                                    {lib.pip && (
                                                        <span
                                                            style={{
                                                                opacity: 0.5,
                                                            }}
                                                        >
                                                            {" "}
                                                            {lib.pip}
                                                        </span>
                                                    )}
                                                </span>
                                            ))}
                                    </div>
                                )}
                            </div>
                        )}

                        {/* Pipeline Report (inline in chat) */}
                        {m.pipelineReport && (
                            <div style={pipelineBlockStyle}>
                                <div
                                    style={{
                                        fontWeight: 600,
                                        marginBottom: 4,
                                        color: m.pipelineReport.passed
                                            ? "#4ade80"
                                            : "#ff6b6b",
                                    }}
                                >
                                    {m.pipelineReport.passed ? "\u2705" : "\u274C"}{" "}
                                    Rule 500 Pipeline
                                    <span
                                        style={{
                                            fontWeight: 400,
                                            opacity: 0.6,
                                            marginLeft: 8,
                                        }}
                                    >
                                        {
                                            m.pipelineReport.steps.filter(
                                                (s) => s.passed
                                            ).length
                                        }
                                        /{m.pipelineReport.steps.length} steps
                                    </span>
                                </div>
                                {m.pipelineReport.steps.map((step) => (
                                    <div
                                        key={step.step}
                                        style={{
                                            ...pipelineStepStyle,
                                            color: step.passed
                                                ? "#ccc"
                                                : "#ff6b6b",
                                        }}
                                    >
                                        <span>
                                            {step.passed ? "\u2705" : "\u274C"}
                                        </span>
                                        <span>
                                            {step.step}. {step.name}
                                        </span>
                                        {step.critical && !step.passed && (
                                            <span
                                                style={{
                                                    color: "#ef4444",
                                                    fontSize: 9,
                                                }}
                                            >
                                                CRITICAL
                                            </span>
                                        )}
                                    </div>
                                ))}
                                {m.pipelineReport.stopped_at !== null && (
                                    <div
                                        style={{
                                            marginTop: 4,
                                            color: "#f59e0b",
                                            fontSize: 10,
                                        }}
                                    >
                                        Pipeline stopped at step{" "}
                                        {m.pipelineReport.stopped_at}
                                    </div>
                                )}
                            </div>
                        )}

                        {/* Code Execution Results */}
                        {m.codeExecution &&
                            m.codeExecution.some((r) => !r.skipped) && (
                                <div style={codeExecBlockStyle}>
                                    <div
                                        style={{
                                            fontWeight: 600,
                                            marginBottom: 3,
                                            fontSize: 10,
                                            color: "var(--text-secondary)",
                                        }}
                                    >
                                        Code Execution
                                    </div>
                                    {m.codeExecution
                                        .filter((r) => !r.skipped)
                                        .map((r, ri) => (
                                            <div
                                                key={ri}
                                                style={{
                                                    display: "flex",
                                                    alignItems: "center",
                                                    gap: 6,
                                                    fontSize: 10,
                                                    padding: "1px 0",
                                                }}
                                            >
                                                <span>
                                                    {r.success
                                                        ? "\u2705"
                                                        : "\u274C"}
                                                </span>
                                                <span>{r.language}</span>
                                                {r.execution_time !==
                                                    undefined && (
                                                    <span
                                                        style={{ opacity: 0.5 }}
                                                    >
                                                        (
                                                        {r.execution_time.toFixed(
                                                            1
                                                        )}
                                                        s)
                                                    </span>
                                                )}
                                                {r.success &&
                                                    r.output_files && (
                                                        <span
                                                            style={{
                                                                color: "var(--accent-green)",
                                                                fontSize: 9,
                                                            }}
                                                        >
                                                            {"\u2192"}{" "}
                                                            {Object.keys(
                                                                r.output_files
                                                            ).join(", ")}
                                                        </span>
                                                    )}
                                                {!r.success && r.error && (
                                                    <span
                                                        style={{
                                                            color: "#ff6b6b",
                                                            fontSize: 9,
                                                        }}
                                                    >
                                                        {r.error.substring(
                                                            0,
                                                            80
                                                        )}
                                                    </span>
                                                )}
                                            </div>
                                        ))}
                                </div>
                            )}

                        {/* Retry badge */}
                        {m.retryCount !== undefined && m.retryCount > 0 && (
                            <div style={{
                                marginTop: 6,
                                display: "inline-block",
                                padding: "2px 8px",
                                borderRadius: 100,
                                background: "rgba(245, 158, 11, 0.1)",
                                border: "1px solid rgba(245, 158, 11, 0.2)",
                                color: "var(--accent-amber)",
                                fontSize: 10,
                            }}>
                                Auto-retried {m.retryCount}x
                            </div>
                        )}

                        {/* Question options from Pipeline */}
                        {m.question?.options && i === messages.length - 1 && (
                            <div
                                style={{
                                    display: "flex",
                                    flexWrap: "wrap",
                                    gap: 6,
                                    marginTop: 8,
                                }}
                            >
                                {m.question.options.map((opt) => (
                                    <button
                                        key={opt.value ?? opt.label}
                                        onClick={() =>
                                            selectOption(
                                                m.question!.field,
                                                opt.value ?? opt.label,
                                                opt.label
                                            )
                                        }
                                        disabled={loading}
                                        style={optionButtonStyle}
                                        onMouseEnter={(e) => {
                                            e.currentTarget.style.background =
                                                "var(--accent-blue)";
                                            e.currentTarget.style.color =
                                                "#fff";
                                        }}
                                        onMouseLeave={(e) => {
                                            e.currentTarget.style.background =
                                                "transparent";
                                            e.currentTarget.style.color =
                                                "var(--accent-blue)";
                                        }}
                                    >
                                        {opt.label}
                                    </button>
                                ))}
                            </div>
                        )}

                        {/* AI-parsed options */}
                        {m.options?.options && i === messages.length - 1 && (
                            <div
                                style={{
                                    display: "flex",
                                    flexWrap: "wrap",
                                    gap: 6,
                                    marginTop: 8,
                                }}
                            >
                                {m.options.options.map((opt) => (
                                    <button
                                        key={opt.value ?? opt.label}
                                        onClick={() =>
                                            selectOption(
                                                m.options!.field,
                                                opt.value ?? opt.label,
                                                opt.label
                                            )
                                        }
                                        disabled={loading}
                                        style={optionButtonStyle}
                                        onMouseEnter={(e) => {
                                            e.currentTarget.style.background =
                                                "var(--accent-blue)";
                                            e.currentTarget.style.color =
                                                "#fff";
                                        }}
                                        onMouseLeave={(e) => {
                                            e.currentTarget.style.background =
                                                "transparent";
                                            e.currentTarget.style.color =
                                                "var(--accent-blue)";
                                        }}
                                    >
                                        {opt.label}
                                        {opt.description && (
                                            <span
                                                style={{
                                                    opacity: 0.6,
                                                    marginLeft: 4,
                                                    fontSize: 11,
                                                }}
                                            >
                                                {" "}
                                                {"\u2014"} {opt.description}
                                            </span>
                                        )}
                                    </button>
                                ))}
                            </div>
                        )}
                    </div>
                ))}

                {/* Loading indicator */}
                {loading && (
                    <div
                        style={{
                            padding: "var(--space-2) var(--space-3)",
                            borderRadius: "var(--radius-lg)",
                            background: "var(--bg-overlay)",
                            border: "1px solid var(--border-subtle)",
                            alignSelf: "flex-start",
                            maxWidth: "92%",
                            fontSize: 13,
                            color: "var(--text-muted)",
                        }}
                    >
                        <span className="thinking-dots">Thinking</span>
                    </div>
                )}

                <div ref={bottomRef} />
            </div>

            {/* Input */}
            <div style={{
                display: "flex",
                gap: "var(--space-2)",
                marginTop: "var(--space-3)",
                padding: "var(--space-2) 0",
                flexShrink: 0,
            }}>
                <input
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && send()}
                    placeholder="Describe your design..."
                    disabled={loading}
                    style={{
                        flex: 1,
                        padding: "8px 12px",
                        borderRadius: "var(--radius-md)",
                        border: "1px solid var(--border-default)",
                        background: "var(--bg-input)",
                        color: "var(--text-primary)",
                        fontSize: 13,
                        outline: "none",
                        transition: "border-color 0.15s ease",
                    }}
                    onFocus={(e) => { e.currentTarget.style.borderColor = "var(--accent-blue)"; }}
                    onBlur={(e) => { e.currentTarget.style.borderColor = "var(--border-default)"; }}
                />
                <button
                    onClick={send}
                    disabled={loading}
                    style={{
                        padding: "8px 14px",
                        borderRadius: "var(--radius-md)",
                        background: loading ? "var(--bg-elevated)" : "var(--accent-blue)",
                        color: loading ? "var(--text-disabled)" : "#fff",
                        fontWeight: 600,
                        fontSize: 12,
                        transition: "all 0.15s ease",
                    }}
                >
                    {loading ? "..." : "Send"}
                </button>
            </div>
            <div style={{ marginTop: "var(--space-1)" }}>
                <FileUpload
                    projectId={projectId}
                    onUpload={(result) => {
                        const a = result.analysis;
                        let analysisText: string;
                        if (typeof a === "string") {
                            analysisText = a;
                        } else if (a?.error) {
                            analysisText = `\u26A0\uFE0F Analysis failed: ${a.error}`;
                        } else if (a?.face_count !== undefined) {
                            const bb = a.bounding_box;
                            analysisText = `**STL Analysis:**\n- ${a.face_count.toLocaleString()} faces, ${a.vertex_count.toLocaleString()} vertices\n- Size: ${bb?.x_size?.toFixed(1)} \u00D7 ${bb?.y_size?.toFixed(1)} \u00D7 ${bb?.z_size?.toFixed(1)} mm\n- Volume: ${a.volume?.toFixed(1)} mm\u00B3\n- Watertight: ${a.is_watertight ? "Yes" : "No"}`;
                        } else if (a?.body_count !== undefined) {
                            analysisText = `**STEP Analysis:**\n- ${a.body_count} bodies\n- ${a.total_faces} faces (${Object.entries(a.face_types || {}).map(([k, v]) => `${v} ${k}`).join(", ")})\n- Volume: ${a.volume?.toFixed(1)} mm\u00B3`;
                        } else if (a?.mechanism_type !== undefined) {
                            analysisText = `**Photo Analysis:**\n- Mechanism: ${a.mechanism_type}\n- Motion: ${a.motion_type}\n- Components: ~${a.component_count}\n- Materials: ${a.materials?.join(", ") || "unknown"}`;
                        } else if (a?.cycle_period !== undefined) {
                            analysisText = `**Video Analysis:**\n- Cycle: ${a.cycle_period}s\n- Tempo: ${a.tempo}\n- Motions: ${a.motion_types?.join(", ")}`;
                        } else {
                            analysisText =
                                a?.message || JSON.stringify(a, null, 2);
                        }
                        setMessages((m) => [
                            ...m,
                            {
                                role: "user",
                                content: `Uploaded: ${result.filename}`,
                            },
                            { role: "assistant", content: analysisText },
                        ]);
                    }}
                />
            </div>
        </div>
    );
}
