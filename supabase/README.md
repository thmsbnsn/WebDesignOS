# Supabase Conventions

This directory is reserved for database schema, policies, and server-side logic. It is intentionally empty for now.

## RLS-first
- Enable RLS on all tables.
- Policies must be explicit and least-privilege.
- Avoid blanket `USING true` or `WITH CHECK true`.

## Changes
All future changes here must pass the security gate.
