// Centralized API client — all backend calls go through here.
// Vite dev server proxies /api → http://localhost:8000

import type {
  Asset,
  AssetCreate,
  Signal,
  GoldenRule,
  RuleCreate,
  RuleUpdate,
  PaperTrade,
  PortfolioSummary,
  AnalysisResult,
  AlertLog,
  HealthResponse,
  BacktestRun,
  BacktestCreate,
  DashboardSummary,
  BulkIngestResult,
} from "./types";

async function request<T>(url: string, init?: RequestInit): Promise<T> {
  const headers: Record<string, string> = { ...init?.headers as Record<string, string> };
  // Only set Content-Type when there's a request body
  if (init?.body) {
    headers["Content-Type"] = headers["Content-Type"] ?? "application/json";
  }
  const apiKey = localStorage.getItem("ap_api_key");
  if (apiKey) {
    headers["X-API-Key"] = apiKey;
  }
  const res = await fetch(url, { ...init, headers });
  if (!res.ok) {
    const body = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(body.detail || `API error ${res.status}`);
  }
  return res.json();
}

// ── Health ──

export const fetchHealth = () => request<HealthResponse>("/api/health");

// ── Assets ──

export const fetchAssets = () => request<Asset[]>("/api/assets");

export const createAsset = (data: AssetCreate) =>
  request<Asset>("/api/assets", {
    method: "POST",
    body: JSON.stringify(data),
  });

export const deleteAsset = (id: string) =>
  request<{ deleted: string }>(`/api/assets/${id}`, { method: "DELETE" });

export const toggleTracked = (id: string, tracked: boolean) =>
  request<Asset>(`/api/assets/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ tracked }),
  });

// ── Signals ──

export const fetchSignals = (params?: { asset_id?: string; limit?: number }) => {
  const qs = new URLSearchParams();
  if (params?.asset_id) qs.set("asset_id", params.asset_id);
  if (params?.limit) qs.set("limit", String(params.limit));
  const query = qs.toString();
  return request<Signal[]>(`/api/signals${query ? `?${query}` : ""}`);
};

export const fetchSignal = (id: number) => request<Signal>(`/api/signals/${id}`);

// ── Analysis ──

export const runAnalysis = (assetId: string) =>
  request<AnalysisResult>(`/api/analyze/${assetId}`, { method: "POST" });

// ── Golden Rules ──

export const fetchRules = () => request<GoldenRule[]>("/api/rules");

export const createRule = (data: RuleCreate) =>
  request<GoldenRule>("/api/rules", {
    method: "POST",
    body: JSON.stringify(data),
  });

export const updateRule = (id: number, data: RuleUpdate) =>
  request<GoldenRule>(`/api/rules/${id}`, {
    method: "PATCH",
    body: JSON.stringify(data),
  });

export const deleteRule = (id: number) =>
  request<{ deleted: number }>(`/api/rules/${id}`, { method: "DELETE" });

export const seedRules = () =>
  request<{ seeded: number; skipped: number }>("/api/rules/seed", {
    method: "POST",
  });

// ── Paper Trading ──

export const fetchTrades = (params?: { status?: string; asset_id?: string }) => {
  const qs = new URLSearchParams();
  if (params?.status) qs.set("status", params.status);
  if (params?.asset_id) qs.set("asset_id", params.asset_id);
  const query = qs.toString();
  return request<PaperTrade[]>(`/api/portfolio/trades${query ? `?${query}` : ""}`);
};

export const createTrade = (data: {
  signal_id: number;
  price: number;
  quantity: number;
}) =>
  request<PaperTrade>("/api/portfolio/trades", {
    method: "POST",
    body: JSON.stringify(data),
  });

export const closeTrade = (tradeId: number, closePrice: number) =>
  request<PaperTrade>(`/api/portfolio/trades/${tradeId}/close`, {
    method: "POST",
    body: JSON.stringify({ close_price: closePrice }),
  });

export const fetchPortfolioSummary = () =>
  request<PortfolioSummary>("/api/portfolio/summary");

// ── Alerts ──

export const fetchAlerts = () => request<AlertLog[]>("/api/alerts");

// ── Backtests ──

export const fetchBacktests = () => request<BacktestRun[]>("/api/backtests");

export const fetchBacktest = (id: number) =>
  request<BacktestRun>(`/api/backtests/${id}`);

export const createBacktest = (data: BacktestCreate) =>
  request<BacktestRun>("/api/backtests", {
    method: "POST",
    body: JSON.stringify(data),
  });

export const deleteBacktest = (id: number) =>
  request<{ deleted: number }>(`/api/backtests/${id}`, { method: "DELETE" });

// ── Dashboard ──

export const fetchDashboardSummary = () =>
  request<DashboardSummary>("/api/dashboard/summary");

// ── Bulk Ingest ──

export const triggerBulkIngest = () =>
  request<BulkIngestResult>("/api/ingest/bulk", { method: "POST" });
