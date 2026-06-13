#Requires -Version 5.1
<#
.SYNOPSIS
  Compile HeidiSQL .rc resource files into .res (required before first MSBuild).
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent

. (Join-Path $PSScriptRoot 'delphi-env.ps1')

$DelphiBin = Get-HeidiDelphiBin -RepoRoot $RepoRoot
if (-not $DelphiBin) { throw 'Delphi not found.' }

$Brcc = Join-Path $DelphiBin 'brcc32.exe'
$Cgrc = Join-Path $DelphiBin 'cgrc.exe'
if (-not (Test-Path $Brcc)) { throw "brcc32 not found: $Brcc" }

Write-Host '=== Compile HeidiSQL resources ===' -ForegroundColor Cyan

$versionRcPath = Join-Path $RepoRoot 'res\version.rc'
$versionText = [System.IO.File]::ReadAllText($versionRcPath)
$versionText = $versionText.Replace('%APPNAME%', 'HeidiSQL')
$versionText = $versionText.Replace('%APPVER%', '13.0.0.1 64 Bit')
$versionTmp = Join-Path $env:TEMP 'heidisql-version.rc'
[System.IO.File]::WriteAllText($versionTmp, $versionText, [System.Text.Encoding]::Default)

Push-Location (Join-Path $RepoRoot 'res')
try {
    & $Brcc $versionTmp
    if (Test-Path (Join-Path $env:TEMP 'heidisql-version.res')) {
        Move-Item (Join-Path $env:TEMP 'heidisql-version.res') (Join-Path $RepoRoot 'res\version.res') -Force
    }
    if (Test-Path $Cgrc) { & $Cgrc 'icon.rc' } else { & $Brcc 'icon.rc' }
    & $Brcc 'icon-question.rc'
    & $Brcc 'manifest.rc'
    & $Brcc 'updater.rc'
    if (Test-Path $Cgrc) { & $Cgrc 'styles.rc' } else { & $Brcc 'styles.rc' }
} finally {
    Pop-Location
}

Push-Location (Join-Path $RepoRoot 'source\vcl-styles-utils')
try {
    & $Brcc 'AwesomeFont.rc'
    & $Brcc 'AwesomeFont_zip.rc'
} finally {
    Pop-Location
}

Write-Host 'Resources compiled.' -ForegroundColor Green
