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
$Pf86 = [Environment]::GetFolderPath('ProgramFilesX86')
$DelphiBin = Join-Path $Pf86 'Embarcadero\Studio\23.0\bin'
$MadDir = Join-Path $Pf86 'madCollection'
$InstalledDir = Join-Path $env:LOCALAPPDATA 'Programs\HeidiSQL'

function Write-Status {
    param([string]$Label, [bool]$Ok)
    if ($Ok) {
        Write-Host "OK   $Label"
    } else {
        Write-Host "MISS $Label"
    }
}

Write-Host '=== HeidiSQL dev environment ===' -ForegroundColor Cyan
Write-Host "Repo: $RepoRoot"
Write-Host ''

$hasDelphi = Test-Path (Join-Path $DelphiBin 'dcc64.exe')
$hasMad = Test-Path (Join-Path $MadDir 'madExcept\Tools\madExceptPatch.exe')
$hasBrcc = Test-Path (Join-Path $DelphiBin 'brcc32.exe')
$hasInstalled = Test-Path (Join-Path $InstalledDir 'heidisql.exe')

Write-Status -Label "Delphi 12.3: $DelphiBin" -Ok $hasDelphi
Write-Status -Label 'madExcept (madCollection)' -Ok $hasMad
Write-Status -Label 'brcc32' -Ok $hasBrcc
Write-Status -Label "Installed HeidiSQL: $InstalledDir" -Ok $hasInstalled
Write-Host ''

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

if ($hasInstalled) {
    Write-Host 'Syncing runtime files to out\ ...' -ForegroundColor Yellow
    $patterns = @('*.dll', '*.ini', 'plink*.exe', '*.txt', 'LICENSE*')
    foreach ($pat in $patterns) {
        Get-ChildItem -Path $InstalledDir -Filter $pat -File -ErrorAction SilentlyContinue |
            Copy-Item -Destination $OutDir -Force
    }
    $pluginsSrc = Join-Path $InstalledDir 'plugins'
    if (Test-Path $pluginsSrc) {
        Copy-Item -Path $pluginsSrc -Destination (Join-Path $OutDir 'plugins') -Recurse -Force
    }
    Write-Host 'Runtime files synced.' -ForegroundColor Green
} else {
    Write-Host 'No installed HeidiSQL found. Run: winget install HeidiSQL.HeidiSQL' -ForegroundColor Yellow
}

New-Item -ItemType Directory -Path (Join-Path $RepoRoot 'build\Win64') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $RepoRoot 'build\Win32') -Force | Out-Null

if (-not $hasDelphi) {
    Write-Host ''
    Write-Host 'Delphi not found. Install RAD Studio 12.1+ and madExcept, then rerun.' -ForegroundColor Red
    Write-Host '  https://www.embarcadero.com/products/delphi' -ForegroundColor Gray
    Write-Host '  http://madshi.net/madCollection.exe' -ForegroundColor Gray
    Write-Host ''
    Write-Host 'Then run: .\scripts\build.ps1' -ForegroundColor Yellow
    exit 1
}

if (-not $hasMad) {
    Write-Host 'Warning: madExcept not found. Release builds may fail.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Ready. Next: .\scripts\build.ps1' -ForegroundColor Green
exit 0
