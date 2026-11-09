<#
.SYNOPSIS
  Completely uninstalls and removes Sleev (sleev.ai) from Windows.

.DESCRIPTION
  Removes Sleev binaries, scheduled task, local SQLite session database,
  request/debug HTTP logs, credentials, npm packages, and browser site data.

.PARAMETER DryRun
  Lists targets that would be removed without deleting anything.

.PARAMETER Yes
  Skips interactive confirmation.
#>

[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$Yes
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Sleev Windows Removal Script (sleev.ai) " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$targets = @(
  "$env:USERPROFILE\.local\bin\sleev.exe",
  "$env:USERPROFILE\.local\state\sleev",
  "$env:LOCALAPPDATA\sleev",
  "$env:LOCALAPPDATA\sleev-gateway",
  "$env:APPDATA\sleev",
  "$env:APPDATA\ai.opencode.desktop\sleev"
)

# Search browser roots for sleev site data
$browserRoots = @(
  "$env:LOCALAPPDATA\Google\Chrome\User Data",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
  "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data",
  "$env:APPDATA\Mozilla\Firefox\Profiles"
)

$browserTargets = @()
foreach ($root in $browserRoots) {
  if (Test-Path $root) {
    $found = Get-ChildItem -Path $root -Recurse -Filter "*sleev*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    if ($found) {
      $browserTargets += $found
    }
  }
}

# Temp directories
$tempTargets = @()
$meiDirs = Get-ChildItem -Path "$env:LOCALAPPDATA\Temp" -Filter "_MEI*" -Directory -ErrorAction SilentlyContinue
foreach ($d in $meiDirs) {
  if (Get-ChildItem -Path $d.FullName -Filter "*sleeve*" -Recurse -ErrorAction SilentlyContinue) {
    $tempTargets += $d.FullName
  }
}

Write-Host "`nTarget paths identified for removal:" -ForegroundColor Yellow
foreach ($t in $targets) {
  $exists = Test-Path $t
  Write-Host "  [$([char]0x2022)] $t $(if ($exists) { '(EXISTS)' } else { '(not found)' })"
}
foreach ($bt in $browserTargets) {
  Write-Host "  [$([char]0x2022)] Browser Data: $bt (EXISTS)"
}
foreach ($tt in $tempTargets) {
  Write-Host "  [$([char]0x2022)] Temp Dist: $tt (EXISTS)"
}

$task = Get-ScheduledTask -TaskName "SleeveGateway" -ErrorAction SilentlyContinue
if ($task) {
  Write-Host "  [$([char]0x2022)] Scheduled Task: \SleeveGateway (Status: $($task.State))" -ForegroundColor Yellow
}

if ($DryRun) {
  Write-Host "`n[DRY RUN] No changes were made." -ForegroundColor Green
  exit 0
}

# Check running browsers
$runningBrowsers = Get-Process -Name "chrome", "msedge", "brave", "firefox" -ErrorAction SilentlyContinue
if ($runningBrowsers -and $browserTargets.Count -gt 0) {
  Write-Warning "Web browsers are currently running. Close them to ensure browser site-data files can be unlocked and deleted."
}

if (-not $Yes) {
  Write-Host "`nWARNING: This will permanently delete Sleev binaries, settings, session SQLite databases, logs, and credentials." -ForegroundColor Red
  $confirm = Read-Host "Type 'REMOVE SLEEV' to proceed"
  if ($confirm -ne 'REMOVE SLEEV') {
    Write-Host "Aborted by user." -ForegroundColor Yellow
    exit 1
  }
}

Write-Host "`n[1/6] Stopping any running Sleev / Sleeve processes..." -ForegroundColor Cyan
Get-Process | Where-Object { $_.ProcessName -match "sleev|sleeve" } | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "[2/6] Removing Scheduled Task 'SleeveGateway'..." -ForegroundColor Cyan
if ($task) {
  try {
    Unregister-ScheduledTask -TaskName "SleeveGateway" -Confirm:$false -ErrorAction Stop
    Write-Host "  Successfully removed Scheduled Task 'SleeveGateway'." -ForegroundColor Green
  } catch {
    Write-Warning "  Could not unregister 'SleeveGateway' task (requires Administrator elevation)."
    Write-Warning "  To remove the task registration, run this one command in an Administrator PowerShell window:"
    Write-Host "    Unregister-ScheduledTask -TaskName 'SleeveGateway' -Confirm:`$false" -ForegroundColor White
  }
} else {
  Write-Host "  No scheduled task found." -ForegroundColor DarkGray
}

Write-Host "[3/6] Checking and uninstalling npm global package..." -ForegroundColor Cyan
try {
  $npmSleev = npm list -g sleev 2>$null
  if ($npmSleev -match "sleev@") {
    npm uninstall -g sleev | Out-Null
    Write-Host "  Uninstalled global npm sleev package." -ForegroundColor Green
  }
} catch {
  # npm not present or failed
}

Write-Host "[4/6] Deleting Sleev files and folders..." -ForegroundColor Cyan
foreach ($t in $targets) {
  if (Test-Path $t) {
    Remove-Item -Path $t -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed: $t" -ForegroundColor Green
  }
}
foreach ($tt in $tempTargets) {
  if (Test-Path $tt) {
    Remove-Item -Path $tt -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed temp build: $tt" -ForegroundColor Green
  }
}

Write-Host "[5/6] Cleaning browser site data..." -ForegroundColor Cyan
foreach ($bt in $browserTargets) {
  if (Test-Path $bt) {
    Remove-Item -Path $bt -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed site data: $bt" -ForegroundColor Green
  }
}

Write-Host "[6/6] Checking AI harness configs..." -ForegroundColor Cyan
$codexConfig = "$env:USERPROFILE\.codex\config.toml"
if (Test-Path $codexConfig) {
  $content = Get-Content $codexConfig -Raw
  if ($content -match "model_providers\.sleev") {
    Write-Warning "  Found sleev provider in $codexConfig. Remember to remove [model_providers.sleev] section."
  }
}

$opencodeConfig = "$env:USERPROFILE\.config\opencode\opencode.jsonc"
if (Test-Path $opencodeConfig) {
  $content = Get-Content $opencodeConfig -Raw
  if ($content -match "17321|sleev") {
    Write-Warning "  Found sleev 17321 proxy in $opencodeConfig. Revert providers to direct upstream URLs."
  }
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " Verification Phase " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$remaining = 0
foreach ($t in $targets) {
  if (Test-Path $t) {
    Write-Host "STILL EXISTS: $t" -ForegroundColor Red
    $remaining++
  }
}
$cli = Get-Command sleev -ErrorAction SilentlyContinue
if ($cli) {
  Write-Host "STILL IN PATH: sleev ($($cli.Source))" -ForegroundColor Red
  $remaining++
}

if ($remaining -eq 0) {
  Write-Host "SUCCESS: Sleev has been cleanly removed from your system!" -ForegroundColor Green
} else {
  Write-Warning "Some items could not be deleted automatically. Check the paths above."
}
