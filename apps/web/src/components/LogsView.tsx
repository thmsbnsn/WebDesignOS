const logEntries = [
  { ts: "12:04:32", level: "INFO", msg: "Server started on port 3000" },
  { ts: "12:04:33", level: "INFO", msg: "Connected to local database" },
  { ts: "12:04:35", level: "INFO", msg: "Security module initialized" },
  { ts: "12:05:01", level: "DEBUG", msg: "Auth middleware loaded" },
  { ts: "12:05:02", level: "INFO", msg: "Rate limiter configured: 100 req/min" },
  { ts: "12:06:11", level: "INFO", msg: "Health check endpoint active" },
  { ts: "12:07:44", level: "WARN", msg: "Deprecated config key detected: 'legacy_mode'" },
  { ts: "12:08:22", level: "INFO", msg: "CI webhook registered" },
  { ts: "12:09:00", level: "DEBUG", msg: "Cache warmed: 24 entries loaded" },
  { ts: "12:10:15", level: "INFO", msg: "Deployment snapshot saved" },
  { ts: "12:11:03", level: "INFO", msg: "All systems nominal" },
];

const levelColor: Record<string, string> = {
  INFO: "text-muted-foreground",
  DEBUG: "text-primary",
  WARN: "text-warning",
  ERROR: "text-destructive",
};

const LogsView = () => {
  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">Logs</h2>

      <div className="bg-card border border-border rounded-lg p-4 font-mono text-xs leading-loose max-h-[500px] overflow-y-auto">
        {logEntries.map((entry, i) => (
          <div key={i} className="flex gap-3">
            <span className="text-muted-foreground shrink-0">{entry.ts}</span>
            <span className={`shrink-0 w-12 ${levelColor[entry.level] ?? "text-foreground"}`}>
              {entry.level}
            </span>
            <span className="text-foreground">{entry.msg}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default LogsView;
