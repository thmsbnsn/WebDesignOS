# WebDesignOS Security (Agent Output Folder)

This folder stores security governance artifacts for WebDesignOS.

- `SECURITY_RULEBOOK_v1.md` — human-readable rules
- `check-specs/v1/check-specs.json` — machine-checkable criteria derived from the rulebook
- `reports/` — PASS/FAIL outputs from scripts/CI

LLMs may write drafts here, but only deterministic tooling can mark PASS/FAIL.

# WebDesignOS Security Gate (v1)

## The one command
Run from repo root:

- Normal gate (shipping gate):
  pwsh -File .\tools\security\check.ps1

- Regression (prove the checker catches known-bad patterns):
  pwsh -File .\tools\security\check.ps1 -IncludeFixtures

## Exit codes
- 0 = PASS (no FAIL findings)
- 2 = FAIL (one or more FAIL findings)

## When the gate must be run
Mandatory before merge/release when changes touch any of:
- **/*.sql
- supabase/** (migrations, functions, policies, triggers)
- src/** (especially import.meta.env usage)
- tools/security/**
- .agents/security/check-specs/**

## Authority model
- Deterministic scripts decide PASS/FAIL.
- LLMs may propose changes, but cannot approve security-sensitive artifacts.

## Fixtures
- Default runs exclude fixtures.
- Use -IncludeFixtures to validate the gate itself.