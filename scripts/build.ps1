#Requires -Version 5.1
<#
.SYNOPSIS
  Build HeidiSQL (Delphi 12.3 + madExcept)

.EXAMPLE
  .\scripts\build.ps1
  .\scripts\build.ps1 -Config Release -Platform Win64
#>
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Config = 'Debug',
    [ValidateSet('Win32', 'Win64')]
    [string]$Platform = 'Win64'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$HeidiProj = Join-Path $RepoRoot 'packages\Delphi12.3\heidisql.dproj'

. (Join-Path $PSScriptRoot 'delphi-env.ps1')

$DelphiBin = Get-HeidiDelphiBin -RepoRoot $RepoRoot
if (-not $DelphiBin) {
    Write-Error 'Delphi not found. Install to D:\tools\Delphi 12.3 or set HEIDISQL_DELPHI_BIN.'
}

$DelphiRoot = Get-HeidiDelphiRoot -DelphiBin $DelphiBin
$RsVars = Ensure-HeidiDelphiRsVars -RepoRoot $RepoRoot -DelphiRoot $DelphiRoot

$setupCode = & (Join-Path $RepoRoot 'scripts\setup-dev.ps1')
if ($setupCode -ne 0) { exit $setupCode }

& (Join-Path $RepoRoot 'scripts\compile-resources.ps1')

& (Join-Path $RepoRoot 'scripts\build-dcc.ps1') -Config $Config -Platform $Platform
exit $LASTEXITCODE
