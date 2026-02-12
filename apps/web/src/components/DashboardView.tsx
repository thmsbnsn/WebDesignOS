import { Shield, GitBranch, MonitorCheck, Clock } from "lucide-react";

const statusItems = [
  { label: "Security Gate", status: "PASS", icon: Shield },
  { label: "CI", status: "PASS", icon: GitBranch },
  { label: "Local Check", status: "PASS", icon: MonitorCheck },
];

const activityItems = [
  { time: "2 min ago", text: "Security scan completed — all checks passed" },
  { time: "14 min ago", text: "Project 'MyLLM' deployed to staging" },
  { time: "1 hr ago", text: "New API key generated for production" },
  { time: "3 hr ago", text: "CI pipeline #482 succeeded" },
  { time: "5 hr ago", text: "Config updated: rate limiting enabled" },
];

const DashboardView = () => {
  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">Dashboard</h2>

      <div className="bg-card border border-border rounded-lg p-5">
        <h3 className="text-sm font-medium text-muted-foreground uppercase tracking-wider mb-4">
          System Status
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {statusItems.map((item) => (
            <div
              key={item.label}
              className="flex items-center gap-3 bg-surface rounded-md p-3 border border-border"
            >
              <item.icon className="h-4 w-4 text-muted-foreground" />
              <div className="flex-1">
                <p className="text-sm text-foreground">{item.label}</p>
              </div>
              <span className="text-xs font-mono font-medium text-success bg-success/10 px-2 py-0.5 rounded">
                {item.status}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-card border border-border rounded-lg p-5">
        <h3 className="text-sm font-medium text-muted-foreground uppercase tracking-wider mb-4">
          Recent Activity
        </h3>
        <div className="space-y-3">
          {activityItems.map((item, i) => (
            <div key={i} className="flex items-start gap-3 text-sm">
              <Clock className="h-3.5 w-3.5 text-muted-foreground mt-0.5 shrink-0" />
              <span className="text-muted-foreground font-mono text-xs w-20 shrink-0">
                {item.time}
              </span>
              <span className="text-foreground">{item.text}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default DashboardView;
