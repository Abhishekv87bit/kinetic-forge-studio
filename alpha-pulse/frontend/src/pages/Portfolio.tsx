import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { fetchTrades, fetchPortfolioSummary, createManualTrade, closeTrade } from "../api/client";

export default function Portfolio() {
  const queryClient = useQueryClient();

  const summary = useQuery({
    queryKey: ["portfolio-summary"],
    queryFn: fetchPortfolioSummary,
  });
  const trades = useQuery({
    queryKey: ["trades"],
    queryFn: () => fetchTrades(),
  });

  // Manual trade form state
  const [assetId, setAssetId] = useState("");
  const [action, setAction] = useState<"buy" | "sell">("buy");
  const [quantity, setQuantity] = useState("");
  const [price, setPrice] = useState("");

  const manualTradeMut = useMutation({
    mutationFn: createManualTrade,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["trades"] });
      queryClient.invalidateQueries({ queryKey: ["portfolio-summary"] });
      setAssetId("");
      setQuantity("");
      setPrice("");
    },
  });

  const closeTradeMut = useMutation({
    mutationFn: ({ tradeId, closePrice }: { tradeId: number; closePrice: number }) =>
      closeTrade(tradeId, closePrice),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["trades"] });
      queryClient.invalidateQueries({ queryKey: ["portfolio-summary"] });
    },
  });

  const handleSubmitTrade = () => {
    const qty = parseFloat(quantity);
    const px = parseFloat(price);
    if (!assetId || isNaN(qty) || isNaN(px) || qty <= 0 || px <= 0) return;
    manualTradeMut.mutate({ asset_id: assetId, action, quantity: qty, price: px });
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-white">Paper Portfolio</h1>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <SummaryCard
          label="Total P&L"
          value={summary.data ? `$${summary.data.total_pnl.toFixed(2)}` : "—"}
          color={summary.data && summary.data.total_pnl >= 0 ? "text-emerald-400" : "text-red-400"}
        />
        <SummaryCard
          label="Realized"
          value={summary.data ? `$${summary.data.realized_pnl.toFixed(2)}` : "—"}
          color={summary.data && summary.data.realized_pnl >= 0 ? "text-emerald-400" : "text-red-400"}
        />
        <SummaryCard
          label="Unrealized"
          value={summary.data ? `$${summary.data.unrealized_pnl.toFixed(2)}` : "—"}
          color={summary.data && summary.data.unrealized_pnl >= 0 ? "text-emerald-400" : "text-red-400"}
        />
        <SummaryCard
          label="Win Rate"
          value={summary.data ? `${(summary.data.win_rate * 100).toFixed(1)}%` : "—"}
          color="text-indigo-400"
        />
      </div>

      {/* Manual Trade Entry */}
      <div className="card">
        <h2 className="mb-3 text-lg font-semibold text-white">Enter Trade</h2>
        <div className="flex flex-wrap items-end gap-3">
          <div>
            <label className="mb-1 block text-xs text-gray-500">Asset</label>
            <input
              type="text"
              value={assetId}
              onChange={(e) => setAssetId(e.target.value.toUpperCase())}
              placeholder="AAPL"
              className="w-28 rounded border border-gray-700 bg-gray-800 px-3 py-2 text-sm text-white placeholder-gray-500 focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs text-gray-500">Action</label>
            <div className="flex overflow-hidden rounded border border-gray-700">
              <button
                onClick={() => setAction("buy")}
                className={`px-3 py-2 text-xs font-medium ${
                  action === "buy"
                    ? "bg-emerald-600 text-white"
                    : "bg-gray-800 text-gray-400 hover:bg-gray-700"
                }`}
              >
                Buy
              </button>
              <button
                onClick={() => setAction("sell")}
                className={`px-3 py-2 text-xs font-medium ${
                  action === "sell"
                    ? "bg-red-600 text-white"
                    : "bg-gray-800 text-gray-400 hover:bg-gray-700"
                }`}
              >
                Sell
              </button>
            </div>
          </div>
          <div>
            <label className="mb-1 block text-xs text-gray-500">Quantity</label>
            <input
              type="number"
              value={quantity}
              onChange={(e) => setQuantity(e.target.value)}
              placeholder="10"
              min="0"
              step="any"
              className="w-24 rounded border border-gray-700 bg-gray-800 px-3 py-2 text-sm text-white placeholder-gray-500 focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs text-gray-500">Price</label>
            <input
              type="number"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              placeholder="150.00"
              min="0"
              step="any"
              className="w-28 rounded border border-gray-700 bg-gray-800 px-3 py-2 text-sm text-white placeholder-gray-500 focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <button
            onClick={handleSubmitTrade}
            disabled={manualTradeMut.isPending || !assetId || !quantity || !price}
            className="rounded bg-indigo-600 px-4 py-2 text-xs font-medium text-white hover:bg-indigo-500 disabled:opacity-50"
          >
            {manualTradeMut.isPending ? "..." : "Submit"}
          </button>
        </div>
        {manualTradeMut.isError && (
          <p className="mt-2 text-xs text-red-400">{manualTradeMut.error.message}</p>
        )}
        {manualTradeMut.isSuccess && !manualTradeMut.isPending && (
          <p className="mt-2 text-xs text-emerald-400">Trade recorded</p>
        )}
      </div>

      {/* Trades Table */}
      <div className="card overflow-hidden p-0">
        <div className="border-b border-gray-800 px-6 py-4">
          <h2 className="text-lg font-semibold text-white">All Trades</h2>
        </div>
        {trades.isLoading ? (
          <p className="p-6 text-sm text-gray-500">Loading trades...</p>
        ) : !trades.data?.length ? (
          <p className="p-6 text-sm text-gray-500">
            No trades yet. Enter a manual trade above or act on signals.
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="border-b border-gray-800 text-left text-xs uppercase text-gray-500">
                <tr>
                  <th className="px-6 py-3">Asset</th>
                  <th className="px-6 py-3">Action</th>
                  <th className="px-6 py-3">Qty</th>
                  <th className="px-6 py-3">Entry</th>
                  <th className="px-6 py-3">Current</th>
                  <th className="px-6 py-3">P&L</th>
                  <th className="px-6 py-3">Status</th>
                  <th className="px-6 py-3">Opened</th>
                  <th className="px-6 py-3"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-800">
                {trades.data.map((trade) => (
                  <tr key={trade.id} className="hover:bg-gray-800/30">
                    <td className="px-6 py-3 font-mono font-medium text-white">
                      {trade.asset_id}
                    </td>
                    <td className="px-6 py-3">
                      <span
                        className={`badge ${
                          trade.action === "buy"
                            ? "bg-emerald-900/50 text-emerald-400"
                            : "bg-red-900/50 text-red-400"
                        }`}
                      >
                        {trade.action.toUpperCase()}
                      </span>
                    </td>
                    <td className="px-6 py-3 text-gray-300">
                      {trade.quantity}
                    </td>
                    <td className="px-6 py-3 text-gray-300">
                      ${trade.price_at.toFixed(2)}
                    </td>
                    <td className="px-6 py-3 text-gray-300">
                      ${trade.price_now.toFixed(2)}
                    </td>
                    <td
                      className={`px-6 py-3 font-medium ${
                        trade.pnl >= 0 ? "text-emerald-400" : "text-red-400"
                      }`}
                    >
                      {trade.pnl >= 0 ? "+" : ""}${trade.pnl.toFixed(2)}
                    </td>
                    <td className="px-6 py-3">
                      <span
                        className={`badge ${
                          trade.status === "open"
                            ? "bg-indigo-900/50 text-indigo-400"
                            : "bg-gray-800 text-gray-500"
                        }`}
                      >
                        {trade.status}
                      </span>
                    </td>
                    <td className="px-6 py-3 text-gray-500">
                      {trade.opened_at
                        ? new Date(trade.opened_at).toLocaleDateString()
                        : "—"}
                    </td>
                    <td className="px-6 py-3">
                      {trade.status === "open" && (
                        <button
                          onClick={() =>
                            closeTradeMut.mutate({
                              tradeId: trade.id,
                              closePrice: trade.price_now,
                            })
                          }
                          disabled={closeTradeMut.isPending}
                          className="rounded bg-gray-700 px-2 py-1 text-xs text-gray-300 hover:bg-gray-600"
                        >
                          Close
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function SummaryCard({
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
