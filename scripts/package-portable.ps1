#Requires -Version 5.1
<#
.SYNOPSIS
  Package out\ into a portable zip for GitHub release.
#>
param(
    [string]$Version = '12.18.1'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$OutDir = Join-Path $RepoRoot 'out'
$DistDir = Join-Path $RepoRoot 'dist'
$ZipName = "HeidiSQL_${Version}_64_Portable.zip"
$ZipPath = Join-Path $DistDir $ZipName
$StageDir = Join-Path $DistDir "HeidiSQL_${Version}_64_Portable"

if (-not (Test-Path (Join-Path $OutDir 'heidisql.exe'))) {
    Write-Error 'out\heidisql.exe not found. Run .\scripts\build.ps1 first.'
}

& (Join-Path $PSScriptRoot 'setup-dev.ps1') | Out-Null

if (Test-Path $StageDir) { Remove-Item $StageDir -Recurse -Force }
New-Item -ItemType Directory -Path $StageDir | Out-Null

$exclude = @('portable_settings.txt', 'tabs.ini', 'portable.lock', 'heidisql.iss')
Get-ChildItem $OutDir -File | Where-Object { $exclude -notcontains $_.Name } | Copy-Item -Destination $StageDir
foreach ($sub in @('plugins', 'plugins64', 'locale', 'Snippets')) {
    $src = Join-Path $OutDir $sub
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $StageDir $sub) -Recurse -Force
    }
}

New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path (Join-Path $StageDir '*') -DestinationPath $ZipPath -Force
Remove-Item $StageDir -Recurse -Force

Write-Host "Created $ZipPath" -ForegroundColor Green
