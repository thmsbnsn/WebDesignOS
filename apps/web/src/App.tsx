import "./index.css";
import { SupabaseHealthCheck } from "./features/supabase/SupabaseHealthCheck";

function App() {
  return (
    <div className="app">
      <div className="app__header">
        <header>
          <h1>WebDesignOS</h1>
          <p>Minimal Vite + React + TypeScript scaffold.</p>
        </header>
        <SupabaseHealthCheck />
      </div>
    </div>
  );
}

export default App;
