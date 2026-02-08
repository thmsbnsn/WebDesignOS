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