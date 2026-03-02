import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { fetchAssets, fetchSignals } from "../api/client";
import type { AssetClass, Signal } from "../api/types";
import SignalBadge from "../components/SignalBadge";
import ConfidenceBar from "../components/ConfidenceBar";

type SortKey = "asset_id" | "signal_type" | "confidence";
type SortDir = "asc" | "desc";

export default function SignalScores() {
  const [filter, setFilter] = useState<AssetClass | "all">("all");
  const [sortKey, setSortKey] = useState<SortKey>("confidence");
  const [sortDir, setSortDir] = useState<SortDir>("desc");

  const assets = useQuery({ queryKey: ["assets"], queryFn: fetchAssets });
  const signals = useQuery({ queryKey: ["signals"], queryFn: () => fetchSignals({ limit: 200 }) });

  // Build latest signal per asset
  const latestByAsset = new Map<string, Signal>();
  if (signals.data) {
    for (const sig of signals.data) {
      const existing = latestByAsset.get(sig.asset_id);
      if (!existing || sig.id > existing.id) {
        latestByAsset.set(sig.asset_id, sig);
      }
    }
  }

  // Filter and sort
  const rows = (assets.data ?? [])
    .filter((a) => a.tracked)
    .filter((a) => filter === "all" || a.asset_class === filter)
    .map((a) => ({
      asset: a,
      signal: latestByAsset.get(a.id) ?? null,
    }))
    .sort((a, b) => {
      const dir = sortDir === "asc" ? 1 : -1;
      if (sortKey === "asset_id") {
        return dir * a.asset.id.localeCompare(b.asset.id);
      }
      if (sortKey === "signal_type") {
        const aType = a.signal?.signal_type ?? "";
        const bType = b.signal?.signal_type ?? "";
        return dir * aType.localeCompare(bType);
      }
      // confidence
      const aC = a.signal?.confidence ?? 0;
      const bC = b.signal?.confidence ?? 0;
      return dir * (aC - bC);
    });

  const handleSort = (key: SortKey) => {
    if (sortKey === key) {
      setSortDir(sortDir === "asc" ? "desc" : "asc");
    } else {
      setSortKey(key);
      setSortDir("desc");
    }
  };

  const sortIcon = (key: SortKey) => {
    if (sortKey !== key) return "";
    return sortDir === "asc" ? " ↑" : " ↓";
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-white">Signal Scores</h1>
        <div className="flex gap-2">
          {(["all", "equity", "crypto"] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`rounded px-3 py-1 text-xs font-medium transition ${
                filter === f
                  ? "bg-indigo-600 text-white"
                  : "bg-gray-800 text-gray-400 hover:text-gray-200"
              }`}
            >
              {f === "all" ? "All" : f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {assets.isLoading || signals.isLoading ? (
        <p className="text-sm text-gray-500">Loading scores...</p>
      ) : rows.length === 0 ? (
        <p className="text-sm text-gray-500">No tracked assets found.</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-gray-800 text-xs uppercase tracking-wider text-gray-500">
                <th
                  className="cursor-pointer px-4 py-3 hover:text-gray-300"
                  onClick={() => handleSort("asset_id")}
                >
                  Asset{sortIcon("asset_id")}
                </th>
                <th className="px-4 py-3">Class</th>
                <th
                  className="cursor-pointer px-4 py-3 hover:text-gray-300"
                  onClick={() => handleSort("signal_type")}
                >
                  Signal{sortIcon("signal_type")}
                </th>
                <th
                  className="cursor-pointer px-4 py-3 hover:text-gray-300"
                  onClick={() => handleSort("confidence")}
                >
                  Confidence{sortIcon("confidence")}
                </th>
                <th className="px-4 py-3">Summary</th>
                <th className="px-4 py-3">Date</th>
              </tr>
            </thead>
            <tbody>
              {rows.map(({ asset, signal }) => (
                <tr
                  key={asset.id}
                  className="border-b border-gray-800/50 transition hover:bg-gray-800/30"
                >
                  <td className="px-4 py-3">
                    <span className="font-mono text-sm font-bold text-white">{asset.id}</span>
                  </td>
                  <td className="px-4 py-3">
                    <span className="rounded bg-gray-800 px-2 py-0.5 text-xs text-gray-400">
                      {asset.asset_class}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    {signal ? (
                      <Link to={`/signals/${signal.id}`}>
                        <SignalBadge type={signal.signal_type} />
                      </Link>
                    ) : (
                      <span className="text-xs text-gray-600">—</span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {signal ? (
                      <ConfidenceBar value={signal.confidence} />
                    ) : (
                      <span className="text-xs text-gray-600">—</span>
                    )}
                  </td>
                  <td className="max-w-xs truncate px-4 py-3 text-xs text-gray-400">
                    {signal?.summary ?? "No analysis yet"}
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-500">
                    {signal?.created_at
                      ? new Date(signal.created_at).toLocaleDateString()
                      : "—"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
