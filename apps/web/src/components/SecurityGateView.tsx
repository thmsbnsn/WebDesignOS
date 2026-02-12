import { useState, useRef, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { Play, Loader2, ShieldCheck, ShieldX, AlertTriangle } from "lucide-react";
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table";

interface Finding {
  rule: string;
  severity: "Error" | "Warning" | "Info";
  file: string;
  description: string;
  status: "Open" | "Fixed";
}

const regressionFindings: Finding[] = [
  { rule: "SEC-001", severity: "Error", file: "src/api/auth.ts", description: "Hardcoded secret detected in source", status: "Open" },
  { rule: "SEC-014", severity: "Warning", file: "package.json", description: "Dependency with known CVE (lodash < 4.17.21)", status: "Open" },
  { rule: "SEC-027", severity: "Warning", file: "src/utils/crypto.ts", description: "Weak hashing algorithm (MD5) in use", status: "Open" },
];

const SecurityGateView = () => {
  const [status, setStatus] = useState<"IDLE" | "RUNNING" | "PASS" | "FAIL">("IDLE");
  const [checksRun, setChecksRun] = useState(0);
  const [findings, setFindings] = useState<Finding[]>([]);
  const [duration, setDuration] = useState("—");
  const [regression, setRegression] = useState(false);
  const [lines, setLines] = useState<string[]>([]);
  const [running, setRunning] = useState(false);
  const termRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (termRef.current) termRef.current.scrollTop = termRef.current.scrollHeight;
  }, [lines]);

  const runCheck = () => {
    setRunning(true);
    setStatus("RUNNING");
    setFindings([]);
    setLines([]);
    const ts = new Date().toLocaleTimeString();

    const outputLines = [
      `$ webdesignos security --check [${ts}]`,
      "[info] Loading project config...",
      "[info] Scanning dependencies...",
      "[info] Running OWASP checks...",
      "[info] Checking API surface...",
      "[info] Analyzing source files...",
    ];

    // Append lines over time
    let i = 0;
    const interval = setInterval(() => {
      if (i < outputLines.length) {
        setLines((prev) => [...prev, outputLines[i]]);
        i++;
      } else {
        clearInterval(interval);
        const willFail = regression;

        if (willFail) {
          setLines((prev) => [
            ...prev,
            "[fail] 3 findings detected.",
            "[fail] Security gate: FAIL",
            "",
          ]);
          setStatus("FAIL");
          setFindings(regressionFindings);
          setChecksRun((c) => c + 1);
          setDuration("4.2s");
        } else {
          setLines((prev) => [
            ...prev,
            "[pass] 0 issues detected.",
            "[pass] Security gate: PASS",
            "",
          ]);
          setStatus("PASS");
          setFindings([]);
          setChecksRun((c) => c + 1);
          setDuration("2.8s");
        }
        setRunning(false);
      }
    }, 250);
  };

  const severityColor: Record<string, string> = {
    Error: "bg-destructive/10 text-destructive border-destructive/20",
    Warning: "bg-warning/10 text-warning border-warning/20",
    Info: "bg-muted text-muted-foreground",
  };

  const StatusIcon = status === "FAIL" ? ShieldX : status === "RUNNING" ? Loader2 : ShieldCheck;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-foreground">Security Gate</h2>
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <Switch id="regression" checked={regression} onCheckedChange={setRegression} />
            <Label htmlFor="regression" className="text-xs text-muted-foreground cursor-pointer">
              Regression Mode
            </Label>
          </div>
          <Button size="sm" onClick={runCheck} disabled={running} className="gap-1.5">
            {running ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Play className="h-3.5 w-3.5" />}
            {running ? "Running..." : "Run Check"}
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-5 pb-4 px-4">
            <p className="text-xs text-muted-foreground mb-1">Overall Status</p>
            <div className="flex items-center gap-2">
              <StatusIcon className={`h-5 w-5 ${status === "FAIL" ? "text-destructive" : status === "RUNNING" ? "text-primary animate-spin" : status === "PASS" ? "text-success" : "text-muted-foreground"}`} />
              <span className={`text-sm font-semibold ${status === "FAIL" ? "text-destructive" : status === "PASS" ? "text-success" : "text-foreground"}`}>
                {status === "IDLE" ? "Not Run" : status}
              </span>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4 px-4">
            <p className="text-xs text-muted-foreground mb-1">Checks Run</p>
            <span className="text-sm font-semibold text-foreground">{checksRun}</span>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4 px-4">
            <p className="text-xs text-muted-foreground mb-1">Findings</p>
            <div className="flex items-center gap-1.5">
              {findings.length > 0 && <AlertTriangle className="h-4 w-4 text-warning" />}
              <span className={`text-sm font-semibold ${findings.length > 0 ? "text-warning" : "text-foreground"}`}>
                {findings.length}
              </span>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4 px-4">
            <p className="text-xs text-muted-foreground mb-1">Duration</p>
            <span className="text-sm font-semibold text-foreground">{duration}</span>
          </CardContent>
        </Card>
      </div>

      {/* Findings Table */}
      {findings.length > 0 && (
        <div className="space-y-2">
          <h3 className="text-sm font-medium text-foreground">Findings</h3>
          <div className="border border-border rounded-lg overflow-hidden">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Rule ID</TableHead>
                  <TableHead>Severity</TableHead>
                  <TableHead>File</TableHead>
                  <TableHead>Description</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {findings.map((f, i) => (
                  <TableRow key={i}>
                    <TableCell className="font-mono text-xs">{f.rule}</TableCell>
                    <TableCell>
                      <Badge variant="outline" className={severityColor[f.severity]}>{f.severity}</Badge>
                    </TableCell>
                    <TableCell className="font-mono text-xs text-muted-foreground">{f.file}</TableCell>
                    <TableCell className="text-xs">{f.description}</TableCell>
                    <TableCell>
                      <Badge variant="outline">{f.status}</Badge>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </div>
      )}

      {/* Raw Output */}
      <div className="space-y-2">
        <h3 className="text-sm font-medium text-foreground">Raw Output</h3>
        <div
          ref={termRef}
          className="bg-card border border-border rounded-lg p-4 font-mono text-xs leading-relaxed max-h-[300px] overflow-y-auto"
        >
          {lines.length === 0 && !running && (
            <span className="text-muted-foreground">Run a check to see output…</span>
          )}
          {lines.map((line, i) => (
            <div key={i} className={
              line.startsWith("[pass]") ? "text-success"
              : line.startsWith("[fail]") ? "text-destructive"
              : line.startsWith("[info]") ? "text-muted-foreground"
              : line.startsWith("$") ? "text-primary"
              : "text-foreground"
            }>
              {line || "\u00A0"}
            </div>
          ))}
          {running && <div className="text-primary animate-pulse">▋</div>}
        </div>
      </div>
    </div>
  );
};

export default SecurityGateView;
