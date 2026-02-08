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