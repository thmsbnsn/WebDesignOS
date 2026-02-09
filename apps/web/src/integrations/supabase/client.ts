export type SupabaseClientLike = unknown;

export function getSupabaseClient(): SupabaseClientLike {
  throw new Error(
    "Supabase client not configured. Env wiring is a separate step."
  );
}
