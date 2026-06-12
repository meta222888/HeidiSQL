#Requires -Version 5.1
<#
.SYNOPSIS
  Download and install madCollection (madExcept) for HeidiSQL builds.
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$TargetDir = if ($env:HEIDISQL_MAD_DIR) { $env:HEIDISQL_MAD_DIR } else { 'D:\tools\madCollection' }
$Installer = Join-Path $env:TEMP 'madCollection.exe'
$Url = 'http://madshi.net/madCollection.exe'

. (Join-Path $PSScriptRoot 'delphi-env.ps1')

if (Get-HeidiMadDir) {
    Write-Host "madExcept already installed: $(Get-HeidiMadDir)" -ForegroundColor Green
    exit 0
}

Write-Host 'Downloading madCollection...' -ForegroundColor Cyan
Invoke-WebRequest -Uri $Url -OutFile $Installer -UseBasicParsing

Write-Host "Installing to $TargetDir (may show installer UI)..." -ForegroundColor Yellow
$proc = Start-Process -FilePath $Installer -ArgumentList '/VERYSILENT', "/DIR=`"$TargetDir`"" -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Write-Host "Silent install exit code $($proc.ExitCode). Trying interactive install..." -ForegroundColor Yellow
    Start-Process -FilePath $Installer -Wait
}

if (-not (Get-HeidiMadDir)) {
    Write-Error "madExcept still not found under $TargetDir. Complete madCollection setup in the installer, then rerun setup-dev.ps1."
}

Write-Host "madExcept installed: $(Get-HeidiMadDir)" -ForegroundColor Green
Write-Host 'Next: open Delphi IDE once and compile madExcept design packages for BDS 23 if prompted.' -ForegroundColor Yellow
