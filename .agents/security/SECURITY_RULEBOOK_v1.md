## WebDesignOS Security Rulebook v1 (Deterministic, Enforceable)

This rulebook defines security constraints that are **explicit**, **script-checkable**, and **release-blocking**.
LLMs may propose changes, but **deterministic checks decide PASS/FAIL**.

### Rule 1 — Server is the Authority
**Rule:** Authorization must be enforced server-side (DB RLS + RPC/Edge/server routes), never trusted to the client.  
**Why:** Clients can be modified; requests can be forged.  
**Enforced by:** Policy + static checks for client-only gating patterns.

### Rule 2 — RLS On By Default
**Rule:** Every table in `public` must have RLS enabled and at least one policy.  
**Why:** Missing RLS is a common catastrophic misconfig.  
**Enforced by:** SQL gatekeeper lint (migration scan).

### Rule 3 — No Self Role Escalation
**Rule:** Users can never grant/upgrade their own roles/permissions.  
**Why:** Prevent “update your own role to admin.”  
**Enforced by:** SQL gatekeeper detects role/permission write patterns.

### Rule 4 — Profiles Are Not Permissions
**Rule:** User-editable profile fields are not trusted authorization sources.  
**Why:** If the user can edit it, it’s not a permission system.  
**Enforced by:** Policy + gatekeeper checks for writable role fields in profiles.

### Rule 5 — Policies Must Bind to `auth.uid()`
**Rule:** RLS policies must bind access to `auth.uid()` and verified membership tables.  
**Why:** Prevent “guess an ID” access.  
**Enforced by:** Policy lint patterns for missing `auth.uid()`.

### Rule 6 — SECURITY DEFINER is Deny-by-Default
**Rule:** `SECURITY DEFINER` is banned unless it passes strict requirements.  
**Why:** It can bypass RLS and become an escalation vector.  
**Enforced by:** Gatekeeper: require safe `search_path`, ban unsafe patterns.

### Rule 7 — Safe search_path Required
**Rule:** Functions (especially SECURITY DEFINER) must set a safe `search_path`.  
**Why:** Prevent search_path hijacks.  
**Enforced by:** Gatekeeper: require `SET search_path = pg_catalog, public` (or stricter).

### Rule 8 — Triggers Must Be Idempotent
**Rule:** Trigger inserts must be idempotent (`ON CONFLICT DO NOTHING` or equivalent).  
**Why:** Retries happen; duplicates break ownership/roles.  
**Enforced by:** Gatekeeper trigger lint.

### Rule 9 — Migrations Must Be Safe to Re-Run
**Rule:** Migrations must be idempotent or guarded.  
**Why:** Local-first + CI replays migrations.  
**Enforced by:** Gatekeeper: flag non-guarded creates/policies/triggers.

### Rule 10 — No Secrets in Repo/Logs/Agent Outputs
**Rule:** Secrets never enter Git, `.agents/`, logs, or outputs.  
**Why:** Leaks are permanent.  
**Enforced by:** Secret scan + workflow policy.

### Rule 11 — Service Role Key is Server-Only
**Rule:** Service role key must never ship to client code.  
**Why:** It’s god-mode.  
**Enforced by:** Client code scan for key patterns + env var naming rules.

### Rule 12 — Client Env Vars Must Be Allowlisted
**Rule:** Only allowlisted `VITE_` vars may be used in client.  
**Why:** Prevent accidental exposure of sensitive vars.  
**Enforced by:** Env usage scan + allowlist file.

### Rule 13 — Audit Privileged Actions
**Rule:** Privileged changes must write immutable audit events.  
**Why:** Forensics beats vibes.  
**Enforced by:** Workflow requirement + later lint markers.

### Rule 14 — AI May Propose, Never Approve
**Rule:** LLM outputs cannot approve/reject security-sensitive artifacts.  
**Why:** Overconfidence + hallucinations.  
**Enforced by:** Workflow: only deterministic checks gate release.

### Rule 15 — Violations Block Merge/Release
**Rule:** Any FAIL from rule checks blocks shipping.  
**Why:** Exceptions become the baseline.  
**Enforced by:** CI gate + local gate scripts.