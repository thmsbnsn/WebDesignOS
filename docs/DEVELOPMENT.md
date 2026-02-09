# Development

## Requirements
- PowerShell 7+

## Security Gate
Run from repo root:
`pwsh -File .\tools\security\check.ps1`

## Web App (Local)
From repo root:
`cd apps/web`
`npm install`
`npm run dev`

## Notes
- No environment files are committed.
- No .env files are tracked in git.
- Client `VITE_*` usage is restricted by the security gate allowlist.
- Keep changes minimal and reversible.
