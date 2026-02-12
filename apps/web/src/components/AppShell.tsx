import { useState } from "react";
import {
  LayoutDashboard,
  FolderKanban,
  ShieldCheck,
  ScrollText,
  Settings,
  Terminal,
  Loader2,
  User,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import DashboardView from "./DashboardView";
import ProjectsView from "./ProjectsView";
import SecurityGateView from "./SecurityGateView";
import LogsView from "./LogsView";
import SettingsView from "./SettingsView";

const navItems = [
  { id: "dashboard", label: "Dashboard", icon: LayoutDashboard },
  { id: "projects", label: "Projects", icon: FolderKanban },
  { id: "security", label: "Security Gate", icon: ShieldCheck },
  { id: "logs", label: "Logs", icon: ScrollText },
  { id: "settings", label: "Settings", icon: Settings },
] as const;

type View = (typeof navItems)[number]["id"];

const viewComponents: Record<View, React.FC> = {
  dashboard: DashboardView,
  projects: ProjectsView,
  security: SecurityGateView,
  logs: LogsView,
  settings: SettingsView,
};

const AppShell = () => {
  const [activeView, setActiveView] = useState<View>("dashboard");
  const [headerLoading, setHeaderLoading] = useState(false);
  const [headerStatus, setHeaderStatus] = useState("PASS");

  const runHeaderCheck = () => {
    setHeaderLoading(true);
    setHeaderStatus("...");
    setTimeout(() => {
      setHeaderStatus("PASS");
      setHeaderLoading(false);
    }, 1500);
  };

  const ActiveComponent = viewComponents[activeView];

  return (
    <div className="flex h-screen bg-background">
      {/* Sidebar */}
      <aside className="w-56 shrink-0 border-r border-border bg-sidebar flex flex-col">
        <div className="flex items-center gap-2 px-5 py-4 border-b border-sidebar-border">
          <Terminal className="h-5 w-5 text-primary" />
          <span className="text-sm font-semibold text-foreground tracking-tight">
            WebDesignOS
          </span>
        </div>
        <nav className="flex-1 py-3 px-3 space-y-0.5">
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => setActiveView(item.id)}
              className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-md text-sm transition-colors ${
                activeView === item.id
                  ? "bg-sidebar-accent text-sidebar-accent-foreground font-medium"
                  : "text-sidebar-foreground hover:bg-sidebar-accent/50 hover:text-sidebar-accent-foreground"
              }`}
            >
              <item.icon className="h-4 w-4 shrink-0" />
              {item.label}
            </button>
          ))}
        </nav>
      </aside>

      {/* Main area */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Header */}
        <header className="h-13 shrink-0 border-b border-border bg-card flex items-center justify-between px-5">
          <div className="flex items-center gap-3">
            <span className="text-sm font-medium text-foreground">MyLLM</span>
            <span className={`text-xs font-mono px-2 py-0.5 rounded ${
              headerStatus === "PASS"
                ? "text-success bg-success/10"
                : "text-muted-foreground bg-muted"
            }`}>
              {headerStatus}
            </span>
          </div>
          <div className="flex items-center gap-3">
            <Button
              size="sm"
              variant="outline"
              onClick={runHeaderCheck}
              disabled={headerLoading}
              className="gap-1.5 text-xs"
            >
              {headerLoading && <Loader2 className="h-3 w-3 animate-spin" />}
              Run Security Check
            </Button>
            <div className="h-7 w-7 rounded-full bg-muted flex items-center justify-center">
              <User className="h-3.5 w-3.5 text-muted-foreground" />
            </div>
          </div>
        </header>

        {/* Content */}
        <main className="flex-1 overflow-y-auto p-6">
          <ActiveComponent />
        </main>
      </div>
    </div>
  );
};

export default AppShell;
