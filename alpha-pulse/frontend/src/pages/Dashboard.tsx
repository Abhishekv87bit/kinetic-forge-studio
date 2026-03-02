import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import {
  fetchSignals,
  fetchAssets,
  fetchPortfolioSummary,
  fetchDashboardSummary,
  triggerBulkIngest,
  runAnalysis,
  validateTicker,
  createAsset,
} from "../api/client";
import type { DashboardOpportunity } from "../api/types";
import SignalBadge from "../components/SignalBadge";
import ConfidenceBar from "../components/ConfidenceBar";

export default function Dashboard() {
  const queryClient = useQueryClient();

  const signals = useQuery({ queryKey: ["signals"], queryFn: () => fetchSignals({ limit: 20 }) });
  const assets = useQuery({ queryKey: ["assets"], queryFn: fetchAssets });
  const portfolio = useQuery({ queryKey: ["portfolio-summary"], queryFn: fetchPortfolioSummary });
  const dashSummary = useQuery({ queryKey: ["dashboard-summary"], queryFn: fetchDashboardSummary });

  const analyze = useMutation({
    mutationFn: (assetId: string) => runAnalysis(assetId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["signals"] });
      queryClient.invalidateQueries({ queryKey: ["portfolio-summary"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-summary"] });
    },
  });

  const bulkIngest = useMutation({
    mutationFn: triggerBulkIngest,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["dashboard-summary"] });
      queryClient.invalidateQueries({ queryKey: ["assets"] });
    },
  });

  // Asset search state
  const [searchTicker, setSearchTicker] = useState("");
  const [searchResult, setSearchResult] = useState<{valid: boolean; name?: string; asset_class?: string} | null>(null);
  const [searchError, setSearchError] = useState("");

  const searchMutation = useMutation({
    mutationFn: (ticker: string) => validateTicker(ticker),
    onSuccess: (data) => {
      setSearchResult(data);
      setSearchError(data.valid ? "" : "Ticker not found on Yahoo Finance");
    },
    onError: () => setSearchError("Search failed"),
  });

  const addAssetMutation = useMutation({
    mutationFn: (data: { id: string; asset_class: string; name: string }) =>
      createAsset({ id: data.id, asset_class: data.asset_class as any, name: data.name }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["assets"] });
      setSearchTicker("");
      setSearchResult(null);
    },
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-white">Dashboard</h1>
        {analyze.isPending && (
          <span className="text-sm text-indigo-400 animate-pulse">
            Running analysis...
          </span>
        )}
      </div>

      {/* Market Pulse */}
      <div className="card">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white">Market Pulse</h2>
          <button
            onClick={() => bulkIngest.mutate()}
            disabled={bulkIngest.isPending}
            className="btn-secondary text-xs"
          >
            {bulkIngest.isPending ? "Scanning..." : "Scan All"}
          </button>
        </div>
        {bulkIngest.isSuccess && !bulkIngest.isPending && (
          <p className="mb-3 text-xs text-emerald-400">
            Scan complete — {bulkIngest.data.equities_succeeded + bulkIngest.data.crypto_succeeded} assets ingested
          </p>
        )}
        {bulkIngest.isError && (
          <p className="mb-3 text-xs text-red-400">Scan failed: {bulkIngest.error.message}</p>
        )}
        {dashSummary.isLoading ? (
          <p className="text-sm text-gray-500">Loading market pulse...</p>
        ) : dashSummary.data ? (
          <div className="space-y-4">
            {dashSummary.data.stale_assets.length > 0 && (
              <p className="text-xs text-yellow-400">
                Stale data: {dashSummary.data.stale_assets.join(", ")}
              </p>
            )}
            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <h3 className="mb-2 text-sm font-medium text-emerald-400">Top Opportunities</h3>
                {dashSummary.data.top_opportunities.length === 0 ? (
                  <p className="text-xs text-gray-500">No buy signals yet</p>
                ) : (
                  <div className="space-y-2">
                    {dashSummary.data.top_opportunities.map((item: DashboardOpportunity) => (
                      <Link
                        key={item.signal_id}
                        to={`/signals/${item.signal_id}`}
                        className="flex items-center justify-between rounded border border-emerald-900/50 bg-emerald-950/20 px-3 py-2 transition hover:border-emerald-700"
                      >
                        <div className="flex items-center gap-2">
                          <span className="font-mono text-xs font-bold text-white">{item.asset_id}</span>
                          <SignalBadge type={item.signal_type} />
                        </div>
                        <ConfidenceBar value={item.confidence} />
                      </Link>
                    ))}
                  </div>
                )}
              </div>
              <div>
                <h3 className="mb-2 text-sm font-medium text-red-400">Risk Alerts</h3>
                {dashSummary.data.top_risks.length === 0 ? (
                  <p className="text-xs text-gray-500">No sell signals</p>
                ) : (
                  <div className="space-y-2">
                    {dashSummary.data.top_risks.map((item: DashboardOpportunity) => (
                      <Link
                        key={item.signal_id}
                        to={`/signals/${item.signal_id}`}
                        className="flex items-center justify-between rounded border border-red-900/50 bg-red-950/20 px-3 py-2 transition hover:border-red-700"
                      >
                        <div className="flex items-center gap-2">
                          <span className="font-mono text-xs font-bold text-white">{item.asset_id}</span>
                          <SignalBadge type={item.signal_type} />
                        </div>
                        <ConfidenceBar value={item.confidence} />
                      </Link>
                    ))}
                  </div>
                )}
              </div>
            </div>
            <p className="text-xs text-gray-600">
              Tracking {dashSummary.data.total_tracked} assets
            </p>
          </div>
        ) : null}
      </div>

      {/* Portfolio Summary Cards */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <StatCard
          label="Total P&L"
          value={portfolio.data ? `$${portfolio.data.total_pnl.toFixed(2)}` : "—"}
          color={portfolio.data && portfolio.data.total_pnl >= 0 ? "text-emerald-400" : "text-red-400"}
        />
        <StatCard
          label="Realized"
          value={portfolio.data ? `$${portfolio.data.realized_pnl.toFixed(2)}` : "—"}
          color={portfolio.data && portfolio.data.realized_pnl >= 0 ? "text-emerald-400" : "text-red-400"}
        />
        <StatCard
          label="Win Rate"
          value={portfolio.data ? `${(portfolio.data.win_rate * 100).toFixed(1)}%` : "—"}
          color="text-indigo-400"
        />
        <StatCard
          label="Open Trades"
          value={portfolio.data ? String(portfolio.data.open_trades) : "—"}
          color="text-gray-300"
        />
      </div>

      {/* Add Asset */}
      <div className="card">
        <h2 className="mb-3 text-lg font-semibold text-white">Add Asset</h2>
        <div className="flex gap-2">
          <input
            type="text"
            value={searchTicker}
            onChange={(e) => setSearchTicker(e.target.value.toUpperCase())}
            onKeyDown={(e) => e.key === "Enter" && searchTicker && searchMutation.mutate(searchTicker)}
            placeholder="Search ticker (e.g. PLTR, SOL-USD)"
            className="flex-1 rounded border border-gray-700 bg-gray-800 px-3 py-2 text-sm text-white placeholder-gray-500 focus:border-indigo-500 focus:outline-none"
          />
          <button
            onClick={() => searchTicker && searchMutation.mutate(searchTicker)}
            disabled={!searchTicker || searchMutation.isPending}
            className="btn-secondary text-xs"
          >
            {searchMutation.isPending ? "..." : "Search"}
          </button>
        </div>
        {searchError && <p className="mt-2 text-xs text-red-400">{searchError}</p>}
        {searchResult?.valid && (
          <div className="mt-3 flex items-center justify-between rounded border border-gray-700 bg-gray-800/50 px-3 py-2">
            <div>
              <span className="font-mono text-sm font-bold text-white">{searchTicker}</span>
              <span className="ml-2 text-sm text-gray-400">{searchResult.name}</span>
              <span className="ml-2 rounded bg-gray-700 px-2 py-0.5 text-xs text-gray-400">{searchResult.asset_class}</span>
            </div>
            <button
              onClick={() => addAssetMutation.mutate({ id: searchTicker, asset_class: searchResult.asset_class!, name: searchResult.name! })}
              disabled={addAssetMutation.isPending}
              className="rounded bg-indigo-600 px-3 py-1 text-xs font-medium text-white hover:bg-indigo-500"
            >
              {addAssetMutation.isPending ? "Adding..." : "Add"}
            </button>
          </div>
        )}
        {addAssetMutation.isSuccess && (
          <p className="mt-2 text-xs text-emerald-400">Asset added successfully</p>
        )}
      </div>

      {/* Tracked Assets + Run Analysis */}
      <div className="card">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white">Tracked Assets</h2>
        </div>
        {assets.isLoading ? (
          <p className="text-sm text-gray-500">Loading assets...</p>
        ) : assets.data?.filter((a) => a.tracked).length === 0 ? (
          <p className="text-sm text-gray-500">
            No tracked assets. Add assets via <code className="text-indigo-400">POST /api/assets</code>.
          </p>
        ) : (
          <div className="flex flex-wrap gap-2">
            {assets.data
              ?.filter((a) => a.tracked)
              .map((asset) => (
                <button
                  key={asset.id}
                  onClick={() => analyze.mutate(asset.id)}
                  disabled={analyze.isPending}
                  className="btn-secondary flex items-center gap-2"
                  title={`Run analysis for ${asset.id}`}
                >
                  <span className="font-mono text-xs">{asset.id}</span>
                  <span className="text-xs text-gray-500">▶</span>
                </button>
              ))}
          </div>
        )}
        {analyze.isError && (
          <p className="mt-2 text-sm text-red-400">
            Analysis failed: {analyze.error.message}
          </p>
        )}
        {analyze.isSuccess && !analyze.isPending && (
          <p className="mt-2 text-sm text-emerald-400">
            ✓ Analysis complete — {analyze.data.signal_type.toUpperCase()} signal for{" "}
            {analyze.data.asset_id} (confidence: {(analyze.data.confidence * 100).toFixed(0)}%)
          </p>
        )}
      </div>

      {/* Recent Signals */}
      <div className="card">
        <h2 className="mb-4 text-lg font-semibold text-white">Recent Signals</h2>
        {signals.isLoading ? (
          <p className="text-sm text-gray-500">Loading signals...</p>
        ) : !signals.data?.length ? (
          <p className="text-sm text-gray-500">
            No signals yet. Run an analysis above to generate your first signal.
          </p>
        ) : (
          <div className="space-y-3">
            {signals.data.map((signal) => (
              <Link
                key={signal.id}
                to={`/signals/${signal.id}`}
                className="flex items-center justify-between rounded-lg border border-gray-800 p-4 transition hover:border-gray-700 hover:bg-gray-800/50"
              >
                <div className="flex items-center gap-4">
                  <span className="font-mono text-sm font-bold text-white">
                    {signal.asset_id}
                  </span>
                  <SignalBadge type={signal.signal_type} />
                </div>
                <div className="flex items-center gap-6">
                  <ConfidenceBar value={signal.confidence} />
                  <span className="text-xs text-gray-500">
                    {signal.created_at
                      ? new Date(signal.created_at).toLocaleDateString()
                      : "—"}
                  </span>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function StatCard({
  label,
  value,
  color,
}: {
  label: string;
  value: string;
  color: string;
}) {
  return (
    <div className="card flex flex-col">
      <span className="text-xs font-medium uppercase tracking-wider text-gray-500">
        {label}
      </span>
      <span className={`mt-1 text-2xl font-bold ${color}`}>{value}</span>
    </div>
  );
}
