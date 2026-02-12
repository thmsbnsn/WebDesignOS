import { useState } from "react";
import LoginScreen from "@/components/LoginScreen";
import AppShell from "@/components/AppShell";

const Index = () => {
  const [authenticated, setAuthenticated] = useState(false);

  if (!authenticated) {
    return <LoginScreen onLogin={() => setAuthenticated(true)} />;
  }

  return <AppShell />;
};

export default Index;
