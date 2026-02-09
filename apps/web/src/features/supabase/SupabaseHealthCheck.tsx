import { useState } from "react";
import { getSupabaseClient } from "../../integrations/supabase";

type CheckStatus = "idle" | "checking" | "ok" | "error";

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}

export function SupabaseHealthCheck() {
  const [status, setStatus] = useState<CheckStatus>("idle");
  const [message, setMessage] = useState("");

  async function handleCheck() {
    setStatus("checking");
    setMessage("");

    try {
      const supabase = getSupabaseClient();
      const { error } = await supabase.auth.getSession();
      if (error) {
        throw error;
      }
      setStatus("ok");
      setMessage("OK: reached Supabase");
    } catch (error) {
      setStatus("error");
      setMessage(`Error: ${getErrorMessage(error)}`);
    }
  }

  return (
    <div>
      <button type="button" onClick={handleCheck} disabled={status === "checking"}>
        Check Supabase connection
      </button>
      {message ? <p>{message}</p> : null}
    </div>
  );
}
