// TypeScript types mirroring backend Pydantic schemas

export type AssetClass = "equity" | "crypto" | "commodity" | "forex";
export type SignalType = "strong_buy" | "buy" | "hold" | "sell" | "strong_sell";

// ── Assets ──

export interface Asset {
  id: string;
  asset_class: AssetClass;
  name: string;
  tracked: boolean;
  metadata: Record<string, unknown>;
  created_at: string | null;
}

export interface AssetCreate {
  id: string;
  asset_class: AssetClass;
  name: string;
  tracked?: boolean;
  metadata?: Record<string, unknown>;
}

// ── Signals ──

export interface EvidenceItem {
  source: string;
  [key: string]: unknown;
}

export interface RiskFlagItem {
  category: string;
  severity: string;
  headline: string;
}

export interface Signal {
  id: number;
  asset_id: string;
  signal_type: SignalType;
  confidence: number;
  summary: string;
  evidence: EvidenceItem[];
  risk_flags: RiskFlagItem[];
  raw_llm: Record<string, unknown>;
  created_at: string | null;
}

// ── Golden Rules ──

export interface GoldenRule {
  id: number;
  name: string;
  description: string;
  rule_prompt: string;
  asset_class: AssetClass | null;
  weight: number;
  active: boolean;
  created_at: string | null;
}

export interface RuleCreate {
  name: string;
  description?: string;
  rule_prompt: string;
  asset_class?: AssetClass | null;
  weight?: number;
  active?: boolean;
}

export interface RuleUpdate {
  name?: string;
  description?: string;
  rule_prompt?: string;
  asset_class?: AssetClass | null;
  weight?: number;
  active?: boolean;
}

// ── Paper Trading ──

export interface PaperTrade {
  id: number;
  signal_id: number;
  asset_id: string;
  action: string;
  quantity: number;
  price_at: number;
  price_now: number;
  pnl: number;
  status: "open" | "closed";
  opened_at: string | null;
  closed_at: string | null;
}

export interface PortfolioSummary {
  total_trades: number;
  open_trades: number;
  closed_trades: number;
  realized_pnl: number;
  unrealized_pnl: number;
  total_pnl: number;
  win_rate: number;
}

// ── Analysis ──

export interface AnalysisResult {
  asset_id: string;
  signal_id: number | null;
  signal_type: SignalType;
  confidence: number;
  analyst: Record<string, unknown>;
  risk: Record<string, unknown>;
  sentiment: Record<string, unknown>;
  synthesis: {
    rule_evaluations: RuleEvaluation[];
    weighted_score: number;
    signal_type: SignalType;
    agreement_ratio: number;
    plain_summary: string;
  };
  fact_check: Record<string, unknown>;
  timestamp: string;
}

export interface RuleEvaluation {
  rule_name: string;
  rule_id: number;
  direction: string;
  score: number;
  reasoning: string;
}

// ── Alerts ──

export interface AlertLog {
  id: number;
  signal_id: number | null;
  channel: string;
  priority: string;
  message: string;
  sent_at: string;
  acknowledged: boolean;
}

// ── Health ──

export interface HealthResponse {
  status: string;
  version: string;
  db: string;
}

// ── Backtests ──

export interface BacktestConfig {
  position_size_pct: number;
  stop_loss_pct: number;
  max_hold_days: number;
}

export interface BacktestCreate {
  name: string;
  asset_ids: string[];
  date_from: string;
  date_to: string;
  rule_ids?: number[];
  initial_capital?: number;
  config?: Partial<BacktestConfig>;
}

export interface BacktestTradeRecord {
  asset_id: string;
  signal_id: number;
  signal_type: SignalType;
  entry_date: string;
  entry_price: number;
  exit_date: string | null;
  exit_price: number | null;
  pnl: number;
  pnl_pct: number;
  exit_reason: string;
}

export interface BacktestResultData {
  id: number;
  run_id: number;
  total_return: number;
  sharpe_ratio: number;
  max_drawdown: number;
  win_rate: number;
  trades: BacktestTradeRecord[];
  equity_curve: { date: string; equity: number }[];
  benchmark: Record<string, unknown>;
}

export interface BacktestRun {
  id: number;
  name: string;
  rule_ids: number[];
  date_from: string;
  date_to: string;
  asset_ids: string[];
  initial_capital: number;
  config: BacktestConfig;
  created_at: string | null;
  results?: BacktestResultData[];
}

// ── Signal Scores ──

export interface SignalScoreItem {
  score: number;
  details: Record<string, unknown>;
  computed_at: string | null;
}

// ── Dashboard Summary ──

export interface DashboardOpportunity {
  asset_id: string;
  signal_type: SignalType;
  confidence: number;
  summary: string;
  signal_id: number;
  created_at: string | null;
}

export interface DashboardSummary {
  top_opportunities: DashboardOpportunity[];
  top_risks: DashboardOpportunity[];
  total_tracked: number;
  stale_assets: string[];
}

// ── Bulk Ingest ──

export interface BulkIngestResult {
  equities_attempted: number;
  equities_succeeded: number;
  equities_failed: number;
  crypto_attempted: number;
  crypto_succeeded: number;
  crypto_failed: number;
}
