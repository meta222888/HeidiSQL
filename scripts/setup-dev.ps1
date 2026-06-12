#Requires -Version 5.1
<#
.SYNOPSIS
  Initialize HeidiSQL local dev environment.
.EXAMPLE
  .\scripts\setup-dev.ps1
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$OutDir = Join-Path $RepoRoot 'out'
$PortableDir = 'D:\tools\HeidiSQL_12.18_64_Portable'
$InstalledDir = Join-Path $env:LOCALAPPDATA 'Programs\HeidiSQL'

. (Join-Path $PSScriptRoot 'delphi-env.ps1')

function Write-Status {
    param([string]$Label, [bool]$Ok)
    if ($Ok) { Write-Host "OK   $Label" -ForegroundColor Green }
    else { Write-Host "MISS $Label" -ForegroundColor Yellow }
}

Write-Host '=== HeidiSQL dev environment ===' -ForegroundColor Cyan
Write-Host "Repo: $RepoRoot"
Write-Host ''

$DelphiBin = Get-HeidiDelphiBin -RepoRoot $RepoRoot
$DelphiRoot = if ($DelphiBin) { Get-HeidiDelphiRoot -DelphiBin $DelphiBin } else { $null }
$MadDir = Get-HeidiMadDir
$hasBrcc = $DelphiBin -and (Test-Path (Join-Path $DelphiBin 'brcc32.exe'))
$hasInstalled = Test-Path (Join-Path $InstalledDir 'heidisql.exe')
$hasPortable = Test-Path (Join-Path $PortableDir 'heidisql.exe')

Write-Status -Label "Delphi: $(if ($DelphiRoot) { $DelphiRoot } else { 'not found' })" -Ok ($null -ne $DelphiBin)
Write-Status -Label "madExcept: $(if ($MadDir) { $MadDir } else { 'not found' })" -Ok ($null -ne $MadDir)
Write-Status -Label 'brcc32' -Ok $hasBrcc
Write-Status -Label "Portable HeidiSQL: $PortableDir" -Ok $hasPortable
Write-Status -Label "Installed HeidiSQL: $InstalledDir" -Ok $hasInstalled
Write-Host ''

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

$runtimeSrc = $null
if ($hasPortable) { $runtimeSrc = $PortableDir }
elseif ($hasInstalled) { $runtimeSrc = $InstalledDir }

if ($runtimeSrc) {
    Write-Host "Syncing runtime files from $runtimeSrc to out\ ..." -ForegroundColor Yellow
    $patterns = @('*.dll', '*.ini', 'plink*.exe', '*.txt', 'LICENSE*')
    foreach ($pat in $patterns) {
        Get-ChildItem -Path $runtimeSrc -Filter $pat -File -ErrorAction SilentlyContinue |
            Copy-Item -Destination $OutDir -Force
    }
    foreach ($sub in @('plugins', 'plugins64', 'locale', 'Snippets')) {
        $src = Join-Path $runtimeSrc $sub
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination (Join-Path $OutDir $sub) -Recurse -Force
        }
    }
    Write-Host 'Runtime files synced.' -ForegroundColor Green
} else {
    Write-Host 'No portable/installed HeidiSQL found for runtime DLL sync.' -ForegroundColor Yellow
    Write-Host '  Optional: extract D:\tools\HeidiSQL_12.18_64_Portable or winget install HeidiSQL.HeidiSQL' -ForegroundColor Gray
}

New-Item -ItemType Directory -Path (Join-Path $RepoRoot 'build\Win64') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $RepoRoot 'build\Win32') -Force | Out-Null

if (-not $DelphiBin) {
    Write-Host ''
    Write-Host 'Delphi not found. Set HEIDISQL_DELPHI_BIN or install to D:\tools\Delphi 12.3' -ForegroundColor Red
    return 1
}

Ensure-HeidiDelphiRsVars -RepoRoot $RepoRoot -DelphiRoot $DelphiRoot | Out-Null
Write-Host "Generated scripts\rsvars-local.bat for: $DelphiRoot" -ForegroundColor Cyan

if (-not $MadDir) {
    Write-Host ''
    Write-Host 'madExcept not found; build will use source\madexcept-stub (dev builds only).' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Ready. Next: .\scripts\build.ps1' -ForegroundColor Green
return 0
