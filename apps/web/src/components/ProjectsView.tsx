import { Button } from "@/components/ui/button";
import { Plus, MoreHorizontal } from "lucide-react";

const projects = [
  { name: "MyLLM", status: "Active", lastDeploy: "2 min ago", checks: "PASS" },
  { name: "AuthProxy", status: "Active", lastDeploy: "1 hr ago", checks: "PASS" },
  { name: "DataPipeline", status: "Paused", lastDeploy: "3 days ago", checks: "WARN" },
  { name: "FrontendKit", status: "Active", lastDeploy: "12 hr ago", checks: "PASS" },
];

const ProjectsView = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-foreground">Projects</h2>
        <Button size="sm" className="gap-1.5">
          <Plus className="h-3.5 w-3.5" />
          Create Project
        </Button>
      </div>

      <div className="bg-card border border-border rounded-lg overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border">
              <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Name
              </th>
              <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Status
              </th>
              <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Last Deploy
              </th>
              <th className="text-left px-4 py-3 text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Checks
              </th>
              <th className="w-10"></th>
            </tr>
          </thead>
          <tbody>
            {projects.map((p) => (
              <tr key={p.name} className="border-b border-border last:border-0 hover:bg-surface/50 transition-colors">
                <td className="px-4 py-3 font-medium text-foreground">{p.name}</td>
                <td className="px-4 py-3">
                  <span className={`text-xs font-mono px-2 py-0.5 rounded ${
                    p.status === "Active"
                      ? "text-success bg-success/10"
                      : "text-warning bg-warning/10"
                  }`}>
                    {p.status}
                  </span>
                </td>
                <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{p.lastDeploy}</td>
                <td className="px-4 py-3">
                  <span className={`text-xs font-mono px-2 py-0.5 rounded ${
                    p.checks === "PASS"
                      ? "text-success bg-success/10"
                      : "text-warning bg-warning/10"
                  }`}>
                    {p.checks}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <MoreHorizontal className="h-4 w-4 text-muted-foreground" />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default ProjectsView;
