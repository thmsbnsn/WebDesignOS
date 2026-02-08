<#
WebDesignOS File Writer
- Deterministically writes project files to disk
- Uses an embedded manifest (paths + content)
- Safe defaults: creates directories, writes UTF-8
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [switch]$DryRun,

  [Parameter(Mandatory = $false)]
  [switch]$NoClobber
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-TextFile {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$Content
  )

  $dir = Split-Path -Parent $Path
  if ($dir -and !(Test-Path $dir)) {
    if ($DryRun) { Write-Host "[DRYRUN] mkdir $dir" }
    else { New-Item -ItemType Directory -Force $dir | Out-Null }
  }

  if ($NoClobber -and (Test-Path $Path)) {
    Write-Host "[SKIP] Exists (NoClobber): $Path"
    return
  }

  if ($DryRun) {
    Write-Host "[DRYRUN] write $Path"
    return
  }

  # UTF-8 (no BOM) for predictable diffs
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
  Write-Host "[WROTE] $Path"
}

# -----------------------------
# MANIFEST: add/update files here
# -----------------------------
$Files = @(
  @{
    path = ".agents\security\SECURITY_RULEBOOK_v1.md"
    content = @'
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
'@
  },
  @{
    path = ".agents\security\README.md"
    content = @'
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
'@
  },
  @{
    path = "SECURITY_GATE.md"
    content = @'
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
'@
  },
  @{
    path = "README.md"
    content = @'
# WebDesignOS

WebDesignOS is a local-first, deterministic, multi-agent system for building SaaS apps. It is security-by-construction and enforced by deterministic gates.

LLMs may propose changes. Deterministic scripts decide PASS/FAIL.

## Security Gate
The one command that matters:

pwsh -File .\tools\security\check.ps1
'@
  },
  @{
    path = ".agents\security\check-specs\v1\check-specs.json"
    content = @'
{
  "version": "1.0.0",
  "generated_from": "SECURITY_RULEBOOK_v1.md",
  "scope": {
    "repo_root": ".",
    "excluded_globs": [
      "**/node_modules/**",
      "**/.git/**",
      "**/dist/**",
      "**/build/**",
      "**/.next/**",
      "**/.turbo/**",
      "**/.cache/**"
    ]
  },
  "rules": [
    {
      "id": "WDSO-RLS-001",
      "title": "RLS must be enabled for public tables created in migrations",
      "why": "Missing RLS is a common catastrophic misconfig.",
      "severity": "FAIL",
      "targets": { "globs": ["**/*.sql"] },
      "checks": [
        {
          "type": "regex_pair_required",
          "description": "If a file creates a public table, it must enable RLS in the same file.",
          "if_regex": "(?is)\\bcreate\\s+table\\s+public\\.",
          "then_regex": "(?is)\\balter\\s+table\\s+public\\.[^;]+\\s+enable\\s+row\\s+level\\s+security\\b"
        }
      ]
    },
    {
      "id": "WDSO-RLS-002",
      "title": "Policies should bind access to auth.uid()",
      "why": "Prevents guessing IDs for access.",
      "severity": "WARN",
      "targets": { "globs": ["**/*.sql"] },
      "checks": [
        {
          "type": "regex_if_not_contains",
          "description": "If a file defines RLS policies, prefer policies referencing auth.uid().",
          "if_regex": "(?is)\\bcreate\\s+policy\\b",
          "must_contain_regex": "(?is)\\bauth\\.uid\\(\\)\\b"
        }
      ]
    },
    {
      "id": "WDSO-ROLE-001",
      "title": "Self-role escalation patterns are forbidden",
      "why": "Users must not be able to set or elevate their own roles/tiers/permissions.",
      "severity": "FAIL",
      "targets": { "globs": ["**/*.sql"] },
      "checks": [
        {
          "type": "regex_forbidden",
          "description": "Block updates/inserts to role-like columns on user-controlled tables.",
          "forbidden_regexes": [
            "(?is)\\bupdate\\s+(?:public\\.)?(profiles|memberships|roles|permissions|billing|plans|subscriptions|audit)\\b[\\s\\S]*?\\bset\\b[\\s\\S]*?\\b(role|is_admin|admin|tier|plan|account_type|permission[a-z0-9_]*)\\b",
            "(?is)\\binsert\\s+into\\s+(?:public\\.)?(profiles|memberships|roles|permissions|billing|plans|subscriptions|audit)\\b\\s*\\([^)]*\\b(role|is_admin|admin|tier|plan|account_type|permission[a-z0-9_]*)\\b[^)]*\\)"
          ]
        }
      ]
    },
    {
      "id": "WDSO-FN-001",
      "title": "SECURITY DEFINER functions must set a safe search_path",
      "why": "Prevents search_path hijacks and RLS bypass surprises.",
      "severity": "FAIL",
      "targets": { "globs": ["**/*.sql"] },
      "checks": [
        {
          "type": "regex_pair_required",
          "description": "If SECURITY DEFINER exists, require SET search_path = pg_catalog, public (or stricter).",
          "if_regex": "(?is)\\bsecurity\\s+definer\\b",
          "then_regex": "(?is)\\bset\\s+search_path\\s*=\\s*pg_catalog\\s*,\\s*public\\b"
        }
      ]
    },
    {
      "id": "WDSO-FN-002",
      "title": "SECURITY DEFINER requires explicit allowlist marker",
      "why": "SECURITY DEFINER is dangerous unless explicitly justified.",
      "severity": "FAIL",
      "targets": { "globs": ["**/*.sql"] },
      "checks": [
        {
          "type": "regex_pair_required",
          "description": "If SECURITY DEFINER exists, require a WDSO_ALLOW_SECURITY_DEFINER marker comment with a reason.",
          "if_regex": "(?is)\\bsecurity\\s+definer\\b",
          "then_regex": "(?m)^\\s*--\\s*WDSO_ALLOW_SECURITY_DEFINER\\s*:\\s*.+$"
        }
      ]
    },
    {
      "id": "WDSO-FN-003",
      "title": "Dynamic SQL in SECURITY DEFINER requires explicit allowlist marker",
      "why": "EXECUTE in SECURITY DEFINER can bypass safeguards unless explicitly justified.",
      "severity": "FAIL",
      "targets": { "globs": ["**/*.sql"] },
      "checks": [
        {
          "type": "regex_pair_required",
          "description": "If SECURITY DEFINER contains EXECUTE, require a WDSO_ALLOW_DYNAMIC_SQL marker comment with a reason.",
          "if_regex": "(?is)\\bsecurity\\s+definer\\b[\\s\\S]*?\\bexecute\\b",
          "then_regex": "(?m)^\\s*--\\s*WDSO_ALLOW_DYNAMIC_SQL\\s*:\\s*.+$"
        }
      ]
    },
    {
      "id": "WDSO-TRG-001",
      "title": "Trigger inserts should be idempotent",
      "why": "Retries happen; duplicates break ownership/roles.",
      "severity": "FAIL",
      "targets": { "globs": ["**/*.sql"] },
      "checks": [
        {
          "type": "regex_pair_required",
          "description": "If a trigger function performs INSERT, it should contain ON CONFLICT or another idempotent guard.",
          "if_regex": "(?is)\\bcreate\\s+(or\\s+replace\\s+)?function\\b[\\s\\S]*?\\blanguage\\s+plpgsql\\b[\\s\\S]*?\\bas\\s+\\$\\$[\\s\\S]*?\\binsert\\b",
          "then_regex": "(?is)\\bon\\s+conflict\\b|\\bwhere\\s+not\\s+exists\\b"
        }
      ]
    },
    {
      "id": "WDSO-RLS-003",
      "title": "RLS footgun: USING true / WITH CHECK true on sensitive tables",
      "why": "Always-true policies on sensitive tables effectively disable RLS.",
      "severity": "FAIL",
      "targets": { "globs": ["**/*.sql"] },
      "checks": [
        {
          "type": "regex_forbidden",
          "description": "Block always-true RLS policies on sensitive tables.",
          "forbidden_regexes": [
            "(?is)\\bcreate\\s+policy\\b[\\s\\S]*?\\bon\\s+(?:public\\.)?(profiles|memberships|roles|permissions|billing|plans|subscriptions|audit)\\b[\\s\\S]*?\\busing\\s*\\(\\s*true\\s*\\)",
            "(?is)\\bcreate\\s+policy\\b[\\s\\S]*?\\bon\\s+(?:public\\.)?(profiles|memberships|roles|permissions|billing|plans|subscriptions|audit)\\b[\\s\\S]*?\\bwith\\s+check\\s*\\(\\s*true\\s*\\)"
          ]
        }
      ]
    },
    {
      "id": "WDSO-ENV-001",
      "title": "Client env vars must be allowlisted",
      "why": "Prevents accidental secret exposure via VITE_ variables.",
      "severity": "FAIL",
      "targets": { "globs": ["src/**/*.ts", "src/**/*.tsx", "src/**/*.js", "src/**/*.jsx"] },
      "checks": [
        {
          "type": "vite_env_allowlist",
          "description": "All import.meta.env.VITE_* must be present in tools/security/allowlists/client_env_allowlist.txt",
          "allowlist_path": "tools/security/allowlists/client_env_allowlist.txt"
        }
      ]
    },
    {
      "id": "WDSO-KEY-001",
      "title": "Service role key must not appear in client code",
      "why": "Service role is god-mode and must never ship to the client.",
      "severity": "FAIL",
      "targets": { "globs": ["src/**/*.*"] },
      "checks": [
        {
          "type": "regex_forbidden",
          "description": "Block common service role key patterns and references in client source.",
          "forbidden_regexes": [
            "(?i)service[_-]?role",
            "(?i)SUPABASE_SERVICE_ROLE_KEY",
            "(?i)serviceRoleKey"
          ]
        }
      ]
    },
    {
      "id": "WDSO-SECRET-001",
      "title": "No secrets committed to repo or agent outputs",
      "why": "Leaks are permanent and multiply in multi-agent systems.",
      "severity": "FAIL",
      "targets": { "globs": ["**/*.*"] },
      "checks": [
        {
          "type": "secret_scan",
          "description": "Scan for common credential patterns and high-risk tokens.",
          "patterns_path": "tools/security/secret-patterns.txt",
          "exclude_globs": [
            "**/.env",
            "**/.env.*",
            "**/.git/**"
          ]
        }
      ]
    }
  ]
}
'@
  },
  @{
    path = "tools\security\allowlists\client_env_allowlist.txt"
    content = @'
# Client-exposed env var allowlist (Vite)
# One per line. Only variables listed here may be referenced as import.meta.env.VITE_*
VITE_SUPABASE_URL
VITE_SUPABASE_ANON_KEY
'@
  },
  @{
    path = "tools\security\secret-patterns.txt"
    content = @'
# Secret patterns (regex), one per line.
# Keep patterns conservative: reduce false positives but block obvious leaks.

(?i)SUPABASE_SERVICE_ROLE_KEY\s*=\s*.+

# JWT-ish tokens / API keys (heuristic)
eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}

# Common private key headers
-----BEGIN (RSA|EC|OPENSSH|PRIVATE) KEY-----

# Generic “apikey=” style
(?i)\b(api[-_ ]?key|secret|token|password)\b\s*[:=]\s*['"]?[^'"\s]{12,}['"]?
'@
  },
  @{
    path = "tools\security\run-checks.ps1"
    content = @'
[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)][string]$SpecPath = ".agents/security/check-specs/v1/check-specs.json",
  [Parameter(Mandatory=$false)][switch]$VerboseFindings,
  [Parameter(Mandatory=$false)][switch]$IncludeFixtures
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepoFiles {
  param([string[]]$Globs, [string[]]$ExcludeGlobs)

  function Convert-GlobToRegex {
    param([string]$Glob)
    $g = $Glob.Replace("\", "/")
    $sb = New-Object System.Text.StringBuilder
    $i = 0
    while ($i -lt $g.Length) {
      if ($i -le ($g.Length - 3) -and $g.Substring($i, 3) -eq "**/") {
        [void]$sb.Append("(?:.*/)?")
        $i += 3
        continue
      }
      if ($i -le ($g.Length - 2) -and $g.Substring($i, 2) -eq "**") {
        [void]$sb.Append(".*")
        $i += 2
        continue
      }
      $ch = $g[$i]
      switch ($ch) {
        "*" { [void]$sb.Append("[^/]*") }
        "?" { [void]$sb.Append("[^/]") }
        "." { [void]$sb.Append("\.") }
        "+" { [void]$sb.Append("\+") }
        "(" { [void]$sb.Append("\(") }
        ")" { [void]$sb.Append("\)") }
        "[" { [void]$sb.Append("\[") }
        "]" { [void]$sb.Append("\]") }
        "{" { [void]$sb.Append("\{") }
        "}" { [void]$sb.Append("\}") }
        "^" { [void]$sb.Append("\^") }
        "$" { [void]$sb.Append("\$") }
        "|" { [void]$sb.Append("\|") }
        "\" { [void]$sb.Append("\\") }
        default { [void]$sb.Append($ch) }
      }
      $i++
    }
    return "^" + $sb.ToString() + "$"
  }

  $root = (Resolve-Path ".").Path
  $all = Get-ChildItem -Path "." -Recurse -File -Force | ForEach-Object {
    $_.FullName.Substring($root.Length + 1).Replace("\", "/")
  } | Sort-Object

  $includeRegexes = @($Globs) | ForEach-Object { [regex]::new((Convert-GlobToRegex $_)) }
  $excludeRegexes = @($ExcludeGlobs) | ForEach-Object { [regex]::new((Convert-GlobToRegex $_)) }

  $selected = New-Object System.Collections.Generic.List[string]
  $seen = New-Object System.Collections.Generic.HashSet[string]

  foreach ($f in $all) {
    $included = $false
    foreach ($rx in $includeRegexes) {
      if ($rx.IsMatch($f)) { $included = $true; break }
    }
    if (-not $included) { continue }

    foreach ($rx in $excludeRegexes) {
      if ($rx.IsMatch($f)) { $included = $false; break }
    }
    if (-not $included) { continue }

    if ($seen.Add($f)) { $selected.Add($f) | Out-Null }
  }

  return @($selected)
}

function Read-Text {
  param([string]$RelPath)
  $p = Join-Path (Resolve-Path ".").Path ($RelPath -replace "/", "\")
  if (!(Test-Path $p)) { return "" }
  return Get-Content -Raw -LiteralPath $p
}

function Load-Allowlist {
  param([string]$RelPath)
  $txt = Read-Text $RelPath
  $lines = $txt -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith("#") }
  return [System.Collections.Generic.HashSet[string]]::new([string[]]$lines)
}

function Load-RegexList {
  param([string]$RelPath)
  $txt = Read-Text $RelPath
  return @(
  $txt -split "`n" |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith("#") }
)
}

function Add-Finding {
  param(
    [System.Collections.Generic.List[object]]$Findings,
    [string]$RuleId,
    [string]$Severity,
    [string]$File,
    [string]$Message
  )
  $Findings.Add([pscustomobject]@{
    rule_id = $RuleId
    severity = $Severity
    file = $File
    message = $Message
  }) | Out-Null
}

# Load specs
if (!(Test-Path $SpecPath)) { throw "Spec not found: $SpecPath" }
$spec = Get-Content -Raw -LiteralPath $SpecPath | ConvertFrom-Json
$exclude = @($spec.scope.excluded_globs)
if (-not $IncludeFixtures) {
  $exclude += "tools/security/fixtures/**"
}

$findings = New-Object System.Collections.Generic.List[object]

foreach ($rule in $spec.rules) {
  $globs = @($rule.targets.globs)
  $files = Get-RepoFiles -Globs $globs -ExcludeGlobs $exclude

  foreach ($check in $rule.checks) {
    $type = $check.type

    switch ($type) {
      "regex_pair_required" {
        $ifRe = [regex]::new($check.if_regex)
        $thenRe = [regex]::new($check.then_regex)

        foreach ($f in $files) {
          $txt = Read-Text $f
          if ($ifRe.IsMatch($txt) -and -not $thenRe.IsMatch($txt)) {
            Add-Finding $findings $rule.id $rule.severity $f $check.description
          }
        }
      }

      "regex_if_not_contains" {
        $ifRe = [regex]::new($check.if_regex)
        $must = [regex]::new($check.must_contain_regex)

        foreach ($f in $files) {
          $txt = Read-Text $f
          if ($ifRe.IsMatch($txt) -and -not $must.IsMatch($txt)) {
            Add-Finding $findings $rule.id $rule.severity $f $check.description
          }
        }
      }

      "regex_forbidden" {
        $forbidden = @($check.forbidden_regexes) | ForEach-Object { [regex]::new($_) }

        foreach ($f in $files) {
          $txt = Read-Text $f
          foreach ($rx in $forbidden) {
            if ($rx.IsMatch($txt)) {
              Add-Finding $findings $rule.id $rule.severity $f ("Forbidden pattern matched: " + $rx.ToString())
            }
          }
        }
      }

      "vite_env_allowlist" {
        $allow = Load-Allowlist $check.allowlist_path
        $envUse = [regex]::new("(?i)import\.meta\.env\.(VITE_[A-Z0-9_]+)")

        foreach ($f in $files) {
          $txt = Read-Text $f
          $matches = $envUse.Matches($txt)
          foreach ($m in $matches) {
            $name = $m.Groups[1].Value
            if (-not $allow.Contains($name)) {
              Add-Finding $findings $rule.id $rule.severity $f ("Client env var not allowlisted: " + $name)
            }
          }
        }
      }

      "secret_scan" {
        $patterns = Load-RegexList $check.patterns_path
        $ex2 = @($exclude + @($check.exclude_globs))

        $scanFiles = Get-RepoFiles -Globs @("**/*.*") -ExcludeGlobs $ex2

        foreach ($f in $scanFiles) {
          $txt = Read-Text $f
          foreach ($p in $patterns) {
            $rx = [regex]::new($p)
            if ($rx.IsMatch($txt)) {
              Add-Finding $findings $rule.id $rule.severity $f ("Potential secret matched pattern: " + $p)
            }
          }
        }
      }

      default {
        throw "Unknown check type: $type (rule $($rule.id))"
      }
    }
  }
}

# Summarize
$failCount = @($findings | Where-Object { $_.severity -eq "FAIL" }).Count
$warnCount = @($findings | Where-Object { $_.severity -eq "WARN" }).Count

Write-Host ""
Write-Host "WebDesignOS Security Checks"
Write-Host "Spec: $SpecPath"
Write-Host "FAIL: $failCount  WARN: $warnCount"
Write-Host ""

if ($findings.Count -gt 0) {
  $findings | Sort-Object severity, rule_id, file, message | ForEach-Object {
    $tag = if ($_.severity -eq "FAIL") { "[FAIL]" } else { "[WARN]" }
    Write-Host "$tag $($_.rule_id) $($_.file) - $($_.message)"
  }
}

# Write report
$reportDir = ".agents/security/reports"
if (!(Test-Path $reportDir)) { New-Item -ItemType Directory -Force $reportDir | Out-Null }
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$reportPath = Join-Path $reportDir ("report-" + $stamp + ".json")
ConvertTo-Json -InputObject $findings -Depth 6 | Set-Content -Encoding UTF8 $reportPath
Write-Host ""
Write-Host "Report: $reportPath"

if ($failCount -gt 0) {
  exit 2
} else {
  exit 0
}
'@
  }
  ,
  @{
    path = "tools\security\fixtures\fail-self-role-escalation.sql"
    content = @'
-- Fixture: self-role escalation (should FAIL)
update public.profiles
set role = 'admin'
where id = auth.uid();
'@
  }
  ,
  @{
    path = "tools\security\fixtures\fail-secdef-missing-marker.sql"
    content = @'
-- Fixture: SECURITY DEFINER without allowlist marker (should FAIL)
create or replace function public.fixture_secdef_missing_marker()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  null;
end;
$$;
'@
  }
  ,
  @{
    path = "tools\security\fixtures\fail-secdef-dynamic-sql.sql"
    content = @'
-- Fixture: SECURITY DEFINER with dynamic SQL missing allowlist marker (should FAIL)
-- WDSO_ALLOW_SECURITY_DEFINER: test fixture
create or replace function public.fixture_secdef_dynamic_sql()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  execute 'select 1';
end;
$$;
'@
  }
  ,
  @{
    path = "tools\security\fixtures\fail-rls-true-footgun.sql"
    content = @'
-- Fixture: RLS USING (true) on sensitive table (should FAIL)
create policy "rls_true_footgun"
on public.memberships
for select
using (true);
'@
  }
  ,
  @{
    path = "tools\security\check.ps1"
    content = @'
[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)][switch]$IncludeFixtures,
  [Parameter(Mandatory=$false)][switch]$SkipGenerate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path ".").Path
$writer = Join-Path $repoRoot "tools\write-files.ps1"
$runner = Join-Path $repoRoot "tools\security\run-checks.ps1"

if (-not $SkipGenerate) {
  Write-Host "[SECURITY] Running generator: $writer"
  pwsh -File $writer
} else {
  Write-Host "[SECURITY] Skipping generator"
}

Write-Host "[SECURITY] Running checks: $runner"
if ($IncludeFixtures) {
  pwsh -File $runner -IncludeFixtures
} else {
  pwsh -File $runner
}

exit $LASTEXITCODE
'@
  }
)

# Write all files
$repoRoot = (Resolve-Path ".").Path
foreach ($f in $Files) {
  $target = Join-Path $repoRoot $f.path
  Write-TextFile -Path $target -Content $f.content
}

Write-Host "Done."
