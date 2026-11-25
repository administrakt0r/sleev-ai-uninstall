<#
.SYNOPSIS
  Removes known Sleev (sleev.ai) application components from Windows.

.DESCRIPTION
  Removes known application files, the verified gateway task, and the exact
  global npm package. Browser site data and AI harness configurations are
  left for manual review. Reports incomplete cleanup with exit code 1.

.PARAMETER DryRun
  Lists targets without stopping processes, uninstalling packages or deleting files.

.PARAMETER Yes
  Skips interactive confirmation, not the safety checks.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$script:removedFiles = 0
$script:failedItems = 0

foreach ($base in @($env:USERPROFILE, $env:LOCALAPPDATA, $env:APPDATA)) {
    if ([string]::IsNullOrWhiteSpace($base) -or $base -notmatch '^[A-Za-z]:\\.+') {
        throw 'A required user directory is missing or is not an absolute local path.'
    }
}

$cliPath = Join-Path $env:USERPROFILE '.local\bin\sleev.exe'
$gatewayRoots = @(
    (Join-Path $env:LOCALAPPDATA 'sleev')
    (Join-Path $env:LOCALAPPDATA 'sleev-gateway')
)
$targets = @(
    $cliPath
    (Join-Path $env:USERPROFILE '.local\state\sleev')
    $gatewayRoots[0]
    $gatewayRoots[1]
    (Join-Path $env:APPDATA 'sleev')
    (Join-Path $env:APPDATA 'ai.opencode.desktop\sleev')
)

function Test-NoReparseAncestor([string]$Path) {
    try {
        $current = [IO.Path]::GetFullPath($Path)
        while ($current) {
            try {
                $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
                if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    return $false
                }
            } catch {
                if ($_.CategoryInfo.Category -ne 'ObjectNotFound') {
                    return $false
                }
            }
            $parent = [IO.Path]::GetDirectoryName($current)
            if (-not $parent -or $parent -eq $current) { break }
            $current = $parent
        }
        return $true
    } catch {
        return $false
    }
}

function Test-SleevExecutable([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    try {
        $expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
        if ($expanded -notmatch '^[A-Za-z]:\\') { return $false }
        $full = [IO.Path]::GetFullPath($expanded)
        if ([string]::Equals($full, [IO.Path]::GetFullPath($cliPath),
                [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
        if ([IO.Path]::GetFileName($full) -notin @('sleev.exe', 'sleeve-gateway.exe', 'sleev-gateway.exe')) {
            return $false
        }
        foreach ($root in $gatewayRoots) {
            $prefix = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
            if ($full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        }
    } catch {
        return $false
    }
    return $false
}

function Get-SleevTask {
    Get-ScheduledTask -ErrorAction Stop | Where-Object {
        $_.TaskName -eq 'SleeveGateway' -and $_.TaskPath -eq '\'
    }
}

function Test-SleevTask($Task) {
    $actions = @($Task.Actions)
    if ($actions.Count -eq 0) { return $false }
    foreach ($action in $actions) {
        if (-not (Test-SleevExecutable $action.Execute)) { return $false }
        $path = [Environment]::ExpandEnvironmentVariables($action.Execute.Trim().Trim('"'))
        if (-not (Test-NoReparseAncestor $path)) { return $false }
    }
    return $true
}

function Get-SleevProcesses {
    Get-CimInstance -ClassName Win32_Process -ErrorAction Stop | Where-Object {
        $_.ProcessId -ne $PID -and
        (Test-SleevExecutable $_.ExecutablePath) -and
        (Test-NoReparseAncestor $_.ExecutablePath)
    }
}

function Get-KnownItem([string]$Path) {
    try {
        Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    } catch {
        if ($_.CategoryInfo.Category -ne 'ObjectNotFound') { throw }
    }
}

# Never recurse through a reparse point. Use literal file deletion and
# nonrecursive directory deletion so a failed child cannot hide siblings.
function Remove-SafeTree($Item) {
    try {
        $Item = Get-Item -LiteralPath $Item.FullName -Force -ErrorAction Stop
        if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw 'Reparse point: manual review required.'
        }
        if ($Item.PSIsContainer) {
            foreach ($child in (Get-ChildItem -LiteralPath $Item.FullName -Force -ErrorAction Stop)) {
                Remove-SafeTree $child
            }
            [IO.Directory]::Delete($Item.FullName, $false)
        } else {
            Remove-Item -LiteralPath $Item.FullName -Force -ErrorAction Stop
            $script:removedFiles++
            if ($script:removedFiles % 500 -eq 0) {
                Write-Host "Removed files: $script:removedFiles | Failed items: $script:failedItems"
            }
        }
    } catch {
        $script:failedItems++
        Write-Warning "Not removed: $($Item.FullName) - $_"
    }
}

function Get-GlobalSleevPackage($Npm) {
    $json = (& $Npm.Source list -g --depth=0 --json --offline --no-audit --no-fund 2>$null) -join [Environment]::NewLine
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect global npm packages.' }
    $packages = $json | ConvertFrom-Json -ErrorAction Stop
    return ($packages.dependencies.PSObject.Properties.Name -contains 'sleev')
}

Write-Host '=== Sleev cleanup targets ===' -ForegroundColor Cyan
foreach ($path in $targets) {
    if (-not (Test-NoReparseAncestor $path)) {
        Write-Warning "Unsafe or inaccessible path (will be skipped): $path"
    } elseif (Get-KnownItem $path) {
        Write-Host "[FOUND] $path"
    } else {
        Write-Host "[NOT FOUND] $path"
    }
}

$task = Get-SleevTask
if ($task) {
    Write-Host 'Scheduled task: \SleeveGateway'
    $task.Actions | Format-Table Execute
    if (-not (Test-SleevTask $task)) {
        Write-Warning 'Task action could not be verified. Cleanup will refuse to remove it.'
    }
}
Write-Host 'Known running Sleev executables:'
Get-SleevProcesses | Format-Table ProcessId, Name, ExecutablePath
Write-Host 'Global npm package: sleev (checked before removal)'
Write-Host 'Browser data, generic temporary directories and AI harness configs are not deleted.'

if ($DryRun) {
    Write-Host '[DRY RUN] No changes were made.'
    exit 0
}

if (-not $Yes) {
    Write-Warning 'This permanently deletes Sleev application files, local sessions, logs and credentials. No backup is made.'
    if ((Read-Host "Type 'REMOVE SLEEV' to proceed") -cne 'REMOVE SLEEV') {
        Write-Host 'Cancelled.'
        exit 1
    }
}

$drives = @($targets | ForEach-Object { [IO.Path]::GetPathRoot($_) } | Sort-Object -Unique)
$before = @{}
foreach ($drive in $drives) {
    try { $before[$drive] = [IO.DriveInfo]::new($drive).AvailableFreeSpace }
    catch { Write-Warning "Cannot measure free space on $drive." }
}

# Re-read task and action after confirmation. Disable startup before stopping
# the gateway. Do not remove application files if task shutdown is uncertain.
$task = Get-SleevTask
if ($task) {
    if (-not (Test-SleevTask $task)) {
        throw 'Unexpected SleeveGateway task action. Inspect the task manually.'
    }
    Disable-ScheduledTask -TaskName 'SleeveGateway' -TaskPath '\' -ErrorAction Stop | Out-Null
    Stop-ScheduledTask -TaskName 'SleeveGateway' -TaskPath '\' -ErrorAction Stop
    Unregister-ScheduledTask -TaskName 'SleeveGateway' -TaskPath '\' -Confirm:$false -ErrorAction Stop
    if (Get-SleevTask) { throw 'Gateway task still exists. Cleanup stopped.' }
    Write-Host 'Scheduled task removed.'
}

# Match the executable path, never merely its name or a substring in a
# command line. Leave unknown wrappers/services for manual inspection.
foreach ($process in @(Get-SleevProcesses)) {
    $current = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($process.ProcessId)" -ErrorAction Stop
    if ($current -and $current.CreationDate -eq $process.CreationDate -and
        (Test-SleevExecutable $current.ExecutablePath) -and
        (Test-NoReparseAncestor $current.ExecutablePath)) {
        Stop-Process -Id $current.ProcessId -Force -ErrorAction Stop
    }
}
Start-Sleep -Seconds 2
if (@(Get-SleevProcesses).Count -gt 0) {
    throw 'Known Sleev processes are still running. Cleanup stopped.'
}

$npm = Get-Command npm.cmd -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($npm) {
    try {
        if (Get-GlobalSleevPackage $npm) {
            & $npm.Source uninstall -g sleev --ignore-scripts --offline --no-audit --no-fund
            if ($LASTEXITCODE -ne 0) { throw 'npm uninstall failed.' }
        }
    } catch {
        $script:failedItems++
        Write-Warning $_
    }
}

foreach ($path in $targets) {
    try {
        if (-not (Test-NoReparseAncestor $path)) { throw 'Unsafe or inaccessible path.' }
        $item = Get-KnownItem $path
        if ($item) {
            Write-Host "Removing: $path"
            Remove-SafeTree $item
            if (-not (Get-KnownItem $path)) {
                Write-Host "Removed: $path" -ForegroundColor Green
            }
        }
    } catch {
        $script:failedItems++
        Write-Warning "Could not remove $path - $_"
    }
}

Write-Host '=== Verification ===' -ForegroundColor Cyan
foreach ($path in $targets) {
    try {
        if (-not (Test-NoReparseAncestor $path) -or (Get-KnownItem $path)) {
            $script:failedItems++
            Write-Warning "NOT CLEARED: $path"
        } else {
            Write-Host "[CLEAR] $path"
        }
    } catch {
        $script:failedItems++
        Write-Warning "Cannot verify $path - $_"
    }
}
if (Get-SleevTask) {
    $script:failedItems++
    Write-Warning 'Scheduled task still exists.'
}
if (@(Get-SleevProcesses).Count -gt 0) {
    $script:failedItems++
    Write-Warning 'Known Sleev executables are still running.'
}
if ($npm) {
    try {
        if (Get-GlobalSleevPackage $npm) { throw 'Global npm sleev package remains.' }
    } catch {
        $script:failedItems++
        Write-Warning $_
    }
}
if (Get-Command sleev -ErrorAction SilentlyContinue) {
    $script:failedItems++
    Write-Warning 'Sleev command remains in PATH.'
}
try {
    $listeners = @(Get-NetTCPConnection -State Listen -ErrorAction Stop |
        Where-Object { $_.LocalPort -eq 17321 })
    if ($listeners.Count -gt 0) {
        $script:failedItems++
        Write-Warning 'Port 17321 is still listening. Inspect the owning process; it may be unrelated.'
        $listeners | Format-Table LocalAddress, LocalPort, OwningProcess
    }
} catch {
    $script:failedItems++
    Write-Warning "Cannot verify port 17321: $_"
}

foreach ($relative in @('.codex\config.toml', '.config\opencode\opencode.json',
        '.config\opencode\opencode.jsonc', '.claude.json')) {
    $config = Join-Path $env:USERPROFILE $relative
    try {
        if (Test-NoReparseAncestor $config) {
            if ((Get-KnownItem $config) -and
                (Select-String -LiteralPath $config -Pattern 'sleev|17321' -Quiet -ErrorAction Stop)) {
                Write-Warning "Potential Sleev proxy reference: $config (manual review)"
            }
        } else {
            Write-Warning "Configuration not inspected: $config"
        }
    } catch {
        Write-Warning "Configuration not inspected: $config"
    }
}

Write-Host '=== Disk space ===' -ForegroundColor Cyan
Write-Host "Removed files: $script:removedFiles"
Write-Host "Failed or unverified items: $script:failedItems"
foreach ($drive in $drives) {
    if ($before.ContainsKey($drive)) {
        try {
            $after = [IO.DriveInfo]::new($drive).AvailableFreeSpace
            Write-Host ("{0} Free-space change: {1:N2} GiB; available: {2:N2} GiB" -f
                $drive, (($after - $before[$drive]) / 1GB), ($after / 1GB))
        } catch { Write-Warning "Cannot measure free space on $drive." }
    }
}
Write-Host 'Review browser site data for sleev.ai and restore any proxy settings manually.'
if ($script:failedItems -eq 0) {
    Write-Host 'Known application targets cleared; see manual checks in README.' -ForegroundColor Green
    exit 0
}
Write-Warning 'Cleanup incomplete. Review warnings and retry after resolving them.'
exit 1
