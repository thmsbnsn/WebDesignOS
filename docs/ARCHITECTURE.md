# Architecture

WebDesignOS is a local-first, deterministic system. The repo is intentionally minimal until security rules and generators are in place.

## Structure
- apps/web: future web UI (not scaffolded yet)
- supabase: database and server-side surface area (structure only)
- docs: project documentation
- tools: deterministic scripts, including the security gate

## Determinism
Changes that affect security-sensitive areas must pass the security gate.
