import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Link } from "react-router-dom";
import Layout from "./components/Layout";
import Dashboard from "./pages/Dashboard";
import SignalDetail from "./pages/SignalDetail";
import Rules from "./pages/Rules";
import Portfolio from "./pages/Portfolio";
import Alerts from "./pages/Alerts";
import Backtests from "./pages/Backtests";
import SignalScores from "./pages/SignalScores";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000, // 30s before refetch
      retry: 1,
    },
  },
});

function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center gap-4 py-20">
      <h1 className="text-4xl font-bold text-gray-500">404</h1>
      <p className="text-gray-400">Page not found.</p>
      <Link to="/" className="text-indigo-400 hover:text-indigo-300">
        ← Back to Dashboard
      </Link>
    </div>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<Dashboard />} />
            <Route path="/signals/:id" element={<SignalDetail />} />
            <Route path="/rules" element={<Rules />} />
            <Route path="/portfolio" element={<Portfolio />} />
            <Route path="/alerts" element={<Alerts />} />
            <Route path="/backtests" element={<Backtests />} />
            <Route path="/scores" element={<SignalScores />} />
            <Route path="*" element={<NotFound />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
