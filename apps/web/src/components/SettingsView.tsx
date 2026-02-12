import { useState } from "react";
import { Switch } from "@/components/ui/switch";

const defaultSettings = [
  { id: "auto_scan", label: "Auto Security Scan", description: "Run security checks on every commit", default: true },
  { id: "notifications", label: "Notifications", description: "Email alerts for failed checks", default: false },
  { id: "telemetry", label: "Telemetry", description: "Send anonymous usage data", default: false },
  { id: "local_cache", label: "Local Cache", description: "Cache build artifacts locally", default: true },
  { id: "debug_mode", label: "Debug Mode", description: "Enable verbose logging output", default: false },
];

const SettingsView = () => {
  const [settings, setSettings] = useState<Record<string, boolean>>(
    Object.fromEntries(defaultSettings.map((s) => [s.id, s.default]))
  );

  const toggle = (id: string) => {
    setSettings((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">Settings</h2>

      <div className="bg-card border border-border rounded-lg divide-y divide-border">
        {defaultSettings.map((s) => (
          <div key={s.id} className="flex items-center justify-between px-5 py-4">
            <div>
              <p className="text-sm font-medium text-foreground">{s.label}</p>
              <p className="text-xs text-muted-foreground">{s.description}</p>
            </div>
            <Switch checked={settings[s.id]} onCheckedChange={() => toggle(s.id)} />
          </div>
        ))}
      </div>
    </div>
  );
};

export default SettingsView;
