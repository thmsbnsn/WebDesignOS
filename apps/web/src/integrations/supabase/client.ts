import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    "Missing Supabase env vars. Create apps/web/.env.local from apps/web/.env.example and set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY."
  );
}

const supabaseClient = createClient(supabaseUrl, supabaseAnonKey);

export function getSupabaseClient(): SupabaseClient {
  return supabaseClient;
}
