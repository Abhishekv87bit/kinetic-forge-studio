import { NavLink, Outlet } from "react-router-dom";

const NAV_ITEMS = [
  { to: "/", label: "Dashboard", icon: "📊" },
  { to: "/rules", label: "Golden Rules", icon: "⚖️" },
  { to: "/portfolio", label: "Portfolio", icon: "💼" },
  { to: "/alerts", label: "Alerts", icon: "🔔" },
  { to: "/backtests", label: "Backtests", icon: "📈" },
  { to: "/scores", label: "Signal Scores", icon: "🎯" },
];

export default function Layout() {
  return (
    <div className="flex h-screen">
      {/* Sidebar */}
      <nav className="flex w-56 flex-col border-r border-gray-800 bg-gray-900/50">
        <div className="flex h-16 items-center gap-2 border-b border-gray-800 px-5">
          <span className="text-xl">⚡</span>
          <span className="text-lg font-bold tracking-tight text-white">
            Alpha Pulse
          </span>
        </div>

        <div className="mt-4 flex flex-col gap-1 px-3">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === "/"}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition ${
                  isActive
                    ? "bg-indigo-600/20 text-indigo-400"
                    : "text-gray-400 hover:bg-gray-800 hover:text-gray-200"
                }`
              }
            >
              <span>{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </div>

        <div className="mt-auto border-t border-gray-800 p-4">
          <p className="text-xs text-gray-600">
            Not investment advice.
            <br />
            Research tool only.
          </p>
        </div>
      </nav>

      {/* Main content */}
      <main className="flex-1 overflow-auto p-6">
        <Outlet />
      </main>
    </div>
  );
}
