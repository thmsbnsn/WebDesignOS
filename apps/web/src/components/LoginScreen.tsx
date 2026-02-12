import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Terminal } from "lucide-react";

interface LoginScreenProps {
  onLogin: () => void;
}

const LoginScreen = ({ onLogin }: LoginScreenProps) => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="w-full max-w-sm space-y-8 px-4">
        <div className="text-center space-y-2">
          <div className="flex items-center justify-center gap-2 mb-6">
            <Terminal className="h-7 w-7 text-primary" />
            <h1 className="text-2xl font-semibold tracking-tight text-foreground">
              WebDesignOS
            </h1>
          </div>
          <p className="text-sm text-muted-foreground font-mono">
            Local-First SaaS Architecture
          </p>
        </div>

        <div className="space-y-4 bg-card border border-border rounded-lg p-6 shadow-sm">
          <div className="space-y-2">
            <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
              Email
            </label>
            <Input
              type="email"
              placeholder="you@company.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="bg-background border-border"
            />
          </div>
          <div className="space-y-2">
            <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
              Password
            </label>
            <Input
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="bg-background border-border"
            />
          </div>
          <Button onClick={onLogin} className="w-full">
            Sign In
          </Button>
          <Button onClick={onLogin} variant="ghost" className="w-full text-muted-foreground">
            Continue in Demo Mode
          </Button>
        </div>

        <p className="text-center text-xs text-muted-foreground">
          No data leaves your machine.
        </p>
      </div>
    </div>
  );
};

export default LoginScreen;
