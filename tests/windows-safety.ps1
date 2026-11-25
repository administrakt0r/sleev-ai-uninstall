# Run on Windows PowerShell 5.1: powershell -NoProfile -File .\tests\windows-safety.ps1
# Load only helper definitions, never execute the uninstall entry point.
$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'uninstall-sleev.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $scriptPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors -join [Environment]::NewLine) }

foreach ($name in @('Test-NoReparseAncestor', 'Test-SleevExecutable', 'Remove-SafeTree')) {
    $definition = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq $name
    }, $false)
    if (-not $definition) { throw "Missing safety helper: $name" }
    . ([scriptblock]::Create($definition.Extent.Text))
}

function Assert-True($condition, [string]$message) {
    if (-not $condition) { throw $message }
}

$fixture = Join-Path ([IO.Path]::GetTempPath()) ('sleev-test-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $fixture
$owned = Join-Path $fixture 'sleev'
$outside = Join-Path $fixture 'sleev-other'
$link = Join-Path $owned 'external-link'
$locked = Join-Path $owned 'locked.log'
$ordinary = Join-Path $owned 'ordinary.log'
$sentinel = Join-Path $outside 'keep.txt'
$handle = $null
try {
    $null = New-Item -ItemType Directory -Path $owned, $outside
    Set-Content -LiteralPath $sentinel -Value 'outside'
    Set-Content -LiteralPath $locked -Value 'locked'
    Set-Content -LiteralPath $ordinary -Value 'ordinary'
    $cliPath = Join-Path $fixture 'sleev.exe'
    $gatewayRoots = @($owned)
    Assert-True (Test-SleevExecutable (Join-Path $owned 'sleeve-gateway.exe')) 'Known gateway path rejected'
    Assert-True (-not (Test-SleevExecutable (Join-Path $outside 'sleeve-gateway.exe'))) 'Sibling path accepted'
    Assert-True (-not (Test-SleevExecutable (Join-Path $owned 'other.exe'))) 'Unrelated executable accepted'
    Assert-True (-not (Test-SleevExecutable (Join-Path $owned '..\sleev-other\sleeve-gateway.exe'))) 'Traversal accepted'
    Assert-True (Test-SleevExecutable $cliPath) 'Exact CLI path rejected'

    $null = New-Item -ItemType Junction -Path $link -Target $outside
    Assert-True (-not (Test-NoReparseAncestor $link)) 'Junction was accepted'
    Assert-True (-not (Test-NoReparseAncestor (Join-Path $link 'keep.txt'))) 'Junction ancestor was accepted'

    $handle = [IO.File]::Open($locked, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::None)
    $script:removedFiles = 0
    $script:failedItems = 0
    Remove-SafeTree (Get-Item -LiteralPath $owned -Force)
    Assert-True (Test-Path -LiteralPath $sentinel) 'External file was deleted'
    Assert-True (Test-Path -LiteralPath $link) 'Junction should be left for manual review'
    Assert-True (Test-Path -LiteralPath $locked) 'Locked file should remain'
    Assert-True (-not (Test-Path -LiteralPath $ordinary)) 'Locked file prevented sibling cleanup'
    Assert-True ($script:removedFiles -eq 1) 'Wrong deletion count'
    Assert-True ($script:failedItems -ge 2) 'Skipped or locked items not reported'
    $handle.Dispose()
    $handle = $null
    [IO.Directory]::Delete($link, $false)
    $script:failedItems = 0
    Remove-SafeTree (Get-Item -LiteralPath $owned -Force)
    Assert-True (-not (Test-Path -LiteralPath $owned)) 'Retry failed to remove owned directory'
    Assert-True ($script:failedItems -eq 0) 'Retry reported failures'
    Assert-True (Test-Path -LiteralPath $sentinel) 'Retry touched external file'
    Write-Host 'PASS: scoped paths, junction safety, locked files and retry'
} finally {
    if ($handle) { $handle.Dispose() }
    if (Test-Path -LiteralPath $link) { [IO.Directory]::Delete($link, $false) }
    Remove-Item -LiteralPath $fixture -Recurse -Force
}
