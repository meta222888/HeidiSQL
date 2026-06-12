#Requires -Version 5.1
<#
.SYNOPSIS
  Build heidisql.exe with dcc64 (same approach as build.php).
#>
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Config = 'Debug',
    [ValidateSet('Win32', 'Win64')]
    [string]$Platform = 'Win64'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'delphi-env.ps1')

$Bit = if ($Platform -eq 'Win64') { '64' } else { '32' }
$DelphiBin = Get-HeidiDelphiBin -RepoRoot $RepoRoot
$DelphiRoot = Get-HeidiDelphiRoot -DelphiBin $DelphiBin
$MadDir = Get-HeidiMadDir
if (-not $MadDir) { $MadDir = 'C:\Program Files (x86)\madCollection' }
$MadPackages = Test-HeidiMadExceptPackages -MadDir $MadDir -Platform $Platform

& (Join-Path $RepoRoot 'scripts\setup-dev.ps1') | Out-Null
& (Join-Path $RepoRoot 'scripts\compile-resources.ps1')

$dcc = Join-Path $DelphiBin "dcc$Bit.exe"
$lib = Join-Path $DelphiRoot "lib\win$Bit\release"
$out = Join-Path $RepoRoot 'out'
$build = Join-Path $RepoRoot "build\$Platform"
$madPaths = @(
    (Join-Path $MadDir "madExcept\BDS23\win$Bit"),
    (Join-Path $MadDir "madDisAsm\BDS23\win$Bit"),
    (Join-Path $MadDir "madBasic\BDS23\win$Bit")
) -join ';'

$unitPathList = @(
    (Join-Path $RepoRoot 'components\synedit\source'),
    (Join-Path $RepoRoot 'components\virtualtreeview\source'),
    (Join-Path $RepoRoot 'source\detours\Source'),
    (Join-Path $RepoRoot 'source\vcl-styles-utils'),
    (Join-Path $RepoRoot 'source\sizegrip')
)
if (-not $MadPackages) {
    $unitPathList = @( (Join-Path $RepoRoot 'source\madexcept-stub') ) + $unitPathList
}
if ($MadPackages) {
    $unitPathList += $madPaths
}
$unitPathList += $lib
$unitPaths = $unitPathList -join ';'

$resourcePaths = @(
    (Join-Path $RepoRoot 'components\synedit\Source'),
    (Join-Path $RepoRoot 'components\virtualtreeview\Source')
) -join ';'

$defines = 'madExcept;DEBUG'
if ($Config -eq 'Release') { $defines = 'madExcept;RELEASE' }

$args = @(
    '-B', '-Q', '-TX.exe',
    "-E`"$out`"",
    "-N0`"$build`"",
    "-U`"$unitPaths`"",
    "-I`"$unitPaths`"",
    "-R`"$resourcePaths`"",
    '-NS"Vcl;System;Winapi;System.Win;Data;"',
    "-D$defines",
    '-GD',
    '--high-entropy-va:off',
    '-W-SYMBOL_PLATFORM', '-W-UNIT_PLATFORM', '-W-DUPLICATE_CTOR_DTOR',
    'heidisql.dpr'
)

Write-Host "=== dcc$Bit heidisql ===" -ForegroundColor Cyan
Push-Location (Join-Path $RepoRoot 'packages\Delphi12.3')
try {
    & $dcc @args 2>&1 | Tee-Object -FilePath (Join-Path $RepoRoot 'build.log')
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

if (Test-Path (Join-Path $out 'heidisql.exe')) {
    Write-Host "Build OK: $(Join-Path $out 'heidisql.exe')" -ForegroundColor Green
} else {
    Write-Error 'dcc finished but out\heidisql.exe was not created.'
}
